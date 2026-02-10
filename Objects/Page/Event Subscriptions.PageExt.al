pageextension 81280 "MOB Event Subscriptions" extends "Event Subscriptions"
{
    trigger OnOpenPage()
    var
        MOBEventSubsNotification: Notification;
    begin
        if MOBShowEventSubsNotification then begin
            MOBEventSubsNotification.Id := '5720b148-2292-4689-9a5a-173bc20454dc';
            MOBEventSubsNotification.Message := MOBEventSubsNotificationLbl;
            MOBEventSubsNotification.SetData('HasRun', 'true');
            MOBEventSubsNotification.Send();
        end;
    end;

    internal procedure MOBSetEventSubsNotification(_MOBShowEventSubsNotification: Boolean)
    begin
        MOBShowEventSubsNotification := _MOBShowEventSubsNotification;
    end;

    var
        MOBEventSubsNotificationLbl: Label 'This page shows subscribers to Mobile WMS events but does not show specific information per document.', Locked = true;
        MOBShowEventSubsNotification: Boolean;

}
