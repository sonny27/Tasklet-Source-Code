codeunit 81286 "MOB Tab7322 EXT.PostedWhseActH"
{
    Access = Public;
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Post Shipment", 'OnBeforePostedWhseShptHeaderInsert', '', true, true)]
    local procedure OnBeforePostedWhseShptHeaderInsert(WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var PostedWhseShipmentHeader: Record "Posted Whse. Shipment Header")
    begin
        // No TransferFields in standard code when Posted Whse. Shipment Header is created
        PostedWhseShipmentHeader."MOB MessageId" := WarehouseShipmentHeader."MOB Posting MessageId";
    end;

}
