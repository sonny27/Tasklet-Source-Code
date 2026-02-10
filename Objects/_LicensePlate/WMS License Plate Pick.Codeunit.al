codeunit 81284 "MOB WMS License Plate Pick"
{
    Access = Public;

    var
        MobSetup: Record "MOB Setup";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        PickFromLPErr: Label 'You cannot pick from License Plate %1 because it is linked to %2 %3.', Comment = '%1 = License Plate No., %2 = Whse. Document Type, %3 = Whse. Document No.';
        NoContentTxt: Label 'No content available to pick from LP: %1', Comment = '%1 = License Plate No.';
        Inv_Pick_And_From_LP_Not_AllowedErr: Label 'Picking from License Plate is not supported for Inventory Pick. Only available for Warehouse Pick', Locked = true;
        FromLicensePlateStepHelpTxt: Label 'Scan the License Plate you are picking the items from';
        LPHandlingDisabledErr: Label 'License Plate handling in Picking is disabled for Location %1.', Comment = '%1 is Location Code ';

    /// <summary>
    /// Finds the content on a License Plate that can be picked based on the scanned License Plate received in the 'ScannedValue' field of the _RequestValues.
    /// </summary>    
    internal procedure GetLicensePlateContentToPick(var _RequestValues: Record "MOB NS Request Element"; var _Commands: Record "MOB Command Element"; var _RegistrationTypeTracking: Text)
    var
        WhseActHeader: Record "Warehouse Activity Header";
        WhseActLine: Record "Warehouse Activity Line";
        MobLicensePlate: Record "MOB License Plate";
        MobLicensePlateContent: Record "MOB License Plate Content";
        MobFeatureTelemetryWrapper: Codeunit "MOB Feature Telemetry Wrapper";
        MobTelemetryEventId: Enum "MOB Telemetry Event ID";
        MobColorCode: Enum "MOB Color Code";
        BackendId: Code[20];
        LicensePlateNo: Text;
        PickFromLPDetected: Boolean;
    begin
        // Read the request values
        BackendId := _RequestValues.Get_BackendID();
        LicensePlateNo := _RequestValues.GetValue('scannedValue', false);


        if not MobLicensePlate.Get(LicensePlateNo) then
            Error(MobWmsLanguage.GetMessage('LP_NOT_FOUND_ERROR'), LicensePlateNo);

        // We only support picking from license plates that are not in use, defined as not having a Whse. Document Type or Whse. Document No.
        if MobLicensePlate."Whse. Document Type" <> MobLicensePlate."Whse. Document Type"::" " then
            Error(PickFromLPErr, MobLicensePlate."No.", MobLicensePlate."Whse. Document Type", MobLicensePlate."Whse. Document No.");

        _RegistrationTypeTracking := MobLicensePlate.TableCaption() + ': ' + MobLicensePlate."No.";

        WhseActHeader.SetRange("No.", BackendId);

        // Check if the backend document is an Inventory Pick, which is not supported for picking from LP
        WhseActHeader.SetRange(Type, WhseActHeader.Type::"Invt. Pick");
        if not WhseActHeader.IsEmpty() then
            Error(Inv_Pick_And_From_LP_Not_AllowedErr);

        WhseActHeader.SetRange(Type, WhseActHeader.Type::Pick);

        // Create a new Filter command
        _Commands.Create_LicensePlate_Filter('1', MobLicensePlate, _RequestValues);

        // If matching content is found, we can set the filter to include the line in the filter command
        if WhseActHeader.FindFirst() then begin

            // Ensure that License Plate handling is enabled for picking at the location
            CheckFromLicensePlateHandling(WhseActHeader."Location Code");

            WhseActLine.SetRange("Activity Type", WhseActHeader.Type);
            WhseActLine.SetRange("No.", WhseActHeader."No.");
            WhseActLine.SetFilter("Breakbulk No.", '=0');
            WhseActLine.SetRange("Action Type", WhseActLine."Action Type"::Take);
            WhseActLine.SetRange("Location Code", MobLicensePlate."Location Code");

            // TODO Await customer/partner feedback to determine if we should apply this filter or not
            // This filter ensures that we only include lines with matching bin code from the LP             
            // WhseActLine.SetRange("Bin Code", MobLicensePlate."Bin Code");

            WhseActLine.SetFilter("Qty. Outstanding", '>0');
            if WhseActLine.FindSet() then
                repeat
                    MobLicensePlateContent.Reset();
                    MobLicensePlateContent.SetRange("License Plate No.", MobLicensePlate."No.");
                    MobLicensePlateContent.SetRange(Type, MobLicensePlateContent.Type::Item);
                    MobLicensePlateContent.SetRange("No.", WhseActLine."Item No.");
                    MobLicensePlateContent.SetRange("Variant Code", WhseActLine."Variant Code");
                    MobLicensePlateContent.SetRange("Unit Of Measure Code", WhseActLine."Unit of Measure Code");

                    // Filter by Lot No., Serial No. and Package No. if they are set in the WhseActLine
                    // Could be pre-filled if Pick acording to FeFo is used or partial post against a Whse. Act Line has been done
                    if WhseActLine."Lot No." <> '' then
                        MobLicensePlateContent.SetRange("Lot No.", WhseActLine."Lot No.");

                    if WhseActLine."Serial No." <> '' then
                        MobLicensePlateContent.SetRange("Serial No.", WhseActLine."Serial No.");

                    /* #if BC18+ */
                    if WhseActLine."Package No." <> '' then
                        MobLicensePlateContent.SetRange("Package No.", WhseActLine."Package No.");
                    /* #endif */

                    if MobLicensePlateContent.FindFirst() then begin
                        _Commands.Set_Filter_Include('LineNumber', Format(WhseActLine."Line No."));
                        PickFromLPDetected := true;
                    end;
                until WhseActLine.Next() = 0;
        end;

        // Handle no matching content found
        if not PickFromLPDetected then begin
            _Commands.Set_Filter_Include('LineNumber', 'No_Lines_Found'); // 'No Lines Found' means no lines will match the filter on the mobile device
            _Commands.Set_Filter_BackgroundColor(Format(MobColorCode::Red));
            _Commands.Set_Filter_DisplayText(StrSubstNo(NoContentTxt, MobLicensePlate."No."));
            _Commands.Set_Filter_Icon('error');
        end;

        // Logging uptake telemetry for used LP feature
        if PickFromLPDetected then
            MobFeatureTelemetryWrapper.LogUptakeUsed(MobTelemetryEventId::"License Plating - Pick From LP (MOB1087)");

        OnAfterGetLicensePlateContentToPick(_RequestValues, _Commands, _RegistrationTypeTracking);
    end;

    internal procedure HandleFromLicensePlateStep(var _RecRef: RecordRef; var _BaseOrderLineElement: Record "MOB NS BaseDataModel Element"; var _Steps: Record "MOB Steps Element")
    var
        Location: Record Location;
        MobLPHandling: Enum "MOB License Plate Handling";
        IsHandled: Boolean;
    begin
        if not MobSetup.LicensePlatingIsEnabled() then
            exit;

        OnBeforeHandleFromLicensePlateStep(_RecRef, _BaseOrderLineElement, _Steps, IsHandled);
        if IsHandled then
            exit;

        if not Location.Get(_BaseOrderLineElement.Get_Location()) then
            exit;

        // Check if location requires From-License Plate during picking
        if Location."MOB Pick from LP" = Location."MOB Pick from LP"::Disabled then
            exit;

        _Steps.Create_TextStep(15, 'FromLicensePlate');
        _Steps.Set_header(MobWmsLanguage.GetMessage('FROM_LICENSEPLATE'));
        _Steps.Set_helpLabel(FromLicensePlateStepHelpTxt);
        _Steps.Set_visible('onEmptyInput');  // Make step visible if no value is provided, eg. from a filter command
        _Steps.Set_optional(Location."MOB Pick from LP" = MobLPHandling::Optional);
        _Steps.Save();
    end;

    internal procedure CheckFromLicensePlateHandling(_LocationCode: Code[20])
    var
        Location: Record Location;
    begin
        Location.Get(_LocationCode);
        if Location."MOB Pick from LP" = Location."MOB Pick from LP"::Disabled then
            Error(LPHandlingDisabledErr, Location.Code);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeHandleFromLicensePlateStep(_RecRef: RecordRef; var _BaseOrderLineElement: Record "MOB NS BaseDataModel Element"; var _Steps: Record "MOB Steps Element"; var _IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetLicensePlateContentToPick(var _RequestValues: Record "MOB NS Request Element"; var _Commands: Record "MOB Command Element"; var _RegistrationTypeTracking: Text)
    begin
    end;
}
