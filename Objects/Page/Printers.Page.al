page 81363 "MOB Printers"
{
    PageType = List;
    Caption = 'Mobile Printers';
    UsageCategory = None;
    SourceTable = "MOB Printer";


    layout
    {
        area(Content)
        {
            repeater(Printers)
            {
                field(Enabled; Rec.Enabled)
                {
                    ToolTip = 'Enable or disable the printer.';
                    ApplicationArea = All;
                }
                field(Name; Rec.Name)
                {
                    ToolTip = 'Enter the name of the printer or its purpose.';
                    ApplicationArea = All;
                }
                field("Address (MAC/IP)"; Rec.Address)
                {
                    ToolTip = 'Enter an IP(xxx.xxx.xxx.xxx) or MAC address(00:00:00:00:00:00). Bluetooth connected devices identified via MAC-address. Network connected devices identified via IP-address.';
                    ApplicationArea = All;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ToolTip = 'Optional: If entered, printing will only be possible when this location is selected from mobile. ';
                    ApplicationArea = All;
                }
                field(DPI; Rec.DPI)
                {
                    ToolTip = '"Dots per inch" is output resolution of the printer.';
                    ApplicationArea = All;
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(Relations)
            {
                ApplicationArea = All;
                Caption = 'Assign Templates';
                ToolTip = 'Assign templates to this printer.';
                Image = Relationship;
                Promoted = true;
                PromotedIsBig = true;
                PromotedCategory = Process;
                RunObject = page "MOB Printer Label-Templates";
                RunPageLink = "Printer Name" = field(Name);
            }
        }
    }

    trigger OnOpenPage()
    var
        MobPrint: Codeunit "MOB Print";
    begin
        MobPrint.ErrorIfNoSetup();
    end;

}
