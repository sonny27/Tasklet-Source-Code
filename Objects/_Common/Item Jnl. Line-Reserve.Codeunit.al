codeunit 81348 "MOB Item Jnl. Line-Reserve"
{
    Access = Public;
    /* #if BC25+ */
    internal procedure InitFromItemJnlLine(var _TrackingSpecification: Record "Tracking Specification"; _ItemJnlLine: Record "Item Journal Line")
    var
        ItemJnlLineReserve: Codeunit "Item Jnl. Line-Reserve";
    begin
        ItemJnlLineReserve.InitFromItemJnlLine(_TrackingSpecification, _ItemJnlLine);
    end;
    /* #endif */
    /* #if BC24- ##
    internal procedure InitFromItemJnlLine(var _TrackingSpecification: Record "Tracking Specification"; _ItemJnlLine: Record "Item Journal Line")
    begin
        _TrackingSpecification.InitFromItemJnlLine(_ItemJnlLine);
    end;
    /* #endif */
}
