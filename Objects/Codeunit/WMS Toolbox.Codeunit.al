codeunit 81388 "MOB WMS Toolbox"
// Lower level Warehouse related helper functions and constants
{
    Access = Public;

    trigger OnRun()
    begin
    end;

    var
        MobItemReferenceMgt: Codeunit "MOB Item Reference Mgt.";
        MobTypeHelper: Codeunit "MOB Type Helper";
        MobToolbox: Codeunit "MOB Toolbox";
        MobRequestMgt: Codeunit "MOB NS Request Management";
        MobDeviceManagement: Codeunit "MOB Device Management";
        UnplannedMoveTok: Label 'UnplannedMove', Locked = true;
        UnplannedMoveAdvancedTok: Label 'UnplannedMoveAdvanced', Locked = true;
        RegisterPutAwayLicensePlateTok: Label 'RegisterPutAwayLicensePlate', Locked = true;
        PrintLicensePlateTok: Label 'PrintLicensePlate', Locked = true;
        UnplannedCountTok: Label 'UnplannedCount', Locked = true;
        AdjustQuantityTok: Label 'AdjustQuantity', Locked = true;
        ItemCrossReferenceTok: Label 'ItemCrossReference', Locked = true;
        AddCountLineTok: Label 'AddCountLine', Locked = true;
        ItemDimensionsTok: Label 'ItemDimensions', Locked = true;
        ToteShippingTok: Label 'ToteShipping', Locked = true;
        BulkMoveTok: Label 'BulkMove', Locked = true;
        PrintLabelTemplateTok: Label 'PrintLabelTemplate', Locked = true;
        RequestDataTok: Label 'requestData', Locked = true;
        PostShipmentTok: Label 'PostShipment', Locked = true;
        InternalTok: Label 'Internal', Locked = true;
        StartNewLicensePlateTok: Label 'StartNewLicensePlate', Locked = true;
        RegisterItemImageTok: Label 'RegisterItemImage', Locked = true;
        RegisterImageTok: Label 'RegisterImage', Locked = true;
        ToggleTotePickingTok: Label 'ToggleTotePicking', Locked = true;
        AddPhysInvtRecordLineTok: Label 'AddPhysInvtRecordLine', Locked = true;
        SubstituteProdOrderComponentTok: Label 'SubstituteProdOrderComponent', Locked = true;
        ProdUnplannedConsumptionTok: Label 'ProdUnplannedConsumption', Locked = true;
        ProdOutputTok: Label 'ProdOutput', Locked = true;
        ProdOutputTimeTrackingTok: Label 'ProdOutputTimeTracking', Locked = true;
        ProdOutputQuantityTok: Label 'ProdOutputQuantity', Locked = true;
        ProdOutputTimeTok: Label 'ProdOutputTime', Locked = true;
        ProdOutputScrapTok: Label 'ProdOutputScrap', Locked = true;
        ProdOutputFinishOperationTok: Label 'ProdOutputFinishOperation', Locked = true;
        CreateAssemblyOrderTok: Label 'CreateAssemblyOrder', Locked = true;
        AdjustQtyToAssembleTok: Label 'AdjustQtyToAssemble', Locked = true;
        EditLicensePlateTok: Label 'EditLicensePlate', Locked = true;
        CreateStepsByReferenceDataKeyAlreadySetErr: Label 'Internal error "%1".Create_StepsByReferenceDataKey: RegisterExtraInfo is already set (%2).', Locked = true;
        PostingMessageIdErr: Label 'Internal error in .SaveReferenceData(): PostingMessageId cannot be an empty guid.', Locked = true;
        MUST_BE_TEMPORARY_Err: Label 'Internal error: %1 must be a temporary record.', Locked = true;
        InvalidLicensePlaceUsageErr: Label 'This document does not require a Warehouse Receipt, therefore License Plates cannot be used.\\Please delete the registrations and try again.';

    // 
    // ------- ITEM -------
    // 

    // Previously named GetItemInvtLedgerBySerialNo 
    procedure InventoryExistsBySerialNo(_ItemNo: Code[20]; _VariantCode: Code[20]; _SerialNumber: Code[50]): Boolean
    var
        MobTrackingSetup: Record "MOB Tracking Setup";
    begin
        Clear(MobTrackingSetup);
        MobTrackingSetup."Serial No." := _SerialNumber;
        exit(InventoryExists(_ItemNo, _VariantCode, MobTrackingSetup));
    end;

    // Previously named GetItemInvtLedgerByLotNo
    procedure InventoryExistsByLotNo(_ItemNo: Code[20]; _VariantCode: Code[20]; _LotNumber: Code[50]): Boolean
    var
        MobTrackingSetup: Record "MOB Tracking Setup";
    begin
        Clear(MobTrackingSetup);
        MobTrackingSetup."Lot No." := _LotNumber;
        exit(InventoryExists(_ItemNo, _VariantCode, MobTrackingSetup));
    end;

    procedure InventoryExists(_ItemNo: Code[20]; _VariantCode: Code[20]; _MobTrackingSetup: Record "MOB Tracking Setup"): Boolean
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.Reset();
        ItemLedgerEntry.SetCurrentKey("Item No.", Open, "Variant Code", Positive);
        ItemLedgerEntry.SetRange("Item No.", _ItemNo);
        ItemLedgerEntry.SetRange(Open, true);
        ItemLedgerEntry.SetRange("Variant Code", _VariantCode);
        ItemLedgerEntry.SetRange(Positive, true);
        _MobTrackingSetup.SetTrackingFilterForItemLedgerEntryIfNotBlank(ItemLedgerEntry);

        exit(not ItemLedgerEntry.IsEmpty());
    end;

    /// <summary>
    /// Replaced by procedure InventoryExists() with parameter "Mob Tracking Setup"  (but not planned for removal for backwards compatibility)
    /// </summary>
    procedure GetItemInvtLedger(_ItemNo: Code[20]; _VariantCode: Code[20]; _SerialNo: Code[50]; _LotNo: Code[50]): Boolean
    var
        MobTrackingSetup: Record "MOB Tracking Setup";
    begin
        MobTrackingSetup."Serial No." := _SerialNo;
        MobTrackingSetup."Lot No." := _LotNo;
        exit(InventoryExists(_ItemNo, _VariantCode, MobTrackingSetup));
    end;

    /// <summary>
    /// Get list of items "Unit of Measure" codes
    /// </summary>
    procedure GetItemUoM(_ItemNo: Code[20]) _ItemUoMList: Text
    begin
        _ItemUoMList := GetItemUoMList(_ItemNo, '', false);
    end;

    /// <summary>
    /// Get list of items "Unit of Measure" codes, only units which also has exists as Item Reference
    /// </summary>
    internal procedure GetItemReferenceUoMList(_ItemNo: Code[20]; _VariantCode: Code[10]) ReturnItemUoMList: Text
    begin
        ReturnItemUoMList := GetItemUoMList(_ItemNo, _VariantCode, true);
    end;

    /// <summary>
    /// Get list of items "Unit of Measure" codes
    /// </summary>
    /// <param name="_ItemNo">Item No.</param>
    /// <param name="_VariantCode">Variant Code</param>
    /// <param name="_MustBeItemReference">Include only units which exists as Item Reference</param>
    local procedure GetItemUoMList(_ItemNo: Code[20]; _VariantCode: Code[10]; _MustBeItemReference: Boolean) ReturnItemUoMList: Text
    var
        ItemUoM: Record "Item Unit of Measure";
        AddToList: Boolean;
    begin
        ItemUoM.SetCurrentKey("Item No.", "Qty. per Unit of Measure");
        ItemUoM.SetRange("Item No.", _ItemNo);
        if ItemUoM.FindSet() then
            repeat
                if _MustBeItemReference then
                    AddToList := MobItemReferenceMgt.GetFirstReferenceNo(ItemUoM."Item No.", _VariantCode, ItemUoM.Code) <> ''
                else
                    AddToList := true;

                if AddToList then
                    if ReturnItemUoMList = '' then
                        ReturnItemUoMList := ItemUoM.Code
                    else
                        ReturnItemUoMList += ';' + ItemUoM.Code;
            until ItemUoM.Next() = 0;
        exit(ReturnItemUoMList);
    end;

    /// <summary>
    /// Get item has more than one "Unit of Measure" codes
    /// </summary>
    procedure GetItemHasMultipleUoM(_ItemNo: Code[20]): Boolean
    begin
        exit(StrPos(GetItemUoM(_ItemNo), ';') > 1);
    end;

    procedure GetItemVariants(_ItemNo: Code[20]) _ItemVariantList: Text
    var
        MobSetup: Record "MOB Setup";
        ItemVariant: Record "Item Variant";
    begin
        MobSetup.Get();

        ItemVariant.SetRange("Item No.", _ItemNo);
        if ItemVariant.FindSet() then begin
            repeat
                if _ItemVariantList = '' then
                    _ItemVariantList := ItemVariant.Code
                else
                    _ItemVariantList += ';' + ItemVariant.Code;
            until ItemVariant.Next() = 0;

            if MobSetup."Allow Blank Variant Code" then
                _ItemVariantList += '; ';
        end;

        exit(_ItemVariantList);
    end;

    /// <summary>
    /// Return Item No. and VariantCode with leading text as concatinated text.
    /// </summary>
    procedure GetItemAndVariantTxt(_ItemNo: Code[20]; _VariantNo: Code[10]) _ReturnText: Text
    var
        MobWmsLanguage: Codeunit "MOB WMS Language";
    begin
        _ReturnText := ' ' + MobWmsLanguage.GetMessage('ITEM_NO') + ': ' + _ItemNo;

        if _VariantNo <> '' then
            _ReturnText += ' ' + MobWmsLanguage.GetMessage('VARIANT_LABEL') + ': ' + _VariantNo;
    end;

    /// <summary>
    /// Return Item Variant Description.
    /// Fallback to Item.Description if called with blank with blank VariantCode or no description is entered in ItemVariant.
    /// </summary>
    procedure GetItemDescription(_ItemNo: Code[20]; _VariantCode: Code[10]) ReturnDescription: Text
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
    begin
        if _VariantCode <> '' then
            if ItemVariant.Get(_ItemNo, _VariantCode) then
                ReturnDescription := ItemVariant.Description;

        // Fallback if called with blank VariantCode or no description is entered in ItemVariant
        if ReturnDescription = '' then
            if Item.Get(_ItemNo) then
                ReturnDescription := Item.Description;

        exit(ReturnDescription);
    end;

    /// <summary>
    /// Return Item Variant Description 1 and 2 as concatinated text.
    /// Fallback to Item Description 1 and 2 if called with blank with blank VariantCode or no description is entered in ItemVariant.
    /// </summary>
    internal procedure GetItemDescriptions(_ItemNo: Code[20]; _VariantCode: Code[10]) ReturnDescription: Text
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        SeparatorText: Text;
    begin
        SeparatorText := ' ';

        if _VariantCode <> '' then
            if ItemVariant.Get(_ItemNo, _VariantCode) then
                ReturnDescription := MobToolbox.JoinText(ItemVariant.Description, ItemVariant."Description 2", SeparatorText);

        // Fallback if called with blank VariantCode or no description is entered in ItemVariant
        if ReturnDescription = '' then
            if Item.Get(_ItemNo) then
                ReturnDescription := MobToolbox.JoinText(Item.Description, Item."Description 2", SeparatorText);

        ReturnDescription := ReturnDescription.TrimStart(SeparatorText);
        exit(ReturnDescription);
    end;

    procedure GetDefaultBin(_ItemNo: Code[20]; _LocationCode: Code[10]; _VariantCode: Code[10]): Code[20]
    var
        BinContent: Record "Bin Content";
        DefaultBin: Code[20];
    begin
        Clear(DefaultBin);

        BinContent.SetCurrentKey(Default, "Location Code", "Item No.", "Variant Code", "Bin Code");
        BinContent.SetRange("Location Code", _LocationCode);
        BinContent.SetRange("Item No.", _ItemNo);
        if _VariantCode <> '' then
            BinContent.SetRange("Variant Code", _VariantCode);
        BinContent.SetFilter(Quantity, '>0');
        BinContent.SetRange(Default, true);
        if BinContent.IsEmpty() then
            BinContent.SetRange(Default);
        if BinContent.FindSet() then
            repeat
                if DefaultBin = '' then
                    DefaultBin := BinContent."Bin Code";
            until BinContent.Next() = 0;
        exit(DefaultBin);
    end;

    /// <summary>
    /// Get exact ItemNumber, and if not exists, search fallback options including Item References. Will throw error if no match is found.
    /// Use ItemReferenceMgt.SearchItemReference(...) to suppress error.
    /// </summary>
    procedure GetItemNumber(_ScannedBarcode: Code[50]) ReturnItemReferenceNo: Code[50]
    var
        Item: Record Item;
        DummyVariantCode: Code[10];
        DummyUoMCode: Code[10];
    begin
        // Determine if the provided value is an item number or an item identifier
        if StrLen(_ScannedBarcode) <= MaxStrLen(Item."No.") then
            if Item.Get(_ScannedBarcode) then begin
                // The value from the mobile device is an item number -> use that
                ReturnItemReferenceNo := _ScannedBarcode;
                exit;
            end;

        // The value is not an item number -> must find an item reference or other reference
        ReturnItemReferenceNo := MobItemReferenceMgt.SearchItemReference(_ScannedBarcode, DummyVariantCode, DummyUoMCode, true);
        exit(ReturnItemReferenceNo);
    end;

    procedure GetItemShelfNo(_ItemNo: Code[20]; _LocationCode: Code[10]; _VariantCode: Code[10]): Code[10]
    var
        SKU: Record "Stockkeeping Unit";
        Item: Record Item;
    begin
        if SKU.Get(_LocationCode, _ItemNo, _VariantCode) then
            if SKU."Shelf No." <> '' then
                exit(SKU."Shelf No.");

        if Item.Get(_ItemNo) then
            exit(Item."Shelf No.");
    end;

    procedure CalcQtyNewUOM(_ItemNo: Code[20]; _Qty: Decimal; _FromUoM: Code[10]; _ToUoM: Code[10]): Decimal
    begin
        exit(CalcQtyNewUOM(_ItemNo, _Qty, _FromUoM, _ToUoM, false));
    end;

    procedure CalcQtyNewUOMRounded(_ItemNo: Code[20]; _Qty: Decimal; _FromUoM: Code[10]; _ToUoM: Code[10]): Decimal
    begin
        exit(CalcQtyNewUOM(_ItemNo, _Qty, _FromUoM, _ToUoM, true));
    end;

    local procedure CalcQtyNewUOM(_ItemNo: Code[20]; _Qty: Decimal; _FromUoM: Code[10]; _ToUoM: Code[10]; _ApplyRounding: Boolean): Decimal
    var
        FromItemUnit: Record "Item Unit of Measure";
        ToItemUnit: Record "Item Unit of Measure";
        UoMMgt: Codeunit "Unit of Measure Management";
    begin
        FromItemUnit.Get(_ItemNo, _FromUoM);
        ToItemUnit.Get(_ItemNo, _ToUoM);

        /* #if BC19+ */
        if _ApplyRounding then
            exit(UoMMgt.RoundQty(_Qty * FromItemUnit."Qty. per Unit of Measure" / ToItemUnit."Qty. per Unit of Measure", ToItemUnit."Qty. Rounding Precision"));
        /* #endif */
        /* #if BC18- ##
        if _ApplyRounding then
            exit(UoMMgt.RoundQty(_Qty * FromItemUnit."Qty. per Unit of Measure" / ToItemUnit."Qty. per Unit of Measure"));
        /* #endif */

        exit(_Qty * FromItemUnit."Qty. per Unit of Measure" / ToItemUnit."Qty. per Unit of Measure");
    end;

    // 
    // ------- BIN -------
    // 

    /// <remarks>
    /// Called only from WMS Pick and only for blank Tracking
    /// </remarks>
    procedure GetFromBin(_ItemNo: Code[20]; _LocationCode: Code[10]; _VariantCode: Code[10]; _MobTrackingSetup: Record "MOB Tracking Setup"; _QtyToPick: Decimal; var _Sorting: Integer): Code[20]
    var
        BinContent: Record "Bin Content";
    begin
        BinContent.SetCurrentKey("Location Code", "Item No.", "Variant Code", "Warehouse Class Code", Fixed, "Bin Ranking");
        BinContent.SetRange("Location Code", _LocationCode);
        BinContent.SetRange("Item No.", _ItemNo);
        BinContent.SetRange("Variant Code", _VariantCode);
        _MobTrackingSetup.SetTrackingFilterForBinContentIfNotBlank(BinContent);
        BinContent.SetFilter(Quantity, '>=%1', Abs(_QtyToPick));
        if BinContent.FindFirst() then begin
            _Sorting := BinContent."Bin Ranking";
            exit(BinContent."Bin Code");
        end else begin
            BinContent.SetFilter(Quantity, '<>0');
            if BinContent.FindFirst() then begin
                _Sorting := BinContent."Bin Ranking";
                exit(BinContent."Bin Code");
            end;
        end;

        // Set sorting to 1000000 to make line appear last when there is no qty. on hand
        _Sorting := 1000000;
        exit('');
    end;

    /// <summary>
    /// Replaced by procedure GetFromBin() with parameter "Mob Tracking Setup"  (but not planned for removal for backwards compatibility)
    /// </summary>
    procedure GetFromBin(_ItemNo: Code[20]; _LocationCode: Code[10]; _VariantCode: Code[10]; _LotNo: Code[50]; _SerialNo: Code[50]; _QtyToPick: Decimal; var _Sorting: Integer): Code[20]
    var
        MobTrackingSetup: Record "MOB Tracking Setup";
    begin
        MobTrackingSetup.ClearTrackingRequired();
        MobTrackingSetup."Serial No." := _SerialNo;
        MobTrackingSetup."Lot No." := _LotNo;

        exit(GetFromBin(_ItemNo, _LocationCode, _VariantCode, MobTrackingSetup, _QtyToPick, _Sorting));
    end;

    procedure GetZoneFromBin(_Location: Code[10]; _Bin: Code[20]): Code[10]
    var
        Bin: Record "Bin";
    begin
        // Get Zone From Bin
        if Bin.Get(_Location, _Bin) then
            exit(Bin."Zone Code");
    end;

    /// <summary>
    /// Before the registrations are processed we need to determine if the multiple bins have been used in the registrations
    /// </summary>
    /// <param name="_MobWmsRegistration"></param>
    procedure ValidateSingleRegistrationBin(var _MobWmsRegistration: Record "MOB WMS Registration")
    var
        MobWmsLanguage: Codeunit "MOB WMS Language";
        FirstFromBinCode: Code[20];
        FirstToBinCode: Code[20];
    begin
        if _MobWmsRegistration.FindSet() then begin
            // First loop -> register the bins to compare against
            FirstFromBinCode := _MobWmsRegistration.FromBin;
            FirstToBinCode := _MobWmsRegistration.ToBin;
            repeat

                // Other bin code is used -> abort the post and notify the user
                if _MobWmsRegistration.FromBin <> FirstFromBinCode then
                    Error('%1\\%2: %3 <> %4', MobWmsLanguage.GetMessage('MULTI_BINS_NOT_ALLOWED'), MobWmsLanguage.GetMessage('FROM_BIN_LABEL'), _MobWmsRegistration.FromBin, FirstFromBinCode);

                if _MobWmsRegistration.ToBin <> FirstToBinCode then
                    Error('%1\\%2: %3 <> %4', MobWmsLanguage.GetMessage('MULTI_BINS_NOT_ALLOWED'), MobWmsLanguage.GetMessage('TO_BIN_LABEL'), _MobWmsRegistration.ToBin, FirstToBinCode);

            until _MobWmsRegistration.Next() = 0;
        end;
    end;

    //
    // ------- TOTE -------
    //

    procedure LookupTotes(var _WhseShipmentLine: Record "Warehouse Shipment Line") _ToteTxt: Text
    var
        MobWmsRegistration: Record "MOB WMS Registration";
    begin
        MobWmsRegistration.SetCurrentKey("Whse. Document Type", "Whse. Document No.", "Whse. Document Line No.", "Tote ID");
        MobWmsRegistration.SetRange("Whse. Document Type", MobWmsRegistration."Whse. Document Type"::Shipment);
        MobWmsRegistration.SetRange("Whse. Document No.", _WhseShipmentLine."No.");
        MobWmsRegistration.SetRange("Whse. Document Line No.", _WhseShipmentLine."Line No.");
        _ToteTxt := BuildToteTxt(MobWmsRegistration);
    end;

    local procedure BuildToteTxt(var _MobWmsRegistration: Record "MOB WMS Registration") _ToteTxt: Text
    var
        LastToteId: Code[100];
    begin
        Clear(LastToteId);
        if _MobWmsRegistration.FindSet() then
            repeat
                // Since the registrations are sorted by the tote id this check will prevent the same tote id from being added multiple times
                if LastToteId <> _MobWmsRegistration."Tote ID" then begin
                    if _ToteTxt = '' then
                        _ToteTxt := _MobWmsRegistration."Tote ID"
                    else
                        _ToteTxt += ', ' + _MobWmsRegistration."Tote ID";
                    // Remember the last tote
                    LastToteId := _MobWmsRegistration."Tote ID";
                end;
            until _MobWmsRegistration.Next() = 0;
    end;

    //
    // ------- ITEM TRACKING -------
    //

    procedure ExtractLotAndExpirationDate(_Data: Code[70]; var _LotNumber: Code[50]; var _ExpirationDate: Date)
    var
        SeparatorPosition: Integer;
        i: Integer;
    begin

        // Find the last occurence of the separator
        for i := 1 to StrLen(_Data) do
            if _Data[i] = ',' then
                SeparatorPosition := i;

        // Date format dd-mm-yyyy   Ex. LOT1123,24-12-2009
        if (SeparatorPosition <> 0) and (MobToolbox.IsDateText(CopyStr(_Data, SeparatorPosition + 1))) then begin
            _LotNumber := CopyStr(_Data, 1, SeparatorPosition - 1);
            _ExpirationDate := MobToolbox.Text2Date(CopyStr(_Data, SeparatorPosition + 1))
        end else
            // In BC ExpirationDate is intentionally not cleared here, as ExpirationDate is set to whatever date comes last in the Xml
            // In NAV priority is defined in method MobWmsRegistration.GetExtractedExpirationDate() instead
            _LotNumber := _Data;
    end;

    procedure ExtractSerialAndExpirationDate(_Data: Code[70]; var _SerialNumber: Code[50]; var _ExpirationDate: Date)
    var
        SeparatorPosition: Integer;
        i: Integer;
    begin

        // Find the last occurence of the separator
        for i := 1 to StrLen(_Data) do
            if _Data[i] = ',' then
                SeparatorPosition := i;

        // Date format dd-mm-yyyy   Ex. SERIAL1123,24-12-2009
        if (SeparatorPosition <> 0) and (MobToolbox.IsDateText(CopyStr(_Data, SeparatorPosition + 1))) then begin
            _SerialNumber := CopyStr(_Data, 1, SeparatorPosition - 1);
            _ExpirationDate := MobToolbox.Text2Date(CopyStr(_Data, SeparatorPosition + 1))
        end else
            // In BC ExpirationDate is intentionally not cleared here, as ExpirationDate is set to whatever date comes last in the Xml
            // In NAV priority is defined in method MobWmsRegistration.GetExtractedExpirationDate() instead
            _SerialNumber := _Data;   // Intentionally do not overwrite ExpirationDate but still throw error on overflow 
    end;

    /// <summary>
    /// Determine if Warehouse Tracking enabled for the _TrackingType. Only Serial and Lot is supported, all other tracking types must be handled using other means (including MobTrackingSetup and events).
    /// </summary>
    procedure WarehouseTrackingEnabled(_ItemNo: Code[20]; _TrackingType: Option Serial,Lot,Either): Boolean
    var
        ItemTrackingCode: Record "Item Tracking Code";
        Item: Record Item;
    begin
        if Item.Get(_ItemNo) then
            if ItemTrackingCode.Get(Item."Item Tracking Code") then
                case _TrackingType of
                    _TrackingType::Serial:
                        exit(ItemTrackingCode."SN Warehouse Tracking");
                    _TrackingType::Lot:
                        exit(ItemTrackingCode."Lot Warehouse Tracking");
                    // Package No. intentionally not supported in this function (cannot change signature)
                    _TrackingType::Either:
                        exit(ItemTrackingCode."SN Warehouse Tracking" or ItemTrackingCode."Lot Warehouse Tracking");
                end;
        exit(false);
    end;

    procedure GetTrackedSummary(var _TempEntrySummary: Record "Entry Summary" temporary; _Location: Record Location; _BinCode: Code[20]; _ItemNo: Code[20]; _VariantCode: Code[10]; _UnitOfMeasureCode: Code[10]; _UseExpDates: Boolean)
    begin
        if not _TempEntrySummary.IsTemporary() then
            Error(MUST_BE_TEMPORARY_Err, _TempEntrySummary.TableCaption());

        _TempEntrySummary.Reset();
        _TempEntrySummary.DeleteAll();

        if _Location."Bin Mandatory" then
            GetTrackedSummaryWarehouseEntry(_TempEntrySummary, _Location, _BinCode, _ItemNo, _VariantCode, _UnitOfMeasureCode, _UseExpDates)
        else
            GetTrackedSummaryItemLedgerEntry(_TempEntrySummary, _Location, _ItemNo, _VariantCode, _UseExpDates);

        _TempEntrySummary.Reset();
    end;

    local procedure GetTrackedSummaryWarehouseEntry(var _TempEntrySummary: Record "Entry Summary" temporary; _Location: Record Location; _BinCode: Code[20]; _ItemNo: Code[20]; _VariantCode: Code[10]; _UnitOfMeasureCode: Code[10]; _UseExpDates: Boolean)
    var
        MobTrackingSetup: Record "MOB Tracking Setup";
        MobItemTrackingManagement: Codeunit "MOB Item Tracking Management";
        TrackingByBin: Query "MOB WMS Tracking By Bin";
        ExpirationDate: Date;
    begin
        TrackingByBin.SetRange(Location_Code, _Location.Code);
        if _BinCode <> '' then
            TrackingByBin.SetRange(Bin_Code, _BinCode);
        if _ItemNo <> '' then
            TrackingByBin.SetRange(Item_No, _ItemNo);
        if _VariantCode <> '' then
            TrackingByBin.SetRange(Variant_Code, _VariantCode);
        if _UnitOfMeasureCode <> '' then
            TrackingByBin.SetRange(Unit_of_Measure_Code, _UnitOfMeasureCode);

        TrackingByBin.Open();

        MobTrackingSetup.DetermineWhseTrackingRequiredWithExpirationDate(_ItemNo, _UseExpDates);

        while TrackingByBin.Read() do begin
            MobTrackingSetup.CopyTrackingFromTrackingByBinQueryIfRequired(TrackingByBin);

            if _UseExpDates then
                MobItemTrackingManagement.GetWhseExpirationDate(TrackingByBin.Item_No, TrackingByBin.Variant_Code, _Location, MobTrackingSetup, ExpirationDate);

            InsertTrackedSummaryEntry(_TempEntrySummary, MobTrackingSetup, ExpirationDate);
        end;
    end;

    local procedure GetTrackedSummaryItemLedgerEntry(var _TempEntrySummary: Record "Entry Summary" temporary; _Location: Record Location; _ItemNo: Code[20]; _VariantCode: Code[10]; _UseExpDates: Boolean)
    var
        MobTrackingSetup: Record "MOB Tracking Setup";
        ItemLedgerEntry: Record "Item Ledger Entry";
        MobItemTrackingManagement: Codeunit "MOB Item Tracking Management";
        ExpirationDate: Date;
    begin
        ItemLedgerEntry.Reset();
        /* #if BC18+ */
        ItemLedgerEntry.SetCurrentKey("Item No.", Open, "Variant Code", Positive, "Lot No.", "Serial No.", "Package No.");
        /* #endif */
        /* #if BC17- ##
        ItemLedgerEntry.SetCurrentKey("Item No.", Open, "Variant Code", Positive, "Lot No.", "Serial No.");
        /* #endif */
        ItemLedgerEntry.SetRange("Item No.", _ItemNo);
        ItemLedgerEntry.SetRange(Open, true);
        ItemLedgerEntry.SetRange("Variant Code", _VariantCode);
        ItemLedgerEntry.SetRange(Positive, true);
        ItemLedgerEntry.SetRange("Location Code", _Location.Code);
        if ItemLedgerEntry.IsEmpty() then
            exit;

        MobTrackingSetup.DetermineSpecificTrackingRequiredFromItemNo(_ItemNo, _UseExpDates);

        if ItemLedgerEntry.FindSet() then
            repeat
                MobTrackingSetup.CopyTrackingFromItemLedgerEntry(ItemLedgerEntry);

                if _UseExpDates then
                    MobItemTrackingManagement.GetWhseExpirationDate(ItemLedgerEntry."Item No.", ItemLedgerEntry."Variant Code", _Location, MobTrackingSetup, ExpirationDate);

                InsertTrackedSummaryEntry(_TempEntrySummary, MobTrackingSetup, ExpirationDate);
            until ItemLedgerEntry.Next() = 0;
    end;

    local procedure InsertTrackedSummaryEntry(var _TempEntrySummary: Record "Entry Summary"; var _MobTrackingSetup: Record "MOB Tracking Setup"; _ExpirationDate: Date)
    var
        LastEntry: Integer;
    begin
        _MobTrackingSetup.SetTrackingFilterForEntrySummary(_TempEntrySummary);

        // Dont insert same Tracking twice
        if not _TempEntrySummary.IsEmpty() then
            exit;

        _TempEntrySummary.Reset();
        if _TempEntrySummary.FindLast() then
            LastEntry := _TempEntrySummary."Entry No.";

        _TempEntrySummary.Init();
        _TempEntrySummary."Entry No." := LastEntry + 1;
        _MobTrackingSetup.CopyTrackingToEntrySummary(_TempEntrySummary);
        _TempEntrySummary."Expiration Date" := _ExpirationDate;
        _TempEntrySummary.Insert();
    end;

    // 
    // ------- MISC -------
    // 

    /// <summary>
    /// Converts TypeAndQty Order Values to Dictionary
    /// </summary>
    procedure TypeAndQtyValueToDictionary(_TypeAndQtyOrderValue: Text; var _TypeAndQtyDictionary: Dictionary of [Text, Decimal])
    begin
        TypeAndQtyValueToDictionary(_TypeAndQtyOrderValue, ';', _TypeAndQtyDictionary);
    end;

    /// <summary>
    /// Converts TypeAndQty Order Values to Dictionary
    /// </summary>
    procedure TypeAndQtyValueToDictionary(_TypeAndQtyOrderValue: Text; _ListSeparator: Text; var _TypeAndQtyDictionary: Dictionary of [Text, Decimal])
    var
        TypesAndQuantitiesList: List of [Text];
        TypeAndQuantityList: List of [Text];
        TypeAndQtyValuePair: Text;
        TypeKey: Text;
        QuantityValue: Decimal;
    begin
        TypesAndQuantitiesList := _TypeAndQtyOrderValue.Split(_ListSeparator);

        foreach TypeAndQtyValuePair in TypesAndQuantitiesList do begin
            TypeAndQuantityList := TypeAndQtyValuePair.Split('=');
            TypeKey := TypeAndQuantityList.Get(1);
            Evaluate(QuantityValue, TypeAndQuantityList.Get(2), 9);
            _TypeAndQtyDictionary.Add(TypeKey, QuantityValue);
        end;
    end;

    procedure GetLocationFilter(_MobileUserID: Text[65]) _LocationFilter: Text
    var
        WhseEmp: Record "Warehouse Employee";
        IsHandled: Boolean;
    begin
        OnBeforeGetLocationFilter(_LocationFilter, IsHandled);
        if IsHandled then
            exit(_LocationFilter);

        // Filter the warehouse employee table to show the locations assigned to this user
        WhseEmp.SetRange("User ID", _MobileUserID);
        WhseEmp.SetFilter("Location Code", '<>%1', '');

        _LocationFilter := 'EMPTY|';

        if WhseEmp.FindSet() then
            repeat

                // Build the location filter string
                _LocationFilter := _LocationFilter + WhseEmp."Location Code" + '|';

            until WhseEmp.Next() = 0;

        // Remove the trailing '|' in the filter
        if _LocationFilter <> '' then
            _LocationFilter := DelStr(_LocationFilter, StrLen(_LocationFilter), 1);

        exit(_LocationFilter);
    end;

    /// <summary>
    /// Gets location and returns Bin Mandatory
    /// </summary>    
    procedure LocationIsBinMandatory(_LocationCode: Code[10]): Boolean
    var
        Location: Record Location;
    begin
        Location.Get(_LocationCode);
        exit(Location."Bin Mandatory");
    end;

    /// <summary>
    /// Mirror code from BC17 table "Item Tracking Code" (all version BC14+ can use same code)
    /// </summary>    
    procedure IsWarehouseTracking(_ItemTrackingCode: Record "Item Tracking Code") _WarehouseTracking: Boolean
    begin
        /* #if BC18+ */
        _WarehouseTracking := _ItemTrackingCode.IsWarehouseTracking();
        /* #endif */
        /* #if BC17- ##
        _WarehouseTracking := _ItemTrackingCode."SN Warehouse Tracking" or _ItemTrackingCode."Lot Warehouse Tracking";
        /* #endif */
    end;

    procedure IsWarehouseTracking(_ItemNo: Code[20]) _WarehouseTracking: Boolean
    var
        ItemTrackingCode: Record "Item Tracking Code";
        Item: Record Item;
    begin
        if not Item.Get(_ItemNo) then
            exit(false);

        if not ItemTrackingCode.Get(Item."Item Tracking Code") then
            exit(false);

        exit(IsWarehouseTracking(ItemTrackingCode));
    end;

    procedure FindOpenPickIDs(var _WhseShptLine: Record "Warehouse Shipment Line") _PickIDs: Text
    var
        WhseActLine: Record "Warehouse Activity Line";
    begin
        if _WhseShptLine.FindSet() then
            repeat
                WhseActLine.SetCurrentKey("Whse. Document No.", "Whse. Document Type", "Activity Type", "Whse. Document Line No.");
                WhseActLine.SetRange("Whse. Document No.", _WhseShptLine."No.");
                WhseActLine.SetRange("Whse. Document Type", WhseActLine."Whse. Document Type"::Shipment);
                WhseActLine.SetRange("Whse. Document Line No.", _WhseShptLine."Line No.");
                if WhseActLine.FindSet() then
                    repeat
                        if _PickIDs = '' then
                            _PickIDs := WhseActLine."No."
                        else
                            if StrPos(_PickIDs, WhseActLine."No.") = 0 then
                                _PickIDs += ', ' + WhseActLine."No.";
                    until WhseActLine.Next() = 0;
            until _WhseShptLine.Next() = 0;
    end;

    /// <summary>
    /// Create the required Inbound Whse Doc.
    /// Either Receipt or Inventory Put-away based on Location Setup
    /// </summary>    
    procedure CreateInboundTransferWarehouseDoc(_TransferNo: Code[20])
    var
        TransferHeader: Record "Transfer Header";
        Location: Record Location;
        WhseRequest: Record "Warehouse Request";
        GetSourceDocuments: Report "Get Source Documents";
        CreateInvtPutawayPickMvmt: Report "Create Invt Put-away/Pick/Mvmt";
    begin
        if TransferHeader.Get(_TransferNo) and Location.Get(TransferHeader."Transfer-to Code") then
            // Create Receipt
            if Location."Require Receive" then begin
                TransferHeader.TestField(Status, TransferHeader.Status::Released);
                WhseRequest.Reset();
                WhseRequest.SetRange(Type, WhseRequest.Type::Inbound);
                WhseRequest.SetRange("Source Type", Database::"Transfer Line");
                WhseRequest.SetRange("Source Subtype", 1);
                WhseRequest.SetRange("Source No.", TransferHeader."No.");
                WhseRequest.SetRange("Document Status", WhseRequest."Document Status"::Released);
                if WhseRequest.FindFirst() then begin
                    GetSourceDocuments.UseRequestPage(false);
                    GetSourceDocuments.SetTableView(WhseRequest);
                    GetSourceDocuments.RunModal();
                end;
            end
            else
                // Create Inventory Put-away
                if Location."Require Put-away" then begin
                    WhseRequest.Reset();
                    WhseRequest.SetCurrentKey("Source Document", "Source No.");
                    WhseRequest.SetFilter(
                      "Source Document", '%1|%2',
                      WhseRequest."Source Document"::"Inbound Transfer",
                      WhseRequest."Source Document"::"Outbound Transfer");
                    WhseRequest.SetRange("Source No.", _TransferNo);
                    CreateInvtPutawayPickMvmt.UseRequestPage(false);
                    CreateInvtPutawayPickMvmt.SetTableView(WhseRequest);
                    CreateInvtPutawayPickMvmt.InitializeRequest(true, true, false, false, false);
                    CreateInvtPutawayPickMvmt.RunModal();
                end;
    end;

    procedure CheckWhseSetupReceipt()
    var
        WarehouseSetup: Record "Warehouse Setup";
    begin
        if WarehouseSetup.Get() then
            WarehouseSetup.TestField("Receipt Posting Policy", WarehouseSetup."Receipt Posting Policy"::"Stop and show the first posting error");
    end;

    procedure CheckWhseSetupShipment()
    var
        WarehouseSetup: Record "Warehouse Setup";
    begin
        if WarehouseSetup.Get() then
            WarehouseSetup.TestField("Shipment Posting Policy", WarehouseSetup."Shipment Posting Policy"::"Stop and show the first posting error");
    end;

    procedure SetWhseSetupErrorMessages()
    var
        WarehouseSetup: Record "Warehouse Setup";
    begin
        if WarehouseSetup.Get() then begin
            WarehouseSetup.Validate("Shipment Posting Policy",
              WarehouseSetup."Shipment Posting Policy"::"Stop and show the first posting error");
            WarehouseSetup.Validate("Receipt Posting Policy",
              WarehouseSetup."Receipt Posting Policy"::"Stop and show the first posting error");
            WarehouseSetup.Modify(true);
        end;
    end;

    procedure DeleteReservationEntries(var _TmpReservationEntryLog: Record "Reservation Entry" temporary)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        // First delete any created or modified Reservation Entries
        if _TmpReservationEntryLog.FindSet() then
            repeat
                ReservationEntry.Get(_TmpReservationEntryLog."Entry No.", _TmpReservationEntryLog.Positive);
                ReservationEntry.Delete(true);
            until _TmpReservationEntryLog.Next() = 0;

        // If the TmpReservationEntryLog is a backup of an existing ReservationEntry, we need to restore the original
        // In that case the TmpReservationEntryLog.Correction boolean will be true
        _TmpReservationEntryLog.SetRange(Correction, true);
        if _TmpReservationEntryLog.FindSet() then
            repeat
                ReservationEntry.Copy(_TmpReservationEntryLog);
                ReservationEntry.Correction := false;
                ReservationEntry.Insert();
            until _TmpReservationEntryLog.Next() = 0;
    end;

    procedure GetReasonCodes() _ReasonCodeList: Text
    var
        ReasonCode: Record "Reason Code";
    begin
        if ReasonCode.FindSet() then
            repeat
                if _ReasonCodeList = '' then
                    _ReasonCodeList := ReasonCode.Code
                else
                    _ReasonCodeList += ';' + ReasonCode.Code;
            until ReasonCode.Next() = 0;

        exit(_ReasonCodeList);
    end;

    /// <summary>
    /// Get the Code value of the first recordref field related to a specific table.
    /// </summary>
    /// <param name="_SourceRecRef">The source of the record to get a value from. Example a Sales Line recref</param>
    /// <param name="_RelatedTableId">The table no. of the related table. Example Database::Item</param>
    /// <param name="_ReturnValue">The value of the field. The value is not changed if no field is found. Example the value of the "No." field </param>
    /// <returns>Specifies if a field was found with a relation to the specified table.</returns>
    internal procedure GetFirstRelatedFieldValue(var _SourceRecRef: RecordRef; _RelatedTableId: Integer; var _ReturnValue: Code[250]) Found: Boolean
    var
        TableRelationsMetadata: Record "Table Relations Metadata";
    begin
        if _SourceRecRef.Number() = 0 then
            exit;

        if _SourceRecRef.IsTemporary() then
            exit; // RecRefIsWithinTableRelationCondition() does not support temporary records

        TableRelationsMetadata.SetRange("Table ID", _SourceRecRef.Number());
        TableRelationsMetadata.SetRange("Related Table ID", _RelatedTableId);
        if TableRelationsMetadata.FindSet() then
            repeat
                if RecRefIsWithinTableRelationCondition(_SourceRecRef, TableRelationsMetadata) then begin
                    _ReturnValue := _SourceRecRef.Field(TableRelationsMetadata."Field No.").Value();
                    exit(true);
                end;

            until TableRelationsMetadata.Next() = 0;
    end;

    local procedure RecRefIsWithinTableRelationCondition(_RecRef: RecordRef; var _TableRelationsMetadata: Record "Table Relations Metadata"): Boolean
    var
        RecRefCopy: RecordRef;
        FieldRef: FieldRef;
    begin
        // Copy the RecRef to a new instance to avoid changing the original RecRef and to be able to set the filters to the current record
        RecRefCopy := _RecRef.Duplicate();
        RecRefCopy.Reset(); // Reset the recordref to the primary key
        RecRefCopy.SetRecFilter(); // Set filters on the PK to only find the current record

        // Loop all conditions in this table relation (E.g. first Type=Item and then DocumentType <>Return&<>CreditMemo)
        _TableRelationsMetadata.SetRange("Field No.", _TableRelationsMetadata."Field No.");
        _TableRelationsMetadata.SetRange("Relation No.", _TableRelationsMetadata."Relation No.");
        repeat

            // Set condition filter from table relation condition
            if _TableRelationsMetadata."Condition Field No." <> 0 then begin
                FieldRef := RecRefCopy.Field(_TableRelationsMetadata."Condition Field No.");
                case _TableRelationsMetadata."Condition Type" of
                    _TableRelationsMetadata."Condition Type"::FILTER:
                        FieldRef.SetFilter(_TableRelationsMetadata."Condition Value");
                    _TableRelationsMetadata."Condition Type"::CONST:
                        FieldRef.SetRange(_TableRelationsMetadata."Condition Value");
                end;
            end;

        until _TableRelationsMetadata.Next() = 0;

        // Allow the outer loop to continue with the next table relation
        _TableRelationsMetadata.SetRange("Relation No.");
        _TableRelationsMetadata.SetRange("Field No.");

        // Check if the current record matches the conditions from the table relation
        exit(not RecRefCopy.IsEmpty());
    end;

    //
    // -------- Set/Get Helpers -------
    // 

    [Obsolete('Replaced by MobWmsMedia.GetItemImageID  (planned for removal 10/2026)', 'MOB5.47')]
    procedure GetItemImageID(_ItemNo: Code[20]): Text
    var
        MobWmsMedia: Codeunit "MOB WMS Media";
    begin
        exit(MobWmsMedia.GetItemImageID(_ItemNo));
    end;

    /// <summary>
    /// Determine the mobile "Status" symbol of an Order/Line (Locked/Has attachment SHARES symbol on mobile)
    /// NOTE: Locking takes precedense over Has Attachment
    /// 0 = Blank symbol (line)
    /// 1 = Not locked (order)
    /// 2 = Locked (order)
    /// 3 = Has Attachment (Order/Line)
    /// </summary>    
    procedure GetStatusCode(_BackendID: Code[40]; _RecRelatedVariantOrReferenceID: Variant) _ReturnStatusCode: Text
    var
        MobWmsOrderLocking: Codeunit "MOB WMS Order Locking";
        ReferenceID: Text;
    begin
        if _RecRelatedVariantOrReferenceID.IsRecord() or
           _RecRelatedVariantOrReferenceID.IsRecordId() or
           _RecRelatedVariantOrReferenceID.IsRecordRef()
        then
            ReferenceID := GetReferenceID(_RecRelatedVariantOrReferenceID)
        else
            ReferenceID := Format(_RecRelatedVariantOrReferenceID);

        // Default ReturnStatusCode '0' is overwritten to at least '1' in GetLockStatusCode() below whenever _BackendID is populated
        _ReturnStatusCode := '0';

        // Get document lock status
        if _BackendID <> '' then begin
            _ReturnStatusCode := MobWmsOrderLocking.GetLockStatusCode(_BackendID);

            // Locking trumps Attachment = exit if locked
            if _ReturnStatusCode = '2' then
                exit;
        end;

        // Document is not locked. Check for attachment
        if HasAttachment(ReferenceID) then
            _ReturnStatusCode := '3';
    end;

    /// <summary>
    /// Determine the mobile "Attachment" Code of an Order/Line
    /// 0 = Blank
    /// 1 = Attachment 
    /// </summary>    
    procedure GetAttachmentCode(_RecRelatedVariantOrReferenceID: Variant): Text
    var
        ReferenceID: Text;
    begin
        if _RecRelatedVariantOrReferenceID.IsRecord() or
           _RecRelatedVariantOrReferenceID.IsRecordId() or
           _RecRelatedVariantOrReferenceID.IsRecordRef()
        then
            ReferenceID := GetReferenceID(_RecRelatedVariantOrReferenceID)
        else
            ReferenceID := Format(_RecRelatedVariantOrReferenceID);

        if HasAttachment(ReferenceID) then
            exit('1')
        else
            exit('0');
    end;

    local procedure HasAttachment(_ReferenceID: Text): Boolean
    var
        MobWmsMedia: Codeunit "MOB WMS Media";
        ReferenceRecordId: RecordId;
    begin
        /// Determine the mobile "Attachment" symbol of an Order/Line
        if _ReferenceID = '' then
            exit(false);

        if not Evaluate(ReferenceRecordId, _ReferenceID) then
            exit(false);

        exit(MobWmsMedia.RecordIDHasAttachment(ReferenceRecordId));
    end;

    procedure GetReferenceID(_RecRelatedVariantOrText: Variant): Text
    begin
        if _RecRelatedVariantOrText.IsRecord() or
           _RecRelatedVariantOrText.IsRecordId() or
           _RecRelatedVariantOrText.IsRecordRef()
        then
            exit(MobToolbox.Variant2RecordID(_RecRelatedVariantOrText))
        else
            exit(Format(_RecRelatedVariantOrText));
    end;

    internal procedure GetSourceReferenceIDFromWhseShipmentLine(_WhseShipmentLine: Record "Warehouse Shipment Line"): Text
    var
        SalesHeader: Record "Sales Header";
        TransferHeader: Record "Transfer Header";
        ServiceHeader: Record "Service Header";
        PurchaseHeader: Record "Purchase Header";
    begin
        case _WhseShipmentLine."Source Document" of

            _WhseShipmentLine."Source Document"::"Sales Order":
                if SalesHeader.Get(SalesHeader."Document Type"::Order, _WhseShipmentLine."Source No.") then
                    exit(GetReferenceID(SalesHeader));

            _WhseShipmentLine."Source Document"::"Outbound Transfer":
                if TransferHeader.Get(_WhseShipmentLine."Source No.") then
                    exit(GetReferenceID(TransferHeader));

            _WhseShipmentLine."Source Document"::"Service Order":
                if ServiceHeader.Get(ServiceHeader."Document Type"::Order, _WhseShipmentLine."Source No.") then
                    exit(GetReferenceID(ServiceHeader));

            _WhseShipmentLine."Source Document"::"Purchase Return Order":
                if PurchaseHeader.Get(_WhseShipmentLine."Source Subtype", _WhseShipmentLine."Source No.") then
                    exit(GetReferenceID(PurchaseHeader));
        end;
    end;

    internal procedure GetSourceReferenceIDFromWhseReceiptLine(_WhseReceiptLine: Record "Warehouse Receipt Line"): Text
    var
        PurchaseHeader: Record "Purchase Header";
        TransferHeader: Record "Transfer Header";
    begin
        case _WhseReceiptLine."Source Document" of

            _WhseReceiptLine."Source Document"::"Purchase Order":
                if PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, _WhseReceiptLine."Source No.") then
                    exit(GetReferenceID(PurchaseHeader));

            _WhseReceiptLine."Source Document"::"Inbound Transfer":
                if TransferHeader.Get(_WhseReceiptLine."Source No.") then
                    exit(GetReferenceID(TransferHeader));
        end;
    end;


    procedure GetSourceReferenceIDFromWhseActivityLine(_WhseActLine: Record "Warehouse Activity Line"): Text
    var
        SalesHeader: Record "Sales Header";
        TransferHeader: Record "Transfer Header";
        PurchaseHeader: Record "Purchase Header";
    begin
        case _WhseActLine."Source Document" of

            _WhseActLine."Source Document"::"Sales Order":
                if SalesHeader.Get(_WhseActLine."Source Subtype", _WhseActLine."Source No.") then
                    exit(GetReferenceID(SalesHeader));

            _WhseActLine."Source Document"::"Outbound Transfer":
                if TransferHeader.Get(_WhseActLine."Source No.") then
                    exit(GetReferenceID(TransferHeader));

            _WhseActLine."Source Document"::"Purchase Return Order":
                if PurchaseHeader.Get(_WhseActLine."Source Subtype", _WhseActLine."Source No.") then
                    exit(GetReferenceID(PurchaseHeader));
        end;
    end;

    procedure SaveRegistrationData(_PostingMessageId: Guid; _XmlRequestDoc: XmlDocument; _RegistrationType: Enum "MOB WMS Registration Type") _OrderID: Code[20]
    var
        MobWmsRegistration: Record "MOB WMS Registration";
    begin
        exit(SaveRegistrationData(_PostingMessageId, _XmlRequestDoc, _RegistrationType, MobWmsRegistration));   // MobWmsRegistration is a non-temporary record -> Save to database
    end;

    procedure SaveRegistrationData(_PostingMessageId: Guid; _XmlRequestDoc: XmlDocument; _RegistrationType: Enum "MOB WMS Registration Type"; var _MobWmsRegistration: Record "MOB WMS Registration") _OrderID: Code[20]
    var
        MobSetup: Record "MOB Setup";
        InitialMobWmsRegistration: Record "MOB WMS Registration";
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        MobXmlMgt: Codeunit "MOB XML Management";
        MobWmsCount: Codeunit "MOB WMS Count";
        XmlRequestNode: XmlNode;
        XmlLineNodeList: XmlNodeList;
        XmlRequestDataNode: XmlNode;
        XmlOrderNode: XmlNode;
        XmlLineNode: XmlNode;
        XmlRegistrationNode: XmlNode;
        XmlRegistrationElementList: XmlNodeList;
        XmlRegistrationElementNode: XmlNode;
        XmlRegistrationNodeList: XmlNodeList;
        AttributeValue: Text[250];
        RawLotNumber: Code[50];
        RawSerialNumber: Code[50];
        WhseJnlBatchName: Code[10];
        WhseJnlBatchLocationCode: Code[10];
        i: Integer;
        j: Integer;
        k: Integer;
        l: Integer;
        BackendID: Text;
        LineNumber: Integer;
        PrefixedLineNo: Text[50];
        XmlExtraInfoElementList: XmlNodeList;
        XmlExtraInfoElementNode: XmlNode;
        NodeName: Text;
        ExtraInfoNodeName: Text;
        Prefix: Text[2];
        IsHandled: Boolean;
        OnApplyBackendId_IsHandled: Boolean;
        RegistrationWithLicensePlate: Boolean;
        RecordingNo: Integer;
        ProdOrderLineNo: Integer;
    begin
        // This function saves the registrations sent in from the mobile devices
        // in the Mobile WMS Registration table

        if IsNullGuid(_PostingMessageId) then
            Error(PostingMessageIdErr);

        // The requestData element only contains one Order element (validated by the schema), but may have other elements as well if sendRegistrationData="Order"|"OrderLine" was used from application.cfg
        if _RegistrationType <> _MobWmsRegistration.Type::CurrentRegistration then begin
            // <Order>-node is mandatory and with no other nodes at same level in the Xml file
            MobXmlMgt.GetDocRootNode(_XmlRequestDoc, XmlRequestNode);
            MobXmlMgt.FindNode(XmlRequestNode, 'requestData', XmlRequestDataNode);
            MobXmlMgt.GetNodeFirstChild(XmlRequestDataNode, XmlOrderNode);
        end else
            // <Order>-node not in the request if action adhocRegistration was used with sendRegistrationData="None"
            if not MobXmlMgt.GetXPathNode(_XmlRequestDoc, '//req:request/req:requestData/registrationData:Order', XmlOrderNode) then
                exit;

        // Get the order ID
        MobXmlMgt.GetAttribute(XmlOrderNode, 'backendID', AttributeValue);
        BackendID := AttributeValue;

        Clear(WhseJnlBatchLocationCode);    // Only populated for planned count from whse. jnl.
        Clear(ProdOrderLineNo);             // Only populated for production order consumption/output

        // Initialize record for event to allow customizing of the registration data
        InitialMobWmsRegistration.Init();
        InitialMobWmsRegistration."Posting MessageId" := _PostingMessageId;
        InitialMobWmsRegistration.Type := _RegistrationType;

        // Event to decode the BackendID for custom registration types and set the Order No. and any custom fields for later processing.
        // Called with an initialized record where only the Type and Posting MessageId fields are filled to determine if and how subscribers wish to handle the decoding.
        // Only "Order ID" and custom fields are used from the subscribers - the rest will be ignored .
        OnApplyBackendId_IsHandled := false;
        OnSaveRegistrationData_OnApplyBackendId(BackendID, InitialMobWmsRegistration, OnApplyBackendId_IsHandled);
        if not OnApplyBackendId_IsHandled then
            case _RegistrationType of
                _MobWmsRegistration.Type::"Sales Order", _MobWmsRegistration.Type::"Purchase Order",
                _MobWmsRegistration.Type::"Sales Return Order", _MobWmsRegistration.Type::"Purchase Return Order",
                _MobWmsRegistration.Type::"Transfer Order":
                    _OrderID := CopyStr(AttributeValue, 4, StrLen(AttributeValue));
                _MobWmsRegistration.Type::"Phys. Invt. Recording":
                    GetOrderNoAndRecordingNoFromBackendId(AttributeValue, _OrderID, RecordingNo);
                _MobWmsRegistration.Type::"Production Consumption":
                    GetOrderNoAndOrderLineNoFromBackendId(AttributeValue, _OrderID, ProdOrderLineNo);
                _MobWmsRegistration.Type::"Count":
                    begin
                        Prefix := CopyStr(AttributeValue, 1, 2);
                        if Prefix = MobWmsCount."CONST::WarehouseJournalPrefix"() then begin
                            GetWhseJnlBatchNameAndLocationCodeFromBackendID(AttributeValue, WhseJnlBatchName, WhseJnlBatchLocationCode);
                            _OrderID := MobWmsCount."CONST::WarehouseJournalPrefix"() + WhseJnlBatchName;
                        end else
                            _OrderID := AttributeValue;
                    end;
                else
                    _OrderID := AttributeValue;
            end
        else
            _OrderID := InitialMobWmsRegistration."Order No.";

        // Save the values from the XML in the Mobile WMS Registration table
        // Loop through the <Line> elements
        MobXmlMgt.GetNodeChildNodes(XmlOrderNode, XmlLineNodeList);

        for i := 1 to XmlLineNodeList.Count() do begin
            MobXmlMgt.GetListItem(XmlLineNodeList, XmlLineNode, (i)); // AL = 1 based index

            // Only perform following code if Element is Line
            if MobXmlMgt.GetNodeName(XmlLineNode) = 'Line' then begin

                // Get the line number
                MobXmlMgt.GetAttribute(XmlLineNode, 'lineNumber', AttributeValue);
                PrefixedLineNo := AttributeValue;

                LineNumber := EvaluateLineNumber(BackendID, PrefixedLineNo);

                // Loop through the <Registration> elements
                MobXmlMgt.GetNodeChildNodes(XmlLineNode, XmlRegistrationNodeList);

                for j := 1 to XmlRegistrationNodeList.Count() do begin

                    MobXmlMgt.GetListItem(XmlRegistrationNodeList, XmlRegistrationNode, (j)); // AL = 1 based index

                    // Create a registration line for each registration
                    _MobWmsRegistration := InitialMobWmsRegistration;

                    _MobWmsRegistration."Order No." := _OrderID;
                    _MobWmsRegistration."Phys. Invt. Recording No." := RecordingNo;
                    _MobWmsRegistration."Line No." := LineNumber;
                    _MobWmsRegistration."Prefixed Line No." := PrefixedLineNo;
                    Clear(_MobWmsRegistration."Registration No.");   // Auto increment (existing value must be cleared)
                    _MobWmsRegistration."Whse. Jnl. Batch Location Code" := WhseJnlBatchLocationCode;    // Only populated for planned count from whse. journal
                    _MobWmsRegistration."Prod. Order Line No." := ProdOrderLineNo;

                    // Save entire Registration-node as XML so custom values that are not saved in DB can be accessed
                    _MobWmsRegistration.SetRegistrationXml(XmlRegistrationNode);

                    // Get the Timestamp and scanned value if it exists
                    MobXmlMgt.GetAttribute(XmlRegistrationNode, 'created', AttributeValue);
                    Evaluate(_MobWmsRegistration.RegistrationCreated, AttributeValue, 9);
                    if MobXmlMgt.GetAttribute(XmlRegistrationNode, 'lineSelectionValue', AttributeValue) then
                        _MobWmsRegistration.LineSelectionValue := AttributeValue;

                    // Loop through the registration elements
                    MobXmlMgt.GetNodeChildNodes(XmlRegistrationNode, XmlRegistrationElementList);
                    for k := 1 to XmlRegistrationElementList.Count() do begin

                        MobXmlMgt.GetListItem(XmlRegistrationElementList, XmlRegistrationElementNode, (k));  // AL = 1 based index

                        IsHandled := false;
                        NodeName := MobXmlMgt.GetNodeName(XmlRegistrationElementNode);
                        if NodeName <> 'ExtraInfo' then
                            OnSaveRegistrationValue(NodeName, MobXmlMgt.GetNodeInnerText(XmlRegistrationElementNode), _MobWmsRegistration, IsHandled);

                        if not IsHandled then
                            case NodeName of

                                'FromBin':
                                    _MobWmsRegistration.FromBin := MobToolbox.ReadBin(MobXmlMgt.GetNodeInnerText(XmlRegistrationElementNode));
                                'ToBin':
                                    _MobWmsRegistration.ToBin := MobToolbox.ReadBin(MobXmlMgt.GetNodeInnerText(XmlRegistrationElementNode));
                                'SerialNumber':
                                    begin
                                        MobWmsToolbox.ExtractSerialAndExpirationDate(MobXmlMgt.GetNodeInnerText(XmlRegistrationElementNode), RawSerialNumber, _MobWmsRegistration."Expiration Date");
                                        _MobWmsRegistration.SerialNumber := MobToolbox.ReadSerial(RawSerialNumber);
                                    end;
                                'LotNumber':
                                    begin
                                        MobWmsToolbox.ExtractLotAndExpirationDate(MobXmlMgt.GetNodeInnerText(XmlRegistrationElementNode), RawLotNumber, _MobWmsRegistration."Expiration Date");
                                        _MobWmsRegistration.LotNumber := MobToolbox.ReadLot(RawLotNumber);
                                    end;
                                // 'PackageNumber' is saved from OnSaveRegistrationValue when MobPackageManagement.IsEnabled()
                                'Quantity':
                                    Evaluate(_MobWmsRegistration.Quantity, MobXmlMgt.GetNodeInnerText(XmlRegistrationElementNode), 9);
                                'UnitOfMeasure':
                                    _MobWmsRegistration.UnitOfMeasure := MobXmlMgt.GetNodeInnerText(XmlRegistrationElementNode);
                                'ActionType':
                                    _MobWmsRegistration.ActionType := MobXmlMgt.GetNodeInnerText(XmlRegistrationElementNode);
                                'ToteId':
                                    begin
                                        RegistrationWithLicensePlate := true;
                                        _MobWmsRegistration."Tote ID" := MobXmlMgt.GetNodeInnerText(XmlRegistrationElementNode);

                                        // Set the License Plate No. to the Tote ID
                                        // Note that the "License Plate No." can be changed later in the ExtraInfo section below
                                        if StrLen(_MobWmsRegistration."Tote ID") <= MaxStrLen(_MobWmsRegistration."License Plate No.") then
                                            _MobWmsRegistration."License Plate No." := _MobWmsRegistration."Tote ID";
                                    end;
                                'LicensePlate':
                                    begin
                                        RegistrationWithLicensePlate := true;
                                        _MobWmsRegistration."License Plate No." := MobXmlMgt.GetNodeInnerText(XmlRegistrationElementNode);
                                    end;
                                'ExtraInfo':
                                    begin
                                        // Write the code to extract the extra info from the registration and save it
                                        // Add new fields to the table to support this
                                        // Each piece of extra information is stored in a elements below the <ExtraInfo> element

                                        MobXmlMgt.GetNodeChildNodes(XmlRegistrationElementNode, XmlExtraInfoElementList);

                                        for l := 1 to XmlExtraInfoElementList.Count() do begin

                                            MobXmlMgt.GetListItem(XmlExtraInfoElementList, XmlExtraInfoElementNode, (l)); // AL = 1 based index

                                            // The registration type was not part of the standard solution -> see if a customization exists
                                            IsHandled := false;
                                            ExtraInfoNodeName := MobXmlMgt.GetNodeName(XmlExtraInfoElementNode);

                                            // To License Plate No. is only available in the ExtraInfo section of the XML
                                            if ExtraInfoNodeName = 'LicensePlate' then
                                                _MobWmsRegistration."License Plate No." := MobXmlMgt.GetNodeInnerText(XmlExtraInfoElementNode);

                                            // From License Plate No. is only available in the ExtraInfo section of the XML                                            
                                            if ExtraInfoNodeName = 'FromLicensePlate' then
                                                _MobWmsRegistration."From License Plate No." := MobXmlMgt.GetNodeInnerText(XmlExtraInfoElementNode);

                                            OnSaveRegistrationValue(ExtraInfoNodeName, MobXmlMgt.GetNodeInnerText(XmlExtraInfoElementNode), _MobWmsRegistration, IsHandled);

                                            // Intentionally no error XML_UNKNOWN_ELEMENT : It is no longer mandatory so save custom values as RegistrationData-fields
                                        end;

                                        _MobWmsRegistration.ExtraInfo := true;
                                    end;
                                else
                                    Error(MobWmsLanguage.GetMessage('XML_UNKNOWN_ELEMENT'), 'OnSaveRegistrationData::' + MobXmlMgt.GetNodeName(XmlRegistrationElementNode));
                            end;  // case

                    end;  // for

                    // Update the registration with additional source information
                    UpdateWmsRegistrationWithSourceInformation(_MobWmsRegistration);

                    // Tote-handle pick lines for Production Lines or Assembly Lines not meant for a sales order (Assemble-to-Order) as these are not "Tote-shipped"
                    if (_MobWmsRegistration."Tote ID" <> '') and (_MobWmsRegistration."Whse. Document Type" <> _MobWmsRegistration."Whse. Document Type"::Shipment) then
                        _MobWmsRegistration."Tote Handled" := true;

                    // Insert the registration
                    _MobWmsRegistration.Insert(true);

                end;  // Registration loop

            end;

        end;  // Line loop

        // Ensure License Plating is not used when receiving without a Warehouse Receipt
        if RegistrationWithLicensePlate and (_MobWmsRegistration.Type in
            [_MobWmsRegistration.Type::"Purchase Order",
             _MobWmsRegistration.Type::"Transfer Order",
             _MobWmsRegistration.Type::"Sales Return Order"])
         then
            Error(InvalidLicensePlaceUsageErr);

        // Ensure License Plating is enabled if receiveing with license plate(s)
        if RegistrationWithLicensePlate and (_MobWmsRegistration.Type = _MobWmsRegistration.Type::Receive) then
            MobSetup.CheckLicensePlatingIsEnabled();

        // Move to first record in case of temporary use (Used by API Events that expose the table or Adhoc with mobile config "sendRegistrationData"="Order"|"OrderLine") 
        if (_RegistrationType = _MobWmsRegistration.Type::CurrentRegistration) and (_MobWmsRegistration.IsTemporary()) then
            if _MobWmsRegistration.FindFirst() then; // Success/failure doesn't require further action

    end;

    /// <summary>
    /// Update the registration data with additional Source information
    /// </summary>
    local procedure UpdateWmsRegistrationWithSourceInformation(var _MobWmsRegistration: Record "MOB WMS Registration")
    var
        WhseActLine: Record "Warehouse Activity Line";
        WhseReceiptLine: Record "Warehouse Receipt Line";
    begin
        // Get Whse. Document Information from Receipt
        if _MobWmsRegistration.Type = _MobWmsRegistration.Type::Receive then begin
            WhseReceiptLine.SetRange("No.", _MobWmsRegistration."Order No.");
            WhseReceiptLine.SetRange("Line No.", _MobWmsRegistration."Line No.");
            if WhseReceiptLine.FindFirst() then begin
                _MobWmsRegistration."Source Type" := WhseReceiptLine."Source Type";
                _MobWmsRegistration."Source No." := WhseReceiptLine."Source No.";
                _MobWmsRegistration."Source Line No." := WhseReceiptLine."Source Line No.";
                _MobWmsRegistration."Source Document" := MobToolbox.AsInteger(WhseReceiptLine."Source Document");
                _MobWmsRegistration."Whse. Document Type" := _MobWmsRegistration."Whse. Document Type"::Receipt;
                _MobWmsRegistration."Whse. Document No." := WhseReceiptLine."No.";
                _MobWmsRegistration."Whse. Document Line No." := WhseReceiptLine."Line No.";
            end;
        end;

        // Get Whse. Document Information
        if _MobWmsRegistration.Type = _MobWmsRegistration.Type::Pick then begin
            WhseActLine.SetRange("Activity Type", WhseActLine."Activity Type"::Pick);
            WhseActLine.SetRange("No.", _MobWmsRegistration."Order No.");
            WhseActLine.SetRange("Line No.", _MobWmsRegistration."Line No.");
            if WhseActLine.FindFirst() then begin
                _MobWmsRegistration."Source Type" := WhseActLine."Source Type";
                _MobWmsRegistration."Source No." := WhseActLine."Source No.";
                _MobWmsRegistration."Source Line No." := WhseActLine."Source Line No.";
                _MobWmsRegistration."Source Document" := MobToolbox.AsInteger(WhseActLine."Source Document");
                _MobWmsRegistration."Destination Type" := MobToolbox.AsInteger(WhseActLine."Destination Type");
                _MobWmsRegistration."Destination No." := WhseActLine."Destination No.";
                _MobWmsRegistration."Whse. Document Type" := MobToolbox.AsInteger(WhseActLine."Whse. Document Type");
                _MobWmsRegistration."Whse. Document No." := WhseActLine."Whse. Document No.";
                _MobWmsRegistration."Whse. Document Line No." := WhseActLine."Whse. Document Line No.";
            end;
        end;
    end;

    /// <summary>
    /// Gets LineNumber including handling any prefix
    /// Used from Planned and Whse. Inquiry
    /// </summary>
    internal procedure EvaluateLineNumber(_OrderBackendID: Text; _Value: Text) ReturnLineNo: Integer
    var
        PrefixedLineNo: Text;
    begin
        // Sales Order Pick & Transfer
        // Line no is prefixed when integrating directly to Sales/Transfer Orders (OrderBackendID contains 'SO-' or 'TO-')
        // Example: <lineNumber>10010000</lineNumber>
        if CopyStr(_OrderBackendID, 1, 3) in ['SO-', 'TO-'] then begin
            PrefixedLineNo := _Value;
            _Value := DelStr(_Value, 1, 3);
        end;

        // Whse. Pick & Ship
        // Line is prefixed when picking/shipping both reserved and tracked Items without Warehouse Tracking 
        // If Line No starts with a P, we know it's not NAV (and it's been prefixed with P001, P002 .. P999)
        // Example: <lineNumber>P00010000</lineNumber>
        if CopyStr(_Value, 1, 1) = 'P' then begin
            PrefixedLineNo := _Value;
            _Value := DelStr(_Value, 1, 4);
        end;

        // Production & Assembly
        // Line No consist of two parts in format "XXXXX - Y", X is linenumber and Y is prefix (really postfix)
        // Example: <lineNumber>110000 - 0</lineNumber>
        if StrPos(_Value, ' - ') <> 0 then begin
            PrefixedLineNo := _Value;
            _Value := CopyStr(_Value, 1, (StrPos(_Value, ' - ') - 1));
        end;

        Evaluate(ReturnLineNo, _Value);
    end;

    /// <summary>
    /// Add additional registration data directly from from source record, not mobile request
    /// </summary>
    procedure SaveRegistrationDataFromSource(_LocationCode: Code[10]; _ItemNo: Code[20]; _VariantCode: Code[20]; var _MobWmsRegistration: Record "MOB WMS Registration")
    begin
        _MobWmsRegistration."Location Code" := _LocationCode;
        _MobWmsRegistration."Item No." := _ItemNo;
        _MobWmsRegistration."Variant Code" := _VariantCode;
    end;

    /// <summary>
    /// Clean up MobileWmsRegistrations with specified _PostingMessageId for when posting fails (Tote shipping can not distinguish posted/not-posted handled registrations)
    /// Also used when deleting a document queue entry and before processing a request
    /// </summary>
    procedure DeleteRegistrationData(_PostingMessageId: Guid)
    var
        MobWmsRegistration: Record "MOB WMS Registration";
    begin
        if not IsNullGuid(_PostingMessageId) then begin
            MobWmsRegistration.SetCurrentKey("Posting MessageId");
            MobWmsRegistration.SetRange("Posting MessageId", _PostingMessageId);
            if not MobWmsRegistration.IsEmpty() then
                MobWmsRegistration.DeleteAll(true);
        end;
    end;

    /// <summary>
    /// Save entire Liveupdate request (RegisterRealtimeQuantity)
    /// Liveupdate request is almost like a Planned post request
    /// But with "itemNumber" and "clearOrderLines" attributes
    /// </summary>

    procedure SaveRealtimeRegistrationData(_XmlRequestDoc: XmlDocument; _DeviceID: Code[200]; _MobileUserID: Code[50]; var _IsClearOrderLines: Boolean; var _RealtimeRegistrations: Record "MOB Realtime Reg Qty.")
    var
        MobWmsLanguage: Codeunit "MOB WMS Language";
        MobXmlMgt: Codeunit "MOB XML Management";
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
        XmlOrderNode: XmlNode;
        XmlLineNode: XmlNode;
        XmlRegistrationNode: XmlNode;
        XmlRegistrationElementList: XmlNodeList;
        XmlRegistrationElementNode: XmlNode;
        XmlRegistrationNodeList: XmlNodeList;
        XmlExtraInfoElementList: XmlNodeList;
        XmlExtraInfoElementNode: XmlNode;
        AttributeValue: Text;
        i: Integer;
        j: Integer;
        k: Integer;
        LineNumber: Code[20];
        OrderType: Code[20];
        BackendID: Code[30];
        ItemNumber: Code[20];
        IsHandled: Boolean;
        NodeName: Text;
        NodeValue: Code[70];
        RawLotNumber: Code[50];
        RawSerialNumber: Code[50];
    begin
        // The Request Document looks like this (Similar to Planned Post)

        // <?xml version="1.0" encoding="utf-8"?>
        // <request name="RegisterRealtimeQuantity" created="2021-01-08T15:19:58+01:00" xmlns="http://schemas.microsoft.com/Dynamics/Mobile/2007/04/Documents/Request">
        //   <requestData name="RegisterRealtimeQuantity">
        //     <Order backendID="PI000003" orderType="Pick" xmlns="http://schemas.taskletfactory.com/MobileWMS/RegistrationData">
        //       <Line lineNumber="30000" itemNumber="TF-003">
        //         <Registration created="2021-01-08T15:19:27+01:00" xmlns="">
        //           <ActionType>TAKE</ActionType>
        //           <FromBin>W-01-0001</FromBin>
        //           <ToBin>W-09-0001</ToBin>
        //           <LotNumber>a</LotNumber>
        //           <SerialNumber />
        //           <Quantity>3</Quantity>
        //           <UnitOfMeasure>PCS</UnitOfMeasure>
        //         </Registration>
        //         <Registration created="2021-01-08T15:19:43+01:00" xmlns="">
        //           <ActionType>TAKE</ActionType>
        //           <FromBin>W-01-0001</FromBin>
        //           <ToBin>W-09-0001</ToBin>
        //           <LotNumber>b</LotNumber>
        //           <SerialNumber />
        //           <Quantity>2</Quantity>
        //           <UnitOfMeasure>PCS</UnitOfMeasure>
        //         </Registration>
        //       </Line>
        //     </Order>
        //   </requestData>
        // </request>


        XmlOrderNode := MobRequestMgt.GetOrderNode(_XmlRequestDoc);
        MobXmlMgt.GetAttribute(XmlOrderNode, 'backendID', AttributeValue);
        BackendID := AttributeValue;
        MobXmlMgt.GetAttribute(XmlOrderNode, 'orderType', AttributeValue);
        OrderType := AttributeValue;

        // -- Request is "ClearOrderLines"
        if MobXmlMgt.GetAttribute(XmlOrderNode, 'clearOrderLines', AttributeValue) then
            _IsClearOrderLines := MobToolbox.Text2Boolean(AttributeValue);

        if _IsClearOrderLines then begin
            // Save as single record so handle knows what Order to delete
            _RealtimeRegistrations."Device ID" := _DeviceID;
            _RealtimeRegistrations.Type := OrderType;
            _RealtimeRegistrations."Order No." := BackendID;
            _RealtimeRegistrations.Insert(true);
            exit;
        end;


        // -- Request is LiveUpdate Quantities
        MobXmlMgt.GetNodeFirstChild(XmlOrderNode, XmlLineNode);

        MobXmlMgt.GetAttribute(XmlLineNode, 'lineNumber', AttributeValue);
        LineNumber := AttributeValue;
        MobXmlMgt.GetAttribute(XmlLineNode, 'itemNumber', AttributeValue);
        ItemNumber := AttributeValue;

        // Get Registration elements
        MobXmlMgt.GetNodeChildNodes(XmlLineNode, XmlRegistrationNodeList);

        // -- No registrations = Delete everything for this single line
        if XmlRegistrationNodeList.Count() = 0 then begin
            // Save as single record so handle knows what Order Line to delete
            _RealtimeRegistrations."Device ID" := _DeviceID;
            _RealtimeRegistrations.Type := OrderType;
            _RealtimeRegistrations."Order No." := BackendID;
            _RealtimeRegistrations."Line No." := LineNumber;
            _RealtimeRegistrations.Insert(true);
            exit;
        end;

        // -- Loop line registrations
        for i := 1 to XmlRegistrationNodeList.Count() do begin
            MobXmlMgt.GetListItem(XmlRegistrationNodeList, XmlRegistrationNode, i);
            _RealtimeRegistrations."Device ID" := _DeviceID;
            _RealtimeRegistrations.Type := OrderType;
            _RealtimeRegistrations."Order No." := BackendID;
            _RealtimeRegistrations."Line No." := LineNumber;
            _RealtimeRegistrations."Item No." := ItemNumber;
            _RealtimeRegistrations."Mobile User ID" := _MobileUserID;
            _RealtimeRegistrations."Registration No." := i; // Temporary table does not support Autoincrement

            // Save entire node as XML so custom values that are not saved in DB can be accessed
            _RealtimeRegistrations.SetRegistrationXml(XmlRegistrationNode);

            MobXmlMgt.GetNodeChildNodes(XmlRegistrationNode, XmlRegistrationElementList);
            for j := 1 to XmlRegistrationElementList.Count() do begin

                MobXmlMgt.GetListItem(XmlRegistrationElementList, XmlRegistrationElementNode, j);

                // -- Event
                IsHandled := false;
                NodeName := MobXmlMgt.GetNodeName(XmlRegistrationElementNode);
                if NodeName <> 'ExtraInfo' then
                    OnSaveRealtimeRegistrationValue(NodeName, MobXmlMgt.GetNodeInnerText(XmlRegistrationElementNode), _RealtimeRegistrations, IsHandled);

                if not IsHandled then
                    case NodeName of
                        'FromBin':
                            _RealtimeRegistrations.FromBin := MobXmlMgt.GetNodeInnerText(XmlRegistrationElementNode);
                        'ToBin':
                            _RealtimeRegistrations.ToBin := MobXmlMgt.GetNodeInnerText(XmlRegistrationElementNode);
                        'SerialNumber':
                            begin
                                NodeValue := MobXmlMgt.GetNodeInnerText(XmlRegistrationElementNode);

