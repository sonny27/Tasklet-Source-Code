tableextension 81271 "MOB Location" extends Location
{
    fields
    {
        field(6181280; "MOB Receive to LP"; Enum "MOB License Plate Handling")
        {
            Caption = 'Receive to License Plate';
            DataClassification = CustomerContent;
            InitValue = Disabled;
        }
        field(6181281; "MOB Pick from LP"; Enum "MOB License Plate Handling")
        {
            Caption = 'Pick from License Plate';
            DataClassification = CustomerContent;
            InitValue = Disabled;
        }
        field(6181282; "MOB Prod. Output to LP"; Enum "MOB License Plate Handling")
        {
            Caption = 'Prod. Output to License Plate';
            DataClassification = CustomerContent;
            InitValue = Disabled;
        }
    }
}
