page 81297 "MOB Report Printer Reports"
{
    Caption = 'Mobile Printer Reports', Locked = true, Comment = 'The list with "Report Printer Reports", but no need for the first "Report" term as it only accesable via a "Report Print" page';
    PageType = List;
    SourceTable = "MOB Report Printer Report";
    DataCaptionFields = "Report Display Name", "Printer Name";

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Printer Name"; Rec."Printer Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Select a printer that should be available as a report printer for the specified report.', Locked = true;

                    Visible = not HidePrinter;
                }
                field("Report Display Name"; Rec."Report Display Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Select a report that should be available as a report for the specified printer.', Locked = true;
                    Visible = not HideReport;
                }
                field("Location Filter"; Rec."Location Filter")
                {
                    ApplicationArea = All;
                    ToolTip = 'Shows the location filter for the printer or blank if available for all locations.', Locked = true;
                    Visible = not HidePrinter;
                }
                field("Packing Station Filter"; Rec."Packing Station Filter")
                {
                    ApplicationArea = MOBWMSPackandShip;
                    ToolTip = 'Shows the packing station filter for the printer or blank if available for all packing stations.', Locked = true;
                    Visible = not HidePrinter;
                }
            }
        }
    }
    trigger OnOpenPage()
    begin
        /* #if BC15- ##
        Error('This Mobile WMS feature is only available in BC 16 and later');
        /* #endif */

        if Rec.GetFilter("Printer Name") <> '' then
            if Rec.GetRangeMin("Printer Name") = Rec.GetRangeMax("Printer Name") then
                HidePrinter := true;

        if Rec.GetFilter("Report Display Name") <> '' then
            if Rec.GetRangeMin("Report Display Name") = Rec.GetRangeMax("Report Display Name") then begin
                HideReport := true;
                Rec.SetCurrentKey("Report Display Name", "Printer Name");
                CurrPage.Caption := OppositePageCaptionLbl;
            end;
    end;

    var
        HidePrinter: Boolean;
        HideReport: Boolean;
        OppositePageCaptionLbl: Label 'Mobile Report Printers', Locked = true, Comment = 'The list with "Report Report Printers", but no need for the first "Report" term as it only accesable via a "Report Print" page';
}
