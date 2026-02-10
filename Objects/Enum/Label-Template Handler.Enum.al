enum 81350 "MOB Label-Template Handler"
{
    Extensible = true;

#pragma warning disable LC0045 // Null value is not expected
    value(0; None)
    {
        Caption = 'None';
    }
#pragma warning restore LC0045
    value(10; "Item Label")
    {
        Caption = 'Item Label';
    }
    value(20; "License Plate")
    {
        Caption = 'License Plate', Locked = true;
    }
    value(25; "License Plate Contents")
    {
        Caption = 'License Plate Contents';
    }
    value(30; "Sales Shipment")
    {
        Caption = 'Sales Shipment';
    }
    value(31; "Warehouse Shipment")
    {
        Caption = 'Warehouse Shipment';
    }
}
