codeunit 82229 "MOB WMS Adhoc Unpl. Move Adv."
{
    Access = Public;
    Permissions = tabledata "Whse. Item Tracking Line" = rimd;

    var
        MobItemReferenceMgt: Codeunit "MOB Item Reference Mgt.";
        MobToolbox: Codeunit "MOB Toolbox";
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
        MobItemJnlLineReserve: Codeunit "MOB Item Jnl. Line-Reserve";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        ChangeLocationOnDirectedNotAllowedErr: Label 'Changing Location on a directed Location is not allowed';
        SameLicensePlateErr: Label 'The To License Plate must be different from the originating License Plate.';
        NotTopLevelWarningTxt: Label 'This License Plate is not top-level';
        RelatedPutawayExistErr: Label 'Related Put-away %1 exists for License Plate %2.\\You must use the function ''Put Away License Plate'' to move this License Plate.', Comment = '%1 is Putaway No. and %2 is License Plate No.';
        SpecificTrackingWithoutWhseTrackingDetectedErr: Label 'Specific Tracking without Warehouse Tracking detected in %1: %2 for Item %3.\\This is not supported when you want to add or remove License Plate Contents.', Comment = '%1 is TableCaption for Item Tracking Code, %2 is the Item Tracking Code value and %3 is Item No.';

    internal procedure CreateSteps(var _HeaderFilter: Record "MOB NS Request Element"; var _Steps: Record "MOB Steps Element") _ReturnRegistrationTypeTracking: Text
    var
        MobLicensePlate: Record "MOB License Plate";
        MobSetup: Record "MOB Setup";
        Number: Code[50];
    begin
        MobSetup.CheckLicensePlatingIsEnabled();

        // Number can represent either an Item No. or a License Plate No.
        Number := _HeaderFilter.Get_Number();

        if MobLicensePlate.Get(Number) then
            CreateStepsForLicensePlateMove(_HeaderFilter, _Steps, MobLicensePlate)
        else
            CreateStepsForItemMove(_HeaderFilter, _Steps, Number);
    end;

    local procedure CreateStepsForLicensePlateMove(var _HeaderFilter: Record "MOB NS Request Element"; var _Steps: Record "MOB Steps Element"; var _MobLicensePlate: Record "MOB License Plate")
    var
        PutAwayNo: Code[20];
    begin
        // Check that no related Put-away Document exists for the License Plate
        PutAwayNo := _MobLicensePlate.GetRelatedPutAwayNo();
        if PutAwayNo <> '' then
            Error(RelatedPutawayExistErr, PutAwayNo, _MobLicensePlate."No.");

        // We use a combined step to support both ToBin and ToLicensePlate
        _Steps.Create_TextStep_ToBinOrLP(10);
        _Steps.Set_helpLabel(GetDefaultOrSuggestedBinAsHtml(_MobLicensePlate, false, _HeaderFilter.GetValue('NewLocation', true)));
        _Steps.Save();
    end;

    local procedure CreateStepsForItemMove(var _HeaderFilter: Record "MOB NS Request Element"; var _Steps: Record "MOB Steps Element"; _Number: Code[50])
    var
        ItemVariant: Record "Item Variant";
        MobSetup: Record "MOB Setup";
        MobTrackingSetup: Record "MOB Tracking Setup";
        Item: Record Item;
        MobWmsAdhocRegistr: Codeunit "MOB WMS Adhoc Registr.";
        DummyRegisterExpirationDate: Boolean;
        LocationCode: Code[10];
        NewLocationCode: Code[10];
        VariantCode: Code[10];
        UoMCode: Code[10];
        ItemNumber: Code[50];
        LicensePlateNo: Code[20];
    begin
        MobSetup.Get();

        // Find the Location, NewLocation, Bin and Item
        LocationCode := _HeaderFilter.Get_Location(true);
        NewLocationCode := _HeaderFilter.GetValue('NewLocation', true);

        ItemNumber := MobItemReferenceMgt.SearchItemReference(MobToolbox.ReadEAN(_Number), VariantCode, UoMCode);

        // Verify that the item exists
        if not Item.Get(ItemNumber) then
            Error(MobWmsLanguage.GetMessage('ITEM_OR_LP_NOT_FOUND'), _Number);

        // If move is within the same Location, Item Tracking should only be collected if Warehouse Tracking is enabled
        Clear(MobTrackingSetup);
        if LocationCode = NewLocationCode then
            MobTrackingSetup.DetermineWhseTrackingRequired(Item."No.", DummyRegisterExpirationDate)
        else
            MobTrackingSetup.DetermineTransferTrackingRequired(Item."No.", DummyRegisterExpirationDate);

        // MobTrackingSetup.Tracking: Tracking values are unused in this scope

        // Step: "From BinOrLP"
        if MobWmsAdhocRegistr.TestBinMandatory(LocationCode) then begin
            _Steps.Create_TextStep_FromBinOrLP(10, LocationCode, Item."No.", VariantCode);

            // If Bin exist as context value, then set it as default value for From Bin Step
            _Steps.Set_defaultValue(_HeaderFilter.GetContextValue('Bin'));

            // If License Plate exist as context value, then overwrite default value based on Bin on this combined step
            LicensePlateNo := _HeaderFilter.GetContextValue('LicensePlate');
            if LicensePlateNo <> '' then begin
                _Steps.Set_defaultValue(LicensePlateNo);
                _Steps.Set_helpLabel('');
            end;
        end;

        // Step: Variant
        if VariantCode = '' then begin
            ItemVariant.Reset();
            ItemVariant.SetRange("Item No.", Item."No.");
            if not ItemVariant.IsEmpty() then
                _Steps.Create_ListStep_Variant(20, Item."No.");
        end;

        // Step: UoM
        if (not MobSetup."Use Base Unit of Measure") and (UoMCode = '') then begin
            _Steps.Create_ListStep_UoM(30, Item."No.");
            _Steps.Set_defaultValue(Item."Base Unit of Measure");
            if not MobWmsToolbox.GetItemHasMultipleUoM(Item."No.") then begin
                UoMCode := Item."Base Unit of Measure";
                _Steps.Set_visible(false);
            end;
        end;

        // Step: Quantity
        if not MobTrackingSetup."Serial No. Required" then begin
            _Steps.Create_DecimalStep_Quantity(40, Item."No.");
            _Steps.Set_minValue(0.0000000001);
            // Show UoM in Quantity help
            if MobSetup."Use Base Unit of Measure" then
                _Steps.Set_helpLabel(MobWmsLanguage.GetMessage('UOM_LABEL') + ': ' + Item."Base Unit of Measure")
            else
                if UoMCode <> '' then
                    _Steps.Set_helpLabel(MobWmsLanguage.GetMessage('UOM_LABEL') + ': ' + UoMCode);
        end;

        // Steps: LotNumber, SerialNumber, PackageNumber and custom tracking dimensions
        _Steps.Create_TrackingStepsIfRequired(MobTrackingSetup, 50, Item."No.");

        // Step: We use a combined step to support both ToBin and ToLicensePlate        
        if MobWmsAdhocRegistr.TestBinMandatory(NewLocationCode) then
            _Steps.Create_TextStep_ToBinOrLP(100);
    end;

    internal procedure PostRegistration(var _RequestValues: Record "MOB NS Request Element"; var _SuccessMessage: Text; var _ReturnRegistrationTypeTracking: Text)
    var
        MobLicensePlate: Record "MOB License Plate";
        MobSetup: Record "MOB Setup";
    begin
        MobSetup.CheckLicensePlatingIsEnabled();

        // If the scanned Number is a License Plate. We move the License Plate and its contents
        if MobLicensePlate.Get(_RequestValues.Get_Number()) then
            PostLicensePlateMove(_RequestValues, _SuccessMessage, _ReturnRegistrationTypeTracking)

        else begin
            // Update License Plate contents based on the Item that has been moved
            UpdateLicensePlateContent(_RequestValues);

            // Item is registered from the header, meaning we are moving an Item
            // Handle the Unplanned Move and Jnl. Posting of an Item
            PostItemMove(_RequestValues, _SuccessMessage, _ReturnRegistrationTypeTracking);
        end;
    end;

    local procedure PostLicensePlateMove(var _RequestValues: Record "MOB NS Request Element"; var _SuccessMessage: Text; var _ReturnRegistrationTypeTracking: Text)
    var
        MobLicensePlate: Record "MOB License Plate";
        ToMobLicensePlate: Record "MOB License Plate";
        Location: Record Location;
        Number: Code[50];
        NewLocationCode: Code[10];
        ToBin: Code[20];
        ToBinOrLp: Code[20];
    begin
        Number := _RequestValues.Get_Number(true);
        NewLocationCode := _RequestValues.GetValue('NewLocation', true);
        ToBinOrLp := _RequestValues.Get_ToBinOrLP();

        // Get License Plate to move
        MobLicensePlate.Get(Number);

        // Check License Plates, update content and find the To Bin
        if ToMobLicensePlate.Get(ToBinOrLp) then begin
            if MobLicensePlate."No." = ToMobLicensePlate."No." then
                Error(SameLicensePlateErr);

            MobLicensePlate.MoveToLicensePlate(ToMobLicensePlate);

            ToMobLicensePlate.TestField("Location Code", NewLocationCode); // TODO: We could add support for reset License Plates with blank Location Code, but it requires the To Bin Code
            ToBin := ToMobLicensePlate."Bin Code";
        end else begin
            // If the To License Plate is not found, then the ToBinOrLP is a Bin Code
            ToBin := ToBinOrLp;

            //Remove License Plate from parent License Plate, if it is included in another License Plate
            MobLicensePlate.DeleteAsContent();
        end;

        // If License Plate has been moved to a different Bin, then we must post using journals
        if (MobLicensePlate."Location Code" <> NewLocationCode) or (MobLicensePlate."Bin Code" <> ToBin) then begin
            // Get the location and determine if it uses directed pick/put-away or not
            Location.Get(MobLicensePlate."Location Code");
            if Location."Directed Put-away and Pick" then begin
                if Location.Code <> NewLocationCode then
                    Error(ChangeLocationOnDirectedNotAllowedErr);

                PostWhseJournalLicensePlateMove(MobLicensePlate, ToBin);
            end else begin
                Location.TestField("Bin Mandatory");

                PostItemJournalLicensePlateMove(MobLicensePlate, NewLocationCode, ToBin);
            end;

            // Update License Plate with new values for Location Code and Bin Code
            if Location.Code <> NewLocationCode then
                MobLicensePlate.Validate("Location Code", NewLocationCode);

            MobLicensePlate.Validate("Bin Code", ToBin);
            MobLicensePlate.Modify(true);
        end;

        // Set the tracking value displayed in the document queue
        _ReturnRegistrationTypeTracking :=
            MobLicensePlate.TableCaption() + ' ' +
            MobLicensePlate."No." + ' -> ' +
            ToMobLicensePlate.TableCaption() + ' ' +
            ToMobLicensePlate."No." + ' ';

        if ToMobLicensePlate."No." <> '' then
            _SuccessMessage := StrSubstNo(MobWmsLanguage.GetMessage('UNPL_MOVE_ADV_COMPLETED'), MobWmsLanguage.GetMessage('LP'), Number, MobWmsLanguage.GetMessage('LP'), ToMobLicensePlate."No.") // LP -> LP
        else
            _SuccessMessage := StrSubstNo(MobWmsLanguage.GetMessage('UNPL_MOVE_ADV_COMPLETED'), MobWmsLanguage.GetMessage('LP'), Number, MobWmsLanguage.GetMessage('BIN'), ToBin) // LP -> Bin
    end;

    local procedure PostItemMove(var _RequestValues: Record "MOB NS Request Element"; var _SuccessMessage: Text; var _ReturnRegistrationTypeTracking: Text)
    var
        ItemJnlLine2: Record "Item Journal Line";
        ItemJnlLine: Record "Item Journal Line";
        Location: Record Location;
        ToMobLicensePlate: Record "MOB License Plate";
        MobTrackingSetup: Record "MOB Tracking Setup";
        ReservationEntry: Record "Reservation Entry";
        WarehouseJnlLine: Record "Warehouse Journal Line";
        WMSAdhocRegistr: Codeunit "MOB WMS Adhoc Registr.";
        WMSAdhocUnplannedMove: Codeunit "MOB WMS Adhoc UnplannedMove";
        WMSMgt: Codeunit "WMS Management";
        LocationCode: Code[10];
        NewLocationCode: Code[10];
        Number: Code[50];
        ItemNumber: Code[50];
        UoMCode: Code[10];
        VariantCode: Code[10];
        Quantity: Decimal;
        FromBin: Code[20];
        ToBin: Code[20];
    begin
        // Identify the Bin Values that can be either Bin Codes or License Plate.Bin Codes
        GetFromBinAndToBinValues(_RequestValues, FromBin, ToBin);

        if ToMobLicensePlate.Get(_RequestValues.Get_ToBinOrLP()) then; // TODO: Consolidate usage of Get_ToBinOrLP and Get_FromBinOrLP to return record variables

        // Read values from the Request Values and assign to local variables        
        LocationCode := _RequestValues.Get_Location(true);
        NewLocationCode := _RequestValues.GetValue('NewLocation', true);

        // 'Number' is now determined to be Item No.
        Number := _RequestValues.Get_Number(true);

        // MobTrackingSetup.TrackingRequired: Determine later when populating the WhseJnLine after a valid WhseJnlLine."Item No." has been found
        MobTrackingSetup.CopyTrackingFromRequestValues(_RequestValues);

        // When using Serial Number Quantity is always = 1
        if MobTrackingSetup."Serial No." = '' then
            Quantity := _RequestValues.Get_Quantity()
        else
            Quantity := 1;

        // Set Item, UoM and Variant from Barcode
        ItemNumber := MobItemReferenceMgt.SearchItemReference(Number, VariantCode, UoMCode);

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

        // Check Bin."Block Movement" as standard BC validation relies on "CurrFieldNo" from fields entered at Pages
        if WMSAdhocRegistr.TestBinMandatory(LocationCode) then
            WMSMgt.CheckInbOutbBin(LocationCode, FromBin, false);   // Check Bin."Block Movement" for Outbound
        if WMSAdhocRegistr.TestBinMandatory(NewLocationCode) then
            WMSMgt.CheckInbOutbBin(NewLocationCode, ToBin, true);   // Check Bin."Block Movement" for Inbound

        // Get the location and determine if it uses directed pick/put-away or not
        // When moving between different locations, both Item Journal and Warehouse Journal Posting is necessarry.
        Location.Get(LocationCode);
        if Location."Directed Put-away and Pick" and (LocationCode = NewLocationCode) then begin

            WMSAdhocUnplannedMove.CreateWhseJnlLine(WarehouseJnlLine, MobTrackingSetup, LocationCode, FromBin, ToBin, ItemNumber, VariantCode, UoMCode, Quantity);

            // Post Warehouse Journal Line
            WMSAdhocRegistr.RegisterWhseJnlLine(WarehouseJnlLine, 4, false);
        end else begin
            // ------- Post both Item and Warehouse Jnl. -------

            // Step 1: Item Jnl.
            WMSAdhocUnplannedMove.CreateItemJnlLine(ItemJnlLine, ReservationEntry, MobTrackingSetup, LocationCode, NewLocationCode, FromBin, ToBin, ItemNumber, VariantCode, UoMCode, Quantity);
            WMSAdhocRegistr.PostItemJnlLine(ItemJnlLine, ItemJnlLine2);

            // Step 2: Warehouse Jnl.            
            WMSAdhocUnplannedMove.CreateAndRegisterWhseJnlLines(ItemJnlLine, ItemJnlLine2, ReservationEntry, MobTrackingSetup);
        end;

        if ToMobLicensePlate."No." <> '' then
            _SuccessMessage := StrSubstNo(MobWmsLanguage.GetMessage('UNPL_MOVE_ADV_COMPLETED'), MobWmsLanguage.GetMessage('ITEM'), Number, MobWmsLanguage.GetMessage('LP'), ToMobLicensePlate."No.") // Item -> LP
        else
            _SuccessMessage := StrSubstNo(MobWmsLanguage.GetMessage('UNPL_MOVE_ADV_COMPLETED'), MobWmsLanguage.GetMessage('ITEM'), Number, MobWmsLanguage.GetMessage('BIN'), ToBin) // Item -> Bin
    end;

    local procedure GetFromBinAndToBinValues(var _RequestValues: Record "MOB NS Request Element"; var _FromBin: Code[20]; var _ToBin: Code[20])
    var
        FromMobLicensePlate: Record "MOB License Plate";
        ToMobLicensePlate: Record "MOB License Plate";
        MobFeatureTelemetryWrapper: Codeunit "MOB Feature Telemetry Wrapper";
        MobTelemetryEventId: Enum "MOB Telemetry Event ID";
        FromBinOrLP: Code[20];
        ToBinOrToLP: Code[20];
    begin
        FromBinOrLP := _RequestValues.Get_FromBinOrLP();
        ToBinOrToLP := _RequestValues.Get_ToBinOrLP();

        // If the From License Plate is found, then the content is deleted
        if FromMobLicensePlate.Get(FromBinOrLP) then
            _FromBin := FromMobLicensePlate."Bin Code"
        else
            _FromBin := FromBinOrLP;

        // If the To License Plate is found, then the content is created
        if ToMobLicensePlate.Get(ToBinOrToLP) then
            _ToBin := ToMobLicensePlate."Bin Code"
        else
            _ToBin := ToBinOrToLP;

        if (FromMobLicensePlate."No." <> '') or (ToMobLicensePlate."No." <> '') then begin
            if FromMobLicensePlate."No." = ToMobLicensePlate."No." then
                Error(SameLicensePlateErr);

            // Logging uptake telemetry for used LP feature
            MobFeatureTelemetryWrapper.LogUptakeUsed(MobTelemetryEventId::"License Plating - Unplanned Move with LP (MOB1080)");
            MobFeatureTelemetryWrapper.LogUptakeUsed(MobTelemetryEventId::"License Plating (MOB1050)");
        end
    end;

    local procedure PostWhseJournalLicensePlateMove(var _MobLicensePlate: Record "MOB License Plate"; _ToBinCode: Code[20])
    var
        Location: Record Location;
        MobSetup: Record "MOB Setup";
        WhseJnlLine2: Record "Warehouse Journal Line";
        WhseJnlLine: Record "Warehouse Journal Line";
        WhseJnlRegisterBatch: Codeunit "Whse. Jnl.-Register Batch";
        MobSetSuppressCommit: Codeunit "MOB Set Suppress Commit";
        NextLineNo: Integer;
    begin
        // The Unplanned Move feature expects 5 values
        // Location, FromBin, ToBin (then Item and Quantity is derived based on these values)
        // The values are added to the relevant journal if they have been registered on the mobile device

        // Get the Mobile WMS configuration
        MobSetup.Get();

        // Get the location and determine if it uses directed pick/put-away or not
        Location.Get(_MobLicensePlate."Location Code");

        MobSetup.TestField("Move Whse. Jnl Template");
        MobSetup.TestField("Unplanned Move Batch Name");
        WhseJnlLine2.SetRange("Journal Template Name", MobSetup."Move Whse. Jnl Template");
        WhseJnlLine2.SetRange("Journal Batch Name", MobSetup."Unplanned Move Batch Name");
        if WhseJnlLine2.FindLast() then
            NextLineNo := WhseJnlLine2."Line No." + 10000
        else
            NextLineNo := 10000;

        AddLicensePlateContentsToWhseJournal(_MobLicensePlate, _ToBinCode, NextLineNo, WhseJnlLine);

        WhseJnlLine.MarkedOnly(true);
        // Perform the posting using the Warehouse Journal
        WhseJnlLine.SetRange("Journal Template Name", MobSetup."Move Whse. Jnl Template");
        WhseJnlLine.SetRange("Journal Batch Name", MobSetup."Unplanned Move Batch Name");
        WhseJnlLine.SetFilter("Item No.", '<>%1', '');
        if WhseJnlLine.FindFirst() then begin
            BindSubscription(MobSetSuppressCommit); // Using manual binding to set SurpressCommit, as WhseJnlRegisterBatch.SetSuppressCommit() isn't available until BC20
            WhseJnlRegisterBatch.Run(WhseJnlLine);
            UnbindSubscription(MobSetSuppressCommit);
        end else
            Error(MobWmsLanguage.GetMessage('NOTHING_TO_REGISTER'));
    end;

    local procedure AddLicensePlateContentsToWhseJournal(var _MobLicensePlate: Record "MOB License Plate"; _ToBinCode: Code[20]; var _NextLineNo: Integer; var _WhseJnlLine: Record "Warehouse Journal Line")
    var
        MobLicensePlateChild: Record "MOB License Plate";
        MobLicensePlateContent: Record "MOB License Plate Content";
        MobSetup: Record "MOB Setup";
        MobWhseTrackingSetup: Record "MOB Tracking Setup";
        SourceCode: Record "Source Code";
        MobItemTrackingManagement: Codeunit "MOB Item Tracking Management";
        WMSAdhocRegistr: Codeunit "MOB WMS Adhoc Registr.";
        MobWMSAdhocUnplannedMove: Codeunit "MOB WMS Adhoc UnplannedMove";
        EntriesExist: Boolean;
        RegisterExpirationDate: Boolean;
        ExpirationDate: Date;
    begin
        MobSetup.Get();

        // Get the Source Code for the MOBUNPMOVE
        MobWMSAdhocUnplannedMove.GetSourceCode(SourceCode);

        MobLicensePlateContent.SetRange("License Plate No.", _MobLicensePlate."No.");
        MobLicensePlateContent.FindSet();
        repeat
            if MobLicensePlateContent."Type" = MobLicensePlateContent.Type::"License Plate" then begin
                MobLicensePlateChild.Get(MobLicensePlateContent."No.");
                AddLicensePlateContentsToWhseJournal(MobLicensePlateChild, _ToBinCode, _NextLineNo, _WhseJnlLine);
            end else begin
                _WhseJnlLine.Init();
                _WhseJnlLine."Journal Template Name" := MobSetup."Move Whse. Jnl Template";
                _WhseJnlLine."Journal Batch Name" := MobSetup."Unplanned Move Batch Name";
                _WhseJnlLine."Location Code" := MobLicensePlateContent."Location Code";
                _WhseJnlLine."Line No." := _NextLineNo;
                _NextLineNo += 10000;

                // Create Warehouse Journal
                _WhseJnlLine.Validate("Registering Date", WorkDate());
                _WhseJnlLine.Validate("Source Code", SourceCode.Code);
                _WhseJnlLine.Validate("Whse. Document Type", _WhseJnlLine."Whse. Document Type"::"Whse. Journal");
                _WhseJnlLine."MOB GetWhseDocumentNo"(false); // Dont modify No. Series, as "Whse Jnl Register Batch" must be able to validate same number
                _WhseJnlLine.Validate("Entry Type", _WhseJnlLine."Entry Type"::Movement);
                _WhseJnlLine."User ID" := UserId();

                // Set the values from the mobile device
                _WhseJnlLine.Validate("Item No.", MobLicensePlateContent."No.");
                _WhseJnlLine.Validate("Variant Code", MobLicensePlateContent."Variant Code");
                _WhseJnlLine.Validate("From Bin Code", _MobLicensePlate."Bin Code");
                _WhseJnlLine.Validate("To Bin Code", _ToBinCode);
                _WhseJnlLine.Validate("Unit of Measure Code", MobLicensePlateContent."Unit Of Measure Code");
                _WhseJnlLine.Validate(Quantity, MobLicensePlateContent.Quantity);

                // Todo: MobWhseTrackingSetup.CopyTrackingFromLicensePlateContent(MobLicensePlateContent);
                // Todo: MobWhseTrackingSetup.ValidateTrackingToWhseJnlLineIfRequired(WhseJnlLine);
                MobWhseTrackingSetup.DetermineWhseTrackingRequired(MobLicensePlateContent."No.", RegisterExpirationDate);

                // Add Item Tracking from the License Plate Content if Warehouse tracking is used
                if MobWhseTrackingSetup.TrackingRequired() then begin
                    if MobLicensePlateContent."Lot No." <> '' then
                        _WhseJnlLine.Validate("Lot No.", MobLicensePlateContent."Lot No.");
                    if MobLicensePlateContent."Serial No." <> '' then
                        _WhseJnlLine.Validate("Serial No.", MobLicensePlateContent."Serial No.");

                    /* #if BC18+ */
                    if MobLicensePlateContent."Package No." <> '' then
                        _WhseJnlLine.Validate("Package No.", MobLicensePlateContent."Package No.");
                    /* #endif */
                end;

                // If expiration date is used for either the serial or lot number then the new expiration date
                // must match the old exp date
                if RegisterExpirationDate then begin
                    ExpirationDate :=
                        MobItemTrackingManagement.ExistingExpirationDate(
                            _WhseJnlLine."Item No.",
                            _WhseJnlLine."Variant Code",
                            MobWhseTrackingSetup,
                            false,
                            EntriesExist);

                    _WhseJnlLine."Expiration Date" := ExpirationDate;
                    _WhseJnlLine."New Expiration Date" := ExpirationDate;
                end;

                _WhseJnlLine.Insert(true);
                _WhseJnlLine.Mark(true);
                WMSAdhocRegistr.InsertWhseItemTracking(_WhseJnlLine);
            end;
        until MobLicensePlateContent.Next() = 0;
    end;

    local procedure PostItemJournalLicensePlateMove(var _MobLicensePlate: Record "MOB License Plate"; _ToLocationCode: Code[10]; _ToBinCode: Code[20])
    var
        ItemJnlLine2: Record "Item Journal Line";
        ItemJnlLine: Record "Item Journal Line";
        MobSetup: Record "MOB Setup";
        SourceCode: Record "Source Code";
        ItemJnlPostBatch: Codeunit "Item Jnl.-Post Batch";
        MobWMSAdhocUnplannedMove: Codeunit "MOB WMS Adhoc UnplannedMove";
        LastExistingLineNo: Integer;
        NextLineNo: Integer;
    begin
        // Get the Source Code for the MOBUNPMOVE        
        MobWMSAdhocUnplannedMove.GetSourceCode(SourceCode);

        // Get the Mobile WMS configuration
        MobSetup.Get();

        // Perform the posting using the standard journal
        MobSetup.TestField("Move Item Jnl. Template");
        MobSetup.TestField("Unpl. Item Jnl Move Batch Name");

        ItemJnlLine2.SetRange("Journal Template Name", MobSetup."Move Item Jnl. Template");
        ItemJnlLine2.SetRange("Journal Batch Name", MobSetup."Unpl. Item Jnl Move Batch Name");
        if ItemJnlLine2.FindLast() then begin
            LastExistingLineNo := ItemJnlLine2."Line No.";
            NextLineNo := LastExistingLineNo + 10000;
        end else
            NextLineNo := 10000;

        AddLicensePlateContentsToItemJournal(_MobLicensePlate, _ToLocationCode, _ToBinCode, NextLineNo, ItemJnlLine);

        ItemJnlLine.SetRange("Journal Template Name", MobSetup."Move Item Jnl. Template");
        ItemJnlLine.SetRange("Journal Batch Name", MobSetup."Unpl. Item Jnl Move Batch Name");
        ItemJnlLine.SetFilter("Item No.", '<>%1', '');
        // Filter to new records only
        if LastExistingLineNo <> 0 then
            ItemJnlLine.SetFilter("Line No.", '>%1', LastExistingLineNo);
        if ItemJnlLine.FindFirst() then begin
            ItemJnlPostBatch.SetSuppressCommit(true);
            ItemJnlPostBatch.Run(ItemJnlLine);
        end else
            Error(MobWmsLanguage.GetMessage('NOTHING_TO_REGISTER'));
    end;

    local procedure AddLicensePlateContentsToItemJournal(var _MobLicensePlate: Record "MOB License Plate"; _ToLocationCode: Code[10]; _ToBinCode: Code[20]; var _NextLineNo: Integer; var _ItemJnlLine: Record "Item Journal Line")
    var
        MobLicensePlateChild: Record "MOB License Plate";
        MobLicensePlateContent: Record "MOB License Plate Content";
        MobSetup: Record "MOB Setup";
        MobTrackingSetup: Record "MOB Tracking Setup";
        ReservationEntry: Record "Reservation Entry";
        TempTrackingSpec: Record "Tracking Specification" temporary;
        SourceCode: Record "Source Code";
        MobTrackingSpecReserve: Codeunit "MOB Tracking Spec-Reserve";
        MobWMSAdhocUnplannedMove: Codeunit "MOB WMS Adhoc UnplannedMove";
    begin
        MobSetup.Get();

        // Get the Source Code for the MOBUNPMOVE
        MobWMSAdhocUnplannedMove.GetSourceCode(SourceCode);

        MobLicensePlateContent.SetRange("License Plate No.", _MobLicensePlate."No.");
        MobLicensePlateContent.FindSet();
        repeat
            if MobLicensePlateContent."Type" = MobLicensePlateContent.Type::"License Plate" then begin
                MobLicensePlateChild.Get(MobLicensePlateContent."No.");
                AddLicensePlateContentsToItemJournal(MobLicensePlateChild, _ToLocationCode, _ToBinCode, _NextLineNo, _ItemJnlLine);
            end else begin
                _ItemJnlLine.Init();
                _ItemJnlLine.Validate("Journal Template Name", MobSetup."Move Item Jnl. Template");
                _ItemJnlLine.Validate("Journal Batch Name", MobSetup."Unpl. Item Jnl Move Batch Name");
                _ItemJnlLine.Validate("Entry Type", _ItemJnlLine."Entry Type"::Transfer);
                _ItemJnlLine.Validate("Posting Date", WorkDate());
                _ItemJnlLine."MOB GetDocumentNo"(false);
                _ItemJnlLine.Validate("Source Code", SourceCode.Code);
                _ItemJnlLine."Line No." := _NextLineNo;
                _NextLineNo += 10000;

                // Set the values from the mobile device
                _ItemJnlLine.Validate("Item No.", MobLicensePlateContent."No.");
                _ItemJnlLine.Validate("Variant Code", MobLicensePlateContent."Variant Code");
                _ItemJnlLine.Validate("Location Code", MobLicensePlateContent."Location Code");
                _ItemJnlLine.Validate("Bin Code", MobLicensePlateContent."Bin Code");
                _ItemJnlLine.Validate("New Location Code", _ToLocationCode);
                _ItemJnlLine.Validate("New Bin Code", _ToBinCode);
                _ItemJnlLine.Validate("Unit of Measure Code", MobLicensePlateContent."Unit Of Measure Code");
                _ItemJnlLine.Validate(Quantity, MobLicensePlateContent.Quantity);
                _ItemJnlLine.Insert(true);

                // Todo: MobTrackingSetup.CopyTrackingFromLicensePlateContent(MobLicensePlateContent);
                MobTrackingSetup."Lot No." := MobLicensePlateContent."Lot No.";
                MobTrackingSetup."Serial No." := MobLicensePlateContent."Serial No.";
                MobTrackingSetup."Package No." := MobLicensePlateContent."Package No.";

                MobItemJnlLineReserve.InitFromItemJnlLine(TempTrackingSpec, _ItemJnlLine);
                Clear(ReservationEntry);
                if MobTrackingSetup.TrackingExists() then begin
                    MobTrackingSetup.CopyTrackingToTrackingSpec(TempTrackingSpec);
                    TempTrackingSpec."Expiration Date" := 0D;

                    MobTrackingSpecReserve.CreateReservation(TempTrackingSpec);
                    MobTrackingSpecReserve.GetLastEntry(ReservationEntry);
                    MobTrackingSetup.CopyTrackingFromReservEntry(ReservationEntry);
                end;
            end;
        until MobLicensePlateContent.Next() = 0;
    end;

    // ## License Plate related Procedures ##

    internal procedure UpdateLicensePlateContent(var _RequestValues: Record "MOB NS Request Element")
    var
        FromMobLicensePlate: Record "MOB License Plate";
        ToMobLicensePlate: Record "MOB License Plate";
        LocationCode: Code[10];
        NewLocationCode: Code[10];
        FromBinOrLP: Code[20];
        ToBinOrToLP: Code[20];
    begin
        LocationCode := _RequestValues.Get_Location(true);
        NewLocationCode := _RequestValues.GetValue('NewLocation', true);
        FromBinOrLP := _RequestValues.Get_FromBinOrLP();
        ToBinOrToLP := _RequestValues.Get_ToBinOrLP();

        // If the From License Plate is found, then the content is deleted
        if FromMobLicensePlate.Get(FromBinOrLP) then begin
            FromMobLicensePlate.TestField("Location Code", LocationCode);

            // It´s only allowed to remove content from a License Plate if it is not related to a Whse. Document
            FromMobLicensePlate.TestField("Whse. Document No.", '');

            DeleteLicensePlateContent(_RequestValues, FromMobLicensePlate);
        end;

        // If the To License Plate is found, then the content is created
        if ToMobLicensePlate.Get(ToBinOrToLP) then begin
            ToMobLicensePlate.TestField("Location Code", NewLocationCode);

            // It´s only allowed to add content to a License Plate if it is not related to a Whse. Document
            ToMobLicensePlate.TestField("Whse. Document No.", '');

            CreateLicensePlateContent(_RequestValues, ToMobLicensePlate);
        end;
    end;

    internal procedure CreateLicensePlateContent(var _RequestValues: Record "MOB NS Request Element"; _MobLicensePlate: Record "MOB License Plate")
    var
        MobSetup: Record "MOB Setup";
        Item: Record Item;
        MobLicensePlateContent: Record "MOB License Plate Content";
        MobTrackingSetup: Record "MOB Tracking Setup";
        ItemNumber: Code[50];
        ScannedBarcode: Code[50];
        UoMCode: Code[20];
        VariantCode: Code[10];
        Quantity: Decimal;
    begin
        MobSetup.Get();

        ScannedBarcode := _RequestValues.Get_Number();
        if ScannedBarcode = '' then
            ScannedBarcode := _RequestValues.GetValueOrContextValue('ItemNumber');

        MobTrackingSetup.CopyTrackingFromRequestValues(_RequestValues);

        // When using Serial Number Quantity is always = 1
        if MobTrackingSetup."Serial No." = '' then
            Quantity := _RequestValues.Get_Quantity()
        else
            Quantity := 1;

        // Avoid creating a license plate if quantity is 0
        if Quantity = 0 then
            exit;

        // Set Item, UoM and Variant from Barcode
        ItemNumber := MobItemReferenceMgt.SearchItemReference(ScannedBarcode, VariantCode, UoMCode);

        // Check if specific tracking and Warehouse Tracking are enabled because it is required to add/remove content
        CheckSpecificWarehouseTrackingIsEnabled(ItemNumber);

        // Collected values have priority and should only be used if avaliable in the Request Values. 
        // Otherwise use the values from the Barcode identified above in SearchItemReference
        if _RequestValues.HasValue('UoM') then
            UoMCode := _RequestValues.GetValue('UoM');

        if (UoMCode = '') or (MobTrackingSetup."Serial No." <> '') or MobSetup."Use Base Unit of Measure" then begin
            Item.Get(ItemNumber);
            UoMCode := Item."Base Unit of Measure";
        end;

        if _RequestValues.HasValue('Variant') then
            VariantCode := _RequestValues.GetValue('Variant');

        // Create the new License Plate Content
        MobLicensePlateContent.Init();
        MobLicensePlateContent.SetValuesFromLicensePlate(_MobLicensePlate."No.");
        MobLicensePlateContent.Validate(Type, MobLicensePlateContent.Type::Item);
        MobLicensePlateContent.Validate("No.", ItemNumber);
        MobLicensePlateContent.Validate("Variant Code", VariantCode);
        MobLicensePlateContent.Validate("Unit Of Measure Code", UoMCode);
        MobLicensePlateContent.Validate(Quantity, Quantity);
        MobLicensePlateContent.SetTracking(MobTrackingSetup);

        // Add the new License Plate Content to the License Plate
        _MobLicensePlate.AddContent(MobLicensePlateContent);
    end;

    internal procedure DeleteLicensePlateContent(var _RequestValues: Record "MOB NS Request Element"; _MobLicensePlate: Record "MOB License Plate")
    var
        MobSetup: Record "MOB Setup";
        Item: Record Item;
        MobLicensePlateContent: Record "MOB License Plate Content";
        MobTrackingSetup: Record "MOB Tracking Setup";
        ItemNumber: Code[50];
        Number: Code[50];
        UoMCode: Code[20];
        VariantCode: Code[10];
        Quantity: Decimal;
    begin
        MobSetup.Get();

        // Get the values from the Request Values
        Number := _RequestValues.Get_Number();
        MobTrackingSetup.CopyTrackingFromRequestValues(_RequestValues);

        // When using Serial Number Quantity is always = 1
        if MobTrackingSetup."Serial No." = '' then
            Quantity := _RequestValues.Get_Quantity()
        else
            Quantity := 1;

        // Set Item, UoM and Variant from Barcode
        ItemNumber := MobItemReferenceMgt.SearchItemReference(Number, VariantCode, UoMCode);

        // Check if specific tracking and Warehouse Tracking are enabled because it is required to add/remove content
        CheckSpecificWarehouseTrackingIsEnabled(ItemNumber);

        // Collected values have priority and should only be used if avaliable in the Request Values. 
        // Otherwise use the values from the Barcode identified above in SearchItemReference
        if _RequestValues.HasValue('UoM') then
            UoMCode := _RequestValues.GetValue('UoM');

        if (UoMCode = '') or (MobTrackingSetup."Serial No." <> '') or MobSetup."Use Base Unit of Measure" then begin
            Item.Get(ItemNumber);
            UoMCode := Item."Base Unit of Measure";
        end;

        if _RequestValues.HasValue('Variant') then
            VariantCode := _RequestValues.GetValue('Variant');

        // Apply the filters to the License Plate Content
        MobLicensePlateContent.SetRange("License Plate No.", _MobLicensePlate."No.");
        MobLicensePlateContent.SetRange(Type, MobLicensePlateContent.Type::Item);
        MobLicensePlateContent.SetRange("No.", ItemNumber);
        MobLicensePlateContent.SetRange("Unit Of Measure Code", UoMCode);
        MobLicensePlateContent.SetFilter(Quantity, '>=%1', Quantity);
        MobLicensePlateContent.SetRange("Lot No.", MobTrackingSetup."Lot No.");
        MobLicensePlateContent.SetRange("Serial No.", MobTrackingSetup."Serial No.");
        MobLicensePlateContent.SetRange("Package No.", MobTrackingSetup."Package No.");
        MobLicensePlateContent.SetRange("Variant Code", VariantCode);

        // Delete or Modify License Plate Content based on the filters and the Quantity to delete
        UpdateLicensePlateContentsFromQuantityToDelete(MobLicensePlateContent, Quantity)
    end;

    /// <summary>
    /// Updates the License Plate Content based on the Quantity to delete
    /// The License Plate Contents are deleted or modified based on the Quantity to delete
    /// </summary>    
    internal procedure UpdateLicensePlateContentsFromQuantityToDelete(var _MobLicensePlateContent: Record "MOB License Plate Content"; _QuantityToDelete: Decimal)
    begin
        _MobLicensePlateContent.LockTable();
        _MobLicensePlateContent.FindFirst(); // Content must exist. 

        // Note: The Content is filtered to ensure that the Quantity is greater than or equal to the Quantity to delete
        // License Plate Content is always accumulated per Item No., UoM, Variant and Item Tracking so it is never needed to delete multiple lines

        // If the Quantity to delete equals the Quantity in the content, then the content is deleted 
        if _MobLicensePlateContent.Quantity = _QuantityToDelete then
            _MobLicensePlateContent.Delete(true)
        else begin // If the Quantity to delete is less than the Quantity in the content, then the content is modified
            _MobLicensePlateContent.Validate(Quantity, _MobLicensePlateContent.Quantity - _QuantityToDelete);
            _MobLicensePlateContent.Modify(true);
        end;
    end;

    internal procedure GetDefaultOrSuggestedBinAsHtml(_MobLicensePlate: Record "MOB License Plate"; _ShowSuggestedBinFromPutAway: Boolean; _NewLocationCode: Code[10]): Text
    var
        MobLicensePlateContent: Record "MOB License Plate Content";
        WhseActLine: Record "Warehouse Activity Line";
        HelpLabelTxt: TextBuilder;
    begin
        HelpLabelTxt.Append('<html><body>');

        _MobLicensePlate.CalcFields("Top-level");
        if not _MobLicensePlate."Top-level" then
            HelpLabelTxt.Append(StrSubstNo('<b>' + NotTopLevelWarningTxt + '</b><p>'));

        MobLicensePlateContent.SetRange("License Plate No.", _MobLicensePlate."No.");
        MobLicensePlateContent.SetRange(Type, MobLicensePlateContent.Type::Item);
        if MobLicensePlateContent.FindFirst() then begin

            // Append the Suggested or Default Bin Code
            HelpLabelTxt.Append('<div align="center"><font color = gray align = center>');
            if _ShowSuggestedBinFromPutAway then begin
                WhseActLine.SetRange("Activity Type", WhseActLine."Activity Type"::"Put-away");
                WhseActLine.SetRange("Whse. Document Type", WhseActLine."Whse. Document Type"::Receipt);
                WhseActLine.SetRange("Whse. Document No.", _MobLicensePlate."Whse. Document No.");
                WhseActLine.SetRange("Action Type", WhseActLine."Action Type"::Place);
                WhseActLine.SetRange("Item No.", MobLicensePlateContent."No.");
                if WhseActLine.FindFirst() then
                    HelpLabelTxt.Append(StrSubstNo(MobWmsLanguage.GetMessage('SUGGESTION'), WhseActLine."Bin Code"))
            end else
                HelpLabelTxt.Append(MobWmsLanguage.GetMessage('DEFAULT') + ': ' + MobWmsToolbox.GetDefaultBin(MobLicensePlateContent."No.", _NewLocationCode, MobLicensePlateContent."Variant Code"));

            HelpLabelTxt.Append('</font></div><p>');
        end;
        HelpLabelTxt.Append('</body></html>');

        exit(HelpLabelTxt.ToText())
    end;

    /// <summary>
    /// During posting, allow user to create new LP.
    /// If scanned value is not recognized as Bin or LP, then ask user if new LP should be created.    
    /// </summary>    
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Adhoc Registr.", 'OnPostAdhocRegistration_OnAddSteps', '', false, false)]
    local procedure UnplannedMoveAdvanced_CreateNewLP_OnPostAdhocRegistration_OnAddSteps(_RegistrationType: Text; var _RequestValues: Record "MOB NS Request Element"; var _Steps: Record "MOB Steps Element"; var _RegistrationTypeTracking: Text)
    var
        Bin: Record Bin;
        MobLicensePlate: Record "MOB License Plate";
        MobSetup: Record "MOB Setup";
        ConfirmTxtBuilder: TextBuilder;
        ToBinOrLP: Code[20];
        NewLocationCode: Code[10];
        BinForNewLP: Code[20];
    begin
        if _RegistrationType <> MobWmsToolbox."CONST::UnplannedMoveAdvanced"() then
            exit;

        MobSetup.CheckLicensePlatingIsEnabled();

        ToBinOrLP := _RequestValues.Get_ToBinOrLP();
        NewLocationCode := _RequestValues.GetValue('NewLocation', true);
        BinForNewLP := _RequestValues.GetValue('BinForNewLP');

        if ToBinOrLP = '' then
            exit;

        if Bin.Get(NewLocationCode, ToBinOrLP) then
            exit;

        if MobLicensePlate.Get(ToBinOrLP) then
            exit;

        // If the scanned value is not recognized as a Bin or License Plate, then ask the user if a new License Plate should be created
        if BinForNewLP = '' then begin
            // Confirmation Dialog on Mobile Device does not support linebreak using \\, so the text is built as html here
            ConfirmTxtBuilder.Append('<html><body>');
            ConfirmTxtBuilder.Append(StrSubstNo(MobWmsLanguage.GetMessage('BIN_OR_LP_NOT_FOUND'), ToBinOrLP));
            ConfirmTxtBuilder.Append('<p>');
            ConfirmTxtBuilder.Append(MobWmsLanguage.GetMessage('CREATE_NEW_LP_CONFIRM'));
            ConfirmTxtBuilder.Append('</body></html>');
            MobToolbox.ErrorIfNotConfirm(_RequestValues, ConfirmTxtBuilder.ToText());

            // Create a step for entering the Bin code for the License Plate if required
            _Steps.Create_TextStep(100, 'BinForNewLP');
            _Steps.Set_header(MobWmsLanguage.GetMessage('SCAN_TO_BIN'));
            _Steps.Set_helpLabel(MobWmsLanguage.GetMessage('SCAN_INITIAL_BIN_FOR_LP'));
            _Steps.Save();

        end else begin
            // New Bin Code has been collected, Create the new License Plate
            Bin.Get(NewLocationCode, BinForNewLP);
            MobLicensePlate."No." := ToBinOrLP;
            MobLicensePlate.Validate("Location Code", NewLocationCode);
            MobLicensePlate.Validate("Bin Code", BinForNewLP);
            MobLicensePlate.Insert(true);
        end;
    end;

    /// <summary>
    /// Check if Items with specific tracking enabled, also have Warehouse Tracking enabled
    /// </summary>
    /// <param name="_ItemNumber"></param>
    local procedure CheckSpecificWarehouseTrackingIsEnabled(_ItemNumber: Code[20])
    var
        ItemTrackingCode: Record "Item Tracking Code";
        Item: Record Item;
        MobTelemetryManagement: Codeunit "MOB Telemetry Management";
        RecRef: RecordRef;
        FieldNumbers: List of [Integer];
        MobTelemetryEventId: Enum "MOB Telemetry Event ID";
    begin
        Item.Get(_ItemNumber);
        if not ItemTrackingCode.Get(Item."Item Tracking Code") then
            exit;

        // Check if any LOT/SN/PACKAGE combination of Specific Tracking is enabled without Warehouse Tracking        
        if (ItemTrackingCode."Lot Specific Tracking" <> ItemTrackingCode."Lot Warehouse Tracking") or
            /* #if BC18+ */
            (ItemTrackingCode."Package Specific Tracking" <> ItemTrackingCode."Package Warehouse Tracking") or
           /* #endif */
           (ItemTrackingCode."SN Specific Tracking" <> ItemTrackingCode."SN Warehouse Tracking")
        then begin

            // Log the unsupported Item Tracking Setup
            FieldNumbers.Add(ItemTrackingCode.FieldNo(Code));
            FieldNumbers.Add(ItemTrackingCode.FieldNo(Description));
            FieldNumbers.Add(ItemTrackingCode.FieldNo("Lot Specific Tracking"));
            FieldNumbers.Add(ItemTrackingCode.FieldNo("Lot Warehouse Tracking"));
            FieldNumbers.Add(ItemTrackingCode.FieldNo("SN Specific Tracking"));
            FieldNumbers.Add(ItemTrackingCode.FieldNo("SN Warehouse Tracking"));
            /* #if BC18+ */
            FieldNumbers.Add(ItemTrackingCode.FieldNo("Package Specific Tracking"));
            FieldNumbers.Add(ItemTrackingCode.FieldNo("Package Warehouse Tracking"));
            /* #endif */
            RecRef.GetTable(ItemTrackingCode);
            MobTelemetryManagement.LogErrorAndRelatedFields(MobTelemetryEventId::"MOB Specific Tracking Without Whse Tracking Detected (MOB2400)", '', RecRef, FieldNumbers);

            // Throw the error
            Error(SpecificTrackingWithoutWhseTrackingDetectedErr, ItemTrackingCode.TableCaption(), ItemTrackingCode.Code, Item."No.");
        end
    end;
}
