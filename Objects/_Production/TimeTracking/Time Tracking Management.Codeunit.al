codeunit 81418 "MOB Time Tracking Management"
{
    Access = Public;
    var
        MobSessionData: Codeunit "MOB SessionData";
        IconNoEntriesTxt: Label '-', Locked = true;
        IconStartedTxt: Label '▶️', Locked = true;
        IconStoppedTxt: Label '⏹', Locked = true;


    /// <summary>
    /// Init a new open Time Tracking Entry record without inserting into DB
    /// The duration (Quantity) is calculated and populated for the StopTime entry (assuming StartTime do not change prior to application)
    /// </summary>
    /// <remarks>
    /// A description of how Time Tracking entries are created and applied can be found in spreadsheet attached to original development task NTW-1111
    /// </remarks>
    procedure InitTimeTrackingEntry(var _NewEntry: Record "MOB Time Tracking Entry"; _SourceRecordId: RecordId; _TimeTrackingEntryType: Enum "MOB Time Tracking Entry Type"; _NewTimeTrackingStatus: Enum "MOB Time Tracking Status"; _NewDateTime: DateTime)
    var
        MobDocQueue: Record "MOB Document Queue";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        StartTimeTrackingEntry: Record "MOB Time Tracking Entry";
        MobCommonMgt: Codeunit "MOB Common Mgt.";
        MobUoMMgt: Codeunit "MOB Unit of Measure Management";
        ProcessDuration: Duration;
        TimeFactor: Decimal;
        CollectedDateTimeWithTimeZoneOffset: Text;
        NewUtcDateTime: DateTime;
    begin
        case _SourceRecordId.TableNo() of
            Database::"Prod. Order Routing Line":
                ProdOrderRoutingLine.Get(_SourceRecordId);
            else
                Error('InitTimeTrackingEntry(): _SourceRecordId.TableNo() = %1 not supported.', _SourceRecordId.TableNo());
        end;

        // Convert to UtcDateTime
        if IsNullGuid(MobSessionData.GetPostingMessageId()) then
            NewUtcDateTime := _NewDateTime  // Support for unit tests with no association to device (no queue entry)
        else begin
            MobDocQueue.GetByGuid(MobSessionData.GetPostingMessageId(), MobDocQueue);
            CollectedDateTimeWithTimeZoneOffset := Format(_NewDateTime, 0, '<Year4>-<Month,2>-<Day,2>T<Hours24,2>:<Minutes,2>:<Seconds,2>') + MobDocQueue.GetRequestTimeZoneOffSet();
            Evaluate(NewUtcDateTime, CollectedDateTimeWithTimeZoneOffset, 9); // Input format in Xml DateTime-format with numberformat 9 will evaluate to Utc
        end;

        _NewEntry.Init();
        Clear(_NewEntry."Entry No.");
        _NewEntry."Registering Date" := Today();
        _NewEntry."Mobile User ID" := MobSessionData.GetMobileUserID();  // May reprocess for a different user from queue
        _NewEntry."Device ID" := MobSessionData.GetDeviceID();
        _NewEntry."Time Tracking Entry Type" := _TimeTrackingEntryType;
        _NewEntry."Time Tracking Status" := _NewTimeTrackingStatus;
        _NewEntry."Source RecordId" := ProdOrderRoutingLine.RecordId();
        _NewEntry."Prod. Order Status" := ProdOrderRoutingLine.Status;
        _NewEntry."Prod. Order No." := ProdOrderRoutingLine."Prod. Order No.";
        _NewEntry."Routing No." := ProdOrderRoutingLine."Routing No.";
        _NewEntry."Routing Reference No." := ProdOrderRoutingLine."Routing Reference No.";
        _NewEntry."Operation No." := ProdOrderRoutingLine."Operation No.";

        // Source: Prod. Order Routing Line
        case _NewEntry."Time Tracking Entry Type" of
            _NewEntry."Time Tracking Entry Type"::"Production Output Run Time":
                _NewEntry."Capacity Unit of Measure Code" := ProdOrderRoutingLine."Run Time Unit of Meas. Code";
            _NewEntry."Time Tracking Entry Type"::"Production Output Setup Time":
                _NewEntry."Capacity Unit of Measure Code" := ProdOrderRoutingLine."Setup Time Unit of Meas. Code";
        end;

        case _NewTimeTrackingStatus of
            _NewEntry."Time Tracking Status"::Started:
                begin
                    _NewEntry."Start DateTime" := NewUtcDateTime;
                    _NewEntry."Start Date" := DT2Date(_NewDateTime);
                    _NewEntry."Start Time" := DT2Time(_NewDateTime);
                    _NewEntry.Quantity := 0; // Populated only for StopTime entries
                end;
            _NewEntry."Time Tracking Status"::Stopped:
                begin
                    _NewEntry.TestField("Capacity Unit of Measure Code");

                    GetStartTimeTrackingEntry(_NewEntry, StartTimeTrackingEntry);
                    _NewEntry."Start DateTime" := StartTimeTrackingEntry."Start DateTime";
                    _NewEntry."Start Date" := StartTimeTrackingEntry."Start Date";
                    _NewEntry."Start Time" := StartTimeTrackingEntry."Start Time";
                    if _NewEntry."Start Date" <> 0D then            // StartDateTime is UtcDateTime from pull request when "Start Date" field was also created
                        _NewEntry."Stop DateTime" := NewUtcDateTime
                    else
                        _NewEntry."Stop DateTime" := _NewDateTime;  // Corresponding StartTimeTrackingEntry is not converted to Utc but using DateTime from registration as-is
                    _NewEntry."Stop Date" := DT2Date(_NewDateTime);
                    _NewEntry."Stop Time" := DT2Time(_NewDateTime);
                    ProcessDuration := _NewEntry."Stop DateTime" - _NewEntry."Start DateTime";
                    TimeFactor := MobCommonMgt.TimeFactor(_NewEntry."Capacity Unit of Measure Code");

                    _NewEntry.Quantity := Round(ProcessDuration / TimeFactor, MobUoMMgt.TimeRndPrecision());
                end;
        end;

        _NewEntry.Open := true;
        _NewEntry."Applies-to Entry No." := 0;
    end;

    /// <summary>
    /// Get the StartTime-entry associated to a StopTime-entry
    /// </summary>
    internal procedure GetStartTimeTrackingEntry(_StopTimeTrackingEntry: Record "MOB Time Tracking Entry"; var _StartTimeTrackingEntry: Record "MOB Time Tracking Entry")
    begin
        _StartTimeTrackingEntry.Reset();
        _StartTimeTrackingEntry.SetRange("Mobile User ID", _StopTimeTrackingEntry."Mobile User ID");
        _StartTimeTrackingEntry.SetRange("Device ID", _StopTimeTrackingEntry."Device ID");
        OnAfterFilterTimeTrackingEntry(_StartTimeTrackingEntry);
        _StartTimeTrackingEntry.SetRange("Source RecordId", _StopTimeTrackingEntry."Source RecordId");
        _StartTimeTrackingEntry.SetRange("Time Tracking Entry Type", _StopTimeTrackingEntry."Time Tracking Entry Type");
        _StartTimeTrackingEntry.SetRange("Time Tracking Status", _StartTimeTrackingEntry."Time Tracking Status"::Started);
        _StartTimeTrackingEntry.SetRange(Open, true);
        _StartTimeTrackingEntry.FindFirst();
    end;

    /// <summary>
    /// Apply and close associcated StartTime- and StopTime-entries
    /// </summary>
    procedure ApplyStopTimeTrackingEntry(var _StopTimeTrackingEntry: Record "MOB Time Tracking Entry")
    var
        StartTimeTrackingEntry: Record "MOB Time Tracking Entry";
        MobTimeTrackingStatus: Enum "MOB Time Tracking Status";
    begin
        _StopTimeTrackingEntry.TestField("Time Tracking Status", MobTimeTrackingStatus::Stopped);
        _StopTimeTrackingEntry.TestField(Open, true);

        GetStartTimeTrackingEntry(_StopTimeTrackingEntry, StartTimeTrackingEntry);
        _StopTimeTrackingEntry.Open := false;
        _StopTimeTrackingEntry."Applies-to Entry No." := StartTimeTrackingEntry."Entry No.";
        _StopTimeTrackingEntry.Modify();

        StartTimeTrackingEntry.Open := false;
        StartTimeTrackingEntry.Modify();
    end;

    /// <summary>
    /// Calculate the current Time Tracking Status for a SourceRecordId / Entry Type combination
    /// </summary>
    /// <returns>
    /// Time Tracking Status: " " = No entries; "Started" = In progress; "Stopped" = Previously started but now stopped
    /// </returns>
    procedure CalcCurrentTimeTrackingStatus(_SourceRecordId: RecordId; _TimeTrackingEntryType: Enum "MOB Time Tracking Entry Type"): Enum "MOB Time Tracking Status"
    var
        MobTimeTrackingEntry: Record "MOB Time Tracking Entry";
        HasEntries: Boolean;
        IsStarted: Boolean;
        IsStopped: Boolean;
    begin
        GetCurrentTimeTrackingStatus(_SourceRecordId, _TimeTrackingEntryType, HasEntries, IsStarted, IsStopped);
        case true of
            not HasEntries:
                exit(MobTimeTrackingEntry."Time Tracking Status"::" "); // No entries
            IsStarted:
                exit(MobTimeTrackingEntry."Time Tracking Status"::Started); // Currently in progress
        end;

        exit(MobTimeTrackingEntry."Time Tracking Status"::Stopped);   // Has entries but not currently in progress
    end;

    /// <summary>
    /// Local helper method for public GetCurrentTimeTrackingStatus-signature
    /// </summary>
    /// <returns>
    /// Booleans for HasEntries, IsStarted and IsStopped
    /// </returns>
    local procedure GetCurrentTimeTrackingStatus(_SourceRecordId: RecordId; _TimeTrackingEntryType: Enum "MOB Time Tracking Entry Type"; var _HasEntries: Boolean; var _IsStarted: Boolean; var _IsStopped: Boolean)
    var
        MobTimeTrackingEntry: Record "MOB Time Tracking Entry";
        MobTimeTrackingStatus: Enum "MOB Time Tracking Status";
    begin

        MobTimeTrackingEntry.Reset();
        MobTimeTrackingEntry.SetRange("Mobile User ID", MobSessionData.GetMobileUserID());
        MobTimeTrackingEntry.SetRange("Device ID", MobSessionData.GetDeviceID());
        OnAfterFilterTimeTrackingEntry(MobTimeTrackingEntry);
        MobTimeTrackingEntry.SetRange("Source RecordId", _SourceRecordId);
        MobTimeTrackingEntry.SetRange("Time Tracking Entry Type", _TimeTrackingEntryType);

        Clear(_HasEntries);
        MobTimeTrackingEntry.SetRange("Time Tracking Status", MobTimeTrackingStatus::Started);
        MobTimeTrackingEntry.SetRange(Open);
        if not MobTimeTrackingEntry.IsEmpty() then
            _HasEntries := true;

        Clear(_IsStarted);
        MobTimeTrackingEntry.SetRange("Time Tracking Status", MobTimeTrackingStatus::Started);
        MobTimeTrackingEntry.SetRange(Open, true);
        if not MobTimeTrackingEntry.IsEmpty() then
            _IsStarted := true;

        Clear(_IsStopped);
        if not _IsStarted then begin
            MobTimeTrackingEntry.SetRange("Time Tracking Status", MobTimeTrackingStatus::Stopped);
            MobTimeTrackingEntry.SetRange(Open);
            if not MobTimeTrackingEntry.IsEmpty() then
                _IsStopped := true;
        end;
    end;

    /// <summary>
    /// Get icon for calculated Time Tracking Status for a SourceRecordId / Entry Type combination
    /// </summary>
    procedure GetStatusIcon(_SourceRecordId: RecordId; _TimeTrackingEntryType: Enum "MOB Time Tracking Entry Type"): Text
    var
        MobTimeTrackingStatus: Enum "MOB Time Tracking Status";
    begin
        MobTimeTrackingStatus := CalcCurrentTimeTrackingStatus(_SourceRecordId, _TimeTrackingEntryType);
        case MobTimeTrackingStatus of
            MobTimeTrackingStatus::" ":
                exit("CONST::IconNoEntries"());
            MobTimeTrackingStatus::Started:
                exit("CONST::IconStarted"());
            MobTimeTrackingStatus::Stopped:
                exit("CONST::IconStopped"());
        end;
    end;

    procedure "CONST::IconNoEntries"(): Text
    begin
        exit(IconNoEntriesTxt);
    end;

    procedure "CONST::IconStarted"(): Text
    begin
        exit(IconStartedTxt);
    end;

    procedure "CONST::IconStopped"(): Text
    begin
        exit(IconStoppedTxt);
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnAfterFilterTimeTrackingEntry(var _MobTimeTrackingEntry: Record "MOB Time Tracking Entry")
    begin
    end;

}
