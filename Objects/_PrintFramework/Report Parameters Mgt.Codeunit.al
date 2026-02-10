codeunit 81308 "MOB ReportParameters Mgt."
{
    Access = Public;
    // Generate the parameter xml string with values to be set in the request page of the report

    // Example of reportparameters:
    // '<?xml version="1.0" standalone="yes"?>' +
    // '<ReportParameters name="XXX Some Item Report" id="50000">' +
    // '  <Options>' +
    // '    <Field name="NoOfCopies">2</Field>' +
    // '    <Field name="ItemVariantCode">BLUE</Field>' +
    // '    <Field name="Quantity">1</Field>' +
    // '    <Field name="UoM">PCS</Field>' +
    // '    <Field name="LotNo">LOT123</Field>' +
    // '    <Field name="ExpirationDate">2029-12-31</Field>' +
    // '    <Field name="SerialNo">SN123</Field>' +
    // '    <Field name="PackageNo">PN123</Field>' +
    // '  </Options>' +
    // '  <DataItems>' +
    // '    <DataItem name="Item">VERSION(1) SORTING(Field1) WHERE(Field1=1(ITEM123))</DataItem>' +
    // '  </DataItems>' +
    // '</ReportParameters>';

    var
        MobXmlMgt: Codeunit "MOB XML Management";
        NoReqPageHandlerErr: Label 'No event subscriber found to create request page parameters for requestpage handler "%1"', Locked = true;

    internal procedure CreateReportParameters(var _MobReport: Record "MOB Report"; var _SourceRecRef: RecordRef; var _RequestValues: Record "MOB NS Request Element" temporary) ReturnReportParameters: Text
    var
        TempOptionsFieldValues: Record "MOB ReportParameters Element" temporary;
        TempDataItemViews: Record "MOB ReportParameters Element" temporary;
        IsHandled: Boolean;
    begin
        // Initialize temporary ReportParameters Element tables
        TempOptionsFieldValues.Create();
        TempDataItemViews.Create();

        // The event publisher below triggers these procedures in MOB:
        //    "MOB ReqPage Handler Item Label".OnCreateReportParameters()
        //    "MOB ReqPage Handler LP".OnCreateReportParameters()
        //    "MOB ReqPage Hdl. LP Contents".OnCreateReportParameters()
        //    "MOB ReqPage Handler None".OnCreateReportParameters()
        // Custom subscribers can add support for new reports and can customize values from the above inbuilt subscribers
        IsHandled := false;
        OnCreateReportParameters(_MobReport, _SourceRecRef, _RequestValues, TempOptionsFieldValues, TempDataItemViews, IsHandled);
        if not IsHandled then
            Error(NoReqPageHandlerErr, _MobReport."RequestPage Handler");

        // Return the result
        ReturnReportParameters := GetReportParametersXml(_MobReport, TempOptionsFieldValues, TempDataItemViews);
        exit(ReturnReportParameters);
    end;

    local procedure GetReportParametersXml(var _MobReport: Record "MOB Report"; var _OptionsFieldValues: Record "MOB ReportParameters Element"; var _DataItemViews: Record "MOB ReportParameters Element") ReturnReportParametersXml: Text
    var
        XmlParameterDoc: XmlDocument;
        ReportParametersNode: XmlNode;
    begin
        // Build the xml document
        ReportParametersInitialization(_MobReport, XmlParameterDoc, ReportParametersNode);
        ReportParametersAddOptions(ReportParametersNode, _OptionsFieldValues);
        ReportParametersAddDataItems(ReportParametersNode, _DataItemViews);

        // Return the result
        XmlParameterDoc.WriteTo(ReturnReportParametersXml);
        exit(ReturnReportParametersXml);
    end;

    local procedure ReportParametersInitialization(var _MobReport: Record "MOB Report"; var _XmlParameterDoc: XmlDocument; var _ReportParametersNode: XmlNode)
    var
        AllObj: Record AllObj;
        XmlRootElement: XmlElement;
    begin
        // Init
        _MobReport.TestField("Report ID");
        AllObj.Get(AllObj."Object Type"::Report, _MobReport."Report ID");

        // Initialize the Parameter xml doc
        if not MobXmlMgt.DocIsNull(_XmlParameterDoc) then
            Clear(_XmlParameterDoc);

        MobXmlMgt.GetDocDocElement(_XmlParameterDoc);
        MobXmlMgt.DocReadText(_XmlParameterDoc, '<?xml version="1.0" standalone="yes"?><ReportParameters/>');

        // Path: /ReportParameters
        _XmlParameterDoc.GetRoot(XmlRootElement);
        _ReportParametersNode := XmlRootElement.AsXmlNode();
        MobXmlMgt.AddAttribute(_ReportParametersNode, 'name', AllObj."Object Name");
        MobXmlMgt.AddAttribute(_ReportParametersNode, 'id', Format(AllObj."Object ID", 0, 9));
    end;

    local procedure ReportParametersAddOptions(var _ReportParametersNode: XmlNode; var _OptionsFieldValues: Record "MOB ReportParameters Element")
    var
        TempNodeValueBuffer: Record "MOB NodeValue Buffer" temporary;
        OptionsNode: XmlNode;
        FieldNode: XmlNode;
    begin
        // The Options node contains the varibles shown on the Options tab of the report request page
        MobXmlMgt.AddElement(_ReportParametersNode, 'Options', '', '', OptionsNode); // Path: /ReportParameters/Options

        // Populate Option Values from ReportParameters Element" table to buffer table
        _OptionsFieldValues.GetSharedNodeValueBuffer(TempNodeValueBuffer);
        TempNodeValueBuffer.SetCurrentKey("Reference Key", Sorting);    // Sort by inserted order
        if TempNodeValueBuffer.FindSet() then
            repeat
                // Path: /ReportParameters/Options/Field
                MobXmlMgt.AddElement(OptionsNode, 'Field', TempNodeValueBuffer.GetValue(), '', FieldNode);
                MobXmlMgt.AddAttribute(FieldNode, 'name', TempNodeValueBuffer.Path);
            until TempNodeValueBuffer.Next() = 0;
    end;

    local procedure ReportParametersAddDataItems(var _ReportParametersNode: XmlNode; var _DataItemViews: Record "MOB ReportParameters Element")
    var
        TempNodeValueBuffer: Record "MOB NodeValue Buffer" temporary;
        DataItemsNode: XmlNode;
        DataItemNode: XmlNode;
    begin
        // The DataItems node contains the filters (views) of the dataitems shown in the report request page
        MobXmlMgt.AddElement(_ReportParametersNode, 'DataItems', '', '', DataItemsNode); // Path: /ReportParameters/DataItems

        // Populate Data Item Views from ReportParameters Element table to buffer table
        _DataItemViews.GetSharedNodeValueBuffer(TempNodeValueBuffer);
        TempNodeValueBuffer.SetCurrentKey("Reference Key", Sorting);    // Sort by inserted order
        if TempNodeValueBuffer.FindSet() then
            repeat
                // Path: /ReportParameters/DataItems/DataItem
                MobXmlMgt.AddElement(DataItemsNode, 'DataItem', TempNodeValueBuffer.GetValue(), '', DataItemNode);
                MobXmlMgt.AddAttribute(DataItemNode, 'name', TempNodeValueBuffer.Path);
            until TempNodeValueBuffer.Next() = 0;
    end;

    // ----- EVENT

    [IntegrationEvent(false, false)]
    local procedure OnCreateReportParameters(_MobReport: Record "MOB Report"; _SourceRecRef: RecordRef; var _RequestValues: Record "MOB NS Request Element" temporary; var _OptionsFieldValues: Record "MOB ReportParameters Element"; var _DataItemViews: Record "MOB ReportParameters Element"; var _IsHandled: Boolean)
    begin
    end;
}
