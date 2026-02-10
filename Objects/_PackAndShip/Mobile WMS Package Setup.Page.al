page 82240 "MOB Mobile WMS Package Setup"
{
    Caption = 'Mobile Package Setup';
    AdditionalSearchTerms = 'Mobile Package Setup Tasklet Configuration Pack Ship', Locked = true;
    PageType = List;
    SourceTable = "MOB Mobile WMS Package Setup";
    UsageCategory = Lists;
    ApplicationArea = MOBWMSPackandShip;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Shipping Agent"; Rec."Shipping Agent")
                {
                    ToolTip = 'All shipments using this Shipping Agent and Service Code will have access to this Package Type. If the Shipping Agent Service Code field is left blank, the Package Type will be available for all Service Codes under the selected Shipping Agent.';
                    ApplicationArea = All;
                }
                field("Shipping Agent Service"; Rec."Shipping Agent Service Code")
                {
                    ToolTip = 'All shipments using this Shipping Agent and Service Code will have access to this Package Type. If the Shipping Agent Service Code field is left blank, the Package Type will be available for all Service Codes under the selected Shipping Agent.';
                    ApplicationArea = All;
                }
                field("Package Type"; Rec."Package Type")
                {
                    ToolTip = 'Specifies the value of the Package Type field';
                    ApplicationArea = All;
                }
                field("Default Package Type"; Rec."Default Package Type")
                {
                    ToolTip = 'Specifies the value of the Default Package Type field';
                    ApplicationArea = All;
                }
                field(RegisterLength; Rec."Register Length")
                {
                    ToolTip = 'Specifies the value of the Register Length field';
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        EnableDefaultLengthField := Rec."Register Length";
                    end;
                }
                field("Default Length"; Rec."Default Length")
                {
                    ToolTip = 'Specifies the value of the Default Length field';
                    ApplicationArea = All;
                    Enabled = EnableDefaultLengthField;
                }
                field(RegisterWidth; Rec."Register Width")
                {
                    ToolTip = 'Specifies the value of the Register Width field';
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        EnableDefaultWidthField := Rec."Register Width";
                    end;
                }
                field("Default Width"; Rec."Default Width")
                {
                    ToolTip = 'Specifies the value of the Default Width field';
                    ApplicationArea = All;
                    Enabled = EnableDefaultWidthField;
                }
                field(RegisterHeight; Rec."Register Height")
                {
                    ToolTip = 'Specifies the value of the Register Height field';
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        EnableDefaultHeightField := Rec."Register Height";
                    end;
                }
                field("Default Height"; Rec."Default Height")
                {
                    ToolTip = 'Specifies the value of the Default Height field';
                    ApplicationArea = All;
                    Enabled = EnableDefaultHeightField;
                }
                field(RegisterWeight; Rec."Register Weight")
                {
                    ToolTip = 'Specifies the value of the Register Weight field';
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        EnableDefaultWeightField := Rec."Register Weight";
                    end;
                }
                field("Default Weight"; Rec."Default Weight")
                {
                    ToolTip = 'Specifies the value of the Default Weight field';
                    ApplicationArea = All;
                    Enabled = EnableDefaultWeightField;
                }
                field("Register Loading Meter"; Rec."Register Loading Meter")
                {
                    ToolTip = 'Specifies the value of the Register Loading Meter (LDM) field';
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        EnableDefaultLoadingMeterField := Rec."Register Loading Meter";
                    end;
                }

                field("Default Loading Meter"; Rec."Default Loading Meter")
                {
                    ToolTip = 'Specifies the value of the Loading Meter (LDM) field';
                    ApplicationArea = All;
                    Enabled = EnableDefaultLoadingMeterField;
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            group(VerifySetup)
            {
                Caption = 'Verify Setup';
                action(VerifyPackageSetup)
                {
                    ApplicationArea = All;
                    Caption = 'Verify Package Setup';
                    Image = CheckDuplicates;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    ToolTip = 'Verify all Package Setup Records';

                    trigger OnAction()
                    begin
                        Rec.VerifySetup();
                    end;
                }
            }
        }
    }
    var
        EnableDefaultLengthField: Boolean;
        EnableDefaultWidthField: Boolean;
        EnableDefaultHeightField: Boolean;
        EnableDefaultWeightField: Boolean;
        EnableDefaultLoadingMeterField: Boolean;

    trigger OnOpenPage()
    var
        MobShippingProvider: Record "MOB Shipping Provider";
        MobPackAPI: Codeunit "MOB Pack API";
    begin
        /* #if BC14 ##
        if not PackFeatureMgt.IsEnabled() then
            Error('You must enable Pack & Ship in Mobile WMS Setup to use this Page');
        /* #endif */

        // Refresh Shipping Provider table prior to lookup
        MobShippingProvider.DeleteAll();
        MobPackAPI.OnDiscoverShippingProvider();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        EnableDefaultLengthField := Rec."Register Length";
        EnableDefaultWidthField := Rec."Register Width";
        EnableDefaultHeightField := Rec."Register Height";
        EnableDefaultWeightField := Rec."Register Weight";
        EnableDefaultLoadingMeterField := Rec."Register Loading Meter";
    end;

    var
    /* #if BC14 ##
    PackFeatureMgt: Codeunit "MOB Pack Feature Management";
    /* #endif */
}
