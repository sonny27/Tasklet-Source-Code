codeunit 82222 "MOB WMS AllToNewLicensePlate"
{
    Access = Public;
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Reference Data", 'OnGetReferenceData_OnAddHeaderConfigurations', '', true, true)]
    local procedure OnGetReferenceData_OnAddHeaderConfigurations(var _HeaderFields: Record "MOB HeaderField Element")
    var
        MobPackFeatureMgt: Codeunit "MOB Pack Feature Management";
    begin
        if not MobPackFeatureMgt.IsEnabled() then
            exit;

        // Add Header for Add All To New License Plate
        _HeaderFields.InitConfigurationKey_AllToNewLicensePlateHeader();
        _HeaderFields.Create_TextField_ShipmentNo(10);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Adhoc Registr.", 'OnPostAdhocRegistration_OnAddSteps', '', true, true)]
    local procedure OnPostAdhocRegistration_OnAddSteps(_RegistrationType: Text; var _RequestValues: Record "MOB NS Request Element"; var _Steps: Record "MOB Steps Element"; var _RegistrationTypeTracking: Text)
    var
        MobSetup: Record "MOB Setup";
        MobLicensePlateMgt: Codeunit "MOB License Plate Mgt";
    begin
        if _RegistrationType <> 'AllToNewLicensePlate' then
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
        if _IsHandled then
            exit;

        if _RegistrationType = 'AllToNewLicensePlate' then begin
            _SuccessMessage := MoveAllToNewLicensePlate(_RegistrationType, _RequestValues);
            _IsHandled := true;
        end;
    end;

    local procedure MoveAllToNewLicensePlate(_RegistrationType: Text; var _RequestValues: Record "MOB NS Request Element"): Text
    var
        WhseShipmentHeader: Record "Warehouse Shipment Header";
        LicensePlateToMove: Record "MOB License Plate";
        NewLicensePlate: Record "MOB License Plate";
        WhseShipmentHeaderRecordId: RecordId;
    begin
        if _RegistrationType <> 'AllToNewLicensePlate' then
            exit;

        // Get Whse. Shipment Header from Context (context are single element from page, not all elements)
        Evaluate(WhseShipmentHeaderRecordId, _RequestValues.GetContextValue('ReferenceID', true));
        if WhseShipmentHeader.Get(WhseShipmentHeaderRecordId) then begin

            // Create new License Plate
            NewLicensePlate.InitLicensePlate(_RequestValues.GetValue('NewLicensePlateNo'), WhseShipmentHeader."Location Code", WhseShipmentHeader."Bin Code", NewLicensePlate."Whse. Document Type"::Shipment, WhseShipmentHeader."No.");
            NewLicensePlate.Insert(true);

            // Find all License Plate to move
            LicensePlateToMove.SetRange("Whse. Document Type", LicensePlateToMove."Whse. Document Type"::Shipment);
            LicensePlateToMove.SetRange("Whse. Document No.", WhseShipmentHeader."No.");
            LicensePlateToMove.SetRange("Package Type", '');
            LicensePlateToMove.SetRange("Top-level", true);
            LicensePlateToMove.SetRange("Content Exists", true);
            LicensePlateToMove.SetFilter("No.", '<>%1', NewLicensePlate."No.");
            if LicensePlateToMove.FindSet(true) then
                repeat
                    LicensePlateToMove.MoveToLicensePlate(NewLicensePlate);
                until LicensePlateToMove.Next() = 0;
        end;
    end;
}
