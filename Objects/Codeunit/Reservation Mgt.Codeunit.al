codeunit 81289 "MOB Reservation Mgt."
{
    Access = Public;

    internal procedure DetermineItemTrackingRequiredByWhseReceiptLine(_WhseReceiptLine: Record "Warehouse Receipt Line"; var _MobTrackingSetup: Record "MOB Tracking Setup"; var _RegisterExpirationDate: Boolean)
    var
        EntryType: Integer;
    begin

        // Determine entrytype
        case _WhseReceiptLine."Source Document" of
            _WhseReceiptLine."Source Document"::"Purchase Order":
                EntryType := 0; // Purchase
            _WhseReceiptLine."Source Document"::"Sales Return Order":
                EntryType := 1; // Sales
            _WhseReceiptLine."Source Document"::"Inbound Transfer":
                EntryType := 4; // Transfer
        end;

        DetermineItemTrackingRequiredByEntryType(_WhseReceiptLine."Item No.", true, EntryType, _MobTrackingSetup, _RegisterExpirationDate);

        if _WhseReceiptLine."Source Document" = _WhseReceiptLine."Source Document"::"Inbound Transfer" then
            _RegisterExpirationDate := false;
    end;

    internal procedure DetermineItemTrackingRequiredByWhseShipmentLine(_WhseShipmentLine: Record "Warehouse Shipment Line"; var _MobTrackingSetup: Record "MOB Tracking Setup"; var _RegisterExpirationDate: Boolean)
    var
        EntryType: Integer;
    begin
        // Determine entrytype
        case _WhseShipmentLine."Source Document" of
            _WhseShipmentLine."Source Document"::"Purchase Return Order":
                EntryType := 0; // Purchase
            _WhseShipmentLine."Source Document"::"Sales Order":
                EntryType := 1; // Sales
            _WhseShipmentLine."Source Document"::"Outbound Transfer":
                EntryType := 4; // Transfer
        end;

        DetermineItemTrackingRequiredByEntryType(_WhseShipmentLine."Item No.", false, EntryType, _MobTrackingSetup, _RegisterExpirationDate);
    end;

    internal procedure DetermineItemTrackingRequiredByPurchaseLine(_PurchaseLine: Record "Purchase Line"; var _MobTrackingSetup: Record "MOB Tracking Setup"; var _RegisterExpirationDate: Boolean)
    var
        Inbound: Boolean;
    begin
        _MobTrackingSetup.ClearTrackingRequired();
        _RegisterExpirationDate := false;

        if not _PurchaseLine.IsInventoriableItem() then
            exit;

        // Purchase is inbound unless Doc. Type is Return Order
        Inbound := _PurchaseLine."Document Type" <> _PurchaseLine."Document Type"::"Return Order";
        DetermineItemTrackingRequiredByEntryType(_PurchaseLine."No.", Inbound, 0, _MobTrackingSetup, _RegisterExpirationDate); // 0 = Purchase
    end;

    internal procedure DetermineItemTrackingRequiredBySalesLine(_SalesLine: Record "Sales Line"; var _MobTrackingSetup: Record "MOB Tracking Setup"; var _RegisterExpirationDate: Boolean)
    var
        Inbound: Boolean;
    begin
        _MobTrackingSetup.ClearTrackingRequired();
        _RegisterExpirationDate := false;

        if not _SalesLine.IsInventoriableItem() then
            exit;

        // Sales is Outbound unless Doc. Type is Return Order
        Inbound := _SalesLine."Document Type" = _SalesLine."Document Type"::"Return Order";
        DetermineItemTrackingRequiredByEntryType(_SalesLine."No.", Inbound, 1, _MobTrackingSetup, _RegisterExpirationDate); // 1 = Sales
    end;

    internal procedure DetermineItemTrackingRequiredByAssemblyHeader(_AssemblyHeader: Record "Assembly Header"; var _MobTrackingSetup: Record "MOB Tracking Setup"; var _RegisterExpirationDate: Boolean)
    var
        Inbound: Boolean;
    begin
        _MobTrackingSetup.ClearTrackingRequired();
        _RegisterExpirationDate := false;

        // Assembly Output is always Inbound
        Inbound := true;
        DetermineItemTrackingRequiredByEntryType(_AssemblyHeader."Item No.", Inbound, 9, _MobTrackingSetup, _RegisterExpirationDate); // 9 = Assembly Output
    end;

    internal procedure DetermineItemTrackingRequiredByAssemblyLine(_AssemblyLine: Record "Assembly Line"; var _MobTrackingSetup: Record "MOB Tracking Setup"; var _RegisterExpirationDate: Boolean)
    var
        MobCommonMgt: Codeunit "MOB Common Mgt.";
        Inbound: Boolean;
    begin
        _MobTrackingSetup.ClearTrackingRequired();
        _RegisterExpirationDate := false;

        if not MobCommonMgt.AssemblyLine_IsInventoriableItem(_AssemblyLine) then
            exit;

        // Assembly Consumption is always Outbound
        Inbound := false;
        DetermineItemTrackingRequiredByEntryType(_AssemblyLine."No.", Inbound, 8, _MobTrackingSetup, _RegisterExpirationDate); // 8 = Assembly Consumption
    end;

    internal procedure DetermineItemTrackingRequiredByEntryType(_ItemNo: Code[20]; _Inbound: Boolean; _EntryType: Option Purchase,Sale,"Positive Adjmt.","Negative Adjmt.",Transfer,Consumption,Output," ","Assembly Consumption","Assembly Output"; var _MobTrackingSetup: Record "MOB Tracking Setup"; var _RegisterExpirationDate: Boolean)
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        MobItemTrackingManagement: Codeunit "MOB Item Tracking Management";
    begin
        // 1. Get the item tracking code from the item
        // 2. Use the item tracking code to determine if serial - lot numbers should be registered
        _MobTrackingSetup.ClearTrackingRequired();
        _RegisterExpirationDate := false;

        if Item.Get(_ItemNo) and Item.IsInventoriableType() then begin

            ItemTrackingCode.Code := Item."Item Tracking Code";
            MobItemTrackingManagement.GetItemTrackingSetup(ItemTrackingCode, _EntryType, _Inbound, _MobTrackingSetup);

            // Expiration date is registered on purchase orders
            if _Inbound and _MobTrackingSetup.TrackingRequired() then
                _RegisterExpirationDate := ItemTrackingCode."Man. Expir. Date Entry Reqd.";
        end;
    end;

    internal procedure DetermineItemTrackingRequired(_WhseActLine: Record "Warehouse Activity Line"; var _MobTrackingSetup: Record "MOB Tracking Setup"; var _RegisterExpirationDate: Boolean)
    var
        ItemTrackingCode: Record "Item Tracking Code";
        Item: Record Item;
    begin
        // 1. Get the item tracking code from the item
        // 2. Use the item tracking code to determine if serial / lot / package numbers should be registered
        _MobTrackingSetup.ClearTrackingRequired();
        _RegisterExpirationDate := false;

        if Item.Get(_WhseActLine."Item No.") and ItemTrackingCode.Get(Item."Item Tracking Code") then
            case _WhseActLine."Activity Type" of
                _WhseActLine."Activity Type"::"Put-away":
                    begin
                        // Warehouse put-aways are generated from Warehouse Receipts
                        // The only scenario where whse. put-aways require item tracking is if "warehouse tracking" is enabled
                        _MobTrackingSetup."Serial No. Required" := ItemTrackingCode."SN Warehouse Tracking";
                        _MobTrackingSetup."Lot No. Required" := ItemTrackingCode."Lot Warehouse Tracking";
                    end;
                _WhseActLine."Activity Type"::"Invt. Put-away":
                    begin
                        // Inventory put-aways are generated from Purchase Orders, Transfer Orders, Sales Return Orders, Production Orders and Assembly Orders
                        if _WhseActLine."Source Document" = _WhseActLine."Source Document"::"Purchase Order" then begin
                            _MobTrackingSetup."Serial No. Required" := ItemTrackingCode."SN Purchase Inbound Tracking";
                            _MobTrackingSetup."Lot No. Required" := ItemTrackingCode."Lot Purchase Inbound Tracking";
                            // Expiration date is registered on Purchase Orders
                            _RegisterExpirationDate := ItemTrackingCode."Man. Expir. Date Entry Reqd.";
                        end;
                        if _WhseActLine."Source Document" = _WhseActLine."Source Document"::"Inbound Transfer" then begin
                            // Inventory put-aways generated from transfer orders do not require item tracking
                            // The tracking lines have been generated on the outbound registration
                            // Still we enable item tracking to verify that the correct serials and lots arrive
                            _MobTrackingSetup."Serial No. Required" := ItemTrackingCode."SN Specific Tracking";
                            _MobTrackingSetup."Lot No. Required" := ItemTrackingCode."Lot Specific Tracking";
                        end;
                        if _WhseActLine."Source Document" = _WhseActLine."Source Document"::"Sales Return Order" then begin
                            _MobTrackingSetup."Serial No. Required" := ItemTrackingCode."SN Sales Inbound Tracking";
                            _MobTrackingSetup."Lot No. Required" := ItemTrackingCode."Lot Sales Inbound Tracking";
                            // Expiration date is registered on Sales Return Orders
                            _RegisterExpirationDate := ItemTrackingCode."Man. Expir. Date Entry Reqd.";
                        end;
                        if _WhseActLine."Source Document" = _WhseActLine."Source Document"::"Prod. Output" then begin
                            _MobTrackingSetup."Serial No. Required" := ItemTrackingCode."SN Manuf. Inbound Tracking";
                            _MobTrackingSetup."Lot No. Required" := ItemTrackingCode."Lot Manuf. Inbound Tracking";
                            // Expiration date is registered on Production Orders
                            _RegisterExpirationDate := ItemTrackingCode."Man. Expir. Date Entry Reqd.";
                        end;
                        if _WhseActLine."Source Document" = _WhseActLine."Source Document"::"Assembly Order" then begin
                            _MobTrackingSetup."Serial No. Required" := ItemTrackingCode."SN Assembly Inbound Tracking";
                            _MobTrackingSetup."Lot No. Required" := ItemTrackingCode."Lot Assembly Inbound Tracking";
                            // Expiration date is registered on Assembly Orders
                            _RegisterExpirationDate := ItemTrackingCode."Man. Expir. Date Entry Reqd.";
                        end;
                        if (_WhseActLine."Source Document" = _WhseActLine."Source Document"::" ") and (_WhseActLine."Source Type" = Database::"Whse. Internal Put-away Line") then begin
                            _MobTrackingSetup."Serial No. Required" := ItemTrackingCode."SN Specific Tracking";
                            _MobTrackingSetup."Lot No. Required" := ItemTrackingCode."Lot Specific Tracking";
                        end;
                    end;
                _WhseActLine."Activity Type"::Pick,
                _WhseActLine."Activity Type"::"Invt. Pick":
                    begin
                        // Warehouse Picks are generated from Warehouse Shipments (in turn generated from Sales Orders, Service Orders, Purchase Return Orders and Transfer Orders)
                        // Warehouse Picks are also generated from Production Orders and Assembly Orders
                        // Inventory picks are generated from Sales Orders, Purchase Return Orders, Transfer Orders, Production Orders and Assembly Orders
                        if _WhseActLine."Source Document" in [_WhseActLine."Source Document"::"Sales Order", _WhseActLine."Source Document"::"Service Order"] then begin
                            // No individual checkbox exists for Service Orders as NAV posts Item Ledger Entries for Service Orders as Sales (Entry Type = Sale)
                            _MobTrackingSetup."Serial No. Required" := ItemTrackingCode."SN Sales Outbound Tracking";
                            _MobTrackingSetup."Lot No. Required" := ItemTrackingCode."Lot Sales Outbound Tracking";
                        end;
                        if _WhseActLine."Source Document" = _WhseActLine."Source Document"::"Purchase Return Order" then begin
                            _MobTrackingSetup."Serial No. Required" := ItemTrackingCode."SN Purchase Outbound Tracking";
                            _MobTrackingSetup."Lot No. Required" := ItemTrackingCode."Lot Purchase Outbound Tracking";
                        end;
                        if _WhseActLine."Source Document" = _WhseActLine."Source Document"::"Outbound Transfer" then begin
                            _MobTrackingSetup."Serial No. Required" := ItemTrackingCode."SN Transfer Tracking";
                            _MobTrackingSetup."Lot No. Required" := ItemTrackingCode."Lot Transfer Tracking";
                        end;
                        if _WhseActLine."Source Document" = _WhseActLine."Source Document"::"Prod. Consumption" then begin
                            _MobTrackingSetup."Serial No. Required" := ItemTrackingCode."SN Manuf. Outbound Tracking";
                            _MobTrackingSetup."Lot No. Required" := ItemTrackingCode."Lot Manuf. Outbound Tracking";
                        end;
                        if _WhseActLine."Source Document" = _WhseActLine."Source Document"::"Assembly Consumption" then begin
                            _MobTrackingSetup."Serial No. Required" := ItemTrackingCode."SN Assembly Outbound Tracking";
                            _MobTrackingSetup."Lot No. Required" := ItemTrackingCode."Lot Assembly Outbound Tracking";
                        end;
                        if (_WhseActLine."Source Document" = _WhseActLine."Source Document"::" ") and (_WhseActLine."Source Type" = Database::"Whse. Internal Pick Line") then begin
                            _MobTrackingSetup."Serial No. Required" := ItemTrackingCode."SN Specific Tracking";
                            _MobTrackingSetup."Lot No. Required" := ItemTrackingCode."Lot Specific Tracking";
                        end;
                        // Job Usage only available from BC20, but checked from BC19 instead of making specific BC20 platform files
                        /* #if BC19+ */
                        if _WhseActLine."Source Document".AsInteger() = 22 then begin // 22 = Job Usage
                            _MobTrackingSetup."Serial No. Required" := ItemTrackingCode."SN Neg. Adjmt. Outb. Tracking";
                            _MobTrackingSetup."Lot No. Required" := ItemTrackingCode."Lot Neg. Adjmt. Outb. Tracking";
                        end;
                        /* #endif */
                    end;
                _WhseActLine."Activity Type"::Movement,
                _WhseActLine."Activity Type"::"Invt. Movement":
                    begin
                        // The only scenario where item tracking is enabled for movements is when "Warehouse Tracking" is enabled
                        _MobTrackingSetup."Serial No. Required" := ItemTrackingCode."SN Warehouse Tracking";
                        _MobTrackingSetup."Lot No. Required" := ItemTrackingCode."Lot Warehouse Tracking";
                    end;
            end; // CASE

        // In BC18+: MobTrackingSetup.OnAfterDetermineItemTrackingRequired(_WhseActLine, Rec, _RegisterExpirationDate) is triggered from MobTrackingSetup table
    end;

    internal procedure DetermineWhseTrackingRequiredWithExpirationDate(_ItemNo: Code[20]; var _MobTrackingSetup: Record "MOB Tracking Setup"; var _SpeficicRegisterExpirationDate: Boolean)
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        MobCommonMgt: Codeunit "MOB Common Mgt.";
    begin
        _MobTrackingSetup.DetermineWhseTrackingRequired(_ItemNo, _SpeficicRegisterExpirationDate);
        _SpeficicRegisterExpirationDate := false;

        if Item.Get(_ItemNo) then
            if ItemTrackingCode.Get(Item."Item Tracking Code") and MobCommonMgt.ItemTrackingCode_IsSpecific(ItemTrackingCode) then
                /* #if BC15+ */
                _SpeficicRegisterExpirationDate := (ItemTrackingCode."Man. Expir. Date Entry Reqd." or ItemTrackingCode."Use Expiration Dates");
        /* #endif */
        /* #if BC14 ##
        _SpeficicRegisterExpirationDate := ItemTrackingCode."Man. Expir. Date Entry Reqd.";
        /* #endif */
    end;

    /// <remarks>
    /// Throw error if Warehouse Tracking is not also required when specific Tracking is required.  Currently used only from Adhoc BulkMove
    /// </remarks>
    procedure CheckWhseTrackingEnabledIfSpecificTrackingRequired(_ItemNo: Code[20])
    var
        ItemTrackingCode: Record "Item Tracking Code";
        Item: Record Item;
        MobWmsLanguage: Codeunit "MOB WMS Language";
    begin
        // 1. Get the item tracking code from the item
        // 2. Use the item tracking code to determine if serial / lot numbers should be registered
        if Item.Get(_ItemNo) then
            if ItemTrackingCode.Get(Item."Item Tracking Code") then begin
                if ItemTrackingCode."SN Specific Tracking" then
                    if not ItemTrackingCode."SN Warehouse Tracking" then
                        Error(MobWmsLanguage.GetMessage('WHSE_TRKG_NEEDED'), _ItemNo);
                if ItemTrackingCode."Lot Specific Tracking" then
                    if not ItemTrackingCode."Lot Warehouse Tracking" then
                        Error(MobWmsLanguage.GetMessage('WHSE_TRKG_NEEDED'), _ItemNo);

                OnAfterCheckWhseTrackingEnabledIfSpecificTrackingRequired(ItemTrackingCode, _ItemNo);
            end;

    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckWhseTrackingEnabledIfSpecificTrackingRequired(_ItemTrackingCode: Record "Item Tracking Code"; _ItemNo: Code[20])
    begin
    end;

}
