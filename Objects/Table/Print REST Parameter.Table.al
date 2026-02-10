table 81366 "MOB Print REST Parameter"
{
    Access = Public;
    // Holds the data of an issued print to Print service web service. Including the result
    Caption = 'Mobile Print REST Parameter', Locked = true;
    fields
    {
        field(1; PrimaryKey; Integer)
        {
            Caption = 'PrimaryKey', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(10; RestMethod; Option)
        {
            Caption = 'RestMethod', Locked = true;
            OptionMembers = get,post,delete,patch,put;
            DataClassification = SystemMetadata;
        }
        field(12; URL; Text[250])
        {
            Caption = 'URL', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(14; Accept; Text[30])
        {
            Caption = 'Accept', Locked = true;
            DataClassification = SystemMetadata;
            ObsoleteState = Removed;
            ObsoleteReason = 'Not used in Mobile WMS';
            ObsoleteTag = 'MOB5.25';
        }
        field(16; ETag; Text[250])
        {
            Caption = 'Etag', Locked = true;
            DataClassification = SystemMetadata;
            ObsoleteState = Removed;
            ObsoleteReason = 'Not used in Mobile WMS';
            ObsoleteTag = 'MOB5.25';
        }
        field(17; Tenant; Text[50])
        {
            Caption = 'Tenant', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(18; UserName; Text[80])
        {
            Caption = 'Username', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(20; Password; Text[80])
        {
            Caption = 'Password', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(38; Printer; Text[80])
        {
            Caption = 'Label-Template Printer', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(40; "Label-Template Name"; Text[250])
        {
            Caption = 'Label-Template', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(80; "Message ID"; Code[100])
        {
            Caption = 'Message ID', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(82; "Device ID"; Code[200])
        {
            Caption = 'Device ID', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(90; Token; Blob)
        {
            Caption = 'Token', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(100; "Result Status"; Text[250])
        {
            Caption = 'Result Status', Locked = true;
            DataClassification = SystemMetadata;
            ObsoleteState = Removed;
            ObsoleteReason = 'Not used in Mobile WMS';
            ObsoleteTag = 'MOB5.25';
        }
        field(110; "Result Size"; Integer)
        {
            Caption = 'Result Size', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(120; "Result URL"; Text[250])
        {
            Caption = 'Result URL', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(130; "Result HttpStatusCode"; Integer)
        {
            Caption = 'Result HttpStatusCode', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(140; "Result IsSuccessStatusCode"; Boolean)
        {
            Caption = 'Result IsSuccessStatusCode', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(150; "Result IsBlockedByEnvironment"; Boolean)
        {
            Caption = 'Result IsBlockedByEnvironment', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(160; "Result ReasonPhrase"; Text[250])
        {
            Caption = 'Result ReasonPhrase', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(200; "Result ResponseContent"; Blob)
        {
            Caption = 'Result ResponseContent', Locked = true;
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; PrimaryKey)
        {
        }
    }
    var
        RequestContent: HttpContent;
        RequestContentSet: Boolean;
        ResponseHeaders: HttpHeaders;
        ResponseMessage: HttpResponseMessage;

    procedure SetRequestContent(var _Value: HttpContent)
    begin
        RequestContent := _Value;
        RequestContentSet := true;
    end;

    procedure HasRequestContent(): Boolean
    begin
        exit(RequestContentSet);
    end;

    procedure GetRequestContent(var _Value: HttpContent)
    begin
        _Value := RequestContent;
    end;

    procedure SetResponseContent(var _Value: HttpContent)
    var
        OutStr: OutStream;
        ResponseAsText: Text;
    begin
        _Value.ReadAs(ResponseAsText);

        "Result ResponseContent".CreateOutStream(OutStr);
        OutStr.Write(ResponseAsText);
    end;

    local procedure HasResponseContent(): Boolean
    begin
        exit("Result ResponseContent".HasValue());
    end;

    procedure GetResponseContentAsBase64Text(var _ReturnValue: Text)
    var
        MobBase64Convert: Codeunit "MOB Base64 Convert";
        InStr: InStream;
    begin
        if Tenant <> '' then
            // NG2: Response is already Base64
            _ReturnValue := GetResponseContentAsText(0)
        else begin
            // NG: Convert to Base64
            "Result ResponseContent".CreateInStream(InStr);
            _ReturnValue := MobBase64Convert.ToBase64(InStr);
        end;
    end;

    procedure GetResponseContentAsText(_CharToRead: Integer) ReturnValue: Text
    var
        InStr: InStream;
        Line: Text;
    begin
        if not HasResponseContent() then
            exit;

        "Result ResponseContent".CreateInStream(InStr);
        InStr.ReadText(ReturnValue);

        // Read some chars
        if _CharToRead > 0 then begin
            InStr.ReadText(Line, _CharToRead);
            ReturnValue += Line;
            exit;
        end;

        // Read everything
        while not InStr.EOS() do begin
            InStr.ReadText(Line);
            ReturnValue += Line;
        end;
    end;

    internal procedure GetResponseContentAsJson(var _JsonToken: JsonToken): Boolean
    var
        ResponseAsText: Text;
    begin
        ResponseAsText := GetResponseContentAsText(0);
        exit(_JsonToken.ReadFrom(ResponseAsText));
    end;

    procedure SetResponseHeaders(var _Value: HttpHeaders)
    begin
        ResponseHeaders := _Value;
    end;

    procedure SetResponseMessage(var _Value: HttpResponseMessage)
    begin
        ResponseMessage := _Value;
    end;

    procedure GetResponseMessage(var _Value: HttpResponseMessage)
    begin
        _Value := ResponseMessage;
    end;

}
