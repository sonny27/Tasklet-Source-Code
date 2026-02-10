table 81295 "MOB Report Print Setup"
{
    Access = Public;

    Caption = 'Mobile Report Print Setup', Locked = true, Comment = 'Keep "Report Print" in English as a product name.';

    fields
    {
#pragma warning disable LC0013 // Ignore since this is a setup table
        field(1; "Primary Key"; Code[10])
#pragma warning restore LC0013
        {
            DataClassification = CustomerContent;
            Caption = 'Primary Key', Locked = true;
            Editable = false;
        }
        field(10; "Language Code"; Code[10])
        {
            DataClassification = CustomerContent;
            Caption = 'Language Code', Locked = true;
            TableRelation = "MOB Language";
        }
        field(20; "Print Shipment on Post"; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Print Shipment on Post', Locked = true;
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {

        }
    }

    /* #if BC20+ */
    /// <summary>
    /// Insert the layouts of the specified report as Mobile Reports - marking only the default layout as enabled
    /// </summary>
    /// <param name="_ReportId">The report to add</param>
    /// <param name="_RequestPageHander">The requestpage handler to assing the mobile reports</param>
    /// <returns>The number of inserted mobile reports</returns>
    procedure InsertLayoutsAsMobileReports(_ReportId: Integer; _RequestPageHander: Enum "MOB RequestPage Handler") AddedReports: Integer
    var
        MobReport: Record "MOB Report";
        ReportLayoutList: Record "Report Layout List";
        ReportMetadata: Record "Report Metadata";
    begin
        // Get Report Metadata to determine the default layout
        if not ReportMetadata.Get(_ReportId) then
            exit;

        // Loop the Layouts of the report
        ReportLayoutList.SetRange("Report ID", ReportMetadata.ID);
        ReportLayoutList.FindSet();
        repeat
            // Init report and assign simple values
            MobReport.Init();
            MobReport."Display Name" := CopyStr(ReportLayoutList.Caption, 1, MaxStrLen(MobReport."Display Name"));
            MobReport."Report ID" := ReportMetadata.ID;
            MobReport."RequestPage Handler" := _RequestPageHander;
            MobReport."Layout Name" := ReportLayoutList.Name;
            MobReport."Layout Application ID" := ReportLayoutList."Application ID";
            MobReport."Layout Publisher" := ReportLayoutList."Layout Publisher";
            MobReport.Enabled := ReportMetadata.DefaultLayoutName = CopyStr(ReportLayoutList.Name, 1, MaxStrLen(ReportMetadata.DefaultLayoutName));

            // Insert the report
            if MobReport.Insert() then
                AddedReports += 1;

        until ReportLayoutList.Next() = 0;
    end;

    internal procedure InsertAllMobileWmsReports()
    var
        AddedReports: Integer;
    begin
        AddedReports := InsertLayoutsAsMobileReports(Report::"MOB Item Label", Enum::"MOB RequestPage Handler"::"Item Label");
        AddedReports += InsertLayoutsAsMobileReports(Report::"MOB License Plate Label", Enum::"MOB RequestPage Handler"::"License Plate Label");
        AddedReports += InsertLayoutsAsMobileReports(Report::"MOB LP Contents Label", Enum::"MOB RequestPage Handler"::"License Plate Contents Label");

        Message(MobileWmwReportsAddedLbl, AddedReports);
    end;
    /* #endif */

    /* #if BC19- ##
    internal procedure InsertAllMobileWmsReports()
    begin
        Error('Mobile WMS reports are only available in BC 20 and later');
    end;
    /* #endif */

    internal procedure GetNoOfEnabledPrinters(): Integer
    var
        MobReportPrinter: Record "MOB Report Printer";
    begin
        MobReportPrinter.SetRange(Enabled, true);
        exit(MobReportPrinter.Count());
    end;

    internal procedure GetNoOfEnabledReports(): Integer
    var
        MobReport: Record "MOB Report";
    begin
        MobReport.SetRange(Enabled, true);
        exit(MobReport.Count());
    end;

    procedure PrintShipmentOnPostEnabled(): Boolean
    var
        MobReportPrintSetup: Record "MOB Report Print Setup";
    begin
        if not MobReportPrintSetup.Get() then
            exit(false);

        exit(MobReportPrintSetup."Print Shipment on Post");
    end;

    var
        MobileWmwReportsAddedLbl: Label '%1 Mobile WMS report(s) has been added.', Locked = true, Comment = '%1 = the number of reports added';
}
