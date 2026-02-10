table 81396 "MOB Steps Element"
{
    Access = Public;
    Caption = 'MOB Steps Element', Locked = true;

    //
    // Android App: Default values from InputLineBaseConfiguration.cs
    // 
    // this.DataDisplayColumn = null;
    // this.DataKeyColumn = null;
    // this.DataTable = null;
    // this.DefaultValue = null;
    // this.DefaultTo = DefaultToType.FirstValue;
    // this.FilterColumn = null;
    // this.id = -1;
    // this.Label = null;
    // this.Length = int.MaxValue;
    // this.LinkColumn = null;
    // this.LinkedElement = int.MinValue;
    // this.ListSeparator = ";";
    // this.Name = null;
    // _maxValue = null;
    // _minValue = null;
    // this.Optional = false;

    // 
    // Android App: Default values from CollectorStepConfiguration.cs
    //
    // this.AutoForwardAfterScan = true;
    // this.OnlineValidation = new OnlineValidationConfiguration();
    // this.PerformCalculation = true;
    // this.Visible = true;

    fields
    {
        //
        // Fields below 10 is not to be written as attributes (assign field, rather than use SetValue)
        //
        field(1; "Key"; Integer)
        {
            Caption = 'Key', Locked = true;
            DataClassification = SystemMetadata;
            AutoIncrement = true;       // Business Central 365 temporary tables not supported
        }

        field(5; ConfigurationKey; Text[50])
        {
            Caption = 'ConfigurationKey', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(6; NodeName; Text[50])
        {
            Caption = 'NodeName', Locked = true;
            DataClassification = SystemMetadata;
        }

        //
        // Fields 10..799|1000.. are wrriten to file as steps attributes (use SetValue, rather than assigning field directly)
        //
        field(10; inputType; Text[50])
        {
            Caption = 'inputType', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(20; id; Text[10])
        {
            Caption = 'id', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(30; name; Text[50])
        {
            Caption = 'name', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(100; autoForwardAfterScan; Text[10])
        {
            Caption = 'autoForwardAfterScan', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(110; header; Text[100])
        {
            Caption = 'header', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(200; visible; Text[10])
        {
            Caption = 'visible', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(210; dataDisplayColumn; Text[50])
        {
            Caption = 'dataDisplayColumn', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(220; dataKeyColumn; Text[50])
        {
            Caption = 'dataKeyColumn', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(230; dataTable; Text[50])
        {
            Caption = 'dataTable', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(235; defaultTo; Text[50])
        {
            Caption = 'defaultTo', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(240; defaultValue; Text[50])
        {
            Caption = 'defaultValue', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(250; eanAi; Text[50])
        {
            Caption = 'eanAi', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(260; editable; Text[10])
        {
            Caption = 'editable', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(270; filterColumn; Text[50])
        {
            Caption = 'filterColumn', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(280; format; Text[50])
        {
            Caption = 'format', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(290; helpLabel; Text[100])
        {
            Caption = 'helpLabel', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(300; helpLabelMaximize; Text[10])
        {
            Caption = 'helpLabelMaximize', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(305; inputFormat; Text[50])
        {
            Caption = 'inputFormat', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(310; "label"; Text[100])
        {
            Caption = 'label', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(320; labelWidth; Text[10])
        {
            Caption = 'labelWidth', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(330; length; Text[10])
        {
            Caption = 'length', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(335; linkColumn; Text[50])
        {
            Caption = 'linkColumn', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(340; linkedElement; Text[10])
        {
            Caption = 'linkedElement', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(350; listSeparator; Text[1])
        {
            Caption = 'listSeparator', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(360; listValues; Text[250])
        {
            Caption = 'listValues', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(370; maxDate; Text[10])
        {
            Caption = 'maxDate', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(380; maxValue; Text[50])
        {
            Caption = 'maxValue', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(390; minDate; Text[10])
        {
            Caption = 'minDate', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(400; minValue; Text[50])
        {
            Caption = 'minValue', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(410; optional; Text[10])
        {
            Caption = 'optional', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(420; overDeliveryValidation; Text[10])
        {
            Caption = 'overDeliveryValidation', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(430; performCalculation; Text[10])
        {
            Caption = 'performCalculation', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(440; primaryInputMethod; Text[50])
        {
            Caption = 'primaryInputMethod', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(450; resolutionHeight; Text[10])
        {
            Caption = 'resolutionHeight', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(460; resolutionWidth; Text[10])
        {
            Caption = 'resolutionWidth', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(470; uniqueValues; Text[10])
        {
            Caption = 'uniqueValues', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(480; validationCaseSensitive; Text[10])
        {
            Caption = 'validationCaseSensitive', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(490; validationValues; Text[250])
        {
            Caption = 'validationValues', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(500; validationWarningType; Text[10])
        {
            Caption = 'validationWarningType', Locked = true;
            DataClassification = SystemMetadata;
        }
        // field(550; acceptBarcode; Text[10])      // Only on HeaderConfigurations - field no. reserved
        // field(560; clearOnClear; Text[10])       // Only on HeaderConfigurations - field no. reserved
        // field(570; locked; Text[10])             // Only on HeaderConfigurations - field no. reserved
        // field(580; searchType; Text[50])         // Only on HeaderConfigurations - field no. reserved
        field(600; scanBehavior; Text[20])          // Only typeAndQuantity
        {
            Caption = 'scanBehavior', Locked = true;
            DataClassification = SystemMetadata;
        }

    }
    keys
    {
        key(Key1; "Key")
        {
        }

        key(ConfigurationKey1; ConfigurationKey)
        {
        }
    }

    var
        NsElementMgt: Codeunit "MOB NS Element Management";
        MobFeatureTelemetryWrapper: Codeunit "MOB Feature Telemetry Wrapper";
        AutoSave: Boolean;
        FastForwardMode: Enum "MOB FastForwardMode";
        CancelBehaviour: Enum "MOB CancelBehaviour";
        LastSetConfigurationKey: Text[50];
        MustCallCreateNext: Boolean;
        MUST_BE_TEMPORARY_Err: Label 'Internal error: %1 must be a temporary record.', Locked = true;
        CREATE_NEVER_CALLED_Err: Label 'Steps cannot be modified from this event or you need to call Steps.Create() before modifying steps.', Locked = true;
        InvalidStepNameErr: Label 'Invalid Step name="%1": %2', Comment = '%1 contains step name, %2 contains last error text', Locked = true;
        WARN_Txt: Label 'Warn', Locked = true;

    trigger OnDelete()
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Rec);
        NsElementMgt.DeleteValues(RecRef); // Doesn't work if called through DeleteAll. Handled in Create procedure
    end;

    procedure InitConfigurationKey(_ConfigurationKey: Text[50])
    begin
        LastSetConfigurationKey := _ConfigurationKey;
        MustCallCreateNext := true;
    end;

    // low level create with no inputType - to be used from UnitTests only
    procedure Create()
    begin
        Create(true);   // with AutoSave upon every SetValue
    end;

    // low level create with no inputType - to be used from UnitTests only
    local procedure Create(_AutoSave: Boolean)
    var
        RecRef: RecordRef;
    begin
        if not IsTemporary() then
            Error(MUST_BE_TEMPORARY_Err, TableCaption());

        Init();
        Key := 0;

        AutoIncrementKey(Rec);
        ConfigurationKey := LastSetConfigurationKey;
        NodeName := 'add';      // default NodeName unless overwritten
        Insert();

        // Make sure all existing values in Mob Node Value Buffer is cleared. Values may hang if step was deleted with DeleteAll
        RecRef.GetTable(Rec);
        NsElementMgt.DeleteValues(RecRef);

        AutoSave := _AutoSave;
        MustCallCreateNext := false;
    end;


    /// <summary>
    /// Save (modify) current Steps Element. Must be called every time a Steps Element has all values set, to persist changes.
    /// </summary>
    procedure Save()
    begin
        if MustCallCreateNext then
            Error(CREATE_NEVER_CALLED_Err);

        TestField(Key);
        SyncronizeTableToBuffer();

        SetLinkedValuesOnSave();

        Modify();
        DeleteDuplicateSteps();

        AutoSave := true;   // performance optimization only 'till first save -- subsequent Set'ters should autosave for less risk of errors
    end;

    local procedure SetLinkedValuesOnSave()
    begin
        // Add additional tags if never set
        if (Get_listValues() <> '') and (Get_listSeparator() = '') then
            Set_listSeparator(';');
        if (Get_validationValues() <> '') and (Get_validationCaseSensitive() = '') then
            Set_validationCaseSensitive(false);
    end;

    /// <summary>
    /// Delete all duplicate Steps for a Configuration Key with same id and name (leaving only the current step)
    /// Used for production OnGetRegistrationConfigurationOnProdOutput_OnAddStepsToProductionOutput event to prevent duplicates in the Xml
    /// </summary>
    local procedure DeleteDuplicateSteps()
    var
        CursorMgt: Codeunit "MOB Cursor Management";
    begin
        CursorMgt.Backup(Rec);
        Rec.SetFilter("Key", '<>%1', Rec."Key");
        Rec.SetRange(ConfigurationKey, Rec.ConfigurationKey);
        Rec.SetRange(id, Rec.id);
        Rec.SetRange(name, Rec.name);
        Rec.DeleteAll(true);
        CursorMgt.Restore(Rec);
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
    /// <param name="_TempElement">The Steps Element record to autoincrement (must be a temporary record)</param>
    local procedure AutoIncrementKey(var _TempElement: Record "MOB Steps Element")
    var
        TempElement2: Record "MOB Steps Element" temporary;
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

    procedure SetValueAsHtml(_PathToSet: Text; _NewHtmlValue: Text)
    begin
        SetValueAsHtml(0, _PathToSet, _NewHtmlValue);
    end;

    local procedure SetValueAsHtml(_FieldNo: Integer; _PathToSet: Text; _NewHtmlValue: Text)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Rec);
        NsElementMgt.SetValueAsHtml(RecRef, Rec."Key", _PathToSet, _NewHtmlValue, _FieldNo);
        RecRef.SetTable(Rec);
    end;

    procedure GetValue(_PathToGet: Text): Text
    begin
        exit(GetValue(0, _PathToGet, false));
    end;

    local procedure GetValue(_FieldNo: Integer; _PathToGet: Text; _ErrorIfNotExists: Boolean): Text
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

    procedure SetMustCallCreateNext(_NewValue: Boolean)
    var
    begin
        MustCallCreateNext := _NewValue;
    end;

    /// <summary>
    /// Get step by Name (move table pointer or clear record) - will overwrite existing step if not saved
    /// </summary>
    procedure GetByName(_Name: Text[250]; _ErrorIfNotExists: Boolean): Boolean
    var
        xView: Text;
        IsFound: Boolean;
    begin
        xView := GetView();
        SetRange(name, _Name);

        if _ErrorIfNotExists then begin
            FindFirst();
            IsFound := true;
        end else
            IsFound := FindFirst();

        if not IsFound then
            Clear(Rec);

        SetView(xView);
        exit(IsFound);
    end;

    /// <summary>
    /// Syncronize current Steps Element record  to internal NodeValue Buffer. All text fields are syncronized excluding field no. range 800..999.
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
    // InputLineBaseConfiguration.cs  (shared properties for HeaderConfigurations and Steps)
    //

    procedure Set_inputType(_NewValue: Text)
    begin
        SetValue(FieldNo(inputType), FieldName(inputType), _NewValue);
    end;

    procedure Set_inputType(_TrueFalseExpression: Boolean; _NewValueTrue: Text; _NewValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_inputType(_NewValueTrue)
        else
            Set_inputType(_NewValueFalse);
    end;

    procedure Get_inputType(): Text
    begin
        exit(GetValue(FieldNo(inputType), FieldName(inputType), false));
    end;

    procedure Set_id(_NewValue: Integer)
    begin
        Set_id(Format(_NewValue));
    end;

    procedure Set_id(_TrueFalseExpression: Boolean; _NewValueTrue: Integer; _NewValueFalse: Integer)
    begin
        if _TrueFalseExpression then
            Set_id(_NewValueTrue)
        else
            Set_id(_NewValueFalse);
    end;

    procedure Set_id(_NewValue: Text)
    begin
        SetValue(FieldNo(id), FieldName(id), _NewValue);
    end;

    procedure Set_id(_TrueFalseExpression: Boolean; _NewValueTrue: Text; _NewValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_id(_NewValueTrue)
        else
            Set_id(_NewValueFalse);
    end;

    procedure Get_id(): Text
    begin
        exit(GetValue(FieldNo(id), FieldName(id), false));
    end;

    procedure Set_name(_NewValue: Text)
    var
        MobXmlMgt: Codeunit "MOB XML Management";
    begin
        SetValue(FieldNo(name), FieldName(name), _NewValue);

        // Verify Xml naming conventions
        if not MobXmlMgt.IsValidNodeName(_NewValue) then
            Error(InvalidStepNameErr, _NewValue, GetLastErrorText());
    end;

    procedure Set_name(_TrueFalseExpression: Boolean; _NewValueTrue: Text; _NewValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_name(_NewValueTrue)
        else
            Set_name(_NewValueFalse);
    end;

    procedure Get_name(): Text
    begin
        exit(GetValue(FieldNo(name), FieldName(name), false));
    end;

    procedure Set_dataDisplayColumn(_NewValue: Text)
    begin
        SetValue(FieldNo(dataDisplayColumn), FieldName(dataDisplayColumn), _NewValue);
    end;

    procedure Set_dataDisplayColumn(_TrueFalseExpression: Boolean; _NewValueTrue: Text; _NewValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_dataDisplayColumn(_NewValueTrue)
        else
            Set_dataDisplayColumn(_NewValueFalse);
    end;

    procedure Get_dataDisplayColumn(): Text
    begin
        exit(GetValue(FieldNo(dataDisplayColumn), FieldName(dataDisplayColumn), false));
    end;

    procedure Set_dataKeyColumn(_NewValue: Text)
    begin
        SetValue(FieldNo(dataKeyColumn), FieldName(dataKeyColumn), _NewValue);
    end;

    procedure Set_dataKeyColumn(_TrueFalseExpression: Boolean; _NewValueTrue: Text; _NewValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_dataKeyColumn(_NewValueTrue)
        else
            Set_dataKeyColumn(_NewValueFalse);
    end;

    procedure Get_dataKeyColumn(): Text
    begin
        exit(GetValue(FieldNo(dataKeyColumn), FieldName(dataKeyColumn), false));
    end;

    procedure Set_dataTable(_NewValue: Text)
    begin
        SetValue(FieldNo(dataTable), FieldName(dataTable), _NewValue);
    end;

    procedure Set_dataTable(_TrueFalseExpression: Boolean; _NewValueTrue: Text; _NewValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_dataTable(_NewValueTrue)
        else
            Set_dataTable(_NewValueFalse);
    end;

    procedure Get_dataTable(): Text
    begin
        exit(GetValue(FieldNo(dataTable), FieldName(dataTable), false));
    end;

    procedure Set_defaultTo(_NewValue: Text)
    begin
        SetValue(FieldNo(defaultTo), FieldName(defaultTo), _NewValue);
    end;

    procedure Set_defaultTo(_TrueFalseExpression: Boolean; _NewValueTrue: Text; _NewValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_defaultTo(_NewValueTrue)
        else
            Set_defaultTo(_NewValueFalse);
    end;

    procedure Get_defaultTo(): Text
    begin
        exit(GetValue(FieldNo(defaultTo), FieldName(defaultTo), false));
    end;

    procedure Set_defaultValue(_NewValue: Text)
    begin
        SetValue(FieldNo(defaultValue), FieldName(defaultValue), _NewValue);
    end;

    procedure Set_defaultValue(_NewValue: DateTime)
    var
        MobToolbox: Codeunit "MOB Toolbox";
    begin
        Set_defaultValue(MobToolbox.DateTime2TextResponseFormat(_NewValue));
    end;

    procedure Set_defaultValue(_NewValue: Date)
    var
        MobToolbox: Codeunit "MOB Toolbox";
    begin
        Set_defaultValue(MobToolbox.Date2TextResponseFormat(_NewValue));
    end;

    procedure Set_defaultValue(_TrueFalseExpression: Boolean; _NewValueTrue: Text; _NewValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_defaultValue(_NewValueTrue)
        else
            Set_defaultValue(_NewValueFalse);
    end;

    procedure Set_defaultValue(_NewValue: Decimal)
    var
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
    begin
        SetValue(FieldNo(defaultValue), FieldName(defaultValue), MobWmsToolbox.Decimal2TextAsXmlFormat(_NewValue));
    end;

    procedure Set_defaultValue(_TrueFalseExpression: Boolean; _NewValueTrue: Decimal; _NewValueFalse: Decimal)
    begin
        if _TrueFalseExpression then
            Set_defaultValue(_NewValueTrue)
        else
            Set_defaultValue(_NewValueFalse);
    end;

    procedure Get_defaultValue(): Text
    begin
        exit(GetValue(FieldNo(defaultValue), FieldName(defaultValue), false));
    end;

    procedure Set_eanAi(_NewValue: Text)
    begin
        SetValue(FieldNo(eanAi), FieldName(eanAi), _NewValue);
    end;

    procedure Set_eanAi(_TrueFalseExpression: Boolean; _NewValueTrue: Text; _NewValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_eanAi(_NewValueTrue)
        else
            Set_eanAi(_NewValueFalse);
    end;

    procedure Get_eanAi(): Text
    begin
        exit(GetValue(FieldNo(eanAi), FieldName(eanAi), false));
    end;

    procedure Set_filterColumn(_NewValue: Text)
    begin
        SetValue(FieldNo(filterColumn), FieldName(filterColumn), _NewValue);
    end;

    procedure Set_filterColumn(_TrueFalseExpression: Boolean; _NewValueTrue: Text; _NewValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_filterColumn(_NewValueTrue)
        else
            Set_filterColumn(_NewValueFalse);
    end;

    procedure Get_filterColumn(): Text
    begin
        exit(GetValue(FieldNo(filterColumn), FieldName(filterColumn), false));
    end;

    procedure Set_inputFormat(_NewValue: Text)
    begin
        SetValue(FieldNo(inputFormat), FieldName(inputFormat), _NewValue);
    end;

    procedure Set_inputFormat(_TrueFalseExpression: Boolean; _NewValueTrue: Text; _NewValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_inputFormat(_NewValueTrue)
        else
            Set_inputFormat(_NewValueFalse);
    end;

    procedure Get_inputFormat(): Text
    begin
        exit(GetValue(FieldNo(inputFormat), FieldName(inputFormat), false));
    end;

    procedure Set_label(_NewValue: Text)
    begin
        SetValue(FieldNo("label"), FieldName("label"), _NewValue);
    end;

    procedure Set_label(_TrueFalseExpression: Boolean; _NewValueTrue: Text; _NewValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_label(_NewValueTrue)
        else
            Set_label(_NewValueFalse);
    end;

    procedure Get_label(): Text
    begin
        exit(GetValue(FieldNo("label"), FieldName("label"), false));
    end;

    procedure Set_length(_NewValue: Integer)
    begin
        Set_length(Format(_NewValue));
    end;

    procedure Set_length(_TrueFalseExpression: Boolean; _NewValueTrue: Integer; _NewValueFalse: Integer)
    begin
        if _TrueFalseExpression then
            Set_length(_NewValueTrue)
        else
            Set_length(_NewValueFalse);
    end;

    procedure Set_length(_NewValue: Text)
    begin
        SetValue(FieldNo(length), FieldName(length), _NewValue);
    end;

    procedure Set_length(_TrueFalseExpression: Boolean; _NewValueTrue: Text; _NewValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_length(_NewValueTrue)
        else
            Set_length(_NewValueFalse);
    end;

    procedure Get_length(): Text
    begin
        exit(GetValue(FieldNo(length), FieldName(length), false));
    end;

    procedure Set_linkColumn(_NewValue: Text)
    begin
        SetValue(FieldNo(linkColumn), FieldName(linkColumn), _NewValue);
    end;

    procedure Set_linkColumn(_TrueFalseExpression: Boolean; _NewValueTrue: Text; _NewValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_linkColumn(_NewValueTrue)
        else
            Set_linkColumn(_NewValueFalse);
    end;

    procedure Get_linkColumn(): Text
    begin
        exit(GetValue(FieldNo(linkColumn), FieldName(linkColumn), false));
    end;

    procedure Set_linkedElement(_NewValue: Integer)
    begin
        Set_linkedElement(Format(_NewValue));
    end;

    procedure Set_linkedElement(_TrueFalseExpression: Boolean; _NewValueTrue: Integer; _NewValueFalse: Integer)
    begin
        if _TrueFalseExpression then
            Set_linkedElement(_NewValueTrue)
        else
            Set_linkedElement(_NewValueFalse);
    end;

    procedure Set_linkedElement(_NewValue: Text)
    begin
        SetValue(FieldNo(linkedElement), FieldName(linkedElement), _NewValue);
    end;

    procedure Set_linkedElement(_TrueFalseExpression: Boolean; _NewValueTrue: Text; _NewValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_linkedElement(_NewValueTrue)
        else
            Set_linkedElement(_NewValueFalse);
    end;

    procedure Get_linkedElement(): Text
    begin
        exit(GetValue(FieldNo(linkedElement), FieldName(linkedElement), false));
    end;

    procedure Set_listSeparator(_NewValue: Text)
    begin
        SetValue(FieldNo(listSeparator), FieldName(listSeparator), _NewValue);
    end;

    procedure Set_listSeparator(_TrueFalseExpression: Boolean; _NewValueTrue: Text; _NewValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_listSeparator(_NewValueTrue)
        else
            Set_listSeparator(_NewValueFalse);
    end;

    procedure Get_listSeparator(): Text
    begin
        exit(GetValue(FieldNo(listSeparator), FieldName(listSeparator), false));
    end;

    procedure Set_listValues(_NewValue: Text)
    begin
        SetValue(FieldNo(listValues), FieldName(listValues), _NewValue);
    end;

    procedure Set_listValues(_TrueFalseExpression: Boolean; _NewValueTrue: Text; _NewValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_listValues(_NewValueTrue)
        else
            Set_listValues(_NewValueFalse);
    end;

    procedure Get_listValues(): Text
    begin
        exit(GetValue(FieldNo(listValues), FieldName(listValues), false));
    end;

    procedure Set_maxDate(_NewValue: Date)
    var
        MobToolbox: Codeunit "MOB Toolbox";
    begin
        Set_maxDate(MobToolbox.Date2TextResponseFormat(_NewValue));
    end;

    procedure Set_maxDate(_TrueFalseExpression: Boolean; _NewValueTrue: Date; _NewValueFalse: Date)
    begin
        if _TrueFalseExpression then
            Set_maxDate(_NewValueTrue)
        else
            Set_maxDate(_NewValueFalse);
    end;

    procedure Set_maxDate(_NewValue: Text)
    begin
        SetValue(FieldNo(maxDate), FieldName(maxDate), _NewValue);
    end;

    procedure Set_maxDate(_TrueFalseExpression: Boolean; _NewValueTrue: Text; _NewValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_maxDate(_NewValueTrue)
        else
            Set_maxDate(_NewValueFalse);
    end;

    procedure Get_maxDate(): Text
    begin
        exit(GetValue(FieldNo(maxDate), FieldName(maxDate), false));
    end;

    procedure Set_maxValue(_NewValue: Decimal)
    var
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
    begin
        SetValue(FieldNo(maxValue), FieldName(maxValue), MobWmsToolbox.Decimal2TextAsXmlFormat(_NewValue));
    end;

    procedure Set_maxValue(_TrueFalseExpression: Boolean; _NewValueTrue: Decimal; _NewValueFalse: Decimal)
    begin
        if _TrueFalseExpression then
            Set_maxValue(_NewValueTrue)
        else
            Set_maxValue(_NewValueFalse);
    end;

    procedure Set_maxValue(_NewValue: Text)
    begin
        SetValue(FieldNo(maxValue), FieldName(maxValue), _NewValue);
    end;

    procedure Set_maxValue(_TrueFalseExpression: Boolean; _NewValueTrue: Text; _NewValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_maxValue(_NewValueTrue)
        else
            Set_maxValue(_NewValueFalse);
    end;

    procedure Get_maxValue(): Text
    begin
        exit(GetValue(FieldNo(maxValue), FieldName(maxValue), false));
    end;

    procedure Set_minDate(_NewValue: Date)
    var
        MobToolbox: Codeunit "MOB Toolbox";
    begin
        Set_minDate(MobToolbox.Date2TextResponseFormat(_NewValue));
    end;

    procedure Set_minDate(_TrueFalseExpression: Boolean; _NewValueTrue: Date; _NewValueFalse: Date)
    begin
        if _TrueFalseExpression then
            Set_minDate(_NewValueTrue)
        else
            Set_minDate(_NewValueFalse);
    end;

    procedure Set_minDate(_NewValue: Text)
    begin
        SetValue(FieldNo(minDate), FieldName(minDate), _NewValue);
    end;

    procedure Set_minDate(_TrueFalseExpression: Boolean; _NewValueTrue: Text; _NewValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_minDate(_NewValueTrue)
        else
            Set_minDate(_NewValueFalse);
    end;

    procedure Get_minDate(): Text
    begin
        exit(GetValue(FieldNo(minDate), FieldName(minDate), false));
    end;

    procedure Set_minValue(_NewValue: Decimal)
    var
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
    begin
        SetValue(FieldNo(minValue), FieldName(minValue), MobWmsToolbox.Decimal2TextAsXmlFormat(_NewValue));
    end;

    procedure Set_minValue(_TrueFalseExpression: Boolean; _NewValueTrue: Decimal; _NewValueFalse: Decimal)
    begin
        if _TrueFalseExpression then
            Set_minValue(_NewValueTrue)
        else
            Set_minValue(_NewValueFalse);
    end;

    procedure Set_minValue(_NewValue: Text)
    begin
        SetValue(FieldNo(minValue), FieldName(minValue), _NewValue);
    end;

    procedure Set_minValue(_TrueFalseExpression: Boolean; _NewValueTrue: Text; _NewValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_minValue(_NewValueTrue)
        else
            Set_minValue(_NewValueFalse);
    end;

    procedure Get_minValue(): Text
    begin
        exit(GetValue(FieldNo(minValue), FieldName(minValue), false));
    end;

    procedure Set_optional(_NewValue: Boolean)
    var
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
    begin
        Set_optional(MobWmsToolbox.Bool2Text(_NewValue));
    end;

    procedure Set_optional(_NewValue: Text)
    begin
        SetValue(FieldNo(optional), FieldName(optional), _NewValue);
    end;

    procedure Get_optional(): Text
    begin
        exit(GetValue(FieldNo(optional), FieldName(optional), false));
    end;

    procedure Set_validationValues(_NewValue: Text)
    begin
        SetValue(FieldNo(validationValues), FieldName(validationValues), _NewValue);
    end;

    procedure Set_validationValues(_TrueFalseExpression: Boolean; _NewValueTrue: Text; _NewValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_validationValues(_NewValueTrue)
        else
            Set_validationValues(_NewValueFalse);
    end;

    procedure Get_validationValues(): Text
    begin
        exit(GetValue(FieldNo(validationValues), FieldName(validationValues), false));
    end;

    //
    // CollectorStepsConfigurations.cs  (do not exists at HeaderConfigurations)
    //
    procedure Set_autoForwardAfterScan(_NewValue: Boolean)
    var
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
    begin
        Set_autoForwardAfterScan(MobWmsToolbox.Bool2Text(_NewValue));
    end;

    procedure Set_autoForwardAfterScan(_NewValue: Text)
    begin
        SetValue(FieldNo(autoForwardAfterScan), FieldName(autoForwardAfterScan), _NewValue);
    end;

    procedure Get_autoForwardAfterScan(): Text
    begin
        exit(GetValue(FieldNo(autoForwardAfterScan), FieldName(autoForwardAfterScan), false));
    end;

    procedure Set_header(_NewValue: Text)
    begin
        SetValue(FieldNo(header), FieldName(header), _NewValue);
    end;

    procedure Set_header(_TrueFalseExpression: Boolean; _NewValueTrue: Text; _NewValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_header(_NewValueTrue)
        else
            Set_header(_NewValueFalse);
    end;

    procedure Get_header(): Text
    begin
        exit(GetValue(FieldNo(header), FieldName(header), false));
    end;

    procedure Set_visible(_NewValue: Boolean)
    var
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
    begin
        Set_visible(MobWmsToolbox.Bool2Text(_NewValue));
    end;

    procedure Set_visible(_NewValue: Text)
    begin
        SetValue(FieldNo(visible), FieldName(visible), _NewValue);
    end;

    procedure Get_visible(): Text
    begin
        exit(GetValue(FieldNo(visible), FieldName(visible), false));
    end;

    procedure Set_helpLabel(_NewValue: Text)
    begin
        if Get_inputType() = 'Information' then
            SetValueAsHtml(FieldName(helpLabel), _NewValue)
        else
            SetValue(FieldNo(helpLabel), FieldName(helpLabel), _NewValue);
    end;

    procedure Set_helpLabel(_TrueFalseExpression: Boolean; _NewValueTrue: Text; _NewValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_helpLabel(_NewValueTrue)
        else
            Set_helpLabel(_NewValueFalse);
    end;

    procedure Get_helpLabel(): Text
    begin
        exit(GetValue(FieldNo(helpLabel), FieldName(helpLabel), false));
    end;

    procedure Set_overDeliveryValidation(_NewValue: Text)
    begin
        SetValue(FieldNo(overDeliveryValidation), FieldName(overDeliveryValidation), _NewValue);
    end;

    procedure Set_overDeliveryValidation(_TrueFalseExpression: Boolean; _NewValueTrue: Text; _NewValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_overDeliveryValidation(_NewValueTrue)
        else
            Set_overDeliveryValidation(_NewValueFalse);
    end;

    procedure Get_overDeliveryValidation(): Text
    begin
        exit(GetValue(FieldNo(overDeliveryValidation), FieldName(overDeliveryValidation), false));
    end;

    procedure Set_primaryInputMethod(_NewValue: Text)
    begin
        SetValue(FieldNo(primaryInputMethod), FieldName(primaryInputMethod), _NewValue);
    end;

    procedure Set_primaryInputMethod(_TrueFalseExpression: Boolean; _NewValueTrue: Text; _NewValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_primaryInputMethod(_NewValueTrue)
        else
            Set_primaryInputMethod(_NewValueFalse);
    end;

    procedure Get_primaryInputMethod(): Text
    begin
        exit(GetValue(FieldNo(primaryInputMethod), FieldName(primaryInputMethod), false));
    end;

    procedure Set_performCalculation(_NewValue: Boolean)
    var
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
    begin
        Set_performCalculation(MobWmsToolbox.Bool2Text(_NewValue));
    end;

    procedure Set_performCalculation(_NewValue: Text)
    begin
        SetValue(FieldNo(performCalculation), FieldName(performCalculation), _NewValue);
    end;

    procedure Get_performCalculation(): Text
    begin
        exit(GetValue(FieldNo(performCalculation), FieldName(performCalculation), false));
    end;

    procedure Set_uniqueValues(_NewValue: Boolean)
    var
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
    begin
        Set_uniqueValues(MobWmsToolbox.Bool2Text(_NewValue));
    end;

    procedure Set_uniqueValues(_NewValue: Text)
    begin
        SetValue(FieldNo(uniqueValues), FieldName(uniqueValues), _NewValue);
    end;

    procedure Get_uniqueValues(): Text
    begin
        exit(GetValue(FieldNo(uniqueValues), FieldName(uniqueValues), false));
    end;

    procedure Set_validationCaseSensitive(_NewValue: Boolean)
    var
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
    begin
        Set_validationCaseSensitive(MobWmsToolbox.Bool2Text(_NewValue));
    end;

    procedure Set_validationCaseSensitive(_NewValue: Text)
    begin
        SetValue(FieldNo(validationCaseSensitive), FieldName(validationCaseSensitive), _NewValue);
    end;

    procedure Get_validationCaseSensitive(): Text
    begin
        exit(GetValue(FieldNo(validationCaseSensitive), FieldName(validationCaseSensitive), false));
    end;

    /// <summary>
    ///  Which action to take when validation fails (the entered value was different than suggested)
    /// 'None' = Allow the user to enter a different value than the one suggested
    /// 'Warn' - Ask the user to accept if validation fails
    /// 'Block' - Do not allow the user to enter a different value than the suggested value
    /// </summary>
    procedure Set_validationWarningType(_NewValue: Text)
    begin
        SetValue(FieldNo(validationWarningType), FieldName(validationWarningType), _NewValue);
    end;

    procedure Set_validationWarningType(_TrueFalseExpression: Boolean; _NewValueTrue: Text; _NewValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_validationWarningType(_NewValueTrue)
        else
            Set_validationWarningType(_NewValueFalse);
    end;

    procedure Get_validationWarningType(): Text
    begin
        exit(GetValue(FieldNo(validationWarningType), FieldName(validationWarningType), false));
    end;

    procedure Set_scanBehavior(_NewValue: Text)
    begin
        SetValue(FieldNo(scanBehavior), FieldName(scanBehavior), _NewValue);
    end;

    procedure Set_scanBehavior(_TrueFalseExpression: Boolean; _NewValueTrue: Text; _NewValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_scanBehavior(_NewValueTrue)
        else
            Set_scanBehavior(_NewValueFalse);
    end;

    procedure Get_scanBehavior(): Text
    begin
        exit(GetValue(FieldNo(scanBehavior), FieldName(scanBehavior), false));
    end;

    procedure Set_fastForwardMode(_NewValue: Enum "MOB FastForwardMode")
    begin
        FastForwardMode := _NewValue;
    end;

    procedure Get_fastForwardMode(): Enum "MOB FastForwardMode"
    begin
        exit(FastForwardMode);
    end;

    procedure Set_cancelBehaviour(_NewValue: Enum "MOB CancelBehaviour")
    begin
        CancelBehaviour := _NewValue;
    end;

    procedure Get_cancelBehaviour(): Enum "MOB CancelBehaviour"
    begin
        exit(CancelBehaviour);
    end;

    //
    // Legacy support: Windows Mobile and Window Mobile Embedded
    //
    procedure Set_editable_WindowsMobile(_NewValue: Boolean)
    var
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
    begin
        Set_editable_WindowsMobile(MobWmsToolbox.Bool2Text(_NewValue));
    end;

    procedure Set_editable_WindowsMobile(_NewValue: Text)
    begin
        SetValue(FieldNo(editable), FieldName(editable), _NewValue);
    end;

    procedure Get_editable_WindowsMobile(): Text
    begin
        exit(GetValue(FieldNo(editable), FieldName(editable), false));
    end;

    procedure Set_format_WindowsMobile(_NewValue: Text)
    begin
        SetValue(FieldNo(format), FieldName(format), _NewValue);
    end;

    procedure Set_format_WindowsMobile(_TrueFalseExpression: Boolean; _NewValueTrue: Text; _NewValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_format_WindowsMobile(_NewValueTrue)
        else
            Set_format_WindowsMobile(_NewValueFalse);
    end;

    procedure Get_format_WindowsMobile(): Text
    begin
        exit(GetValue(FieldNo(format), FieldName(format), false));
    end;

    procedure Set_helpLabelMaximize_WindowsMobile(_NewValue: Boolean)
    var
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
    begin
        Set_helpLabelMaximize_WindowsMobile(MobWmsToolbox.Bool2Text(_NewValue));
    end;

    procedure Set_helpLabelMaximize_WindowsMobile(_NewValue: Text)
    begin
        SetValue(FieldNo(helpLabelMaximize), FieldName(helpLabelMaximize), _NewValue);
    end;

    procedure Get_helpLabelMaximize_WindowsMobile(): Text
    begin
        exit(GetValue(FieldNo(helpLabelMaximize), FieldName(helpLabelMaximize), false));
    end;

    procedure Set_labelWidth_WindowsMobile(_NewValue: Integer)
    var
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
    begin
        Set_labelWidth_WindowsMobile(MobWmsToolbox.Integer2TextAsXmlFormat(_NewValue));
    end;

    procedure Set_labelWidth_WindowsMobile(_TrueFalseExpression: Boolean; _NewValueTrue: Integer; _NewValueFalse: Integer)
    begin
        if _TrueFalseExpression then
            Set_labelWidth_WindowsMobile(_NewValueTrue)
        else
            Set_labelWidth_WindowsMobile(_NewValueFalse);
    end;

    procedure Set_labelWidth_WindowsMobile(_NewValue: Text)
    begin
        SetValue(FieldNo(labelWidth), FieldName(labelWidth), _NewValue);
    end;

    procedure Set_labelWidth_WindowsMobile(_TrueFalseExpression: Boolean; _NewValueTrue: Text; _NewValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_labelWidth_WindowsMobile(_NewValueTrue)
        else
            Set_labelWidth_WindowsMobile(_NewValueFalse);
    end;

    procedure Get_labelWidth_WindowsMobile(): Text
    begin
        exit(GetValue(FieldNo(labelWidth), FieldName(labelWidth), false));
    end;

    procedure Set_resolutionHeight_WindowsMobile(_NewValue: Integer)
    var
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
    begin
        SetValue(FieldNo(resolutionHeight), FieldName(resolutionHeight), MobWmsToolbox.Integer2TextAsXmlFormat(_NewValue));
    end;

    procedure Set_resolutionHeight_WindowsMobile(_TrueFalseExpression: Boolean; _NewValueTrue: Decimal; _NewValueFalse: Decimal)
    begin
        if _TrueFalseExpression then
            Set_resolutionHeight_WindowsMobile(_NewValueTrue)
        else
            Set_resolutionHeight_WindowsMobile(_NewValueFalse);
    end;

    procedure Set_resolutionHeight_WindowsMobile(_NewValue: Text)
    begin
        SetValue(FieldNo(resolutionHeight), FieldName(resolutionHeight), _NewValue);
    end;

    procedure Set_resolutionHeight_WindowsMobile(_TrueFalseExpression: Boolean; _NewValueTrue: Text; _NewValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_resolutionHeight_WindowsMobile(_NewValueTrue)
        else
            Set_resolutionHeight_WindowsMobile(_NewValueFalse);
    end;

    procedure Get_resolutionHeight_WindowsMobile(): Text
    begin
        exit(GetValue(FieldNo(resolutionHeight), FieldName(resolutionHeight), false));
    end;

    procedure Set_resolutionWidth_WindowsMobile(_NewValue: Integer)
    var
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
    begin
        SetValue(FieldNo(resolutionWidth), FieldName(resolutionWidth), MobWmsToolbox.Integer2TextAsXmlFormat(_NewValue));
    end;

    procedure Set_resolutionWidth_WindowsMobile(_TrueFalseExpression: Boolean; _NewValueTrue: Decimal; _NewValueFalse: Decimal)
    begin
        if _TrueFalseExpression then
            Set_resolutionWidth_WindowsMobile(_NewValueTrue)
        else
            Set_resolutionWidth_WindowsMobile(_NewValueFalse);
    end;

    procedure Set_resolutionWidth_WindowsMobile(_NewValue: Text)
    begin
        SetValue(FieldNo(resolutionWidth), FieldName(resolutionWidth), _NewValue);
    end;

    procedure Set_resolutionWidth_WindowsMobile(_TrueFalseExpression: Boolean; _NewValueTrue: Text; _NewValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_resolutionWidth_WindowsMobile(_NewValueTrue)
        else
            Set_resolutionWidth_WindowsMobile(_NewValueFalse);
    end;

    procedure Get_resolutionWidth_WindowsMobile(): Text
    begin
        exit(GetValue(FieldNo(resolutionWidth), FieldName(resolutionWidth), false));
    end;

    //
    // onlineValidation
    //

    /// <summary>
    /// Online Validation will trigger a reqeust to the backend where the collected value can be validated or rejected
    /// </summary>
    /// <param name="_RequestDocumentType">Name of mobile document type to call when the online validation is triggered</param>
    procedure Set_onlineValidation(_RequestDocumentType: Text)
    begin
        SetOnlineValidation(_RequestDocumentType, false);
    end;

    /// <summary>
    /// Online Validation will trigger a reqeust to the backend where the collected value can be validated or rejected
    /// </summary>
    /// <param name="_RequestDocumentType">Name of mobile document type to call when the online validation is triggered</param>
    /// <param name="_IncludeCollectedValues">Include "up-until-this-step" collected values in the reqeust for online validation.</param>
    procedure Set_onlineValidation(_RequestDocumentType: Text; _IncludeCollectedValues: Boolean)
    begin
        SetOnlineValidation(_RequestDocumentType, _IncludeCollectedValues);
    end;

    /// <summary>
    /// Internal helper for onlineValidation
    /// </summary>
    local procedure SetOnlineValidation(_RequestDocumentType: Text; _IncludeCollectedValues: Boolean)
    begin
        if _RequestDocumentType <> '' then begin
            SetValue('/onlineValidation', '');
            SetValue('/onlineValidation/@documentName', _RequestDocumentType);
            SetValue('/onlineValidation/@online', 'true');
            if _IncludeCollectedValues then
                SetValue('/onlineValidation/@includeCollectedValues', 'true')
            else
                SetValue('/onlineValidation/@includeCollectedValues', 'false');
        end else begin
            DeleteValue('/onlineValidation');
            DeleteValue('/onlineValidation/@documentName');
            DeleteValue('/onlineValidation/@online');
            DeleteValue('/onlineValidation/@includeCollectedValues');
        end;
    end;

    // ---------------------------------------------------
    // Multiple fields setters for backwards compatibility
    // ---------------------------------------------------
    local procedure RC_Std_Parms(_Id: Integer; _Name: Text; _Header: Text; _Label: Text; _HelpLabel: Text)
    begin
        // Use this function to set the standard parameters for all step types
        // It initializes the advanced parameters to it's default values

        // Standard parameters for all steps

        Set_id(_Id);
        Set_name(_Name);
        Set_header(_Header);
        Set_label(_Label);
        Set_helpLabel(_HelpLabel);

        // Default values and tags that should be included even if empty
        Set_primaryInputMethod('Scan');
        Set_labelWidth_WindowsMobile(100);
        Set_autoForwardAfterScan(true);
        Set_optional(false);
        Set_visible(true);
        Set_eanAi('');
        Set_performCalculation(false);
        Set_helpLabelMaximize_WindowsMobile(false);
        Set_editable_WindowsMobile(true);
        Set_overDeliveryValidation(WARN_Txt);
    end;

    // 
    // Steps Library: Create Methods for all inputTypes
    // 

    // Add a simple list step with data from a table sent out as reference data
    procedure Create_ListStepFromDataTable(_Id: Integer; _Name: Text; _Header: Text; _Label: Text; _HelpLabel: Text; _DataTable: Text; _DataKeyColumn: Text; _DataDisplayColumn: Text; _DefaultValue: Text)
    begin
        Create(false);
        Set_inputType('List');
        RC_Std_Parms(_Id, _Name, _Header, _Label, _HelpLabel);
        Set_dataTable(_DataTable);
        Set_dataKeyColumn(_DataKeyColumn);
        Set_dataDisplayColumn(_DataDisplayColumn);
        Set_defaultValue(_DefaultValue);
        Save();
    end;

    procedure Create_ListStepFromListValues(_Id: Integer; _Name: Text; _Header: Text; _Label: Text; _HelpLabel: Text; _ListValues: Text; _DefaultValue: Text)
    begin
        Create(false);
        Set_inputType('List');
        RC_Std_Parms(_Id, _Name, _Header, _Label, _HelpLabel);
        Set_listValues(_ListValues);
        Set_defaultValue(_DefaultValue);
        Save();
    end;

    procedure Create_ListStep(_Id: Integer; _Name: Text; _Header: Text)
    begin
        Create_ListStep(_Id, _Name);
        Set_header(_Header);
    end;

    procedure Create_ListStep(_Id: Integer; _Name: Text)
    begin
        Create_ListStep(_Id, _Name, true);
    end;

    procedure Create_ListStep(_Id: Integer; _Name: Text; _AutoSave: Boolean)
    begin
        Create(_AutoSave);
        Set_inputType('List');
        RC_Std_Parms(_Id, _Name, '', '', '');
    end;

    procedure Create_TextStep(_Id: Integer; _Name: Text; _Header: Text; _Label: Text; _HelpLabel: Text; _DefaultValue: Text; _Length: Integer)
    begin
        Create(false);
        Set_inputType('Text');
        RC_Std_Parms(_Id, _Name, _Header, _Label, _HelpLabel);
        Set_defaultValue(_DefaultValue);
        Set_length(_Length);
        Save();
    end;

    procedure Create_TextStep(_Id: Integer; _Name: Text; _Header: Text)
    begin
        Create_TextStep(_Id, _Name);
        Set_header(_Header);
    end;

    procedure Create_TextStep(_Id: Integer; _Name: Text)
    begin
        Create_TextStep(_Id, _Name, true);
    end;

    procedure Create_TextStep(_Id: Integer; _Name: Text; _AutoSave: Boolean)
    begin
        Create(_AutoSave);
        Set_inputType('Text');
        RC_Std_Parms(_Id, _Name, '', '', '');
    end;


    procedure Create_RadioButtonStep(_Id: Integer; _Name: Text; _Header: Text; _Label: Text; _HelpLabel: Text; _DefaultValue: Text; _ListValues: Text)
    begin
        Create(false);
        Set_inputType('RadioButton');
        RC_Std_Parms(_Id, _Name, _Header, _Label, _HelpLabel);
        Set_defaultValue(_DefaultValue);
        Set_listValues(_ListValues);
        Save();
    end;

    procedure Create_RadioButtonStep(_Id: Integer; _Name: Text; _Header: Text)
    begin
        Create_RadioButtonStep(_Id, _Name);
        Set_header(_Header);
    end;

    procedure Create_RadioButtonStep(_Id: Integer; _Name: Text)
    begin
        Create_RadioButtonStep(_Id, _Name, true);
    end;

    procedure Create_RadioButtonStep(_Id: Integer; _Name: Text; _AutoSave: Boolean)
    begin
        Create(_AutoSave);
        Set_inputType('RadioButton');
        RC_Std_Parms(_Id, _Name, '', '', '');
    end;

    procedure Create_QuantityByScanStep(_Id: Integer; _Name: Text; _Header: Text; _Label: Text; _HelpLabel: Text; _Editable: Boolean; _MinValue: Decimal; _MaxValue: Decimal; _OverDeliveryValidation: Text; _ValidationValues: Text; _DataTable: Text; _DataKeyColumn: Text)
    begin
        Create(false);
        Set_inputType('QuantityByScan');
        RC_Std_Parms(_Id, _Name, _Header, _Label, _HelpLabel);
        Set_editable_WindowsMobile(_Editable);
        Set_minValue(_MinValue);
        Set_maxValue(_MaxValue);
        Set_overDeliveryValidation(_OverDeliveryValidation);
        Set_listValues(_ValidationValues);  // For backwards compatibility with Windows Mobile
        Set_validationValues(_ValidationValues);
        Set_validationCaseSensitive(false);
        Set_dataTable(_DataTable);
        Set_dataKeyColumn(_DataKeyColumn);
        Save();
    end;

    procedure Create_QuantityByScanStep(_Id: Integer; _Name: Text; _Header: Text)
    begin
        Create_QuantityByScanStep(_Id, _Name);
        Set_header(_Header);
    end;

    procedure Create_QuantityByScanStep(_Id: Integer; _Name: Text)
    begin
        Create_QuantityByScanStep(_Id, _Name, true);
    end;

    procedure Create_QuantityByScanStep(_Id: Integer; _Name: Text; _AutoSave: Boolean)
    begin
        Create(_AutoSave);
        Set_inputType('QuantityByScan');
        RC_Std_Parms(_Id, _Name, '', '', '');
    end;

    procedure Create_MultiScanStep(_Id: Integer; _Name: Text; _Header: Text; _Label: Text; _HelpLabel: Text; _UniqueValues: Boolean)
    begin
        Create(false);
        Set_inputType('MultiScan');
        RC_Std_Parms(_Id, _Name, _Header, _Label, _HelpLabel);
        Set_uniqueValues(_UniqueValues);
        Save();
    end;

    procedure Create_MultiScanStep(_Id: Integer; _Name: Text; _Header: Text)
    begin
        Create_MultiScanStep(_Id, _Name);
        Set_header(_Header);
    end;

    procedure Create_MultiScanStep(_Id: Integer; _Name: Text; _AutoSave: Boolean)
    begin
        Create(_AutoSave);
        Set_inputType('MultiScan');
        RC_Std_Parms(_Id, _Name, '', '', '');
    end;

    procedure Create_MultiScanStep(_Id: Integer; _Name: Text)
    begin
        Create_MultiScanStep(_Id, _Name, true);
    end;

    procedure Create_MultiLineTextStep(_Id: Integer; _Name: Text; _Header: Text; _Label: Text; _HelpLabel: Text; _DefaultValue: Text; _Length: Integer)
    begin
        Create(false);
        Set_inputType('MultiLineText');
        RC_Std_Parms(_Id, _Name, _Header, _Label, _HelpLabel);
        Set_defaultValue(_DefaultValue);
        Set_length(_Length);
        Save();
    end;

    procedure Create_MultiLineTextStep(_Id: Integer; _Name: Text; _Header: Text)
    begin
        Create_MultiLineTextStep(_Id, _Name);
        Set_header(_Header);
    end;

    procedure Create_MultiLineTextStep(_Id: Integer; _Name: Text)
    begin
        Create_MultiLineTextStep(_Id, _Name, true);
    end;

    procedure Create_MultiLineTextStep(_Id: Integer; _Name: Text; _AutoSave: Boolean)
    begin
        Create(_AutoSave);
        Set_inputType('MultiLineText');
        RC_Std_Parms(_Id, _Name, '', '', '');
    end;

    procedure Create_InformationStep(_Id: Integer; _Name: Text; _Header: Text; _Label: Text; _HelpLabelAsHtml: Text)
    begin
        Create(false);
        Set_inputType('Information');
        RC_Std_Parms(_Id, _Name, _Header, _Label, _HelpLabelAsHtml);
        Save();
    end;

    procedure Create_InformationStep(_Id: Integer; _Name: Text; _Header: Text)
    begin
        Create_InformationStep(_Id, _Name);
        Set_header(_Header);
    end;

    procedure Create_InformationStep(_Id: Integer; _Name: Text)
    begin
        Create_InformationStep(_Id, _Name, '', '', '');
    end;

    procedure Create_ImageStep(_Id: Integer; _Name: Text; _Header: Text; _Label: Text; _HelpLabel: Text; _DefaultValue: Text)
    begin
        Create(false);
        Set_inputType('Image');
        RC_Std_Parms(_Id, _Name, _Header, _Label, _HelpLabel);
        Set_defaultValue(_DefaultValue);
        Save();
    end;

    procedure Create_ImageStep(_Id: Integer; _Name: Text; _Header: Text)
    begin
        Create_ImageStep(_Id, _Name);
        Set_header(_Header);
    end;

    procedure Create_ImageStep(_Id: Integer; _Name: Text)
    begin
        Create_ImageStep(_Id, _Name, true);
    end;

    procedure Create_ImageStep(_Id: Integer; _Name: Text; _AutoSave: Boolean)
    begin
        Create(_AutoSave);
        Set_inputType('Image');
        RC_Std_Parms(_Id, _Name, '', '', '');
    end;

    procedure Create_ImageCaptureStep(_Id: Integer; _Name: Text; _Header: Text; _Label: Text; _HelpLabel: Text; _DefaultValue: Text; _ListSeparator: Text; _ResolutionHeight: Integer; _ResolutionWidth: Integer)
    begin
        Create(false);
        Set_inputType('ImageCapture');
        RC_Std_Parms(_Id, _Name, _Header, _Label, _HelpLabel);
        Set_defaultValue(_DefaultValue);
        Set_listSeparator(_ListSeparator);
        Set_resolutionHeight_WindowsMobile(_ResolutionHeight);
        Set_resolutionWidth_WindowsMobile(_ResolutionWidth);
        Save();
    end;

    procedure Create_ImageCaptureStep(_Id: Integer; _Name: Text; _Header: Text)
    begin
        Create_ImageCaptureStep(_Id, _Name);
        Set_header(_Header);
    end;

    procedure Create_ImageCaptureStep(_Id: Integer; _Name: Text)
    begin
        Create_ImageCaptureStep(_Id, _Name, true);
    end;

    procedure Create_ImageCaptureStep(_Id: Integer; _Name: Text; _AutoSave: Boolean)
    begin
        Create(_AutoSave);
        Set_inputType('ImageCapture');
        RC_Std_Parms(_Id, _Name, '', '', '');
    end;

    procedure Create_IntegerStep(_Id: Integer; _Name: Text; _Header: Text; _Label: Text; _HelpLabel: Text; _DefaultValue: Integer; _MinValue: Integer; _MaxValue: Integer; _Length: Decimal; _PerformCalculation: Boolean)
    begin
        Create(false);
        Set_inputType('Integer');
        RC_Std_Parms(_Id, _Name, _Header, _Label, _HelpLabel);
        Set_defaultValue(_DefaultValue);
        Set_minValue(_MinValue);
        Set_maxValue(_MaxValue);
        Set_length(_Length);
        Set_performCalculation(_PerformCalculation);
        Save();
    end;

    procedure Create_IntegerStep(_Id: Integer; _Name: Text; _Header: Text)
    begin
        Create_IntegerStep(_Id, _Name);
        Set_header(_Header);
    end;

    procedure Create_IntegerStep(_Id: Integer; _Name: Text)
    begin
        Create_IntegerStep(_Id, _Name, true);
    end;

    procedure Create_IntegerStep(_Id: Integer; _Name: Text; _AutoSave: Boolean)
    begin
        Create(_AutoSave);
        Set_inputType('Integer');
        RC_Std_Parms(_Id, _Name, '', '', '');
    end;

    procedure Create_DecimalStep(_Id: Integer; _Name: Text; _Header: Text; _Label: Text; _HelpLabel: Text; _DefaultValue: Decimal; _MinValue: Decimal; _MaxValue: Decimal; _Length: Decimal; _PerformCalculation: Boolean)
    begin
        Create(false);
        Set_inputType('Decimal');
        RC_Std_Parms(_Id, _Name, _Header, _Label, _HelpLabel);
        Set_defaultValue(_DefaultValue);
        Set_minValue(_MinValue);
        Set_maxValue(_MaxValue);
        Set_length(_Length);
        Set_performCalculation(_PerformCalculation);
        Save();
    end;

    procedure Create_DecimalStep(_Id: Integer; _Name: Text; _Header: Text)
    begin
        Create_DecimalStep(_Id, _Name);
        Set_header(_Header);
    end;

    procedure Create_DecimalStep(_Id: Integer; _Name: Text)
    begin
        Create_DecimalStep(_Id, _Name, true);
    end;

    procedure Create_DecimalStep(_Id: Integer; _Name: Text; _AutoSave: Boolean)
    begin
        Create(_AutoSave);
        Set_inputType('Decimal');
        RC_Std_Parms(_Id, _Name, '', '', '');
    end;

    procedure Create_DateStep(_Id: Integer; _Name: Text; _Header: Text; _Label: Text; _HelpLabel: Text; _DefaultValue: Date; _Format: Text; _MinDate: Date; _MaxDate: Date)
    begin
        Create(false);
        Set_inputType('Date');
        RC_Std_Parms(_Id, _Name, _Header, _Label, _HelpLabel);
        Set_defaultValue(_DefaultValue);
        Set_format_WindowsMobile(_Format);
        Set_minDate(_MinDate);
        Set_maxDate(_MaxDate);
        Save();
    end;

    procedure Create_DateStep(_Id: Integer; _Name: Text; _Header: Text)
    begin
        Create_DateStep(_Id, _Name);
        Set_header(_Header);
    end;

    procedure Create_DateStep(_Id: Integer; _Name: Text)
    begin
        Create_DateStep(_Id, _Name, true);
    end;

    procedure Create_DateStep(_Id: Integer; _Name: Text; _AutoSave: Boolean)
    begin
        Create(_AutoSave);
        Set_inputType('Date');
        RC_Std_Parms(_Id, _Name, '', '', '');
    end;

    procedure Create_DateTimeStep(_Id: Integer; _Name: Text; _Header: Text; _Label: Text; _HelpLabel: Text; _DefaultValue: DateTime; _Format: Text; _MinDate: Date; _MaxDate: Date)
    begin
        Create(false);
        Set_inputType('DateTime');
        RC_Std_Parms(_Id, _Name, _Header, _Label, _HelpLabel);
        Set_defaultValue(_DefaultValue);
        Set_format_WindowsMobile(_Format);
        Set_minDate(_MinDate);
        Set_maxDate(_MaxDate);
        Save();
    end;

    procedure Create_DateTimeStep(_Id: Integer; _Name: Text; _Header: Text)
    begin
        Create_DateTimeStep(_Id, _Name);
        Set_header(_Header);
    end;

    procedure Create_DateTimeStep(_Id: Integer; _Name: Text)
    begin
        Create_DateTimeStep(_Id, _Name, true);
    end;

    procedure Create_DateTimeStep(_Id: Integer; _Name: Text; _AutoSave: Boolean)
    begin
        Create(_AutoSave);
        Set_inputType('DateTime');
        RC_Std_Parms(_Id, _Name, '', '', '');
    end;

    procedure Create_SignatureStep(_Id: Integer; _Name: Text; _Header: Text; _Label: Text; _HelpLabel: Text)
    begin
        Create(false);
        Set_inputType('Signature');
        RC_Std_Parms(_Id, _Name, _Header, _Label, _HelpLabel);
        Save();
    end;

    procedure Create_SignatureStep(_Id: Integer; _Name: Text; _Header: Text)
    begin
        Create_SignatureStep(_Id, _Name);
        Set_header(_Header);
    end;

    procedure Create_SignatureStep(_Id: Integer; _Name: Text)
    begin
        Create_SignatureStep(_Id, _Name, true);
    end;

    procedure Create_SignatureStep(_Id: Integer; _Name: Text; _AutoSave: Boolean)
    var
        MobWMSLanguage: Codeunit "MOB WMS Language";
    begin
        Create(_AutoSave);
        Set_inputType('Signature');
        RC_Std_Parms(_Id, _Name, MobWMSLanguage.GetMessage('SIGNATURE'), MobWMSLanguage.GetMessage('SIGNATURE_LABEL'), '');
    end;

    procedure Create_SummaryStep(_Id: Integer; _Name: Text; _Header: Text; _HelpLabel: Text)
    begin
        Create(false);
        Set_inputType('Summary');
        RC_Std_Parms(_Id, _Name, _Header, '', _HelpLabel);
        Save();
    end;

    procedure Create_SummaryStep(_Id: Integer; _Name: Text)
    begin
        Create(false);
        Set_inputType('Summary');
        RC_Std_Parms(_Id, _Name, '', '', '');
        Save();
    end;

    procedure Create_SummaryStep(_Id: Integer; _Name: Text; _AutoSave: Boolean)
    begin
        Create(_AutoSave);
        Set_inputType('Summary');
        RC_Std_Parms(_Id, _Name, '', '', '');
    end;
    //
    // Steps Library: Templates
    //

    procedure Create_DateStep_ExpirationDate(_Id: Integer; _ItemNo: Code[20])
    var
        MobToolbox: Codeunit "MOB Toolbox";
        MobWmsLanguage: Codeunit "MOB WMS Language";
    begin
        Create_DateStep(_Id, 'ExpirationDate', false);
        Set_header(MobWmsLanguage.GetMessage('ITEM') + ' ' + _ItemNo + ' - ' + MobWmsLanguage.GetMessage('ENTER_EXP_DATE'));
        Set_label(MobWmsLanguage.GetMessage('EXP_DATE_LABEL') + ':');
        Set_eanAi(MobToolbox.GetExpirationDateGS1Ai());
        Set_defaultValue(WorkDate());
        Set_format_WindowsMobile('dd-MM-yyyy');
        // No minDate
        // No maxDate
        Save();
    end;

    procedure Create_DecimalStep_Quantity(_Id: Integer; _ItemNo: Code[20])
    var
        Item: Record Item;
        MobSetup: Record "MOB Setup";
        MobToolbox: Codeunit "MOB Toolbox";
        MobWmsLanguage: Codeunit "MOB WMS Language";
    begin
        MobSetup.Get();
        Item.Get(_ItemNo);

        Create_DecimalStep(_Id, 'Quantity', false);
        Set_header(MobWmsLanguage.GetMessage('ITEM') + ' ' + Item."No." + ' - ' + MobWmsLanguage.GetMessage('ENTER_QTY'));
        Set_label(MobWmsLanguage.GetMessage('QTY_LABEL') + ':');
        Set_eanAi(MobToolbox.GetQuantityGS1Ai());
        Set_defaultValue(0);
        // No minValue
        // No maxValue
        // No length
        Set_performCalculation(true);
        Save();
    end;

    procedure Create_DecimalStep_QuantityPerLabel(_Id: Integer)
    var
        MobToolbox: Codeunit "MOB Toolbox";
        MobWmsLanguage: Codeunit "MOB WMS Language";
    begin
        Create_DecimalStep(_Id, 'QuantityPerLabel', false);
        Set_header(MobWmsLanguage.GetMessage('ENTER_QTY'));
        Set_label(MobWmsLanguage.GetMessage('QUANTITY_PER_LABEL') + ':');
        Set_helpLabel(MobWmsLanguage.GetMessage('QUANTITY_PER_LABEL_HELP'));
        Set_eanAi(MobToolbox.GetQuantityGS1Ai());
        Set_minValue(0.00001); // Ai 310n Allows for max 5 decimals.
        Set_performCalculation(true);
        Save();
    end;

    procedure Create_IntegerStep_NoOfLabels(_Id: Integer)
    var
        MobWmsLanguage: Codeunit "MOB WMS Language";
    begin
        Create_IntegerStep(_Id, 'NoOfLabels', false);
        Set_header(MobWmsLanguage.GetMessage('NO_OF_LABELS'));
        Set_helpLabel(MobWmsLanguage.GetMessage('NO_OF_LABELS_HELP'));
        Set_defaultValue(1);
        Set_minValue(1);
        Set_performCalculation(true);
        Save();
    end;

    [Obsolete('Use Create_IntegerStep_NoOfCopies instead (planned for removal 04/2025)', 'MOB5.48')]
    procedure Create_DecimalStep_NoOfCopies(_Id: Integer)
    begin
        Create_IntegerStep_NoOfCopies(_Id, true);
    end;

    procedure Create_IntegerStep_NoOfCopies(_Id: Integer)
    begin
        Create_IntegerStep_NoOfCopies(_Id, true);
    end;

    procedure Create_IntegerStep_NoOfCopies(_Id: Integer; _AutoSave: Boolean)
    var
        MobWmsLanguage: Codeunit "MOB WMS Language";
    begin
        Create_IntegerStep(_Id, 'NoOfCopies', false);
        Set_header(MobWmsLanguage.GetMessage('NUMBER_OF_COPIES'));
        Set_helpLabel(MobWmsLanguage.GetMessage('NUMBER_OF_COPIES_HELP'));
        Set_defaultValue(1);
        Set_minValue(1);
        Set_performCalculation(true);
        if _AutoSave then
            Save();
    end;

    procedure Create_ListStep_ReasonCode(_Id: Integer; _ItemNo: Code[20])
    var
        MobWmsLanguage: Codeunit "MOB WMS Language";
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
    begin
        Create_ListStep(_Id, 'ReasonCode', false);
        Set_header(MobWmsLanguage.GetMessage('ITEM') + ' ' + _ItemNo + ' - ' + MobWmsLanguage.GetMessage('REASON'));
        Set_label(MobWmsLanguage.GetMessage('REASON') + ':');
        Set_helpLabel(MobWmsLanguage.GetMessage('ENTER_REASON'));
        Set_listValues(MobWmsToolbox.GetReasonCodes());
        Save();
    end;

    procedure Create_ListStep_Variant(_Id: Integer; _ItemNo: Code[20])
    var
        MobWmsLanguage: Codeunit "MOB WMS Language";
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
    begin
        Create_ListStep(_Id, 'Variant', false);
        Set_header(MobWmsLanguage.GetMessage('ITEM') + ' ' + _ItemNo + ' - ' + MobWmsLanguage.GetMessage('ENTER_VARIANT'));
        Set_label(MobWmsLanguage.GetMessage('VARIANT_LABEL') + ':');
        Set_helpLabel(MobWmsLanguage.GetMessage('ENTER_VARIANT_HELP'));
        Set_listValues(MobWmsToolbox.GetItemVariants(_ItemNo));
        Set_optional(true); // Optional to support blank value. Otherwise 1st element is selected on a list step.
        Save();
    end;

    /// <summary>
    /// Creates a step for collecting "Unit for Measure" (UoM) for a given item
    /// </summary>
    /// <param name="_Id">ID of the step. This unique number also controls the order of the steps</param>
    /// <param name="_ItemNo">Item number, this is used to get the "UoM" codes</param>
    procedure Create_ListStep_UoM(_Id: Integer; _ItemNo: Code[20])
    var
        MobWmsLanguage: Codeunit "MOB WMS Language";
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
    begin
        Create_ListStep(_Id, 'UoM', false);
        Set_header(MobWmsLanguage.GetMessage('ITEM') + ' ' + _ItemNo + ' - ' + MobWmsLanguage.GetMessage('ENTER_UOM'));
        Set_label(MobWmsLanguage.GetMessage('UOM_LABEL') + ':');
        Set_helpLabel(MobWmsLanguage.GetMessage('ENTER_UOM_HELP'));
        Set_listValues(MobWmsToolbox.GetItemUoM(_ItemNo));
        Save();
    end;

    procedure Create_ListStep_Printer(_Id: Integer; _TemplateName: Text[50]; _LocationCode: Code[10])
    var
        MobPrint: Codeunit "MOB Print";
        MobWmsLanguage: Codeunit "MOB WMS Language";
    begin
        Create_ListStep(_Id, 'Printer', false);
        Set_header(StrSubstNo(MobWmsLanguage.GetMessage('SELECT_X'), MobWmsLanguage.GetMessage('PRINTER')));
        Set_listValues(MobPrint.GetMobilePrinters(_TemplateName, _LocationCode));
        Save();
    end;

    procedure Create_ListStep_Printer(_Id: Integer; _TemplateName: Text[50])
    begin
        Create_ListStep_Printer(_Id, _TemplateName, '');
    end;

    /// <summary>
    /// Create a ListStep for Report Print. 
    /// Requires the _RequestValues contains a Location Code to be able to find the right printer(s)
    /// </summary>
    /// <param name="_Id">ID of the step. This unique number also controls the order of the steps</param>
    /// <param name="_ReportDisplayName">The DisplayName is the PK of the Mobile Report table and used to determine which printer(s) are available</param>
    /// <param name="_RequestValues">The request values with a location code (packing station code is optional) to be able to find the right printer(s)</param>
    procedure Create_ListStep_ReportPrinter(_Id: Integer; _ReportDisplayName: Text[50]; var _RequestValues: Record "MOB NS Request Element")
    begin
        Create_ListStep_ReportPrinter(_Id, _ReportDisplayName, _RequestValues, true);
    end;

    internal procedure Create_ListStep_ReportPrinter(_Id: Integer; _ReportDisplayName: Text[50]; var _RequestValues: Record "MOB NS Request Element"; _AutoSave: Boolean)
    var
        MobReportPrintManagement: Codeunit "MOB Report Print Management";
        MobWmsLanguage: Codeunit "MOB WMS Language";
    begin
        Create_ListStep(_Id, 'ReportPrinter', false);
        Set_header(StrSubstNo(MobWmsLanguage.GetMessage('SELECT_X'), MobWmsLanguage.GetMessage('PRINTER')));
        Set_listValues(MobReportPrintManagement.GetReportPrinterList(_ReportDisplayName, _RequestValues));
        if _AutoSave then
            Save();
    end;

    procedure Create_RadioButtonStep_YesNo(_Id: Integer; _Name: Text; _Header: Text; _HelpLabel: Text; _DefaultValue: Boolean)
    var
        MobWmsLanguage: Codeunit "MOB WMS Language";
    begin
        Create_RadioButtonStep_YesNo(_Id, _Name, _Header, _HelpLabel);
        if _DefaultValue then
            Set_defaultValue(MobWmsLanguage.GetMessage('YES'))
        else
            Set_defaultValue(MobWmsLanguage.GetMessage('NO'));
    end;

    procedure Create_RadioButtonStep_YesNo(_Id: Integer; _Name: Text; _Header: Text; _HelpLabel: Text)
    var
        MobWmsLanguage: Codeunit "MOB WMS Language";
    begin
        Create_RadioButtonStep(_Id, _Name, false);
        Set_header(_Header);
        Set_label('');
        Set_helpLabel(_HelpLabel);
        Set_listValues(MobWmsLanguage.GetMessage('YES_NO'));
        Save();
    end;

    procedure Create_RadioButtonStep_YesNo(_Id: Integer; _Name: Text)
    begin
        Create_RadioButtonStep_YesNo(_Id, _Name, '', '', false);
    end;

    procedure Create_TextStep_Barcode(_Id: Integer; _ItemNo: Code[20])
    var
        MobToolbox: Codeunit "MOB Toolbox";
        MobWmsLanguage: Codeunit "MOB WMS Language";
    begin
        Create_TextStep(_Id, 'Barcode', false);
        Set_header(MobWmsLanguage.GetMessage('ITEM') + ' ' + _ItemNo + ' - ' + MobWmsLanguage.GetMessage('SCAN_BARCODE'));
        Set_label(MobWmsLanguage.GetMessage('ITEM_BARCODE') + ':');
        Set_eanAi(MobToolbox.GetItemNoGS1Ai());
        Set_length(50);     //50=length of Item Reference when accepting barcode
        Save();
    end;

    procedure Create_TextStep_ItemNumber(_Id: Integer)
    var
        MobToolbox: Codeunit "MOB Toolbox";
        MobWmsLanguage: Codeunit "MOB WMS Language";
    begin
        Create_TextStep(_Id, 'ItemNumber', false);
        Set_header(MobWmsLanguage.GetMessage('ITEM') + ' - ' + MobWmsLanguage.GetMessage('SCAN_BARCODE'));
        Set_label(MobWmsLanguage.GetMessage('ITEM_BARCODE') + ':');
        Set_eanAi(MobToolbox.GetItemNoGS1Ai());
        Set_length(50);     //50=length of Item Reference when accepting barcode
        Save();
    end;

    procedure Create_TextStep_Bin(_Id: Integer; _LocationCode: Code[10]; _ItemNo: Code[20]; _VariantCode: Code[10])
    var
        MobToolbox: Codeunit "MOB Toolbox";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
    begin
        Create_TextStep(_Id, 'Bin', false);
        if _ItemNo <> '' then begin
            Set_header(MobWmsLanguage.GetMessage('ITEM') + ' ' + _ItemNo + ' - ' + MobWmsLanguage.GetMessage('SELECT_BIN'));
            Set_helpLabel(MobWmsLanguage.GetMessage('DEFAULT') + ': ' + MobWmsToolbox.GetDefaultBin(_ItemNo, _LocationCode, _VariantCode));
        end else
            Set_header(MobWmsLanguage.GetMessage('SELECT_BIN'));
        Set_label(MobWmsLanguage.GetMessage('BIN') + ':');
        Set_eanAi(MobToolbox.GetBinGS1Ai());
        Set_length(20);
        Save();
    end;

    procedure Create_TextStep_ToBin(_Id: Integer; _ItemNo: Code[20])
    var
        MobToolbox: Codeunit "MOB Toolbox";
        MobWmsLanguage: Codeunit "MOB WMS Language";
    begin
        Create_TextStep(_Id, 'ToBin', false);
        Set_header(MobWmsLanguage.GetMessage('ITEM') + ' ' + _ItemNo + ' - ' + MobWmsLanguage.GetMessage('SCAN_TO_BIN'));
        Set_label(MobWmsLanguage.GetMessage('TO_BIN_LABEL') + ':');
        Set_eanAi(MobToolbox.GetBinGS1Ai());
        Set_length(20);
        Save();
    end;

    procedure Create_TextStep_ToBin(_Id: Integer)
    var
        MobToolbox: Codeunit "MOB Toolbox";
        MobWmsLanguage: Codeunit "MOB WMS Language";
    begin
        Create_TextStep(_Id, 'ToBin', false);
        Set_header(MobWmsLanguage.GetMessage('SCAN_TO_BIN'));
        Set_label(MobWmsLanguage.GetMessage('TO_BIN_LABEL') + ':');
        Set_eanAi(MobToolbox.GetBinGS1Ai());
        Set_length(20);
        Save();
    end;

    procedure Create_TextStep_FromBinOrLP(_Id: Integer; _LocationCode: Code[10]; _ItemNo: Code[20]; _VariantCode: Code[10])
    var
        MobToolbox: Codeunit "MOB Toolbox";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
    begin
        Create_TextStep(_Id, 'FromBinOrLP', false);
        Set_header(MobWmsLanguage.GetMessage('SCAN_FROM_BIN_OR_LP'));
        Set_label(MobWmsLanguage.GetMessage('FROM_BIN_LABEL') + ' / ' + MobWmsLanguage.GetMessage('LICENSEPLATE') + ':');
        Set_helpLabel(MobWmsLanguage.GetMessage('DEFAULT') + ': ' + MobWmsToolbox.GetDefaultBin(_ItemNo, _LocationCode, _VariantCode));
        Set_eanAi(MobToolbox.GetBinGS1Ai() + ',' + MobToolbox.GetLicensePlateNoGS1Ai());
        Set_length(20);
        Save();
    end;

    procedure Create_TextStep_ToBinOrLP(_Id: Integer)
    var
        MobToolbox: Codeunit "MOB Toolbox";
        MobWmsLanguage: Codeunit "MOB WMS Language";
    begin
        Create_TextStep(_Id, 'ToBinOrLP', false);
        Set_header(MobWmsLanguage.GetMessage('SCAN_TO_BIN') + ' / ' + MobWmsLanguage.GetMessage('LICENSEPLATE'));
        Set_label(MobWmsLanguage.GetMessage('TO_BIN_LABEL') + ' / ' + MobWmsLanguage.GetMessage('LICENSEPLATE') + ':');
        Set_eanAi(MobToolbox.GetBinGS1Ai() + ',' + MobToolbox.GetLicensePlateNoGS1Ai());
        Set_length(20);
        Save();
    end;

    procedure Create_TextStep_LotNumber(_Id: Integer; _ItemNo: Code[20])
    var
        MobTrackingSetup: Record "MOB Tracking Setup";
        MobToolbox: Codeunit "MOB Toolbox";
        MobWmsLanguage: Codeunit "MOB WMS Language";
    begin
        Create_TextStep(_Id, 'LotNumber', false);
        Set_header(MobWmsLanguage.GetMessage('ITEM') + ' ' + _ItemNo + ' - ' + StrSubstNo(MobWmsLanguage.GetMessage('SCAN_X'), MobTrackingSetup.FieldCaption("Lot No.")));
        Set_label(MobWmsLanguage.GetMessage('LOT_NO_LABEL') + ':');
        Set_eanAi(MobToolbox.GetLotNoGS1Ai());
        Set_length(50);
        Save();
    end;

    procedure Create_TextStep_SerialNumber(_Id: Integer; _ItemNo: Code[20])
    var
        MobTrackingSetup: Record "MOB Tracking Setup";
        MobToolbox: Codeunit "MOB Toolbox";
        MobWmsLanguage: Codeunit "MOB WMS Language";
    begin
        Create_TextStep(_Id, 'SerialNumber', false);
        Set_header(MobWmsLanguage.GetMessage('ITEM') + ' ' + _ItemNo + ' - ' + StrSubstNo(MobWmsLanguage.GetMessage('SCAN_X'), MobTrackingSetup.FieldCaption("Serial No.")));
        Set_label(MobWmsLanguage.GetMessage('SERIAL_NO_LABEL') + ':');
        Set_eanAi(MobToolbox.GetSerialNoGS1Ai());
        Set_length(50);
        Save();
    end;

    /* #if BC18+ */
    procedure Create_TextStep_PackageNumber(_Id: Integer; _AutoSave: Boolean)
    var
        MobTrackingSetup: Record "Item Tracking Setup";
        MobToolbox: Codeunit "MOB Toolbox";
        MobWmsLanguage: Codeunit "MOB WMS Language";
    begin
        Create_TextStep(_Id, 'PackageNumber', false);
        Set_header(StrSubstNo(MobWmsLanguage.GetMessage('SCAN_X'), MobTrackingSetup.FieldCaption("Package No.")));
        Set_label(MobTrackingSetup.FieldCaption("Package No.") + ':');
        Set_eanAi(MobToolbox.GetPackageNoGS1Ai());
        Set_length(50);
        // Standard SerialNumber- and LotNumber-steps will prevent pre-populated default values from being changed (including when enherited from parent element)
        // However validationWarningType('Block') is not supported on custom Text steps -- therefore implemented as validationValues in MOB Package Management
        if _AutoSave then
            Save();

        MobFeatureTelemetryWrapper.LogUptakeUsedByPackageNo();
    end;

    procedure Create_TextStep_PackageNumber(_Id: Integer)
    begin
        Create_TextStep_PackageNumber(_Id, true);
    end;

    procedure Create_TextStep_PackageNumber(_Id: Integer; _ItemNo: Code[20]; _AutoSave: Boolean)
    var
        MobTrackingSetup: Record "MOB Tracking Setup";
        MobWmsLanguage: Codeunit "MOB WMS Language";
    begin
        Create_TextStep_PackageNumber(_Id, false);
        Set_header(MobWmsLanguage.GetMessage('ITEM') + ' ' + _ItemNo + ' - ' + StrSubstNo(MobWmsLanguage.GetMessage('SCAN_X'), MobTrackingSetup.FieldCaption("Package No.")));
        if _AutoSave then
            Save();
    end;

    procedure Create_TextStep_PackageNumber(_Id: Integer; _ItemNo: Code[20])
    begin
        Create_TextStep_PackageNumber(_Id, _ItemNo, true);
    end;
    /* #endif */

    procedure Create_TextStep_LicensePlate(_Id: Integer; _AutoSave: Boolean)
    var
        MobLicensePlate: Record "MOB License Plate";
        MobToolbox: Codeunit "MOB Toolbox";
        MobWmsLanguage: Codeunit "MOB WMS Language";
    begin
        Create_TextStep(_Id, 'LicensePlate', false);
        Set_header(StrSubstNo(MobWmsLanguage.GetMessage('SCAN_X'), MobWmsLanguage.GetMessage('LICENSEPLATE')));
        Set_label(MobLicensePlate.FieldCaption("No.") + ':');
        Set_eanAi(MobToolbox.GetLicensePlateNoGS1Ai());
        Set_length(20);
        if _AutoSave then
            Save();
    end;

    procedure Create_typeAndQuantityStepFromDataTable(_Id: Integer; _Name: Text; _Header: Text; _HelpLabel: Text; _InputFormat: Text; _ScanBehavior: Text; _EanAI: Text; _UniqueValues: Boolean; _DataTable: Text; _DataKeyColumn: Text; _DataDisplayColumn: Text)
    begin
        Create_typeAndQuantityStep(
            _Id,
            _Name,
            _Header,
            _HelpLabel,
            _InputFormat,
            _ScanBehavior,
            _EanAI,
            _UniqueValues,
            '');
        Set_dataTable(_DataTable);
        Set_dataKeyColumn(_DataKeyColumn);
        Set_dataDisplayColumn(_DataDisplayColumn);
    end;

    procedure Create_typeAndQuantityStepFromListValues(_Id: Integer; _Name: Text; _Header: Text; _HelpLabel: Text; _InputFormat: Text; _ScanBehavior: Text; _EanAI: Text; _UniqueValues: Boolean; _ListValues: Text)
    begin
        Create_typeAndQuantityStep(
            _Id,
            _Name,
            _Header,
            _HelpLabel,
            _InputFormat,
            _ScanBehavior,
            _EanAI,
            _UniqueValues,
            '');
        Set_listValues(_ListValues);
        Set_listSeparator(';');
    end;

    procedure Create_typeAndQuantityStep(_Id: Integer; _Name: Text; _Header: Text; _HelpLabel: Text; _InputFormat: Text; _ScanBehavior: Text; _EanAI: Text; _UniqueValues: Boolean; _DefaultValue: Text)
    begin
        // sample: 
        // <typeAndQuantity scanBehavior="Add" id="91" name="Quantity2" inputType="Decimal" header="@{RegistrationCollectorQuantityHeader}" label="" helpLabel="@{RegistrationCollectorQuantityHelpLabel}" optional="false" eanAi="310,30,37"/>
        Create(false);
        NodeName := 'typeAndQuantity';      // Override default value 'add'
        Set_inputType('Decimal');
        RC_Std_Parms(_Id, _Name, _Header, '', _HelpLabel);
        Set_inputFormat(_InputFormat);
        if _ScanBehavior = '' then
            Set_scanBehavior('Add')
        else
            Set_scanBehavior(_ScanBehavior);
        Set_eanAi(_EanAI);
        Set_uniqueValues(_UniqueValues);
        Set_defaultValue(_DefaultValue);    // ie. 'Type1=0;Type2=12'
        Save();
    end;

    procedure Create_typeAndQuantityStep(_Id: Integer; _Name: Text; _Header: Text)
    begin
        Create_typeAndQuantityStep(_Id, _Name);
        Set_header(_Header);
    end;

    procedure Create_typeAndQuantityStep(_Id: Integer; _Name: Text)
    begin
        Create_typeAndQuantityStep(_Id, _Name, true);
    end;

    procedure Create_typeAndQuantityStep(_Id: Integer; _Name: Text; _AutoSave: Boolean)
    begin
        Create(_AutoSave);
        NodeName := 'typeAndQuantity';
        Set_inputType('Decimal');
        RC_Std_Parms(_Id, _Name, '', '', '');
        Set_scanBehavior('Add');
    end;

    /// <summary>
    /// Add LotNumber, SerialNumber and PackageNumber steps if required by Item Tracking Setup.
    /// PackageNumber and custom dimensions supported via event.
    /// </summary>
    procedure Create_TrackingStepsIfRequired(var _MobTrackingSetup: Record "MOB Tracking Setup"; _NextId: Integer; _ItemNo: Code[20])
    begin
        Create_TrackingStepsIfRequired(_MobTrackingSetup, _NextId, _ItemNo, false);
    end;

    /// <summary>
    /// Add LotNumber, SerialNumber and PackageNumber steps if required by Item Tracking Setup.
    /// PackageNumber and custom dimensions supported via event.
    /// </summary>
    procedure Create_TrackingStepsIfRequired(var _MobTrackingSetup: Record "MOB Tracking Setup"; _NextId: Integer; _ItemNo: Code[20]; _SetStepValueOptional: Boolean)
    begin
        if _MobTrackingSetup."Serial No. Required" then begin
            Create_TextStep_SerialNumber(_NextId, _ItemNo);

            // Suggest existing value and make it optional so user can accept it as-is
            if _MobTrackingSetup."Serial No." <> '' then begin
                Set_defaultValue(_MobTrackingSetup."Serial No.");
                Set_optional(_SetStepValueOptional);
            end;
        end;

        if _MobTrackingSetup."Lot No. Required" then begin
            Create_TextStep_LotNumber(_NextId + 10, _ItemNo);

            // Suggest existing value and make it optional so user can accept it as-is
            if _MobTrackingSetup."Lot No." <> '' then begin
                Set_defaultValue(_MobTrackingSetup."Lot No.");
                Set_optional(_SetStepValueOptional);
            end;
        end;

        _NextId := _NextId + 10;
        OnAfterCreateStepsFromItemTrackingSetupIfRequired(_MobTrackingSetup, _NextId, _ItemNo, Rec);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateStepsFromItemTrackingSetupIfRequired(var _MobTrackingSetup: Record "MOB Tracking Setup"; var _NextId: Integer; _ItemNo: Code[20]; var _Steps: Record "MOB Steps Element")
    begin
    end;

}
