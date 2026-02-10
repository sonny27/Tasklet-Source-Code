codeunit 81355 "MOB Force Printer Selection"
{
    Access = Public;
    SingleInstance = true;

    var
        ForcedPrinterSelectionDict: Dictionary of [Integer, Text[250]];

    /// <summary>
    /// Check if a forced printer selection exists for the specific report ID - otherwise check if a forced printer selection exists for all reports (ReportID = 0)
    /// </summary>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::ReportManagement, 'OnAfterGetPrinterName', '', false, false)]
    local procedure GetForcedPrinterSelection_OnAfterGetPrinterName(ReportID: Integer; var PrinterName: Text[250])
    begin
        if ForcedPrinterSelectionDict.Count() = 0 then
            exit;

        if ForcedPrinterSelectionDict.ContainsKey(ReportID) then
            ForcedPrinterSelectionDict.Get(ReportID, PrinterName)
        else
            if ForcedPrinterSelectionDict.ContainsKey(0) then
                ForcedPrinterSelectionDict.Get(0, PrinterName);
    end;

    /// <summary>
    /// Sets the forced printer selection for a specific report or all reports.
    /// You can call the function multiple times to set different forced printer selections for different reports.
    /// The printername is stored in a single instance codeunit and used until cleared by calling Clear_ForcedPrinterSelection() or the session stops.
    /// </summary>
    /// <param name="_ReportID">Specifying a specific Report ID will ensure the printername is only forced for the specific report. Specifying 0 will force the printername to be used for all reports not having a specific forced printername</param>
    /// <param name="_PrinterName">The exact name of the printer to be used for the report(s)</param>
    procedure Set_ForcedPrinterSelectionForCurrentSession(_ReportID: Integer; _PrinterName: Text[250])
    begin
        if ForcedPrinterSelectionDict.ContainsKey(_ReportID) then
            ForcedPrinterSelectionDict.Set(_ReportID, _PrinterName)
        else
            ForcedPrinterSelectionDict.Add(_ReportID, _PrinterName);
    end;

    /// <summary>
    /// Clears the forced printer selection for all reports.
    /// </summary>
    procedure Clear_ForcedPrinterSelectionForCurrentSession()
    begin
        Clear(ForcedPrinterSelectionDict);
    end;
}
