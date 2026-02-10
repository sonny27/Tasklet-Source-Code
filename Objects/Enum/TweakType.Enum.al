enum 81363 "MOB TweakType"
{
    Extensible = false;

    /// <summary>
    /// No Tweak-attribute is added to Xml (tweak is not relevant for adhoc SetRegistrationCollector but only for planned Workflows).
    /// Steps are replacing the entire workflow from application.cfg for planned Document Types (this is default behavior from Android App when no tweak-attribute is stated).
    /// </summary>
    value(0; " ")
    {
        Caption = ' ', Locked = true;
    }
    /// <summary>
    /// Add Tweak="Append" attribute to planned Workflows. Steps are added to the current workflow from the application.cfg.
    /// Requires Android App 1.8 to be respected at the Mobile Device.
    /// </summary>  
    value(1; Append)
    {
        Caption = 'Append', Locked = true;
    }
    /// <summary>
    /// Add Tweak="Replace" planned Workflows. Steps are replacing the entire workflow from application.cfg.
    /// This is the default behaviour from Android App (same as when no tweak-attribute is in the Xml).
    /// </summary>  
    value(2; Replace)
    {
        Caption = 'Replace', Locked = true;
    }
}
