codeunit 81370 "MOB Test Helper"
{
    Access = Public;
    // // 1: Run the test-helper to Purchase Orders, and then process them before creating Transfer Orders (the purchased quantities are required to fulfill the Transfer Orders' quantities).
    // // 2: Run the test-helper to create Transfer Orders and then process them.
    // // 3: When the Transfer Orders are processed on the mobile device, create the sales orders.
    // // 4: Assembly Orders can be created when BaseData has been created.

    // // Package No. currently not supported in TestHelper

    Permissions = tabledata "Item Ledger Entry" = rimd;

    trigger OnRun()
    begin
        SetupPartnerTestData();
    end;

    var
        MobToolbox: Codeunit "MOB Toolbox";
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
        Localization: Codeunit "MOB WMS Test Localization";
        CreatedMsg: Label '%1 has been created.', Comment = '%1 contains message', Locked = true;
#pragma warning disable LC0055 // They are messages and not tokens
        TestDataLbl: Label 'Test data', Locked = true;
        SalesDataLbl: Label 'Sales data', Locked = true;
        PurchaseDataLbl: Label 'Purchase data', Locked = true;
        TransferDataLbl: Label 'Transfer data', Locked = true;
        AssemblyDataLbl: Label 'Assembly data', Locked = true;
        ProductionDataLbl: Label 'Production data', Locked = true;
        WhseInternalPicksLbl: Label 'Whse. Internal Picks', Locked = true;
#pragma warning restore LC0055
        MobileSetupLbl: Label 'Mobile WMS Setup Updated', Locked = true;
        OpenWhseShipmentExistsErr: Label 'The warehouse shipment was not created because an open warehouse shipment exists for the Sales Header and Shipping Advice is %1.\\You must add the item(s) as new line(s) to the existing warehouse shipment or change Shipping Advice to Partial.', Comment = '%1 contains value of shipping advice', Locked = true;
        InvalidLocationCreateTransgerOrderErr: Label 'CreateTransferOrder with _PostShipment only implemented for FromLocation=WHITE.', Locked = true;
        AssertTempRecNotTempErr: Label 'AssertTemporaryRecord failed. _TestData must be a temporary record.', Locked = true;
        HideMessages: Boolean;

    //
    // ----- TEST HELPER -----
    //

    local procedure SetupPartnerTestData()
    begin
        // <---------- Basic (master) data ---------->
        SetupAllBaseData();

        // <---------- Orders ---------->
        SetupTestOrderPurchase();
        SetupTestOrderTransfer();
        SetupTestOrderSales();
        SetupTestOrderAssembly();
        SetupTestOrderProduction();
    end;

    /// <remarks>
    /// For INVBIN a default BinContent or populated PurchaseLine."Bin Code" must exist or no Invt. PutAway is created (since BC23 = 2023 Wave2)
    /// All TF-* items created by TestHelper will have a default BinContent at INVBIN ('S-01-0001'), hence leaving SourceLineBin parameter blank here.
    /// </remarks>
    internal procedure SetupTestOrderPurchase()
    begin
        CreatePurchaseOrder('10000', Localization.BLUE(), '');    // (10000 = London Postmaster - No default Location)
        CreatePurchaseOrder('10000', Localization.INVBIN(), '');  // INVBIN = Create Put-Away
        CreatePurchaseOrder('10000', Localization.WHITE(), '');   // WHITE  = Create Whse Receipt Lines

        DisplayCreatedMessage(PurchaseDataLbl);
    end;

    /// <remarks>
    /// For INVBIN a default BinContent or populated PurchaseLine."Bin Code" must exist or no Invt. PutAway is created (since BC23 = 2023 Wave2)
    /// All TF-* items created by TestHelper will have a default BinContent at INVBIN ('S-01-0001'), hence leaving SourceLineBin parameter blank here.
    /// </remarks>
    internal procedure SetupTestOrderPurchase_BOX()
    begin
        CreatePurchaseOrder_BOX('10000', Localization.BLUE(), '');   // (10000 = London Postmaster - No default Location)
        CreatePurchaseOrder_BOX('10000', Localization.INVBIN(), ''); // INVBIN = Create Put-Away
        CreatePurchaseOrder_BOX('10000', Localization.WHITE(), '');  // WHITE  = Create Whse Receipt Lines

        DisplayCreatedMessage(PurchaseDataLbl);
    end;


    internal procedure SetupTestOrderTransfer()
    var
        TempTestData: Record "MOB Test Data" temporary;
    begin
        // Create transfer order from BLUE to INVBIN
        CreateData_Small_Warehouse(TempTestData, Localization.BLUE(), '', '', true, true);
        CreateTransferOrder(TempTestData, Localization.BLUE(), Localization.INVBIN(), false);

        // Create transfer order from INVBIN to WHITE
        CreateData_Small_Warehouse(TempTestData, Localization.INVBIN(), 'S-01-0001', 'W-01-0001', true, true);
        CreateTransferOrder(TempTestData, Localization.INVBIN(), Localization.WHITE(), false);

        // Create transfer order from WHITE to BLUE
        CreateData_Small_Warehouse(TempTestData, Localization.WHITE(), 'W-01-0001', '', true, true);
        CreateTransferOrder(TempTestData, Localization.WHITE(), Localization.BLUE(), false);

        DisplayCreatedMessage(TransferDataLbl);
    end;

    internal procedure SetupTestOrderTransfer_BOX()
    var
        TempTestData: Record "MOB Test Data" temporary;
    begin
        // Create transfer order from BLUE to INVBIN
        CreateData_Small_Warehouse_BOX(TempTestData, Localization.BLUE(), '', '', true, true);
        CreateTransferOrder(TempTestData, Localization.BLUE(), Localization.INVBIN(), false);

        // Create transfer order from INVBIN to WHITE
        CreateData_Small_Warehouse_BOX(TempTestData, Localization.INVBIN(), 'S-01-0001', 'W-01-0001', true, true);
        CreateTransferOrder(TempTestData, Localization.INVBIN(), Localization.WHITE(), false);

        // Create transfer order from WHITE to BLUE
        CreateData_Small_Warehouse_BOX(TempTestData, Localization.WHITE(), 'W-01-0001', '', true, true);
        CreateTransferOrder(TempTestData, Localization.WHITE(), Localization.BLUE(), false);

        DisplayCreatedMessage(TransferDataLbl);
    end;

    internal procedure SetupTestOrderSales()
    begin
        //Create sales order for BLUE
        CreateSalesOrder('20000', Localization.BLUE(), 0); // (20000 = Selangorian Ltd. - No default Location)

        //Create sales order for INVBIN
        CreateSalesOrder('20000', Localization.INVBIN(), 0);

        //Create sales order WHITE
        CreateSalesOrder('20000', Localization.WHITE(), 0);

        DisplayCreatedMessage(SalesDataLbl);
    end;

    internal procedure SetupTestOrderSales_BOX()
    begin
        CreateSalesOrder_BOX('20000', Localization.BLUE()); // (20000 = Selangorian Ltd. - No default Location)
        CreateSalesOrder_BOX('20000', Localization.INVBIN());
        CreateSalesOrder_BOX('20000', Localization.WHITE());

        DisplayCreatedMessage(SalesDataLbl);
    end;

    // Setup Mobile WMS for Tote Pick
    internal procedure SetupMobileWMSForTotePick()
    begin
        SetupMobileSetupForTotePick();
        Message(MobileSetupLbl);
    end;

    // Create Sales Orders for Tote Pick
    internal procedure SetupTestOrderSales_TotePick()
    begin
        CreateSalesOrder_WHITE_TotePick('20000');
        DisplayCreatedMessage(SalesDataLbl);
    end;

    //
    // ----- ORDER ------
    //

    internal procedure CreatePurchaseOrders(_NoOfOrders: Integer; _NoOfLines: Integer; _Location: Code[20]; _SourceLineBin: Code[10])
    var
        i: Integer;
    begin
        // Create a number of purchase orders
        repeat
            i += 1;

            case _Location of
                Localization.WHITE(),  // WHITE  = Create Whse Receipt Lines
                Localization.INVBIN(): // INVBIN = Create Put-Away
                    CreatePurchaseOrder('10000', _Location, _SourceLineBin, _NoOfLines);
                else
                    CreatePurchaseOrder('10000', Localization.BLUE(), _SourceLineBin, _NoOfLines); // No dedicated warehouse activities
            end;

        until i >= _NoOfOrders;

        DisplayCreatedMessage(PurchaseDataLbl);
    end;

    procedure CreatePurchaseOrder(_VendorNo: Code[20]; _LocationCode: Code[20]; _SourceLineBin: Code[10]): Code[20]
    begin
        exit(CreatePurchaseOrder(_VendorNo, _LocationCode, _SourceLineBin, 0 /*NoOfLines*/));
    end;

    procedure CreatePurchaseOrder(_VendorNo: Code[20]; _LocationCode: Code[20]; _NoOfLines: Integer): Code[20]
    begin
        exit(CreatePurchaseOrder(_VendorNo, _LocationCode, '' /*SourceLineBinCode*/, _NoOfLines));
    end;

    local procedure CreatePurchaseOrder(_VendorNo: Code[20]; _LocationCode: Code[20]; _SourceLineBinCode: Code[10]; _NoOfLines: Integer): Code[20]
    var
        TempTestData: Record "MOB Test Data" temporary;
        SetsOfLines: Integer;
        i: Integer;
    begin
        // 1. Create a Purchase Order and release it
        // 2. Create a Warehouse Receipt from the Purchase Order if applicable        

        // Create Test Data
        // Use "sets of three"
        if _NoOfLines = 0 then
            CreateData_Small_PurchaseOrder(TempTestData, _LocationCode, '', '', _SourceLineBinCode, false, true)
        else begin
            SetsOfLines := Round(_NoOfLines / 3, 1, '=');
            repeat
                i += 1;
                TempTestData.AddLine('Small_PurchaseOrder', _LocationCode, '', '', _SourceLineBinCode, 'TF-002', '', 0D, '', Localization.UoM_PCS(), false, 0, 15);
                TempTestData.AddLine('Small_PurchaseOrder', _LocationCode, '', '', _SourceLineBinCode, 'TF-003', '', WorkDate(), '', Localization.UoM_PCS(), false, 0, 15);
                TempTestData.AddLine('Small_PurchaseOrder', _LocationCode, '', '', _SourceLineBinCode, 'TF-004', '', 0D, '', Localization.UoM_PCS(), false, 0, 3);
            until i >= SetsOfLines;
        end;

        // Create Order
        exit(CreatePurchaseOrder(_VendorNo, _LocationCode, TempTestData, false));
    end;

    local procedure CreatePurchaseOrder_BOX(_VendorNo: Code[20]; _LocationCode: Code[20]; _SourceLineBin: Code[10]): Code[20]
    var
        TempTestData: Record "MOB Test Data" temporary;
    begin
        // Create a Purchase Order for alternative UoM::BOX and release it
        // Create a Warehouse Receipt from the Purchase Order if applicable        

        CreateData_Small_PurchaseOrder_BOX(TempTestData, _LocationCode, '', '', _SourceLineBin, false, true);
        exit(CreatePurchaseOrder(_VendorNo, _LocationCode, TempTestData, false));
    end;

    procedure CreatePurchaseOrder(_VendorNo: Code[20]; _LocationCode: Code[20]; var _TestData: Record "MOB Test Data" temporary): Code[20]
    begin
        exit(CreatePurchaseOrder(_VendorNo, _LocationCode, _TestData, false));
    end;

    local procedure CreatePurchaseOrder(_VendorNo: Code[20]; _LocationCode: Code[20]; var _TestData: Record "MOB Test Data" temporary; _CreateWithItemTracking: Boolean): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        Location: Record Location;
        WhseRequest: Record "Warehouse Request";
        TempCreateTestData: Record "MOB Test Data" temporary;
        CreateInvtPutawayPickMvmt: Report "Create Invt Put-away/Pick/Mvmt";
        ReleasePurchDoc: Codeunit "Release Purchase Document";
        GetSourceDocInbound: Codeunit "Get Source Doc. Inbound";
    begin
        // 1. Create a Purchase Order and release it
        // 2. Create a Warehouse Receipt from the Purchase Order if applicable

        // Create Order
        PurchaseHeader.Init();
        PurchaseHeader.Validate("Document Type", PurchaseHeader."Document Type"::Order);
        PurchaseHeader.Insert(true);

        // Set Vendor
        PurchaseHeader.Validate("Buy-from Vendor No.", _VendorNo);
        PurchaseHeader.Validate("Location Code", _LocationCode);
        PurchaseHeader.Validate("Expected Receipt Date", 20180101D);
        PurchaseHeader.Modify(true);

        // Create Lines
        if _TestData.FindSet() then
            repeat
                TempCreateTestData.Copy(_TestData);
                CreatePurchaseOrderLine(PurchaseHeader, TempCreateTestData, _CreateWithItemTracking);
            until _TestData.Next() = 0;

        _TestData.Copy(TempCreateTestData, true);

        // Release the Purchase Order
        ReleasePurchDoc.Run(PurchaseHeader);

        // Create the Warehouse Receipt or Inventory Put-away if applicable
        Location.Get(PurchaseHeader."Location Code");
        if Location."Require Receive" then
            GetSourceDocInbound.CreateFromPurchOrderHideDialog(PurchaseHeader)
        else
            if Location."Require Put-away" then begin
                WhseRequest.SetRange("Source No.", PurchaseHeader."No.");
                CreateInvtPutawayPickMvmt.SetTableView(WhseRequest);
                CreateInvtPutawayPickMvmt.InitializeRequest(true, false, false, false, false);
                CreateInvtPutawayPickMvmt.SuppressMessages(true);
                CreateInvtPutawayPickMvmt.UseRequestPage(false);
                CreateInvtPutawayPickMvmt.RunModal();
            end;

        exit(PurchaseHeader."No.");
    end;

    local procedure CreatePurchaseOrderLine(_PurchaseHeader: Record "Purchase Header"; var _TestData: Record "MOB Test Data" temporary; _CreateWithItemTracking: Boolean)
    var
        PurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        MobTrackingSetup: Record "MOB Tracking Setup";
        CreateReservationEntry: Codeunit "Create Reserv. Entry";
        LineNo: Integer;
        RegisterExpirationDate: Boolean;
    begin
        if _TestData."Ref. Line No." <> 0 then begin
            PurchaseLine.SetRange("Document Type", _PurchaseHeader."Document Type");
            PurchaseLine.SetRange("Document No.", _PurchaseHeader."No.");
            PurchaseLine.SetRange("Line No.", _TestData."Ref. Line No.");
        end;

        if PurchaseLine.FindSet() and (_TestData."Ref. Line No." <> 0) then begin
            PurchaseLine.Validate(Quantity, PurchaseLine.Quantity + _TestData."Qty. To Handle");
            PurchaseLine.Modify(true);
        end else begin
            PurchaseLine.Reset();
            PurchaseLine.Init();
            PurchaseLine."Document Type" := _PurchaseHeader."Document Type";
            PurchaseLine."Document No." := _PurchaseHeader."No.";
            if _TestData."Ref. Line No." <> 0 then
                LineNo := _TestData."Ref. Line No."
            else
                LineNo += 10000;
            PurchaseLine."Line No." := LineNo;

            PurchaseLine.Validate(Type, PurchaseLine.Type::Item);
            PurchaseLine.Validate("No.", _TestData."Item No.");
            PurchaseLine.Validate("Unit of Measure Code", _TestData."Unit of Measure Code");
            PurchaseLine.Validate(Quantity, _TestData."Qty. To Handle");
            if _TestData."Source Line Bin Code" <> '' then
                PurchaseLine.Validate("Bin Code", _TestData."Source Line Bin Code");
            PurchaseLine.Insert(true);
        end;

        if _CreateWithItemTracking then begin

            MobTrackingSetup.DetermineItemTrackingRequiredByPurchaseLine(PurchaseLine, RegisterExpirationDate);
            MobTrackingSetup.CopyTrackingFromTestData(_TestData);

            if MobTrackingSetup.TrackingRequired() then begin

                // The function expects the quantity to be in the base UoM
                MobTrackingSetup.CreateReservEntryFor(
                    CreateReservationEntry,
                    Database::"Purchase Line",
                    MobToolbox.AsInteger(PurchaseLine."Document Type"),
                    PurchaseLine."Document No.",
                    '', // ForBatchName
                    0,  // ForProdOrderLine
                    PurchaseLine."Line No.",  // SourceLineNo
                    PurchaseLine."Qty. per Unit of Measure",
                    PurchaseLine.Quantity,
                    PurchaseLine."Quantity (Base)");

                // If the ExpirationDate is registered it must be set on the reservation entry
                if RegisterExpirationDate then
                    CreateReservationEntry.SetDates(0D, WorkDate());

                CreateReservationEntry.CreateEntry(PurchaseLine."No.",
                                                   PurchaseLine."Variant Code",
                                                   PurchaseLine."Location Code",
                                                   '',   //Description
                                                   0D,
                                                   WorkDate(),
                                                   0,  // Tranferred from entry no.
                                                   ReservationEntry."Reservation Status"::Prospect);

            end;
        end;

        _TestData.Code := PurchaseLine."Document No.";
        _TestData."Ref. Line No." := PurchaseLine."Line No.";
        _TestData.Insert();
    end;

    procedure CreateTransferOrder(_FromLocationCode: Code[10]; _ToLocationCode: Code[10]; _PostShipment: Boolean): Code[20]
    var
        TempTestData: Record "MOB Test Data" temporary;
    begin
        CreateData_Small_NonWarehouse(TempTestData, _FromLocationCode, true, true);

        exit(CreateTransferOrder(TempTestData, _FromLocationCode, _ToLocationCode, _PostShipment));
    end;

    procedure CreateTransferOrder(var _TestData: Record "MOB Test Data" temporary; _FromLocationCode: Code[10]; _ToLocationCode: Code[10]; _PostShipment: Boolean): Code[20]
    var
        TransferHeader: Record "Transfer Header";
        Location: Record Location;
        WhseRequest: Record "Warehouse Request";
        WhseActivityLine: Record "Warehouse Activity Line";
        WhseShipmentLine: Record "Warehouse Shipment Line";
        MobTrackingSetup: Record "MOB Tracking Setup";
        TempCreateTestData: Record "MOB Test Data" temporary;
        CreateInvtPutawayPickMvmt: Report "Create Invt Put-away/Pick/Mvmt";
        ReleaseTransferDocument: Codeunit "Release Transfer Document";
        GetSourceDocOutbound: Codeunit "Get Source Doc. Outbound";
        WhseActivityRegister: Codeunit "Whse.-Activity-Register";
        WhsePostShipment: Codeunit "Whse.-Post Shipment";
    begin
        // 1. Create a Transfer Order and release it
        // 2. Create a Warehouse Receipt, if applicable

        // Create Order
        TransferHeader.Init();
        TransferHeader.Insert(true);

        // Set the Vendor (London Postmaster - No default Location)
        TransferHeader.Validate("Transfer-from Code", _FromLocationCode);
        TransferHeader.Validate("Transfer-to Code", _ToLocationCode);
        TransferHeader.Validate("In-Transit Code", 'OWN LOG.');
        TransferHeader.Modify(true);

        // Create Lines
        if _TestData.FindSet() then
            repeat
                TempCreateTestData.Copy(_TestData);
                CreateTransferOrderLine(TransferHeader, TempCreateTestData);
            until _TestData.Next() = 0;

        _TestData.Copy(TempCreateTestData, true);

        // Release
        ReleaseTransferDocument.Run(TransferHeader);

        // Create the Warehouse Shipment/Pick or Inventory Pick if applicable
        Location.Get(TransferHeader."Transfer-from Code");
        if Location."Require Shipment" then begin
            GetSourceDocOutbound.CreateFromOutbndTransferOrder(TransferHeader);
            ReleaseWhseShipment(Database::"Transfer Line", 0, TransferHeader."No.");
            if Location."Require Pick" then
                CreateWhsePick(Database::"Transfer Line", 0, TransferHeader."No.");
        end else
            if Location."Require Pick" then begin
                WhseRequest.SetRange("Source No.", TransferHeader."No.");
                CreateInvtPutawayPickMvmt.SetTableView(WhseRequest);
                CreateInvtPutawayPickMvmt.InitializeRequest(false, true, false, false, false);
                CreateInvtPutawayPickMvmt.SuppressMessages(true);
                CreateInvtPutawayPickMvmt.UseRequestPage(false);
                CreateInvtPutawayPickMvmt.RunModal();
            end;

        if _PostShipment then
            if Location."Require Shipment" and Location."Require Pick" then begin
                // WHITE (no pick document was created for BLUE or INVBIN)
                if _FromLocationCode <> Localization.WHITE() then
                    Error(InvalidLocationCreateTransgerOrderErr);

                FindWhseActivityLine(
                    WhseActivityLine,
                    MobToolbox.AsInteger(WhseActivityLine."Activity Type"::Pick),
                    MobToolbox.AsInteger(WhseActivityLine."Action Type"::Take),
                    _FromLocationCode,
                    TransferHeader."No.");

                // Set Warehouse Pick LotNo's and SerialNo's at TAKE+PLACE lines                
                WhseActivityLine.SetRange("Source No.", TransferHeader."No.");
                WhseActivityLine.SetRange("Action Type");
                _TestData.SetCurrentKey("Code", "Ref. Line No.", "Line No.");
                if _TestData.FindSet() then
                    repeat

                        MobTrackingSetup.ClearTrackingRequired();
                        MobTrackingSetup.CopyTrackingFromTestData(_TestData);

                        _TestData.SetRange("Ref. Line No.", _TestData."Ref. Line No.");
                        WhseActivityLine.SetRange("Source Line No.", _TestData."Ref. Line No.");
                        if WhseActivityLine.FindSet() then
                            repeat
                                MobTrackingSetup.CopyTrackingToWhseActivityLine(WhseActivityLine);
                                WhseActivityLine.Modify(true);

                                // Place Line is the next line
                                WhseActivityLine.Next();
                                MobTrackingSetup.CopyTrackingToWhseActivityLine(WhseActivityLine);
                                WhseActivityLine.Modify(true);
                            until (WhseActivityLine.Next() = 0) or (_TestData.Next() = 0);
                        _TestData.FindLast();
                        _TestData.SetRange("Ref. Line No.");
                    until _TestData.Next() = 0;

                // Post pick
                WhseActivityLine.Reset();
                WhseActivityLine.SetRange("Activity Type", WhseActivityLine."Activity Type");
                WhseActivityLine.SetRange("No.", WhseActivityLine."No.");
                WhseActivityRegister.Run(WhseActivityLine);

                // Post shipment
                FindWarehouseShipmentLine(WhseShipmentLine, MobToolbox.AsInteger(WhseShipmentLine."Source Document"::"Outbound Transfer"), TransferHeader."No.");
                Clear(WhsePostShipment);
                WhsePostShipment.SetPostingSettings(true);    // Invoice
                WhsePostShipment.SetPrint(false);
                WhsePostShipment.Run(WhseShipmentLine);
            end;

        exit(TransferHeader."No.");
    end;

    procedure SetupTestOrderAssembly()
    var
        TempTestData: Record "MOB Test Data" temporary;
    begin
        //Create assembly orders for BLUE
        CreateData_AssemblyOrder(TempTestData, 'TF-009', 2, Localization.BLUE(), '', '', true, false);
        CreateAssemblyOrder(TempTestData, 'TF-009', 2, Localization.BLUE(), false);

        CreateData_AssemblyOrder(TempTestData, 'TF-009', 2, Localization.BLUE(), '', '', true, false);
        CreateAssemblyOrder(TempTestData, 'TF-009', 2, Localization.BLUE(), true); // With Tracking pre-defined        

        //Create assembly orders for INVBIN
        CreateData_AssemblyOrder(TempTestData, 'TF-009', 2, Localization.INVBIN(), 'S-01-0001', '', true, false);
        CreateAssemblyOrder(TempTestData, 'TF-009', 2, Localization.INVBIN(), false);

        CreateData_AssemblyOrder(TempTestData, 'TF-009', 2, Localization.INVBIN(), 'S-01-0001', '', true, false);
        CreateAssemblyOrder(TempTestData, 'TF-009', 2, Localization.INVBIN(), true); // With Tracking pre-defined        

        //Create assembly orders WHITE
        CreateData_AssemblyOrder(TempTestData, 'TF-009', 2, Localization.WHITE(), 'W-01-0001', '', true, false);
        CreateAssemblyOrder(TempTestData, 'TF-009', 2, Localization.WHITE(), false);

        CreateData_AssemblyOrder(TempTestData, 'TF-009', 2, Localization.WHITE(), 'W-01-0001', '', true, false);
        CreateAssemblyOrder(TempTestData, 'TF-009', 2, Localization.WHITE(), true); // With Tracking pre-defined        

        DisplayCreatedMessage(AssemblyDataLbl);
    end;

    procedure CreateAssemblyOrder(var _TestData: Record "MOB Test Data"; _ItemNo: Code[20]; _QtyToAssemble: Decimal; _LocationCode: Code[20]; _CreateTracking: Boolean): Code[20]
    var
        Location: Record Location;
        AssemblyHeader: Record "Assembly Header";
        WhseActHeader: Record "Warehouse Activity Header";
        WhseActLine: Record "Warehouse Activity Line";
        ReleaseAssemblyDoc: Codeunit "Release Assembly Document";
        WhseActivityRegister: Codeunit "Whse.-Activity-Register";
        ATOMovementsCreated: Integer;
        TotalATOMovementsToBeCreated: Integer;

    begin
        Location.Get(_LocationCode);

        // Create Assembly Order
        AssemblyHeader.Init();
        AssemblyHeader.Validate("Document Type", AssemblyHeader."Document Type"::Order);
        AssemblyHeader.Insert(true);

        // Set Addition Header info        
        AssemblyHeader.Validate("Due Date", CalcDate('<1M>', WorkDate()));
        AssemblyHeader.Validate("Location Code", _LocationCode);
        AssemblyHeader.Validate("Item No.", _ItemNo);

        AssemblyHeader.SetWarningsOff();   // New "Rollback := not (AssemblyAvailability.RunModal = ACTION::Yes);" in AssemblyLineManagement.ShowAvailability from BC 19
        AssemblyHeader.Validate(Quantity, _QtyToAssemble);  // Trigger the creation of Assembly Lines based on BOM

        AssemblyHeader.Modify(true);

        // Apply Item Tracking to Lines if applicable        
        if _CreateTracking then
            AddTrackingToAssemblyOrderLines(AssemblyHeader, _TestData);

        // Release the Assembly Order
        ReleaseAssemblyDoc.Run(AssemblyHeader);

        // Handle Inv. Movement if applicable (INVBIN)
        if Location."Require Pick" and not Location."Require Shipment" then begin

            //Create Inv. Movement
            AssemblyHeader.CreateInvtMovement(true, false, false, ATOMovementsCreated, TotalATOMovementsToBeCreated);

            // Register Inv. Movement
            if _CreateTracking and WhseActHeader.Get(WhseActHeader.Type::"Invt. Movement", GetFirstAssemblyOrderConsumptionInvMovNo(AssemblyHeader."No.")) then begin
                WhseActLine.Reset();
                WhseActLine.SetRange("Activity Type", WhseActHeader.Type);
                WhseActLine.SetRange("No.", WhseActHeader."No.");
                if WhseActLine.FindFirst() then begin
                    WhseActLine.AutofillQtyToHandle(WhseActLine);
                    WhseActivityRegister.Run(WhseActLine);
                end;
            end;
        end;

        // Handle Pick if applicable (WHITE)
        if Location."Require Pick" and Location."Require Shipment" then begin

            // Create Pick            
            AssemblyHeader.CreatePick(false, '', 0, false, false, false);

            // Register Pick
            if _CreateTracking and WhseActHeader.Get(WhseActHeader.Type::Pick, GetFirstAssemblyOrderConsumptionPickNo(AssemblyHeader."No.")) then begin
                WhseActLine.Reset();
                WhseActLine.SetRange("No.", WhseActHeader."No.");
                WhseActLine.SetRange("Activity Type", WhseActHeader.Type);
                if WhseActLine.FindFirst() then begin
                    WhseActLine.AutofillQtyToHandle(WhseActLine);
                    WhseActivityRegister.Run(WhseActLine);
                end;
            end;
        end;

        exit(AssemblyHeader."No.");
    end;

    procedure CreateData_AssemblyOrder(var _TestData: Record "MOB Test Data"; _ItemNo: Code[20]; _QtyToAssemble: Decimal; _LocationCode: Code[10]; _FromBin: Code[20]; _ToBin: Code[20]; _CreateInventory: Boolean; _SetExpirationDate: Boolean)
    var
        BOMComp: Record "BOM Component";
        MobTrackingSetup: Record "MOB Tracking Setup";
        Name: Code[50];
        ExpDateRequired: Boolean;
        Quantity: Decimal;
        SNCount: Integer;
    begin

        //Cleanup Dataset
        _TestData.DeleteAll();

        Name := 'AssemblyOrder';
        AssertTemporaryRecord(_TestData);

        // Create Testdata matching BOM content
        BOMComp.SetRange("Parent Item No.", _ItemNo);
        // Filter needed - posible to create BOM Component without Quantity per specified
        BOMComp.SetFilter("Quantity per", '<>%1', 0);
        BOMComp.SetRange(Type, BOMComp.Type::Item);
        if BOMComp.FindSet() then
            repeat
                Quantity := _QtyToAssemble * BOMComp."Quantity per";

                Clear(MobTrackingSetup);
                MobTrackingSetup.DetermineSpecificTrackingRequiredFromItemNo(BOMComp."No.", ExpDateRequired);
                // MobTrackingSetup.Tracking: Tracking values are unused in this scope

                if not (MobTrackingSetup."Serial No. Required" or MobTrackingSetup."Lot No. Required") then
                    _TestData.AddLineWithRef(Name, 0, BOMComp."Line No.", _LocationCode, _FromBin, _ToBin, BOMComp."No.", '', 0D, '', Localization.UoM_PCS(), _CreateInventory, 100, Quantity);

                if MobTrackingSetup."Lot No. Required" then
                    if _SetExpirationDate then
                        _TestData.AddLineWithRef(Name, 0, BOMComp."Line No.", _LocationCode, _FromBin, _ToBin, BOMComp."No.", '*', WorkDate(), '', Localization.UoM_PCS(), _CreateInventory, Quantity, Quantity)
                    else
                        _TestData.AddLineWithRef(Name, 0, BOMComp."Line No.", _LocationCode, _FromBin, _ToBin, BOMComp."No.", '*', 0D, '', Localization.UoM_PCS(), _CreateInventory, Quantity, Quantity);

                if MobTrackingSetup."Serial No. Required" then begin
                    SNCount := 0;
                    repeat
                        _TestData.AddLineWithRef(Name, 0, BOMComp."Line No.", _LocationCode, _FromBin, _ToBin, BOMComp."No.", '', 0D, '*', Localization.UoM_PCS(), _CreateInventory, 1, 1);
                        SNCount += 1;
                    until SNCount = Quantity;
                end;
            until BOMComp.Next() = 0;
    end;

    local procedure AddTrackingToAssemblyOrderLines(_AssemblyHeader: Record "Assembly Header"; var _TestData: Record "MOB Test Data")
    var
        AssemblyLine: Record "Assembly Line";
        ReservationEntry: Record "Reservation Entry";
        MobTrackingSetup: Record "MOB Tracking Setup";
        CreateReservationEntry: Codeunit "Create Reserv. Entry";
        RegisterExpirationDate: Boolean;
    begin

        if _TestData.FindSet() then
            repeat
                if AssemblyLine.Get(_AssemblyHeader."Document Type", _AssemblyHeader."No.", _TestData."Ref. Line No.") then begin

                    MobTrackingSetup.DetermineItemTrackingRequiredByAssemblyLine(AssemblyLine, RegisterExpirationDate);
                    MobTrackingSetup.CopyTrackingFromTestData(_TestData);

                    // The function expects the quantity to be in the base UoM
                    if MobTrackingSetup."Lot No. Required" then
                        MobTrackingSetup.CreateReservEntryFor(
                            CreateReservationEntry,
                            Database::"Assembly Line",
                            MobToolbox.AsInteger(AssemblyLine."Document Type"),
                            AssemblyLine."Document No.",
                            '', // ForBatchName
                            0,  // ForProdOrderLine
                            AssemblyLine."Line No.",  // SourceLineNo
                            AssemblyLine."Qty. per Unit of Measure",
                            AssemblyLine.Quantity,
                            AssemblyLine."Quantity (Base)");

                    if MobTrackingSetup."Serial No. Required" then
                        MobTrackingSetup.CreateReservEntryFor(
                            CreateReservationEntry,
                            Database::"Assembly Line",
                            MobToolbox.AsInteger(AssemblyLine."Document Type"),
                            AssemblyLine."Document No.",
                            '', // ForBatchName
                            0,  // ForProdOrderLine
                            AssemblyLine."Line No.",  // SourceLineNo
                            1,
                            1,
                            1);

                    if MobTrackingSetup."Lot No. Required" or MobTrackingSetup."Serial No. Required" then begin
                        // If the ExpirationDate is registered it must be set on the reservation entry
                        if RegisterExpirationDate then
                            CreateReservationEntry.SetDates(0D, WorkDate());

                        CreateReservationEntry.CreateEntry(AssemblyLine."No.",
                                                           AssemblyLine."Variant Code",
                                                           AssemblyLine."Location Code",
                                                           '',   //Description
                                                           0D,
                                                           WorkDate(),
                                                           0,  // Tranferred from entry no.
                                                           ReservationEntry."Reservation Status"::Prospect);
                    end;
                end;
            until _TestData.Next() = 0;
    end;

    local procedure GetFirstAssemblyOrderConsumptionPickNo(_AssemblyOrderNo: Code[20]): Code[20]
    var
        WhseActLine: Record "Warehouse Activity Line";
    begin
        WhseActLine.SetRange("Activity Type", WhseActLine."Activity Type"::Pick);
        WhseActLine.SetRange("Source Document", WhseActLine."Source Document"::"Assembly Consumption");
        WhseActLine.SetRange("Source No.", _AssemblyOrderNo);
        WhseActLine.FindFirst();

        exit(WhseActLine."No.");
    end;

    local procedure GetFirstAssemblyOrderConsumptionInvMovNo(_AssemblyOrderNo: Code[20]): Code[20]
    var
        WhseActHeader: Record "Warehouse Activity Header";
    begin
        WhseActHeader.SetRange(Type, WhseActHeader.Type::"Invt. Movement");
        WhseActHeader.SetRange("Source Document", WhseActHeader."Source Document"::"Assembly Consumption");
        WhseActHeader.SetRange("Source No.", _AssemblyOrderNo);
        WhseActHeader.FindFirst();

        exit(WhseActHeader."No.");
    end;

    internal procedure SetupTestOrderProduction()
    var
        ProductionOrder: Record "Production Order";
    begin
        //Create productions orders for WHITE
        CreateAndRefreshAndPickProductionOrder_WHITE(ProductionOrder, 'TF-011', 11);
        CreateAndRefreshAndPickProductionOrder_WHITE(ProductionOrder, 'TF-012', 12);

        DisplayCreatedMessage(ProductionDataLbl);
    end;

    procedure CreateAndRefreshAndPickProductionOrder_WHITE(var _ProductionOrder: Record "Production Order"; _ItemNo: Code[20]; _Quantity: Decimal)
    var
        ProdOrderLine: Record "Prod. Order Line";
        WhseActHeader: Record "Warehouse Activity Header";
        WhseActLine: Record "Warehouse Activity Line";
        TempTestData: Record "MOB Test Data" temporary;
        WhseActivityRegister: Codeunit "Whse.-Activity-Register";
    begin
        CreateAndRefreshProductionOrder(_ProductionOrder, _ItemNo, _Quantity, Localization.WHITE());

        ProdOrderLine.Reset();
        ProdOrderLine.SetFilterByReleasedOrderNo(_ProductionOrder."No.");
        ProdOrderLine.FindFirst();  // Assuming only one prod. order line at new production order
        CreateInventoryForProdOrderLine(ProdOrderLine, 'W-01-0001', TempTestData);

        LibraryManufactoring_CreateWhsePickFromProduction(_ProductionOrder);
        WhseActHeader.Get(WhseActHeader.Type::Pick, GetFirstPickNo(Database::"Prod. Order Component", 3, _ProductionOrder."No."));

        WarehousePickCopyTrackingFromTestData(WhseActHeader, TempTestData);

        WhseActLine.Reset();
        WhseActLine.SetRange("Activity Type", WhseActHeader.Type);
        WhseActLine.SetRange("No.", WhseActHeader."No.");
        WhseActivityRegister.ShowHideDialog(true);
        WhseActLine.FindFirst();    // Must be populated prior to .Run
        WhseActivityRegister.Run(WhseActLine);  // Intentionally committing as CreateAndRefreshProductionOrder includes a commit as well
    end;

    local procedure CreateAndRefreshProductionOrder(var _ProductionOrder: Record "Production Order"; _ItemNo: Code[20]; _Quantity: Decimal; _LocationCode: Code[20])
    begin
        LibraryManufactoring_CreateProductionOrder(_ProductionOrder, 3 /*Released*/, 0 /*Item*/, _ItemNo, _Quantity);
        _ProductionOrder.Validate("Location Code", _LocationCode);
        _ProductionOrder.Modify(true);

        LibraryManufactoring_RefreshProdOrder(_ProductionOrder, true, true, true, true, false);   // Must be Forward to avoid calendar error, Includes commit
    end;

    /// <remarks>
    /// Cloned from LibraryManufactoring_CreateProductionOrder but WITHOUT updating ManufacturingSetup."XXX Order Nos." (number series)
    /// Enum parameters changed to Integer.
    /// </remarks>
    local procedure LibraryManufactoring_CreateProductionOrder(var ProductionOrder: Record "Production Order"; ProductionOrderStatus: Integer; ProdOrderSourceType: Integer; SourceNo: Code[20]; Quantity: Decimal)
    begin
        // [removed standard code to update ManufactoringSetup number series codes]

        // Production Order Status:
        // 0 = Simulated
        // 1 = Planned
        // 2 = Firm Planned
        // 3 = Released
        // 4 = Finished

        // Prod. Order Source Type:
        // 0 = Item
        // 1 = Family
        // 2 = Sales Header

        Clear(ProductionOrder);
        ProductionOrder.Init();
        ProductionOrder.Validate(Status, ProductionOrderStatus);
        ProductionOrder.Insert(true);
        ProductionOrder.Validate("Source Type", ProdOrderSourceType);
        ProductionOrder.Validate("Source No.", SourceNo);
        ProductionOrder.Validate(Quantity, Quantity);
        ProductionOrder.Modify(true);
    end;

    /// <remarks>
    /// Cloned from LibraryManufactoring.RefreshProdOrder
    /// </remarks>
    local procedure LibraryManufactoring_RefreshProdOrder(var ProductionOrder: Record "Production Order"; Forward: Boolean; CalcLines: Boolean; CalcRoutings: Boolean; CalcComponents: Boolean; CreateInbRqst: Boolean)
    var
        TmpProductionOrder: Record "Production Order";
        RefreshProductionOrder: Report "Refresh Production Order";
        TempTransactionType: TransactionType;
        Direction: Option Forward,Backward;
    begin
        Commit();
        TempTransactionType := CurrentTransactionType();
        CurrentTransactionType(TransactionType::Update);

        if Forward then
            Direction := Direction::Forward
        else
            Direction := Direction::Backward;
        if ProductionOrder.HasFilter() then
            TmpProductionOrder.CopyFilters(ProductionOrder)
        else begin
            ProductionOrder.Get(ProductionOrder.Status, ProductionOrder."No.");
            TmpProductionOrder.SetRange(Status, ProductionOrder.Status);
            TmpProductionOrder.SetRange("No.", ProductionOrder."No.");
        end;
        RefreshProductionOrder.InitializeRequest(Direction, CalcLines, CalcRoutings, CalcComponents, CreateInbRqst);
        RefreshProductionOrder.SetTableView(TmpProductionOrder);
        RefreshProductionOrder.UseRequestPage := false;
        RefreshProductionOrder.RunModal();

        Commit();
        CurrentTransactionType(TempTransactionType);
    end;

    /// <remarks>
    /// Cloned from LibraryManufactoring.CreateWhsePickFromProduction
    /// </remarks>
    local procedure LibraryManufactoring_CreateWhsePickFromProduction(ProductionOrder: Record "Production Order")
    begin
        ProductionOrder.SetHideValidationDialog(true);
        ProductionOrder.CreatePick(UserId(), 0, false, false, false);
    end;

    local procedure CreateInventoryForProdOrderLine(_ProdOrderLine: Record "Prod. Order Line"; _FromBin: Code[20]; var _ReturnTestData: Record "MOB Test Data")
    var
        ProdOrderComp: Record "Prod. Order Component";
        MobTrackingSetup: Record "MOB Tracking Setup";
        ExpDateRequired: Boolean;
        SNCount: Integer;
        TestDataCode: Code[50];
    begin
        TestDataCode := 'PRODUCTION';

        _ProdOrderLine.TestField(Status, 3 /*"Production Order Status"::Released*/);
        ProdOrderComp.Reset();
        ProdOrderComp.SetFilterByReleasedOrderNo(_ProdOrderLine."Prod. Order No.");
        if ProdOrderComp.FindSet() then
            repeat
                ProdOrderComp.TestField("Variant Code", '');    // Variant Code currently not supported in CreateInventory

                Clear(MobTrackingSetup);
                MobTrackingSetup.DetermineSpecificTrackingRequiredFromItemNo(ProdOrderComp."Item No.", ExpDateRequired);
                // MobTrackingSetup.Tracking: Tracking values are unused in this scope

                if not (MobTrackingSetup."Serial No. Required" or MobTrackingSetup."Lot No. Required") then
                    _ReturnTestData.AddLineWithRef(TestDataCode, 0, ProdOrderComp."Line No.", ProdOrderComp."Location Code", _FromBin, '', ProdOrderComp."Item No.", '', 0D, '', ProdOrderComp."Unit of Measure Code", true, ProdOrderComp."Expected Quantity", ProdOrderComp."Expected Quantity");

                if MobTrackingSetup."Lot No. Required" then
                    if ExpDateRequired then
                        _ReturnTestData.AddLineWithRef(TestDataCode, 0, ProdOrderComp."Line No.", ProdOrderComp."Location Code", _FromBin, '', ProdOrderComp."Item No.", '*', WorkDate(), '', ProdOrderComp."Unit of Measure Code", true, ProdOrderComp."Expected Quantity", ProdOrderComp."Expected Quantity")
                    else
                        _ReturnTestData.AddLineWithRef(TestDataCode, 0, ProdOrderComp."Line No.", ProdOrderComp."Location Code", _FromBin, '', ProdOrderComp."Item No.", '*', 0D, '', ProdOrderComp."Unit of Measure Code", true, ProdOrderComp."Expected Quantity", ProdOrderComp."Expected Quantity");

                if MobTrackingSetup."Serial No. Required" then begin
                    SNCount := 0;
                    repeat
                        _ReturnTestData.AddLineWithRef(TestDataCode, 0, ProdOrderComp."Line No.", ProdOrderComp."Location Code", _FromBin, '', ProdOrderComp."Item No.", '', 0D, '*', ProdOrderComp."Unit of Measure Code", true, 1, 1);
                        SNCount += 1;
                    until SNCount = ProdOrderComp."Expected Quantity";
                end;
            until ProdOrderComp.Next() = 0;
    end;

    procedure GetFirstPickNo(_SourceType: Integer; _SourceSubtype: Integer; _SourceNo: Code[20]): Code[20]
    var
        WhseActLine: Record "Warehouse Activity Line";
    begin
        WhseActLine.Reset();
        WhseActLine.SetCurrentKey("Source Type", "Source Subtype", "Source No.");
        WhseActLine.SetRange("Source Type", _SourceType);
        WhseActLine.SetRange("Source Subtype", _SourceSubtype);
        WhseActLine.SetRange("Source No.", _SourceNo);
        WhseActLine.SetRange("Activity Type", WhseActLine."Activity Type"::Pick);
        WhseActLine.FindFirst();

        exit(WhseActLine."No.")
    end;

    /// <summary>
    /// Populate Warehouse Pick tracking by copying TestData 1:1 (assuming same number of records and order of TestData, Take lines and Place lines)
    /// </summary>
    local procedure WarehousePickCopyTrackingFromTestData(_WhseActHeader: Record "Warehouse Activity Header"; var _TestData: Record "MOB Test Data")
    var
        WhseActLineTake: Record "Warehouse Activity Line";
        WhseActLinePlace: Record "Warehouse Activity Line";
        ItemTrackingSetupBlank: Record "MOB Tracking Setup";
        ItemTrackingSetupTestData: Record "MOB Tracking Setup";
    begin
        _WhseActHeader.TestField(Type, _WhseActHeader.Type::Pick);

        WhseActLineTake.Reset();
        WhseActLineTake.SetRange("Activity Type", _WhseActHeader.Type);
        WhseActLineTake.SetRange("No.", _WhseActHeader."No.");
        WhseActLineTake.SetRange("Action Type", WhseActLineTake."Action Type"::Take);
        WhseActLinePlace.Copy(WhseActLineTake);
        WhseActLinePlace.SetRange("Action Type", WhseActLineTake."Action Type"::Place);

        _TestData.FindSet();
        repeat
            ItemTrackingSetupTestData.ClearTrackingRequired();
            ItemTrackingSetupTestData.CopyTrackingFromTestData(_TestData);

            if _TestData.TrackingExists() then begin
                WhseActLineTake.SetRange("Item No.", _TestData."Item No.");
                WhseActLineTake.SetRange("Qty. to Handle", _TestData."Qty. To Handle");
                WhseActLineTake.SetRange("Unit of Measure Code", _TestData."Unit of Measure Code");

                Clear(ItemTrackingSetupBlank);
                // MobTrackingSetup.TrackingRequired: Tracking Required values are unused in this scope
                // MobTrackingSetup.Tracking: Tracking values are unused in this scope
                ItemTrackingSetupBlank.SetTrackingFilterForWhseActivityLine(WhseActLineTake);
                WhseActLineTake.SetRange("Expiration Date", 0D);

                if WhseActLineTake.FindFirst() then begin   // Conditonal since Warehouse Pick may include fewer lines than DataSet if some goods was on inventory at Prodution Input Bin
                    ItemTrackingSetupTestData.CopyTrackingToWhseActivityLine(WhseActLineTake);
                    WhseActLineTake.Validate("Expiration Date", _TestData."Expiration Date");
                    WhseActLineTake.Modify();

                    WhseActLinePlace.SetFilter("Line No.", '>%1', WhseActLineTake."Line No.");
                    WhseActLinePlace.FindFirst();
                    WhseActLinePlace.TestField("Qty. to Handle", _TestData."Qty. To Handle");
                    WhseActLinePlace.TestField("Unit of Measure Code", _TestData."Unit of Measure Code");
                    ItemTrackingSetupTestData.CopyTrackingToWhseActivityLine(WhseActLinePlace);
                    WhseActLinePlace.Validate("Expiration Date", _TestData."Expiration Date");
                    WhseActLinePlace.Modify();
                end;
            end;
        until _TestData.Next() = 0;
    end;

    internal procedure BatchCreateWhseInternalPicks(_NoOfPicks: Integer)
    var
        TempTestData: Record "MOB Test Data" temporary;
        i: Integer;
    begin
        CreateInventory('WHITE', 'W-01-0001', 'TF-002', '', '', '', _NoOfPicks * 15, Localization.UoM_PCS(), true);
        TempTestData.AddLineWithRef('BatchCreateWarehousePicks', 0, 10000, 'WHITE', 'W-01-0001', 'W-02-0001', 'TF-002', '', 0D, '', Localization.UoM_PCS(), false, 15, 15);

        for i := 1 to _NoOfPicks do
            CreateWhseInternalPick('WHITE', 'W-02-0001', TempTestData);

        DisplayCreatedMessage(StrSubstNo('%1 %2', _NoOfPicks, WhseInternalPicksLbl));
    end;

    procedure CreateWhseInternalPick(_LocationCode: Code[10]; _ToBinCode: Code[20]; var _TestData: Record "MOB Test Data"): Code[20]
    var
        WhseInternalPickHeader: Record "Whse. Internal Pick Header";
        WhseInternalPickLine: Record "Whse. Internal Pick Line";
        TempCreateTestData: Record "MOB Test Data" temporary;
        WhseActivityLine: Record "Warehouse Activity Line";
        ReleaseWhseInternalPick: Codeunit "Whse. Internal Pick Release";
    begin
        // 1. Create a Whse. Internal Pick and release it
        // 2. Create a Warehouse Pick from the Whse. Internal Pick if applicable

        // Create Whse. Internal Pick Document
        WhseInternalPickHeader.Init();
        WhseInternalPickHeader.Insert(true);
        WhseInternalPickHeader.Validate("Location Code", _LocationCode);
        WhseInternalPickHeader.Validate("To Bin Code", _ToBinCode);
        WhseInternalPickHeader.Validate("Due Date", WorkDate());
        WhseInternalPickHeader.Modify(true);

        // Create Lines
        if _TestData.FindSet() then
            repeat
                TempCreateTestData.Copy(_TestData);
                CreateWhseInternalPickLine(WhseInternalPickHeader, TempCreateTestData);
            until _TestData.Next() = 0;

        _TestData.Copy(TempCreateTestData, true);

        // Release document
        if WhseInternalPickHeader.Status = WhseInternalPickHeader.Status::Open then
            ReleaseWhseInternalPick.Release(WhseInternalPickHeader);

        // Create Warehouse Pick
        WhseInternalPickLine.SetRange("No.", WhseInternalPickHeader."No.");
        if not WhseInternalPickLine.IsEmpty() then begin
            WhseInternalPickLine.SetHideValidationDialog(true);
            WhseInternalPickLine.CreatePickDoc(WhseInternalPickLine, WhseInternalPickHeader);
        end;

        // Find created Warehouse Pick Line and exit Activity No.
        WhseActivityLine.SetRange("Whse. Document Type", WhseActivityLine."Whse. Document Type"::"Internal Pick");
        WhseActivityLine.SetRange("Whse. Document No.", WhseInternalPickLine."No.");
        WhseActivityLine.FindFirst();
        exit(WhseActivityLine."No.");
    end;

    local procedure CreateWhseInternalPickLine(_WhseInternalPickHeader: Record "Whse. Internal Pick Header"; var _TestData: Record "MOB Test Data")
    var
        WhseInternalPickLine: Record "Whse. Internal Pick Line";
        LineNo: Integer;
    begin
        if _TestData."Ref. Line No." <> 0 then begin
            WhseInternalPickLine.SetRange("No.", _WhseInternalPickHeader."No.");
            WhseInternalPickLine.SetRange("Line No.", _TestData."Ref. Line No.");
        end;

        if WhseInternalPickLine.FindSet() and (_TestData."Ref. Line No." <> 0) then begin
            _TestData.TestField("Item No.", WhseInternalPickLine."Item No.");
            _TestData.TestField("Variant Code", WhseInternalPickLine."Variant Code");
            _TestData.TestField("To Bin Code", WhseInternalPickLine."To Bin Code");
            WhseInternalPickLine.Validate(Quantity, WhseInternalPickLine.Quantity + _TestData."Qty. To Handle");
            WhseInternalPickLine.Modify(true);
        end else begin
            WhseInternalPickLine.Reset();
            WhseInternalPickLine.Init();
            WhseInternalPickLine."No." := _WhseInternalPickHeader."No.";
            if _TestData."Ref. Line No." <> 0 then
                LineNo := _TestData."Ref. Line No."
            else
                LineNo += 10000;
            WhseInternalPickLine."Line No." := LineNo;
            WhseInternalPickLine.Validate("Item No.", _TestData."Item No.");
            WhseInternalPickLine.Validate("Variant Code", _TestData."Variant Code");
            WhseInternalPickLine.Validate("To Bin Code", _TestData."To Bin Code");
            WhseInternalPickLine.Validate(Quantity, _TestData."Qty. To Handle");
            WhseInternalPickLine.Insert(true);
        end;

        _TestData.Code := WhseInternalPickLine."No.";
        _TestData."Ref. Line No." := WhseInternalPickLine."Line No.";
        _TestData.Insert();
    end;

    procedure CreateWhseInternalPutAway(_LocationCode: Code[20]; _FromBinCode: Code[20]; var _TestData: Record "MOB Test Data"): Code[20]
    var
        WhseInternalPutAwayHeader: Record "Whse. Internal Put-away Header";
        WhseInternalPutAwayLine: Record "Whse. Internal Put-away Line";
        WhseActivityLine: Record "Warehouse Activity Line";
        TempNewTestData: Record "MOB Test Data" temporary;
        ReleaseWhseInternalPutAway: Codeunit "Whse. Int. Put-away Release";
    begin
        // 1. Create a Whse. Internal Put-Away and release it
        // 2. Create a Warehouse Put-Away from the Whse. Internal Put-Away if applicable

        // Create Whse. Internal PutAway Document
        WhseInternalPutAwayHeader.Init();
        WhseInternalPutAwayHeader.Insert(true);
        WhseInternalPutAwayHeader.Validate("Location Code", _LocationCode);
        WhseInternalPutAwayHeader.Validate("From Bin Code", _FromBinCode);
        WhseInternalPutAwayHeader.Validate("Due Date", WorkDate());
        WhseInternalPutAwayHeader.Modify(true);

        // Create Lines, then update _TestData to include new document no's and line ref. no's
        CreateWhseInternalPutAwayLines(WhseInternalPutAwayHeader, _TestData, TempNewTestData);
        _TestData.Copy(TempNewTestData, true);

        // Release document
        if WhseInternalPutAwayHeader.Status = WhseInternalPutAwayHeader.Status::Open then
            ReleaseWhseInternalPutAway.Release(WhseInternalPutAwayHeader);

        // Create Warehouse Put-away
        WhseInternalPutAwayLine.Reset();
        WhseInternalPutAwayLine.SetRange("No.", WhseInternalPutAwayHeader."No.");
        WhseInternalPutAwayLine.FindFirst();    // Intentionally throw error if not found
        WhseInternalPutAwayLine.SetHideValidationDialog(true);
        WhseInternalPutAwayLine.CreatePutAwayDoc(WhseInternalPutAwayLine);

        // Find a created put-away Whse. Activity Line and exit Activity No.
        WhseActivityLine.Reset();
        WhseActivityLine.SetRange("Whse. Document Type", WhseActivityLine."Whse. Document Type"::"Internal Put-away");
        WhseActivityLine.SetRange("Whse. Document No.", WhseInternalPutAwayLine."No.");
        WhseActivityLine.FindFirst();
        exit(WhseActivityLine."No.");
    end;

    local procedure CreateWhseInternalPutAwayLines(_WhseInternalPutAwayHeader: Record "Whse. Internal Put-away Header"; var _TestData: Record "MOB Test Data"; var _NewTestData: Record "MOB Test Data")
    var
        LastWhseInternalPutAwayLine: Record "Whse. Internal Put-away Line";
    begin
        if _TestData.FindSet() then
            repeat
                CreateWhseInternalPutAwayLine(_WhseInternalPutAwayHeader, _TestData, LastWhseInternalPutAwayLine);

                // TestData may need to be updated to include new document no's / line ref. no's, hence store new values in separate instance to avoid affecting iteration of current instance
                _NewTestData := _TestData;
                _NewTestData.Code := LastWhseInternalPutAwayLine."No.";
                _NewTestData."Ref. Line No." := LastWhseInternalPutAwayLine."Line No.";
                _NewTestData.Insert();
            until _TestData.Next() = 0;
    end;

    local procedure CreateWhseInternalPutAwayLine(_WhseInternalPutAwayHeader: Record "Whse. Internal Put-away Header"; var _TestData: Record "MOB Test Data"; var _LastWhseInternalPutAwayLine: Record "Whse. Internal Put-away Line")
    var
        WhseInternalPutAwayLine: Record "Whse. Internal Put-away Line";
        MobTrackingSetup: Record "MOB Tracking Setup";
    begin
        if _TestData."Ref. Line No." <> 0 then begin
            WhseInternalPutAwayLine.SetRange("No.", _WhseInternalPutAwayHeader."No.");
            WhseInternalPutAwayLine.SetRange("Line No.", _TestData."Ref. Line No.");
        end;

        if WhseInternalPutAwayLine.FindFirst() and (_TestData."Ref. Line No." <> 0) then begin
            _TestData.TestField("Item No.", WhseInternalPutAwayLine."Item No.");
            _TestData.TestField("Variant Code", WhseInternalPutAwayLine."Variant Code");
            _TestData.TestField("Bin Code", WhseInternalPutAwayLine."From Bin Code");
            WhseInternalPutAwayLine.Validate(Quantity, WhseInternalPutAwayLine.Quantity + _TestData."Qty. To Handle");
            WhseInternalPutAwayLine.Modify(true);
        end else begin
            WhseInternalPutAwayLine.Init();
            WhseInternalPutAwayLine."No." := _WhseInternalPutAwayHeader."No.";
            WhseInternalPutAwayLine.SetUpNewLine(_LastWhseInternalPutAwayLine); // Line No. / Location Code / From Zone Code / From Bin Code / Due Date
            WhseInternalPutAwayLine.Validate("Item No.", _TestData."Item No.");
            WhseInternalPutAwayLine.Validate("Variant Code", _TestData."Variant Code");
            WhseInternalPutAwayLine.Validate("From Bin Code", _TestData."Bin Code");
            WhseInternalPutAwayLine.Validate(Quantity, _TestData."Qty. To Handle");
            WhseInternalPutAwayLine.Insert(true);
        end;

        MobTrackingSetup.ClearTrackingRequired();
        MobTrackingSetup.CopyTrackingFromTestData(_TestData);

        if MobTrackingSetup.TrackingExists() then
            WhseInternalPutAwayLine_SetItemTrackingLines(WhseInternalPutAwayLine, MobTrackingSetup, _TestData."Expiration Date", _TestData."Qty. To Handle");    // Add single new tracking line

        _LastWhseInternalPutAwayLine := WhseInternalPutAwayLine;
    end;

    /* #if BC16+ */
    local procedure WhseInternalPutAwayLine_SetItemTrackingLines(var _WhseInternalPutAwayLine: Record "Whse. Internal Put-away Line"; _MobTrackingSetup: Record "MOB Tracking Setup"; _ExpirationDate: Date; _QtyToHandle: Decimal)
    var
        TempWhseEntry: Record "Warehouse Entry" temporary;
        WhseJnlLine: Record "Warehouse Journal Line";
        QtyToEmpty: Decimal;
    begin
        _MobTrackingSetup.CopyTrackingToWhseJnlLine(WhseJnlLine);
        TempWhseEntry.CopyTrackingFromWhseJnlLine(WhseJnlLine);
        TempWhseEntry."Expiration Date" := _ExpirationDate;
        QtyToEmpty := _QtyToHandle;

        _WhseInternalPutAwayLine.SetItemTrackingLines(TempWhseEntry, QtyToEmpty);
    end;
    /* #endif */
    /* #if BC15 ##
    local procedure WhseInternalPutAwayLine_SetItemTrackingLines(var _WhseInternalPutAwayLine: Record "Whse. Internal Put-away Line"; _MobTrackingSetup: Record "MOB Tracking Setup"; _ExpirationDate: Date; _QtyToHandle: Decimal)
    var
        TempWhseEntry: Record "Warehouse Entry" temporary;
        QtyToEmpty: Decimal;
    begin
        TempWhseEntry."Serial No." := _MobTrackingSetup."Serial No.";
        TempWhseEntry."Lot No." := _MobTrackingSetup."Lot No.";
        TempWhseEntry."Expiration Date" := _ExpirationDate;
        QtyToEmpty := _QtyToHandle;

        _WhseInternalPutAwayLine.SetItemTrackingLines(TempWhseEntry, QtyToEmpty);
    end;
    /* #endif */
    /* #if BC14 ##
    local procedure WhseInternalPutAwayLine_SetItemTrackingLines(var _WhseInternalPutAwayLine: Record "Whse. Internal Put-away Line"; _MobTrackingSetup: Record "MOB Tracking Setup"; _ExpirationDate: Date; _QtyToHandle: Decimal)
    var
        QtyToEmpty: Decimal;
    begin
        QtyToEmpty := _QtyToHandle;
        _WhseInternalPutAwayLine.SetItemTrackingLines(_MobTrackingSetup."Serial No.", _MobTrackingSetup."Lot No.", _ExpirationDate, QtyToEmpty);
    end;
    /* #endif */


    local procedure FindWhseActivityLine(var _WhseActivityLine: Record "Warehouse Activity Line"; _ActivityType: Option; _ActionType: Option; _LocationCode: Code[10]; _SourceNo: Code[20])
    begin
        _WhseActivityLine.Reset();
        _WhseActivityLine.SetRange("Activity Type", _ActivityType);
        _WhseActivityLine.SetRange("Location Code", _LocationCode);
        _WhseActivityLine.SetRange("No.", FindWarehouseActivityNo(_SourceNo, _ActivityType));
        _WhseActivityLine.SetRange("Action Type", _ActionType);
        _WhseActivityLine.FindSet();
    end;

    local procedure FindWarehouseActivityNo(_SourceNo: Code[20]; _ActivityType: Option): Code[20]
    var
        WhseActivityLine: Record "Warehouse Activity Line";
    begin
        WhseActivityLine.Reset();
        WhseActivityLine.SetRange("Source No.", _SourceNo);
        WhseActivityLine.SetRange("Activity Type", _ActivityType);
        WhseActivityLine.FindFirst();
        exit(WhseActivityLine."No.");
    end;

    local procedure FindWarehouseShipmentLine(var _WhseShipmentLine: Record "Warehouse Shipment Line"; _SourceDocument: Option; _SourceNo: Code[20])
    begin
        _WhseShipmentLine.Reset();
        _WhseShipmentLine.SetCurrentKey("Source Document", "Source No.");
        _WhseShipmentLine.SetRange("Source Document", _SourceDocument);
        _WhseShipmentLine.SetRange("Source No.", _SourceNo);
        _WhseShipmentLine.FindFirst();
    end;

    local procedure CreateTransferOrderLine(_TransferHeader: Record "Transfer Header"; var _TestData: Record "MOB Test Data" temporary)
    var
        TransferLine: Record "Transfer Line";
        LineNo: Integer;
    begin
        if _TestData."Ref. Line No." <> 0 then begin
            TransferLine.SetRange("Document No.", _TransferHeader."No.");
            TransferLine.SetRange("Line No.", _TestData."Ref. Line No.");
        end;

        if TransferLine.FindSet() and (_TestData."Ref. Line No." <> 0) then begin
            TransferLine.Validate(Quantity, TransferLine.Quantity + _TestData."Qty. To Handle");
            TransferLine.Modify(true);
        end else begin
            TransferLine.Reset();
            TransferLine.Init();
            TransferLine."Document No." := _TransferHeader."No.";
            if _TestData."Ref. Line No." <> 0 then
                LineNo := _TestData."Ref. Line No."
            else
                LineNo += 10000;
            TransferLine."Line No." := LineNo;

            TransferLine.Validate("Item No.", _TestData."Item No.");
            TransferLine.Validate("Unit of Measure Code", _TestData."Unit of Measure Code");
            TransferLine.Validate(Quantity, _TestData."Qty. To Handle");

            TransferLine.Insert(true);
        end;

        _TestData.Code := TransferLine."Document No.";
        _TestData."Ref. Line No." := TransferLine."Line No.";
        _TestData.Insert();
    end;

    procedure CreateSalesOrder(_CustomerNo: Code[20]; _LocationCode: Code[20]; _NoOfLines: Integer): Code[20]
    var
        TempTestData: Record "MOB Test Data" temporary;
        SetsOfLines: Integer;
        i: Integer;
    begin
        // 1. Create a Sales Order and release it
        // 2. Create a Warehouse Shipment from the Sales Order if applicable        

        // Create Test Data
        // Use "sets of three"
        if _NoOfLines = 0 then
            _NoOfLines := 3;
        SetsOfLines := Round(_NoOfLines / 3, 1, '=');

        repeat
            i += 1;
            CreateData_Small_NonWarehouse(TempTestData, _LocationCode, false, true);
        until i >= SetsOfLines;

        exit(CreateSalesOrder(_CustomerNo, _LocationCode, TempTestData));
    end;

    local procedure CreateSalesOrder_BOX(_CustomerNo: Code[20]; _LocationCode: Code[20]): Code[20]
    var
        TempTestData: Record "MOB Test Data" temporary;
    begin
        // 1. Create a Sales Order for alternate UoM::BOX and release it
        // 2. Create a Warehouse Shipment from the Sales Order if applicable        

        CreateData_Small_NonWarehouse_BOX(TempTestData, _LocationCode, false, true);
        exit(CreateSalesOrder(_CustomerNo, _LocationCode, TempTestData));
    end;

    local procedure CreateSalesOrder_WHITE_TotePick(_CustomerNo: Code[20]): Code[20]
    var
        TempTestData: Record "MOB Test Data" temporary;
    begin
        // 1. Update Mobile WMS Setup for Tote Picking
        // 2. Create a Sales Order and release it
        // 3. Create a Warehouse Shipment from the Sales Order if applicable

        CreateData_Small_Warehouse_Without_SN(TempTestData, Localization.WHITE(), 'W-01-0001', '', '99', true, true);  // Hardcoded LOT = 99 for easy manual test
        exit(CreateSalesOrder(_CustomerNo, Localization.WHITE(), TempTestData));
    end;

    procedure CreateSalesOrder(_CustomerNo: Code[20]; _LocationCode: Code[20]; var _TestData: Record "MOB Test Data" temporary): Code[20]
    var
        SalesHeader: Record "Sales Header";
        Location: Record Location;
        WhseRequest: Record "Warehouse Request";
        TempCreateTestData: Record "MOB Test Data" temporary;
        CreateInvtPutawayPickMvmt: Report "Create Invt Put-away/Pick/Mvmt";
        GetSourceDocuments: Report "Get Source Documents";
        MobCommonMgt: Codeunit "MOB Common Mgt.";
        ReleaseSalesDocument: Codeunit "Release Sales Document";
        GetSourceDocOutbound: Codeunit "Get Source Doc. Outbound";
        LocationFilter: Text;
    begin
        // 1. Create a Sales Order and release it
        // 2. Create a Warehouse Shipment from the Sales Order if applicable

        // Create Order No.
        SalesHeader.Init();
        SalesHeader.Validate("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.Insert(true);

        // Set Customer
        SalesHeader.Validate("Sell-to Customer No.", _CustomerNo);
        SalesHeader.Validate("Location Code", _LocationCode);
        SalesHeader.Modify(true);

        // Create Lines        
        if _TestData.FindSet() then
            repeat
                TempCreateTestData.Copy(_TestData);
                CreateSalesOrderLine(SalesHeader, TempCreateTestData);
            until _TestData.Next() = 0;

        _TestData.Copy(TempCreateTestData, true);

        // Release
        ReleaseSalesDocument.Run(SalesHeader);

        // Create the Warehouse Shipment/Pick or Inventory Pick - Based on the Location Setup
        Location.Get(SalesHeader."Location Code");
        if Location."Require Shipment" then begin
            // Create Warehouse Shipment

            SalesHeader.TestField(Status, SalesHeader.Status::Released);
            if MobCommonMgt.WhseShipmentConflict(SalesHeader."Document Type", SalesHeader."No.", SalesHeader."Shipping Advice") then
                Error(OpenWhseShipmentExistsErr, Format(SalesHeader."Shipping Advice"));
            GetSourceDocOutbound.CheckSalesHeader(SalesHeader, true);
            WhseRequest.SetRange(Type, WhseRequest.Type::Outbound);
            WhseRequest.SetRange("Source Type", Database::"Sales Line");
            WhseRequest.SetRange("Source Subtype", SalesHeader."Document Type");
            WhseRequest.SetRange("Source No.", SalesHeader."No.");
            WhseRequest.SetRange("Document Status", WhseRequest."Document Status"::Released);

            if WhseRequest.FindSet() then begin
                repeat
                    if Location.RequireShipment(WhseRequest."Location Code") then
                        LocationFilter += WhseRequest."Location Code" + '|';
                until WhseRequest.Next() = 0;
                if LocationFilter <> '' then
                    LocationFilter := CopyStr(LocationFilter, 1, StrLen(LocationFilter) - 1);
                WhseRequest.SetFilter("Location Code", LocationFilter);
            end;

            if not WhseRequest.IsEmpty() then begin
                Clear(GetSourceDocuments);
                GetSourceDocuments.UseRequestPage(false);
                GetSourceDocuments.SetTableView(WhseRequest);
                //GetSourceDocuments.SetHideDialog(true); //Cannot be used in extension dev.
                GetSourceDocuments.RunModal();
                ReleaseWhseShipment(Database::"Sales Line", MobToolbox.AsInteger(SalesHeader."Document Type"), SalesHeader."No.");
            end;

            // Create Warehouse Pick
            if Location."Require Pick" then
                CreateWhsePick(Database::"Sales Line", MobToolbox.AsInteger(SalesHeader."Document Type"), SalesHeader."No.");
        end else
            // Inventory Pick
            if Location."Require Put-away" then begin
                WhseRequest.SetRange("Source No.", SalesHeader."No.");
                CreateInvtPutawayPickMvmt.SetTableView(WhseRequest);
                CreateInvtPutawayPickMvmt.InitializeRequest(false, true, false, false, false);
                CreateInvtPutawayPickMvmt.SuppressMessages(true);
                CreateInvtPutawayPickMvmt.UseRequestPage(false);
                CreateInvtPutawayPickMvmt.RunModal();
            end;

        exit(SalesHeader."No.");
    end;

    local procedure CreateSalesOrderLine(SalesHeader: Record "Sales Header"; var _TestData: Record "MOB Test Data" temporary)
    var
        SalesLine: Record "Sales Line";
        LineNo: Integer;
    begin
        if _TestData."Ref. Line No." <> 0 then begin
            SalesLine.SetRange("Document Type", SalesHeader."Document Type");
            SalesLine.SetRange("Document No.", SalesHeader."No.");
            SalesLine.SetRange("Line No.", _TestData."Ref. Line No.");
        end;

        if SalesLine.FindSet() and (_TestData."Ref. Line No." <> 0) then begin
            SalesLine.Validate(Quantity, SalesLine.Quantity + _TestData."Qty. To Handle");
            SalesLine.Modify(true);
        end else begin
            SalesLine.Reset();
            SalesLine.Init();
            SalesLine."Document Type" := SalesHeader."Document Type";
            SalesLine."Document No." := SalesHeader."No.";
            if _TestData."Ref. Line No." <> 0 then
                LineNo := _TestData."Ref. Line No."
            else
                LineNo += 10000;
            SalesLine."Line No." := LineNo;

            SalesLine.Validate(Type, SalesLine.Type::Item);
            SalesLine.Validate("No.", _TestData."Item No.");
            SalesLine.Validate("Unit of Measure Code", _TestData."Unit of Measure Code");
            SalesLine.Validate(Quantity, _TestData."Qty. To Handle");
            SalesLine.Insert(true);
        end;

        _TestData.Code := SalesLine."Document No.";
        _TestData."Ref. Line No." := SalesLine."Line No.";
        _TestData.Insert();
    end;

    procedure CreateSalesReturnOrder(_CustomerNo: Code[20]; _LocationCode: Code[20]): Code[20]
    var
        TempTestData: Record "MOB Test Data" temporary;
    begin
        CreateData_XL(TempTestData, _LocationCode, false, true);

        exit(CreateSalesReturnOrder(_CustomerNo, _LocationCode, TempTestData));
    end;

    procedure CreateSalesReturnOrder(_CustomerNo: Code[20]; _LocationCode: Code[20]; var _TestData: Record "MOB Test Data" temporary): Code[20]
    var
        SalesReturnHeader: Record "Sales Header";
        Location: Record Location;
        WhseRequest: Record "Warehouse Request";
        TempCreateTestData: Record "MOB Test Data" temporary;
        CreateInvtPutawayPickMvmt: Report "Create Invt Put-away/Pick/Mvmt";
        ReleaseSalesDoc: Codeunit "Release Sales Document";
        GetSourceDocInbound: Codeunit "Get Source Doc. Inbound";
    begin
        // 1. Create a Sales Return Order and release it
        // 2. Create a Warehouse Receipt from the Sales Return Order if applicable

        // Create Sales Return Order
        SalesReturnHeader.Init();
        SalesReturnHeader.Validate("Document Type", SalesReturnHeader."Document Type"::"Return Order");
        SalesReturnHeader.Insert(true);

        // Set Customer
        SalesReturnHeader.Validate("Sell-to Customer No.", _CustomerNo);
        SalesReturnHeader.Validate("Location Code", _LocationCode);
        SalesReturnHeader.Validate("Shipment Date", CalcDate('<+2M>', WorkDate()));       // Sales Return shipment date cannot be earlier than workdate
        SalesReturnHeader.Modify(true);

        if _TestData.FindSet() then
            repeat
                TempCreateTestData.Copy(_TestData);
                CreateSalesOrderLine(SalesReturnHeader, TempCreateTestData);
            until _TestData.Next() = 0;

        _TestData.Copy(TempCreateTestData, true);

        // Release the Sales Return Order
        ReleaseSalesDoc.Run(SalesReturnHeader);

        // Create the Warehouse Receipt or Inventory Put-away if applicable
        Location.Get(SalesReturnHeader."Location Code");
        if Location."Require Receive" then
            GetSourceDocInbound.CreateFromSalesReturnOrderHideDialog(SalesReturnHeader)
        else
            if Location."Require Put-away" then begin
                WhseRequest.SetRange("Source Document", WhseRequest."Source Document"::"Sales Return Order");
                WhseRequest.SetRange("Source Type", Database::"Sales Line");
                WhseRequest.SetRange("Source Subtype", SalesReturnHeader."Document Type");
                CreateInvtPutawayPickMvmt.SetTableView(WhseRequest);
                CreateInvtPutawayPickMvmt.InitializeRequest(true, false, false, false, false);
                CreateInvtPutawayPickMvmt.SuppressMessages(true);
                CreateInvtPutawayPickMvmt.UseRequestPage(false);
                CreateInvtPutawayPickMvmt.RunModal();
            end;

        exit(SalesReturnHeader."No.");
    end;

    procedure CreatePurchaseReturnOrder(_VendorNo: Code[20]; _LocationCode: Code[20]): Code[20]
    var
        TempTestData: Record "MOB Test Data" temporary;
    begin
        CreateData_XL(TempTestData, _LocationCode, false, true);

        exit(CreatePurchaseReturnOrder(_VendorNo, _LocationCode, TempTestData, false));
    end;

    procedure CreatePurchaseReturnOrderWithItemTracking(_VendorNo: Code[20]; _LocationCode: Code[20]): Code[20]
    var
        TempTestData: Record "MOB Test Data" temporary;
    begin
        CreateData_XL(TempTestData, _LocationCode, false, true);

        exit(CreatePurchaseReturnOrder(_VendorNo, _LocationCode, TempTestData, true));
    end;

    procedure CreatePurchaseReturnOrder(_VendorNo: Code[20]; _LocationCode: Code[20]; var _TestData: Record "MOB Test Data" temporary): Code[20]
    begin
        exit(CreatePurchaseReturnOrder(_VendorNo, _LocationCode, _TestData, false));
    end;

    procedure CreatePurchaseReturnOrderWithItemTracking(_VendorNo: Code[20]; _LocationCode: Code[20]; var _TestData: Record "MOB Test Data" temporary): Code[20]
    begin
        exit(CreatePurchaseReturnOrder(_VendorNo, _LocationCode, _TestData, true));
    end;

    local procedure CreatePurchaseReturnOrder(_VendorNo: Code[20]; _LocationCode: Code[20]; var _TestData: Record "MOB Test Data" temporary; _CreateWithItemTracking: Boolean): Code[20]
    var
        PurchaseReturnHeader: Record "Purchase Header";
        Location: Record Location;
        WhseRequest: Record "Warehouse Request";
        TempCreateTestData: Record "MOB Test Data" temporary;
        CreateInvtPutawayPickMvmt: Report "Create Invt Put-away/Pick/Mvmt";
        ReleasePurchaseDoc: Codeunit "Release Purchase Document";
        GetSourceDocOutbound: Codeunit "Get Source Doc. Outbound";
    begin
        // 1. Create a Sales Return Order and release it
        // 2. Create a Warehouse Receipt from the Sales Return Order if applicable

        // Create Sales Return Order
        PurchaseReturnHeader.Init();
        PurchaseReturnHeader.Validate("Document Type", PurchaseReturnHeader."Document Type"::"Return Order");
        PurchaseReturnHeader.Insert(true);

        // Set Customer
        PurchaseReturnHeader.Validate("Buy-from Vendor No.", _VendorNo);
        PurchaseReturnHeader.Validate("Location Code", _LocationCode);
        PurchaseReturnHeader.Validate("Expected Receipt Date", CalcDate('<+2M>', WorkDate()));       // Sales Return shipment date cannot be earlier than workdate
        PurchaseReturnHeader.Modify(true);

        if _TestData.FindSet() then
            repeat
                TempCreateTestData.Copy(_TestData);
                CreatePurchaseOrderLine(PurchaseReturnHeader, TempCreateTestData, _CreateWithItemTracking)
            until _TestData.Next() = 0;

        _TestData.Copy(TempCreateTestData, true);

        // Release the Sales Return Order
        ReleasePurchaseDoc.Run(PurchaseReturnHeader);

        // Create the Warehouse Receipt or Inventory Put-away if applicable
        Location.Get(PurchaseReturnHeader."Location Code");
        if Location."Require Receive" then
            GetSourceDocOutbound.CreateFromPurchReturnOrderHideDialog(PurchaseReturnHeader)
        else
            if Location."Require Pick" then begin
                WhseRequest.SetRange("Source Document", WhseRequest."Source Document"::"Purchase Return Order");
                WhseRequest.SetRange("Source Type", Database::"Purchase Line");
                WhseRequest.SetRange("Source Subtype", PurchaseReturnHeader."Document Type");
                CreateInvtPutawayPickMvmt.SetTableView(WhseRequest);
                CreateInvtPutawayPickMvmt.InitializeRequest(false, true, false, false, false);
                CreateInvtPutawayPickMvmt.SuppressMessages(true);
                CreateInvtPutawayPickMvmt.UseRequestPage(false);
                CreateInvtPutawayPickMvmt.RunModal();
            end;

        exit(PurchaseReturnHeader."No.");
    end;

    local procedure ReleaseWhseShipment(_SourceType: Integer; _SourceSubtype: Integer; _SourceNo: Code[20])
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WhseShipmentRelease: Codeunit "Whse.-Shipment Release";
    begin
        WarehouseShipmentLine.SetRange("Source Type", _SourceType);
        WarehouseShipmentLine.SetRange("Source Subtype", _SourceSubtype);
        WarehouseShipmentLine.SetRange("Source No.", _SourceNo);
        WarehouseShipmentLine.FindFirst();
        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");
        if WarehouseShipmentHeader.Status = WarehouseShipmentHeader.Status::Open then
            WhseShipmentRelease.Release(WarehouseShipmentHeader);
    end;

    local procedure CreateWhsePick(_SourceType: Integer; _SourceSubtype: Integer; _SourceNo: Code[20])
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        WarehouseShipmentLine.SetRange("Source Type", _SourceType);
        WarehouseShipmentLine.SetRange("Source Subtype", _SourceSubtype);
        WarehouseShipmentLine.SetRange("Source No.", _SourceNo);
        WarehouseShipmentLine.FindFirst();

        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");
        if WarehouseShipmentHeader.Status = WarehouseShipmentHeader.Status::Open then
            ReleaseWhseShipment(_SourceType, _SourceSubtype, _SourceNo);
        WarehouseShipmentLine.SetHideValidationDialog(true);
        WarehouseShipmentLine.CreatePickDoc(WarehouseShipmentLine, WarehouseShipmentHeader);
    end;

    //
    // ----- BASE -----
    //

    procedure SetupAllBaseData()
    var
        MobSetup: Record "MOB Setup";
        MobPrintSetup: Record "MOB Print Setup";
        MobReportPrintSetup: Record "MOB Report Print Setup";
    begin
        // Set up base data for Mobile WMS and for testing,
        // i.e.Item, No.Series, Item Tracking etc.

        if not MobSetup.Get() then begin
            MobSetup.Init();
            MobSetup.Insert(true);
        end;

        if not MobPrintSetup.Get() then begin
            MobPrintSetup.Init();
            MobPrintSetup.Insert(true);
        end;

        if not MobReportPrintSetup.Get() then begin
            MobReportPrintSetup.Init();
            MobReportPrintSetup.Insert(true);
        end;

        SetupMobileJournals();
        SetupMobilePrintSetup();
        SetupCountryCode();
        SetupPutAwayTemplate();
        SetupNoSeries();
        SetupItemTracking();
        SetupLocations();
        SetupItems();
        SetupWhseEmployees();
        SetupMobileUsers();
        OnAfterSetupBaseData();
        DisplayCreatedMessage(TestDataLbl)
    end;

    local procedure SetupMobileJournals()
    var
        MobSetup: Record "MOB Setup";
        ItemJournalTemplate: Record "Item Journal Template";
        WhseJournalTemplate: Record "Warehouse Journal Template";
    begin
        MobSetup.Get();

        if not (Localization.IsCronusW1() or Localization.IsCronusInsider()) then exit;

        // Item & Warehouse Journals
        if MobSetup."Item Jnl. Template" = '' then
            if ItemJournalTemplate.Get('ITEM') then begin
                MobSetup.Validate("Item Jnl. Template", ItemJournalTemplate.Name);  // Item Journal Template
                MobSetup.Validate("Item Jnl. Batch", 'DEFAULT');                    // Item Journal Batch
            end;

        if MobSetup."Warehouse Jnl. Template" = '' then
            if WhseJournalTemplate.Get('ADJMT') then begin
                MobSetup.Validate("Warehouse Jnl. Template", WhseJournalTemplate.Name); // Warehouse Journal Template
                MobSetup.Validate("Warehouse Jnl. Batch", 'DEFAULT');                   // Warehouse Journal Batch
            end;


        // Reclassification
        if MobSetup."Move Item Jnl. Template" = '' then
            if ItemJournalTemplate.Get('RECLASS') then begin
                MobSetup.Validate("Move Item Jnl. Template", ItemJournalTemplate.Name); // Item Reclassification Template
                MobSetup.Validate("Unpl. Item Jnl Move Batch Name", 'DEFAULT');         // Item Reclassification Batch
            end;

        if MobSetup."Move Whse. Jnl Template" = '' then
            if WhseJournalTemplate.Get('RECLASS') then begin
                MobSetup.Validate("Move Whse. Jnl Template", WhseJournalTemplate.Name); // Warehouse Reclassification Template
                MobSetup.Validate("Unplanned Move Batch Name", 'DEFAULT');              // Warehouse Reclassification Batch
            end;


        // Physical Inventory
        if MobSetup."Inventory Jnl Template" = '' then
            if ItemJournalTemplate.Get('PHYS. INV.') then begin
                MobSetup.Validate("Inventory Jnl Template", ItemJournalTemplate.Name); // Physical Inventory Template
                MobSetup.Validate("Physical Inventory Batch", 'DEFAULT');              // Physical Inventory Batch
            end;

        if MobSetup."Whse Inventory Jnl Template" = '' then
            if WhseJournalTemplate.Get('PHYSINVT') then begin
                MobSetup.Validate("Whse Inventory Jnl Template", WhseJournalTemplate.Name); // Warehouse Physical Inventory Template
                MobSetup.Validate("Whse. Physical Inventory Batch", 'DEFAULT');             // Warehouse Physical Inventory Batch
            end;

        MobSetup.Modify();
    end;

    local procedure SetupMobilePrintSetup()
    var
        MobPrintSetup: Record "MOB Print Setup";
        MobPrinter: Record "MOB Printer";
        MobPrint: Codeunit "MOB Print";
    begin
        // Setup mobile printing
        MobPrint.CreateStandardSetup(MobPrintSetup, false);

        MobPrintSetup.Validate("Connection Tenant", 'DemoBC');
        MobPrintSetup."Connection Username" := 'demo@taskletfactory.com';
        MobPrintSetup.Modify();

        MobPrinter.Init();
        MobPrinter.Name := 'My mobile printer';
        if MobPrinter.Insert() then; // Dummy printer
    end;

    local procedure SetupMobileSetupForTotePick()
    var
        MobSetup: Record "MOB Setup";
        AllowModifySetup: Boolean;
    begin
        AllowModifySetup := MobSetup.Get() and (Localization.IsCronusW1() or Localization.IsCronusInsider());
        if not AllowModifySetup then
            exit;

        MobSetup.Get();
        if MobSetup."Enable Tote Picking" and (MobSetup."Tote per" = MobSetup."Tote per"::"Whse. Document No.") then
            exit;

        MobSetup.Validate("Enable Tote Picking", true);
        MobSetup.Validate("Tote per", MobSetup."Tote per"::"Whse. Document No.");
        MobSetup.Modify();
    end;

    local procedure SetupCountryCode()
    begin
        CreateCountryCode('DK');
    end;

    local procedure SetupPutAwayTemplate()
    var
        TempCode: Code[10];
    begin
        TempCode := 'VAR';
        CreatePutAwayTemplate(TempCode, 'Variable Template');
        CreatePutAwayTemplateLine(TempCode,
                                  '',
                                  false,
                                  true,
                                  true,
                                  true,
                                  false,
                                  false);
        CreatePutAwayTemplateLine(TempCode,
                                  '',
                                  false,
                                  true,
                                  false,
                                  false,
                                  false,
                                  true);
        CreatePutAwayTemplateLine(TempCode,
                                  '',
                                  false,
                                  true,
                                  false,
                                  false,
                                  false,
                                  false);
    end;

    local procedure CreatePutAwayTemplate(_Code: Code[20]; _Desc: Text[50])
    var
        PutAwayTemplateHeader: Record "Put-away Template Header";
    begin
        PutAwayTemplateHeader.Validate(Code, _Code);
        PutAwayTemplateHeader.Validate(Description, _Desc);
        if not PutAwayTemplateHeader.Insert() then; // Avoid error if already exists
    end;

    local procedure CreatePutAwayTemplateLine(_Code: Code[20];
                                              _Desc: Text[50];
                                              _FixedBin: Boolean;
                                              _FloatingFixedBin: Boolean;
                                              _SameItem: Boolean;
                                              _UOM: Boolean;
                                              _LessThenMin: Boolean;
                                              _Empty: Boolean
                                              )
    var
        PutAwayTemplateLine: Record "Put-away Template Line";
    begin
        PutAwayTemplateLine."Put-away Template Code" := _Code;
        PutAwayTemplateLine.Description := _Desc;
        PutAwayTemplateLine."Find Fixed Bin" := _FixedBin;
        PutAwayTemplateLine."Find Floating Bin" := _FloatingFixedBin;
        PutAwayTemplateLine."Find Same Item" := _SameItem;
        PutAwayTemplateLine."Find Unit of Measure Match" := _UOM;
        PutAwayTemplateLine."Find Bin w. Less than Min. Qty" := _LessThenMin;
        PutAwayTemplateLine."Find Empty Bin" := _Empty;
        if not PutAwayTemplateLine.Insert() then; // Avoid error if already exists
    end;

    local procedure SetupNoSeries()
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        if not NoSeries.Get('LOT') then begin
            NoSeries.Init();
            NoSeries.Code := 'LOT';
            NoSeries.Description := 'Lot Numbering';
            NoSeries."Default Nos." := true;
            NoSeries."Manual Nos." := true;
            NoSeries.Insert(true);
        end;

        if not NoSeries.Get('SERIALNO') then begin
            NoSeries.Init();
            NoSeries.Code := 'SERIALNO';
            NoSeries.Description := 'Serial No.';
            NoSeries."Default Nos." := true;
            NoSeries."Manual Nos." := true;
            NoSeries.Insert(true);
        end;

        if not NoSeriesLine.Get('LOT', 10000) then begin
            NoSeriesLine.Init();
            NoSeriesLine."Series Code" := 'LOT';
            NoSeriesLine."Line No." := 10000;
            NoSeriesLine.Validate("Starting No.", 'LOT0001');
            NoSeriesLine.Validate("Ending No.", 'LOT9999');
            NoSeriesLine.Validate("Increment-by No.", 1);
            NoSeriesLine.Validate(Open, true);
            NoSeriesLine.Insert(true);
        end;

        if not NoSeriesLine.Get('SERIALNO', 10000) then begin
            NoSeriesLine.Init();
            NoSeriesLine."Series Code" := 'SERIALNO';
            NoSeriesLine."Line No." := 10000;
            NoSeriesLine.Validate("Starting No.", 'S000001');
            NoSeriesLine.Validate("Ending No.", 'S999999');
            NoSeriesLine.Validate("Increment-by No.", 1);
            NoSeriesLine.Validate(Open, true);
            NoSeriesLine.Insert(true);
        end;
    end;

    local procedure SetupItemTracking()
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        if not ItemTrackingCode.Get('LOTSEREXP') then begin
            ItemTrackingCode.Init();
            ItemTrackingCode.Code := 'LOTSEREXP';
            ItemTrackingCode.Description := 'Lot + serial + exp. date';
            ItemTrackingCode.Validate("Man. Expir. Date Entry Reqd.", true);
            ItemTrackingCode.Validate("SN Specific Tracking", true);
            ItemTrackingCode.Validate("SN Warehouse Tracking", true);
            ItemTrackingCode.Validate("Lot Specific Tracking", true);
            ItemTrackingCode.Validate("Lot Warehouse Tracking", true);
            ItemTrackingCode.Insert(true);
        end;

        if not ItemTrackingCode.Get('LOTWHSE') then begin
            ItemTrackingCode.Init();
            ItemTrackingCode.Code := 'LOTWHSE';
            ItemTrackingCode.Description := 'Lot with warehouse tracking';
            ItemTrackingCode.Validate("Man. Expir. Date Entry Reqd.", true);
            ItemTrackingCode.Validate("Lot Specific Tracking", true);
            ItemTrackingCode.Validate("Lot Warehouse Tracking", true);
            ItemTrackingCode.Insert(true);
        end;

        if not ItemTrackingCode.Get('LOTEXPCALC') then begin
            ItemTrackingCode.Init();
            ItemTrackingCode.Code := 'LOTEXPCALC';
            ItemTrackingCode.Description := 'Lot used with expiration calculation';
            ItemTrackingCode.Validate("Lot Specific Tracking", true);
            ItemTrackingCode.Validate("Lot Warehouse Tracking", true);
            ItemTrackingCode.Insert(true);
        end;

        if not ItemTrackingCode.Get('SNOUTBOUND') then begin
            ItemTrackingCode.Init();
            ItemTrackingCode.Code := 'SNOUTBOUND';
            ItemTrackingCode.Description := 'SN Outbound Only';
            ItemTrackingCode.Validate("SN Sales Outbound Tracking", true);
            ItemTrackingCode.Insert(true);
        end;

        if not ItemTrackingCode.Get('SNWHSE') then begin
            ItemTrackingCode.Init();
            ItemTrackingCode.Code := 'SNWHSE';
            ItemTrackingCode.Description := 'Serial with warehouse tracking';
            ItemTrackingCode.Validate("SN Specific Tracking", true);
            ItemTrackingCode.Validate("SN Warehouse Tracking", true);
            ItemTrackingCode.Insert(true);
        end;

        if not ItemTrackingCode.Get('FREEENTRY') then begin
            ItemTrackingCode.Init();
            ItemTrackingCode.Code := 'FREEENTRY';
            ItemTrackingCode.Description := 'Free entry of tracking';
            ItemTrackingCode.Insert(true);
        end;
    end;

    local procedure CreateProductionBOMHeader(var _ProductionBOMHeader: Record "Production BOM Header"; _No: Code[20]; _Description: Text[50]; _BaseUnitOfMeasure: Code[10])

    begin
        _ProductionBOMHeader.Init();
        _ProductionBOMHeader.Validate("No.", _No);
        _ProductionBOMHeader.Validate(Description, _Description);
        _ProductionBOMHeader.Validate("Unit of Measure Code", _BaseUnitOfMeasure);
        _ProductionBOMHeader.Insert(true);
    end;

    local procedure CreateProductionBOMLine(var _ProductionBOMLine: Record "Production BOM Line"; _ProductionBOMNo: Code[20]; _LineNo: Integer; _ItemNo: Code[20])
    begin
        _ProductionBOMLine.Init();
        _ProductionBOMLine.Validate("Production BOM No.", _ProductionBOMNo);
        _ProductionBOMLine.Validate("Line No.", _LineNo);
        _ProductionBOMLine.Validate(Type, _ProductionBOMLine.Type::Item);
        _ProductionBOMLine.Validate("No.", _ItemNo);
        _ProductionBOMLine.Validate("Quantity per", 1);
        _ProductionBOMLine.Insert(true);
    end;

    local procedure CreateBOMComponent(var _BOMComponent: Record "BOM Component"; _LineNo: Integer; _ParentItemNo: Code[20]; _ItemNo: Code[20]; _QtyPer: Decimal)
    begin
        if not _BOMComponent.Get(_BOMComponent.Type::Item, _LineNo) then begin
            _BOMComponent.Init();
            _BOMComponent.Validate(Type, _BOMComponent.Type::Item);
            _BOMComponent.Validate("Line No.", _LineNo);
            _BOMComponent.Validate("Parent Item No.", _ParentItemNo);
            _BOMComponent.Validate("No.", _ItemNo);
            _BOMComponent.Validate("Quantity per", _QtyPer);
            _BOMComponent.Insert(true)
        end;
    end;

    local procedure CreateRoutingHeader(var _RoutingHeader: Record "Routing Header"; _No: Code[20]; _Description: Text[50])
    begin
        _RoutingHeader.Init();
        _RoutingHeader.Validate("No.", _No);
        _RoutingHeader.Validate(Description, _Description);
        _RoutingHeader.Validate(Type, _RoutingHeader.Type::Serial);
        _RoutingHeader.Insert(true);
    end;

    local procedure CreateRoutingLine(_RoutingHeaderNo: Code[20]; _RunTime: Decimal)
    var
        RoutingLine: Record "Routing Line";
        PreviousOperationNo: Code[10];
        NextOperationNo: Integer;
        NextNo: Integer;
    begin
        RoutingLine.SetRange("Routing No.", _RoutingHeaderNo);
        if RoutingLine.FindLast() then begin
            Evaluate(NextNo, RoutingLine."No.");
            NextNo += 100;

            PreviousOperationNo := RoutingLine."Operation No.";
            Evaluate(NextOperationNo, RoutingLine."Operation No.");
            NextOperationNo += 10;

            RoutingLine.Validate("Next Operation No.", Format(NextOperationNo));
            RoutingLine.Modify(true);
        end else begin
            NextNo := 100;
            NextOperationNo := 10;
        end;

        RoutingLine.Init();
        RoutingLine.Validate("Routing No.", _RoutingHeaderNo);
        RoutingLine.Validate("No.", Format(NextNo));
        RoutingLine.Validate("Operation No.", Format(NextOperationNo));
        RoutingLine.Validate("Work Center No.", Format(NextNo));
        if PreviousOperationNo <> '' then
            RoutingLine.Validate("Previous Operation No.", PreviousOperationNo);
        RoutingLine.Validate("Run Time", _RunTime);
        RoutingLine.Validate("Run Time Unit of Meas. Code", Localization.CapacityUnitOfMeaure_MINUTES());
        RoutingLine.Insert(true);

    end;

    //Setup Items
    local procedure SetupItems()
    var
        Item: Record Item;
        ItemUnitofMeasure: Record "Item Unit of Measure";
        StockkeepingUnit: Record "Stockkeeping Unit";
        RoutingHeader: Record "Routing Header";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        BOMComponent: Record "BOM Component";
        ItemReferenceMgt: Codeunit "MOB Item Reference Mgt.";
    begin

        if Item.Get('LS-2') then
            ItemReferenceMgt.CreateItemReference(Item."No.", '', Localization.UoM_PCS(), '7622400611445'); // Sales Demo

        if Item.Get('LS-S15') then
            ItemReferenceMgt.CreateItemReference(Item."No.", '', Localization.UoM_PCS(), '7622400622445'); // Sales Demo

        if Item.Get('LSU-15') then
            ItemReferenceMgt.CreateItemReference(Item."No.", '', Localization.UoM_PCS(), '7622400633445'); // Sales Demo

        if not Item.Get('70064') then begin
            Item.Init();
            Item.Validate("No.", '70064');
            Item.Validate(Description, 'Test Max Cubage');
            Item.Insert(true);

            if not ItemUnitofMeasure.Get(Item."No.", Localization.UoM_PCS()) then begin
                ItemUnitofMeasure.Init();
                ItemUnitofMeasure.Validate("Item No.", Item."No.");
                ItemUnitofMeasure.Validate(Code, Localization.UoM_PCS());
                ItemUnitofMeasure.Validate("Qty. per Unit of Measure", 1);
                ItemUnitofMeasure.Validate(Cubage, 20);
                ItemUnitofMeasure.Insert(true);
            end;

            if not ItemUnitofMeasure.Get(Item."No.", Localization.UoM_PALLET()) then begin
                ItemUnitofMeasure.Init();
                ItemUnitofMeasure.Validate("Item No.", Item."No.");
                ItemUnitofMeasure.Validate(Code, Localization.UoM_PALLET());
                ItemUnitofMeasure.Validate("Qty. per Unit of Measure", 10);
                ItemUnitofMeasure.Validate(Cubage, 200);
                ItemUnitofMeasure.Insert(true);
            end;

            Item.Validate("Base Unit of Measure", Localization.UoM_PCS());
            Item.Validate("Gen. Prod. Posting Group", Localization.GenProdPostingGroup_RETAIL());
            Item.Validate("Inventory Posting Group", Localization.InventoryPostingGroup_RESALE());
            Item.Validate("Sales Unit of Measure", Localization.UoM_PCS());
            Item.Validate("Purch. Unit of Measure", Localization.UoM_PCS());
            Item.Validate("Item Tracking Code", 'LOTWHSE');
            Item.Validate("Put-away Template Code", 'VAR');
            Item.Validate("Put-away Unit of Measure Code", Localization.UoM_PCS());
            Item.Validate("Unit Price", 20);
            Item.Validate("Unit Cost", 10);
            Item.Modify(true);

            if not StockkeepingUnit.Get(Localization.WHITE(), Item."No.", '') then begin
                StockkeepingUnit.Init();
                StockkeepingUnit.Validate("Location Code", Localization.WHITE());
                StockkeepingUnit.Validate("Item No.", Item."No.");
                StockkeepingUnit.Validate("Last Direct Cost", 36);
                StockkeepingUnit.Validate("Vendor No.", '30000');
                StockkeepingUnit.Validate("Reordering Policy", StockkeepingUnit."Reordering Policy"::"Fixed Reorder Qty.");
                StockkeepingUnit.Validate("Reorder Point", 12);
                StockkeepingUnit.Validate("Reorder Quantity", 40);
                StockkeepingUnit.Validate("Put-away Template Code", 'VAR');
                StockkeepingUnit.Validate("Put-away Unit of Measure Code", Localization.UoM_PALLET());
                StockkeepingUnit.Insert(true);
            end;

            CopyBinContentSetup(Localization.SILVER(), 'LS-75', Localization.INVBIN(), Item);
        end;

        if not Item.Get('TF-001') then begin
            Item.Init();
            Item.Validate("No.", 'TF-001');
            Item.Validate(Description, 'Marabou Orange');
            Item.Insert(true);

            CreateItemUnitOfMeasure(Item."No.", Localization.UoM_PCS(), 1);
            CreateItemUnitOfMeasure(Item."No.", Localization.UoM_BOX(), 10);

            Item.Validate("Base Unit of Measure", Localization.UoM_PCS());
            Item.Validate("Gen. Prod. Posting Group", Localization.GenProdPostingGroup_RETAIL());
            Item.Validate("Inventory Posting Group", Localization.InventoryPostingGroup_RESALE());
            Item.Validate("Shelf No.", 'TTT');
            Item.Validate("Item Category Code", Localization.ItemCategoryCode_MISC());
            Item.Validate("Sales Unit of Measure", Localization.UoM_PCS());
            Item.Validate("Purch. Unit of Measure", Localization.UoM_BOX());
            Item.Validate("Reordering Policy", Item."Reordering Policy"::Order);
            Item.Validate("Unit Price", 20);
            Item.Validate("Unit Cost", 10);
            Item.Validate(GTIN, 'GTIN-001');
            Item.Modify(true);

            if not StockkeepingUnit.Get(Localization.BLUE(), Item."No.", '') then begin
                StockkeepingUnit.Init();
                StockkeepingUnit.Validate("Location Code", Localization.BLUE());
                StockkeepingUnit.Validate("Item No.", Item."No.");
                StockkeepingUnit.Validate("Shelf No.", 'NNN');
                StockkeepingUnit.Validate("Last Direct Cost", 10);
                StockkeepingUnit.Validate("Reordering Policy", StockkeepingUnit."Reordering Policy"::Order);
                StockkeepingUnit.Insert(true);
            end;

            ItemReferenceMgt.CreateItemReference(Item."No.", '', Localization.UoM_BOX(), '114466');
            ItemReferenceMgt.CreateItemReference(Item."No.", '', Localization.UoM_PCS(), '114455');
            ItemReferenceMgt.CreateItemReference(Item."No.", '', Localization.UoM_PCS(), '7610400074520');
            ItemReferenceMgt.CreateItemReference(Item."No.", '', Localization.UoM_PCS(), '7622400624520'); // Sales Demo

            // A default Bin Code must be exist at BinContent or source line (else no Invt.PutAway is created since BC23 = 2023 Wave2)
            CopyBinContentSetup(Localization.SILVER(), 'LS-75', Localization.INVBIN(), Item);
        end;

        if not Item.Get('TF-002') then begin
            Item.Init();
            Item.Validate("No.", 'TF-002');
            Item.Validate(Description, 'Marabou Pistachio');
            Item.Insert(true);

            CreateItemUnitOfMeasure(Item."No.", Localization.UoM_PCS(), 1);
            CreateItemUnitOfMeasure(Item."No.", Localization.UoM_BOX(), 10);

            Item.Validate("Base Unit of Measure", Localization.UoM_PCS());
            Item.Validate("Gen. Prod. Posting Group", Localization.GenProdPostingGroup_RETAIL());
            Item.Validate("Inventory Posting Group", Localization.InventoryPostingGroup_RESALE());
            Item.Validate("Item Category Code", Localization.ItemCategoryCode_MISC());
            Item.Validate("Sales Unit of Measure", Localization.UoM_PCS());
            Item.Validate("Purch. Unit of Measure", Localization.UoM_PCS());
            Item.Validate("Unit Price", 20);
            Item.Validate("Unit Cost", 10);
            Item.Validate(GTIN, 'GTIN-002');
            Item.Modify(true);

            ItemReferenceMgt.CreateItemReference(Item."No.", '', Localization.UoM_PCS(), '3046920028370');
            ItemReferenceMgt.CreateItemReference(Item."No.", '', Localization.UoM_PCS(), '7622400624445'); // Sales Demo

            // A default Bin Code must be exist at BinContent or source line (else no Invt.PutAway is created since BC23 = 2023 Wave2)
            CopyBinContentSetup(Localization.SILVER(), 'LS-75', Localization.INVBIN(), Item);
        end;

        if not Item.Get('TF-003') then begin
            Item.Init();
            Item.Validate("No.", 'TF-003');
            Item.Validate(Description, 'Pukka Peppermint - LOTWHSE');
            Item.Insert(true);

            CreateItemUnitOfMeasure(Item."No.", Localization.UoM_PCS(), 1);
            CreateItemUnitOfMeasure(Item."No.", Localization.UoM_BOX(), 10);

            Item.Validate("Base Unit of Measure", Localization.UoM_PCS());
            Item.Validate("Gen. Prod. Posting Group", Localization.GenProdPostingGroup_RETAIL());
            Item.Validate("Inventory Posting Group", Localization.InventoryPostingGroup_RESALE());
            Item.Validate("Item Category Code", Localization.ItemCategoryCode_MISC());
            Item.Validate("Sales Unit of Measure", Localization.UoM_PCS());
            Item.Validate("Purch. Unit of Measure", Localization.UoM_PCS());
            Item.Validate("Item Tracking Code", 'LOTWHSE');
            Item.Validate("Unit Price", 20);
            Item.Validate("Unit Cost", 10);
            Item.Validate(GTIN, 'GTIN-003');
            Item.Modify(true);

            ItemReferenceMgt.CreateItemReference(Item."No.", '', Localization.UoM_PCS(), '03661103036043');
            ItemReferenceMgt.CreateItemReference(Item."No.", '', Localization.UoM_PCS(), '08008203800764');
            ItemReferenceMgt.CreateItemReference(Item."No.", '', Localization.UoM_PCS(), '1010154');
            ItemReferenceMgt.CreateItemReference(Item."No.", '', Localization.UoM_PCS(), '12345678901231'); // Sales Demo
            ItemReferenceMgt.CreateItemReference(Item."No.", '', Localization.UoM_PCS(), '3046920028752');
            ItemReferenceMgt.CreateItemReference(Item."No.", '', Localization.UoM_PCS(), '0850835000016'); // Sales Demo

            // A default Bin Code must be exist at BinContent or source line (else no Invt.PutAway is created since BC23 = 2023 Wave2)
            CopyBinContentSetup(Localization.SILVER(), 'LS-75', Localization.INVBIN(), Item);

        end;

        if not Item.Get('TF-004') then begin
            Item.Init();
            Item.Validate("No.", 'TF-004');
            Item.Validate(Description, '70% Cocoa - SNWHSE');
            Item.Insert(true);

            CreateItemUnitOfMeasure(Item."No.", Localization.UoM_PCS(), 1);
            CreateItemUnitOfMeasure(Item."No.", Localization.UoM_BOX(), 5);

            Item.Validate("Base Unit of Measure", Localization.UoM_PCS());
            Item.Validate("Gen. Prod. Posting Group", Localization.GenProdPostingGroup_RETAIL());
            Item.Validate("Inventory Posting Group", Localization.InventoryPostingGroup_RESALE());
            Item.Validate("Item Category Code", Localization.ItemCategoryCode_MISC());
            Item.Validate("Sales Unit of Measure", Localization.UoM_PCS());
            Item.Validate("Purch. Unit of Measure", Localization.UoM_PCS());
            Item.Validate("Item Tracking Code", 'SNWHSE');
            Item.Validate("Serial Nos.", 'SERIALNO');
            Item.Validate("Unit Price", 20);
            Item.Validate("Unit Cost", 10);
            Item.Validate(GTIN, 'GTIN-004');
            Item.Modify(true);

            ItemReferenceMgt.CreateItemReference(Item."No.", '', Localization.UoM_PCS(), '3046920028004');
            ItemReferenceMgt.CreateItemReference(Item."No.", '', Localization.UoM_PCS(), '0084984412684'); // Sales Demo

            // A default Bin Code must be exist at BinContent or source line (else no Invt.PutAway is created since BC23 = 2023 Wave2)
            CopyBinContentSetup(Localization.SILVER(), 'LS-75', Localization.INVBIN(), Item);
        end;

        if not Item.Get('TF-005') then begin
            Item.Init();
            Item.Validate("No.", 'TF-005');
            Item.Validate(Description, 'Box of chocolates - SNWHSE - ProdBom WithRoute');
            Item.Insert(true);

            CreateItemUnitOfMeasure(Item."No.", Localization.UoM_BOX(), 1);

            Item.Validate("Base Unit of Measure", Localization.UoM_BOX());
            Item.Validate("Gen. Prod. Posting Group", Localization.GenProdPostingGroup_RETAIL());
            Item.Validate("Inventory Posting Group", Localization.InventoryPostingGroup_RESALE());
            Item.Validate("Item Category Code", Localization.ItemCategoryCode_MISC());
            Item.Validate("Sales Unit of Measure", Localization.UoM_BOX());
            Item.Validate("Purch. Unit of Measure", Localization.UoM_BOX());
            Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
            Item.Validate("Manufacturing Policy", Item."Manufacturing Policy"::"Make-to-Stock");

            // Routing No.
            if not RoutingHeader.Get('TF-005') then begin
                CreateRoutingHeader(RoutingHeader, 'TF-005', 'Box of choco');

                CreateRoutingLine(RoutingHeader."No.", 5);
                CreateRoutingLine(RoutingHeader."No.", 2);

                RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
                RoutingHeader.Modify(true);
            end;

            // Production Bom No.
            if not ProductionBOMHeader.Get('TF-005') then begin
                CreateProductionBOMHeader(ProductionBOMHeader, 'TF-005', 'Box of chocolates', Item."Base Unit of Measure");

                CreateProductionBOMLine(ProductionBOMLine, ProductionBOMHeader."No.", 10000, 'TF-001');
                CreateProductionBOMLine(ProductionBOMLine, ProductionBOMHeader."No.", 20000, 'TF-002');
                CreateProductionBOMLine(ProductionBOMLine, ProductionBOMHeader."No.", 30000, 'TF-003');
                CreateProductionBOMLine(ProductionBOMLine, ProductionBOMHeader."No.", 40000, 'TF-004');

                ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
                ProductionBOMHeader.Modify(true);
            end;

            Item.Validate("Routing No.", 'TF-005');
            Item.Validate("Production BOM No.", 'TF-005');
            Item.Validate("Item Tracking Code", 'SNWHSE');
            Item.Validate("Unit Price", 200);
            Item.Validate("Unit Cost", 100);
            Item.Modify(true);

            // A default Bin Code must be exist at BinContent or source line (else no Invt.PutAway is created since BC23 = 2023 Wave2)
            CopyBinContentSetup(Localization.SILVER(), 'LS-75', Localization.INVBIN(), Item);
        end;

        if not Item.Get('TF-006') then begin
            Item.Init();
            Item.Validate("No.", 'TF-006');
            Item.Validate(Description, 'Tasklet T-Shirt - LOTWHSE');
            Item.Insert(true);

            CreateItemUnitOfMeasure(Item."No.", Localization.UoM_PCS(), 1);
            CreateItemUnitOfMeasure(Item."No.", Localization.UoM_PACK(), 10);

            CreateItemVariant(Item."No.", 'BLACK', 'Tasklet T-Shirt Black');
            CreateItemVariant(Item."No.", 'GREEN', 'Tasklet T-Shirt Green');
            CreateItemVariant(Item."No.", 'ORANGE', 'Tasklet T-Shirt Orange');
            CreateItemVariant(Item."No.", 'YELLOW', 'Tasklet T-Shirt Yellow');

            Item.Validate("Base Unit of Measure", Localization.UoM_PCS());
            Item.Validate("Gen. Prod. Posting Group", Localization.GenProdPostingGroup_RETAIL());
            Item.Validate("Inventory Posting Group", Localization.InventoryPostingGroup_RESALE());
            Item.Validate("Item Category Code", Localization.ItemCategoryCode_MISC());
            Item.Validate("Sales Unit of Measure", Localization.UoM_PCS());
            Item.Validate("Purch. Unit of Measure", Localization.UoM_PCS());
            Item.Validate("Item Tracking Code", 'LOTWHSE');
            Item.Validate("Serial Nos.", 'LOT');
            Item.Validate("Unit Price", 225);
            Item.Validate("Unit Cost", 100);
            Item.Modify(true);

            ItemReferenceMgt.CreateItemReference(Item."No.", 'BLACK', Localization.UoM_PCS(), '100001');
            ItemReferenceMgt.CreateItemReference(Item."No.", 'GREEN', Localization.UoM_PCS(), '100002');
            ItemReferenceMgt.CreateItemReference(Item."No.", 'ORANGE', Localization.UoM_PCS(), '100003');
            ItemReferenceMgt.CreateItemReference(Item."No.", 'YELLOW', Localization.UoM_PCS(), '100004');

            CreateItemSubstitution(Item."No.", 'BLACK', Item."No.", 'GREEN');
            CreateItemSubstitution(Item."No.", 'BLACK', Item."No.", 'ORANGE');
            CreateItemSubstitution(Item."No.", 'BLACK', Item."No.", 'YELLOW');
            CreateItemSubstitution(Item."No.", 'GREEN', Item."No.", 'BLACK');
            CreateItemSubstitution(Item."No.", 'GREEN', Item."No.", 'ORANGE');
            CreateItemSubstitution(Item."No.", 'YELLOW', Item."No.", 'BLACK');

            // A default Bin Code must be exist at BinContent or source line (else no Invt.PutAway is created since BC23 = 2023 Wave2)
            CopyBinContentSetup(Localization.SILVER(), 'LS-75', Localization.INVBIN(), Item);
        end;

        if not Item.Get('TF-007') then begin
            Item.Init();
            Item.Validate("No.", 'TF-007');
            Item.Validate(Description, 'Tasklet Factory Briefs - FREEENTRY');
            Item.Insert(true);

            CreateItemUnitOfMeasure(Item."No.", Localization.UoM_PCS(), 1);
            CreateItemUnitOfMeasure(Item."No.", Localization.UoM_BOX(), 5);

            CreateItemVariant(Item."No.", 'BLACK', 'Tasklet T-Shirt Black');
            CreateItemVariant(Item."No.", 'GREEN', 'Tasklet T-Shirt Green');
            CreateItemVariant(Item."No.", 'GREEN', 'Tasklet T-Shirt Green');
            CreateItemVariant(Item."No.", 'ORANGE', 'Tasklet T-Shirt Orange');
            CreateItemVariant(Item."No.", 'YELLOW', 'Tasklet T-Shirt Yellow');

            Item.Validate("Base Unit of Measure", Localization.UoM_PCS());
            Item.Validate("Gen. Prod. Posting Group", Localization.GenProdPostingGroup_RETAIL());
            Item.Validate("Inventory Posting Group", Localization.InventoryPostingGroup_RESALE());
            Item.Validate("Item Category Code", Localization.ItemCategoryCode_MISC());
            Item.Validate("Sales Unit of Measure", Localization.UoM_PCS());
            Item.Validate("Purch. Unit of Measure", Localization.UoM_PCS());
            Item.Validate("Item Tracking Code", 'FREEENTRY');
            Item.Validate("Unit Price", 100);
            Item.Validate("Unit Cost", 50);
            Item.Modify(true);

            ItemReferenceMgt.CreateItemReference(Item."No.", 'BLACK', Localization.UoM_PCS(), '200001');
            ItemReferenceMgt.CreateItemReference(Item."No.", 'GREEN', Localization.UoM_PCS(), '200002');
            ItemReferenceMgt.CreateItemReference(Item."No.", 'GREEN', Localization.UoM_PCS(), '200003');
            ItemReferenceMgt.CreateItemReference(Item."No.", 'ORANGE', Localization.UoM_PCS(), '200004');
            ItemReferenceMgt.CreateItemReference(Item."No.", 'YELLOW', Localization.UoM_PCS(), '200005');

            // A default Bin Code must be exist at BinContent or source line (else no Invt.PutAway is created since BC23 = 2023 Wave2)
            CopyBinContentSetup(Localization.SILVER(), 'LS-75', Localization.INVBIN(), Item);
        end;

        if not Item.Get('TF-LOT-SER') then begin
            Item.Init();
            Item.Validate("No.", 'TF-LOT-SER');
            Item.Validate(Description, 'TF Lot/Serial/Exp - LOTSEREXP');
            Item.Insert(true);

            CreateItemUnitOfMeasure(Item."No.", Localization.UoM_PCS(), 1);

            Item.Validate("Base Unit of Measure", Localization.UoM_PCS());
            Item.Validate("Gen. Prod. Posting Group", Localization.GenProdPostingGroup_RETAIL());
            Item.Validate("Inventory Posting Group", Localization.InventoryPostingGroup_RESALE());
            Item.Validate("Item Category Code", Localization.ItemCategoryCode_MISC());
            Item.Validate("Sales Unit of Measure", Localization.UoM_PCS());
            Item.Validate("Purch. Unit of Measure", Localization.UoM_PCS());
            Item.Validate("Item Tracking Code", 'LOTSEREXP');
            Item.Validate("Lot Nos.", 'LOT');
            Item.Validate("Unit Price", 125);
            Item.Validate("Unit Cost", 80);
            Item.Modify(true);

            ItemReferenceMgt.CreateItemReference(Item."No.", '', Localization.UoM_PCS(), '300001');

            // A default Bin Code must be exist at BinContent or source line (else no Invt.PutAway is created since BC23 = 2023 Wave2)
            CopyBinContentSetup(Localization.SILVER(), 'LS-75', Localization.INVBIN(), Item);
        end;

        if not Item.Get('TF-008') then begin
            Item.Init();
            Item.Validate("No.", 'TF-008');
            Item.Validate(Description, 'Frozen Fudge - LOTWHSE');
            Item.Insert(true);

            CreateItemUnitOfMeasure(Item."No.", Localization.UoM_PCS(), 1);
            Item.Validate("Gen. Prod. Posting Group", Localization.GenProdPostingGroup_RETAIL());
            Item.Validate("Inventory Posting Group", Localization.InventoryPostingGroup_RESALE());
            CreateItemUnitOfMeasure(Item."No.", Localization.UoM_BOX(), 10);
            Item.Validate("Base Unit of Measure", Localization.UoM_PCS());

            Item.Validate("Item Category Code", Localization.ItemCategoryCode_MISC());

            CreateWhseClass('FROZEN', '- 8 degrees Celsius');

            Item.Validate("Sales Unit of Measure", Localization.UoM_PCS());
            Item.Validate("Purch. Unit of Measure", Localization.UoM_PCS());
            Item.Validate("Item Tracking Code", 'LOTWHSE');
            Item.Validate("Unit Price", 20);
            Item.Validate("Unit Cost", 10);
            Item.Modify(true);

            CreateBin(Localization.WHITE(), Localization.Zone_WHITE_PICK(), 'W-04-0016', Localization.WhseClass_FROZEN());
            CreateBin(Localization.WHITE(), Localization.Zone_WHITE_RECEIVE(), 'W-08-0016', Localization.WhseClass_FROZEN());

            // A default Bin Code must be exist at BinContent or source line (else no Invt.PutAway is created since BC23 = 2023 Wave2)
            CopyBinContentSetup(Localization.SILVER(), 'LS-75', Localization.INVBIN(), Item);
        end;

        if not Item.Get('TF-009') then begin
            Item.Init();
            Item.Validate("No.", 'TF-009');
            Item.Validate(Description, 'Collection of chocolates - Assembly');
            Item.Insert(true);

            CreateItemUnitOfMeasure(Item."No.", Localization.UoM_BOX(), 1);

            Item.Validate("Base Unit of Measure", Localization.UoM_BOX());
            Item.Validate("Gen. Prod. Posting Group", Localization.GenProdPostingGroup_RETAIL());
            Item.Validate("Inventory Posting Group", Localization.InventoryPostingGroup_RESALE());
            Item.Validate("Item Category Code", Localization.ItemCategoryCode_MISC());
            Item.Validate("Sales Unit of Measure", Localization.UoM_BOX());
            Item.Validate("Purch. Unit of Measure", Localization.UoM_BOX());
            Item.Validate("Replenishment System", Item."Replenishment System"::Assembly);
            Item.Validate("Assembly Policy", Item."Assembly Policy"::"Assemble-to-Order");

            CreateBOMComponent(BOMComponent, 10000, 'TF-009', 'TF-002', 2);
            CreateBOMComponent(BOMComponent, 20000, 'TF-009', 'TF-003', 2);
            CreateBOMComponent(BOMComponent, 30000, 'TF-009', 'TF-004', 1);

            // A default Bin Code must be exist at BinContent or source line (else no Invt.PutAway is created since BC23 = 2023 Wave2)
            CopyBinContentSetup(Localization.SILVER(), 'LS-75', Localization.INVBIN(), Item);

            Item.Validate("Item Tracking Code", 'LOTWHSE');
            Item.Validate("Unit Price", 200);
            Item.Validate("Unit Cost", 100);
            Item.Modify(true);
        end;

        if not Item.Get('TF-010') then begin
            Item.Init();
            Item.Validate("No.", 'TF-010');
            Item.Validate(Description, 'Box of chocolates - SNWHSE - ProdBom NoRoute');
            Item.Insert(true);

            CreateItemUnitOfMeasure(Item."No.", Localization.UoM_BOX(), 1);

            Item.Validate("Base Unit of Measure", Localization.UoM_BOX());
            Item.Validate("Gen. Prod. Posting Group", Localization.GenProdPostingGroup_RETAIL());
            Item.Validate("Inventory Posting Group", Localization.InventoryPostingGroup_RESALE());
            Item.Validate("Item Category Code", Localization.ItemCategoryCode_MISC());
            Item.Validate("Sales Unit of Measure", Localization.UoM_BOX());
            Item.Validate("Purch. Unit of Measure", Localization.UoM_BOX());
            Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
            Item.Validate("Manufacturing Policy", Item."Manufacturing Policy"::"Make-to-Stock");

            // Production Bom No.
            if not ProductionBOMHeader.Get('TF-010') then begin
                CreateProductionBOMHeader(ProductionBOMHeader, 'TF-010', 'Box of chocolates', Item."Base Unit of Measure");

                CreateProductionBOMLine(ProductionBOMLine, ProductionBOMHeader."No.", 10000, 'TF-001');
                CreateProductionBOMLine(ProductionBOMLine, ProductionBOMHeader."No.", 20000, 'TF-002');
                CreateProductionBOMLine(ProductionBOMLine, ProductionBOMHeader."No.", 30000, 'TF-003');
                CreateProductionBOMLine(ProductionBOMLine, ProductionBOMHeader."No.", 40000, 'TF-004');

                ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
                ProductionBOMHeader.Modify(true);
            end;

            // A default Bin Code must be exist at BinContent or source line (else no Invt.PutAway is created since BC23 = 2023 Wave2)
            CopyBinContentSetup(Localization.SILVER(), 'LS-75', Localization.INVBIN(), Item);

            Item.Validate("Production BOM No.", 'TF-010');
            Item.Validate("Item Tracking Code", 'SNWHSE');
            Item.Validate("Unit Price", 200);
            Item.Validate("Unit Cost", 100);
            Item.Modify(true);
        end;

        if not Item.Get('TF-011') then begin
            Item.Init();
            Item.Validate("No.", 'TF-011');
            Item.Validate(Description, 'Box of chocolates - LOTWHSE - ProdBom WithRoute');
            Item.Insert(true);

            CreateItemUnitOfMeasure(Item."No.", Localization.UoM_BOX(), 1);

            Item.Validate("Base Unit of Measure", Localization.UoM_BOX());
            Item.Validate("Gen. Prod. Posting Group", Localization.GenProdPostingGroup_RETAIL());
            Item.Validate("Inventory Posting Group", Localization.InventoryPostingGroup_RESALE());
            Item.Validate("Item Category Code", Localization.ItemCategoryCode_MISC());
            Item.Validate("Sales Unit of Measure", Localization.UoM_BOX());
            Item.Validate("Purch. Unit of Measure", Localization.UoM_BOX());
            Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
            Item.Validate("Manufacturing Policy", Item."Manufacturing Policy"::"Make-to-Stock");

            // Routing No.
            if not RoutingHeader.Get('TF-011') then begin
                CreateRoutingHeader(RoutingHeader, 'TF-011', 'Box of choco');

                CreateRoutingLine(RoutingHeader."No.", 5);
                CreateRoutingLine(RoutingHeader."No.", 2);

                RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
                RoutingHeader.Modify(true);
            end;

            // Production Bom No.
            if not ProductionBOMHeader.Get('TF-011') then begin
                CreateProductionBOMHeader(ProductionBOMHeader, 'TF-011', 'Box of chocolates', Item."Base Unit of Measure");

                CreateProductionBOMLine(ProductionBOMLine, ProductionBOMHeader."No.", 10000, 'TF-001');
                CreateProductionBOMLine(ProductionBOMLine, ProductionBOMHeader."No.", 20000, 'TF-002');
                CreateProductionBOMLine(ProductionBOMLine, ProductionBOMHeader."No.", 30000, 'TF-003');
                CreateProductionBOMLine(ProductionBOMLine, ProductionBOMHeader."No.", 40000, 'TF-004');

                ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
                ProductionBOMHeader.Modify(true);
            end;

            // A default Bin Code must be exist at BinContent or source line (else no Invt.PutAway is created since BC23 = 2023 Wave2)
            CopyBinContentSetup(Localization.SILVER(), 'LS-75', Localization.INVBIN(), Item);

            Item.Validate("Routing No.", 'TF-011');
            Item.Validate("Production BOM No.", 'TF-011');
            Item.Validate("Item Tracking Code", 'LOTWHSE');
            Item.Validate("Unit Price", 200);
            Item.Validate("Unit Cost", 100);
            Item.Modify(true);
        end;

        if not Item.Get('TF-012') then begin
            Item.Init();
            Item.Validate("No.", 'TF-012');
            Item.Validate(Description, 'Box of chocolates - LOTWHSE - ProdBom NoRoute');
            Item.Insert(true);

            CreateItemUnitOfMeasure(Item."No.", Localization.UoM_BOX(), 1);

            Item.Validate("Base Unit of Measure", Localization.UoM_BOX());
            Item.Validate("Gen. Prod. Posting Group", Localization.GenProdPostingGroup_RETAIL());
            Item.Validate("Inventory Posting Group", Localization.InventoryPostingGroup_RESALE());
            Item.Validate("Item Category Code", Localization.ItemCategoryCode_MISC());
            Item.Validate("Sales Unit of Measure", Localization.UoM_BOX());
            Item.Validate("Purch. Unit of Measure", Localization.UoM_BOX());
            Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
            Item.Validate("Manufacturing Policy", Item."Manufacturing Policy"::"Make-to-Stock");

            // Production Bom No.
            if not ProductionBOMHeader.Get('TF-012') then begin
                CreateProductionBOMHeader(ProductionBOMHeader, 'TF-012', 'Box of chocolates', Item."Base Unit of Measure");

                CreateProductionBOMLine(ProductionBOMLine, ProductionBOMHeader."No.", 10000, 'TF-001');
                CreateProductionBOMLine(ProductionBOMLine, ProductionBOMHeader."No.", 20000, 'TF-002');
                CreateProductionBOMLine(ProductionBOMLine, ProductionBOMHeader."No.", 30000, 'TF-003');
                CreateProductionBOMLine(ProductionBOMLine, ProductionBOMHeader."No.", 40000, 'TF-004');

                ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
                ProductionBOMHeader.Modify(true);
            end;

            // A default Bin Code must be exist at BinContent or source line (else no Invt.PutAway is created since BC23 = 2023 Wave2)
            CopyBinContentSetup(Localization.SILVER(), 'LS-75', Localization.INVBIN(), Item);

            Item.Validate("Production BOM No.", 'TF-012');
            Item.Validate("Item Tracking Code", 'LOTWHSE');
            Item.Validate("Unit Price", 200);
            Item.Validate("Unit Cost", 100);
            Item.Modify(true);
        end;

        if not Item.Get('TF-013') then begin
            Item.Init();
            Item.Validate("No.", 'TF-013');
            Item.Validate(Description, 'Small Box of chocolates - ProdBom WithRoute');
            Item.Insert(true);

            CreateItemUnitOfMeasure(Item."No.", Localization.UoM_BOX(), 1);

            Item.Validate("Base Unit of Measure", Localization.UoM_BOX());
            Item.Validate("Gen. Prod. Posting Group", Localization.GenProdPostingGroup_RETAIL());
            Item.Validate("Inventory Posting Group", Localization.InventoryPostingGroup_RESALE());
            Item.Validate("Item Category Code", Localization.ItemCategoryCode_MISC());
            Item.Validate("Sales Unit of Measure", Localization.UoM_BOX());
            Item.Validate("Purch. Unit of Measure", Localization.UoM_BOX());
            Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
            Item.Validate("Manufacturing Policy", Item."Manufacturing Policy"::"Make-to-Stock");

            // Routing No.
            if not RoutingHeader.Get('TF-013') then begin
                CreateRoutingHeader(RoutingHeader, 'TF-013', 'Box of choco');

                CreateRoutingLine(RoutingHeader."No.", 5);
                CreateRoutingLine(RoutingHeader."No.", 2);

                RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
                RoutingHeader.Modify(true);
            end;

            // Production Bom No.
            if not ProductionBOMHeader.Get('TF-013') then begin
                CreateProductionBOMHeader(ProductionBOMHeader, 'TF-013', 'Box of chocolates', Item."Base Unit of Measure");

                CreateProductionBOMLine(ProductionBOMLine, ProductionBOMHeader."No.", 10000, 'TF-001');
                CreateProductionBOMLine(ProductionBOMLine, ProductionBOMHeader."No.", 20000, 'TF-002');

                ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
                ProductionBOMHeader.Modify(true);
            end;

            // A default Bin Code must be exist at BinContent or source line (else no Invt.PutAway is created since BC23 = 2023 Wave2)
            CopyBinContentSetup(Localization.SILVER(), 'LS-75', Localization.INVBIN(), Item);

            Item.Validate("Routing No.", 'TF-013');
            Item.Validate("Production BOM No.", 'TF-013');
            Item.Validate("Unit Price", 200);
            Item.Validate("Unit Cost", 100);
            Item.Modify(true);
        end;

        if not Item.Get('TF-014') then begin
            Item.Init();
            Item.Validate("No.", 'TF-014');
            Item.Validate(Description, 'Small Box of chocolates - ProdBom NoRoute');
            Item.Insert(true);

            CreateItemUnitOfMeasure(Item."No.", Localization.UoM_BOX(), 1);

            Item.Validate("Base Unit of Measure", Localization.UoM_BOX());
            Item.Validate("Gen. Prod. Posting Group", Localization.GenProdPostingGroup_RETAIL());
            Item.Validate("Inventory Posting Group", Localization.InventoryPostingGroup_RESALE());
            Item.Validate("Item Category Code", Localization.ItemCategoryCode_MISC());
            Item.Validate("Sales Unit of Measure", Localization.UoM_BOX());
            Item.Validate("Purch. Unit of Measure", Localization.UoM_BOX());
            Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
            Item.Validate("Manufacturing Policy", Item."Manufacturing Policy"::"Make-to-Stock");

            // Production Bom No.
            if not ProductionBOMHeader.Get('TF-014') then begin
                CreateProductionBOMHeader(ProductionBOMHeader, 'TF-014', 'Box of chocolates', Item."Base Unit of Measure");

                CreateProductionBOMLine(ProductionBOMLine, ProductionBOMHeader."No.", 10000, 'TF-001');
                CreateProductionBOMLine(ProductionBOMLine, ProductionBOMHeader."No.", 20000, 'TF-002');

                ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
                ProductionBOMHeader.Modify(true);
            end;

            // A default Bin Code must be exist at BinContent or source line (else no Invt.PutAway is created since BC23 = 2023 Wave2)
            CopyBinContentSetup(Localization.SILVER(), 'LS-75', Localization.INVBIN(), Item);

            Item.Validate("Production BOM No.", 'TF-014');
            Item.Validate("Unit Price", 200);
            Item.Validate("Unit Cost", 100);
            Item.Modify(true);
        end;

        if not Item.Get('TF-SN-OUTBOUND') then begin
            Item.Init();
            Item.Validate("No.", 'TF-SN-OUTBOUND');
            Item.Validate(Description, 'TF Serial/Outbound - SNOUTBOUND');
            Item.Insert(true);

            CreateItemUnitOfMeasure(Item."No.", Localization.UoM_PCS(), 1);
            CreateItemUnitOfMeasure(Item."No.", Localization.UoM_BOX(), 5);

            Item.Validate("Base Unit of Measure", Localization.UoM_PCS());
            Item.Validate("Gen. Prod. Posting Group", Localization.GenProdPostingGroup_RETAIL());
            Item.Validate("Inventory Posting Group", Localization.InventoryPostingGroup_RESALE());
            Item.Validate("Item Category Code", Localization.ItemCategoryCode_MISC());
            Item.Validate("Sales Unit of Measure", Localization.UoM_PCS());
            Item.Validate("Purch. Unit of Measure", Localization.UoM_PCS());
            Item.Validate("Item Tracking Code", 'SNOUTBOUND');
            Item.Validate("Lot Nos.", 'LOT');
            Item.Validate("Unit Price", 150);
            Item.Validate("Unit Cost", 120);
            Item.Modify(true);

            ItemReferenceMgt.CreateItemReference(Item."No.", '', Localization.UoM_PCS(), '400001');

            // A default Bin Code must be exist at BinContent or source line (else no Invt.PutAway is created since BC23 = 2023 Wave2)
            CopyBinContentSetup(Localization.SILVER(), 'LS-75', Localization.INVBIN(), Item);

        end;

        if not Item.Get('TF-EXP-CALC') then begin
            Item.Init();
            Item.Validate("No.", 'TF-EXP-CALC');
            Item.Validate(Description, 'TF LOT/Expiration Calculation');
            Item.Insert(true);

            CreateItemUnitOfMeasure(Item."No.", Localization.UoM_PCS(), 1);
            CreateItemUnitOfMeasure(Item."No.", Localization.UoM_BOX(), 10);

            Item.Validate("Base Unit of Measure", Localization.UoM_PCS());
            Item.Validate("Gen. Prod. Posting Group", Localization.GenProdPostingGroup_RETAIL());
            Item.Validate("Inventory Posting Group", Localization.InventoryPostingGroup_RESALE());
            Item.Validate("Shelf No.", 'TTT');
            Item.Validate("Item Category Code", Localization.ItemCategoryCode_MISC());
            Item.Validate("Sales Unit of Measure", Localization.UoM_PCS());
            Item.Validate("Purch. Unit of Measure", Localization.UoM_PCS());
            Item.Validate("Item Tracking Code", 'LOTEXPCALC');
            Item.Validate("Lot Nos.", 'LOT');
            Evaluate(Item."Expiration Calculation", '<2Y>');
            Item.Validate("Unit Price", 20);
            Item.Validate("Unit Cost", 10);
            Item.Modify(true);

            ItemReferenceMgt.CreateItemReference(Item."No.", '', Localization.UoM_BOX(), '137532');
            ItemReferenceMgt.CreateItemReference(Item."No.", '', Localization.UoM_PCS(), '857664');
            ItemReferenceMgt.CreateItemReference(Item."No.", '', Localization.UoM_PCS(), '7610400084756');

            // A default Bin Code must be exist at BinContent or source line (else no Invt.PutAway is created since BC23 = 2023 Wave2)
            CopyBinContentSetup(Localization.SILVER(), 'LS-75', Localization.INVBIN(), Item);
        end;

        if not Item.Get('TF-LOTALL') then begin
            Item.Init();
            Item.Validate("No.", 'TF-LOTALL');
            Item.Validate(Description, CopyStr('Lot Specific / no WhseTracking / no ExpDate - LOTALL', 1, StrLen(Item.Description)));
            Item.Insert(true);

            CreateItemUnitOfMeasure(Item."No.", Localization.UoM_PCS(), 1);
            CreateItemUnitOfMeasure(Item."No.", Localization.UoM_BOX(), 10);

            Item.Validate("Base Unit of Measure", Localization.UoM_PCS());
            Item.Validate("Gen. Prod. Posting Group", Localization.GenProdPostingGroup_RETAIL());
            Item.Validate("Inventory Posting Group", Localization.InventoryPostingGroup_RESALE());
            Item.Validate("Item Category Code", Localization.ItemCategoryCode_MISC());
            Item.Validate("Sales Unit of Measure", Localization.UoM_PCS());
            Item.Validate("Purch. Unit of Measure", Localization.UoM_PCS());
            Item.Validate("Item Tracking Code", 'LOTALL');
            Item.Validate("Unit Price", 20);
            Item.Validate("Unit Cost", 10);
            Item.Validate(GTIN, 'GTIN-LOTALL');
            Item.Modify(true);

            ItemReferenceMgt.CreateItemReference(Item."No.", '', Localization.UoM_PCS(), '32361103036043');
            ItemReferenceMgt.CreateItemReference(Item."No.", '', Localization.UoM_PCS(), '32308203800764');
            ItemReferenceMgt.CreateItemReference(Item."No.", '', Localization.UoM_PCS(), '3230154');
            ItemReferenceMgt.CreateItemReference(Item."No.", '', Localization.UoM_PCS(), '32345678901231');
            ItemReferenceMgt.CreateItemReference(Item."No.", '', Localization.UoM_PCS(), '3236920028752');

            // A default Bin Code must be exist at BinContent or source line (else no Invt.PutAway is created since BC23 = 2023 Wave2)
            CopyBinContentSetup(Localization.SILVER(), 'LS-75', Localization.INVBIN(), Item);
        end;

        if not Item.Get('TF-SNALL') then begin
            Item.Init();
            Item.Validate("No.", 'TF-SNALL');
            Item.Validate(Description, CopyStr('SN Specific / no WhseTracking / no ExpDate - LOTALL', 1, StrLen(Item.Description)));
            Item.Insert(true);

            CreateItemUnitOfMeasure(Item."No.", Localization.UoM_PCS(), 1);
            CreateItemUnitOfMeasure(Item."No.", Localization.UoM_BOX(), 5);

            Item.Validate("Base Unit of Measure", Localization.UoM_PCS());
            Item.Validate("Gen. Prod. Posting Group", Localization.GenProdPostingGroup_RETAIL());
            Item.Validate("Inventory Posting Group", Localization.InventoryPostingGroup_RESALE());
            Item.Validate("Item Category Code", Localization.ItemCategoryCode_MISC());
            Item.Validate("Sales Unit of Measure", Localization.UoM_PCS());
            Item.Validate("Purch. Unit of Measure", Localization.UoM_PCS());
            Item.Validate("Item Tracking Code", 'SNALL');
            Item.Validate("Serial Nos.", 'SERIALNO');
            Item.Validate("Unit Price", 20);
            Item.Validate("Unit Cost", 10);
            Item.Validate(GTIN, 'GTIN-SNALL');
            Item.Modify(true);

            ItemReferenceMgt.CreateItemReference(Item."No.", '', Localization.UoM_PCS(), '3246920028004');

            // A default Bin Code must be exist at BinContent or source line (else no Invt.PutAway is created since BC23 = 2023 Wave2)
            CopyBinContentSetup(Localization.SILVER(), 'LS-75', Localization.INVBIN(), Item);
        end;
    end;

    local procedure SetupLocations()
    var
        Location: Record Location;
    begin
        if not Location.Get('ShipRecpt') then begin
            Location.Init();
            Location.Validate(Code, 'ShipRecpt');
            Location.Validate(Name, 'Shipment Receipts No Bins');
            Location.Validate(Address, 'Alfred Nobels Vej 21B');
            Location.Validate("Post Code", '9220');
            Location.Validate(City, 'Aalborg Ø');
            Location.Validate("Country/Region Code", 'DK');
            Location.Validate(Contact, 'Peter List');
            Location.Validate("Require Shipment", true);
            Location.Validate("Require Receive", true);
            Location.Insert(true);
            CopySetupFromLocation(Localization.SILVER(), Location.Code);
        end;

        if not Location.Get('BinShipRec') then begin
            Location.Init();
            Location.Validate(Code, 'BinShipRec');
            Location.Validate(Name, 'Shipment Receipts Bins');
            Location.Validate(Address, 'Alfred Nobels Vej 21B');
            Location.Validate("Post Code", '9220');
            Location.Validate(City, 'Aalborg Ø');
            Location.Validate("Country/Region Code", 'DK');
            Location.Validate(Contact, 'Peter List');
            Location.Validate("Require Shipment", true);
            Location.Validate("Require Receive", true);
            Location.Validate("Bin Mandatory", true);
            Location.Insert(true);
            CopySetupFromLocation(Localization.SILVER(), Location.Code);
        end;

        if not Location.Get(Localization.INVBIN()) then begin
            Location.Init();
            Location.Validate(Code, Localization.INVBIN());
            Location.Validate(Name, 'Inventory With Bins');
            Location.Validate(Address, 'Alfred Nobels Vej 21B');
            Location.Validate("Post Code", '9220');
            Location.Validate(City, 'Aalborg Ø');
            Location.Validate("Country/Region Code", 'DK');
            Location.Validate(Contact, 'Peter List');
            Location.Validate("Require Pick", true);
            Location.Validate("Require Put-away", true);
            Location.Validate("Bin Mandatory", true);
            Location.Insert(true);
            CopySetupFromLocation(Localization.SILVER(), Location.Code);
            Location.Validate("Open Shop Floor Bin Code", 'S-07-0001');
            Location.Validate("To-Production Bin Code", 'S-07-0002');
            Location.Validate("From-Production Bin Code", 'S-07-0003');
            Location.Validate("From-Assembly Bin Code", 'S-07-0003');
            Location.Validate("To-Assembly Bin Code", 'S-07-0002');
            Location.Validate("Asm.-to-Order Shpt. Bin Code", 'S-07-0001');
            Location.Modify(true);
        end;

        if not Location.Get('InvNoBin') then begin
            Location.Init();
            Location.Validate(Code, 'InvNoBin');
            Location.Validate(Name, 'Inventory Without Bins');
            Location.Validate(Address, 'Alfred Nobels Vej 21B');
            Location.Validate("Post Code", '9220');
            Location.Validate(City, 'Aalborg Ø');
            Location.Validate("Country/Region Code", 'DK');
            Location.Validate(Contact, 'Peter List');
            Location.Validate("Require Pick", true);
            Location.Validate("Require Put-away", true);
            Location.Insert(true);
            CopySetupFromLocation(Localization.SILVER(), Location.Code);
        end;

        if not Location.Get('WhseBin') then begin
            Location.Init();
            Location.Validate(Code, 'WhseBin');
            Location.Validate(Name, 'Warehouse Bin Not Directed');
            Location.Validate(Address, 'Alfred Nobels Vej 21B');
            Location.Validate("Post Code", '9220');
            Location.Validate(City, 'Aalborg Ø');
            Location.Validate("Country/Region Code", 'DK');
            Location.Validate(Contact, 'Peter List');
            Location.Validate("Require Pick", true);
            Location.Validate("Require Put-away", true);
            Location.Validate("Require Receive", true);
            Location.Validate("Require Shipment", true);
            Location.Validate("Bin Mandatory", true);
            Location.Insert(true);
            CopySetupFromLocation(Localization.SILVER(), Location.Code);
        end;

        if Location.Get('SILVER') then begin
            Location.Validate("Open Shop Floor Bin Code", 'S-07-0001');
            Location.Validate("To-Production Bin Code", 'S-07-0002');
            Location.Validate("From-Production Bin Code", 'S-07-0003');
            Location.Modify(true);
        end;

        if Location.Get('WHITE') then begin
            Location.Validate("To-Assembly Bin Code", 'W-07-0002');
            Location.Validate("From-Assembly Bin Code", 'W-07-0003');
            Location.Modify(true);
        end;
    end;

    local procedure SetupWhseEmployees()
    var
        WarehouseEmployee: Record "Warehouse Employee";
        User: Record User;
        Location: Record Location;
    begin
        if User.FindSet() then
            repeat
                Location.SetRange("Use As In-Transit", false);
                if Location.FindSet() then
                    repeat
                        if not WarehouseEmployee.Get(User."User Name", Location.Code) then begin
                            WarehouseEmployee.Init();
                            WarehouseEmployee.Validate("User ID", User."User Name");
                            WarehouseEmployee.Validate("Location Code", Location.Code);

                            if (Location.Code = Localization.WHITE()) and not WhseEmployeeHasDefLoc(User."User Name") then
                                WarehouseEmployee.Default := true;

                            WarehouseEmployee.Insert(true);
                        end;
                    until Location.Next() = 0;
            until User.Next() = 0;
    end;

    local procedure SetupMobileUsers()
    var
        User: Record User;
        MobUser: Record "MOB User";
        MobGroupUser: Record "MOB Group User";
        MobGroup: Record "MOB Group";
    begin
        if User.FindSet() then
            repeat
                if not MobUser.Get(User."User Name") then begin
                    MobUser.Init();
                    MobUser.Validate("User ID", User."User Name");
                    MobUser.Insert(true);
                end;

                if MobUser.Get(User."User Name") then
                    if MobGroup.FindFirst() then
                        if not MobGroupUser.Get(MobGroup.Code, MobUser."User ID") then begin
                            MobGroupUser.Validate("Group Code", MobGroup.Code);
                            MobGroupUser.Validate("Mobile User ID", MobUser."User ID");
                            MobGroupUser.Insert(true);
                        end;
            until User.Next() = 0;
    end;

    internal procedure SetupPackAndShip()
    var
        MobSetup: Record "MOB Setup";
        MobPackageType: Record "MOB Package Type";
        MobPackingStation: Record "MOB Packing Station";
        MobPackingSetup: Record "MOB Mobile WMS Package Setup";
        MobPackAPI: Codeunit "MOB Pack API";
    begin

        // MOB Setup
        MobSetup.Get();
        MobSetup.Validate("Enable Tote Picking", true);
        MobSetup.Validate(MobSetup."Tote per", MobSetup."Tote per"::"Whse. Document No.");
        MobSetup.Modify();

        MobSetup.Validate("Enable Pack and Ship", true);
        MobSetup.Validate("LP Number Series", 'DDM'); // Standard Cronus data
        MobSetup.Validate("Pick Collect Packing Station", true);
        MobSetup.Validate("Dimensions Unit", 'MILES'); // Standard Cronus data
        MobSetup.Validate("Weight Unit", 'KG'); // Standard Cronus data
        MobSetup.Modify();

        //Package Types        
        MobPackageType.Init();
        MobPackageType.Code := 'BOX';
        MobPackageType.Description := 'Box';
        MobPackageType.Height := 100;
        MobPackageType.Weight := 50;
        if MobPackageType.Insert() then; // Avoid error if already exists

        MobPackageType.Init();
        MobPackageType.Code := 'BAG';
        MobPackageType.Description := 'Bag';
        MobPackageType.Height := 50;
        MobPackageType.Weight := 10;
        if MobPackageType.Insert() then; // Avoid error if already exists

        MobPackageType.Init();
        MobPackageType.Code := 'PALLET';
        MobPackageType.Description := 'Pallet';
        MobPackageType.Height := 500;
        MobPackageType.Weight := 100;
        if MobPackageType.Insert() then; // Avoid error if already exists

        // Call API to Syncronize data
        MobPackAPI.OnSynchronizePackageTypes(MobPackageType);

        //Packing Stations
        MobPackingStation.Init();
        MobPackingStation.Code := 'PACK A';
        MobPackingStation.Description := 'Packing Station A';
        if MobPackingStation.Insert() then; // Avoid error if already exists

        MobPackingStation.Init();
        MobPackingStation.Code := 'PACK B';
        MobPackingStation.Description := 'Packing Station B';
        if MobPackingStation.Insert() then; // Avoid error if already exists

        // Call API to Syncronize data
        MobPackAPI.OnSynchronizePackingStations(MobPackingStation);

        //Package Setup
        MobPackingSetup.Init();
        MobPackingSetup.Validate("Shipping Agent", 'UPS'); // Standard Cronus data
        MobPackingSetup.Validate("Package Type", 'BOX');
        MobPackingSetup.Validate("Default Package Type", true);
        MobPackingSetup."Register Weight" := true;
        MobPackingSetup."Register Height" := true;
        if MobPackingSetup.Insert() then; // Avoid error if already exists

        MobPackingSetup.Init();
        MobPackingSetup.Validate("Shipping Agent", 'UPS'); // Standard Cronus data
        MobPackingSetup.Validate("Package Type", 'BAG');
        MobPackingSetup."Register Weight" := true;
        if MobPackingSetup.Insert() then; // Avoid error if already exists

        MobPackingSetup.Init();
        MobPackingSetup.Validate("Shipping Agent", 'UPS'); // Standard Cronus data
        MobPackingSetup.Validate("Package Type", 'PALLET');
        MobPackingSetup."Register Weight" := true;
        MobPackingSetup."Register Height" := true;
        if MobPackingSetup.Insert() then; // Avoid error if already exists
    end;

    local procedure CreateItemUnitOfMeasure(_ItemNo: Code[20]; _UoM: Code[10]; _QtyPerUoM: Decimal)
    var
        ItemUnitofMeasure: Record "Item Unit of Measure";
    begin
        if not ItemUnitofMeasure.Get(_ItemNo, _UoM) then begin
            ItemUnitofMeasure.Init();
            ItemUnitofMeasure.Validate("Item No.", _ItemNo);
            ItemUnitofMeasure.Validate(Code, _UoM);
            ItemUnitofMeasure.Validate("Qty. per Unit of Measure", _QtyPerUoM);
            ItemUnitofMeasure.Insert(true);
        end;
    end;

    local procedure CreateItemVariant(_ItemNo: Code[20]; _VariantCode: Code[10]; _Description: Text[30])
    var
        ItemVariant: Record "Item Variant";
    begin
        if not ItemVariant.Get(_ItemNo, _VariantCode) then begin
            ItemVariant.Init();
            ItemVariant.Validate("Item No.", _ItemNo);
            ItemVariant.Validate(Code, _VariantCode);
            ItemVariant.Validate(Description, _Description);
            ItemVariant.Insert(true);
        end;
    end;

    local procedure CreateItemSubstitution(_No: Code[20]; _VariantCode: Code[10]; _SubstituteNo: Code[20]; _SubstituteVariantCode: Code[10])
    var
        ItemSubstitution: Record "Item Substitution";
    begin
        if not ItemSubstitution.Get(ItemSubstitution.Type::Item, _No, _VariantCode, ItemSubstitution.Type::Item, _SubstituteNo, _SubstituteVariantCode) then begin
            ItemSubstitution.Init();
            ItemSubstitution.Validate(Type, ItemSubstitution.Type::Item);
            ItemSubstitution.Validate("No.", _No);
            ItemSubstitution.Validate("Variant Code", _VariantCode);
            ItemSubstitution.Validate("Substitute Type", ItemSubstitution.Type::Item);
            ItemSubstitution.Validate("Substitute No.", _SubstituteNo);
            ItemSubstitution.Validate("Substitute Variant Code", _SubstituteVariantCode);
            ItemSubstitution.Insert(true);
        end;
    end;

    local procedure CreateWhseClass(_WhseClassCode: Code[20]; _Description: Text[30])
    var
        WarehouseClass: Record "Warehouse Class";
    begin
        if not WarehouseClass.Get(_WhseClassCode) then begin
            WarehouseClass.Init();
            WarehouseClass.Validate(Code, _WhseClassCode);
            WarehouseClass.Validate(Description, _Description);
            WarehouseClass.Insert(true);
        end;
    end;

    local procedure CopySetupFromLocation(_FromLocation: Code[20]; _ToLocation: Code[20])
    var
        FromZone: Record Zone;
        ToZone: Record Zone;
        FromBins: Record Bin;
        ToBins: Record Bin;
        FromBinContent: Record "Bin Content";
        ToBinContent: Record "Bin Content";
        FromInventoryPostingSetup: Record "Inventory Posting Setup";
        ToInventoryPostingSetup: Record "Inventory Posting Setup";
    begin
        FromZone.SetRange("Location Code", _FromLocation);
        if FromZone.FindSet() then
            repeat
                ToZone.Init();
                ToZone.TransferFields(FromZone);
                ToZone."Location Code" := _ToLocation;
                if ToZone.Insert(true) then;
            until FromZone.Next() = 0;

        FromBins.SetRange("Location Code", _FromLocation);
        if FromBins.FindSet() then
            repeat
                ToBins.Init();
                ToBins.TransferFields(FromBins);
                ToBins.Validate("Location Code", _ToLocation);
                if ToBins.Insert(true) then;
            until FromBins.Next() = 0;

        FromBinContent.Reset();
        FromBinContent.SetRange("Location Code", _FromLocation);
        FromBinContent.FilterGroup(-1); // Cross Column Search
        FromBinContent.SetRange(Default, true);
        FromBinContent.SetRange(Fixed, true);
        FromBinContent.FilterGroup(0); // Standard
        if FromBinContent.FindSet() then
            repeat
                ToBinContent.Init();
                ToBinContent.TransferFields(FromBinContent);
                ToBinContent."Location Code" := _ToLocation; // No validation (avoid check for manual change and do not clear Bin Code)
                if ToBinContent.Insert(true) then;
            until FromBinContent.Next() = 0;

        FromInventoryPostingSetup.SetRange("Location Code", _FromLocation);
        if FromInventoryPostingSetup.FindSet() then
            repeat
                ToInventoryPostingSetup.Init();
                ToInventoryPostingSetup.TransferFields(FromInventoryPostingSetup);
                ToInventoryPostingSetup.Validate("Location Code", _ToLocation);
                if ToInventoryPostingSetup.Insert(true) then;
            until FromInventoryPostingSetup.Next() = 0;
    end;

    /// <summary>
    /// Gets an item from a Fixed/ Default bin and copies setup to a new item.
    /// No. and Base UoM are copied from the new item  
    /// </summary>
    local procedure CopyBinContentSetup(_FromLocation: Code[20]; _FromItem: Code[20]; _ToLocation: Code[20]; _ToItem: Record Item)
    var
        FromBinContent: Record "Bin Content";
        ToBinContent: Record "Bin Content";
    begin
        FromBinContent.Reset();
        FromBinContent.SetRange("Location Code", _FromLocation);
        FromBinContent.SetRange("Item No.", _FromItem);
        FromBinContent.FilterGroup(-1); // Cross Column Search
        FromBinContent.SetRange(Default, true);
        FromBinContent.SetRange(Fixed, true);
        FromBinContent.FilterGroup(0); // Standard
        if FromBinContent.FindSet() then
            repeat
                ToBinContent.Init();
                ToBinContent.TransferFields(FromBinContent);
                ToBinContent."Location Code" := _ToLocation; // No validation (avoid check for manual change and do not clear Bin Code)
                ToBinContent."Item No." := _ToItem."No.";
                ToBinContent."Variant Code" := '';  // Copying setup from other item that may have other variants
                ToBinContent."Unit of Measure Code" := _ToItem."Base Unit of Measure"; //Copying Base unit of measure from item
                if ToBinContent.Insert(true) then; // Avoid error if already exists
            until FromBinContent.Next() = 0;
    end;

    local procedure CreateBin(_LocationCode: Code[10]; _ZoneCode: Code[10]; _BinCode: Code[20]; _WhseClassCode: Code[10])
    var
        Bin: Record Bin;
    begin
        if not Bin.Get(_LocationCode, _BinCode) then begin
            Bin.Init();
            Bin.Validate("Location Code", _LocationCode);
            Bin.Validate("Zone Code", _ZoneCode);
            Bin.Validate(Code, _BinCode);
            Bin.Insert(true);
        end else begin
            Bin.Validate("Warehouse Class Code", _WhseClassCode);
            Bin.Modify(true);
        end;
    end;

    local procedure CreateCountryCode(_CountryCode: Code[10])
    var
        CountryRegion: Record "Country/Region";
    begin
        CountryRegion.Code := _CountryCode;
        if not CountryRegion.Insert(true) then; // Avoid error if already exists
    end;

    procedure AddInventory(_LocationCode: Code[10]; _Bin: Code[20]; _ItemNo: Code[20]; _VariantCode: Code[10]; _LotNumber: Code[50]; _SerialNo: Code[50]; _Quantity: Decimal; _UoM: Code[10])
    begin
        // Add to existing inventory
        CreateInventory(_LocationCode, _Bin, _ItemNo, _VariantCode, _LotNumber, _SerialNo, _Quantity, _UoM, true);
    end;

    procedure CreateInventory(_LocationCode: Code[10]; _Bin: Code[20]; _ItemNo: Code[20]; _VariantCode: Code[10]; _LotNumber: Code[50]; _SerialNo: Code[50]; _Quantity: Decimal; _UoM: Code[10])
    begin
        // Overwrite existing inventory
        CreateInventory(_LocationCode, _Bin, _ItemNo, _VariantCode, _LotNumber, _SerialNo, _Quantity, _UoM, false);
    end;

    local procedure CreateInventory(_LocationCode: Code[10]; _Bin: Code[20]; _ItemNo: Code[20]; _VariantCode: Code[10]; _LotNumber: Code[50]; _SerialNo: Code[50]; _Quantity: Decimal; _UoM: Code[10]; _KeepExistingInventory: Boolean)
    var
        Item: Record Item;
        BinRec: Record Bin;
        Location: Record Location;
        DummyILE: Record "Item Ledger Entry";
        SourceCode: Record "Source Code";
        BinContent: Record "Bin Content";
        ItemJnlLine: Record "Item Journal Line";
        ItemJnlLine2: Record "Item Journal Line";
        MobSetup: Record "MOB Setup";
        TempWhseJnlLine: Record "Warehouse Journal Line" temporary;
        ReservationEntry: Record "Reservation Entry";
        MobTrackingSetup: Record "MOB Tracking Setup";
        WMSMgt: Codeunit "WMS Management";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
        WhseJnlPostLine: Codeunit "Whse. Jnl.-Register Line";
        CreateReservationEntry: Codeunit "Create Reserv. Entry";
        QuantityBase: Decimal;
        AdjustedQuantity: Decimal;
        RegisterExpirationDate: Boolean;
        NewLotNo: Code[50];
        NewSerialNo: Code[50];
        Inbound: Boolean;
    begin

        MobSetup.Get();

        Location.Get(_LocationCode);

        Item.Get(_ItemNo);
        Item.TestField("Base Unit of Measure");

        if _LotNumber = '*' then
            // No Line No. is included in NewLotNo when updated from this function, use TestData.AddLineWithRef to have a line number included
            NewLotNo := CopyStr('L-' + DelChr(CreateGuid(), '<>', '{}'), 1, 50)
        else
            NewLotNo := _LotNumber;

        if _SerialNo = '*' then
            // No Line No. is included in NewSerialNo when updated from this function, use TestData.AddLineWithRef to have a line number included
            NewSerialNo := CopyStr('S-' + DelChr(CreateGuid(), '<>', '{}'), 1, 50)
        else
            NewSerialNo := _SerialNo;

        // Perform the posting
        ItemJnlLine.Init();
        ItemJnlLine."Document No." := MobWmsLanguage.GetMessage('HANDHELD');
        ItemJnlLine.Validate("Item No.", _ItemNo);
        ItemJnlLine.Validate("Variant Code", _VariantCode);
        ItemJnlLine.Validate("Posting Date", WorkDate());
        ItemJnlLine."Source Code" := SourceCode.Code;
        ItemJnlLine.Validate("Location Code", _LocationCode);
        ItemJnlLine.Validate("Unit of Measure Code", Item."Base Unit of Measure");

        ItemJnlLine."Phys. Inventory" := true;
        if _Bin <> '' then begin
            BinContent.SetRange("Location Code", _LocationCode);
            BinContent.SetRange("Bin Code", _Bin);
            BinContent.SetRange("Item No.", _ItemNo);
            BinContent.SetRange("Variant Code", _VariantCode);
            if Location."Directed Put-away and Pick" then
                BinContent.SetRange("Unit of Measure Code", _UoM);
            BinContent.SetRange("Lot No. Filter", NewLotNo);
            BinContent.SetRange("Serial No. Filter", NewSerialNo);
            BinContent.SetAutoCalcFields("Quantity (Base)");
            if BinContent.FindFirst() then
                ItemJnlLine."Qty. (Calculated)" := BinContent."Quantity (Base)";
        end else begin
            Item.SetRange("Location Filter", _LocationCode);
            Item.SetRange("Variant Filter", _VariantCode);
            Item.SetRange("Lot No. Filter", NewLotNo);
            Item.SetRange("Serial No. Filter", NewSerialNo);
            Item.SetAutoCalcFields(Inventory);
            if Item.Get(_ItemNo) then
                ItemJnlLine."Qty. (Calculated)" := Item.Inventory;
        end;

        QuantityBase := MobWmsToolbox.CalcQtyNewUOMRounded(ItemJnlLine."Item No.", _Quantity, _UoM, Item."Base Unit of Measure");
        if _KeepExistingInventory then
            ItemJnlLine.Validate("Qty. (Phys. Inventory)", ItemJnlLine."Qty. (Calculated)" + QuantityBase)   // Add to existing inventory
        else
            ItemJnlLine.Validate("Qty. (Phys. Inventory)", QuantityBase);   // Overwrite existing inventory

        ItemJnlLine.Validate("Bin Code", _Bin);

        if ItemJnlLine.Quantity = 0 then  // Already has exact target Quantity on inventory
            exit;

        Inbound := ItemJnlLine.Signed(ItemJnlLine.Quantity) >= 0;

        Clear(MobTrackingSetup);
        DetermineAdjustmentItemTracking(_ItemNo, MobToolbox.AsInteger(ItemJnlLine."Entry Type"), Inbound, MobTrackingSetup, RegisterExpirationDate);
        MobTrackingSetup."Serial No." := NewSerialNo;
        MobTrackingSetup."Lot No." := NewLotNo;
        // Package No. not supported in Test Helper

        if MobTrackingSetup."Lot No. Required" or MobTrackingSetup."Serial No. Required" then begin

            // The function expects the quantity to be in the base UoM
            MobTrackingSetup.CreateReservEntryFor(
                CreateReservationEntry,
                83,
                MobToolbox.AsInteger(ItemJnlLine."Entry Type"),
                ItemJnlLine."Source No.",
                '', // ForBatchName
                0,  // ForProdOrderLine
                0,  // SourceLineNo
                ItemJnlLine."Qty. per Unit of Measure",
                ItemJnlLine.Quantity,
                ItemJnlLine."Quantity (Base)");

            // If the ExpirationDate is registered it must be set on the reservation entry
            if RegisterExpirationDate then
                CreateReservationEntry.SetDates(0D, WorkDate());

            CreateReservationEntry.CreateEntry(ItemJnlLine."Item No.",
                                               ItemJnlLine."Variant Code",
                                               ItemJnlLine."Location Code",
                                               '',   //Description
                                               0D,
                                               WorkDate(),
                                               0,  // Tranferred from entry no.
                                               ReservationEntry."Reservation Status"::Prospect);

        end;

        // Take copy of Item Journal Line to preserve Quantity according to Unit of Measure
        ItemJnlLine2.Copy(ItemJnlLine);

        // TEMPORARY WORKAROUND:
        // -- spring relaese 2019 currently got an error in standard code: CU22 Item Jnl.-Post Line.CheckExpirationDate() will blank
        // -- Expiration Date when new field ItemTrackingCode."Use Expiration Dates" is set, and no ItemLedgerEntry exists for the item
        // -- cannot be solved wit EventSubscribers... workaround: Create a dummy ILE and delete it after posting
        // -- dummmy record is found and used in ItemTrackingMgt."ExistingExpirationDate" (called from ItemJnlPostLine.CheckExpirationDate)
        if (RegisterExpirationDate) then begin
            Clear(DummyILE);
            DummyILE."Entry No." := -1234567890;
            DummyILE."Item No." := ItemJnlLine."Item No.";
            DummyILE."Variant Code" := ItemJnlLine."Variant Code";
            MobTrackingSetup.CopyTrackingToItemLedgerEntry(DummyILE);
            DummyILE."Expiration Date" := WorkDate();
            DummyILE.Positive := true;
            DummyILE.Insert(false);
        end;

        ItemJnlPostLine.RunWithCheck(ItemJnlLine);

        // TEMPORARY WORKAROUND:
        // -- spring relaese 2019 currently got an error in standard code: CU22 Item Jnl.-Post Line.CheckExpirationDate() will blank
        // -- Expiration Date when new field ItemTrackingCode."Use Expiration Dates" is set, and no ItemLedgerEntry exists for the item
        // -- cannot be solved wit EventSubscribers... workaround: Create a dummy ILE and delete it after posting
        // -- dummmy record is found and used in ItemTrackingMgt."ExistingExpirationDate" (called from ItemJnlPostLine.CheckExpirationDate)
        if (RegisterExpirationDate) then
            DummyILE.Delete(false);

        if ItemJnlLine."Location Code" <> '' then begin
            Location.Get(ItemJnlLine."Location Code");
            if Location."Bin Mandatory" then
                // When using Directed Put-away and Pick, Zone Code and Bin Code is set to Adjustment bin from Location Card. This must be
                // overwritten to post on the correct Zone and Bin.
                if WMSMgt.CreateWhseJnlLine(ItemJnlLine2, 1, TempWhseJnlLine, false) then begin
                    TempWhseJnlLine."Lot No." := ItemJnlLine."Lot No.";
                    TempWhseJnlLine."Serial No." := ItemJnlLine."Serial No.";
                    TempWhseJnlLine."Expiration Date" := ItemJnlLine."Item Expiration Date";
                    if Location."Directed Put-away and Pick" then begin
                        TempWhseJnlLine."Journal Template Name" := MobSetup."Whse Inventory Jnl Template";

                        // ItemJnlLine is always base UoM -- for directed putaway and pick the WhseJnlLine needs to be exact UoM
                        AdjustedQuantity := MobWmsToolbox.CalcQtyNewUOMRounded(TempWhseJnlLine."Item No.", ItemJnlLine.Quantity, ItemJnlLine."Unit of Measure Code", _UoM);
                        TempWhseJnlLine.Quantity := AdjustedQuantity;
                        TempWhseJnlLine.Validate("Unit of Measure Code", _UoM);

                        if TempWhseJnlLine."Entry Type" = TempWhseJnlLine."Entry Type"::"Positive Adjmt." then begin
                            BinContent.SetRange("Location Code", _LocationCode);
                            BinContent.SetRange("Bin Code", _Bin);
                            BinContent.SetRange("Item No.", _ItemNo);
                            BinContent.SetRange("Variant Code", _VariantCode);
                            BinContent.SetRange("Lot No. Filter", NewLotNo);
                            BinContent.SetRange("Serial No. Filter", NewSerialNo);
                            BinContent.SetRange("Unit of Measure Code", TempWhseJnlLine."Unit of Measure Code");
                            if BinContent.FindFirst() then begin
                                BinContent.CheckWhseClass(false);
                                TempWhseJnlLine.Validate("To Zone Code", BinContent."Zone Code");
                                TempWhseJnlLine.Validate("To Bin Code", BinContent."Bin Code");
                            end else begin
                                BinRec.SetRange("Location Code", _LocationCode);
                                BinRec.SetRange(Code, _Bin);
                                if BinRec.FindFirst() then begin
                                    BinRec.CheckWhseClass(_ItemNo, false);
                                    TempWhseJnlLine.Validate("To Zone Code", BinRec."Zone Code");
                                    TempWhseJnlLine.Validate("To Bin Code", BinRec.Code);
                                end;
                            end;
                            // Unset Adjustment Bin (was set from WhseJnlLine.SetAdjustmentBin())
                            TempWhseJnlLine."From Zone Code" := '';
                            TempWhseJnlLine."From Bin Code" := '';
                            TempWhseJnlLine."From Bin Type Code" := '';
                        end else
                            if TempWhseJnlLine."Entry Type" = TempWhseJnlLine."Entry Type"::"Negative Adjmt." then begin
                                //Validation is deliberately not performed
                                TempWhseJnlLine."From Zone Code" := BinContent."Zone Code";
                                TempWhseJnlLine."From Bin Type Code" := BinContent."Bin Type Code";
                                TempWhseJnlLine."From Bin Code" := BinContent."Bin Code";
                            end;
                    end;
                    WhseJnlPostLine.Run(TempWhseJnlLine);
                end;
        end;
    end;

    local procedure DetermineAdjustmentItemTracking(_ItemNo: Code[20]; _ItemLedgerEntryType: Integer; _Inbound: Boolean; var _MobTrackingSetup: Record "MOB Tracking Setup"; var _RegisterExpirationDate: Boolean)
    var
        ItemTrackingCode: Record "Item Tracking Code";
        Item: Record Item;
        MobItemTrackingManagement: Codeunit "MOB Item Tracking Management";
    begin
        _MobTrackingSetup.ClearTrackingRequired();
        _RegisterExpirationDate := false;

        if Item.Get(_ItemNo) then
            if ItemTrackingCode.Get(Item."Item Tracking Code") then begin
                MobItemTrackingManagement.GetItemTrackingSetup(ItemTrackingCode, _ItemLedgerEntryType, _Inbound, _MobTrackingSetup);
                _RegisterExpirationDate := ItemTrackingCode."Man. Expir. Date Entry Reqd.";
            end;
    end;

    local procedure DisplayCreatedMessage(_Message: Text[1024])
    begin
        if GuiAllowed() and (not HideMessages) then
            Message(CreatedMsg, _Message);
    end;

    procedure SetHideMessages(_Set: Boolean)
    begin
        HideMessages := _Set;
    end;

    local procedure WhseEmployeeHasDefLoc(_User: Code[50]): Boolean
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        // Warehouse Employee already have a default location
        WarehouseEmployee.SetRange("User ID", _User);
        WarehouseEmployee.SetRange(Default, true);
        exit(not WarehouseEmployee.IsEmpty());
    end;

    procedure CalcWhseQtyBase(_LocationCode: Code[10]; _Bin: Code[20]; _ItemNo: Code[20]; _VariantCode: Code[10]; _LotNumber: Code[50]; _SerialNo: Code[50]): Decimal
    var
        WhseEntry: Record "Warehouse Entry";
    begin
        WhseEntry.Reset();
        if _LocationCode <> '' then
            WhseEntry.SetRange("Location Code", _LocationCode);
        if _Bin <> '' then
            WhseEntry.SetRange("Bin Code", _Bin);
        if _ItemNo <> '' then
            WhseEntry.SetRange("Item No.", _ItemNo);
        if _VariantCode <> '' then
            WhseEntry.SetRange("Variant Code", _VariantCode);
        // no UoM filter
        if _LotNumber <> '' then
            WhseEntry.SetRange("Lot No.", _LotNumber);
        if _SerialNo <> '' then
            WhseEntry.SetRange("Serial No.", _SerialNo);
        WhseEntry.CalcSums("Qty. (Base)");
        exit(WhseEntry."Qty. (Base)");
    end;

    procedure CalcWhseQty(LocationCode: Code[10]; Bin: Code[20]; ItemNo: Code[20]; VariantCode: Code[10]; LotNumber: Code[50]; SerialNo: Code[50]; UoMCode: Code[10]): Decimal
    var
        WhseEntry: Record "Warehouse Entry";
    begin
        WhseEntry.Reset();
        if LocationCode <> '' then
            WhseEntry.SetRange("Location Code", LocationCode);
        if Bin <> '' then
            WhseEntry.SetRange("Bin Code", Bin);
        if ItemNo <> '' then
            WhseEntry.SetRange("Item No.", ItemNo);
        if VariantCode <> '' then
            WhseEntry.SetRange("Variant Code", VariantCode);
        if UoMCode <> '' then
            WhseEntry.SetRange("Unit of Measure Code", UoMCode);
        if LotNumber <> '' then
            WhseEntry.SetRange("Lot No.", LotNumber);
        if SerialNo <> '' then
            WhseEntry.SetRange("Serial No.", SerialNo);
        WhseEntry.CalcSums("Qty. (Base)");
        exit(WhseEntry."Qty. (Base)");
    end;

    procedure CalcInvQtyBase(_LocationCode: Code[10]; _ItemNo: Code[20]; _VariantCode: Code[10]; _LotNumber: Code[50]; _SerialNo: Code[50]): Decimal
    var
        Item: Record Item;
    begin
        if _LocationCode <> '' then
            Item.SetRange("Location Filter", _LocationCode);
        if _VariantCode <> '' then
            Item.SetRange("Variant Filter", _VariantCode);
        if _LotNumber <> '' then
            Item.SetRange("Lot No. Filter", _LotNumber);
        if _SerialNo <> '' then
            Item.SetRange("Serial No. Filter", _SerialNo);
        Item.SetAutoCalcFields(Inventory);
        if Item.Get(_ItemNo) then;
        exit(Item.Inventory);
    end;

    //
    // ------------------ CREATE TEST DATA ------------------
    //
    // Create commonly used data sets for testing

    procedure CreateData_XL(var _TestData: Record "MOB Test Data" temporary; _LocationCode: Code[10]; _CreateInventory: Boolean; _SetExpirationDate: Boolean)
    var
        Name: Code[20];
    begin
        Name := 'XL';
        AssertTemporaryRecord(_TestData);

        _TestData.DeleteAll();
        _TestData.AddLineWithRef(Name, 0, 10000, _LocationCode, '', '', 'TF-002', '', 0D, '', Localization.UoM_PCS(), _CreateInventory, 15, 15);
        if _SetExpirationDate then
            _TestData.AddLineWithRef(Name, 0, 20000, _LocationCode, '', '', 'TF-003', '*', WorkDate(), '', Localization.UoM_PCS(), _CreateInventory, 15, 15)
        else
            _TestData.AddLineWithRef(Name, 0, 20000, _LocationCode, '', '', 'TF-003', '*', 0D, '', Localization.UoM_PCS(), _CreateInventory, 15, 15);
        _TestData.AddLineWithRef(Name, 0, 30000, _LocationCode, '', '', 'TF-004', '', 0D, '*', Localization.UoM_PCS(), _CreateInventory, 1, 1);
        _TestData.AddLineWithRef(Name, 0, 30000, _LocationCode, '', '', 'TF-004', '', 0D, '*', Localization.UoM_PCS(), _CreateInventory, 1, 1);
        _TestData.AddLineWithRef(Name, 0, 30000, _LocationCode, '', '', 'TF-004', '', 0D, '*', Localization.UoM_PCS(), _CreateInventory, 1, 1);
    end;

    procedure CreateData_Small_NonWarehouse(var _TestData: Record "MOB Test Data" temporary; _LocationCode: Code[10]; _CreateInventory: Boolean; _SetExpirationDate: Boolean)
    var
        Name: Code[50];
    begin
        Name := 'Small_NonWarehouse';
        AssertTemporaryRecord(_TestData);

        _TestData.DeleteAll();
        _TestData.AddLineWithRef(Name, 0, 10000, _LocationCode, '', '', 'TF-002', '', 0D, '', Localization.UoM_PCS(), _CreateInventory, 100, 5);
        if _SetExpirationDate then
            _TestData.AddLineWithRef(Name, 0, 20000, _LocationCode, '', '', 'TF-003', '*', WorkDate(), '', Localization.UoM_PCS(), _CreateInventory, 100, 5)
        else
            _TestData.AddLineWithRef(Name, 0, 20000, _LocationCode, '', '', 'TF-003', '*', 0D, '', Localization.UoM_PCS(), _CreateInventory, 100, 5);
        _TestData.AddLineWithRef(Name, 0, 30000, _LocationCode, '', '', 'TF-004', '', 0D, '*', Localization.UoM_PCS(), _CreateInventory, 1, 1);
        _TestData.AddLineWithRef(Name, 0, 30000, _LocationCode, '', '', 'TF-004', '', 0D, '*', Localization.UoM_PCS(), _CreateInventory, 1, 1);
    end;

    local procedure CreateData_Small_NonWarehouse_BOX(var _TestData: Record "MOB Test Data" temporary; _LocationCode: Code[10]; _CreateInventory: Boolean; _SetExpirationDate: Boolean)
    var
        Name: Code[50];
    begin
        Name := 'Small_NonWarehouse';
        AssertTemporaryRecord(_TestData);

        _TestData.DeleteAll();
        _TestData.AddLineWithRef(Name, 0, 10000, _LocationCode, '', '', 'TF-002', '', 0D, '', Localization.UoM_BOX(), _CreateInventory, 10, 0.5);             // 1:10
        if _SetExpirationDate then
            _TestData.AddLineWithRef(Name, 0, 20000, _LocationCode, '', '', 'TF-003', '*', WorkDate(), '', Localization.UoM_BOX(), _CreateInventory, 10, 0.5) // 1:10
        else
            _TestData.AddLineWithRef(Name, 0, 20000, _LocationCode, '', '', 'TF-003', '*', 0D, '', Localization.UoM_BOX(), _CreateInventory, 10, 0.5);        // 1:10
        _TestData.AddLineWithRef(Name, 0, 30000, _LocationCode, '', '', 'TF-004', '', 0D, '*', Localization.UoM_PCS(), _CreateInventory, 1, 1);               // 1:1
        _TestData.AddLineWithRef(Name, 0, 30000, _LocationCode, '', '', 'TF-004', '', 0D, '*', Localization.UoM_PCS(), _CreateInventory, 1, 1);               // 1:1
    end;

    procedure CreateData_Small_Basic_Warehouse(var _TestData: Record "MOB Test Data" temporary; _LocationCode: Code[10]; _FromBin: Code[10]; _ToBin: Code[10]; _CreateInventory: Boolean; _SetExpirationDate: Boolean)
    begin
        CreateData_Small_Basic_Warehouse(_TestData, _LocationCode, _FromBin, _ToBin, '*', '*', '*', _CreateInventory, _SetExpirationDate);
    end;

    procedure CreateData_Small_Basic_Warehouse(var _TestData: Record "MOB Test Data" temporary; _LocationCode: Code[10]; _FromBin: Code[10]; _ToBin: Code[10]; _LotNo: Code[50]; _SerialNo1: Code[50]; _SerialNo2: Code[50]; _CreateInventory: Boolean; _SetExpirationDate: Boolean)
    var
        Name: Code[50];
    begin
        Name := 'Small_Basic_Warehouse';
        AssertTemporaryRecord(_TestData);

        _TestData.DeleteAll();
        _TestData.AddLineWithRef(Name, 0, 10000, _LocationCode, _FromBin, _ToBin, 'TF-002', '', 0D, '', Localization.UoM_PCS(), _CreateInventory, 100, 5);
        if _SetExpirationDate then
            _TestData.AddLineWithRef(Name, 0, 20000, _LocationCode, _FromBin, _ToBin, 'TF-003', _LotNo, WorkDate(), '', Localization.UoM_PCS(), _CreateInventory, 100, 5)
        else
            _TestData.AddLineWithRef(Name, 0, 20000, _LocationCode, _FromBin, _ToBin, 'TF-003', _LotNo, 0D, '', Localization.UoM_PCS(), _CreateInventory, 100, 5);
        _TestData.AddLineWithRef(Name, 0, 30000, _LocationCode, _FromBin, _ToBin, 'TF-004', '', 0D, _SerialNo1, Localization.UoM_PCS(), _CreateInventory, 1, 1);
        _TestData.AddLineWithRef(Name, 0, 30000, _LocationCode, _FromBin, _ToBin, 'TF-004', '', 0D, _SerialNo2, Localization.UoM_PCS(), _CreateInventory, 1, 1);
    end;

    procedure CreateData_Small_Warehouse(var _TestData: Record "MOB Test Data" temporary; _LocationCode: Code[10]; _FromBin: Code[10]; _ToBin: Code[10]; _CreateInventory: Boolean; _SetExpirationDate: Boolean)
    begin
        CreateData_Small_Warehouse(_TestData, _LocationCode, _FromBin, _ToBin, '*', '*', '*', _CreateInventory, _SetExpirationDate);
    end;

    procedure CreateData_Small_Warehouse(var _TestData: Record "MOB Test Data" temporary; _LocationCode: Code[10]; _FromBin: Code[10]; _ToBin: Code[10]; _LotNo: Code[50]; _SerialNo1: Code[50]; _SerialNo2: Code[50]; _CreateInventory: Boolean; _SetExpirationDate: Boolean)
    var
        Name: Code[50];
    begin
        Name := 'Small_Warehouse';
        AssertTemporaryRecord(_TestData);

        _TestData.DeleteAll();
        _TestData.AddLineWithRef(Name, 0, 10000, _LocationCode, _FromBin, _ToBin, 'TF-002', '', 0D, '', Localization.UoM_PCS(), _CreateInventory, 100, 5);
        if _SetExpirationDate then
            _TestData.AddLineWithRef(Name, 0, 20000, _LocationCode, _FromBin, _ToBin, 'TF-003', _LotNo, WorkDate(), '', Localization.UoM_PCS(), _CreateInventory, 100, 5)
        else
            _TestData.AddLineWithRef(Name, 0, 20000, _LocationCode, _FromBin, _ToBin, 'TF-003', _LotNo, 0D, '', Localization.UoM_PCS(), _CreateInventory, 100, 5);
        _TestData.AddLineWithRef(Name, 0, 30000, _LocationCode, _FromBin, _ToBin, 'TF-004', '', 0D, _SerialNo1, Localization.UoM_PCS(), _CreateInventory, 1, 1);
        _TestData.AddLineWithRef(Name, 0, 40000, _LocationCode, _FromBin, _ToBin, 'TF-004', '', 0D, _SerialNo2, Localization.UoM_PCS(), _CreateInventory, 1, 1);
    end;

    local procedure CreateData_Small_Warehouse_BOX(var _TestData: Record "MOB Test Data" temporary; _LocationCode: Code[10]; _FromBin: Code[10]; _ToBin: Code[10]; _CreateInventory: Boolean; _SetExpirationDate: Boolean)
    begin
        CreateData_Small_Warehouse_BOX(_TestData, _LocationCode, _FromBin, _ToBin, '*', '*', '*', _CreateInventory, _SetExpirationDate);
    end;

    local procedure CreateData_Small_Warehouse_BOX(var _TestData: Record "MOB Test Data" temporary; _LocationCode: Code[10]; _FromBin: Code[10]; _ToBin: Code[10]; _LotNo: Code[50]; _SerialNo1: Code[50]; _SerialNo2: Code[50]; _CreateInventory: Boolean; _SetExpirationDate: Boolean)
    var
        Name: Code[50];
    begin
        Name := 'Small_Warehouse';
        AssertTemporaryRecord(_TestData);

        _TestData.DeleteAll();
        _TestData.AddLineWithRef(Name, 0, 10000, _LocationCode, _FromBin, _ToBin, 'TF-002', '', 0D, '', Localization.UoM_BOX(), _CreateInventory, 10, 0.5);                   // 1:10
        if _SetExpirationDate then
            _TestData.AddLineWithRef(Name, 0, 20000, _LocationCode, _FromBin, _ToBin, 'TF-003', _LotNo, WorkDate(), '', Localization.UoM_BOX(), _CreateInventory, 10, 0.5)    // 1:10
        else
            _TestData.AddLineWithRef(Name, 0, 20000, _LocationCode, _FromBin, _ToBin, 'TF-003', _LotNo, 0D, '', Localization.UoM_BOX(), _CreateInventory, 10, 0.5);           // 1:10
        _TestData.AddLineWithRef(Name, 0, 30000, _LocationCode, _FromBin, _ToBin, 'TF-004', '', 0D, _SerialNo1, Localization.UoM_PCS(), _CreateInventory, 1, 1);              // 1:1
        _TestData.AddLineWithRef(Name, 0, 40000, _LocationCode, _FromBin, _ToBin, 'TF-004', '', 0D, _SerialNo2, Localization.UoM_PCS(), _CreateInventory, 1, 1);              // 1:1
    end;

    local procedure CreateData_Small_Warehouse_Without_SN(var _TestData: Record "MOB Test Data" temporary; _LocationCode: Code[10]; _FromBin: Code[10]; _ToBin: Code[10]; _LotNo: Code[50]; _CreateInventory: Boolean; _SetExpirationDate: Boolean)
    var
        Name: Code[50];
    begin
        Name := 'Small_Warehouse_Without_SN';
        AssertTemporaryRecord(_TestData);

        _TestData.DeleteAll();
        _TestData.AddLineWithRef(Name, 0, 10000, _LocationCode, _FromBin, _ToBin, 'TF-002', '', 0D, '', Localization.UoM_PCS(), _CreateInventory, 15, 15);
        if _SetExpirationDate then
            _TestData.AddLineWithRef(Name, 0, 20000, _LocationCode, _FromBin, _ToBin, 'TF-003', _LotNo, WorkDate(), '', Localization.UoM_PCS(), _CreateInventory, 10, 10)
        else
            _TestData.AddLineWithRef(Name, 0, 20000, _LocationCode, _FromBin, _ToBin, 'TF-003', _LotNo, 0D, '', Localization.UoM_PCS(), _CreateInventory, 10, 10);
    end;

    procedure CreateData_Small_PurchaseOrder(var _TestData: Record "MOB Test Data" temporary; _LocationCode: Code[10]; _FromBin: Code[10]; _ToBin: Code[10]; _CreateInventory: Boolean; _SetExpirationDate: Boolean)
    begin
        CreateData_Small_PurchaseOrder(_TestData, _LocationCode, _FromBin, _ToBin, '' /*SourceLineBin*/, _CreateInventory, _SetExpirationDate);
    end;

    procedure CreateData_Small_PurchaseOrder(var _TestData: Record "MOB Test Data" temporary; _LocationCode: Code[10]; _FromBin: Code[10]; _ToBin: Code[10]; _SourceLineBin: Code[10]; _CreateInventory: Boolean; _SetExpirationDate: Boolean)
    var
        Name: Code[50];
    begin
        Name := 'Small_PurchaseOrder';
        AssertTemporaryRecord(_TestData);

        _TestData.AddLineWithRef(Name, 0, 10000, _LocationCode, '', _FromBin, _ToBin, _SourceLineBin, 'TF-002', '', 0D, '', Localization.UoM_PCS(), _CreateInventory, 0, 15);
        if _SetExpirationDate then
            _TestData.AddLineWithRef(Name, 0, 20000, _LocationCode, '', _FromBin, _ToBin, _SourceLineBin, 'TF-003', '*', WorkDate(), '', Localization.UoM_PCS(), _CreateInventory, 0, 15)
        else
            _TestData.AddLineWithRef(Name, 0, 20000, _LocationCode, '', _FromBin, _ToBin, _SourceLineBin, 'TF-003', '*', 0D, '', Localization.UoM_PCS(), _CreateInventory, 0, 15);
        _TestData.AddLineWithRef(Name, 0, 30000, _LocationCode, '', _FromBin, _ToBin, _SourceLineBin, 'TF-004', '', 0D, '*', Localization.UoM_PCS(), _CreateInventory, 0, 1);
        _TestData.AddLineWithRef(Name, 0, 30000, _LocationCode, '', _FromBin, _ToBin, _SourceLineBin, 'TF-004', '', 0D, '*', Localization.UoM_PCS(), _CreateInventory, 0, 1);
        _TestData.AddLineWithRef(Name, 0, 30000, _LocationCode, '', _FromBin, _ToBin, _SourceLineBin, 'TF-004', '', 0D, '*', Localization.UoM_PCS(), _CreateInventory, 0, 1);
    end;

    local procedure CreateData_Small_PurchaseOrder_BOX(var _TestData: Record "MOB Test Data" temporary; _LocationCode: Code[10]; _FromBin: Code[10]; _ToBin: Code[10]; _SourceLineBin: Code[10]; _CreateInventory: Boolean; _SetExpirationDate: Boolean)
    var
        Name: Code[50];
    begin
        Name := 'Small_PurchaseOrder_BOX';

        AssertTemporaryRecord(_TestData);
        _TestData.AddLineWithRef(Name, 0, 10000, _LocationCode, '', _FromBin, _ToBin, _SourceLineBin, 'TF-002', '', 0D, '', Localization.UoM_BOX(), _CreateInventory, 0, 1.5);                // 1:10
        if _SetExpirationDate then
            _TestData.AddLineWithRef(Name, 0, 20000, _LocationCode, '', _FromBin, _ToBin, _SourceLineBin, 'TF-003', '*', WorkDate(), '', Localization.UoM_BOX(), _CreateInventory, 0, 1.5)    // 1:10
        else
            _TestData.AddLineWithRef(Name, 0, 20000, _LocationCode, '', _FromBin, _ToBin, _SourceLineBin, 'TF-003', '*', 0D, '', Localization.UoM_BOX(), _CreateInventory, 0, 1.5);           // 1:10
        _TestData.AddLineWithRef(Name, 0, 30000, _LocationCode, '', _FromBin, _ToBin, _SourceLineBin, 'TF-004', '', 0D, '*', Localization.UoM_PCS(), _CreateInventory, 0, 1);                 // 1:1
        _TestData.AddLineWithRef(Name, 0, 30000, _LocationCode, '', _FromBin, _ToBin, _SourceLineBin, 'TF-004', '', 0D, '*', Localization.UoM_PCS(), _CreateInventory, 0, 1);                 // 1:1
        _TestData.AddLineWithRef(Name, 0, 30000, _LocationCode, '', _FromBin, _ToBin, _SourceLineBin, 'TF-004', '', 0D, '*', Localization.UoM_PCS(), _CreateInventory, 0, 1);                 // 1:1
    end;

    local procedure AssertTemporaryRecord(var _TestData: Record "MOB Test Data" temporary)
    begin
        if (not _TestData.IsTemporary()) then
            Error(AssertTempRecNotTempErr);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetupBaseData()
    begin
    end;
}

