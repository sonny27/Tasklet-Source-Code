enum 81362 "MOB ValueInteractionPermission"
{
    /// <summary>
    /// When utilizing lot- or serial number validation, a quantity can be returned, which will be used as the quantity going forward.
    /// Whether or not the user is allowed to edit the quantity can be set by the ValueInteractionPermission element.
    /// 
    /// ValueInteractionPermission can have three states:
    /// - AllowEdit - Allows the user to edit the value in the quantity step. User still sees quantity step
    /// - ApplyDirectly - Hides the quantity step altogether
    /// - VerifyOnly - "Disables" the quantity step. User still sees quantity step, but cannot edit it
    /// </summary>
    Extensible = false;

    /// <summary>
    /// Allows the user to edit the value in the quantity step.
    /// </summary>
#pragma warning disable LC0045 // Null value is not expected
    value(0; AllowEdit)
    {
        Caption = 'AllowEdit', Locked = true;
    }
#pragma warning restore LC0045
    /// <summary>
    /// Hides the quantity step all together.
    /// </summary>
    value(1; ApplyDirectly)
    {
        Caption = 'ApplyDirectly', Locked = true;
    }
    /// <summary>
    /// Disables the quantity step, allowing the user to see, but not edit it.
    /// </summary>
    value(2; VerifyOnly)
    {
        Caption = 'VerifyOnly', Locked = true;
    }
}
