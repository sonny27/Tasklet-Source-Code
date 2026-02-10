codeunit 81298 "MOB Device Management"
{
    Access = Public;
    /* Example of Capabilities node:
        <capabilities>
            <application version="1.8.1" />
            <device manufacturer="Honeywell" model="EDA60K">
                <language currentCultureName="en-US" />
                <platform name="Android" version="7.1.1" />
                <screen height="533" width="320" orientation="Portrait" />
            </device>
        </capabilities>
    */

    var
        MobXmlMgt: Codeunit "MOB XML Management";
        MobSessionData: Codeunit "MOB SessionData";
        AutomaticallyCreatedMsg: Label 'Automatically created';
        GetDevAppInstallerInvalidDocTypeErr: Label 'Internal error: MOB Device Management.GetDeviceApplicationInstaller() Invalid Document Type', Locked = true;
        NoValidDeviceMinVersionFoundErr: Label 'At least one mobile device must be updated to version %1 to use this feature.', Comment = '%1 is the required version number';
        NoSpecificValidDeviceMinVersionFoundErr: Label 'This mobile device must be updated to minimum version %1 to use this feature.', Comment = '%1 is the required version number';

    internal procedure StoreDeviceProperties(var _XmlRequestDoc: XmlDocument)
    var
        MobDevice: Record "MOB Device";
    begin
        // Insert new device
        if not MobDevice.Get(MobSessionData.GetDeviceID()) then begin
            MobDevice.Init();
            MobDevice."Device ID" := MobSessionData.GetDeviceID();
            MobDevice.Description := AutomaticallyCreatedMsg;
            MobDevice.Insert(false);
        end;

        // Exit if no capability node or unchanged capabilities
        if not UpdateDeviceProperties(MobDevice, _XmlRequestDoc) then
            exit;

        MobDevice.Modify(false)
    end;

    local procedure UpdateDeviceProperties(var _MobDevice: Record "MOB Device"; _XmlRequestDoc: XmlDocument): Boolean
    var
        MobDeviceProperty: Record "MOB Device Property";
        MobCommonMgt: Codeunit "MOB Common Mgt.";
        RequestNode: XmlNode;
        RequestDataNode: XmlNode;
        CapabilitiesNode: XmlNode;
        CapabilitiesHashValue: Text;
    begin
        // Find the capabilities node or exit if not supported by the mobile app
        MobXmlMgt.GetDocRootNode(_XmlRequestDoc, RequestNode);
        if not MobXmlMgt.SelectSingleNode(RequestNode, 'requestData', RequestDataNode) then
            exit;
        if not MobXmlMgt.SelectSingleNode(RequestDataNode, 'capabilities', CapabilitiesNode) then
            if not MobXmlMgt.SelectSingleNode(RequestDataNode, 'capabilites', CapabilitiesNode) then // Typo in node name in app version 1.8.1
                exit(false);

        // Check if the Capabilities has been changed since the last update. Otherwise no need to go through each property
        CapabilitiesHashValue := MobCommonMgt.GenerateHashMD5(MobXmlMgt.GetNodeOuterText(CapabilitiesNode));
        if CapabilitiesHashValue = _MobDevice."Capability Hash Value" then
            exit(false);

        // Check if this device is the last device with this Hash Value before assigning the new value
        _MobDevice.DeleteDevicePropertiesIfLastDevice();

        // Update Mobile Device with new capability hash
        _MobDevice."Capability Hash Value" := CapabilitiesHashValue;

        // Check if capability hash is already stored
        MobDeviceProperty.Reset();
        MobDeviceProperty.SetRange("Capability Hash Value", _MobDevice."Capability Hash Value");
        if not MobDeviceProperty.IsEmpty() then
            exit(true);

        StoreDevicePropertiesForNode(_MobDevice, CapabilitiesNode, '');

        exit(true);
    end;

    local procedure StoreDevicePropertiesForNode(var _MobDevice: Record "MOB Device"; _XmlNode: XmlNode; _PropertyPath: Text)
    var
        ChildXmlNode: XmlNode;
        XmlAttrib: XmlAttribute;
        NodeList: XmlNodeList;
        NodeNo: Integer;
        AttributeNo: Integer;
    begin
        // Loop all child nodes and store them recursivly
        MobXmlMgt.GetNodeChildNodes(_XmlNode, NodeList);
        for NodeNo := 1 to NodeList.Count() do begin
            NodeList.Get(NodeNo, ChildXmlNode);
            StoreDevicePropertiesForNode(_MobDevice, ChildXmlNode, _PropertyPath + '/' + ChildXmlNode.AsXmlElement().LocalName());
        end;

        // Loop all attributes and store them
        for AttributeNo := 1 to _XmlNode.AsXmlElement().Attributes().Count() do begin
            _XmlNode.AsXmlElement().Attributes().Get(AttributeNo, XmlAttrib);
            InsertDeviceProperty(_MobDevice."Capability Hash Value", StrSubstNo('%1[@%2]', _PropertyPath, XmlAttrib.Name()), XmlAttrib.Value());
        end;
    end;

    local procedure InsertDeviceProperty(_CapabilityHashValue: Text; _Name: Text; _Value: Text)
    var
        MobDeviceProperty: Record "MOB Device Property";
    begin
        MobDeviceProperty.Init();
        MobDeviceProperty."Capability Hash Value" := CopyStr(_CapabilityHashValue, 1, MaxStrLen(MobDeviceProperty."Capability Hash Value"));
        MobDeviceProperty.Name := CopyStr(_Name, 1, MaxStrLen(MobDeviceProperty.Name));
        MobDeviceProperty.Value := CopyStr(_Value, 1, MaxStrLen(MobDeviceProperty.Value));
        MobDeviceProperty.Insert(true);
    end;

    /// <summary>
    /// Gets the device property value of the current device
    /// </summary>
    /// <param name="_PropertyName">Specify the name of the property i.e. '/application[@version]' </param>
    /// <returns>The property value in Text</returns>
    internal procedure GetDeviceProperty(_PropertyName: Text[250]) ReturnValue: Text[250]
    var
        MobDevice: Record "MOB Device";
        MobDeviceProperty: Record "MOB Device Property";
    begin
        // Has this property already been asked for?
        if MobSessionData.DevicePropertyDictionary_Get(_PropertyName, ReturnValue) then
            exit(ReturnValue);

        // Find the capability hash value of the current device (if available) and find the device property (if available)
        if MobDevice.Get(MobSessionData.GetDeviceID()) then
            if MobDevice."Capability Hash Value" <> '' then
                if MobDeviceProperty.Get(MobDevice."Capability Hash Value", _PropertyName) then
                    ReturnValue := MobDeviceProperty.Value;

        // Store the value - no matter if it was found or not. This avoids trying to find it again later during the processing of this request
        MobSessionData.DevicePropertyDictionary_Add(_PropertyName, ReturnValue);

        // Return the value
        exit(ReturnValue);
    end;

    /// <summary>
    /// Gets the device application version of the current device
    /// </summary>
    /// <returns>The device application version</returns>
    internal procedure GetDeviceApplicationVersion() ReturnValue: Version
    var
        VersionTxt: Text[250];
    begin
        VersionTxt := GetDeviceProperty('/application[@version]');

        if not Evaluate(ReturnValue, VersionTxt, 9) then
            ReturnValue := Version.Create(0, 0, 0, 0);
    end;

    /// <summary>
    /// Check if any device exist with a minimum required version
    /// </summary>
    /// <param name="_MinRequiredVersionTxt">The required version formatted like "Major.Minor.Build.Revision" i.e. "1.10.0.0"</param>
    /// <returns></returns>
    internal procedure CheckAnyDeviceExistWithMinimumAppVersion(_MinRequiredVersionTxt: Text; _ThrowError: Boolean): Boolean
    var
        MobDeviceProperty: Record "MOB Device Property";
        MinRequiredVersion: Version;
        FoundVersion: Version;
    begin
        Evaluate(MinRequiredVersion, _MinRequiredVersionTxt, 9);

        MobDeviceProperty.SetRange(Name, '/application[@version]');
        if MobDeviceProperty.FindSet() then
            repeat
                if Evaluate(FoundVersion, MobDeviceProperty.Value, 9) then
                    if FoundVersion >= MinRequiredVersion then
                        exit(true);
            until MobDeviceProperty.Next() = 0;

        if _ThrowError then
            Error(NoValidDeviceMinVersionFoundErr, _MinRequiredVersionTxt);
    end;

    /// <summary>
    /// Check if the current device exist with a minimum required version
    /// </summary>
    /// <param name="_MinRequiredVersionTxt">The required version formatted like "Major.Minor.Build.Revision" i.e. "1.10.0.0"</param>
    /// <returns></returns>
    internal procedure CheckAppVersionOfCurrentDevice(_MinRequiredVersionTxt: Text; _ThrowError: Boolean): Boolean
    var
        MinRequiredVersion: Version;
        DeviceVersion: Version;
    begin
        Evaluate(MinRequiredVersion, _MinRequiredVersionTxt, 9);
        DeviceVersion := GetDeviceApplicationVersion();

        if DeviceVersion >= MinRequiredVersion then
            exit(true);

        if _ThrowError then
            Error(NoSpecificValidDeviceMinVersionFoundErr, _MinRequiredVersionTxt);
    end;

    /// <summary>
    /// Date and Decimal formatting is based on "culture" in order to match Mobile App
    /// Do not confuse culture with text/mobile language
    /// </summary>
    internal procedure GetDeviceLanguageId() LanguageID: Integer
    begin
        // Respect mobile culture (if present)

        // Get from cache
        LanguageID := MobSessionData.GetDeviceLanguageID();
        if LanguageID > 0 then
            exit(LanguageID);

        // Get from device properties
        if GetValidLanguageIdFromCulture(GetDeviceProperty('/device/language[@currentCultureName]'), LanguageID) then begin
            // Save to cache (if valid)
            MobSessionData.SetDeviceLanguageID(LanguageID);
            exit(LanguageID);
        end;

        // Fallback to globallanguage culture (Mobile User Language) set from "MOB Document Processor"
        exit(GlobalLanguage());
    end;

    /// <summary>
    /// Check eg. 'en-US' is valid as BC culture
    /// Else fallback to Global LanguageID
    /// </summary>
    /* #if BC22+ */
    local procedure GetValidLanguageIdFromCulture(_Culture: Text; var _ReturnLanguageId: Integer) Success: Boolean
    var
        WindowsLanguage: Record "Windows Language";
    begin
        WindowsLanguage.SetRange("Language Tag", _Culture);
        if WindowsLanguage.FindFirst() then begin
            _ReturnLanguageId := WindowsLanguage."Language ID";
            Success := true;
        end;
    end;
    /* #endif */

    /* #if BC21- ##
    local procedure GetValidLanguageIDFromCulture(_Culture: Text; var _ReturnLanguageId: Integer) Success: Boolean
    begin
        exit(false); // BC21 and lower, does not support using mobile device property "currentCultureName"
    end;
    /* #endif */

    internal procedure GetDeviceInstaller(var _XmlRequestDoc: XmlDocument) ReturnValue: Text
    var
        RequestNode: XmlNode;
        RequestDataNode: XmlNode;
        CapabilitiesNode: XmlNode;
        ApplicationNode: XmlNode;
        PropertyName: Text;
    begin
        PropertyName := '/application[@installer]';

        // Has this property already been asked for?
        if MobSessionData.DevicePropertyDictionary_Get(PropertyName, ReturnValue) then
            exit(ReturnValue);

        // Is this a valid document type to get the installer from?
        if MobSessionData.GetDocumentType() <> 'GetReferenceData' then
            Error(GetDevAppInstallerInvalidDocTypeErr);

        // Find the installer attribute in the XML of the current GetReferenceData request (not using the device properties table)
        MobXmlMgt.GetDocRootNode(_XmlRequestDoc, RequestNode);
        if MobXmlMgt.SelectSingleNode(RequestNode, 'requestData', RequestDataNode) then
            if MobXmlMgt.SelectSingleNode(RequestDataNode, 'capabilities', CapabilitiesNode) then
                if MobXmlMgt.SelectSingleNode(CapabilitiesNode, 'application', ApplicationNode) then
                    if MobXmlMgt.GetAttribute(ApplicationNode, 'installer', ReturnValue) then; // Avoid error if not found
                    
        // Store the value - no matter if it was found or not. This avoids trying to find it again later during the processing of this request        
        MobSessionData.DevicePropertyDictionary_Add(PropertyName, ReturnValue);
    end;

    internal procedure GetDeviceInstallerIsUnmanaged(var _XmlRequestDoc: XmlDocument): Boolean
    var
        ApplicationInstaller: Text;
    begin
        ApplicationInstaller := GetDeviceInstaller(_XmlRequestDoc);
        exit(ApplicationInstaller = 'Unmanaged');
    end;

    internal procedure GetDeviceInstallerIsUnmanaged(): Boolean
    var
        ApplicationInstaller: Text;
    begin
        ApplicationInstaller := GetDeviceProperty('/application[@installer]');
        exit(ApplicationInstaller = 'Unmanaged');
    end;
}
