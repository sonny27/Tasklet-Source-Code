codeunit 81392 "MOB NS Element Management"
{
    Access = Public;
    var
        NodeValueBufferMgt: Codeunit "MOB NodeValue Buffer Mgt.";
        PATH_MUST_NOT_BE_KEY_Err: Label 'Internal error: You cannot use "Key" as path', Locked = true;

    internal procedure GetGroupByValues(var _RecRef: RecordRef; _ReferenceKey: Integer; _GroupBy: Text): Text
    var
        GroupByFieldsList: List of [Text];
        GroupByFieldName: Text;
        GroupByValues: Text;
    begin
        if _GroupBy = '' then
            exit('');

        GroupByFieldsList := _GroupBy.Split(',');
        foreach GroupByFieldName in GroupByFieldsList do
            GroupByValues := GroupByValues + GetValue(_RecRef, _ReferenceKey, GroupByFieldName, 0, true) + ',';

        exit(DelChr(GroupByValues, '>', ','));
    end;

    /// <param name="_ReferenceKey">_ReferenceKey = 0 -> Value from RecRef field no. 1</param>
    /// <param name="_FieldNo">_FieldNo = 0 -> Sorting is set to 100000+ during autoincrement</param>
    internal procedure SetValue(var _RecRef: RecordRef; _ReferenceKey: Integer; _PathToSet: Text[250]; _NewValue: Text; _FieldNo: Integer)
    begin
        if _ReferenceKey = 0 then
            Evaluate(_ReferenceKey, GetValueByFieldNo(_RecRef, 1));

        if _FieldNo = 0 then
            _FieldNo := FieldName2FieldNo(_RecRef, _PathToSet);

        NodeValueBufferMgt.SetValue(_ReferenceKey, _PathToSet, _NewValue, _FieldNo);      // _FieldNo = 0 -> Sorting is set to 100000+ during autoincrement

        if (_FieldNo <> 0) then  // Path has a corresponding database field in current table
            SetValueByFieldNo(_RecRef, _FieldNo, _NewValue);
    end;

    internal procedure SetValueAsCData(var _RecRef: RecordRef; _ReferenceKey: Integer; _PathToSet: Text[250]; _NewValueAsCData: Text; _FieldNo: Integer)
    begin
        if _ReferenceKey = 0 then
            Evaluate(_ReferenceKey, GetValueByFieldNo(_RecRef, 1));

        if _FieldNo = 0 then
            _FieldNo := FieldName2FieldNo(_RecRef, _PathToSet);

        NodeValueBufferMgt.SetValueAsCData(_ReferenceKey, _PathToSet, _NewValueAsCData, _FieldNo);      // FieldNo = 0 -> Sorting is set to 100000+ during autoincrement

        if (_FieldNo <> 0) then  // Path has a corresponding database field in current table
            SetValueByFieldNo(_RecRef, _FieldNo, _NewValueAsCData);
    end;

    internal procedure SetValueAsHtml(var _RecRef: RecordRef; _ReferenceKey: Integer; _PathToSet: Text[250]; _NewHtmlValue: Text; _FieldNo: Integer)
    begin
        if _ReferenceKey = 0 then
            Evaluate(_ReferenceKey, GetValueByFieldNo(_RecRef, 1));

        if _FieldNo = 0 then
            _FieldNo := FieldName2FieldNo(_RecRef, _PathToSet);

        NodeValueBufferMgt.SetValueAsHtml(_ReferenceKey, _PathToSet, _NewHtmlValue, _FieldNo);      // FieldNo = 0 -> Sorting is set to 100000+ during autoincrement (or left as 0 if Path is 'html')

        if (_FieldNo <> 0) then  // Path has a corresponding database field in current table
            SetValueByFieldNo(_RecRef, _FieldNo, _NewHtmlValue);
    end;

    internal procedure HasValue(var _RecRef: RecordRef; _ReferenceKey: Integer; _PathToGet: Text[250]): Boolean
    begin
        if _ReferenceKey = 0 then
            Evaluate(_ReferenceKey, GetValueByFieldNo(_RecRef, 1));

        exit(NodeValueBufferMgt.Exists(_ReferenceKey, _PathToGet));
    end;

    internal procedure GetValue(var _RecRef: RecordRef; _ReferenceKey: Integer; _PathToGet: Text[250]; _FieldNo: Integer): Text
    begin
        // Default behaviour is no error if path not exists
        exit(GetValue(_RecRef, _ReferenceKey, _PathToGet, _FieldNo, false));
    end;

    /// <param name="_ReferenceKey">_ReferenceKey = 0 -> fallback to value of field(1) from RecRef</param>
    /// <param name="_FieldNo">_FieldNo = 0 -> fallback to FieldName2FieldNo</param>
    internal procedure GetValue(var _RecRef: RecordRef; _ReferenceKey: Integer; _PathToGet: Text[250]; _FieldNo: Integer; _ErrorIfNotExists: Boolean): Text
    var
        BufferValue: Text;
        TableFieldValue: Text;
        MaxDataLength: Integer;    // DataLength property from field definition = MaxStrLen
    begin
        // Optimization: Return value directly from table field if TableFieldValue is shorter than MaxStrLen (not cut off)
        // Assuming TableField is populated from SetValue including blank values (not testing for blank in condition below)
        // Cannot know if a blank TableFieldValue was set or not, hence optimization can only work when not _ErrorIfNotExists
        Clear(MaxDataLength);
        if _FieldNo = 0 then
            _FieldNo := FieldName2FieldNo(_RecRef, _PathToGet);

        if (_FieldNo <> 0) then begin
            TableFieldValue := GetValueByFieldNo(_RecRef, _FieldNo, MaxDataLength);

            if (not _ErrorIfNotExists) and (StrLen(TableFieldValue) < MaxDataLength) then
                exit(TableFieldValue);
        end;

        // Fallback: Read value from buffer when cannot definitely be read from table field
        if _ReferenceKey = 0 then
            Evaluate(_ReferenceKey, GetValueByFieldNo(_RecRef, 1));
        BufferValue := NodeValueBufferMgt.GetValue(_ReferenceKey, _PathToGet, _ErrorIfNotExists);

        // table field has preference over buffer when values are inconsistent since this can only happen if buffer field  
        // was set by SetValues, then manually set by table level assigment afterwards
        case true of
            (BufferValue = TableFieldValue):
                exit(BufferValue);
            ((BufferValue <> '') and (TableFieldValue = '')):
                exit(BufferValue);
            ((TableFieldValue <> '') and (BufferValue = '')):
                exit(TableFieldValue);
            ((StrLen(BufferValue) >= StrLen(TableFieldValue)) and (CopyStr(BufferValue, 1, StrLen(TableFieldValue)) = TableFieldValue)):
                exit(BufferValue);
            else
                exit(TableFieldValue);
        end;
    end;

    internal procedure GetValueAsBoolean(var _RecRef: RecordRef; _ReferenceKey: Integer; _PathToGet: Text[250]; _FieldNo: Integer; _ErrorIfNotExists: Boolean) ReturnValue: Boolean
    var
        MobToolbox: Codeunit "MOB Toolbox";
        TextValue: Text;
    begin
        TextValue := GetValue(_RecRef, _ReferenceKey, _PathToGet, _FieldNo, _ErrorIfNotExists);
        ReturnValue := MobToolbox.Text2Boolean(TextValue);
    end;

    internal procedure GetValueAsDate(var _RecRef: RecordRef; _ReferenceKey: Integer; _PathToGet: Text[250]; _FieldNo: Integer; _ErrorIfNotExists: Boolean) ReturnValue: Date
    var
        MobToolbox: Codeunit "MOB Toolbox";
        TextValue: Text;
    begin
        TextValue := GetValue(_RecRef, _ReferenceKey, _PathToGet, _FieldNo, _ErrorIfNotExists);
        ReturnValue := MobToolbox.Text2Date(TextValue);
    end;

    internal procedure GetValueAsDateTime(var _RecRef: RecordRef; _ReferenceKey: Integer; _PathToGet: Text[250]; _FieldNo: Integer; _ErrorIfNotExists: Boolean) ReturnValue: DateTime
    var
        MobToolbox: Codeunit "MOB Toolbox";
        TextValue: Text;
    begin
        TextValue := GetValue(_RecRef, _ReferenceKey, _PathToGet, _FieldNo, _ErrorIfNotExists);
        ReturnValue := MobToolbox.Text2DateTime(TextValue);
    end;

    internal procedure GetValueAsDecimal(var _RecRef: RecordRef; _ReferenceKey: Integer; _PathToGet: Text[250]; _FieldNo: Integer; _ErrorIfNotExists: Boolean) ReturnValue: Decimal
    var
        MobToolbox: Codeunit "MOB Toolbox";
        TextValue: Text;
    begin
        TextValue := GetValue(_RecRef, _ReferenceKey, _PathToGet, _FieldNo, _ErrorIfNotExists);
        ReturnValue := MobToolbox.Text2Decimal(TextValue);
    end;

    internal procedure GetValueAsInteger(var _RecRef: RecordRef; _ReferenceKey: Integer; _PathToGet: Text[250]; _FieldNo: Integer; _ErrorIfNotExists: Boolean) ReturnValue: Integer
    var
        MobToolbox: Codeunit "MOB Toolbox";
        TextValue: Text;
    begin
        TextValue := GetValue(_RecRef, _ReferenceKey, _PathToGet, _FieldNo, _ErrorIfNotExists);
        ReturnValue := MobToolbox.Text2Integer(TextValue);
    end;

    internal procedure DeleteValue(var RecRef: RecordRef; _ReferenceKey: Integer; _PathToDelete: Text[250])
    begin
        if _ReferenceKey = 0 then
            Evaluate(_ReferenceKey, GetValueByFieldNo(RecRef, 1));   // Key = PK

        SetValue(RecRef, _ReferenceKey, _PathToDelete, '', 0);                    // clear field at current element buffer
        NodeValueBufferMgt.DeleteValue(_ReferenceKey, _PathToDelete);         // delete record in underlying NodeValue Buffer table (PKey is foreign ReferenceKey)
    end;

    internal procedure DeleteValues(var RecRef: RecordRef)
    var
        PKey: Integer;
    begin
        Evaluate(PKey, GetValueByFieldNo(RecRef, 1));   // Key = PK
        NodeValueBufferMgt.DeleteValues(PKey);          // delete records in underlying NodeValue Buffer table (PKey is foreign ReferenceKey)
        RecRef.Init();
    end;

    internal procedure SyncronizeTableToBuffer(var RecRef: RecordRef)
    var
        FldRef: FieldRef;
        FldCount: Integer;
        FieldValue: Text;
        PKey: Integer;
        i: Integer;
    begin
        // push table field values to buffer if buffer entries do not exists
        // this ensures all values will exist in the buffer when looped during writing to xml
        Evaluate(PKey, GetValueByFieldNo(RecRef, 1));

        FldCount := RecRef.FieldCount();
        for i := 1 to FldCount do begin
            FldRef := RecRef.FieldIndex(i);
            if (UpperCase(Format(FldRef.Type())) = 'TEXT') and
               (UpperCase(Format(FldRef.Class())) = 'NORMAL') and
               (((FldRef.Number() >= 10) and (FldRef.Number() < 800)) or (FldRef.Number() >= 1000)) and
               (FldRef.Active())
            then begin    // <10 = Primary Key; 800.999 = internal fields
                FieldValue := FldRef.Value();
                if ((FieldValue <> '') and (not NodeValueBufferMgt.Exists(PKey, FldRef.Name()))) then
                    NodeValueBufferMgt.SetValue(PKey, FldRef.Name(), FieldValue, FldRef.Number());
            end;
        end;
    end;

    local procedure FieldName2FieldNo(var _RecRef: RecordRef; _FieldNameToConvert: Text): Integer
    var
        FieldRec: Record Field;
    begin
        if (StrLen(_FieldNameToConvert) > MaxStrLen(FieldRec.FieldName)) then    // FieldNameToConvert too long and cannot be a table field name
            exit(0);

        FieldRec.Reset();
        FieldRec.SetCurrentKey(TableNo, FieldName);
        FieldRec.SetRange(TableNo, _RecRef.Number());
        FieldRec.SetRange(FieldName, _FieldNameToConvert);
        if FieldRec.FindFirst() then
            exit(FieldRec."No.");

        exit(0);
    end;

    local procedure SetValueByFieldNo(var _RecRef: RecordRef; _FieldNo: Integer; _NewValue: Text)
    var
        NewFieldRef: FieldRef;
    begin

        // "Key" field is reserved
        if _FieldNo = 1 then
            Error(PATH_MUST_NOT_BE_KEY_Err);

        NewFieldRef := _RecRef.Field(_FieldNo);
        NewFieldRef.Value(CopyStr(_NewValue, 1, NewFieldRef.Length()));
    end;

    /// <remarks>Redundant code in signatures for better performance</remarks>
    local procedure GetValueByFieldNo(var _RecRef: RecordRef; _FieldNo: Integer): Text
    var
        NewFieldRef: FieldRef;
        ValueText: Text;
    begin
        NewFieldRef := _RecRef.Field(_FieldNo);
        ValueText := Format(NewFieldRef.Value());

        exit(ValueText);
    end;

    /// <remarks>Redundant code in signatures for better performance</remarks>
    local procedure GetValueByFieldNo(var _RecRef: RecordRef; _FieldNo: Integer; var _ReturnDataLength: Integer): Text
    var
        NewFieldRef: FieldRef;
        ValueText: Text;
    begin
        NewFieldRef := _RecRef.Field(_FieldNo);
        ValueText := Format(NewFieldRef.Value());

        Clear(_ReturnDataLength);
        if (UpperCase(Format(NewFieldRef.Type())) = 'TEXT') and
           (UpperCase(Format(NewFieldRef.Class())) = 'NORMAL') and
           (NewFieldRef.Active())
        then
            _ReturnDataLength := NewFieldRef.Length();

        exit(ValueText);
    end;

    internal procedure GetSharedNodeValueBuffer(_ReferenceKey: Integer; var _ToNodeValueBuffer: Record "MOB NodeValue Buffer")
    begin
        NodeValueBufferMgt.GetSharedNodeValueBuffer(_ReferenceKey, _ToNodeValueBuffer);
    end;

}
