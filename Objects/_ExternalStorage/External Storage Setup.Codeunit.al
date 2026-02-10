codeunit 81357 "MOB External Storage Setup"
{
    Access = Internal;

    /* #if BC26+ */
    Permissions =
        tabledata "MOB Setup" = rm;

    var
        FileAccount: Codeunit "File Account";
        FileScenario: Codeunit "File Scenario";

    internal procedure IsAttachImagesScenarioAssigned(): Boolean
    var
        TempFileAccount: Record "File Account" temporary;
    begin
        exit(FileScenario.GetFileAccount(Enum::"File Scenario"::"MOB Attach Image", TempFileAccount));
    end;

    internal procedure GetAttachImagesScenarioAccountName(): Text[250]
    var
        TempFileAccount: Record "File Account" temporary;
    begin
        if FileScenario.GetFileAccount(Enum::"File Scenario"::"MOB Attach Image", TempFileAccount) then
            exit(TempFileAccount.Name);
        exit('');
    end;

    internal procedure LookupAndValidateFileAccount() FileAccountName: Text[250]
    var
        TempOldAccount: Record "File Account" temporary;
        TempNewAccount: Record "File Account" temporary;
        FileAccountsPage: Page "File Accounts";
    begin
        if not FileAccount.IsAnyAccountRegistered() then
            ShowNoAccountsExistsErrorDialog();

        if FileScenario.GetFileAccount(Enum::"File Scenario"::"MOB Attach Image", TempOldAccount) then
            FileAccountsPage.SetAccount(TempOldAccount);
        FileAccountName := TempOldAccount.Name; // In case user cancels the lookup, we keep the old name (Blank if no account was assigned)

        FileAccountsPage.EnableLookupMode();
        if FileAccountsPage.RunModal() <> Action::LookupOK then
            exit;
        FileAccountsPage.GetRecord(TempNewAccount);

        if (TempOldAccount."Account Id" = TempNewAccount."Account Id") and (TempOldAccount.Connector = TempNewAccount.Connector) then
            exit; // No change

        FileScenario.SetFileAccount(Enum::"File Scenario"::"MOB Attach Image", TempNewAccount);
        FileAccountName := TempNewAccount.Name;
    end;

    internal procedure ValidateAttachImagesFileAccountName(_FileAccountName: Text[250])
    var
        TempFileAccount: Record "File Account" temporary;
        FileAccountErr: Label 'A %1 with the name "%2" does not exist. Please specify a valid %1.', Comment = '%1 = File Account, %2 = File Account Name';
    begin
        if _FileAccountName = '' then
            FileScenario.UnassignScenario(Enum::"File Scenario"::"MOB Attach Image")
        else begin
            FileAccount.GetAllAccounts(TempFileAccount);
            TempFileAccount.SetRange(Name, _FileAccountName);
            if not TempFileAccount.FindFirst() then
                Error(FileAccountErr, TempFileAccount.TableCaption(), _FileAccountName);
            FileScenario.SetFileAccount(Enum::"File Scenario"::"MOB Attach Image", TempFileAccount);
        end;
        DisableExternalStorageIfScenarioNotAssigned();
    end;

    internal procedure ValidateUseExternalStorageForAttachImages(Enabled: Boolean)
    var
        ConfirmMgt: Codeunit "Confirm Management";
        ExternalFileAccountNotSpecifiedErr: Label 'Please specify an external file account before enabling external storage.';
        DefaultAccountConfirmQst: Label 'You are about to enable external storage using the default file account. It is recommended to create and use a dedicated file account for storing images from Mobile WMS.\\Do you want to proceed with the default account?';
    begin
        if not Enabled then
            exit;
        if not IsAttachImagesScenarioAssigned() then
            Error(ExternalFileAccountNotSpecifiedErr);
        if IsAttachImagesScenarioAccountAlsoDefault() then
            if not ConfirmMgt.GetResponse(DefaultAccountConfirmQst, false) then
                Error('');
    end;

    local procedure IsAttachImagesScenarioAccountAlsoDefault(): Boolean
    var
        TempDefaultAccount: Record "File Account" temporary;
        TempScenarioAccount: Record "File Account" temporary;
    begin
        if not FileScenario.GetFileAccount(Enum::"File Scenario"::"MOB Attach Image", TempScenarioAccount) then
            exit(false);
        if not FileScenario.GetDefaultFileAccount(TempDefaultAccount) then
            exit(false);
        exit((TempScenarioAccount."Account Id" = TempDefaultAccount."Account Id") and (TempScenarioAccount.Connector = TempDefaultAccount.Connector));
    end;

    local procedure ShowNoAccountsExistsErrorDialog()
    var
        NoAccountsError: ErrorInfo;
        TitleLbl: Label 'No file accounts exists.';
        MessageLbl: Label 'You must create a file account to be able to use external storage.';
        ActionLbl: Label 'Go to File Accounts list';
    begin
        NoAccountsError.Title := TitleLbl;
        NoAccountsError.Message := MessageLbl;

        NoAccountsError.PageNo := Page::"File Accounts";
        NoAccountsError.AddNavigationAction(ActionLbl);

        Error(NoAccountsError);
    end;

    local procedure DisableExternalStorageIfScenarioNotAssigned()
    var
        MobSetup: Record "MOB Setup";
    begin
        if IsAttachImagesScenarioAssigned() then
            exit;
        MobSetup.Get();
        MobSetup."Use External Storage_AttaImage" := false;
        MobSetup.Modify(true);
    end;
    /* #endif */
}
