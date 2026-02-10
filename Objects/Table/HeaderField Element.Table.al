table 81397 "MOB HeaderField Element"
{
    Access = Public;
    Caption = 'MOB HeaderField Element', Locked = true;

    //
    // Android App: Default values from InputLineBaseConfiguration.cs
    // 
    // this.DataDisplayColumn = null;
    // this.DataKeyColumn = null;
    // this.DataTable = null;
    // this.DefaultValue = null;
    // this.DefaultTo = DefaultToType.FirstValue;
    // this.FilterColumn = null;
    // this.Id = -1;
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
    // Android App: Default values from HeaderLineConfigution.cs
    //
    // this.AcceptBarcode = true;
    // this.ClearOnClear = true;
    // this.Locked = false;
    // this.SearchType = null;    

    // 
    // BC only tags (introduced for consistency with steps, not to be written to Xml)
    // 
    // Visible = true

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
        // field(100; autoForwardAfterScan; Text[10])       // Only on Steps - field no. reserved
        // field(110; header; Text[100])                    // Only on Steps - field no. reserved

        // visible is not really supported for headerConfigurations, but included here for consistency of use (only record is not written to Xml is set)
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
        // field(260; editable; Text[10])                // Only on Steps - field no. reserved
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
        // field(290; helpLabel; Text[100])             // Only on Steps - field no. reserved
        // field(300; helpLabelMaximize; Text[10])      // Only on Steps - field no. reserved
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
        // field(420; overDeliveryValidation; Text[10])     // Only on Steps - field no. reserved
        // field(430; performCalculation; Text[10])         // Only on Steps - field no. reserved
        // field(440; primaryInputMethod; Text[50])         // Only on Steps - field no. reserved
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
        // field(470; uniqueValues; Text[10])               // Only on Steps - field no. reserved
        // field(480; validationCaseSensitive; Text[10])    // Only on Steps - field no. reserved
        field(490; validationValues; Text[250])
        {
            Caption = 'validationValues', Locked = true;
            DataClassification = SystemMetadata;
        }
        // field(500; validationWarningType; Text[10])      // Only on Steps - field no. reserved
        field(550; acceptBarcode; Text[10])
        {
            Caption = 'acceptBarcode', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(560; clearOnClear; Text[10])
        {
            Caption = 'clearOnClear', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(570; locked; Text[10])
        {
            Caption = 'locked', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(580; searchType; Text[50])
        {
            Caption = 'searchType', Locked = true;
            DataClassification = SystemMetadata;
        }
        // field(600; scanBehavior; Text[20])               // Only on Steps - field no. reserved

        /// <summary>
        /// Internal field used to order HeaderFields by numeric value of _Id 
        /// For HeaderFields only Sorting1 is implemented.
        /// </summary>
        /// <remarks>
        /// Cannot be Set_ directly, but is populated indirectly using Set_Id.
        /// Fields 800..999 are internal fields and is never syncronized or output.
        /// </remarks>
        field(810; "Sorting1 (internal)"; Code[250])
        {
            Caption = 'Sorting1 (internal)', Locked = true;
            DataClassification = SystemMetadata;
        }
    }
    keys
    {
        key(Key1; "Key")
        {
        }

        key(ConfigurationIdKey1; ConfigurationKey, id)
        {
        }

        key(ConfigurationSortingKey1; ConfigurationKey, "Sorting1 (internal)")
        {
        }
    }

    var
        MobToolbox: Codeunit "MOB Toolbox";
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
        NsElementMgt: Codeunit "MOB NS Element Management";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        MobReferenceData: Codeunit "MOB WMS Reference Data";
        AutoSave: Boolean;
        LastSetConfigurationKey: Text[50];
        MustCallInitNext: Boolean;
        MUST_BE_TEMPORARY_Err: Label 'Internal error: %1 must be a temporary record.', Locked = true;
        INIT_NEVER_CALLED_Err: Label 'Internal error: _HeaderField.InitConfigurationKey() was never called.', Locked = true;
        InvalidHeaderFieldNameErr: Label 'Invalid HeaderField name="%1": %2', Comment = '%1 contains headerfield name, %2 contains last error text', Locked = true;
        CustomerPONumber_400_Txt: Label '400', Locked = true;

    trigger OnDelete()
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Rec);
        NsElementMgt.DeleteValues(RecRef); // Doesn't work if called through DeleteAll. Handled in Create procedure
    end;

    procedure InitConfigurationKey(_Key: Text)
    begin
        InitConfigurationKey(_Key, true);
    end;

    procedure InitConfigurationKey(_Key: Text; _AutoSave: Boolean)
    begin
        LastSetConfigurationKey := _Key;
        Create(_AutoSave);
    end;

    procedure InitConfigurationKey_AddCountLineHeader()
    begin
        InitConfigurationKey('AddCountLineHeader', true);
    end;

    procedure InitConfigurationKey_AdjustQtyToAssembleHeader()
    begin
        InitConfigurationKey('AdjustQtyToAssembleHeader', true);
    end;

    procedure InitConfigurationKey_AdjustQuantityHeader()
    begin
        InitConfigurationKey('AdjustQuantityHeader', true);
    end;

    procedure InitConfigurationKey_AssemblyOrderFilters()
    begin
        InitConfigurationKey('AssemblyOrderFilters', true);
    end;

    procedure InitConfigurationKey_AttachmentsHeader()
    begin
        InitConfigurationKey('AttachmentsHeader', true);
    end;

    procedure InitConfigurationKey_BinContentCfgHeader()
    begin
        InitConfigurationKey('BinContentCfgHeader', true);
    end;

    procedure InitConfigurationKey_BulkMoveHeader()
    begin
        InitConfigurationKey('BulkMoveHeader', true);
    end;

    procedure InitConfigurationKey_CreateAssemblyOrderHeader()
    begin
        InitConfigurationKey('CreateAssemblyOrderHeader', true);
    end;

    procedure InitConfigurationKey_ItemCrossReferenceHeader()
    begin
        InitConfigurationKey('ItemCrossReferenceHeader', true);
    end;

    procedure InitConfigurationKey_ItemDimensionsHeader()
    begin
        InitConfigurationKey('ItemDimensionsHeader', true);
    end;

    procedure InitConfigurationKey_LocateItemCfgHeader()
    begin
        InitConfigurationKey('LocateItemCfgHeader', true);
    end;

    procedure InitConfigurationKey_MoveOrderFilters()
    begin
        InitConfigurationKey('MoveOrderFilters', true);
    end;

    procedure InitConfigurationKey_PickOrderFilters()
    begin
        InitConfigurationKey('PickOrderFilters', true);
    end;

    procedure InitConfigurationKey_PostShipmentCfgHeader()
    begin
        InitConfigurationKey('PostShipmentCfgHeader', true);
    end;

    procedure InitConfigurationKey_PrintLabelHeader()
    begin
        InitConfigurationKey('PrintLabelHeader', true);
    end;

    procedure InitConfigurationKey_PrintLabelTemplateHeader()
    begin
        InitConfigurationKey('PrintLabelTemplateHeader', true);
    end;

    procedure InitConfigurationKey_PrintLabelTemplateMenuItemHeader()
    begin
        InitConfigurationKey('PrintLabelTemplateMenuItemHeader', true);
    end;

    procedure InitConfigurationKey_PrintLabelTemplateLicensePlateHeader()
    begin
        InitConfigurationKey('PrintLabelTemplateLicensePlateHeader', true);
    end;

    procedure InitConfigurationKey_ProdOrderLineFilters()
    begin
        InitConfigurationKey('ProdOrderLineFilters', true);
    end;

    procedure InitConfigurationKey_ProdOutputActionHeader()
    begin
        InitConfigurationKey('ProdOutputActionHeader', true);
    end;

    procedure InitConfigurationKey_ProdOutputHeader()
    begin
        InitConfigurationKey('ProdOutputHeader', true);
    end;

    procedure InitConfigurationKey_PutAwayOrderFilters()
    begin
        InitConfigurationKey('PutAwayOrderFilters', true);
    end;

    procedure InitConfigurationKey_ReceiveOrderFilters()
    begin
        InitConfigurationKey('ReceiveOrderFilters', true);
    end;

    procedure InitConfigurationKey_RegisterImageHeader()
    begin
        InitConfigurationKey('RegisterImageHeader', true);
    end;

    procedure InitConfigurationKey_RegisterItemImageHeader()
    begin
        InitConfigurationKey('RegisterItemImageHeader', true);
    end;

    procedure InitConfigurationKey_ShipOrderFilters()
    begin
        InitConfigurationKey('ShipOrderFilters', true);
    end;

    procedure InitConfigurationKey_SubstituteItemsCfgHeader()
    begin
        InitConfigurationKey('SubstituteItemsCfgHeader', true);
    end;

    procedure InitConfigurationKey_SubstituteProdOrderComponentHeader()
    begin
        InitConfigurationKey('SubstituteProdOrderComponentHeader', true);
    end;

    procedure InitConfigurationKey_ToteShippingHeader()
    begin
        InitConfigurationKey('ToteShippingHeader', true);
    end;

    procedure InitConfigurationKey_UnplannedCountHeader()
    begin
        InitConfigurationKey('UnplannedCountHeader', true);
    end;

    procedure InitConfigurationKey_UnplannedMoveHeader()
    begin
        InitConfigurationKey('UnplannedMoveHeader', true);
    end;

    procedure InitConfigurationKey_UnplannedMoveAdvancedHeader()
    begin
        InitConfigurationKey('UnplannedMoveAdvancedHeader', true);
    end;

    procedure InitConfigurationKey_LicensePlateHeader()
    begin
        InitConfigurationKey('LicensePlateHeader', true);
    end;

    procedure InitConfigurationKey_PutAwayLicensePlateHeader()
    begin
        InitConfigurationKey('PutAwayLicensePlateHeader', true);
    end;

    procedure InitConfigurationKey_RegisterPutAwayLicensePlateHeader()
    begin
        InitConfigurationKey('RegisterPutAwayLicensePlateHeader', true);
    end;

    procedure InitConfigurationKey_AddLicensePlateHeader()
    begin
        InitConfigurationKey('AddLicensePlateHeader', true);
    end;

    procedure InitConfigurationKey_CreateLicensePlateHeader()
    begin
        InitConfigurationKey('CreateLicensePlateHeader', true);
    end;

    procedure InitConfigurationKey_AllToNewLicensePlateHeader()
    begin
        InitConfigurationKey('AllToNewLicensePlateHeader', true);
    end;

    procedure InitConfigurationKey_AllContentToNewLicensePlateHeader()
    begin
        InitConfigurationKey('AllContentToNewLicensePlateHeader', true);
    end;

    procedure InitConfigurationKey_PackagesToShipHeader()
    begin
        InitConfigurationKey('PackagesToShipHeader', true);
    end;

    procedure InitConfigurationKey_BulkRegPackageInfoHeader()
    begin
        InitConfigurationKey('BulkRegPackageInfoHeader', true);
    end;

    procedure InitConfigurationKey_HistoryHeader()
    begin
        InitConfigurationKey('HistoryHeader', true);
    end;

    // low level create with no inputType
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
        Insert();

        // Make sure all existing values in Mob Node Value Buffer is cleared. Values may hang if step was deleted with DeleteAll
        RecRef.GetTable(Rec);
        NsElementMgt.DeleteValues(RecRef);

        AutoSave := _AutoSave;
        MustCallInitNext := false;
    end;

    /// <summary>
    /// Save (modify) current Steps Element. Must be called every time a Steps Element has all values set, to persist changes.
    /// </summary>
    procedure Save()
    begin
        if MustCallInitNext then
            Error(INIT_NEVER_CALLED_Err);

        TestField(Key);
        SyncronizeTableToBuffer();

        SetLinkedValuesOnSave();

        Modify();
        AutoSave := true;   // performance optimization only 'till first save -- subsequent Set'ters should autosave for less risk of errors
    end;

    local procedure SetLinkedValuesOnSave()
    begin
        // Add additional tags if never set
        if (Get_listValues() <> '') and (Get_listSeparator() = '') then
            Set_listSeparator(';');
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
    /// <param name="_TempElement">The HeaderField Element record to autoincrement (must be a temporary record)</param>
    local procedure AutoIncrementKey(var _TempElement: Record "MOB HeaderField Element")
    var
        TempElement2: Record "MOB HeaderField Element" temporary;
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

    internal procedure SetValue(_FieldNo: Integer; _PathToSet: Text; _NewValue: Text)
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

    internal procedure SetValueAsCData(_FieldNo: Integer; _PathToSet: Text; _NewCDataValue: Text)
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

    procedure SetMustCallInitNext(_NewValue: Boolean)
    var
    begin
        MustCallInitNext := _NewValue;
    end;

    /// <summary>
    /// Syncronize current Stepsl Element record  to internal NodeValue Buffer. All text fields are syncronized excluding field no. range 800..999.
    /// Oneway syncronization from table to buffer hance no return value by SetTable.
    /// </summary>
    internal procedure SyncronizeTableToBuffer()
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Rec);
        NsElementMgt.SyncronizeTableToBuffer(RecRef);
    end;

    // ----------------------
    // Mandatory
    // ----------------------

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
    var
        IdAsInteger: Integer;
    begin
        SetValue(FieldNo(id), FieldName(id), _NewValue);

        // For HeadeFields only Sorting1 is implemented and always for Id numeric value
        if Evaluate(IdAsInteger, _NewValue) then
            Set_Sorting1(IdAsInteger)
        else
            Set_Sorting1(0);
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
            Error(InvalidHeaderFieldNameErr, _NewValue, GetLastErrorText());
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

    // ----------------------
    // Optional [O] all
    // ----------------------

    procedure Set_visible(_NewValue: Boolean)
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

    // ----------------------
    // Limited applicability
    // ----------------------

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

    procedure Set_defaultValue(_NewValue: Date)
    begin
        Set_defaultValue(MobToolbox.Date2TextResponseFormat(_NewValue));
    end;

    procedure Set_defaultValue(_TrueFalseExpression: Boolean; _NewValueTrue: Date; _NewValueFalse: Date)
    begin
        if _TrueFalseExpression then
            Set_defaultValue(_NewValueTrue)
        else
            Set_defaultValue(_NewValueFalse);
    end;

    procedure Set_defaultValue(_TrueFalseExpression: Boolean; _NewValueTrue: Text; _NewValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_defaultValue(_NewValueTrue)
        else
            Set_defaultValue(_NewValueFalse);
    end;

    procedure Set_defaultValue(_NewValue: Decimal)
    begin
        Set_defaultValue(MobWmsToolbox.Decimal2TextAsXmlFormat(_NewValue));
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
    begin
        Set_maxValue(MobWmsToolbox.Decimal2TextAsXmlFormat(_NewValue));
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
    begin
        Set_minValue(MobWmsToolbox.Decimal2TextAsXmlFormat(_NewValue));
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
    // HeaderLineConfiguration.cs  (do not exists at Steps)
    //

    procedure Set_acceptBarcode(_NewValue: Boolean)
    begin
        Set_acceptBarcode(MobWmsToolbox.Bool2Text(_NewValue));
    end;

    procedure Set_acceptBarcode(_NewValue: Text)
    begin
        SetValue(FieldNo(acceptBarcode), FieldName(acceptBarcode), _NewValue);
    end;

    procedure Get_acceptBarcode(): Text
    begin
        exit(GetValue(FieldNo(acceptBarcode), FieldName(acceptBarcode), false));
    end;

    procedure Set_clearOnClear(_NewValue: Boolean)
    begin
        Set_clearOnClear(MobWmsToolbox.Bool2Text(_NewValue));
    end;

    procedure Set_clearOnClear(_NewValue: Text)
    begin
        SetValue(FieldNo(clearOnClear), FieldName(clearOnClear), _NewValue);
    end;

    procedure Get_clearOnClear(): Text
    begin
        exit(GetValue(FieldNo(clearOnClear), FieldName(clearOnClear), false));
    end;

    procedure Set_locked(_NewValue: Boolean)
    begin
        Set_locked(MobWmsToolbox.Bool2Text(_NewValue));
    end;

    procedure Set_locked(_NewValue: Text)
    begin
        SetValue(FieldNo(locked), FieldName(locked), _NewValue);
    end;

    procedure Get_locked(): Text
    begin
        exit(GetValue(FieldNo(locked), FieldName(locked), false));
    end;

    procedure Set_searchType(_NewValue: Text)
    begin
        SetValue(FieldNo(searchType), FieldName(searchType), _NewValue);
    end;

    procedure Set_searchType(_TrueFalseExpression: Boolean; _NewValueTrue: Text; _NewValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_searchType(_NewValueTrue)
        else
            Set_searchType(_NewValueFalse);
    end;

    procedure Get_searchType(): Text
    begin
        exit(GetValue(FieldNo(searchType), FieldName(searchType), false));
    end;

    //
    // Legacy support: Windows Mobile and Window Mobile Embedded
    // 
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

    procedure Set_labelWidth_WindowsMobile(_NewValue: Integer)
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
    begin
        Set_resolutionHeight_WindowsMobile(MobWmsToolbox.Integer2TextAsXmlFormat(_NewValue));
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
    begin
        Set_resolutionWidth_WindowsMobile(MobWmsToolbox.Integer2TextAsXmlFormat(_NewValue));
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

    /// <summary>
    /// Set_Sorting1 to indirectly set "Sorting"-tag in the xml file.
    /// For HeaderFields only Sorting1 is implemented and always for Id numeric value.
    /// </summary>
    procedure Set_Sorting1(_NewValue: Integer)
    begin
        SetValue(FieldNo("Sorting1 (internal)"), FieldName("Sorting1 (internal)"), MobWmsToolbox.Int2Sorting(_NewValue, MaxStrLen("Sorting1 (internal)")));
    end;

    //
    // Default values
    //
    local procedure RC_Std_Parms(_Id: Integer; _Name: Text; _Label: Text)

    begin
        // Use this function to set the standard parameters for all step types
        // It initializes the advanced parameters to it's default values

        // Standard parameters for all steps
        Set_id(_Id);
        Set_name(_Name);
        if _Label <> '' then
            Set_label(_Label);

        // Default values and tags that are mandatory on Windows Mobile
        Set_labelWidth_WindowsMobile(100);
        Set_optional(false);
        Set_acceptBarcode(true);
        Set_clearOnClear(true);

        //
        // Android App: Default values (At time of writing version 1.5.5)
        // 
        // optional = false
        // acceptBarcode = true
        // clearOnClear = true

        // visible is not really supported for headerConfigurations, but included here for consistency of use (only record is not written to Xml is set)
        Set_visible(true);
    end;

    //
    // Steps Library: Create Methods for all inputTypes
    //

    // Add a simple list step with data from a table sent out as reference data
    procedure Create_ListFieldFromDataTable(_Id: Integer; _Name: Text; _Label: Text; _DataTable: Text; _DataKeyColumn: Text; _DataDisplayColumn: Text; _DefaultValue: Text)
    begin
        Create(false);
        Set_inputType('List');
        RC_Std_Parms(_Id, _Name, _Label);
        Set_dataTable(_DataTable);
        Set_dataKeyColumn(_DataKeyColumn);
        Set_dataDisplayColumn(_DataDisplayColumn);
        Set_defaultValue(_DefaultValue);
        Save();
    end;

    procedure Create_ListFieldFromListValues(_Id: Integer; _Name: Text; _Label: Text; _ListValues: Text; _DefaultValue: Text)
    begin
        Create(false);
        Set_inputType('List');
        RC_Std_Parms(_Id, _Name, _Label);
        Set_listValues(_ListValues);
        Set_defaultValue(_DefaultValue);
        Save();
    end;

    procedure Create_ListField(_Id: Integer; _Name: Text; _Label: Text)
    begin
        Create_ListField(_Id, _Name);
        Set_label(_Label);
    end;

    procedure Create_ListField(_Id: Integer; _Name: Text)
    begin
        Create_ListField(_Id, _Name, true);
    end;

    procedure Create_ListField(_Id: Integer; _Name: Text; _AutoSave: Boolean)
    begin
        Create(_AutoSave);
        Set_inputType('List');
        RC_Std_Parms(_Id, _Name, '');
    end;

    procedure Create_TextField(_Id: Integer; _Name: Text; _Label: Text; _DefaultValue: Text; _Length: Integer)
    begin
        Create(false);
        Set_inputType('Text');
        RC_Std_Parms(_Id, _Name, _Label);
        Set_defaultValue(_DefaultValue);
        Set_length(_Length);
        Save();
    end;

    procedure Create_TextField(_Id: Integer; _Name: Text; _Label: Text)
    begin
        Create_TextField(_Id, _Name);
        Set_label(_Label);
    end;

    procedure Create_TextField(_Id: Integer; _Name: Text)
    begin
        Create_TextField(_Id, _Name, true);
    end;

    procedure Create_TextField(_Id: Integer; _Name: Text; _AutoSave: Boolean)
    begin
        Create(_AutoSave);
        Set_inputType('Text');
        RC_Std_Parms(_Id, _Name, '');
    end;

    procedure Create_IntegerField(_Id: Integer; _Name: Text; _Label: Text; _DefaultValue: Integer; _MinValue: Integer; _MaxValue: Integer; _Length: Decimal; _PerformCalculation: Boolean)
    begin
        Create(false);
        Set_inputType('Integer');
        RC_Std_Parms(_Id, _Name, _Label);
        Set_defaultValue(_DefaultValue);
        Set_minValue(_MinValue);
        Set_maxValue(_MaxValue);
        Set_length(_Length);
        Save();
    end;

    procedure Create_IntegerField(_Id: Integer; _Name: Text; _Label: Text)
    begin
        Create_IntegerField(_Id, _Name);
        Set_label(_Label);
    end;

    procedure Create_IntegerField(_Id: Integer; _Name: Text)
    begin
        Create_IntegerField(_Id, _Name, true);
    end;

    procedure Create_IntegerField(_Id: Integer; _Name: Text; _AutoSave: Boolean)
    begin
        Create(_AutoSave);
        Set_inputType('Integer');
        RC_Std_Parms(_Id, _Name, '');
    end;

    procedure Create_DecimalField(_Id: Integer; _Name: Text; _Label: Text; _DefaultValue: Decimal; _MinValue: Decimal; _MaxValue: Decimal; _Length: Decimal; _PerformCalculation: Boolean)
    begin
        Create(false);
        Set_inputType('Decimal');
        RC_Std_Parms(_Id, _Name, _Label);
        Set_defaultValue(_DefaultValue);
        Set_minValue(_MinValue);
        Set_maxValue(_MaxValue);
        Set_length(_Length);
        Save();
    end;

    procedure Create_DecimalField(_Id: Integer; _Name: Text; _Label: Text)
    begin
        Create_DecimalField(_Id, _Name);
        Set_label(_Label);
    end;

    procedure Create_DecimalField(_Id: Integer; _Name: Text)
    begin
        Create_DecimalField(_Id, _Name, true);
    end;

    procedure Create_DecimalField(_Id: Integer; _Name: Text; _AutoSave: Boolean)
    begin
        Create(_AutoSave);
        Set_inputType('Decimal');
        RC_Std_Parms(_Id, _Name, '');
    end;

    procedure Create_DateField(_Id: Integer; _Name: Text; _Label: Text; _DefaultValue: Date; _Format: Text; _MinDate: Date; _MaxDate: Date)
    begin
        Create(false);
        Set_inputType('Date');
        RC_Std_Parms(_Id, _Name, _Label);
        Set_defaultValue(MobToolbox.Date2TextResponseFormat(_DefaultValue));
        Set_format_WindowsMobile(_Format);
        Set_minDate(_MinDate);
        Set_maxDate(_MaxDate);
        Save();
    end;

    procedure Create_DateField(_Id: Integer; _Name: Text; _Label: Text)
    begin
        Create_DateField(_Id, _Name);
        Set_label(_Label);
    end;

    procedure Create_DateField(_Id: Integer; _Name: Text)
    begin
        Create_DateField(_Id, _Name, true);
    end;

    procedure Create_DateField(_Id: Integer; _Name: Text; _AutoSave: Boolean)
    begin
        Create(_AutoSave);
        Set_inputType('Date');
        RC_Std_Parms(_Id, _Name, '');
    end;

    procedure Create_DateTimeField(_Id: Integer; _Name: Text; _Label: Text; _DefaultValue: Text; _Format: Text; _MinDate: Date; _MaxDate: Date)
    begin
        Create(false);
        Set_inputType('DateTime');
        RC_Std_Parms(_Id, _Name, _Label);
        Set_defaultValue(_DefaultValue);
        Set_format_WindowsMobile(_Format);
        Set_minDate(_MinDate);
        Set_maxDate(_MaxDate);
        Save();
    end;

    procedure Create_DateTimeField(_Id: Integer; _Name: Text; _Label: Text)
    begin
        Create_DateTimeField(_Id, _Name);
        Set_label(_Label);
    end;

    procedure Create_DateTimeField(_Id: Integer; _Name: Text)
    begin
        Create_DateTimeField(_Id, _Name, true);
    end;

    procedure Create_DateTimeField(_Id: Integer; _Name: Text; _AutoSave: Boolean)
    begin
        Create(_AutoSave);
        Set_inputType('DateTime');
        RC_Std_Parms(_Id, _Name, '');
    end;

    //
    // Fields Library: Templates
    //
    // If new Create-methods are added a Get-method should be added to NS Request Element as well

    procedure Create_DateField_ExpirationDate(_Id: Integer)
    begin
        Create_DateField(_Id, 'ExpirationDate', false);
        Set_label(MobWmsLanguage.GetMessage('EXP_DATE_LABEL') + ':');
        Set_clearOnClear(false);
        Set_eanAi(MobToolbox.GetExpirationDateGS1Ai());
        Save();
    end;

    procedure Create_DateField_ExpRecvDateAsDate(_Id: Integer)
    begin
        Create_DateField(_Id, 'Date', false);
        Set_label(MobWmsLanguage.GetMessage('EXP_RECV_DATE') + ':');
        Set_acceptBarcode(false);
        Set_clearOnClear(false);
        Save();
    end;

    procedure Create_DateField_ShipmentDateAsDate(_Id: Integer)
    begin
        Create_DateField(_Id, 'Date', false);
        Set_label(MobWmsLanguage.GetMessage('SHIPMT_DATE') + ':');
        Set_acceptBarcode(false);
        Set_clearOnClear(false);
        Save();
    end;

    procedure Create_DateField_StartingDate(_Id: Integer)
    begin
        Create_DateField(_Id, 'StartingDate', false);
        Set_label(MobWmsLanguage.GetMessage('STARTING_DATE') + ':');
        Set_acceptBarcode(false);
        Set_clearOnClear(false);
        Save();
    end;

    procedure Create_IntegerField_Quantity(_Id: Integer)
    begin
        Create_IntegerField(_Id, 'Quantity', false);
        Set_label(MobWmsLanguage.GetMessage('QUANTITY') + ':');
        Set_minValue(0);
        Set_eanAi(MobToolbox.GetQuantityGS1Ai());
        Save();
    end;

    procedure Create_IntegerField_Quantity_NoAcceptBarcode(_Id: Integer)
    begin
        Create_IntegerField(_Id, 'Quantity', false);
        Set_label(MobWmsLanguage.GetMessage('QUANTITY') + ':');
        Set_minValue(0);
        Set_acceptBarcode(false);
        Save();
    end;

    procedure Create_ListField_AssignedUserFilterAsAssignedUser(_Id: Integer)
    begin
        Create_ListField(_Id, 'AssignedUser', false);
        Set_label(MobWmsLanguage.GetMessage('ASSIGNED_USER_ID') + ':');
        Set_dataTable(MobReferenceData.DataTable_ASSIGNED_USER_FILTER_TABLE());
        Set_dataKeyColumn('Code');
        Set_dataDisplayColumn('Name');
        Set_acceptBarcode(false);
        Save();
    end;

    procedure Create_ListField_ItemCategory(_Id: Integer)
    begin
        Create_ListField(_Id, 'ItemCategory', false);
        Set_label(MobWmsLanguage.GetMessage('ITEM_CATEGORY') + ':');
        Set_dataTable(MobReferenceData.DataTable_ITEM_CATEGORY_TABLE());
        Set_dataKeyColumn('Code');
        Set_dataDisplayColumn('Name');
        Set_optional(true);
        Save();
    end;

    procedure Create_ListField_Location(_Id: Integer)
    begin
        Create_ListField(_Id, 'Location', false);
        Set_label(MobWmsLanguage.GetMessage('LOCATION') + ':');
        Set_dataTable(MobReferenceData.DataTable_LOCATION_TABLE());
        Set_dataKeyColumn('Code');
        Set_dataDisplayColumn('Code');
        Set_acceptBarcode(false);
        Save();
    end;

    procedure Create_ListField_NewLocation(_Id: Integer)
    begin
        Create_ListField(_Id, 'NewLocation', false);
        Set_label(MobWmsLanguage.GetMessage('NEW_LOCATION') + ':');
        Set_dataTable(MobReferenceData.DataTable_LOCATION_TABLE());
        Set_dataKeyColumn('Code');
        Set_dataDisplayColumn('Code');
        Set_acceptBarcode(false);
        Save();
    end;

    procedure Create_ListField_FilterLocation(_Id: Integer)
    begin
        Create_ListField(_Id, 'FilterLocation', false);
        Set_label(MobWmsLanguage.GetMessage('LOCATION') + ':');
        Set_dataTable(MobReferenceData.DataTable_FILTER_LOCATION_TABLE());
        Set_dataKeyColumn('Code');
        Set_dataDisplayColumn('Code');
        Set_acceptBarcode(false);
        Save();
    end;

    procedure Create_ListField_YesNo(_Id: Integer; _Name: Text; _Label: Text; _DefaultValue: Boolean)
    begin
        Create_ListField(_Id, _Name, _Label);
        Set_listValues(MobWmsLanguage.GetMessage('YES_NO'));

        if _DefaultValue then
            Set_defaultValue(MobWmsLanguage.GetMessage('YES'))
        else
            Set_defaultValue(MobWmsLanguage.GetMessage('NO'));
    end;

    procedure Create_ListField_FilterLocationAsLocation(_Id: Integer)
    begin
        Create_ListField_FilterLocation(_Id);
        Set_name('Location');
    end;

    procedure Create_ListField_FilterLocationAsLocationFilter(_Id: Integer)
    begin
        Create_ListField_FilterLocation(_Id);
        Set_name('LocationFilter');
    end;

    procedure Create_ListField_WorkCenterFilter(_Id: Integer)
    begin
        Create_ListField(_Id, 'WorkCenterFilter', false);
        Set_label(MobWmsLanguage.GetMessage('WORK_CENTER') + ':');
        Set_dataTable(MobReferenceData.DataTable_WORKCENTER_FILTER_TABLE());
        Set_dataKeyColumn('Code');
        Set_dataDisplayColumn('Name');
        Set_acceptBarcode(false);
        Save();
    end;

    procedure Create_ListField_ProductionProgress(_Id: Integer)
    begin
        Create_ListField(_Id, 'ProductionProgress', false);
        Set_label(MobWmsLanguage.GetMessage('PROGRESS') + ':');
        Set_dataTable(MobReferenceData.DataTable_PRODUCTION_PROGRESS_FILTER_TABLE());
        Set_dataKeyColumn('Code');
        Set_dataDisplayColumn('Name');
        Set_acceptBarcode(false);
        Save();
    end;

    procedure Create_ListField_ShipmentDocumentStatusFilter(_Id: Integer)
    begin
        Create_ListField(_Id, 'ShipmentDocumentStatusFilter', false);
        Set_label(MobWmsLanguage.GetMessage('SHIPMENT_DOCUMENT_STATUS') + ':');
        Set_dataTable(MobReferenceData.DataTable_SHIPMENT_DOCUMENT_STATUS_FILTER_TABLE());
        Set_dataKeyColumn('Code');
        Set_dataDisplayColumn('Name');
        Set_acceptBarcode(false);
        Save();
    end;

    procedure Create_ListField_UnitOfMeasure(_Id: Integer)
    begin
        Create_ListField(_Id, 'UnitOfMeasure', false);
        Set_label(MobWmsLanguage.GetMessage('UOM_LABEL') + ':');
        Set_dataTable(MobReferenceData.DataTable_UOM_TABLE());
        Set_dataKeyColumn('Code');
        Set_dataDisplayColumn('Code');
        Set_acceptBarcode(false);
        Set_clearOnClear(false);
        Save();
    end;

    procedure Create_TextField_Bin(_Id: Integer)
    begin
        Create_TextField(_Id, 'Bin', false);
        Set_label(MobWmsLanguage.GetMessage('BIN') + ':');
        Set_length(20);
        Set_searchType('BinSearch');
        Set_eanAi(MobToolbox.GetBinGS1Ai());
        Save();
    end;

    procedure Create_TextField_Bin_NoSearchType(_Id: Integer)
    begin
        Create_TextField(_Id, 'Bin', false);
        Set_label(MobWmsLanguage.GetMessage('BIN') + ':');
        Set_length(20);
        Set_eanAi(MobToolbox.GetBinGS1Ai());
        Save();
    end;

    procedure Create_TextField_FromBin(_Id: Integer)
    begin
        Create_TextField(_Id, 'FromBin', false);
        Set_label(MobWmsLanguage.GetMessage('FROM_BIN_LABEL') + ':');
        Set_length(20);
        Set_searchType('BinSearch');
        Set_eanAi(MobToolbox.GetBinGS1Ai());
        Save();
    end;

    procedure Create_TextField_FromBinOrLP(_Id: Integer)
    begin
        Create_TextField(_Id, 'FromBinOrLP', false);
        Set_label(MobWmsLanguage.GetMessage('BIN') + ' / ' + MobWmsLanguage.GetMessage('LICENSEPLATE') + ':');
        Set_length(20);
        Set_searchType('BinSearch');
        Set_eanAi(MobToolbox.GetItemNoGS1Ai() + ',' + MobToolbox.GetLicensePlateNoGS1Ai());
        Save();
    end;

    procedure Create_TextField_ItemDescription(_Id: Integer)
    begin
        Create_TextField(_Id, 'ItemDescription', false);
        Set_label(MobWmsLanguage.GetMessage('ITEM_Description') + ':');
        Set_length(30);
        Set_optional(true);
        Set_acceptBarcode(false);
        Save();
    end;

    procedure Create_TextField_ItemNumber(_Id: Integer)
    begin
        Create_TextField(_Id, 'ItemNumber', false);
        Set_label(MobWmsLanguage.GetMessage('ITEM') + ':');
        Set_length(50);     //50=length of Item Reference when accepting barcode
        Set_searchType('ItemSearch');
        Set_eanAi(MobToolbox.GetItemNoGS1Ai());
        Save();
    end;

    procedure Create_TextField_ItemNumberAsItem(_Id: Integer)
    begin
        Create_TextField(_Id, 'Item', false);
        Set_label(MobWmsLanguage.GetMessage('ITEM') + ':');
        Set_length(50);     //50=length of Item Reference when accepting barcode
        Set_searchType('ItemSearch');
        Set_eanAi(MobToolbox.GetItemNoGS1Ai());
        Save();
    end;

    procedure Create_TextField_ItemNumberAsItemNo_NoAcceptBarcode(_Id: Integer)
    begin
        Create_TextField(_Id, 'ItemNo', false);
        Set_label(MobWmsLanguage.GetMessage('ITEM') + ':');
        Set_length(20);     //length=20 when no accept barcode
        Set_optional(true);
        Set_acceptBarcode(false);
        Save();
    end;

    procedure Create_TextField_Number(_Id: Integer)
    begin
        Create_TextField(_Id, 'Number', false);
        Set_label(MobWmsLanguage.GetMessage('ITEM') + '/' + MobWmsLanguage.GetMessage('LICENSEPLATE') + ':');
        Set_length(50);     //50=length of Item Reference when accepting barcode
        Set_searchType('ItemSearch');
        Set_eanAi(MobToolbox.GetItemNoGS1Ai() + ',' + MobToolbox.GetLicensePlateNoGS1Ai());
        Save();
    end;

    procedure Create_TextField_LotNumber(_Id: Integer)
    begin
        Create_TextField(_Id, 'LotNumber', false);
        Set_label(MobWmsLanguage.GetMessage('LOT_NO_LABEL') + ':');
        Set_length(50);
        Set_eanAi(MobToolbox.GetLotNoGS1Ai());
        Save();
    end;

    procedure Create_TextField_SerialNumber(_Id: Integer)
    begin
        Create_TextField(_Id, 'SerialNumber', false);
        Set_label(MobWmsLanguage.GetMessage('SERIAL_NO_LABEL') + ':');
        Set_length(50);
        Set_eanAi(MobToolbox.GetSerialNoGS1Ai());
        Save();
    end;

    procedure Create_TextField_LicensePlate(_Id: Integer)
    begin
        Create_TextField(_Id, 'LicensePlate', false);
        Set_label(MobWmsLanguage.GetMessage('LICENSEPLATE') + ':');
        Set_length(20);
        Set_eanAi(MobToolbox.GetLicensePlateNoGS1Ai());
        Save();
    end;

    procedure Create_TextField_OrderBackendID(_Id: Integer)
    begin
        Create_TextField_OrderBackendID(_Id, true);
    end;

    procedure Create_TextField_OrderBackendID(_Id: Integer; _AutoSave: Boolean)
    begin
        Create_TextField(_Id, 'OrderBackendID', false);
        Set_label(MobWmsLanguage.GetMessage('ORDER_NUMBER') + ':');
        Set_length(40);
        Set_acceptBarcode(false);
        Set_clearOnClear(false);
        Set_locked(true);
        if _AutoSave then
            Save();
    end;

    procedure Create_TextField_BackendID(_Id: Integer)
    begin
        Create_TextField_BackendID(_Id, true);
    end;

    procedure Create_TextField_BackendID(_Id: Integer; _AutoSave: Boolean)
    begin
        Create_TextField(_Id, 'BackendID', false);
        Set_label(MobWmsLanguage.GetMessage('ORDER_NUMBER') + ':');
        Set_length(40);
        Set_acceptBarcode(false);
        Set_clearOnClear(false);
        Set_locked(true);
        if _AutoSave then
            Save();
    end;

    procedure Create_TextField_PurchaseOrderNumber(_Id: Integer)
    begin
        Create_TextField(_Id, 'PurchaseOrderNumber', false);
        Set_label(MobWmsLanguage.GetMessage('PO_NUMBER') + ':');
        Set_length(20);
        Set_optional(true);
        Set_eanAi(CustomerPONumber_400_Txt);
        Save();
    end;

    procedure Create_TextField_ShipmentNoFilter(_Id: Integer)
    begin
        Create_TextField(_Id, 'ShipmentNoFilter', false);
        Set_label(MobWmsLanguage.GetMessage('SHIPMENT') + ':');
        Set_length(20);
        Set_optional(true);
        Save();
    end;

    procedure Create_TextField_ReferenceID(_Id: Integer)
    begin
        Create_TextField(_Id, 'ReferenceID', false);
        Set_label(MobWmsLanguage.GetMessage('REFERENCE_ID') + ':');
        Set_length(250);
        Set_acceptBarcode(false);
        Set_clearOnClear(false);
        Set_locked(true);
        Save();
    end;

    procedure Create_TextField_ToBin(_Id: Integer)
    begin
        Create_TextField(_Id, 'ToBin', false);
        Set_label(MobWmsLanguage.GetMessage('TO_BIN_LABEL') + ':');
        Set_length(20);
        Set_searchType('BinSearch');
        Set_eanAi(MobToolbox.GetBinGS1Ai());
        Save();
    end;

    procedure Create_TextField_ToteID(_Id: Integer)
    begin
        Create_TextField(_Id, 'ToteID', false);
        Set_label(MobWmsLanguage.GetMessage('TOTE_ID') + ':');
        Set_length(100);
        Save();
    end;

    procedure Create_TextField_ShipmentNo(_Id: Integer)
    begin
        Create_TextField(_Id, 'BackendID', false);
        Set_label(MobWmsLanguage.GetMessage('SHIPMT_NO') + ':');
        Set_length(20);
        Set_acceptBarcode(false);
        Set_clearOnClear(false);
        Set_locked(true);
        Save();
    end;

    procedure Create_ListField_NoOfEntries(_Id: Integer)
    begin
        Create_ListField(_Id, 'NoOfEntries', false);
        Set_label(MobWmsLanguage.GetMessage('NO_OF_ENTRIES') + ':');
        Set_listValues('10;25;50;100');
        Save();
    end;
}
