codeunit 81335 "MOB Language"
{
    Access = Public;
    /* #if BC26+ */
    /// <summary>
    /// Wrapper for codeunit 43 Language, procedure GetCultureName
    /// </summary>
    internal procedure GetCultureName(_LanguageID: Integer): Text
    var
        Language: Codeunit Language;
    begin
        exit(Language.GetCultureName(_LanguageID));
    end;
    /* #endif */

    /* #if BC25- ##
    internal procedure GetCultureName(_LanguageID: Integer): Text
    var
        TypeHelper: Codeunit "Type Helper";
    begin
        exit(TypeHelper.LanguageIDToCultureName(_LanguageID));
    end;
    /* #endif */
}
