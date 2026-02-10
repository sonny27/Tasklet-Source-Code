page 82217 "MOB License Plate"
{
    Caption = 'Mobile License Plate';
    PageType = Document;
    SourceTable = "MOB License Plate";
    Editable = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General', Locked = true;
                field("No."; Rec."No.")
                {
                    ToolTip = 'Specifies the value of the No. field.';
                    ApplicationArea = All;
                }
                field("Top-level"; Rec."Top-level")
                {
                    ToolTip = 'Specifies if the License Plate is a top-level license plate (not a content of other license plates).';
                    ApplicationArea = All;
                }
                field("Whse. Document Type"; Rec."Whse. Document Type")
                {
                    ToolTip = 'Specifies the value of the Whse. Document Type field.';
                    ApplicationArea = All;
                }
                field("Whse. Document No."; Rec."Whse. Document No.")
                {
                    ToolTip = 'Specifies the value of the Whse. Document No. field.';
                    ApplicationArea = All;
                }
                field("Receipt Status"; Rec."Receipt Status")
                {
                    ToolTip = 'Specifies the Receipt Status.';
                    ApplicationArea = All;
                    Visible = false;
                }

                field("Location Code"; Rec."Location Code")
                {
                    ToolTip = 'Specifies the Location Code where the License Plate is currently located.';
                    ApplicationArea = All;
                }
                field("Bin Code"; Rec."Bin Code")
                {
                    ToolTip = 'Specifies the Bin Code where the License Plate is currently located. One License Plate can only be located at one Bin but multiple License Plates can be located at the same Bin.';
                    ApplicationArea = All;
                }
                field(Comment; Rec.Comment)
                {
                    ToolTip = 'Specifies a comment to mark or identify a License Plate.';
                    ApplicationArea = All;
                }
            }
            group(LPContent)
            {
                Caption = 'Content';
                part(LicensePlateContent; "MOB License Plate Content")
                {
                    SubPageLink = "License Plate No." = field("No.");
                    ApplicationArea = All;
                }
            }
            group(Package)
            {
                Caption = 'Packing';
                field("Package Type"; Rec."Package Type")
                {
                    ToolTip = 'Specifies the value of the Package Type field.';
                    ApplicationArea = All;
                }
                field("Packing Station Code"; Rec."Packing Station Code")
                {
                    ToolTip = 'Specifies where the License Plate is currently staged. Can be collected during Warehouse Picks.';
                    ApplicationArea = All;
                }
                field("Staging Hint"; Rec."Staging Hint")
                {
                    ToolTip = 'Specifies where the License Plate is currently staged. Can be collected during Warehouse Picks.';
                    ApplicationArea = All;
                }
                field("Content Exists"; Rec."Content Exists")
                {
                    ToolTip = 'Specifies if the License Plate has Content.';
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Content Quantity(Base)"; Rec."Content Quantity (Base)")
                {
                    ToolTip = 'Specifies the value of the Content Quantity(Base) field.';
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Sub License Plate Qty."; Rec."Sub License Plate Qty.")
                {
                    ToolTip = 'Specifies the number of sub License Plates.';
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Transferred to Shipping Provdr"; Rec."Transferred to Shipping")
                {
                    ToolTip = 'Specifies if the License Plate has been transferred to Shipping.';
                    ApplicationArea = All;
                }
                field("Shipping Status"; Rec."Shipping Status")
                {
                    ToolTip = 'Specifies the Shipping Status.';
                    ApplicationArea = All;
                }
                field(Weight; Rec.Weight)
                {
                    ToolTip = 'Specifies the value of the Weight field.';
                    ApplicationArea = All;
                }
                field(Height; Rec.Height)
                {
                    ToolTip = 'Specifies the value of the Height field.';
                    ApplicationArea = All;
                }
                field(Width; Rec.Width)
                {
                    ToolTip = 'Specifies the value of the Width field.';
                    ApplicationArea = All;
                }
                field(Length; Rec.Length)
                {
                    ToolTip = 'Specifies the value of the Length field.';
                    ApplicationArea = All;
                }
                field("Loading Meter"; Rec."Loading Meter")
                {
                    ToolTip = 'Specifies the value of Loading Meter (LDM) field.';
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
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
                ToolTip = 'Print the License Plate Label.';
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
                ToolTip = 'Print the License Plate Contents Label.';
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
