table 81398 "MOB DataTable Element"
{
    Access = Public;
    Caption = 'MOB DataTable Element', Locked = true;

    fields
    {
        //
        // Fields below 10 is not to be written as Nodes (assign field, rather than use SetValue)
        //
        field(1; "Key"; Integer)
        {
            Caption = 'Key', Locked = true;
            DataClassification = SystemMetadata;
            AutoIncrement = true;       // Business Central 365 temporary tables not supported
        }

        field(5; DataTableId; Text[50])
        {
            Caption = 'DataTableId', Locked = true;
            DataClassification = SystemMetadata;
        }

        //
        // Fields 10..799|1000.. are written to file as DataTable Nodes (use SetValue, rather than assigning field directly)
        //

        field(10; "Option"; Text[250])
        {
            Caption = 'Option', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(20; "Code"; Text[250])
        {
            Caption = 'Code', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(30; Name; Text[250])
        {
            Caption = 'Name', Locked = true;
            DataClassification = SystemMetadata;
        }

    }
    keys
    {
        key(Key1; "Key")
        {
        }

        key(DataTableIdKey1; DataTableId)
        {
        }
    }

    var
        NsElementMgt: Codeunit "MOB NS Element Management";
        AutoSave: Boolean;
        LastSetDataTableId: Text[50];
        MustCallCreateNext: Boolean;
        MUST_BE_TEMPORARY_Err: Label 'Internal error: %1 must be a temporary record.', Locked = true;
        CREATE_NEVER_CALLED_Err: Label 'Internal error: _HeaderConfiguration.Create() was never called.', Locked = true;

    trigger OnDelete()
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Rec);
        NsElementMgt.DeleteValues(RecRef); // Doesn't work if called through DeleteAll. Handled in Create procedure
    end;

    procedure InitDataTable(_DataTableId: Text[50])
    begin
        LastSetDataTableId := _DataTableId;
        MustCallCreateNext := true;
    end;

    // low level create with no DataTableId
    procedure Create()
    begin
        Create(true);   // with AutoSave upon every SetValue
    end;

    // low level create with no inputType - to be used from UnitTests and Templates only
    local procedure Create(_AutoSave: Boolean)
    var
        RecRef: RecordRef;
    begin
        if not IsTemporary() then
            Error(MUST_BE_TEMPORARY_Err, TableCaption());

        Init();
        Key := 0;

        AutoIncrementKey(Rec);
        DataTableId := LastSetDataTableId;
        Insert();

        // Make sure all existing values in Mob Node Value Buffer is cleared. Values may hang if step was deleted with DeleteAll
        RecRef.GetTable(Rec);
        NsElementMgt.DeleteValues(RecRef);

        AutoSave := _AutoSave;
        MustCallCreateNext := false;
    end;


    /// <summary>
    /// Save (modify) current DataTable Element. Must be called every time a DataTable Element has all values set, to persist changes.
    /// </summary>
    local procedure Save()
    begin
        if MustCallCreateNext then
            Error(CREATE_NEVER_CALLED_Err);

        TestField(Key);
        SyncronizeTableToBuffer();

        Modify();
        AutoSave := true;   // performance optimization only 'till first save -- subsequent Set'ters should autosave for less risk of errors
    end;


    // ------------------------------------------------
    // Redundant methods in all namespace buffer tables
    // ------------------------------------------------

    procedure GetSharedNodeValueBuffer(var _ToNodeValueBuffer: Record "MOB NodeValue Buffer")
    begin
        TestField(Key);
        NsElementMgt.GetSharedNodeValueBuffer(Key, _ToNodeValueBuffer);
    end;

    /// <summary>
    /// Autoincrement primary key "Key" since Autoincrement table property is not supported for BC temporary tables in cloud, hence implemented programmatically
    /// </summary>
    /// <param name="_TempElement">The DataTable Element record to autoincrement (must be a temporary record)</param>
    local procedure AutoIncrementKey(var _TempElement: Record "MOB DataTable Element")
    var
        TempElement2: Record "MOB DataTable Element" temporary;
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

    procedure SetValue(_PathToSet: Text; _NewValue: Text)
    begin
        SetValue(0, _PathToSet, _NewValue);
    end;

    local procedure SetValue(_FieldNo: Integer; _PathToSet: Text; _NewValue: Text)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Rec);
        NsElementMgt.SetValue(RecRef, Rec."Key", _PathToSet, _NewValue, _FieldNo);
        RecRef.SetTable(Rec);

        if AutoSave then
            Save();
    end;

    procedure SetValueAsCData(_PathToSet: Text; _NewXmlCData: XmlCData)
    begin
        SetValueAsCData(0, _PathToSet, _NewXmlCData.Value());
    end;

    procedure SetValueAsCData(_PathToSet: Text; _NewCDataValue: Text)
    begin
        SetValueAsCData(0, _PathToSet, _NewCDataValue);
    end;

    local procedure SetValueAsCData(_FieldNo: Integer; _PathToSet: Text; _NewCDataValue: Text)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Rec);
        NsElementMgt.SetValueAsCData(RecRef, Rec."Key", _PathToSet, _NewCDataValue, _FieldNo);
        RecRef.SetTable(Rec);

        if AutoSave then
            Save();
    end;

    procedure GetValue(_PathToGet: Text): Text
    begin
        exit(GetValue(0, _PathToGet, false));
    end;

    procedure GetValue(_FieldNo: Integer; _PathToGet: Text; _ErrorIfNotExists: Boolean): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Rec);
        exit(NsElementMgt.GetValue(RecRef, Rec."Key", _PathToGet, _FieldNo, _ErrorIfNotExists));
    end;

    procedure SetMustCallCreateNext(_NewValue: Boolean)
    var
    begin
        MustCallCreateNext := _NewValue;
    end;

    /// <summary>
    /// Syncronize current DataTable Element record  to internal NodeValue Buffer. All text fields are syncronized excluding field no. range ..10 and 800..999
    /// Oneway syncronization from table to buffer hance no return value by SetTable.
    /// </summary>
    internal procedure SyncronizeTableToBuffer()
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Rec);
        NsElementMgt.SyncronizeTableToBuffer(RecRef);
    end;

    //
    // Standard Set'ers
    //

    procedure Set_Code(_NewValue: Text)
    begin
        SetValue(FieldNo("Code"), FieldName("Code"), _NewValue);
    end;

    procedure Set_Code(_TrueFalseExpression: Boolean; _NewValueTrue: Text; _NewValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_Code(_NewValueTrue)
        else
            Set_Code(_NewValueFalse);
    end;

    procedure Get_Code(): Text
    begin
        exit(GetValue(FieldNo("Code"), FieldName("Code"), false));
    end;

    procedure Set_Name(_NewValue: Text)
    begin
        SetValue(FieldNo(Name), FieldName(Name), _NewValue);
    end;

    procedure Set_Name(_TrueFalseExpression: Boolean; _NewValueTrue: Text; _NewValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_Name(_NewValueTrue)
        else
            Set_Name(_NewValueFalse);
    end;

    procedure Get_Name(): Text
    begin
        exit(GetValue(FieldNo(Name), FieldName(Name), false));
    end;

    procedure Set_Option(_NewValue: Text)
    begin
        SetValue(FieldNo("Option"), FieldName("Option"), _NewValue);
    end;

    procedure Set_Option(_TrueFalseExpression: Boolean; _NewValueTrue: Text; _NewValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_Option(_NewValueTrue)
        else
            Set_Option(_NewValueFalse);
    end;

    procedure Get_Option(): Text
    begin
        exit(GetValue(FieldNo("Option"), FieldName("Option"), false));
    end;


    // 
    // Template Library: Create Methods
    // 

    procedure Create_Code(_CodeText: Text)
    begin
        Create(false);
        Set_Code(_CodeText);
        Save();
    end;

    procedure Create_CodeAndName(_CodeText: Text; _Name: Text)
    begin
        Create(false);
        Set_Code(_CodeText);
        Set_Name(_Name);
        Save();
    end;

    procedure Create_Option(_Option: Text)
    begin
        Create(false);
        Set_Option(_Option);
        Save();
    end;

}
