codeunit 82240 "MOB WMS Pack Adhoc Reg"
{
    Access = Public;
    //
    // Post 'PackagesToShipLookup' (legacy eventpublishers)
    // Post 'BulkRegPackageInfo' (legacy eventpublishers)
    // 

    EventSubscriberInstance = Manual;

    // TODO [Obsolete('Use "MOB WMS Pack Lookup".UpdateLicensePlateFromSteps instead  (planned for removal 04/2024)', 'MOB5.41')]
    procedure UpdateLicensePlateFromSteps(_RegistrationType: Text; var _RequestValues: Record "MOB NS Request Element"): Text
    var
        MobWmsPackLookup: Codeunit "MOB WMS Pack Lookup";
    begin
        exit(MobWmsPackLookup.UpdateLicensePlateFromSteps(_RegistrationType, _RequestValues));
    end;

    //
    // Obsolete IntegrationEvents
    //

    // TODO [Obsolete('Use "MOB WMS Pack Adhoc Reg-BulkReg".OnPostAdhocRegistrationOnBulkRegPackageInfo_OnAfterUpdateLicensePlate instead  (planned for removal 04/2024)', 'MOB5.41')]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Pack Adhoc Reg-BulkReg", 'OnPostAdhocRegistrationOnBulkRegPackageInfo_OnAfterUpdateLicensePlate', '', true, true)]
    [IntegrationEvent(false, false)]
    local procedure OnPostAdhocRegistrationOnBulkRegPackageInfo_OnAfterUpdateLicensePlate(var _LicensePlate: Record "MOB License Plate"; var _RequestValues: Record "MOB NS Request Element")
    begin
    end;

    // TODO [Obsolete('Use "MOB WMS Pack Lookup".OnPostAdhocRegistrationOnPackagesToShip_OnAfterUpdateLicensePlate instead  (planned for removal 04/2024)', 'MOB5.41')]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Pack Lookup", 'OnPostAdhocRegistrationOnPackagesToShip_OnAfterUpdateLicensePlate', '', true, true)]
    [IntegrationEvent(false, false)]
    local procedure OnPostAdhocRegistrationOnPackagesToShip_OnAfterUpdateLicensePlate(var _LicensePlate: Record "MOB License Plate"; var _RequestValues: Record "MOB NS Request Element")
    begin
    end;

    // TODO [Obsolete('Use "MOB WMS Pack Lookup".OnPostAdhocRegistrationOnPackagesToShip_OnUpdateLicensePlateFromPackageSetup instead  (planned for removal 04/2024)', 'MOB5.41')]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Pack Lookup", 'OnPostAdhocRegistrationOnPackagesToShip_OnUpdateLicensePlateFromPackageSetup', '', true, true)]
    [IntegrationEvent(false, false)]
    local procedure OnPostAdhocRegistrationOnPackagesToShip_OnUpdateLicensePlateFromPackageSetup(var _LicensePlate: Record "MOB License Plate"; _PackageSetup: Record "MOB Mobile WMS Package Setup")
    begin
    end;

    // TODO [Obsolete('Use "MOB WMS Pack Lookup".OnPostAdhocRegistrationOnPackagesToShip_OnAddStepsToLicensePlate instead  (planned for removal 04/2024)', 'MOB5.41')]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Pack Lookup", 'OnPostAdhocRegistrationOnPackagesToShip_OnAddStepsToLicensePlate', '', true, true)]
    [IntegrationEvent(false, false)]
    local procedure OnPostAdhocRegistrationOnPackagesToShip_OnAddStepsToLicensePlate(var _RequestValues: Record "MOB NS Request Element"; var _Steps: Record "MOB Steps Element")
    begin
    end;

    // TODO [Obsolete('Use "MOB WMS Pack Lookup".OnPostAdhocRegistrationOnPackagesToShip_OnAfterAddStepToLicensePlate instead  (planned for removal 04/2024)', 'MOB5.41')]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Pack Lookup", 'OnPostAdhocRegistrationOnPackagesToShip_OnAfterAddStepToLicensePlate', '', true, true)]
    [IntegrationEvent(false, false)]
    local procedure OnPostAdhocRegistrationOnPackagesToShip_OnAfterAddStepToLicensePlate(var _RequestValues: Record "MOB NS Request Element"; var _Step: Record "MOB Steps Element")
    begin
    end;

    // TODO [Obsolete('Use "MOB WMS Pack Lookup".OnPostAdhocRegistrationOnPackagesToShip_OnBeforeUpdateLicensePlate instead  (planned for removal 04/2024)', 'MOB5.41')]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Pack Lookup", 'OnPostAdhocRegistrationOnPackagesToShip_OnBeforeUpdateLicensePlate', '', true, true)]
    [IntegrationEvent(false, false)]
    local procedure OnPostAdhocRegistrationOnPackagesToShip_OnBeforeUpdateLicensePlate(var _RequestValues: Record "MOB NS Request Element"; var _IsHandled: Boolean)
    begin
    end;

}
