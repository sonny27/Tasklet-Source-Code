table 81296 "MOB Report Printer"
{
    Access = Public;
    Caption = 'Mobile Report Printer', Locked = true;
    DataClassification = CustomerContent;
    DrillDownPageId = "MOB Report Printers";
    LookupPageId = "MOB Report Printers";

    fields
    {
        field(1; "Printer Name"; Text[250])
        {
            Caption = 'Printer Name', Locked = true;
            TableRelation = Printer;
            NotBlank = true;
            trigger OnValidate()
            begin
                // Printer Names are sent as a ';' seperated list, so names must not contain it
                if Rec."Printer Name".Contains(';') then
                    Error(FieldMustNotContainValueErr, Rec.FieldCaption("Printer Name"), ';');
            end;
        }
        field(10; Enabled; Boolean)
        {
            Caption = 'Enabled', Locked = true;
            InitValue = true;
        }
        field(20; "Location Filter"; Code[250])
        {
            Caption = 'Location Filter', Locked = true;
            TableRelation = Location;
            ValidateTableRelation = false;
            trigger OnValidate()
            var
                Location: Record Location;
            begin
                if Rec."Location Filter" <> '' then begin
                    Location.SetFilter(Code, Rec."Location Filter"); // Validates the filter
                    Rec."Location Filter" := Location.GetFilter(Code); // Formats the filter
                end
            end;
        }
        field(30; "Packing Station Filter"; Code[250])
        {
            Caption = 'Packing Station Filter', Locked = true;
            TableRelation = "MOB Packing Station";
            ValidateTableRelation = false;
            trigger OnValidate()
            var
                MobPackingStation: Record "MOB Packing Station";
            begin
                if Rec."Packing Station Filter" <> '' then begin
                    MobPackingStation.SetFilter(Code, Rec."Packing Station Filter"); // Validates the filter
                    Rec."Packing Station Filter" := MobPackingStation.GetFilter(Code); // Formats the filter
                end
            end;
        }
    }
    keys
    {
        key(Key1; "Printer Name")
        {
            Clustered = true;
        }
        key(Key2; Enabled)
        {
        }
    }
    fieldgroups
    {
        fieldgroup(DropDown; "Printer Name", Enabled, "Location Filter")
        { }
    }

    trigger OnDelete()
    var
        MobReportPrinterReport: Record "MOB Report Printer Report";
    begin
        MobReportPrinterReport.SetRange("Printer Name", Rec."Printer Name");
        MobReportPrinterReport.DeleteAll();
    end;

    var
        FieldMustNotContainValueErr: Label '%1 must not contain %2', Locked = true, Comment = '%1 = Field Caption, ie. "Printer Name". %2 = Illegal char(s), ie. ";"';
}
