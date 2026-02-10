codeunit 81327 "MOB GS1 Helper"
{
    Access = Public;
    var
        MobTypeHelper: Codeunit "MOB Type Helper";
        TooManyDecimalsErr: Label 'The value is limited to 5 decimals (%1).', Comment = '%1 is value';
        TooManySignificantDigitsErr: Label 'The value is limited to 6 significant digits (%1).', Comment = '%1 is value';

    /// <summary>
    /// Success if quantity needs to be transformed to Ai 310n (to reflect decimals). Otherwise Ai 37 is normally used
    /// </summary>
    internal procedure QuantityTransformedToAI310n(_QuantityPerLabel: Decimal; var _Ai310n: Text[1]; var _Ai310Qty: Text) Success: Boolean
    var
        DecimalPart: Text;
        IntegerPart: Text;
    begin
        if _QuantityPerLabel <= 0 then
            exit(false);

        IntegerPart := MobTypeHelper.DecimalGetInteger(_QuantityPerLabel);
        DecimalPart := MobTypeHelper.DecimalGetDecimals(_QuantityPerLabel);

        if DecimalPart = '' then
            exit(false); // No decimal: No need to use Ai 310n

        if StrLen(DecimalPart) > 5 then
            Error(TooManyDecimalsErr, _QuantityPerLabel); // Max 5 decimals

        // Encode AI 310n. Example: 2 decimals is "3102"
        _Ai310n := Format(StrLen(DecimalPart));

        // Encode barcode quantity. Example: "1,23" becomes "000123"
        _Ai310Qty := IntegerPart + DecimalPart;
        _Ai310Qty := _Ai310Qty.TrimStart('0').PadLeft(6, '0');
        if StrLen(_Ai310Qty) <> 6 then
            Error(TooManySignificantDigitsErr, _QuantityPerLabel);

        exit(true);
    end;
}
