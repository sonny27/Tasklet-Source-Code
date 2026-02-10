codeunit 82226 "MOB WMS LicensePlate Lookup"
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
        AddHeaderConfiguration_LicensePlateHeader(_HeaderFields);
    end;

    local procedure AddHeaderConfiguration_LicensePlateHeader(var _HeaderConfiguration: Record "MOB HeaderField Element")
    begin
        _HeaderConfiguration.InitConfigurationKey_LicensePlateHeader();
        _HeaderConfiguration.Create_ListField_Location(10);
        _HeaderConfiguration.Create_TextField_FromBinOrLP(20);
    end;

    internal procedure LookupLicensePlate(var _RequestValues: Record "MOB NS Request Element"; var _LookupResponseElement: Record "MOB NS WhseInquery Element"; var _ReturnRegistrationTypeTracking: Text)
    var
        Bin: Record Bin;
        MobLicensePlate: Record "MOB License Plate";
        MobSetup: Record "MOB Setup";
        MobSessionData: Codeunit "MOB SessionData";
        LicensePlateNumber: Code[20];
        FromBinOrLP: Code[20];
        LocationCode: Code[10];
    begin
        MobSetup.CheckLicensePlatingIsEnabled();

        LocationCode := _RequestValues.Get_Location();
        FromBinOrLP := _RequestValues.Get_FromBinOrLP();

        if not Bin.Get(LocationCode, FromBinOrLP) then
            LicensePlateNumber := FromBinOrLP;

        MobLicensePlate.SetRange("Location Code", LocationCode);
        MobLicensePlate.SetFilter("Bin Code", Bin.Code);
        MobLicensePlate.SetFilter("No.", LicensePlateNumber);
        if LicensePlateNumber = '' then
            MobLicensePlate.SetRange("Top-level", true);

        MobLicensePlate.SetFilter("Shipping Status", '<>%1', MobLicensePlate."Shipping Status"::Shipped);
        MobLicensePlate.SetAutoCalcFields("Content Exists", "Content Quantity (Base)", "Sub License Plate Qty.");
        if MobLicensePlate.FindSet() then
            repeat
                // Set values for the <BaseOrderLine>-element and save to buffer
                _LookupResponseElement.Create();
                SetFromLicensePlate(MobLicensePlate, _LookupResponseElement);
                _LookupResponseElement.Save();
            until MobLicensePlate.Next() = 0;

        _ReturnRegistrationTypeTracking := DelChr(LocationCode + ' - ' + Bin.Code + ' - ' + LicensePlateNumber, '<>', ' - ');
        MobSessionData.SetRegistrationTypeTracking(_ReturnRegistrationTypeTracking);
    end;

    internal procedure SetFromLicensePlate(var _MobLicensePlate: Record "MOB License Plate"; var _LookupResponse: Record "MOB NS WhseInquery Element")
    var
        MobLicensePlateContent: Record "MOB License Plate Content";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
        NoOfLines: Integer;
        DisplayLine2To9List: List of [Text];
        ExtraInfo1_Col1: List of [Text];
        ExtraInfo1_Col2: List of [Text];
        ExtraInfo1_Col3: List of [Text];
        ExtraInfo2_Col1: List of [Text];
        ExtraInfo2_Col2: List of [Text];
        ExtraInfo2_Col3: List of [Text];
    begin
        _LookupResponse.Init();

        _LookupResponse.SetValue('LicensePlate', _MobLicensePlate."No.");
        _LookupResponse.Set_Barcode(_MobLicensePlate."No.");
        _LookupResponse.Set_Number(_MobLicensePlate."No.");

        // Force print of label for current License Plate rather than pulling a next number from the number series (when the LabelTemplate."Number Series" is populated)
        _LookupResponse.SetValue('NoSeriesValue', _MobLicensePlate."No.");

        _LookupResponse.Set_ReferenceID(_MobLicensePlate.GetReferenceID());
        _LookupResponse.SetValue('SourceReferenceID', _MobLicensePlate.GetSourceReferenceID());

        MobLicensePlateContent.SetRange("License Plate No.", _MobLicensePlate."No.");
        if MobLicensePlateContent.FindSet() then begin
            ExtraInfo1_Col1.Add('Type');
            ExtraInfo1_Col2.Add('No.');
            ExtraInfo1_Col3.Add('Quantity');
            repeat
                NoOfLines += 1;
                if NoOfLines <= 2 then begin
                    if MobLicensePlateContent.Type = MobLicensePlateContent.Type::Item then
                        ExtraInfo2_Col1.Add(Format(MobLicensePlateContent.Type))
                    else
                        ExtraInfo2_Col1.Add('LP');  // LP is short for License Plate

                    ExtraInfo2_Col2.Add(MobLicensePlateContent."No.");
                    ExtraInfo2_Col3.Add(StrSubstNo('%1 %2', MobWmsToolbox.Decimal2TextAsDisplayFormat(MobLicensePlateContent.Quantity), MobLicensePlateContent."Unit Of Measure Code"))
                end else begin
                    ExtraInfo2_Col1.Add('...');
                    ExtraInfo2_Col2.Add('...');
                    ExtraInfo2_Col3.Add('...');
                end;
            until (MobLicensePlateContent.Next() = 0) or (NoOfLines > 2);
        end;

        _LookupResponse.SetValue('ExtraInfo1_Col1', MobWmsToolbox.List2TextLn(ExtraInfo1_Col1, 999));
        _LookupResponse.SetValue('ExtraInfo1_Col2', MobWmsToolbox.List2TextLn(ExtraInfo1_Col2, 999));
        _LookupResponse.SetValue('ExtraInfo1_Col3', MobWmsToolbox.List2TextLn(ExtraInfo1_Col3, 999));
        _LookupResponse.SetValue('ExtraInfo2_Col1', MobWmsToolbox.List2TextLn(ExtraInfo2_Col1, 999));
        _LookupResponse.SetValue('ExtraInfo2_Col2', MobWmsToolbox.List2TextLn(ExtraInfo2_Col2, 999));
        _LookupResponse.SetValue('ExtraInfo2_Col3', MobWmsToolbox.List2TextLn(ExtraInfo2_Col3, 999));

        if _MobLicensePlate."Content Exists" then
            _LookupResponse.Set_DisplayLine1(MobWmsLanguage.GetMessage('LICENSEPLATE') + ': ' + _MobLicensePlate."No.")
        else
            _LookupResponse.Set_DisplayLine1(MobWmsLanguage.GetMessage('LICENSEPLATE') + ': ' + _MobLicensePlate."No." + ' (' + MobWmsLanguage.GetMessage('EMPTY') + ')');

        _LookupResponse.Set_DisplayLine2(StrSubstNo('%1: %2', MobWmsLanguage.GetMessage('BIN'), _MobLicensePlate."Bin Code"));
        if _MobLicensePlate.Comment <> '' then
            _LookupResponse.Set_DisplayLine3(StrSubstNo('%1 %2', MobWmsLanguage.GetMessage('LICENSEPLATE_COMMENT') + ': ', _MobLicensePlate.Comment));

        // Compressed display lines 2 to 9 (after integration events to change display lines)
        _LookupResponse.GetDisplayLinesAsList(DisplayLine2To9List, 2, 9);
        MobWmsToolbox.ListTrimBlank(DisplayLine2To9List, 2);
        _LookupResponse.SetValue('CompressedDisplayLine2To9', MobWmsToolbox.List2TextLn(DisplayLine2To9List, 999));

        OnLookupOnLicensePlate_OnAfterSetFromLicensePlate(_MobLicensePlate, _LookupResponse);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupOnLicensePlate_OnAfterSetFromLicensePlate(_LicensePlate: Record "MOB License Plate"; var _LookupResponseElement: Record "MOB NS WhseInquery Element")
    begin
    end;
}
