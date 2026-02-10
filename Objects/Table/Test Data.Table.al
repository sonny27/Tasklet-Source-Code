table 81386 "MOB Test Data"
{
    Access = Public;
    Caption = 'MOB Test Data', Locked = true;

    fields
    {
        field(90; "Action Type"; Option)
        {
            Caption = 'Action Type', Locked = true;
            DataClassification = SystemMetadata;
            OptionMembers = TAKE,PLACE;
        }
        field(100; "Code"; Code[50])
        {
            Caption = 'Code', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(130; "Line No."; Integer)
        {
            Caption = 'Line No.', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(140; "Ref. Line No."; Integer)
        {
            Caption = 'Ref. Line No.', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(180; "Location Code"; Code[10])
        {
            Caption = 'Location Code', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(190; "New Location Code"; Code[10])
        {
            Caption = 'New Location Code', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(200; "Item No."; Code[20])
        {
            Caption = 'Item No.', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(210; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(220; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(250; "Create Inventory"; Boolean)
        {
            Caption = 'Create Inventory', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(260; "Qty. To Create"; Decimal)
        {
            Caption = 'Qty. To Create', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(265; "Qty. To Handle"; Decimal)
        {
            Caption = 'Qty. To Handle', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(270; "Serial No."; Code[50])
        {
            Caption = 'Serial No.', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(280; "Lot No."; Code[50])
        {
            Caption = 'Lot No.', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(290; "Expiration Date"; Date)
        {
            Caption = 'Expiration Date', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(300; "Bin Code"; Code[20])
        {
            Caption = 'Bin Code', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(305; "To Bin Code"; Code[20])
        {
            Caption = 'To Bin Code', Locked = true;
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Use to populate PurchaseLine."Bin Code" during TestHelper.CreatePurchaseOrders().
        /// Needed only when creating Invt.PutAways and when item has no default BinContent record.
        /// </summary>
        /// <remarks>
        /// When creating Invt.PutAway the item must have a default Bin (from BinContent or PurchaseLine),
        /// otherwise no Invt.PutAway is created ("Nothing to create").
        /// All TF-* items created from TestHelper will have a default BinContent (copied from item LS-75 setup).
        /// </remarks>
        field(307; "Source Line Bin Code"; Code[20])
        {
            Caption = 'Source Line Bin Code', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(310; "Zone Code"; Code[10])
        {
            Caption = 'Zone Code', Locked = true;
            DataClassification = SystemMetadata;
        }

        field(320; xQty; Decimal)
        {
            Caption = 'xQty', Locked = true;
            DataClassification = SystemMetadata;
        }

        field(330; xQtyBase; Decimal)
        {
            Caption = 'xQtyBase', Locked = true;
            DataClassification = SystemMetadata;
        }

        field(340; xInvQtyBase; Decimal)
        {
            Caption = 'xInvQtyBase', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(400; "Source Document"; Option)
        {
            Caption = 'Source Document', Locked = true;
            DataClassification = SystemMetadata;
            OptionMembers = " ","Sales Order",,,"Sales Return Order","Purchase Order",,,"Purchase Return Order","Inbound Transfer","Outbound Transfer","Prod. Consumption","Prod. Output",,,,,,"Service Order",,"Assembly Consumption","Assembly Order";
        }
        field(500; "Tote ID"; Code[100])
        {
            Caption = 'Tote ID', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(510; "ExtraInfo NodeName"; Text[50])
        {
            Caption = 'ExtraInfo NodeName', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(520; "ExtraInfo NodeValue"; Text[250])
        {
            Caption = 'ExtraInfo NodeValue', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(530; "Image Name"; Text[250])
        {
            Caption = 'Image Name', Locked = true;
            DataClassification = SystemMetadata;
        }
    }
    keys
    {
        key(Key1; "Code", "Line No.")
        {
        }
        key(Key2; "Code", "Ref. Line No.", "Line No.")
        {
        }
    }
    var

    trigger OnInsert()
    begin
        CreateInventory();
        InitXValues();
    end;

    trigger OnModify()
    begin
        CreateInventory();
        InitXValues();
    end;

    trigger OnDelete()
    begin

    end;

    trigger OnRename()
    begin

    end;

    local procedure InitXValues()
    begin
        xQty := Qty();
        xQtyBase := QtyBase();
        xInvQtyBase := InvQtyBase();
    end;

    procedure InitializeAsCopyOf(var _TestData: Record "MOB Test Data" temporary; _NewLocationCode: Code[10]; _NewBin: Code[20])
    begin
        // Initializes this record as a copy of existing data
        _TestData.Reset();
        if _TestData.FindSet(false) then
            repeat
                Rec.Copy(_TestData, false);

                if _NewLocationCode <> '' then
                    Rec."Location Code" := _NewLocationCode;

                if _NewBin <> '' then
                    Rec."Bin Code" := _NewBin;

                InitXValues();
                Rec.Insert(false);

            until _TestData.Next() = 0;
    end;

    local procedure NewLineNo(var _TestData: Record "MOB Test Data" temporary)
    var
        TempTestData2: Record "MOB Test Data" temporary;

    begin
        // Increment with 10000 on new Line No.
        TempTestData2.Copy(_TestData, true);
        if "Line No." <> 0 then
            exit;

        if not TempTestData2.FindLast() then; // To increment line no. from the last record. If no record exists the empty record line no. equals zero.
        "Line No." := TempTestData2."Line No." + 10000;
    end;

    // 12 arguments
    procedure AddLine(_TestDataCode: Code[50]; _Location: Code[10]; _Bin: Code[20]; _ToBin: Code[20]; _ItemNo: Code[20]; _LotNo: Code[50]; _ExpDate: Date; _SerialNo: Code[50]; _UoM: Code[10]; _CreateInventory: Boolean; _QtyToCreate: Decimal; _QtyToHandle: Decimal)
    begin
        Rec.Init();
        Clear("Line No.");
        NewLineNo(Rec);

        AddLineWithRef(
            _TestDataCode,
            Rec."Line No.",
            Rec."Line No.",
            _Location,
            '', // NewLocation
            _Bin,
            _ToBin,
            '', // SourceLineBin
            _ItemNo,
            _LotNo,
            _ExpDate,
            _SerialNo,
            _UoM,
            _CreateInventory,
            _QtyToCreate,
            _QtyToHandle,
            '', // ToteID
            '', // ImageName
            '', // ExtraInfoNodeName
            ''  // ExtraInfoValue
            );
    end;

    // 13 arguments
    procedure AddLine(_TestDataCode: Code[50]; _Location: Code[10]; _NewLocation: Code[10]; _Bin: Code[20]; _ToBin: Code[20]; _ItemNo: Code[20]; _LotNo: Code[50]; _ExpDate: Date; _SerialNo: Code[50]; _UoM: Code[10]; _CreateInventory: Boolean; _QtyToCreate: Decimal; _QtyToHandle: Decimal)
    begin
        Rec.Init();
        Clear("Line No.");
        NewLineNo(Rec);

        AddLineWithRef(
            _TestDataCode,
            Rec."Line No.",
            Rec."Line No.",
            _Location,
            _NewLocation,
            _Bin,
            _ToBin,
            '', // SourceLineBin
            _ItemNo,
            _LotNo,
            _ExpDate,
            _SerialNo,
            _UoM,
            _CreateInventory,
            _QtyToCreate,
            _QtyToHandle,
            '', // ToteID,
            '', // ImageName,
            '', // ExtraInfoNodeName
            ''  // ExtraInfoValue
            );
    end;

    // 7 arguments
    procedure AddLine(_Location: Code[10]; _ItemNo: Code[20]; _UoM: Code[10]; _CreateInventory: Boolean; _QtyToCreate: Decimal; _QtyToHandle: Decimal; _ImageName: Text[250])
    begin
        Rec.Init();
        Clear("Line No.");
        NewLineNo(Rec);

        AddLineWithRef(
            '', // TestDataCode
            Rec."Line No.",
            Rec."Line No.",
            _Location,
            '', // NewLocation
            '', // Bin
            '', // ToBin
            '', // SourceLineBin
            _ItemNo,
            '', // LotNo
            0D, // ExpDate
            '', // SerialNo
            _UoM,
            _CreateInventory,
            _QtyToCreate,
            _QtyToHandle,
            '', // ToteID
            _ImageName,
            '', // ExtraInfoNodeName
            ''  // ExtraInfoValue
            );
    end;

    // 14 arguments
    procedure AddLineWithRef(_TestDataCode: Code[50]; _LineNo: Integer; _RefLineNo: Integer; _Location: Code[10]; _Bin: Code[20]; _ToBin: Code[20]; _ItemNo: Code[20]; _LotNo: Code[50]; ExpDate: Date; _SerialNo: Code[50]; _UoM: Code[10]; _CreateInventory: Boolean; _QtyToCreate: Decimal; _QtyToHandle: Decimal)
    begin
        AddLineWithRef(_TestDataCode, _LineNo, _RefLineNo, _Location, '' /*NewLocation*/, _Bin, _ToBin, '' /*SourceLineBin*/, _ItemNo, _LotNo, ExpDate, _SerialNo, _UoM, _CreateInventory, _QtyToCreate, _QtyToHandle, '' /*ToteID*/, '' /*ImageName*/, '' /*ExtraInfoNodeName*/, '' /*ExtraInfoValue*/);
    end;

    // 15 arguments
    procedure AddLineWithRef(_TestDataCode: Code[50]; _LineNo: Integer; _RefLineNo: Integer; _Location: Code[10]; _NewLocation: Code[10]; _Bin: Code[20]; _ToBin: Code[20]; _ItemNo: Code[20]; _LotNo: Code[50]; ExpDate: Date; _SerialNo: Code[50]; _UoM: Code[10]; _CreateInventory: Boolean; _QtyToCreate: Decimal; _QtyToHandle: Decimal)
    begin
        AddLineWithRef(_TestDataCode, _LineNo, _RefLineNo, _Location, _NewLocation, _Bin, _ToBin, '' /*SourceLineBin*/, _ItemNo, _LotNo, ExpDate, _SerialNo, _UoM, _CreateInventory, _QtyToCreate, _QtyToHandle, '' /*ToteID*/, '' /*ImageName*/, '' /*ExtraInfoNodeName*/, '' /*ExtraInfoValue*/);
    end;

    // 15 arguments incl. ToteID
    procedure AddLineWithRefTotePickShip(_TestDataCode: Code[50]; _LineNo: Integer; _RefLineNo: Integer; _Location: Code[10]; _Bin: Code[20]; _ToBin: Code[20]; _ItemNo: Code[20]; _LotNo: Code[50]; ExpDate: Date; _SerialNo: Code[50]; _UoM: Code[10]; _CreateInventory: Boolean; _QtyToCreate: Decimal; _QtyToHandle: Decimal; _ToteID: Code[100])
    begin
        AddLineWithRef(_TestDataCode, _LineNo, _RefLineNo, _Location, '' /*NewLocation*/, _Bin, _ToBin, '' /*SourceLineBin*/, _ItemNo, _LotNo, ExpDate, _SerialNo, _UoM, _CreateInventory, _QtyToCreate, _QtyToHandle, _ToteID, '' /*ImageName*/, '' /*ExtraInfoNodeName*/, '' /*ExtraInfoValue*/);
    end;

    // 16 arguments incl. NewLocation and SourceLineBinCode
    procedure AddLineWithRef(_TestDataCode: Code[50]; _LineNo: Integer; _RefLineNo: Integer; _Location: Code[10]; _NewLocation: Code[10]; _Bin: Code[20]; _ToBin: Code[20]; _SourceLineBin: Code[20]; _ItemNo: Code[20]; _LotNo: Code[50]; ExpDate: Date; _SerialNo: Code[50]; _UoM: Code[10]; _CreateInventory: Boolean; _QtyToCreate: Decimal; _QtyToHandle: Decimal)
    begin
        AddLineWithRef(_TestDataCode, _LineNo, _RefLineNo, _Location, _NewLocation, _Bin, _ToBin, _SourceLineBin, _ItemNo, _LotNo, ExpDate, _SerialNo, _UoM, _CreateInventory, _QtyToCreate, _QtyToHandle, '' /*ToteID*/, '' /*ImageName*/, '' /*ExtraInfoNodeName*/, '' /*ExtraInfoValue*/);
    end;

    // 18 arguments
    procedure AddLineWithRef(_TestDataCode: Code[50]; _LineNo: Integer; _RefLineNo: Integer; _Location: Code[10]; _Bin: Code[20]; _ToBin: Code[20]; _ItemNo: Code[20]; _LotNo: Code[50]; ExpDate: Date; _SerialNo: Code[50]; _UoM: Code[10]; _CreateInventory: Boolean; _QtyToCreate: Decimal; _QtyToHandle: Decimal; _ToteID: Code[100]; _ImageName: Text[250]; _ExtraInfoNodeName: Text[50]; _ExtraInfoNodeValue: Text[250])
    begin
        AddLineWithRef(_TestDataCode, _LineNo, _RefLineNo, _Location, '' /*NewLocation*/, _Bin, _ToBin, '' /*SourceLineBin*/, _ItemNo, _LotNo, ExpDate, _SerialNo, _UoM, _CreateInventory, _QtyToCreate, _QtyToHandle, _ToteID, _ImageName, _ExtraInfoNodeName, _ExtraInfoNodeValue);
    end;

    local procedure AddLineWithRef(_TestDataCode: Code[50]; _LineNo: Integer; _RefLineNo: Integer; _Location: Code[10]; _NewLocation: Code[10]; _Bin: Code[20]; _ToBin: Code[20]; _SourceLineBin: Code[20]; _ItemNo: Code[20]; _LotNo: Code[50]; ExpDate: Date; _SerialNo: Code[50]; _UoM: Code[10]; _CreateInventory: Boolean; _QtyToCreate: Decimal; _QtyToHandle: Decimal; _ToteID: Code[100]; _ImageName: Text[250]; _ExtraInfoNodeName: Text[50]; _ExtraInfoNodeValue: Text[250])
    begin
        // Add new line to Test Data
        Rec.Init();
        "Code" := _TestDataCode;
        if _LineNo = 0 then begin
            Clear("Line No.");
            NewLineNo(Rec);
        end else
            "Line No." := _LineNo;
        "Ref. Line No." := _RefLineNo;
        "Expiration Date" := ExpDate;
        "Location Code" := _Location;
        if _NewLocation <> '' then
            "New Location Code" := _NewLocation
        else
            "New Location Code" := _Location;
        "Bin Code" := _Bin;
        "To Bin Code" := _ToBin;
        "Source Line Bin Code" := _SourceLineBin;
        "Item No." := _ItemNo;
        "Create Inventory" := _CreateInventory;
        "Qty. To Create" := _QtyToCreate;
        "Qty. To Handle" := _QtyToHandle;
        if _LotNo = '*' then
            "Lot No." := CopyStr(Format("Line No.") + '-L' + CreateGuid(), 1, 50)
        else
            "Lot No." := _LotNo;

        if _SerialNo = '*' then
            "Serial No." := CopyStr(Format("Line No.") + '-S' + CreateGuid(), 1, 50)
        else
            "Serial No." := _SerialNo;

        "Unit of Measure Code" := _UoM;
        "Tote ID" := _ToteID;
        "Image Name" := _ImageName;
        "ExtraInfo NodeName" := _ExtraInfoNodeName;
        "ExtraInfo NodeValue" := _ExtraInfoNodeValue;
        Insert(true);
    end;

    local procedure CreateInventory()
    var
        TestHelper: Codeunit "MOB Test Helper";
    begin
        if "Create Inventory" then
            // ''= Variant currently not supported
             TestHelper.CreateInventory("Location Code", "Bin Code", "Item No.", '', "Lot No.", "Serial No.", "Qty. To Create", "Unit of Measure Code");
    end;

    procedure TrackingExists() _IsTrackingExist: Boolean
    begin
        // Same conditions as ItemJnlLine.TrackingExists
        _IsTrackingExist := ("Lot No." <> '') or ("Serial No." <> '');
    end;

    procedure QtyBase(): Decimal
    var
        TestHelper: Codeunit "MOB Test Helper";
    begin
        exit(
        TestHelper.CalcWhseQtyBase("Location Code", "Bin Code", "Item No.", "Variant Code", "Lot No.", "Serial No.")
        );
    end;

    procedure Qty(): Decimal
    var
        TestHelper: Codeunit "MOB Test Helper";
    begin
        exit(
        TestHelper.CalcWhseQty("Location Code", "Bin Code", "Item No.", "Variant Code", "Lot No.", "Serial No.", "Unit of Measure Code")
        );
    end;

    procedure WhseQtyAllBins(): Decimal
    var
        TestHelper: Codeunit "MOB Test Helper";
    begin
        exit(
        TestHelper.CalcWhseQty("Location Code", '', "Item No.", "Variant Code", "Lot No.", "Serial No.", "Unit of Measure Code")
        );
    end;

    procedure WhseQtyAllBinsBase(): Decimal
    var
        TestHelper: Codeunit "MOB Test Helper";
    begin
        exit(
        TestHelper.CalcWhseQtyBase("Location Code", '', "Item No.", "Variant Code", "Lot No.", "Serial No.")
        );
    end;

    procedure InvQtyBase(): Decimal
    var
        TestHelper: Codeunit "MOB Test Helper";
    begin
        exit(
        TestHelper.CalcInvQtyBase("Location Code", "Item No.", "Variant Code", "Lot No.", "Serial No.")
        );
    end;

    procedure DeltaQtyBase(): Decimal
    begin
        exit(QtyBase() - xQtyBase);
    end;

    procedure DeltaQty(): Decimal
    begin
        exit(Qty() - xQty);
    end;

    procedure DeltaInvQty(): Decimal
    begin
        exit(InvQtyBase() - xInvQtyBase);
    end;

    procedure QtyBaseErrorMsg(): Text[1024]
    var
        MobToolbox: Codeunit "MOB Toolbox";
    begin
        exit(
            MobToolbox.Format2Text1024(
                StrSubstNo('QtyOnHand (Base) do not match expected quantity ' +
                           '(LineNo: %1, LocationCode: %2, Bin: %3, ItemNo: %4, VariantCode: %5, LotNo: %6, SerialNo: %7)',
                    "Line No.",
                    "Location Code",
                    "Bin Code",
                    "Item No.",
                    "Variant Code",
                    "Lot No.",
                    "Serial No."))
            );
    end;

    procedure QtyErrorMsg(): Text[1024]
    var
        MobToolbox: Codeunit "MOB Toolbox";
    begin
        exit(
            MobToolbox.Format2Text1024(
                StrSubstNo('QtyOnHand do not match expected quantity ' +
                           '(LineNo: %1, LocationCode: %2, Bin: %3, ItemNo: %4, VariantCode: %5, UoM: %6, LotNo: %7, SerialNo: %8)',
                    "Line No.",
                    "Location Code",
                    "Bin Code",
                    "Item No.",
                    "Variant Code",
                    "Unit of Measure Code",
                    "Lot No.",
                    "Serial No."))
            );
    end;

    procedure ImbalanceBetweenInventoryAndWhseDetectedErrorMsg(): Text[1024]
    var
        MobToolbox: Codeunit "MOB Toolbox";
    begin
        exit(
            MobToolbox.Format2Text1024(
                StrSubstNo('Imbalance between Inventory and Warehouse Detected ' +
                            '(Location Code: %1, Item No.: %2, Variant Code: %3, UoM: %4, Lot No.: %5, Serial No.: %6)',
                "Location Code",
                "Item No.",
                "Variant Code",
                "Unit of Measure Code",
                "Lot No.",
                "Serial No."))
            );
    end;

    procedure InvQtyErrorMsg(): Text[1024]
    begin
        exit(QtyBaseErrorMsg());       // same message as QtyBase ie. with no UoM
    end;

}
