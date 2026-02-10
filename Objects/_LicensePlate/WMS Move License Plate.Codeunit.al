codeunit 82221 "MOB WMS MoveLicensePlate"
{
    Access = Public;
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Adhoc Registr.", 'OnGetRegistrationConfiguration_OnAddSteps', '', true, true)]
    local procedure MoveLicensePlate_OnAddSteps(_RegistrationType: Text; var _HeaderFieldValues: Record "MOB NS Request Element"; var _Steps: Record "MOB Steps Element"; var _RegistrationTypeTracking: Text)
    var
        MobLicensePlate: Record "MOB License Plate";
        MobLicensePlateMgt: Codeunit "MOB License Plate Mgt";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        MobToolBox: Codeunit "MOB Toolbox";
    begin
        if _RegistrationType <> 'MoveLicensePlate' then
            exit;

        MobLicensePlate.Get(_HeaderFieldValues.GetValue('LicensePlate', true));

        _RegistrationTypeTracking := MobLicensePlate."No.";

        _Steps.Create_ListStep(10, 'ToLicensePlate');
        _Steps.Set_eanAi(MobToolBox.GetLicensePlateNoGS1Ai());
        _Steps.Set_header(MobWmsLanguage.GetMessage('TO_LICENSEPLATE'));
        _Steps.Set_helpLabel(MobWmsLanguage.GetMessage('TO_LICENSEPLATE_HELP'));
        _Steps.Set_listValues(MobLicensePlateMgt.GetLicensePlatesAsListValues(MobLicensePlate));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Adhoc Registr.", 'OnPostAdhocRegistrationOnCustomRegistrationType', '', true, true)]
    local procedure OnPostAdhocRegistrationOnCustomRegistrationType(_RegistrationType: Text; var _RequestValues: Record "MOB NS Request Element"; var _SuccessMessage: Text; var _IsHandled: Boolean)
    begin
        if _IsHandled then
            exit;

        if _RegistrationType = 'MoveLicensePlate' then begin
            _SuccessMessage := MoveLicensePlate(_RegistrationType, _RequestValues);
            _IsHandled := true;
        end;
    end;

    /// <summary>
    /// Move a "Top-Level" license plate (including all its contents) to a new license plate.
    /// Both license plates must be associated to the same warehouse shipment.
    /// </summary>    
    local procedure MoveLicensePlate(_RegistrationType: Text; var _RequestValues: Record "MOB NS Request Element"): Text
    var
        MobLicensePlate: Record "MOB License Plate";
        ToLicensePlate: Record "MOB License Plate";
        NewLicensePlateContent: Record "MOB License Plate Content";
        MobLicensePlateMgt: Codeunit "MOB License Plate Mgt";
    begin
        if _RegistrationType <> 'MoveLicensePlate' then
            exit;

        MobLicensePlate.Get(_RequestValues.GetValue('LicensePlate'));
        MobLicensePlate.CalcFields("Top-level");
        MobLicensePlate.TestField("Top-level");

        ToLicensePlate.Get(_RequestValues.GetValue('ToLicensePlate'));

        // Make sure we only move to License Plate related to same Whse. Source Doc Type + No.
        ToLicensePlate.TestField("Whse. Document Type", MobLicensePlate."Whse. Document Type");
        ToLicensePlate.TestField("Whse. Document No.", MobLicensePlate."Whse. Document No.");

        // Make sure the Move is valid, to avoid LP orfants..
        MobLicensePlateMgt.CheckIsValidToLicensePlate(MobLicensePlate."No.", ToLicensePlate."No.");

        // Create new Content from the License Plate that is moved
        NewLicensePlateContent.Init();
        NewLicensePlateContent.Validate("License Plate No.", ToLicensePlate."No.");
        NewLicensePlateContent.Validate(Type, NewLicensePlateContent.Type::"License Plate");
        NewLicensePlateContent.Validate("No.", MobLicensePlate."No.");
        NewLicensePlateContent.Validate("Quantity (Base)", 1);
        NewLicensePlateContent.Validate("Line No.", MobLicensePlateMgt.GetNextLicensePlateContentLineNo(ToLicensePlate));
        NewLicensePlateContent.Validate("Whse. Document Type", ToLicensePlate."Whse. Document Type");
        NewLicensePlateContent.Validate("Whse. Document No.", ToLicensePlate."Whse. Document No.");
        NewLicensePlateContent.Validate("Whse. Document Line No.", 0);  // Line reference is populated only on Type::Item)
        NewLicensePlateContent.Insert();

        // Ensure to update Shipping Status Field                        
        MobLicensePlate.Validate("Shipping Status", ToLicensePlate."Shipping Status");

        // No need to update Receipt Status Field, as you cannot move a License Plate into a License Plate that is already received

        MobLicensePlate.Modify(true);
    end;
}
