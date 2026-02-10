codeunit 81277 "MOB JSON Helper"
{
    Access = Internal;

    internal procedure GetValue(_Object: JsonObject; _Property: Text; var _Value: JsonValue) ReturnSuccess: Boolean
    var
        JToken: JsonToken;
    begin
        if _Object.Get(_Property, JToken) then
            if JToken.IsValue() then begin
                _Value := JToken.AsValue();
                ReturnSuccess := true;
            end;
    end;

    internal procedure GetValueAsText(_Token: JsonToken; _Property: Text): Text
    begin
        if _Token.IsObject() then
            exit(GetValueAsText(_Token.AsObject(), _Property));
    end;

    internal procedure GetValueAsText(_Object: JsonObject; _Property: Text): Text
    var
        JValue: JsonValue;
    begin
        if GetValue(_Object, _Property, JValue) then
            exit(JValue.AsText());
    end;

    internal procedure GetValueAsInteger(_Object: JsonObject; _Property: Text): Integer
    var
        JValue: JsonValue;
    begin
        if GetValue(_Object, _Property, JValue) then
            exit(JValue.AsInteger());
    end;

    internal procedure GetValueAsArray(_Object: JsonObject; _Property: Text): JsonArray
    var
        JToken: JsonToken;
    begin
        if _Object.Get(_Property, JToken) then
            exit(JToken.AsArray());
    end;

    /// <summary>
    /// Similar to GetValue(), but using SelectToken and thereby supporting paths
    /// Should only be used for paths, as GetKey is more efficient for direct properties
    /// </summary>
    internal procedure SelectValue(_Object: JsonObject; _Path: Text; var _Value: JsonValue): Boolean
    var
        JToken: JsonToken;
    begin
        if _Object.SelectToken(_Path, JToken) then
            if JToken.IsValue() then begin
                _Value := JToken.AsValue();
                exit(true);
            end;
    end;

    /// <summary>
    /// Similar to GetValueAsText(), but using SelectToken and thereby supporting paths
    /// Should only be used for paths, as GetKey is more efficient for direct properties
    /// </summary>
    internal procedure SelectValueAsText(_Token: JsonToken; _Path: Text): Text
    begin
        if _Token.IsObject() then
            exit(SelectValueAsText(_Token.AsObject(), _Path));
    end;

    /// <summary>
    /// Similar to GetValueAsText(), but using SelectToken and thereby supporting paths
    /// Should only be used for paths, as GetKey is more efficient for direct properties
    /// </summary>
    internal procedure SelectValueAsText(_Object: JsonObject; _Path: Text): Text
    var
        JValue: JsonValue;
    begin
        if SelectValue(_Object, _Path, JValue) then
            exit(JValue.AsText());
    end;
}
