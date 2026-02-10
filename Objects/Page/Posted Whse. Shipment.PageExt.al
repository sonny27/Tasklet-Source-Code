pageextension 81411 "MOB Posted Whse. Shipment" extends "Posted Whse. Shipment"
{
    layout
    {
        addafter(Shipping)
        {
            group("MOB Packing")
            {
                Caption = 'Mobile License Plates';
                Visible = PackAndShipEnabled;
                Enabled = PackAndShipEnabled;

                part("MOB LicensePlateList"; "MOB License Plate List Part")
                {
                    SubPageLink = "Whse. Document Type" = const(Shipment), "Whse. Document No." = field("No."), "Top-level" = const(true);
                    ApplicationArea = MOBWMSPackandShip;
                    Editable = false;
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        PackFeatureMgt: Codeunit "MOB Pack Feature Management";
    begin
        PackAndShipEnabled := PackFeatureMgt.IsEnabled(true); // Shouldn't fail if user lacks permission to the MOB Setup table
    end;

    var
        PackAndShipEnabled: Boolean;
}
