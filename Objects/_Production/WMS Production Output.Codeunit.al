codeunit 81404 "MOB WMS Production Output"
{
    Access = Public;

    var
        MobSessionData: Codeunit "MOB SessionData";

    procedure RunLookup(_LookupType: Text[50]; var _RequestValues: Record "MOB NS Request Element"; var _LookupResponse: Record "MOB NS WhseInquery Element"; var _ReturnRegistrationTypeTracking: Text)
    begin
        case _LookupType of
            // Order output lines
            MobWmsToolbox."CONST::ProdOutput"():
                LookupProdOutputLines(_RequestValues, _LookupResponse, _ReturnRegistrationTypeTracking)
            else
                Error(MobWmsLanguage.GetMessage('NO_DOC_HANDLER'), 'Lookup.' + _LookupType);
        end;
    end;

    procedure RunGetRegistrationConfiguration(_MobDocQueue: Record "MOB Document Queue"; _RegistrationType: Text; var _HeaderFilter: Record "MOB NS Request Element"; var _Steps: Record "MOB Steps Element"; var _ReturnRegistrationTypeTracking: Text)
    begin
        case _RegistrationType of
            // Output Actions
            MobWmsToolbox."CONST::ProdOutputTimeTracking"():
                _ReturnRegistrationTypeTracking := CreateProdOutputTimeTrackingRegColConf(_HeaderFilter, _Steps);
            MobWmsToolbox."CONST::ProdOutputQuantity"():
                _ReturnRegistrationTypeTracking := CreateProdOutputQuantityRegColConf(_HeaderFilter, _Steps);
            MobWmsToolbox."CONST::ProdOutputTime"():
                _ReturnRegistrationTypeTracking := CreateProdOutputTimeRegColConf(_HeaderFilter, _Steps);
            MobWmsToolbox."CONST::ProdOutputScrap"():
                _ReturnRegistrationTypeTracking := CreateProdOutputScrapRegColConf(_HeaderFilter, _Steps);
        end;
    end;

    procedure RunPostAdhocRegistration(_MobDocQueue: Record "MOB Document Queue"; _RegistrationType: Text; var _RequestValues: Record "MOB NS Request Element"; var _SuccessMessage: Text; var _ReturnRegistrationTypeTracking: Text)
    begin
        case _RegistrationType of
            // Posting Time Tracking from Lookup
            MobWmsToolbox."CONST::ProdOutputTimeTracking"():
                PostProdOutputTimeTracking(_MobDocQueue, _RequestValues, _SuccessMessage, _ReturnRegistrationTypeTracking);
            // Posting from Lookup
            MobWmsToolbox."CONST::ProdOutput"(),
            MobWmsToolbox."CONST::ProdOutputQuantity"(),
            MobWmsToolbox."CONST::ProdOutputTime"(),
            MobWmsToolbox."CONST::ProdOutputScrap"():
                PostProdOutput(_RegistrationType, _MobDocQueue, _RequestValues, _SuccessMessage, _ReturnRegistrationTypeTracking);
            MobWmsToolbox."CONST::ProdOutputFinishOperation"():
                PostFinishRouteOperation(_MobDocQueue, _RequestValues, _SuccessMessage, _ReturnRegistrationTypeTracking);
            else
                Error(MobWmsLanguage.GetMessage('NO_DOC_HANDLER'), 'PostAdhocRegistration.' + _RegistrationType);
        end;
    end;

    var
        MobItemReferenceMgt: Codeunit "MOB Item Reference Mgt.";
        MobToolbox: Codeunit "MOB Toolbox";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
        MUST_BE_TEMPORARY_Err: Label 'Internal error: %1 must be a temporary record.', Locked = true;

    //
    // ------- LookupProdOutput -------
    // 
    local procedure LookupProdOutputLines(var _RequestValues: Record "MOB NS Request Element"; var _LookupResponse: Record "MOB NS WhseInquery Element"; var _ReturnRegistrationTypeTracking: Text)
    var
        ProdOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
        MobWmsLookup: Codeunit "MOB WMS Lookup";
        BackendID: Code[40];
        ProdOrderNo: Code[20];
        ProdOrderLineNo: Integer;
    begin
        Evaluate(BackendID, _RequestValues.GetValue('BackendID', true));
        MobWmsToolbox.GetOrderNoAndOrderLineNoFromBackendId(BackendID, ProdOrderNo, ProdOrderLineNo);

        _ReturnRegistrationTypeTracking := ProdOrderNo + ' - ' + Format(ProdOrderLineNo);

        ProdOrder.Get(ProdOrderLine.Status::Released, ProdOrderNo);
        ProdOrderLine.Get(ProdOrderLine.Status::Released, ProdOrderNo, ProdOrderLineNo);

        // No AddSteps event for collectorSteps to be displayed on posting. Possible steps to display should be same
        // for "workflow" (clicking the lookup line) and actions (separately clicking Quantity/Time/Scrap adhoc)

        // Create/sort output lines by associated Routing Reference No.
        ProdOrderRtngLine.Reset();
        ProdOrderRtngLine.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
        ProdOrderRtngLine.SetRange("Routing No.", ProdOrderLine."Routing No.");
        ProdOrderRtngLine.SetRange(Status, ProdOrderLine.Status);
        ProdOrderRtngLine.SetRange("Routing Reference No.", ProdOrderLine."Routing Reference No.");
        // Event
        MobWmsLookup.OnLookupOnProdOutput_OnSetFilterProdOrderRoutingLine(_RequestValues, ProdOrderRtngLine);

        if not ProdOrderRtngLine.IsEmpty() then begin
            if _RequestValues.GetValue('RouteOperationStatus') = MobWmsLanguage.GetMessage('ROUTE_OPERATION_STATUS_UNFINISHED') then
                ProdOrderRtngLine.SetFilter("Routing Status", '<>%1', ProdOrderRtngLine."Routing Status"::Finished);
            if ProdOrderRtngLine.FindSet() then
                repeat
                    InsertProdOutputLines(_RequestValues, ProdOrderRtngLine, ProdOrderLine, BackendID, _LookupResponse);
                until ProdOrderRtngLine.Next() = 0
        end else begin
            Clear(ProdOrderRtngLine);
            InsertProdOutputLines(_RequestValues, ProdOrderRtngLine, ProdOrderLine, BackendID, _LookupResponse);
        end;
    end;

    local procedure InsertProdOutputLines(var _RequestValues: Record "MOB NS Request Element"; _ProdOrderRtngLine: Record "Prod. Order Routing Line"; _ProdOrderLine: Record "Prod. Order Line"; _BackendID: Code[40]; var _LookupResponse: Record "MOB NS WhseInquery Element")
    var
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        MobWmsLookup: Codeunit "MOB WMS Lookup";
        IncludeInOrderLines: Boolean;
        IsLastOperation: Boolean;
    begin
        IncludeInOrderLines := true;
        if _ProdOrderRtngLine."Prod. Order No." <> '' then // Operation exist
            case _ProdOrderRtngLine.Type of
                _ProdOrderRtngLine.Type::"Work Center":
                    if (SubcontractingWorkCenterUsed(_ProdOrderRtngLine)) then
                        IncludeInOrderLines := false;
                _ProdOrderRtngLine.Type::"Machine Center":
                    ; // IncludeInOrderLine := true;
            end;

        // Verify addtional conditions from eventsubscribers
        MobWmsLookup.OnLookupOnProdOutput_OnIncludeProductionOutput(_RequestValues, _ProdOrderLine, _ProdOrderRtngLine, IncludeInOrderLines);

        if IncludeInOrderLines then begin
            // Add the data to the order line element
            IsLastOperation := _ProdOrderRtngLine."Next Operation No." = '';
            if IsLastOperation then
                RetrieveProdOrderLineItemTracking(_ProdOrderLine, TempTrackingSpecification);
            if TempTrackingSpecification.FindSet() then
                repeat
                    _LookupResponse.Create();
                    SetFromProdOutputLine(_ProdOrderLine, TempTrackingSpecification, _ProdOrderRtngLine, _BackendID, _LookupResponse);
                    _LookupResponse.Save();
                until TempTrackingSpecification.Next() = 0
            else begin
                Clear(TempTrackingSpecification);
                _LookupResponse.Create();
                SetFromProdOutputLine(_ProdOrderLine, TempTrackingSpecification, _ProdOrderRtngLine, _BackendID, _LookupResponse);
                _LookupResponse.Save();
            end;
        end;
    end;

    local procedure SubcontractingWorkCenterUsed(_ProdOrderRtngLine: Record "Prod. Order Routing Line"): Boolean
    var
        WorkCenter: Record "Work Center";
    begin
        if _ProdOrderRtngLine.Type = _ProdOrderRtngLine.Type::"Work Center" then
            if WorkCenter.Get(_ProdOrderRtngLine."Work Center No.") then
                exit(WorkCenter."Subcontractor No." <> '');

        exit(false);
    end;

    local procedure RetrieveProdOrderLineItemTracking(_ProdOrderLine: Record "Prod. Order Line"; var _TempTrackingSpecification: Record "Tracking Specification" temporary): Boolean
    var
        ReservEntry: Record "Reservation Entry";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        CommonMgt: Codeunit "MOB Common Mgt.";
    begin
        if not _TempTrackingSpecification.IsTemporary() then
            Error(MUST_BE_TEMPORARY_Err, _TempTrackingSpecification.TableCaption());    // SumUpItemTracking() will delete all content

        CommonMgt.SetSourceFilterForReservEntry(ReservEntry, Database::"Prod. Order Line", MobToolbox.AsInteger(_ProdOrderLine.Status), _ProdOrderLine."Prod. Order No.", 0, true);
        CommonMgt.SetSourceFilterForReservEntry(ReservEntry, '', _ProdOrderLine."Line No.");
        ReservEntry.SetFilter("Qty. to Handle (Base)", '<>0');

        // Sum up in a temporary table per component line:
        exit(ItemTrackingMgt.SumUpItemTracking(ReservEntry, _TempTrackingSpecification, true, true));
    end;

    local procedure SetFromProdOutputLine(_ProdOrderLine: Record "Prod. Order Line"; _TempTrackingSpecification: Record "Tracking Specification"; _ProdOrderRtngLine: Record "Prod. Order Routing Line"; _BackendID: Code[40]; var _LookupResponse: Record "MOB NS WhseInquery Element")
    var
        Location: Record Location;
        WorkCenter: Record "Work Center";
        MachineCenter: Record "Machine Center";
        Item: Record Item;
        MobSetup: Record "MOB Setup";
        TempSteps: Record "MOB Steps Element" temporary;
        MobTrackingSetupThisOperation: Record "MOB Tracking Setup";
        MobCommonMgt: Codeunit "MOB Common Mgt.";
        UoMMgt: Codeunit "Unit of Measure Management";
        MobWmsAdhocReg: Codeunit "MOB WMS Adhoc Registr.";
        MobLicensePlateProdOutput: Codeunit "MOB License Plate Prod Output";
        MobWmsLookup: Codeunit "MOB WMS Lookup";
        MobTimeTrackingMgt: Codeunit "MOB Time Tracking Management";
        ExpDateRequiredThisOperation: Boolean;
        ActualRunTime: Decimal;
        ActualSetupTime: Decimal;
        ActualOutputQty: Decimal;
        ActualScrapQty: Decimal;
        CapUnitOfMeasureCode: Code[10];
        DisplayLine2To9List: List of [Text];
        ExtraInfo1_Col1: List of [Text];
        ExtraInfo1_Col2: List of [Text];
        ExtraInfo2_Col1: List of [Text];
        ExtraInfo2_Col2: List of [Text];
        ExpectedQtyToPost: Decimal;
        IsLastOperation: Boolean;
        FirstItemReferenceNo: Code[50];
        SetupTimeIcon: Text;
        RunTimeIcon: Text;
    begin
        MobSetup.Get();
        IsLastOperation := _ProdOrderRtngLine."Next Operation No." = '';

        if not Location.Get(_ProdOrderLine."Location Code") then
            Clear(Location);

        Item.Get(_ProdOrderLine."Item No.");

        // Add the data to the journal line element        
        _LookupResponse.Init();
        _LookupResponse.SetValue('BackendID', _BackendID);

        _LookupResponse.SetValue('LineNumber', Format(_ProdOrderLine."Line No.")); // not unique but no error error at mobile device in lookup pages
        _LookupResponse.Set_ItemNumber(_ProdOrderLine."Item No.");

        _LookupResponse.Set_Location(_ProdOrderLine."Location Code");

        // ToBin
        if IsLastOperation then begin
            _LookupResponse.SetValue('ToBin', _ProdOrderLine."Bin Code");
            _LookupResponse.SetValue('ValidateToBin', MobWmsToolbox.Bool2Text((MobWmsAdhocReg.TestBinMandatory(_ProdOrderLine."Location Code") and not Location."Directed Put-away and Pick")))
        end else
            _LookupResponse.SetValue('ValidateToBin', MobWmsToolbox.Bool2Text(false));

        if IsLastOperation then begin
            MobTrackingSetupThisOperation.DetermineManufInboundTrackingRequiredFromItemNo(_ProdOrderLine."Item No.", ExpDateRequiredThisOperation);
            MobTrackingSetupThisOperation.CopyTrackingFromTrackingSpec(_TempTrackingSpecification);
        end else begin
            MobTrackingSetupThisOperation.ClearTrackingRequired();
            MobTrackingSetupThisOperation.CopyTrackingFromTrackingSpec(_TempTrackingSpecification);
            Clear(ExpDateRequiredThisOperation);
        end;

        _LookupResponse.SetTracking(MobTrackingSetupThisOperation);
        if _TempTrackingSpecification."Expiration Date" <> 0D then
            _LookupResponse.Set_ExpirationDate(_TempTrackingSpecification."Expiration Date");

        // RegisterTracking is generally not used for unplanned functions but is used in the Production area for adhoc steps customization
        _LookupResponse.SetRegisterTracking(MobTrackingSetupThisOperation);
        _LookupResponse.SetValue('RegisterExpirationDate', MobWmsToolbox.Bool2Text(ExpDateRequiredThisOperation));

        // We split/display lines by pre-entered tracking but cannot similarily split associated fixed scrap qty / scrap%
        // In case of tracking we keep it simple and ask for the tracked quantity
        if _TempTrackingSpecification.TrackingExists() then
            ExpectedQtyToPost := _TempTrackingSpecification."Quantity (Base)"
        else
            ExpectedQtyToPost := CalcExpectedQtyToPost(_ProdOrderLine, _ProdOrderRtngLine);

        if MobSetup."Use Base Unit of Measure" then begin
            _LookupResponse.Set_Quantity(MobWmsToolbox.Decimal2TextAsDisplayFormat(UoMMgt.CalcBaseQty(ExpectedQtyToPost, _ProdOrderLine."Qty. per Unit of Measure")));
            _LookupResponse.Set_UoM(Item."Base Unit of Measure");
            _LookupResponse.SetValue('DisplayUoM', MobWmsLanguage.GetMessage('UOM_LABEL') + ': ' + Item."Base Unit of Measure");
        end else begin
            _LookupResponse.Set_Quantity(MobWmsToolbox.Decimal2TextAsDisplayFormat(ExpectedQtyToPost));
            _LookupResponse.Set_UoM(_ProdOrderLine."Unit of Measure Code");
            _LookupResponse.SetValue('DisplayUoM', MobWmsLanguage.GetMessage('UOM_LABEL') + ': ' + _ProdOrderLine."Unit of Measure Code")
        end;

        if ExpectedQtyToPost <> 0 then begin
            FirstItemReferenceNo := MobItemReferenceMgt.GetFirstReferenceNo(_ProdOrderLine."Item No.", _ProdOrderLine."Variant Code", _ProdOrderLine."Unit of Measure Code");
            _LookupResponse.Set_Barcode(FirstItemReferenceNo <> '', FirstItemReferenceNo, _ProdOrderLine."Item No.");
        end;

        // There are 3 display lines available in the ProdOutput configuration
        // Line 1: Show the Routing Line Description / Work Center / Machine Center -- or Item No. if no route
        // Line 2: Show the Item Number (if with route) and Item Description (UoM is displayed in Quantity-step helplabel) / Item Variant
        // Line 3: Show the Serial/Lot Info
        // Line 4: Show the Operation No. / Work Center No. / Machine Center No. (default not visbible in application.cfg)

        if _ProdOrderRtngLine."Prod. Order No." <> '' then // Operation exist
            case _ProdOrderRtngLine.Type of
                _ProdOrderRtngLine.Type::"Work Center":
                    begin
                        WorkCenter.Get(_ProdOrderRtngLine."No.");
                        if _ProdOrderRtngLine.Description <> '' then
                            _LookupResponse.Set_DisplayLine1(_ProdOrderRtngLine.Description)
                        else
                            _LookupResponse.Set_DisplayLine1(WorkCenter.Name <> '', WorkCenter.Name, WorkCenter."No.");
                    end;
                _ProdOrderRtngLine.Type::"Machine Center":
                    begin
                        MachineCenter.Get(_ProdOrderRtngLine."No.");
                        WorkCenter.Get(_ProdOrderRtngLine."Work Center No.");
                        if _ProdOrderRtngLine.Description <> '' then
                            _LookupResponse.Set_DisplayLine1(_ProdOrderRtngLine.Description)
                        else begin
                            _LookupResponse.Set_DisplayLine1(MachineCenter.Name <> '', MachineCenter.Name, MachineCenter."No.");
                            if WorkCenter.Name <> '' then
                                _LookupResponse.Set_DisplayLine1(_LookupResponse.Get_DisplayLine1() + ' / ' + WorkCenter.Name)
                            else
                                _LookupResponse.Set_DisplayLine1(_LookupResponse.Get_DisplayLine1() + ' / ' + WorkCenter."No.");
                        end;
                    end;
                else
            end;

        if _LookupResponse.Get_DisplayLine1() = '' then begin // No capacities
            _LookupResponse.Set_DisplayLine1(_ProdOrderLine."Item No.");
            _LookupResponse.Set_DisplayLine2(_ProdOrderLine.Description);
        end else
            _LookupResponse.Set_DisplayLine2(_ProdOrderLine."Item No." + '  ' + _ProdOrderLine.Description);

        // Tracking and variant
        _LookupResponse.Set_DisplayLine3(MobTrackingSetupThisOperation.FormatTracking());
        _LookupResponse.Set_DisplayLine4('');
        _LookupResponse.Set_DisplayLine5(_TempTrackingSpecification."Expiration Date" <> 0D, MobWmsLanguage.GetMessage('EXP_DATE_LABEL') + ': ' + MobWmsToolbox.Date2TextAsDisplayFormat(_TempTrackingSpecification."Expiration Date"), '');
        _LookupResponse.Set_DisplayLine6(_ProdOrderLine."Variant Code" <> '', MobWmsLanguage.GetMessage('VARIANT_LABEL') + ': ' + _ProdOrderLine."Variant Code", '');

        GetActOutputTimeAndQty(_ProdOrderLine, _ProdOrderRtngLine, ActualRunTime, ActualSetupTime, ActualOutputQty, ActualScrapQty);
        CapUnitOfMeasureCode := GetCapUnitOfMeasureCode(_ProdOrderRtngLine);

        if MobCommonMgt.TimeFactor(CapUnitOfMeasureCode) in [1000, 60000] then begin    // Seconds or Minutes
            ActualRunTime := Round(ActualRunTime, 1, '>');
            ActualSetupTime := Round(ActualSetupTime, 1, '>');
        end;

        Clear(SetupTimeIcon);
        Clear(RunTimeIcon);
        ExtraInfo1_Col1.Add(MobWmsLanguage.GetMessage('FINISHED_QTY'));
        ExtraInfo1_Col2.Add(StrSubstNo('%1/%2 %3', MobWmsToolbox.Decimal2TextAsDisplayFormat(ActualOutputQty), MobWmsToolbox.Decimal2TextAsDisplayFormat(_ProdOrderLine.Quantity), _ProdOrderLine."Unit of Measure Code"));   // 7/10 PCS
        if CanRegisterTime(_ProdOrderRtngLine) then begin
            // Setup Time / Run Time including Status icon for time tracking
            SetupTimeIcon := MobTimeTrackingMgt.GetStatusIcon(_ProdOrderRtngLine.RecordId(), "MOB Time Tracking Entry Type"::"Production Output Setup Time");
            RunTimeIcon := MobTimeTrackingMgt.GetStatusIcon(_ProdOrderRtngLine.RecordId(), "MOB Time Tracking Entry Type"::"Production Output Run Time");

            ExtraInfo2_Col1.Add(MobWmsLanguage.GetMessage('ACTUAL_SETUP_TIME'));
            if SetupTimeIcon = MobTimeTrackingMgt."CONST::IconStarted"() then
                ExtraInfo2_Col2.Add(StrSubstNo('%1 %2   [ %3 ]', ActualSetupTime, CapUnitOfMeasureCode, SetupTimeIcon))
            else
                ExtraInfo2_Col2.Add(StrSubstNo('%1 %2', ActualSetupTime, CapUnitOfMeasureCode));

            ExtraInfo2_Col1.Add(MobWmsLanguage.GetMessage('ACTUAL_RUN_TIME'));
            if RunTimeIcon = MobTimeTrackingMgt."CONST::IconStarted"() then
                ExtraInfo2_Col2.Add(StrSubstNo('%1 %2  [ %3 ]', ActualRunTime, CapUnitOfMeasureCode, RunTimeIcon))
            else
                ExtraInfo2_Col2.Add(StrSubstNo('%1 %2', ActualRunTime, CapUnitOfMeasureCode));
        end;
        ExtraInfo2_Col1.Add(MobWmsLanguage.GetMessage('ACTUAL_SCRAP_QTY'));
        ExtraInfo2_Col2.Add(StrSubstNo('%1 %2', MobWmsToolbox.Decimal2TextAsDisplayFormat(ActualScrapQty), _ProdOrderLine."Unit of Measure Code"));

        _LookupResponse.SetValue('ExtraInfo1_Col1', MobWmsToolbox.List2TextLn(ExtraInfo1_Col1, 999));
        _LookupResponse.SetValue('ExtraInfo1_Col2', MobWmsToolbox.List2TextLn(ExtraInfo1_Col2, 999));
        _LookupResponse.SetValue('ExtraInfo2_Col1', MobWmsToolbox.List2TextLn(ExtraInfo2_Col1, 999));
        _LookupResponse.SetValue('ExtraInfo2_Col2', MobWmsToolbox.List2TextLn(ExtraInfo2_Col2, 999));

        _LookupResponse.SetValue('SetupTime', '0');
        _LookupResponse.SetValue('RegisterSetupTime', 'true');
        _LookupResponse.SetValue('RunTime', '0');
        _LookupResponse.SetValue('RegisterRunTime', 'true');
        _LookupResponse.SetValue('ScrapQuantity', '0');
        _LookupResponse.SetValue('RegisterScrapQuantity', 'true');
        _LookupResponse.SetValue('ScrapCode', '');
        _LookupResponse.SetValue('RegisterScrapCode', MobWmsToolbox.Bool2Text(CanRegisterScrapCode(_ProdOrderRtngLine)));

        _LookupResponse.Set_ReferenceID(_ProdOrderLine);
        _LookupResponse.Set_ItemImageID();

        _LookupResponse.SetValue('ProdOrderRtngLine_RecordId', Format(_ProdOrderRtngLine.RecordId()));
        _LookupResponse.SetValue('LookupId', StrSubstNo('%1;%2;%3', _ProdOrderLine.RecordId(), _ProdOrderRtngLine.RecordId(), _TempTrackingSpecification.RecordId()));  // Reposition on close Adhoc

        // Integration Event
        MobWmsLookup.OnLookupOnProdOutput_OnAfterSetFromProductionOutput(_ProdOrderLine, _ProdOrderRtngLine, _TempTrackingSpecification, _LookupResponse);

        //
        // RegistrationCollector node incl. eventsubscribers _OnAddStepsToProdOutputXXX for 3 "line level" step types (Quantity/Time/Scrap)
        //
        CreateStepsForProdOutputQuantity(MobWmsToolbox."CONST::ProdOutput"(), _LookupResponse, TempSteps);
        CreateStepsForProdOutputTime(MobWmsToolbox."CONST::ProdOutput"(), _LookupResponse, _ProdOrderRtngLine, false, TempSteps);
        CreateStepsForProdOutputScrap(MobWmsToolbox."CONST::ProdOutput"(), _LookupResponse, false, TempSteps);

        // Create the LP related steps
        MobLicensePlateProdOutput.CreateStepsForProdOutputLicensePlate(_ProdOrderRtngLine, _LookupResponse, TempSteps);

        // Set compressed display lines 2 to 9 (after integration events to change display lines) and registrationcollector
        _LookupResponse.GetDisplayLinesAsList(DisplayLine2To9List, 2, 9);
        MobWmsToolbox.ListTrimBlank(DisplayLine2To9List, 2);
        _LookupResponse.SetValue('CompressedDisplayLine2To9', MobWmsToolbox.List2TextLn(DisplayLine2To9List, 999));
        _LookupResponse.SetRegistrationCollector(TempSteps);
    end;

    local procedure CalcExpectedQtyToPost(_ProdOrderLine: Record "Prod. Order Line"; _ProdOrderRtngLine: Record "Prod. Order Routing Line") ExpectedQtyToPost: Decimal
    var
        /* #if BC26+ */
        MfgCostCalculationMgt: Codeunit "Mfg. Cost Calculation Mgt.";
        /* #endif */
        /* #if BC25- ##
        MfgCostCalculationMgt: Codeunit "Cost Calculation Management";
        /* #endif */
        PresetOutputQuantity: Option "Expected Quantity","Zero on All Operations","Zero on Last Operation";
        IsLastOperation: Boolean;
    begin
        PresetOutputQuantity := PresetOutputQuantity::"Expected Quantity";
        IsLastOperation := _ProdOrderRtngLine."Next Operation No." = '';

        if (_ProdOrderRtngLine."Flushing Method" <> _ProdOrderRtngLine."Flushing Method"::Manual) or
           (PresetOutputQuantity = PresetOutputQuantity::"Zero on All Operations") or
           ((PresetOutputQuantity = PresetOutputQuantity::"Zero on Last Operation") and
            IsLastOperation) or
           ((_ProdOrderRtngLine."Prod. Order No." = '') and
            (PresetOutputQuantity <> PresetOutputQuantity::"Expected Quantity")) or
           (_ProdOrderRtngLine."Routing Status" = _ProdOrderRtngLine."Routing Status"::Finished)
        then
            ExpectedQtyToPost := 0
        else
            if _ProdOrderRtngLine."Prod. Order No." <> '' then begin
                ExpectedQtyToPost :=
                  MfgCostCalculationMgt.CalcQtyAdjdForRoutingScrap(
                    _ProdOrderLine."Quantity (Base)",
                    _ProdOrderRtngLine."Scrap Factor % (Accumulated)",
                    _ProdOrderRtngLine."Fixed Scrap Qty. (Accum.)") -
                  MfgCostCalculationMgt.CalcActOutputQtyBase(_ProdOrderLine, _ProdOrderRtngLine);
                ExpectedQtyToPost := ExpectedQtyToPost / _ProdOrderLine."Qty. per Unit of Measure";
            end else // No Routing Line
                ExpectedQtyToPost := _ProdOrderLine."Remaining Quantity";

        if ExpectedQtyToPost < 0 then
            ExpectedQtyToPost := 0;
    end;

    /// <summary>
    /// Calculate actual (posted) times and quanties for the prod. order line
    /// </summary>
    local procedure GetActOutputTimeAndQty(
        _ProdOrderLine: Record "Prod. Order Line";
        _ProdOrderRtngLine: Record "Prod. Order Routing Line";
        var _ActualRunTime: Decimal;
        var _ActualSetupTime: Decimal;
        var _ActualOutputQty: Decimal;
        var _ActualScrapQty: Decimal
    )
    var
        /* #if BC26+ */
        MfgCostCalculationMgt: Codeunit "Mfg. Cost Calculation Mgt.";
        /* #endif */
        /* #if BC25- ##
        MfgCostCalculationMgt: Codeunit "Cost Calculation Management";
        /* #endif */
        UoMMgt: Codeunit "Unit of Measure Management";
        MobUoMMgt: Codeunit "MOB Unit of Measure Management";
        CapUnitOfMeasureCode: Code[10];
        QtyPerCapUnitOfMeasure: Decimal;
        ActRunTimeBase: Decimal;
        ActSetupTimeBase: Decimal;
        ActOutputQtyBase: Decimal;
        ActScrapQtyBase: Decimal;
    begin
        MfgCostCalculationMgt.CalcActTimeAndQtyBase(
            _ProdOrderLine, _ProdOrderRtngLine."Operation No.", ActRunTimeBase, ActSetupTimeBase, ActOutputQtyBase, ActScrapQtyBase);

        CapUnitOfMeasureCode := GetCapUnitOfMeasureCode(_ProdOrderRtngLine);    // may be empty, will calculate QtyPer = 1 in case
        if (_ProdOrderRtngLine."Work Center No." <> '') then
            QtyPerCapUnitOfMeasure :=
                Round(
                    QtyperTimeUnitofMeasure(_ProdOrderRtngLine."Work Center No.", CapUnitOfMeasureCode),
                    UoMMgt.QtyRndPrecision())
        else
            QtyPerCapUnitOfMeasure := 1;

        _ActualSetupTime := Round(ActSetupTimeBase / QtyPerCapUnitOfMeasure, MobUoMMgt.TimeRndPrecision());
        _ActualRunTime := Round(ActRunTimeBase / QtyPerCapUnitOfMeasure, MobUoMMgt.TimeRndPrecision());

        _ActualOutputQty := UoMMgt.CalcQtyFromBase(ActOutputQtyBase, _ProdOrderLine."Qty. per Unit of Measure");
        _ActualScrapQty := UoMMgt.CalcQtyFromBase(ActScrapQtyBase, _ProdOrderLine."Qty. per Unit of Measure");
    end;

    local procedure GetCapUnitOfMeasureCode(_ProdOrderRtngLine: Record "Prod. Order Routing Line"): Code[10]
    var
        WorkCenter: Record "Work Center";
        MachineCenter: Record "Machine Center";
    begin
        if _ProdOrderRtngLine."Prod. Order No." = '' then
            exit('');

        case _ProdOrderRtngLine.Type of
            _ProdOrderRtngLine.Type::"Work Center":
                begin
                    WorkCenter.Get(_ProdOrderRtngLine."No.");
                    WorkCenter.TestField(Blocked, false);
                end;
            _ProdOrderRtngLine.Type::"Machine Center":
                begin
                    MachineCenter.Get(_ProdOrderRtngLine."No.");
                    MachineCenter.TestField(Blocked, false);
                    WorkCenter.Get(MachineCenter."Work Center No.");
                    WorkCenter.TestField(Blocked, false);
                end;
        end;

        exit(WorkCenter."Unit of Measure Code");
    end;

    /// <summary>
    /// Replacing "Shop Calendar Management".QtyperTimeUnitofMeasure()  (do not exist in BC14)
    /// </summary>
    local procedure QtyperTimeUnitofMeasure(WorkCenterNo: Code[20]; UnitOfMeasureCode: Code[10]): Decimal
    var
        WorkCenter: Record "Work Center";
        MobCommonMgt: Codeunit "MOB Common Mgt.";
    begin
        WorkCenter.Get(WorkCenterNo);

        exit(MobCommonMgt.TimeFactor(UnitOfMeasureCode) / MobCommonMgt.TimeFactor(WorkCenter."Unit of Measure Code"));
    end;

    local procedure CanRegisterTime(_ProdOrderRtngLine: Record "Prod. Order Routing Line"): Boolean
    begin
        exit(GetCapUnitOfMeasureCode(_ProdOrderRtngLine) <> '');
    end;

    local procedure CanRegisterScrapCode(_ProdOrderRtngLine: Record "Prod. Order Routing Line"): Boolean
    var
        Scrap: Record Scrap;
    begin
        /* #if BC20+ */
        exit((_ProdOrderRtngLine.Type in [_ProdOrderRtngLine.Type::"Work Center", _ProdOrderRtngLine.Type::"Machine Center"]) and (not Scrap.IsEmpty()));
        /* #endif */
        /* #if BC19- ##
        exit((_ProdOrderRtngLine.Type = _ProdOrderRtngLine.Type::"Machine Center") and (not Scrap.IsEmpty()));
        /* #endif */
    end;

    /// <summary>
    /// Error if Item or Item Variant is blocked for production output
    /// The general Item/ItemVariant "Blocked" field is also checked
    /// Inspired by: Tableextension "Mfg. Item" - "CheckItemAndVariantForProdBlocked"
    /// </summary>
    local procedure ErrorIfItemProductionOutputBlocked(_ItemNo: Code[20]; _VariantCode: Code[10])
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
    begin
        /* #if BC26+ */
        if _ItemNo = '' then
            exit;

        Item.Get(_ItemNo);
        Item.TestField(Blocked, false);

        if Item."Production Blocked" = Item."Production Blocked"::Output then
            Item.TestField("Production Blocked", Item."Production Blocked"::" ");

        if _VariantCode <> '' then begin
            ItemVariant.Get(_ItemNo, _VariantCode);
            if ItemVariant."Production Blocked" = ItemVariant."Production Blocked"::Output then
                ItemVariant.TestField("Production Blocked", ItemVariant."Production Blocked"::" ");

            ItemVariant.TestField(Blocked, false);
        end;
        /* #endif */
    end;

    local procedure ProdOrderRoutingLineRecordIdIsEmpty(_ProdOrderRtngLineRecordId: RecordId): Boolean
    var
        EmptyProdOrderRtngLine: Record "Prod. Order Routing Line";
    begin
        if Format(_ProdOrderRtngLineRecordId) = '' then
            exit(true);

        Clear(EmptyProdOrderRtngLine);
        exit(_ProdOrderRtngLineRecordId = EmptyProdOrderRtngLine.RecordId());
    end;

    local procedure GetProdOrderRoutingLineFromRecordId(var _ProdOrderRtngLine: Record "Prod. Order Routing Line"; _ProdOrderRtngLineRecordId: RecordId; _ErrorIfNotExists: Boolean) _IsFound: Boolean
    var
        ProdOrderRtngLineRecRef: RecordRef;
    begin
        ProdOrderRtngLineRecRef := _ProdOrderRtngLineRecordId.GetRecord();
        ProdOrderRtngLineRecRef.SetTable(_ProdOrderRtngLine);

        if _ErrorIfNotExists then begin
            _ProdOrderRtngLine.Find('=');
            _IsFound := true;
        end else
            _IsFound := _ProdOrderRtngLine.Find('=');

        exit(_IsFound);
    end;

    //
    // ------- GetRegistrationConfiguration -------
    //
    local procedure CreateProdOutputTimeTrackingRegColConf(var _HeaderValues: Record "MOB NS Request Element"; var _Steps: Record "MOB Steps Element") _ReturnRegistrationTypeTracking: Text
    var
        TempLookupResponseValues: Record "MOB NS WhseInquery Element" temporary;
    begin
        // Set the tracking value displayed in the document queue
        _ReturnRegistrationTypeTracking := _HeaderValues.GetValue('BackendID', false);

        // Load parent lookup response for context the adhoc was called from
        _HeaderValues.Get_ContextValuesAsWhseInquiryElement(TempLookupResponseValues, true);

        CreateStepsForProdOutputTimeTracking(TempLookupResponseValues, _Steps);
    end;

    local procedure CreateStepsForProdOutputTimeTracking(var _LookupResponse: Record "MOB NS WhseInquery Element"; var _Steps: Record "MOB Steps Element")
    var
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
        MobWmsAdhocRegistr: Codeunit "MOB WMS Adhoc Registr.";
        MobTimeTrackingMgt: Codeunit "MOB Time Tracking Management";
        ProdOrderRtngLineRecordId: RecordId;
        SetupTimeStatus: Enum "MOB Time Tracking Status";
        RunTimeStatus: Enum "MOB Time Tracking Status";
        ListValues: Text;
        DefaultValue: Text;
        DateTimeHeaderValue: Text;
        RoutingExists: Boolean;
    begin
        // Find the associated routing line
        Evaluate(ProdOrderRtngLineRecordId, _LookupResponse.GetValue('ProdOrderRtngLine_RecordId', true));
        RoutingExists := not ProdOrderRoutingLineRecordIdIsEmpty(ProdOrderRtngLineRecordId);

        if not RoutingExists then begin
            _Steps.Create_InformationStep(150, 'TimeInformation');
            _Steps.Set_header(MobWmsLanguage.GetMessage('TIME'));
            _Steps.Set_helpLabel(MobWmsLanguage.GetMessage('TIME_CAN_NOT_BE_REGISTERED'));
            _Steps.Save();
        end else begin
            GetProdOrderRoutingLineFromRecordId(ProdOrderRtngLine, ProdOrderRtngLineRecordId, true);    // Must exist

            SetupTimeStatus := MobTimeTrackingMgt.CalcCurrentTimeTrackingStatus(ProdOrderRtngLine.RecordId(), "MOB Time Tracking Entry Type"::"Production Output Setup Time");
            RunTimeStatus := MobTimeTrackingMgt.CalcCurrentTimeTrackingStatus(ProdOrderRtngLine.RecordId(), "MOB Time Tracking Entry Type"::"Production Output Run Time");

            // Build conditional listValues
            // Priority for DefaultValue is RunTime > SetupTime as not every customer is recording setup time

            if (SetupTimeStatus <> "MOB Time Tracking Status"::Started) and (RunTimeStatus <> "MOB Time Tracking Status"::Started) then begin
                ListValues := MobWmsLanguage.GetMessage('START_SETUP');
                DefaultValue := MobWmsLanguage.GetMessage('START_SETUP');
                DateTimeHeaderValue := MobWmsLanguage.GetMessage('START_TIME');
            end;

            if SetupTimeStatus = "MOB Time Tracking Status"::Started then begin
                ListValues += ';' + MobWmsLanguage.GetMessage('STOP_SETUP');
                DefaultValue := MobWmsLanguage.GetMessage('STOP_SETUP');
                DateTimeHeaderValue := MobWmsLanguage.GetMessage('STOP_TIME');
            end;

            if (RunTimeStatus <> "MOB Time Tracking Status"::Started) and (SetupTimeStatus <> "MOB Time Tracking Status"::Started) then begin
                ListValues += ';' + MobWmsLanguage.GetMessage('START_RUN');
                DefaultValue := MobWmsLanguage.GetMessage('START_RUN');
                DateTimeHeaderValue := MobWmsLanguage.GetMessage('START_TIME');
            end;

            if RunTimeStatus = "MOB Time Tracking Status"::Started then begin
                ListValues += ';' + MobWmsLanguage.GetMessage('STOP_RUN');
                DefaultValue := MobWmsLanguage.GetMessage('STOP_RUN');
                DateTimeHeaderValue := MobWmsLanguage.GetMessage('STOP_TIME');
            end;

            ListValues := DelChr(ListValues, '<', ';');

            _Steps.Create_RadioButtonStep(10, 'StatusOption');
            _Steps.Set_header(_LookupResponse.Get_DisplayLine1());
            _Steps.Set_listValues(ListValues);
            _Steps.Set_defaultValue(DefaultValue);
            _Steps.Create_DateTimeStep(20, 'DateTime');
            _Steps.Set_header(DateTimeHeaderValue);
        end;

        MobWmsAdhocRegistr.OnGetRegistrationConfigurationOnProdOutput_OnAddStepsToProductionOutputTimeTracking(_LookupResponse, _Steps);
    end;

    local procedure CreateProdOutputQuantityRegColConf(var _HeaderValues: Record "MOB NS Request Element"; var _Steps: Record "MOB Steps Element") _ReturnRegistrationTypeTracking: Text
    var
        TempLookupResponseValues: Record "MOB NS WhseInquery Element" temporary;
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
        MobLicensePlateProdOutput: Codeunit "MOB License Plate Prod Output";
        ProdOrderRtngLineRecordId: RecordId;
    begin
        // Set the tracking value displayed in the document queue
        _ReturnRegistrationTypeTracking := _HeaderValues.GetValue('BackendID', false);

        // Load parent lookup response for context the adhoc was called from
        _HeaderValues.Get_ContextValuesAsWhseInquiryElement(TempLookupResponseValues, true);

        // Find the routing line the output is for (may not have any routing but the ProdOrderRtngLine_RecordId tag must be in the xml)
        Clear(ProdOrderRtngLine);
        Evaluate(ProdOrderRtngLineRecordId, TempLookupResponseValues.GetValue('ProdOrderRtngLine_RecordId', false));
        if not ProdOrderRoutingLineRecordIdIsEmpty(ProdOrderRtngLineRecordId) then
            GetProdOrderRoutingLineFromRecordId(ProdOrderRtngLine, ProdOrderRtngLineRecordId, true);

        // Create the LP related steps
        MobLicensePlateProdOutput.CreateStepsForProdOutputLicensePlate(ProdOrderRtngLine, TempLookupResponseValues, _Steps);

        CreateStepsForProdOutputQuantity(MobWmsToolbox."CONST::ProdOutputQuantity"(), TempLookupResponseValues, _Steps);
    end;

    local procedure CreateStepsForProdOutputQuantity(_RegistrationType: Text; var _LookupResponse: Record "MOB NS WhseInquery Element"; var _Steps: Record "MOB Steps Element")
    var
        MobSetup: Record "MOB Setup";
        MobTrackingSetup: Record "MOB Tracking Setup";
        Item: Record Item;
        MobWmsAdhocRegistr: Codeunit "MOB WMS Adhoc Registr.";
        Location: Text;
        ItemNumber: Text;
        UoM: Text;
        RegisterExpirationDate: Boolean;
    begin
        // Based on standardworkflow
        // <fromBin id="10" header="@{RegistrationCollectorFromBinHeader}" label="'{FromBin'}" defaultValue="{FromBin}" helpLabel="@{RegistrationCollectorFromBinHelpLabel}" eanAi="00"/>
        // <toBin id="20" header="@{RegistrationCollectorToBinHeader}" label="'{ToBin'}" defaultValue="{ToBin}" helpLabel="@{RegistrationCollectorToBinHelpLabel}" eanAi="00"/>
        // <expirationDate id="31" header="@{RegistrationCollectorExpirationDateHeader}" label="" helpLabel="@{RegistrationCollectorExpirationDateHelpLabel}" eanAi="15,17,12"/>
        // <lotNumber id="32" header="@{RegistrationCollectorLotNumberHeader}" defaultValue="{LotNumber}" helpLabel="@{RegistrationCollectorLotNumberHelpLabel}" eanAi="10"/>
        // <tote id="35" header="@{RegistrationCollectorToteHeader}" helpLabel="@{RegistrationCollectorToteHelpLabel}" eanAi="98"/>
        // <serialNumber id="40" header="@{RegistrationCollectorSerialNumberHeader}" defaultValue="{SerialNumber}" helpLabel="@{RegistrationCollectorSerialNumberHelpLabel}" eanAi="21"/>
        // <quantity id="50" header="@{RegistrationCollectorQuantityHeader}" helpLabel="@{RegistrationCollectorQuantityHelpLabel}" eanAi="310,30,37" minValue="0.0000000001"/>
        // <quantityByScan id="51" header="@{RegistrationCollectorQuantityByScanHeader}" helpLabel="@{RegistrationCollectorQuantityByScanHelpLabel}" minValue="0.0000000001"/>

        MobSetup.Get();

        Location := _LookupResponse.Get_Location();
        ItemNumber := _LookupResponse.Get_ItemNumber();
        UoM := _LookupResponse.Get_UoM();

        Clear(MobTrackingSetup);
        MobTrackingSetup.CopyTrackingRequiredFromLookupResponse(_LookupResponse, true); /// RegisterTracking is generally not used for unplanned functions but is used in the Production area for adhoc steps customization
        // MobTrackingSetup.Tracking: Tracking values are unused in this scope
        RegisterExpirationDate := _LookupResponse.GetValueAsBoolean('RegisterExpirationDate', true);

        Item.Get(ItemNumber);

        if _LookupResponse.GetValueAsBoolean('ValidateToBin', false) and (MobWmsAdhocRegistr.TestBinMandatory(Location)) then begin
            _Steps.Create_TextStep_ToBin(20, ItemNumber);
            _Steps.Set_defaultValue(_LookupResponse.GetValue('ToBin'));
        end;

        // Steps: SerialNumber, LotNumber, PackageNumber
        _Steps.Create_TrackingStepsIfRequired(MobTrackingSetup, 30, ItemNumber);

        // Step: ExpirationDate
        if RegisterExpirationDate then
            _Steps.Create_DateStep_ExpirationDate(70, ItemNumber);

        // Step: Quantity
        if not MobTrackingSetup."Serial No. Required" then begin
            _Steps.Create_DecimalStep_Quantity(80, ItemNumber);
            _Steps.Set_helpLabel(_LookupResponse.GetValue('DisplayUoM', true));
            _Steps.Set_minValue(-999999999);    // allow negative correction
        end;

        //
        // Events
        //
        MobWmsAdhocRegistr.OnGetRegistrationConfigurationOnProdOutput_OnAddStepsToProductionOutput(_LookupResponse, _Steps);

        // _Steps.SetMustCallCreateNext(true); -- exluded to avoid breaking change to old customization example using OnAddStepsToProductionOutputQuantity to modify other steps by SetRange/Find/Modify
        MobWmsAdhocRegistr.OnGetRegistrationConfigurationOnProdOutput_OnAddStepsToProductionOutputQuantity(_LookupResponse, _Steps);
        // _Steps.SetMustCallCreateNext(false);
        if _Steps.FindSet() then
            repeat
                MobWmsAdhocRegistr.OnGetRegistrationConfigurationOnProdOutput_OnAfterAddStepToProductionOutputQuantity(_RegistrationType, _LookupResponse, _Steps);
            until _Steps.Next() = 0;
    end;

    local procedure CreateProdOutputTimeRegColConf(var _HeaderValues: Record "MOB NS Request Element"; var _Steps: Record "MOB Steps Element") _ReturnRegistrationTypeTracking: Text
    var
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
        TempLookupResponse: Record "MOB NS WhseInquery Element" temporary;
        ProdOrderRtngLineRecordId: RecordId;
    begin
        // Set the tracking value displayed in the document queue
        _ReturnRegistrationTypeTracking := _HeaderValues.GetValue('BackendID', true);

        // Load parent lookup response for context the adhoc was called from
        _HeaderValues.Get_ContextValuesAsWhseInquiryElement(TempLookupResponse, true);

        // Find the routing line the output is for (may not have any routing but the ProdOrderRtngLine_RecordId tag must be in the xml)
        Clear(ProdOrderRtngLine);
        Evaluate(ProdOrderRtngLineRecordId, TempLookupResponse.GetValue('ProdOrderRtngLine_RecordId', true));
        if not ProdOrderRoutingLineRecordIdIsEmpty(ProdOrderRtngLineRecordId) then
            GetProdOrderRoutingLineFromRecordId(ProdOrderRtngLine, ProdOrderRtngLineRecordId, true);

        CreateStepsForProdOutputTime(MobWmsToolbox."CONST::ProdOutputTime"(), TempLookupResponse, ProdOrderRtngLine, true, _Steps);
    end;

    local procedure CreateStepsForProdOutputTime(_RegistrationType: Text; var _LookupResponse: Record "MOB NS WhseInquery Element"; _ProdOrderRtngLine: Record "Prod. Order Routing Line"; _IncludeAllSteps: Boolean; var _Steps: Record "MOB Steps Element")
    var
        MobWmsAdhocRegistr: Codeunit "MOB WMS Adhoc Registr.";
        ProdOrderRtngLineRecordId: RecordId;
        RoutingExists: Boolean;
        IncludeStep: Boolean;
    begin
        Evaluate(ProdOrderRtngLineRecordId, _LookupResponse.GetValue('ProdOrderRtngLine_RecordId', true));
        RoutingExists := not ProdOrderRoutingLineRecordIdIsEmpty(ProdOrderRtngLineRecordId);

        // Step: SetupTime
        IncludeStep := RoutingExists and (_IncludeAllSteps or (_LookupResponse.GetValue('RegisterSetupTime', false) = 'true'));
        if IncludeStep then begin
            _Steps.Create_DecimalStep(100, 'SetupTime', false);
            _Steps.Set_header(MobWmsLanguage.GetMessage('ENTER_SETUP_TIME'));
            _Steps.Set_label(MobWmsLanguage.GetMessage('SETUP_TIME') + ':');
            _Steps.Set_helpLabel(MobWmsLanguage.GetMessage('SETUP_TIME') + ': ' + _ProdOrderRtngLine."Setup Time Unit of Meas. Code");
            _Steps.Set_autoForwardAfterScan(true);
            _Steps.Set_optional(true);
            _Steps.Set_visible(true);
            _Steps.Set_labelWidth_WindowsMobile(100);
            // Set_defaultValue(0);      // No defaultValue (inherited from parent LookupResponse)
            _Steps.Set_minValue(-999999999);    // allow negative correction
            _Steps.Set_performCalculation(true);
            _Steps.Save();
        end;

        // Step: RunTime
        IncludeStep := RoutingExists and (_IncludeAllSteps or (_LookupResponse.GetValue('RegisterRunTime', false) = 'true'));
        if IncludeStep then begin
            _Steps.Create_DecimalStep(110, 'RunTime', false);
            _Steps.Set_header(MobWmsLanguage.GetMessage('ENTER_RUN_TIME'));
            _Steps.Set_label(MobWmsLanguage.GetMessage('RUN_TIME') + ':');
            _Steps.Set_helpLabel(MobWmsLanguage.GetMessage('RUN_TIME') + ': ' + _ProdOrderRtngLine."Run Time Unit of Meas. Code");
            _Steps.Set_autoForwardAfterScan(true);
            _Steps.Set_optional(true);
            _Steps.Set_visible(true);
            _Steps.Set_labelWidth_WindowsMobile(100);
            // Set_defaultValue(0);      // No defaultValue (inherited from parent LookupResponse)
            _Steps.Set_minValue(-999999999);    // allow negative correction
            _Steps.Set_performCalculation(true);
            _Steps.Save();
        end;

        IncludeStep := _IncludeAllSteps and (not RoutingExists);
        if IncludeStep then begin
            _Steps.Create_InformationStep(150, 'TimeInformation');
            _Steps.Set_header(MobWmsLanguage.GetMessage('TIME'));
            _Steps.Set_helpLabel(MobWmsLanguage.GetMessage('TIME_CAN_NOT_BE_REGISTERED'));
            _Steps.Save();
        end else
            MobWmsAdhocRegistr.OnGetRegistrationConfigurationOnProdOutput_OnAddStepsToProductionOutput(_LookupResponse, _Steps);

        //
        // Events
        //
        _Steps.SetMustCallCreateNext(true);
        MobWmsAdhocRegistr.OnGetRegistrationConfigurationOnProdOutput_OnAddStepsToProductionOutputTime(_LookupResponse, _IncludeAllSteps, _Steps);
        _Steps.SetMustCallCreateNext(false);
        if _Steps.FindSet() then
            repeat
                MobWmsAdhocRegistr.OnGetRegistrationConfigurationOnProdOutput_OnAfterAddStepToProductionOutputTime(_RegistrationType, _LookupResponse, _Steps);
            until _Steps.Next() = 0;
    end;

    local procedure CreateProdOutputScrapRegColConf(var _HeaderValues: Record "MOB NS Request Element"; var _Steps: Record "MOB Steps Element") _ReturnRegistrationTypeTracking: Text
    var
        TempLookupResponse: Record "MOB NS WhseInquery Element" temporary;
    begin
        // Set the tracking value displayed in the document queue
        _ReturnRegistrationTypeTracking := _HeaderValues.GetValue('BackendID', true);

        // Load parent lookup response for context the adhoc was called from
        _HeaderValues.Get_ContextValuesAsWhseInquiryElement(TempLookupResponse, true);

        CreateStepsForProdOutputScrap(MobWmsToolbox."CONST::ProdOutputScrap"(), TempLookupResponse, true, _Steps);
    end;

    local procedure CreateStepsForProdOutputScrap(_RegistrationType: Text; var _LookupResponse: Record "MOB NS WhseInquery Element"; _IncludeAllSteps: Boolean; var _Steps: Record "MOB Steps Element")
    var
        MobWmsAdhocRegistr: Codeunit "MOB WMS Adhoc Registr.";
        IncludeQuantityStep: Boolean;
        IncludeCodeStep: Boolean;
    begin
        // Step: Scrap Quantity
        IncludeQuantityStep := _IncludeAllSteps or (_LookupResponse.GetValue('RegisterScrapQuantity', false) = 'true');
        if IncludeQuantityStep then begin
            _Steps.Create_DecimalStep(200, 'ScrapQuantity', false);
            _Steps.Set_header(MobWmsLanguage.GetMessage('ENTER_SCRAP_QUANTITY'));
            _Steps.Set_label(MobWmsLanguage.GetMessage('SCRAP_QUANTITY') + ':');
            _Steps.Set_helpLabel(MobWmsLanguage.GetMessage('SCRAP_QUANTITY') + ': ' + _LookupResponse.Get_UoM());
            _Steps.Set_autoForwardAfterScan(true);
            _Steps.Set_optional(true);
            _Steps.Set_visible(true);
            _Steps.Set_labelWidth_WindowsMobile(100);
            // Set_defaultValue(0);      // No defaultValue (inherited from parent LookupResponse)
            _Steps.Set_minValue(-999999999);    // allow negative correction
            _Steps.Set_performCalculation(true);
            _Steps.Save();
        end;

        // Step: Scrap Code
        IncludeCodeStep := IncludeQuantityStep and (_LookupResponse.GetValue('RegisterScrapCode', false) = 'true');
        if IncludeCodeStep then begin
            _Steps.Create_ListStep(210, 'ScrapCode', false);
            _Steps.Set_header(MobWmsLanguage.GetMessage('ENTER_SCRAP_CODE'));
            _Steps.Set_label(MobWmsLanguage.GetMessage('SCRAP_CODE') + ':');
            _Steps.Set_helpLabel('');
            _Steps.Set_optional(true);
            _Steps.Set_dataTable('ScrapCode');
            _Steps.Set_dataKeyColumn('Code');
            _Steps.Set_dataDisplayColumn('Name');
            _Steps.Save();
        end;

        if IncludeQuantityStep or IncludeCodeStep then
            MobWmsAdhocRegistr.OnGetRegistrationConfigurationOnProdOutput_OnAddStepsToProductionOutput(_LookupResponse, _Steps);

        //
        // Events
        //
        _Steps.SetMustCallCreateNext(true);
        MobWmsAdhocRegistr.OnGetRegistrationConfigurationOnProdOutput_OnAddStepsToProductionOutputScrap(_LookupResponse, _IncludeAllSteps, _Steps);
        _Steps.SetMustCallCreateNext(false);
        if _Steps.FindSet() then
            repeat
                MobWmsAdhocRegistr.OnGetRegistrationConfigurationOnProdOutput_OnAfterAddStepToProductionOutputScrap(_RegistrationType, _LookupResponse, _Steps);
            until _Steps.Next() = 0;
    end;

    //
    // ------- Posting Time Tracking -------
    //

    /// <summary>
    /// Post Time Tracking (create+apply Time Tracking Entry. Posting using PostProdOutput() as RegistrationType::ProdOutputTime)
    /// </summary>
    local procedure PostProdOutputTimeTracking(_MobDocQueue: Record "MOB Document Queue"; var _RequestValues: Record "MOB NS Request Element"; var _SuccessMessage: Text; var _ReturnRegistrationTypeTracking: Text)
    var
        ProdOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
        NewTimeTrackingEntry: Record "MOB Time Tracking Entry";
        MobTimeTrackingMgt: Codeunit "MOB Time Tracking Management";
        ProdOrderRtngLineRecordId: RecordId;
        ProdOrderNo: Code[20];
        ProdOrderLineNo: Integer;
        CollectedStatusOption: Text;
        CollectedDateTime: DateTime;
        NewTimeTrackingEntryType: Enum "MOB Time Tracking Entry Type";
        NewTimeTrackingStatus: Enum "MOB Time Tracking Status";
    begin
        // Disable the locktimeout to prevent timeout messages on the mobile device
        LockTimeout(false);

        MobWmsToolbox.GetOrderNoAndOrderLineNoFromBackendId(_RequestValues.GetValue('BackendID', true), ProdOrderNo, ProdOrderLineNo);

        if not _RequestValues.HasValue('StatusOption') then begin // Time cannot be registered (no route)
            _ReturnRegistrationTypeTracking := StrSubstNo('%1 - %2', ProdOrderNo, ProdOrderLineNo);
            _SuccessMessage := MobWmsLanguage.GetMessage('NOTHING_TO_REGISTER');
            exit;
        end;

        CollectedStatusOption := _RequestValues.GetValue('StatusOption', true); // Text string based on translated text constants i.e. "Start Run"
        CollectedDateTime := _RequestValues.GetValueAsDateTime('DateTime', true);

        // Make sure that the released prod. order line still exists
        ProdOrder.Get(ProdOrder.Status::Released, ProdOrderNo);
        ProdOrderLine.Get(ProdOrderLine.Status::Released, ProdOrderNo, ProdOrderLineNo);

        _ReturnRegistrationTypeTracking := StrSubstNo('%1 - %2', ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.");

        ErrorIfItemProductionOutputBlocked(ProdOrderLine."Item No.", ProdOrderLine."Variant Code");

        // Find the routing line the time tracking is for
        Clear(ProdOrderRtngLine);
        Evaluate(ProdOrderRtngLineRecordId, _RequestValues.GetValueOrContextValue('ProdOrderRtngLine_RecordId', true));
        GetProdOrderRoutingLineFromRecordId(ProdOrderRtngLine, ProdOrderRtngLineRecordId, true);    // Must exist

        case CollectedStatusOption of
            MobWmsLanguage.GetMessage('START_SETUP'):
                begin
                    NewTimeTrackingEntryType := "MOB Time Tracking Entry Type"::"Production Output Setup Time";
                    NewTimeTrackingStatus := "MOB Time Tracking Status"::Started;
                end;
            MobWmsLanguage.GetMessage('STOP_SETUP'):
                begin
                    NewTimeTrackingEntryType := "MOB Time Tracking Entry Type"::"Production Output Setup Time";
                    NewTimeTrackingStatus := "MOB Time Tracking Status"::Stopped;
                end;
            MobWmsLanguage.GetMessage('START_RUN'):
                begin
                    NewTimeTrackingEntryType := "MOB Time Tracking Entry Type"::"Production Output Run Time";
                    NewTimeTrackingStatus := "MOB Time Tracking Status"::Started;
                end;
            MobWmsLanguage.GetMessage('STOP_RUN'):
                begin
                    NewTimeTrackingEntryType := "MOB Time Tracking Entry Type"::"Production Output Run Time";
                    NewTimeTrackingStatus := "MOB Time Tracking Status"::Stopped;
                end;
        end;

        // Init new entry, but do not insert due to commit in ProdOutputTime function
        MobTimeTrackingMgt.InitTimeTrackingEntry(
            NewTimeTrackingEntry,
            ProdOrderRtngLine.RecordId(),
            NewTimeTrackingEntryType,
            NewTimeTrackingStatus,
            CollectedDateTime);

        // Update requestValues to mirror code from PostOutputTime
        if NewTimeTrackingEntry.Quantity <> 0 then begin
            if NewTimeTrackingEntry."Time Tracking Entry Type" = "MOB Time Tracking Entry Type"::"Production Output Setup Time" then
                _RequestValues.InsertElement('SetupTime', MobToolbox.Variant2TextResponseFormat(NewTimeTrackingEntry.Quantity));
            if NewTimeTrackingEntry."Time Tracking Entry Type" = "MOB Time Tracking Entry Type"::"Production Output Run Time" then
                _RequestValues.InsertElement('RunTime', MobToolbox.Variant2TextResponseFormat(NewTimeTrackingEntry.Quantity));

            // Re-use posting function for ProdOutputTime
            PostProdOutput(MobWmsToolbox."CONST::ProdOutputTime"(), _MobDocQueue, _RequestValues, _SuccessMessage, _ReturnRegistrationTypeTracking);
        end;

        // Delayed write new entry and entry application to DB (following Production Journal posting and commit)
        NewTimeTrackingEntry.Insert();
        if NewTimeTrackingEntry."Time Tracking Status" = NewTimeTrackingEntry."Time Tracking Status"::Stopped then
            MobTimeTrackingMgt.ApplyStopTimeTrackingEntry(NewTimeTrackingEntry);
    end;

    //
    // ------- Posting ProdOutput -------
    //

    /// <summary>
    /// Post Production Output (always a single Adhoc Registation, no iteration)
    /// </summary>
    local procedure PostProdOutput(_RegistrationType: Text; _MobDocQueue: Record "MOB Document Queue"; var _RequestValues: Record "MOB NS Request Element"; var _SuccessMessage: Text; var _ReturnRegistrationTypeTracking: Text)
    var
        MobSetup: Record "MOB Setup";
        AppliesToItemLedgEntry: Record "Item Ledger Entry";
        OutputJnlLine: Record "Item Journal Line";
        ProdOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
        TempReservationEntry: Record "Reservation Entry" temporary;
        TempTrackingSpec: Record "Tracking Specification" temporary;
        MobTrackingSetupThisOperation: Record "MOB Tracking Setup";
        ItemJnlPostBatch: Codeunit "Item Jnl.-Post Batch";
        UoMMgt: Codeunit "Unit of Measure Management";
        ProductionJnlMgt: Codeunit "Production Journal Mgt";
        MobProductionJnlMgt: Codeunit "MOB Production Journal Mgt";
        MobSyncItemTracking: Codeunit "MOB Sync. Item Tracking";
        MobWmsAdhocRegistr: Codeunit "MOB WMS Adhoc Registr.";
        MobLicensePlateProdOutput: Codeunit "MOB License Plate Prod Output";
        MobUoMMgt: Codeunit "MOB Unit of Measure Management";
        ProdOrderRtngLineRecordId: RecordId;
        BackendID: Code[40];
        ProdOrderNo: Code[20];
        ProdOrderLineNo: Integer;
        ToTemplateName: Code[10];
        ToBatchName: Code[10];
        ResultMessage: Text;
        ExpDateRequiredThisOperation: Boolean;
        ToBinCode: Code[20];
        Quantity: Decimal;
        IsLastOperation: Boolean;
        SetupTime: Decimal;
        RunTime: Decimal;
        PostingOutputQty: Boolean;
        PostingOutputTime: Boolean;
        PostingScrapQty: Boolean;
        PostingScrapCode: Code[10];
        SetupTimeFactor: Decimal;
        RunTimeFactor: Decimal;
    begin
        PostingOutputQty := _RegistrationType in [MobWmsToolbox."CONST::ProdOutput"(), MobWmsToolbox."CONST::ProdOutputQuantity"()];
        PostingOutputTime := _RegistrationType in [MobWmsToolbox."CONST::ProdOutput"(), MobWmsToolbox."CONST::ProdOutputTime"()];
        PostingScrapQty := _RegistrationType in [MobWmsToolbox."CONST::ProdOutput"(), MobWmsToolbox."CONST::ProdOutputScrap"()];

        // Disable the locktimeout to prevent timeout messages on the mobile device
        LockTimeout(false);

        MobSetup.Get();

        Evaluate(BackendID, _RequestValues.GetValue('BackendID', true));
        MobWmsToolbox.GetOrderNoAndOrderLineNoFromBackendId(BackendID, ProdOrderNo, ProdOrderLineNo);

        // Make sure that the released prod. order line still exists
        ProdOrder.Get(ProdOrder.Status::Released, ProdOrderNo);
        ProdOrderLine.Get(ProdOrderLine.Status::Released, ProdOrderNo, ProdOrderLineNo);

        _ReturnRegistrationTypeTracking := StrSubstNo('%1 - %2', ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.");

        // Create production jnl. and reset all lines to zero
        MobProductionJnlMgt.CreateAndResetJnlLines(ProdOrder, ProdOrderLine, ToTemplateName, ToBatchName);     // MAY COMMIT

        // Turn on commit protection to prevent unintentional committing data
        _MobDocQueue.Consistent(false);

        // Lock the tables to work on
        ProdOrderLine.LockTable();
        OutputJnlLine.LockTable();  // is Item Jnl. Line

        // Re-read due to possible commit above.
        ProdOrder.Get(ProdOrder.Status::Released, ProdOrderNo);
        ProdOrderLine.Get(ProdOrderLine.Status::Released, ProdOrderNo, ProdOrderLineNo);

        // Find the routing line the output is for (may not have any routing but the ProdOrderRtngLine_RecordId tag must be in the xml)
        Clear(ProdOrderRtngLine);
        Evaluate(ProdOrderRtngLineRecordId, _RequestValues.GetValueOrContextValue('ProdOrderRtngLine_RecordId', true));
        if not ProdOrderRoutingLineRecordIdIsEmpty(ProdOrderRtngLineRecordId) then
            GetProdOrderRoutingLineFromRecordId(ProdOrderRtngLine, ProdOrderRtngLineRecordId, true);
        IsLastOperation := ProdOrderRtngLine."Next Operation No." = '';

        FindOutputJnlLine(ToTemplateName, ToBatchName, ProdOrderLine, ProdOrderRtngLine, OutputJnlLine);

        if IsLastOperation then
            // MobTrackingSetupThisOperation.Tracking: Copy later in this procedure
            MobTrackingSetupThisOperation.DetermineManufInboundTrackingRequiredFromItemNo(ProdOrderLine."Item No.", ExpDateRequiredThisOperation)
        else begin
            Clear(MobTrackingSetupThisOperation);   // No TrackingRequired or Tracking Values unless IsLastOperation
            Clear(ExpDateRequiredThisOperation);
        end;

        //
        // Populate OutputJnl for PostProdOutputQuantity
        //
        if PostingOutputQty then begin
            ToBinCode := _RequestValues.Get_ToBin();
            if ToBinCode <> '' then
                OutputJnlLine.Validate("Bin Code", ToBinCode);

            if MobTrackingSetupThisOperation."Serial No. Required" then
                Quantity := 1
            else
                Quantity := _RequestValues.GetValueAsDecimal('Quantity', true); // lowercase from "workflow"

            if MobSetup."Use Base Unit of Measure" then
                OutputJnlLine.Validate("Output Quantity", UoMMgt.CalcQtyFromBase(Quantity, ProdOrderLine."Qty. per Unit of Measure"))
            else
                OutputJnlLine.Validate("Output Quantity", Quantity);
        end;

        //
        // Populate OutputJnl for PostProdOutputTime
        //
        if PostingOutputTime then begin
            SetupTime := _RequestValues.GetValueAsDecimal('SetupTime');
            RunTime := _RequestValues.GetValueAsDecimal('RunTime');

            if (ProdOrderRtngLine."Work Center No." <> '') and (OutputJnlLine."Cap. Unit of Measure Code" <> ProdOrderRtngLine."Setup Time Unit of Meas. Code") then
                SetupTimeFactor := QtyperTimeUnitofMeasure(ProdOrderRtngLine."Work Center No.", ProdOrderRtngLine."Setup Time Unit of Meas. Code")
            else
                SetupTimeFactor := 1;

            if (ProdOrderRtngLine."Work Center No." <> '') and (OutputJnlLine."Cap. Unit of Measure Code" <> ProdOrderRtngLine."Run Time Unit of Meas. Code") then
                RunTimeFactor := QtyperTimeUnitofMeasure(ProdOrderRtngLine."Work Center No.", ProdOrderRtngLine."Run Time Unit of Meas. Code")
            else
                RunTimeFactor := 1;

            OutputJnlLine.Validate("Setup Time", Round(SetupTime * SetupTimeFactor, MobUoMMgt.TimeRndPrecision()));
            OutputJnlLine.Validate("Run Time", Round(RunTime * RunTimeFactor, MobUoMMgt.TimeRndPrecision()));
        end;

        //
        // Populate OutputJnl for PostProdOutputScrap
        //
        if PostingScrapQty then begin
            Quantity := _RequestValues.GetValueAsDecimal('ScrapQuantity', true);

            if MobSetup."Use Base Unit of Measure" then
                OutputJnlLine.Validate("Scrap Quantity", UoMMgt.CalcQtyFromBase(Quantity, ProdOrderLine."Qty. per Unit of Measure"))
            else
                OutputJnlLine.Validate("Scrap Quantity", Quantity);

            if OutputJnlLine."Scrap Quantity" <> 0 then begin
                PostingScrapCode := _RequestValues.GetValue('ScrapCode', false);  // Optional
                if PostingScrapCode <> '' then
                    OutputJnlLine.Validate("Scrap Code", PostingScrapCode);
            end;
        end;

        // Event: OnAfterCreate....  // Not really a "create"... but kept like this for consistent event naming
        MobWmsAdhocRegistr.OnPostAdhocRegistrationOnProdOutput_OnAfterCreateProductionJnlLine(_RequestValues, OutputJnlLine);
        OutputJnlLine.Modify(true);

        if IsLastOperation and MobTrackingSetupThisOperation.TrackingRequired() and (OutputJnlLine."Output Quantity" <> 0) then begin
            // MobTrackingSetupThisOperation.TrackingRequired: Determined before (earlier in this procedure)
            MobTrackingSetupThisOperation.CopyTrackingFromRequestValuesIfRequired(_RequestValues, true);

            TempTrackingSpec.Init();
            MobTrackingSetupThisOperation.CopyTrackingToTrackingSpec(TempTrackingSpec); // Indirectly only when required due to CopyTrackingFromRequestValuesIfRequired above
            if ExpDateRequiredThisOperation then
                TempTrackingSpec."Expiration Date" := _RequestValues.GetValueAsDate('ExpirationDate', true);
            MobSyncItemTracking.CreateTempReservEntryForItemJnlLineFromTrackingSpecWithoutQty(OutputJnlLine, true, TempTrackingSpec, TempReservationEntry, OutputJnlLine."Output Quantity (Base)");
        end;

        //
        // Primitive application for negative Output
        //
        if IsLastOperation and (OutputJnlLine."Output Quantity" < 0) then begin
            FilterAppliesToItemEntry(OutputJnlLine, AppliesToItemLedgEntry);
            AppliesToItemLedgEntry.SetFilter(Quantity, '>=%1', Abs(OutputJnlLine."Output Quantity"));
            AppliesToItemLedgEntry.SetTrackingFilterFromSpec(TempTrackingSpec);

            if AppliesToItemLedgEntry.FindLast() then
                if MobTrackingSetupThisOperation.TrackingRequired() then begin
                    TempReservationEntry."Appl.-to Item Entry" := AppliesToItemLedgEntry."Entry No.";
                    TempReservationEntry.Modify();
                end else begin
                    OutputJnlLine.Validate("Applies-to Entry", AppliesToItemLedgEntry."Entry No.");
                    OutputJnlLine.Modify();
                end;
        end;

        //
        // Register Output to License Plate
        //
        MobLicensePlateProdOutput.CheckAndRegisterOutputToLicensePlate(ProdOrderLine, IsLastOperation, PostingOutputQty, _RequestValues, _ReturnRegistrationTypeTracking);

        // Post applied lines from consumption journal
        MobSyncItemTracking.Run(TempReservationEntry);
        MobProductionJnlMgt.DeleteJnlLinesWithNoRegistrations(ToTemplateName, ToBatchName, ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.");
        if OutputJnlLine.Get(OutputJnlLine."Journal Template Name", OutputJnlLine."Journal Batch Name", OutputJnlLine."Line No.") then begin
            _MobDocQueue.Consistent(true);
            Commit();

            Clear(ItemJnlPostBatch);
            ItemJnlPostBatch.SetSuppressCommit(true);

            // Journal Batch Name is per user: Post only lines in this batch for exact Prod. Order Line No. 
            // Same batch may hold lines for other production order lines if same userid is reused for multiple mobile users
            OutputJnlLine.Reset();
            OutputJnlLine.SetRange("Journal Template Name", OutputJnlLine."Journal Template Name");
            OutputJnlLine.SetRange("Journal Batch Name", OutputJnlLine."Journal Batch Name");
            OutputJnlLine.SetRange("Entry Type", OutputJnlLine."Entry Type"::Output);
            OutputJnlLine.SetRange("Order Type", OutputJnlLine."Order Type"::Production);
            OutputJnlLine.SetRange("Order No.", OutputJnlLine."Order No.");
            OutputJnlLine.SetRange("Order Line No.", OutputJnlLine."Order Line No.");
            if not ItemJnlPostBatch.Run(OutputJnlLine) then begin
                ProductionJnlMgt.DeleteJnlLines(ToTemplateName, ToBatchName, ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.");
                MobWmsToolbox.DeleteRegistrationData(_MobDocQueue.MessageIDAsGuid());
                Commit();
                ResultMessage := GetLastErrorText();
                MobSessionData.SetPreservedLastErrorCallStack();
                Error(ResultMessage);

            end
        end else
            _SuccessMessage := MobWmsLanguage.GetMessage('NOTHING_TO_REGISTER');

        // Turn commit protection off again
        _MobDocQueue.Consistent(true);


        // Create a response inside the <description> element of the document response
        if _RegistrationType <> MobWmsToolbox."CONST::ProdOutput"() then
            _SuccessMessage := MobWmsLanguage.GetMessage('REG_TRANS_SUCCESS');
    end;

    local procedure FindOutputJnlLine(_ToTemplateName: Code[10]; _ToBatchName: Code[10]; _ProdOrderLine: Record "Prod. Order Line"; _ProdOrderRtngLine: Record "Prod. Order Routing Line"; var _OutputJnlLine: Record "Item Journal Line")
    var
        ItemJnlLine: Record "Item Journal Line";
    begin
        ItemJnlLine.Reset();
        ItemJnlLine.SetRange("Journal Template Name", _ToTemplateName);
        ItemJnlLine.SetRange("Journal Batch Name", _ToBatchName);
        // No filter for ItemJnlLine."Line No." -- was assigned sequentially from NextLineNo
        ItemJnlLine.SetRange("Entry Type", ItemJnlLine."Entry Type"::Output);
        ItemJnlLine.SetRange("Order Type", ItemJnlLine."Order Type"::Production);
        ItemJnlLine.SetRange("Order No.", _ProdOrderLine."Prod. Order No.");
        ItemJnlLine.SetRange("Order Line No.", _ProdOrderLine."Line No.");
        ItemJnlLine.SetRange("Item No.", _ProdOrderLine."Item No.");
        ItemJnlLine.SetRange("Variant Code", _ProdOrderLine."Variant Code");
        ItemJnlLine.SetRange("Location Code", _ProdOrderLine."Location Code");
        if _ProdOrderLine."Bin Code" <> '' then
            ItemJnlLine.SetRange("Bin Code", _ProdOrderLine."Bin Code");
        ItemJnlLine.SetRange("Routing No.", _ProdOrderLine."Routing No.");
        ItemJnlLine.SetRange("Routing Reference No.", _ProdOrderLine."Routing Reference No.");
        if _ProdOrderRtngLine."Prod. Order No." <> '' then
            ItemJnlLine.SetRange("Operation No.", _ProdOrderRtngLine."Operation No.");
        ItemJnlLine.SetRange("Unit of Measure Code", _ProdOrderLine."Unit of Measure Code");
        ItemJnlLine.FindFirst();

        _OutputJnlLine := ItemJnlLine;
    end;

    /// <summary>
    /// Based on ItemJnlLine.SelectItemEntry() but rewritten to no longer be a lookup but to filter possible applications for negative Output
    /// </summary>
    local procedure FilterAppliesToItemEntry(_ItemJnlLine: Record "Item Journal Line"; var _ItemLedgEntry: Record "Item Ledger Entry")
    var
        PositiveFilterValue: Boolean;
    begin
        _ItemJnlLine.TestField("Order Type", _ItemJnlLine."Order Type"::Production);
        _ItemJnlLine.TestField("Entry Type", _ItemJnlLine."Entry Type"::Output);
        if _ItemJnlLine."Value Entry Type" = _ItemJnlLine."Value Entry Type"::Revaluation then
            _ItemJnlLine.FieldError("Value Entry Type");

        _ItemLedgEntry.Reset();
        _ItemLedgEntry.SetCurrentKey(
            "Order Type", "Order No.", "Order Line No.", "Entry Type", "Prod. Order Comp. Line No.");
        _ItemLedgEntry.SetRange("Order Type", _ItemJnlLine."Order Type");
        _ItemLedgEntry.SetRange("Order No.", _ItemJnlLine."Order No.");
        _ItemLedgEntry.SetRange("Order Line No.", _ItemJnlLine."Order Line No.");
        _ItemLedgEntry.SetRange("Entry Type", _ItemJnlLine."Entry Type");
        _ItemLedgEntry.SetRange("Prod. Order Comp. Line No.", 0);

        if _ItemJnlLine."Location Code" <> '' then
            _ItemLedgEntry.SetRange("Location Code", _ItemJnlLine."Location Code");

        if _ItemJnlLine.Quantity <> 0 then begin
            PositiveFilterValue := (_ItemJnlLine.Signed(_ItemJnlLine.Quantity) < 0) or (_ItemJnlLine."Value Entry Type" = _ItemJnlLine."Value Entry Type"::Revaluation);    // Revaluation shouldn't happen from Output, though
            _ItemLedgEntry.SetRange(Positive, PositiveFilterValue);
        end;

        _ItemLedgEntry.SetCurrentKey("Item No.", Open);
        _ItemLedgEntry.SetRange(Open, true);
    end;

    //
    // Post Finish Route Operation
    //
    local procedure PostFinishRouteOperation(_MobDocQueue: Record "MOB Document Queue"; var _RequestValues: Record "MOB NS Request Element"; var _SuccessMessage: Text; var _ReturnRegistrationTypeTracking: Text)
    var
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
        ProdOrderCapacityNeed: Record "Prod. Order Capacity Need";
        ProdOrderRtngLineRecordId: RecordId;
        XmlRequestDoc: XmlDocument;
        RoutingExists: Boolean;
    begin
        Evaluate(ProdOrderRtngLineRecordId, _RequestValues.GetValueOrContextValue('ProdOrderRtngLine_RecordId', false));   // Intentionally suppress error to provide a better error message below when called on empty list
        RoutingExists := not ProdOrderRoutingLineRecordIdIsEmpty(ProdOrderRtngLineRecordId);

        // Set the tracking value displayed in the document queue
        if RoutingExists then
            _ReturnRegistrationTypeTracking := Format(ProdOrderRtngLineRecordId)
        else begin
            _ReturnRegistrationTypeTracking := _RequestValues.GetValue('BackendID', true);
            _MobDocQueue.SetRegistrationTypeAndTracking(MobWmsToolbox."CONST::ProdOutputFinishOperation"(), _ReturnRegistrationTypeTracking);
            Error(MobWmsLanguage.GetMessage('NOT_A_ROUTE_OPERATION'));
        end;

        _MobDocQueue.LoadXMLRequestDoc(XmlRequestDoc);
        MobToolbox.ErrorIfNotConfirm(StrSubstNo((MobWmsLanguage.GetMessage('FINISH_OPERATION_X') + '?'), _RequestValues.GetValueOrContextValue('DisplayLine1')), XmlRequestDoc);

        ProdOrderRtngLine.Get(ProdOrderRtngLineRecordId);
        ProdOrderRtngLine."Routing Status" := ProdOrderRtngLine."Routing Status"::Finished;
        ProdOrderRtngLine.Modify(false);    // Intentionally suppress error from standard OnModify code when "Routing Status" is finished

        // Duplicated code from ProdOrderRtngLine."Routing Status".OnValidate()
        ProdOrderCapacityNeed.Reset();
        ProdOrderCapacityNeed.SetCurrentKey(Status, "Prod. Order No.", "Requested Only", "Routing No.", "Routing Reference No.", "Operation No.", "Line No.");
        ProdOrderCapacityNeed.SetRange(Status, ProdOrderRtngLine.Status);
        ProdOrderCapacityNeed.SetRange("Prod. Order No.", ProdOrderRtngLine."Prod. Order No.");
        ProdOrderCapacityNeed.SetRange("Requested Only", false);
        ProdOrderCapacityNeed.SetRange("Routing No.", ProdOrderRtngLine."Routing No.");
        ProdOrderCapacityNeed.SetRange("Routing Reference No.", ProdOrderRtngLine."Routing Reference No.");
        ProdOrderCapacityNeed.SetRange("Operation No.", ProdOrderRtngLine."Operation No.");
        ProdOrderCapacityNeed.ModifyAll("Allocated Time", 0);

        _SuccessMessage := ''; // No message (page is closed on postSuccess)
    end;

    //
    // ------- IntegrationEvents: OnLookupOnProdOutput -------
    //
    // OnLookupOnProdOutput_OnSetFilterProdOrderRoutingLine
    // OnLookupOnProdOutput_OnIncludeProductionOutput
    // OnLookupOnProdOutput_OnAfterSetFromProductionOutput
    // OnLookupOnAnyLookupType_OnAfterSetCurrentKey
    //
    // See: "MOB WMS Lookup".OnLookupOnProdOutput_OnXXX()
    ///

    //
    // ------- IntegrationEvents: OnGetRegistrationConfigurationOnProdOutput -------
    //
    // OnAddStepsToProductionOutput : not implemented as possible steps should be same for "workflow" (clicking the lookup line) and actions (separately clicking Quantity/Time/Scrap adhoc)
    // OnGetRegistrationConfigurationOnProdOutput_OnAddStepsToProductionOutputQuantity
    // OnGetRegistrationConfigurationOnProdOutput_OnAddStepsToProductionOutputTime
    // OnGetRegistrationConfigurationOnProdOutput_OnAddStepsToProductionOutputScrap
    //
    // See: "MOB WMS Adhoc Registr".OnPostAdhocRegistrationOnProdOutput_OnAAddStepsToXXX()
    //

    //
    // ------- IntegrationEvents: OnPostAdhocRegistrationOnProdOutput -------
    //
    // OnPostProdOutput_OnBeforePostProdOrderLine : not implemented as adhocregistrations has a single registration only (use OnAfterCreateItemJnlLine instead)
    // OnPostProdOutput_OnHandleRegistrationForOutputJnlLine : not implemented as adhocregistrations has a single registration only (use OnAfterCreateItemJnlLine instead)
    // OnBeforeRunItemJnlPostBatch: not implemented as this posting codeunit as no addtional parameters to set
    //
    // See: "MOB WMS Adhoc Registr".OnPostAdhocRegistrationOnProdOutput_OnAfterCreateProductionJnlLine()
    //

}
