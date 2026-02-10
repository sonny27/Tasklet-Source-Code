pageextension 81410 "MOB Warehouse Shipment" extends "Warehouse Shipment"
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
        addlast(Shipping)
        {
            group("MOB Shipping2")
            {
                Caption = 'Mobile WMS', Locked = true;
                Visible = PackAndShipEnabled;
                Enabled = PackAndShipEnabled;

                field("MOB Packing Station Code2"; Rec."MOB Packing Station Code")
                {
                    ApplicationArea = MOBWMSPackandShip;
                    ToolTip = 'Specifies the Packing Station as staging information';
                    Width = 20;
                    ColumnSpan = 10;
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
