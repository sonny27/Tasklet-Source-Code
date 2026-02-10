codeunit 81411 "MOB WMS History"
{
    Access = Public;
    var
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        MobToolbox: Codeunit "MOB Toolbox";

    /// <summary>
    /// Lookup History - Gets the last 10, 25, 50 or 100 entries from Whse Entries or Item Ledger Entry.
    /// </summary>
    internal procedure LookupHistory(var _RequestValues: Record "MOB NS Request Element"; var _LookupResponse: Record "MOB NS WhseInquery Element"; var _ReturnRegistrationTypeTracking: Text)
    var
        Location: Record Location;
        WhseEntry: Record "Warehouse Entry";
        ItemLedgerEntry: Record "Item Ledger Entry";
        MobItemReferenceMgt: Codeunit "MOB Item Reference Mgt.";
        MobSessionData: Codeunit "MOB SessionData";
        LocationCode: Code[10];
        BinCode: Code[20];
        ItemNumber: Code[50];
        VariantCode: Code[10];
        Counter: Integer;
        NoOfEntries: Integer;
        IncludeInLookup: Boolean;
    begin
        // Read Request
        // The "Lookup "History" requires four parameters: LocationCode, BinCode, NoOfEntries and ItemNumber.
        LocationCode := _RequestValues.Get_Location(true);
        NoOfEntries := _RequestValues.GetValueAsInteger('NoOfEntries', true);
        BinCode := MobToolbox.ReadBin(_RequestValues.Get_Bin());
        ItemNumber := MobItemReferenceMgt.SearchItemReference(MobToolbox.ReadEAN(_RequestValues.Get_ItemNumber(true)), VariantCode);
        //UoM Intentionally not parsed, displaying all units of measures in response.
        Location.Get(LocationCode);
        _ReturnRegistrationTypeTracking := DelChr(LocationCode + ' - ' + BinCode + ' - ' + ItemNumber, '<>', ' - ');
        MobSessionData.SetRegistrationTypeTracking(_ReturnRegistrationTypeTracking);

        if Location."Bin Mandatory" then begin
            WhseEntry.SetCurrentKey("Entry No.");
            WhseEntry.SetAscending("Entry No.", false);
            WhseEntry.SetRange("Location Code", LocationCode);
            if BinCode <> '' then
                WhseEntry.SetRange("Bin Code", BinCode);
            if ItemNumber <> '' then
                WhseEntry.SetRange("Item No.", ItemNumber);
            if VariantCode <> '' then
                WhseEntry.SetRange("Variant Code", VariantCode);

            OnLookupOnHistory_OnSetFilterWarehouseEntry(_RequestValues, WhseEntry);
            Clear(Counter);
            if WhseEntry.FindSet() then
                repeat
                    IncludeInLookup := true;
                    OnLookupOnHistory_OnIncludeWarehouseEntry(WhseEntry, IncludeInLookup);
                    if IncludeInLookup then begin
                        Counter += 1;
                        _LookupResponse.Create();
                        SetFromLookupHistory(WhseEntry, _LookupResponse);
                        _LookupResponse.Save();
                    end;
                until (WhseEntry.Next() = 0) or (Counter = NoOfEntries);

        end else begin
            ItemLedgerEntry.SetCurrentKey("Entry No.");
            ItemLedgerEntry.SetAscending("Entry No.", false);
            ItemLedgerEntry.SetRange("Location Code", LocationCode);
            if BinCode <> '' then
                exit;
            if ItemNumber <> '' then
                ItemLedgerEntry.SetRange("Item No.", ItemNumber);
            if VariantCode <> '' then
                ItemLedgerEntry.SetRange("Variant Code", VariantCode);

            OnLookupOnHistory_OnSetFilterItemLedgerEntry(_RequestValues, ItemLedgerEntry);
            Clear(Counter);
            if ItemLedgerEntry.FindSet() then
                repeat
                    IncludeInLookup := true;
                    OnLookupOnHistory_OnIncludeItemLedgerEntry(ItemLedgerEntry, IncludeInLookup);
                    if IncludeInLookup then begin
                        Counter += 1;
                        _LookupResponse.Create();
                        SetFromLookupHistory(ItemLedgerEntry, _LookupResponse);
                        _LookupResponse.Save();
                    end;
                until (ItemLedgerEntry.Next() = 0) or (Counter = NoOfEntries);
        end;
    end;

    local procedure SetFromLookupHistory(_WhseEntry: Record "Warehouse Entry"; var _LookupResponse: Record "MOB NS WhseInquery Element")
    var
        DisplayLine4List: List of [Text];
    begin
        _LookupResponse.Init();

        _LookupResponse.Set_Location(_WhseEntry."Location Code");
        _LookupResponse.Set_ItemNumber(_WhseEntry."Item No.");
        _LookupResponse.Set_Variant(_WhseEntry."Variant Code");

        _LookupResponse.SetTracking(_WhseEntry);
        _LookupResponse.Set_ExpirationDate(_WhseEntry."Expiration Date");

        _LookupResponse.SetDisplayTracking(_WhseEntry);
        _LookupResponse.Set_DisplayExpirationDate(_WhseEntry."Expiration Date" <> 0D, MobWmsLanguage.GetMessage('EXP_DATE_LABEL') + ': ' + MobWmsToolbox.Date2TextAsDisplayFormat(_WhseEntry."Expiration Date"), '');

        _LookupResponse.Set_Bin(_WhseEntry."Bin Code");
        _LookupResponse.Set_Quantity(MobWmsToolbox.Decimal2TextAsDisplayFormat(_WhseEntry.Quantity));
        if _WhseEntry.Quantity < 0 then
            _LookupResponse.Set_Positive(false);
        _LookupResponse.Set_UoM(_WhseEntry."Unit of Measure Code");

        _LookupResponse.Set_DisplayLine1(_WhseEntry.FieldCaption("Registering Date") + ': ' + MobWmsToolbox.Date2TextAsDisplayFormat(_WhseEntry."Registering Date"));
        _LookupResponse.Set_DisplayLine2(_WhseEntry.FieldCaption("User ID") + ': ' + _WhseEntry."User ID");

        _LookupResponse.Set_DisplayLine3((_WhseEntry."Source No." <> '') and (Format(_WhseEntry."Source Document") <> '0'),
           Format(_WhseEntry."Entry Type") + ' - ' + Format(_WhseEntry."Source Document") + ': ' + _WhseEntry."Source No.",
           Format(_WhseEntry."Entry Type"));

        DisplayLine4List.Add(_WhseEntry."Item No." + ' - ' + MobWmsToolbox.GetItemDescriptions(_WhseEntry."Item No.", _WhseEntry."Variant Code"));
        if _WhseEntry."Variant Code" <> '' then
            DisplayLine4List.Add(MobWmsLanguage.GetMessage('VARIANT_LABEL') + ': ' + _WhseEntry."Variant Code");
        _LookupResponse.Set_DisplayLine4(MobWmsToolbox.List2TextLn(DisplayLine4List, 999));

        _LookupResponse.Set_ItemImageID();
        _LookupResponse.Set_ReferenceID(_WhseEntry);

        OnLookupOnHistory_OnAfterSetFromWarehouseEntry(_WhseEntry, _LookupResponse);
    end;

    local procedure SetFromLookupHistory(_ItemLedgerEntry: Record "Item Ledger Entry"; var _LookupResponse: Record "MOB NS WhseInquery Element")
    var
        ValueEntry: Record "Value Entry";
        DisplayLine4List: List of [Text];
    begin
        _LookupResponse.Init();

        _LookupResponse.Set_Location(_ItemLedgerEntry."Location Code");
        _LookupResponse.Set_ItemNumber(_ItemLedgerEntry."Item No.");
        _LookupResponse.Set_Variant(_ItemLedgerEntry."Variant Code");

        _LookupResponse.SetTracking(_ItemLedgerEntry);
        _LookupResponse.Set_ExpirationDate(_ItemLedgerEntry."Expiration Date");

        _LookupResponse.SetDisplayTracking(_ItemLedgerEntry);
        _LookupResponse.Set_DisplayExpirationDate(_ItemLedgerEntry."Expiration Date" <> 0D, MobWmsLanguage.GetMessage('EXP_DATE_LABEL') + ': ' + MobWmsToolbox.Date2TextAsDisplayFormat(_ItemLedgerEntry."Expiration Date"), '');
        _LookupResponse.Set_Quantity(MobWmsToolbox.Decimal2TextAsDisplayFormat(_ItemLedgerEntry.Quantity));
        _LookupResponse.Set_UoM(_ItemLedgerEntry."Unit of Measure Code");
        if _ItemLedgerEntry.Quantity < 0 then
            _LookupResponse.Set_Positive(false);

        _LookupResponse.Set_DisplayLine1(_ItemLedgerEntry.FieldCaption("Posting Date") + ': ' + MobWmsToolbox.Date2TextAsDisplayFormat(_ItemLedgerEntry."Posting Date"));

        // Read First Value Entry to get User ID, as the User ID is not stored directly on the Item Ledger Entry
        ValueEntry.SetCurrentKey("Item Ledger Entry No.");
        ValueEntry.SetRange("Item Ledger Entry No.", _ItemLedgerEntry."Entry No.");
        if ValueEntry.FindFirst() then
            _LookupResponse.Set_DisplayLine2(ValueEntry.FieldCaption("User ID") + ': ' + ValueEntry."User ID");

        if _ItemLedgerEntry."Document Type" <> _ItemLedgerEntry."Document Type"::" " then
            _LookupResponse.Set_DisplayLine3(Format(_ItemLedgerEntry."Entry Type") + ' - ' + Format(_ItemLedgerEntry."Document Type") + ': ' + _ItemLedgerEntry."Document No.")
        else
            _LookupResponse.Set_DisplayLine3(Format(_ItemLedgerEntry."Entry Type") + ': ' + _ItemLedgerEntry."Document No.");

        DisplayLine4List.Add(_ItemLedgerEntry."Item No." + ' - ' + MobWmsToolbox.GetItemDescriptions(_ItemLedgerEntry."Item No.", _ItemLedgerEntry."Variant Code"));
        if _ItemLedgerEntry."Variant Code" <> '' then
            DisplayLine4List.Add(MobWmsLanguage.GetMessage('VARIANT_LABEL') + ': ' + _ItemLedgerEntry."Variant Code");
        _LookupResponse.Set_DisplayLine4(MobWmsToolbox.List2TextLn(DisplayLine4List, 999));

        _LookupResponse.Set_ItemImageID();
        _LookupResponse.Set_ReferenceID(_ItemLedgerEntry);

        OnLookupOnHistory_OnAfterSetFromItemLedgerEntry(_ItemLedgerEntry, _LookupResponse);
    end;

    // ------- IntegrationEvents: History -------
    //
    [IntegrationEvent(false, false)]
    local procedure OnLookupOnHistory_OnSetFilterWarehouseEntry(var _RequestValues: Record "MOB NS Request Element"; var _WhseEntry: Record "Warehouse Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupOnHistory_OnSetFilterItemLedgerEntry(var _RequestValues: Record "MOB NS Request Element"; var _ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupOnHistory_OnIncludeWarehouseEntry(_WhseEntry: Record "Warehouse Entry"; var _IncludeInLookup: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupOnHistory_OnIncludeItemLedgerEntry(_ItemLedgerEntry: Record "Item Ledger Entry"; var _IncludeInLookup: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupOnHistory_OnAfterSetFromWarehouseEntry(_WhseEntry: Record "Warehouse Entry"; var _LookupResponseElement: Record "MOB NS WhseInquery Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupOnHistory_OnAfterSetFromItemLedgerEntry(_ItemLedgerEntry: Record "Item Ledger Entry"; var _LookupResponseElement: Record "MOB NS WhseInquery Element")
    begin
    end;
}
