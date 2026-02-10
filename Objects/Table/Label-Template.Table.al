table 81364 "MOB Label-Template"
{
    Access = Public;
    Caption = 'Mobile Label-Template';
    DrillDownPageId = "MOB Label-Templates";
    LookupPageId = "MOB Label-Templates";

    fields
    {
        field(1; Name; Text[50])
        {
            Caption = 'Name';
            DataClassification = CustomerContent;
            NotBlank = true;

            trigger OnValidate()
            begin
                if "Display Name" = '' then
                    "Display Name" := Name;
            end;
        }
        field(11; "Display Name"; Text[50])
        {
            Caption = 'Display Name';
            DataClassification = CustomerContent;
            NotBlank = true;
        }
        field(20; "Template Handler"; Enum "MOB Label-Template Handler")
        {
            Caption = 'Template Handler';
            DataClassification = CustomerContent;
        }
        field(40; Enabled; Boolean)
        {
            Caption = 'Enabled';
            DataClassification = CustomerContent;
            InitValue = true;
        }
        field(80; "URL Mapping"; Text[250])
        {
            Caption = 'Template Path';
            DataClassification = CustomerContent;
        }
        field(90; "Number Series"; Code[20])
        {
            Caption = 'Number Series';
            DataClassification = CustomerContent;
            TableRelation = "No. Series".Code;
        }
    }
    keys
    {
        key(Key1; Name)
        {
        }
    }
    var
        DoNotRenameQst: Label 'Warning: Do NOT rename label-templates in use. Customizations may refer directly to this Name and will break if the record is renamed. Do you want to continue?';

    trigger OnDelete()
    var
        MobPrintSetup: Record "MOB Print Setup";
        MobPrinterLabelTemplate: Record "MOB Printer Label-Template";
    begin
        // Clean up assigned templates
        MobPrinterLabelTemplate.SetRange("Label-Template Name", Rec.Name);
        MobPrinterLabelTemplate.DeleteAll();

        // Clean up setup
        MobPrintSetup.Get();
        if MobPrintSetup."Print on Sales Order Pick" = Rec.Name then begin
            MobPrintSetup."Print on Sales Order Pick" := '';
            MobPrintSetup.Modify();
        end;
    end;

    trigger OnRename()
    begin
        if not Confirm(DoNotRenameQst) then exit;
    end;

}
