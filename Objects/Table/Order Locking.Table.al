table 81283 "MOB Order Locking"
{
    Access = Public;

    Caption = 'MobileOrderLocking', Locked = true;

    fields
    {
        field(1; BackendID; Code[250]) // BackendID now increased to 250
        {
            Caption = 'BackendID', Locked = true;
            DataClassification = CustomerContent;
            NotBlank = true;
        }
        field(2; MobileUser; Code[50])
        {
            Caption = 'MobileUser', Locked = true;
            DataClassification = CustomerContent;
        }
        field(3; Name; Text[80])
        {
            Caption = 'Name';  // Used for FieldCaption and must be translated
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(Key1; BackendID)
        {
        }
    }

    fieldgroups
    {
    }


    /// <summary>
    /// Insert via BackendID
    /// </summary>
    procedure InsertLock(_BackendID: Code[250]; _MobileUser: Code[50]; _MobileUserName: Text[80]): Boolean
    begin
        BackendID := _BackendID;
        MobileUser := _MobileUser;
        Name := _MobileUserName;
        Insert();
    end;

    /// <summary>
    /// DeleteInsert via BackendID
    /// </summary>
    procedure DeleteLock(_BackendID: Code[250]): Boolean
    begin
        if Get(_BackendID) then
            Delete();
    end;
}

