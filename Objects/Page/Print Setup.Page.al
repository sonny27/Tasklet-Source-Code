page 81362 "MOB Print Setup"
{
    Caption = 'Mobile Cloud Print Setup', Comment = 'Keep "Cloud Print" in English as a product name.';
    AdditionalSearchTerms = 'Mobile Cloud Print Setup Tasklet Configuration', Locked = true;
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "MOB Print Setup";
    Editable = true;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(Group00)
            {
                Caption = 'General';
                grid(Grid01)
                {
                    GridLayout = Columns;
                    group(Group0101)
                    {
                        Caption = 'Essential Setup';

                        field(Enabled; Rec.Enabled)
                        {
                            ToolTip = 'Enable or disable printing.';
                            ApplicationArea = All;
                        }
                        field("Language Code"; Rec."Language Code")
                        {
                            ToolTip = 'Labels will be printed in this language code, when supported. All labels are in this language, regardless of the Mobile User''s language. The setting affects both "Mobile Messages" used and the "GlobalLanguage"-context of AL code. By installing "Langauge Pack"-extensions your AL code can leverage all available  BC languages.';
                            ApplicationArea = All;
                        }

                    }
                    group(Group0201)
                    {
                        Caption = 'Connection to print service';
                        field("Connection URL"; Rec."Connection URL")
                        {
                            ToolTip = 'URL to print service.';
                            ApplicationArea = All;
                        }
                        field("Connection Tenant"; Rec."Connection Tenant")
                        {
                            ToolTip = 'Tenant name for print service.';
                            ApplicationArea = All;
                        }
                        field(Username; Rec."Connection Username")
                        {
                            ToolTip = 'Username to print service.';
                            ApplicationArea = All;
                        }
                        field(Password; Rec."Connection Password")
                        {
                            ToolTip = 'Password to print service.';
                            ApplicationArea = All;
                        }
                    }
                }
            }
            group(Group03)
            {
                Caption = 'Print on mobile actions';
                grid(Grid03)
                {
                    Caption = 'Automatically issue print when mobile users performs certain actions';
                    GridLayout = Columns;
                    group(Group0301)
                    {
                        Caption = 'Actions';
                        field("Print on Sales Order Pick"; Rec."Print on Sales Order Pick")
                        {
                            Caption = 'Print on Sales Order Pick';
                            ToolTip = 'Template to print when mobile user posts picked item, directly on sales orders.';
                            ApplicationArea = All;
                        }
                        field("Print on Warehouse Shipment Post"; Rec."Print on Whse. Shipment Post")
                        {
                            Caption = 'Print on Warehouse Shipment Post';
                            ToolTip = 'Template to print when mobile user posts warehouse shipment.';
                            ApplicationArea = All;
                        }
                    }
                    group(Group0302)
                    {
                        ShowCaption = false;
                    }
                }
            }
            group(Group02)
            {
                Caption = 'Information';
                grid(Grid02)
                {
                    GridLayout = Columns;
                    group(Group0103)
                    {
                        Caption = 'Statistics';

                        field(EnabledTemplates; "Enabled Templates")
                        {
                            Caption = 'Enabled templates';
                            Style = Unfavorable;
                            StyleExpr = "Enabled Templates" = 0;
                            ToolTip = 'Number of enabled templates.';
                            Editable = false;
                            ApplicationArea = All;
                        }
                        field(EnabledPrinters; "Enabled Printers")
                        {
                            Caption = 'Enabled printers';
                            Style = Unfavorable;
                            StyleExpr = "Enabled Printers" = 0;
                            ToolTip = 'Number of enabled printers.';
                            Editable = false;
                            ApplicationArea = All;
                        }

                    }
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(PerformStandardSetup)
            {
                ApplicationArea = All;
                Caption = 'Create Standard Setup';
                ToolTip = 'Create Standard Setup including Templates (designs).';
                Image = ServiceSetup;
                Promoted = true;
                PromotedIsBig = true;
                PromotedCategory = Process;

                trigger OnAction()
                begin
                    GetStats();
                    MobPrint.CreateStandardSetup(Rec, true);
                    GetStats();
                    CurrPage.Update(false);
                end;
            }
            action(Printers)
            {
                Caption = 'Printers';
                ToolTip = 'Available Mobile Printers (label printers). Each printer may support only a subset of Label Templates (designs) due to label dimensions or other features.';
                ApplicationArea = All;
                Image = PrintDocument;
                PromotedCategory = Process;
                Promoted = true;
                PromotedOnly = true;
                PromotedIsBig = true;

                trigger OnAction()
                begin
                    Page.RunModal(Page::"MOB Printers");
                    GetStats();
                    CurrPage.Update(false);
                end;
            }
            action(Templates)
            {
                Caption = 'Templates';
                ToolTip = 'Available Label Templates (designs). Each Template may require a specific printers to print due to label dimensions or other features.';
                ApplicationArea = All;
                Image = PrintInstallment;
                PromotedCategory = Process;
                Promoted = true;
                PromotedOnly = true;
                PromotedIsBig = true;

                trigger OnAction()
                begin
                    Page.RunModal(Page::"MOB Label-Templates");
                    GetStats();
                    CurrPage.Update(false);
                end;
            }
            action(TestConnection)
            {
                Caption = 'Test Connection';
                ToolTip = 'Test your access credentials are working.';
                ApplicationArea = All;
                Image = Setup;
                PromotedCategory = Process;
                Promoted = true;
                PromotedOnly = true;
                PromotedIsBig = true;

                trigger OnAction()
                var
                    MobPrintInterForm: Codeunit "MOB Print InterForm";
                begin
                    Rec.TestField("Connection Tenant");
                    MobPrintInterForm.TestConnection();
                    CurrPage.Update(false);
                end;
            }
        }
    }

    var
        MobPrint: Codeunit "MOB Print";
        "Http Request Allowed": Boolean;
        "Enabled Printers": Integer;
        "Enabled Templates": Integer;

    trigger OnOpenPage()
    var
        MobFeatureTelemetryWrapper: Codeunit "MOB Feature Telemetry Wrapper";
        MobTelemetryEventId: Enum "MOB Telemetry Event ID";
    begin
        MobFeatureTelemetryWrapper.LogUptakeDiscovered(MobTelemetryEventId::"Mobile Print Feature (MOB1020)");

        GetStats();
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;

        "Http Request Allowed" := MobPrint.SetHTTPRequestAllow();
        GetStats();
    end;

    local procedure GetStats()
    begin
        "Enabled Printers" := Rec.GetNoOfEnabledPrinters();
        "Enabled Templates" := Rec.GetNoOfEnabledLabelTemplates();
    end;
}
