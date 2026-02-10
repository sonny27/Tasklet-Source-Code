codeunit 81435 "MOB Type Helper"
{
    Access = Public;
    var
        TypeHelper: Codeunit "Type Helper";
        MobLanguage: Codeunit "MOB Language";

    /// <summary>
    /// Formatting and misc. helper-functions for Text, Date, Decimal etc. types
    /// </summary>

    /// <summary>
    /// YYMMDD is also the "GS1" date format
    /// </summary>    
    procedure FormatDateAsYYMMDD(_Date: Date): Text
    begin
        if _Date <> 0D then
            exit(CopyStr(Format(_Date, 0, '<Year4>'), 3) + Format(_Date, 0, '<Month,2><Day,2>')); // CopyStr() because <Year> do not return last two digits as documented
    end;

    internal procedure FormatDateAsYYYYMMDD(_Date: Date): Text
    begin
        if _Date <> 0D then
            exit(Format(_Date, 0, '<Year4><Month,2><Day,2>'));
    end;

    /// <summary>
    /// Convert Date to Text in Mobile Display format (Mobile user language format)
    /// </summary>    
    internal procedure FormatDateAsLanguage(_Date: Date; _LanguageID: Integer): Text
    begin
        if _Date = 0D then
            exit('');

        if _LanguageID < 1 then // Typehelper WILL CRASH if LanguageID is not positive
            exit('');

        exit(TypeHelper.FormatDate(_Date, _LanguageID)); // TypeHelper outputs 4-digit year i.e. 12/31/2020   AL:Format(_Date) would return 2-digit 12/31/20
    end;

    internal procedure FormatTimeAsHHMM(_Time: Time): Text
    begin
        if _Time <> 0T then
            exit(Format(_Time, 0, '<Hours24,2><Minutes,2>'));
    end;

    internal procedure FormatDateTimeAsYYYYMMDDHHMM(_DateTime: DateTime): Text
    begin
        exit(FormatDateAsYYYYMMDD(DT2Date(_DateTime)) + FormatTimeAsHHMM(DT2Time(_DateTime)));
    end;

    /// <summary>
    /// Convert DateTime to Text in Mobile Display format (Mobile user language format)
    /// </summary>    
    internal procedure FormatDateTimeAsLanguage(_DateTime: DateTime; _LanguageID: Integer): Text
    var
        LongDateTimeText: Text;
        ShortDateTimeText: Text;
        ZeroSecondsPos: Integer;
        OffsetPos: Integer;
    begin
        if _DateTime = 0DT then
            exit('');

        if _LanguageID < 1 then // Typehelper WILL CRASH if LanguageID is not positive
            exit('');

        LongDateTimeText := TypeHelper.FormatUtcDateTime(_DateTime, '', MobLanguage.GetCultureName(_LanguageID)); // ie. "12/31/2022 3:25:00 PM +01:00" or "31/12/2022 15:25:00+01:00"
        ShortDateTimeText := LongDateTimeText;
        ZeroSecondsPos := StrPos(ShortDateTimeText, ':00');
        if ZeroSecondsPos <> 0 then
            ShortDateTimeText := ShortDateTimeText.Remove(ZeroSecondsPos, StrLen(':00'));
        OffsetPos := StrPos(ShortDateTimeText, '+');
        if OffsetPos <> 0 then
            ShortDateTimeText := CopyStr(ShortDateTimeText, 1, OffsetPos - 1);
        ShortDateTimeText := ShortDateTimeText.TrimEnd();

        if ShortDateTimeText.EndsWith('AM') or ShortDateTimeText.EndsWith('PM') then
            ShortDateTimeText := CopyStr(ShortDateTimeText, 1, StrLen(ShortDateTimeText) - 3) + ' ' + CopyStr(ShortDateTimeText, StrLen(ShortDateTimeText) - 1);

        exit(ShortDateTimeText);
    end;

    /// <summary>
    /// Convert Decimal to Text in Mobile Display format (Mobile user language format)
    /// </summary>    
    internal procedure FormatDecimalAsLanguage(_Decimal: Decimal; _BlankZero: Boolean; _LanguageID: Integer): Text
    begin
        if _Decimal = 0 then
            if _BlankZero then
                exit(' ') // Space is intentional
            else
                exit('0');

        // Uses DotNet String.Format. See https://learn.microsoft.com/en-us/dotnet/standard/base-types/custom-numeric-format-strings#SpecifierD
        exit(TypeHelper.FormatDecimal(_Decimal, '0.################', MobLanguage.GetCultureName(_LanguageID))); //'0.################' = Any value without 1000-separator, limited to max 16 decimal places
    end;

    /// <summary>
    /// Get only the decimal part of a Decimal
    /// </summary>
    internal procedure DecimalGetDecimals(_Decimal: Decimal): Text
    begin
        exit(CopyStr(Format(_Decimal, 0, '<Decimals>'), 2)); // Copy "123" from "0.123"
    end;

    /// <summary>
    /// Get only the integer part of a Decimal
    /// </summary>
    internal procedure DecimalGetInteger(_Decimal: Decimal): Text
    begin
        exit(Format(_Decimal, 0, '<Integer>'));
    end;

    /// <summary>
    /// New function "Type Helper".ReadAsTextWithSeparator() introduced in BC15
    /// </summary>
    /* #if BC15+ */
    procedure ReadAsTextWithSeparator(var _Instream: InStream; _LineSeparator: Text): Text
    begin
        exit(TypeHelper.ReadAsTextWithSeparator(_Instream, _LineSeparator));
    end;
    /* #endif */
    /* #if BC14 ##
    procedure ReadAsTextWithSeparator(var _Instream: InStream; _LineSeparator: Text): Text
    var
        TempBlob: Record TempBlob;
        OStream: OutStream;
    begin
        TempBlob.Blob.CreateOutStream(OStream);
        CopyStream(OStream, _Instream);
        exit(TempBlob.ReadAsText(_LineSeparator, TextEncoding::UTF8));
    end;
    /* #endif */

}
