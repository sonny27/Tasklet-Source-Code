page 81275 "MOB Groups"
{
    Caption = 'Mobile Groups';
    AdditionalSearchTerms = 'Mobile Groups Tasklet Configuration Device Scanner', Locked = true;
    PageType = List;
    SourceTable = "MOB Group";
    UsageCategory = Administration;
    ApplicationArea = All;
    CardPageId = "MOB Group Card";
    Editable = false;
    RefreshOnActivate = true;

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
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
                field("User Count"; Rec."User Count")
                {
                    ToolTip = 'Specifies the number of users assigned to this Mobile Group.';
                    ApplicationArea = All;
                }
                field("Menu Item Count"; Rec."Menu Item Count")
                {
                    ToolTip = 'Specifies the number of menu items assigned to this Mobile Group.';
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            group("&Group")
            {
                Caption = '&Group';
                action(Users)
                {
                    Caption = 'Users';
                    ToolTip = 'Shows Users assigned to Mobile Group';
                    ApplicationArea = All;
                    Image = Users;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    RunObject = page "MOB Group Users";
                    RunPageMode = Edit;
                    RunPageLink = "Group Code" = field(Code);
                    /* #if BC21+ */
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Replaced by "Group Users ListPart" on the "Mobile Groups" page. (planned for removal 10/2026)';
                    ObsoleteTag = 'MOB5.58';
                    /* #endif */
                    Visible = false;
                    Enabled = false;
                }
                action("Mobile Menu")
                {
                    Caption = 'Mobile Menu';
                    ToolTip = 'Shows Mobile Menu Options assigned to Mobile Group';
                    ApplicationArea = All;
                    Image = SetupList;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    RunObject = page "MOB Group Menu Config";
                    RunPageLink = "Mobile Group" = field(Code);
                    RunPageView = sorting("Mobile Group", "Mobile Menu Option")
                                  order(ascending);
                    RunPageMode = Edit;
                    /* #if BC21+ */
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Replaced by "Mobile Menu ListPart" on the "Mobile Groups" page. (planned for removal 10/2026)';
                    ObsoleteTag = 'MOB5.58';
                    /* #endif */
                    Visible = false;
                    Enabled = false;
                }
            }
        }
    }
}
