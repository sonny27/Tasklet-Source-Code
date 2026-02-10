codeunit 81395 "MOB NS WhseInquiry Management"
{
    Access = Public;
    var
        MUST_BE_TEMPORARY_Err: Label 'Internal error: %1 must be a temporary record.', Locked = true;
        LookupResponseNodeNotFoundErr: Label '%1::LookupResponse/%2', Locked = true;

    /// <summary>
    /// Find first LookupResponse containing a specific nodename/value 
    /// </summary>
    internal procedure FindFirstByNameAndValue(var _LookupResponseValues: Record "MOB NS WhseInquery Element"; _NodeName: Text; _NodeValue: Text; _ErrorIfNotFound: Boolean): Boolean
    var
        xElement: Record "MOB NS WhseInquery Element";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        Done: Boolean;
        IsFound: Boolean;
    begin
        xElement.Copy(_LookupResponseValues);
        if not _LookupResponseValues.FindSet() then
            exit(false);

        Clear(IsFound);
        Done := false;
        while not (IsFound or Done) do begin
            IsFound := _LookupResponseValues.GetValue(_NodeName, false) = _NodeValue;
            if not IsFound then
                Done := (_LookupResponseValues.Next() = 0);
        end;

        if not IsFound then begin
            _LookupResponseValues.Copy(xElement);
            if _ErrorIfNotFound then
                Error(LookupResponseNodeNotFoundErr, MobWmsLanguage.GetMessage('DATA_NOT_FOUND'), _NodeName);
        end;

        exit(IsFound);
    end;

    /// <summary>
    /// Save response Mobile XML LookupResponse Values into Temporary table for easy access from Actions
    /// </summary>
    // EXAMPLE:
    // <?xml version="1.0" encoding="UTF-8"?>
    // <response xmlns="http://schemas.microsoft.com/Dynamics/Mobile/2007/04/Documents/Response" messageid="EBB5E356-DD02-4CA5-A235-F3FA471B6791" status="Completed">
    //   <description />
    //   <responseData xmlns="http://schemas.taskletfactory.com/MobileWMS/WarehouseInquiryDataModel">
    //     <LookupResponse>
    //       <ItemNumber>TF-005</ItemNumber>
    //       <DisplayLine1>Assembly department</DisplayLine1>
    //       ...
    //       <RegistrationCollector><![CDATA[<registrationCollectorConfiguration>....<RegistrationCollector/>
    //     <LookupResponse>
    //       <ItemNumber>TF-005</ItemNumber>
    //       <SerialNumber>11115</SerialNumber>
    //       <DisplayLine1>Packing department</DisplayLine1>
    //       ...
    //       <RegistrationCollector><![CDATA[<registrationCollectorConfiguration>...<RegistrationCollector/>
    //     </LookupResponse>
    //   </responseData>
    // </response>    
    internal procedure SaveLookupResponseValues(var _XmlResponseDoc: XmlDocument; var _LookupResponseValues: Record "MOB NS WhseInquery Element")
    var
        MobXmlMgt: Codeunit "MOB XML Management";
        XmlResponseDataNode: XmlNode;
        XmlLookupResponseNodeList: XmlNodeList;
        LookupResponseNode: XmlNode;
        XmlChildNodeList: XmlNodeList;
        ChildNode: XmlNode;
        NodeName: Text;
        NodeValue: Text;
        i: Integer;
        c: Integer;
    begin
        if not _LookupResponseValues.IsTemporary() then
            Error(MUST_BE_TEMPORARY_Err, _LookupResponseValues.TableCaption());

        if not MobXmlMgt.GetXPathNode(_XmlResponseDoc, '//resp:response/whse:responseData', XmlResponseDataNode) then
            exit;

        // Loop "LookupResponse" nodes
        MobXmlMgt.GetNodeChildNodes(XmlResponseDataNode, XmlLookupResponseNodeList);
        for i := 1 to XmlLookupResponseNodeList.Count() do begin

            MobXmlMgt.GetListItem(XmlLookupResponseNodeList, LookupResponseNode, i);
            _LookupResponseValues.Create();

            // Loop child nodes (values)
            MobXmlMgt.GetNodeChildNodes(LookupResponseNode, XmlChildNodeList);
            for c := 1 to XmlChildNodeList.Count() do begin
                MobXmlMgt.GetListItem(XmlChildNodeList, ChildNode, c);
                NodeName := MobXmlMgt.GetNodeName(ChildNode);
                NodeValue := MobXmlMgt.GetNodeInnerText(ChildNode);
                _LookupResponseValues.SetValue(NodeName, NodeValue);
            end;

            _LookupResponseValues.Save();
        end;

        // move cursor to first record for good measure in case caller is expecting cursor at first record
        if _LookupResponseValues.FindFirst() then;
    end;
}
