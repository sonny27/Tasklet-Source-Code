enum 81376 "MOB CancelBehaviour"
{
    Extensible = false;

    /// <summary>
    /// NOTE: Default value
    /// The registration collector closes on cancel.
    /// </summary>
#pragma warning disable LC0045 // Null value is not expected
    value(0; Close)
    {
        Caption = 'Close', Locked = true;
    }
#pragma warning restore LC0045

    /// <summary>
    /// Prompt the user whether to close the registration collector or not.
    /// </summary>  
    value(1; Warn)
    {
        Caption = 'Warn', Locked = true;
    }
}
