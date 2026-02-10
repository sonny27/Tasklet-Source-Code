codeunit 82247 "MOB Internal ShippingProvider"
{
    Access = Public;
    //
    // Pack & Ship - ShippingProvider for blank Shipping Provider Id
    //

    /// <summary>
    /// Interface implementation: Unique Shipping Provider Id for this class (implementation)
    /// </summary>
    local procedure GetShippingProviderId(): Code[20]
    begin
        exit('');
    end;

    /// <summary>
    /// Interface implementation: Is the package type handled by the current Shipping Provider Id
    /// </summary>   
    local procedure IsShippingProvider(_PackageType: Code[20]): Boolean
    var
        MobPackageType: Record "MOB Package Type";
        MobPackageSetup: Record "MOB Mobile WMS Package Setup";
    begin
        if MobPackageType.Get(_PackageType) then
            exit(MobPackageType."Shipping Provider Id" = GetShippingProviderId());

        MobPackageSetup.Reset();
        exit(MobPackageSetup.IsEmpty());
    end;

    /// <summary>
    /// Interface implementation: Mark everyting handled by own logistics as "Transferred to Shipping" (prior to initial commit)
    /// </summary>
    /// <remarks>
    /// Redirected from standard event OnAfterCheckWhseShptLine to new local event for more accessible "interface" (all neccessary events in MOB Pack Register CU)
    /// </remarks>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB Pack API", 'OnPostPackingOnBeforePostWarehouseShipment', '', false, false)]
    local procedure OnPostPackingOnBeforePostWarehouseShipment(var WhseShptHeader: Record "Warehouse Shipment Header"; var WhseShptLine: Record "Warehouse Shipment Line")
    var
        UntransferredLicensePlates: Record "MOB License Plate";
        MobLicensePlate: Record "MOB License Plate";
        MosWmsPostAdhocRegPostPck: Codeunit "MOB WMS Pack Adhoc Reg-PostPck";
        MobPackFeatureMgt: Codeunit "MOB Pack Feature Management";
    begin
        if not MobPackFeatureMgt.IsEnabled() then
            exit;

        // Get Untransferred License Plates marked 'Ready for Shipping'
        MosWmsPostAdhocRegPostPck.FilterUntransferredLicensePlatesForWarehouseShipment(WhseShptHeader."No.", UntransferredLicensePlates);

        if UntransferredLicensePlates.FindSet(true) then
            repeat
                if IsShippingProvider(UntransferredLicensePlates."Package Type") then begin
                    MobLicensePlate.Get(UntransferredLicensePlates."No.");
                    MobLicensePlate.Validate("Transferred to Shipping", true); // Will update all child license plates as well
                    MobLicensePlate.Modify(true);
                end;
            until UntransferredLicensePlates.Next() = 0;
    end;
}
