codeunit 81440 "MOB ScannedValue Mgt."
{
    Access = Public;
    var
        MobToolbox: Codeunit "MOB Toolbox";

    //
    // Item
    //

    /// <summary>
    /// Wrapper function for MobItemReferenceMgt.SearchItemReference but return true/false if Item exists
    /// </summary>
    internal procedure SearchItemReference(_ScannedBarcode: Code[50]; var _ReturnItemNumber: Code[50]; var _ReturnVariantCode: Code[10]): Boolean
    var
        Item: Record Item;
        MobItemReferenceMgt: Codeunit "MOB Item Reference Mgt.";
    begin
        if (_ScannedBarcode = '') then
            exit(false);

        _ReturnItemNumber := MobItemReferenceMgt.SearchItemReference(_ScannedBarcode, _ReturnVariantCode);
        if not MobToolbox.IsValidExpressionLen(_ReturnItemNumber, MaxStrLen(Item."No.")) then
            exit(false);

        Item.Reset();
        Item.SetRange("No.", _ReturnItemNumber);
        exit(not Item.IsEmpty());
    end;


    //
    // Warehouse Receipt
    //

    /// <summary>
    /// Filter ReceiptNo or Item/Variant by _ScannedValue (match for scanned receipt no. at location takes precedence over other filters)
    /// </summary>
    procedure SetFilterForWhseReceipt(var _WhseReceiptHeader: Record "Warehouse Receipt Header"; var _WhseReceiptLine: Record "Warehouse Receipt Line"; _ScannedValue: Text)
    var
        ItemNumber: Code[50];
        VariantCode: Code[10];
    begin
        case true of
            SearchWhseReceiptHeader(_ScannedValue, _WhseReceiptHeader):
                ReplaceFilterWhseReceiptHeader(_WhseReceiptHeader, _ScannedValue);
            SearchItemReference(_ScannedValue, ItemNumber, VariantCode):
                begin
                    _WhseReceiptLine.SetRange("Item No.", ItemNumber);
                    if VariantCode <> '' then
                        _WhseReceiptLine.SetRange("Variant Code", VariantCode);
                end;
            SearchPackageTrackingNoOnSalesReturnOrders(_ScannedValue, _WhseReceiptLine):
                _WhseReceiptHeader.SetFilter("No.", _WhseReceiptLine."No.");
            else
                _WhseReceiptHeader.SetRange("No.", '22e35d32-8aa2-4181-8'); // Empty list
        end;
    end;

    /// <summary>
    /// Search Whse. Receipt Header by ReceiptNo and within current Location-filter (but ignoring other filters)
    /// </summary>
    local procedure SearchWhseReceiptHeader(_ScannedValue: Text; var _FilteredWhseReceiptHeader: Record "Warehouse Receipt Header"): Boolean
    var
        WhseReceiptHeader2: Record "Warehouse Receipt Header";
    begin
        if (_ScannedValue = '') or (not MobToolbox.IsValidExpressionLen(_ScannedValue, MaxStrLen(WhseReceiptHeader2."No."))) then
            exit(false);

        WhseReceiptHeader2.Copy(_FilteredWhseReceiptHeader);
        ReplaceFilterWhseReceiptHeader(WhseReceiptHeader2, _ScannedValue);
        if WhseReceiptHeader2.FindFirst() then begin
            _FilteredWhseReceiptHeader := WhseReceiptHeader2;
            exit(true);
        end;

        exit(false);
    end;

    /// <summary>
    /// Set new filter for only ReceiptNo and current Location-filter (ignoring all other filters)
    /// </summary>
    local procedure ReplaceFilterWhseReceiptHeader(var _WhseReceiptHeader: Record "Warehouse Receipt Header"; _ScannedValue: Text): Boolean
    var
        WhseReceiptHeader2: Record "Warehouse Receipt Header";
    begin
        WhseReceiptHeader2.Copy(_WhseReceiptHeader);

        _WhseReceiptHeader.Reset();
        _WhseReceiptHeader.SetFilter("No.", _ScannedValue);
        WhseReceiptHeader2.CopyFilter("Location Code", _WhseReceiptHeader."Location Code");
    end;


    //
    // Warehouse Activity
    //

    /// <summary>
    /// Filter ActivityNo or Item/Variant by _ScannedValue (match for scanned activity no. at location takes precedence over other filters)
    /// </summary>
    procedure SetFilterForWhseActivity(var _WhseActHeader: Record "Warehouse Activity Header"; var _WhseActLine: Record "Warehouse Activity Line"; _ScannedValue: Text)
    var
        ItemNumber: Code[50];
        VariantCode: Code[10];
    begin
        case true of
            SearchWhseActivityHeader(_ScannedValue, _WhseActHeader):
                ReplaceFilterWhseActivityHeader(_WhseActHeader, _ScannedValue);
            SearchItemReference(_ScannedValue, ItemNumber, VariantCode):
                begin
                    _WhseActLine.SetRange("Item No.", ItemNumber);
                    if VariantCode <> '' then
                        _WhseActLine.SetRange("Variant Code", VariantCode);
                end;
            else
                _WhseActHeader.SetRange("No.", '22e35d32-8aa2-4181-8'); // Empty list
        end;
    end;

    /// <summary>
    /// Search Whse. Activity Header by ActivityNo and within current ActType/Location-filter (but ignoring other filters)
    /// </summary>
    local procedure SearchWhseActivityHeader(_ScannedValue: Text; var _FilteredWhseActivityHeader: Record "Warehouse Activity Header"): Boolean
    var
        WhseActHeader2: Record "Warehouse Activity Header";
    begin
        if (_ScannedValue = '') or (not MobToolbox.IsValidExpressionLen(_ScannedValue, MaxStrLen(WhseActHeader2."No."))) then
            exit(false);

        WhseActHeader2.Copy(_FilteredWhseActivityHeader);
        ReplaceFilterWhseActivityHeader(WhseActHeader2, _ScannedValue);
        if WhseActHeader2.FindFirst() then begin
            _FilteredWhseActivityHeader := WhseActHeader2;
            exit(true);
        end;

        exit(false);
    end;

    /// <summary>
    /// Set new filter for only ActivityNo and current ActType/Location-filter (ignoring all other filters)
    /// </summary>
    local procedure ReplaceFilterWhseActivityHeader(var _WhseActHeader: Record "Warehouse Activity Header"; _ScannedValue: Text): Boolean
    var
        WhseActHeader2: Record "Warehouse Activity Header";
    begin
        WhseActHeader2.Copy(_WhseActHeader);

        _WhseActHeader.Reset();
        _WhseActHeader.SetFilter("No.", _ScannedValue);
        WhseActHeader2.CopyFilter("Type", _WhseActHeader."Type");
        WhseActHeader2.CopyFilter("Location Code", _WhseActHeader."Location Code");
    end;


    //
    // Sales (SalesOrders and SalesReturnOrders)
    //

    /// <summary>
    /// Filter DocumentNo or Item/Variant by _ScannedValue (match for scanned document no. at location takes precedence over other filters)
    /// </summary>
    procedure SetFilterForSalesDoc(var _SalesHeader: Record "Sales Header"; var _SalesLine: Record "Sales Line"; _ScannedValue: Text)
    var
        ItemNumber: Code[50];
        VariantCode: Code[10];
    begin
        case true of
            SearchSalesHeader(_ScannedValue, _SalesHeader):
                ReplaceFilterSalesHeader(_SalesHeader, _ScannedValue);
            SearchItemReference(_ScannedValue, ItemNumber, VariantCode):
                begin
                    _SalesLine.SetRange("Type", _SalesLine.Type::Item);
                    _SalesLine.SetRange("No.", ItemNumber);
                    if VariantCode <> '' then
                        _SalesLine.SetRange("Variant Code", VariantCode);
                end;
            SearchPackageTrackingNoOnSalesReturnOrders(_ScannedValue, _SalesHeader): // Filter after Package Tracking no.- only for Sales return orders
                _SalesHeader.SetRecFilter();
            else
                _SalesHeader.SetRange("No.", '22e35d32-8aa2-4181-8'); // Empty list
        end;
    end;

    /// <summary>
    /// Overload to search Package Tracking No from Sales Header or Whse. Receipt Line in Sales Return Order and return true if found
    /// </summary>
    local procedure SearchPackageTrackingNoOnSalesReturnOrders(_ScannedValue: Text; var _FilteredSalesHeader: Record "Sales Header"): Boolean
    var
        SalesHeader: Record "Sales Header";
    begin
        if _ScannedValue = '' then
            exit(false);
        SalesHeader.Copy(_FilteredSalesHeader);
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::"Return Order");
#pragma warning disable AL0432
        SalesHeader.SetRange("Package Tracking No.", _ScannedValue);
