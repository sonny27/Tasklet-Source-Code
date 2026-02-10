page 81377 "MOB Group Users ListPart"
{
    Caption = 'Mobile Group Users';
    PageType = ListPart;
    SourceTable = "MOB Group User";

    layout
    {
        area(Content)
        {
            repeater(List)
            {
                field("Mobile User ID"; Rec."Mobile User ID")
                {
                    ToolTip = 'Specifies the Mobile User ID associated with the Mobile Group.';
                    ApplicationArea = All;
                }
            }
        }
    }
}
