codeunit 81293 "MOB WMS License Plate Receive"
{
    Access = Public;

    var
        MobSetup: Record "MOB Setup";
        ToLicensePlateStepHelpTxt: Label 'Scan or enter the To License Plate for receiving items';
        LPHandlingDisabledErr: Label 'License Plate handling in Receive is disabled for Location %1.', Comment = '%1 is Location Code ';

    internal procedure HandleToLicensePlateStep(var _RecRef: RecordRef; var _BaseOrderLineElement: Record "MOB NS BaseDataModel Element"; var _Steps: Record "MOB Steps Element")
    var
        Location: Record Location;
        MobWmsLanguage: Codeunit "MOB WMS Language";
        MobLPHandling: Enum "MOB License Plate Handling";
        IsHandled: Boolean;
    begin
        if not MobSetup.LicensePlatingIsEnabled() then
            exit;

        OnBeforeHandleToLicensePlateStep(_RecRef, _BaseOrderLineElement, _Steps, IsHandled);
        if IsHandled then
            exit;

        if not Location.Get(_BaseOrderLineElement.Get_Location()) then
            exit;

        // Check if location requires License Plate during receiving
        if Location."MOB Receive to LP" = Location."MOB Receive to LP"::Disabled then
            exit;

        _Steps.Create_TextStep(55, 'LicensePlate');
        _Steps.Set_header(MobWmsLanguage.GetMessage('TO_LICENSEPLATE'));
        _Steps.Set_helpLabel(ToLicensePlateStepHelpTxt);
        _Steps.Set_visible('onEmptyInput');  // Make step visible if no value is provided
        _Steps.Set_optional(Location."MOB Receive to LP" = MobLPHandling::Optional);
        _Steps.Save();
    end;

    internal procedure CheckToLicensePlateHandling(_LocationCode: Code[20])
    var
        Location: Record Location;
    begin
        Location.Get(_LocationCode);
        if Location."MOB Receive to LP" = Location."MOB Receive to LP"::Disabled then
            Error(LPHandlingDisabledErr, Location.Code);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeHandleToLicensePlateStep(_RecRef: RecordRef; var _BaseOrderLineElement: Record "MOB NS BaseDataModel Element"; var _Steps: Record "MOB Steps Element"; var _IsHandled: Boolean)
    begin
    end;
}
