table 81303 "MOB ReportParameters Element"
{
    Access = Public;
    Caption = 'MOB ReportParameters Element', Locked = true;

    fields
    {
        field(1; "Key"; Integer)
        {
            Caption = 'Key', Locked = true;
            DataClassification = SystemMetadata;
            AutoIncrement = false;       // Business Central 365 temporary tables not supported
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

    procedure Create()
    var
        RecRef: RecordRef;
    begin
        if not IsTemporary() then
            Error(MUST_BE_TEMPORARY_Err, TableCaption());

        Init();
        Key := 0;

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
    /// <param name="_TempElement">The MOB ReportParameters Element record to autoincrement (must be a temporary record)</param>
    local procedure AutoIncrementKey(var _TempElement: Record "MOB ReportParameters Element")
    var
        TempElement2: Record "MOB ReportParameters Element" temporary;
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

    procedure DeleteValue(_PathToDelete: Text)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Rec);
        NsElementMgt.DeleteValue(RecRef, Rec."Key", _PathToDelete);
        RecRef.SetTable(Rec);
    end;

    local procedure SyncronizeTableToBuffer()
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Rec);
        NsElementMgt.SyncronizeTableToBuffer(RecRef);
        // oneway syncronization from table to buffer hance no return value by SetTable
    end;

    /// <summary>
    /// Delete everything and initialize (Copy) from another ReportParameters Element instance 
    /// </summary>
    procedure InitFromReportParameterElement(var _FromInstance: Record "MOB ReportParameters Element")
    var
        TempNodeValueBuffer: Record "MOB NodeValue Buffer" temporary;
    begin
        _FromInstance.GetSharedNodeValueBuffer(TempNodeValueBuffer);
        if TempNodeValueBuffer.FindSet() then begin
            Clear(Rec); // Delete existing entries
            Create();
            repeat
                SetValue(TempNodeValueBuffer.Path, TempNodeValueBuffer.GetValue());
            until TempNodeValueBuffer.Next() = 0;
        end;
    end;


    // -------------------------
    // Get/Set procedures
    // -------------------------
    procedure SetValue(_PathToSet: Text; _NewValue: Text)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Rec);
        NsElementMgt.SetValue(RecRef, Rec."Key", _PathToSet, _NewValue, 0);
        RecRef.SetTable(Rec);
    end;

    procedure SetValue(_PathToSet: Text; _NewValue: Variant)
    begin
        // All datatypes for the ReportParameters Xml are standard Xml format (unlike ie. Common Element, with would be “ResponseFormat”)
        SetValue(_PathToSet, Format(_NewValue, 0, 9));
    end;

    procedure HasValue(_PathToGet: Text[250]) ReturnHasValue: Boolean
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Rec);
        exit(NsElementMgt.HasValue(RecRef, Rec."Key", _PathToGet));
    end;

    procedure GetValue(_PathToGet: Text): Text
    begin
        // Default behaviour is no error if path not exists
        exit(GetValue(_PathToGet, false));
    end;

    procedure GetValue(_PathToGet: Text; _ErrorIfNotExists: Boolean): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Rec);
        exit(NsElementMgt.GetValue(RecRef, Rec."Key", _PathToGet, 0, _ErrorIfNotExists));
    end;
    /// <summary>
    /// Get value by path as "Date"
    /// </summary>
    procedure GetValueAsDate(_PathToGet: Text[250]; _ErrorIfNotExists: Boolean) _ReturnValue: Date
    begin
        // All datatypes for the ReportParameters Xml are standard Xml format (unlike ie. Common Element, with would be “ResponseFormat”)
        if Evaluate(_ReturnValue, GetValue(_PathToGet, _ErrorIfNotExists), 9) then
            exit(_ReturnValue);
    end;

    /// <summary>
    /// Get value by path as "Date"
    /// </summary>
    procedure GetValueAsDate(_PathToGet: Text[250]): Date
    begin
        exit(GetValueAsDate(_PathToGet, false));
    end;


    /// <summary>
    /// Get value by path as "DateTime"
    /// </summary>
    procedure GetValueAsDateTime(_PathToGet: Text[250]; _ErrorIfNotExists: Boolean) _ReturnValue: DateTime
    begin
        if Evaluate(_ReturnValue, GetValue(_PathToGet, _ErrorIfNotExists), 9) then
            exit(_ReturnValue);
    end;

    /// <summary>
    /// Get value by path as "DateTime"
    /// </summary>
    procedure GetValueAsDateTime(_PathToGet: Text[250]): DateTime
    begin
        exit(GetValueAsDateTime(_PathToGet, false));
    end;

    /// <summary>
    /// Get value by path as "Integer"
    /// </summary>
    procedure GetValueAsInteger(_PathToGet: Text[250]; _ErrorIfNotExists: Boolean) _ReturnValue: Integer
    begin
        if Evaluate(_ReturnValue, GetValue(_PathToGet, _ErrorIfNotExists), 9) then
            exit(_ReturnValue);
    end;

    /// <summary>
    /// Get value by path as "Integer"
    /// </summary>
    procedure GetValueAsInteger(_PathToGet: Text[250]): Integer
    begin
        exit(GetValueAsInteger(_PathToGet, false));
    end;

    /// <summary>
    /// Get value by path as "Decimal"
    /// </summary>
    procedure GetValueAsDecimal(_PathToGet: Text[250]; _ErrorIfNotExists: Boolean) _ReturnValue: Decimal
    begin
        if Evaluate(_ReturnValue, GetValue(_PathToGet, _ErrorIfNotExists), 9) then
            exit(_ReturnValue);
    end;

    /// <summary>
    /// Get value by path as "Decimal"
    /// </summary>
    procedure GetValueAsDecimal(_PathToGet: Text[250]): Decimal
    begin
        exit(GetValueAsDecimal(_PathToGet, false));
    end;

    /// <summary>
    /// Get value by path as "Boolean"
    /// </summary>
    procedure GetValueAsBoolean(_PathToGet: Text[250]) _ReturnValue: Boolean
    begin
        if Evaluate(_ReturnValue, GetValue(_PathToGet), 9) then
            exit(_ReturnValue);
    end;
}
