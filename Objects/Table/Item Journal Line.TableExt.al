tableextension 81305 "MOB Item Journal Line" extends "Item Journal Line"

// Tasklet Factory - Mobile WMS
// Added the field RegisteredOnMobile
// It shows if the counted value has been set from a mobile device

// Tasklet Factory - Mobile WMS
// Added key "Location Code","Bin Code","Item No.","Variant Code"
// It is used to sort the count order lines on the mobile device

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
    keys
    {
    }

    /// <summary>
    /// Set "Document No." using No. Series on Item Jnl. Batch or the generic "Handheld"  
    /// </summary>
    internal procedure "MOB GetDocumentNo"(_ModifySeries: Boolean)
    var
        ItemJournalBatch: Record "Item Journal Batch";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        MobNoSeries: Codeunit "MOB No. Series";
    begin
        if ItemJournalBatch.Get("Journal Template Name", "Journal Batch Name") and (ItemJournalBatch."No. Series" <> '') then
            "Document No." := MobNoSeries.GetNextNo(ItemJournalBatch."No. Series", "Posting Date", _ModifySeries)

        else
            "Document No." := MobWmsLanguage.GetMessage('HANDHELD'); // No. Series not found. Use generic number instead
    end;
}
