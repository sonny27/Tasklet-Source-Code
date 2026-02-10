pageextension 81283 "MOB File Accounts" extends "File Accounts"
{
    actions
    {
        modify(Delete)
        {
            trigger OnBeforeAction()
            begin
                CheckActiveMobAccounts()
            end;
        }
    }

    local procedure CheckActiveMobAccounts()
    var
        TempFileAccount: Record "File Account" temporary;
        DeleteErr: Label 'The file account %1 (%2) cannot be deleted because it is currently being used for stored images in Tasklet Mobile WMS.', Comment = '%1 = File Account Name, %2 = Connector Type';
    begin
        TempFileAccount.Copy(Rec, true);
        CurrPage.SetSelectionFilter(TempFileAccount);
        if TempFileAccount.IsEmpty() then
            exit;
        if TempFileAccount.FindSet(false) then
            repeat
                if IsActiveMobFileAccount(TempFileAccount) then
                    Error(DeleteErr, TempFileAccount.Name, TempFileAccount.Connector);
            until TempFileAccount.Next() = 0;
    end;

    local procedure IsActiveMobFileAccount(_TempFileAccount: Record "File Account" temporary): Boolean
    var
        MobWmsMediaQueue: Record "MOB WMS Media Queue";
    begin
        MobWmsMediaQueue.ReadIsolation(IsolationLevel::ReadUncommitted);
        MobWmsMediaQueue.SetRange("Ext. File Account Id", _TempFileAccount."Account Id");
        MobWmsMediaQueue.SetRange("Ext. Storage Connector", _TempFileAccount.Connector);
        exit(not MobWmsMediaQueue.IsEmpty());
    end;
}
