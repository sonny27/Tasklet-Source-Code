tableextension 81494 "MOB Application Area Setup" extends "Application Area Setup"
{
    fields
    {
        // Spaces in field name are omitted in the ApplicationArea attribute        
        field(6182230; "MOB WMS Pack and Ship"; Boolean)
        {
            Caption = 'Mobile WMS - Pack & Ship', Locked = true;
            DataClassification = CustomerContent;
        }
    }
}
