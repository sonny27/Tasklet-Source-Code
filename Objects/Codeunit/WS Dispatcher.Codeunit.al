codeunit 81280 "MOB WS Dispatcher"
{
    Access = Public;

    var
        MobTelemetryMgt: Codeunit "MOB Telemetry Management";
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
        IsRequiredErr: Label '%1 is required.', Comment = '%1 contains Field Caption', Locked = true;
        ExceedsMaxLengthErr: Label '%1 exceeds the maximum length.', Comment = '%1 contains Field Caption', Locked = true;

    trigger OnRun()
    begin
    end;

    /// <remarks>
    /// Do NOT rename parameters or change case -- parameter names must exactly match names from webservice
    /// </remarks>
    procedure ProcessRequest(mobileUserID: Text[1024]; deviceID: Text[1024]; messageID: Text[1024]; messageIn: BigText; var messageOut: Text)
    var
        MobDocQueue: Record "MOB Document Queue";
        MobDocProcessor: Report "MOB Document Processor";
        MobSessionData: Codeunit "MOB SessionData";
        MobDocMgt: Codeunit "MOB Document Management";
        MobToolbox: Codeunit "MOB Toolbox";
        MobFeatureTelemetryWrapper: Codeunit "MOB Feature Telemetry Wrapper";
        XmlRequestDoc: XmlDocument;
        XmlResponseDoc: XmlDocument;
        XmlErrorDoc: XmlDocument;
        ErrorText: Text;
    begin

        // Load the MessageIn into the XML variable
        XmlDocument.ReadFrom(Format(messageIn), XmlRequestDoc);

        ValidateRequest(XmlRequestDoc, deviceID, messageID);

        MobDocQueue.Init();
        MobDocQueue."Message ID" := messageID;
        MobDocQueue."Device ID" := deviceID;
        MobDocQueue."Mobile User ID" := UserId();

        // Save the XML request in the document queue 
        MobDocQueue.SaveXMLRequestDoc(XmlRequestDoc);

        // Determine the document type
        MobDocQueue."Document Type" := MobDocMgt.GetDocumentType(XmlRequestDoc);

        // Ensure telemetry is initialized per request
        MobTelemetryMgt.Initialize();

        // Make MessageId, MobileUserID, DeviceID, StartDateTime and DocumentType available from everywhere via SingleInstance codeunit (including from all standard events)
        MobSessionData.Initialize(); // Ensure unassigned values are cleared in single instance codeunit
        MobSessionData.SetPostingMessageId(MobDocQueue.MessageIDAsGuid());
        MobSessionData.SetDocumentType(MobDocQueue."Document Type");
        MobSessionData.SetMobileUserID(MobDocQueue."Mobile User ID");
        MobSessionData.SetDeviceID(MobDocQueue."Device ID");
        MobSessionData.SetProcessingStartDateTime(CurrentDateTime());

        // Start Performance Profiler
        /* #if BC20+ */
        PerfProfilerStart(MobDocQueue);
        /* #endif */

        // Extract Date and Time from Request
        MobDocMgt.SetRequestDateAndTime(XmlRequestDoc, MobDocQueue);

        // Set Workdate
        WorkDate(MobDocQueue.GetCalculatedWorkDate());

        // Determine if this request has been received before
        // If it has the previous result is returned
        if not MobDocMgt.ReceivedBefore(MobDocQueue, XmlResponseDoc) then begin

            MobWmsToolbox.DeleteRegistrationData(MobDocQueue.MessageIDAsGuid());

            MobDocQueue.Status := MobDocQueue.Status::Processing;
            MobDocQueue.Insert();

            Commit();

            ErrorText := MobDocMgt.ProcessDocumentWebService(MobDocQueue);
            if ErrorText = '' then begin
                // Success
                MobDocQueue.LoadXMLResponseDoc(XmlResponseDoc);
                MobDocQueue.ReduceImageData();
            end else begin
                // Error
                ErrorText := MobDocProcessor.AddErrorOrigin(ErrorText);

                // Use error as Response (reduce to 1024 characters to avoid overwhelming end user, full error message can be seen if document can be reprocessed from document queue)
                if not GuiAllowed() then
                    MobDocMgt.CreateXMLResponseDocError(XmlErrorDoc, messageID, CopyStr(ErrorText, 1, 1024))
                else
                    MobDocMgt.CreateXMLResponseDocError(XmlErrorDoc, messageID, ErrorText);
                MobDocQueue.SaveXMLResponseDoc(XmlErrorDoc);
                MobDocQueue.LoadXMLResponseDoc(XmlResponseDoc);
                MobDocQueue.Status := MobDocQueue.Status::Error;
            end;

            if MobDocQueue."Registration Type" = '' then
                MobDocQueue.SetRegistrationTypeAndTracking(MobSessionData.GetRegistrationType(), MobSessionData.GetRegistrationTypeTracking());

            MobDocQueue.Modify();
            Commit();
        end;

        // Save the response in the message out variable
        MobToolbox.PostProcessRequest(XmlResponseDoc, messageOut);

        // Save Telemetry
        if ErrorText = '' then
            MobFeatureTelemetryWrapper.LogUsage(MobDocQueue)
        else
            MobFeatureTelemetryWrapper.LogError(MobDocQueue, ErrorText);

        // Errors displayed at mobile device will show as "internal server error" when thrown from the dispatcher.
        // This is what we want for messages created due to errors in user or document setup, even when GuiAllowed() is false.
        // Also, if errors outside an "ok := Codeunit.Run" is suppressed in this procedure the mobile app may display blank message despite the ReponseXml actually having status="Error" and with the correct error message.
        // This is only an issue when processing directly from webservice (WS Dispatcher), never when retrying from document queue.
        // For both reasons we re-validate if error was due to user/document setup, then always throws error here if this was the case.
        if ErrorText <> '' then
            MobDocProcessor.ValidateUserAndDocumentType(MobDocQueue);

        // Stop Performance Profiler
        /* #if BC20+ */
        PerfProfilerStop();
        /* #endif */
    end;

    local procedure ValidateRequest(var _XmlRequestDoc: XmlDocument; _DeviceID: Text[1024]; _MessageID: Text[1024])
    var
        MobDocQueue: Record "MOB Document Queue";
        MobXmlMgt: Codeunit "MOB XML Management";
    begin
        case true of
            _DeviceID = '':
                Error(IsRequiredErr, MobDocQueue.FieldCaption("Device ID"));

            StrLen(_DeviceID) > MaxStrLen(MobDocQueue."Device ID"):
                Error(ExceedsMaxLengthErr, MobDocQueue.FieldCaption("Device ID"));

            _MessageID = '':
                Error(IsRequiredErr, MobDocQueue.FieldCaption("Message ID"));

            StrLen(_MessageID) > MaxStrLen(MobDocQueue."Message ID"):
                Error(ExceedsMaxLengthErr, MobDocQueue.FieldCaption("Message ID"));

            MobXmlMgt.DocIsNull(_XmlRequestDoc):
                Error(IsRequiredErr, MobDocQueue.FieldCaption("Request XML"));
        end;
    end;

    /* #if BC20+ */
    local procedure PerfProfilerStart(_MobDocQueue: Record "MOB Document Queue")
    var
        MobPerfProfiler: Codeunit "MOB Perf. Profiler";
    begin
        if MobPerfProfiler.IsActivatedForUserOrDocumentType(_MobDocQueue) then
            MobPerfProfiler.Start();
    end;

    local procedure PerfProfilerStop()
    var
        MobPerfProfiler: Codeunit "MOB Perf. Profiler";
    begin
        if MobPerfProfiler.IsRecordingInProgress() then
            MobPerfProfiler.Stop();
    end;
    /* #endif */
}
