page 82235 "MOB Packing Station List"
{
    Caption = 'Mobile Packing Stations';
    AdditionalSearchTerms = 'Mobile Packing Stations Tasklet Configuration Pack Ship', Locked = true;
    PageType = List;
    SourceTable = "MOB Packing Station";
    UsageCategory = Lists;
    ApplicationArea = MOBWMSPackandShip;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Code"; Rec.Code)
                {
                    ToolTip = 'Specifies the value of the Code field';
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
                {
                    ToolTip = 'Specifies the value of the Description field';
                    ApplicationArea = All;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ToolTip = 'Specifies the value of the Location Code field';
                    ApplicationArea = All;
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            group("&Synchronize")
            {
                Caption = '&Synchronize';
                action(SyncronizePackingStations)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Synchronize Packing Stations';
                    Enabled = true;
                    Image = OutlookSyncFields;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    ToolTip = 'Syncronize (read) Packing Stations from all Shipping Providers.';

                    trigger OnAction()
                    begin
                        SynchronizePackingStations();
                    end;
                }
            }
            group("&Print")
            {
                Caption = '&Print';
                action(ShowLabelTemplatesForPackingStation)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Printer Label Template setup';
                    Enabled = true;
                    Image = PrintCheck;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    ToolTip = 'Show Printer Label Template setup for Packing Station';
                    RunObject = page "MOB Printer Label-Templates";
                    RunPageLink = "Packing Station Code" = field(Code);
                }
            }
        }
    }

    /* #if BC14 ##
    trigger OnOpenPage()
    var
        PackFeatureMgt: Codeunit "MOB Pack Feature Management";
    begin
        if not PackFeatureMgt.IsEnabled() then
            Error('You must enable Pack & Ship in Mobile WMS Setup to use this Page');
    end;
    /* #endif */

    local procedure SynchronizePackingStations()
    var
        MobPackAPI: Codeunit "MOB Pack API";
    begin
        Rec.Reset();
        Rec.DeleteAll();

        MobPackAPI.OnSynchronizePackingStations(Rec);

        if GuiAllowed() then
            Message('Packing Stations has been synchonized.');
    end;

}
