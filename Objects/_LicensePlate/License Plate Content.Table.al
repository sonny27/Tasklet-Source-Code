table 82218 "MOB License Plate Content"
{
    Access = Public;
    Caption = 'Mobile License Plate Content';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "License Plate No."; Code[20])
        {
            Caption = 'License Plate No.';
            DataClassification = CustomerContent;
            TableRelation = "MOB License Plate";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
            DataClassification = CustomerContent;
        }
        field(15; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            DataClassification = CustomerContent;
            TableRelation = Location;
            Editable = false;
        }
        field(16; "Bin Code"; Code[20])
        {
            Caption = 'Bin Code';
            DataClassification = CustomerContent;
            TableRelation = Bin.Code where("Location Code" = field("Location Code"));
            Editable = false;
        }
        field(20; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Item,License Plate';
            OptionMembers = Item,"License Plate";
            DataClassification = CustomerContent;
        }
        field(21; "No."; Code[20])
        {
            Caption = 'No.';
            DataClassification = CustomerContent;
            TableRelation =
            if (Type = const(Item)) Item
            else
            if (Type = const("License Plate")) "MOB License Plate";
        }
        field(22; "Serial No."; Code[50])
        {
            Caption = 'Serial No.';
            DataClassification = CustomerContent;
        }
        field(23; "Lot No."; Code[50])
        {
            Caption = 'Lot No.';
            DataClassification = CustomerContent;
        }
        field(24; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DataClassification = CustomerContent;
            trigger OnValidate()
            var
                UOMMgt: Codeunit "Unit of Measure Management";
            begin
                "Quantity (Base)" :=
                    UOMMgt.CalcBaseQty(Quantity, "Qty. per Unit of Measure");
            end;
        }
        field(25; "Unit Of Measure Code"; Code[10])
        {
            Caption = 'Unit Of Measure Code';
            DataClassification = CustomerContent;

            TableRelation = if (Type = const(Item),
                                "No." = filter(<> '')) "Item Unit of Measure".Code where("Item No." = field("No."))
            else
            "Unit of Measure";

            trigger OnValidate()
            var
                UOMMgt: Codeunit "Unit of Measure Management";
            begin
                case Type of
                    Type::Item:
                        begin
                            GetItem();
                            "Qty. per Unit of Measure" := UOMMgt.GetQtyPerUnitOfMeasure(Item, "Unit Of Measure Code");
                            Validate(Quantity);
                        end;
                end;
            end;
        }
        field(26; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            DataClassification = CustomerContent;
        }
        field(27; "Quantity (Base)"; Decimal)
        {
            Caption = 'Quantity (Base)';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                TestField("Qty. per Unit of Measure", 1);
                Validate(Quantity, "Quantity (Base)");
            end;
        }
        field(28; "Qty. per Unit of Measure"; Decimal)
        {
            Caption = 'Qty. per Unit of Measure';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            Editable = false;
            InitValue = 1;
        }
        field(30; "Whse. Document Type"; Option)
        {
            Caption = 'Whse. Document Type';
            DataClassification = CustomerContent;
            Editable = false;
            OptionCaption = ' ,Receipt,Shipment,Internal Put-away,Internal Pick,Production,Movement Worksheet,,Assembly';
            OptionMembers = " ",Receipt,Shipment,"Internal Put-away","Internal Pick",Production,"Movement Worksheet",,Assembly;
        }
        field(31; "Whse. Document No."; Code[20])
        {
            Caption = 'Whse. Document No.';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(32; "Whse. Document Line No."; Integer)
        {
            BlankZero = true;
            Caption = 'Whse. Document Line No.';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(40; "Source Type"; Integer)
        {
            Caption = 'Source Type';
            Editable = false;
            DataClassification = CustomerContent;
        }
        field(41; "Source No."; Code[20])
        {
            Caption = 'Source No.';
            Editable = false;
            DataClassification = CustomerContent;
        }
        field(42; "Source Line No."; Integer)
        {
            Caption = 'Source Line No.';
            Editable = false;
            DataClassification = CustomerContent;
        }
        field(43; "Source Document"; Option)
        {
            Caption = 'Source Document';
            Editable = false;
            OptionCaption = ' ,Sales Order,,,Sales Return Order,Purchase Order,,,Purchase Return Order,Inbound Transfer,Outbound Transfer,Prod. Consumption,Prod. Output,,,,,,Service Order,,Assembly Consumption,Assembly Order';
            OptionMembers = " ","Sales Order",,,"Sales Return Order","Purchase Order",,,"Purchase Return Order","Inbound Transfer","Outbound Transfer","Prod. Consumption","Prod. Output",,,,,,"Service Order",,"Assembly Consumption","Assembly Order";
            DataClassification = CustomerContent;
        }
        // BC 14, 15 and 16 not supported. Enum and event not available. 
        /* #if BC17+ */
        field(44; "Posted Source Document"; Enum "Warehouse Shipment Posted Source Document")
        {
            Caption = 'Posted Source Document';
            Editable = false;
        }
        field(45; "Posted Source No."; Code[20])
        {
            Caption = 'Posted Source No.';
            Editable = false;
        }
        field(46; "Posted Source Line No."; Integer)
        {
            Caption = 'Posted Source Line No.';
            Editable = false;
        }
        /* #endif */
        field(50; "Package No."; Code[50])  // Unused in BC17- but retained for fewer changes to the code base
        {
            Caption = 'Package No.', Locked = true;
            CaptionClass = '6,1';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(Key1; "License Plate No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "License Plate No.", Type)
        {
            SumIndexFields = Quantity, "Quantity (Base)";
        }
        key(Key3; "Whse. Document Type", "Whse. Document No.", Type, "No.", "Lot No.", "Serial No.", "Variant Code")
        {

        }
        key(Key4; Type, "No.")
        {
            MaintainSqlIndex = true;
        }

    }

    local procedure GetItem()
    begin
        TestField("No.");
        if "No." <> Item."No." then
            Item.Get("No.");
    end;

    internal procedure CopyTrackingToMobTrackingSetup(var _MobTrackingSetup: Record "MOB Tracking Setup")
    begin
        _MobTrackingSetup."Serial No." := "Serial No.";
        _MobTrackingSetup."Lot No." := "Lot No.";
        _MobTrackingSetup."Package No." := "Package No.";
    end;

    internal procedure CopyTrackingToReservEntry(var _ReservEntry: Record "Reservation Entry")
    begin
        _ReservEntry."Serial No." := "Serial No.";
        _ReservEntry."Lot No." := "Lot No.";
        /* #if BC18+ */
        _ReservEntry."Package No." := "Package No.";    // Field only exists in BC18 and newer
        /* #endif */
    end;

    internal procedure SetTracking(_MobTrackingSetup: Record "MOB Tracking Setup")
    begin
        Validate("Serial No.", _MobTrackingSetup."Serial No.");
        Validate("Lot No.", _MobTrackingSetup."Lot No.");
        Validate("Package No.", _MobTrackingSetup."Package No.");
    end;

    internal procedure SetTrackingFilterFromLicensePlateContent(var _MobLicensePlateContent: Record "MOB License Plate Content")
    begin
        SetRange("Serial No.", _MobLicensePlateContent."Serial No.");
        SetRange("Lot No.", _MobLicensePlateContent."Lot No.");
        SetRange("Package No.", _MobLicensePlateContent."Package No.");
    end;

    internal procedure SetTrackingFilterFromRegistration(var _MobWmsRegistration: Record "MOB WMS Registration")
    begin
        SetRange("Serial No.", _MobWmsRegistration.SerialNumber);
        SetRange("Lot No.", _MobWmsRegistration.LotNumber);
        SetRange("Package No.", _MobWmsRegistration.PackageNumber);
    end;

    internal procedure SetValuesFromLicensePlate(_LicensePlateNo: Code[20])
    var
        MobLicensePlate: Record "MOB License Plate";
    begin
        if MobLicensePlate.Get(_LicensePlateNo) then begin
            Validate("License Plate No.", MobLicensePlate."No.");
            Validate("Location Code", MobLicensePlate."Location Code");
            Validate("Bin Code", MobLicensePlate."Bin Code");
            Validate("Whse. Document Type", MobLicensePlate."Whse. Document Type");
            Validate("Whse. Document No.", MobLicensePlate."Whse. Document No.");
        end;
    end;

    var
        Item: Record Item;
}
