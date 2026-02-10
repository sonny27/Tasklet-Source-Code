page 82231 "MOB Package Type List"
{
    Caption = 'Mobile Package Types';
    AdditionalSearchTerms = 'Mobile Package Types Tasklet Configuration Pack Ship', Locked = true;
    CardPageId = "MOB Package Type";
    Editable = true;
    PageType = List;
    SourceTable = "MOB Package Type";
    UsageCategory = Lists;
    ApplicationArea = MOBWMSPackandShip;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Code"; Rec."Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a code for the Package Type. The code must be unique and may include a prefix for the Shipping Provider.';
                }
                field("Shipping Provider Id"; Rec."Shipping Provider Id")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a unique identifier for a shipping provider (provided by subscriber app during syncronization).';
                    Editable = false;
                }
                field("Shipping Provider Package Type"; Rec."Shipping Provider Package Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Package Type Code from the external system. The code is unique by Shipping Provider Id.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description for a Package Type.';
                }
                field(Unit; Rec.Unit)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the unit for the Package Type. This is a value from the Shipping Provider and may not match up with existing Unit of Measure Codes from Business Central.';
                }
                field(Default; Rec.Default)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies if this is the default package type for a Shipping Provider.';
                }
                field(Length; Rec.Length)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the default Length for the Package Type.';
                }
                field(Width; Rec.Width)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the default Width for the Package Type.';
                }
                field(Height; Rec.Height)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the default Height for the Package Type.';
                }
                field(Weight; Rec.Weight)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the default weight or maximum weight for a Package Type.';
                }
                field("Loading Meter"; Rec."Loading Meter")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the default Loading Meter (LDM) for a Package Type.';
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
                action(PackageSetup)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Package Setup';
                    ToolTip = 'Open the Package Setup Page';
                    Image = SetupLines;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    RunObject = page "MOB Mobile WMS Package Setup";
                }
                action(SyncronizePackageTypes)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Synchronize Package Types';
                    Enabled = true;
                    Image = OutlookSyncFields;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    ToolTip = 'Syncronize (read) Package Types from all Shipping Providers.';

                    trigger OnAction()
                    begin
                        SynchronizePackageTypes();

                        Commit(); //Commit synchronised data before Verify Setup

                        if Confirm(VerifyPackageSetupTxt) then
                            MobPackageSetup.VerifySetup();
                    end;
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

    local procedure SynchronizePackageTypes()
    var
        MobPackAPI: Codeunit "MOB Pack API";
    begin
        Rec.Reset();
        Rec.SetFilter("Shipping Provider Id", '<>%1', '');
        Rec.DeleteAll();

        MobPackAPI.OnSynchronizePackageTypes(Rec);

        Rec.Reset();
        Rec.SetFilter("Shipping Provider Id", '<>%1', '');

        if GuiAllowed() then
            if Rec.IsEmpty() then
                Message(NoPackageTypeToSyncTxt)
            else
                Message(PackageTypeSyncTxt);

        Rec.Reset();  // Remove Filters
    end;

    var
        MobPackageSetup: Record "MOB Mobile WMS Package Setup";
        PackageTypeSyncTxt: Label 'Package Types has been synchonized';
        NoPackageTypeToSyncTxt: Label 'No external Package Types found to synchonize';
        VerifyPackageSetupTxt: Label 'Do you want to verify the Package Setup now?';

}
