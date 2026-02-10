codeunit 81276 "MOB Document Management"
{
    Access = Public;
    Permissions = tabledata "MOB Document Queue" = d;
    TableNo = "MOB Document Queue";

    trigger OnRun()
    begin
    end;

    var
        GlobalMobBaseEventSubscribers: Codeunit "MOB Base Event Subscribers";
        GlobalMobPackageManagement: Codeunit "MOB Package Management";
        GlobalMobPackShipFeatureMgt: Codeunit "MOB Pack Feature Management";
        MobSessionData: Codeunit "MOB SessionData";
        MobToolbox: Codeunit "MOB Toolbox";
        MobWmsToolBox: Codeunit "MOB WMS Toolbox";
        MobXmlMgt: Codeunit "MOB XML Management";
        MobTelemetryMgt: Codeunit "MOB Telemetry Management";
        NoValidMobileUserErr: Label 'The user %1 could not be found as a valid mobile user.', Comment = '%1 contains Mobile User Id';
        DocumentTypeNotFoundErr: Label 'Document type %1 was not found.', Comment = '%1 contains name of Document Type';
        MessageExistsErr: Label 'Message already exists.';
        RequestNotProcessedMsg: Label 'Unable to return a response for the request %1 because it has not been processed yet.', Comment = '%1 contains MessageID';
        RequestQueuedMsg: Label 'The request has been received and queued for later processing.';
        MissingCodeunitErr: Label 'Error in Mobile Document Type setup.\\Codeunit %1 specified in %2 ''%3'' does not exist.', Locked = true;

    internal procedure ProcessDocumentManual(var _MobDocQueue: Record "MOB Document Queue")
    var
        MobDocProcessor: Report "MOB Document Processor";
        XmlRequestDoc: XmlDocument;
    begin
        // Ensure telemetry is initialized per request
        MobTelemetryMgt.Initialize();

        // Make MessageId, MobileUserID, DeviceID, StartDateTime and DocumentType available from everywhere via SingleInstance codeunit (including from all standard events)
        MobSessionData.Initialize(); // Ensure unassigned values are cleared in single instance codeunit
        MobSessionData.SetPostingMessageId(_MobDocQueue.MessageIDAsGuid());
        MobSessionData.SetDocumentType(_MobDocQueue."Document Type");
        MobSessionData.SetMobileUserID(_MobDocQueue."Mobile User ID");
        MobSessionData.SetDeviceID(_MobDocQueue."Device ID");
        MobSessionData.SetProcessingStartDateTime(CurrentDateTime());

        _MobDocQueue.Status := _MobDocQueue.Status::Error;
        _MobDocQueue.Modify();
        Commit();

        BindGlobalEventSubscriberCodeunits();

        _MobDocQueue.LoadXMLRequestDoc(XmlRequestDoc);
        MobDocProcessor.ProcessDocumentQueue(_MobDocQueue);
    end;

    internal procedure DeleteDocument(var _MobDocQueue: Record "MOB Document Queue")
    begin
        _MobDocQueue.Delete(true);

        MobWmsToolBox.DeleteRegistrationData(_MobDocQueue.MessageIDAsGuid());
    end;

    internal procedure ResetDocument(var _MobDocQueue: Record "MOB Document Queue")
    begin
        _MobDocQueue.Status := _MobDocQueue.Status::New;
        _MobDocQueue.Modify(true);
    end;

    internal procedure ValidateUser(_MobileUserID: Text[65])
    var
        MobUser: Record "MOB User";
    begin
        MobUser.SetFilter("User ID", '@' + _MobileUserID);
        if MobUser.IsEmpty() then
            Error(NoValidMobileUserErr, _MobileUserID);
    end;

    internal procedure GetDocumentType(var _XmlRequestDoc: XmlDocument): Text[50]
    var
        XmlRootNode: XmlNode;
        DocumentType: Text;
    begin
        MobXmlMgt.GetDocRootNode(_XmlRequestDoc, XmlRootNode);
        if MobXmlMgt.GetAttribute(XmlRootNode, 'name', DocumentType) then
            exit(DocumentType);
    end;

    internal procedure ValidateDocumentType(_DocumentType: Text[50])
    var
        MobDocType: Record "MOB Document Type";
    begin
        MobDocType.SetAutoCalcFields("Processing Codeunit Name");
        if not MobDocType.Get(_DocumentType) then
            Error(DocumentTypeNotFoundErr, _DocumentType);

        // If the flowfield "Processing Codeunit Name" is blank, the specified "Processing Codeunit" does not exist        
        if MobDocType."Processing Codeunit Name" = '' then
            Error(MissingCodeunitErr, MobDocType."Processing Codeunit", MobDocType.TableCaption(), MobDocType."Document Type");
    end;

    /// <summary>
    /// Add additional system information to request for support purposes
    /// </summary>
    [TryFunction]
    internal procedure AddTroubleshootingInfo(var _XmlRootNode: XmlNode)
    var
        AppSystemConst: Codeunit "Application System Constants";
        MobDeviceMgt: Codeunit "MOB Device Management";
        MobInstall: Codeunit "MOB Install";
        XmlCreatedNode: XmlNode;
    begin

        MobXmlMgt.AddAttribute(_XmlRootNode, 'bcAppVersion', Format(MobInstall.GetCurrentVersion()));
        /* #if BC15+ */
        MobXmlMgt.AddAttribute(_XmlRootNode, 'bcVersion', AppSystemConst.BuildFileVersion()); // Example "2x.0.23364.25624"
        /* #endif */
        MobXmlMgt.AddAttribute(_XmlRootNode, 'deviceAppVersion', Format(MobDeviceMgt.GetDeviceApplicationVersion()));
        MobXmlMgt.AddAttribute(_XmlRootNode, 'deviceId', Format(MobSessionData.GetDeviceID()));
        MobXmlMgt.AddAttribute(_XmlRootNode, 'deviceAppInstaller', MobDeviceMgt.GetDeviceProperty('/application[@installer]'));

        MobXmlMgt.AddElement(_XmlRootNode, 'errorCallStack', MobSessionData.GetPreservedLastErrorCallStack(), MobXmlMgt.GetNodeNSURI(_XmlRootNode), XmlCreatedNode);
    end;

    internal procedure ReceivedBefore(var _MobDocQueue: Record "MOB Document Queue"; var _XmlResponseDoc: XmlDocument): Boolean
    var
        MobDocQueue2: Record "MOB Document Queue";
        XmlResponseDoc2: XmlDocument;
    begin
        if MobDocQueue2.Get(_MobDocQueue."Message ID") then begin

            if LowerCase(_MobDocQueue."Mobile User ID") <> LowerCase(MobDocQueue2."Mobile User ID") then
                Error(MessageExistsErr);

            if _MobDocQueue."Device ID" <> MobDocQueue2."Device ID" then
                Error(MessageExistsErr);

            if not MobDocQueue2.LoadXMLResponseDoc(XmlResponseDoc2) then
                Error(RequestNotProcessedMsg, _MobDocQueue."Message ID");

            _XmlResponseDoc := XmlResponseDoc2;
            exit(true);
        end;

        exit(false);
    end;

    internal procedure CreateXMLResponseDocError(var _XmlResponseDoc: XmlDocument; _MessageID: Code[100]; _Description: Text)
    var
        Status: Option Completed,Error,Received;
    begin
        CreateXMLResponseDoc(_XmlResponseDoc, _MessageID, _Description, Status::Error);
    end;

    internal procedure CreateXMLResponseDocReceived(var _XmlLResponseDoc: XmlDocument; _MessageID: Code[100])
    var
        Status: Option Completed,Error,Received;
    begin
        CreateXMLResponseDoc(_XmlLResponseDoc, _MessageID, RequestQueuedMsg, Status::Received);
    end;

    local procedure CreateXMLResponseDoc(var _XmlResponseDoc: XmlDocument; _MessageID: Code[100]; _Description: Text; Status: Option Completed,Error,Received)
    var
        XmlRootNode: XmlNode;
        XmlCreatedNode: XmlNode;
    begin
        MobToolbox.InitializeQueueResponseDoc(_XmlResponseDoc);

        MobXmlMgt.GetDocRootNode(_XmlResponseDoc, XmlRootNode);

        MobXmlMgt.AddAttribute(XmlRootNode, 'messageid', _MessageID);
        case Status of
            Status::Error:
                MobXmlMgt.AddAttribute(XmlRootNode, 'status', 'Error');
            Status::Received:
                MobXmlMgt.AddAttribute(XmlRootNode, 'status', 'Received');
        end;

        MobXmlMgt.AddElement(XmlRootNode, 'description', _Description, MobXmlMgt.GetNodeNSURI(XmlRootNode), XmlCreatedNode);

        if Status = Status::Error then
            AddTroubleshootingInfo(XmlRootNode);
    end;

    procedure UpdateResult(var _MobDocQueue: Record "MOB Document Queue"; var _XmlResponseDoc: XmlDocument)
    var
        XmlRootNode: XmlNode;
    begin
        MobXmlMgt.GetDocRootNode(_XmlResponseDoc, XmlRootNode);
        MobXmlMgt.AddAttribute(XmlRootNode, 'messageid', _MobDocQueue."Message ID");
        MobXmlMgt.AddAttribute(XmlRootNode, 'status', 'Completed');

        _MobDocQueue.SaveXMLResponseDoc(_XmlResponseDoc);
        _MobDocQueue.Status := _MobDocQueue.Status::Completed;
        _MobDocQueue.Modify();
    end;

    internal procedure ProcessDocumentWebService(var _MobDocQueue: Record "MOB Document Queue") _ErrorText: Text
    var
        MobDocProcessor: Report "MOB Document Processor";
        XmlRequestDoc: XmlDocument;
    begin
        BindGlobalEventSubscriberCodeunits();

        _MobDocQueue.LoadXMLRequestDoc(XmlRequestDoc);
        _ErrorText := MobDocProcessor.ProcessDocumentWebService(_MobDocQueue);
    end;

    internal procedure SetRequestDateAndTime(var _XmlRequestDoc: XmlDocument; var _MobDocQueue: Record "MOB Document Queue")
    var
        XmlRootNode: XmlNode;
        CreatedDateTimeText: Text;
    begin
        MobXmlMgt.GetDocRootNode(_XmlRequestDoc, XmlRootNode);
        if MobXmlMgt.GetAttribute(XmlRootNode, 'created', CreatedDateTimeText) then begin
            Evaluate(_MobDocQueue."Request Date", CopyStr(CreatedDateTimeText, 1, 10), 9);
            Evaluate(_MobDocQueue."Request Time", CopyStr(CreatedDateTimeText, 12, 8), 9);
        end;
    end;

    /// <remarks>
    /// Bindings are shared for all active MobPackageManagement instances.
    /// When global codeunits goes out of scope, all bindings are removed.
    /// </remarks>
    local procedure BindGlobalEventSubscriberCodeunits()
    begin
        // Misc. base events
        BindSubscription(GlobalMobBaseEventSubscribers);

        // Pack & Ship
        GlobalMobPackShipFeatureMgt.BindUnbindPackManagement();

        // Package No.
        if GlobalMobPackageManagement.IsEnabled() then
            BindSubscription(GlobalMobPackageManagement);
    end;
}
