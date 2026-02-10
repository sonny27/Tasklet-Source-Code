codeunit 81427 "MOB Stopwatch"
{
    Access = Public;
    SingleInstance = true;

    var
        CounterDict: Dictionary of [Text, Integer];
        DurationDict: Dictionary of [Text, Duration];
        StarttimeDict: Dictionary of [Text, DateTime];
        Initialized: Boolean;

    trigger OnRun()
    var
        i: Integer;
        j: Integer;
    begin
        // The codeunit is SingleInstance. 
        // You can therefore start and stop counters in different objects via individual Stopwatch variables

        // Example of usage
        Initialize();
        Start('Overall');
        for i := 1 to 10 do begin
            Start('Overall step');
            for j := 1 to 20 do begin
                Start('Function 1');
                Sleep(25);
                Stop('Function 1');
                Start('Function 2');
                Sleep(50);
                Stop('Function 2');
            end;
            Stop('Overall step');
        end;
        Stop('Overall');
        ShowResults();

        /* Example output: (manuelly added blanks to align columns)

        Key;       Duration(ms); Count; Duration(txt)
        Overall;          18793;     1; 18 seconds 793 milliseconds
        Overall step;     18793;    10; 18 seconds 793 milliseconds
        Function 1;        6279;   200; 6 seconds 279 milliseconds
        Function 2;       12514;   200; 12 seconds 514 milliseconds

        */
    end;

    internal procedure Initialize()
    begin
        Clear(CounterDict);
        Clear(DurationDict);
        Clear(StarttimeDict);
        Initialized := true;
    end;

    internal procedure Start(_Name: Text)
    var
        CurrCounter: Integer;
    begin
        if CounterDict.Get(_Name, CurrCounter) then begin
            StarttimeDict.Set(_Name, CurrentDateTime()); // Currently not checking if already started
            CounterDict.Set(_Name, CurrCounter + 1);
        end else begin
            StarttimeDict.Add(_Name, CurrentDateTime());
            CounterDict.Add(_Name, 1);
            DurationDict.Add(_Name, 0);
        end;
    end;

    internal procedure Stop(_Name: Text)
    var
        StartDatetime: DateTime;
        CurrDuration: Duration;
    begin
        StarttimeDict.Get(_Name, StartDatetime);
        DurationDict.Get(_Name, CurrDuration);
        DurationDict.Set(_Name, (CurrentDateTime() - StartDatetime) + CurrDuration);
        StarttimeDict.Set(_Name, 0DT);
    end;

    internal procedure ShowResults()
    var
        MobToolbox: Codeunit "MOB Toolbox";
        ThisCounter: Integer;
        ThisDuration: Duration;
        ThisDurationMs: Integer;
        DictKey: Text;
        Result: Text;
    begin
        Result := 'Key; Duration(ms); Count; Duration(txt)';
        foreach DictKey in CounterDict.Keys() do begin
            DurationDict.Get(DictKey, ThisDuration);
            CounterDict.Get(DictKey, ThisCounter);
            ThisDurationMs := ThisDuration;
            Result := Result + MobToolbox.CRLFSeparator() + StrSubstNo('%1; %2; %3; %4', DictKey, ThisDurationMs, ThisCounter, ThisDuration);
        end;
        Message(Result);

        if not Initialized then
            Message('Please make sure to Initialize the Stopwatch codeunit before usage.\Otherwise the results will be accumulated.');
    end;
}
