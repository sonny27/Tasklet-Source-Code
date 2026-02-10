codeunit 81356 "MOB Telemetry Container"
{
    SingleInstance = true;
    Access = Internal;

    var
        RequestDetailsDictionary: Dictionary of [Text, Text];

    internal procedure AddToRequestDetails(_Key: Text; _Value: Text)
    var
        KeyTxt: Text;
    begin
        KeyTxt := 'al' + _Key;
        if RequestDetailsDictionary.ContainsKey(KeyTxt) then
            RequestDetailsDictionary.Set(KeyTxt, _Value)
        else
            RequestDetailsDictionary.Add(KeyTxt, _Value);
    end;

    internal procedure GetRequestDetailsDictionary(var _RequestDetails: Dictionary of [Text, Text]): Boolean
    begin
        if RequestDetailsDictionary.Count() = 0 then
            exit(false);
        _RequestDetails := RequestDetailsDictionary;
        ClearRequestDetailsDictionary();
        exit(true);
    end;

    internal procedure ClearRequestDetailsDictionary()
    begin
        Clear(RequestDetailsDictionary);
    end;
}
