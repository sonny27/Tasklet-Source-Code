codeunit 81334 "MOB WMS Adhoc UnplannedMove"
{
    Access = Public;
    Permissions = tabledata "Whse. Item Tracking Line" = rimd;

    var
        MobItemReferenceMgt: Codeunit "MOB Item Reference Mgt.";
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
        MobToolbox: Codeunit "MOB Toolbox";
        WMSAdhocRegistr: Codeunit "MOB WMS Adhoc Registr.";
        MobItemJnlLineReserve: Codeunit "MOB Item Jnl. Line-Reserve";

    internal procedure CreateSteps(var _HeaderFilter: Record "MOB NS Request Element"; var _Steps: Record "MOB Steps Element") _ReturnRegistrationTypeTracking: Text
    var
        MobSetup: Record "MOB Setup";
        Item: Record Item;
        Bin: Record Bin;
        MobWmsLanguage: Codeunit "MOB WMS Language";
        FromBinCode: Code[20];
        LocationCode: Code[10];
        NewLocationCode: Code[10];
        ItemNumber: Code[50];
        VariantCode: Code[10];
        UoMCode: Code[10];
    begin
        // Find the Location, NewLocation, Bin and Item
        LocationCode := _HeaderFilter.GetValue('Location', true);
        NewLocationCode := _HeaderFilter.GetValue('NewLocation', true);
        FromBinCode := _HeaderFilter.GetValue('Bin');
        ItemNumber := MobItemReferenceMgt.SearchItemReference(MobToolbox.ReadEAN(_HeaderFilter.GetValue('ItemNumber', true)), VariantCode, UoMCode);

        // Set the tracking value displayed in the document queue
        _ReturnRegistrationTypeTracking := StrSubstNo('%1 - %2', LocationCode, ItemNumber);

        // Verify that the item exists
        if not Item.Get(ItemNumber) then
            Error(MobWmsLanguage.GetMessage('ITEM_NOT_FOUND'), ItemNumber);

        // Verify that the bin exists
        MobSetup.Get();
        if MobSetup."Unpl Move Show Info" and WMSAdhocRegistr.TestBinMandatory(LocationCode) then
            Bin.Get(LocationCode, FromBinCode);

        // Add the steps
        CreateUnplannedMoveSteps(_Steps, Item, LocationCode, NewLocationCode, FromBinCode, VariantCode, UoMCode);

    end;

    local procedure CreateUnplannedMoveSteps(var _Steps: Record "MOB Steps Element"; _Item: Record Item; _LocationCode: Code[10]; _NewLocationCode: Code[10]; _FromBinCode: Code[20]; _VariantCode: Code[10]; var _UoMCode: Code[10])
    var
        MobSetup: Record "MOB Setup";
        MobTrackingSetup: Record "MOB Tracking Setup";
        ItemVariant: Record "Item Variant";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        DummyRegisterExpirationDate: Boolean;
        HtmlTable: Text;
    begin
        MobSetup.Get();

        // If move is within the same Location, Item Tracking should only be collected if Warehouse Tracking is enabled
        Clear(MobTrackingSetup);
        if _LocationCode = _NewLocationCode then
            MobTrackingSetup.DetermineWhseTrackingRequired(_Item."No.", DummyRegisterExpirationDate)
        else
            MobTrackingSetup.DetermineTransferTrackingRequired(_Item."No.", DummyRegisterExpirationDate);
        // MobTrackingSetup.Tracking: Tracking values are unused in this scope

        // Step: "From Bin" (as 'Bin')
        if (_FromBinCode = '') and WMSAdhocRegistr.TestBinMandatory(_LocationCode) then
            _Steps.Create_TextStep_Bin(10, _LocationCode, _Item."No.", _VariantCode);

        // Step: "Available qty. to take"
        if MobSetup."Unpl Move Show Info" and WMSAdhocRegistr.TestBinMandatory(_LocationCode) and (_FromBinCode <> '') then begin
            // Info-step showing what can be moved
            HtmlTable := GetBinContentAsHtmlTable(_LocationCode, _FromBinCode, _Item."No.");
            _Steps.Create_InformationStep(20, 'Information');
            _Steps.Set_header(MobWmsLanguage.GetMessage('AVAILABLE_QTY_TO_TAKE'));
            _Steps.Set_helpLabel(HtmlTable);
        end;

        // Step: Variant
        if _VariantCode = '' then begin
            ItemVariant.Reset();
            ItemVariant.SetRange("Item No.", _Item."No.");
            if not ItemVariant.IsEmpty() then
                _Steps.Create_ListStep_Variant(30, _Item."No.");
        end;

        // Step: UoM
        if (not MobSetup."Use Base Unit of Measure") and (_UoMCode = '') then begin
            _Steps.Create_ListStep_UoM(40, _Item."No.");
            _Steps.Set_defaultValue(_Item."Base Unit of Measure");
            if not MobWmsToolbox.GetItemHasMultipleUoM(_Item."No.") then begin
                _UoMCode := _Item."Base Unit of Measure";
                _Steps.Set_visible(false);
            end;
        end;

        // Step: Quantity
        if not MobTrackingSetup."Serial No. Required" then begin
            _Steps.Create_DecimalStep_Quantity(50, _Item."No.");
            _Steps.Set_minValue(0.0000000001);

            // Show UoM in Quantity help
            if MobSetup."Use Base Unit of Measure" then
                _Steps.Set_helpLabel(MobWmsLanguage.GetMessage('UOM_LABEL') + ': ' + _Item."Base Unit of Measure")
            else
                if _UoMCode <> '' then
                    _Steps.Set_helpLabel(MobWmsLanguage.GetMessage('UOM_LABEL') + ': ' + _UoMCode);
        end;

        // Steps: LotNumber, SerialNumber, PackageNumber and custom tracking dimensions
        _Steps.Create_TrackingStepsIfRequired(MobTrackingSetup, 60, _Item."No.");

        // Step: ToBin
        if WMSAdhocRegistr.TestBinMandatory(_NewLocationCode) then
            _Steps.Create_TextStep_ToBin(100, _Item."No.");

    end;

    internal procedure PostRegistration(var _RequestValues: Record "MOB NS Request Element"; var _SuccessMessage: Text; var _ReturnRegistrationTypeTracking: Text)
    var
        MobSetup: Record "MOB Setup";
        MobTrackingSetup: Record "MOB Tracking Setup";
        Location: Record Location;
        ItemJnlLine: Record "Item Journal Line";
        WarehouseJnlLine: Record "Warehouse Journal Line";
        ReservationEntry: Record "Reservation Entry";
        ItemJnlLine2: Record "Item Journal Line";
        WMSMgt: Codeunit "WMS Management";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        LocationCode: Code[10];
        NewLocationCode: Code[10];
        FromBin: Code[20];
        ToBin: Code[20];
        ScannedBarcode: Code[50];
        ItemNumber: Code[50];
        VariantCode: Code[10];
        UoMCode: Code[10];
        Quantity: Decimal;
    begin
        Clear(MobTrackingSetup);
        MobSetup.Get();

        // The Unplanned Move feature expects 5 values
        // Location, NewLocationCode, FromBin, ToBin, Item and Quantity
        LocationCode := _RequestValues.GetValue('Location', true);
        NewLocationCode := _RequestValues.GetValue('NewLocation', true);
        FromBin := MobToolbox.ReadBin(_RequestValues.GetValue('Bin'));
        ToBin := MobToolbox.ReadBin(_RequestValues.GetValue('ToBin'));
        ScannedBarcode := _RequestValues.GetValue('ItemNumber', true);
        Quantity := _RequestValues.GetValueAsDecimal('Quantity');
        // MobTrackingSetup.TrackingRequired: Determine later when populating the WhseJnLine after a valid WhseJnlLine."Item No." has been found
        MobTrackingSetup.CopyTrackingFromRequestValues(_RequestValues);

        // Set Item, UoM and Variant from Barcode
        ItemNumber := MobItemReferenceMgt.SearchItemReference(ScannedBarcode, VariantCode, UoMCode);
        // Collected values have priority
        if _RequestValues.HasValue('UoM') then
            UoMCode := _RequestValues.GetValue('UoM');
        if _RequestValues.HasValue('Variant') then
            VariantCode := _RequestValues.GetValue('Variant');


        // Set the tracking value displayed in the document queue
        _ReturnRegistrationTypeTracking :=
            ItemJnlLine.FieldCaption("Location Code") + ' ' +
            LocationCode + ' ' +
            ItemJnlLine.FieldCaption("Item No.") + ' ' +
            ItemNumber + ' ' +
            ItemJnlLine.FieldCaption(Quantity) + ' ' +
            Format(Quantity);

        // When using Serial Number Quantity is always = 1
        if MobTrackingSetup."Serial No." <> '' then
            Quantity := 1;

        // Check Bin."Block Movement" as standard BC validation relies on "CurrFieldNo" from fields entered at Pages
        if WMSAdhocRegistr.TestBinMandatory(LocationCode) then
            WMSMgt.CheckInbOutbBin(LocationCode, FromBin, false);   // Check Bin."Block Movement" for Outbound
        if WMSAdhocRegistr.TestBinMandatory(NewLocationCode) then
            WMSMgt.CheckInbOutbBin(NewLocationCode, ToBin, true);   // Check Bin."Block Movement" for Inbound

        // Get the location and determine if it uses directed pick/put-away or not
        // When moving between different locations, both Item Journal and Warehouse Journal Posting is necessarry.
        Location.Get(LocationCode);
        if Location."Directed Put-away and Pick" and (LocationCode = NewLocationCode) then begin

            CreateWhseJnlLine(WarehouseJnlLine, MobTrackingSetup, LocationCode, FromBin, ToBin, ItemNumber, VariantCode, UoMCode, Quantity);

            WMSAdhocRegistr.OnPostAdhocRegistrationOnUnplannedMove_OnAfterCreateWhseJnlLine(_RequestValues, WarehouseJnlLine);

            // Post Warehouse Journal Line
            WMSAdhocRegistr.RegisterWhseJnlLine(WarehouseJnlLine, 4, false);
        end else begin
            // ------- Post both Item and Warehouse Jnl. -------

            // Step 1: Item Jnl.
            CreateItemJnlLine(ItemJnlLine, ReservationEntry, MobTrackingSetup, LocationCode, NewLocationCode, FromBin, ToBin, ItemNumber, VariantCode, UoMCode, Quantity);

            // Step 2: Warehouse Jnl.
            WMSAdhocRegistr.OnPostAdhocRegistrationOnUnplannedMove_OnAfterCreateItemJnlLine(_RequestValues, ReservationEntry, ItemJnlLine);

            WMSAdhocRegistr.PostItemJnlLine(ItemJnlLine, ItemJnlLine2);

            CreateAndRegisterWhseJnlLines(ItemJnlLine, ItemJnlLine2, ReservationEntry, MobTrackingSetup);
        end;

        _SuccessMessage := StrSubstNo(MobWmsLanguage.GetMessage('UNPL_MOVE_COMPLETED'), ItemNumber);
    end;

    /// <summary>    
    /// Retrieves the record in the "Source Code" table with Code 'MOBUNPMOVE'.
    /// If the record does not exist, it creates a new record with the specified code and description.
    /// </summary>
    /// <param name="_SourceCode">The returned "Source Code" record variable.</param>
    internal procedure GetSourceCode(var _SourceCode: Record "Source Code")
    var
        MobWmsLanguage: Codeunit "MOB WMS Language";
    begin
        if not _SourceCode.Get('MOBUNPMOVE') then begin
            _SourceCode.Code := 'MOBUNPMOVE';
            _SourceCode.Description := CopyStr(MobWmsLanguage.GetMessage('HANDHELD_UNPLANNED_MOVE'), 1, MaxStrLen(_SourceCode.Description));
            _SourceCode.Insert();
        end;
    end;

    internal procedure CreateWhseJnlLine(var _WhseJnlLine: Record "Warehouse Journal Line"; var _MobTrackingSetup: Record "MOB Tracking Setup"; _LocationCode: Code[10]; _FromBin: Code[20]; _ToBin: Code[20]; _ItemNumber: Code[50]; _VariantCode: Code[10]; _UoMCode: Code[10]; _Quantity: Decimal)
    var
        MobSetup: Record "MOB Setup";
        Location: Record Location;
        SourceCode: Record "Source Code";
        MobItemTrackingManagement: Codeunit "MOB Item Tracking Management";
        DummyRegisterExpirationDate: Boolean;
        ExpirationDate: Date;
        EntriesExist: Boolean;
    begin
        MobSetup.Get();
        Location.Get(_LocationCode);

        // Make sure that the MOBUNPMOVE source code exist (for tracking purposes)
        GetSourceCode(SourceCode);

        // Perform the posting using the Warehouse Item Journal
        // Set the template
        MobSetup.TestField("Move Whse. Jnl Template");
        _WhseJnlLine."Journal Template Name" := MobSetup."Move Whse. Jnl Template";

        // Set the batch name
        MobSetup.TestField("Unplanned Move Batch Name");
        _WhseJnlLine."Journal Batch Name" := MobSetup."Unplanned Move Batch Name";

        // Set the location code
        _WhseJnlLine."Location Code" := _LocationCode;

        // Create Warehouse Journal
        _WhseJnlLine.Validate("Registering Date", WorkDate());
        _WhseJnlLine."MOB GetWhseDocumentNo"(true);

        _WhseJnlLine.Validate("Source Code", SourceCode.Code);
        _WhseJnlLine.Validate("Whse. Document Type", _WhseJnlLine."Whse. Document Type"::"Whse. Journal");
        _WhseJnlLine.Validate("Entry Type", _WhseJnlLine."Entry Type"::Movement);
        _WhseJnlLine."User ID" := UserId();

        // Set the values from the mobile device
        _WhseJnlLine.Validate("Item No.", _ItemNumber);
        _WhseJnlLine.Validate("Variant Code", _VariantCode);
        _WhseJnlLine.Validate("From Bin Code", _FromBin);
        _WhseJnlLine.Validate("To Bin Code", _ToBin);
        if MobSetup."Use Base Unit of Measure" then
            _WhseJnlLine.Validate("Qty. (Base)", _Quantity)
        else begin
            _WhseJnlLine.Validate("Unit of Measure Code", _UoMCode);
            _WhseJnlLine.Validate(Quantity, _Quantity);
        end;

        // Wrapped in condition (LocationCode = NewLocationCode) meaning this part of code will always be WhseTracking and never TransferTracking
        _MobTrackingSetup.DetermineWhseTrackingRequired(_WhseJnlLine."Item No.", DummyRegisterExpirationDate);
        // MobTrackingSetup.Tracking: Copied before (during parse of RequestValues)

        // Validate LotNumber, SerialNumber, PackageNumber and custom tracking dimensions
        _MobTrackingSetup.ValidateTrackingToWhseJnlLineIfRequired(_WhseJnlLine);

        // If expiration date is used for either the serial or lot number then the new expiration date must match the old exp date            
        // Determine ExpDate from Whse. Entries to account for new entries that has not yet been posted to ItemLedgEntry from adj. bin
        EntriesExist :=
          MobItemTrackingManagement.GetWhseExpirationDate(
            _WhseJnlLine."Item No.",
            _WhseJnlLine."Variant Code",
            Location,
            _MobTrackingSetup,
            ExpirationDate);

        if EntriesExist then begin
            if _WhseJnlLine."Expiration Date" <> ExpirationDate then
                _WhseJnlLine."Expiration Date" := ExpirationDate;
            if _WhseJnlLine."New Expiration Date" <> ExpirationDate then
                _WhseJnlLine."New Expiration Date" := ExpirationDate;
        end;
    end;

    internal procedure CreateItemJnlLine(var _ItemJnlLine: Record "Item Journal Line"; var _ReservationEntry: Record "Reservation Entry"; var _MobTrackingSetup: Record "MOB Tracking Setup"; _LocationCode: Code[10]; _NewLocationCode: Code[10]; _FromBin: Code[20]; _ToBin: Code[20]; _ItemNumber: Code[50]; _VariantCode: Code[10]; _UoMCode: Code[10]; _Quantity: Decimal)
    var
        MobSetup: Record "MOB Setup";
        SourceCode: Record "Source Code";
        TempTrackingSpec: Record "Tracking Specification" temporary;
        MobTrackingSpecReserve: Codeunit "MOB Tracking Spec-Reserve";
        DummyRegisterExpirationDate: Boolean;
    begin
        MobSetup.Get();

        // Make sure that the MOBUNPMOVE source code exist (for tracking purposes)
        GetSourceCode(SourceCode);

        _ItemJnlLine.Init();
        _ItemJnlLine."Journal Template Name" := MobSetup."Move Item Jnl. Template";
        _ItemJnlLine."Journal Batch Name" := MobSetup."Unpl. Item Jnl Move Batch Name";

        _ItemJnlLine."Entry Type" := _ItemJnlLine."Entry Type"::Transfer;
        _ItemJnlLine.Validate("Item No.", _ItemNumber);
        _ItemJnlLine.Validate("Variant Code", _VariantCode);
        _ItemJnlLine.Validate("Posting Date", WorkDate());
        _ItemJnlLine."MOB GetDocumentNo"(true);
        _ItemJnlLine."Source Code" := SourceCode.Code;
        _ItemJnlLine.Validate("Location Code", _LocationCode);

        if WMSAdhocRegistr.TestBinMandatory(_LocationCode) then
            _ItemJnlLine.Validate("Bin Code", _FromBin);
        _ItemJnlLine.Validate("New Location Code", _NewLocationCode);
        if WMSAdhocRegistr.TestBinMandatory(_NewLocationCode) then
            _ItemJnlLine.Validate("New Bin Code", _ToBin);
        if MobSetup."Use Base Unit of Measure" then
            _ItemJnlLine.Validate(Quantity, _Quantity)
        else begin
            _ItemJnlLine.Validate("Unit of Measure Code", _UoMCode);
            _ItemJnlLine.Validate(Quantity, _Quantity);
        end;

        MobItemJnlLineReserve.InitFromItemJnlLine(TempTrackingSpec, _ItemJnlLine);

        Clear(_ReservationEntry);
        if _MobTrackingSetup.TrackingExists() then begin
            _MobTrackingSetup.CopyTrackingToTrackingSpec(TempTrackingSpec);
            TempTrackingSpec."Expiration Date" := 0D;

            // Determine if tracking registration is needed
            // Only verify against existing inventory if "Specific Tracking" is set
            _MobTrackingSetup.DetermineSpecificTrackingRequiredFromItemNo(TempTrackingSpec."Item No.", DummyRegisterExpirationDate);
            _MobTrackingSetup.CheckTrackingOnInventoryIfRequired(TempTrackingSpec."Item No.", TempTrackingSpec."Variant Code");

            MobTrackingSpecReserve.CreateReservation(TempTrackingSpec);
            MobTrackingSpecReserve.GetLastEntry(_ReservationEntry);
            _MobTrackingSetup.CopyTrackingFromReservEntry(_ReservationEntry);
        end;
    end;

    internal procedure CreateAndRegisterWhseJnlLines(var _ItemJnlLine: Record "Item Journal Line"; var _ItemJnlLine2: Record "Item Journal Line"; var _ReservationEntry: Record "Reservation Entry"; var _MobTrackingSetup: Record "MOB Tracking Setup")
    var
        MobSetup: Record "MOB Setup";
        Location: Record Location;
        WarehouseJnlLine: Record "Warehouse Journal Line";
        TempWhseJnlLine: Record "Warehouse Journal Line" temporary;
        ItemJournalTemplate: Record "Item Journal Template";
        WMSMgt: Codeunit "WMS Management";
    begin
        MobSetup.Get();

        if _ItemJnlLine."Location Code" <> '' then begin
            Location.Get(_ItemJnlLine."Location Code");
            if Location."Bin Mandatory" then begin
                _MobTrackingSetup.CopyTrackingToItemJnlLine(_ItemJnlLine2);
                _ItemJnlLine2."Item Expiration Date" := _ReservationEntry."Expiration Date";

                // Post Warehouse "Transfer From" 
                if WMSMgt.CreateWhseJnlLine(_ItemJnlLine2, MobToolbox.AsInteger(ItemJournalTemplate.Type::Transfer), TempWhseJnlLine, false) then begin
                    if Location."Directed Put-away and Pick" then begin
                        TempWhseJnlLine."Journal Template Name" := MobSetup."Move Whse. Jnl Template";
                        TempWhseJnlLine."Journal Batch Name" := MobSetup."Unplanned Move Batch Name";
                        TempWhseJnlLine.Validate("Whse. Document Type", WarehouseJnlLine."Whse. Document Type"::"Whse. Journal");
                        TempWhseJnlLine."MOB GetWhseDocumentNo"(true);

                        TempWhseJnlLine.Validate("From Zone Code", MobWmsToolbox.GetZoneFromBin(_ItemJnlLine2."Location Code", _ItemJnlLine2."Bin Code"));
                        TempWhseJnlLine.Validate("From Bin Code", _ItemJnlLine2."Bin Code");
                        // Validation deliberately not performed to avoid posting to adjustment bin
                        TempWhseJnlLine."To Zone Code" := '';
                        TempWhseJnlLine."To Bin Code" := '';
                    end;
                    WMSAdhocRegistr.RegisterWhseJnlLine(TempWhseJnlLine, 1, false);
                end;
            end;
        end;

        if _ItemJnlLine."New Location Code" <> '' then begin
            Location.Get(_ItemJnlLine."New Location Code");
            if Location."Bin Mandatory" then begin
                _MobTrackingSetup.CopyTrackingToItemJnlLine(_ItemJnlLine2);
                _ItemJnlLine2."Item Expiration Date" := _ReservationEntry."Expiration Date";

                // Post Warehouse "Transfer To"
                if WMSMgt.CreateWhseJnlLine(_ItemJnlLine2, MobToolbox.AsInteger(ItemJournalTemplate.Type::Transfer), TempWhseJnlLine, true) then begin
                    TempWhseJnlLine.Validate("Whse. Document Type", WarehouseJnlLine."Whse. Document Type"::"Whse. Journal");
                    TempWhseJnlLine."MOB GetWhseDocumentNo"(false);

                    if Location."Directed Put-away and Pick" then begin
                        TempWhseJnlLine."Journal Template Name" := MobSetup."Move Whse. Jnl Template";
                        TempWhseJnlLine."Journal Batch Name" := MobSetup."Unplanned Move Batch Name";
                        TempWhseJnlLine.Validate("To Zone Code", MobWmsToolbox.GetZoneFromBin(_ItemJnlLine2."New Location Code", _ItemJnlLine2."New Bin Code"));
                        TempWhseJnlLine.Validate("To Bin Code", _ItemJnlLine2."New Bin Code");
                        // Validation deliberately not performed to avoid posting to adjustment bin
                        TempWhseJnlLine."From Zone Code" := '';
                        TempWhseJnlLine."From Bin Type Code" := '';
                        TempWhseJnlLine."From Bin Code" := '';
                    end;
                    WMSAdhocRegistr.RegisterWhseJnlLine(TempWhseJnlLine, 1, true);
                end;
            end;
        end;

    end;

    //
    // ------- STEPS -------
    //

    local procedure GetBinContentAsHtmlTable(_LocationCode: Code[10]; _BinCode: Code[20]; ItemNo: Code[20]) _HtmlTable: Text
    var
        ItemVariant: Record "Item Variant";
        BinContent: Record "Bin Content";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        MobHtmlMgt: Codeunit "MOB HTML Management";
        VariantColumnText: Text;
        QtyAvailToTakeUoM: Decimal;
        HtmlRowAdded: Boolean;
    begin
        Clear(_HtmlTable);

        ItemVariant.Reset();
        ItemVariant.SetRange("Item No.", ItemNo);
        if not ItemVariant.IsEmpty() then
            VariantColumnText := MobWmsLanguage.GetMessage('VARIANT_LABEL');

        MobHtmlMgt.BeginFourColumnTable(_HtmlTable,
            MobWmsLanguage.GetMessage('UOM_LABEL'),         // Column A Header
            VariantColumnText,                              // Column B Header
            '',                                             // Column C Header
            MobWmsLanguage.GetMessage('AVAILABLE_QTY'));    // Column D Header

        BinContent.Reset();
        BinContent.SetRange("Location Code", _LocationCode);
        BinContent.SetRange("Bin Code", _BinCode);
        BinContent.SetRange("Item No.", ItemNo);
        if BinContent.FindSet() then
            repeat
                // Available qty. to take per Unit of Measure
                QtyAvailToTakeUoM := BinContent.CalcQtyAvailToTakeUOM();

                if QtyAvailToTakeUoM > 0 then begin
                    MobHtmlMgt.AddRowToFourColumnTable(_HtmlTable,
                                                        Format(BinContent."Unit of Measure Code"),                              // Column A Text
                                                        BinContent."Variant Code",                                              // Column B Text
                                                        '',                                                                     // Column C Text
                                                        MobWmsToolbox.Decimal2TextAsDisplayFormat(QtyAvailToTakeUoM, true));    // Column D Text
                    HtmlRowAdded := true;
                end;
            until BinContent.Next() = 0;

        if not HtmlRowAdded then
            MobHtmlMgt.AddRowToFourColumnTable(_HtmlTable, 'n/a', '', ' ', ' '); // Qty was zero

        MobHtmlMgt.EndTable(_HtmlTable);
    end;
}
