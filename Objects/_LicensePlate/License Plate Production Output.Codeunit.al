codeunit 82232 "MOB License Plate Prod Output"
{
    Access = Public;

    var
        MobWmsLanguage: Codeunit "MOB WMS Language";
        ScanLPLbl: Label 'Scan or enter a License Plate No. to add the output to a License Plate.';

    internal procedure CreateStepsForProdOutputLicensePlate(var _ProdOrderRoutingLine: Record "Prod. Order Routing Line"; _LookupResponse: Record "MOB NS WhseInquery Element"; var _Steps: Record "MOB Steps Element")
    var
        Location: Record Location;
        MobSetup: Record "MOB Setup";
        MobWmsAdhocRegistr: Codeunit "MOB WMS Adhoc Registr.";
        MobLPHandling: Enum "MOB License Plate Handling";
        IsLastOperation: Boolean;
        IsHandled: Boolean;
    begin
        if not MobSetup.LicensePlatingIsEnabled() then
            exit;

        IsLastOperation := _ProdOrderRoutingLine."Next Operation No." = '';
        if not IsLastOperation then
            exit;

        Location.Get(_LookupResponse.Get_Location());

        // Check if location requires License Plate during production output
        if Location."MOB Prod. Output to LP" = Location."MOB Prod. Output to LP"::Disabled then
            exit;

        // Block for use of Put-away for Production output if License Plating is enabled.
        /* #if BC26+ */
        Location.TestField("Prod. Output Whse. Handling", Location."Prod. Output Whse. Handling"::"No Warehouse Handling");
        /* #endif */

        // License Plate step is created only if it is Bin Mandatory and the last Operation
        if not MobWmsAdhocRegistr.TestBinMandatory(Location.Code) then
            exit;

        OnBeforeCheckLicensePlateHandlingInProdOutput(_ProdOrderRoutingLine, _LookupResponse, _Steps, Location, IsHandled);
        if IsHandled then
            exit;

        _Steps.Create_TextStep_LicensePlate(300, false);
        _Steps.Set_optional(Location."MOB Prod. Output to LP" = MobLPHandling::Optional);
        _Steps.Set_helpLabel(ScanLPLbl);
        _Steps.Save();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Adhoc Registr.", 'OnPostAdhocRegistration_OnAddSteps', '', false, false)]
    local procedure ProdOutput_CreateNewLP_OnPostAdhocRegistration_OnAddSteps(_RegistrationType: Text; var _RequestValues: Record "MOB NS Request Element"; var _Steps: Record "MOB Steps Element"; var _RegistrationTypeTracking: Text)
    var
        MobLicensePlate: Record "MOB License Plate";
        ProdOutputLine: Record "Prod. Order Line";
        Location: Record Location;
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
        LicensePlate: Code[20];
        BinForNewLP: Code[20];
        OrderNo: Code[20];
        LineNo: Integer;
    begin
        if not (_RegistrationType in [MobWmsToolbox."CONST::ProdOutputQuantity"(), MobWmsToolbox."CONST::ProdOutput"()]) then
            exit;

        Location.Get(_RequestValues.GetValueOrContextValue('Location', true));
        if Location."MOB Prod. Output to LP" = Location."MOB Prod. Output to LP"::Disabled then
            exit;

        LicensePlate := _RequestValues.Get_LicensePlate();
        BinForNewLP := _RequestValues.GetValueOrContextValue('ToBin');

        if LicensePlate = '' then
            exit;

        // Exit if the License Plate already exists 
        if MobLicensePlate.Get(LicensePlate) then
            exit;

        if _RequestValues.Get_Quantity() = 0 then
            exit;

        // If the scanned value is not recognized as a License Plate, then ask the user if a new License Plate should be created
        CreateConfirmDialogForNewLP(LicensePlate, _RequestValues);

        MobWmsToolbox.GetOrderNoAndOrderLineNoFromBackendId(_RequestValues.Get_BackendID(), OrderNo, LineNo);
        if ProdOutputLine.Get(ProdOutputLine.Status::Released, OrderNo, LineNo) then begin
            MobLicensePlate.InitLicensePlate(LicensePlate, Location.Code, BinForNewLP, MobLicensePlate."Whse. Document Type"::" ", '');
            MobLicensePlate.Insert(true);
        end;
    end;

    internal procedure CheckAndRegisterOutputToLicensePlate(_ProdOrderLine: Record "Prod. Order Line"; _IsLastOperation: Boolean; _PostingOutputQty: Boolean; var _RequestValues: Record "MOB NS Request Element"; var _ReturnRegistrationTypeTracking: Text)
    var
        Location: Record Location;
        MobLicensePlate: Record "MOB License Plate";
    begin
        if not (_IsLastOperation or _PostingOutputQty) then
            exit;

        Location.Get(_ProdOrderLine."Location Code");

        // Only process if License Plate handling is Optional or Required
        if Location."MOB Prod. Output to LP" = Location."MOB Prod. Output to LP"::Disabled then
            exit;

        if not MobLicensePlate.Get(_RequestValues.Get_LicensePlate()) then
            exit;

        MobLicensePlate.TestField("Location Code", _ProdOrderLine."Location Code");
        MobLicensePlate.TestField("Bin Code", _RequestValues.GetValueOrContextValue('ToBin'));
        MobLicensePlate.TestField("Whse. Document Type", MobLicensePlate."Whse. Document Type"::" ");

        UpdateLicensePlateContentFromProdOutPut(MobLicensePlate, _RequestValues, _ReturnRegistrationTypeTracking);
    end;

    internal procedure UpdateLicensePlateContentFromProdOutPut(var _MobLicensePlate: Record "MOB License Plate"; var _RequestValues: Record "MOB NS Request Element"; var _ReturnRegistrationTypeTracking: Text)
    var
        ProdOrderLine: Record "Prod. Order Line";
        MobUnplannedMoveAdv: Codeunit "MOB WMS Adhoc Unpl. Move Adv.";
        MobFeatureTelemetryWrapper: Codeunit "MOB Feature Telemetry Wrapper";
        MobTelemetryEventId: Enum "MOB Telemetry Event ID";
        ItemNumber: Code[50];
        Quantity: Decimal;
    begin
        ItemNumber := _RequestValues.GetValueOrContextValue('ItemNumber');
        Quantity := _RequestValues.Get_Quantity();

        // Get the License Plate and add the content
        MobUnplannedMoveAdv.CreateLicensePlateContent(_RequestValues, _MobLicensePlate);

        // Logging uptake telemetry for used LP feature
        MobFeatureTelemetryWrapper.LogUptakeUsed(MobTelemetryEventId::"License Plating - Prod. Output to LP (MOB1085)");
        MobFeatureTelemetryWrapper.LogUptakeUsed(MobTelemetryEventId::"License Plating (MOB1050)");

        // Set the tracking value displayed in the document queue
        _ReturnRegistrationTypeTracking += ' ' + _MobLicensePlate.TableCaption() + ' ' +
            _MobLicensePlate."No." + ' ' +
            ProdOrderLine.FieldCaption("Item No.") + ' ' +
            ItemNumber + ' ' +
            ProdOrderLine.FieldCaption(Quantity) + ' ' +
            Format(Quantity);
    end;

    local procedure CreateConfirmDialogForNewLP(_LicensePlateNo: Code[20]; var _RequestValues: Record "MOB NS Request Element")
    var
        MobToolbox: Codeunit "MOB Toolbox";
        ConfirmTxtBuilder: TextBuilder;
    begin
        // Confirmation Dialog on Mobile Device does not support linebreak using \\, so the text is built as html here
        ConfirmTxtBuilder.Append('<html><body>');
        ConfirmTxtBuilder.Append(StrSubstNo(MobWmsLanguage.GetMessage('LP_NOT_FOUND_ERROR'), _LicensePlateNo));
        ConfirmTxtBuilder.Append('<p>');
        ConfirmTxtBuilder.Append(MobWmsLanguage.GetMessage('CREATE_NEW_LP_CONFIRM'));
        ConfirmTxtBuilder.Append('</body></html>');
        MobToolbox.ErrorIfNotConfirm(_RequestValues, ConfirmTxtBuilder.ToText());
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckLicensePlateHandlingInProdOutput(_ProdOrderRoutingLine: Record "Prod. Order Routing Line"; _LookupResponse: Record "MOB NS WhseInquery Element"; _Steps: Record "MOB Steps Element"; Location: Record Location; var IsHandled: Boolean)
    begin
    end;
}
