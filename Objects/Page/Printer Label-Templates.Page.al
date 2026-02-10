page 81365 "MOB Printer Label-Templates"
{
    PageType = List;
    Description = 'The combination of printers and the Label-templates assiged to them.';
    Caption = 'Printer/Label-Templates Assignments';
    UsageCategory = None;
    SourceTable = "MOB Printer Label-Template";
    DataCaptionFields = "Printer Name", "Label-Template Name";
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Relations)
            {
                field("Label-Template"; Rec."Label-Template Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Select the label-template.';
                    Visible = ShowLabelTemplate;
                }
                field(Printer; Rec."Printer Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Select the printer.';
                    Visible = ShowPrinter;
                }

                // Pack & Ship
                field("Packing Station Code"; Rec."Packing Station Code")
                {
                    ApplicationArea = MOBWMSPackandShip;
                    Visible = PackAndShipEnabled;
                    Enabled = PackAndShipEnabled;
                    ToolTip = 'Packing Station Code will be used as filter for default printer suggestion for Cloud Print labels.';
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(AssignAll)
            {
                ApplicationArea = All;
                Caption = 'Assign All Label-Templates';
                ToolTip = 'Assign all available label-templates.';
                Image = GetLines;
                Promoted = true;
                PromotedIsBig = true;
                PromotedCategory = Process;
                Visible = ShowLabelTemplate;
                trigger OnAction()
                begin
                    MobPrint.AssignAllTemplates(Rec."Printer Name");
                end;
            }
        }
    }
    var
        MobPrint: Codeunit "MOB Print";
        ShowPrinter: Boolean;
        ShowLabelTemplate: Boolean;
        PackAndShipEnabled: Boolean;

    trigger OnOpenPage()
    var
        PackFeatureMgt: Codeunit "MOB Pack Feature Management";
    begin
        ShowPrinter := Rec.GetFilter("Printer Name") = '';
        ShowLabelTemplate := Rec.GetFilter("Label-Template Name") = '';

        PackAndShipEnabled := PackFeatureMgt.IsEnabled();
    end;
}
