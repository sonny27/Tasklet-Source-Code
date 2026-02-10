table 81373 "MOB Realtime Reg Qty."
{
    Access = Public;
    Caption = 'Register Realtime Quantity.';
    DataClassification = CustomerContent;
    DrillDownPageId = "MOB RealTime Reg Qty";
    LookupPageId = "MOB RealTime Reg Qty";

    fields
    {
#pragma warning disable LC0076 // The related field "MOB Device"."Device ID" is Code[200] but the "Device ID" length is never expected to be over 150
        field(1; "Device ID"; Code[150])
#pragma warning restore LC0076
        {
            Caption = 'Device ID';
            DataClassification = CustomerContent;
            TableRelation = "MOB Device";
            ValidateTableRelation = false;
        }
        field(2; Type; Code[20])
        {
            Caption = 'Type';
            DataClassification = CustomerContent;
        }
        field(3; "Order No."; Code[20])
        {
            Caption = 'Order No.';
            DataClassification = CustomerContent;

        }
        field(4; "Line No."; Code[20])
        {
            Caption = 'Line No.';
            DataClassification = CustomerContent;
        }
        field(5; "Registration No."; Integer)
        {
            AutoIncrement = true;
            Caption = 'Registration No.';
            DataClassification = CustomerContent;
        }
        field(6; FromBin; Code[20])
        {
            Caption = 'FromBin';
            DataClassification = CustomerContent;
        }
        field(7; ToBin; Code[20])
        {
            Caption = 'ToBin';
            DataClassification = CustomerContent;
        }
        field(8; SerialNumber; Code[70])
        {
            Caption = 'SerialNumber';
            DataClassification = CustomerContent;
            ObsoleteState = Pending;
            ObsoleteReason = 'Use "Serial No." and "Expiration Date" instead (planned for removal 03/2027)';
            ObsoleteTag = 'MOB5.58';
        }
        field(9; LotNumber; Code[70])
        {
            Caption = 'LotNumber';
            DataClassification = CustomerContent;
            ObsoleteState = Pending;
            ObsoleteReason = 'Use "Lot No." and "Expiration Date" instead (planned for removal 03/2027)';
            ObsoleteTag = 'MOB5.58';

        }
        field(10; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DataClassification = CustomerContent;
        }
        field(11; UnitOfMeasure; Code[10])
        {
            Caption = 'UnitOfMeasure';
            DataClassification = CustomerContent;
        }
        field(12; ActionType; Code[10])
        {
            Caption = 'ActionType';
            DataClassification = CustomerContent;
        }
        field(13; "Mobile User ID"; Text[65])
        {
            Caption = 'Mobile User ID';
            TableRelation = "MOB User";
            DataClassification = CustomerContent;
        }
        field(14; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            DataClassification = CustomerContent;
        }

        field(15; "Tote ID"; Code[100])
        {
            Caption = 'Tote ID';
            DataClassification = CustomerContent;
        }
        field(20; PackageNumber; Code[50])
        {
            Caption = 'PackageNumber';
            DataClassification = CustomerContent;
        }
        field(30; "Serial No."; Code[70])
        {
            Caption = 'Serial No.';
            DataClassification = CustomerContent;
        }
        field(31; "Lot No."; Code[70])
        {
            Caption = 'Lot No.';
            DataClassification = CustomerContent;
        }
        field(32; "Expiration Date"; Date)
        {
            Caption = 'Expiration Date';
            DataClassification = CustomerContent;
        }
        field(80; "Registration XML"; Blob)
        {
            Caption = 'Registration XML';
            DataClassification = CustomerContent;
            Compressed = false;
        }
    }

    keys
    {
        key(Key1; "Device ID", Type, "Order No.", "Line No.", "Registration No.")
        {
        }
    }

    fieldgroups
    {
    }
    var
        MobXmlMgt: Codeunit "MOB XML Management";
        MobToolbox: Codeunit "MOB Toolbox";
        GetValueNotFoundErr: Label 'Internal error: WMS RealtimeRegistration.GetValue(''%1'') not found.', Locked = true;

    // Get a single node value from the Registration XML (BLOB). The '//Registration/' part of XPath is implicit
    // Sample use: MyText := GetValue('MyCustomTag');
    procedure GetValue(_Path: Text[250]): Text
    begin
        exit(GetValue(_Path, false));
    end;

    procedure GetValue(_Path: Text; _ErrorIfNotExists: Boolean): Text
    var
        RegistationXmlDoc: XmlDocument;
        XPath: Text;
    begin
        // Support _Path being either a full path or relative to //Registration/ExtraInfo/
        if (CopyStr(_Path, 1, 2) = '//') then
            XPath := _Path
        else
            XPath := '//Registration/ExtraInfo/' + DelChr(_Path, '<', '/');

        if (GetRegistrationXmlAsXmlDoc(RegistationXmlDoc)) then
            if MobXmlMgt.XPathFound(RegistationXmlDoc, XPath) then
                exit(MobXmlMgt.XPathInnerText(RegistationXmlDoc, XPath));

        if _ErrorIfNotExists then
            Error(GetValueNotFoundErr, _Path);
    end;

    // Get Registration XML (BLOB) as Text
    procedure GetRegistrationXmlAsText(): Text
    var
        InText: Text;
        iStream: InStream;
    begin
        CalcFields("Registration XML");
        if not "Registration XML".HasValue() then
            exit('');

        "Registration XML".CreateInStream(iStream);
        iStream.Read(InText);
        exit(InText);
    end;

    // Get field "Registration XML" as XMLDoc
    local procedure GetRegistrationXmlAsXmlDoc(var _XmlDoc: XmlDocument): Boolean
    var
        iStream: InStream;
        iText: Text;
    begin
        CalcFields("Registration XML");
        if "Registration XML".HasValue() then begin
            "Registration XML".CreateInStream(iStream);
            iStream.Read(iText);
            exit(MobXmlMgt.DocReadText(_XmlDoc, iText));
        end;
    end;

    // Store Registration-node from PostRequest in Registration XML (BLOB)
    internal procedure SetRegistrationXml(var _RequestRegistrationXmlNode: XmlNode): Boolean
    var
        XmlDoc: XmlDocument;
        RootXmlElement: XmlElement;
        OutText: Text;
        oStream: OutStream;
    begin
        Clear("Registration XML");

        XmlDoc := XmlDocument.Create();
        XmlDoc.SetDeclaration(XmlDeclaration.Create('1.0', 'utf-8', 'yes'));
        RootXmlElement := XmlElement.Create('root');
        XmlDoc.Add(RootXmlElement);
        RootXmlElement.Add(_RequestRegistrationXmlNode);

        OutText := '<?xml version="1.0" encoding="utf-8" standalone="yes"?>' + MobToolbox.CRLFSeparator() + RootXmlElement.InnerXml();
        "Registration XML".CreateOutStream(oStream);
        oStream.Write(OutText);
        exit(true);
    end;
}
