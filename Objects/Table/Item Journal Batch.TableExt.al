tableextension 81306 "MOB Item Journal Batch" extends "Item Journal Batch"

// Tasklet Factory - Mobile WMS
// Added the ReleasedToMobile field
// It determines if the journal batch is available on the mobile devices

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
