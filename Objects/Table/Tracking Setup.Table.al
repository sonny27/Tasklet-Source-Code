table 81284 "MOB Tracking Setup"
{
    Access = Public;

    //
    // AppVersion 18.0.0.0 / 19.0.0.0
    //

    Caption = 'MOB Tracking Setup', Locked = true;
    DataCaptionFields = "Code";
#pragma warning disable AS0034
    TableType = Temporary;
#pragma warning restore AS0034

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code', Locked = true;
            DataClassification = CustomerContent;
            NotBlank = true;
        }
        field(10; "Serial No. Required"; Boolean)
        {
            Caption = 'Serial No. Required', Locked = true;
            DataClassification = CustomerContent;
        }
        field(11; "Lot No. Required"; Boolean)
        {
            Caption = 'Lot No. Required', Locked = true;
            DataClassification = CustomerContent;
        }
        field(12; "Package No. Required"; Boolean)
        {
            Caption = 'Package No. Required', Locked = true;
            CaptionClass = '6,4';
            DataClassification = CustomerContent;
        }
        field(20; "Serial No."; Code[50])
        {
            Caption = 'Serial No.', Locked = true;
            DataClassification = CustomerContent;
        }
        field(21; "Lot No."; Code[50])
        {
            Caption = 'Lot No.', Locked = true;
            DataClassification = CustomerContent;
        }
        field(22; "Package No."; Code[50])
        {
            Caption = 'Package No.', Locked = true;
            CaptionClass = '6,1';
            DataClassification = CustomerContent;
        }
        field(30; "Serial No. Info Required"; Boolean)
        {
            Caption = 'Serial No. Info Required', Locked = true;
            DataClassification = CustomerContent;
        }
        field(31; "Lot No. Info Required"; Boolean)
        {
            Caption = 'Lot No. Info Required', Locked = true;
            DataClassification = CustomerContent;
        }
        field(32; "Package No. Info Required"; Boolean)
        {
            Caption = 'Package No. Info Required', Locked = true;
            CaptionClass = '6,5';
            DataClassification = CustomerContent;
        }
        //
        // Mismatch fields (field 40-42) are unused in Mobile WMS and not supported
        //
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        MobReservationMgt: Codeunit "MOB Reservation Mgt.";

    /// <summary>
    /// Clear all "No." fields without clearing "Required" fields. Partially derived from ItemJnlLine.ClearTracking()
    /// </summary>
    procedure ClearTracking()
    var
        ItemJnlLine: Record "Item Journal Line";
        ItemTrackingSetup: Record "Item Tracking Setup";
    begin
        Clear(ItemJnlLine);
        ItemTrackingSetup.TransferFields(Rec);
        ItemTrackingSetup.CopyTrackingFromItemJnlLine(ItemJnlLine); // Clear "No." fields without clearing "Required" fields
        Rec.TransferFields(ItemTrackingSetup);

        // Intentionally no event here (inheriting standard event)
        // ItemJnlLine.OnAfterClearTracking()
    end;

    /// <summary>
    /// Clear all "Required" fields without clearing "No." fields. New Mobile WMS function and not derived from any standard method.
    /// </summary>
    procedure ClearTrackingRequired()
    var
        ItemTrackingCode: Record "Item Tracking Code";
        ItemTrackingSetup: Record "Item Tracking Setup";
    begin
        Clear(ItemTrackingCode);
        ItemTrackingSetup.TransferFields(Rec);
        ItemTrackingSetup.CopyTrackingFromItemTrackingCodeWarehouseTracking(ItemTrackingCode); // Clear all "Required" fields without clearing "No." fields
        Rec.TransferFields(ItemTrackingSetup);

        // Intentionally no event here (inheriting standard event)
        // ItemTrackingSetup.OnAfterCopyTrackingFromItemTrackingCodeWarehouseTracking(Rec, ItemTrackingCode);
    end;

    procedure CopyTrackingFromItemLedgerEntry(_ItemLedgerEntry: Record "Item Ledger Entry")
    var
        ItemJnlLine: Record "Item Journal Line";
    begin
        ItemJnlLine.CopyTrackingFromItemLedgEntry(_ItemLedgerEntry);
        CopyTrackingFromItemJnlLine(ItemJnlLine);

        // Intentionally no event here (inheriting standard event)
        // ItemJnlLine.OnAfterCopyTrackingFromItemLedgEntry(Rec, ItemLedgEntry);
    end;

    procedure CopyTrackingRequiredFromItemTrackingSetup(_ItemTrackingSetup: Record "Item Tracking Setup")
    begin
        "Serial No. Required" := _ItemTrackingSetup."Serial No. Required";
        "Lot No. Required" := _ItemTrackingSetup."Lot No. Required";

        OnAfterCopyTrackingRequiredFromItemTrackingSetup(Rec, _ItemTrackingSetup);
    end;

    procedure CopyTrackingFromPhysInvtRecordLine(_PhysInvtRecordLine: Record "Phys. Invt. Record Line")
    begin
        "Lot No." := _PhysInvtRecordLine."Lot No.";
        "Serial No." := _PhysInvtRecordLine."Serial No.";

        OnAfterCopyTrackingFromPhysInvtRecordLine(Rec, _PhysInvtRecordLine);// Note: Package No. supported in PhysInvtRecordLine from BC24+ if feature enabled
    end;

    procedure CopyTrackingFromRequestValues(var _RequestValues: Record "MOB NS Request Element")
    var
        MobToolbox: Codeunit "MOB Toolbox";
    begin
        "Serial No." := MobToolbox.ReadLot(_RequestValues.GetValue('SerialNumber', false));
        "Lot No." := MobToolbox.ReadSerial(_RequestValues.GetValue('LotNumber', false));

        OnAfterCopyTrackingFromRequestValues(Rec, _RequestValues);
    end;

    procedure CopyTrackingFromRequestValuesIfRequired(var _RequestValues: Record "MOB NS Request Element"; _ErrorIfNotExists: Boolean)
    var
        MobToolbox: Codeunit "MOB Toolbox";
    begin
        if "Serial No. Required" then
            "Serial No." := MobToolbox.ReadLot(_RequestValues.GetValue('SerialNumber', _ErrorIfNotExists));
        if "Lot No. Required" then
            "Lot No." := MobToolbox.ReadSerial(_RequestValues.GetValue('LotNumber', _ErrorIfNotExists));

        OnAfterCopyTrackingFromRequestValuesIfRequired(Rec, _RequestValues, _ErrorIfNotExists);
    end;

    procedure CopyTrackingFromRequestContextValues(var _RequestValues: Record "MOB NS Request Element")
    var
        MobToolbox: Codeunit "MOB Toolbox";
    begin
        "Serial No." := MobToolbox.ReadLot(_RequestValues.GetContextValue('SerialNumber', false));
        "Lot No." := MobToolbox.ReadSerial(_RequestValues.GetContextValue('LotNumber', false));

        OnAfterCopyTrackingFromRequestContextValues(Rec, _RequestValues);
    end;

    procedure CopyTrackingFromRegistration(var _Registration: Record "MOB WMS Registration")
    begin
        "Serial No." := _Registration.SerialNumber;
        "Lot No." := _Registration.LotNumber;

        OnAfterCopyTrackingFromRegistration(Rec, _Registration);
    end;

    procedure CopyTrackingFromRegistrationIfRequired(var _Registration: Record "MOB WMS Registration")
    begin
        if "Serial No. Required" then
            "Serial No." := _Registration.SerialNumber;
        if "Lot No. Required" then
            "Lot No." := _Registration.LotNumber;

        OnAfterCopyTrackingFromRegistrationIfRequired(Rec, _Registration);
    end;

    procedure CopyTrackingFromTestData(var _TestData: Record "MOB Test Data")
    begin
        "Serial No." := _TestData."Serial No.";
        "Lot No." := _TestData."Lot No.";

        OnAfterCopyTrackingFromTestData(Rec, _TestData);    // Note: Package No. currently not supported in TestData and Test Helper
    end;

    procedure CopyTrackingFromTrackingByBinQueryIfRequired(_TrackingByBinQuery: Query "MOB WMS Tracking By Bin")
    begin
        if "Lot No. Required" then
            "Lot No." := _TrackingByBinQuery.Lot_No;
        if "Serial No. Required" then
            "Serial No." := _TrackingByBinQuery.Serial_No;

        OnAfterCopyTrackingFromTrackingByBinQueryIfRequired(Rec, _TrackingByBinQuery);
    end;

    procedure CopyTrackingFromTrackingSpec(var _TrackingSpecification: Record "Tracking Specification")
    var
        ItemTrackingSetup: Record "Item Tracking Setup";
    begin
        ItemTrackingSetup.TransferFields(Rec);
        ItemTrackingSetup.CopyTrackingFromTrackingSpec(_TrackingSpecification);
        Rec.TransferFields(ItemTrackingSetup);

        // Intentionally no event here (inheriting standard event)
        // ItemTrackingSetup.OnAfterCopyTrackingFromTrackingSpec(Rec, TrackingSpecification);
    end;

    procedure CopyTrackingFromWhseActivityLine(_WhseActLine: Record "Warehouse Activity Line")
    var
        ItemTrackingSetup: Record "Item Tracking Setup";
    begin
        ItemTrackingSetup.TransferFields(Rec);
        ItemTrackingSetup.CopyTrackingFromWhseActivityLine(_WhseActLine);
        Rec.TransferFields(ItemTrackingSetup);

        // Intentionally no event here (inheriting standard event)
        // ItemTrackingSetup.OnAfterCopyTrackingFromWhseActivityLine(Rec, WhseActivityLine);
    end;

    procedure CopyTrackingFromWhseJnlLine(_WhseJnlLine: Record "Warehouse Journal Line")
    var
        ItemTrackingSetup: Record "Item Tracking Setup";
        WhseEntry: Record "Warehouse Entry";
    begin
        ItemTrackingSetup.TransferFields(Rec);
        WhseEntry.CopyTrackingFromWhseJnlLine(_WhseJnlLine);
        ItemTrackingSetup.CopyTrackingFromWhseEntry(WhseEntry);
        Rec.TransferFields(ItemTrackingSetup);

        // Intentionally no event here (inheriting standard event)
        // WhseEntry.OnAfterCopyTrackingFromWhseJnlLine(Rec, WhseJnlLine);
    end;

    procedure CopyTrackingToBaseOrderLine(var _BaseOrderLine: Record "MOB NS BaseDataModel Element")
    begin
        _BaseOrderLine.Set_LotNumber("Lot No.");
        _BaseOrderLine.Set_SerialNumber("Serial No.");

        OnAfterCopyTrackingToBaseOrderLine(_BaseOrderLine, Rec);
    end;

    procedure CopyTrackingToLookupResponse(var _LookupResponse: Record "MOB NS WhseInquery Element")
    begin
        _LookupResponse.Set_LotNumber("Lot No.");
        _LookupResponse.Set_SerialNumber("Serial No.");

        OnAfterCopyTrackingToLookupResponse(_LookupResponse, Rec);
    end;

    procedure CopyTrackingToLookupResponseAsDisplayTracking(var _LookupResponse: Record "MOB NS WhseInquery Element")
    var
        MobWmsLanguage: Codeunit "MOB WMS Language";
    begin
        _LookupResponse.Set_DisplaySerialNumber("Serial No." <> '', MobWmsLanguage.GetMessage('SERIAL_NO_LABEL') + ': ' + "Serial No.", '');
        _LookupResponse.Set_DisplayLotNumber("Lot No." <> '', MobWmsLanguage.GetMessage('LOT_NO_LABEL') + ': ' + "Lot No.", '');
        _LookupResponse.SetValue('DisplayTracking', FormatTracking());
        _LookupResponse.SetValue('DisplayTrackingFeatureIsEnabled', 'true');

        OnAfterCopyTrackingToLookupResponseAsDisplayTracking(_LookupResponse, Rec);
    end;

    /// <summary>
    /// RegisterTracking is generally not used for unplanned functions but is used in the Production area for adhoc steps customization.
    /// </summary>
    internal procedure CopyTrackingRequiredFromLookupResponse(var _LookupResponse: Record "MOB NS WhseInquery Element"; _ErrorIfNotExists: Boolean)
    begin
        "Lot No. Required" := _LookupResponse.GetValueAsBoolean('RegisterLotNumber', _ErrorIfNotExists);
        "Serial No. Required" := _LookupResponse.GetValueAsBoolean('RegisterSerialNumber', _ErrorIfNotExists);

        OnAfterCopyTrackingRequiredFromLookupResponse(Rec, _LookupResponse, _ErrorIfNotExists);
    end;

    procedure CopyTrackingRequiredToBaseOrderLine(var _BaseOrderLine: Record "MOB NS BaseDataModel Element")
    begin
        _BaseOrderLine.Set_RegisterLotNumber("Lot No. Required");
        _BaseOrderLine.Set_RegisterSerialNumber("Serial No. Required");

        OnAfterCopyTrackingRequiredToBaseOrderLine(_BaseOrderLine, Rec);
    end;

    /// <summary>
    /// RegisterTracking is generally not used for unplanned functions but is used in the Production area for adhoc steps customization.
    /// </summary>
    internal procedure CopyTrackingRequiredToLookupResponse(var _LookupResponse: Record "MOB NS WhseInquery Element")
    var
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
    begin
        _LookupResponse.SetValue('RegisterLotNumber', MobWmsToolbox.Bool2Text("Lot No. Required"));
        _LookupResponse.SetValue('RegisterSerialNumber', MobWmsToolbox.Bool2Text("Serial No. Required"));

        OnAfterCopyTrackingRequiredToLookupResponse(_LookupResponse, Rec);
    end;

    procedure CopyTrackingToEntrySummary(var _EntrySummary: Record "Entry Summary")
    var
        ItemTrackingSetup: Record "Item Tracking Setup";
    begin
        ItemTrackingSetup.TransferFields(Rec);
        _EntrySummary.CopyTrackingFromItemTrackingSetup(ItemTrackingSetup);

        // Intentionally no event here (inheriting standard event)
        // EntrySummary.OnAfterCopyTrackingFromItemTrackingSetup(Rec, ItemTrackingSetup);
    end;

    procedure CopyTrackingToItemJnlLine(var _ItemJnlLine: Record "Item Journal Line")
    var
        TrackingSpecification: Record "Tracking Specification";
    begin
        CopyTrackingToTrackingSpec(TrackingSpecification);
        _ItemJnlLine.CopyTrackingFromSpec(TrackingSpecification);

        // Intentionally no event here (inheriting standard event)
        // ItemJnlLine.OnAfterCopyTrackingFromSpec(Rec, TrackingSpecification);
    end;

    procedure CopyTrackingToItemLedgerEntry(var _ItemLedgerEntry: Record "Item Ledger Entry")
    var
        ItemJnlLine: Record "Item Journal Line";
    begin
        CopyTrackingToItemJnlLine(ItemJnlLine);
        _ItemLedgerEntry.CopyTrackingFromItemJnlLine(ItemJnlLine);

        // Intentionally no event here (inheriting standard event)
        // ItemLedgEntry.OnAfterCopyTrackingFromItemJnlLine(Rec, ItemJnlLine);
    end;

    procedure CopyTrackingToReservEntry(var _ReservEntry: Record "Reservation Entry")
    var
        ItemTrackingSetup: Record "Item Tracking Setup";
    begin
        ItemTrackingSetup.TransferFields(Rec);
        _ReservEntry.CopyTrackingFromItemTrackingSetup(ItemTrackingSetup);
        Rec.TransferFields(ItemTrackingSetup);

        // Intentionally no event here (inheriting standard event)
        // ReservEntry.OnAfterCopyTrackingFromItemTrackingSetup(Rec, ItemTrackingSetup);
    end;

    procedure CopyTrackingToTrackingSpec(var _TrackingSpecification: Record "Tracking Specification")
    var
        ItemTrackingSetup: Record "Item Tracking Setup";
    begin
        ItemTrackingSetup.TransferFields(Rec);
        _TrackingSpecification.CopyTrackingFromItemTrackingSetup(ItemTrackingSetup);

        // Intentionally no event here (inheriting standard event)
        // TrackingSpecification.OnAfterCopyTrackingFromItemTrackingSetup(Rec, ItemTrackingSetup);
    end;

    procedure CopyTrackingToWhseActivityLine(var _WhseActivityLine: Record "Warehouse Activity Line")
    var
        ItemTrackingSetup: Record "Item Tracking Setup";
    begin
        ItemTrackingSetup.TransferFields(Rec);
        _WhseActivityLine.CopyTrackingFromItemTrackingSetup(ItemTrackingSetup);

        // Intentionally no event here (inheriting standard event)
        // WhseActivityLine.OnAfterCopyTrackingFromItemTrackingSetup(Rec, WhseItemTrackingSetup);
    end;

    procedure CopyTrackingToWhseJnlLine(var _WhseJnlLine: Record "Warehouse Journal Line")
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        CopyTrackingToItemLedgerEntry(ItemLedgEntry);
        _WhseJnlLine.CopyTrackingFromItemLedgEntry(ItemLedgEntry);

        // Intentionally no event here (inheriting standard event)
        // WhseJnlLine.OnAfterCopyTrackingFromItemLedgEntry(Rec, ItemLedgEntry);
    end;

    /// <summary>
    /// Based on ItemTrackingSetup.CopyTrackingFromEntrySummary
    /// </summary>
    procedure CopyTrackingFromEntrySummary(_EntrySummary: Record "Entry Summary")
    var
        ItemTrackingSetup: Record "Item Tracking Setup";
    begin
        ItemTrackingSetup.TransferFields(Rec);
        ItemTrackingSetup.CopyTrackingFromEntrySummary(_EntrySummary);
        Rec.TransferFields(ItemTrackingSetup);

        // Intentionally no event here (inheriting standard event)
        // ItemTrackingSetup.OnAfterCopyTrackingFromEntrySummary(Rec, EntrySummary);
    end;

    /// <summary>
    /// Based on ItemTrackingSetup.CopyTrackingFromWhseEntry
    /// </summary>
    procedure CopyTrackingFromWhseEntry(_WhseEntry: Record "Warehouse Entry")
    var
        ItemTrackingSetup: Record "Item Tracking Setup";
    begin
        ItemTrackingSetup.TransferFields(Rec);
        ItemTrackingSetup.CopyTrackingFromWhseEntry(_WhseEntry);
        Rec.TransferFields(ItemTrackingSetup);

        // Intentionally no event here (inheriting standard event)
        // ItemTrackingSetup.OnAfterCopyTrackingFromWhseEntry(Rec, WhseEntry);
    end;

    procedure CopyTrackingFromItemJnlLine(_ItemJnlLine: Record "Item Journal Line")
    var
        ItemTrackingSetup: Record "Item Tracking Setup";
    begin
        ItemTrackingSetup.TransferFields(Rec);
        ItemTrackingSetup.CopyTrackingFromItemJnlLine(_ItemJnlLine);
        Rec.TransferFields(ItemTrackingSetup);

        // Intentionally no event here (inheriting standard event)
        // ItemTrackingSetup.OnAfterCopyTrackingFromItemJnlLine(Rec, ItemJnlLine);
    end;

    procedure CopyTrackingFromReservEntry(ReservEntry: Record "Reservation Entry")
    var
        ItemTrackingSetup: Record "Item Tracking Setup";
    begin
        ItemTrackingSetup.TransferFields(Rec);
        ItemTrackingSetup.CopyTrackingFromReservEntry(ReservEntry);
        Rec.TransferFields(ItemTrackingSetup);

        // Intentionally no event here (inheriting standard event)
        // ItemTrackingSetup.OnAfterCopyTrackingFromReservEntry(Rec, ReservEntry);
    end;

    procedure CopyTrackingFromReservEntryIfNotBlank(_ReservEntry: Record "Reservation Entry")
    begin
        if _ReservEntry."Serial No." <> '' then
            "Serial No." := _ReservEntry."Serial No.";
        if _ReservEntry."Lot No." <> '' then
            "Lot No." := _ReservEntry."Lot No.";

        OnAfterCopyTrackingFromReservEntryIfNotBlank(Rec, _ReservEntry);
    end;

    procedure TrackingExists() IsTrackingExists: Boolean
    var
        ItemTrackingSetup: Record "Item Tracking Setup";
    begin
        ItemTrackingSetup.TransferFields(Rec);
        IsTrackingExists := ItemTrackingSetup.TrackingExists();

        // Intentionally no event here (inheriting standard event)
        // ItemTrackingSetup.OnAfterTrackingExists(Rec, IsTrackingExists);
    end;

    procedure TrackingRequired() IsTrackingRequired: Boolean
    var
        ItemTrackingSetup: Record "Item Tracking Setup";
    begin
        ItemTrackingSetup.TransferFields(Rec);
        IsTrackingRequired := ItemTrackingSetup.TrackingRequired();

        // Intentionally no event here (inheriting standard event)
        // ItemTrackingSetup.OnAfterTrackingRequired(Rec, IsTrackingRequired);
    end;

    /// <summary>
    /// Check Tracking is on inventory if tracking is not blank
    /// </summary>
    procedure CheckTrackingOnInventoryIfNotBlank(_ItemNo: Code[20]; _VariantCode: Code[10])
    begin
        if "Serial No." <> '' then
            CheckSerialNoOnInventory(_ItemNo, _VariantCode);
        if "Lot No." <> '' then
            CheckLotNoOnInventory(_ItemNo, _VariantCode);

        OnAfterCheckTrackingOnInventoryIfNotBlank(_ItemNo, _VariantCode, Rec);
    end;

    /// <summary>
    /// Check Tracking is on inventory if TrackingRequired
    /// </summary>
    procedure CheckTrackingOnInventoryIfRequired(_ItemNo: Code[20]; _VariantCode: Code[10])
    begin
        if "Serial No. Required" then
            CheckSerialNoOnInventory(_ItemNo, _VariantCode);
        if "Lot No. Required" then
            CheckLotNoOnInventory(_ItemNo, _VariantCode);

        OnAfterCheckTrackingOnInventoryIfRequired(_ItemNo, _VariantCode, Rec);
    end;

    /// <summary>
    /// Check Serial No. is on inventory
    /// </summary>
    internal procedure CheckSerialNoOnInventory(_ItemNo: Code[20]; _VariantCode: Code[10])
    var
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
        SerialExists: Boolean;
    begin
        SerialExists := ItemTrackingMgt.FindInInventory(_ItemNo, _VariantCode, "Serial No.");
        if not SerialExists then
            Error(MobWmsLanguage.GetMessage('UNKNOWN_SERIAL'), "Serial No.", MobWmsToolbox.GetItemAndVariantTxt(_ItemNo, _VariantCode));
    end;

    /// <summary>
    /// Check Lot No. is on inventory
    /// </summary>
    internal procedure CheckLotNoOnInventory(_ItemNo: Code[20]; _VariantCode: Code[10])
    var
        MobWmsLanguage: Codeunit "MOB WMS Language";
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
        LotExists: Boolean;
    begin
        LotExists := MobWmsToolbox.InventoryExistsByLotNo(_ItemNo, _VariantCode, "Lot No.");
        if not LotExists then
            Error(MobWmsLanguage.GetMessage('UNKNOWN_LOT'), "Lot No.", MobWmsToolbox.GetItemAndVariantTxt(_ItemNo, _VariantCode));
    end;

    /// <summary>
    /// Format tracking fields as CRLF separated text
    /// </summary>
    procedure FormatTracking(): Text
    begin
        exit(FormatTracking('%1'));   // Standard Tracking format with no indentation
    end;

    /// <summary>
    /// Format tracking fields as CRLF separated text with a format expression
    /// </summary>
    /// <param name="_FormatExpr">The format of each line. The tracking field is %1 in a StrSubstNo-expression. To be used for ie. indentation</param>
    procedure FormatTracking(_FormatExpr: Text): Text
    var
        MobToolbox: Codeunit "MOB Toolbox";
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        TrackingList: List of [Text];
    begin
        if "Lot No." <> '' then
            MobToolbox.AddUniqueText(TrackingList, StrSubstNo(_FormatExpr, MobWmsLanguage.GetMessage('LOT_NO_LABEL') + ': ' + "Lot No."));
        if "Serial No." <> '' then
            MobToolbox.AddUniqueText(TrackingList, StrSubstNo(_FormatExpr, MobWmsLanguage.GetMessage('SERIAL_NO_LABEL') + ': ' + "Serial No."));

        OnFormatTrackingOnAfterGetTrackingList(TrackingList, Rec, _FormatExpr);

        exit(MobWmsToolbox.List2TextLn(TrackingList, 999));
    end;

    /// <summary>
    /// Set "Lot No. Filter", "Serial No. Filter" and "Package No. Filter" unconditionally
    /// </summary>
    procedure SetTrackingFilterForBinContent(var _BinContent: Record "Bin Content")
    var
        ItemTrackingSetup: Record "Item Tracking Setup";
    begin
        ItemTrackingSetup.TransferFields(Rec);
        _BinContent.SetTrackingFilterFromWhseItemTrackingSetup(ItemTrackingSetup);

        // Intentionally no event here (inheriting standard event)
        // BinContent.OnAfterSetTrackingFilterFromWhseItemTrackingSetup(Rec, WhseItemTrackingSetup);
    end;

    /// <summary>
    /// Set "Serial No. Filter", "Lot No. Filter" and "Package No. Filter" using values from the "Serial No.", "Lot No." and "Package No." fields
    /// Derived from BinContent.SetTrackingFilterFromWhseItemTrackingSetup
    /// </summary>
    procedure SetTrackingFilterForBinContentIfNotBlank(var _BinContent: Record "Bin Content")
    var
        ItemTrackingSetup: Record "Item Tracking Setup";
    begin
        ItemTrackingSetup.TransferFields(Rec);
        _BinContent.SetTrackingFilterFromItemTrackingSetupIfNotBlank(ItemTrackingSetup);

        // Intentionally no event here (inheriting standard event)
        // BinContent.OnAfterSetTrackingFilterFromWhseItemTrackingSetup(Rec, WhseItemTrackingSetup);
    end;

    procedure SetTrackingFilterForEntrySummary(var _EntrySummary: Record "Entry Summary")
    var
        ItemTrackingSetup: Record "Item Tracking Setup";
    begin
        ItemTrackingSetup.TransferFields(Rec);
        _EntrySummary.SetTrackingFilterFromItemTrackingSetup(ItemTrackingSetup);

        // Intentionally no event here (inheriting standard event)
        // EntrySummary.OnAfterSetTrackingFilterFromItemTrackingSetup(Rec, ItemTrackingSetup);
    end;

    /// <summary>
    /// New method with same name as standard method SetTrackingFilterForItem but working differently (setting filters unconditionally including when not blank)
    /// </summary>
    procedure SetTrackingFilterForItem(var _Item: Record Item)
    begin
        _Item.SetRange("Serial No. Filter", "Serial No.");
        _Item.SetRange("Lot No. Filter", "Lot No.");

        OnAfterSetTrackingFilterForItem(_Item, Rec);
    end;


    /// <summary>
    /// Based on standard ItemTrackingSetup.SetTrackingFilterForItem() but renamed to SetTrackingFilterForItemIfNotBlank
    /// </summary>
    procedure SetTrackingFilterForItemIfNotBlank(var _Item: Record Item)
    var
        ItemTrackingSetup: Record "Item Tracking Setup";
    begin
        ItemTrackingSetup.TransferFields(Rec);
        ItemTrackingSetup.SetTrackingFilterForItem(_Item);  // Despite naming filters are only set if not blank

        // Intentionally no event here (inheriting standard event)
        // ItemTrackingSetup.OnAfterSetTrackingFilterForItem(Item, Rec);
    end;

    /// <summary>
    /// New method used from Ship
    /// </summary>
    procedure SetTrackingFilterForItemIfRequired(var _Item: Record Item)
    begin
        if "Serial No. Required" then
            _Item.SetRange("Serial No. Filter", "Serial No.");
        if "Lot No. Required" then
            _Item.SetRange("Lot No. Filter", "Lot No.");

        OnAfterSetTrackingFilterForItemIfRequired(_Item, Rec);
    end;

    procedure SetTrackingFilterForItemLedgerEntryIfNotBlank(var _ItemLedgerEntry: Record "Item Ledger Entry")
    var
        ItemTrackingSetup: Record "Item Tracking Setup";
    begin
        ItemTrackingSetup.TransferFields(Rec);
        _ItemLedgerEntry.SetTrackingFilterFromItemTrackingSetupIfNotBlank(ItemTrackingSetup);

        // Intentionally no event here (inheriting standard event)
        // ItemLedgerEntry.SetTrackingFilterFromItemTrackingSetupIfNotBlank(Rec, ItemTrackingSetup);
    end;

    /// <summary>
    /// New method used from Ship
    /// </summary>
    /// <remarks>
    /// "Homemade" naming convention (a similar condition do not exist in standard code)
    /// </remarks>
    procedure SetTrackingFilterNotEqualForItemLedgerEntryIfNotBlank(var _ItemLedgerEntry: Record "Item Ledger Entry")
    begin
        if "Serial No." <> '' then
            _ItemLedgerEntry.SetFilter("Serial No.", '<>%1', "Serial No.");
        if "Lot No." <> '' then
            _ItemLedgerEntry.SetFilter("Lot No.", '<>%1', "Lot No.");

        OnAfterSetTrackingFilterNotEqualForItemLedgerEntryIfNotBlank(_ItemLedgerEntry, Rec);
    end;

    /// <summary>
    /// New method used from Adhoc
    /// </summary>
    procedure SetTrackingFilterForItemJnlLineIfNotBlank(var _ItemJnlLine: Record "Item Journal Line")
    begin
        if "Serial No." <> '' then
            _ItemJnlLine.SetRange("Serial No.", "Serial No.");
        if "Lot No." <> '' then
            _ItemJnlLine.SetRange("Lot No.", "Lot No.");

        OnAfterSetTrackingFilterForItemJnlLineIfNotBlank(_ItemJnlLine, Rec);
    end;

    procedure SetTrackingFilterForRegisteredWhseActLine(var _RegisteredWhseActLine: Record "Registered Whse. Activity Line")
    var
        TrackingSpecification: Record "Tracking Specification";
    begin
        CopyTrackingToTrackingSpec(TrackingSpecification);
        _RegisteredWhseActLine.SetTrackingFilterFromSpec(TrackingSpecification);

        // Intentionally no event here (inheriting standard event)
        // RegisteredWhseActLine.OnAfterSetTrackingFilterFromSpec(Rec, TrackingSpecification);
    end;

    /// <summary>
    /// New function used from Ship
    /// </summary>
    internal procedure SetTrackingFilterBlankForReservEntryIfNotBlank(var _ReservEntry: Record "Reservation Entry")
    begin
        if "Serial No." <> '' then
            _ReservEntry.SetRange("Serial No.", '');
        if "Lot No." <> '' then
            _ReservEntry.SetRange("Lot No.", '');

        OnAfterSetTrackingFilterBlankForReservEntryIfNotBlank(_ReservEntry, Rec);
    end;

    /// <summary>
    /// New function used from Ship
    /// </summary>
    internal procedure SetTrackingFilterForReservEntryIfNotBlank(var _ReservEntry: Record "Reservation Entry")
    var
        ItemTrackingSetup: Record "Item Tracking Setup";
    begin
        ItemTrackingSetup.TransferFields(Rec);
        _ReservEntry.SetTrackingFilterFromItemTrackingSetupIfNotBlank(ItemTrackingSetup);

        // Intentionally no event here (inheriting standard event)
        // ReservEntry.OnAfterSetTrackingFilterFromItemTrackingSetupIfNotBlank(Rec, ItemTrackingSetup);
    end;

    procedure SetTrackingFilterForReservEntryIfRequired(var _ReservEntry: Record "Reservation Entry")
    begin
        if "Serial No. Required" then
            _ReservEntry.SetRange("Serial No.", "Serial No.");
        if "Lot No. Required" then
            _ReservEntry.SetRange("Lot No.", "Lot No.");

        OnAfterSetTrackingFilterForReservEntryIfRequired(_ReservEntry, Rec);
    end;

    /// <summary>
    /// Set "Serial No. Filter", "Lot No. Filter" and "Package No. Filter" using values from the "Serial No.", "Lot No." and "Package No." fields
    /// Derived from WhseActivityLine.OnAfterSetTrackingFilterFromItemTrackingSetup
    /// </summary>
    procedure SetTrackingFilterForWhseActivityLine(var _WhseActivityLine: Record "Warehouse Activity Line")
    var
        ItemTrackingSetup: Record "Item Tracking Setup";
    begin
        ItemTrackingSetup.TransferFields(Rec);
        _WhseActivityLine.SetTrackingFilterFromItemTrackingSetup(ItemTrackingSetup);

        // Intentionally no event here (inheriting standard event)
        // WhseActivityLine.OnAfterSetTrackingFilterFromItemTrackingSetup(Rec, ItemTrackingSetup);
    end;

    /// <summary>
    /// New method used from Adhoc
    /// </summary>
    procedure SetTrackingFilterForWhseJnlLineIfNotBlank(var _WhseJnlLine: Record "Warehouse Journal Line")
    begin
        if "Serial No." <> '' then
            _WhseJnlLine.SetRange("Serial No.", "Serial No.");
        if "Lot No." <> '' then
            _WhseJnlLine.SetRange("Lot No.", "Lot No.");

        OnAfterSetTrackingFilterForWhseJnlLineIfNotBlank(_WhseJnlLine, Rec);
    end;

    /// <summary>
    /// New method originally used from planned Activity. No longer used from our standard code as Serial No. can no
    /// longer be validated at Warehouse Activity Lines with Quantity (Base) greater than 1 (prior to split line).
    /// This was a change in recent BC versions.
    /// </summary>
    procedure ValidateTrackingToWhseActLine(var _WhseActLine: Record "Warehouse Activity Line")
    begin
        _WhseActLine.Validate("Serial No.", "Serial No.");
        _WhseActLine.Validate("Lot No.", "Lot No.");

        OnAfterValidateTrackingToWhseActLine(_WhseActLine, Rec);
    end;

    /// <summary>
    /// New method used from planned Activity
    /// Only if value are changed and only validated if Required
    /// </summary>
    procedure ValidateTrackingToWhseActLineIfRequired(var _WhseActLine: Record "Warehouse Activity Line")
    begin
        if (_WhseActLine."Serial No." <> "Serial No.") then
            if "Serial No. Required" then
                _WhseActLine.Validate("Serial No.", "Serial No.")
            else
                _WhseActLine."Serial No." := "Serial No.";

        if (_WhseActLine."Lot No." <> "Lot No.") then
            if "Lot No. Required" then
                _WhseActLine.Validate("Lot No.", "Lot No.")
            else
                _WhseActLine."Lot No." := "Lot No.";

        OnAfterValidateTrackingToWhseActLineIfRequired(_WhseActLine, Rec);
    end;

    /// <summary>
    /// New method used from Adhoc Registration
    /// </summary>
    procedure ValidateTrackingToWhseItemTrackingLine(var _WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
        _WhseItemTrackingLine.Validate("Serial No.", "Serial No.");
        _WhseItemTrackingLine.Validate("Lot No.", "Lot No.");

        OnAfterValidateTrackingToWhseItemTrackingLine(_WhseItemTrackingLine, Rec);
    end;

    /// <summary>
    /// New method used from Adhoc
    /// </summary>
    procedure ValidateTrackingToWhseJnlLineIfRequired(var _WhseJnlLine: Record "Warehouse Journal Line")
    begin
        if "Serial No. Required" then
            _WhseJnlLine.Validate("Serial No.", "Serial No.");
        if "Lot No. Required" then
            _WhseJnlLine.Validate("Lot No.", "Lot No.");

        OnAfterValidateTrackingToWhseJnlLineIfRequired(_WhseJnlLine, Rec);
    end;

    procedure DetermineItemTrackingRequired(_WhseActLine: Record "Warehouse Activity Line"; var _RegisterExpirationDate: Boolean)
    begin
        MobReservationMgt.DetermineItemTrackingRequired(_WhseActLine, Rec, _RegisterExpirationDate);
        OnAfterDetermineItemTrackingRequired(_WhseActLine, Rec, _RegisterExpirationDate);
    end;

    procedure DetermineItemTrackingRequiredByAssemblyHeader(_AssemblyHeader: Record "Assembly Header"; var _RegisterExpirationDate: Boolean)
    begin
        MobReservationMgt.DetermineItemTrackingRequiredByAssemblyHeader(_AssemblyHeader, Rec, _RegisterExpirationDate);
    end;

    procedure DetermineItemTrackingRequiredByAssemblyLine(_AssemblyLine: Record "Assembly Line"; var _RegisterExpirationDate: Boolean)
    begin
        MobReservationMgt.DetermineItemTrackingRequiredByAssemblyLine(_AssemblyLine, Rec, _RegisterExpirationDate);
    end;

    procedure DetermineItemTrackingRequiredByPurchaseLine(_PurchaseLine: Record "Purchase Line"; var _RegisterExpirationDate: Boolean)
    begin
        MobReservationMgt.DetermineItemTrackingRequiredByPurchaseLine(_PurchaseLine, Rec, _RegisterExpirationDate);
    end;

    procedure DetermineItemTrackingRequiredBySalesLine(_SalesLine: Record "Sales Line"; var _RegisterExpirationDate: Boolean)
    begin
        MobReservationMgt.DetermineItemTrackingRequiredBySalesLine(_SalesLine, Rec, _RegisterExpirationDate);
    end;

    procedure DetermineItemTrackingRequiredByTransferLine(_TransferLine: Record "Transfer Line"; _Inbound: Boolean; var _RegisterExpirationDate: Boolean)
    begin
        DetermineItemTrackingRequiredByEntryType(_TransferLine."Item No.", _Inbound, 4, _RegisterExpirationDate); // 4 = Transfer
    end;

    procedure DetermineItemTrackingRequiredByWhseReceiptLine(_WhseReceiptLine: Record "Warehouse Receipt Line"; var _RegisterExpirationDate: Boolean)
    begin
        MobReservationMgt.DetermineItemTrackingRequiredByWhseReceiptLine(_WhseReceiptLine, Rec, _RegisterExpirationDate);
    end;

    procedure DetermineItemTrackingRequiredByWhseShipmentLine(_WhseShipmentLine: Record "Warehouse Shipment Line"; var _RegisterExpirationDate: Boolean)
    begin
        MobReservationMgt.DetermineItemTrackingRequiredByWhseShipmentLine(_WhseShipmentLine, Rec, _RegisterExpirationDate);
    end;

    /// <summary>
    /// Uses the item's tracking code to determine if serial / lot / package numbers should be registered during production output
    /// </summary>
    procedure DetermineManufInboundTrackingRequiredFromItemNo(_ItemNo: Code[20]; var _RegisterExpirationDate: Boolean)
    begin
        DetermineItemTrackingRequiredByEntryType(_ItemNo, true, 6, _RegisterExpirationDate);    // true = Inbound, 6 = Output
    end;

    /// <summary>
    /// Uses the item's tracking code to determine if serial / lot / package numbers should be registered during production consumption
    /// </summary>
    procedure DetermineManufOutboundTrackingRequiredFromItemNo(_ItemNo: Code[20]; var _RegisterExpirationDate: Boolean)
    begin
        DetermineItemTrackingRequiredByEntryType(_ItemNo, false, 5, _RegisterExpirationDate);    // false = Outbound, 5 = Consumption
    end;

    procedure DetermineWhseTrackingRequired(_ItemNo: Code[20]; var _RegisterExpirationDate: Boolean)
    var
        ItemTrackingSetup: Record "Item Tracking Setup";
        ItemTrackingCode: Record "Item Tracking Code";
        Item: Record Item;
    begin
        // Clear all _ItemTrackingSetup "Required" fields
        ClearTrackingRequired();
        _RegisterExpirationDate := false;

        // Copy WarehouseTracking to _ItemTrackingSetup
        if Item.Get(_ItemNo) then
            if ItemTrackingCode.Get(Item."Item Tracking Code") then begin
                ItemTrackingSetup.TransferFields(Rec);
                ItemTrackingSetup.CopyTrackingFromItemTrackingCodeWarehouseTracking(ItemTrackingCode);
                Rec.TransferFields(ItemTrackingSetup);

                _RegisterExpirationDate := ItemTrackingCode."Man. Expir. Date Entry Reqd.";
            end;
    end;

    /// <summary>
    /// Determine Whse. Tracking enabled with "Manual" or "Strict" Expiration Date.
    /// </summary>
    procedure DetermineWhseTrackingRequiredWithExpirationDate(_ItemNo: Code[20]; var _SpeficicRegisterExpirationDate: Boolean)
    begin
        MobReservationMgt.DetermineWhseTrackingRequiredWithExpirationDate(_ItemNo, Rec, _SpeficicRegisterExpirationDate);
    end;

    procedure DetermineItemTrackingRequiredByEntryType(_ItemNo: Code[20]; _Inbound: Boolean; _EntryType: Option Purchase,Sale,"Positive Adjmt.","Negative Adjmt.",Transfer,Consumption,Output," ","Assembly Consumption","Assembly Output"; var _RegisterExpirationDate: Boolean)
    begin
        MobReservationMgt.DetermineItemTrackingRequiredByEntryType(_ItemNo, _Inbound, _EntryType, Rec, _RegisterExpirationDate);
    end;

    /// <summary>
    /// Uses the item's tracking code to determine if serial / lot numbers should be registered
    /// </summary>
    procedure DetermineSpecificTrackingRequiredFromItemNo(_ItemNo: Code[20]; var _RegisterExpirationDate: Boolean)
    var
        ItemTrackingCode: Record "Item Tracking Code";
        ItemTrackingSetup: Record "Item Tracking Setup";
        Item: Record Item;
    begin
        ClearTrackingRequired();
        _RegisterExpirationDate := false;

        // Copy SpecificTracking to _ItemTrackingSetup
        if Item.Get(_ItemNo) then
            if ItemTrackingCode.Get(Item."Item Tracking Code") then begin
                ItemTrackingSetup.TransferFields(Rec);
                ItemTrackingSetup.CopyTrackingFromItemTrackingCodeSpecificTracking(ItemTrackingCode);
                Rec.TransferFields(ItemTrackingSetup);

                _RegisterExpirationDate := ItemTrackingCode."Man. Expir. Date Entry Reqd.";
            end;
    end;

    procedure DetermineTransferTrackingRequired(_ItemNo: Code[20]; var _RegisterExpirationDate: Boolean)
    var
        ItemTrackingCode: Record "Item Tracking Code";
        ItemTrackingSetup: Record "Item Tracking Setup";
        Item: Record Item;
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        DummyInbound: Boolean;
    begin
        // Clear all _ItemTrackingSetup "Required" fields
        ClearTrackingRequired();
        _RegisterExpirationDate := false;

        // Copy Transfer Tracking to _ItemTrackingSetup
        if Item.Get(_ItemNo) then
            if ItemTrackingCode.Get(Item."Item Tracking Code") then begin
                DummyInbound := true;   // Unused for Item Ledger Entry Type::Transfer
                ItemTrackingSetup.TransferFields(Rec);
                ItemTrackingMgt.GetItemTrackingSetup(ItemTrackingCode, "Item Ledger Entry Type"::Transfer, DummyInbound, ItemTrackingSetup);
                Rec.TransferFields(ItemTrackingSetup);

                if TrackingRequired() then
                    _RegisterExpirationDate := ItemTrackingCode."Man. Expir. Date Entry Reqd.";
            end;
    end;

    //
    // ------- Adhoc Determine functions -------
    //

    procedure DetermineNegAdjustItemTrackingRequired(_ItemNo: Code[20]; var _RegisterExpirationDate: Boolean)
    var
        ItemTrackingCode: Record "Item Tracking Code";
        ItemTrackingSetupInbound: Record "Item Tracking Setup";
        ItemTrackingSetupOutbound: Record "Item Tracking Setup";
        DummyItemLedgerEntry: Record "Item Ledger Entry";
        Item: Record Item;
        ItemTrackingMgt: Codeunit "Item Tracking Management";

    begin
        ClearTrackingRequired();
        _RegisterExpirationDate := false;

        if Item.Get(_ItemNo) then
            if ItemTrackingCode.Get(Item."Item Tracking Code") then begin
                ItemTrackingMgt.GetItemTrackingSetup(ItemTrackingCode, DummyItemLedgerEntry."Entry Type"::"Negative Adjmt.", true, ItemTrackingSetupInbound);
                ItemTrackingMgt.GetItemTrackingSetup(ItemTrackingCode, DummyItemLedgerEntry."Entry Type"::"Negative Adjmt.", false, ItemTrackingSetupOutbound);

                "Serial No. Required" := ItemTrackingSetupInbound."Serial No. Required" or ItemTrackingSetupOutbound."Serial No. Required";
                "Lot No. Required" := ItemTrackingSetupInbound."Lot No. Required" or ItemTrackingSetupOutbound."Lot No. Required";

                _RegisterExpirationDate := ItemTrackingCode."Man. Expir. Date Entry Reqd.";
            end;

        OnAfterDetermineNegAdjustItemTrackingRequired(ItemTrackingSetupInbound, ItemTrackingSetupOutbound, Rec, _RegisterExpirationDate);
    end;

    //
    // ------- Create Reserv. Entry -------
    //
    procedure CreateReservEntryFor(var _CreateReservEntry: Codeunit "Create Reserv. Entry"; _ForType: Option; _ForSubtype: Integer; _ForID: Code[20]; _ForBatchName: Code[10]; _ForProdOrderLine: Integer; _ForRefNo: Integer; _ForQtyPerUOM: Decimal; _Quantity: Decimal; _QuantityBase: Decimal)
    var
        ForReservEntry: Record "Reservation Entry";
    begin
        Rec.CopyTrackingToReservEntry(ForReservEntry);
        _CreateReservEntry.CreateReservEntryFor(_ForType, _ForSubtype, _ForID, _ForBatchName, _ForProdOrderLine, _ForRefNo, _ForQtyPerUOM, _Quantity, _QuantityBase, ForReservEntry);
    end;

    //
    // ------- IntegrationEvents -------
    // NOTE: PackageNumber and custom dimensions supported via events

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingRequiredFromItemTrackingSetup(var _MobTrackingSetup: Record "MOB Tracking Setup"; _ItemTrackingSetup: Record "Item Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromPhysInvtRecordLine(var _MobTrackingSetup: Record "MOB Tracking Setup"; _PhysInvtRecordLine: Record "Phys. Invt. Record Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromRequestValues(var _MobTrackingSetup: Record "MOB Tracking Setup"; var _RequestValues: Record "MOB NS Request Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromRequestValuesIfRequired(var _MobTrackingSetup: Record "MOB Tracking Setup"; var _RequestValues: Record "MOB NS Request Element"; _ErrorIfNotExists: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromRequestContextValues(var _MobTrackingSetup: Record "MOB Tracking Setup"; var _RequestValues: Record "MOB NS Request Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromRegistration(var _MobTrackingSetup: Record "MOB Tracking Setup"; _Registration: Record "MOB WMS Registration")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromRegistrationIfRequired(var _MobTrackingSetup: Record "MOB Tracking Setup"; _Registration: Record "MOB WMS Registration")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromTestData(var _MobTrackingSetup: Record "MOB Tracking Setup"; _TestData: Record "MOB Test Data")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromTrackingByBinQueryIfRequired(var _MobTrackingSetup: Record "MOB Tracking Setup"; _MobWmsTrackingByBinQuery: Query "MOB WMS Tracking By Bin")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingToBaseOrderLine(var _BaseOrderLine: Record "MOB NS BaseDataModel Element"; _MobTrackingSetup: Record "MOB Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingToLookupResponse(var _LookupResponse: Record "MOB NS WhseInquery Element"; _MobTrackingSetup: Record "MOB Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingToLookupResponseAsDisplayTracking(var _LookupResponse: Record "MOB NS WhseInquery Element"; _MobTrackingSetup: Record "MOB Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingRequiredFromLookupResponse(var _MobTrackingSetup: Record "MOB Tracking Setup"; var _LookupResponse: Record "MOB NS WhseInquery Element"; _ErrorIfNotExists: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingRequiredToBaseOrderLine(var _BaseOrderLine: Record "MOB NS BaseDataModel Element"; _MobTrackingSetup: Record "MOB Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingRequiredToLookupResponse(var _LookupResponse: Record "MOB NS WhseInquery Element"; _MobTrackingSetup: Record "MOB Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterForItem(var _Item: Record Item; _MobTrackingSetup: Record "MOB Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterForItemIfRequired(var _Item: Record Item; _MobTrackingSetup: Record "MOB Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterNotEqualForItemLedgerEntryIfNotBlank(var _ItemLedgerEntry: Record "Item Ledger Entry"; _MobTrackingSetup: Record "MOB Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterForItemJnlLineIfNotBlank(var _ItemJnlLine: Record "Item Journal Line"; _MobTrackingSetup: Record "MOB Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterBlankForReservEntryIfNotBlank(var _ReservEntry: Record "Reservation Entry"; _MobTrackingSetup: Record "MOB Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterForReservEntryIfRequired(var _ReservEntry: Record "Reservation Entry"; _MobTrackingSetup: Record "MOB Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterForWhseJnlLineIfNotBlank(var _WhseJnlLine: Record "Warehouse Journal Line"; _MobTrackingSetup: Record "MOB Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateTrackingToWhseActLine(var _WhseActLine: Record "Warehouse Activity Line"; _MobTrackingSetup: Record "MOB Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateTrackingToWhseActLineIfRequired(var _WhseActLine: Record "Warehouse Activity Line"; _MobTrackingSetup: Record "MOB Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateTrackingToWhseItemTrackingLine(var _WhseItemTrackingLine: Record "Whse. Item Tracking Line"; _MobTrackingSetup: Record "MOB Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateTrackingToWhseJnlLineIfRequired(var _WhseJnlLine: Record "Warehouse Journal Line"; _MobTrackingSetup: Record "MOB Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromReservEntryIfNotBlank(var _MobTrackingSetup: Record "MOB Tracking Setup"; _ReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckTrackingOnInventoryIfNotBlank(_ItemNo: Code[20]; _VariantCode: Code[10]; _MobTrackingSetup: Record "MOB Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckTrackingOnInventoryIfRequired(_ItemNo: Code[20]; _VariantCode: Code[10]; _MobTrackingSetup: Record "MOB Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFormatTrackingOnAfterGetTrackingList(var _TrackingList: List of [Text]; _MobTrackingSetup: Record "MOB Tracking Setup"; _FormatExpr: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDetermineItemTrackingRequired(_WhseActLine: Record "Warehouse Activity Line"; var _MobTrackingSetup: Record "MOB Tracking Setup"; var _RegisterExpirationDate: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDetermineNegAdjustItemTrackingRequired(_ItemTrackingSetupInbound: Record "Item Tracking Setup"; _ItemTrackingSetupOutbound: Record "Item Tracking Setup"; var _MobTrackingSetup: Record "MOB Tracking Setup"; var _RegisterExpirationDate: Boolean)
    begin
    end;

}
