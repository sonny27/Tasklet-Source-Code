table 81392 "MOB NS WhseInquery Element"
{
    Access = Public;
    Caption = 'MOB NS WhseInquery Element', Locked = true;

    fields
    {
        field(1; "Key"; Integer)
        {
            Caption = 'Key', Locked = true;
            DataClassification = SystemMetadata;
            AutoIncrement = true;       // Business Central 365 temporary tables not supported
        }

        field(10; Location; Text[10])
        {
            Caption = 'Location', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(20; ItemNumber; Text[20])
        {
            Caption = 'ItemNumber', Locked = true;
            DataClassification = SystemMetadata;
        }

        // Number can be used for either Item No. or License Plate No.
        field(22; Number; Text[20])
        {
            Caption = 'Number', Locked = true;
            DataClassification = SystemMetadata;
        }

        field(25; "Variant"; Text[10])
        {
            Caption = 'Variant', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(30; Barcode; Text[50])
        {
            Caption = 'Barcode', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(40; DisplaySerialNumber; Text[100])
        {
            Caption = 'DisplaySerialNumber', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(50; SerialNumber; Text[50])
        {
            Caption = 'SerialNumber', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(60; DisplayLotNumber; Text[100])
        {
            Caption = 'DisplayLotNumber', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(70; LotNumber; Text[50])
        {
            Caption = 'LotNumber', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(75; DisplayPackageNumber; Text[100])
        {
            Caption = 'DisplayPackageNumber', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(77; PackageNumber; Text[50])
        {
            Caption = 'PackageNumber', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(80; DisplayExpirationDate; Text[100])
        {
            Caption = 'DisplayExpirationDate', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(90; ExpirationDate; Text[50])
        {
            Caption = 'ExpirationDate', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(200; Bin; Text[20])
        {
            Caption = 'Bin', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(210; Quantity; Text[20])
        {
            Caption = 'Quantity', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(220; UoM; Text[20])
        {
            Caption = 'UoM', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(300; DisplayLine1; Text[250])
        {
            Caption = 'DisplayLine1', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(310; DisplayLine2; Text[250])
        {
            Caption = 'DisplayLine2', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(320; DisplayLine3; Text[250])
        {
            Caption = 'DisplayLine3', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(330; DisplayLine4; Text[250])
        {
            Caption = 'DisplayLine4', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(340; DisplayLine5; Text[250])
        {
            Caption = 'DisplayLine5', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(350; DisplayLine6; Text[250])
        {
            Caption = 'DisplayLine6', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(360; DisplayLine7; Text[250])
        {
            Caption = 'DisplayLine7', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(370; DisplayLine8; Text[250])
        {
            Caption = 'DisplayLine8', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(380; DisplayLine9; Text[250])
        {
            Caption = 'DisplayLine9', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(400; ExtraInfo1; Text[250])
        {
            Caption = 'ExtraInfo1', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(410; ExtraInfo2; Text[250])
        {
            Caption = 'ExtraInfo2', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(420; ExtraInfo3; Text[250])
        {
            Caption = 'ExtraInfo3', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(500; ShipmentNo; Text[20])
        {
            Caption = 'ShipmentNo', Locked = true;
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
    /// Prepare current NS WhseInquiry Element to be used for buffer. Will populate Key and insert into DB. Method should always be called prior to calling Set-/Get-methods.
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
    /// <param name="_TempElement">The NS WhseInquery Element record to autoincrement (must be a temporary record)</param>
    local procedure AutoIncrementKey(var _TempElement: Record "MOB NS WhseInquery Element")
    var
        TempElement2: Record "MOB NS WhseInquery Element" temporary;
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

    local procedure SetValueAsHtml(_FieldNo: Integer; _PathToSet: Text; _NewHtmlValue: Text)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Rec);
        NsElementMgt.SetValueAsHtml(RecRef, Rec."Key", _PathToSet, _NewHtmlValue, _FieldNo);
        RecRef.SetTable(Rec);
    end;

    procedure GetValue(_PathToGet: Text; _ErrorIfNotFound: Boolean): Text
    begin
        exit(GetValue(0, _PathToGet, _ErrorIfNotFound));
    end;

    procedure GetValue(_PathToGet: Text): Text
    begin
        exit(GetValue(0, _PathToGet, false));
    end;

    local procedure GetValue(_FieldNo: Integer; _PathToGet: Text; _ErrorIfNotFound: Boolean): Text
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Rec);
        exit(NsElementMgt.GetValue(RecRef, Rec."Key", _PathToGet, _FieldNo, _ErrorIfNotFound));
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

    // ---------------------------------------
    // Get/Set procedures for internal Sorting
    // ---------------------------------------

    /// <summary>
    /// Set_Sorting1 .. Set_Sorting5: Five internal sort-fields to indirectly set "Sorting"-tag in the xml file.
    /// "Sorting" intentially has no dedicaded Set_'er to prevent users from trying to set a value that is later overwritten by our standard code. 
    /// </summary>
    /// <remarks>Elements "Sorting" is assigned using sequence determined by key "Sorting1, Sorting2, Sorting3, Sorting4, Sorting5. This behavior can be overriden using OnSetCurrenyKey-events (where available, see API documentation)</remarks>
    procedure Set_Sorting1(_NewValue: Integer)
    var
        MobToolbox: Codeunit "MOB WMS Toolbox";
    begin
        Set_Sorting1(MobToolbox.Int2Sorting(_NewValue, MaxStrLen("Sorting1 (internal)")));
    end;

    procedure Set_Sorting1(_NewValue: Code[250])
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
    var
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
            Set_Sorting1(CopyStr(_NewValueTrue, 1, MaxStrLen("Sorting1 (internal)")))
        else
            Set_Sorting1(CopyStr(_NewValueFalse, 1, MaxStrLen("Sorting1 (internal)")));
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
        Set_Sorting2(MobToolbox.Int2Sorting(_NewValue, MaxStrLen("Sorting2 (internal)")));
    end;

    procedure Set_Sorting2(_NewValue: Code[250])
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
    var
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
            Set_Sorting2(CopyStr(_NewValueTrue, 1, MaxStrLen("Sorting2 (internal)")))
        else
            Set_Sorting2(CopyStr(_NewValueFalse, 1, MaxStrLen("Sorting2 (internal)")));
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
        Set_Sorting3(MobToolbox.Int2Sorting(_NewValue, MaxStrLen("Sorting3 (internal)")));
    end;

    procedure Set_Sorting3(_NewValue: Code[250])
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
    var
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
            Set_Sorting3(CopyStr(_NewValueTrue, 1, MaxStrLen("Sorting3 (internal)")))
        else
            Set_Sorting3(CopyStr(_NewValueFalse, 1, MaxStrLen("Sorting3 (internal)")));
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
        Set_Sorting4(MobToolbox.Int2Sorting(_NewValue, MaxStrLen("Sorting4 (internal)")));
    end;

    procedure Set_Sorting4(_NewValue: Code[250])
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
    var
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
            Set_Sorting4(CopyStr(_NewValueTrue, 1, MaxStrLen("Sorting4 (internal)")))
        else
            Set_Sorting4(CopyStr(_NewValueFalse, 1, MaxStrLen("Sorting4 (internal)")));
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
        Set_Sorting5(MobToolbox.Int2Sorting(_NewValue, MaxStrLen("Sorting5 (internal)")));
    end;

    procedure Set_Sorting5(_NewValue: Code[250])
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
    var
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
            Set_Sorting5(CopyStr(_NewValueTrue, 1, MaxStrLen("Sorting5 (internal)")))
        else
            Set_Sorting5(CopyStr(_NewValueFalse, 1, MaxStrLen("Sorting5 (internal)")));
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

    // ------------------------------
    // Get/Set procedures 
    // ------------------------------

    procedure Set_LookupType(_NewValue: Text)
    begin
        SetValue('LookupType', _NewValue);
    end;

    procedure Get_LookupType(): Text
    begin
        exit(GetValue('LookupType'));
    end;

    procedure Set_Location(_NewValue: Text)
    begin
        SetValue(FieldNo(Location), FieldName(Location), _NewValue);
    end;

    procedure Set_Location(_TrueFalseExpression: Boolean; _NewValueTrue: Text; _NewValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_Location(_NewValueTrue)
        else
            Set_Location(_NewValueFalse);
    end;

    procedure Get_Location(): Text
    begin
        exit(GetValue(FieldNo(Location), FieldName(Location), false));
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

    procedure Set_Number(_NewValue: Text)
    begin
        SetValue(FieldNo(Number), FieldName(Number), _NewValue);
    end;

    procedure Set_Number(_TrueFalseExpression: Boolean; _NewValueTrue: Text; _NewValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_Number(_NewValueTrue)
        else
            Set_Number(_NewValueFalse);
    end;

    procedure Get_Number(): Text
    begin
        exit(GetValue(FieldNo(Number), FieldName(Number), false));
    end;

    procedure Set_Variant(_NewValue: Text)
    begin
        SetValue(FieldNo(Variant), FieldName(Variant), _NewValue);
    end;

    procedure Set_Variant(_TrueFalseExpression: Boolean; _NewValueTrue: Text; _NewValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_Variant(_NewValueTrue)
        else
            Set_Variant(_NewValueFalse);
    end;

    procedure Get_Variant(): Text
    begin
        exit(GetValue(FieldNo(Variant), FieldName(Variant), false));
    end;

    procedure Set_Barcode(_NewValue: Text)
    begin
        SetValue(FieldNo(Barcode), FieldName(Barcode), _NewValue);
    end;

    procedure Set_Barcode(_TrueFalseExpression: Boolean; _NewValueTrue: Text; _NewValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_Barcode(_NewValueTrue)
        else
            Set_Barcode(_NewValueFalse);
    end;

    procedure Get_Barcode(): Text
    begin
        exit(GetValue(FieldNo(Barcode), FieldName(Barcode), false));
    end;

    procedure Set_DisplaySerialNumber(_NewValue: Text)
    begin
        SetValue(FieldNo(DisplaySerialNumber), FieldName(DisplaySerialNumber), _NewValue);
    end;

    procedure Set_DisplaySerialNumber(_TrueFalseExpression: Boolean; _NewValueTrue: Text; _NewValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_DisplaySerialNumber(_NewValueTrue)
        else
            Set_DisplaySerialNumber(_NewValueFalse);
    end;

    procedure Get_DisplaySerialNumber(): Text
    begin
        exit(GetValue(FieldNo(DisplaySerialNumber), FieldName(DisplaySerialNumber), false));
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

    procedure Set_DisplayLotNumber(_NewValue: Text)
    begin
        SetValue(FieldNo(DisplayLotNumber), FieldName(DisplayLotNumber), _NewValue);
    end;

    procedure Set_DisplayLotNumber(_TrueFalseExpression: Boolean; _NewValueTrue: Text; _NewValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_DisplayLotNumber(_NewValueTrue)
        else
            Set_DisplayLotNumber(_NewValueFalse);
    end;

    procedure Get_DisplayLotNumber(): Text
    begin
        exit(GetValue(FieldNo(DisplayLotNumber), FieldName(DisplayLotNumber), false));
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

    procedure Set_DisplayPackageNumber(_NewValue: Text)
    begin
        SetValue(FieldNo(DisplayPackageNumber), FieldName(DisplayPackageNumber), _NewValue);
    end;

    procedure Set_DisplayPackageNumber(_TrueFalseExpression: Boolean; _NewValueTrue: Text; _NewValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_DisplayPackageNumber(_NewValueTrue)
        else
            Set_DisplayPackageNumber(_NewValueFalse);
    end;

    procedure Get_DisplayPackageNumber(): Text
    begin
        exit(GetValue(FieldNo(DisplayPackageNumber), FieldName(DisplayPackageNumber), false));
    end;

    procedure Set_PackageNumber(_NewValue: Text)
    begin
        SetValue(FieldNo(PackageNumber), FieldName(PackageNumber), _NewValue);
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

    procedure Set_DisplayExpirationDate(_NewValue: Text)
    begin
        SetValue(FieldNo(DisplayExpirationDate), FieldName(DisplayExpirationDate), _NewValue);
    end;

    procedure Set_DisplayExpirationDate(_NewValue: Date)
    var
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
    begin
        Set_DisplayExpirationDate(MobWmsToolbox.Date2TextAsDisplayFormat(_NewValue));
    end;

    procedure Set_DisplayExpirationDate(_TrueFalseExpression: Boolean; _NewValueTrue: Text; _NewValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_DisplayExpirationDate(_NewValueTrue)
        else
            Set_DisplayExpirationDate(_NewValueFalse);
    end;

    procedure Set_DisplayExpirationDate(_TrueFalseExpression: Boolean; _NewValueTrue: Date; _NewValueFalse: Date)
    begin
        if _TrueFalseExpression then
            Set_DisplayExpirationDate(_NewValueTrue)
        else
            Set_DisplayExpirationDate(_NewValueFalse);
    end;

    procedure Get_DisplayExpirationDate(): Text
    begin
        exit(GetValue(FieldNo(DisplayExpirationDate), FieldName(DisplayExpirationDate), false));
    end;

    procedure Set_ExpirationDate(_NewValue: Text)
    begin
        SetValue(FieldNo(ExpirationDate), FieldName(ExpirationDate), _NewValue);
    end;

    procedure Set_ExpirationDate(_NewValue: Date)
    var
        MobToolbox: Codeunit "MOB Toolbox";
    begin
        Set_ExpirationDate(MobToolbox.Date2TextResponseFormat(_NewValue));
    end;

    procedure Set_ExpirationDate(_TrueFalseExpression: Boolean; _NewValueTrue: Text; _NewValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_ExpirationDate(_NewValueTrue)
        else
            Set_ExpirationDate(_NewValueFalse);
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

    procedure Set_Bin(_NewValue: Text)
    begin
        SetValue(FieldNo(Bin), FieldName(Bin), _NewValue);
    end;

    procedure Set_Bin(_TrueFalseExpression: Boolean; _NewValueTrue: Text; _NewValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_Bin(_NewValueTrue)
        else
            Set_Bin(_NewValueFalse);
    end;

    procedure Get_Bin(): Text
    begin
        exit(GetValue(FieldNo(Bin), FieldName(Bin), false));
    end;

    procedure Set_Positive(_NewValue: Boolean)
    begin
        if _NewValue then
            SetValue('Positive', 'true') else
            SetValue('Positive', 'false');
    end;

    procedure Set_Quantity(_NewValue: Decimal)
    begin
        Set_Quantity(Format(_NewValue, 0, 9));
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

    procedure Set_UoM(_NewValue: Text)
    begin
        SetValue(FieldNo(UoM), FieldName(UoM), _NewValue);
    end;

    procedure Set_UoM(_TrueFalseExpression: Boolean; _NewValueTrue: Text; _NewValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_UoM(_NewValueTrue)
        else
            Set_UoM(_NewValueFalse);
    end;

    procedure Get_UoM(): Text
    begin
        exit(GetValue(FieldNo(UoM), FieldName(UoM), false));
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

    procedure Set_ExtraInfo1(_NewValue: Text)
    begin
        SetValue(FieldNo(ExtraInfo1), FieldName(ExtraInfo1), _NewValue);
    end;

    procedure Set_ExtraInfo1(_TrueFalseExpression: Boolean; _NewValueTrue: Text; _NewValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_ExtraInfo1(_NewValueTrue)
        else
            Set_ExtraInfo1(_NewValueFalse);
    end;

    procedure Get_ExtraInfo1(): Text
    begin
        exit(GetValue(FieldNo(ExtraInfo1), FieldName(ExtraInfo1), false));
    end;

    procedure Set_ExtraInfo2(_NewValue: Text)
    begin
        SetValue(FieldNo(ExtraInfo2), FieldName(ExtraInfo2), _NewValue);
    end;

    procedure Set_ExtraInfo2(_TrueFalseExpression: Boolean; _NewValueTrue: Text; _NewValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_ExtraInfo2(_NewValueTrue)
        else
            Set_ExtraInfo2(_NewValueFalse);
    end;

    procedure Get_ExtraInfo2(): Text
    begin
        exit(GetValue(FieldNo(ExtraInfo2), FieldName(ExtraInfo2), false));
    end;

    procedure Set_ExtraInfo3(_NewValue: Text)
    begin
        SetValue(FieldNo(ExtraInfo3), FieldName(ExtraInfo3), _NewValue);
    end;

    procedure Set_ExtraInfo3(_TrueFalseExpression: Boolean; _NewValueTrue: Text; _NewValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_ExtraInfo3(_NewValueTrue)
        else
            Set_ExtraInfo3(_NewValueFalse);
    end;

    procedure Get_ExtraInfo3(): Text
    begin
        exit(GetValue(FieldNo(ExtraInfo3), FieldName(ExtraInfo3), false));
    end;

    procedure Set_ReferenceID(_RecRelatedVariant: Variant)
    var
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
    begin
        Set_ReferenceID(MobWmsToolbox.GetReferenceID(_RecRelatedVariant));
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

    procedure Set_ShipmentNo(_NewValue: Text)
    begin
        SetValue(FieldNo(ShipmentNo), FieldName(ShipmentNo), _NewValue);
    end;

    procedure Set_ShipmentNo(_TrueFalseExpression: Boolean; _NewValueTrue: Text; _NewValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_ShipmentNo(_NewValueTrue)
        else
            Set_ShipmentNo(_NewValueFalse);
    end;

    procedure Get_ShipmentNo(): Text
    begin
        exit(GetValue(FieldNo(ShipmentNo), FieldName(ShipmentNo), false));
    end;

    procedure Set_ItemImageID()
    var
        MobWmsMedia: Codeunit "MOB WMS Media";
    begin
        Set_ItemImageID(MobWmsMedia.GetItemImageID(Get_ItemNumber()));
    end;

    /// <summary>
    /// Set value for <ItemImage/>. The value (ItemImageID) is a reference to the image, not the image itself. The images is pulled asynchroniously by the Mobile WMS andriod app. based in the ID's provided here.
    /// </summary>
    procedure Set_ItemImageID(_NewValue: Text)
    begin
        SetValue(FieldName(ItemImage), _NewValue);
    end;

    procedure Set_ItemImageID(_TrueFalseExpression: Boolean; _NewValueTrue: Text; _NewValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_ItemImageID(_NewValueTrue)
        else
            Set_ItemImageID(_NewValueFalse);
    end;

    procedure Get_ItemImageID(): Text
    begin
        exit(GetValue(FieldNo(ItemImage), FieldName(ItemImage), false));
    end;

    // 
    // html : special tag, always sorted first (Sorting = 0) and nodevalue automatically wrapped in <html></html> upon write
    //

    /// <summary>
    /// Set value for <html/>. Upon write the value will be automatically wrapped as <html></html>. Also, writing tags via XmlDom will automatically encode the string (not visible in chrome/edge, but is in notepad)
    /// The <html/> tag will always have sorting = 0 and be the first LookupResponse childElement (needs to be, in order to trigger the html-view)
    /// </summary>
    procedure Set_html(_NewHtmlValue: Text)
    begin
        if _NewHtmlValue <> '' then
            SetValueAsHtml(0, 'html', _NewHtmlValue)
        else
            DeleteValue('html');
    end;

    procedure Set_html(_TrueFalseExpression: Boolean; _NewHtmlValueTrue: Text; _NewHtmlValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_html(_NewHtmlValueTrue)
        else
            Set_html(_NewHtmlValueFalse);
    end;

    //
    // RegistrationCollector
    // 

    /// <summary>
    /// Set RegistationCollector CDATA -- to be replaced by new function _LookupResponse.Set_Workflow(?) when naming conventions is streamlined in mobile app (1.5.4?)
    /// </summary>
    procedure SetRegistrationCollector(var _Steps: Record "MOB Steps Element"; var _AdditionalValuesElement: Record "MOB NS BaseDataModel Element")
    var
        MobToolbox: Codeunit "MOB Toolbox";
        WorkflowInnerText: Text;
    begin
        WorkflowInnerText := MobToolbox.GetWorkflowInnerText(_Steps, _AdditionalValuesElement, "MOB TweakType"::" "); // TweakType attribute not set for RegistrationCollectors (only for Workflows)
        SetValueAsCData('RegistrationCollector', WorkflowInnerText);
    end;

    /// <summary>
    /// Set RegistationCollector CDATA -- to be replaced by new function _LookupResponse.Set_Workflow(?) when naming conventions is streamlined in mobile app (1.5.4?)
    /// </summary>
    procedure SetRegistrationCollector(var _Steps: Record "MOB Steps Element")
    var
        TempDummyAdditionalValuesElement: Record "MOB NS BaseDataModel Element" temporary;
    begin
        TempDummyAdditionalValuesElement.Create();
        SetRegistrationCollector(_Steps, TempDummyAdditionalValuesElement);
    end;

    //
    // Tracking
    //
    procedure SetTracking(var _MobTrackingSetup: Record "MOB Tracking Setup")
    begin
        _MobTrackingSetup.CopyTrackingToLookupResponse(Rec);
    end;

    procedure SetTracking(_EntrySummary: Record "Entry Summary")
    var
        MobTrackingSetup: Record "MOB Tracking Setup";
    begin
        MobTrackingSetup.CopyTrackingFromEntrySummary(_EntrySummary);
        SetTracking(MobTrackingSetup);
    end;

    procedure SetTracking(_WhseEntry: Record "Warehouse Entry")
    var
        MobTrackingSetup: Record "MOB Tracking Setup";
    begin
        MobTrackingSetup.CopyTrackingFromWhseEntry(_WhseEntry);
        SetTracking(MobTrackingSetup);
    end;

    procedure SetTracking(_ItemLedgerEntry: Record "Item Ledger Entry")
    var
        MobTrackingSetup: Record "MOB Tracking Setup";
    begin
        MobTrackingSetup.CopyTrackingFromItemLedgerEntry(_ItemLedgerEntry);
        SetTracking(MobTrackingSetup);
    end;

    /// <summary>
    /// RegisterTracking is generally not used for unplanned functions but is used in the Production area for adhoc steps customization.
    /// </summary>
    internal procedure SetRegisterTracking(var _MobTrackingSetup: Record "MOB Tracking Setup")
    begin
        _MobTrackingSetup.CopyTrackingRequiredToLookupResponse(Rec);
    end;

    procedure SetDisplayTracking(var _MobTrackingSetup: Record "MOB Tracking Setup")
    begin
        _MobTrackingSetup.CopyTrackingToLookupResponseAsDisplayTracking(Rec);
    end;

    procedure SetDisplayTracking(_EntrySummary: Record "Entry Summary")
    var
        MobTrackingSetup: Record "MOB Tracking Setup";
    begin
        MobTrackingSetup.CopyTrackingFromEntrySummary(_EntrySummary);
        SetDisplayTracking(MobTrackingSetup);
    end;

    procedure SetDisplayTracking(_WhseEntry: Record "Warehouse Entry")
    var
        MobTrackingSetup: Record "MOB Tracking Setup";
    begin
        MobTrackingSetup.CopyTrackingFromWhseEntry(_WhseEntry);
        SetDisplayTracking(MobTrackingSetup);
    end;

    procedure SetDisplayTracking(_ItemLedgerEntry: Record "Item Ledger Entry")
    var
        MobTrackingSetup: Record "MOB Tracking Setup";
    begin
        MobTrackingSetup.CopyTrackingFromItemLedgerEntry(_ItemLedgerEntry);
        SetDisplayTracking(MobTrackingSetup);
    end;

}
