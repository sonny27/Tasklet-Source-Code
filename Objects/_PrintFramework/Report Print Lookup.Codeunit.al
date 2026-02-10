codeunit 81307 "MOB Report Print Lookup"
{
    Access = Public;
    // LookupType "PrintLabelTemplate" for "Report Print" reports. 
    // Results will be combined with "Label Templates" from "Cloud Print" label templates in "MOB WMS Lookup"

    var
        MobToolbox: Codeunit "MOB Toolbox";
        MobLanguage: Codeunit "MOB WMS Language";
        MobReportPrintManagement: Codeunit "MOB Report Print Management";
        InternalErrorHeaderErr: Label 'Internal error', Locked = true;
        NoReqPageHandlerExistErr: Label 'No event subscriber found to create steps for requestpage handler "%1"', Locked = true;


    /// <summary>
    /// Identify required Steps for a Report
    /// </summary>
    internal procedure CreateStepsForReport(var _MobReport: Record "MOB Report"; var _RequestValues: Record "MOB NS Request Element"; _SourceRecRef: RecordRef; var _RequiredSteps: Record "MOB Steps Element") HasRequiredSteps: Boolean
    var
        IsHandled: Boolean;
    begin
        _RequiredSteps.DeleteAll();

        // The event publisher below triggers these procedures in MOB:
        //   "MOB ReqPage Handler Item Label".OnLookupOnPrintReport_OnAddStepsForReport()
        //   "MOB ReqPage Handler LP".OnLookupOnPrintReport_OnAddStepsForReport()
        //   "MOB ReqPage Hdl. LP Contents".OnLookupOnPrintReport_OnAddStepsForReport()
        //   "MOB ReqPage Handler None".OnLookupOnPrintReport_OnAddStepsForReport()
        IsHandled := false;
        _RequiredSteps.SetMustCallCreateNext(true);
        OnLookupOnPrintReport_OnAddStepsForReport(_MobReport, _RequestValues, _SourceRecRef, _RequiredSteps, IsHandled);
        _RequiredSteps.SetMustCallCreateNext(false);

        if not IsHandled then begin
            // Inform the user (hopefully the developer) about the missing requestpage handler
            _RequiredSteps.Create_InformationStep(10, 'NO_REQPAGE_HANDLER');
            _RequiredSteps.Set_header(InternalErrorHeaderErr);
            _RequiredSteps.Set_helpLabel(StrSubstNo(NoReqPageHandlerExistErr, _MobReport."RequestPage Handler"));

            // TODO: Add Telemetry?
        end;

        // Event to modify existing steps
        if _RequiredSteps.FindSet() then
            repeat
                OnLookupOnPrintReport_OnAfterAddStepForReport(_MobReport, _RequestValues, _SourceRecRef, _RequiredSteps);
            until _RequiredSteps.Next() = 0;

        exit(not _RequiredSteps.IsEmpty()); // No steps = Do not show report
    end;

    /// <summary>
    /// Set lookup display values of a Report
    /// </summary>
    internal procedure SetFromLookupReport(_MobReport: Record "MOB Report"; _SourceRecRef: RecordRef; var _LookupResponse: Record "MOB NS WhseInquery Element"; var _RequiredSteps: Record "MOB Steps Element")
    var
        TempAdditionalValues: Record "MOB NS BaseDataModel Element" temporary;
    begin
        // Display values
        _LookupResponse.Init();
        _LookupResponse.Set_Location('');
        _LookupResponse.Set_DisplayLine1(_MobReport."Display Name");
        _MobReport.CalcFields("Report Caption");
        _LookupResponse.Set_DisplayLine2(StrSubstNo('(%1)', _MobReport."Report Caption"));
        _LookupResponse.Set_ReferenceID(_MobReport);

        // Events to add and modify _RequiredSteps are being handled in MobPrint.GetStepsForTemplate()

        // Required steps for this Label
        if not _RequiredSteps.IsEmpty() then begin
            TempAdditionalValues.Create();
            TempAdditionalValues.SetValue('ReportDisplayName', _MobReport."Display Name");
            TempAdditionalValues.Save();
            _LookupResponse.SetRegistrationCollector(_RequiredSteps, TempAdditionalValues);
        end;

        // TODO: Add OnAfterSetFrom ?
    end;

    //
    // -------------------------------- GLOBAL FUNCTIONS TO CREATE STEPS --------------------------------
    //

    /// <summary>
    /// Add Printer-step (if more than one printer)  
    /// </summary>
    /// <param name="_MobReport">The Report being printed</param>
    /// <param name="_RequestValues">The temporary record with values from the request</param>
    /// <param name="_Steps">The temporary record with already inserted steps and where the new step should be added.</param>
    /// <param name="_PrinterStepNo">The StepNo for the Printer step.</param>
    procedure CreateReportPrinterStep(_MobReport: Record "MOB Report"; var _RequestValues: Record "MOB NS Request Element"; var _Steps: Record "MOB Steps Element"; _PrinterStepNo: Integer)
    begin
        CreateReportPrinterAndNoOfCopiesSteps(_MobReport, _RequestValues, _Steps, _PrinterStepNo, 0); // The 0 indicates no NoOfCopies step is to be made
    end;

    /// <summary>
    /// Add No. of Copies-step and Printer-step (if more than one printer)  
    /// If only one printer then show printer name as helpLabel 
    /// </summary>
    /// <param name="_MobReport">The Report being printed</param>
    /// <param name="_RequestValues">The temporary record with values from the request</param>
    /// <param name="_Steps">The temporary record with already inserted steps and where new steps should be added.</param>
    /// <param name="_PrinterStepNo">The StepNo for the Printer step.</param>
    /// <param name="_NoOfCopiesStepNo">The StepNo for the NoOfCopies step. Specify 0 if the step should not be created.</param>
    procedure CreateReportPrinterAndNoOfCopiesSteps(_MobReport: Record "MOB Report"; var _RequestValues: Record "MOB NS Request Element"; var _Steps: Record "MOB Steps Element"; _PrinterStepNo: Integer; _NoOfCopiesStepNo: Integer)
    var
        ExclusivePrinter: Text;
    begin
        // Create Printer step
        ExclusivePrinter := MobReportPrintManagement.GetExclusivePrinter(_MobReport."Display Name", _RequestValues);
        _Steps.Create_ListStep_ReportPrinter(_PrinterStepNo, _MobReport."Display Name", _RequestValues, false);
        if ExclusivePrinter <> '' then begin // Only one printer = Hide step and set default value
            _Steps.Set_defaultValue(ExclusivePrinter);
            _Steps.Set_visible(false);
        end;
        _Steps.Save();

        // Create NoOfCopies step
        if _NoOfCopiesStepNo <> 0 then begin
            _Steps.Create_IntegerStep_NoOfCopies(_NoOfCopiesStepNo, false);
            if ExclusivePrinter <> '' then // Only one printer = Show the printer name as helpLabel
                _Steps.Set_helpLabel(_Steps.Get_helpLabel() + MobToolbox.CRLFSeparator() + MobToolbox.CRLFSeparator() + MobLanguage.GetMessage('PRINTER') + ': ' + ExclusivePrinter);
            _Steps.Save();
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupOnPrintReport_OnAddStepsForReport(_MobReport: Record "MOB Report"; var _RequestValues: Record "MOB NS Request Element"; _SourceRecRef: RecordRef; var _Steps: Record "MOB Steps Element"; var _IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupOnPrintReport_OnAfterAddStepForReport(_MobReport: Record "MOB Report"; var _RequestValues: Record "MOB NS Request Element"; _SourceRecRef: RecordRef; var _Step: Record "MOB Steps Element")
    begin
    end;
}
