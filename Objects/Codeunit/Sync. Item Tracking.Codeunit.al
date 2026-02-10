codeunit 81290 "MOB Sync. Item Tracking"
{
    Access = Public;
    Permissions = tabledata "Reservation Entry" = rimd;

    TableNo = "Reservation Entry";

    trigger OnRun()
    begin
        if Rec.IsEmpty() then
            exit;

        SynchronizeItemTrkg(Rec, not SuppressClearQtyToHandle);
    end;

    var
        MobToolbox: Codeunit "MOB Toolbox";
        ActivityTypeMustNotBeErr: Label 'MOB Sync Item Tracking.WhseActivitySignFactor(): %1 must not be %2.', Comment = '%1 contains Activity Type Fieldcaption, %2 contains Activity Type', Locked = true;
        SuppressClearQtyToHandle: Boolean;
        CannotMatchItemTrackingErr: Label 'MOB Sync Item Tracking.SynchronizeItemTrkg(): Cannot match item tracking: %1 for Item No. %2 Variant %3.', Locked = true;

    procedure CreateTempReservEntryForItemJnlLineFromMobWmsRegistration(_ItemJnlLine: Record "Item Journal Line"; _MobWmsRegistration: Record "MOB WMS Registration"; var _TempReservEntry: Record "Reservation Entry"; _QtyBase: Decimal)
    var
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        SignFactor: Integer;
        ToRowID: Text;
    begin
        // Used for carrying the item tracking from the registration to the Item Journal Line
        if not _MobWmsRegistration.TrackingExists() then
            exit;

        ToRowID :=
            ItemTrackingMgt.ComposeRowID(
                Database::"Item Journal Line", MobToolbox.AsInteger(_ItemJnlLine."Entry Type"), _ItemJnlLine."Journal Template Name", _ItemJnlLine."Journal Batch Name", 0, _ItemJnlLine."Line No.");

        _TempReservEntry.SetPointer(ToRowID);
        _TempReservEntry.SetItemData(
            _ItemJnlLine."Item No.",
            _ItemJnlLine.Description,
            _ItemJnlLine."Location Code",
            _ItemJnlLine."Variant Code",
            _ItemJnlLine."Qty. per Unit of Measure");

        if IsInbound(_ItemJnlLine, _QtyBase) then
            SignFactor := 1
        else
            SignFactor := -1;

        InsertTempReservEntryFromMobWmsRegistration(_MobWmsRegistration, _TempReservEntry, _QtyBase, SignFactor);
    end;

    /// <summary>
    /// Clone from ItemJnlLine.IsBound() but including new _Quantity parameter to allow using the function prior to validating ItemJnlLine.Quantity
    /// </summary>
    internal procedure IsInbound(_ItemJnlLine: Record "Item Journal Line"; _Quantity: Decimal): Boolean
    begin
        exit((_ItemJnlLine.Signed(_Quantity) > 0));
    end;

    procedure CreateTempReservEntryForItemJnlLineFromTrackingSpecWithoutQty(_ItemJnlLine: Record "Item Journal Line"; _Inbound: Boolean; _TrackingSpecWithoutQty: Record "Tracking Specification"; var _TempReservEntry: Record "Reservation Entry"; _QtyBase: Decimal)
    var
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        SignFactor: Integer;
        ToRowID: Text;
    begin
        // Used for carrying the item tracking from the registration to the Item Journal Line
        if not _TrackingSpecWithoutQty.TrackingExists() then
            exit;

        ToRowID :=
            ItemTrackingMgt.ComposeRowID(
                Database::"Item Journal Line", MobToolbox.AsInteger(_ItemJnlLine."Entry Type"), _ItemJnlLine."Journal Template Name", _ItemJnlLine."Journal Batch Name", 0, _ItemJnlLine."Line No.");

        _TempReservEntry.SetPointer(ToRowID);
        _TempReservEntry.SetItemData(
            _ItemJnlLine."Item No.",
            _ItemJnlLine.Description,
            _ItemJnlLine."Location Code",
            _ItemJnlLine."Variant Code",
            _ItemJnlLine."Qty. per Unit of Measure");

        if _Inbound then
            SignFactor := 1
        else
            SignFactor := -1;

        InsertTempReservEntryFromTrackingSpecWithoutQty(_TrackingSpecWithoutQty, _TempReservEntry, _QtyBase, SignFactor);
    end;

    procedure CreateTempReservEntryForPurchLine(_PurchaseLine: Record "Purchase Line"; _MobWmsRegistration: Record "MOB WMS Registration"; var _TempReservEntry: Record "Reservation Entry"; _QtyBase: Decimal)
    var
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        SignFactor: Integer;
        ToRowID: Text;
    begin
        // Used for carrying the item tracking from the registration to the Purchase Line
        if not _MobWmsRegistration.TrackingExists() then
            exit;

        ToRowID :=
          ItemTrackingMgt.ComposeRowID(
            Database::"Purchase Line", MobToolbox.AsInteger(_PurchaseLine."Document Type"), _PurchaseLine."Document No.", '', 0, _PurchaseLine."Line No.");

        _TempReservEntry.SetPointer(ToRowID);
        _TempReservEntry.SetItemData(
            _PurchaseLine."No.",
            _PurchaseLine.Description,
            _PurchaseLine."Location Code",
            _PurchaseLine."Variant Code",
            _PurchaseLine."Qty. per Unit of Measure");

        if _PurchaseLine."Document Type" = _PurchaseLine."Document Type"::"Return Order" then
            SignFactor := -1
        else
            SignFactor := 1;

        InsertTempReservEntryFromMobWmsRegistration(_MobWmsRegistration, _TempReservEntry, _QtyBase, SignFactor);
    end;

    procedure CreateTempReservEntryForSalesLine(_SalesLine: Record "Sales Line"; _MobWmsRegistration: Record "MOB WMS Registration"; var _TempReservEntry: Record "Reservation Entry"; _QtyBase: Decimal)
    var
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        SignFactor: Integer;
        ToRowID: Text;
    begin
        // Used for carrying the item tracking from the registration to the Sales Line
        if not _MobWmsRegistration.TrackingExists() then
            exit;

        ToRowID :=
          ItemTrackingMgt.ComposeRowID(
            Database::"Sales Line", MobToolbox.AsInteger(_SalesLine."Document Type"), _SalesLine."Document No.", '', 0, _SalesLine."Line No.");

        _TempReservEntry.SetPointer(ToRowID);
        _TempReservEntry.SetItemData(
            _SalesLine."No.",
            _SalesLine.Description,
            _SalesLine."Location Code",
            _SalesLine."Variant Code",
            _SalesLine."Qty. per Unit of Measure");

        if _SalesLine."Document Type" = _SalesLine."Document Type"::"Return Order" then
            SignFactor := 1
        else
            SignFactor := -1;

        InsertTempReservEntryFromMobWmsRegistration(_MobWmsRegistration, _TempReservEntry, _QtyBase, SignFactor);
    end;

    procedure CreateTempReservEntryForTransferLine(_TransferLine: Record "Transfer Line"; _Inbound: Boolean; _MobWmsRegistration: Record "MOB WMS Registration"; var _TempReservEntry: Record "Reservation Entry"; _QtyBase: Decimal)
    var
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        LocationCode: Code[10];
        SignFactor: Integer;
        ToRowID: Text;
    begin
        // Used for carrying the item tracking from the registration to the Transfer Line
        if not _MobWmsRegistration.TrackingExists() then
            exit;

        if _Inbound then
            ToRowID :=
              ItemTrackingMgt.ComposeRowID(
                Database::"Transfer Line", 1, _TransferLine."Document No.", '', 0, _TransferLine."Line No.")
        else
            ToRowID :=
                  ItemTrackingMgt.ComposeRowID(
                    Database::"Transfer Line", 0, _TransferLine."Document No.", '', 0, _TransferLine."Line No.");

        if _Inbound then begin
            SignFactor := 1;
            LocationCode := _TransferLine."Transfer-to Code";
        end else begin
            SignFactor := -1;
            LocationCode := _TransferLine."Transfer-from Code";
        end;

        _TempReservEntry.SetPointer(ToRowID);
        _TempReservEntry.SetItemData(
            _TransferLine."Item No.",
            _TransferLine.Description,
            LocationCode,
            _TransferLine."Variant Code",
            _TransferLine."Qty. per Unit of Measure");

        InsertTempReservEntryFromMobWmsRegistration(_MobWmsRegistration, _TempReservEntry, _QtyBase, SignFactor);
    end;

    procedure CreateTempReservEntryForWhseActivityLine(_WhseActivityLine: Record "Warehouse Activity Line"; _MobWmsRegistration: Record "MOB WMS Registration"; var _TempReservEntry: Record "Reservation Entry"; _QtyBase: Decimal)
    var
        ATOSalesLine: Record "Sales Line";
        AsmHeader: Record "Assembly Header";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        SignFactor: Integer;
        ToRowID: Text;
        IsTransferReceipt: Boolean;
        IsATOPosting: Boolean;
    begin
        // Used for carrying the item tracking from the registration to the Warehouse Activity Line
        if not _MobWmsRegistration.TrackingExists() then
            exit;

        // Transfer receipt needs special treatment:
        IsTransferReceipt := (_WhseActivityLine."Source Type" = Database::"Transfer Line") and (_WhseActivityLine."Source Subtype" = 1);
        IsATOPosting := (_WhseActivityLine."Source Type" = Database::"Sales Line") and _WhseActivityLine."Assemble to Order";
        if (_WhseActivityLine."Source Type" in [Database::"Prod. Order Line", Database::"Prod. Order Component"]) or IsTransferReceipt then
            ToRowID :=
              ItemTrackingMgt.ComposeRowID(
                _WhseActivityLine."Source Type", _WhseActivityLine."Source Subtype", _WhseActivityLine."Source No.", '', _WhseActivityLine."Source Line No.", _WhseActivityLine."Source Subline No.")
        else
            if IsATOPosting then begin
                ATOSalesLine.Get(_WhseActivityLine."Source Subtype", _WhseActivityLine."Source No.", _WhseActivityLine."Source Line No.");
                ATOSalesLine.AsmToOrderExists(AsmHeader);
                ToRowID :=
                  ItemTrackingMgt.ComposeRowID(
                    Database::"Assembly Header", MobToolbox.AsInteger(AsmHeader."Document Type"), AsmHeader."No.", '', 0, 0);
            end else
                ToRowID :=
                  ItemTrackingMgt.ComposeRowID(
                    _WhseActivityLine."Source Type", _WhseActivityLine."Source Subtype", _WhseActivityLine."Source No.", '', _WhseActivityLine."Source Subline No.", _WhseActivityLine."Source Line No.");

        _TempReservEntry.SetPointer(ToRowID);
        _TempReservEntry.SetItemData(
            _WhseActivityLine."Item No.",
            _WhseActivityLine.Description,
            _WhseActivityLine."Location Code",
            _WhseActivityLine."Variant Code",
            _WhseActivityLine."Qty. per Unit of Measure");

        SignFactor := WhseActivitySignFactor(_WhseActivityLine);
        InsertTempReservEntryFromMobWmsRegistration(_MobWmsRegistration, _TempReservEntry, _QtyBase, SignFactor);
    end;

    procedure CreateTempReservEntryForWhseReceiptLine(_WhseReceiptLine: Record "Warehouse Receipt Line"; _MobWmsRegistration: Record "MOB WMS Registration"; var _TempReservEntry: Record "Reservation Entry"; _QtyBase: Decimal)
    var
        TransferLine: Record "Transfer Line";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        SignFactor: Integer;
        ToRowID: Text;
        IsTransferReceipt: Boolean;
        SourceProdOrderLine: Integer;
        SourceRefNo: Integer;
    begin
        // Used for carrying the item tracking from the registration to the Warehouse Receipt Line
        if not _MobWmsRegistration.TrackingExists() then
            exit;

        // Transfer receipt needs special treatment:
        IsTransferReceipt := (_WhseReceiptLine."Source Type" = Database::"Transfer Line") and (_WhseReceiptLine."Source Subtype" = 1);
        if IsTransferReceipt then begin
            SourceProdOrderLine := _WhseReceiptLine."Source Line No.";
            TransferLine.SetRange("Document No.", _WhseReceiptLine."Source No.");
            TransferLine.SetRange("Derived From Line No.", _WhseReceiptLine."Source Line No.");
            if TransferLine.FindFirst() then
                SourceRefNo := TransferLine."Line No."
            else
                SourceRefNo := 0;
        end else begin
            SourceProdOrderLine := 0;
            SourceRefNo := _WhseReceiptLine."Source Line No.";
        end;

        ToRowID :=
            ItemTrackingMgt.ComposeRowID(
            _WhseReceiptLine."Source Type", _WhseReceiptLine."Source Subtype", _WhseReceiptLine."Source No.", '', SourceProdOrderLine, SourceRefNo);

        _TempReservEntry.SetPointer(ToRowID);
        _TempReservEntry.SetItemData(
            _WhseReceiptLine."Item No.",
            _WhseReceiptLine.Description,
            _WhseReceiptLine."Location Code",
            _WhseReceiptLine."Variant Code",
            _WhseReceiptLine."Qty. per Unit of Measure");

        SignFactor := 1;
        InsertTempReservEntryFromMobWmsRegistration(_MobWmsRegistration, _TempReservEntry, _QtyBase, SignFactor);
    end;

    procedure CreateTempReservEntryForWhseShipmentLine(_WhseShipmentLine: Record "Warehouse Shipment Line"; _MobWmsRegistration: Record "MOB WMS Registration"; var _TempReservEntry: Record "Reservation Entry"; _QtyBase: Decimal)
    var
        ATOSalesLine: Record "Sales Line";
        AsmHeader: Record "Assembly Header";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        SignFactor: Integer;
        ToRowID: Text;
        IsATOPosting: Boolean;
    begin
        // Used for carrying the item tracking from the registration to the Warehouse Shipment line
        if not _MobWmsRegistration.TrackingExists() then
            exit;

        IsATOPosting := (_WhseShipmentLine."Source Type" = Database::"Sales Line") and _WhseShipmentLine."Assemble to Order";

        if IsATOPosting then begin
            ATOSalesLine.Get(_WhseShipmentLine."Source Subtype", _WhseShipmentLine."Source No.", _WhseShipmentLine."Source Line No.");
            ATOSalesLine.AsmToOrderExists(AsmHeader);
            ToRowID :=
                ItemTrackingMgt.ComposeRowID(
                    Database::"Assembly Header", MobToolbox.AsInteger(AsmHeader."Document Type"), AsmHeader."No.", '', 0, 0);
        end else begin
            _WhseShipmentLine.Reset();
            _WhseShipmentLine.SetSourceFilter(_WhseShipmentLine."Source Type", _WhseShipmentLine."Source Subtype", _WhseShipmentLine."Source No.", _WhseShipmentLine."Source Line No.", true);
            ToRowID :=
                ItemTrackingMgt.ComposeRowID(
                    _WhseShipmentLine."Source Type", _WhseShipmentLine."Source Subtype", _WhseShipmentLine."Source No.", '', 0, _WhseShipmentLine."Source Line No.");
        end;

        _TempReservEntry.SetPointer(ToRowID);
        _TempReservEntry.SetItemData(
            _WhseShipmentLine."Item No.",
            _WhseShipmentLine.Description,
            _WhseShipmentLine."Location Code",
            _WhseShipmentLine."Variant Code",
            _WhseShipmentLine."Qty. per Unit of Measure");

        if IsATOPosting then
            SignFactor := 1
        else
            SignFactor := -1;

        InsertTempReservEntryFromMobWmsRegistration(_MobWmsRegistration, _TempReservEntry, _QtyBase, SignFactor);
    end;

    procedure CreateTempReservEntryForAssemblyHeader(_AssemblyHeader: Record "Assembly Header"; _MobWmsRegistration: Record "MOB WMS Registration"; var _TempReservEntry: Record "Reservation Entry"; _QtyBase: Decimal)
    var
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        SignFactor: Integer;
        ToRowID: Text;
    begin
        // Used for carrying the item tracking from the registration to the Assembly Header
        if not _MobWmsRegistration.TrackingExists() then
            exit;

        ToRowID :=
          ItemTrackingMgt.ComposeRowID(
            Database::"Assembly Header", MobToolbox.AsInteger(_AssemblyHeader."Document Type"), _AssemblyHeader."No.", '', 0, 0);

        _TempReservEntry.SetPointer(ToRowID);
        _TempReservEntry.SetItemData(
            _AssemblyHeader."Item No.",
            _AssemblyHeader.Description,
            _AssemblyHeader."Location Code",
            _AssemblyHeader."Variant Code",
            _AssemblyHeader."Qty. per Unit of Measure");

        SignFactor := 1;
        InsertTempReservEntryFromMobWmsRegistration(_MobWmsRegistration, _TempReservEntry, _QtyBase, SignFactor);
    end;

    procedure CreateTempReservEntryForAssemblyLine(_AssemblyLine: Record "Assembly Line"; _MobWmsRegistration: Record "MOB WMS Registration"; var _TempReservEntry: Record "Reservation Entry"; _QtyBase: Decimal)
    var
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        SignFactor: Integer;
        ToRowID: Text;
    begin
        // Used for carrying the item tracking from the registration to the Assembly Line
        if not _MobWmsRegistration.TrackingExists() then
            exit;

        ToRowID :=
          ItemTrackingMgt.ComposeRowID(
            Database::"Assembly Line", MobToolbox.AsInteger(_AssemblyLine."Document Type"), _AssemblyLine."Document No.", '', 0, _AssemblyLine."Line No.");

        _TempReservEntry.SetPointer(ToRowID);
        _TempReservEntry.SetItemData(
            _AssemblyLine."No.",
            _AssemblyLine.Description,
            _AssemblyLine."Location Code",
            _AssemblyLine."Variant Code",
            _AssemblyLine."Qty. per Unit of Measure");

        SignFactor := -1;
        InsertTempReservEntryFromMobWmsRegistration(_MobWmsRegistration, _TempReservEntry, _QtyBase, SignFactor);
    end;

    local procedure InsertTempReservEntryFromMobWmsRegistration(var _MobWmsRegistration: Record "MOB WMS Registration"; var _TempReservEntry: Record "Reservation Entry"; _QtyBase: Decimal; _SignFactor: Integer)
    begin
        _TempReservEntry."Entry No." += 1;
        _TempReservEntry.Positive := _SignFactor > 0;
        _TempReservEntry."Quantity (Base)" := _QtyBase * _SignFactor;
        _TempReservEntry.Quantity := _MobWmsRegistration.Quantity * _SignFactor;
        _TempReservEntry."Qty. to Handle (Base)" := _QtyBase * _SignFactor;
        _TempReservEntry."Qty. to Invoice (Base)" := _QtyBase * _SignFactor;
        CopyTrackingFromMobRegistration(_TempReservEntry, _MobWmsRegistration);
        _TempReservEntry."Expiration Date" := _MobWmsRegistration."Expiration Date";
        _TempReservEntry.Insert();
    end;

    local procedure InsertTempReservEntryFromTrackingSpecWithoutQty(var _TrackingSpec: Record "Tracking Specification"; var _TempReservEntry: Record "Reservation Entry"; _QtyBase: Decimal; _SignFactor: Integer)
    begin
        _TempReservEntry."Entry No." += 1;
        _TempReservEntry.Positive := _SignFactor > 0;
        _TempReservEntry."Quantity (Base)" := _QtyBase * _SignFactor;
        _TempReservEntry.Quantity := _TrackingSpec.CalcQty(_QtyBase) * _SignFactor;
        _TempReservEntry."Qty. to Handle (Base)" := _QtyBase * _SignFactor;
        _TempReservEntry."Qty. to Invoice (Base)" := _QtyBase * _SignFactor;
        _TempReservEntry.CopyTrackingFromSpec(_TrackingSpec);
        _TempReservEntry."Expiration Date" := _TrackingSpec."Expiration Date";

        _TempReservEntry.Insert();
    end;

    /// <summmary>
    /// Replaced by procedures MobTrackingSetup.CopyTrackingFromRegistration() and MobTrackingSetup.CopyTrackingToReservEntry()  (but not planned for removal for backwards compatibility)
    /// </summmary>
    /// <remarks>
    /// Copy Tracking from "MOB WMS Registration" to "Reservation Entry"  (including Expiration Date)
    /// </remarks>
    procedure CopyTrackingFromMobRegistration(var _TempReservEntry: Record "Reservation Entry"; _MobRegistration: Record "MOB WMS Registration")
    var
        MobTrackingSetup: Record "MOB Tracking Setup";
    begin
        MobTrackingSetup.CopyTrackingFromRegistration(_MobRegistration);
        MobTrackingSetup.CopyTrackingToReservEntry(_TempReservEntry);
        _TempReservEntry."Expiration Date" := _MobRegistration."Expiration Date";

        OnAfterCopyTrackingFromMobRegistration(_TempReservEntry, _MobRegistration);
    end;

    /// <summary>
    /// Replaced by procedures MobTrackingSetup.CopyTrackingFromRequestValues() and MobTrackingSetup.CopyTrackingToReservEntry()  (but not planned for removal for backwards compatibility)
    /// </summary>
    /// <remarks>
    /// Copy Tracking from "MOB NS Request Element" to "Reservation Entry"  (including Expiration Date)
    /// </remarks>
    procedure CopyTrackingFromRequestValues(var _TempReservEntry: Record "Reservation Entry"; var _RequestValues: Record "MOB NS Request Element")
    var
        MobTrackingSetup: Record "MOB Tracking Setup";
    begin
        MobTrackingSetup.CopyTrackingFromRequestValues(_RequestValues);
        MobTrackingSetup.CopyTrackingToReservEntry(_TempReservEntry);
        _TempReservEntry."Expiration Date" := _RequestValues.GetValueAsDate('ExpirationDate');

        OnAfterCopyTrackingFromRequestValues(_TempReservEntry, _RequestValues);
    end;

    local procedure SynchronizeItemTrkg(var _TempReservEntry: Record "Reservation Entry"; _ClearQtyToHandle: Boolean)
    var
        TempTrackingSpec: Record "Tracking Specification" temporary;
        ReservEntry: Record "Reservation Entry";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        MobExtItemTrackingMgt: Codeunit "MOB Cod6500 EXT.ItemTrackingMa";
        CommonMgt: Codeunit "MOB Common Mgt.";
        IsTransferReceipt: Boolean;
    begin
        // Eventsubscriber: Include Source ID in filters when processing SumUpItemTracking
        BindSubscription(MobExtItemTrackingMgt);
        ItemTrackingMgt.SumUpItemTracking(_TempReservEntry, TempTrackingSpec, true, true);
        UnbindSubscription(MobExtItemTrackingMgt);

        if _ClearQtyToHandle then
            ClearQtyToHandleOnReservationEntries(TempTrackingSpec);

        if TempTrackingSpec.FindSet() then
            repeat
                CommonMgt.SetSourceFilterForReservEntry(ReservEntry, TempTrackingSpec."Source Type", TempTrackingSpec."Source Subtype", TempTrackingSpec."Source ID", TempTrackingSpec."Source Ref. No.", true);
                CommonMgt.SetSourceFilterForReservEntry(ReservEntry, '', TempTrackingSpec."Source Prod. Order Line");
                ReservEntry.SetTrackingFilterFromSpec(TempTrackingSpec);
                IsTransferReceipt := (TempTrackingSpec."Source Type" = Database::"Transfer Line") and (TempTrackingSpec."Source Subtype" = 1);
                if IsTransferReceipt then
                    ReservEntry.SetRange("Source Ref. No.");
                if ReservEntry.FindSet() then begin
                    repeat
                        if Abs(TempTrackingSpec."Qty. to Handle (Base)") > Abs(ReservEntry."Quantity (Base)") then
                            ReservEntry.Validate("Qty. to Handle (Base)", ReservEntry."Quantity (Base)")
                        else
                            ReservEntry.Validate("Qty. to Handle (Base)", TempTrackingSpec."Qty. to Handle (Base)");

                        if Abs(TempTrackingSpec."Qty. to Invoice (Base)") > Abs(ReservEntry."Quantity (Base)") then
                            ReservEntry.Validate("Qty. to Invoice (Base)", ReservEntry."Quantity (Base)")
                        else
                            ReservEntry.Validate("Qty. to Invoice (Base)", TempTrackingSpec."Qty. to Invoice (Base)");

                        TempTrackingSpec."Qty. to Handle (Base)" -= ReservEntry."Qty. to Handle (Base)";
                        TempTrackingSpec."Qty. to Invoice (Base)" -= ReservEntry."Qty. to Invoice (Base)";
                        // OnSyncActivItemTrkgOnBeforeTempTrackingSpecModify(TempTrackingSpec, ReservEntry);
                        TempTrackingSpec.Modify();

                        ReservEntry."Expiration Date" := TempTrackingSpec."Expiration Date";
                        ReservEntry.Modify();

                        if IsReservedFromTransferShipment(ReservEntry) then
                            UpdateItemTrackingInTransferReceipt(ReservEntry);
                    until ReservEntry.Next() = 0;

                    if (TempTrackingSpec."Qty. to Handle (Base)" = 0) and (TempTrackingSpec."Qty. to Invoice (Base)" = 0) then
                        TempTrackingSpec.Delete();
                end;
            until TempTrackingSpec.Next() = 0;

        if TempTrackingSpec.FindSet() then
            repeat
                // Original standard code
                // TempTrackingSpec."Quantity (Base)" := Abs(TempTrackingSpec."Qty. to Handle (Base)");
                // TempTrackingSpec."Qty. to Handle (Base)" := Abs(TempTrackingSpec."Qty. to Handle (Base)");
                // TempTrackingSpec."Qty. to Invoice (Base)" := Abs(TempTrackingSpec."Qty. to Invoice (Base)");
                //
                // New condition for Production Consumption and Output (allow negative reservation entries when posting negative "correction")
                if IsProductionJournalTrackingSpec(TempTrackingSpec) then begin
                    TempTrackingSpec."Quantity (Base)" := TempTrackingSpec."Qty. to Handle (Base)";
                    TempTrackingSpec."Qty. to Handle (Base)" := TempTrackingSpec."Qty. to Handle (Base)";
                    TempTrackingSpec."Qty. to Invoice (Base)" := TempTrackingSpec."Qty. to Invoice (Base)";
                end else begin
                    TempTrackingSpec."Quantity (Base)" := Abs(TempTrackingSpec."Qty. to Handle (Base)");
                    TempTrackingSpec."Qty. to Handle (Base)" := Abs(TempTrackingSpec."Qty. to Handle (Base)");
                    TempTrackingSpec."Qty. to Invoice (Base)" := Abs(TempTrackingSpec."Qty. to Invoice (Base)");
                end;
                TempTrackingSpec.Modify();
            until TempTrackingSpec.Next() = 0;

        RegisterNewItemTrackingLines(TempTrackingSpec);
    end;

    local procedure IsProductionJournalTrackingSpec(TrackingSpec: Record "Tracking Specification"): Boolean
    var
        ItemJnlLine: Record "Item Journal Line";
    begin
        if not ((TrackingSpec."Source Type" = Database::"Item Journal Line") and
            (MobToolbox.AsInteger(TrackingSpec."Source Subtype") in [MobToolbox.AsInteger(ItemJnlLine."Entry Type"::Consumption), MobToolbox.AsInteger(ItemJnlLine."Entry Type"::Output)]))
        then
            exit(false);

        if ItemJnlLine.Get(TrackingSpec."Source ID", TrackingSpec."Source Batch Name", TrackingSpec."Source Ref. No.") then
            exit(ItemJnlLine.Quantity < 0);
    end;

    local procedure RegisterNewItemTrackingLines(var _TempTrackingSpec: Record "Tracking Specification" temporary)
    var
        TrackingSpec: Record "Tracking Specification";
        ReservEntry: Record "Reservation Entry";
        MobTrackingSetupErr: Record "MOB Tracking Setup";
        ReservMgt: Codeunit "Reservation Management";
        CommonMgt: Codeunit "MOB Common Mgt.";
        ItemTrackingLines: Page "Item Tracking Lines";
        QtyToHandleInItemTracking: Decimal;
        QtyToHandleOnSourceDocLine: Decimal;
        QtyToHandleToNewRegister: Decimal;
    begin
        // OnBeforeRegisterNewItemTrackingLines(TempTrackingSpec);

        if _TempTrackingSpec.FindSet() then
            repeat
                CommonMgt.SetSourceFilterForTrackingSpec(_TempTrackingSpec, _TempTrackingSpec."Source Type", _TempTrackingSpec."Source Subtype", _TempTrackingSpec."Source ID", _TempTrackingSpec."Source Ref. No.", false);
                CommonMgt.SetSourceFilterForTrackingSpec(_TempTrackingSpec, _TempTrackingSpec."Source Batch Name", _TempTrackingSpec."Source Prod. Order Line");   // Standard code did not include any SourceBatchName-filter
                TrackingSpec := _TempTrackingSpec;
                _TempTrackingSpec.CalcSums("Qty. to Handle (Base)");

                QtyToHandleToNewRegister := _TempTrackingSpec."Qty. to Handle (Base)";
                ReservEntry.TransferFields(_TempTrackingSpec);
                QtyToHandleInItemTracking :=
                  Abs(CalcQtyToHandleForTrackedQtyOnDocumentLine(
                      ReservEntry."Source Type", ReservEntry."Source Subtype", ReservEntry."Source ID", ReservEntry."Source Ref. No.", ReservEntry."Source Batch Name", ReservEntry."Source Prod. Order Line"));
                QtyToHandleOnSourceDocLine := ReservMgt.GetSourceRecordValue(ReservEntry, false, 0);

                if QtyToHandleToNewRegister + QtyToHandleInItemTracking > QtyToHandleOnSourceDocLine then begin
                    MobTrackingSetupErr.CopyTrackingFromReservEntry(ReservEntry);
                    Error(CannotMatchItemTrackingErr, MobToolbox.CRLFSeparator() + MobTrackingSetupErr.FormatTracking() + MobToolbox.CRLFSeparator(), ReservEntry."Item No.", ReservEntry."Variant Code");
                end;

                TrackingSpec."Quantity (Base)" :=
                  _TempTrackingSpec."Qty. to Handle (Base)" + Abs(ItemTrkgQtyPostedOnSource(TrackingSpec));

                // OnBeforeRegisterItemTrackingLinesLoop(TrackingSpec, TempTrackingSpec);

                Clear(ItemTrackingLines);
                ItemTrackingLines.SetCalledFromSynchWhseItemTrkg(true);
                ItemTrackingLines.SetBlockCommit(true);
                /* #if BC19+ */
                if (TrackingSpec."Source Type" = Database::"Transfer Line") and (TrackingSpec."Source Subtype" = 1) then // Source Subtype 1 = Inbound Transfer
                    ItemTrackingLines.SetRunMode(Enum::"Item Tracking Run Mode"::Transfer);
                /* #endif */
                /* #if BC18- ##
                if (TrackingSpec."Source Type" = Database::"Transfer Line") and (TrackingSpec."Source Subtype" = 1) then // Source Subtype 1 = Inbound Transfer
                    ItemTrackingLines.SetFormRunMode(4); // 4 = Transfer
                /* #endif */
                ItemTrackingLines.RegisterItemTrackingLines(TrackingSpec, TrackingSpec."Creation Date", _TempTrackingSpec);
                _TempTrackingSpec.ClearSourceFilter();
            until _TempTrackingSpec.Next() = 0;
    end;

    local procedure CalcQtyToHandleForTrackedQtyOnDocumentLine(SourceType: Integer; SourceSubtype: Option; SourceID: Code[20]; SourceRefNo: Integer; SourceBatchName: Code[10]; SourceProdOrderLine: Integer): Decimal
    var
        ReservEntry: Record "Reservation Entry";
        CommonMgt: Codeunit "MOB Common Mgt.";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        // OnBeforeCalcQtyToHandleForTrackedQtyOnDocumentLine(ReservEntry, IsHandled);
        if IsHandled then
            exit;

        CommonMgt.SetSourceFilterForReservEntry(ReservEntry, SourceType, SourceSubtype, SourceID, SourceRefNo, true);
        if (SourceType = Database::"Transfer Line") and (SourceSubtype = 1) then // Source Subtype 1 = Inbound Transfer
            CommonMgt.SetSourceFilterForReservEntry(ReservEntry, SourceBatchName, SourceProdOrderLine)
        else
            CommonMgt.SetSourceFilterForReservEntry(ReservEntry, '', 0);
        ReservEntry.SetFilter("Item Tracking", '<>%1', ReservEntry."Item Tracking"::None);
        ReservEntry.CalcSums("Qty. to Handle (Base)");
        exit(ReservEntry."Qty. to Handle (Base)");
    end;

    local procedure IsReservedFromTransferShipment(ReservEntry: Record "Reservation Entry"): Boolean
    begin
        exit((ReservEntry."Source Type" = Database::"Transfer Line") and (ReservEntry."Source Subtype" = 0));
    end;

    local procedure UpdateItemTrackingInTransferReceipt(_FromReservEntry: Record "Reservation Entry")
    var
        ToReservEntry: Record "Reservation Entry";
        ItemTrkgMgt: Codeunit "Item Tracking Management";
        ToRowID: Text[250];
    begin
        ToRowID := ItemTrkgMgt.ComposeRowID(
            Database::"Transfer Line", 1, _FromReservEntry."Source ID",
            _FromReservEntry."Source Batch Name", _FromReservEntry."Source Prod. Order Line", _FromReservEntry."Source Ref. No.");
        ToReservEntry.SetPointer(ToRowID);
        ToReservEntry.SetPointerFilter();
        SynchronizeItemTrkgTransfer(ToReservEntry);
    end;

    local procedure ItemTrkgQtyPostedOnSource(_SourceTrackingSpec: Record "Tracking Specification") Qty: Decimal
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservEntry: Record "Reservation Entry";
        TransferLine: Record "Transfer Line";
        CommonMgt: Codeunit "MOB Common Mgt.";
    begin
        CommonMgt.SetSourceFilterForTrackingSpec(TrackingSpecification, _SourceTrackingSpec."Source Type", _SourceTrackingSpec."Source Subtype", _SourceTrackingSpec."Source ID", _SourceTrackingSpec."Source Ref. No.", true);
        CommonMgt.SetSourceFilterForTrackingSpec(TrackingSpecification, _SourceTrackingSpec."Source Batch Name", _SourceTrackingSpec."Source Prod. Order Line");
        if not TrackingSpecification.IsEmpty() then begin
            TrackingSpecification.FindSet();
            repeat
                Qty += TrackingSpecification."Quantity (Base)";
            until TrackingSpecification.Next() = 0;
        end;

        CommonMgt.SetSourceFilterForReservEntry(ReservEntry, _SourceTrackingSpec."Source Type", _SourceTrackingSpec."Source Subtype", _SourceTrackingSpec."Source ID", _SourceTrackingSpec."Source Ref. No.", false);
        CommonMgt.SetSourceFilterForReservEntry(ReservEntry, '', _SourceTrackingSpec."Source Prod. Order Line");
        if not ReservEntry.IsEmpty() then begin
            ReservEntry.FindSet();
            repeat
                Qty += ReservEntry."Qty. to Handle (Base)";
            until ReservEntry.Next() = 0;
        end;
        if _SourceTrackingSpec."Source Type" = Database::"Transfer Line" then begin
            TransferLine.Get(_SourceTrackingSpec."Source ID", _SourceTrackingSpec."Source Ref. No.");
            Qty -= TransferLine."Qty. Shipped (Base)";
        end;
    end;

    local procedure SynchronizeItemTrkgTransfer(var _ReservEntry: Record "Reservation Entry")
    var
        FromReservEntry: Record "Reservation Entry";
        ToReservEntry: Record "Reservation Entry";
        TempToReservEntry: Record "Reservation Entry" temporary;
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        MobExtItemTrackingMgt: Codeunit "MOB Cod6500 EXT.ItemTrackingMa";
    begin
        FromReservEntry.Copy(_ReservEntry);
        FromReservEntry.SetRange("Source Subtype", 0);

        ToReservEntry.Copy(_ReservEntry);
        ToReservEntry.SetRange("Source Subtype", 1);
        if ToReservEntry.FindSet() then
            repeat
                TempToReservEntry := ToReservEntry;
                TempToReservEntry."Qty. to Handle (Base)" := 0;
                TempToReservEntry."Qty. to Invoice (Base)" := 0;
                TempToReservEntry.Insert();
            until ToReservEntry.Next() = 0;
        if TempToReservEntry.IsEmpty() then
            exit;

        // Eventsubscriber: Include Source ID in filters when processing SumUpItemTracking
        BindSubscription(MobExtItemTrackingMgt);
        ItemTrackingMgt.SumUpItemTracking(FromReservEntry, TempTrackingSpecification, true, true);
        UnbindSubscription(MobExtItemTrackingMgt);

        TempTrackingSpecification.Reset();
        TempTrackingSpecification.SetFilter("Qty. to Handle (Base)", '<%1', 0);
        if TempTrackingSpecification.FindSet() then
            repeat
                ToReservEntry.SetTrackingFilterFromSpec(TempTrackingSpecification);
                ToReservEntry.ModifyAll("Qty. to Handle (Base)", 0);
                ToReservEntry.ModifyAll("Qty. to Invoice (Base)", 0);

                TempTrackingSpecification."Qty. to Handle (Base)" *= -1;

                TempToReservEntry.SetCurrentKey(
                  "Item No.", "Variant Code", "Location Code", "Item Tracking", "Reservation Status", "Lot No.", "Serial No.");
                TempToReservEntry.SetTrackingFilterFromSpec(TempTrackingSpecification);
                if TempToReservEntry.FindSet() then
                    repeat
                        if TempToReservEntry."Quantity (Base)" < TempTrackingSpecification."Qty. to Handle (Base)" then begin
                            TempToReservEntry."Qty. to Handle (Base)" := TempToReservEntry."Quantity (Base)";
                            TempTrackingSpecification."Qty. to Handle (Base)" -= TempToReservEntry."Quantity (Base)";
                            TempToReservEntry."Qty. to Invoice (Base)" := TempToReservEntry."Quantity (Base)";
                        end else begin
                            TempToReservEntry."Qty. to Handle (Base)" := TempTrackingSpecification."Qty. to Handle (Base)";
                            TempTrackingSpecification."Qty. to Handle (Base)" := 0;
                            TempToReservEntry."Qty. to Invoice (Base)" := TempTrackingSpecification."Qty. to Handle (Base)";
                        end;

                        ToReservEntry.Get(TempToReservEntry."Entry No.", TempToReservEntry.Positive);
                        ToReservEntry."Qty. to Handle (Base)" := TempToReservEntry."Qty. to Handle (Base)";
                        ToReservEntry."Qty. to Invoice (Base)" := TempToReservEntry."Qty. to Handle (Base)";
                        ToReservEntry.Modify();
                    until (TempToReservEntry.Next() = 0) or (TempTrackingSpecification."Qty. to Handle (Base)" = 0);
                _ReservEntry.Get(ToReservEntry."Entry No.", ToReservEntry.Positive);

            until TempTrackingSpecification.Next() = 0;
    end;

    local procedure WhseActivitySignFactor(_WhseActivityLine: Record "Warehouse Activity Line"): Integer
    begin
        case _WhseActivityLine."Activity Type" of
            _WhseActivityLine."Activity Type"::"Invt. Pick":
                if _WhseActivityLine."Assemble to Order" then
                    exit(1)
                else
                    exit(-1);
            _WhseActivityLine."Activity Type"::Pick:
                exit(-1);
            _WhseActivityLine."Activity Type"::"Put-away",
            _WhseActivityLine."Activity Type"::"Invt. Put-away":
                exit(1);
        end;

        Error(ActivityTypeMustNotBeErr, _WhseActivityLine.FieldCaption("Activity Type"), _WhseActivityLine."Activity Type");
    end;

    procedure SetSuppressClearQtyToHandle(_NewSuppressClearQtyToHandle: Boolean)
    begin
        SuppressClearQtyToHandle := _NewSuppressClearQtyToHandle;
    end;

    local procedure ClearQtyToHandleOnReservationEntries(var _TempTrackingSpec: Record "Tracking Specification")
    var
        ReservEntry: Record "Reservation Entry";
        CommonMgt: Codeunit "MOB Common Mgt.";
        IsTransferReceipt: Boolean;
    begin
        if _TempTrackingSpec.FindSet() then
            repeat
                ReservEntry.Reset();
                CommonMgt.SetSourceFilterForReservEntry(ReservEntry, _TempTrackingSpec."Source Type", _TempTrackingSpec."Source Subtype", _TempTrackingSpec."Source ID", _TempTrackingSpec."Source Ref. No.", true);
                CommonMgt.SetSourceFilterForReservEntry(ReservEntry, '', _TempTrackingSpec."Source Prod. Order Line");
                IsTransferReceipt := (_TempTrackingSpec."Source Type" = Database::"Transfer Line") and (_TempTrackingSpec."Source Subtype" = 1);
                if IsTransferReceipt then
                    ReservEntry.SetRange("Source Ref. No.");
                if not ReservEntry.IsEmpty() then
                    ReservEntry.ModifyAll("Qty. to Handle (Base)", 0, true);
            until _TempTrackingSpec.Next() = 0;
    end;

    procedure SaveOriginalReservationEntriesForItemJnlLines(var _ItemJnlLine: Record "Item Journal Line"; var _TmpReservationEntryLog: Record "Reservation Entry")
    begin
        if _ItemJnlLine.FindSet() then
            repeat
                SaveOriginalReservationEntries(
                    Database::"Item Journal Line",                   // Source Type
                    MobToolbox.AsInteger(_ItemJnlLine."Entry Type"), // Source Subtype
                    _ItemJnlLine."Journal Template Name",            // Source ID
                    _ItemJnlLine."Line No.",                         // Source Ref. No.
                    _ItemJnlLine."Journal Batch Name",               // Source Batch Name
                    0,                                               // SourceProdOrderLine (is blank for Source Type 83 even for consumption/output)
                    _TmpReservationEntryLog);
            until _ItemJnlLine.Next() = 0;
    end;

    procedure RevertToOriginalReservationEntriesForItemJnlLines(var _ItemJnlLine: Record "Item Journal Line"; var _TmpReservationEntryLog: Record "Reservation Entry")
    begin
        if _ItemJnlLine.FindSet() then
            repeat
                RevertToOriginalReservationEntries(
                    Database::"Item Journal Line",                   // Source Type
                    MobToolbox.AsInteger(_ItemJnlLine."Entry Type"), // Source Subtype
                    _ItemJnlLine."Journal Template Name",            // Source ID
                    _ItemJnlLine."Line No.",                         // Source Ref. No.
                    _ItemJnlLine."Journal Batch Name",               // Source Batch Name
                    0,                                               // SourceProdOrderLine (is blank for Source Type 83 even for consumption/output)
                    _TmpReservationEntryLog);
            until _ItemJnlLine.Next() = 0;
    end;

    procedure SaveOriginalReservationEntriesForPurchLines(var _PurchaseLine: Record "Purchase Line"; var _TmpReservationEntryLog: Record "Reservation Entry")
    begin
        if _PurchaseLine.FindSet() then
            repeat
                SaveOriginalReservationEntries(
                    Database::"Purchase Line",
                    MobToolbox.AsInteger(_PurchaseLine."Document Type"),
                    _PurchaseLine."Document No.",
                    _PurchaseLine."Line No.", '', 0, _TmpReservationEntryLog);
            until _PurchaseLine.Next() = 0;
    end;

    procedure RevertToOriginalReservationEntriesForPurchLines(var _PurchaseLine: Record "Purchase Line"; var _TmpReservationEntryLog: Record "Reservation Entry")
    begin
        if _PurchaseLine.FindSet() then
            repeat
                RevertToOriginalReservationEntries(
                    Database::"Purchase Line",
                    MobToolbox.AsInteger(_PurchaseLine."Document Type"),
                    _PurchaseLine."Document No.",
                    _PurchaseLine."Line No.", '', 0, _TmpReservationEntryLog);
            until _PurchaseLine.Next() = 0;
    end;

    procedure SaveOriginalReservationEntriesForSalesLines(var _SalesLine: Record "Sales Line"; var _TmpReservationEntryLog: Record "Reservation Entry")
    begin
        if _SalesLine.FindSet() then
            repeat
                SaveOriginalReservationEntries(
                    Database::"Sales Line",
                    MobToolbox.AsInteger(_SalesLine."Document Type"),
                    _SalesLine."Document No.",
                    _SalesLine."Line No.", '', 0, _TmpReservationEntryLog);
            until _SalesLine.Next() = 0;
    end;

    procedure RevertToOriginalReservationEntriesForSalesLines(var _SalesLine: Record "Sales Line"; var _TmpReservationEntryLog: Record "Reservation Entry")
    begin
        if _SalesLine.FindSet() then
            repeat
                RevertToOriginalReservationEntries(
                    Database::"Sales Line",
                    MobToolbox.AsInteger(_SalesLine."Document Type"),
                    _SalesLine."Document No.",
                    _SalesLine."Line No.", '', 0, _TmpReservationEntryLog);
            until _SalesLine.Next() = 0;
    end;

    procedure SaveOriginalReservationEntriesForTransferLines(var _TransferLine: Record "Transfer Line"; _Inbound: Boolean; var _TmpReservationEntryLog: Record "Reservation Entry")
    begin
        if _TransferLine.FindSet() then
            repeat
                if _Inbound then
                    SaveOriginalReservationEntries(Database::"Transfer Line", 1, _TransferLine."Document No.", 0, '', _TransferLine."Line No.", _TmpReservationEntryLog)
                else
                    SaveOriginalReservationEntries(Database::"Transfer Line", 0, _TransferLine."Document No.", _TransferLine."Line No.", '', 0, _TmpReservationEntryLog);
            until _TransferLine.Next() = 0;
    end;

    procedure RevertToOriginalReservationEntriesForTransferLines(var _TransferLine: Record "Transfer Line"; _Inbound: Boolean; var _TmpReservationEntryLog: Record "Reservation Entry")
    begin
        if _TransferLine.FindSet() then
            repeat
                if _Inbound then
                    RevertToOriginalReservationEntries(Database::"Transfer Line", 1, _TransferLine."Document No.", 0, '', _TransferLine."Line No.", _TmpReservationEntryLog)
                else
                    RevertToOriginalReservationEntries(Database::"Transfer Line", 0, _TransferLine."Document No.", _TransferLine."Line No.", '', 0, _TmpReservationEntryLog);
            until _TransferLine.Next() = 0;
    end;

    procedure SaveOriginalReservationEntriesForWhseActivityLines(var _WhseActivityLine: Record "Warehouse Activity Line"; var _TmpReservationEntryLog: Record "Reservation Entry")
    var
        SourceRefNo: Integer;
        SourceProdOrderLine: Integer;
        IsTransferReceipt: Boolean;
    begin
        if _WhseActivityLine.FindSet() then
            repeat

                IsTransferReceipt := (_WhseActivityLine."Source Type" = Database::"Transfer Line") and (_WhseActivityLine."Source Subtype" = 1);

                if (_WhseActivityLine."Source Type" in [Database::"Prod. Order Line", Database::"Prod. Order Component"]) or IsTransferReceipt then begin
                    SourceRefNo := _WhseActivityLine."Source Subline No.";
                    SourceProdOrderLine := _WhseActivityLine."Source Line No.";
                end else begin
                    SourceRefNo := _WhseActivityLine."Source Line No.";
                    SourceProdOrderLine := _WhseActivityLine."Source Subline No.";
                end;

                SaveOriginalReservationEntries(
                        _WhseActivityLine."Source Type",
                        _WhseActivityLine."Source Subtype",
                        _WhseActivityLine."Source No.",
                        SourceRefNo, '', SourceProdOrderLine, _TmpReservationEntryLog);

            until _WhseActivityLine.Next() = 0;
    end;

    procedure RevertToOriginalReservationEntriesForWhseActivityLines(var _WhseActivityLine: Record "Warehouse Activity Line"; var _TmpReservationEntryLog: Record "Reservation Entry")
    var
        SourceRefNo: Integer;
        SourceProdOrderLine: Integer;
        IsTransferReceipt: Boolean;
    begin
        if _WhseActivityLine.FindSet() then
            repeat

                IsTransferReceipt := (_WhseActivityLine."Source Type" = Database::"Transfer Line") and (_WhseActivityLine."Source Subtype" = 1);

                if (_WhseActivityLine."Source Type" in [Database::"Prod. Order Line", Database::"Prod. Order Component"]) or IsTransferReceipt then begin
                    SourceRefNo := _WhseActivityLine."Source Subline No.";
                    SourceProdOrderLine := _WhseActivityLine."Source Line No.";
                end else begin
                    SourceRefNo := _WhseActivityLine."Source Line No.";
                    SourceProdOrderLine := _WhseActivityLine."Source Subline No.";
                end;

                RevertToOriginalReservationEntries(
                    _WhseActivityLine."Source Type",
                    _WhseActivityLine."Source Subtype",
                    _WhseActivityLine."Source No.",
                    SourceRefNo, '', SourceProdOrderLine, _TmpReservationEntryLog);

            until _WhseActivityLine.Next() = 0;
    end;

    procedure SaveOriginalReservationEntriesForWhseReceiptLines(var _WhseReceiptLine: Record "Warehouse Receipt Line"; var _TmpReservationEntryLog: Record "Reservation Entry")
    begin
        if _WhseReceiptLine.FindSet() then
            repeat
                SaveOriginalReservationEntries(
                    _WhseReceiptLine."Source Type",
                    _WhseReceiptLine."Source Subtype",
                    _WhseReceiptLine."Source No.",
                    _WhseReceiptLine."Source Line No.", '', 0, _TmpReservationEntryLog);
            until _WhseReceiptLine.Next() = 0;
    end;

    procedure RevertToOriginalReservationEntriesForWhseReceiptLines(var _WhseReceiptLine: Record "Warehouse Receipt Line"; var _TmpReservationEntryLog: Record "Reservation Entry")
    begin
        if _WhseReceiptLine.FindSet() then
            repeat
                RevertToOriginalReservationEntries(
                    _WhseReceiptLine."Source Type",
                    _WhseReceiptLine."Source Subtype",
                    _WhseReceiptLine."Source No.",
                    _WhseReceiptLine."Source Line No.", '', 0, _TmpReservationEntryLog);
            until _WhseReceiptLine.Next() = 0;
    end;

    procedure SaveOriginalReservationEntriesForWhseShipmentLines(var _WhseShipmentLine: Record "Warehouse Shipment Line"; var _TmpReservationEntryLog: Record "Reservation Entry")
    var
        ATOSalesLine: Record "Sales Line";
        AssemblyHeader: Record "Assembly Header";
    begin
        if _WhseShipmentLine.FindSet() then
            repeat
                if (_WhseShipmentLine."Source Type" = Database::"Sales Line") and _WhseShipmentLine."Assemble to Order" then begin
                    ATOSalesLine.Get(_WhseShipmentLine."Source Subtype", _WhseShipmentLine."Source No.", _WhseShipmentLine."Source Line No.");
                    ATOSalesLine.AsmToOrderExists(AssemblyHeader);
                    SaveOriginalReservationEntries(
                        Database::"Assembly Header",
                        MobToolbox.AsInteger(AssemblyHeader."Document Type"),
                        AssemblyHeader."No.",
                        0, '', 0, _TmpReservationEntryLog);
                end else
                    SaveOriginalReservationEntries(
                        _WhseShipmentLine."Source Type",
                        _WhseShipmentLine."Source Subtype",
                        _WhseShipmentLine."Source No.",
                        _WhseShipmentLine."Source Line No.", '', 0, _TmpReservationEntryLog);
            until _WhseShipmentLine.Next() = 0;
    end;

    procedure RevertToOriginalReservationEntriesForWhseShipmentLines(var _WhseShipmentLine: Record "Warehouse Shipment Line"; var _TmpReservationEntryLog: Record "Reservation Entry")
    var
        ATOSalesLine: Record "Sales Line";
        AssemblyHeader: Record "Assembly Header";
    begin
        if _WhseShipmentLine.FindSet() then
            repeat
                if (_WhseShipmentLine."Source Type" = Database::"Sales Line") and _WhseShipmentLine."Assemble to Order" then begin
                    ATOSalesLine.Get(_WhseShipmentLine."Source Subtype", _WhseShipmentLine."Source No.", _WhseShipmentLine."Source Line No.");
                    ATOSalesLine.AsmToOrderExists(AssemblyHeader);
                    RevertToOriginalReservationEntries(
                        Database::"Assembly Header",
                        MobToolbox.AsInteger(AssemblyHeader."Document Type"),
                        AssemblyHeader."No.",
                        0, '', 0, _TmpReservationEntryLog);
                end else
                    RevertToOriginalReservationEntries(
                        _WhseShipmentLine."Source Type",
                        _WhseShipmentLine."Source Subtype",
                        _WhseShipmentLine."Source No.",
                        _WhseShipmentLine."Source Line No.", '', 0, _TmpReservationEntryLog);
            until _WhseShipmentLine.Next() = 0;
    end;

    procedure SaveOriginalReservationEntriesForAssemblyHeader(var _AssemblyHeader: Record "Assembly Header"; var _TmpReservationEntryLog: Record "Reservation Entry")
    begin

        SaveOriginalReservationEntries(
            Database::"Assembly Header",
            MobToolbox.AsInteger(_AssemblyHeader."Document Type"),
            _AssemblyHeader."No.",
            0, '', 0, _TmpReservationEntryLog);
    end;

    procedure RevertToOriginalReservationEntriesForAssemblyHeader(var _AssemblyHeader: Record "Assembly Header"; var _TmpReservationEntryLog: Record "Reservation Entry")
    begin
        RevertToOriginalReservationEntries(
            Database::"Assembly Header",
            MobToolbox.AsInteger(_AssemblyHeader."Document Type"),
            _AssemblyHeader."No.",
            0, '', 0, _TmpReservationEntryLog);
    end;

    procedure SaveOriginalReservationEntriesForAssemblyLines(var _AssemblyLine: Record "Assembly Line"; var _TmpReservationEntryLog: Record "Reservation Entry")
    begin
        if _AssemblyLine.FindSet() then
            repeat
                SaveOriginalReservationEntries(
                    Database::"Assembly Line",
                    MobToolbox.AsInteger(_AssemblyLine."Document Type"),
                    _AssemblyLine."Document No.",
                    _AssemblyLine."Line No.", '', 0, _TmpReservationEntryLog);
            until _AssemblyLine.Next() = 0;
    end;

    procedure RevertToOriginalReservationEntriesForAssemblyLines(var _AssemblyLine: Record "Assembly Line"; var _TmpReservationEntryLog: Record "Reservation Entry")
    begin
        if _AssemblyLine.FindSet() then
            repeat
                RevertToOriginalReservationEntries(
                    Database::"Assembly Line",
                    MobToolbox.AsInteger(_AssemblyLine."Document Type"),
                    _AssemblyLine."Document No.",
                    _AssemblyLine."Line No.", '', 0, _TmpReservationEntryLog);
            until _AssemblyLine.Next() = 0;
    end;

    procedure SaveOriginalReservationEntries(_SourceType: Integer; _SourceSubtype: Integer; _SourceID: Code[20]; _SourceRefNo: Integer; _SourceBatchName: Code[10]; _SourceProdOrderLine: Integer; var _TmpReservationEntryLog: Record "Reservation Entry")
    var
        ReservationEntry: Record "Reservation Entry";
        PairedReservationEntry: Record "Reservation Entry";
        CommonMgt: Codeunit "MOB Common Mgt.";
        IsTransferReceipt: Boolean;
    begin
        IsTransferReceipt := (_SourceType = Database::"Transfer Line") and (_SourceSubtype = 1);
        if IsTransferReceipt then begin
            CommonMgt.SetSourceFilterForReservEntry(ReservationEntry, _SourceType, _SourceSubtype, _SourceID, -1, true); // -1 to prohibit filtering "Source Ref. No."
            CommonMgt.SetSourceFilterForReservEntry(ReservationEntry, '', _SourceRefNo);
        end else
            ReservationEntry.SetSourceFilter(_SourceType, _SourceSubtype, _SourceID, _SourceRefNo, true);
        if ReservationEntry.FindSet() then
            repeat
                _TmpReservationEntryLog.Copy(ReservationEntry);
                if _TmpReservationEntryLog.Insert() then; // Deliberately suppress Insert Error

                // Check if there is a paired reservation entry that also needs to be saved
                if PairedReservationEntry.Get(ReservationEntry."Entry No.", not ReservationEntry.Positive) then begin
                    _TmpReservationEntryLog.Copy(PairedReservationEntry);
                    if _TmpReservationEntryLog.Insert() then; // Deliberately suppress Insert Error
                end;
            until ReservationEntry.Next() = 0;
    end;

    procedure RevertToOriginalReservationEntries(_SourceType: Integer; _SourceSubtype: Integer; _SourceID: Code[20]; _SourceRefNo: Integer; _SourceBatchName: Code[10]; _SourceProdOrderLine: Integer; var _TmpReservationEntryLog: Record "Reservation Entry" temporary)
    var
        ReservationEntry: Record "Reservation Entry";
        PairedReservationEntry: Record "Reservation Entry";
        CommonMgt: Codeunit "MOB Common Mgt.";
        IsTransferReceipt: Boolean;
    begin
        IsTransferReceipt := (_SourceType = Database::"Transfer Line") and (_SourceSubtype = 1);
        if IsTransferReceipt then begin
            CommonMgt.SetSourceFilterForReservEntry(ReservationEntry, _SourceType, _SourceSubtype, _SourceID, -1, true); // -1 to prohibit filtering "Source Ref. No."
            CommonMgt.SetSourceFilterForReservEntry(ReservationEntry, '', _SourceRefNo);
        end else
            ReservationEntry.SetSourceFilter(_SourceType, _SourceSubtype, _SourceID, _SourceRefNo, true);

        // Find and delete all reservation entries for the source line, including paired reservations
        if ReservationEntry.FindSet() then
            repeat
                ReservationEntry.Delete();
                if PairedReservationEntry.Get(ReservationEntry."Entry No.", not ReservationEntry.Positive) then
                    PairedReservationEntry.Delete();
            until ReservationEntry.Next() = 0;

        // Restore reservations for the source lines
        _TmpReservationEntryLog.CopyFilters(ReservationEntry);
        if _TmpReservationEntryLog.FindFirst() then
            repeat
                ReservationEntry.Copy(_TmpReservationEntryLog);
                ReservationEntry.Insert();
            until _TmpReservationEntryLog.Next() = 0;

        // Restore paired reservation entries
        _TmpReservationEntryLog.Reset();
        if ReservationEntry.FindSet() then
            repeat
                if _TmpReservationEntryLog.Get(ReservationEntry."Entry No.", not ReservationEntry.Positive) then begin
                    PairedReservationEntry.Copy(_TmpReservationEntryLog);
                    PairedReservationEntry.Insert();
                end;
            until ReservationEntry.Next() = 0;
    end;

    /// <summmary>
    /// Replaced by events MobTrackingSetup.OnAfterCopyTrackingFromReservation and MobTrackingSetup.OnAfterCopyTrackingToReservEntry  (but not planned for removal for backwards compatibility)
    /// </summmary>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromMobRegistration(var _TempReservEntry: Record "Reservation Entry"; _MobRegistration: Record "MOB WMS Registration")
    begin
    end;

    /// <summmary>
    /// Replaced by events MobTrackingSetup.OnAfterCopyTrackingFromRequestValues and MobTrackingSetup.OnAfterCopyTrackingToReservEntry  (but not planned for removal for backwards compatibility)
    /// </summmary>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromRequestValues(var _TempReservEntry: Record "Reservation Entry"; var _RequestValues: Record "MOB NS Request Element")
    begin
    end;
}