#pragma warning restore AL0432
        if SalesHeader.FindFirst() then begin
            _FilteredSalesHeader := SalesHeader;
            exit(true);
        end;
        exit(false);
    end;

    local procedure SearchPackageTrackingNoOnSalesReturnOrders(_ScannedValue: Text; var _WhseReceiptLine: Record "Warehouse Receipt Line"): Boolean
    var
        SalesHeader: Record "Sales Header";
    begin
        if not SearchPackageTrackingNoOnSalesReturnOrders(_ScannedValue, SalesHeader) then
            exit;
        _WhseReceiptLine.SetRange("Source Type", Database::"Sales Line");
        _WhseReceiptLine.SetRange("Source Subtype", SalesHeader."Document Type");
        _WhseReceiptLine.SetRange("Source Document", _WhseReceiptLine."Source Document"::"Sales Return Order");
        _WhseReceiptLine.SetRange("Source No.", SalesHeader."No.");
        exit(_WhseReceiptLine.FindFirst());
    end;

    /// <summary>
    /// Search Sales Header by DocumentNo and within current DocumentType/Location/Status-filter (but ignoring other filters)
    /// </summary>
    local procedure SearchSalesHeader(_ScannedValue: Text; var _FilteredSalesHeader: Record "Sales Header"): Boolean
    var
        SalesHeader2: Record "Sales Header";
    begin
        if (_ScannedValue = '') or (not MobToolbox.IsValidExpressionLen(_ScannedValue, MaxStrLen(SalesHeader2."No."))) then
            exit(false);

        SalesHeader2.Copy(_FilteredSalesHeader);
        ReplaceFilterSalesHeader(SalesHeader2, _ScannedValue);
        if SalesHeader2.FindFirst() then begin
            _FilteredSalesHeader := SalesHeader2;
            exit(true);
        end;

        exit(false);
    end;

    /// <summary>
    /// Set new filter for only DocumentNo and current DocumentType/Location/Status-filter (ignoring all other filters)
    /// </summary>
    local procedure ReplaceFilterSalesHeader(var _SalesHeader: Record "Sales Header"; _ScannedValue: Text): Boolean
    var
        SalesHeader2: Record "Sales Header";
    begin
        SalesHeader2.Copy(_SalesHeader);

        _SalesHeader.Reset();
        _SalesHeader.SetFilter("No.", _ScannedValue);
        SalesHeader2.CopyFilter("Document Type", _SalesHeader."Document Type");
        SalesHeader2.CopyFilter("Location Code", _SalesHeader."Location Code");
        SalesHeader2.CopyFilter(Status, _SalesHeader.Status);
    end;


    //
    // Purchase (PurchOrders and PurchReturnOrders)
    //

    /// <summary>
    /// Filter DocumentNo or Item/Variant by _ScannedValue (match for scanned document no. at location takes precedence over other filters)
    /// </summary>
    procedure SetFilterForPurchDoc(var _PurchHeader: Record "Purchase Header"; var _PurchLine: Record "Purchase Line"; _ScannedValue: Text)
    var
        ItemNumber: Code[50];
        VariantCode: Code[10];
    begin
        case true of
            SearchPurchHeader(_ScannedValue, _PurchHeader):
                ReplaceFilterPurchHeader(_PurchHeader, _ScannedValue);
            SearchItemReference(_ScannedValue, ItemNumber, VariantCode):
                begin
                    _PurchLine.SetRange("Type", _PurchLine.Type::Item);
                    _PurchLine.SetRange("No.", ItemNumber);
                    if VariantCode <> '' then
                        _PurchLine.SetRange("Variant Code", VariantCode);
                end;
            else
                _PurchHeader.SetRange("No.", '22e35d32-8aa2-4181-8'); // Empty list
        end;
    end;

    /// <summary>
    /// Search Purchase Header by DocumentNo and within current DocumentType/Location/Status-filter (but ignoring other filters)
    /// </summary>
    local procedure SearchPurchHeader(_ScannedValue: Text; var _FilteredPurchHeader: Record "Purchase Header"): Boolean
    var
        PurchHeader2: Record "Purchase Header";
    begin
        if (_ScannedValue = '') or (not MobToolbox.IsValidExpressionLen(_ScannedValue, MaxStrLen(PurchHeader2."No."))) then
            exit(false);

        PurchHeader2.Copy(_FilteredPurchHeader);
        ReplaceFilterPurchHeader(PurchHeader2, _ScannedValue);
        if PurchHeader2.FindFirst() then begin
            _FilteredPurchHeader := PurchHeader2;
            exit(true);
        end;

        exit(false);
    end;

    /// <summary>
    /// Set new filter for only DocumentNo and current DocumentType/Location/Status-filter (ignoring all other filters)
    /// </summary>
    local procedure ReplaceFilterPurchHeader(var _PurchHeader: Record "Purchase Header"; _ScannedValue: Text): Boolean
    var
        PurchHeader2: Record "Purchase Header";
    begin
        PurchHeader2.Copy(_PurchHeader);

        _PurchHeader.Reset();
        _PurchHeader.SetFilter("No.", _ScannedValue);
        PurchHeader2.CopyFilter("Document Type", _PurchHeader."Document Type");
        PurchHeader2.CopyFilter("Location Code", _PurchHeader."Location Code");
        PurchHeader2.CopyFilter(Status, _PurchHeader.Status);
    end;


    //
    // Transfer Orders
    //

    /// <summary>
    /// Filter TransferNo or Item/Variant by _ScannedValue (match for scanned transfer no. at location takes precedence over other filters)
    /// </summary>
    procedure SetFilterForTransferOrder(var _TransHeader: Record "Transfer Header"; var _TransLine: Record "Transfer Line"; _ScannedValue: Text)
    var
        ItemNumber: Code[50];
        VariantCode: Code[10];
    begin
        case true of
            SearchTransferHeader(_ScannedValue, _TransHeader):
                ReplaceFilterTransferHeader(_TransHeader, _ScannedValue);
            SearchItemReference(_ScannedValue, ItemNumber, VariantCode):
                begin
                    _TransLine.SetRange("Item No.", ItemNumber);
                    if VariantCode <> '' then
                        _TransLine.SetRange("Variant Code", VariantCode);
                end;
            else
                _TransHeader.SetRange("No.", '22e35d32-8aa2-4181-8'); // Empty list
        end;
    end;

    /// <summary>
    /// Search Transfer Header by TransferNo and within current Status/To-From-Location-filter (but ignoring other filters)
    /// </summary>
    local procedure SearchTransferHeader(_ScannedValue: Text; var _FilteredTransHeader: Record "Transfer Header"): Boolean
    var
        TransHeader2: Record "Transfer Header";
    begin
        if (_ScannedValue = '') or (not MobToolbox.IsValidExpressionLen(_ScannedValue, MaxStrLen(TransHeader2."No."))) then
            exit(false);

        TransHeader2.Copy(_FilteredTransHeader);
        ReplaceFilterTransferHeader(TransHeader2, _ScannedValue);
        if TransHeader2.FindFirst() then begin
            _FilteredTransHeader := TransHeader2;
            exit(true);
        end;

        exit(false);
    end;

    /// <summary>
    /// Set new filter for only TransferNo and current Status/To-From-Location-filter (ignoring all other filters)
    /// </summary>
    local procedure ReplaceFilterTransferHeader(var _TransHeader: Record "Transfer Header"; _ScannedValue: Text): Boolean
    var
        TransHeader2: Record "Transfer Header";
    begin
        TransHeader2.Copy(_TransHeader);

        _TransHeader.Reset();
        _TransHeader.SetFilter("No.", _ScannedValue);
        TransHeader2.CopyFilter(Status, _TransHeader.Status);
        TransHeader2.CopyFilter("Transfer-from Code", _TransHeader."Transfer-from Code");
        TransHeader2.CopyFilter("Transfer-to Code", _TransHeader."Transfer-to Code");
    end;


    //
    // Warehouse Shipment
    //

    /// <summary>
    /// Filter ShipmentNo or Item/Variant by _ScannedValue (match for scanned shipment no. at location takes precedence over other filters)
    /// </summary>
    procedure SetFilterForWhseShipment(var _WhseShipmentHeader: Record "Warehouse Shipment Header"; var _WhseShipmentLine: Record "Warehouse Shipment Line"; _ScannedValue: Text)
    var
        ItemNumber: Code[50];
        VariantCode: Code[10];
    begin
        case true of
            SearchWhseShipmentHeader(_ScannedValue, _WhseShipmentHeader):
                ReplaceFilterWhseShipmentHeader(_WhseShipmentHeader, _ScannedValue);
            SearchItemReference(_ScannedValue, ItemNumber, VariantCode):
                begin
                    _WhseShipmentLine.SetRange("Item No.", ItemNumber);
                    if VariantCode <> '' then
                        _WhseShipmentLine.SetRange("Variant Code", VariantCode);
                end;
            else
                _WhseShipmentHeader.SetRange("No.", '22e35d32-8aa2-4181-8'); // Empty list
        end;
    end;

    /// <summary>
    /// Search Whse. Shipment Header by ShipmentNo and within current Status/Location-filter (but ignoring other filters)
    /// </summary>
    local procedure SearchWhseShipmentHeader(_ScannedValue: Text; var _FilteredWhseShipmentHeader: Record "Warehouse Shipment Header"): Boolean
    var
        WhseShipmentHeader2: Record "Warehouse Shipment Header";
    begin
        if (_ScannedValue = '') or (not MobToolbox.IsValidExpressionLen(_ScannedValue, MaxStrLen(WhseShipmentHeader2."No."))) then
            exit(false);

        WhseShipmentHeader2.Copy(_FilteredWhseShipmentHeader);
        ReplaceFilterWhseShipmentHeader(WhseShipmentHeader2, _ScannedValue);
        if WhseShipmentHeader2.FindFirst() then begin
            _FilteredWhseShipmentHeader := WhseShipmentHeader2;
            exit(true);
        end;

        exit(false);
    end;

    /// <summary>
    /// Set new filter for only ShipmentNo and current Status/Location-filter (ignoring all other filters)
    /// </summary>
    local procedure ReplaceFilterWhseShipmentHeader(var _WhseShipmentHeader: Record "Warehouse Shipment Header"; _ScannedValue: Text): Boolean
    var
        WhseShipmentHeader2: Record "Warehouse Shipment Header";
    begin
        WhseShipmentHeader2.Copy(_WhseShipmentHeader);

        _WhseShipmentHeader.Reset();
        _WhseShipmentHeader.SetFilter("No.", _ScannedValue);
        WhseShipmentHeader2.CopyFilter("Location Code", _WhseShipmentHeader."Location Code");
        WhseShipmentHeader2.CopyFilter(Status, _WhseShipmentHeader.Status);
    end;


    //
    // Item Journal (Batch and Line)
    //

    /// <summary>
    /// Filter BatchName or Item/Variant by _ScannedValue (match for scanned batch name at location takes precedence over other filters)
    /// </summary>
    procedure SetFilterForItemJnl(var _ItemJnlBatch: Record "Item Journal Batch"; var _ItemJnlLine: Record "Item Journal Line"; _ScannedValue: Text)
    var
        ItemNumber: Code[50];
        VariantCode: Code[10];
    begin
        case true of
            SearchItemJournalBatch(_ScannedValue, _ItemJnlBatch):
                ReplaceFilterItemJnlBatch(_ItemJnlBatch, _ScannedValue);
            SearchItemReference(_ScannedValue, ItemNumber, VariantCode):
                begin
                    _ItemJnlLine.SetRange("Item No.", ItemNumber);
                    if VariantCode <> '' then
                        _ItemJnlLine.SetRange("Variant Code", VariantCode);
                end;
            else
                _ItemJnlBatch.SetRange(Name, '22e35d32-8'); // Empty list
        end;
    end;

    /// <summary>
    /// Search Item Journal Batch by BatchName and within current Template/Location-filter (but ignoring other filters)
    /// </summary>
    local procedure SearchItemJournalBatch(_ScannedValue: Text; var _FilteredItemJnlBatch: Record "Item Journal Batch"): Boolean
    var
        ItemJnlBatch2: Record "Item Journal Batch";
    begin
        if (_ScannedValue = '') or (not MobToolbox.IsValidExpressionLen(_ScannedValue, MaxStrLen(ItemJnlBatch2.Name))) then
            exit(false);

        ItemJnlBatch2.Copy(_FilteredItemJnlBatch);
        ReplaceFilterItemJnlBatch(ItemJnlBatch2, _ScannedValue);
        if ItemJnlBatch2.FindFirst() then begin
            _FilteredItemJnlBatch := ItemJnlBatch2;
            exit(true);
        end;

        exit(false);
    end;

    /// <summary>
    /// Set new filter for only BatchName and current Template-filter (ignoring all other filters)
    /// </summary>
    local procedure ReplaceFilterItemJnlBatch(var _ItemJnlBatch: Record "Item Journal Batch"; _ScannedValue: Text): Boolean
    var
        ItemJnlBatch2: Record "Item Journal Batch";
    begin
        ItemJnlBatch2.Copy(_ItemJnlBatch);

        _ItemJnlBatch.Reset();
        _ItemJnlBatch.SetFilter(Name, _ScannedValue);
        ItemJnlBatch2.CopyFilter("Journal Template Name", _ItemJnlBatch."Journal Template Name");
        ItemJnlBatch2.CopyFilter(MOBReleasedToMobile, _ItemJnlBatch.MOBReleasedToMobile);
    end;


    //
    // Warehouse Journal (Batch and Line)
    //

    /// <summary>
    /// Filter BatchName or Item/Variant by _ScannedValue (match for scanned batch name at location takes precedence over other filters)
    /// </summary>
    procedure SetFilterForWhseJnl(var _WhseJnlBatch: Record "Warehouse Journal Batch"; var _WhseJnlLine: Record "Warehouse Journal Line"; _ScannedValue: Text)
    var
        ItemNumber: Code[50];
        VariantCode: Code[10];
    begin
        case true of
            SearchWhseJournalBatch(_ScannedValue, _WhseJnlBatch):
                ReplaceFilterWhseJnlBatch(_WhseJnlBatch, _ScannedValue);
            SearchItemReference(_ScannedValue, ItemNumber, VariantCode):
                begin
                    _WhseJnlLine.SetRange("Item No.", ItemNumber);
                    if VariantCode <> '' then
                        _WhseJnlLine.SetRange("Variant Code", VariantCode);
                end;
            else
                _WhseJnlBatch.SetRange(Name, '22e35d32-8'); // Empty list
        end;
    end;

    /// <summary>
    /// Search Warehouse Journal Batch by BatchName and within current Template/Location-filter (but ignoring other filters)
    /// </summary>
    local procedure SearchWhseJournalBatch(_ScannedValue: Text; var _FilteredWhseJnlBatch: Record "Warehouse Journal Batch"): Boolean
    var
        WhseJnlBatch2: Record "Warehouse Journal Batch";
    begin
        if (_ScannedValue = '') or (not MobToolbox.IsValidExpressionLen(_ScannedValue, MaxStrLen(WhseJnlBatch2.Name))) then
            exit(false);

        WhseJnlBatch2.Copy(_FilteredWhseJnlBatch);
        ReplaceFilterWhseJnlBatch(WhseJnlBatch2, _ScannedValue);
        if WhseJnlBatch2.FindFirst() then begin
            _FilteredWhseJnlBatch := WhseJnlBatch2;
            exit(true);
        end;

        exit(false);
    end;

    /// <summary>
    /// Set new filter for only BatchName and current Template-filter (ignoring all other filters)
    /// </summary>
    local procedure ReplaceFilterWhseJnlBatch(var _WhseJnlBatch: Record "Warehouse Journal Batch"; _ScannedValue: Text): Boolean
    var
        WhseJnlBatch2: Record "Warehouse Journal Batch";
    begin
        WhseJnlBatch2.Copy(_WhseJnlBatch);

        _WhseJnlBatch.Reset();
        _WhseJnlBatch.SetFilter(Name, _ScannedValue);
        WhseJnlBatch2.CopyFilter("Journal Template Name", _WhseJnlBatch."Journal Template Name");
        WhseJnlBatch2.CopyFilter(MOBReleasedToMobile, _WhseJnlBatch.MOBReleasedToMobile);
    end;

    //
    // Assembly
    //

    /// <summary>
    /// Filter Assembly No or Item/Variant by _ScannedValue (match for scanned assembly no. at location takes precedence over other filters)
    /// </summary>
    internal procedure SetFilterForAssemblyOrder(var _AssemblyHeader: Record "Assembly Header"; _ScannedValue: Text)
    var
        ItemNumber: Code[50];
        VariantCode: Code[10];
    begin
        case true of
            SearchAssemblyHeader(_ScannedValue, _AssemblyHeader):
                ReplaceFilterAssemblyHeader(_AssemblyHeader, _ScannedValue);
            SearchItemReference(_ScannedValue, ItemNumber, VariantCode):
                begin
                    _AssemblyHeader.SetRange("Item No.", ItemNumber);
                    if VariantCode <> '' then
                        _AssemblyHeader.SetRange("Variant Code", VariantCode);
                end;
            else
                _AssemblyHeader.SetRange("No.", '22e35d32-8aa2-4181-8'); // Empty list
        end;
    end;

    /// <summary>
    /// Search Assembly Header by Assembly No and within current Location-filter (but ignoring other filters)
    /// </summary>
    local procedure SearchAssemblyHeader(_ScannedValue: Text; var _FilteredHeader: Record "Assembly Header"): Boolean
    var
        AssemblyHeader2: Record "Assembly Header";
    begin
        if (_ScannedValue = '') or (not MobToolbox.IsValidExpressionLen(_ScannedValue, MaxStrLen(AssemblyHeader2."No."))) then
            exit(false);

        AssemblyHeader2.Copy(_FilteredHeader);
        ReplaceFilterAssemblyHeader(AssemblyHeader2, _ScannedValue);
        if AssemblyHeader2.FindFirst() then begin
            _FilteredHeader := AssemblyHeader2;
            exit(true);
        end;

        exit(false);
    end;

    /// <summary>
    /// Set new filter for only Assembly Order and current Location-filter (ignoring all other filters)
    /// </summary>
    local procedure ReplaceFilterAssemblyHeader(var _AssemblyHeader: Record "Assembly Header"; _ScannedValue: Text): Boolean
    var
        AssemblyHeader2: Record "Assembly Header";
    begin
        AssemblyHeader2.Copy(_AssemblyHeader);

        _AssemblyHeader.Reset();
        _AssemblyHeader.SetFilter("No.", _ScannedValue);
        AssemblyHeader2.CopyFilter("Location Code", _AssemblyHeader."Location Code");
    end;


    //
    // Phys. Invt. Recording
    //

    // See "MOB WMS Phys Invt Recording.al" (tables only exists in BC14)

}
