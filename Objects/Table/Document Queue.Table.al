table 81279 "MOB Document Queue"
{
    Access = Public;
    Caption = 'Mobile Document Queue';
    LookupPageId = "MOB Document Queue List";
    DrillDownPageId = "MOB Document Queue List";

    fields
    {
        field(1; "Message ID"; Code[100])
        {
            Caption = 'Message ID';
            DataClassification = CustomerContent;
            NotBlank = true;
        }
        field(2; "Device ID"; Code[200])
        {
            Caption = 'Device ID';
            DataClassification = CustomerContent;
            TableRelation = "MOB Device";
            ValidateTableRelation = false;
        }
        field(3; "Mobile User ID"; Code[50])
        {
            Caption = 'Mobile User ID';
            TableRelation = "MOB User";
            DataClassification = CustomerContent;
        }
        field(4; "Document Type"; Text[50])
        {
            Caption = 'Document Type';
            TableRelation = "MOB Document Type";
            DataClassification = CustomerContent;
        }
        field(5; "Process Type"; Option)
        {
            Caption = 'Process Type';
            OptionCaption = 'Queue,Direct';
            OptionMembers = Queue,Direct;
            DataClassification = CustomerContent;
            ObsoleteReason = 'Not used in Mobile WMS';
            ObsoleteState = Removed;
            ObsoleteTag = 'MOB5.35';
        }
        field(6; Status; Option)
        {
            Caption = 'Status';
            OptionCaption = 'New,Processing,Completed,Error';
            OptionMembers = New,Processing,Completed,Error;
            DataClassification = CustomerContent;
        }
        field(7; "Created Date/Time"; DateTime)
        {
            Caption = 'Created Date/Time';
            Editable = true;
            DataClassification = CustomerContent;
        }
        field(8; "Answer Date/Time"; DateTime)
        {
            Caption = 'Answer Date/Time';
            DataClassification = CustomerContent;
        }
        field(9; "Result Date/Time"; DateTime)
        {
            Caption = 'Result Date/Time', Locked = true;
            DataClassification = CustomerContent;
            ObsoleteReason = 'Not used in Mobile WMS';
            ObsoleteState = Removed;
            ObsoleteTag = 'MOB4.37';
        }
        field(10; "Request XML"; Blob)
        {
            Caption = 'Request XML';
            Compressed = false;
            DataClassification = CustomerContent;
        }
        field(11; "Answer XML"; Blob)
        {
            Caption = 'Response XML';
            DataClassification = CustomerContent;
            Compressed = false;
        }
        field(12; "Result XML"; Blob)
        {
            Caption = 'Result XML', Locked = true;
            DataClassification = CustomerContent;
            Compressed = false;
            ObsoleteReason = 'Not used in Mobile WMS';
            ObsoleteState = Removed;
            ObsoleteTag = 'MOB4.37';
        }
        field(13; "NAS User ID"; Code[50])
        {
            Caption = 'NAS User ID', Locked = true;
            DataClassification = CustomerContent;
            ObsoleteState = Removed;
            ObsoleteReason = 'Unused';
            ObsoleteTag = 'MOB5.60';
        }

        field(14; "NAS Host Name"; Text[65])
        {
            Caption = 'NAS Host Name', Locked = true;
            DataClassification = CustomerContent;
            ObsoleteState = Removed;
            ObsoleteReason = 'Unused';
            ObsoleteTag = 'MOB5.60';
        }
        field(15; "NAS Port"; Integer)
        {
            Caption = 'NAS Port', Locked = true;
            DataClassification = CustomerContent;
            ObsoleteState = Removed;
            ObsoleteReason = 'Unused';
            ObsoleteTag = 'MOB5.60';
        }
        field(20; "Registration Type"; Text[80])
        {
            Caption = 'Registration Type';
            DataClassification = CustomerContent;
        }

        field(30; "Request Date"; Date)
        {
            Caption = 'Request Date';
            DataClassification = CustomerContent;
        }

        field(31; "Request Time"; Time)
        {
            Caption = 'Request Time';
            DataClassification = CustomerContent;
        }
        field(40; "Print Log"; Boolean)
        {
            CalcFormula = exist("MOB Print Log" where("Message ID" = field("Message ID")));
            Caption = 'Print Log';
            BlankZero = true;
            Editable = false;
            FieldClass = FlowField;
        }
        field(50; "Processing Duration"; Duration)
        {
            Caption = 'Processing Duration';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(Key1; "Message ID")
        {
        }
        key(Key2; Status, "Process Type", "Created Date/Time")
        {
            ObsoleteReason = 'Field Process Type removed';
            ObsoleteState = Removed;
            ObsoleteTag = 'MOB5.35';
        }
        key(Key3; "Created Date/Time", Status, "Document Type", "Mobile User ID")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Message ID", "Document Type", Status)
        {
        }
    }

    var
        MobToolbox: Codeunit "MOB Toolbox";
        MobXmlMgt: Codeunit "MOB XML Management";
        MobSessionData: Codeunit "MOB SessionData";
        NoXmlAvailableErr: Label 'No XML is available.';
        StatusOnManualProcessErr: Label 'Only documents with the status New or Error can be processed manually.';
        StatusOnDeleteErr: Label 'Only documents with the status New, Completed or Error can be deleted.';
        MUST_BE_TEMPORARY_Err: Label 'Internal error: %1 must be a temporary record.', Locked = true;

    internal procedure ProcessDocument(var _MobDocQueue: Record "MOB Document Queue")
    var
        MobDocMgt: Codeunit "MOB Document Management";
    begin
        if _MobDocQueue.Status in [_MobDocQueue.Status::Error, _MobDocQueue.Status::New] then
            MobDocMgt.ProcessDocumentManual(_MobDocQueue)
        else
            Error(StatusOnManualProcessErr);
    end;

    internal procedure ResetDocument(var _MobDocQueue: Record "MOB Document Queue")
    var
        MobDocMgt: Codeunit "MOB Document Management";
    begin
        MobDocMgt.ResetDocument(_MobDocQueue);
    end;

    internal procedure DeleteDocument(var _MobDocQueue: Record "MOB Document Queue")
    var
        MobDocMgt: Codeunit "MOB Document Management";
    begin
        if _MobDocQueue.Status in [_MobDocQueue.Status::New, _MobDocQueue.Status::Error, _MobDocQueue.Status::Completed] then
            MobDocMgt.DeleteDocument(_MobDocQueue)
        else
            Error(StatusOnDeleteErr);
    end;

    internal procedure ShowXMLRequestDoc()
    var
        XmlDoc: XmlDocument;
        ToFile: Text[1024];
        Stream: InStream;
    begin
        if LoadXMLRequestDoc(XmlDoc) then begin

            Rec."Request XML".CreateInStream(Stream);
            ToFile := 'Request.xml';
            DownloadFromStream(Stream, '', '', '', ToFile);
        end else
            Error(NoXmlAvailableErr);

    end;

    internal procedure ShowXMLResponseDoc()
    var
        XmlDoc: XmlDocument;
        ToFile: Text[1024];
        Stream: InStream;
    begin
        if LoadXMLResponseDoc(XmlDoc) then begin

            Rec."Answer XML".CreateInStream(Stream);
            ToFile := 'Response.xml';
            DownloadFromStream(Stream, '', '', '', ToFile);
        end else
            Error(NoXmlAvailableErr);

    end;

    internal procedure ShowRegistrations()
    var
        MobWmsRegistration: Record "MOB WMS Registration";
    begin
        MobWmsRegistration.SetCurrentKey("Posting MessageId");
        MobWmsRegistration.SetRange("Posting MessageId", MessageIDAsGuid());
        Page.Run(Page::"MOB WMS Registration List", MobWmsRegistration);
    end;

    procedure LoadXMLRequestDoc(var _XmlDoc: XmlDocument): Boolean
    var
        XmlInStream: InStream;
    begin
        if not MobXmlMgt.DocIsNull(_XmlDoc) then
            Clear(_XmlDoc);

        CalcFields("Request XML");
        if "Request XML".HasValue() then begin
            "Request XML".CreateInStream(XmlInStream);

            MobXmlMgt.GetDocDocElement(_XmlDoc);
            MobXmlMgt.DocReadStream(_XmlDoc, XmlInStream);
            exit(not MobXmlMgt.DocIsNull(_XmlDoc));

        end;
    end;

    procedure LoadXMLResponseDoc(var _XmlDoc: XmlDocument): Boolean
    var
        XMLInStream: InStream;
    begin
        if not MobXmlMgt.DocIsNull(_XmlDoc) then
            Clear(_XmlDoc);

        CalcFields("Answer XML");
        if "Answer XML".HasValue() then begin
            "Answer XML".CreateInStream(XMLInStream);

            MobXmlMgt.GetDocDocElement(_XmlDoc);
            MobXmlMgt.DocReadStream(_XmlDoc, XMLInStream);
            exit(not MobXmlMgt.DocIsNull(_XmlDoc));
        end;
    end;

    procedure LoadAdhocRequestValues(var _TempRequestValues: Record "MOB NS Request Element")
    var
        MobRequestMgt: Codeunit "MOB NS Request Management";
        XmlRequestDoc: XmlDocument;
    begin
        if not _TempRequestValues.IsTemporary() then
            Error(MUST_BE_TEMPORARY_Err, _TempRequestValues.TableCaption());

        LoadXMLRequestDoc(XmlRequestDoc);
        MobRequestMgt.SaveAdhocRequestValues(XmlRequestDoc, _TempRequestValues);
    end;

    internal procedure SaveXMLRequestDoc(var _XmlDoc: XmlDocument): Boolean
    var
        XmlOutStream: OutStream;
    begin

        if MobXmlMgt.DocIsNull(_XmlDoc) then
            exit(false);

        "Request XML".CreateOutStream(XmlOutStream);
        MobXmlMgt.DocSaveStream(_XmlDoc, XmlOutStream);
        "Created Date/Time" := CurrentDateTime();
        exit(true);
    end;

    internal procedure SaveXMLResponseDoc(var _XmlDom: XmlDocument): Boolean
    var
        XmlOutStream: OutStream;
        StartDateTime: DateTime;
    begin
        if MobXmlMgt.DocIsNull(_XmlDom) then
            exit(false);

        Clear("Answer XML");
        "Answer XML".CreateOutStream(XmlOutStream);
        MobXmlMgt.DocSaveStream(_XmlDom, XmlOutStream);
        Modify(); // To prohibit CalcFields overwriting if Mob Doc Queue record has an existing "Answer XML" value
        CalcFields("Answer XML"); // This CalcField is required to ensure correct value in Answer XML
        "Answer Date/Time" := CurrentDateTime();

        StartDateTime := MobSessionData.GetProcessingStartDateTime();
        if StartDateTime <> 0DT then
            "Processing Duration" := "Answer Date/Time" - StartDateTime; // Prevent error if the session data is not set

        exit(true);
    end;

    /// <summary>
    /// Remove image (Base64) data from GetMedia response and PostMedia request, in order to save storage space
    /// </summary>
    procedure ReduceImageData()
    var
        XmlDoc: XmlDocument;
    begin
        case "Document Type" of
            'GetMedia':
                begin
                    LoadXMLResponseDoc(XmlDoc);
                    ReduceDataInNode(XmlDoc, 'image');
                    Clear("Answer XML");
                    SaveXMLResponseDoc(XmlDoc);
                end;

            'PostMedia':
                begin
                    LoadXMLRequestDoc(XmlDoc);
                    ReduceDataInNode(XmlDoc, 'Data');
                    Clear("Request XML");
                    SaveXMLRequestDoc(XmlDoc);
                end;
        end;
    end;

    /// <summary>
    /// Creates an XmlElement that contains limited data from an image in order to save space.
    /// </summary>
    internal procedure ReduceDataInNode(_XmlDoc: XmlDocument; _NodeName: Text)
    var
        XmlRootNode: XmlNode;
        ReplaceXmlNode: XmlNode;
        NewXmlElement: XmlElement;
        ImageId: Text;
    begin
        MobXmlMgt.GetDocRootNode(_XmlDoc, XmlRootNode);

        if XmlRootNode.SelectSingleNode(StrSubstNo('//*[local-name() = "%1"]', _NodeName), ReplaceXmlNode) then begin
            NewXmlElement := XmlElement.Create(_NodeName, XmlRootNode.AsXmlElement().NamespaceUri(), CopyStr(ReplaceXmlNode.AsXmlElement().InnerText(), 1, 80) + '...image data is limited to save storage space');
            if MobXmlMgt.GetAttribute(ReplaceXmlNode, 'id', ImageId) then
                NewXmlElement.SetAttribute('id', ImageId);

            // Replace node
            ReplaceXmlNode.AsXmlElement().ReplaceWith(NewXmlElement);
        end;
    end;

    procedure MessageIDAsGuid(): Guid
    begin
        exit(Format("Message ID"));
    end;

    /// <summary>
    /// Get the entry matching the MessageId from on base tables i.e. during MOB posting events
    /// </summary>
    procedure GetByGuid(_MessageId: Guid; var _MobDocumentQueue: Record "MOB Document Queue"): Boolean
    begin
        exit(_MobDocumentQueue.Get(MobToolbox.ConvertGUIDtoCode100(_MessageId)));
    end;

    /// <summary>
    /// Return the WorkDate to use according to "Use Mobile DateTime Settings" on "Mob Setup" table
    /// </summary>
    procedure GetCalculatedWorkDate(): Date
    var
        MobSetup: Record "MOB Setup";
    begin
        MobSetup.Get();
        if MobSetup."Use Mobile DateTime Settings" then
            exit(Rec."Request Date")
        else
            exit(DT2Date(Rec."Created Date/Time"));
    end;

    /// <summary>
    /// Return the WorkTime to use according to "Use Mobile DateTime Settings" on "Mob Setup" table
    /// </summary>
    procedure GetCalculatedWorkTime(): Time
    var
        MobSetup: Record "MOB Setup";
    begin
        MobSetup.Get();
        if MobSetup."Use Mobile DateTime Settings" then
            exit(Rec."Request Time")
        else
            exit(DT2Time(Rec."Created Date/Time"));
    end;

    internal procedure GetRequestTimeZoneOffSet(): Text
    var
        XmlRequestDoc: XmlDocument;
        XmlRootNode: XmlNode;
        CreatedDateTimeText: Text;
    begin
        LoadXMLRequestDoc(XmlRequestDoc);
        MobXmlMgt.GetDocRootNode(XmlRequestDoc, XmlRootNode);
        if MobXmlMgt.GetAttribute(XmlRootNode, 'created', CreatedDateTimeText) then
            if CreatedDateTimeText.Contains('T') and (StrLen(CreatedDateTimeText) > 20) then
                exit(CopyStr(CreatedDateTimeText, 20, 6)) // i.e 'Z' or '+02:00'
            else
                exit('');
    end;

    /// <summary>
    /// Update the registration type field on the document queue record for better traceability
    /// Simple validation if RegistrationTypeTracking is already set to 'RegistrationType' to avoid adding the info twice (backwards compatibility)
    /// The values are saved to the Mob Document Queue even on error (when processed from Mob WS Dispatcher)
    /// </summary>
    /// <param name="_RegistrationType">Registration Type (if any), leave blank if processing a Document Type with no associated RegistrationType(s)</param>
    /// <param name="_RegistrationTypeTracking">Text string to log. Is reworked in the function if associated RegistrationType is not included in the text</param>
    procedure SetRegistrationTypeAndTracking(_RegistrationType: Text; _RegistrationTypeTracking: Text)
    var
        NewRegistrationType: Text;
    begin
        case true of
            _RegistrationType = '':
                NewRegistrationType := _RegistrationTypeTracking;
            _RegistrationTypeTracking = '',
            _RegistrationTypeTracking = _RegistrationType:
                NewRegistrationType := _RegistrationType;
            (not _RegistrationTypeTracking.Contains(_RegistrationType)):
                NewRegistrationType := _RegistrationType + ': ' + _RegistrationTypeTracking;
            else
                NewRegistrationType := _RegistrationTypeTracking;
        end;

        Validate("Registration Type", CopyStr(NewRegistrationType, 1, MaxStrLen("Registration Type")));

        // Push values to be restored from buffer on error (used by Mob WS Dispatcher)
        MobSessionData.SetRegistrationTypeAndTracking(_RegistrationType, _RegistrationTypeTracking);
    end;

    //
    // ----- Helper functions -----
    //

    internal procedure GetRequestXMLAsText() ReturnXMLAsText: Text
    var
        IStream: InStream;
    begin
        Rec.CalcFields("Request XML");
        Rec."Request XML".CreateInStream(IStream, TextEncoding::UTF8); // Response XML Encoding is always UTF-8, so reading must also be UTF-8
        MobToolbox.TryReadXmlAsTextWithSeparator(IStream, MobToolbox.LFSeparator(), ReturnXMLAsText);
    end;

    internal procedure GetResponseXMLAsText() ReturnXMLAsText: Text
    var
        IStream: InStream;
    begin
        Rec.CalcFields("Answer XML");
        Rec."Answer XML".CreateInStream(IStream, TextEncoding::UTF8); // Response XML Encoding is always UTF-8, so reading must also be UTF-8
        MobToolbox.TryReadXmlAsTextWithSeparator(IStream, MobToolbox.LFSeparator(), ReturnXMLAsText);
    end;
}
