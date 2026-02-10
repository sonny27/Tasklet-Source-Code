page 81360 "MOB PrintNode Select Printer"
{
    Caption = 'Select Printer', Locked = true;
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "MOB PrintNode Printer Settings";
    SourceTableTemporary = true;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'The printer Name from PrintNode.', Locked = true;
                }
                field(PrintNodeID; Rec."PrintNode Printer ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'The printer ID from PrintNode.', Locked = true;
                }
                field(PrintNodeClient; Rec."PrintNode Client Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'The name of the PrintNode client this printer is connected to.', Locked = true;
                }
            }
        }
    }
}
