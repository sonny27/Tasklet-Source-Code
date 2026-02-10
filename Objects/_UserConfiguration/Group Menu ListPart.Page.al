page 81378 "MOB Group Menu ListPart"
{
    Caption = 'Mobile Group Menu';
    PageType = ListPart;
    SourceTable = "MOB Group Menu Config";
    SourceTableView = sorting("Sorting");

    layout
    {
        area(Content)
        {
            repeater(List)
            {
                field("Mobile Group"; Rec."Mobile Group")
                {
                    ToolTip = 'Mobile Group associated with the Menu Options.';
                    Editable = false;
                    Visible = false;
                    ApplicationArea = All;
                }
                field("Mobile Menu Option"; Rec."Mobile Menu Option")
                {
                    ToolTip = 'Menu Option to be available for all members of current Mobile Group.';
                    ApplicationArea = All;
                }
                field(Sorting; Rec.Sorting)
                {
                    ToolTip = 'Sorting is used to specify in which order Menu Options appear on the Mobile Device.';
                    ApplicationArea = All;
                }
            }
        }
    }
}
