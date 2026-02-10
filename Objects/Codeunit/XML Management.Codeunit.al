codeunit 81279 "MOB XML Management"
{
    Access = Public;
    trigger OnRun()
    begin
    end;

    var
        ParentNotInstantiatedErr: Label 'XML Parser Error:\Parent node for "%1" is not instantiated.', Comment = '%1 contains Nodepath', Locked = true;
        ChildNodeNotFoundErr: Label 'XML Parser Error:\The "%1" node could not be found as a child node for the "%2" node.', Comment = '%1 contains node path, %2 contains node name', Locked = true;
        NoChildNodesErr: Label '%1 has no child nodes', Comment = '%1 contains element name', Locked = true;
        GetChildErr: Label 'Could not get child node %1', Comment = '%1 contains node name', Locked = true;
        NodeNotFoundErr: Label '%1 node not found', Comment = '%1 contains node name', Locked = true;
        InvalidNodeNameErr: Label 'Invalid XML node name="%1": %2', Comment = '%1 contains node name, %2 contains last error text', Locked = true;
        RESPONSEDATA_Txt: Label 'responseData', Locked = true;
        BASEORDERLINE_Txt: Label 'BaseOrderLine', Locked = true;
        BASEORDER_Txt: Label 'BaseOrder', Locked = true;
        GROUPORDERLINE_Txt: Label 'GroupOrderLine', Locked = true;
        LOOKUPRESPONSE_Txt: Label 'LookupResponse', Locked = true;
        REGISTRATIONCOLLECTOR_Txt: Label 'RegistrationCollector', Locked = true;
        NS_BASEMODEL_Txt: Label 'http://schemas.taskletfactory.com/MobileWMS/BaseDataModel', Locked = true;
        NS_WHSEMODEL_Txt: Label 'http://schemas.taskletfactory.com/MobileWMS/WarehouseInquiryDataModel', Locked = true;
        NS_RESPONSE_Txt: Label 'http://schemas.microsoft.com/Dynamics/Mobile/2007/04/Documents/Response', Locked = true;
        NS_REQUEST_Txt: Label 'http://schemas.microsoft.com/Dynamics/Mobile/2007/04/Documents/Request', Locked = true;
        NS_REGISTRATIONDATA_Txt: Label 'http://schemas.taskletfactory.com/MobileWMS/RegistrationData', Locked = true;
        NS_SEARCHPARAMETERS_Txt: Label 'http://schemas.taskletfactory.com/MobileWMS/SearchParameters', Locked = true;
        NS_SEARCHRESULT_Txt: Label 'http://schemas.taskletfactory.com/MobileWMS/SearchResult', Locked = true;
        NS_EXTRAINFO_Txt: Label 'http://schemas.taskletfactory.com/MobileWMS/OrderData/ExtraInfo', Locked = true;
        AttributeAtNotFoundErr: Label 'Attribute %1 at %2 not found', Comment = '%1 contains Attribute Name, %2 contains Xpath';
        ResponceDataContentNameMissingErr: Label '"ResponseDataContentName" is missing. A Whse. Inquiry -response must have a specific name in the childnode of ResponseData. Use "Set_ResponseDataContentsNode" to name this node.', Locked = true;
        NsMgr: XmlNamespaceManager;

    procedure InitializeDoc(var _XmlRequestDoc: XmlDocument; _RootName: Text)
    var
        TempText: Text;
    begin
        // Create Root node for Request
        if not DocIsNull(_XmlRequestDoc) then
            Clear(_XmlRequestDoc);

        TempText := '<?xml version="1.0" encoding="utf-8"?>' +
                    '<' + _RootName + '/>';
        DocReadText(_XmlRequestDoc, TempText);
    end;

    procedure CreateNode(_NodeName: Text; var _XmlCreatedNode: XmlNode)
    begin
        _XmlCreatedNode := XmlElement.Create(_NodeName).AsXmlNode();
    end;

    procedure AddElement(var _XmlNode: XmlNode; _Node: Text; _NodeText: Text; _NameSpace: Text; var _XmlCreatedNode: XmlNode)
    var
        XmlNewChildNode: XmlNode;
    begin
        // Verify Xml naming conventions before writing node for better error message
        if not IsValidNodeName(_Node) then
            Error(InvalidNodeNameErr, _Node, GetLastErrorText());

        if _NodeText <> '' then
            XmlNewChildNode := XmlElement.Create(_Node, _NameSpace, _NodeText).AsXmlNode()
        else
            XmlNewChildNode := XmlElement.Create(_Node, _NameSpace).AsXmlNode();

        if _XmlNode.AsXmlElement().Add(XmlNewChildNode) then
            _XmlCreatedNode := XmlNewChildNode;

    end;

    procedure AddAttribute(var _XmlNode: XmlNode; _Name: Text; _Value: Text)
    begin
        if _Value <> '' then
            _XmlNode.AsXmlElement().SetAttribute(_Name, _Value);
    end;

    local procedure SetupNS(var _XmlNode: XmlNode; var _NSname: Text)
    var
        RootDoc: XmlDocument;
        XmlRootElement: XmlElement;
        XmlChildNodeList: XmlNodeList;
        XmlChildNode: XmlNode;
        URI: Text;
        TempText: Text;
    begin
        // Sets up Namespace manager. Reads the current node's namespace.

        // Use node as NS prefix
        //_NSName := DelChr(GetNodeName(_XmlNode),'=',':');
        _NSname := GetNodeName(_XmlNode);

        // Dont add twice if Prefix exists
        if NsMgr.HasNamespace(_NSname) then
            exit;

        // Get URI
        URI := GetNodeNSURI(_XmlNode);

        // Lookup if Namespace URI has been used

        if NsMgr.LookupPrefix(URI, TempText) then;

        // URI has been used.
        // So the NS is unknown, get the NS from first child 
        if TempText <> '' then begin
            XmlRootElement := _XmlNode.AsXmlElement();
            XmlChildNodeList := XmlRootElement.GetChildElements();
            if XmlChildNodeList.Get(1, XmlChildNode) then
                URI := GetNodeNSURI(XmlChildNode)
            else
                URI := GetNodeNSURI(_XmlNode);
        end;

        // Add the namespace
        if _XmlNode.IsXmlDocument() then
            // Use Doc
            NsMgr.NameTable(_XmlNode.AsXmlDocument().NameTable())
        else
            // Use Node 
            // ... nodes created internally may have no parent document if the node is intended to be added as CDATA (ie. from OnGetReferenceData_OnAddRegistrationCollectorConfigurations)
            if _XmlNode.GetDocument(RootDoc) then
                NsMgr.NameTable(RootDoc.NameTable());

        NsMgr.AddNamespace(_NSname, URI);

    end;

    /// <summary>
    /// Find a node
    /// NO error if node is not found
    /// Return the node and if the node exists
    /// </summary>
    procedure SelectSingleNode(var _XmlNode: XmlNode; _NodePath: Text; var _XmlFoundNode: XmlNode): Boolean
    var
        NSName: Text;
    begin
        SetupNS(_XmlNode, NSName);
        exit(_XmlNode.SelectSingleNode(NSName + ':' + _NodePath, NsMgr, _XmlFoundNode));
    end;

    /// <summary>
    /// Find a node
    /// Error if node is not found
    /// </summary>
    procedure FindNode(var _XmlNode: XmlNode; _NodePath: Text; var _XmlFoundNode: XmlNode)
    var
        NSName: Text;
    begin

        // Node must have contents
        if NodeIsNull(_XmlNode) then
            Error(ParentNotInstantiatedErr, _NodePath);

        SetupNS(_XmlNode, NSName);

        if not _XmlNode.SelectSingleNode(NSName + ':' + _NodePath, NsMgr, _XmlFoundNode) then
            Error(ChildNodeNotFoundErr, _NodePath, _XmlNode.AsXmlElement().Name());

    end;

    /// <summary>
    /// Find a node and return it's value
    /// NO error if node is not found
    /// </summary>
    procedure FindNodeAndValue(var _XmlNode: XmlNode; _NodePath: Text; var _XmlFoundNode: XmlNode): Text
    var
        NSName: Text;
    begin

        // Node must have contents
        if NodeIsNull(_XmlNode) then
            Error(ParentNotInstantiatedErr, _NodePath);

        SetupNS(_XmlNode, NSName);

        if _XmlNode.SelectSingleNode(NSName + ':' + _NodePath, NsMgr, _XmlFoundNode) then
            exit(GetNodeInnerText(_XmlFoundNode));
    end;

    procedure GetAttribute(var _XmlNode: XmlNode; _AttributeName: Text; var _AttributeValue: Text): Boolean
    var
        FoundXmlAttribute: XmlAttribute;
        XmlRootElement: XmlElement;
    begin

        XmlRootElement := _XmlNode.AsXmlElement();
        if not XmlRootElement.HasAttributes() then
            exit;

        if _XmlNode.AsXmlElement().Attributes().Get(_AttributeName, FoundXmlAttribute) then begin
            _AttributeValue := FoundXmlAttribute.Value();
            exit(true);
        end;

    end;

    //
    // ------- COMMON -------
    //

    procedure NodeIsNull(var _XmlNode: XmlNode): Boolean
    begin
        if _XmlNode.IsXmlElement() then
            exit(_XmlNode.AsXmlElement().IsEmpty());
        exit(true);
    end;

    procedure NodeAppendCDataText(var _XmlCData: XmlCData; _Text: Text)
    var
        TempText: Text;
    begin

        TempText += _XmlCData.Value();
        TempText += _Text;
        _XmlCData.Value(TempText);

    end;

    procedure NodeCreateCData(var _XmlCData: XmlCData; _Text: Text)
    begin
        _XmlCData := XmlCData.Create(_Text);
    end;

    procedure NodeAppendNodeAsCData(var _ToNode: XmlNode; var _InnerNode: XmlNode): Boolean
    var
        XmlCDataSection: XmlCData;
        CDataText: Text;
    begin
        _InnerNode.WriteTo(CDataText);
        XmlCDataSection := XmlCData.Create(CDataText);
        NodeAppendCData(_ToNode, XmlCDataSection);
    end;

    procedure NodeAppendCData(var _XmlRootNode: XmlNode; var _XmlCData: XmlCData): Boolean
    begin

        // Append as Child
        _XmlRootNode.AsXmlElement().Add(_XmlCData);

    end;

    procedure DocIsNull(var _XmlDoc: XmlDocument): Boolean
    var
        NodesList: XmlNodeList;
    begin

        NodesList := _XmlDoc.GetDescendantElements();
        exit(NodesList.Count() = 0);
    end;

    procedure DocSaveStream(var _XmlDoc: XmlDocument; var _OutStream: OutStream): Boolean
    begin

        _XmlDoc.WriteTo(_OutStream);

    end;

    procedure DocSaveToText(var _XmlDoc: XmlDocument; var _Text: Text): Boolean
    begin

        _XmlDoc.WriteTo(_Text);

    end;

    procedure DocReadStream(var _XmlDoc: XmlDocument; var _InStream: InStream): Boolean
    begin

        XmlDocument.ReadFrom(_InStream, _XmlDoc);

    end;

    procedure DocReadText(var _XmlDoc: XmlDocument; _InText: Text): Boolean
    begin

        exit(XmlDocument.ReadFrom(_InText, _XmlDoc));

    end;

    procedure GetDocRootNodeHasChildNodes(var _XmlDoc: XmlDocument): Boolean
    var
        XmlRootNode: XmlNode;
    begin
        if DocIsNull(_XmlDoc) then
            exit(false);

        GetDocRootNode(_XmlDoc, XmlRootNode);
        exit(GetNodeHasChildNodes(XmlRootNode));
    end;

    procedure GetDocRootNode(var _XmlDoc: XmlDocument; var _XmlRootNode: XmlNode)
    var
        XmlRootElement: XmlElement;
    begin

        _XmlDoc.GetRoot(XmlRootElement);
        _XmlRootNode := XmlRootElement.AsXmlNode();

    end;

    procedure GetDocNSURI(_XmlDoc: XmlDocument): Text
    var
        XmlRootElement: XmlElement;
    begin
        _XmlDoc.GetRoot(XmlRootElement);
        exit(XmlRootElement.NamespaceUri());
    end;

    procedure GetDocDocElement(var _XmlDoc: XmlDocument)
    begin

        _XmlDoc := XmlDocument.Create();

    end;

    procedure GetNodeNSURI(_XmlRootNode: XmlNode): Text
    var
        XmlRootElement: XmlElement;
    begin

        XmlRootElement := _XmlRootNode.AsXmlElement();
        exit(XmlRootElement.NamespaceUri());

    end;

    procedure GetNodeInnerText(_XmlRootNode: XmlNode): Text
    var
        XmlRootElement: XmlElement;
    begin

        XmlRootElement := _XmlRootNode.AsXmlElement();
        exit(XmlRootElement.InnerText());

    end;

    procedure GetNodeOuterText(_XmlNode: XmlNode) ReturnValue: Text
    begin
        _XmlNode.WriteTo(ReturnValue);
    end;

    procedure GetNodeName(_XmlRootNode: XmlNode): Text
    var
        XmlRootElement: XmlElement;
    begin

        XmlRootElement := _XmlRootNode.AsXmlElement();
        exit(DelChr(XmlRootElement.Name(), '=', ':'));

    end;

    procedure GetNodeHasChildNodes(var _XmlRootNode: XmlNode): Boolean
    begin
        exit(_XmlRootNode.AsXmlElement().HasElements());
    end;

    /// <summary>
    /// Get number of child nodes
    /// </summary>
    procedure GetNodeChildListSize(var _Node: XmlNode): Integer
    var
        ChildNodeList: XmlNodeList;
    begin
        GetNodeChildNodes(_Node, ChildNodeList);
        exit(ChildNodeList.Count());
    end;

    procedure GetNodeChildNodes(var _XmlRootNode: XmlNode; var _XmlChildNodeList: XmlNodeList)
    var
        XmlRootElement: XmlElement;
    begin
        XmlRootElement := _XmlRootNode.AsXmlElement();
        _XmlChildNodeList := XmlRootElement.GetChildElements();
    end;

    local procedure GetNodeChildItem(var _XmlRootNode: XmlNode; var _XmlChildNode: XmlNode; _No: Integer)
    var
        XmlChildNodeList: XmlNodeList;
    begin

        GetNodeChildNodes(_XmlRootNode, XmlChildNodeList);

        if XmlChildNodeList.Count() > 0 then begin
            if not XmlChildNodeList.Get(_No, _XmlChildNode) then
                Error(GetChildErr, _No);
        end else
            Error(NoChildNodesErr, _XmlRootNode.AsXmlElement().Name());

    end;

    procedure GetListItem(var _XmlChildNodeList: XmlNodeList; var _XmlChildNode: XmlNode; _No: Integer)
    begin

        if not (_XmlChildNodeList.Count() > 0) and
               (_XmlChildNodeList.Get(_No, _XmlChildNode)) then
            Error(GetChildErr, _No);

    end;

    procedure GetNodeFirstChild(var _XmlRootNode: XmlNode; var _XmlChildNode: XmlNode)
    begin

        GetNodeChildItem(_XmlRootNode, _XmlChildNode, 1);

    end;

    procedure GetNodeLastChild(var _XmlRootNode: XmlNode; var _XmlChildNode: XmlNode)
    var
        XmlChildNodeList: XmlNodeList;
    begin

        GetNodeChildNodes(_XmlRootNode, XmlChildNodeList);
        GetNodeChildItem(_XmlRootNode, _XmlChildNode, XmlChildNodeList.Count());

    end;

    [TryFunction]
    procedure IsValidNodeName(_NodeName: Text)  // Try method returns true/false depending on whether the method returns an error or not
    var
        DummyXmlNode: XmlNode;
    begin
        CreateNode(_NodeName, DummyXmlNode);
    end;

    //
    // -------- XPath --------
    //

    procedure XPathFound(_XmlDoc: XmlDocument; _XPath: Text[1024]): Boolean
    var
        dummyNodeOut: XmlNode;
        nodeFound: Boolean;
    begin
        nodeFound := GetXPathNode(_XmlDoc, _XPath, dummyNodeOut);
        exit(nodeFound);
    end;

    procedure GetXPathNode(_XmlDoc: XmlDocument; _XPath: Text[1024]; var _NodeOut: XmlNode): Boolean
    var
        nodeFound: Boolean;
        responseNode: XmlNode;
    begin
        if DocIsNull(_XmlDoc) then
            exit(false);

        GetDocRootNode(_XmlDoc, responseNode);

        NsMgr.NameTable(_XmlDoc.NameTable());
        NsMgr.AddNamespace('resp', NS_RESPONSE());
        NsMgr.AddNamespace('req', NS_REQUEST());
        NsMgr.AddNamespace('whse', NS_WHSEMODEL());
        NsMgr.AddNamespace('base', NS_BASEMODEL());
        NsMgr.AddNamespace('registrationData', NS_REGISTRATIONDATA());
        NsMgr.AddNamespace('SearchParameters', NS_SEARCHPARAMETERS());

        nodeFound := responseNode.SelectSingleNode(_XPath, NsMgr, _NodeOut);
        exit(nodeFound);
    end;

    /// <summary>
    /// Get innerText of node on an Xpath. 
    /// Error if node does not exist
    /// </summary>
    procedure XPathInnerText(_XmlDoc: XmlDocument; _XPath: Text[1024]): Text
    begin
        exit(XPathInnerText(_XmlDoc, _XPath, true));
    end;

    /// <summary>
    /// Get innerText of node on an Xpath
    /// </summary>
    procedure XPathInnerText(_XmlDoc: XmlDocument; _XPath: Text; _ErrorIfNotExists: Boolean): Text
    var
        NodeFound: XmlNode;
    begin
        if GetXPathNode(_XmlDoc, _XPath, NodeFound) then
            exit(GetNodeInnerText(NodeFound))
        else
            if _ErrorIfNotExists then
                Error(NodeNotFoundErr, _XPath);
    end;

    procedure XPathAttribute(_XmlDoc: XmlDocument; _XPath: Text[1024]; _Attribute: Text[1024]): Text
    var
        nodeOut: XmlNode;
        nodeFound: Boolean;
        attributeFound: Boolean;
        attributeValueOut: Text;
    begin
        nodeFound := GetXPathNode(_XmlDoc, _XPath, nodeOut);
        if (not nodeFound) then
            Error(NodeNotFoundErr, _XPath);

        attributeFound := GetAttribute(nodeOut, _Attribute, attributeValueOut);
        if (not attributeFound) then
            Error(AttributeAtNotFoundErr, _Attribute, _XPath);

        exit(attributeValueOut);
    end;

    //
    // ------- Write Order NS BaseDataModel Element to Xml --------
    //

    procedure AddNsBaseDataModelBaseOrderElements(var _XmlResponseData: XmlNode; var _HeaderElement: Record "MOB NS BaseDataModel Element")
    var
        CursorMgt: Codeunit "MOB Cursor Management";
        NewSorting: Integer;
        XmlCreatedNode: XmlNode;
    begin
        CursorMgt.Backup(_HeaderElement);
        if _HeaderElement.FindSet() then
            repeat
                NewSorting := NewSorting + 1;
                _HeaderElement.SetValue(_HeaderElement.FieldName(Sorting), Format(NewSorting, 0, 9));   // "Sorting" intentially has no dedicaded Set_'er to prevent users from trying to set value
                AddNsBaseDataModelBaseOrderElement(_XmlResponseData, _HeaderElement, XmlCreatedNode);
            until _HeaderElement.Next() = 0;

        CursorMgt.Restore(_HeaderElement);
    end;

    local procedure AddNsBaseDataModelBaseOrderElement(var _XmlResponseData: XmlNode; var _HeaderElement: Record "MOB NS BaseDataModel Element"; var _XmlCreatedNode: XmlNode)
    var
        XmlOrderNode: XmlNode;
        XmlOrderElement: XmlElement;
    begin
        // Create the <Order> element and add it to the <Orders> node
        AddElement(_XmlResponseData, BASEORDER(), '', NS_BASEMODEL(), XmlOrderNode);
        XmlOrderElement := XmlOrderNode.AsXmlElement();
        AddNsBaseDataModelElement2XmlElement(XmlOrderElement, _HeaderElement, _XmlCreatedNode);
    end;

    //
    // ------- Write OrderLine NS BaseDataModel Element to Xml --------
    //

    procedure AddNsBaseDataModelBaseOrderLineElements(var _XmlResponseData: XmlNode; var _LineElement: Record "MOB NS BaseDataModel Element")
    var
        CursorMgt: Codeunit "MOB Cursor Management";
        XmlCreatedNode: XmlNode;
        NewSorting: Integer;
        IsGrouped: Boolean;
    begin
        CursorMgt.Backup(_LineElement);
        if not _LineElement.FindSet() then
            exit;

        // update elements Sorting
        // write ungrouped BaseOrderLines
        repeat
            NewSorting := NewSorting + 1;
            _LineElement.SetValue(_LineElement.FieldName(Sorting), Format(NewSorting, 0, 9));   // "Sorting" intentially has no dedicaded Set_'er to prevent users from trying to set value
            if _LineElement."GroupBy1 (internal)" = '' then
                AddNsBaseDataModelBaseOrderLineElement(_XmlResponseData, _LineElement, XmlCreatedNode)  // Ungrouped line: Write xml immidiately with no table Modify for best possible performance
            else
                _LineElement.Modify();   // Grouped line: Delay write xml till below
        until _LineElement.Next() = 0;

        // write grouped elements to xml
        _LineElement.SetCurrentKey("GroupBy1 (internal)", "GroupByValues1 (internal)", Sorting);
        _LineElement.SetFilter("GroupBy1 (internal)", '<>%1', '');
        if _LineElement.FindSet() then
            repeat
                _LineElement.SetRange("GroupBy1 (internal)", _LineElement."GroupBy1 (internal)");
                _LineElement.SetRange("GroupByValues1 (internal)", _LineElement."GroupByValues1 (internal)");
                repeat
                    IsGrouped := true;
                    AddNsBaseDataModelBaseOrderLineElementGroup(IsGrouped, _XmlResponseData, _LineElement);
                    if not IsGrouped then   // Group suppressed by event
                        AddNsBaseDataModelBaseOrderLineElement(_XmlResponseData, _LineElement, XmlCreatedNode);
                until _LineElement.Next() = 0;
                _LineElement.SetFilter("GroupBy1 (internal)", '<>%1', '');
                _LineElement.SetRange("GroupByValues1 (internal)");
            until _LineElement.Next() = 0;

        // restore previous cursors and sorting
        CursorMgt.Restore(_LineElement);
    end;

    procedure AddNsBaseDataModelBaseOrderLineElementGroup(var _IsGrouped: Boolean; var _XmlResponseData: XmlNode; var _LineElement: Record "MOB NS BaseDataModel Element")
    var
        TempGroupOrderLineElement: Record "MOB NS BaseDataModel Element" temporary;
        TempNodeValueBuffer: Record "MOB NodeValue Buffer" temporary;
        MobBaseDocumentHandler: Codeunit "MOB WMS Base Document Handler";
        MobCursorMgt: Codeunit "MOB Cursor Management";
        XmlGroupNode: XmlNode;
        XmlCreatedNode: XmlNode;
        IsHandled: Boolean;
    begin
        TempGroupOrderLineElement.Create();

        // Clone first _LineElement to new GroupOrderLine-element
        _LineElement.GetSharedNodeValueBuffer(TempNodeValueBuffer);
        if TempNodeValueBuffer.FindSet() then
            repeat
                TempGroupOrderLineElement.SetValue(TempNodeValueBuffer.Path, TempNodeValueBuffer.GetValue());
            until TempNodeValueBuffer.Next() = 0;

        // Default behavior even when no OnAfterGroupByBaseOrderLineElement-subscribers
        // Current implementation is cloning the first grouped line, but clearing LotNumber/SerialNumber if number of lines > 1
        if (_LineElement.Count() > 1) then begin
            if (_LineElement.Get_SerialNumber() <> '') then
                TempGroupOrderLineElement.Set_SerialNumber('');
            if (_LineElement.Get_LotNumber() <> '') then
                TempGroupOrderLineElement.Set_LotNumber('');

            TempGroupOrderLineElement.Set_Quantity(0);
        end;

        // Event to set Group element incl. flag to suppress the group entirely
        MobCursorMgt.Backup(_LineElement);
        MobBaseDocumentHandler.OnAfterGroupByBaseOrderLineElements(TempGroupOrderLineElement, _IsGrouped, _LineElement, IsHandled);
        MobCursorMgt.Restore(_LineElement);

        if _IsGrouped then begin
            TempGroupOrderLineElement.Save();

            // GroupOrderline element
            AddElement(_XmlResponseData, 'Group', '', NS_BASEMODEL(), XmlGroupNode);
            AddAttribute(XmlGroupNode, 'groupBy', _LineElement."GroupBy1 (internal)");          // for easier debug, not used by Mobile App
            AddAttribute(XmlGroupNode, 'values', _LineElement."GroupByValues1 (internal)");     // for easier debug, not used by Mobile App
            AddNsBaseDataModelGroupOrderLineElement(XmlGroupNode, TempGroupOrderLineElement, XmlCreatedNode);

            // Consolidated BaseOrderLine-elements
            repeat
                AddNsBaseDataModelBaseOrderLineElement(XmlGroupNode, _LineElement, XmlCreatedNode);
            until _LineElement.Next() = 0;
        end;
    end;

    local procedure AddNsBaseDataModelGroupOrderLineElement(var _XmlResponseData: XmlNode; var _GroupOrderLineElement: Record "MOB NS BaseDataModel Element"; var _XmlCreatedNode: XmlNode)
    var
        XmlOrderNode: XmlNode;
        XmlGroupOrderLineElement: XmlElement;
    begin
        // Create the <GroupOrderLine> element and add it to the <GroupBy> node
        AddElement(_XmlResponseData, GROUPORDERLINE(), '', NS_BASEMODEL(), XmlOrderNode);
        XmlGroupOrderLineElement := XmlOrderNode.AsXmlElement();
        AddNsBaseDataModelElement2XmlElement(XmlGroupOrderLineElement, _GroupOrderLineElement, _XmlCreatedNode);
    end;

    local procedure AddNsBaseDataModelBaseOrderLineElement(var _XmlResponseData: XmlNode; var _LineElement: Record "MOB NS BaseDataModel Element"; var _XmlCreatedNode: XmlNode)
    var
        XmlOrderNode: XmlNode;
        XmlOrderElement: XmlElement;
    begin
        // Create the <Order> element and add it to the <Orders> node
        AddElement(_XmlResponseData, BASEORDERLINE(), '', NS_BASEMODEL(), XmlOrderNode);
        XmlOrderElement := XmlOrderNode.AsXmlElement();
        AddNsBaseDataModelElement2XmlElement(XmlOrderElement, _LineElement, _XmlCreatedNode);
    end;

    //
    // ------- Write Whse Inquiry Element to Xml ------
    // Used by Lookup codeunit (Whse. Inquiry codeunit has seperate functions)
    //

    procedure AddNsWhseInquiryModelLookupResponseElements(var _XmlResponseData: XmlNode; var _LookupResponseElement: Record "MOB NS WhseInquery Element")
    var
        CursorMgt: Codeunit "MOB Cursor Management";
        XmlCreatedNode: XmlNode;
    begin
        CursorMgt.Backup(_LookupResponseElement);
        if _LookupResponseElement.FindSet() then
            repeat
                AddNsWhseInquiryModelLookupResponseElement(_XmlResponseData, _LookupResponseElement, XmlCreatedNode);
            until _LookupResponseElement.Next() = 0;

        // restore previous cursors and sorting
        CursorMgt.Restore(_LookupResponseElement);
    end;

    local procedure AddNsWhseInquiryModelLookupResponseElement(var _XmlResponseData: XmlNode; var _LookupResponseElement: Record "MOB NS WhseInquery Element"; var _XmlCreatedNode: XmlNode)
    var
        XmlOrderNode: XmlNode;
        XmlOrderElement: XmlElement;
    begin
        // Create the <Order> element and add it to the <Orders> node
        AddElement(_XmlResponseData, LOOKUPRESPONSE(), '', NS_WHSEMODEL(), XmlOrderNode);
        XmlOrderElement := XmlOrderNode.AsXmlElement();
        AddNsWhseInquiryModelElement2XmlElement(XmlOrderElement, _LookupResponseElement, _XmlCreatedNode);
    end;

    //
    // ------- Write NS Resp Element to Xml -------
    // Used by Whse. Inquiry codeunit
    //

    procedure AddNsWhseInquiryModelResponseDataElements(var _XmlResponseData: XmlNode; var _ResponseElement: Record "MOB NS Resp Element")
    var
        XmlCreatedNode: XmlNode;
    begin
        // Add Response elements to XML
        // (Whse Inqury has normally only one main element (with multiple values in it))
        if _ResponseElement.FindSet() then
            repeat
                AddNsWhseInquiryModelResponseDataElement(_XmlResponseData, _ResponseElement, XmlCreatedNode);
            until _ResponseElement.Next() = 0;
    end;

    local procedure AddNsWhseInquiryModelResponseDataElement(var _XmlResponseData: XmlNode; var _ResponseElements: Record "MOB NS Resp Element"; var _XmlCreatedNode: XmlNode)
    var
        XmlOrderNode: XmlNode;
        XmlOrderElement: XmlElement;
        ResponseDataNodeName: Text;
    begin
        // Create the <ResponseDataContentName> element and add it to the <ResponseData> node
        ResponseDataNodeName := _ResponseElements.NodeName;
        if ResponseDataNodeName = '' then
            Error(ResponceDataContentNameMissingErr);

        AddElement(_XmlResponseData, ResponseDataNodeName, '', NS_WHSEMODEL(), XmlOrderNode);
        XmlOrderElement := XmlOrderNode.AsXmlElement();
        AddNsRespElement2XmlElement(XmlOrderElement, _ResponseElements, _XmlCreatedNode);
    end;

    //
    // ------- Steps -------
    //
    procedure AddStepsaddElements(var _XmlStepsNode: XmlNode; var _StepsElements: Record "MOB Steps Element")
    var
        DummyXmlStepsaddNode: XmlNode;
    begin
        if _StepsElements.FindSet() then
            repeat
                AddStepsaddElement(_XmlStepsNode, _StepsElements, DummyXmlStepsaddNode);
            until _StepsElements.Next() = 0;
    end;

    local procedure AddStepsaddElement(var _XmlStepsNode: XmlNode; var _StepsElement: Record "MOB Steps Element"; var _XmlAddNode: XmlNode)
    begin
        // Create the (usually) 'add' element and add it to the <Steps> node
        // 'add' is the default nodename for everything but 'typeAndQuantity'
        _StepsElement.TestField(NodeName);
        AddElement(_XmlStepsNode, _StepsElement.NodeName, '', GetNodeNSURI(_XmlStepsNode), _XmlAddNode);
        AddStepsElement2XmlNodeAttributes(_XmlAddNode, _StepsElement);
    end;

    /// <remarks>
    /// Call to SyncronizeTableToBuffer removed in MOB5.39 for optimization. Can break existing customization if _Steps table value was assigned manually with _Steps.Modify() instead of _Steps.Save()
    /// </remarks>
    local procedure AddStepsElement2XmlNodeAttributes(var _XmlNode: XmlNode; var _StepsElement: Record "MOB Steps Element")
    var
        TempValueBuffer: Record "MOB NodeValue Buffer" temporary;
    begin
        _StepsElement.GetSharedNodeValueBuffer(TempValueBuffer);       // Applies filter to a single Reference Key
        TempValueBuffer.SetCurrentKey("Reference Key", Sorting);
        TempValueBuffer.SetFilter(Sorting, '0|10..799|1000..');        // Fields 1..9, 800..999 are reserved internal fields and should never be output

        AddValueBuffer2XmlNodeAttributes(_XmlNode, TempValueBuffer);
    end;

    //
    // ------- Header Fields -------
    //

    procedure AddHeaderFieldsaddElements(var _XmlStepsNode: XmlNode; var _HeaderFields: Record "MOB HeaderField Element")
    var
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
        DummyXmlStepsaddNode: XmlNode;
        IsVisible: Boolean;
    begin
        if _HeaderFields.FindSet() then
            repeat
                // visible is not really a headerField property, but is included for consistency of API when compared to Steps (but should not be written to Xml)
                IsVisible := _HeaderFields.visible = MobWmsToolbox.Bool2Text(true);
                if IsVisible then
                    AddHeaderFieldaddElement(_XmlStepsNode, _HeaderFields, DummyXmlStepsaddNode);
            until _HeaderFields.Next() = 0;
    end;

    local procedure AddHeaderFieldaddElement(var _XmlLinesNode: XmlNode; var _HeaderField: Record "MOB HeaderField Element"; var _XmlAddNode: XmlNode)
    begin
        // Create the <add> element and add it to the <headerConfiguration><lines> node
        AddElement(_XmlLinesNode, 'add', '', GetNodeNSURI(_XmlLinesNode), _XmlAddNode);
        AddHeaderFieldElement2XmlNodeAttributes(_XmlAddNode, _HeaderField);
    end;

    local procedure AddHeaderFieldElement2XmlNodeAttributes(var _XmlNode: XmlNode; var _HeaderField: Record "MOB HeaderField Element")
    var
        TempValueBuffer: Record "MOB NodeValue Buffer" temporary;
    begin
        _HeaderField.SyncronizeTableToBuffer();
        _HeaderField.GetSharedNodeValueBuffer(TempValueBuffer);                 // Applies filter to a single Reference Key
        TempValueBuffer.SetCurrentKey("Reference Key", Sorting);
        TempValueBuffer.SetFilter(Sorting, '0|10..199|201..799|1000..');        // Fields 1..9, 800..999 are reserved internal fields and should never be output, Field200 is 'visible' (not really a valid headerConfiguration-field)

        AddValueBuffer2XmlNodeAttributes(_XmlNode, TempValueBuffer);
    end;

    procedure AddDataTableEntry2XmlElement(var _ToXmlElement: XmlElement; var _DataTableEntry: Record "MOB DataTable Element")
    var
        TempValueBuffer: Record "MOB NodeValue Buffer" temporary;
        DummyXmlCreatedNode: XmlNode;
    begin
        _DataTableEntry.SyncronizeTableToBuffer();
        _DataTableEntry.GetSharedNodeValueBuffer(TempValueBuffer);     // Applies filter to a single Reference Key
        TempValueBuffer.SetCurrentKey("Reference Key", Sorting);
        TempValueBuffer.SetFilter(Sorting, '0|10..799|1000..');        // Fields 1..9, 800..999 are reserved internal fields and should never be output

        AddValueBuffer2XmlElement(_ToXmlElement, TempValueBuffer, DummyXmlCreatedNode)
    end;

    procedure AddNsRespElement2XmlElement(var _ToXmlElement: XmlElement; var _NsRespElement: Record "MOB NS Resp Element"; var _XmlCreatedNode: XmlNode)
    var
        TempValueBuffer: Record "MOB NodeValue Buffer" temporary;
    begin
        _NsRespElement.SyncronizeTableToBuffer();
        _NsRespElement.GetSharedNodeValueBuffer(TempValueBuffer);      // Applies filter to a single Reference Key
        TempValueBuffer.SetCurrentKey("Reference Key", Sorting);
        TempValueBuffer.SetFilter(Sorting, '0|10..799|1000..');        // Fields 1..9, 800..999 are reserved internal fields and should never be output

        AddValueBuffer2XmlElement(_ToXmlElement, TempValueBuffer, _XmlCreatedNode)
    end;

    procedure AddNsBaseDataModelElement2XmlElement(var _ToXmlElement: XmlElement; var _NsBaseDataModelElement: Record "MOB NS BaseDataModel Element"; var _XmlCreatedNode: XmlNode)
    var
        TempValueBuffer: Record "MOB NodeValue Buffer" temporary;
    begin
        _NsBaseDataModelElement.SyncronizeTableToBuffer();
        _NsBaseDataModelElement.GetSharedNodeValueBuffer(TempValueBuffer); // Applies filter to a single Reference Key
        TempValueBuffer.SetCurrentKey("Reference Key", Sorting);
        TempValueBuffer.SetFilter(Sorting, '0|10..799|1000..');        // Fields 1..9, 800..999 are reserved internal fields and should never be output

        AddValueBuffer2XmlElement(_ToXmlElement, TempValueBuffer, _XmlCreatedNode)
    end;

    internal procedure AddNsSearchResultElement2XmlElement(var _ToXmlElement: XmlElement; var _NsSearchResultElement: Record "MOB NS SearchResult Element"; var _XmlCreatedNode: XmlNode)
    var
        TempValueBuffer: Record "MOB NodeValue Buffer" temporary;
    begin
        _NsSearchResultElement.SyncronizeTableToBuffer();
        _NsSearchResultElement.GetSharedNodeValueBuffer(TempValueBuffer); // Applies filter to a single Reference Key
        TempValueBuffer.SetCurrentKey("Reference Key", Sorting);
        TempValueBuffer.SetFilter(Sorting, '0|10..799|1000..');        // Fields 1..9, 800..999 are reserved internal fields and should never be output

        AddValueBuffer2XmlElement(_ToXmlElement, TempValueBuffer, _XmlCreatedNode)
    end;

    procedure AddNsWhseInquiryModelElement2XmlElement(var _ToXmlElement: XmlElement; var _NsWhseInquiryElement: Record "MOB NS WhseInquery Element"; var _XmlCreatedNode: XmlNode)
    var
        TempValueBuffer: Record "MOB NodeValue Buffer" temporary;
    begin
        _NsWhseInquiryElement.SyncronizeTableToBuffer();
        _NsWhseInquiryElement.GetSharedNodeValueBuffer(TempValueBuffer); // Applies filter to a single Reference Key
        TempValueBuffer.SetCurrentKey("Reference Key", Sorting);
        TempValueBuffer.SetFilter(Sorting, '0|10..799|1000..');        // Fields 1..9, 800..999 are reserved internal fields and should never be output

        AddValueBuffer2XmlElement(_ToXmlElement, TempValueBuffer, _XmlCreatedNode)
    end;

    procedure AddCommonElement2XmlNode(var _ToXmlNode: XmlNode; var _CommonElement: Record "MOB Common Element")
    var
        TempNodeValueBuffer: Record "MOB NodeValue Buffer" temporary;
    begin
        _CommonElement.GetSharedNodeValueBuffer(TempNodeValueBuffer);
        AddValueBuffer2XmlNode(_ToXmlNode, TempNodeValueBuffer);
    end;

    local procedure AddValueBuffer2XmlNode(var _ToXmlNode: XmlNode; var _NodeValueBuffer: Record "MOB NodeValue Buffer")
    var
        MobXmlMgt: Codeunit "MOB XML Management";
        ToXmlElement: XmlElement;
        XmlCreatedNode: XmlNode;
    begin
        ToXmlElement := _ToXmlNode.AsXmlElement();
        MobXmlMgt.AddValueBuffer2XmlElement(ToXmlElement, _NodeValueBuffer, XmlCreatedNode);
    end;

    procedure AddValueBuffer2XmlElement(var _ToXmlElement: XmlElement; var _ValueBuffer: Record "MOB NodeValue Buffer"; var _XmlCreatedNode: XmlNode)
    var
        XmlCreatedNode: XmlNode;
        XmlCDataSection: XmlCData;
        ToXmlNode: XmlNode;
        PathParts: List of [Text];
        PartsCount: Integer;
        PathPart: Text;
        UseValue: Text;
        i: Integer;
        IsAttribute: Boolean;
        IsFirstPart: Boolean;
        IsLastPart: Boolean;
        NodeExists: Boolean;
    begin
        ToXmlNode := _ToXmlElement.AsXmlNode();
        if (_ValueBuffer.FindSet()) then
            repeat
                //
                // html conversion
                //
                UseValue := _ValueBuffer.GetValue();
                if _ValueBuffer.IsHtml then
                    if (_ValueBuffer.IsCData) or (_ValueBuffer.Path = 'html') then
                        // CDATA and <html>-node needs htmlcontent wrapped in at least a single <html>-tag
                        // html-content is automatically encoded when writing via XmlDom (visible in Notepad, but not when viewing Response in Chrome/Edge)
                        // NOTE: <html> requires Android 1.4.3 to parse correctly
                        UseValue := '<html>' + UseValue + '</html>'
                    else
                        // ... other nodes needs double <html><html> to work (ie. InformationStep.helpLabel) -- only automatic htmlencodeding
                        UseValue := '<html><html>' + UseValue + '</html></html>';

                //
                // Add new Element or Attribute
                //
                if _ValueBuffer.IsCData then begin
                    AddElement(ToXmlNode, _ValueBuffer.Path, '', _ToXmlElement.NamespaceUri(), _XmlCreatedNode);
                    NodeCreateCData(XmlCDataSection, UseValue);
                    NodeAppendCData(_XmlCreatedNode, XmlCDataSection);
                end else begin
                    // Split path by '/'  (first part may be empty ie. '/tag')
                    PathParts := _ValueBuffer.Path.Split('/');

                    PartsCount := PathParts.Count();
                    for i := 1 to PartsCount do begin
                        PathParts.Get(i, PathPart);
                        PathPart := StripArrayIndex(PathPart); // Remove any [x] array index from path part
                        IsFirstPart := i = 1;
                        IsLastPart := i = PartsCount;
                        IsAttribute := PathPart.StartsWith('@');

                        if IsFirstPart then
                            Clear(XmlCreatedNode);  // Reset when we start over with a new tag inclduding possible subtags and attributes

                        case true of
                            (IsFirstPart) and (not IsLastPart) and (PathPart = ''):
                                ;   // Ignore empty first part when writing elements (as opposed to the function to function to write attributes where this condition do not exist)

                            // Write: Last part must always be written and with populated nodevalue
                            (IsLastPart) and (not IsAttribute):
                                if not XmlCreatedNode.IsXmlElement() then  // Note: NodeIsNull would return true when content is blank, using not IsXmlElement() instead
                                    AddElement(ToXmlNode, PathPart, UseValue, _ToXmlElement.NamespaceUri(), XmlCreatedNode)  // ie. 'onlineValidation' from '/onlineValidation'
                                else
                                    AddElement(XmlCreatedNode, PathPart, UseValue, _ToXmlElement.NamespaceUri(), XmlCreatedNode);

                            // Write: Attribute is always a last part of the path and must have a previously created node ie. 'ItemNumber/@origin'
                            (IsLastPart) and (IsAttribute):
                                if (IsFirstPart) then
                                    AddAttribute(ToXmlNode, PathPart.TrimStart('@'), UseValue)
                                else
                                    AddAttribute(XmlCreatedNode, PathPart.TrimStart('@'), UseValue);

                            // Search/Write: Search or create part of a multilevel path that do not currently exists as a node with blank value
                            (not IsLastPart) and (not IsAttribute) and (PathPart <> ''):
                                if not XmlCreatedNode.IsXmlElement() then begin // Note: NodeIsNull would return true when nodevalue is blank, using not IsXmlElement() instead
                                    NodeExists := SelectSingleNode(ToXmlNode, PathPart, XmlCreatedNode);
                                    if not NodeExists then
                                        AddElement(ToXmlNode, PathPart, '', _ToXmlElement.NamespaceUri(), XmlCreatedNode)  // ie. 'BarcodeQuantity from 'BarcodeQuantity/@enableMultiplier'
                                end else begin
                                    NodeExists := SelectSingleNode(XmlCreatedNode, PathPart, XmlCreatedNode);
                                    if not NodeExists then
                                        AddElement(XmlCreatedNode, PathPart, '', _ToXmlElement.NamespaceUri(), XmlCreatedNode);
                                end;

                            // Fallback: Not the last part of the path and not created in this iteration: Move to either ToXmlNode (first lookup) or current XmlCreatedNode (subsequent lookups)
                            (not IsLastPart) and (PathPart <> ''):
                                if not XmlCreatedNode.IsXmlElement() then // Note: NodeIsNull would return true when nodevalue is blank, using not IsXmlElement() instead
                                    FindNode(ToXmlNode, PathPart, XmlCreatedNode)
                                else
                                    FindNode(XmlCreatedNode, PathPart, XmlCreatedNode);
                        end;
                    end;
                end;

            until _ValueBuffer.Next() = 0;
    end;

    internal procedure AddValueBuffer2XmlNodeAttributes(var _ToXmlNode: XmlNode; var _ValueBuffer: Record "MOB NodeValue Buffer")
    var
        XmlCreatedNode: XmlNode;
        PathParts: List of [Text];
        PartsCount: Integer;
        PathPart: Text;
        UseValue: Text;
        i: Integer;
        IsAttribute: Boolean;
        IsFirstPart: Boolean;
        IsLastPart: Boolean;
    begin
        //
        // _ValueBuffer.Value() input format for attributes:
        // 
        // A value with no special characters (/@) designates an attribute (different from BaseOrderLineElement that defaults to nodes)
        // A value with special characters (/@) is xpath, meaning attributes must be represented as '@attrib'
        //
        // 'xxxx' designates an attribute
        // '/onlineValidation' will be two parts with empty first part and designates a node due to '/'
        // '/onlineValidation/@documentName' will be three parts with second part designating a node, and 3rd part an attribute

        if (_ValueBuffer.FindSet()) then
            repeat
                Clear(XmlCreatedNode);

                //
                // html conversion
                // 
                UseValue := _ValueBuffer.GetValue();
                if _ValueBuffer.IsHtml then
                    // Attributes with html-support (InformationStep.helpLabel) needs double <html><html>-tag to be proberbly parsed at mobile device
                    UseValue := '<html><html>' + UseValue + '</html></html>';

                //
                // Add new Element or Attribute
                // 

                // Split path by '/'  (first part may be empty ie. '/onlineValidation')
                PathParts := _ValueBuffer.Path.Split('/');

                PartsCount := PathParts.Count();
                for i := 1 to PartsCount do begin
                    PathParts.Get(i, PathPart);
                    IsFirstPart := i = 1;
                    IsLastPart := i = PartsCount;
                    IsAttribute := (PartsCount = 1) or (PathPart.StartsWith('@'));

                    // This version: The first non-empty or last part of the Path is always the one to trigger a write, anything else will run FindNode instead.
                    // Multi-level paths requires a SetValue for each level to work, ie '/onlineValidation', then '/onlineValidation/@documentName'
                    case true of
                        (IsLastPart) and (not IsAttribute):
                            if NodeIsNull(XmlCreatedNode) then
                                AddElement(_ToXmlNode, PathPart, UseValue, GetNodeNSURI(_ToXmlNode), XmlCreatedNode)  // ie. 'onlineValidation' from '/onlineValidation'
                            else
                                AddElement(XmlCreatedNode, PathPart, UseValue, GetNodeNSURI(_ToXmlNode), XmlCreatedNode);

                        // Write: Attribute is always a last part of the path and must have a previously created node ie. 'ItemNumber/@origin'
                        (IsLastPart) and (IsAttribute):
                            if (IsFirstPart) then
                                AddAttribute(_ToXmlNode, PathPart.TrimStart('@'), UseValue)
                            else
                                AddAttribute(XmlCreatedNode, PathPart.TrimStart('@'), UseValue);

                        // Search: Not the last part of the path: Move to either ToXmlNode (first lookup) or current XmlCreatedNode (subsequent lookups)
                        (not IsLastPart) and (PathPart <> ''):
                            if NodeIsNull(XmlCreatedNode) then
                                FindNode(_ToXmlNode, PathPart, XmlCreatedNode)
                            else
                                FindNode(XmlCreatedNode, PathPart, XmlCreatedNode);
                    end;
                end;
            until _ValueBuffer.Next() = 0;
    end;

    //
    // ------- CONSTANTS -------
    //

    procedure NS_BASEMODEL(): Text
    begin
        exit(NS_BASEMODEL_Txt);
    end;

    procedure NS_WHSEMODEL(): Text
    begin
        exit(NS_WHSEMODEL_Txt);
    end;

    procedure NS_REQUEST(): Text
    begin
        exit(NS_REQUEST_Txt);
    end;

    procedure NS_RESPONSE(): Text
    begin
        exit(NS_RESPONSE_Txt);
    end;

    procedure NS_REGISTRATIONDATA(): Text
    begin
        exit(NS_REGISTRATIONDATA_Txt);
    end;

    procedure NS_SEARCHPARAMETERS(): Text
    begin
        exit(NS_SEARCHPARAMETERS_Txt);
    end;

    procedure NS_SEARCHRESULT(): Text
    begin
        exit(NS_SEARCHRESULT_Txt);
    end;

    procedure NS_EXTRAINFO(): Text
    begin
        exit(NS_EXTRAINFO_Txt);
    end;

    procedure BASEORDER(): Text[30]
    begin
        exit(BASEORDER_Txt);
    end;

    procedure BASEORDERLINE(): Text[30]
    begin
        exit(BASEORDERLINE_Txt);
    end;

    procedure GROUPORDERLINE(): Text[30]
    begin
        exit(GROUPORDERLINE_Txt);
    end;

    procedure RESPONSEDATA(): Text[30]
    begin
        exit(RESPONSEDATA_Txt);
    end;

    procedure LOOKUPRESPONSE(): Text[30]
    begin
        exit(LOOKUPRESPONSE_Txt);
    end;

    procedure REGISTRATIONCOLLECTOR(): Text
    begin
        exit(REGISTRATIONCOLLECTOR_Txt);
    end;

    /// <summary>
    /// Strips any array index from a path part, e.g. "include[1]" becomes "include"
    /// </summary>    
    local procedure StripArrayIndex(_PathPart: Text): Text
    var
        BracketPos: Integer;
    begin
        // Strip array indices like [1], [2], etc. from path parts
        // e.g., "include[1]" becomes "include"
        BracketPos := _PathPart.IndexOf('[');
        if BracketPos > 0 then
            exit(_PathPart.Substring(1, BracketPos - 1))
        else
            exit(_PathPart);
    end;
}
