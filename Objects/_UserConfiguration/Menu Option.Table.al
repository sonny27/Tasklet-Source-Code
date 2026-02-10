table 81272 "MOB Menu Option"
{
    Access = Public;
    Caption = 'Mobile Menu Options';
    LookupPageId = "MOB Menu Options";
    DrillDownPageId = "MOB Menu Options";

    fields
    {
        field(6181271; "Menu Option"; Text[100])
        {
            Caption = 'Menu Option';
            DataClassification = CustomerContent;
            NotBlank = true;
        }
    }

    keys
    {
        key(Key1; "Menu Option")
        {
        }
    }
}
