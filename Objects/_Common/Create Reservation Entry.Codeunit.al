codeunit 81319 "MOB Create Reserv. Entry"
{
    Access = Public;
    /// <summary>
    /// CreateReservEntry.SetNewTrackingFromNewTrackingSpecification: Method only available from BC17
    /// </summary>
    /* #if BC17+ */
    procedure SetNewTrackingFromNewTrackingSpecification(var _CreateReservEntry: Codeunit "Create Reserv. Entry"; _FromTrackingSpec: Record "Tracking Specification")
    begin
        _CreateReservEntry.SetNewTrackingFromNewTrackingSpecification(_FromTrackingSpec);
    end;
    /* #endif */
    /* #if BC16- ##
    procedure SetNewTrackingFromNewTrackingSpecification(var _CreateReservEntry: Codeunit "Create Reserv. Entry"; _FromTrackingSpec: Record "Tracking Specification")
    begin
        _CreateReservEntry.SetNewSerialLotNo(_FromTrackingSpec."New Serial No.", _FromTrackingSpec."New Lot No.");
    end;
    /* #endif */

    /// <summary>
    /// Replaced by procedure MobTrackingSetup.CreateReservEntryFor() with no ForSerialNo/ForLotNo parameters  (but not planned for removal for backwards compatibility)
    /// </summary>
    /* #if BC16+ */
    procedure CreateReservEntryFor(var _CreateReservEntry: Codeunit "Create Reserv. Entry"; _ForType: Option; _ForSubtype: Integer; _ForID: Code[20]; _ForBatchName: Code[10]; _ForProdOrderLine: Integer; _ForRefNo: Integer; _ForQtyPerUOM: Decimal; _Quantity: Decimal; _QuantityBase: Decimal; _ForSerialNo: Code[50]; _ForLotNo: Code[50])
    var
        ForReservEntry: Record "Reservation Entry";
    begin
        ForReservEntry."Serial No." := _ForSerialNo;
        ForReservEntry."Lot No." := _ForLotNo;
        _CreateReservEntry.CreateReservEntryFor(_ForType, _ForSubtype, _ForID, _ForBatchName, _ForProdOrderLine, _ForRefNo, _ForQtyPerUOM, _Quantity, _QuantityBase, ForReservEntry);
    end;
    /* #endif */
    /* #if BC15- ##
    procedure CreateReservEntryFor(var _CreateReservEntry: Codeunit "Create Reserv. Entry"; _ForType: Option; _ForSubtype: Integer; _ForID: Code[20]; _ForBatchName: Code[10]; _ForProdOrderLine: Integer; _ForRefNo: Integer; _ForQtyPerUOM: Decimal; _Quantity: Decimal; _QuantityBase: Decimal; _ForSerialNo: Code[50]; _ForLotNo: Code[50])
    begin
        _CreateReservEntry.CreateReservEntryFor(_ForType, _ForSubtype, _ForID, _ForBatchName, _ForProdOrderLine, _ForRefNo, _ForQtyPerUOM, _Quantity, _QuantityBase, _ForSerialNo, _ForLotNo);
    end;
    /* #endif */

    /// <summary>
    /// Replaced by procedure MobTrackingSetup.CreateReservEntryFor() with no ReservEntry parameter  (but not planned for removal for backwards compatibility)
    /// </summary>
    /// <remarks>
    /// Also called from Codeunit 6181291 "MOB Tracking Spec-Reserve"
    /// </remarks>
    /* #if BC16+ */
    procedure CreateReservEntryFor(var _CreateReservEntry: Codeunit "Create Reserv. Entry"; _ForType: Option; _ForSubtype: Integer; _ForID: Code[20]; _ForBatchName: Code[10]; _ForProdOrderLine: Integer; _ForRefNo: Integer; _ForQtyPerUOM: Decimal; _Quantity: Decimal; _QuantityBase: Decimal; ForReservEntry: Record "Reservation Entry")
    begin
        _CreateReservEntry.CreateReservEntryFor(_ForType, _ForSubtype, _ForID, _ForBatchName, _ForProdOrderLine, _ForRefNo, _ForQtyPerUOM, _Quantity, _QuantityBase, ForReservEntry);
    end;
    /* #endif */
    /* #if BC15- ##
    procedure CreateReservEntryFor(var _CreateReservEntry: Codeunit "Create Reserv. Entry"; _ForType: Option; _ForSubtype: Integer; _ForID: Code[20]; _ForBatchName: Code[10]; _ForProdOrderLine: Integer; _ForRefNo: Integer; _ForQtyPerUOM: Decimal; _Quantity: Decimal; _QuantityBase: Decimal; ForReservEntry: Record "Reservation Entry")
    begin
        _CreateReservEntry.CreateReservEntryFor(_ForType, _ForSubtype, _ForID, _ForBatchName, _ForProdOrderLine, _ForRefNo, _ForQtyPerUOM, _Quantity, _QuantityBase, ForReservEntry."Serial No.", ForReservEntry."Lot No.");
    end;
    /* #endif */

    /// <summary>
    /// Called from Codeunit 6181291 "MOB Tracking Spec-Reserve"
    /// </summary>
    /* #if BC16+ */
    procedure CreateReservEntryFrom(var _CreateReservEntry: Codeunit "Create Reserv. Entry"; _FromType: Option; _FromSubtype: Integer; _FromID: Code[20]; _FromBatchName: Code[10]; _FromProdOrderLine: Integer; _FromRefNo: Integer; _FromQtyPerUOM: Decimal; _FromSerialNo: Code[50]; _FromLotNo: Code[50])
    var
        FromTrackingSpecification: Record "Tracking Specification";
    begin
        Clear(FromTrackingSpecification);
        FromTrackingSpecification."Source Type" := _FromType;
        FromTrackingSpecification."Source Subtype" := _FromSubtype;
        FromTrackingSpecification."Source ID" := _FromID;
        FromTrackingSpecification."Source Ref. No." := _FromRefNo;
        FromTrackingSpecification."Source Batch Name" := _FromBatchName;
        FromTrackingSpecification."Source Prod. Order Line" := _FromProdOrderLine;
        FromTrackingSpecification."Qty. per Unit of Measure" := _FromQtyPerUOM;
        FromTrackingSpecification."Serial No." := _FromSerialNo;
        FromTrackingSpecification."Lot No." := _FromLotNo;

        _CreateReservEntry.CreateReservEntryFrom(FromTrackingSpecification);
    end;
    /* #endif */
    /* #if BC15- ##
    procedure CreateReservEntryFrom(var _CreateReservEntry: Codeunit "Create Reserv. Entry"; _FromType: Option; _FromSubtype: Integer; _FromID: Code[20]; _FromBatchName: Code[10]; _FromProdOrderLine: Integer; _FromRefNo: Integer; _FromQtyPerUOM: Decimal; _FromSerialNo: Code[50]; _FromLotNo: Code[50])
    begin
        _CreateReservEntry.CreateReservEntryFrom(_FromType, _FromSubtype, _FromID, _FromBatchName, _FromProdOrderLine, _FromRefNo, _FromQtyPerUOM, _FromSerialNo, _FromLotNo);
    end;
    /* #endif */

}
