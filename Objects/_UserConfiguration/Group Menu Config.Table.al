table 81273 "MOB Group Menu Config"
{
    Access = Public;
    Caption = 'Mobile Group Menu Config';
    LookupPageId = "MOB Group Menu Config";
    DrillDownPageId = "MOB Group Menu Config";

    fields
    {
        field(6181271; "Mobile Group"; Code[10])
        {
            Caption = 'Mobile Group';
            TableRelation = "MOB Group".Code;
            DataClassification = CustomerContent;
        }
        field(6181272; "Mobile Menu Option"; Text[100])
        {
            Caption = 'Mobile Menu Option';
            TableRelation = "MOB Menu Option"."Menu Option";
            DataClassification = CustomerContent;
        }
        field(6181273; Sorting; Integer)
        {
            Caption = 'Sorting';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(Key1; "Mobile Group", "Mobile Menu Option")
        {
        }
        key(Key2; Sorting)
        {
        }
    }
}
