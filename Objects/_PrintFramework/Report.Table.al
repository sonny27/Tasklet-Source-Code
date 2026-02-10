table 81297 "MOB Report"
{
    Access = Public;
    Caption = 'Mobile Report', Locked = true;
    DataClassification = CustomerContent;
    DrillDownPageId = "MOB Reports";
    LookupPageId = "MOB Reports";

    fields
    {
        field(1; "Display Name"; Text[50])
        {
            Caption = 'Display Name', Locked = true;
            NotBlank = true;
        }

        field(10; Enabled; Boolean)
        {
            Caption = 'Enabled', Locked = true;
            InitValue = true;
        }

        field(20; "Report ID"; Integer)
        {
            Caption = 'Report ID', Locked = true;
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Report));
            BlankZero = true;
            trigger OnValidate()
            begin
                Rec.CalcFields("Report Caption");
                if Rec."Display Name" = '' then
                    Rec."Display Name" := CopyStr(Rec."Report Caption", 1, MaxStrLen(Rec."Display Name"));

                /* #if BC20+ */
                Rec."Layout Name" := '';
                Clear("Layout Application ID");
                Rec."Layout Publisher" := '';
                /* #endif */

                /* #if BC19- ##
                Rec."Custom Layout Code" := '';
                Rec.CalcFields("Custom Layout Description");
                /* #endif */
            end;
        }

        field(30; "Report Caption"; Text[250])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Report),
                                                                           "Object ID" = field("Report ID")));
            Caption = 'Report Caption', Locked = true;
            Editable = false;
            FieldClass = FlowField;
        }

        field(40; "RequestPage Handler"; Enum "MOB RequestPage Handler")
        {
            Caption = 'RequestPage Handler', Locked = true;
        }

        /* #if BC20+ */
        field(50; "Layout Name"; Text[250])
        {
            Caption = 'Layout Name', Locked = true;
            TableRelation = "Report Layout List" where("Report ID" = field("Report ID"));
            ValidateTableRelation = false;

            trigger OnLookup()
            var
                ReportLayoutList: Record "Report Layout List";
            begin
                ReportLayoutList.Reset();
                ReportLayoutList.SetRange("Report ID", Rec."Report ID");
                if Page.RunModal(Page::"Report Layouts", ReportLayoutList) = Action::LookupOK then begin
                    Rec."Layout Name" := ReportLayoutList.Name;
                    Rec."Layout Application ID" := ReportLayoutList."Application ID";
                    Rec."Layout Publisher" := ReportLayoutList."Layout Publisher";
                end;
            end;

            trigger OnValidate()
            begin
                if Rec."Layout Name" <> '' then
                    Error(UseLayoutLookupErr, Rec.FieldCaption("Layout Name"), Rec.FieldCaption("Layout Application ID"));

                Clear(Rec."Layout Application ID");
                Rec."Layout Publisher" := '';
            end;
        }

        field(60; "Layout Application ID"; Guid)
        {
            Caption = 'Layout Application ID', Locked = true;
            Editable = false;
        }

        field(70; "Layout Publisher"; Text[250])
        {
            Caption = 'Layout Publisher', Locked = true;
            Editable = false;
        }
        /* #endif */

        /* #if BC19- ##
        field(80; "Custom Layout Code"; Code[20])
        {
            Caption = 'Custom Layout Code', Locked = true;
            TableRelation = "Custom Report Layout" where("Report ID" = field("Report Id"));

            trigger OnValidate()
            begin
                CalcFields("Custom Layout Description");
            end;
        }

        field(90; "Custom Layout Description"; Text[250])
        {
            Caption = 'Custom Layout Description', Locked = true;
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Custom Report Layout".Description where(Code = field("Custom Layout Code")));
        }
        /* #endif */

        field(100; "All Printers"; Boolean)
        {
            Caption = 'All Printers', Locked = true;
            FieldClass = FlowField;
            CalcFormula = - exist("MOB Report Printer Report" where("Report Display Name" = field("Display Name")));
            Editable = false;
        }
    }
    keys
    {
        key(Key1; "Display Name")
        {
            Clustered = true;
        }
        key(Key2; Enabled)
        {
        }
    }
    fieldgroups
    {
        fieldgroup(DropDown; "Display Name", "Report ID", "Report Caption", "All Printers")
        {
        }
    }

    trigger OnDelete()
    var
        MobReportPrinterReport: Record "MOB Report Printer Report";
    begin
        MobReportPrinterReport.SetRange("Report Display Name", Rec."Display Name");
        MobReportPrinterReport.DeleteAll();
    end;

    internal procedure LookupAssignPrinter()
    var
        MobReportPrinterReport: Record "MOB Report Printer Report";
    begin
        MobReportPrinterReport.SetCurrentKey("Report Display Name", "Printer Name");
        MobReportPrinterReport.SetRange("Report Display Name", Rec."Display Name");

        Page.RunModal(Page::"MOB Report Printer Reports", MobReportPrinterReport);
    end;

    internal procedure Print(_Parameters: Text; _PrinterName: Text[250])
    var
        MobReportPrintSetup: Record "MOB Report Print Setup";
        DesigntimeReportSelection: Codeunit "Design-time Report Selection";
        MobToolbox: Codeunit "MOB Toolbox";
        SavedLanguageID: Integer;
    begin
        // Override user language if applied in Report Print Setup and apply to GlobalLanguage        
        MobReportPrintSetup.Get();

        if not GuiAllowed() and (MobReportPrintSetup."Language Code" <> '') then begin
            SavedLanguageID := GlobalLanguage();
            GlobalLanguage(MobToolbox.GetLanguageId(MobReportPrintSetup."Language Code", true)); // true = Throw error if language ID is not set
        end;

        // Layouts are supported from BC20, but BC20 is a bit different than BC21+ as the "Report Layouts Definition" table was introduced in BC21
        /* #if BC21+ */
        if Rec."Layout Name" <> '' then begin
            DesigntimeReportSelection.SetSelectedLayout(Rec."Layout Name", Rec."Layout Application ID");
            Report.Print(Rec."Report ID", _Parameters, _PrinterName);
            DesigntimeReportSelection.ClearLayoutSelection();
        end else
            Report.Print(Rec."Report ID", _Parameters, _PrinterName);
        /* #endif */

        /* #if BC20 ##
        // BC20 does not support "Layout Application ID" and does not have a ClearLayoutSelection() function
        if Rec."Layout Name" <> '' then begin
            DesigntimeReportSelection.SetSelectedLayout(Rec."Layout Name");
            Report.Print(Rec."Report ID", _Parameters, _PrinterName);
            DesigntimeReportSelection.SetSelectedLayout('');
        end else
            Report.Print(Rec."Report ID", _Parameters, _PrinterName);
        /* #endif */

        /* #if BC19- ##
        // BC19- uses Custom Layouts instead of Report Layouts
        if Rec."Custom Layout Code" <> '' then begin
            DesigntimeReportSelection.SetSelectedCustomLayout(Rec."Custom Layout Code");
            Report.Print(Rec."Report ID", _Parameters, _PrinterName);
            DesigntimeReportSelection.SetSelectedCustomLayout('');
        end else
            Report.Print(Rec."Report ID", _Parameters, _PrinterName);
        /* #endif */

        // Reset Global language
        if SavedLanguageID <> 0 then
            GlobalLanguage(SavedLanguageID);
    end;

    internal procedure GetLayout(): Text[250]
    begin
        /* #if BC20+ */
        exit(Rec."Layout Name");
        /* #endif */

        /* #if BC19- ##
        exit(Rec."Custom Layout Code");
        /* #endif */
    end;

    var
        UseLayoutLookupErr: Label 'Please Lookup the %1 to also populate the %2 of the selected layout.', Locked = true, Comment = '%1 = Layout Name, %2 = Layout Application ID';
}
