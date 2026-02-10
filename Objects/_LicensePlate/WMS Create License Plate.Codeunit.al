codeunit 82228 "MOB WMS CreateLicensePlate"
{
    //
    // -------------------------------- Create License plate from "License Plate Lookup"  --------------------------------
    //

    Access = Public;
    var
        MobLicensePlateMgt: Codeunit "MOB License Plate Mgt";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        NewLPInvalidBinAndLocationErr: Label 'To create a new License Plate you must specify a valid Location and Bin in the header.';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Reference Data", 'OnGetReferenceData_OnAddHeaderConfigurations', '', true, true)]
    local procedure OnGetReferenceData_OnAddHeaderConfigurations(var _HeaderFields: Record "MOB HeaderField Element")
    var
        MobSetup: Record "MOB Setup";
    begin
        if not MobSetup.LicensePlatingIsEnabled() then
            exit;

        // Add Header for Create License Plate
        _HeaderFields.InitConfigurationKey_CreateLicensePlateHeader();
        _HeaderFields.Create_ListField_Location(10);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Adhoc Registr.", 'OnPostAdhocRegistration_OnAddSteps', '', true, true)]
    local procedure OnPostAdhocRegistration_OnAddSteps_CreateLicensePlate(_RegistrationType: Text; var _RequestValues: Record "MOB NS Request Element"; var _Steps: Record "MOB Steps Element"; var _RegistrationTypeTracking: Text)
    var
        Bin: Record Bin;
        MobSetup: Record "MOB Setup";
    begin
        if _RegistrationType <> 'CreateLicensePlate' then
            exit;

        // LP Step
        if not _RequestValues.HasValue('NewLicensePlateNo') then begin
            MobSetup.Get();
            if MobSetup."LP Number Series" = '' then // If No.Series is used = Do not collect
                MobLicensePlateMgt.Create_TextStep_NewLicensePlateNo(10, _Steps);
        end;

        // Bin Step
        if not _RequestValues.HasValue('Bin') then begin

            // Check Bin value from header
            if not Bin.Get(_RequestValues.GetValueOrContextValue('Location'), _RequestValues.GetContextValue('FromBinOrLP')) then
                Error('%1\\%2', StrSubstNo(MobWmsLanguage.GetMessage('BIN_EXIST_ERR'), _RequestValues.GetContextValue('FromBinOrLP'), _RequestValues.GetValueOrContextValue('Location')), NewLPInvalidBinAndLocationErr);

            // Transfer "FromBinOrLP" as "Bin" into posting
            _Steps.Create_TextStep_Bin(20, _RequestValues.Get_Location(), '', ''); // Suggest Bin code from header
            _Steps.Set_primaryInputMethod('Control'); // Suggested value can be accepted as-is
            _Steps.Set_defaultValue(Bin.Code);
            _Steps.Set_visible(false);
        end;

    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Adhoc Registr.", 'OnPostAdhocRegistrationOnCustomRegistrationType', '', true, true)]
    local procedure OnPostAdhocRegistrationOnCustomRegistrationType_CreateLicensePlate(_RegistrationType: Text; var _RequestValues: Record "MOB NS Request Element"; var _SuccessMessage: Text; var _IsHandled: Boolean)
    var
        MobFeatureTelemetryWrapper: Codeunit "MOB Feature Telemetry Wrapper";
        MobTelemetryEventId: Enum "MOB Telemetry Event ID";
    begin
        if _IsHandled then
            exit;

        if _RegistrationType = 'CreateLicensePlate' then begin
            _SuccessMessage := CreateLicensePlate(_RegistrationType, _RequestValues);
            _IsHandled := true;

            // Logging uptake telemetry for used LP feature
            MobFeatureTelemetryWrapper.LogUptakeUsed(MobTelemetryEventId::"License Plating - LP Created manually (MOB1090)");
        end;
    end;

    internal procedure CreateLicensePlate(_RegistrationType: Text; var _RequestValues: Record "MOB NS Request Element"): Text
    var
        MobLicensePlate: Record "MOB License Plate";
    begin
        MobLicensePlate.InitLicensePlate(_RequestValues.GetValue('NewLicensePlateNo'), _RequestValues.GetValueOrContextValue('Location', true), _RequestValues.Get_Bin(true), MobLicensePlate."Whse. Document Type"::" ", '');
        MobLicensePlate.Insert(true);
    end;
}
