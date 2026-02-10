page 81364 "MOB Label-Templates"
{
    /// <summary>
    /// Displays (print service) templates assigned to a label
    /// </summary>

    PageType = List;
    Caption = 'Mobile Label-Templates';
    SourceTable = "MOB Label-Template";
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Templates)
            {
                field(Enabled; Rec.Enabled)
                {
                    ApplicationArea = All;
                    ToolTip = 'Enable or disable the template.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'The name of the template. Warning: Do NOT rename label-templates in use. Customizations may refer directly to this Name and will break if the record is renamed.';
                }
                field("Display Name"; Rec."Display Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'The mobile user will see this name.';
                }
                field("Template Handler"; Rec."Template Handler")
                {
                    ApplicationArea = All;
                    ToolTip = 'A Template Handler makes it possible to reuse existing logic, step-collection and data mapping.';
                }
                field("URL Mapping"; Rec."URL Mapping")
                {
                    ApplicationArea = All;
                    ToolTip = 'The file path to identify this template. I.e. /ItemLabels/NAV/MyLabel.ift.';
                    ExtendedDatatype = URL;
                    trigger OnAssistEdit()
                    begin
                        System.Hyperlink(MobPrint.GetTemplateOpenInDesignerUrl(Rec));
                    end;

                    trigger OnValidate()
                    begin
                        if xRec."URL Mapping" <> '' then
                            if not Confirm(WarnModifyPathQst, false) then
                                Error('');
                    end;
                }
                field(AvailableToPrinters; AvailableToPrinters)
                {
                    ApplicationArea = All;
                    Editable = false;
                    Style = AttentionAccent;
                    Caption = 'Available To';
                    ToolTip = 'A template is by default available to all printers, alternatively only to it''s assigned printers.';

                    trigger OnAssistEdit()
                    begin
                        LookupAssignPrinter();
                    end;
                }
                field("Number Series"; Rec."Number Series")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the code for the number series that will be used to assign numbers to labels when needed (i.e. Serial Numbers, Lot Numbers or License Plates).';
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(Printers)
            {
                ApplicationArea = All;
                Caption = 'Assign Printers';
                ToolTip = 'Assign printers to this label-template.';
                Image = PrintDocument;
                Promoted = true;
                PromotedIsBig = true;
                PromotedCategory = Process;
                trigger OnAction()
                begin
                    LookupAssignPrinter();
                end;
            }
            action(DefaultTemplates)
            {
                ApplicationArea = All;
                Caption = 'Create Default Templates';
                ToolTip = 'Create Default Templates.';
                Image = PrintInstallment;
                Promoted = true;
                PromotedIsBig = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    LabelTemplate: Record "MOB Label-Template";
                begin
                    MobPrint.SetupStandardTemplate(LabelTemplate, true);
                end;
            }
            action(CopyToNew)
            {
                ApplicationArea = All;
                Caption = 'Copy Template';
                ToolTip = 'Create a copy of this template with a new name.';
                Image = Copy;
                Promoted = true;
                PromotedIsBig = true;
                PromotedCategory = Process;
                trigger OnAction()
                begin
                    MobPrint.CopyTemplate(Rec);
                end;
            }
            action(OpenInDesigner)
            {
                ApplicationArea = All;
                Caption = 'Open In Designer';
                ToolTip = 'Open this template in the cloud designer.';
                Image = LinkWeb;
                Promoted = true;
                PromotedIsBig = true;
                PromotedCategory = Process;
                trigger OnAction()
                begin
                    System.Hyperlink(MobPrint.GetTemplateOpenInDesignerUrl(Rec));
                end;
            }
        }
    }
    var
        MobPrint: Codeunit "MOB Print";
        AvailableToPrinters: Text;
        WarnModifyPathQst: Label 'Make sure the entered value exactly matches the path in designer, otherwise the label-template will not work. Do you want to change the path?';

    internal procedure LookupAssignPrinter()
    var
        MOBPrinterLabelTemplate: Record "MOB Printer Label-Template";
        MobPrinterLabelTemplates: Page "MOB Printer Label-Templates";
    begin
        MOBPrinterLabelTemplate.SetRange("Label-Template Name", Rec.Name);
        MobPrinterLabelTemplates.SetTableView(MOBPrinterLabelTemplate);
        MobPrinterLabelTemplates.RunModal();
    end;

    trigger OnOpenPage()
    begin
        MobPrint.ErrorIfNoSetup();
    end;

    trigger OnAfterGetRecord()
    var
        MobPrinterLabelTemplate: Record "MOB Printer Label-Template";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        TemplateCount: Integer;
    begin
        MobPrinterLabelTemplate.SetRange("Label-Template Name", Rec.Name);
        TemplateCount := MobPrinterLabelTemplate.Count();
        if TemplateCount > 0 then
            AvailableToPrinters := Format(TemplateCount) + ' ' + MobWmsLanguage.GetMessage('PRINTER(S)')
        else
            AvailableToPrinters := MobWmsLanguage.GetMessage('FILTER_ALL') + ' ' + MobWmsLanguage.GetMessage('PRINTERS');
    end;
}
