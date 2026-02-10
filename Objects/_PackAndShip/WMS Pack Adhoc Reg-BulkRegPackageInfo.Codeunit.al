codeunit 82242 "MOB WMS Pack Adhoc Reg-BulkReg"
{
    Access = Public;
    //
    // 'BulkRegPackageInfo' (incl. eventsubscribers incl. eventpublishers)
    //

    EventSubscriberInstance = Manual;

    var
        MobPackFeatureMgt: Codeunit "MOB Pack Feature Management";

    //
    // GetReferenceData
    //
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Reference Data", 'OnGetReferenceData_OnAddHeaderConfigurations', '', true, true)]
    local procedure OnGetReferenceData_OnAddHeaderConfigurations(var _HeaderFields: Record "MOB HeaderField Element")
    begin
        if not MobPackFeatureMgt.IsEnabled() then
            exit;

        // Add Header for Batch Add License Plate Info        
        _HeaderFields.InitConfigurationKey_BulkRegPackageInfoHeader();
        _HeaderFields.Create_TextField_ShipmentNo(10);
    end;

    //
    // GetRegistrationConfiguration
    //
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Adhoc Registr.", 'OnGetRegistrationConfiguration_OnAddSteps', '', true, true)]
    local procedure BulkRegPackageInfo_OnAddSteps(_RegistrationType: Text; var _HeaderFieldValues: Record "MOB NS Request Element"; var _Steps: Record "MOB Steps Element"; var _RegistrationTypeTracking: Text)
    var
        WhseShipmentHeader: Record "Warehouse Shipment Header";
        MobPackManagement: Codeunit "MOB Pack Management";
        BackendId: Code[20];
    begin
        if _RegistrationType <> 'BulkRegPackageInfo' then
            exit;

        BackendId := _HeaderFieldValues.Get_BackendID();
        WhseShipmentHeader.Get(BackendId);

        WhseShipmentHeader.TestField("Shipping Agent Code");
        MobPackManagement.AddPackageInfoSteps(_Steps, WhseShipmentHeader."Shipping Agent Code", WhseShipmentHeader."Shipping Agent Service Code", '');
    end;

    //
    // PostAdhocRegistration
    //

    /// <summary>
    /// Handle Add Extra Steps to Packages
    /// </summary>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Adhoc Registr.", 'OnPostAdhocRegistration_OnAddSteps', '', true, true)]
    local procedure OnPostAdhocRegistration_OnAddStepsToPackage(_RegistrationType: Text; var _RequestValues: Record "MOB NS Request Element"; var _Steps: Record "MOB Steps Element"; var _RegistrationTypeTracking: Text)
    var
        MobPackManagement: Codeunit "MOB Pack Management";
    begin
        if _RegistrationType <> 'BulkRegPackageInfo' then
            exit;

        // Break if our step is already collected to prevent infinite loop
        if _RequestValues.HasValue('ExtraSteps') then
            exit;

        MobPackManagement.AddPackageInfoLastSteps(_Steps, _RequestValues);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Adhoc Registr.", 'OnPostAdhocRegistrationOnCustomRegistrationType', '', true, true)]
    local procedure OnPostAdhocRegistrationOnCustomRegistrationTypeBulkRegPackageInfo(_RegistrationType: Text; var _RequestValues: Record "MOB NS Request Element"; var _CurrentRegistrations: Record "MOB WMS Registration"; var _SuccessMessage: Text; var _RegistrationTypeTracking: Text; var _IsHandled: Boolean)
    var
        MobLicensePlate: Record "MOB License Plate";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        PackageType: Code[20];
        Weight: Decimal;
        Height: Decimal;
        Width: Decimal;
        Length: Decimal;
        LoadMeter: Decimal;
    begin
        if _RegistrationType <> 'BulkRegPackageInfo' then
            exit;

        if _IsHandled then
            exit;

        PackageType := _RequestValues.GetValue('PackageType');
        Weight := _RequestValues.GetValueAsDecimal('Weight');
        Height := _RequestValues.GetValueAsDecimal('Height');
        Width := _RequestValues.GetValueAsDecimal('Width');
        Length := _RequestValues.GetValueAsDecimal('Length');
        LoadMeter := _RequestValues.GetValueAsDecimal('LoadMeter');

        MobLicensePlate.SetRange("Whse. Document Type", MobLicensePlate."Whse. Document Type"::Shipment);
        MobLicensePlate.SetRange("Whse. Document No.", _RequestValues.Get_BackendID());
        MobLicensePlate.SetRange("Content Exists", true);
        MobLicensePlate.SetFilter("Package Type", '%1', '');

        _RegistrationTypeTracking := 'BulkRegPackageInfo';

        if MobLicensePlate.IsEmpty() then
            Error(MobWmsLanguage.GetMessage('NO_LICENSE_PLATES_TO_UPDATE'));

        if MobLicensePlate.FindSet(true) then
            repeat
                if PackageType <> '' then
                    MobLicensePlate.Validate("Package Type", PackageType);

                if Weight <> 0 then
                    MobLicensePlate.Validate(Weight, Weight);

                if Height <> 0 then
                    MobLicensePlate.Validate(Height, Height);

                if Width <> 0 then
                    MobLicensePlate.Validate(Width, Width);

                if Length <> 0 then
                    MobLicensePlate.Validate(Length, Length);

                if LoadMeter <> 0 then
                    MobLicensePlate.Validate("Loading Meter", LoadMeter);

                OnPostAdhocRegistrationOnBulkRegPackageInfo_OnAfterUpdateLicensePlate(MobLicensePlate, _RequestValues);

                MobLicensePlate.Modify(true);
            until MobLicensePlate.Next() = 0;

        _IsHandled := true;
    end;

    //
    // IntegrationEvents
    //
    [IntegrationEvent(false, false)]
    local procedure OnPostAdhocRegistrationOnBulkRegPackageInfo_OnAfterUpdateLicensePlate(var _LicensePlate: Record "MOB License Plate"; var _RequestValues: Record "MOB NS Request Element")
    begin
    end;
}
