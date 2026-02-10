tableextension 81304 "MOB Item Ledger Entry" extends "Item Ledger Entry"

// Tasklet Factory - Mobile WMS
// Enabled the key on Serial No.

{
    fields
    {
        field(6181271; MOBRegisteredOnMobile; Boolean)
        {
            Description = 'Mobile WMS';
            Caption = 'Registered On Mobile';
            DataClassification = SystemMetadata;
        }
    }

    procedure MobSetTrackingFilterFromMobWmsRegistrationIfNotBlank(_FromMobWmsRegistration: Record "MOB WMS Registration")
    begin
        if _FromMobWmsRegistration.SerialNumber <> '' then
            Rec.SetRange("Serial No.", _FromMobWmsRegistration.SerialNumber);
        if _FromMobWmsRegistration.LotNumber <> '' then
            Rec.SetRange("Lot No.", _FromMobWmsRegistration.LotNumber);

        MobOnAfterSetTrackingFilterFromMobWmsRegistrationIfNotBlank(Rec, _FromMobWmsRegistration);
    end;

    procedure MobSetTrackingFilterFromEntrySummaryIfNotBlank(_FromEntrySummary: Record "Entry Summary")
    begin
        if _FromEntrySummary."Serial No." <> '' then
            Rec.SetRange("Serial No.", _FromEntrySummary."Serial No.");
        if _FromEntrySummary."Lot No." <> '' then
            Rec.SetRange("Lot No.", _FromEntrySummary."Lot No.");

        MobOnAfterSetTrackingFilterFromEntrySummaryIfNotBlank(Rec, _FromEntrySummary);
    end;

    [IntegrationEvent(false, false)]
    local procedure MobOnAfterSetTrackingFilterFromMobWmsRegistrationIfNotBlank(var _ItemLedgerEntry: Record "Item Ledger Entry"; _FromMobWmsRegistration: Record "MOB WMS Registration")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure MobOnAfterSetTrackingFilterFromEntrySummaryIfNotBlank(var _ItemLedgerEntry: Record "Item Ledger Entry"; _FromEntrySummary: Record "Entry Summary")
    begin
    end;
}
