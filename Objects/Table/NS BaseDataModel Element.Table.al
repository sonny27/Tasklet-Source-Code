table 81391 "MOB NS BaseDataModel Element"
{
    Access = Public;
    Caption = 'MOB NS BaseDataModel Element', Locked = true;

    fields
    {
        field(1; "Key"; Integer)
        {
            Caption = 'Key', Locked = true;
            DataClassification = SystemMetadata;
            AutoIncrement = true;       // Business Central 365 temporary tables not supported
        }
        field(10; BackendID; Text[20])
        {
            Caption = 'BackendID', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(20; OrderBackendID; Text[20])
        {
            Caption = 'OrderBackendID', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(30; LineNumber; Text[10])
        {
            Caption = 'LineNumber', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(40; FromBin; Text[20])
        {
            Caption = 'FromBin', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(50; ValidateFromBin; Text[10])
        {
            Caption = 'ValidateFromBin', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(60; ToBin; Text[20])
        {
            Caption = 'ToBin', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(70; ValidateToBin; Text[10])
        {
            Caption = 'ValidateToBin', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(80; AllowBinChange; Text[10])
        {
            Caption = 'AllowBinChange', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(100; ItemNumber; Text[20])
        {
            Caption = 'ItemNumber', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(110; ItemBarcode; Text[50])
        {
            Caption = 'ItemBarcode', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(120; Description; Text[20])
        {
            Caption = 'Description', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(150; RegisterSerialNumber; Text[10])
        {
            Caption = 'RegisterSerialNumber', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(160; RegisterLotNumber; Text[10])
        {
            Caption = 'RegisterLotNumber', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(165; RegisterPackageNumber; Text[10])
        {
            Caption = 'RegisterPackageNumber', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(170; RegisterExpirationDate; Text[10])
        {
            Caption = 'RegisterExpirationDate', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(180; RegisterQuantityByScan; Text[10])
        {
            Caption = 'RegisterQuantityByScan', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(190; BarcodeQuantity; Text[100])
        {
            Caption = 'BarcodeQuantity', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(200; SerialNumber; Text[20])
        {
            Caption = 'SerialNumber', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(210; LotNumber; Text[20])
        {
            Caption = 'LotNumber', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(212; PackageNumber; Text[50])
        {
            Caption = 'PackageNumber', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(215; ExpirationDate; Text[10])
        {
            Caption = 'ExpirationDate', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(220; Location; Code[10])
        {
            Caption = 'Location', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(240; Quantity; Text[20])
        {
            Caption = 'Quantity', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(250; RegisteredQuantity; Text[20])
        {
            Caption = 'RegisteredQuantity', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(260; UnitOfMeasure; Text[20])
        {
            Caption = 'UnitOfMeasure', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(270; Status; Text[1])
        {
            Caption = 'Status', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(275; Attachment; Text[1])
        {
            Caption = 'Attachment', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(280; "Sorting"; Text[10])
        {
            Caption = 'Sorting', Locked = true;
            DataClassification = SystemMetadata;
        }

        field(300; HeaderLabel1; Text[250])
        {
            Caption = 'HeaderLabel1', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(310; HeaderLabel2; Text[250])
        {
            Caption = 'HeaderLabel2', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(320; HeaderValue1; Text[250])
        {
            Caption = 'HeaderValue1', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(330; HeaderValue2; Text[250])
        {
            Caption = 'HeaderValue2', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(400; DisplayLine1; Text[250])
        {
            Caption = 'DisplayLine1', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(410; DisplayLine2; Text[250])
        {
            Caption = 'DisplayLine2', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(420; DisplayLine3; Text[250])
        {
            Caption = 'DisplayLine3', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(430; DisplayLine4; Text[250])
        {
            Caption = 'DisplayLine4', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(440; DisplayLine5; Text[250])
        {
            Caption = 'DisplayLine5', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(450; DisplayLine6; Text[250])
        {
            Caption = 'DisplayLine6', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(460; DisplayLine7; Text[250])
        {
            Caption = 'DisplayLine7', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(470; DisplayLine8; Text[250])
        {
            Caption = 'DisplayLine8', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(480; DisplayLine9; Text[250])
        {
            Caption = 'DisplayLine9', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(500; UnderDeliveryValidation; Text[10])
        {
            Caption = 'UnderDeliveryValidation', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(510; OverDeliveryValidation; Text[10])
        {
            Caption = 'OverDeliveryValidation', Locked = true;
            DataClassification = SystemMetadata;
        }

        field(550; TotePicking; Text[10])
        {
            Caption = 'TotePicking', Locked = true;
            DataClassification = SystemMetadata;
        }

        field(560; Destination; Text[20])
        {
            Caption = 'Destination', Locked = true;
            DataClassification = SystemMetadata;
        }

        field(570; Priority; Text[10])
        {
            Caption = 'Priority', Locked = true;
            DataClassification = SystemMetadata;
        }

        field(580; PriorityValidation; Text[10])
        {
            Caption = 'PriorityValidation', Locked = true;
            DataClassification = SystemMetadata;
        }

        /// <summary>
        /// Tag ItemImage, but field content really is ItemImageID. Get_'ers and Set_'ers is inconsistently (but intentionally) named ItemImageID
        /// </summary>
        field(520; ItemImage; Text[100])  // 
        {
            Caption = 'ItemImage', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(700; ReferenceID; Text[250])
        {
            Caption = 'ReferenceID', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(750; RewindToStepOnIncompleteLine; Text[50])
        {
            Caption = 'RewindToStepOnIncompleteLine', Locked = true;
            DataClassification = SystemMetadata;
        }

        /// <summary>
        /// Internal field used when generating values for tag "Sorting". 
        /// </summary>
        /// <remarks>
        /// Tag "Sorting" cannot be Set_ directly, but is populated indirectly using fields Set_Sorting1..Set_Sorting5.
        /// Fields 800..999 are internal fields and is never syncronized or output.
        /// </remarks>
        field(810; "Sorting1 (internal)"; Code[250])
        {
            Caption = 'Sorting1 (internal)', Locked = true;
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Internal field used when generating values for tag "Sorting". 
        /// </summary>
        /// <remarks>
        /// Tag "Sorting" cannot be Set_ directly, but is populated based on fields Sorting1..Sorting5.
        /// Fields 800..999 are internal fields and is never syncronized or output.
        /// </remarks>
        field(820; "Sorting2 (internal)"; Code[250])
        {
            Caption = 'Sorting2 (internal)', Locked = true;
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Internal field used when generating values for "Sorting". 
        /// </summary>
        /// <remarks>
        /// Tag "Sorting" cannot be Set_ directly, but is populated based on fields Sorting1..Sorting5.
        /// Fields 800..999 are internal fields and is never syncronized or output.
        /// </remarks>
        field(830; "Sorting3 (internal)"; Code[250])
        {
            Caption = 'Sorting3 (internal)', Locked = true;
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Internal field used when generating values for "Sorting". 
        /// </summary>
        /// <remarks>
        /// Tag "Sorting" cannot be Set_ directly, but is populated based on fields Sorting1..Sorting5.
        /// Fields 800..999 are internal fields and is never syncronized or output.
        /// </remarks>
        field(840; "Sorting4 (internal)"; Code[250])
        {
            Caption = 'Sorting4 (internal)', Locked = true;
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Internal field used when generating values for "Sorting". 
        /// </summary>
        /// <remarks>
        /// Tag "Sorting" cannot be Set_ directly, but is populated based on fields Sorting1..Sorting5.
        /// Fields 800..999 are internal fields and is never syncronized or output.
        /// </remarks>
        field(850; "Sorting5 (internal)"; Code[250])
        {
            Caption = 'Sorting5 (internal)', Locked = true;
            DataClassification = SystemMetadata;
        }

        /// <summary>
        /// Internal field used for adding "Group"-tags to xml. The output xml format is implicitely affected by the writer when this value is set.
        /// </summary>
        /// <remarks>
        /// Fields 800..999 are internal fields and is never syncronized or output.
        /// </remarks>
        field(860; "GroupBy1 (internal)"; Text[250])
        {
            Caption = 'GroupBy1 (internal)', Locked = true;
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Internal field used for adding "Group"-tags to xml. The output xml format is implicitely affected by the writer when this value is set.
        /// </summary>
        /// <remarks>
        /// Fields 800..999 are internal fields and is never syncronized or output.
        /// </remarks>
        field(870; "GroupByValues1 (internal)"; Text[250])
        {
            Caption = 'GroupByValues1 (internal)', Locked = true;
            DataClassification = SystemMetadata;
        }

        // Note: Field No cannot be > 100000 due to buffer sorting
    }

    keys
    {
        key(Key1; "Key")
        {
        }
        key(SortOrderKey1; "Sorting1 (internal)", "Sorting2 (internal)", "Sorting3 (internal)", "Sorting4 (internal)", "Sorting5 (internal)")
        {
        }
        key(GroupByAndSortingKey1; "GroupBy1 (internal)", "GroupByValues1 (internal)", "Sorting")
        {
        }
    }

    var
        NsElementMgt: Codeunit "MOB NS Element Management";
        MobTypeHelper: Codeunit "MOB Type Helper";
        MUST_BE_TEMPORARY_Err: Label 'Internal error: %1 must be a temporary record.', Locked = true;

    trigger OnDelete()
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Rec);
        NsElementMgt.DeleteValues(RecRef); // Doesn't work if called through DeleteAll. Handled in Create procedure
    end;

    /// <summary>
    /// Prepare current NS BaseDataModel Element to be used for buffer. Will populate Key and insert into DB. Method should always be called prior to calling Set-/Get-methods.
    /// </summary>
    /// <remarks>
    /// This initialization is needed, since buffer requires a Reference Key but autoincremented keys are not supported for Business Central 365 temporary tables.
    /// </remarks>
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

    /// <summary>
    /// Save (modify) current NS BaseDataModel Element and append to internal NsElementMgt NodeValue Buffer.
    /// Must be called every time a NS BaseDataModel Element has all values set, to persist changes.
    /// </summary>
    /// <remarks>Elements are linked to associated valuebuffer entries by Element.Key == ValueBuffer.ReferenceKey</remarks>
    procedure Save()
    begin
        TestField(Key);
        SyncronizeTableToBuffer();

        // Set "GroupByValues1 (internal)" only if new GroupBy has been defined or old GroupBy exists and may be cleared (avoid creating blank tag when element is reused for ie. LabelPrint)
        if HasValue(FieldName("GroupByValues1 (internal)")) or (GetGroupBy() <> '') then // 
            SetValue(FieldName("GroupByValues1 (internal)"), GetGroupByValues());

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
    /// <param name="_TempElement">The NS BaseDataModel Element record to autoincrement (must be a temporary record)</param>
    local procedure AutoIncrementKey(var _TempElement: Record "MOB NS BaseDataModel Element")
    var
        TempElement2: Record "MOB NS BaseDataModel Element" temporary;
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

    // ---------------------------------------------------------------
    // Redundant methods in namespace buffer tables supporting GroupBy
    // ---------------------------------------------------------------

    procedure SetGroupBy(_GroupBy: Text)
    begin
        SetValue(FieldNo("GroupBy1 (internal)"), FieldName("GroupBy1 (internal)"), _GroupBy);
    end;

    procedure GetGroupBy(): Text
    begin
        exit(GetValue(FieldNo("GroupBy1 (internal)"), FieldName("GroupBy1 (internal)"), false));
    end;

    local procedure GetGroupByValues(): Text
    var
        RecRef: RecordRef;
        GroupBy: Text;
    begin
        GroupBy := GetGroupBy();
        if GroupBy = '' then
            exit('');

        RecRef.GetTable(Rec);
        exit(NsElementMgt.GetGroupByValues(RecRef, Rec."Key", GroupBy));
    end;

    // ------------------------------------------------
    // Redundant methods in all namespace buffer tables
    // ------------------------------------------------

    procedure SetValue(_PathToSet: Text; _NewValue: Text)
    begin
        SetValue(0, _PathToSet, _NewValue);
    end;

    local procedure SetValue(_FieldNo: Integer; _FieldNameAsPathToSet: Text; _NewValue: Text)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Rec);
        NsElementMgt.SetValue(RecRef, Rec."Key", _FieldNameAsPathToSet, _NewValue, _FieldNo);
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

    local procedure SetValueAsCData(_FieldNo: Integer; _PathToSet: Text; _NewCDataValue: Text)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Rec);
        NsElementMgt.SetValueAsCData(RecRef, Rec."Key", _PathToSet, _NewCDataValue, _FieldNo);
        RecRef.SetTable(Rec);
    end;

    procedure SetTracking(var _MobTrackingSetup: Record "MOB Tracking Setup")
    begin
        _MobTrackingSetup.CopyTrackingToBaseOrderLine(Rec);
    end;

    procedure SetRegisterTracking(var _MobTrackingSetup: Record "MOB Tracking Setup")
    begin
        _MobTrackingSetup.CopyTrackingRequiredToBaseOrderLine(Rec);
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
        exit(GetValue(0, _PathToGet, false));
    end;

    local procedure GetValue(_FieldNo: Integer; _FieldNameAsPathToGet: Text; _ErrorIfNotExists: Boolean): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Rec);
        exit(NsElementMgt.GetValue(RecRef, Rec."Key", _FieldNameAsPathToGet, _FieldNo, _ErrorIfNotExists));
    end;

    procedure GetValueAsBoolean(_PathToGet: Text; _ErrorIfNotExists: Boolean): Boolean
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Rec);
        exit(NsElementMgt.GetValueAsBoolean(RecRef, Rec."Key", _PathToGet, 0, _ErrorIfNotExists));
    end;

    procedure GetValueAsDate(_PathToGet: Text; _ErrorIfNotExists: Boolean): Date
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Rec);
        exit(NsElementMgt.GetValueAsDate(RecRef, Rec."Key", _PathToGet, 0, _ErrorIfNotExists));
    end;

    procedure GetValueAsDateTime(_PathToGet: Text; _ErrorIfNotExists: Boolean): DateTime
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Rec);
        exit(NsElementMgt.GetValueAsDateTime(RecRef, Rec."Key", _PathToGet, 0, _ErrorIfNotExists));
    end;

    procedure GetValueAsInteger(_PathToGet: Text; _ErrorIfNotExists: Boolean): Integer
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Rec);
        exit(NsElementMgt.GetValueAsInteger(RecRef, Rec."Key", _PathToGet, 0, _ErrorIfNotExists));
    end;

    procedure GetValueAsDecimal(_PathToGet: Text; _ErrorIfNotExists: Boolean): Decimal
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Rec);
        exit(NsElementMgt.GetValueAsDecimal(RecRef, Rec."Key", _PathToGet, 0, _ErrorIfNotExists));
    end;

    procedure GetDisplayLinesAsList(var _DisplayLinesList: List of [Text]; _FromIndex: Integer; _ToIndex: Integer)
    var
        i: Integer;
    begin
        Clear(_DisplayLinesList);
        for i := _FromIndex to _ToIndex do
            case i of
                1:
                    _DisplayLinesList.Add(Get_DisplayLine1());
                2:
                    _DisplayLinesList.Add(Get_DisplayLine2());
                3:
                    _DisplayLinesList.Add(Get_DisplayLine3());
                4:
                    _DisplayLinesList.Add(Get_DisplayLine4());
                5:
                    _DisplayLinesList.Add(Get_DisplayLine5());
                6:
                    _DisplayLinesList.Add(Get_DisplayLine6());
                7:
                    _DisplayLinesList.Add(Get_DisplayLine7());
                8:
                    _DisplayLinesList.Add(Get_DisplayLine8());
                9:
                    _DisplayLinesList.Add(Get_DisplayLine9());
                else
                    _DisplayLinesList.Add(GetValue('DisplayLine' + Format(i)));
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

    /// <summary>
    /// Syncronize current NS BaseDataModel Element record  to internal NodeValue Buffer. All text fields are syncronized excluding field no. range 800..999.
    /// Oneway syncronization from table to buffer hance no return value by SetTable.
    /// </summary>
    internal procedure SyncronizeTableToBuffer()
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Rec);
        NsElementMgt.SyncronizeTableToBuffer(RecRef);
    end;

    // -------------------------
    // Helper methods
    // -----------
    procedure Create_StepsByReferenceDataKey(_ReferenceDataRegistrationCollectorConfigurationKey: Text)
    begin
        Create_StepsByReferenceDataKey(_ReferenceDataRegistrationCollectorConfigurationKey, true);
    end;

    // Was used in early documentation examples -- leaving as public procedure
    procedure Create_StepsByReferenceDataKey(_ReferenceDataRegistrationCollectorConfigurationKey: Text; _ErrorIfAlreadyCreated: Boolean)
    var
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
    begin
        // MOB5.11
        // Currently the Android Mobile App supports only one "RegisterExtraInfo"-node (one extra RegistrationCollectorConfigurationKey).
        // The last subscriber to OnGetReceiveOrderLines_OnAfterAddStepsByReferenceDataKey must set a <RegisterExtraInfo>-key that includes steps for all previous subscribers.
        // This is only possible by knowing what other customizations is done and manually create a new RegistrationCollectorConfigurationKey that includes all steps.
        if (_ErrorIfAlreadyCreated and (GetValue('RegisterExtraInfo') <> '')) then
            Error(MobWmsToolbox."ERROR::CreateStepsByReferenceDataKeyAlreadySet"(), TableCaption(), GetValue('RegisterExtraInfo'));

        SetValue('RegisterExtraInfo', _ReferenceDataRegistrationCollectorConfigurationKey);
    end;

    // -------------------------
    // Get/Set procedures
    // -------------------------

    procedure Set_BackendID(_NewValue: Text)
    begin
        SetValue(FieldName(BackendID), _NewValue);
    end;

    procedure Set_BackendID(_TrueFalseExpression: Boolean; _NewValueTrue: Text; _NewValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_BackendID(_NewValueTrue)
        else
            Set_BackendID(_NewValueFalse);
    end;

    procedure Get_BackendID(): Text
    begin
        exit(GetValue(FieldNo(BackendID), FieldName(BackendID), false));
    end;

    procedure Set_OrderBackendID(_NewValue: Text)
    begin
        SetValue(FieldNo(OrderBackendID), FieldName(OrderBackendID), _NewValue);
    end;

    procedure Set_OrderBackendID(_TrueFalseExpression: Boolean; _NewValueTrue: Text; _NewValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_OrderBackendID(_NewValueTrue)
        else
            Set_OrderBackendID(_NewValueFalse);
    end;

    procedure Get_OrderBackendID(): Text
    begin
        exit(GetValue(FieldNo(OrderBackendID), FieldName(OrderBackendID), false));
    end;

    procedure Set_LineNumber(_NewValue: Integer)
    begin
        Set_LineNumber(Format(_NewValue));
    end;

    procedure Set_LineNumber(_TrueFalseExpression: Boolean; _NewValueTrue: Integer; _NewValueFalse: Integer)
    begin
        if _TrueFalseExpression then
            Set_LineNumber(_NewValueTrue)
        else
            Set_LineNumber(_NewValueFalse);
    end;

    procedure Set_LineNumber(_NewValue: Text)
    begin
        SetValue(FieldNo(LineNumber), FieldName(LineNumber), _NewValue);
    end;

    procedure Set_LineNumber(_TrueFalseExpression: Boolean; _NewValueTrue: Text; _NewValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_LineNumber(_NewValueTrue)
        else
            Set_LineNumber(_NewValueFalse);
    end;

    procedure Get_LineNumber(): Text
    begin
        exit(GetValue(FieldNo(LineNumber), FieldName(LineNumber), false));
    end;

    procedure Set_FromBin(_NewValue: Text)
    begin
        SetValue(FieldNo(FromBin), FieldName(FromBin), _NewValue);
    end;

    procedure Set_FromBin(_TrueFalseExpression: Boolean; _NewValueTrue: Text; _NewValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_FromBin(_NewValueTrue)
        else
            Set_FromBin(_NewValueFalse);
    end;

    procedure Get_FromBin(): Text
    begin
        exit(GetValue(FieldNo(FromBin), FieldName(FromBin), false));
    end;

    procedure Set_ValidateFromBin(_NewValue: Boolean)
    var
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
    begin
        Set_ValidateFromBin(MobWmsToolbox.Bool2Text(_NewValue));
    end;

    procedure Set_ValidateFromBin(_NewValue: Text)
    begin
        SetValue(FieldNo(ValidateFromBin), FieldName(ValidateFromBin), _NewValue);
    end;

    procedure Get_ValidateFromBin(): Text
    begin
        exit(GetValue(FieldNo(ValidateFromBin), FieldName(ValidateFromBin), false));
    end;

    procedure Set_ToBin(_NewValue: Text)
    begin
        SetValue(FieldNo(ToBin), FieldName(ToBin), _NewValue);
    end;

    procedure Set_ToBin(_TrueFalseExpression: Boolean; _NewValueTrue: Text; _NewValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_ToBin(_NewValueTrue)
        else
            Set_ToBin(_NewValueFalse);
    end;

    procedure Get_ToBin(): Text
    begin
        exit(GetValue(FieldNo(ToBin), FieldName(ToBin), false));
    end;

    procedure Set_ValidateToBin(_NewValue: Boolean)
    var
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
    begin
        Set_ValidateToBin(MobWmsToolbox.Bool2Text(_NewValue));
    end;

    procedure Set_ValidateToBin(_NewValue: Text)
    begin
        SetValue(FieldNo(ValidateToBin), FieldName(ValidateToBin), _NewValue);
    end;

    procedure Get_ValidateToBin(): Text
    begin
        exit(GetValue(FieldNo(ValidateToBin), FieldName(ValidateToBin), false));
    end;

    procedure Set_AllowBinChange(_NewValue: Boolean)
    var
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
    begin
        Set_AllowBinChange(MobWmsToolbox.Bool2Text(_NewValue));
    end;

    procedure Set_AllowBinChange(_NewValue: Text)
    begin
        SetValue(FieldNo(AllowBinChange), FieldName(AllowBinChange), _NewValue);
    end;

    procedure Get_AllowBinChange(): Text
    begin
        exit(GetValue(FieldNo(AllowBinChange), FieldName(AllowBinChange), false));
    end;

    procedure Set_ItemNumber(_NewValue: Text)
    begin
        SetValue(FieldNo(ItemNumber), FieldName(ItemNumber), _NewValue);
    end;

    procedure Set_ItemNumber(_TrueFalseExpression: Boolean; _NewValueTrue: Text; _NewValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_ItemNumber(_NewValueTrue)
        else
            Set_ItemNumber(_NewValueFalse);
    end;

    procedure Get_ItemNumber(): Text
    begin
        exit(GetValue(FieldNo(ItemNumber), FieldName(ItemNumber), false));
    end;

    procedure Set_ItemBarcode(_NewValue: Text)
    begin
        SetValue(FieldNo(ItemBarcode), FieldName(ItemBarcode), _NewValue);
    end;

    procedure Set_ItemBarcode(_TrueFalseExpression: Boolean; _NewValueTrue: Text; _NewValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_ItemBarcode(_NewValueTrue)
        else
            Set_ItemBarcode(_NewValueFalse);
    end;

    procedure Get_ItemBarcode(): Text
    begin
        exit(GetValue(FieldNo(ItemBarcode), FieldName(ItemBarcode), false));
    end;

    procedure Set_Description(_NewValue: Text)
    begin
        SetValue(FieldNo(Description), FieldName(Description), _NewValue);
    end;

    procedure Set_Description(_TrueFalseExpression: Boolean; _NewValueTrue: Text; _NewValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_Description(_NewValueTrue)
        else
            Set_Description(_NewValueFalse);
    end;

    procedure Get_Description(): Text
    begin
        exit(GetValue(FieldNo(Description), FieldName(Description), false));
    end;

    procedure Set_RegisterSerialNumber(_NewValue: Boolean)
    var
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
    begin
        Set_RegisterSerialNumber(MobWmsToolbox.Bool2Text(_NewValue));
    end;

    procedure Set_RegisterSerialNumber(_NewValue: Text)
    begin
        SetValue(FieldNo(RegisterSerialNumber), FieldName(RegisterSerialNumber), _NewValue);
    end;

    procedure Get_RegisterSerialNumber(): Text
    begin
        exit(GetValue(FieldNo(RegisterSerialNumber), FieldName(RegisterSerialNumber), false));
    end;

    procedure Set_RegisterLotNumber(_NewValue: Boolean)
    var
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
    begin
        Set_RegisterLotNumber(MobWmsToolbox.Bool2Text(_NewValue));
    end;

    procedure Set_RegisterLotNumber(_NewValue: Text)
    begin
        SetValue(FieldNo(RegisterLotNumber), FieldName(RegisterLotNumber), _NewValue);
    end;

    procedure Get_RegisterLotNumber(): Text
    begin
        exit(GetValue(FieldNo(RegisterLotNumber), FieldName(RegisterLotNumber), false));
    end;

    procedure Set_RegisterPackageNumber(_NewValue: Boolean)
    var
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
    begin
        Set_RegisterPackageNumber(MobWmsToolbox.Bool2Text(_NewValue));
    end;

    procedure Set_RegisterPackageNumber(_NewValue: Text)
    begin
        SetValue(FieldName(RegisterPackageNumber), _NewValue);
    end;

    procedure Get_RegisterPackageNumber(): Text
    begin
        exit(GetValue(FieldNo(RegisterPackageNumber), FieldName(RegisterPackageNumber), false));
    end;

    procedure Set_RegisterExpirationDate(_NewValue: Boolean)
    var
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
    begin
        Set_RegisterExpirationDate(MobWmsToolbox.Bool2Text(_NewValue));
    end;

    procedure Set_RegisterExpirationDate(_NewValue: Text)
    begin
        SetValue(FieldNo(RegisterExpirationDate), FieldName(RegisterExpirationDate), _NewValue);
    end;

    procedure Get_RegisterExpirationDate(): Text
    begin
        exit(GetValue(FieldNo(RegisterExpirationDate), FieldName(RegisterExpirationDate), false));
    end;

    /// <summary>
    /// If the <RegisterQuantityByScan/> element is set to true the mobile device can use values in <BarcodeQuantity/>
    /// element to register the quantity associated with barcode instead of always registering 1.
    /// </summary>
    /// <param name="_NewValue">Sets the value of RegisterQuantityByScan</param>
    /// <remarks>Make sure that the mobile device is registering in the base unit if this is enabled</remarks>        
    procedure Set_RegisterQuantityByScan(_NewValue: Boolean)
    var
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
    begin
        Set_RegisterQuantityByScan(MobWmsToolbox.Bool2Text(_NewValue));
    end;

    /// <summary>
    /// If the <RegisterQuantityByScan/> element is set to true the mobile device can use values in <BarcodeQuantity/>
    /// element to register the quantity associated with barcode instead of always registering 1.
    /// </summary>
    /// <param name="_NewValue">Sets the value of RegisterQuantityByScan. Valid values are 'true' and 'false' in lower case</param>
    /// <remarks>Make sure that the mobile device is registering in the base unit if this is enabled</remarks>
    procedure Set_RegisterQuantityByScan(_NewValue: Text)
    begin
        SetValue(FieldNo(RegisterQuantityByScan), FieldName(RegisterQuantityByScan), _NewValue);
    end;

    /// <summary>
    /// Sets <RegisterQuantityByScan/> element to TRUE so the mobile device can use values in <BarcodeQuantity/>
    /// element to register the quantity associated with barcode instead of always registering 1.
    /// </summary>
    /// <param name="_ItemNo">Used to retrieve the Item quantities used in the accompanying "BarcodeQuantity" parameter</param>
    /// <param name="_VariantCode">Used to retrieve the Item quantities used in the accompanying "BarcodeQuantity" parameter</param>
    /// <param name="_UoMCode">Used to calculate to quantity in the Source Line Unit of measure when used in the accompanying "BarcodeQuantity" parameter</param>   
    procedure Set_RegisterQuantityByScanAndBarcodeQuantity(_ItemNo: Code[20]; _VariantCode: Code[10]; _UoMCode: Code[10])
    begin
        Set_RegisterQuantityByScan(true);
        Set_BarcodeQuantity(_ItemNo, _VariantCode, _UoMCode);
    end;

    procedure Get_RegisterQuantityByScan(): Text
    begin
        exit(GetValue(FieldNo(RegisterQuantityByScan), FieldName(RegisterQuantityByScan), false));
    end;

    /// <summary>
    /// The mobile device can use values in <BarcodeQuantity/> element to register the quantity associated
    /// with barcode instead of always registering 1. If the <RegisterQuantityByScan/> element is set to true.
    /// </summary>
    /// <param name="_NewValue">Sets the value of <BarcodeQuantity/>. Valid format is xxxxxxxxxxxxx{Qty}[UoM]. If you have several barcodes use ; as delimiter</param>
    /// <remarks>Make sure that the mobile device is registering in the base unit if this is enabled</remarks>
    procedure Set_BarcodeQuantity(_NewValue: Text)
    begin
        SetValue(FieldNo(BarcodeQuantity), FieldName(BarcodeQuantity), _NewValue);
    end;

    /// <summary>
    /// The mobile device can use values in <BarcodeQuantity/> element to register the quantity associated
    /// with barcode instead of always registering 1. If the <RegisterQuantityByScan/> element is set to true.
    /// </summary>
    /// <param name="_NewValue">Sets the value of <BarcodeQuantity/>. Valid format is xxxxxxxxxxxxx{Qty}[UoM]. If you have several barcodes use ; as delimiter</param>
    /// <param name="_EnableMultiplier">Used to enable "BarcodeQuantity" multiplication</param>
    /// <remarks>Make sure that the mobile device is registering in the base unit if this is enabled</remarks>
    procedure Set_BarcodeQuantity(_NewValue: Text; _EnableMultiplier: Boolean)
    var
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
    begin
        SetValue(FieldName(BarcodeQuantity), _NewValue);
        SetValue(FieldName(BarcodeQuantity) + '/@enableMultiplier', MobWmsToolbox.Bool2Text(_EnableMultiplier));
    end;

    /// <summary>
    /// The mobile device can use values in <BarcodeQuantity/> element to register the quantity associated
    /// with barcode instead of always registering 1. If the <RegisterQuantityByScan/> element is set to true.
    /// </summary>
    /// <param name="_ItemNo">Used to retrieve the Item quantities used in the accompanying "BarcodeQuantity" parameter</param>
    /// <param name="_VariantCode">Used to retrieve the Item quantities used in the accompanying "BarcodeQuantity" parameter</param>
    /// <param name="_UnitOfMeasure">Used to calculate the quantity in the Source Line Unit of measure when used in the accompanying "BarcodeQuantity" parameter</param>  
    procedure Set_BarcodeQuantity(_ItemNo: Code[20]; _VariantCode: Code[10]; _UoMCode: Code[10])
    var
        MobItemReferenceMgt: Codeunit "MOB Item Reference Mgt.";
    begin
        SetValue(FieldNo(BarcodeQuantity), FieldName(BarcodeQuantity), MobItemReferenceMgt.GetBarcodeQuantityList(_ItemNo, _VariantCode, _UoMCode));
    end;

    /// <summary>
    /// Available from Mobile App v.1.5.12
    /// The mobile device can use values in <BarcodeQuantity/> element to register the quantity associated
    /// Enabling barcode quantity multiplication allows the user to enter how many e.g. boxes where picked up. This will result in a registration which multiplies the user input of boxes, and the amount of individual items the box can contain.
    /// So if a barcode is scanned, the quantity field is left blank, and a multiplier is displayed to the right of the input field, notifying that the entered quantity will be multiplied by that value.
    /// </summary>
    /// <param name="_ItemNo">Used to retrieve the Item quantities used in the accompanying "BarcodeQuantity" parameter</param>
    /// <param name="_VariantCode">Used to retrieve the Item quantities used in the accompanying "BarcodeQuantity" parameter</param>
    /// <param name="_UnitOfMeasure">Used to calculate the quantity in the Source Line Unit of measure when used in the accompanying "BarcodeQuantity" parameter</param>
    /// <param name="_EnableMultiplier">Used to enable "BarcodeQuantity" multiplication</param>
    procedure Set_BarcodeQuantity(_ItemNo: Code[20]; _VariantCode: Code[10]; _UoMCode: Code[10]; _EnableMultiplier: Boolean)
    var
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
    begin
        Set_BarcodeQuantity(_ItemNo, _VariantCode, _UoMCode);
        SetValue(FieldName(BarcodeQuantity) + '/@enableMultiplier', MobWmsToolbox.Bool2Text(_EnableMultiplier));
    end;

    /// <summary>
    /// The mobile device can use values in <BarcodeQuantity/> element to register the quantity associated
    /// with barcode instead of always registering 1. If the <RegisterQuantityByScan/> element is set to true.
    /// </summary>    
    /// <param name="_NewValueTrue">Sets the value of <BarcodeQuantity/> if _TrueFalseExpression equals true. Valid format is xxxxxxxxxxxxx{Qty}. If you have several barcodes use ; as delimiter</param>
    /// <param name="_NewValueFalse">Sets the value of <BarcodeQuantity/> if _TrueFalseExpression equals false. Valid format is xxxxxxxxxxxxx{Qty}. If you have several barcodes use ; as delimiter</param>
    /// <remarks>Make sure that the mobile device is registering in the base unit if this is enabled</remarks>
    procedure Set_BarcodeQuantity(_TrueFalseExpression: Boolean; _NewValueTrue: Text; _NewValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_BarcodeQuantity(_NewValueTrue)
        else
            Set_BarcodeQuantity(_NewValueFalse);
    end;

    procedure Get_BarcodeQuantity(): Text
    begin
        exit(GetValue(FieldNo(BarcodeQuantity), FieldName(BarcodeQuantity), false));
    end;

    procedure Set_SerialNumber(_NewValue: Text)
    begin
        SetValue(FieldNo(SerialNumber), FieldName(SerialNumber), _NewValue);
    end;

    procedure Set_SerialNumber(_TrueFalseExpression: Boolean; _NewValueTrue: Text; _NewValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_SerialNumber(_NewValueTrue)
        else
            Set_SerialNumber(_NewValueFalse);
    end;

    procedure Get_SerialNumber(): Text
    begin
        exit(GetValue(FieldNo(SerialNumber), FieldName(SerialNumber), false));
    end;

    procedure Set_LotNumber(_NewValue: Text)
    begin
        SetValue(FieldNo(LotNumber), FieldName(LotNumber), _NewValue);
    end;

    procedure Set_LotNumber(_TrueFalseExpression: Boolean; _NewValueTrue: Text; _NewValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_LotNumber(_NewValueTrue)
        else
            Set_LotNumber(_NewValueFalse);
    end;

    procedure Get_LotNumber(): Text
    begin
        exit(GetValue(FieldNo(LotNumber), FieldName(LotNumber), false));
    end;

    procedure Set_PackageNumber(_NewValue: Text)
    begin
        SetValue(FieldName(PackageNumber), _NewValue);
    end;

    procedure Set_PackageNumber(_TrueFalseExpression: Boolean; _NewValueTrue: Text; _NewValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_PackageNumber(_NewValueTrue)
        else
            Set_PackageNumber(_NewValueFalse);
    end;

    procedure Get_PackageNumber(): Text
    begin
        exit(GetValue(FieldNo(PackageNumber), FieldName(PackageNumber), false));
    end;

    procedure Set_ExpirationDate(_NewValue: Date)
    var
        MobToolbox: Codeunit "MOB Toolbox";
    begin
        if _NewValue = 0D then
            SetValue(FieldNo(ExpirationDate), FieldName(ExpirationDate), ' ')    // Blank date must be a single space to suggest no date in Mobile App
        else
            SetValue(FieldNo(ExpirationDate), FieldName(ExpirationDate), MobToolbox.Date2TextResponseFormat(_NewValue));
    end;

    procedure Set_ExpirationDate(_TrueFalseExpression: Boolean; _NewValueTrue: Date; _NewValueFalse: Date)
    begin
        if _TrueFalseExpression then
            Set_ExpirationDate(_NewValueTrue)
        else
            Set_ExpirationDate(_NewValueFalse);
    end;

    procedure Get_ExpirationDate(): Text
    begin
        exit(GetValue(FieldNo(ExpirationDate), FieldName(ExpirationDate), false));
    end;

    /// <summary>
    /// Use this for "Order Lines" and Mobile will convert to the regional culture format (based on Android language setting) 
    /// </summary>
    procedure Set_Quantity(_NewValue: Decimal)
    begin
        Set_Quantity(Format(_NewValue, 0, 9)); // Format to  XML format and mobile converts to the correct regional format
    end;

    procedure Set_Quantity(_TrueFalseExpression: Boolean; _NewValueTrue: Decimal; _NewValueFalse: Decimal)
    begin
        if _TrueFalseExpression then
            Set_Quantity(_NewValueTrue)
        else
            Set_Quantity(_NewValueFalse);
    end;

    procedure Set_Quantity(NewValue: Text)
    begin
        SetValue(FieldNo(Quantity), FieldName(Quantity), NewValue);
    end;

    procedure Get_Quantity(): Text
    begin
        exit(GetValue(FieldNo(Quantity), FieldName(Quantity), false));
    end;

    procedure Set_Location(_NewValue: Text)
    begin
        SetValue(FieldNo(Location), FieldName(Location), _NewValue);
    end;

    procedure Get_Location(): Text
    begin
        exit(GetValue(FieldNo(Location), FieldName(Location), false));
    end;

    /// <summary>
    /// Use this for "Order Lines" and Mobile will convert to the regional culture format (based on Android language setting) 
    /// </summary>
    procedure Set_RegisteredQuantity(_NewValue: Decimal)
    begin
        Set_RegisteredQuantity(Format(_NewValue, 0, 9)); // Format to  XML format and mobile converts to the correct regional format
    end;

    procedure Set_RegisteredQuantity(_TrueFalseExpression: Boolean; _NewValueTrue: Decimal; _NewValueFalse: Decimal)
    begin
        if _TrueFalseExpression then
            Set_RegisteredQuantity(_NewValueTrue)
        else
            Set_RegisteredQuantity(_NewValueFalse);
    end;

    procedure Set_RegisteredQuantity(_NewValue: Text)
    begin
        SetValue(FieldNo(RegisteredQuantity), FieldName(RegisteredQuantity), _NewValue);
    end;

    procedure Get_RegisteredQuantity(): Text
    begin
        exit(GetValue(FieldNo(RegisteredQuantity), FieldName(RegisteredQuantity), false));
    end;

    procedure Set_UnitOfMeasure(_NewValue: Text)
    begin
        SetValue(FieldNo(UnitOfMeasure), FieldName(UnitOfMeasure), _NewValue);
    end;

    procedure Set_UnitOfMeasure(_TrueFalseExpression: Boolean; _NewValueTrue: Text; _NewValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_UnitOfMeasure(_NewValueTrue)
        else
            Set_UnitOfMeasure(_NewValueFalse);
    end;

    procedure Get_UnitOfMeasure(): Text
    begin
        exit(GetValue(FieldNo(UnitOfMeasure), FieldName(UnitOfMeasure), false));
    end;

    procedure Set_Status()
    var
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
    begin
        SetValue(FieldName(Status), MobWmsToolbox.GetStatusCode(Get_BackendID(), Get_ReferenceID()));
    end;

    procedure Set_Status(_NewValue: Text)
    begin
        SetValue(FieldNo(Status), FieldName(Status), _NewValue);
    end;

    procedure Set_Status(_TrueFalseExpression: Boolean; _NewValueTrue: Text; _NewValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_Status(_NewValueTrue)
        else
            Set_Status(_NewValueFalse);
    end;

    procedure Get_Status(): Text
    begin
        exit(GetValue(FieldNo(Status), FieldName(Status), false));
    end;

    procedure Set_Attachment()
    var
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
    begin
        SetValue(FieldNo(Attachment), FieldName(Attachment), MobWmsToolbox.GetAttachmentCode(Get_ReferenceID()));
    end;

    procedure Set_Attachment(_NewValue: Text)
    begin
        SetValue(FieldNo(Attachment), FieldName(Attachment), _NewValue);
    end;

    procedure Set_Attachment(_TrueFalseExpression: Boolean; _NewValueTrue: Text; _NewValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_Attachment(_NewValueTrue)
        else
            Set_Attachment(_NewValueFalse);
    end;

    procedure Get_Attachment(): Text
    begin
        exit(GetValue(FieldNo(Attachment), FieldName(Attachment), false));
    end;

    procedure Set_DisplayLine1(_NewValue: Text)
    begin
        SetValue(FieldNo(DisplayLine1), FieldName(DisplayLine1), _NewValue);
    end;

    procedure Set_DisplayLine1(_TrueFalseExpression: Boolean; _NewValueTrue: Text; _NewValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_DisplayLine1(_NewValueTrue)
        else
            Set_DisplayLine1(_NewValueFalse);
    end;

    procedure Get_DisplayLine1(): Text
    begin
        exit(GetValue(FieldNo(DisplayLine1), FieldName(DisplayLine1), false));
    end;

    procedure Set_DisplayLine2(_NewValue: Text)
    begin
        SetValue(FieldNo(DisplayLine2), FieldName(DisplayLine2), _NewValue);
    end;

    procedure Set_DisplayLine2(_TrueFalseExpression: Boolean; _NewValueTrue: Text; _NewValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_DisplayLine2(_NewValueTrue)
        else
            Set_DisplayLine2(_NewValueFalse);
    end;

    procedure Get_DisplayLine2(): Text
    begin
        exit(GetValue(FieldNo(DisplayLine2), FieldName(DisplayLine2), false));
    end;

    procedure Set_DisplayLine3(_NewValue: Text)
    begin
        SetValue(FieldNo(DisplayLine3), FieldName(DisplayLine3), _NewValue);
    end;

    procedure Set_DisplayLine3(_TrueFalseExpression: Boolean; _NewValueTrue: Text; _NewValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_DisplayLine3(_NewValueTrue)
        else
            Set_DisplayLine3(_NewValueFalse);
    end;

    procedure Get_DisplayLine3(): Text
    begin
        exit(GetValue(FieldNo(DisplayLine3), FieldName(DisplayLine3), false));
    end;

    procedure Set_DisplayLine4(_NewValue: Text)
    begin
        SetValue(FieldNo(DisplayLine4), FieldName(DisplayLine4), _NewValue);
    end;

    procedure Set_DisplayLine4(_TrueFalseExpression: Boolean; _NewValueTrue: Text; _NewValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_DisplayLine4(_NewValueTrue)
        else
            Set_DisplayLine4(_NewValueFalse);
    end;

    procedure Get_DisplayLine4(): Text
    begin
        exit(GetValue(FieldNo(DisplayLine4), FieldName(DisplayLine4), false));
    end;

    procedure Set_DisplayLine5(_NewValue: Text)
    begin
        SetValue(FieldNo(DisplayLine5), FieldName(DisplayLine5), _NewValue);
    end;

    procedure Set_DisplayLine5(_TrueFalseExpression: Boolean; _NewValueTrue: Text; _NewValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_DisplayLine5(_NewValueTrue)
        else
            Set_DisplayLine5(_NewValueFalse);
    end;

    procedure Get_DisplayLine5(): Text
    begin
        exit(GetValue(FieldNo(DisplayLine5), FieldName(DisplayLine5), false));
    end;

    procedure Set_DisplayLine6(_NewValue: Text)
    begin
        SetValue(FieldNo(DisplayLine6), FieldName(DisplayLine6), _NewValue);
    end;

    procedure Set_DisplayLine6(_TrueFalseExpression: Boolean; _NewValueTrue: Text; _NewValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_DisplayLine6(_NewValueTrue)
        else
            Set_DisplayLine6(_NewValueFalse);
    end;

    procedure Get_DisplayLine6(): Text
    begin
        exit(GetValue(FieldNo(DisplayLine6), FieldName(DisplayLine6), false));
    end;

    procedure Set_DisplayLine7(_NewValue: Text)
    begin
        SetValue(FieldNo(DisplayLine7), FieldName(DisplayLine7), _NewValue);
    end;

    procedure Set_DisplayLine7(_TrueFalseExpression: Boolean; _NewValueTrue: Text; _NewValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_DisplayLine7(_NewValueTrue)
        else
            Set_DisplayLine7(_NewValueFalse);
    end;

    procedure Get_DisplayLine7(): Text
    begin
        exit(GetValue(FieldNo(DisplayLine7), FieldName(DisplayLine7), false));
    end;

    procedure Set_DisplayLine8(_NewValue: Text)
    begin
        SetValue(FieldNo(DisplayLine8), FieldName(DisplayLine8), _NewValue);
    end;

    procedure Set_DisplayLine8(_TrueFalseExpression: Boolean; _NewValueTrue: Text; _NewValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_DisplayLine8(_NewValueTrue)
        else
            Set_DisplayLine8(_NewValueFalse);
    end;

    procedure Get_DisplayLine8(): Text
    begin
        exit(GetValue(FieldNo(DisplayLine8), FieldName(DisplayLine8), false));
    end;

    procedure Set_DisplayLine9(_NewValue: Text)
    begin
        SetValue(FieldNo(DisplayLine9), FieldName(DisplayLine9), _NewValue);
    end;

    procedure Set_DisplayLine9(_TrueFalseExpression: Boolean; _NewValueTrue: Text; _NewValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_DisplayLine9(_NewValueTrue)
        else
            Set_DisplayLine9(_NewValueFalse);
    end;

    procedure Get_DisplayLine9(): Text
    begin
        exit(GetValue(FieldNo(DisplayLine9), FieldName(DisplayLine9), false));
    end;

    procedure Set_HeaderLabel1(_NewValue: Text)
    begin
        SetValue(FieldNo(HeaderLabel1), FieldName(HeaderLabel1), _NewValue);
    end;

    procedure Set_HeaderLabel1(_TrueFalseExpression: Boolean; _NewValueTrue: Text; _NewValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_HeaderLabel1(_NewValueTrue)
        else
            Set_HeaderLabel1(_NewValueFalse);
    end;

    procedure Get_HeaderLabel1(): Text
    begin
        exit(GetValue(FieldNo(HeaderLabel1), FieldName(HeaderLabel1), false));
    end;

    procedure Set_HeaderLabel2(_NewValue: Text)
    begin
        SetValue(FieldNo(HeaderLabel2), FieldName(HeaderLabel2), _NewValue);
    end;

    procedure Set_HeaderLabel2(_TrueFalseExpression: Boolean; _NewValueTrue: Text; _NewValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_HeaderLabel2(_NewValueTrue)
        else
            Set_HeaderLabel2(_NewValueFalse);
    end;

    procedure Get_HeaderLabel2(): Text
    begin
        exit(GetValue(FieldNo(HeaderLabel2), FieldName(HeaderLabel2), false));
    end;

    procedure Set_HeaderValue1(_NewValue: Text)
    begin
        SetValue(FieldNo(HeaderValue1), FieldName(HeaderValue1), _NewValue);
    end;

    procedure Set_HeaderValue1(_TrueFalseExpression: Boolean; _NewValueTrue: Text; _NewValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_HeaderValue1(_NewValueTrue)
        else
            Set_HeaderValue1(_NewValueFalse);
    end;

    procedure Get_HeaderValue1(): Text
    begin
        exit(GetValue(FieldNo(HeaderValue1), FieldName(HeaderValue1), false));
    end;

    procedure Set_HeaderValue2(_NewValue: Text)
    begin
        SetValue(FieldNo(HeaderValue2), FieldName(HeaderValue2), _NewValue);
    end;

    procedure Set_HeaderValue2(_TrueFalseExpression: Boolean; _NewValueTrue: Text; _NewValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_HeaderValue2(_NewValueTrue)
        else
            Set_HeaderValue2(_NewValueFalse);
    end;

    procedure Get_HeaderValue2(): Text
    begin
        exit(GetValue(FieldNo(HeaderValue2), FieldName(HeaderValue2), false));
    end;

    procedure Set_UnderDeliveryValidation(_NewValue: Text)
    begin
        SetValue(FieldNo(UnderDeliveryValidation), FieldName(UnderDeliveryValidation), _NewValue);
    end;

    procedure Set_UnderDeliveryValidation(_ValidationWarningType: Enum "MOB ValidationWarningType")
    begin
        Set_UnderDeliveryValidation(Format(_ValidationWarningType));
    end;

    procedure Set_UnderDeliveryValidation(_TrueFalseExpression: Boolean; _NewValueTrue: Text; _NewValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_UnderDeliveryValidation(_NewValueTrue)
        else
            Set_UnderDeliveryValidation(_NewValueFalse);
    end;

    procedure Get_UnderDeliveryValidation(): Text
    begin
        exit(GetValue(FieldNo(UnderDeliveryValidation), FieldName(UnderDeliveryValidation), false));
    end;

    procedure Set_OverDeliveryValidation(_NewValue: Text)
    begin
        SetValue(FieldNo(OverDeliveryValidation), FieldName(OverDeliveryValidation), _NewValue);
    end;

    procedure Set_OverDeliveryValidation(_ValidationWarningType: Enum "MOB ValidationWarningType")
    begin
        Set_OverDeliveryValidation(Format(_ValidationWarningType));
    end;

    procedure Set_OverDeliveryValidation(_TrueFalseExpression: Boolean; _NewValueTrue: Text; _NewValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_OverDeliveryValidation(_NewValueTrue)
        else
            Set_OverDeliveryValidation(_NewValueFalse);
    end;

    procedure Get_OverDeliveryValidation(): Text
    begin
        exit(GetValue(FieldNo(OverDeliveryValidation), FieldName(OverDeliveryValidation), false));
    end;

    /// <summary>
    /// Control visibilty of menu items (actions).
    /// </summary>
    /// <param name="_Name">Menu item name</param>
    /// <param name="_Enabled">If False the item is visible, but greyed-out</param>
    /// <param name="_Promoted">The order of which items are promoted and permanently displayed in the bottom of the screen. "1" is highest</param>
    procedure Set_MenuItemStateConfiguration(_Name: Text; _Enabled: Boolean; _Promoted: Integer)
    var
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
    begin
        SetValue('menuItemStateConfigurations/' + _Name + '/@enabled', MobWmsToolbox.Bool2Text(_Enabled));
        if _Promoted > 0 then
            SetValue('menuItemStateConfigurations/' + _Name + '/@promoted', Format(_Promoted));
    end;

    procedure Set_ItemImageID()
    var
        MobWmsMedia: Codeunit "MOB WMS Media";
    begin
        Set_ItemImageID(MobWmsMedia.GetItemImageID(Get_ItemNumber()));
    end;

    procedure Set_ItemImageID(_NewValue: Text)
    begin
        SetValue(FieldNo(ItemImage), FieldName(ItemImage), _NewValue);
    end;

    procedure Set_ItemImageID(_TrueFalseExpression: Boolean; _NewValueTrue: Text; _NewValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_ItemImageID(_NewValueTrue)
        else
            Set_ItemImageID(_NewValueFalse);
    end;

    /// <summary>
    /// Set value for <ItemImage/>. The value (ItemImageID) is a reference to the image, not the image itself. The images is pulled asynchroniously by the Mobile WMS andriod app. based in the ID's provided here.
    /// </summary>
    procedure Get_ItemImageID(): Text
    begin
        exit(GetValue(FieldNo(ItemImage), FieldName(ItemImage), false));
    end;

    procedure Set_TotePicking(_NewValue: Boolean)
    var
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
    begin
        Set_TotePicking(MobWmsToolbox.Bool2Text(_NewValue));
    end;

    procedure Set_TotePicking(_NewValue: Text)
    begin
        SetValue(FieldNo(TotePicking), FieldName(TotePicking), _NewValue);
    end;

    procedure Get_TotePicking(): Text
    begin
        exit(GetValue(FieldNo(TotePicking), FieldName(TotePicking), false));
    end;

    procedure Set_Destination(_NewValue: Text)
    begin
        SetValue(FieldNo(Destination), FieldName(Destination), _NewValue);
    end;

    procedure Set_Destination(_TrueFalseExpression: Boolean; _NewValueTrue: Text; _NewValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_Destination(_NewValueTrue)
        else
            Set_Destination(_NewValueFalse);
    end;

    procedure Get_Destination(): Text
    begin
        exit(GetValue(FieldNo(Destination), FieldName(Destination), false));
    end;

    procedure Set_Priority(_NewValue: Text)
    begin
        SetValue(FieldNo(Priority), FieldName(Priority), _NewValue);
    end;

    procedure Set_Priority(_TrueFalseExpression: Boolean; _NewValueTrue: Text; _NewValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_Priority(_NewValueTrue)
        else
            Set_Priority(_NewValueFalse);
    end;

    procedure Get_Priority(): Text
    begin
        exit(GetValue(FieldNo(Priority), FieldName(Priority), false));
    end;

    procedure Set_PriorityValidation(_NewValue: Text)
    begin
        SetValue(FieldNo(PriorityValidation), FieldName(PriorityValidation), _NewValue);
    end;

    procedure Set_PriorityValidation(_TrueFalseExpression: Boolean; _NewValueTrue: Text; _NewValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_PriorityValidation(_NewValueTrue)
        else
            Set_PriorityValidation(_NewValueFalse);
    end;

    procedure Get_PriorityValidation(): Text
    begin
        exit(GetValue(FieldNo(PriorityValidation), FieldName(PriorityValidation), false));
    end;

    procedure Set_ReferenceID(_RecRelatedVariant: Variant)
    var
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
    begin
        SetValue(FieldNo(ReferenceID), FieldName(ReferenceID), MobWmsToolbox.GetReferenceID(_RecRelatedVariant));
    end;

    procedure Set_ReferenceID(_NewValue: Text)
    begin
        SetValue(FieldNo(ReferenceID), FieldName(ReferenceID), _NewValue);
    end;

    procedure Set_ReferenceID(_TrueFalseExpression: Boolean; _NewValueTrue: Text; _NewValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_ReferenceID(_NewValueTrue)
        else
            Set_ReferenceID(_NewValueFalse);
    end;

    procedure Get_ReferenceID(): Text
    begin
        exit(GetValue(FieldNo(ReferenceID), FieldName(ReferenceID), false));
    end;

    /// <summary>
    /// Get ReferenceID (RecordId) as RecordRef
    /// </summary>
    procedure Get_RecRefFromReferenceID(var _RecRef: RecordRef): Boolean
    var
        MobToolbox: Codeunit "MOB Toolbox";
    begin
        exit(MobToolbox.ReferenceIDText2RecRef(Get_ReferenceID(), _RecRef));
    end;

    //
    // Workflow
    // 

    procedure Set_RewindToStepOnIncompleteLine(_StepName: Text)
    begin
        SetValue(FieldNo(RewindToStepOnIncompleteLine), FieldName(RewindToStepOnIncompleteLine), _StepName);
    end;

    procedure Get_RewindToStepOnIncompleteLine(): Text
    begin
        exit(GetValue(FieldNo(RewindToStepOnIncompleteLine), FieldName(RewindToStepOnIncompleteLine), false));
    end;

    /// <summary>
    /// Tweak existing Workflow for planned Order Lines (Append or Replace)
    /// </summary>
    procedure Set_Workflow(var _Steps: Record "MOB Steps Element"; _TweakType: Enum "MOB TweakType")
    var
        TempDummyAdditionalValues: Record "MOB NS BaseDataModel Element" temporary;
    begin
        TempDummyAdditionalValues.Create(); // Must have a populated Key when used in Set_Workflow()
        Set_Workflow(_Steps, TempDummyAdditionalValues, _TweakType);
    end;

    /// <summary>
    /// Tweak existing Workflow for planned Order Lines (Append or Replace)
    /// </summary>
    internal procedure Set_Workflow(var _Steps: Record "MOB Steps Element"; var _AdditionalValuesElement: Record "MOB NS BaseDataModel Element"; _TweakType: Enum "MOB TweakType")
    var
        MobToolbox: Codeunit "MOB Toolbox";
        WorkflowInnerText: Text;
    begin
        WorkflowInnerText := MobToolbox.GetWorkflowInnerText(_Steps, _AdditionalValuesElement, _TweakType);
        Set_Workflow(WorkflowInnerText);
    end;

    procedure Set_Workflow(_NewInnerText: Text)
    begin
        SetValueAsCData('Workflow', _NewInnerText);
    end;

    procedure Get_Workflow(): Text
    begin
        exit(GetValue('Workflow'));
    end;

    /// <summary>
    /// Set_Sorting1 .. Set_Sorting5: Five internal sort-fields to indirectly set "Sorting"-tag in the xml file.
    /// "Sorting" intentially has no dedicaded Set_'er to prevent users from trying to set a value that is later overwritten by our standard code. 
    /// </summary>
    /// <remarks>Elements "Sorting" is assigned using sequence determined by key "Sorting1, Sorting2, Sorting3, Sorting4, Sorting5. This behavior can be overriden using OnSetCurrenyKey-events (where available, see API documentation)</remarks>
    procedure Set_Sorting1(_NewValue: Integer)
    var
        MobToolbox: Codeunit "MOB WMS Toolbox";
    begin
        Set_Sorting1(MobToolbox.Int2Sorting(_NewValue, MaxStrLen(Sorting)));
    end;

    procedure Set_Sorting1(_NewValue: Text)
    begin
        SetValue(FieldNo("Sorting1 (internal)"), FieldName("Sorting1 (internal)"), _NewValue);
    end;

    procedure Set_Sorting1(_NewValue: Date)
    var
        MobToolbox: Codeunit "MOB WMS Toolbox";
    begin
        Set_Sorting1(MobToolbox.Date2Sorting(_NewValue));
    end;

    procedure Set_Sorting1(_NewValue: DateTime)
    begin
        Set_Sorting1(MobTypeHelper.FormatDateTimeAsYYYYMMDDHHMM(_NewValue));
    end;

    procedure Set_Sorting1(_TrueFalseExpression: Boolean; _NewValueTrue: Integer; _NewValueFalse: Integer)
    begin
        if _TrueFalseExpression then
            Set_Sorting1(_NewValueTrue)
        else
            Set_Sorting1(_NewValueFalse);
    end;

    procedure Set_Sorting1(_TrueFalseExpression: Boolean; _NewValueTrue: Text; _NewValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_Sorting1(_NewValueTrue)
        else
            Set_Sorting1(_NewValueFalse);
    end;

    procedure Set_Sorting1(_TrueFalseExpression: Boolean; _NewValueTrue: Date; _NewValueFalse: Date)
    begin
        if _TrueFalseExpression then
            Set_Sorting1(_NewValueTrue)
        else
            Set_Sorting1(_NewValueFalse);
    end;

    procedure Get_Sorting1(): Text
    begin
        exit(GetValue(FieldNo("Sorting1 (internal)"), FieldName("Sorting1 (internal)"), false));
    end;

    procedure Set_Sorting2(_NewValue: Integer)
    var
        MobToolbox: Codeunit "MOB WMS Toolbox";
    begin
        Set_Sorting2(MobToolbox.Int2Sorting(_NewValue, MaxStrLen(Sorting)));
    end;

    procedure Set_Sorting2(_NewValue: Text)
    begin
        SetValue(FieldNo("Sorting2 (internal)"), FieldName("Sorting2 (internal)"), _NewValue);
    end;

    procedure Set_Sorting2(_NewValue: Date)
    var
        MobToolbox: Codeunit "MOB WMS Toolbox";
    begin
        Set_Sorting2(MobToolbox.Date2Sorting(_NewValue));
    end;

    procedure Set_Sorting2(_NewValue: DateTime)
    begin
        Set_Sorting2(MobTypeHelper.FormatDateTimeAsYYYYMMDDHHMM(_NewValue));
    end;

    procedure Set_Sorting2(_TrueFalseExpression: Boolean; _NewValueTrue: Integer; _NewValueFalse: Integer)
    begin
        if _TrueFalseExpression then
            Set_Sorting2(_NewValueTrue)
        else
            Set_Sorting2(_NewValueFalse);
    end;

    procedure Set_Sorting2(_TrueFalseExpression: Boolean; _NewValueTrue: Text; _NewValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_Sorting2(_NewValueTrue)
        else
            Set_Sorting2(_NewValueFalse);
    end;

    procedure Set_Sorting2(_TrueFalseExpression: Boolean; _NewValueTrue: Date; _NewValueFalse: Date)
    begin
        if _TrueFalseExpression then
            Set_Sorting2(_NewValueTrue)
        else
            Set_Sorting2(_NewValueFalse);
    end;

    procedure Get_Sorting2(): Text
    begin
        exit(GetValue(FieldNo("Sorting2 (internal)"), FieldName("Sorting2 (internal)"), false));
    end;

    procedure Set_Sorting3(_NewValue: Integer)
    var
        MobToolbox: Codeunit "MOB WMS Toolbox";
    begin
        Set_Sorting3(MobToolbox.Int2Sorting(_NewValue, MaxStrLen(Sorting)));
    end;

    procedure Set_Sorting3(_NewValue: Text)
    begin
        SetValue(FieldNo("Sorting3 (internal)"), FieldName("Sorting3 (internal)"), _NewValue);
    end;

    procedure Set_Sorting3(_NewValue: Date)
    var
        MobToolbox: Codeunit "MOB WMS Toolbox";
    begin
        Set_Sorting3(MobToolbox.Date2Sorting(_NewValue));
    end;

    procedure Set_Sorting3(_NewValue: DateTime)
    begin
        Set_Sorting3(MobTypeHelper.FormatDateTimeAsYYYYMMDDHHMM(_NewValue));
    end;

    procedure Set_Sorting3(_TrueFalseExpression: Boolean; _NewValueTrue: Integer; _NewValueFalse: Integer)
    begin
        if _TrueFalseExpression then
            Set_Sorting3(_NewValueTrue)
        else
            Set_Sorting3(_NewValueFalse);
    end;

    procedure Set_Sorting3(_TrueFalseExpression: Boolean; _NewValueTrue: Text; _NewValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_Sorting3(_NewValueTrue)
        else
            Set_Sorting3(_NewValueFalse);
    end;

    procedure Set_Sorting3(_TrueFalseExpression: Boolean; _NewValueTrue: Date; _NewValueFalse: Date)
    begin
        if _TrueFalseExpression then
            Set_Sorting3(_NewValueTrue)
        else
            Set_Sorting3(_NewValueFalse);
    end;

    procedure Get_Sorting3(): Text
    begin
        exit(GetValue(FieldNo("Sorting3 (internal)"), FieldName("Sorting3 (internal)"), false));
    end;

    procedure Set_Sorting4(_NewValue: Integer)
    var
        MobToolbox: Codeunit "MOB WMS Toolbox";
    begin
        Set_Sorting4(MobToolbox.Int2Sorting(_NewValue, MaxStrLen(Sorting)));
    end;

    procedure Set_Sorting4(_NewValue: Text)
    begin
        SetValue(FieldNo("Sorting4 (internal)"), FieldName("Sorting4 (internal)"), _NewValue);
    end;

    procedure Set_Sorting4(_NewValue: Date)
    var
        MobToolbox: Codeunit "MOB WMS Toolbox";
    begin
        Set_Sorting4(MobToolbox.Date2Sorting(_NewValue));
    end;

    procedure Set_Sorting4(_NewValue: DateTime)
    begin
        Set_Sorting4(MobTypeHelper.FormatDateTimeAsYYYYMMDDHHMM(_NewValue));
    end;

    procedure Set_Sorting4(_TrueFalseExpression: Boolean; _NewValueTrue: Integer; _NewValueFalse: Integer)
    begin
        if _TrueFalseExpression then
            Set_Sorting4(_NewValueTrue)
        else
            Set_Sorting4(_NewValueFalse);
    end;

    procedure Set_Sorting4(_TrueFalseExpression: Boolean; _NewValueTrue: Text; _NewValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_Sorting4(_NewValueTrue)
        else
            Set_Sorting4(_NewValueFalse);
    end;

    procedure Set_Sorting4(_TrueFalseExpression: Boolean; _NewValueTrue: Date; _NewValueFalse: Date)
    begin
        if _TrueFalseExpression then
            Set_Sorting4(_NewValueTrue)
        else
            Set_Sorting4(_NewValueFalse);
    end;

    procedure Get_Sorting4(): Text
    begin
        exit(GetValue(FieldNo("Sorting4 (internal)"), FieldName("Sorting4 (internal)"), false));
    end;

    procedure Set_Sorting5(_NewValue: Integer)
    var
        MobToolbox: Codeunit "MOB WMS Toolbox";
    begin
        Set_Sorting5(MobToolbox.Int2Sorting(_NewValue, MaxStrLen(Sorting)));
    end;

    procedure Set_Sorting5(_NewValue: Text)
    begin
        SetValue(FieldNo("Sorting5 (internal)"), FieldName("Sorting5 (internal)"), _NewValue);
    end;

    procedure Set_Sorting5(_NewValue: Date)
    var
        MobToolbox: Codeunit "MOB WMS Toolbox";
    begin
        Set_Sorting5(MobToolbox.Date2Sorting(_NewValue));
    end;

    procedure Set_Sorting5(_NewValue: DateTime)
    begin
        Set_Sorting5(MobTypeHelper.FormatDateTimeAsYYYYMMDDHHMM(_NewValue));
    end;

    procedure Set_Sorting5(_TrueFalseExpression: Boolean; _NewValueTrue: Integer; _NewValueFalse: Integer)
    begin
        if _TrueFalseExpression then
            Set_Sorting5(_NewValueTrue)
        else
            Set_Sorting5(_NewValueFalse);
    end;

    procedure Set_Sorting5(_TrueFalseExpression: Boolean; _NewValueTrue: Text; _NewValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_Sorting5(_NewValueTrue)
        else
            Set_Sorting5(_NewValueFalse);
    end;

    procedure Set_Sorting5(_TrueFalseExpression: Boolean; _NewValueTrue: Date; _NewValueFalse: Date)
    begin
        if _TrueFalseExpression then
            Set_Sorting5(_NewValueTrue)
        else
            Set_Sorting5(_NewValueFalse);
    end;

    procedure Get_Sorting5(): Text
    begin
        exit(GetValue(FieldNo("Sorting5 (internal)"), FieldName("Sorting5 (internal)"), false));
    end;

}
