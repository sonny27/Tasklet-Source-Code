enum 81375 "MOB ValidationWarningType"
{
    Extensible = false;

    /// <summary>
    /// NOTE: Default value
    /// Block user from entering a different value than the suggested value
    /// </summary>
#pragma warning disable LC0045 // Null value is not expected
    value(0; Block)
    {
        Caption = 'Block', Locked = true;
    }
#pragma warning restore LC0045

    /// <summary>
    /// Warn the user if an other value than the suggested is entered. Allowing the user to change it by accepting the prompt
    /// </summary>  
    value(1; Warn)
    {
        Caption = 'Warn', Locked = true;
    }

    /// <summary>
    /// Allow the user to enter a different value than the one suggested
    /// </summary>  
    value(2; None)
    {
        Caption = 'None', Locked = true;
    }
}
