table 81363 "MOB Printer"
{
    Access = Public;
    Caption = 'Mobile Printer';
    DrillDownPageId = "MOB Printers";
    LookupPageId = "MOB Printers";

    fields
    {
        field(1; Name; Text[50])
        {
            Caption = 'Name';
            DataClassification = CustomerContent;
            NotBlank = true;
        }
        field(10; Enabled; Boolean)
        {
            Caption = 'Enabled';
            DataClassification = CustomerContent;
            InitValue = true;
            NotBlank = true;
        }
        field(20; Address; Text[250])
        {
            Caption = 'Address';
            DataClassification = CustomerContent;
            NotBlank = true;
        }
        field(30; "Location Code"; Code[10])
        {
            Caption = 'Location';
            DataClassification = CustomerContent;
            TableRelation = Location.Code;
        }
        field(80; DPI; Option)
        {
            Caption = 'DPI', Locked = true;
            DataClassification = CustomerContent;
            OptionMembers = ,,,,,"203",,,,,"300",,,,,"600";
            OptionCaption = ',,,,,203,,,,,300,,,,,600', Locked = true;
            InitValue = "203";
        }
    }
    keys
    {
        key(Key1; Name)
        {
        }
    }

    trigger OnDelete()
    var
        MobPrinterLabelTemplate: Record "MOB Printer Label-Template";
    begin
        // Clean assigned templates
        MobPrinterLabelTemplate.SetRange("Printer Name", Rec.Name);
        MobPrinterLabelTemplate.DeleteAll();
    end;
}
