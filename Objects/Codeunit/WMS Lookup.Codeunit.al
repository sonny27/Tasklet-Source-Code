codeunit 81382 "MOB WMS Lookup"
{
    Access = Public;

    TableNo = "MOB Document Queue";

    trigger OnRun()
    begin
        MobDocQueue := Rec;

        case Rec."Document Type" of

            'Lookup':
                Lookup();

            else
                Error(MobWmsLanguage.GetMessage('NO_DOC_HANDLER'), Rec."Document Type");
        end;

        // Store the result in the queue and update the status
        Rec := MobDocQueue;
        MobToolbox.UpdateResult(Rec, XmlResponseDoc);
    end;

    var
        MobDocQueue: Record "MOB Document Queue";
        MobSessionData: Codeunit "MOB SessionData";
        MobItemReferenceMgt: Codeunit "MOB Item Reference Mgt.";
        MobToolbox: Codeunit "MOB Toolbox";
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
        MobXmlMgt: Codeunit "MOB XML Management";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        XmlResponseDoc: XmlDocument;
        BIN_CONTENT_Txt: Label 'BinContent', Locked = true;
        SUBSTITUTE_ITEMS_Txt: Label 'SubstituteItems', Locked = true;
        LOCATE_ITEM_Txt: Label 'LocateItem', Locked = true;
        PRINT_LABELTEMPLATE_Txt: Label 'PrintLabelTemplate', Locked = true;
        POST_SHIPMENT_Txt: Label 'PostShipment', Locked = true;
        ATTACHMENTS_Txt: Label 'Attachments', Locked = true;
        PROD_OUTPUT_Txt: Label 'ProdOutput', Locked = true;
        SUBSTITUTE_PROD_ORDER_COMPONENT_Txt: Label 'SubstituteProdOrderComponent', Locked = true;
        HISTORY_Txt: Label 'History', Locked = true;
        LicensePlate_Txt: Label 'LicensePlate', Locked = true;
        PutAwayLicensePlate_Txt: Label 'PutAwayLicensePlate', Locked = true;
        PleaseSetupPrintErr: Label 'Printing is not enabled. Please set up either Report Print or Cloud Print.', Locked = true;

    local procedure Lookup()
    var
        TempRequestValues: Record "MOB NS Request Element" temporary;
        TempLookupResponse: Record "MOB NS WhseInquery Element" temporary;
        MobWmsProductionOutput: Codeunit "MOB WMS Production Output";
        MobWmsProductionConsumption: Codeunit "MOB WMS Production Consumption";
        MobWmsHistory: Codeunit "MOB WMS History";
        MobWmsLicensePlate: Codeunit "MOB WMS LicensePlate Lookup";
        MobWmsPutAwayLicensePlate: Codeunit "MOB WMS Put-away LP Lookup";
        MobRequestMgt: Codeunit "MOB NS Request Management";
        XmlRequestDoc: XmlDocument;
        XmlResponseData: XmlNode;
        LookupType: Text[50];
        RegistrationTypeTracking: Text;
        IsHandled: Boolean;
    begin
        // The Request Document looks like this:
        // <request name="Lookup" created="2018-11-16T13:23:56+01:00" xmlns="http://schemas.microsoft.com/Dynamics/Mobile/2007/04/Documents/Request">
        //   <requestData name="Lookup">
        //     <Location>WHITE</Location>
        //     <Bin>w-01-0002</Bin>
        //     <LookupType>BinContent</LookupType>
        //   </requestData>
        // </request>

        // Load the request document from the document queue
        MobDocQueue.LoadXMLRequestDoc(XmlRequestDoc);

        // Read mandatory LookupType and requestvalues to process
        MobRequestMgt.SaveAdhocRequestValues(XmlRequestDoc, TempRequestValues);     // Same format as Adhoc
        Evaluate(LookupType, TempRequestValues.GetValue('LookupType', true));       // Text to Text[50] conversion due to existing events

        // Save value to be logged in case of error (LookupType is logged in Registration Type field)
        MobSessionData.SetRegistrationType(LookupType);

        // The Lookup function is always called from the "Lookup" screen
        // This screen can be configured to handle many different types of lookups
        // The lookup type is always added as one of the supplied parameters.
        // Use the lookup type to forward the call to the appropriate function.
        case LookupType of
            "CONST::BinContent"():
                LookupBinContent(TempRequestValues, TempLookupResponse, RegistrationTypeTracking);
            "CONST::SubstituteItems"():
                LookupSubstituteItems(TempRequestValues, TempLookupResponse, RegistrationTypeTracking);
            "CONST::LocateItem"():
                LookupLocateItem(TempRequestValues, TempLookupResponse, RegistrationTypeTracking);
            "CONST::PrintLabelTemplate"():
                LookupPrint(TempRequestValues, TempLookupResponse, RegistrationTypeTracking);
            "CONST::Attachments"():
                LookupAttachments(TempRequestValues, TempLookupResponse);
            "CONST::PostShipment"():
                LookupPostShipment(TempRequestValues, TempLookupResponse, RegistrationTypeTracking);
            "CONST::SubstituteProdOrderComponent"():
                MobWmsProductionConsumption.RunLookup(LookupType, TempRequestValues, TempLookupResponse, RegistrationTypeTracking);
            "CONST::ProdOutput"():
                MobWmsProductionOutput.RunLookup(LookupType, TempRequestValues, TempLookupResponse, RegistrationTypeTracking);   // LookupPostProdOutput
            "CONST::History"():
                MobWmsHistory.LookupHistory(TempRequestValues, TempLookupResponse, RegistrationTypeTracking);
            "CONST::LicensePlate"():
                MobWmsLicensePlate.LookupLicensePlate(TempRequestValues, TempLookupResponse, RegistrationTypeTracking);
            "CONST::PutAwayLicensePlate"():
                MobWmsPutAwayLicensePlate.LookupPutAwayLicensePlate(TempRequestValues, TempLookupResponse, RegistrationTypeTracking);
            else begin
                // The LookupType was not part of the standard solution -> see if a customization exists
                Clear(XmlResponseDoc);
                IsHandled := false;
                OnLookupOnCustomLookupType(MobDocQueue.MessageIDAsGuid(), LookupType, TempRequestValues, TempLookupResponse, XmlResponseDoc, RegistrationTypeTracking, IsHandled);  // Parameter XmlReponseDoc only included for backwards compatibility

                // Attempt handle AsXml only if unhandled by no-Xml event
                if not IsHandled then
                    OnLookupOnCustomLookupTypeAsXml(XmlRequestDoc, LookupType, XmlResponseDoc, IsHandled);

                if not IsHandled then
                    Error(MobWmsLanguage.GetMessage('NO_DOC_HANDLER'), 'Lookup::' + LookupType);
            end;
        end;

        // Write XmlReponseDoc
        // Backwards compatibility: XmlResponseDoc returned from OnLookupOnCustomLookupType overrides TempLookupResponse
        if MobXmlMgt.DocIsNull(XmlResponseDoc) then begin
            MobToolbox.InitializeResponseDocWithNS(XmlResponseDoc, XmlResponseData, MobXmlMgt.NS_WHSEMODEL());
            AddLookupResponseElements(LookupType, XmlResponseData, TempLookupResponse);
        end;

        // Update the registration type field on the mobile document queue record
        // In case of errors a fallback value is written from MOB WS Dispatcher
        MobDocQueue.SetRegistrationTypeAndTracking(LookupType, RegistrationTypeTracking);
    end;

    local procedure LookupBinContent(var _RequestValues: Record "MOB NS Request Element"; var _LookupResponse: Record "MOB NS WhseInquery Element"; var _ReturnRegistrationTypeTracking: Text)
    var
        Location: Record Location;
        BinContent: Record "Bin Content";
        BinContentLotSerial: Record "Bin Content";
        TempEntrySummary: Record "Entry Summary" temporary;
        MobTrackingSetup: Record "MOB Tracking Setup";
        LocationCode: Code[10];
        ScannedBin: Text;
        BinCode: Code[20];
        SpecificRegisterExpirationDate: Boolean;
        BinContentIsIncluded: Boolean;
        EntrySummaryFound: Boolean;
        TrackingRequired: Boolean;
    begin
        // Read Request
        // The "Lookup bin content" supplies two parameters: Location and Bin
        // The names of the XML elements are determined by the LookupBinContentConfiguration supplied as reference data
        LocationCode := _RequestValues.GetValue('Location', true);
        ScannedBin := _RequestValues.GetValue('Bin', true);
        BinCode := MobToolbox.ReadBin(ScannedBin);

        Location.Get(LocationCode);

        _ReturnRegistrationTypeTracking := DelChr(LocationCode + ' - ' + BinCode, '<>', ' - ');

        // Lookup the content of the bin
        BinContent.SetCurrentKey("Location Code", "Bin Code");
        BinContent.SetRange("Location Code", LocationCode);
        BinContent.SetRange("Bin Code", BinCode);
        BinContent.SetFilter(Quantity, '<>0');
        OnLookupOnBinContent_OnSetFilterBinContent(_RequestValues, BinContent);

        if BinContent.FindSet() then
            repeat
                MobTrackingSetup.DetermineWhseTrackingRequiredWithExpirationDate(BinContent."Item No.", SpecificRegisterExpirationDate);
                // MobTrackingSetup.Tracking: Copy later in TempEntrySummary loop or fallback to no summary

                EntrySummaryFound := false;
                TrackingRequired := MobTrackingSetup.TrackingRequired();
                if TrackingRequired then begin
                    // Item is tracked, get at summary to Look Up in Bin Content
                    MobWmsToolbox.GetTrackedSummary(TempEntrySummary, Location, BinContent."Bin Code", BinContent."Item No.",
                                                                BinContent."Variant Code", BinContent."Unit of Measure Code", SpecificRegisterExpirationDate);

                    // Respect additional filters from event
                    BinContent.CopyFilter("Serial No. Filter", TempEntrySummary."Serial No.");
                    BinContent.CopyFilter("Lot No. Filter", TempEntrySummary."Lot No.");
                    /* #if BC18+ */
                    BinContent.CopyFilter("Package No. Filter", TempEntrySummary."Package No.");
                    /* #endif */

                    if TempEntrySummary.FindSet() then begin
                        EntrySummaryFound := true;
                        repeat
                            // MobTrackingSetup.TrackingRequired: Determined before (in BinContent loop)
                            MobTrackingSetup.CopyTrackingFromEntrySummary(TempEntrySummary);

                            BinContentLotSerial.Reset();
                            BinContentLotSerial.CopyFilters(BinContent);    // Respect Quantity filter and additional filters from event
                            BinContentLotSerial.SetRange("Location Code", Location.Code);
                            BinContentLotSerial.SetRange("Bin Code", BinContent."Bin Code");
                            BinContentLotSerial.SetRange("Item No.", BinContent."Item No.");
                            BinContentLotSerial.SetRange("Variant Code", BinContent."Variant Code");
                            BinContentLotSerial.SetRange("Unit of Measure Code", BinContent."Unit of Measure Code");
                            MobTrackingSetup.SetTrackingFilterForBinContentIfNotBlank(BinContentLotSerial);
                            BinContentLotSerial.SetAutoCalcFields(Quantity); // Recalculate in case Quantity-filter was entirely removed from event
                            if BinContentLotSerial.FindFirst() then begin

                                // Populate LookupReponse buffer element for <LookupResponse>
                                BinContentIsIncluded := true;
                                OnLookupOnBinContent_OnIncludeBinContent(BinContentLotSerial, BinContentIsIncluded);
                                if BinContentIsIncluded then begin
                                    _LookupResponse.Create();
                                    SetFromLookupBinContent(
                                        BinContentLotSerial,
                                        TempEntrySummary,
                                        _LookupResponse);
                                    _LookupResponse.Save();
                                end;
                            end;
                        until TempEntrySummary.Next() = 0;
                    end;    // EntrySummary found
                end;

                if not (TrackingRequired and EntrySummaryFound) then begin
                    // Fallback for no tracking and tracked items with no inventory on hand
                    Clear(TempEntrySummary);

                    // Recalculate in case Quantity-filter was entirely removed from event
                    BinContent.CalcFields(Quantity);

                    // Populate LookupReponse buffer element for <LookupResponse>
                    BinContentIsIncluded := true;
                    OnLookupOnBinContent_OnIncludeBinContent(BinContent, BinContentIsIncluded);
                    if BinContentIsIncluded then begin
                        _LookupResponse.Create();
                        SetFromLookupBinContent(
                            BinContent,
                            TempEntrySummary, // Blank tracking and Expiration Date
                            _LookupResponse);
                        _LookupResponse.Save();
                    end;
                end;
            until BinContent.Next() = 0;
    end;

    local procedure LookupSubstituteItems(var _RequestValues: Record "MOB NS Request Element"; var _LookupResponse: Record "MOB NS WhseInquery Element"; var _ReturnRegistrationTypeTracking: Text)
    var
        ItemSubstitution: Record "Item Substitution";
        ScannedItemNumber: Text;
        ItemNumber: Code[50];
        VariantCode: Code[10];
    begin
        // Read Request
        ScannedItemNumber := _RequestValues.GetValue('ItemNumber', true);
        ItemNumber := MobItemReferenceMgt.SearchItemReference(MobToolbox.ReadEAN(ScannedItemNumber), VariantCode);

        if VariantCode = '' then
            VariantCode := _RequestValues.GetValue('VariantCode', false);   // Allow reusing LookupSubstituteItems from pages with VariantCode headerfield

        _ReturnRegistrationTypeTracking := DelChr(ItemNumber + ' - ' + VariantCode, '<>', ' - ');

        // Determine if the item has substitutes
        ItemSubstitution.SetRange("No.", MobWmsToolbox.GetItemNumber(ItemNumber));
        ItemSubstitution.SetRange("Variant Code", VariantCode);

        if ItemSubstitution.FindSet() then
            repeat
                // Collect the buffer values for the <LookupResponse> element
                _LookupResponse.Create();
                SetFromLookupSubstituteItem(ItemSubstitution, _LookupResponse);
                _LookupResponse.Save();
            until ItemSubstitution.Next() = 0;
    end;

    /// <summary>
    /// Determine the inventory of the requested item
    /// </summary>
    local procedure LookupLocateItem(var _RequestValues: Record "MOB NS Request Element"; var _LookupResponse: Record "MOB NS WhseInquery Element"; var _ReturnRegistrationTypeTracking: Text)
    var
        Location: Record Location;
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        BinContent: Record "Bin Content";
        BinContentLotSerial: Record "Bin Content";
        TempEntrySummary: Record "Entry Summary" temporary;
        MobTrackingSetup: Record "MOB Tracking Setup";
        ScannedItemNumber: Text;
        ItemNumber: Code[50];
        VariantCode: Code[10];
        DummyUoMCCode: Code[10];
        SpecificRegisterExpirationDate: Boolean;
        LocationCode: Text[10];
        BinContentIsIncluded: Boolean;
    begin
        // Read Request
        ScannedItemNumber := _RequestValues.GetValue('ItemNumber', true);
        ItemNumber := MobItemReferenceMgt.SearchItemReference(MobToolbox.ReadEAN(ScannedItemNumber), VariantCode, DummyUoMCCode, false);
        LocationCode := _RequestValues.GetValue('Location', true);

        _ReturnRegistrationTypeTracking := DelChr(LocationCode + ' - ' + ItemNumber + ' - ' + VariantCode, '<>', ' - ');

        // Only search the locations this user has been assigned
        if LocationCode = 'All' then
            Location.SetFilter(Code, MobWmsToolbox.GetLocationFilter(MobDocQueue."Mobile User ID"))
        else
            Location.SetRange(Code, LocationCode);


        if Location.FindSet() then
            repeat

                // -- Location."Bin Mandatory"
                if Location."Bin Mandatory" then begin

                    // Filter the bin content records
                    BinContent.SetCurrentKey("Item No.");
                    BinContent.SetFilter("Item No.", ConvertItemNumberToExpression(ItemNumber));  // Support wildcard search
                    if VariantCode <> '' then
                        BinContent.SetRange("Variant Code", VariantCode);
                    BinContent.SetFilter("Location Code", Location.Code);
                    BinContent.SetFilter(Quantity, '>0');
                    OnLookupOnLocateItem_OnSetFilterBinContent(_RequestValues, BinContent);

                    // Loop through the bin content records and find the available / physical quantitites
                    if BinContent.FindSet() then
                        repeat

                            Item.Reset();
                            Item.Get(BinContent."Item No.");

                            Clear(MobTrackingSetup);
                            MobTrackingSetup.DetermineWhseTrackingRequiredWithExpirationDate(BinContent."Item No.", SpecificRegisterExpirationDate);
                            // MobTrackingSetup.Tracking: Copy later in TempEntrySummary loop

                            if MobTrackingSetup.TrackingRequired() then begin

                                // Item is tracked, get at summary to Look Up in Bin Content
                                MobWmsToolbox.GetTrackedSummary(TempEntrySummary, Location, BinContent."Bin Code", BinContent."Item No.",
                                                                BinContent."Variant Code", BinContent."Unit of Measure Code", SpecificRegisterExpirationDate);

                                // Respect additional filters from event
                                BinContent.CopyFilter("Serial No. Filter", TempEntrySummary."Serial No.");
                                BinContent.CopyFilter("Lot No. Filter", TempEntrySummary."Lot No.");
                                /* #if BC18+ */
                                BinContent.CopyFilter("Package No. Filter", TempEntrySummary."Package No.");
                                /* #endif */

                                if TempEntrySummary.FindSet() then
                                    repeat
                                        // MobTrackingSetup.TrackingRequired: Determined before (per BinContent)
                                        MobTrackingSetup.CopyTrackingFromEntrySummary(TempEntrySummary);

                                        BinContentLotSerial.Reset();
                                        BinContentLotSerial.CopyFilters(BinContent);    // Respect Quantity filter and additional filters from event
                                        BinContentLotSerial.SetRange("Location Code", BinContent."Location Code");
                                        BinContentLotSerial.SetRange("Bin Code", BinContent."Bin Code");
                                        BinContentLotSerial.SetRange("Item No.", BinContent."Item No.");
                                        BinContentLotSerial.SetRange("Variant Code", BinContent."Variant Code");
                                        BinContentLotSerial.SetRange("Unit of Measure Code", BinContent."Unit of Measure Code");
                                        MobTrackingSetup.SetTrackingFilterForBinContentIfNotBlank(BinContentLotSerial);

                                        BinContentLotSerial.SetAutoCalcFields(Quantity, "Pick Qty.", "Neg. Adjmt. Qty.", "ATO Components Pick Qty.");
                                        if BinContentLotSerial.FindFirst() then begin
                                            BinContentIsIncluded := true;
                                            OnLookupOnLocateItem_OnIncludeBinContent(BinContentLotSerial, BinContentIsIncluded);
                                            if BinContentIsIncluded then begin
                                                // Determine if the item uses serial or lot tracking
                                                // Yes -> find the tracking information
                                                // No  -> just use the quantity from the bin content table

                                                // Populate LookupResponse buffer element for <LookupResponse> (Bin Content with TrackingRequired)
                                                _LookupResponse.Create();
                                                SetFromLookupLocateItem_BinContent(
                                                    Location,
                                                    BinContentLotSerial,
                                                    MobTrackingSetup,
                                                    TempEntrySummary."Expiration Date",
                                                    _LookupResponse);
                                                _LookupResponse.Save();
                                            end;
                                        end;

                                    until TempEntrySummary.Next() = 0;

                            end else begin
                                // MobTrackingSetup.TrackingRequired: Determined before (per BinContent)
                                MobTrackingSetup.ClearTracking();

                                // Calculate the inventory
                                BinContent.CalcFields(Quantity, "Pick Qty.", "Neg. Adjmt. Qty.", "ATO Components Pick Qty.");

                                BinContentIsIncluded := true;
                                OnLookupOnLocateItem_OnIncludeBinContent(BinContent, BinContentIsIncluded);
                                if BinContentIsIncluded then begin
                                    // Populate LookupResponse buffer element for <LookupResponse> (Bin Content with no TrackingRequired)
                                    _LookupResponse.Create();
                                    SetFromLookupLocateItem_BinContent(
                                        Location,
                                        BinContent,
                                        MobTrackingSetup,   // Blank values
                                        0D,     // ExpirationDate
                                        _LookupResponse);
                                    _LookupResponse.Save();
                                end;
                            end;

                        until BinContent.Next() = 0;

                end else begin

                    // -- Not Location."Bin Mandatory"
                    Item.SetFilter("No.", '%1', ConvertItemNumberToExpression(ItemNumber));
                    if Item.FindSet() then
                        repeat
                            Item.SetRange("Location Filter", Location.Code);
                            ItemVariant.SetRange("Item No.", Item."No.");
                            if VariantCode <> '' then
                                ItemVariant.SetRange(Code, VariantCode);

                            // Add inventory (Item has variants)
                            if ItemVariant.FindSet() then
                                repeat
                                    AddLookupLocateItemElement(Item, Location, ItemVariant, _LookupResponse);
                                until ItemVariant.Next() = 0;

                            // Include 'blank' variant inventory
                            if VariantCode = '' then begin
                                Clear(ItemVariant);
                                AddLookupLocateItemElement(Item, Location, ItemVariant, _LookupResponse);
                            end;
                        until Item.Next() = 0;

                end;  // Not Location."Bin Mandatory"

            until Location.Next() = 0;

    end;

    /// <summary>
    /// Convert _ItemNumber to expression being either an exact item number or "fallback" to filter *_ItemNumber*
    /// </summary>
    local procedure ConvertItemNumberToExpression(_ItemNumber: Code[50]) ReturnExpression: Text
    var
        Item: Record Item;
    begin
        case true of
            MobToolbox.IsFilter(_ItemNumber) or (StrLen(_ItemNumber) > MaxStrLen(Item."No.")):
                ReturnExpression := _ItemNumber;
            Item.Get(_ItemNumber):
                ReturnExpression := _ItemNumber;
            else
                ReturnExpression := '*' + _ItemNumber + '*';
        end;
    end;

    /// <summary>
    /// Add a LocateItem entry to the response
    /// </summary>
    local procedure AddLookupLocateItemElement(var _Item: Record Item; _Location: Record Location; _ItemVariant: Record "Item Variant"; var _LookupResponse: Record "MOB NS WhseInquery Element")
    var
        MobCommonMgt: Codeunit "MOB Common Mgt.";
        ItemIsIncluded: Boolean;
    begin
        _Item.SetRange("Variant Filter", _ItemVariant.Code);
        _Item.CalcFields(Inventory, "Qty. on Sales Order", "Trans. Ord. Shipment (Qty.)", "Qty. on Service Order");
        MobCommonMgt.Item_CalcFields_QtyOnComponentines(_Item); // wrapper for "Scheduled Need (Qty.)" (BC 17 or earlier) or "Qty. on Component Lines" (BC18 and newer)

        ItemIsIncluded := _Item.Inventory > 0;
        OnLookupOnLocateItem_OnIncludeItem(_Location, _Item, _ItemVariant, ItemIsIncluded);

        if ItemIsIncluded then begin
            _LookupResponse.Create();
            SetFromLookupLocateItem_Item(_Location, _Item, _ItemVariant, _LookupResponse);
            _LookupResponse.Save();
        end;
    end;


    /// <summary>
    /// Lookup which Labels (Cloud Print) and Reports (Report Print) are available to print
    /// </summary>
    local procedure LookupPrint(var _RequestValues: Record "MOB NS Request Element"; var _LookupResponse: Record "MOB NS WhseInquery Element"; var _ReturnRegistrationTypeTracking: Text)
    var
        MobPrintSetup: Record "MOB Print Setup";
        TempLabelTemplate: Record "MOB Label-Template" temporary;
        TempMobReport: Record "MOB Report" temporary;
        TempRequiredSteps: Record "MOB Steps Element" temporary;
        MobPrint: Codeunit "MOB Print";
        MobReportPrintManagement: Codeunit "MOB Report Print Management";
        MobReportPrintLookup: Codeunit "MOB Report Print Lookup";
        SourceRecRef: RecordRef;
        LocationCode: Text;
        ReportPrintEnabled: Boolean;
    begin
        // This lookup must serve Printing from OrderLines and Printing from Main Menu  
        if not MobPrintSetup.Get() then
            MobPrintSetup.Init();
        ReportPrintEnabled := MobReportPrintManagement.IsEnabled();

        if (MobPrintSetup.Enabled = false) and (ReportPrintEnabled = false) then
            Error(PleaseSetupPrintErr);

        // Location
        LocationCode := _RequestValues.Get_Location();
        _ReturnRegistrationTypeTracking := LocationCode;

        // ReferenceID and Scanned ItemNumber
        case true of
            // ReferenceID sent out on order lines to identify the context which this page is called from
            _RequestValues.Get_ReferenceID() <> '':
                MobToolbox.ReferenceIDText2RecRef(_RequestValues.Get_ReferenceID(), SourceRecRef);

            // Identify Item, Item Reference or Item Cross Reference
            _RequestValues.Get_ItemNumber() <> '':
                MobItemReferenceMgt.SearchItemReference(_RequestValues.Get_ItemNumber(), SourceRecRef, true);
        end;


        // Find relevant label-templates
        if MobPrintSetup.Enabled then begin
            MobPrint.GetRelevantTemplates(TempLabelTemplate, LocationCode);

            // Add Label-templates to response
            if TempLabelTemplate.FindSet() then
                repeat
                    // Get steps, if label can be used
                    if MobPrint.GetStepsForTemplate(TempLabelTemplate, _RequestValues, SourceRecRef, TempRequiredSteps) then begin
                        // Add label to response
                        _LookupResponse.Create();
                        SetFromLookupPrintLabel(TempLabelTemplate, _LookupResponse, SourceRecRef, TempRequiredSteps);
                        _LookupResponse.Save();
                    end;
                until TempLabelTemplate.Next() = 0;
        end;

        // Find relevant reports
        if ReportPrintEnabled then begin
            MobReportPrintManagement.GetReportsAllowedForRequest(_RequestValues, TempMobReport);

            // Add reports to response
            if TempMobReport.FindSet() then
                repeat
                    // Get steps, if label can be used
                    if MobReportPrintLookup.CreateStepsForReport(TempMobReport, _RequestValues, SourceRecRef, TempRequiredSteps) then begin
                        // Add label to response
                        _LookupResponse.Create();
                        MobReportPrintLookup.SetFromLookupReport(TempMobReport, SourceRecRef, _LookupResponse, TempRequiredSteps);
                        _LookupResponse.Save();
                    end;
                until TempMobReport.Next() = 0;
        end
    end;

    /// <summary>
    /// Lookup attached images
    /// </summary>
    local procedure LookupAttachments(var _RequestValues: Record "MOB NS Request Element"; var _LookupResponse: Record "MOB NS WhseInquery Element")
    var
        MobMediaQueue: Record "MOB WMS Media Queue";
        SourceRecRef: RecordRef;
    begin
        // Read Request
        // ReferenceID sent out on order lines to identify the context which this page is called from
        MobToolbox.ReferenceIDText2RecRef(_RequestValues.GetValue('ReferenceID', true), SourceRecRef);

        // Find images attached to this RecordId
        MobMediaQueue.SetRange("Record ID", SourceRecRef.RecordId());
        if MobMediaQueue.FindSet() then
            repeat
                // Add to reponse
                _LookupResponse.Create();
                SetFromLookupAttachments(MobMediaQueue, _LookupResponse);
                _LookupResponse.Save();
            until MobMediaQueue.Next() = 0;
    end;

    local procedure LookupPostShipment(var _RequestValues: Record "MOB NS Request Element"; var _LookupResponse: Record "MOB NS WhseInquery Element"; var _ReturnRegistrationTypeTracking: Text)
    var
        Location: Record Location;
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        ShipmentNo: Code[20];
        LocationCode: Text;
        IncludeInLookup: Boolean;
    begin
        // Read Request
        ShipmentNo := _RequestValues.GetValue('ShipmentNoFilter', true);
        LocationCode := _RequestValues.GetValue('LocationFilter', true);

        _ReturnRegistrationTypeTracking := ShipmentNo;

        // Only search the locations this user has been assigned
        if LocationCode = 'All' then
            Location.SetFilter(Code, MobWmsToolbox.GetLocationFilter(MobDocQueue."Mobile User ID"))
        else
            Location.SetRange(Code, LocationCode);

        if Location.FindSet() then
            repeat
                Clear(WarehouseShipmentHeader);

                if ShipmentNo <> '' then
                    WarehouseShipmentHeader.SetRange("No.", ShipmentNo);

                WarehouseShipmentHeader.SetRange("Location Code", Location.Code);
                WarehouseShipmentHeader.SetRange(Status, WarehouseShipmentHeader.Status::Released);

                Clear(WarehouseShipmentLine);
                WarehouseShipmentLine.SetFilter("Qty. to Ship", '>0');
                OnLookupOnPostShipment_OnSetFilterWarehouseShipment(_RequestValues, WarehouseShipmentHeader, WarehouseShipmentLine);

                if WarehouseShipmentHeader.FindSet() then
                    repeat
                        WarehouseShipmentLine.SetRange("No.", WarehouseShipmentHeader."No.");
                        IncludeInLookup := not WarehouseShipmentLine.IsEmpty();
                        OnLookupOnPostShipment_OnIncludeWarehouseShipment(WarehouseShipmentHeader, IncludeInLookup);

                        if IncludeInLookup then begin
                            // Populate LookupResponse buffer element for <LookupResponse>
                            _LookupResponse.Create();
                            SetFromLookupPostShipment(Location, WarehouseShipmentHeader, _LookupResponse);
                            _LookupResponse.Save();
                        end;
                    until WarehouseShipmentHeader.Next() = 0;
            until Location.Next() = 0;
    end;

    //
    // ------- RESPONSE -------
    //

    procedure AddLookupResponseElements(_LookupType: Text; var _XmlResponseData: XmlNode; var _LookupResponseElement: Record "MOB NS WhseInquery Element")
    var
        CursorMgt: Codeunit "MOB Cursor Management";
        XmlMgt: Codeunit "MOB XML Management";
    begin
        // store current cursor and sorting, then set default sorting to be used for the export
        CursorMgt.Backup(_LookupResponseElement);

        SetCurrentKeyOnAnyLookupType(_LookupType, _LookupResponseElement);
        XmlMgt.AddNsWhseInquiryModelLookupResponseElements(_XmlResponseData, _LookupResponseElement);

        // restore cursor and sorting
        CursorMgt.Restore(_LookupResponseElement);
    end;

    local procedure SetCurrentKeyOnAnyLookupType(_LookupType: Text; var _LookupResponseElement: Record "MOB NS WhseInquery Element")
    var
        TempLookupResponseElementView: Record "MOB NS WhseInquery Element" temporary;
    begin
        // set sorting to be used for the export
        _LookupResponseElement.SetCurrentKey("Sorting1 (internal)", "Sorting2 (internal)", "Sorting3 (internal)", "Sorting4 (internal)", "Sorting5 (internal)");

        TempLookupResponseElementView.SetView(_LookupResponseElement.GetView());
        OnLookupOnAnyLookupType_OnAfterSetCurrentKey(_LookupType, TempLookupResponseElementView);
        _LookupResponseElement.SetView(TempLookupResponseElementView.GetView());
    end;

    local procedure SetFromLookupBinContent(_BinContent: Record "Bin Content"; _TempEntrySummary: Record "Entry Summary"; var _LookupResponse: Record "MOB NS WhseInquery Element")
    var
        MobWmsMedia: Codeunit "MOB WMS Media";
    begin
        _LookupResponse.Init();

        _LookupResponse.Set_Location(_BinContent."Location Code");
        _LookupResponse.Set_ItemNumber(_BinContent."Item No.");
        _LookupResponse.Set_Number(_BinContent."Item No."); // Number is required for UnplannedMove Advanced
        _LookupResponse.Set_Variant(_BinContent."Variant Code");
        _LookupResponse.Set_Barcode('');

        _LookupResponse.SetTracking(_TempEntrySummary);
        _LookupResponse.Set_ExpirationDate(_TempEntrySummary."Expiration Date");

        _LookupResponse.SetDisplayTracking(_TempEntrySummary);
        _LookupResponse.Set_DisplayExpirationDate(_TempEntrySummary."Expiration Date" <> 0D, MobWmsLanguage.GetMessage('EXP_DATE_LABEL') + ': ' + MobWmsToolbox.Date2TextAsDisplayFormat(_TempEntrySummary."Expiration Date"), '');

        _LookupResponse.Set_Bin(_BinContent."Bin Code");
        _LookupResponse.Set_Quantity(MobWmsToolbox.Decimal2TextAsDisplayFormat(_BinContent.Quantity));
        _LookupResponse.Set_UoM(_BinContent."Unit of Measure Code");

        _LookupResponse.Set_DisplayLine1(_BinContent."Item No.");
        _LookupResponse.Set_DisplayLine2(MobWmsToolbox.GetItemDescriptions(_BinContent."Item No.", _BinContent."Variant Code"));
        _LookupResponse.Set_DisplayLine3(_BinContent."Variant Code" <> '', MobWmsLanguage.GetMessage('VARIANT_LABEL') + ': ' + _BinContent."Variant Code", '');
        _LookupResponse.Set_DisplayLine4(MobWmsLanguage.GetMessage('UOM_LABEL') + ': ' + _BinContent."Unit of Measure Code");
        _LookupResponse.Set_DisplayLine5('');

        _LookupResponse.Set_ItemImageID(MobWmsMedia.GetItemImageID(_LookupResponse.Get_ItemNumber()));
        _LookupResponse.Set_ReferenceID(_BinContent);

        OnLookupOnBinContent_OnAfterSetFromBinContent(_BinContent, _LookupResponse);
    end;

    procedure SetFromLookupSubstituteItem(_ItemSubstitution: Record "Item Substitution"; var _LookupResponse: Record "MOB NS WhseInquery Element")
    var
        MobWmsMedia: Codeunit "MOB WMS Media";
    begin
        _LookupResponse.Init();

        _LookupResponse.Set_ItemNumber(_ItemSubstitution."Substitute No.");
        _LookupResponse.Set_Variant(_ItemSubstitution."Variant Code");
        _LookupResponse.Set_Barcode('');

        _LookupResponse.Set_SerialNumber('');
        _LookupResponse.Set_LotNumber('');
        _LookupResponse.Set_Bin('');
        _LookupResponse.Set_Quantity(1);
        _LookupResponse.Set_UoM('');

        _LookupResponse.Set_DisplayLine1(_LookupResponse.Get_ItemNumber());
        _LookupResponse.Set_DisplayLine2(MobWmsToolbox.GetItemDescriptions(_ItemSubstitution."Substitute No.", _ItemSubstitution."Substitute Variant Code"));
        _LookupResponse.Set_DisplayLine3('');
        _LookupResponse.Set_DisplayLine4(_ItemSubstitution."Substitute Variant Code" <> '', MobWmsLanguage.GetMessage('VARIANT_LABEL') + ': ' + _ItemSubstitution."Substitute Variant Code", '');
        _LookupResponse.Set_DisplayLine5('');

        _LookupResponse.Set_ItemImageID(MobWmsMedia.GetItemImageID(_LookupResponse.Get_ItemNumber()));
        _LookupResponse.Set_ReferenceID(_ItemSubstitution);

        OnLookupOnSubstituteItems_OnAfterSetFromItemSubstitution(_ItemSubstitution, _LookupResponse);
    end;

    local procedure SetFromLookupLocateItem_BinContent(_Location: Record Location; var _BinContent: Record "Bin Content"; _MobTrackingSetup: Record "MOB Tracking Setup"; _ExpirationDate: Date; var _LookupResponse: Record "MOB NS WhseInquery Element")
    var
        MobWmsMedia: Codeunit "MOB WMS Media";
        DisplayLine2List: List of [Text];
    begin
        _LookupResponse.Init();

        _LookupResponse.Set_Location(_BinContent."Location Code");
        _LookupResponse.Set_ItemNumber(_BinContent."Item No.");
        _LookupResponse.Set_Number(_BinContent."Item No."); // Number is required for UnplannedMove Advanced
        _LookupResponse.Set_Variant(_BinContent."Variant Code");
        _LookupResponse.Set_Barcode('');

        _LookupResponse.SetTracking(_MobTrackingSetup);
        _LookupResponse.Set_ExpirationDate(_ExpirationDate);

        _LookupResponse.SetDisplayTracking(_MobTrackingSetup);
        _LookupResponse.Set_DisplayExpirationDate(_ExpirationDate <> 0D, MobWmsLanguage.GetMessage('EXP_DATE_LABEL') + ': ' + MobWmsToolbox.Date2TextAsDisplayFormat(_ExpirationDate), '');

        _LookupResponse.Set_Bin(_BinContent."Bin Code");

        _LookupResponse.Set_Quantity(MobWmsToolbox.Decimal2TextAsDisplayFormat(_BinContent.CalcQtyAvailToTakeUOM()));

        _LookupResponse.Set_UoM(_BinContent."Unit of Measure Code");

        _LookupResponse.Set_DisplayLine1(_BinContent."Bin Code");

        // DisplayLine2 = Item No, Descriptions and Location
        DisplayLine2List.Add(_BinContent."Item No.");
        DisplayLine2List.Add(MobWmsToolbox.GetItemDescription(_BinContent."Item No.", _BinContent."Variant Code"));
        if _Location.Name <> '' then
            DisplayLine2List.Add(_Location.Name)
        else
            DisplayLine2List.Add(_Location.Code);
        _LookupResponse.Set_DisplayLine2(MobWmsToolbox.List2TextLn(DisplayLine2List, 999));

        _LookupResponse.Set_DisplayLine3(MobWmsLanguage.GetMessage('UOM_LABEL') + ': ' + _BinContent."Unit of Measure Code");
        _LookupResponse.Set_DisplayLine4(_BinContent."Variant Code" <> '', MobWmsLanguage.GetMessage('VARIANT_LABEL') + ': ' + _BinContent."Variant Code", '');
        _LookupResponse.Set_DisplayLine5('');

        _LookupResponse.Set_ExtraInfo1(MobWmsToolbox.Decimal2TextAsDisplayFormat(_BinContent.Quantity));
        _LookupResponse.Set_ExtraInfo2('');
        _LookupResponse.Set_ExtraInfo3('');

        _LookupResponse.Set_ItemImageID(MobWmsMedia.GetItemImageID(_LookupResponse.Get_ItemNumber()));
        _LookupResponse.Set_ReferenceID(_BinContent);

        OnLookupOnLocateItem_OnAfterSetFromBinContent(_BinContent, _LookupResponse);
    end;

    local procedure SetFromLookupLocateItem_Item(_Location: Record Location; _Item: Record Item; _ItemVariant: Record "Item Variant"; var _LookupResponse: Record "MOB NS WhseInquery Element")
    var
        MobCommonMgt: Codeunit "MOB Common Mgt.";
        MobWmsMedia: Codeunit "MOB WMS Media";
        AvailableQuantity: Decimal;
        DisplayLine2List: List of [Text];
    begin
        // Calculate AvailableQuantity : assume flowfields has been calculated already including correct filters

        // Item
        // GetQtyOnComponentLines is wrapper for "Scheduled Need (Qty.)" (BC 17 or earlier) or "Qty. on Component Lines" (BC18 and newer)
        AvailableQuantity :=
            _Item.Inventory - _Item."Qty. on Sales Order" - MobCommonMgt.Item_GetQtyOnComponentines(_Item) - _Item."Trans. Ord. Shipment (Qty.)" - _Item."Qty. on Service Order";

        _LookupResponse.Init();

        _LookupResponse.Set_Location(_Location.Code);
        _LookupResponse.Set_ItemNumber(_Item."No.");
        _LookupResponse.Set_Variant(_ItemVariant.Code);
        _LookupResponse.Set_Barcode('');
        _LookupResponse.Set_SerialNumber('');
        _LookupResponse.Set_LotNumber('');
        _LookupResponse.Set_Bin('');
        _LookupResponse.Set_Quantity(MobWmsToolbox.Decimal2TextAsDisplayFormat(AvailableQuantity));
        _LookupResponse.Set_UoM(_Item."Base Unit of Measure");

        _LookupResponse.Set_DisplayLine1(_Item."No.");

        // DisplayLine2 = Description and Location
        DisplayLine2List.Add(MobWmsToolbox.GetItemDescription(_Item."No.", _ItemVariant."Code")); // Using _Item."No." as _ItemVariant may be empty parameter
        if _Location.Name <> '' then
            DisplayLine2List.Add(_Location.Name)
        else
            DisplayLine2List.Add(_Location.Code);
        _LookupResponse.Set_DisplayLine2(MobWmsToolbox.List2TextLn(DisplayLine2List, 999));

        _LookupResponse.Set_DisplayLine3(MobWmsLanguage.GetMessage('UOM_LABEL') + ': ' + _Item."Base Unit of Measure");
        _LookupResponse.Set_DisplayLine4(_ItemVariant.Code <> '', MobWmsLanguage.GetMessage('VARIANT_LABEL') + ': ' + _ItemVariant.Code, '');
        _LookupResponse.Set_DisplayLine5('');

        _LookupResponse.Set_ExtraInfo1(MobWmsToolbox.Decimal2TextAsDisplayFormat(_Item.Inventory));
        _LookupResponse.Set_ExtraInfo2('');
        _LookupResponse.Set_ExtraInfo3('');

        _LookupResponse.Set_ItemImageID(MobWmsMedia.GetItemImageID(_LookupResponse.Get_ItemNumber()));
        if _ItemVariant."Item No." <> '' then
            _LookupResponse.Set_ReferenceID(_ItemVariant)
        else
            _LookupResponse.Set_ReferenceID(_Item);

        OnLookupOnLocateItem_OnAfterSetFromItem(_Location, _Item, _ItemVariant, _LookupResponse);
    end;

    local procedure SetFromLookupPostShipment(_Location: Record Location; _WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var _LookupResponse: Record "MOB NS WhseInquery Element")
    var
        TempHeaderSteps: Record "MOB Steps Element" temporary;
        HtmlTable: Text;
    begin
        _LookupResponse.Init();

        _LookupResponse.Set_Location(_Location.Code);
        _LookupResponse.Set_ShipmentNo(_WarehouseShipmentHeader."No.");
        _LookupResponse.Set_Barcode(_WarehouseShipmentHeader."No.");

        _LookupResponse.Set_DisplayLine1(_WarehouseShipmentHeader."No.");
        _LookupResponse.Set_DisplayLine2(MobWmsLanguage.GetMessage('LOCATION') + ': ' + _Location.Name);
        _LookupResponse.Set_DisplayLine3(MobWmsLanguage.GetMessage('SHIPMT_DATE') + ': ' + MobWmsToolbox.Date2TextAsDisplayFormat(_WarehouseShipmentHeader."Shipment Date"));
        _LookupResponse.Set_DisplayLine4(Format(_WarehouseShipmentHeader."Document Status"));

        _LookupResponse.Set_ReferenceID(_WarehouseShipmentHeader);

        // Infostep displaying the Shipment Lines
        HtmlTable := GetWhseShipmentLinesAsHtmlTable(_WarehouseShipmentHeader);
        TempHeaderSteps.Create_InformationStep(1, 'InfoStep', MobWmsLanguage.GetMessage('POST_SHIPMENT'), '', HtmlTable);

        //
        // Events
        //
        TempHeaderSteps.SetMustCallCreateNext(true);
        OnLookupOnPostShipment_OnAddSteps(_WarehouseShipmentHeader, TempHeaderSteps);
        TempHeaderSteps.SetMustCallCreateNext(false);
        if TempHeaderSteps.FindSet() then
            repeat
                OnLookupOnPostShipment_OnAfterAddStep(_WarehouseShipmentHeader, TempHeaderSteps);
            until TempHeaderSteps.Next() = 0;
        _LookupResponse.SetRegistrationCollector(TempHeaderSteps);

        OnLookupOnPostShipment_OnAfterSetFromWarehouseShipmentHeader(_WarehouseShipmentHeader, _LookupResponse);
    end;

    /// <summary>
    /// Create a Html table of Shipment Lines
    /// </summary>
    local procedure GetWhseShipmentLinesAsHtmlTable(_WarehouseShipmentHeader: Record "Warehouse Shipment Header") HtmlTable: Text
    var
        WhseShipmentLine: Record "Warehouse Shipment Line";
        MobHtmlMgt: Codeunit "MOB HTML Management";
    begin

        MobHtmlMgt.BeginFourColumnTable(HtmlTable,
            WhseShipmentLine.FieldCaption("Item No."),                  // Column A Header
            '',                                                         // Column B Header
            WhseShipmentLine.FieldCaption("Qty. to Ship"),              // Column C Header
            'UoM');                                                     // Column D Header

        WhseShipmentLine.Reset();
        WhseShipmentLine.SetRange("No.", _WarehouseShipmentHeader."No.");
        WhseShipmentLine.SetFilter("Qty. to Ship", '>0');
        if WhseShipmentLine.FindSet() then
            repeat
                // Available qty. to take per Unit of Measure                
                MobHtmlMgt.AddRowToFourColumnTable(HtmlTable,
                                                    WhseShipmentLine."Item No.",                                             // Column A Text
                                                    '',                                                                      // Column B Text
                                                    MobWmsToolbox.Decimal2TextAsDisplayFormat(WhseShipmentLine."Qty. to Ship", true),    // Column C Text
                                                    Format(WhseShipmentLine."Unit of Measure Code"));                        // Column D Text
            until WhseShipmentLine.Next() = 0
        else
            // Qty was zero
            MobHtmlMgt.AddRowToFourColumnTable(HtmlTable, 'n/a', '', ' ', ' ');
    end;

    /// <summary>
    /// Set lookup display values of a Label-Template
    /// </summary>
    local procedure SetFromLookupPrintLabel(_LabelTemplate: Record "MOB Label-Template"; var _LookupResponse: Record "MOB NS WhseInquery Element"; _SourceRecRef: RecordRef; var _RequiredSteps: Record "MOB Steps Element")
    var
        TempAdditionalValues: Record "MOB NS BaseDataModel Element" temporary;
    begin
        // Display values
        _LookupResponse.Init();
        _LookupResponse.Set_Location('');
        _LookupResponse.Set_DisplayLine1(_LabelTemplate."Display Name" <> '', _LabelTemplate."Display Name", _LabelTemplate.Name); // Fallback to "Name"
        _LookupResponse.Set_ReferenceID(_LabelTemplate);

        // Events to add and modify _RequiredSteps are being handled in MobPrint.GetStepsForTemplate()

        // Required steps for this Label
        if not _RequiredSteps.IsEmpty() then begin
            TempAdditionalValues.Create();
            TempAdditionalValues.SetValue('LabelTemplate', _LabelTemplate.Name);
            TempAdditionalValues.Save();
            _LookupResponse.SetRegistrationCollector(_RequiredSteps, TempAdditionalValues);
        end;

        // LookupType is PrintLabelTemplate but event named accordingly to existing MobPrint events
        OnLookupOnPrintLabel_OnAfterSetFromLabelTemplate(_LabelTemplate, _SourceRecRef, _LookupResponse);
    end;

    /// <summary>
    /// Set lookup display values of an Attachment
    /// </summary>
    local procedure SetFromLookupAttachments(_MobMediaQueue: Record "MOB WMS Media Queue"; var _LookupResponse: Record "MOB NS WhseInquery Element")
    var
        MobWmsMedia: Codeunit "MOB WMS Media";
    begin
        _LookupResponse.Init();

        _LookupResponse.Set_DisplayLine1(_MobMediaQueue.Note);
        _LookupResponse.Set_DisplayLine2(MobWmsToolbox.Date2TextAsDisplayFormat(_MobMediaQueue."Created Date") + ' ' + Format(_MobMediaQueue."Created Time"));

        // Tells mobile which Attached Image/mediaID to request, when streaming this image
        _LookupResponse.Set_ItemImageID(MobWmsMedia.CreateAttachedImageID(_MobMediaQueue));

        _LookupResponse.Set_ReferenceID(_MobMediaQueue);
    end;

    //
    // ------- Constants -------
    //
    procedure "CONST::BinContent"(): Text
    begin
        exit(BIN_CONTENT_Txt);
    end;

    procedure "CONST::SubstituteItems"(): Text
    begin
        exit(SUBSTITUTE_ITEMS_Txt);
    end;

    procedure "CONST::LocateItem"(): Text
    begin
        exit(LOCATE_ITEM_Txt);
    end;

    procedure "CONST::PrintLabelTemplate"(): Text
    begin
        exit(PRINT_LABELTEMPLATE_Txt);
    end;

    procedure "CONST::PostShipment"(): Text
    begin
        exit(POST_SHIPMENT_Txt);
    end;

    procedure "CONST::ProdOutput"(): Text
    begin
        exit(PROD_OUTPUT_Txt);
    end;

    procedure "CONST::SubstituteProdOrderComponent"(): Text
    begin
        exit(SUBSTITUTE_PROD_ORDER_COMPONENT_Txt);
    end;

    procedure "CONST::Attachments"(): Text
    begin
        exit(ATTACHMENTS_Txt);
    end;

    procedure "CONST::History"(): Text
    begin
        exit(HISTORY_Txt);
    end;

    procedure "CONST::LicensePlate"(): Text
    begin
        exit(LicensePlate_Txt);
    end;

    procedure "CONST::PutAwayLicensePlate"(): Text
    begin
        exit(PutAwayLicensePlate_Txt);
    end;

    // ------- IntegrationEvents: OnLookup -------
    //

    [IntegrationEvent(false, false)]
    local procedure OnLookupOnAnyLookupType_OnAfterSetCurrentKey(_LookupType: Text; var _LookupResponseElementView: Record "MOB NS WhseInquery Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupOnCustomLookupType(_MessageId: Guid; _LookupType: Text; var _RequestValues: Record "MOB NS Request Element"; var _LookupResponseElement: Record "MOB NS WhseInquery Element"; var _XmlResultDoc: XmlDocument; var _RegistrationTypeTracking: Text; var _IsHandled: Boolean)
    begin
        // Parameter _XmlResultDoc only included for backwards compatibility
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupOnCustomLookupTypeAsXml(var _XmlRequestDoc: XmlDocument; _LookupType: Text[50]; var _XmlResultDoc: XmlDocument; var _IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupOnBinContent_OnSetFilterBinContent(var _RequestValues: Record "MOB NS Request Element"; var _BinContent: Record "Bin Content")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupOnBinContent_OnIncludeBinContent(_BinContent: Record "Bin Content"; var _IncludeInLookup: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupOnBinContent_OnAfterSetFromBinContent(_BinContent: Record "Bin Content"; var _LookupResponseElement: Record "MOB NS WhseInquery Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupOnSubstituteItems_OnAfterSetFromItemSubstitution(_ItemSubstitution: Record "Item Substitution"; var _LookupResponseElement: Record "MOB NS WhseInquery Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupOnLocateItem_OnSetFilterBinContent(var _RequestValues: Record "MOB NS Request Element"; var _BinContent: Record "Bin Content")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupOnLocateItem_OnIncludeBinContent(_BinContent: Record "Bin Content"; var _IncludeInLookup: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupOnLocateItem_OnIncludeItem(_Location: Record Location; _Item: Record Item; _ItemVariant: Record "Item Variant"; var _IncludeInLookup: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupOnLocateItem_OnAfterSetFromBinContent(_BinContent: Record "Bin Content"; var _LookupResponseElement: Record "MOB NS WhseInquery Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupOnLocateItem_OnAfterSetFromItem(_Location: Record Location; _Item: Record Item; _ItemVariant: Record "Item Variant"; var _LookupResponseElement: Record "MOB NS WhseInquery Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupOnPrintLabel_OnAfterSetFromLabelTemplate(_LabelTemplate: Record "MOB Label-Template"; _SourceRecRef: RecordRef; var _LookupResponseElement: Record "MOB NS WhseInquery Element")
    begin
    end;

    // OnLookupOnPrintLabel_OnAddStepsForTemplate: (see MOB Print)
    // OnLookupOnPrintLabel_OnAfterAddStepForTemplate (see MOB Print)

    [IntegrationEvent(false, false)]
    local procedure OnLookupOnPostShipment_OnSetFilterWarehouseShipment(var _RequestValues: Record "MOB NS Request Element"; var _WhseShipmentHeader: Record "Warehouse Shipment Header"; var _WhseShipmentLine: Record "Warehouse Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupOnPostShipment_OnIncludeWarehouseShipment(_WhseShipmentHeader: Record "Warehouse Shipment Header"; var _IncludeInLookup: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupOnPostShipment_OnAfterSetFromWarehouseShipmentHeader(_WhseShipmentHeader: Record "Warehouse Shipment Header"; var _LookupResponseElement: Record "MOB NS WhseInquery Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupOnPostShipment_OnAddSteps(_WhseShipmentHeader: Record "Warehouse Shipment Header"; var _Steps: Record "MOB Steps Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupOnPostShipment_OnAfterAddStep(_WhseShipmentHeader: Record "Warehouse Shipment Header"; var _Step: Record "MOB Steps Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnLookupOnProdOutput_OnIncludeProductionOutput(var _RequestValues: Record "MOB NS Request Element"; _ProdOrderLine: Record "Prod. Order Line"; _ProdOrderRtngLine: Record "Prod. Order Routing Line"; var _IncludeInOrderLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnLookupOnProdOutput_OnAfterSetFromProductionOutput(_ProdOrderLine: Record "Prod. Order Line"; _ProdOrderRtngLine: Record "Prod. Order Routing Line"; _TrackingSpecification: Record "Tracking Specification"; var _LookupResponseElement: Record "MOB NS WhseInquery Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnLookupOnProdOutput_OnSetFilterProdOrderRoutingLine(var _RequestValues: Record "MOB NS Request Element"; var _ProdOrderRtngLine: Record "Prod. Order Routing Line")
    begin
    end;
}
