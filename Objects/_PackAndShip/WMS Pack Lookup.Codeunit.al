codeunit 82239 "MOB WMS Pack Lookup"
{
    Access = Public;
    //
    // Lookup 'PackagesToShipLookup' (incl. eventsubscribers incl. eventpublishers)
    // Lookup 'LicensePlateContentLookup (obsolete eventpublishers)
    // Post 'PackagesToShipLookup' (incl. eventsubscribers incl. eventpublishers)
    // 

    EventSubscriberInstance = Manual;

    //
    // ReferenceData
    //

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Reference Data", 'OnGetReferenceData_OnAddHeaderConfigurations', '', true, true)]
    local procedure OnGetReferenceData_OnAddHeaderConfigurations(var _HeaderFields: Record "MOB HeaderField Element")
    var
        MobPackFeatureMgt: Codeunit "MOB Pack Feature Management";
    begin
        if not MobPackFeatureMgt.IsEnabled() then
            exit;

        // Add Header for License Plates per Shipment lookup        
        _HeaderFields.InitConfigurationKey_PackagesToShipHeader();
        _HeaderFields.Create_TextField_ShipmentNo(10);
    end;

    //
    // Lookup
    //

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Lookup", 'OnLookupOnCustomLookupType', '', true, true)]
    local procedure LicensePlatesToShip_OnLookupOnCustomLookupType(_MessageId: Guid; _LookupType: Text; var _RequestValues: Record "MOB NS Request Element"; var _XmlResultDoc: XmlDocument; var _RegistrationTypeTracking: Text; var _IsHandled: Boolean)
    begin
        if _IsHandled then
            exit;

        if _LookupType = 'PackagesToShipLookup' then begin
            PackagesToShipLookup(_LookupType, _RequestValues, _XmlResultDoc);
            _IsHandled := true;
        end;
    end;

    //
    // PostAdhocRegistration
    //

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Adhoc Registr.", 'OnPostAdhocRegistration_OnAddSteps', '', true, true)]
    local procedure OnPostAdhocRegistration_OnAddSteps(_RegistrationType: Text; var _RequestValues: Record "MOB NS Request Element"; var _Steps: Record "MOB Steps Element"; var _RegistrationTypeTracking: Text)
    var
        ShippingAgentService: Record "Shipping Agent Services";
        WhseShipmentHeader: Record "Warehouse Shipment Header";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        MobPackMgt: Codeunit "MOB Pack Management";
        ShippingAgentCode: Code[10];
        BackendId: Code[20];
    begin
        if _RegistrationType <> 'PackagesToShipLookup' then
            exit;

        if _RequestValues.HasValue('ShippingAgentService') then
            exit;   // already collected, break to avoid adding the same new step indefinitely

        if _RequestValues.HasValue('LicensePlate') then
            exit;   // Wrong registration sequence, PackageType should only be present on License Plates

        Evaluate(BackendId, _RequestValues.GetValue('BackendID'));
        ShippingAgentCode := _RequestValues.GetValue('ShippingAgent', true); // mandatory        

        ShippingAgentService.SetRange("Shipping Agent Code", ShippingAgentCode);
        if ShippingAgentService.IsEmpty() then
            exit;

        // Add the new step        
        _Steps.Create_ListStep(100, 'ShippingAgentService');
        _Steps.Set_header(WhseShipmentHeader.FieldCaption("Shipping Agent Service Code"));
        _Steps.Set_listValues(MobPackMgt.GetShippingAgentServicesAsListValues(ShippingAgentCode));
        _Steps.Set_helpLabel(MobWmsLanguage.GetMessage('SHIPPING_AGENT_SERVICE_HELP'));
        _Steps.Set_optional(true);

        if WhseShipmentHeader.Get(BackendId) then
            _Steps.Set_defaultValue(WhseShipmentHeader."Shipping Agent Service Code");
        _Steps.Save();
    end;

    /// <summary>
    /// Handle Add Extra Steps to Packages
    /// </summary>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Adhoc Registr.", 'OnPostAdhocRegistration_OnAddSteps', '', true, true)]
    local procedure OnPostAdhocRegistration_OnAddStepsToPackage(_RegistrationType: Text; var _RequestValues: Record "MOB NS Request Element"; var _Steps: Record "MOB Steps Element"; var _RegistrationTypeTracking: Text)
    var
        MobPackManagement: Codeunit "MOB Pack Management";
    begin

        if _RegistrationType <> 'PackagesToShipLookup' then
            exit;

        // Break if our step is already collected to prevent infinite loop
        if _RequestValues.HasValue('ExtraSteps') then
            exit;

        MobPackManagement.AddPackageInfoLastSteps(_Steps, _RequestValues);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Adhoc Registr.", 'OnPostAdhocRegistration_OnAddSteps', '', true, true)]
    local procedure OnPostAdhocRegistration_OnAddStepsForPackingStation(_RegistrationType: Text; var _RequestValues: Record "MOB NS Request Element"; var _Steps: Record "MOB Steps Element"; var _RegistrationTypeTracking: Text)
    var
        WhseShipmentHeader: Record "Warehouse Shipment Header";
        MobPackingStation: Record "MOB Packing Station";
        MobPackingStationMgt: Codeunit "MOB Packing Station Management";
        WhseShipHeaderRecordId: RecordId;
        LocationFilterTxt: Text;
        PackingStationListAsTxt: Text;
    begin
        if _RegistrationType <> 'PackagesToShipLookup' then
            exit;

        if _RequestValues.HasValue('PackingStation') then
            exit;   // already collected, break to avoid adding the same new step indefinitely

        if _RequestValues.HasValue('LicensePlate') then
            exit;   // Wrong registration sequence, PackageType should only be present on License Plates        

        if MobPackingStation.IsEmpty() then
            exit;

        Evaluate(WhseShipHeaderRecordId, _RequestValues.GetValue('ReferenceID', true));
        WhseShipmentHeader.Get(WhseShipHeaderRecordId);

        // Apply filter on Location Code based on WhseActHeader and Stations without Location specified.
        LocationFilterTxt := StrSubstNo('%1|%2', WhseShipmentHeader."Location Code", '''''');
        MobPackingStation.SetFilter("Location Code", LocationFilterTxt);

        if MobPackingStation.FindSet() then begin
            repeat
                PackingStationListAsTxt += MobPackingStation.Code + ';';
            until MobPackingStation.Next() = 0;

            PackingStationListAsTxt := DelStr(PackingStationListAsTxt, StrLen(PackingStationListAsTxt), 1);

            MobPackingStationMgt.Create_ListStep_PackingStation(300, _Steps);
            _Steps.Set_listValues(PackingStationListAsTxt);

            // Set default Packing Station
            if WhseShipmentHeader."MOB Packing Station Code" <> '' then
                _Steps.Set_defaultValue(WhseShipmentHeader."MOB Packing Station Code");

            _Steps.Save();
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Adhoc Registr.", 'OnPostAdhocRegistrationOnCustomRegistrationType', '', true, true)]
    local procedure OnPostAdhocRegistrationOnCustomRegistrationType(_RegistrationType: Text; var _RequestValues: Record "MOB NS Request Element"; var _SuccessMessage: Text; var _IsHandled: Boolean)
    begin
        if _IsHandled then
            exit;

        if _RegistrationType = 'PackagesToShipLookup' then begin
            _SuccessMessage := UpdateLicensePlateFromSteps(_RegistrationType, _RequestValues);
            _IsHandled := true;
        end;
    end;

    //
    // Lookup 'PackagesToShipLookup'
    //

    local procedure PackagesToShipLookup(_LookupType: Text; var _RequestValues: Record "MOB NS Request Element"; var _XmlResultDoc: XmlDocument)
    var
        TempLookupResponseElement: Record "MOB NS WhseInquery Element" temporary;
        MobToolbox: Codeunit "MOB Toolbox";
        MobXmlMgt: Codeunit "MOB XML Management";
        MobWmsLookup: Codeunit "MOB WMS Lookup";
        XmlResponseData: XmlNode;
        BackendId: Code[20];
    begin
        Evaluate(BackendId, _RequestValues.GetValue('BackendID'));

        // Initialize the response xml
        MobToolbox.InitializeResponseDocWithNS(_XmlResultDoc, XmlResponseData, CopyStr(MobXmlMgt.NS_WHSEMODEL(), 1, 1024));

        CreateLicensePlatesToShipResponse(BackendId, '', TempLookupResponseElement);

        MobWmsLookup.AddLookupResponseElements(_LookupType, XmlResponseData, TempLookupResponseElement);
    end;

    local procedure CreateLicensePlatesToShipResponse(_WhseShipmentNo: Code[20]; _LicensePlateNo: Code[20]; var _LookupResponse: Record "MOB NS WhseInquery Element")
    var
        WhseShipmentHeader: Record "Warehouse Shipment Header";
        MobLicensePlate: Record "MOB License Plate";
        MobLicensePlateContent: Record "MOB License Plate Content";
        LicensePlateInput: Record "MOB License Plate";
        IncludeInOrderLines: Boolean;
    begin

        if _LicensePlateNo <> '' then begin
            LicensePlateInput.Get(_LicensePlateNo);
            if _WhseShipmentNo = '' then
                _WhseShipmentNo := LicensePlateInput."Whse. Document No.";
        end;

        if not WhseShipmentHeader.Get(_WhseShipmentNo) then
            exit;

        // Filter the lines for this particular order
        MobLicensePlate.SetRange("Whse. Document Type", MobLicensePlate."Whse. Document Type"::Shipment);
        MobLicensePlate.SetRange("Whse. Document No.", _WhseShipmentNo);
        MobLicensePlate.SetRange("Transferred to Shipping", false);

        // Insert the values from the header in the XML
        if MobLicensePlate.FindSet() then begin

            // Add License Plate Info Element
            _LookupResponse.Create();
            SetFromWarehouseShipmentHeader(WhseShipmentHeader, _LookupResponse);
            _LookupResponse.Save();

            repeat
                // Verify addtional conditions from eventsubscribers
                IncludeInOrderLines := true;

                // If Current License Plate is part of other License Plate, then exclude form list to show
                MobLicensePlateContent.SetRange(Type, MobLicensePlateContent.Type::"License Plate");
                MobLicensePlateContent.SetRange("No.", MobLicensePlate."No.");
                if not MobLicensePlateContent.IsEmpty() then
                    IncludeInOrderLines := false;

                if IncludeInOrderLines then begin

                    // Set values for the <BaseOrderLine>-element and save to buffer
                    _LookupResponse.Create();
                    SetFromLicensePlate(MobLicensePlate, _LookupResponse);
                    _LookupResponse.Save();

                end; // IncludeInOrderLines

            until MobLicensePlate.Next() = 0;
        end;
    end;

    local procedure SetFromWarehouseShipmentHeader(_WhseShipmentHeader: Record "Warehouse Shipment Header"; var _LookupResponse: Record "MOB NS WhseInquery Element")
    var
        TempSteps: Record "MOB Steps Element" temporary;
        WhseShipmentLine: Record "Warehouse Shipment Line";
        MobSetup: Record "MOB Setup";
        MobPackingStation: Record "MOB Packing Station";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
        MobToolbox: Codeunit "MOB Toolbox";
        MobWmsShip: Codeunit "MOB WMS Ship";
        MobPackMgt: Codeunit "MOB Pack Management";
        MobWmsPack: Codeunit "MOB WMS Pack";
        DisplayLine2To9List: List of [Text];
    begin
        MobSetup.Get();
        _LookupResponse.Set_LookupType('PackagesToShipLookup');
        _LookupResponse.Set_ReferenceID(_WhseShipmentHeader);

        // Add reference to specific Source Document - in this case assume all Whse. Shipment Lines are for same Source Doc.                        
        WhseShipmentLine.SetRange("No.", _WhseShipmentHeader."No.");
        if WhseShipmentLine.FindFirst() then
            _LookupResponse.SetValue('SourceReferenceID', MobWmsToolbox.GetSourceReferenceIDFromWhseShipmentLine(WhseShipmentLine));

        // Add Location to enable filtering by "MOB Printer"."Location Filter"
        _LookupResponse.Set_Location(_WhseShipmentHeader."Location Code");

        if MobSetup."Pick Collect Packing Station" then begin
            if (_WhseShipmentHeader."Shipping Agent Code" = '') or (_WhseShipmentHeader."MOB Packing Station Code" = '') then
                _LookupResponse.Set_ItemImageID('mainmenushipping')
            else
                _LookupResponse.Set_ItemImageID('shipcompleted');

        end else
            if _WhseShipmentHeader."Shipping Agent Code" = '' then
                _LookupResponse.Set_ItemImageID('mainmenushipping')
            else
                _LookupResponse.Set_ItemImageID('shipcompleted');

        // Descide what to show on the lines
        _LookupResponse.Set_DisplayLine1(_WhseShipmentHeader."No." + ' (' + MobWmsToolbox.Date2TextAsDisplayFormat(_WhseShipmentHeader."Shipment Date") + ')');

        if _WhseShipmentHeader."MOB Packing Station Code" <> '' then begin
            MobPackingStation.Get(_WhseShipmentHeader."MOB Packing Station Code");
            _LookupResponse.Set_DisplayLine2(MobPackingStation.TableCaption() + ': ' + MobPackingStation.Description);
        end;

        _LookupResponse.Set_DisplayLine3(MobWmsPack.GetReceiver(_WhseShipmentHeader."No."));
        _LookupResponse.Set_DisplayLine4(MobWmsShip.GetSourceTypeNo(_WhseShipmentHeader."No.", 3));

        if _WhseShipmentHeader."Shipping Agent Code" <> '' then
            _LookupResponse.Set_DisplayLine5(_WhseShipmentHeader.FieldCaption("Shipping Agent Code") + ': ' + _LookupResponse.Get_DisplayLine5() + _WhseShipmentHeader."Shipping Agent Code");

        if _WhseShipmentHeader."Shipping Agent Service Code" <> '' then
            _LookupResponse.Set_DisplayLine5(_LookupResponse.Get_DisplayLine5() + ' | ' + _WhseShipmentHeader."Shipping Agent Service Code");

        // Only show Document status if Whse shipment. contains ATO Lines and is not completely picked
        if not _WhseShipmentHeader."MOB CompletelyPicked"() then
            _LookupResponse.Set_DisplayLine5(_LookupResponse.Get_DisplayLine5() + MobToolbox.CRLFSeparator() + MobWmsLanguage.GetMessage('SHIPMENT_DOCUMENT_STATUS_PARTIALLY_PICKED'))
        else
            _LookupResponse.Set_DisplayLine5(_LookupResponse.Get_DisplayLine5() + MobToolbox.CRLFSeparator() + MobWmsLanguage.GetMessage('SHIPMENT_DOCUMENT_STATUS_COMPLETELY_PICKED'));

        // Set default value for Packing Station
        if _WhseShipmentHeader."MOB Packing Station Code" <> '' then
            _LookupResponse.SetValue('DefaultPackingStationCode', _WhseShipmentHeader."MOB Packing Station Code");

        TempSteps.Create_TextStep(10, 'ReferenceID');
        TempSteps.Set_defaultValue(_WhseShipmentHeader."No.");
        TempSteps.Set_visible(false);
        TempSteps.Save();

        TempSteps.Create_ListStep(20, 'ShippingAgent');
        TempSteps.Set_header('Shipping Agent');
        TempSteps.Set_listValues(MobPackMgt.GetShippingAgentsAsListValues());
        TempSteps.Set_defaultValue(_WhseShipmentHeader."Shipping Agent Code");
        TempSteps.Set_optional(true);
        TempSteps.Set_helpLabel(MobWmsLanguage.GetMessage('SHIPPING_AGENT_HELP'));
        TempSteps.Save();

        TempSteps.SetMustCallCreateNext(true);
        OnLookupOnPackagesToShip_OnAddStepsToWarehouseShipmentHeader(_LookupResponse, _WhseShipmentHeader, TempSteps);
        TempSteps.SetMustCallCreateNext(false);
        if TempSteps.FindSet() then
            repeat
                OnLookupOnPackagesToShip_OnAfterAddStepToWarehouseShipmentHeader(_WhseShipmentHeader, TempSteps);
            until TempSteps.Next() = 0;

        // -- Add step        
        _LookupResponse.SetRegistrationCollector(TempSteps);

        OnLookupOnPackagesToShip_OnAfterSetFromWarehouseShipmentHeader(_WhseShipmentHeader, _LookupResponse);

        // Compressed display lines 2 to 9 (after integration events to change display lines)
        _LookupResponse.GetDisplayLinesAsList(DisplayLine2To9List, 2, 9);
        MobWmsToolbox.ListTrimBlank(DisplayLine2To9List, 2);
        _LookupResponse.SetValue('CompressedDisplayLine2To9', MobWmsToolbox.List2TextLn(DisplayLine2To9List, 999));
    end;

    local procedure SetFromLicensePlate(_LicensePlate: Record "MOB License Plate"; var _LookupResponse: Record "MOB NS WhseInquery Element")
    var
        WhseShipmentHeader: Record "Warehouse Shipment Header";
        MobSetup: Record "MOB Setup";
        MobPackingStation: Record "MOB Packing Station";
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        DisplayLine2To9List: List of [Text];
        ExtraInfo1_Col1: List of [Text];
        ExtraInfo1_Col2: List of [Text];
        StagingHintTxt: Text;
    begin
        if not WhseShipmentHeader.Get(_LicensePlate."Whse. Document No.") then
            exit;

        MobSetup.Get();
        _LookupResponse.Set_LookupType('PackagesToShipLookup');
        _LookupResponse.Set_ReferenceID(WhseShipmentHeader);
        _LookupResponse.SetValue('LookupId', _LicensePlate."No.");
        _LookupResponse.SetValue('SourceReferenceID', _LicensePlate.GetSourceReferenceID());

        // Add Location to enable filtering by "MOB Printer"."Location Filter"
        if _LicensePlate."Location Code" <> '' then
            _LookupResponse.Set_Location(_LicensePlate."Location Code")
        else
            if WhseShipmentHeader."Location Code" <> '' then
                _LookupResponse.Set_Location(WhseShipmentHeader."Location Code");

        // Add Packing Station to enable filtering by "Packing Station Filter"
        if _LicensePlate."Packing Station Code" <> '' then
            _LookupResponse.SetValue('PackingStation', _LicensePlate."Packing Station Code")
        else
            _LookupResponse.SetValue('PackingStation', WhseShipmentHeader."MOB Packing Station Code"); // Use Packing Station from Whse. Shipment Header if available

        // Add value in NoSeriesValue to use predefined No. instead of Next Numberseries Value
        _LookupResponse.SetValue('NoSeriesValue', _LicensePlate."No.");

        _LookupResponse.SetValue('LicensePlate', _LicensePlate."No.");

        _LicensePlate.CalcFields("Content Exists");
        if _LicensePlate."Content Exists" then
            _LookupResponse.Set_DisplayLine1(_LicensePlate."No.")
        else
            _LookupResponse.Set_DisplayLine1(_LicensePlate."No." + ' (' + MobWmsLanguage.GetMessage('EMPTY') + ')');

        if _LicensePlate."Package Type" <> '' then
            _LookupResponse.Set_DisplayLine2(StrSubstNo('Type: %1', _LicensePlate."Package Type"));

        // Check if Required Package Info for Shipping Agent is filled on License Plate
        // and Show Icon to Visually Mark line as Ready
        if _LicensePlate."Shipping Status" = _LicensePlate."Shipping Status"::Ready then
            _LookupResponse.Set_ItemImageID('postsuccess') // OK            
        else
            _LookupResponse.Set_ItemImageID('postready'); // Not OK            

        if _LicensePlate.Weight <> 0 then
            _LookupResponse.Set_DisplayLine3(StrSubstNo('%1 %2', _LicensePlate.Weight, MobSetup."Weight Unit"));

        if _LicensePlate."Loading Meter" <> 0 then
            _LookupResponse.Set_DisplayLine3(_LookupResponse.Get_DisplayLine3() + StrSubstNo(' / %1 %2', _LicensePlate."Loading Meter", MobWmsLanguage.GetMessage('LOAD_METER_LABEL')));

        if (_LicensePlate.Length <> 0) or (_LicensePlate.Width <> 0) or (_LicensePlate.Height <> 0) then
            _LookupResponse.Set_DisplayLine4(StrSubstNo('%1 x %2 x %3 %4', _LicensePlate.Length, _LicensePlate.Width, _LicensePlate.Height, MobSetup."Dimensions Unit"));

        if (_LicensePlate."Staging Hint" <> '') or (_LicensePlate."Packing Station Code" <> '') then begin
            StagingHintTxt := MobWmsLanguage.GetMessage('STAGING_HINT') + ': ';

            if MobPackingStation.Get(_LicensePlate."Packing Station Code") then
                StagingHintTxt += MobPackingStation.Description + ', ';

            if _LicensePlate."Staging Hint" <> '' then
                StagingHintTxt += _LicensePlate."Staging Hint";

            //_LookupResponseElement.Set_DisplayLine5(StagingHintTxt);
            ExtraInfo1_Col1.Add(StagingHintTxt);
        end;

        //Set Comment to display
        if _LicensePlate.Comment <> '' then
            ExtraInfo1_Col1.Add(MobWmsLanguage.GetMessage('LICENSEPLATE_COMMENT') + ': ' + _LicensePlate.Comment);

        // Set License Plate No. to enable Line Scan in Lookup List
        _LookupResponse.Set_Barcode(_LicensePlate."No.");

        _LicensePlate.CalcFields("Content Quantity (Base)", "Sub License Plate Qty.");

        if _LicensePlate."Sub License Plate Qty." <> 0 then
            ExtraInfo1_Col1.Add(MobWmsLanguage.GetMessage('PACKAGE_QTY') + StrSubstNo(': %1', _LicensePlate."Sub License Plate Qty."));

        if _LicensePlate."Content Quantity (Base)" <> 0 then
            ExtraInfo1_Col1.Add(MobWmsLanguage.GetMessage('ITEM_QTY') + StrSubstNo(': %1', _LicensePlate."Content Quantity (Base)"));

        _LookupResponse.SetValue('ExtraInfo1_Col1', MobWmsToolbox.List2TextLn(ExtraInfo1_Col1, 999));
        _LookupResponse.SetValue('ExtraInfo1_Col2', MobWmsToolbox.List2TextLn(ExtraInfo1_Col2, 999));

        // Create and add Steps based on Shipping Agent
        AddStepsToLicensePlate(_LookupResponse, _LicensePlate);

        OnLookupOnPackagesToShip_OnAfterSetFromLicensePlate(_LicensePlate, _LookupResponse);

        // Compressed display lines 2 to 9 (after integration events to change display lines)
        _LookupResponse.GetDisplayLinesAsList(DisplayLine2To9List, 2, 9);
        MobWmsToolbox.ListTrimBlank(DisplayLine2To9List, 2);
        _LookupResponse.SetValue('CompressedDisplayLine2To9', MobWmsToolbox.List2TextLn(DisplayLine2To9List, 999));
    end;

    local procedure AddStepsToLicensePlate(var _LookupResponse: Record "MOB NS WhseInquery Element"; _LicensePlate: Record "MOB License Plate")
    var
        WhseShipmentHeader: Record "Warehouse Shipment Header";
        TempSteps: Record "MOB Steps Element" temporary;
        MobPackManagement: Codeunit "MOB Pack Management";
    begin
        if not WhseShipmentHeader.Get(_LicensePlate."Whse. Document No.") then
            exit;

        if WhseShipmentHeader."Shipping Agent Code" = '' then
            exit;

        TempSteps.Create_TextStep(10, 'LicensePlate');
        TempSteps.Set_defaultValue(_LicensePlate."No.");
        TempSteps.Set_visible(false);
        TempSteps.Save();

        // Add Additional Steps based on Shipping Agent
        MobPackManagement.AddPackageInfoSteps(TempSteps, WhseShipmentHeader."Shipping Agent Code", WhseShipmentHeader."Shipping Agent Service Code", _LicensePlate."No.");

        TempSteps.SetMustCallCreateNext(true);
        OnLookupOnPackagesToShip_OnAddStepsToLicensePlate(_LookupResponse, _LicensePlate, TempSteps);
        TempSteps.SetMustCallCreateNext(false);
        if TempSteps.FindSet() then
            repeat
                OnLookupOnPackagesToShip_OnAfterAddStepToLicensePlate(_LicensePlate, TempSteps);
            until TempSteps.Next() = 0;
        _LookupResponse.SetRegistrationCollector(TempSteps);
    end;

    //
    // PostAdhocRegistration 'PackagesToShipLookup'
    //

    procedure UpdateLicensePlateFromSteps(_RegistrationType: Text; var _RequestValues: Record "MOB NS Request Element"): Text
    var
        WhseShipmentHeader: Record "Warehouse Shipment Header";
        MobPackageSetup: Record "MOB Mobile WMS Package Setup";
        MobLicensePlate: Record "MOB License Plate";
        WhseShipmentHeaderRecordId: RecordId;
        LicensePlateNo: Text;
        Weight: Decimal;
        Width: Decimal;
        Length: Decimal;
        Height: Decimal;
        LoadMeter: Decimal;
        PackageType: Code[100];
        ShippingAgentCode: Code[10];
        ShippingAgentServiceCode: Code[10];
        PackingStationCode: Code[20];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnPostAdhocRegistrationOnPackagesToShip_OnBeforeUpdateLicensePlate(_RequestValues, IsHandled);

        if IsHandled then
            exit;

        PackageType := _RequestValues.GetValue('PackageType');
        Weight := _RequestValues.GetValueAsDecimal('Weight');
        Width := _RequestValues.GetValueAsDecimal('Width');
        Height := _RequestValues.GetValueAsDecimal('Height');
        Length := _RequestValues.GetValueAsDecimal('Length');
        LoadMeter := _RequestValues.GetValueAsDecimal('LoadMeter');

        LicensePlateNo := _RequestValues.GetValue('LicensePlate');
        Evaluate(WhseShipmentHeaderRecordId, _RequestValues.GetContextValue('ReferenceID', true));

        ShippingAgentCode := _RequestValues.GetValue('ShippingAgent');
        ShippingAgentServiceCode := _RequestValues.GetValue('ShippingAgentService');
        PackingStationCode := _RequestValues.GetValue('PackingStation');

        // Handle update of License Plate
        if not MobPackageSetup.IsEmpty() then
            if LicensePlateNo <> '' then begin
                MobLicensePlate.Get(LicensePlateNo);
                MobLicensePlate.Validate("Package Type", PackageType);  // Will Apply Defualt Values from Package Type                

                if Weight <> 0 then
                    MobLicensePlate.Weight := Weight;
                if Width <> 0 then
                    MobLicensePlate.Width := Width;
                if Height <> 0 then
                    MobLicensePlate.Height := Height;
                if Length <> 0 then
                    MobLicensePlate.Length := Length;
                if LoadMeter <> 0 then
                    MobLicensePlate."Loading Meter" := LoadMeter;
            end;

        // Handle update of Warehouse Activity Header
        if (LicensePlateNo = '') and (WhseShipmentHeaderRecordId.TableNo() <> 0) then begin
            if not WhseShipmentHeader.Get(WhseShipmentHeaderRecordId) then
                exit;
            WhseShipmentHeader.Validate("Shipping Agent Code", ShippingAgentCode);
            WhseShipmentHeader.Validate("Shipping Agent Service Code", ShippingAgentServiceCode);
            WhseShipmentHeader.Validate("MOB Packing Station Code", PackingStationCode);
            WhseShipmentHeader.Modify(false);

            UpdateLicensePlateFromShippingAgentPackageTypes(WhseShipmentHeader);
        end;

        OnPostAdhocRegistrationOnPackagesToShip_OnAfterUpdateLicensePlate(MobLicensePlate, _RequestValues);

        if MobLicensePlate."No." <> '' then
            MobLicensePlate.Modify(true);
    end;

    local procedure UpdateLicensePlateFromShippingAgentPackageTypes(_WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    var
        MobPackageSetup: Record "MOB Mobile WMS Package Setup";
        MobLicensePlate: Record "MOB License Plate";
    begin
        //Update License Plate values if Shipping Agents has changed
        MobLicensePlate.SetRange("Whse. Document Type", MobLicensePlate."Whse. Document Type"::Shipment);
        MobLicensePlate.SetRange("Whse. Document No.", _WarehouseShipmentHeader."No.");
        MobLicensePlate.SetRange("Transferred to Shipping", false);
        MobLicensePlate.SetRange("Top-level", true);
        MobLicensePlate.SetFilter("Package Type", '<>%1', '');
        if MobLicensePlate.FindSet(true) then
            repeat
                MobPackageSetup.SetRange("Shipping Agent", _WarehouseShipmentHeader."Shipping Agent Code");
                MobPackageSetup.SetFilter("Shipping Agent Service Code", '%1|%2', _WarehouseShipmentHeader."Shipping Agent Service Code", '');
                MobPackageSetup.SetRange("Package Type", MobLicensePlate."Package Type");
                if MobPackageSetup.FindLast() then begin
                    if not MobPackageSetup."Register Weight" then
                        Clear(MobLicensePlate.Weight);
                    if not MobPackageSetup."Register Width" then
                        Clear(MobLicensePlate.Width);
                    if not MobPackageSetup."Register Height" then
                        Clear(MobLicensePlate.Height);
                    if not MobPackageSetup."Register Length" then
                        Clear(MobLicensePlate.Length);
                    if not MobPackageSetup."Register Loading Meter" then
                        Clear(MobLicensePlate."Loading Meter");
                end else begin
                    Clear(MobPackageSetup); // Prepare for Event
                    Clear(MobLicensePlate."Package Type");
                    Clear(MobLicensePlate.Weight);
                    Clear(MobLicensePlate.Width);
                    Clear(MobLicensePlate.Height);
                    Clear(MobLicensePlate.Length);
                    Clear(MobLicensePlate."Loading Meter");
                end;

                OnPostAdhocRegistrationOnPackagesToShip_OnUpdateLicensePlateFromPackageSetup(MobLicensePlate, MobPackageSetup);
                MobLicensePlate.Modify(true);
            until MobLicensePlate.Next() = 0;
    end;

    //
    // Obsolete IntegrationEvents
    //

    // TODO [Obsolete('Use "MOB WMS LicensePlateContLookup".OnLookupOnLicensePlateContent_OnAfterSetFromLicensePlateContent instead  (planned for removed 04/2024)', 'MOB5.41')]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS LicensePlateContLookup", 'OnLookupOnLicensePlateContent_OnAfterSetFromLicensePlateContent', '', true, true)]
    [IntegrationEvent(false, false)]
    local procedure OnLookupOnLicensePlateContent_OnAfterSetFromLicensePlateContent(_LicensePlateContent: Record "MOB License Plate Content"; var _LookupResponseElement: Record "MOB NS WhseInquery Element")
    begin
    end;

    // TODO [Obsolete('Use "MOB WMS LicensePlateContLookup".OnLookupOnLicensePlateContent_OnAddSteps instead  (planned for removed 04/2024)', 'MOB5.41')]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS LicensePlateContLookup", 'OnLookupOnLicensePlateContent_OnAddSteps', '', true, true)]
    [IntegrationEvent(false, false)]
    local procedure OnLookupOnLicensePlateContent_OnAddSteps(var _LookupResponseElement: Record "MOB NS WhseInquery Element"; _LicensePlateContent: Record "MOB License Plate Content"; var _Steps: Record "MOB Steps Element")
    begin
    end;

    // TODO [Obsolete('Use "MOB WMS LicensePlateContLookup".OnLookupOnLicensePlateContent_OnAfterAddStep instead  (planned for removed 04/2024)', 'MOB5.41')]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS LicensePlateContLookup", 'OnLookupOnLicensePlateContent_OnAfterAddStep', '', true, true)]
    [IntegrationEvent(false, false)]
    local procedure OnLookupOnLicensePlateContent_OnAfterAddStep(_LicensePlateContent: Record "MOB License Plate Content"; var _Step: Record "MOB Steps Element")
    begin
    end;

    //
    // IntegrationEvents
    //

    [IntegrationEvent(false, false)]
    local procedure OnLookupOnPackagesToShip_OnAfterSetFromWarehouseShipmentHeader(_WhseShipmentHeader: Record "Warehouse Shipment Header"; var _LookupResponseElement: Record "MOB NS WhseInquery Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupOnPackagesToShip_OnAfterSetFromLicensePlate(_LicensePlate: Record "MOB License Plate"; var _LookupResponseElement: Record "MOB NS WhseInquery Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupOnPackagesToShip_OnAddStepsToWarehouseShipmentHeader(var _LookupResponse: Record "MOB NS WhseInquery Element"; _WhseShipmentHeader: Record "Warehouse Shipment Header"; var _Steps: Record "MOB Steps Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupOnPackagesToShip_OnAfterAddStepToWarehouseShipmentHeader(_WhseShipmentHeader: Record "Warehouse Shipment Header"; var _Step: Record "MOB Steps Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupOnPackagesToShip_OnAddStepsToLicensePlate(var _LookupResponseElement: Record "MOB NS WhseInquery Element"; _LicensePlate: Record "MOB License Plate"; var _Steps: Record "MOB Steps Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupOnPackagesToShip_OnAfterAddStepToLicensePlate(_LicensePlate: Record "MOB License Plate"; var _Step: Record "MOB Steps Element")
    begin
    end;

    // 'PackagesToShipLookup' and 'BulkRegPackageInfo' (called from MOB Pack Management)
    [IntegrationEvent(false, false)]
    internal procedure OnPostAdhocRegistrationOnPackagesToShip_OnAddStepsToLicensePlate(var _RequestValues: Record "MOB NS Request Element"; var _Steps: Record "MOB Steps Element")
    begin
    end;

    // 'PackagesToShipLookup' and 'BulkRegPackageInfo'  (called from MOB Pack Management)
    [IntegrationEvent(false, false)]
    internal procedure OnPostAdhocRegistrationOnPackagesToShip_OnAfterAddStepToLicensePlate(var _RequestValues: Record "MOB NS Request Element"; var _Step: Record "MOB Steps Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostAdhocRegistrationOnPackagesToShip_OnAfterUpdateLicensePlate(var _LicensePlate: Record "MOB License Plate"; var _RequestValues: Record "MOB NS Request Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostAdhocRegistrationOnPackagesToShip_OnUpdateLicensePlateFromPackageSetup(var _LicensePlate: Record "MOB License Plate"; _PackageSetup: Record "MOB Mobile WMS Package Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostAdhocRegistrationOnPackagesToShip_OnBeforeUpdateLicensePlate(var _RequestValues: Record "MOB NS Request Element"; var _IsHandled: Boolean)
    begin
    end;

}
