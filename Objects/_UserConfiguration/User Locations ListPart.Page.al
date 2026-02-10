page 81376 "MOB User Locations ListPart"
{
    Caption = 'Mobile User Locations';
    PageType = ListPart;
    SourceTable = "Warehouse Employee";

    layout
    {
        area(Content)
        {
            repeater(List)
            {
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the code of the location in which the employee works.';
                }
                field(Default; Rec.Default)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies that the location code that is defined as the default location for this employee''s activities.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(AddLocationsToUser)
            {
                Caption = 'Add Locations';
                ToolTip = 'Use this action to add a selection of locations for the mobile user. This will create warehouse employee records for the user.';
                ApplicationArea = All;
                Image = WarehouseSetup;

                trigger OnAction()
                var
                    MobUser: Record "MOB User";
                    MobUserSetup: Codeunit "MOB User Configuration";
                begin
                    MobUser.SetRange("User ID", Rec."User ID");
                    MobUserSetup.AddLocationsToSelectedUsers(MobUser);
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        CurrPage.Update(false);
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        CurrPage.Update(false);
    end;
}
