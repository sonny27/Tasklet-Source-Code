codeunit 81377 "MOB WMS Move"
{
    Access = Public;

    TableNo = "MOB Document Queue";

    trigger OnRun()
    begin
        MobDocQueue := Rec;

        case Rec."Document Type" of

            // Order headers
            'GetMoveOrders':
                GetOrders();

            // Order lines
            'GetMoveOrderLines':
                GetOrderLines();

            // Posting
            'PostMoveOrder':
                PostOrder();

            else
                Error(MobWmsLanguage.GetMessage('NO_DOC_HANDLER'), Rec."Document Type");
        end;

        // Store the result in the queue and update the status
        MobToolbox.UpdateResult(Rec, XmlResponseDoc);
    end;

    var
        MobDocQueue: Record "MOB Document Queue";
        MobXmlMgt: Codeunit "MOB XML Management";
        MobToolbox: Codeunit "MOB Toolbox";
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
        MobWmsActivity: Codeunit "MOB WMS Activity";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        XmlResponseDoc: XmlDocument;

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
        MobToolbox.InitializeResponseDoc(XmlResponseDoc, XmlResponseData);

        // Filter on the order type
        WhseActHeader.SetFilter(Type, '%1|%2', WhseActHeader.Type::Movement, MobWmsToolbox."WhseActType::Invt. Movement"());

        // Movements to buffer
        MobWmsActivity.GetMoveOrders(XmlRequestDoc, WhseActHeader, MobDocQueue, TempHeaderElement);

        // Add collected buffer values to new <Orders> nodes
        AddBaseOrderElements(XmlResponseData, TempHeaderElement);
    end;

    local procedure GetOrderLines()
    var
        XmlRequestDoc: XmlDocument;
        XmlBackendIDNode: XmlNode;
        OrderID: Code[20];
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
        OrderID := MobXmlMgt.GetNodeInnerText(XmlBackendIDNode);

        // Create the response for the mobile device
        CreateOrderLinesResponse(OrderID);
    end;

    local procedure CreateOrderLinesResponse(_OrderNo: Code[20])
    begin

        // Generate a response
        MobWmsActivity.CreateWhseActLinesResponse(XmlResponseDoc, _OrderNo);
    end;

    procedure AddStepsToWarehouseActvityHeader(_WhseActivityHeader: Record "Warehouse Activity Header"; _XmlResponseDoc: XmlDocument; var _XmlResponseData: XmlNode)
    var
        TempSteps: Record "MOB Steps Element" temporary;
        XmlSteps: XmlNode;
    begin
        TempSteps.SetMustCallCreateNext(true);
        OnGetMoveOrderLines_OnAddStepsToWarehouseActivityHeader(_WhseActivityHeader, TempSteps);

        if not TempSteps.IsEmpty() then begin
            // Adds Collector Configuration with <steps> {<add ... />} <steps/>
            MobToolbox.AddCollectorConfiguration(_XmlResponseDoc, _XmlResponseData, XmlSteps);
            MobXmlMgt.AddStepsaddElements(XmlSteps, TempSteps);
        end;
    end;

    local procedure PostOrder()
    var
        MobReg: Record "MOB WMS Registration";
        TempReturnSteps: Record "MOB Steps Element" temporary;
        XmlRequestDoc: XmlDocument;
        ResultMessage: Text;
    begin
        // Description:
        // The posting processes for the warehouse activities (put-away, pick, move) are handled identically
        // The function that performes the posting is stored in the WMS toolbox

        // Load the request document from the document queue
        MobDocQueue.LoadXMLRequestDoc(XmlRequestDoc);

        // Post the order
        MobWmsActivity.PostWhseActivityOrder(MobDocQueue.MessageIDAsGuid(), XmlRequestDoc, MobReg.Type::Move, TempReturnSteps, ResultMessage);

        // No errors occurred during posting
        if not TempReturnSteps.IsEmpty() then
            MobToolbox.CreateResponseWithSteps(XmlResponseDoc, TempReturnSteps)
        else
            MobToolbox.CreateSimpleResponse(XmlResponseDoc, ResultMessage);
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
        OnGetMoveOrders_OnAfterSetCurrentKey(TempHeaderElementCustomView);
        _BaseOrderElement.SetView(TempHeaderElementCustomView.GetView());
    end;

    //
    // ------- IntegrationEvents: GetMoveOrders -------
    //
    // OnSetFilterWarehouseActivity            from  'GetMoveOrders'
    // OnIncludeWarehouseActivityHeader        from  MobBaseDocHandler.CopyFilteredWhseActivityHeadersToTempRecord()
    // OnAfterSetFromWhseActivityHeader        from  'GetMoveOrders'.GetOrders()."MOBWMSActivity.GetOrders"().SetFromWhseActivityHeader()
    // OnAfterSetCurrentKey                    from  'GetMoveOrders'.GetOrders()."MOBWMSActivity.GetOrders"().AddBaseOrderElements().SetCurrentKeyHeader()

    [IntegrationEvent(false, false)]
    internal procedure OnGetMoveOrders_OnSetFilterWarehouseActivity(_HeaderFilter: Record "MOB NS Request Element"; var _WhseActivityHeader: Record "Warehouse Activity Header"; var _WhseActivityLine: Record "Warehouse Activity Line"; var _IsHandled: Boolean)
    begin
        // Called from MOB Activity for activity types Movement and Invt.Movement
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnGetMoveOrders_OnIncludeWarehouseActivityHeader(_WhseActHeader: Record "Warehouse Activity Header"; var _HeaderFilters: Record "MOB NS Request Element"; var _IncludeInOrderList: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnGetMoveOrders_OnAfterSetFromWarehouseActivityHeader(_WhseActHeader: Record "Warehouse Activity Header"; var _BaseOrderElement: Record "MOB NS BaseDataModel Element")
    begin
        // Called from MOB Activity for activity types Movement and Invt.Movement
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetMoveOrders_OnAfterSetCurrentKey(var _BaseOrderElementView: Record "MOB NS BaseDataModel Element")
    begin
    end;

    //
    // ------- IntegrationEvents: GetMoveOrderLines -------
    //
    // OnSetFilterWarehouseActivityLine        from  'OnGetMoveOrderLines'
    // OnIncludeWarehouseActivityLine          from  'GetMoveOrderLines'.GetOrderLines().CreateOrderLinesResponse()."MobWmsActivity.CreateWhseActLinesResponse"()
    // OnAfterSetFromWhseActivityLine          from  'GetMoveOrderLines'.GetOrderLines().CreateOrderLinesResponse()."MOBWMSActivity.CreateWhseActLinesResponse"().SetFromWhseActivityLine()
    // OnAfterSetCurrentKey                    from  'GetMoveOrderLines'.GetOrderLines().CreateOrderLinesResponse()."MOBWMSActivity.CreateWhseActLinesResponse"().AddBaseOrderLineElements().SetCurrentKeyLine()

    [IntegrationEvent(false, false)]
    internal procedure OnGetMoveOrderLines_OnSetFilterWarehouseActivityLine(var _WhseActLineTake: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnGetMoveOrderLines_OnIncludeWarehouseActivityLine(var _WhseActLineTake: Record "Warehouse Activity Line"; var _IncludeInOrderLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnGetMoveOrderLines_OnAfterSetFromWarehouseActivityLine(_WhseActLineTake: Record "Warehouse Activity Line"; var _BaseOrderLineElement: Record "MOB NS BaseDataModel Element")
    begin
        // Called from MOB Activity for activity types Movement and Invt.Movement
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnGetMoveOrderLines_OnAfterSetCurrentKey(var _BaseOrderLineElementView: Record "MOB NS BaseDataModel Element")
    begin
        // Called from MOB Activity for activity types Movement and Invt.Movement
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetMoveOrderLines_OnAddStepsToWarehouseActivityHeader(_WhseActivityHeader: Record "Warehouse Activity Header"; var _StepsElement: Record "MOB Steps Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnGetMoveOrderLines_OnAddStepsToWarehouseActivityLine(_WhseActivityLine: Record "Warehouse Activity Line"; var _BaseOrderLineElement: Record "MOB NS BaseDataModel Element"; var _Steps: Record "MOB Steps Element")
    begin
    end;

    //
    // ------- IntegrationEvents: PostMoveOrder -------
    //

    [IntegrationEvent(false, false)]
    internal procedure OnPostMoveOrder_OnBeforeHandleRegistrationForWarehouseActivityLine(var _Registration: Record "MOB WMS Registration"; var _WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnPostMoveOrder_OnHandleRegistrationForWarehouseActivityLine(var _Registration: Record "MOB WMS Registration"; var _WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnPostMoveOrder_OnAddStepsToWarehouseActivityHeader(var _OrderValues: Record "MOB Common Element"; _WhseActivityHeader: Record "Warehouse Activity Header"; var _StepsElement: Record "MOB Steps Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnPostMoveOrder_OnBeforePostWarehouseActivityOrder(var _OrderValues: Record "MOB Common Element"; var _WhseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnPostMoveOrder_OnBeforeRunWhseActivityRegister(var _WhseActLinesToPost: Record "Warehouse Activity Line"; var _WhseActRegister: Codeunit "Whse.-Activity-Register"; var _IsHandled: Boolean; var _HandledResultMessage: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnPostMoveOrder_OnAfterPostWarehouseActivity(var _OrderValues: Record "MOB Common Element"; var _WhseActivityLine: Record "Warehouse Activity Line"; var _ResultMessage: Text)
    begin
    end;
}

