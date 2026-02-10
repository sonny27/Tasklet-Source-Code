codeunit 81386 "MOB ProdUnplConsump_RegPosting"
{
    Access = Internal;

    Permissions =
        tabledata "Production Order" = r,
        tabledata "Prod. Order Line" = r,
        tabledata "MOB Setup" = r,
        tabledata "Source Code" = ri;

    var
        MobToolbox: Codeunit "MOB Toolbox";
        MobWmsLanguage: Codeunit "MOB WMS Language";

    internal procedure Post(var _TempRequestValues: Record "MOB NS Request Element" temporary; var _RegistrationTypeTracking: Text; var _SuccessMessage: Text)
    var
        ItemJnlLine: Record "Item Journal Line";
        MobTrackingSetup: Record "MOB Tracking Setup";
        ProdOrderLine: Record "Prod. Order Line";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
        RegConfig: Codeunit "MOB ProdUnplConsump_RegConfig";
        UoMCode: Code[10];
        VariantCode: Code[10];
        BinCode: Code[20];
        ItemNo: Code[20];
        OrderBackendId: Code[40];
        Quantity: Decimal;
    begin
        Evaluate(OrderBackendId, _TempRequestValues.Get_OrderBackendID(true));
        RegConfig.ValidateProductionOrder(OrderBackendId, ProdOrderLine);

        ItemNo := _TempRequestValues.GetValue('UnplConsumption_ItemNo');
        VariantCode := _TempRequestValues.GetValue('UnplConsumption_Variant');
        UoMCode := _TempRequestValues.GetValue('UnplConsumption_UoM');
        BinCode := MobToolbox.ReadBin(_TempRequestValues.GetValue('UnplConsumption_Bin'));

        ReadAndCheckTracking(_TempRequestValues, MobTrackingSetup, ItemNo, VariantCode);

        if _TempRequestValues.HasValue('UnplConsumption_Quantity') then
            Quantity := _TempRequestValues.GetValueAsDecimal('UnplConsumption_Quantity');
        if MobTrackingSetup."Serial No." <> '' then
            Quantity := 1;

        _RegistrationTypeTracking := CreateRegTypeTrackingText(ProdOrderLine, ItemNo, Quantity);

        CreateItemJnlLine(ItemJnlLine, ProdOrderLine, BinCode, ItemNo, VariantCode, UoMCode, Quantity);
        CreateItemTracking(ItemJnlLine, MobTrackingSetup);

        ItemJnlPostLine.RunWithCheck(ItemJnlLine);
        _SuccessMessage := StrSubstNo(MobWmsLanguage.GetMessage('PROD_UNPL_CONSUMPTION_COMPLETED'), ItemNo, ProdOrderLine."Prod. Order No.", ProdOrderLine."Item No.");
    end;

    internal procedure CreateRegTypeTrackingText(var _ProdOrderLine: Record "Prod. Order Line"; _ItemNo: Code[20]; _Quantity: Decimal): Text
    var
        TrackingTxt: Label '%1 - %2 - %3 %4', Locked = true;
    begin
        exit(StrSubstNo(TrackingTxt, _ProdOrderLine."Prod. Order No.", _ItemNo, MobWmsLanguage.GetMessage('QTY_LABEL'), _Quantity));
    end;

    internal procedure ReadAndCheckTracking(var _TempRequestValues: Record "MOB NS Request Element" temporary; var _MobTrackingSetup: Record "MOB Tracking Setup"; _ItemNo: Code[20]; _VariantCode: Code[10])
    var
        DummyBool: Boolean;
    begin
        _MobTrackingSetup."Serial No." := MobToolbox.ReadSerial(_TempRequestValues.GetValue('UnplConsumption_SerialNumber', false));
        _MobTrackingSetup."Lot No." := MobToolbox.ReadLot(_TempRequestValues.GetValue('UnplConsumption_LotNumber', false));
        _MobTrackingSetup."Package No." := _TempRequestValues.GetValue('UnplConsumption_PackageNumber', false);

        _MobTrackingSetup.DetermineManufOutboundTrackingRequiredFromItemNo(_ItemNo, DummyBool);
        _MobTrackingSetup.CheckTrackingOnInventoryIfRequired(_ItemNo, _VariantCode);
    end;


    internal procedure CreateItemJnlLine(var _ItemJnlLine: Record "Item Journal Line"; var _ProdOrderLine: Record "Prod. Order Line"; _BinCode: Code[20]; _ItemNo: Code[50]; _VariantCode: Code[10]; _UoMCode: Code[10]; _Quantity: Decimal)
    begin
        _ItemJnlLine.Init();
        _ItemJnlLine.Validate("Entry Type", _ItemJnlLine."Entry Type"::Consumption);
        _ItemJnlLine.Validate("Order Type", _ItemJnlLine."Order Type"::Production);
        _ItemJnlLine.Validate("Order No.", _ProdOrderLine."Prod. Order No.");
        _ItemJnlLine.Validate("Order Line No.", _ProdOrderLine."Line No.");
        _ItemJnlLine."Prod. Order Comp. Line No." := 0; // For unplanned consumption, Prod. Order Comp. Line No. is left as 0
        _ItemJnlLine.Validate("Source Code", GetSourceCode());
        _ItemJnlLine.Validate("Posting Date", WorkDate());
        _ItemJnlLine.Validate("Item No.", _ItemNo);
        if _VariantCode <> '' then
            _ItemJnlLine.Validate("Variant Code", _VariantCode);
        _ItemJnlLine.Validate("Location Code", _ProdOrderLine."Location Code");
        if _BinCode <> '' then
            _ItemJnlLine.Validate("Bin Code", _BinCode);
        _ItemJnlLine.Validate("Unit of Measure Code", _UoMCode);
        _ItemJnlLine.Validate(Quantity, _Quantity);
    end;

    internal procedure CreateItemTracking(var _ItemJnlLine: Record "Item Journal Line"; var _MobTrackingSetup: Record "MOB Tracking Setup" temporary)
    var
        ReservationEntry: Record "Reservation Entry";
        TempTrackingSpec: Record "Tracking Specification" temporary;
        MobItemJnlLineReserve: Codeunit "MOB Item Jnl. Line-Reserve";
        MobTrackingSpecReserve: Codeunit "MOB Tracking Spec-Reserve";
    begin
        MobItemJnlLineReserve.InitFromItemJnlLine(TempTrackingSpec, _ItemJnlLine);
        _MobTrackingSetup.CopyTrackingToTrackingSpec(TempTrackingSpec);
        TempTrackingSpec."Expiration Date" := 0D; // Unplanned consumption only supported for Tracking already on inventory (Expiration Date is populated from existing entries)

        if not TempTrackingSpec.TrackingExists() then
            exit;

        MobTrackingSpecReserve.CreateReservation(TempTrackingSpec);
        MobTrackingSpecReserve.GetLastEntry(ReservationEntry);
        _MobTrackingSetup.CopyTrackingFromReservEntry(ReservationEntry);
    end;

    internal procedure GetSourceCode(): Code[10]
    var
        SourceCode: Record "Source Code";
        CodeTok: Label 'MOBUNPCONS', Locked = true;
        DescriptionTxt: Label 'Items consumed using the Mobile Unplanned Consumption', MaxLength = 100, Comment = 'Description for the Source Code record with code MOBUNPCONS';
    begin
        if SourceCode.Get(CodeTok) then
            exit(SourceCode.Code);

        SourceCode.Init();
        SourceCode.Code := CodeTok;
        SourceCode.Description := CopyStr(DescriptionTxt, 1, MaxStrLen(SourceCode.Description));
        SourceCode.Insert(true);
        exit(SourceCode.Code);
    end;
}
