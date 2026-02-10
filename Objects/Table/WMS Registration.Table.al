table 81372 "MOB WMS Registration"
{
    Access = Public;
    Caption = 'Mobile WMS Registration';
    Description = 'Contains registrations received from the mobile devices';
    LookupPageId = "MOB WMS Registration List";
    DrillDownPageId = "MOB WMS Registration List";
    fields
    {
        field(1; Type; Enum "MOB WMS Registration Type")
        {
            Caption = 'Type';
            DataClassification = CustomerContent;
        }
        field(2; "Order No."; Code[20])
        {
            Caption = 'Order No.';
            DataClassification = CustomerContent;
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
            DataClassification = CustomerContent;
        }
        field(4; "Registration No."; Integer)
        {
            AutoIncrement = true;
            Caption = 'Registration No.';
            DataClassification = CustomerContent;
        }
        field(5; FromBin; Code[20])
        {
            Caption = 'FromBin';
            DataClassification = CustomerContent;
        }
        field(6; ToBin; Code[20])
        {
            Caption = 'ToBin';
            DataClassification = CustomerContent;
        }
        field(7; SerialNumber; Code[70])
        {
            Caption = 'SerialNumber';
            DataClassification = CustomerContent;
        }
        field(8; LotNumber; Code[70])
        {
            Caption = 'LotNumber';
            DataClassification = CustomerContent;
        }
        field(9; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DataClassification = CustomerContent;
        }
        field(10; UnitOfMeasure; Code[10])
        {
            Caption = 'UnitOfMeasure';
            DataClassification = CustomerContent;
        }
        field(11; Handled; Boolean)
        {
            Caption = 'Handled';
            DataClassification = CustomerContent;
        }
        field(12; ActionType; Code[10])
        {
            Caption = 'ActionType';
            DataClassification = CustomerContent;
        }
        field(13; "Tote ID"; Code[100])
        {
            Caption = 'Tote ID';
            DataClassification = CustomerContent;
        }
        field(14; "Whse. Document Type"; Option)
        {
            Caption = 'Whse. Document Type';
            OptionCaption = ' ,Receipt,Shipment,Internal Put-away,Internal Pick,Production,Movement Worksheet,,Assembly';
            OptionMembers = " ",Receipt,Shipment,"Internal Put-away","Internal Pick",Production,"Movement Worksheet",,Assembly;
            DataClassification = CustomerContent;
        }
        field(15; "Whse. Document No."; Code[20])
        {
            Caption = 'Whse. Document No.';
            DataClassification = CustomerContent;
        }
        field(16; "Whse. Document Line No."; Integer)
        {
            BlankZero = true;
            Caption = 'Whse. Document Line No.';
            DataClassification = CustomerContent;
        }
        field(17; "Tote Handled"; Boolean)
        {
            Caption = 'Tote Handled';
            DataClassification = CustomerContent;
        }
        field(18; "Source Type"; Integer)
        {
            Caption = 'Source Type';
            Editable = false;
            DataClassification = CustomerContent;
        }
        field(19; "Source No."; Code[20])
        {
            Caption = 'Source No.';
            Editable = false;
            DataClassification = CustomerContent;
        }
        field(20; "Destination Type"; Option)
        {
            Caption = 'Destination Type';
            Editable = false;
            OptionCaption = ' ,Customer,Vendor,Location,Item,Family,Sales Order';
            OptionMembers = " ",Customer,Vendor,Location,Item,Family,"Sales Order";
            DataClassification = CustomerContent;
        }
        field(21; "Destination No."; Code[20])
        {
            Caption = 'Destination No.';
            Editable = false;
            TableRelation = if ("Destination Type" = const(Vendor)) Vendor
            else
            if ("Destination Type" = const(Customer)) Customer
            else
            if ("Destination Type" = const(Location)) Location
            else
            if ("Destination Type" = const(Item)) Item
            else
            if ("Destination Type" = const(Family)) Family
            else
            if ("Destination Type" = const("Sales Order")) "Sales Header"."No." where("Document Type" = const(Order));
            DataClassification = CustomerContent;
        }
        field(22; "Whse. Shpmt. Exists"; Boolean)
        {
            CalcFormula = exist("Warehouse Shipment Line" where("No." = field("Whse. Document No."),
                                                                 "Line No." = field("Whse. Document Line No.")));
            Caption = 'Whse. Shpmt. Exists';
            FieldClass = FlowField;
            Editable = false;
        }
        field(23; "AtO Tracking Collected"; Boolean)
        {
            Caption = 'AtO Tracking Collected';
            DataClassification = CustomerContent;
        }
        field(25; "Source Line No."; Integer)
        {
            Caption = 'Source Line No.';
            Editable = false;
            DataClassification = CustomerContent;
        }
        field(26; "Source Document"; Option)
        {
            Caption = 'Source Document';
            Editable = false;
            OptionCaption = ' ,Sales Order,,,Sales Return Order,Purchase Order,,,Purchase Return Order,Inbound Transfer,Outbound Transfer,Prod. Consumption,Prod. Output,,,,,,Service Order,,Assembly Consumption,Assembly Order';
            OptionMembers = " ","Sales Order",,,"Sales Return Order","Purchase Order",,,"Purchase Return Order","Inbound Transfer","Outbound Transfer","Prod. Consumption","Prod. Output",,,,,,"Service Order",,"Assembly Consumption","Assembly Order";
            DataClassification = CustomerContent;
        }
        field(30; "Phys. Invt. Recording No."; Integer)
        {
            Caption = 'Phys. Invt. Recording No.';
            DataClassification = CustomerContent;
            BlankZero = true;
        }
        field(35; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            DataClassification = CustomerContent;
        }
        field(37; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            DataClassification = CustomerContent;
        }
        field(39; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            DataClassification = CustomerContent;
        }
        field(40; "Whse. Jnl. Batch Location Code"; Code[10])
        {
            Caption = 'Whse. Jnl. Batch Location Code';
            DataClassification = CustomerContent;
        }
        field(50; "Prefixed Line No."; Text[50])
        {
            Caption = 'Prefixed Line No.';
            DataClassification = CustomerContent;
        }
        field(60; RegistrationCreated; DateTime)
        {
            Caption = 'Registration Created';
            DataClassification = CustomerContent;
        }
        field(65; LineSelectionValue; Code[20])
        {
            Caption = 'LineSelection Value';
            DataClassification = CustomerContent;
        }

        field(70; "Expiration Date"; Date)
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

        field(90; "Posting MessageId"; Guid)
        {
            Description = 'Mobile WMS';
            Caption = 'Posting MessageId';
            DataClassification = CustomerContent;
        }

        field(100; "Source MOBSystemId"; Guid)
        {
            Caption = 'Source MOBSystemId';
            DataClassification = CustomerContent;
        }

        field(110; "Prod. Order Line No."; Integer)
        {
            Caption = 'Prod. Order Line No.';
            DataClassification = CustomerContent;
        }

        field(120; ExtraInfo; Boolean)
        {
            Caption = 'ExtraInfo', Locked = true;
            DataClassification = CustomerContent;
        }

        field(130; PackageNumber; Code[50])
        {
            Caption = 'PackageNumber';
            DataClassification = CustomerContent;
        }

        field(180; "From License Plate No."; Code[20])
        {
            Caption = 'From License Plate No.';
            DataClassification = CustomerContent;
            TableRelation = "MOB License Plate";
            ValidateTableRelation = false;
        }
        field(190; "License Plate No."; Code[20])
        {
            Caption = 'To License Plate No.';
            DataClassification = CustomerContent;
            TableRelation = "MOB License Plate";
            ValidateTableRelation = false;
        }

        field(200; "Transferred to License Plate"; Boolean)
        {
            Caption = 'Transferred To LicensePlate';
            DataClassification = CustomerContent;
        }

        field(205; "Transferred From License Plate"; Boolean)
        {
            Caption = 'Transferred From LicensePlate';
            DataClassification = CustomerContent;
        }

    }

    keys
    {
        key(Key1; Type, "Order No.", "Line No.", "Registration No.")
        {
        }
        key(Key2; "Registration No.")
        {
        }
        key(Key3; FromBin)
        {
        }
        key(Key4; ToBin)
        {
        }
        key(Key5; "Tote ID", "Whse. Document Type", "Whse. Document No.", "Whse. Document Line No.")
        {
        }
        key(Key6; "Posting MessageId")
        {
        }
        key(Key7; "Whse. Document Type", "Whse. Document No.", "Whse. Document Line No.")
        {
        }
    }

    fieldgroups
    {
    }

    var
        MobToolbox: Codeunit "MOB Toolbox";
        GetValueNotFoundErr: Label 'Internal error: WMS Registration.GetValue(''%1'') not found.', Locked = true;

    trigger OnInsert()
    begin
        // autoincrement not supported at by Business Central 365 temporary tables in cloud hence implemented programmatically
        if IsTemporary() then
            AutoIncrementRegistrationNo();
    end;

    local procedure AutoIncrementRegistrationNo()
    var
        xMobWmsRegistration: Record "MOB WMS Registration";
        xView: Text;
        NextRegistrationNo: Integer;
    begin
        if Rec."Registration No." = 0 then begin
            xMobWmsRegistration := Rec;
            xView := Rec.GetView();

            Rec.SetCurrentKey("Registration No.");
            if Rec.FindLast() then
                NextRegistrationNo := Rec."Registration No." + 1
            else
                NextRegistrationNo := 1;

            Rec.SetView(xView);
            Rec := xMobWmsRegistration;
            Rec."Registration No." := NextRegistrationNo;
        end;
    end;

    procedure HasExtraInfo(): Boolean
    var
        MobXmlMgt: Codeunit "MOB XML Management";
        RegistationXmlDoc: XmlDocument;
        XPath: Text[1024];
    begin
        XPath := '//Registration/ExtraInfo';

        if (GetRegistrationXmlAsXmlDoc(RegistationXmlDoc)) then
            exit(MobXmlMgt.XPathFound(RegistationXmlDoc, XPath));
    end;

    // Get a single node value from the Registration XML (BLOB). The '//Registration/' part of XPath is implicit
    // Sample use: MyText := GetValue('MyCustomTag');
    procedure GetValue(_Path: Text[250]): Text
    begin
        exit(GetValue(_Path, false));
    end;

    procedure GetValue(_Path: Text[1024]; _ErrorIfNotExists: Boolean): Text
    var
        MobXmlMgt: Codeunit "MOB XML Management";
        RegistationXmlDoc: XmlDocument;
        XPath: Text[1024];
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

        exit('');
    end;

    procedure GetValueAsBoolean(_PathToGet: Text[250]; _ErrorIfNotExists: Boolean): Boolean
    begin
        exit(MobToolbox.Text2Boolean(GetValue(_PathToGet, _ErrorIfNotExists)));
    end;

    procedure GetValueAsBoolean(_PathToGet: Text[250]): Boolean
    begin
        exit(GetValueAsBoolean(_PathToGet, false));
    end;

    procedure GetValueAsDate(_PathToGet: Text[250]; _ErrorIfNotExists: Boolean): Date
    begin
        exit(MobToolbox.Text2Date(GetValue(_PathToGet, _ErrorIfNotExists)));
    end;

    procedure GetValueAsDate(_PathToGet: Text[250]): Date
    begin
        exit(GetValueAsDate(_PathToGet, false));
    end;

    procedure GetValueAsDateTime(_PathToGet: Text[250]; _ErrorIfNotExists: Boolean): DateTime
    begin
        exit(MobToolbox.Text2DateTime(GetValue(_PathToGet, _ErrorIfNotExists)));
    end;

    procedure GetValueAsDateTime(_PathToGet: Text[250]): DateTime
    begin
        exit(GetValueAsDateTime(_PathToGet, false));
    end;

    procedure GetValueAsInteger(_PathToGet: Text[250]; _ErrorIfNotExists: Boolean): Integer
    begin
        exit(MobToolbox.Text2Integer(GetValue(_PathToGet, _ErrorIfNotExists)));
    end;

    procedure GetValueAsInteger(_PathToGet: Text[250]): Integer
    begin
        exit(GetValueAsInteger(_PathToGet, false));
    end;

    procedure GetValueAsDecimal(_PathToGet: Text[250]; _ErrorIfNotExists: Boolean): Decimal
    begin
        exit(MobToolbox.Text2Decimal(GetValue(_PathToGet, _ErrorIfNotExists)));
    end;

    procedure GetValueAsDecimal(_PathToGet: Text[250]): Decimal
    begin
        exit(GetValueAsDecimal(_PathToGet, false));
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

    // Get Registration XML (BLOB) as new XmlDoc
    procedure GetRegistrationXmlAsXmlDoc(var _RegistrationXmlDoc: XmlDocument): Boolean
    var
        MobXmlMgt: Codeunit "MOB XML Management";
        InText: Text;
        iStream: InStream;
    begin
        Clear(_RegistrationXmlDoc);

        CalcFields("Registration XML");
        if "Registration XML".HasValue() then begin
            Clear(iStream);
            "Registration XML".CreateInStream(iStream);
            iStream.Read(InText);
            XmlDocument.ReadFrom(InText, _RegistrationXmlDoc);
        end;
        exit(not MobXmlMgt.DocIsNull(_RegistrationXmlDoc));
    end;

    // Store Registration-node from PostRequest in Registration XML (BLOB)
    procedure SetRegistrationXml(var _RequestRegistrationXmlNode: XmlNode): Boolean
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

    /// <remarks>
    /// PackageNumber and custom dimensions are supported via event
    /// </remarks>
    procedure TrackingExists() _IsTrackingExist: Boolean
    begin
        // Same conditions as ItemJnlLine.TrackingExists
        _IsTrackingExist := (LotNumber <> '') or (SerialNumber <> '');

        OnAfterTrackingExists(Rec, _IsTrackingExist);
    end;

    /// <remarks>
    /// PackageNumber and custom dimensions are supported via event
    /// </remarks>
    procedure SetTrackingFilterFromMobWmsRegistration(_FromMobWmsRegistration: Record "MOB WMS Registration")
    begin
        SetRange(SerialNumber, _FromMobWmsRegistration.SerialNumber);
        SetRange(LotNumber, _FromMobWmsRegistration.LotNumber);

        OnAfterSetTrackingFilterFromMobWmsRegistration(Rec, _FromMobWmsRegistration);
    end;

    /// <remarks>
    /// PackageNumber and custom dimensions are supported via event
    /// </remarks>
    procedure SetTrackingFilterFromEntrySummary(_FromEntrySummary: Record "Entry Summary")
    begin
        SetRange(SerialNumber, _FromEntrySummary."Serial No.");
        SetRange(LotNumber, _FromEntrySummary."Lot No.");

        OnAfterSetTrackingFilterFromEntrySummary(Rec, _FromEntrySummary);
    end;

    internal procedure GetLocationAndBinFromRelatedWhseDocLine(var _LocationCode: Code[10]; var _BinCode: Code[20])
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        case Rec."Whse. Document Type" of
            Rec."Whse. Document Type"::Receipt:
                begin
                    WarehouseReceiptLine.Get("Whse. Document No.", "Whse. Document Line No.");
                    _LocationCode := WarehouseReceiptLine."Location Code";
                    _BinCode := WarehouseReceiptLine."Bin Code";
                end;
            Rec."Whse. Document Type"::Shipment:
                begin
                    WarehouseShipmentLine.Get("Whse. Document No.", "Whse. Document Line No.");
                    _LocationCode := WarehouseShipmentLine."Location Code";
                    _BinCode := WarehouseShipmentLine."Bin Code";
                end;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTrackingExists(_MobWmsRegistration: Record "MOB WMS Registration"; var _IsTrackingExist: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromMobWmsRegistration(var _MobWmsRegistration: Record "MOB WMS Registration"; _FromMobWmsRegistration: Record "MOB WMS Registration")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromEntrySummary(var _MobWmsRegistration: Record "MOB WMS Registration"; _FromEntrySummary: Record "Entry Summary")
    begin
    end;
}

