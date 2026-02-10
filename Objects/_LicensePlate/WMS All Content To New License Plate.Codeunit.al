codeunit 82223 "MOB WMS AllContentToNewLP"
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

        // Add Header for Move all Content to new License Plate
        _HeaderFields.InitConfigurationKey_AllContentToNewLicensePlateHeader();
        _HeaderFields.Create_TextField_ShipmentNo(10);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Adhoc Registr.", 'OnPostAdhocRegistration_OnAddSteps', '', true, true)]
    local procedure OnPostAdhocRegistration_OnAddSteps(_RegistrationType: Text; var _RequestValues: Record "MOB NS Request Element"; var _Steps: Record "MOB Steps Element"; var _RegistrationTypeTracking: Text)
    var
        MobSetup: Record "MOB Setup";
        MobLicensePlateMgt: Codeunit "MOB License Plate Mgt";
    begin
        if _RegistrationType <> 'AllContentToNewLicensePlate' then
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

        if _RegistrationType = 'AllContentToNewLicensePlate' then begin
            _SuccessMessage := MoveAllContentToNewLicensePlate(_RegistrationType, _RequestValues);
            _IsHandled := true;
        end;
    end;

    local procedure MoveAllContentToNewLicensePlate(_RegistrationType: Text; var _RequestValues: Record "MOB NS Request Element"): Text
    var
        WhseShipmentHeader: Record "Warehouse Shipment Header";
        LicensePlateToMove: Record "MOB License Plate";
        NewLicensePlate: Record "MOB License Plate";
        WhseShipmentHeaderRecordId: RecordId;
    begin
        if _RegistrationType <> 'AllContentToNewLicensePlate' then
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
            LicensePlateToMove.SetRange("Top-level", true);
            LicensePlateToMove.SetRange("Package Type", '');
            LicensePlateToMove.SetFilter("Shipping Status", '<>%1', LicensePlateToMove."Shipping Status"::Shipped);
            LicensePlateToMove.SetFilter("No.", '<>%1', NewLicensePlate."No.");
            if LicensePlateToMove.FindSet(true) then
                repeat
                    LicensePlateToMove.MoveContentsTo(NewLicensePlate."No.");
                    LicensePlateToMove.Delete(true);
                until LicensePlateToMove.Next() = 0;
        end;
    end;
}
