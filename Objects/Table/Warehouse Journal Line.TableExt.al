tableextension 81310 "MOB Warehouse Journal Line" extends "Warehouse Journal Line"


// Tasklet Factory - Mobile WMS
// Added the RegisteredOnMobile field
// This field is set when a counted quantity has been updated from the mobile device

{
    fields
    {
        field(6181271; MOBRegisteredOnMobile; Boolean)
        {
            Description = 'Mobile WMS';
            Caption = 'Registered On Mobile';
            DataClassification = CustomerContent;
        }
    }
    /// <summary>
    /// Set "Whse. Document No." using No. Series on Whse. Jnl. Batch or the generic "Handheld"  
    /// </summary>
    internal procedure "MOB GetWhseDocumentNo"(_ModifySeries: Boolean)
    var
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        MobNoSeries: Codeunit "MOB No. Series";
    begin
        if WarehouseJournalBatch.Get("Journal Template Name", "Journal Batch Name", "Location Code") and (WarehouseJournalBatch."No. Series" <> '') then
            "Whse. Document No." := MobNoSeries.GetNextNo(WarehouseJournalBatch."No. Series", "Registering Date", _ModifySeries)
        else
            "Whse. Document No." := MobWmsLanguage.GetMessage('HANDHELD'); // No. Series not found. Use generic number instead
    end;
}
