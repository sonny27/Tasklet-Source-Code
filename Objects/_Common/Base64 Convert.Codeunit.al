codeunit 81320 "MOB Base64 Convert"
{
    Access = Public;
    /* #if BC15+ */
    var
        GlobalTempBlob: Codeunit "Temp Blob"; // Needed to retain value in TempBlob
    /* #endif */
    /* #if BC14 ##
    var
        GlobalTempBlob: Record TempBlob; // Needed to retain value in TempBlob
    /* #endif */

    /// <summary>
    /// Converts the specified string, which encodes binary data as base-64 digits, to an equivalent regular string.
    /// </summary>
    /// <param name="_Base64String">The string to convert.</param>
    /// <param name="_InStream">The stream to read the output from.</param>
    /// <returns>Regular string that is equivalent to the input base-64 string.</returns>
    /// <error>The length of Base64String, ignoring white-space characters, is not zero or a multiple of 4.</error>
    /// <error>The format of Base64String is invalid. Base64String contains a non-base-64 character, more than two padding characters,
    /// or a non-white space-character among the padding characters.</error>
    /* #if BC15+ */
    procedure FromBase64(_Base64String: Text; var _InStream: InStream)
    var
        Base64Convert: Codeunit "Base64 Convert";
        oStream: OutStream;
    begin
        Clear(GlobalTempBlob);
        GlobalTempBlob.CreateOutStream(oStream);
        Base64Convert.FromBase64(_Base64String, oStream);
        GlobalTempBlob.CreateInStream(_InStream);
    end;
    /* #endif */
    /* #if BC14 ##
    procedure FromBase64(_Base64String: Text; var _InStream: InStream)
    begin
        // GlobalTempBlob needed to retain value upon exit from procedure
        Clear(GlobalTempBlob);
        GlobalTempBlob.FromBase64String(_Base64String);
        GlobalTempBlob.Blob.CreateInStream(_InStream);
    end;
    /* #endif */

    /// <summary>
    /// Converts the value of the input stream to its equivalent string representation that is encoded with base-64 digits.
    /// </summary>
    /// <param name="InStream">The stream to read the input from.</param>
    /// <returns>The string representation, in base-64, of the input string.</returns>
    /* #if BC15+ */
    procedure ToBase64(_Instream: InStream): Text
    var
        Base64Convert: Codeunit "Base64 Convert";
    begin
        exit(Base64Convert.ToBase64(_Instream));
    end;
    /* #endif */
    /* #if BC14 ##
    procedure ToBase64(_Instream: InStream): Text
    var
        TempBlob: Record TempBlob;
        OStream: OutStream;
    begin
        TempBlob.Blob.CreateOutStream(OStream);
        CopyStream(OStream, _Instream);
        exit(TempBlob.ToBase64String());
    end;
    /* #endif */

    /// <summary>
    /// Converts the value of the input string to its equivalent string representation that is encoded with base-64 digits.
    /// </summary>
    /// <param name="String">The string to convert.</param>
    /// <returns>The string representation, in base-64, of the input string.</returns>
    /* #if BC15+ */
    procedure ToBase64(_String: Text): Text
    var
        Base64Convert: Codeunit "Base64 Convert";
    begin
        exit(Base64Convert.ToBase64(_String));
    end;
    /* #endif */
    /* #if BC14 ##
    procedure ToBase64(_String: Text): Text
    var
        TempBlob: Record TempBlob;
    begin
        TempBlob.WriteAsText(_String, TextEncoding::Windows);
        exit(TempBlob.ToBase64String());
    end;
    /* #endif */

}
