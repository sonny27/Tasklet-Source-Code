page 81272 "MOB Menu Options"
{
    Caption = 'Mobile Menu Options';
    AdditionalSearchTerms = 'Mobile Menu Options Tasklet Configuration Device Scanner', Locked = true;
    PageType = List;
    SourceTable = "MOB Menu Option";
    UsageCategory = Administration;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Control1000000000)
            {
                field("Menu Option"; Rec."Menu Option")
                {
                    ToolTip = 'All existing Menu Options at the Mobile Device. Not every Menu Option may be visible for every Mobile User (a Mobile User must be member of a Mobile Group with the Menu Option enabled).';
                    ApplicationArea = All;
                }
            }
        }
    }
}
