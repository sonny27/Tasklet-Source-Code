codeunit 81420 "MOB Print"
{
    Access = Public;

    TableNo = "MOB Print REST Parameter";
    // Printing from mobile

    var
        TempRequestElements: Record "MOB NS Request Element" temporary;
        MobPrintSetup: Record "MOB Print Setup";
        MobPrintLog: Record "MOB Print Log";
        MobGs1Helper: Codeunit "MOB GS1 Helper";
        MobToolbox: Codeunit "MOB Toolbox";
        MobTypeHelper: Codeunit "MOB Type Helper";
        MobXmlMgt: Codeunit "MOB XML Management";
        MobItemReferenceMgt: Codeunit "MOB Item Reference Mgt.";
        MobLanguage: Codeunit "MOB WMS Language";
        MobInterForm: Codeunit "MOB Print InterForm";
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
        MobSessionData: Codeunit "MOB SessionData";
        FormatAddress: Codeunit "Format Address";
        SourceRecVariant: Variant;
        FailedLabelXmlTxt: Label 'Failed to create label data as XML';
        ReplaceSetupTxt: Label 'A setup already exists. Do you want to continue?';
        CopyOfTxt: Label 'Copy of ';
        DesignerNotAvailForCommonErr: Label 'Designer is not available for the "%1" tenant. Please contact Tasklet support to get your own individual tenant.', Comment = '%1 is tenant name.';
        IllegalPrinterLabelSetupTxt: Label 'You do not have Printer and Label-Template enabled and assigned';
        SeePrintLogForDetailsErr: Label 'See "Mobile Print Log" and "Cloud Response", for details.';
        CloudPrintPrefixLbl: Label 'Cloud Print: %1', Locked = true;
    //
    // -------------------------------- OnRun --------------------------------
    //
    trigger OnRun()
    begin
        // OnRun parameters are set by caller, using Setters and Codeunit Record
        CreateMobilePrint(SourceRecVariant, TempRequestElements, Rec);
    end;

    procedure SetSourceRecRef(_SourceRecVariant: Variant)
    begin
        SourceRecVariant := _SourceRecVariant;
    end;

    // Used from documentation "Case - Print Label on unplanned function Posting"
    procedure SetRequestElements(var _RequestElements: Record "MOB NS Request Element")
    begin
        TempRequestElements.Copy(_RequestElements, true);
    end;

    procedure SetRequestElementsFromOrderValues(var _TempOrderValues: Record "MOB Common Element")
    begin
        TempRequestElements.InitFromCommonElement(_TempOrderValues);
    end;

    //
    // -------------------------------- Print --------------------------------
    //

    /// <summary>
    /// Handle print on Planned function posting
    /// </summary>
    procedure PrintOnPlannedPosting(var _RecRef: RecordRef; var _TempOrderValues: Record "MOB Common Element"; var _ResultMessage: Text)
    var
        MobPrinter: Record "MOB Printer";
        TempPrintParameter: Record "MOB Print REST Parameter" temporary;
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesHeader: Record "Sales Header";
        MobPrint: Codeunit "MOB Print";
        MobPrintBuffer: Codeunit "MOB Print Buffer";
        SourceRecRef: RecordRef;
        PrintCommand: Text;
    begin
        // -- Prepare to Print
        if not MobPrintSetup.Get() then
            exit;

        if not MobPrintSetup.Enabled then
            exit;

        if _TempOrderValues.GetValue('LabelTemplate') = '' then
            exit;

        case true of
            // Pick directly on Sales Order also posts Sales Shipment
            (MobPrintSetup."Print on Sales Order Pick" <> '') and (_RecRef.Number() = Database::"Sales Header"):
                begin
                    _RecRef.SetTable(SalesHeader);
                    if (SalesHeader."Last Shipping No." = '') or (not SalesShipmentHeader.Get(SalesHeader."Last Shipping No.")) then begin
                        _ResultMessage += ' ' + MobLanguage.GetMessage('PRINT_FAILED') + ': ' + StrSubstNo(MobLanguage.GetMessage('SHIPMENT_MISSING'), SalesHeader."Last Shipping No.");
                        exit;
                    end;

                    SourceRecRef.GetTable(SalesShipmentHeader);
                end;

            // Post Warehouse Shipment
            (MobPrintSetup."Print on Whse. Shipment Post" <> '') and (_RecRef.Number() = Database::"Warehouse Shipment Line"):
                SourceRecRef := _RecRef;
            else
                exit; // Source not relevant for printing
        end;

        // -- Print
        // Init printer parameters
        TempPrintParameter.Printer := _TempOrderValues.GetValue('Printer');
        TempPrintParameter."Label-Template Name" := _TempOrderValues.GetValue('LabelTemplate');

        TempPrintParameter."Message ID" := MobToolbox.ConvertGUIDtoCode100(MobSessionData.GetPostingMessageId());
        TempPrintParameter."Device ID" := MobSessionData.GetDeviceID();

        // Set parameters
        MobPrint.SetSourceRecRef(SourceRecRef);
        MobPrint.SetRequestElementsFromOrderValues(_TempOrderValues);

        // Perform cloud print
        if MobPrint.Run(TempPrintParameter) then begin

            // Command is returned from cloud
            TempPrintParameter.GetResponseContentAsBase64Text(PrintCommand);

            // Convert the printer selected to an Address
            MobPrint.GetPrinterFromName(MobPrinter, TempPrintParameter.Printer);

            // Save response to be sent in the next Mobile response
            MobPrintBuffer.Add(MobPrinter.Address, PrintCommand);

        end else
            // If failed, append Error to ResultMessage 
            _ResultMessage += ' ' + MobLanguage.GetMessage('PRINT_FAILED') + ': ' + GetLastErrorText();
    end;

    /// <summary>
    /// Header Steps for print on posting
    /// </summary>
    procedure GetStepsForPrintOnPosting(_RecRef: RecordRef; var _Steps: Record "MOB Steps Element" temporary; var _AdditionalValues: Record "MOB Common Element")
    var
        MobLabelTemplate: Record "MOB Label-Template";
    begin
        if not MobPrintSetup.Get() then
            exit;

        if not MobPrintSetup.Enabled then
            exit;

        case true of
            // Pick posts Sales Shipment
            (MobPrintSetup."Print on Sales Order Pick" <> '') and (_RecRef.Number() = Database::"Sales Header"):
                MobLabelTemplate.Get(MobPrintSetup."Print on Sales Order Pick");

            // Post Warehouse Shipment
            (MobPrintSetup."Print on Whse. Shipment Post" <> '') and (_RecRef.Number() = Database::"Warehouse Shipment Header"):
                MobLabelTemplate.Get(MobPrintSetup."Print on Whse. Shipment Post");
            else
                exit; // Source not relevant for printing
        end;

        // Create steps
        GetStepsForTemplate(MobLabelTemplate, _RecRef, _Steps);

        // Carry info through to Posting as "AdditionalValue"
        _AdditionalValues.Create();
        _AdditionalValues.SetValue('LabelTemplate', MobLabelTemplate.Name);
        _AdditionalValues.Save();
    end;

    /// <summary>
    /// Handle a user printing a label
    /// </summary>
    procedure CreateMobilePrint(_SourceRecVariant: Variant; var _RequestValues: Record "MOB NS Request Element"; var _PrintParameter: Record "MOB Print REST Parameter")
    var
        TempDataset: Record "MOB Common Element" temporary;
        LabelTemplate: Record "MOB Label-Template";
    begin
        ErrorIfNoSetup();
        // Determine which Template to run 
        LabelTemplate.Get(_PrintParameter."Label-Template Name");

        LogBegin(_SourceRecVariant, _PrintParameter);

        // Prepare data in the form of dataset records
        PopulateDatasets(_PrintParameter, LabelTemplate, _SourceRecVariant, TempDataset, _RequestValues);

        LogDataSet(TempDataset);

        // Send request to Cloud
        CreateSendRequest(_PrintParameter, LabelTemplate, TempDataset);
    end;

    /// <summary>
    /// Generate datasets for each label
    /// </summary>
    local procedure PopulateDatasets(var _PrintParameter: Record "MOB Print REST Parameter"; var _LabelTemplate: Record "MOB Label-Template"; _SourceRecVariant: Variant; var _Dataset: Record "MOB Common Element"; var _RequestValues: Record "MOB NS Request Element")
    var
        i: Integer;
        NoOfLabels: Integer;
        SavedLanguage: Integer;
    begin
        // Get step value
        NoOfLabels := _RequestValues.GetValueAsInteger('NoOfLabels');

        // Always create one label
        if NoOfLabels = 0 then
            NoOfLabels := 1;

        // Change language
        SavedLanguage := GlobalLanguage();
        GlobalLanguage(GetPrintLanguageId());

        // Generate Dataset per label, generally the same, with difference in numbering
        for i := 1 to NoOfLabels do
            PopulateDataset(_PrintParameter, _LabelTemplate, _SourceRecVariant, _Dataset, _RequestValues);

        // Reset language
        GlobalLanguage(SavedLanguage);
    end;

    /// <summary>
    /// Transfer all possible data to dataset for use in printing
    /// Mobile request, ReferenceID record etc.
    /// TryFunction allows GlobalLanguage being rolled back - which is not done by CodeUnit.Run()
    /// </summary>
    [TryFunction]
    local procedure PopulateDataset(var _PrintParameter: Record "MOB Print REST Parameter"; var _LabelTemplate: Record "MOB Label-Template"; _SourceRecVariant: Variant; var _Dataset: Record "MOB Common Element"; var _RequestValues: Record "MOB NS Request Element")
    var
        SourceRecRef: RecordRef;
    begin

        MobToolbox.Variant2RecRef(_SourceRecVariant, SourceRecRef);
        _Dataset.Create();

        // Transfer Context/Source record to dataset
        TransferSourceRecord2Dataset(SourceRecRef, _RequestValues, _Dataset);

        // Transfer Request Values (request tags has preference over context tags)
        // Includes values collected from Steps
        TransferRequestValues2Dataset(_Dataset, _RequestValues);

        // Transfer value specific to the Template Handler
        TransferTemplateHandlerValues2Dataset(_LabelTemplate, _Dataset);

        // Transform dataset to have output values in node names as expected by InterForm
        TransformStandardValues(_Dataset);

        // Add commonly used labels
        AddStandardLabels(_Dataset);

        // Transfer Template Info (DPI, size etc.)
        TransferTemplateInfo(_PrintParameter, _LabelTemplate, _Dataset);

        // - Event 
        OnPrintLabel_OnAfterPopulateDataset(_LabelTemplate.Name, _RequestValues, SourceRecRef, _Dataset);
    end;

    /// <summary>
    /// Send template request to Interform
    /// Create XML based on context and collected values.
    /// </summary>
    local procedure CreateSendRequest(var _PrintParameter: Record "MOB Print REST Parameter"; var _LabelTemplate: Record "MOB Label-Template"; var _Dataset: Record "MOB Common Element")
    var
        RequestAsXmlDoc: XmlDocument;
    begin
        // Populate request with fields from dataset buffer
        RequestAsXmlDoc := Dataset2TemplateRequest(_Dataset, _LabelTemplate);

        LogCloudRequest(RequestAsXmlDoc);

        Commit(); // Commit log before sending request

        // Send to Print service
        SendRequest(RequestAsXmlDoc, _PrintParameter);

        LogCloudResponse(_PrintParameter);

        Commit(); // Commit log before call Error() to display message to user

        CheckResponseForError(_PrintParameter);
    end;

    local procedure CheckConnectionSetup()
    begin
        ErrorIfNoSetup();
        MobPrintSetup.TestField("Connection Username");
        MobPrintSetup.TestField("Connection Password");
        MobPrintSetup.TestField("Connection URL");
    end;

    local procedure CheckConnectionAndPrintSetup()
    begin
        CheckConnectionSetup();

        if (MobPrintSetup.GetNoOfEnabledPrinters() = 0) or
                (MobPrintSetup.GetNoOfEnabledLabelTemplates() = 0) then
            Error(IllegalPrinterLabelSetupTxt);
    end;

    local procedure SendRequest(_RequestAsXmlDoc: XmlDocument; var _PrintParameter: Record "MOB Print REST Parameter")
    var
        RequestAsText: Text;
    begin
        CheckConnectionAndPrintSetup();

        // XML to Text
        MobXmlMgt.DocSaveToText(_RequestAsXmlDoc, RequestAsText);

        // Encode Text
        MobToolbox.Text2UrlEncodedText(RequestAsText);

        // Send to Interform
        MobInterForm.SendPrint(RequestAsText, _PrintParameter);
    end;

    /// <summary>
    /// Check response for error 
    /// Display error to user
    /// </summary>    
    local procedure CheckResponseForError(var _PrintParameter: Record "MOB Print REST Parameter")
    var
        ErrorMessage: Text;
    begin
        ErrorMessage := MobInterForm.CheckResponseForError(_PrintParameter);
        if ErrorMessage <> '' then
            Error('%1: %2%3%4',
                MobLanguage.GetMessage('PRINT_FAILED'), ErrorMessage, MobToolbox.CRLFSeparator(), SeePrintLogForDetailsErr);
    end;

    //
    // -------------------------------- Templates --------------------------------
    //

    /// <summary>
    /// Transfer Template Info (DPI, size etc.)
    /// </summary>
    local procedure TransferTemplateInfo(_PrintParameter: Record "MOB Print REST Parameter"; _LabelTemplate: Record "MOB Label-Template"; var _Dataset: Record "MOB Common Element")
    var
        MobPrinter: Record "MOB Printer";
    begin
        GetPrinterFromName(MobPrinter, _PrintParameter.Printer);
        _Dataset.SetValue('PrinterName', MobPrinter.Name);
        _Dataset.SetValue('dpi', 'DPI' + Format(MobPrinter.DPI));
        _Dataset.SetValue('DesignID', _PrintParameter."Label-Template Name");
        _Dataset.SetValue('TemplatePath', _LabelTemplate."URL Mapping");
        _Dataset.SetValue('PrinterAddress', MobPrinter.Address);
        _Dataset.SetValue('ServiceUser', MobPrintSetup."Connection Username");

        // No of labels = print copies
        if _Dataset.GetValue('NoOfCopies', false) <> '' then
            _Dataset.SetValue('PrintCopies', _Dataset.GetValue('NoOfCopies', false))
        else
            _Dataset.SetValue('PrintCopies', '1');
    end;

    /// <summary>
    /// Return a record of relevant templates from a context (Location, Printer etc.)
    /// </summary>
    procedure GetRelevantTemplates(var _ReturnFilteredRecord: Record "MOB Label-Template" temporary; _LocationFilter: Code[10])
    var
        MobLabelTemplate: Record "MOB Label-Template";
        MobPrinterLabelTemplate: Record "MOB Printer Label-Template";
    begin
        MobLabelTemplate.SetRange(Enabled, true);
        if MobLabelTemplate.FindSet() then
            repeat
                MobPrinterLabelTemplate.SetRange("Label-Template Name", MobLabelTemplate.Name);
                // Respect Printer assignments
                if MobPrinterLabelTemplate.FindSet() then
                    repeat
                        if IsPrinterAllowedOnLocation(MobPrinterLabelTemplate."Printer Name", _LocationFilter) then begin
                            _ReturnFilteredRecord.Copy(MobLabelTemplate);
                            if _ReturnFilteredRecord.Insert(false) then; // Avoid error if already exists
                        end;
                    until MobPrinterLabelTemplate.Next() = 0
                else begin

                    // Templates without assignments are available by default, but requires that enabled printer(s) exists  
                    _ReturnFilteredRecord.Copy(MobLabelTemplate);
                    if _ReturnFilteredRecord.Insert(false) then; // Avoid error if already exists
                end;
            until MobLabelTemplate.Next() = 0;
    end;

    /// <summary>
    /// Create a new template as a copy of this template
    /// </summary>
    internal procedure CopyTemplate(var _LabelTemplateToCopyFrom: Record "MOB Label-Template")
    var
        NewLabelTemplate: Record "MOB Label-Template";
        MobCopyLabelTemplate: Page "MOB Copy Label-Template";
        NewName: Text;
        NewPath: Text;
    begin
        ErrorIfTenantIsCommon();

        _LabelTemplateToCopyFrom.TestField("URL Mapping");

        // Ask for new name   
        MobCopyLabelTemplate.SetTemplateName(CopyOfTxt + _LabelTemplateToCopyFrom.Name);
        if MobCopyLabelTemplate.RunModal() = Action::OK then
            NewName := MobCopyLabelTemplate.GetTemplateName()
        else
            exit;

        if NewLabelTemplate.Get(NewName) then
            NewLabelTemplate.FieldError(Name); // Error if already exists

        // Request cloud service to copy template and return path 
        NewPath := MobInterForm.CopyTemplate(_LabelTemplateToCopyFrom."URL Mapping", NewName);

        // Insert new template record
        if NewPath <> '' then
            InsertTemplate(NewLabelTemplate, NewName, NewName, NewPath, _LabelTemplateToCopyFrom."Template Handler");
    end;

    internal procedure InsertTemplate(var _LabelTemplate: Record "MOB Label-Template"; _Enabled: Boolean; _Name: Text[50]; _DisplayName: Text[50]; _Template: Text[250]; _Handler: Enum "MOB Label-Template Handler")
    begin
        _LabelTemplate.Init();
        _LabelTemplate.Enabled := _Enabled;
        _LabelTemplate."URL Mapping" := _Template;
        _LabelTemplate.Name := _Name;
        _LabelTemplate."Display Name" := _DisplayName;
        _LabelTemplate."Template Handler" := _Handler;
        if _LabelTemplate.Insert(true) then;   // Allow template to already exist
    end;

    procedure InsertTemplate(var _LabelTemplate: Record "MOB Label-Template"; _Name: Text[50]; _DisplayName: Text[50]; _Template: Text[250]; _Handler: Enum "MOB Label-Template Handler")
    begin
        InsertTemplate(_LabelTemplate, true, _Name, _DisplayName, _Template, _Handler);
    end;

    procedure InsertTemplateDisabled(var _LabelTemplate: Record "MOB Label-Template"; _Name: Text[50]; _DisplayName: Text[50]; _Template: Text[250]; _Handler: Enum "MOB Label-Template Handler")
    begin
        InsertTemplate(_LabelTemplate, false, _Name, _DisplayName, _Template, _Handler);
    end;

    internal procedure ReplaceLabelTemplate(_ObsoleteName: Text[50]; _Name: Text[50]; _DisplayName: Text[50]; _Template: Text[250]; _Handler: Enum "MOB Label-Template Handler")
    var
        MobLabelTemplate: Record "MOB Label-Template";
        MobPrint: Codeunit "MOB Print";
    begin
        if MobLabelTemplate.IsEmpty() then
            exit;

        // Disable the obsolete template if it exists
        if MobLabelTemplate.Get(_ObsoleteName) and MobLabelTemplate.Enabled then begin
            MobLabelTemplate.Validate(Enabled, false);
            MobLabelTemplate.Modify(true);
        end;

        // Enable or insert the new templete
        if MobLabelTemplate.Get(_Name) then begin
            if not MobLabelTemplate.Enabled then begin
                MobLabelTemplate.Validate(Enabled, true);
                MobLabelTemplate.Modify(true);
            end;
        end else
            MobPrint.InsertTemplate(MobLabelTemplate, _Name, _DisplayName, _Template, _Handler);
    end;

    /// <summary>
    /// Assign all existing templates to a printer
    /// </summary>
    procedure AssignAllTemplates(_PrinterName: Text[50])
    var
        MobPrinterLabelTemplate: Record "MOB Printer Label-Template";
        MobLabelTemplate: Record "MOB Label-Template";
    begin
        if MobLabelTemplate.FindSet() then
            repeat
                MobPrinterLabelTemplate."Printer Name" := _PrinterName;
                MobPrinterLabelTemplate."Label-Template Name" := MobLabelTemplate.Name;
                if not MobPrinterLabelTemplate.Insert() then; // Avoid error if already exists
            until MobLabelTemplate.Next() = 0;
    end;

    //
    // -------------------------------- Transfer To dataset --------------------------------
    //

    /// <summary>
    /// Transfer context tabel to "common" so it can be mapped to label-templates
    /// and identify required Steps
    /// </summary>
    local procedure TransferSourceRecord2Dataset(_SourceRecRef: RecordRef; var _RequestValues: Record "MOB NS Request Element"; var _Dataset: Record "MOB Common Element")
    var
        WhseShipmentLine: Record "Warehouse Shipment Line";
    begin

        case _SourceRecRef.Number() of

            5717, // Item Reference -- intentionally not using Database::Item Reference to prevent error if table is not in database
            5777: // Item Cross Reference -- intentionally not using Database::Item Cross Reference to prevent error if table is not in database
                TransferItemCrossRef2Dataset(_SourceRecRef, _Dataset);

            Database::"Bin Content":
                TransferBinContent2Dataset(_SourceRecRef, _RequestValues, _Dataset);

            Database::Item:
                TransferItem2Dataset(_SourceRecRef, _Dataset);

            Database::"Warehouse Receipt Line":
                TransferWhseReceiptLine2Dataset(_SourceRecRef, _Dataset);

            Database::"Warehouse Shipment Line":
                begin
                    TransferWhseShipmentLine2Dataset(_SourceRecRef, _Dataset);

                    _SourceRecRef.SetTable(WhseShipmentLine); // Transfer Whse Shipment's Sales Shipments to Dataset as individual labels
                    TransferShipmentsByWhseShipmentLine2Dataset(WhseShipmentLine, _Dataset);
                end;

            Database::"Warehouse Activity Line":
                TransferWhseActivityLine2Dataset(_SourceRecRef, _Dataset);

            Database::"Sales Line":
                TransferSalesLine2Dataset(_SourceRecRef, _Dataset);

            Database::"Purchase Line":
                TransferPurchaseLine2Dataset(_SourceRecRef, _Dataset);

            Database::"Sales Shipment Header":
                TransferSalesShipmentHeaderAndLines2Dataset(_SourceRecRef, _Dataset);

            Database::"Transfer Line":
                TransferTransferLine2Dataset(_SourceRecRef, _Dataset);

            Database::"Warehouse Journal Line":
                TransferWhseJournalLine2Dataset(_SourceRecRef, _Dataset);

            Database::"Item Journal Line":
                TransferItemJournalLine2Dataset(_SourceRecRef, _Dataset);

            Database::"Prod. Order Line":
                TransferProdOrderLine2Dataset(_SourceRecRef, _Dataset);

            Database::"Assembly Header":
                TransferAssemblyHeader2Dataset(_SourceRecRef, _Dataset);

            Database::"Assembly Line":
                TransferAssemblyLine2Dataset(_SourceRecRef, _Dataset);

        end;
    end;

    /// <summary>
    /// Transfer collected (requestelements) steps to dataset 
    /// </summary>
    local procedure TransferRequestValues2Dataset(var _Dataset: Record "MOB Common Element"; var _RequestValues: Record "MOB NS Request Element")
    var
        RecRef: RecordRef;
    begin

        // Transfer all values from the Unplanned Reqeust
        // - Including steps
        // - Including line context 

        if _RequestValues.FindSet() then
            repeat
                if not (_RequestValues.Name in [MobXmlMgt.REGISTRATIONCOLLECTOR(), 'xmlns']) then // Exclude XML elements from Mobile context like Schema or Steps that is not relevant or allowed in Print service request
                    _Dataset.SetValue(_RequestValues.Name, _RequestValues."Value");
            until _RequestValues.Next() = 0;

        //  Transfer Shipment info based on ShipmentNo. If collected.
        if GetWarehouseShipmentLine_As_RecRef(RecRef, _RequestValues.GetValue('ShipmentNo', false), 0) then
            TransferWhseShipmentLine2Dataset(RecRef, _Dataset);
    end;

    /// <summary>
    /// Transfer values specific to this template handler
    /// </summary>
    local procedure TransferTemplateHandlerValues2Dataset(var _LabelTemplate: Record "MOB Label-Template"; var _Dataset: Record "MOB Common Element")
    begin
        // Set/respect No. Series
        if _LabelTemplate."Number Series" <> '' then
            if _Dataset.GetValue('NoSeriesValue') = '' then // Respect if value is already set in Mobile request 
                _Dataset.SetValue('NoSeriesValue', GetNextNo(_LabelTemplate));
    end;

    /// <summary>
    /// Transfer Bin Content fields to Dataset
    /// </summary>
    local procedure TransferBinContent2Dataset(_SourceRecRef: RecordRef; var _RequestValues: Record "MOB NS Request Element"; var _Dataset: Record "MOB Common Element")
    var
        MobTrackingSetup: Record "MOB Tracking Setup";
        BinContent: Record "Bin Content";
        Item: Record Item;
    begin
        _SourceRecRef.SetTable(BinContent);

        // Transfer Item info
        if Item.Get(BinContent."Item No.") then
            TransferItem2Dataset(Item, _Dataset);

        // "Bin Contents" lookup has many values available for reuse
        if _SourceRecRef.Number() = Database::"Bin Content" then begin

            MobTrackingSetup.CopyTrackingFromRequestContextValues(_RequestValues);
            CopyTrackingToDataset(MobTrackingSetup, _Dataset);

            _Dataset.SetValue('Variant', _RequestValues.GetContextValue('Variant'));
            _Dataset.SetValue('QuantityPerLabel', _RequestValues.GetContextValue('Quantity'));
        end;
    end;

    /// <summary>
    /// Transfer Item fields to Dataset
    /// </summary>
    local procedure TransferItem2Dataset(_SourceRecRef: RecordRef; var _Dataset: Record "MOB Common Element")
    var
        Item: Record Item;
    begin
        // Get source Rec
        _SourceRecRef.SetTable(Item);
        Item.SetView(_SourceRecRef.GetView());

        TransferItem2Dataset(Item, _Dataset);
    end;

    /// <summary>
    /// Transfer Item fields to Dataset
    /// </summary>
    local procedure TransferItem2Dataset(_Item: Record Item; var _Dataset: Record "MOB Common Element")
    begin
        _Dataset.SetValue('ItemNumber', _Item."No.");
        _Dataset.SetValue('ItemNumber_Label', MobLanguage.GetMessage('ITEM_NO'));

        _Dataset.SetValue('Description', _Item.Description);
        _Dataset.SetValue('Description2', _Item."Description 2");
        _Dataset.SetValue('Description_Label', MobLanguage.GetMessage('DESCRIPTION'));

        _Dataset.SetValue('ItemType', MobToolbox.AsInteger(_Item.Type));
        _Dataset.SetValue('ItemType_Label', MobLanguage.GetMessage('TYPE'));
    end;

    /// <summary>
    /// Transfer Item Cross Reference / Item Reference fields to Dataset
    /// Using FieldRef to support all BC versions with and without Item Reference feature enabled
    /// </summary>
    local procedure TransferItemCrossRef2Dataset(_SourceRecRef: RecordRef; var _Dataset: Record "MOB Common Element")
    var
        ItemRecRef: RecordRef;
        ItemNoFieldRef: FieldRef;
        CrossReferenceNoFieldRef: FieldRef;
        UnitOfMeasureFieldRef: FieldRef;
        VariantCodeFieldRef: FieldRef;
        ItemNo: Code[20];
    begin
        ItemNoFieldRef := _SourceRecRef.Field(1);           // Item No.
        CrossReferenceNoFieldRef := _SourceRecRef.Field(6); // Cross-Reference No. / Reference No.
        UnitOfMeasureFieldRef := _SourceRecRef.Field(3);    // Unit Of Measure Code
        VariantCodeFieldRef := _SourceRecRef.Field(2);      // Variant Code

        // Transfer values to dataset
        _Dataset.SetValue('ItemBarcode', CrossReferenceNoFieldRef.Value());
        _Dataset.SetValue('ItemBarcodeUoM', UnitOfMeasureFieldRef.Value()); // ItemBarcodeUoM = Unit is retrieved from Item Reference/Itembarcode
        _Dataset.SetValue('Variant', VariantCodeFieldRef.Value());

        // Transfer full Item info
        Evaluate(ItemNo, ItemNoFieldRef.Value());
        if GetItem_As_RecRef(ItemRecRef, ItemNo) then
            TransferItem2Dataset(ItemRecRef, _Dataset);
    end;

    local procedure ReceiveLine2Dataset(_Line: Record "Warehouse Receipt Line"; var _Dataset: Record "MOB Common Element")
    begin
        _Dataset.SetValue('Line-' + 'ItemNumber', _Line."Item No.");
        _Dataset.SetValue('Line-' + 'ItemName', _Line.Description + ' ' + _Line."Description 2");
        _Dataset.SetValue('Line-' + 'Qty', Format(_Line.Quantity));
        _Dataset.SetValue('Line-' + 'Unit', _Line."Unit of Measure Code");
        _Dataset.SetValue('Line-' + 'Variant', _Line."Variant Code");
    end;

    local procedure ReceiveHeader2Dataset(_Header: Record "Warehouse Receipt Header"; var _Dataset: Record "MOB Common Element")
    begin
        _Dataset.SetValue('Header-No', _Header."No.");
        _Dataset.SetValue('Header-VendorShipmentNo', _Header."Vendor Shipment No.");
    end;

    local procedure TransferLine2Dataset(_Line: Record "Transfer Line"; var _Dataset: Record "MOB Common Element")
    begin
        _Dataset.SetValue('Line-' + 'ItemNumber', _Line."Item No.");
        _Dataset.SetValue('Line-' + 'ItemName', _Line.Description + ' ' + _Line."Description 2");
        _Dataset.SetValue('Line-' + 'Qty', Format(_Line.Quantity));
        _Dataset.SetValue('Line-' + 'Unit', _Line."Unit of Measure Code");
        _Dataset.SetValue('Line-' + 'Variant', _Line."Variant Code");
    end;

    local procedure TransferHeader2Dataset(_Header: Record "Transfer Header"; var _Dataset: Record "MOB Common Element")
    begin
        _Dataset.SetValue('Header-No', _Header."No.");
    end;

    local procedure WarehouseActivityLine2Dataset(_Line: Record "Warehouse Activity Line"; var _Dataset: Record "MOB Common Element")
    var
        MobTrackingSetup: Record "MOB Tracking Setup";
    begin
        _Dataset.SetValue('Line-' + 'ItemNumber', _Line."Item No.");
        _Dataset.SetValue('Line-' + 'ItemName', _Line.Description + ' ' + _Line."Description 2");
        _Dataset.SetValue('Line-' + 'Qty', Format(_Line.Quantity));
        _Dataset.SetValue('Line-' + 'Unit', _Line."Unit of Measure Code");
        _Dataset.SetValue('Line-' + 'Variant', _Line."Variant Code");

        MobTrackingSetup.CopyTrackingFromWhseActivityLine(_Line);
        CopyTrackingToDataset(MobTrackingSetup, 'Line-', _Dataset);
    end;

    local procedure WarehouseJournalLine2Dataset(_Line: Record "Warehouse Journal Line"; var _Dataset: Record "MOB Common Element")
    var
        MobTrackingSetup: Record "MOB Tracking Setup";
    begin
        _Dataset.SetValue('Line-' + 'ItemNumber', _Line."Item No.");
        _Dataset.SetValue('Line-' + 'ItemName', _Line.Description);
        _Dataset.SetValue('Line-' + 'Qty', Format(_Line.Quantity));
        _Dataset.SetValue('Line-' + 'Unit', _Line."Unit of Measure Code");
        _Dataset.SetValue('Line-' + 'Variant', _Line."Variant Code");

        MobTrackingSetup.CopyTrackingFromWhseJnlLine(_Line);
        CopyTrackingToDataset(MobTrackingSetup, 'Line-', _Dataset);
    end;

    local procedure ItemJournalLine2Dataset(_Line: Record "Item Journal Line"; var _Dataset: Record "MOB Common Element")
    var
        MobTrackingSetup: Record "MOB Tracking Setup";
    begin
        _Dataset.SetValue('Line-' + 'ItemNumber', _Line."Item No.");
        _Dataset.SetValue('Line-' + 'ItemName', _Line.Description);
        _Dataset.SetValue('Line-' + 'Qty', Format(_Line.Quantity));
        _Dataset.SetValue('Line-' + 'Unit', _Line."Unit of Measure Code");
        _Dataset.SetValue('Line-' + 'Variant', _Line."Variant Code");

        MobTrackingSetup.CopyTrackingFromItemJnlLine(_Line);
        CopyTrackingToDataset(MobTrackingSetup, 'Line-', _Dataset);
    end;

    local procedure ProdOrderLine2Dataset(_Line: Record "Prod. Order Line"; var _Dataset: Record "MOB Common Element")
    begin
        _Dataset.SetValue('Line-' + 'ItemNumber', _Line."Item No.");
        _Dataset.SetValue('Line-' + 'ItemName', _Line.Description);
        _Dataset.SetValue('Line-' + 'Qty', Format(_Line.Quantity));
        _Dataset.SetValue('Line-' + 'Unit', _Line."Unit of Measure Code");
        _Dataset.SetValue('Line-' + 'Variant', _Line."Variant Code");
    end;

    local procedure AssemblyHeader2Dataset(_Header: Record "Assembly Header"; var _Dataset: Record "MOB Common Element")
    begin
        _Dataset.SetValue('Line-' + 'ItemNumber', _Header."Item No.");
        _Dataset.SetValue('Line-' + 'ItemName', _Header.Description);
        _Dataset.SetValue('Line-' + 'Qty', Format(_Header.Quantity));
        _Dataset.SetValue('Line-' + 'Unit', _Header."Unit of Measure Code");
        _Dataset.SetValue('Line-' + 'Variant', _Header."Variant Code");
    end;

    local procedure AssemblyLine2Dataset(_Line: Record "Assembly Line"; var _Dataset: Record "MOB Common Element")
    begin
        _Dataset.SetValue('Line-' + 'ItemNumber', _Line."No.");
        _Dataset.SetValue('Line-' + 'ItemName', _Line.Description);
        _Dataset.SetValue('Line-' + 'Qty', Format(_Line.Quantity));
        _Dataset.SetValue('Line-' + 'Unit', _Line."Unit of Measure Code");
        _Dataset.SetValue('Line-' + 'Variant', _Line."Variant Code");
    end;

    local procedure SalesLine2Dataset(_Line: Record "Sales Line"; var _Dataset: Record "MOB Common Element")
    begin
        _Dataset.SetValue('Line-' + 'ItemNumber', _Line."No.");
        _Dataset.SetValue('Line-' + 'ItemName', _Line.Description + ' ' + _Line."Description 2");
        _Dataset.SetValue('Line-' + 'Qty', Format(_Line.Quantity));
        _Dataset.SetValue('Line-' + 'Unit', _Line."Unit of Measure Code");
        _Dataset.SetValue('Line-' + 'Variant', _Line."Variant Code");
    end;

    local procedure SalesHeader2Dataset(_Header: Record "Sales Header"; var _Dataset: Record "MOB Common Element")
    begin
        _Dataset.SetValue('Header-No', _Header."No.");
    end;

    local procedure PurchaseLine2Dataset(_Line: Record "Purchase Line"; var _Dataset: Record "MOB Common Element")
    begin
        _Dataset.SetValue('Line-' + 'ItemNumber', _Line."No.");
        _Dataset.SetValue('Line-' + 'ItemName', _Line.Description + ' ' + _Line."Description 2");
        _Dataset.SetValue('Line-' + 'Qty', Format(_Line.Quantity));
        _Dataset.SetValue('Line-' + 'Unit', _Line."Unit of Measure Code");
        _Dataset.SetValue('Line-' + 'Variant', _Line."Variant Code");
    end;

    local procedure PurchaseHeader2Dataset(_Header: Record "Purchase Header"; var _Dataset: Record "MOB Common Element")
    begin
        _Dataset.SetValue('Header-No', _Header."No.");
    end;

    local procedure SalesShipmentHeader2Dataset(_Header: Record "Sales Shipment Header"; var _Dataset: Record "MOB Common Element")
    var
        AddrArray: array[8] of Text;
    begin
        _Dataset.SetValue('Header-No', _Header."No.");

        _Dataset.SetValue('OrderId_Label', MobLanguage.GetMessage('SHIPMT_NO'));
        _Dataset.SetValue('OrderId', _Header."No.");

        FormatAddress.SalesShptShipTo(AddrArray, _Header);
        SetDeliveryAddress(AddrArray, _Dataset);
    end;

    local procedure ReturnShipmentHeader2Dataset(_Header: Record "Return Shipment Header"; var _Dataset: Record "MOB Common Element")
    var
        AddrArray: array[8] of Text;
    begin
        _Dataset.SetValue('Header-No', _Header."No.");

        _Dataset.SetValue('OrderId_Label', MobLanguage.GetMessage('RETURN_SHIPMT_NO'));
        _Dataset.SetValue('OrderId', _Header."No.");

        FormatAddress.PurchShptShipTo(AddrArray, _Header);
        SetDeliveryAddress(AddrArray, _Dataset);
    end;

    local procedure TransferShipmentHeader2Dataset(_Header: Record "Transfer Shipment Header"; var _Dataset: Record "MOB Common Element")
    var
        AddrArray: array[8] of Text;
    begin
        _Dataset.SetValue('Header-No', _Header."No.");

        _Dataset.SetValue('OrderId_Label', MobLanguage.GetMessage('TRANSFER_SHIPMT_NO'));
        _Dataset.SetValue('OrderId', _Header."No.");
        FormatAddress.TransferShptTransferTo(AddrArray, _Header);

        SetDeliveryAddress(AddrArray, _Dataset);
    end;

    local procedure SetDeliveryAddress(_AddrArray: array[8] of Text; var _Dataset: Record "MOB Common Element")
    begin
        _Dataset.SetValue('DeliveryName_Label', MobLanguage.GetMessage('SHIPTOADDRESS'));
        _Dataset.SetValue('DeliveryName', _AddrArray[1]);
        _Dataset.SetValue('DeliveryAddress', _AddrArray[2] + MobToolbox.CRLFSeparator() +
                                                     _AddrArray[3] + MobToolbox.CRLFSeparator() +
                                                     _AddrArray[4] + MobToolbox.CRLFSeparator() +
                                                     _AddrArray[5]);
        _Dataset.SetValue('DeliveryAddress_Label', MobLanguage.GetMessage('SHIPTOADDRESS'));
    end;

    /// <summary>
    /// Transfer a sales shipment line to Dataset
    /// This is used for "OrderList"-template
    /// </summary>
    local procedure SalesShipmentLine2Dataset(_Line: Record "Sales Shipment Line"; var _Dataset: Record "MOB Common Element")
    var
        RecRef: RecordRef;
        Path: Text;
    begin
        Path := 'Lines/OrderLine' + Format(_Line."Line No.");
        _Dataset.SetValue(Path + '/Col1', _Line."No.");
        _Dataset.SetValue(Path + '/Col1_Label', MobLanguage.GetMessage('NO.'));
        _Dataset.SetValue(Path + '/Col2', _Line.Description + ' ' + _Line."Description 2");
        _Dataset.SetValue(Path + '/Col2_Label', MobLanguage.GetMessage('DESCRIPTION'));
        _Dataset.SetValue(Path + '/Col3', Format(_Line.Quantity));
        _Dataset.SetValue(Path + '/Col3_Label', MobLanguage.GetMessage('QUANTITY'));
        _Dataset.SetValue(Path + '/Col4', _Line."Unit of Measure Code");
        _Dataset.SetValue(Path + '/Col4_Label', MobLanguage.GetMessage('UOM_LABEL'));

        RecRef.GetTable(_Line);
        OnPrintLabel_OnAfterPopulateOrderListLine(Path, RecRef, _Dataset);
    end;

    /// <summary>
    /// Transfer a return shipment line to Dataset
    /// This is used for "OrderList"-template
    /// </summary>
    local procedure ReturnShipmentLine2DataSet(_Line: Record "Return Shipment Line"; var _Dataset: Record "MOB Common Element")
    var
        RecRef: RecordRef;
        Path: Text;
    begin
        Path := 'Lines/OrderLine' + Format(_Line."Line No.");
        _Dataset.SetValue(Path + '/Col1', _Line."No.");
        _Dataset.SetValue(Path + '/Col1_Label', MobLanguage.GetMessage('NO.'));
        _Dataset.SetValue(Path + '/Col2', _Line.Description + ' ' + _Line."Description 2");
        _Dataset.SetValue(Path + '/Col2_Label', MobLanguage.GetMessage('DESCRIPTION'));
        _Dataset.SetValue(Path + '/Col3', Format(_Line.Quantity));
        _Dataset.SetValue(Path + '/Col3_Label', MobLanguage.GetMessage('QUANTITY'));
        _Dataset.SetValue(Path + '/Col4', _Line."Unit of Measure Code");
        _Dataset.SetValue(Path + '/Col4_Label', MobLanguage.GetMessage('UOM_LABEL'));

        RecRef.GetTable(_Line);
        OnPrintLabel_OnAfterPopulateOrderListLine(Path, RecRef, _Dataset);
    end;

    /// <summary>
    /// Transfer a Transfer shipment line to Dataset
    /// This is used for "OrderList"-template
    /// </summary>
    local procedure TransferShipmentLine2DataSet(_Line: Record "Transfer Shipment Line"; var _Dataset: Record "MOB Common Element")
    var
        RecRef: RecordRef;
        Path: Text;
    begin
        Path := 'Lines/OrderLine' + Format(_Line."Line No.");
        _Dataset.SetValue(Path + '/Col1', _Line."Item No.");
        _Dataset.SetValue(Path + '/Col1_Label', MobLanguage.GetMessage('NO.'));
        _Dataset.SetValue(Path + '/Col2', _Line.Description + ' ' + _Line."Description 2");
        _Dataset.SetValue(Path + '/Col2_Label', MobLanguage.GetMessage('DESCRIPTION'));
        _Dataset.SetValue(Path + '/Col3', Format(_Line.Quantity));
        _Dataset.SetValue(Path + '/Col3_Label', MobLanguage.GetMessage('QUANTITY'));
        _Dataset.SetValue(Path + '/Col4', _Line."Unit of Measure Code");
        _Dataset.SetValue(Path + '/Col4_Label', MobLanguage.GetMessage('UOM_LABEL'));

        RecRef.GetTable(_Line);
        OnPrintLabel_OnAfterPopulateOrderListLine(Path, RecRef, _Dataset);
    end;

    /// <summary>
    /// Populate tracking in Dataset with lines. Prefix is usually "Line-"
    /// </summary>
    local procedure CopyTrackingToDataset(_MobTrackingSetup: Record "MOB Tracking Setup"; _Prefix: Text; var _Dataset: Record "MOB Common Element")
    begin
        _Dataset.SetValue(_Prefix + 'LotNo', _MobTrackingSetup."Lot No.");
        _Dataset.SetValue(_Prefix + 'SerialNo', _MobTrackingSetup."Serial No.");

        OnPrintLabel_OnPopulateDatasetOnCopyTrackingToDataset(_MobTrackingSetup, _Prefix, _Dataset);
    end;

    /// <summary>
    /// Populate tracking in Dataset
    /// </summary>
    local procedure CopyTrackingToDataset(_MobTrackingSetup: Record "MOB Tracking Setup"; var _Dataset: Record "MOB Common Element")
    begin
        _Dataset.SetValue('LotNumber', _MobTrackingSetup."Lot No.");
        _Dataset.SetValue('SerialNumber', _MobTrackingSetup."Serial No.");

        OnPrintLabel_OnPopulateDatasetOnCopyTrackingToDataset(_MobTrackingSetup, '', _Dataset);
    end;

    /// <summary>
    /// Transfer Context info to Dataset
    /// Order Lines of "Planned functions" contains lots of info.
    /// Some values are transformed to match InterForm label
    /// </summary>
    local procedure TransformStandardValues(var _Dataset: Record "MOB Common Element")
    var
        Item: Record Item;
        MobWhseTrackingSetup: Record "MOB Tracking Setup";
        UoMCode: Text;
        VariantCode: Text;
        CrossRef: Text;
        ScannedItemNumber: Text;
        Ai310n: Text[1];
        Ai310Qty: Text;
        ItemNumber: Code[50];
        DummyVariantCode: Code[10];
        DummyRegisterExpirationDate: Boolean;
        QtyPerLabel: Decimal;
    begin
        // Convert (Scanned)ItemNumber to ItemNumber but discard VariantCode as the variant may be different in RequestValues
        ScannedItemNumber := _Dataset.GetValue('ItemNumber', false);
        ItemNumber := MobItemReferenceMgt.SearchItemReference(ScannedItemNumber, DummyVariantCode);
        Clear(Item);
        if Item.Get(ItemNumber) then
            _Dataset.SetValue('ItemNumber', ItemNumber);

        // Format as label language
        _Dataset.SetValue('ExpirationDateDisplay', MobTypeHelper.FormatDateAsLanguage(_Dataset.GetValueAsDate('ExpirationDate', false), GlobalLanguage())); // NOTE: Global Language has been set to: MobPrintSetup."Language Code"

        _Dataset.SetValue('ExpirationDateGS1', MobTypeHelper.FormatDateAsYYMMDD(_Dataset.GetValueAsDate('ExpirationDate', false)));

        // Transform Variant Code
        VariantCode := _Dataset.GetValue('Variant', false);             // Use collected value
        if VariantCode = '' then
            VariantCode := _Dataset.GetValue('Line-Variant', false);    // Else value from context
        _Dataset.SetValue('Variant', VariantCode);

        // Transform Unit of Measure
        UoMCode := _Dataset.GetValue('ItemBarcodeUoM', false);  // Use value from Item Reference / barcode
        if UoMCode = '' then
            UoMCode := _Dataset.GetValue('UoM', false);  // Else use collected value
        if UoMCode = '' then
            UoMCode := _Dataset.GetValue('UnitOfMeasure', false);   // Else value from Mobile Line
        if UoMCode = '' then
            UoMCode := _Dataset.GetValue('Line-Unit', false);       // Else value from context
        if UoMCode = '' then
            UoMCode := Item."Base Unit of Measure";     // Else Item base unit (may be blank if ItemNumber is unknown)
        _Dataset.SetValue('UnitOfMeasure', UoMCode);

        Clear(MobWhseTrackingSetup);
        MobWhseTrackingSetup.DetermineWhseTrackingRequired(Item."No.", DummyRegisterExpirationDate); // MobWhseTrackingSetup.Tracking: Tracking values are unused in this scope

        // Serial tracked items always represents One piece per label
        if (Item."No." <> '') and MobWhseTrackingSetup."Serial No. Required" then
            QtyPerLabel := 1 // Serial item =  One piece per label
        else
            QtyPerLabel := _Dataset.GetValueAsDecimal('QuantityPerLabel'); // Use collected value

        // Fallback to line context as last resort
        if QtyPerLabel = 0 then
            QtyPerLabel := _Dataset.GetValueAsDecimal('Line-Qty');
        _Dataset.SetValue('QuantityPerLabel', QtyPerLabel);

        // Transform Quantity. Set Ai310n if decimals are used
        if MobGs1Helper.QuantityTransformedToAI310n(QtyPerLabel, Ai310n, Ai310Qty) then begin
            _Dataset.SetValue('QuantityAI', '310' + Ai310n);
            _Dataset.SetValue('QuantityBarcode', Ai310Qty); // Add a Barcode value as AI310n quantity is encoded differently
        end;

        _Dataset.SetValue('Quantity', QtyPerLabel); // If no decimals. Quantity is used  both barcode and display

        // Ai(91) printed at standardlabels must include only one barcode for the item
        // Always override ItemBarcode since tag from planned documents may have include all alternative barcodes and
        // may include barcodes from other UoM's due to values being set from MobWmsToolbox.GetItemCrossRefList()
        if Item."No." <> '' then begin
            CrossRef := MobItemReferenceMgt.GetFirstReferenceNo(Item."No.", VariantCode, UoMCode);
            if CrossRef <> '' then
                _Dataset.SetValue('ItemBarcode', CrossRef)
            else // Fallback to Item No.
                _Dataset.SetValue('ItemBarcode', Item."No.");
        end;
    end;

    /// <summary>
    /// Labels to support commonly used values
    /// </summary>
    local procedure AddStandardLabels(var _Dataset: Record "MOB Common Element")
    begin
        // Add labels for fields in context
        _Dataset.SetValue('ExpirationDateDisplay_Label', MobLanguage.GetMessage('EXP_DATE_LABEL'));
        _Dataset.SetValue('UnitOfMeasure_Label', MobLanguage.GetMessage('UOM_LABEL'));
        _Dataset.SetValue('SerialNumber_Label', MobLanguage.GetMessage('SERIAL_NO_LABEL'));
        _Dataset.SetValue('LotNumber_Label', MobLanguage.GetMessage('LOT_NO_LABEL'));
        // PackageNumber_Label is added from OnPrintLabel_OnAfterPopulateDataset event
        _Dataset.SetValue('ItemBarcode_Label', 'ItemBarcode');
        _Dataset.SetValue('Quantity_Label', MobLanguage.GetMessage('QUANTITY'));
    end;

    /// <summary>
    /// Transfer Whse Receipt fields to Dataset
    /// </summary>
    local procedure TransferWhseReceiptLine2Dataset(_SourceRecRef: RecordRef; var _Dataset: Record "MOB Common Element")
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        ItemRecRef: RecordRef;
    begin
        // Get source Records
        _SourceRecRef.SetTable(WarehouseReceiptLine);
        WarehouseReceiptLine.SetView(_SourceRecRef.GetView());
        WarehouseReceiptHeader.Get(WarehouseReceiptLine."No.");

        // Transfer header/lines
        ReceiveHeader2Dataset(WarehouseReceiptHeader, _Dataset);
        ReceiveLine2Dataset(WarehouseReceiptLine, _Dataset);

        // Transfer Item info if possible
        if GetItem_As_RecRef(ItemRecRef, WarehouseReceiptLine."Item No.") then
            TransferItem2Dataset(ItemRecRef, _Dataset);
    end;

    /// <summary>
    /// Transfer Sales Shipment to Dataset
    /// This is used for "OrderList"-template
    /// </summary>
    local procedure TransferSalesShipmentHeaderAndLines2Dataset(_SourceRecRef: RecordRef; var _Dataset: Record "MOB Common Element")
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesShipmentLine: Record "Sales Shipment Line";
    begin

        // Get source Records
        _SourceRecRef.SetTable(SalesShipmentHeader);
        SalesShipmentLine.SetRange("Document No.", SalesShipmentHeader."No.");

        // Transfer header/lines
        SalesShipmentHeader2Dataset(SalesShipmentHeader, _Dataset);
        SalesShipmentLine.SetFilter(Quantity, '>0');
        if SalesShipmentLine.FindSet() then
            repeat
                SalesShipmentLine2Dataset(SalesShipmentLine, _Dataset);
            until SalesShipmentLine.Next() = 0;
    end;

    /// <summary>
    /// Transfer Return Shipment to Dataset
    /// This is used for "OrderList"-template
    /// </summary>
    local procedure TransferReturnShipmentHeaderAndLines2DataSet(_SourceRecRef: RecordRef; var _Dataset: Record "MOB Common Element")
    var
        ReturnShipmentHeader: Record "Return Shipment Header";
        ReturnShipmentLine: Record "Return Shipment Line";
    begin

        //Get source Records
        _SourceRecRef.SetTable(ReturnShipmentHeader);
        ReturnShipmentLine.SetRange("Document No.", ReturnShipmentHeader."No.");

        //Transfer header/lines
        ReturnShipmentHeader2Dataset(ReturnShipmentHeader, _Dataset);
        ReturnShipmentLine.SetFilter(Quantity, '>0');
        if ReturnShipmentLine.FindSet() then
            repeat
                ReturnShipmentLine2DataSet(ReturnShipmentLine, _Dataset);
            until ReturnShipmentLine.Next() = 0;
    end;

    /// <summary>
    /// Transfer "Transfer Shipment" to Dataset
    /// This is used for "OrderList"-template
    /// </summary>
    local procedure TransferTransferShipmentHeaderAndLines2DataSet(_SourceRecRef: RecordRef; var _Dataset: Record "MOB Common Element")
    var
        TransferShipmentHeader: Record "Transfer Shipment Header";
        TransferShipmentLine: Record "Transfer Shipment Line";
    begin

        //Get source Records
        _SourceRecRef.SetTable(TransferShipmentHeader);
        TransferShipmentLine.SetRange("Document No.", TransferShipmentHeader."No.");

        //Transfer Header/Lines
        TransferShipmentHeader2Dataset(TransferShipmentHeader, _Dataset);
        TransferShipmentLine.SetFilter(Quantity, '>0');
        if TransferShipmentLine.FindSet() then
            repeat
                TransferShipmentLine2DataSet(TransferShipmentLine, _Dataset);
            until TransferShipmentLine.Next() = 0;
    end;

    /// <summary>
    /// Transfer Sales fields to Dataset
    /// </summary>
    local procedure TransferSalesLine2Dataset(_SourceRecRef: RecordRef; var _Dataset: Record "MOB Common Element")
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemRecRef: RecordRef;
    begin
        // Get source Records
        _SourceRecRef.SetTable(SalesLine);
        SalesLine.SetView(_SourceRecRef.GetView());
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");

        // Transfer header/lines
        SalesHeader2Dataset(SalesHeader, _Dataset);
        SalesLine2Dataset(SalesLine, _Dataset);

        // Transfer Item info if possible
        if SalesLine.Type = SalesLine.Type::Item then
            if GetItem_As_RecRef(ItemRecRef, SalesLine."No.") then
                TransferItem2Dataset(ItemRecRef, _Dataset);
    end;

    /// <summary>
    /// Transfer Purchase fields to Dataset
    /// </summary>
    local procedure TransferPurchaseLine2Dataset(_SourceRecRef: RecordRef; var _Dataset: Record "MOB Common Element")
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ItemRecRef: RecordRef;
    begin
        // Get source Records
        _SourceRecRef.SetTable(PurchaseLine);
        PurchaseLine.SetView(_SourceRecRef.GetView());
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");

        // Transfer header/lines
        PurchaseHeader2Dataset(PurchaseHeader, _Dataset);
        PurchaseLine2Dataset(PurchaseLine, _Dataset);

        // Transfer Item info if possible
        if PurchaseLine.Type = PurchaseLine.Type::Item then
            if GetItem_As_RecRef(ItemRecRef, PurchaseLine."No.") then
                TransferItem2Dataset(ItemRecRef, _Dataset);
    end;

    /// <summary>
    /// Transfer Whse Transfer fields to Dataset
    /// </summary>
    local procedure TransferTransferLine2Dataset(_SourceRecRef: RecordRef; var _Dataset: Record "MOB Common Element")
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ItemRecRef: RecordRef;
    begin
        // Get source Records
        _SourceRecRef.SetTable(TransferLine);
        TransferLine.SetView(_SourceRecRef.GetView());
        TransferHeader.Get(TransferLine."Document No.");

        // Transfer header/lines
        TransferHeader2Dataset(TransferHeader, _Dataset);
        TransferLine2Dataset(TransferLine, _Dataset);

        // Transfer Item info if possible
        if GetItem_As_RecRef(ItemRecRef, TransferLine."Item No.") then
            TransferItem2Dataset(ItemRecRef, _Dataset);
    end;

    /// <summary>
    /// Transfer Shipments to Dataset as individual labels
    /// For Sales, Return and Transfer Shipments 
    /// This is used for "OrderList"-template
    /// </summary>
    local procedure TransferShipmentsByWhseShipmentLine2Dataset(_WhseShipmentLine: Record "Warehouse Shipment Line"; var _Dataset: Record "MOB Common Element")
    var
        PostedWhseShipmentHeader: Record "Posted Whse. Shipment Header";
        PostedWhseShipmentLine: Record "Posted Whse. Shipment Line";
        SalesShipmentHeader: Record "Sales Shipment Header";
        ReturnShipmentHeader: Record "Return Shipment Header";
        TransferShipmentHeader: Record "Transfer Shipment Header";
        RecRef: RecordRef;
        AddNewLabel: Boolean;
    begin
        // Find last posted shipment
        PostedWhseShipmentHeader.SetRange("Whse. Shipment No.", _WhseShipmentLine."No.");
        if not PostedWhseShipmentHeader.FindLast() then
            exit;

        // Loop each unique source document posted on this shipment
        PostedWhseShipmentLine.SetCurrentKey("No.", "Source Type", "Source Subtype", "Source No.", "Source Line No.");
        PostedWhseShipmentLine.SetRange("No.", PostedWhseShipmentHeader."No.");
        if PostedWhseShipmentLine.FindSet() then
            repeat
                PostedWhseShipmentLine.SetRange("Source Type", PostedWhseShipmentLine."Source Type");
                PostedWhseShipmentLine.SetRange("Source Subtype", PostedWhseShipmentLine."Source Subtype");
                PostedWhseShipmentLine.SetRange("Source No.", PostedWhseShipmentLine."Source No.");

                // Create new dataset per source = A label per shipment
                if AddNewLabel then
                    _Dataset.Create();
                AddNewLabel := true;

                case PostedWhseShipmentLine."Posted Source Document" of

                    // Transfer Sales Shipment to dataset
                    PostedWhseShipmentLine."Posted Source Document"::"Posted Shipment":
                        if SalesShipmentHeader.Get(PostedWhseShipmentLine."Posted Source No.") then begin
                            RecRef.GetTable(SalesShipmentHeader);
                            TransferSalesShipmentHeaderAndLines2Dataset(RecRef, _Dataset);
                        end;

                    // Transfer Return Shipment to dataset
                    PostedWhseShipmentLine."Posted Source Document"::"Posted Return Shipment":
                        if ReturnShipmentHeader.Get(PostedWhseShipmentLine."Posted Source No.") then begin
                            RecRef.GetTable(ReturnShipmentHeader);
                            TransferReturnShipmentHeaderAndLines2DataSet(RecRef, _Dataset);
                        end;

                    // Transfer Transfer Shipment to dataset

                    PostedWhseShipmentLine."Posted Source Document"::"Posted Transfer Shipment":
                        if TransferShipmentHeader.Get(PostedWhseShipmentLine."Posted Source No.") then begin
                            RecRef.GetTable(TransferShipmentHeader);
                            TransferTransferShipmentHeaderAndLines2DataSet(RecRef, _Dataset);
                        end;
                end;

                // Exclude more shipment lines from the same source document
                if PostedWhseShipmentLine.FindLast() then;
                PostedWhseShipmentLine.SetRange("Source Type");
                PostedWhseShipmentLine.SetRange("Source Subtype");
                PostedWhseShipmentLine.SetRange("Source No.");
            until PostedWhseShipmentLine.Next() = 0;
    end;

    /// <summary>
    /// Transfer Whse Shipment fields to Dataset
    /// </summary>
    local procedure TransferWhseShipmentLine2Dataset(_SourceRecRef: RecordRef; var _Dataset: Record "MOB Common Element")
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        ItemRecRef: RecordRef;
    begin
        // Get source Rec
        _SourceRecRef.SetTable(WarehouseShipmentLine);
        WarehouseShipmentLine.SetView(_SourceRecRef.GetView());

        // Transfer Item info if possible
        if GetItem_As_RecRef(ItemRecRef, WarehouseShipmentLine."Item No.") then
            TransferItem2Dataset(ItemRecRef, _Dataset);

        // Transfer shipment info
        _Dataset.SetValue('PackingSlipId', WarehouseShipmentLine."No.");
        _Dataset.SetValue('DeliveryName', GetShipToName_FromShipmentLine(WarehouseShipmentLine));
        _Dataset.SetValue('DeliveryAddress', GetShipToAddress_FromShipmentLine(WarehouseShipmentLine));
        _Dataset.SetValue('Worker', GetToContact_FromShipmentLine(WarehouseShipmentLine));
    end;

    /// <summary>
    /// Transfer Whse Shipment fields to Dataset
    /// </summary>
    local procedure TransferWhseActivityLine2Dataset(_SourceRecRef: RecordRef; var _Dataset: Record "MOB Common Element")
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ItemRecRef: RecordRef;
    begin
        // Get source Rec
        _SourceRecRef.SetTable(WarehouseActivityLine);
        WarehouseActivityLine.SetView(_SourceRecRef.GetView());

        // Transfer header
        _Dataset.SetValue('Header-No', WarehouseActivityLine."No.");

        // Transfer lines
        WarehouseActivityLine2Dataset(WarehouseActivityLine, _Dataset);

        // Transfer activity info
        _Dataset.SetValue('PackingSlipId', GetShipment_FromWhseActivityLine(WarehouseActivityLine));
        _Dataset.SetValue('DeliveryName', GetShipToName_FromWhseActivityLine(WarehouseActivityLine));
        _Dataset.SetValue('DeliveryAddress', GetShipToAddress_FromWhseActivitytLine(WarehouseActivityLine));

        // Transfer Item info if possible
        if GetItem_As_RecRef(ItemRecRef, WarehouseActivityLine."Item No.") then
            TransferItem2Dataset(ItemRecRef, _Dataset);
    end;

    /// <summary>
    /// Transfer Whse Journal fields to Dataset
    /// </summary>
    local procedure TransferWhseJournalLine2Dataset(_SourceRecRef: RecordRef; var _Dataset: Record "MOB Common Element")
    var
        WarehouseJournalLine: Record "Warehouse Journal Line";
        ItemRecRef: RecordRef;
    begin
        // Get source Rec
        _SourceRecRef.SetTable(WarehouseJournalLine);
        WarehouseJournalLine.SetView(_SourceRecRef.GetView());

        // Transfer lines
        WarehouseJournalLine2Dataset(WarehouseJournalLine, _Dataset);

        // Transfer Item info if possible
        if GetItem_As_RecRef(ItemRecRef, WarehouseJournalLine."Item No.") then
            TransferItem2Dataset(ItemRecRef, _Dataset);
    end;

    /// <summary>
    /// Transfer Item Journal fields to Dataset
    /// </summary>
    local procedure TransferItemJournalLine2Dataset(_SourceRecRef: RecordRef; var _Dataset: Record "MOB Common Element")
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemRecRef: RecordRef;
    begin
        // Get source Rec
        _SourceRecRef.SetTable(ItemJournalLine);
        ItemJournalLine.SetView(_SourceRecRef.GetView());

        // Transfer lines
        ItemJournalLine2Dataset(ItemJournalLine, _Dataset);

        // Transfer Item info if possible
        if GetItem_As_RecRef(ItemRecRef, ItemJournalLine."Item No.") then
            TransferItem2Dataset(ItemRecRef, _Dataset);
    end;

    /// <summary>
    /// Transfer Prod. Order Line fields to Dataset
    /// </summary>
    local procedure TransferProdOrderLine2Dataset(_SourceRecRef: RecordRef; var _Dataset: Record "MOB Common Element")
    var
        ProdOrderLine: Record "Prod. Order Line";
        ItemRecRef: RecordRef;
    begin
        // Get source Rec
        _SourceRecRef.SetTable(ProdOrderLine);
        ProdOrderLine.SetView(_SourceRecRef.GetView());

        // Transfer lines
        ProdOrderLine2Dataset(ProdOrderLine, _Dataset);

        // Transfer Item info if possible
        if GetItem_As_RecRef(ItemRecRef, ProdOrderLine."Item No.") then
            TransferItem2Dataset(ItemRecRef, _Dataset);
    end;

    /// <summary>
    /// Transfer Assembly Header fields to Dataset
    /// </summary>
    local procedure TransferAssemblyHeader2Dataset(_SourceRecRef: RecordRef; var _Dataset: Record "MOB Common Element")
    var
        AssemblyHeader: Record "Assembly Header";
        ItemRecRef: RecordRef;
    begin
        // Get source Rec
        _SourceRecRef.SetTable(AssemblyHeader);
        AssemblyHeader.SetView(_SourceRecRef.GetView());

        // Transfer lines
        AssemblyHeader2Dataset(AssemblyHeader, _Dataset);

        // Transfer Item info if possible
        if GetItem_As_RecRef(ItemRecRef, AssemblyHeader."Item No.") then
            TransferItem2Dataset(ItemRecRef, _Dataset);
    end;

    /// <summary>
    /// Transfer Assembly Line fields to Dataset
    /// </summary>
    local procedure TransferAssemblyLine2Dataset(_SourceRecRef: RecordRef; var _Dataset: Record "MOB Common Element")
    var
        AssemblyLine: Record "Assembly Line";
        ItemRecRef: RecordRef;
    begin
        // Get source Rec
        _SourceRecRef.SetTable(AssemblyLine);
        AssemblyLine.SetView(_SourceRecRef.GetView());

        // Transfer lines
        AssemblyLine2Dataset(AssemblyLine, _Dataset);

        // Transfer Item info if possible
        if GetItem_As_RecRef(ItemRecRef, AssemblyLine."No.") then
            TransferItem2Dataset(ItemRecRef, _Dataset);
    end;

    /// <summary>
    /// Populate label-template with fields from dataset buffer
    /// </summary>
    local procedure Dataset2TemplateRequest(var _Dataset: Record "MOB Common Element"; var _LabelTemplate: Record "MOB Label-Template") ReturnValue: XmlDocument
    begin
        ReturnValue := MobInterForm.CreateRequest(_Dataset, _LabelTemplate);
        if MobXmlMgt.DocIsNull(ReturnValue) then
            Error(FailedLabelXmlTxt);
    end;

    /// <summary>
    /// Identify required Steps for a Label-Template
    /// </summary>
    internal procedure GetStepsForTemplate(_LabelTemplate: Record "MOB Label-Template"; var _RequestValues: Record "MOB NS Request Element"; _SourceRecRef: RecordRef; var _RequiredSteps: Record "MOB Steps Element" temporary) HasRequiredSteps: Boolean
    var
        PrintParameter: Record "MOB Print REST Parameter";
        TempCommonElements: Record "MOB Common Element" temporary;
    begin
        _RequiredSteps.DeleteAll();

        // Copy context data to dataset
        TempCommonElements.Create();
        TransferSourceRecord2Dataset(_SourceRecRef, _RequestValues, TempCommonElements);
        TransformStandardValues(TempCommonElements);

        // Identify steps
        PrintParameter."Label-Template Name" := _LabelTemplate.Name;
        case _LabelTemplate."Template Handler" of
            "MOB Label-Template Handler"::"Item Label":
                GetSteps_ItemLabel(_LabelTemplate.Name, TempCommonElements, _RequestValues, _RequiredSteps);
            "MOB Label-Template Handler"::"Sales Shipment",
            "MOB Label-Template Handler"::"Warehouse Shipment":
                GetSteps_OrderList(_LabelTemplate.Name, _SourceRecRef, _RequestValues, _RequiredSteps);
        end;

        // Events to allow of custom templates
        // or modify existing template's steps
        _RequiredSteps.SetMustCallCreateNext(true);
        OnLookupOnPrintLabel_OnAddStepsForTemplate(_LabelTemplate.Name, _RequestValues, _SourceRecRef, _RequiredSteps, TempCommonElements);
        _RequiredSteps.SetMustCallCreateNext(false);
        if _RequiredSteps.FindSet() then begin
            repeat
                OnLookupOnPrintLabel_OnAfterAddStepForTemplate(_LabelTemplate.Name, _RequestValues, _SourceRecRef, _RequiredSteps, TempCommonElements);
            until _RequiredSteps.Next() = 0;
            exit(true);
        end;
        // No steps = Do not show label
    end;

    /// <summary>
    /// Identify required Steps for a Label-Template
    /// </summary>
    procedure GetStepsForTemplate(_LabelTemplate: Record "MOB Label-Template"; _SourceRecRef: RecordRef; var _RequiredSteps: Record "MOB Steps Element" temporary) HasRequiredSteps: Boolean
    var
        TempDummyRequestValues: Record "MOB NS Request Element" temporary;
    begin
        GetStepsForTemplate(_LabelTemplate, TempDummyRequestValues, _SourceRecRef, _RequiredSteps);
    end;

    /// <summary>
    /// Get the required steps for Item Label
    /// </summary>
    local procedure GetSteps_ItemLabel(_TemplateName: Text[50]; var _Dataset: Record "MOB Common Element"; var _RequestValues: Record "MOB NS Request Element"; var _RequiredSteps: Record "MOB Steps Element")
    var
        Item: Record Item;
        MobTrackingSetup: Record "MOB Tracking Setup";
        RegisterExpirationDate: Boolean;
        MultipleItemUoM: Boolean;
        ItemReferenceUoMList: Text;
        ItemReferenceUoMHelp: Text;
    begin
        if not Item.Get(_Dataset.GetValue('ItemNumber', false)) then
            exit; // Return no steps = Label will not be included

        // Determine Item tracking
        MobTrackingSetup.DetermineSpecificTrackingRequiredFromItemNo(Item."No.", RegisterExpirationDate);
        MobTrackingSetup.CopyTrackingFromRequestContextValues(_RequestValues); // Respect values from context as defaultvalues when creating steps below
        // Collect Lot, SN 
        _RequiredSteps.Create_TrackingStepsIfRequired(MobTrackingSetup, 10, Item."No.", true);
        // Collect ExpirationDate
        if RegisterExpirationDate then begin
            _RequiredSteps.Create_DateStep_ExpirationDate(50, Item."No.");
            _RequiredSteps.Set_defaultValue(_RequestValues.GetContextValueAsDate('ExpirationDate'));
        end;

        // Collect Unit of Measure
        _RequiredSteps.Create_ListStep_UoM(60, Item."No.");

        if not MobTrackingSetup."Serial No. Required" then // Not relevant for serial number                
            if _Dataset.GetValue('ItemBarcodeUoM') = '' then // Not relevant if known from ItemReference
                ItemReferenceUoMList := MobWmsToolbox.GetItemReferenceUoMList(Item."No.", _Dataset.GetValue('Variant'));

        MultipleItemUoM := ItemReferenceUoMList.Contains(';');
        if MultipleItemUoM then begin // Must have multiple units in order to collect
            _RequiredSteps.Set_defaultValue(_Dataset.GetValue('UnitOfMeasure', false));
            _RequiredSteps.Set_listValues(ItemReferenceUoMList); // Overwrite with list of Units 
        end else begin
            _RequiredSteps.Set_defaultValue(ItemReferenceUoMList); // Set default value to the single valid UoM
            _RequiredSteps.Set_visible(false); // Hide step if only one valid UoM
        end;

        // Collect Quantity per label
        if not MobTrackingSetup."Serial No. Required" then begin
            _RequiredSteps.Create_DecimalStep_QuantityPerLabel(70);
            _RequiredSteps.Set_defaultValue(_Dataset.GetValueAsInteger('QuantityPerLabel', false));

            // Add Helplabel
            if (ItemReferenceUoMList <> '') and (not MultipleItemUoM) then // A single valid UoM was found
                ItemReferenceUoMHelp := ItemReferenceUoMList
            else
                ItemReferenceUoMHelp := _Dataset.GetValue('ItemBarcodeUoM'); // UoM is known from ItemReference

            if ItemReferenceUoMHelp <> '' then
                _RequiredSteps.Set_helpLabel(_RequiredSteps.Get_helpLabel() + MobToolbox.CRLFSeparator() + MobLanguage.GetMessage('UOM_LABEL') + ': ' + ItemReferenceUoMHelp);
        end;

        // Collect Variant 
        if (MobWmsToolbox.GetItemVariants(Item."No.") <> '') and (_Dataset.GetValue('Variant') = '') then
            _RequiredSteps.Create_ListStep_Variant(80, Item."No.");

        // Printer related steps
        CreatePrinterAndNoOfCopiesSteps(_TemplateName, _RequestValues, _RequiredSteps);
    end;

    /// <summary>
    /// Get the required steps for Order List
    /// </summary>
    local procedure GetSteps_OrderList(_TemplateName: Text[50]; _SourceRecRef: RecordRef; var _RequestValues: Record "MOB NS Request Element"; var _RequiredSteps: Record "MOB Steps Element")
    begin
        // Order List is based on a document, so no steps are needed except required printer steps
        if not (_SourceRecRef.Number() in [Database::"Sales Header", Database::"Warehouse Shipment Header"]) then
            exit;

        // Prevent Orderlist from printing from Pack & Ship lookup
        if _RequestValues.GetContextValue('LookupType') = 'PackagesToShipLookup' then
            exit;

        // Printer related steps
        CreatePrinterAndNoOfCopiesSteps(_TemplateName, _RequestValues, _RequiredSteps);
    end;


    //
    // -------------------------------- Base Record Helper --------------------------------
    //

    local procedure GetItem_As_RecRef(var _RecRef: RecordRef; _No: Code[20]): Boolean
    var
        Item: Record Item;
    begin
        if not Item.Get(_No) then
            exit(false);

        _RecRef.GetTable(Item);
        exit(true);
    end;

    local procedure GetWarehouseShipmentLine_As_RecRef(var _RecRef: RecordRef; _No: Code[20]; _LineNo: Integer): Boolean
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        if _LineNo <> 0 then begin
            if not WarehouseShipmentLine.Get(_No, _LineNo) then
                exit(false);
        end else begin
            WarehouseShipmentLine.SetRange("No.", _No);
            if not WarehouseShipmentLine.FindFirst() then
                exit(false);
        end;

        _RecRef.GetTable(WarehouseShipmentLine);
        exit(true);
    end;

    local procedure GetSourceRecords_FromShipmentLine(_Line: Record "Warehouse Shipment Line"; var _SalesHeader: Record "Sales Header"; var _TransferHeader: Record "Transfer Header"): Boolean
    begin
        GetSourceRecords(_Line."Source Type", _Line."Source Subtype", _Line."Source No.", _SalesHeader, _TransferHeader);
    end;

    local procedure GetSourceRecords_FromWhseActivityLine(_Line: Record "Warehouse Activity Line"; var _SalesHeader: Record "Sales Header"; var _TransferHeader: Record "Transfer Header"): Boolean
    begin
        GetSourceRecords(_Line."Source Type", _Line."Source Subtype", _Line."Source No.", _SalesHeader, _TransferHeader);
    end;

    local procedure GetSourceRecords(_SourceType: Integer; _SourceSubType: Integer; _SourceNo: Code[20]; var _SalesHeader: Record "Sales Header"; var _TransferHeader: Record "Transfer Header"): Boolean
    begin
        case _SourceType of
            Database::"Sales Line":
                exit(_SalesHeader.Get(_SourceSubType, _SourceNo));
            Database::"Transfer Line":
                exit(_TransferHeader.Get(_SourceNo));
        end;
    end;

    local procedure GetShipToName_FromShipmentLine(_Line: Record "Warehouse Shipment Line"): Text
    var
        SalesHeader: Record "Sales Header";
        TransferHeader: Record "Transfer Header";
    begin
        GetSourceRecords_FromShipmentLine(_Line, SalesHeader, TransferHeader);
        case _Line."Source Type" of
            Database::"Sales Line":
                exit(SalesHeader."Ship-to Name");
            Database::"Transfer Line":
                exit(TransferHeader."Transfer-to Name");
        end;
    end;

    local procedure GetShipToAddress_FromShipmentLine(_Line: Record "Warehouse Shipment Line"): Text
    var
        SalesHeader: Record "Sales Header";
        TransferHeader: Record "Transfer Header";
        AddrArray: array[8] of Text;
        CustAddrArray: array[8] of Text;
    begin
        GetSourceRecords_FromShipmentLine(_Line, SalesHeader, TransferHeader);

        FormatAddress.SalesHeaderShipTo(AddrArray, CustAddrArray, SalesHeader);

        exit(AddrArray[2] + MobToolbox.CRLFSeparator() +
             AddrArray[3] + MobToolbox.CRLFSeparator() +
             AddrArray[4] + MobToolbox.CRLFSeparator() +
             AddrArray[5]);
    end;

    local procedure GetToContact_FromShipmentLine(_Line: Record "Warehouse Shipment Line"): Text
    var
        SalesHeader: Record "Sales Header";
        TransferHeader: Record "Transfer Header";
    begin
        GetSourceRecords_FromShipmentLine(_Line, SalesHeader, TransferHeader);
        case _Line."Source Type" of
            Database::"Sales Line":
                exit(SalesHeader."Ship-to Contact");
            Database::"Transfer Line":
                exit(TransferHeader."Transfer-to Contact");
        end;
    end;

    local procedure GetShipment_FromWhseActivityLine(_Line: Record "Warehouse Activity Line"): Text
    var
        SalesHeader: Record "Sales Header";
        TransferHeader: Record "Transfer Header";
    begin
        if _Line."Whse. Document Type" = _Line."Whse. Document Type"::Shipment then
            exit(_Line."Whse. Document No.");

        GetSourceRecords_FromWhseActivityLine(_Line, SalesHeader, TransferHeader);
        case _Line."Source Type" of
            Database::"Sales Line":
                exit(SalesHeader."No.");
            Database::"Transfer Line":
                exit(TransferHeader."No.");
        end;
    end;

    local procedure GetShipToName_FromWhseActivityLine(_Line: Record "Warehouse Activity Line"): Text
    var
        SalesHeader: Record "Sales Header";
        TransferHeader: Record "Transfer Header";
    begin
        GetSourceRecords_FromWhseActivityLine(_Line, SalesHeader, TransferHeader);
        case _Line."Source Type" of
            Database::"Sales Line":
                exit(SalesHeader."Ship-to Name");
            Database::"Transfer Line":
                exit(TransferHeader."Transfer-to Name");
        end;
    end;

    /// <summary>
    /// Get Ship-to from Warehouse Shipment
    /// </summary>
    local procedure GetShipToAddress_FromWhseActivitytLine(_Line: Record "Warehouse Activity Line"): Text
    var
        SalesHeader: Record "Sales Header";
        TransferHeader: Record "Transfer Header";
        AddrArray: array[8] of Text;
        CustAddrArray: array[8] of Text;
    begin
        GetSourceRecords_FromWhseActivityLine(_Line, SalesHeader, TransferHeader);
        FormatAddress.SalesHeaderShipTo(AddrArray, CustAddrArray, SalesHeader);

        exit(AddrArray[2] + MobToolbox.CRLFSeparator() +
             AddrArray[3] + MobToolbox.CRLFSeparator() +
             AddrArray[4] + MobToolbox.CRLFSeparator() +
             AddrArray[5]);
    end;

    //
    // -------------------------------- Logging --------------------------------
    //

    /// <summary>
    /// Init log entry, Status = processing
    /// </summary>
    local procedure LogBegin(_SourceRecVariant: Variant; var _PrintParameter: Record "MOB Print REST Parameter")
    begin
        MobPrintLog.Init();
        MobPrintLog."Created Date/Time" := CurrentDateTime();
        MobPrintLog."Message ID" := _PrintParameter."Message ID";
        MobPrintLog."Device ID" := _PrintParameter."Device ID";
        MobPrintLog."Mobile User ID" := UserId();
        MobPrintLog."Label-Template Name" := _PrintParameter."Label-Template Name";
        Evaluate(MobPrintLog."Record ID", MobToolbox.Variant2RecordID(_SourceRecVariant));
        MobPrintLog.Description := Format(MobPrintLog."Record ID");
        MobPrintLog.Insert();
    end;

    /// <summary>
    /// Log internal Dataset
    /// Helps developer when customizing labels 
    /// </summary>
    local procedure LogDataSet(var _Dataset: Record "MOB Common Element")
    var
        TempNodeValueBuffer: Record "MOB NodeValue Buffer" temporary;
        DataSetAsXml: XmlDocument;
        XmlRootNode: XmlNode;
        XmlDataSetNode: XmlNode;
        XmlReturnNode: XmlNode;
        NodeName: Text;
        oStream: OutStream;
    begin
        if _Dataset.FindSet() then begin // Can be multiple labels
            MobXmlMgt.InitializeDoc(DataSetAsXml, 'Root');
            MobXmlMgt.GetDocRootNode(DataSetAsXml, XmlRootNode);
            repeat
                _Dataset.GetSharedNodeValueBuffer(TempNodeValueBuffer);
                if TempNodeValueBuffer.FindSet() then begin
                    // Add each label's dataset
                    MobXmlMgt.AddElement(XmlRootNode, 'Dataset' + Format(_Dataset."Key"), '', '', XmlDataSetNode);
                    repeat
                        NodeName := ConvertStr(TempNodeValueBuffer.Path, '/', '.');
                        MobXmlMgt.AddElement(XmlDataSetNode, NodeName, TempNodeValueBuffer.GetValue(), '', XmlReturnNode);
                    until TempNodeValueBuffer.Next() = 0;
                end;
            until _Dataset.Next() = 0;
        end;

        MobPrintLog."Request DataSet".CreateOutStream(oStream);
        if not MobXmlMgt.DocIsNull(DataSetAsXml) then
            MobXmlMgt.DocSaveStream(DataSetAsXml, oStream);
        MobPrintLog.Modify();
    end;

    /// <summary>
    /// Log the request (Xml) sent to Cloud Print Service
    /// </summary>

    local procedure LogCloudRequest(_XmlRequestDoc: XmlDocument)
    var
        oStream: OutStream;
    begin
        MobPrintLog."Request Data".CreateOutStream(oStream);
        MobXmlMgt.DocSaveStream(_XmlRequestDoc, oStream);
        MobPrintLog.Modify();
    end;

    /// <summary>
    /// Log the response(Xml/Zpl/Url/Pdf) received from to Cloud Print Service
    /// </summary>

    local procedure LogCloudResponse(var _PrintParameter: Record "MOB Print REST Parameter")
    var
        oStream: OutStream;
    begin
        MobPrintLog."Response Data".CreateOutStream(oStream);
        oStream.WriteText(_PrintParameter.GetResponseContentAsText(0));
        MobPrintLog.Modify();
    end;

    //
    // -------------------------------- Misc. Helper --------------------------------
    //

    /// <summary>
    /// Add No. of Copies-step and Printer-step (if more than one printer)  
    /// If only one printer then show printer name as helpLabel 
    /// </summary>
    procedure CreatePrinterAndNoOfCopiesSteps(_TemplateName: Text[50]; var _RequestValues: Record "MOB NS Request Element"; var _Steps: Record "MOB Steps Element")
    var
        ExclusivePrinter: Text;
    begin
        ExclusivePrinter := GetExclusivePrinter(_TemplateName, _RequestValues.Get_Location());
        _Steps.Create_ListStep_Printer(70, _TemplateName, _RequestValues.Get_Location());
        if ExclusivePrinter <> '' then begin // Only one printer = Hide step and set default value
            _Steps.Set_defaultValue(ExclusivePrinter);
            _Steps.Set_visible(false);
        end;

        _Steps.Create_IntegerStep_NoOfCopies(110);
        if ExclusivePrinter <> '' then // Only one printer = Show the printer name as helpLabel
            _Steps.Set_helpLabel(_Steps.Get_helpLabel() + MobToolbox.CRLFSeparator() + MobToolbox.CRLFSeparator() + MobLanguage.GetMessage('PRINTER') + ': ' + ExclusivePrinter)
    end;

    procedure GetPrinterFromName(var _Printer: Record "MOB Printer"; _Name: Text[80]): Boolean
    begin
        _Printer.Get(_Name);
        _Printer.TestField(Enabled, true);
    end;

    /// <summary>
    /// If only one printer is available to a template, the name of that printer "exclusive" is returned
    /// </summary>
    internal procedure GetExclusivePrinter(_TemplateName: Text[50]; _LocationCode: Code[10]): Text
    var
        MobilePrinterList: Text;
    begin
        MobilePrinterList := GetMobilePrinters(_TemplateName, _LocationCode);

        if MobilePrinterList = '' then
            Error(CloudPrintPrefixLbl, MobLanguage.GetMessage('NOPRINTERSETUP'));  // No printer found

        if not MobilePrinterList.Contains(';') then
            exit(MobilePrinterList); // Only one exclusive printer was found
    end;

    /// <summary>
    /// Get comma-separated list of mobile printers available to a template
    /// </summary>
    procedure GetMobilePrinters(_TemplateName: Text[50]; _LocationCode: Code[10]) ReturnPrinterList: Text
    var
        MobPrinter: Record "MOB Printer";
    begin
        MobPrinter.SetRange(Enabled, true);
        if MobPrinter.FindSet() then
            repeat
                if IsTemplateAvailable(MobPrinter.Name, _TemplateName, _LocationCode) then
                    if ReturnPrinterList = '' then
                        ReturnPrinterList := MobPrinter.Name
                    else
                        ReturnPrinterList += ';' + MobPrinter.Name;
            until MobPrinter.Next() = 0;
    end;

    /// <summary>
    /// Get comma-separated list of mobile printers available to a template
    /// </summary>
    procedure GetMobilePrinters(_TemplateName: Text[50]): Text
    begin
        exit(GetMobilePrinters(_TemplateName, ''));
    end;

    /// <summary>
    /// Is printer enabled and allowed for a location 
    /// </summary>
    local procedure IsPrinterAllowedOnLocation(_PrinterName: Text[50]; _LocationCode: Code[10]): Boolean
    var
        MobPrinter: Record "MOB Printer";
    begin
        // Check enabled
        if not (MobPrinter.Get(_PrinterName) and MobPrinter.Enabled) then
            exit(false);

        // Check location filter
        if _LocationCode <> '' then
            exit((MobPrinter."Location Code" = '') or (MobPrinter."Location Code" = _LocationCode))
        else
            exit(true);
    end;

    /// <summary>
    /// Is template available for a printer
    /// </summary>
    local procedure IsTemplateAvailable(_PrinterName: Text[50]; _TemplateName: Text[50]; _LocationCode: Code[10]) ReturnIsAvailable: Boolean
    var
        MobPrinterLabelTemplate: Record "MOB Printer Label-Template";
    begin
        MobPrinterLabelTemplate.SetRange("Label-Template Name", _TemplateName);

        if MobPrinterLabelTemplate.IsEmpty() then
            ReturnIsAvailable := true // No Printer assignment = Template is available by default
        else
            ReturnIsAvailable := MobPrinterLabelTemplate.Get(_PrinterName, _TemplateName); // Check printer assignments

        if ReturnIsAvailable then // Check Location filter
            exit(IsPrinterAllowedOnLocation(_PrinterName, _LocationCode))
    end;

    internal procedure GetTemplateOpenInDesignerUrl(_LabelTemplate: Record "MOB Label-Template") ReturnUrl: Text
    begin
        ErrorIfTenantIsCommon();

        if _LabelTemplate."URL Mapping" = '' then
            exit;

        ReturnUrl := MobInterForm.GetBaseUrl() + 'designer/library/?template=' + _LabelTemplate."URL Mapping";
    end;

    local procedure GetNextNo(_LabelTemplate: Record "MOB Label-Template"): Code[20]
    var
        MobNoSeries: Codeunit "MOB No. Series";
    begin
        _LabelTemplate.TestField("Number Series");
        exit(MobNoSeries.GetNextNo(_LabelTemplate."Number Series", WorkDate(), true));
    end;

    /// <summary>
    /// Set and return the Extensions "Allow HttpClient Requests" setting
    /// </summary>
    procedure SetHTTPRequestAllow() AllowHttpClientRequests: Boolean
    var
        MobEnvironmentInformation: Codeunit "MOB Environment Information";
        AppInfo: ModuleInfo;
    begin
        if not MobEnvironmentInformation.IsSandbox() then
            exit(false);

        NavApp.GetCurrentModuleInfo(AppInfo);

        AllowHttpClientRequests := SetHTTPRequestAllowForApp(AppInfo.Id());

        if not AllowHttpClientRequests then
            AllowHttpClientRequests := SetHTTPRequestAllowForApp('a5727ce6-368c-49e2-84cb-1a6052f0551c'); // Hardcoded due to unreliablity when getting the value dynamically    

        exit(AllowHttpClientRequests);
    end;

    local procedure SetHTTPRequestAllowForApp(_AppId: Guid): Boolean
    var
        NAVAppSetting: Record "NAV App Setting";
    begin
        if not NAVAppSetting.Get(_AppId) then begin
            NAVAppSetting."App ID" := _AppId;
            NAVAppSetting.Insert(true);
        end;

        if not NAVAppSetting."Allow HttpClient Requests" then begin
            NAVAppSetting."Allow HttpClient Requests" := true;
            NAVAppSetting.Modify();
        end;

        exit(NAVAppSetting."Allow HttpClient Requests");
    end;

    //
    // -------------------------------- Setup --------------------------------
    //

    internal procedure ErrorIfNoSetup()
    begin
        MobPrintSetup.Get();
        MobPrintSetup.TestField(Enabled, true);
    end;

    /// <summary>
    /// Returns the Windows Language Id to use for printing.
    /// If Language code is not specified in Print Setup, it will return the Global Language Id.
    /// If the Language record is not found, it will return the Global Language Id.
    /// </summary>
    internal procedure GetPrintLanguageId(): Integer
    begin
        MobPrintSetup.Get();
        exit(MobToolbox.GetLanguageId(MobPrintSetup."Language Code", false));
    end;

    internal procedure ErrorIfTenantIsCommon()
    begin
        MobPrintSetup.Get();
        if MobPrintSetup."Connection Tenant".ToUpper().Contains('COMMON') then
            Error(DesignerNotAvailForCommonErr, MobPrintSetup."Connection Tenant");
    end;

    /// <summary>
    /// Perform the standard basic print setup
    /// </summary>
    procedure CreateStandardSetup(var _Rec: Record "MOB Print Setup"; _Confirm: Boolean)
    var
        LabelTemplate: Record "MOB Label-Template";
    begin
        // Create Setup Record
        InitSetupRec(_Rec, _Confirm);

        // Insert Connection details
        SetupConnection(_Rec);

        // Finish the record
        _Rec.Insert();

        // Insert the supported reports
        SetupStandardTemplate(LabelTemplate, _Confirm);

        // Set HttpRequest is allowed
        SetHTTPRequestAllow();
    end;

    local procedure InitSetupRec(var _PrintSetup: Record "MOB Print Setup"; _Confirm: Boolean): Boolean
    var
        OldPrintSetup: Record "MOB Print Setup";
    begin
        // Warn if exist
        _PrintSetup.Reset();
        if _PrintSetup.FindFirst() and (_PrintSetup."Connection URL" <> '') then
            if _Confirm and GuiAllowed() then
                if not Confirm(ReplaceSetupTxt, false) then
                    Error('');
        OldPrintSetup := _PrintSetup;

        _PrintSetup.DeleteAll(true);

        // Create Record
        _PrintSetup.Init();
        _PrintSetup.Enabled := true;
        _PrintSetup."Language Code" := OldPrintSetup."Language Code"; // Keep Language Code from existing Printer Setup (if existed)

        exit(true);
    end;

    /// <summary>
    /// Create print service connection setup
    /// </summary>
    local procedure SetupConnection(var _PrintSetup: Record "MOB Print Setup")
    begin
        MobInterForm.CreateConnectionSetup(_PrintSetup);
    end;

    internal procedure TestConnection()
    begin
        CheckConnectionSetup();
        MobInterForm.TestConnection();
    end;

    /// <summary>
    /// Insert the supported Label-Templates
    /// </summary>
    internal procedure SetupStandardTemplate(var _LabelTemplate: Record "MOB Label-Template"; _Confirm: Boolean)
    begin
        MobInterForm.CreateTemplates(_LabelTemplate, _Confirm);
    end;

    //
    // ------- IntegrationEvents -------
    //

    /// <summary>
    /// Add steps for a template 
    /// </summary>
    [IntegrationEvent(false, false)]
    local procedure OnLookupOnPrintLabel_OnAddStepsForTemplate(_TemplateName: Text[50]; var _RequestValues: Record "MOB NS Request Element"; _SourceRecRef: RecordRef; var _Steps: Record "MOB Steps Element"; var _Dataset: Record "MOB Common Element")
    begin
    end;

    /// <summary>
    /// Change step for a template 
    /// </summary>
    [IntegrationEvent(false, false)]
    local procedure OnLookupOnPrintLabel_OnAfterAddStepForTemplate(_TemplateName: Text[50]; var _RequestValues: Record "MOB NS Request Element"; _SourceRecRef: RecordRef; var _Step: Record "MOB Steps Element"; var _Dataset: Record "MOB Common Element")
    begin
    end;

    /// <summary>
    /// Populate tracking in Dataset. Prefix is usually "Line-"
    /// </summary>
    [IntegrationEvent(false, false)]
    local procedure OnPrintLabel_OnPopulateDatasetOnCopyTrackingToDataset(_MobTrackingSetup: Record "MOB Tracking Setup"; _Prefix: Text; var _Dataset: Record "MOB Common Element")
    begin
    end;

    /// <summary>
    /// Modify the Dataset after it has been populated with context and collected step values
    /// </summary>
    [IntegrationEvent(false, false)]
    local procedure OnPrintLabel_OnAfterPopulateDataset(_TemplateName: Text[50]; var _RequestValues: Record "MOB NS Request Element"; _SourceRecRef: RecordRef; var _Dataset: Record "MOB Common Element")
    begin
    end;

    /// <summary>
    /// Modify the Dataset line, after it has been populated
    /// </summary>
    [IntegrationEvent(false, false)]
    internal procedure OnPrintLabel_OnAfterPopulateOrderListLine(_LinePath: Text; _SourceRecRef: RecordRef; var _Dataset: Record "MOB Common Element")
    begin
    end;
}
