codeunit 82224 "MOB WMS LicensePlateContLookup"
{
    Access = Public;

    var
        MobPackFeatureMgt: Codeunit "MOB Pack Feature Management";
        Move_qtyErr: Label 'You cannot move more than %1 %2', Comment = '%1 contains Quantity, %2 contains Unit of Measure';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Reference Data", 'OnGetReferenceData_OnAddHeaderConfigurations', '', true, true)]
    local procedure OnGetReferenceData_OnAddHeaderConfigurations(var _HeaderFields: Record "MOB HeaderField Element")
    begin
        // TODO: Remove this check when all customers have migrated from Pack and Ship PTE
        if MobPackFeatureMgt.LegacyPackAndShipDetected() then
            exit;

        // Add Header for License Plate Content lookup
        AddHeaderConfiguration_LicensePlateContentHeader(_HeaderFields);
    end;

    local procedure AddHeaderConfiguration_LicensePlateContentHeader(var _HeaderConfiguration: Record "MOB HeaderField Element")
    var
        MobWmsLanguage: Codeunit "MOB WMS Language";
        MobToolbox: Codeunit "MOB Toolbox";
    begin
        _HeaderConfiguration.InitConfigurationKey('LicensePlateContentHeader');

        // Add the header lines                
        _HeaderConfiguration.Create_TextField_OrderBackendID(10, false);
        _HeaderConfiguration.Set_name('LicensePlate');
        _HeaderConfiguration.Set_label(MobWmsLanguage.GetMessage('LICENSEPLATE') + ':');
        _HeaderConfiguration.Set_eanAi(MobToolbox.GetLicensePlateNoGS1Ai());
        _HeaderConfiguration.Set_acceptBarcode(true);
        _HeaderConfiguration.Set_locked(false);
        _HeaderConfiguration.Save();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Lookup", 'OnLookupOnCustomLookupType', '', true, true)]
    local procedure LicensePlatesToShip_OnLookupOnCustomLookupType(_MessageId: Guid; _LookupType: Text; var _RequestValues: Record "MOB NS Request Element"; var _XmlResultDoc: XmlDocument; var _RegistrationTypeTracking: Text; var _IsHandled: Boolean)
    begin
        // TODO: Remove this check when all customers have migrated from Pack and Ship PTE
        if MobPackFeatureMgt.LegacyPackAndShipDetected() then
            exit;

        if _IsHandled then
            exit;

        if _LookupType = 'LicensePlateContentLookup' then begin
            LicensePlateContentLookup(_LookupType, _RequestValues, _XmlResultDoc);
            _IsHandled := true;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Adhoc Registr.", 'OnPostAdhocRegistrationOnCustomRegistrationType', '', true, true)]
    local procedure OnPostAdhocRegistrationOnCustomRegistrationType(_RegistrationType: Text; var _RequestValues: Record "MOB NS Request Element"; var _SuccessMessage: Text; var _IsHandled: Boolean)
    begin
        if not MobPackFeatureMgt.IsEnabled() then
            exit;

        if _IsHandled then
            exit;

        // Default behaviour in LicensePlateContentLookup page is moving a single license content to another license plate when element is scanned or selected
        if _RegistrationType = 'LicensePlateContentLookup' then begin
            _SuccessMessage := MoveSingleLicensePlateContent(_RegistrationType, _RequestValues);
            _IsHandled := true;
        end;
    end;

    local procedure LicensePlateContentLookup(_LookupType: Text; var _RequestValues: Record "MOB NS Request Element"; var _XmlResultDoc: XmlDocument)
    var
        TempLookupResponseElement: Record "MOB NS WhseInquery Element" temporary;
        MobToolbox: Codeunit "MOB Toolbox";
        MobXmlMgt: Codeunit "MOB XML Management";
        MobWmsLookup: Codeunit "MOB WMS Lookup";
        XmlResponseData: XmlNode;
        LicensePlateNo: Code[20];
    begin
        // Read Request
        Evaluate(LicensePlateNo, _RequestValues.GetValue('LicensePlate'));

        // Initialize the response xml
        MobToolbox.InitializeResponseDocWithNS(_XmlResultDoc, XmlResponseData, CopyStr(MobXmlMgt.NS_WHSEMODEL(), 1, 1024));

        CreateLicensePlateContentResponse(LicensePlateNo, TempLookupResponseElement);

        MobWmsLookup.AddLookupResponseElements(_LookupType, XmlResponseData, TempLookupResponseElement);
    end;

    local procedure CreateLicensePlateContentResponse(_LicensePlateNo: Code[20]; var _LookupResponseElement: Record "MOB NS WhseInquery Element")
    var
        MobLicensePlateContent: Record "MOB License Plate Content";
    begin
        // Filter the lines for this particular License Plate
        MobLicensePlateContent.SetRange("License Plate No.", _LicensePlateNo);

        if MobLicensePlateContent.FindSet() then
            repeat
                // Set values for the <BaseOrderLine>-element and save to buffer
                _LookupResponseElement.Create();
                SetFromLicensePlateContent(MobLicensePlateContent, _LookupResponseElement);
                _LookupResponseElement.Save();
            until MobLicensePlateContent.Next() = 0;
    end;

    local procedure SetFromLicensePlateContent(_LicensePlateContent: Record "MOB License Plate Content"; var _LookupResponse: Record "MOB NS WhseInquery Element")
    var
        MobTrackingSetup: Record "MOB Tracking Setup";
        WhseShipmentHeader: Record "Warehouse Shipment Header";
        MobLicensePlate: Record "MOB License Plate";
        MobItemReferenceMgt: Codeunit "MOB Item Reference Mgt.";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        MobWmsMedia: Codeunit "MOB WMS Media";
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
    begin
        _LookupResponse.SetValue('ParentLicensePlateNo', _LicensePlateContent."License Plate No.");
        _LookupResponse.SetValue('LineNo', Format(_LicensePlateContent."Line No."));
        _LookupResponse.SetValue('LookupId', _LicensePlateContent."License Plate No." + ':' + Format(_LicensePlateContent."Line No."));

        // Force print of label for current License Plate rather than pulling a next number from the number series (when the LabelTemplate."Number Series" is populated)
        _LookupResponse.SetValue('NoSeriesValue', _LicensePlateContent."License Plate No.");

        if _LicensePlateContent."Whse. Document Type" = _LicensePlateContent."Whse. Document Type"::Shipment then
            if WhseShipmentHeader.Get(_LicensePlateContent."Whse. Document No.") then
                _LookupResponse.Set_ReferenceID(WhseShipmentHeader);

        // Add Location to enable filtering by "MOB Printer"."Location Filter"
        MobLicensePlate.Get(_LicensePlateContent."License Plate No.");
        if MobLicensePlate."Location Code" <> '' then
            _LookupResponse.Set_Location(MobLicensePlate."Location Code")
        else
            if WhseShipmentHeader."Location Code" <> '' then
                _LookupResponse.Set_Location(WhseShipmentHeader."Location Code");

        // Add Packing Station to enable filtering by "Packing Station Filter"
        if MobLicensePlate."Packing Station Code" <> '' then
            _LookupResponse.SetValue('PackingStation', MobLicensePlate."Packing Station Code")
        else
            _LookupResponse.SetValue('PackingStation', WhseShipmentHeader."MOB Packing Station Code"); // Use Packing Station from Whse. Shipment Header if available

        // Add reference to specific Source Document - in this case assume all Whse. Shipment Lines are for same Source Doc.                        
        _LookupResponse.SetValue('SourceReferenceID', MobLicensePlate.GetSourceReferenceID());

        // Number represents either the Item No. or the License Plate No.
        _LookupResponse.Set_Number(_LicensePlateContent."No.");

        case _LicensePlateContent.Type of
            // Content of type ITEM
            _LicensePlateContent.Type::Item:
                begin
                    _LookupResponse.Set_Barcode(MobItemReferenceMgt.GetBarcodeList(_LicensePlateContent."No.", _LicensePlateContent."Variant Code", _LicensePlateContent."Unit Of Measure Code") + ';' + _LicensePlateContent."No.");  // Must be able to scan either Item Cross ref, GTIN, Item Variant or Item No.
                    _LookupResponse.Set_DisplayLine1(_LicensePlateContent."No.");
                    _LookupResponse.Set_DisplayLine2(MobWmsToolbox.GetItemDescriptions(_LicensePlateContent."No.", _LicensePlateContent."Variant Code"));
                    _LookupResponse.Set_Quantity(_LicensePlateContent.Quantity);

                    Clear(MobTrackingSetup);
                    _LicensePlateContent.CopyTrackingToMobTrackingSetup(MobTrackingSetup);
                    _LookupResponse.SetDisplayTracking(MobTrackingSetup);
                    _LookupResponse.SetTracking(MobTrackingSetup);

                    _LookupResponse.Set_ItemImageID(MobWmsMedia.GetItemImageID(_LicensePlateContent."No."));

                    _LookupResponse.Set_DisplayLine3(_LicensePlateContent."Variant Code" <> '',
                        MobWmsLanguage.GetMessage('VARIANT_LABEL') + ': ' + _LicensePlateContent."Variant Code", '');

                    _LookupResponse.Set_DisplayLine4(MobWmsLanguage.GetMessage('UOM_LABEL') + ': ' + _LicensePlateContent."Unit Of Measure Code");
                end;
            // Content of type License Plate
            _LicensePlateContent.Type::"License Plate":
                begin
                    _LookupResponse.Set_Barcode(_LicensePlateContent."No.");

                    MobLicensePlate.SetAutoCalcFields("Content Exists", "Content Quantity (Base)", "Sub License Plate Qty.");
                    if MobLicensePlate.Get(_LicensePlateContent."No.") then begin
                        if MobLicensePlate."Content Exists" then
                            _LookupResponse.Set_DisplayLine1(MobWmsLanguage.GetMessage('LICENSEPLATE') + ': ' + MobLicensePlate."No.")
                        else
                            _LookupResponse.Set_DisplayLine1(MobWmsLanguage.GetMessage('LICENSEPLATE') + ': ' + MobLicensePlate."No." + ' (' + MobWmsLanguage.GetMessage('EMPTY') + ')');

                        _LookupResponse.Set_DisplayLine2(StrSubstNo('%1', MobLicensePlate."Package Type"));
                        _LookupResponse.SetValue('LicensePlate', MobLicensePlate."No.");
                        _LookupResponse.Set_ItemImageID('');

                        if MobLicensePlate."Sub License Plate Qty." <> 0 then
                            _LookupResponse.Set_DisplayLine3(MobWmsLanguage.GetMessage('PACKAGE_QTY') + StrSubstNo(': %1', MobLicensePlate."Sub License Plate Qty."));

                        if MobLicensePlate."Content Quantity (Base)" <> 0 then
                            _LookupResponse.Set_DisplayLine4(MobWmsLanguage.GetMessage('ITEM_QTY') + StrSubstNo(': %1', MobLicensePlate."Content Quantity (Base)"));
                    end;
                end;
        end;

        // For LP related to a Shipment (used by Pack) we add steps to move the content to another LP
        if MobLicensePlate."Whse. Document Type" = MobLicensePlate."Whse. Document Type"::Shipment then
            AddStepsToLicensePlateContent(_LookupResponse, _LicensePlateContent);

        OnLookupOnLicensePlateContent_OnAfterSetFromLicensePlateContent(_LicensePlateContent, _LookupResponse);
    end;

    local procedure AddStepsToLicensePlateContent(var _LookupResponse: Record "MOB NS WhseInquery Element"; _LicensePlateContent: Record "MOB License Plate Content")
    var
        TempSteps: Record "MOB Steps Element" temporary;
        MobWmsLanguage: Codeunit "MOB WMS Language";
        MobLicensePlateMgt: Codeunit "MOB License Plate Mgt";
        MobToolbox: Codeunit "MOB Toolbox";
    begin
        TempSteps.Create_ListStep(10, 'ToLicensePlate');
        TempSteps.Set_eanAi(MobToolbox.GetLicensePlateNoGS1Ai());
        TempSteps.Set_header(MobWmsLanguage.GetMessage('TO_LICENSEPLATE'));
        TempSteps.Set_helpLabel(MobWmsLanguage.GetMessage('TO_LICENSEPLATE_HELP'));

        if _LicensePlateContent.Type = _LicensePlateContent.Type::Item then
            TempSteps.Set_listValues(MobLicensePlateMgt.GetLicensePlatesAsListValues(_LicensePlateContent))
        else
            TempSteps.Set_listValues(MobLicensePlateMgt.GetLicensePlatesAsListValues(_LicensePlateContent) + ';' + MobWmsLanguage.GetMessage('TOP_LEVEL'));


        TempSteps.Save();

        if _LicensePlateContent.Type = _LicensePlateContent.Type::Item then begin
            TempSteps.Create_DecimalStep_Quantity(20, _LicensePlateContent."No.");
            TempSteps.Set_defaultValue(_LicensePlateContent.Quantity);
            TempSteps.Set_minValue(1);
            TempSteps.Set_maxValue(_LicensePlateContent.Quantity);
        end;

        TempSteps.SetMustCallCreateNext(true);
        OnLookupOnLicensePlateContent_OnAddSteps(_LookupResponse, _LicensePlateContent, TempSteps);
        TempSteps.SetMustCallCreateNext(false);
        if TempSteps.FindSet() then
            repeat
                OnLookupOnLicensePlateContent_OnAfterAddStep(_LicensePlateContent, TempSteps);
            until TempSteps.Next() = 0;

        _LookupResponse.SetRegistrationCollector(TempSteps);
    end;

    /// <summary>
    /// Move a License Plate content line (an item, or a License Plate including all its contents) to a new license plate or unbind the License Plate (promoting it to a top-level license plate).
    /// Items cannot be unbound in the current version, but must stay associated to a license plate always.
    /// </summary>    
    local procedure MoveSingleLicensePlateContent(_RegistrationType: Text; var _RequestValues: Record "MOB NS Request Element"): Text
    var
        MobLicensePlate: Record "MOB License Plate";
        ToLicensePlate: Record "MOB License Plate";
        MobLicensePlateContent: Record "MOB License Plate Content";
        NewLicensePlateContent: Record "MOB License Plate Content";
        MobSessionData: Codeunit "MOB SessionData";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        MobLicensePlateMgt: Codeunit "MOB License Plate Mgt";
        ParentLicensePlateNo: Text;
        ToLicensePlateNo: Text;
        LineNo: Integer;
        QtyToMove: Decimal;
    begin
        if _RegistrationType <> 'LicensePlateContentLookup' then
            exit;

        Evaluate(ParentLicensePlateNo, _RequestValues.GetValue('ParentLicensePlateNo', true));
        Evaluate(LineNo, _RequestValues.GetValue('LineNo', true));
        Evaluate(ToLicensePlateNo, _RequestValues.GetValue('ToLicensePlate', true));
        QtyToMove := _RequestValues.Get_Quantity();

        MobSessionData.SetRegistrationTypeTracking(StrSubstNo('%1.%2 - %3', ParentLicensePlateNo, LineNo, ToLicensePlateNo));

        if ToLicensePlateNo = MobWmsLanguage.GetMessage('TOP_LEVEL') then begin  // Meaning you want to move LP from being a Content to a top-level LP on the Packing.
            Evaluate(ParentLicensePlateNo, _RequestValues.GetValue('ParentLicensePlateNo', true));
            Evaluate(LineNo, _RequestValues.GetValue('LineNo', true));

            MobLicensePlateContent.Get(ParentLicensePlateNo, LineNo);
            MobLicensePlateContent.TestField(Type, MobLicensePlateContent.Type::"License Plate");
            MobLicensePlateContent.Delete();

            MobLicensePlate.Get(MobLicensePlateContent."No.");
            MobLicensePlate.Modify(true);  // Ensure to update Shipping Status Field
        end else begin
            MobLicensePlateContent.Get(ParentLicensePlateNo, LineNo);
            ToLicensePlate.Get(ToLicensePlateNo);

            case MobLicensePlateContent.Type of
                MobLicensePlateContent.Type::"License Plate":
                    begin
                        // Make sure the Move is valid, to avoid LP orfants..
                        MobLicensePlateMgt.CheckIsValidToLicensePlate(MobLicensePlateContent."No.", ToLicensePlate."No.");
                        MobLicensePlateContent.Rename(ToLicensePlate."No.", MobLicensePlateMgt.GetNextLicensePlateContentLineNo(ToLicensePlate));

                        // Ensure to update Shipping Status Field
                        MobLicensePlate.Get(MobLicensePlateContent."No.");
                        MobLicensePlate.Validate("Shipping Status", ToLicensePlate."Shipping Status");

                        // No need to update Receipt Status Field, as you cannot move a License Plate into a License Plate that is already received

                        MobLicensePlate.Modify(true);
                    end;
                MobLicensePlateContent.Type::Item:
                    begin

                        if QtyToMove > MobLicensePlateContent.Quantity then
                            Error(Move_qtyErr, MobLicensePlateContent.Quantity, MobLicensePlateContent."Unit Of Measure Code");

                        // Update existing Content
                        if QtyToMove = MobLicensePlateContent.Quantity then
                            MobLicensePlateContent.Delete()
                        else begin
                            MobLicensePlateContent.Validate(Quantity, MobLicensePlateContent.Quantity - QtyToMove);
                            MobLicensePlateContent.Modify(true);
                        end;

                        // Create new Content and set the Quantity to move
                        NewLicensePlateContent.Copy(MobLicensePlateContent);
                        NewLicensePlateContent.Validate(Quantity, QtyToMove);

                        // Add the new content to the target License Plate
                        ToLicensePlate.AddContent(NewLicensePlateContent);
                    end;
            end;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupOnLicensePlateContent_OnAfterSetFromLicensePlateContent(_LicensePlateContent: Record "MOB License Plate Content"; var _LookupResponseElement: Record "MOB NS WhseInquery Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupOnLicensePlateContent_OnAddSteps(var _LookupResponseElement: Record "MOB NS WhseInquery Element"; _LicensePlateContent: Record "MOB License Plate Content"; var _Steps: Record "MOB Steps Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupOnLicensePlateContent_OnAfterAddStep(_LicensePlateContent: Record "MOB License Plate Content"; var _Step: Record "MOB Steps Element")
    begin
    end;

}
