table 81294 "MOB PrintNode LookupCapability"
{
    Access = Internal;
    Caption = 'Tasklet PrintNode Lookup Capability', Locked = true;
    LookupPageId = "MOB PrintNode LookupCapability";
    DrillDownPageId = "MOB PrintNode LookupCapability";

    fields
    {
        field(1; Type; Option)
        {
            Caption = 'Type', Locked = true;
            DataClassification = CustomerContent;
            OptionMembers = PaperSize,PaperTray;
        }
        field(2; Value; Text[250])
        {
            Caption = 'Value', Locked = true;
            DataClassification = CustomerContent;
        }
        field(10; "Paper Size Width"; Decimal)
        {
            Caption = 'Width (cm)', Locked = true;
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 2;
            BlankZero = true;
        }
        field(20; "Paper Size Height"; Decimal)
        {
            Caption = 'Height (cm)', Locked = true;
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 2;
            BlankZero = true;
        }
        /// <summary>
        /// The ID field is used as a parameter to the LoadCapabilities() function via the table relation
        /// </summary>
        field(100; "PrintNode Printer ID Filter"; Text[250])
        {
            Caption = 'PrintNode Printer ID Filter', Locked = true;
            FieldClass = FlowFilter;
        }
    }
    keys
    {
        key(PK; Type, Value)
        {
            Clustered = true;
        }
    }
    fieldgroups
    {
        fieldgroup(DropDown; Value)
        {
        }
    }
    internal procedure InsertPaperSize(_Name: Text; _Height: Decimal; _Width: Decimal)
    begin
        Rec.Init();
        Rec.Type := Rec.Type::PaperSize;
        Rec.Value := _Name;
        Rec."Paper Size Height" := _Height;
        Rec."Paper Size Width" := _Width;
        if Rec.Insert() then; // Names are not always unique in Windows printer drivers
    end;

    internal procedure InsertPaperTray(_Name: Text)
    begin
        Rec.Init();
        Rec.Type := Rec.Type::PaperTray;
        Rec.Value := _Name;
        if Rec.Insert() then; // Names are not always unique in Windows printer drivers
    end;

}
