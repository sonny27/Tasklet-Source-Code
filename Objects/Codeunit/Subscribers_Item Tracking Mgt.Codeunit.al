codeunit 81287 "MOB Cod6500 EXT.ItemTrackingMa"
{
    Access = Public;
    EventSubscriberInstance = Manual;

    /// <summary>
    /// Solve issue in "Item Tracking Management".SumUpItemTracking(): Would include tracking for other source document if multiple lines at same shipment has identical Item No's and Source Ref. No.s ("line" numbers)
    /// The standard SumUpItemTracking-method is written for i.e. Inventory Picks with only a single source document per pick.
    /// </summary>
    /// <remarks>
    /// This eventsubscriber is bound from "MOB Sync Item Tracking" during processing.
    /// </remarks>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Tracking Management", 'OnBeforeFindTempHandlingSpecification', '', true, true)]
    local procedure OnBeforeFindTempHandlingSpecification(var TempTrackingSpecification: Record "Tracking Specification"; ReservEntry: Record "Reservation Entry")
    begin
        if (TempTrackingSpecification.GetFilter("Source Ref. No.") <> '') then
            TempTrackingSpecification.SetRange("Source ID", ReservEntry."Source ID");
    end;

}
