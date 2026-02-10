table 82230 "MOB Package Type"
{
    Access = Public;
    Caption = 'Mobile Package Type';
    DataClassification = CustomerContent;
    DrillDownPageId = "MOB Package Type List";
    LookupPageId = "MOB Package Type List";

    fields
    {
        field(1; "Code"; Code[100])
        {
            Caption = 'Code';
            DataClassification = CustomerContent;
            NotBlank = true;
        }
        field(10; "Shipping Provider Id"; Code[20])
        {
            Caption = 'Shipping Provider Id';
            DataClassification = CustomerContent;
            NotBlank = true;
        }
        field(11; "Shipping Provider Package Type"; Code[50])
        {
            Caption = 'Shipping Provider Package Type';
            DataClassification = CustomerContent;
            NotBlank = true;
        }
        field(20; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
        }
        field(30; Unit; Text[20])
        {
            Caption = 'Unit';
            DataClassification = CustomerContent;
            // Note: No tablerelation for easier syncronizing (to be used as display-field only)
        }
        field(40; Default; Boolean)
        {
            Caption = 'Default';
            DataClassification = CustomerContent;
        }
        field(50; Width; Decimal)
        {
            Caption = 'Width';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(60; Length; Decimal)
        {
            Caption = 'Length';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(70; Height; Decimal)
        {
            Caption = 'Height';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(80; "Loading Meter"; Decimal)
        {
            Caption = 'Loading Meter (LDM)';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(90; Weight; Decimal)
        {
            Caption = 'Weight';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
    }
    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    begin
        if Rec.Code = '' then
            Rec.Code := Rec."Shipping Provider Id" + '-' + Rec."Shipping Provider Package Type";
    end;

    procedure GetShippingProviderId(): Code[20]
    begin
        exit(Rec."Shipping Provider Id");
    end;
}
