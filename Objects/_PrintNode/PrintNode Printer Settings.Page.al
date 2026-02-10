page 81291 "MOB PrintNode Printer Settings"
{
    Caption = 'Tasklet PrintNode Printer Settings', Locked = true;
    PageType = Card;
    SourceTable = "MOB PrintNode Printer Settings";
    UsageCategory = None;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            group(PrintNode)
            {
                Caption = 'Printer', Locked = true;
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'The printer Name.', Locked = true;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'The description of the printer.', Locked = true;
                }
                field(PrintNodePrinterID; Rec."PrintNode Printer ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'The printer ID from PrintNode.', Locked = true;
                    ShowMandatory = true; // Currently not shown in GUI because the field is not editable, but might be shown in future versions

                    trigger OnAssistEdit()
                    var
                        MobPrintNodeMgt: Codeunit "MOB PrintNode Mgt.";
                    begin
                        MobPrintNodeMgt.LookupPrintNodePrinters(Rec);
                    end;
                }
                field(PrintNodeClientName; Rec."PrintNode Client Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'The name of the PrintNode client this printer is connected to.', Locked = true;
                }
            }
            group(Paper)
            {
                Caption = 'Paper', Locked = true;
                group(PaperEssential)
                {
                    Caption = 'Essential Setup', Locked = true;

                    field(PaperSize; Rec."Paper Size")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the paper size. The paper size is used to get PrintNode to print on the proper paper and sets the recommended width and height for the internally generated PDF files.', Locked = true;
                        ShowMandatory = true;
                    }
                    field(PaperTray; Rec."Paper Tray")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the output paper tray.', Locked = true;
                    }
                }
                group(PaperAdditional)
                {
                    Caption = 'Additional Setup', Locked = true;

                    field(PaperRotation; Rec."Paper Rotation")
                    {
                        ApplicationArea = All;
                        ToolTip = 'This sets the rotation angle of each page in the print - 0 for portrait, 90 for landscape, 180 for inverted portrait and 270 for inverted landscape. This setting is absolute and not relative. For example, if your output is in landscape format, setting this option to 90 will leave it unchanged. PrintNode have found that not all printers and printer drivers support this feature to the same degree. For instance, in Windows the 180 and 270 settings are often respectively treated like 0 and 90, i.e. they switch between portrait and landscape but do not invert the print.', Locked = true;
                    }
                }
            }
            group(Page)
            {
                Caption = 'Page', Locked = true;
                field(PageWidth; Rec."Page Width")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the width of the page. This is used to generate an internal PDF file which is then sent to PrintNode.', Locked = true;
                    ShowMandatory = true;
                }
                field(PageHeight; Rec."Page Height")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the height of the page. This is used to generate an internal PDF file which is then sent to PrintNode.', Locked = true;
                    ShowMandatory = true;
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        MobPrintNodeMgt: Codeunit "MOB PrintNode Mgt.";
    begin
        MobPrintNodeMgt.CheckConfirmIsEnabled();
        if not MobPrintNodeMgt.IsEnabled() then
            Error(''); // Closes page to force user to perform required setup
    end;
}
