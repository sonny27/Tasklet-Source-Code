page 81276 "MOB Group Users"
{
    Caption = 'Mobile Group Users';
    PageType = List;
    SourceTable = "MOB Group User";
    DataCaptionFields = "Group Code";

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                field("Group Code"; Rec."Group Code")
                {
                    ToolTip = 'Code for the Mobile Group.';
                    Editable = false;
                    Visible = false;
                    ApplicationArea = All;
                }
                field("Mobile User ID"; Rec."Mobile User ID")
                {
                    ToolTip = 'Mobile User ID associated with the Mobile Group.';
                    ApplicationArea = All;
                }
            }
        }
    }
}
