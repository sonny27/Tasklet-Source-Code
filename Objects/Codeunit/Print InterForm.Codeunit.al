codeunit 81421 "MOB Print InterForm"
{
    Access = Public;
    // Printing from mobile, via InterForm as online print service

    // Terminology: 
    // Request: XML Request to Interform containing the data to print a label.
    // Template or Label-Template: The name of Label to print. Templates have a Name and an URL.


    var
        MobPrintSetup: Record "MOB Print Setup";
        MobPrint: Codeunit "MOB Print";
        MobXmlMgt: Codeunit "MOB XML Management";
        MobToolbox: Codeunit "MOB Toolbox";
        MobHttpHelper: Codeunit "MOB HTTP Helper";
        MobJsonHelper: Codeunit "MOB JSON Helper";
        SetupRead: Boolean;
        PDF_Txt: Label 'pdf', Locked = true;
        SuggestionTxt: Label 'Suggestion: ';
        ReplaceTemplatesTxt: Label 'Do you want to create the standard label-templates?';
        AreYouUsingCorrectUserNamePasswordErr: Label 'Are you using correct Username/Password and Connection URL?';
        FailedErr: Label 'Send to print service failed.\\Status Code: %1\\%2\\Url: %3\\Message: %4', Comment = '%1 contains status code. %2 contains fix suggestion. %3 contains URL. %4 contains message';
        FailedResponseErr: Label 'An empty reponse was received from the Cloud print service.';
        FailedResponseNoPdfErr: Label 'The returned Preview is not a valid PDF.';
        TemplatesCreatedTxt: Label '%1 label-templates has been created.', Comment = '%1 contains number of label-templates';
        // Note: URLs are case-sensitive
        TaskletConnectionURLNg2Txt: Label 'https://cloudprint.taskletfactory.com:8086/', Locked = true;
        TaskletConnectionTenantNg2Txt: Label 'COMMONBC', Locked = true;
        PreviewUrlTxt: Label 'rest/tempStorage/', Locked = true;
        Template_ItemLabel_4x1_URLTxt: Label '/ItemLabels/NAV/standard_item_nav_gs1_datamatrix_4x1_v1.ift', Locked = true;
        Template_ItemLabel_4x2_URLTxt: Label '/ItemLabels/NAV/standard_item_nav_gs1_datamatrix_4x2_v3.ift', Locked = true;
        Template_ItemLabel_4x3_URLTxt: Label '/ItemLabels/NAV/standard_item_nav_gs1_datamatrix_4x3_v1.ift', Locked = true;
        Template_ItemLabel_4x6_URLTxt: Label '/ItemLabels/NAV/standard_item_nav_gs1_datamatrix_4x6_v3.ift', Locked = true;
        Template_ItemLabel_3x2_URLTxt: Label '/ItemLabels/NAV/standard_item_nav_gs1_datamatrix_3x2_v2.ift', Locked = true;
        Template_ItemLabel_2x1_URLTxt: Label '/ItemLabels/NAV/standard_item_nav_gs1_datamatrix_2x1_v1.ift', Locked = true;
        Template_Generic_OrderList_4x6_URLTxt: Label '/Orderlist/standard_generic_orderlist_4x6_v3.ift', Locked = true;
        Template_Generic_OrderList_GS1_4x6_URLTxt: Label '/Orderlist/standard_generic_orderlist_gs1_4x6_v1.ift', Locked = true;
        Template_LicensePlate_QR_3x2_URLTxt: Label '/LicensePlate/NAV/standard_lp_nav_qr_3x2_v2.ift', Locked = true;
        Template_LicensePlate_GS1_3x2_URLTxt: Label '/LicensePlate/NAV/standard_lp_nav_gs1_3x2_v1.ift', Locked = true;

    //
    // -------------------------------- Web Service ------------------------------
    //

    /// <summary>
    /// Send Request to InterForm
    /// </summary>
    procedure SendPrint(_Request: Text; var _PrintParameter: Record "MOB Print REST Parameter" temporary)
    var
        RequestContent: HttpContent;
        ContentHeaders: HttpHeaders;
        JsonResponse: JsonObject;
        ResponseAsText: Text;
        ResponseMessage: HttpResponseMessage;
        Suggestion: Text;
    begin
        AddConnectionDetails(_PrintParameter);

        _PrintParameter.RestMethod := _PrintParameter.RestMethod::post;

        _Request := 'xml=' + _Request;

        RequestContent.WriteFrom(_Request);
        RequestContent.GetHeaders(ContentHeaders);
        ContentHeaders.Remove('Content-Type');
        ContentHeaders.Add('Content-Type', 'application/x-www-form-urlencoded');
        _PrintParameter.SetRequestContent(RequestContent);

        // NG2 requires Token
        if _PrintParameter.Tenant <> '' then
            GetToken(_PrintParameter);

        // This section reads the response as JSON. This is specific from printing.
        if MobHttpHelper.TrySend(_PrintParameter) then begin

            _PrintParameter.GetResponseMessage(ResponseMessage);

            // Get and Read response
            ResponseAsText := _PrintParameter.GetResponseContentAsText(0);
            if JsonResponse.ReadFrom(ResponseAsText) then begin
                _PrintParameter."Result URL" := MobJsonHelper.GetValueAsText(JsonResponse, 'filename');
                _PrintParameter."Result Size" := MobJsonHelper.GetValueAsInteger(JsonResponse, 'size');
            end;

            if (ResponseAsText = '') or (not _PrintParameter."Result IsSuccessStatusCode") then
                Error(FailedResponseErr);

        end else begin
            // Show error
            GetFixSuggestion(_PrintParameter, Suggestion);
            Error(FailedErr, _PrintParameter."Result HttpStatusCode", Suggestion, _PrintParameter.URL, _PrintParameter.GetResponseContentAsText(0));
        end;

    end;

    /// <summary>
    /// Display preview PDF from a previous print request
    /// </summary>
    internal procedure TemplateShowPreview(var _PrintParameter: Record "MOB Print REST Parameter")
    var
        ResponseAsXmlDoc: XmlDocument;
        ResponseXmlAsText: Text;
        Filename: Text;
    begin
        // A Pdf filename is returned
        _PrintParameter.GetResponseContentAsBase64Text(ResponseXmlAsText);
        MobXmlMgt.DocReadText(ResponseAsXmlDoc, ResponseXmlAsText);
        Filename := MobXmlMgt.XPathInnerText(ResponseAsXmlDoc, '//tempStorage/filename');

        // Display Pdf
        if not Filename.Contains(PDF_Txt) then
            Error(FailedResponseNoPdfErr);

        System.Hyperlink(GetPreviewUrl() + Filename);
    end;

    /// <summary>
    /// Get access token (OAuth2)  
    /// </summary>
    [NonDebuggable]
    local procedure GetToken(var _PrintParameter: Record "MOB Print REST Parameter")
    var
        TempPrintParameter: Record "MOB Print REST Parameter" temporary;
        RequestContent: HttpContent;
        ContentHeaders: HttpHeaders;
        ResponseMessage: HttpResponseMessage;
        JsonResponse: JsonObject;
        ResponseAsText: Text;
        Suggestion: Text;
        OStream: OutStream;
    begin
        TempPrintParameter.URL := GetBaseUrl() + 'oauth/token';
        AddConnectionDetails(TempPrintParameter);
        TempPrintParameter.RestMethod := TempPrintParameter.RestMethod::post;

        RequestContent.WriteFrom('grant_type=password&username=' + TempPrintParameter.UserName + '/' + TempPrintParameter.Tenant + '&password=' + TempPrintParameter.Password);
        RequestContent.GetHeaders(ContentHeaders);
        ContentHeaders.Remove('Content-Type');
        ContentHeaders.Add('Content-Type', 'application/x-www-form-urlencoded');
        TempPrintParameter.SetRequestContent(RequestContent);

        // Static credentials for getting token
        TempPrintParameter.UserName := 'interform';
        TempPrintParameter.Password := 'Io14oarPPnv3Bso10bagGA9Ovns2lvxt';

        if MobHttpHelper.TrySend(TempPrintParameter) then begin

            TempPrintParameter.GetResponseMessage(ResponseMessage);

            // Get and Read response
            ResponseAsText := TempPrintParameter.GetResponseContentAsText(0);
            if JsonResponse.ReadFrom(ResponseAsText) then begin
                _PrintParameter.Token.CreateOutStream(OStream);
                OStream.WriteText(MobJsonHelper.GetValueAsText(JsonResponse, 'access_token'));
                // JsonGetValueAsText('expires_in')
            end;

            if (ResponseAsText = '') or (not TempPrintParameter."Result IsSuccessStatusCode") then
                Error(FailedResponseErr);

        end else begin
            // Show error
            GetFixSuggestion(TempPrintParameter, Suggestion);
            Error(FailedErr, TempPrintParameter."Result HttpStatusCode", Suggestion, TempPrintParameter.URL, TempPrintParameter.GetResponseContentAsText(0));
        end;

    end;

    //
    // -------------------------------- Standard Template Requests ------------------------------
    //

    /// <summary>
    /// Create request with fields from dataset buffer
    /// Transfer data from dataset to XML using the same names
    /// </summary>
    procedure CreateRequest(var _Dataset: Record "MOB Common Element"; _LabelTemplate: Record "MOB Label-Template") _TemplateAsXmlDoc: XmlDocument
    var
        TempNodeValueBuffer: Record "MOB NodeValue Buffer" temporary;
        LabelsNode: XmlNode;
        LabelNode: XmlNode;
    begin
        if not _Dataset.FindSet() then
            exit;

        // Init request XML
        InitRequest(_TemplateAsXmlDoc, _Dataset, LabelsNode);

        repeat
            // Send each label
            MobXmlMgt.AddElement(LabelsNode, 'Label', '', '', LabelNode);

            // Flush dataset values
            _Dataset.GetSharedNodeValueBuffer(TempNodeValueBuffer);
            TempNodeValueBuffer.SetCurrentKey("Reference Key", Sorting);    // Sort by inserted order
            if TempNodeValueBuffer.FindSet() then
                repeat
                    if StrPos(TempNodeValueBuffer.Path, '_Label') = 0 then  // Ignore Node_Labels. They are written along with it's corresponding node as they need to be adjacent in the Xml to InterForm
                        AddLabelAndValue(LabelNode, TempNodeValueBuffer.Path, _Dataset);
                until TempNodeValueBuffer.Next() = 0;
            TempNodeValueBuffer.SetCurrentKey("Reference Key", Path);   // Restore primary key sorting since this is a shared scope variable

        until _Dataset.Next() = 0;
    end;


    //
    // -------------------------------- Template Request Helper ------------------------------
    //

    /// <summary>
    /// Initialize a XML request for Interform 
    /// Adds mandatory fields
    /// </summary>
    local procedure InitRequest(var _TemplateAsXmlDoc: XmlDocument; var _Dataset: Record "MOB Common Element"; var _LabelsNode: XmlNode)
    var
        RootNode: XmlNode;
    begin
        MobXmlMgt.InitializeDoc(_TemplateAsXmlDoc, 'LabelContent');
        MobXmlMgt.GetDocRootNode(_TemplateAsXmlDoc, RootNode);

        // <PrinterSetting> & <CompanyInfo> Nodes
        AddMandatoryFieldsToRequest(_TemplateAsXmlDoc, _Dataset);

        // <Label> Node
        MobXmlMgt.AddElement(RootNode, 'Labels', '', '', _LabelsNode);
    end;

    /// <summary>
    /// Adds a set of "Value" and "Label" nodes to XML request
    /// Including potential parent nodes if they do not already exist (i.e. path = first/middle/last)
    /// </summary>
    local procedure AddLabelAndValueNodes(var _ToNode: XmlNode; _Name: Text; _Label: Text; _Value: Text)
    var
        LastNode: XmlNode;
        CreatedNode: XmlNode;
        PathParts: List of [Text];
        i: Integer;
        PathPart: Text;
        LastPart: Boolean;
        FirstPart: Boolean;
        PartsCount: Integer;
    begin
        _Name := DelChr(_Name, '<', '/'); // Removed prefixed slash if present
        PathParts := _Name.Split('/');
        PartsCount := PathParts.Count();

        // Add as a single node and exit
        if PartsCount = 1 then begin
            MobXmlMgt.AddElement(_ToNode, _Name, '', '', LastNode);
            MobXmlMgt.AddElement(LastNode, 'Label', _Label, '', CreatedNode);
            MobXmlMgt.AddElement(LastNode, 'Value', _Value, '', CreatedNode);
            exit;
        end;

        // Add parent nodes if they do not already exist PLUS the last node itself
        for i := 1 to PartsCount do begin
            PathParts.Get(i, PathPart);
            FirstPart := i = 1;
            LastPart := i = PartsCount;

            // Part of path "FIRST/MIDDLE/last"
            if not LastPart then begin
                // First node = Search for existing node in ToNode
                if FirstPart then
                    if not _ToNode.SelectSingleNode(PathPart, CreatedNode) then
                        CreatedNode := _ToNode; // Re-use ToNode

                // Middle node = Search for existing node locally
                if (not CreatedNode.SelectSingleNode(PathPart, CreatedNode)) and (CreatedNode.AsXmlElement().Name() <> PathPart) then // Could be already selected
                    MobXmlMgt.AddElement(CreatedNode, PathPart, '', '', CreatedNode);  // Insert the middle path

            end else begin
                // End of path. Ie. "first/middle/LAST"
                MobXmlMgt.AddElement(CreatedNode, PathPart, '', '', LastNode);
                MobXmlMgt.AddElement(LastNode, 'Label', _Label, '', CreatedNode);
                MobXmlMgt.AddElement(LastNode, 'Value', _Value, '', CreatedNode);
            end;
        end;
    end;

    /// <summary>
    /// Overload for when Label and Value names match i.e. "Joe" and "Joe_Label"
    /// </summary>
    local procedure AddLabelAndValue(var _ParentNode: XmlNode; _Name: Text; var _Dataset: Record "MOB Common Element")
    begin
        if _Dataset.GetValue(_Name, false) <> '' then  // Dont export the tag if there is no value.
            AddLabelAndValueNodes(_ParentNode, _Name, _Dataset.GetValue(_Name + '_Label', false), _Dataset.GetValue(_Name, false));
    end;

    local procedure AddMandatoryFieldsToRequest(var _TemplateAsXmlDoc: XmlDocument; var _Dataset: Record "MOB Common Element")
    var
        CompanyInformation: Record "Company Information";
        FormatAddress: Codeunit "Format Address";
        RootNode: XmlNode;
        PrinterSettingsNode: XmlNode;
        CompanyInfoNode: XmlNode;
        TempNode: XmlNode;
        AddrArray: array[10] of Text[50];
    begin
        if CompanyInformation.FindFirst() then; // To avoid error if company info does not exist (fields will be empty)
        MobXmlMgt.GetDocRootNode(_TemplateAsXmlDoc, RootNode);

        // - Printer Settings
        MobXmlMgt.AddElement(RootNode, 'PrinterSettings', '', '', PrinterSettingsNode);
        MobXmlMgt.AddElement(PrinterSettingsNode, 'PrintCopies', _Dataset.GetValue('PrintCopies'), '', TempNode);
        MobXmlMgt.AddElement(PrinterSettingsNode, 'PrinterName', _Dataset.GetValue('PrinterName'), '', TempNode);
        MobXmlMgt.AddElement(PrinterSettingsNode, 'PrinterAddress', _Dataset.GetValue('PrinterAddress'), '', TempNode);
        MobXmlMgt.AddElement(PrinterSettingsNode, 'dpi', _Dataset.GetValue('dpi'), '', TempNode);
        MobXmlMgt.AddElement(PrinterSettingsNode, 'DesignID', _Dataset.GetValue('DesignID'), '', TempNode);
        MobXmlMgt.AddElement(PrinterSettingsNode, 'TemplatePath', _Dataset.GetValue('TemplatePath'), '', TempNode);

        // - Company Info
        FormatAddress.Company(AddrArray, CompanyInformation);
        MobXmlMgt.AddElement(RootNode, 'CompanyInfo', '', '', CompanyInfoNode);
        MobXmlMgt.AddElement(CompanyInfoNode, 'CompanyId', CompanyInformation.Name, '', TempNode);
        MobXmlMgt.AddElement(CompanyInfoNode, 'CompanyName', CompanyInformation.Name, '', TempNode);
        MobXmlMgt.AddElement(CompanyInfoNode, 'ServiceUser', _Dataset.GetValue('ServiceUser'), '', TempNode);
        MobXmlMgt.AddElement(CompanyInfoNode, 'CompanyLogisticsPostalAddress',
                            AddrArray[2] + MobToolbox.CRLFSeparator() +
                            AddrArray[3] + MobToolbox.CRLFSeparator() +
                            AddrArray[4] + MobToolbox.CRLFSeparator() +
                            AddrArray[5], '', TempNode);
    end;

    //
    // -------------------------------- Misc. Helper ------------------------------
    //

    /// <summary>
    /// Get Caption ENU for a LabelTemplateHandler enum value
    /// </summary>
    /// <remarks>
    /// Enum.Names and Enum.Ordinals are unsupported in BC14. This method works for all BC versions
    /// </remarks>
    internal procedure GetLabelTemplateHandlerCaptionENU(_LabelTemplateHandler: Enum "MOB Label-Template Handler") ReturnCaptionENU: Text
    var
        CurrentLanguage: Integer;
    begin
        CurrentLanguage := GlobalLanguage();
        GlobalLanguage(1033); // ENU
        ReturnCaptionENU := Format(_LabelTemplateHandler);
        GlobalLanguage(CurrentLanguage);

        exit(ReturnCaptionENU);
    end;

    /// <summary>
    /// Show some useful help to common HTTP connection errors
    /// </summary>    
    local procedure GetFixSuggestion(_PrintParameter: Record "MOB Print REST Parameter"; var _Suggestion: Text)
    begin
        case _PrintParameter."Result HttpStatusCode" of
            -1: // HttpClient.Send() failed
                _Suggestion := _PrintParameter."Result ReasonPhrase";
            401:
                _Suggestion := AreYouUsingCorrectUserNamePasswordErr;
        end;

        if StrLen(_Suggestion) > 0 then
            _Suggestion := SuggestionTxt + _Suggestion;
    end;

    local procedure AddConnectionDetails(var _PrintParameter: Record "MOB Print REST Parameter" temporary)
    begin
        _PrintParameter.UserName := GetUsername();
        _PrintParameter.Password := GetPassword();
        _PrintParameter.Tenant := GetTenant();

        MobToolbox.Text2UrlEncodedText(_PrintParameter.UserName);
        MobToolbox.Text2UrlEncodedText(_PrintParameter.Password);
        MobToolbox.Text2UrlEncodedText(_PrintParameter.Tenant);

        if _PrintParameter.URL = '' then
            if _PrintParameter.Tenant <> '' then // If Tenant then NG2 is used
                _PrintParameter.URL := GetBaseUrl() + 'webservice/' + GetWorkflowURL(_PrintParameter."Label-Template Name") // <Connection URL>/webservice/<Workflow URL> 
            else
                _PrintParameter.URL := GetBaseUrl() + GetWorkflowURL(_PrintParameter."Label-Template Name"); // <Connection URL>/<Workflow URL>
                                                                                                             //
    end;

    // -------------------------------- Setup --------------------------------
    //

    procedure CreateConnectionSetup(var _Rec: Record "MOB Print Setup")
    begin
        // Connection details
        _Rec."Connection Username" := 'Contact Tasklet for Username/Password';
        _Rec."Connection Password" := '1234';
        SetConnectionUrl(_Rec);
    end;

    procedure SetConnectionUrl(var _Rec: Record "MOB Print Setup")
    begin
        _Rec."Connection URL" := TaskletConnectionURLNg2Txt;
        _Rec."Connection Tenant" := TaskletConnectionTenantNg2Txt;
    end;

    /// <summary>
    /// Creates or updates supported templates
    /// </summary>
    procedure CreateTemplates(var _Rec: Record "MOB Label-Template"; _Confirm: Boolean)
    var
        LabelTemplateHandler: Enum "MOB Label-Template Handler";
        NameENU: Text;
    begin
        // Also used by Install/Upgrade
        _Rec.Reset();
        if (not _Rec.IsEmpty()) and _Confirm and GuiAllowed() then
            if not Confirm(ReplaceTemplatesTxt, false) then exit;

        // Difference between Name and DisplayName:
        // Names uses ENU caption values, since this is used for customizations (unlike Display Name which is translated)
        // The caption is used instead of the ordinal name to remove app extension prefixes from extended enum values (i.e. "MOS License Plate Contents")
        NameENU := GetLabelTemplateHandlerCaptionENU(LabelTemplateHandler::"Item Label");
        MobPrint.InsertTemplate(_Rec, NameENU + ' 4x1', Format(LabelTemplateHandler::"Item Label") + ' 4x1', Template_ItemLabel_4x1_URLTxt, LabelTemplateHandler::"Item Label");
        MobPrint.InsertTemplate(_Rec, NameENU + ' 4x2', Format(LabelTemplateHandler::"Item Label") + ' 4x2', Template_ItemLabel_4x2_URLTxt, LabelTemplateHandler::"Item Label");
        MobPrint.InsertTemplate(_Rec, NameENU + ' 4x3', Format(LabelTemplateHandler::"Item Label") + ' 4x3', Template_ItemLabel_4x3_URLTxt, LabelTemplateHandler::"Item Label");
        MobPrint.InsertTemplate(_Rec, NameENU + ' 4x6', Format(LabelTemplateHandler::"Item Label") + ' 4x6', Template_ItemLabel_4x6_URLTxt, LabelTemplateHandler::"Item Label");
        MobPrint.InsertTemplate(_Rec, NameENU + ' 3x2', Format(LabelTemplateHandler::"Item Label") + ' 3x2', Template_ItemLabel_3x2_URLTxt, LabelTemplateHandler::"Item Label");
        MobPrint.InsertTemplate(_Rec, NameENU + ' 2x1', Format(LabelTemplateHandler::"Item Label") + ' 2x1', Template_ItemLabel_2x1_URLTxt, LabelTemplateHandler::"Item Label");

        NameENU := GetLabelTemplateHandlerCaptionENU(LabelTemplateHandler::"Sales Shipment");
        MobPrint.InsertTemplate(_Rec, NameENU + ' 4x6', Format(LabelTemplateHandler::"Sales Shipment") + ' 4x6', Template_Generic_OrderList_4x6_URLTxt, LabelTemplateHandler::"Sales Shipment");

        NameENU := GetLabelTemplateHandlerCaptionENU(LabelTemplateHandler::"Warehouse Shipment");
        MobPrint.InsertTemplate(_Rec, NameENU + ' 4x6', Format(LabelTemplateHandler::"Warehouse Shipment") + ' 4x6', Template_Generic_OrderList_4x6_URLTxt, LabelTemplateHandler::"Warehouse Shipment");

        NameENU := GetLabelTemplateHandlerCaptionENU(LabelTemplateHandler::"License Plate");
        MobPrint.InsertTemplateDisabled(_Rec, NameENU + ' 3x2', Format(LabelTemplateHandler::"License Plate") + ' 3x2', Template_LicensePlate_QR_3x2_URLTxt, LabelTemplateHandler::"License Plate");
        MobPrint.InsertTemplate(_Rec, NameENU + ' GS1 3x2', Format(LabelTemplateHandler::"License Plate") + ' GS1 3x2', Template_LicensePlate_GS1_3x2_URLTxt, LabelTemplateHandler::"License Plate");

        NameENU := GetLabelTemplateHandlerCaptionENU(LabelTemplateHandler::"License Plate Contents");
        MobPrint.InsertTemplateDisabled(_Rec, NameENU + ' 4x6', Format(LabelTemplateHandler::"License Plate Contents") + ' 4x6', Template_Generic_OrderList_4x6_URLTxt, LabelTemplateHandler::"License Plate Contents");
        MobPrint.InsertTemplate(_Rec, NameENU + ' GS1 4x6', Format(LabelTemplateHandler::"License Plate Contents") + ' GS1 4x6', Template_Generic_OrderList_GS1_4x6_URLTxt, LabelTemplateHandler::"License Plate Contents");

        if _Confirm and GuiAllowed() then
            Message(TemplatesCreatedTxt, _Rec.Count());
    end;

    internal procedure GetWorkflowURL(_TemplateName: Text[50]): Text[250]
    var
        MobLabelTemplate: Record "MOB Label-Template";
    begin
        MobLabelTemplate.Get(_TemplateName);

        if MobLabelTemplate."URL Mapping".Contains('/') then // If URL mapping is a file path, it's the path of the Template file on InterForm 
            exit('generic_workflow')                         // Generic workflow is used for URL
        else
            exit(MobLabelTemplate."URL Mapping"); // Not file path = Individual workflow is used for URL (Legacy from MOB5.35)
    end;

    internal procedure TestConnection()
    var
        TempPrintParameter: Record "MOB Print REST Parameter" temporary;
        RequestAsXmlDoc: XmlDocument;
        XmlRootNode: XmlNode;
        XmlReturnNode: XmlNode;
        ResquestXmlAsText: Text;
    begin
        // -- Create request for a demo Label
        TempPrintParameter.URL := GetBaseUrl() + 'webservice/' + 'TestPrintLabel';

        // Xml request for test label
        MobXmlMgt.InitializeDoc(RequestAsXmlDoc, 'body');
        MobXmlMgt.GetDocRootNode(RequestAsXmlDoc, XmlRootNode);
        MobXmlMgt.AddElement(XmlRootNode, 'value', UserId(), '', XmlReturnNode);
        MobXmlMgt.AddElement(XmlRootNode, 'dpi', 'Preview', '', XmlReturnNode);   // Preview means return filname to a hosted Pdf

        // Send request
        MobXmlMgt.DocSaveToText(RequestAsXmlDoc, ResquestXmlAsText);
        MobToolbox.Text2UrlEncodedText(ResquestXmlAsText);
        SendPrint(ResquestXmlAsText, TempPrintParameter);

        // -- Handle demo label response
        TemplateShowPreview(TempPrintParameter);
    end;

    /// <summary>
    /// Create a new template as a copy of this template
    /// </summary>
    internal procedure CopyTemplate(_CopyTemplatePath: Text; _NewName: Text) ReturnNewPath: Text
    var
        TempPrintParameter: Record "MOB Print REST Parameter" temporary;
        RequestAsXmlDoc: XmlDocument;
        XmlRootNode: XmlNode;
        XmlReturnNode: XmlNode;
        ResquestXmlAsText: Text;
        NewPath: Text;
    begin
        // Name is used in Path, so remove illegal chars and replace space with underscore
        _NewName := MobToolbox.TextRemoveNotInCharset(_NewName, MobToolbox.CharsetAlphaNumeric() + ' ');
        _NewName := ConvertStr(_NewName, ' ', '_');

        // Create new path by inserting new name in path to copy from
        if not MobToolbox.PathHelperReplaceFileName(_CopyTemplatePath, _NewName, NewPath) then
            exit;

        // Create request
        TempPrintParameter.URL := GetBaseUrl() + 'webservice/' + 'copy_template';
        MobXmlMgt.InitializeDoc(RequestAsXmlDoc, 'CopyTemplate');
        MobXmlMgt.GetDocRootNode(RequestAsXmlDoc, XmlRootNode);
        MobXmlMgt.AddElement(XmlRootNode, 'TemplateFrom', _CopyTemplatePath, '', XmlReturnNode);
        MobXmlMgt.AddElement(XmlRootNode, 'TemplateTo', NewPath, '', XmlReturnNode);

        // Send request
        MobXmlMgt.DocSaveToText(RequestAsXmlDoc, ResquestXmlAsText);
        MobToolbox.Text2UrlEncodedText(ResquestXmlAsText);
        SendPrint(ResquestXmlAsText, TempPrintParameter);

        ReturnNewPath := NewPath;
    end;

    /// <summary>
    /// If found: Returns the first error message in response XML
    /// </summary>
    internal procedure CheckResponseForError(var _PrintParameter: Record "MOB Print REST Parameter") ReturnErrorMessage: Text
    var
        ResponseAsXmlDoc: XmlDocument;
        ResponseXmlAsText: Text;
    begin
        // Example XML
        // <log>
        //  <children>
        //   <log>
        //    <lines>
        //     <level>ERROR</level>
        //      <message>Error Message Here</message>

        _PrintParameter.GetResponseContentAsBase64Text(ResponseXmlAsText);
        if MobXmlMgt.DocReadText(ResponseAsXmlDoc, ResponseXmlAsText) then
            ReturnErrorMessage := MobXmlMgt.XPathInnerText(ResponseAsXmlDoc, '//level[text()="ERROR"]/following-sibling::message[1]', false); // Find the first occuring error message node
    end;

    local procedure GetSetup()
    begin
        if not SetupRead then
            SetupRead := MobPrintSetup.Get();
    end;

    internal procedure GetBaseUrl(): Text
    begin
        GetSetup();
        exit(MobPrintSetup."Connection URL");
    end;

    local procedure GetPreviewUrl(): Text
    begin
        GetSetup();
        exit(MobPrintSetup."Connection URL" + PreviewUrlTxt);
    end;

    local procedure GetUsername(): Text[80]
    begin
        GetSetup();
        exit(MobPrintSetup."Connection Username");
    end;

    local procedure GetPassword(): Text[80]
    begin
        GetSetup();
        exit(MobPrintSetup."Connection Password");
    end;

    internal procedure GetTenant(): Text[50]
    begin
        GetSetup();
        exit(MobPrintSetup."Connection Tenant");
    end;

    internal procedure Get_Template_Generic_OrderList_4x6_URL(): Text
    begin
        exit(Template_Generic_OrderList_4x6_URLTxt);
    end;

    internal procedure Get_Template_Generic_OrderList_GS1_4x6_URL(): Text
    begin
        exit(Template_Generic_OrderList_GS1_4x6_URLTxt);
    end;

    internal procedure Get_Template_LicensePlate_QR_3x2_URL(): Text
    begin
        exit(Template_LicensePlate_QR_3x2_URLTxt);
    end;

    internal procedure Get_Template_LicensePlate_GS1_3x2_URL(): Text
    begin
        exit(Template_LicensePlate_GS1_3x2_URLTxt);
    end;
}
