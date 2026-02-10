page 81294 "MOB Report Printers"
{
    Caption = 'Mobile Printers', Locked = true, Comment = 'The list with Report Printers, but no need add the "Report" term as it only accesable via the Report Print Setup page';
    PageType = List;
    SourceTable = "MOB Report Printer";

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(Enabled; Rec.Enabled)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies if the printer is enabled. Disabling prevents the printer from being shown to mobile users.', Locked = true;
                }
                field("Printer Name"; Rec."Printer Name")
                {
                    ToolTip = 'Select the printer that should be available as a report printer for mobile devices.', Locked = true;
                    ApplicationArea = All;
                }
                field("Location Filter"; Rec."Location Filter")
                {
                    ToolTip = 'Enter a location filter if the printer should only be available for specific location(s) or leave blank to enable the printer for all locations.', Locked = true;
                    ApplicationArea = All;
                }
                field("Packing Station Filter"; Rec."Packing Station Filter")
                {
                    ToolTip = 'Enter a packing station filter if the printer should only be available for specific packing station(s) or leave blank to enable the printer for all packing stations.', Locked = true;
                    ApplicationArea = MOBWMSPackandShip;
                }
            }
        }
    }
    actions
    {
        area(Navigation)
        {
            action(Reports)
            {
                Caption = 'Reports', Locked = true;
                ToolTip = 'Set up reports available for the printer. If no printer are set up for a report then are all printers are available for the report. Therefore can a printer be available for more reports than it seems to be set up for.', Locked = true;
                ApplicationArea = All;
                Image = Print;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                RunObject = page "MOB Report Printer Reports";
                RunPageLink = "Printer Name" = field("Printer Name");
            }
        }
    }
}
