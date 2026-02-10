codeunit 81299 "MOB Report Barcode Mgt. 2D"
{
    Access = Public;
    /// <summary>
    /// https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-barcode-fonts
    /// 
    /// Barcode free in SaaS, purchase required Onprem
    /// Two-dimensional (2D) barcode fonts and encoders are only included in version 19.1 and later.
    /// We only build main versions like 19.0 + 20.0 meaning our minimum requirement is 20.0
    /// </summary>

    /* #if BC20+ */
    var
        BarcodeFontProvider: Interface "Barcode Font Provider 2D";
        BarcodeSymbology: Enum "Barcode Symbology 2D";
        AiDictionary: Dictionary of [Text, Text];
        SimpleTextToEncode: Text;

    /// <summary>
    /// Declare the Barcode Provider using the barcode provider interface and enum        
    /// </summary>    
    procedure Set_BarcodeFontProvider(_BarcodeFontProvider: Interface "Barcode Font Provider 2D")
    begin
        BarcodeFontProvider := _BarcodeFontProvider;
    end;
    /// <summary>
    /// Declare the Font using the barcode symbology enum
    /// </summary>    
    procedure Set_BarcodeSymbology(_BarcodeSymbology: Enum "Barcode Symbology 2D")
    begin
        BarcodeSymbology := _BarcodeSymbology;
    end;

    procedure GetEncodedBarcodeText(): Text
    var
        BarcodeTxtBuilder: TextBuilder;
        AiKey: Text;
    begin
        foreach AiKey in AiDictionary.Keys() do
            BarcodeTxtBuilder.Append('(' + Format(AiKey) + ')' + AiDictionary.Get(AiKey));

        // If no Ai to encode, try use the SimpleTextToEncode
        if BarcodeTxtBuilder.ToText() = '' then
            BarcodeTxtBuilder.Append(SimpleTextToEncode);

        exit(BarcodeFontProvider.EncodeFont(BarcodeTxtBuilder.ToText(), BarcodeSymbology));
    end;

    procedure GetBarcodeText(): Text
    var
        BarcodeTxtBuilder: TextBuilder;
        AiKey: Text;
    begin
        foreach AiKey in AiDictionary.Keys() do
            BarcodeTxtBuilder.Append('(' + Format(AiKey) + ')' + AiDictionary.Get(AiKey));

        // If no Ai to encode, try use the SimpleTextToEncode
        if BarcodeTxtBuilder.ToText() = '' then
            BarcodeTxtBuilder.Append(SimpleTextToEncode);

        exit(BarcodeTxtBuilder.ToText());
    end;

    procedure GetAiDictionary(): Dictionary of [Text, Text]
    begin
        exit(AiDictionary);
    end;

    procedure SetAiDictionary(_AiDictionary: Dictionary of [Text, Text])
    begin
        AiDictionary := _AiDictionary;
    end;

    procedure SetSimpleTextToEncode(_InputValue: Text)
    begin
        SimpleTextToEncode := _InputValue;
    end;
    /* #endif */
}
