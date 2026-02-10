codeunit 81402 "MOB Production Journal Mgt"
{
    Access = Public;
    var
#pragma warning disable AA0137
        DefaultBatchNameTxt: Label 'DEFAULT'; // Only used by BC16- but always needs to be declared to get in the XLF files
#pragma warning restore AA0137

    /// <summary>
    /// Create and reset Production Journal for the Prod. Order Line (Consumtion and Output)
    /// </summary>
    procedure CreateAndResetJnlLines(ProdOrder: Record "Production Order"; _ProdOrderLine: Record "Prod. Order Line"; var _ReturnToTemplateName: Code[10]; var _ReturnToBatchName: Code[10])
    var
        ProductionJnlMgt: Codeunit "Production Journal Mgt";
        ToTemplateName: Code[10];
        ToBatchName: Code[10];
    begin
        // Create consumption jnl. and but reset all lines to zero
        Clear(ProductionJnlMgt);
        ProductionJnlMgt.SetTemplateAndBatchName();    // MAY COMMIT
        GetJnlTemplateAndBatchName(ProductionJnlMgt, ToTemplateName, ToBatchName);
        ProductionJnlMgt.InitSetupValues();
        ProductionJnlMgt.DeleteJnlLines(ToTemplateName, ToBatchName, _ProdOrderLine."Prod. Order No.", _ProdOrderLine."Line No.");
        ProductionJnlMgt.CreateJnlLines(ProdOrder, _ProdOrderLine."Line No.");
        ResetJnlLines(ToTemplateName, ToBatchName, _ProdOrderLine."Prod. Order No.", _ProdOrderLine."Line No.");

        _ReturnToTemplateName := ToTemplateName;
        _ReturnToBatchName := ToBatchName;
    end;

    local procedure GetJnlTemplateAndBatchName(var _ProductionJnlMgt: Codeunit "Production Journal Mgt"; var _ToTemplateName: Code[10]; var _ToBatchName: Code[10])
    begin
        /* #if BC17+ */
        _ProductionJnlMgt.GetJnlTemplateAndBatchName(_ToTemplateName, _ToBatchName);
        /* #endif */
        /* #if BC16- ##
        GetTemplateAndBatchName(_ToTemplateName, _ToBatchName);    // redundant code due to inaccessibility
        /* #endif */
    end;

    /* #if BC16- ##
    /// <summary>
    /// Redundant code based on "Production Journal Mgt.".SetTemplateAndBatchName() since internal variables for the ToTemplateName/ToBatchName cannot be read externally from the mgt. codeunit before BC17
    /// </summary>
    local procedure GetTemplateAndBatchName(var _ToTemplateName: Code[10]; var _ToBatchName: Code[10])
    var
        ItemJnlTemplate: Record "Item Journal Template";
        ItemJnlBatch: Record "Item Journal Batch";
        ItemJnlLine: Record "Item Journal Line";
        User: Text;
    begin
        ItemJnlTemplate.Reset();
        ItemJnlTemplate.SetRange("Page ID", PAGE::"Production Journal");
        ItemJnlTemplate.SetRange(Recurring, false);
        ItemJnlTemplate.SetRange(Type, ItemJnlTemplate.Type::"Prod. Order");
        ItemJnlTemplate.FindFirst();
        _ToTemplateName := ItemJnlTemplate.Name;

        _ToBatchName := '';
        User := UpperCase(UserId); // Uppercase in case of Windows Login

        //ProductionJnlMgt.OnAfterSetTemplateAndBatchName(ItemJnlTemplate, User);   // -- inaccessible, if this event is used in other vertical we may find and return an invalid batch name

        if User <> '' then
            if (StrLen(User) < MaxStrLen(ItemJnlLine."Journal Batch Name")) and (ItemJnlLine."Journal Batch Name" <> '') then
                _ToBatchName := CopyStr(ItemJnlLine."Journal Batch Name", 1, MaxStrLen(ItemJnlLine."Journal Batch Name") - 1) + 'A'
            else
                _ToBatchName := DelChr(CopyStr(User, 1, MaxStrLen(ItemJnlLine."Journal Batch Name")), '>', '0123456789');

        if _ToBatchName = '' then
            _ToBatchName := DefaultBatchNameTxt;

        ItemJnlBatch.Get(_ToTemplateName, _ToBatchName);
    end;
    /* #endif */

    /// <summary>
    /// Delete all tracking and reset quantities in ConsumptionJnl (Item Jnl. Lines)
    /// </summary>
    local procedure ResetJnlLines(TemplateName: Code[10]; BatchName: Code[10]; ProdOrderNo: Code[20]; ProdOrderLineNo: Integer)
    var
        ItemJnlLine2: Record "Item Journal Line";
        ReservEntry: Record "Reservation Entry";
        MobCommonMgt: Codeunit "MOB Common Mgt.";
        MobToolbox: Codeunit "MOB Toolbox";
    begin
        ItemJnlLine2.Reset();
        ItemJnlLine2.SetRange("Journal Template Name", TemplateName);
        ItemJnlLine2.SetRange("Journal Batch Name", BatchName);
        ItemJnlLine2.SetRange("Order Type", ItemJnlLine2."Order Type"::Production);
        ItemJnlLine2.SetRange("Order No.", ProdOrderNo);
        if ProdOrderLineNo <> 0 then
            ItemJnlLine2.SetRange("Order Line No.", ProdOrderLineNo);
        if ItemJnlLine2.FindSet() then
            repeat
                ReservEntry.Reset();
                ReservEntry.SetCurrentKey("Source ID", "Source Ref. No.", "Source Type", "Source Subtype", "Source Batch Name", "Source Prod. Order Line");
                MobCommonMgt.SetSourceFilterForReservEntry(ReservEntry, Database::"Item Journal Line", MobToolbox.AsInteger(ItemJnlLine2."Entry Type"), ItemJnlLine2."Journal Template Name", ItemJnlLine2."Line No.", true);
                MobCommonMgt.SetSourceFilterForReservEntry(ReservEntry, ItemJnlLine2."Journal Batch Name", 0);
                ReservEntry.ModifyAll("Quantity (Base)", 0, true);
                ReservEntry.ModifyAll("Qty. to Handle (Base)", 0, true);

                if ItemJnlLine2.Quantity <> 0 then begin
                    ItemJnlLine2.Quantity := 0; // Prevent error in WhseValidateSourceLine.ItemLineVerifyChange
                    ItemJnlLine2.Validate(Quantity, 0);
                end;
                if ItemJnlLine2."Output Quantity" <> 0 then
                    ItemJnlLine2.Validate("Output Quantity", 0);
                if ItemJnlLine2."Scrap Quantity" <> 0 then
                    ItemJnlLine2.Validate("Scrap Quantity", 0);
                if ItemJnlLine2."Setup Time" <> 0 then
                    ItemJnlLine2.Validate("Setup Time", 0);
                if ItemJnlLine2."Run Time" <> 0 then
                    ItemJnlLine2.Validate("Run Time", 0);
                if ItemJnlLine2."Stop Time" <> 0 then
                    ItemJnlLine2.Validate("Stop Time", 0);

                ItemJnlLine2.Modify(true);
            until ItemJnlLine2.Next() = 0;
    end;

    /// <summary>
    /// Delete Production Jnl Lines (consumption+output) and Reservation Entries that has no registrations applied. To be used only after registrations are handled
    /// </summary>
    procedure DeleteJnlLinesWithNoRegistrations(TemplateName: Code[10]; BatchName: Code[10]; ProdOrderNo: Code[20]; ProdOrderLineNo: Integer)
    var
        ItemJnlLine2: Record "Item Journal Line";
        ReservEntry: Record "Reservation Entry";
        ProdJnlMgt: Codeunit "Production Journal Mgt";
    begin
        ItemJnlLine2.Reset();
        ItemJnlLine2.SetRange("Journal Template Name", TemplateName);
        ItemJnlLine2.SetRange("Journal Batch Name", BatchName);
        ItemJnlLine2.SetRange("Order Type", ItemJnlLine2."Order Type"::Production);
        ItemJnlLine2.SetRange("Order No.", ProdOrderNo);
        if ProdOrderLineNo <> 0 then
            ItemJnlLine2.SetRange("Order Line No.", ProdOrderLineNo);
        if ItemJnlLine2.FindSet() then
            repeat
                if (ItemJnlLine2.Quantity = 0) and (ItemJnlLine2."Output Quantity" = 0) and (ItemJnlLine2."Scrap Quantity" = 0) and (ItemJnlLine2."Setup Time" = 0) and (ItemJnlLine2."Run Time" = 0) then begin
                    // ReservEntryExists filters ReservEntry to the ItemJnlLine2 Source Fields
                    if ProdJnlMgt.ReservEntryExist(ItemJnlLine2, ReservEntry) then
                        ReservEntry.DeleteAll(true);
                    ItemJnlLine2.Delete(true);
                end else
                    DeleteReservEntriesWithNoRegistrations(ItemJnlLine2);
            until ItemJnlLine2.Next() = 0;

    end;

    /// <summary>
    /// Delete Reservation Entries (consumption+output) that had no registrations applied.
    /// </summary>
    local procedure DeleteReservEntriesWithNoRegistrations(var _ItemJnlLine: Record "Item Journal Line")
    var
        ReservEntry: Record "Reservation Entry";
        ProdJnlMgt: Codeunit "Production Journal Mgt";
    begin
        // ReservEntryExists filters ReservEntry to the ItemJnlLine2 Source Fields
        if ProdJnlMgt.ReservEntryExist(_ItemJnlLine, ReservEntry) then begin
            ReservEntry.SetRange("Qty. to Handle (Base)", 0);
            ReservEntry.DeleteAll(true);
        end;
    end;

}
