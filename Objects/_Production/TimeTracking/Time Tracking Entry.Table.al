table 81405 "MOB Time Tracking Entry"
{
    Access = Public;

    Caption = 'Mobile Time Tracking Entry';

    fields
    {
        field(1; "Entry No."; Integer)
        {
            AutoIncrement = true;
            Caption = 'Entry No.';
            DataClassification = CustomerContent;
        }
        field(10; "Registering Date"; Date)
        {
            Caption = 'Registering Date';
            DataClassification = CustomerContent;
        }
        field(20; "Mobile User ID"; Code[50])
        {
            Caption = 'Mobile User ID';
            DataClassification = CustomerContent;
            TableRelation = "MOB User";
        }
        field(21; "Device ID"; Code[200])
        {
            Caption = 'Device ID';
            DataClassification = CustomerContent;
        }
        field(30; "Time Tracking Entry Type"; Enum "MOB Time Tracking Entry Type")
        {
            Caption = 'Entry Type';
            DataClassification = CustomerContent;
        }
        field(31; "Time Tracking Status"; Enum "MOB Time Tracking Status")
        {
            Caption = 'Status';
            DataClassification = CustomerContent;
        }

        field(40; "Start DateTime"; DateTime)
        {
            Caption = 'Start DateTime';
            DataClassification = CustomerContent;
        }
        field(41; "Stop DateTime"; DateTime)
        {
            Caption = 'Stop DateTime';
            DataClassification = CustomerContent;
        }
        field(45; "Start Date"; Date)
        {
            Caption = 'Start Date';
            DataClassification = CustomerContent;
        }
        field(46; "Start Time"; Time)
        {
            Caption = 'Start Time';
            DataClassification = CustomerContent;
        }
        field(47; "Stop Date"; Date)
        {
            Caption = 'Stop Date';
            DataClassification = CustomerContent;
        }
        field(48; "Stop Time"; Time)
        {
            Caption = 'Stop Time';
            DataClassification = CustomerContent;
        }
        field(50; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
        }
        field(51; "Capacity Unit of Measure Code"; Code[10])
        {
            Caption = 'Capacity Unit of Measure Code';
            DataClassification = CustomerContent;
            TableRelation = "Capacity Unit of Measure";
        }
        field(60; Open; Boolean)
        {
            Caption = 'Open';
            DataClassification = CustomerContent;
        }
        field(61; "Applies-to Entry No."; Integer)
        {
            AccessByPermission = tabledata "MOB Time Tracking Entry" = R;
            Caption = 'Applies-to Entry No.';
            DataClassification = CustomerContent;
        }
        // Enum in BC17 and newer
        /* #if BC17+ */
        field(70; "Prod. Order Status"; Enum "Production Order Status")
        {
            Caption = 'Status';
            DataClassification = CustomerContent;
        }
        /* #endif */
        // Option in BC14, BC15 and BC16
        /* #if BC14,BC15,BC16 ##
        field(70; "Prod. Order Status"; Option)
        {
            Caption = 'Status';
            OptionCaption = 'Simulated,Planned,Firm Planned,Released,Finished';
            OptionMembers = Simulated,Planned,"Firm Planned",Released,Finished;
            DataClassification = CustomerContent;
        }
        /* #endif */
        field(71; "Prod. Order No."; Code[20])
        {
            Caption = 'Prod. Order No.';
            DataClassification = CustomerContent;
            TableRelation = "Production Order"."No." where(Status = field("Prod. Order Status"));
        }
        field(72; "Routing No."; Code[20])
        {
            Caption = 'Routing No.';
            DataClassification = CustomerContent;
            TableRelation = "Routing Header";
        }
        field(73; "Routing Reference No."; Integer)
        {
            Caption = 'Routing Reference No.';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(74; "Operation No."; Code[10])
        {
            Caption = 'Operation No.';
            DataClassification = CustomerContent;
        }
        field(80; "Source RecordId"; RecordId)
        {
            Caption = 'Source RecordId';
            DataClassification = CustomerContent;
        }

    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Source RecordId", "Mobile User ID", "Device ID", "Time Tracking Entry Type", "Time Tracking Status", Open)
        {
        }
    }

    fieldgroups
    {
    }

}
