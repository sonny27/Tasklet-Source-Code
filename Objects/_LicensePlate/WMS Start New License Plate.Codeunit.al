codeunit 81292 "MOB WMS Start New LicensePlate"
{
    Access = Public;

    var
        MobLicensePlateMgt: Codeunit "MOB License Plate Mgt";
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Adhoc Registr.", 'OnPostAdhocRegistration_OnAddSteps', '', true, true)]
    local procedure CreateStartNewLicensePlateSteps(_RegistrationType: Text; var _RequestValues: Record "MOB NS Request Element"; var _Steps: Record "MOB Steps Element"; var _RegistrationTypeTracking: Text)
    var
        MobSetup: Record "MOB Setup";
    begin
        if _RegistrationType <> MobWmsToolbox."CONST::StartNewLicensePlate"() then
            exit;

        if _RequestValues.HasValue('NewLicensePlateNo') then
            exit;   // already collected, break to avoid adding the same new step indefinitely

        // TODO Add check on Mobile App version, when we know the excact version with commands support for 'pin'. MobDeviceManagement.CheckAppVersionOfCurrentDevice('1.11.?.0', true);

        MobSetup.Get();
        if MobSetup."LP Number Series" = '' then
            MobLicensePlateMgt.Create_TextStep_NewLicensePlateNo(100, _Steps);
    end;

    internal procedure AdhocStartNewLicensePlateFromWhseReceipt(_RegistrationType: Text; var _RequestValues: Record "MOB NS Request Element"; var _Commands: Record "MOB Command Element"; var _SuccessMessage: Text)
    var
        WhseReceiptLine: Record "Warehouse Receipt Line";
        MobLicensePlate: Record "MOB License Plate";
        MobFeatureTelemetryWrapper: Codeunit "MOB Feature Telemetry Wrapper";
        MobWmsLicensePlateReceive: Codeunit "MOB WMS License Plate Receive";
        ReferenceId: RecordId;
        MobTelemetryEventId: Enum "MOB Telemetry Event ID";
    begin
        // Ensure that License Plate handling is enabled for receiving
        MobWmsLicensePlateReceive.CheckToLicensePlateHandling(_RequestValues.GetValueOrContextValue('Location', true));

        Evaluate(ReferenceId, _RequestValues.GetContextValue('ReferenceID', true));
        GetWhseReceiptLineFromReferenceId(ReferenceId, WhseReceiptLine);

        // Create new License Plate
        Clear(MobLicensePlate);
        MobLicensePlate.InitLicensePlate(_RequestValues.GetValue('NewLicensePlateNo'), WhseReceiptLine."Location Code", WhseReceiptLine."Bin Code", MobLicensePlate."Whse. Document Type"::Receipt, _RequestValues.Get_BackendID());
        MobLicensePlate.InitReceiptStatus();
        MobLicensePlate.Insert(true);

        // Add a pin command to the response with reference to the name attribute in the <pinnableByAi> element in application.cfg
        _Commands.Create_Pin('LicensePlate', MobLicensePlate."No.");

        // Logging uptake telemetry for used LP feature
        MobFeatureTelemetryWrapper.LogUptakeUsed(MobTelemetryEventId::"License Plating - Start New LP (MOB1077)");

        _SuccessMessage := '';
    end;

    /// <summary>
    /// Gets the Warehouse Receipt Line record based on the provided ReferenceId.
    /// </summary>    
    local procedure GetWhseReceiptLineFromReferenceId(var ReferenceId: RecordId; var WhseReceiptLine: Record "Warehouse Receipt Line")
    var
        WhseReceiptHeader: Record "Warehouse Receipt Header";
    begin

        // Get the record based on the ReferenceID
        case ReferenceId.TableNo() of
            Database::"Warehouse Receipt Header":
                begin
                    WhseReceiptHeader.Get(ReferenceId); // Intentionally use of unconditional Get to provide best error message to user.
                    WhseReceiptLine.SetRange("No.", WhseReceiptHeader."No.");
                    WhseReceiptLine.FindFirst();
                end;
            Database::"Warehouse Receipt Line":
                WhseReceiptLine.Get(ReferenceId);  // Intentionally use of unconditional Get to provide best error message to user.
        end;
    end;
}
