codeunit 81278 "MOB HTML Management"
{
    Access = Public;
    /// <summary>
    /// Begin table with four columns
    /// </summary>
    procedure BeginFourColumnTable(var _HtmlTable: Text; _ColumnAHeader: Text; _ColumnBHeader: Text; _ColumnCHeader: Text; _ColumnDHeader: Text)
    begin

        _HtmlTable := '<html><table style="width:100%">';
        _HtmlTable += '<tr>';
        if _ColumnAHeader <> '' then
            _HtmlTable += StrSubstNo('<th align="left">%1</th>', _ColumnAHeader);
        if _ColumnBHeader <> '' then
            _HtmlTable += StrSubstNo('<th align="left">%1</th>', _ColumnBHeader);
        if _ColumnCHeader <> '' then
            _HtmlTable += StrSubstNo('<th align="right">%1</th>', _ColumnCHeader);
        if _ColumnDHeader <> '' then
            _HtmlTable += StrSubstNo('<th align="right">%1</th>', _ColumnDHeader);
        _HtmlTable += '</tr>';
    end;

    /// <summary>
    /// Add a row to table with four columns
    /// </summary>
    procedure AddRowToFourColumnTable(var _HtmlTable: Text; _ColumnA: Text; _ColumnB: Text; _ColumnC: Text; _ColumnD: Text)
    begin
        _HtmlTable += '<tr>';
        if _ColumnA <> '' then
            _HtmlTable += StrSubstNo('<td align="left">%1</td>', _ColumnA);
        if _ColumnB <> '' then
            _HtmlTable += StrSubstNo('<td align="left">%1</td>', _ColumnB);
        if _ColumnC <> '' then
            _HtmlTable += StrSubstNo('<td align="right">%1</td>', _ColumnC);
        if _ColumnD <> '' then
            _HtmlTable += StrSubstNo('<td align="right">%1</td>', _ColumnD);
        _HtmlTable += '</tr>';
    end;

    /// <summary>
    /// Finalize table
    /// </summary>
    procedure EndTable(var _HtmlTable: Text)
    begin
        _HtmlTable += '</table></html>';
    end;

    /// <summary>
    /// Create and return a simple HTML page containing a textarea element showing _input text
    /// </summary>
    internal procedure CreateHtmlWithTextArea(_Input: Text): Text
    var
        Html: Text;
    begin
        Html := '<!DOCTYPE html><html><head><style type=''text/css''>textarea { background-color:#F6F7F8; width:100%; height:100%; resize: none; border: none; padding: 10px;';
        Html += 'font-size: 14px; font-family: "Segoe UI", "Segoe WP", Segoe, device-segoe, Tahoma, Helvetica, Arial;}</style></head>';
        Html += '<body><textarea readonly Id="TextArea">%1</textarea></body></html>';

        exit(StrSubstNo(Html, _Input));
    end;

}
