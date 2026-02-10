tableextension 81312 "MOB Bin Content" extends "Bin Content"

// Tasklet Factory - Mobile WMS
// Added procedure to set filter from Mob Wms Registration

{
    procedure MobSetTrackingFilterFromMobWmsRegistrationIfNotBlank(_FromMobWmsRegistration: Record "MOB WMS Registration")
    begin
        if _FromMobWmsRegistration.SerialNumber <> '' then
            Rec.SetRange("Serial No. Filter", _FromMobWmsRegistration.SerialNumber);
        if _FromMobWmsRegistration.LotNumber <> '' then
            Rec.SetRange("Lot No. Filter", _FromMobWmsRegistration.LotNumber);

        MobOnAfterSetTrackingFilterFromMobWmsRegistrationIfNotBlank(Rec, _FromMobWmsRegistration);
    end;

    procedure MobSetTrackingFilterFromEntrySummaryIfNotBlank(_FromEntrySummary: Record "Entry Summary")
    begin
        if _FromEntrySummary."Serial No." <> '' then
            Rec.SetRange("Serial No. Filter", _FromEntrySummary."Serial No.");
        if _FromEntrySummary."Lot No." <> '' then
            Rec.SetRange("Lot No. Filter", _FromEntrySummary."Lot No.");

        MobOnAfterSetTrackingFilterFromEntrySummaryIfNotBlank(Rec, _FromEntrySummary);
    end;

    [IntegrationEvent(false, false)]
    local procedure MobOnAfterSetTrackingFilterFromMobWmsRegistrationIfNotBlank(var _BinContent: Record "Bin Content"; _FromMobWmsRegistration: Record "MOB WMS Registration")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure MobOnAfterSetTrackingFilterFromEntrySummaryIfNotBlank(var _BinContent: Record "Bin Content"; _FromEntrySummary: Record "Entry Summary")
    begin
    end;
}
