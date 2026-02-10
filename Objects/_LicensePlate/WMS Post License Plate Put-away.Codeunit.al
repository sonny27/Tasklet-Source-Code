codeunit 82218 "MOB WMS Post LP Put-away"
{
    Access = Internal;

    var
        MobPostLpPutawayEventSub: Codeunit "MOB Post LP Put-away EventSub";
        UnableToApplyErr: Label 'Failed to apply %1 of Item %2 from the License Plate to the Warehouse Activity Lines.', Comment = '%1 is Remaining Quantity to apply, %2 is an Item No.';
        ToBinNotValidErr: Label 'The value %1 is as a License Plate.\\You cannot move a License Plate into a License Plate during the Put-away process. When a related Put-away exists, you must scan or specify the Bin Code to which the License Plate will be moved.', Comment = '%1 is the Scanned ToBin Value.';

    internal procedure PostPutAwayFromLicensePlate(_LicensePlate: Record "MOB License Plate"; _ToBin: Code[20]; var _ResultMessage: Text) PostingRunSuccessful: Boolean
    var
        WhseActHeader: Record "Warehouse Activity Header";
        WhseActLine: Record "Warehouse Activity Line";
        MobLicensePlate: Record "MOB License Plate";
        WhseActRegister: Codeunit "Whse.-Activity-Register";
        WMSMgt: Codeunit "WMS Management";
        MobToolbox: Codeunit "MOB Toolbox";
        MobWmsActivity: Codeunit "MOB WMS Activity";
        MobSessionData: Codeunit "MOB SessionData";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        PostedDocExists: Boolean;
    begin
        WhseActLine.SetCurrentKey("Whse. Document No.", "Whse. Document Type", "Activity Type");
        WhseActLine.SetRange("Whse. Document No.", _LicensePlate."Whse. Document No.");
        WhseActLine.SetRange("Whse. Document Type", WhseActLine."Whse. Document Type"::Receipt);
        WhseActLine.SetRange("Activity Type", WhseActLine."Activity Type"::"Put-away");
        if not WhseActLine.FindFirst() then
            exit(false);

        // Check that _ToBin is not a License Plate, we only accept Bin Code when a related Put-away exist
        if MobLicensePlate.Get(_ToBin) then
            Error(ToBinNotValidErr, _ToBin);

        // Lock the tables to work on
        WhseActHeader.LockTable();
        WhseActLine.LockTable();

        if not WhseActHeader.Get(WhseActHeader.Type::"Put-away", WhseActLine."No.") then
            exit(false);

        WhseActHeader.Validate("Posting Date", WorkDate());
        WhseActHeader."MOB Posting MessageId" := MobSessionData.GetPostingMessageId();
        WhseActHeader.Modify();

        WhseActLine.Reset();
        WhseActLine.SetRange("Activity Type", WhseActHeader.Type);
        WhseActLine.SetRange("No.", WhseActHeader."No.");

        // Reset QtyToHandle on all lines
        ResetQtyToHandle(WhseActLine);

        // Update QtyToHandle and Bin Code based on the License Plate
        UpdateWhseActLineFromLicensePlateContent(WhseActHeader, _LicensePlate, _ToBin);

        // Filter again to get both the take and place lines -> then post
        WhseActLine.Reset();
        WhseActLine.SetRange("Activity Type", WhseActHeader.Type);
        WhseActLine.SetRange("No.", WhseActHeader."No.");
        WhseActLine.FindSet();

        // Make sure that no windows are shown during the posting process
        WhseActRegister.ShowHideDialog(true);

        // Check balance on everything having Take/Place lines
        WMSMgt.CheckBalanceQtyToHandle(WhseActLine);

        // Commit Required to use Codeunit.Run below
        Commit();

        // Manual bind of Event Subscriber to ensure that the specific License Plate is updated with the specified ToBin in the same transaction as the Put-away is registered
        MobPostLpPutawayEventSub.SetParameters(_LicensePlate."No.", _ToBin);
        BindSubscription(MobPostLpPutawayEventSub);

        // Do the actual posting
        /* #if BC15+ */
        WhseActRegister.SetSuppressCommit(true);
        /* #endif */
        PostingRunSuccessful := WhseActRegister.Run(WhseActLine);

        // Unbind the Event Subscriber
        UnbindSubscription(MobPostLpPutawayEventSub);

        // If Posted Warehouse Activity Exists Posting has succeeded but something else failed. ie. partner code OnAfter event
        if not PostingRunSuccessful then
            PostedDocExists := MobWmsActivity.PostedWhseActivityExists(WhseActHeader);

        if PostingRunSuccessful or PostedDocExists then begin
            _ResultMessage := MobToolbox.GetPostSuccessMessage(PostingRunSuccessful) + MobToolbox.CRLFSeparator() + MobToolbox.CRLFSeparator() + MobWmsLanguage.GetMessage('LICENSEPLATE') + ': ' + _LicensePlate."No." + ' ' + MobWmsLanguage.GetMessage('BIN') + ': ' + _ToBin;
            Commit();
            MobWmsActivity.UpdateIncomingWarehouseActivityOrder(WhseActHeader);
        end else begin
            _ResultMessage := GetLastErrorText();
            MobSessionData.SetPreservedLastErrorCallStack();
            MobWmsActivity.UpdateIncomingWarehouseActivityOrder(WhseActHeader);
            Commit();
            Error(_ResultMessage);
        end;
    end;

    local procedure ResetQtyToHandle(var _WhseActLine: Record "Warehouse Activity Line")
    begin
        if _WhseActLine.FindSet(true) then
            repeat
                _WhseActLine.Validate("Qty. to Handle", 0);
                _WhseActLine.Modify();
            until _WhseActLine.Next() = 0;
    end;

    local procedure UpdateWhseActLineFromLicensePlateContent(var _WhseActHeader: Record "Warehouse Activity Header"; _MobLicensePlate: Record "MOB License Plate"; _ToBin: Code[20])
    var
        MobLicensePlate: Record "MOB License Plate";
        MobLicensePlateContent: Record "MOB License Plate Content";
        ActionType: Option Take,Place;
    begin
        MobLicensePlateContent.Reset();
        MobLicensePlateContent.SetRange("License Plate No.", _MobLicensePlate."No.");
        if MobLicensePlateContent.FindSet() then
            repeat
                if MobLicensePlateContent.Type = MobLicensePlateContent.Type::Item then begin
                    // Handle related Take Lines
                    UpdateWhseActLine(_WhseActHeader, MobLicensePlateContent, ActionType::Take, '');

                    // Handle related Place Lines
                    UpdateWhseActLine(_WhseActHeader, MobLicensePlateContent, ActionType::Place, _ToBin);
                end else begin // Type = License Plate
                    MobLicensePlate.Get(MobLicensePlateContent."No.");
                    UpdateWhseActLineFromLicensePlateContent(_WhseActHeader, MobLicensePlate, _ToBin);
                end;
            until MobLicensePlateContent.Next() = 0;
    end;

    local procedure UpdateWhseActLine(_WhseActHeader: Record "Warehouse Activity Header"; _MobLicensePlateContent: Record "MOB License Plate Content"; _ActionType: Option Take,Place; _BinCode: Code[20])
    var
        MobTrackingSetup: Record "MOB Tracking Setup";
        WhseActLine: Record "Warehouse Activity Line";
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
        RegisterExpirationDate: Boolean;
        RemainingQtyToApplyBase: Decimal;
        CalculatedOutstandingQtyBase: Decimal;
    begin
        RemainingQtyToApplyBase := _MobLicensePlateContent."Quantity (Base)";

        WhseActLine.SetCurrentKey("Whse. Document No.", "Whse. Document Type", "Activity Type", "Whse. Document Line No.");
        WhseActLine.SetRange("Activity Type", _WhseActHeader.Type);
        WhseActLine.SetRange("No.", _WhseActHeader."No.");
        WhseActLine.SetRange("Whse. Document Type", _MobLicensePlateContent."Whse. Document Type"::Receipt);
        WhseActLine.SetRange("Whse. Document No.", _MobLicensePlateContent."Whse. Document No.");
        WhseActLine.SetRange("Whse. Document Line No.", _MobLicensePlateContent."Whse. Document Line No.");

        MobTrackingSetup.DetermineWhseTrackingRequired(_MobLicensePlateContent."No.", RegisterExpirationDate);

        if MobTrackingSetup."Serial No. Required" then
            WhseActLine.SetRange("Serial No.", _MobLicensePlateContent."Serial No.");

        if MobTrackingSetup."Lot No. Required" then
            WhseActLine.SetRange("Lot No.", _MobLicensePlateContent."Lot No.");

        /* #if BC18+ */
        if MobTrackingSetup."Package No. Required" then
            WhseActLine.SetRange("Package No.", _MobLicensePlateContent."Package No.");
        /* #endif */

        if _ActionType = _ActionType::Take then
            WhseActLine.SetRange("Action Type", WhseActLine."Action Type"::Take)
        else
            WhseActLine.SetRange("Action Type", WhseActLine."Action Type"::Place);
        if WhseActLine.FindSet(true) then
            repeat
                if WhseActLine."Qty. to Handle (Base)" < WhseActLine."Qty. Outstanding (Base)" then begin  // Check if some has already been handled

                    CalculatedOutstandingQtyBase := WhseActLine."Qty. Outstanding (Base)" - WhseActLine."Qty. to Handle (Base)";

                    if CalculatedOutstandingQtyBase <= RemainingQtyToApplyBase then begin  // Check if we have enough RemainingQtyToApply                        
                        WhseActLine.Validate("Qty. to Handle (Base)", WhseActLine."Qty. to Handle (Base)" + CalculatedOutstandingQtyBase);
                        RemainingQtyToApplyBase := RemainingQtyToApplyBase - CalculatedOutstandingQtyBase;
                    end else begin
                        WhseActLine.Validate("Qty. to Handle (Base)", WhseActLine."Qty. to Handle (Base)" + RemainingQtyToApplyBase);
                        RemainingQtyToApplyBase := 0;
                    end;

                    // Update Zone Code Bin Code on Place Lines
                    if WhseActLine."Action Type" = WhseActLine."Action Type"::Place then

                        // Reset the zone code to handle scenarios where the user selects a bin from another zone
                        if WhseActLine."Bin Code" <> _BinCode then begin
                            WhseActLine."Zone Code" := '';
                            WhseActLine.Validate("Bin Code", _BinCode);
                            WhseActLine."Zone Code" := MobWmsToolbox.GetZoneFromBin(WhseActLine."Location Code", WhseActLine."Bin Code");
                        end;

                    WhseActLine.Modify();
                end;
            until (WhseActLine.Next() = 0) or (RemainingQtyToApplyBase = 0);

        if RemainingQtyToApplyBase <> 0 then
            Error(UnableToApplyErr, RemainingQtyToApplyBase, _MobLicensePlateContent."No.");
    end;
}
