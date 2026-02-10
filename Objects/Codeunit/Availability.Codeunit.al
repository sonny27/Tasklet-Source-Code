codeunit 81397 "MOB Availability"
// Everything related to item/warehouse availability

{
    Access = Public;
    var
        OneOrMoreReservation_Txt: Label 'One or more reservation entries exist for the item with %1 = %2, %3 = %4, %5 = %6 which may be disrupted if you post this negative adjustment.', Comment = '%1, %3 and %5 contains Field Caption, %2, %4 and %6 contains Fields value';

    //
    // ------- ITEM -------
    //

    procedure ItemGetAvailability(_LocationCode: Code[10]; _ItemNo: Code[20]; _VariantCode: Code[10]; _MobTrackingSetup: Record "MOB Tracking Setup"; var _ReturnReservedQtyOnInventory: Decimal; var _ReturnNetChangeQty: Decimal)
    var
        Item: Record Item;
    begin
        // Gets the Item Inventory. Available and Reserved separately
        // Used in our version of Base checks in the object

        Item.SetFilter("Location Filter", _LocationCode);
        if _VariantCode <> '' then
            Item.SetFilter("Variant Filter", _VariantCode);
        _MobTrackingSetup.SetTrackingFilterForItemIfNotBlank(Item);

        Item.SetAutoCalcFields("Reserved Qty. on Inventory", "Net Change");
        Item.Get(_ItemNo);

        _ReturnReservedQtyOnInventory := Item."Reserved Qty. on Inventory";
        _ReturnNetChangeQty := Item."Net Change";
    end;

    /// <summary>
    /// Replaced by procedure ItemGetAvailability() with parameter "Mob Tracking Setup"  (but not planned for removal for backwards compatibility)
    /// </summary>
    procedure ItemGetAvailability(_LocationCode: Code[10]; _ItemNo: Code[20]; _VariantCode: Code[10]; _LotNo: Code[50]; _SerialNo: Code[50]; var _ReturnReservedQtyOnInventory: Decimal; var _ReturnNetChangeQty: Decimal)
    var
        MobTrackingSetup: Record "MOB Tracking Setup";
    begin
        MobTrackingSetup.ClearTrackingRequired();
        MobTrackingSetup."Serial No." := _SerialNo;
        MobTrackingSetup."Lot No." := _LotNo;

        ItemGetAvailability(_LocationCode, _ItemNo, _VariantCode, MobTrackingSetup, _ReturnReservedQtyOnInventory, _ReturnNetChangeQty);
    end;

    //
    // ------- ITEM JOURNAL -------
    //

    procedure ItemJnlPostBatch_CheckItemAvailability(_LocationCode: Code[10]; _ItemNo: Code[20]; _VariantCode: Code[10]; _MobTrackingSetup: Record "MOB Tracking Setup"; _RequiredQty: Decimal; _OrderType: Option; _OrderNo: Code[20])
    var
        ItemJnlLine: Record "Item Journal Line";
        ReservedQtyOnInventory: Decimal;
        AvailableQty: Decimal;
        NetChangeQty: Decimal;
    begin
        // This is our version of base Codeunit 23: "Item Jnl.-Post Batch" Function: CheckItemAvailability
        // Unlike base this only works on ONE jnl line
        // Gets the Available Item Inventory - error if reservations exists

        ItemGetAvailability(_LocationCode, _ItemNo, _VariantCode, _MobTrackingSetup, ReservedQtyOnInventory, NetChangeQty);
        AvailableQty := NetChangeQty -
                        ReservedQtyOnInventory +
                        SelfReservedQty(_LocationCode, _ItemNo, _VariantCode, _OrderType, _OrderNo);

        if (ReservedQtyOnInventory > 0) and (AvailableQty < Abs(_RequiredQty)) then
            // Base will make a Confirm - we throw Error
            Error(OneOrMoreReservation_Txt, ItemJnlLine.FieldCaption("Item No."), _ItemNo,
                                            ItemJnlLine.FieldCaption("Location Code"), _LocationCode,
                                            ItemJnlLine.FieldCaption("Variant Code"), _VariantCode)
    end;

    local procedure SelfReservedQty(_LocationCode: Code[10]; _ItemNo: Code[20]; _VariantCode: Code[10]; _OrderType: Option; _OrderNo: Code[20]): Decimal
    var
        ReservationEntry: Record "Reservation Entry";
        ItemJnlLine: Record "Item Journal Line";
        MobToolbox: Codeunit "MOB Toolbox";
    begin
        if _OrderType <> MobToolbox.AsInteger(ItemJnlLine."Order Type"::Production) then
            exit;

        ReservationEntry.SetRange("Item No.", _ItemNo);
        ReservationEntry.SetRange("Location Code", _LocationCode);
        ReservationEntry.SetRange("Variant Code", _VariantCode);
        ReservationEntry.SetRange("Source Type", Database::"Prod. Order Component");
        ReservationEntry.SetRange("Source ID", _OrderNo);
        if ReservationEntry.IsEmpty() then
            exit;
        ReservationEntry.CalcSums("Quantity (Base)");
        exit(-ReservationEntry."Quantity (Base)");
    end;

    //
    // ------- WAREHOUSE JOURNAL -------
    //

    procedure WhseJnlRegisterBatch_CheckItemAvailability(_LocationCode: Code[10]; _ItemNo: Code[20]; _VariantCode: Code[10]; _MobTrackingSetup: Record "MOB Tracking Setup"; _RequiredQty: Decimal)

    var
        WhseJnlLine: Record "Warehouse Journal Line";
        WhseJnlLineQty: Decimal;
        ReservedQtyOnInventory: Decimal;
        NetChangeQty: Decimal;
        QtyOnWarehouseEntries: Decimal;
    begin
        // This is our version of base Codeunit: 7304 "Whse. Jnl.-Register Batch" Function: CheckItemAvailability
        // Unlike base this only works on ONE jnl line
        // Gets the Available Item Inventory - error if reservations exists

        WhseJnlLineQty := CalcRequiredQty(_ItemNo, _LocationCode, _VariantCode);
        if WhseJnlLineQty < 0 then begin
            ItemGetAvailability(_LocationCode, _ItemNo, _VariantCode, _MobTrackingSetup, ReservedQtyOnInventory, NetChangeQty);

            QtyOnWarehouseEntries := CalcQtyOnWarehouseEntry(_ItemNo, _LocationCode, _VariantCode);
            if (ReservedQtyOnInventory > 0) and ((QtyOnWarehouseEntries - ReservedQtyOnInventory) < Abs(WhseJnlLineQty)) then
                // Base will make a Confirm - we throw Error
                Error(OneOrMoreReservation_Txt, WhseJnlLine.FieldCaption("Item No."), _ItemNo,
                                                WhseJnlLine.FieldCaption("Location Code"), _LocationCode,
                                                WhseJnlLine.FieldCaption("Variant Code"), _VariantCode);
        end;
    end;

    local procedure CalcRequiredQty(_ItemNo: Code[20]; _LocationCode: Code[20]; _VariantCode: Code[20]): Decimal
    var
        WhseJnlLine: Record "Warehouse Journal Line";
    begin
        WhseJnlLine.SetRange("Item No.", _ItemNo);
        WhseJnlLine.SetRange("Location Code", _LocationCode);
        WhseJnlLine.SetRange("Variant Code", _VariantCode);
        WhseJnlLine.CalcSums("Qty. (Base)");
        exit(WhseJnlLine."Qty. (Base)");
    end;

    local procedure CalcQtyOnWarehouseEntry(_ItemNo: Code[20]; _LocationCode: Code[20]; _VariantCode: Code[20]): Decimal
    var
        WarehouseEntry: Record "Warehouse Entry";
    begin
        WarehouseEntry.Reset();
        WarehouseEntry.SetCurrentKey("Item No.", "Location Code", "Variant Code", "Bin Type Code", "Unit of Measure Code", "Lot No.", "Serial No.");
        WarehouseEntry.SetRange("Item No.", _ItemNo);
        WarehouseEntry.SetRange("Location Code", _LocationCode);
        WarehouseEntry.SetRange("Variant Code", _VariantCode);
        WarehouseEntry.CalcSums("Qty. (Base)");
        exit(WarehouseEntry."Qty. (Base)");
    end;


    /// <remarks>
    /// Cloned from AssemblyLineManagement.AvailToPromise()
    /// </remarks>
    internal procedure AssemblyLineManagement_AvailToPromise(AsmHeader: Record "Assembly Header"; var AssemblyLine: Record "Assembly Line"; var OrderAbleToAssemble: Decimal; var EarliestDueDate: Date)
    var
        LineAvailabilityDate: Date;
        LineStartingDate: Date;
        EarliestStartingDate: Date;
        LineAbleToAssemble: Decimal;
    begin
        Clear(EarliestStartingDate);

        AssemblyLine.SetRange("Document Type", AsmHeader."Document Type");
        AssemblyLine.SetRange("Document No.", AsmHeader."No.");
        AssemblyLine.SetFilter("No.", '<>%1', '');
        AssemblyLine.SetFilter("Quantity per", '<>%1', 0);
        OrderAbleToAssemble := AsmHeader."Remaining Quantity";
        if AssemblyLine.FindSet() then
            repeat
                LineAbleToAssemble := AssemblyLineManagement_CalcAvailToAssemble(AssemblyLine, AsmHeader, LineAvailabilityDate);

                if LineAbleToAssemble < OrderAbleToAssemble then
                    OrderAbleToAssemble := LineAbleToAssemble;

                if LineAvailabilityDate > 0D then begin
                    LineStartingDate := CalcDate(AssemblyLine."Lead-Time Offset", LineAvailabilityDate);
                    if LineStartingDate > EarliestStartingDate then
                        EarliestStartingDate := LineStartingDate; // latest of all line starting dates
                end;
            until AssemblyLine.Next() = 0;

        EarliestDueDate := AssemblyLineManagement_CalcEarliestDueDate(AsmHeader, EarliestStartingDate);
    end;

    /// <remarks>
    /// Cloned from AssemblyLineManagement.CalcAvailToAssemble()
    /// </remarks>
    local procedure AssemblyLineManagement_CalcAvailToAssemble(AssemblyLine: Record "Assembly Line"; AsmHeader: Record "Assembly Header"; var LineAvailabilityDate: Date) LineAbleToAssemble: Decimal
    var
        Item: Record Item;
        GrossRequirement: Decimal;
        ScheduledRcpt: Decimal;
        ExpectedInventory: Decimal;
        LineInventory: Decimal;
    begin
        AssemblyLine.CalcAvailToAssemble(
          AsmHeader, Item, GrossRequirement, ScheduledRcpt, ExpectedInventory, LineInventory,
          LineAvailabilityDate, LineAbleToAssemble);
    end;

    /// <remarks>
    /// Cloned from AssemblyLineManagement.CalcEarliestDueDate()
    /// </remarks>
    local procedure AssemblyLineManagement_CalcEarliestDueDate(AsmHeader: Record "Assembly Header"; EarliestStartingDate: Date) EarliestDueDate: Date
    var
        ReqLine: Record "Requisition Line";
        LeadTimeMgt: Codeunit "Lead-Time Management";
        MobLeadTimeMgt: Codeunit "MOB Lead-Time Management";
        EarliestEndingDate: Date;
    begin
        EarliestDueDate := 0D;
        if EarliestStartingDate > 0D then begin
            EarliestEndingDate :=
                MobLeadTimeMgt.GetPlannedEndingDate(AsmHeader."Item No.", AsmHeader."Location Code", AsmHeader."Variant Code",
                '', LeadTimeMgt.ManufacturingLeadTime(AsmHeader."Item No.", AsmHeader."Location Code", AsmHeader."Variant Code"),
                ReqLine."Ref. Order Type"::Assembly, EarliestStartingDate); // earliest starting date + lead time calculation
            EarliestDueDate :=
                MobLeadTimeMgt.GetPlannedDueDate(AsmHeader."Item No.", AsmHeader."Location Code", AsmHeader."Variant Code",
                EarliestEndingDate, '', ReqLine."Ref. Order Type"::Assembly); // earliest ending date + (default) safety lead time
        end;
    end;
}
