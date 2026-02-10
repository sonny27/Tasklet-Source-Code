codeunit 81376 "MOB WMS Count"
{
    Access = Public;

    TableNo = "MOB Document Queue";
    Permissions = tabledata "Warehouse Journal Batch" = m;

    trigger OnRun()
    begin
        MobDocQueue := Rec;

        MobSetup.Get();

        case Rec."Document Type" of

            // Order headers
            'GetCountOrders':
                GetOrders();

            // Order lines
            'GetCountOrderLines':
                GetOrderLines();

            // Posting
            'PostCountOrder':
                PostOrder();

            else
                Error(MobWmsLanguage.GetMessage('NO_DOC_HANDLER'), Rec."Document Type");
        end;

        // Store the result in the queue and update the status
        MobToolbox.UpdateResult(Rec, XmlResponseDoc);
    end;

    var
        MobSetup: Record "MOB Setup";
        MobDocQueue: Record "MOB Document Queue";
        MobSessionData: Codeunit "MOB SessionData";
        MobItemReferenceMgt: Codeunit "MOB Item Reference Mgt.";
        MobRequestMgt: Codeunit "MOB NS Request Management";
        MobXmlMgt: Codeunit "MOB XML Management";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        MobBaseDocHandler: Codeunit "MOB WMS Base Document Handler";
        MobToolbox: Codeunit "MOB Toolbox";
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
        MobItemJnlLineReserve: Codeunit "MOB Item Jnl. Line-Reserve";
        XmlResponseDoc: XmlDocument;
        INV_JNL_PREFIX_Txt: Label 'I-', Locked = true;
        WHSE_INV_JNL_PREFIX_Txt: Label 'W-', Locked = true;

    local procedure GetOrders()
    var
        TempHeaderElement: Record "MOB NS BaseDataModel Element" temporary;
        XmlRequestDoc: XmlDocument;
        OrdersXmlResponseData: XmlNode;
    begin
        // Process:
        // 1. Filter and sort the count orders for this particular user
        // 2. Save the result in XML and return it to the mobile device

        // The mobile solution is integrated with both the "inventory journal" and the "warehouse inventory journal"
        // Both journals are transferred to the mobile devices, but they are prefixed with "I-" and "W-" to tell them apart
        // (the journals can have the same names)

        // Load the request from the queue
        MobDocQueue.LoadXMLRequestDoc(XmlRequestDoc);

        // Initialize the response document for order data
        MobToolbox.InitializeResponseDoc(XmlResponseDoc, OrdersXmlResponseData);

        // First we get the inventory journals        

        // Create the response for the mobile device
        PhysCreateOrderResponse(XmlRequestDoc, TempHeaderElement);

        // Then we get the warehouse inventory journals        

        // Create the response for the mobile device
        CreateOrderResponse(XmlRequestDoc, TempHeaderElement);

        // Add collected buffer values to new <Orders> nodes
        AddBaseOrderElements(OrdersXmlResponseData, TempHeaderElement);
    end;

    local procedure CreateOrderResponse(var _XmlRequestDoc: XmlDocument; var _BaseOrderElement: Record "MOB NS BaseDataModel Element")
    var
        WhseJnlBatch: Record "Warehouse Journal Batch";
        WhseJnlLine: Record "Warehouse Journal Line";
        TempWhseJnlBatch: Record "Warehouse Journal Batch" temporary;
        TempHeaderFilter: Record "MOB NS Request Element" temporary;
        MobScannedValueMgt: Codeunit "MOB ScannedValue Mgt.";
        IsHandled: Boolean;
        ScannedValue: Text;
    begin
        /// <summary>
        /// Loop through the warehouse phys. invt. journals and add the information that should be available
        /// on the mobile device to the XML. The only elements that MUST be present in the XML are "BackendID", "Status" and "Sorting".
        /// Other values can be added freely and used in Mobile WMS by referencing the element name from the XML.
        /// </summary>

        // Filter the WhseJnlBatch table to only show the warehouse inventory journals        
        FilterWhseJnlBatch(WhseJnlBatch, MobDocQueue."Mobile User ID");

        // XML filter data into Temporary table
        MobRequestMgt.SaveHeaderFilters(_XmlRequestDoc, TempHeaderFilter);

        if TempHeaderFilter.FindSet() then
            repeat
                //
                // Event to allow for handling (custom) filters
                //
                IsHandled := false;
                OnGetCountOrders_OnSetFilterWarehouseJournalBatch(TempHeaderFilter, WhseJnlBatch, WhseJnlLine, IsHandled);

                if not IsHandled then
                    case TempHeaderFilter.Name of

                        'ScannedValue':
                            ScannedValue := TempHeaderFilter."Value";   // Used in search for Document No. or Item/Variant later

                    end;

            until TempHeaderFilter.Next() = 0;

        // Run event once more with Empty "Header filter" to allow for additional filtering directly on the records, NOT related to specific Header filter
        IsHandled := false;
        TempHeaderFilter.ClearFields();
        OnGetCountOrders_OnSetFilterWarehouseJournalBatch(TempHeaderFilter, WhseJnlBatch, WhseJnlLine, IsHandled);

        // Filter: BatchName or Item/Variant (match for scanned batch name takes precedence over other filters)
        if ScannedValue <> '' then
            MobScannedValueMgt.SetFilterForWhseJnl(WhseJnlBatch, WhseJnlLine, ScannedValue);

        // Insert orders into temp rec
        MobBaseDocHandler.CopyFilteredWhseJnlBatchToTempRecord(WhseJnlBatch, WhseJnlLine, TempHeaderFilter, TempWhseJnlBatch);

        // Respond with resulting orders
        CreateWhseJnlBatchResponse(TempWhseJnlBatch, _BaseOrderElement);
    end;

    local procedure CreateWhseJnlBatchResponse(var _WhseJnlBatch: Record "Warehouse Journal Batch"; var _BaseOrderElement: Record "MOB NS BaseDataModel Element")
    begin
        if _WhseJnlBatch.FindSet() then
            repeat
                _BaseOrderElement.Create();
                SetFromWarehouseJournalBatch(_WhseJnlBatch, _BaseOrderElement);
                _BaseOrderElement.Save();
            until _WhseJnlBatch.Next() = 0;
    end;

    local procedure GetOrderLines()
    var
        XmlRequestDoc: XmlDocument;
        XmlBackendIDNode: XmlNode;
        BackendID: Code[40];
        XmlRequestNode: XmlNode;
        XmlRequestDataNode: XmlNode;
        Prefix: Text[2];
        BatchName: Code[10];
        BatchLocationCode: Code[10];
    begin
        // The Request Document looks like this:
        //  <request name="GetReceiveOrderLines"
        //           created="2009-01-20T22:36:34-08:00"
        //           xmlns="http://schemas.microsoft.com/Dynamics/Mobile/2007/04>
        //    <requestData name="GetReceiveOrderLines">
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

        // Extract prefix that determines which type of journal it is
        Prefix := CopyStr(BackendID, 1, 2);

        if Prefix = INV_JNL_PREFIX_Txt then
            // Create the item journal response for the mobile device
            PhysCreateOrderLinesResponse(BackendID)
        else begin
            // Create the warehouse journal response for the mobile device
            MobWmsToolbox.GetWhseJnlBatchNameAndLocationCodeFromBackendID(BackendID, BatchName, BatchLocationCode);
            CreateOrderLinesResponse(BackendID, BatchName, BatchLocationCode);
        end;
    end;

    local procedure CreateOrderLinesResponse(_BackendID: Code[40]; _BatchName: Code[10]; _BatchLocationCode: Code[10])
    var
        WhseJnlBatch: Record "Warehouse Journal Batch";
        WhseJnlLine: Record "Warehouse Journal Line";
        TempBaseOrderLineElement: Record "MOB NS BaseDataModel Element" temporary;
        RecRef: RecordRef;
        XmlResponseData: XmlNode;
        IncludeInOrderLines: Boolean;
    begin
        // Description:
        // Get the order lines for the requested order.
        // Sort the lines.
        // Create the response XML

        // Initialize the response document for order line data
        MobToolbox.InitializeOrderLineDataRespDoc(XmlResponseDoc, XmlResponseData);

        // Filter the lines for this particular order
        case MobSetup."Sort Order Count" of
            MobSetup."Sort Order Count"::Item:
                WhseJnlLine.SetCurrentKey("Item No.", "Location Code", "Entry Type", "From Bin Type Code", "Variant Code", "Unit of Measure Code");
            MobSetup."Sort Order Count"::Bin:
                WhseJnlLine.SetCurrentKey("Location Code", "Bin Code", "Item No.", "Variant Code");
        end;
        WhseJnlLine.SetRange("Journal Template Name", MobSetup."Whse Inventory Jnl Template");

        // The OrderNo contains the 2 character prefix. Remove it when searching for the journal lines
        WhseJnlLine.SetRange("Journal Batch Name", _BatchName);
        WhseJnlLine.SetRange("Location Code", _BatchLocationCode);
        WhseJnlLine.SetRange(MOBRegisteredOnMobile, false);

        // Event to expost Lines for filtering before Response
        OnGetCountOrderLines_OnSetFilterWarehouseJournalLine(WhseJnlLine);

        // Insert the values from the header in the XML
        if WhseJnlLine.FindSet() then begin

            // Add collectorSteps to be displayed on posting
            WhseJnlBatch.Get(WhseJnlLine."Journal Template Name", WhseJnlLine."Journal Batch Name", WhseJnlLine."Location Code");
            RecRef.GetTable(WhseJnlBatch);
            AddStepsToAnyHeader(RecRef, XmlResponseDoc, XmlResponseData);

            repeat
                // Verify addtional conditions from eventsubscribers
                IncludeInOrderLines := true;
                OnGetCountOrderLines_OnIncludeWarehouseJournalLine(WhseJnlLine, IncludeInOrderLines);

                if IncludeInOrderLines then begin
                    // Add the data to the order line element
                    TempBaseOrderLineElement.Create();
                    SetFromWarehouseJournalLine(WhseJnlLine, TempBaseOrderLineElement, _BackendID);
                    TempBaseOrderLineElement.Save();
                end;
            until WhseJnlLine.Next() = 0;
        end;

        AddBaseOrderLineElements(XmlResponseData, TempBaseOrderLineElement);
    end;

    local procedure AddStepsToAnyHeader(_RecRef: RecordRef; _XmlResponseDoc: XmlDocument; var _XmlResponseData: XmlNode)
    var
        TempSteps: Record "MOB Steps Element" temporary;
        XmlSteps: XmlNode;
    begin
        TempSteps.SetMustCallCreateNext(true);
        OnGetCountOrderLines_OnAddStepsToAnyHeader(_RecRef, TempSteps);

        if not TempSteps.IsEmpty() then begin
            // Adds Collector Configuration with <steps> {<add ... />} <steps/>
            MobToolbox.AddCollectorConfiguration(_XmlResponseDoc, _XmlResponseData, XmlSteps);
            MobXmlMgt.AddStepsaddElements(XmlSteps, TempSteps);
        end;
    end;

    local procedure PostOrder()
    var
        TempOrderValues: Record "MOB Common Element" temporary;
        MobWmsRegistration: Record "MOB WMS Registration";
        XmlRequestDoc: XmlDocument;
        PrefixedOrderID: Code[20];
        Prefix: Text[2];
    begin
        // Disable the locktimeout to prevent timeout messages on the mobile device
        LockTimeout(false);

        // Load the request document from the document queue
        MobDocQueue.LoadXMLRequestDoc(XmlRequestDoc);
        MobRequestMgt.InitCommonFromXmlOrderNode(XmlRequestDoc, TempOrderValues);

        // Turn on commit protection to prevent unintentional committing data
        MobDocQueue.Consistent(false);

        // Save the registrations from the XML in the Mobile WMS Registration table
        // When posting planned Count the retured OrderID is still prefixed by I-/W- to be able to separate Item Journal vs. Whse. Journal posting
        PrefixedOrderID := MobWmsToolbox.SaveRegistrationData(MobDocQueue.MessageIDAsGuid(), XmlRequestDoc, MobWmsRegistration.Type::Count);

        // The OrderID contains the prefix that determines the journal type
        Prefix := CopyStr(PrefixedOrderID, 1, 2);

        if Prefix = INV_JNL_PREFIX_Txt then
            PostOrderToItemJnl(PrefixedOrderID, TempOrderValues)
        else
            PostOrderToWhseJnl(PrefixedOrderID, TempOrderValues);
    end;

    local procedure PostOrderToItemJnl(_PrefixedOrderID: Code[20]; var _OrderValues: Record "MOB Common Element")
    var
        Location: Record Location;
        BinContent: Record "Bin Content";
        ItemJnlBatch: Record "Item Journal Batch";
        ItemJnlLine: Record "Item Journal Line";
        SplitItemJnlLine: Record "Item Journal Line";
        TempReservationEntryLog: Record "Reservation Entry" temporary;
        TempReservationEntry: Record "Reservation Entry" temporary;
        ItemLedgEntry: Record "Item Ledger Entry";
        MobWmsRegistration: Record "MOB WMS Registration";
        TempMobWmsRegistration: Record "MOB WMS Registration" temporary;
        TempSteps: Record "MOB Steps Element" temporary;
        MobTryEvent: Codeunit "MOB Try Event";
        MobSyncItemTracking: Codeunit "MOB Sync. Item Tracking";
        BatchRecRef: RecordRef;
        LineRecRef: RecordRef;
        QtyToHandle: Decimal;
        QtyOnHand: Decimal;
        ResultMessage: Text;
        MultipleRegistrations: Boolean;
    begin
        // Lock the tables to work on
        ItemJnlBatch.LockTable();
        ItemJnlLine.LockTable();
        MobWmsRegistration.LockTable();

        // Get the order lines
        // Loop through them and set the physical inventory to the registered qty
        ItemJnlLine.SetRange("Journal Template Name", MobSetup."Inventory Jnl Template");
        // Remove the prefix on the filter
        ItemJnlLine.SetRange("Journal Batch Name", CopyStr(_PrefixedOrderID, 3));

        // Make sure that the order still exists
        if ItemJnlLine.IsEmpty() then
            Error(MobWmsLanguage.GetMessage('UNKNOWN_ORDER'), CopyStr(_PrefixedOrderID, 3));

        ItemJnlLine.FindSet();

        // Field "MOB Posting MessageId" do not exists for journal batches and is not set (since no posting events are fired that could use the value)

        // OnAddStepsTo IntegrationEvents
        BatchRecRef.GetTable(ItemJnlBatch);
        OnPostCountOrder_OnAddStepsToItemJournalBatch(_OrderValues, ItemJnlBatch, TempSteps);
        OnPostCountOrder_OnAddStepsToAnyBatch(_OrderValues, BatchRecRef, TempSteps);
        if not TempSteps.IsEmpty() then begin
            MobSessionData.SetRegistrationTypeTracking('OnAddStepsTo');
            MobWmsToolbox.DeleteRegistrationData(MobDocQueue.MessageIDAsGuid());
            MobToolbox.CreateResponseWithSteps(XmlResponseDoc, TempSteps);
            MobDocQueue.Consistent(true);
            exit;
        end;

        // OnBeforePost IntegrationEvents
        ItemJnlBatch.Get(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name");
        OnPostCountOrder_OnBeforePostItemJournalBatch(_OrderValues, ItemJnlBatch);
        BatchRecRef.GetTable(ItemJnlBatch);
        OnPostCountOrder_OnBeforePostAnyBatch(_OrderValues, BatchRecRef);
        BatchRecRef.SetTable(ItemJnlBatch);
        ItemJnlBatch.Modify();

        // Save the original reservation entrie in case we need to revert (if the posting fails)
        MobSyncItemTracking.SaveOriginalReservationEntriesForItemJnlLines(ItemJnlLine, TempReservationEntryLog);
        ItemJnlLine.FindSet();

        // Iterate ItemJnlLines
        repeat

            // Try to find the quantity in the registrations
            // Try to find the registrations
            QtyToHandle := 0;
            MobWmsRegistration.SetRange("Posting MessageId", MobDocQueue.MessageIDAsGuid());
            MobWmsRegistration.SetRange(Type, MobWmsRegistration.Type::Count);
            // The registrations are stored with the prefix so here we use the OrderID variable
            MobWmsRegistration.SetRange("Order No.", _PrefixedOrderID);
            MobWmsRegistration.SetRange("Line No.", ItemJnlLine."Line No.");
            MobWmsRegistration.SetRange(Handled, false);

            MultipleRegistrations := MobWmsRegistration.Count() > 1;

            TempMobWmsRegistration.Reset();
            TempMobWmsRegistration.DeleteAll();

            if MobWmsRegistration.FindFirst() then begin
                repeat
                    TempMobWmsRegistration.Reset();
                    TempMobWmsRegistration.SetRange(Type, MobWmsRegistration.Type);
                    TempMobWmsRegistration.SetRange("Order No.", MobWmsRegistration."Order No.");
                    TempMobWmsRegistration.SetRange("Line No.", MobWmsRegistration."Line No.");
                    TempMobWmsRegistration.SetRange(UnitOfMeasure, MobWmsRegistration.UnitOfMeasure);
                    TempMobWmsRegistration.SetTrackingFilterFromMobWmsRegistration(MobWmsRegistration);
                    if TempMobWmsRegistration.FindFirst() then begin
                        TempMobWmsRegistration.Quantity += MobWmsRegistration.Quantity;
                        TempMobWmsRegistration.Modify();
                    end else begin
                        TempMobWmsRegistration.Init();
                        TempMobWmsRegistration.TransferFields(MobWmsRegistration);
                        TempMobWmsRegistration.Insert();
                    end;

                    QtyToHandle += MobWmsRegistration.Quantity;

                    MobWmsToolbox.SaveRegistrationDataFromSource(ItemJnlLine."Location Code", ItemJnlLine."Item No.", ItemJnlLine."Variant Code", MobWmsRegistration);

                    // OnHandle IntegrationEvents
                    OnPostCountOrder_OnHandleRegistrationForItemJournalLine(MobWmsRegistration, ItemJnlLine);
                    LineRecRef.GetTable(ItemJnlLine);
                    OnPostCountOrder_OnHandleRegistrationForAnyLine(MobWmsRegistration, LineRecRef);
                    LineRecRef.SetTable(ItemJnlLine);
                    ItemJnlLine.Modify();

                    // Remember that the registration was handled
                    MobWmsRegistration.Validate(Handled, true);
                    MobWmsRegistration.Modify();

                until MobWmsRegistration.Next() = 0;

                ItemJnlLine.Find('=');
                ItemJnlLine.Validate("Qty. (Phys. Inventory)", QtyToHandle);
                ItemJnlLine.Validate(MOBRegisteredOnMobile, true);
                ItemJnlLine.Modify();

                // If item tracking is needed a reservation entry must be created
                // Unless if we are handling an inventory put-away generated from a transfer order
                if TempMobWmsRegistration.TrackingExists() then begin

                    TempMobWmsRegistration.Reset();
                    TempMobWmsRegistration.SetRange(Type, MobWmsRegistration.Type);
                    TempMobWmsRegistration.SetRange("Order No.", MobWmsRegistration."Order No.");
                    TempMobWmsRegistration.SetRange("Line No.", MobWmsRegistration."Line No.");
                    TempMobWmsRegistration.SetRange(UnitOfMeasure, MobWmsRegistration.UnitOfMeasure);

                    // Item tracking needed -> create reservation entries
                    if TempMobWmsRegistration.FindFirst() then
                        repeat
                            QtyOnHand := 0;

                            if not Location.Get(ItemJnlLine."Location Code") then
                                Clear(Location);

                            // Set filters equal for all MOB WMS Registration Records
                            if Location."Bin Mandatory" then begin
                                BinContent.Reset();
                                BinContent.SetRange("Location Code", ItemJnlLine."Location Code");
                                BinContent.SetRange("Bin Code", ItemJnlLine."Bin Code");
                                BinContent.SetRange("Item No.", ItemJnlLine."Item No.");
                                BinContent.SetRange("Variant Code", ItemJnlLine."Variant Code");
                                BinContent.SetRange("Unit of Measure Code", ItemJnlLine."Unit of Measure Code");
                                BinContent.MobSetTrackingFilterFromMobWmsRegistrationIfNotBlank(TempMobWmsRegistration);
                                BinContent.SetAutoCalcFields(Quantity);
                                if BinContent.FindFirst() then
                                    QtyOnHand := BinContent.Quantity;
                            end else begin
                                ItemLedgEntry.Reset();
                                ItemLedgEntry.SetCurrentKey("Item No.", Open, "Variant Code", "Location Code", "Item Tracking", "Lot No.", "Serial No.");
                                ItemLedgEntry.SetRange("Item No.", ItemJnlLine."Item No.");
                                ItemLedgEntry.SetRange(Open, true);
                                ItemLedgEntry.SetRange("Variant Code", ItemJnlLine."Variant Code");
                                ItemLedgEntry.SetRange("Location Code", ItemJnlLine."Location Code");
                                ItemLedgEntry.SetRange("Unit of Measure Code", ItemJnlLine."Unit of Measure Code");
                                ItemLedgEntry.MobSetTrackingFilterFromMobWmsRegistrationIfNotBlank(TempMobWmsRegistration);
                                ItemLedgEntry.CalcSums("Remaining Quantity");
                                QtyOnHand := ItemLedgEntry."Remaining Quantity";
                            end;

                            if QtyOnHand <> TempMobWmsRegistration.Quantity then begin

                                if ItemJnlLine."Entry Type" = ItemJnlLine."Entry Type"::"Positive Adjmt." then
                                    QtyToHandle := TempMobWmsRegistration.Quantity - QtyOnHand
                                else
                                    QtyToHandle := QtyOnHand - TempMobWmsRegistration.Quantity;

                                // Negative Quantity isn't allowed on an Item Tracking Line. Item Jnl. Line needs to be split to be able to create Item Tracking Correctly.
                                // If an entirely new quantity is found on inventory, a new line to cover this should be created to still be able to handle existing inventory
                                // If there are multipleRegistrations present we also always need to split the line.
                                // SplitItemJnlLine is a new journal line for this current MobRegistration
                                // Unlike WhseActivityLine.SplitLine() the qty. currently being posted is at the SplitLine, and not-yet-posted qty. remains at the original ItemJnlLine
                                // This is to avoid MobRegistrations having to be updated to point to a new Line No. everytime a line splits
                                if (QtyToHandle < 0) or (QtyOnHand = 0) or MultipleRegistrations then begin
                                    SplitItemJnlLine.Init();
                                    SplitItemJnlLine.TransferFields(ItemJnlLine);
                                    repeat
                                        SplitItemJnlLine."Line No." += 10;
                                    until SplitItemJnlLine.Insert(true);
                                    SplitItemJnlLine."Qty. (Calculated)" := QtyOnHand;
                                    SplitItemJnlLine."Qty. (Phys. Inventory)" := TempMobWmsRegistration.Quantity;
                                    SplitItemJnlLine.Validate("Qty. (Phys. Inventory)");
                                    SplitItemJnlLine.Modify(true);
                                    // Deduct from original line
                                    ItemJnlLine."Qty. (Calculated)" := ItemJnlLine."Qty. (Calculated)" - QtyOnHand;
                                    ItemJnlLine."Qty. (Phys. Inventory)" := ItemJnlLine."Qty. (Phys. Inventory)" - TempMobWmsRegistration.Quantity;
                                    ItemJnlLine.Validate("Qty. (Phys. Inventory)");
                                    if (ItemJnlLine."Qty. (Calculated)" = 0) and (ItemJnlLine."Qty. (Phys. Inventory)" = 0) then
                                        ItemJnlLine.Delete(true)
                                    else
                                        ItemJnlLine.Modify(true);

                                    // Synchronize Item Tracking to Source Document
                                    MobSyncItemTracking.CreateTempReservEntryForItemJnlLineFromMobWmsRegistration(SplitItemJnlLine, TempMobWmsRegistration, TempReservationEntry, CalcQtyItemJnlLine(SplitItemJnlLine, Abs(QtyToHandle)));

                                end else

                                    // Synchronize Item Tracking to Source Document
                                    MobSyncItemTracking.CreateTempReservEntryForItemJnlLineFromMobWmsRegistration(ItemJnlLine, TempMobWmsRegistration, TempReservationEntry, CalcQtyItemJnlLine(ItemJnlLine, Abs(QtyToHandle)));

                            end;

                        until TempMobWmsRegistration.Next() = 0;

                    // Check if there is unhandled Inventory
                    CheckForUnhandledInventory(ItemJnlLine, TempMobWmsRegistration, Location, TempReservationEntry);
                end;
            end;
        until ItemJnlLine.Next() = 0;

        // Registrations related to deleted journal lines must be marked as handled
        MobWmsRegistration.SetRange("Line No.");
        MobWmsRegistration.ModifyAll(Handled, true);

        // Turn on commit protection off again
        MobDocQueue.Consistent(true);
        Commit();

        if not MobSyncItemTracking.Run(TempReservationEntry) then begin
            // The created reservation entries might have been committed
            // If the synchronization fails for some reason we need to clean up the created reservation entries
            ResultMessage := GetLastErrorText();
            MobSessionData.SetPreservedLastErrorCallStack();
            MobSyncItemTracking.RevertToOriginalReservationEntriesForItemJnlLines(ItemJnlLine, TempReservationEntryLog);
            Commit();
            MobWmsToolbox.DeleteRegistrationData(MobDocQueue.MessageIDAsGuid());
            Commit();   // Separate commit to prevent error in UpdateIncomingWarehouseShipment from preventing Reservation Entries being rollback
            Error(ResultMessage);
        end;

        // The posting was successful
        ResultMessage := MobWmsLanguage.GetMessage('REG_TRANS_SUCCESS');

        // Event OnAfterPost
        LineRecRef.GetTable(ItemJnlBatch);
        MobTryEvent.RunEventOnPlannedPosting('OnPostCountOrder_OnAfterPostAnyOrder', LineRecRef, _OrderValues, ResultMessage);

        // Create a response inside the <description> element of the document response
        MobToolbox.CreateSimpleResponse(XmlResponseDoc, ResultMessage);

    end;

    local procedure PostOrderToWhseJnl(_PrefixedOrderID: Code[20]; var _OrderValues: Record "MOB Common Element")
    var
        MobWmsRegistration: Record "MOB WMS Registration";
        MobWmsRegistrationFirst: Record "MOB WMS Registration";
        WhseJnlBatch: Record "Warehouse Journal Batch";
        WhseJnlLine: Record "Warehouse Journal Line";
        TempSteps: Record "MOB Steps Element" temporary;
        MobTryEvent: Codeunit "MOB Try Event";
        BatchRecRef: RecordRef;
        LineRecRef: RecordRef;
        WhseJnlBatchName: Code[10];
        WhseJnlBatchLocationCode: Code[10];
        ResultMessage: Text;
        TotalQty: Decimal;
    begin
        // Lock the tables to work on
        WhseJnlLine.LockTable();
        MobWmsRegistration.LockTable();
        MobWmsRegistrationFirst.LockTable();

        // Determine whse journal batch name and batch location code to post against -- assumes all MobRegistrations is for same batch
        MobWmsRegistrationFirst.Reset();
        MobWmsRegistrationFirst.SetCurrentKey("Posting MessageId");
        MobWmsRegistrationFirst.SetRange("Posting MessageId", MobDocQueue.MessageIDAsGuid());
        MobWmsRegistrationFirst.FindFirst();    // Must exist
        MobWmsRegistrationFirst.TestField("Whse. Jnl. Batch Location Code");

        WhseJnlBatchName := CopyStr(_PrefixedOrderID, 3);
        WhseJnlBatchLocationCode := MobWmsRegistrationFirst."Whse. Jnl. Batch Location Code";

        // Get the order lines
        // Loop through them and set the physical inventory to the registered qty
        WhseJnlLine.SetRange("Journal Template Name", MobSetup."Whse Inventory Jnl Template");
        // Do not use the prefix on the filter
        WhseJnlLine.SetRange("Journal Batch Name", WhseJnlBatchName);
        WhseJnlLine.SetRange("Location Code", WhseJnlBatchLocationCode);

        // Make sure that the order still exists
        if WhseJnlLine.Count() = 0 then
            Error(MobWmsLanguage.GetMessage('UNKNOWN_ORDER'), WhseJnlBatchName + ',' + WhseJnlBatchLocationCode);

        WhseJnlLine.FindSet();

        // Field "MOB Posting MessageId" do not exists for journal batches and is not set (since no posting events are fired that could use the value)

        // OnAddStepsTo IntegrationEvents
        BatchRecRef.GetTable(WhseJnlBatch);
        OnPostCountOrder_OnAddStepsToWarehouseJournalBatch(_OrderValues, WhseJnlBatch, TempSteps);
        OnPostCountOrder_OnAddStepsToAnyBatch(_OrderValues, BatchRecRef, TempSteps);
        if not TempSteps.IsEmpty() then begin
            MobSessionData.SetRegistrationTypeTracking('OnAddStepsTo');
            MobWmsToolbox.DeleteRegistrationData(MobDocQueue.MessageIDAsGuid());
            MobToolbox.CreateResponseWithSteps(XmlResponseDoc, TempSteps);
            MobDocQueue.Consistent(true);
            exit;
        end;

        // OnBeforePost IntegrationEvents
        WhseJnlBatch.Get(WhseJnlLine."Journal Template Name", WhseJnlLine."Journal Batch Name", WhseJnlLine."Location Code");
        OnPostCountOrder_OnBeforePostWarehouseJournalBatch(_OrderValues, WhseJnlBatch);
        BatchRecRef.GetTable(WhseJnlBatch);
        OnPostCountOrder_OnBeforePostAnyBatch(_OrderValues, BatchRecRef);
        BatchRecRef.SetTable(WhseJnlBatch);
        WhseJnlBatch.Modify();

        // Iterate WhseJnlLines
        repeat

            // Try to find the quantity in the registrations
            // Try to find the registrations
            MobWmsRegistration.SetRange("Posting MessageId", MobDocQueue.MessageIDAsGuid());
            MobWmsRegistration.SetRange(Type, MobWmsRegistration.Type::Count);
            // The registration is saved with the prefix so here we use the OrderID variable
            MobWmsRegistration.SetRange("Order No.", _PrefixedOrderID);
            MobWmsRegistration.SetRange("Whse. Jnl. Batch Location Code", WhseJnlBatchLocationCode);
            MobWmsRegistration.SetRange("Line No.", WhseJnlLine."Line No.");
            MobWmsRegistration.SetRange(Handled, false);

            if MobWmsRegistration.FindSet() then begin

                TotalQty := 0;

                repeat
                    TotalQty := TotalQty + MobWmsRegistration.Quantity;

                    MobWmsToolbox.SaveRegistrationDataFromSource(WhseJnlLine."Location Code", WhseJnlLine."Item No.", WhseJnlLine."Variant Code", MobWmsRegistration);

                    // OnHandle IntegrationEvents
                    OnPostCountOrder_OnHandleRegistrationForWarehouseJournalLine(MobWmsRegistration, WhseJnlLine);
                    LineRecRef.GetTable(WhseJnlLine);
                    OnPostCountOrder_OnHandleRegistrationForAnyLine(MobWmsRegistration, LineRecRef);
                    LineRecRef.SetTable(WhseJnlLine);
                    WhseJnlLine.Modify();

                    // Remember that the registration was handled
                    MobWmsRegistration.Validate(Handled, true);
                    MobWmsRegistration.Modify();
                until MobWmsRegistration.Next() = 0;

                WhseJnlLine.Validate("Qty. (Phys. Inventory)", TotalQty);
                WhseJnlLine.Validate(MOBRegisteredOnMobile, true);
                WhseJnlLine.Modify();
            end;

        until WhseJnlLine.Next() = 0;

        // Registrations related to deleted journal lines must be marked as handled
        MobWmsRegistration.SetRange("Line No.");
        MobWmsRegistration.ModifyAll(Handled, true);

        // The posting was successful
        ResultMessage := MobWmsLanguage.GetMessage('REG_TRANS_SUCCESS');

        // Turn on commit protection off again
        MobDocQueue.Consistent(true);
        Commit();

        // Event OnAfterPost
        LineRecRef.GetTable(WhseJnlBatch);
        MobTryEvent.RunEventOnPlannedPosting('OnPostCountOrder_OnAfterPostAnyOrder', LineRecRef, _OrderValues, ResultMessage);

        // Create a response inside the <description> element of the document response
        MobToolbox.CreateSimpleResponse(XmlResponseDoc, ResultMessage);

    end;

    local procedure CheckForUnhandledInventory(var _ItemJnlLine: Record "Item Journal Line"; var _TempMobWmsRegistration: Record "MOB WMS Registration"; _Location: Record Location; var _TempReservationEntry: Record "Reservation Entry")
    var
        TempEntrySummary: Record "Entry Summary" temporary;
        BinContent: Record "Bin Content";
        ItemLedgEntry: Record "Item Ledger Entry";
        SplitItemJnlLine: Record "Item Journal Line";
        TempTrackingSpec: Record "Tracking Specification" temporary;
        MobCommonMgt: Codeunit "MOB Common Mgt.";
        MobSyncItemTracking: Codeunit "MOB Sync. Item Tracking";
        ValidateQtyPhysInvOnOrigJnlLine: Boolean;
        QtyOnHand: Decimal;
    begin
        MobWmsToolbox.GetTrackedSummary(TempEntrySummary, _Location, _ItemJnlLine."Bin Code", _ItemJnlLine."Item No.",
                                                    _ItemJnlLine."Variant Code", _ItemJnlLine."Unit of Measure Code", false);

        if TempEntrySummary.FindSet() then begin

            // Set filters equal for all EntrySummary records
            if _Location."Bin Mandatory" then begin
                BinContent.Reset();
                BinContent.SetRange("Location Code", _ItemJnlLine."Location Code");
                BinContent.SetRange("Bin Code", _ItemJnlLine."Bin Code");
                BinContent.SetRange("Item No.", _ItemJnlLine."Item No.");
                BinContent.SetRange("Variant Code", _ItemJnlLine."Variant Code");
                BinContent.SetRange("Unit of Measure Code", _ItemJnlLine."Unit of Measure Code");
            end else begin
                ItemLedgEntry.Reset();
                ItemLedgEntry.SetCurrentKey("Item No.", Open, "Variant Code", "Location Code", "Item Tracking", "Lot No.", "Serial No.");
                ItemLedgEntry.SetRange("Item No.", _ItemJnlLine."Item No.");
                ItemLedgEntry.SetRange(Open, true);
                ItemLedgEntry.SetRange("Variant Code", _ItemJnlLine."Variant Code");
                ItemLedgEntry.SetRange("Location Code", _ItemJnlLine."Location Code");
                ItemLedgEntry.SetRange("Unit of Measure Code", _ItemJnlLine."Unit of Measure Code");
            end;

            // Create Reservation Entries per TempEntrySummary combination (if needed)
            repeat
                QtyOnHand := 0;

                // Calculate Qty. on Hand per Serial No. / Lot No. / Package No.
                if _Location."Bin Mandatory" then begin
                    BinContent.MobSetTrackingFilterFromEntrySummaryIfNotBlank(TempEntrySummary);
                    BinContent.SetAutoCalcFields(Quantity);
                    if BinContent.FindFirst() then
                        QtyOnHand := BinContent.Quantity;
                end else begin
                    ItemLedgEntry.MobSetTrackingFilterFromEntrySummaryIfNotBlank(TempEntrySummary);
                    ItemLedgEntry.CalcSums("Remaining Quantity");
                    QtyOnHand := ItemLedgEntry."Remaining Quantity";
                end;

                if QtyOnHand <> 0 then begin
                    _TempMobWmsRegistration.SetTrackingFilterFromEntrySummary(TempEntrySummary);
                    if _TempMobWmsRegistration.IsEmpty() then begin
                        if _ItemJnlLine."Entry Type" = _ItemJnlLine."Entry Type"::"Positive Adjmt." then begin
                            SplitItemJnlLine.Init();
                            SplitItemJnlLine.TransferFields(_ItemJnlLine);
                            repeat
                                SplitItemJnlLine."Line No." += 10;
                            until SplitItemJnlLine.Insert(true);
                        end else
                            SplitItemJnlLine := _ItemJnlLine;
                        if _ItemJnlLine."Line No." <> SplitItemJnlLine."Line No." then begin
                            SplitItemJnlLine."Qty. (Calculated)" := QtyOnHand;
                            SplitItemJnlLine.Validate("Qty. (Phys. Inventory)", 0);
                            // Deduct from original line                                        
                            _ItemJnlLine."Qty. (Calculated)" := _ItemJnlLine."Qty. (Calculated)" - QtyOnHand;
                            ValidateQtyPhysInvOnOrigJnlLine := true;
                        end;
                        SplitItemJnlLine.Modify(true);

                        Clear(TempTrackingSpec);
                        MobItemJnlLineReserve.InitFromItemJnlLine(TempTrackingSpec, SplitItemJnlLine);
                        MobCommonMgt.CopyTrackingFromEntrySummary(TempTrackingSpec, TempEntrySummary);

                        // Synchronize Item Tracking to Source Document
                        MobSyncItemTracking.CreateTempReservEntryForItemJnlLineFromTrackingSpecWithoutQty(SplitItemJnlLine, false, TempTrackingSpec, _TempReservationEntry, CalcQtyItemJnlLine(SplitItemJnlLine, Abs(QtyOnHand)));

                    end;
                end;
            until TempEntrySummary.Next() = 0;

            // If Qty. has been deducted from Original Item Journal Line, the line has to be recalculated for Quantity to be correctly calculated.
            // Qty. (Phys. Inventory) must first be validated when the entire qty. has been deducted to avoid deleting earlier created Item Tracking.
            if ValidateQtyPhysInvOnOrigJnlLine then begin
                _ItemJnlLine.Validate("Qty. (Phys. Inventory)");
                if (_ItemJnlLine."Qty. (Calculated)" = 0) then
                    _ItemJnlLine.Delete(true)
                else
                    _ItemJnlLine.Modify(true);
            end;
        end;
    end;

    local procedure FilterWhseJnlBatch(var _WhseJnlBatch: Record "Warehouse Journal Batch"; _MobileUserID: Text[65])
    begin
        // 1. Set the key you want the orders to be sorted by (primary key by default)
        // 2. Determine which warehouse employee the mobile user corresponds to and filter on "Assigned User ID"
        //    (if you want to filter the orders)
        _WhseJnlBatch.SetRange(MOBReleasedToMobile, true);
        _WhseJnlBatch.SetRange("Journal Template Name", MobSetup."Whse Inventory Jnl Template");
        _WhseJnlBatch.SetFilter("Location Code", MobWmsToolbox.GetLocationFilter(_MobileUserID));
    end;

    local procedure PhysCreateOrderResponse(var _XmlRequestDoc: XmlDocument; var _BaseOrderElement: Record "MOB NS BaseDataModel Element")
    var
        ItemJnlBatch: Record "Item Journal Batch";
        ItemJnlLine: Record "Item Journal Line";
        TempItemJnlBatch: Record "Item Journal Batch" temporary;
        TempHeaderFilter: Record "MOB NS Request Element" temporary;
        MobScannedValueMgt: Codeunit "MOB ScannedValue Mgt.";
        IsHandled: Boolean;
        ScannedValue: Text;
    begin
        /// <summary>
        /// Loop through the item journal batches and add the information that should be available on the mobile device to the XML.
        /// The only elements that MUST be present in the XML are "BackendID", "Status" and "Sorting".
        /// Other values can be added freely and used in Mobile WMS by referencing the element name from the XML.
        /// </summary>

        // Filter the ItemJnlBatch table to only show the counting journals        
        PhysFilterOrders(ItemJnlBatch);

        // XML filter data into Temporary table
        MobRequestMgt.SaveHeaderFilters(_XmlRequestDoc, TempHeaderFilter);

        if TempHeaderFilter.FindSet() then
            repeat

                //
                // Event to allow for handling (custom) filters
                //
                IsHandled := false;
                OnGetCountOrders_OnSetFilterItemJournalBatch(TempHeaderFilter, ItemJnlBatch, ItemJnlLine, IsHandled);

                if not IsHandled then
                    case TempHeaderFilter.Name of

                        'ScannedValue':
                            ScannedValue := TempHeaderFilter."Value";   // Used in search for Document No. or Item/Variant later

                    end;

            until TempHeaderFilter.Next() = 0;


        // Run event once more with Empty "Header filter" to allow for additional filtering directly on the records, NOT related to specific Header filter
        IsHandled := false;
        TempHeaderFilter.ClearFields();
        OnGetCountOrders_OnSetFilterItemJournalBatch(TempHeaderFilter, ItemJnlBatch, ItemJnlLine, IsHandled);

        // Filter: BatchName or Item/Variant (match for scanned batch name takes precedence over other filters)
        if ScannedValue <> '' then
            MobScannedValueMgt.SetFilterForItemJnl(ItemJnlBatch, ItemJnlLine, ScannedValue);

        // Insert orders into temp rec
        MobBaseDocHandler.CopyFilteredItemJnlBatchToTempRecord(ItemJnlBatch, ItemJnlLine, TempHeaderFilter, TempItemJnlBatch);

        // Respond with resulting orders
        CreateItemJnlBatchResponse(ItemJnlBatch, _BaseOrderElement);
    end;

    local procedure CreateItemJnlBatchResponse(var _ItemJnlBatch: Record "Item Journal Batch"; var _BaseOrderElement: Record "MOB NS BaseDataModel Element")
    begin
        if _ItemJnlBatch.FindSet() then
            repeat
                _BaseOrderElement.Create();
                SetFromItemJournalBatch(_ItemJnlBatch, _BaseOrderElement);
                _BaseOrderElement.Save();
            until _ItemJnlBatch.Next() = 0;
    end;

    local procedure PhysCreateOrderLinesResponse(_BackendID: Code[40])
    var
        ItemJnlBatch: Record "Item Journal Batch";
        ItemJnlLine: Record "Item Journal Line";
        TempLineElement: Record "MOB NS BaseDataModel Element" temporary;
        RecRef: RecordRef;
        XmlResponseData: XmlNode;
        IncludeInOrderLines: Boolean;
    begin
        // Description:
        // Get the order lines for the requested order.
        // Sort the lines.
        // Create the response XML

        // Initialize the response document for order line data
        MobToolbox.InitializeOrderLineDataRespDoc(XmlResponseDoc, XmlResponseData);

        // Filter the lines for this particular order
        case MobSetup."Sort Order Count" of
            MobSetup."Sort Order Count"::Item:
                ItemJnlLine.SetCurrentKey("Item No.", "Posting Date");
            MobSetup."Sort Order Count"::Bin:
                ItemJnlLine.SetCurrentKey("Location Code", "Bin Code", "Item No.", "Variant Code");
        end;
        ItemJnlLine.SetRange("Journal Template Name", MobSetup."Inventory Jnl Template");
        // Do not use the prefix when filtering
        ItemJnlLine.SetRange("Journal Batch Name", CopyStr(_BackendID, 3));
        ItemJnlLine.SetRange(MOBRegisteredOnMobile, false);

        // Event to expost Lines for filtering before Response
        OnGetCountOrderLines_OnSetFilterItemJournalLine(ItemJnlLine);

        // Insert the values from the header in the XML
        if ItemJnlLine.FindSet() then begin

            // Add collectorSteps to be displayed on posting
            ItemJnlBatch.Get(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name");
            RecRef.GetTable(ItemJnlBatch);
            AddStepsToAnyHeader(RecRef, XmlResponseDoc, XmlResponseData);

            repeat
                // Verify addtional conditions from eventsubscribers
                IncludeInOrderLines := true;
                OnGetCountOrderLines_OnIncludeItemJournalLine(ItemJnlLine, IncludeInOrderLines);

                if IncludeInOrderLines then begin
                    // Add the data to the order line element
                    TempLineElement.Create();
                    SetFromItemJournalLine(ItemJnlLine, TempLineElement, _BackendID);
                    TempLineElement.Save();
                end;
            until ItemJnlLine.Next() = 0;
        end;

        AddBaseOrderLineElements(XmlResponseData, TempLineElement);
    end;

    local procedure PhysFilterOrders(var _ItemJnlBatch: Record "Item Journal Batch")
    begin
        // 1. Set the key you want the orders to be sorted by (primary key by default)
        // 2. Determine which warehouse employee the mobile user corresponds to and filter on "Assigned User ID"
        //    (if you want to filter the orders)
        _ItemJnlBatch.SetRange(MOBReleasedToMobile, true);
        _ItemJnlBatch.SetRange("Journal Template Name", MobSetup."Inventory Jnl Template");
    end;

    local procedure CalcQtyItemJnlLine(var _ItemJnlLine: Record "Item Journal Line"; QtyBase: Decimal): Decimal
    begin
        _ItemJnlLine.TestField("Qty. per Unit of Measure");
        exit(Round(QtyBase / _ItemJnlLine."Qty. per Unit of Measure", 0.00001));
    end;

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
        OnGetCountOrders_OnAfterSetCurrentKey(TempHeaderElementCustomView);
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

    procedure CreateBackendIdForWhseJnlBatch(_Prefix: Text[2]; _BatchName: Code[10]; _LocationCode: Code[10]): Code[40]
    var
        Batch: Text;
    begin
        Batch := _BatchName;
        exit(_Prefix + Batch.PadRight(10) + _LocationCode);
    end;

    local procedure SetCurrentKeyLine(var _BaseOrderLineElement: Record "MOB NS BaseDataModel Element")
    var
        TempBaseOrderLineElementCustomView: Record "MOB NS BaseDataModel Element" temporary;
    begin
        _BaseOrderLineElement.SetCurrentKey("Sorting1 (internal)", "Sorting2 (internal)", "Sorting3 (internal)", "Sorting4 (internal)", "Sorting5 (internal)");

        // use new temporary/empty record for integration event to prevent SetFrom from being in effect at this point in time
        TempBaseOrderLineElementCustomView.SetView(_BaseOrderLineElement.GetView());
        OnGetCountOrderLines_OnAfterSetCurrentKey(TempBaseOrderLineElementCustomView);
        _BaseOrderLineElement.SetView(TempBaseOrderLineElementCustomView.GetView());
    end;

    local procedure SetFromItemJournalBatch(_ItemJnlBatch: Record "Item Journal Batch"; var _BaseOrder: Record "MOB NS BaseDataModel Element")
    var
        RecRef: RecordRef;
    begin
        // Add the data elements to the <Order> element
        _BaseOrder.Init();

        // The backend ID is prefixed to determine the journal type
        _BaseOrder.Set_BackendID(INV_JNL_PREFIX_Txt + _ItemJnlBatch.Name);

        // Now we add the elements that we want the user to see
        _BaseOrder.Set_DisplayLine1(_ItemJnlBatch.Name);
        _BaseOrder.Set_DisplayLine2(_ItemJnlBatch.Description);
        _BaseOrder.Set_DisplayLine3('');
        _BaseOrder.Set_HeaderLabel1(MobWmsLanguage.GetMessage('JNL_BATCH'));
        _BaseOrder.Set_HeaderLabel2(MobWmsLanguage.GetMessage('DESCRIPTION'));
        _BaseOrder.Set_HeaderValue1(_ItemJnlBatch.Name);
        _BaseOrder.Set_HeaderValue2(_ItemJnlBatch.Description);

        RecRef.GetTable(_ItemJnlBatch);
        SetFromAnyBatch(RecRef, _BaseOrder);
        OnGetCountOrders_OnAfterSetFromItemJournalBatch(_ItemJnlBatch, _BaseOrder);
        OnGetCountOrders_OnAfterSetFromAnyBatch(RecRef, _BaseOrder);
    end;

    local procedure SetFromWarehouseJournalBatch(_WhseJnlBatch: Record "Warehouse Journal Batch"; var _BaseOrder: Record "MOB NS BaseDataModel Element")
    var
        Location: Record Location;
        RecRef: RecordRef;
    begin
        // Add the data to the order header element
        // with _BaseOrderElement do begin
        _BaseOrder.Init();

        // The journal name is prefixed to determine its type later
        _BaseOrder.Set_BackendID(CreateBackendIdForWhseJnlBatch("CONST::WarehouseJournalPrefix"(), _WhseJnlBatch.Name, _WhseJnlBatch."Location Code"));

        // Now we add the elements that we want the user to see
        _BaseOrder.Set_DisplayLine1(_WhseJnlBatch.Name);
        _BaseOrder.Set_DisplayLine2(_WhseJnlBatch.Description);
        _BaseOrder.Set_HeaderLabel1(MobWmsLanguage.GetMessage('JNL_BATCH'));
        _BaseOrder.Set_HeaderLabel2(MobWmsLanguage.GetMessage('LOCATION'));
        _BaseOrder.Set_HeaderValue1(_WhseJnlBatch.Name);

        if Location.Get(_WhseJnlBatch."Location Code") then
            _BaseOrder.Set_HeaderValue2(Location.Name <> '', Location.Name, Location.Code)
        else
            _BaseOrder.Set_HeaderValue2(_WhseJnlBatch."Location Code");

        _BaseOrder.Set_DisplayLine3(_BaseOrder.Get_HeaderValue2());

        RecRef.GetTable(_WhseJnlBatch);
        SetFromAnyBatch(RecRef, _BaseOrder);
        OnGetCountOrders_OnAfterSetFromWarehouseJournalBatch(_WhseJnlBatch, _BaseOrder);
        OnGetCountOrders_OnAfterSetFromAnyBatch(RecRef, _BaseOrder);
    end;

    local procedure SetFromAnyBatch(var _RecRef: RecordRef; var _BaseOrder: Record "MOB NS BaseDataModel Element")
    begin
        _BaseOrder.Set_ReferenceID(_RecRef);
        _BaseOrder.Set_Status();   // Set Locked/Has Attachment symbol (1=Unlocked, 2=Locked, 3=Attachment)
    end;

    local procedure SetFromItemJournalLine(_ItemJnlLine: Record "Item Journal Line"; var _BaseOrderLine: Record "MOB NS BaseDataModel Element"; _BackendID: Code[40])
    var
        Location: Record Location;
        MobTrackingSetup: Record "MOB Tracking Setup";
        TempSteps: Record "MOB Steps Element" temporary;
        RecRef: RecordRef;
        ExpDateRequired: Boolean;
        DummyWhseExpDateRequired: Boolean;
    begin
        // Add the data to the journal line element
        _BaseOrderLine.Init();

        // Here we use he prefix. Use the OrderBackendID variable
        _BaseOrderLine.Set_OrderBackendID(_BackendID);
        _BaseOrderLine.Set_LineNumber(_ItemJnlLine."Line No.");

        // No ToBin when counting
        _BaseOrderLine.Set_FromBin(_ItemJnlLine."Bin Code");
        _BaseOrderLine.Set_ToBin('');

        if not Location.Get(_ItemJnlLine."Location Code") then
            Clear(Location);

        _BaseOrderLine.Set_ValidateFromBin(Location."Bin Mandatory");
        _BaseOrderLine.Set_ValidateToBin(false);
        _BaseOrderLine.Set_Location(Location.Code);

        // Determine if tracking should be collected
        if Location."Bin Mandatory" then
            // If item tracking (lot/SN) are used in combination with bins, it is recommended that warehouse tracking (lot/SN)
            // are enabled as well.
            // If warehouse tracking is disabled, the "Item Ledger Entry" will hold information of lot/SN but this informations
            // is not registred per bin.
            // This makes it impossible to calculate and create the relevant tracking linies to the journal lines.
            // As a result of this planned count, shall not collect item tracking information, if Warehouse Tracking is disabled.
            // After completing planned count, all adjustments to items with item tracking, must be investigated and entered
            // to the tracking lines manually.
            MobTrackingSetup.DetermineWhseTrackingRequired(_ItemJnlLine."Item No.", DummyWhseExpDateRequired)
        else
            MobTrackingSetup.DetermineSpecificTrackingRequiredFromItemNo(_ItemJnlLine."Item No.", ExpDateRequired);

        MobTrackingSetup.CopyTrackingFromItemJnlLine(_ItemJnlLine);

        // Override ExpDateRequired: Expiration dates should never be collected on a planned count, as it is inherited from the ItemLedgerEntry
        ExpDateRequired := false;

        // Serial / lot / package number registration
        _BaseOrderLine.SetTracking(MobTrackingSetup);   // Set empty "Serial No." / "Lot No." / "Package No." to include tags in xml
        _BaseOrderLine.SetRegisterTracking(MobTrackingSetup);
        _BaseOrderLine.Set_RegisterExpirationDate(ExpDateRequired);

        _BaseOrderLine.Set_ItemNumber(_ItemJnlLine."Item No.");
        _BaseOrderLine.Set_ItemBarcode(MobItemReferenceMgt.GetBarcodeList(_ItemJnlLine."Item No.", _ItemJnlLine."Variant Code", _ItemJnlLine."Unit of Measure Code"));
        _BaseOrderLine.Set_Description(_ItemJnlLine.Description);

        // If the <RegisterQuantityByScan> element is set to true the mobile device can use values in <BarcodeQuantity>
        // element to register the quantity associated with barcode instead of always registering 1.
        _BaseOrderLine.Set_RegisterQuantityByScan(false);

        _BaseOrderLine.Set_Quantity(_ItemJnlLine."Qty. (Calculated)");
        _BaseOrderLine.Set_UnitOfMeasure(_ItemJnlLine."Unit of Measure Code");

        // Decide what to display on the lines
        // There are 5 display lines available in the standard configuration
        // Line 1: Show the Bin
        // Line 2: Show the Location
        // Line 3: Show the Item Number + UoM under the quantity (this is handled in the UserRole.xml on the mobile device)
        // Line 4: Show the Item Description
        // Line 5: Show the Item Variant
        _BaseOrderLine.Set_DisplayLine1(_ItemJnlLine."Bin Code" <> '', _ItemJnlLine."Bin Code", MobWmsLanguage.GetMessage('NO_BIN'));
        _BaseOrderLine.Set_DisplayLine2(_ItemJnlLine."Location Code");
        _BaseOrderLine.Set_DisplayLine3(_ItemJnlLine."Item No.");
        _BaseOrderLine.Set_DisplayLine4(_ItemJnlLine.Description);
        _BaseOrderLine.Set_DisplayLine5(_ItemJnlLine."Variant Code" <> '', MobWmsLanguage.GetMessage('VARIANT_LABEL') + ': ' + _ItemJnlLine."Variant Code", '');

        RecRef.GetTable(_ItemJnlLine);
        SetFromAnyLine(RecRef, _BaseOrderLine);
        OnGetCountOrderLines_OnAfterSetFromItemJournalLine(_ItemJnlLine, _BaseOrderLine);
        OnGetCountOrderLines_OnAfterSetFromAnyLine(RecRef, _BaseOrderLine);

        TempSteps.SetMustCallCreateNext(true);
        OnGetCountOrderLines_OnAddStepsToAnyLine(RecRef, _BaseOrderLine, TempSteps);
        if not TempSteps.IsEmpty() then
            _BaseOrderLine.Set_Workflow(TempSteps, "MOB TweakType"::Append);
    end;

    local procedure SetFromWarehouseJournalLine(_WhseJnlLine: Record "Warehouse Journal Line"; var _BaseOrderLine: Record "MOB NS BaseDataModel Element"; _BackendID: Code[40])
    var
        Location: Record Location;
        MobTrackingSetup: Record "MOB Tracking Setup";
        TempSteps: Record "MOB Steps Element" temporary;
        RecRef: RecordRef;
        DummyRegisterExpirationDate: Boolean;
    begin
        // Add the data to the journal line element
        _BaseOrderLine.Init();

        // Add the data to the order line element
        // Use the OrderNo value because it contains the prefix
        _BaseOrderLine.Set_OrderBackendID(_BackendID);
        _BaseOrderLine.Set_LineNumber(_WhseJnlLine."Line No.");

        // There is no ToBin when counting
        _BaseOrderLine.Set_FromBin(_WhseJnlLine."Bin Code");
        _BaseOrderLine.Set_ToBin('');

        if Location.Get(_WhseJnlLine."Location Code") then
            _BaseOrderLine.Set_ValidateFromBin(Location."Bin Mandatory")
        else
            _BaseOrderLine.Set_ValidateFromBin(false);

        _BaseOrderLine.Set_Location(Location.Code);
        _BaseOrderLine.Set_ValidateToBin(false);

        // Serial / lot / package number registration is disabled during counting
        MobTrackingSetup.DetermineWhseTrackingRequired(_WhseJnlLine."Item No.", DummyRegisterExpirationDate);
        MobTrackingSetup.CopyTrackingFromWhseJnlLine(_WhseJnlLine);

        _BaseOrderLine.SetTracking(MobTrackingSetup);
        _BaseOrderLine.SetRegisterTracking(MobTrackingSetup);
        _BaseOrderLine.Set_RegisterExpirationDate(false);

        _BaseOrderLine.Set_ItemNumber(_WhseJnlLine."Item No.");
        _BaseOrderLine.Set_ItemBarcode(MobItemReferenceMgt.GetBarcodeList(_WhseJnlLine."Item No.", _WhseJnlLine."Variant Code", _WhseJnlLine."Unit of Measure Code"));
        _BaseOrderLine.Set_Description(_WhseJnlLine.Description);

        // If the <RegisterQuantityByScan> element is set to true the mobile device can use values in <BarcodeQuantity>
        // element to register the quantity associated with barcode instead of always registering 1.
        _BaseOrderLine.Set_RegisterQuantityByScan(false);

        _BaseOrderLine.Set_Quantity(_WhseJnlLine."Qty. (Calculated)");
        _BaseOrderLine.Set_UnitOfMeasure(_WhseJnlLine."Unit of Measure Code");

        // Decide what to display on the lines
        // There are 5 display lines available in the standard configuration
        // Line 1: Show the Bin
        // Line 2: Show the Item Number + UoM under the quantity (this is handled in the UserRole.xml on the mobile device)
        // Line 3: Show the Item Description
        // Line 4: Show the Serial/Lot Info
        // Line 5: Show the Item Variant
        _BaseOrderLine.Set_DisplayLine1(_WhseJnlLine."Bin Code");
        _BaseOrderLine.Set_DisplayLine2(_WhseJnlLine."Item No.");
        _BaseOrderLine.Set_DisplayLine3(_WhseJnlLine.Description);
        _BaseOrderLine.Set_DisplayLine4(MobTrackingSetup.FormatTracking());
        _BaseOrderLine.Set_DisplayLine5(_WhseJnlLine."Variant Code" <> '', MobWmsLanguage.GetMessage('VARIANT_LABEL') + ': ' + _WhseJnlLine."Variant Code", '');

        RecRef.GetTable(_WhseJnlLine);
        SetFromAnyLine(RecRef, _BaseOrderLine);
        OnGetCountOrderLines_OnAfterSetFromWarehouseJournalLine(_WhseJnlLine, _BaseOrderLine);
        OnGetCountOrderLines_OnAfterSetFromAnyLine(RecRef, _BaseOrderLine);

        TempSteps.SetMustCallCreateNext(true);
        OnGetCountOrderLines_OnAddStepsToAnyLine(RecRef, _BaseOrderLine, TempSteps);
        if not TempSteps.IsEmpty() then
            _BaseOrderLine.Set_Workflow(TempSteps, "MOB TweakType"::Append);
    end;

    local procedure SetFromAnyLine(var _RecRef: RecordRef; var _BaseOrderLine: Record "MOB NS BaseDataModel Element")
    begin
        // Bin Change not allowed when counting
        _BaseOrderLine.Set_AllowBinChange(false);

        _BaseOrderLine.Set_RegisterQuantityByScan(false);
        _BaseOrderLine.Set_RegisteredQuantity('0');

        // The choices are: None, Warn, Block
        _BaseOrderLine.Set_UnderDeliveryValidation('None');
        _BaseOrderLine.Set_OverDeliveryValidation('None');

        _BaseOrderLine.Set_ReferenceID(_RecRef);
        _BaseOrderLine.Set_Status('0');
        _BaseOrderLine.Set_Attachment();
        _BaseOrderLine.Set_ItemImageID();

    end;

    internal procedure "CONST::WarehouseJournalPrefix"(): Text[2]
    begin
        exit(WHSE_INV_JNL_PREFIX_Txt);
    end;

    // 
    // ------- IntegrationEvents: GetCountOrders -------
    // 
    // // SetFilterItemJournalBatch                from  'OnGetCountOrders'
    // // SetFilterWarehouseJournalBatch           from  'OnGetCountOrders'
    // OnAfterSetFromItemJournalBatch           from  'GetCountOrders'.GetOrders().PhysCreateOrderResponse().SetFromItemJournalBatch()
    // OnAfterSetFromWarehouseJournalBatch      from  'GetCountOrders'.GetOrders().CreateOrderResponse().SetFromWarehouseJournalBatch()
    // OnAfterSetFromAnyBatch                   from  'GetCountOrders'. ....  SetFromXXXBatch()
    // OnAfterSetCurrentKey                     from  'GetCountOrders'. ....  AddBaseOrderElements().SetCurrentKeyHeader()

    [IntegrationEvent(false, false)]
    local procedure OnGetCountOrders_OnSetFilterItemJournalBatch(_HeaderFilter: Record "MOB NS Request Element"; var _ItemJnlBatch: Record "Item Journal Batch"; var _ItemJnlLine: Record "Item Journal Line"; var _IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetCountOrders_OnSetFilterWarehouseJournalBatch(_HeaderFilter: Record "MOB NS Request Element"; var _WhseJnlBatch: Record "Warehouse Journal Batch"; var _WhseJnlLine: Record "Warehouse Journal Line"; var _IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnGetCountOrders_OnIncludeWarehouseJournalBatch(_WhseJournalBatch: Record "Warehouse Journal Batch"; var _HeaderFilters: Record "MOB NS Request Element"; var _IncludeInOrderList: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnGetCountOrders_OnIncludeItemJournalBatch(_ItemJournalBatch: Record "Item Journal Batch"; var _HeaderFilters: Record "MOB NS Request Element"; var _IncludeInOrderList: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetCountOrders_OnAfterSetFromItemJournalBatch(_ItemJnlBatch: Record "Item Journal Batch"; var _BaseOrderElement: Record "MOB NS BaseDataModel Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetCountOrders_OnAfterSetFromWarehouseJournalBatch(_WhseJnlBatch: Record "Warehouse Journal Batch"; var _BaseOrderElement: Record "MOB NS BaseDataModel Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetCountOrders_OnAfterSetFromAnyBatch(_RecRef: RecordRef; var _BaseOrderElement: Record "MOB NS BaseDataModel Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetCountOrders_OnAfterSetCurrentKey(var _BaseOrderElementView: Record "MOB NS BaseDataModel Element")
    begin
    end;

    //
    // ------- IntegrationEvents: GetCountOrderLines -------
    //
    // OnAfterSetFromItemJournalLine            from  'OnGetCountOrderLines'
    // OnAfterSetFromWarehouseJournalLine       from  'OnGetCountOrderLines'
    // OnAfterSetFromItemJournalLine            from  'GetCountOrderLines'.GetOrderLines().PhysCreateOrderLinesResponse().SetFromItemJnlLine()
    // OnAfterSetFromWarehouseJournalLine       from  'GetCountOrderLines'.GetOrderLines().CreateOrderLinesResponse().SetFromWhseJnlLne()
    // OnAfterSetFromAnyLine                    from  'GetCountOrderLines'. ....  SetFromXXXLine()
    // OnAfterSetCurrentKey                     from  'GetCountOrderLines'. ....  AddBaseOrderLineElements().SetCurrentKeyLine()

    [IntegrationEvent(false, false)]
    local procedure OnGetCountOrderLines_OnSetFilterItemJournalLine(var _ItemJnlLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetCountOrderLines_OnSetFilterWarehouseJournalLine(var _WhseJnlLine: Record "Warehouse Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetCountOrderLines_OnIncludeItemJournalLine(_ItemJnlLine: Record "Item Journal Line"; var _IncludeInOrderLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetCountOrderLines_OnIncludeWarehouseJournalLine(_WhseJnlLine: Record "Warehouse Journal Line"; var _IncludeInOrderLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetCountOrderLines_OnAfterSetFromItemJournalLine(_ItemJnlLine: Record "Item Journal Line"; var _BaseOrderLineElement: Record "MOB NS BaseDataModel Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetCountOrderLines_OnAfterSetFromWarehouseJournalLine(_WhseJnlLine: Record "Warehouse Journal Line"; var _BaseOrderLineElement: Record "MOB NS BaseDataModel Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetCountOrderLines_OnAfterSetFromAnyLine(_RecRef: RecordRef; var _BaseOrderLineElement: Record "MOB NS BaseDataModel Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetCountOrderLines_OnAfterSetCurrentKey(var _BaseOrderLineElementView: Record "MOB NS BaseDataModel Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetCountOrderLines_OnAddStepsToAnyHeader(_RecRef: RecordRef; var _StepsElement: Record "MOB Steps Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetCountOrderLines_OnAddStepsToAnyLine(_RecRef: RecordRef; var _BaseOrderLineElement: Record "MOB NS BaseDataModel Element"; var _Steps: Record "MOB Steps Element")
    begin
    end;

    //
    // ------- IntegrationEvents: PostCountOrder -------
    //

    [IntegrationEvent(false, false)]
    local procedure OnPostCountOrder_OnHandleRegistrationForItemJournalLine(var _Registration: Record "MOB WMS Registration"; var _ItemJnlLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostCountOrder_OnHandleRegistrationForWarehouseJournalLine(var _Registration: Record "MOB WMS Registration"; var _WhseJnlLine: Record "Warehouse Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostCountOrder_OnHandleRegistrationForAnyLine(var _Registration: Record "MOB WMS Registration"; var _RecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostCountOrder_OnAddStepsToItemJournalBatch(var _OrderValues: Record "MOB Common Element"; _ItemJnlBatch: Record "Item Journal Batch"; var _StepsElement: Record "MOB Steps Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostCountOrder_OnAddStepsToWarehouseJournalBatch(var _OrderValues: Record "MOB Common Element"; _WhseJnlBatch: Record "Warehouse Journal Batch"; var _StepsElement: Record "MOB Steps Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostCountOrder_OnAddStepsToAnyBatch(var _OrderValues: Record "MOB Common Element"; _RecRef: RecordRef; var _StepsElement: Record "MOB Steps Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostCountOrder_OnBeforePostItemJournalBatch(var _OrderValues: Record "MOB Common Element"; var _ItemJnlBatch: Record "Item Journal Batch")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostCountOrder_OnBeforePostWarehouseJournalBatch(var _OrderValues: Record "MOB Common Element"; var _WhseJnlBatch: Record "Warehouse Journal Batch")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostCountOrder_OnBeforePostAnyBatch(var _OrderValues: Record "MOB Common Element"; var _RecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnPostCountOrder_OnAfterPostAnyOrder(var _OrderValues: Record "MOB Common Element"; var _RecRef: RecordRef; var _ResultMessage: Text)
    begin
    end;

}
