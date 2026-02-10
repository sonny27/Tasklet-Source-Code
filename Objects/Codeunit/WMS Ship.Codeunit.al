codeunit 81375 "MOB WMS Ship"
{
    Access = Public;
    TableNo = "MOB Document Queue";

    trigger OnRun()
    begin
        MobDocQueue := Rec;

        case Rec."Document Type" of

            // Order headers
            'GetShipOrders':
                GetOrders();

            // Order lines
            'GetShipOrderLines':
                GetOrderLines();

            // Posting
            'PostShipOrder':
                PostOrder();

            else
                Error(MobWmsLanguage.GetMessage('NO_DOC_HANDLER'), Rec."Document Type");
        end;

        MobDocMgt.UpdateResult(Rec, XmlResponseDoc);
    end;

    var
        MobDocQueue: Record "MOB Document Queue";
        MobSessionData: Codeunit "MOB SessionData";
        MobBaseDocHandler: Codeunit "MOB WMS Base Document Handler";
        MobRequestMgt: Codeunit "MOB NS Request Management";
        MobXmlMgt: Codeunit "MOB XML Management";
        MobDocMgt: Codeunit "MOB Document Management";
        MobToolbox: Codeunit "MOB Toolbox";
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        XmlResponseDoc: XmlDocument;
        MUST_BE_TEMPORARY_Err: Label 'Internal error: %1 must be a temporary record.', Locked = true;

    local procedure GetOrders()
    var
        TempBaseOrderElement: Record "MOB NS BaseDataModel Element" temporary;
        XmlRequestDoc: XmlDocument;
        XmlResponseData: XmlNode;
    begin
        // Process:
        // 1. Filter and sort the orders for this particular user
        // 2. Save the result in XML and return it to the mobile device

        // Load the request from the queue
        MobDocQueue.LoadXMLRequestDoc(XmlRequestDoc);

        // Initialize the response document for order data
        MobToolbox.InitializeResponseDoc(XmlResponseDoc, XmlResponseData);

        // Warehouse shipments to buffer
        GetWarehouseShipments(XmlRequestDoc, MobDocQueue, TempBaseOrderElement);

        // Add collected buffer values to new <BaseOrder> nodes
        AddBaseOrderElements(XmlResponseData, TempBaseOrderElement);
    end;

    local procedure GetWarehouseShipments(var _XmlRequestDoc: XmlDocument; var _MobDocQueue: Record "MOB Document Queue"; var _BaseOrderElement: Record "MOB NS BaseDataModel Element")
    var
        WhseShipmentHeader: Record "Warehouse Shipment Header";
        WhseShipmentLine: Record "Warehouse Shipment Line";
        TempWhseShipmentHeader: Record "Warehouse Shipment Header" temporary;
        TempHeaderFilter: Record "MOB NS Request Element" temporary;
        Location: Record Location;
        MobScannedValueMgt: Codeunit "MOB ScannedValue Mgt.";
        IsHandled: Boolean;
        ScannedValue: Text;
    begin
        // Respond with a list of Shipments

        // Mandatory Header filters for this function to operate
        WhseShipmentHeader.SetFilter("Location Code", MobBaseDocHandler.GetLocationFilter_Ship(_MobDocQueue."Mobile User ID"));
        WhseShipmentHeader.SetRange(Status, WhseShipmentHeader.Status::Released);

        // XML filter data into Temporary table
        MobRequestMgt.SaveHeaderFilters(_XmlRequestDoc, TempHeaderFilter);

        if TempHeaderFilter.FindSet() then
            repeat

                //
                // Event to allow for handling (custom) filters
                //
                IsHandled := false;
                OnGetShipOrders_OnSetFilterWarehouseShipment(TempHeaderFilter, WhseShipmentHeader, WhseShipmentLine, IsHandled);

                if not IsHandled then
                    case TempHeaderFilter.Name of

                        'Location':
                            if TempHeaderFilter."Value" = 'All' then
                                // Set the location filter to all locations
                                WhseShipmentHeader.SetFilter("Location Code", MobBaseDocHandler.GetLocationFilter_Ship(_MobDocQueue."Mobile User ID"))
                            else begin
                                Location.Get(TempHeaderFilter."Value");
                                WhseShipmentHeader.SetRange("Location Code", TempHeaderFilter."Value");
                            end;

                        'Date':
                            WhseShipmentLine.SetFilter("Due Date", '<=%1', MobToolbox.Text2Date(TempHeaderFilter."Value"));

                        'ScannedValue':
                            ScannedValue := TempHeaderFilter."Value";   // Used in search for Document No. or Item/Variant later

                        'ShipmentDocumentStatusFilter':
                            case TempHeaderFilter."Value" of
                                'All':
                                    ; // No filter -> do nothing
                                'PartiallyPicked':
                                    WhseShipmentHeader.SetRange("Document Status", WhseShipmentHeader."Document Status"::"Partially Picked");
                                'CompletelyPicked':
                                    WhseShipmentHeader.SetRange("Document Status", WhseShipmentHeader."Document Status"::"Completely Picked");
                                'PartiallyShipped':
                                    WhseShipmentHeader.SetRange("Document Status", WhseShipmentHeader."Document Status"::"Partially Shipped");
                            end;

                        'AssignedUser':
                            case TempHeaderFilter."Value" of
                                'All':
                                    ; // No filter -> do nothing
                                'OnlyMine':
                                    // Set the filter to the current user
                                    WhseShipmentHeader.SetRange("Assigned User ID", _MobDocQueue."Mobile User ID"); // Current user
                                'MineAndUnassigned':
                                    // Set the filter to the current user + blank
                                    WhseShipmentHeader.SetFilter("Assigned User ID", '''''|%1', _MobDocQueue."Mobile User ID"); // Current user or blank
                            end;
                    end;

            until TempHeaderFilter.Next() = 0;

        // Run event once more with Empty "Header filter" to allow for additional filtering directly on the records, NOT related to specific Header filter
        Clear(IsHandled);
        TempHeaderFilter.ClearFields();
        OnGetShipOrders_OnSetFilterWarehouseShipment(TempHeaderFilter, WhseShipmentHeader, WhseShipmentLine, IsHandled);

        // Filter: DocumentNo or Item/Variant (match for scanned document no. at location takes precedence over other filters)
        if ScannedValue <> '' then begin
            MobScannedValueMgt.SetFilterForWhseShipment(WhseShipmentHeader, WhseShipmentLine, ScannedValue);
            WhseShipmentLine.SetRange("Due Date");
        end;

        // Insert orders into temp rec
        MobBaseDocHandler.CopyFilteredWhseShipmentHeadersToTempRecord(WhseShipmentHeader, WhseShipmentLine, TempHeaderFilter, TempWhseShipmentHeader);

        // Respond with resulting orders
        CreateWhseShipmentResponse(TempWhseShipmentHeader, _BaseOrderElement);
    end;

    local procedure CreateWhseShipmentResponse(var _WhseShipmentHeader: Record "Warehouse Shipment Header"; var _BaseOrderElement: Record "MOB NS BaseDataModel Element")
    var
        OpenPickOrders: Boolean;
    begin
        // This was used when Pick and Ship was allowed from mobile device. Kept as this might be introduced again. Explicitly assigned to remove Vsix warning
        OpenPickOrders := false;
        if _WhseShipmentHeader.FindSet() then
            repeat
                // Collect buffer values for the <Order>-<BaseOrder> element
                _BaseOrderElement.Create();
                SetFromWarehouseShipmentHeader(_WhseShipmentHeader, OpenPickOrders, _BaseOrderElement);
                _BaseOrderElement.Save();
            until _WhseShipmentHeader.Next() = 0;
    end;

    local procedure GetOrderLines()
    var
        TempHeaderFilter: Record "MOB NS Request Element" temporary;
        XmlRequestDoc: XmlDocument;
        OrderID: Code[20];
    begin
        // The Request Document looks like this:
        //  <request name="GetXXXOrderLines"
        //           created="2009-01-20T22:36:34-08:00"
        //           xmlns="http://schemas.microsoft.com/Dynamics/Mobile/2007/04>
        //    <requestData name="GetXXXOrderLines">
        //      <BackendID>RE000004</BackendID>
        //    </requestData>
        //  </request>
        //
        MobWmsToolbox.CheckWhseSetupShipment();

        // XML filter data into Temporary table
        MobDocQueue.LoadXMLRequestDoc(XmlRequestDoc);
        MobRequestMgt.SaveAdhocRequestValues(XmlRequestDoc, TempHeaderFilter);

        // We want to extract the BackendID (Order No.) from the XML to get the order lines
        Evaluate(OrderID, TempHeaderFilter.GetValue('BackendID', true));

        CreateWhseShipmentLinesResponse(OrderID);
    end;

    local procedure CreateWhseShipmentLinesResponse(_OrderNo: Code[20])
    var
        Location: Record Location;
        ItemTrackingCode: Record "Item Tracking Code";
        Item: Record Item;
        WhseShipmentHeader: Record "Warehouse Shipment Header";
        WhseShipmentLine: Record "Warehouse Shipment Line";
        TempBaseOrderLineElement: Record "MOB NS BaseDataModel Element" temporary;
        RecRef: RecordRef;
        XmlResponseData: XmlNode;
        IncludeInOrderLines: Boolean;
        RequirePicking: Boolean;
        IsWarehouseTracking: Boolean;
    begin
        // Description:
        // Get the order lines for the requested order.
        // Sort the lines.
        // Create the response XML

        // Initialize the response document for order line data
        MobToolbox.InitializeRespDocWithoutNS(XmlResponseDoc, XmlResponseData);

        // Check Locations Warehouse Setup
        // The order may not exist at this point, because the mobile device
        // will ask for the lines after a post. So if all lines have been posted then the shipment is gone.
        if not WhseShipmentHeader.Get(_OrderNo) then
            exit;

        // Add collectorSteps to be displayed on posting
        RecRef.GetTable(WhseShipmentHeader);
        AddStepsToWarehouseShipmentHeader(WhseShipmentHeader, XmlResponseDoc, XmlResponseData);

        Location.Get(WhseShipmentHeader."Location Code");

        // Respect Sorting Method fields value from Warehouse Shipment Header
        WhseShipmentLine.SetCurrentKey("No.", "Sorting Sequence No.");

        // Filter the lines for this particular order
        WhseShipmentLine.SetRange(WhseShipmentLine."No.", _OrderNo);
        WhseShipmentLine.SetFilter("Qty. Outstanding", '<>0');

        // Event to expose Lines for filtering before Response
        OnGetShipOrderLines_OnSetFilterWarehouseShipmentLine(WhseShipmentLine);

        // Insert the values from the header in the XML
        if WhseShipmentLine.FindSet() then
            repeat

                // Verify addtional conditions from eventsubscribers
                IncludeInOrderLines := true;
                OnGetShipOrderLines_OnIncludeWarehouseShipmentLine(WhseShipmentLine, IncludeInOrderLines);

                if IncludeInOrderLines then begin

                    Item.Get(WhseShipmentLine."Item No.");
                    if not ItemTrackingCode.Get(Item."Item Tracking Code") then
                        Clear(ItemTrackingCode);

                    RequirePicking := Location.RequirePicking(Location.Code);
                    IsWarehouseTracking := MobWmsToolbox.IsWarehouseTracking(ItemTrackingCode);

                    case true of
                        (WhseShipmentLine."Source Type" = Database::"Sales Line") and WhseShipmentLine."Assemble to Order":
                            ATOInsertShptLine(Location, WhseShipmentLine, TempBaseOrderLineElement);
                        RequirePicking and IsWarehouseTracking:
                            InsertShptLineWithPick_WarehouseTracking(Location, WhseShipmentLine, TempBaseOrderLineElement); // i.e. WHITE w/TF-002
                        RequirePicking and (not IsWarehouseTracking):
                            InsertShptLineWithPick_NoWarehouseTracking(Location, WhseShipmentLine, TempBaseOrderLineElement); // i.e. WHITE w/TF-LOTALL
                        (not RequirePicking):
                            InsertShptLineWithoutPick(Location, WhseShipmentLine, TempBaseOrderLineElement); // i.e. BINSHIPREC or SHIPRECPT
                    end;

                end;

            until WhseShipmentLine.Next() = 0;

        // Flush buffer to new <BaseOrderLine>-elements
        AddBaseOrderLineElements(XmlResponseData, TempBaseOrderLineElement);
    end;

    local procedure ATOInsertShptLine(_Location: Record Location; _WhseShipmentLine: Record "Warehouse Shipment Line"; var _TempBaseOrderLineElement: Record "MOB NS BaseDataModel Element")
    var
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        ATOSalesLine: Record "Sales Line";
        AsmHeader: Record "Assembly Header";
        UOMMgt: Codeunit "Unit of Measure Management";
        QtyOutstandingBase: Decimal;
        OrderAbleToAssemble: Decimal;
        OrderAbleToAssembleBase: Decimal;
        QtyPickedBase: Decimal;
        QtyShippedBase: Decimal;
        QtyPickedNotShippedBase: Decimal;
    begin
        // Shipment for Assemble to Order (shipping assembly output item)
        //   "Able to Assemble" cannot be calculated per pre-populated LotNo/SerialNo from the Output item. A single element with no tracking specification is created instead.
        ATOSalesLine.Get(_WhseShipmentLine."Source Subtype", _WhseShipmentLine."Source No.", _WhseShipmentLine."Source Line No.");
        ATOSalesLine.AsmToOrderExists(AsmHeader);
        ATOAvailToAssemble(AsmHeader, OrderAbleToAssemble); // Will subtract a partial shipment from original picked quantity
        OrderAbleToAssembleBase := UOMMgt.CalcBaseQty(OrderAbleToAssemble, AsmHeader."Qty. per Unit of Measure");

        QtyOutstandingBase := _WhseShipmentLine."Qty. Outstanding (Base)";
        QtyPickedBase := OrderAbleToAssembleBase + _WhseShipmentLine."Qty. Shipped (Base)";
        QtyShippedBase := _WhseShipmentLine."Qty. Shipped (Base)";
        QtyPickedNotShippedBase := QtyPickedBase - QtyShippedBase;

        Clear(TempTrackingSpecification);
        InsertFromWarehouseShipmentLine(_WhseShipmentLine, '', _Location, TempTrackingSpecification, QtyOutstandingBase, QtyPickedNotShippedBase, _TempBaseOrderLineElement);  // never set Expiration Date for ship
    end;

    local procedure ATOAvailToAssemble(_AssemblyHeader: Record "Assembly Header"; var _OrderAbleToAssemble: Decimal)
    var
        AssemblyLine: Record "Assembly Line";
        MobCommonMgt: Codeunit "MOB Common Mgt.";
        LineAbleToAssemble: Decimal;
    begin
        AssemblyLine.Reset();
        AssemblyLine.SetRange("Document Type", _AssemblyHeader."Document Type");
        AssemblyLine.SetRange("Document No.", _AssemblyHeader."No.");
        AssemblyLine.SetRange(Type, AssemblyLine.Type::Item);
        AssemblyLine.SetFilter("No.", '<>%1', '');
        AssemblyLine.SetFilter("Quantity per", '<>%1', 0);

        _OrderAbleToAssemble := _AssemblyHeader."Remaining Quantity";
        if AssemblyLine.FindSet() then
            repeat
                if MobCommonMgt.AssemblyLine_IsInventoriableItem(AssemblyLine) then begin

                    LineAbleToAssemble := CalculateLineAbleToAssemble(_AssemblyHeader, AssemblyLine);

                    if LineAbleToAssemble < _OrderAbleToAssemble then
                        _OrderAbleToAssemble := LineAbleToAssemble;
                end;
            until AssemblyLine.Next() = 0;
    end;

    local procedure CalculateLineAbleToAssemble(var _AssemblyHeader: Record "Assembly Header"; var _AssemblyLine: Record "Assembly Line") LineAbleToAssemble: Decimal
    var
        BinContent: Record "Bin Content";
        UOMMgt: Codeunit "Unit of Measure Management";
        QtyAvailToTake: Decimal;
    begin
        // If Pick is mandatory or has been picked, then use the picked quantity - consumed quantity as the available quantity
        if AssemblyConsumptionRequirePicking(_AssemblyLine) or ((_AssemblyLine."Qty. Picked" - _AssemblyLine."Consumed Quantity") > 0) then
            LineAbleToAssemble := Round((_AssemblyLine."Qty. Picked" - _AssemblyLine."Consumed Quantity") / _AssemblyLine."Quantity per", UOMMgt.QtyRndPrecision(), '<')
        else
            if MobWmsToolbox.LocationIsBinMandatory(_AssemblyLine."Location Code") then begin
                // Calculate the available quantity on the Assembly Bin
                if BinContent.Get(_AssemblyLine."Location Code", _AssemblyLine."Bin Code", _AssemblyLine."No.", _AssemblyLine."Variant Code", _AssemblyLine."Unit of Measure Code") then
                    QtyAvailToTake := BinContent.CalcQtyAvailToTake(0)
                else
                    QtyAvailToTake := 0;

                if QtyAvailToTake < _AssemblyLine."Remaining Quantity" then
                    if QtyAvailToTake <= 0 then
                        LineAbleToAssemble := 0
                    else
                        LineAbleToAssemble := Round(QtyAvailToTake / _AssemblyLine."Quantity per", UOMMgt.QtyRndPrecision(), '<')
                else
                    LineAbleToAssemble := _AssemblyHeader."Remaining Quantity";
            end else
                // Without bins it is not possible to calculate the available quantity so we just return the remaining quantity and let the posting fail if inventory is not available
                LineAbleToAssemble := _AssemblyHeader."Remaining Quantity"
    end;

    local procedure AssemblyConsumptionRequirePicking(_AssemblyLine: Record "Assembly Line"): Boolean
    var
        Location: Record Location;
        WhseSetup: Record "Warehouse Setup";
    begin
        /* #if BC23+ */
        if Location.Get(_AssemblyLine."Location Code") then
            exit(Location."Asm. Consump. Whse. Handling" = Location."Asm. Consump. Whse. Handling"::"Warehouse Pick (mandatory)")
        else begin
            WhseSetup.Get();
            exit(WhseSetup."Require Pick");
        end;
        /* #endif */
        /* #if BC22- #/
        exit(Location.RequirePicking(_AssemblyLine."Location Code"))
        /* #endif */
    end;

    local procedure InsertShptLineWithPick_WarehouseTracking(_Location: Record Location; _WhseShipmentLine: Record "Warehouse Shipment Line"; var _TempBaseOrderLineElement: Record "MOB NS BaseDataModel Element")
    var
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        QtyBase: Decimal;
        QtyOutstandingBase: Decimal;
        QtyPickedBase: Decimal;
        QtyShippedBase: Decimal;
        QtyPickedNotShippedBase: Decimal;
        TotalTrackedQtyOutstandingBase: Decimal;
        TotalTrackedQtyPickedNotShippedBase: Decimal;
        RemQtyOutstandingBase: Decimal;
        LineNoPrefix: Text[30];
    begin
        Clear(TotalTrackedQtyOutstandingBase);
        Clear(TotalTrackedQtyPickedNotShippedBase);
        Clear(LineNoPrefix);

        // SumUp WITH Pick and WITH Warehouse Tracking
        //   Picked items with warehouse tracking will have associated reservations entries with lotno/serialno populated. TrackingSpec is split by tracking information
        SumUpWhseShipmentLineItemTracking(_WhseShipmentLine, TempTrackingSpecification, true, true);
        TempTrackingSpecification.SetCurrentKey("Lot No.", "Serial No.");

        if TempTrackingSpecification.FindSet() then begin
            LineNoPrefix := 'P000'; // Prefix on tracked lines only
            repeat
                QtyBase := CalcItemTrkgQuantityBase(_WhseShipmentLine, TempTrackingSpecification);
                QtyOutstandingBase := Abs(TempTrackingSpecification."Quantity (Base)");  // Qty. Shipped is deducted from Reservation Entries quantity on shipment posting
                QtyPickedBase := CalcItemTrkgPickedBase(_WhseShipmentLine, TempTrackingSpecification);
                QtyShippedBase := QtyBase - QtyOutstandingBase;
                QtyPickedNotShippedBase := QtyPickedBase - QtyShippedBase;

                InsertFromWarehouseShipmentLine(_WhseShipmentLine, LineNoPrefix, _Location, TempTrackingSpecification, QtyOutstandingBase, QtyPickedNotShippedBase, _TempBaseOrderLineElement);  // never set Expiration Date for ship

                TotalTrackedQtyOutstandingBase += QtyOutstandingBase;
                TotalTrackedQtyPickedNotShippedBase += TotalTrackedQtyPickedNotShippedBase;
                LineNoPrefix := IncStr(LineNoPrefix);
            until TempTrackingSpecification.Next() = 0;

            RemQtyOutstandingBase := _WhseShipmentLine."Qty. Outstanding (Base)" - TotalTrackedQtyOutstandingBase;
        end else
            RemQtyOutstandingBase := _WhseShipmentLine."Qty. Outstanding (Base)";

        // Display remainder as separate line
        // Assume RemQtyPickedNotShippedBase is always 0 as picked lines would have had tracking and is assumed handled above
        if RemQtyOutstandingBase <> 0 then begin
            Clear(TempTrackingSpecification);
            InsertFromWarehouseShipmentLine(_WhseShipmentLine, LineNoPrefix, _Location, TempTrackingSpecification, RemQtyOutstandingBase, 0, _TempBaseOrderLineElement);  // never set Expiration Date for ship
        end;
    end;

    local procedure InsertShptLineWithPick_NoWarehouseTracking(_Location: Record Location; _WhseShipmentLine: Record "Warehouse Shipment Line"; var _TempBaseOrderLineElement: Record "MOB NS BaseDataModel Element")
    var
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        QtyOutstandingBase: Decimal;
        QtyPickedBase: Decimal;
        QtyShippedBase: Decimal;
        QtyPickedNotShippedBase: Decimal;
    begin
        // WITH Pick but WITHOUT Warehouse Tracking
        //   Since goods is picked but with NO warehouse tracking, there is no telling which exact lotnumbers/serialnumbers was picked.
        //   Intended reservations from the source document cannot be carried over to the shipment line and cannot be fully supported.
        QtyOutstandingBase := _WhseShipmentLine."Qty. Outstanding (Base)";
        QtyPickedBase := _WhseShipmentLine."Qty. Picked (Base)";
        QtyShippedBase := _WhseShipmentLine."Qty. Shipped (Base)";
        QtyPickedNotShippedBase := QtyPickedBase - QtyShippedBase;

        Clear(TempTrackingSpecification);
        InsertFromWarehouseShipmentLine(_WhseShipmentLine, '', _Location, TempTrackingSpecification, QtyOutstandingBase, QtyPickedNotShippedBase, _TempBaseOrderLineElement);  // never set Expiration Date for ship
    end;

    local procedure InsertShptLineWithoutPick(_Location: Record Location; _WhseShipmentLine: Record "Warehouse Shipment Line"; var _TempBaseOrderLineElement: Record "MOB NS BaseDataModel Element")
    var
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        QtyOutstandingBase: Decimal;
        TotalTrackedQtyOutstandingBase: Decimal;
        RemQtyOutstandingBase: Decimal;
        LineNoPrefix: Text[30];
    begin
        Clear(TotalTrackedQtyOutstandingBase);
        Clear(LineNoPrefix);

        SumUpWhseShipmentLineItemTracking(_WhseShipmentLine, TempTrackingSpecification, true, true);    // Per line with tracking = pre-reservation (specific)
        TempTrackingSpecification.SetCurrentKey("Lot No.", "Serial No.");

        if TempTrackingSpecification.FindSet() then begin
            LineNoPrefix := 'P000'; // Prefix on tracked lines only
            repeat
                QtyOutstandingBase := Abs(TempTrackingSpecification."Qty. to Handle (Base)" - TempTrackingSpecification."Quantity Handled (Base)");
                InsertFromWarehouseShipmentLine(_WhseShipmentLine, LineNoPrefix, _Location, TempTrackingSpecification, QtyOutstandingBase, QtyOutstandingBase, _TempBaseOrderLineElement);  // never set Expiration Date for ship

                TotalTrackedQtyOutstandingBase += QtyOutstandingBase;
                LineNoPrefix := IncStr(LineNoPrefix);
            until TempTrackingSpecification.Next() = 0;

            RemQtyOutstandingBase := _WhseShipmentLine."Qty. Outstanding (Base)" - TotalTrackedQtyOutstandingBase;
        end else
            RemQtyOutstandingBase := _WhseShipmentLine."Qty. Outstanding (Base)";

        // Display remainder as separate line
        // Assume RemQtyOutstandingBase is all available and ready to ship
        if RemQtyOutstandingBase <> 0 then begin
            Clear(TempTrackingSpecification);
            InsertFromWarehouseShipmentLine(_WhseShipmentLine, LineNoPrefix, _Location, TempTrackingSpecification, RemQtyOutstandingBase, RemQtyOutstandingBase, _TempBaseOrderLineElement);  // never set Expiration Date for ship
        end;
    end;

    local procedure InsertFromWarehouseShipmentLine(_WhseShipmentLine: Record "Warehouse Shipment Line"; _LineNoPrefix: Code[30]; _Location: Record Location; _TempTrackingSpecification: Record "Tracking Specification"; _QtyOutstandingBase: Decimal; _QtyPickedNotShippedBase: Decimal; var _BaseOrderLineElement: Record "MOB NS BaseDataModel Element")
    var
        UoMMgt: Codeunit "Unit of Measure Management";
        QtyOutstanding: Decimal;
        QtyPickedNotShipped: Decimal;
        QtyToShipBase: Decimal;
        QtyToShip: Decimal;
        ShippingAdviceReached: Boolean;
    begin
        // Adjust QtyToShip for when shipping advice conditions is not met
        // Standard code only deals with this during posting
        if _WhseShipmentLine."Shipping Advice" = _WhseShipmentLine."Shipping Advice"::Partial then
            ShippingAdviceReached := true
        else
            ShippingAdviceReached := _QtyOutstandingBase = _QtyPickedNotShippedBase;

        Clear(QtyToShipBase);
        if ShippingAdviceReached then
            QtyToShipBase := _QtyPickedNotShippedBase;

        QtyOutstanding := UoMMgt.CalcQtyFromBase(_QtyOutstandingBase, _WhseShipmentLine."Qty. per Unit of Measure");
        QtyPickedNotShipped := UoMMgt.CalcQtyFromBase(_QtyPickedNotShippedBase, _WhseShipmentLine."Qty. per Unit of Measure");
        QtyToShip := UoMMgt.CalcQtyFromBase(QtyToShipBase, _WhseShipmentLine."Qty. per Unit of Measure");

        _BaseOrderLineElement.Create();
        SetFromWarehouseShipmentLine(_WhseShipmentLine, _LineNoPrefix, _Location, _TempTrackingSpecification, _QtyOutstandingBase, QtyOutstanding, _QtyPickedNotShippedBase, QtyPickedNotShipped, QtyToShipBase, QtyToShip, _BaseOrderLineElement);  // never set Expiration Date for ship
        _BaseOrderLineElement.Save();
    end;

    local procedure SumUpWhseShipmentLineItemTracking(_WhseShptLine: Record "Warehouse Shipment Line"; var _TempTrackingSpecification: Record "Tracking Specification" temporary; _SumPerLine: Boolean; _SumPerTracking: Boolean): Boolean
    var
        ReservEntry: Record "Reservation Entry";
        ATOSalesLine: Record "Sales Line";
        AsmHeader: Record "Assembly Header";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        MobCommonMgt: Codeunit "MOB Common Mgt.";
    begin
        if not _TempTrackingSpecification.IsTemporary() then
            Error(MUST_BE_TEMPORARY_Err, _TempTrackingSpecification.TableCaption());    // SumUpItemTracking() will delete all content

        // ATO are currently handled from ATOInsertShptLine and do not use this SumUpWhseShipmentLineItemTracking() function - leaving the ATO code in place here for future use 
        if (_WhseShptLine."Source Type" = Database::"Sales Line") and _WhseShptLine."Assemble to Order" then begin
            ATOSalesLine.Get(_WhseShptLine."Source Subtype", _WhseShptLine."Source No.", _WhseShptLine."Source Line No.");
            ATOSalesLine.AsmToOrderExists(AsmHeader);
            MobCommonMgt.SetSourceFilterForReservEntry(ReservEntry, Database::"Assembly Header", MobToolbox.AsInteger(AsmHeader."Document Type"), AsmHeader."No.", 0, true);
        end else
            MobCommonMgt.SetSourceFilterForReservEntry(ReservEntry, _WhseShptLine."Source Type", _WhseShptLine."Source Subtype", _WhseShptLine."Source No.", _WhseShptLine."Source Line No.", true);

        exit(ItemTrackingMgt.SumUpItemTracking(ReservEntry, _TempTrackingSpecification, _SumPerLine, _SumPerTracking));
    end;

    local procedure CalcItemTrkgQuantityBase(_WhseShptLine: Record "Warehouse Shipment Line"; _TrackingSpec: Record "Tracking Specification"): Decimal
    var
        ReservationEntry: Record "Reservation Entry";
        WhseItemTrkgLine: Record "Whse. Item Tracking Line";
    begin
        Clear(ReservationEntry);
        ReservationEntry.CopyTrackingFromSpec(_TrackingSpec);

        WhseItemTrkgLine.SetCurrentKey("Serial No.", "Lot No.");
        WhseItemTrkgLine.SetTrackingFilterFromReservEntry(ReservationEntry);    // Filter Serial No. and Lot No. (cloned from TrackingSpec, could be empty)
        WhseItemTrkgLine.SetSourceFilter(Database::"Warehouse Shipment Line", -1, _WhseShptLine."No.", _WhseShptLine."Line No.", false);
        WhseItemTrkgLine.CalcSums("Quantity (Base)");
        exit(WhseItemTrkgLine."Quantity (Base)");
    end;

    local procedure CalcItemTrkgPickedBase(_WhseShptLine: Record "Warehouse Shipment Line"; _TrackingSpec: Record "Tracking Specification"): Decimal
    var
        ReservationEntry: Record "Reservation Entry";
        WhseItemTrkgLine: Record "Whse. Item Tracking Line";
    begin
        Clear(ReservationEntry);
        ReservationEntry.CopyTrackingFromSpec(_TrackingSpec);

        WhseItemTrkgLine.SetCurrentKey("Serial No.", "Lot No.");
        WhseItemTrkgLine.SetTrackingFilterFromReservEntry(ReservationEntry);    // Filter Serial No. and Lot No. (cloned from TrackingSpec, could be empty)
        WhseItemTrkgLine.SetSourceFilter(Database::"Warehouse Shipment Line", -1, _WhseShptLine."No.", _WhseShptLine."Line No.", false);
        WhseItemTrkgLine.CalcSums("Qty. Registered (Base)");
        exit(WhseItemTrkgLine."Qty. Registered (Base)");
    end;

    local procedure AddStepsToWarehouseShipmentHeader(_WhseShipmentHeader: Record "Warehouse Shipment Header"; _XmlResponseDoc: XmlDocument; var _XmlResponseData: XmlNode)
    var
        TempSteps: Record "MOB Steps Element" temporary;
        TempAdditionalValues: Record "MOB Common Element" temporary;
        MobPrint: Codeunit "MOB Print";
        RecRef: RecordRef;
        RegistrationCollectorConfiguration: XmlNode;
        XmlSteps: XmlNode;
    begin
        // Get steps for printing
        RecRef.GetTable(_WhseShipmentHeader);
        MobPrint.GetStepsForPrintOnPosting(RecRef, TempSteps, TempAdditionalValues);

        // Event: OnAddSteps
        TempSteps.SetMustCallCreateNext(true);
        OnGetShipOrderLines_OnAddStepsToWarehouseShipmentHeader(_WhseShipmentHeader, TempSteps);

        if not TempSteps.IsEmpty() then begin
            // Adds Collector Configuration with <steps> {<add ... />} <steps/>
            MobToolbox.AddCollectorConfiguration(_XmlResponseDoc, _XmlResponseData, RegistrationCollectorConfiguration, XmlSteps);

            MobXmlMgt.AddStepsaddElements(XmlSteps, TempSteps);

            // Add node: AdditionalValues   
            MobToolbox.AddAdditionalValuesToCollectorConfiguration(RegistrationCollectorConfiguration, TempAdditionalValues);
        end;
    end;

    local procedure PostOrder()
    var
        TempOrderValues: Record "MOB Common Element" temporary;
        XmlRequestDoc: XmlDocument;
        OrderID: Code[20];
    begin
        // Load the request document from the document queue
        MobDocQueue.LoadXMLRequestDoc(XmlRequestDoc);
        MobRequestMgt.InitCommonFromXmlOrderNode(XmlRequestDoc, TempOrderValues);

        // Get the order ID
        Evaluate(OrderID, TempOrderValues.GetValue('backendID', true));

        PostWhseShipmentOrder(OrderID);
    end;

    local procedure PostWhseShipmentOrder(OrderID: Code[20])
    var
        MobSetup: Record "MOB Setup";
        MobReportPrintSetup: Record "MOB Report Print Setup";
        MobTrackingSetup: Record "MOB Tracking Setup";
        Location: Record Location;
        WhseShipmentHeader: Record "Warehouse Shipment Header";
        WhseShipmentLine: Record "Warehouse Shipment Line";
        ATOSalesLine: Record "Sales Line";
        AssemblyHeader: Record "Assembly Header";
        MobWmsRegistration: Record "MOB WMS Registration";
        TempOrderValues: Record "MOB Common Element" temporary;
        TempSteps: Record "MOB Steps Element" temporary;
        TempReservationEntryLog: Record "Reservation Entry" temporary;
        TempReservationEntry: Record "Reservation Entry" temporary;
        WhsePostShipment: Codeunit "Whse.-Post Shipment";
        UoMMgt: Codeunit "Unit of Measure Management";
        MobSyncItemTracking: Codeunit "MOB Sync. Item Tracking";
        MobTryEvent: Codeunit "MOB Try Event";
        MobPrint: Codeunit "MOB Print";
        LineRecRef: RecordRef;
        XmlRequestDoc: XmlDocument;
        RegisterExpirationDate: Boolean;
        Qty: Decimal;
        QtyBase: Decimal;
        TotalQty: Decimal;
        TotalQtyBase: Decimal;
        ResultMessage: Text;
        LastBin: Code[20];
        PostingRunSuccessful: Boolean;
        PostedDocExists: Boolean;
    begin
        // 1. Get the order ID from the XML
        // 2. Get the line registrations from the XML
        // 3. Get the warehouse Shipment lines
        // 4. Update the quantities
        // 5. Post the warehouse Shipment lines
        // 6. Generate a response for the mobile device

        // Disable the locktimeout to prevent timeout messages on the mobile device
        LockTimeout(false);

        // Lock the tables to work on
        WhseShipmentHeader.LockTable();
        WhseShipmentLine.LockTable();
        MobWmsRegistration.LockTable();

        MobSetup.Get();

        // Turn on commit protection to prevent unintentional committing data
        MobDocQueue.Consistent(false);

        // Load the request document from the document queue
        MobDocQueue.LoadXMLRequestDoc(XmlRequestDoc);
        MobRequestMgt.InitCommonFromXmlOrderNode(XmlRequestDoc, TempOrderValues);

        // Save the registrations from the XML in the Mobile WMS Registration table
        OrderID := MobWmsToolbox.SaveRegistrationData(MobDocQueue.MessageIDAsGuid(), XmlRequestDoc, MobWmsRegistration.Type::Ship);

        // Check Locations Warehouse Setup
        WhseShipmentHeader.Get(OrderID);
        Location.Get(WhseShipmentHeader."Location Code");

        WhseShipmentHeader.Validate("Posting Date", WorkDate());
        WhseShipmentHeader."Shipment Date" := WorkDate();
        WhseShipmentHeader."MOB Posting MessageId" := MobDocQueue.MessageIDAsGuid();

        // OnAddStepsTo IntegrationEvents
        OnPostShipOrder_OnAddStepsToWarehouseShipmentHeader(TempOrderValues, WhseShipmentHeader, TempSteps);
        if not TempSteps.IsEmpty() then begin
            MobSessionData.SetRegistrationTypeTracking('OnAddStepsTo');
            MobWmsToolbox.DeleteRegistrationData(MobDocQueue.MessageIDAsGuid());
            MobToolbox.CreateResponseWithSteps(XmlResponseDoc, TempSteps);
            MobDocQueue.Consistent(true);
            exit;
        end;

        // OnBeforePost IntegrationEvents
        OnPostShipOrder_OnBeforePostWarehouseShipment(TempOrderValues, WhseShipmentHeader);
        WhseShipmentHeader.Modify(true);

        // Get the real warehouse shipment lines
        // Loop through them and set all "qty to ship" to the registered qty (or zero if the reg. does not exist)
        WhseShipmentLine.SetRange("No.", OrderID);

        // Update lines shipment date
        WhseShipmentLine.ModifyAll("Shipment Date", WorkDate());

        // Save the original reservation entrie in case we need to revert (if the posting fails)
        MobSyncItemTracking.SaveOriginalReservationEntriesForWhseShipmentLines(WhseShipmentLine, TempReservationEntryLog);

        if WhseShipmentLine.FindSet() then begin
            Location.Get(WhseShipmentLine."Location Code");
            repeat
                // Try to find the registrations
                MobWmsRegistration.SetRange("Posting MessageId", MobDocQueue.MessageIDAsGuid());
                MobWmsRegistration.SetRange(Type, MobWmsRegistration.Type::Ship);
                MobWmsRegistration.SetRange("Order No.", OrderID);
                MobWmsRegistration.SetRange("Line No.", WhseShipmentLine."Line No.");
                MobWmsRegistration.SetRange(Handled, false);


                // Scenarios:
                // Location requires Shipment but Not Pick, The line requires item tracking (maybe more than one registration, create
                // reservation entries for each registration)
                // Location requires Shipment and Pick, Item Tracking has been created by posting of pick.

                // Determine if item tracking is needed
                if (WhseShipmentLine."Source Type" = Database::"Sales Line") and WhseShipmentLine."Assemble to Order" then begin
                    ATOSalesLine.Get(WhseShipmentLine."Source Subtype", WhseShipmentLine."Source No.", WhseShipmentLine."Source Line No.");
                    ATOSalesLine.AsmToOrderExists(AssemblyHeader);
                    MobTrackingSetup.DetermineItemTrackingRequiredByAssemblyHeader(AssemblyHeader, RegisterExpirationDate);
                    // MobTrackingSetup.Tracking: Copy later in MobWmsRegistration loop
                end else
                    // MobTrackingSetup.Tracking: Copy later in MobWmsRegistration loop
                    MobTrackingSetup.DetermineItemTrackingRequiredByWhseShipmentLine(WhseShipmentLine, RegisterExpirationDate);

                //
                // Handle Registrations
                //

                // Initialize the quantity counter
                TotalQty := 0;
                TotalQtyBase := 0;

                // Initialize the last bin variable
                LastBin := '';

                if MobWmsRegistration.FindSet() then begin
                    repeat
                        // MobTrackingSetup.TrackingRequired: Determined before (outside inner MobWmsRegistration loop)
                        MobTrackingSetup.CopyTrackingFromRegistration(MobWmsRegistration);

                        // Registrations exist for this line

                        // Shipments do not handle line splitting.
                        // Return an error if multiple bins are registered on the mobile device
                        if MobWmsRegistration.FromBin <> WhseShipmentLine."Bin Code" then
                            if LastBin = '' then begin
                                LastBin := MobWmsRegistration.FromBin;
                                WhseShipmentLine.SuspendStatusCheck(true);
                                WhseShipmentLine.Validate("Bin Code", MobWmsRegistration.FromBin);
                                WhseShipmentLine.SuspendStatusCheck(false);
                            end else
                                if LastBin <> MobWmsRegistration.FromBin then
                                    Error(MobWmsLanguage.GetMessage('MULTI_BINS_NOT_ALLOWED'));

                        // Calculate registered quantity and base quantity
                        if MobSetup."Use Base Unit of Measure" then begin
                            Qty := 0; // To ensure best possible rounding the TotalQty will be calculated after the loop
                            QtyBase := MobWmsRegistration.Quantity;
                        end else begin
                            MobWmsRegistration.TestField(UnitOfMeasure);
                            Qty := MobWmsToolbox.CalcQtyNewUOMRounded(WhseShipmentLine."Item No.", MobWmsRegistration.Quantity, MobWmsRegistration.UnitOfMeasure, WhseShipmentLine."Unit of Measure Code");
                            QtyBase := UoMMgt.CalcBaseQty(MobWmsRegistration.Quantity, WhseShipmentLine."Qty. per Unit of Measure");
                        end;

                        TotalQty := TotalQty + Qty;
                        TotalQtyBase := TotalQtyBase + QtyBase;

                        // Synchronize Item Tracking to Source Document
                        MobSyncItemTracking.CreateTempReservEntryForWhseShipmentLine(WhseShipmentLine, MobWmsRegistration, TempReservationEntry, QtyBase);

                        MobWmsToolbox.SaveRegistrationDataFromSource(WhseShipmentLine."Location Code", WhseShipmentLine."Item No.", WhseShipmentLine."Variant Code", MobWmsRegistration);

                        // OnHandle IntegrationEvents (WhseShipmentLine intentionally not modified -- is modified below)
                        OnPostShipOrder_OnHandleRegistrationForWarehouseShipmentLine(MobWmsRegistration, WhseShipmentLine, TempReservationEntry);

                        // Set the handled flag to true on the registration
                        MobWmsRegistration.Validate(Handled, true);
                        MobWmsRegistration.Modify();

                        if MobTrackingSetup.TrackingRequired() then
                            if TempReservationEntry.Modify() then; // // To modify if created earlier and possibly updated in subscriber

                    until MobWmsRegistration.Next() = 0;

                    // To ensure best possible rounding the TotalQty is calculated and rounded only once when MobSetup."Use Base Unit of Measure" is enabled (i.e. 3 * 1/3 = 1)
                    if MobSetup."Use Base Unit of Measure" then
                        TotalQty := UoMMgt.CalcQtyFromBase(TotalQtyBase, WhseShipmentLine."Qty. per Unit of Measure");

                    WhseShipmentLine.Validate("Qty. to Ship", TotalQty);

                end else  // endif MobWmsRegistration.FindSet()
                    WhseShipmentLine.Validate("Qty. to Ship", 0);

                WhseShipmentLine.Modify();

            until WhseShipmentLine.Next() = 0;

            // -- 5. Post the warehouse Shipment lines

            // Set Print Shipment
            if MobReportPrintSetup.PrintShipmentOnPostEnabled() then
                WhsePostShipment.SetPrint(true);

            // OnBeforeRun IntegrationEvent
            OnPostShipOrder_OnBeforeRunWhsePostShipment(WhseShipmentLine, WhsePostShipment);

            // Turn off the commit protection
            // From this point on we explicitely clean up committed data if an error occurs
            MobDocQueue.Consistent(true);

            Commit();

            if not MobSyncItemTracking.Run(TempReservationEntry) then begin
                // The created reservation entries might have been committed
                // If the synchronization fails for some reason we need to clean up the created reservation entries
                ResultMessage := GetLastErrorText();
                MobSessionData.SetPreservedLastErrorCallStack();
                MobSyncItemTracking.RevertToOriginalReservationEntriesForWhseShipmentLines(WhseShipmentLine, TempReservationEntryLog);
                Commit();
                UpdateIncomingWarehouseShipment(WhseShipmentHeader);
                MobWmsToolbox.DeleteRegistrationData(MobDocQueue.MessageIDAsGuid());
                Commit();   // Separate commit to prevent error in UpdateIncomingWarehouseShipment from preventing Reservation Entries being rollback
                Error(ResultMessage);
            end;

            PostingRunSuccessful := WhsePostShipment.Run(WhseShipmentLine);

            // If Posted Whse. Shipment exists posting has succeeded but something else failed. ie. partner code OnAfter event
            if not PostingRunSuccessful then
                PostedDocExists := PostedWhseShipmentHeaderExists(WhseShipmentHeader);

            if PostingRunSuccessful or PostedDocExists then begin
                // The posting was successful
                ResultMessage := MobToolbox.GetPostSuccessMessage(PostingRunSuccessful);

                // Commit to allow for codeunit.run
                Commit();

                // Event OnAfterPost
                LineRecRef.GetTable(WhseShipmentLine);
                MobTryEvent.RunEventOnPlannedPosting('OnPostShipOrder_OnAfterPostWarehouseShipment', LineRecRef, TempOrderValues, ResultMessage);

                UpdateIncomingWarehouseShipment(WhseShipmentHeader);

                // Print on posting
                Commit();
                MobPrint.PrintOnPlannedPosting(LineRecRef, TempOrderValues, ResultMessage);

                // If Shipment is based on Transfer Order(s) then
                // create also the Inbound Receipts/Invt.Put-aways on the Transfer-to Code destination
                CreateInboundWarehouseDocs(WhseShipmentLine);
            end else begin
                // The created reservation entries have been committed
                // If the posting fails for some reason we need to clean up the created reservation entries and MobWmsRegistrations
                ResultMessage := GetLastErrorText();
                MobSessionData.SetPreservedLastErrorCallStack();
                MobSyncItemTracking.RevertToOriginalReservationEntriesForWhseShipmentLines(WhseShipmentLine, TempReservationEntryLog);
                Commit();
                UpdateIncomingWarehouseShipment(WhseShipmentHeader);
                MobWmsToolbox.DeleteRegistrationData(MobDocQueue.MessageIDAsGuid());
                Commit();   // Separate commit to prevent error in UpdateIncomingWarehouseShipment from preventing Reservation Entries being rollback
                Error(ResultMessage);
            end;

            // Create a response inside the <description> element of the document response
            MobToolbox.CreateSimpleResponse(XmlResponseDoc, ResultMessage);
        end;
    end;

    /// <summary>
    /// Identify each Transfer Order(s) of the Posted Shipment
    /// Create Inbound Receipts/Invt.Put-aways on the Transfer-to Code destination
    /// </summary>
    local procedure CreateInboundWarehouseDocs(var _WhseShipmentLine: Record "Warehouse Shipment Line")
    var
        PostedWhseShipmentHeader: Record "Posted Whse. Shipment Header";
        PostedWhseShipmentLine: Record "Posted Whse. Shipment Line";
    begin
        PostedWhseShipmentHeader.SetCurrentKey("Whse. Shipment No.");
        PostedWhseShipmentHeader.SetRange("Whse. Shipment No.", _WhseShipmentLine."No.");

        if PostedWhseShipmentHeader.FindLast() then begin
            PostedWhseShipmentLine.SetCurrentKey("Source Type", "Source Subtype", "Source No.", "Source Line No.");
            PostedWhseShipmentLine.SetRange("Source Type", Database::"Transfer Line");
            PostedWhseShipmentLine.SetRange("Source Subtype", 0);
            PostedWhseShipmentLine.SetRange("Source Document", PostedWhseShipmentLine."Source Document"::"Outbound Transfer");
            PostedWhseShipmentLine.SetRange("No.", PostedWhseShipmentHeader."No.");
            if PostedWhseShipmentLine.FindSet() then
                repeat
                    PostedWhseShipmentLine.SetRange("Source No.", PostedWhseShipmentLine."Source No.");
                    MobWmsToolbox.CreateInboundTransferWarehouseDoc(PostedWhseShipmentLine."Source No.");
                    // Run only once per Source document
                    PostedWhseShipmentLine.FindLast(); // Make Repeat go to next Source Document
                    PostedWhseShipmentLine.SetRange("Source No.");
                until PostedWhseShipmentLine.Next() = 0;
        end;
    end;

    local procedure UpdateIncomingWarehouseShipment(var _WhseShipmentHeader: Record "Warehouse Shipment Header")
    begin
        if not _WhseShipmentHeader.Get(_WhseShipmentHeader."No.") then
            exit;

        _WhseShipmentHeader.LockTable();
        _WhseShipmentHeader.Get(_WhseShipmentHeader."No.");
        Clear(_WhseShipmentHeader."MOB Posting MessageId");
        _WhseShipmentHeader.Modify();
    end;

    //
    // ------- MISC. HELPER -------
    //

    local procedure GetReceiver_FromWhseShipment(_ShipmentNo: Code[20]; _MaxNoOfLines: Integer) ReturnReceiver: Text
    var
        WhseShipmentLine: Record "Warehouse Shipment Line";
        SalesHeader: Record "Sales Header";
        ServiceHeader: Record "Service Header";
        PurchaseHeader: Record "Purchase Header";
        TransferHeader: Record "Transfer Header";
        ReceiverList: List of [Text];
    begin
        WhseShipmentLine.SetCurrentKey("No.", "Source Type", "Source No.", "Source Line No.");
        WhseShipmentLine.SetRange("No.", _ShipmentNo);

        // Create unique senders list to support lines from multiple senders (vendors, sales return customers)
        if WhseShipmentLine.FindSet() then
            repeat
                WhseShipmentLine.SetRange("Source Type", WhseShipmentLine."Source Type");
                WhseShipmentLine.SetRange("Source No.", WhseShipmentLine."Source No.");

                case WhseShipmentLine."Source Type" of
                    Database::"Sales Line":
                        if SalesHeader.Get(WhseShipmentLine."Source Subtype", WhseShipmentLine."Source No.") then
                            MobToolbox.AddUniqueText(ReceiverList, SalesHeader."Ship-to Name")
                        else
                            MobToolbox.AddUniqueText(ReceiverList, MobWmsLanguage.GetMessage('NOT_AVAILABLE'));
                    Database::"Purchase Line":
                        if PurchaseHeader.Get(WhseShipmentLine."Source Subtype", WhseShipmentLine."Source No.") then
                            MobToolbox.AddUniqueText(ReceiverList, PurchaseHeader."Ship-to Name")
                        else
                            MobToolbox.AddUniqueText(ReceiverList, MobWmsLanguage.GetMessage('NOT_AVAILABLE'));
                    Database::"Transfer Line":
                        if TransferHeader.Get(WhseShipmentLine."Source No.") then
                            if TransferHeader."Transfer-to Name" <> '' then
                                MobToolbox.AddUniqueText(ReceiverList, MobWmsLanguage.GetMessage('OUTBOUND_TRANSFER_LABEL') + ': ' + TransferHeader."Transfer-to Name")
                            else
                                MobToolbox.AddUniqueText(ReceiverList, MobWmsLanguage.GetMessage('OUTBOUND_TRANSFER_LABEL') + ': ' + TransferHeader."Transfer-to Code")
                        else
                            MobToolbox.AddUniqueText(ReceiverList, MobWmsLanguage.GetMessage('NOT_AVAILABLE'));
                    Database::"Service Line":
                        if ServiceHeader.Get(WhseShipmentLine."Source Subtype", WhseShipmentLine."Source No.") then
                            MobToolbox.AddUniqueText(ReceiverList, ServiceHeader."Ship-to Name")
                        else
                            MobToolbox.AddUniqueText(ReceiverList, MobWmsLanguage.GetMessage('NOT_AVAILABLE'));
                    else
                        MobToolbox.AddUniqueText(ReceiverList, MobWmsLanguage.GetMessage('NOT_AVAILABLE'));
                end;

                WhseShipmentLine.FindLast();
                WhseShipmentLine.SetRange("Source Type");
                WhseShipmentLine.SetRange("Source No.");
            until WhseShipmentLine.Next() = 0;

        // Combine unique senderlist to a single string
        ReturnReceiver := CopyStr(MobWmsToolbox.List2TextLn(ReceiverList, _MaxNoOfLines), 1, MaxStrLen(ReturnReceiver));
        exit(ReturnReceiver);
    end;

    internal procedure GetSourceTypeNo(_ShipmentNo: Code[20]; _MaxNoOfLines: Integer) _SourceTypeNo: Text[250]
    var
        WhseShipmentLine: Record "Warehouse Shipment Line";
        WmsToolbox: Codeunit "MOB WMS Toolbox";
        SourceTypeNoList: List of [Text];
    begin
        // with WhseReceiptLine do begin
        WhseShipmentLine.SetCurrentKey("No.", "Source Document", "Source No.");
        WhseShipmentLine.SetRange("No.", _ShipmentNo);

        // Combine receipt lines from multiple senders into one string (vendors)
        if WhseShipmentLine.FindFirst() then
            repeat
                WhseShipmentLine.SetRange("Source Document", WhseShipmentLine."Source Document");
                WhseShipmentLine.SetRange("Source No.", WhseShipmentLine."Source No.");

                MobToolbox.AddUniqueText(SourceTypeNoList, Format(WhseShipmentLine."Source Document") + ' ' + Format(WhseShipmentLine."Source No."));

                WhseShipmentLine.FindLast();
                WhseShipmentLine.SetRange("Source No.");
                WhseShipmentLine.SetRange("Source Document");
            until WhseShipmentLine.Next() = 0;

        // i.e. "Sales Order 104013\r\nSales Order 104014\r\nPurchase Return Order 1001"
        _SourceTypeNo := CopyStr(WmsToolbox.List2TextLn(SourceTypeNoList, _MaxNoOfLines), 1, MaxStrLen(_SourceTypeNo));
        exit(_SourceTypeNo);
        // end;
    end;

    /// <remarks>
    /// Used for Adhoc PostToteShipping for Assembly Orders
    /// </remarks>
    procedure ReservEntriesExist(_WhseShipmentLine: Record "Warehouse Shipment Line"; var _ReservEntry: Record "Reservation Entry"; _MobTrackingSetup: Record "MOB Tracking Setup"; var _ReservedQtyToHandleReset: Boolean; _QtyBase: Decimal): Boolean
    var
        ReservEntry2: Record "Reservation Entry";
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        ValidOutboundSerialNo: Boolean;
        ValidOutboundLotNo: Boolean;
        ValidOutboundTracking: Boolean;
    begin
        Clear(_ReservEntry);
        Clear(ReservEntry2);

        _ReservEntry.SetCurrentKey(
          "Source ID", "Source Ref. No.", "Source Type", "Source Subtype",
          "Source Batch Name", "Source Prod. Order Line", "Reservation Status",
          "Shipment Date", "Expected Receipt Date");
        _ReservEntry.SetRange("Source ID", _WhseShipmentLine."Source No.");
        _ReservEntry.SetRange("Source Ref. No.", _WhseShipmentLine."Source Line No.");
        _ReservEntry.SetRange("Source Type", _WhseShipmentLine."Source Type");
        _ReservEntry.SetRange("Source Subtype", _WhseShipmentLine."Source Subtype");
        _ReservEntry.SetRange("Source Batch Name", '');
        _ReservEntry.SetRange("Source Prod. Order Line", 0);
        _ReservEntry.SetRange("Reservation Status", _ReservEntry."Reservation Status"::Reservation);

        // The line can have several reservation entries
        // We need to make sure that the "Quantity to handle" is set to zero before posting is started
        // The real Quantity to Handle is set when the registrations from the mobile device are handled
        if not _ReservedQtyToHandleReset then begin
            if _ReservEntry.FindSet() then
                repeat
                    _ReservEntry.Validate("Qty. to Handle (Base)", 0);
                    _ReservEntry.Modify();
                until _ReservEntry.Next() = 0;
            _ReservedQtyToHandleReset := true;
        end;
        // Make sure the reservation hasn't been filled by a previous MobWmsRegistration-run, in which case "Qty. to Handle (Base)" will be <> 0
        _ReservEntry.SetRange("Qty. to Handle (Base)", 0);

        // Since its outbound the reservation entry may already contain Item Tracking (i.e. Order-to-Order Binding or manual reservations of specific serial/lot)
        _MobTrackingSetup.SetTrackingFilterForReservEntryIfNotBlank(_ReservEntry);
        if _ReservEntry.FindFirst() then
            exit(true);
        // If no Order-to-Order Binding is found, clear the Item Tracking filters to find any reservation for the current Warehouse Shipment Line
        // The reservation may still be for the picked Lot/Serial only not entered on the outbound entry
        _MobTrackingSetup.SetTrackingFilterBlankForReservEntryIfNotBlank(_ReservEntry);
        if _ReservEntry.FindSet() then
            repeat
                if ReservEntry2.Get(_ReservEntry."Entry No.", not _ReservEntry.Positive) then begin
                    Item.Get(ReservEntry2."Item No.");
                    if Item."Item Tracking Code" <> '' then
                        ItemTrackingCode.Get(Item."Item Tracking Code")
                    else
                        Clear(ItemTrackingCode);

                    ValidOutboundSerialNo := (not ItemTrackingCode."SN Specific Tracking") or (_MobTrackingSetup."Serial No." = ReservEntry2."Serial No.");
                    ValidOutboundLotNo := (not ItemTrackingCode."Lot Specific Tracking") or (_MobTrackingSetup."Lot No." = ReservEntry2."Lot No.");
                    ValidOutboundTracking := ValidOutboundSerialNo and ValidOutboundLotNo;

                    OnReservEntriesExistOnCheckValidOutboundTracking(ItemTrackingCode, _MobTrackingSetup, ReservEntry2, ValidOutboundTracking);

                    if ValidOutboundTracking then
                        exit(true);
                end;
            until _ReservEntry.Next() = 0;

        // If no Trackingspecific reservations exist, test that the tracking is available for outbound entries (i.e. not reserved on another order)
        if GetAvailableQty(_WhseShipmentLine, _MobTrackingSetup) < _QtyBase then
            Error(MobWmsLanguage.GetMessage('TRACKING_RESERVED'),
                MobWmsToolbox.GetItemAndVariantTxt(_WhseShipmentLine."Item No.", _WhseShipmentLine."Variant Code") +
                MobToolbox.CRLFSeparator() + MobToolbox.CRLFSeparator() +
                _MobTrackingSetup.FormatTracking() +
                MobToolbox.CRLFSeparator() + MobToolbox.CRLFSeparator() +
                GetAvailableItemsTxt(_WhseShipmentLine, _MobTrackingSetup, ReservEntry2));

        // Filter out reservation entries filled by previous inbound/outbound entries with other Lots/Serials
        _ReservEntry.SetRange("Item Tracking", _ReservEntry."Item Tracking"::None);

        if _ReservEntry.FindFirst() then
            exit(true)
        else
            Clear(_ReservEntry);
    end;

    /// <summary>
    /// Replaced by procedure ReservEntriesExist() with parameter "Mob Tracking Setup"  (but not planned for removed for backwards compatibility)
    /// </summary>
    procedure ReservEntriesExist(_WhseShipmentLine: Record "Warehouse Shipment Line"; var _ReservEntry: Record "Reservation Entry"; _SerialNo: Code[50]; _LotNo: Code[50]; var _ReservedQtyToHandleReset: Boolean; _QtyBase: Decimal): Boolean
    var
        MobTrackingSetup: Record "MOB Tracking Setup";
    begin
        MobTrackingSetup.ClearTrackingRequired();
        MobTrackingSetup."Serial No." := _SerialNo;
        MobTrackingSetup."Lot No." := _LotNo;
        exit(ReservEntriesExist(_WhseShipmentLine, _ReservEntry, MobTrackingSetup, _ReservedQtyToHandleReset, _QtyBase));
    end;

    /// <remarks>
    /// Helper function for xxxx (used for Adhoc PostToteShipping for Assembly Orders)
    /// </remarks>
    local procedure GetAvailableQty(_WarehouseShipmentLine: Record "Warehouse Shipment Line"; _MobTrackingSetup: Record "MOB Tracking Setup"): Decimal
    var
        Item: Record Item;
        MobSpecificTrackingSetup: Record "MOB Tracking Setup";
        DummyRegisterExpirationDate: Boolean;
    begin
        Item.Get(_WarehouseShipmentLine."Item No.");
        Item.SetRange("Location Filter", _WarehouseShipmentLine."Location Code");
        Item.SetRange("Variant Filter", _WarehouseShipmentLine."Variant Code");

        MobSpecificTrackingSetup.DetermineSpecificTrackingRequiredFromItemNo(_WarehouseShipmentLine."Item No.", DummyRegisterExpirationDate);
        MobSpecificTrackingSetup.TransferFields(_MobTrackingSetup);

        // Mirror condtions from COD22 ApplyItemLedgerEntry: Settle only when specific tracking is enabled
        MobSpecificTrackingSetup.SetTrackingFilterForItemIfRequired(Item);

        Item.CalcFields(Inventory, "Reserved Qty. on Inventory");
        exit(Item.Inventory - Item."Reserved Qty. on Inventory");
    end;

    local procedure GetAvailableItemsTxt(_WarehouseShipmentLine: Record "Warehouse Shipment Line"; _MobTrackingSetup: Record "MOB Tracking Setup"; ReservationEntry: Record "Reservation Entry") _ReturnText: Text
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        MobItemLedgerEntryTracking: Record "MOB Tracking Setup";
        SuggestionCount: Integer;
        AvailableQty: Decimal;
    begin
        _ReturnText := ' ' + MobWmsLanguage.GetMessage('AVAILABLE_NOW');
        if ReservationEntry."Item Tracking" <> ReservationEntry."Item Tracking"::None then begin
            SuggestionCount += 1;
            if ReservationEntry."Serial No." <> '' then
                _ReturnText += ' ' + MobWmsLanguage.GetMessage('SERIAL_NO_LABEL') + ' ' + ReservationEntry."Serial No." + ' (' + Format(ReservationEntry.Quantity) + ' ' + _WarehouseShipmentLine."Unit of Measure Code" + ')';
            if _MobTrackingSetup."Lot No." <> '' then
                _ReturnText += ' ' + MobWmsLanguage.GetMessage('LOT_NO_LABEL') + ' ' + ReservationEntry."Lot No." + ' (' + Format(ReservationEntry.Quantity) + ' ' + _WarehouseShipmentLine."Unit of Measure Code" + ')';

            OnGetAvailableItemsTxtOnAddTrackingIfNotBlank(_MobTrackingSetup, ReservationEntry.Quantity, _WarehouseShipmentLine."Unit of Measure Code", _ReturnText);
        end;

        ItemLedgerEntry.SetCurrentKey("Item No.", Open, "Variant Code", Positive, "Location Code", "Posting Date", "Expiration Date", "Lot No.", "Serial No.");
        ItemLedgerEntry.SetRange("Item No.", _WarehouseShipmentLine."Item No.");
        ItemLedgerEntry.SetRange(Open, true);
        ItemLedgerEntry.SetRange("Variant Code", _WarehouseShipmentLine."Variant Code");
        ItemLedgerEntry.SetRange(Positive, true);
        ItemLedgerEntry.SetRange("Location Code", _WarehouseShipmentLine."Location Code");
        _MobTrackingSetup.SetTrackingFilterNotEqualForItemLedgerEntryIfNotBlank(ItemLedgerEntry);
        if ItemLedgerEntry.FindSet() then
            repeat
                MobItemLedgerEntryTracking.ClearTrackingRequired();
                MobItemLedgerEntryTracking.CopyTrackingFromItemLedgerEntry(ItemLedgerEntry);
                AvailableQty := GetAvailableQty(_WarehouseShipmentLine, MobItemLedgerEntryTracking);
                if AvailableQty > 0 then begin
                    SuggestionCount += 1;
                    if _MobTrackingSetup."Serial No." <> '' then
                        _ReturnText += ' ' + MobWmsLanguage.GetMessage('SERIAL_NO_LABEL') + ' ' + ItemLedgerEntry."Serial No." + ' (' + Format(AvailableQty) + ' ' + ItemLedgerEntry."Unit of Measure Code" + ')';
                    if _MobTrackingSetup."Lot No." <> '' then
                        _ReturnText += ' ' + MobWmsLanguage.GetMessage('LOT_NO_LABEL') + ' ' + ItemLedgerEntry."Lot No." + ' (' + Format(AvailableQty) + ' ' + ItemLedgerEntry."Unit of Measure Code" + ')';

                    OnGetAvailableItemsTxtOnAddTrackingIfNotBlank(_MobTrackingSetup, AvailableQty, ItemLedgerEntry."Unit of Measure Code", _ReturnText);
                end;
            until (ItemLedgerEntry.Next() = 0) or (SuggestionCount = 3);

        if SuggestionCount = 0 then
            Clear(_ReturnText);
    end;

    //
    // ------- DATAMODEL HELPER -------
    //

    local procedure AddBaseOrderElements(var _XmlResponseData: XmlNode; var _BaseOrderElement: Record "MOB NS BaseDataModel Element")
    var
        CursorMgt: Codeunit "MOB Cursor Management";
    begin
        // store current cursor and sorting
        CursorMgt.Backup(_BaseOrderElement);

        // set sorting to be used for the export, then write to xml
        SetCurrentKeyHeader(_BaseOrderElement);
        MobXmlMgt.AddNsBaseDataModelBaseOrderElements(_XmlResponseData, _BaseOrderElement);

        // restore cursor and sorting
        CursorMgt.Restore(_BaseOrderElement);
    end;

    local procedure SetCurrentKeyHeader(var _BaseOrderElement: Record "MOB NS BaseDataModel Element")
    var
        TempBaseOrderElementCustomView: Record "MOB NS BaseDataModel Element" temporary;
    begin
        _BaseOrderElement.SetCurrentKey("Sorting1 (internal)", "Sorting2 (internal)", "Sorting3 (internal)", "Sorting4 (internal)", "Sorting5 (internal)");

        // use new temporary/empty record for integration event to prevent SetFrom from being in effect at this point in time
        TempBaseOrderElementCustomView.SetView(_BaseOrderElement.GetView());
        OnGetShipOrders_OnAfterSetCurrentKey(TempBaseOrderElementCustomView);
        _BaseOrderElement.SetView(TempBaseOrderElementCustomView.GetView());
    end;

    local procedure AddBaseOrderLineElements(var _XmlResponseData: XmlNode; var _BaseOrderLineElement: Record "MOB NS BaseDataModel Element")
    var
        CursorMgt: Codeunit "MOB Cursor Management";
    begin
        // store current cursor and sorting, then set default sorting to be used for the export
        CursorMgt.Backup(_BaseOrderLineElement);

        // set sorting to be used for the export, then write to xml
        SetCurrentKeyLine(_BaseOrderLineElement);
        MobXmlMgt.AddNsBaseDataModelBaseOrderLineElements(_XmlResponseData, _BaseOrderLineElement);

        // restore cursor and sorting
        CursorMgt.Restore(_BaseOrderLineElement);
    end;

    local procedure SetCurrentKeyLine(var _BaseOrderLineElement: Record "MOB NS BaseDataModel Element")
    var
        TempBaseOrderLineElementCustomView: Record "MOB NS BaseDataModel Element" temporary;
    begin
        _BaseOrderLineElement.SetCurrentKey("Sorting1 (internal)", "Sorting2 (internal)", "Sorting3 (internal)", "Sorting4 (internal)", "Sorting5 (internal)");

        // use new temporary/empty record for integration event to prevent SetFrom from being in effect at this point in time
        TempBaseOrderLineElementCustomView.SetView(_BaseOrderLineElement.GetView());
        OnGetShipOrderLines_OnAfterSetCurrentKey(TempBaseOrderLineElementCustomView);
        _BaseOrderLineElement.SetView(TempBaseOrderLineElementCustomView.GetView());
    end;

    local procedure SetFromWarehouseShipmentHeader(_WhseShipmentHeader: Record "Warehouse Shipment Header"; _OpenPickOrders: Boolean; var _BaseOrder: Record "MOB NS BaseDataModel Element")
    begin
        // Add the data elements to the <Order> element
        _BaseOrder.Set_BackendID(_WhseShipmentHeader."No.");

        // Decide what to show on the lines
        _BaseOrder.Set_DisplayLine1(GetReceiver_FromWhseShipment(_WhseShipmentHeader."No.", 3));
        _BaseOrder.Set_DisplayLine2(MobWmsToolbox.Date2TextAsDisplayFormat(_WhseShipmentHeader."Shipment Date"));
        _BaseOrder.Set_DisplayLine3(_WhseShipmentHeader."No.");
        _BaseOrder.Set_DisplayLine4(GetSourceTypeNo(_WhseShipmentHeader."No.", 3));
        _BaseOrder.Set_DisplayLine5(Format(_WhseShipmentHeader."Document Status"));
        if _OpenPickOrders then
            _BaseOrder.Set_DisplayLine5(_BaseOrder.Get_DisplayLine5() + ' (' + MobWmsLanguage.GetMessage('OPEN_PICK_ORDERS') + ')');

        _BaseOrder.Set_HeaderLabel1(MobWmsLanguage.GetMessage('SHIPMENT'));
        _BaseOrder.Set_HeaderLabel2(MobWmsLanguage.GetMessage('RECEIVER'));
        _BaseOrder.Set_HeaderValue1(_WhseShipmentHeader."No.");
        _BaseOrder.Set_HeaderValue2(_BaseOrder.Get_DisplayLine1());

        _BaseOrder.Set_ReferenceID(_WhseShipmentHeader);
        _BaseOrder.Set_Status();   // Set Locked/Has Attachment symbol (1=Unlocked, 2=Locked, 3=Attachment)

        OnGetShipOrders_OnAfterSetFromWarehouseShipmentHeader(_WhseShipmentHeader, _BaseOrder);
    end;

    local procedure SetFromWarehouseShipmentLine(_WhseShipmentLine: Record "Warehouse Shipment Line"; _LineNoPrefix: Code[30]; _Location: Record Location; _TempTrackingSpecification: Record "Tracking Specification"; _QtyOutstandingBase: Decimal; _QtyOutstanding: Decimal; _QtyPickedNotShippedBase: Decimal; _QtyPickedNotShipped: Decimal; _QtyToShipBase: Decimal; _QtyToShip: Decimal; var _BaseOrderLine: Record "MOB NS BaseDataModel Element")
    var
        MobSetup: Record "MOB Setup";
        MobTrackingSetup: Record "MOB Tracking Setup";
        TempSteps: Record "MOB Steps Element" temporary;
        DummyLocation: Record Location;
        TempReservationEntryParm: Record "Reservation Entry" temporary;
        Item: Record Item;
        ATOSalesLine: Record "Sales Line";
        AssemblyHeader: Record "Assembly Header";
        MobItemReferenceMgt: Codeunit "MOB Item Reference Mgt.";
        DisplayDimList: List of [Text];
        UseQtyPickedNotShipped: Decimal;
        UseQtyOutstanding: Decimal;
        ExpDateRequired: Boolean;
    begin
        Clear(DisplayDimList);

        MobSetup.Get();
        Item.Get(_WhseShipmentLine."Item No.");

        // Determine if serial / lot number registration is needed
        if (_WhseShipmentLine."Source Type" = Database::"Sales Line") and _WhseShipmentLine."Assemble to Order" then begin
            ATOSalesLine.Get(_WhseShipmentLine."Source Subtype", _WhseShipmentLine."Source No.", _WhseShipmentLine."Source Line No.");
            ATOSalesLine.AsmToOrderExists(AssemblyHeader);
            MobTrackingSetup.DetermineItemTrackingRequiredByAssemblyHeader(AssemblyHeader, ExpDateRequired);
        end else
            MobTrackingSetup.DetermineItemTrackingRequiredByWhseShipmentLine(_WhseShipmentLine, ExpDateRequired);
        MobTrackingSetup.CopyTrackingFromTrackingSpec(_TempTrackingSpecification);

        _BaseOrderLine.Set_OrderBackendID(_WhseShipmentLine."No.");
        _BaseOrderLine.Set_LineNumber(_LineNoPrefix + Format(_WhseShipmentLine."Line No.")); // _LineNoPrefix may be empty for untracked line and remainder

        _BaseOrderLine.Set_Location(_Location.Code);
        _BaseOrderLine.Set_FromBin(_WhseShipmentLine."Bin Code");
        _BaseOrderLine.Set_ValidateFromBin(_Location."Bin Mandatory");

        // There is no ToBin in shipment
        _BaseOrderLine.Set_ToBin('');
        _BaseOrderLine.Set_ValidateToBin(false);

        _BaseOrderLine.Set_ItemNumber(_WhseShipmentLine."Item No.");
        _BaseOrderLine.Set_ItemBarcode(MobItemReferenceMgt.GetBarcodeList(_WhseShipmentLine."Item No.", _WhseShipmentLine."Variant Code", _WhseShipmentLine."Unit of Measure Code"));

        _BaseOrderLine.SetTracking(MobTrackingSetup);
        _BaseOrderLine.SetRegisterTracking(MobTrackingSetup);
        _BaseOrderLine.Set_RegisterExpirationDate(ExpDateRequired); // always false on shipment lines with no ATO

        // If the <RegisterQuantityByScan> element is set to true the mobile device can use values in <BarcodeQuantity>
        // element to register the quantity associated with barcode instead of always registering 1.
        _BaseOrderLine.Set_RegisterQuantityByScan(false);

        _BaseOrderLine.Set_Description(_WhseShipmentLine.Description);

        _BaseOrderLine.Set_Quantity(MobSetup."Use Base Unit of Measure", _QtyToShipBase, _QtyToShip);
        _BaseOrderLine.Set_RegisteredQuantity('0');

        _BaseOrderLine.Set_UnitOfMeasure(MobSetup."Use Base Unit of Measure", Item."Base Unit of Measure", _WhseShipmentLine."Unit of Measure Code");

        // Decide what to display on the lines
        // There are 5 display lines available in the standard configuration
        // Line 1: Show the Bin
        // Line 2: Show the Item Number + UoM under the quantity (this is handled in the UserRole.xml on the mobile device)
        // Line 3: Show the Item Description
        // Line 4: Show the Item Variant + tracking + shipment document status
        // Line 4_1: Item Variant + tracking (part of Line 4 as single field)
        // Line 4_2: Shipment Document Status (part of Line 4 as single field)
        _BaseOrderLine.Set_DisplayLine1(_WhseShipmentLine."Bin Code");
        _BaseOrderLine.Set_DisplayLine2(_WhseShipmentLine."Item No.");
        _BaseOrderLine.Set_DisplayLine3(_WhseShipmentLine.Description);

        // DisplayLine4 is set later as merge of DisplayLine5 and DisplayLine6 due to limited number of lines in default shipment page in application.cfg
        if _WhseShipmentLine."Variant Code" <> '' then
            DisplayDimList.Add(MobWmsLanguage.GetMessage('VARIANT_LABEL') + ': ' + _WhseShipmentLine."Variant Code");

        if _BaseOrderLine.Get_LotNumber() <> '' then
            DisplayDimList.Add(MobWmsLanguage.GetMessage('LOT_NO_LABEL') + ': ' + _BaseOrderLine.Get_LotNumber());

        if _BaseOrderLine.Get_SerialNumber() <> '' then
            DisplayDimList.Add(MobWmsLanguage.GetMessage('SERIAL_NO_LABEL') + ': ' + _BaseOrderLine.Get_SerialNumber());

        _BaseOrderLine.SetValue('DisplayLine4_1', MobWmsToolbox.List2TextLn(DisplayDimList, 999));

        // Pick status (Partial/Complete/NotPicked)
        if DummyLocation.RequirePicking(_WhseShipmentLine."Location Code") then begin
            if MobSetup."Use Base Unit of Measure" then begin
                UseQtyOutstanding := _QtyOutstandingBase;
                UseQtyPickedNotShipped := _QtyPickedNotShippedBase;
            end else begin
                UseQtyOutstanding := _QtyOutstanding;
                UseQtyPickedNotShipped := _QtyPickedNotShipped;
            end;

            case true of
                _QtyPickedNotShippedBase = _QtyOutstandingBase:
                    _BaseOrderLine.SetValue('DisplayLine4_2', MobWmsLanguage.GetMessage('SHIPMENT_DOCUMENT_STATUS_COMPLETELY_PICKED'));
                _QtyPickedNotShippedBase > 0:
                    _BaseOrderLine.SetValue('DisplayLine4_2', StrSubstNo('%1 (%2/%3)', MobWmsLanguage.GetMessage('SHIPMENT_DOCUMENT_STATUS_PARTIALLY_PICKED'), UseQtyPickedNotShipped, UseQtyOutstanding))
                else
                    _BaseOrderLine.SetValue('DisplayLine4_2', StrSubstNo('%1 (%2)', MobWmsLanguage.GetMessage('SHIPMENT_DOCUMENT_STATUS_NOT_PICKED'), UseQtyOutstanding));   // Artificial status to replace "blank"
            end;
        end;

        // Only 4 DiplayLines available in default shipment order list in application.cfg -> condense some information
        if _BaseOrderLine.GetValue('DisplayLine4_1') <> '' then
            _BaseOrderLine.Set_DisplayLine4(_BaseOrderLine.GetValue('DisplayLine4_1'));
        if _BaseOrderLine.GetValue('DisplayLine4_2') <> '' then
            _BaseOrderLine.Set_DisplayLine4(_BaseOrderLine.Get_DisplayLine4() + MobToolbox.CRLFSeparator() + _BaseOrderLine.GetValue('DisplayLine4_2'));

        // The choices are: None, Warn, Block
        _BaseOrderLine.Set_UnderDeliveryValidation('Warn');
        _BaseOrderLine.Set_OverDeliveryValidation('Block');

        _BaseOrderLine.Set_AllowBinChange(true);

        _BaseOrderLine.Set_ReferenceID(_WhseShipmentLine);
        _BaseOrderLine.Set_Status('0');
        _BaseOrderLine.Set_Attachment();
        _BaseOrderLine.Set_ItemImageID();

        // event with legacy signature (avoid breaking change)
        TempReservationEntryParm.TransferFields(_TempTrackingSpecification);
        OnGetShipOrderLines_OnAfterSetFromWarehouseShipmentLine(_WhseShipmentLine, TempReservationEntryParm, _BaseOrderLine);

        TempSteps.SetMustCallCreateNext(true);
        OnGetShipOrderLines_OnAddStepsToWarehouseShipmentLine(_WhseShipmentLine, MobTrackingSetup, _BaseOrderLine, TempSteps);
        if not TempSteps.IsEmpty() then
            _BaseOrderLine.Set_Workflow(TempSteps, "MOB TweakType"::Append);
    end;

    local procedure PostedWhseShipmentHeaderExists(_WhseShipmentHeader: Record "Warehouse Shipment Header"): Boolean
    var
        PostedWhseShipmentHeader: Record "Posted Whse. Shipment Header";
    begin
        PostedWhseShipmentHeader.SetRange("Whse. Shipment No.", _WhseShipmentHeader."No.");
        PostedWhseShipmentHeader.SetRange("MOB MessageId", _WhseShipmentHeader."MOB Posting MessageId"); //TODO Missing Index!
        exit(not PostedWhseShipmentHeader.IsEmpty());
    end;

    //
    // ------- IntegrationEvents: GetShipOrders -------
    // 
    // OnSetFilterWarehouseShipment             from  'GetOrders'
    // OnIncludeWarehouseShipmentHeader         from  MobWmsBaseDocumentHandler.CopyFilteredWhseShipmentHeadersToTempRecord()
    // OnAfterSetFromWarehouseShipmentHeader    from  'GetOrders'.GetOrders().GetWarehouseShipments().CreateOrdersResponse().SetFromWarehouseShipmentHeader()
    // OnAfterSetCurrentKey                     from  'GetOrders'.AddBaseOrderElements()

    [IntegrationEvent(false, false)]
    local procedure OnGetShipOrders_OnSetFilterWarehouseShipment(_HeaderFilter: Record "MOB NS Request Element"; var _WhseShipmentHeader: Record "Warehouse Shipment Header"; var _WhseShipmentLine: Record "Warehouse Shipment Line"; var _IsHandled: Boolean)
    begin
        // Called from MOB Activity for activity types Movement and Invt.Movement
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnGetShipOrders_OnIncludeWarehouseShipmentHeader(_WhseShipmentHeader: Record "Warehouse Shipment Header"; var _HeaderFilters: Record "MOB NS Request Element"; var _IncludeInOrderList: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetShipOrders_OnAfterSetFromWarehouseShipmentHeader(_WhseShipmentHeader: Record "Warehouse Shipment Header"; var _BaseOrderElement: Record "MOB NS BaseDataModel Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetShipOrders_OnAfterSetCurrentKey(var _BaseOrderElementView: Record "MOB NS BaseDataModel Element")
    begin
    end;

    //
    // ------- IntegrationEvents: GetShipOrderLines -------
    //
    // OnSetFilterWarehouseShipmentLine         from  'GetPutAwayOrderLines'
    // OnIncludeWarehouseShipmentLine           from  'GetOrderLines'.CreateWhseShipmentLinesResponse()
    // OnAfterSetFromWarehouseShipmentLine      from  'GetOrderLines'.CreateWhseShipmentLinesResponse().SetFromWarehouseShipmentLine()
    // OnAfterSetCurrentKey                     from  'GetOrderLines'.AddBaseOrderLineElements()
    // OnAddStepsToWarehouseShipmentHeader      from  'GetOrderLines'.CreateWhseShipmentLinesResponse().AddStepsToWarehouseShipmentHeader()
    // OnAddStepsToWarehouseShipmentLine        from  'GetOrderLines'.CreateWhseShipmentLinesResponse().SetFromWarehouseShipmentLine()

    [IntegrationEvent(false, false)]
    local procedure OnGetShipOrderLines_OnSetFilterWarehouseShipmentLine(var _WhseShipmentLine: Record "Warehouse Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetShipOrderLines_OnIncludeWarehouseShipmentLine(_WhseShipmentLine: Record "Warehouse Shipment Line"; var _IncludeInOrderLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetShipOrderLines_OnAfterSetFromWarehouseShipmentLine(_WhseShipmentLine: Record "Warehouse Shipment Line"; _TempReservationEntry: Record "Reservation Entry"; var _BaseOrderLineElement: Record "MOB NS BaseDataModel Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetShipOrderLines_OnAfterSetCurrentKey(var _BaseOrderLineElementView: Record "MOB NS BaseDataModel Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetShipOrderLines_OnAddStepsToWarehouseShipmentHeader(_WhseShipmentHeader: Record "Warehouse Shipment Header"; var _StepsElement: Record "MOB Steps Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetShipOrderLines_OnAddStepsToWarehouseShipmentLine(_WhseShipmentLine: Record "Warehouse Shipment Line"; _MobTrackingSetup: Record "MOB Tracking Setup"; var _BaseOrderLineElement: Record "MOB NS BaseDataModel Element"; var _Steps: Record "MOB Steps Element")
    begin
    end;

    //
    // ------- IntegrationEvents: PostShipOrder -------
    //
    // OnPostShipOrder_OnHandleRegistrationForWarehouseShipmentLine     from  'PostOrder.PostWhseShipmentOrder()'
    // OnPostShipOrder_OnAddStepsToWarehouseShipmentHeader              from  'PostOrder.PostWhseShipmentOrder()'
    // OnPostShipOrder_OnBeforePostWarehouseShipment                    from  'PostOrder.PostWhseShipmentOrder()'
    // OnPostShipOrder_OnBeforeRunWhsePostShipment                      from  'PostOrder.PostWhseShipmentOrder()'

    [IntegrationEvent(false, false)]
    local procedure OnPostShipOrder_OnHandleRegistrationForWarehouseShipmentLine(var _Registration: Record "MOB WMS Registration"; var _WarehouseShipmentLine: Record "Warehouse Shipment Line"; var _NewReservationEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostShipOrder_OnAddStepsToWarehouseShipmentHeader(var _OrderValues: Record "MOB Common Element"; _WhseShipmentHeader: Record "Warehouse Shipment Header"; var _StepsElement: Record "MOB Steps Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostShipOrder_OnBeforePostWarehouseShipment(var _OrderValues: Record "MOB Common Element"; var _WhseShipmentHeader: Record "Warehouse Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostShipOrder_OnBeforeRunWhsePostShipment(var _WhseShipmentLinesToPost: Record "Warehouse Shipment Line"; var _WhsePostShipment: Codeunit "Whse.-Post Shipment")
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnPostShipOrder_OnAfterPostWarehouseShipment(var _OrderValues: Record "MOB Common Element"; var _WhseShipmentLine: Record "Warehouse Shipment Line"; var _ResultMessage: Text)
    begin
    end;

    /// <summary>
    /// Used from Adhoc PostToteShipping -> ReservEntriesExist()
    /// Subscription exists from MOB Tracking Management.
    /// </summary>
    [IntegrationEvent(false, false)]
    local procedure OnReservEntriesExistOnCheckValidOutboundTracking(_ItemTrackingCode: Record "Item Tracking Code"; _MobTrackingSetup: Record "MOB Tracking Setup"; _ReservEntry: Record "Reservation Entry"; var _ValidOutboundTracking: Boolean)
    begin
    end;

    /// <summary>
    /// Used from Adhoc PostToteShipping -> ReservEntriesExist() -> GetAvailableItemsTxt()
    /// Subscription exists from MOB Tracking Management.
    /// </summary>
    [IntegrationEvent(false, false)]
    local procedure OnGetAvailableItemsTxtOnAddTrackingIfNotBlank(_MobTrackingSetup: Record "MOB Tracking Setup"; _Quantity: Decimal; _UoMCode: Code[10]; var _AvailableItemsTxt: Text)
    begin
    end;

}

