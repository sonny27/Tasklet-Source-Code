table 81390 "MOB NS Resp Element"
{
    Access = Public;
    Caption = 'MOB NS Resp Element', Locked = true;

    fields
    {
        field(1; "Key"; Integer)
        {
            Caption = 'Key', Locked = true;
            DataClassification = SystemMetadata;
            AutoIncrement = true;       // Business Central 365 temporary tables not supported
        }
        field(6; NodeName; Text[50])
        {
            Caption = 'NodeName', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(10; description; Text[250])
        {
            Caption = 'description', Locked = true;
            DataClassification = SystemMetadata;
        }
        // Note: Field No cannot be > 100000 due to buffer sorting

    }
    keys
    {
        key(Key1; "Key")
        {
        }
    }

    var
        NsElementMgt: Codeunit "MOB NS Element Management";
        MUST_BE_TEMPORARY_Err: Label 'Internal error: %1 must be a temporary record.', Locked = true;

    trigger OnDelete()
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Rec);
        NsElementMgt.DeleteValues(RecRef); // Doesn't work if called through DeleteAll. Handled in Create procedure
    end;

    // ------------------------------------------------
    // Redundant methods in all namespace buffer tables
    // ------------------------------------------------

    /// <summary>
    /// Initialize for a new set of elements.
    /// </summary>
    /// <param name="_NodeName">The name of the childnode of the ReponseData-node</param>
    procedure Create(_NodeName: Text)
    var
        RecRef: RecordRef;
    begin
        if not IsTemporary() then
            Error(MUST_BE_TEMPORARY_Err, TableCaption());

        Init();
        Key := 0;

        NodeName := _NodeName;

        // AutoIncrement property not supported for Business Central 365 temporary tables 
        AutoIncrementKey(Rec);
        Insert();

        // Make sure all existing values in Mob Node Value Buffer is cleared. Values may hang if step was deleted with DeleteAll
        RecRef.GetTable(Rec);
        NsElementMgt.DeleteValues(RecRef);
    end;

    procedure Save()
    begin
        TestField(Key);
        SyncronizeTableToBuffer();
        Modify();
    end;

    procedure GetSharedNodeValueBuffer(var _ToNodeValueBuffer: Record "MOB NodeValue Buffer")
    begin
        TestField(Key);
        NsElementMgt.GetSharedNodeValueBuffer(Key, _ToNodeValueBuffer);
    end;

    /// <summary>
    /// Autoincrement primary key "Key" since Autoincrement table property is not supported for BC temporary tables in cloud, hence implemented programmatically
    /// </summary>
    /// <param name="_TempElement">The NS Resp Element record to autoincrement (must be a temporary record)</param>
    local procedure AutoIncrementKey(var _TempElement: Record "MOB NS Resp Element")
    var
        TempElement2: Record "MOB NS Resp Element" temporary;
        NextKey: Integer;
    begin
        if ("Key" = 0) then begin
            if not _TempElement.IsTemporary() then
                Error(MUST_BE_TEMPORARY_Err, _TempElement.TableCaption());  // Avoid error on Copy below

            TempElement2.Copy(_TempElement, true); // ShareTable=true
            TempElement2.Reset();   // All FilterGroups

            if TempElement2.FindLast() then
                NextKey := TempElement2."Key" + 1
            else
                NextKey := 1;

            _TempElement."Key" := NextKey;
        end;
    end;

    procedure SetValue(_PathToSet: Text; NewValue: Text)
    begin
        SetValue(0, _PathToSet, NewValue);
    end;

    internal procedure SetValue(_FieldNo: Integer; _PathToSet: Text; NewValue: Text)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Rec);
        NsElementMgt.SetValue(RecRef, Rec."Key", _PathToSet, NewValue, _FieldNo);
        RecRef.SetTable(Rec);
    end;

    procedure SetValueAsCData(_PathToSet: Text; _NewXmlCData: XmlCData)
    begin
        SetValueAsCData(0, _PathToSet, _NewXmlCData.Value());
    end;

    procedure SetValueAsCData(_PathToSet: Text; _NewCDataValue: Text)
    begin
        SetValueAsCData(0, _PathToSet, _NewCDataValue);
    end;

    internal procedure SetValueAsCData(_FieldNo: Integer; _PathToSet: Text; _NewCDataValue: Text)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Rec);
        NsElementMgt.SetValueAsCData(RecRef, Rec."Key", _PathToSet, _NewCDataValue, _FieldNo);
        RecRef.SetTable(Rec);
    end;

    procedure GetValue(_PathToGet: Text): Text
    begin
        exit(GetValue(0, _PathToGet, false));
    end;

    internal procedure GetValue(_FieldNo: Integer; _PathToGet: Text; _ErrorIfNotExists: Boolean): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Rec);
        exit(NsElementMgt.GetValue(RecRef, Rec."Key", _PathToGet, _FieldNo, _ErrorIfNotExists));
    end;

    procedure DeleteValue(_PathToDelete: Text)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Rec);
        NsElementMgt.DeleteValue(RecRef, Rec."Key", _PathToDelete);
        RecRef.SetTable(Rec);
    end;

    procedure SyncronizeTableToBuffer()
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Rec);
        NsElementMgt.SyncronizeTableToBuffer(RecRef);
        // oneway syncronization from table to buffer hance no return value by SetTable
    end;

    // -------------------------
    // Get/Set procedures
    // -------------------------

    procedure Set_description(_NewValue: Text)
    begin
        SetValue(FieldNo(description), FieldName(description), _NewValue);
    end;

    procedure Get_description(): Text
    begin
        exit(GetValue(FieldNo(description), FieldName(description), false));
    end;

    // ---------------------------------
    // -------- HELPER FUNCTIONS--------
    // ---------------------------------

    /// <summary>
    /// ValueInteractionPermission can have three values defined by Enum "MOB Value Interaction": AllowEdit, ApplyDirectly, VerifyOnly
    /// - AllowEdit - Allows the user to edit the value in the quantity step.    
    /// - ApplyDirectly - Hides the quantity step all together.    
    /// - VerifyOnly - Disables the quantity step, allowing the user to see, but not edit it.
    /// </summary>
    /// <param name="_Quantity">The Quantity to return in the response to the mobile device</param>        
    /// <param name="_ValueInteractionPermission">Three values avaliable, defined by Enum "MOB Value Interaction" : AllowEdit, ApplyDirectly, VerifyOnly. Defines behavior on the mobile device</param>
    procedure Set_LotNumberInformation(_Quantity: Decimal; _ValueInteractionPermission: Enum "MOB ValueInteractionPermission")
    begin
        Create('LotNumberInformation');
        SetValue('Quantity', Format(_Quantity, 0, 9));
        SetValue('ValueInteractionPermission', Format(_ValueInteractionPermission));
    end;

    /// <summary>
    /// When utilizing Serial number validation, an ItemNumber can be returned, which then can be used as input on the mobile device
    /// </summary>
    /// <param name="_ItemNumber">The ItemNumber value to return in the response to the mobile device</param>
    procedure Set_SerialNumberInformation(_ItemNumber: Code[20])
    begin
        Create('SerialNumberInformation');
        SetValue('ItemNumber', _ItemNumber);
    end;
}
