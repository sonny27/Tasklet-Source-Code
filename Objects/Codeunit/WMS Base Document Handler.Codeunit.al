codeunit 81371 "MOB WMS Base Document Handler"
{
    Access = Public;
    trigger OnRun()
    begin
    end;

    var
        MobToolbox: Codeunit "MOB Toolbox";
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";

    //
    // ----------- Copy filtered Headers into Temp -----------
    //

    /// <summary>
    /// Transfer possibly filtered orders into temp record
    /// </summary> 
    procedure CopyFilteredWhseReceiptHeadersToTempRecord(var _WhseReceiptHeaderView: Record "Warehouse Receipt Header"; var _WhseReceiptLineView: Record "Warehouse Receipt Line"; var _HeaderFilters: Record "MOB NS Request Element"; var _TempWhseReceiptHeader: Record "Warehouse Receipt Header")
    var
        MobWmsReceive: Codeunit "MOB WMS Receive";
        IncludeInOrderList: Boolean;
    begin
        if _WhseReceiptHeaderView.FindSet() then
            repeat
                // Insert Only if lines exist
                _WhseReceiptLineView.SetRange("No.", _WhseReceiptHeaderView."No.");
                IncludeInOrderList := not _WhseReceiptLineView.IsEmpty();

                // Verify additional conditions from eventsubscribers
                if IncludeInOrderList then
                    MobWmsReceive.OnGetReceiveOrders_OnIncludeWarehouseReceiptHeader(_WhseReceiptHeaderView, _HeaderFilters, IncludeInOrderList);

                if IncludeInOrderList then begin
                    _TempWhseReceiptHeader.Copy(_WhseReceiptHeaderView);
                    _TempWhseReceiptHeader.Insert();
                end;
            until _WhseReceiptHeaderView.Next() = 0;
    end;

    /// <summary>
    /// Transfer possibly filtered orders into temp record
    /// </summary>
    procedure CopyFilteredWhseActivityHeadersToTempRecord(var _WhseActivityHeaderView: Record "Warehouse Activity Header"; var _WhseActivityLineView: Record "Warehouse Activity Line"; var _HeaderFilters: Record "MOB NS Request Element"; var _TempWhseActivityHeader: Record "Warehouse Activity Header"; _IsAnyPutAway: Boolean; _IsAnyPick: Boolean; _IsAnyMovement: Boolean)
    var
        MobWmsPick: Codeunit "MOB WMS Pick";
        MobWmsPutAway: Codeunit "MOB WMS Put Away";
        MobWmsMove: Codeunit "MOB WMS Move";
        IncludeInOrderList: Boolean;
    begin
        if _WhseActivityHeaderView.FindSet() then
            repeat
                // Insert Only if lines exist
                _WhseActivityLineView.SetRange("No.", _WhseActivityHeaderView."No.");
                _WhseActivityLineView.SetRange("Activity Type", _WhseActivityHeaderView.Type);
                IncludeInOrderList := not _WhseActivityLineView.IsEmpty();

                // Verify additional conditions from eventsubscribers
                if IncludeInOrderList then begin
                    if _IsAnyPick then
                        MobWmsPick.OnGetPickOrders_OnIncludeWarehouseActivityHeader(_WhseActivityHeaderView, _HeaderFilters, IncludeInOrderList);
                    if _IsAnyPutAway then
                        MobWmsPutAway.OnGetPutAwayOrders_OnIncludeWarehouseActivityHeader(_WhseActivityHeaderView, _HeaderFilters, IncludeInOrderList);
                    if _IsAnyMovement then
                        MobWmsMove.OnGetMoveOrders_OnIncludeWarehouseActivityHeader(_WhseActivityHeaderView, _HeaderFilters, IncludeInOrderList);
                end;

                if IncludeInOrderList then begin
                    _TempWhseActivityHeader.Copy(_WhseActivityHeaderView);
                    _TempWhseActivityHeader.Insert();
                end;
            until _WhseActivityHeaderView.Next() = 0;
    end;

    /// <summary>
    /// Transfer possibly filtered orders into temp record 
    /// </summary>
    procedure CopyFilteredSalesHeadersToTempRecord(var _SalesHeaderView: Record "Sales Header"; var _SalesLineView: Record "Sales Line"; var _HeaderFilters: Record "MOB NS Request Element"; var _TempSalesHeader: Record "Sales Header")
    var
        MobWmsPick: Codeunit "MOB WMS Pick";
        MobWmsReceive: Codeunit "MOB WMS Receive";
        IncludeInOrderList: Boolean;
    begin
        if _SalesHeaderView.FindSet() then
            repeat
                IncludeInOrderList := false;

                // Insert Only if lines exist
                _SalesLineView.SetRange("Document Type", _SalesHeaderView."Document Type");
                _SalesLineView.SetRange("Document No.", _SalesHeaderView."No.");
                if _SalesLineView.FindSet() then
                    repeat
                        IncludeInOrderList := _SalesLineView.IsInventoriableItem();
                    until (_SalesLineView.Next() = 0) or IncludeInOrderList;

                // Verify additional conditions from eventsubscribers
                if _SalesHeaderView."Document Type" = _SalesHeaderView."Document Type"::Order then
                    MobWmsPick.OnGetPickOrders_OnIncludeSalesHeader(_SalesHeaderView, _HeaderFilters, IncludeInOrderList);
                if _SalesHeaderView."Document Type" = _SalesHeaderView."Document Type"::"Return Order" then
                    MobWmsReceive.OnGetReceiveOrders_OnIncludeSalesReturnHeader(_SalesHeaderView, _HeaderFilters, IncludeInOrderList);

                if IncludeInOrderList then begin
                    _TempSalesHeader.Copy(_SalesHeaderView);
                    _TempSalesHeader.Insert();
                end;

            until _SalesHeaderView.Next() = 0;
    end;

    /// <summary>
    /// Transfer possibly filtered orders into temp record 
    /// </summary>
    procedure CopyFilteredPurchaseHeadersToTempRecord(var _PurchHeaderView: Record "Purchase Header"; var _PurchLineView: Record "Purchase Line"; var _HeaderFilters: Record "MOB NS Request Element"; var _TempPurchHeader: Record "Purchase Header")
    var
        MobWmsPick: Codeunit "MOB WMS Pick";
        MobWmsReceive: Codeunit "MOB WMS Receive";
        IncludeInOrderList: Boolean;
    begin
        if _PurchHeaderView.FindSet() then
            repeat
                IncludeInOrderList := false;

                // Insert Only if lines exist
                _PurchLineView.SetRange("Document Type", _PurchHeaderView."Document Type");
                _PurchLineView.SetRange("Document No.", _PurchHeaderView."No.");
                if _PurchLineView.FindSet() then
                    repeat
                        IncludeInOrderList := _PurchLineView.IsInventoriableItem();
                    until (_PurchLineView.Next() = 0) or IncludeInOrderList;

                // Verify additional conditions from eventsubscribers
                if _PurchHeaderView."Document Type" = _PurchHeaderView."Document Type"::Order then
                    MobWmsReceive.OnGetReceiveOrders_OnIncludePurchaseHeader(_PurchHeaderView, _HeaderFilters, IncludeInOrderList);
                if _PurchHeaderView."Document Type" = _PurchHeaderView."Document Type"::"Return Order" then
                    MobWmsPick.OnGetPickOrders_OnIncludePurchaseReturnHeader(_PurchHeaderView, _HeaderFilters, IncludeInOrderList);

                if IncludeInOrderList then begin
                    _TempPurchHeader.Copy(_PurchHeaderView);
                    _TempPurchHeader.Insert();
                end;

            until _PurchHeaderView.Next() = 0;
    end;

    /// <summary>
    /// Transfer possibly filtered orders into temp record
    /// </summary>
    procedure CopyFilteredTransferHeadersToTempRecord(var _TransferHeaderView: Record "Transfer Header"; var _TransferLineView: Record "Transfer Line"; var _HeaderFilters: Record "MOB NS Request Element"; var _TempTransferHeader: Record "Transfer Header"; _IsPick: Boolean; _IsReceive: Boolean)
    var
        MobWmsPick: Codeunit "MOB WMS Pick";
        MobWmsReceive: Codeunit "MOB WMS Receive";
        IncludeInOrderList: Boolean;
    begin
        if _TransferHeaderView.FindSet() then
            repeat
                // Insert Only if lines exist
                _TransferLineView.SetRange("Document No.", _TransferHeaderView."No.");
                IncludeInOrderList := not _TransferLineView.IsEmpty();

                // Verify additional conditions from eventsubscribers
                if IncludeInOrderList then begin
                    if _IsPick then
                        MobWmsPick.OnGetPickOrders_OnIncludeTransferHeader(_TransferHeaderView, _HeaderFilters, IncludeInOrderList);
                    if _IsReceive then
                        MobWmsReceive.OnGetReceiveOrders_OnIncludeTransferHeader(_TransferHeaderView, _HeaderFilters, IncludeInOrderList);
                end;

                if IncludeInOrderList then begin
                    _TempTransferHeader.Copy(_TransferHeaderView);
                    _TempTransferHeader.Insert();
                end;
            until _TransferHeaderView.Next() = 0;
    end;

    /// <summary>
    /// Transfer possibly filtered orders into temp record
    /// </summary> 
    procedure CopyFilteredWhseShipmentHeadersToTempRecord(var _WhseShipmentHeaderView: Record "Warehouse Shipment Header"; var _WhseShipmentLineView: Record "Warehouse Shipment Line"; var _HeaderFilters: Record "MOB NS Request Element"; var _TempWhseShipmentHeader: Record "Warehouse Shipment Header")
    var
        MobWmsShip: Codeunit "MOB WMS Ship";
        IncludeInOrderList: Boolean;
    begin
        if _WhseShipmentHeaderView.FindSet() then
            repeat
                // Insert Only if lines exist
                _WhseShipmentLineView.SetRange("No.", _WhseShipmentHeaderView."No.");
                IncludeInOrderList := not _WhseShipmentLineView.IsEmpty();

                // Verify additional conditions from eventsubscribers
                if IncludeInOrderList then
                    MobWmsShip.OnGetShipOrders_OnIncludeWarehouseShipmentHeader(_WhseShipmentHeaderView, _HeaderFilters, IncludeInOrderList);

                if IncludeInOrderList then begin
                    _TempWhseShipmentHeader.Copy(_WhseShipmentHeaderView);
                    _TempWhseShipmentHeader.Insert();
                end;
            until _WhseShipmentHeaderView.Next() = 0;
    end;

    /// <summary>
    /// Transfer possibly filtered item journal batches into temp record
    /// </summary>
    procedure CopyFilteredItemJnlBatchToTempRecord(var _ItemJnlBatchView: Record "Item Journal Batch"; var _ItemJnlLineView: Record "Item Journal Line"; var _HeaderFilters: Record "MOB NS Request Element"; var _TempItemJnlBatch: Record "Item Journal Batch")
    var
        MobWmsCount: Codeunit "MOB WMS Count";
        IncludeInOrderList: Boolean;
    begin
        if _ItemJnlBatchView.FindSet() then
            repeat
                // Insert Only if lines exist
                _ItemJnlLineView.SetRange("Journal Template Name", _ItemJnlBatchView."Journal Template Name");
                _ItemJnlLineView.SetRange("Journal Batch Name", _ItemJnlBatchView.Name);
                _ItemJnlLineView.SetRange(MOBRegisteredOnMobile, false);
                IncludeInOrderList := not _ItemJnlLineView.IsEmpty();

                // Verify additional conditions from eventsubscribers
                if IncludeInOrderList then
                    MobWmsCount.OnGetCountOrders_OnIncludeItemJournalBatch(_ItemJnlBatchView, _HeaderFilters, IncludeInOrderList);

                if IncludeInOrderList then begin
                    _TempItemJnlBatch.Copy(_ItemJnlBatchView);
                    _TempItemJnlBatch.Insert();
                end;
            until _ItemJnlBatchView.Next() = 0;
    end;

    /// <summary>
    /// Transfer possibly filtered warehouse journal batches into temp record
    /// </summary>
    procedure CopyFilteredWhseJnlBatchToTempRecord(var _WhseJnlBatchView: Record "Warehouse Journal Batch"; var _WhseJnlLineView: Record "Warehouse Journal Line"; var _HeaderFilters: Record "MOB NS Request Element"; var _TempWhseJnlBatch: Record "Warehouse Journal Batch")
    var
        MobWmsCount: Codeunit "MOB WMS Count";
        IncludeInOrderList: Boolean;
    begin
        if _WhseJnlBatchView.FindSet() then
            repeat
                // Insert Only if lines exist
                _WhseJnlLineView.SetRange("Journal Template Name", _WhseJnlBatchView."Journal Template Name");
                _WhseJnlLineView.SetRange("Journal Batch Name", _WhseJnlBatchView.Name);
                _WhseJnlLineView.SetRange(MOBRegisteredOnMobile, false);
                IncludeInOrderList := not _WhseJnlLineView.IsEmpty();

                // Verify additional conditions from eventsubscribers
                if IncludeInOrderList then
                    MobWmsCount.OnGetCountOrders_OnIncludeWarehouseJournalBatch(_WhseJnlBatchView, _HeaderFilters, IncludeInOrderList);

                if IncludeInOrderList then begin
                    _TempWhseJnlBatch.Copy(_WhseJnlBatchView);
                    _TempWhseJnlBatch.Insert();
                end;
            until _WhseJnlBatchView.Next() = 0;
    end;

    //
    // ----------- Source Document -----------
    //

    /// <summary>
    /// Get Purchase/Sales Header/Line from a RecordRef
    /// If recordref is Warehouse header which can have multiple sources (Whse Receipt/Pick), then the first line's source doc header is used
    /// </summary>
    /// <param name="_RecRef">Typically "ReferenceID" from mobile</param>
    internal procedure GetSourceDocOrLine(_RecRef: RecordRef; var _ReturnRecRef: RecordRef) ReturnSuccess: Boolean
    var
        WhseReceiptHeader: Record "Warehouse Receipt Header";
        WhseReceiptLine: Record "Warehouse Receipt Line";
        WhseActivityHeader: Record "Warehouse Activity Header";
        WhseActivityLine: Record "Warehouse Activity Line";
        WhseShipmentHeader: Record "Warehouse Shipment Header";
        WhseShipmentLine: Record "Warehouse Shipment Line";
    begin

        case _RecRef.Number() of

            // Recordref is already a source document
            Database::"Sales Header",
            Database::"Purchase Header",
            Database::"Sales Line",
            Database::"Purchase Line":
                _ReturnRecRef := _RecRef;

            // Recordref is a Warehouse Header 
            Database::"Warehouse Receipt Header":
                begin
                    _RecRef.SetTable(WhseReceiptHeader);
                    WhseReceiptLine.SetRange("No.", WhseReceiptHeader."No.");
                    // Get first Line and use that's Header as source header
                    if WhseReceiptLine.FindFirst() then
                        GetSourceDocFromWhseLine(WhseReceiptLine, _ReturnRecRef, true);
                end;
            Database::"Warehouse Shipment Header":
                begin
                    _RecRef.SetTable(WhseShipmentHeader);
                    WhseShipmentLine.SetRange("No.", WhseShipmentHeader."No.");
                    // Get first Line and use that's Header as source header
                    if WhseShipmentLine.FindFirst() then
                        GetSourceDocFromWhseLine(WhseShipmentLine, _ReturnRecRef, true);
                end;
            Database::"Warehouse Activity Header":
                begin
                    _RecRef.SetTable(WhseActivityHeader);
                    WhseActivityLine.SetRange("No.", WhseActivityHeader."No.");
                    WhseActivityLine.SetRange("Activity Type", WhseActivityHeader.Type);
                    // Get first Line and use that's Header as source header
                    if WhseActivityLine.FindFirst() then
                        GetSourceDocFromWhseLine(WhseActivityLine, _ReturnRecRef, true);
                end;

            // Recordref is a Warehouse Line
            Database::"Warehouse Receipt Line":
                GetSourceDocFromWhseLine(_RecRef, _ReturnRecRef, false);
            Database::"Warehouse Shipment Line":
                GetSourceDocFromWhseLine(_RecRef, _ReturnRecRef, false);
            Database::"Warehouse Activity Line":
                GetSourceDocFromWhseLine(_RecRef, _ReturnRecRef, false);

        end;

        ReturnSuccess := _ReturnRecRef.Number() <> 0;
    end;

    /// <summary>
    /// Get source doc from a Warehouse Receipt or Warehouse Activity Line
    /// </summary>
    internal procedure GetSourceDocFromWhseLine(_WhseLine: Variant; var _ReturnRecRef: RecordRef; _ReturnAsHeader: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SourceSubtype: Option;
        SourceType: Option;
        SourceNo: Code[20];
        SourceLineNo: Integer;
    begin

        GetSourceFromWhseLine(_WhseLine, SourceNo, SourceType, SourceSubtype, SourceLineNo);

        // Get source doc
        case SourceType of
            Database::"Purchase Line":
                if _ReturnAsHeader then begin
                    PurchaseHeader.Get(SourceSubtype, SourceNo);
                    _ReturnRecRef.GetTable(PurchaseHeader);
                end else begin
                    PurchaseLine.Get(SourceSubtype, SourceNo, SourceLineNo);
                    _ReturnRecRef.GetTable(PurchaseLine);
                end;

            Database::"Sales Line":
                if _ReturnAsHeader then begin
                    SalesHeader.Get(SourceSubtype, SourceNo);
                    _ReturnRecRef.GetTable(SalesHeader);
                end else begin
                    SalesLine.Get(SourceSubtype, SourceNo, SourceLineNo);
                    _ReturnRecRef.GetTable(SalesLine);
                end;
        end;
    end;

    internal procedure GetSourceFromWhseLine(_WhseLine: Variant; var _SourceNo: Code[20]; var _SourceType: Option; var _SourceSubtype: Option; var _SourceLineNo: Integer)
    begin
        _SourceType := MobToolbox.FindFieldValueAsInteger(_WhseLine, 'Source Type');
        _SourceSubtype := MobToolbox.FindFieldValueAsInteger(_WhseLine, 'Source Subtype');
        _SourceNo := MobToolbox.FindFieldValueAsText(_WhseLine, 'Source No.');
        _SourceLineNo := MobToolbox.FindFieldValueAsInteger(_WhseLine, 'Source Line No.');
    end;

    //
    // ----------- Location Filter -----------
    //

    /// <summary>
    /// "Inventory" locations
    /// </summary>
    procedure GetLocationFilter_Inventory(_MobileUserID: Text[1024]) _LocationFilter: Text
    var
        Location: Record Location;
    begin
        // Get the location filters allowed for the mobile user
        Location.SetFilter(Code, MobWmsToolbox.GetLocationFilter(_MobileUserID));

        _LocationFilter := 'EMPTY|';

        if Location.FindSet() then
            repeat
                // Build the location filter string
                if not (Location."Require Pick" or Location."Require Shipment") then
                    _LocationFilter := _LocationFilter + Location.Code + '|';
            until Location.Next() = 0;

        // Remove the trailing '|' in the filter
        if _LocationFilter <> '' then
            _LocationFilter := DelStr(_LocationFilter, StrLen(_LocationFilter), 1);
    end;

    /// <summary>
    /// Locations NOT using Receipts or Put-aways
    /// </summary>
    procedure GetLocationFilter_NoReceiptOrNoPutAway(_MobileUserID: Text[65]) _LocationFilter: Text
    var
        Location: Record Location;
    begin
        // Get the location filters allowed for the mobile user
        Location.SetFilter(Code, MobWmsToolbox.GetLocationFilter(_MobileUserID));

        _LocationFilter := 'EMPTY|';

        if Location.FindSet() then
            repeat
                // Build the location filter string
                if not (Location."Require Put-away" or Location."Require Receive") then
                    _LocationFilter := _LocationFilter + Location.Code + '|';
            until Location.Next() = 0;

        // Remove the trailing '|' in the filter
        if _LocationFilter <> '' then
            _LocationFilter := DelStr(_LocationFilter, StrLen(_LocationFilter), 1);
    end;

    /// <summary>
    /// Locations using Shipment
    /// </summary>
    procedure GetLocationFilter_Ship(_MobileUserID: Text[65]) _LocationFilter: Text
    var
        Location: Record Location;
    begin
        // Get the location filters allowed for the mobile user
        Location.SetFilter(Code, MobWmsToolbox.GetLocationFilter(_MobileUserID));

        _LocationFilter := 'EMPTY|';

        if Location.FindSet() then
            repeat
                // Build the location filter string
                if Location.RequireShipment(Location.Code) then
                    _LocationFilter := _LocationFilter + Location.Code + '|';
            until Location.Next() = 0;

        // Remove the trailing '|' in the filter
        if _LocationFilter <> '' then
            _LocationFilter := DelStr(_LocationFilter, StrLen(_LocationFilter), 1);
    end;

    /// <summary>
    /// Locations using Shipment and NOT using Pick
    /// </summary>
    procedure GetLocationFilter_ShipAndNoPick(_MobileUserID: Text[65]) _LocationFilter: Text
    var
        Location: Record Location;
    begin
        // Get the location filters allowed for the mobile user
        Location.SetFilter(Code, MobWmsToolbox.GetLocationFilter(_MobileUserID));

        _LocationFilter := 'EMPTY|';

        if Location.FindSet() then
            repeat
                // Build the location filter string
                if Location.RequireShipment(Location.Code) and (not Location.RequirePicking(Location.Code)) then
                    _LocationFilter := _LocationFilter + Location.Code + '|';
            until Location.Next() = 0;

        // Remove the trailing '|' in the filter
        if _LocationFilter <> '' then
            _LocationFilter := DelStr(_LocationFilter, StrLen(_LocationFilter), 1);
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnAfterGroupByBaseOrderLineElements(var _GroupOrderLineElement: Record "MOB NS BaseDataModel Element"; var _IsGrouped: Boolean; var _BaseOrderLineElements: Record "MOB NS BaseDataModel Element"; var _IsHandled: Boolean)
    begin
    end;
}
