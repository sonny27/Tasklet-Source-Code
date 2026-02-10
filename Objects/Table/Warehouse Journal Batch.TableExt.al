tableextension 81309 "MOB Warehouse Journal Batch" extends "Warehouse Journal Batch"


// Tasklet Factory - Mobile WMS
// Added the Released To Mobile field
// It determines if the journal is visible on the mobile device


{
    fields
    {
        field(6181271; MOBReleasedToMobile; Boolean)
        {
            Description = 'Mobile WMS';
            Caption = 'Released To Mobile';
            DataClassification = CustomerContent;
        }
    }
}
