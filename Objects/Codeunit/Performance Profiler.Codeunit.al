codeunit 81275 "MOB Perf. Profiler"
{
    /* #if BC20+ */

    SingleInstance = true;
    Access = Internal;

    var
        SamplingPerformanceProfiler: Codeunit "Sampling Performance Profiler";
        StartSqlRowsRead: BigInteger;
        StartSqlStatementsExecuted: BigInteger;
        MobRecordingInProgress: Boolean;
        ProfilingEnabledMsg: Label 'Sampling Profiling has been activated for %1 %2 for 15 minutes.\\Sampling Profiling does not give an accurate view of code execution. But it can give an indication about the time spent in different code sections by periodically log the executing code.\\The frequency can be increased to improve level of detail for manually processed requests by activating additional logging in the Business Central Help & Support window.\\The results are typically better the longer the request takes to process. It is therefore recommended to only use sampling profiling for requests taking longer than 750ms to process.', Comment = '(Do not translate Sampling Profiling) %1 contains table name (i.e. Mobile User), %2 contains primary key of table (i.e. JOHN)', Locked = true;
        ProfilingDisabledMsg: Label 'Sampling Profiling has been disabled for %1 %2.', Comment = '(Do not translate Sampling Profiling) %1 contains table name (i.e. Mobile User), %2 contains primary key of table (i.e. JOHN)', Locked = true;

    procedure IsActivatedForUserOrDocumentType(var _MobDocQueue: Record "MOB Document Queue"): Boolean
    var
        MobUser: Record "MOB User";
        MobDocType: Record "MOB Document Type";
    begin
        MobUser.SetRange("User ID", _MobDocQueue."Mobile User ID");
        MobUser.SetFilter("Profiling Enabled Until", '>%1', CurrentDateTime());
        if not MobUser.IsEmpty() then
            exit(true);

        MobDocType.SetRange("Document Type", _MobDocQueue."Document Type");
        MobDocType.SetFilter("Profiling Enabled Until", '>%1', CurrentDateTime());
        if not MobDocType.IsEmpty() then
            exit(true);

        exit(false);
    end;

    procedure Start()
    begin
        if IsRecordingInProgress() then
            exit;

        ClearAll();

        // Store selected SessionInformation values to store deltas
        MobRecordingInProgress := true;
        StartSqlRowsRead := SessionInformation.SqlRowsRead();
        StartSqlStatementsExecuted := SessionInformation.SqlStatementsExecuted();

        // Flush service tier data cache to increase chance of finding poorly performing queries
        SelectLatestVersion();

        // Start the actual Sampling Performance Profiler
        StartPerformanceProfiler();
    end;

    procedure Stop()
    var
        MobPerformanceProfileEntry: Record "MOB Perf. Profile Entry";
    begin
        Stop(MobPerformanceProfileEntry);
    end;

    procedure Stop(var _MobPerformanceProfileEntry: Record "MOB Perf. Profile Entry")
    var
        OStream: OutStream;
    begin
        if not MobRecordingInProgress then
            exit;

        MobRecordingInProgress := false;
        SamplingPerformanceProfiler.Stop();

        _MobPerformanceProfileEntry.InitializeValues();
        _MobPerformanceProfileEntry."Mobile WMS Extension Version" := GetAppVersion('MOB');
        _MobPerformanceProfileEntry."Base App Version" := GetAppVersion('BASE');
        _MobPerformanceProfileEntry."SQL Statements Executed" := SessionInformation.SqlStatementsExecuted() - StartSqlStatementsExecuted;
        _MobPerformanceProfileEntry."SQL Rows Read" := SessionInformation.SqlRowsRead() - StartSqlRowsRead;
        _MobPerformanceProfileEntry."Profile Data".CreateOutStream(OStream);
        CopyStream(OStream, SamplingPerformanceProfiler.GetData());
        _MobPerformanceProfileEntry.Insert();
    end;

    procedure IsRecordingInProgress(): Boolean
    begin
        exit(MobRecordingInProgress);
    end;

    procedure ToggleEnabledUntil(var _ProfilingEnabledUntil: DateTime; _TableCaption: Text; _TablePK: Text)
    begin
        if _ProfilingEnabledUntil < CurrentDateTime() then begin
            _ProfilingEnabledUntil := CurrentDateTime() + (15 * 60 * 1000); // 15 minutes
            Message(ProfilingEnabledMsg, _TableCaption, _TablePK);
        end else begin
            Clear(_ProfilingEnabledUntil);
            Message(ProfilingDisabledMsg, _TableCaption, _TablePK);
        end;
    end;

    procedure DownloadProfilerFiles(var _MobPerfProfileEntry: Record "MOB Perf. Profile Entry")
    var
        MobDocQueue: Record "MOB Document Queue";
        DataCompression: Codeunit "Data Compression";
        TempBlob: Codeunit "Temp Blob";
        IStream: InStream;
        FileName: Text;
    begin
        DataCompression.CreateZipArchive();

        _MobPerfProfileEntry.SetAutoCalcFields("Profile Data");
        _MobPerfProfileEntry.FindSet();
        repeat
            _MobPerfProfileEntry."Profile Data".CreateInStream(IStream);
            DataCompression.AddEntry(IStream, _MobPerfProfileEntry.FilenameWithExtension());

            MobDocQueue.SetAutoCalcFields("Request XML", "Answer XML");
            MobDocQueue.Get(_MobPerfProfileEntry."Message ID");

            MobDocQueue."Request XML".CreateInStream(IStream);
            DataCompression.AddEntry(IStream, (StrSubstNo('%1 %2 (Request).xml', MobDocQueue."Document Type", MobDocQueue."Message ID")));

            MobDocQueue."Answer XML".CreateInStream(IStream);
            DataCompression.AddEntry(IStream, (StrSubstNo('%1 %2 (Response).xml', MobDocQueue."Document Type", MobDocQueue."Message ID")));
        until _MobPerfProfileEntry.Next() = 0;

        DataCompression.SaveZipArchive(TempBlob);
        FileName := StrSubstNo('%1 (BASE%2 MOB%3).zip', CompanyName(), GetAppVersion('BASE'), GetAppVersion('MOB'));
        DownloadFromStream(TempBlob.CreateInStream(), '', '', '', FileName);
    end;

    procedure GetAppVersion(_AppTag: Text): Text[50]
    var
        AppModuleInfo: ModuleInfo;
        AppGuid: Guid;
    begin
        case _AppTag of
            'MOB':
                AppGuid := 'a5727ce6-368c-49e2-84cb-1a6052f0551c'; // Mobile WMS
            'BASE':
                AppGuid := '437dbf0e-84ff-417a-965d-ed2bb9650972'; // Base Application by Microsoft                                
            else
                exit('');
        end;

        if not NavApp.GetModuleInfo(AppGuid, AppModuleInfo) then
            exit('');

        exit(Format(AppModuleInfo.AppVersion()));
    end;

    /* #endif */

    // ********************************************************************************************************************
    // Code above is active for BC20+
    // ********************************************************************************************************************
    // Code below differs per version
    // ********************************************************************************************************************

    local procedure StartPerformanceProfiler()
    begin
        /* #if BC23+ */
        SamplingPerformanceProfiler.Start("Sampling Interval"::SampleEvery50ms); // 50ms is the minimum interval and gives the most details
        /* #endif */
        /* #if BC20,BC21,BC22 ##
        SamplingPerformanceProfiler.Start();
        /* #endif */
    end;
}
