enum 81365 "MOB FastForwardMode"
{
    Extensible = false;

    /// <summary>
    /// Fast forward is for automatically stepping over steps, if their value is already provided in either the input or scanned values.
    /// This setting determines which values can be used. Note: DefaultValue is never considered and has no effect.
    /// OnlyScanValues (Default): Only scanned barcode values are accepted for stepping over steps.
    /// </summary>
#pragma warning disable LC0045 // Null value is not expected
    value(0; OnlyScanValues) // Default
    {
        Caption = 'OnlyScanValues', Locked = true;
    }
#pragma warning restore LC0045

    /// <summary>
    /// Fast forward is for automatically stepping over steps, if their value is already provided in either the input or scanned values.
    /// This setting determines which values can be used. Note: DefaultValue is never considered and has no effect.
    /// Input values are header values (filters) or properties from the selected lookup or order line.
    /// InputAndScanValues: Both input and scanned values are accepted for stepping steps.
    /// </summary>  
    value(1; InputAndScanValues)
    {
        Caption = 'InputAndScanValues', Locked = true;
    }
}
