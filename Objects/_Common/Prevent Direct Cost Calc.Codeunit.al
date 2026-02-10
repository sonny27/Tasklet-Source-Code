codeunit 81329 "MOB Prevent Direct Cost Calc"
{
    Access = Public;
    // This codeunit is used to prevent the direct unit cost calculation when over-receipt is updating the purchase line from a mobile device.
    // The problem happens because CurrFieldNo is always 0 from a mobile device and the calculation therefore not skipped as it would had been from a web client.
    // Over-receipt is available from BC16 and forward, so the code is only relevant for BC16 and forward.

    /* #if BC16+ */

    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", 'OnBeforeUpdateDirectUnitCost', '', false, false)]
    local procedure PreventPurchLineDirectCostCalc_OnBeforeUpdateDirectUnitCost(var PurchLine: Record "Purchase Line"; xPurchLine: Record "Purchase Line"; CalledByFieldNo: Integer; CurrFieldNo: Integer; var Handled: Boolean)
    begin
        // Standard code from the "Purchase Line" table: (This part of the code is identical in BC16 and BC23)

        // local procedure UpdateDirectUnitCostByField(...)
        // ...
        // OnBeforeUpdateDirectUnitCost(Rec, xRec, CalledByFieldNo, CurrFieldNo, IsHandled);
        // if IsHandled then
        //     exit;
        //
        // if (CurrFieldNo <> 0) and ("Prod. Order No." <> '') then
        //     UpdateAmounts;
        //
        // if ((CalledByFieldNo <> CurrFieldNo) and (CurrFieldNo <> 0)) or
        //    ("Prod. Order No." <> '')
        // then
        //     exit;
        // ...
        // <Calculation of direct unit cost>

        // The UpdateAmounts() needs to be executed to get the same logic as the standard code - see above
        if PurchLine."Prod. Order No." <> '' then
            PurchLine.UpdateAmounts();

        Handled := true;
    end;

    /* #endif */
}
