enum 81280 "MOB License Plate Handling"
{
    Extensible = false;

#pragma warning disable LC0045 // Zero (0) Enum value should be reserved for Empty Value
    value(0; Disabled)
    {
        Caption = 'Disabled';
    }
#pragma warning restore LC0045
    value(5; Optional)
    {
        Caption = 'Optional';
    }
    value(10; Mandatory)
    {
        Caption = 'Mandatory';
    }
}
