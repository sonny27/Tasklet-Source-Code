codeunit 81372 "MOB WMS Receive"
{
    Access = Public;
    TableNo = "MOB Document Queue";

    trigger OnRun()
    var
        MobWmsLanguage: Codeunit "MOB WMS Language";
    begin
        MobDocQueue := Rec;

        case Rec."Document Type" of

            // Order headers
            'GetReceiveOrders':
                GetOrders();

            // Order lines
            'GetReceiveOrderLines':
                GetOrderLines();

            // Posting
            'PostReceiveOrder':
                PostOrder();

            else
                Error(MobWmsLanguage.GetMessage('NO_DOC_HANDLER'), Rec."Document Type");
        end;

        // Store the result in the queue and update the status
        MobToolbox.UpdateResult(Rec, XmlResponseDoc);
    end;

    var
        MobDocQueue: Record "MOB Document Queue";
        MobItemReferenceMgt: Codeunit "MOB Item Reference Mgt.";
        MobSessionData: Codeunit "MOB SessionData";
        MobXmlMgt: Codeunit "MOB XML Management";
        MobRequestMgt: Codeunit "MOB NS Request Management";
        MobBaseDocHandler: Codeunit "MOB WMS Base Document Handler";
        MobToolbox: Codeunit "MOB Toolbox";
        MobTryEvent: Codeunit "MOB Try Event";
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
        XmlResponseDoc: XmlDocument;
        DELIVERY_NOTE_Txt: Label 'DeliveryNote', Locked = true;
        MobMixedRegistrationsDetected_Txt: Label 'All lines must be received the same way: either all with or all without a License Plate. Ensure all registrations either include or exclude a License Plate.';

    local procedure GetOrders()
    var
        TempBaseOrderElement: Record "MOB NS BaseDataModel Element" temporary;
        XmlRequestDoc: XmlDocument;
        XmlResponseData: XmlNode;
    begin
        // Load the request from the queue
        MobDocQueue.LoadXMLRequestDoc(XmlRequestDoc);

        // Initialize the response document for order data
        MobToolbox.InitializeResponseDoc(XmlResponseDoc, XmlResponseData);

        // Warehouse receipts to buffer
        GetWarehouseReceipts(XmlRequestDoc, MobDocQueue, TempBaseOrderElement);

        // Purchase orders to buffer
        GetPurchaseOrders(XmlRequestDoc, MobDocQueue, TempBaseOrderElement);

        // Transfer orders to buffer
        GetTransferOrders(XmlRequestDoc, MobDocQueue, TempBaseOrderElement);

        // Sales Return Orders to buffer
        GetSalesReturnOrders(XmlRequestDoc, MobDocQueue, TempBaseOrderElement);

        // Add collected buffer values to new <Orders> nodes
        AddBaseOrderElements(XmlResponseData, TempBaseOrderElement);
    end;

    local procedure GetOrderLines()
    var
        MobSetup: Record "MOB Setup";
        XmlRequestDoc: XmlDocument;
        XmlRequestDataNode: XmlNode;
        XmlBackendIDNode: XmlNode;
        XmlRequestNode: XmlNode;
        BackendID: Code[30];
        OrderType: Option PurchaseOrder,TransferOrder,SalesReturnOrder,WhseReceiptOrder;
        OrderNo: Code[20];
    begin
        // The Request Document looks like this:
        //  <request name="GetReceiveOrderLines"
        //           created="2009-01-20T22:36:34-08:00"
        //           xmlns="http://schemas.microsoft.com/Dynamics/Mobile/2007/04>
        //    <requestData name="GetReceiveOrderLines">
        //      <BackendID>RE000004</BackendID>
        //    </requestData>
        //  </request>

        // We want to extract the BackendID (Order No.) from the XML to get the order lines

        // Get Mobile Base Configuration
        MobSetup.Get();

        // Load the request document from the document queue
        MobDocQueue.LoadXMLRequestDoc(XmlRequestDoc);

        // Get the <BackendID> element (the first item in the returned node list)
        MobXmlMgt.GetDocRootNode(XmlRequestDoc, XmlRequestNode);
        MobXmlMgt.FindNode(XmlRequestNode, 'requestData', XmlRequestDataNode);
        MobXmlMgt.FindNode(XmlRequestDataNode, 'BackendID', XmlBackendIDNode);

        // Read the value of the BackendID
        BackendID := MobXmlMgt.GetNodeInnerText(XmlBackendIDNode);
        SetOrderIDAndType(BackendID, OrderNo, OrderType);

        // Create the response for the mobile device
        case OrderType of
            OrderType::WhseReceiptOrder:
                CreateWhseReceiptLinesResponse(BackendID);
            OrderType::PurchaseOrder:
                CreatePurchaseLinesResponse(BackendID);
            OrderType::TransferOrder:
                CreateTransferLinesResponse(BackendID);
            OrderType::SalesReturnOrder:
                CreateSalesReturnLinesResponse(BackendID);
        end;
    end;

    local procedure PostOrder()
    var
        MobSetup: Record "MOB Setup";
        TempOrderValues: Record "MOB Common Element" temporary;
        XmlRequestDoc: XmlDocument;
        BackendID: Code[30];
        OrderType: Option PurchaseOrder,TransferOrder,SalesReturnOrder,WhseReceiptOrder;
        OrderID: Code[20];
    begin
        // Get Mobile Base Configuration
        MobSetup.Get();

        // Load the request document from the document queue
        MobDocQueue.LoadXMLRequestDoc(XmlRequestDoc);
        MobRequestMgt.InitCommonFromXmlOrderNode(XmlRequestDoc, TempOrderValues);

        // Get the order ID
        Evaluate(BackendID, TempOrderValues.GetValue('backendID', true));
        SetOrderIDAndType(BackendID, OrderID, OrderType);

        // Post Receipt
        case OrderType of
            OrderType::WhseReceiptOrder:
                PostWhseReceiptOrder(OrderID);
            OrderType::PurchaseOrder:
                PostPurchaseOrder(OrderID);
            OrderType::TransferOrder:
                PostTransferOrder(OrderID);
            OrderType::SalesReturnOrder:
                PostSalesReturnOrder();
        end;
    end;

    //
    // ----- RESPONSE -----
    //

    local procedure GetWarehouseReceipts(var _XmlRequestDoc: XmlDocument; var _MobDocQueue: Record "MOB Document Queue"; var _BaseOrderElement: Record "MOB NS BaseDataModel Element")
    var
        TempWhseReceiptHeader: Record "Warehouse Receipt Header" temporary;
        WhseReceiptHeader: Record "Warehouse Receipt Header";
        WhseReceiptLine: Record "Warehouse Receipt Line";
        TempHeaderFilter: Record "MOB NS Request Element" temporary;
        MobScannedValueMgt: Codeunit "MOB ScannedValue Mgt.";
        ExpectedReceiptDate: Date;
        IsHandled: Boolean;
        ScannedValue: Text;
    begin
        // Respond with a list of Warehouse Receipts

        // XML filter data into Temporary table
        MobRequestMgt.SaveHeaderFilters(_XmlRequestDoc, TempHeaderFilter);

        // Loop Filters
        if TempHeaderFilter.FindSet() then
            repeat

                // Event to allow for handling (custom) filters
                IsHandled := false;
                OnGetReceiveOrders_OnSetFilterWarehouseReceipt(TempHeaderFilter, WhseReceiptHeader, WhseReceiptLine, IsHandled);

                if not IsHandled then
                    case TempHeaderFilter.Name of

                        'Location':
                            if TempHeaderFilter."Value" = 'All' then
                                WhseReceiptHeader.SetFilter("Location Code", MobWmsToolbox.GetLocationFilter(_MobDocQueue."Mobile User ID")) // All locations for this user
                            else
                                WhseReceiptHeader.SetRange("Location Code", TempHeaderFilter."Value");

                        // Filter: Expected Receipt Date
                        'Date':
                            begin
                                ExpectedReceiptDate := TempHeaderFilter.GetValueAsDate();
                                if ExpectedReceiptDate <> 0D then
                                    WhseReceiptLine.SetFilter("Due Date", '<=%1', ExpectedReceiptDate);
                            end;

                        'PurchaseOrderNumber':
                            if TempHeaderFilter."Value" <> '' then begin
                                // Create Receipt for this PO if missing
                                CreateWhseReceipt(TempHeaderFilter."Value");

                                // The PO number is on the Receipt lines
                                WhseReceiptLine.SetRange("Source No.", TempHeaderFilter."Value");
                            end;

                        'ScannedValue':
                            ScannedValue := TempHeaderFilter."Value";   // Used in search for Document No. or Item/Variant later

                        'AssignedUser':
                            case TempHeaderFilter."Value" of
                                'All':
                                    ; // No filter -> do nothing
                                'OnlyMine':
                                    WhseReceiptHeader.SetRange("Assigned User ID", _MobDocQueue."Mobile User ID");  // Set the filter to the current user
                                'MineAndUnassigned':
                                    WhseReceiptHeader.SetFilter("Assigned User ID", '''''|%1', _MobDocQueue."Mobile User ID"); // Current user or blank
                            end;
                    end;

            until TempHeaderFilter.Next() = 0;


        // Run event once more with Empty "Header filter" to allow for additional filtering directly on the records, NOT related to specific Header filter
        Clear(IsHandled);
        TempHeaderFilter.ClearFields();
        OnGetReceiveOrders_OnSetFilterWarehouseReceipt(TempHeaderFilter, WhseReceiptHeader, WhseReceiptLine, IsHandled);

        // Filter: DocumentNo or Item/Variant (match for scanned document no. at location takes precedence over other filters)
        if ScannedValue <> '' then begin
            MobScannedValueMgt.SetFilterForWhseReceipt(WhseReceiptHeader, WhseReceiptLine, ScannedValue);
            WhseReceiptLine.SetRange("Due Date");
        end;

        // Insert orders into temp rec
        MobBaseDocHandler.CopyFilteredWhseReceiptHeadersToTempRecord(WhseReceiptHeader, WhseReceiptLine, TempHeaderFilter, TempWhseReceiptHeader);

        // Respond with resulting orders
        CreateWhseReceiptHeaderResponse(TempWhseReceiptHeader, _BaseOrderElement);
    end;

    local procedure GetSalesReturnOrders(var _XmlRequestDoc: XmlDocument; var _MobDocQueue: Record "MOB Document Queue"; var _BaseOrderElement: Record "MOB NS BaseDataModel Element")
    var
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        TempFilteredSalesHeader: Record "Sales Header" temporary;
        TempHeaderFilter: Record "MOB NS Request Element" temporary;
        SalesLine: Record "Sales Line";
        MobScannedValueMgt: Codeunit "MOB ScannedValue Mgt.";
        IsHandled: Boolean;
        ScannedValue: Text;
    begin
        // Respond with a list of Sales Orders

        // Mandatory Header filters for this function to operate
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::"Return Order");
        SalesHeader.SetRange(Status, SalesHeader.Status::Released);
        SalesHeader.SetRange("Completely Shipped", false);
        // Allow only locations that DO NOT use Receipts or Put-aways
        SalesHeader.SetFilter("Location Code", MobBaseDocHandler.GetLocationFilter_NoReceiptOrNoPutAway(_MobDocQueue."Mobile User ID"));

        // Mandatory Line filters
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.SetFilter("Outstanding Qty. (Base)", '>0');

        // XML filter data into Temporary table
        MobRequestMgt.SaveHeaderFilters(_XmlRequestDoc, TempHeaderFilter);

        if TempHeaderFilter.FindSet() then
            repeat

                // Event to allow for handling (custom) filters
                IsHandled := false;
                OnGetReceiveOrders_OnSetFilterSalesReturnOrder(TempHeaderFilter, SalesHeader, SalesLine, IsHandled);

                if not IsHandled then
                    case TempHeaderFilter.Name of

                        'Location':
                            if TempHeaderFilter."Value" = 'All' then
                                // Set the location filter to all locations NOT using Receipts or Put-aways
                                SalesHeader.SetFilter("Location Code", MobBaseDocHandler.GetLocationFilter_NoReceiptOrNoPutAway(_MobDocQueue."Mobile User ID"))
                            else begin
                                Location.Get(TempHeaderFilter."Value");
                                if Location."Require Put-away" or Location."Require Receive" then
                                    // Put-away or receive is used -> do not show sales return orders
                                    exit
                                else
                                    SalesHeader.SetRange("Location Code", TempHeaderFilter."Value");
                            end;
                        // Filter: Expected Receipt Date
                        'Date':
                            ;    // Do nothing, date is not relevant

                        'PurchaseOrderNumber':
                            if TempHeaderFilter."Value" <> '' then
                                exit;   // Illegal filter, return nothing for this type

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
        OnGetReceiveOrders_OnSetFilterSalesReturnOrder(TempHeaderFilter, SalesHeader, SalesLine, IsHandled);

        // Filter: DocumentNo or Item/Variant (match for scanned document no. at location takes precedence over other filters)
        if ScannedValue <> '' then
            MobScannedValueMgt.SetFilterForSalesDoc(SalesHeader, SalesLine, ScannedValue);

        // Insert orders into temp rec
        MobBaseDocHandler.CopyFilteredSalesHeadersToTempRecord(SalesHeader, SalesLine, TempHeaderFilter, TempFilteredSalesHeader);

        // Respond with resulting orders
        CreateSalesReturnResponse(TempFilteredSalesHeader, _BaseOrderElement);
    end;


    local procedure GetPurchaseOrders(var _XmlRequestDoc: XmlDocument; var _MobDocQueue: Record "MOB Document Queue"; var _BaseOrderElement: Record "MOB NS BaseDataModel Element")
    var
        Location: Record Location;
        PurchLine: Record "Purchase Line";
        PurchHeader: Record "Purchase Header";
        TempHeaderFilter: Record "MOB NS Request Element" temporary;
        TempFilteredPurchHeader: Record "Purchase Header" temporary;
        MobScannedValueMgt: Codeunit "MOB ScannedValue Mgt.";
        ExpectedReceiptDate: Date;
        IsHandled: Boolean;
        ScannedValue: Text;
    begin
        // Respond with a list of Purchase Orders

        // Mandatory Header filters for this function to operate
        PurchHeader.SetRange("Document Type", PurchHeader."Document Type"::Order);
        PurchHeader.SetRange(Status, PurchHeader.Status::Released);
        PurchHeader.SetRange("Completely Received", false);
        // Allow only locations that DO NOT use Receipts or Put-aways
        PurchHeader.SetFilter("Location Code", MobBaseDocHandler.GetLocationFilter_NoReceiptOrNoPutAway(_MobDocQueue."Mobile User ID"));

        // Mandatory Line filters
        PurchLine.SetRange(Type, PurchLine.Type::Item);
        PurchLine.SetRange("Drop Shipment", false);
        PurchLine.SetFilter("Outstanding Qty. (Base)", '>0');

        // XML filter data into Temporary table
        MobRequestMgt.SaveHeaderFilters(_XmlRequestDoc, TempHeaderFilter);

        if TempHeaderFilter.FindSet() then
            repeat

                // Event to allow for handling (custom) filters
                IsHandled := false;
                OnGetReceiveOrders_OnSetFilterPurchaseOrder(TempHeaderFilter, PurchHeader, PurchLine, IsHandled);

                if not IsHandled then
                    case TempHeaderFilter.Name of

                        'Location':
                            if TempHeaderFilter."Value" = 'All' then
                                // Set the location filter to all locations NOT using Receipts or Put-aways
                                PurchHeader.SetFilter("Location Code", MobBaseDocHandler.GetLocationFilter_NoReceiptOrNoPutAway(_MobDocQueue."Mobile User ID"))
                            else begin
                                Location.Get(TempHeaderFilter."Value");
                                if Location."Require Receive" or Location."Require Put-away" then
                                    exit  // Receive or put-away is used -> do not show purchase orders
                                else
                                    PurchHeader.SetRange("Location Code", TempHeaderFilter."Value");
                            end;

                        // Filter: Expected Receipt Date
                        'Date':
                            begin
                                ExpectedReceiptDate := MobToolbox.Text2Date(TempHeaderFilter."Value");
                                PurchHeader.SetFilter("Expected Receipt Date", '<=%1', ExpectedReceiptDate);
                            end;

                        'PurchaseOrderNumber':
                            if TempHeaderFilter."Value" <> '' then
                                PurchHeader.SetRange("No.", TempHeaderFilter."Value");

                        'ScannedValue':
                            ScannedValue := TempHeaderFilter."Value";   // Used in search for Document No. or Item/Variant later

                        'AssignedUser':
                            case TempHeaderFilter."Value" of
                                'All':
                                    ; // No filter -> do nothing
                                'OnlyMine':
                                    PurchHeader.SetRange("Assigned User ID", _MobDocQueue."Mobile User ID");  // Current user
                                'MineAndUnassigned':
                                    PurchHeader.SetFilter("Assigned User ID", '''''|%1', _MobDocQueue."Mobile User ID"); // Current user or blank
                            end;
                    end;

            until TempHeaderFilter.Next() = 0;

        // Run event once more with Empty "Header filter" to allow for additional filtering directly on the records, NOT related to specific Header filter
        Clear(IsHandled);
        TempHeaderFilter.ClearFields();
        OnGetReceiveOrders_OnSetFilterPurchaseOrder(TempHeaderFilter, PurchHeader, PurchLine, IsHandled);

        // Filter: DocumentNo or Item/Variant (match for scanned document no. at location takes precedence over other filters)
        if ScannedValue <> '' then
            MobScannedValueMgt.SetFilterForPurchDoc(PurchHeader, PurchLine, ScannedValue);

        // Insert orders into temp rec
        MobBaseDocHandler.CopyFilteredPurchaseHeadersToTempRecord(PurchHeader, PurchLine, TempHeaderFilter, TempFilteredPurchHeader);

        // Respond with resulting orders
        CreatePurchHeaderResponse(TempFilteredPurchHeader, _BaseOrderElement);

    end;

    local procedure GetTransferOrders(var _XmlRequestDoc: XmlDocument; var _MobDocQueue: Record "MOB Document Queue"; var _BaseOrderElement: Record "MOB NS BaseDataModel Element")
    var
        TempFilteredTransferHeader: Record "Transfer Header" temporary;
        TempHeaderFilter: Record "MOB NS Request Element" temporary;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        Location: Record Location;
        MobScannedValueMgt: Codeunit "MOB ScannedValue Mgt.";
        IsHandled: Boolean;
        ScannedValue: Text;
        ExpectedReceiptDate: Date;
    begin
        // Respond with a list of Transfer Orders

        // Mandatory Header filters for this function to operate
        TransferHeader.SetRange(Status, TransferHeader.Status::Released);
        // Allow only locations that DO NOT use Receipts or Put-aways
        TransferHeader.SetFilter("Transfer-to Code", MobBaseDocHandler.GetLocationFilter_NoReceiptOrNoPutAway(_MobDocQueue."Mobile User ID"));

        // Mandatory Line filters
        TransferLine.SetFilter("Qty. in Transit (Base)", '>0');

        // XML filter data into Temporary table
        MobRequestMgt.SaveHeaderFilters(_XmlRequestDoc, TempHeaderFilter);

        if TempHeaderFilter.FindSet() then
            repeat

                // Event to allow for handling (custom) filters
                IsHandled := false;
                OnGetReceiveOrders_OnSetFilterTransferOrder(TempHeaderFilter, TransferHeader, TransferLine, IsHandled);

                if not IsHandled then
                    case TempHeaderFilter.Name of
                        'Location':
                            if TempHeaderFilter."Value" = 'All' then
                                // Set the location filter to all locations NOT using Receipts or Put-aways
                                TransferHeader.SetFilter("Transfer-to Code", MobBaseDocHandler.GetLocationFilter_NoReceiptOrNoPutAway(_MobDocQueue."Mobile User ID"))
                            else begin
                                Location.Get(TempHeaderFilter."Value");
                                if Location."Require Receive" or Location."Require Put-away" then
                                    // Receive or put-away is used -> do not show purchase orders
                                    exit
                                else
                                    TransferHeader.SetRange("Transfer-to Code", TempHeaderFilter."Value");
                            end;

                        'Date':
                            begin
                                ExpectedReceiptDate := MobToolbox.Text2Date(TempHeaderFilter."Value");
                                TransferHeader.SetFilter("Receipt Date", '<=%1', ExpectedReceiptDate);
                            end;

                        'PurchaseOrderNumber':
                            if TempHeaderFilter."Value" <> '' then
                                exit;   // Illegal filter, return nothing for this type

                        'ScannedValue':
                            ScannedValue := TempHeaderFilter."Value";   // Used in search for Document No. or Item/Variant later

                        'AssignedUser':
                            case TempHeaderFilter."Value" of
                                'All':
                                    ; // No filter -> do nothing
                                'OnlyMine':
                                    TransferHeader.SetRange("Assigned User ID", _MobDocQueue."Mobile User ID");  // Current user
                                'MineAndUnassigned':
                                    TransferHeader.SetFilter("Assigned User ID", '''''|%1', _MobDocQueue."Mobile User ID"); // Current user or blank
                            end;
                    end;

            until TempHeaderFilter.Next() = 0;

        // Run event once more with Empty "Header filter" to allow for additional filtering directly on the records, NOT related to specific Header filter
        Clear(IsHandled);
        TempHeaderFilter.ClearFields();
        OnGetReceiveOrders_OnSetFilterTransferOrder(TempHeaderFilter, TransferHeader, TransferLine, IsHandled);

        // Filter: DocumentNo or Item/Variant (match for scanned document no. at location takes precedence over other filters)
        if ScannedValue <> '' then
            MobScannedValueMgt.SetFilterForTransferOrder(TransferHeader, TransferLine, ScannedValue);

        // Insert orders into temp rec
        MobBaseDocHandler.CopyFilteredTransferHeadersToTempRecord(TransferHeader, TransferLine, TempHeaderFilter, TempFilteredTransferHeader, false, true);

        // Respond with resulting orders
        CreateTransferHeaderResponse(TempFilteredTransferHeader, _BaseOrderElement);
    end;

    local procedure CreateWhseReceiptHeaderResponse(var _WhseReceiptHeader: Record "Warehouse Receipt Header"; var _BaseOrderElement: Record "MOB NS BaseDataModel Element")
    begin
        // Loop through the header records and insert the values in the XML
        if _WhseReceiptHeader.FindSet() then
            repeat

                // Collect buffer values for the <Order> element and add it to the <Orders> node
                _BaseOrderElement.Create();
                SetFromWarehouseReceiptHeader(_WhseReceiptHeader, _BaseOrderElement);
                _BaseOrderElement.Save();

            until _WhseReceiptHeader.Next() = 0;
    end;

    local procedure CreateWhseReceiptLinesResponse(_BackendID: Code[30])
    var
        WhseReceiptLine: Record "Warehouse Receipt Line";
        WhseReceiptHeader: Record "Warehouse Receipt Header";
        TempBaseOrderLineElement: Record "MOB NS BaseDataModel Element" temporary;
        MobWmsLanguage: Codeunit "MOB WMS Language";
        RecRef: RecordRef;
        XmlResponseData: XmlNode;
        OrderType: Option PurchaseOrder,TransferOrder,SalesReturnOrder,WhseReceiptOrder;
        OrderNo: Code[20];
        IncludeInOrderLines: Boolean;
    begin
        // Description:
        // Get the order lines for the requested order.
        // Sort the lines.
        // Create the response XML
        SetOrderIDAndType(_BackendID, OrderNo, OrderType);

        MobWmsToolbox.CheckWhseSetupReceipt();

        // Initialize the response document for order line data
        MobToolbox.InitializeRespDocWithoutNS(XmlResponseDoc, XmlResponseData);

        // Check that the same numbers are not used
        WhseReceiptHeader.SetRange("No.", OrderNo);
        if (WhseReceiptHeader.Count()) > 1 then
            Error(MobWmsLanguage.GetMessage('WHSE_ACT_NOT_UNIQUE'), OrderNo);

        if WhseReceiptHeader.FindFirst() then begin
            // Add Collector Steps for collecting data On Posting
            RecRef.GetTable(WhseReceiptHeader);
            AddStepsToAnyHeader(_BackendID, RecRef, XmlResponseDoc, XmlResponseData);
        end;

        // Respect Sorting Method fields value from Warehouse Receipt Header
        WhseReceiptLine.SetCurrentKey("No.", "Sorting Sequence No.");

        // Filter the lines for this particular order
        WhseReceiptLine.SetRange(WhseReceiptLine."No.", OrderNo);

        // Event to expose Lines for filtering before Response
        OnGetReceiveOrderLines_OnSetFilterWarehouseReceiptLine(WhseReceiptLine);

        // Insert the values from the line in the XML
        if WhseReceiptLine.FindSet() then
            repeat
                // Verify conditions from eventsubscribers
                IncludeInOrderLines := true;
                OnGetReceiveOrderLines_OnIncludeWarehouseReceiptLine(WhseReceiptLine, IncludeInOrderLines);

                if IncludeInOrderLines then begin
                    TempBaseOrderLineElement.Create();
                    SetFromWarehouseReceiptLine(WhseReceiptLine, TempBaseOrderLineElement);
                    TempBaseOrderLineElement.Save();
                end;
            until WhseReceiptLine.Next() = 0;

        AddBaseOrderLineElements(XmlResponseData, TempBaseOrderLineElement);
    end;

    local procedure CreatePurchHeaderResponse(var _PurchHeader: Record "Purchase Header"; var _BaseOrderElement: Record "MOB NS BaseDataModel Element")
    begin
        // Loop through the header records and insert the values in the XML
        if _PurchHeader.FindSet() then
            repeat
                // Collect the buffer values for <Order> elements
                _BaseOrderElement.Create();
                SetFromPurchaseHeader(_PurchHeader, _BaseOrderElement);
                _BaseOrderElement.Save();
            until _PurchHeader.Next() = 0;
    end;

    local procedure CreatePurchaseLinesResponse(_BackendID: Code[30])
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TempBaseOrderLineElement: Record "MOB NS BaseDataModel Element" temporary;
        RecRef: RecordRef;
        XmlResponseData: XmlNode;
        OrderType: Option PurchaseOrder,TransferOrder,SalesReturnOrder,WhseReceiptOrder;
        OrderNo: Code[20];
        IncludeInOrderLines: Boolean;
    begin
        // Description:
        // Get the order lines for the requested order.
        // Sort the lines.
        // Create the response XML
        SetOrderIDAndType(_BackendID, OrderNo, OrderType);

        // Initialize the response document for order line data
        MobToolbox.InitializeRespDocWithoutNS(XmlResponseDoc, XmlResponseData);

        if PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, OrderNo) then begin
            // Add Collector Steps for collecting data On Posting
            RecRef.GetTable(PurchaseHeader);
            AddStepsToAnyHeader(_BackendID, RecRef, XmlResponseDoc, XmlResponseData);
        end;

        // Filter the lines for this particular order
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Document No.", OrderNo);
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetRange("Drop Shipment", false);
        PurchaseLine.SetFilter("Outstanding Qty. (Base)", '>0');

        // Event to expose Lines for filtering before Response
        OnGetReceiveOrderLines_OnSetFilterPurchaseLine(PurchaseLine);

        // Insert the values from the line in the XML
        if PurchaseLine.FindSet() then
            repeat
                IncludeInOrderLines := PurchaseLine.IsInventoriableItem();

                // Verify additional conditions from eventsubscribers
                OnGetReceiveOrderLines_OnIncludePurchaseLine(PurchaseLine, IncludeInOrderLines);

                if IncludeInOrderLines then begin
                    TempBaseOrderLineElement.Create();
                    SetFromPurchaseLine(PurchaseLine, TempBaseOrderLineElement);
                    TempBaseOrderLineElement.Save();
                end;
            until PurchaseLine.Next() = 0;

        AddBaseOrderLineElements(XmlResponseData, TempBaseOrderLineElement);
    end;

    local procedure CreateTransferHeaderResponse(var _TransferHeader: Record "Transfer Header"; var _BaseOrderElement: Record "MOB NS BaseDataModel Element")
    begin
        // Loop through the header records and insert the values in the XML
        if _TransferHeader.FindSet() then
            repeat
                // Collect the buffer values for the <Order> element
                _BaseOrderElement.Create();
                SetFromTransferHeader(_TransferHeader, _BaseOrderElement);
                _BaseOrderElement.Save();
            until _TransferHeader.Next() = 0;
    end;

    local procedure CreateTransferLinesResponse(_BackendID: Code[30])
    var
        MobSetup: Record "MOB Setup";
        MobTrackingSetup: Record "MOB Tracking Setup";
        TempBaseOrderLineElement: Record "MOB NS BaseDataModel Element" temporary;
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ReservEntry: Record "Reservation Entry";
        RecRef: RecordRef;
        XmlResponseData: XmlNode;
        PadInt: Integer;
        PadString: Text[3];
        UseQuantity: Decimal;
        UseUoM: Code[10];
        OrderType: Option PurchaseOrder,TransferOrder,SalesReturnOrder,WhseReceiptOrder;
        OrderNo: Code[20];
        IncludeInOrderLines: Boolean;
        DummyExpDateRequired: Boolean;
    begin
        // This function is used to return receive order lines for a transfer order
        MobSetup.Get();
        SetOrderIDAndType(_BackendID, OrderNo, OrderType);

        // Initialize the response document for order line data
        MobToolbox.InitializeRespDocWithoutNS(XmlResponseDoc, XmlResponseData);

        if TransferHeader.Get(OrderNo) then begin
            // Add Collector Steps for collecting data On Posting
            RecRef.GetTable(TransferHeader);
            AddStepsToAnyHeader(_BackendID, RecRef, XmlResponseDoc, XmlResponseData);
        end;

        // Filter the transfer lines (return the lines that have been shipped, but not received)
        TransferLine.SetRange("Document No.", OrderNo);
        TransferLine.SetFilter("Qty. in Transit (Base)", '>0');
        TransferLine.SetRange("Derived From Line No.", 0);

        // Event to expose Lines for filtering before Response
        OnGetReceiveOrderLines_OnSetFilterTransferLine(TransferLine);

        if TransferLine.FindSet() then
            repeat
                // Verify conditions from eventsubscribers
                IncludeInOrderLines := true;
                OnGetReceiveOrderLines_OnIncludeTransferLine(TransferLine, IncludeInOrderLines);

                if IncludeInOrderLines then begin

                    // Initialize the PadInt counter
                    PadInt := 0;

                    // If item tracking is used we create a line for each lot / serial / package number
                    // The reservation entries were created when the transfer order was picked
                    ReservEntry.SetCurrentKey("Source ID", "Source Ref. No.", "Source Type");
                    ReservEntry.SetRange("Source ID", TransferLine."Document No.");
                    ReservEntry.SetRange("Source Prod. Order Line", TransferLine."Line No.");
                    ReservEntry.SetRange("Source Type", Database::"Transfer Line");
                    ReservEntry.SetFilter("Item Tracking", '<>%1', ReservEntry."Item Tracking"::None);
                    if ReservEntry.FindSet() then
                        repeat
                            // Update the reservation entry with the prefixed line number
                            // This allows the posting function to update the correct reservation entry
                            // "Prefixed Line No." = "LineNumber" on the mobile device
                            PadInt := PadInt + 1;
                            PadString := Format(PadInt);
                            ReservEntry.MOBPrefixedLineNo := PadString.PadLeft(3, '0') + Format(TransferLine."Line No.");
                            ReservEntry.Modify();

                            Item.Get(TransferLine."Item No.");

                            if MobSetup."Use Base Unit of Measure" then begin
                                UseQuantity := Abs(ReservEntry."Qty. to Handle (Base)");
                                UseUoM := Item."Base Unit of Measure";
                            end else begin
                                UseQuantity := MobWmsToolbox.CalcQtyNewUOMRounded(
                                                    TransferLine."Item No.",
                                                    Abs(ReservEntry."Qty. to Handle (Base)"),
                                                    Item."Base Unit of Measure",
                                                    TransferLine."Unit of Measure Code");
                                UseUoM := TransferLine."Unit of Measure Code";
                            end;

                            MobTrackingSetup.DetermineItemTrackingRequiredByTransferLine(TransferLine, true, DummyExpDateRequired);
                            MobTrackingSetup.CopyTrackingFromReservEntry(ReservEntry);

                            TempBaseOrderLineElement.Create();
                            SetFromTransferLine(TransferLine,
                                                ReservEntry."Entry No.",
                                                ReservEntry.MOBPrefixedLineNo,  // LineNumber
                                                MobTrackingSetup,               // SerialNumber, LotNumber, PackageNumber
                                                UseQuantity,                    // Quantity
                                                UseUoM,                         // Unit of Measure
                                                TempBaseOrderLineElement);
                            TempBaseOrderLineElement.Save();
                        until ReservEntry.Next() = 0
                    else begin

                        PadInt := PadInt + 1;
                        PadString := Format(PadInt);

                        if MobSetup."Use Base Unit of Measure" then begin
                            Item.Get(TransferLine."Item No.");
                            UseQuantity := TransferLine."Qty. in Transit (Base)";
                            UseUoM := Item."Base Unit of Measure";
                        end else begin
                            UseQuantity := TransferLine."Qty. in Transit";
                            UseUoM := TransferLine."Unit of Measure Code";
                        end;

                        Clear(MobTrackingSetup);
                        MobTrackingSetup.DetermineItemTrackingRequiredByTransferLine(TransferLine, true, DummyExpDateRequired);
                        // MobTrackingSetup.Tracking: Tracking values are unused in this scope

                        TempBaseOrderLineElement.Create();
                        SetFromTransferLine(TransferLine,
                                            0,                              // No Reservation Entry reference
                                            PadString.PadLeft(3, '0') + Format(TransferLine."Line No."),    // LineNumber
                                            MobTrackingSetup,               // Blank SerialNumber / LotNumber / PackageNumber
                                            UseQuantity,                    // Quantity
                                            UseUoM,                         // Unit of Measure
                                            TempBaseOrderLineElement);
                        TempBaseOrderLineElement.Save();
                    end;
                end; // IncludeInOrderLines
            until TransferLine.Next() = 0;

        AddBaseOrderLineElements(XmlResponseData, TempBaseOrderLineElement);
    end;

    local procedure CreateSalesReturnResponse(var _SalesReturnHeader: Record "Sales Header"; var _BaseOrderElement: Record "MOB NS BaseDataModel Element")
    begin
        // Loop through the header records and insert the values in the XML
        if _SalesReturnHeader.FindSet() then
            repeat
                // Collect the buffer values for the <Order> element and add it to the <Orders> node
                _BaseOrderElement.Create();
                SetFromSalesReturnHeader(_SalesReturnHeader, _BaseOrderElement);
                _BaseOrderElement.Save();
            until _SalesReturnHeader.Next() = 0;
    end;

    local procedure CreateSalesReturnLinesResponse(_BackendID: Code[30])
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TempBaseOrderLineElement: Record "MOB NS BaseDataModel Element" temporary;
        RecRef: RecordRef;
        XmlResponseData: XmlNode;
        OrderType: Option PurchaseOrder,TransferOrder,SalesReturnOrder,WhseReceiptOrder;
        OrderNo: Code[20];
        IncludeInOrderLines: Boolean;
    begin
        SetOrderIDAndType(_BackendID, OrderNo, OrderType);

        // Initialize the response document for order line data
        MobToolbox.InitializeRespDocWithoutNS(XmlResponseDoc, XmlResponseData);

        // Filter the sales header
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::"Return Order");
        SalesHeader.SetRange("No.", OrderNo);

        if SalesHeader.FindFirst() then begin

            // Add Collector Steps for collecting data On Posting
            RecRef.GetTable(SalesHeader);
            AddStepsToAnyHeader(_BackendID, RecRef, XmlResponseDoc, XmlResponseData);

            // Filter the sales lines
            SalesLine.SetRange("Document Type", SalesHeader."Document Type");
            SalesLine.SetRange("Document No.", SalesHeader."No.");
            SalesLine.SetRange(Type, SalesLine.Type::Item);
            SalesLine.SetFilter("Outstanding Qty. (Base)", '>0');

            // Event to expose Lines for filtering before Response
            OnGetReceiveOrderLines_OnSetFilterSalesReturnLine(SalesLine);

            if SalesLine.FindSet() then
                repeat
                    IncludeInOrderLines := SalesLine.IsInventoriableItem();

                    // Verify addional conditions from eventsubscribers
                    OnGetReceiveOrderLines_OnIncludeSalesReturnLine(SalesLine, IncludeInOrderLines);

                    if IncludeInOrderLines then begin
                        // Add the data to the order line element
                        TempBaseOrderLineElement.Create();
                        SetFromSalesReturnLine(SalesLine, TempBaseOrderLineElement);
                        TempBaseOrderLineElement.Save();
                    end;
                until SalesLine.Next() = 0;

            AddBaseOrderLineElements(XmlResponseData, TempBaseOrderLineElement);
        end;
    end;

    //
    // ------ COLLECTOR STEPS -----
    //

    local procedure AddStepsToAnyHeader(_BackendID: Code[30]; _RecRef: RecordRef; _XmlResponseDoc: XmlDocument; var _XmlResponseData: XmlNode)
    var
        MobSetup: Record "MOB Setup";
        TempSteps: Record "MOB Steps Element" temporary;
        MobWmsLanguage: Codeunit "MOB WMS Language";
        XmlSteps: XmlNode;
        OrderType: Option PurchaseOrder,TransferOrder,SalesReturnOrder,WhseReceiptOrder;
        OrderNo: Code[20];
    begin
        SetOrderIDAndType(_BackendID, OrderNo, OrderType);

        // Add step to Collect Delivery Note on posting receipt
        MobSetup.Get();
        if (OrderType in [OrderType::WhseReceiptOrder, OrderType::PurchaseOrder]) and (not MobSetup."Skip Collect Delivery Note") then
            // Define the delivery note
            TempSteps.Create_TextStep(
                10,                                                     // id
                DELIVERY_NOTE_Txt,                                      // name
                MobWmsLanguage.GetMessage('ENTER_DELV_NOTE'),           // header
                MobWmsLanguage.GetMessage('DELV_NOTE_LABEL_TEXT'),      // label
                '',                                                     // helpLabel
                '',                                                     // defaultValue
                35);                                                    // length

        TempSteps.SetMustCallCreateNext(true);
        OnGetReceiveOrderLines_OnAddStepsToAnyHeader(_RecRef, TempSteps);

        if not TempSteps.IsEmpty() then begin
            // Adds Collector Configuration with <steps> {<add ... />} <steps/>
            MobToolbox.AddCollectorConfiguration(_XmlResponseDoc, _XmlResponseData, XmlSteps);
            MobXmlMgt.AddStepsaddElements(XmlSteps, TempSteps);
        end;
    end;


    //
    // ----- POSTING -----
    // 

    local procedure PostWhseReceiptOrder(OrderID: Code[20])
    var
        MobSetup: Record "MOB Setup";
        MobTrackingSetup: Record "MOB Tracking Setup";
        MobWmsRegistration: Record "MOB WMS Registration";
        Location: Record Location;
        WhseReceiptHeader: Record "Warehouse Receipt Header";
        WhseReceiptLine: Record "Warehouse Receipt Line";
        CrossDockOpp: Record "Whse. Cross-Dock Opportunity";
        TempReservationEntryLog: Record "Reservation Entry" temporary;
        TempReservationEntry: Record "Reservation Entry" temporary;
        TempOrderValues: Record "MOB Common Element" temporary;
        TempSteps: Record "MOB Steps Element" temporary;
        CrossDockMgt: Codeunit "Whse. Cross-Dock Management";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        UoMMgt: Codeunit "Unit of Measure Management";
        WhsePostReceipt: Codeunit "Whse.-Post Receipt";
        MobOverReceiptMgt: Codeunit "MOB Over-Receipt Mgt.";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        MobSyncItemTracking: Codeunit "MOB Sync. Item Tracking";
        MobLicensePlateMgt: Codeunit "MOB License Plate Mgt";
        HeaderRecRef: RecordRef;
        LineRecRef: RecordRef;
        XmlRequestDoc: XmlDocument;
        RegisterExpirationDate: Boolean;
        SerialExists: Boolean;
        ResultMessage: Text;
        LastBin: Code[20];
        Qty: Decimal;
        QtyBase: Decimal;
        TotalQty: Decimal;
        TotalQtyBase: Decimal;
        UseCrossDock: Boolean;
        PostingRunSuccessful: Boolean;
        PostedDocExists: Boolean;
        CrossDockingCalculationNeeded: Boolean;
        LicensePlateDetected: Boolean;
        BlankLicensePlateDetected: Boolean;
    begin
        // 1. Get the order ID from the XML
        // 2. Get the line registrations from the XML
        // 3. Get the warehouse receipt lines
        // 4. Update the quantities
        // 5. Post the warehouse receipt lines
        // 6. Generate a response for the mobile device
        MobSetup.Get();

        // Make sure that the order still exists
        if not WhseReceiptHeader.Get(OrderID) then
            Error(MobWmsLanguage.GetMessage('UNKNOWN_ORDER'), OrderID);

        // Disable the locktimeout to prevent timeout messages on the mobile device
        LockTimeout(false);

        // Lock the tables to work on
        WhseReceiptHeader.LockTable();
        WhseReceiptLine.LockTable();
        MobWmsRegistration.LockTable();

        // Turn on commit protection to prevent unintentional committing data
        MobDocQueue.Consistent(false);

        // Load the request document from the document queue
        MobDocQueue.LoadXMLRequestDoc(XmlRequestDoc);
        MobRequestMgt.InitCommonFromXmlOrderNode(XmlRequestDoc, TempOrderValues);

        // Save the registrations from the XML in the Mobile WMS Registration table
        OrderID := MobWmsToolbox.SaveRegistrationData(MobDocQueue.MessageIDAsGuid(), XmlRequestDoc, MobWmsRegistration.Type::Receive);

        WhseReceiptHeader.Get(OrderID);
        WhseReceiptHeader.Validate("Posting Date", WorkDate());
        WhseReceiptHeader."MOB Posting MessageId" := MobDocQueue.MessageIDAsGuid();

        // Set the delivery note on the receipt header
        if TempOrderValues.HasValue(DELIVERY_NOTE_Txt) then
            Evaluate(WhseReceiptHeader."Vendor Shipment No.", TempOrderValues.GetValue(DELIVERY_NOTE_Txt));

        // OnAddStepsTo IntegrationEvents
        HeaderRecRef.GetTable(WhseReceiptHeader);
        OnPostReceiveOrder_OnAddStepsToWarehouseReceiptHeader(TempOrderValues, WhseReceiptHeader, TempSteps);
        OnPostReceiveOrder_OnAddStepsToAnyHeader(TempOrderValues, HeaderRecRef, TempSteps);
        if not TempSteps.IsEmpty() then begin
            MobSessionData.SetRegistrationTypeTracking('OnAddStepsTo');
            MobWmsToolbox.DeleteRegistrationData(MobDocQueue.MessageIDAsGuid());
            MobToolbox.CreateResponseWithSteps(XmlResponseDoc, TempSteps);
            MobDocQueue.Consistent(true);
            exit;
        end;

        // OnBeforePost IntegrationEvents
        OnPostReceiveOrder_OnBeforePostWarehouseReceipt(TempOrderValues, WhseReceiptHeader);
        HeaderRecRef.GetTable(WhseReceiptHeader);
        OnPostReceiveOrder_OnBeforePostAnyOrder(TempOrderValues, HeaderRecRef);
        HeaderRecRef.SetTable(WhseReceiptHeader);

        WhseReceiptHeader.Modify(true);

        if not Location.Get(WhseReceiptHeader."Location Code") then
            Clear(Location);

        // Get the real warehouse receipt lines
        // Loop through them and set all "qty to receive" to the registered qty (or zero if the reg. does not exist)
        WhseReceiptLine.SetRange("No.", OrderID);

        // Save the original reservation entrie in case we need to revert (if the posting fails)
        MobSyncItemTracking.SaveOriginalReservationEntriesForWhseReceiptLines(WhseReceiptLine, TempReservationEntryLog);

        if WhseReceiptLine.FindSet() then begin
            repeat
                // Verify Cross-Docking setup for better error message than standard code
                // For better performance, verify the partial condition Location."Use Cross-Docking" before reading item setup in GetUseCrossDock()
                if Location."Use Cross-Docking" and not CrossDockingCalculationNeeded then begin
                    CrossDockMgt.GetUseCrossDock(UseCrossDock, Location."Code", WhseReceiptLine."Item No.");
                    if UseCrossDock then begin
                        Location.TestField("Cross-Dock Bin Code");
                        CrossDockingCalculationNeeded := true;
                    end
                end;

                // Try to find the registrations
                MobWmsRegistration.SetRange("Posting MessageId", MobDocQueue.MessageIDAsGuid());
                MobWmsRegistration.SetRange(Type, MobWmsRegistration.Type::Receive);
                MobWmsRegistration.SetRange("Order No.", OrderID);
                MobWmsRegistration.SetRange("Line No.", WhseReceiptLine."Line No.");
                MobWmsRegistration.SetRange(Handled, false);

                // Scenarios:
                // The line requires item tracking (maybe more than one registration, create reservation entries for each registration)
                // No item tracking (there must only be one registration with the quantity)

                // Determine if item tracking is needed
                // Intentionally not verifying Type=Type::Item as receipt lines are always item lines)
                MobTrackingSetup.DetermineItemTrackingRequiredByWhseReceiptLine(WhseReceiptLine, RegisterExpirationDate);
                // MobTrackingSetup.Tracking: Copy later in MobWmsRegistration loop

                // Initialize the quantity counter
                TotalQty := 0;
                TotalQtyBase := 0;

                // Initialize the last bin variable
                LastBin := '';

                if MobWmsRegistration.FindSet() then begin
                    repeat
                        if MobWmsRegistration."License Plate No." <> '' then
                            LicensePlateDetected := true
                        else
                            BlankLicensePlateDetected := true;

                        if LicensePlateDetected and BlankLicensePlateDetected then
                            Error(MobMixedRegistrationsDetected_Txt);

                        // MobTrackingSetup.TrackingRequired: Determined before (outside inner MobWmsRegistration loop)
                        MobTrackingSetup.CopyTrackingFromRegistration(MobWmsRegistration);

                        // Registrations exist for this line

                        // Receive orders do not handle line splitting.
                        // Return an error if multiple bins are registered on the mobile device
                        if MobWmsRegistration.ToBin <> '' then
                            if LastBin = '' then begin
                                LastBin := MobWmsRegistration.ToBin;
                                WhseReceiptLine.Validate("Bin Code", MobWmsRegistration.ToBin);
                            end else
                                if LastBin <> MobWmsRegistration.ToBin then
                                    Error(MobWmsLanguage.GetMessage('RECV_MULTI_BINS_NOT_ALLOWED'));

                        // Calculate registered quantity and base quantity
                        if MobSetup."Use Base Unit of Measure" then begin
                            Qty := 0; // To ensure best possible rounding the TotalQty will be calculated after the loop
                            QtyBase := MobWmsRegistration.Quantity;
                        end else begin
                            MobWmsRegistration.TestField(UnitOfMeasure, WhseReceiptLine."Unit of Measure Code");
                            Qty := MobWmsRegistration.Quantity;
                            QtyBase := UoMMgt.CalcBaseQty(MobWmsRegistration.Quantity, WhseReceiptLine."Qty. per Unit of Measure");
                        end;

                        TotalQty := TotalQty + Qty;
                        TotalQtyBase := TotalQtyBase + QtyBase;

                        // If the receipt originates from a transfer order the lot number is known and expiration date is not registered
                        // RegisterExpirationDate was calculated using "Source Document" (not "Source Type")
                        if (WhseReceiptLine."Source Type" <> Database::"Transfer Line") then begin
                            if MobTrackingSetup.TrackingRequired() and RegisterExpirationDate then
                                MobWmsRegistration.TestField("Expiration Date");

                            if MobTrackingSetup."Serial No. Required" then begin
                                SerialExists := ItemTrackingMgt.FindInInventory(WhseReceiptLine."Item No.", WhseReceiptLine."Variant Code", MobWmsRegistration.SerialNumber);
                                if SerialExists then
                                    Error(MobWmsLanguage.GetMessage('RECV_KNOWN_SERIAL'), MobWmsRegistration.SerialNumber)
                            end;
                        end;

                        // Synchronize Item Tracking to Source Document
                        MobSyncItemTracking.CreateTempReservEntryForWhseReceiptLine(WhseReceiptLine, MobWmsRegistration, TempReservationEntry, QtyBase);

                        MobWmsToolbox.SaveRegistrationDataFromSource(WhseReceiptLine."Location Code", WhseReceiptLine."Item No.", WhseReceiptLine."Variant Code", MobWmsRegistration);

                        // OnHandle IntegrationEvents -- intentionally do not update WhseReceiptLine (is updated below)
                        OnPostReceiveOrder_OnHandleRegistrationForWarehouseReceiptLine(MobWmsRegistration, WhseReceiptLine, TempReservationEntry);
                        LineRecRef.GetTable(WhseReceiptLine);
                        OnPostReceiveOrder_OnHandleRegistrationForAnyLine(MobWmsRegistration, LineRecRef);
                        LineRecRef.SetTable(WhseReceiptLine);

                        // Set the handled flag to true on the registration
                        MobWmsRegistration.Validate(Handled, true);
                        MobWmsRegistration.Modify();

                    until MobWmsRegistration.Next() = 0;

                    // To ensure best possible rounding the TotalQty is calculated and rounded only once when MobSetup."Use Base Unit of Measure" is enabled (i.e. 3 * 1/3 = 1)
                    if MobSetup."Use Base Unit of Measure" then
                        TotalQty := UoMMgt.CalcQtyFromBase(TotalQtyBase, WhseReceiptLine."Qty. per Unit of Measure");

                    // Set the quantity on the receipt line
                    if (TotalQty > WhseReceiptLine."Qty. Outstanding") and (MobOverReceiptMgt.IsOverReceiptAllowed(WhseReceiptLine)) then begin
                        WhseReceiptLine.Validate("Qty. to Receive", WhseReceiptLine."Qty. Outstanding");
                        MobOverReceiptMgt.ValidateOverReceiptQuantity(WhseReceiptLine, TotalQty - WhseReceiptLine."Qty. to Receive"); // Validate OverReceiptQty separately to support 16.0
                    end else
                        WhseReceiptLine.Validate("Qty. to Receive", TotalQty);

                end else    // endif MobWmsRegistration.FindSet()
                    WhseReceiptLine.Validate("Qty. to Receive", 0);

                // Save the values on the receipt line
                WhseReceiptLine.Modify();

            until WhseReceiptLine.Next() = 0;

            // Calculate cross docking
            if CrossDockingCalculationNeeded then
                if not MobLicensePlateMgt.RelatedLicensePlatesExists(WhseReceiptHeader) then
                    CrossDockMgt.CalculateCrossDockLines(CrossDockOpp, '', OrderID, WhseReceiptHeader."Location Code");

            // Turn off the commit protection
            // From this point on we explicitely clean up committed data if an error occurs
            MobDocQueue.Consistent(true);

            Commit();

            if not MobSyncItemTracking.Run(TempReservationEntry) then begin
                // The created reservation entries might have been committed
                // If the synchronization fails for some reason we need to clean up the created reservation entries
                ResultMessage := GetLastErrorText();
                MobSessionData.SetPreservedLastErrorCallStack();
                MobSyncItemTracking.RevertToOriginalReservationEntriesForWhseReceiptLines(WhseReceiptLine, TempReservationEntryLog);
                Commit();
                UpdateIncomingWhseReceiptOrder(WhseReceiptHeader);
                MobWmsToolbox.DeleteRegistrationData(MobDocQueue.MessageIDAsGuid());
                Commit();   // Separate commit to prevent error in UpdateIncomingWhseReceiptOrder from preventing Reservation Entries being rollback
                Error(ResultMessage);
            end;

            /* #if BC15+ */
            WhsePostReceipt.SetSuppressCommit(not MobSetup."Commit per Source Doc(Receive)");
            /* #endif */
            PostingRunSuccessful := WhsePostReceipt.Run(WhseReceiptLine);

            // If Posted Whse. Receipt exists posting has succeeded but something else failed. ie. partner code OnAfter event
            if not PostingRunSuccessful then
                PostedDocExists := PostedWhseReceiptHeaderExists(WhseReceiptHeader);

            if PostingRunSuccessful or PostedDocExists then begin
                // The posting was successful
                ResultMessage := MobToolbox.GetPostSuccessMessage(PostingRunSuccessful);

                // Commit to allow for codeunit.run
                Commit();

                // Event OnAfterPost
                LineRecRef.GetTable(WhseReceiptLine);
                MobTryEvent.RunEventOnPlannedPosting('OnPostReceiveOrder_OnAfterPostAnyOrder', LineRecRef, TempOrderValues, ResultMessage);

                UpdateIncomingWhseReceiptOrder(WhseReceiptHeader);

            end else begin
                // The created reservation entries have been committed
                // If the posting fails for some reason we need to clean up the created reservation entries
                ResultMessage := GetLastErrorText();
                MobSessionData.SetPreservedLastErrorCallStack();
                MobSyncItemTracking.RevertToOriginalReservationEntriesForWhseReceiptLines(WhseReceiptLine, TempReservationEntryLog);
                Commit();
                UpdateIncomingWhseReceiptOrder(WhseReceiptHeader);
                MobWmsToolbox.DeleteRegistrationData(MobDocQueue.MessageIDAsGuid());
                Commit();   // Separate commit to prevent error in UpdateIncomingWhseReceiptOrder from preventing Reservation Entries being rollback
                Error(ResultMessage);
            end;

            // Create a response inside the <description> element of the document response
            MobToolbox.CreateSimpleResponse(XmlResponseDoc, ResultMessage);
        end;
    end;

    local procedure UpdateIncomingWhseReceiptOrder(var _WhseReceiptHeader: Record "Warehouse Receipt Header")
    begin
        if not _WhseReceiptHeader.Get(_WhseReceiptHeader."No.") then
            exit;

        _WhseReceiptHeader.LockTable();
        _WhseReceiptHeader.Get(_WhseReceiptHeader."No.");
        Clear(_WhseReceiptHeader."MOB Posting MessageId");
        _WhseReceiptHeader.Modify();
    end;

    local procedure PostPurchaseOrder(OrderID: Code[20])
    var
        MobSetup: Record "MOB Setup";
        MobTrackingSetup: Record "MOB Tracking Setup";
        MobWmsRegistration: Record "MOB WMS Registration";
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TempReservationEntryLog: Record "Reservation Entry" temporary;
        TempReservationEntry: Record "Reservation Entry" temporary;
        TempOrderValues: Record "MOB Common Element" temporary;
        TempSteps: Record "MOB Steps Element" temporary;
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        UoMMgt: Codeunit "Unit of Measure Management";
        PurchRelease: Codeunit "Release Purchase Document";
        PurchPost: Codeunit "Purch.-Post";
        MobItemTrackingManagement: Codeunit "MOB Item Tracking Management";
        MobOverReceiptMgt: Codeunit "MOB Over-Receipt Mgt.";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        MobSyncItemTracking: Codeunit "MOB Sync. Item Tracking";
        HeaderRecRef: RecordRef;
        LineRecRef: RecordRef;
        XmlRequestDoc: XmlDocument;
        RegisterExpirationDate: Boolean;
        Qty: Decimal;
        QtyBase: Decimal;
        TotalQty: Decimal;
        TotalQtyBase: Decimal;
        SerialExists: Boolean;
        ResultMessage: Text;
        LotExists: Boolean;
        EntriesExist: Boolean;
        ExistingExpirationDate: Date;
        PostingRunSuccessful: Boolean;
        PostedDocExists: Boolean;
    begin
        MobSetup.Get();

        // Disable the locktimeout to prevent timeout messages on the mobile device
        LockTimeout(false);

        // Lock the tables to work on
        PurchaseHeader.LockTable();
        PurchaseLine.LockTable();
        MobWmsRegistration.LockTable();

        // Turn on commit protection to prevent unintentional committing data
        MobDocQueue.Consistent(false);

        // Load the request document from the document queue
        MobDocQueue.LoadXMLRequestDoc(XmlRequestDoc);
        MobRequestMgt.InitCommonFromXmlOrderNode(XmlRequestDoc, TempOrderValues);

        // Save the registrations from the XML in the Mobile WMS Registration table
        OrderID := MobWmsToolbox.SaveRegistrationData(MobDocQueue.MessageIDAsGuid(), XmlRequestDoc, MobWmsRegistration.Type::"Purchase Order");

        // Make sure that the order still exists
        if not PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, OrderID) then
            Error(MobWmsLanguage.GetMessage('UNKNOWN_ORDER'), OrderID);

        PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, OrderID);
        PurchaseHeader."MOB Posting MessageId" := MobDocQueue.MessageIDAsGuid();

        // Set posting date
        if PurchaseHeader."Posting Date" <> WorkDate() then begin
            PurchRelease.Reopen(PurchaseHeader);
            PurchRelease.SetSkipCheckReleaseRestrictions();
            PurchaseHeader.SetHideValidationDialog(true);   // same behavior when reprocessing from queue ie. no "change exchange rate" confirmation
            PurchaseHeader.Validate("Posting Date", WorkDate());
            PurchRelease.Run(PurchaseHeader);
        end;

        // Set the delivery note on the receipt header
        if TempOrderValues.HasValue(DELIVERY_NOTE_Txt) then
            Evaluate(PurchaseHeader."Vendor Shipment No.", TempOrderValues.GetValue(DELIVERY_NOTE_Txt));

        // OnAddStepsTo IntegrationEvents
        HeaderRecRef.GetTable(PurchaseHeader);
        OnPostReceiveOrder_OnAddStepsToPurchaseHeader(TempOrderValues, PurchaseHeader, TempSteps);
        OnPostReceiveOrder_OnAddStepsToAnyHeader(TempOrderValues, HeaderRecRef, TempSteps);
        if not TempSteps.IsEmpty() then begin
            MobSessionData.SetRegistrationTypeTracking('OnAddStepsTo');
            MobWmsToolbox.DeleteRegistrationData(MobDocQueue.MessageIDAsGuid());
            MobToolbox.CreateResponseWithSteps(XmlResponseDoc, TempSteps);
            MobDocQueue.Consistent(true);
            exit;
        end;

        // OnBeforePost IntegrationEvents
        OnPostReceiveOrder_OnBeforePostPurchaseOrder(TempOrderValues, PurchaseHeader);
        HeaderRecRef.GetTable(PurchaseHeader);
        OnPostReceiveOrder_OnBeforePostAnyOrder(TempOrderValues, HeaderRecRef);
        HeaderRecRef.SetTable(PurchaseHeader);

        PurchaseHeader.Modify(true);

        // Filter the purchase lines
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Document No.", OrderID);

        // Save the original reservation entries in case we need to revert (if the posting fails)
        MobSyncItemTracking.SaveOriginalReservationEntriesForPurchLines(PurchaseLine, TempReservationEntryLog);

        // Loop through the purchase lines
        if PurchaseLine.FindSet() then
            repeat

                // Try to find the registrations
                MobWmsRegistration.SetRange("Posting MessageId", MobDocQueue.MessageIDAsGuid());
                MobWmsRegistration.SetRange(Type, MobWmsRegistration.Type::"Purchase Order");
                MobWmsRegistration.SetRange("Order No.", OrderID);
                MobWmsRegistration.SetRange("Line No.", PurchaseLine."Line No.");
                MobWmsRegistration.SetRange(Handled, false);

                // Line splitting is not supported for purchase orders
                // Before the registrations are processed we need to determine if the user has received to multiple bins
                MobWmsToolbox.ValidateSingleRegistrationBin(MobWmsRegistration);

                // If the registration is found -> set the quantity to handle
                // Else set the quantity to handle to zero (to avoid posting lines with the qty to handle set to something)
                if MobWmsRegistration.FindSet() then begin

                    // IF Location."Bin Mandatory" Bin Code must be validated.
                    if not Location.Get(PurchaseLine."Location Code") then
                        Clear(Location);

                    if Location."Bin Mandatory" and PurchaseLine.IsInventoriableItem() then
                        PurchaseLine.Validate("Bin Code", MobWmsRegistration.ToBin);

                    // Scenarios:
                    // The line requires item tracking (maybe more than one registration, create reservation entries for each registration)
                    // No item tracking (there must only be one registration with the quantity)

                    // Determine if item tracking is needed
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

                        if PurchaseLine.IsInventoriableItem() then begin
                            if MobTrackingSetup.TrackingRequired() and RegisterExpirationDate then
                                MobWmsRegistration.TestField("Expiration Date");

                            // Make sure that the serial number does not exist already
                            // SerialNumber contains only the serial number (unlike earlier version where expiration date was included in same field)
                            if MobTrackingSetup."Serial No. Required" then begin
                                SerialExists := ItemTrackingMgt.FindInInventory(PurchaseLine."No.", PurchaseLine."Variant Code", MobWmsRegistration.SerialNumber);
                                if SerialExists then
                                    Error(MobWmsLanguage.GetMessage('RECV_KNOWN_SERIAL'), MobWmsRegistration.SerialNumber);
                            end;

                            // Make sure LotNumber has same Expiration Date if already on inventory
                            // LotNumber contains only the lot number (unlike earlier version where expiration date was included in same field)
                            if MobTrackingSetup."Lot No. Required" then begin
                                LotExists := MobWmsToolbox.InventoryExistsByLotNo(PurchaseLine."No.", PurchaseLine."Variant Code", MobWmsRegistration.LotNumber);
                                if LotExists then begin
                                    ExistingExpirationDate := MobItemTrackingManagement.ExistingExpirationDate(PurchaseLine."No.",
                                                                                                        PurchaseLine."Variant Code",
                                                                                                        MobTrackingSetup,
                                                                                                        false,
                                                                                                        EntriesExist);

                                    if MobWmsRegistration."Expiration Date" <> ExistingExpirationDate then
                                        Error(MobWmsLanguage.GetMessage('WRONG_EXPIRATION_DATE'), MobWmsToolbox.Date2TextAsDisplayFormat(ExistingExpirationDate), MobWmsRegistration.LotNumber);
                                end;
                            end;
                        end;

                        // Synchronize Item Tracking to Source Document
                        MobSyncItemTracking.CreateTempReservEntryForPurchLine(PurchaseLine, MobWmsRegistration, TempReservationEntry, QtyBase);

                        MobWmsToolbox.SaveRegistrationDataFromSource(PurchaseLine."Location Code", PurchaseLine."No.", PurchaseLine."Variant Code", MobWmsRegistration);

                        // OnHandle IntegrationEvents (PurchaseLine intentionally not modified -- is modified below)
                        OnPostReceiveOrder_OnHandleRegistrationForPurchaseLine(MobWmsRegistration, PurchaseLine, TempReservationEntry);
                        LineRecRef.GetTable(PurchaseLine);
                        OnPostReceiveOrder_OnHandleRegistrationForAnyLine(MobWmsRegistration, LineRecRef);
                        LineRecRef.SetTable(PurchaseLine);

                        // Set the handled flag to true on the registration
                        MobWmsRegistration.Validate(Handled, true);
                        MobWmsRegistration.Modify();

                        if MobTrackingSetup.TrackingRequired() then
                            if TempReservationEntry.Modify() then; // Needed to ensure that the temporary table is written to disk (and thus visible in Item Tracking Management codeunit)

                    until MobWmsRegistration.Next() = 0;

                    // To ensure best possible rounding the TotalQty is calculated and rounded only once when MobSetup."Use Base Unit of Measure" is enabled (i.e. 3 * 1/3 = 1)
                    if MobSetup."Use Base Unit of Measure" then
                        TotalQty := UoMMgt.CalcQtyFromBase(TotalQtyBase, PurchaseLine."Qty. per Unit of Measure");

                    // Set the quantity on the order line
                    if (TotalQtyBase > PurchaseLine."Outstanding Qty. (Base)") and (MobOverReceiptMgt.IsOverReceiptAllowed(PurchaseLine)) then begin
                        PurchaseLine.Validate("Qty. to Receive", PurchaseLine."Outstanding Quantity");
                        MobOverReceiptMgt.ValidateOverReceiptQuantity(PurchaseLine, TotalQty - PurchaseLine."Qty. to Receive");   // Validate OverReceiptQty separately to support 16.0
                    end else
                        PurchaseLine.Validate("Qty. to Receive", TotalQty);

                end else  // endif MobWmsRegistration.FindSet()
                    // No registrations found -> set the quantity to zero
                    PurchaseLine.Validate("Qty. to Receive", 0);

                // Save the values on the purchase line
                PurchaseLine.Modify();

            until PurchaseLine.Next() = 0;

        // Find the purchase header
        PurchaseHeader.SetRange("Document Type", PurchaseLine."Document Type");
        PurchaseHeader.SetRange("No.", PurchaseLine."Document No.");
        if PurchaseHeader.FindFirst() then begin
            PurchaseHeader.Receive := true;
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
            UpdateIncomingPurchaseOrder(PurchaseHeader);
            MobWmsToolbox.DeleteRegistrationData(MobDocQueue.MessageIDAsGuid());
            Commit();   // Separate commit to prevent error in UpdateIncomingPurchase from preventing Reservation Entries being rollback
            Error(ResultMessage);
        end;

        PurchPost.SetSuppressCommit(true);
        PostingRunSuccessful := PurchPost.Run(PurchaseHeader);

        // If Posted Rcpt- Header exists posting has succeeded but something else failed. ie. partner code OnAfter event
        if not PostingRunSuccessful then
            PostedDocExists := PurchRcptHeaderExists(PurchaseHeader);

        // If Posted Purchase Receipt exists posting has succeeded but something else failed. ie. partner code OnAfter event
        if PostingRunSuccessful or PostedDocExists then begin
            // The posting was successful
            ResultMessage := MobToolbox.GetPostSuccessMessage(PostingRunSuccessful);

            // Commit to allow for codeunit.run
            Commit();

            // Event OnAfterPost
            HeaderRecRef.GetTable(PurchaseHeader);
            MobTryEvent.RunEventOnPlannedPosting('OnPostReceiveOrder_OnAfterPostAnyOrder', HeaderRecRef, TempOrderValues, ResultMessage);

            UpdateIncomingPurchaseOrder(PurchaseHeader);

        end else begin
            // The created reservation entries have been committed
            // If the posting fails for some reason we need to clean up the created reservation entries
            ResultMessage := GetLastErrorText();
            MobSessionData.SetPreservedLastErrorCallStack();
            MobSyncItemTracking.RevertToOriginalReservationEntriesForPurchLines(PurchaseLine, TempReservationEntryLog);
            Commit();
            UpdateIncomingPurchaseOrder(PurchaseHeader);
            MobWmsToolbox.DeleteRegistrationData(MobDocQueue.MessageIDAsGuid());
            Commit();   // Separate commit to prevent error in UpdateIncomingPurchase from preventing Reservation Entries being rollback
            Error(ResultMessage);
        end;

        // Create a response inside the <description> element of the document response
        MobToolbox.CreateSimpleResponse(XmlResponseDoc, ResultMessage);
    end;

    local procedure UpdateIncomingPurchaseOrder(var _PurchHeader: Record "Purchase Header")
    begin
        if not _PurchHeader.Get(_PurchHeader."Document Type", _PurchHeader."No.") then
            exit;

        _PurchHeader.LockTable();
        _PurchHeader.Get(_PurchHeader."Document Type", _PurchHeader."No.");
        Clear(_PurchHeader."MOB Posting MessageId");
        _PurchHeader.Modify();
    end;

    local procedure PostTransferOrder(OrderID: Code[20])
    var
        MobSetup: Record "MOB Setup";
        MobTrackingSetup: Record "MOB Tracking Setup";
        Location: Record Location;
        ReservEntry: Record "Reservation Entry";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        MobWmsRegistration: Record "MOB WMS Registration";
        TempOrderValues: Record "MOB Common Element" temporary;
        TempSteps: Record "MOB Steps Element" temporary;
        TransferOrderPostReceipt: Codeunit "TransferOrder-Post Receipt";
        UoMMgt: Codeunit "Unit of Measure Management";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        HeaderRecRef: RecordRef;
        LineRecRef: RecordRef;
        XmlRequestDoc: XmlDocument;
        RegisterExpirationDate: Boolean;
        Qty: Decimal;
        QtyBase: Decimal;
        TotalQty: Decimal;
        TotalQtyBase: Decimal;
        ResultMessage: Text;
        PostingRunSuccessful: Boolean;
        PostedDocExists: Boolean;
    begin
        MobSetup.Get();

        // Disable the locktimeout to prevent timeout messages on the mobile device
        LockTimeout(false);

        // Lock the tables to work on
        TransferHeader.LockTable();
        TransferLine.LockTable();
        MobWmsRegistration.LockTable();

        // Turn on commit protection to prevent unintentional committing data
        MobDocQueue.Consistent(false);

        // Load the request document from the document queue
        MobDocQueue.LoadXMLRequestDoc(XmlRequestDoc);
        MobRequestMgt.InitCommonFromXmlOrderNode(XmlRequestDoc, TempOrderValues);

        // Save the registrations from the XML in the Mobile WMS Registration table
        OrderID := MobWmsToolbox.SaveRegistrationData(MobDocQueue.MessageIDAsGuid(), XmlRequestDoc, MobWmsRegistration.Type::"Transfer Order");

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
        OnPostReceiveOrder_OnAddStepsToTransferHeader(TempOrderValues, TransferHeader, TempSteps);
        OnPostReceiveOrder_OnAddStepsToAnyHeader(TempOrderValues, HeaderRecRef, TempSteps);
        if not TempSteps.IsEmpty() then begin
            MobSessionData.SetRegistrationTypeTracking('OnAddStepsTo');
            MobWmsToolbox.DeleteRegistrationData(MobDocQueue.MessageIDAsGuid());
            MobToolbox.CreateResponseWithSteps(XmlResponseDoc, TempSteps);
            MobDocQueue.Consistent(true);
            exit;
        end;

        // OnBeforePost IntegrationEvents
        OnPostReceiveOrder_OnBeforePostTransferOrder(TempOrderValues, TransferHeader);
        HeaderRecRef.GetTable(TransferHeader);
        OnPostReceiveOrder_OnBeforePostAnyOrder(TempOrderValues, HeaderRecRef);
        HeaderRecRef.SetTable(TransferHeader);

        TransferHeader.Modify(true);

        TransferLine.SetRange("Document No.", OrderID);
        TransferLine.SetRange("Derived From Line No.", 0);
        TransferLine.SetFilter("Item No.", '<>%1', '');

        if TransferLine.FindSet() then
            repeat

                // Try to find the registrations
                MobWmsRegistration.SetRange("Posting MessageId", MobDocQueue.MessageIDAsGuid());
                MobWmsRegistration.SetRange(Type, MobWmsRegistration.Type::"Transfer Order");
                MobWmsRegistration.SetRange("Order No.", OrderID);
                MobWmsRegistration.SetRange("Line No.", TransferLine."Line No.");
                MobWmsRegistration.SetRange(Handled, false);

                // Line splitting is not supported for transfer orders
                // Before the registrations are processed we need to determine if the user has received to multiple bins
                MobWmsToolbox.ValidateSingleRegistrationBin(MobWmsRegistration);

                // Determine if item tracking is needed
                // Intentionally not verifying Type=Type::Item as transfer lines are always item lines
                MobTrackingSetup.DetermineItemTrackingRequiredByTransferLine(TransferLine, true, RegisterExpirationDate);
                // MobTrackingSetup.Tracking: Copy later in MobWmsRegistration loop

                if MobTrackingSetup.TrackingRequired() then begin

                    // The transfer line can have several reservation entries
                    // We need to make sure that the "Quantity to handle" is set to zero before posting is started
                    // The real quantity to handle is set when the registrations from the mobile device is handled
                    ReservEntry.Reset();
                    ReservEntry.SetCurrentKey("Source ID", "Source Ref. No.", "Source Type");
                    ReservEntry.SetRange("Source ID", OrderID);
                    ReservEntry.SetRange("Source Prod. Order Line", TransferLine."Line No.");
                    ReservEntry.SetRange("Source Type", Database::"Transfer Line");
                    if ReservEntry.FindSet() then
                        repeat
                            ReservEntry.Validate("Qty. to Handle (Base)", 0);
                            ReservEntry.Modify();
                        until ReservEntry.Next() = 0;
                end;

                // Initialize the quantity counter
                TotalQty := 0;
                TotalQtyBase := 0;

                if MobWmsRegistration.FindSet() then begin

                    // Transfer-To Bin Code must be validated when Location."Bin Mandatory"
                    Location.Get(TransferLine."Transfer-to Code");
                    if Location."Bin Mandatory" then
                        TransferLine.Validate("Transfer-To Bin Code", MobWmsRegistration.ToBin);

                    repeat
                        // MobTrackingSetup.TrackingRequired: Determined before (outside inner MobWmsRegistration loop)
                        MobTrackingSetup.CopyTrackingFromRegistration(MobWmsRegistration);

                        // All registrations for the transfer line must have same ToBin (same conditions as GetReceiveOrderLines/Set_ToBin)
                        if Location."Bin Mandatory" then
                            MobWmsRegistration.TestField(ToBin, TransferLine."Transfer-To Bin Code")
                        else
                            MobWmsRegistration.TestField(ToBin, MobWmsToolbox.GetItemShelfNo(TransferLine."Item No.", TransferLine."Transfer-to Code", TransferLine."Variant Code"));

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

                        // Item tracking needed -> update reservation entries
                        // For transfer orders only the lot number is registered (never the expiration date)
                        if MobTrackingSetup.TrackingRequired() then begin

                            // Make sure that the tracking exists on inventory if tracking code is populated
                            MobTrackingSetup.CheckTrackingOnInventoryIfNotBlank(TransferLine."Item No.", TransferLine."Variant Code");

                            // Update the Reservation entry with quantity to handle
                            ReservEntry.Reset();
                            ReservEntry.SetCurrentKey("Source ID", "Source Ref. No.", "Source Type");
                            ReservEntry.SetRange("Source ID", MobWmsRegistration."Order No.");
                            ReservEntry.SetRange("Source Prod. Order Line", MobWmsRegistration."Line No.");
                            ReservEntry.SetRange("Source Type", Database::"Transfer Line");
                            ReservEntry.SetRange(MOBPrefixedLineNo, MobWmsRegistration."Prefixed Line No.");

                            MobTrackingSetup.SetTrackingFilterForReservEntryIfRequired(ReservEntry);

                            if ReservEntry.FindFirst() then begin
                                // Update the reservation entry
                                ReservEntry.Validate("Qty. to Handle (Base)", ReservEntry."Qty. to Handle (Base)" + QtyBase);
                                ReservEntry.Modify();

                                // We have only updated the qty to handle so we don't have to worry about restoring
                                // the original reservation entry if the posting fails
                            end;
                        end;

                        MobWmsToolbox.SaveRegistrationDataFromSource(TransferLine."Transfer-to Code", TransferLine."Item No.", TransferLine."Variant Code", MobWmsRegistration);

                        // OnHandle IntegrationEvents
                        OnPostReceiveOrder_OnHandleRegistrationForTransferLine(MobWmsRegistration, TransferLine);
                        LineRecRef.GetTable(TransferLine);
                        OnPostReceiveOrder_OnHandleRegistrationForAnyLine(MobWmsRegistration, LineRecRef);
                        LineRecRef.SetTable(TransferLine);
                        TransferLine.Modify();

                        // Set the handled flag to true on the registration
                        MobWmsRegistration.Validate(Handled, true);
                        MobWmsRegistration.Modify();

                    until MobWmsRegistration.Next() = 0;

                    // To ensure best possible rounding the TotalQty is calculated and rounded only once when MobSetup."Use Base Unit of Measure" is enabled (i.e. 3 * 1/3 = 1)
                    if MobSetup."Use Base Unit of Measure" then
                        TotalQty := UoMMgt.CalcQtyFromBase(TotalQtyBase, TransferLine."Qty. per Unit of Measure");

                    TransferLine.Validate("Qty. to Receive", TotalQty);

                end else  // endif MobWmsRegistration.FindSet()
                    // No registrations for this line -> set quantity to zero
                    TransferLine.Validate("Qty. to Receive", 0);

                // Save the values on the transfer line
                TransferLine.Modify();
            until TransferLine.Next() = 0;

        TransferHeader.SetRange("No.", TransferLine."Document No.");
        if TransferHeader.FindFirst() then; // To avoid error - if (unlikely) record does not exist the posting will error


        MobDocQueue.Consistent(true);

        Commit();

        TransferOrderPostReceipt.SetSuppressCommit(true);
        PostingRunSuccessful := TransferOrderPostReceipt.Run(TransferHeader);

        // If Posted Transfer Receipt exists posting has succeeded but something else failed. ie. partner code OnAfter event
        if not PostingRunSuccessful then
            PostedDocExists := TransferReceiptHeaderExists(TransferHeader);

        if PostingRunSuccessful or PostedDocExists then begin
            // The posting was successful
            ResultMessage := MobToolbox.GetPostSuccessMessage(PostingRunSuccessful);

            // Commit to allow for codeunit.run
            Commit();

            // Event OnAfterPost
            HeaderRecRef.GetTable(TransferHeader);
            MobTryEvent.RunEventOnPlannedPosting('OnPostReceiveOrder_OnAfterPostAnyOrder', HeaderRecRef, TempOrderValues, ResultMessage);

            UpdateIncomingTransferOrder(TransferHeader);

        end else begin
            // We have only updated the qty to handle so we don't have to worry about restoring
            // the original reservation entry if the posting fails
            ResultMessage := GetLastErrorText();
            MobSessionData.SetPreservedLastErrorCallStack();
            UpdateIncomingTransferOrder(TransferHeader);
            MobWmsToolbox.DeleteRegistrationData(MobDocQueue.MessageIDAsGuid());
            Commit();
            Error(ResultMessage);
        end;

        // Create a response inside the <description> element of the document response
        MobToolbox.CreateSimpleResponse(XmlResponseDoc, ResultMessage);
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

    local procedure PostSalesReturnOrder()
    var
        MobSetup: Record "MOB Setup";
        MobTrackingSetup: Record "MOB Tracking Setup";
        MobWmsRegistration: Record "MOB WMS Registration";
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TempReservationEntryLog: Record "Reservation Entry" temporary;
        TempReservationEntry: Record "Reservation Entry" temporary;
        TempOrderValues: Record "MOB Common Element" temporary;
        TempSteps: Record "MOB Steps Element" temporary;
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        UoMMgt: Codeunit "Unit of Measure Management";
        SalesPost: Codeunit "Sales-Post";
        MobItemTrackingManagement: Codeunit "MOB Item Tracking Management";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        SalesRelease: Codeunit "Release Sales Document";
        MobSyncItemTracking: Codeunit "MOB Sync. Item Tracking";
        HeaderRecRef: RecordRef;
        LineRecRef: RecordRef;
        XmlRequestDoc: XmlDocument;
        RegisterExpirationDate: Boolean;
        OrderID: Code[20];
        ResultMessage: Text;
        Qty: Decimal;
        QtyBase: Decimal;
        TotalQty: Decimal;
        TotalQtyBase: Decimal;
        SerialExists: Boolean;
        LotExists: Boolean;
        EntriesExist: Boolean;
        ExistingExpirationDate: Date;
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

        MobSetup.Get();

        // Disable the locktimeout to prevent timeout messages on the mobile device
        LockTimeout(false);

        // Lock the tables to work on
        SalesHeader.LockTable();
        SalesLine.LockTable();
        MobWmsRegistration.LockTable();

        // Turn on commit protection to prevent unintentional committing data
        MobDocQueue.Consistent(false);

        // Load the request document from the document queue
        MobDocQueue.LoadXMLRequestDoc(XmlRequestDoc);
        MobRequestMgt.InitCommonFromXmlOrderNode(XmlRequestDoc, TempOrderValues);

        // Save the registrations from the XML in the Mobile WMS Registration table
        // The function returns the order id without the prefix
        OrderID := MobWmsToolbox.SaveRegistrationData(MobDocQueue.MessageIDAsGuid(), XmlRequestDoc, MobWmsRegistration.Type::"Sales Return Order");

        // Update the sales header
        SalesHeader.Get(SalesHeader."Document Type"::"Return Order", OrderID);

        // Set posting
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
        OnPostReceiveOrder_OnAddStepsToSalesReturnHeader(TempOrderValues, SalesHeader, TempSteps);
        OnPostReceiveOrder_OnAddStepsToAnyHeader(TempOrderValues, HeaderRecRef, TempSteps);
        if not TempSteps.IsEmpty() then begin
            MobSessionData.SetRegistrationTypeTracking('OnAddStepsTo');
            MobWmsToolbox.DeleteRegistrationData(MobDocQueue.MessageIDAsGuid());
            MobToolbox.CreateResponseWithSteps(XmlResponseDoc, TempSteps);
            MobDocQueue.Consistent(true);
            exit;
        end;

        // OnBeforePost IntegrationEvents
        OnPostReceiveOrder_OnBeforePostSalesReturnOrder(TempOrderValues, SalesHeader);
        HeaderRecRef.GetTable(SalesHeader);
        OnPostReceiveOrder_OnBeforePostAnyOrder(TempOrderValues, HeaderRecRef);
        HeaderRecRef.SetTable(SalesHeader);

        SalesHeader.Modify();

        // Filter the sales lines
        SalesLine.SetRange("Document Type", SalesHeader."Document Type"::"Return Order");
        SalesLine.SetRange("Document No.", OrderID);

        // Save the original reservation entries in case we need to revert (if the posting fails)
        MobSyncItemTracking.SaveOriginalReservationEntriesForSalesLines(SalesLine, TempReservationEntryLog);

        if SalesLine.FindSet() then
            repeat

                // Try to find the registrations
                MobWmsRegistration.SetRange("Posting MessageId", MobDocQueue.MessageIDAsGuid());
                MobWmsRegistration.SetRange(Type, MobWmsRegistration.Type::"Sales Return Order");
                MobWmsRegistration.SetRange("Order No.", OrderID);
                MobWmsRegistration.SetRange("Line No.", SalesLine."Line No.");
                MobWmsRegistration.SetRange(Handled, false);

                // Line splitting is not supported for sales return orders
                // Before the registrations are processed we need to determine if the user has received to multiple bins
                MobWmsToolbox.ValidateSingleRegistrationBin(MobWmsRegistration);

                // If the registration is found -> set the quantity to handle
                // Else set the quantity to handle to zero (to avoid posting lines with the qty to handle set to something)
                if MobWmsRegistration.FindSet() then begin

                    if not Location.Get(SalesLine."Location Code") then
                        Clear(Location);

                    // Transfer-To Bin Code must be validated when Location."Bin Mandatory"
                    if Location."Bin Mandatory" and SalesLine.IsInventoriableItem() then
                        SalesLine.Validate("Bin Code", MobWmsRegistration.ToBin);

                    SalesLine.TestField("Qty. per Unit of Measure");

                    // Scenarios:
                    // The line requires item tracking (maybe more than one registration, create reservation entries for each registration)
                    // No item tracking (there must only be one registration with the quantity)

                    // Determine if item tracking is needed
                    MobTrackingSetup.DetermineItemTrackingRequiredBySalesLine(SalesLine, RegisterExpirationDate);
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
                            MobWmsRegistration.TestField(UnitOfMeasure, SalesLine."Unit of Measure Code");
                            Qty := MobWmsRegistration.Quantity;
                            QtyBase := UoMMgt.CalcBaseQty(MobWmsRegistration.Quantity, SalesLine."Qty. per Unit of Measure");
                        end;

                        TotalQty := TotalQty + Qty;
                        TotalQtyBase := TotalQtyBase + QtyBase;

                        if SalesLine.IsInventoriableItem() then begin
                            if MobTrackingSetup.TrackingRequired() and RegisterExpirationDate then
                                MobWmsRegistration.TestField("Expiration Date");

                            // Make sure that the serial number does not exist already
                            // SerialNumber contains only the serial number (unlike earlier version where expiration date was included in same field)
                            if MobTrackingSetup."Serial No. Required" then begin
                                SerialExists := ItemTrackingMgt.FindInInventory(SalesLine."No.", SalesLine."Variant Code", MobWmsRegistration.SerialNumber);
                                if SerialExists then
                                    Error(MobWmsLanguage.GetMessage('RECV_KNOWN_SERIAL'), MobWmsRegistration.SerialNumber);
                            end;

                            // Handle lot numbers and expiration dates
                            // Make sure LotNumber has same Expiration Date if already on inventory
                            // LotNumber contains only the lot number (unlike earlier version where expiration date was included in same field)
                            if MobTrackingSetup."Lot No. Required" then begin
                                LotExists := MobWmsToolbox.InventoryExistsByLotNo(SalesLine."No.", SalesLine."Variant Code", MobWmsRegistration.LotNumber);
                                if LotExists then begin
                                    ExistingExpirationDate := MobItemTrackingManagement.ExistingExpirationDate(SalesLine."No.",
                                                                                                        SalesLine."Variant Code",
                                                                                                        MobTrackingSetup,
                                                                                                        false,
                                                                                                        EntriesExist);

                                    if MobWmsRegistration."Expiration Date" <> ExistingExpirationDate then
                                        Error(MobWmsLanguage.GetMessage('WRONG_EXPIRATION_DATE'), MobWmsToolbox.Date2TextAsDisplayFormat(ExistingExpirationDate), MobWmsRegistration.LotNumber);
                                end;
                            end;
                        end;

                        // Synchronize Item Tracking to Source Document
                        MobSyncItemTracking.CreateTempReservEntryForSalesLine(SalesLine, MobWmsRegistration, TempReservationEntry, QtyBase);

                        MobWmsToolbox.SaveRegistrationDataFromSource(SalesLine."Location Code", SalesLine."No.", SalesLine."Variant Code", MobWmsRegistration);

                        // OnHandle IntegrationEvents (SalesLine intentionally not modified -- is modified below)
                        OnPostReceiveOrder_OnHandleRegistrationForSalesReturnLine(MobWmsRegistration, SalesLine, TempReservationEntry);
                        LineRecRef.GetTable(SalesLine);
                        OnPostReceiveOrder_OnHandleRegistrationForAnyLine(MobWmsRegistration, LineRecRef);
                        LineRecRef.SetTable(SalesLine);

                        // Remember that the registration was handled
                        MobWmsRegistration.Validate(Handled, true);
                        MobWmsRegistration.Modify();

                    until MobWmsRegistration.Next() = 0;

                    // To ensure best possible rounding the TotalQty is calculated and rounded only once when MobSetup."Use Base Unit of Measure" is enabled (i.e. 3 * 1/3 = 1)
                    if MobSetup."Use Base Unit of Measure" then
                        TotalQty := UoMMgt.CalcQtyFromBase(TotalQtyBase, SalesLine."Qty. per Unit of Measure");

                    SalesLine.Validate("Return Qty. to Receive", TotalQty);
                end else  // endif MobWmsRegistration.FindSet()
                    SalesLine.Validate("Return Qty. to Receive", 0);

                SalesLine.Modify();

            until SalesLine.Next() = 0;

        // Find the sales header
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::"Return Order");
        SalesHeader.SetRange("No.", SalesLine."Document No.");
        if SalesHeader.FindFirst() then begin
            SalesHeader.Receive := true;
            SalesHeader.Invoice := false;
            SalesHeader.Modify();
        end;

        // Turn off the commit protection
        // From this point on we explicitely clean up committed data if an error occurs
        MobDocQueue.Consistent(true);

        Commit();

        // Post
        if not MobSyncItemTracking.Run(TempReservationEntry) then begin
            ResultMessage := GetLastErrorText();
            MobSessionData.SetPreservedLastErrorCallStack();
            MobSyncItemTracking.RevertToOriginalReservationEntriesForSalesLines(SalesLine, TempReservationEntryLog);
            Commit();
            UpdateIncomingSalesReturnOrder(SalesHeader);
            MobWmsToolbox.DeleteRegistrationData(MobDocQueue.MessageIDAsGuid());
            Commit();   // Separate commit to prevent error in UpdateIncomingPurchase from preventing Reservation Entries being rollback
            Error(ResultMessage);
        end;

        // SuppressCommit do not fully work for SalesReturnOrder, but is still included to at least improve the 
        // change of good rollbacks if customer creates eventsubscriptions to standard posting events.
        SalesPost.SetSuppressCommit(true);
        PostingRunSuccessful := SalesPost.Run(SalesHeader);

        // If Posted Return Receipt exists posting has succeeded but something else failed. ie. partner code OnAfter event
        if not PostingRunSuccessful then
            PostedDocExists := ReturnReceiptHeaderExists(SalesHeader);

        if PostingRunSuccessful or PostedDocExists then begin
            // The posting was successful
            ResultMessage := MobToolbox.GetPostSuccessMessage(PostingRunSuccessful);

            // Commit to allow for codeunit.run
            Commit();

            // Event OnAfterPost
            HeaderRecRef.GetTable(SalesHeader);
            MobTryEvent.RunEventOnPlannedPosting('OnPostReceiveOrder_OnAfterPostAnyOrder', HeaderRecRef, TempOrderValues, ResultMessage);

            UpdateIncomingSalesReturnOrder(SalesHeader);
        end else begin

            // The created reservation entries have been committed
            // If the posting fails for some reason we need to clean up the created reservation entries and MobWmsRegistrations
            ResultMessage := GetLastErrorText();
            MobSessionData.SetPreservedLastErrorCallStack();
            MobSyncItemTracking.RevertToOriginalReservationEntriesForSalesLines(SalesLine, TempReservationEntryLog);
            Commit();
            UpdateIncomingSalesReturnOrder(SalesHeader);
            MobWmsToolbox.DeleteRegistrationData(MobDocQueue.MessageIDAsGuid());
            Commit();
            Error(ResultMessage);
        end;

        // Create a response inside the <description> element of the document response
        MobToolbox.CreateSimpleResponse(XmlResponseDoc, ResultMessage);
    end;

    local procedure UpdateIncomingSalesReturnOrder(var _SalesReturnHeader: Record "Sales Header")
    begin
        if not _SalesReturnHeader.Get(_SalesReturnHeader."Document Type", _SalesReturnHeader."No.") then
            exit;

        _SalesReturnHeader.LockTable();
        _SalesReturnHeader.Get(_SalesReturnHeader."Document Type", _SalesReturnHeader."No.");
        Clear(_SalesReturnHeader."MOB Posting MessageId");
        _SalesReturnHeader.Modify();
    end;

    //
    // ------- MISC. HELPER -------
    //

    local procedure GetDefaultBin(_ItemNo: Code[20]; _LocationCode: Code[20]; _VariantCode: Code[10]): Code[20]
    var
        BinContent: Record "Bin Content";
        bin: Record Bin;
    begin
        BinContent.SetCurrentKey(Default, "Location Code", "Item No.", "Variant Code", "Bin Code");
        BinContent.SetRange(Default, true);
        BinContent.SetRange("Item No.", _ItemNo);
        BinContent.SetRange("Location Code", _LocationCode);
        BinContent.SetRange("Variant Code", _VariantCode);
        if BinContent.FindFirst() then
            exit(BinContent."Bin Code");

        bin.SetRange("Location Code", _LocationCode);
        bin.SetRange(Default, true);
        if bin.FindFirst() then
            exit(bin.Code)
        else
            exit('');
    end;

    local procedure GetReceiptDate_FromWhseReceipt(_ReceiptNo: Code[20]): Date
    var
        WhseReceiptLine: Record "Warehouse Receipt Line";
        PurchaseLine: Record "Purchase Line";
        TransferHeader: Record "Transfer Header";
    begin
        WhseReceiptLine.SetRange("No.", _ReceiptNo);

        // There is no support for receipt lines from multiple senders (vendors)
        if WhseReceiptLine.FindFirst() then
            case WhseReceiptLine."Source Type" of
                Database::"Purchase Line":
                    if PurchaseLine.Get(PurchaseLine."Document Type"::Order, WhseReceiptLine."Source No.", WhseReceiptLine."Source Line No.") then
                        exit(PurchaseLine."Expected Receipt Date");
                Database::"Transfer Line":
                    if TransferHeader.Get(WhseReceiptLine."Source No.") then
                        exit(TransferHeader."Receipt Date");
                Database::"Sales Line":
                    exit(WhseReceiptLine."Due Date");
            end;
    end;

    local procedure GetReceiptDate_FromPurchase(_PurchHeaderNo: Code[20]): Date
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Document No.", _PurchHeaderNo);
        PurchaseLine.SetFilter(Type, '<>%1', PurchaseLine.Type::" ");
        PurchaseLine.SetFilter("Expected Receipt Date", '<>%1', 0D);
        if PurchaseLine.FindFirst() then
            exit(PurchaseLine."Expected Receipt Date")
        else
            exit(0D);
    end;

    local procedure GetVendor_FromWhseReceipt(_ReceiptNo: Code[20]; _MaxNoOfLines: Integer) _Sender: Text
    var
        WhseReceiptLine: Record "Warehouse Receipt Line";
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        TransferHeader: Record "Transfer Header";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        SenderList: List of [Text];
    begin
        WhseReceiptLine.SetCurrentKey("No.", "Source Type", "Source No.", "Source Line No.");
        WhseReceiptLine.SetRange("No.", _ReceiptNo);

        // Create unique senders list to support lines from multiple senders (vendors, sales return customers)
        if WhseReceiptLine.FindSet() then
            repeat
                WhseReceiptLine.SetRange("Source Type", WhseReceiptLine."Source Type");
                WhseReceiptLine.SetRange("Source No.", WhseReceiptLine."Source No.");

                case WhseReceiptLine."Source Type" of
                    Database::"Sales Line":
                        if SalesHeader.Get(SalesHeader."Document Type"::"Return Order", WhseReceiptLine."Source No.") then
                            MobToolbox.AddUniqueText(SenderList, SalesHeader."Sell-to Customer Name")
                        else
                            MobToolbox.AddUniqueText(SenderList, MobWmsLanguage.GetMessage('NOT_AVAILABLE'));
                    Database::"Purchase Line":
                        if PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, WhseReceiptLine."Source No.") then
                            MobToolbox.AddUniqueText(SenderList, PurchaseHeader."Buy-from Vendor Name")
                        else
                            MobToolbox.AddUniqueText(SenderList, MobWmsLanguage.GetMessage('NOT_AVAILABLE'));
                    Database::"Transfer Line":
                        if TransferHeader.Get(WhseReceiptLine."Source No.") then
                            if TransferHeader."Transfer-from Name" <> '' then
                                MobToolbox.AddUniqueText(SenderList, MobWmsLanguage.GetMessage('INBOUND_TRANSFER_LABEL') + ': ' + TransferHeader."Transfer-from Name")
                            else
                                MobToolbox.AddUniqueText(SenderList, MobWmsLanguage.GetMessage('INBOUND_TRANSFER_LABEL') + ': ' + TransferHeader."Transfer-from Code")
                        else
                            MobToolbox.AddUniqueText(SenderList, MobWmsLanguage.GetMessage('NOT_AVAILABLE'));
                    else
                        MobToolbox.AddUniqueText(SenderList, MobWmsLanguage.GetMessage('NOT_AVAILABLE'));
                end;

                WhseReceiptLine.FindLast();
                WhseReceiptLine.SetRange("Source Type");
                WhseReceiptLine.SetRange("Source No.");
            until WhseReceiptLine.Next() = 0;

        // Combine unique senderlist to a single string
        _Sender := CopyStr(MobWmsToolbox.List2TextLn(SenderList, _MaxNoOfLines), 1, MaxStrLen(_Sender));
        exit(_Sender);
    end;

    local procedure GetVendor_FromPurchase(_PurchHeaderNo: Code[20]): Text
    var
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        MobWmsLanguage: Codeunit "MOB WMS Language";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Document No.", _PurchHeaderNo);
        PurchaseLine.SetFilter(Type, '<>%1', PurchaseLine.Type::" ");
        PurchaseLine.SetFilter("Buy-from Vendor No.", '<>%1', '');
        if PurchaseLine.FindFirst() then begin
            if not Vendor.Get(PurchaseLine."Buy-from Vendor No.") then
                Vendor.Name := '';
            exit(Vendor.Name);
        end else
            exit(MobWmsLanguage.GetMessage('NOT_AVAILABLE'));
    end;

    local procedure GetSourceTypeNo(_ReceiptNo: Code[20]; _MaxNoOfLines: Integer) _SourceTypeNo: Text[250]
    var
        WhseReceiptLine: Record "Warehouse Receipt Line";
        SourceTypeNoList: List of [Text];
    begin
        // with WhseReceiptLine do begin
        WhseReceiptLine.SetCurrentKey("No.", "Source Document", "Source No.");
        WhseReceiptLine.SetRange("No.", _ReceiptNo);

        // Combine receipt lines from multiple senders into one string (vendors)
        if WhseReceiptLine.FindFirst() then
            repeat
                WhseReceiptLine.SetRange("Source Document", WhseReceiptLine."Source Document");
                WhseReceiptLine.SetRange("Source No.", WhseReceiptLine."Source No.");

                MobToolbox.AddUniqueText(SourceTypeNoList, Format(WhseReceiptLine."Source Document") + ' ' + Format(WhseReceiptLine."Source No."));

                WhseReceiptLine.FindLast();
                WhseReceiptLine.SetRange("Source No.");
                WhseReceiptLine.SetRange("Source Document");
            until WhseReceiptLine.Next() = 0;

        // i.e. "Purchase Order 104013\r\nPurchase Order 104014\r\nSales Return Order 1001"
        _SourceTypeNo := CopyStr(MobWmsToolbox.List2TextLn(SourceTypeNoList, _MaxNoOfLines), 1, MaxStrLen(_SourceTypeNo));
        exit(_SourceTypeNo);
        // end;
    end;

    local procedure CreateWhseReceipt(_PurchaseOrderNumber: Code[20])
    var
        Location: Record Location;
        PurchHeader: Record "Purchase Header";
        WhseReceiptLine: Record "Warehouse Receipt Line";
        WhseRqst: Record "Warehouse Request";
        GetSourceDocuments: Report "Get Source Documents";
        ReleasePurchDoc: Codeunit "Release Purchase Document";
    begin
        // This function will automatically create a warehouse receipt for the PO if it is missing

        // First we do some basic validation
        // - Does the PO exist
        if not PurchHeader.Get(PurchHeader."Document Type"::Order, _PurchaseOrderNumber) then
            exit;

        // Does the location from the PO require warehouse receipts
        if PurchHeader."Location Code" = '' then
            exit;

        Location.Get(PurchHeader."Location Code");
        if Location."Require Receive" = false then
            exit;

        // - Does a warehouse receipt exists for this PO. If yes then stop
        WhseReceiptLine.SetRange("Source No.", _PurchaseOrderNumber);
        if not WhseReceiptLine.IsEmpty() then
            exit;

        // Determine if the PO is Open or Released
        // - Open -> Release
        // - Relased -> do nothing
        if PurchHeader.Status = PurchHeader.Status::Open then
            ReleasePurchDoc.PerformManualRelease(PurchHeader);


        // Now create the warehouse receipt
        // This code is copied from the GetSourceDocInbound.CreateFromPurchOrder (CU 5751)
        // It is copied because the function ends by opening the warehouse receipt form and this is not desired when running without UI
        WhseRqst.SetRange(Type, WhseRqst.Type::Inbound);
        WhseRqst.SetRange("Source Type", Database::"Purchase Line");
        WhseRqst.SetRange("Source Subtype", PurchHeader."Document Type");
        WhseRqst.SetRange("Source No.", PurchHeader."No.");
        WhseRqst.SetRange("Document Status", WhseRqst."Document Status"::Released);

        if WhseRqst.FindFirst() then begin
            // This disables the message "There are no Warehouse Receipt Lines created."
            // This will happen when the order has been posted and PO filtering has been used
            GetSourceDocuments.SetHideDialog(true);
            GetSourceDocuments.UseRequestPage(false);
            GetSourceDocuments.SetTableView(WhseRqst);
            GetSourceDocuments.RunModal();
        end;
    end;

    local procedure SetOrderIDAndType(_BackendID: Code[30]; var _OrderID: Code[20]; var _OrderType: Option PurchaseOrder,TransferOrder,SalesReturnOrder,WhseReceiptOrder)
    begin
        // Identify the whether Order Type is Warehouse Related, Purchase etc.
        case CopyStr(_BackendID, 1, 3) of
            'PO-':
                _OrderType := _OrderType::PurchaseOrder;
            'TO-':
                _OrderType := _OrderType::TransferOrder;
            'SR-':
                _OrderType := _OrderType::SalesReturnOrder;
            else
                _OrderType := _OrderType::WhseReceiptOrder;
        end;

        if _OrderType <> _OrderType::WhseReceiptOrder then
            _OrderID := CopyStr(_BackendID, 4, StrLen(_BackendID))
        else
            _OrderID := _BackendID;
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
        OnGetReceiveOrders_OnAfterSetCurrentKey(TempHeaderElementCustomView);
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
        OnGetReceiveOrderLines_OnAfterSetCurrentKey(TempLineElementCustomView);
        _BaseOrderLineElement.SetView(TempLineElementCustomView.GetView());
    end;

    local procedure SetFromWarehouseReceiptHeader(_WhseReceiptHeader: Record "Warehouse Receipt Header"; var _BaseOrder: Record "MOB NS BaseDataModel Element")
    var
        MobWmsLanguage: Codeunit "MOB WMS Language";
        RecRef: RecordRef;
    begin
        // Add the data elements to the <Order> element
        _BaseOrder.Init();
        _BaseOrder.Set_BackendID(_WhseReceiptHeader."No.");

        _BaseOrder.Set_DisplayLine1(GetVendor_FromWhseReceipt(_WhseReceiptHeader."No.", 3));
        _BaseOrder.Set_DisplayLine2(MobWmsToolbox.Date2TextAsDisplayFormat(GetReceiptDate_FromWhseReceipt(_WhseReceiptHeader."No.")));
        _BaseOrder.Set_DisplayLine3(_WhseReceiptHeader."No.");
        _BaseOrder.Set_DisplayLine4(GetSourceTypeNo(_WhseReceiptHeader."No.", 3));

        _BaseOrder.Set_HeaderLabel1(MobWmsLanguage.GetMessage('ORDER_NUMBER'));
        _BaseOrder.Set_HeaderLabel2(MobWmsLanguage.GetMessage('SENDER'));
        _BaseOrder.Set_HeaderValue1(_WhseReceiptHeader."No.");
        _BaseOrder.Set_HeaderValue2(_BaseOrder.Get_DisplayLine1());

        RecRef.GetTable(_WhseReceiptHeader);
        SetFromAnyHeader(RecRef, _BaseOrder);
        OnGetReceiveOrders_OnAfterSetFromWarehouseReceiptHeader(_WhseReceiptHeader, _BaseOrder);
        OnGetReceiveOrders_OnAfterSetFromAnyHeader(RecRef, _BaseOrder);
    end;

    local procedure SetFromPurchaseHeader(_PurchHeader: Record "Purchase Header"; var _BaseOrder: Record "MOB NS BaseDataModel Element")
    var
        MobWmsLanguage: Codeunit "MOB WMS Language";
        RecRef: RecordRef;
    begin
        // Add the data elements to the <Order> element
        _BaseOrder.Init();
        _BaseOrder.Set_BackendID('PO-' + _PurchHeader."No.");

        _BaseOrder.Set_DisplayLine1(GetVendor_FromPurchase(_PurchHeader."No."));
        _BaseOrder.Set_DisplayLine2(MobWmsToolbox.Date2TextAsDisplayFormat(GetReceiptDate_FromPurchase(_PurchHeader."No.")));
        _BaseOrder.Set_DisplayLine3(_PurchHeader."No.");

        _BaseOrder.Set_HeaderLabel1(MobWmsLanguage.GetMessage('ORDER_NUMBER'));
        _BaseOrder.Set_HeaderLabel2(MobWmsLanguage.GetMessage('SENDER'));
        _BaseOrder.Set_HeaderValue1(_PurchHeader."No.");
        _BaseOrder.Set_HeaderValue2(GetVendor_FromPurchase(_PurchHeader."No."));

        RecRef.GetTable(_PurchHeader);
        SetFromAnyHeader(RecRef, _BaseOrder);
        OnGetReceiveOrders_OnAfterSetFromPurchaseHeader(_PurchHeader, _BaseOrder);
        OnGetReceiveOrders_OnAfterSetFromAnyHeader(RecRef, _BaseOrder);
    end;

    local procedure SetFromTransferHeader(_TransferHeader: Record "Transfer Header"; var _BaseOrder: Record "MOB NS BaseDataModel Element")
    var
        FromLocation: Record Location;
        ToLocation: Record Location;
        MobWmsLanguage: Codeunit "MOB WMS Language";
        RecRef: RecordRef;
    begin
        // Add the data elements to the <Order> element
        _BaseOrder.Init();
        _BaseOrder.Set_BackendID('TO-' + _TransferHeader."No.");

        // Decide what to show on the lines
        _BaseOrder.Set_DisplayLine1(MobWmsLanguage.GetMessage('INBOUND_TRANSFER_LABEL') + ' ' + _TransferHeader."No.");

        _BaseOrder.Set_DisplayLine2(
            (FromLocation.Get(_TransferHeader."Transfer-from Code")) and (FromLocation.Name <> ''),
            StrSubstNo(MobWmsLanguage.GetMessage('FROM'), FromLocation.Name),
            StrSubstNo(MobWmsLanguage.GetMessage('FROM'), _TransferHeader."Transfer-from Code"));

        _BaseOrder.Set_DisplayLine3(
            (ToLocation.Get(_TransferHeader."Transfer-to Code")) and (ToLocation.Name <> ''),
            StrSubstNo(MobWmsLanguage.GetMessage('TO'), ToLocation.Name),
            StrSubstNo(MobWmsLanguage.GetMessage('TO'), _TransferHeader."Transfer-to Code"));

        _BaseOrder.Set_HeaderLabel1(MobWmsLanguage.GetMessage('ORDER_NUMBER'));
        _BaseOrder.Set_HeaderLabel2(MobWmsLanguage.GetMessage('SENDER'));
        _BaseOrder.Set_HeaderValue1(_TransferHeader."No.");
        _BaseOrder.Set_HeaderValue2(FromLocation.Name <> '', FromLocation.Name, _TransferHeader."Transfer-from Code");

        RecRef.GetTable(_TransferHeader);
        SetFromAnyHeader(RecRef, _BaseOrder);
        OnGetReceiveOrders_OnAfterSetFromTransferHeader(_TransferHeader, _BaseOrder);
        OnGetReceiveOrders_OnAfterSetFromAnyHeader(RecRef, _BaseOrder);
    end;

    local procedure SetFromSalesReturnHeader(_SalesReturnHeader: Record "Sales Header"; var _BaseOrder: Record "MOB NS BaseDataModel Element")
    var
        Location: Record Location;
        MobWmsLanguage: Codeunit "MOB WMS Language";
        RecRef: RecordRef;
    begin
        // Add the data elements to the <Order> element
        _BaseOrder.Init();
        _BaseOrder.Set_BackendID('SR-' + _SalesReturnHeader."No.");

        _BaseOrder.Set_DisplayLine1(MobWmsLanguage.GetMessage('RETURN_ORDER_LABEL') + ' ' + _SalesReturnHeader."No.");
        _BaseOrder.Set_DisplayLine2(_SalesReturnHeader."Sell-to Customer Name" <> '', _SalesReturnHeader."Sell-to Customer Name", _SalesReturnHeader."Sell-to Customer No.");

        if Location.Get(_SalesReturnHeader."Location Code") then
            _BaseOrder.Set_DisplayLine3(Location.Name <> '', Location.Name, Location.Code)
        else
            _BaseOrder.Set_DisplayLine3('');

        _BaseOrder.Set_HeaderLabel1(MobWmsLanguage.GetMessage('ORDER_NUMBER'));
        _BaseOrder.Set_HeaderLabel2(MobWmsLanguage.GetMessage('SENDER'));
        _BaseOrder.Set_HeaderValue1(_SalesReturnHeader."No.");
        _BaseOrder.Set_HeaderValue2(_SalesReturnHeader."Sell-to Customer Name");

        RecRef.GetTable(_SalesReturnHeader);
        SetFromAnyHeader(RecRef, _BaseOrder);
        OnGetReceiveOrders_OnAfterSetFromSalesReturnHeader(_SalesReturnHeader, _BaseOrder);
        OnGetReceiveOrders_OnAfterSetFromAnyHeader(RecRef, _BaseOrder);
    end;

    local procedure SetFromAnyHeader(var _RecRef: RecordRef; var _BaseOrder: Record "MOB NS BaseDataModel Element")
    begin
        _BaseOrder.Set_ReferenceID(_RecRef);
        _BaseOrder.Set_Status();     // Set Locked/Has Attachment symbol (1=Unlocked, 2=Locked, 3=Attachment)
    end;

    local procedure SetFromWarehouseReceiptLine(_WhseReceiptLine: Record "Warehouse Receipt Line"; var _BaseOrderLine: Record "MOB NS BaseDataModel Element")
    var
        MobSetup: Record "MOB Setup";
        MobTrackingSetup: Record "MOB Tracking Setup";
        TempSteps: Record "MOB Steps Element" temporary;
        Location: Record Location;
        Item: Record Item;
        MobOverReceiptMgt: Codeunit "MOB Over-Receipt Mgt.";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        MobWmsLicensePlateReceive: Codeunit "MOB WMS License Plate Receive";
        RecRef: RecordRef;
        ExpDateRequired: Boolean;
    begin
        MobSetup.Get();

        // Add the data to the order line element
        _BaseOrderLine.Init();
        _BaseOrderLine.Set_OrderBackendID(_WhseReceiptLine."No.");
        _BaseOrderLine.Set_LineNumber(_WhseReceiptLine."Line No.");

        // There is no FromBin in receiving
        _BaseOrderLine.Set_FromBin('');
        _BaseOrderLine.Set_ValidateFromBin(false);

        // If the receive order is used without put-away then we must register the ToBin
        Location.Get(_WhseReceiptLine."Location Code");
        if ((Location."Require Put-away" = false) and Location."Bin Mandatory") then begin
            // Receive is used without put-away -> use bin
            _BaseOrderLine.Set_ToBin(_WhseReceiptLine."Bin Code");
            _BaseOrderLine.Set_ValidateToBin(true);
        end else begin
            // Put-away is used -> do not use bin unless receipt bin is missing
            _BaseOrderLine.Set_ToBin('');
            _BaseOrderLine.Set_ValidateToBin((_WhseReceiptLine."Bin Code" = '') and (Location."Bin Mandatory"));
        end;

        _BaseOrderLine.Set_Location(Location.Code);

        _BaseOrderLine.Set_ItemNumber(_WhseReceiptLine."Item No.");
        _BaseOrderLine.Set_ItemBarcode(MobItemReferenceMgt.GetBarcodeList(_WhseReceiptLine."Item No.", _WhseReceiptLine."Variant Code", _WhseReceiptLine."Unit of Measure Code"));
        _BaseOrderLine.Set_Description(_WhseReceiptLine.Description);

        // Determine if serial / lot number / package number registration is needed
        Clear(MobTrackingSetup);
        MobTrackingSetup.DetermineItemTrackingRequiredByWhseReceiptLine(_WhseReceiptLine, ExpDateRequired);
        // MobTrackingSetup.Tracking: Tracking values are unused in this scope

        _BaseOrderLine.SetTracking(MobTrackingSetup);   // Set empty "Serial No." / "Lot No." / "Package No." to include tags in xml
        _BaseOrderLine.SetRegisterTracking(MobTrackingSetup);
        _BaseOrderLine.Set_RegisterExpirationDate(ExpDateRequired);

        // If the <RegisterQuantityByScan> element is set to true the mobile device can use values in <BarcodeQuantity>
        // element to register the quantity associated with barcode instead of always registering 1.                        
        _BaseOrderLine.Set_RegisterQuantityByScan(false);

        if MobSetup."Use Base Unit of Measure" then begin
            // The mobile device always works in the base unit of measure
            Item.Get(_WhseReceiptLine."Item No.");
            _BaseOrderLine.Set_Quantity(_WhseReceiptLine."Qty. Outstanding (Base)");
            _BaseOrderLine.Set_UnitOfMeasure(Item."Base Unit of Measure");
        end else begin
            _BaseOrderLine.Set_Quantity(_WhseReceiptLine."Qty. Outstanding");
            _BaseOrderLine.Set_UnitOfMeasure(_WhseReceiptLine."Unit of Measure Code");
        end;

        // Decide what to display on the lines
        // There are 5 display lines available in the standard configuration
        // Line 1: Show the Item Number
        // Line 2: Show the UoM under the quantity (this is handled in the UserRole.xml on the mobile device)
        // Line 3: Show the Item Description
        // Line 4: Show the Item Variant
        // IF Require Put-Away
        // Line 1: Show the Bin
        // Line 2: Show the Item Number + UoM under the quantity (this is handled in the UserRole.xml on the mobile device)
        // Line 3: Show the Item Description
        // Line 4: Show the Item Variant
        if ((Location."Require Put-away" = false) and Location."Require Receive") then begin
            _BaseOrderLine.Set_DisplayLine1(_WhseReceiptLine."Bin Code");
            _BaseOrderLine.Set_DisplayLine2(_WhseReceiptLine."Item No.");
        end else begin
            _BaseOrderLine.Set_DisplayLine1(_WhseReceiptLine."Item No.");
            _BaseOrderLine.Set_DisplayLine2('');
        end;
        _BaseOrderLine.Set_DisplayLine3(_WhseReceiptLine.Description);
        _BaseOrderLine.Set_DisplayLine4(_WhseReceiptLine."Variant Code" <> '', MobWmsLanguage.GetMessage('VARIANT_LABEL') + ': ' + _WhseReceiptLine."Variant Code", '');

        // Allow Bin Change (not relevant during receive)
        _BaseOrderLine.Set_AllowBinChange(true);

        // if License Plating is enabled then show and enable the "Print LP" action on the mobile device
        if MobSetup.LicensePlatingIsEnabled() then
            _BaseOrderLine.Set_MenuItemStateConfiguration('LicensePlatingEnabled', true, 1);

        // Under-/OverDeliveryValidation - The choices are: None, Warn, Block
        _BaseOrderLine.Set_UnderDeliveryValidation('Warn');
        _BaseOrderLine.Set_OverDeliveryValidation(MobOverReceiptMgt.IsOverReceiptAllowed(_WhseReceiptLine), 'None', 'Block');

        RecRef.GetTable(_WhseReceiptLine);
        SetFromAnyLine(RecRef, _BaseOrderLine);
        OnGetReceiveOrderLines_OnAfterSetFromWarehouseReceiptLine(_WhseReceiptLine, _BaseOrderLine);
        OnGetReceiveOrderLines_OnAfterSetFromAnyLine(RecRef, _BaseOrderLine);

        TempSteps.SetMustCallCreateNext(true);
        
        // Check if LP handling is required and add steps accordingly
        MobWmsLicensePlateReceive.HandleToLicensePlateStep(RecRef, _BaseOrderLine, TempSteps);
        
        OnGetReceiveOrderLines_OnAddStepsToAnyLine(RecRef, _BaseOrderLine, TempSteps);

        if not TempSteps.IsEmpty() then
            _BaseOrderLine.Set_Workflow(TempSteps, "MOB TweakType"::Append);
    end;

    local procedure SetFromPurchaseLine(_PurchLine: Record "Purchase Line"; var _BaseOrderLine: Record "MOB NS BaseDataModel Element")
    var
        MobSetup: Record "MOB Setup";
        MobTrackingSetup: Record "MOB Tracking Setup";
        TempSteps: Record "MOB Steps Element" temporary;
        Location: Record Location;
        Item: Record Item;
        MobOverReceiptMgt: Codeunit "MOB Over-Receipt Mgt.";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        RecRef: RecordRef;
        ExpDateRequired: Boolean;
    begin
        MobSetup.Get();

        // Add the data to the order line element
        _BaseOrderLine.Init();
        _BaseOrderLine.Set_OrderBackendID('PO-' + _PurchLine."Document No.");
        _BaseOrderLine.Set_LineNumber(_PurchLine."Line No.");

        // There is no FromBin in receiving
        _BaseOrderLine.Set_FromBin('');
        _BaseOrderLine.Set_ValidateFromBin(false);

        // If the receive order is used without put-away then we must register the ToBin
        if _PurchLine.IsInventoriableItem() and Location.Get(_PurchLine."Location Code") and Location."Bin Mandatory" then begin
            // Bins are used
            // It is always allowed to use another bin than the suggested
            // In the posting function we verify that the user only registers one bin to avoid line splitting
            _BaseOrderLine.Set_ToBin(GetDefaultBin(_PurchLine."No.", _PurchLine."Location Code", _PurchLine."Variant Code"));
            _BaseOrderLine.Set_ValidateToBin(true);
            _BaseOrderLine.Set_AllowBinChange(true);
        end else begin
            // Bins are not used (or location not found), use SKU/Item."Shelf No."
            // Change of bin (shelf), is not allowed because bin is only saved on Item Ledger Entries
            _BaseOrderLine.Set_ToBin(MobWmsToolbox.GetItemShelfNo(_PurchLine."No.", _PurchLine."Location Code", _PurchLine."Variant Code"));
            _BaseOrderLine.Set_ValidateToBin(_BaseOrderLine.Get_ToBin() <> '');
            _BaseOrderLine.Set_AllowBinChange(false);
        end;

        _BaseOrderLine.Set_Location(Location.Code);
        _BaseOrderLine.Set_ItemNumber(_PurchLine."No.");

        if _PurchLine.Type = _PurchLine.Type::Item then
            _BaseOrderLine.Set_ItemBarcode(MobItemReferenceMgt.GetBarcodeList(_PurchLine."No.", _PurchLine."Variant Code", _PurchLine."Unit of Measure Code"))
        else
            _BaseOrderLine.Set_ItemBarcode(_PurchLine."No.");  // Fallback to No. for non-item types

        _BaseOrderLine.Set_Description(_PurchLine.Description);

        // Determine if serial / lot number registration is needed
        Clear(MobTrackingSetup);
        MobTrackingSetup.DetermineItemTrackingRequiredByPurchaseLine(_PurchLine, ExpDateRequired);
        // MobTrackingSetup.Tracking: Tracking values are unused in this scope

        _BaseOrderLine.SetTracking(MobTrackingSetup);   // Set empty "Serial No." / "Lot No." / "Package No." to include tags in xml
        _BaseOrderLine.SetRegisterTracking(MobTrackingSetup);
        _BaseOrderLine.Set_RegisterExpirationDate(ExpDateRequired);

        // If the <RegisterQuantityByScan> element is set to true the mobile device can use values in <BarcodeQuantity>
        // element to register the quantity associated with barcode instead of always registering 1.            
        _BaseOrderLine.Set_RegisterQuantityByScan(false);

        if MobSetup."Use Base Unit of Measure" and Item.Get(_PurchLine."No.") then begin
            // The mobile device always works in the base unit of measure
            _BaseOrderLine.Set_Quantity(_PurchLine."Outstanding Qty. (Base)");
            _BaseOrderLine.Set_UnitOfMeasure(Item."Base Unit of Measure");
        end else begin
            _BaseOrderLine.Set_Quantity(_PurchLine."Outstanding Quantity");
            _BaseOrderLine.Set_UnitOfMeasure(_PurchLine."Unit of Measure Code");
        end;

        // Add DisplayLines
        // There are 4 display lines available in the standard configuration
        // Line 1: Show the Bin
        // Line 2: Show the Item Number + UoM under the quantity (this is handled in the UserRole.xml on the mobile device)
        // Line 3: Show the Item Description
        // Line 4: Show the Item Variant
        _BaseOrderLine.Set_DisplayLine1(_BaseOrderLine.Get_ToBin() <> '', _BaseOrderLine.Get_ToBin(), MobWmsLanguage.GetMessage('NO_BIN'));
        _BaseOrderLine.Set_DisplayLine2(_PurchLine."No.");
        _BaseOrderLine.Set_DisplayLine3(_PurchLine.Description);
        _BaseOrderLine.Set_DisplayLine4(_PurchLine."Variant Code" <> '', MobWmsLanguage.GetMessage('VARIANT_LABEL') + ': ' + _PurchLine."Variant Code", '');
        _BaseOrderLine.Set_DisplayLine5('');

        // Under-/OverDeliveryValidation - The choices are: None, Warn, Block
        _BaseOrderLine.Set_UnderDeliveryValidation('Warn');
        _BaseOrderLine.Set_OverDeliveryValidation(MobOverReceiptMgt.IsOverReceiptAllowed(_PurchLine), 'None', 'Block');

        RecRef.GetTable(_PurchLine);
        SetFromAnyLine(RecRef, _BaseOrderLine);
        OnGetReceiveOrderLines_OnAfterSetFromPurchaseLine(_PurchLine, _BaseOrderLine);
        OnGetReceiveOrderLines_OnAfterSetFromAnyLine(RecRef, _BaseOrderLine);

        TempSteps.SetMustCallCreateNext(true);
        OnGetReceiveOrderLines_OnAddStepsToAnyLine(RecRef, _BaseOrderLine, TempSteps);
        if not TempSteps.IsEmpty() then
            _BaseOrderLine.Set_Workflow(TempSteps, "MOB TweakType"::Append);
    end;

    local procedure SetFromTransferLine(
        _TransferLine: Record "Transfer Line";
        _ReservEntryNo: Integer;
        _PrefixedLineNumber: Text;
        _MobTrackingSetup: Record "MOB Tracking Setup";
        _Quantity: Decimal;
        _UoM: Code[10];
        var _BaseOrderLine: Record "MOB NS BaseDataModel Element")
    var
        Location: Record Location;
        TempSteps: Record "MOB Steps Element" temporary;
        MobWmsLanguage: Codeunit "MOB WMS Language";
        RecRef: RecordRef;
    begin
        // Add the data to the order line element
        _BaseOrderLine.Init();
        _BaseOrderLine.Set_OrderBackendID('TO-' + _TransferLine."Document No.");
        _BaseOrderLine.Set_LineNumber(_PrefixedLineNumber);

        // There is no FromBin in receiving
        _BaseOrderLine.Set_FromBin('');
        _BaseOrderLine.Set_ValidateFromBin(false);

        // If bins are mandatory or if a shelf has been defined (no bin)
        // then we validate where received item is placed
        Location.Get(_TransferLine."Transfer-to Code");
        if Location."Bin Mandatory" then begin
            // Bin is mandatory -> use bin
            // It is always allowed to use another bin than the suggested
            // In the posting function we verify that the user only registers one bin to avoid line splitting
            _BaseOrderLine.Set_ToBin(GetDefaultBin(_TransferLine."Item No.", _TransferLine."Transfer-to Code", _TransferLine."Variant Code"));
            _BaseOrderLine.Set_ValidateToBin(true);
            _BaseOrderLine.Set_AllowBinChange(true);
        end else begin
            // Bins are not used, use SKU/Item."Shelf No."
            //Change of bin (shelf), is not allowed because bin is only saved on Item Ledger Entries
            _BaseOrderLine.Set_ToBin(MobWmsToolbox.GetItemShelfNo(_TransferLine."Item No.", _TransferLine."Transfer-to Code", _TransferLine."Variant Code"));
            _BaseOrderLine.Set_ValidateToBin(_BaseOrderLine.Get_ToBin() <> '');
            _BaseOrderLine.Set_AllowBinChange(false);
        end;

        _BaseOrderLine.Set_Location(Location.Code);
        _BaseOrderLine.Set_ItemNumber(_TransferLine."Item No.");
        _BaseOrderLine.Set_ItemBarcode(MobItemReferenceMgt.GetBarcodeList(_TransferLine."Item No.", _TransferLine."Variant Code", _TransferLine."Unit of Measure Code"));
        _BaseOrderLine.Set_Description(_TransferLine.Description);

        _BaseOrderLine.SetTracking(_MobTrackingSetup);

        _BaseOrderLine.SetRegisterTracking(_MobTrackingSetup);
        _BaseOrderLine.Set_RegisterExpirationDate(false);   // Never register expiration dates on transfer orders

        // If the <RegisterQuantityByScan> element is set to true the mobile device can use values in <BarcodeQuantity>
        // element to register the quantity associated with barcode instead of always registering 1.            
        _BaseOrderLine.Set_RegisterQuantityByScan(false);

        // The mobile device always works in the base unit of measure
        _BaseOrderLine.Set_Quantity(_Quantity);
        _BaseOrderLine.Set_UnitOfMeasure(_UoM);

        // Decide what to display on the lines
        // There are 5 display lines available in the standard configuration
        // Line 1: Show the Bin
        // Line 2: Show the Item Number + UoM under the quantity (this is handled in the UserRole.xml on the mobile device)
        // Line 3: Show the Item Description
        // Line 4: Show the Lot/Serial/Package info
        // Line 5: Show the Item Variant
        _BaseOrderLine.Set_DisplayLine1(_BaseOrderLine.Get_ToBin() <> '', _BaseOrderLine.Get_ToBin(), MobWmsLanguage.GetMessage('NO_BIN'));
        _BaseOrderLine.Set_DisplayLine2(_TransferLine."Item No.");
        _BaseOrderLine.Set_DisplayLine3(_TransferLine.Description);
        _BaseOrderLine.Set_DisplayLine4(_MobTrackingSetup.FormatTracking());
        _BaseOrderLine.Set_DisplayLine5(_TransferLine."Variant Code" <> '', MobWmsLanguage.GetMessage('VARIANT_LABEL') + ': ' + _TransferLine."Variant Code", '');

        // Under-/OverDeliveryValidation - The choices are: None, Warn, Block
        _BaseOrderLine.Set_UnderDeliveryValidation('Warn');
        _BaseOrderLine.Set_OverDeliveryValidation('Block');

        RecRef.GetTable(_TransferLine);
        SetFromAnyLine(RecRef, _BaseOrderLine);
        OnGetReceiveOrderLines_OnAfterSetFromTransferLine(_TransferLine, _ReservEntryNo, _BaseOrderLine);
        OnGetReceiveOrderLines_OnAfterSetFromAnyLine(RecRef, _BaseOrderLine);

        TempSteps.SetMustCallCreateNext(true);
        OnGetReceiveOrderLines_OnAddStepsToAnyLine(RecRef, _BaseOrderLine, TempSteps);
        if not TempSteps.IsEmpty() then
            _BaseOrderLine.Set_Workflow(TempSteps, "MOB TweakType"::Append);
    end;

    local procedure SetFromSalesReturnLine(_SalesReturnLine: Record "Sales Line"; var _BaseOrderLine: Record "MOB NS BaseDataModel Element")
    var
        MobSetup: Record "MOB Setup";
        MobTrackingSetup: Record "MOB Tracking Setup";
        TempSteps: Record "MOB Steps Element" temporary;
        Location: Record Location;
        Item: Record Item;
        MobWmsLanguage: Codeunit "MOB WMS Language";
        RecRef: RecordRef;
        ExpDateRequired: Boolean;
    begin
        MobSetup.Get();

        // Add the data to the order line element
        _BaseOrderLine.Init();
        _BaseOrderLine.Set_OrderBackendID('SR-' + _SalesReturnLine."Document No.");
        _BaseOrderLine.Set_LineNumber(_SalesReturnLine."Line No.");

        if _SalesReturnLine.IsInventoriableItem() and Location.Get(_SalesReturnLine."Location Code") and Location."Bin Mandatory" then begin
            // Bins are used
            // It is always allowed to use another bin than the suggested
            // In the posting function we verify that the user only registers one bin to avoid line splitting
            _BaseOrderLine.Set_ToBin(GetDefaultBin(_SalesReturnLine."No.", _SalesReturnLine."Location Code", _SalesReturnLine."Variant Code"));
            _BaseOrderLine.Set_ValidateToBin(true);
            _BaseOrderLine.Set_AllowBinChange(true);
        end else begin
            // Bins are not used (or Location not found), use SKU/Item."Shelf No."
            // Change of bin (shelf), is not allowed because bin is only saved on Item Ledger Entries
            _BaseOrderLine.Set_ToBin(MobWmsToolbox.GetItemShelfNo(_SalesReturnLine."No.", _SalesReturnLine."Location Code", _SalesReturnLine."Variant Code"));
            _BaseOrderLine.Set_ValidateToBin(_BaseOrderLine.Get_ToBin() <> '');
            _BaseOrderLine.Set_AllowBinChange(false);
        end;

        _BaseOrderLine.Set_Location(Location.Code);
        _BaseOrderLine.Set_ItemNumber(_SalesReturnLine."No.");

        if _SalesReturnLine.Type = _SalesReturnLine.Type::Item then
            _BaseOrderLine.Set_ItemBarcode(_SalesReturnLine.Type = _SalesReturnLine.Type::Item, MobItemReferenceMgt.GetBarcodeList(_SalesReturnLine."No.", _SalesReturnLine."Variant Code", _SalesReturnLine."Unit of Measure Code"), _SalesReturnLine."No.")
        else
            _BaseOrderLine.Set_ItemBarcode(_SalesReturnLine."No.");  // Fallback to No. for non-item types

        _BaseOrderLine.Set_Description(_SalesReturnLine.Description);

        // Determine if serial / lot number registration is needed
        MobTrackingSetup.DetermineItemTrackingRequiredBySalesLine(_SalesReturnLine, ExpDateRequired);
        _BaseOrderLine.SetTracking(MobTrackingSetup);
        _BaseOrderLine.SetRegisterTracking(MobTrackingSetup);
        _BaseOrderLine.Set_RegisterExpirationDate(ExpDateRequired);

        // If the <RegisterQuantityByScan> element is set to true the mobile device can use values in <BarcodeQuantity>
        // element to register the quantity associated with barcode instead of always registering 1.            
        _BaseOrderLine.Set_RegisterQuantityByScan(false);

        if MobSetup."Use Base Unit of Measure" and Item.Get(_SalesReturnLine."No.") then begin
            // The quantity on the mobile device is always in base UoM
            _BaseOrderLine.Set_Quantity(_SalesReturnLine."Outstanding Qty. (Base)");
            _BaseOrderLine.Set_UnitOfMeasure(Item."Base Unit of Measure");
        end else begin
            _BaseOrderLine.Set_Quantity(_SalesReturnLine."Outstanding Quantity");
            _BaseOrderLine.Set_UnitOfMeasure(_SalesReturnLine."Unit of Measure Code");
        end;

        // Set which values that should be displayed on the line
        _BaseOrderLine.Set_DisplayLine1(_SalesReturnLine."No.");
        _BaseOrderLine.Set_DisplayLine2(_SalesReturnLine.Description);
        _BaseOrderLine.Set_DisplayLine3('');
        _BaseOrderLine.Set_DisplayLine4(
            _BaseOrderLine.Get_ToBin() <> '',
            MobWmsLanguage.GetMessage('TO_BIN_LABEL') + ': ' + _BaseOrderLine.Get_ToBin() + '  ' + MobWmsLanguage.GetMessage('UOM_LABEL') + ': ' + _BaseOrderLine.Get_UnitOfMeasure(),
            MobWmsLanguage.GetMessage('UOM_LABEL') + ': ' + _BaseOrderLine.Get_UnitOfMeasure());
        _BaseOrderLine.Set_DisplayLine5(
            _SalesReturnLine."Variant Code" <> '',
            MobWmsLanguage.GetMessage('VARIANT_LABEL') + ': ' + _SalesReturnLine."Variant Code",
            '');

        // Under-/OverDeliveryValidation - The choices are: None, Warn, Block
        _BaseOrderLine.Set_UnderDeliveryValidation('Warn');
        _BaseOrderLine.Set_OverDeliveryValidation('Block');

        RecRef.GetTable(_SalesReturnLine);
        SetFromAnyLine(RecRef, _BaseOrderLine);
        OnGetReceiveOrderLines_OnAfterSetFromSalesReturnLine(_SalesReturnLine, _BaseOrderLine);
        OnGetReceiveOrderLines_OnAfterSetFromAnyLine(RecRef, _BaseOrderLine);

        TempSteps.SetMustCallCreateNext(true);
        OnGetReceiveOrderLines_OnAddStepsToAnyLine(RecRef, _BaseOrderLine, TempSteps);
        if not TempSteps.IsEmpty() then
            _BaseOrderLine.Set_Workflow(TempSteps, "MOB TweakType"::Append);
    end;

    local procedure SetFromAnyLine(var _RecRef: RecordRef; var _BaseOrderLine: Record "MOB NS BaseDataModel Element")
    begin
        _BaseOrderLine.Set_RegisterQuantityByScan(false);
        _BaseOrderLine.Set_RegisteredQuantity('0');

        _BaseOrderLine.Set_ReferenceID(_RecRef);
        _BaseOrderLine.Set_Status('0');
        _BaseOrderLine.Set_Attachment();
        _BaseOrderLine.Set_ItemImageID();
    end;

    local procedure PurchRcptHeaderExists(_PurchHeader: Record "Purchase Header"): Boolean
    var
        PurchRcptHeader: Record "Purch. Rcpt. Header";
    begin
        PurchRcptHeader.SetRange("Order No.", _PurchHeader."No.");
        PurchRcptHeader.SetRange("MOB MessageId", _PurchHeader."MOB Posting MessageId");
        exit(not PurchRcptHeader.IsEmpty());
    end;

    local procedure PostedWhseReceiptHeaderExists(_WhseReceiptHeader: Record "Warehouse Receipt Header"): Boolean
    var
        PostedWhseReceiptHeader: Record "Posted Whse. Receipt Header";
    begin
        PostedWhseReceiptHeader.SetRange("Whse. Receipt No.", _WhseReceiptHeader."No.");
        PostedWhseReceiptHeader.SetRange("MOB MessageId", _WhseReceiptHeader."MOB Posting MessageId");
        exit(not PostedWhseReceiptHeader.IsEmpty());
    end;

    local procedure TransferReceiptHeaderExists(_TransferHeader: Record "Transfer Header"): Boolean
    var
        TransferReceiptHeader: Record "Transfer Receipt Header";
    begin
        TransferReceiptHeader.SetRange("Transfer Order No.", _TransferHeader."No.");
        TransferReceiptHeader.SetRange("MOB MessageId", _TransferHeader."MOB Posting MessageId");
        exit(not TransferReceiptHeader.IsEmpty());
    end;

    local procedure ReturnReceiptHeaderExists(_SalesHeader: Record "Sales Header"): Boolean
    var
        ReturnReceiptHeader: Record "Return Receipt Header";
    begin
        ReturnReceiptHeader.SetRange("Return Order No.", _SalesHeader."No.");
        ReturnReceiptHeader.SetRange("MOB MessageId", _SalesHeader."MOB Posting MessageId");
        exit(not ReturnReceiptHeader.IsEmpty());
    end;

    //
    // ------- IntegrationEvents: GetReceiveOrders -------
    //
    // OnSetFilterWarehouseReceipt
    // OnSetFilterPurchaseOrder
    // OnSetFilterTransferOrder
    // OnSetFilterSalesReturnOrder

    // OnIncludeWarehouseReceiptHeader          from  'GetReceiveOrders'.GetOrders().GetWarehouseReceipts()
    // OnIncludePurchaseHeader                  from  'GetReceiveOrders'.GetOrders().GetPurchaseOrders()
    // OnIncludeTransferHeader                  from  'GetReceiveOrders'.GetOrders().GetTransferOrders()
    // OnIncludeSalesReturnHeader               from  'GetReceiveOrders'.GetOrders().GetSalesReturnOrders()

    // OnAfterSetFromWarehouseReceiptHeader     from  'GetReceiveOrders'.GetOrders().GetWarehouseReceipts().CreateWhseReceiptResponse().SetFromWhseReceiptHeader()
    // OnAfterSetFromPurchaseHeader             from  'GetReceiveOrders'.GetOrders().GetPurchaseOrders().CreatePurchHeaderResponse().SetFromPurchHeader()
    // OnAfterSetFromTransferHeader             from  'GetReceiveOrders'.GetOrders().GetTransferOrders().CreateTransferHeaderResponse().SetFromTransferHeader()
    // OnAfterSetFromSalesReturnHeader          from  'GetReceiveOrders'.GetOrders().GetSalesReturnOrders().CreateSalesReturnHeaderResp().SetFromSalesReturnHeader()
    // OnAfterSetFromAnyHeader                  from  'GetReceiveOrders'.GetOrders().[...].SetFromXXXHeader()

    // OnAfterSetCurrentKey                     from  'GetReceiveOrders'.AddOrderElements()

    [IntegrationEvent(false, false)]
    local procedure OnGetReceiveOrders_OnSetFilterWarehouseReceipt(_HeaderFilter: Record "MOB NS Request Element"; var _WhseReceiptHeader: Record "Warehouse Receipt Header"; var _WhseReceiptLine: Record "Warehouse Receipt Line"; var _IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetReceiveOrders_OnSetFilterPurchaseOrder(_HeaderFilter: Record "MOB NS Request Element"; var _PurchHeader: Record "Purchase Header"; var _PurchLine: Record "Purchase Line"; var _IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetReceiveOrders_OnSetFilterTransferOrder(_HeaderFilter: Record "MOB NS Request Element"; var _TransferHeader: Record "Transfer Header"; var _TransferLine: Record "Transfer Line"; var _IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetReceiveOrders_OnSetFilterSalesReturnOrder(_HeaderFilter: Record "MOB NS Request Element"; var _SalesReturnHeader: Record "Sales Header"; var _SalesReturnLine: Record "Sales Line"; var _IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnGetReceiveOrders_OnIncludeWarehouseReceiptHeader(_WhseReceiptHeader: Record "Warehouse Receipt Header"; var _HeaderFilters: Record "MOB NS Request Element"; var _IncludeInOrderList: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnGetReceiveOrders_OnIncludePurchaseHeader(_PurchHeader: Record "Purchase Header"; var _HeaderFilters: Record "MOB NS Request Element"; var _IncludeInOrderList: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnGetReceiveOrders_OnIncludeTransferHeader(_TransferHeader: Record "Transfer Header"; var _HeaderFilters: Record "MOB NS Request Element"; var _IncludeInOrderList: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnGetReceiveOrders_OnIncludeSalesReturnHeader(_SalesReturnHeader: Record "Sales Header"; var _HeaderFilters: Record "MOB NS Request Element"; var _IncludeInOrderList: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetReceiveOrders_OnAfterSetFromWarehouseReceiptHeader(_WhseReceiptHeader: Record "Warehouse Receipt Header"; var _BaseOrderElement: Record "MOB NS BaseDataModel Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetReceiveOrders_OnAfterSetFromPurchaseHeader(_PurchHeader: Record "Purchase Header"; var _BaseOrderElement: Record "MOB NS BaseDataModel Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetReceiveOrders_OnAfterSetFromTransferHeader(_TransferHeader: Record "Transfer Header"; var _BaseOrderElement: Record "MOB NS BaseDataModel Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetReceiveOrders_OnAfterSetFromSalesReturnHeader(_SalesReturnHeader: Record "Sales Header"; var _BaseOrderElement: Record "MOB NS BaseDataModel Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetReceiveOrders_OnAfterSetFromAnyHeader(_RecRef: RecordRef; var _BaseOrderElement: Record "MOB NS BaseDataModel Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetReceiveOrders_OnAfterSetCurrentKey(var _BaseOrderElementView: Record "MOB NS BaseDataModel Element")
    begin
    end;

    //
    // ------- IntegrationEvents: GetReceiveOrderLines -------
    //
    // OnSetFilterWarehouseReceiptLine        from  'GetReceiveOrderLines'
    // OnSetFilterPurchaseLine                from  'GetReceiveOrderLines'
    // OnSetFilterTransferLine                from  'GetReceiveOrderLines'
    // OnSetFilterSalesReturnLine             from  'GetReceiveOrderLines'

    // OnIncludeWarehouseReceiptLine          from  'GetReceiveOrderLines'.GetOrderLines().CreateWhseReceiptLinesResponse()
    // OnIncludePurchaseLine                  from  'GetReceiveOrderLines'.GetOrderLines().CreatePurchaseLinesResponse()
    // OnIncludeTransferLine                  from  'GetReceiveOrderLines'.GetOrderLines().CreateTransferLinesResponse()
    // OnIncludeSalesReturnLine               from  'GetReceiveOrderLines'.GetOrderLines().CreateSalesReturnLinesResponse()

    // OnAfterSetFromWarehouseReceiptLine     from  'GetReceiveOrderLines'.GetOrderLines().CreateWhseReceiptLinesResponse().SetFromWhseReceiptLine()
    // OnAfterSetFromPurchaseLine             from  'GetReceiveOrderLines'.GetOrderLines().CreatePurchaseLinesResponse().SetFromPurchaseLine()
    // OnAfterSetFromTransferLine             from  'GetReceiveOrderLines'.GetOrderLines().CreateTransferLinesResponse().CreateTransferLine().SetFromTransferLine()
    // OnAfterSetFromSalesReturnLine          from  'GetReceiveOrderLines'.GetOrderLines().CreateSalesReturnLinesResponse().SetFromSalesReturnLine()
    // OnAfterSetFromAnyLine                  from  'GetReceiveOrderLines'.GetOrderLines().[...].SetFromXXXLine()

    // OnAfterSetCurrentKey                   from  'GetReceiveOrderLines'.AddOrderLineElements()

    // OnAddStepsToAnyHeader                  from  'GetReceiveOrderLines'.GetOrderLines().CreateXXXResponse().AddStepsOnAnyHeader
    // OnAddStepsToAnyLine                    from  'GetReceiveOrderLines'.GetOrderLines().[...].SetFromXXXLine()

    [IntegrationEvent(false, false)]
    local procedure OnGetReceiveOrderLines_OnSetFilterWarehouseReceiptLine(var _WhseReceiptLine: Record "Warehouse Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetReceiveOrderLines_OnSetFilterPurchaseLine(var _PurchLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetReceiveOrderLines_OnSetFilterTransferLine(var _TransferLine: Record "Transfer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetReceiveOrderLines_OnSetFilterSalesReturnLine(var _SalesReturnLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetReceiveOrderLines_OnIncludeWarehouseReceiptLine(_WhseReceiptLine: Record "Warehouse Receipt Line"; var _IncludeInOrderLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetReceiveOrderLines_OnIncludePurchaseLine(_PurchLine: Record "Purchase Line"; var _IncludeInOrderLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetReceiveOrderLines_OnIncludeTransferLine(_TransferLine: Record "Transfer Line"; var _IncludeInOrderLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetReceiveOrderLines_OnIncludeSalesReturnLine(_SalesReturnLine: Record "Sales Line"; var _IncludeInOrderLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetReceiveOrderLines_OnAfterSetFromWarehouseReceiptLine(_WhseReceiptLine: Record "Warehouse Receipt Line"; var _BaseOrderLineElement: Record "MOB NS BaseDataModel Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetReceiveOrderLines_OnAfterSetFromPurchaseLine(_PurchLine: Record "Purchase Line"; var _BaseOrderLineElement: Record "MOB NS BaseDataModel Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetReceiveOrderLines_OnAfterSetFromTransferLine(_TransferLine: Record "Transfer Line"; _ReservEntryNo: Integer; var _BaseOrderLineElement: Record "MOB NS BaseDataModel Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetReceiveOrderLines_OnAfterSetFromSalesReturnLine(_SalesReturnLine: Record "Sales Line"; var _BaseOrderLineElement: Record "MOB NS BaseDataModel Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetReceiveOrderLines_OnAfterSetFromAnyLine(_RecRef: RecordRef; var _BaseOrderLineElement: Record "MOB NS BaseDataModel Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetReceiveOrderLines_OnAfterSetCurrentKey(var _BaseOrderLineElementView: Record "MOB NS BaseDataModel Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetReceiveOrderLines_OnAddStepsToAnyHeader(_RecRef: RecordRef; var _StepsElement: Record "MOB Steps Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetReceiveOrderLines_OnAddStepsToAnyLine(_RecRef: RecordRef; var _BaseOrderLineElement: Record "MOB NS BaseDataModel Element"; var _Steps: Record "MOB Steps Element")
    begin
    end;

    //
    // ------- IntegrationEvents: PostReceiveOrder -------
    //
    // OnPostReceiveOrder_OnHandleRegistrationForWarehouseReceiptLine       from 'PostOrder'.PostWhseReceiptOrder
    // OnPostReceiveOrder_OnHandleRegistrationForPurchaseLine               from 'PostOrder'.PostPurchaeOrder
    // OnPostReceiveOrder_OnHandleRegistrationForTransferLine               from 'PostOrder'.PostTransferOrder
    // OnPostReceiveOrder_OnHandleRegistrationForSalesReturnLine            from 'PostOrder'.PostSalesReturnOrder
    // OnPostReceiveOrder_OnHandleRegistrationForAnyLine                    from 'PostOrder'.PostXXXOrder

    // OnPostReceiveOrder_OnAddStepsToWarehouseReceipt                      from 'PostOrder'.PostWhseReceiptOrder
    // OnPostReceiveOrder_OnAddStepsToPurchaseHeader                        from 'PostOrder'.PostPurchaseOrder
    // OnPostReceiveOrder_OnAddStepsToTransferHeader                        from 'PostOrder'.PostTransferOrder
    // OnPostReceiveOrder_OnAddStepsToSalesReturnHeader                     from 'PostOrder'.PostSalesReturnOrder
    // OnPostReceiveOrder_OnAddStepsToAnyHeader                             from 'PostOrder'.PostXXXOrder
    // OnPostReceiveOrder_OnBeforePostWarehouseReceipt                      from 'PostOrder'.PostWhseReceiptOrder
    // OnPostReceiveOrder_OnBeforePostPurchaseOrder                         from 'PostOrder'.PostPurchaseOrder
    // OnPostReceiveOrder_OnBeforePostTransferOrder                         from 'PostOrder'.PostTransferOrder
    // OnPostReceiveOrder_OnBeforePostSalesReturnOrder                      from 'PostOrder'.PostSalesReturnOrder
    // OnPostReceiveOrder_OnBeforePostAnyOrder                              from 'PostOrder'.PostXXXOrder

    [IntegrationEvent(false, false)]
    local procedure OnPostReceiveOrder_OnAddStepsToWarehouseReceiptHeader(var _OrderValues: Record "MOB Common Element"; _WhseReceiptHeader: Record "Warehouse Receipt Header"; var _StepsElement: Record "MOB Steps Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostReceiveOrder_OnAddStepsToPurchaseHeader(var _OrderValues: Record "MOB Common Element"; _PurchHeader: Record "Purchase Header"; var _StepsElement: Record "MOB Steps Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostReceiveOrder_OnAddStepsToTransferHeader(var _OrderValues: Record "MOB Common Element"; _TransferHeader: Record "Transfer Header"; var _StepsElement: Record "MOB Steps Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostReceiveOrder_OnAddStepsToSalesReturnHeader(var _OrderValues: Record "MOB Common Element"; _SalesReturnHeader: Record "Sales Header"; var _StepsElement: Record "MOB Steps Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostReceiveOrder_OnAddStepsToAnyHeader(var _OrderValues: Record "MOB Common Element"; _RecRef: RecordRef; var _StepsElement: Record "MOB Steps Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostReceiveOrder_OnHandleRegistrationForWarehouseReceiptLine(var _Registration: Record "MOB WMS Registration"; var _WhseReceiptLine: Record "Warehouse Receipt Line"; var _NewReservationEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostReceiveOrder_OnHandleRegistrationForPurchaseLine(var _Registration: Record "MOB WMS Registration"; var _PurchLine: Record "Purchase Line"; var _NewReservationEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostReceiveOrder_OnHandleRegistrationForTransferLine(var _Registration: Record "MOB WMS Registration"; var _TransferLine: Record "Transfer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostReceiveOrder_OnHandleRegistrationForSalesReturnLine(var _Registration: Record "MOB WMS Registration"; var _SalesReturnLine: Record "Sales Line"; var _NewReservationEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostReceiveOrder_OnHandleRegistrationForAnyLine(var _Registration: Record "MOB WMS Registration"; var _RecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostReceiveOrder_OnBeforePostWarehouseReceipt(var _OrderValues: Record "MOB Common Element"; var _WhseReceiptHeader: Record "Warehouse Receipt Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostReceiveOrder_OnBeforePostPurchaseOrder(var _OrderValues: Record "MOB Common Element"; var _PurchHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostReceiveOrder_OnBeforePostTransferOrder(var _OrderValues: Record "MOB Common Element"; var _TransferHeader: Record "Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostReceiveOrder_OnBeforePostAnyOrder(var _OrderValues: Record "MOB Common Element"; var _RecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostReceiveOrder_OnBeforePostSalesReturnOrder(var _OrderValues: Record "MOB Common Element"; var _SalesReturnHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnPostReceiveOrder_OnAfterPostAnyOrder(var _OrderValues: Record "MOB Common Element"; var _RecRef: RecordRef; var _ResultMessage: Text)
    begin
    end;

}
