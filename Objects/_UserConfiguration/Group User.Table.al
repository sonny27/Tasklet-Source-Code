table 81276 "MOB Group User"
{
    Access = Public;
    Caption = 'Mobile Group User';
    DataCaptionFields = "Group Code", "Mobile User ID";
    LookupPageId = "MOB Group Users";
    DrillDownPageId = "MOB Group Users";
    Permissions = tabledata "MOB Group User" = r;

    fields
    {
        field(1; "Group Code"; Code[10])
        {
            Caption = 'Group Code';
            NotBlank = true;
            TableRelation = "MOB Group";
            DataClassification = CustomerContent;
        }
        field(2; "Mobile User ID"; Code[50])
        {
            Caption = 'Mobile User ID';
            NotBlank = true;
            TableRelation = "MOB User";
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                CheckUserNotInAnotherGroup();
            end;
        }
    }

    keys
    {
        key(Key1; "Group Code", "Mobile User ID")
        {
        }
    }

    local procedure CheckUserNotInAnotherGroup()
    var
        MobGroup: Record "MOB Group";
        MobGroupUser: Record "MOB Group User";
        UserAlreadyInGroupErr: Label 'The %1: %2 is already assigned to the %3: %4. A user can only belong to one group at a time.', Comment = 'Error text for checking if user is already in another group. %1 = Fieldcaption("Mobile User ID"), %2 = User ID, %3 = MobGroup.TableCaption(), %4 = Group Code';
    begin
        MobGroupUser.SetRange("Mobile User ID", "Mobile User ID");
        MobGroupUser.SetFilter("Group Code", '<>%1', "Group Code");
        if MobGroupUser.FindFirst() then
            Error(UserAlreadyInGroupErr, FieldCaption("Mobile User ID"), "Mobile User ID", MobGroup.TableCaption(), MobGroupUser."Group Code");
    end;
}
