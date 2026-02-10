table 81291 "MOB PrintNode Printer Settings"
{
    Access = Internal;
    Caption = 'Tasklet PrintNode Printer Settings', Locked = true;
    LookupPageId = "MOB PrintNode Select Printer";
    DrillDownPageId = "MOB PrintNode Select Printer";

    fields
    {
        field(1; Name; Text[250])
        {
            Caption = 'Name', Locked = true;
            NotBlank = true;
            DataClassification = CustomerContent;
        }
        field(10; "PrintNode Printer ID"; Text[250])
        {
            Caption = 'PrintNode Printer ID', Locked = true;
            Editable = false;
            NotBlank = true;
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                TempMobPrintNodeLookupCapability: Record "MOB PrintNode LookupCapability" temporary;
                MobPrintNodeMgt: Codeunit "MOB PrintNode Mgt.";
            begin
                // Clear inherited values
                Rec."Paper Size" := '';
                Rec."Page Height" := 0;
                Rec."Page Width" := 0;
                Rec."Paper Tray" := '';

                if Rec."PrintNode Printer ID" <> '' then begin

                    // Populating the temporary "MOB PrintNode Ptr. Capability" table to set init values (= if only one exists)
                    TempMobPrintNodeLookupCapability.SetRange("PrintNode Printer ID Filter", Rec."PrintNode Printer ID");
                    MobPrintNodeMgt.LoadCapabilities(TempMobPrintNodeLookupCapability);

                    // Check if only a single Paper Size exists
                    TempMobPrintNodeLookupCapability.SetRange(Type, TempMobPrintNodeLookupCapability.Type::PaperSize);
                    if TempMobPrintNodeLookupCapability.FindSet() then
                        if TempMobPrintNodeLookupCapability.Next() = 0 then begin
                            Rec."Paper Size" := TempMobPrintNodeLookupCapability.Value;
                            Rec."Page Height" := TempMobPrintNodeLookupCapability."Paper Size Height";
                            Rec."Page Width" := TempMobPrintNodeLookupCapability."Paper Size Width";
                        end;

                    // Check if only a single Paper Tray exists
                    TempMobPrintNodeLookupCapability.SetRange(Type, TempMobPrintNodeLookupCapability.Type::PaperTray);
                    if TempMobPrintNodeLookupCapability.FindSet() then
                        if TempMobPrintNodeLookupCapability.Next() = 0 then
                            Rec."Paper Tray" := TempMobPrintNodeLookupCapability.Value;
                end;
            end;
        }
        field(12; "PrintNode Client Name"; Text[250])
        {
            Editable = false;
            Caption = 'PrintNode Client Name', Locked = true;
            DataClassification = CustomerContent;
        }
        field(20; Description; Text[100])
        {
            Caption = 'Description', Locked = true;
            DataClassification = CustomerContent;
        }

        /// <summary>
        /// The media (paper) size of the printer.
        /// </summary>
        field(100; "Paper Size"; Text[250])
        {
            Caption = 'Paper Size', Locked = true;
            DataClassification = CustomerContent;
            TableRelation = "MOB PrintNode LookupCapability".Value where("PrintNode Printer ID Filter" = field("PrintNode Printer ID"),
                                                                  Type = const(PaperSize));
            ValidateTableRelation = false;

            trigger OnValidate()
            var
                TempMobPrintNodeLookupCapability: Record "MOB PrintNode LookupCapability" temporary;
                MobPrintNodeMgt: Codeunit "MOB PrintNode Mgt.";
            begin
                if Rec."Paper Size" <> '' then begin

                    // Populating the temporary "MOB PrintNode Ptr. Capability" table to get additional field values
                    TempMobPrintNodeLookupCapability.SetRange("PrintNode Printer ID Filter", Rec."PrintNode Printer ID");
                    MobPrintNodeMgt.LoadCapabilities(TempMobPrintNodeLookupCapability);
                    if not TempMobPrintNodeLookupCapability.Get(TempMobPrintNodeLookupCapability.Type::PaperSize, Rec."Paper Size") then
                        Error(InvalidPaperSizeErr, Rec."Paper Size");

                    Rec."Page Height" := TempMobPrintNodeLookupCapability."Paper Size Height";
                    Rec."Page Width" := TempMobPrintNodeLookupCapability."Paper Size Width";
                end else begin
                    // Initializing height and width when flushing the Paper Size field
                    Rec."Page Height" := 0;
                    Rec."Page Width" := 0;
                end;
            end;
        }

        /// <summary>
        /// The height of the paper. Used to generate a PDF in the correct size.
        /// </summary>
        field(110; "Page Height"; Decimal)
        {
            Caption = 'Page Height (cm)', Locked = true;
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 2;
            BlankZero = true;
        }

        /// <summary>
        /// The width of the paper. Used to generate a PDF in the correct size.
        /// </summary>
        field(120; "Page Width"; Decimal)
        {
            Caption = 'Page Width (cm)', Locked = true;
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 2;
            BlankZero = true;
        }

        /// <summary>
        /// The value indicating the rotation parameter to PrintNode.
        /// Note: Not all printer drivers support all values.
        /// </summary>
        field(130; "Paper Rotation"; Option)
        {
            Caption = 'Paper Rotation', Locked = true;
            OptionMembers = Automatic,"0 Degrees","90 Degrees","180 Degrees","270 Degrees";
            OptionCaption = 'Automatic,0°,90°,180°,270°', Locked = true;
            DataClassification = CustomerContent;
        }

        /// <summary>
        /// The output paper tray to use when printing the document.
        /// </summary>
        field(140; "Paper Tray"; Text[250])
        {
            Caption = 'Paper Tray', Locked = true;
            DataClassification = CustomerContent;
            TableRelation = "MOB PrintNode LookupCapability".Value where("PrintNode Printer ID Filter" = field("PrintNode Printer ID"),
                                                                  Type = const(PaperTray));
            ValidateTableRelation = false;
        }
    }
    keys
    {
        key(PK; Name)
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    var
        MobPrintNodePrinterSettings: Record "MOB PrintNode Printer Settings";
    begin
        // Ensure records always got a Printer ID. The page uses DelayedInsert, so this can be ensured without having the field in the PK.
        TestField("PrintNode Printer ID");

        // Add Telemetry for adding the first single printer from the PrintNode Printer Settings page (page uses DelayedInsert)
        if MobPrintNodePrinterSettings.IsEmpty() then
            MobFeatureTelemetryWrapper.LogUptakeSetup(MobTelemetryEventId::"Tasklet PrintNode Feature (MOB1030)");
    end;

    trigger OnRename()
    var
        PrinterSelection: Record "Printer Selection";
        MobReportPrinter: Record "MOB Report Printer";
        MobReportPrinterRenamed: Record "MOB Report Printer";
    begin
        // Rename Printer Selection using this printer
        PrinterSelection.SetRange("Printer Name", xRec.Name);
        if PrinterSelection.FindSet(true) then
            repeat
                PrinterSelection."Printer Name" := Rec.Name;
                PrinterSelection.Modify(true);
            until PrinterSelection.Next() = 0;

        // Rename Mobile Printers
        MobReportPrinter.SetRange("Printer Name", xRec.Name);
        if MobReportPrinter.FindSet(true) then
            repeat
                MobReportPrinterRenamed := MobReportPrinter;
                MobReportPrinterRenamed.Rename(Rec.Name); // Renames automatically "MOB Report Printer Report" records
            until MobReportPrinter.Next() = 0;
    end;

    trigger OnDelete()
    var
        PrinterSelection: Record "Printer Selection";
    begin
        // Error if printer is in use
        PrinterSelection.SetRange("Printer Name", Rec.Name);
        if not PrinterSelection.IsEmpty() then
            Error(UsedInPrinterSelectionErr, Rec.Name);
    end;

    var
        MobFeatureTelemetryWrapper: Codeunit "MOB Feature Telemetry Wrapper";
        MobTelemetryEventId: Enum "MOB Telemetry Event ID";
        UsedInPrinterSelectionErr: Label 'You cannot delete printer %1. It is used on the Printer Selections page.', Comment = '%1 = Printer ID', Locked = true;
        InvalidPaperSizeErr: Label 'PrintNode does not support paper size %1 for this printer.', Comment = '%1 is a paper size, for example A4 or Letter', Locked = true;
}
