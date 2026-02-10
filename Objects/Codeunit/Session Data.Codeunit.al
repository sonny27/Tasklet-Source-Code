codeunit 81272 "MOB SessionData"
{
    Access = Public;
    // Stores values to be maintained on error

    SingleInstance = true;

    var
        MobTelemetryContainer: Codeunit "MOB Telemetry Container";
        DevicePropertyDictionary: Dictionary of [Text[250], Text[250]];
        PostingMessageId: Guid;
        MobileUserID: Code[50];
        DeviceID: Code[200];
        DeviceLanguageID: Integer;
        DocumentType: Text[50];
        RegistrationType: Text;
        RegistrationTypeTracking: Text;
        PreservedLastErrorCallStack: Text;
        LastErrorCallStackPreserved: Boolean;
        ProcessingStartDateTime: DateTime;
    //
    // WS Dispatcher: PostingMessageId, MobileUserID, DeviceID and ProcessingStartDateTime
    // 

    /// <summary>
    /// Ensure unassigned values (i.e. PostingMessageId) are cleared when executing requests manually via GUI or from Unit Tests.
    /// Clear(codeunit) does not clear variables in single instance codeunits.
    /// </summary>
    procedure Initialize()
    begin
#pragma warning disable LC0032 // MobTelemetryContainer is a SingleInstance codeunit but is cleared below
        ClearAll();
#pragma warning restore LC0032
        MobTelemetryContainer.ClearRequestDetailsDictionary();
    end;

    internal procedure SetPostingMessageId(_PostingMessageId: Guid)
    begin
        PostingMessageId := _PostingMessageId;
    end;

    procedure GetPostingMessageId(): Guid
    begin
        exit(PostingMessageId);
    end;

    internal procedure SetMobileUserID(_MobileUserID: Code[50])
    begin
        MobileUserID := _MobileUserID;
    end;

    procedure GetMobileUserID(): Code[50]
    begin
        exit(MobileUserID);
    end;

    internal procedure SetDeviceID(_DeviceID: Code[200])
    begin
        DeviceID := _DeviceID;
    end;

    procedure GetDeviceID(): Code[200]
    begin
        exit(DeviceID);
    end;

    internal procedure SetDeviceLanguageID(_LanguageID: Integer)
    begin
        DeviceLanguageID := _LanguageID;
    end;

    procedure GetDeviceLanguageID(): Integer
    begin
        exit(DeviceLanguageID);
    end;

    internal procedure SetProcessingStartDateTime(_ProcessingStartDateTime: DateTime)
    begin
        ProcessingStartDateTime := _ProcessingStartDateTime;
    end;

    procedure GetProcessingStartDateTime(): DateTime
    begin
        exit(ProcessingStartDateTime);
    end;

    //
    // Mobile Document Queue / Registration Type Tracking : Store fallback values on error
    //

    procedure SetDocumentType(_DocumentType: Text[50])
    begin
        DocumentType := _DocumentType;
    end;

    procedure GetDocumentType(): Text[50]
    begin
        exit(DocumentType);
    end;

    procedure SetRegistrationTypeAndTracking(_RegistrationType: Text; _RegistrationTypeTracking: Text)
    begin
        SetRegistrationType(_RegistrationType);
        SetRegistrationTypeTracking(_RegistrationTypeTracking);
    end;

    procedure SetRegistrationType(_RegistrationType: Text)
    begin
        RegistrationType := _RegistrationType;
    end;

    procedure GetRegistrationType(): Text
    begin
        exit(RegistrationType);
    end;

    procedure SetRegistrationTypeTracking(_RegistrationTypeTracking: Text)
    begin
        RegistrationTypeTracking := _RegistrationTypeTracking;
    end;

    procedure GetRegistrationTypeTracking(): Text
    begin
        exit(RegistrationTypeTracking);
    end;

    /// <summary>
    /// Set/preserve the LastErrorCallStack to display in the document queue on error. Overrides last callstack when errors are recasted from our own code.
    /// </summary>
    procedure SetPreservedLastErrorCallStack()
    begin
        PreservedLastErrorCallStack := GetLastErrorCallStack();
        LastErrorCallStackPreserved := true;
    end;

    /// <summary>
    /// Get/read a preserved LastErrorCallStack to display in the document queue on error. Overrides last callstack when errors are recasted from our own code.
    /// </summary>
    internal procedure GetPreservedLastErrorCallStack(): Text
    begin
        if PreservedLastErrorCallStack <> '' then
            exit(PreservedLastErrorCallStack)
        else
            exit(GetLastErrorCallStack());
    end;

    /// <summary>
    /// Check to avoid getting unrelated error in ErrorCallStack.
    /// </summary>
    internal procedure IsLastErrorCallStackPreserved(): Boolean
    begin
        exit(LastErrorCallStackPreserved);
    end;

    /// <summary>
    /// Wrapper for a global single instance dictionary variable to cache device properties.
    /// </summary>
    /// <param name="_Key">The key of the value to get. If the specified key is not found an error will be reported.</param>
    /// <param name="_Value">The value associated with the specified key.</param>
    /// <returns>Specifies whether the Key existed or not</returns>
    internal procedure DevicePropertyDictionary_Get(_Key: Text; var _Value: Text): Boolean
    begin
        if DevicePropertyDictionary.ContainsKey(_Key) then
            exit(DevicePropertyDictionary.Get(_Key, _Value));
    end;

    /// <summary>
    /// Wrapper for a global single instance dictionary variable to cache device properties.
    /// </summary>
    /// <param name="_Key">The key of the value to add.</param>
    /// <param name="_Value">The value associated with the specified key.</param>
    internal procedure DevicePropertyDictionary_Add(_Key: Text; _Value: Text)
    begin
        if not DevicePropertyDictionary.ContainsKey(_Key) then
            DevicePropertyDictionary.Add(_Key, _Value);
    end;

}
