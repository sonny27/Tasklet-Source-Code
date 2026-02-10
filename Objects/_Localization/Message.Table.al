table 81282 "MOB Message"
{
    Access = Public;
    Caption = 'Mobile Message';
    DrillDownPageId = "MOB Messages";
    LookupPageId = "MOB Messages";

    fields
    {
        field(1; "Code"; Code[50])
        {
            Caption = 'Code';
            NotBlank = true;
            DataClassification = CustomerContent;
        }
        field(2; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            NotBlank = true;
            DataClassification = CustomerContent;
        }
        field(3; Message; Text[250])
        {
            Caption = 'Message';
            DataClassification = CustomerContent;
        }
        field(4; "Message Type"; Option)
        {
            Caption = 'Message Type';
            OptionMembers = NAV,Mobile;
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(Key1; "Language Code", "Code")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        SetLastDateTimeModified();
    end;

    trigger OnModify()
    begin
        SetLastDateTimeModified();
    end;

    trigger OnDelete()
    begin
        SetLastDateTimeModified();
    end;

    trigger OnRename()
    begin
        SetLastDateTimeModified();
    end;

    local procedure SetLastDateTimeModified()
    begin
        if MobLanguage.Get("Language Code") then begin
            MobLanguage.SetLastDateTimeModified();
            MobLanguage.Modify();
        end;
    end;

    // Used in customization samples
    procedure Create(_LanguageCode: Code[10]; _MessageCode: Code[50]; _MessageText: Text[250])
    var
        MobWmsLanguage: Codeunit "MOB WMS Language";
    begin
        // Public Create procedure for consistent naming with other events
        MobWmsLanguage.CreateMergeMessage(Rec, _LanguageCode, _MessageCode, _MessageText);
    end;

    var
        // Text001: Label '%1 %2 cannot be deleted when it is used by at least one %3.';
        MobLanguage: Record "MOB Language";
}

