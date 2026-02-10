codeunit 81283 "MOB Print License Plate Label"
{
    Access = Public;
    //
    // Ad-hoc Print specific report or template using either Report Print or Cloud Print
    //

    var
        NoToLPValueFoundTxt: Label 'You must select a ''To-License Plate'' before you can print a specific License Plate label.', Locked = true;
        PleaseSetupPrintErr: Label 'Printing is not enabled. Please set up either Report Print or Cloud Print.', Locked = true;

    internal procedure AddSteps(var _RequestValues: Record "MOB NS Request Element"; var _Steps: Record "MOB Steps Element")
    var
        MobPrintSetup: Record "MOB Print Setup";
        MobReportPrintManagement: Codeunit "MOB Report Print Management";
        MobFeatureTelemetryWrapper: Codeunit "MOB Feature Telemetry Wrapper";
        MobTelemetryEventId: Enum "MOB Telemetry Event ID";
        ReportPrintEnabled: Boolean;
    begin
        // Check if step has already been collected, break to avoid adding the same new step indefinitely
        if _RequestValues.HasValue('NoOfCopies') then
            exit;

        // If no License Plate value found, show error message.
        if _RequestValues.Get_ToteID() = '' then
            if _RequestValues.Get_LicensePlate() = '' then
                Error(NoToLPValueFoundTxt);

        // Check if either Cloud Print or Report Print are enabled
        if not MobPrintSetup.Get() then
            MobPrintSetup.Init();

        ReportPrintEnabled := MobReportPrintManagement.IsEnabled();
        if (MobPrintSetup.Enabled = false) and (ReportPrintEnabled = false) then
            Error(PleaseSetupPrintErr);

        // First try to print using Report Print, if not availabe then try to print using Cloud Print
        if not PrintLicensePlateLabelUsingReportPrint(_RequestValues, _Steps) then
            PrintLicensePlateLabelUsingCloudPrint(_RequestValues, _Steps);

        // Logging uptake telemetry for used LP feature
        MobFeatureTelemetryWrapper.LogUptakeUsed(MobTelemetryEventId::"License Plating - Print LP Label in Receive (MOB1075)");
    end;

    /// <summary>
    /// Print a specific report using Report Print
    /// Will find and use the first enabled report with the request page handler 'License Plate Label'
    /// </summary>    
    local procedure PrintLicensePlateLabelUsingReportPrint(var _RequestValues: Record "MOB NS Request Element"; var _Steps: Record "MOB Steps Element"): Boolean
    var
        MobReport: Record "MOB Report";
        MobReportPrintSteps: Codeunit "MOB Report Print Lookup";
        MobReportPrintManagement: Codeunit "MOB Report Print Management";
    begin
        if not MobReportPrintManagement.IsEnabled() then
            exit(false);

        // Printer related steps
        MobReport.SetRange(Enabled, true);
        MobReport.SetRange("RequestPage Handler", MobReport."RequestPage Handler"::"License Plate Label");
        MobReport.FindFirst(); // The expected label'License Plate Label GS1 3x2' must be exist and enabled in "Report Print"

        // Add the standard steps for printing the report
        MobReportPrintSteps.CreateReportPrinterAndNoOfCopiesSteps(MobReport, _RequestValues, _Steps, 90, 100);

        // Add hidden steps used to transfer value for the pre-defined label
        _Steps.Create_TextStep(500, 'ReportDisplayName', '');
        _Steps.Set_defaultValue(MobReport."Display Name");
        _Steps.Set_visible(false);

        exit(true);
    end;

    /// <summary>
    /// Print a specific lable template using Cloud Print
    /// Will find and use the first enabled template with the handler 'License Plate'
    /// </summary>    
    local procedure PrintLicensePlateLabelUsingCloudPrint(var _RequestValues: Record "MOB NS Request Element"; var _Steps: Record "MOB Steps Element")
    var
        MobLabelTemplate: Record "MOB Label-Template";
        MobPrint: Codeunit "MOB Print";
    begin
        MobLabelTemplate.SetRange(Enabled, true);
        MobLabelTemplate.SetRange("Template Handler", MobLabelTemplate."Template Handler"::"License Plate");
        MobLabelTemplate.FindFirst(); // The expected label 'License Plate GS1 3x2' must be exist and enabled in "Cloud Print"

        // Add the standard steps for printing
        MobPrint.CreatePrinterAndNoOfCopiesSteps(MobLabelTemplate.Name, _RequestValues, _Steps);

        // Add hidden steps used to transfer value for the pre-defined label
        _Steps.Create_TextStep(500, 'LabelTemplate', '');
        _Steps.Set_defaultValue(MobLabelTemplate.Name);
        _Steps.Set_visible(false);
    end;
}
