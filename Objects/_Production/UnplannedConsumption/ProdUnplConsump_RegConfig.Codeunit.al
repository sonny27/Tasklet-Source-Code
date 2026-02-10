codeunit 81407 "MOB ProdUnplConsump_RegConfig"
{
    Access = Internal;

    Permissions =
        tabledata "Production Order" = r,
        tabledata "Prod. Order Line" = r,
        tabledata "Prod. Order Component" = r,
        tabledata Item = r,
        tabledata "Item Variant" = r,
        tabledata "MOB Setup" = r;

    var
        MobToolbox: Codeunit "MOB Toolbox";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";

    internal procedure CreateConfiguration(var _HeaderValues: Record "MOB NS Request Element"; var _Steps: Record "MOB Steps Element"; var _RegistrationTypeTracking: Text)
    var
        Item: Record Item;
        ProdOrderLine: Record "Prod. Order Line";
        MobTrackingSetup: Record "MOB Tracking Setup";
        LocationCode: Code[10];
        OrderBackendId: Code[40];
        UoMCode: Code[10];
        VariantCode: Code[10];
        DummyBool: Boolean;
        UseBaseUoM: Boolean;
        StepId: Integer;
    begin
        Evaluate(OrderBackendId, _HeaderValues.Get_OrderBackendID(true));
        ValidateProductionOrder(OrderBackendId, ProdOrderLine);
        LocationCode := ProdOrderLine."Location Code";

        ValidateItem(_HeaderValues.Get_Item(), ProdOrderLine, Item, VariantCode, UoMCode);
        MobTrackingSetup.DetermineManufOutboundTrackingRequiredFromItemNo(Item."No.", DummyBool);
        UseBaseUoM := GetUseBaseUnitFromSetup();

        _RegistrationTypeTracking := CreateRegTypeTrackingText(ProdOrderLine, Item);

        CreateItemStep(_Steps, StepId, Item);

        CreateVariantStep(_Steps, StepId, Item, VariantCode);

        CreateTrackingSteps(_Steps, StepId, Item, MobTrackingSetup);

        CreateBinStep(_Steps, StepId, Item, VariantCode, LocationCode);

        CreateUoMStep(_Steps, StepId, Item, UoMCode, UseBaseUoM, MobTrackingSetup);

        CreateQuantityStep(_Steps, StepId, Item, UoMCode, UseBaseUoM, MobTrackingSetup);
    end;

    internal procedure CreateRegTypeTrackingText(var _ProdOrderLine: Record "Prod. Order Line"; var _Item: Record Item): Text
    var
        TrackingTxt: Label '%1 - %2', Locked = true;
    begin
        exit(StrSubstNo(TrackingTxt, _ProdOrderLine."Prod. Order No.", _Item."No."));
    end;

    internal procedure CreateItemStep(var _Steps: Record "MOB Steps Element"; var _StepId: Integer; var _Item: Record Item)
    begin
        _StepId += 10;
        _Steps.Create_TextStep(_StepId, 'UnplConsumption_ItemNo'); // To differ from context values (Prod. Order Component)
        _Steps.Set_defaultValue(_Item."No.");
        _Steps.Set_visible(false); // Step never visible. It is only needed to transfer found item number from barcode scan
    end;

    internal procedure CreateVariantStep(var _Steps: Record "MOB Steps Element"; var _StepId: Integer; var _Item: Record Item; _VariantCode: Code[10])
    begin
        _StepId += 10;
        _Steps.Create_ListStep_Variant(_StepId, _Item."No.");
        _Steps.Set_name('UnplConsumption_Variant'); // To differ from context values (Prod. Order Component)

        if _VariantCode <> '' then begin
            _Steps.Set_defaultValue(_VariantCode);
            _Steps.Set_visible(false); // Step not visible. Only used to transfer pre-defined Variant from barcode scan
            exit;
        end;
        if not VariantsAvailable(_Item."No.") then
            _Steps.Set_visible(false); // Step not visible if no variants available for the item
    end;

    internal procedure CreateBinStep(var _Steps: Record "MOB Steps Element"; var _StepId: Integer; var _Item: Record Item; _VariantCode: Code[10]; _LocationCode: Code[10])
    var
        WmsAdhocRegistr: Codeunit "MOB WMS Adhoc Registr.";
        Visible: Boolean;
    begin
        _StepId += 10;
        _Steps.Create_TextStep_Bin(_StepId, _LocationCode, _Item."No.", _VariantCode);
        _Steps.Set_name('UnplConsumption_Bin'); // To differ from context values (Prod. Order Component)

        Visible := WmsAdhocRegistr.TestBinMandatory(_LocationCode); // Step only visible if Bin is mandatory in the Location
        if _Item.IsNonInventoriableType() then // Step not visible for Non-Inventoriable Items
            Visible := false;
        _Steps.Set_visible(Visible);
    end;

    internal procedure CreateUoMStep(var _Steps: Record "MOB Steps Element"; var _StepId: Integer; var _Item: Record Item; _UoMCode: Code[10]; _UseBaseUoM: Boolean; var _MobTrackingSetup: Record "MOB Tracking Setup" temporary)
    begin
        _StepId += 10;
        _Steps.Create_ListStep_UoM(_StepId, _Item."No.");
        _Steps.Set_name('UnplConsumption_UoM'); // To differ from context values (Prod. Order Component)

        case true of
            _UseBaseUoM or _MobTrackingSetup."Serial No. Required":
                begin
                    _UoMCode := _Item."Base Unit of Measure";
                    _Steps.Set_defaultValue(_UoMCode);
                    _Steps.Set_visible(false); // Step not visible if always using Base UoM
                end;
            _UoMCode <> '':
                begin
                    _Steps.Set_defaultValue(_UoMCode);
                    _Steps.Set_visible(false); // Step not visible if UoM is pre-defined from barcode scan (Item Reference)
                end;
            not MobWmsToolbox.GetItemHasMultipleUoM(_Item."No."):
                begin
                    _UoMCode := _Item."Base Unit of Measure";
                    _Steps.Set_defaultValue(_UoMCode);
                    _Steps.Set_visible(false); // Step not visible if Item only have one UoM (Base UoM)
                end;
        end;
    end;

    internal procedure CreateQuantityStep(var _Steps: Record "MOB Steps Element"; var _StepId: Integer; var _Item: Record Item; _UoMCode: Code[10]; _UseBaseUoM: Boolean; var _MobTrackingSetup: Record "MOB Tracking Setup" temporary)
    var
        InfoUoMCode: Code[10];
    begin
        _StepId += 10;
        _Steps.Create_DecimalStep_Quantity(_StepId, _Item."No.");
        _Steps.Set_name('UnplConsumption_Quantity'); // To differ from context values (Prod. Order Component)
        _Steps.Set_minValue(0.0000000001);

        if _MobTrackingSetup."Serial No. Required" then begin // Step not visible for serial tracked items (quantity always 1)
            _Steps.Set_visible(false);
            _Steps.Set_defaultValue(1);
            exit;
        end;

        if _UoMCode <> '' then
            InfoUoMCode := _UoMCode;
        if _UseBaseUoM then
            InfoUoMCode := _Item."Base Unit of Measure";
        if InfoUoMCode <> '' then
            _Steps.Set_helpLabel(MobWmsLanguage.GetMessage('UOM_LABEL') + ': ' + InfoUoMCode);
    end;

    internal procedure CreateTrackingSteps(var _Steps: Record "MOB Steps Element"; var _StepId: Integer; var Item: Record Item; var _MobTrackingSetup: Record "MOB Tracking Setup" temporary)
    begin
        _StepId += 10;
        _Steps.Create_TrackingStepsIfRequired(_MobTrackingSetup, _StepId, Item."No.");

        if _Steps.GetByName('SerialNumber', false) then begin
            _Steps.Set_name('UnplConsumption_SerialNumber'); // To differ from context values (Prod. Order Component)
            _Steps.Save();
        end;

        if _Steps.GetByName('LotNumber', false) then begin
            _Steps.Set_name('UnplConsumption_LotNumber'); // To differ from context values (Prod. Order Component)
            _Steps.Save();
        end;

        if _Steps.GetByName('PackageNumber', false) then begin
            _Steps.Set_name('UnplConsumption_PackageNumber'); // To differ from context values (Prod. Order Component)
            _Steps.Save();
        end;
    end;

    internal procedure ValidateProductionOrder(_OrderBackendId: Code[40]; var _ProdOrderLine: Record "Prod. Order Line")
    var
        ProdOrder: Record "Production Order";
        ProdOrderNo: Code[20];
        ProdOrderLineNo: Integer;
    begin
        MobWmsToolbox.GetOrderNoAndOrderLineNoFromBackendId(_OrderBackendId, ProdOrderNo, ProdOrderLineNo);

        /* #if BC22+ */
        ProdOrder.ReadIsolation(IsolationLevel::ReadCommitted);
        ProdOrder.SetLoadFields("Status", "No.");
        /* #endif */
        ProdOrder.Get(ProdOrder.Status::Released, ProdOrderNo);

        /* #if BC22+ */
        _ProdOrderLine.ReadIsolation(IsolationLevel::ReadCommitted);
        _ProdOrderLine.SetBaseLoadFields();
        /* #endif */
        _ProdOrderLine.Get(ProdOrder.Status, ProdOrder."No.", ProdOrderLineNo);
    end;

    internal procedure ValidateItem(_ItemBarcode: Code[20]; _ProdOrderLine: Record "Prod. Order Line"; var _Item: Record Item; var _VariantCode: Code[10]; var _UoMCode: Code[10])
    var
        ProdOrderComponent: Record "Prod. Order Component";
        MobItemReferenceMgt: Codeunit "MOB Item Reference Mgt.";
        ItemNumber: Code[50];
        ItemIsComponentErr: Label 'Item %1 is a component of the production order line and cannot be used for unplanned consumption.', Comment = '%1 = Item Number';
    begin
        ItemNumber := MobItemReferenceMgt.SearchItemReference(MobToolbox.ReadEAN(_ItemBarcode), _VariantCode, _UoMCode, true);
        /* #if BC22+ */
        _Item.ReadIsolation(IsolationLevel::ReadCommitted);
        _Item.SetBaseLoadFields();
        /* #endif */
        _Item.Get(ItemNumber);

        /* #if BC22+ */
        ProdOrderComponent.ReadIsolation(IsolationLevel::ReadCommitted);
        /* #endif */
        ProdOrderComponent.SetRange(Status, _ProdOrderLine.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", _ProdOrderLine."Prod. Order No.");
        ProdOrderComponent.SetRange("Prod. Order Line No.", _ProdOrderLine."Line No.");
        ProdOrderComponent.SetRange("Item No.", _Item."No.");
        ProdOrderComponent.SetRange("Variant Code", _VariantCode);
        if not ProdOrderComponent.IsEmpty() then
            Error(ItemIsComponentErr, ItemNumber);
    end;

    internal procedure VariantsAvailable(_ItemNo: Code[20]): Boolean
    var
        ItemVariant: Record "Item Variant";
    begin
        /* #if BC22+ */
        ItemVariant.ReadIsolation(IsolationLevel::ReadCommitted);
        /* #endif */
        ItemVariant.SetRange("Item No.", _ItemNo);
        exit(not ItemVariant.IsEmpty());
    end;

    internal procedure GetUseBaseUnitFromSetup(): Boolean
    var
        MobSetup: Record "MOB Setup";
    begin
        /* #if BC22+ */
        MobSetup.ReadIsolation(IsolationLevel::ReadCommitted);
        MobSetup.SetLoadFields("Use Base Unit of Measure");
        /* #endif */
        MobSetup.Get();
        exit(MobSetup."Use Base Unit of Measure");
    end;
}
