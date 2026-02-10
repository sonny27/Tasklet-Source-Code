table 81389 "MOB Common Element"
{
    Access = Public;
    Caption = 'MOB Common Element', Locked = true;

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
        MobToolBox: Codeunit "MOB Toolbox";
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
    /// <param name="_TempElement">The MOB Common Element record to autoincrement (must be a temporary record)</param>
    local procedure AutoIncrementKey(var _TempElement: Record "MOB Common Element")
    var
        TempElement2: Record "MOB Common Element" temporary;
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
    /// Delete everything and initialize (Copy) from another Common Element instance 
    /// </summary>
    procedure InitFromCommonElement(var _FromInstance: Record "MOB Common Element")
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

    procedure SetValue(_PathToSet: Text; _NewValue: Decimal)
    var
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
    begin
        SetValue(_PathToSet, MobWmsToolbox.Decimal2TextAsXmlFormat(_NewValue));
    end;

    procedure SetValue(_PathToSet: Text; _NewValue: Integer)
    var
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
    begin
        SetValue(_PathToSet, MobWmsToolbox.Integer2TextAsXmlFormat(_NewValue));
    end;

    // ... Date Format for dates should not be AsXmlFormat, as dates in Mobile WMS is Danish format -- disabled method till it can be reworked
    // procedure SetValue(_PathToSet: Text; _NewValue: Date)
    // var
    //     MobWmsToolbox: Codeunit "MOB WMS Toolbox";
    // begin
    //     SetValue(_PathToSet, MobWmsToolbox.Date2TextAsXmlFormat(_NewValue));
    // end;

    procedure SetValue(_PathToSet: Text; _NewValue: Variant)
    begin
        SetValue(_PathToSet, Format(_NewValue));
    end;

    procedure SetValue(_PathToSet: Text; _NewValue: Boolean)
    var
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
    begin
        SetValue(_PathToSet, MobWmsToolbox.Bool2Text(_NewValue));
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
    procedure GetValueAsDate(_PathToGet: Text[250]; _ErrorIfNotExists: Boolean): Date
    begin
        exit(MobToolBox.Text2Date(GetValue(_PathToGet, _ErrorIfNotExists)));
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
    procedure GetValueAsDateTime(_PathToGet: Text[250]; _ErrorIfNotExists: Boolean): DateTime
    begin
        exit(MobToolBox.Text2DateTime(GetValue(_PathToGet, _ErrorIfNotExists)));
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
        if Evaluate(_ReturnValue, GetValue(_PathToGet, _ErrorIfNotExists)) then
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
        if Evaluate(_ReturnValue, GetValue(_PathToGet, _ErrorIfNotExists)) then
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
        _ReturnValue := MobToolBox.Text2Boolean(GetValue(_PathToGet));
    end;

    // ------------------------
    // Setters from XmlElements
    // ------------------------
    procedure SetValuesFromXmlNodeAttributes(_XmlNode: XmlNode)
    var
        XmlAttributesCol: XmlAttributeCollection;
        XmlAttr: XmlAttribute;
        AttributeName: Text;
        AttributeValue: Text;
        i: Integer;
    begin
        // Extract attributes from the node
        XmlAttributesCol := _XmlNode.AsXmlElement().Attributes();

        for i := 1 to XmlAttributesCol.Count() do begin
            XmlAttributesCol.Get(i, XmlAttr);
            AttributeName := XmlAttr.Name();
            AttributeValue := XmlAttr.Value();
            SetValue(AttributeName, AttributeValue);
        end;
    end;


}
