codeunit 82231 "MOB Pack Management"
{
    Access = Public;
    /// <summary>
    /// _PackAndShip Plate Object ID range: 6182230 - 6182250
    /// </summary>

    EventSubscriberInstance = Manual;

    // 'PackagesToShipLookup'
    internal procedure GetShippingAgentsAsListValues(): Text
    var
        ShippingAgent: Record "Shipping Agent";
        MobPackageSetup: Record "MOB Mobile WMS Package Setup";
        ShippingAgentListAsTxt: Text;
        DoNotUseShippingAgentPackageTypes: Boolean;
    begin
        DoNotUseShippingAgentPackageTypes := MobPackageSetup.IsEmpty();

        if ShippingAgent.FindSet() then begin
            ShippingAgentListAsTxt += ';';
            repeat
                MobPackageSetup.Reset();
                MobPackageSetup.SetRange("Shipping Agent", ShippingAgent.Code);
                if not MobPackageSetup.IsEmpty() or DoNotUseShippingAgentPackageTypes then
                    ShippingAgentListAsTxt += ShippingAgent.Code + ';';
            until ShippingAgent.Next() = 0;
        end;

        if ShippingAgentListAsTxt <> '' then
            ShippingAgentListAsTxt := DelStr(ShippingAgentListAsTxt, StrLen(ShippingAgentListAsTxt), 1);

        exit(ShippingAgentListAsTxt);
    end;

    // 'PackagesToShipLookup'
    internal procedure GetShippingAgentServicesAsListValues(_ShippingAgentCode: Code[10]): Text
    var
        ShippingAgentService: Record "Shipping Agent Services";
        ShippingAgentServiceListAsTxt: Text;
    begin
        ShippingAgentService.SetRange("Shipping Agent Code", _ShippingAgentCode);
        if ShippingAgentService.FindSet() then begin
            ShippingAgentServiceListAsTxt += ';';
            repeat
                ShippingAgentServiceListAsTxt += ShippingAgentService.Code + ';';
            until ShippingAgentService.Next() = 0;
        end;

        if ShippingAgentServiceListAsTxt <> '' then
            ShippingAgentServiceListAsTxt := DelStr(ShippingAgentServiceListAsTxt, StrLen(ShippingAgentServiceListAsTxt), 1);

        exit(ShippingAgentServiceListAsTxt);
    end;

    /// <summary>
    /// Handled online validation of Tote ID
    /// </summary>
    // TODO: Move OnlineValidation code to own codeunit
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Whse. Inquiry", 'OnWhseInquiryOnCustomDocumentTypeAsXml', '', true, true)]
    local procedure OnlineValidate_OnWhseInquiryOnCustomDocumentType(_DocumentType: Text; var _XMLRequestDoc: XmlDocument; var _XMLResponseDoc: XmlDocument; var _IsHandled: Boolean)
    begin
        // Check linked Warehouse Document to License Plate
        ValidateToteIdOnWhseDocReference(_DocumentType, _XMLRequestDoc, _XMLResponseDoc, _IsHandled);
    end;

    internal procedure ValidateToteIdOnWhseDocReference(_DocumentType: Text; var _XMLRequestDoc: XmlDocument; var _XMLResponseDoc: XmlDocument; var _IsHandled: Boolean)
    var
        TempRequestValues: Record "MOB NS Request Element" temporary;
        WhseActLine: Record "Warehouse Activity Line";
        LicensePlate: Record "MOB License Plate";
        MobToolbox: Codeunit "MOB Toolbox";
        RequestMgt: Codeunit "MOB NS Request Management";
    begin
        if _IsHandled then
            exit;

        // Save the incoming request values
        RequestMgt.SaveAdhocFilters(_XMLRequestDoc, TempRequestValues);

        // Use request values and throw any validation error
        case _DocumentType of
            'ValidateToteID':
                if LicensePlate.Get(TempRequestValues.Get_ToteID()) then
                    if LicensePlate."Whse. Document No." <> '' then begin
                        WhseActLine.Get(WhseActLine."Activity Type"::Pick, TempRequestValues.GetValue('orderBackendId'), TempRequestValues.GetValue('lineNumber'));
                        LicensePlate.TestField("Whse. Document Type", WhseActLine."Whse. Document Type");
                        LicensePlate.TestField("Whse. Document No.", WhseActLine."Whse. Document No.");
                    end;
            else
                exit;
        end;

        // Validation did not error, so respond = OK
        MobToolbox.CreateSimpleResponse(_XMLResponseDoc, 'OK');
        _IsHandled := true;
    end;

    internal procedure UpdateDefaultPackageDimensionsOnLicensePlate(_PackageType: Record "MOB Package Type"; var _LicensePlate: Record "MOB License Plate")
    begin
        if _LicensePlate."No." = '' then
            exit;

        _LicensePlate.Validate(Length, _PackageType.Length);
        _LicensePlate.Validate(Width, _PackageType.Width);
        _LicensePlate.Validate(Height, _PackageType.Height);
        _LicensePlate.Validate(Weight, _PackageType.Weight);
        _LicensePlate.Validate("Loading Meter", _PackageType."Loading Meter");
    end;

    internal procedure ResetDefaultPackageDimensionsOnLicensePlate(var _LicensePlate: Record "MOB License Plate")
    begin
        if _LicensePlate."No." = '' then
            exit;

        Clear(_LicensePlate.Length);
        Clear(_LicensePlate.Width);
        Clear(_LicensePlate.Height);
        Clear(_LicensePlate.Weight);
        Clear(_LicensePlate."Loading Meter");
    end;

    internal procedure CheckLicensePlatePackageInfo(var _LicensePlate: Record "MOB License Plate")
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        MobPackageSetup: Record "MOB Mobile WMS Package Setup";
        MobPackageType: Record "MOB Package Type";
        MobLicensePlateMgt: Codeunit "MOB License Plate Mgt";
        Ready: Boolean;
    begin
        if _LicensePlate."Whse. Document Type" <> _LicensePlate."Whse. Document Type"::Shipment then
            exit;

        // Only update "Top-Level" License Plates
        _LicensePlate.CalcFields("Top-level");
        if not _LicensePlate."Top-level" then
            exit;

        if _LicensePlate."Shipping Status" = _LicensePlate."Shipping Status"::Shipped then
            exit;

        // If no Package Setup exist or License plate is already handled, then no need for further checks
        if MobPackageSetup.IsEmpty() or _LicensePlate."Transferred to Shipping" then begin
            _LicensePlate.Validate("Shipping Status", _LicensePlate."Shipping Status"::Ready);
            exit;
        end;

        // Ensure required values before actual check is performed
        Ready := true;
        Ready := Ready and (_LicensePlate."Whse. Document Type" = _LicensePlate."Whse. Document Type"::Shipment);
        Ready := Ready and WarehouseShipmentHeader.Get(_LicensePlate."Whse. Document No.");
        Ready := Ready and (WarehouseShipmentHeader."Shipping Agent Code" <> '');
        Ready := Ready and (_LicensePlate."Package Type" <> '');
        Ready := Ready and MobPackageType.Get(_LicensePlate."Package Type");

        MobPackageSetup.SetRange("Shipping Agent", WarehouseShipmentHeader."Shipping Agent Code");
        MobPackageSetup.SetFilter("Shipping Agent Service Code", '%1|%2', WarehouseShipmentHeader."Shipping Agent Service Code", '');
        MobPackageSetup.SetRange("Package Type", MobPackageType.Code);
        Ready := Ready and MobPackageSetup.FindLast();

        // Check required fields in Package Setup
        if Ready and MobPackageSetup."Register Length" then
            Ready := _LicensePlate.Length <> 0;

        if Ready and MobPackageSetup."Register Width" then
            Ready := _LicensePlate.Width <> 0;

        if Ready and MobPackageSetup."Register Height" then
            Ready := _LicensePlate.Height <> 0;

        if Ready and MobPackageSetup."Register Weight" then
            Ready := _LicensePlate.Weight <> 0;

        if Ready and MobPackageSetup."Register Loading Meter" then
            Ready := _LicensePlate."Loading Meter" <> 0;

        MobLicensePlateMgt.OnCheckLicensePlatePackageInfo(_LicensePlate, MobPackageSetup, Ready);

        if Ready then
            _LicensePlate.Validate("Shipping Status", _LicensePlate."Shipping Status"::Ready)
        else
            _LicensePlate.Validate("Shipping Status", _LicensePlate."Shipping Status"::" ")
    end;

    internal procedure CreateValidDataTableName(_InputText: Text): Text
    var
        OutputText: Text;
    begin
        OutputText := _InputText;
        OutputText := ConvertStr(OutputText, ' ', '_');
        OutputText := ConvertStr(OutputText, '.', '_');
        OutputText := ConvertStr(OutputText, ',', '_');
        OutputText := ConvertStr(OutputText, '-', '_'); // Is valid in Xml tag name but unsupported in Android App
        exit(OutputText);
    end;

    /// <summary>
    /// Check if all ATO lines are completely picked
    /// </summary>
    internal procedure ATOCompletelyPicked(_WhseShipmentHeader: Record "Warehouse Shipment Header"): Boolean
    var
        AssemblyHeader: Record "Assembly Header";
        ATOLink: Record "Assemble-to-Order Link";
        WhseShipmentLine: Record "Warehouse Shipment Line";
    begin
        WhseShipmentLine.SetRange("No.", _WhseShipmentHeader."No.");
        WhseShipmentLine.SetRange("Assemble to Order", true);
        if WhseShipmentLine.FindSet() then
            repeat
                ATOLink.SetRange("Assembly Document Type", ATOLink."Assembly Document Type"::Order);
                ATOLink.SetRange("Document No.", WhseShipmentLine."Source No.");
                if ATOLink.FindSet() then
                    repeat
                        if AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, ATOLink."Assembly Document No.") then
                            if not AssemblyHeader.CompletelyPicked() then
                                exit(false);
                    until ATOLink.Next() = 0;
            until WhseShipmentLine.Next() = 0;
        exit(true);
    end;

    // ----------------- Procedures used from different Codeunits -------------------------------------

    // 'PackLookup' and 'BulkRegPackageInfo'
    internal procedure AddPackageInfoSteps(var _Steps: Record "MOB Steps Element"; _ShippingAgentCode: Code[20]; _ShippingAgentServiceCode: Code[10]; _LicensePlateNo: Code[20])
    var
        MobSetup: Record "MOB Setup";
        MobPackageSetup: Record "MOB Mobile WMS Package Setup";
        MobLicensePlate: Record "MOB License Plate";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        MobPackMgt: Codeunit "MOB Pack Management";
        DataTableName: Text;
        ShippingAgentServiceSetupFound: Boolean;
    begin
        if MobPackageSetup.IsEmpty() then
            exit;

        if _ShippingAgentCode = '' then
            exit;

        MobSetup.Get();
        if _LicensePlateNo <> '' then
            MobLicensePlate.Get(_LicensePlateNo);

        // Check if any Package Type is setup for the Shipping Agent Service
        if _ShippingAgentServiceCode <> '' then begin
            MobPackageSetup.SetCurrentKey("Shipping Agent", "Shipping Agent Service Code");
            MobPackageSetup.SetRange("Shipping Agent", _ShippingAgentCode);
            MobPackageSetup.SetRange("Shipping Agent Service Code", _ShippingAgentServiceCode);
            if not MobPackageSetup.IsEmpty() then
                ShippingAgentServiceSetupFound := true;
        end;

        // Determine DataTableName to use
        if (_ShippingAgentServiceCode = '') or (not ShippingAgentServiceSetupFound) then
            DataTableName := StrSubstNo('%1_%2', 'PackageTypeTable', MobPackMgt.CreateValidDataTableName(_ShippingAgentCode))
        else
            DataTableName := StrSubstNo('%1_%2_%3', 'PackageTypeTable', MobPackMgt.CreateValidDataTableName(_ShippingAgentCode), MobPackMgt.CreateValidDataTableName(_ShippingAgentServiceCode));

        _Steps.Create_ListStep(100, 'PackageType', false);
        _Steps.Set_header(MobWmsLanguage.GetMessage('PACKAGE_TYPE_LABEL'));
        _Steps.Set_helpLabel(MobWmsLanguage.GetMessage('PACKAGE_TYPE'));
        _Steps.Set_dataTable(DataTableName);  // 'PackageTypeTable-ShippingAgentCode'
        _Steps.Set_dataKeyColumn('Code');
        _Steps.Set_dataDisplayColumn('Name');
        _Steps.Set_optional(true);

        // Identify if any default Package should be set
        if MobLicensePlate."Package Type" <> '' then
            _Steps.Set_defaultValue(MobLicensePlate."Package Type")
        else begin
            MobPackageSetup.Reset();
            MobPackageSetup.SetCurrentKey("Shipping Agent", "Shipping Agent Service Code");
            MobPackageSetup.SetRange("Shipping Agent", _ShippingAgentCode);
            MobPackageSetup.SetFilter("Shipping Agent Service Code", '%1|%2', '', _ShippingAgentServiceCode);
            MobPackageSetup.SetRange("Default Package Type", true);
            if MobPackageSetup.FindLast() then
                _Steps.Set_defaultValue(MobPackageSetup."Package Type");
        end;

        _Steps.Save();
    end;

    // 'PackLookup' and 'BulkRegPackageInfo'
    internal procedure AddPackageInfoLastSteps(var _Steps: Record "MOB Steps Element"; var _RequestValues: Record "MOB NS Request Element")
    var
        WhseShipmentHeader: Record "Warehouse Shipment Header";
        MobSetup: Record "MOB Setup";
        MobPackageSetup: Record "MOB Mobile WMS Package Setup";
        MobPackageType: Record "MOB Package Type";
        MobLicensePlate: Record "MOB License Plate";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        MobWmsPackLookup: Codeunit "MOB WMS Pack Lookup";
        PackageTypeCode: Code[100];
        LicensePlateCode: Code[20];
    begin
        MobSetup.Get();

        if not WhseShipmentHeader.Get(_RequestValues.GetValue('BackendID')) then
            exit;

        if WhseShipmentHeader."Shipping Agent Code" = '' then
            exit;

        Evaluate(PackageTypeCode, _RequestValues.GetValue('PackageType'));

        if not MobPackageType.Get(PackageTypeCode) then
            exit;

        MobPackageSetup.SetRange("Shipping Agent", WhseShipmentHeader."Shipping Agent Code");
        MobPackageSetup.SetFilter("Shipping Agent Service Code", '%1|%2', WhseShipmentHeader."Shipping Agent Service Code", '');
        MobPackageSetup.SetRange("Package Type", MobPackageType.Code);
        if not MobPackageSetup.FindFirst() then
            exit;

        Evaluate(LicensePlateCode, _RequestValues.GetValue('LicensePlate'));
        if LicensePlateCode <> '' then
            MobLicensePlate.Get(LicensePlateCode);

        if MobPackageSetup."Register Length" then begin
            _Steps.Create_DecimalStep(200, 'Length');
            _Steps.Set_header(MobWmsLanguage.GetMessage('LENGTH_LABEL'));
            _Steps.Set_helpLabel(MobWmsLanguage.GetMessage('ENTER_LENGTH') + ': ' + MobSetup."Dimensions Unit");
            if MobLicensePlate.Length <> 0 then
                _Steps.Set_defaultValue(MobLicensePlate.Length)
            else
                _Steps.Set_defaultValue(MobPackageSetup."Default Length");
            _Steps.Save();
        end;

        if MobPackageSetup."Register Width" then begin
            _Steps.Create_DecimalStep(300, 'Width');
            _Steps.Set_header(MobWmsLanguage.GetMessage('WIDTH_LABEL'));
            _Steps.Set_helpLabel(MobWmsLanguage.GetMessage('ENTER_WIDTH') + ': ' + MobSetup."Dimensions Unit");
            if MobLicensePlate.Width <> 0 then
                _Steps.Set_defaultValue(MobLicensePlate.Width)
            else
                _Steps.Set_defaultValue(MobPackageSetup."Default Width");
            _Steps.Save();
        end;

        if MobPackageSetup."Register Height" then begin
            _Steps.Create_DecimalStep(400, 'Height');
            _Steps.Set_header(MobWmsLanguage.GetMessage('HEIGHT_LABEL'));
            _Steps.Set_helpLabel(MobWmsLanguage.GetMessage('ENTER_HEIGHT') + ': ' + MobSetup."Dimensions Unit");
            if MobLicensePlate.Height <> 0 then
                _Steps.Set_defaultValue(MobLicensePlate.Height)
            else
                _Steps.Set_defaultValue(MobPackageSetup."Default Height");
            _Steps.Save();
        end;

        if MobPackageSetup."Register Weight" then begin
            _Steps.Create_DecimalStep(500, 'Weight');
            _Steps.Set_header(MobWmsLanguage.GetMessage('WEIGHT_LABEL'));
            _Steps.Set_helpLabel(MobWmsLanguage.GetMessage('ENTER_WEIGHT') + ': ' + MobSetup."Weight Unit");
            if MobLicensePlate.Weight <> 0 then
                _Steps.Set_defaultValue(MobLicensePlate.Weight)
            else
                _Steps.Set_defaultValue(MobPackageSetup."Default Weight");
            _Steps.Save();
        end;

        if MobPackageSetup."Register Loading Meter" then begin
            _Steps.Create_DecimalStep(600, 'LoadMeter');
            _Steps.Set_header(MobWmsLanguage.GetMessage('LOAD_METER_LABEL'));
            _Steps.Set_helpLabel(MobWmsLanguage.GetMessage('ENTER_LOAD_METER') + ':');
            if MobLicensePlate."Loading Meter" <> 0 then
                _Steps.Set_defaultValue(MobLicensePlate."Loading Meter")
            else
                _Steps.Set_defaultValue(MobPackageSetup."Default Loading Meter");
            _Steps.Save();
        end;

        _Steps.SetMustCallCreateNext(true);
        MobWmsPackLookup.OnPostAdhocRegistrationOnPackagesToShip_OnAddStepsToLicensePlate(_RequestValues, _Steps);
        _Steps.SetMustCallCreateNext(false);

        if _Steps.FindSet() then
            repeat
                MobWmsPackLookup.OnPostAdhocRegistrationOnPackagesToShip_OnAfterAddStepToLicensePlate(_RequestValues, _Steps);
            until _Steps.Next() = 0;

        // Hidden Step to mark second group of Steps has been activated
        // (avoid asking if the steps above HasValue, since each step may or may not be included)
        if not _Steps.IsEmpty() then begin
            _Steps.Create_TextStep(1000, 'ExtraSteps', 'ExtraSteps');
            _Steps.Set_visible(false);
            _Steps.Save();
        end;
    end;
}
