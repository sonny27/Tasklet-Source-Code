codeunit 82225 "MOB Print License Plate"
{
    Access = Public;
    var
        MobPrint: Codeunit "MOB Print";
        MobToolbox: Codeunit "MOB Toolbox";
        MobLanguage: Codeunit "MOB WMS Language";
        MobTypeHelper: Codeunit "MOB Type Helper";
        FormatAddress: Codeunit "Format Address";
        MobFormatAddress: Codeunit "MOB Format Address";
        MobPackFeatureMgt: Codeunit "MOB Pack Feature Management";

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB Print", 'OnPrintLabel_OnAfterPopulateDataset', '', true, true)]
    local procedure OnPrintLabelOnAfterPopulateDataset(var _Dataset: Record "MOB Common Element"; var _RequestValues: Record "MOB NS Request Element"; _SourceRecRef: RecordRef; _TemplateName: Text[50])
    var
        LabelTemplate: Record "MOB Label-Template";
    begin
        if not LabelTemplate.Get(_TemplateName) then
            exit;

        case LabelTemplate."Template Handler" of

            // Handle and modify "License Plate" label (when used from Pack & Ship as opposed to from Pick)
            LabelTemplate."Template Handler"::"License Plate":
                OnAfterPopulateDataset_LicensePlate(_Dataset, _RequestValues, LabelTemplate);

            // Handle "License Plate Contents" label (only used in Pack & Ship for now)
            LabelTemplate."Template Handler"::"License Plate Contents":
                OnAfterPopulateDataset_LicensePlateContents(_Dataset, _RequestValues, _SourceRecRef);
        end;
    end;

    local procedure OnAfterPopulateDataset_LicensePlate(var _Dataset: Record "MOB Common Element"; var _RequestValues: Record "MOB NS Request Element"; _LabelTemplate: Record "MOB Label-Template")
    var
        CompanyInformation: Record "Company Information";
        SalesHeader: Record "Sales Header";
        TransferHeader: Record "Transfer Header";
        ServiceHeader: Record "Service Header";
        PurchaseHeader: Record "Purchase Header";
        SourceRecRef: RecordRef;
        AddrArray: array[8] of Text;
        LicensePlateNo: Code[20];
    begin
        // Respect License Plate no. from context (E.g. Pack & Ship lookup)
        LicensePlateNo := _RequestValues.GetValueOrContextValue('LicensePlate');

        // Fallback to using "No. Series" as set by default "Mob Print" handling
        if LicensePlateNo = '' then begin
            LicensePlateNo := _Dataset.GetValue('NoSeriesValue');

            if LicensePlateNo = '' then
                _LabelTemplate.TestField("Number Series");
        end;

        _Dataset.SetValue('ExtraInfo02', LicensePlateNo);

        // "Header" is sender
        CompanyInformation.Get();
        FormatAddress.Company(AddrArray, CompanyInformation);
        _Dataset.SetValue('Header_Label', CompanyInformation.Name);
        _Dataset.SetValue('Header', AddrArray[2] + MobToolbox.CRLFSeparator() +
                                            AddrArray[3] + MobToolbox.CRLFSeparator() +
                                            AddrArray[4] + MobToolbox.CRLFSeparator() +
                                            AddrArray[5]);

        _Dataset.SetValue('Body_Label', _Dataset.GetValue('DeliveryName'));
        _Dataset.SetValue('Body', _Dataset.GetValue('DeliveryAddress'));

        // "Body" is receiver
        // Modify "License Plate" label (when used from Pack & Ship as opposed to from Pick)
        // Note: we are working on 'SourceReferenceID' pointing to Source Document of either type Sales Order or Transfer Order.
        // The value in 'ReferenceID' will point to the Warehouse Shipment
        if MobPackFeatureMgt.IsEnabled() then begin
            MobToolbox.ReferenceIDText2RecRef(_Dataset.GetValue('SourceReferenceID'), SourceRecRef);

            case SourceRecRef.Number() of
                Database::"Sales Header":
                    begin
                        SourceRecRef.SetTable(SalesHeader);
                        _Dataset.SetValue('Body_Label', SalesHeader."Ship-to Name");
                        _Dataset.SetValue('Body', GetShipToAddress_FromRecRef(SourceRecRef));
                    end;
                Database::"Transfer Header":
                    begin
                        SourceRecRef.SetTable(TransferHeader);
                        _Dataset.SetValue('Body_Label', TransferHeader."Transfer-to Code");
                        _Dataset.SetValue('Body', GetShipToAddress_FromRecRef(SourceRecRef));
                    end;
                Database::"Service Header":
                    begin
                        SourceRecRef.SetTable(ServiceHeader);
                        _Dataset.SetValue('Body_Label', ServiceHeader."Ship-to Name");
                        _Dataset.SetValue('Body', GetShipToAddress_FromRecRef(SourceRecRef));
                    end;
                Database::"Purchase Header":
                    begin
                        SourceRecRef.SetTable(PurchaseHeader);
                        _Dataset.SetValue('Body_Label', PurchaseHeader."Ship-to Name");
                        _Dataset.SetValue('Body', GetShipToAddress_FromRecRef(SourceRecRef));
                    end;
            end;
        end;
    end;

    local procedure OnAfterPopulateDataset_LicensePlateContents(var _Dataset: Record "MOB Common Element"; var _RequestValues: Record "MOB NS Request Element"; _SourceRecRef: RecordRef)
    var
        WhseShipmentHeader: Record "Warehouse Shipment Header";
        LicensePlateToPrint: Record "MOB License Plate";
        LicensePlateNo: Code[20];
        MoreThanOne: Boolean;
    begin
        if not MobPackFeatureMgt.IsEnabled() then
            exit;

        LicensePlateNo := _RequestValues.GetValueOrContextValue('LicensePlate');

        // Request is a single License Plate
        if LicensePlateNo <> '' then
            TransferLicensePlateAndContent2Dataset(LicensePlateNo, _Dataset)

        else // Request is a Shipment (can be multiple License Plates)
            if _SourceRecRef.Number() = Database::"Warehouse Shipment Header" then begin
                _SourceRecRef.SetTable(WhseShipmentHeader);

                LicensePlateToPrint.SetRange("Whse. Document Type", LicensePlateToPrint."Whse. Document Type"::Shipment);
                LicensePlateToPrint.SetRange("Whse. Document No.", WhseShipmentHeader."No.");
                LicensePlateToPrint.SetRange("Top-level", true);
                LicensePlateToPrint.SetRange("Content Exists", true);
                if LicensePlateToPrint.FindSet() then
                    repeat
                        if MoreThanOne then begin
                            _Dataset.Create();
                            _Dataset.SetValue('SourceReferenceID', _RequestValues.GetValue('SourceReferenceID'));
                        end;

                        TransferLicensePlateAndContent2Dataset(LicensePlateToPrint."No.", _Dataset);
                        MoreThanOne := true;
                    until LicensePlateToPrint.Next() = 0;
            end
    end;

    // Return steps for "License Plate" and "License Plate Contents" labels
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB Print", 'OnLookupOnPrintLabel_OnAddStepsForTemplate', '', true, true)]
    local procedure OnLookupOnPrintLabel_OnAddStepsForTemplate(_TemplateName: Text[50]; _SourceRecRef: RecordRef; var _Steps: Record "MOB Steps Element"; var _Dataset: Record "MOB Common Element"; var _RequestValues: Record "MOB NS Request Element")
    var
        MobLabelTemplate: Record "MOB Label-Template";
    begin
        MobLabelTemplate.Get(_TemplateName);

        case MobLabelTemplate."Template Handler" of
            MobLabelTemplate."Template Handler"::"License Plate":
                GetSteps_LicensePlate(_TemplateName, _RequestValues, _Steps);
            MobLabelTemplate."Template Handler"::"License Plate Contents":
                GetSteps_LicensePlateContents(_TemplateName, _RequestValues, _SourceRecRef, _Steps);
        end;
    end;

    local procedure GetSteps_LicensePlateContents(_TemplateName: Text[50]; var _RequestValues: Record "MOB NS Request Element"; _SourceRecRef: RecordRef; var _Steps: Record "MOB Steps Element")
    begin
        if not MobPackFeatureMgt.IsEnabled() then
            exit;

        // Request must be either a License Plate or a Shipment
        if (_RequestValues.GetContextValue('LicensePlate') = '') and (_SourceRecRef.Number() <> Database::"Warehouse Shipment Header") then
            exit;

        MobPrint.CreatePrinterAndNoOfCopiesSteps(_TemplateName, _RequestValues, _Steps);
    end;

    local procedure GetSteps_LicensePlate(_TemplateName: Text[50]; var _RequestValues: Record "MOB NS Request Element"; var _Steps: Record "MOB Steps Element")
    var
        ExclusivePrinter: Text;
    begin
        ExclusivePrinter := MobPrint.GetExclusivePrinter(_TemplateName, _RequestValues.Get_Location());
        _Steps.Create_ListStep_Printer(70, _TemplateName, _RequestValues.Get_Location());
        if ExclusivePrinter <> '' then begin // Only one printer = Hide step and set default value
            _Steps.Set_defaultValue(ExclusivePrinter);
            _Steps.Set_visible(false);
        end;

        if _RequestValues.GetValueOrContextValue('LicensePlate') <> '' then
            _Steps.Create_IntegerStep_NoOfCopies(10)  // Existing LP, ask for copy
        else
            _Steps.Create_IntegerStep_NoOfLabels(10); // New LP, ask for number of new labels

        if ExclusivePrinter <> '' then // Only one printer = Show the printer name as helpLabel
            _Steps.Set_helpLabel(_Steps.Get_helpLabel() + MobToolbox.CRLFSeparator() + MobToolbox.CRLFSeparator() + MobLanguage.GetMessage('PRINTER') + ': ' + ExclusivePrinter)
    end;

    //
    // ----------- Helper funcs ----------- // Todo: Move all these function to Mob Print
    //

    local procedure TransferLicensePlateAndContent2Dataset(LicensePlateNo: Code[20]; var _Dataset: Record "MOB Common Element")
    var
        LicensePlate: Record "MOB License Plate";
    begin
        if not LicensePlate.Get(LicensePlateNo) then
            exit;

        // Transfer Top-level License Plate as label header
        LicensePlate2Dataset(LicensePlate, _Dataset);
        TransferLicensePlateContent2Dataset(LicensePlate."No.", _Dataset);
    end;

    local procedure TransferLicensePlateContent2Dataset(LicensePlateNo: Code[20]; var _Dataset: Record "MOB Common Element")
    var
        LicensePlateContent: Record "MOB License Plate Content";
    begin
        LicensePlateContent.Reset();
        LicensePlateContent.SetCurrentKey("Whse. Document Type", "Whse. Document No.", Type, "No.", "Package No.", "Lot No.", "Serial No.", "Variant Code"); // TODO: No database key includes Package No.
        LicensePlateContent.SetRange("License Plate No.", LicensePlateNo);  // TODO: Not in current key
        if LicensePlateContent.FindSet() then
            repeat
                if LicensePlateContent.Type = LicensePlateContent.Type::"License Plate" then begin
                    // Print a Header-line for the License Plate, before it's lines
                    LicensePlateContentHeader2Dataset(LicensePlateContent, _Dataset);
                    TransferLicensePlateContent2Dataset(LicensePlateContent."No.", _Dataset);
                end else
                    // Print License Plate Content-line
                    LicensePlateContent2Dataset(LicensePlateContent, _Dataset);
            until LicensePlateContent.Next() = 0;
    end;

    /// <summary>
    /// Transfer License Plate to Dataset
    /// </summary>
    local procedure LicensePlate2Dataset(_LicensePlate: Record "MOB License Plate"; var _Dataset: Record "MOB Common Element")
    var
        SourceRecRef: RecordRef;
    begin
        _Dataset.SetValue('Header-No', _LicensePlate."No.");

        _Dataset.SetValue('DeliveryName', 'License Plate Contents');
        _Dataset.SetValue('OrderId_Label', _LicensePlate."No.");
        _Dataset.SetValue('OrderId', _LicensePlate."No.");

        MobToolbox.ReferenceIDText2RecRef(_Dataset.GetValue('SourceReferenceID'), SourceRecRef);
        _Dataset.SetValue('DeliveryAddress', GetShipToAddress_FromRecRef(SourceRecRef));
    end;

    /// <summary>
    /// Transfer License Plate Content to Dataset
    /// </summary>
    local procedure LicensePlateContent2Dataset(_LicensePlateContent: Record "MOB License Plate Content"; var _Dataset: Record "MOB Common Element")
    var
        WhseShipmentLine: Record "Warehouse Shipment Line";
        Location: Record Location;
        MobTrackingSetup: Record "MOB Tracking Setup";
        MobItemTrackingManagement: Codeunit "MOB Item Tracking Management";
        RecRef: RecordRef;
        ExpDate: Date;
        Path: Text;
    begin
        WhseShipmentLine.Get(_LicensePlateContent."Whse. Document No.", _LicensePlateContent."Whse. Document Line No.");

        Path := 'Lines/OrderLine' + _LicensePlateContent."License Plate No." + Format(_LicensePlateContent."Line No.") + 'DESCRIPTION'; // Use the records PrimaryKey as Path
        RecRef.GetTable(_LicensePlateContent);

        _Dataset.SetValue(Path + '/Col1', _LicensePlateContent."No.");
        _Dataset.SetValue(Path + '/Col1_Label', MobLanguage.GetMessage('NO.'));
        _Dataset.SetValue(Path + '/Col2', WhseShipmentLine.Description + ' ' + WhseShipmentLine."Description 2");
        _Dataset.SetValue(Path + '/Col2_Label', MobLanguage.GetMessage('DESCRIPTION'));
        _Dataset.SetValue(Path + '/Col3', Format(_LicensePlateContent.Quantity));
        _Dataset.SetValue(Path + '/Col3_Label', MobLanguage.GetMessage('QUANTITY'));
        _Dataset.SetValue(Path + '/Col4', _LicensePlateContent."Unit Of Measure Code");
        _Dataset.SetValue(Path + '/Col4_Label', MobLanguage.GetMessage('UOM_LABEL'));
        MobPrint.OnPrintLabel_OnAfterPopulateOrderListLine(Path, RecRef, _Dataset);

        Clear(MobTrackingSetup);
        _LicensePlateContent.CopyTrackingToMobTrackingSetup(MobTrackingSetup);

        if MobTrackingSetup."Serial No." <> '' then begin
            Path := 'Lines/OrderLine' + _LicensePlateContent."License Plate No." + Format(_LicensePlateContent."Line No.") + 'SNNO';
            _Dataset.SetValue(Path + '/Col2', MobLanguage.GetMessage('SERIAL_NO_LABEL') + ': ' + MobTrackingSetup."Serial No.");
            _Dataset.SetValue(Path + '/Col2_Label', MobLanguage.GetMessage('DESCRIPTION'));
            MobPrint.OnPrintLabel_OnAfterPopulateOrderListLine(Path, RecRef, _Dataset);
        end;

        if MobTrackingSetup."Lot No." <> '' then begin
            Location.Get(WhseShipmentLine."Location Code");
            Path := 'Lines/OrderLine' + _LicensePlateContent."License Plate No." + Format(_LicensePlateContent."Line No.") + 'LOTNO';
            _Dataset.SetValue(Path + '/Col2', MobLanguage.GetMessage('LOT_NO_LABEL') + ': ' + MobTrackingSetup."Lot No.");
            _Dataset.SetValue(Path + '/Col2_Label', MobLanguage.GetMessage('DESCRIPTION'));
            MobPrint.OnPrintLabel_OnAfterPopulateOrderListLine(Path, RecRef, _Dataset);

            MobItemTrackingManagement.GetWhseExpirationDate(_LicensePlateContent."No.", _LicensePlateContent."Variant Code", Location, MobTrackingSetup, ExpDate);

            if ExpDate <> 0D then begin
                Path := 'Lines/OrderLine' + _LicensePlateContent."License Plate No." + Format(_LicensePlateContent."Line No.") + 'EXPDATE';
                _Dataset.SetValue(Path + '/Col2', MobLanguage.GetMessage('EXP_DATE_LABEL') + ': ' + MobTypeHelper.FormatDateAsLanguage(ExpDate, GlobalLanguage())); // NOTE: Global Language has been set to: MobPrintSetup."Language Code"
                _Dataset.SetValue(Path + '/Col2_Label', MobLanguage.GetMessage('DESCRIPTION'));
                MobPrint.OnPrintLabel_OnAfterPopulateOrderListLine(Path, RecRef, _Dataset);
            end;
        end;

        if MobTrackingSetup."Package No." <> '' then begin
            Path := 'Lines/OrderLine' + _LicensePlateContent."License Plate No." + Format(_LicensePlateContent."Line No.") + 'PACKAGENO';
            _Dataset.SetValue(Path + '/Col2', _LicensePlateContent.FieldCaption("Package No.") + ': ' + MobTrackingSetup."Package No.");
            _Dataset.SetValue(Path + '/Col2_Label', MobLanguage.GetMessage('DESCRIPTION'));
            MobPrint.OnPrintLabel_OnAfterPopulateOrderListLine(Path, RecRef, _Dataset);
        end;

    end;

    local procedure LicensePlateContentHeader2Dataset(_LicensePlateContent: Record "MOB License Plate Content"; var _Dataset: Record "MOB Common Element")
    var
        LicensePlateMgt: Codeunit "MOB License Plate Mgt";
        Path: Text;
        LPStructureTxt: Text;
    begin
        LPStructureTxt := Format(_LicensePlateContent."No.");
        LicensePlateMgt.GetLicensePlateStructureAsText(_LicensePlateContent, LPStructureTxt);  // LPStructureTxt will contain info of the LP Structure, like '10 -> 12 -> 15' where 10 = LP No. on top level and 15 = LP No. on current level

        Path := 'Lines/OrderLine' + _LicensePlateContent."No.";
        _Dataset.SetValue(Path + '/LongLine', 'true');
        _Dataset.SetValue(Path + '/Col1', ' '); // Blank line
        _Dataset.SetValue(Path + '/Col1_Label', MobLanguage.GetMessage('NO.'));

        Path := 'Lines/OrderLine' + _LicensePlateContent."No." + '0'; // Unique pah for each line
        _Dataset.SetValue(Path + '/LongLine', 'true');
        _Dataset.SetValue(Path + '/Col1', LPStructureTxt);
        _Dataset.SetValue(Path + '/Col1_Label', MobLanguage.GetMessage('NO.'));
    end;

    local procedure GetShipToAddress_FromRecRef(_SourceRecRef: RecordRef): Text
    var
        SalesHeader: Record "Sales Header";
        TransferHeader: Record "Transfer Header";
        ServiceHeader: Record "Service Header";
        PurchaseHeader: Record "Purchase Header";
        AddrArray: array[8] of Text;
        CustAddrArray: array[8] of Text;
    begin
        case _SourceRecRef.Number() of
            Database::"Sales Header":
                begin
                    _SourceRecRef.SetTable(SalesHeader);
                    FormatAddress.SalesHeaderShipTo(AddrArray, CustAddrArray, SalesHeader);
                    exit(ConvertAddrArrayToText(AddrArray));
                end;
            Database::"Transfer Header":
                begin
                    _SourceRecRef.SetTable(TransferHeader);
                    FormatAddress.TransferHeaderTransferTo(AddrArray, TransferHeader);
                    exit(ConvertAddrArrayToText(AddrArray));
                end;
            Database::"Service Header":
                begin
                    _SourceRecRef.SetTable(ServiceHeader);
                    MobFormatAddress.ServiceHeaderShipTo(AddrArray, ServiceHeader);
                    exit(ConvertAddrArrayToText(AddrArray));
                end;
            Database::"Purchase Header":
                begin
                    _SourceRecRef.SetTable(PurchaseHeader);
                    FormatAddress.PurchHeaderShipTo(AddrArray, PurchaseHeader);
                    exit(ConvertAddrArrayToText(AddrArray));
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB Print", 'OnLookupOnPrintLabel_OnAfterAddStepForTemplate', '', true, true)]
    local procedure OnLookupOnPrintLabel_OnAfterAddStepForTemplate(_TemplateName: Text[50]; _SourceRecRef: RecordRef; var _Step: Record "MOB Steps Element"; var _Dataset: Record "MOB Common Element")
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        MobPrinterLabelTemplate: Record "MOB Printer Label-Template";
        LabelTemplate: Record "MOB Label-Template";
    begin
        if not MobPackFeatureMgt.IsEnabled() then
            exit;

        if _Step.Get_name() = 'Printer' then begin
            LabelTemplate.Get(_TemplateName);
            if not (LabelTemplate."Template Handler" in [LabelTemplate."Template Handler"::"License Plate", LabelTemplate."Template Handler"::"License Plate Contents"]) then
                exit;

            if _SourceRecRef.Number() = Database::"Warehouse Shipment Header" then begin
                _SourceRecRef.SetTable(WarehouseShipmentHeader);

                if WarehouseShipmentHeader."MOB Packing Station Code" = '' then
                    exit;

                MobPrinterLabelTemplate.SetRange("Label-Template Name", _TemplateName);
                MobPrinterLabelTemplate.SetRange("Packing Station Code", WarehouseShipmentHeader."MOB Packing Station Code");
                if MobPrinterLabelTemplate.FindFirst() then
                    _Step.Set_defaultValue(MobPrinterLabelTemplate."Printer Name");
            end;
        end;
    end;

    local procedure ConvertAddrArrayToText(_AddrArray: array[8] of Text): Text
    begin
        exit(_AddrArray[1] + MobToolbox.CRLFSeparator() +
             _AddrArray[2] + MobToolbox.CRLFSeparator() +
             _AddrArray[3] + MobToolbox.CRLFSeparator() +
             _AddrArray[4] + MobToolbox.CRLFSeparator() +
             _AddrArray[5]);
    end;
}
