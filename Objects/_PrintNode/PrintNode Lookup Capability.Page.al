page 81290 "MOB PrintNode LookupCapability"
{
    Caption = 'Tasklet PrintNode Printer Capabilities', Locked = true, Comment = 'Prefix with Tasklet instead of Mobile and caption is by-design different than table name.';
    PageType = List;
    SourceTable = "MOB PrintNode LookupCapability";
    UsageCategory = None;
    Editable = false;
    SourceTableTemporary = true;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(Name; Rec.Value)
                {
                    ApplicationArea = All;
                    ToolTip = 'The printer capability value.', Locked = true;
                }
                field("Paper Size Width"; Rec."Paper Size Width")
                {
                    ApplicationArea = All;
                    ToolTip = 'The width of the paper.', Locked = true;
                    Visible = PaperSizeVisible;
                }
                field("Paper Size Height"; Rec."Paper Size Height")
                {
                    ApplicationArea = All;
                    ToolTip = 'The height of the paper.', Locked = true;
                    Visible = PaperSizeVisible;
                }
            }
        }
    }
    trigger OnOpenPage()
    var
        MobPrintNodeMgt: Codeunit "MOB PrintNode Mgt.";
    begin
        // Rec is filtered with "PrintNode Printer ID" and Type (Size or Tray) via the TableRelation to populate the table for a specific printer
        MobPrintNodeMgt.LoadCapabilities(Rec);

        // Page is used for multiple capability types. Some fields only relevant for selected types
        if Rec.FindFirst() then
            PaperSizeVisible := Rec.Type = Rec.Type::PaperSize;
    end;

    var
        PaperSizeVisible: Boolean;
}
