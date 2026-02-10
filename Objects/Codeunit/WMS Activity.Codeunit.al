codeunit 81399 "MOB WMS Activity"
// Higher level Warehouse related processing
{
    Access = Public;

    var
        MobSessionData: Codeunit "MOB SessionData";
        MUST_BE_TEMPORARY_Err: Label 'Internal error: %1 must be a temporary record.', Locked = true;
        RelatedLicensePlatesDetectedErr: Label 'One or more related License Plates exists for this order.\\Please use the ''%1'' function.', Comment = '%1 is the name of the Put-Away License Plate function';

    trigger OnRun()
    begin
    end;

    local procedure CreateWhseActHeaderResponse(var _WhseActHeader: Record "Warehouse Activity Header"; var _BaseOrderElement: Record "MOB NS BaseDataModel Element")
    var
        MobSetup: Record "MOB Setup";
    begin
        MobSetup.Get();
        // buffer
        // Setting filter to enable calculation of "MOB No. of Lines".
        // If _WhseActHeader."Location Code"."Bin Mandatory" then select either Place or Take lines depending on Type.
        // If not _WhseActHeader."Location Code"."Bin Mandatory" then select the blank Action Type lines.
        // Both types will never co-exit on the same Warehouse Activity Header.
        case _WhseActHeader.Type of
            _WhseActHeader.Type::"Put-away", _WhseActHeader.Type::"Invt. Put-away":
                _WhseActHeader.SetFilter("MOB Action Type Filter", '%1|%2', _WhseActHeader."MOB Action Type Filter"::" ", _WhseActHeader."MOB Action Type Filter"::Place);
            else
                // All other action types (Pick, Invt. Pick, Movement, Invt. Movement) use take
                _WhseActHeader.SetFilter("MOB Action Type Filter", '%1|%2', _WhseActHeader."MOB Action Type Filter"::" ", _WhseActHeader."MOB Action Type Filter"::Take);
        end;

        if MobSetup."Post breakbulk automatically" then
            _WhseActHeader.SetRange("MOB Breakbulk No. Filter", 0);

        _WhseActHeader.SetAutoCalcFields("MOB No. of Lines");

        if _WhseActHeader.FindSet() then
            repeat
                // Collect buffer values for the <Order> element and add it to the <Orders> node
                _BaseOrderElement.Create();
                SetFromWhseActivityHeader(_WhseActHeader, _BaseOrderElement);
                _BaseOrderElement.Save();
            until _WhseActHeader.Next() = 0;
    end;

    procedure CreateWhseActLinesResponse(var _XmlResponseDoc: XmlDocument; _OrderNo: Code[20])
    var
        WhseActHeader: Record "Warehouse Activity Header";
        PrimaryWhseActLine: Record "Warehouse Activity Line";
        PairedWhseActLine: Record "Warehouse Activity Line";
        OriginalWhseActLineTake: Record "Warehouse Activity Line";
        ReservationEntry: Record "Reservation Entry";
        TempReservationEntry: Record "Reservation Entry" temporary;
        MobSetup: Record "MOB Setup";
        TempLineElement: Record "MOB NS BaseDataModel Element" temporary;
        MobTrackingSetup: Record "MOB Tracking Setup";
        MobToolbox: Codeunit "MOB Toolbox";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        MobWmsPick: Codeunit "MOB WMS Pick";
        MobWmsPutAway: Codeunit "MOB WMS Put Away";
        MobWmsMove: Codeunit "MOB WMS Move";
        MobLicensePlateMgt: Codeunit "MOB License Plate Mgt";
        RecRefPick: RecordRef;
        XmlResponseData: XmlNode;
        ExpDateRequired: Boolean;
        LineType: Code[30];
        FromBin: Code[20];
        ToBin: Code[20];
        LineNoPrefix: Text[1024];
        PrefixedLineNosCleared: Boolean;
        IsAnyPick: Boolean;
        IsAnyPutAway: Boolean;
        IsAnyMovement: Boolean;
        IncludeInOrderLines: Boolean;
    begin
        // Initialize the response document for order line data
        MobToolbox.InitializeOrderLineDataRespDoc(_XmlResponseDoc, XmlResponseData);

        // Filter on the order no.
        // Since we are NOT filtering on the Type the search can potentially return more than one result
        // This can happen if the same numbers are used in different warehouse activities.
        // This is not "best practice" and we need to make sure that it does not happen
        WhseActHeader.SetRange("No.", _OrderNo);

        if (WhseActHeader.Count()) > 1 then
            Error(MobWmsLanguage.GetMessage('WHSE_ACT_NOT_UNIQUE'), _OrderNo);

        if WhseActHeader.FindFirst() then begin
            // Filter the "take" lines
            MobSetup.Get();

            GetTypesFromWhseActHeader(WhseActHeader, IsAnyPutAway, IsAnyPick, IsAnyMovement);

            case true of
                IsAnyPick:
                    case MobSetup."Sort Order Pick" of
                        MobSetup."Sort Order Pick"::Worksheet:
                            PrimaryWhseActLine.SetCurrentKey("Activity Type", "No.", "Sorting Sequence No.");
                        MobSetup."Sort Order Pick"::Item:
                            PrimaryWhseActLine.SetCurrentKey("Activity Type", "No.", "Item No.", "Variant Code", "Action Type", "Bin Code");
                        MobSetup."Sort Order Pick"::Bin:
                            PrimaryWhseActLine.SetCurrentKey("Activity Type", "No.", "Action Type", "Bin Code");
                    end;

                IsAnyPutAway:
                    begin
                        if MobLicensePlateMgt.RelatedLicensePlatesExists(WhseActHeader) then
                            Error(RelatedLicensePlatesDetectedErr, MobWmsLanguage.GetMessage('MainMenuPutAwayLicensePlate'));

                        case MobSetup."Sort Order Put-away" of
                            MobSetup."Sort Order Put-away"::Worksheet:
                                PrimaryWhseActLine.SetCurrentKey("Activity Type", "No.", "Sorting Sequence No.");
                            MobSetup."Sort Order Put-away"::Item:
                                PrimaryWhseActLine.SetCurrentKey("Activity Type", "No.", "Item No.", "Variant Code", "Action Type", "Bin Code");
                            MobSetup."Sort Order Put-away"::Bin:
                                PrimaryWhseActLine.SetCurrentKey("Activity Type", "No.", "Action Type", "Bin Code");
                        end;
                    end;

                IsAnyMovement:
                    case MobSetup."Sort Order Movement" of
                        MobSetup."Sort Order Movement"::Worksheet:
                            PrimaryWhseActLine.SetCurrentKey("Activity Type", "No.", "Sorting Sequence No.");
                        MobSetup."Sort Order Movement"::Item:
                            PrimaryWhseActLine.SetCurrentKey("Activity Type", "No.", "Item No.", "Variant Code", "Action Type", "Bin Code");
                        MobSetup."Sort Order Movement"::Bin:
                            PrimaryWhseActLine.SetCurrentKey("Activity Type", "No.", "Action Type", "Bin Code");
                    end;
            end;

            // Filter the "take" lines
            PrimaryWhseActLine.SetRange("Activity Type", WhseActHeader.Type);
            PrimaryWhseActLine.SetRange("No.", WhseActHeader."No.");

            // Never show break bulk lines on the mobile device
            // Break bulk lines are assigned a break bulk no (the "Breakbulk" field cannot be used - it's not set when the pick is created)
            if MobSetup."Post breakbulk automatically" then
                PrimaryWhseActLine.SetFilter("Breakbulk No.", '=0');

            LineType := SetWhseActLineFilter(PrimaryWhseActLine, WhseActHeader);

            //
            // Event to expose Lines for filtering before Response
            //
            case true of
                IsAnyPick:
                    MobWmsPick.OnGetPickOrderLines_OnSetFilterWarehouseActivityLine(PrimaryWhseActLine);
                IsAnyPutAway:
                    MobWmsPutAway.OnGetPutAwayOrderLines_OnSetFilterWarehouseActivityLine(PrimaryWhseActLine);
                IsAnyMovement:
                    MobWmsMove.OnGetMoveOrderLines_OnSetFilterWarehouseActivityLine(PrimaryWhseActLine);
            end;

            // In this version only 1 take and 1 place line is supported
            // 1.   Find all the take lines (and the ones with ActionType='')
            // 1.2. Fill the line values (FromBin)
            // 1.3  Find the matching place line and fill the ToBin
            if PrimaryWhseActLine.FindSet() then begin

                //
                // Event Add collectorSteps to be displayed on posting
                //
                case true of
                    IsAnyPick:
                        begin
                            RecRefPick.GetTable(WhseActHeader);
                            MobWmsPick.AddStepsToAnyHeader(RecRefPick, _XmlResponseDoc, XmlResponseData);
                        end;
                    IsAnyPutAway:
                        MobWmsPutAway.AddStepsToWarehouseActivityHeader(WhseActHeader, _XmlResponseDoc, XmlResponseData);
                    IsAnyMovement:
                        MobWmsMove.AddStepsToWarehouseActvityHeader(WhseActHeader, _XmlResponseDoc, XmlResponseData);
                end;

                repeat

                    // Verify conditions from eventsubscribers
                    IncludeInOrderLines := true;
                    case true of
                        IsAnyPick:
                            MobWmsPick.OnGetPickOrderLines_OnIncludeWarehouseActivityLine(PrimaryWhseActLine, IncludeInOrderLines);
                        IsAnyPutAway:
                            // 'WhseActLineTake' is really a Place line for PutAway
                            MobWmsPutAway.OnGetPutAwayOrderLines_OnIncludeWarehouseActivityLine(PrimaryWhseActLine, IncludeInOrderLines);
                        IsAnyMovement:
                            MobWmsMove.OnGetMoveOrderLines_OnIncludeWarehouseActivityLine(PrimaryWhseActLine, IncludeInOrderLines);
                    end;

                    if IncludeInOrderLines then begin
                        // Determine if serial / lot / package number registration is needed
                        MobTrackingSetup.DetermineItemTrackingRequired(PrimaryWhseActLine, ExpDateRequired);
                        // MobTrackingSetup.Tracking: Copy later (only after PrimaryWhseActLine tracking has been updated below)

                        // Insert Reservation Entry loop
                        // To be able to check that the correct serial/lot is picked, we need to find possible reservation entries with item tracking.
                        // First we build a list of Tracked Reservations and then we create a Line on the scanner for each reservation.
                        if MobTrackingSetup.TrackingRequired() then
                            BuildTrackedReservationsList(PrimaryWhseActLine, TempReservationEntry, PrefixedLineNosCleared);

                        // Save this value for calculating how many pick lines are needed.
                        // Must be Copy rather than assigment for performance reasons (Record := Record performing very poorly with 1500+ lines - solved in BC16)
                        OriginalWhseActLineTake.Copy(PrimaryWhseActLine);

                        LineNoPrefix := 'P000';
                        while OriginalWhseActLineTake."Qty. Outstanding (Base)" > 0 do begin  // > 0 ensures that the code is always run once (i.e. no reservations found we still need a pick line)
                            if TempReservationEntry.FindFirst() then begin
                                // Update the reservation entry with the prefixed line number
                                // This allows the posting function to update the correct reservation entry
                                // "Prefixed Line No." = "LineNumber" on the mobile device
                                PrimaryWhseActLine."Qty. Outstanding (Base)" := -TempReservationEntry."Quantity (Base)";  // When the Reservation Entry is Outbound, the Quantity will be negative for a positive WhseActLine
                                PrimaryWhseActLine."Qty. Outstanding" := -TempReservationEntry.Quantity;
                                OriginalWhseActLineTake."Qty. Outstanding (Base)" += TempReservationEntry."Quantity (Base)";
                                OriginalWhseActLineTake."Qty. Outstanding" += TempReservationEntry.Quantity;
                                LineNoPrefix := IncStr(LineNoPrefix);
                                ReservationEntry.Get(TempReservationEntry."Entry No.", TempReservationEntry.Positive);
                                ReservationEntry.MOBPrefixedLineNo := LineNoPrefix + Format(PrimaryWhseActLine."Line No.");
                                ReservationEntry.Modify();
                                TempReservationEntry.Delete();
                            end else begin
                                PrimaryWhseActLine := OriginalWhseActLineTake;
                                // If we run out of reservation entries, we want no more runs in the QtyOutstandingBase > 0 loop
                                OriginalWhseActLineTake."Qty. Outstanding (Base)" := 0;
                                // Avoid stale variables
                                Clear(ReservationEntry);
                                Clear(TempReservationEntry);
                            end;

                            // Determine From/To bin
                            case LineType of
                                'TAKE':
                                    begin
                                        // Only take lines exist -> set the from bin
                                        FromBin := PrimaryWhseActLine."Bin Code";
                                        ToBin := '';
                                    end;
                                'PLACE':
                                    begin
                                        // Only place lines exist -> set the to bin
                                        FromBin := '';
                                        ToBin := PrimaryWhseActLine."Bin Code";
                                    end;
                                'BLANK':
                                    begin
                                        // Bins are not used
                                        FromBin := '';
                                        ToBin := '';
                                    end;
                                'TAKE_PLACE_PAIR_PUT_AWAY':
                                    begin
                                        // A take place pair exist -> from bin = take line, to bin = place line
                                        ToBin := PrimaryWhseActLine."Bin Code";

                                        // Now find the take line
                                        FindTakeLine(PairedWhseActLine, WhseActHeader, PrimaryWhseActLine);
                                        FromBin := PairedWhseActLine."Bin Code"
                                    end;
                                'TAKE_PLACE_PAIR_PICK',
                                'TAKE_PLACE_PAIR_MOVE':
                                    begin
                                        // A take place pair exist -> from bin = take line, to bin = place line
                                        FromBin := PrimaryWhseActLine."Bin Code";

                                        // Now find the place line
                                        FindPlaceLine(PairedWhseActLine, WhseActHeader, PrimaryWhseActLine);
                                        ToBin := PairedWhseActLine."Bin Code";   // may be empty
                                    end;
                            end;

                            // Tracking is stored as MobTrackingSetup rather than using PrimaryWhseActLine as placeholder (as in earlier releases)
                            // Copy Tracking from Acitivity Line, then overwrite with individual Tracking values from Reservation Entry if a specific reservation exists (but after first PlaceLine has been found).
                            // MobTrackingSetup.TrackingRequired: Determined before (per PrimaryWhseActLine)
                            MobTrackingSetup.CopyTrackingFromWhseActivityLine(PrimaryWhseActLine);
                            MobTrackingSetup.CopyTrackingFromReservEntryIfNotBlank(TempReservationEntry);   // Overwrite individual values if found from Reservation Entry

                            // Add the data to the receive orders element
                            TempLineElement.Create();
                            SetFromWhseActivityLine(WhseActHeader, PrimaryWhseActLine, MobTrackingSetup, PairedWhseActLine, TempLineElement, ReservationEntry, FromBin, ToBin, ExpDateRequired);
                            TempLineElement.Save();

                        end;  // Reservation Entry WHILE loop
                        TempReservationEntry.DeleteAll();  // Make sure no surplus reservations exist - this can happen with several Pick Lines for one Warehouse Shipment Line
                    end; // IncludeInOrderLines

                until PrimaryWhseActLine.Next() = 0;
            end;

            AddBaseOrderLineElements(WhseActHeader, XmlResponseData, TempLineElement);
        end;
    end;

    procedure GetPutAwayOrders(var _XmlRequestDoc: XmlDocument; var _WhseActHeader: Record "Warehouse Activity Header"; var _MobDocQueue: Record "MOB Document Queue"; var _BaseOrderElement: Record "MOB NS BaseDataModel Element")
    begin
        GetOrders(_XmlRequestDoc, _WhseActHeader, _MobDocQueue, _BaseOrderElement, true, false, false);
    end;

    procedure GetPickOrders(var _XmlRequestDoc: XmlDocument; var _WhseActHeader: Record "Warehouse Activity Header"; var _MobDocQueue: Record "MOB Document Queue"; var _BaseOrderElement: Record "MOB NS BaseDataModel Element")
    begin
        GetOrders(_XmlRequestDoc, _WhseActHeader, _MobDocQueue, _BaseOrderElement, false, true, false);
    end;

    procedure GetMoveOrders(var _XmlRequestDoc: XmlDocument; var _WhseActHeader: Record "Warehouse Activity Header"; var _MobDocQueue: Record "MOB Document Queue"; var _BaseOrderElement: Record "MOB NS BaseDataModel Element")
    begin
        GetOrders(_XmlRequestDoc, _WhseActHeader, _MobDocQueue, _BaseOrderElement, false, false, true);
    end;

    local procedure GetOrders(var _XmlRequestDoc: XmlDocument; var _WhseActHeader: Record "Warehouse Activity Header"; var _MobDocQueue: Record "MOB Document Queue"; var _BaseOrderElement: Record "MOB NS BaseDataModel Element"; _IsAnyPutAway: Boolean; _IsAnyPick: Boolean; _IsAnyMovement: Boolean)
    var
        WhseActLine: Record "Warehouse Activity Line";
        TempHeaderFilter: Record "MOB NS Request Element" temporary;
        TempWhseActHeader: Record "Warehouse Activity Header" temporary;
        MobBaseDocHandler: Codeunit "MOB WMS Base Document Handler";
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
        MobWmsPick: Codeunit "MOB WMS Pick";
        MobWmsPutAway: Codeunit "MOB WMS Put Away";
        MobWmsMove: Codeunit "MOB WMS Move";
        MobRequestMgt: Codeunit "MOB NS Request Management";
        MobScannedValueMgt: Codeunit "MOB ScannedValue Mgt.";
        IsHandled: Boolean;
        ScannedValue: Text;
    begin
        // Respond with a list of Warehouse Activitiy Headers (Pick, Put-away etc.)

        // Mandatory Header filters for this function to operate
        _WhseActHeader.SetFilter("Location Code", MobWmsToolbox.GetLocationFilter(_MobDocQueue."Mobile User ID"));

        // XML filter data into Temporary table
        MobRequestMgt.SaveHeaderFilters(_XmlRequestDoc, TempHeaderFilter);

        if TempHeaderFilter.FindSet() then
            repeat

                // Event to allow for handling (custom) filters
                IsHandled := false;
                if _IsAnyPick then
                    MobWmsPick.OnGetPickOrders_OnSetFilterWarehouseActivity(TempHeaderFilter, _WhseActHeader, WhseActLine, IsHandled);
                if _IsAnyPutAway then
                    MobWmsPutAway.OnGetPutAwayOrders_OnSetFilterWarehouseActivity(TempHeaderFilter, _WhseActHeader, WhseActLine, IsHandled);
                if _IsAnyMovement then
                    MobWmsMove.OnGetMoveOrders_OnSetFilterWarehouseActivity(TempHeaderFilter, _WhseActHeader, WhseActLine, IsHandled);

                if not IsHandled then
                    case TempHeaderFilter.Name of

                        'Location':
                            if TempHeaderFilter."Value" = 'All' then
                                // Set the location filter to all locations
                                _WhseActHeader.SetFilter("Location Code", MobWmsToolbox.GetLocationFilter(_MobDocQueue."Mobile User ID"))
                            else
                                // Set the filter to the specific location
                                _WhseActHeader.SetRange("Location Code", TempHeaderFilter."Value");

                        'ScannedValue':
                            ScannedValue := TempHeaderFilter."Value";   // Used for filtering DocumentNo or Item/Variant later

                        'AssignedUser':
                            case TempHeaderFilter."Value" of
                                'All':
                                    ; // No action required for All
                                'OnlyMine':
                                    // Set the filter to the current user
                                    _WhseActHeader.SetRange("Assigned User ID", _MobDocQueue."Mobile User ID");
                                'MineAndUnassigned':
                                    // Set the filter to the current user + blank
                                    _WhseActHeader.SetFilter("Assigned User ID", '''''|%1', _MobDocQueue."Mobile User ID");
                            end;
                    end;

            until TempHeaderFilter.Next() = 0;

        // Run event once more with Empty "Header filter" to allow for additional filtering directly on the records, NOT related to specific Header filter
        Clear(IsHandled);
        TempHeaderFilter.ClearFields();
        if _IsAnyPick then
            MobWmsPick.OnGetPickOrders_OnSetFilterWarehouseActivity(TempHeaderFilter, _WhseActHeader, WhseActLine, IsHandled);
        if _IsAnyPutAway then
            MobWmsPutAway.OnGetPutAwayOrders_OnSetFilterWarehouseActivity(TempHeaderFilter, _WhseActHeader, WhseActLine, IsHandled);
        if _IsAnyMovement then
            MobWmsMove.OnGetMoveOrders_OnSetFilterWarehouseActivity(TempHeaderFilter, _WhseActHeader, WhseActLine, IsHandled);

        // Filter: DocumentNo or Item/Variant (match for scanned document no. at location takes precedence over other filters)
        if ScannedValue <> '' then
            MobScannedValueMgt.SetFilterForWhseActivity(_WhseActHeader, WhseActLine, ScannedValue);

        // Insert orders into temp rec
        MobBaseDocHandler.CopyFilteredWhseActivityHeadersToTempRecord(_WhseActHeader, WhseActLine, TempHeaderFilter, TempWhseActHeader, _IsAnyPutAway, _IsAnyPick, _IsAnyMovement);

        // Respond with resulting orders
        // Create the response based on the temporary warehouse activity header
        CreateWhseActHeaderResponse(TempWhseActHeader, _BaseOrderElement);
    end;

    procedure PostWhseActivityOrder(_PostingMessageId: Guid; var _XmlRequestDoc: XmlDocument; _RegistrationType: Enum "MOB WMS Registration Type"; var _ReturnSteps: Record "MOB Steps Element"; var _ResultMessage: Text)
    var
        WhseActHeader: Record "Warehouse Activity Header";
        WhseActLine: Record "Warehouse Activity Line";
        WhseActLinePost: Record "Warehouse Activity Line";
        TempWhseActLine: Record "Warehouse Activity Line" temporary;
        TempReservationEntryLog: Record "Reservation Entry" temporary;
        TempNewReservationEntry: Record "Reservation Entry" temporary;
        MobSetup: Record "MOB Setup";
        MobReportPrintSetup: Record "MOB Report Print Setup";
        MobWmsRegistration: Record "MOB WMS Registration";
        TempOrderValues: Record "MOB Common Element" temporary;
        MobSyncItemTracking: Codeunit "MOB Sync. Item Tracking";
        WhseActRegister: Codeunit "Whse.-Activity-Register";
        WhseActPost: Codeunit "Whse.-Activity-Post";
        MobTryEvent: Codeunit "MOB Try Event";
        WMSMgt: Codeunit "WMS Management";
        MobToolbox: Codeunit "MOB Toolbox";
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        MobRequestMgt: Codeunit "MOB NS Request Management";
        MobWmsPutAway: Codeunit "MOB WMS Put Away";
        MobWmsPick: Codeunit "MOB WMS Pick";
        MobWmsMove: Codeunit "MOB WMS Move";
        HeaderRecRef: RecordRef;
        OrderID: Code[20];
        LineType: Code[30];
        IsAnyPick: Boolean;
        IsAnyPutAway: Boolean;
        IsAnyMovement: Boolean;
        PostingRunSuccessful: Boolean;
        PostedDocExists: Boolean;
        IsHandled: Boolean;
        HandledResultMessage: Text;
        WhseActLineNo: Integer;
    begin
        // This function is used to post:
        // - Warehouse picks/put-aways
        // - Inventory picks/put-aways
        // - Movements

        // The warehouse and inventory orders are posted differently.
        // Warehouse uses the "Whse.-Activity-Register" codeunit
        // Inventory uses the "Whse.-Activity-Post" codeunit

        // NOTE !!!!
        // This codeunit assumes that the order numbers are unique
        // This will be true in most circumstances since it is good practice to name the different order types differently.
        // If a search for a specific order number returns more than one result an error will be generated
        // NOTE !!!!

        // 1. Determine which type to post
        // 2. Save the registrations from the XML in the database
        // 3. Set the registration values on the Take and Place lines
        // 4. Post

        // The XML looks like this:
        // <request name="PostXXXOrder" created="2009-02-20T13:32:10-08:00" xmlns="http://schemas.microsoft.com/Dynamics/Mobile/2007/04/Doc
        // <requestData name="PostXXXOrder">
        // <Order backendID="PU000059" xmlns="http://schemas.taskletfactory.com/MobileWMS/RegistrationData">
        // <Line lineNumber="10000">
        // <Registration>
        // <FromBin/>
        // <ToBin>W-08-0001</ToBin>
        // <SerialNumber/>
        // <LotNumber>MyTestLot15</LotNumber>
        // <Quantity>15</Quantity>
        // <UnitOfMeasure/>
        // </Registration>
        // </Line>
        // </Order>
        // </requestData>
        // </request>

        // Disable the locktimeout to prevent timeout messages on the mobile device
        LockTimeout(false);

        // Turn on commit protection to prevent unintentional committing data
        MobWmsRegistration.Consistent(false);

        // Lock the tables to work on
        WhseActHeader.LockTable();
        WhseActLine.LockTable();
        MobWmsRegistration.LockTable();

        MobSetup.Get();

        // Load the request document header steps
        MobRequestMgt.InitCommonFromXmlOrderNode(_XmlRequestDoc, TempOrderValues);

        // Save the registrations from the XML in the Mobile WMS Registration table
        OrderID := MobWmsToolbox.SaveRegistrationData(_PostingMessageId, _XmlRequestDoc, _RegistrationType);

        // Find the warehouse activity header
        // Since the filtering on the Type is not unique the search can potentially return more than one result
        // This can happen if the same numbers are used in different warehouse activities.
        // This is not "best practice" and we need to make sure that it does not happen
        FilterWhseActHeader(OrderID, _RegistrationType, WhseActHeader);

        // Make sure that the order still exists
        if not WhseActHeader.FindSet() then
            Error(MobWmsLanguage.GetMessage('UNKNOWN_ORDER'), OrderID);

        if WhseActHeader.Next() <> 0 then  // Check that we only have 1 record within current filter on OrderID
            Error(MobWmsLanguage.GetMessage('WHSE_ACT_NOT_UNIQUE'), OrderID);

        WhseActHeader.Validate("Posting Date", WorkDate());
        WhseActHeader."MOB Posting MessageId" := _PostingMessageId;

        GetTypesFromWhseActHeader(WhseActHeader, IsAnyPutAway, IsAnyPick, IsAnyMovement);

        // Backwards compatibility: Ensure MOBSystemID is set at all Warehouse Activity Lines
        PopulateWhseActLineMOBSystemId(WhseActHeader);

        // Syncronize MOBSystemID: RegistrationData and WarehouseActivityLines must be able to match up by MOBSystemID rather than "Line No." to prevent issues stemming from RenumberLines
        SyncMOBSystemIdToMobRegistration(WhseActHeader, _RegistrationType, OrderID);

        // Reset the filter to leave the variable unchanged
        MobWmsRegistration.Reset();

        //
        // OnAddStepsTo IntegrationEvents
        //
        if IsAnyPutAway then
            MobWmsPutAway.OnPostPutAwayOrder_OnAddStepsToWarehouseActivityHeader(TempOrderValues, WhseActHeader, _ReturnSteps);
        if IsAnyPick then begin
            MobWmsPick.OnPostPickOrder_OnAddStepsToWarehouseActivityHeader(TempOrderValues, WhseActHeader, _ReturnSteps);
            HeaderRecRef.GetTable(WhseActHeader);
            MobWmsPick.OnPostPickOrder_OnAddStepsToAnyHeader(TempOrderValues, HeaderRecRef, _ReturnSteps);
            HeaderRecRef.SetTable(WhseActHeader);
        end;
        if IsAnyMovement then
            MobWmsMove.OnPostMoveOrder_OnAddStepsToWarehouseActivityHeader(TempOrderValues, WhseActHeader, _ReturnSteps);
        if not _ReturnSteps.IsEmpty() then begin
            MobSessionData.SetRegistrationTypeTracking('OnAddStepsTo');
            MobWmsToolbox.DeleteRegistrationData(_PostingMessageId);
            MobWmsRegistration.Consistent(true);
            exit;   // Interrupt posting and return extra Steps to be displayed at the mobile device
        end;

        //
        // OnBeforePost IntegrationEvents
        //
        if IsAnyPutAway then
            MobWmsPutAway.OnPostPutAwayOrder_OnBeforePostWarehouseActivityOrder(TempOrderValues, WhseActHeader);
        if IsAnyPick then begin
            MobWmsPick.OnPostPickOrder_OnBeforePostWarehouseActivityOrder(TempOrderValues, WhseActHeader);
            HeaderRecRef.GetTable(WhseActHeader);
            MobWmsPick.OnPostPickOrder_OnBeforePostAnyOrder(TempOrderValues, HeaderRecRef);
            HeaderRecRef.SetTable(WhseActHeader);
        end;
        if IsAnyMovement then
            MobWmsMove.OnPostMoveOrder_OnBeforePostWarehouseActivityOrder(TempOrderValues, WhseActHeader);
        WhseActHeader.Modify();

        //
        // Iterate WhseActLines and handle all registrations for the single line or matching pair
        // 
        if WhseActHeader.FindFirst() then begin

            // Get the warehouse activity lines
            // Loop through them and set all "qty to handle" to the registered qty (or zero if the reg. does not exist)
            WhseActLine.Reset();
            WhseActLine.SetRange("No.", OrderID);
            WhseActLine.SetRange("Activity Type", WhseActHeader.Type);

            // Save the original warehouse activity lines in case we need to revert split lines (if the posting fails)
            if WhseActLine.FindSet() then
                repeat
                    TempWhseActLine.Copy(WhseActLine);
                    TempWhseActLine.Insert();
                until WhseActLine.Next() = 0;

            // Set the qty to handle to zero to avoid posting lines not registered on the mobile device
            ResetQtyToHandle(WhseActLine);

            // The correct action type filter to use is calculated (see the function for more details)
            // The line type tells if there are one or two lines per order line on the mobile device
            LineType := SetWhseActLineFilter(WhseActLine, WhseActHeader);

            // When we loop over the lines we want to make sure that we do not get the lines that were split automatically
            WhseActLine.SetRange(MOBLineSplitAutomatically, false);

            // Save the original reservation entries in case we need to revert (if the posting fails)
            MobSyncItemTracking.SaveOriginalReservationEntriesForWhseActivityLines(WhseActLine, TempReservationEntryLog);

            // Breakbulk Lines have already been handled in procedure ResetQtyToHandle
            if MobSetup."Post breakbulk automatically" then
                WhseActLine.SetRange("Breakbulk No.", 0);

            // Usually the "primary" WhseActLine (the instance controlling the loop) is TAKE lines, but in case of Put-away: PLACE lines
            // The line numbers in the XML is from the take lines
            // 1. Fill the TAKE(/PLACE) or "blank" line
            // 2. Fill the PLACE(/TAKE) line (if it exists)
            // When done with loop -> set order filter and post

            if WhseActLine.FindSet() then
                repeat
                    WhseActLineNo := 0; // Initialize output variable

                    // Note: No MobWmsRegistration input here
                    // In case of a "paired" Whse. Activity Line the "other leg" of the TAKE/PLACE-pair is handled here as well
                    HandleRegistrationsForWhseActLine(
                        _RegistrationType,
                        OrderID,
                        LineType,
                        WhseActHeader,
                        IsAnyPick,
                        IsAnyPutAway,
                        IsAnyMovement,
                        WhseActLine,                // not a var, is modified in procedure but also reset+read below
                        WhseActLineNo,              // var (out): To specify the current line no in case of line splitting and re-numbering
                        TempNewReservationEntry);      // var 

                    // Move Line No. "pointer" as re-numbering may have moved the lines to a lower range and could therefor skip lines if we do not ensure the pointer is correct
                    if (WhseActLineNo <> 0) and (WhseActLineNo <> WhseActLine."Line No.") then
                        WhseActLine."Line No." := WhseActLineNo;

                until WhseActLine.Next() = 0;

            // We have now finished looping over the original order lines
            // The split lines were excluded from this loop by setting the LineSplitAutomatically flag
            // It is important that the flag is removed, because if the line is not fully posted then it needs to be
            // treated as a normal line on the next post.
            WhseActLine.Reset();
            WhseActLine.SetRange("No.", OrderID);
            WhseActLine.SetRange("Activity Type", WhseActHeader.Type);
            WhseActLine.ModifyAll(MOBLineSplitAutomatically, false);

            // Filter again to get both the take and place lines -> then post
            WhseActLinePost.SetRange("Activity Type", WhseActHeader.Type);
            WhseActLinePost.SetRange("No.", OrderID);
            WhseActLinePost.FindSet();

            // Make sure that no windows are shown during the posting process
            WhseActRegister.ShowHideDialog(true);
            WhseActPost.ShowHideDialog(true);

            // Invt. Pick - Set Print Shipment (before OnPostPickOrder_OnBeforeRunWhseActivityPost)
            if (WhseActHeader.Type = WhseActHeader.Type::"Invt. Pick") and (MobReportPrintSetup.PrintShipmentOnPostEnabled()) then
                WhseActPost.PrintDocument(true);

            // Events OnBeforePost/OnBeforeRegister
            IsHandled := false;
            HandledResultMessage := '';

            if IsAnyPutAway then
                if WhseActLinePost."Activity Type" = WhseActLinePost."Activity Type"::"Invt. Put-away" then
                    MobWmsPutAway.OnPostPutAwayOrder_OnBeforeRunWhseActivityPost(WhseActLinePost, WhseActPost, IsHandled, HandledResultMessage)
                else
                    MobWmsPutAway.OnPostPutAwayOrder_OnBeforeRunWhseActivityRegister(WhseActLinePost, WhseActRegister, IsHandled, HandledResultMessage);

            if IsAnyPick then
                if WhseActLinePost."Activity Type" = WhseActLinePost."Activity Type"::"Invt. Pick" then
                    MobWmsPick.OnPostPickOrder_OnBeforeRunWhseActivityPost(WhseActLinePost, WhseActPost, IsHandled, HandledResultMessage)
                else
                    MobWmsPick.OnPostPickOrder_OnBeforeRunWhseActivityRegister(WhseActLinePost, WhseActRegister, IsHandled, HandledResultMessage);

            if IsAnyMovement then
                MobWmsMove.OnPostMoveOrder_OnBeforeRunWhseActivityRegister(WhseActLinePost, WhseActRegister, IsHandled, HandledResultMessage);

            // Skip the remaining validation and posting if the *_OnBeforeRunWhseActivity* event has handled the document
            if IsHandled then begin
                UpdateIncomingWarehouseActivityOrder(WhseActHeader);
                MobWmsRegistration.Consistent(true);
                Commit();

                if HandledResultMessage <> '' then
                    _ResultMessage := HandledResultMessage
                else
                    _ResultMessage := MobToolbox.GetPostSuccessMessage(true);

                exit;
            end;

            // Check balance on everything having Take/Place lines
            if ((WhseActLinePost."Activity Type" <> WhseActLinePost."Activity Type"::"Invt. Put-away") and
                (WhseActLinePost."Activity Type" <> WhseActLinePost."Activity Type"::"Invt. Pick"))
            then
                WMSMgt.CheckBalanceQtyToHandle(WhseActLinePost);

            // Turn off commit protection that was enabled while MobRegistrations was still marked as unhandled
            MobWmsRegistration.Consistent(true);

            Commit();

            // Clear QtyToHandle on everything except our own "staged" (not-posted) Reservation Entries from Picks
            MobSyncItemTracking.SetSuppressClearQtyToHandle(WhseActLinePost."Activity Type" = WhseActLinePost."Activity Type"::Pick);

            if not MobSyncItemTracking.Run(TempNewReservationEntry) then begin
                _ResultMessage := GetLastErrorText();
                MobSessionData.SetPreservedLastErrorCallStack();
                RevertToOriginalLines(TempWhseActLine);
                MobSyncItemTracking.RevertToOriginalReservationEntriesForWhseActivityLines(WhseActLine, TempReservationEntryLog);
                Commit();
                UpdateIncomingWarehouseActivityOrder(WhseActHeader);
                MobWmsToolbox.DeleteRegistrationData(_PostingMessageId);
                Commit();   // Separate commit to prevent error in UpdateIncomingWarehouseActivityOrder from preventing Reservation Entries being rollback
                Error(_ResultMessage);
            end;

            // Determine which posting codeunit to call
            if ((WhseActLinePost."Activity Type" = WhseActLinePost."Activity Type"::"Invt. Put-away") or
               (WhseActLinePost."Activity Type" = WhseActLinePost."Activity Type"::"Invt. Pick"))
            then
                PostingRunSuccessful := WhseActPost.Run(WhseActLinePost)
            else
                PostingRunSuccessful := WhseActRegister.Run(WhseActLinePost);

            // If Posted Warehouse Activity Exists Posting has succeeded but something else failed. ie. partner code OnAfter event
            if not PostingRunSuccessful then
                PostedDocExists := PostedWhseActivityExists(WhseActHeader);

            if PostingRunSuccessful or PostedDocExists then begin
                _ResultMessage := MobToolbox.GetPostSuccessMessage(PostingRunSuccessful);

                // Commit to allow for codeunit.run
                Commit();

                // Event OnAfterPost
                case true of
                    IsAnyPick:
                        MobTryEvent.RunEventOnPlannedPosting('OnPostPickOrder_OnAfterPostAnyOrder', WhseActLinePost, TempOrderValues, _ResultMessage);
                    IsAnyPutAway:
                        MobTryEvent.RunEventOnPlannedPosting('OnPostPutAwayOrder_OnAfterPostWarehouseActivity', WhseActLinePost, TempOrderValues, _ResultMessage);
                    IsAnyMovement:
                        MobTryEvent.RunEventOnPlannedPosting('OnPostMoveOrder_OnAfterPostWarehouseActivity', WhseActLinePost, TempOrderValues, _ResultMessage);
                end;

                UpdateIncomingWarehouseActivityOrder(WhseActHeader);

            end else begin

                // The created reservation entries have been committed
                // If the posting fails for some reason we need to clean up the created reservation entries and MobWmsRegistrations
                _ResultMessage := GetLastErrorText();
                MobSessionData.SetPreservedLastErrorCallStack();
                RevertToOriginalLines(TempWhseActLine);
                MobSyncItemTracking.RevertToOriginalReservationEntriesForWhseActivityLines(WhseActLine, TempReservationEntryLog);
                Commit();
                UpdateIncomingWarehouseActivityOrder(WhseActHeader);
                MobWmsToolbox.DeleteRegistrationData(_PostingMessageId);
                Commit();   // Separate commit to prevent error in UpdateIncomingWarehouseActivityOrder from preventing Reservation Entries being rollback
                Error(_ResultMessage);

            end;

            // The post completed successfully
            // If we have posted an outbound transfer order then we automatically create the Warehouse Receipt or invt. put-away
            if (WhseActLinePost."Activity Type" = WhseActLinePost."Activity Type"::"Invt. Pick") and
               (WhseActLinePost."Source Document" = WhseActLinePost."Source Document"::"Outbound Transfer")
            then
                MobWmsToolbox.CreateInboundTransferWarehouseDoc(WhseActLinePost."Source No.");

        end;

    end;

    local procedure FilterWhseActHeader(_OrderID: Code[20]; _RegistrationType: Enum "MOB WMS Registration Type"; var _WhseActHeader: Record "Warehouse Activity Header")
    begin
        case _RegistrationType of
            _RegistrationType::PutAway:
                _WhseActHeader.SetFilter(Type, '%1|%2', _WhseActHeader.Type::"Invt. Put-away", _WhseActHeader.Type::"Put-away");
            _RegistrationType::Pick:
                _WhseActHeader.SetFilter(Type, '%1|%2', _WhseActHeader.Type::"Invt. Pick", _WhseActHeader.Type::Pick);
            _RegistrationType::Move:
                _WhseActHeader.SetFilter(Type, '%1|%2', _WhseActHeader.Type::"Invt. Movement", _WhseActHeader.Type::Movement);
        end;

        _WhseActHeader.SetRange("No.", _OrderID);
    end;

    internal procedure PostedWhseActivityExists(_WhseActHeader: Record "Warehouse Activity Header"): Boolean
    var
        RegisteredWhseActHeader: Record "Registered Whse. Activity Hdr.";
        RegisteredInvtMovementHeader: Record "Registered Invt. Movement Hdr.";
        PostedInvtPickHeader: Record "Posted Invt. Pick Header";
        PostedInvtPutAwayHeader: Record "Posted Invt. Put-away Header";
    begin
        case _WhseActHeader.Type of
            _WhseActHeader."Type"::Movement,
            _WhseActHeader."Type"::Pick,
            _WhseActHeader."Type"::"Put-away":
                begin
                    RegisteredWhseActHeader.SetRange("Whse. Activity No.", _WhseActHeader."No.");
                    RegisteredWhseActHeader.SetRange("MOB MessageId", _WhseActHeader."MOB Posting MessageId");
                    exit(not RegisteredWhseActHeader.IsEmpty());
                end;
            _WhseActHeader."Type"::"Invt. Pick":
                begin
                    PostedInvtPickHeader.SetRange("Invt Pick No.", _WhseActHeader."No.");
                    PostedInvtPickHeader.SetRange("MOB MessageId", _WhseActHeader."MOB Posting MessageId");
                    exit(not PostedInvtPickHeader.IsEmpty());
                end;
            _WhseActHeader."Type"::"Invt. Put-away":
                begin
                    PostedInvtPutAwayHeader.SetRange("Invt. Put-away No.", _WhseActHeader."No.");
                    PostedInvtPutAwayHeader.SetRange("MOB MessageId", _WhseActHeader."MOB Posting MessageId");
                    exit(not PostedInvtPutAwayHeader.IsEmpty());
                end;
            _WhseActHeader."Type"::"Invt. Movement":
                begin
                    RegisteredInvtMovementHeader.SetRange("Invt. Movement No.", _WhseActHeader."No.");
                    RegisteredInvtMovementHeader.SetRange("MOB MessageId", _WhseActHeader."MOB Posting MessageId");
                    exit(not RegisteredInvtMovementHeader.IsEmpty());
                end;
        end;
    end;

    local procedure PopulateWhseActLineMOBSystemId(_WhseActHeader: Record "Warehouse Activity Header")
    var
        WhseActLine: Record "Warehouse Activity Line";
        NullGuid: Guid;
    begin
        // Backwards compatibility: Ensure MOBSystemID is set at all Warehouse Activity Lines
        WhseActLine.Reset();
        WhseActLine.SetRange("Activity Type", _WhseActHeader.Type);
        WhseActLine.SetRange("No.", _WhseActHeader."No.");
        WhseActLine.SetRange(MOBSystemId, NullGuid);
        if WhseActLine.FindSet(true) then
            repeat
                WhseActLine.MOBSystemId := CreateGuid();
                WhseActLine.Modify();
            until WhseActLine.Next() = 0;
    end;

    local procedure SyncMOBSystemIdToMobRegistration(_WhseActHeader: Record "Warehouse Activity Header"; _RegistrationType: Enum "MOB WMS Registration Type"; _OrderID: Code[20])
    var
        WhseActLine: Record "Warehouse Activity Line";
        MobWmsRegistration: Record "MOB WMS Registration";
    begin
        // Syncronize MOBSystemID: RegistrationData and WarehouseActivityLines must be able to match up by MOBSystemID rather than "Line No." to prevent issues stemming from RenumberLines
        MobWmsRegistration.Reset();
        MobWmsRegistration.SetRange(Type, _RegistrationType);
        MobWmsRegistration.SetRange("Order No.", _OrderID);
        MobWmsRegistration.SetRange(Handled, false);
        if MobWmsRegistration.FindSet() then
            repeat
                if WhseActLine.Get(_WhseActHeader.Type, _WhseActHeader."No.", MobWmsRegistration."Line No.") then begin
                    WhseActLine.TestField(MOBSystemId);
                    MobWmsRegistration."Source MOBSystemId" := WhseActLine.MOBSystemId;
                    MobWmsRegistration.Modify();
                end;
            until MobWmsRegistration.Next() = 0;
    end;

    local procedure HandleRegistrationsForWhseActLine(
        _RegistrationType: Enum "MOB WMS Registration Type";
        _OrderID: Code[20];
        _LineType: Code[30];
        _WhseActHeader: Record "Warehouse Activity Header";
        _IsAnyPick: Boolean;
        _IsAnyPutAway: Boolean;
        _IsAnyMovement: Boolean;
        _WhseActLine: Record "Warehouse Activity Line";      // is modified in this procedure, but reset+read where called from, hence not var
        var _WhseActLineNo: Integer;                         // is used to return the line no. of the processed line as it might have changed after a split and re-numbering
        var _TempNewReservationEntry: Record "Reservation Entry" // temporary, must be var
    )
    var
        MobSetup: Record "MOB Setup";
        MobWmsRegistration: Record "MOB WMS Registration";
        PairedMobWmsRegistration: Record "MOB WMS Registration";
        xWhseActLine: Record "Warehouse Activity Line";
        PairedWhseActLine: Record "Warehouse Activity Line";
        MobTrackingSetup: Record "MOB Tracking Setup";
        MobSpecificTrackingSetup: Record "MOB Tracking Setup";
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
        RegisterExpirationDate: Boolean;
        DummyRegisterExpirationDate: Boolean;
        ExpirationDate: Date;
        RegisteredBinCode: Code[50];
        UpdatePairedLine: Boolean;
    begin
        // The WhseActLine may be Action Type::Take or ::Place dependent on LineType
        MobSetup.Get();
        xWhseActLine := _WhseActLine;

        // MOBSystemID is mandatory to match WarehouseActivityLines with MobRegistrations
        _WhseActLine.TestField(MOBSystemId);

        // Try to find the registrations
        // Key MUST exclude "Source MOBSystemId" and "Handled" due to these values being modified during iteration
        MobWmsRegistration.Reset();
        MobWmsRegistration.SetRange(Type, _RegistrationType);
        MobWmsRegistration.SetRange("Order No.", _OrderID);
        MobWmsRegistration.SetRange("Source MOBSystemId", _WhseActLine.MOBSystemId);
        MobWmsRegistration.SetRange(Handled, false);

        if _IsAnyMovement then
            MobWmsRegistration.SetRange(ActionType, 'TAKE');

        // If the registration is found -> set the quantity to handle
        // Else set the quantity to handle to zero (to avoid posting lines with the qty to handle set to something)
        if MobWmsRegistration.FindSet() then begin

            // Find matching opposite action type prior to lines getting manipulated from splits
            UpdatePairedLine := ((_WhseActHeader.Type in [_WhseActHeader.Type::"Put-away", _WhseActHeader.Type::Pick]) or _IsAnyMovement) and MobWmsToolbox.LocationIsBinMandatory(_WhseActLine."Location Code");
            if UpdatePairedLine then
                case xWhseActLine."Action Type" of
                    xWhseActLine."Action Type"::Take:
                        FindPlaceLineWithOutstandingQtyToHandle(PairedWhseActLine, _WhseActHeader, xWhseActLine);
                    xWhseActLine."Action Type"::Place:
                        FindTakeLineWithOutstandingQtyToHandle(PairedWhseActLine, _WhseActHeader, xWhseActLine);
                end;

            // Determine if serial / lot number registration is needed
            // Only verify against existing inventory if "SN Specific Tracking" / "Lot Specific Tracking" is set
            MobSpecificTrackingSetup.DetermineSpecificTrackingRequiredFromItemNo(_WhseActLine."Item No.", DummyRegisterExpirationDate);
            // MobSpecificTrackingSetup.Tracking: Copy later from MobWmsRegistration during CheckRegisteredItemTracking()

            MobTrackingSetup.DetermineItemTrackingRequired(_WhseActLine, RegisterExpirationDate);

            // OnBeforeHandle IntegrationEvents -- is executed prior to all other code in this loop to prevent lines from being split prior to events
            repeat
                OnBeforeHandleRegistration(_WhseActLine, MobWmsRegistration, _IsAnyPutAway, _IsAnyPick, _IsAnyMovement);
            until MobWmsRegistration.Next() = 0;

            if MobWmsRegistration.FindSet() then begin
                repeat
                    //
                    // Handle single MobileWmsRegistration for WhseActLine Take/Place pair 
                    //

                    ReReadWhseActLine(_WhseActLine);     // May be renumbered during handling of PairedWhseActLine
                    _WhseActLineNo := _WhseActLine."Line No."; // Store current line no. as it might be different after a split and re-numbering of lines

                    CheckRegisteredItemTracking(
                        _RegistrationType,
                        _WhseActHeader,
                        _WhseActLine,
                        MobWmsRegistration,
                        MobSpecificTrackingSetup);

                    // Set value for BinCode to use based on LineType for primary WhseActLine
                    GetRegisteredBinCodeForPrimaryWhseActLine(_LineType, MobWmsRegistration.FromBin, MobWmsRegistration.ToBin, RegisteredBinCode);

                    // 
                    // Populate and possibly split line (the whse act. line controlling the loop)
                    //
                    GetExpirationDateToRegister(MobWmsRegistration, RegisterExpirationDate, ExpirationDate);
                    HandleRegistrationForPrimaryWhseActLine(
                        _WhseActLine,           // var
                        MobWmsRegistration,
                        RegisteredBinCode,
                        ExpirationDate,
                        _IsAnyPutAway,
                        _IsAnyPick,
                        _IsAnyMovement,
                        _TempNewReservationEntry);  // var

                    //
                    // Populate and possibly split matching line (other "leg" in paired Action Types) 
                    // if pairedMobWmsRegistration exists, paired registrations will be handled in a separate loop after the Registrations for “primary” WhseActLine’s has been handled (the instances controlling the loop).
                    //
                    if UpdatePairedLine and (not FindPairedMobWmsRegistrations(MobWmsRegistration, PairedMobWmsRegistration)) then begin
                        ReReadWhseActLine(PairedWhseActLine);    // May be renumbered during handling of PrimaryWhseActLine

                        GetRegisteredBinCodeForPairedWhseActLine(_LineType, PairedWhseActLine, MobWmsRegistration, RegisteredBinCode);
                        HandleRegistrationForPairedWhseActLine(
                            PairedWhseActLine,
                            MobWmsRegistration,
                            RegisteredBinCode,
                            ExpirationDate,
                            _IsAnyPutAway,
                            _IsAnyPick,
                            _IsAnyMovement);
                    end;

                until MobWmsRegistration.Next() = 0;

                // Movements allows scanning a different ToBin than suggested, ToBins must be fetched from paired registrations (ActionType PLACE)
                if UpdatePairedLine and FindPairedMobWmsRegistrations(MobWmsRegistration, PairedMobWmsRegistration) then
                    repeat
                        GetRegisteredBinCodeForPairedWhseActLine(_LineType, PairedWhseActLine, PairedMobWmsRegistration, RegisteredBinCode);
                        HandleRegistrationForPairedWhseActLine(
                            PairedWhseActLine,
                            PairedMobWmsRegistration,
                            RegisteredBinCode,
                            ExpirationDate,
                            _IsAnyPutAway,
                            _IsAnyPick,
                            _IsAnyMovement);
                    until PairedMobWmsRegistration.Next() = 0;

            end; // If MobWmsRegistration.FindSet() then begin .. after OnBeforeHandleRegistration that might mark the registrations as Handled

        end;

        // At this point all registrations for this line have been handled

        // If we are handling a movement the loop is only performed on the TAKE lines
        // but we need to mark the place lines as handled as well.
        if _IsAnyMovement then
            MobWmsRegistration.SetRange(ActionType);

        // Mark registrations as handled. Registrations associated with splitted Actitivity Lines is already marked handled and is not updated here
        MobWmsRegistration.ModifyAll(Handled, true);
    end;

    local procedure OnBeforeHandleRegistration(
         var _WhseActLineBeforeSplit: Record "Warehouse Activity Line";
         var _MobWmsRegistration: Record "MOB WMS Registration";
         _IsAnyPutAway: Boolean;
         _IsAnyPick: Boolean;
         _IsAnyMovement: Boolean)
    var
        MobWmsPutAway: Codeunit "MOB WMS Put Away";
        MobWmsPick: Codeunit "MOB WMS Pick";
        MobWmsMove: Codeunit "MOB WMS Move";
    begin
        if _IsAnyPutAway then
            MobWmsPutAway.OnPostPutAwayOrder_OnBeforeHandleRegistrationForWarehouseActivityLine(_MobWmsRegistration, _WhseActLineBeforeSplit);
        if _IsAnyPick then
            // OnBefore-event exists only for warehouse activity line, hence no "ForAnyLine"-event is triggered here
            MobWmsPick.OnPostPickOrder_OnBeforeHandleRegistrationForWarehouseActivityLine(_MobWmsRegistration, _WhseActLineBeforeSplit);
        if _IsAnyMovement then
            MobWmsMove.OnPostMoveOrder_OnBeforeHandleRegistrationForWarehouseActivityLine(_MobWmsRegistration, _WhseActLineBeforeSplit);
        _MobWmsRegistration.Modify();
        _WhseActLineBeforeSplit.Modify();
    end;

    local procedure OnHandleRegistration(
         var _WhseActLine: Record "Warehouse Activity Line";
         var _MobWmsRegistration: Record "MOB WMS Registration";
         _IsAnyPutAway: Boolean;
         _IsAnyPick: Boolean;
         _IsAnyMovement: Boolean)
    var
        MobWmsPutAway: Codeunit "MOB WMS Put Away";
        MobWmsPick: Codeunit "MOB WMS Pick";
        MobWmsMove: Codeunit "MOB WMS Move";
        RecRef: RecordRef;
    begin
        if _IsAnyPutAway then
            MobWmsPutAway.OnPostPutAwayOrder_OnHandleRegistrationForWarehouseActivityLine(_MobWmsRegistration, _WhseActLine);
        if _IsAnyPick then begin
            MobWmsPick.OnPostPickOrder_OnHandleRegistrationForWarehouseActivityLine(_MobWmsRegistration, _WhseActLine);
            // Only picks needs ForAnyLine-event, since putaway/movement is always warehouse activity only
            RecRef.GetTable(_WhseActLine);
            MobWmsPick.OnPostPickOrder_OnHandleRegistrationForAnyLine(_MobWmsRegistration, RecRef);
            RecRef.SetTable(_WhseActLine);
        end;
        if _IsAnyMovement then
            MobWmsMove.OnPostMoveOrder_OnHandleRegistrationForWarehouseActivityLine(_MobWmsRegistration, _WhseActLine);
        _MobWmsRegistration.Modify();
        // _WhseActLine is modified in calling functions
    end;

    local procedure CheckRegisteredItemTracking(
        _RegistrationType: Enum "MOB WMS Registration Type";
        _WhseActHeader: Record "Warehouse Activity Header";
        _WhseActLine: Record "Warehouse Activity Line";
        _MobWmsRegistration: Record "MOB WMS Registration";
        _MobSpecificTrackingSetup: Record "MOB Tracking Setup")
    var
        DummyMobWmsRegistration: Record "MOB WMS Registration";
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        SerialExists: Boolean;
    begin
        if not _MobSpecificTrackingSetup.TrackingRequired() then
            exit;

        // _MobSpecificTrackingSetup.TrackingRequired: Determined before (for the WhseActLine outside MobWmsRegistration loop)
        _MobSpecificTrackingSetup.CopyTrackingFromRegistration(_MobWmsRegistration);    // Not a var = not returned to caller

        // Is this a Pick and not for Assemble-to-order the tracked goods must be on inventory
        if (_RegistrationType = DummyMobWmsRegistration.Type::Pick) and (not _WhseActLine."Assemble to Order") then
            _MobSpecificTrackingSetup.CheckTrackingOnInventoryIfRequired(_WhseActLine."Item No.", _WhseActLine."Variant Code");

        // If this is an invt. put-away then serial number must NOT exist (unless it's a Transfer Order put-away in which case it will exist in the Transit Location)
        if (_WhseActHeader.Type = _WhseActHeader.Type::"Invt. Put-away") and (_WhseActHeader."Source Document" <> _WhseActHeader."Source Document"::"Inbound Transfer") then
            if _MobSpecificTrackingSetup."Serial No. Required" then begin
                SerialExists := MobWmsToolbox.InventoryExistsBySerialNo(_WhseActLine."Item No.", _WhseActLine."Variant Code", _MobWmsRegistration.SerialNumber);
                if SerialExists then
                    Error(MobWmsLanguage.GetMessage('RECV_KNOWN_SERIAL'), _MobWmsRegistration.SerialNumber);
            end;
    end;

    local procedure GetRegisteredBinCodeForPrimaryWhseActLine(_LineType: Code[30]; _FromBin: Code[20]; _ToBin: Code[20]; var _RegisteredBinCode: Code[20])
    begin
        case _LineType of
            'BLANK':
                // BLANK = No bins
                _RegisteredBinCode := '';

            'TAKE',
            'TAKE_PLACE_PAIR_PICK',
            'TAKE_PLACE_PAIR_MOVE':
                // The registration have been filtered to only loop over registrations relating to this take line
                _RegisteredBinCode := _FromBin;

            'PLACE',
            'TAKE_PLACE_PAIR_PUT_AWAY':
                _RegisteredBinCode := _ToBin;

        end;  // case
    end;

    local procedure GetRegisteredBinCodeForPairedWhseActLine(_LineType: Code[30]; _PairedWhseActLine: Record "Warehouse Activity Line"; _MobWmsRegistration: Record "MOB WMS Registration"; var _RegisteredBinCode: Code[20])
    begin
        Clear(_RegisteredBinCode);
        case _LineType of
            'TAKE_PLACE_PAIR_MOVE':
                _RegisteredBinCode := _MobWmsRegistration.ToBin;
        end;  // case

        if _RegisteredBinCode = '' then
            _RegisteredBinCode := _PairedWhseActLine."Bin Code";
    end;

    /// <summary>
    /// Get a paired MobWmsRegistration. These Registrations exist on Movements that has both Take and Place registrations
    /// </summary>
    local procedure FindPairedMobWmsRegistrations(_MobWmsRegistration: Record "MOB WMS Registration"; var _PairedMobWmsRegistration: Record "MOB WMS Registration"): Boolean
    begin
        Clear(_PairedMobWmsRegistration);
        _PairedMobWmsRegistration.SetRange(Type, _MobWmsRegistration.Type);
        _PairedMobWmsRegistration.SetRange("Order No.", _MobWmsRegistration."Order No.");
        _PairedMobWmsRegistration.SetRange("Line No.", _MobWmsRegistration."Line No.");
        _PairedMobWmsRegistration.SetRange("Posting MessageId", _MobWmsRegistration."Posting MessageId");
        case true of
            _MobWmsRegistration.ActionType = 'TAKE':
                begin
                    _PairedMobWmsRegistration.SetRange(ActionType, 'PLACE');
                    exit(_PairedMobWmsRegistration.FindSet());
                end;
            _MobWmsRegistration.ActionType = 'PLACE':
                begin
                    _PairedMobWmsRegistration.SetRange(ActionType, 'TAKE');
                    exit(_PairedMobWmsRegistration.FindSet());
                end;
            else
                _MobWmsRegistration.FieldError(ActionType);
        end;
    end;

    local procedure GetExpirationDateToRegister(_MobWmsRegistration: Record "MOB WMS Registration"; _RegisterExpirationDate: Boolean; var _ExpirationDate: Date)
    begin
        // Lot/SerialNumbers and Expiration Dates to handle
        // Lot/SerialNumber contains only the number (unlike earlier version where expiration date was included in same field)
        if _RegisterExpirationDate then begin
            _MobWmsRegistration.TestField("Expiration Date");
            _ExpirationDate := _MobWmsRegistration."Expiration Date";
        end else
            _ExpirationDate := 0D;
    end;

    local procedure HandleRegistrationForPrimaryWhseActLine(
        var _WhseActLine: Record "Warehouse Activity Line";
        var _MobWmsRegistration: Record "MOB WMS Registration";
        _RegisteredBinCode: Code[50];
        _ExpirationDate: Date;
        _IsAnyPutAway: Boolean;
        _IsAnyPick: Boolean;
        _IsAnyMovement: Boolean;
        var _TempNewReservationEntry: Record "Reservation Entry")   // must be var, temporary
    var
        NewWhseActLine: Record "Warehouse Activity Line";
        MobWhseTrackingSetup: Record "MOB Tracking Setup";
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
        ConvertedQtyToHandle: Decimal;
        DummyWhseRegisterExpirationDate: Boolean;
    begin
        ConvertedQtyToHandle := MobWmsToolbox.CalcQtyNewUOMRounded(_WhseActLine."Item No.", _MobWmsRegistration.Quantity, _MobWmsRegistration.UnitOfMeasure, _WhseActLine."Unit of Measure Code");

        // "Allow split" condition from standard code WarehouseActivityLine.SplitLine(): Mostly any line, but for put-away only place lines and only if not breakbulk
        // Therefore unconditially allow split here, as the WhseActLine controlling the loop is always a Place-line for put-away (and with no Breakbulk)
        PerformSplitIfNeeded(_WhseActLine, _MobWmsRegistration, NewWhseActLine, ConvertedQtyToHandle, _RegisteredBinCode);

        _MobWmsRegistration."Source MOBSystemId" := _WhseActLine.MOBSystemId;

        // Set Qty. To Handle, Zone Code and Bin Code after possibly splitting original line
        UpdateWhseActLine(_WhseActLine, _RegisteredBinCode, ConvertedQtyToHandle);

        // Zone, Bin Code and Qty. To Handle was set in UpdateOrigBeforeSpit

        // Tracking Steps was created based on wheither tracking is needed for i.e. Shipment (MobTrackingSetup = DetermineITEMTracking).
        // We now need to determine where to store the collected tracking values based on WHSE Tracking 
        MobWhseTrackingSetup.DetermineWhseTrackingRequired(_WhseActLine."Item No.", DummyWhseRegisterExpirationDate);
        MobWhseTrackingSetup.CopyTrackingFromRegistration(_MobWmsRegistration);

        if MobWhseTrackingSetup.TrackingRequired() then
            UpdateItemTrackingOnWhseActLine(_WhseActLine, MobWhseTrackingSetup, _ExpirationDate)
        else
            UpdateItemTrackingOnSourceDocReservationEntry(
                _WhseActLine,               // var
                _MobWmsRegistration,
                _TempNewReservationEntry);  // var                

        MobWmsToolbox.SaveRegistrationDataFromSource(_WhseActLine."Location Code", _WhseActLine."Item No.", _WhseActLine."Variant Code", _MobWmsRegistration);

        // OnHandle IntegrationEvents -- is executed after split line but prior to populating tracking
        OnHandleRegistration(_WhseActLine, _MobWmsRegistration, _IsAnyPutAway, _IsAnyPick, _IsAnyMovement);
        _WhseActLine.Modify();

        // MobWmsRegistation marked as handled since "ModifyAll(Handled, true)" later excludes this registration due to "Source MOBSystemId"-filter
        _MobWmsRegistration.Handled := true;
        _MobWmsRegistration.Modify();
    end;

    local procedure HandleRegistrationForPairedWhseActLine(
        var _PairedWhseActLine: Record "Warehouse Activity Line";
        var _MobWmsRegistration: Record "MOB WMS Registration";
        _RegisteredBinCode: Code[50];
        _ExpirationDate: Date;
        _IsAnyPutAway: Boolean;
        _IsAnyPick: Boolean;
        _IsAnyMovement: Boolean)
    var
        xPairedWhseActLine: Record "Warehouse Activity Line";
        NewPairedWhseActLine: Record "Warehouse Activity Line";
        MobWhseTrackingSetup: Record "MOB Tracking Setup";
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
        ConvertedQtyToHandle: Decimal;
        SplitPairedIsAllowed: Boolean;
        DummyWhseRegisterExpirationDate: Boolean;
    begin
        xPairedWhseActLine := _PairedWhseActLine;

        ConvertedQtyToHandle := MobWmsToolbox.CalcQtyNewUOMRounded(_PairedWhseActLine."Item No.", _MobWmsRegistration.Quantity, _MobWmsRegistration.UnitOfMeasure, _PairedWhseActLine."Unit of Measure Code");

        // Mirror "allow split" condition from standard code WarehouseActivityLine.SplitLine(): Mostly any line, but for put-away only place lines and only if not breakbulk
        // Will return false for all put-away for _PairedWhseActLine, since paired line is a "Take"-line (for put-away the "Place"-line is the line controlling the loop)
        SplitPairedIsAllowed :=
            (_PairedWhseActLine."Activity Type" <> _PairedWhseActLine."Activity Type"::"Put-away") or
            ((_PairedWhseActLine."Activity Type" = _PairedWhseActLine."Activity Type"::"Put-away") and
             (_PairedWhseActLine."Action Type" = _PairedWhseActLine."Action Type"::Place) and
             (_PairedWhseActLine."Breakbulk No." = 0));

        if SplitPairedIsAllowed then
            PerformSplitIfNeeded(_PairedWhseActLine, _MobWmsRegistration, NewPairedWhseActLine, ConvertedQtyToHandle, _RegisteredBinCode);

        // Set Qty. To Handle, Zone Code and Bin Code after possibly splitting original line
        UpdateWhseActLine(_PairedWhseActLine, _RegisteredBinCode, ConvertedQtyToHandle);

        // Zone, Bin Code and Qty. To Handle was set in UpdateOrigBeforeSpit

        // Tracking Steps was created based on wheither tracking is needed for i.e. Shipment (MobTrackingSetup = DetermineITEMTracking).
        // We now need to determine where to store the collected tracking values based on WHSE Tracking 
        MobWhseTrackingSetup.DetermineWhseTrackingRequired(_PairedWhseActLine."Item No.", DummyWhseRegisterExpirationDate);
        MobWhseTrackingSetup.CopyTrackingFromRegistration(_MobWmsRegistration);

        // No else-condition (never update reservation entries for PairedWhseActLine -- as opposed to HandleRegistrationForPrimaryWhseActLine)
        if MobWhseTrackingSetup.TrackingRequired() then
            UpdateItemTrackingOnWhseActLine(_PairedWhseActLine, MobWhseTrackingSetup, _ExpirationDate);

        // OnHandle IntegrationEvents for paired line -- is executed only when split is allowed, then when tracking is saved after the split
        if SplitPairedIsAllowed then
            OnHandleRegistration(_PairedWhseActLine, _MobWmsRegistration, _IsAnyPutAway, _IsAnyPick, _IsAnyMovement);

        _PairedWhseActLine.Modify();
    end;

    internal procedure UpdateIncomingWarehouseActivityOrder(var _WhseActHeader: Record "Warehouse Activity Header")
    begin
        if not _WhseActHeader.Get(_WhseActHeader."Type", _WhseActHeader."No.") then
            exit;

        _WhseActHeader.LockTable();
        _WhseActHeader.Get(_WhseActHeader."Type", _WhseActHeader."No.");
        Clear(_WhseActHeader."MOB Posting MessageId");
        _WhseActHeader.Modify();
    end;

    local procedure UpdateItemTrackingOnWhseActLine(var _WhseActLine: Record "Warehouse Activity Line"; _MobWhseTrackingSetup: Record "MOB Tracking Setup"; _ExpirationDate: Date)
    var
        MobItemTrackingManagement: Codeunit "MOB Item Tracking Management";
        EntriesExist: Boolean;
        ExpDate: Date;
    begin
        // Set the values from the registration.
        // Recent BC versions allows validating Serial No. only when Quantity (Base) is 1. Since we populate Tracking
        // prior to split lines in our code, we can Validate only Required fields, but must stil populate all fields.
        // Workaround is to only validate values with WHSE tracking enabled.
        _MobWhseTrackingSetup.ValidateTrackingToWhseActLineIfRequired(_WhseActLine); // Validation can have a big performance impact as a search for related tracking information is done by Base app

        // Do not update the expiration date if it is the null date
        // (happens when handling invt. put-aways from transfer orders)
        if _ExpirationDate <> 0D then
            _WhseActLine.Validate("Expiration Date", _ExpirationDate);
        // Get expirationdate when handling movements (warehouse) - otherwise exp.date is lost in new positive entries
        if _WhseActLine.TrackingExists() then
            ExpDate := MobItemTrackingManagement.ExistingExpirationDate(_WhseActLine."Item No.", _WhseActLine."Variant Code", _MobWhseTrackingSetup, false, EntriesExist);
        if ExpDate <> 0D then
            _WhseActLine.Validate("Expiration Date", ExpDate);
    end;

    local procedure UpdateItemTrackingOnSourceDocReservationEntry(
        _PrimaryWhseActLine: Record "Warehouse Activity Line";
        _MobWmsRegistration: Record "MOB WMS Registration";
        var _TempNewReservationEntry: Record "Reservation Entry" // must be var, temporary
    )
    var
        MobSetup: Record "MOB Setup";
        MobSyncItemTracking: Codeunit "MOB Sync. Item Tracking";
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
        WMSMgt: Codeunit "WMS Management";
        QtyBase: Decimal;
    begin
        MobSetup.Get();

        if MobSetup."Use Base Unit of Measure" then
            QtyBase := _MobWmsRegistration.Quantity
        else
            QtyBase := MobWmsToolbox.CalcQtyNewUOMRounded(_PrimaryWhseActLine."Item No.",
                                    _MobWmsRegistration.Quantity,
                                    _MobWmsRegistration.UnitOfMeasure,
                                    WMSMgt.GetBaseUOM(_PrimaryWhseActLine."Item No."));

        MobSyncItemTracking.CreateTempReservEntryForWhseActivityLine(_PrimaryWhseActLine, _MobWmsRegistration, _TempNewReservationEntry, QtyBase);
    end;

    local procedure SetWhseActLineFilter(var _WhseActLine: Record "Warehouse Activity Line"; _WhseActHeader: Record "Warehouse Activity Header"): Code[30]
    var
        Location: Record Location;
    begin
        // Get the location to determine how it's configured
        Location.Get(_WhseActHeader."Location Code");

        // From the configuration of the location + the type of the warehouse activity
        // we can determine which lines to look for (action type: blank, take, place, or a take/place pair)
        //
        // If bins are mandatory then the following is true:
        // - Location requires both receive and put-away -> whse. put-away with take/place pairs
        // - Location only requires put-away -> invt. put-away with place lines
        // - Location requires both shipment and pick -> whse. pick with take/place pairs
        // - Location only requires pick -> invt. pick with take lines
        //
        // If bins are not mandatory then the following is true
        // All lines have action type "blank"

        if Location."Bin Mandatory" then begin

            // Bin is mandatory
            // Invt. put-away
            if _WhseActHeader.Type = _WhseActHeader.Type::"Invt. Put-away" then begin
                _WhseActLine.SetRange("Action Type", _WhseActLine."Action Type"::Place);
                exit('PLACE');
            end;

            // Whse. put-away
            if _WhseActHeader.Type = _WhseActHeader.Type::"Put-away" then begin
                _WhseActLine.SetRange("Action Type", _WhseActLine."Action Type"::Place);
                exit('TAKE_PLACE_PAIR_PUT_AWAY');
            end;

            // Invt. pick
            if _WhseActHeader.Type = _WhseActHeader.Type::"Invt. Pick" then begin
                _WhseActLine.SetRange("Action Type", _WhseActLine."Action Type"::Take);
                exit('TAKE');
            end;

            // Whse. pick
            if _WhseActHeader.Type = _WhseActHeader.Type::Pick then begin
                _WhseActLine.SetRange("Action Type", _WhseActLine."Action Type"::Take);
                exit('TAKE_PLACE_PAIR_PICK');
            end;

            // Whse. Move
            if _WhseActHeader.Type = _WhseActHeader.Type::Movement then begin
                _WhseActLine.SetRange("Action Type", _WhseActLine."Action Type"::Take);
                exit('TAKE_PLACE_PAIR_MOVE');
            end;

            // Invt. Move
            if _WhseActHeader.Type = _WhseActHeader.Type::"Invt. Movement" then begin
                _WhseActLine.SetRange("Action Type", _WhseActLine."Action Type"::Take);
                exit('TAKE_PLACE_PAIR_MOVE');
            end;

        end else begin

            // Bin is NOT mandatory
            // The action type is the same on all lines: "blank"
            _WhseActLine.SetRange("Action Type", _WhseActLine."Action Type"::" ");
            exit('BLANK');

        end;
    end;

    /// <summary>
    /// Validate Quantity to handle
    /// Update Bin and Zone if Bin Code changed 
    /// IMPORTANT: Assumes all lines was Reset to 0 before processing
    /// </summary>
    local procedure UpdateWhseActLine(var _WhseActLine: Record "Warehouse Activity Line"; _BinCode: Code[20]; _QuantityToHandle: Decimal)
    var
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
        MobOverReceiptMgt: Codeunit "MOB Over-Receipt Mgt.";
        TotalQty: Decimal;
    begin
        TotalQty := _WhseActLine."Qty. to Handle" + _QuantityToHandle;

        if TotalQty > _WhseActLine."Qty. Outstanding" then
            case true of
                // OverReceipt
                MobOverReceiptMgt.IsOverReceiptAllowed(_WhseActLine):
                    begin
                        _WhseActLine.Validate("Qty. to Handle", _WhseActLine."Qty. Outstanding");
                        MobOverReceiptMgt.ValidateOverReceiptQuantity(_WhseActLine, TotalQty - _WhseActLine."Qty. to Handle");
                    end;

                // OverPick
                _WhseActLine."MOB ItemAllowWhseOverpick"():
                    ValidateOverPickQuantity(_WhseActLine, TotalQty);

                else
                    _WhseActLine.Validate("Qty. to Handle", TotalQty);  // Intentionally throw error on Over-Receipt/Pick not allowed
            end
        else
            // Regular
            _WhseActLine.Validate("Qty. to Handle", TotalQty);

        // Update the bin code
        if _WhseActLine."Bin Code" <> _BinCode then begin
            _WhseActLine."Zone Code" := ''; // Reset zone code to allow Bin code validation
            _WhseActLine.Validate("Bin Code", _BinCode);
            _WhseActLine."Zone Code" := MobWmsToolbox.GetZoneFromBin(_WhseActLine."Location Code", _WhseActLine."Bin Code");
        end;
    end;

    local procedure ValidateOverPickQuantity(var _WhseActLine: Record "Warehouse Activity Line"; _QtyToHandle: Decimal)
    var
        OverPickQty: Decimal;
    begin
        OverPickQty := _QtyToHandle - _WhseActLine."Qty. Outstanding"; // Calc. surplus to OverPick

        _WhseActLine.Validate(Quantity, _WhseActLine.Quantity + OverPickQty); // 1st Trigger OverPick by increasing Quantity
        _WhseActLine.Validate("Qty. to Handle", _QtyToHandle); // 2nd validate Qty. to handle
    end;

    local procedure PerformSplitIfNeeded(var _WhseActLine: Record "Warehouse Activity Line"; var _MobWmsRegistration: Record "MOB WMS Registration"; var _WhseActLineNew: Record "Warehouse Activity Line"; _QuantityToHandle: Decimal; _RegisteredBinCode: Code[20]): Boolean
    var
        BinContent: Record "Bin Content";
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        SplitNeeded: Boolean;
        SplitLineNo: Integer;
        IsHandled: Boolean;
    begin
        // Determine if split is needed
        // This is done before setting the values from the mobile device
        // (to prevent the lot and serial number fields from being filled with the current registration values)
        // The only value that must be set is the qty to handle
        OnBeforeSplitNeeded(_WhseActLine, _MobWmsRegistration, _QuantityToHandle, _RegisteredBinCode, SplitNeeded, IsHandled);

        if not IsHandled then
            if (_QuantityToHandle < _WhseActLine."Qty. Outstanding") and (_WhseActLine."Qty. to Handle" <> 0) then
                SplitNeeded := (_WhseActLine."Bin Code" <> _RegisteredBinCode) or MobWmsToolbox.IsWarehouseTracking(_WhseActLine."Item No.") or _MobWmsRegistration.ExtraInfo;

        if SplitNeeded then begin
            _WhseActLine.Modify();  // Renumbering in SplitLine will re-read the original record and overwrite Qty. To Handle etc. if not modified
            SplitLineNo := SplitLine(_WhseActLine);

            // Find the split line
            _WhseActLineNew.SetRange("Activity Type", _WhseActLine."Activity Type");
            _WhseActLineNew.SetRange("No.", _WhseActLine."No.");
            _WhseActLineNew.SetRange("Line No.", SplitLineNo);
            if not _WhseActLineNew.FindFirst() then
                Error('%1  (%2=%3, %4=%5, %6=%7)',
                    MobWmsLanguage.GetMessage('SPLIT_LINE_NOT_FOUND'),
                    _WhseActLine.FieldCaption("Activity Type"), _WhseActLine."Activity Type",
                    _WhseActLine.FieldCaption("No."), _WhseActLine."No.",
                    _WhseActLine.FieldCaption("Line No."), SplitLineNo);

            // This prevents the line to be included in the loop over WhseActLineTake
            _WhseActLineNew.MOBLineSplitAutomatically := true;

            // Set the qty to handle to 0 to prevent partially handled lines from being posted
            _WhseActLineNew.Validate("Qty. to Handle", 0);

            if _RegisteredBinCode <> _WhseActLineNew."Bin Code" then begin
                _WhseActLineNew."Zone Code" := '';

                //
                // "safe" validation of Bin Code: Inventory Picks (INVBIN) allow reserved Bin Content to be picked to other documents and may remove non-fixed Bin Content for Bins that is still referenced from other Inventory Pick lines
                //
                if BinContent.Get(_WhseActLineNew."Location Code", _RegisteredBinCode, _WhseActLineNew."Item No.", _WhseActLineNew."Variant Code", _WhseActLineNew."Unit of Measure Code") then
                    _WhseActLineNew.Validate("Bin Code", _RegisteredBinCode)
                else begin
                    // Workaround: Temporarily insert, then delete Bin Content
                    BinContent.Init();
                    BinContent."Location Code" := _WhseActLineNew."Location Code";
                    BinContent."Bin Code" := _RegisteredBinCode;
                    BinContent."Item No." := _WhseActLineNew."Item No.";
                    BinContent."Variant Code" := _WhseActLineNew."Variant Code";
                    BinContent."Unit of Measure Code" := _WhseActLineNew."Unit of Measure Code";

                    BinContent.Insert();
                    _WhseActLineNew.Validate("Bin Code", _RegisteredBinCode);
                    BinContent.Delete();
                end;

                _WhseActLineNew."Zone Code" := MobWmsToolbox.GetZoneFromBin(_WhseActLineNew."Location Code", _WhseActLineNew."Bin Code");
            end;

            // Move Take-pointer to new line (new outstanding qty.)
            _WhseActLine := _WhseActLineNew;
        end else
            _WhseActLine.Modify();

        exit(SplitNeeded);
    end;

    local procedure SplitLine(var _LineToSplit: Record "Warehouse Activity Line"): Integer
    var
        TempPreSplitLine: Record "Warehouse Activity Line" temporary;
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // Backwards compatibility: Update empty WarehouseActivityLine.MOBSystemID at existing lines
        if IsNullGuid(_LineToSplit.MOBSystemId) then begin
            _LineToSplit.MOBSystemId := CreateGuid();
            _LineToSplit.Modify();
        end;

        // Splits line into two and return the created line no.

        // Save Copy of Lines
        WarehouseActivityLine.SetRange("Action Type", _LineToSplit."Action Type");
        WarehouseActivityLine.SetRange("No.", _LineToSplit."No.");
        WarehouseActivityLine.SetRange("Activity Type", _LineToSplit."Activity Type");
        if WarehouseActivityLine.FindSet() then
            repeat
                // Backwards compatibility: Update empty WarehouseActivityLine.MOBSystemID at existing lines
                if IsNullGuid(WarehouseActivityLine.MOBSystemId) then begin
                    WarehouseActivityLine.MOBSystemId := CreateGuid();
                    WarehouseActivityLine.Modify();
                end;

                TempPreSplitLine.Copy(WarehouseActivityLine);
                TempPreSplitLine.TestField(MOBSystemId);
                TempPreSplitLine.Insert(false);
            until WarehouseActivityLine.Next() = 0;

        // Standard Split Line
        _LineToSplit.TestField(MOBSystemId);
        _LineToSplit.SplitLine(_LineToSplit);

        // Compare to Saved Copy
        if WarehouseActivityLine.FindSet() then
            repeat
                TempPreSplitLine.SetRange(MOBSystemId, WarehouseActivityLine.MOBSystemId);
                if TempPreSplitLine.IsEmpty() then
                    exit(WarehouseActivityLine."Line No."); // Not found = The New Line
            until WarehouseActivityLine.Next() = 0;
    end;

    procedure FindPlaceLine(var _WhseActLinePlace: Record "Warehouse Activity Line"; _WhseActHeader: Record "Warehouse Activity Header"; _WhseActLineTake: Record "Warehouse Activity Line")
    var
        MobWmsLanguage: Codeunit "MOB WMS Language";
    begin
        FilterWhseActLinePlace(_WhseActLinePlace, _WhseActHeader, _WhseActLineTake);

        if not _WhseActLinePlace.FindFirst() then
            Error(MobWmsLanguage.GetMessage('PLACE_LINE_NOT_FOUND'), _WhseActLineTake."Line No.");
    end;

    local procedure FindPlaceLineWithOutstandingQtyToHandle(var _WhseActLinePlace: Record "Warehouse Activity Line"; _WhseActHeader: Record "Warehouse Activity Header"; _WhseActLineTake: Record "Warehouse Activity Line")
    var
        MobWmsLanguage: Codeunit "MOB WMS Language";
    begin
        FilterWhseActLinePlace(_WhseActLinePlace, _WhseActHeader, _WhseActLineTake);
        if _WhseActLinePlace.FindSet() then
            repeat
                if _WhseActLinePlace."Qty. Outstanding" > _WhseActLinePlace."Qty. to Handle" then // Something to handle
                    exit;

            until _WhseActLinePlace.Next() = 0;

        Error(MobWmsLanguage.GetMessage('PLACE_LINE_NOT_FOUND'), _WhseActLineTake."Line No.");
    end;

    local procedure FilterWhseActLinePlace(var _WhseActLinePlace: Record "Warehouse Activity Line"; _WhseActHeader: Record "Warehouse Activity Header"; _WhseActLineTake: Record "Warehouse Activity Line")
    var
        MobCommonMgt: Codeunit "MOB Common Mgt.";
    begin
        // There is no direct link between the take and the place line, so it is assumed that it's the next place line with something outstanding to handle
        // Intentially include lines with MOBLineSplitAutomatically=true since these are the new Place-lines created during splits and which hold the remaining quantities (original line with a lower line number is fully settled during the split)
        Clear(_WhseActLinePlace);
        _WhseActLinePlace.SetRange("Activity Type", _WhseActHeader.Type);
        _WhseActLinePlace.SetRange("No.", _WhseActHeader."No.");
        _WhseActLinePlace.SetRange("Action Type", _WhseActLinePlace."Action Type"::Place);
        _WhseActLinePlace.SetRange("Whse. Document Type", _WhseActLineTake."Whse. Document Type");
        _WhseActLinePlace.SetRange("Whse. Document No.", _WhseActLineTake."Whse. Document No.");
        _WhseActLinePlace.SetRange("Whse. Document Line No.", _WhseActLineTake."Whse. Document Line No.");
        _WhseActLinePlace.SetFilter("Line No.", '>%1', _WhseActLineTake."Line No.");
        _WhseActLinePlace.SetRange("Item No.", _WhseActLineTake."Item No.");
        _WhseActLinePlace.SetRange("Variant Code", _WhseActLineTake."Variant Code");
        _WhseActLinePlace.SetRange("Breakbulk No.", _WhseActLineTake."Breakbulk No.");
        MobCommonMgt.SetTrackingFilterFromWhseActivityLine(_WhseActLinePlace, _WhseActLineTake);

        OnAfterFilterWhseActLinePlace(_WhseActLinePlace, _WhseActHeader, _WhseActLineTake);
    end;

    local procedure RevertToOriginalLines(var _TempWhseActLine: Record "Warehouse Activity Line" temporary)
    var
        WhseActLine: Record "Warehouse Activity Line";
    begin
        if _TempWhseActLine.FindFirst() then begin
            WhseActLine.SetRange("Activity Type", _TempWhseActLine."Activity Type");
            WhseActLine.SetRange("No.", _TempWhseActLine."No.");
            WhseActLine.DeleteAll();
            repeat
                WhseActLine.Copy(_TempWhseActLine);
                WhseActLine.Insert();
            until _TempWhseActLine.Next() = 0;
        end;
    end;

    procedure FindTakeLine(var _WhseActLineTake: Record "Warehouse Activity Line"; _WhseActHeader: Record "Warehouse Activity Header"; _WhseActLinePlace: Record "Warehouse Activity Line")
    var
        MobWmsLanguage: Codeunit "MOB WMS Language";
    begin
        FilterWhseActLineTake(_WhseActLineTake, _WhseActHeader, _WhseActLinePlace);

        if not _WhseActLineTake.FindLast() then
            Error(MobWmsLanguage.GetMessage('TAKE_LINE_NOT_FOUND'), _WhseActLinePlace."Line No.");
    end;

    local procedure FindTakeLineWithOutstandingQtyToHandle(var _WhseActLineTake: Record "Warehouse Activity Line"; _WhseActHeader: Record "Warehouse Activity Header"; _WhseActLinePlace: Record "Warehouse Activity Line")
    var
        MobWmsLanguage: Codeunit "MOB WMS Language";
    begin
        FilterWhseActLineTake(_WhseActLineTake, _WhseActHeader, _WhseActLinePlace);
        if _WhseActLineTake.FindLast() then
            repeat
                if _WhseActLineTake."Qty. Outstanding" > _WhseActLineTake."Qty. to Handle" then // Something to handle
                    exit;

            until _WhseActLineTake.Next(-1) = 0;

        Error(MobWmsLanguage.GetMessage('TAKE_LINE_NOT_FOUND'), _WhseActLinePlace."Line No.");
    end;

    local procedure FilterWhseActLineTake(var _WhseActLineTake: Record "Warehouse Activity Line"; _WhseActHeader: Record "Warehouse Activity Header"; _WhseActLinePlace: Record "Warehouse Activity Line")
    var
        MobCommonMgt: Codeunit "MOB Common Mgt.";
    begin
        _WhseActLineTake.SetRange("Activity Type", _WhseActHeader.Type);
        _WhseActLineTake.SetRange("No.", _WhseActHeader."No.");
        _WhseActLineTake.SetRange("Action Type", _WhseActLineTake."Action Type"::Take);
        _WhseActLineTake.SetRange("Whse. Document Type", _WhseActLinePlace."Whse. Document Type");
        _WhseActLineTake.SetRange("Whse. Document No.", _WhseActLinePlace."Whse. Document No.");
        _WhseActLineTake.SetRange("Whse. Document Line No.", _WhseActLinePlace."Whse. Document Line No.");
        _WhseActLineTake.SetFilter("Line No.", '<%1', _WhseActLinePlace."Line No.");
        _WhseActLineTake.SetRange("Item No.", _WhseActLinePlace."Item No.");
        _WhseActLineTake.SetRange("Variant Code", _WhseActLinePlace."Variant Code");
        _WhseActLineTake.SetRange("Breakbulk No.", _WhseActLinePlace."Breakbulk No.");
        MobCommonMgt.SetTrackingFilterFromWhseActivityLine(_WhseActLineTake, _WhseActLinePlace);

        // When we loop over the lines we want to make sure that we do not get the lines that were split automatically
        _WhseActLineTake.SetRange(MOBLineSplitAutomatically, false);

        OnAfterFilterWhseActLineTake(_WhseActLineTake, _WhseActHeader, _WhseActLinePlace);
    end;

    local procedure ResetQtyToHandle(var _WhseActLine: Record "Warehouse Activity Line")
    var
        MobSetup: Record "MOB Setup";
        IsHandled: Boolean;
    begin
        OnBeforeResetQtyToHandle(_WhseActLine, IsHandled);
        if IsHandled then
            exit;

        // -> set quantity to handle to 0 for both the take and place line (if it exists)
        // If the line is a break bulk line the quantity to handle should be set to the outstanding qty.
        // for both the take and place line
        MobSetup.Get();

        if _WhseActLine.FindFirst() then
            repeat
                if (_WhseActLine."Breakbulk No." > 0) and (MobSetup."Post breakbulk automatically") then
                    _WhseActLine.Validate("Qty. to Handle", _WhseActLine."Qty. Outstanding")
                else
                    _WhseActLine.Validate("Qty. to Handle", 0);
                _WhseActLine.Modify();
            until _WhseActLine.Next() = 0;
    end;

    local procedure BuildTrackedReservationsList(_WhseActivityLine: Record "Warehouse Activity Line"; var _TempReservEntry: Record "Reservation Entry" temporary; var _PrefixedLineNosCleared: Boolean)
    var
        ReservEntry: Record "Reservation Entry";
        ReservEntry2: Record "Reservation Entry";
        MobWhseItemTrackingSetup: Record "MOB Tracking Setup";
        ReservedQuantity: Decimal;
        DummyWhseRegisterExpirationDate: Boolean;
    begin
        // Only relevant for outbound activities
        if not (_WhseActivityLine."Activity Type" in [_WhseActivityLine."Activity Type"::"Invt. Pick", _WhseActivityLine."Activity Type"::Pick]) then
            exit;
        // if Warehouse Tracking is enabled all pick lines will already be divided according to the tracking/reservations, no special handling is needed
        if not SpecialTrackingHandlingNeeded(_WhseActivityLine) then
            exit;

        ReservEntry.SetCurrentKey(
          "Source ID", "Source Ref. No.", "Source Type", "Source Subtype",
          "Source Batch Name", "Source Prod. Order Line", "Reservation Status",
          "Shipment Date", "Expected Receipt Date");
        ReservEntry.SetRange("Source ID", _WhseActivityLine."Source No.");
        ReservEntry.SetRange("Source Ref. No.", _WhseActivityLine."Source Line No.");
        ReservEntry.SetRange("Source Type", _WhseActivityLine."Source Type");
        ReservEntry.SetRange("Source Subtype", _WhseActivityLine."Source Subtype");
        ReservEntry.SetRange("Source Batch Name", '');
        ReservEntry.SetRange("Source Prod. Order Line", 0);
        ReservEntry.SetRange("Reservation Status", ReservEntry."Reservation Status"::Reservation);

        // -----------------------------------------------------------------------------------------------
        // Known inconsistency in this code:
        // -----------------------------------------------------------------------------------------------
        // Is clearing the MobPrefixedLineNo for the first line only -- subsequent lines are not cleared.
        //
        // When the 5 code lines below are included the 2nd update at the page will combine remaining
        // SN lines into a total quantity, but allow registering. However, no information about which SN
        // to register is available.
        //
        // If the 5 lines below are excluded the 2nd update will attempt to exclude the partially posted
        // tracking, but it is not working as intended. The correct number of remaining SN lines are
        // displayed, but with incorrect serial numbers. Rather than being remaining serial numbers it will
        // be the same numbers as before (ordered from top to bottom, regardless what was registered).
        // Reason being GetPickedQty() below cannot recognize already picked quantities when no warehouse 
        // tracking is enabled (which was a condition in SpecialTrackingHandlingNeeded above).
        // Item numbers TF-SNALL and TF-LOTALL can be used for testing at location WHITE.
        if not _PrefixedLineNosCleared then
            if not ReservEntry.IsEmpty() then
                ReservEntry.ModifyAll(MOBPrefixedLineNo, '');

        _PrefixedLineNosCleared := true;
        ReservEntry.SetRange(MOBPrefixedLineNo, '');

        if ReservEntry.FindSet() then
            repeat
                MobWhseItemTrackingSetup.DetermineWhseTrackingRequired(_WhseActivityLine."Item No.", DummyWhseRegisterExpirationDate);
                // MobWhseItemTrackingSetup.Tracking: Copy later (delay copying tracking until _TempReservEntry is conditionally updated from ReservEntry2)

                _TempReservEntry := ReservEntry;
                // If only supply line is tracked (non-specific reservation) get the tracking from supply line if Warehouse Tracking is not enabled
                // otherwise posting will fail because supply line (Item Ledger Entry No.) changes with changed serial/lot
                if (_TempReservEntry."Item Tracking" = _TempReservEntry."Item Tracking"::None) and
                    not (MobWhseItemTrackingSetup.TrackingRequired())
                then begin
                    ReservEntry2.Get(ReservEntry."Entry No.", not ReservEntry.Positive);
                    _TempReservEntry."Item Tracking" := ReservEntry2."Item Tracking";
                    _TempReservEntry.CopyTrackingFromReservEntry(ReservEntry2);
                end;

                // MobWhseItemTrackingSetup.TrackingRequired: Determined before (at top of current ReservEntry loop)
                MobWhseItemTrackingSetup.CopyTrackingFromReservEntry(_TempReservEntry);

                // If the item has already been picked on a partial post of a pick on the same sales order we need to make sure it's not sent to the scanner again
                // (the reservation entry created by reserving a specific serial/lot are exactly the same as the ones made by a partial picking of tracked items)
                if GetPickedQty(_WhseActivityLine, MobWhseItemTrackingSetup) >= Abs(_TempReservEntry."Quantity (Base)") then
                    _TempReservEntry."Item Tracking" := _TempReservEntry."Item Tracking"::None;
                if _TempReservEntry."Item Tracking" <> _TempReservEntry."Item Tracking"::None then begin
                    // The reservation entry may have a larger quantity than the WhseActivityLine. This must be handled.
                    if -_TempReservEntry."Quantity (Base)" > _WhseActivityLine."Qty. Outstanding (Base)" then begin  // Reservation entry is outbound, hence negative qty.
                        _TempReservEntry."Quantity (Base)" := -_WhseActivityLine."Qty. Outstanding (Base)";
                        _TempReservEntry.Quantity := -_WhseActivityLine."Qty. Outstanding";
                    end;
                    if _TempReservEntry.Insert() then;  // Take into account that several reservations may exist for one WhseActivityLine
                    ReservedQuantity -= _TempReservEntry."Quantity (Base)" // Outbound activities are negative
                end;
            until (ReservEntry.Next() = 0) or (ReservedQuantity >= _WhseActivityLine."Qty. (Base)");
    end;

    local procedure SpecialTrackingHandlingNeeded(_WhseActivityLine: Record "Warehouse Activity Line"): Boolean
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        Location: Record Location;
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
    begin
        // If item is not tracked, then special handling is not needed.
        if not (Item.Get(_WhseActivityLine."Item No.") and ItemTrackingCode.Get(Item."Item Tracking Code")) then
            exit(false);

        // If item tracking code has warehouse tracking enabled and Tracking has been filled on the line
        // then special handling is not needed.
        Location.Get(_WhseActivityLine."Location Code");
        if MobWmsToolbox.IsWarehouseTracking(ItemTrackingCode) and
            _WhseActivityLine.TrackingExists()
        then
            exit(false);

        // Tracked and reserved with no warehouse tracking may leave one pick line for several lot/serials and reservations. These need special handling.
        exit(true);
    end;

    local procedure GetPickedQty(_WhseActLine: Record "Warehouse Activity Line"; _MobTrackingSetup: Record "MOB Tracking Setup"): Decimal
    var
        RegisteredWhseActLine: Record "Registered Whse. Activity Line";
    begin
        RegisteredWhseActLine.SetCurrentKey("Source Type", "Source Subtype", "Source No.", "Source Line No.", "Source Subline No.", "Whse. Document No.", "Serial No.", "Lot No.", "Action Type");
        RegisteredWhseActLine.SetRange("Source Type", _WhseActLine."Source Type");
        RegisteredWhseActLine.SetRange("Source Subtype", _WhseActLine."Source Subtype");
        RegisteredWhseActLine.SetRange("Source No.", _WhseActLine."Source No.");
        RegisteredWhseActLine.SetRange("Source Line No.", _WhseActLine."Source Line No.");
        RegisteredWhseActLine.SetRange("Source Subline No.", _WhseActLine."Source Subline No.");
        RegisteredWhseActLine.SetRange("Whse. Document No.", _WhseActLine."Whse. Document No.");
        _MobTrackingSetup.SetTrackingFilterForRegisteredWhseActLine(RegisteredWhseActLine);
        RegisteredWhseActLine.SetRange("Action Type", RegisteredWhseActLine."Action Type"::Take);
        RegisteredWhseActLine.CalcSums("Qty. (Base)");
        exit(RegisteredWhseActLine."Qty. (Base)");
    end;

    local procedure GetTypesFromWhseActHeader(_WhseActHeader: Record "Warehouse Activity Header"; var _IsAnyPutAway: Boolean; var _IsAnyPick: Boolean; var _IsAnyMovement: Boolean)
    begin
        _IsAnyPutAway := _WhseActHeader.Type in [_WhseActHeader.Type::"Put-away", _WhseActHeader.Type::"Invt. Put-away"];
        _IsAnyPick := _WhseActHeader.Type in [_WhseActHeader.Type::Pick, _WhseActHeader.Type::"Invt. Pick"];
        _IsAnyMovement := _WhseActHeader.Type in [_WhseActHeader.Type::Movement, _WhseActHeader.Type::"Invt. Movement"];
    end;

    local procedure GetTypesFromWhseActLine(_WhseActLineTake: Record "Warehouse Activity Line"; var _IsAnyPutAway: Boolean; var _IsAnyPick: Boolean; var _IsAnyMovement: Boolean)
    begin
        _IsAnyPutAway := _WhseActLineTake."Activity Type" in [_WhseActLineTake."Activity Type"::"Put-away", _WhseActLineTake."Activity Type"::"Invt. Put-away"];
        _IsAnyPick := _WhseActLineTake."Activity Type" in [_WhseActLineTake."Activity Type"::Pick, _WhseActLineTake."Activity Type"::"Invt. Pick"];
        _IsAnyMovement := _WhseActLineTake."Activity Type" in [_WhseActLineTake."Activity Type"::Movement, _WhseActLineTake."Activity Type"::"Invt. Movement"];
    end;

    local procedure AddBaseOrderLineElements(_FromWhseActHeader: Record "Warehouse Activity Header"; var _XmlResponseData: XmlNode; var _LineElement: Record "MOB NS BaseDataModel Element")
    var
        CursorMgt: Codeunit "MOB Cursor Management";
        XmlMgt: Codeunit "MOB XML Management";
    begin
        // store current cursor and sorting, then set default sorting to be used for the export
        CursorMgt.Backup(_LineElement);

        // set sorting to be used for the export, then write to xml
        SetCurrentKeyLine(_FromWhseActHeader, _LineElement);
        XmlMgt.AddNsBaseDataModelBaseOrderLineElements(_XmlResponseData, _LineElement);

        // restore cursor and sorting
        CursorMgt.Restore(_LineElement);
    end;

    local procedure SetCurrentKeyLine(_FromWhseActHeader: Record "Warehouse Activity Header"; var _BaseOrderLineElement: Record "MOB NS BaseDataModel Element")
    var
        TempLineElementCustomView: Record "MOB NS BaseDataModel Element" temporary;
        MobWmsPutAway: Codeunit "MOB WMS Put Away";
        MobWmsPick: Codeunit "MOB WMS Pick";
        MobWmsMove: Codeunit "MOB WMS Move";
        IsAnyPick: Boolean;
        IsAnyPutAway: Boolean;
        IsAnyMovement: Boolean;
    begin
        GetTypesFromWhseActHeader(_FromWhseActHeader, IsAnyPutAway, IsAnyPick, IsAnyMovement);

        _BaseOrderLineElement.SetCurrentKey("Sorting1 (internal)", "Sorting2 (internal)", "Sorting3 (internal)", "Sorting4 (internal)", "Sorting5 (internal)");

        // use new temporary/empty record for integration event to prevent SetValues from being in effect at this point in time
        TempLineElementCustomView.SetView(_BaseOrderLineElement.GetView());
        if IsAnyPutAway then
            MobWmsPutAway.OnGetPutAwayOrderLines_OnAfterSetCurrentKey(TempLineElementCustomView);
        if IsAnyPick then
            MobWmsPick.OnGetPickOrderLines_OnAfterSetCurrentKey(TempLineElementCustomView);
        if IsAnyMovement then
            MobWmsMove.OnGetMoveOrderLines_OnAfterSetCurrentKey(TempLineElementCustomView);
        _BaseOrderLineElement.SetView(TempLineElementCustomView.GetView());
    end;

    local procedure SetFromWhseActivityHeader(_WhseActHeader: Record "Warehouse Activity Header"; var _BaseOrder: Record "MOB NS BaseDataModel Element")
    var
        Location: Record Location;
        Customer: Record Customer;
        Vendor: Record Vendor;
        TransferHeader: Record "Transfer Header";
        TempGroupedWhseActLine: Record "Warehouse Activity Line" temporary;
        MobSetup: Record "MOB Setup";
        MobUoMMgt: Codeunit "MOB Unit of Measure Management";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        MobToolbox: Codeunit "MOB Toolbox";
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
        MobWmsPutAway: Codeunit "MOB WMS Put Away";
        MobWmsPick: Codeunit "MOB WMS Pick";
        MobWmsMove: Codeunit "MOB WMS Move";
        MobLicensePlateMgt: Codeunit "MOB License Plate Mgt";
        RecRef: RecordRef;
        NoOfWhseDocuments: Integer;
        TotalWeight: Decimal;
        TotalCubage: Decimal;
        TotalWeightCubageSubstStr: Text;
        IsAnyPick: Boolean;
        IsAnyPutAway: Boolean;
        IsAnyMovement: Boolean;
        TotePickingEnabled: Boolean;
    begin
        // Add the data elements to the <Order> element
        MobSetup.Get();

        GetTypesFromWhseActHeader(_WhseActHeader, IsAnyPutAway, IsAnyPick, IsAnyMovement);

        if not Location.Get(_WhseActHeader."Location Code") then
            Clear(Location);

        _BaseOrder.Init();
        _BaseOrder.Set_BackendID(_WhseActHeader."No.");

        TotePickingEnabled := (_WhseActHeader.Type = _WhseActHeader.Type::Pick) and _WhseActHeader."MOB GetTotePickingEnabled"();
        _BaseOrder.Set_TotePicking(TotePickingEnabled);
        if TotePickingEnabled then
            _BaseOrder.SetValue('ToggleTotePickingTitle', MobWmsLanguage.GetMessage('DISABLE_TOTE_PICKING'))
        else
            _BaseOrder.SetValue('ToggleTotePickingTitle', MobWmsLanguage.GetMessage('ENABLE_TOTE_PICKING'));

        // Set which values that should be displayed on the line
        if _WhseActHeader.Type in [_WhseActHeader.Type::"Invt. Pick", _WhseActHeader.Type::"Invt. Put-away"] then begin
            _BaseOrder.Set_DisplayLine1(Format(_WhseActHeader."Source Document") + ' ' + _WhseActHeader."Source No.");

            // DisplayLine2
            // DisplayLine5
            case _WhseActHeader."Destination Type" of
                _WhseActHeader."Destination Type"::Customer:
                    begin
                        _BaseOrder.Set_DisplayLine2(Customer.Get(_WhseActHeader."Destination No."), Customer.Name, _WhseActHeader."Destination No.");
                        if _WhseActHeader."Shipment Date" <> 0D then
                            _BaseOrder.Set_DisplayLine5(StrSubstNo(MobWmsLanguage.GetMessage('SHIPMENT_DATE'), MobWmsToolbox.Date2TextAsDisplayFormat(_WhseActHeader."Shipment Date")));
                    end;
                _WhseActHeader."Destination Type"::Vendor:
                    begin
                        _BaseOrder.Set_DisplayLine2(Vendor.Get(_WhseActHeader."Destination No."), Vendor.Name, _WhseActHeader."Destination No.");
                        if _WhseActHeader."Expected Receipt Date" <> 0D then
                            _BaseOrder.Set_DisplayLine5(StrSubstNo(MobWmsLanguage.GetMessage('EXPECTED_RECEIPT_DATE'), MobWmsToolbox.Date2TextAsDisplayFormat(_WhseActHeader."Expected Receipt Date")));
                    end;
                _WhseActHeader."Destination Type"::Location:
                    if TransferHeader.Get(_WhseActHeader."Source No.") then
                        case _WhseActHeader."Source Document" of
                            _WhseActHeader."Source Document"::"Outbound Transfer":
                                begin
                                    _BaseOrder.Set_DisplayLine2(StrSubstNo(MobWmsLanguage.GetMessage('TO'), TransferHeader."Transfer-to Name"));
                                    if _WhseActHeader."Shipment Date" <> 0D then
                                        _BaseOrder.Set_DisplayLine5(StrSubstNo(MobWmsLanguage.GetMessage('SHIPMENT_DATE'), MobWmsToolbox.Date2TextAsDisplayFormat(_WhseActHeader."Shipment Date")));
                                end;
                            _WhseActHeader."Source Document"::"Inbound Transfer":
                                begin
                                    _BaseOrder.Set_DisplayLine2(StrSubstNo(MobWmsLanguage.GetMessage('FROM'), TransferHeader."Transfer-from Name"));
                                    if _WhseActHeader."Expected Receipt Date" <> 0D then
                                        _BaseOrder.Set_DisplayLine5(StrSubstNo(MobWmsLanguage.GetMessage('EXPECTED_RECEIPT_DATE'), MobWmsToolbox.Date2TextAsDisplayFormat(_WhseActHeader."Expected Receipt Date")));
                                end;
                        end
                    else
                        _BaseOrder.Set_DisplayLine2(_WhseActHeader."Destination No.");
            end;

            _BaseOrder.Set_DisplayLine3(
                (Location.Name <> ''),
                Location.Name,
                _WhseActHeader."Location Code");

            _BaseOrder.Set_DisplayLine4(Format(_WhseActHeader.Type) + ': ' + _WhseActHeader."No.");
        end else begin  // not Invt.Pick or Invt.PutAway
            _BaseOrder.Set_DisplayLine1(_WhseActHeader."No.");

            _BaseOrder.Set_DisplayLine2(
                (MobToolbox.AsInteger(_WhseActHeader."Source Document") > 0),
                Format(_WhseActHeader."Source Document") + ' ' + _WhseActHeader."Source No.",
                StrSubstNo(MobWmsLanguage.GetMessage('NO_OF_LINES'), Format(_WhseActHeader."MOB No. of Lines")));

            // Display Source Documents information (Source Document, count and total Cubage/Weight)
            if IsAnyPick then begin
                GetSourceDocumentsInformation(_WhseActHeader, TempGroupedWhseActLine, TotalWeight, TotalCubage);

                NoOfWhseDocuments := TempGroupedWhseActLine.Count();
                if NoOfWhseDocuments > 0 then begin
                    TempGroupedWhseActLine.FindFirst();
                    _BaseOrder.Set_DisplayLine3(StrSubstNo('%1: %2', MobWmsLanguage.GetMessage('TYPE'), Format(TempGroupedWhseActLine."Whse. Document Type")));
                    _BaseOrder.Set_DisplayLine4(NoOfWhseDocuments = 1,
                        MobWmsLanguage.GetMessage('DOCUMENT') + ': ' + TempGroupedWhseActLine."Whse. Document No.",
                        StrSubstNo(MobWmsLanguage.GetMessage('NO_OF_DOCUMENTS'), Format(NoOfWhseDocuments)));
                end;

                TotalWeight := Round(TotalWeight, MobUoMMgt.WeightRndPrecision());
                TotalCubage := Round(TotalCubage, MobUoMMgt.CubageRndPrecision());
                case true of
                    (TotalWeight > 0) and (TotalCubage > 0):
                        TotalWeightCubageSubstStr := '%1: %2  /  %3: %4';
                    TotalWeight > 0:
                        TotalWeightCubageSubstStr := '%1: %2';
                    TotalCubage > 0:
                        TotalWeightCubageSubstStr := '%3: %4';
                end;
                if TotalWeightCubageSubstStr <> '' then
                    _BaseOrder.Set_DisplayLine5(StrSubstNo(TotalWeightCubageSubstStr,
                        MobWmsLanguage.GetMessage('WEIGHT_LABEL'),
                        MobWmsToolbox.Decimal2TextAsDisplayFormat(TotalWeight),
                        MobWmsLanguage.GetMessage('CUBAGE_LABEL'),
                        MobWmsToolbox.Decimal2TextAsDisplayFormat(TotalCubage)));
            end;
        end;    // not Invt.Pick or Invt.PutAway

        _BaseOrder.Set_HeaderLabel1(MobWmsLanguage.GetMessage('ORDER_NUMBER'));
        _BaseOrder.Set_HeaderValue1(_WhseActHeader."No.");

        if MobToolbox.AsInteger(_WhseActHeader."Source Document") > 0 then begin
            _BaseOrder.Set_HeaderLabel2(MobWmsLanguage.GetMessage('DOCUMENT'));
            _BaseOrder.Set_HeaderValue2(Format(_WhseActHeader."Source Document") + ' ' + _WhseActHeader."Source No.");
        end;

        _BaseOrder.Set_ReferenceID(_WhseActHeader);
        _BaseOrder.Set_Status();   // Set Locked/Has Attachment symbol (1=Unlocked, 2=Locked, 3=Attachment)

        // Check if any related LP exists and mark the element with ContainsLicensePlate to show the LP icon in the Order List
        if IsAnyPutAway and MobLicensePlateMgt.RelatedLicensePlatesExists(_WhseActHeader) then
            _BaseOrder.SetValue('ContainsLicensePlate', 'true');

        if IsAnyPutAway then
            MobWmsPutAway.OnGetPutAwayOrders_OnAfterSetFromWarehouseActivityHeader(_WhseActHeader, _BaseOrder);
        if IsAnyPick then begin
            RecRef.GetTable(_WhseActHeader);
            MobWmsPick.OnGetPickOrders_OnAfterSetFromWarehouseActivityHeader(_WhseActHeader, _BaseOrder);
            MobWmsPick.OnGetPickOrders_OnAfterSetFromAnyHeader(RecRef, _BaseOrder); // Pick can be any of warehouse activity, sales order, transfer order, purch return order
        end;
        if IsAnyMovement then
            MobWmsMove.OnGetMoveOrders_OnAfterSetFromWarehouseActivityHeader(_WhseActHeader, _BaseOrder);

    end;

    local procedure GetSourceDocumentsInformation(_WhseActivityHeader: Record "Warehouse Activity Header"; var _TempGroupedWhseActLine: Record "Warehouse Activity Line"; var _TotalWeight: Decimal; var _TotalCubage: Decimal)
    var
        WhseActivityLine: Record "Warehouse Activity Line";
        xWhseActivityLine: Record "Warehouse Activity Line";
        WmsMgt: Codeunit "WMS Management";
    begin
        if not _TempGroupedWhseActLine.IsTemporary() then
            Error(MUST_BE_TEMPORARY_Err, _TempGroupedWhseActLine.TableCaption());

        if not _TempGroupedWhseActLine.IsEmpty() then
            _TempGroupedWhseActLine.DeleteAll();

        WhseActivityLine.Reset();
        WhseActivityLine.SetRange("Activity Type", _WhseActivityHeader."Type");
        WhseActivityLine.SetRange("No.", _WhseActivityHeader."No.");
        SetWhseActLineFilter(WhseActivityLine, _WhseActivityHeader);
        if WhseActivityLine.FindSet() then
            repeat
                // Assuming lines for the same Whse. Document Type + Whse. Document No. is grouped at the activity (that same Whse Document do not repeat later at the activity)
                if (WhseActivityLine."Whse. Document Type" <> xWhseActivityLine."Whse. Document Type") or (WhseActivityLine."Whse. Document No." <> xWhseActivityLine."Whse. Document No.") then begin
                    _TempGroupedWhseActLine := WhseActivityLine;
                    _TempGroupedWhseActLine.Insert();
                end;

                WmsMgt.CalcCubageAndWeight(WhseActivityLine."Item No.", WhseActivityLine."Unit of Measure Code", WhseActivityLine."Qty. Outstanding", WhseActivityLine.Cubage, WhseActivityLine.Weight);
                _TotalWeight += WhseActivityLine.Weight;
                _TotalCubage += WhseActivityLine.Cubage;

                xWhseActivityLine := WhseActivityLine;
            until WhseActivityLine.Next() = 0;
    end;

    local procedure SetFromWhseActivityLine(_WhseActHeader: Record "Warehouse Activity Header";
        _PrimaryWhseActLine: Record "Warehouse Activity Line";
        _MobPrimaryItemTrackingSetup: Record "MOB Tracking Setup";
        _PairedWhseActLine: Record "Warehouse Activity Line";
        var _BaseOrderLine: Record "MOB NS BaseDataModel Element";
        _ReservationEntry: Record "Reservation Entry";
        _FromBin: Code[20];
        _ToBin: Code[20];
        _PrimaryExpDateRequired: Boolean)
    var
        MobSetup: Record "MOB Setup";
        TempSteps: Record "MOB Steps Element" temporary;
        Location: Record Location;
        Item: Record Item;
        MobToolbox: Codeunit "MOB Toolbox";
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
        MobItemReferenceMgt: Codeunit "MOB Item Reference Mgt.";
        MobOverReceiptMgt: Codeunit "MOB Over-Receipt Mgt.";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        MobWmsPutAway: Codeunit "MOB WMS Put Away";
        MobWmsPick: Codeunit "MOB WMS Pick";
        MobWmsMove: Codeunit "MOB WMS Move";
        MobWmsLicensePlatePick: Codeunit "MOB WMS License Plate Pick";
        RecRefPick: RecordRef;
        ValidationWarningType: Enum "MOB ValidationWarningType";
        IsAnyPick: Boolean;
        IsAnyPutAway: Boolean;
        IsAnyMovement: Boolean;
    begin
        MobSetup.Get();

        GetTypesFromWhseActLine(_PrimaryWhseActLine, IsAnyPutAway, IsAnyPick, IsAnyMovement);

        // Add the data to the order line element
        _BaseOrderLine.Init();
        _BaseOrderLine.Set_OrderBackendID(_PrimaryWhseActLine."No.");

        if _ReservationEntry.MOBPrefixedLineNo <> '' then
            _BaseOrderLine.Set_LineNumber(_ReservationEntry.MOBPrefixedLineNo)
        else
            _BaseOrderLine.Set_LineNumber(_PrimaryWhseActLine."Line No.");

        _BaseOrderLine.Set_FromBin(_FromBin);
        _BaseOrderLine.Set_ToBin(_ToBin);

        if (Location.Get(_PrimaryWhseActLine."Location Code")) and (Location."Bin Mandatory") then begin
            _BaseOrderLine.Set_ValidateFromBin(IsAnyPick or IsAnyMovement);
            _BaseOrderLine.Set_ValidateToBin(IsAnyPutAway or IsAnyMovement);
        end else begin
            // No location or no mandatory bin -> no bin validation
            _BaseOrderLine.Set_ValidateFromBin(false);
            _BaseOrderLine.Set_ValidateToBin(false);
        end;

        _BaseOrderLine.SetValue('SourceReferenceID', MobWmsToolbox.GetSourceReferenceIDFromWhseActivityLine(_PrimaryWhseActLine));
        _BaseOrderLine.Set_Location(Location.Code);
        _BaseOrderLine.Set_ItemNumber(_PrimaryWhseActLine."Item No.");
        _BaseOrderLine.Set_Description(_PrimaryWhseActLine.Description);

        // Use the cross reference (type = barcode) as the barcode
        _BaseOrderLine.Set_ItemBarcode(MobItemReferenceMgt.GetBarcodeList(_PrimaryWhseActLine."Item No.", _PrimaryWhseActLine."Variant Code", _PrimaryWhseActLine."Unit of Measure Code"));

        // Tracking is populated from _MobPrimaryItemTrackingSetup rather than placeholders at PrimaryWhseActLine (unlike earlier releases)
        // TrackingRequired is from DetermineItemTracking
        _BaseOrderLine.SetTracking(_MobPrimaryItemTrackingSetup);
        _BaseOrderLine.Set_ExpirationDate(_PrimaryWhseActLine."Expiration Date");

        _BaseOrderLine.SetRegisterTracking(_MobPrimaryItemTrackingSetup);
        _BaseOrderLine.Set_RegisterExpirationDate(_PrimaryExpDateRequired);

        // If the <RegisterQuantityByScan> element is set to true the mobile device can use values in <BarcodeQuantity>
        // element to register the quantity associated with barcode instead of always registering 1.
        _BaseOrderLine.Set_RegisterQuantityByScan(false);

        _BaseOrderLine.Set_Quantity(MobSetup."Use Base Unit of Measure", _PrimaryWhseActLine."Qty. Outstanding (Base)", _PrimaryWhseActLine."Qty. Outstanding");

        _BaseOrderLine.Set_RegisteredQuantity('0');

        Item.Get(_PrimaryWhseActLine."Item No.");
        _BaseOrderLine.Set_UnitOfMeasure(MobSetup."Use Base Unit of Measure", Item."Base Unit of Measure", _PrimaryWhseActLine."Unit of Measure Code");

        // Set which values that should be displayed on the line
        // There are 5 display lines available in the standard configuration
        // Line 1: Show the Bin
        // Line 2: Show the Item Number + UoM under the quantity (this is handled in the UserRole.xml on the mobile device)
        // Line 3: Show the Item Description
        // Line 4: Show the Destination (if tote picking is enabled else Lot/Serial info)
        // Line 5: Show the Item Variant
        // IF Movement document THEN
        // Line 1: Show the From Bin
        // Line 2: Show the To Bin + UoM under the quantity (this is handled in the UserRole.xml on the mobile device)
        // Line 3: Show the Item Number
        // Line 4: Show the Item Description
        // Line 5: Show the Item Variant
        case true of
            IsAnyPutAway:
                begin
                    _BaseOrderLine.Set_DisplayLine1(_BaseOrderLine.Get_ToBin() <> '', _BaseOrderLine.Get_ToBin(), _PrimaryWhseActLine."Shelf No.");
                    _BaseOrderLine.Set_DisplayLine2(_PrimaryWhseActLine."Item No.");
                    _BaseOrderLine.Set_DisplayLine3(_PrimaryWhseActLine.Description);
                    _BaseOrderLine.Set_DisplayLine4('');   // may get overridden below, but ensure tag is always in file
                    if _PrimaryWhseActLine."Breakbulk No." <> 0 then
                        _BaseOrderLine.Set_DisplayLine1(_BaseOrderLine.Get_DisplayLine1() + MobToolbox.CRLFSeparator() +
                                                                'Breakbulk: ' + Format(_PairedWhseActLine."Qty. Outstanding") + ' ' + _PairedWhseActLine."Unit of Measure Code" + ' -> ' +
                                                                Format(_PrimaryWhseActLine."Qty. Outstanding") + ' ' + _PrimaryWhseActLine."Unit of Measure Code");
                end;
            IsAnyPick:
                begin
                    _BaseOrderLine.Set_DisplayLine1(_BaseOrderLine.Get_FromBin() <> '', _BaseOrderLine.Get_FromBin(), _PrimaryWhseActLine."Shelf No.");
                    _BaseOrderLine.Set_DisplayLine2(_PrimaryWhseActLine."Item No.");
                    _BaseOrderLine.Set_DisplayLine3(_PrimaryWhseActLine.Description);
                    _BaseOrderLine.Set_DisplayLine4('');   // may get overridden below, but ensure tag is always in file
                    if _PrimaryWhseActLine."Breakbulk No." <> 0 then
                        _BaseOrderLine.Set_DisplayLine1(_BaseOrderLine.Get_DisplayLine1() + MobToolbox.CRLFSeparator() +
                                                                'Breakbulk: ' + Format(_PrimaryWhseActLine."Qty. Outstanding") + ' ' + _PrimaryWhseActLine."Unit of Measure Code" + ' -> ' +
                                                                Format(_PairedWhseActLine."Qty. Outstanding") + ' ' + _PairedWhseActLine."Unit of Measure Code");
                end;
            IsAnyMovement:
                begin
                    _BaseOrderLine.Set_DisplayLine1(_BaseOrderLine.Get_FromBin());
                    _BaseOrderLine.Set_DisplayLine2(_BaseOrderLine.Get_ToBin());
                    _BaseOrderLine.Set_DisplayLine3(_PrimaryWhseActLine."Item No.");
                    _BaseOrderLine.Set_DisplayLine4(_PrimaryWhseActLine.Description);
                    if _PrimaryWhseActLine."Breakbulk No." <> 0 then
                        _BaseOrderLine.Set_DisplayLine1(_BaseOrderLine.Get_DisplayLine1() + MobToolbox.CRLFSeparator() +
                                                                'Breakbulk: ' + Format(_PrimaryWhseActLine."Qty. Outstanding") + ' ' + _PrimaryWhseActLine."Unit of Measure Code" + ' -> ' +
                                                                Format(_PairedWhseActLine."Qty. Outstanding") + ' ' + _PairedWhseActLine."Unit of Measure Code");
                end;
        end;

        // DisplayLine4 for PutAway and Pick
        if (not IsAnyMovement) then
            if _WhseActHeader."MOB GetTotePickingEnabled"() and TotePickingAllowed(_PrimaryWhseActLine) then    // exclude Inventory Picks, breakbulk and picks with different Whse. Document type than Shipment
                case MobSetup."Tote per" of
                    MobSetup."Tote per"::"Destination No.":
                        _BaseOrderLine.Set_DisplayLine4(
                           _PrimaryWhseActLine."Destination No." <> '',
                            Format(_PrimaryWhseActLine."Destination Type") + ': ' + _PrimaryWhseActLine."Destination No.",
                            Format(_PrimaryWhseActLine."Source Document") + ': ' + _PrimaryWhseActLine."Source No.");
                    MobSetup."Tote per"::"Source No.":
                        _BaseOrderLine.Set_DisplayLine4(Format(_PrimaryWhseActLine."Source Document") + ': ' + _PrimaryWhseActLine."Source No.");
                    MobSetup."Tote per"::"Whse. Document No.":
                        _BaseOrderLine.Set_DisplayLine4(Format(_PrimaryWhseActLine."Whse. Document Type") + ': ' + _PrimaryWhseActLine."Whse. Document No.");
                end
            else begin
                _BaseOrderLine.Set_DisplayLine4(_MobPrimaryItemTrackingSetup.FormatTracking());

                if _PrimaryWhseActLine."Expiration Date" <> 0D then
                    _BaseOrderLine.Set_DisplayLine4(_BaseOrderLine.Get_DisplayLine4() + MobToolbox.CRLFSeparator() + MobWmsLanguage.GetMessage('EXP_DATE_LABEL') + ': ' + MobWmsToolbox.Date2TextAsDisplayFormat(_PrimaryWhseActLine."Expiration Date"));
            end;

        // Item Variant
        _BaseOrderLine.Set_DisplayLine5(_PrimaryWhseActLine."Variant Code" <> '', MobWmsLanguage.GetMessage('VARIANT_LABEL') + ': ' + _PrimaryWhseActLine."Variant Code", '');

        // UnderDelivery: The choices are: None, Warn, Block
        _BaseOrderLine.Set_UnderDeliveryValidation(ValidationWarningType::Warn);

        // OverDelivery: OverReceipt / OverPick requires validation set to "None" 
        if MobOverReceiptMgt.IsOverReceiptAllowed(_PrimaryWhseActLine) or _PrimaryWhseActLine."MOB ItemAllowWhseOverpick"() then
            _BaseOrderLine.Set_OverDeliveryValidation(ValidationWarningType::None)
        else
            _BaseOrderLine.Set_OverDeliveryValidation(ValidationWarningType::Block);

        // Allow Bin Change
        _BaseOrderLine.Set_AllowBinChange(true);

        _BaseOrderLine.Set_ReferenceID(_PrimaryWhseActLine);
        _BaseOrderLine.Set_Status('0');
        _BaseOrderLine.Set_Attachment();
        _BaseOrderLine.Set_ItemImageID();

        // Tote Picking
        if TotePickingAllowed(_PrimaryWhseActLine) and _WhseActHeader."MOB GetTotePickingEnabled"() then begin
            case MobSetup."Tote per" of
                MobSetup."Tote per"::"Destination No.":
                    _BaseOrderLine.Set_Destination(_PrimaryWhseActLine."Destination No." <> '', _PrimaryWhseActLine."Destination No.", _PrimaryWhseActLine."Source No.");
                MobSetup."Tote per"::"Source No.":
                    _BaseOrderLine.Set_Destination(_PrimaryWhseActLine."Source No.");
                MobSetup."Tote per"::"Whse. Document No.":
                    _BaseOrderLine.Set_Destination(_PrimaryWhseActLine."Whse. Document No.");
            end;

            // 0 = highest priority
            // If different priorities are sent to the mobile device it will make the user handle those lines first
            // An example is that heavy items must be placed at the bottom of the pallet (i.e. picked first)
            // In this case the heavy items can get priority 0 and the rest can get 1
            // In the standard solution all lines are equal
            _BaseOrderLine.Set_Priority('0');

            // The choices are: None, Warn, Block
            _BaseOrderLine.Set_PriorityValidation('None');
        end;

        TempSteps.SetMustCallCreateNext(true);
        if IsAnyPutAway then begin
            MobWmsPutAway.OnGetPutAwayOrderLines_OnAfterSetFromWarehouseActivityLine(_PrimaryWhseActLine, _BaseOrderLine);
            MobWmsPutAway.OnGetPutAwayOrderLines_OnAddStepsToWarehouseActivityLine(_PrimaryWhseActLine, _BaseOrderLine, TempSteps);
        end;
        if IsAnyPick then begin
            RecRefPick.GetTable(_PrimaryWhseActLine);
            MobWmsPick.OnGetPickOrderLines_OnAfterSetFromWarehouseActivityLine(_PrimaryWhseActLine, _BaseOrderLine);
            MobWmsPick.OnGetPickOrderLines_OnAfterSetFromAnyLine(RecRefPick, _BaseOrderLine);

            // Check if LP handling is required and add steps accordingly
            MobWmsLicensePlatePick.HandleFromLicensePlateStep(RecRefPick, _BaseOrderLine, TempSteps);

            MobWmsPick.OnGetPickOrderLines_OnAddStepsToAnyLine(RecRefPick, _BaseOrderLine, TempSteps);
        end;
        if IsAnyMovement then begin
            MobWmsMove.OnGetMoveOrderLines_OnAfterSetFromWarehouseActivityLine(_PrimaryWhseActLine, _BaseOrderLine);
            MobWmsMove.OnGetMoveOrderLines_OnAddStepsToWarehouseActivityLine(_PrimaryWhseActLine, _BaseOrderLine, TempSteps);
        end;

        if not TempSteps.IsEmpty() then
            _BaseOrderLine.Set_Workflow(TempSteps, "MOB TweakType"::Append);
    end;

    local procedure TotePickingAllowed(_WhseActLine: Record "Warehouse Activity Line"): Boolean
    begin
        exit((_WhseActLine."Activity Type" = _WhseActLine."Activity Type"::Pick) and (_WhseActLine."Breakbulk No." = 0) and (_WhseActLine."Whse. Document Type" = _WhseActLine."Whse. Document Type"::Shipment));   // Never collect ToteID for original breakbulk lines or document types other than Shipment
    end;

    local procedure ReReadWhseActLine(var _WhseActLine: Record "Warehouse Activity Line")
    var
        _RenumberedWhseActLine: Record "Warehouse Activity Line";
    begin
        _WhseActLine.TestField(MOBSystemId);

        _RenumberedWhseActLine.Reset();
        _RenumberedWhseActLine.SetCurrentKey(MOBSystemId);
        _RenumberedWhseActLine.SetRange(MOBSystemId, _WhseActLine.MOBSystemId);

        _RenumberedWhseActLine.SetRange("Activity Type", _WhseActLine."Activity Type");
        _RenumberedWhseActLine.SetRange("No.", _WhseActLine."No.");
        _RenumberedWhseActLine.FindSet(); // must exist

        _WhseActLine := _RenumberedWhseActLine;

        // Unique property cannot be used in extension objects : Verify MOBSystemId is indeed unique
        if _RenumberedWhseActLine.Next() <> 0 then
            _RenumberedWhseActLine.FieldError(MOBSystemId);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSplitNeeded(_WhseActLine: Record "Warehouse Activity Line"; _MobWmsRegistration: Record "MOB WMS Registration"; _QuantityToHandle: Decimal; _OrigBinCode: Code[20]; var _SplitNeeded: Boolean; var _IsHandled: Boolean)
    begin
        // Intentionally undocumented in confluence
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFilterWhseActLinePlace(var _WhseActLinePlace: Record "Warehouse Activity Line"; _WhseActHeader: Record "Warehouse Activity Header"; _WhseActLineTake: Record "Warehouse Activity Line")
    begin
        // Intentionally undocumented in confluence
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFilterWhseActLineTake(var _WhseActLineTake: Record "Warehouse Activity Line"; _WhseActHeader: Record "Warehouse Activity Header"; _WhseActLinePlace: Record "Warehouse Activity Line")
    begin
        // Intentionally undocumented in confluence
    end;

    // Intentionally undocumented in confluence
    [IntegrationEvent(false, false)]
    local procedure OnBeforeResetQtyToHandle(var _WhseActLine: Record "Warehouse Activity Line"; var _IsHandled: Boolean)
    begin
    end;

    //
    // ------- IntegrationEvents: GetXXXOrders -------
    // 
    // Currently no published integration events for GetXXXOrders -- use events at document handler codeunits instead ("MOB Put Away", "MOB Pick", "MOB Move")

    // 
    // ------- IntegrationEvents: GetXXXOrderLines -------
    //
    // Currently no published integration events for GetXXXOrders -- use events at document handler codeunits instead ("MOB Put Away", "MOB Pick", "MOB Move")

}
