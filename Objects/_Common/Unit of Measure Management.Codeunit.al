codeunit 81318 "MOB Unit of Measure Management"
{
    Access = Public;
    /// <summary>
    /// New function "Unit of Measure Management".TimeRndPrecision() introduced in BC14.X.X
    /// </summary>
    /* #if BC15+ */
    procedure TimeRndPrecision(): Decimal
    var
        UoMMgt: Codeunit "Unit of Measure Management";
    begin
        exit(UoMMgt.TimeRndPrecision());
    end;
    /* #endif */
    /* #if BC14 ##
    procedure TimeRndPrecision(): Decimal
    begin
        // Event OnBeforeTimeRndPrecision(RoundingPrecision) not supported in this BC version
        exit(0.00001);
    end;
    /* #endif */


    /// <summary>
    /// New function "Unit of Measure Management".CubageRndPrecision() introduced in BC14.X.X
    /// </summary>
    /* #if BC15+ */
    procedure CubageRndPrecision(): Decimal
    var
        UoMMgt: Codeunit "Unit of Measure Management";
    begin
        exit(UoMMgt.CubageRndPrecision());
    end;
    /* #endif */
    /* #if BC14 ##
    procedure CubageRndPrecision(): Decimal
    begin
        exit(0.00001);
    end;
    /* #endif */


    /// <summary>
    /// New function "Unit of Measure Management".WeightRndPrecision() introduced in BC14.X.X
    /// </summary>
    /* #if BC15+ */
    procedure WeightRndPrecision(): Decimal
    var
        UoMMgt: Codeunit "Unit of Measure Management";
    begin
        exit(UoMMgt.WeightRndPrecision());
    end;
    /* #endif */
    /* #if BC14 ##
    procedure WeightRndPrecision(): Decimal
    begin
        exit(0.00001);
    end;
    /* #endif */


    /// <summary>
    /// New function "Unit of Measure Management".RoundToItemRndPrecision() introduced in BC15.X
    /// </summary>
    /* #if BC16+ */
    procedure RoundToItemRndPrecision(_Qty: Decimal; _ItemRndPrecision: Decimal) _Result: Decimal
    var
        UomMgt: Codeunit "Unit of Measure Management";
    begin
        exit(UomMgt.RoundToItemRndPrecision(_Qty, _ItemRndPrecision));
    end;
    /* #endif */
    /* #if BC15- ##
    procedure RoundToItemRndPrecision(_Qty: Decimal; _ItemRndPrecision: Decimal) _Result: Decimal
    begin
        exit(Round(_Qty, _ItemRndPrecision, '>'));
    end;
    /* #endif */

}
