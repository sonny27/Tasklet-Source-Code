table 82220 "MOB Temp LP Report Content"
{
    Access = Public;
    Caption = 'Mobile Temp License Plate Report Content', Locked = true;
    DataClassification = CustomerContent;
    /* #if BC20+ */
    TableType = Temporary;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.', Locked = true;
            DataClassification = CustomerContent;
        }
        field(11; "License Plate No."; Code[20])
        {
            Caption = 'License Plate No.', Locked = true;
            DataClassification = CustomerContent;
        }
        field(13; Description; Text[250])
        {
            Caption = 'Description', Locked = true;
            DataClassification = CustomerContent;
        }
        field(15; Type; Option)
        {
            Caption = 'Type', Locked = true;
            OptionCaption = 'Item,License Plate';
            OptionMembers = Item,"License Plate";
            DataClassification = CustomerContent;
        }
        field(16; "No."; Code[20])
        {
            Caption = 'No.', Locked = true;
            DataClassification = CustomerContent;
        }
        field(20; "Serial No."; Code[50])
        {
            Caption = 'Serial No.', Locked = true;
            DataClassification = CustomerContent;
        }
        field(21; "Lot No."; Code[50])
        {
            Caption = 'Lot No.', Locked = true;
            DataClassification = CustomerContent;
        }
        field(22; "Package No."; Code[50])
        {
            Caption = 'Package No.', Locked = true;
            DataClassification = CustomerContent;
        }
        field(23; "Expiration Date"; Date)
        {
            Caption = 'Expiration Date', Locked = true;
            DataClassification = CustomerContent;
        }
        field(24; Quantity; Decimal)
        {
            Caption = 'Quantity', Locked = true;
            DataClassification = CustomerContent;
            BlankZero = true;
        }
        field(25; "Unit Of Measure Code"; Code[10])
        {
            Caption = 'Unit Of Measure Code', Locked = true;
            DataClassification = CustomerContent;
        }
        field(26; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code', Locked = true;
            DataClassification = CustomerContent;
        }
        field(27; "Quantity (Base)"; Decimal)
        {
            Caption = 'Quantity (Base)', Locked = true;
            DataClassification = CustomerContent;
        }
    }
    /* #endif */
    /* #if BC19- ##
    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = CustomerContent;
        }
    }
    /* #endif */
    keys
    {
        key(Key1; "Entry No.")
        {
        }
    }
}
