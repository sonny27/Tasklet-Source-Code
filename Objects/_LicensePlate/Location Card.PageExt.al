pageextension 81271 "MOB Location Card" extends "Location Card"
{
    layout
    {
        addlast(content)
        {
            group("MOB License Plate")
            {
                Caption = 'Mobile WMS - License Plate';

                field("MOB Receive to LP"; Rec."MOB Receive to LP")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies if ''To License Plate'' must be selected when receiving items at this location.';
                    Editable = LicensePlatingEnabled;
                }
                field("MOB Pick From LP"; Rec."MOB Pick from LP")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies if ''From License Plate'' must be selected when picking items at this location.';
                    Editable = LicensePlatingEnabled;

                }
                field("MOB Prod. Output to LP"; Rec."MOB Prod. Output to LP")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies if ''To License Plate'' must be selected when posting production output at this location.';
                    Editable = LicensePlatingEnabled;
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        MobSetup: Record "MOB Setup";
    begin
        LicensePlatingEnabled := MobSetup.LicensePlatingIsEnabled();
    end;

    var
        LicensePlatingEnabled: Boolean;
}
