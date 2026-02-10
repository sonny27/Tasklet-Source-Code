codeunit 81339 "MOB Http Client Handler" implements "Http Client Handler"
//
// AppVersion 25.0.0.0
//
// (Interface might exist before BC25, but currently isn't used in MOB before BC25)
{
    Access = Public;
    
    procedure Send(_HttpClient: HttpClient; _HttpRequestMessage: Codeunit "Http Request Message"; var _HttpResponseMessage: Codeunit "Http Response Message") Success: Boolean
    var
        ResponseMessage: HttpResponseMessage;
    begin
        Success := _HttpClient.Send(_HttpRequestMessage.GetHttpRequestMessage(), ResponseMessage);
        _HttpResponseMessage.SetResponseMessage(ResponseMessage);
    end;
}
