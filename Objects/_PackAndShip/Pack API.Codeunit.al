codeunit 82234 "MOB Pack API"
{
    Access = Public;
    var
        MobPackFeatureMgt: Codeunit "MOB Pack Feature Management";

    procedure SetupShippingProvider(_Id: Code[20]; _Description: Text[50])
    var
        MobShippingProvider: Record "MOB Shipping Provider";
    begin
        if not MobPackFeatureMgt.IsEnabled() then
            exit;

        MobShippingProvider.Init();
        MobShippingProvider.Validate(Id, _Id);
        MobShippingProvider.Validate(Description, _Description);
        MobShippingProvider.Insert();  // Intentionally fails if multiple registrants use same Id
    end;

    procedure SynchronizePackageTypes(_PackageType: Record "MOB Package Type")
    begin
        if not MobPackFeatureMgt.IsEnabled() then
            exit;

        _PackageType.SetFilter("Shipping Provider Id", '<>%1', '');
        OnSynchronizePackageTypes(_PackageType);
    end;

    internal procedure DiscoverShippingProviders()
    var
        MobShippingProvider: Record "MOB Shipping Provider";
        MobPackAPI: Codeunit "MOB Pack API";
    begin
        if not MobPackFeatureMgt.IsEnabled() then
            exit;

        MobShippingProvider.DeleteAll();
        MobPackAPI.OnDiscoverShippingProvider();
    end;

    // 'pack - ShipIT' and 'pack - LogTrade'
    procedure HasUntransferredLicensePlatesForWarehouseShipment(_WhseShipmentNo: Code[20]): Boolean
    var
        UntransferredLicensePlate: Record "MOB License Plate";
        MobWMSPackAdhocRegPostPck: Codeunit "MOB WMS Pack Adhoc Reg-PostPck";
    begin
        if _WhseShipmentNo = '' then
            exit(false);

        MobWMSPackAdhocRegPostPck.FilterUntransferredLicensePlatesForWarehouseShipment(_WhseShipmentNo, UntransferredLicensePlate);
        if UntransferredLicensePlate.IsEmpty() then
            exit(false)
        else
            exit(true);
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnDiscoverShippingProvider()
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnSynchronizePackageTypes(var _PackageType: Record "MOB Package Type")
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnSynchronizePackingStations(var _PackingStation: Record "MOB Packing Station")
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnBeforePostPacking(_RegistrationType: Text; _PackingStation: Record "MOB Packing Station"; var _RequestValues: Record "MOB NS Request Element")
    begin
        // Packing Station Information might be avaliable from 'PackingStation' Step
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnPostPackingOnCheckUntransferredLicensePlate(_LicensePlate: Record "MOB License Plate")
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnPostPackingOnAfterPostWarehouseShipment(var WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnPostPackingOnBeforePostWarehouseShipment(var WhseShptHeader: Record "Warehouse Shipment Header"; var WhseShptLine: Record "Warehouse Shipment Line")
    begin
    end;
}
