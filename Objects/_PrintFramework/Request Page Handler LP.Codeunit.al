codeunit 81310 "MOB ReqPage Handler LP"
{
    Access = Public;
    /// <summary>
    /// RequestPage Handler for report 6181272 "MOB License Plate Label"
    /// </summary>

    // ----- STEPS -----

    /// <summary>
    /// Get the required steps for Item Reports
    /// </summary>    
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB Report Print Lookup", 'OnLookupOnPrintReport_OnAddStepsForReport', '', true, true)]
    local procedure OnLookupOnPrintReport_OnAddStepsForReport(_MobReport: Record "MOB Report"; var _RequestValues: Record "MOB NS Request Element"; _SourceRecRef: RecordRef; var _Steps: Record "MOB Steps Element"; var _IsHandled: Boolean)
    begin
        if _MobReport."RequestPage Handler" <> _MobReport."RequestPage Handler"::"License Plate Label" then
            exit;

        CreateSteps_FromRequestValues(_MobReport, _RequestValues, _Steps);

        // The requestpage is handled but might not always return any steps and should therefore maybe not be shown
        _IsHandled := true;
    end;

    /// <summary>
    /// Get the required steps for License Plate Report based on Value and ContextValue in RequestValues
    /// </summary>
    local procedure CreateSteps_FromRequestValues(_MobReport: Record "MOB Report"; var _RequestValues: Record "MOB NS Request Element"; var _RequiredSteps: Record "MOB Steps Element")
    var
        MobReportPrintSteps: Codeunit "MOB Report Print Lookup";
    begin
        // Add No. of Labels step if License Plate is <blank>
        if _RequestValues.GetValueOrContextValue('LicensePlate') = '' then
            _RequiredSteps.Create_IntegerStep_NoOfLabels(20);

        // Printer related steps
        MobReportPrintSteps.CreateReportPrinterAndNoOfCopiesSteps(_MobReport, _RequestValues, _RequiredSteps, 90, 100);
    end;

    // ----- REQUEST PAGE PARAMETERS -----

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB ReportParameters Mgt.", 'OnCreateReportParameters', '', true, true)]
    local procedure OnCreateReportParameters(_MobReport: Record "MOB Report"; _SourceRecRef: RecordRef; var _RequestValues: Record "MOB NS Request Element" temporary; var _OptionsFieldValues: Record "MOB ReportParameters Element"; var _DataItemViews: Record "MOB ReportParameters Element"; var _IsHandled: Boolean)
    var
        NoOfCopies: Integer;
    begin
        if _MobReport."RequestPage Handler" <> _MobReport."RequestPage Handler"::"License Plate Label" then
            exit;

        // Everything in the Parameter shall be formatted in XML format to support non-text fields in the request page
        // All options (with and without value) are transfered to ensure any personal saved values are overwritten

        // Request Page Control: No. of Copies
        NoOfCopies := _RequestValues.GetValueAsInteger('NoOfCopies');
        NoOfCopies := NoOfCopies - 1; // Handle difference in NoOfCopies logic in Step Element vs. Report.RequestPage
        _OptionsFieldValues.SetValue('NoOfCopiesReq', NoOfCopies);

        // Request Value License Plate No.                
        _OptionsFieldValues.SetValue('LicensePlateNoReq', _RequestValues.GetValue('LicensePlate'));

        // Request Value SourceReferenceID
        _OptionsFieldValues.SetValue('SourceReferenceIDReq', _RequestValues.GetValue('SourceReferenceID'));

        // Request Page Control: Quantity
        _OptionsFieldValues.SetValue('NoOfLabelsReq', _RequestValues.GetValueAsInteger('NoOfLabels'));

        _IsHandled := true; // Multiple subscribers can add to the parameters for the same requestpage handler - this just indicates at least one subscriber has handled this report
    end;
}
