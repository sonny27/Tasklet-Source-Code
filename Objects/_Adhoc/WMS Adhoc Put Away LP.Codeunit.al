codeunit 81345 "MOB WMS Adhoc Put Away LP"
{
    Access = Public;
    var
        RelatedPutAwayNotFoundErr: Label 'No Related Put-away exists for LP: %1.', Comment = '%1 is License Plate No.';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Reference Data", 'OnGetReferenceData_OnAddHeaderConfigurations', '', true, true)]
    local procedure OnGetReferenceData_OnAddHeaderConfigurations(var _HeaderFields: Record "MOB HeaderField Element")
    var
        MobSetup: Record "MOB Setup";
    begin
        if not MobSetup.LicensePlatingIsEnabled() then
            exit;

        // Add Header for Put Away License Plate
        _HeaderFields.InitConfigurationKey_RegisterPutAwayLicensePlateHeader();
        _HeaderFields.Create_TextField_LicensePlate(10);
    end;

    internal procedure CreateSteps(var _HeaderFilter: Record "MOB NS Request Element"; var _Steps: Record "MOB Steps Element") _ReturnRegistrationTypeTracking: Text
    var
        MobLicensePlate: Record "MOB License Plate";
    begin
        MobLicensePlate.Get(_HeaderFilter.Get_LicensePlate());

        // Check if the License Plate is related to a Put-away Document and throw an error if not
        if MobLicensePlate.GetRelatedPutAwayNo() = '' then
            Error(RelatedPutAwayNotFoundErr, MobLicensePlate."No.");

        CreateStepsForRegisterPutAwayLicensePlate(_Steps, MobLicensePlate)
    end;

    internal procedure CreateStepsForRegisterPutAwayLicensePlate(var _Steps: Record "MOB Steps Element"; var _MobLicensePlate: Record "MOB License Plate")
    var
        MobWmsAdhocUnplMoveAdv: Codeunit "MOB WMS Adhoc Unpl. Move Adv.";
    begin
        _Steps.Create_TextStep_ToBin(10);
        _Steps.Set_helpLabel(MobWmsAdhocUnplMoveAdv.GetDefaultOrSuggestedBinAsHtml(_MobLicensePlate, true, _MobLicensePlate."Location Code"));
        _Steps.Save();
    end;

    internal procedure PostRegistration(var _RequestValues: Record "MOB NS Request Element"; var _SuccessMessage: Text; var _ReturnRegistrationTypeTracking: Text)
    var
        MobLicensePlate: Record "MOB License Plate";
        MobFeatureTelemetryWrapper: Codeunit "MOB Feature Telemetry Wrapper";
        MobTelemetryEventId: Enum "MOB Telemetry Event ID";
    begin
        MobLicensePlate.Get(_RequestValues.Get_LicensePlate());

        // Determine if the License Plate is related to a Warehouse Receipt with a Unposted Put-away Document
        if MobLicensePlate.GetRelatedPutAwayNo() <> '' then begin
            PostRelatedPutAway(_RequestValues, MobLicensePlate, _SuccessMessage, _ReturnRegistrationTypeTracking);

            // Logging uptake telemetry for used LP feature
            MobFeatureTelemetryWrapper.LogUptakeUsed(MobTelemetryEventId::"License Plating - Put-away LP (MOB1070)");
        end;
    end;

    internal procedure PostRelatedPutAway(var _RequestValues: Record "MOB NS Request Element"; var _MobLicensePlate: Record "MOB License Plate"; var _SuccessMessage: Text; var _ReturnRegistrationTypeTracking: Text)
    var
        MobWmsPostLpPutAway: Codeunit "MOB WMS Post LP Put-away";
    begin
        MobWmsPostLpPutAway.PostPutAwayFromLicensePlate(_MobLicensePlate, _RequestValues.Get_ToBin(), _SuccessMessage);

        // Set the tracking value displayed in the document queue
        _ReturnRegistrationTypeTracking :=
            _MobLicensePlate.TableCaption() + ': ' +
            _MobLicensePlate."No." + ' -> ' +
            _MobLicensePlate.FieldCaption("Bin Code") + ': ' +
            _MobLicensePlate."Bin Code";
    end;
}
