table 81367 "MOB Print Log"
{
    Access = Public;

    Caption = 'Mobile Print Log';
    Description = 'Log of print requests from the mobile and the response received from print cloud service';
    LookupPageId = "MOB Print Log";
    DrillDownPageId = "MOB Print Log";
    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
            DataClassification = CustomerContent;
        }
        field(10; "Created Date/Time"; DateTime)
        {
            Caption = 'Created Date/Time';
            DataClassification = CustomerContent;
        }
        field(12; "Device ID"; Code[200])
        {
            Caption = 'Device ID';
            DataClassification = CustomerContent;
        }
        field(13; "Mobile User ID"; Code[50])
        {
            Caption = 'Mobile User ID';
            TableRelation = "MOB User";
            DataClassification = CustomerContent;
        }
        field(14; Description; Text[250])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
        }
        field(15; "Record ID"; RecordId)
        {
            Caption = 'Record ID';
            DataClassification = SystemMetadata;
        }
        field(16; "Message ID"; Code[100])
        {
            Caption = 'Message ID';
            TableRelation = "MOB Document Queue"."Message ID";
            DataClassification = CustomerContent;
        }
        field(19; "Label-Template Name"; Text[50])
        {
            Caption = 'Label-Template Name';
            DataClassification = CustomerContent;
            TableRelation = "MOB Label-Template".Name;
        }
        field(20; "Request DataSet"; Blob)
        {
            Caption = 'Request DataSet', Locked = true;
            Compressed = true;
            DataClassification = CustomerContent;
        }
        field(21; "Request Data"; Blob)
        {
            Caption = 'Request Data', Locked = true;
            Compressed = true;
            DataClassification = CustomerContent;
        }
        field(23; "Response Data"; Blob)
        {
            Caption = 'Response Data', Locked = true;
            Compressed = true;
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
        }
        key(Key2; "Message ID")
        {
        }
        key(Key3; "Record ID")
        {
        }
        key(Key4; "Created Date/Time")
        {
        }
    }

    fieldgroups
    {
    }

    var

    trigger OnInsert()
    begin
    end;

    trigger OnModify()
    begin
    end;

    internal procedure ShowRequestDataSet()
    var
        iStream: InStream;
        ToFile: Text;
    begin
        CalcFields("Request DataSet");
        if "Request DataSet".HasValue() then begin
            "Request DataSet".CreateInStream(iStream);
            ToFile := 'RequestDataSet.xml';
            DownloadFromStream(iStream, '', '', '', ToFile);
        end;
    end;

    internal procedure ShowRequestData()
    var
        iStream: InStream;
        ToFile: Text;
    begin
        CalcFields("Request Data");
        if "Request Data".HasValue() then begin
            "Request Data".CreateInStream(iStream);
            ToFile := 'RequestData.xml';
            DownloadFromStream(iStream, '', '', '', ToFile);
        end;
    end;

    internal procedure ShowResponseData()
    var
        iStream: InStream;
        ToFile: Text;
    begin
        CalcFields("Response Data");
        if "Response Data".HasValue() then begin
            "Response Data".CreateInStream(iStream);
            ToFile := 'ResponseData.xml';
            DownloadFromStream(iStream, '', '', '', ToFile);
        end;
    end;

    internal procedure GetRequestXMLAsText() ReturnXMLAsText: Text
    var
        MobToolbox: Codeunit "MOB Toolbox";
        IStream: InStream;
    begin
        Rec.CalcFields("Request Data");
        Rec."Request Data".CreateInStream(IStream, TextEncoding::UTF8);
        MobToolbox.TryReadXmlAsTextWithSeparator(IStream, MobToolbox.LFSeparator(), ReturnXMLAsText);
    end;
}
