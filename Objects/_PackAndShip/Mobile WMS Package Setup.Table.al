table 82240 "MOB Mobile WMS Package Setup"
{
    Access = Public;
    Caption = 'Mobile Package Setup';
    DataClassification = CustomerContent;
    DrillDownPageId = "MOB Mobile WMS Package Setup";
    LookupPageId = "MOB Mobile WMS Package Setup";

    fields
    {
        field(1; "Shipping Agent"; Code[20])
        {
            Caption = 'Shipping Agent Code';
            DataClassification = CustomerContent;
            TableRelation = "Shipping Agent".Code;
        }
#pragma warning disable LC0076 // The related field "MOB Package Type".Code is Code[100] but the Package Type length is never expected to be over 50
        field(3; "Package Type"; Code[50])
#pragma warning restore LC0076
        {
            Caption = 'Package Type';
            DataClassification = CustomerContent;
            TableRelation = "MOB Package Type".Code;
            NotBlank = true;

            trigger OnValidate()
            var
                PackageType: Record "MOB Package Type";
            begin
                PackageType.SetRange(Code, "Package Type");
                if PackageType.FindFirst() then begin
                    Rec.Validate("Default Package Type", PackageType.Default);
                    Rec.Validate("Default Height", PackageType.Height);
                    Rec.Validate("Default Length", PackageType.Length);
                    Rec.Validate("Default Width", PackageType.Width);
                    Rec.Validate("Default Weight", PackageType.Weight);
                    Rec.Validate("Default Loading Meter", PackageType."Loading Meter");
                end;
            end;

            trigger OnLookup()
            var
                PackageType: Record "MOB Package Type";
            begin
                if Page.RunModal(0, PackageType) = Action::LookupOK then
                    Rec.Validate("Package Type", PackageType.Code);
            end;
        }
        field(5; "Shipping Agent Service Code"; Code[10])
        {
            Caption = 'Shipping Agent Service Code';
            TableRelation = "Shipping Agent Services".Code where("Shipping Agent Code" = field("Shipping Agent"));
        }
        field(11; "Default Package Type"; Boolean)
        {
            Caption = 'Default Package Type';
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                PackageSetup: Record "MOB Mobile WMS Package Setup";
            begin
                if Rec."Default Package Type" then begin
                    PackageSetup.SetRange("Shipping Agent", Rec."Shipping Agent");
                    PackageSetup.SetRange("Shipping Agent Service Code", Rec."Shipping Agent Service Code");
                    PackageSetup.SetFilter("Package Type", '<>%1', Rec."Package Type");
                    PackageSetup.ModifyAll("Default Package Type", false);
                end;
            end;
        }
        field(12; "Register Weight"; Boolean)
        {
            Caption = 'Register Weight';
            DataClassification = CustomerContent;
        }
        field(13; "Default Weight"; Decimal)
        {
            Caption = 'Default Weight';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }

        field(14; "Register Width"; Boolean)
        {
            Caption = 'Register Width';
            DataClassification = CustomerContent;
        }
        field(15; "Default Width"; Decimal)
        {
            Caption = 'Default Width';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(16; "Register Length"; Boolean)
        {
            Caption = 'Register Length';
            DataClassification = CustomerContent;
        }
        field(17; "Default Length"; Decimal)
        {
            Caption = 'Default Length';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(18; "Register Height"; Boolean)
        {
            Caption = 'Register Height';
            DataClassification = CustomerContent;
        }
        field(19; "Default Height"; Decimal)
        {
            Caption = 'Default Height';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(20; "Register Loading Meter"; Boolean)
        {
            Caption = 'Register Loading Meter (LDM)';
            DataClassification = CustomerContent;
        }

        field(21; "Default Loading Meter"; Decimal)
        {
            Caption = 'Default Loading Meter (LDM)';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }

    }

    keys
    {
        key(Key1; "Shipping Agent", "Package Type", "Shipping Agent Service Code")
        {
            Clustered = true;
        }
        key(Key2; "Shipping Agent", "Shipping Agent Service Code", "Package Type")
        {

        }
    }

    /// <summary>
    /// Verify the 3 primary key fields in Package Setup
    /// </summary>
    internal procedure VerifySetup()
    var
        MobileWMSPackageSetup: Record "MOB Mobile WMS Package Setup";
        TempMobileWMSPackageSetup: Record "MOB Mobile WMS Package Setup" temporary;
    begin
        if MobileWMSPackageSetup.FindSet() then
            repeat
                TempMobileWMSPackageSetup := MobileWMSPackageSetup;
                TempMobileWMSPackageSetup.TestField("Shipping Agent");
                TempMobileWMSPackageSetup.TestField("Package Type");
                TempMobileWMSPackageSetup.Validate("Shipping Agent");
                TempMobileWMSPackageSetup.Validate("Package Type");
                TempMobileWMSPackageSetup.Validate("Shipping Agent Service Code");
            until MobileWMSPackageSetup.Next() = 0;

        if GuiAllowed() then
            Message(PackageSetupOKTxt, Rec.TableCaption());
    end;

    var
        PackageSetupOKTxt: Label '%1 is OK', Comment = '%1 is Table Caption';
}
