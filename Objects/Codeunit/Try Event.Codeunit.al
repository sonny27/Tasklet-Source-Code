codeunit 81430 "MOB Try Event"
{
    Access = Public;
    /// <summary>
    /// Used on as codeunit.Run 
    /// Shields calling code from errors and rollbacks 
    /// </summary>

    var
        TempOrderValues: Record "MOB Common Element" temporary;
        TempRequestValues: Record "MOB NS Request Element" temporary;
        MobToolbox: Codeunit "MOB Toolbox";
        MobLanguage: Codeunit "MOB WMS Language";
        SourceRecRef: RecordRef;
        ResultMessage: Text;
        EventName: Text;
        UnknownEventErr: Label 'Unknown event %1 in "MOB Try Event".OnRun()', Locked = true;

    //
    // -------------------------------- OnRun --------------------------------
    //
    trigger OnRun()
    var
        SourceWhseActLine: Record "Warehouse Activity Line";
        SourceWhseShipLine: Record "Warehouse Shipment Line";
        MobWmsPick: Codeunit "MOB WMS Pick";
        MobWmsReceive: Codeunit "MOB WMS Receive";
        MobWmsMove: Codeunit "MOB WMS Move";
        MobWmsPutAway: Codeunit "MOB WMS Put Away";
        MobWmsShip: Codeunit "MOB WMS Ship";
        MobWmsCount: Codeunit "MOB WMS Count";
        MobAdhoc: Codeunit "MOB WMS Adhoc Registr.";
    begin
        // Use Record for the events that needs this
        case SourceRecRef.Number() of
            Database::"Warehouse Activity Line":
                SourceRecRef.SetTable(SourceWhseActLine);
            Database::"Warehouse Shipment Line":
                SourceRecRef.SetTable(SourceWhseShipLine);
        end;

        case EventName of
            'OnPostReceiveOrder_OnAfterPostAnyOrder':
                MobWmsReceive.OnPostReceiveOrder_OnAfterPostAnyOrder(TempOrderValues, SourceRecRef, ResultMessage);
            'OnPostPickOrder_OnAfterPostAnyOrder':
                MobWmsPick.OnPostPickOrder_OnAfterPostAnyOrder(TempOrderValues, SourceRecRef, ResultMessage);
            'OnPostMoveOrder_OnAfterPostWarehouseActivity':
                MobWmsMove.OnPostMoveOrder_OnAfterPostWarehouseActivity(TempOrderValues, SourceWhseActLine, ResultMessage);
            'OnPostPutAwayOrder_OnAfterPostWarehouseActivity':
                MobWmsPutAway.OnPostPutAwayOrder_OnAfterPostWarehouseActivity(TempOrderValues, SourceWhseActLine, ResultMessage);
            'OnPostShipOrder_OnAfterPostWarehouseShipment':
                MobWmsShip.OnPostShipOrder_OnAfterPostWarehouseShipment(TempOrderValues, SourceWhseShipLine, ResultMessage);
            'OnPostCountOrder_OnAfterPostAnyOrder':
                MobWmsCount.OnPostCountOrder_OnAfterPostAnyOrder(TempOrderValues, SourceRecRef, ResultMessage);
            'OnPostAdhocRegistration_OnAfterPostToteShipping':
                MobAdhoc.OnPostAdhocRegistration_OnAfterPostToteShipping(SourceWhseShipLine, TempRequestValues, ResultMessage);
            else
                Error(UnknownEventErr, EventName);
        end;

    end;
    //
    // -------------------------------- Set/Get --------------------------------
    //
    internal procedure SetSourceRecRef(_SourceRecVariant: Variant)
    begin
        MobToolbox.Variant2RecRef(_SourceRecVariant, SourceRecRef);
    end;

    internal procedure SetEventName(_EventName: Text)
    begin
        EventName := _EventName;
    end;

    internal procedure SetResultMessage(_ResultMessage: Text)
    begin
        ResultMessage := _ResultMessage;
    end;

    internal procedure SetOrderValues(var _OrderValues: Record "MOB Common Element")
    begin
        TempOrderValues.InitFromCommonElement(_OrderValues);
    end;

    internal procedure SetRequestValues(var _RequestValues: Record "MOB NS Request Element")
    begin
        TempRequestValues.InitFromRequestValues(_RequestValues);
    end;

    internal procedure GetResultMessage(var _ResultMessage: Text)
    begin
        _ResultMessage := ResultMessage;
    end;

    //
    // -------------------------------- Recursive Run --------------------------------
    //

    procedure RunEventOnPlannedPosting(_EventName: Text; _SourceRecVariant: Variant; var _OrderValues: Record "MOB Common Element"; var _ResultMessage: Text)
    var
        MobTryEvent: Codeunit "MOB Try Event";
        MobSessionData: Codeunit "MOB SessionData";
    begin
        MobTryEvent.SetEventName(_EventName);                     // Event to run
        MobTryEvent.SetSourceRecRef(_SourceRecVariant);           // Reference of the posted record
        MobTryEvent.SetResultMessage(_ResultMessage);             // Message to mobile user after posting
        MobTryEvent.SetOrderValues(_OrderValues);                 // Original incoming 'PostOrder'-request and ordervalues

        if MobTryEvent.Run() then
            // Success
            MobTryEvent.GetResultMessage(_ResultMessage)
        else begin
            // Failed - Return error details to mobile, but does not throw error
            _ResultMessage += ' ' + StrSubstNo(MobLanguage.GetMessage('ONPOSTEVENT_FAILED'), GetLastErrorText(), _EventName);

            if not MobSessionData.IsLastErrorCallStackPreserved() then
                MobSessionData.SetPreservedLastErrorCallStack();
        end;
    end;

    procedure RunEventOnUnplannedPosting(_EventName: Text; _SourceRecVariant: Variant; var _RequestValues: Record "MOB NS Request Element"; var _ResultMessage: Text)
    var
        MobTryEvent: Codeunit "MOB Try Event";
        MobSessionData: Codeunit "MOB SessionData";
    begin
        MobTryEvent.SetEventName(_EventName);                     // Event to run
        MobTryEvent.SetSourceRecRef(_SourceRecVariant);           // Reference of the posted record
        MobTryEvent.SetResultMessage(_ResultMessage);             // Message to mobile user after posting
        MobTryEvent.SetRequestValues(_RequestValues);             // Original incoming 'PostAdhocRegistration'-request and values

        if MobTryEvent.Run() then
            // Success
            MobTryEvent.GetResultMessage(_ResultMessage)
        else begin
            // Failed - Return error details to mobile, but does not throw error
            _ResultMessage += ' ' + StrSubstNo(MobLanguage.GetMessage('ONPOSTEVENT_FAILED'), GetLastErrorText(), _EventName);

            if not MobSessionData.IsLastErrorCallStackPreserved() then
                MobSessionData.SetPreservedLastErrorCallStack();
        end;
    end;
}
