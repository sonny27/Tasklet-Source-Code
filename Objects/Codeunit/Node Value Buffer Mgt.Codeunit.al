codeunit 81391 "MOB NodeValue Buffer Mgt."
{
    Access = Public;
    var
        TempValueBuffer: Record "MOB NodeValue Buffer" temporary;
        PathWasNeverSetErr: Label 'Internal error: NodeValueBufferMgt.GetValue(): Path %1 was never set.', Locked = true;

    internal procedure SetValue(_ReferenceKey: Integer; _PathToSet: Text[250]; _NewValue: Text; _Sorting: Integer)
    begin
        if (not TempValueBuffer.Get(_ReferenceKey, _PathToSet)) then
            TempValueBuffer.Init();

        TempValueBuffer."Reference Key" := _ReferenceKey;
        TempValueBuffer.TestField("Reference Key");
        TempValueBuffer.Path := _PathToSet;   // intentional overflow error if path too long
        TempValueBuffer.SetValue(_NewValue, _Sorting);   // _Sorting may be FieldNo or 0 -- if 0, is set to 100000+ during AutoIncrement
    end;

    internal procedure SetValueAsCData(_ReferenceKey: Integer; _PathToSet: Text[250]; _NewCDataValue: Text; _Sorting: Integer)
    begin
        if (not TempValueBuffer.Get(_ReferenceKey, _PathToSet)) then
            TempValueBuffer.Init();

        TempValueBuffer."Reference Key" := _ReferenceKey;
        TempValueBuffer.TestField("Reference Key");
        TempValueBuffer.Path := _PathToSet;   // intentional overflow error if path too long
        TempValueBuffer.SetValueAsCData(_NewCDataValue, _Sorting);   // _Sorting may be FieldNo or 0 -- if 0, is set to 100000+ during AutoIncrement
    end;

    internal procedure SetValueAsHtml(_ReferenceKey: Integer; _PathToSet: Text[250]; _NewHtmlValue: Text; _Sorting: Integer)
    begin
        if (not TempValueBuffer.Get(_ReferenceKey, _PathToSet)) then
            TempValueBuffer.Init();

        TempValueBuffer."Reference Key" := _ReferenceKey;
        TempValueBuffer.TestField("Reference Key");
        TempValueBuffer.Path := _PathToSet;   // intentional overflow error if path too long
        TempValueBuffer.SetValueAsHtml(_NewHtmlValue, _Sorting);   // _Sorting may be FieldNo or 0 -- if 0, is set to 100000+ during AutoIncrement
    end;

    internal procedure GetValue(_ReferenceKey: Integer; _PathToGet: Text[250]; _ErrorIfNotExists: Boolean): Text
    begin
        if (TempValueBuffer.Get(_ReferenceKey, _PathToGet)) then
            exit(TempValueBuffer.GetValue());

        if _ErrorIfNotExists then
            Error(PathWasNeverSetErr, _PathToGet);

        exit('');
    end;


    // ----------------------------
    // DATA METHODS                     
    // ----------------------------

    internal procedure Exists(_ReferenceKey: Integer; _Path: Text): Boolean
    begin
        exit(TempValueBuffer.Get(_ReferenceKey, _Path));
    end;

    internal procedure GetSharedNodeValueBuffer(_ReferenceKey: Integer; var _ToNodeValueBuffer: Record "MOB NodeValue Buffer")
    begin
        _ToNodeValueBuffer.Copy(TempValueBuffer, true);

        _ToNodeValueBuffer.Reset();
        _ToNodeValueBuffer.SetRange("Reference Key", _ReferenceKey);
    end;

    internal procedure DeleteValue(_ReferenceKey: Integer; _Path: Text)
    begin
        if (TempValueBuffer.Get(_ReferenceKey, _Path)) then
            TempValueBuffer.Delete();
    end;

    internal procedure DeleteValues(_ReferenceKey: Integer)
    var
        CursorMgt: Codeunit "MOB Cursor Management";
    begin
        CursorMgt.Backup(TempValueBuffer);
        TempValueBuffer.SetRange("Reference Key", _ReferenceKey);
        TempValueBuffer.DeleteAll();
        CursorMgt.Restore(TempValueBuffer);
    end;

}
