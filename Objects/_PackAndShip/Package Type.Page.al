page 82230 "MOB Package Type"
{
    Caption = 'Mobile Package Type';
    Editable = true;
    PageType = Card;
    SourceTable = "MOB Package Type";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';
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
            }
            group(Attributes)
            {
                Caption = 'Attributes';
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

    /* #if BC14 ##
    trigger OnOpenPage()
    var
        PackFeatureMgt: Codeunit "MOB Pack Feature Management";
    begin
        if not PackFeatureMgt.IsEnabled() then
            Error('You must enable Pack & Ship in Mobile WMS Setup to use this Page');
    end;
    /* #endif */
}
