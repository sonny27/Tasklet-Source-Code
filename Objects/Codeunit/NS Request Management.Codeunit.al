codeunit 81394 "MOB NS Request Management"
{
    Access = Public;
    var
        MobXmlMgt: Codeunit "MOB XML Management";
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
        MobToolbox: Codeunit "MOB Toolbox";
        MUST_BE_TEMPORARY_Err: Label 'Internal error: %1 must be a temporary record.', Locked = true;

    /// <summary>
    /// Return <requestData/> node
    /// </summary>
    procedure GetRequestDataNode(_XmlRequestDoc: XmlDocument) ReturnNode: XmlNode
    var
        XmlRequestNode: XmlNode;
    begin
        MobXmlMgt.GetDocRootNode(_XmlRequestDoc, XmlRequestNode);
        MobXmlMgt.FindNode(XmlRequestNode, 'requestData', ReturnNode);
        exit(ReturnNode);
    end;

    //
    // ----- PLANNED HELPER -----
    //

    /// <summary>
    /// Return <Order/> node 
    /// </summary>
    internal procedure GetOrderNode(_XmlRequestDoc: XmlDocument) ReturnNode: XmlNode
    var
        XmlRequestNode: XmlNode;
        XmlRequestDataNode: XmlNode;
    begin
        MobXmlMgt.GetDocRootNode(_XmlRequestDoc, XmlRequestNode);
        MobXmlMgt.FindNode(XmlRequestNode, 'requestData', XmlRequestDataNode);
        MobXmlMgt.GetNodeFirstChild(XmlRequestDataNode, ReturnNode);
        exit(ReturnNode);
    end;

    /// <summary>
    /// GetApplicationConfiguration: Extract all configuration name attributes and versions attribute as MOB Common Elements
    /// </summary>

    // The request xml looks like this
    // <?xml version="1.0" encoding="utf-8"?>
    // <request name="GetApplicationConfiguration" created="2024-02-07T15:51:55+01:00" xmlns="http://schemas.microsoft.com/Dynamics/Mobile/2007/04/Documents/Request">
    //   <requestData name="GetApplicationConfiguration">
    //     <applicationConfiguration>
    //       <configuration name="ApplicationConfiguration" version="d843c706c3fc92dbc611371dbca9accd" />
    //       <configuration name="Tweak1" version="bbc0b9efb06640aecb28f1f440682c55"/>
    //       <configuration name="Tweak2" version="d843c706c3fc92dbc611371dbca9accd"/>
    //       <configuration name="Tweak3" version="e06fe48988aa06b90f45cab2d0a79a9d"/>
    //       <configuration name="..." version="fc92dbc611371dbca9accd2dbc6113" />
    //     </applicationConfiguration>
    //   </requestData>
    // </request>    

    internal procedure InitCommonFromApplicationConfigurationNodes(var _XmlRequestDoc: XmlDocument; var _ConfigurationValues: Record "MOB Common Element")
    var
        XmlRequestNode: XmlNode;
        XmlRequestDataNode: XmlNode;
        XmlApplicationConfigurationNode: XmlNode;
        ConfigurationNodeList: XmlNodeList;
        ConfigurationNode: XmlNode;
        ConfigurationName: Text;
        ConfigurationVersion: Text;
        i: Integer;
    begin

        // "request" node
        MobXmlMgt.GetDocRootNode(_XmlRequestDoc, XmlRequestNode);
        if MobXmlMgt.GetNodeHasChildNodes(XmlRequestNode) then begin

            // "requestData" node
            MobXmlMgt.FindNode(XmlRequestNode, 'requestData', XmlRequestDataNode);

            // "applicationConfiguration" node
            MobXmlMgt.GetNodeFirstChild(XmlRequestDataNode, XmlApplicationConfigurationNode);

            // "configuration" nodes
            MobXmlMgt.GetNodeChildNodes(XmlApplicationConfigurationNode, ConfigurationNodeList);
            for i := 1 to ConfigurationNodeList.Count() do begin
                // Loop "configuration" nodes
                MobXmlMgt.GetListItem(ConfigurationNodeList, ConfigurationNode, i);
                MobXmlMgt.GetAttribute(ConfigurationNode, 'name', ConfigurationName);
                MobXmlMgt.GetAttribute(ConfigurationNode, 'version', ConfigurationVersion);

                // Adds a Header Filter to temporary record
                _ConfigurationValues.Create();
                _ConfigurationValues.SetValue('name', ConfigurationName);
                _ConfigurationValues.SetValue('version', ConfigurationVersion);
                _ConfigurationValues.Save();
            end;
        end;
    end;

    /// <summary>
    /// Extract Order Node attributes like 'backendID'
    /// Attributes includes collected values for Header Steps
    /// </summary>
    procedure InitCommonFromXmlOrderNode(_XmlRequestDoc: XmlDocument; var _OrderValues: Record "MOB Common Element")
    var
        XmlOrderNode: XmlNode;
    begin
        XmlOrderNode := GetOrderNode(_XmlRequestDoc);

        _OrderValues.Create();
        _OrderValues.SetValuesFromXmlNodeAttributes(XmlOrderNode);
        _OrderValues.Save();
    end;


    procedure GetOrderValues(_MessageId: Guid; var _OrderValues: Record "MOB Common Element")
    var
        MobRequestMgt: Codeunit "MOB NS Request Management";
        XmlRequestDoc: XmlDocument;
    begin
        // Extract custom StepsOnPosting values from attributes at the <Order> node
        GetXMLRequestByMessageID(_MessageId, XmlRequestDoc);
        MobRequestMgt.InitCommonFromXmlOrderNode(XmlRequestDoc, _OrderValues);
    end;

    local procedure GetXMLRequestByMessageID(_MessageId: Guid; var _XmlRequestDoc: XmlDocument): Boolean
    var
        MobDocumentQueue: Record "MOB Document Queue";
    begin
        MobDocumentQueue.GetByGuid(_MessageId, MobDocumentQueue);
        exit(MobDocumentQueue.LoadXMLRequestDoc(_XmlRequestDoc));
    end;

    /// <summary>
    /// Gets whether a request has Force attribute/node
    /// </summary>
    internal procedure GetRequestIsForce(_XmlRequestDoc: XmlDocument) ReturnValue: Boolean
    var
        RequestDataNode: XmlNode;
        ForceNode: XmlNode;
        TempText: Text;
    begin
        // Unplanned functions
        // Look for <Requestdata\Force> node
        RequestDataNode := GetRequestDataNode(_XmlRequestDoc);
        TempText := MobXmlMgt.FindNodeAndValue(RequestDataNode, 'force', ForceNode);

        if TempText = '' then
            TempText := MobXmlMgt.FindNodeAndValue(RequestDataNode, 'Force', ForceNode);

        ReturnValue := MobToolbox.Text2Boolean(TempText);
    end;

    /// <summary>
    /// Gets whether a request has Force attribute/node
    /// </summary>

    // The request xml looks like this
    // <request name="LockOrder" created="2020-12-23T15:30:23+01:00" xmlns="http://schemas.microsoft.com/Dynamics/Mobile/2007/04/Documents/Request">
    //   <requestData name="LockOrder">
    //     <BackendID>PI000007</BackendID>
    //     <Type>Pick</Type>
    //     <Force>True</Force>  
    //   </requestData>
    // </request>

    procedure GetRequestIsForce(var _RequestValues: Record "MOB NS Request Element") ReturnIsForce: Boolean
    begin
        ReturnIsForce := _RequestValues.GetValueAsBoolean('Force');
        if not ReturnIsForce then
            ReturnIsForce := _RequestValues.GetValueAsBoolean('force');
    end;

    //
    // ----- UNPLANNED HANDLER (Adhoc) -----
    //

    /// <summary>
    /// Save incoming Mobile XML Request Header Filters into Temporary table for easy processing
    /// </summary>
    /// <remarks>
    /// -- EXAMPLE
    ///  <request name="GetPickOrders" created="2019-09-02T10:31:12+02:00" xmlns="http://schemas.microsoft.com/Dynamics/Mobile/2007/04/Documents/Request">
    ///    <requestData name="GetPickOrders">
    ///      <filters xmlns="http://schemas.taskletfactory.com/MobileWMS/FilterData">
    ///        <add sequence="1" name="Location" value="WHITE" />
    ///        <add sequence="2" name="AssignedUser" value="All" />
    ///      </filters>
    ///    </requestData>
    ///  </request>
    /// -- EXAMPLE
    /// </remarks>
    procedure SaveHeaderFilters(var _XmlRequestDoc: XmlDocument; var _HeaderFilter: Record "MOB NS Request Element")
    var
        XmlRequestNode: XmlNode;
        XmlRequestDataNode: XmlNode;
        FiltersNode: XmlNode;
        FilterNodeList: XmlNodeList;
        AddNode: XmlNode;
        FilterName: Text;
        FilterValue: Text;
        i: Integer;
    begin
        if not _HeaderFilter.IsTemporary() then
            Error(MUST_BE_TEMPORARY_Err, _HeaderFilter.TableCaption());

        // "request" node
        MobXmlMgt.GetDocRootNode(_XmlRequestDoc, XmlRequestNode);
        if MobXmlMgt.GetNodeHasChildNodes(XmlRequestNode) then begin

            // "requestData" node
            MobXmlMgt.FindNode(XmlRequestNode, 'requestData', XmlRequestDataNode);

            // "filters" node
            MobXmlMgt.GetNodeFirstChild(XmlRequestDataNode, FiltersNode);

            MobXmlMgt.GetNodeChildNodes(FiltersNode, FilterNodeList);
            for i := 1 to FilterNodeList.Count() do begin
                // Loop "add" nodes
                MobXmlMgt.GetListItem(FilterNodeList, AddNode, i);
                MobXmlMgt.GetAttribute(AddNode, 'name', FilterName);
                MobXmlMgt.GetAttribute(AddNode, 'value', FilterValue);

                // Adds a Header Filter to temporary record
                _HeaderFilter.InsertElement(FilterName, FilterValue);
            end;
        end;
        // HeaderFilters do currently not support ContextValues and Xml structure is unknown -> no call to SetXmlRequestDocument here
    end;

    /// <summary>
    /// Get incoming "Search" Mobile XML Request Type (ie. "ItemSearch" or "BinSearch")
    /// </summary>
    // -- EXAMPLE
    // <request name="Search" created="2023-07-27T08:49:39+02:00" xmlns="http://schemas.microsoft.com/Dynamics/Mobile/2007/04/Documents/Request">
    //   <requestData name="Search">
    //     <Type>ItemSearch</Type>
    //     <parameters xmlns="http://schemas.taskletfactory.com/MobileWMS/SearchParameters">
    //       ...
    //     </parameters>
    //   </requestData>
    // </request>
    // -- EXAMPLE
    procedure GetSearchType(var _XmlRequestDoc: XmlDocument): Text
    var
        TypeNode: XmlNode;
    begin
        MobXmlMgt.GetXPathNode(_XmlRequestDoc, '//req:request/req:requestData/req:Type', TypeNode);
        exit(MobXmlMgt.GetNodeInnerText(TypeNode));
    end;

    /// <summary>
    /// Save incoming "Search" Mobile XML Request Header Filters into Temporary table for easy processing
    /// </summary>
    // -- EXAMPLE
    // <request name="Search" created="2023-07-27T08:49:39+02:00" xmlns="http://schemas.microsoft.com/Dynamics/Mobile/2007/04/Documents/Request">
    //   <requestData name="Search">
    //     <Type>ItemSearch</Type>
    //     <parameters xmlns="http://schemas.taskletfactory.com/MobileWMS/SearchParameters">
    //       <add id="1" name="ItemNo" value="TF-003" />
    //       <add id="2" name="ItemDescription" value="" />
    //       <add id="3" name="ItemCategory" value="" />
    //     </parameters>
    //   </requestData>
    // </request>
    // -- EXAMPLE
    procedure SaveSearchRequestValues(var _XmlRequestDoc: XmlDocument; var _RequestValues: Record "MOB NS Request Element")
    var
        ParametersNode: XmlNode;
        AddNodeList: XmlNodeList;
        AddNode: XmlNode;
        FilterName: Text;
        FilterValue: Text;
        i: Integer;
    begin
        if not _RequestValues.IsTemporary() then
            Error(MUST_BE_TEMPORARY_Err, _RequestValues.TableCaption());

        MobXmlMgt.GetXPathNode(_XmlRequestDoc, '//req:request/req:requestData/SearchParameters:parameters', ParametersNode);
        MobXmlMgt.GetNodeChildNodes(ParametersNode, AddNodeList);
        for i := 1 to AddNodeList.Count() do begin
            // Loop "add" nodes
            MobXmlMgt.GetListItem(AddNodeList, AddNode, i);
            MobXmlMgt.GetAttribute(AddNode, 'name', FilterName);
            MobXmlMgt.GetAttribute(AddNode, 'value', FilterValue);

            // Adds a Header Filter to temporary record
            _RequestValues.InsertElement(FilterName, FilterValue);
        end;
    end;

    /// <summary>
    /// Save incoming Mobile XML Adhoc Request Values (or Filters) into Temporary table for easy processing
    /// </summary>
    // EXAMPLE:
    // <?xml version="1.0" encoding="UTF-8"?>
    // <request xmlns="http://schemas.microsoft.com/Dynamics/Mobile/2007/04/Documents/Request" created="2020-01-15T10:19:20+01:00" name="GetRegistrationConfiguration">
    //    <requestData name="GetRegistrationConfiguration">
    //        <Location>WHITE</Location>
    //        <ItemNumber>tf-003</ItemNumber>
    //        <RegistrationType>UnplannedMove</RegistrationType>
    //    </requestData>
    // </request>
    procedure SaveAdhocRequestValues(var _XmlRequestDoc: XmlDocument; var _RequestValues: Record "MOB NS Request Element")
    var
        XmlRequestNode: XmlNode;
        XmlRequestDataNode: XmlNode;
        XmlRequestDataNodeList: XmlNodeList;
        ChildNode: XmlNode;
        NodeName: Text;
        NodeValue: Text;
        i: Integer;
    begin
        if not _RequestValues.IsTemporary() then
            Error(MUST_BE_TEMPORARY_Err, _RequestValues.TableCaption());

        // "request" node
        MobXmlMgt.GetDocRootNode(_XmlRequestDoc, XmlRequestNode);
        if MobXmlMgt.GetNodeHasChildNodes(XmlRequestNode) then begin

            // "requestData" node
            MobXmlMgt.FindNode(XmlRequestNode, MobWmsToolbox."CONST::requestData"(), XmlRequestDataNode);

            // Loop "child" nodes
            MobXmlMgt.GetNodeChildNodes(XmlRequestDataNode, XmlRequestDataNodeList);
            for i := 1 to XmlRequestDataNodeList.Count() do begin
                MobXmlMgt.GetListItem(XmlRequestDataNodeList, ChildNode, i);
                NodeName := MobXmlMgt.GetNodeName(ChildNode);
                NodeValue := MobXmlMgt.GetNodeInnerText(ChildNode);

                // Adds a Request node to temporary record
                if NodeName <> 'Order' then // <Order>-node is draft registrations for when sendRegistrationData="Order"|"OrderLine" was used from application.cfg and is to be excluded
                    _RequestValues.InsertElement(NodeName, NodeValue);
            end;

            // move cursor to first record for good measure in case caller is expecting cursor at first record
            if _RequestValues.FindFirst() then;
        end;
        _RequestValues.SetXmlRequestDocument(_XmlRequestDoc);   // Internal global variable for access to ContextValues for Adhoc Requests
    end;

    /// <summary>
    /// Overload for legacy reasons  (Used in current customization examples)
    /// </summary>
    procedure SaveAdhocFilters(var _XmlRequestDoc: XmlDocument; var _HeaderFilter: Record "MOB NS Request Element")
    begin
        SaveAdhocRequestValues(_XmlRequestDoc, _HeaderFilter);
    end;

    /// <summary>
    /// Save incoming Mobile XML ContextValues into Temporary table for easy processing
    /// </summary>
    // EXAMPLE:
    // <?xml version="1.0" encoding="utf-8"?>
    // <request name="GetRegistrationConfiguration" created="2020-11-18T16:04:52+01:00" xmlns="http://schemas.microsoft.com/Dynamics/Mobile/2007/04/Documents/Request">
    //   <requestData name="GetRegistrationConfiguration">
    //     <BackendID>101005 - 10000</BackendID>
    //     <ContextValues>
    //       <LookupMessageId>{D8BB3FCB-5194-4B0F-ADC1-5E7497AF2B76}</LookupMessageId>
    //       <LookupResultId>{5508BE8C-CEA6-4767-8757-5ADCB0DD8B28}</LookupResultId>
    //       ...
    //     </ContextValues>
    //     <RegistrationType>ProdOutputQuantity</RegistrationType>
    //   </requestData>
    // </request>    
    internal procedure SaveContextValuesAsWhseInquiryElement(var _XmlRequestDoc: XmlDocument; var _ContextValues: Record "MOB NS WhseInquery Element")
    var
        XmlContextValuesNode: XmlNode;
        XmlContextValuesNodeList: XmlNodeList;
        ChildNode: XmlNode;
        XPath: Text;
        NodeName: Text;
        NodeValue: Text;
        i: Integer;
    begin
        if not _ContextValues.IsTemporary() then
            Error(MUST_BE_TEMPORARY_Err, _ContextValues.TableCaption());

        Clear(_ContextValues);

        XPath := '//req:request/req:requestData/req:ContextValues';
        if not MobXmlMgt.XPathFound(_XmlRequestDoc, XPath) then
            exit;

        MobXmlMgt.GetXPathNode(_XmlRequestDoc, XPath, XmlContextValuesNode);
        if not MobXmlMgt.GetNodeHasChildNodes(XmlContextValuesNode) then
            exit;

        _ContextValues.Create();

        // Loop childnodes for ContextValues 
        MobXmlMgt.GetNodeChildNodes(XmlContextValuesNode, XmlContextValuesNodeList);
        for i := 1 to XmlContextValuesNodeList.Count() do begin
            MobXmlMgt.GetListItem(XmlContextValuesNodeList, ChildNode, i);
            NodeName := MobXmlMgt.GetNodeName(ChildNode);
            NodeValue := MobXmlMgt.GetNodeInnerText(ChildNode);

            _ContextValues.SetValue(NodeName, NodeValue);
        end;
        _ContextValues.Save();
    end;

    internal procedure AddNodeToRequestDataDoc(var _XmlRequestDoc: XmlDocument; _NodeName: Text; _NodeValue: Text)
    var
        RootNode: XmlNode;
        RequestDataNode: XmlNode;
        NewNode: XmlNode;
    begin
        MobXmlMgt.GetDocRootNode(_XmlRequestDoc, RootNode);
        MobXmlMgt.SelectSingleNode(RootNode, 'requestData', RequestDataNode);
        MobXmlMgt.AddElement(RequestDataNode, _NodeName, _NodeValue, MobXmlMgt.NS_REQUEST(), NewNode);
    end;

}
