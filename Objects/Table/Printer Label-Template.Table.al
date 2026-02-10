table 81365 "MOB Printer Label-Template"
{
    Access = Public;
    // The combination of printers and the Label-templates assiged to them.

    Caption = 'Mobile Printer Label-Template';
    DrillDownPageId = "MOB Printer Label-Templates";
    LookupPageId = "MOB Printer Label-Templates";

    fields
    {
        field(1; "Printer Name"; Text[50])
        {
            Caption = 'Printer Name';
            DataClassification = CustomerContent;
            TableRelation = "MOB Printer".Name;
            NotBlank = true;
        }
        field(3; "Label-Template Name"; Text[50])
        {
            Caption = 'Label-Template Name';
            DataClassification = CustomerContent;
            TableRelation = "MOB Label-Template".Name;
            NotBlank = true;
        }

        // Pack & Ship 
        field(10; "Packing Station Code"; Code[20])
        {
            Caption = 'Packing Station Code';
            DataClassification = CustomerContent;
            TableRelation = "MOB Packing Station";
        }
    }
    keys
    {
        key(Key1; "Printer Name", "Label-Template Name")
        {
        }
    }

}
