codeunit 81303 "MOB Base Event Subscribers"
{
    Access = Public;
    EventSubscriberInstance = Manual;

    /// <summary>
    /// Disables confirm dialog triggered Unplanned Move > "Warehouse Journal".Quantity > "Bin Content" > WMS Management
    /// when "Location"."Bin Capacity Policy"::"Allow More Than Max. Capacity".
    /// This feature became available for non-Directed in BC23
    /// </summary>
    /* #if BC19+ */
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"WMS Management", 'OnBeforeConfirmExceededCapacity', '', true, true)]
    local procedure OnBeforeConfirmExceededCapacity(var IsHandled: Boolean; BinCode: Code[20]; CheckFieldCaption: Text[100]; CheckTableCaption: Text[100]; ValueToPutAway: Decimal; ValueAvailable: Decimal)
    begin
        IsHandled := true;
    end;
    /* #endif */
}
