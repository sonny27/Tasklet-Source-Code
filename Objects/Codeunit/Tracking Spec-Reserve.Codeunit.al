codeunit 81291 "MOB Tracking Spec-Reserve"
{
    Access = Public;

    var
        CreateReservEntry: Codeunit "Create Reserv. Entry";

    /// <summary>
    /// Create a single ReservationEntry (with no ReservationEntryFrom) for a TrackingSpec
    /// The function expects the quantity to be in the base UoM.
    /// </summary>
    procedure CreateReservation(_TrackingSpec: Record "Tracking Specification")
    var
        DummyReservEntry: Record "Reservation Entry";
        MobCommonMgt: Codeunit "MOB Common Mgt.";
        MobCreateReservEntry: Codeunit "MOB Create Reserv. Entry";
        MobItemTrackingManagement: Codeunit "MOB Item Tracking Management";
        ExpirationDate: Date;
        EntriesExist: Boolean;
    begin
        CreateReservEntryFor(_TrackingSpec);

        // If expiration date is used for either the serial or lot number then the new expiration date must match the old exp date
        ExpirationDate :=
            MobItemTrackingManagement.ExistingExpirationDate(
                _TrackingSpec,
                false,
                EntriesExist);

        if EntriesExist and (ExpirationDate <> 0D) then begin
            SetDates(0D, ExpirationDate);
            SetNewExpirationDate(ExpirationDate);
        end else begin
            SetDates(0D, _TrackingSpec."Expiration Date");
            SetNewExpirationDate(_TrackingSpec."Expiration Date");
        end;

        MobCommonMgt.CopyNewTrackingFromTrackingSpec(_TrackingSpec, _TrackingSpec);
        MobCreateReservEntry.SetNewTrackingFromNewTrackingSpecification(CreateReservEntry, _TrackingSpec);

        CreateEntry(
            _TrackingSpec."Item No.",
            _TrackingSpec."Variant Code",
            _TrackingSpec."Location Code",
            _TrackingSpec.Description,
            0D,
            WorkDate(),
            0,  // Transferred from entry no.
            DummyReservEntry."Reservation Status"::Prospect);
    end;

    procedure CreateReservEntryFor(_TrackingSpec: Record "Tracking Specification")
    var
        ReservEntry: Record "Reservation Entry";
        MobCreateReservEntry: Codeunit "MOB Create Reserv. Entry";
    begin
        ReservEntry.CopyTrackingFromSpec(_TrackingSpec);

        MobCreateReservEntry.CreateReservEntryFor(CreateReservEntry,
            _TrackingSpec."Source Type",
            _TrackingSpec."Source Subtype",
            _TrackingSpec."Source ID",
            _TrackingSpec."Source Batch Name",
            _TrackingSpec."Source Prod. Order Line",
            _TrackingSpec."Source Ref. No.",
            _TrackingSpec."Qty. per Unit of Measure",
            _TrackingSpec."Qty. to Handle",
            _TrackingSpec."Qty. to Handle (Base)",
            ReservEntry);
    end;

    procedure SetDates(_WarrantyDate: Date; _ExpirationDate: Date)
    begin
        CreateReservEntry.SetDates(_WarrantyDate, _ExpirationDate);
    end;

    procedure SetNewExpirationDate(_NewExpirationDate: Date)
    begin
        CreateReservEntry.SetNewExpirationDate(_NewExpirationDate);
    end;

    // Reservation Status changed from option to enum since BC16
    /* #if BC16+ */
    procedure CreateEntry(_ItemNo: Code[20]; _VariantCode: Code[10]; _LocationCode: Code[10]; _Description: Text[100]; _ExpectedReceiptDate: Date; _ShipmentDate: Date; _TransferredFromEntryNo: Integer; _Status: Enum "Reservation Status")
    begin
        CreateReservEntry.CreateEntry(_ItemNo, _VariantCode, _LocationCode, _Description, _ExpectedReceiptDate, _ShipmentDate, _TransferredFromEntryNo, _Status);
    end;
    /* #endif */
    /* #if BC14,BC15 ##
    procedure CreateEntry(_ItemNo: Code[20]; _VariantCode: Code[10]; _LocationCode: Code[10]; _Description: Text[100]; _ExpectedReceiptDate: Date; _ShipmentDate: Date; _TransferredFromEntryNo: Integer; _Status: Option Reservation,Tracking,Surplus,Prospect)
    begin
        CreateReservEntry.CreateEntry(_ItemNo, _VariantCode, _LocationCode, _Description, _ExpectedReceiptDate, _ShipmentDate, _TransferredFromEntryNo, _Status);
    end;
    /* #endif */

    procedure GetLastEntry(var _ReservEntry: Record "Reservation Entry")
    begin
        CreateReservEntry.GetLastEntry(_ReservEntry);
    end;
}
