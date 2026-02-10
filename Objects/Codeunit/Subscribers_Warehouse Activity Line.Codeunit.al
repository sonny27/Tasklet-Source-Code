codeunit 81285 "MOB Tab5767 EXT.WhseActLine"
{
    Access = Public;
    [EventSubscriber(ObjectType::Table, Database::"Warehouse Activity Line", 'OnBeforeInsertNewWhseActivLine', '', true, true)]
    local procedure OnBeforeInsertNewWhseActivLine(var NewWarehouseActivityLine: Record "Warehouse Activity Line"; var WarehouseActivityLine: Record "Warehouse Activity Line")
    var
    begin
        // NewWarehouseActivityLine was copied from an existing line -- the MOBSystemID must be updated to be unique for the new line
        NewWarehouseActivityLine.MOBSystemId := CreateGuid();
    end;

}
