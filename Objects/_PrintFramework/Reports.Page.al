page 81296 "MOB Reports"
{
    Caption = 'Mobile Reports', Locked = true;
    PageType = List;
    SourceTable = "MOB Report";
    DelayedInsert = true; // Enables selecting the report id before assigning a name setting the name from the report

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(Enabled; Rec.Enabled)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies if the report is enabled. Disabling prevents the report from being shown to mobile users.', Locked = true;
                }
                field("Display Name"; Rec."Display Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Here you can assign a descriptive name to the report which is shown to mobile users.', Locked = true;
                }
                field("Report ID"; Rec."Report ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Select the report-id that should be available for mobile users.', Locked = true;
                    trigger OnValidate()
                    begin
                        UpdatePrinterAvailability();
                    end;
                }
                field("Report Caption"; Rec."Report Caption")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the caption of the report.', Locked = true;
                }
                field("RequestPage Handler"; Rec."RequestPage Handler")
                {
                    ApplicationArea = All;
                    ToolTip = 'A requestpage handler makes it possible to reuse existing logic, step-collection and data mapping.', Locked = true;
                }
                /* #if BC20+ */
                field("Layout Name"; Rec."Layout Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'A report can have multiple report layouts. If no layout is specified, the default layout will be used.', Locked = true;
                }
                field("Layout Application ID"; Rec."Layout Application ID")
                {
                    ApplicationArea = All;
                    Visible = false;
                    ToolTip = 'This specifies the application id of the report layout, as a layout name is not always unique across applications.', Locked = true;
                }
                field("Layout Publisher"; Rec."Layout Publisher")
                {
                    ApplicationArea = All;
                    ToolTip = 'This specifies the publisher of the application with the report layout, as a layout name is not always unique across applications.', Locked = true;
                }
                /* #endif */

                /* #if BC19- ##
                field("Custom Layout Code"; Rec."Custom Layout Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'A report can have multiple custom layouts. If no layout is specified, the default layout will be used.', Locked = true;
                }
                field("Custom Layout Description"; Rec."Custom Layout Description")
                {
                    ApplicationArea = All;
                    ToolTip = 'This specifies the description of the custom layout.', Locked = true;
                }
                /* #endif */

                field(AvailableToPrinters; AvailableToPrinters)
                {
                    ApplicationArea = All;
                    Editable = false;
                    Style = AttentionAccent;
                    Caption = 'Available To', Locked = true;
                    ToolTip = 'A report is by default available to all printers, alternatively only to it''s assigned printers.', Locked = true;
                    AssistEdit = true;
                    trigger OnAssistEdit()
                    begin
                        Rec.LookupAssignPrinter();
                    end;
                }
            }
        }
    }
    actions
    {
        area(Navigation)
        {
            action(InsertMobWmsReports)
            {
                ApplicationArea = All;
                Caption = 'Insert all Mobile WMS Reports', Locked = true;
                ToolTip = 'Insert all Mobile WMS Reports with their associated requestpage handler.', Locked = true;
                Image = ServiceSetup;
                Promoted = true;
                PromotedIsBig = true;
                PromotedOnly = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    MobReportPrintSetup: Record "MOB Report Print Setup";
                begin
                    MobReportPrintSetup.InsertAllMobileWmsReports();
                end;
            }

            action(Printers)
            {
                Caption = 'Printers', Locked = true;
                ToolTip = 'Set up printers available for the report. All printers will be available if none are set up for the report.', Locked = true;
                ApplicationArea = All;
                Image = Print;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                RunObject = page "MOB Report Printer Reports";
                RunPageLink = "Report Display Name" = field("Display Name");
            }
        }
    }

    trigger OnOpenPage()
    begin
        /* #if BC15- ##
        Error('This Mobile WMS feature is only available in BC 16 and later');
        /* #endif */
    end;

    trigger OnAfterGetRecord()
    begin
        UpdatePrinterAvailability();
    end;

    local procedure UpdatePrinterAvailability()
    var
        MobReportPrinterReport: Record "MOB Report Printer Report";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        ReportCount: Integer;
    begin
        MobReportPrinterReport.SetRange("Report Display Name", Rec."Display Name");
        ReportCount := MobReportPrinterReport.Count();
        if ReportCount > 0 then
            AvailableToPrinters := Format(ReportCount) + ' ' + MobWmsLanguage.GetMessage('PRINTER(S)')
        else
            AvailableToPrinters := MobWmsLanguage.GetMessage('FILTER_ALL') + ' ' + MobWmsLanguage.GetMessage('PRINTERS');
    end;

    var
        AvailableToPrinters: Text;
}
