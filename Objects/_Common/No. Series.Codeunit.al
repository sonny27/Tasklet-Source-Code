codeunit 81331 "MOB No. Series"
{
    Access = Public;
    /* #if BC24+ */
    internal procedure GetNextNo(_NoSeriesCode: Code[20]; _SeriesDate: Date; _ModifySeries: Boolean) Result: Code[20]
    var
        NoSeries: Codeunit "No. Series";
    begin
        if _ModifySeries then
            exit(NoSeries.GetNextNo(_NoSeriesCode, _SeriesDate, false))
        else
            exit(NoSeries.PeekNextNo(_NoSeriesCode, _SeriesDate));
    end;
    /* #endif */

    /* #if BC23- ##
    internal procedure GetNextNo(_NoSeriesCode: Code[20]; _SeriesDate: Date; _ModifySeries: Boolean) Result: Code[20]
    var
        NoSeriesManagement: Codeunit NoSeriesManagement;
    begin
        exit(NoSeriesManagement.GetNextNo(_NoSeriesCode, _SeriesDate, _ModifySeries));
    end;
    /* #endif */
}
