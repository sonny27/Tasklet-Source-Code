codeunit 81309 "MOB ReqPage Handler Item Label"
{
    Access = Public;
    var
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
        MobToolbox: Codeunit "MOB Toolbox";
        MobWmsLanguage: Codeunit "MOB WMS Language";

    // ----- STEPS ------ Ensure proper steps are shown on the device

    /// <summary>
    /// Get the required steps for Item Reports when the report is called from from the main menu or from a page with context values
    /// </summary>    
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB Report Print Lookup", 'OnLookupOnPrintReport_OnAddStepsForReport', '', true, true)]
    local procedure OnLookupOnPrintReport_OnAddStepsForReport(_MobReport: Record "MOB Report"; var _RequestValues: Record "MOB NS Request Element"; _SourceRecRef: RecordRef; var _Steps: Record "MOB Steps Element"; var _IsHandled: Boolean)
    begin
        if _MobReport."RequestPage Handler" <> _MobReport."RequestPage Handler"::"Item Label" then
            exit;

        // ReferenceID and Scanned ItemNumber
        case true of
            // ReferenceID sent out on order lines to identify the context which this page is called from
            _RequestValues.Get_ReferenceID() <> '':
                CreateSteps_FromPageWithContextValues(_MobReport, _RequestValues, _SourceRecRef, _Steps);

            // Identify Item, Item Reference or Item Cross Reference
            _RequestValues.Get_ItemNumber() <> '':
                CreateSteps_FromMainMenu(_MobReport, _RequestValues, _Steps);
        end;

        // The requestpage is handled but might not always return any steps and should therefore maybe not be shown
        _IsHandled := true;
    end;

    /// <summary>
    /// Get the required steps for Item Label requestpage when request has ContextValues (called from a Mobile Page that was called from another Mobile Page)
    /// </summary>
    local procedure CreateSteps_FromPageWithContextValues(_MobReport: Record "MOB Report"; var _RequestValues: Record "MOB NS Request Element"; _SourceRecRef: RecordRef; var _RequiredSteps: Record "MOB Steps Element")
    var
        Item: Record Item;
        MobTrackingSetup: Record "MOB Tracking Setup";
        MobReportPrintLookup: Codeunit "MOB Report Print Lookup";
        ItemNumber: Code[20];
        VariantCode: Code[10];
        UoMCode: Code[10];
        RegisterExpirationDate: Boolean;
        MultipleItemUoM: Boolean;
        ItemReferenceUoMList: Text;
        ItemReferenceUoMHelp: Text;
    begin
        // Prevent "Unused variable" warning
        Clear(ItemNumber);
        Clear(VariantCode);

        // Get ItemNumber from source record - otherwise exit
        if not MobWmsToolbox.GetFirstRelatedFieldValue(_SourceRecRef, Database::Item, ItemNumber) then
            exit;

        // Exit if no valid Item is found
        if not Item.Get(ItemNumber) then
            exit;

        // Get VariantCode to be used in other steps
        if not MobWmsToolbox.GetFirstRelatedFieldValue(_SourceRecRef, Database::"Item Variant", VariantCode) then
            VariantCode := '';

        // Determine Item tracking
        MobTrackingSetup.DetermineSpecificTrackingRequiredFromItemNo(Item."No.", RegisterExpirationDate);
        MobTrackingSetup.CopyTrackingFromRequestContextValues(_RequestValues); // Respect values from context as defaultvalues when creating steps below

        // Steps: SerialNumber, LotNumber, PackageNumber, Experation Date and custom tracking dimensions
        _RequiredSteps.Create_TrackingStepsIfRequired(MobTrackingSetup, 10, Item."No.", true);

        if RegisterExpirationDate then begin
            _RequiredSteps.Create_DateStep_ExpirationDate(50, Item."No.");
            _RequiredSteps.Set_defaultValue(_RequestValues.GetContextValueAsDate('ExpirationDate'));
        end;

        // Step Unit of Measure (Structured very differently, but aligned with the Cloud Print approach)
        _RequiredSteps.Create_ListStep_UoM(60, Item."No."); // Initially adding all UoMs - also those without a barcode

        if MobTrackingSetup."Serial No. Required" then // SN tracked items should always be printed in the Base UoM
            UoMCode := Item."Base Unit of Measure";

        if UoMCode = '' then begin
            ItemReferenceUoMList := MobWmsToolbox.GetItemReferenceUoMList(Item."No.", VariantCode); // Get all UoMs with a barcode
            MultipleItemUoM := ItemReferenceUoMList.Contains(';');

            if MultipleItemUoM then // If multiple UoMs are found, then set the list of UoMs - otherwise set the UoMCode (might be blank)
                _RequiredSteps.Set_listValues(ItemReferenceUoMList) // If the UoM isn't unique, then ensure the step only contains values related to the ItemNo and Variant
            else
                UoMCode := ItemReferenceUoMList;
        end;

        if (UoMCode = '') and MultipleItemUoM then // If no UoM is found, then try to get the UoM from the source record
            if not MobWmsToolbox.GetFirstRelatedFieldValue(_SourceRecRef, Database::"Unit of Measure", UoMCode) then
                MobWmsToolbox.GetFirstRelatedFieldValue(_SourceRecRef, Database::"Item Unit of Measure", UoMCode);

        if (UoMCode = '') and MultipleItemUoM then // If no UoM is found, then try to get the UoM from the request values
            UoMCode := _RequestValues.GetValueOrContextValue('UnitOfMeasure');

        if UoMCode = '' then // If no UoM is found, then set the UoM to the Base UoM
            UoMCode := Item."Base Unit of Measure"; // This allows the Item No. to be used as barcode even when no barcode exists

        if UoMCode <> '' then
            _RequiredSteps.Set_defaultValue(UoMCode); // If the UoM is found above, then set the default value

        if (UoMCode <> '') and not MultipleItemUoM then begin // A single valid UoM was found, so hide the step and show it in the helpLabel for the Qty step
            _RequiredSteps.Set_visible(false);
            ItemReferenceUoMHelp := UoMCode // Add Helplabel if UoM is known
        end;

        // Step Quantity per label
        _RequiredSteps.Create_DecimalStep_QuantityPerLabel(70);

        if not MobTrackingSetup."Serial No. Required" then begin
            _RequiredSteps.Set_defaultValue(_RequestValues.GetValueOrContextValueAsDecimal('Quantity'));

            if ItemReferenceUoMHelp <> '' then
                _RequiredSteps.Set_helpLabel(_RequiredSteps.Get_helpLabel() + MobToolbox.CRLFSeparator() + MobWmsLanguage.GetMessage('UOM_LABEL') + ': ' + ItemReferenceUoMHelp);

        end else begin
            _RequiredSteps.Set_defaultValue(1);
            _RequiredSteps.Set_visible(false);
        end;

        // Step Variant
        _RequiredSteps.Create_ListStep_Variant(80, Item."No.");
        _RequiredSteps.Set_defaultValue(VariantCode);
        _RequiredSteps.Set_visible((VariantCode = '') and (_RequiredSteps.Get_listValues() <> '')); // Only show step if variant isn't specified on the source and the item got variant(s) 

        // Printer related steps
        MobReportPrintLookup.CreateReportPrinterAndNoOfCopiesSteps(_MobReport, _RequestValues, _RequiredSteps, 90, 100);
    end;

    /// <summary>
    /// Get the required steps for Item Reports when the report is called from the main menu
    /// </summary>
    local procedure CreateSteps_FromMainMenu(_MobReport: Record "MOB Report"; var _RequestValues: Record "MOB NS Request Element"; var _RequiredSteps: Record "MOB Steps Element")
    var
        Item: Record Item;
        MobTrackingSetup: Record "MOB Tracking Setup";
        MobItemReferenceMgt: Codeunit "MOB Item Reference Mgt.";
        MobReportPrintLookup: Codeunit "MOB Report Print Lookup";
        ItemNumber: Code[20];
        VariantCode: Code[10];
        VariantList: Text;
        ItemUoMList: Text;
        UoMCode: Code[10];
        RegisterExpirationDate: Boolean;
        MultipleItemUoM: Boolean;
        MultipleVariants: Boolean;
        ItemReferenceUoMHelp: Text;
    begin
        ItemNumber := MobItemReferenceMgt.SearchItemReference(_RequestValues.Get_ItemNumber(), VariantCode, UoMCode);

        // Exit if no valid Item is found
        if ItemNumber = '' then
            exit;
        if not Item.Get(ItemNumber) then
            Error(MobWmsLanguage.GetMessage('UNKNOWN_ITEM_NO'), ItemNumber);

        // Determine Item tracking
        MobTrackingSetup.DetermineSpecificTrackingRequiredFromItemNo(Item."No.", RegisterExpirationDate);

        // Steps: SerialNumber, LotNumber, PackageNumber, Experation Date and custom tracking dimensions
        _RequiredSteps.Create_TrackingStepsIfRequired(MobTrackingSetup, 10, Item."No.", true);
        if RegisterExpirationDate then
            _RequiredSteps.Create_DateStep_ExpirationDate(50, Item."No.");

        // Step Unit of Measure
        if (UoMCode = '') or MobTrackingSetup."Serial No. Required" then
            UoMCode := Item."Base Unit of Measure";

        ItemUoMList := MobWmsToolbox.GetItemUoM(Item."No.");
        MultipleItemUoM := ItemUoMList.Contains(';');

        _RequiredSteps.Create_ListStep_UoM(60, Item."No.");
        _RequiredSteps.Set_defaultValue(UoMCode);
        _RequiredSteps.Set_visible(MultipleItemUoM and (not MobTrackingSetup."Serial No. Required"));

        // Step Quantity per label
        _RequiredSteps.Create_DecimalStep_QuantityPerLabel(70);

        if not MobTrackingSetup."Serial No. Required" then begin

            // Set default value to prevent ['' is not a valid value] errors (improve error message at device if no value was entered)
            _RequiredSteps.Set_defaultValue(0);

            // Add Helplabel if UoM is known
            if (UoMCode <> '') and (not MultipleItemUoM) then // A single valid UoM was found
                ItemReferenceUoMHelp := UoMCode;

            if ItemReferenceUoMHelp <> '' then
                _RequiredSteps.Set_helpLabel(_RequiredSteps.Get_helpLabel() + MobToolbox.CRLFSeparator() + MobWmsLanguage.GetMessage('UOM_LABEL') + ': ' + ItemReferenceUoMHelp);

        end else begin
            _RequiredSteps.Set_defaultValue(1);
            _RequiredSteps.Set_visible(false);
        end;

        // Step Variant 
        VariantList := MobWmsToolbox.GetItemVariants(Item."No.");
        MultipleVariants := VariantList.Contains(';');

        _RequiredSteps.Create_ListStep_Variant(80, Item."No.");
        _RequiredSteps.Set_defaultValue(VariantCode);
        _RequiredSteps.Set_visible(MultipleVariants);

        // Printer related steps
        MobReportPrintLookup.CreateReportPrinterAndNoOfCopiesSteps(_MobReport, _RequestValues, _RequiredSteps, 90, 100);
    end;

    // ----- REQUEST PAGE PARAMETERS

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB ReportParameters Mgt.", 'OnCreateReportParameters', '', true, true)]
    local procedure OnCreateReportParameters(_MobReport: Record "MOB Report"; _SourceRecRef: RecordRef; var _RequestValues: Record "MOB NS Request Element" temporary; var _OptionsFieldValues: Record "MOB ReportParameters Element"; var _DataItemViews: Record "MOB ReportParameters Element"; var _IsHandled: Boolean)
    var
        Item: Record Item;
        MobItemReferenceMgt: Codeunit "MOB Item Reference Mgt.";
        ItemNumber: Code[20];
        DummyVariantCode: Code[10];
        DummyUoMCode: Code[10];
        NoOfCopies: Integer;
    begin
        if _MobReport."RequestPage Handler" <> _MobReport."RequestPage Handler"::"Item Label" then
            exit;

        // Everything in the Parameter shall be formatted in XML format to support non-text fields in the request page
        // All options (with and without value) are transfered to ensure any personal saved values are overwritten

        // Request Page Control: No. of Copies
        NoOfCopies := _RequestValues.GetValueAsInteger('NoOfCopies');
        NoOfCopies := NoOfCopies - 1; // Handle difference in NoOfCopies logic in Step Element vs. Report.RequestPage
        _OptionsFieldValues.SetValue('NoOfCopiesReq', NoOfCopies);

        // Request Page Control: Variant Code
        _OptionsFieldValues.SetValue('ItemVariantCodeReq', _RequestValues.GetValue('Variant'));

        // Request Page Control: Quantity
        _OptionsFieldValues.SetValue('QuantityReq', _RequestValues.GetValueAsDecimal('QuantityPerLabel'));

        // Request Page Control: Unit of Meassure
        _OptionsFieldValues.SetValue('UoMReq', _RequestValues.GetValue('UoM'));

        // Request Page Control: Lot Number
        _OptionsFieldValues.SetValue('LotNoReq', _RequestValues.Get_LotNumber());

        // Request Page Control: Expiration Date 
        _OptionsFieldValues.SetValue('ExpirationDateReq', _RequestValues.Get_ExpirationDate());

        // Request Page Control: Serial No.
        _OptionsFieldValues.SetValue('SerialNoReq', _RequestValues.Get_SerialNumber());

        // Request Page Control: Package No.
        /* #if BC18+ */
        _OptionsFieldValues.SetValue('PackageNoReq', _RequestValues.GetValue('PackageNumber'));
        /* #endif */

        // Request Page DataItem: Item
        // Generate an Item variable with filters to be set in the Item dataitem of the report
        // I.e. like this: <DataItem name="Item">VERSION(1) SORTING(Field1) WHERE(Field1=1(70000))</DataItem>
        if _SourceRecRef.Number() = Database::Item then begin
            _SourceRecRef.SetTable(Item);
            ItemNumber := Item."No.";
        end else
            ItemNumber := MobItemReferenceMgt.SearchItemReference(_RequestValues.Get_ItemNumber(), DummyVariantCode, DummyUoMCode);

        Item.SetRange("No.", ItemNumber); // If no ItemNumber is found, the filter will not include any record
        _DataItemViews.SetValue('Item', Item.GetView(false));

        _IsHandled := true; // Multiple subscribers can add to the parameters for the same requestpage handler - this just indicates at least one subscriber has handled this report
    end;
}
