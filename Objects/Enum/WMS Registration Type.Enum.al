enum 81277 "MOB WMS Registration Type"
{
    Extensible = true;
    /* #if BC16+ */
    AssignmentCompatibility = true;
    /* #endif */

#pragma warning disable LC0045 // Null value is not expected
    value(0; Receive)
    {
        Caption = 'Receive';
    }
#pragma warning restore LC0045
    value(1; PutAway)
    {
        Caption = 'Put-away';
    }
    value(2; Pick)
    {
        Caption = 'Pick';
    }
    value(3; Ship)
    {
        Caption = 'Ship';
    }
    value(4; "Count")
    {
        Caption = 'Count';
    }
    value(5; Move)
    {
        Caption = 'Move';
    }
    value(6; "Sales Order")
    {
        Caption = 'Sales Order';
    }
    value(7; "Purchase Order")
    {
        Caption = 'Purchase Order';
    }
    value(8; "Transfer Order")
    {
        Caption = 'Transfer Order';
    }
    value(9; "Sales Return Order")
    {
        Caption = 'Sales Return Order';
    }
    value(10; "Purchase Return Order")
    {
        Caption = 'Purchase Return Order';
    }
    value(11; CurrentRegistration)
    {
        Caption = 'Current Registration';
    }
    value(12; "Phys. Invt. Recording")
    {
        Caption = 'Phys. Invt. Recording';
    }
    value(13; "Production Consumption")
    {
        Caption = 'Production Consumption';
    }
    value(14; "Assembly Order")
    {
        Caption = 'Assembly Order';
    }
}
