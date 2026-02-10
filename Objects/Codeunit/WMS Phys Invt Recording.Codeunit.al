codeunit 81401 "MOB WMS Phys Invt Recording"
{
    Access = Public;
    TableNo = "MOB Document Queue";

    trigger OnRun()
    begin
        MobDocQueue := Rec;

        case Rec."Document Type" of

            // Order headers
            'GetPhysInvtRecordings':
                GetPhysInvtRecordings();

            // Order lines
            'GetPhysInvtRecordingLines':
                GetPhysInvtRecordingLines();

            // Posting
            'PostPhysInvtRecording':
                PostPhysInvtRecording();

            else
                Error(MobWmsLanguage.GetMessage('NO_DOC_HANDLER'), Rec."Document Type");
        end;

        // Store the result in the queue and update the status
        MobToolbox.UpdateResult(Rec, XmlResponseDoc);
    end;

    var
        MobDocQueue: Record "MOB Document Queue";
        MobSessionData: Codeunit "MOB SessionData";
        MobRequestMgt: Codeunit "MOB NS Request Management";
        MobXmlMgt: Codeunit "MOB XML Management";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
        MobToolbox: Codeunit "MOB Toolbox";
        MobItemReferenceMgt: Codeunit "MOB Item Reference Mgt.";
        XmlResponseDoc: XmlDocument;
        PHYS_INVT_RECORDING_HEADER_Txt: Label 'PhysInvtRecordingCfgHeader', Locked = true;
        ADD_PHYS_INVT_RECORD_LINE_HEADER_Txt: Label 'AddPhysInvtRecordLineHeader', Locked = true;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Setup Doc. Types", 'OnAfterCreateDefaultDocumentTypes', '', true, true)]
    local procedure OnAfterCreateDefaultDocumentTypes()
    var
        MobWmsSetupDocTypes: Codeunit "MOB WMS Setup Doc. Types";
    begin
        MobWmsSetupDocTypes.CreateDocumentType('GetPhysInvtRecordings', '', Codeunit::"MOB WMS Phys Invt Recording");
        MobWmsSetupDocTypes.CreateDocumentType('GetPhysInvtRecordingLines', '', Codeunit::"MOB WMS Phys Invt Recording");
        MobWmsSetupDocTypes.CreateDocumentType('PostPhysInvtRecording', '', Codeunit::"MOB WMS Phys Invt Recording");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Setup Doc. Types", 'OnAfterCreateDefaultMenuOptions', '', true, true)]
    local procedure OnAfterCreateDefaultMenuOptions()
    var
        MobWmsSetupDocTypes: Codeunit "MOB WMS Setup Doc. Types";
    begin
        MobWmsSetupDocTypes.CreateMobileMenuOptionAndAddToMobileGroup('PhysInvtRecording', 'WMS', 450);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Reference Data", 'OnGetReferenceData_OnAddHeaderConfigurations', '', true, true)]
    local procedure OnGetReferenceData_OnAddHeaderConfigurations(var _HeaderFields: Record "MOB HeaderField Element")
    begin
        AddHeaderConfiguration_PhysInvtRecordingCfgHeader(_HeaderFields);
        AddHeaderConfiguration_AddPhysInvtRecordLineHeader(_HeaderFields);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Adhoc Registr.", 'OnGetRegistrationConfiguration_OnAddSteps', '', true, true)]
    local procedure OnGetRegistrationConfiguration_OnAddSteps(_RegistrationType: Text; var _HeaderFieldValues: Record "MOB NS Request Element"; var _Steps: Record "MOB Steps Element"; var _RegistrationTypeTracking: Text)
    begin
        if _RegistrationType = MobWmsToolbox."CONST::AddPhysInvtRecordLine"() then
            _RegistrationTypeTracking := CreateAddPhysInvtRecordLineColConf(_HeaderFieldValues, _Steps);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Adhoc Registr.", 'OnPostAdhocRegistrationOnCustomRegistrationType', '', true, true)]
    local procedure OnPostAdhocRegistrationOnCustomRegistrationType(_RegistrationType: Text; var _RequestValues: Record "MOB NS Request Element"; var _SuccessMessage: Text; var _RegistrationTypeTracking: Text; var _IsHandled: Boolean)
    begin
        if _RegistrationType = MobWmsToolbox."CONST::AddPhysInvtRecordLine"() then begin
            if _IsHandled then
                exit;

            PostAddPhysInvtRecordLineRegistration(_RequestValues, _SuccessMessage, _RegistrationTypeTracking);

            _IsHandled := true;
        end;
    end;

    local procedure GetPhysInvtRecordings()
    var
        TempHeaderElement: Record "MOB NS BaseDataModel Element" temporary;
        XmlRequestDoc: XmlDocument;
        OrdersXmlResponseData: XmlNode;
    begin
        // Process:
        // 1. Filter and sort the Phys. Inventory Recordings for this particular user
        // 2. Save the result in XML and return it to the mobile device        

        // Load the request from the queue
        MobDocQueue.LoadXMLRequestDoc(XmlRequestDoc);

        // Initialize the response document for order data
        MobToolbox.InitializeResponseDoc(XmlResponseDoc, OrdersXmlResponseData);

        // Create the response for the mobile device
        CreatePhysInvtRecordingsResponse(XmlRequestDoc, TempHeaderElement);

        // Add collected buffer values to new <Orders> nodes
        AddBaseOrderElements(OrdersXmlResponseData, TempHeaderElement);
    end;

    local procedure CreatePhysInvtRecordingsResponse(var _XmlRequestDoc: XmlDocument; var _BaseOrderElement: Record "MOB NS BaseDataModel Element")
    var
        MobUser: Record "MOB User";
        PhysInvtRecordHeader: Record "Phys. Invt. Record Header";
        PhysInvtRecordLine: Record "Phys. Invt. Record Line";
        TempPhysInvtRecordHeader: Record "Phys. Invt. Record Header" temporary;
        TempHeaderFilter: Record "MOB NS Request Element" temporary;
        IsHandled: Boolean;
        ScannedValue: Text;
    begin
        /// <summary>
        /// Loop through the Phys. Invt. Recordings and add the information that should be available
        /// on the mobile device to the XML. The only elements that MUST be present in the XML are "BackendID", "Status" and "Sorting".
        /// Other values can be added freely and used in Mobile WMS by referencing the element name from the XML.
        /// </summary>

        // Mandatory Header filters for this function to operate
        PhysInvtRecordHeader.SetRange(Status, PhysInvtRecordHeader.Status::Open);

        // Mandatory Line filters 
        PhysInvtRecordLine.SetFilter("Item No.", '<>%1', '');

        // XML filter data into Temporary table
        MobRequestMgt.SaveHeaderFilters(_XmlRequestDoc, TempHeaderFilter);

        if TempHeaderFilter.FindSet() then
            repeat
                //
                // Event to allow for handling (custom) filters
                //
                IsHandled := false;
                OnGetPhysInvtRecordings_OnSetFilterPhysInvtRecordHeader(TempHeaderFilter, PhysInvtRecordHeader, PhysInvtRecordLine, IsHandled);

                if not IsHandled then
                    case TempHeaderFilter.Name of

                        'Location':
                            if TempHeaderFilter."Value" = 'All' then
                                PhysInvtRecordHeader.SetFilter("Location Code", MobWmsToolbox.GetLocationFilter(UserId())) // All locations for this user
                            else
                                PhysInvtRecordHeader.SetRange("Location Code", TempHeaderFilter."Value");

                        'AssignedUser':
                            begin
                                MobUser.Get(UserId());
                                case TempHeaderFilter."Value" of
                                    'All':
                                        ; // No filter -> do nothing
                                    'OnlyMine':
                                        if MobUser."Employee No." <> '' then
                                            PhysInvtRecordHeader.SetRange("Person Responsible", MobUser."Employee No.")  // Set the filter to the current user
                                        else
                                            PhysInvtRecordHeader.SetRange("Person Responsible", '22e35d32-8aa2-4181-8'); // Empty list
                                    'MineAndUnassigned':
                                        PhysInvtRecordHeader.SetFilter("Person Responsible", '''''|%1', MobUser."Employee No."); // Current user or blank
                                end;
                            end;

                        'ScannedValue':
                            ScannedValue := TempHeaderFilter."Value";   // Used for filtering OrderNo or Item/Variant later
                    end;

            until TempHeaderFilter.Next() = 0;

        // Run event once more with Empty "Header filter" to allow for additional filtering directly on the records, NOT related to specific Header filter
        IsHandled := false;
        TempHeaderFilter.ClearFields();
        OnGetPhysInvtRecordings_OnSetFilterPhysInvtRecordHeader(TempHeaderFilter, PhysInvtRecordHeader, PhysInvtRecordLine, IsHandled);

        // Filter: OrderNo or Item/Variant (match for scanned order no. at location takes precedence over other filters)
        if ScannedValue <> '' then
            SetFilterForPhysInvtRecording(PhysInvtRecordHeader, PhysInvtRecordLine, ScannedValue);

        // Insert orders into temp rec
        CopyFilteredPhysInvtRecordHeaderToTempRecord(PhysInvtRecordHeader, PhysInvtRecordLine, TempHeaderFilter, TempPhysInvtRecordHeader);

        // Respond with resulting orders
        CreatePhysInvtRecordHeaderResponse(TempPhysInvtRecordHeader, _BaseOrderElement);
    end;

    /// <summary>
    /// Filter OrderNo or Item/Variant by _ScannedValue (match for scanned order no. takes precedence over other filters)
    /// </summary>
    procedure SetFilterForPhysInvtRecording(var _PhysInvtRecordHeader: Record "Phys. Invt. Record Header"; var PhysInvtRecordLine: Record "Phys. Invt. Record Line"; _ScannedValue: Text)
    var
        MobScannedValueMgt: Codeunit "MOB ScannedValue Mgt.";
        ItemNumber: Code[50];
        VariantCode: Code[10];
    begin
        case true of
            SearchPhysInvtRecordHeader(_ScannedValue, _PhysInvtRecordHeader):
                ReplaceFilterPhysInvtRecordHeader(_PhysInvtRecordHeader, _ScannedValue);
            MobScannedValueMgt.SearchItemReference(_ScannedValue, ItemNumber, VariantCode):
                begin
                    PhysInvtRecordLine.SetRange("Item No.", ItemNumber); // Narrow the filter from <>'' to a specific ItemNo
                    if VariantCode <> '' then
                        PhysInvtRecordLine.SetRange("Variant Code", VariantCode);
                end;
            else
                _PhysInvtRecordHeader.SetRange("Order No.", '22e35d32-8aa2-4181-8'); // Empty list
        end;
    end;

    /// <summary>
    /// Search Phys. Invt. Recording by OrderNo and within current Location/Status-filter (but ignoring other filters)
    /// </summary>
    local procedure SearchPhysInvtRecordHeader(_ScannedValue: Text; var _FilteredPhysInvtRecordHeader: Record "Phys. Invt. Record Header"): Boolean
    var
        PhysInvtRecordHeader2: Record "Phys. Invt. Record Header";
    begin
        if (_ScannedValue = '') or (not MobToolbox.IsValidExpressionLen(_ScannedValue, MaxStrLen(PhysInvtRecordHeader2."Order No."))) then
            exit(false);

        PhysInvtRecordHeader2.Copy(_FilteredPhysInvtRecordHeader);
        ReplaceFilterPhysInvtRecordHeader(PhysInvtRecordHeader2, _ScannedValue);
        if PhysInvtRecordHeader2.FindFirst() then begin
            _FilteredPhysInvtRecordHeader := PhysInvtRecordHeader2;
            exit(true);
        end;

        exit(false);
    end;

    /// <summary>
    /// Set new filter for only OrderNo and current Location/Status-filter (ignoring all other filters)
    /// </summary>
    local procedure ReplaceFilterPhysInvtRecordHeader(var _PhysInvtRecordHeader: Record "Phys. Invt. Record Header"; _ScannedValue: Text): Boolean
    var
        PhysInvtRecordHeader2: Record "Phys. Invt. Record Header";
    begin
        PhysInvtRecordHeader2.Copy(_PhysInvtRecordHeader);

        _PhysInvtRecordHeader.Reset();
        _PhysInvtRecordHeader.SetFilter("Order No.", _ScannedValue);
        PhysInvtRecordHeader2.CopyFilter("Location Code", _PhysInvtRecordHeader."Location Code");
        PhysInvtRecordHeader2.CopyFilter(Status, _PhysInvtRecordHeader.Status);
    end;

    /// <summary>
    /// Transfer possibly filtered orders into temp record
    /// </summary>
    local procedure CopyFilteredPhysInvtRecordHeaderToTempRecord(var _PhysInvtRecordHeaderView: Record "Phys. Invt. Record Header"; var _PhysInvtRecordLineView: Record "Phys. Invt. Record Line"; var _HeaderFilters: Record "MOB NS Request Element"; var _TempPhysInvtRecordHeader: Record "Phys. Invt. Record Header")
    var
        IncludeInOrderList: Boolean;
    begin
        if _PhysInvtRecordHeaderView.FindSet() then
            repeat
                // Insert Only if lines exist
                _PhysInvtRecordLineView.SetRange("Order No.", _PhysInvtRecordHeaderView."Order No.");
                _PhysInvtRecordLineView.SetRange("Recording No.", _PhysInvtRecordHeaderView."Recording No.");
                _PhysInvtRecordLineView.SetRange(Recorded, false);
                IncludeInOrderList := not _PhysInvtRecordLineView.IsEmpty();

                // Verify additional conditions from eventsubscribers
                if IncludeInOrderList then
                    OnGetPhysInvtRecordings_OnIncludePhysInvtRecordHeader(_PhysInvtRecordHeaderView, _HeaderFilters, IncludeInOrderList);

                if IncludeInOrderList then begin
                    _TempPhysInvtRecordHeader.Copy(_PhysInvtRecordHeaderView);
                    _TempPhysInvtRecordHeader.Insert();
                end;
            until _PhysInvtRecordHeaderView.Next() = 0;
    end;

    local procedure CreatePhysInvtRecordHeaderResponse(var _PhysInvtRecordHeader: Record "Phys. Invt. Record Header"; var _BaseOrderElement: Record "MOB NS BaseDataModel Element")
    begin
        if _PhysInvtRecordHeader.FindSet() then
            repeat
                _BaseOrderElement.Create();
                SetFromPhysInvtRecordHeader(_PhysInvtRecordHeader, _BaseOrderElement);
                _BaseOrderElement.Save();
            until _PhysInvtRecordHeader.Next() = 0;
    end;

    local procedure GetPhysInvtRecordingLines()
    var
        TempRequestValues: Record "MOB NS Request Element" temporary;
        XmlRequestDoc: XmlDocument;
        BackendID: Code[40];
    begin
        // We want to extract the BackendID (Recording No. + Order No.) from the XML to get the order lines

        // Load the request document from the document queue
        MobDocQueue.LoadXMLRequestDoc(XmlRequestDoc);

        // Get the <BackendID> element
        MobRequestMgt.SaveAdhocRequestValues(XmlRequestDoc, TempRequestValues);
        BackendID := TempRequestValues.GetValue('BackendID', true);

        // Create the response for the mobile device
        CreatePhysInvtRecordLinesResponse(BackendID);

    end;

    local procedure CreatePhysInvtRecordLinesResponse(_BackendID: Code[40])
    var
        MobSetup: Record "MOB Setup";
        PhysInvtRecordHeader: Record "Phys. Invt. Record Header";
        PhysInvtRecordLine: Record "Phys. Invt. Record Line";
        TempBaseOrderLineElement: Record "MOB NS BaseDataModel Element" temporary;
        XmlResponseData: XmlNode;
        IncludeInOrderLines: Boolean;
        OrderNo: Code[20];
        RecordingNo: Integer;
    begin
        // Description:
        // Get the order lines for the requested order.
        // Sort the lines.
        // Create the response XML

        MobSetup.Get();

        // Initialize the response document for order line data
        MobToolbox.InitializeOrderLineDataRespDoc(XmlResponseDoc, XmlResponseData);

        // Extract the Order No and Recording No. from the BackendID
        MobWmsToolbox.GetOrderNoAndRecordingNoFromBackendId(_BackendID, OrderNo, RecordingNo);

        // Filter the lines for this particular order
        case MobSetup."Sort Order Count" of
            MobSetup."Sort Order Count"::Item:
                PhysInvtRecordLine.SetCurrentKey("Order No.", "Item No.", "Variant Code", "Location Code", "Bin Code");
            MobSetup."Sort Order Count"::Bin:
                PhysInvtRecordLine.SetCurrentKey("Order No.", "Recording No.", "Location Code", "Bin Code");
            MobSetup."Sort Order Count"::Worksheet:
                ; // Keep primary key sorting
        end;

        PhysInvtRecordLine.SetRange("Order No.", OrderNo);
        PhysInvtRecordLine.SetRange("Recording No.", RecordingNo);
        PhysInvtRecordLine.SetRange(Recorded, false);

        // Event to expose Lines for filtering before Response
        OnGetPhysInvtRecordingLines_OnSetFilterPhysInvtRecordLine(PhysInvtRecordLine);

        // Insert the values from the header in the XML
        if PhysInvtRecordLine.FindSet() then begin

            // Add collectorSteps to be displayed on posting
            PhysInvtRecordHeader.Get(OrderNo, RecordingNo);
            AddStepsToPhysInvtRecordHeader(PhysInvtRecordHeader, XmlResponseDoc, XmlResponseData);

            repeat
                // Verify addtional conditions from eventsubscribers
                IncludeInOrderLines := true;
                OnGetPhysInvtRecordingLines_OnIncludePhysInvtRecordLine(PhysInvtRecordLine, IncludeInOrderLines);

                if IncludeInOrderLines then begin
                    // Add the data to the order line element
                    TempBaseOrderLineElement.Create();
                    SetFromPhysInvtRecordingLine(PhysInvtRecordLine, TempBaseOrderLineElement, _BackendID);
                    TempBaseOrderLineElement.Save();
                end;
            until PhysInvtRecordLine.Next() = 0;
        end;

        AddBaseOrderLineElements(XmlResponseData, TempBaseOrderLineElement);
    end;

    local procedure AddStepsToPhysInvtRecordHeader(_PhysInvtRecordHeader: Record "Phys. Invt. Record Header"; _XmlResponseDoc: XmlDocument; var _XmlResponseData: XmlNode)
    var
        TempSteps: Record "MOB Steps Element" temporary;
        XmlSteps: XmlNode;
    begin
        TempSteps.SetMustCallCreateNext(true);
        OnGetPhysInvtRecordingLines_OnAddStepsToPhysInvtRecordHeader(_PhysInvtRecordHeader, TempSteps);

        if not TempSteps.IsEmpty() then begin
            // Adds Collector Configuration with <steps> {<add ... />} <steps/>
            MobToolbox.AddCollectorConfiguration(_XmlResponseDoc, _XmlResponseData, XmlSteps);
            MobXmlMgt.AddStepsaddElements(XmlSteps, TempSteps);
        end;
    end;

    local procedure PostPhysInvtRecording()
    var
        MobUser: Record "MOB User";
        MobRegistration: Record "MOB WMS Registration";
        PhysInvtRecordHeader: Record "Phys. Invt. Record Header";
        PhysInvtRecordLine: Record "Phys. Invt. Record Line";
        TempOrderValues: Record "MOB Common Element" temporary;
        TempSteps: Record "MOB Steps Element" temporary;
        XmlRequestDoc: XmlDocument;
        BackendID: Code[40];
        OrderNo: Code[20];
        RecordingNo: Integer;
    begin
        // Disable the locktimeout to prevent timeout messages on the mobile device
        LockTimeout(false);

        // Load the request document from the document queue
        MobDocQueue.LoadXMLRequestDoc(XmlRequestDoc);
        MobRequestMgt.InitCommonFromXmlOrderNode(XmlRequestDoc, TempOrderValues);

        // Turn on commit protection to prevent unintentional committing data
        MobDocQueue.Consistent(false);

        // Save the registrations from the XML in the Mobile WMS Registration table
        MobWmsToolbox.SaveRegistrationData(MobDocQueue.MessageIDAsGuid(), XmlRequestDoc, MobRegistration.Type::"Phys. Invt. Recording");

        // Get the backendID from Request
        Evaluate(BackendID, TempOrderValues.GetValue('backendID', true));

        // Extract the Order No and Recording No. from the BackendID
        MobWmsToolbox.GetOrderNoAndRecordingNoFromBackendId(BackendID, OrderNo, RecordingNo);

        // Lock the tables to work on
        PhysInvtRecordHeader.LockTable();
        PhysInvtRecordLine.LockTable();
        MobRegistration.LockTable();

        // Make sure that the order still exists
        if not PhysInvtRecordHeader.Get(OrderNo, RecordingNo) then
            Error(MobWmsLanguage.GetMessage('UNKNOWN_ORDER'), OrderNo);

        MobUser.Get(UserId());
        if MobUser."Employee No." <> '' then
            PhysInvtRecordHeader.Validate("Person Recorded", MobUser."Employee No.")
        else
            PhysInvtRecordHeader.Validate("Person Recorded", CopyStr(MobUser."User ID", 1, MaxStrLen(PhysInvtRecordHeader."Person Recorded")));

        PhysInvtRecordHeader.Validate("Date Recorded", MobDocQueue.GetCalculatedWorkDate());
        PhysInvtRecordHeader.Validate("Time Recorded", MobDocQueue.GetCalculatedWorkTime());

        // OnAddStepsTo IntegrationEvents
        OnPostPhysInvtRecording_OnAddStepsToPhysInvtRecording(TempOrderValues, PhysInvtRecordHeader, TempSteps);
        if not TempSteps.IsEmpty() then begin
            MobSessionData.SetRegistrationTypeTracking('OnAddStepsTo');
            MobWmsToolbox.DeleteRegistrationData(MobDocQueue.MessageIDAsGuid());
            MobToolbox.CreateResponseWithSteps(XmlResponseDoc, TempSteps);
            MobDocQueue.Consistent(true);
            exit;
        end;

        // OnBeforePost IntegrationEvents        
        OnPostPhysInvtRecording_OnBeforePostPhysInvtRecording(TempOrderValues, PhysInvtRecordHeader);

        PhysInvtRecordHeader.Modify(true);

        MobRegistration.SetRange("Posting MessageId", MobDocQueue.MessageIDAsGuid());
        MobRegistration.SetRange(Type, MobRegistration.Type::"Phys. Invt. Recording");
        // The registration is saved with the prefix so here we use the BackendID variable
        MobRegistration.SetRange("Order No.", OrderNo);
        MobRegistration.SetRange("Phys. Invt. Recording No.", RecordingNo);

        // Iterate Lines
        PhysInvtRecordLine.SetRange("Order No.", OrderNo);
        PhysInvtRecordLine.SetRange("Recording No.", RecordingNo);
        if PhysInvtRecordLine.FindSet() then
            repeat

                // Try to find the quantity in the registrations
                // Try to find the registrations                
                MobRegistration.SetRange("Line No.", PhysInvtRecordLine."Line No.");
                MobRegistration.SetRange(Handled, false);

                if MobRegistration.FindFirst() then begin
                    PhysInvtRecordLine.TestField(Recorded, false);
                    repeat
                        InsertPhysInvtRecordLine(PhysInvtRecordHeader, PhysInvtRecordLine, MobRegistration);

                        // Set the handled flag to true on the registration
                        MobRegistration.Validate(Handled, true);
                        MobRegistration.Modify();
                    until MobRegistration.Next() = 0;

                    // Delete original Phys. Invt. Record Line
                    PhysInvtRecordLine.Delete();
                end;

            until PhysInvtRecordLine.Next() = 0;

        // Registrations related to deleted Phys. Invt. Record lines must be marked as handled
        MobRegistration.SetRange("Line No.");
        MobRegistration.ModifyAll(Handled, true);

        // if all lines have been recorded, try and finish the recording.
        PhysInvtRecordLine.SetRange(Recorded, false);
        if PhysInvtRecordLine.IsEmpty() then
            Codeunit.Run(Codeunit::"Phys. Invt. Rec.-Finish", PhysInvtRecordHeader);

        // Turn on commit protection off again
        MobDocQueue.Consistent(true);

        // Create a response inside the <description> element of the document response
        MobToolbox.CreateSimpleResponse(XmlResponseDoc, MobWmsLanguage.GetMessage('REG_TRANS_SUCCESS'));
    end;

    local procedure InsertPhysInvtRecordLine(var _PhysInvtRecordHeader: Record "Phys. Invt. Record Header"; var _PhysInvtRecordLine: Record "Phys. Invt. Record Line"; _MobRegistration: Record "MOB WMS Registration")
    var
        PhysInvtRecordLine: Record "Phys. Invt. Record Line";
        MobSetup: Record "MOB Setup";
        Item: Record Item;
        PhysInvtTrackingMgt: Codeunit "Phys. Invt. Tracking Mgt.";
    begin
        MobSetup.Get();

        PhysInvtRecordLine.Init();
        PhysInvtRecordLine.Validate("Order No.", _PhysInvtRecordHeader."Order No.");
        PhysInvtRecordLine.Validate("Recording No.", _PhysInvtRecordHeader."Recording No.");
        PhysInvtRecordLine.Validate("Line No.", GetNextPhysInvtRecordLineNo(_PhysInvtRecordHeader));
        PhysInvtRecordLine.Validate("Item No.", _PhysInvtRecordLine."Item No.");
        PhysInvtRecordLine.Validate("Location Code", _PhysInvtRecordLine."Location Code");
        PhysInvtRecordLine.Validate("Bin Code", _MobRegistration.FromBin);
        PhysInvtRecordLine.Validate("Variant Code", _PhysInvtRecordLine."Variant Code");

        PhysInvtRecordLine.Validate("Serial No.", _MobRegistration.SerialNumber);
        PhysInvtRecordLine.Validate("Lot No.", _MobRegistration.LotNumber);
        /* #if BC24+ */
        PhysInvtRecordLine.Validate("Package No.", _MobRegistration.PackageNumber);
        /* #endif */
        PhysInvtRecordLine.Validate("Unit of Measure Code", _PhysInvtRecordLine."Unit of Measure Code");
        Item.Get(_PhysInvtRecordLine."Item No.");
        if MobSetup."Use Base Unit of Measure" or (_PhysInvtRecordLine."Serial No." <> '') then
            PhysInvtRecordLine.Validate("Quantity (Base)", _MobRegistration.Quantity)
        else
            PhysInvtRecordLine.Validate(Quantity, _MobRegistration.Quantity);
        PhysInvtRecordLine."Use Item Tracking" := PhysInvtTrackingMgt.SuggestUseTrackingLines(Item); // Isn't automatically set in early BC14 versions

        MobWmsToolbox.SaveRegistrationDataFromSource(PhysInvtRecordLine."Location Code", PhysInvtRecordLine."Item No.", PhysInvtRecordLine."Variant Code", _MobRegistration);

        // OnHandleRegistrationFor IntegrationEvent
        OnPostPhysInvtRecording_OnHandleRegistrationForPhysInvtRecordLine(_MobRegistration, PhysInvtRecordLine);
        PhysInvtRecordLine.Insert(true);
    end;

    local procedure GetNextPhysInvtRecordLineNo(var _PhysInvtRecordHeader: Record "Phys. Invt. Record Header"): Integer
    var
        PhysInvtRecordLine: Record "Phys. Invt. Record Line";
    begin
        PhysInvtRecordLine.SetRange("Order No.", _PhysInvtRecordHeader."Order No.");
        PhysInvtRecordLine.SetRange("Recording No.", _PhysInvtRecordHeader."Recording No.");
        if PhysInvtRecordLine.FindLast() then
            exit(PhysInvtRecordLine."Line No." + 10000)
        else
            exit(10000);
    end;

    local procedure AddBaseOrderElements(var _XmlResponseData: XmlNode; var _BaseOrderElement: Record "MOB NS BaseDataModel Element")
    var
        CursorMgt: Codeunit "MOB Cursor Management";
        XmlMgt: Codeunit "MOB XML Management";
    begin
        // store current cursor and sorting
        CursorMgt.Backup(_BaseOrderElement);

        // set sorting to be used for the export, then write to xml
        SetCurrentKeyHeader(_BaseOrderElement);
        XmlMgt.AddNsBaseDataModelBaseOrderElements(_XmlResponseData, _BaseOrderElement);

        // restore cursor and sorting
        CursorMgt.Restore(_BaseOrderElement);
    end;

    local procedure SetCurrentKeyHeader(var _BaseOrderElement: Record "MOB NS BaseDataModel Element")
    var
        TempHeaderElementCustomView: Record "MOB NS BaseDataModel Element" temporary;
    begin
        _BaseOrderElement.SetCurrentKey("Sorting1 (internal)", "Sorting2 (internal)", "Sorting3 (internal)", "Sorting4 (internal)", "Sorting5 (internal)");

        // use new temporary/empty record for integration event to prevent SetFrom from being in effect at this point in time
        TempHeaderElementCustomView.SetView(_BaseOrderElement.GetView());
        OnGetPhysInvtRecordings_OnAfterSetCurrentKey(TempHeaderElementCustomView);
        _BaseOrderElement.SetView(TempHeaderElementCustomView.GetView());
    end;

    local procedure AddBaseOrderLineElements(var _XmlResponseData: XmlNode; var _BaseOrderLineElement: Record "MOB NS BaseDataModel Element")
    var
        CursorMgt: Codeunit "MOB Cursor Management";
        XmlMgt: Codeunit "MOB XML Management";
    begin
        // store current cursor and sorting, then set default sorting to be used for the export
        CursorMgt.Backup(_BaseOrderLineElement);

        // set sorting to be used for the export, then write to xml
        SetCurrentKeyLine(_BaseOrderLineElement);
        XmlMgt.AddNsBaseDataModelBaseOrderLineElements(_XmlResponseData, _BaseOrderLineElement);

        // restore cursor and sorting
        CursorMgt.Restore(_BaseOrderLineElement);
    end;

    local procedure SetCurrentKeyLine(var _BaseOrderLineElement: Record "MOB NS BaseDataModel Element")
    var
        TempBaseOrderLineElementCustomView: Record "MOB NS BaseDataModel Element" temporary;
    begin
        _BaseOrderLineElement.SetCurrentKey("Sorting1 (internal)", "Sorting2 (internal)", "Sorting3 (internal)", "Sorting4 (internal)", "Sorting5 (internal)");

        // use new temporary/empty record for integration event to prevent SetFrom from being in effect at this point in time
        TempBaseOrderLineElementCustomView.SetView(_BaseOrderLineElement.GetView());
        OnGetPhysInvtRecordingLines_OnAfterSetCurrentKey(TempBaseOrderLineElementCustomView);
        _BaseOrderLineElement.SetView(TempBaseOrderLineElementCustomView.GetView());
    end;

    local procedure SetFromPhysInvtRecordHeader(_PhysInvtRecordHeader: Record "Phys. Invt. Record Header"; var _BaseOrder: Record "MOB NS BaseDataModel Element")
    begin
        // Add the data to the order header element        
        _BaseOrder.Init();

        // The journal name is prefixed to determine its type later            
        _BaseOrder.Set_BackendID(CreateBackendIdForPhysInvtRecordHeader(_PhysInvtRecordHeader));

        // Now we add the elements that we want the user to see            
        _BaseOrder.Set_DisplayLine1(_PhysInvtRecordHeader."Order No.");
        _BaseOrder.Set_DisplayLine2(MobWmsLanguage.GetMessage('RECORDING_NO') + ': ' + Format(_PhysInvtRecordHeader."Recording No."));
        _BaseOrder.Set_DisplayLine3(_PhysInvtRecordHeader.Description);
        _BaseOrder.Set_DisplayLine4(_PhysInvtRecordHeader."Person Responsible" <> '', MobWmsLanguage.GetMessage('PERSON_RESPONSIBLE') + ': ' + _PhysInvtRecordHeader."Person Responsible", '');

        _BaseOrder.Set_HeaderLabel1(MobWmsLanguage.GetMessage('ORDER_NUMBER'));
        _BaseOrder.Set_HeaderLabel2(MobWmsLanguage.GetMessage('DESCRIPTION'));
        _BaseOrder.Set_HeaderValue1(_PhysInvtRecordHeader."Order No." + ' - ' + Format(_PhysInvtRecordHeader."Recording No."));
        _BaseOrder.Set_HeaderValue2(_PhysInvtRecordHeader.Description);

        _BaseOrder.Set_ReferenceID(_PhysInvtRecordHeader);
        _BaseOrder.Set_Status();    // Set Locked/Has Attachment symbol (1=Unlocked, 2=Locked, 3=Attachment)

        // Integration Events
        OnGetPhysInvtRecordings_OnAfterSetFromPhysInvtRecordHeader(_PhysInvtRecordHeader, _BaseOrder);
    end;

    local procedure SetFromPhysInvtRecordingLine(_PhysInvtRecordLine: Record "Phys. Invt. Record Line"; var _BaseOrderLine: Record "MOB NS BaseDataModel Element"; _BackendID: Code[40])
    var
        Location: Record Location;
        MobTrackingSetup: Record "MOB Tracking Setup";
        TempSteps: Record "MOB Steps Element" temporary;
        ExpDateRequired: Boolean;
    begin
        // Add the data to the journal line element        
        _BaseOrderLine.Init();

        // Add the data to the order line element
        // Use the OrderNo value because it contains the prefix
        _BaseOrderLine.Set_OrderBackendID(_BackendID);
        _BaseOrderLine.Set_LineNumber(_PhysInvtRecordLine."Line No.");

        // There is no ToBin when counting
        _BaseOrderLine.Set_FromBin(_PhysInvtRecordLine."Bin Code");
        _BaseOrderLine.Set_ToBin('');
        if Location.Get(_PhysInvtRecordLine."Location Code") then
            _BaseOrderLine.Set_ValidateFromBin(Location."Bin Mandatory")
        else
            _BaseOrderLine.Set_ValidateFromBin(false);
        _BaseOrderLine.Set_ValidateToBin(false);

        _BaseOrderLine.Set_Location(Location.Code);

        _BaseOrderLine.Set_ItemNumber(_PhysInvtRecordLine."Item No.");
        _BaseOrderLine.Set_ItemBarcode(MobItemReferenceMgt.GetBarcodeList(_PhysInvtRecordLine."Item No.", _PhysInvtRecordLine."Variant Code", _PhysInvtRecordLine."Unit of Measure Code"));
        _BaseOrderLine.Set_Description(_PhysInvtRecordLine.Description);

        MobTrackingSetup.DetermineSpecificTrackingRequiredFromItemNo(_PhysInvtRecordLine."Item No.", ExpDateRequired);
        MobTrackingSetup.CopyTrackingFromPhysInvtRecordLine(_PhysInvtRecordLine);
        _BaseOrderLine.SetTracking(MobTrackingSetup);
        _BaseOrderLine.SetRegisterTracking(MobTrackingSetup);
        _BaseOrderLine.Set_RegisterExpirationDate(false);

        // If the <RegisterQuantityByScan> element is set to true the mobile device can use values in <BarcodeQuantity>
        // element to register the quantity associated with barcode instead of always registering 1.
        _BaseOrderLine.Set_RegisterQuantityByScan(false);
        _BaseOrderLine.Set_Quantity(_PhysInvtRecordLine.Quantity);
        _BaseOrderLine.Set_UnitOfMeasure(_PhysInvtRecordLine."Unit of Measure Code");
        _BaseOrderLine.Set_RegisteredQuantity('0');

        // Decide what to display on the lines
        // There are 5 display lines available in the standard configuration
        // Line 1: Show the Bin
        // Line 2: Show the Item Number + UoM under the quantity (this is handled in the application.cfg file on the mobile device)
        // Line 3: Show the Item Description
        // Line 4: Show the Serial/Lot Info
        // Line 5: Show the Item Variant
        _BaseOrderLine.Set_DisplayLine1(_PhysInvtRecordLine."Bin Code");
        _BaseOrderLine.Set_DisplayLine2(_PhysInvtRecordLine."Item No.");
        _BaseOrderLine.Set_DisplayLine3(_PhysInvtRecordLine.Description);
        _BaseOrderLine.Set_DisplayLine4(MobTrackingSetup.FormatTracking());
        _BaseOrderLine.Set_DisplayLine5(_PhysInvtRecordLine."Variant Code" <> '', MobWmsLanguage.GetMessage('VARIANT_LABEL') + ': ' + _PhysInvtRecordLine."Variant Code", '');

        // Bin Change not allowed when counting
        _BaseOrderLine.Set_AllowBinChange(false);

        // The choices are: None, Warn, Block
        _BaseOrderLine.Set_UnderDeliveryValidation('None');
        _BaseOrderLine.Set_OverDeliveryValidation('None');

        _BaseOrderLine.Set_ReferenceID(_PhysInvtRecordLine);
        _BaseOrderLine.Set_Status('0');
        _BaseOrderLine.Set_Attachment();
        _BaseOrderLine.Set_ItemImageID();

        // Integration Events
        OnGetPhysInvtRecordingLines_OnAfterSetFromPhysInvtRecordLine(_PhysInvtRecordLine, _BaseOrderLine);

        TempSteps.SetMustCallCreateNext(true);
        OnGetPhysInvtRecordingLines_OnAddStepsToPhysInvtRecordLine(_PhysInvtRecordLine, _BaseOrderLine, TempSteps);
        if not TempSteps.IsEmpty() then
            _BaseOrderLine.Set_Workflow(TempSteps, "MOB TweakType"::Append);
    end;

    /// <summary>
    /// Get Phys. Invt. Record Header from 'OrderBackendID'
    /// </summary>
    local procedure GetPhysInvtRecordHeader(_OrderBackendID: Code[40]; var _PhysInvtRecordHeader: Record "Phys. Invt. Record Header")
    var
        OrderNo: Code[20];
        RecordingNo: Integer;
    begin
        MobWmsToolbox.GetOrderNoAndRecordingNoFromBackendId(_OrderBackendID, OrderNo, RecordingNo);
        _PhysInvtRecordHeader.Get(OrderNo, RecordingNo);
    end;

    /// <summary>
    /// Create 'BackendID' and 'OrderBackendID' for Phys. Invt. Record Header
    /// </summary>
    local procedure CreateBackendIdForPhysInvtRecordHeader(_PhysInvtRecordHeader: Record "Phys. Invt. Record Header"): Code[40]
    begin
        exit(Format(_PhysInvtRecordHeader."Recording No.") + '-' + _PhysInvtRecordHeader."Order No.");
    end;

    // 
    // ------- Reference Data: -------
    //

    /// <summary>
    /// Filter fields for new 'Phys Inventory Recordings' Order List
    /// </summary>
    local procedure AddHeaderConfiguration_PhysInvtRecordingCfgHeader(var _HeaderConfiguration: Record "MOB HeaderField Element")
    begin
        _HeaderConfiguration.InitConfigurationKey(PHYS_INVT_RECORDING_HEADER_Txt);

        _HeaderConfiguration.Create_ListField_FilterLocationAsLocation(10);
        _HeaderConfiguration.Create_ListField_AssignedUserFilterAsAssignedUser(20);
    end;

    /// <summary>
    /// Header for adding new 'Phys Inventory Recording Order' -line
    /// </summary>
    local procedure AddHeaderConfiguration_AddPhysInvtRecordLineHeader(var _HeaderConfiguration: Record "MOB HeaderField Element")
    begin
        _HeaderConfiguration.InitConfigurationKey(ADD_PHYS_INVT_RECORD_LINE_HEADER_Txt);

        _HeaderConfiguration.Create_TextField_OrderBackendID(10);
        _HeaderConfiguration.Set_locked(true);

        _HeaderConfiguration.Create_TextField_ItemNumberAsItem(20);
    end;

    //
    // ------- Adhoc: -------
    //

    local procedure CreateAddPhysInvtRecordLineColConf(var _HeaderFilter: Record "MOB NS Request Element"; var _Steps: Record "MOB Steps Element") _ReturnRegistrationTypeTracking: Text
    var
        Item: Record Item;
        PhysInvtRecordHeader: Record "Phys. Invt. Record Header";
        LocationCode: Code[10];
        ItemNo: Code[50];
        VariantCode: Code[10];
        UoMCode: Code[10];
    begin
        // Get Order No and Recording No. as Record 
        GetPhysInvtRecordHeader(_HeaderFilter.GetValue('OrderBackendID', true), PhysInvtRecordHeader);

        // Get Location from Recording Header
        LocationCode := PhysInvtRecordHeader."Location Code";

        ItemNo := MobItemReferenceMgt.SearchItemReference(MobToolbox.ReadEAN(_HeaderFilter.GetValue('Item', true)), VariantCode, UoMCode, true);
        if not Item.Get(ItemNo) then
            Error(MobWmsLanguage.GetMessage('UNKNOWN_ITEM_NO'), ItemNo);

        // Set the tracking value displayed in the document queue
        _ReturnRegistrationTypeTracking := StrSubstNo('%1 - %2 %3 %4', PhysInvtRecordHeader.FieldCaption("Order No."), PhysInvtRecordHeader."Order No.", PhysInvtRecordHeader.FieldCaption("Recording No."), PhysInvtRecordHeader."Recording No.");

        // Add the steps
        AddPhysInvtRecordLineSteps(_Steps, LocationCode, Item, VariantCode, UoMCode);
    end;

    local procedure AddPhysInvtRecordLineSteps(var _Steps: Record "MOB Steps Element"; _LocationCode: Code[10]; _Item: Record Item; _VariantCode: Code[10]; _UoMCode: Code[10])
    var
        ItemVariant: Record "Item Variant";
        MobSetup: Record "MOB Setup";
    begin
        MobSetup.Get();

        // Step: Bin
        if MobWmsToolbox.LocationIsBinMandatory(_LocationCode) then
            _Steps.Create_TextStep_Bin(10, _LocationCode, _Item."No.", _VariantCode);

        // Step: Variant
        if _VariantCode = '' then begin
            ItemVariant.Reset();
            ItemVariant.SetRange("Item No.", _Item."No.");
            if not ItemVariant.IsEmpty() then
                _Steps.Create_ListStep_Variant(20, _Item."No.");
        end;

        // Step: UoM
        if (not MobSetup."Use Base Unit of Measure") and (_UoMCode = '') then begin
            _Steps.Create_ListStep_UoM(30, _Item."No.");
            _Steps.Set_defaultValue(_Item."Base Unit of Measure");
            if not MobWmsToolbox.GetItemHasMultipleUoM(_Item."No.") then begin
                _UoMCode := _Item."Base Unit of Measure";
                _Steps.Set_visible(false);
            end;
        end;

        // Step: Confirm step if no visible steps are defined
        _Steps.SetRange(visible, 'true');
        if _Steps.IsEmpty() then begin
            _Steps.Create_RadioButtonStep_YesNo(40, 'AddLine');
            _Steps.Set_header(MobWmsLanguage.GetMessage('ADD_LINE'));
        end;
        _Steps.Reset();
    end;

    /// <summary>
    /// Add a line to an existing Phys. Invt. Recording
    /// </summary>
    local procedure PostAddPhysInvtRecordLineRegistration(var _RequestValues: Record "MOB NS Request Element"; var _SuccessMessage: Text; var _ReturnRegistrationTypeTracking: Text)
    var
        PhysInvtRecordLine: Record "Phys. Invt. Record Line";
        PhysInvtRecordHeader: Record "Phys. Invt. Record Header";
        UoMCode: Code[10];
        BinCode: Code[20];
        ItemNumber: Code[50];
        VariantCode: Code[10];
    begin
        BinCode := MobToolbox.ReadBin(_RequestValues.GetValue('Bin'));
        ItemNumber := _RequestValues.GetValue('Item', true);

        if _RequestValues.GetValue('AddLine') = MobWmsLanguage.GetMessage('NO') then
            exit;

        // Get Order No. and Recording No. as Record 
        GetPhysInvtRecordHeader(_RequestValues.GetValue('OrderBackendID', true), PhysInvtRecordHeader);

        // Set Item, UoM and Variant from Barcode
        ItemNumber := MobItemReferenceMgt.SearchItemReference(ItemNumber, VariantCode, UoMCode);
        // Collected values have priority
        if _RequestValues.HasValue('UoM') then
            UoMCode := _RequestValues.GetValue('UoM');
        if _RequestValues.HasValue('Variant') then
            VariantCode := _RequestValues.GetValue('Variant');

        // Set the tracking value displayed in the document queue
        _ReturnRegistrationTypeTracking := PhysInvtRecordHeader."Order No." + ' - ' + PhysInvtRecordLine.FieldCaption("Item No.") + ' ' + ItemNumber;

        // Insert the line
        AddPhysInvtRecordLine(_RequestValues, PhysInvtRecordHeader, ItemNumber, VariantCode, BinCode, UoMCode);

        _SuccessMessage := StrSubstNo(MobWmsLanguage.GetMessage('ADDED_LINE'), ItemNumber);
    end;

    local procedure AddPhysInvtRecordLine(var _RequestValues: Record "MOB NS Request Element"; _PhysInvtRecordHeader: Record "Phys. Invt. Record Header"; _ItemNo: Code[20]; _VariantCode: Code[10]; _BinCode: Code[20]; _UoMCode: Code[10])
    var
        Item: Record Item;
        MobSetup: Record "MOB Setup";
        PhysInvtRecordLine: Record "Phys. Invt. Record Line";
        PhysInvtTrackingMgt: Codeunit "Phys. Invt. Tracking Mgt.";
    begin

        MobSetup.Get();
        Item.Get(_ItemNo);

        // Use Item's Base unit - Else keep incoming collected value
        if MobSetup."Use Base Unit of Measure" then
            _UoMCode := Item."Base Unit of Measure";

        // Add as new line
        PhysInvtRecordLine.Init();
        PhysInvtRecordLine.Validate("Order No.", _PhysInvtRecordHeader."Order No.");
        PhysInvtRecordLine.Validate("Recording No.", _PhysInvtRecordHeader."Recording No.");
        PhysInvtRecordLine.Validate("Line No.", GetNextPhysInvtRecordLineNo(_PhysInvtRecordHeader));
        PhysInvtRecordLine.Validate("Item No.", _ItemNo);
        PhysInvtRecordLine.Validate("Location Code", _PhysInvtRecordHeader."Location Code");
        PhysInvtRecordLine.Validate("Bin Code", _BinCode);
        PhysInvtRecordLine.Validate("Variant Code", _VariantCode);
        PhysInvtRecordLine.Validate("Unit of Measure Code", _UoMCode);
        PhysInvtRecordLine."Use Item Tracking" := PhysInvtTrackingMgt.SuggestUseTrackingLines(Item); // Isn't automatically set in early BC14 versions
        PhysInvtRecordLine.Recorded := false;
        OnAddPhysInvtRecordLine_OnAfterCreatePhysInvtRecordLine(_RequestValues, PhysInvtRecordLine);
        PhysInvtRecordLine.Insert(true);
    end;

    //
    // ------- IntegrationEvents: GetPhysInvtRecordings -------
    //
    // OnSetFilterPhysInvtRecordHeader
    // OnIncludePhysInvtRecordHeader
    // OnAfterSetFromPhysInvtRecordHeader
    // OnAfterSetCurrentKey

    [IntegrationEvent(false, false)]
    local procedure OnGetPhysInvtRecordings_OnSetFilterPhysInvtRecordHeader(_HeaderFilter: Record "MOB NS Request Element"; var _PhysInvtRecordHeader: Record "Phys. Invt. Record Header"; var _PhysInvtRecordLine: Record "Phys. Invt. Record Line"; var _IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetPhysInvtRecordings_OnIncludePhysInvtRecordHeader(_PhysInvtRecordHeader: Record "Phys. Invt. Record Header"; var _HeaderFilters: Record "MOB NS Request Element"; var _IncludeInOrderList: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetPhysInvtRecordings_OnAfterSetFromPhysInvtRecordHeader(_PhysInvtRecordHeader: Record "Phys. Invt. Record Header"; var _BaseOrderElement: Record "MOB NS BaseDataModel Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetPhysInvtRecordings_OnAfterSetCurrentKey(var _BaseOrderElementView: Record "MOB NS BaseDataModel Element")
    begin
    end;

    //
    // ------- IntegrationEvents: GetPhysInvtRecordingLines -------
    //
    // OnSetFilterPhysInvtRecordLine
    // OnIncludePhysInvtRecordLine
    // OnAfterSetFromPhysInvtRecordLine
    // OnAfterSetCurrentKey
    // OnAddStepsToPhysInvtRecordHeader
    // OnAddStepsToPhysInvtRecordLine

    [IntegrationEvent(false, false)]
    local procedure OnGetPhysInvtRecordingLines_OnSetFilterPhysInvtRecordLine(var _PhysInvtRecordLine: Record "Phys. Invt. Record Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetPhysInvtRecordingLines_OnIncludePhysInvtRecordLine(_PhysInvtRecordLine: Record "Phys. Invt. Record Line"; var _IncludeInOrderLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetPhysInvtRecordingLines_OnAfterSetFromPhysInvtRecordLine(_PhysInvtRecordLine: Record "Phys. Invt. Record Line"; var _BaseOrderLineElement: Record "MOB NS BaseDataModel Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetPhysInvtRecordingLines_OnAfterSetCurrentKey(var _BaseOrderLineElementView: Record "MOB NS BaseDataModel Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetPhysInvtRecordingLines_OnAddStepsToPhysInvtRecordHeader(_PhysInvtRecordHeader: Record "Phys. Invt. Record Header"; var _StepsElement: Record "MOB Steps Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetPhysInvtRecordingLines_OnAddStepsToPhysInvtRecordLine(_PhysInvtRecordLine: Record "Phys. Invt. Record Line"; var _BaseOrderLineElement: Record "MOB NS BaseDataModel Element"; var _Steps: Record "MOB Steps Element")
    begin
    end;

    //
    // ------- IntegrationEvents: PostPhysInvtRecording -------
    //
    // OnAddStepsToPhysInvtRecording
    // OnBeforePostPhysInvtRecording
    // OnHandleRegistrationForPhysInvtRecordLine
    // OnAfterCreatePhysInvtRecordLine

    [IntegrationEvent(false, false)]
    local procedure OnPostPhysInvtRecording_OnAddStepsToPhysInvtRecording(var _OrderValues: Record "MOB Common Element"; _PhysInvtRecordHeader: Record "Phys. Invt. Record Header"; var _StepsElement: Record "MOB Steps Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostPhysInvtRecording_OnBeforePostPhysInvtRecording(var _OrderValues: Record "MOB Common Element"; var _PhysInvtRecordHeader: Record "Phys. Invt. Record Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostPhysInvtRecording_OnHandleRegistrationForPhysInvtRecordLine(var _Registration: Record "MOB WMS Registration"; var _PhysInvtRecordLine: Record "Phys. Invt. Record Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAddPhysInvtRecordLine_OnAfterCreatePhysInvtRecordLine(var _RequestValues: Record "MOB NS Request Element"; var _PhysInvtRecordLine: Record "Phys. Invt. Record Line")
    begin
    end;
}
