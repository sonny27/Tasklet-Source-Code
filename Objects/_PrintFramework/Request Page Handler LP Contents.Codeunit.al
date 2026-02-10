codeunit 81311 "MOB ReqPage Hdl. LP Contents"
{
    Access = Public;
    /// <summary>
    /// RequestPage Handler for report 6181274 "MOB LP Contents Label"
    /// </summary>

    // ----- STEPS ----- 

    /// <summary>
    /// Get the required steps for Item Reports
    /// </summary>    
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB Report Print Lookup", 'OnLookupOnPrintReport_OnAddStepsForReport', '', true, true)]
    local procedure OnLookupOnPrintReport_OnAddStepsForReport(_MobReport: Record "MOB Report"; var _RequestValues: Record "MOB NS Request Element"; _SourceRecRef: RecordRef; var _Steps: Record "MOB Steps Element"; var _IsHandled: Boolean)
    begin
        if _MobReport."RequestPage Handler" <> _MobReport."RequestPage Handler"::"License Plate Contents Label" then
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
        MobToolbox: Codeunit "MOB Toolbox";
        LicensePlate: Text;
        ReferenceId: Text;
    begin
        ReferenceId := _RequestValues.Get_ReferenceID();
        LicensePlate := _RequestValues.GetValueOrContextValue('LicensePlate');

        // Number of Labels step        
        if (LicensePlate = '') and (ReferenceId = '') then begin
            _RequiredSteps.Create_TextStep(10, 'LicensePlate', 'LicensePlate');
            _RequiredSteps.Set_eanAi(MobToolbox.GetLicensePlateNoGS1Ai());
        end;

        // Printer related steps
        MobReportPrintSteps.CreateReportPrinterAndNoOfCopiesSteps(_MobReport, _RequestValues, _RequiredSteps, 90, 100);
    end;

    // ----- REQUEST PAGE PARAMETERS -----

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB ReportParameters Mgt.", 'OnCreateReportParameters', '', true, true)]
    local procedure OnCreateReportParameters(_MobReport: Record "MOB Report"; _SourceRecRef: RecordRef; var _RequestValues: Record "MOB NS Request Element" temporary; var _OptionsFieldValues: Record "MOB ReportParameters Element"; var _DataItemViews: Record "MOB ReportParameters Element"; var _IsHandled: Boolean)
    var
        MobLicensePlate: Record "MOB License Plate";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        NoOfCopies: Integer;
        LicensePlateNo: Code[20];
        LicensePlateFilter: Text;
    begin
        if _MobReport."RequestPage Handler" <> _MobReport."RequestPage Handler"::"License Plate Contents Label" then
            exit;

        // Everything in the Parameter shall be formatted in XML format to support non-text fields in the request page
        // All options (with and without value) are transfered to ensure any personal saved values are overwritten

        // Request Page Control: No. of Copies
        NoOfCopies := _RequestValues.GetValueAsInteger('NoOfCopies');
        NoOfCopies := NoOfCopies - 1; // Handle difference in NoOfCopies logic in Step Element vs. Report.RequestPage
        _OptionsFieldValues.SetValue('NoOfCopiesReq', NoOfCopies);

        // Request Value License Plate No.
        LicensePlateNo := _RequestValues.GetValue('LicensePlate');
        if LicensePlateNo <> '' then begin
            MobLicensePlate.SetRange("No.", LicensePlateNo);
            _DataItemViews.SetValue('MOB License Plate', MobLicensePlate.GetView(false));
        end else begin
            _SourceRecRef.SetTable(WarehouseShipmentHeader);
            MobLicensePlate.SetRange("Whse. Document Type", MobLicensePlate."Whse. Document Type"::Shipment);
            MobLicensePlate.SetRange("Whse. Document No.", WarehouseShipmentHeader."No.");
            MobLicensePlate.SetRange("Top-level", true);
            MobLicensePlate.FindSet();  // Intentionally unconditional FindSet(), ok to throw error if no License plates are found
            repeat
                LicensePlateFilter += MobLicensePlate."No." + '|';
            until MobLicensePlate.Next() = 0;

            // Remove the trailing '|' in the filter                
            LicensePlateFilter := DelStr(LicensePlateFilter, StrLen(LicensePlateFilter), 1);

            MobLicensePlate.Reset();
            MobLicensePlate.SetFilter("No.", LicensePlateFilter);
            _DataItemViews.SetValue('MOB License Plate', MobLicensePlate.GetView(false));
        end;

        _IsHandled := true; // Multiple subscribers can add to the parameters for the same requestpage handler - this just indicates at least one subscriber has handled this report
    end;
}
