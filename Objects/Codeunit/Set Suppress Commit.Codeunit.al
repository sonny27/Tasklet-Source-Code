codeunit 81337 "MOB Set Suppress Commit"
{
    Access = Public;
    EventSubscriberInstance = Manual;

    /* #if BC15+ */
    // The OnBeforeCode event was introduced in BC15
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse. Jnl.-Register Batch", 'OnBeforeCode', '', false, false)]
    local procedure WhseJnlRegisterBatch_OnBeforeCode_SetSuppressCommit(var SuppressCommit: Boolean)
    begin
        SuppressCommit := true;
    end;
    /* #endif */
}
