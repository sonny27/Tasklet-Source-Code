codeunit 81364 "MOB External File Download"
{
    Access = Internal;

    /* #if BC26+ */
    Permissions =
        tabledata "Document Attachment" = rm,
        tabledata "MOB WMS Media Queue" = rm;

    var
        TempScenarioAccount: Record "File Account" temporary;

    // Download initialised from "Document Attachment"
    [EventSubscriber(ObjectType::Table, Database::"Document Attachment", OnBeforeHasContent, '', false, false)]
    local procedure HandleExternalStorage_OnBeforeHasContent_DocumentAttachment(var DocumentAttachment: Record "Document Attachment"; var IsHandled: Boolean; var AttachmentIsAvailable: Boolean)
    begin
        if IsHandled then
            exit;
        if DocumentAttachment.MobIsExternalFile() then begin
            AttachmentIsAvailable := true;
            IsHandled := true;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Document Attachment", OnBeforeExportToStream, '', false, false)]
    local procedure HandleExternalStorage_OnBeforeExportToStream_DocumentAttachment(var DocumentAttachment: Record "Document Attachment"; var IsHandled: Boolean; var AttachmentOutStream: OutStream)
    var
        FileInStream: InStream;
        AccountInfoUpdated: Boolean;
    begin
        if IsHandled then
            exit;
        if not DocumentAttachment.MobIsExternalFile() then
            exit;
        if GetFileAsStream(DocumentAttachment."File Name" + '.' + DocumentAttachment."File Extension", FileInStream, DocumentAttachment."MOB Ext. File Account Id", DocumentAttachment."MOB Ext. Storage Connector", AccountInfoUpdated) then begin
            CopyStream(AttachmentOutStream, FileInStream);
            if AccountInfoUpdated then
                DocumentAttachment.Modify(true);
            IsHandled := true;
        end;
    end;

    // Download initialised from "MOB WMS Media Queue"
    internal procedure DownloadFileFromExternalStorage(_MobWmsMediaQueue: Record "MOB WMS Media Queue"): Boolean
    var
        FileInStream: InStream;
        AccountInfoUpdated: Boolean;
    begin
        if not _MobWmsMediaQueue.IsExternalFile() then
            exit(false);
        if not GetFileAsStream(_MobWmsMediaQueue."Ext. File Name", FileInStream, _MobWmsMediaQueue."Ext. File Account Id", _MobWmsMediaQueue."Ext. Storage Connector", AccountInfoUpdated) then
            exit(false);
        if AccountInfoUpdated then
            _MobWmsMediaQueue.Modify(true);

        exit(File.DownloadFromStream(FileInStream, '', '', '', _MobWmsMediaQueue."Ext. File Name"));
    end;

    // Download/view initialised from device - GetMedia
    internal procedure GetFileFromExternalStorageAsStream(_MobWmsMediaQueue: Record "MOB WMS Media Queue"; var _FileInStream: InStream): Boolean
    var
        AccountInfoUpdated: Boolean;
    begin
        if not _MobWmsMediaQueue.IsExternalFile() then
            exit(false);
        if GetFileAsStream(_MobWmsMediaQueue."Ext. File Name", _FileInStream, _MobWmsMediaQueue."Ext. File Account Id", _MobWmsMediaQueue."Ext. Storage Connector", AccountInfoUpdated) then begin
            if AccountInfoUpdated then
                _MobWmsMediaQueue.Modify(true);
            exit(true);
        end;
    end;

    local procedure GetFileAsStream(_FileName: Text[250]; var _FileInStream: InStream; var _FileAccountId: Guid; var _FileAccountConnector: Enum "Ext. File Storage Connector"; var _AccountInfoUpdated: Boolean): Boolean
    begin
        _AccountInfoUpdated := false;

        if GetFileFromLoggedAccount(_FileName, _FileInStream, _FileAccountId, _FileAccountConnector) then
            exit(true);

        if not ShouldAlsoTryScenarioAccount(_FileAccountId, _FileAccountConnector) then
            Error(GetLastErrorText());

        GetFileFromScenarioAccount(_FileName, _FileInStream);

        _FileAccountId := TempScenarioAccount."Account Id";
        _FileAccountConnector := TempScenarioAccount.Connector;
        _AccountInfoUpdated := true;
        exit(true);
    end;

    local procedure ShouldAlsoTryScenarioAccount(_FileAccountId: Guid; _FileAccountConnector: Enum "Ext. File Storage Connector"): Boolean
    var
        FileScenario: Codeunit "File Scenario";
    begin
        if not FileScenario.GetFileAccount(Enum::"File Scenario"::"MOB Attach Image", TempScenarioAccount) then
            exit(false);
        exit((TempScenarioAccount."Account Id" <> _FileAccountId) or (TempScenarioAccount.Connector <> _FileAccountConnector));
    end;

    [TryFunction]
    local procedure GetFileFromLoggedAccount(_FileName: Text[250]; var _FileInStream: InStream; _FileAccountId: Guid; _FileAccountConnector: Enum "Ext. File Storage Connector")
    var
        TempFileAccount: Record "File Account" temporary;
        FileAccount: Codeunit "File Account";
        ExternalFileStorage: Codeunit "External File Storage";
        FileAccountNotExistErr: Label 'An External File Account with Id %1 and Connector %2 does not exist. The Business Central record may have been deleted.', Comment = '%1 = Account Id, %2 = Connector';
        ExternalFileNotExistErr: Label 'The file %1 does not exist in the external storage %2 %3.', Comment = '%1 = File Name, %2 = Account Name, %3 = Connector';
    begin
        CheckValidConnector(_FileAccountConnector);

        FileAccount.GetAllAccounts(TempFileAccount);
        if not TempFileAccount.Get(_FileAccountId, _FileAccountConnector) then
            Error(FileAccountNotExistErr, _FileAccountId, _FileAccountConnector);

        ExternalFileStorage.Initialize(TempFileAccount);
        if not ExternalFileStorage.FileExists(_FileName) then
            Error(ExternalFileNotExistErr, _FileName, TempFileAccount.Name, _FileAccountConnector);
        ExternalFileStorage.GetFile(_FileName, _FileInStream);
    end;

    local procedure GetFileFromScenarioAccount(_FileName: Text[250]; var _FileInStream: InStream)
    var
        ExternalFileStorage: Codeunit "External File Storage";
        FileNotFoundInStorageErr: Label 'The file %1 cannot be found in external storage.', Comment = '%1 = File Name';
    begin
        ExternalFileStorage.Initialize(TempScenarioAccount);
        if not ExternalFileStorage.FileExists(_FileName) then
            Error(FileNotFoundInStorageErr, _FileName);
        ExternalFileStorage.GetFile(_FileName, _FileInStream);
    end;

    local procedure CheckValidConnector(_ExtFileStorageConnector: Enum "Ext. File Storage Connector")
    var
        ConnectorNotAvailableErr: Label 'The external file storage connector %1 is not available. The extension containing this connector may not be installed.', Comment = '%1 = Connector Name';
    begin
        if "Ext. File Storage Connector".Ordinals().Contains(_ExtFileStorageConnector.AsInteger()) then
            exit;
        Error(ConnectorNotAvailableErr, _ExtFileStorageConnector);
    end;
    /* #endif */
}
