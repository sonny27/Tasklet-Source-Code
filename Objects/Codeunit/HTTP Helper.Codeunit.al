codeunit 81282 "MOB HTTP Helper"
{
    Access = Internal;

    var
        MobTelemetryMgt: Codeunit "MOB Telemetry Management";
        HttpClientFailedErr: Label 'HttpClient.Send() failed. This may be because Mobile WMS has not been granted permission to make HttpClient requests, or due to firewall or network connectivity issues.';

    /// <summary>
    /// Try sending Http request
    /// </summary>
    internal procedure TrySend(var _RestParameter: Record "MOB Print REST Parameter" temporary): Boolean
    var
        RequestMessage: HttpRequestMessage;
        IsSuccessStatusCode: Boolean;
    begin
        HttpInitialize(RequestMessage, _RestParameter);
        HttpAddContent(RequestMessage, _RestParameter);

        ClearLastError();

        IsSuccessStatusCode := HttpGetResponse(RequestMessage, _RestParameter);

        // Log Telemetry
        if not IsSuccessStatusCode then
            MobTelemetryMgt.LogErrorHttpHelperTrySend(_RestParameter);

        exit(IsSuccessStatusCode);
    end;

    local procedure HttpInitialize(var _RequestMessage: HttpRequestMessage; var _RestParameter: Record "MOB Print REST Parameter")
    var
        MobBase64Convert: Codeunit "MOB Base64 Convert";
        Headers: HttpHeaders;
        AuthText: Text;
        Token: Text;
        IStream: InStream;
    begin
        _RequestMessage.Method := Format(_RestParameter.RestMethod);
        _RequestMessage.SetRequestUri(_RestParameter.URL);

        _RequestMessage.GetHeaders(Headers);

        if _RestParameter.Token.HasValue() then begin
            // OAuth 
            _RestParameter.Token.CreateInStream(IStream);
            IStream.ReadText(Token);
            AuthText := StrSubstNo('Bearer %1', Token);
        end else
            // Basic
            AuthText := StrSubstNo('Basic %1', MobBase64Convert.ToBase64(StrSubstNo('%1:%2', _RestParameter.UserName, _RestParameter.Password)));

        Headers.Add('Authorization', AuthText);
    end;

    local procedure HttpAddContent(var _RequestMessage: HttpRequestMessage; var _RestParameter: Record "MOB Print REST Parameter")
    var
        Content: HttpContent;
    begin
        if _RestParameter.HasRequestContent() then begin
            _RestParameter.GetRequestContent(Content);
            _RequestMessage.Content := Content;
        end;
    end;

    local procedure HttpGetResponse(var _RequestMessage: HttpRequestMessage; var _RestParameter: Record "MOB Print REST Parameter"): Boolean
    var
        Client: HttpClient;
        Content: HttpContent;
        MessageHeaders: HttpHeaders;
        ResponseMessage: HttpResponseMessage;
    begin
        // Client.Send() returns Ok if it can reach the server and the server responds - no matter which error code it returns.
        if Client.Send(_RequestMessage, ResponseMessage) then begin

            MessageHeaders := ResponseMessage.Headers();
            Content := ResponseMessage.Content();

            _RestParameter.SetResponseMessage(ResponseMessage);
            _RestParameter.SetResponseHeaders(MessageHeaders);
            _RestParameter.SetResponseContent(Content);

            _RestParameter."Result HttpStatusCode" := ResponseMessage.HttpStatusCode();
            _RestParameter."Result IsSuccessStatusCode" := ResponseMessage.IsSuccessStatusCode();
            _RestParameter."Result IsBlockedByEnvironment" := ResponseMessage.IsBlockedByEnvironment();
            _RestParameter."Result ReasonPhrase" := CopyStr(ResponseMessage.ReasonPhrase(), 1, 250);

        end else begin

            _RestParameter."Result HttpStatusCode" := -1; // -1 means that the server is unreachable
            _RestParameter."Result IsSuccessStatusCode" := false;
            _RestParameter."Result IsBlockedByEnvironment" := false;
            _RestParameter."Result ReasonPhrase" := HttpClientFailedErr;

        end;

        exit(_RestParameter."Result IsSuccessStatusCode");

    end;
}
