codeunit 81450 "MOB Package Management"
{
    Access = Public;
    /* #if BC14,BC15,BC16,BC17 ## 
    procedure IsEnabled(): Boolean
    begin
        exit(false); // Not supported in Mobile WMS until 18.0 (table ItemTrackingSetup is supported from 16.0 but not in Mobile WMS)
    end;
    /* #endif */

    /* #if BC18+ */
    EventSubscriberInstance = Manual;

    var
        MobToolbox: Codeunit "MOB Toolbox";
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";

    internal procedure IsEnabled() FeatureEnabled: Boolean
    var
        MobSetup: Record "MOB Setup";
    begin
        FeatureEnabled := MobSetup.Get() and (MobSetup."Package No. implementation" = 1);    // 1 = "Standard Mobile WMS" / MOB Package Management is deployed as EventSubscriberInstance = Manual
    end;

    //
    // ------- PackageNumber Steps -------
    // 

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Receive", 'OnGetReceiveOrderLines_OnAddStepsToAnyLine', '', true, true)]
    local procedure OnGetReceiveOrderLines_OnAddStepsToAnyLine(_RecRef: RecordRef; var _BaseOrderLineElement: Record "MOB NS BaseDataModel Element"; var _Steps: Record "MOB Steps Element")
    begin
        if _BaseOrderLineElement.Get_RegisterPackageNumber() = 'true' then begin
            _Steps.Create_TextStep_PackageNumber(37, false);
            _Steps.Set_defaultValue('{PackageNumber}');
            _Steps.Set_validationValues(_BaseOrderLineElement.Get_PackageNumber()); // Mirror default behavior in Mobile App for SerialNumber and LotNumber steps (pre-populated value cannot be changed, but validationWarningType is not supported on custom Text steps)
            _Steps.Set_validationCaseSensitive(false);
            _Steps.Save();
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Put Away", 'OnGetPutAwayOrderLines_OnAddStepsToWarehouseActivityLine', '', true, true)]
    local procedure OnGetPutAwayOrderLines_OnAddStepsToWarehouseActivityLine(_WhseActivityLine: Record "Warehouse Activity Line"; var _BaseOrderLineElement: Record "MOB NS BaseDataModel Element"; var _Steps: Record "MOB Steps Element")
    begin
        if _BaseOrderLineElement.Get_RegisterPackageNumber() = 'true' then begin
            _Steps.Create_TextStep_PackageNumber(37, false);
            _Steps.Set_defaultValue('{PackageNumber}');
            _Steps.Set_validationValues(_BaseOrderLineElement.Get_PackageNumber()); // Mirror default behavior in Mobile App for SerialNumber and LotNumber steps (pre-populated value cannot be changed, but validationWarningType is not supported on custom Text steps)
            _Steps.Set_validationCaseSensitive(false);
            _Steps.Save();
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Pick", 'OnGetPickOrderLines_OnAddStepsToAnyLine', '', true, true)]
    local procedure OnGetPickOrderLines_OnAddStepsToAnyLine(_RecRef: RecordRef; var _BaseOrderLineElement: Record "MOB NS BaseDataModel Element"; var _Steps: Record "MOB Steps Element")
    begin
        if _BaseOrderLineElement.Get_RegisterPackageNumber() = 'true' then begin
            _Steps.Create_TextStep_PackageNumber(37, false);
            _Steps.Set_defaultValue('{PackageNumber}');
            _Steps.Set_validationValues(_BaseOrderLineElement.Get_PackageNumber()); // Mirror default behavior in Mobile App for SerialNumber and LotNumber steps (pre-populated value cannot be changed, but validationWarningType is not supported on custom Text steps)
            _Steps.Set_validationCaseSensitive(false);
            _Steps.Save();
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Ship", 'OnGetShipOrderLines_OnAddStepsToWarehouseShipmentLine', '', true, true)]
    local procedure OnGetShipOrderLines_OnAddStepsToWarehouseShipmentLine(_WhseShipmentLine: Record "Warehouse Shipment Line"; _MobTrackingSetup: Record "MOB Tracking Setup"; var _BaseOrderLineElement: Record "MOB NS BaseDataModel Element"; var _Steps: Record "MOB Steps Element")
    begin
        if _BaseOrderLineElement.Get_RegisterPackageNumber() = 'true' then begin
            _Steps.Create_TextStep_PackageNumber(37, false);
            _Steps.Set_defaultValue('{PackageNumber}');
            _Steps.Set_validationValues(_BaseOrderLineElement.Get_PackageNumber()); // Mirror default behavior in Mobile App for SerialNumber and LotNumber steps (pre-populated value cannot be changed, but validationWarningType is not supported on custom Text steps)
            _Steps.Set_validationCaseSensitive(false);
            _Steps.Save();
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Count", 'OnGetCountOrderLines_OnAddStepsToAnyLine', '', true, true)]
    local procedure OnGetCountOrderLines_OnAddStepsToAnyLine(_RecRef: RecordRef; var _BaseOrderLineElement: Record "MOB NS BaseDataModel Element"; var _Steps: Record "MOB Steps Element")
    begin
        if _BaseOrderLineElement.Get_RegisterPackageNumber() = 'true' then begin
            _Steps.Create_TextStep_PackageNumber(37, false);
            _Steps.Set_defaultValue('{PackageNumber}');
            _Steps.Set_validationValues(_BaseOrderLineElement.Get_PackageNumber()); // Mirror default behavior in Mobile App for SerialNumber and LotNumber steps (pre-populated value cannot be changed, but validationWarningType is not supported on custom Text steps)
            _Steps.Set_validationCaseSensitive(false);
            _Steps.Save();
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Move", 'OnGetMoveOrderLines_OnAddStepsToWarehouseActivityLine', '', true, true)]
    local procedure OnGetMoveOrderLines_OnAddStepsToWarehouseActivityLine(_WhseActivityLine: Record "Warehouse Activity Line"; var _BaseOrderLineElement: Record "MOB NS BaseDataModel Element"; var _Steps: Record "MOB Steps Element")
    begin
        if _BaseOrderLineElement.Get_RegisterPackageNumber() = 'true' then begin
            _Steps.Create_TextStep_PackageNumber(37, false);
            _Steps.Set_defaultValue('{PackageNumber}');
            _Steps.Set_validationValues(_BaseOrderLineElement.Get_PackageNumber()); // Mirror default behavior in Mobile App for SerialNumber and LotNumber steps (pre-populated value cannot be changed, but validationWarningType is not supported on custom Text steps)
            _Steps.Set_validationCaseSensitive(false);
            _Steps.Save();
        end;
    end;

    //
    // PackageNo supported in standard Phys. Invt. Recording from BC24+ if feature is enabled
    //
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Phys Invt Recording", 'OnGetPhysInvtRecordingLines_OnAddStepsToPhysInvtRecordLine', '', true, true)]
    local procedure OnGetPhysInvtRecordingLines_OnAddStepsToPhysInvtRecordLine(_PhysInvtRecordLine: Record "Phys. Invt. Record Line"; var _BaseOrderLineElement: Record "MOB NS BaseDataModel Element"; var _Steps: Record "MOB Steps Element")
    begin
        if FeaturePhysInvtOrderPackageTrackingEnabled() then
            if _BaseOrderLineElement.Get_RegisterPackageNumber() = 'true' then begin
                _Steps.Create_TextStep_PackageNumber(37, false);
                _Steps.Set_defaultValue('{PackageNumber}');
                _Steps.Set_validationValues(_BaseOrderLineElement.Get_PackageNumber()); // Mirror default behavior in Mobile App for SerialNumber and LotNumber steps (pre-populated value cannot be changed, but validationWarningType is not supported on custom Text steps)
                _Steps.Set_validationCaseSensitive(false);
                _Steps.Save();
            end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Production Consumption", 'OnGetProdConsumptionLines_OnAddStepsToProdOrderComponent', '', true, true)]
    local procedure OnGetProdConsumptionLines_OnAddStepsToProdOrderComponent(_ProdOrderComponent: Record "Prod. Order Component"; _TrackingSpecification: Record "Tracking Specification"; var _BaseOrderLineElement: Record "MOB NS BaseDataModel Element"; var _Steps: Record "MOB Steps Element")
    begin
        if _BaseOrderLineElement.Get_RegisterPackageNumber() = 'true' then begin
            _Steps.Create_TextStep_PackageNumber(37, false);
            _Steps.Set_defaultValue('{PackageNumber}');
            _Steps.Set_validationValues(_BaseOrderLineElement.Get_PackageNumber()); // Mirror default behavior in Mobile App for SerialNumber and LotNumber steps (pre-populated value cannot be changed, but validationWarningType is not supported on custom Text steps)
            _Steps.Set_validationCaseSensitive(false);
            _Steps.Save();
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Assembly", 'OnGetAssemblyOrderLines_OnAddStepsToOutputLine', '', true, true)]
    local procedure OnGetAssemblyOrderLines_OnAddStepsToOutputLine(_AssemblyHeader: Record "Assembly Header"; var _BaseOrderLineElement: Record "MOB NS BaseDataModel Element"; var _Steps: Record "MOB Steps Element")
    begin
        if _BaseOrderLineElement.Get_RegisterPackageNumber() = 'true' then begin
            _Steps.Create_TextStep_PackageNumber(37, false);
            _Steps.Set_defaultValue('{PackageNumber}');    // Usually no default PackageNo for Prod.Output
            _Steps.Set_validationValues(_BaseOrderLineElement.Get_PackageNumber()); // Mirror default behavior in Mobile App for SerialNumber and LotNumber steps (pre-populated value cannot be changed, but validationWarningType is not supported on custom Text steps)
            _Steps.Set_validationCaseSensitive(false);
            _Steps.Save();
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Assembly", 'OnGetAssemblyOrderLines_OnAddStepsToConsumptionLine', '', true, true)]
    local procedure OnGetAssemblyOrderLines_OnAddStepsToConsumptionLine(_AssemblyLine: Record "Assembly Line"; _TrackingSpecification: Record "Tracking Specification"; var _BaseOrderLineElement: Record "MOB NS BaseDataModel Element"; var _Steps: Record "MOB Steps Element")
    begin
        if _BaseOrderLineElement.Get_RegisterPackageNumber() = 'true' then begin
            _Steps.Create_TextStep_PackageNumber(37, false);
            _Steps.Set_defaultValue('{PackageNumber}');
            _Steps.Set_validationValues(_BaseOrderLineElement.Get_PackageNumber()); // Mirror default behavior in Mobile App for SerialNumber and LotNumber steps (pre-populated value cannot be changed, but validationWarningType is not supported on custom Text steps)
            _Steps.Set_validationCaseSensitive(false);
            _Steps.Save();
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Toolbox", 'OnSaveRegistrationValue', '', true, true)]
    local procedure OnSaveRegistrationValue(_Path: Text; _Value: Text; var _MobileWMSRegistration: Record "MOB WMS Registration"; var _IsHandled: Boolean)
    begin
        if _Path <> 'PackageNumber' then
            exit;

        Evaluate(_MobileWMSRegistration.PackageNumber, _Value);
        _IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Toolbox", 'OnSaveRealtimeRegistrationValue', '', true, true)]
    local procedure OnSaveRealtimeRegistrationValue(_Path: Text; _Value: Text; var _RealtimeRegistration: Record "MOB Realtime Reg Qty."; var _IsHandled: Boolean)
    begin
        if _Path <> 'PackageNumber' then
            exit;

        Evaluate(_RealtimeRegistration.PackageNumber, _Value);
        _IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB Print", 'OnPrintLabel_OnPopulateDatasetOnCopyTrackingToDataset', '', true, true)]
    local procedure OnPrintLabel_OnPopulateDatasetOnCopyTrackingToDataset(_MobTrackingSetup: Record "MOB Tracking Setup"; _Prefix: Text; var _Dataset: Record "MOB Common Element")
    begin
        _Dataset.SetValue(_Prefix + 'PackageNumber', _MobTrackingSetup."Package No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB Print", 'OnPrintLabel_OnAfterPopulateDataset', '', true, true)]
    local procedure OnPrintLabel_OnAfterPopulateDataset(var _Dataset: Record "MOB Common Element")
    var
        ItemTrackingSetup: Record "Item Tracking Setup";
    begin
        _Dataset.SetValue('PackageNumber_Label', ItemTrackingSetup.FieldCaption("Package No."));
    end;

    //
    // ------- Tracking Specification subscribers -------
    // 

    [EventSubscriber(ObjectType::Table, Database::"MOB WMS Registration", 'OnAfterTrackingExists', '', false, false)]
    local procedure OnAfterTrackingExists(_MobWmsRegistration: Record "MOB WMS Registration"; var _IsTrackingExist: Boolean)
    begin
        _IsTrackingExist := _IsTrackingExist or (_MobWmsRegistration.PackageNumber <> '');
    end;

    [EventSubscriber(ObjectType::Table, Database::"MOB WMS Registration", 'OnAfterSetTrackingFilterFromMobWmsRegistration', '', false, false)]
    local procedure OnAfterSetTrackingFilterFromMobWmsRegistration(var _MobWmsRegistration: Record "MOB WMS Registration"; _FromMobWmsRegistration: Record "MOB WMS Registration")
    begin
        _MobWmsRegistration.SetRange(PackageNumber, _FromMobWmsRegistration.PackageNumber);
    end;

    [EventSubscriber(ObjectType::Table, Database::"MOB WMS Registration", 'OnAfterSetTrackingFilterFromEntrySummary', '', false, false)]
    local procedure OnAfterSetTrackingFilterFromEntrySummary(var _MobWmsRegistration: Record "MOB WMS Registration"; _FromEntrySummary: Record "Entry Summary")
    begin
        _MobWmsRegistration.SetRange(PackageNumber, _FromEntrySummary."Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"MOB Steps Element", 'OnAfterCreateStepsFromItemTrackingSetupIfRequired', '', false, false)]
    local procedure OnAfterCreateStepsFromItemTrackingSetupIfRequired(var _MobTrackingSetup: Record "MOB Tracking Setup"; var _NextId: Integer; _ItemNo: Code[20]; var _Steps: Record "MOB Steps Element")
    begin

        if _MobTrackingSetup."Package No. Required" then begin
            _Steps.Create_TextStep_PackageNumber(_NextId, _ItemNo);

            // Suggest existing value and make it optional so user can accept it as-is
            if _MobTrackingSetup."Package No." <> '' then begin
                _Steps.Set_defaultValue(_MobTrackingSetup."Package No.");
                _Steps.Set_validationValues(_MobTrackingSetup."Package No."); // Mirror default behavior in Mobile App for SerialNumber and LotNumber steps (pre-populated value cannot be changed, but validationWarningType is not supported on custom Text steps)
                _Steps.Set_validationCaseSensitive(false);
                _Steps.Set_optional(true);
            end;

            _NextId := _NextId + 10;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"MOB Tracking Setup", 'OnAfterCopyTrackingRequiredFromItemTrackingSetup', '', false, false)]
    local procedure OnAfterCopyTrackingRequiredFromItemTrackingSetup(var _MobTrackingSetup: Record "MOB Tracking Setup"; _ItemTrackingSetup: Record "Item Tracking Setup")
    begin
        _MobTrackingSetup."Package No. Required" := _ItemTrackingSetup."Package No. Required";
    end;

    [EventSubscriber(ObjectType::Table, Database::"MOB Tracking Setup", 'OnAfterCopyTrackingFromRequestValues', '', false, false)]
    local procedure OnAfterCopyTrackingFromRequestValues(var _MobTrackingSetup: Record "MOB Tracking Setup"; var _RequestValues: Record "MOB NS Request Element")
    begin
        _MobTrackingSetup."Package No." := _RequestValues.GetValue('PackageNumber', false);
    end;

    [EventSubscriber(ObjectType::Table, Database::"MOB Tracking Setup", 'OnAfterCopyTrackingFromRequestValuesIfRequired', '', false, false)]
    local procedure OnAfterCopyTrackingFromRequestValuesIfRequired(var _MobTrackingSetup: Record "MOB Tracking Setup"; var _RequestValues: Record "MOB NS Request Element"; _ErrorIfNotExists: Boolean)
    begin
        if _MobTrackingSetup."Package No. Required" then
            _MobTrackingSetup."Package No." := _RequestValues.GetValue('PackageNumber', _ErrorIfNotExists);
    end;

    [EventSubscriber(ObjectType::Table, Database::"MOB Tracking Setup", 'OnAfterCopyTrackingFromRequestContextValues', '', false, false)]
    local procedure OnAfterCopyTrackingFromRequestContextValues(var _MobTrackingSetup: Record "MOB Tracking Setup"; var _RequestValues: Record "MOB NS Request Element")
    begin
        _MobTrackingSetup."Package No." := _RequestValues.GetContextValue('PackageNumber', false);
    end;

    [EventSubscriber(ObjectType::Table, Database::"MOB Tracking Setup", 'OnAfterCopyTrackingFromRegistration', '', false, false)]
    local procedure OnAfterCopyTrackingFromRegistration(var _MobTrackingSetup: Record "MOB Tracking Setup"; _Registration: Record "MOB WMS Registration")
    begin
        _MobTrackingSetup."Package No." := _Registration.PackageNumber;
    end;

    [EventSubscriber(ObjectType::Table, Database::"MOB Tracking Setup", 'OnAfterCopyTrackingFromRegistrationIfRequired', '', false, false)]
    local procedure OnAfterCopyTrackingFromRegistrationIfRequired(var _MobTrackingSetup: Record "MOB Tracking Setup"; _Registration: Record "MOB WMS Registration")
    begin
        if _MobTrackingSetup."Package No. Required" then
            _MobTrackingSetup."Package No." := _Registration.PackageNumber;
    end;

    [EventSubscriber(ObjectType::Table, Database::"MOB Tracking Setup", 'OnAfterCopyTrackingFromTrackingByBinQueryIfRequired', '', false, false)]
    local procedure OnAfterCopyTrackingFromTrackingByBinQueryIfRequired(var _MobTrackingSetup: Record "MOB Tracking Setup"; _MobWmsTrackingByBinQuery: Query "MOB WMS Tracking By Bin")
    begin
        if _MobTrackingSetup."Package No. Required" then
            _MobTrackingSetup."Package No." := _MobWmsTrackingByBinQuery.Package_No;
    end;

    [EventSubscriber(ObjectType::Table, Database::"MOB Tracking Setup", 'OnAfterCopyTrackingToLookupResponse', '', false, false)]
    local procedure OnAfterCopyTrackingToLookupResponse(var _LookupResponse: Record "MOB NS WhseInquery Element"; _MobTrackingSetup: Record "MOB Tracking Setup")
    begin
        _LookupResponse.Set_PackageNumber(_MobTrackingSetup."Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"MOB Tracking Setup", 'OnAfterCopyTrackingToLookupResponseAsDisplayTracking', '', false, false)]
    local procedure OnAfterCopyTrackingToLookupResponseAsDisplayTracking(var _LookupResponse: Record "MOB NS WhseInquery Element"; _MobTrackingSetup: Record "MOB Tracking Setup")
    var
        ItemTrackingSetup: Record "Item Tracking Setup";
    begin
        _LookupResponse.Set_DisplayPackageNumber(_MobTrackingSetup."Package No." <> '', ItemTrackingSetup.FieldCaption("Package No.") + ': ' + _MobTrackingSetup."Package No.", '');
    end;

    [EventSubscriber(ObjectType::Table, Database::"MOB Tracking Setup", 'OnAfterCopyTrackingToBaseOrderLine', '', false, false)]
    local procedure OnAfterCopyTrackingToBaseOrderLine(var _BaseOrderLine: Record "MOB NS BaseDataModel Element"; _MobTrackingSetup: Record "MOB Tracking Setup")
    begin
        _BaseOrderLine.Set_PackageNumber(_MobTrackingSetup."Package No.");
    end;

    /// <summary>
    /// RegisterTracking is generally not used for unplanned functions but is used in the Production area for adhoc steps customization.
    /// </summary>
    [EventSubscriber(ObjectType::Table, Database::"MOB Tracking Setup", 'OnAfterCopyTrackingRequiredFromLookupResponse', '', false, false)]
    local procedure OnAfterCopyTrackingRequiredFromLookupResponse(var _MobTrackingSetup: Record "MOB Tracking Setup"; var _LookupResponse: Record "MOB NS WhseInquery Element"; _ErrorIfNotExists: Boolean)
    begin
        _MobTrackingSetup."Package No. Required" := _LookupResponse.GetValueAsBoolean('RegisterPackageNumber', _ErrorIfNotExists);
    end;

    [EventSubscriber(ObjectType::Table, Database::"MOB Tracking Setup", 'OnAfterCopyTrackingRequiredToBaseOrderLine', '', false, false)]
    local procedure OnAfterCopyTrackingRequiredToBaseOrderLine(var _BaseOrderLine: Record "MOB NS BaseDataModel Element"; _MobTrackingSetup: Record "MOB Tracking Setup")
    begin
        _BaseOrderLine.Set_RegisterPackageNumber(_MobTrackingSetup."Package No. Required");
    end;

    [EventSubscriber(ObjectType::Table, Database::"MOB Tracking Setup", 'OnAfterCopyTrackingRequiredToLookupResponse', '', false, false)]
    local procedure OnAfterCopyTrackingRequiredToLookupResponse(var _LookupResponse: Record "MOB NS WhseInquery Element"; _MobTrackingSetup: Record "MOB Tracking Setup")
    begin
        _LookupResponse.SetValue('RegisterPackageNumber', MobWmsToolbox.Bool2Text(_MobTrackingSetup."Package No. Required"));
    end;

    [EventSubscriber(ObjectType::Table, Database::"MOB Tracking Setup", 'OnAfterSetTrackingFilterForItem', '', false, false)]
    local procedure OnAfterSetTrackingFilterForItem(var _Item: Record Item; _MobTrackingSetup: Record "MOB Tracking Setup")
    begin
        _Item.SetRange("Package No. Filter", _MobTrackingSetup."Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"MOB Tracking Setup", 'OnAfterSetTrackingFilterForItemIfRequired', '', false, false)]
    local procedure OnAfterSetTrackingFilterForItemIfRequired(var _Item: Record Item; _MobTrackingSetup: Record "MOB Tracking Setup")
    begin
        if _MobTrackingSetup."Package No. Required" then
            _Item.SetRange("Package No. Filter", _MobTrackingSetup."Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"MOB Tracking Setup", 'OnAfterSetTrackingFilterNotEqualForItemLedgerEntryIfNotBlank', '', false, false)]
    local procedure OnAfterSetTrackingFilterNotEqualForItemLedgerEntryIfNotBlank(var _ItemLedgerEntry: Record "Item Ledger Entry"; _MobTrackingSetup: Record "MOB Tracking Setup")
    begin
        if _MobTrackingSetup."Package No." <> '' then
            _ItemLedgerEntry.SetFilter("Package No.", '<>%1', _MobTrackingSetup."Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"MOB Tracking Setup", 'OnAfterSetTrackingFilterForItemJnlLineIfNotBlank', '', false, false)]
    local procedure OnAfterSetTrackingFilterForItemJnlLineIfNotBlank(var _ItemJnlLine: Record "Item Journal Line"; _MobTrackingSetup: Record "MOB Tracking Setup")
    begin
        if _MobTrackingSetup."Package No." <> '' then
            _ItemJnlLine.SetRange("Package No.", _MobTrackingSetup."Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"MOB Tracking Setup", 'OnAfterSetTrackingFilterBlankForReservEntryIfNotBlank', '', false, false)]
    local procedure OnAfterSetTrackingFilterBlankForReservEntryIfNotBlank(var _ReservEntry: Record "Reservation Entry"; _MobTrackingSetup: Record "MOB Tracking Setup")
    begin
        if _MobTrackingSetup."Package No." <> '' then
            _ReservEntry.SetRange("Package No.", '');
    end;

    [EventSubscriber(ObjectType::Table, Database::"MOB Tracking Setup", 'OnAfterSetTrackingFilterForReservEntryIfRequired', '', false, false)]
    local procedure OnAfterSetTrackingFilterForReservEntryIfRequired(var _ReservEntry: Record "Reservation Entry"; _MobTrackingSetup: Record "MOB Tracking Setup")
    begin
        if _MobTrackingSetup."Package No. Required" then
            _ReservEntry.SetRange("Package No.", _MobTrackingSetup."Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"MOB Tracking Setup", 'OnAfterSetTrackingFilterForWhseJnlLineIfNotBlank', '', false, false)]
    local procedure OnAfterSetTrackingFilterForWhseJnlLineIfNotBlank(var _WhseJnlLine: Record "Warehouse Journal Line"; _MobTrackingSetup: Record "MOB Tracking Setup")
    begin
        if _MobTrackingSetup."Package No." <> '' then
            _WhseJnlLine.SetRange("Package No.", _MobTrackingSetup."Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"MOB Tracking Setup", 'OnAfterValidateTrackingToWhseActLine', '', false, false)]
    local procedure OnAfterValidateTrackingToWhseActLine(var _WhseActLine: Record "Warehouse Activity Line"; _MobTrackingSetup: Record "MOB Tracking Setup")
    begin
        _WhseActLine.Validate("Package No.", _MobTrackingSetup."Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"MOB Tracking Setup", 'OnAfterValidateTrackingToWhseActLineIfRequired', '', false, false)]
    local procedure OnAfterValidateTrackingToWhseActLineIfRequired(var _WhseActLine: Record "Warehouse Activity Line"; _MobTrackingSetup: Record "MOB Tracking Setup")
    begin
        if (_WhseActLine."Package No." <> _MobTrackingSetup."Package No.") then
            if _MobTrackingSetup."Package No. Required" then
                _WhseActLine.Validate("Package No.", _MobTrackingSetup."Package No.")
            else
                _WhseActLine."Package No." := _MobTrackingSetup."Package No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"MOB Tracking Setup", 'OnAfterValidateTrackingToWhseItemTrackingLine', '', false, false)]
    local procedure OnAfterValidateTrackingToWhseItemTrackingLine(var _WhseItemTrackingLine: Record "Whse. Item Tracking Line"; _MobTrackingSetup: Record "MOB Tracking Setup")
    begin
        _WhseItemTrackingLine.Validate("Package No.", _MobTrackingSetup."Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"MOB Tracking Setup", 'OnAfterValidateTrackingToWhseJnlLineIfRequired', '', false, false)]
    local procedure OnAfterValidateTrackingToWhseJnlLineIfRequired(var _WhseJnlLine: Record "Warehouse Journal Line"; _MobTrackingSetup: Record "MOB Tracking Setup")
    begin
        if _MobTrackingSetup."Package No. Required" then
            _WhseJnlLine.Validate("Package No.", _MobTrackingSetup."Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"MOB Tracking Setup", 'OnAfterCopyTrackingFromReservEntryIfNotBlank', '', false, false)]
    local procedure OnAfterCopyTrackingFromReservEntryIfNotBlank(var _MobTrackingSetup: Record "MOB Tracking Setup"; _ReservEntry: Record "Reservation Entry")
    begin
        if _ReservEntry."Package No." <> '' then
            _MobTrackingSetup."Package No." := _ReservEntry."Package No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"MOB Tracking Setup", 'OnAfterCheckTrackingOnInventoryIfNotBlank', '', false, false)]
    local procedure OnAfterCheckTrackingOnInventoryIfNotBlank(_ItemNo: Code[20]; _VariantCode: Code[10]; _MobTrackingSetup: Record "MOB Tracking Setup")
    begin
        if _MobTrackingSetup."Package No." <> '' then
            CheckPackageNoOnInventory(_ItemNo, _VariantCode, _MobTrackingSetup."Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"MOB Tracking Setup", 'OnAfterCheckTrackingOnInventoryIfRequired', '', false, false)]
    local procedure OnAfterCheckTrackingOnInventoryIfRequired(_ItemNo: Code[20]; _VariantCode: Code[10]; _MobTrackingSetup: Record "MOB Tracking Setup")
    begin
        if _MobTrackingSetup."Package No. Required" then
            CheckPackageNoOnInventory(_ItemNo, _VariantCode, _MobTrackingSetup."Package No.");
    end;

    local procedure CheckPackageNoOnInventory(_ItemNo: Code[20]; _VariantCode: Code[10]; _PackageNo: Code[50])
    var
        ItemTrackingSetup: Record "Item Tracking Setup";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        PackageExists: Boolean;
    begin
        PackageExists := InventoryExistsByPackage(_ItemNo, _VariantCode, _PackageNo);
        if not PackageExists then
            Error(MobWmsLanguage.GetMessage('XY_DOESNOTEXIST_Z'), ItemTrackingSetup.FieldCaption("Package No."), _PackageNo, MobWmsToolbox.GetItemAndVariantTxt(_ItemNo, _VariantCode));
    end;

    local procedure InventoryExistsByPackage(_ItemNo: Code[20]; _VariantCode: Code[20]; _PackageNumber: Code[50]): Boolean
    var
        MobTrackingSetup: Record "MOB Tracking Setup";
    begin
        Clear(MobTrackingSetup);
        MobTrackingSetup."Package No." := _PackageNumber;
        exit(MobWmsToolbox.InventoryExists(_ItemNo, _VariantCode, MobTrackingSetup));
    end;

    [EventSubscriber(ObjectType::Table, Database::"MOB Tracking Setup", 'OnFormatTrackingOnAfterGetTrackingList', '', false, false)]
    local procedure OnFormatTrackingOnAfterGetTrackingList(var _TrackingList: List of [Text]; _MobTrackingSetup: Record "MOB Tracking Setup"; _FormatExpr: Text)
    var
        ItemTrackingSetup: Record "Item Tracking Setup";
    begin
        if _MobTrackingSetup."Package No." <> '' then
            MobToolbox.AddUniqueText(_TrackingList, StrSubstNo(_FormatExpr, ItemTrackingSetup.FieldCaption("Package No.") + ': ' + _MobTrackingSetup."Package No."));
    end;

    [EventSubscriber(ObjectType::Table, Database::"MOB Tracking Setup", 'OnAfterDetermineItemTrackingRequired', '', false, false)]
    local procedure OnAfterDetermineItemTrackingRequired(_WhseActLine: Record "Warehouse Activity Line"; var _MobTrackingSetup: Record "MOB Tracking Setup"; var _RegisterExpirationDate: Boolean)
    var
        ItemTrackingCode: Record "Item Tracking Code";
        Item: Record Item;
    begin
        if Item.Get(_WhseActLine."Item No.") and ItemTrackingCode.Get(Item."Item Tracking Code") then
            case _WhseActLine."Activity Type" of
                _WhseActLine."Activity Type"::"Put-away":
                    _MobTrackingSetup."Package No. Required" := ItemTrackingCode."Package Warehouse Tracking";
                _WhseActLine."Activity Type"::"Invt. Put-away":
                    begin
                        if _WhseActLine."Source Document" = _WhseActLine."Source Document"::"Purchase Order" then
                            _MobTrackingSetup."Package No. Required" := ItemTrackingCode."Package Purchase Inb. Tracking";
                        if _WhseActLine."Source Document" = _WhseActLine."Source Document"::"Inbound Transfer" then
                            _MobTrackingSetup."Package No. Required" := ItemTrackingCode."Package Specific Tracking";
                        if _WhseActLine."Source Document" = _WhseActLine."Source Document"::"Sales Return Order" then
                            _MobTrackingSetup."Package No. Required" := ItemTrackingCode."Package Sales Inbound Tracking";
                        if _WhseActLine."Source Document" = _WhseActLine."Source Document"::"Prod. Output" then
                            _MobTrackingSetup."Package No. Required" := ItemTrackingCode."Package Manuf. Inb. Tracking";
                        if _WhseActLine."Source Document" = _WhseActLine."Source Document"::"Assembly Order" then
                            _MobTrackingSetup."Package No. Required" := ItemTrackingCode."Package Assembly Inb. Tracking";
                        if (_WhseActLine."Source Document" = _WhseActLine."Source Document"::" ") and (_WhseActLine."Source Type" = Database::"Whse. Internal Put-away Line") then
                            _MobTrackingSetup."Package No. Required" := ItemTrackingCode."Package Specific Tracking";
                    end;
                _WhseActLine."Activity Type"::Pick,
                _WhseActLine."Activity Type"::"Invt. Pick":
                    begin
                        if _WhseActLine."Source Document" in [_WhseActLine."Source Document"::"Sales Order", _WhseActLine."Source Document"::"Service Order"] then
                            _MobTrackingSetup."Package No. Required" := ItemTrackingCode."Package Sales Outb. Tracking";
                        if _WhseActLine."Source Document" = _WhseActLine."Source Document"::"Purchase Return Order" then
                            _MobTrackingSetup."Package No. Required" := ItemTrackingCode."Package Purch. Outb. Tracking";
                        if _WhseActLine."Source Document" = _WhseActLine."Source Document"::"Outbound Transfer" then
                            _MobTrackingSetup."Package No. Required" := ItemTrackingCode."Package Transfer Tracking";
                        if _WhseActLine."Source Document" = _WhseActLine."Source Document"::"Prod. Consumption" then
                            _MobTrackingSetup."Package No. Required" := ItemTrackingCode."Package Manuf. Outb. Tracking";
                        if _WhseActLine."Source Document" = _WhseActLine."Source Document"::"Assembly Consumption" then
                            _MobTrackingSetup."Package No. Required" := ItemTrackingCode."Package Assembly Out. Tracking";
                        if (_WhseActLine."Source Document" = _WhseActLine."Source Document"::" ") and (_WhseActLine."Source Type" = Database::"Whse. Internal Pick Line") then
                            _MobTrackingSetup."Package No. Required" := ItemTrackingCode."Package Specific Tracking";
                        if MobToolbox.AsInteger(_WhseActLine."Source Document") = 22 then // 22 = Job Usage
                            _MobTrackingSetup."Package No. Required" := ItemTrackingCode."Package Neg. Outb. Tracking";
                    end;
                _WhseActLine."Activity Type"::Movement,
                _WhseActLine."Activity Type"::"Invt. Movement":
                    _MobTrackingSetup."Package No. Required" := ItemTrackingCode."Package Warehouse Tracking";
            end; // CASE
    end;

    [EventSubscriber(ObjectType::Table, Database::"MOB Tracking Setup", 'OnAfterDetermineNegAdjustItemTrackingRequired', '', false, false)]
    local procedure OnAfterDetermineNegAdjustItemTrackingRequired(_ItemTrackingSetupInbound: Record "Item Tracking Setup"; _ItemTrackingSetupOutbound: Record "Item Tracking Setup"; var _MobTrackingSetup: Record "MOB Tracking Setup"; var _RegisterExpirationDate: Boolean)
    begin
        _MobTrackingSetup."Package No. Required" := _ItemTrackingSetupInbound."Package No. Required" or _ItemTrackingSetupOutbound."Package No. Required";
    end;

    //
    // ------- Tracking Specification subscribers in other tables than "MOB Tracking Setup" -------
    //

    [EventSubscriber(ObjectType::Table, Database::"Bin Content", 'MobOnAfterSetTrackingFilterFromEntrySummaryIfNotBlank', '', false, false)]
    local procedure BinContent_MobOnAfterSetTrackingFilterFromEntrySummaryIfNotBlank_BinContent(var _BinContent: Record "Bin Content"; _FromEntrySummary: Record "Entry Summary")
    begin
        if _FromEntrySummary."Package No." <> '' then
            _BinContent.SetRange("Package No. Filter", _FromEntrySummary."Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Bin Content", 'MobOnAfterSetTrackingFilterFromMobWmsRegistrationIfNotBlank', '', false, false)]
    local procedure BinContent_MobOnAfterSetTrackingFilterFromMobWmsRegistrationIfNotBlank(var _BinContent: Record "Bin Content"; _FromMobWmsRegistration: Record "MOB WMS Registration")
    begin
        if _FromMobWmsRegistration.PackageNumber <> '' then
            _BinContent.SetRange("Package No. Filter", _FromMobWmsRegistration.PackageNumber);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Ledger Entry", 'MobOnAfterSetTrackingFilterFromEntrySummaryIfNotBlank', '', false, false)]
    local procedure ItemLedgEntry_MobOnAfterSetTrackingFilterFromEntrySummaryIfNotBlank(var _ItemLedgerEntry: Record "Item Ledger Entry"; _FromEntrySummary: Record "Entry Summary")
    begin
        if _FromEntrySummary."Package No." <> '' then
            _ItemLedgerEntry.SetRange("Package No.", _FromEntrySummary."Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Ledger Entry", 'MobOnAfterSetTrackingFilterFromMobWmsRegistrationIfNotBlank', '', false, false)]
    local procedure ItemLedgEntry_MobOnAfterSetTrackingFilterFromMobWmsRegistrationIfNotBlank(var _ItemLedgerEntry: Record "Item Ledger Entry"; _FromMobWmsRegistration: Record "MOB WMS Registration")
    begin
        if _FromMobWmsRegistration.PackageNumber <> '' then
            _ItemLedgerEntry.SetRange("Package No.", _FromMobWmsRegistration.PackageNumber);
    end;

    //
    // ------- Events implemented to avoid refactoring during Mob Tracking Setup implementation (likely to be refactored later) -------
    // 

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB Reservation Mgt.", 'OnAfterCheckWhseTrackingEnabledIfSpecificTrackingRequired', '', false, false)]
    local procedure OnAfterCheckWhseTrackingEnabledIfSpecificTrackingRequired(_ItemTrackingCode: Record "Item Tracking Code"; _ItemNo: Code[20])
    var
        MobWmsLanguage: Codeunit "MOB WMS Language";
    begin
        if _ItemTrackingCode."Package Specific Tracking" then
            if not _ItemTrackingCode."Package Warehouse Tracking" then
                Error(MobWmsLanguage.GetMessage('WHSE_TRKG_NEEDED'), _ItemNo);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Adhoc Registr.", 'OnPostAdhocRegistrationOnToteShipping_OnAddStepsIfToteContainsAtoLines', '', false, false)]
    local procedure OnPostAdhocRegistrationOnToteShipping_OnAddStepsIfToteContainsAtoLines(_WhseShptLine: Record "Warehouse Shipment Line"; _MobTrackingSetup: Record "MOB Tracking Setup"; var _NextStepNo: Integer; var _Steps: Record "MOB Steps Element")
    begin
        if _MobTrackingSetup."Package No. Required" then begin
            _Steps.Create_TextStep_PackageNumber(_NextStepNo, _WhseShptLine."Item No.", false);
            _Steps.Set_name('PackageNumber' + _WhseShptLine."No." + '_' + Format(_WhseShptLine."Line No."));
            _Steps.Save();
            _NextStepNo += 10;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Ship", 'OnReservEntriesExistOnCheckValidOutboundTracking', '', false, false)]
    local procedure OnReservEntriesExistOnCheckValidOutboundTracking(_ItemTrackingCode: Record "Item Tracking Code"; _MobTrackingSetup: Record "MOB Tracking Setup"; _ReservEntry: Record "Reservation Entry"; var _ValidOutboundTracking: Boolean)
    var
        ValidOutboundPackageNo: Boolean;
    begin
        ValidOutboundPackageNo := (not _ItemTrackingCode."Package Specific Tracking") or (_MobTrackingSetup."Package No." = _ReservEntry."Package No.");
        _ValidOutboundTracking := _ValidOutboundTracking and ValidOutboundPackageNo;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Ship", 'OnGetAvailableItemsTxtOnAddTrackingIfNotBlank', '', false, false)]
    local procedure OnGetAvailableItemsTxtOnAddTrackingIfNotBlank(_MobTrackingSetup: Record "MOB Tracking Setup"; _Quantity: Decimal; _UoMCode: Code[10]; var _AvailableItemsTxt: Text)
    begin
        if _MobTrackingSetup."Package No." <> '' then
            _AvailableItemsTxt += ' ' + _MobTrackingSetup.FieldCaption("Package No.") + ' ' + _MobTrackingSetup."Package No." + ' (' + Format(_Quantity) + ' ' + _UoMCode + ')';
    end;
    /* #endif */

    // ************************************************************************************************************************************************************************************
    // Functions above are all active for BC18+
    // ************************************************************************************************************************************************************************************
    // Functions below differs per version
    // ************************************************************************************************************************************************************************************

    /* #if BC24+ */
    [EventSubscriber(ObjectType::Table, Database::"MOB Tracking Setup", 'OnAfterCopyTrackingFromPhysInvtRecordLine', '', false, false)]
    local procedure OnAfterCopyTrackingFromPhysInvtRecordLine(var _MobTrackingSetup: Record "MOB Tracking Setup"; _PhysInvtRecordLine: Record "Phys. Invt. Record Line")
    begin
        _MobTrackingSetup."Package No." := _PhysInvtRecordLine."Package No.";
    end;
    /* #endif */

    /* #if BC24+ */
    internal procedure IsFeaturePackageMgtEnabled() FeatureEnabled: Boolean
    begin
        exit(true); // The Package No. feature is always enabled for BC24+
    end;
    /* #endif */

    /* #if BC18,BC19,BC20,BC21,BC22,BC23 ##
    internal procedure IsFeaturePackageMgtEnabled() FeatureEnabled: Boolean
    var
        PackageMgt: Codeunit "Package Management";
    begin
        FeatureEnabled := PackageMgt.IsEnabled();
    end;
    /* #endif */

    /* #if BC24+ */
    procedure FeaturePhysInvtOrderPackageTrackingEnabled() Enabled: Boolean
    var
        FeatureMgtFacade: Codeunit "Feature Management Facade";
    begin
        Enabled := FeatureMgtFacade.IsEnabled('PhysInvtOrderPackageTracking');
    end;
    /* #endif */

    /* #if BC18,BC19,BC20,BC21,BC22,BC23 ##
    procedure FeaturePhysInvtOrderPackageTrackingEnabled() Enabled: Boolean
    begin
        exit(false); // The Package No. feature is never available for BC18..BC23 for physical inventory orders
    end;
    /* #endif */
}