#pragma warning disable AL0432
                                _RealtimeRegistrations.SerialNumber := NodeValue;
#pragma warning restore AL0432

                                MobWmsToolbox.ExtractSerialAndExpirationDate(NodeValue, RawSerialNumber, _RealtimeRegistrations."Expiration Date");
                                _RealtimeRegistrations."Serial No." := MobToolbox.ReadSerial(RawSerialNumber);
                            end;
                        'LotNumber':
                            begin
                                NodeValue := MobXmlMgt.GetNodeInnerText(XmlRegistrationElementNode);

#pragma warning disable AL0432
                                _RealtimeRegistrations.LotNumber := NodeValue;
#pragma warning restore AL0432

                                MobWmsToolbox.ExtractLotAndExpirationDate(NodeValue, RawLotNumber, _RealtimeRegistrations."Expiration Date");
                                _RealtimeRegistrations."Lot No." := MobToolbox.ReadLot(RawLotNumber);
                            end;
                        'Quantity':
                            Evaluate(_RealtimeRegistrations.Quantity, MobXmlMgt.GetNodeInnerText(XmlRegistrationElementNode), 9);
                        'UnitOfMeasure':
                            _RealtimeRegistrations.UnitOfMeasure := MobXmlMgt.GetNodeInnerText(XmlRegistrationElementNode);
                        'ActionType':
                            _RealtimeRegistrations.ActionType := MobXmlMgt.GetNodeInnerText(XmlRegistrationElementNode);
                        'ToteId':
                            _RealtimeRegistrations."Tote ID" := MobXmlMgt.GetNodeInnerText(XmlRegistrationElementNode);
                        'ExtraInfo':
                            begin
                                // Write the code to extract the extra info from the registration and save it
                                // Add new fields to the table to support this
                                // Each piece of extra information is stored in a elements below the <ExtraInfo> element

                                MobXmlMgt.GetNodeChildNodes(XmlRegistrationElementNode, XmlExtraInfoElementList);

                                for k := 1 to XmlExtraInfoElementList.Count() do begin

                                    MobXmlMgt.GetListItem(XmlExtraInfoElementList, XmlExtraInfoElementNode, (k)); // AL = 1 based index

                                    // -- Event
                                    // The registration type was not part of the standard solution -> see if a customization exists
                                    IsHandled := false;
                                    OnSaveRealtimeRegistrationValue(MobXmlMgt.GetNodeName(XmlExtraInfoElementNode), MobXmlMgt.GetNodeInnerText(XmlExtraInfoElementNode), _RealtimeRegistrations, IsHandled);
                                end;
                            end;
                        else
                            Error(MobWmsLanguage.GetMessage('XML_UNKNOWN_ELEMENT'), 'OnSaveRegistrationData::' + MobXmlMgt.GetNodeName(XmlRegistrationElementNode));
                    end;
            end;
            _RealtimeRegistrations.Insert(true);
        end;
    end;

    /// <summary>
    /// Get Order No. and Recording No. from 'BackendID'
    /// </summary>
    procedure GetOrderNoAndRecordingNoFromBackendId(_BackendID: Code[40]; var _OrderNo: Code[20]; var _RecordingNo: Integer)
    var
        Pos: Integer;
    begin
        Pos := StrPos(_BackendID, '-');

        if Pos > 0 then begin
            _OrderNo := CopyStr(_BackendID, Pos + 1);
            Evaluate(_RecordingNo, CopyStr(_BackendID, 1, Pos - 1));
        end else
            _OrderNo := _BackendID;
    end;

    /// <summary>
    /// Get Order No. and Line No. 'BackendID'
    /// Line. No. is before Order No. to avoid issues if Order No. includes ":" and to easier distinguish from displayed HeaderValue1 (ie. 104101 - 10000)
    /// </summary>
    procedure GetOrderNoAndOrderLineNoFromBackendId(_BackendID: Code[40]; var _OrderNo: Code[20]; var _OrderLineNo: Integer)
    var
        PartsList: List of [Text];
        PartText: Text;
        i: Integer;
    begin
        PartsList := Format(_BackendID).Split(' - ');

        Clear(_OrderNo);
        for i := 1 to (PartsList.Count() - 1) do begin // May have more than total two parts if OrderNo included " - "
            PartsList.Get(i, PartText);
            if _OrderNo = '' then
                _OrderNo := PartText
            else
                _OrderNo := _OrderNo + ' - ' + PartText;
        end;

        PartsList.Get(i + 1, PartText); // Last part
        Evaluate(_OrderLineNo, PartText);
    end;

    /// <summary>
    /// Get Whse. Batch Name and Location Code from 'BackendID'
    /// </summary>
    procedure GetWhseJnlBatchNameAndLocationCodeFromBackendID(_BackendID: Code[40]; var _BatchName: Code[10]; var _LocationCode: Code[10])
    begin
        // _BackendID contains prefix, batch name and location code in the following format (W-DEFAULT   WHITE)
        _BackendID := CopyStr(_BackendID, 3);
        _BatchName := CopyStr(_BackendID, 1, 10); // Because the Code datatype doesn't allow trailing spaces inputting 'DEFAULT   ' into _BatchName will become 'DEFAULT'
        _LocationCode := CopyStr(_BackendID, 11);
    end;

    //
    // ------- TEXT MGT -------
    //

    procedure Bool2Text(_Boolean: Boolean): Text[5]
    begin
        // Converts boolean to 'true' / 'false' as used in Xml files
        if _Boolean then
            exit('true')
        else
            exit('false');
    end;

    /// <summary>
    /// Convert Boolean to Text in Mobile Display format (Mobile user language format)
    /// </summary>    
    procedure Bool2TextAsDisplayFormat(_Boolean: Boolean): Text
    var
        MobWmsLanguage: Codeunit "MOB WMS Language";
    begin
        if _Boolean = true then
            exit(MobWmsLanguage.GetMessage('YES'))
        else
            exit(MobWmsLanguage.GetMessage('NO'));
    end;

    /// <summary>
    /// Convert Decimal to Text in Mobile Display format (Mobile user language format)
    /// </summary>    
    procedure Decimal2TextAsDisplayFormat(_Decimal: Decimal; _BlankZero: Boolean): Text
    begin
        exit(MobTypeHelper.FormatDecimalAsLanguage(_Decimal, _BlankZero, MobDeviceManagement.GetDeviceLanguageId()));
    end;

    /// <summary>
    /// Convert Decimal to Text in Mobile Display format (Mobile user language format)
    /// </summary>
    procedure Decimal2TextAsDisplayFormat(_Decimal: Decimal): Text
    begin
        exit(Decimal2TextAsDisplayFormat(_Decimal, false));
    end;

    /// <summary>
    /// Converts Date to Sql sort order Code (format by YYYYMMDD)
    /// </summary>
    procedure Date2Sorting(_Date: Date): Code[250]
    begin
        exit(MobTypeHelper.FormatDateAsYYYYMMDD(_Date));
    end;

    /// <summary>
    /// Converts Date to Text in Xml Format (format by YYYY-MM-DD)
    /// </summary>
    procedure Date2TextAsXmlFormat(_Date: Date): Text
    begin
        exit(Format(_Date, 0, 9));  // 9 = Xml format
    end;

    /// <summary>
    /// Convert Date to Text in Mobile Display format (Mobile user language format)
    /// </summary>    
    procedure Date2TextAsDisplayFormat(_Date: Date): Text
    begin
        exit(MobTypeHelper.FormatDateAsLanguage(_Date, MobDeviceManagement.GetDeviceLanguageId()));
    end;

    /// <summary>
    /// Convert DateTime to Text in Mobile Display format (Mobile user language format)
    /// </summary>    
    procedure DateTime2TextAsDisplayFormat(_DateTime: DateTime): Text
    begin
        exit(MobTypeHelper.FormatDateTimeAsLanguage(_DateTime, MobDeviceManagement.GetDeviceLanguageId()));
    end;

    /// <summary>
    /// Converts Decimal to Text in Xml Format
    /// </summary>
    procedure Decimal2TextAsXmlFormat(_Decimal: Decimal): Text
    begin
        exit(Format(_Decimal, 0, 9));  // 9 = Xml format
    end;

    /// <summary>
    /// Converts Integer to Text in Xml Format
    /// </summary>
    procedure Integer2TextAsXmlFormat(_Integer: Integer): Text
    begin
        exit(Format(_Integer, 0, 9));  // 9 = Xml format
    end;

    /// <summary>
    /// Converts Integer to Sql sort order Code (padding with leading 0's)
    /// </summary>
    procedure Int2Sorting(_Int: Integer; _MaxStrLen: Integer): Code[250]
    var
        NewCode: Code[250];
    begin
        NewCode := (Format(_Int, 0, 9));
        NewCode := PadStr('', _MaxStrLen - StrLen(NewCode), '0') + NewCode;  // intentionally fails if strlen(_int) > _maxstrlen
        exit(NewCode);
    end;

    /// <summary>
    /// Converts List of [Text] to textstring with up to _MaxLines separated by _Separator. 
    /// If too many lines in list the excess list elements is returned as i.e. [+3] at last line / end of string.
    /// </summary>
    procedure List2Text(_List: List of [Text]; _MaxNoOfLines: Integer; _Separator: Text) _CombinedText: Text
    var
        Idx: Integer;
        MaxIdx: Integer;
    begin
        Clear(_CombinedText);

        MaxIdx := _List.Count();

        if (_MaxNoOfLines = 1) and (MaxIdx >= 1) then
            exit(_List.Get(1));

        Idx := 1;
        for Idx := 1 to MaxIdx do begin
            if (Idx > _MaxNoOfLines) and (_MaxNoOfLines <> 0) then
                exit(_CombinedText);

            if (Idx > 1) then
                _CombinedText := _CombinedText + _Separator;

            if (Idx = _MaxNoOfLines) and (Idx < MaxIdx) then begin
                _CombinedText := _CombinedText + StrSubstNo('[+%1]', MaxIdx - Idx + 1); // No of lines not shown is current + whatever comes after
                exit(_CombinedText);
            end;

            _CombinedText := _CombinedText + _List.Get(Idx);
        end;
    end;

    /// <summary>
    /// Converts List of [Text] to \r\n separated textstring with up to _MaxLines. If too many lines in list the excess list elements is returned as i.e. [+3] at last line of string.
    /// </summary>
    procedure List2TextLn(_List: List of [Text]; _MaxNoOfLines: Integer) _CombinedText: Text
    var
        LF: Char;
    begin
        LF := 10;
        exit(List2Text(_List, _MaxNoOfLines, LF));
    end;

    /// <summary>
    /// Trim blank lines in list (trailing blanks prior to inside blanks)
    /// </summary>
    procedure ListTrimBlank(var _List: List of [Text]; _MinNoOfLines: Integer)
    var
        i: Integer;
        RemoveLine: Boolean;
    begin
        repeat
            i := _List.LastIndexOf('');
            RemoveLine := (_List.Count() > _MinNoOfLines) and (i <> 0);
            if RemoveLine then
                _List.RemoveAt(i);
        until not RemoveLine;
    end;

    //
    // ------- CONSTANTS -------
    //

    procedure "WhseActType::Invt. Movement"(): Integer
    begin
        exit(6);
    end;

    procedure "CONST::UnplannedMove"(): Text
    begin
        exit(UnplannedMoveTok);
    end;

    procedure "CONST::UnplannedMoveAdvanced"(): Text
    begin
        exit(UnplannedMoveAdvancedTok);
    end;

    procedure "CONST::RegisterPutAwayLicensePlate"(): Text
    begin
        exit(RegisterPutAwayLicensePlateTok);
    end;

    procedure "CONST::PrintLicensePlate"(): Text
    begin
        exit(PrintLicensePlateTok);
    end;

    procedure "CONST::UnplannedCount"(): Text
    begin
        exit(UnplannedCountTok);
    end;

    procedure "CONST::AdjustQuantity"(): Text
    begin
        exit(AdjustQuantityTok);
    end;

    procedure "CONST::ItemCrossReference"(): Text
    begin
        exit(ItemCrossReferenceTok);
    end;

    procedure "CONST::AddCountLine"(): Text
    begin
        exit(AddCountLineTok);
    end;

    procedure "CONST::ItemDimensions"(): Text
    begin
        exit(ItemDimensionsTok);
    end;

    procedure "CONST::ToteShipping"(): Text
    begin
        exit(ToteShippingTok);
    end;

    procedure "CONST::PrintLabelTemplate"(): Text
    begin
        exit(PrintLabelTemplateTok);
    end;

    procedure "CONST::BulkMove"(): Text
    begin
        exit(BulkMoveTok);
    end;

    procedure "CONST::requestData"(): Text
    begin
        exit(RequestDataTok);
    end;

    procedure "CONST::PostShipment"(): Text
    begin
        exit(PostShipmentTok);
    end;

    procedure "CONST::Internal"(): Text
    begin
        exit(InternalTok);
    end;

    procedure "CONST::StartNewLicensePlate"(): Text
    begin
        exit(StartNewLicensePlateTok);
    end;

    procedure "CONST::RegisterItemImage"(): Text
    begin
        exit(RegisterItemImageTok);
    end;

    procedure "CONST::RegisterImage"(): Text
    begin
        exit(RegisterImageTok);
    end;

    procedure "CONST::ToggleTotePicking"(): Text
    begin
        exit(ToggleTotePickingTok);
    end;

    procedure "CONST::AddPhysInvtRecordLine"(): Text
    begin
        exit(AddPhysInvtRecordLineTok);
    end;

    procedure "CONST::SubstituteProdOrderComponent"(): Text
    begin
        exit(SubstituteProdOrderComponentTok);    // Same type is used for lookup and postadhoc
    end;

    procedure "CONST::ProdUnplannedConsumption"(): Text
    begin
        exit(ProdUnplannedConsumptionTok);
    end;

    procedure "CONST::ProdOutputTimeTracking"(): Text
    begin
        exit(ProdOutputTimeTrackingTok);
    end;

    procedure "CONST::ProdOutput"(): Text
    begin
        exit(ProdOutputTok);    // Same type is used for lookup and postadhoc
    end;

    procedure "CONST::ProdOutputQuantity"(): Text
    begin
        exit(ProdOutputQuantityTok);
    end;

    procedure "CONST::ProdOutputTime"(): Text
    begin
        exit(ProdOutputTimeTok);
    end;

    procedure "CONST::ProdOutputScrap"(): Text
    begin
        exit(ProdOutputScrapTok);
    end;

    procedure "CONST::ProdOutputFinishOperation"(): Text
    begin
        exit(ProdOutputFinishOperationTok);
    end;

    procedure "CONST::CreateAssemblyOrder"(): Text
    begin
        exit(CreateAssemblyOrderTok);
    end;

    procedure "CONST::AdjustQtyToAssemble"(): Text
    begin
        exit(AdjustQtyToAssembleTok);
    end;

    procedure "CONST::EditLicensePlate"(): Text
    begin
        exit(EditLicensePlateTok);
    end;

    procedure "ERROR::CreateStepsByReferenceDataKeyAlreadySet"(): Text
    begin
        exit(CreateStepsByReferenceDataKeyAlreadySetErr);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSaveRegistrationValue(_Path: Text; _Value: Text; var _MobileWMSRegistration: Record "MOB WMS Registration"; var _IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// ONLY use this event when your planned function uses a more complex BackendID e.g. "Order No."+"Document Type"
    /// BackendID is the key value, mobile uses to handle orders, this is normally just "Order No."
    /// Planned functions needs to save "Order No." in "Mob WMS Registrations".
    /// If you use a complex BackendID,  use this event to extract the "Order No." from BackendID.
    /// Tip: You should extend the Enum::"MOB WMS Registration Type" with your custom type.
    /// </summary>
    /// <param name="_BackendID">The BackendID value to extract values from.</param>
    /// <param name="_MobWmsRegistration">You MUST set "_MobWmsRegistration.Order No.". Plus any custom fields you have extended _MobWmsRegistration with.</param>
    /// <param name="_IsHandled">Set to true when you handle your "_MobWmsRegistration.Type"</param>
    [IntegrationEvent(false, false)]
    local procedure OnSaveRegistrationData_OnApplyBackendId(_BackendID: Text; var _MobWmsRegistration: Record "MOB WMS Registration"; var _IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSaveRealtimeRegistrationValue(_Path: Text; _Value: Text; var _RealtimeRegistration: Record "MOB Realtime Reg Qty."; var _IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetLocationFilter(var _LocationFilter: Text; var _IsHandled: Boolean)
    begin
    end;

}
