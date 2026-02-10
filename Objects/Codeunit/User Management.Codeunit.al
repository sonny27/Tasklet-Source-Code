codeunit 81274 "MOB User Management"
{
    Access = Public;
    TableNo = "MOB Document Queue";

    trigger OnRun()
    begin
        MobDocQueue := Rec;

        case Rec."Document Type" of

            'Login':
                Login();

            else
                Error(NoDocHandlerErr, Rec."Document Type");
        end;

        // Store the result in the queue and update the status
        MobToolbox.UpdateResult(Rec, XmlResponseDoc);

        // Event to allow running custom code on Login
        OnLogin_OnAfterLogin(Rec);
    end;

    var
        MobDocQueue: Record "MOB Document Queue";
        MobToolbox: Codeunit "MOB Toolbox";
        XmlResponseDoc: XmlDocument;
        NoDocHandlerErr: Label 'No document handler is available for %1.', Comment = '%1 contains Document Type';

    local procedure Login()
    begin
        // The Request Document looks like this:
        //  <request name="Login"
        //           created="2009-01-20T22:36:34-08:00"
        //           xmlns="http://schemas.microsoft.com/Dynamics/Mobile/2007/04>
        //    <requestData name="Login">
        //    </requestData>
        //  </request>
        //

        // The Dynamics Mobile framework handles the user validation
        // If this point is reached the supplied credentials are valid
        MobToolbox.CreateSimpleResponse(XmlResponseDoc, 'Ok');
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLogin_OnAfterLogin(var _MobDocQueue: Record "MOB Document Queue")
    begin
    end;
}

