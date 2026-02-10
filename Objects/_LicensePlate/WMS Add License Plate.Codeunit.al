codeunit 82219 "MOB WMS AddLicensePlate"
{
    Access = Public;
    var
        MobLicensePlateMgt: Codeunit "MOB License Plate Mgt";
        MobPackFeatureMgt: Codeunit "MOB Pack Feature Management";

    //
    // -------------------------------- Add License plate from "Pack & Ship" --------------------------------
    //

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Reference Data", 'OnGetReferenceData_OnAddHeaderConfigurations', '', true, true)]
    local procedure OnGetReferenceData_OnAddHeaderConfigurations(var _HeaderFields: Record "MOB HeaderField Element")
    begin
        if not MobPackFeatureMgt.IsEnabled() then
            exit;

        // Add Header for Add License Plate
        _HeaderFields.InitConfigurationKey_AddLicensePlateHeader();
        _HeaderFields.Create_TextField_ShipmentNo(10);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Adhoc Registr.", 'OnPostAdhocRegistration_OnAddSteps', '', true, true)]
    local procedure OnPostAdhocRegistration_OnAddSteps(_RegistrationType: Text; var _RequestValues: Record "MOB NS Request Element"; var _Steps: Record "MOB Steps Element"; var _RegistrationTypeTracking: Text)
    var
        MobSetup: Record "MOB Setup";
    begin
        if not MobPackFeatureMgt.IsEnabled() then
            exit;

        if _RegistrationType <> 'AddLicensePlate' then
            exit;

        if _RequestValues.HasValue('NewLicensePlateNo') then
            exit;   // already collected, break to avoid adding the same new step indefinitely

        MobSetup.Get();
        if MobSetup."LP Number Series" <> '' then
            exit;

        MobLicensePlateMgt.Create_TextStep_NewLicensePlateNo(10, _Steps);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Adhoc Registr.", 'OnPostAdhocRegistrationOnCustomRegistrationType', '', true, true)]
    local procedure OnPostAdhocRegistrationOnCustomRegistrationType(_RegistrationType: Text; var _RequestValues: Record "MOB NS Request Element"; var _SuccessMessage: Text; var _IsHandled: Boolean)
    begin
        if not MobPackFeatureMgt.IsEnabled() then
            exit;

        if _IsHandled then
            exit;

        if _RegistrationType = 'AddLicensePlate' then begin
            _SuccessMessage := AddLicensePlate(_RegistrationType, _RequestValues);
            _IsHandled := true;
        end;
    end;

    //
    // -------------------------------- Misc. Helper --------------------------------
    //

    internal procedure AddLicensePlate(_RegistrationType: Text; var _RequestValues: Record "MOB NS Request Element"): Text
    var
        WhseShipmentHeader: Record "Warehouse Shipment Header";
        MobLicensePlate: Record "MOB License Plate";
        WhseShipmentHeaderRecordId: RecordId;
    begin
        Evaluate(WhseShipmentHeaderRecordId, _RequestValues.GetContextValue('ReferenceID', true));
        WhseShipmentHeader.Get(WhseShipmentHeaderRecordId);

        // Create new License Plate
        MobLicensePlate.InitLicensePlate(_RequestValues.GetValue('NewLicensePlateNo'), WhseShipmentHeader."Location Code", WhseShipmentHeader."Bin Code", MobLicensePlate."Whse. Document Type"::Shipment, WhseShipmentHeader."No.");
        MobLicensePlate.Insert(true);
    end;
}
