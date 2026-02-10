codeunit 81306 "MOB Report Print Management"
{
    Access = Public;

    //
    // Functions for finding Report Printers and Reports
    //

    var
        ReportPrintPrefixErr: Label 'Report Print: %1', Locked = true;

    /// <summary>
    /// Is any Report Printer enabled?
    /// </summary>
    internal procedure IsEnabled(): Boolean
    var
        MobReportPrinter: Record "MOB Report Printer";
    begin
        /* #if BC16+ */
        MobReportPrinter.SetCurrentKey(Enabled);
        MobReportPrinter.SetRange(Enabled, true);
        exit(not MobReportPrinter.IsEmpty());
        /* #endif */

        // Report Print not available for BC15-
        /* #if BC15- ##
        exit(false);
        /* #endif */
    end;

    /// <summary>
    /// Return a list of relevant reports from a context (Location, Printer etc.)
    /// </summary>
    internal procedure GetReportsAllowedForRequest(var _RequestValues: Record "MOB NS Request Element"; var _TempMobReport: Record "MOB Report")
    var
        MobReport: Record "MOB Report";
        MobReportPrinterReport: Record "MOB Report Printer Report";
        MobReportPrinter: Record "MOB Report Printer";
        IsPrinterAllowed: Boolean;
    begin
        MobReport.SetCurrentKey(Enabled);
        MobReport.SetRange(Enabled, true);
        if MobReport.FindSet() then
            repeat
                MobReportPrinterReport.SetRange("Report Display Name", MobReport."Display Name");
                // Respect Printer assignments
                if MobReportPrinterReport.FindSet() then
                    repeat
                        IsPrinterAllowed := IsPrinterAllowedForRequest(MobReportPrinterReport."Printer Name", _RequestValues);
                        if IsPrinterAllowed then begin
                            _TempMobReport := MobReport;
                            _TempMobReport.Insert(false);
                        end;
                    until (MobReportPrinterReport.Next() = 0) or IsPrinterAllowed
                else begin

                    // Reports without assignments are available by default, but requires that an enabled printer(s) is allowed for the location
                    MobReportPrinter.SetCurrentKey(Enabled);
                    MobReportPrinter.SetRange(Enabled, true);
                    if MobReportPrinter.FindSet() then
                        repeat
                            IsPrinterAllowed := IsPrinterAllowedForRequest(MobReportPrinter."Printer Name", _RequestValues);
                            if IsPrinterAllowed then begin
                                _TempMobReport := MobReport;
                                _TempMobReport.Insert(false);
                            end;
                        until (MobReportPrinter.Next() = 0) or IsPrinterAllowed
                end;
            until MobReport.Next() = 0;
    end;

    /// <summary>
    /// If only one printer is available for a report, the name of that "exclusive" printer is returned
    /// </summary>
    internal procedure GetExclusivePrinter(_ReportDisplayName: Text[50]; var _RequestValues: Record "MOB NS Request Element"): Text[250]
    var
        MobLanguage: Codeunit "MOB WMS Language";
        MobilePrinterList: Text;
    begin
        MobilePrinterList := GetReportPrinterList(_ReportDisplayName, _RequestValues);

        if MobilePrinterList = '' then
            Error(ReportPrintPrefixErr, MobLanguage.GetMessage('NOPRINTERSETUP')); // No printer found

        if not MobilePrinterList.Contains(';') then
            exit(CopyStr(MobilePrinterList, 1, 250)); // Only one exclusive printer was found
    end;

    /// <summary>
    /// Get comma-separated list of mobile printers available to a report
    /// </summary>
    procedure GetReportPrinterList(_ReportDisplayName: Text[50]; var _RequestValues: Record "MOB NS Request Element") ReturnPrinterList: Text
    var
        MobReportPrinter: Record "MOB Report Printer";
    begin
        MobReportPrinter.SetCurrentKey(Enabled);
        MobReportPrinter.SetRange(Enabled, true);
        if MobReportPrinter.FindSet() then
            repeat
                if IsReportAvailableForPrinter(MobReportPrinter."Printer Name", _ReportDisplayName, _RequestValues) then
                    if ReturnPrinterList = '' then
                        ReturnPrinterList := MobReportPrinter."Printer Name"
                    else
                        ReturnPrinterList += ';' + MobReportPrinter."Printer Name";
            until MobReportPrinter.Next() = 0;
    end;

    /// <summary>
    /// Is printer enabled and allowed for a location 
    /// </summary>
    internal procedure IsPrinterAllowedForRequest(_PrinterName: Text[250]; var _RequestValues: Record "MOB NS Request Element"): Boolean
    var
        MobReportPrinter: Record "MOB Report Printer";
        TempLocation: Record Location temporary;
        TempMobPackingStation: Record "MOB Packing Station" temporary;
    begin
        // Check enabled
        if not (MobReportPrinter.Get(_PrinterName) and MobReportPrinter.Enabled) then
            exit(false);

        // Check location filter (if specified)
        if MobReportPrinter."Location Filter" <> '' then begin
            TempLocation.Code := _RequestValues.GetValueOrContextValue('Location');
            TempLocation.Insert(false);
            TempLocation.SetFilter(Code, MobReportPrinter."Location Filter");
            if TempLocation.IsEmpty() then
                exit(false);
        end;

        // Check packing station filter (if specified)
        if MobReportPrinter."Packing Station Filter" <> '' then begin
            // Insert a temporary record with the Packing Station Code from the RequestValues. Even if the code isn't specified, the filter will be respected
            TempMobPackingStation.Code := _RequestValues.GetValueOrContextValue('PackingStation'); // From the License Plate
            if TempMobPackingStation.Code = '' then
                TempMobPackingStation.Code := _RequestValues.GetValueOrContextValue('DefaultPackingStationCode'); // From the Warehouse Shipment Header
            TempMobPackingStation.Insert(false);
            TempMobPackingStation.SetFilter(Code, MobReportPrinter."Packing Station Filter");
            if TempMobPackingStation.IsEmpty() then
                exit(false);
        end;

        // All specified filters are respected and Printer is Ok to be used
        exit(true);
    end;

    /// <summary>
    /// Is any ReportPrinter setup available for a given PrinterName/ReportDisplayName combination, while also taking in account the Location and Packing Station from RequestValues
    /// </summary>
    /// <param name="_PrinterName">The PrinterName to seach for available PrinterReport setup for</param>
    /// <param name="_ReportDisplayName">The ReportDisplayName to search for available PrinterReport setup for</param>
    /// <param name="_RequestValues">The Location and Packing Station to match to the "ReportPrint Printer"</param>
    internal procedure IsReportAvailableForPrinter(_PrinterName: Text[250]; _ReportDisplayName: Text[50]; var _RequestValues: Record "MOB NS Request Element") ReturnIsAvailable: Boolean
    var
        MobReportPrinterReport: Record "MOB Report Printer Report";
    begin
        MobReportPrinterReport.SetRange("Report Display Name", _ReportDisplayName);

        if MobReportPrinterReport.IsEmpty() then
            ReturnIsAvailable := true // No Printer assignment = Report is available by default
        else
            ReturnIsAvailable := MobReportPrinterReport.Get(_PrinterName, _ReportDisplayName); // Check printer assignments

        if ReturnIsAvailable then // Check printer filters
            ReturnIsAvailable := IsPrinterAllowedForRequest(_PrinterName, _RequestValues);

        exit(ReturnIsAvailable);
    end;

    /* #if BC20+ */
    internal procedure EnableReportLayoutAndDisableOthers(_ReportId: Integer; _LayoutName: Text[250]; _RequestPageHandler: Enum "MOB RequestPage Handler")
    var
        MobReport: Record "MOB Report";
        ReportLayoutList: Record "Report Layout List";
        LayoutFound: Boolean;
        AppInfo: ModuleInfo;
        NewEnabledValue: Boolean;
    begin
        if MobReport.IsEmpty() then
            exit;

        NavApp.GetCurrentModuleInfo(AppInfo);

        // Disable all other layouts for the report than the specified layout
        MobReport.SetRange("Report ID", _ReportId);
        MobReport.SetRange("Layout Application ID", AppInfo.Id()); // Only consider layouts provided by Mobile WMS
        if MobReport.FindSet() then
            repeat

                // Determine if the layout should be enabled or disabled
                NewEnabledValue := MobReport."Layout Name" = _LayoutName;
                if MobReport.Enabled <> NewEnabledValue then begin
                    MobReport.Enabled := NewEnabledValue;
                    MobReport.Modify(true);
                end;

                if MobReport.Enabled then
                    LayoutFound := true;

            until MobReport.Next() = 0;

        // Insert the specified layout if it does not exist already
        if not LayoutFound then begin

            // Find the layout in the Report Layout List to get the layout caption (Layout name are not unique per report, but per report/app)
            ReportLayoutList.SetRange("Report ID", _ReportId);
            ReportLayoutList.SetRange(Name, _LayoutName);
            ReportLayoutList.SetRange("Application ID", AppInfo.Id());
            if ReportLayoutList.FindFirst() then begin

                // Insert the report
                MobReport.Init();
                MobReport."Display Name" := CopyStr(ReportLayoutList.Caption, 1, MaxStrLen(MobReport."Display Name"));
                MobReport."Report ID" := _ReportId;
                MobReport."RequestPage Handler" := _RequestPageHandler;
                MobReport.Enabled := true;
                MobReport."Layout Name" := _LayoutName;
                MobReport."Layout Application ID" := ReportLayoutList."Application ID";
                MobReport."Layout Publisher" := ReportLayoutList."Layout Publisher";
                MobReport.Insert(true);
            end;
        end;
    end;
    /* #endif */

    [IntegrationEvent(false, false)]
    internal procedure OnPostPrintReport_OnAfterGetMobReport(var _RequestValues: Record "MOB NS Request Element"; var _SourceRecRef: RecordRef; var _ReportPrinter: Text[250]; var _MobReport: Record "MOB Report")
    begin
    end;

}
