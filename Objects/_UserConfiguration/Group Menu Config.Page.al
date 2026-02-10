page 81273 "MOB Group Menu Config"
{
    Caption = 'Mobile Group Menu Config';
    PageType = List;
    SourceTable = "MOB Group Menu Config";
    SourceTableView = sorting("Sorting");
    DataCaptionFields = "Mobile Group";

    layout
    {
        area(Content)
        {
            repeater(Control1000000000)
            {
                field("Mobile Group"; Rec."Mobile Group")
                {
                    ToolTip = 'Mobile Group associated with the Menu Options.';
                    Visible = false;
                    Editable = false;
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
