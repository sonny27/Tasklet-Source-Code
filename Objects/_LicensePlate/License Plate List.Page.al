page 82220 "MOB License Plate List"
{
    Caption = 'Mobile License Plates';
    AdditionalSearchTerms = 'Mobile License Plates Tasklet LP Barcode Packing', Locked = true;
    PageType = List;
    SourceTable = "MOB License Plate";
    UsageCategory = Lists;
    ApplicationArea = All;
    CardPageId = "MOB License Plate";
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("No."; Rec."No.")
                {
                    ToolTip = 'Specifies the value of the No. field.';
                    ApplicationArea = All;
                }
                field("Package Type"; Rec."Package Type")
                {
                    ToolTip = 'Specifies the value of the "Package Type" field.';
                    ApplicationArea = All;
                }
                field("Top Level"; Rec."Top-level")
                {
                    ToolTip = 'Top-level means that this License Plate is not part of any other License Plate.';
                    ApplicationArea = All;
                }
                field("Content Exists"; Rec."Content Exists")
                {
                    ToolTip = 'Specifies if the License Plate has Content.';
                    ApplicationArea = All;
                }
                field("Gross Weight"; Rec.Weight)
                {
                    ToolTip = 'Specifies the value of the Weight field.';
                    ApplicationArea = All;
                }
                field("Whse. Document Type"; Rec."Whse. Document Type")
                {
                    ToolTip = 'Specifies the value of the "Whse. Document Type" field.';
                    ApplicationArea = All;
                }
                field("Whse. Document No."; Rec."Whse. Document No.")
                {
                    ToolTip = 'Specifies the value of the "Whse. Document Document No." field';
                    ApplicationArea = All;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ToolTip = 'Specifies the Location Code where the License Plate is currently located.';
                    ApplicationArea = All;
                }
                field("Bin Code"; Rec."Bin Code")
                {
                    ToolTip = 'Specifies the Bin Code where the License Plate is currently located. One License Plate can only be located at one Bin but multiple License Plates can be located in the same Bin.';
                    ApplicationArea = All;
                }
                field("Shipping Status"; Rec."Shipping Status")
                {
                    ToolTip = 'Specifies the Shipping Status.';
                    ApplicationArea = All;
                }
                field("Receipt Status"; Rec."Receipt Status")
                {
                    ToolTip = 'Specifies the Receipt Status.';
                    ApplicationArea = All;
                }
                field(Comment; Rec.Comment)
                {
                    ToolTip = 'Specifies a comment to mark or identify a License Plate.';
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action("Show Content")
            {
                Caption = 'Show Content';
                ToolTip = 'Shows License Plate Content.';
                ApplicationArea = All;
                Image = ProdBOMMatrixPerVersion;
                RunObject = page "MOB License Plate Content";
                RunPageMode = View;
                RunPageLink = "License Plate No." = field("No.");
            }
        }
        area(Processing)
        {
            action("Reset License Plate")
            {
                Caption = 'Reset License Plate';
                ToolTip = 'Reset License Plate values and delete content.';
                ApplicationArea = All;
                Image = ProdBOMMatrixPerVersion;

                trigger OnAction()
                begin
                    if GuiAllowed() then begin
                        if Confirm(ResetLicensePlateTxt, false) then
                            Rec.ResetLicensePlate();
                    end else
                        Rec.ResetLicensePlate();
                end;
            }
        }
        area(Reporting)
        {
            /* #if BC20+ */
            action(LicensePlateLabel)
            {
                Caption = 'License Plate Label';
                ToolTip = 'Print the License Plate Label';
                ApplicationArea = All;
                Image = "Report";

                trigger OnAction()
                var
                    LicensePlateLabel: Report "MOB License Plate Label";
                begin
                    LicensePlateLabel.SetLicensePlateNo(Rec."No.");
                    LicensePlateLabel.Run();
                end;
            }
            action(LicensePlateContensLabel)
            {
                Caption = 'License Plate Contents Label';
                ToolTip = 'Print the License Plate Contents Label';
                ApplicationArea = All;
                Image = "Report";

                trigger OnAction()
                var
                    MobLicensePlate: Record "MOB License Plate";
                begin
                    MobLicensePlate := Rec;
                    MobLicensePlate.SetRecFilter();
                    Report.Run(Report::"MOB LP Contents Label", true, false, MobLicensePlate);
                end;
            }
            /* #endif */
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

    var
        ResetLicensePlateTxt: Label 'Reset License Plate and delete all content?';
}
