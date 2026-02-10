table 81274 "MOB User"
{
    Access = Public;
    Caption = 'Mobile User';
    DataCaptionFields = "User ID";
    LookupPageId = "MOB Users";
    DrillDownPageId = "MOB Users";
    Permissions = tabledata "MOB Group User" = rid;

    fields
    {
        field(1; "User ID"; Code[50])
        {
            Caption = 'User ID';
            NotBlank = true;
            DataClassification = EndUserIdentifiableInformation;
            // new validationmethod since platform 15
            /* #if BC15+ */
            TableRelation = User."User Name";
            ValidateTableRelation = false;

            trigger OnValidate()
            var
                UserSelection: Codeunit "User Selection";
            begin
                UserSelection.ValidateUserName("User ID");
            end;
            /* #endif */
            /* #if BC14 ##
            trigger OnLookup();
            var
                MobUser: Record "MOB User";
                MobUsers: Page "MOB Users";
            begin
                MobUsers.LookupMode := true;
                if MobUsers.RunModal() = Action::LookupOK then begin
                    MobUsers.GetRecord(MobUser);
                    "User ID" := MobUser."User ID";
                end;
            end;
            
            trigger OnValidate();
            var
                User: Record User;
            begin
                User.SetRange("User Name", "User ID");
                User.FindFirst();   // intentional error if not found
                User := User; // intentional to Suppress vsix warning
            end;
            /* #endif */
        }
        field(3; "User Name"; Text[80])
        {
            Caption = 'User Name';
            FieldClass = FlowField;
            CalcFormula = lookup(User."Full Name" where("User Name" = field("User ID")));
            Editable = false;
        }
        field(4; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            TableRelation = "MOB Language";
            DataClassification = CustomerContent;
        }
        field(10; "Employee No."; Code[20])
        {
            Caption = 'Employee No.';
            TableRelation = Employee;
            ValidateTableRelation = false;
            DataClassification = EndUserIdentifiableInformation;
        }

        /* #if BC20+ */
        field(20; "Profiling Enabled Until"; DateTime)
        {
            Caption = 'Profiling Enabled Until';
            DataClassification = CustomerContent;
            Editable = false;
        }
        /* #endif */
        field(21; "Location Count"; Integer)
        {
            Caption = 'Location Count';
            FieldClass = FlowField;
            CalcFormula = count("Warehouse Employee" where("User ID" = field("User ID")));
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "User ID")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "User ID", "User Name", "Language Code")
        {
        }
    }

    trigger OnDelete()
    var
        MobGroupUser: Record "MOB Group User";
    begin
        MobGroupUser.SetRange("Mobile User ID", "User ID");
        MobGroupUser.DeleteAll(true);
    end;

    internal procedure GetUserGroupCode(): Code[10]
    var
        MobGroupUser: Record "MOB Group User";
    begin
        MobGroupUser.SetRange("Mobile User ID", "User ID");
        if MobGroupUser.FindFirst() then
            exit(MobGroupUser."Group Code");
    end;

    internal procedure ValidateMobileUserGroup(_SelectedGroupCode: Code[10])
    var
        MobGroupUser: Record "MOB Group User";
    begin
        if _SelectedGroupCode = '' then
            exit;

        MobGroupUser.SetRange("Mobile User ID", "User ID");
        MobGroupUser.DeleteAll(true);

        MobGroupUser.Init();
        MobGroupUser.Validate("Group Code", _SelectedGroupCode);
        MobGroupUser.Validate("Mobile User ID", "User ID");
        MobGroupUser.Insert(true);
    end;

    internal procedure GetLocationStatusStyle(): Text[20]
    begin
        if "Location Count" = 0 then
            exit('Unfavorable')
        else
            exit('Standard');
    end;
}
