codeunit 81302 "MOB Feature Telemetry Wrapper"
{
    Access = Public;
    /* #if BC20+ */
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        MobTelemetryMgt: Codeunit "MOB Telemetry Management";
        FeatureUptakeStatus: Enum "Feature Uptake Status";
        MobTelemetryEventId: Enum "MOB Telemetry Event ID";
    /* #endif */

    /// <summary>
    /// A wrapper function for the FeatureTelemetry.LogUptake() available from BC20
    /// </summary>
    /// <param name="_EventId">A unique ID of the event.</param>
    /// <param name="_FeatureName">The name of the feature.</param>
    internal procedure LogUptakeDiscovered(_MobTelemetryEventId: Enum "MOB Telemetry Event ID")
    begin
        /* #if BC20+ */
        LogUptake(_MobTelemetryEventId, FeatureUptakeStatus::Discovered);
        /* #endif */
    end;

    /// <summary>
    /// A wrapper function for the FeatureTelemetry.LogUptake() available from BC20
    /// </summary>
    /// <param name="_EventId">A unique ID of the event.</param>
    /// <param name="_FeatureName">The name of the feature.</param>
    internal procedure LogUptakeSetup(_MobTelemetryEventId: Enum "MOB Telemetry Event ID")
    begin
        /* #if BC20+ */
        LogUptake(_MobTelemetryEventId, FeatureUptakeStatus::"Set up");
        /* #endif */
    end;

    internal procedure LogUptakeSetupOfPackageNoFeature(_MobSetup: Record "MOB Setup")
    begin
        /* #if BC20+ */
        case _MobSetup."Package No. implementation" of
            _MobSetup."Package No. implementation"::"Standard Mobile WMS":
                LogUptakeSetup(MobTelemetryEventId::"Package No. Implementation (Standard Mobile WMS) (MOB1000)");
            _MobSetup."Package No. implementation"::"None/Customization":
                LogUptakeUndiscovered(MobTelemetryEventId::"Package No. Implementation (Standard Mobile WMS) (MOB1000)");
        end;
        /* #endif */
    end;

    internal procedure LogUptakeSetupOfMobilePrintFeature(_MobPrintSetup: Record "MOB Print Setup")
    begin
        /* #if BC20+ */
        if _MobPrintSetup.Enabled then
            LogUptakeSetup(MobTelemetryEventId::"Mobile Print Feature (MOB1020)")
        else
            LogUptakeUndiscovered(MobTelemetryEventId::"Mobile Print Feature (MOB1020)");
        /* #endif */
    end;

    /// <summary>
    /// A wrapper function for the FeatureTelemetry.LogUptake() available from BC20
    /// </summary>
    /// <param name="_EventId">A unique ID of the event.</param>
    /// <param name="_FeatureName">The name of the feature.</param>
    internal procedure LogUptakeUsed(_MobTelemetryEventId: Enum "MOB Telemetry Event ID")
    begin
        /* #if BC20+ */
        LogUptake(_MobTelemetryEventId, FeatureUptakeStatus::Used);
        /* #endif */
    end;

    internal procedure LogUptakeUsedByPackageNo()
    /* #if BC20+ */
    var
        MobSetup: Record "MOB Setup";
    begin
        // Avoid getting MobSetup unless nessesary requires both options checked        
        if MobTelemetryMgt.GetFeatureTelemetryUsageLogged(MobTelemetryEventId::"Package No. implementation (None/Customization) (MOB1001)") then
            exit;
        if MobTelemetryMgt.GetFeatureTelemetryUsageLogged(MobTelemetryEventId::"Package No. Implementation (Standard Mobile WMS) (MOB1000)") then
            exit;

        MobSetup.Get();
        case MobSetup."Package No. implementation" of
            MobSetup."Package No. implementation"::"None/Customization":
                LogUptakeUsed(MobTelemetryEventId::"Package No. implementation (None/Customization) (MOB1001)");
            MobSetup."Package No. implementation"::"Standard Mobile WMS":
                LogUptakeUsed(MobTelemetryEventId::"Package No. Implementation (Standard Mobile WMS) (MOB1000)");
        end;
    end;
    /* #endif */
    /* #if BC19- ##
    begin
    end;
    /* #endif */

    /// <summary>
    /// A wrapper function for the FeatureTelemetry.LogUptake() available from BC20
    /// </summary>
    /// <param name="_EventId">A unique ID of the event.</param>
    /// <param name="_FeatureName">The name of the feature.</param>
    internal procedure LogUptakeUndiscovered(_MobTelemetryEventId: Enum "MOB Telemetry Event ID")
    begin
        /* #if BC20+ */
        LogUptake(_MobTelemetryEventId, FeatureUptakeStatus::Undiscovered);
        /* #endif */
    end;

    [Obsolete('Only to be used by the Pack & Ship Migration Tool (planned for removal 12/2024)', 'MOB5.42')]
    procedure LogUptakeMigratedPackAndShip()
    begin
        /* #if BC20+ */
        LogUptakeDiscovered(MobTelemetryEventId::"Pack & Ship Feature (MOB1010)");
        LogUptakeSetup(MobTelemetryEventId::"Pack & Ship Feature (MOB1010)");
        /* #endif */
    end;

    /// <summary>
    /// Sends telemetry about feature usage.
    /// </summary>
    /// <param name="_MobTelemetryEventId">A unique ID of the event.</param>
    /// <param name="_EventName">The name of the event.</param>
    /// <param name="_CustomDimensions">A dictionary containing additional information about the event.</param>
    /// <remarks>Custom dimensions often contain infromation translated in different languages. It is a common practice to send telemetry in the default language (see example).</remarks>
    /// <example>
    /// TranslationHelper.SetGlobalLanguageToDefault();
    /// CustomDimensions.Add('JobQueueObjectType', Format(JobQueueEntry."Object Type to Run"));
    /// CustomDimensions.Add('JobQueueObjectId', Format(JobQueueEntry."Object ID to Run"));
    /// FeatureTelemetry.LogUsage('0000XYZ', 'Job Queue', 'Job executed', CustomDimensions);
    /// TranslationHelper.RestoreGlobalLanguage();
    /// </example>
    internal procedure LogUsage(_MobTelemetryEventId: Enum "MOB Telemetry Event ID"; _EventName: Text; _CustomDimensions: Dictionary of [Text, Text])
    /* #if BC20+ */
    var
        EventId: Text;
        FeatureName: Text;
    begin
        MobTelemetryMgt.GetEventIdAndFeatureName(_MobTelemetryEventId, EventId, FeatureName);
        FeatureTelemetry.LogUsage(EventId, FeatureName, _EventName, _CustomDimensions);
    end;
    /* #endif */
    /* #if BC19- ##
    begin
    end;
    /* #endif */

    internal procedure LogUsage(var _MobDocQueue: Record "MOB Document Queue")
    /* #if BC20+ */
    var
        CustomDimensions: Dictionary of [Text, Text];
        EventId: Text;
        FeatureName: Text;
    begin
        MobTelemetryMgt.AddGenericCustomDimensions(_MobDocQueue, CustomDimensions, true);
        MobTelemetryMgt.AddRequestDetailsCustomDimension(CustomDimensions);

        MobTelemetryMgt.GetEventIdAndFeatureName(MobTelemetryEventId::"MOB Request Processing (ok) (MOB2000)", EventId, FeatureName);
        FeatureTelemetry.LogUsage(EventId, FeatureName, MobTelemetryMgt.GetEventName(_MobDocQueue), CustomDimensions);
    end;
    /* #endif */
    /* #if BC19- ##
    begin
    end;
    /* #endif */

    /// <summary>
    /// Sends telemetry about errors happening during feature usage.
    /// </summary>
    /// <param name="_MobTelemetryEventId">A unique ID of the event.</param>
    /// <param name="_EventName">The name of the event.</param>
    /// <param name="_CustomDimensions">A dictionary containing additional information about the error.</param>
    /// <remarks>Custom dimensions often contain infromation translated in different languages. It is a common practice to send telemetry in the default language (see example).</remarks>
    /// <example>
    /// if not Success then begin
    ///     TranslationHelper.SetGlobalLanguageToDefault();
    ///     CustomDimensions.Add('UpdateEntity', Format(AzureADUserUpdateBuffer."Update Entity"));
    ///     FeatureTelemetry.LogError('0000XYZ', 'User management', 'Syncing users with M365', GetLastErrorText(true), GetLastErrorCallStack(), CustomDimensions);
    ///     TranslationHelper.RestoreGlobalLanguage();
    /// end;
    /// </example>

    internal procedure LogError(_MobTelemetryEventId: Enum "MOB Telemetry Event ID"; _EventName: Text; _ErrorText: Text; _CustomDimensions: Dictionary of [Text, Text])
    /* #if BC20+ */
    var
        EventId: Text;
        FeatureName: Text;
    begin
        MobTelemetryMgt.GetEventIdAndFeatureName(_MobTelemetryEventId, EventId, FeatureName);
        FeatureTelemetry.LogError(EventId, FeatureName, _EventName, _ErrorText, '', _CustomDimensions);
    end;
    /* #endif */
    /* #if BC19- ##
    begin
    end;
    /* #endif */

    internal procedure LogError(var _MobDocQueue: Record "MOB Document Queue"; _ErrorText: Text)
    /* #if BC20+ */
    var
        MobSessionData: Codeunit "MOB SessionData";
        CustomDimensions: Dictionary of [Text, Text];
        EventId: Text;
        FeatureName: Text;
    begin
        MobTelemetryMgt.AddGenericCustomDimensions(_MobDocQueue, CustomDimensions, false);
        MobTelemetryMgt.AddRequestDetailsCustomDimension(CustomDimensions);

        if StrPos(_ErrorText, 'ForceWarning') = 1 then
            MobTelemetryMgt.GetEventIdAndFeatureName(MobTelemetryEventId::"MOB Request Processing (warning) (MOB2002)", EventId, FeatureName)
        else
            MobTelemetryMgt.GetEventIdAndFeatureName(MobTelemetryEventId::"MOB Request Processing (error) (MOB2001)", EventId, FeatureName);

        FeatureTelemetry.LogError(EventId, FeatureName, MobTelemetryMgt.GetEventName(_MobDocQueue), _ErrorText, MobSessionData.GetPreservedLastErrorCallStack(), CustomDimensions);
    end;
    /* #endif */
    /* #if BC19- ##
    begin
    end;
    /* #endif */

    // ********************************************************************************************************************
    // Code above is available internally for all versions, but might contain empty functions for BC19-
    // Code below is locally available for BC20+
    // ********************************************************************************************************************

    /* #if BC20+ */
    local procedure LogUptake(_MobTelemetryEventId: Enum "MOB Telemetry Event ID"; _FeatureUptakeStatus: Enum "Feature Uptake Status")
    var
        CustomDimensions: Dictionary of [Text, Text];
        EventId: Text;
        FeatureName: Text;
    begin
        // Use MOB Session Data single instance codeunit to prevent multiple identical "Used" signals for the same request
        if _FeatureUptakeStatus = _FeatureUptakeStatus::Used then begin
            if MobTelemetryMgt.GetFeatureTelemetryUsageLogged(_MobTelemetryEventId) then
                exit;
            MobTelemetryMgt.SetFeatureTelemetryUsageLogged(_MobTelemetryEventId);
        end;

        // Prepare and save telemetry
        MobTelemetryMgt.AddGenericCustomDimensions(CustomDimensions);
        MobTelemetryMgt.GetEventIdAndFeatureName(_MobTelemetryEventId, EventId, FeatureName);
        FeatureTelemetry.LogUptake(EventId, FeatureName, _FeatureUptakeStatus, false, CustomDimensions);
    end;
    /* #endif */
}
