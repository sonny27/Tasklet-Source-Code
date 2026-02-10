codeunit 81304 "MOB Report Print OnPostPickOrd"
{
    Access = Public;
    /// <summary>
    /// Handle "Print Shipment on Post" for Sales Shipment, Purchase Return Shipment and Transfer Shipment. 
    /// Printing for "Warehouse Shipment" and "Invt. Pick" are handled directly in WMS classes by SetPrint/PrintDocument standard methods.
    /// </summary>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Pick", 'OnPostPickOrder_OnAfterPostAnyOrder', '', false, false)]
    local procedure ReportPrint_OnPostPickOrder_OnAfterPostAnyOrder(var _RecRef: RecordRef)
    var
        MobReportPrintSetup: Record "MOB Report Print Setup";
    begin
        if not MobReportPrintSetup.PrintShipmentOnPostEnabled() then
            exit;

        case _RecRef.Number() of
            Database::"Sales Header":
                PrintSalesShipment(_RecRef);
            Database::"Purchase Header":
                PrintPurchaseReturnShipment(_RecRef);
            Database::"Transfer Header":
                PrintTransferShipment(_RecRef);
        end;
    end;

    local procedure PrintSalesShipment(var _RecRef: RecordRef)
    var
        SalesHeader: Record "Sales Header";
        SalesPostPrint: Codeunit "Sales-Post + Print";
    begin
        _RecRef.SetTable(SalesHeader);
        SalesPostPrint.GetReport(SalesHeader);
    end;

    local procedure PrintPurchaseReturnShipment(var _RecRef: RecordRef)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchPostPrint: Codeunit "Purch.-Post + Print";
    begin
        _RecRef.SetTable(PurchaseHeader);
        PurchPostPrint.GetReport(PurchaseHeader);
    end;

    local procedure PrintTransferShipment(var _RecRef: RecordRef)
    var
        TransferHeader: Record "Transfer Header";
        TransferOrderPostPrint: Codeunit "TransferOrder-Post + Print";
        TransferReportSelection: Option " ",Shipment,Receipt;
    begin
        _RecRef.SetTable(TransferHeader);
        TransferOrderPostPrint.PrintReport(TransferHeader, TransferReportSelection::Shipment);
    end;
}
