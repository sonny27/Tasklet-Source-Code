codeunit 81353 "MOB Application Configuration"
{
    Access = Public;
    // GetApplicationConfiguration (and GetReferenceData) is used to get the application.cfg and tweak files

    TableNo = "MOB Document Queue";

    trigger OnRun()
    begin
        MobDocQueue := Rec;

        case Rec."Document Type" of

            'GetApplicationConfiguration':
                GetApplicationConfiguration(XmlResponseDoc);

            else
                Error(MobWmsLanguage.GetMessage('NO_DOC_HANDLER'), Rec."Document Type");
        end;

        // Store the result in the queue and update the status
        MobToolbox.UpdateResult(Rec, XmlResponseDoc);
    end;


    var
        MobDocQueue: Record "MOB Document Queue";
        MobXmlMgt: Codeunit "MOB XML Management";
        MobToolbox: Codeunit "MOB Toolbox";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        XmlResponseDoc: XmlDocument;
        InvalidConfigurationNameErr: Label 'Internal error: Invalid configuration name "%1" in GetApplicationConfiguration()', Locked = true;

    /// <summary>
    /// 'GetReferenceData': Send version for full standard/main application.cfg and/or tweak files if needed.
    /// "Version" is a hash for the content rather than a version number.
    /// The Android App will subsequently issue a separate "GetApplicationConfiguration"-request if application.cfg or tweak versions differs from what exists at the device.
    /// </summary>

    // Sample response:
    // <Configuration>
    //   <Key>ApplicationConfiguration</Key>
    //   <Value>
    //     <![CDATA[
    //       <applicationConfiguration>
    //         <configuration name="ApplicationConfiguration" version="d843c706c3fc92dbc611371dbca9accd" main="true" />
    //         <configuration name="Tweak1" version="bbc0b9efb06640aecb28f1f440682c55" />
    //         <configuration name="Tweak2" version="d843c706c3fc92dbc611371dbca9accd" />
    //         <configuration name="Tweak3" version="e06fe48988aa06b90f45cab2d0a79a9d" />
    //       </applicationConfiguration>
    //     ]]>
    //    </Value>
    // </Configuration>

    internal procedure AddApplicationConfigurationVersionToReferenceData(var _XmlResponseData: XmlNode)
    var
        TempTweakBuffer: Record "MOB Tweak Buffer" temporary;
        MobStandardApplicationCfg: Codeunit "MOB Standard Application.cfg";
        MobDeviceManagement: Codeunit "MOB Device Management";
        MobTweakContainer: Codeunit "MOB Tweak Container";
        MobTelemetryManagement: Codeunit "MOB Telemetry Management";
        XmlConfigurationNode: XmlNode;
        XmlConfigurationValueNode: XmlNode;
        XmlApplicationConfigurationPlaceholderNode: XmlNode;
        XmlCreatedNode: XmlNode;
        XmlCDataSection: XmlCData;
        IncludeStandardApplicationCfg: Boolean;
        HasApplicationConfigurationTweakSubscribers: Boolean;
        HeaderConfNS: Text;
    begin
        // Standard application.cfg for sandbox demo environments
        IncludeStandardApplicationCfg := MobDeviceManagement.GetDeviceInstallerIsUnmanaged(); // Device usage already validated

        // Tweaks from eventsubscribers
        OnGetApplicationConfiguration_OnAddTweaks(MobTweakContainer);
        MobTweakContainer.GetTweakBuffer(TempTweakBuffer);
        HasApplicationConfigurationTweakSubscribers := not TempTweakBuffer.IsEmpty();

        if IncludeStandardApplicationCfg or HasApplicationConfigurationTweakSubscribers then begin

            HeaderConfNS := MobXmlMgt.GetNodeNSURI(_XmlResponseData);

            // Create the configuration "envelope"
            MobXmlMgt.AddElement(_XmlResponseData, 'Configuration', '', '', XmlConfigurationNode);
            MobXmlMgt.AddElement(XmlConfigurationNode, 'Key', 'ApplicationConfiguration', '', XmlCreatedNode);
            MobXmlMgt.AddElement(XmlConfigurationNode, 'Value', '', '', XmlConfigurationValueNode);
            MobXmlMgt.AddElement(XmlConfigurationNode, 'applicationConfiguration', '', '', XmlApplicationConfigurationPlaceholderNode); // This node is made as a placeholder for a CData element
            MobXmlMgt.AddAttribute(XmlApplicationConfigurationPlaceholderNode, 'tweakStrategy', 'MergeWithExisting'); // Default="BackendOnly" - This allows local tweaks on the device to be applied in addition to the tweaks sent from the backend

            if IncludeStandardApplicationCfg then
                AddConfigurationNode('ApplicationConfiguration', MobStandardApplicationCfg.GetApplicationCfgAsText(), false, HeaderConfNS, XmlApplicationConfigurationPlaceholderNode);

            if HasApplicationConfigurationTweakSubscribers then begin
                TempTweakBuffer.FindSet();
                repeat
                    AddConfigurationNode(TempTweakBuffer, false, HeaderConfNS, XmlApplicationConfigurationPlaceholderNode);
                until TempTweakBuffer.Next() = 0;

                MobTelemetryManagement.LogTweakUsage(TempTweakBuffer);
            end;

            // Create a CDATA element with the contents of the placeholder and delete the placeholder
            MobXmlMgt.NodeCreateCData(XmlCDataSection, Format(XmlApplicationConfigurationPlaceholderNode));
            MobXmlMgt.NodeAppendCData(XmlConfigurationValueNode, XmlCDataSection);
            XmlApplicationConfigurationPlaceholderNode.Remove();
        end;
    end;

    /// <summary>
    /// 'GetApplicationConfiguration': Send standard/main application.cfg to Android App.
    /// </summary>

    // Sample response:
    // <response xmlns="http://schemas.microsoft.com/Dynamics/Mobile/2007/04/Documents/Response" messageid="966CC210-4E4E-4958-93FA-29516784CB4D" status="Completed">
    //   <description/>
    //   <responseData xmlns="http://schemas.taskletfactory.com/MobileWMS/BaseDataModel">
    //     <applicationConfiguration>
    //       <configuration name="ApplicationConfiguration" version="FD0BCAF739D3C369770D6AC8360BA4C1">
    //         <![CDATA[ <?xml version="1.0" encoding="utf-8"?><application> <pages tweak="Append"> <page id="PutAwayLines" tweak="Append"> <orderLinesConfiguration tweak="Append"> <toggleOrderLineGrouping tweak="Append" enabled="true" title="@{MenuItemOrderLineUngroup}" icon="menuplus" groupTitle="@{MenuItemOrderLineGroup}" groupIcon="menuminus" contextMenuPlacement="1" menuPlacement="1" /> </orderLinesConfiguration> </page> </pages></application> ]]>
    //       </configuration>
    //     </applicationConfiguration>
    //   </responseData>
    // </response>    

    local procedure GetApplicationConfiguration(var _XmlResponseDoc: XmlDocument)
    var
        TempTweakBuffer: Record "MOB Tweak Buffer" temporary;
        TempConfigurationValues: Record "MOB Common Element" temporary;
        MobTweakContainer: Codeunit "MOB Tweak Container";
        MobStandardApplicationCfg: Codeunit "MOB Standard Application.cfg";
        MobNsRequestMgt: Codeunit "MOB NS Request Management";
        MobDeviceManagement: Codeunit "MOB Device Management";
        MobFeatureTelemetryWrapper: Codeunit "MOB Feature Telemetry Wrapper";
        MobTelemetryEventId: Enum "MOB Telemetry Event ID";
        XmlApplicationConfigurationNode: XmlNode;
        XmlRequestDoc: XmlDocument;
        XmlResponseData: XmlNode;
        ConfigurationCDataText: Text;
        HeaderConfNS: Text;
    begin
        // Load the request document from the document queue
        MobDocQueue.LoadXMLRequestDoc(XmlRequestDoc);
        MobNsRequestMgt.InitCommonFromApplicationConfigurationNodes(XmlRequestDoc, TempConfigurationValues);

        // Initialize the response xml
        MobToolbox.InitializeResponseDoc(_XmlResponseDoc, XmlResponseData);
        HeaderConfNS := MobXmlMgt.GetNodeNSURI(XmlResponseData);
        MobXmlMgt.AddElement(XmlResponseData, 'applicationConfiguration', '', HeaderConfNS, XmlApplicationConfigurationNode);

        if TempConfigurationValues.FindSet() then
            repeat

                if TempConfigurationValues.GetValue('name') = 'ApplicationConfiguration' then begin

                    // Add ApplicationConfiguration
                    ConfigurationCDataText := MobStandardApplicationCfg.GetApplicationCfgAsText();
                    AddConfigurationNode('ApplicationConfiguration', ConfigurationCDataText, true, HeaderConfNS, XmlApplicationConfigurationNode);

                end else begin

                    // Get all tweaks from eventsubscribers the first time - reuse the buffer for all tweak requests
                    if TempTweakBuffer.IsEmpty() then begin
                        OnGetApplicationConfiguration_OnAddTweaks(MobTweakContainer);
                        MobTweakContainer.GetTweakBuffer(TempTweakBuffer);
                    end;

                    // Requesting unknown configuration?
                    if not TempTweakBuffer.Get(TempConfigurationValues.GetValue('name')) then
                        Error(InvalidConfigurationNameErr, TempConfigurationValues.GetValue('name'));

                    AddConfigurationNode(TempTweakBuffer, true, HeaderConfNS, XmlApplicationConfigurationNode);
                end;

            until TempConfigurationValues.Next() = 0;

        // Log telemetry of successfull connection by trial version
        if MobDeviceManagement.GetDeviceInstallerIsUnmanaged() then
            MobFeatureTelemetryWrapper.LogUptakeUsed(MobTelemetryEventId::"Mobile WMS Trial (MOB1040)");
    end;

    local procedure AddConfigurationNode(_Name: Text; _Content: Text; _AddContent: Boolean; _HeaderConfNS: Text; var _XmlApplicationConfigurationNode: XmlNode)
    var
        MobCommonMgt: Codeunit "MOB Common Mgt.";
        XmlConfigurationNode: XmlNode;
        XmlConfigurationCData: XmlCData;
    begin
        MobXmlMgt.AddElement(_XmlApplicationConfigurationNode, 'configuration', '', _HeaderConfNS, XmlConfigurationNode);
        MobXmlMgt.AddAttribute(XmlConfigurationNode, 'name', _Name);
        MobXmlMgt.AddAttribute(XmlConfigurationNode, 'version', MobCommonMgt.GenerateHashMD5(_Content));

        if _Name = 'ApplicationConfiguration' then
            MobXmlMgt.AddAttribute(XmlConfigurationNode, 'main', 'true');

        // Don't add content for GetReferenceData. Add content for GetApplicationConfiguration.
        if _AddContent then begin
            MobXmlMgt.NodeCreateCData(XmlConfigurationCData, _Content);
            MobXmlMgt.NodeAppendCData(XmlConfigurationNode, XmlConfigurationCData);
        end
    end;

    local procedure AddConfigurationNode(var _MobTweakBuffer: Record "MOB Tweak Buffer"; _AddContent: Boolean; _HeaderConfNS: Text; var _XmlApplicationConfigurationNode: XmlNode)
    var
        Content: Text;
        IStream: InStream;
    begin
        // Get the content from the buffer
        _MobTweakBuffer.CalcFields(Content);
        _MobTweakBuffer.Content.CreateInStream(IStream);
        IStream.Read(Content);

        AddConfigurationNode(_MobTweakBuffer."File Name", Content, _AddContent, _HeaderConfNS, _XmlApplicationConfigurationNode);
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnGetApplicationConfiguration_OnAddTweaks(var _MobTweakContainer: Codeunit "MOB Tweak Container")
    begin
    end;
}
