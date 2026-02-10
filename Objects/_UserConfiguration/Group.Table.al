table 81275 "MOB Group"
{
    Access = Public;
    Caption = 'Mobile Group';
    DataCaptionFields = "Code", Name;
    LookupPageId = "MOB Groups";
    DrillDownPageId = "MOB Groups";
    Permissions = 
        tabledata "MOB Group User" = rd,
        tabledata "MOB Group Menu Config" = rd;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
            DataClassification = CustomerContent;
        }
        field(2; Name; Text[50])
        {
            Caption = 'Name';
            DataClassification = CustomerContent;
        }
        field(3; "User Count"; Integer)
        {
            Caption = 'User Count';
            FieldClass = FlowField;
            CalcFormula = count("MOB Group User" where("Group Code" = field(Code)));
            Editable = false;
        }
        field(4; "Menu Item Count"; Integer)
        {
            Caption = 'Menu Item Count';
            FieldClass = FlowField;
            CalcFormula = count("MOB Group Menu Config" where("Mobile Group" = field(Code)));
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Code")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Code", Name)
        {
        }
    }

    trigger OnDelete()
    var
        MobGroupUser: Record "MOB Group User";
        MobGroupMenuItems: Record "MOB Group Menu Config";
    begin
        MobGroupUser.SetRange("Group Code", Code);
        MobGroupUser.DeleteAll(true);

        MobGroupMenuItems.SetRange("Mobile Group", Code);
        MobGroupMenuItems.DeleteAll(true);
    end;
}
