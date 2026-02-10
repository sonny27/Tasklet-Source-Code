page 82221 "MOB License Plate List Part"
{
    Caption = 'License Plates', Locked = true;
    PageType = ListPart;
    SourceTable = "MOB License Plate";
    CardPageId = "MOB License Plate";
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Package No. field.';
                }
                field("Package Type"; Rec."Package Type")
                {
                    ToolTip = 'Specifies the value of the Package Type field.';
                    ApplicationArea = All;
                }
                field("Top Level"; Rec."Top-level")
                {
                    ToolTip = 'Top-level means that this License Plate is not part of any other License Plate.';
                    ApplicationArea = All;
                    Visible = false;
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
                field("Location Code"; Rec."Location Code")
                {
                    ToolTip = 'Specifies the Location Code where the License Plate is currently located';
                    ApplicationArea = All;
                }
                field("Bin Code"; Rec."Bin Code")
                {
                    ToolTip = 'Specifies the Bin Code where the License Plate is currently located. One License Plate can only be located at one Bin but multiple License Plates can be located in the same Bin.';
                    ApplicationArea = All;
                }
            }
        }
    }
}
