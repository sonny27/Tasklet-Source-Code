codeunit 81378 "MOB WMS Order Locking"
{
    Access = Public;
    // <summary>
    // Handle document locking at mobile device to prevent other mobile wms users to access same documents during scanning.
    // Do not confuse with table locking during processing/posting, which is handled in the documenthandler codeunits
    // 
    // Read and convert <BackendID/> element into
    // - Order no.
    // - Prefix is Source document type, SO, PO, TR (If present)
    // </summary>
    // <remarks>
    // The Request Document looks like this:
    //   <request name="LockOrder" xmlns="http://schemas.microsoft.com/Dynamics/Mobile/2007/04/Documents/Request" created="2020-10-06T08:43:03+02:00">
    //     <requestData name="LockOrder">
    //       <BackendID>PI000005</BackendID>
    //       <Type>Pick</Type>
    //             or
    //       <BackendID>I-DEFAULT</BackendID>
    //       <Type>Count</Type>
    //     </requestData>
    //   </request>
    // </remarks>
    TableNo = "MOB Document Queue";

    trigger OnRun()
    begin
        case Rec."Document Type" of

            'LockOrder':
                LockOrder(Rec);

            'UnlockOrder':
                UnlockOrder(Rec);

            else
                Error(MobWmsLanguage.GetMessage('NO_DOC_HANDLER'), Rec."Document Type");
        end;

        // Store the result in the queue and update the status
        MobToolbox.UpdateResult(Rec, XmlResponseDoc);
    end;

    var
        MobWmsLanguage: Codeunit "MOB WMS Language";
        MobToolbox: Codeunit "MOB Toolbox";
        XmlResponseDoc: XmlDocument;

    /// <summary>
    /// Determine if an order is locked by a user
    /// </summary>
    [InherentPermissions(PermissionObjectType::TableData, Database::"MOB Order Locking", 'R', InherentPermissionsScope::Both)]
    internal procedure GetLockStatusCode(_BackendID: Code[250]): Code[1]
    var
        MobOrderLocking: Record "MOB Order Locking";
    begin
        if MobOrderLocking.Get(_BackendID) then
            exit('2')   // Locked
        else
            exit('1');  // Not locked
    end;

    /// <summary>
    /// Place a lock on an order so other mobile users can NOT access it
    /// </summary>
    [InherentPermissions(PermissionObjectType::TableData, Database::"MOB Order Locking", 'RI', InherentPermissionsScope::Both)]
    local procedure LockOrder(_MobDocQueue: Record "MOB Document Queue")
    var
        MobUser: Record "MOB User";
        MobOrderLocking: Record "MOB Order Locking";
        TempRequestValues: Record "MOB NS Request Element" temporary;
        BackendID: Code[250];
        IsHandled: Boolean;
    begin
        _MobDocQueue.LoadAdhocRequestValues(TempRequestValues);

        // Integration event
        IsHandled := false;
        OnLockOrder_OnBeforeLockOrder(_MobDocQueue, TempRequestValues, IsHandled);

        if IsHandled then begin
            MobToolbox.CreateSimpleResponse(XmlResponseDoc, 'Order Locking handled by Event Subscriber');
            exit;
        end;

        // Get BackendID
        BackendID := TempRequestValues.GetValue('BackendID');

        // If locked, respond with error and the locking User
        MobOrderLocking.LockTable();
        if MobOrderLocking.Get(BackendID) then
            Error(MobWmsLanguage.GetMessage('ORDER_LOCKED_BY'), MobOrderLocking.Name);

        // Get user info
        MobUser.SetFilter("User ID", '@' + _MobDocQueue."Mobile User ID");
        MobUser.SetAutoCalcFields("User Name");
        MobUser.FindFirst();

        // Lock the order
        if MobUser."User Name" <> '' then
            MobOrderLocking.InsertLock(BackendID, MobUser."User ID", MobUser."User Name")
        else
            MobOrderLocking.InsertLock(BackendID, MobUser."User ID", MobUser."User ID");

        // Success
        MobToolbox.CreateSimpleResponse(XmlResponseDoc, MobWmsLanguage.GetMessage('LOCK_SUCCESS'));
    end;


    /// <summary>
    /// Release a lock on an order so other mobile users can access it.
    /// </summary>
    [InherentPermissions(PermissionObjectType::TableData, Database::"MOB Order Locking", 'RD', InherentPermissionsScope::Both)]
    local procedure UnlockOrder(_MobDocQueue: Record "MOB Document Queue")
    var
        MobOrderLocking: Record "MOB Order Locking";
        TempRequestValues: Record "MOB NS Request Element" temporary;
        BackendID: Code[250];
        IsHandled: Boolean;
    begin
        _MobDocQueue.LoadAdhocRequestValues(TempRequestValues);

        // Integration event
        IsHandled := false;
        OnUnlockOrder_OnBeforeUnlockOrder(_MobDocQueue, TempRequestValues, IsHandled);

        if IsHandled then begin
            MobToolbox.CreateSimpleResponse(XmlResponseDoc, 'Order Locking handled by Event Subscriber');
            exit;
        end;

        // Get BackendID
        BackendID := TempRequestValues.GetValue('BackendID');

        // Unlock by deletion
        MobOrderLocking.DeleteLock(BackendID);

        // Success
        MobToolbox.CreateSimpleResponse(XmlResponseDoc, MobWmsLanguage.GetMessage('UNLOCK_SUCCESS'));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLockOrder_OnBeforeLockOrder(_MobDocumentQueue: Record "MOB Document Queue"; var _RequestValues: Record "MOB NS Request Element"; var _IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUnlockOrder_OnBeforeUnlockOrder(_MobDocumentQueue: Record "MOB Document Queue"; var _RequestValues: Record "MOB NS Request Element"; var _IsHandled: Boolean)
    begin
    end;
}
