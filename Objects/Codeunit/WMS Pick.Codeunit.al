codeunit 81374 "MOB WMS Pick"
{
    Access = Public;

    TableNo = "MOB Document Queue";

    trigger OnRun()
    begin
        MobDocQueue := Rec;

        case Rec."Document Type" of

            // Order headers
            'GetPickOrders':
                GetOrders();

            // Order lines
            'GetPickOrderLines':
                GetOrderLines();

            // Posting
            'PostPickOrder':
                PostOrder();

            else
                Error(MobWmsLanguage.GetMessage('NO_DOC_HANDLER'), Rec."Document Type");
        end;

        // Store the result in the queue and update the status
        MobToolbox.UpdateResult(Rec, XmlResponseDoc);
    end;

    var
        MobDocQueue: Record "MOB Document Queue";
        MobSessionData: Codeunit "MOB SessionData";
        MobItemReferenceMgt: Codeunit "MOB Item Reference Mgt.";
        MobRequestMgt: Codeunit "MOB NS Request Management";
        MobXmlMgt: Codeunit "MOB XML Management";
        MobBaseDocHandler: Codeunit "MOB WMS Base Document Handler";
        MobToolbox: Codeunit "MOB Toolbox";
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        MobWmsActivity: Codeunit "MOB WMS Activity";
        MobTryEvent: Codeunit "MOB Try Event";
        XmlResponseDoc: XmlDocument;
        ResultMessage: Text;

    local procedure GetOrders()
    var
        TempHeaderElement: Record "MOB NS BaseDataModel Element" temporary;
        WhseActHeader: Record "Warehouse Activity Header";
        XmlRequestDoc: XmlDocument;
        XmlResponseData: XmlNode;
    begin
        // Load the request document from the document queue
        MobDocQueue.LoadXMLRequestDoc(XmlRequestDoc);

        // Initialize the response document for order data
        // This is used for all order types
        MobToolbox.InitializeResponseDoc(XmlResponseDoc, XmlResponseData);

        // Warehouse- or Inventory-Picks to buffer
        WhseActHeader.SetFilter(Type, '%1|%2', WhseActHeader.Type::Pick, WhseActHeader.Type::"Invt. Pick");
        MobWmsActivity.GetPickOrders(XmlRequestDoc, WhseActHeader, MobDocQueue, TempHeaderElement);

        // Sales orders to buffer
        GetSalesOrders(XmlRequestDoc, MobDocQueue, TempHeaderElement);

        // Transfer orders to buffer
        GetTransferOrders(XmlRequestDoc, MobDocQueue, TempHeaderElement);

        // Purchase Return Orders to buffer
        GetPurchaseReturnOrders(XmlRequestDoc, MobDocQueue, TempHeaderElement);

        // Add collected buffer values to new <Orders> nodes
        AddBaseOrderElements(XmlResponseData, TempHeaderElement);
    end;

    local procedure GetOrderLines()
    var
        XmlRequestDoc: XmlDocument;
        XmlBackendIDNode: XmlNode;
        BackendID: Code[30];
        XmlRequestNode: XmlNode;
        XmlRequestDataNode: XmlNode;
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
        // We want to extract the BackendID (Order No.) from the XML to get the order lines

        // Load the request document from the document queue
        MobDocQueue.LoadXMLRequestDoc(XmlRequestDoc);

        // Get the <BackendID> element (the first item in the returned node list)
        MobXmlMgt.GetDocRootNode(XmlRequestDoc, XmlRequestNode);
        MobXmlMgt.FindNode(XmlRequestNode, 'requestData', XmlRequestDataNode);
        MobXmlMgt.FindNode(XmlRequestDataNode, 'BackendID', XmlBackendIDNode);

        // Read the value of the BackendID
        BackendID := MobXmlMgt.GetNodeInnerText(XmlBackendIDNode);

        // Create the response for the mobile device
        case CopyStr(BackendID, 1, 3) of
            'SO-':
                CreateSalesLinesResponse(CopyStr(BackendID, 4, StrLen(BackendID)));
            'TO-':
                CreateTransferLinesResponse(CopyStr(BackendID, 4, StrLen(BackendID)));
            'PR-':
                CreatePurchaseReturnLinesResp(CopyStr(BackendID, 4, StrLen(BackendID)));
            else
                MobWmsActivity.CreateWhseActLinesResponse(XmlResponseDoc, BackendID);
        end;
    end;

    /// <summary>
    /// Collect and output Header Steps
    /// </summary>
    procedure AddStepsToAnyHeader(_RecRef: RecordRef; _XmlResponseDoc: XmlDocument; var _XmlResponseData: XmlNode)
    var
        TempSteps: Record "MOB Steps Element" temporary;
        TempAdditionalValues: Record "MOB Common Element" temporary;
        MobPrint: Codeunit "MOB Print";
        RegistrationCollectorConfiguration: XmlNode;
        XmlSteps: XmlNode;
    begin
        // Get steps for printing
        MobPrint.GetStepsForPrintOnPosting(_RecRef, TempSteps, TempAdditionalValues);

        // Event: OnAddSteps
        TempSteps.SetMustCallCreateNext(true);
        OnGetPickOrderLines_OnAddStepsToAnyHeader(_RecRef, TempSteps);

        // Allow integration partners to update custom registration collectors (standard Mobile WMS has no header steps - but Pack&Ship includes pick steps for PackingStation and staging hint)
        TempSteps.SetMustCallCreateNext(false);
        if TempSteps.FindSet() then
            repeat
                OnGetPickOrderLines_OnAfterAddStepToAnyHeader(_RecRef, TempSteps);
            until TempSteps.Next() = 0;

        if not TempSteps.IsEmpty() then begin
            // Add nodes: RegCollectorConf and Steps
            MobToolbox.AddCollectorConfiguration(_XmlResponseDoc, _XmlResponseData, RegistrationCollectorConfiguration, XmlSteps);
            MobXmlMgt.AddStepsaddElements(XmlSteps, TempSteps);

            // Add node: AdditionalValues   
            MobToolbox.AddAdditionalValuesToCollectorConfiguration(RegistrationCollectorConfiguration, TempAdditionalValues);
        end;
    end;

    local procedure PostOrder()
    var
        MobReg: Record "MOB WMS Registration";
        TempReturnSteps: Record "MOB Steps Element" temporary;
        XmlRequestDoc: XmlDocument;
        XmlRequestNode: XmlNode;
        XmlRequestDataNode: XmlNode;
        XmlOrderNode: XmlNode;
        AttributeValue: Text[250];
        BackendID: Code[30];
    begin
        // Description:
        // The posting processes for the warehouse activities (put-away, pick, move) are handled identically
        // The function that performes the posting is stored in the WMS toolbox

        // Load the request document from the document queue
        MobDocQueue.LoadXMLRequestDoc(XmlRequestDoc);

        MobXmlMgt.GetDocRootNode(XmlRequestDoc, XmlRequestNode);
        MobXmlMgt.FindNode(XmlRequestNode, 'requestData', XmlRequestDataNode);

        MobXmlMgt.GetNodeFirstChild(XmlRequestDataNode, XmlOrderNode);

        MobXmlMgt.GetAttribute(XmlOrderNode, 'backendID', AttributeValue);
        BackendID := AttributeValue;

        // Post the order
        case CopyStr(BackendID, 1, 3) of
            'SO-':
                PostSalesOrder(XmlRequestDoc, MobReg.Type::"Sales Order", TempReturnSteps);
            'TO-':
                PostTransferOrder(XmlRequestDoc, MobReg.Type::"Transfer Order", TempReturnSteps);
            'PR-':
                PostPurchaseReturnOrder(XmlRequestDoc, MobReg.Type::"Purchase Return Order", TempReturnSteps);
            else
                MobWmsActivity.PostWhseActivityOrder(MobDocQueue.MessageIDAsGuid(), XmlRequestDoc, MobReg.Type::Pick, TempReturnSteps, ResultMessage);
        end;

        // No errors occurred during posting
        if not TempReturnSteps.IsEmpty() then
            MobToolbox.CreateResponseWithSteps(XmlResponseDoc, TempReturnSteps)
        else
            MobToolbox.CreateSimpleResponse(XmlResponseDoc, ResultMessage);
    end;

    //
    // ----- RESPONSE -----
    // 

    local procedure GetSalesOrders(var _XmlRequestDoc: XmlDocument; var _MobDocQueue: Record "MOB Document Queue"; var _BaseOrderElement: Record "MOB NS BaseDataModel Element")
    var
        Location: Record Location;
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        TempHeaderFilter: Record "MOB NS Request Element" temporary;
        TempFilteredSalesHeader: Record "Sales Header" temporary;
        MobScannedValueMgt: Codeunit "MOB ScannedValue Mgt.";
        IsHandled: Boolean;
        ScannedValue: Text;
    begin
        // Respond with a list of Sales Orders

        // Mandatory Header filters for this function to operate
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.SetRange(Status, SalesHeader.Status::Released);
        SalesHeader.SetRange("Completely Shipped", false);
        // Allow only Inventory locations. Advanced orders are handled as Whse. documents
        SalesHeader.SetFilter("Location Code", MobBaseDocHandler.GetLocationFilter_Inventory(_MobDocQueue."Mobile User ID"));

        // Mandatory Line filters
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.SetRange("Drop Shipment", false);
        SalesLine.SetFilter("Outstanding Qty. (Base)", '>0');

        // XML filter data into Temporary table
        MobRequestMgt.SaveHeaderFilters(_XmlRequestDoc, TempHeaderFilter);

        if TempHeaderFilter.FindSet() then
            repeat

                // Event to allow for handling (custom) filters
                IsHandled := false;
                OnGetPickOrders_OnSetFilterSalesOrder(TempHeaderFilter, SalesHeader, SalesLine, IsHandled);

                if not IsHandled then
                    case TempHeaderFilter.Name of

                        'Location':
                            if TempHeaderFilter."Value" = 'All' then
                                // Set the location filter to all locations not using shpiments or picks (not to all locations in the list)
                                SalesHeader.SetFilter("Location Code", MobBaseDocHandler.GetLocationFilter_Inventory(_MobDocQueue."Mobile User ID"))
                            else begin
                                Location.Get(TempHeaderFilter."Value");
                                if Location."Require Pick" or Location."Require Shipment" then
                                    exit // Pick or ship is used -> do not show sales orders
                                else
                                    SalesHeader.SetRange("Location Code", TempHeaderFilter."Value");
                            end;

                        'ScannedValue':
                            ScannedValue := TempHeaderFilter."Value";   // Used in search for Document No. or Item/Variant later

                        'AssignedUser':
                            case TempHeaderFilter."Value" of
                                'All':
                                    ; // No filter -> do nothing
                                'OnlyMine':
                                    SalesHeader.SetRange("Assigned User ID", _MobDocQueue."Mobile User ID");  // Current user
                                'MineAndUnassigned':
                                    SalesHeader.SetFilter("Assigned User ID", '''''|%1', _MobDocQueue."Mobile User ID"); // Current user or blank
                            end;
                    end;

            until TempHeaderFilter.Next() = 0;

        // Run event once more with Empty "Header filter" to allow for additional filtering directly on the records, NOT related to specific Header filter
        Clear(IsHandled);
        TempHeaderFilter.ClearFields();
        OnGetPickOrders_OnSetFilterSalesOrder(TempHeaderFilter, SalesHeader, SalesLine, IsHandled);

        // Filter: DocumentNo or Item/Variant (match for scanned document no. at location takes precedence over other filters)
        if ScannedValue <> '' then
            MobScannedValueMgt.SetFilterForSalesDoc(SalesHeader, SalesLine, ScannedValue);

        // Insert orders into temp rec
        MobBaseDocHandler.CopyFilteredSalesHeadersToTempRecord(SalesHeader, SalesLine, TempHeaderFilter, TempFilteredSalesHeader);

        // Respond with resulting orders
        CreateSalesHeaderResponse(TempFilteredSalesHeader, _BaseOrderElement);
    end;

    local procedure CreateSalesLinesResponse(_OrderNo: Code[20])
    var
        TempBaseOrderLineElement: Record "MOB NS BaseDataModel Element" temporary;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RecRef: RecordRef;
        XmlResponseData: XmlNode;
        IncludeInOrderLines: Boolean;
    begin
        // Initialize the response document for order line data
        MobToolbox.InitializeOrderLineDataRespDoc(XmlResponseDoc, XmlResponseData);

        if SalesHeader.Get(SalesHeader."Document Type"::Order, _OrderNo) then begin

            // Add collectorSteps to be displayed on posting
            RecRef.GetTable(SalesHeader);
            AddStepsToAnyHeader(RecRef, XmlResponseDoc, XmlResponseData);

            // Filter the sales lines
            SalesLine.SetRange("Document Type", SalesHeader."Document Type");
            SalesLine.SetRange("Document No.", SalesHeader."No.");
            SalesLine.SetRange(Type, SalesLine.Type::Item);
            SalesLine.SetRange("Drop Shipment", false);
            SalesLine.SetFilter("Outstanding Qty. (Base)", '>0');

            // Event to expose Lines for filtering before Response
            OnGetPickOrderLines_OnSetFilterSalesLine(SalesLine);

            if SalesLine.FindSet() then
                repeat
                    IncludeInOrderLines := SalesLine.IsInventoriableItem();

                    // Verify additional conditions from eventsubscribers
                    OnGetPickOrderLines_OnIncludeSalesLine(SalesLine, IncludeInOrderLines);

                    if IncludeInOrderLines then begin

                        TempBaseOrderLineElement.Create();
                        SetFromSalesLine(SalesLine, TempBaseOrderLineElement);
                        TempBaseOrderLineElement.Save();

                    end;
                until SalesLine.Next() = 0;

            AddBaseOrderLineElements(XmlResponseData, TempBaseOrderLineElement);
        end;
    end;

    local procedure PostSalesOrder(var _XmlRequestDoc: XmlDocument; _RegistrationType: Enum "MOB WMS Registration Type"; var _ReturnSteps: Record "MOB Steps Element")
    var
        MobSetup: Record "MOB Setup";
        MobTrackingSetup: Record "MOB Tracking Setup";
        Location: Record Location;
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        TempReservationEntryLog: Record "Reservation Entry" temporary;
        TempReservationEntry: Record "Reservation Entry" temporary;
        MobSpecificTrackingSetup: Record "MOB Tracking Setup";
        MobWmsRegistration: Record "MOB WMS Registration";
        TempOrderValues: Record "MOB Common Element" temporary;
        AsmHeader: Record "Assembly Header";
        UoMMgt: Codeunit "Unit of Measure Management";
        SalesPost: Codeunit "Sales-Post";
        SalesRelease: Codeunit "Release Sales Document";
        MobSyncItemTracking: Codeunit "MOB Sync. Item Tracking";
        MobPrint: Codeunit "MOB Print";
        HeaderRecRef: RecordRef;
        LineRecRef: RecordRef;
        OrderID: Code[20];
        RegisterExpirationDate: Boolean;
        Qty: Decimal;
        QtyBase: Decimal;
        TotalQty: Decimal;
        TotalQtyBase: Decimal;
        AssembleToOrder: Boolean;
        PostingRunSuccessful: Boolean;
        PostedDocExists: Boolean;
    begin
        // The XML looks like this:
        //<request name="PostXXXOrder" created="2009-02-20T13:32:10-08:00" xmlns="http://schemas.microsoft.com/Dynamics/Mobile/2007/04/Doc
        //  <requestData name="PostXXXOrder">
        //    <Order backendID="PU000059" xmlns="http://schemas.taskletfactory.com/MobileWMS/RegistrationData">
        //      <Line lineNumber="10000">
        //        <Registration>
        //          <FromBin/>
        //          <ToBin>W-08-0001</ToBin>
        //          <SerialNumber/>
        //          <LotNumber>MyTestLot15</LotNumber>
        //          <Quantity>15</Quantity>
        //          <UnitOfMeasure/>
        //        </Registration>
        //      </Line>
        //    </Order>
        //  </requestData>
        //</request>

        // Disable the locktimeout to prevent timeout messages on the mobile device
        LockTimeout(false);

        // Lock the tables to work on
        SalesHeader.LockTable();
        SalesLine.LockTable();
        MobWmsRegistration.LockTable();

        // Turn on commit protection to prevent unintentional committing data
        MobDocQueue.Consistent(false);

        // Read the MOB Setup
        MobSetup.Get();

        // Load the request document header steps
        MobRequestMgt.InitCommonFromXmlOrderNode(_XmlRequestDoc, TempOrderValues);

        // Save the registrations from the XML in the Mobile WMS Registration table
        // The function returns the order id without the prefix
        OrderID := MobWmsToolbox.SaveRegistrationData(MobDocQueue.MessageIDAsGuid(), _XmlRequestDoc, _RegistrationType);

        // Make sure that the order still exists
        if not SalesHeader.Get(SalesHeader."Document Type"::Order, OrderID) then
            Error(MobWmsLanguage.GetMessage('UNKNOWN_ORDER'), OrderID);

        // Set posting date
        if SalesHeader."Posting Date" <> WorkDate() then begin
            SalesRelease.Reopen(SalesHeader);
            SalesRelease.SetSkipCheckReleaseRestrictions();
            SalesHeader.SetHideValidationDialog(true);
            SalesHeader.Validate("Posting Date", WorkDate());
            SalesRelease.Run(SalesHeader);
        end;

        SalesHeader."MOB Posting MessageId" := MobDocQueue.MessageIDAsGuid();

        // OnAddStepsTo IntegrationEvents
        HeaderRecRef.GetTable(SalesHeader);
        OnPostPickOrder_OnAddStepsToSalesHeader(TempOrderValues, SalesHeader, _ReturnSteps);
        OnPostPickOrder_OnAddStepsToAnyHeader(TempOrderValues, HeaderRecRef, _ReturnSteps);
        if not _ReturnSteps.IsEmpty() then begin
            MobSessionData.SetRegistrationTypeTracking('OnAddStepsTo');
            MobWmsToolbox.DeleteRegistrationData(MobDocQueue.MessageIDAsGuid());
            MobDocQueue.Consistent(true);
            exit;   // Interrupt posting and return extra Steps to be displayed at the mobile device
        end;

        // OnBeforePost IntegrationEvents
        OnPostPickOrder_OnBeforePostSalesOrder(TempOrderValues, SalesHeader);
        HeaderRecRef.GetTable(SalesHeader);
        OnPostPickOrder_OnBeforePostAnyOrder(TempOrderValues, HeaderRecRef);
        HeaderRecRef.SetTable(SalesHeader);
        SalesHeader.Modify(true);

        // Filter the sales lines
        SalesLine.SetRange("Document Type", SalesHeader."Document Type"::Order);
        SalesLine.SetRange("Document No.", OrderID);

        // Save the original reservation entrie in case we need to revert (if the posting fails)
        MobSyncItemTracking.SaveOriginalReservationEntriesForSalesLines(SalesLine, TempReservationEntryLog);

        if SalesLine.FindSet() then
            repeat

                // Try to find the registrations
                MobWmsRegistration.SetRange("Posting MessageId", MobDocQueue.MessageIDAsGuid());
                MobWmsRegistration.SetRange(Type, _RegistrationType);
                MobWmsRegistration.SetRange("Order No.", OrderID);
                MobWmsRegistration.SetRange("Line No.", SalesLine."Line No.");
                MobWmsRegistration.SetRange(Handled, false);

                AssembleToOrder := SalesLine.AsmToOrderExists(AsmHeader) and (AsmHeader."Remaining Quantity (Base)" <> 0);

                // Line splitting is not supported for sales orders
                // Before the registrations are processed we need to determine if the user has picked from multiple bins
                MobWmsToolbox.ValidateSingleRegistrationBin(MobWmsRegistration);

                // If the registration is found -> set the quantity to handle
                // Else set the quantity to handle to zero (to avoid posting lines with the qty to handle set to something)
                if MobWmsRegistration.FindSet() then begin

                    // IF Location."Bin Mandatory" Bin Code must be validated.
                    if not Location.Get(SalesLine."Location Code") then
                        Clear(Location);

                    if Location.Get(SalesLine."Location Code") and Location."Bin Mandatory" and SalesLine.IsInventoriableItem() then
                        SalesLine.Validate("Bin Code", MobWmsRegistration.FromBin);

                    // If item tracking is used the quantity must be set to the sum of the registrations
                    // Determine if serial / lot number / package number registration is needed based on sales line type (inbound and outbound "SN Sales Tracking")
                    MobTrackingSetup.DetermineItemTrackingRequiredBySalesLine(SalesLine, RegisterExpirationDate);
                    // MobTrackingSetup.Tracking: Copy later in MobWmsRegistration loop

                    // Initialize the quantity counter
                    TotalQty := 0;
                    TotalQtyBase := 0;

                    repeat
                        // MobTrackingSetup.TrackingRequired: Determined before (outside inner MobWmsRegistration loop)
                        MobTrackingSetup.CopyTrackingFromRegistration(MobWmsRegistration);

                        // Update the quantity
                        if MobSetup."Use Base Unit of Measure" then begin
                            Qty := 0; // To ensure best possible rounding the TotalQty will be calculated after the loop
                            QtyBase := MobWmsRegistration.Quantity;
                        end else begin
                            MobWmsRegistration.TestField(UnitOfMeasure, SalesLine."Unit of Measure Code");
                            Qty := MobWmsRegistration.Quantity;
                            QtyBase := UoMMgt.CalcBaseQty(MobWmsRegistration.Quantity, SalesLine."Qty. per Unit of Measure");
                        end;

                        TotalQty := TotalQty + Qty;
                        TotalQtyBase := TotalQtyBase + QtyBase;

                        // Only verify against existing inventory if "SN Specific Tracking" / "Lot Specific Tracking" is set
                        MobSpecificTrackingSetup.DetermineSpecificTrackingRequiredFromItemNo(SalesLine."No.", RegisterExpirationDate);
                        MobSpecificTrackingSetup.CopyTrackingFromRegistration(MobWmsRegistration);

                        // Lot No. /SN /Package no. at existing entries for this item can only be guaranteed to be populated if "Lot Specific Tracking"/"SN Specific Tracking"/"Package Specific Tracking" is set
                        // Unknown combination of SerialNo/LotNumber/PackageNo is not verified but will throw error in standard posting routine
                        MobSpecificTrackingSetup.CheckTrackingOnInventoryIfRequired(SalesLine."No.", SalesLine."Variant Code");

                        // Synchronize Item Tracking to Source Document
                        if AssembleToOrder then
                            MobSyncItemTracking.CreateTempReservEntryForAssemblyHeader(AsmHeader, MobWmsRegistration, TempReservationEntry, QtyBase)
                        else
                            MobSyncItemTracking.CreateTempReservEntryForSalesLine(SalesLine, MobWmsRegistration, TempReservationEntry, QtyBase);

                        MobWmsToolbox.SaveRegistrationDataFromSource(SalesLine."Location Code", SalesLine."No.", SalesLine."Variant Code", MobWmsRegistration);

                        // OnHandle IntegrationEvents (SalesLine intentionally not modified -- is modified below)
                        OnPostPickOrder_OnHandleRegistrationForSalesLine(MobWmsRegistration, SalesLine, TempReservationEntry);
                        LineRecRef.GetTable(SalesLine);
                        OnPostPickOrder_OnHandleRegistrationForAnyLine(MobWmsRegistration, LineRecRef);
                        LineRecRef.SetTable(SalesLine);

                        // Set the handled flag to true on the registration
                        MobWmsRegistration.Validate(Handled, true);
                        MobWmsRegistration.Modify();

                        if MobTrackingSetup.TrackingRequired() then
                            if TempReservationEntry.Modify() then; // To modify if created earlier and possibly updated in subscriber

                    until MobWmsRegistration.Next() = 0;

                    // To ensure best possible rounding the TotalQty is calculated and rounded only once when MobSetup."Use Base Unit of Measure" is enabled (i.e. 3 * 1/3 = 1)
                    if MobSetup."Use Base Unit of Measure" then
                        TotalQty := UoMMgt.CalcQtyFromBase(TotalQtyBase, SalesLine."Qty. per Unit of Measure");

                    // Set the quantity on the order line
                    SalesLine.Validate("Qty. to Ship", TotalQty);

                end else  // endif MobWmsRegistration.FindSet()
                    SalesLine.Validate("Qty. to Ship", 0);

                SalesLine.Modify();

            until SalesLine.Next() = 0;

        // Find the sales header
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.SetRange("No.", SalesLine."Document No.");
        if SalesHeader.FindFirst() then begin
            SalesHeader.Ship := true;
            SalesHeader.Invoice := false;
            SalesHeader.Modify();
        end;

        // Turn off the commit protection
        // From this point on we explicitely clean up committed data if an error occurs
        MobDocQueue.Consistent(true);
        Commit();

        if not MobSyncItemTracking.Run(TempReservationEntry) then begin
            ResultMessage := GetLastErrorText();
            MobSessionData.SetPreservedLastErrorCallStack();
            MobSyncItemTracking.RevertToOriginalReservationEntriesForSalesLines(SalesLine, TempReservationEntryLog);
            Commit();
            UpdateIncomingSalesOrder(SalesHeader);
            MobWmsToolbox.DeleteRegistrationData(MobDocQueue.MessageIDAsGuid());
            Commit();   // Separate commit to prevent error in UpdateIncomingSalesOrder from preventing Reservation Entries being rollback
            Error(ResultMessage);
        end;

        // Post
        SalesPost.SetSuppressCommit(true);
        PostingRunSuccessful := SalesPost.Run(SalesHeader);

        // If Posted Sales Shipment exists posting has succeeded but something else failed. ie. partner code OnAfter event
        if not PostingRunSuccessful then
            PostedDocExists := SalesShipmentHeaderExists(SalesHeader);

        if PostingRunSuccessful or PostedDocExists then begin
            // The posting was successful
            ResultMessage := MobToolbox.GetPostSuccessMessage(PostingRunSuccessful);

            // Commit to allow for codeunit.run
            Commit();

            // Event OnAfterPost 
            HeaderRecRef.GetTable(SalesHeader);
            MobTryEvent.RunEventOnPlannedPosting('OnPostPickOrder_OnAfterPostAnyOrder', HeaderRecRef, TempOrderValues, ResultMessage); // Internal subscriber handles "Print Shipment on Post"

            // Modify header and remove posting messageId
            UpdateIncomingSalesOrder(SalesHeader);

            // Print on posting
            Commit();
            MobPrint.PrintOnPlannedPosting(HeaderRecRef, TempOrderValues, ResultMessage);

        end else begin

            // The created reservation entries have been committed
            // If the posting fails for some reason we need to clean up the created reservation entries and MobWmsRegistrations
            ResultMessage := GetLastErrorText();
            MobSessionData.SetPreservedLastErrorCallStack();
            MobSyncItemTracking.RevertToOriginalReservationEntriesForSalesLines(SalesLine, TempReservationEntryLog);
            Commit();
            UpdateIncomingSalesOrder(SalesHeader);
            MobWmsToolbox.DeleteRegistrationData(MobDocQueue.MessageIDAsGuid());
            Commit();   // Separate commit to prevent error in UpdateIncomingSalesOrder from preventing Reservation Entries being rollback
            Error(ResultMessage);
        end;
    end;

    local procedure UpdateIncomingSalesOrder(var _SalesHeader: Record "Sales Header")
    begin
        if not _SalesHeader.Get(_SalesHeader."Document Type", _SalesHeader."No.") then
            exit;

        _SalesHeader.LockTable();
        _SalesHeader.Get(_SalesHeader."Document Type", _SalesHeader."No.");
        Clear(_SalesHeader."MOB Posting MessageId");
        _SalesHeader.Modify();
    end;

    local procedure GetTransferOrders(var _XmlRequestDoc: XmlDocument; var _MobDocQueue: Record "MOB Document Queue"; var _BaseOrderElement: Record "MOB NS BaseDataModel Element")
    var
        TransferLine: Record "Transfer Line";
        TransferHeader: Record "Transfer Header";
        TempHeaderFilter: Record "MOB NS Request Element" temporary;
        TempFilteredTransferHeader: Record "Transfer Header" temporary;
        Location: Record Location;
        MobScannedValueMgt: Codeunit "MOB ScannedValue Mgt.";
        IsHandled: Boolean;
        ScannedValue: Text;
    begin
        // Respond with a list of Transfer Orders

        // Mandatory Header filters for this function to operate
        TransferHeader.SetRange(Status, TransferHeader.Status::Released);
        // Allow only Inventory locations. Advanced orders are handled as Whse. documents
        TransferHeader.SetFilter(TransferHeader."Transfer-from Code", MobBaseDocHandler.GetLocationFilter_Inventory(_MobDocQueue."Mobile User ID"));

        // Mandatory Line filters
        TransferLine.SetFilter("Outstanding Qty. (Base)", '>0');
        TransferLine.SetRange("Derived From Line No.", 0);

        // XML filter data into Temporary table
        MobRequestMgt.SaveHeaderFilters(_XmlRequestDoc, TempHeaderFilter);

        if TempHeaderFilter.FindSet() then
            repeat

                // Event to allow for handling (custom) filters
                IsHandled := false;
                OnGetPickOrders_OnSetFilterTransferOrder(TempHeaderFilter, TransferHeader, TransferLine, IsHandled);

                if not IsHandled then
                    case TempHeaderFilter.Name of

                        'Location':
                            if TempHeaderFilter."Value" = 'All' then
                                // Set the location filter to all locations not using shpiments or picks (not to all locations in the list)
                                TransferHeader.SetFilter("Transfer-from Code", MobBaseDocHandler.GetLocationFilter_Inventory(_MobDocQueue."Mobile User ID"))
                            else begin
                                Location.Get(TempHeaderFilter."Value");
                                if Location."Require Pick" or Location."Require Shipment" then
                                    exit // Pick or ship is used -> do not show sales orders
                                else
                                    TransferHeader.SetRange("Transfer-from Code", TempHeaderFilter."Value");
                            end;

                        'AssignedUser':
                            case TempHeaderFilter."Value" of
                                'All':
                                    ; // No filter -> do nothing
                                'OnlyMine':
                                    TransferHeader.SetRange("Assigned User ID", _MobDocQueue."Mobile User ID");  // Current user
                                'MineAndUnassigned':
                                    TransferHeader.SetFilter("Assigned User ID", '''''|%1', _MobDocQueue."Mobile User ID"); // Current user or blank
                            end;

                        'ScannedValue':
                            ScannedValue := TempHeaderFilter."Value";   // Used in search for Document No. or Item/Variant later
                    end;

            until TempHeaderFilter.Next() = 0;

        // Run event once more with Empty "Header filter" to allow for additional filtering directly on the records, NOT related to specific Header filter
        Clear(IsHandled);
        TempHeaderFilter.ClearFields();
        OnGetPickOrders_OnSetFilterTransferOrder(TempHeaderFilter, TransferHeader, TransferLine, IsHandled);

        // Filter: DocumentNo or Item/Variant (match for scanned document no. at location takes precedence over other filters)
        if ScannedValue <> '' then
            MobScannedValueMgt.SetFilterForTransferOrder(TransferHeader, TransferLine, ScannedValue);

        // Insert orders into temp rec
        MobBaseDocHandler.CopyFilteredTransferHeadersToTempRecord(TransferHeader, TransferLine, TempHeaderFilter, TempFilteredTransferHeader, true, false);

        // Respond with resulting orders
        CreateTransferHeaderResponse(TempFilteredTransferHeader, _BaseOrderElement);
    end;

    local procedure CreateTransferLinesResponse(_OrderNo: Code[20])
    var
        MobSetup: Record "MOB Setup";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        TempLineElement: Record "MOB NS BaseDataModel Element" temporary;
        RecRef: RecordRef;
        XmlResponseData: XmlNode;
        IncludeInOrderLines: Boolean;
    begin
        // This function is used to generate the pick order lines for transfer orders
        MobSetup.Get();

        // Initialize the response document for order line data
        MobToolbox.InitializeOrderLineDataRespDoc(XmlResponseDoc, XmlResponseData);

        // Verify that the transfer header exists
        TransferHeader.SetRange("No.", _OrderNo);
        if TransferHeader.FindFirst() then begin

            // Add collectorSteps to be displayed on posting
            RecRef.GetTable(TransferHeader);
            AddStepsToAnyHeader(RecRef, XmlResponseDoc, XmlResponseData);

            // Find the lines
            TransferLine.SetRange("Document No.", TransferHeader."No.");
            TransferLine.SetFilter("Outstanding Qty. (Base)", '>0');
            TransferLine.SetRange("Derived From Line No.", 0);

            // Event to expose Lines for filtering before Response
            OnGetPickOrderLines_OnSetFilterTransferLine(TransferLine);

            if TransferLine.FindSet() then
                repeat
                    // Verify conditions from eventsubscribers
                    IncludeInOrderLines := true;
                    OnGetPickOrderLines_OnIncludeTransferLine(TransferLine, IncludeInOrderLines);

                    if IncludeInOrderLines then begin
                        // Collect the buffer values for the <OrderLine> element
                        TempLineElement.Create();
                        SetFromTransferLine(TransferLine, TempLineElement);
                        TempLineElement.Save();
                    end;
                until TransferLine.Next() = 0;

            AddBaseOrderLineElements(XmlResponseData, TempLineElement);
        end;
    end;

    local procedure PostTransferOrder(var _XmlRequestDoc: XmlDocument; _RegistrationType: Enum "MOB WMS Registration Type"; var _ReturnSteps: Record "MOB Steps Element")
    var
        MobSetup: Record "MOB Setup";
        MobTrackingSetup: Record "MOB Tracking Setup";
        MobWmsRegistration: Record "MOB WMS Registration";
        TempOrderValues: Record "MOB Common Element" temporary;
        TempReservationEntryLog: Record "Reservation Entry" temporary;
        TempReservationEntry: Record "Reservation Entry" temporary;
        Location: Record Location;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        TransferHeaderPost: Record "Transfer Header";
        UoMMgt: Codeunit "Unit of Measure Management";
        TransferOrderPostShipment: Codeunit "TransferOrder-Post Shipment";
        TransferOrderPostYesNo: Codeunit "TransferOrder-Post (Yes/No)";
        MobSyncItemTracking: Codeunit "MOB Sync. Item Tracking";
        HeaderRecRef: RecordRef;
        LineRecRef: RecordRef;
        OrderID: Code[20];
        RegisterExpirationDate: Boolean;
        Qty: Decimal;
        QtyBase: Decimal;
        TotalQty: Decimal;
        TotalQtyBase: Decimal;
        PostingRunSuccessful: Boolean;
        PostedDocExists: Boolean;
    begin
        // The XML looks like this:
        //<request name="PostXXXOrder" created="2009-02-20T13:32:10-08:00" xmlns="http://schemas.microsoft.com/Dynamics/Mobile/2007/04/Doc
        //  <requestData name="PostXXXOrder">
        //    <Order backendID="PU000059" xmlns="http://schemas.taskletfactory.com/MobileWMS/RegistrationData">
        //      <Line lineNumber="10000">
        //        <Registration>
        //          <FromBin/>
        //          <ToBin>W-08-0001</ToBin>
        //          <SerialNumber/>
        //          <LotNumber>MyTestLot15</LotNumber>
        //          <Quantity>15</Quantity>
        //          <UnitOfMeasure/>
        //        </Registration>
        //      </Line>
        //    </Order>
        //  </requestData>
        //</request>

        // Disable the locktimeout to prevent timeout messages on the mobile device
        LockTimeout(false);

        // Lock the tables to work on
        TransferHeader.LockTable();
        TransferLine.LockTable();
        MobWmsRegistration.LockTable();

        // Read Mobile Setup
        MobSetup.Get();

        // Load the request document header steps
        MobRequestMgt.InitCommonFromXmlOrderNode(_XmlRequestDoc, TempOrderValues);

        // Save the registrations from the XML in the Mobile WMS Registration table
        // The function returns the order id without the prefix
        OrderID := MobWmsToolbox.SaveRegistrationData(MobDocQueue.MessageIDAsGuid(), _XmlRequestDoc, _RegistrationType);

        // Make sure that the order still exists
        if not TransferHeader.Get(OrderID) then
            Error(MobWmsLanguage.GetMessage('UNKNOWN_ORDER'), OrderID);

        //Set posting date
        if TransferHeader."Posting Date" <> WorkDate() then begin
            TransferHeader.CalledFromWarehouse(true);
            TransferHeader.Validate("Posting Date", WorkDate());
        end;

        TransferHeader."MOB Posting MessageId" := MobDocQueue.MessageIDAsGuid();

        // OnAddStepsTo IntegrationEvents
        HeaderRecRef.GetTable(TransferHeader);
        OnPostPickOrder_OnAddStepsToTransferHeader(TempOrderValues, TransferHeader, _ReturnSteps);
        OnPostPickOrder_OnAddStepsToAnyHeader(TempOrderValues, HeaderRecRef, _ReturnSteps);
        if not _ReturnSteps.IsEmpty() then begin
            MobSessionData.SetRegistrationTypeTracking('OnAddStepsTo');
            MobWmsToolbox.DeleteRegistrationData(MobDocQueue.MessageIDAsGuid());
            MobDocQueue.Consistent(true);
            exit;   // Interrupt posting and return extra Steps to be displayed at the mobile device
        end;

        // OnBeforePost IntegrationEvents
        OnPostPickOrder_OnBeforePostTransferOrder(TempOrderValues, TransferHeader);
        HeaderRecRef.GetTable(TransferHeader);
        OnPostPickOrder_OnBeforePostAnyOrder(TempOrderValues, HeaderRecRef);
        HeaderRecRef.SetTable(TransferHeader);
        TransferHeader.Modify();

        TransferLine.SetRange("Document No.", OrderID);
        TransferLine.SetRange("Derived From Line No.", 0);
        TransferLine.SetFilter("Item No.", '<>%1', '');

        // Save the original reservation entrie in case we need to revert (if the posting fails)
        MobSyncItemTracking.SaveOriginalReservationEntriesForTransferLines(TransferLine, false, TempReservationEntryLog);

        // Loop through the lines
        if TransferLine.FindSet() then
            repeat

                // Try to find the registrations
                MobWmsRegistration.SetRange("Posting MessageId", MobDocQueue.MessageIDAsGuid());
                MobWmsRegistration.SetRange(Type, _RegistrationType);
                MobWmsRegistration.SetRange("Order No.", OrderID);
                MobWmsRegistration.SetRange("Line No.", TransferLine."Line No.");
                MobWmsRegistration.SetRange(Handled, false);

                // Line splitting is not supported for transfer orders
                // Before the registrations are processed we need to determine if the user has picked from multiple bins
                MobWmsToolbox.ValidateSingleRegistrationBin(MobWmsRegistration);

                // If item tracking is used the quantity must be set to the sum of the registrations
                // Determine if serial / lot number registration is needed
                // Intentionally not verifying Type=Type::Item as transfer lines are always item lines
                MobTrackingSetup.DetermineItemTrackingRequiredByTransferLine(TransferLine, false, RegisterExpirationDate);
                // MobTrackingSetup.Tracking: Copy later in MobWmsRegistration loop

                // Initialize the quantity counter
                TotalQty := 0;
                TotalQtyBase := 0;

                // If the registration is found -> set the quantity to handle
                // Else set the quantity to handle to zero (to avoid posting lines with the qty to handle set to something)
                if MobWmsRegistration.FindSet() then begin
                    // IF Location."Bin Mandatory" Bin Code must be validated.
                    Location.Get(TransferLine."Transfer-from Code");
                    if Location."Bin Mandatory" then
                        TransferLine.Validate("Transfer-from Bin Code", MobWmsRegistration.FromBin);

                    if TransferLine."Direct Transfer" and MobWmsToolbox.LocationIsBinMandatory(TransferLine."Transfer-to Code") then
                        TransferLine.TestField("Transfer-To Bin Code");

                    if MobWmsRegistration.FindSet() then
                        repeat
                            // MobTrackingSetup.TrackingRequired: Determined before (outside inner MobWmsRegistration loop)
                            MobTrackingSetup.CopyTrackingFromRegistration(MobWmsRegistration);

                            // Registrations exist for this line

                            // Calculate registered quantity and base quantity
                            if MobSetup."Use Base Unit of Measure" then begin
                                Qty := 0; // To ensure best possible rounding the TotalQty will be calculated after the loop
                                QtyBase := MobWmsRegistration.Quantity;
                            end else begin
                                MobWmsRegistration.TestField(UnitOfMeasure, TransferLine."Unit of Measure Code");
                                Qty := MobWmsRegistration.Quantity;
                                QtyBase := UoMMgt.CalcBaseQty(MobWmsRegistration.Quantity, TransferLine."Qty. per Unit of Measure");
                            end;

                            TotalQty := TotalQty + Qty;
                            TotalQtyBase := TotalQtyBase + QtyBase;

                            // Make sure that the tracking exists on inventory
                            MobTrackingSetup.CheckTrackingOnInventoryIfRequired(TransferLine."Item No.", TransferLine."Variant Code");

                            // Synchronize Item Tracking to Source Document
                            MobSyncItemTracking.CreateTempReservEntryForTransferLine(TransferLine, false, MobWmsRegistration, TempReservationEntry, QtyBase);

                            MobWmsToolbox.SaveRegistrationDataFromSource(TransferLine."Transfer-from Code", TransferLine."Item No.", TransferLine."Variant Code", MobWmsRegistration);

                            // OnHandle IntegrationEvents (TransferLine intentionally not modified -- is modified below)
                            OnPostPickOrder_OnHandleRegistrationForTransferLine(MobWmsRegistration, TransferLine, TempReservationEntry);
                            LineRecRef.GetTable(TransferLine);
                            OnPostPickOrder_OnHandleRegistrationForAnyLine(MobWmsRegistration, LineRecRef);
                            LineRecRef.SetTable(TransferLine);

                            // Set the handled flag to true on the registration
                            MobWmsRegistration.Validate(Handled, true);
                            MobWmsRegistration.Modify();

                            if MobTrackingSetup.TrackingRequired() then
                                if TempReservationEntry.Modify() then; // To modify if created earlier and possibly updated in subscriber

                        until MobWmsRegistration.Next() = 0;

                    // To ensure best possible rounding the TotalQty is calculated and rounded only once when MobSetup."Use Base Unit of Measure" is enabled (i.e. 3 * 1/3 = 1)
                    if MobSetup."Use Base Unit of Measure" then
                        TotalQty := UoMMgt.CalcQtyFromBase(TotalQtyBase, TransferLine."Qty. per Unit of Measure");

                    // Set the quantity on the order line (in the UoM from the order line)
                    TransferLine.Validate("Qty. to Ship", TotalQty);

                end else  // endif MobWmsRegistration.FindSet()
                    TransferLine.Validate("Qty. to Ship", 0);

                TransferLine.Modify();

            until TransferLine.Next() = 0;

        TransferHeaderPost.SetRange("No.", TransferLine."Document No.");

        if TransferHeaderPost.FindFirst() then; // To avoid error - if (unlikely) record does not exist the posting will error

        Commit();

        if not MobSyncItemTracking.Run(TempReservationEntry) then begin
            ResultMessage := GetLastErrorText();
            MobSessionData.SetPreservedLastErrorCallStack();
            MobSyncItemTracking.RevertToOriginalReservationEntriesForTransferLines(TransferLine, false, TempReservationEntryLog);
            Commit();
            UpdateIncomingTransferOrder(TransferHeader);
            MobWmsToolbox.DeleteRegistrationData(MobDocQueue.MessageIDAsGuid());
            Commit();   // Separate commit to prevent error in UpdateIncomingTransferOrder from preventing Reservation Entries being rollback
            Error(ResultMessage);
        end;

        if TransferHeaderPost."Direct Transfer" then
            PostingRunSuccessful := TransferOrderPostYesNo.Run(TransferHeaderPost)
        else begin
            TransferOrderPostShipment.SetSuppressCommit(true);
            PostingRunSuccessful := TransferOrderPostShipment.Run(TransferHeaderPost);
        end;

        // If Posted Transfer Shipment exists posting has succeeded but something else failed. ie. partner code OnAfter event
        if not PostingRunSuccessful then
            PostedDocExists := TransferShipmentHeaderExists(TransferHeaderPost);

        if PostingRunSuccessful or PostedDocExists then begin
            // The posting was successful
            ResultMessage := MobToolbox.GetPostSuccessMessage(PostingRunSuccessful);

            // Since we have posted the shipment of an outbound transfer order then we automatically create the
            // inbound Receipt/Invt. Put-away if needed
            MobWmsToolbox.CreateInboundTransferWarehouseDoc(TransferHeaderPost."No.");

            // Commit to allow for codeunit.run
            Commit();

            // Event OnAfterPost 
            HeaderRecRef.GetTable(TransferHeaderPost);
            MobTryEvent.RunEventOnPlannedPosting('OnPostPickOrder_OnAfterPostAnyOrder', HeaderRecRef, TempOrderValues, ResultMessage); // Internal subscriber handles "Print Shipment on Post"

            UpdateIncomingTransferOrder(TransferHeader);
        end else begin
            // The created reservation entries have been committed
            // If the posting fails for some reason we need to clean up the created reservation entries and MobWmsRegistrations
            ResultMessage := GetLastErrorText();
            MobSessionData.SetPreservedLastErrorCallStack();
            MobSyncItemTracking.RevertToOriginalReservationEntriesForTransferLines(TransferLine, false, TempReservationEntryLog);
            Commit();
            UpdateIncomingTransferOrder(TransferHeader);
            MobWmsToolbox.DeleteRegistrationData(MobDocQueue.MessageIDAsGuid());
            Commit();   // Separate commit to prevent error in UpdateIncomingTransferOrder from preventing Reservation Entries being rollback
            Error(ResultMessage);
        end;
    end;

    local procedure UpdateIncomingTransferOrder(var _TransferHeader: Record "Transfer Header")
    begin
        if not _TransferHeader.Get(_TransferHeader."No.") then
            exit;

        _TransferHeader.LockTable();
        _TransferHeader.Get(_TransferHeader."No.");
        Clear(_TransferHeader."MOB Posting MessageId");
        _TransferHeader.Modify();
    end;

    local procedure GetPurchaseReturnOrders(var _XmlRequestDoc: XmlDocument; var _MobDocQueue: Record "MOB Document Queue"; var _BaseOrderElement: Record "MOB NS BaseDataModel Element")
    var
        Location: Record Location;
        PurchLine: Record "Purchase Line";
        PurchHeader: Record "Purchase Header";
        TempFilteredPurchHeader: Record "Purchase Header" temporary;
        TempHeaderFilter: Record "MOB NS Request Element" temporary;
        MobScannedValueMgt: Codeunit "MOB ScannedValue Mgt.";
        IsHandled: Boolean;
        ScannedValue: Text;
    begin
        // Respond with a list of Purchase Orders

        // Mandatory Header filters for this function to operate
        PurchHeader.SetRange("Document Type", PurchHeader."Document Type"::"Return Order");
        PurchHeader.SetRange(Status, PurchHeader.Status::Released);
        PurchHeader.SetRange("Completely Received", false);

        // Allow only Inventory locations. Advanced orders are handled as Whse. documents
        PurchHeader.SetFilter("Location Code", MobBaseDocHandler.GetLocationFilter_Inventory(_MobDocQueue."Mobile User ID"));

        // Mandatory Line filters
        PurchLine.SetRange(Type, PurchLine.Type::Item);
        PurchLine.SetFilter("Outstanding Qty. (Base)", '>0');

        // XML filter data into Temporary table
        MobRequestMgt.SaveHeaderFilters(_XmlRequestDoc, TempHeaderFilter);

        if TempHeaderFilter.FindSet() then
            repeat

                // Event to allow for handling (custom) filters
                IsHandled := false;
                OnGetPickOrders_OnSetFilterPurchaseReturnOrder(TempHeaderFilter, PurchHeader, PurchLine, IsHandled);


                if not IsHandled then
                    case TempHeaderFilter.Name of

                        'Location':
                            if TempHeaderFilter."Value" = 'All' then
                                // Set the location filter to all locations not using shipments or Picks (not to all locations in the list)
                                PurchHeader.SetFilter("Location Code", MobBaseDocHandler.GetLocationFilter_Inventory(_MobDocQueue."Mobile User ID"))
                            else begin
                                Location.Get(TempHeaderFilter."Value");
                                if Location."Require Shipment" or Location."Require Pick" then
                                    exit // Shipment or pick is used -> do not show purchase return orders
                                else
                                    PurchHeader.SetRange("Location Code", TempHeaderFilter."Value");
                            end;

                        'AssignedUser':
                            case TempHeaderFilter."Value" of
                                'All':
                                    ; // No filter -> do nothing
                                'OnlyMine':
                                    PurchHeader.SetRange("Assigned User ID", _MobDocQueue."Mobile User ID");  // Current user
                                'MineAndUnassigned':
                                    PurchHeader.SetFilter("Assigned User ID", '''''|%1', _MobDocQueue."Mobile User ID"); // Current user or blank
                            end;

                        'ScannedValue':
                            ScannedValue := TempHeaderFilter."Value";   // Used in search for Document No. or Item/Variant later
                    end;

            until TempHeaderFilter.Next() = 0;

        // Run event once more with Empty "Header filter" to allow for additional filtering directly on the records, NOT related to specific Header filter
        Clear(IsHandled);
        TempHeaderFilter.ClearFields();
        OnGetPickOrders_OnSetFilterPurchaseReturnOrder(TempHeaderFilter, PurchHeader, PurchLine, IsHandled);

        // Filter: DocumentNo or Item/Variant (match for scanned document no. at location takes precedence over other filters)
        if ScannedValue <> '' then
            MobScannedValueMgt.SetFilterForPurchDoc(PurchHeader, PurchLine, ScannedValue);

        // Insert orders into temp rec
        MobBaseDocHandler.CopyFilteredPurchaseHeadersToTempRecord(PurchHeader, PurchLine, TempHeaderFilter, TempFilteredPurchHeader);

        // Respond with resulting orders
        CreatePurchReturnHeaderResponse(TempFilteredPurchHeader, _BaseOrderElement);
    end;

    local procedure CreatePurchaseReturnLinesResp(_OrderNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TempLineElement: Record "MOB NS BaseDataModel Element" temporary;
        RecRef: RecordRef;
        XmlResponseData: XmlNode;
        IncludeInOrderLines: Boolean;
    begin
        // Initialize the response document for order line data
        MobToolbox.InitializeRespDocWithoutNS(XmlResponseDoc, XmlResponseData);

        if PurchaseHeader.Get(PurchaseHeader."Document Type"::"Return Order", _OrderNo) then begin

            // Add collectorSteps to be displayed on posting
            RecRef.GetTable(PurchaseHeader);
            AddStepsToAnyHeader(RecRef, XmlResponseDoc, XmlResponseData);

            // Filter the lines for this particular order
            PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::"Return Order");
            PurchaseLine.SetRange("Document No.", _OrderNo);
            PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
            PurchaseLine.SetFilter("Outstanding Qty. (Base)", '>0');

            // Event to expose Lines for filtering before Response
            OnGetPickOrderLines_OnSetFilterPurchaseReturnLine(PurchaseLine);

            // Insert the values from the header in the XML
            if PurchaseLine.FindSet() then
                repeat
                    IncludeInOrderLines := PurchaseLine.IsInventoriableItem();

                    // Verify additional conditions from eventsubscribers
                    OnGetPickOrderLines_OnIncludePurchaseReturnLine(PurchaseLine, IncludeInOrderLines);

                    if IncludeInOrderLines then begin
                        // Add the data to the order line element
                        TempLineElement.Create();
                        SetFromPurchaseReturnLine(PurchaseLine, TempLineElement);
                        TempLineElement.Save();
                    end;
                until PurchaseLine.Next() = 0;

            AddBaseOrderLineElements(XmlResponseData, TempLineElement);
        end;
    end;

    local procedure PostPurchaseReturnOrder(var _XmlRequestDoc: XmlDocument; _RegistrationType: Enum "MOB WMS Registration Type"; var _ReturnSteps: Record "MOB Steps Element")
    var
        MobSetup: Record "MOB Setup";
        MobTrackingSetup: Record "MOB Tracking Setup";
        Location: Record Location;
        MobWmsRegistration: Record "MOB WMS Registration";
        TempOrderValues: Record "MOB Common Element" temporary;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TempReservationEntryLog: Record "Reservation Entry" temporary;
        TempReservationEntry: Record "Reservation Entry" temporary;
        MobSpecificTrackingSetup: Record "MOB Tracking Setup";
        UoMMgt: Codeunit "Unit of Measure Management";
        PurchRelease: Codeunit "Release Purchase Document";
        PurchPost: Codeunit "Purch.-Post";
        MobSyncItemTracking: Codeunit "MOB Sync. Item Tracking";
        HeaderRecRef: RecordRef;
        LineRecRef: RecordRef;
        RegisterExpirationDate: Boolean;
        Qty: Decimal;
        QtyBase: Decimal;
        TotalQty: Decimal;
        TotalQtyBase: Decimal;
        OrderID: Code[20];
        PostingRunSuccessful: Boolean;
        PostedDocExists: Boolean;
    begin

        // Disable the locktimeout to prevent timeout messages on the mobile device
        LockTimeout(false);

        // Lock the tables to work on
        PurchaseHeader.LockTable();
        PurchaseLine.LockTable();
        MobWmsRegistration.LockTable();

        // Turn on commit protection to prevent unintentional committing data
        MobDocQueue.Consistent(false);

        // Read mobile Setup
        MobSetup.Get();

        // Load the request document header steps
        MobRequestMgt.InitCommonFromXmlOrderNode(_XmlRequestDoc, TempOrderValues);

        // Save the registrations from the XML in the Mobile WMS Registration table
        OrderID := MobWmsToolbox.SaveRegistrationData(MobDocQueue.MessageIDAsGuid(), _XmlRequestDoc, _RegistrationType);

        // Update the purchase header
        PurchaseHeader.Get(PurchaseHeader."Document Type"::"Return Order", OrderID);

        // Set posting date
        if PurchaseHeader."Posting Date" <> WorkDate() then begin
            PurchRelease.Reopen(PurchaseHeader);
            PurchRelease.SetSkipCheckReleaseRestrictions();
            PurchaseHeader.SetHideValidationDialog(true);   // same behavior when reprocessing from queue ie. no "change exchange rate" confirmation
            PurchaseHeader.Validate("Posting Date", WorkDate());
            PurchRelease.Run(PurchaseHeader);
        end;

        PurchaseHeader."MOB Posting MessageId" := MobDocQueue.MessageIDAsGuid();

        // OnAddStepsTo IntegrationEvents
        HeaderRecRef.GetTable(PurchaseHeader);
        OnPostPickOrder_OnAddStepsToPurchaseReturnHeader(TempOrderValues, PurchaseHeader, _ReturnSteps);
        OnPostPickOrder_OnAddStepsToAnyHeader(TempOrderValues, HeaderRecRef, _ReturnSteps);
        if not _ReturnSteps.IsEmpty() then begin
            MobSessionData.SetRegistrationTypeTracking('OnAddStepsTo');
            MobWmsToolbox.DeleteRegistrationData(MobDocQueue.MessageIDAsGuid());
            MobDocQueue.Consistent(true);
            exit;   // Interrupt posting and return extra Steps to be displayed at the mobile device
        end;

        // OnBeforePost IntegrationEvents
        OnPostPickOrder_OnBeforePostPurchaseReturnOrder(TempOrderValues, PurchaseHeader);
        HeaderRecRef.GetTable(PurchaseHeader);
        OnPostPickOrder_OnBeforePostAnyOrder(TempOrderValues, HeaderRecRef);
        HeaderRecRef.SetTable(PurchaseHeader);

        PurchaseHeader.Modify();

        // Filter the purchase return lines
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::"Return Order");
        PurchaseLine.SetRange("Document No.", OrderID);

        // Save the original reservation entrie in case we need to revert (if the posting fails)
        MobSyncItemTracking.SaveOriginalReservationEntriesForPurchLines(PurchaseLine, TempReservationEntryLog);

        // Loop through the purchase lines
        if PurchaseLine.FindSet() then
            repeat

                // Try to find the registrations
                MobWmsRegistration.SetRange("Posting MessageId", MobDocQueue.MessageIDAsGuid());
                MobWmsRegistration.SetRange(Type, _RegistrationType);
                MobWmsRegistration.SetRange("Order No.", OrderID);
                MobWmsRegistration.SetRange("Line No.", PurchaseLine."Line No.");
                MobWmsRegistration.SetRange(Handled, false);

                // Line splitting is not supported for purchase return orders
                // Before the registrations are processed we need to determine if the user has picked from multiple bins
                MobWmsToolbox.ValidateSingleRegistrationBin(MobWmsRegistration);

                // If the registration is found -> set the quantity to handle
                // Else set the quantity to handle to zero (to avoid posting lines with the qty to handle set to something)
                if MobWmsRegistration.FindSet() then begin

                    // IF Location."Bin Mandatory" Bin Code must be validated.
                    if not Location.Get(PurchaseLine."Location Code") then
                        Clear(Location);

                    if Location."Bin Mandatory" and PurchaseLine.IsInventoriableItem() then
                        PurchaseLine.Validate("Bin Code", MobWmsRegistration.FromBin);

                    // If item tracking is used the quantity must be set to the sum of the registrations
                    // Determine if serial / lot number / package number registration is needed based on sales line type (inbound and outbound "SN Sales Tracking")
                    MobTrackingSetup.DetermineItemTrackingRequiredByPurchaseLine(PurchaseLine, RegisterExpirationDate);
                    // MobTrackingSetup.Tracking: Copy later in MobWmsRegistration loop

                    // Initialize the quantity counter
                    TotalQty := 0;
                    TotalQtyBase := 0;

                    repeat
                        // MobTrackingSetup.TrackingRequired: Determined before (outside inner MobWmsRegistration loop)
                        MobTrackingSetup.CopyTrackingFromRegistration(MobWmsRegistration);

                        // Calculate registered quantity and base quantity
                        if MobSetup."Use Base Unit of Measure" then begin
                            Qty := 0; // To ensure best possible rounding the TotalQty will be calculated after the loop
                            QtyBase := MobWmsRegistration.Quantity;
                        end else begin
                            MobWmsRegistration.TestField(UnitOfMeasure, PurchaseLine."Unit of Measure Code");
                            Qty := MobWmsRegistration.Quantity;
                            QtyBase := UoMMgt.CalcBaseQty(MobWmsRegistration.Quantity, PurchaseLine."Qty. per Unit of Measure");
                        end;

                        TotalQty := TotalQty + Qty;
                        TotalQtyBase := TotalQtyBase + QtyBase;

                        // Only verify against existing inventory if "SN Specific Tracking" / "Lot Specific Tracking" is set
                        MobSpecificTrackingSetup.DetermineSpecificTrackingRequiredFromItemNo(PurchaseLine."No.", RegisterExpirationDate);
                        MobSpecificTrackingSetup.CopyTrackingFromRegistration(MobWmsRegistration);

                        // SN/ Lot No. at existing entries for this item can only be guaranteed to be populated if "SN Specific Tracking" or "Lot Specific Tracking" is set
                        // Unknown combination of SerialNo/LotNumber is not verified but will throw error in standard posting routine
                        MobSpecificTrackingSetup.CheckTrackingOnInventoryIfRequired(PurchaseLine."No.", PurchaseLine."Variant Code");
                        // Synchronize Item Tracking to Source Document
                        MobSyncItemTracking.CreateTempReservEntryForPurchLine(PurchaseLine, MobWmsRegistration, TempReservationEntry, QtyBase);

                        MobWmsToolbox.SaveRegistrationDataFromSource(PurchaseLine."Location Code", PurchaseLine."No.", PurchaseLine."Variant Code", MobWmsRegistration);

                        // OnHandle IntegrationEvents (PurchaseLine intentionally not modified -- is modified below)
                        OnPostPickOrder_OnHandleRegistrationForPurchaseReturnLine(MobWmsRegistration, PurchaseLine);
                        LineRecRef.GetTable(PurchaseLine);
                        OnPostPickOrder_OnHandleRegistrationForAnyLine(MobWmsRegistration, LineRecRef);
                        LineRecRef.SetTable(PurchaseLine);

                        // Set the handled flag to true on the registration
                        MobWmsRegistration.Validate(Handled, true);
                        MobWmsRegistration.Modify();

                    until MobWmsRegistration.Next() = 0;

                    // To ensure best possible rounding the TotalQty is calculated and rounded only once when MobSetup."Use Base Unit of Measure" is enabled (i.e. 3 * 1/3 = 1)
                    if MobSetup."Use Base Unit of Measure" then
                        TotalQty := UoMMgt.CalcQtyFromBase(TotalQtyBase, PurchaseLine."Qty. per Unit of Measure");

                    // Set the quantity on the order line
                    PurchaseLine.Validate("Return Qty. to Ship", TotalQty);

                end else  // endif MobWmsRegistration.FindSet()

                    // No registrations found -> set the quantity to zero
                    PurchaseLine.Validate("Return Qty. to Ship", 0);

                // Save the values on the purchase line
                PurchaseLine.Modify();

            until PurchaseLine.Next() = 0;

        // Find the purchase header
        PurchaseHeader.SetRange("Document Type", PurchaseLine."Document Type");
        PurchaseHeader.SetRange("No.", PurchaseLine."Document No.");
        if PurchaseHeader.FindFirst() then begin
            PurchaseHeader.Ship := true;
            PurchaseHeader.Invoice := false;
            PurchaseHeader.Modify();
        end;

        // Turn off the commit protection
        // From this point on we explicitely clean up committed data if an error occurs
        MobDocQueue.Consistent(true);
        Commit();

        if not MobSyncItemTracking.Run(TempReservationEntry) then begin
            ResultMessage := GetLastErrorText();
            MobSessionData.SetPreservedLastErrorCallStack();
            MobSyncItemTracking.RevertToOriginalReservationEntriesForPurchLines(PurchaseLine, TempReservationEntryLog);
            Commit();
            UpdateIncomingPurchaseReturnOrder(PurchaseHeader);
            MobWmsToolbox.DeleteRegistrationData(MobDocQueue.MessageIDAsGuid());
            Commit();   // Separate commit to prevent error in UpdateIncomingSalesOrder from preventing Reservation Entries being rollback
            Error(ResultMessage);
        end;

        // Post
        PurchPost.SetSuppressCommit(true);
        PostingRunSuccessful := PurchPost.Run(PurchaseHeader);

        // If Posted Return Shipment exists posting has succeeded but something else failed. ie. partner code OnAfter event
        if not PostingRunSuccessful then
            PostedDocExists := ReturnShptHeaderExists(PurchaseHeader);

        if PostingRunSuccessful or PostedDocExists then begin
            // The posting was successful
            ResultMessage := MobToolbox.GetPostSuccessMessage(PostingRunSuccessful);
            UpdateIncomingPurchaseReturnOrder(PurchaseHeader);

            // Commit to allow for codeunit.run
            Commit();

            // Event OnAfterPost 
            HeaderRecRef.GetTable(PurchaseHeader);
            MobTryEvent.RunEventOnPlannedPosting('OnPostPickOrder_OnAfterPostAnyOrder', HeaderRecRef, TempOrderValues, ResultMessage); // Internal subscriber handles "Print Shipment on Post"

        end else begin
            // The created reservation entries have been committed
            // If the posting fails for some reason we need to clean up the created reservation entries and MobWmsRegistrations
            ResultMessage := GetLastErrorText();
            MobSessionData.SetPreservedLastErrorCallStack();
            MobSyncItemTracking.RevertToOriginalReservationEntriesForPurchLines(PurchaseLine, TempReservationEntryLog);
            Commit();
            UpdateIncomingPurchaseReturnOrder(PurchaseHeader);
            MobWmsToolbox.DeleteRegistrationData(MobDocQueue.MessageIDAsGuid());
            Commit();   // Separate commit to prevent error in UpdateIncomingPurchaseReturnOrder from preventing Reservation Entries being rollback
            Error(ResultMessage);
        end;
    end;

    local procedure UpdateIncomingPurchaseReturnOrder(var _PurchReturnHeader: Record "Purchase Header")
    begin
        if not _PurchReturnHeader.Get(_PurchReturnHeader."Document Type", _PurchReturnHeader."No.") then
            exit;

        _PurchReturnHeader.LockTable();
        _PurchReturnHeader.Get(_PurchReturnHeader."Document Type", _PurchReturnHeader."No.");
        Clear(_PurchReturnHeader."MOB Posting MessageId");
        _PurchReturnHeader.Modify();
    end;

    local procedure CreatePurchReturnHeaderResponse(var _PurchHeader: Record "Purchase Header"; var _BaseOrderElement: Record "MOB NS BaseDataModel Element")
    begin
        if _PurchHeader.FindSet() then
            repeat
                // Collect the buffer values for <Order> elements
                _BaseOrderElement.Create();
                SetFromPurchaseReturnHeader(_PurchHeader, _BaseOrderElement);
                _BaseOrderElement.Save();
            until _PurchHeader.Next() = 0;
    end;

    local procedure CreateTransferHeaderResponse(var _TransferHeader: Record "Transfer Header"; var _BaseOrderElement: Record "MOB NS BaseDataModel Element")
    begin
        if _TransferHeader.FindSet() then
            repeat
                // Collect the buffer values for the <Order> element
                _BaseOrderElement.Create();
                SetFromTransferHeader(_TransferHeader, _BaseOrderElement);
                _BaseOrderElement.Save();
            until _TransferHeader.Next() = 0;
    end;

    local procedure CreateSalesHeaderResponse(var _SalesReturnHeader: Record "Sales Header"; var _BaseOrderElement: Record "MOB NS BaseDataModel Element")
    begin
        if _SalesReturnHeader.FindSet() then
            repeat
                // Collect the buffer values for the <Order> element and add it to the <Orders> node
                _BaseOrderElement.Create();
                SetFromSalesHeader(_SalesReturnHeader, _BaseOrderElement);
                _BaseOrderElement.Save();
            until _SalesReturnHeader.Next() = 0;
    end;

    // 
    // ------- IntegrationEvents: HELPER -------
    // 

    local procedure AddBaseOrderElements(var _XmlResponseData: XmlNode; var _BaseOrderElement: Record "MOB NS BaseDataModel Element")
    var
        CursorMgt: Codeunit "MOB Cursor Management";
        XmlMgt: Codeunit "MOB XML Management";
    begin
        // store current cursor and sorting
        CursorMgt.Backup(_BaseOrderElement);

        // set sorting to be used for the export, then write to xml
        SetCurrentKeyHeader(_BaseOrderElement);
        XmlMgt.AddNsBaseDataModelBaseOrderElements(_XmlResponseData, _BaseOrderElement);

        // restore cursor and sorting
        CursorMgt.Restore(_BaseOrderElement);
    end;

    local procedure SetCurrentKeyHeader(var _BaseOrderElement: Record "MOB NS BaseDataModel Element")
    var
        TempHeaderElementCustomView: Record "MOB NS BaseDataModel Element" temporary;
    begin
        _BaseOrderElement.SetCurrentKey("Sorting1 (internal)", "Sorting2 (internal)", "Sorting3 (internal)", "Sorting4 (internal)", "Sorting5 (internal)");

        // use new temporary/empty record for integration event to prevent SetFrom from being in effect at this point in time
        TempHeaderElementCustomView.SetView(_BaseOrderElement.GetView());
        OnGetPickOrders_OnAfterSetCurrentKey(TempHeaderElementCustomView);
        _BaseOrderElement.SetView(TempHeaderElementCustomView.GetView());
    end;

    local procedure AddBaseOrderLineElements(var _XmlResponseData: XmlNode; var _BaseOrderLineElement: Record "MOB NS BaseDataModel Element")
    var
        CursorMgt: Codeunit "MOB Cursor Management";
        XmlMgt: Codeunit "MOB XML Management";
    begin
        // store current cursor and sorting, then set default sorting to be used for the export
        CursorMgt.Backup(_BaseOrderLineElement);

        // set sorting to be used for the export, then write to xml
        SetCurrentKeyLine(_BaseOrderLineElement);
        XmlMgt.AddNsBaseDataModelBaseOrderLineElements(_XmlResponseData, _BaseOrderLineElement);

        // restore cursor and sorting
        CursorMgt.Restore(_BaseOrderLineElement);
    end;

    local procedure SetCurrentKeyLine(var _BaseOrderLineElement: Record "MOB NS BaseDataModel Element")
    var
        TempLineElementCustomView: Record "MOB NS BaseDataModel Element" temporary;
    begin
        _BaseOrderLineElement.SetCurrentKey("Sorting1 (internal)", "Sorting2 (internal)", "Sorting3 (internal)", "Sorting4 (internal)", "Sorting5 (internal)");

        // use new temporary/empty record for integration event to prevent SetFrom from being in effect at this point in time
        TempLineElementCustomView.SetView(_BaseOrderLineElement.GetView());
        OnGetPickOrderLines_OnAfterSetCurrentKey(TempLineElementCustomView);
        _BaseOrderLineElement.SetView(TempLineElementCustomView.GetView());
    end;

    local procedure SetFromSalesHeader(_SalesHeader: Record "Sales Header"; var _BaseOrder: Record "MOB NS BaseDataModel Element")
    var
        Location: Record Location;
        RecRef: RecordRef;
    begin
        // Add the data elements to the <Order> element
        _BaseOrder.Init();
        _BaseOrder.Set_BackendID('SO-' + _SalesHeader."No.");

        // Set which values that should be displayed on the line
        _BaseOrder.Set_DisplayLine1(MobWmsLanguage.GetMessage('SALES_ORDER_LABEL') + ' ' + _SalesHeader."No.");
        _BaseOrder.Set_DisplayLine2(_SalesHeader."Sell-to Customer Name" <> '', _SalesHeader."Sell-to Customer Name", _SalesHeader."Sell-to Customer No.");

        if Location.Get(_SalesHeader."Location Code") then
            _BaseOrder.Set_DisplayLine3(Location.Name <> '', Location.Name, Location.Code)
        else
            _BaseOrder.Set_DisplayLine3('');

        if _SalesHeader."Shipment Date" <> 0D then
            _BaseOrder.Set_DisplayLine5(StrSubstNo(MobWmsLanguage.GetMessage('SHIPMENT_DATE'), MobWmsToolbox.Date2TextAsDisplayFormat(_SalesHeader."Shipment Date")));

        _BaseOrder.Set_HeaderLabel1(MobWmsLanguage.GetMessage('ORDER_NUMBER'));
        _BaseOrder.Set_HeaderLabel2(MobWmsLanguage.GetMessage('RECEIVER'));
        _BaseOrder.Set_HeaderValue1(_SalesHeader."No.");
        _BaseOrder.Set_HeaderValue2(_SalesHeader."Sell-to Customer Name");

        RecRef.GetTable(_SalesHeader);
        SetFromAnyHeader(RecRef, _BaseOrder);
        OnGetPickOrders_OnAfterSetFromSalesHeader(_SalesHeader, _BaseOrder);
        OnGetPickOrders_OnAfterSetFromAnyHeader(RecRef, _BaseOrder);
    end;

    local procedure SetFromTransferHeader(_TransferHeader: Record "Transfer Header"; var _BaseOrder: Record "MOB NS BaseDataModel Element")
    var
        FromLocation: Record Location;
        ToLocation: Record Location;
        RecRef: RecordRef;
    begin
        // Add the data elements to the <Order> element
        _BaseOrder.Init();
        _BaseOrder.Set_BackendID('TO-' + _TransferHeader."No.");

        // Set which values that should be displayed on the line        
        if _TransferHeader."Direct Transfer" then
            _BaseOrder.Set_DisplayLine1(_TransferHeader.FieldCaption("Direct Transfer") + ' ' + _TransferHeader."No.")
        else
            _BaseOrder.Set_DisplayLine1(MobWmsLanguage.GetMessage('OUTBOUND_TRANSFER_LABEL') + ' ' + _TransferHeader."No.");

        _BaseOrder.Set_DisplayLine2(
            (FromLocation.Get(_TransferHeader."Transfer-from Code")) and (FromLocation.Name <> ''),
            StrSubstNo(MobWmsLanguage.GetMessage('FROM'), FromLocation.Name),
            StrSubstNo(MobWmsLanguage.GetMessage('FROM'), _TransferHeader."Transfer-from Code"));

        _BaseOrder.Set_DisplayLine3(
            (ToLocation.Get(_TransferHeader."Transfer-to Code")) and (ToLocation.Name <> ''),
            StrSubstNo(MobWmsLanguage.GetMessage('TO'), ToLocation.Name),
            StrSubstNo(MobWmsLanguage.GetMessage('TO'), _TransferHeader."Transfer-to Code"));

        if _TransferHeader."Shipment Date" <> 0D then
            _BaseOrder.Set_DisplayLine4(StrSubstNo(MobWmsLanguage.GetMessage('SHIPMENT_DATE'), MobWmsToolbox.Date2TextAsDisplayFormat(_TransferHeader."Shipment Date")));

        _BaseOrder.Set_HeaderLabel1(MobWmsLanguage.GetMessage('ORDER_NUMBER'));
        _BaseOrder.Set_HeaderLabel2(MobWmsLanguage.GetMessage('RECEIVER'));
        _BaseOrder.Set_HeaderValue1(_TransferHeader."No.");
        _BaseOrder.Set_HeaderValue2(ToLocation.Name <> '', ToLocation.Name, _TransferHeader."Transfer-to Code");

        RecRef.GetTable(_TransferHeader);
        SetFromAnyHeader(RecRef, _BaseOrder);
        OnGetPickOrders_OnAfterSetFromTransferHeader(_TransferHeader, _BaseOrder);
        OnGetPickOrders_OnAfterSetFromAnyHeader(RecRef, _BaseOrder);
    end;

    local procedure SetFromPurchaseReturnHeader(_PurchReturnHeader: Record "Purchase Header"; var _BaseOrder: Record "MOB NS BaseDataModel Element")
    var
        RecRef: RecordRef;
    begin
        // Add the data elements to the <Order> element
        _BaseOrder.Init();
        _BaseOrder.Set_BackendID('PR-' + _PurchReturnHeader."No.");

        // Set which values that should be displayed on the line
        _BaseOrder.Set_DisplayLine1(MobWmsLanguage.GetMessage('RETURN_ORDER_LABEL') + ' ' + _PurchReturnHeader."No.");
        _BaseOrder.Set_DisplayLine2(_PurchReturnHeader."Buy-from Vendor Name");
        _BaseOrder.Set_DisplayLine3(_PurchReturnHeader."No.");

        _BaseOrder.Set_HeaderLabel1(MobWmsLanguage.GetMessage('ORDER_NUMBER'));
        _BaseOrder.Set_HeaderLabel2(MobWmsLanguage.GetMessage('RECEIVER'));
        _BaseOrder.Set_HeaderValue1(_PurchReturnHeader."No.");
        _BaseOrder.Set_HeaderValue2(_PurchReturnHeader."Buy-from Vendor Name");

        RecRef.GetTable(_PurchReturnHeader);
        SetFromAnyHeader(RecRef, _BaseOrder);
        OnGetPickOrders_OnAfterSetFromPurchaseReturnHeader(_PurchReturnHeader, _BaseOrder);
        OnGetPickOrders_OnAfterSetFromAnyHeader(RecRef, _BaseOrder);
    end;

    local procedure SetFromAnyHeader(var _RecRef: RecordRef; var _BaseOrder: Record "MOB NS BaseDataModel Element")
    begin
        _BaseOrder.Set_ReferenceID(_RecRef);
        _BaseOrder.Set_Status();   // Set Locked/Has Attachment symbol (1=Unlocked, 2=Locked, 3=Attachment)
    end;

    local procedure SetFromSalesLine(_SalesLine: Record "Sales Line"; var _BaseOrderLine: Record "MOB NS BaseDataModel Element")
    var
        MobSetup: Record "MOB Setup";
        MobTrackingSetup: Record "MOB Tracking Setup";
        MobBlankTrackingSetup: Record "MOB Tracking Setup";
        TempSteps: Record "MOB Steps Element" temporary;
        Location: Record Location;
        Item: Record Item;
        RecRef: RecordRef;
        ExpDateRequired: Boolean;
        PadInt: Integer;
        PadString: Text[3];
        BinRanking: Integer;
    begin
        MobSetup.Get();

        // Add the data to the order line element
        _BaseOrderLine.Init();
        _BaseOrderLine.Set_OrderBackendID('SO-' + _SalesLine."Document No.");

        // Add the data to the order line element
        PadInt := 1;
        PadString := Format(PadInt);

        _BaseOrderLine.Set_LineNumber(PadStr(PadString, 3, '0') + Format(_SalesLine."Line No."));

        if not Location.Get(_SalesLine."Location Code") then
            Clear(Location);

        _BaseOrderLine.Set_Location(Location.Code);

        if Location."Bin Mandatory" then begin
            // The GetFromBin function tries to find a bin that can fulfill the sales line
            // If a bin is found the Sorting1 variable is set to the bin ranking
            // If bin ranking has been setup properly the order of the sales lines on the mobile device
            // will be the optimal picking route
            Clear(MobBlankTrackingSetup);
            _BaseOrderLine.Set_FromBin(MobWmsToolbox.GetFromBin(_SalesLine."No.", _SalesLine."Location Code", _SalesLine."Variant Code", MobBlankTrackingSetup, _SalesLine."Outstanding Qty. (Base)", BinRanking));     // BinContent with blank Tracking
            _BaseOrderLine.Set_ValidateFromBin(true);
        end else begin
            // No location or no mandatory bin -> no bin validation
            _BaseOrderLine.Set_FromBin(MobWmsToolbox.GetItemShelfNo(_SalesLine."No.", _SalesLine."Location Code", _SalesLine."Variant Code"));
            _BaseOrderLine.Set_ValidateFromBin(_BaseOrderLine.Get_FromBin() <> '');
        end;

        _BaseOrderLine.Set_ToBin('');
        _BaseOrderLine.Set_ValidateToBin(false);

        // Set the primary sorting to BinRanking, then sequence inserted
        _BaseOrderLine.Set_Sorting1(BinRanking);

        _BaseOrderLine.Set_ItemNumber(_SalesLine."No.");

        if _SalesLine.Type = _SalesLine.Type::Item then
            _BaseOrderLine.Set_ItemBarcode(MobItemReferenceMgt.GetBarcodeList(_SalesLine."No.", _SalesLine."Variant Code", _SalesLine."Unit of Measure Code"))
        else
            _BaseOrderLine.Set_ItemBarcode(_SalesLine."No.");  // Fallback to No. for non-item types

        _BaseOrderLine.Set_Description(_SalesLine.Description);

        // Determine if serial / lot / package number registration is needed
        Clear(MobTrackingSetup);
        MobTrackingSetup.DetermineItemTrackingRequiredBySalesLine(_SalesLine, ExpDateRequired);
        // MobTrackingSetup.Tracking: Tracking values are unused in this scope

        _BaseOrderLine.SetTracking(MobTrackingSetup);   // Set empty "Serial No." / "Lot No." / "Package No." to include tags in xml
        _BaseOrderLine.SetRegisterTracking(MobTrackingSetup);
        _BaseOrderLine.Set_RegisterExpirationDate(ExpDateRequired);

        // If the <RegisterQuantityByScan> element is set to true the mobile device can use values in <BarcodeQuantity>
        // element to register the quantity associated with barcode instead of always registering 1.
        _BaseOrderLine.Set_RegisterQuantityByScan(false);

        // The quantity on the mobile device is always in base UoM
        _BaseOrderLine.Set_Quantity(MobSetup."Use Base Unit of Measure", _SalesLine."Outstanding Qty. (Base)", _SalesLine."Outstanding Quantity");
        _BaseOrderLine.Set_RegisteredQuantity('0');

        // The mobile device always works in the base unit of measure
        _BaseOrderLine.Set_UnitOfMeasure(MobSetup."Use Base Unit of Measure" and (_SalesLine.Type = _SalesLine.Type::Item) and Item.Get(_SalesLine."No."), Item."Base Unit of Measure", _SalesLine."Unit of Measure Code");

        // Set which values that should be displayed on the line
        // There are 4 display lines available in the standard configuration
        // Line 1: Show the Bin
        // Line 2: Show the Item Number + UoM under the quantity (this is handled in the UserRole.xml on the mobile device)
        // Line 3: Show the Item Description
        // Line 4: Show the Item Variant
        _BaseOrderLine.Set_DisplayLine1(_BaseOrderLine.Get_FromBin() <> '', _BaseOrderLine.Get_FromBin(), MobWmsLanguage.GetMessage('NO_BIN'));
        _BaseOrderLine.Set_DisplayLine2(_SalesLine."No.");
        _BaseOrderLine.Set_DisplayLine3(_SalesLine.Description);
        _BaseOrderLine.Set_DisplayLine4(_SalesLine."Variant Code" <> '', MobWmsLanguage.GetMessage('VARIANT_LABEL') + ': ' + _SalesLine."Variant Code", '');
        _BaseOrderLine.Set_DisplayLine5('');

        // UnderDeliveryValidation - The choices are: None, Warn, Block
        _BaseOrderLine.Set_UnderDeliveryValidation('Warn');

        // OverDeliveryValidation - The choices are: None, Warn, Block
        _BaseOrderLine.Set_OverDeliveryValidation('Block');

        // Always allow bin change (the posting function will verify that only one bin is registered)
        _BaseOrderLine.Set_AllowBinChange(true);

        RecRef.GetTable(_SalesLine);
        SetFromAnyLine(RecRef, _BaseOrderLine);
        OnGetPickOrderLines_OnAfterSetFromSalesLine(_SalesLine, _BaseOrderLine);
        OnGetPickOrderLines_OnAfterSetFromAnyLine(RecRef, _BaseOrderLine);

        TempSteps.SetMustCallCreateNext(true);
        OnGetPickOrderLines_OnAddStepsToAnyLine(RecRef, _BaseOrderLine, TempSteps);
        if not TempSteps.IsEmpty() then
            _BaseOrderLine.Set_Workflow(TempSteps, "MOB TweakType"::Append);
    end;

    local procedure SetFromTransferLine(_TransferLine: Record "Transfer Line"; var _BaseOrderLine: Record "MOB NS BaseDataModel Element")
    var
        MobSetup: Record "MOB Setup";
        MobTrackingSetup: Record "MOB Tracking Setup";
        MobBlankTrackingSetup: Record "MOB Tracking Setup";
        TempSteps: Record "MOB Steps Element" temporary;
        Location: Record Location;
        Item: Record Item;
        RecRef: RecordRef;
        DummyExpDateRequired: Boolean;
        PadInt: Integer;
        PadString: Text[3];
        BinRanking: Integer;
    begin
        MobSetup.Get();

        // Add the data to the order line element
        _BaseOrderLine.Init();
        _BaseOrderLine.Set_OrderBackendID('TO-' + _TransferLine."Document No.");

        // Add the data to the receive orders element
        PadInt := 1;
        PadString := Format(PadInt);
        _BaseOrderLine.Set_LineNumber(PadStr(PadString, 3, '0') + Format(_TransferLine."Line No."));

        if (Location.Get(_TransferLine."Transfer-from Code")) and (Location."Bin Mandatory") then begin
            Clear(MobBlankTrackingSetup);
            _BaseOrderLine.Set_FromBin(MobWmsToolbox.GetFromBin(_TransferLine."Item No.", _TransferLine."Transfer-from Code", _TransferLine."Variant Code", MobBlankTrackingSetup, _TransferLine."Outstanding Qty. (Base)", BinRanking));    // BinContent with blank Tracking
            _BaseOrderLine.Set_ValidateFromBin(true);
        end else begin
            // No location or no mandatory bin -> no bin validation
            _BaseOrderLine.Set_FromBin(MobWmsToolbox.GetItemShelfNo(_TransferLine."Item No.", _TransferLine."Transfer-from Code", _TransferLine."Variant Code"));
            _BaseOrderLine.Set_ValidateFromBin(_BaseOrderLine.Get_FromBin() <> '');
        end;

        _BaseOrderLine.Set_Location(Location.Code);
        _BaseOrderLine.Set_ToBin('');
        _BaseOrderLine.Set_ValidateToBin(false);

        // Set the primary sorting to BinRanking, then sequence inserted
        _BaseOrderLine.Set_Sorting1(BinRanking);

        _BaseOrderLine.Set_ItemNumber(_TransferLine."Item No.");
        _BaseOrderLine.Set_Description(_TransferLine.Description);

        _BaseOrderLine.Set_ItemBarcode(MobItemReferenceMgt.GetBarcodeList(_TransferLine."Item No.", _TransferLine."Variant Code", _TransferLine."Unit of Measure Code"));

        // Determine if serial / lot / package number registration is needed
        Clear(MobTrackingSetup);
        MobTrackingSetup.DetermineItemTrackingRequiredByTransferLine(_TransferLine, false, DummyExpDateRequired);
        // MobTrackingSetup.Tracking: Tracking values are unused in this scope

        _BaseOrderLine.SetTracking(MobTrackingSetup);   // Set empty "Serial No." / "Lot No." / "Package No." to include tags in xml
        _BaseOrderLine.SetRegisterTracking(MobTrackingSetup);
        // Never register expiration date on transfer orders
        _BaseOrderLine.Set_RegisterExpirationDate(false);

        // If the <RegisterQuantityByScan> element is set to true the mobile device can use values in <BarcodeQuantity>
        // element to register the quantity associated with barcode instead of always registering 1.
        _BaseOrderLine.Set_RegisterQuantityByScan(false);

        // Quantity (always in the base UoM)
        _BaseOrderLine.Set_Quantity(MobSetup."Use Base Unit of Measure", _TransferLine."Outstanding Qty. (Base)", _TransferLine."Outstanding Quantity");
        _BaseOrderLine.Set_RegisteredQuantity('0');

        // Unit of measure (always in the base UoM)
        Item.Get(_TransferLine."Item No.");
        _BaseOrderLine.Set_UnitOfMeasure(MobSetup."Use Base Unit of Measure", Item."Base Unit of Measure", _TransferLine."Unit of Measure Code");

        // Set which values that should be displayed on the line
        // There are 4 display lines available in the standard configuration
        // Line 1: Show the Bin
        // Line 2: Show the Item Number + UoM under the quantity (this is handled in the UserRole.xml on the mobile device)
        // Line 3: Show the Item Description
        // Line 4: Show the Item Variant
        if _TransferLine."Direct Transfer" and MobWmsToolbox.LocationIsBinMandatory(_TransferLine."Transfer-to Code") then
            if (_TransferLine."Transfer-To Bin Code" <> '') then
                _BaseOrderLine.Set_DisplayLine1(_BaseOrderLine.Get_FromBin() <> '', _BaseOrderLine.Get_FromBin() + ' -> ' + _TransferLine."Transfer-To Bin Code", MobWmsLanguage.GetMessage('NO_BIN') + ' -> ' + _TransferLine."Transfer-To Bin Code")
            else
                _BaseOrderLine.Set_DisplayLine1(_BaseOrderLine.Get_FromBin() <> '', _BaseOrderLine.Get_FromBin() + ' -> ' + MobWmsLanguage.GetMessage('NO_BIN'), MobWmsLanguage.GetMessage('NO_BIN') + ' -> ' + MobWmsLanguage.GetMessage('NO_BIN'))
        else
            _BaseOrderLine.Set_DisplayLine1(_BaseOrderLine.Get_FromBin() <> '', _BaseOrderLine.Get_FromBin(), MobWmsLanguage.GetMessage('NO_BIN'));

        _BaseOrderLine.Set_DisplayLine2(_TransferLine."Item No.");
        _BaseOrderLine.Set_DisplayLine3(_TransferLine.Description);
        _BaseOrderLine.Set_DisplayLine4(_TransferLine."Variant Code" <> '', MobWmsLanguage.GetMessage('VARIANT_LABEL') + ': ' + _TransferLine."Variant Code", '');
        _BaseOrderLine.Set_DisplayLine5('');

        // UnderDeliveryValidation - The choices are: None, Warn, Block
        _BaseOrderLine.Set_UnderDeliveryValidation('Warn');

        // OverDeliveryValidation - The choices are: None, Warn, Block
        _BaseOrderLine.Set_OverDeliveryValidation('Block');

        // Always allow bin change (the posting function will verify that only one bin is registered)
        _BaseOrderLine.Set_AllowBinChange(true);

        RecRef.GetTable(_TransferLine);
        SetFromAnyLine(RecRef, _BaseOrderLine);
        OnGetPickOrderLines_OnAfterSetFromTransferLine(_TransferLine, _BaseOrderLine);
        OnGetPickOrderLines_OnAfterSetFromAnyLine(RecRef, _BaseOrderLine);

        TempSteps.SetMustCallCreateNext(true);
        OnGetPickOrderLines_OnAddStepsToAnyLine(RecRef, _BaseOrderLine, TempSteps);
        if not TempSteps.IsEmpty() then
            _BaseOrderLine.Set_Workflow(TempSteps, "MOB TweakType"::Append);
    end;

    local procedure SetFromPurchaseReturnLine(_PurchReturnLine: Record "Purchase Line"; var _BaseOrderLine: Record "MOB NS BaseDataModel Element")
    var
        MobSetup: Record "MOB Setup";
        MobTrackingSetup: Record "MOB Tracking Setup";
        MobBlankTrackingSetup: Record "MOB Tracking Setup";
        TempSteps: Record "MOB Steps Element" temporary;
        Location: Record Location;
        Item: Record Item;
        RecRef: RecordRef;
        ExpDateRequired: Boolean;
        BinRanking: Integer;
    begin
        MobSetup.Get();

        // Add the data to the order line element
        _BaseOrderLine.Init();
        _BaseOrderLine.Set_OrderBackendID('PR-' + _PurchReturnLine."Document No.");
        _BaseOrderLine.Set_LineNumber(_PurchReturnLine."Line No.");

        if not Location.Get(_PurchReturnLine."Location Code") then
            Clear(Location);

        _BaseOrderLine.Set_Location(Location.Code);

        if Location."Bin Mandatory" then begin
            // The GetFromBin function tries to find a bin that can fulfill the purchase return line
            // If a bin is found the Sorting1 variable is set to the bin ranking
            // If bin ranking has been setup properly the order of the sales lines on the mobile device
            // will be the optimal picking route
            Clear(MobBlankTrackingSetup);
            _BaseOrderLine.Set_FromBin(MobWmsToolbox.GetFromBin(_PurchReturnLine."No.", _PurchReturnLine."Location Code", _PurchReturnLine."Variant Code", MobBlankTrackingSetup, _PurchReturnLine."Outstanding Qty. (Base)", BinRanking));   // BinContent with blank Tracking
            _BaseOrderLine.Set_ValidateFromBin(true);
        end else begin
            // No location or no mandatory bin -> no bin validation
            _BaseOrderLine.Set_FromBin(MobWmsToolbox.GetItemShelfNo(_PurchReturnLine."No.", _PurchReturnLine."Location Code", _PurchReturnLine."Variant Code"));
            _BaseOrderLine.Set_ValidateFromBin(_BaseOrderLine.Get_FromBin() <> '');
        end;

        // There is no ToBin in purch. returns
        _BaseOrderLine.Set_ToBin('');
        _BaseOrderLine.Set_ValidateToBin(false);

        // Set the primary sorting to BinRanking, then sequence inserted
        _BaseOrderLine.Set_Sorting1(BinRanking);

        _BaseOrderLine.Set_ItemNumber(_PurchReturnLine."No.");

        if _PurchReturnLine.Type = _PurchReturnLine.Type::Item then
            _BaseOrderLine.Set_ItemBarcode(MobItemReferenceMgt.GetBarcodeList(_PurchReturnLine."No.", _PurchReturnLine."Variant Code", _PurchReturnLine."Unit of Measure Code"))
        else
            _BaseOrderLine.Set_ItemBarcode(_PurchReturnLine."No.");  // Fallback to No. for non-item types

        // Determine if serial / lot number registration is needed
        MobBlankTrackingSetup.DetermineItemTrackingRequiredByPurchaseLine(_PurchReturnLine, ExpDateRequired);
        _BaseOrderLine.SetTracking(MobTrackingSetup);
        _BaseOrderLine.SetRegisterTracking(MobTrackingSetup);
        _BaseOrderLine.Set_RegisterExpirationDate(ExpDateRequired);

        // If the <RegisterQuantityByScan> element is set to true the mobile device can use values in <BarcodeQuantity>
        // element to register the quantity associated with barcode instead of always registering 1.
        _BaseOrderLine.Set_RegisterQuantityByScan(false);

        _BaseOrderLine.Set_Description(_PurchReturnLine.Description);

        // The mobile device always works in the base unit of measure
        _BaseOrderLine.Set_Quantity(MobSetup."Use Base Unit of Measure", _PurchReturnLine."Outstanding Qty. (Base)", _PurchReturnLine."Outstanding Quantity");
        _BaseOrderLine.Set_UnitOfMeasure(MobSetup."Use Base Unit of Measure" and (_PurchReturnLine.Type = _PurchReturnLine.Type::Item) and Item.Get(_PurchReturnLine."No."), Item."Base Unit of Measure", _PurchReturnLine."Unit of Measure Code");

        _BaseOrderLine.Set_RegisteredQuantity('0');

        // Decide what to display on the lines
        _BaseOrderLine.Set_DisplayLine1(_PurchReturnLine."No.");
        _BaseOrderLine.Set_DisplayLine2(_PurchReturnLine.Description);
        _BaseOrderLine.Set_DisplayLine3(
                _BaseOrderLine.Get_FromBin() <> '',
                MobWmsLanguage.GetMessage('FROM_BIN_LABEL') + ': ' + _BaseOrderLine.Get_FromBin() + '  ' + MobWmsLanguage.GetMessage('UOM_LABEL') + ': ' + _BaseOrderLine.Get_UnitOfMeasure(),
                MobWmsLanguage.GetMessage('UOM_LABEL') + ': ' + _BaseOrderLine.Get_UnitOfMeasure());
        if _PurchReturnLine."Variant Code" <> '' then
            _BaseOrderLine.Set_DisplayLine4(MobWmsLanguage.GetMessage('VARIANT_LABEL') + ': ' + _PurchReturnLine."Variant Code");

        // UnderDeliveryValidation - The choices are: None, Warn, Block
        _BaseOrderLine.Set_UnderDeliveryValidation('Warn');

        // OverDeliveryValidation - The choices are: None, Warn, Block
        _BaseOrderLine.Set_OverDeliveryValidation('Block');

        // It is always allowed to use another bin than the suggested
        // In the posting function we verify that the user only registers one bin to avoid line splitting
        _BaseOrderLine.Set_AllowBinChange(true);

        RecRef.GetTable(_PurchReturnLine);
        SetFromAnyLine(RecRef, _BaseOrderLine);
        OnGetPickOrderLines_OnAfterSetFromPurchaseReturnLine(_PurchReturnLine, _BaseOrderLine);
        OnGetPickOrderLines_OnAfterSetFromAnyLine(RecRef, _BaseOrderLine);

        TempSteps.SetMustCallCreateNext(true);
        OnGetPickOrderLines_OnAddStepsToAnyLine(RecRef, _BaseOrderLine, TempSteps);
        if not TempSteps.IsEmpty() then
            _BaseOrderLine.Set_Workflow(TempSteps, "MOB TweakType"::Append);
    end;

    local procedure SetFromAnyLine(var _RecRef: RecordRef; var _BaseOrderLine: Record "MOB NS BaseDataModel Element")
    begin
        // Next release: Move from SetFromXXX to here (+verify list of fields below are correct):
        // Set_RegisterQuantityByScan(false);
        // Set_RegisteredQuantity('0');

        // // Under-/OverDeliveryValidation - The choices are: None, Warn, Block
        // Set_UnderDeliveryValidation('Warn');
        // Set_OverDeliveryValidation('Block');

        _BaseOrderLine.Set_ReferenceID(_RecRef);
        _BaseOrderLine.Set_Status('0');
        _BaseOrderLine.Set_Attachment();
        _BaseOrderLine.Set_ItemImageID();

    end;

    local procedure SalesShipmentHeaderExists(_SalesHeader: Record "Sales Header"): Boolean
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
    begin
        SalesShipmentHeader.SetRange("Order No.", _SalesHeader."No.");
        SalesShipmentHeader.SetRange("MOB MessageId", _SalesHeader."MOB Posting MessageId");
        exit(not SalesShipmentHeader.IsEmpty());
    end;

    local procedure TransferShipmentHeaderExists(_TransferHeader: Record "Transfer Header"): Boolean
    var
        TransferShipmentHeader: Record "Transfer Shipment Header";
    begin
        TransferShipmentHeader.SetRange("Transfer Order No.", _TransferHeader."No.");
        TransferShipmentHeader.SetRange("MOB MessageId", _TransferHeader."MOB Posting MessageId");
        exit(not TransferShipmentHeader.IsEmpty());
    end;

    local procedure ReturnShptHeaderExists(_PurchHeader: Record "Purchase Header"): Boolean
    var
        ReturnShptHeader: Record "Return Shipment Header";
    begin
        ReturnShptHeader.SetRange("Return Order No.", _PurchHeader."No.");
        ReturnShptHeader.SetRange("MOB MessageId", _PurchHeader."MOB Posting MessageId");
        exit(not ReturnShptHeader.IsEmpty());
    end;

    //
    // ------- IntegrationEvents: GetPickOrders -------
    //
    // OnSetFilterWarehouseActivity           from  'GetPickOrders'
    // OnSetFilterPurchaseReturnOrder         from  'GetPickOrders'
    // OnSetFilterTransferOrder               from  'GetPickOrders'
    // OnSetFilterSalesOrder                  from  'GetPickOrders'

    // OnIncludeWarehouseActivityHeader       from  MobBaseDocHandler.CopyFilteredWhseActivityHeadersToTempRecord()
    // OnIncludeSalesHeader                   from  MobBaseDocHandler.CopyFilteredSalesHeadersToTempRecord()
    // OnIncludeTransferHeader                from  MobBaseDocHandler.CopyFilteredTransferHeadersToTempRecord()
    // OnIncludePurchaseReturnHeader          from  MobBaseDocHandler.CopyFilteredPurchaseHeadersToTempRecord()

    // OnAfterSetFromWarehouseActivityHeader  from  'GetPickOrders'.GetOrders()."MOBWMSActivity.GetOrders"().CreateWhseActHeaderResponse().SetFromWhseAcitivtHeader()
    // OnAfterSetFromSalesHeader              from  'GetPickOrders'.GetOrders().GetPurchaseOrders().CreatePurchHeaderResponse().SetFromPurchHeader()
    // OnAfterSetFromTransferHeader           from  'GetPickOrders'.GetOrders().GetTransferOrders().CreateTransferHeaderResponse().SetFromTransferHeader()
    // OnAfterSetFromPurchaseReturnHeader     from  'GetPickOrders'.GetOrders().GetSalesReturnOrders().CreateSalesReturnHeaderResp().SetFromSalesReturnHeader()
    // OnAfterSetFromAnyHeader                from  'GetPickOrders'.GetOrders().[...].SetFromXXXHeader()

    // OnAfterSetCurrentKey                   from  'GetPickOrders'.AddBaseOrderElements() and MOBWMSActivity.AddBaseOrderElements()

    [IntegrationEvent(false, false)]
    internal procedure OnGetPickOrders_OnSetFilterWarehouseActivity(_HeaderFilter: Record "MOB NS Request Element"; var _WhseActHeader: Record "Warehouse Activity Header"; var _WhseActLine: Record "Warehouse Activity Line"; var _IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetPickOrders_OnSetFilterPurchaseReturnOrder(_HeaderFilter: Record "MOB NS Request Element"; var _PurchReturnHeader: Record "Purchase Header"; var _PurchReturnLine: Record "Purchase Line"; var _IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetPickOrders_OnSetFilterTransferOrder(_HeaderFilter: Record "MOB NS Request Element"; var _TransferHeader: Record "Transfer Header"; var _TransferLine: Record "Transfer Line"; var _IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetPickOrders_OnSetFilterSalesOrder(_HeaderFilter: Record "MOB NS Request Element"; var _SalesHeader: Record "Sales Header"; var _SalesLine: Record "Sales Line"; var _IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnGetPickOrders_OnIncludeWarehouseActivityHeader(_WhseActHeader: Record "Warehouse Activity Header"; var _HeaderFilters: Record "MOB NS Request Element"; var _IncludeInOrderList: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnGetPickOrders_OnIncludeSalesHeader(_SalesHeader: Record "Sales Header"; var _HeaderFilters: Record "MOB NS Request Element"; var _IncludeInOrderList: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnGetPickOrders_OnIncludeTransferHeader(_TransferHeader: Record "Transfer Header"; var _HeaderFilters: Record "MOB NS Request Element"; var _IncludeInOrderList: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnGetPickOrders_OnIncludePurchaseReturnHeader(_PurchReturnHeader: Record "Purchase Header"; var _HeaderFilters: Record "MOB NS Request Element"; var _IncludeInOrderList: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnGetPickOrders_OnAfterSetFromWarehouseActivityHeader(_WhseActHeader: Record "Warehouse Activity Header"; var _BaseOrderElement: Record "MOB NS BaseDataModel Element")
    begin
        // Called from MOB Activity for activity types Pick and Invt.Pick
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetPickOrders_OnAfterSetFromSalesHeader(_SalesHeader: Record "Sales Header"; var _BaseOrderElement: Record "MOB NS BaseDataModel Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetPickOrders_OnAfterSetFromTransferHeader(_TransferHeader: Record "Transfer Header"; var _BaseOrderElement: Record "MOB NS BaseDataModel Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetPickOrders_OnAfterSetFromPurchaseReturnHeader(_PurchReturnHeader: Record "Purchase Header"; var _BaseOrderElement: Record "MOB NS BaseDataModel Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnGetPickOrders_OnAfterSetFromAnyHeader(_RecRef: RecordRef; var _BaseOrderElement: Record "MOB NS BaseDataModel Element")
    begin
        // Called from current codeunit but also also from MOB Activity for activity types Pick and Invt.Pick
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetPickOrders_OnAfterSetCurrentKey(var _BaseOrderElementView: Record "MOB NS BaseDataModel Element")
    begin
        // Called from current codeunit but also also from MOB Activity for activity types Pick and Invt.Pick
    end;

    //
    // ------- IntegrationEvents: GetPickOrderLines -------
    //
    // OnSetFilterWarehouseActivityLine         from ' GetPickOrderLines'
    // OnSetFilterSalesLine                     from ' GetPickOrderLines'
    // OnSetFilterTransferLine                  from ' GetPickOrderLines'
    // OnSetFilterPurchaseReturnLine            from ' GetPickOrderLines'

    // OnIncludeWarehouseActivityLine           from  'GetPickOrderLines'.GetOrderLines()."MOBWMSActivity.CreateWhseActLinesResponse"()
    // OnIncludeSalesLine                       from  'GetPickOrderLines'.GetOrderLines().CreateSalesLinesResponse()
    // OnIncludeTransferLine                    from  'GetPickOrderLines'.GetOrderLines().CreateTransferLinesResponse()
    // OnIncludePurchaseReturnLine              from  'GetPickOrderLines'.GetOrderLines().CreatePurchaseReturnLinesResp()

    // OnAfterSetFromWarehouseActivityLine      from  'GetPickOrderLines'.GetOrderLines()."MOBWMSActivity.CreateWhseActLinesResponse"().SetFromWhseActiLine()
    // OnAfterSetFromSalesLine                  from  'GetPickOrderLines'.GetOrderLines().CreateSalesLinesResponse().SetFromSalesine()
    // OnAfterSetFromTransferLine               from  'GetPickOrderLines'.GetOrderLines().CreateTransferLinesResponse().CreateTransferLine().SetFromTransferLine()
    // OnAfterSetFromPurchaseReturnLine         from  'GetPickOrderLines'.GetOrderLines().CreatePurchReturnLinesResponse().SetFromPurchReturnLine()
    // OnAfterSetFromAnyLine                    from  'GetPIckOrderLines'.GetOrderLines().[...].SetFromXXXLine()

    // OnAfterSetCurrentKey                     from  'GetPickOrderLines'.AddBaseOrderLineElements() and MOBWMSActivity.AddBaseOrderLineElements()

    [IntegrationEvent(false, false)]
    internal procedure OnGetPickOrderLines_OnSetFilterWarehouseActivityLine(var _WhseActLineTake: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetPickOrderLines_OnSetFilterPurchaseReturnLine(var _PurchReturnLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetPickOrderLines_OnSetFilterTransferLine(var _TransferLine: Record "Transfer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetPickOrderLines_OnSetFilterSalesLine(var _SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnGetPickOrderLines_OnIncludeWarehouseActivityLine(var _WhseActLineTake: Record "Warehouse Activity Line"; var _IncludeInOrderLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetPickOrderLines_OnIncludeSalesLine(_SalesLine: Record "Sales Line"; var _IncludeInOrderLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetPickOrderLines_OnIncludeTransferLine(_TransferLine: Record "Transfer Line"; var _IncludeInOrderLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetPickOrderLines_OnIncludePurchaseReturnLine(_PurchReturnLine: Record "Purchase Line"; var _IncludeInOrderLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnGetPickOrderLines_OnAfterSetFromWarehouseActivityLine(_WhseActLineTake: Record "Warehouse Activity Line"; var _BaseOrderLineElement: Record "MOB NS BaseDataModel Element")
    begin
        // Called from MOB Activity for activity types Pick and Invt.Pick
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetPickOrderLines_OnAfterSetFromSalesLine(_SalesLine: Record "Sales Line"; var _BaseOrderLineElement: Record "MOB NS BaseDataModel Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetPickOrderLines_OnAfterSetFromTransferLine(_TransferLine: Record "Transfer Line"; var _BaseOrderLineElement: Record "MOB NS BaseDataModel Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetPickOrderLines_OnAfterSetFromPurchaseReturnLine(_PurchReturnLine: Record "Purchase Line"; var _BaseOrderLineElement: Record "MOB NS BaseDataModel Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnGetPickOrderLines_OnAfterSetFromAnyLine(_RecRef: RecordRef; var _BaseOrderLineElement: Record "MOB NS BaseDataModel Element")
    begin
        // Called from current codeunit but also also from MOB Activity for activity types Pick and Invt.Pick
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnGetPickOrderLines_OnAfterSetCurrentKey(var _BaseOrderLineElementView: Record "MOB NS BaseDataModel Element")
    begin
        // Called from current codeunit but also also from MOB Activity for activity types Pick and Invt.Pick
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetPickOrderLines_OnAddStepsToAnyHeader(_RecRef: RecordRef; var _StepsElement: Record "MOB Steps Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetPickOrderLines_OnAfterAddStepToAnyHeader(_RecRef: RecordRef; var _StepsElement: Record "MOB Steps Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnGetPickOrderLines_OnAddStepsToAnyLine(_RecRef: RecordRef; var _BaseOrderLineElement: Record "MOB NS BaseDataModel Element"; var _Steps: Record "MOB Steps Element")
    begin
    end;

    //
    // ------- IntegrationEvents: PostPickOrder -------
    //

    [IntegrationEvent(false, false)]
    internal procedure OnPostPickOrder_OnBeforeHandleRegistrationForWarehouseActivityLine(var _Registration: Record "MOB WMS Registration"; var _WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnPostPickOrder_OnHandleRegistrationForWarehouseActivityLine(var _Registration: Record "MOB WMS Registration"; var _WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostPickOrder_OnHandleRegistrationForSalesLine(var _Registration: Record "MOB WMS Registration"; var _SalesLine: Record "Sales Line"; var _NewReservationEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostPickOrder_OnHandleRegistrationForTransferLine(var _Registration: Record "MOB WMS Registration"; var _TransferLine: Record "Transfer Line"; var _NewReservationEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostPickOrder_OnHandleRegistrationForPurchaseReturnLine(var _Registration: Record "MOB WMS Registration"; var _PurchReturnLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnPostPickOrder_OnAddStepsToWarehouseActivityHeader(var _OrderValues: Record "MOB Common Element"; _WhseActivityHeader: Record "Warehouse Activity Header"; var _StepsElement: Record "MOB Steps Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostPickOrder_OnAddStepsToSalesHeader(var _OrderValues: Record "MOB Common Element"; _SalesHeader: Record "Sales Header"; var _StepsElement: Record "MOB Steps Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostPickOrder_OnAddStepsToTransferHeader(var _OrderValues: Record "MOB Common Element"; _TransferHeader: Record "Transfer Header"; var _StepsElement: Record "MOB Steps Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostPickOrder_OnAddStepsToPurchaseReturnHeader(var _OrderValues: Record "MOB Common Element"; _PurchReturnHeader: Record "Purchase Header"; var _StepsElement: Record "MOB Steps Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnPostPickOrder_OnAddStepsToAnyHeader(var _OrderValues: Record "MOB Common Element"; _RecRef: RecordRef; var _StepsElement: Record "MOB Steps Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnPostPickOrder_OnBeforePostWarehouseActivityOrder(var _OrderValues: Record "MOB Common Element"; var _WhseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnPostPickOrder_OnHandleRegistrationForAnyLine(var _Registration: Record "MOB WMS Registration"; var _RecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostPickOrder_OnBeforePostSalesOrder(var _OrderValues: Record "MOB Common Element"; var _SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostPickOrder_OnBeforePostTransferOrder(var _OrderValues: Record "MOB Common Element"; var _TransferHeader: Record "Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostPickOrder_OnBeforePostPurchaseReturnOrder(var _OrderValues: Record "MOB Common Element"; var _PurchReturnHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnPostPickOrder_OnBeforePostAnyOrder(var _OrderValues: Record "MOB Common Element"; var _RecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnPostPickOrder_OnBeforeRunWhseActivityPost(var _WhseActLinesToPost: Record "Warehouse Activity Line"; var _WhseActPost: Codeunit "Whse.-Activity-Post"; var _IsHandled: Boolean; var _HandledResultMessage: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnPostPickOrder_OnBeforeRunWhseActivityRegister(var _WhseActLinesToPost: Record "Warehouse Activity Line"; var _WhseActRegister: Codeunit "Whse.-Activity-Register"; var _IsHandled: Boolean; var _HandledResultMessage: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnPostPickOrder_OnAfterPostAnyOrder(var _OrderValues: Record "MOB Common Element"; var _RecRef: RecordRef; var _ResultMessage: Text)
    begin
    end;
}
