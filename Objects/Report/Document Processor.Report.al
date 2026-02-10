report 81271 "MOB Document Processor"
{


    Caption = 'Mobile Document Processor';
    ProcessingOnly = true;

    dataset
    {
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    var
        MobSessionData: Codeunit "MOB SessionData";
        MobDocMgt: Codeunit "MOB Document Management";
        MobFeatureTelemetryWrapper: Codeunit "MOB Feature Telemetry Wrapper";
        MobToolbox: Codeunit "MOB Toolbox";
        ErrorOrigintedFromErr: Label '(%1 by %2)', Comment = '%1 is Ext Name. %2 is Ext Publisher.', Locked = true;

    internal procedure ProcessDocumentWebService(var _MobDocQueue: Record "MOB Document Queue") _ErrorText: Text
    var
        MobDocType: Record "MOB Document Type";
        Completed: Boolean;
    begin
        GlobalLanguage(GetUserLanguageId(_MobDocQueue)); // Sets global language to the MOB users language

        Clear(Completed);
        ClearLastError();

        AddDocumentTypeIfNotExists(_MobDocQueue."Document Type");   // Event subscriber may or may not add a missing Document Type
        Commit();

        if TryValidateUserAndDocumentType(_MobDocQueue) then begin
            MobDocType.Get(_MobDocQueue."Document Type");
            Completed := Codeunit.Run(MobDocType."Processing Codeunit", _MobDocQueue);
        end;

        if Completed then
            exit('')
        else
            _ErrorText := GetLastErrorText();
    end;

    internal procedure ProcessDocumentQueue(var _MobDocQueue: Record "MOB Document Queue")
    var
        MobDocType: Record "MOB Document Type";
        XmlErrorDoc: XmlDocument;
        Completed: Boolean;
        LastErrorCallStack: Text;
        ErrorText: Text;
    begin
        GlobalLanguage(GetUserLanguageId(_MobDocQueue)); // Sets global language to the MOB users language

        _MobDocQueue.Status := _MobDocQueue.Status::Processing;
        _MobDocQueue.Modify();
        Commit();

        Clear(Completed);
        ClearLastError();

        AddDocumentTypeIfNotExists(_MobDocQueue."Document Type");   // Event subscriber may or may not add a missing Document Type
        Commit();

        if TryValidateUserAndDocumentType(_MobDocQueue) then begin
            MobDocType.Get(_MobDocQueue."Document Type");
            Completed := Codeunit.Run(MobDocType."Processing Codeunit", _MobDocQueue);
        end;

        if Completed then
            // Save Telemetry
            MobFeatureTelemetryWrapper.LogUsage(_MobDocQueue)
        else begin
            ErrorText := AddErrorOrigin(GetLastErrorText());

            MobDocMgt.CreateXMLResponseDocError(XmlErrorDoc, _MobDocQueue."Message ID", CopyStr(ErrorText, 1, 1024));
            _MobDocQueue.SaveXMLResponseDoc(XmlErrorDoc);
            _MobDocQueue.Status := _MobDocQueue.Status::Error;
            _MobDocQueue.Modify();

            // Save Telemetry
            MobFeatureTelemetryWrapper.LogError(_MobDocQueue, CopyStr(ErrorText, 1, 1024));

            // Stop Performance Profiler
            /* #if BC20+ */
            PerfProfilerStop();
            /* #endif */

            Commit();
            if GuiAllowed() then begin
                LastErrorCallStack := MobSessionData.GetPreservedLastErrorCallStack();
                MobSessionData.Initialize(); // Clear the session data to avoid leaving data behind (could be sensitive data or logged in telemetry for other processes)
                Error(CopyStr(ErrorText + MobToolbox.CRLFSeparator() + MobToolbox.CRLFSeparator() + LastErrorCallStack, 1, 1024));
            end
        end;
    end;

    internal procedure AddDocumentTypeIfNotExists(_MobDocumentType: Text[50])
    var
        MobDocType: Record "MOB Document Type";
        MobWmsSetupDocTypes: Codeunit "MOB WMS Setup Doc. Types";
    begin
        if (_MobDocumentType = '') or MobDocType.Get(_MobDocumentType) then
            exit;

        // Eventsubscriber may or may not add the missing Document Type
        // Note: Events do not handle a specific Document Type but will (re)execute all existing subscribers for all custom document types
        MobWmsSetupDocTypes.OnAfterCreateDefaultDocumentTypes();
    end;

    /// <summary>
    /// Compose the error text for displaying to user
    /// </summary>
    /// <param name="_LastErrorText">Current errortext i.e. "GetLastErrorText"</param>
    internal procedure AddErrorOrigin(_LastErrorText: Text) DisplayErrorText: Text
    var
        ExtPublisher: Text;
        ExtName: Text;
    begin
        if _LastErrorText.ToUpper().StartsWith('FORCEWARNING:') then
            exit(_LastErrorText); // Ignore Forcewarning dialogs. Fallback to lasterror

        if not ErrorOriginatesFromThirdParty(ExtPublisher, ExtName) then
            exit(_LastErrorText); // Fallback to lasterror

        // The callstack originates from Third-party
        DisplayErrorText := _LastErrorText + MobToolbox.CRLFSeparator() + MobToolbox.CRLFSeparator() + StrSubstNo(ErrorOrigintedFromErr, ExtName, ExtPublisher);
    end;

    /// <summary>
    /// Is error caused by third-party extension
    /// </summary>
    local procedure ErrorOriginatesFromThirdParty(var _ExtPublisher: Text; var _ExtName: Text): Boolean
    var
        MobInstall: Codeunit "MOB Install";
    begin
        if TryGetCallStackOrigin(_ExtPublisher, _ExtName) then
            // Publisher is different from "Tasklet Factory" and "Micrsoft"
            exit(not (_ExtPublisher.Contains(MobInstall.GetCurrentPublisher()) or _ExtPublisher.Contains('Microsoft')));
    end;

    /// <summary>
    /// Get origin of the the ErrorCallstack. Return extension Name and Publisher
    /// </summary>
    [TryFunction]
    local procedure TryGetCallStackOrigin(var _ExtPublisher: Text; var _ExtName: Text)
    var
        TempText: Text;
        TempList: List of [Text];
    begin
        if MobSessionData.GetPreservedLastErrorCallStack() = '' then
            exit;
        TempText := CopyStr(MobSessionData.GetPreservedLastErrorCallStack(), 1, StrPos(MobSessionData.GetPreservedLastErrorCallStack(), '\') - 1); // Get first call in callstack: "MyObject"(CodeUnit 50100).FunctionX line 2 - Contoso Extension by Publisher
        TempText := CopyStr(TempText, TempText.LastIndexOf(' line ') + 6);
        TempText := CopyStr(TempText, TempText.IndexOf(' - ') + 3);
        TempList := TempText.Split(' by ');

        _ExtName := TempList.Get(1);
        _ExtPublisher := TempList.Get(2);
    end;

    [TryFunction]
    local procedure TryValidateUserAndDocumentType(var _MobDocQueue: Record "MOB Document Queue")
    begin
        // ***********************************************************************************************************
        // ***** IMPORTANT: NO DATABASE WRITE TRANSACTIONS IN THIS PROCEDURE (WOULD NOT BE ROLLED BACK ON ERROR) *****
        // ***********************************************************************************************************

        ValidateUserAndDocumentType(_MobDocQueue);
    end;

    internal procedure ValidateUserAndDocumentType(var _MobDocQueue: Record "MOB Document Queue")
    var
        MobDocType: Record "MOB Document Type";
    begin
        // ***********************************************************************************************************
        // ***** IMPORTANT: NO DATABASE WRITE TRANSACTIONS IN THIS PROCEDURE (WOULD NOT BE ROLLED BACK ON ERROR) *****
        // ***********************************************************************************************************

        // Validate that the user is a mobile user
        MobDocMgt.ValidateUser(_MobDocQueue."Mobile User ID");

        // Make sure that the document type is known
        MobDocMgt.ValidateDocumentType(_MobDocQueue."Document Type");
        MobDocType.Get(_MobDocQueue."Document Type");
    end;

    /// <summary>
    /// Returns the Windows Language ID for the user in the MOB Document Queue.
    /// If the MOB User is not found, it will return the GlobalLanguage ID.
    /// If the Language Code on the user is unspecified or the Language record is not found, it will return the GlobalLanguage ID.
    /// If the Windows Language ID is not specified in the Language record, it will throw an error.
    /// </summary>
    local procedure GetUserLanguageId(var _MobDocQueue: Record "MOB Document Queue"): Integer
    var
        MobUser: Record "MOB User";
    begin
        MobUser.SetFilter("User ID", '@' + _MobDocQueue."Mobile User ID");
        if MobUser.FindFirst() then
            exit(MobToolbox.GetLanguageId(MobUser."Language Code", true)); // true = Throw error if language ID is not set

        exit(GlobalLanguage()); // Fallback to global language if user not found
    end;

    /* #if BC20+ */
    local procedure PerfProfilerStop()
    var
        MobPerfProfiler: Codeunit "MOB Perf. Profiler";
    begin
        if MobPerfProfiler.IsRecordingInProgress() then
            MobPerfProfiler.Stop();
    end;
    /* #endif */

}

