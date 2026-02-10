table 81298 "MOB Report Printer Report"
{
    Access = Public;
    Caption = 'Mobile Report Printer Report', Locked = true;
    DataClassification = CustomerContent;
    DrillDownPageId = "MOB Report Printer Reports";
    LookupPageId = "MOB Report Printer Reports";

    fields
    {
        field(1; "Printer Name"; Text[250])
        {
            Caption = 'Printer Name', Locked = true;
            TableRelation = "MOB Report Printer";
            NotBlank = true;
        }
        field(2; "Report Display Name"; Text[50])
        {
            Caption = 'Report Display Name', Locked = true;
            TableRelation = "MOB Report";
            NotBlank = true;
        }
        field(10; "Location Filter"; Code[250])
        {
            CalcFormula = lookup("MOB Report Printer"."Location Filter" where("Printer Name" = field("Printer Name")));
            Caption = 'Location Filter', Locked = true;
            Editable = false;
            FieldClass = FlowField;
        }
        field(20; "Packing Station Filter"; Code[250])
        {
            CalcFormula = lookup("MOB Report Printer"."Packing Station Filter" where("Printer Name" = field("Printer Name")));
            Caption = 'Packing Station Filter', Locked = true;
            Editable = false;
            FieldClass = FlowField;
        }
    }
    keys
    {
        key(Key1; "Printer Name", "Report Display Name")
        {
            Clustered = true;
        }
        key(Key2; "Report Display Name", "Printer Name")
        {
        }
    }
}
