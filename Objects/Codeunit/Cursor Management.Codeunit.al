codeunit 81393 "MOB Cursor Management"
{
    Access = Public;
    // Backup and restore record cursors and view

    var
        xRecRef: RecordRef;
        xView: Text;
        CALL_ONLY_ONCE_Err: Label 'Internal error: "Cursor Management".Backup() has been called already, but can only be called once per codeunit instance. Use Clear() to clear current stored values.', Locked = true;
        BACKUP_NOT_CALLED_Err: Label 'Internal error: "Cursor Management".Restore() can only be called when .Backup() has previously been called.', Locked = true;


    procedure Backup(var _NsBaseDataModelElement: Record "MOB NS BaseDataModel Element")
    begin
        xRecRef.GetTable(_NsBaseDataModelElement);
        Backup(xRecRef);
    end;

    procedure Backup(var _NsWhseInquiryElement: Record "MOB NS WhseInquery Element")
    begin
        xRecRef.GetTable(_NsWhseInquiryElement);
        Backup(xRecRef);
    end;

    procedure Backup(var _NsSearchResultElement: Record "MOB NS SearchResult Element")
    begin
        xRecRef.GetTable(_NsSearchResultElement);
        Backup(xRecRef);
    end;

    procedure Backup(var _NodeValueBuffer: Record "MOB NodeValue Buffer")
    begin
        xRecRef.GetTable(_NodeValueBuffer);
        Backup(xRecRef);
    end;

    procedure Backup(var _StepsElement: Record "MOB Steps Element")
    begin
        xRecRef.GetTable(_StepsElement);
        Backup(xRecRef);
    end;

    local procedure Backup(var _RecRef: RecordRef)
    begin
        TestCanBackup();

        xRecRef := _RecRef;
        xView := _RecRef.GetView();
    end;

    procedure Restore(var _ToNsBaseDataModelElement: Record "MOB NS BaseDataModel Element")
    begin
        TestCanRestore();

        xRecRef.SetTable(_ToNsBaseDataModelElement);
        _ToNsBaseDataModelElement.SetView(xView);
    end;

    procedure Restore(var _ToNsWhseInquiryElement: Record "MOB NS WhseInquery Element")
    begin
        TestCanRestore();

        xRecRef.SetTable(_ToNsWhseInquiryElement);
        _ToNsWhseInquiryElement.SetView(xView);
    end;

    procedure Restore(var _ToNsSearchResultElement: Record "MOB NS SearchResult Element")
    begin
        TestCanRestore();

        xRecRef.SetTable(_ToNsSearchResultElement);
        _ToNsSearchResultElement.SetView(xView);
    end;

    procedure Restore(var _ToNodeValueBuffer: Record "MOB NodeValue Buffer")
    begin
        TestCanRestore();

        xRecRef.SetTable(_ToNodeValueBuffer);
        _ToNodeValueBuffer.SetView(xView);
    end;

    procedure Restore(var _StepsElement: Record "MOB Steps Element")
    begin
        TestCanRestore();

        xRecRef.SetTable(_StepsElement);
        _StepsElement.SetView(xView);
    end;

    local procedure TestCanBackup()
    begin
        if xView <> '' then
            Error(CALL_ONLY_ONCE_Err);
    end;

    local procedure TestCanRestore()
    begin
        if xView = '' then
            Error(BACKUP_NOT_CALLED_Err);
    end;
}
