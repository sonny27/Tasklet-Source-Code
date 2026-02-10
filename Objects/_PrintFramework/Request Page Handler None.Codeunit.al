codeunit 81312 "MOB ReqPage Handler None"
{
    Access = Public;
    var
        ReqPageHandlerNoneHeaderErr: Label 'Missing setup', Locked = true;
        ReqPageHandlerNoneErr: Label 'The %1 report has not been configured with a requestpage handler. Please set up a requestpage handler for the report.', Locked = true;

    // ----- STEPS ------ 

    /// <summary>
    /// The "None" requestpage handler indicates missing setup as a handler needs to be assigned
    /// </summary>    
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB Report Print Lookup", 'OnLookupOnPrintReport_OnAddStepsForReport', '', true, true)]
    local procedure OnLookupOnPrintReport_OnAddStepsForReport(_MobReport: Record "MOB Report"; var _RequestValues: Record "MOB NS Request Element"; _SourceRecRef: RecordRef; var _Steps: Record "MOB Steps Element"; var _IsHandled: Boolean)
    begin
        if _MobReport."RequestPage Handler" <> _MobReport."RequestPage Handler"::None then
            exit;

        // Inform the user about the missing setup
        _Steps.Create_InformationStep(10, 'REQPAGE_HANDLER_NONE');
        _Steps.Set_header(ReqPageHandlerNoneHeaderErr);
        _Steps.Set_helpLabel(StrSubstNo(ReqPageHandlerNoneErr, _MobReport."Display Name"));

        _IsHandled := true;
    end;

    // ----- REQUEST PAGE PARAMETERS ------ 

    /// <summary>
    /// The "None" requestpage handler indicates missing setup as a handler needs to be assigned
    /// </summary>    
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB ReportParameters Mgt.", 'OnCreateReportParameters', '', true, true)]
    local procedure OnCreateReportParameters(_MobReport: Record "MOB Report"; var _IsHandled: Boolean)
    begin
        if _MobReport."RequestPage Handler" <> _MobReport."RequestPage Handler"::None then
            exit;

        // Fail due to missing setup
        Error(ReqPageHandlerNoneErr, _MobReport."Display Name");
    end;
}
