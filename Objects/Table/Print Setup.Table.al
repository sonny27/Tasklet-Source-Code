table 81362 "MOB Print Setup"
{
    Access = Public;
    // Print service setup

    Caption = 'Mobile Cloud Print Setup', Comment = 'Keep "Cloud Print" in English as a product name.';
    LookupPageId = "MOB Print Setup";


    fields
    {
#pragma warning disable LC0013 // Ignore since this is a setup table
        field(1; "Primary Key"; Code[10])
#pragma warning restore LC0013
        {
            DataClassification = CustomerContent;
            Caption = 'Primary Key', Locked = true;
            Editable = false;
        }
        field(11; Enabled; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Printing is enabled';

            trigger OnValidate()
            var
                MobFeatureTelemetryWrapper: Codeunit "MOB Feature Telemetry Wrapper";
            begin
                MobFeatureTelemetryWrapper.LogUptakeSetupOfMobilePrintFeature(Rec);
            end;
        }
        field(15; "Language Code"; Code[10])
        {
            DataClassification = CustomerContent;
            Caption = 'Language';
            TableRelation = "MOB Language".Code;
        }
        field(25; "Connection URL"; Text[250])
        {
            DataClassification = CustomerContent;
            Caption = 'Connection URL';
        }
        field(28; "Preview URL"; Text[250])
        {
            DataClassification = CustomerContent;
            Caption = 'Preview URL', Locked = true;
            ObsoleteState = Removed;
            ObsoleteReason = 'Not used in Mobile WMS';
            ObsoleteTag = 'MOB5.35';
        }
        field(29; "Connection Tenant"; Text[50])
        {
            DataClassification = CustomerContent;
            Caption = 'Connection Tenant';
        }
        field(30; "Connection Username"; Text[80])
        {
            DataClassification = CustomerContent;
            Caption = 'Connection Username';
        }
        field(32; "Connection Password"; Text[80])
        {
            DataClassification = CustomerContent;
            Caption = 'Connection Password';
            ExtendedDatatype = Masked;
        }
        field(51; "Print on Sales Order Pick"; Text[50])
        {
            DataClassification = CustomerContent;
            Caption = 'Print on Sales Order Pick';
            TableRelation = "MOB Label-Template".Name where("Template Handler" = const("Sales Shipment"));
        }
        field(55; "Print on Whse. Shipment Post"; Text[50])
        {
            DataClassification = CustomerContent;
            Caption = 'Print on Warehouse Shipment Post';
            TableRelation = "MOB Label-Template".Name where("Template Handler" = const("Warehouse Shipment"));
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {

        }
    }

    procedure GetNoOfEnabledPrinters(): Integer
    var
        Printer: Record "MOB Printer";
    begin
        Printer.SetRange(Enabled, true);
        exit(Printer.Count());
    end;

    procedure GetNoOfEnabledLabelTemplates(): Integer
    var
        LabelTemplate: Record "MOB Label-Template";
    begin
        LabelTemplate.SetRange(Enabled, true);
        exit(LabelTemplate.Count());
    end;

    procedure GetNoOfEnabledPrinterLabelTemplates(): Integer
    var
        PrinterLabelTemplate: Record "MOB Printer Label-Template";
    begin
        exit(PrinterLabelTemplate.Count());
    end;

}
