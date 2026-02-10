table 81387 "MOB NodeValue Buffer"
{
    Access = Public;
    Caption = 'MOB NodeValue Buffer', Locked = true;

    fields
    {
        /// <summary>
        /// FK "MOB NodeValue Buffer"."Reference Key" = PK "MOB NS BaseDataModel Element".Key
        /// </summary>
        field(1; "Reference Key"; Integer)
        {
            Caption = 'Reference Key', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(5; Path; Text[250])
        {
            Caption = 'Path', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(10; Sorting; Integer)
        {
            Caption = 'Sorting', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(20; "Value"; Text[250])
        {
            Caption = 'Value', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(30; "Value BLOB"; Blob)
        {
            Caption = 'Value BLOB', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(40; IsCData; Boolean)
        {
            Caption = 'IsCData', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(50; IsHtml; Boolean)
        {
            Caption = 'IsHtml', Locked = true;
            DataClassification = SystemMetadata;
        }

    }

    keys
    {
        key(RefKeyPathKey; "Reference Key", Path)
        {
        }
        key(PathKey; Path)
        {
        }
        key(RefKeySortingKey; "Reference Key")
        {
        }
        key(SortingKey; Sorting)
        {
        }
        key(RefKeySortingKey2; "Reference Key", Sorting)
        {
        }
    }

    var
    // NOTE: DO NOT CREATE GLOBAL VARIABLES AT THIS TABLE
    // NOTE: VALLUES WILL BE LOST DURING AUTOINCREMENTSORTING()

    trigger OnInsert()
    begin
        TestField("Reference Key");

        // nodes with associated fields in element table must come before other nodes (i.e. attributes for same nodes) to ensure "parent" node is properly written first
        // <html>-node must return sorting = 0 to insert node prior to all other nodes in order for WhseInquiry html lookup responses to work
        if ("Sorting" = 0) and (Path <> 'html') then
            AutoIncrementSorting(Rec);
    end;

    procedure GetValue(): Text
    var
        MobTypeHelper: Codeunit "MOB Type Helper";
        IStream: InStream;
        CR: Text;
    begin
        CalcFields("Value BLOB");
        if not "Value BLOB".HasValue() then
            exit(Value);
        CR[1] := 10;
        "Value BLOB".CreateInStream(IStream, TextEncoding::UTF8);
        exit(MobTypeHelper.ReadAsTextWithSeparator(IStream, CR));
    end;

    internal procedure SetValue(_NewValue: Text; _Sorting: Integer)
    var
    begin
        SetValueWithoutModifying(_NewValue, false, false);
        Sorting := _Sorting;    // may be FieldNo or 0 -- if zero, is set to 100000+ during AutoIncrementSorting (or left as 0 if path if 'html')
        if not Insert(true) then
            Modify();
    end;

    internal procedure SetValueAsCData(_NewCDataValue: Text; _Sorting: Integer)
    var
    begin
        SetValueWithoutModifying(_NewCDataValue, true, false);
        Sorting := _Sorting;    // may be FieldNo or 0 -- if zero, is set to 100000+ during AutoIncrementSorting (or left as 0 if path if 'html')
        if not Insert(true) then
            Modify();
    end;

    internal procedure SetValueAsHtml(_NewHtmlValue: Text; _Sorting: Integer)
    var
    begin
        // html values are currently not always parsed correctly at lookup responses on mobile device if written as CDATA (displayed output is i.e. 'test]]>') (Android 1.4.1.1)
        // currently writing html-content as plain text with no CDATA (wrapped in single or double <html>-tags, node is being automatically htmlencoded when writing using XmlDom)
        SetValueWithoutModifying(_NewHtmlValue, false, true);
        Sorting := _Sorting;    // may be FieldNo or 0 -- if zero, is set to 100000+ during AutoIncrementSorting (or left as 0 if path if is 'html')
        if not Insert(true) then
            Modify();
    end;

    local procedure SetValueWithoutModifying(_NewValue: Text; _IsCData: Boolean; _IsHtml: Boolean)
    var
        OStream: OutStream;
    begin
        Clear("Value BLOB");
        Value := CopyStr(_NewValue, 1, MaxStrLen(Value));
        IsCData := _IsCData;
        IsHtml := _IsHtml;
        if StrLen(_NewValue) <= MaxStrLen(Value) then
            exit; // No need to store anything in the blob
        if _NewValue = '' then
            exit;
        "Value BLOB".CreateOutStream(OStream, TextEncoding::UTF8);
        OStream.WriteText(_NewValue);
    end;

    local procedure AutoIncrementSorting(var _ValueBuffer: Record "MOB NodeValue Buffer")
    var
        CursorMgt: Codeunit "MOB Cursor Management";
        NextSorting: Integer;
    begin
        // nodes with associated fields in element table must come before other nodes (i.e. attributes for same nodes) to ensure "parent" node is properly written first

        if (_ValueBuffer."Sorting" = 0) then begin
            CursorMgt.Backup(_ValueBuffer);

            _ValueBuffer.SetCurrentKey(Sorting);
            if (_ValueBuffer.FindLast() and (_ValueBuffer.Sorting >= 100000)) then
                NextSorting := _ValueBuffer.Sorting + 1
            else
                NextSorting := 100000;

            CursorMgt.Restore(_ValueBuffer);
            _ValueBuffer.Sorting := NextSorting;
        end;
    end;
}
