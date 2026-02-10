codeunit 82220 "MOB WMS DeleteLicensePlate"
{
    Access = Public;
    var
        MobPackFeatureMgt: Codeunit "MOB Pack Feature Management";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        MobToolBox: Codeunit "MOB Toolbox";
        ConfirmDeleteLicensePlateTxt: Label 'Are you sure you want to delete License Plate %1?', Comment = '%1 is the License Plate No.';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Adhoc Registr.", 'OnPostAdhocRegistrationOnCustomRegistrationType', '', true, true)]
    local procedure OnPostAdhocRegistrationOnCustomRegistrationType(_RegistrationType: Text; var _RequestValues: Record "MOB NS Request Element"; var _SuccessMessage: Text; var _IsHandled: Boolean)
    begin
        if _IsHandled then
            exit;

        // TODO: Remove this check when all customers have migrated from Pack and Ship PTE
        if MobPackFeatureMgt.LegacyPackAndShipDetected() then
            exit;

        if _RegistrationType = 'DeleteLicensePlate' then begin
            _SuccessMessage := DeleteLicensePlate(_RegistrationType, _RequestValues);
            _IsHandled := true;
        end;
    end;

    /// <summary>
    /// Delete LP
    /// All contents and children LP's are moved to the parent, if exist
    /// </summary>
    internal procedure DeleteLicensePlate(_RegistrationType: Text; var _RequestValues: Record "MOB NS Request Element"): Text
    var
        MobLicensePlate: Record "MOB License Plate";
    begin
        MobLicensePlate.Get(_RequestValues.GetValue('LicensePlate'));

        CheckDeleteFromPackAndShip(MobLicensePlate);

        MobToolBox.ErrorIfNotConfirm(_RequestValues, StrSubstNo(ConfirmDeleteLicensePlateTxt, MobLicensePlate."No."));
        MobLicensePlate.DeleteLicensePlate();
    end;

    internal procedure CheckDeleteFromPackAndShip(_MobLicensePlate: Record "MOB License Plate")
    begin
        if _MobLicensePlate."Whse. Document Type" = _MobLicensePlate."Whse. Document Type"::Shipment then begin
            _MobLicensePlate.CalcFields("Content Exists");
            if _MobLicensePlate."Content Exists" then
                Error(MobWmsLanguage.GetMessage('LICENSEPLATE_MUST_BE_EMPTY_ERROR'));
        end;
    end;
}
