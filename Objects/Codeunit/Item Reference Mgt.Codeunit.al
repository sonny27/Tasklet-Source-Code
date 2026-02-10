codeunit 81441 "MOB Item Reference Mgt."
{
    Access = Public;
    //
    // AppVersion 19.0.0.0
    //

    var
        MobToolbox: Codeunit "MOB Toolbox";
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";

    procedure FeatureItemReferenceIsEnabled(): Boolean
    begin
        exit(true);
    end;

    /// <summary>
    /// Find and return Item No., Variant Code and UnitofMeasure from a scanned Barcode by searching the Item Reference table or Item Cross Reference table.
    /// Will return _ScannedBarcode as-is if not found (but clear _ReturnVariantCode and _ReturnUoMCode)
    /// </summary>
    /// <param name="_ScannedBarcode">Unprocessed barcode, may hold Item No., Item Reference or Item Cross Reference</param>
    /// <param name="_ReturnVariantCode">Returns Variant Code from found Item Reference (if populated). Cleared if no reference was found.</param>
    /// <param name="_ReturnUoMCode">Returns Unit Of Measure Code from found Item Reference (if populated). Cleared if no reference was found.</param>
    /// <returns>
    /// Item No. from found Item Reference (if found), otherwise _ScannedBarcode as-is
    /// An overload exists to throw error on not found (was accidentially default behavior in MOB5.26-MOB5.28, restored original default behaviour (no error) in MOB5.29)
    /// </returns>
    procedure SearchItemReference(_ScannedBarcode: Code[50]; var _ReturnVariantCode: Code[10]; var _ReturnUoMCode: Code[10]): Code[50]
    begin
        exit(SearchItemReference(_ScannedBarcode, _ReturnVariantCode, _ReturnUoMCode, false));
    end;

    procedure SearchItemReference(_ScannedBarcode: Code[50]; var _ReturnVariantCode: Code[10]; var _ReturnUoMCode: Code[10]; _ErrorIfNotExists: Boolean): Code[50]
    var
        DummyRecRef: RecordRef;
    begin
        exit(SearchItemReference(_ScannedBarcode, _ReturnVariantCode, _ReturnUoMCode, DummyRecRef, _ErrorIfNotExists));
    end;

    procedure SearchItemReference(_ScannedBarcode: Text; var _ReturnRecRef: RecordRef; _ErrorIfNotExists: Boolean)
    var
        DummyVariantCode: Code[10];
        DummyUoMCode: Code[10];
    begin
        SearchItemReference(_ScannedBarcode, DummyVariantCode, DummyUoMCode, _ReturnRecRef, _ErrorIfNotExists);
    end;

    local procedure SearchItemReference(_ScannedBarcode: Code[50]; var _ReturnVariantCode: Code[10]; var _ReturnUoMCode: Code[10]; var _ReturnRecRef: RecordRef; _ErrorIfNotExists: Boolean): Code[50]
    var
        Item: Record Item;
        ItemReference: Record "Item Reference";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        IsHandled: Boolean;
        ReturnItemNumber: Code[20];
    begin
        Clear(_ReturnVariantCode);
        Clear(_ReturnUoMCode);
        Clear(_ReturnRecRef);
        OnBeforeSearchItemReference(_ScannedBarcode, ReturnItemNumber, _ReturnVariantCode, _ReturnUoMCode, IsHandled);

        if IsHandled then begin
            // If Integration Event OnBeforeSearchItemReference has handled the search,
            // we have to create an Item Reference RecordRef with the returned Values for CloudPrint to work
            if StrLen(ReturnItemNumber) <= MaxStrLen(Item."No.") then
                if Item.Get(ReturnItemNumber) then begin
                    ItemReference."Item No." := Item."No.";
                    ItemReference."Variant Code" := _ReturnVariantCode;
                    ItemReference."Unit of Measure" := _ReturnUoMCode;
                    ItemReference."Reference Type" := ItemReference."Reference Type"::"Bar Code";
                    ItemReference."Reference No." := _ScannedBarcode;
                    _ReturnRecRef.GetTable(ItemReference);
                end;

            exit(ReturnItemNumber);
        end;

        if _ScannedBarcode = '' then
            exit;

        ItemReference.Reset();
        ItemReference.SetRange("Reference Type", ItemReference."Reference Type"::"Bar Code");
        ItemReference.SetRange("Reference No.", _ScannedBarcode);
        // ItemReference.SetRange("Discontinue Bar Code", false);     // Marked for removal in BC18: Not used in base application

        OnSearchItemReferenceOnAfterSetFilters(_ScannedBarcode, ItemReference);

        if ItemReference.FindFirst() then begin
            // Found Item Cross Reference
            if ItemReference."Variant Code" <> '' then
                _ReturnVariantCode := ItemReference."Variant Code";
            if ItemReference."Unit of Measure" <> '' then
                _ReturnUoMCode := ItemReference."Unit of Measure";
            _ReturnRecRef.GetTable(ItemReference);
            exit(ItemReference."Item No.");
        end else begin
            // First fallback: Search exact ItemNo whenever we can to avoid searching GTIN with no good table key
            if StrLen(_ScannedBarcode) <= MaxStrLen(Item."No.") then begin
                Item.Reset();
                Item.SetRange("No.", _ScannedBarcode);
                if Item.FindFirst() then begin
                    _ReturnRecRef.GetTable(Item);
                    exit(Item."No.");
                end;
            end;

            // Second fallback: Search GTIN
            if StrLen(_ScannedBarcode) <= MaxStrLen(Item.GTIN) then begin
                Item.Reset();
                Item.SetCurrentKey(GTIN);   // Likely do not exist but index hint
                Item.SetRange(GTIN, _ScannedBarcode);
                if Item.FindFirst() then begin
                    _ReturnRecRef.GetTable(Item);
                    exit(Item."No.");
                end;
            end;

            // Not found = Return the scanned value again
            if _ErrorIfNotExists then
                Error(MobWmsLanguage.GetMessage('UNKNOWN_ITEM_NO'), _ScannedBarcode);

            exit(_ScannedBarcode);
        end;
    end;

    /// <summary>
    /// Find and return Item No. and Variant Code from a scanned Barcode by searching the Item Reference table or Item Cross Reference table.
    /// Will return _ScannedBarcode as-is if not found (but clear _ReturnVariantCode)
    /// </summary>
    /// <param name="_ScannedBarcode">Unprocessed barcode, may hold Item No., Item Reference or Item Cross Reference</param>
    /// <param name="_ReturnVariantCode">Returns Variant Code from found Item Reference (if populated). Cleared if no reference was found</param>
    /// <returns>Item No. from found Item Reference (if found), otherwise _ScannedBarcode as-is. Variant Code is returned as separate parameter. No UoM Code is returned</returns>
    procedure SearchItemReference(_ScannedBarcode: Code[50]; var _ReturnVariantCode: Code[10]): Code[50]
    var
        DummyUoMCode: Code[10];
    begin
        exit(SearchItemReference(_ScannedBarcode, _ReturnVariantCode, DummyUoMCode));
    end;

    /// <summary>
    /// Returns first barcode registered for an item
    /// </summary>
    procedure GetFirstReferenceNo(_ItemNo: Code[20]; _VariantCode: Code[10]; _UoM: Text): Code[50]
    var
        Item: Record Item;
        ItemReference: Record "Item Reference";
        FallbackToGTIN: Boolean;
    begin
        ItemReference.Reset();
        ItemReference.SetRange("Reference Type", ItemReference."Reference Type"::"Bar Code");
        ItemReference.SetRange("Item No.", _ItemNo);
        ItemReference.SetRange("Variant Code", _VariantCode);
        ItemReference.SetRange("Unit of Measure", _UoM);
        // ItemReference.SetRange("Discontinue Bar Code", false);     // Marked for removal in BC18: Not used in base application
        if ItemReference.FindFirst() then
            exit(ItemReference."Reference No.");

        if Item.Get(_ItemNo) then begin
            // Fallback to GTIN when Variant is not part of filter and UoM is blank or = Base Unit 
            FallbackToGTIN := (_VariantCode = '') and (_UoM in ['', Item."Base Unit of Measure"]);

            if FallbackToGTIN and (Item.GTIN <> '') then
                exit(Item.GTIN);
        end;
    end;

    [Obsolete('Replaced by GetBarcodeList() below to include UoMCode for customizations (planned for removal 02/2026)', 'MOB5.53')]
    procedure GetBarcodeList(_ItemNo: Code[20]; _VariantCode: Code[10]): Text
    begin
        exit(GetBarcodeQuantityList(_ItemNo, _VariantCode, '', false)); // Blank UoMCode
    end;

    /// <summary>
    /// Return list of barcodes from Item Reference table or Item Cross Reference table.
    /// </summary>
    procedure GetBarcodeList(_ItemNo: Code[20]; _VariantCode: Code[10]; _UoMCode: Code[10]): Text
    begin
        exit(GetBarcodeQuantityList(_ItemNo, _VariantCode, _UoMCode, false));
    end;

    /// <summary>
    /// Return list of barcodes from Item Reference table or Item Cross Reference table including barcode Quantity
    /// The BarcodeQuantityList can be used for BarcodeQuantity-value when RegisterQuantityByScan is enabled
    /// </summary>
    procedure GetBarcodeQuantityList(_ItemNo: Code[20]; _VariantCode: Code[10]; _UoMCode: Code[10]): Text
    begin
        exit(GetBarcodeQuantityList(_ItemNo, _VariantCode, _UoMCode, true));    // true = IncludeBarcodeQuantity
    end;

    /// <summary>
    /// Return list of barcodes from Item Reference table or Item Cross Reference table with- or without barcode Quantity
    /// </summary>
    internal procedure GetBarcodeQuantityList(_ItemNo: Code[20]; _VariantCode: Code[10]; _UoMCode: Code[10]; _IncludeBarcodeQuantity: Boolean) _BarcodeList: Text
    var
        Item: Record Item;
        ItemReference: Record "Item Reference";
        ItemUoMCrossRef: Record "Item Unit of Measure";
        ItemUoMInput: Record "Item Unit of Measure";
        UnitOfMeasure: Record "Unit of Measure";
        MobItemReferenceMgt: Codeunit "MOB Item Reference Mgt.";
        UoMMgt: Codeunit "Unit of Measure Management";
        Qty: Decimal;
        UoMDescription: Text;
        IsHandled: Boolean;
        ItemGtinIsInBarcodeList: Boolean;
    begin
        if not _IncludeBarcodeQuantity then
            MobItemReferenceMgt.OnBeforeGetBarcodeList(_ItemNo, _VariantCode, _UoMCode, _BarcodeList, IsHandled);  // BarcodeQuantity to have separate event (not implemented)

        if not IsHandled then begin

            // This function returns all barcodes registered for an item in a semi-colon separated list
            // This list can be interpreted by the mobile device and should be sent out in the ItemBarcode element on the order lines
            ItemReference.Reset();
            ItemReference.SetRange("Reference Type", ItemReference."Reference Type"::"Bar Code");
            ItemReference.SetRange(ItemReference."Item No.", _ItemNo);
            ItemReference.SetRange(ItemReference."Variant Code", _VariantCode);
            // ItemReference.SetRange("Discontinue Bar Code", false);     // Marked for removal in BC18: Not used in base application

            if not _IncludeBarcodeQuantity then
                OnGetBarcodeListOnAfterSetFilters(_ItemNo, _VariantCode, _UoMCode, ItemReference);

            Item.Get(_ItemNo);
            if _IncludeBarcodeQuantity then
                ItemUoMInput.Get(_ItemNo, _UoMCode);

            if ItemReference.FindSet() then
                repeat
                    if _IncludeBarcodeQuantity then begin
                        // Find the quantity for this unit of measure and divide by Input Unit of Meaure if specified
                        if ItemUoMCrossRef.Get(ItemReference."Item No.", ItemReference."Unit of Measure") and (ItemUoMInput."Qty. per Unit of Measure" <> 0) then
                            Qty := Round(ItemUoMCrossRef."Qty. per Unit of Measure" / ItemUoMInput."Qty. per Unit of Measure", UoMMgt.QtyRndPrecision())
                        else
                            // Not found -> just use 1
                            Qty := 1;

                        if UnitOfMeasure.Get(ItemReference."Unit of Measure") then
                            UoMDescription := UnitOfMeasure.GetDescriptionInCurrentLanguage()
                        else
                            UoMDescription := '';

                        if UoMDescription = '' then
                            UoMDescription := ItemReference."Unit of Measure";

                        // Add the barcode to the list
                        _BarcodeList += ItemReference."Reference No." + '{' + MobWmsToolbox.Decimal2TextAsXmlFormat(Qty) + '}[' + UoMDescription + '];';
                    end else
                        // Add the barcode to the list
                        _BarcodeList += ItemReference."Reference No." + ';';

                    if ItemReference."Reference No." = Item.GTIN then
                        ItemGtinIsInBarcodeList := true;

                until ItemReference.Next() = 0
            else
                _BarcodeList := _ItemNo + ';';

            if (Item.GTIN <> '') and (not ItemGtinIsInBarcodeList) then // Base Unit of Measure = 1                
                if _IncludeBarcodeQuantity then begin
                    if UnitOfMeasure.Get(Item."Base Unit of Measure") then
                        UoMDescription := UnitOfMeasure.GetDescriptionInCurrentLanguage()
                    else
                        UoMDescription := '';

                    if UoMDescription = '' then
                        UoMDescription := Item."Base Unit of Measure";

                    if ItemUoMInput."Qty. per Unit of Measure" <> 0 then
                        _BarcodeList += Item.GTIN + '{' + MobWmsToolbox.Decimal2TextAsXmlFormat(Round(1 / ItemUoMInput."Qty. per Unit of Measure", UoMMgt.QtyRndPrecision())) + '}[' + UoMDescription + '];' // GTIN calculated based on input from Source Line UOM
                    else
                        _BarcodeList += Item.GTIN + '{1}[' + UoMDescription + '];' // Item card base unit is for 1 of the item
                end else
                    _BarcodeList += Item.GTIN + ';';

            _BarcodeList := DelChr(_BarcodeList, '>', ';');

        end;

        if not _IncludeBarcodeQuantity then
            MobItemReferenceMgt.OnAfterGetBarcodeList(_ItemNo, _VariantCode, _UoMCode, _BarcodeList);  // BarcodeQuantity to have separate event (not implemented)
    end;

    /// <summary>
    /// Post Adhoc RegistrationType 'ItemCrossReference' (intentionally using legacy RegistrationType and named after this)
    /// </summary>
    procedure PostItemCrossRefRegistration(var _RequestValues: Record "MOB NS Request Element"; var _SuccessMessage: Text; var _ReturnRegistrationTypeTracking: Text)
    var
        Item: Record Item;
        ItemRef: Record "Item Reference";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        EnteredItem: Code[20];
        NewBarcode: Code[50];
        UoM: Code[10];
        VariantCode: Code[10];
    begin
        // The values are added to the relevant journal if they have been registered on the mobile device

        EnteredItem := MobWmsToolbox.GetItemNumber(MobToolbox.ReadMisc(_RequestValues.GetValue('ItemNumber')));
        NewBarcode := MobToolbox.ReadEAN(_RequestValues.GetValue('Barcode'));
        UoM := _RequestValues.GetValue('UoM');
        VariantCode := _RequestValues.GetValue('Variant');

        _ReturnRegistrationTypeTracking :=
            Item.TableCaption() + ' ' +
            EnteredItem + ' ' +
            ItemRef.FieldCaption("Unit of Measure") + ' ' +
            UoM;

        // Perform the posting
        if not Item.Get(EnteredItem) then
            Error(MobWmsLanguage.GetMessage('ITEM_EXIST_ERR'), EnteredItem);

        // with ItemCrossRef do begin
        ItemRef.SetFilter("Item No.", '<>%1', Item."No.");
        ItemRef.SetRange("Reference Type", ItemRef."Reference Type"::"Bar Code");
        ItemRef.SetRange("Reference No.", NewBarcode);
        // ItemRef.SetRange("Discontinue Bar Code", false);       // Marked for removal in BC18: Not used in base application

        if ItemRef.FindFirst() then
            Error(MobWmsLanguage.GetMessage('BARCODE_REF_IN_USE_ERR'), NewBarcode, ItemRef."Item No.");

        ItemRef.Reset();
        ItemRef.Init();
        ItemRef.Validate("Item No.", Item."No.");
        ItemRef.Validate("Variant Code", VariantCode);
        if UoM = '' then
            ItemRef.Validate("Unit of Measure", Item."Base Unit of Measure")
        else
            ItemRef.Validate("Unit of Measure", UoM);
        ItemRef.Validate("Reference Type", ItemRef."Reference Type"::"Bar Code");
        ItemRef.Validate("Reference No.", NewBarcode);
        OnPostAdhocRegistrationOnItemCrossReference_OnBeforeInsertItemReference(_RequestValues, ItemRef);
        if ItemRef.Insert(true) then; // Avoid error if already exists

        _SuccessMessage := StrSubstNo(MobWmsLanguage.GetMessage('ITEM_REFERENCE_CREATED'), EnteredItem);
    end;

    procedure CreateItemReference(_ItemNo: Code[20]; _VariantCode: Code[10]; _UoM: Code[10]; _RefNo: Code[50])
    var
        ItemReference: Record "Item Reference";
    begin
        if not ItemReference.Get(_ItemNo, _VariantCode, _UoM, ItemReference."Reference Type"::"Bar Code", '', _RefNo) then begin
            ItemReference.Init();
            ItemReference.Validate("Item No.", _ItemNo);
            ItemReference.Validate("Variant Code", _VariantCode);
            ItemReference.Validate("Unit of Measure", _UoM);
            ItemReference.Validate("Reference Type", ItemReference."Reference Type"::"Bar Code");
            ItemReference.Validate("Reference No.", _RefNo);
            ItemReference.Insert(true);
        end;
    end;

    // Intentionally named OnItemCrossReference to be consistent with Registration Type
    [IntegrationEvent(false, false)]
    internal procedure OnPostAdhocRegistrationOnItemCrossReference_OnBeforeInsertItemReference(var _RequestValues: Record "MOB NS Request Element"; var _ItemReference: Record "Item Reference")
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnBeforeSearchItemReference(_ScannedBarcode: Code[50]; var _ReturnItemNo: Code[20]; var _ReturnVariantCode: Code[10]; var _ReturnUoMCode: Code[10]; var _IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSearchItemReferenceOnAfterSetFilters(_ScannedBarcode: Code[50]; var _ItemReference: Record "Item Reference")
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnBeforeGetBarcodeList(_ItemNo: Code[20]; _VariantCode: Code[10]; _UoMCode: Code[10]; var _BarcodeListToReturn: Text; var _IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetBarcodeListOnAfterSetFilters(_ItemNo: Code[20]; _VariantCode: Code[10]; _UoMCode: Code[10]; var _ItemReference: Record "Item Reference")
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnAfterGetBarcodeList(_ItemNo: Code[20]; _VariantCode: Code[10]; _UoMCode: Code[10]; var _BarcodeListToReturn: Text)
    begin
    end;

}
