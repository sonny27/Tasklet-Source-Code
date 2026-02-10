codeunit 81410 "MOB WMS LiveUpdate"
{
    Access = Public;

    TableNo = "MOB Document Queue";

    trigger OnRun()
    var
        TempRealtimeRegistrations: Record "MOB Realtime Reg Qty." temporary;
        TempResponseElement: Record "MOB NS Resp Element" temporary;
        XmlRequestDoc: XmlDocument;
        RegistrationTypeTracking: Text[200];
        IsHandled: Boolean;
        IsClearOrderLines: Boolean;
    begin

        MobDocQueue := Rec;
        MobDocQueue.LoadXMLRequestDoc(XmlRequestDoc);

        // Read request values into table for easy processing
        MobWmsToolbox.SaveRealtimeRegistrationData(XmlRequestDoc, MobDocQueue."Device ID", MobDocQueue."Mobile User ID", IsClearOrderLines, TempRealtimeRegistrations);

        // -- Event
        OnLiveUpdateOnCustomDocumentType(Rec."Document Type", TempRealtimeRegistrations, TempResponseElement, IsClearOrderLines, RegistrationTypeTracking, IsHandled);

        // -- Standard functions
        if not IsHandled then begin
            case Rec."Document Type" of
                'RegisterRealtimeQuantity':
                    RegisterRealtimeQuantity(TempRealtimeRegistrations, IsClearOrderLines, RegistrationTypeTracking);
                else
                    Error(MobWmsLanguage.GetMessage('NO_DOC_HANDLER'), 'MOB WMS LiveUpdate::' + Rec."Document Type");
            end;
            IsHandled := true;
        end;

        // -- Mobile response
        MobToolbox.CreateSimpleResponse(XmlResponseDoc, 'OK');

        // Update the registration type field on the mobile document queue record
        // In case of errors a fallback value is written from MOB WS Dispatcher
        MobDocQueue.SetRegistrationTypeAndTracking('', RegistrationTypeTracking);

        // Store the result in the queue
        Rec := MobDocQueue;
        MobToolbox.UpdateResult(Rec, XmlResponseDoc);
    end;

    var
        MobDocQueue: Record "MOB Document Queue";
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        MobToolbox: Codeunit "MOB Toolbox";
        XmlResponseDoc: XmlDocument;

    local procedure RegisterRealtimeQuantity(var _CurrentRegistrations: Record "MOB Realtime Reg Qty."; _IsClearOrderLines: Boolean; var _RegistrationTypeTracking: Text)
    var
        MobRealtimeRegQty: Record "MOB Realtime Reg Qty.";
    begin

        if not _CurrentRegistrations.FindFirst() then
            exit;

        // -- Clear all quantities for entire order (Request is "ClearOrderLines")
        if _IsClearOrderLines then begin
            DeleteRealtimeQuantity(_CurrentRegistrations);

            _RegistrationTypeTracking := 'ClearOrderLines' + ' ' + _CurrentRegistrations.Type + ' ' + _CurrentRegistrations."Order No.";
            // Success = exit
            exit;
        end;

        // -- Save line quantities
        // Clear previous registrations for this line, since request contains all current line registrations
        DeleteRealtimeQuantity(_CurrentRegistrations);

        // Loop and Insert as Realtime registration if quantity is present
        _CurrentRegistrations.SetFilter(Quantity, '>0');
        if _CurrentRegistrations.FindSet() then
            repeat
                // Copy temp record and insert 
                _CurrentRegistrations.CalcFields("Registration XML");
                MobRealtimeRegQty := _CurrentRegistrations;
                MobRealtimeRegQty."Registration No." := 0;  // Autoincremented when inserted
                MobRealtimeRegQty.Insert(true);
            until _CurrentRegistrations.Next() = 0;

        // Success
        _RegistrationTypeTracking := _CurrentRegistrations.Type + ' ' + _CurrentRegistrations."Order No.";
    end;

    local procedure DeleteRealtimeQuantity(_CurrentRegistrations: Record "MOB Realtime Reg Qty.")
    var
        MobRealtimeRegQty: Record "MOB Realtime Reg Qty.";
    begin
        MobRealtimeRegQty.SetRange("Device ID", MobDocQueue."Device ID");
        MobRealtimeRegQty.SetRange(Type, _CurrentRegistrations.Type);
        MobRealtimeRegQty.SetRange("Order No.", _CurrentRegistrations."Order No.");

        if _CurrentRegistrations."Line No." <> '' then // Delete only for current line, not entire order
            MobRealtimeRegQty.SetRange("Line No.", _CurrentRegistrations."Line No.");

        MobRealtimeRegQty.DeleteAll();
    end;

    //
    // ------- IntegrationEvents -------
    //

    [IntegrationEvent(false, false)]
    local procedure OnLiveUpdateOnCustomDocumentType(_DocumentType: Text; var _TempRealtimeRegistrations: Record "MOB Realtime Reg Qty."; var _ResponseElement: Record "MOB NS Resp Element"; _ClearOrderLines: Boolean; var _RegistrationTypeTracking: Text; var _IsHandled: Boolean)
    begin
    end;
}
