table 82235 "MOB Packing Station"
{
    Access = Public;
    Caption = 'Mobile Packing Station';
    DataClassification = CustomerContent;
    DrillDownPageId = "MOB Packing Station List";
    LookupPageId = "MOB Packing Station List";

    fields
    {
        field(1; Code; Code[20])
        {
            Caption = 'Code';
            DataClassification = CustomerContent;
            NotBlank = true;
        }
        field(2; Description; Text[80])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
        }
        field(10; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            DataClassification = CustomerContent;
            TableRelation = Location;

            trigger OnValidate()
            var
                Location: Record Location;
            begin
                if Location.Get("Location Code") then
                    Location.TestField("Require Shipment");
            end;
        }
    }
    keys
    {
        key(PK; Code)
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    var
        MobPackingStation: Record "MOB Packing Station";
    begin
        // Find next avaliable Primary key Value
        if Code = '' then begin
            Rec.Code := '1';
            while MobPackingStation.Get(Rec.Code) do
                Rec.Code := IncStr(Code);
        end;
    end;
}
