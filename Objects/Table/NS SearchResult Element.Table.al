table 81393 "MOB NS SearchResult Element"
{
    Access = Public;
    Caption = 'MOB NS SearchResult Element', Locked = true;

    fields
    {
        field(1; "Key"; Integer)
        {
            Caption = 'Key', Locked = true;
            DataClassification = SystemMetadata;
            AutoIncrement = true;       // Business Central 365 temporary tables not supported
        }

        field(10; IdValue; Text[250])
        {
            Caption = 'IdValue', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(20; Name; Text[250])
        {
            Caption = 'Name', Locked = true;
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
        MUST_BE_TEMPORARY_Err: Label 'Internal error: %1 must be a temporary record.', Locked = true;

    trigger OnDelete()
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Rec);
        NsElementMgt.DeleteValues(RecRef); // Doesn't work if called through DeleteAll. Handled in Create procedure
    end;

    /// <summary>
    /// Prepare current NS SearchResult Element to be used for buffer. Will populate Key and insert into DB. Method should always be called prior to calling Set-/Get-methods.
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
        TestField(IdValue);
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
    /// <param name="_TempElement">The NS SearchResult Element record to autoincrement (must be a temporary record)</param>
    local procedure AutoIncrementKey(var _TempElement: Record "MOB NS SearchResult Element")
    var
        TempElement2: Record "MOB NS SearchResult Element" temporary;
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

    procedure DeleteValue(_PathToDelete: Text)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Rec);
        NsElementMgt.DeleteValue(RecRef, Rec."Key", _PathToDelete);
        RecRef.SetTable(Rec);
    end;

    /// <summary>
    /// Syncronize current NS SearchResult Element record  to internal NodeValue Buffer. All text fields are syncronized excluding field no. range 800..999.
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

    procedure Set_IdValue(_NewValue: Text)
    begin
        SetValue(FieldNo(IdValue), FieldName(IdValue), _NewValue);
    end;

    procedure Set_IdValue(_TrueFalseExpression: Boolean; _NewValueTrue: Text; _NewValueFalse: Text)
    begin
        if _TrueFalseExpression then
            Set_IdValue(_NewValueTrue)
        else
            Set_IdValue(_NewValueFalse);
    end;

    procedure Get_IdValue(): Text
    begin
        exit(GetValue(FieldNo(IdValue), FieldName(IdValue), false));
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

    // 
    // html : special tag, always sorted first (Sorting = 0) and nodevalue automatically wrapped in <html></html> upon write
    //

    /// <summary>
    /// Set value for <html/>. Upon write the value will be automatically wrapped as <html></html>. Also, writing tags via XmlDom will automatically encode the string (not visible in chrome/edge, but is in notepad)
    /// The <html/> tag will always have sorting = 0 and be the first SearchResponse childElement (needs to be, in order to trigger the html-view)
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

}
