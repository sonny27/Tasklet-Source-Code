pageextension 81412 "MOB Printer Management"
/* #if BC20- ##
extends "Standard Text Codes"
{
    // Dummy page extension without content.
    // Misc. scripts require object id in first line, but the "Printer Management" page and Printer table are not extendable before BC21.
}
/* #endif */

/* #if BC21+ */
extends "Printer Management"
{
    PromotedActionCategories = ',,,,,,,,,,,,Tasklet PrintNode', Locked = true; // Use category13 to avoid conflicts
    actions
    {
        addlast(Processing)
        {
            action(MOBAddAllPrintNodePrinters)
            {
                Caption = 'Add all PrintNode printers', Locked = true;
                ToolTip = 'Add all available printers from PrintNode.', Locked = true;
                Image = PrintInstallment;
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Category13;
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
                PromotedCategory = Category13;
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
                PromotedCategory = Category13;
                trigger OnAction()
                begin
                    Hyperlink('https://printnode.com');
                end;
            }
        }
    }
}
/* #endif */
