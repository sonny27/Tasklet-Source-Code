codeunit 81352 "MOB Tweak Container"
{
    Access = Public;
    var
        TempMobTweakBuffer: Record "MOB Tweak Buffer" temporary;
        SortingIdMissingErr: Label 'Internal error: Tweak SortingId must be greater than 0 for %1', Locked = true;
        DescriptionMissingErr: Label 'Internal error: Tweak Description must be specified for %1', Locked = true;
        ContentMissingErr: Label 'Internal error: Tweak Content must be specified for %1', Locked = true;

    /// <summary>
    /// Add a tweak to the tweak container
    /// </summary>
    /// <param name="_SortingId">Determins the order the tweaks are applied to the application.cfg. If a tweak dependens on another tweak, it will need to have a higher SortingId to be applied in the right order.</param>
    /// <param name="_Description">A description to identity the contents of the tweak. The extension name and publisher of the tweak is automatically added, so focus on describing the content or purpose of the tweak</param>
    /// <param name="_Content">The XML content of the tweak</param>
    procedure Add(_SortingId: Integer; _Description: Text[100]; _Content: Text)
    var
        CallerModuleInfo: ModuleInfo;
        OStream: OutStream;
    begin
        if _SortingId <= 0 then
            Error(SortingIdMissingErr, _Description);
        if _Description = '' then
            Error(DescriptionMissingErr, _Description);
        if _Content = '' then
            Error(ContentMissingErr, _Description);

        // Init and store simple values
        TempMobTweakBuffer.Init();
        TempMobTweakBuffer."Sorting Id" := _SortingId;
        TempMobTweakBuffer.Description := _Description;

        // Store the content in Blob field in the buffer table
        TempMobTweakBuffer.Content.CreateOutStream(OStream);
        OStream.Write(_Content);

        // Store the caller module info
        /* #if BC19+ */
        // CallerModuleInfo is first available from BC19 (unless we change target to OnPrem - then it's available from BC17)
        NavApp.GetCallerModuleInfo(CallerModuleInfo);
        TempMobTweakBuffer."Source Name" := CallerModuleInfo.Name();
        TempMobTweakBuffer."Source Publisher" := CallerModuleInfo.Publisher();
        TempMobTweakBuffer."Source Version" := Format(CallerModuleInfo.AppVersion());
        /* #endif */
        /* #if BC18- ##
        // CallerModuleInfo is first available from BC19 (unless we change target to OnPrem - then it's available from BC17)
        TempMobTweakBuffer."Source Name" := 'Unknown';
        TempMobTweakBuffer."Source Publisher" := 'Unknown';
        TempMobTweakBuffer."Source Version" := '0.0.0.0';
        /* #endif */

        // Set File Name (PK) to the name of the tweak, which determines the order the tweaks are handled
        TempMobTweakBuffer."File Name" := TempMobTweakBuffer.GetTweakName();

        TempMobTweakBuffer.Insert();
    end;

    internal procedure GetTweakBuffer(var _TempMobTweakBuffer: Record "MOB Tweak Buffer")
    begin
        _TempMobTweakBuffer.Copy(TempMobTweakBuffer, true); // true = ShareTable
    end;
}
