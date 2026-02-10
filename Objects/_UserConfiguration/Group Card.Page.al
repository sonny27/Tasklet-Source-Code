page 81318 "MOB Group Card"
{
    Caption = 'Mobile Group Card';
    PageType = Card;
    SourceTable = "MOB Group";

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';
                field("Code"; Rec.Code)
                {
                    ToolTip = 'Code for the Mobile Group.';
                    ApplicationArea = All;
                }
                field(Name; Rec.Name)
                {
                    ToolTip = 'Name of the Mobile Group.';
                    ApplicationArea = All;
                }
            }
            group("Group Configuration")
            {
                ShowCaption = false;

                part(MobGroupUsers; "MOB Group Users ListPart")
                {
                    Caption = 'Users';
                    ApplicationArea = All;
                    SubPageLink = "Group Code" = field(Code);
                    UpdatePropagation = Both;
                }
                part(MobGroupMenu; "MOB Group Menu ListPart")
                {
                    Caption = 'Menu Items';
                    ApplicationArea = All;
                    SubPageLink = "Mobile Group" = field(Code);
                    UpdatePropagation = Both;
                }
            }
        }
    }
}
