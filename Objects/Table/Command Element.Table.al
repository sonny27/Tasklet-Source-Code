table 81285 "MOB Command Element"
{
    Access = Public;
    // Supports mobile device command generation for License Plate operations
    Caption = 'MOB Command Element', Locked = true;
    fields
    {
        field(1; "Key"; Integer)
        {
            Caption = 'Key', Locked = true;
            DataClassification = SystemMetadata;
            AutoIncrement = false;       // Business Central 365 temporary tables not supported
        }
        field(2; Id; Text[50])
        {
            Caption = 'Id', Locked = true;
            DataClassification = SystemMetadata;
        }
        // Note: Field No cannot be > 100000 due to buffer sorting
        field(6; NodeName; Text[50])
        {
            Caption = 'NodeName', Locked = true;
            DataClassification = SystemMetadata;
        }

        // Fields 800..999 are used for internal purposes and not written to file (use assigning field directly, rather than use SetValue)
        field(900; Type; Enum "MOB Command Element Type")
        {
            Caption = 'Type', Locked = true;
            DataClassification = SystemMetadata;
        }
    }
    keys
    {
        key(Key1; "Key")
        {
        }
        key(Key2; "Type", Id)
        {
        }
    }

    var
        NsElementMgt: Codeunit "MOB NS Element Management";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        MUST_BE_TEMPORARY_Err: Label 'Internal error: %1 must be a temporary record.', Locked = true;
        CommandElementType: Enum "MOB Command Element Type";
        MobColorCode: Enum "MOB Color Code";

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

    /// <summary>
    /// Initialize for a new command element with specific ID.
    /// </summary>
    /// <param name="_NodeName">The name of the childnode of the ReponseData-node</param>
    /// <param name="_ID">The unique identifier for this command element</param>
    procedure Create(_NodeName: Text; _ID: Text)
    var
        RecRef: RecordRef;
    begin
        if not IsTemporary() then
            Error(MUST_BE_TEMPORARY_Err, TableCaption());

        Init();
        "Key" := 0;

        NodeName := _NodeName;
        Id := _ID;

        // AutoIncrement property not supported for Business Central 365 temporary tables
        AutoIncrementKey(Rec);
        Insert();

        // Make sure all existing values in Mob Node Value Buffer is cleared. Values may hang if step was deleted with DeleteAll
        RecRef.GetTable(Rec);
        NsElementMgt.DeleteValues(RecRef);
    end;

    procedure Save()
    begin
        TestField("Key");
        SyncronizeTableToBuffer();
        Modify();
    end;

    procedure GetSharedNodeValueBuffer(var _ToNodeValueBuffer: Record "MOB NodeValue Buffer")
    begin
        TestField("Key");
        NsElementMgt.GetSharedNodeValueBuffer("Key", _ToNodeValueBuffer);
    end;

    /// <summary>
    /// Autoincrement primary key "Key" since Autoincrement table property is not supported for BC temporary tables in cloud, hence implemented programmatically
    /// </summary>
    /// <param name="_TempElement">The MOB Command Element record to autoincrement (must be a temporary record)</param>
    local procedure AutoIncrementKey(var _TempElement: Record "MOB Command Element")
    var
        TempElement2: Record "MOB Command Element" temporary;
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

    // --------- PIN Commands ---------------

    /// <summary>
    /// Sets the pin command from the name value.
    /// </summary>
    /// <param name="_Name"></param>
    /// <param name="_Value"></param>
    procedure Create_Pin(_Name: Text; _Value: Text)
    begin
        Create('pin', '');
        SetValue('name', _Name);
        SetValue('value', _Value);
        SetValue('backgroundColor', Format(MobColorCode::Blue));

        // Set Type for XML generation
        Type := CommandElementType::Pin;
        Save();
    end;

    procedure Set_Pin_BackgroundColor(_BackgroundColor: Text)
    begin
        TestField(Type, CommandElementType::Pin);
        TestField(Id);
        SetValue('backgroundColor', _BackgroundColor);
        Modify();
    end;
    // --------- FILTER Commands ---------------

    procedure Create_Filter(_Id: Text; _DisplayText: Text)
    begin
        Create('filter', _Id);
        SetValue('icon', 'LicensePlate');
        SetValue('text', _DisplayText);
        SetValue('backgroundColor', Format(MobColorCode::Green));

        // Internal fields, not used direcly in XML
        Type := CommandElementType::Filter;

        Save();
    end;

    procedure Set_Filter_Include(_Name: Text; _Value: Text)
    var
        IncludeIndex: Integer;
    begin
        TestField(Type, CommandElementType::Filter);
        TestField(Id);

        // Find next available include index
        IncludeIndex := GetNextIncludeIndex();

        // Store each include as separate entries with unique index and name/value
        SetValue('include[' + Format(IncludeIndex) + ']/name', _Name);
        SetValue('include[' + Format(IncludeIndex) + ']/value', _Value);

        Modify();
    end;

    procedure Set_Filter_Values_Element(_ElementName: Text; _ElementValue: Text)
    begin
        TestField(Type, CommandElementType::Filter);
        TestField(Id);

        SetValue('values/' + _ElementName, _ElementValue);
        Modify();
    end;

    procedure Set_Filter_BackgroundColor(_BackgroundColor: Text)
    begin
        TestField(Type, CommandElementType::Filter);
        TestField(Id);

        SetValue('backgroundColor', _BackgroundColor);
        Modify();
    end;

    procedure Set_Filter_DisplayText(_DisplayText: Text)
    begin
        TestField(Type, CommandElementType::Filter);
        TestField(Id);

        SetValue('text', _DisplayText);
        Modify();
    end;

    procedure Set_Filter_Icon(_Icon: Text)
    begin
        TestField(Type, CommandElementType::Filter);
        TestField(Id);

        SetValue('icon', _Icon);
        Modify();
    end;

    /// <summary>
    /// Creates a filter command for license plate picking with values container and elements
    /// </summary>
    internal procedure Create_LicensePlate_Filter(_Id: Text; var _MobLicensePlate: Record "MOB License Plate"; var _RequestValues: Record "MOB NS Request Element")
    var
        MobToolbox: Codeunit "MOB Toolbox";
        DisplayText: Text;
    begin
        // Build Text for the license plate comment etc.
        if _MobLicensePlate.Comment <> '' then
            DisplayText := _MobLicensePlate.Comment + MobToolbox.CRLFSeparator();

        DisplayText += MobWmsLanguage.GetMessage('FROM_LICENSEPLATE') + ': ' + _MobLicensePlate."No.";

        // Create the main filter element: <filter id="abc" icon="filter" text="Pick from LP" backgroundColor="#rrggbbaa">
        Create_Filter(_Id, DisplayText);

        // Create values elements under filter using current record
        Set_Filter_Values_Element('FromBin', _MobLicensePlate."Bin Code");
        Set_Filter_Values_Element('FromLicensePlate', _MobLicensePlate."No.");

        OnAfterCreateLicensePlateFilter(Rec, _MobLicensePlate, _RequestValues);
    end;

    // --------- Helper Functions ---------------

    local procedure GetNextIncludeIndex(): Integer
    var
        TempValueBuffer: Record "MOB NodeValue Buffer" temporary;
        HighestIndex: Integer;
        CurrentIndex: Integer;
        BracketStartPos: Integer;
        BracketEndPos: Integer;
        IndexText: Text;
    begin
        HighestIndex := 0; // Initialize to 0

        // Get the shared buffer to find existing include entries
        GetSharedNodeValueBuffer(TempValueBuffer);

        // Look for existing include[x] entries to find the highest index
        TempValueBuffer.Reset();
        if TempValueBuffer.FindSet() then
            repeat
                if TempValueBuffer.Path.StartsWith('include[') then begin
                    BracketStartPos := TempValueBuffer.Path.IndexOf('[');
                    BracketEndPos := TempValueBuffer.Path.IndexOf(']');
                    if (BracketStartPos > 0) and (BracketEndPos > BracketStartPos) then begin
                        IndexText := TempValueBuffer.Path.Substring(BracketStartPos + 1, BracketEndPos - BracketStartPos - 1);
                        if Evaluate(CurrentIndex, IndexText) then
                            if CurrentIndex > HighestIndex then
                                HighestIndex := CurrentIndex;
                    end;
                end;
            until TempValueBuffer.Next() = 0;

        // Return next available index
        exit(HighestIndex + 1);
    end;

    // --------- Event Procedures ---------------

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateLicensePlateFilter(var _CommandElement: Record "MOB Command Element"; var _MobLicensePlate: Record "MOB License Plate"; var _RequestValues: Record "MOB NS Request Element")
    begin
    end;
}
