codeunit 81296 "MOB PrintNode Mgt."
{
    Access = Internal;

    var
        MobToolbox: Codeunit "MOB Toolbox";
        MobJsonHelper: Codeunit "MOB JSON Helper";
        MobFeatureTelemetryWrapper: Codeunit "MOB Feature Telemetry Wrapper";
        MobTelemetryEventId: Enum "MOB Telemetry Event ID";
        ConnectionOkMsg: Label 'Connection succesfully established.', Locked = true;
        YouMustEnablePrintNodeMsg: Label 'Tasklet PrintNode is not enabled. Would you like to do that now?', Locked = true;
        PrintNodeReturnedXPrintersMsg: Label 'Number of new printers added: %1 out of a total of %2.', Comment = '%1 is number of inserts. %2 is number of printers.', Locked = true;
        FailedErr: Label 'Request to PrintNode API failed.\\Status Code: %1\\Url: %2\\Message: %3\\Error: %4', Locked = true;
        UnauthorizedErr: Label 'Status code %1 received from the PrintNode API. This is typically because of an incorrect PrintNode API Key.', Locked = true;
        DisabledAndUnableToPrintErr: Label 'Unable to print to %1 because the Tasklet PrintNode connector is disabled. Please enable it in the %2.', Locked = true;
        LoadingPrintersMsg: Label 'Processing no. #2 of #1', Locked = true;

    internal procedure IsEnabled(): Boolean
    var
        PrintNodeSetup: Record "MOB PrintNode Setup";
    begin
        if PrintNodeSetup.Get() and PrintNodeSetup.Enabled then
            exit(true);
    end;

    internal procedure CheckConfirmIsEnabled()
    begin
        if IsEnabled() then
            exit;

        MobFeatureTelemetryWrapper.LogUptakeDiscovered(MobTelemetryEventId::"Tasklet PrintNode Feature (MOB1030)");

        if GuiAllowed() then
            if Confirm(YouMustEnablePrintNodeMsg, true) then
                Page.Run(Page::"MOB PrintNode Setup");
    end;

    //
    // -------------------------------- Event Subscribers --------------------------------
    //

    /* #if BC16+ */

    /// <summary>
    /// When user opens "Printer Management" this event discovers available printers. https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-onaftersetupprinters-event
    /// </summary>
    [InherentPermissions(PermissionObjectType::TableData, Database::"MOB PrintNode Printer Settings", 'R', InherentPermissionsScope::Both)]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::ReportManagement, 'OnAfterSetupPrinters', '', true, true)]
    local procedure AddPrintNodePrinters(var Printers: Dictionary of [Text[250], JsonObject])
    var
        MobPrintNodePrinterSettings: Record "MOB PrintNode Printer Settings";
        PaperTrays: JsonArray;
        PaperTray: JsonObject;
        Payload: JsonObject;
        WidthMM: Integer;
        HeightMM: Integer;
    begin
        // Check if required permissions are available
        // For BC21+ everybody has read permissions because of InherentPermissions
        // For BC20- it requires explicit permissions in the permission set
        if not MobPrintNodePrinterSettings.ReadPermission() then
            exit;

        MobPrintNodePrinterSettings.SetFilter(Name, '<>%1', ''); // Never include empty
        if MobPrintNodePrinterSettings.FindSet() then
            repeat
                // Create a JSON payload of this printer
                Clear(Payload);
                Clear(PaperTrays);
                Clear(PaperTray);

                // Add basic info to payload
                Payload.Add('version', 1);
                Payload.Add('description', MobPrintNodePrinterSettings.Description);

                // Create custom PaperTray - If paper height or width is not specified then set the paper size to A4
                if (MobPrintNodePrinterSettings."Page Height" >= 0.1) and (MobPrintNodePrinterSettings."Page Width" >= 0.1) then begin
                    PaperTray.Add('papersourcekind', 'Custom');
                    PaperTray.Add('paperkind', 'Custom');

                    // Convert size from CM to MM rounding down to prevent creating a bigger page than the printer supports
                    WidthMM := Round(MobPrintNodePrinterSettings."Page Width" * 10, 1, '<');
                    HeightMM := Round(MobPrintNodePrinterSettings."Page Height" * 10, 1, '<');
                    PaperTray.Add('width', WidthMM);
                    PaperTray.Add('height', HeightMM);
                    PaperTray.Add('units', 'mm');
                end else begin
                    PaperTray.Add('papersourcekind', 'Upper');
                    PaperTray.Add('paperkind', 'A4');
                end;

                // Add tray to payload
                PaperTrays.Add(PaperTray);
                Payload.Add('papertrays', PaperTrays);

                // Add this printer payload to the event parameter
                Printers.Add(MobPrintNodePrinterSettings.Name, Payload);

            until MobPrintNodePrinterSettings.Next() = 0;
    end;

    /// <summary>
    /// When user opens "Printer Settings" from "Printer Management" this event opens the Card for the printer
    /// </summary>
    [InherentPermissions(PermissionObjectType::TableData, Database::"MOB PrintNode Printer Settings", 'R', InherentPermissionsScope::Both)]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Printer Setup", 'OnOpenPrinterSettings', '', true, true)]
    local procedure AddPrintNodePrinterSettings(PrinterID: Text; var IsHandled: Boolean)
    var
        MobPrintNodePrinterSettings: Record "MOB PrintNode Printer Settings";
    begin
        if MobPrintNodePrinterSettings.Get(PrinterID) then begin
            Page.Run(Page::"MOB PrintNode Printer Settings", MobPrintNodePrinterSettings);
            IsHandled := true;
        end;
    end;

    /// <summary>
    /// When user prints reports, this event will channel the print onto PrintNode
    /// </summary>
    [InherentPermissions(PermissionObjectType::TableData, Database::"MOB PrintNode Printer Settings", 'R', InherentPermissionsScope::Both)]
    [InherentPermissions(PermissionObjectType::TableData, Database::"MOB PrintNode Setup", 'R', InherentPermissionsScope::Both)]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::ReportManagement, 'OnAfterDocumentPrintReady', '', true, true)]
    local procedure PrintDocument(ObjectType: Option "Report","Page"; ObjectId: Integer; ObjectPayload: JsonObject; DocumentStream: InStream; var Success: Boolean)
    var
        MobPrintNodePrinterSettings: Record "MOB PrintNode Printer Settings";
        MobPrintNodeSetup: Record "MOB PrintNode Setup";
    begin
        begin
            if Success then
                exit;
            if ObjectType <> ObjectType::Report then
                exit;
            if not MobPrintNodePrinterSettings.Get(MobJsonHelper.GetValueAsText(ObjectPayload, 'printername')) then
                exit;

            if not IsEnabled() then
                Error(DisabledAndUnableToPrintErr, MobPrintNodePrinterSettings.Name, MobPrintNodeSetup.TableCaption());

            Success := SendPrintJob(ObjectPayload, DocumentStream, MobPrintNodePrinterSettings);

            // Add Telemetry for using the feature
            if Success then
                MobFeatureTelemetryWrapper.LogUptakeUsed(MobTelemetryEventId::"Tasklet PrintNode Feature (MOB1030)");
        end;
    end;

    /* #endif */

    //
    // -------------------------------- Get Printers --------------------------------
    //

    internal procedure AddAllPrinters()
    var
        TempMobPrintNodePrinterSettings: Record "MOB PrintNode Printer Settings" temporary;
    begin
        CheckConfirmIsEnabled();
        if not IsEnabled() then
            exit;

        // Update all printers
        if GetPrinters(TempMobPrintNodePrinterSettings) then
            InsertNewPrinters(TempMobPrintNodePrinterSettings, true);
    end;

    /// <summary>
    /// Get printers from PrintNode. https://www.printnode.com/en/docs/api/curl#printers
    /// </summary>
    internal procedure GetPrinters(var _MobPrintNodePrinters: Record "MOB PrintNode Printer Settings"): Boolean
    var
        RestParameter: Record "MOB Print REST Parameter";
        MobPrintNodeSetup: Record "MOB PrintNode Setup";
        MobTelemetryMgt: Codeunit "MOB Telemetry Management";
        Printers: JsonToken;
        Printer: JsonToken;
        Computer: JsonToken;
        Window: Dialog;
        PrinterNo: Integer;
    begin
        CheckConfirmIsEnabled();
        if not IsEnabled() then
            exit;

        // Request printers from PrintNode
        if TrySendToPrintNode('', StrSubstNo('/printers?limit=%1', MobPrintNodeSetup.GetApiRecordLimit()), RestParameter) then
            if RestParameter.GetResponseContentAsJson(Printers) then begin

                MobTelemetryMgt.LogPrintNodeGetPrinters(Printers);

                Window.Open(LoadingPrintersMsg);
                Window.Update(1, Printers.AsArray().Count());

                // Build temp record of available printers
                foreach Printer in Printers.AsArray() do begin
                    Printer.SelectToken('computer', Computer);
                    _MobPrintNodePrinters.Init();
                    _MobPrintNodePrinters."PrintNode Client Name" := MobJsonHelper.GetValueAsText(Computer, 'name'); // Path: printer/computer/name
                    _MobPrintNodePrinters.Validate("PrintNode Printer ID", MobJsonHelper.GetValueAsText(Printer, 'id')); // Path: printer/id
                    _MobPrintNodePrinters.Name := _MobPrintNodePrinters."PrintNode Client Name" + '\' + MobJsonHelper.GetValueAsText(Printer, 'name'); // Path: printer/name
                    _MobPrintNodePrinters.Description := 'Tasklet PrintNode Printer';
                    _MobPrintNodePrinters.Insert();

                    PrinterNo += 1;
                    Window.Update(2, PrinterNo);
                    Sleep(110); // Sleep 110 ms to ensure staying under 10 req/sec limit of PrintNode (The validation of "PrintNode Printer ID" also calls PrintNode)
                end;
                Window.Close();

                exit(true);
            end;
    end;

    internal procedure InsertNewPrinters(var _MobPrintNodePrinterSettings: Record "MOB PrintNode Printer Settings"; _ShowDialog: Boolean)
    var
        NoOfInserts: Integer;
    begin
        // Insert new printers
        if _MobPrintNodePrinterSettings.FindSet() then
            repeat
                if InsertPrinter(_MobPrintNodePrinterSettings) then
                    NoOfInserts += 1;
            until _MobPrintNodePrinterSettings.Next() = 0;

        if _ShowDialog then
            Message(PrintNodeReturnedXPrintersMsg, NoOfInserts, _MobPrintNodePrinterSettings.Count());
    end;

    /// <summary>
    /// Insert a printer
    /// </summary>
    local procedure InsertPrinter(_MobPrintNodePrinterSettings: Record "MOB PrintNode Printer Settings"): Boolean
    var
        MobPrintNodePrinterSettings: Record "MOB PrintNode Printer Settings";
    begin
        // The unique "Printer ID" is used to ignore existing printers
        MobPrintNodePrinterSettings.SetRange("PrintNode Printer ID", _MobPrintNodePrinterSettings."PrintNode Printer ID");
        if not MobPrintNodePrinterSettings.IsEmpty() then
            exit;

        // Reuse input parameter for insert
        exit(_MobPrintNodePrinterSettings.Insert(true));
    end;

    internal procedure LookupPrintNodePrinters(var _MobPrintNodePrinterSettings: Record "MOB PrintNode Printer Settings")
    var
        TempMobPrintNodePrinterSettings: Record "MOB PrintNode Printer Settings" temporary;
    begin
        CheckConfirmIsEnabled();
        if not IsEnabled() then
            exit;

        // Display available printers to user
        if GetPrinters(TempMobPrintNodePrinterSettings) then
            if Page.RunModal(0, TempMobPrintNodePrinterSettings) = Action::LookupOK then begin
                // Create new using selected printer
                _MobPrintNodePrinterSettings.Validate("PrintNode Printer ID", TempMobPrintNodePrinterSettings."PrintNode Printer ID");
                _MobPrintNodePrinterSettings."PrintNode Client Name" := TempMobPrintNodePrinterSettings."PrintNode Client Name";
                if _MobPrintNodePrinterSettings.Description = '' then
                    _MobPrintNodePrinterSettings.Description := TempMobPrintNodePrinterSettings.Description;
                _MobPrintNodePrinterSettings.Name := TempMobPrintNodePrinterSettings.Name;
            end;
    end;

    //
    // -------------------------------- Printer Capabilities --------------------------------
    //
    internal procedure LoadCapabilities(var _MobPrintNodeLookupCapability: Record "MOB PrintNode LookupCapability")
    var
        Printer: JsonToken;
        Capabilities: JsonToken;
        Papers: JsonToken;
        Bins: JsonToken;
        Paper: JsonToken;
        Bin: JsonToken;
        Width: JsonToken;
        Height: JsonToken;
        WidthDecimal: Decimal;
        HeightDecimal: Decimal;
        ListOfPapers: List of [Text];
        PaperKey: Text;
    begin
        // Use filtered PrinterID
        if GetPrinter(_MobPrintNodeLookupCapability.GetFilter("PrintNode Printer ID Filter"), Printer) then
            // Read capabilities in JSON
            if Printer.SelectToken('capabilities', Capabilities) then begin

                // Get paper formats
                if Capabilities.SelectToken('papers', Papers) then begin
                    ListOfPapers := Papers.AsObject().Keys();
                    foreach PaperKey in ListOfPapers do begin
                        Papers.AsObject().Get(PaperKey, Paper);
                        Paper.SelectToken('[0]', Width);
                        Paper.SelectToken('[1]', Height);

                        if not Width.AsValue().IsNull() then
                            WidthDecimal := MobToolbox.Text2Decimal(Width.AsValue().AsText());
                        if not Height.AsValue().IsNull() then
                            HeightDecimal := MobToolbox.Text2Decimal(Height.AsValue().AsText());

                        _MobPrintNodeLookupCapability.InsertPaperSize(PaperKey, HeightDecimal / 100, WidthDecimal / 100); // Height and Width are converted from 1/10 MM from PrintNode to CM
                    end;
                end;

                // Get Paper Trays
                if Capabilities.SelectToken('bins', Bins) then
                    foreach Bin in Bins.AsArray() do
                        _MobPrintNodeLookupCapability.InsertPaperTray(Bin.AsValue().AsText());
            end;
    end;

    /// <summary>
    /// Get a single known printer from PrintNode. https://www.printnode.com/en/docs/api/curl#printers
    /// </summary>
    internal procedure GetPrinter(_PrinterID: Text; var _Printer: JsonToken): Boolean
    var
        RestParameter: Record "MOB Print REST Parameter";
        Printers: JsonToken;
    begin
        // Request printers from PrintNode
        if TrySendToPrintNode('', '/printers/' + _PrinterID, RestParameter) then
            if RestParameter.GetResponseContentAsJson(Printers) then
                exit(Printers.SelectToken('[0]', _Printer)); // Get root token
    end;

    //
    // -------------------------------- Printing --------------------------------
    //

    internal procedure SendPrintJob(_ObjectPayload: JsonObject; _DocumentStream: InStream; _MobPrintNodePrinterSettings: Record "MOB PrintNode Printer Settings") ReturnSuccess: Boolean
    var
        PrintParameter: Record "MOB Print REST Parameter";
        Request: Text;
    begin
        Request := CreatePrintJobRequest(MobJsonHelper.GetValueAsText(_ObjectPayload, 'objectname'), _DocumentStream, _MobPrintNodePrinterSettings);
        ReturnSuccess := TrySendToPrintNode(Request, '/printjobs', PrintParameter);
    end;

    local procedure CreatePrintJobRequest(_Title: Text; _DocumentInStream: InStream; _MobPrintNodePrinterSettings: Record "MOB PrintNode Printer Settings") ReturnRequest: Text
    var
        MobBase64Convert: Codeunit "MOB Base64 Convert";
        ContentBase64String: Text;
        Payload: JsonObject;
        Options: JsonObject;
    begin
        ContentBase64String := MobBase64Convert.ToBase64(_DocumentInStream);

        Payload.Add('printerId', _MobPrintNodePrinterSettings."PrintNode Printer ID");
        Payload.Add('title', _Title);
        Payload.Add('contentType', 'pdf_base64');
        Payload.Add('content', ContentBase64String);
        Payload.Add('source', 'Business Central - Tasklet Mobile WMS | ' + CompanyName());

        // Add options payload. Options left blank will be using the printer default.
        if _MobPrintNodePrinterSettings."Paper Size" <> '' then
            Options.Add('paper', _MobPrintNodePrinterSettings."Paper Size");
        if _MobPrintNodePrinterSettings."Paper Tray" <> '' then
            Options.Add('bin', _MobPrintNodePrinterSettings."Paper Tray");
        case _MobPrintNodePrinterSettings."Paper Rotation" of
            _MobPrintNodePrinterSettings."Paper Rotation"::"0 Degrees":
                Options.Add('rotate', 0);
            _MobPrintNodePrinterSettings."Paper Rotation"::"90 Degrees":
                Options.Add('rotate', 90);
            _MobPrintNodePrinterSettings."Paper Rotation"::"180 Degrees":
                Options.Add('rotate', 180);
            _MobPrintNodePrinterSettings."Paper Rotation"::"270 Degrees":
                Options.Add('rotate', 270);
        end;
        Payload.Add('options', Options);

        Payload.WriteTo(ReturnRequest);
    end;

    //
    // -------------------------------- HTTP  --------------------------------
    //

    /// <summary>
    /// Perform "No Operation" to check credentials. https://www.printnode.com/en/docs/api/curl
    /// </summary>
    internal procedure CheckConnection()
    var
        RestParameter: Record "MOB Print REST Parameter";
    begin
        if TrySendToPrintNode('', '/noop', RestParameter) then
            Message(ConnectionOkMsg);
    end;

    internal procedure TrySendToPrintNode(_Request: Text; _Url: Text; var _RestParameter: Record "MOB Print REST Parameter" temporary) ReturnSuccess: Boolean
    var
        MobHttpHelper: Codeunit "MOB HTTP Helper";
        RequestContent: HttpContent;
        ContentHeaders: HttpHeaders;
    begin
        AddConnectionDetails(_Url, _RestParameter);

        // POST
        if _Request <> '' then begin
            _RestParameter.RestMethod := _RestParameter.RestMethod::post;
            RequestContent.WriteFrom(_Request);

            RequestContent.GetHeaders(ContentHeaders);
            ContentHeaders.Remove('Content-Type');
            ContentHeaders.Add('Content-Type', 'application/Json');

            _RestParameter.SetRequestContent(RequestContent);
        end else
            // GET
            _RestParameter.RestMethod := _RestParameter.RestMethod::get;

        if not MobHttpHelper.TrySend(_RestParameter) then

            // Throw Error
            case _RestParameter."Result HttpStatusCode" of
                -1: // HttpClient.Send() failed
                    Error(FailedErr, _RestParameter."Result HttpStatusCode", _RestParameter.URL, _RestParameter."Result ReasonPhrase", GetLastErrorText());
                401: // Unauthorized
                    Error(UnauthorizedErr, _RestParameter."Result HttpStatusCode");
                else // Failed
                    Error(FailedErr, _RestParameter."Result HttpStatusCode", _RestParameter.URL, _RestParameter.GetResponseContentAsText(0), GetLastErrorText());
            end;

        ReturnSuccess := true;
    end;

    local procedure AddConnectionDetails(_Url: Text; var _RestParameter: Record "MOB Print REST Parameter" temporary)
    var
        MobPrintNodeSetup: Record "MOB PrintNode Setup";
    begin
        MobPrintNodeSetup.Get();
        _RestParameter.URL := 'https://api.printnode.com' + _Url;

        _RestParameter.UserName := MobPrintNodeSetup.GetPrintNodeAPIKey(); // Only userName is required
        MobToolbox.Text2UrlEncodedText(_RestParameter.UserName);
    end;

    /* #endif */
}
