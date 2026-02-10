codeunit 81379 "MOB WMS Whse. Inquiry"
{
    Access = Public;

    TableNo = "MOB Document Queue";

    var
        MobSetup: Record "MOB Setup";
        MobDocQueue: Record "MOB Document Queue";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        MobXmlMgt: Codeunit "MOB XML Management";
        MobToolbox: Codeunit "MOB Toolbox";
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
        MobLicensePlatePick: Codeunit "MOB WMS License Plate Pick";

    trigger OnRun()
    var
        TempRequestValues: Record "MOB NS Request Element" temporary;
        TempResponseElement: Record "MOB NS Resp Element" temporary;
        TempSteps: Record "MOB Steps Element" temporary;
        TempCommands: Record "MOB Command Element" temporary;
        MobRequestMgt: Codeunit "MOB NS Request Management";
        XmlRequestDoc: XmlDocument;
        XmlResponseDoc: XmlDocument;
        RegistrationTypeTracking: Text[200];
        IsHandled: Boolean;
        IsHandledAsXml: Boolean;
    begin
        // The Request Document looks like this:
        //  <request name="DocumentTypeName" created="2009-01-20T22:36:34-08:00" xmlns="http://schemas.microsoft.com/Dynamics/Mobile/2007/04>
        //    <requestData name="DocumentTypeName">
        //      <Barcode>LS-75</Barcode>
        //      <Quantity>3</Quantity>
        //    </requestData>
        //  </request>

        MobDocQueue := Rec;
        MobDocQueue.LoadXMLRequestDoc(XmlRequestDoc);

        // Read request values
        MobRequestMgt.SaveAdhocRequestValues(XmlRequestDoc, TempRequestValues);

        // -- Event
        OnWhseInquiryOnCustomDocumentType(Rec."Document Type", TempRequestValues, TempResponseElement, RegistrationTypeTracking, IsHandled);

        // -- Event AsXML
        if not IsHandled then begin

            MobToolbox.InitializeQueueResponseDoc(XmlResponseDoc);
            OnWhseInquiryOnCustomDocumentTypeAsXml(XmlRequestDoc, XmlResponseDoc, Rec."Document Type", RegistrationTypeTracking, IsHandledAsXml);

            // No default SimpleResponse for custom types: custom document handler must create response during handling
            if IsHandledAsXml then begin
                if not MobXmlMgt.GetDocRootNodeHasChildNodes(XmlResponseDoc) then
                    Error(MobWmsLanguage.GetMessage('NO_DOC_HANDLER'), 'MOB WMS Whse. Inquiry::' + Rec."Document Type" + '/XMLResponseDoc');
                SetRegistrationTypeTrackingAndUpdateResult(Rec, XmlResponseDoc, RegistrationTypeTracking);
                exit;
            end;
        end;

        // -- Standard functions
        if not IsHandled then
            case Rec."Document Type" of

                'ValidateLotNumber':
                    begin
                        ValidateLotNumber(TempRequestValues, RegistrationTypeTracking);
                        IsHandled := true;
                    end;

                'GetSerialNumberInformation':
                    begin
                        GetSerialNumberInformation(TempRequestValues, TempResponseElement, RegistrationTypeTracking);
                        IsHandled := true;
                    end;

                'ValidateBinCode':
                    begin
                        ValidateBin(TempRequestValues, RegistrationTypeTracking);
                        IsHandled := true;
                    end;
                'GetLicensePlateContentToPick':
                    begin
                        // Ensure License Plating is enabled before creating or updating the license plates
                        MobSetup.CheckLicensePlatingIsEnabled();

                        MobLicensePlatePick.GetLicensePlateContentToPick(TempRequestValues, TempCommands, RegistrationTypeTracking);
                        IsHandled := true;
                    end;
            end;

        // Event: Add additional steps on online validation (but only after the Document Type has optionally been validated above)
        // OnAddSteps-event only supported when the full xml response has not been created already using the OnWhseInquiryOnCustomDocumentTypeAsXml event
        OnWhseInquiry_OnAddSteps(Rec."Document Type", TempRequestValues, TempSteps, RegistrationTypeTracking, IsHandled);

        // Event: Add or change commands to send to the mobile device
        // OnAddCommands-event only supported when the full xml response has not been created already using the OnWhseInquiryOnCustomDocumentTypeAsXml event
        OnWhseInquiry_OnAddCommands(Rec."Document Type", TempRequestValues, TempCommands, RegistrationTypeTracking, IsHandled);

        case true of

            not TempSteps.IsEmpty():
                MobToolbox.CreateResponseWithSteps(XmlResponseDoc, TempSteps);

            not TempCommands.IsEmpty():
                MobToolbox.CreateResponseWithCommands(XmlResponseDoc, TempCommands);

            IsHandled:
                CreateResponse(TempResponseElement, XmlResponseDoc);

            else // Not handled and did not exit OnAddSteps either
                Error(MobWmsLanguage.GetMessage('NO_DOC_HANDLER'), 'MOB WMS Whse. Inquiry::' + Rec."Document Type");
        end;

        SetRegistrationTypeTrackingAndUpdateResult(Rec, XmlResponseDoc, RegistrationTypeTracking);
    end;

    local procedure CreateResponse(var _ResponseElement: Record "MOB NS Resp Element"; var _XmlResponseDoc: XmlDocument)
    var
        XmlResponseData: XmlNode;
    begin
        if _ResponseElement.IsEmpty() then
            // Respond with a simple OK when no error occurred 
            MobToolbox.CreateSimpleResponse(_XmlResponseDoc, 'OK')
        else begin
            // Respons with elements (ie. Item No.,Quantity etc.)
            MobToolbox.InitializeResponseDoc(_XmlResponseDoc, XmlResponseData);
            MobXmlMgt.AddNsWhseInquiryModelResponseDataElements(XmlResponseData, _ResponseElement);
        end;
    end;

    local procedure SetRegistrationTypeTrackingAndUpdateResult(var _Rec: Record "MOB Document Queue"; var _XmlResponseDoc: XmlDocument; _RegistrationTypeTracking: Text)
    begin
        // Update the registration type field on the mobile document queue record
        // In case of errors a fallback value is written from MOB WS Dispatcher
        MobDocQueue.SetRegistrationTypeAndTracking('', _RegistrationTypeTracking);

        // Store the result in the queue
        _Rec := MobDocQueue;
        MobToolbox.UpdateResult(_Rec, _XmlResponseDoc);
    end;

    /// <summary>
    /// Online Validation of Lot Number
    /// User enters a Lot number in a planned Order Line registration
    /// BC verifies the Lot exits in warehouse or returns errors 
    /// </summary>
    local procedure ValidateLotNumber(var _RequestValues: Record "MOB NS Request Element"; var _RegistrationTypeTracking: Text)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        LotNumber: Code[50];
        ItemNumber: Code[20];
    begin

        // Read request
        LotNumber := _RequestValues.GetValue('lotNumber');
        ItemNumber := _RequestValues.GetValue('itemNumber');

        // -- Lot number must be available in the Item Ledger Entries
        ItemLedgerEntry.Reset();
        ItemLedgerEntry.SetCurrentKey("Item No.");
        ItemLedgerEntry.SetRange("Item No.", ItemNumber);
        ItemLedgerEntry.SetRange("Lot No.", LotNumber);
        ItemLedgerEntry.SetRange(Open, true);
        ItemLedgerEntry.SetRange(Positive, true);

        if ItemLedgerEntry.IsEmpty() then
            // Not found
            Error(MobWmsLanguage.GetMessage('UNKNOWN_LOT'), LotNumber, '');

        // No error = Success. Lot number is available
        _RegistrationTypeTracking := LotNumber;
    end;

    /// <summary>
    /// Online Validation of Serial Number and return of Item Number for filtering Order Lines
    /// The validation is that the Serial is assinged only once in warehouse or error is returned
    /// 
    /// User scans serial number WITHOUT selecting a line first
    /// because line selection can happen automatically because this function converts the serial number to an item number
    ///  OR 
    /// User enters Serial number in a regular Order Line step 
    /// </summary>
    local procedure GetSerialNumberInformation(var _RequestValues: Record "MOB NS Request Element"; var _ResponseElement: Record "MOB NS Resp Element"; var _RegistrationTypeTracking: Text)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        SerialNumber: Code[50];
        ItemList: Text[1024];
        First: Boolean;
    begin

        // Read request
        SerialNumber := _RequestValues.GetValue('SerialNumber');

        // Serial number must be available in the Item Ledger Entries
        ItemLedgerEntry.Reset();
        ItemLedgerEntry.SetCurrentKey("Serial No.");
        ItemLedgerEntry.SetRange("Serial No.", SerialNumber);
        ItemLedgerEntry.SetRange(Open, true);
        ItemLedgerEntry.SetRange(Positive, true);

        case true of
            ItemLedgerEntry.Count() = 1:
                begin
                    // -- The Serial number is available

                    // Respond with Item Number
                    ItemLedgerEntry.FindFirst();

                    _ResponseElement.Create('SerialNumberInformation'); // SerialNumberInformation is a app-specific name that allows BC to reply with additional values
                    _ResponseElement.SetValue('ItemNumber', ItemLedgerEntry."Item No.");
                end;

            ItemLedgerEntry.Count() > 1:
                begin
                    // -- Not unique: The serial number has been used for multiple items

                    // Return an error with a list of the items
                    First := true;
                    if ItemLedgerEntry.FindSet() then
                        repeat
                            if First then
                                ItemList := ItemLedgerEntry."Item No."
                            else
                                ItemList += ', ' + ItemLedgerEntry."Item No.";
                            First := false;
                        until ItemLedgerEntry.Next() = 0;

                    Error(MobWmsLanguage.GetMessage('MULTIPLE_SERIAL_EXIST'), SerialNumber, ItemList);
                end;

            else
                // -- Not found
                Error(MobWmsLanguage.GetMessage('UNKNOWN_SERIAL'), SerialNumber, '')
        end;

        _RegistrationTypeTracking := SerialNumber;
    end;

    /// <summary>
    /// Online Validation of Bin Code
    /// User enters a Bin and BC checks whether that bin exists or returns errors 
    /// </summary>

    local procedure ValidateBin(var _RequestValues: Record "MOB NS Request Element"; var _RegistrationTypeTracking: Text)
    var
        Bin: Record Bin;
    begin
        Bin.Get(GetLocationCode(_RequestValues), _RequestValues.Get_Bin());
        _RegistrationTypeTracking := _RequestValues.Get_Bin();
    end;

    local procedure GetLocationCode(var _RequestValues: Record "MOB NS Request Element"): Code[10]
    begin
        case _RequestValues.Get_OrderType() of
            'Pick':
                exit(GetLocationPick(_RequestValues.Get_OrderBackendID(), _RequestValues.Get_LineNumberAsInteger()));
            'Receive':
                exit(GetLocationCodeReceive(_RequestValues.Get_OrderBackendID(), _RequestValues.Get_LineNumberAsInteger()));
            'PutAway':
                exit(GetLocationCodePutAway(_RequestValues.Get_OrderBackendID(), _RequestValues.Get_LineNumberAsInteger()));
            'Move':
                exit(GetLocationCodeMove(_RequestValues.Get_OrderBackendID(), _RequestValues.Get_LineNumberAsInteger()));
            'Ship':
                exit(GetLocationCodeShip(_RequestValues.Get_OrderBackendID(), _RequestValues.Get_LineNumberAsInteger()));
            'Assembly':
                exit(GetLocationCodeAssembly(_RequestValues.Get_OrderBackendID()));
            'Production':
                exit(GetLocationCodeProduction(_RequestValues.Get_OrderBackendID(), _RequestValues.Get_LineNumberAsInteger()));
            'Count':
                exit(GetLocationCodeCount(_RequestValues.Get_OrderBackendID(), _RequestValues.Get_LineNumberAsInteger()));
            'PhysInvtRecording':
                exit(GetLocationCodePhysInvRecording(_RequestValues.Get_OrderBackendID(), _RequestValues.Get_LineNumberAsInteger()));
        end;
    end;

    local procedure GetLocationPick(_OrderBackendID: Code[40]; _LineNumber: Integer): Code[10]
    var
        SalesLine: Record "Sales Line";
        PurchaseLine: Record "Purchase Line";
        WhseActLine: Record "Warehouse Activity Line";
        TransferHeader: Record "Transfer Header";
        DocumentNo: Code[20];
    begin
        DocumentNo := CopyStr(_OrderBackendID, 4, StrLen(_OrderBackendID));

        case CopyStr(_OrderBackendID, 1, 3) of
            'SO-':
                begin
                    SalesLine.Get(SalesLine."Document Type"::Order, DocumentNo, _LineNumber);
                    exit(SalesLine."Location Code");
                end;
            'TO-':
                if TransferHeader.Get(DocumentNo) then
                    exit(TransferHeader."Transfer-from Code");
            'PR-':
                begin
                    PurchaseLine.Get(PurchaseLine."Document Type"::"Return Order", DocumentNo, _LineNumber);
                    exit(PurchaseLine."Location Code");
                end;
            else
                WhseActLine.SetFilter("Activity Type", '%1| %2', WhseActLine."Activity Type"::"Invt. Pick", WhseActLine."Activity Type"::Pick);
                WhseActLine.SetRange("No.", _OrderBackendID);
                WhseActLine.SetRange("Line No.", _LineNumber);
                if WhseActLine.FindFirst() then
                    exit(WhseActLine."Location Code");
        end;
    end;

    local procedure GetLocationCodeReceive(_OrderBackendId: Code[40]; _LineNumber: Integer): Code[10]
    var
        PurchaseLine: Record "Purchase Line";
        TransferHeader: Record "Transfer Header";
        WhseReceiptLine: Record "Warehouse Receipt Line";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
    begin
        DocumentNo := CopyStr(_OrderBackendId, 4, StrLen(_OrderBackendId));

        case CopyStr(_OrderBackendId, 1, 3) of
            'PO-':
                if PurchaseLine.Get(PurchaseLine."Document Type"::Order, DocumentNo, _LineNumber) then
                    exit(PurchaseLine."Location Code");
            'TO-':
                if TransferHeader.Get(DocumentNo) then
                    exit(TransferHeader."Transfer-to Code");
            'SR-':
                if SalesLine.Get(SalesLine."Document Type"::"Return Order", DocumentNo, _LineNumber) then
                    exit(SalesLine."Location Code");
            else
                if WhseReceiptLine.Get(_OrderBackendId, _LineNumber) then
                    exit(WhseReceiptLine."Location Code");
        end;
    end;

    local procedure GetLocationCodePutAway(_OrderBackendId: Code[40]; _LineNumber: Integer): Code[10]
    var
        WhseActLine: Record "Warehouse Activity Line";
    begin
        WhseActLine.SetFilter(WhseActLine."Activity Type", '%1| %2', WhseActLine."Activity Type"::"Put-away", WhseActLine."Activity Type"::"Invt. Put-away");
        WhseActLine.SetRange("No.", _OrderBackendId);
        WhseActLine.SetRange("Line No.", _LineNumber);
        if WhseActLine.FindFirst() then
            exit(WhseActLine."Location Code");
    end;

    local procedure GetLocationCodeMove(_OrderBackendId: Code[40]; _LineNumber: Integer): Code[10]
    var
        WhseActLine: Record "Warehouse Activity Line";
    begin
        WhseActLine.SetFilter(WhseActLine."Activity Type", '%1| %2', WhseActLine."Activity Type"::Movement, WhseActLine."Activity Type"::"Invt. Movement");
        WhseActLine.SetRange("No.", _OrderBackendId);
        WhseActLine.SetRange("Line No.", _LineNumber);
        if WhseActLine.FindFirst() then
            exit(WhseActLine."Location Code");
    end;

    local procedure GetLocationCodeShip(_OrderBackendId: Code[40]; _LineNumber: Integer): Code[10]
    var
        WhseShipLine: Record "Warehouse Shipment Line";
    begin
        if WhseShipLine.Get(_OrderBackendId, _LineNumber) then
            exit(WhseShipLine."Location Code");
    end;

    local procedure GetLocationCodeAssembly(_OrderBackendId: Code[40]): Code[10]
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        if AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, _OrderBackendId) then
            exit(AssemblyHeader."Location Code");
    end;

    local procedure GetLocationCodeProduction(_OrderBackendId: Code[40]; _LineNumber: Integer): Code[10]
    var
        ProdOrder: Record "Production Order";
        OrderNo: Code[20];
    begin
        MobWmsToolbox.GetOrderNoAndOrderLineNoFromBackendId(_OrderBackendId, OrderNo, _LineNumber);
        if ProdOrder.Get(ProdOrder.Status::Released, OrderNo) then
            exit(ProdOrder."Location Code");
    end;

    local procedure GetLocationCodeCount(_OrderBackendId: Code[40]; _LineNumber: Integer): Code[10]
    var
        ItemJnlLine: Record "Item Journal Line";
        ItemJnlBatchName: Code[20];

        Prefix: Text[2];
        BatchNo: Code[10];
        LocationCode: Code[10];
    begin
        Prefix := CopyStr(_OrderBackendId, 1, 2);
        case Prefix of
            'W-':
                // orderBackendId is W-BatchName LocationCode
                begin
                    MobWmsToolbox.GetWhseJnlBatchNameAndLocationCodeFromBackendID(_OrderBackendId, BatchNo, LocationCode);
                    exit(LocationCode);
                end;
            'I-':
                begin
                    MobSetup.Get();
                    ItemJnlBatchName := CopyStr(_OrderBackendId, 3, StrLen(_OrderBackendId));
                    if ItemJnlLine.Get(MobSetup."Inventory Jnl Template", ItemJnlBatchName, _LineNumber) then
                        exit(ItemJnlLine."Location Code");
                end;
        end;
    end;

    local procedure GetLocationCodePhysInvRecording(_OrderBackendId: Code[40]; _LineNumber: Integer): Code[10]
    var
        PhysInvOrderLine: Record "Phys. Invt. Record Line";
        OrderNo: Code[20];
        RecordingNo: Integer;
    begin
        MobWmsToolbox.GetOrderNoAndRecordingNoFromBackendId(_OrderBackendId, OrderNo, RecordingNo);
        if PhysInvOrderLine.Get(OrderNo, RecordingNo, _LineNumber) then
            exit(PhysInvOrderLine."Location Code");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnWhseInquiry_OnAddSteps(_DocumentType: Text; var _RequestValues: Record "MOB NS Request Element"; var _Steps: Record "MOB Steps Element"; var _RegistrationTypeTracking: Text; var _IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnWhseInquiryOnCustomDocumentTypeAsXml(var _XMLRequestDoc: XmlDocument; var _XMLResponseDoc: XmlDocument; _DocumentType: Text; var _RegistrationTypeTracking: Text[200]; var _IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnWhseInquiryOnCustomDocumentType(_DocumentType: Text; var _RequestValues: Record "MOB NS Request Element"; var _ResponseElement: Record "MOB NS Resp Element"; var _RegistrationTypeTracking: Text; var _IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnWhseInquiry_OnAddCommands(_DocumentType: Text; var _RequestValues: Record "MOB NS Request Element"; var _Commands: Record "MOB Command Element"; var _RegistrationTypeTracking: Text; var _IsHandled: Boolean)
    begin
    end;
}
