codeunit 81271 "MOB Report Barcode Mgt. 1D"
{
    Access = Public;
    /// <summary>
    /// https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-barcode-fonts
    /// 
    /// Barcode free in SaaS, purchase required Onprem
    /// One-dimensional (1D) barcode fonts and encoders are only included in version Business Central 2021 release wave 1 (v18.0) and later
    /// </summary>

    /* #if BC18+ */
    var
        BarcodeFontProvider: Interface "Barcode Font Provider";
        BarcodeSymbology: Enum "Barcode Symbology";
        AiDictionary: Dictionary of [Text, Text];
        SimpleTextToEncode: Text;

    /// <summary>
    /// Declare the Barcode Provider using the barcode provider interface and enum        
    /// </summary>    
    procedure Set_BarcodeFontProvider(_BarcodeFontProvider: Interface "Barcode Font Provider")
    begin
        BarcodeFontProvider := _BarcodeFontProvider;
    end;

    /// <summary>
    /// Declare the Font using the barcode symbology enum
    /// </summary>    
    procedure Set_BarcodeSymbology(_BarcodeSymbology: Enum "Barcode Symbology")
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
