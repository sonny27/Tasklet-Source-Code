table 81280 "MOB Language"
{
    Access = Public;
    Caption = 'Mobile Language';
    DrillDownPageId = "MOB Languages";
    LookupPageId = "MOB Languages";
    Permissions = 
        tabledata "MOB User" = r,
        tabledata "MOB Message" = r;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
            TableRelation = Language;
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                MobWmsLanguage: Codeunit "MOB WMS Language";
                DeviceLanguageCode: Code[20];
                IsHandled: Boolean;
            begin
                CalcFields(Name);

                // Suggest device language code
                Clear(DeviceLanguageCode);
                Clear(IsHandled);
                MobWmsLanguage.OnConvertLanguageCodeToDeviceLanguageCode("Code", DeviceLanguageCode, IsHandled);
                case true of
                    (DeviceLanguageCode <> '') or IsHandled:
                        Validate("Device Language Code", DeviceLanguageCode);
                    CopyStr("Code", 1, 2) in
                    [
                        // 'CS'     // Excluded, not on Android
                        'DE',
                        'DA',
                        'ET',
                        'EN',
                        'ES',
                        'FI',
                        'FR',
                        'HR',
                        'IT',
                        'LT',
                        'LV',
                        'NL',
                        'NO',
                        'PL',
                        'PT',
                        'RO',
                        'RU',
                        'SL'
                    ]:
                        Validate("Device Language Code", CopyStr("Code", 1, 2));
                    // Exeptions where ISO 639-1 language code is not two first characters in Windows Language Code
                    "Code" = 'JPN':
                        Validate("Device Language Code", 'JA'); // Assuming Android device, windows devices are JP
                    "Code" = 'SVE':
                        Validate("Device Language Code", 'SE'); // Assuming Android device, windows devices are SV
                end;
            end;
        }
        field(2; Name; Text[50])
        {
            Caption = 'Name';
            CalcFormula = lookup(Language.Name where(Code = field(Code)));
            Editable = false;
            FieldClass = FlowField;
        }
        field(3; "Device Language Code"; Code[20])
        {
            Caption = 'Device Language Code';
            DataClassification = CustomerContent;
        }
        field(10; "Last DateTime Modified"; DateTime)
        {
            Caption = 'Last DateTime Modified';
            DataClassification = CustomerContent;
        }
        field(11; "Last Date Modified"; Date)
        {
            Caption = 'Last Date Modified';
            DataClassification = CustomerContent;
        }
        field(12; "Last Time Modified"; Time)
        {
            Caption = 'Last Time Modified';
            DataClassification = CustomerContent;
        }
        field(20; Messages; Boolean)
        {
            Caption = 'Messages';
            CalcFormula = exist("MOB Message" where("Language Code" = field("Code")));
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Code")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Code", Name, "Device Language Code")
        {
        }
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
    var
        MobUser: Record "MOB User";
        MobMessage: Record "MOB Message";
    begin
        MobUser.SetRange("Language Code", Code);
        if not MobUser.IsEmpty() then
            Error(CannotDeleteWhenUsedErr, TableCaption(), Code, MobUser.TableCaption());

        MobMessage.SetRange("Language Code", Code);
        if not MobMessage.IsEmpty() then
            Error(CannotDeleteWhenUsedErr, TableCaption(), Code, MobMessage.TableCaption());
    end;

    trigger OnRename()
    begin
        SetLastDateTimeModified();
    end;

    internal procedure SetLastDateTimeModified()
    begin
        "Last DateTime Modified" := CurrentDateTime();
        "Last Date Modified" := DT2Date("Last DateTime Modified");
        "Last Time Modified" := DT2Time("Last DateTime Modified");
    end;

    procedure GetLanguageCustomizationVersion() _LanguageCustomizationVersion: Text
    begin
        exit(Format("Last Date Modified", 0, '<Day,2><Month,2><Year4>') + Format("Last Time Modified", 0, '<Hours24><Minutes,2><Seconds,2>'));
    end;

    var
        CannotDeleteWhenUsedErr: Label '%1 %2 cannot be deleted when it is used by at least one %3.', Comment = '%1 contains Mobile Language Tablename, %2 contains Language Code, %3 contains Mobile User Tablecaption';
}

