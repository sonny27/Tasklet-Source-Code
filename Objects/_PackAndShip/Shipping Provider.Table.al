table 82245 "MOB Shipping Provider"
{
    Access = Public;
    Caption = 'Mobile Shipping Provider';
    DataClassification = CustomerContent;

    fields
    {
        field(1; Id; Code[20])
        {
            Caption = 'Id';
            DataClassification = CustomerContent;
            NotBlank = true;
        }
        field(10; Description; Text[50])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(Key1; Id)
        {
            Clustered = true;
        }
    }

}
