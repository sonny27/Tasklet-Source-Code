page 81293 "MOB Report Print Setup"
{
    // Report Print not available for BC15-
    /* #if BC16+ */
    UsageCategory = Administration;
    ApplicationArea = All;
    /* #endif */

    Caption = 'Mobile Report Print Setup', Locked = true, Comment = 'Keep "Report Print" in English as a product name.';
    AdditionalSearchTerms = 'Mobile Report Print Setup Tasklet Configuration', Locked = true;
    PageType = Card;
    SourceTable = "MOB Report Print Setup";
    Editable = true;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(Group00)
            {
                Caption = 'General', Locked = true;
                grid(Grid01)
                {
                    GridLayout = Columns;
                    group(Group0101)
                    {
                        Caption = 'Essential Setup', Locked = true;
                        field("Language Code"; Rec."Language Code")
                        {
                            ToolTip = 'Reports will be printed from the mobile device in this language code when supported by the report, regardless of the Mobile User''s language. All Mobile WMS reports support this field but standard reports from Microsoft does not. Custom reports will need to implement support for the value of this field.', Locked = true;
                            ApplicationArea = All;
                        }
                    }
                    group(Group0102)
                    {
                        Caption = 'Information', Locked = true;
                        field(EnabledTemplates; EnabledReports)
                        {
                            Caption = 'Enabled reports', Locked = true;
                            Style = Unfavorable;
                            StyleExpr = EnabledReports = 0;
                            ToolTip = 'Number of enabled reports.', Locked = true;
                            Editable = false;
                            ApplicationArea = All;
                        }
                        field(EnabledPrinters; EnabledPrinters)
                        {
                            Caption = 'Enabled printers', Locked = true;
                            Style = Unfavorable;
                            StyleExpr = EnabledPrinters = 0;
                            ToolTip = 'Number of enabled printers.', Locked = true;
                            Editable = false;
                            ApplicationArea = All;
                        }
                    }
                }
            }
            group(Group02)
            {
                Caption = 'Print on mobile actions', Locked = true;
                field("Print Shipment on Post"; Rec."Print Shipment on Post")
                {
                    ToolTip = 'Print the configured report(s) from Report Selection when mobile user posts an outbound transaction (Warehouse Posted Shipment, Sales Shipment, Transfer Shipment or Purchase Return Shipment)', Locked = true;
                    ApplicationArea = All;
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(Templates)
            {
                Caption = 'Reports', Locked = true;
                ToolTip = 'Available Reports. Each report may require specific printers to print due to dimensions or other features.', Locked = true;
                ApplicationArea = All;
                Image = PrintInstallment;
                PromotedCategory = Process;
                Promoted = true;
                PromotedOnly = true;
                PromotedIsBig = true;
                trigger OnAction()
                begin
                    Page.RunModal(Page::"MOB Reports");

                    GetStats();
                end;
            }
            action(Printers)
            {
                Caption = 'Printers', Locked = true;
                ToolTip = 'Available Mobile Printers. Each printer may support only a subset of reports (designs) due to dimensions or other features.', Locked = true;
                ApplicationArea = All;
                Image = PrintDocument;
                PromotedCategory = Process;
                Promoted = true;
                PromotedOnly = true;
                PromotedIsBig = true;

                trigger OnAction()
                begin
                    Page.RunModal(Page::"MOB Report Printers");

                    GetStats();
                end;
            }
        }
    }
    var
        EnabledPrinters: Integer;
        EnabledReports: Integer;

    trigger OnOpenPage()
    var
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;

        GetStats();
    end;

    local procedure GetStats()
    begin
        EnabledPrinters := Rec.GetNoOfEnabledPrinters();
        EnabledReports := Rec.GetNoOfEnabledReports();
    end;
}
