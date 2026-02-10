table 81305 "MOB WMS Sandbox Config. Guide"
{
    Caption = 'Mobile WMS Sandbox Configuration Guide', Locked = true;
    DataClassification = SystemMetadata;
    TableType = Temporary;
    Access = Internal;

    fields
    {
#pragma warning disable LC0013 // Ignore since this is a setup table
        field(1; "Primary Key"; Code[10])
#pragma warning restore LC0013
        {
            Caption = 'Primary Key', Locked = true;
        }
        field(10; "User ID"; Code[50])
        {
            Caption = 'User ID', Locked = true;
            TableRelation = User."User Name";
            ValidateTableRelation = false;
            trigger OnValidate()
            var
                UserSelection: Codeunit "User Selection";
            begin
                if Rec."User ID" <> '' then
                    UserSelection.ValidateUserName("User ID");
            end;
        }
        field(15; "Authentication Email"; Text[250])
        {
            Caption = 'Authentication Email', Locked = true;
        }
        field(20; "Default Location Code"; Code[10])
        {
            Caption = 'Default Location Code', Locked = true;
            TableRelation = Location;
        }
        field(30; "Application ID Text"; Text[38]) // Allow pasting guid with brackets but brackets will be removed when validated
        {
            Caption = 'Application (client) ID', Locked = true;
        }
        field(40; "Directory ID Text"; Text[38]) // Allow pasting guid with brackets but brackets will be removed when validated
        {
            Caption = 'Directory (tenant) ID', Locked = true;
        }
        field(50; "Save Microsoft Entra IDs"; Boolean)
        {
            Caption = 'Save Microsoft Entra IDs', Locked = true;
        }
        field(60; "SOAP URL"; Text[2048])
        {
            Caption = 'SOAP URL', Locked = true;
        }
    }
    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }
}
