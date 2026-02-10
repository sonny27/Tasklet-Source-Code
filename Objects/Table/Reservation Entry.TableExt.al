tableextension 81307 "MOB Reservation Entry" extends "Reservation Entry"

// NAVW111.00,MOB7.10.4.00

// Tasklet Factory - Mobile WMS

// Enabled the keys on Serial Number and Lot Number.
// Added the "Prefixed Line No." field. This is used when the mobile application integrates directly to transfer orders
// that handle item tracking information.

{
    fields
    {
        field(6181271; MOBPrefixedLineNo; Text[50])
        {
            Description = 'Mobile WMS';
            Caption = 'Prefixed Line No.';
            DataClassification = CustomerContent;
        }
    }
    keys
    {
    }
}
