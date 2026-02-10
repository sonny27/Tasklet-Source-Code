page 82218 "MOB License Plate Content"
{
    Caption = 'Mobile License Plate Contents';
    PageType = ListPart;
    SourceTable = "MOB License Plate Content";
    Editable = false;
    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("License Plate No."; Rec."License Plate No.")
                {
                    ToolTip = 'Specifies the value of the License Plate No. field';
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Line No."; Rec."Line No.")
                {
                    ToolTip = 'Specifies the value of the Line No. field';
                    ApplicationArea = All;
                    Visible = false;
                }
                field(Type; Rec.Type)
                {
                    ToolTip = 'Specifies the value of the Type field';
                    ApplicationArea = All;
                }
                field("No."; Rec."No.")
                {
                    ToolTip = 'Specifies the value of the No. field';
                    ApplicationArea = All;
                }
                field(VariantCode; Rec."Variant Code")
                {
                    ToolTip = 'Specifies the value of the Variant Code field';
                    ApplicationArea = All;
                    Visible = false;
                }
                field(Quantity; Rec.Quantity)
                {
                    ToolTip = 'Specifies the value of the Quantity field';
                    ApplicationArea = All;
                }
                field(UnitOfMeasure; Rec."Unit Of Measure Code")
                {
                    ToolTip = 'Specifies the value of the UnitOfMeasure field';
                    ApplicationArea = All;
                }
                field("Quantity (Base)"; Rec."Quantity (Base)")
                {
                    ToolTip = 'Specifies the value of the Quantity (Base) field';
                    ApplicationArea = All;
                }
                field(LotNumber; Rec."Lot No.")
                {
                    ToolTip = 'Specifies the value of the LotNumber field';
                    ApplicationArea = All;
                }
                field(SerialNumber; Rec."Serial No.")
                {
                    ToolTip = 'Specifies the value of the SerialNumber field';
                    ApplicationArea = All;
                }
                /* #if BC18+ */
                field("Package No."; Rec."Package No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Package No. field';
                    Visible = PackageVisible;
                }
                /* #endif */
                field("Whse. Document Type"; Rec."Whse. Document Type")
                {
                    ToolTip = 'Specifies the value of the "Whse. Document Type" field';
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Whse. Document No."; Rec."Whse. Document No.")
                {
                    ToolTip = 'Specifies the value of the "Whse. Document No." field';
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Whse. Document Line No."; Rec."Whse. Document Line No.")
                {
                    ToolTip = 'Specifies the value of the "Whse. Document Line No." field';
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Source Type"; Rec."Source Type")
                {
                    ToolTip = 'Specifies the value of the "Source Type" field';
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Source No."; Rec."Source No.")
                {
                    ToolTip = 'Specifies the value of the "Source No." field';
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Source Line No."; Rec."Source Line No.")
                {
                    ToolTip = 'Specifies the value of the "Source Line No." field';
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Source Document"; Rec."Source Document")
                {
                    ToolTip = 'Specifies the value of the "Source Document No." field';
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ToolTip = 'Specifies the Location Code where the License Plate is currently located.';
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Bin Code"; Rec."Bin Code")
                {
                    ToolTip = 'Specifies the Bin Code where the License Plate is currently located. One License Plate can only be located at one Bin but multiple License Plates can be located at the same Bin.';
                    ApplicationArea = All;
                    Visible = false;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        /* #if BC14 ##
        if not PackFeatureMgt.IsEnabled() then
            Error('You must enable Pack & Ship in Mobile WMS Setup to use this Page');
        /* #endif */

        /* #if BC18+ */
        SetPackageVisibility();
        /* #endif */
    end;


    var
        PackageVisible: Boolean;

    /* #if BC14 ##
    PackFeatureMgt: Codeunit "MOB Pack Feature Management";
    /* #endif */

    /* #if BC18+ */
    local procedure SetPackageVisibility()
    var
        MobPackageMgt: Codeunit "MOB Package Management";
    begin
        PackageVisible := MobPackageMgt.IsFeaturePackageMgtEnabled();
    end;
    /* #endif */
}
