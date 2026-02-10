codeunit 81362 "MOB External File Upload"
{
    Access = Internal;

    /* #if BC26+ */
    Permissions =
        tabledata "Document Attachment" = rm,
        tabledata "MOB Setup" = r,
        tabledata "MOB WMS Media Queue" = rm,
        tabledata "Tenant Media" = r;

    var
        IsBatchTransfer: Boolean;

    internal procedure StorePictureExternally(var _MobWmsMediaQueue: Record "MOB WMS Media Queue"): Boolean
    begin
        if not MustStoreExternally() then
            exit(false);
        if IsItemPicture(_MobWmsMediaQueue) then
            exit(false);
        if _MobWmsMediaQueue.Picture.Count() = 0 then
            exit(false);

        if not IsBatchTransfer then
            CheckAttachImageScenarioAccount();

        exit(TransferMediaQueuePicture(_MobWmsMediaQueue));
    end;

    internal procedure InitializeBatchTransfer()
    begin
        CheckAttachImageScenarioAccount();
        IsBatchTransfer := true;
    end;

    local procedure TransferMediaQueuePicture(var _MobWmsMediaQueue: Record "MOB WMS Media Queue"): Boolean
    var
        TenantMedia: Record "Tenant Media";
        DocAttRecRef: RecordRef;
        UsedForAttachments: Boolean;
        FileInStream: InStream;
        FileName: Text;
    begin
        if not TenantMedia.Get(_MobWmsMediaQueue.Picture.Item(1)) then
            exit(false);
        if not TenantMedia.Content.HasValue() then
            exit(false);

        UsedForAttachments := FindDocumentAttachmentsWithMedia(TenantMedia, DocAttRecRef);

        TenantMedia.CalcFields(Content);
        TenantMedia.Content.CreateInStream(FileInStream);

        FileName := GetUniqueFileName(_MobWmsMediaQueue);

        if not CreateFileInExternalFileStorage(Enum::"File Scenario"::"MOB Attach Image", FileInStream, FileName) then
            exit(false);

        UpdateMediaQueue(_MobWmsMediaQueue, FileName);
        if UsedForAttachments then
            UpdateDocumentAttachments(DocAttRecRef, _MobWmsMediaQueue);

        exit(true);
    end;

    local procedure CreateFileInExternalFileStorage(_FileScenario: Enum "File Scenario"; var _FileInStream: InStream; _FileName: Text): Boolean
    var
        ExternalFileStorage: Codeunit "External File Storage";
    begin
        ExternalFileStorage.Initialize(_FileScenario);
        exit(ExternalFileStorage.CreateFile(_FileName, _FileInStream));
    end;

    local procedure UpdateMediaQueue(var _MobWmsMediaQueue: Record "MOB WMS Media Queue"; _FileName: Text)
    var
        TempFileAccount: Record "File Account" temporary;
        FileScenario: Codeunit "File Scenario";
    begin
        FileScenario.GetFileAccount(Enum::"File Scenario"::"MOB Attach Image", TempFileAccount);

        _MobWmsMediaQueue."Ext. File Account Id" := TempFileAccount."Account Id";
        _MobWmsMediaQueue."Ext. Storage Connector" := TempFileAccount.Connector;
        _MobWmsMediaQueue."Ext. File Name" := _FileName;
        Clear(_MobWmsMediaQueue.Picture); // This also deletes the Tenant Media record (even if the media is referenced from document attachments)
        _MobWmsMediaQueue.Modify(true);
    end;

    local procedure FindDocumentAttachmentsWithMedia(_TenantMedia: Record "Tenant Media"; var _DocAttRecRef: RecordRef): Boolean
    var
        DocumentAttachment: Record "Document Attachment";
        FldRef: FieldRef;
    begin
        Clear(_DocAttRecRef);
        _DocAttRecRef.Open(Database::"Document Attachment");
        FldRef := _DocAttRecRef.Field(DocumentAttachment.FieldNo("Document Reference ID"));
        FldRef.SetFilter('=%1', _TenantMedia.ID);
        exit(not _DocAttRecRef.IsEmpty());
    end;

    local procedure UpdateDocumentAttachments(_DocAttRecRef: RecordRef; var _MobWmsMediaQueue: Record "MOB WMS Media Queue")
    var
        DocumentAttachment: Record "Document Attachment";
        FileMgt: Codeunit "File Management";
    begin
        if _DocAttRecRef.FindSet() then
            repeat
                _DocAttRecRef.SetTable(DocumentAttachment);
                DocumentAttachment."File Name" := FileMgt.GetFileNameWithoutExtension(_MobWmsMediaQueue."Ext. File Name");
                DocumentAttachment."File Extension" := FileMgt.GetExtension(_MobWmsMediaQueue."Ext. File Name");
                DocumentAttachment."MOB Ext. File Account Id" := _MobWmsMediaQueue."Ext. File Account Id";
                DocumentAttachment."MOB Ext. Storage Connector" := _MobWmsMediaQueue."Ext. Storage Connector";
                Clear(DocumentAttachment."Document Reference ID");
                DocumentAttachment.Modify(false);
            until _DocAttRecRef.Next() = 0;
        _DocAttRecRef.Close();
    end;

    local procedure GetUniqueFileName(_MobWmsMediaQueue: Record "MOB WMS Media Queue"): Text
    var
        FileMgt: Codeunit "File Management";
        FileNameLbl: Label '%1_%2_%3.%4', Locked = true;
        Extension: Text;
        FileName: Text;
        NameWOExt: Text;
    begin
        FileName := FileMgt.GetFileName(_MobWmsMediaQueue."Image Id");
        NameWOExt := FileMgt.GetFileNameWithoutExtension(FileName);
        Extension := FileMgt.GetExtension(FileName);
        FileName := FileMgt.GetSafeFileName(StrSubstNo(FileNameLbl, CompanyProperty.DisplayName(), NameWOExt, _MobWmsMediaQueue."Device ID", Extension));
        exit(FileName); // If file with this name already exists in the external storage, it will be overwritten
    end;

    local procedure MustStoreExternally(): Boolean
    var
        MobSetup: Record "MOB Setup";
    begin
        if IsBatchTransfer then
            exit(true);
        MobSetup.ReadIsolation(IsolationLevel::ReadCommitted);
        MobSetup.SetLoadFields("Use External Storage_AttaImage");
        if MobSetup.Get() then
            exit(MobSetup."Use External Storage_AttaImage");
    end;

    local procedure CheckAttachImageScenarioAccount()
    var
        TempFileAccount: Record "File Account" temporary;
        FileScenario: Codeunit "File Scenario";
        NoFileAccountAssignedErr: Label 'The file scenario "%1" is not assigned to any external file account. Please assign the scenario to be able to store images externally.', Comment = '%1 - File Scenario Caption';
    begin
        if not FileScenario.GetFileAccount(Enum::"File Scenario"::"MOB Attach Image", TempFileAccount) then
            Error(NoFileAccountAssignedErr, Format(Enum::"File Scenario"::"MOB Attach Image", 0, 0));
    end;

    local procedure IsItemPicture(_MobWmsMediaQueue: Record "MOB WMS Media Queue"): Boolean
    begin
        exit(_MobWmsMediaQueue."Record ID".TableNo() = Database::Item);
    end;
    /* #endif */
}
