codeunit 81301 "MOB Telemetry Management"
{
    Access = Public;
    SingleInstance = true;

    var
        MobFeatureTelemetryWrapper: Codeunit "MOB Feature Telemetry Wrapper";
        MobSessionData: Codeunit "MOB SessionData";
        MobTelemetryEventId: Enum "MOB Telemetry Event ID";
        FeatureTelemetryLoggedUsed: List of [Enum "MOB Telemetry Event ID"]; // Warning: Used across functions because it is a Single Instance Codeunit        
        NotAvailableTxt: Label 'N/A', Locked = true;

    internal procedure Initialize()
    begin
        /* #if BC20+ */
#pragma warning disable LC0032 // MobSessionData is a SingleInstance codeunit but is cleared elsewhere
        ClearAll(); // The only way to clear all variables in a single instance codeunit
#pragma warning restore LC0032
        /* #endif */
    end;

    /* #if BC20+ */
    [EventSubscriber(ObjectType::Table, Database::"MOB Setup", 'OnAfterModifyEvent', '', true, true)]
    local procedure MobSetup_OnAfterModifyEvent(var Rec: Record "MOB Setup"; var xRec: Record "MOB Setup"; RunTrigger: Boolean)
    var
        RecRef: RecordRef;
        xRecRef: RecordRef;
        FldRef: FieldRef;
        xFldRef: FieldRef;
        FieldIndex: Integer;
        CustomDimensions: Dictionary of [Text, Text];
    begin
        if Rec.IsTemporary() then
            exit;

        // Add custom dimensions
        AddGenericCustomDimensions(CustomDimensions);

        // Loop fields and add current value of all fields xRec values of changed fields
        RecRef.GetTable(Rec);
        xRecRef.GetTable(xRec);
        for FieldIndex := 1 to RecRef.FieldCount() do begin
            FldRef := RecRef.FieldIndex(FieldIndex);
            if (FldRef.Class() = FldRef.Class::Normal) and
               (not (FldRef.Type() in [FldRef.Type::Blob, FldRef.Type::Media, FldRef.Type::MediaSet, FldRef.Type::Guid])) // Guids excepted to avoid storing App Registration IDs
            then begin
                CustomDimensions.Add('Mob.' + RecRef.Name() + '.' + FldRef.Name(), Format(FldRef.Value(), 0, 9));

                xFldRef := xRecRef.FieldIndex(FieldIndex);
                if FldRef.Value() <> xFldRef.Value() then
                    CustomDimensions.Add('Mob.' + RecRef.Name() + '.' + xFldRef.Name() + '.xRec', Format(xFldRef.Value(), 0, 9));
            end;
        end;

        MobFeatureTelemetryWrapper.LogUsage(MobTelemetryEventId::"MOB Setup table (MOB2010)", 'OnAfterModifyEvent', CustomDimensions);
    end;
    /* #endif */

    internal procedure LogErrorHttpHelperTrySend(var _RestParameter: Record "MOB Print REST Parameter")
    /* #if BC20+ */
    var
        CustomDimensions: Dictionary of [Text, Text];
    begin
        // Add generic dimensions
        AddGenericCustomDimensions(CustomDimensions);

        // Add specific dimensions for MOB2100
        CustomDimensions.Add('MobResultHttpStatusCode', Format(_RestParameter."Result HttpStatusCode", 0, 9));
        CustomDimensions.Add('MobResultReasonPhrase', _RestParameter."Result ReasonPhrase");
        CustomDimensions.Add('MobResultIsBlockedByEnvironment', Format(_RestParameter."Result IsBlockedByEnvironment", 0, 9)); // If the HTTP response is the result of the environment blocking an outgoing HTTP request

        MobFeatureTelemetryWrapper.LogError(MobTelemetryEventId::"MOB HTTP Helper TrySend() Failed (MOB2100)", _RestParameter.URL, _RestParameter."Result ReasonPhrase", CustomDimensions);
    end;
    /* #endif */
    /* #if BC19- ##
    begin
    end;
    /* #endif */

    internal procedure LogPrintNodeGetPrinters(_Printers: JsonToken)
    /* #if BC20+ */
    var
        CustomDimensions: Dictionary of [Text, Text];
    begin
        // Add generic dimensions
        AddGenericCustomDimensions(CustomDimensions);

        // Add specific dimensions for MOB2200
        CustomDimensions.Add('MobNoOfPrinters', Format(_Printers.AsArray().Count()));

        MobFeatureTelemetryWrapper.LogUsage(MobTelemetryEventId::"MOB PrintNode Get Printers (MOB2200)", '', CustomDimensions);
    end;
    /* #endif */
    /* #if BC19- ##
    begin
    end;
    /* #endif */

    internal procedure LogSandboxConfigurationGuideUsage(_StepName: Text; _EventName: Text)
    /* #if BC20+ */
    var
        CustomDimensions: Dictionary of [Text, Text];
    begin
        // Add generic dimensions
        AddGenericCustomDimensions(CustomDimensions);

        MobFeatureTelemetryWrapper.LogUsage(MobTelemetryEventId::"MOB Sandbox Configuration Guide (MOB2300)", StrSubstNo('%1.%2', _StepName, _EventName), CustomDimensions);
    end;
    /* #endif */
    /* #if BC19- ##
    begin
    end;
    /* #endif */

    internal procedure LogErrorAndRelatedFields(_MobTelemetryEventId: Enum "MOB Telemetry Event ID"; _ErrorText: Text; _RecRef: RecordRef; _FieldNumbers: List of [Integer])
    /* #if BC20+ */
    var
        CustomDimensions: Dictionary of [Text, Text];
    begin
        // Add generic dimensions
        AddGenericCustomDimensions(CustomDimensions);

        // Add selected field values
        AddFieldValuesToDimensions(_RecRef, _FieldNumbers, CustomDimensions);

        // Optional to specify a specific error text, as it can be specified directly in the Enum
        if _ErrorText = '' then
            _ErrorText := Format(_MobTelemetryEventId);

        MobFeatureTelemetryWrapper.LogError(_MobTelemetryEventId, GetEventName(), _ErrorText, CustomDimensions);
    end;
    /* #endif */
    /* #if BC19- ##
    begin
    end;
    /* #endif */

    internal procedure LogTweakUsage(var _TempTweakBuffer: Record "MOB Tweak Buffer")
    /* #if BC20+ */
    var
        CustomDimensions: Dictionary of [Text, Text];
        JsonTweakArray: JsonArray;
        JsonTweak: JsonObject;
    begin
        // Add generic dimensions
        AddGenericCustomDimensions(CustomDimensions);

        // Add selected field values
        CustomDimensions.Add('MobTweaksCount', Format(_TempTweakBuffer.Count(), 0, 9));

        // Build json array with each tweak as an object in the array
        // Prepare data for mv-expand in KQL: "| extend alMobTweaks = parse_json(trim('"', tostring(customDimensions.alMobTweaks)))"
        if _TempTweakBuffer.FindSet() then
            repeat
                Clear(JsonTweak);
                JsonTweak.Add('alMobTweakSortingId', Format(_TempTweakBuffer."Sorting Id", 0, 9));
                JsonTweak.Add('alMobTweakDescription', _TempTweakBuffer.Description);
                JsonTweak.Add('alMobTweakSourceName', _TempTweakBuffer."Source Name");
                JsonTweak.Add('alMobTweakSourcePublisher', _TempTweakBuffer."Source Publisher");
                JsonTweak.Add('alMobTweakSourceVersion', _TempTweakBuffer."Source Version");
                JsonTweakArray.Add(JsonTweak);
            until _TempTweakBuffer.Next() = 0;
        CustomDimensions.Add('MobTweaks', Format(JsonTweakArray));

        MobFeatureTelemetryWrapper.LogUsage(MobTelemetryEventId::"MOB Tweak Usage (MOB2020)", '', CustomDimensions);
    end;
    /* #endif */
    /* #if BC19- ##
    begin
    end;
    /* #endif */

    internal procedure SavePostMediaDetails(_MobWmsMediaQueue: Record "MOB WMS Media Queue")
    /* #if BC20+ */
    var
        TenantMedia: Record "Tenant Media";
        MobTelemetryContainer: Codeunit "MOB Telemetry Container";
    begin
        MobTelemetryContainer.AddToRequestDetails('MobImageId', _MobWmsMediaQueue."Image Id");
        MobTelemetryContainer.AddToRequestDetails('MobNoteLength', Format(StrLen(_MobWmsMediaQueue.Note), 0, 9));
        MobTelemetryContainer.AddToRequestDetails('MobRecordId', GetRedactedRecordId(_MobWmsMediaQueue."Record ID"));
        MobTelemetryContainer.AddToRequestDetails('MobTargetRecordId', GetRedactedRecordId(_MobWmsMediaQueue."Target Record ID"));

        if (_MobWmsMediaQueue.Picture.Count() > 0) and TenantMedia.Get(_MobWmsMediaQueue.Picture.Item(1)) then begin
            MobTelemetryContainer.AddToRequestDetails('MobImageHeight', Format(TenantMedia.Height, 0, 9));
            MobTelemetryContainer.AddToRequestDetails('MobImageWidth', Format(TenantMedia.Width, 0, 9));
            MobTelemetryContainer.AddToRequestDetails('MobImageSizeInKB', Format(Round(TenantMedia.Content.Length() / 1024, 1), 0, 9));
        end;
    end;
    /* #endif */
    /* #if BC19- ##
    begin
    end;
    /* #endif */


    internal procedure SavePostMediaImageStorageDetails(_MobWmsMediaQueue: Record "MOB WMS Media Queue")
    /* #if BC26+ */
    var
        MobTelemetryContainer: Codeunit "MOB Telemetry Container";
        StorageTxt: Text;
    begin
        if _MobWmsMediaQueue.IsExternalFile() then
            StorageTxt := GetExtStorageConnectorAsTextENU(_MobWmsMediaQueue."Ext. Storage Connector")
        else
            StorageTxt := 'Tenant Media';

        MobTelemetryContainer.AddToRequestDetails('MobImageStorage', StorageTxt);
    end;
    /* #endif */
    /* #if BC25,BC24,BC23,BC22,BC21,BC20 ##
    var
        MobTelemetryContainer: Codeunit "MOB Telemetry Container";
        StorageTxt: Text;
    begin
        StorageTxt := 'Tenant Media';
        MobTelemetryContainer.AddToRequestDetails('MobImageStorage', StorageTxt);
    end;
    /* #endif */
    /* #if BC19- ##
    begin
    end;
    /* #endif */


    local procedure GetRedactedRecordId(_RecordId: RecordId) RedactedText: Text
    var
        RecIdAsText: Text;
    begin
        RecIdAsText := GetRecordIdAsTextENU(_RecordId);
        if RecIdAsText = '' then
            exit(NotAvailableTxt);

        if RecIdAsText.Contains(':') then
            RedactedText := RecIdAsText.Substring(1, RecIdAsText.IndexOf(':') - 1)
        else
            RedactedText := RecIdAsText;

        case _RecordId.TableNo() of
            Database::"Sales Header",
            Database::"Sales Line",
            Database::"Purchase Header",
            Database::"Purchase Line",
            Database::"Warehouse Activity Header",
            Database::"Warehouse Activity Line":
                if RecIdAsText.Contains(':') and RecIdAsText.Contains(',') then
                    RedactedText := RecIdAsText.Substring(1, RecIdAsText.IndexOf(',') - 1);
        end;
    end;

    local procedure GetRecordIdAsTextENU(_RecordId: RecordId) RecIdAsText: Text
    var
        CurrentLanguage: Integer;
    begin
        CurrentLanguage := GlobalLanguage();
        GlobalLanguage(1033); // ENU
        RecIdAsText := Format(_RecordId, 0, 0);
        GlobalLanguage(CurrentLanguage);
    end;

    /* #if BC26+ */
    local procedure GetExtStorageConnectorAsTextENU(_ExtStorageConnector: Enum "Ext. File Storage Connector") ConnectorAsText: Text
    var
        CurrentLanguage: Integer;
    begin
        CurrentLanguage := GlobalLanguage();
        GlobalLanguage(1033); // ENU
        ConnectorAsText := Format(_ExtStorageConnector, 0, 0);
        GlobalLanguage(CurrentLanguage);
    end;
    /* #endif */

    local procedure AddFieldValuesToDimensions(_RecRef: RecordRef; _FieldNumbers: List of [Integer]; _CustomDimensions: Dictionary of [Text, Text])
    var
        FldRef: FieldRef;
        FldNo: Integer;
    begin
        for FldNo := 1 to _FieldNumbers.Count() do begin
            FldRef := _RecRef.Field(_FieldNumbers.Get(FldNo));
            _CustomDimensions.Add('Mob.' + _RecRef.Name() + '.' + FldRef.Name(), Format(FldRef.Value(), 0, 9));
        end;
    end;

    /// <summary>
    /// Adds the core custom dimensions to the telemetry dictionary without considering the request.
    /// </summary>
    local procedure AddCoreCustomDimensions(_CustomDimensions: Dictionary of [Text, Text])
    /* #if BC20+ */
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        _CustomDimensions.Add('MobGuiAllowed', Format(GuiAllowed(), 0, 9));
        _CustomDimensions.Add('MobIsSaaS', Format(EnvironmentInformation.IsSaaS(), 0, 9));
        _CustomDimensions.Add('MobEnvironmentName', EnvironmentInformation.GetEnvironmentName());
    end;
    /* #endif */
    /* #if BC19- ##
    begin
    end;
    /* #endif */

    /// <summary>
    /// Adds the generic custom dimensions to the telemetry dictionary.
    /// To be used when a logged event is initiated by a mobile request, and the DocQueue record is available.
    /// </summary>
    internal procedure AddGenericCustomDimensions(_MobDocQueue: Record "MOB Document Queue"; _CustomDimensions: Dictionary of [Text, Text]; _AddErrorCallStackIfPreserved: Boolean)
    var
        MobDocType: Record "MOB Document Type";
        MobDeviceManagement: Codeunit "MOB Device Management";
    begin
        /* #if BC20+ */
        AddCoreCustomDimensions(_CustomDimensions);

        // Add custom dimensions for MobDocQueue
        _CustomDimensions.Add('MobMessageId', _MobDocQueue."Message ID");
        _CustomDimensions.Add('MobDeviceId', _MobDocQueue."Device ID");
        _CustomDimensions.Add('MobDeviceAppVersion', Format(MobDeviceManagement.GetDeviceApplicationVersion()));
        _CustomDimensions.Add('MobAppInstaller', MobDeviceManagement.GetDeviceProperty('/application[@installer]'));
        if MobDocType.Get(_MobDocQueue."Document Type") then
            _CustomDimensions.Add('MobProcessingCodeunit', Format(MobDocType."Processing Codeunit", 0, 9));
        _CustomDimensions.Add('MobRegistrationType', _MobDocQueue."Registration Type");
        _CustomDimensions.Add('MobProcessingDurationInMs', Format(_MobDocQueue."Processing Duration" / 1, 0, 9)); // Convert the Duration to Integer

        if _AddErrorCallStackIfPreserved then
            if MobSessionData.IsLastErrorCallStackPreserved() then
                _CustomDimensions.Add('MobErrorCallStack', MobSessionData.GetPreservedLastErrorCallStack());
        /* #endif */
    end;

    /// <summary>
    /// Adds the generic custom dimensions to the telemetry dictionary by trying to find the request.
    /// To be used when a logged event can have been initiated by a mobile request, but the DocQueue record is not available.
    /// </summary>
    internal procedure AddGenericCustomDimensions(_CustomDimensions: Dictionary of [Text, Text])
    var
        MobDocQueue: Record "MOB Document Queue";
    begin
        /* #if BC20+ */
        if not IsNullGuid(MobSessionData.GetPostingMessageId()) then
            if MobDocQueue.GetByGuid(MobSessionData.GetPostingMessageId(), MobDocQueue) then begin
                AddGenericCustomDimensions(MobDocQueue, _CustomDimensions, false);
                exit;
            end;

        // If no request is found, just add the core generic custom dimensions
        AddCoreCustomDimensions(_CustomDimensions);
        /* #endif */
    end;

    internal procedure AddRequestDetailsCustomDimension(var _CustomDimensions: Dictionary of [Text, Text])
    /* #if BC20+ */
    var
        MobTelemetryContainer: Codeunit "MOB Telemetry Container";
        RequestDetailsCustomDimensions: Dictionary of [Text, Text];
        DimKey: Text;
        JObj: JsonObject;
    begin
        if not MobTelemetryContainer.GetRequestDetailsDictionary(RequestDetailsCustomDimensions) then
            exit;

        // Add the custom dimensions saved in the container
        foreach DimKey in RequestDetailsCustomDimensions.Keys() do
            JObj.Add(DimKey, RequestDetailsCustomDimensions.Get(DimKey));

        _CustomDimensions.Add('MobRequestDetails', Format(JObj));
    end;
    /* #endif */
    /* #if BC19- ##
    begin
    end;
    /* #endif */

    internal procedure GetEventIdAndFeatureName(_MobTelemetryEventId: Enum "MOB Telemetry Event ID"; var _EventId: Text; var _FeatureName: Text)
    begin
        /* #if BC20+ */
        _EventId := StrSubstNo('MOB%1', _MobTelemetryEventId.AsInteger());
        _FeatureName := Format(_MobTelemetryEventId); // Returns the locked English Caption of the enum. The name includes the event id which shouldn't be stored as feature name but is usefull for intellisense
        /* #endif */
    end;

    internal procedure GetEventName() _EventName: Text
    /* #if BC20+ */
    var
        MobDocQueue: Record "MOB Document Queue";
    begin
        // Get the EventName to group simular requests based on "Document Type" and "Registration Type"
        if not IsNullGuid(MobSessionData.GetPostingMessageId()) then
            if MobDocQueue.GetByGuid(MobSessionData.GetPostingMessageId(), MobDocQueue) then
                _EventName := GetEventName(MobDocQueue);
        if _EventName = '' then
            _EventName := 'Not a Mobile Reuqest';
    end;
    /* #endif */
    /* #if BC19- ##
    begin
    end;
    /* #endif */

    internal procedure GetEventName(_MobDocQueue: Record "MOB Document Queue") _EventName: Text
    /* #if BC20+ */
    var
        RegistrationType: Text;
    begin
        // Build the EventName to group simular requests based on "Document Type" and "Registration Type".
        // The _MobDocQueue."Registration Type" field is often modified by the request processor but the MobSessionData() contains the original value
        RegistrationType := MobSessionData.GetRegistrationType();

        if RegistrationType = '' then
            _EventName := _MobDocQueue."Document Type"
        else
            _EventName := StrSubstNo('%1.%2', _MobDocQueue."Document Type", RegistrationType)
    end;
    /* #endif */
    /* #if BC19- ##
    begin
    end;
    /* #endif */

    internal procedure SetFeatureTelemetryUsageLogged(_MobTelemetryEventId: Enum "MOB Telemetry Event ID")
    begin
        /* #if BC20+ */
        FeatureTelemetryLoggedUsed.Add(_MobTelemetryEventId);
        /* #endif */
    end;

    internal procedure GetFeatureTelemetryUsageLogged(_MobTelemetryEventId: Enum "MOB Telemetry Event ID"): Boolean
    begin
        /* #if BC20+ */
        exit(FeatureTelemetryLoggedUsed.Contains(_MobTelemetryEventId));
        /* #endif */
    end;
}
