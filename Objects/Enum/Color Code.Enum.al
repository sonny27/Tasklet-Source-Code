enum 81271 "MOB Color Code"
{
    Extensible = false;

    // Color codes are defined as HEX color codes, only use 6-digit HEX codes (e.g. #RRGGBB)

#pragma warning disable LC0045 // Null value is not expected
    value(0; Red)
    {
        Caption = '#E03C32', Locked = true;
    }
#pragma warning restore LC0045
    value(10; Green)
    {
        Caption = '#639754', Locked = true;
    }
    value(20; Blue)
    {
        Caption = '#5A7FA5', Locked = true;
    }
}
