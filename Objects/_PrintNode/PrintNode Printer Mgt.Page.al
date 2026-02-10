page 81292 "MOB PrintNode Printer Mgt."
{
    /* #if BC16+ */
    ApplicationArea = All;
    UsageCategory = Administration;
    /* #endif */
    Caption = 'Tasklet PrintNode Printer Management', Locked = true;
    AdditionalSearchTerms = 'Tasklet PrintNode Printer Management Configuration', Locked = true;
    PageType = List;
    Editable = false;
    CardPageId = "MOB PrintNode Printer Settings";
    SourceTable = "MOB PrintNode Printer Settings";
    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'The printer name.', Locked = true;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'The description of the printer.', Locked = true;
                }
                field("Paper Tray"; Rec."Paper Tray")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the output paper tray.', Locked = true;
                }
                field("Paper Size"; Rec."Paper Size")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the paper size. The paper size is used to get PrintNode to print on the proper paper and sets the recommended width and height for the internally generated PDF files.', Locked = true;
                }
                field("Page Width"; Rec."Page Width")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the width of the page. This is used when generating the internal PDF file which is sent to PrintNode.', Locked = true;
                }
                field("Page Height"; Rec."Page Height")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the height of the page. This is used when generating the internal PDF file which is sent to PrintNode.', Locked = true;
                }
                field("Paper Rotation"; Rec."Paper Rotation")
                {
                    ApplicationArea = All;
                    ToolTip = 'This sets the rotation angle of each page in the print - 0 for portrait, 90 for landscape, 180 for inverted portrait and 270 for inverted landscape. This setting is absolute and not relative. For example, if your output is in landscape format, setting this option to 90 will leave it unchanged. PrintNode have found that not all printers and printer drivers support this feature to the same degree. For instance, in Windows the 180 and 270 settings are often respectively treated like 0 and 90, i.e. they switch between portrait and landscape but do not invert the print.', Locked = true;
                }
                field("PrintNode Printer ID"; Rec."PrintNode Printer ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'The Printer ID from PrintNode.', Locked = true;
                }
                field("PrintNode Client Name"; Rec."PrintNode Client Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'The name of the PrintNode client this printer is connected to.', Locked = true;
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(MOBAddAllPrintNodePrinters)
            {
                Caption = 'Add all PrintNode printers', Locked = true;
                ToolTip = 'Add all available printers from PrintNode.', Locked = true;
                Image = PrintInstallment;
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                var
                    PrintNodeMgt: Codeunit "MOB PrintNode Mgt.";
                begin
                    PrintNodeMgt.AddAllPrinters();
                end;
            }
            action(MOBAddPrintNodePrinter)
            {
                ApplicationArea = All;
                Caption = 'Add a PrintNode printer', Locked = true;
                ToolTip = 'Add one specific PrintNode printer.', Locked = true;
                Image = Print;
                Promoted = true;
                PromotedIsBig = true;
                PromotedOnly = true;
                PromotedCategory = Process;
                RunPageMode = Create;
                RunObject = page "MOB PrintNode Printer Settings";
            }
            action(MOBOpenPrintNodeCom)
            {
                ApplicationArea = All;
                Caption = 'PrintNode.com', Locked = true;
                ToolTip = 'Opens PrintNode.com where you can set up a user and get an API key.', Locked = true;
                Image = Open;
                Promoted = true;
                PromotedIsBig = true;
                PromotedOnly = true;
                PromotedCategory = Process;
                trigger OnAction()
                begin
                    Hyperlink('https://printnode.com');
                end;
            }
        }
    }
}
