table 81394 "MOB NS Request Element"
{
    Access = Public;
    Caption = 'MOB NS Request Element', Locked = true;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(20; "Attached To Entry No."; Integer)
        {
            // Not used
            Caption = 'Attached To Entry No.', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(100; Name; Text[250])
        {
            Caption = 'Name', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(110; "Value"; Text[250])
        {
            Caption = 'Value', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(130; "Value BLOB"; Blob)
        {
            // Not used
            Caption = 'Value BLOB', Locked = true;
            DataClassification = SystemMetadata;
            ObsoleteReason = 'Not used in Mobile WMS (table always used as temporary table. Long values for SetValue/GetValue are handled internally by NsRequestMgt)';
            ObsoleteState = Removed;
            ObsoleteTag = '5.35';
        }
    }

    keys
    {
        key(EntryNo; "Entry No.") { }
        key(AttachedToEntryNo; "Attached To Entry No.") { }
    }

    var
        MobToolbox: Codeunit "MOB Toolbox";
        NsElementMgt: Codeunit "MOB NS Element Management";
        MobNsRequestMgt: Codeunit "MOB NS Request Management";
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
        GlobalXmlRequestDoc: XmlDocument; // For Adhoc Requests only -- using internal variable rather than new field due to Request Element being implemented with new record for each value
        ThereIsNoNSRequestElementErr: Label 'GetValueByName(): There is no MOB NS Request Element with the Name: %1', Locked = true;
        MUST_BE_TEMPORARY_Err: Label 'Internal error: %1 must be a temporary record.', Locked = true;

    trigger OnDelete()
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Rec);
        NsElementMgt.DeleteValues(RecRef); // Doesn't work if called through DeleteAll. Handled in Create procedure
    end;

    /// <summary>
    /// Clear only the current record values, keeping global vars and temporary records
    /// </summary>
    procedure ClearFields()
    var
        MobNsRequestElement: Record "MOB NS Request Element";
    begin
        // Transfers empty values to the current record
        Rec.TransferFields(MobNsRequestElement);
    end;

    procedure InsertElement(_FilterName: Text; _FilterValue: Text)
    begin
        Rec.Create();
        Rec.Name := CopyStr(_FilterName, 1, MaxStrLen(Name));
        Rec."Value" := CopyStr(_FilterValue, 1, MaxStrLen("Value"));    // Populate value in record returned from this method for backwards compatibility
        Rec.Modify();

        SetValue(_FilterName, _FilterValue);    // Populate value in NsElementMgt to support values > 250 characters
    end;

    //
    // ------------------------------------------ MISC ------------------------------------------
    //

    /// <summary>
    /// Autoincrement primary key "Entry No." since Autoincrement table property is not supported for BC temporary tables in cloud, hence implemented programmatically
    /// </summary>
    /// <param name="_TempElement">The NS Request Element record to autoincrement (must be a temporary record)</param>
    local procedure AutoIncrementKey(var _TempElement: Record "MOB NS Request Element")
    var
        TempElement2: Record "MOB NS Request Element" temporary;
        NextEntryNo: Integer;
    begin
        if ("Entry No." = 0) then begin
            if not _TempElement.IsTemporary() then
                Error(MUST_BE_TEMPORARY_Err, _TempElement.TableCaption());  // Avoid error on Copy below

            TempElement2.Copy(_TempElement, true); // ShareTable=true
            TempElement2.Reset();   // All FilterGroups

            if TempElement2.FindLast() then
                NextEntryNo := TempElement2."Entry No." + 1
            else
                NextEntryNo := 1;

            _TempElement."Entry No." := NextEntryNo;
        end;
    end;

    /// <summary>
    /// Prepare current record to be used for buffer. Will populate Key and insert into DB. Method should always be called prior to calling Set-/Get-methods.
    /// </summary>
    /// <remarks>
    /// This initialization is needed, since buffer requires a Reference Key but autoincremented keys are not supported for Business Central 365 temporary tables.
    /// </remarks>
    procedure Create(var _XmlRequestDoc: XmlDocument)
    var
        RecRef: RecordRef;
    begin
        Init();
        "Entry No." := 0;

        AutoIncrementKey(Rec);
        Insert();

        // Make sure all existing values in Mob Node Value Buffer is cleared. Values may hang if step was deleted with DeleteAll
        RecRef.GetTable(Rec);
        NsElementMgt.DeleteValues(RecRef);
    end;

    /// <summary>
    /// Prepare current record to be used for buffer. Will populate Key and insert into DB. Method should always be called prior to calling Set-/Get-methods.
    /// </summary>
    /// <remarks>
    /// This initialization is needed, since buffer requires a Reference Key but autoincremented keys are not supported for Business Central 365 temporary tables.
    /// </remarks>
    procedure Create()
    var
        RecRef: RecordRef;
    begin
        Init();
        "Entry No." := 0;

        AutoIncrementKey(Rec);
        Insert();

        // Make sure all existing values in Mob Node Value Buffer is cleared. Values may hang if step was deleted with DeleteAll
        RecRef.GetTable(Rec);
        NsElementMgt.DeleteValues(RecRef);
    end;

    //
    // ------------------------------------------ SET and GET ------------------------------------------
    //

    /// <summary>
    /// Transfer all values from a Common Element
    /// </summary>
    procedure InitFromCommonElement(var _TempOrderValues: Record "MOB Common Element")
    var
        TempNodeValueBuffer: Record "MOB NodeValue Buffer" temporary;
    begin
        _TempOrderValues.GetSharedNodeValueBuffer(TempNodeValueBuffer);
        if TempNodeValueBuffer.FindSet() then
            repeat
                InsertElement(TempNodeValueBuffer.Path, TempNodeValueBuffer.GetValue());
            until TempNodeValueBuffer.Next() = 0;
    end;

    /// <summary>
    /// Transfer all values from another Request Elements instance (clone RequestValues)
    /// </summary>
    internal procedure InitFromRequestValues(var _RequestValues: Record "MOB NS Request Element")
    begin
        if _RequestValues.FindSet() then
            repeat
                InsertElement(_RequestValues.Name, _RequestValues.GetValue());
            until _RequestValues.Next() = 0;
    end;

    procedure SetValue(_Name: Text[250]; _NewValue: Text)
    var
        xElement: Record "MOB NS Request Element";
    begin
        xElement.Copy(Rec);
        SetValueByName(_Name, _NewValue);
        Rec.Copy(xElement);
    end;

    local procedure SetValueByName(_Name: Text[250]; _NewValue: Text)
    var
        RecRef: RecordRef;
        xView: Text;
        IsFound: Boolean;
    begin
        xView := Rec.GetView();
        Rec.SetRange(Name, _Name);

        if Rec.Name = _Name then
            IsFound := true    // Already at correct record -- needed for events with no-var _RequestElements that can not search table
        else
            IsFound := Rec.FindFirst();

        if not IsFound then
            Rec.Create();

        Rec.Name := _Name;
        Rec."Value" := CopyStr(_NewValue, 1, MaxStrLen(Rec."Value"));
        Rec.Modify();
        RecRef.GetTable(Rec);
        NsElementMgt.SetValue(RecRef, Rec."Entry No.", _Name, _NewValue, 0);    // "Entry No." is ReferenceKey

        Rec.SetView(xView);
    end;

    /// <summary>
    /// Has a value been set for the path (do node exist in Xml)
    /// </summary>
    procedure HasValue(_PathToGet: Text[250]) ReturnHasValue: Boolean
    var
        xElement: Record "MOB NS Request Element";
        DummyReturnValue: Text;
    begin
        xElement.Copy(Rec);
        ReturnHasValue := GetValueByName(_PathToGet, DummyReturnValue, false);
        Rec.Copy(xElement);
        exit(ReturnHasValue);
    end;

    /// <summary>
    /// Get value by path as "Boolean"
    /// </summary>
    procedure GetValueAsBoolean(_PathToGet: Text[250]; _ErrorIfNotExists: Boolean): Boolean
    begin
        exit(MobToolbox.Text2Boolean(GetValue(_PathToGet, _ErrorIfNotExists)));
    end;

    /// <summary>
    /// Get value by path as "Boolean"
    /// </summary>
    procedure GetValueAsBoolean(_PathToGet: Text[250]): Boolean
    begin
        exit(GetValueAsBoolean(_PathToGet, false));
    end;

    /// <summary>
    /// Get current record in buffer as "Boolean"
    /// </summary>
    procedure GetValueAsBoolean() _ReturnValue: Boolean
    begin
        exit(GetValueAsBoolean(Rec.Name, false));
    end;

    /// <summary>
    /// Get value by path as "Date"
    /// </summary>
    procedure GetValueAsDate(_PathToGet: Text[250]; _ErrorIfNotExists: Boolean): Date
    begin
        exit(MobToolbox.Text2Date(GetValue(_PathToGet, _ErrorIfNotExists)));
    end;

    /// <summary>
    /// Get value by path as "Date"
    /// </summary>
    procedure GetValueAsDate(_PathToGet: Text[250]): Date
    begin
        exit(GetValueAsDate(_PathToGet, false));
    end;

    /// <summary>
    /// Get current record in buffer as "Date"
    /// </summary>
    procedure GetValueAsDate(): Date
    begin
        exit(GetValueAsDate(Rec.Name, false));
    end;

    /// <summary>
    /// Get value by path as "DateTime"
    /// </summary>
    procedure GetValueAsDateTime(_PathToGet: Text[250]; _ErrorIfNotExists: Boolean): DateTime
    begin
        exit(MobToolbox.Text2DateTime(GetValue(_PathToGet, _ErrorIfNotExists)));
    end;

    /// <summary>
    /// Get value by path as "DateTime"
    /// </summary>
    procedure GetValueAsDateTime(_PathToGet: Text[250]): DateTime
    begin
        exit(GetValueAsDateTime(_PathToGet, false));
    end;

    /// <summary>
    /// Get current record in buffer as "DateTime"
    /// </summary>
    procedure GetValueAsDateTime(): DateTime
    begin
        exit(GetValueAsDateTime(Rec.Name, false));
    end;

    /// <summary>
    /// Get value by path as "Integer"
    /// </summary>
    procedure GetValueAsInteger(_PathToGet: Text[250]; _ErrorIfNotExists: Boolean): Integer
    begin
        exit(MobToolbox.Text2Integer(GetValue(_PathToGet, _ErrorIfNotExists)));
    end;

    /// <summary>
    /// Get value by path as "Integer"
    /// </summary>
    procedure GetValueAsInteger(_PathToGet: Text[250]): Integer
    begin
        exit(GetValueAsInteger(_PathToGet, false));
    end;

    /// <summary>
    /// Get current record in buffer as "Integer"
    /// </summary>
    procedure GetValueAsInteger() _ReturnValue: Integer
    begin
        exit(GetValueAsInteger(Rec.Name, false));
    end;

    /// <summary>
    /// Get value by path as "Decimal"
    /// </summary>
    procedure GetValueAsDecimal(_PathToGet: Text[250]; _ErrorIfNotExists: Boolean): Decimal
    begin
        exit(MobToolbox.Text2Decimal(GetValue(_PathToGet, _ErrorIfNotExists)));
    end;

    /// <summary>
    /// Get value by path as "Decimal"
    /// </summary>
    procedure GetValueAsDecimal(_PathToGet: Text[250]): Decimal
    begin
        exit(GetValueAsDecimal(_PathToGet, false));
    end;

    /// <summary>
    /// Get current record in buffer as "Decimal"
    /// </summary>
    procedure GetValueAsDecimal(): Decimal
    begin
        exit(GetValueAsDecimal(Rec.Name, false));
    end;

    procedure GetValue(_PathToGet: Text[250]; _ErrorIfNotExists: Boolean) _RetVal: Text
    var
        xElement: Record "MOB NS Request Element";
    begin
        xElement.Copy(Rec);
        GetValueByName(_PathToGet, _RetVal, _ErrorIfNotExists);
        Rec.Copy(xElement);
    end;

    procedure GetValue(_PathToGet: Text[250]): Text
    begin
        exit(GetValue(_PathToGet, false));
    end;

    procedure GetValue(): Text
    begin
        exit(GetValue(Name));
    end;

    local procedure GetValueByName(_Name: Text[250]; var _ReturnValue: Text; _ErrorIfNotExists: Boolean) _IsFound: Boolean
    var
        RecRef: RecordRef;
        xView: Text;
    begin
        xView := Rec.GetView();
        Rec.SetRange(Name, _Name);

        if Rec.Name = _Name then
            _IsFound := true    // Already at correct record -- needed for events with no-var _RequestElements that can not search table
        else
            _IsFound := Rec.FindFirst();

        if _IsFound then begin
            RecRef.GetTable(Rec);
            _ReturnValue := NsElementMgt.GetValue(RecRef, Rec."Entry No.", _Name, 0);   // "Entry No." is ReferenceKey
            if _ReturnValue = '' then
                _ReturnValue := Value;  // HeaderFilter as a non-Var parameter do not support GetValue from BLOB -- fallback to the first 250 characters stored in Value-field
        end
        else begin
            if _ErrorIfNotExists then
                Error(ThereIsNoNSRequestElementErr, _Name);

            _ReturnValue := '';

            // Not found (do not use Clear due to internal GlobalXmlDocument)
            Rec.Init();
            Rec."Entry No." := 0;
        end;

        Rec.SetView(xView);
        exit(_IsFound);
    end;

    /// <summary>
    /// Gets value of a path
    /// If empty will fallback to search for path in "ContextValues" (the previous Order, Line, Lookup or Page)
    /// </summary>
    procedure GetValueOrContextValue(_PathToGet: Text[250]; _ErrorIfNotExists: Boolean) _RetVal: Text
    var
        xElement: Record "MOB NS Request Element";
    begin
        xElement.Copy(Rec);
        GetValueOrContextValueByName(_PathToGet, _RetVal, _ErrorIfNotExists);
        Rec.Copy(xElement);
    end;

    /// <summary>
    /// Gets value of a path
    /// If empty will fallback to search for path in "ContextValues" (the previous Order, Line, Lookup or Page)
    /// </summary>
    procedure GetValueOrContextValue(_PathToGet: Text[250]): Text
    begin
        exit(GetValueOrContextValue(_PathToGet, false));
    end;

    /// <summary>
    /// Gets value of a path
    /// If empty will fallback to search for path in "ContextValues" (the previous Order, Line, Lookup or Page)
    /// </summary>
    local procedure GetValueOrContextValueByName(_Name: Text[250]; var _ReturnValue: Text; _ErrorIfNotExists: Boolean) _IsFound: Boolean
    var
        xView: Text;
    begin
        xView := Rec.GetView();
        SetRange(Name, _Name);

        _IsFound := Rec.FindFirst();
        if _IsFound then
            _ReturnValue := Rec.Value
        else
            _ReturnValue := GetContextValue(_Name, _IsFound, _ErrorIfNotExists);     // Fallback to ContextValues if value is not found in RequestData-element

        if not _IsFound then begin
            if _ErrorIfNotExists then
                FindFirst();    // Intentionally throw error

            _ReturnValue := '';

            // Not found (do not use Clear due to internal GlobalXmlDocument)
            Rec.Init();
            Rec."Entry No." := 0;
        end;

        SetView(xView);
        exit(_IsFound);
    end;

    /// <summary>
    /// Gets value of a path
    /// If empty will fallback to search for path in "ContextValues" (the previous Order, Line, Lookup or Page)
    /// </summary>
    procedure GetValueOrContextValueAsBoolean(_PathToGet: Text[250]; _ErrorIfNotFound: Boolean): Boolean
    begin
        exit(MobToolbox.Text2Boolean(GetValueOrContextValue(_PathToGet, _ErrorIfNotFound)));
    end;

    /// <summary>
    /// Gets value of a path
    /// If empty will fallback to search for path in "ContextValues" (the previous Order, Line, Lookup or Page)
    /// </summary>
    procedure GetValueOrContextValueAsBoolean(_PathToGet: Text[250]): Boolean
    begin
        exit(GetValueOrContextValueAsBoolean(_PathToGet, false));
    end;

    /// <summary>
    /// Gets value of a path as "Date"
    /// If empty will fallback to search for path in "ContextValues" (the previous Order, Line, Lookup or Page)
    /// </summary>
    procedure GetValueOrContextValueAsDate(_PathToGet: Text[250]; _ErrorIfNotFound: Boolean): Date
    begin
        exit(MobToolbox.Text2Date(GetValueOrContextValue(_PathToGet, _ErrorIfNotFound)));
    end;

    /// <summary>
    /// Gets value of a path as "Date"
    /// If empty will fallback to search for path in "ContextValues" (the previous Order, Line, Lookup or Page)
    /// </summary>
    procedure GetValueOrContextValueAsDate(_PathToGet: Text[250]): Date
    begin
        exit(GetValueOrContextValueAsDate(_PathToGet, false));
    end;

    /// <summary>
    /// Gets value of a path as "DateTime"
    /// If empty will fallback to search for path in "ContextValues" (the previous Order, Line, Lookup or Page)
    /// </summary>
    procedure GetValueOrContextValueAsDateTime(_PathToGet: Text[250]; _ErrorIfNotFound: Boolean): DateTime
    begin
        exit(MobToolbox.Text2DateTime(GetValueOrContextValue(_PathToGet, _ErrorIfNotFound)));
    end;

    /// <summary>
    /// Gets value of a path as "DateTime"
    /// If empty will fallback to search for path in "ContextValues" (the previous Order, Line, Lookup or Page)
    /// </summary>
    procedure GetValueOrContextValueAsDateTime(_PathToGet: Text[250]): DateTime
    begin
        exit(GetValueOrContextValueAsDateTime(_PathToGet, false));
    end;

    /// <summary>
    /// Gets value of a path as "Integer"
    /// If empty will fallback to search for path in "ContextValues" (the previous Order, Line, Lookup or Page)
    /// </summary>
    procedure GetValueOrContextValueAsInteger(_PathToGet: Text[250]; _ErrorIfNotFound: Boolean): Integer
    begin
        exit(MobToolbox.Text2Integer(GetValueOrContextValue(_PathToGet, _ErrorIfNotFound)));
    end;

    /// <summary>
    /// Gets value of a path as "Integer"
    /// If empty will fallback to search for path in "ContextValues" (the previous Order, Line, Lookup or Page)
    /// </summary>
    procedure GetValueOrContextValueAsInteger(_PathToGet: Text[250]): Integer
    begin
        exit(GetValueOrContextValueAsInteger(_PathToGet, false));
    end;

    /// <summary>
    /// Gets value of a path as "Decimal"
    /// If empty will fallback to search for path in "ContextValues" (the previous Order, Line, Lookup or Page)
    /// </summary>
    procedure GetValueOrContextValueAsDecimal(_PathToGet: Text[250]; _ErrorIfNotFound: Boolean): Decimal
    begin
        exit(MobToolbox.Text2Decimal(GetValueOrContextValue(_PathToGet, _ErrorIfNotFound)));
    end;

    /// <summary>
    /// Gets value of a path as "Decimal"
    /// If empty will fallback to search for path in "ContextValues" (the previous Order, Line, Lookup or Page)
    /// </summary>
    procedure GetValueOrContextValueAsDecimal(_PathToGet: Text[250]): Decimal
    begin
        exit(GetValueOrContextValueAsDecimal(_PathToGet, false));
    end;

    /// <summary>
    /// Gets value of a path in "ContextValues" (the previous Order, Line, Lookup or Page)
    /// </summary>
    procedure GetContextValue(_PathToGet: Text[250]; var _IsFound: Boolean; _ErrorIfNotExists: Boolean) _RetVal: Text
    var
        MobXmlMgt: Codeunit "MOB XML Management";
        XmlValueNode: XmlNode;
        XPath: Text;
    begin
        XPath := '//req:request/req:requestData/req:ContextValues/req:' + _PathToGet; // Assuming Adhoc Request Xml format
        if not MobXmlMgt.XPathFound(GlobalXmlRequestDoc, XPath) then begin
            _IsFound := false;
            if _ErrorIfNotExists then
                Rec.GetValue('ContextValues/' + _PathToGet, true);   // Intentionally throw error using an invalid node name (values not saved as path 'ContextValues/')

            exit('');
        end;

        _IsFound := MobXmlMgt.GetXPathNode(GlobalXmlRequestDoc, XPath, XmlValueNode);
        exit(MobXmlMgt.GetNodeInnerText(XmlValueNode));
    end;

    /// <summary>
    /// Gets value of a path in "ContextValues" (the previous Order, Line, Lookup or Page)
    /// </summary>
    procedure GetContextValue(_PathToGet: Text[250]; _ErrorIfNotFound: Boolean): Text
    var
        DummyIsFound: Boolean;
    begin
        exit(GetContextValue(_PathToGet, DummyIsFound, _ErrorIfNotFound));
    end;

    /// <summary>
    /// Gets value of a path in "ContextValues" (the previous Order, Line, Lookup or Page)
    /// </summary>
    procedure GetContextValue(_PathToGet: Text[250]): Text
    begin
        exit(GetContextValue(_PathToGet, false));
    end;

    /// <summary>
    /// Gets value as "Boolean" of a path in "ContextValues" (the previous Order, Line, Lookup or Page)
    /// </summary>
    procedure GetContextValueAsBoolean(_PathToGet: Text[250]; _ErrorIfNotFound: Boolean): Boolean
    begin
        exit(MobToolbox.Text2Boolean(GetContextValue(_PathToGet, _ErrorIfNotFound)));
    end;

    /// <summary>
    /// Gets value as "Boolean" of a path in "ContextValues" (the previous Order, Line, Lookup or Page)
    /// </summary>
    procedure GetContextValueAsBoolean(_PathToGet: Text[250]): Boolean
    begin
        exit(GetContextValueAsBoolean(_PathToGet, false));
    end;

    /// <summary>
    /// Gets value as "Date" of a path in "ContextValues" (the previous Order, Line, Lookup or Page)
    /// </summary>
    procedure GetContextValueAsDate(_PathToGet: Text[250]; _ErrorIfNotFound: Boolean): Date
    begin
        exit(MobToolbox.Text2Date(GetContextValue(_PathToGet, _ErrorIfNotFound)));
    end;

    /// <summary>
    /// Gets value as "Date" of a path in "ContextValues" (the previous Order, Line, Lookup or Page)
    /// </summary>
    procedure GetContextValueAsDate(_PathToGet: Text[250]): Date
    begin
        exit(GetContextValueAsDate(_PathToGet, false));
    end;

    /// <summary>
    /// Gets value as "DateTime" of a path in "ContextValues" (the previous Order, Line, Lookup or Page)
    /// </summary>
    procedure GetContextValueAsDateTime(_PathToGet: Text[250]; _ErrorIfNotFound: Boolean): DateTime
    begin
        exit(MobToolbox.Text2DateTime(GetContextValue(_PathToGet, _ErrorIfNotFound)));
    end;

    /// <summary>
    /// Gets value as "DateTime" of a path in "ContextValues" (the previous Order, Line, Lookup or Page)
    /// </summary>
    procedure GetContextValueAsDateTime(_PathToGet: Text[250]): DateTime
    begin
        exit(GetContextValueAsDateTime(_PathToGet, false));
    end;

    /// <summary>
    /// Gets value as "Integer" of a path in "ContextValues" (the previous Order, Line, Lookup or Page)
    /// </summary>
    procedure GetContextValueAsInteger(_PathToGet: Text[250]; _ErrorIfNotFound: Boolean): Integer
    begin
        exit(MobToolbox.Text2Integer(GetContextValue(_PathToGet, _ErrorIfNotFound)));
    end;

    /// <summary>
    /// Gets value as "Integer" of a path in "ContextValues" (the previous Order, Line, Lookup or Page)
    /// </summary>
    procedure GetContextValueAsInteger(_PathToGet: Text[250]): Integer
    begin
        exit(GetContextValueAsInteger(_PathToGet, false));
    end;

    /// <summary>
    /// Gets value as "Decimal" of a path in "ContextValues" (the previous Order, Line, Lookup or Page)
    /// </summary>
    procedure GetContextValueAsDecimal(_PathToGet: Text[250]; _ErrorIfNotFound: Boolean): Decimal
    begin
        exit(MobToolbox.Text2Decimal(GetContextValue(_PathToGet, _ErrorIfNotFound)));
    end;

    /// <summary>
    /// Gets value as "Decimal" of a path in "ContextValues" (the previous Order, Line, Lookup or Page)
    /// </summary>
    procedure GetContextValueAsDecimal(_PathToGet: Text[250]): Decimal
    begin
        exit(GetContextValueAsDecimal(_PathToGet, false));
    end;

    /// <summary>
    /// Internal use (set internal global XmlRequestDoc used for accessing ContextValues)
    /// </summary>
    procedure SetXmlRequestDocument(var _XmlRequestDoc: XmlDocument)
    begin
        GlobalXmlRequestDoc := _XmlRequestDoc;
    end;

    /// <summary>
    /// Internal use (get internal global XmlRequestDoc used for accessing ContextValues)
    /// </summary>
    procedure GetXmlRequestDocument(var _XmlRequestDoc: XmlDocument)
    begin
        _XmlRequestDoc := GlobalXmlRequestDoc
    end;

    //
    // Get-method for Fields Library: Templates
    //

    /// <remarks>
    /// From DataTable -> return type is Text
    /// MaxLen for non-table data: 'MineAndUnassigned' (17)
    /// </remarks>
    procedure Get_AssignedUser(_ErrorIfNotExists: Boolean) _AssignedUser: Text[50]
    begin
        Evaluate(_AssignedUser, GetValue('AssignedUser', _ErrorIfNotExists));
    end;

    procedure Get_AssignedUser(): Text[50]
    begin
        exit(Get_AssignedUser(false));
    end;

    /// <remarks>
    /// Support different casing of NodeName used in planned functions and OnlineValidation
    /// </remarks>
    procedure Get_BackendID(_ErrorIfNotExists: Boolean) _BackendID: Text
    begin
        if HasValue('BackendID') then
            Evaluate(_BackendID, GetValue('BackendID'))
        else
            Evaluate(_BackendID, GetValue('backendId', _ErrorIfNotExists));
    end;

    procedure Get_BackendID(): Text
    begin
        exit(Get_BackendID(false));
    end;

    /// <remarks>
    /// Bin.Code = Code[20]
    /// Item.ShelfNo = Code[10]
    /// Support different casing of NodeName used in planned functions and OnlineValidation
    /// </remarks>    
    procedure Get_Bin(_ErrorIfNotExists: Boolean) _Bin: Code[20]
    var
    begin
        if HasValue('bin') then
            Evaluate(_Bin, GetValue('bin'))
        else
            Evaluate(_Bin, GetValue('Bin', _ErrorIfNotExists));
    end;

    procedure Get_Bin(): Code[20]
    begin
        exit(Get_Bin(false));
    end;

    procedure Get_Date(_ErrorIfNotExists: Boolean): Date
    begin
        exit(GetValueAsDate('Date', _ErrorIfNotExists));
    end;

    procedure Get_Date(): Date
    begin
        exit(Get_Date(false));
    end;

    procedure Get_ExpirationDate(_ErrorIfNotExists: Boolean): Date
    begin
        exit(GetValueAsDate('ExpirationDate', _ErrorIfNotExists));
    end;

    procedure Get_ExpirationDate(): Date
    begin
        exit(Get_ExpirationDate(false));
    end;

    /// <remarks>
    /// From DataTable -> return type is Text
    /// MaxLen for non-table data: 'All' (3)
    /// </remarks>
    procedure Get_FilterLocation(_ErrorIfNotExists: Boolean) _FilterLocation: Text[10]
    begin
        Evaluate(_FilterLocation, GetValue('FilterLocation', _ErrorIfNotExists));
    end;

    procedure Get_FilterLocation(): Text[10]
    begin
        exit(Get_FilterLocation(false));
    end;

    /// <remarks>
    /// Bin.Code = Code[20]
    /// Item.ShelfNo = Code[10]
    /// </remarks>
    procedure Get_FromBin(_ErrorIfNotExists: Boolean) _FromBin: Code[20]
    begin

        Evaluate(_FromBin, GetValue('FromBin', _ErrorIfNotExists));
    end;

    procedure Get_FromBin(): Code[20]
    begin
        exit(Get_FromBin(false));
    end;

    /// <summary>
    /// Get either From Bin or From License Plate dependent on usage context
    /// </summary>    
    procedure Get_FromBinOrLP(_ErrorIfNotExists: Boolean) _FromBinOrLP: Code[20]
    begin

        Evaluate(_FromBinOrLP, GetValue('FromBinOrLP', _ErrorIfNotExists));
    end;

    procedure Get_FromBinOrLP(): Code[20]
    begin
        exit(Get_FromBinOrLP(false));
    end;

    /// <summary>
    /// Get either To Bin or To License Plate dependent on usage context
    /// </summary>    
    procedure Get_ToBinOrLP(_ErrorIfNotExists: Boolean) _FromBinOrLP: Code[20]
    begin

        Evaluate(_FromBinOrLP, GetValue('ToBinOrLP', _ErrorIfNotExists));
    end;

    procedure Get_ToBinOrLP(): Code[20]
    begin
        exit(Get_ToBinOrLP(false));
    end;

    /// <remarks>
    /// Support different casing of NodeName used in planned functions and OnlineValidation
    /// </remarks>
    procedure Get_Force(): Boolean
    begin
        if HasValue('force') then
            exit(GetValueAsBoolean('force'))
        else
            exit(GetValueAsBoolean('Force'));
    end;

    procedure Get_Item(_ErrorIfNotExists: Boolean) _Item: Code[20]
    begin
        Evaluate(_Item, GetValue('Item', _ErrorIfNotExists));
    end;

    procedure Get_Item(): Code[20]
    begin
        exit(Get_Item(false));
    end;

    /// <remarks>
    /// From DataTable -> return type is Text
    /// MaxLen for non-table data: None
    /// </remarks>
    procedure Get_ItemCategory(_ErrorIfNotExists: Boolean) _ItemCategory: Text[20]
    begin
        Evaluate(_ItemCategory, GetValue('ItemCategory', _ErrorIfNotExists));
    end;

    procedure Get_ItemCategory(): Text[20]
    begin
        exit(Get_ItemCategory(false));
    end;

    procedure Get_ItemDescription(_ErrorIfNotExists: Boolean) _ItemDescription: Text[100]
    begin
        Evaluate(_ItemDescription, GetValue('ItemDescription', _ErrorIfNotExists));
    end;

    procedure Get_ItemDescription(): Text[100]
    begin
        exit(Get_ItemDescription(false));
    end;

    procedure Get_ItemNo(_ErrorIfNotExists: Boolean) _ItemNo: Code[20]
    begin
        Evaluate(_ItemNo, GetValue('ItemNo', _ErrorIfNotExists));
    end;

    procedure Get_ItemNo(): Code[20]
    begin
        exit(Get_ItemNo(false));
    end;

    /// <remarks>
    /// Support different casing of NodeName used in planned functions and OnlineValidation
    /// </remarks>
    procedure Get_ItemNumber(_ErrorIfNotExists: Boolean) _ItemNumber: Code[20]
    begin
        if HasValue('itemNumber') then
            Evaluate(_ItemNumber, GetValue('itemNumber'))
        else
            Evaluate(_ItemNumber, GetValue('ItemNumber', _ErrorIfNotExists));
    end;

    procedure Get_ItemNumber(): Code[20]
    begin
        exit(Get_ItemNumber(false));
    end;

    /// <summary>
    /// Number can represent either Item No. or License Plate No. dependent on usage context
    /// </summary>    
    procedure Get_Number(_ErrorIfNotExists: Boolean) _No: Code[20]
    begin
        Evaluate(_No, GetValue('Number', _ErrorIfNotExists));
    end;

    procedure Get_Number(): Code[20]
    begin
        exit(Get_Number(false));
    end;

    /// <remarks>
    /// From DataTable -> return type is Text
    /// MaxLen for non-table data: 'All' (3)
    /// </remarks>
    procedure Get_Location(_ErrorIfNotExists: Boolean) _Location: Text[10]
    begin
        Evaluate(_Location, GetValue('Location', _ErrorIfNotExists));
    end;

    procedure Get_Location(): Text[10]
    begin
        exit(Get_Location(false));
    end;

    /// <remarks>
    /// From DataTable -> return type is Text
    /// MaxLen for non-table data: 'All' (3)
    /// </remarks>
    procedure Get_LocationFilter(_ErrorIfNotExists: Boolean) _LocationFilter: Text[10]
    begin
        Evaluate(_LocationFilter, GetValue('LocationFilter', _ErrorIfNotExists));
    end;

    procedure Get_LocationFilter(): Text[10]
    begin
        exit(Get_LocationFilter(false));
    end;

    /// <remarks>
    /// Support different casing of NodeName used in planned functions and OnlineValidation
    /// </remarks>
    procedure Get_LotNumber(_ErrorIfNotExists: Boolean) _LotNumber: Code[50]
    begin
        if HasValue('lotNumber') then
            Evaluate(_LotNumber, GetValue('lotNumber'))
        else
            Evaluate(_LotNumber, GetValue('LotNumber', _ErrorIfNotExists));
    end;

    procedure Get_LotNumber(): Code[50]
    begin
        exit(Get_LotNumber(false));
    end;

    /// <remarks>
    /// Support different casing of NodeName used in planned functions and OnlineValidation
    /// </remarks>
    procedure Get_SerialNumber(_ErrorIfNotExists: Boolean) _SerialNumber: Text
    begin
        if HasValue('serialNumber') then
            Evaluate(_SerialNumber, GetValue('serialNumber'))
        else
            Evaluate(_SerialNumber, GetValue('SerialNumber', _ErrorIfNotExists));
    end;

    procedure Get_SerialNumber(): Text
    begin
        exit(Get_SerialNumber(false));
    end;

    procedure Get_LicensePlate(_ErrorIfNotExists: Boolean) _LicensePlate: Code[20]
    begin
        Evaluate(_LicensePlate, GetValue('LicensePlate', _ErrorIfNotExists));
    end;

    procedure Get_LicensePlate(): Code[20]
    begin
        exit(Get_LicensePlate(false));
    end;

    /// <remarks>
    /// Support different casing of NodeName used in planned functions and OnlineValidation
    /// </remarks>
    procedure Get_OrderBackendID(_ErrorIfNotExists: Boolean) _OrderBackendID: Text
    begin
        if HasValue('orderBackendID') then
            Evaluate(_OrderBackendID, GetValue('orderBackendID'))
        else
            if HasValue('OrderBackendID') then
                Evaluate(_OrderBackendID, GetValue('OrderBackendID'))
            else
                Evaluate(_OrderBackendID, GetValue('orderBackendId', _ErrorIfNotExists))
    end;

    procedure Get_OrderBackendID(): Text
    begin
        exit(Get_OrderBackendID(false));
    end;

    /// <remarks>
    /// Support different casing of NodeName used in planned functions and OnlineValidation
    /// </remarks>
    procedure Get_OrderType(_ErrorIfNotExists: Boolean) _OrderType: Text
    begin
        if HasValue('orderType') then
            Evaluate(_OrderType, GetValue('orderType'))
        else
            Evaluate(_OrderType, GetValue('OrderType', _ErrorIfNotExists));
    end;

    procedure Get_OrderType() _OrderType: Text
    begin
        exit(Get_OrderType(false));
    end;

    procedure Get_PurchaseOrderNumber(_ErrorIfNotExists: Boolean) _PurchaseOrderNumber: Code[20]
    begin
        Evaluate(_PurchaseOrderNumber, GetValue('PurchaseOrderNumber', _ErrorIfNotExists));
    end;

    /// <remarks>
    /// Support different casing of NodeName used in planned functions and OnlineValidation
    /// </remarks>
    procedure Get_LineNumber(_ErrorIfNotExists: Boolean) _LineNumber: Text
    begin
        if HasValue('lineNumber') then
            Evaluate(_LineNumber, GetValue('lineNumber'))
        else
            Evaluate(_LineNumber, GetValue('LineNumber', _ErrorIfNotExists));
    end;

    procedure Get_LineNumber(): Text
    begin
        exit(Get_LineNumber(false))
    end;

    /// <summary>
    /// Get_LineNumberAsInteger returns the lineNumber as integer and removes the prefix/ suffix in some cases
    /// </summary>
    procedure Get_LineNumberAsInteger(): Integer
    begin
        exit(MobWmsToolbox.EvaluateLineNumber(Get_OrderBackendID(), Get_LineNumber()));
    end;

    procedure Get_PurchaseOrderNumber(): Code[20]
    begin
        exit(Get_PurchaseOrderNumber(false));
    end;

    /// <remarks>
    /// Support different casing of NodeName used in planned functions and OnlineValidation
    /// </remarks>
    procedure Get_Quantity(_ErrorIfNotExists: Boolean) _Quantity: Decimal
    begin
        if HasValue('quantity') then
            _Quantity := GetValueAsDecimal('quantity')
        else
            _Quantity := GetValueAsDecimal('Quantity', _ErrorIfNotExists);
    end;

    procedure Get_Quantity(): Decimal
    begin
        exit(Get_Quantity(false));
    end;

    procedure Get_ReferenceID(_ErrorIfNotExists: Boolean): Text
    begin
        exit(GetValue('ReferenceID', _ErrorIfNotExists));
    end;

    procedure Get_ReferenceID(): Text
    begin
        exit(Get_ReferenceID(false));
    end;

    procedure Get_ShipmentNoFilter(_ErrorIfNotExists: Boolean) _ShipmentNoFilter: Code[20]
    begin
        Evaluate(_ShipmentNoFilter, GetValue('ShipmentNoFilter', _ErrorIfNotExists));
    end;

    procedure Get_ShipmentNoFilter(): Code[20]
    begin
        exit(Get_ShipmentNoFilter(false));
    end;

    /// <remarks>
    /// Bin.Code = Code[20]
    /// Item.ShelfNo = Code[10]
    /// </remarks>
    procedure Get_ToBin(_ErrorIfNotExists: Boolean) _ToBin: Code[20]
    begin
        Evaluate(_ToBin, GetValue('ToBin', _ErrorIfNotExists));
    end;

    procedure Get_ToBin(): Code[20]
    begin
        exit(Get_ToBin(false));
    end;
    /// <remarks>
    /// Support different casing of NodeName used in planned functions and OnlineValidation
    /// </remarks>
    procedure Get_ToteID(_ErrorIfNotExists: Boolean) _ToteID: Text[100]
    begin
        if HasValue('ToteID') then
            Evaluate(_ToteID, GetValue('ToteID'))
        else
            if HasValue('toteId') then  // OnlineValidation / ValidateToteID
                Evaluate(_ToteID, GetValue('toteId'))
            else
                Evaluate(_ToteID, GetValue('ToteId', _ErrorIfNotExists));
    end;

    procedure Get_ToteID(): Text[100]
    begin
        exit(Get_ToteID(false));
    end;

    /// <remarks>
    /// From DataTable -> return type is Text
    /// MaxLen for non-table data: None
    /// </remarks>
    procedure Get_UnitOfMeasure(_ErrorIfNotExists: Boolean) _UnitOfMeasure: Text[10]
    begin
        Evaluate(_UnitOfMeasure, GetValue('UnitOfMeasure', _ErrorIfNotExists));
    end;

    procedure Get_UnitOfMeasure(): Text[10]
    begin
        exit(Get_UnitOfMeasure(false));
    end;

    procedure Get_ContextValuesAsWhseInquiryElement(var _ContextValues: Record "MOB NS WhseInquery Element"; _ErrorIfNotExists: Boolean)
    begin
        MobNsRequestMgt.SaveContextValuesAsWhseInquiryElement(GlobalXmlRequestDoc, _ContextValues);

        if _ErrorIfNotExists and (_ContextValues.IsEmpty()) then
            Rec.GetValue('ContextValues', true);    // Intentionally throw error if node do not exist but allow code to run if node exists with no child nodes
    end;

    procedure Get_ContextValuesAsWhseInquiryElement(var _ContextValues: Record "MOB NS WhseInquery Element")
    begin
        Get_ContextValuesAsWhseInquiryElement(_ContextValues, false);
    end;

}
