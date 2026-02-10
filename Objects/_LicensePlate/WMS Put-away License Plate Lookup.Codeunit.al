codeunit 82227 "MOB WMS Put-away LP Lookup"
{
    Access = Public;
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Reference Data", 'OnGetReferenceData_OnAddHeaderConfigurations', '', true, true)]
    local procedure OnGetReferenceData_OnAddHeaderConfigurations(var _HeaderFields: Record "MOB HeaderField Element")
    var
        MobSetup: Record "MOB Setup";
    begin
        if not MobSetup.LicensePlatingIsEnabled() then
            exit;

        // Add Header for License Plate Content lookup
        _HeaderFields.InitConfigurationKey_PutAwayLicensePlateHeader();
        _HeaderFields.Create_ListField_Location(10);
    end;

    internal procedure LookupPutAwayLicensePlate(var _RequestValues: Record "MOB NS Request Element"; var _LookupResponseElement: Record "MOB NS WhseInquery Element"; var _ReturnRegistrationTypeTracking: Text)
    var
        MobLicensePlate: Record "MOB License Plate";
        MobSetup: Record "MOB Setup";
        MobSessionData: Codeunit "MOB SessionData";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        MobWmsLicensePlateLookup: Codeunit "MOB WMS LicensePlate Lookup";
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
        DisplayLine2To9List: List of [Text];
        LocationCode: Code[10];
        PutAwayNo: Code[20];
    begin
        MobSetup.CheckLicensePlatingIsEnabled();

        LocationCode := _RequestValues.Get_Location();

        MobLicensePlate.SetRange("Location Code", LocationCode);
        MobLicensePlate.SetRange("Top-level", true);
        MobLicensePlate.SetRange("Whse. Document Type", MobLicensePlate."Whse. Document Type"::Receipt);
        MobLicensePlate.SetAutoCalcFields("Content Exists", "Content Quantity (Base)", "Sub License Plate Qty.");
        if MobLicensePlate.FindSet() then
            repeat
                PutAwayNo := MobLicensePlate.GetRelatedPutAwayNo();
                if PutAwayNo <> '' then begin
                    // Set values for the <BaseOrderLine>-element and save to buffer
                    _LookupResponseElement.Create();

                    // Reuse the SetFromLicensePlate method from the LicensePlate Lookup
                    MobWmsLicensePlateLookup.SetFromLicensePlate(MobLicensePlate, _LookupResponseElement);

                    // Override display line 2 with the PutAwayNo
                    _LookupResponseElement.Set_DisplayLine2(StrSubstNo(MobWmsLanguage.GetMessage('PUTAWAY_NUMBER'), PutAwayNo));

                    // Compressed display lines 2 to 9 again(after integration events to change display lines)
                    _LookupResponseElement.GetDisplayLinesAsList(DisplayLine2To9List, 2, 9);
                    MobWmsToolbox.ListTrimBlank(DisplayLine2To9List, 2);
                    _LookupResponseElement.SetValue('CompressedDisplayLine2To9', MobWmsToolbox.List2TextLn(DisplayLine2To9List, 999));
                end;
            until MobLicensePlate.Next() = 0;

        _ReturnRegistrationTypeTracking := LocationCode;
        MobSessionData.SetRegistrationTypeTracking(_ReturnRegistrationTypeTracking);
    end;
}
