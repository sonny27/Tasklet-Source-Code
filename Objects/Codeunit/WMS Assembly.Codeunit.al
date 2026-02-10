codeunit 81405 "MOB WMS Assembly"
{
    Access = Public;
    TableNo = "MOB Document Queue";

    var
        MobSessionData: Codeunit "MOB SessionData";

    trigger OnRun()
    var
        MobDocQueue: Record "MOB Document Queue";
        XmlResponseDoc: XmlDocument;
    begin
        MobDocQueue := Rec;

        case Rec."Document Type" of

            // Order headers
            'GetAssemblyOrders':
                GetAssemblyOrders(MobDocQueue, XmlResponseDoc);

            // Order lines
            'GetAssemblyOrderLines':
                GetAssemblyOrderLines(MobDocQueue, XmlResponseDoc);

            // Posting
            'PostAssemblyOrder':
                PostAssemblyOrder(MobDocQueue, XmlResponseDoc);

            else
                Error(MobWmsLanguage.GetMessage('NO_DOC_HANDLER'), Rec."Document Type");
        end;

        // Store the result in the queue and update the status
        MobToolbox.UpdateResult(Rec, XmlResponseDoc);
    end;

    procedure RunGetRegistrationConfiguration(_MobDocQueue: Record "MOB Document Queue"; _RegistrationType: Text; var _HeaderFilter: Record "MOB NS Request Element"; var _Steps: Record "MOB Steps Element"; var _ReturnRegistrationTypeTracking: Text)
    begin
        case _RegistrationType of
            MobWmsToolbox."CONST::CreateAssemblyOrder"():
                _ReturnRegistrationTypeTracking := CreateAssemblyOrderRegColConf(_HeaderFilter, _Steps);
            MobWmsToolbox."CONST::AdjustQtyToAssemble"():
                _ReturnRegistrationTypeTracking := AdjustQtyToAssembleRegColConf(_HeaderFilter, _Steps);
            else
                Error(MobWmsLanguage.GetMessage('NO_DOC_HANDLER'), GetRegistrationConfigurationTok + _RegistrationType);
        end;
    end;

    procedure RunPostAdhocRegistration(_RegistrationType: Text; var _RequestValues: Record "MOB NS Request Element"; var _SuccessMessage: Text; var _ReturnRegistrationTypeTracking: Text)
    begin
        case _RegistrationType of
            MobWmsToolbox."CONST::CreateAssemblyOrder"():
                CreateAssemblyOrder(_RequestValues, _SuccessMessage, _ReturnRegistrationTypeTracking);
            MobWmsToolbox."CONST::AdjustQtyToAssemble"():
                AdjustQtyToAssemble(_RequestValues, _SuccessMessage, _ReturnRegistrationTypeTracking);
            else
                Error(MobWmsLanguage.GetMessage('NO_DOC_HANDLER'), PostAdhocRegistrationTok + _RegistrationType);
        end;
    end;

    var
        MobRequestMgt: Codeunit "MOB NS Request Management";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
        MobToolbox: Codeunit "MOB Toolbox";
        MobItemReferenceMgt: Codeunit "MOB Item Reference Mgt.";
        MUST_BE_TEMPORARY_Err: Label 'Internal error: %1 must be a temporary record.', Locked = true;
        PostAdhocRegistrationTok: Label 'PostAdhocRegistration.', Locked = true;
        GetRegistrationConfigurationTok: Label 'GetRegistrationConfiguration.', Locked = true;

    //
    // ------- GetRegistrationConfiguration -------
    // 
    local procedure CreateAssemblyOrderRegColConf(var _HeaderValues: Record "MOB NS Request Element"; var _Steps: Record "MOB Steps Element") _ReturnRegistrationTypeTracking: Text
    begin
        // Set the tracking value displayed in the document queue
        _ReturnRegistrationTypeTracking := _HeaderValues.Get_ItemNumber();

        CreateStepsForCreateAssemblyOrder(_HeaderValues, _Steps);
    end;

    local procedure CreateStepsForCreateAssemblyOrder(var _HeaderValues: Record "MOB NS Request Element"; var _Steps: Record "MOB Steps Element")
    var
        MobSetup: Record "MOB Setup";
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ItemNumber: Code[20];
        VariantCode: Code[10];
        UnitOfMeasureCode: Code[10];
    begin
        ItemNumber := MobItemReferenceMgt.SearchItemReference(_HeaderValues.Get_ItemNumber(), VariantCode, UnitOfMeasureCode);

        MobSetup.Get();
        Item.Get(ItemNumber);

        if VariantCode = '' then begin
            ItemVariant.Reset();
            ItemVariant.SetRange("Item No.", Item."No.");
            if not ItemVariant.IsEmpty() then
                _Steps.Create_ListStep_Variant(10, Item."No.");
        end;

        if (not MobSetup."Use Base Unit of Measure") and (UnitOfMeasureCode = '') then
            _Steps.Create_ListStep_UoM(20, Item."No.");

        _Steps.Create_DecimalStep_Quantity(30, Item."No.");
        _Steps.Set_name('QuantityToAssemble');
        _Steps.Set_minValue(1);
        // Show UoM in Quantity help
        if MobSetup."Use Base Unit of Measure" then
            _Steps.Set_helpLabel(MobWmsLanguage.GetMessage('UOM_LABEL') + ': ' + Item."Base Unit of Measure")
        else
            if UnitOfMeasureCode <> '' then
                _Steps.Set_helpLabel(MobWmsLanguage.GetMessage('UOM_LABEL') + ': ' + UnitOfMeasureCode);
    end;

    local procedure AdjustQtyToAssembleRegColConf(var _HeaderValues: Record "MOB NS Request Element"; var _Steps: Record "MOB Steps Element") _ReturnRegistrationTypeTracking: Text
    begin
        // Set the tracking value displayed in the document queue        
        _ReturnRegistrationTypeTracking := _HeaderValues.Get_OrderBackendID(true);

        CreateStepsForAdjustQtyToAssemble(_HeaderValues, _Steps);
    end;

    local procedure CreateStepsForAdjustQtyToAssemble(var _HeaderValues: Record "MOB NS Request Element"; var _Steps: Record "MOB Steps Element")
    var
        MobSetup: Record "MOB Setup";
        AssemblyHeader: Record "Assembly Header";
        Item: Record Item;
        AssemblyDocNo: Code[20];
    begin
        Evaluate(AssemblyDocNo, _HeaderValues.Get_OrderBackendID(true));

        MobSetup.Get();
        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, AssemblyDocNo);
        AssemblyHeader.TestField("Item No.");
        Item.Get(AssemblyHeader."Item No.");

        _Steps.Create_DecimalStep(10, 'QuantityToAssemble');
        _Steps.Set_header(MobWmsLanguage.GetMessage('ITEM') + ' ' + Item."No." + ' - ' + MobWmsLanguage.GetMessage('ENTER_QTY'));
        _Steps.Set_label(MobWmsLanguage.GetMessage('QTY_LABEL') + ':');
        _Steps.Set_eanAi(MobToolbox.GetQuantityGS1Ai());
        _Steps.Set_autoForwardAfterScan(true);
        _Steps.Set_optional(false);
        _Steps.Set_visible(true);
        _Steps.Set_labelWidth_WindowsMobile(100);
        _Steps.Set_minValue(0.0000000001);
        _Steps.Set_performCalculation(true);
        // Show UoM in QuantityToAssemble help
        if MobSetup."Use Base Unit of Measure" then begin
            _Steps.Set_defaultValue(AssemblyHeader."Quantity to Assemble (Base)");
            _Steps.Set_helpLabel(MobWmsLanguage.GetMessage('UOM_LABEL') + ': ' + Item."Base Unit of Measure")
        end else begin
            _Steps.Set_defaultValue(AssemblyHeader."Quantity to Assemble");
            _Steps.Set_helpLabel(MobWmsLanguage.GetMessage('UOM_LABEL') + ': ' + AssemblyHeader."Unit of Measure Code");
        end;
    end;

    //
    // ------- PostAdhocRegistration -------
    //
    local procedure CreateAssemblyOrder(var _RequestValues: Record "MOB NS Request Element"; var _SuccessMessage: Text; var _ReturnRegistrationTypeTracking: Text)
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        ReleaseAssemblyDocument: Codeunit "Release Assembly Document";
        MobAvailbility: Codeunit "MOB Availability";
        LocationCode: Code[20];
        ScannedBarcode: Code[50];
        ItemNumber: Code[20];
        VariantCode: Code[10];
        UoMCode: Code[10];
        Qty: Decimal;
        OrderAbleToAssemble: Decimal;
        EarliestDueDate: Date;
    begin
        // Parse values from Request
        LocationCode := _RequestValues.Get_Location(true);
        ScannedBarcode := _RequestValues.Get_ItemNumber(true);
        Qty := _RequestValues.GetValueAsDecimal('QuantityToAssemble', true);

        // Set Item, UoM and Variant from Barcode
        ItemNumber := MobItemReferenceMgt.SearchItemReference(ScannedBarcode, VariantCode, UoMCode);
        // Collected values have priority
        if _RequestValues.HasValue('UoM') then
            UoMCode := _RequestValues.GetValue('UoM');
        if _RequestValues.HasValue('Variant') then
            VariantCode := _RequestValues.GetValue('Variant');


        // Create Assembly Order
        AssemblyHeader.Init();
        AssemblyHeader.Validate("Document Type", AssemblyHeader."Document Type"::Order);
        AssemblyHeader.Insert(true);
        AssemblyHeader.Validate("Location Code", LocationCode);
        AssemblyHeader.Validate("Item No.", ItemNumber);
        if VariantCode <> '' then
            AssemblyHeader.Validate("Variant Code", VariantCode);
        if UoMCode <> '' then
            AssemblyHeader.Validate("Unit of Measure Code", UoMCode);
        AssemblyHeader.Validate(Quantity, Qty);
        AssemblyHeader.Validate("Quantity to Assemble", Qty);
        AssemblyHeader.Modify(true);

        // AvailToPromise will filter AssemblyLine as neccesary but also return a filtered line record
        MobAvailbility.AssemblyLineManagement_AvailToPromise(AssemblyHeader, AssemblyLine, OrderAbleToAssemble, EarliestDueDate);
        if OrderAbleToAssemble < AssemblyHeader."Quantity to Assemble" then
            MobToolbox.ErrorIfNotConfirm(_RequestValues, StrSubstNo(MobWmsLanguage.GetMessage('QUANTITY_ON_INVENTORY_XY_IS_NOT_SUFFICIENT'), OrderAbleToAssemble, AssemblyHeader."Unit of Measure Code"));

        // Release Assembly Header
        ReleaseAssemblyDocument.Run(AssemblyHeader);

        _ReturnRegistrationTypeTracking := ItemNumber;
        _SuccessMessage := MobWmsLanguage.GetMessage('REG_TRANS_SUCCESS');
    end;

    local procedure AdjustQtyToAssemble(var _RequestValues: Record "MOB NS Request Element"; var _SuccessMessage: Text; var _ReturnRegistrationTypeTracking: Text)
    var
        MobSetup: Record "MOB Setup";
        AssemblyHeader: Record "Assembly Header";
        Item: Record Item;
        UoMMgt: Codeunit "Unit of Measure Management";
        AssemblyDocNo: Code[20];
        Quantity: Decimal;
    begin
        // Parse values from Request
        Evaluate(AssemblyDocNo, _RequestValues.Get_OrderBackendID(true));
        Quantity := _RequestValues.GetValueAsDecimal('QuantityToAssemble', true);

        MobSetup.Get();
        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, AssemblyDocNo);
        AssemblyHeader.TestField("Item No.");
        Item.Get(AssemblyHeader."Item No.");

        if MobSetup."Use Base Unit of Measure" then
            AssemblyHeader.Validate("Quantity to Assemble", UoMMgt.CalcQtyFromBase(Quantity, AssemblyHeader."Qty. per Unit of Measure"))
        else
            AssemblyHeader.Validate("Quantity to Assemble", Quantity);
        AssemblyHeader.Modify(true);

        _ReturnRegistrationTypeTracking := AssemblyDocNo;
        _SuccessMessage := MobWmsLanguage.GetMessage('REG_TRANS_SUCCESS');
    end;

    //
    // -------  GetAssemblyOrders -------
    //

    local procedure GetAssemblyOrders(_MobDocQueue: Record "MOB Document Queue"; var _XmlResponseDoc: XmlDocument)
    var
        TempBaseOrderElement: Record "MOB NS BaseDataModel Element" temporary;
        XmlRequestDoc: XmlDocument;
        OrdersXmlResponseData: XmlNode;
    begin
        // Process:
        // 1. Filter and sort the Assembly Orders for this particular user
        // 2. Save the result in XML and return it to the mobile device

        // Load the request from the queue
        _MobDocQueue.LoadXMLRequestDoc(XmlRequestDoc);

        // Initialize the response document for order data
        MobToolbox.InitializeResponseDoc(_XmlResponseDoc, OrdersXmlResponseData);

        // Create the response for the mobile device
        CreateAssemblyOrdersResponse(XmlRequestDoc, _MobDocQueue, TempBaseOrderElement);

        // Add collected buffer values to new <Orders> nodes
        AddBaseOrderElements(OrdersXmlResponseData, TempBaseOrderElement);
    end;

    /// <summary>
    /// Loop through the Assembly Orders and add the information that should be available
    /// on the mobile device to the XML. The only elements that MUST be present in the XML are "BackendID", "Status" and "Sorting".
    /// Other values can be added freely and used in Mobile WMS by referencing the element name from the XML.
    /// </summary>
    local procedure CreateAssemblyOrdersResponse(var _XmlRequestDoc: XmlDocument; var _MobDocQueue: Record "MOB Document Queue"; var _BaseOrderElement: Record "MOB NS BaseDataModel Element")
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        TempAssemblyHeader: Record "Assembly Header" temporary;
        TempHeaderFilter: Record "MOB NS Request Element" temporary;
        TempEmptyHeaderFilter: Record "MOB NS Request Element" temporary;
        MobScannedValueMgt: Codeunit "MOB ScannedValue Mgt.";
        StartingDate: Date;
        ScannedValue: Text;
        IsHandled: Boolean;
    begin
        // Mandatory Header filters for this function to operate        
        AssemblyHeader.Reset();
        AssemblyHeader.SetCurrentKey(Status, "Starting Date", "Document Type", "No.");   // Order by "Starting Date" (however field is not a part of actual key)
        AssemblyHeader.SetRange(Status, AssemblyHeader.Status::Released);
        AssemblyHeader.SetRange("Document Type", AssemblyHeader."Document Type"::Order);
        AssemblyHeader.SetRange("Assemble to Order", false);
        AssemblyHeader.SetFilter("Item No.", '<>%1', '');
        AssemblyHeader.SetFilter("Remaining Quantity", '>0');

        // Mandatory Line filters
        AssemblyLine.SetRange(Type, AssemblyLine.Type::Item);

        // XML filter data into Temporary table
        MobRequestMgt.SaveHeaderFilters(_XmlRequestDoc, TempHeaderFilter);

        if TempHeaderFilter.FindSet() then
            repeat
                //
                // Event to allow for handling (custom) filters
                //
                IsHandled := false;
                OnGetAssemblyOrders_OnSetFilterAssemblyHeader(TempHeaderFilter, AssemblyHeader, AssemblyLine, IsHandled);

                if not IsHandled then
                    case TempHeaderFilter.Name of

                        'Location':
                            if TempHeaderFilter."Value" = 'All' then
                                AssemblyHeader.SetFilter("Location Code", MobWmsToolbox.GetLocationFilter(UserId())) // All locations for this user
                            else
                                AssemblyHeader.SetRange("Location Code", TempHeaderFilter."Value");

                        'StartingDate':
                            begin
                                StartingDate := TempHeaderFilter.GetValueAsDate();
                                if StartingDate <> 0D then
                                    AssemblyHeader.SetFilter("Starting Date", '<=%1', StartingDate);
                            end;

                        'ScannedValue':
                            ScannedValue := TempHeaderFilter."Value";   // Used in search for Document No. or Item/Variant later

                        'AssignedUser':
                            case TempHeaderFilter."Value" of
                                'All':
                                    ; // No filter -> do nothing
                                'OnlyMine':
                                    AssemblyHeader.SetRange("Assigned User ID", _MobDocQueue."Mobile User ID");  // Current user
                                'MineAndUnassigned':
                                    AssemblyHeader.SetFilter("Assigned User ID", '''''|%1', _MobDocQueue."Mobile User ID"); // Current user or blank
                            end;
                    end;

            until TempHeaderFilter.Next() = 0;

        // Run event once more with Empty "Header filter" to allow for additional filtering directly on the records, NOT related to specific Header filter        
        IsHandled := false;
        OnGetAssemblyOrders_OnSetFilterAssemblyHeader(TempEmptyHeaderFilter, AssemblyHeader, AssemblyLine, IsHandled);

        // Filter: DocumentNo or Item/Variant (match for scanned document no. at location takes precedence over other filters)
        if ScannedValue <> '' then
            MobScannedValueMgt.SetFilterForAssemblyOrder(AssemblyHeader, ScannedValue);

        // Insert orders into temp rec
        CopyFilteredAssemblyOrderToTempRecord(AssemblyHeader, AssemblyLine, TempAssemblyHeader);

        // Respond with resulting orders
        SetAssemblyOrdersResponse(TempAssemblyHeader, _BaseOrderElement, TempHeaderFilter);
    end;

    /// <summary>
    /// Transfer possibly filtered orders into temp record
    /// </summary>
    local procedure CopyFilteredAssemblyOrderToTempRecord(var _AssemblyHeaderView: Record "Assembly Header"; var _AssemblyLineView: Record "Assembly Line"; var _TempAssemblyHeader: Record "Assembly Header")
    var
        IncludeInOrderList: Boolean;
    begin
        if _AssemblyHeaderView.FindSet() then
            repeat
                IncludeInOrderList := false;

                // Insert Only if lines exist
                _AssemblyLineView.SetRange("Document Type", _AssemblyHeaderView."Document Type");
                _AssemblyLineView.SetRange("Document No.", _AssemblyHeaderView."No.");
                // Is also filtered: _AssemblyLineView.Type::Item unless this was changed during OnGetAssemblyOrders_OnSetFilterAssemblyHeader event
                if _AssemblyLineView.FindSet() then
                    repeat
                        // Find at least one 'Consumption' Assembly Line that is included using same criterias as
                        // later used for OrderLinesList however not respecting OnIncludeAssemblyLine-event here.
                        // Customizations in this event will need to be redundantly implemented in OnIncludeAssemblyHeader.
                        IncludeInOrderList := IsAssemblyLineIncluded(_AssemblyLineView);
                    until (_AssemblyLineView.Next() = 0) or IncludeInOrderList;

                // Verify additional conditions from eventsubscribers
                OnGetAssemblyOrders_OnIncludeAssemblyHeader(_AssemblyHeaderView, IncludeInOrderList);

                if IncludeInOrderList then begin
                    _TempAssemblyHeader.Copy(_AssemblyHeaderView);
                    _TempAssemblyHeader.Insert();
                end;

            until _AssemblyHeaderView.Next() = 0;
    end;

    local procedure SetAssemblyOrdersResponse(var _AssemblyHeader: Record "Assembly Header"; var _BaseOrderElement: Record "MOB NS BaseDataModel Element"; var _TempHeaderFilter: Record "MOB NS Request Element")
    begin
        if _AssemblyHeader.FindSet() then
            repeat
                _BaseOrderElement.Create();
                SetFromAssemblyHeader(_AssemblyHeader, _BaseOrderElement, _TempHeaderFilter);
                _BaseOrderElement.Save();
            until _AssemblyHeader.Next() = 0;
    end;

    //
    // -------  GetAssemblyOrderLines -------
    //

    local procedure GetAssemblyOrderLines(_MobDocQueue: Record "MOB Document Queue"; var _XmlResponseDoc: XmlDocument)
    var
        TempRequestValues: Record "MOB NS Request Element" temporary;
        BackendID: Code[20];
    begin
        // Get the prefixed <BackendID> element
        _MobDocQueue.LoadAdhocRequestValues(TempRequestValues);
        Evaluate(BackendID, TempRequestValues.Get_BackendID(true));

        // Create the response for the mobile device
        CreateAssemblyLinesResponse(BackendID, _XmlResponseDoc);
    end;

    local procedure CreateAssemblyLinesResponse(_BackendID: Code[20]; var _XmlResponseDoc: XmlDocument)
    var
        MobSetup: Record "MOB Setup";
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        TempBaseOrderLineElement: Record "MOB NS BaseDataModel Element" temporary;
        XmlResponseData: XmlNode;
        IncludeInOrderLines: Boolean;
    begin
        MobSetup.Get();

        // Initialize the response document for order line data
        MobToolbox.InitializeOrderLineDataRespDoc(_XmlResponseDoc, XmlResponseData);

        if AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, _BackendID) then begin

            // Add collectorSteps to be displayed on posting
            AddStepsToAssemblyHeader(AssemblyHeader, _XmlResponseDoc, XmlResponseData);

            // Assembly Output and Input are displayed in same orderlines page on Mobile Device -- this is the single line for Assembly Output 
            // In MobWmsRegistrations this line is separated by having Line No. = 0
            TempBaseOrderLineElement.Create();
            SetLineFromAssemblyHeader(AssemblyHeader, TempBaseOrderLineElement);
            TempBaseOrderLineElement.Save();

            // Filter the Assembly Lines
            AssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type");
            AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
            AssemblyLine.SetRange(Type, AssemblyLine.Type::Item);

            // Event to expose Lines for filtering before Response
            OnGetAssemblyOrderLines_OnSetFilterAssemblyLine(AssemblyLine);

            if AssemblyLine.FindSet() then
                repeat
                    IncludeInOrderLines := IsAssemblyLineIncluded(AssemblyLine);

                    // Verify additional conditions from eventsubscribers
                    OnGetAssemblyOrderLines_OnIncludeAssemblyLine(AssemblyLine, IncludeInOrderLines);

                    if IncludeInOrderLines then begin
                        if (AssemblyLine.Type = AssemblyLine.Type::Item) then begin
                            RetrieveAssemblyLineItemTracking(AssemblyLine, TempTrackingSpecification);
                            if TempTrackingSpecification.FindSet() then
                                repeat
                                    // Using AssemblyLine."Quantity to Consume (Base)" and ."Qty. to Handle" for remaining quantities during this iteration
                                    if Abs(TempTrackingSpecification."Qty. to Handle (Base)") > AssemblyLine."Quantity to Consume (Base)" then begin
                                        TempTrackingSpecification."Qty. to Handle (Base)" := -AssemblyLine."Quantity to Consume (Base)";
                                        TempTrackingSpecification."Qty. to Handle" := -AssemblyLine."Quantity to Consume";
                                    end;
                                    TempBaseOrderLineElement.Create();
                                    SetFromAssemblyLine(AssemblyLine, TempTrackingSpecification, TempBaseOrderLineElement);
                                    TempBaseOrderLineElement.Save();
                                    AssemblyLine."Quantity to Consume (Base)" += TempTrackingSpecification."Qty. to Handle (Base)";
                                    AssemblyLine."Quantity to Consume" += TempTrackingSpecification."Qty. to Handle";
                                until (TempTrackingSpecification.Next() = 0) or (AssemblyLine."Quantity to Consume (Base)" <= 0);
                        end; // endif Type::Item

                        // Remaining Quantity to Consume for the line goes on a new element (could be total qty. if no tracking was inserted above or remaining qty. if partial tracking)
                        if (AssemblyLine."Quantity to Consume (Base)" > 0) or (AssemblyLine.Type = AssemblyLine.Type::" ") then begin
                            Clear(TempTrackingSpecification);
                            TempBaseOrderLineElement.Create();
                            SetFromAssemblyLine(AssemblyLine, TempTrackingSpecification, TempBaseOrderLineElement);
                            TempBaseOrderLineElement.Save();
                        end;
                    end;
                until AssemblyLine.Next() = 0;

            // Insert the values from the assembly lines in the XML
            AddBaseOrderLineElements(XmlResponseData, TempBaseOrderLineElement);
        end;
    end;

    local procedure IsAssemblyLineIncluded(_AssemblyLine: Record "Assembly Line"): Boolean
    begin
        case _AssemblyLine.Type of
            _AssemblyLine.Type::" ":
                exit(true);
            _AssemblyLine.Type::Item:
                exit(_AssemblyLine."Remaining Quantity" > 0); // BC ensure Items are either of type Inventory or Non-Inventory (Service is not allowed)
            _AssemblyLine.Type::Resource:
                exit(_AssemblyLine."Remaining Quantity" > 0);
        end;
    end;

    local procedure AddStepsToAssemblyHeader(_AssemblyHeader: Record "Assembly Header"; _XmlResponseDoc: XmlDocument; var _XmlResponseData: XmlNode)
    var
        TempSteps: Record "MOB Steps Element" temporary;
        MobXmlMgt: Codeunit "MOB XML Management";
        XmlSteps: XmlNode;
    begin
        TempSteps.SetMustCallCreateNext(true);
        OnGetAssemblyOrderLines_OnAddStepsToAssemblyHeader(_AssemblyHeader, TempSteps);

        if not TempSteps.IsEmpty() then begin
            // Adds Collector Configuration with <steps> {<add ... />} <steps/>
            MobToolbox.AddCollectorConfiguration(_XmlResponseDoc, _XmlResponseData, XmlSteps);
            MobXmlMgt.AddStepsaddElements(XmlSteps, TempSteps);
        end;
    end;

    internal procedure RetrieveAssemblyHeaderItemTracking(_AssemblyHeader: Record "Assembly Header"): Boolean
    var
        ReservEntry: Record "Reservation Entry";
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        ItemTrackingMgt: Codeunit "Item Tracking Management";
    begin
        ReservEntry.SetSourceFilter(Database::"Assembly Header", MobToolbox.AsInteger(_AssemblyHeader."Document Type"), _AssemblyHeader."No.", 0, true);
        ReservEntry.SetFilter("Qty. to Handle (Base)", '<>0');

        exit(ItemTrackingMgt.SumUpItemTracking(ReservEntry, TempTrackingSpecification, true, true));
    end;

    local procedure RetrieveAssemblyLineItemTracking(_AssemblyLine: Record "Assembly Line"; var _TempTrackingSpecification: Record "Tracking Specification" temporary): Boolean
    var
        ReservEntry: Record "Reservation Entry";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
    begin
        if not _TempTrackingSpecification.IsTemporary() then
            Error(MUST_BE_TEMPORARY_Err, _TempTrackingSpecification.TableCaption());    // SumUpItemTracking() will delete all content

        ReservEntry.SetSourceFilter(Database::"Assembly Line", MobToolbox.AsInteger(_AssemblyLine."Document Type"), _AssemblyLine."Document No.", _AssemblyLine."Line No.", true);
        ReservEntry.SetFilter("Qty. to Handle (Base)", '<>0');

        // Sum up in a temporary table per component line:
        exit(ItemTrackingMgt.SumUpItemTracking(ReservEntry, _TempTrackingSpecification, true, true));
    end;

    //
    // ------- PostAssemblyOrder -------
    //

    local procedure PostAssemblyOrder(_MobDocQueue: Record "MOB Document Queue"; var _XmlResponseDoc: XmlDocument)
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        TempReservationEntryLog: Record "Reservation Entry" temporary;
        TempReservationEntry: Record "Reservation Entry" temporary;
        MobRegistration: Record "MOB WMS Registration";
        TempOrderValues: Record "MOB Common Element" temporary;
        AssemblyPost: Codeunit "Assembly-Post";
        MobSyncItemTracking: Codeunit "MOB Sync. Item Tracking";
        XmlRequestDoc: XmlDocument;
        BackendID: Code[20];
        ResultMessage: Text;
    begin
        // Disable the locktimeout to prevent timeout messages on the mobile device
        LockTimeout(false);

        // Lock the tables to work on
        AssemblyHeader.LockTable();
        AssemblyLine.LockTable();
        MobRegistration.LockTable();

        // Turn on commit protection to prevent unintentional committing data
        _MobDocQueue.Consistent(false);

        // Load the request document from the document queue
        _MobDocQueue.LoadXMLRequestDoc(XmlRequestDoc);

        // Save the registrations from the XML in the Mobile WMS Registration table
        // The function returns the order id without the prefix        
        BackendID := MobWmsToolbox.SaveRegistrationData(_MobDocQueue.MessageIDAsGuid(), XmlRequestDoc, MobRegistration.Type::"Assembly Order");

        // Make sure that the order still exists
        if not AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, BackendID) then
            Error(MobWmsLanguage.GetMessage('UNKNOWN_ORDER'), BackendID);

        // Set posting date
        if AssemblyHeader."Posting Date" <> WorkDate() then begin
            AssemblyHeader.SetHideValidationDialog(true);
            AssemblyHeader.Validate("Posting Date", WorkDate());
        end;

        AssemblyHeader."MOB Posting MessageId" := _MobDocQueue.MessageIDAsGuid();

        // OnBeforePost IntegrationEvents
        MobRequestMgt.InitCommonFromXmlOrderNode(XmlRequestDoc, TempOrderValues);
        OnPostAssemblyOrder_OnBeforePostAssemblyOrder(TempOrderValues, AssemblyHeader);
        AssemblyHeader.Modify(true);

        // Filter the assembly lines
        AssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type"::Order);
        AssemblyLine.SetRange("Document No.", BackendID);

        // Save the original reservation entries in case we need to revert (if the posting fails)
        MobSyncItemTracking.SaveOriginalReservationEntriesForAssemblyHeader(AssemblyHeader, TempReservationEntryLog);
        MobSyncItemTracking.SaveOriginalReservationEntriesForAssemblyLines(AssemblyLine, TempReservationEntryLog);

        HandleRegistrationsForAssemblyHeader(AssemblyHeader, TempReservationEntry, AssemblyHeader."MOB Posting MessageId");

        if AssemblyLine.FindSet() then
            repeat
                HandleRegistrationsForAssemblyLine(AssemblyLine, TempReservationEntry, AssemblyHeader."MOB Posting MessageId");
            until AssemblyLine.Next() = 0;

        // Verify all registrations was handled
        MobRegistration.Reset();
        MobRegistration.SetCurrentKey("Posting MessageId");
        MobRegistration.SetRange("Posting MessageId", _MobDocQueue.MessageIDAsGuid());
        MobRegistration.SetRange(Handled, false);
        if MobRegistration.FindFirst() then
            MobRegistration.FieldError(Handled);

        MobSyncItemTracking.Run(TempReservationEntry);
        // Turn off the commit protection
        // From this point on we explicitely clean up committed data if an error occurs
        _MobDocQueue.Consistent(true);
        Commit();

        Clear(AssemblyPost);
        if not AssemblyPost.Run(AssemblyHeader) then begin
            // The created reservation entries have been committed
            // If the posting fails for some reason we need to clean up the created reservation entries and MobWmsRegistrations
            ResultMessage := GetLastErrorText();
            MobSessionData.SetPreservedLastErrorCallStack();
            // Delete the created reservation entries
            MobSyncItemTracking.RevertToOriginalReservationEntriesForAssemblyHeader(AssemblyHeader, TempReservationEntryLog);
            MobSyncItemTracking.RevertToOriginalReservationEntriesForAssemblyLines(AssemblyLine, TempReservationEntryLog);
            Commit();
            UpdateIncomingAssemblyOrder(AssemblyHeader);
            MobWmsToolbox.DeleteRegistrationData(_MobDocQueue.MessageIDAsGuid());
            Commit();   // Separate commit to prevent error in UpdateIncomingAssemblyOrder from preventing Reservation Entries being rollback
            Error(ResultMessage);
        end;

        // Create a response inside the <description> element of the document response
        MobToolbox.CreateSimpleResponse(_XmlResponseDoc, MobWmsLanguage.GetMessage('POST_SUCCESS'));
    end;

    local procedure UpdateIncomingAssemblyOrder(var _AssemblyHeader: Record "Assembly Header")
    begin
        if not _AssemblyHeader.Get(_AssemblyHeader."Document Type", _AssemblyHeader."No.") then
            exit;

        _AssemblyHeader.LockTable();
        _AssemblyHeader.Get(_AssemblyHeader."Document Type", _AssemblyHeader."No.");
        Clear(_AssemblyHeader."MOB Posting MessageId");
        _AssemblyHeader.Modify();
    end;

    local procedure HandleRegistrationsForAssemblyHeader(var _AssemblyHeader: Record "Assembly Header"; var _TempNewReservationEntry: Record "Reservation Entry"; _PostingMessageId: Guid)
    var
        MobSetup: Record "MOB Setup";
        MobTrackingSetup: Record "MOB Tracking Setup";
        MobWmsRegistration: Record "MOB WMS Registration";
        Location: Record Location;
        ReservationEntry: Record "Reservation Entry";
        UoMMgt: Codeunit "Unit of Measure Management";
        MobSyncItemTracking: Codeunit "MOB Sync. Item Tracking";
        RegisterExpirationDate: Boolean;
        Qty: Decimal;
        QtyBase: Decimal;
        TotalQty: Decimal;
        TotalQtyBase: Decimal;
    begin
        MobSetup.Get();

        // Try to find the registrations
        MobWmsRegistration.Reset();
        MobWmsRegistration.SetRange(Type, MobWmsRegistration.Type::"Assembly Order");
        MobWmsRegistration.SetRange("Order No.", _AssemblyHeader."No.");
        MobWmsRegistration.SetRange("Line No.", 0);     // Registrations for the Output has no associated Line No.
        MobWmsRegistration.SetRange("Posting MessageId", _PostingMessageId);
        MobWmsRegistration.SetRange(Handled, false);

        // Line splitting is not supported for Assembly Orders
        // Before the registrations are processed we need to determine if the user has picked from multiple bins
        MobWmsToolbox.ValidateSingleRegistrationBin(MobWmsRegistration);

        // If the registration is found -> set the quantity to handle
        // Else set the quantity to handle to zero (to avoid posting lines with the qty to handle set to something)
        if MobWmsRegistration.FindSet() then begin

            // If Location."Bin Mandatory" Bin Code must be validated.
            if not Location.Get(_AssemblyHeader."Location Code") then
                Clear(Location);

            if Location."Bin Mandatory" then begin
                _AssemblyHeader.SuspendStatusCheck(true);
                _AssemblyHeader.Validate("Bin Code", MobWmsRegistration.ToBin);
                _AssemblyHeader.SuspendStatusCheck(false);
            end;

            // If item tracking is used the quantity must be set to the sum of the registrations
            // Determine if serial / lot number registration is needed based on Assembly Line type (inbound and outbound "SN Assembly Tracking")
            Clear(MobTrackingSetup);
            MobTrackingSetup.DetermineItemTrackingRequiredByAssemblyHeader(_AssemblyHeader, RegisterExpirationDate);
            // MobTrackingSetup.Tracking: Tracking values are unused in this scope

            if MobTrackingSetup.TrackingRequired() then begin
                ReservationEntry.Reset();
                ReservationEntry.SetSourceFilter(Database::"Assembly Header", MobToolbox.AsInteger(_AssemblyHeader."Document Type"), _AssemblyHeader."No.", 0, true);
                if not ReservationEntry.IsEmpty() then
                    ReservationEntry.ModifyAll("Qty. to Handle (Base)", 0, true);
            end;

            // Initialize the quantity counter
            TotalQty := 0;
            TotalQtyBase := 0;

            repeat
                // Update the quantity
                if MobSetup."Use Base Unit of Measure" then begin
                    Qty := 0; // To ensure best possible rounding the TotalQty will be calculated after the loop
                    QtyBase := MobWmsRegistration.Quantity;
                end else begin
                    MobWmsRegistration.TestField(UnitOfMeasure, _AssemblyHeader."Unit of Measure Code");
                    Qty := MobWmsRegistration.Quantity;
                    QtyBase := UoMMgt.CalcBaseQty(MobWmsRegistration.Quantity, _AssemblyHeader."Qty. per Unit of Measure");
                end;

                TotalQty := TotalQty + Qty;
                TotalQtyBase := TotalQtyBase + QtyBase;

                // If item tracking is needed a reservation entry must be created                
                if MobTrackingSetup.TrackingRequired() then
                    // Synchronize Item Tracking to Source Document
                    MobSyncItemTracking.CreateTempReservEntryForAssemblyHeader(_AssemblyHeader, MobWmsRegistration, _TempNewReservationEntry, QtyBase);

                MobWmsToolbox.SaveRegistrationDataFromSource(_AssemblyHeader."Location Code", _AssemblyHeader."Item No.", _AssemblyHeader."Variant Code", MobWmsRegistration);

                // OnHandle IntegrationEvents (AssemblyHeader intentionally not modified -- is modified below)
                OnPostAssemblyOrder_OnHandleRegistrationForAssemblyHeader(MobWmsRegistration, _AssemblyHeader, _TempNewReservationEntry);

                // Set the handled flag to true on the registration
                MobWmsRegistration.Validate(Handled, true);
                MobWmsRegistration.Modify();

                if MobTrackingSetup.TrackingRequired() then
                    if _TempNewReservationEntry.Modify() then; // To modify if created earlier and possibly updated in subscriber

            until MobWmsRegistration.Next() = 0;

            // To ensure best possible rounding the TotalQty is calculated and rounded only once when MobSetup."Use Base Unit of Measure" is enabled (i.e. 3 * 1/3 = 1)
            if MobSetup."Use Base Unit of Measure" then
                TotalQty := UoMMgt.CalcQtyFromBase(TotalQtyBase, _AssemblyHeader."Qty. per Unit of Measure");

            // Set the quantity on the order line
            _AssemblyHeader.Validate("Quantity to Assemble", TotalQty);

        end else  // endif MobWmsRegistration.FindSet()
            _AssemblyHeader.Validate("Quantity to Assemble", 0);

        _AssemblyHeader.Modify();
    end;

    local procedure HandleRegistrationsForAssemblyLine(var _AssemblyLine: Record "Assembly Line"; var _TempNewReservationEntry: Record "Reservation Entry"; _PostingMessageId: Guid)
    var
        MobSetup: Record "MOB Setup";
        Location: Record Location;
        ReservationEntry: Record "Reservation Entry";
        MobWmsRegistration: Record "MOB WMS Registration";
        AssemblyLineTrackingSetup: Record "MOB Tracking Setup";
        MobSpecificTrackingSetup: Record "MOB Tracking Setup";
        UoMMgt: Codeunit "Unit of Measure Management";
        MobSyncItemTracking: Codeunit "MOB Sync. Item Tracking";
        MobCommonMgt: Codeunit "MOB Common Mgt.";
        DummyRegisterExpirationDate: Boolean;
        Qty: Decimal;
        QtyBase: Decimal;
        TotalQty: Decimal;
        TotalQtyBase: Decimal;
    begin
        // Try to find the registrations
        MobWmsRegistration.SetRange(Type, MobWmsRegistration.Type::"Assembly Order");
        MobWmsRegistration.SetRange("Order No.", _AssemblyLine."Document No.");
        MobWmsRegistration.SetRange("Line No.", _AssemblyLine."Line No.");
        MobWmsRegistration.SetRange("Posting MessageId", _PostingMessageId);
        MobWmsRegistration.SetRange(Handled, false);

        // Line splitting is not supported for Assembly Orders
        // Before the registrations are processed we need to determine if the user has picked from multiple bins
        MobWmsToolbox.ValidateSingleRegistrationBin(MobWmsRegistration);

        // If the registration is found -> set the quantity to handle
        // Else quantity is left as partial quantity to consume (all lines was initiated with partial quantity during header validate)
        if MobWmsRegistration.FindSet() then begin

            // Read the MOB Setup
            MobSetup.Get();

            // If Location."Bin Mandatory" Bin Code must be validated.
            if not Location.Get(_AssemblyLine."Location Code") then
                Clear(Location);

            if Location."Bin Mandatory" and MobCommonMgt.AssemblyLine_IsInventoriableItem(_AssemblyLine) then begin
                _AssemblyLine.SuspendStatusCheck(true);
                _AssemblyLine.Validate("Bin Code", MobWmsRegistration.FromBin);
                _AssemblyLine.SuspendStatusCheck(false);
            end;

            // If item tracking is used the quantity must be set to the sum of the registrations
            // Determine if serial / lot number registration is needed based on Assembly Line type (inbound and outbound "SN Assembly Tracking")
            Clear(AssemblyLineTrackingSetup);
            AssemblyLineTrackingSetup.DetermineItemTrackingRequiredByAssemblyLine(_AssemblyLine, DummyRegisterExpirationDate);
            // MobTrackingSetup.Tracking: Tracking values are unused in this scope

            if AssemblyLineTrackingSetup.TrackingRequired() then begin
                ReservationEntry.Reset();
                ReservationEntry.SetSourceFilter(Database::"Assembly Line", MobToolbox.AsInteger(_AssemblyLine."Document Type"), _AssemblyLine."Document No.", _AssemblyLine."Line No.", true);
                if not ReservationEntry.IsEmpty() then
                    ReservationEntry.ModifyAll("Qty. to Handle (Base)", 0, true);
            end;

            // Initialize the quantity counter
            TotalQty := 0;
            TotalQtyBase := 0;

            repeat
                // Update the quantity
                if MobSetup."Use Base Unit of Measure" then begin
                    Qty := 0; // To ensure best possible rounding the TotalQty will be calculated after the loop
                    QtyBase := MobWmsRegistration.Quantity;
                end else begin
                    MobWmsRegistration.TestField(UnitOfMeasure, _AssemblyLine."Unit of Measure Code");
                    Qty := MobWmsRegistration.Quantity;
                    QtyBase := UoMMgt.CalcBaseQty(MobWmsRegistration.Quantity, _AssemblyLine."Qty. per Unit of Measure");
                end;

                TotalQty := TotalQty + Qty;
                TotalQtyBase := TotalQtyBase + QtyBase;

                // If item tracking is needed a reservation entry must be created                
                if AssemblyLineTrackingSetup.TrackingRequired() then begin

                    // Only verify against existing inventory if "SN Specific Tracking" / "Lot Specific Tracking" is set
                    MobSpecificTrackingSetup.DetermineSpecificTrackingRequiredFromItemNo(_AssemblyLine."No.", DummyRegisterExpirationDate);
                    MobSpecificTrackingSetup.CopyTrackingFromRegistration(MobWmsRegistration);

                    // SN at existing entries for this item can only be guaranteed to be populated if "SN Specific Tracking" is set
                    // Unknown combination of SerialNo/LotNumber is not verified but will throw error in standard posting routine
                    MobSpecificTrackingSetup.CheckTrackingOnInventoryIfRequired(_AssemblyLine."No.", _AssemblyLine."Variant Code");

                    // Synchronize Item Tracking to Source Document
                    MobSyncItemTracking.CreateTempReservEntryForAssemblyLine(_AssemblyLine, MobWmsRegistration, _TempNewReservationEntry, QtyBase);
                end;

                MobWmsToolbox.SaveRegistrationDataFromSource(_AssemblyLine."Location Code", _AssemblyLine."No.", _AssemblyLine."Variant Code", MobWmsRegistration);

                // OnHandle IntegrationEvents (AssemblyLine intentionally not modified -- is modified below)
                OnPostAssemblyOrder_OnHandleRegistrationForAssemblyLine(MobWmsRegistration, _AssemblyLine, _TempNewReservationEntry);

                // Set the handled flag to true on the registration
                MobWmsRegistration.Validate(Handled, true);
                MobWmsRegistration.Modify();

                if AssemblyLineTrackingSetup.TrackingRequired() then
                    _TempNewReservationEntry.Modify();

            until MobWmsRegistration.Next() = 0;

            // To ensure best possible rounding the TotalQty is calculated and rounded only once when MobSetup."Use Base Unit of Measure" is enabled (i.e. 3 * 1/3 = 1)
            if MobSetup."Use Base Unit of Measure" then
                TotalQty := UoMMgt.CalcQtyFromBase(TotalQtyBase, _AssemblyLine."Qty. per Unit of Measure");

            // Set the quantity on the order line
            _AssemblyLine.Validate("Quantity to Consume", TotalQty);

        end; // endif MobWmsRegistration.FindSet()
        _AssemblyLine.Modify();
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
        OnGetAssemblyOrders_OnAfterSetCurrentKey(TempHeaderElementCustomView);
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
        TempBaseOrderLineElementCustomView: Record "MOB NS BaseDataModel Element" temporary;
    begin
        _BaseOrderLineElement.SetCurrentKey("Sorting1 (internal)", "Sorting2 (internal)", "Sorting3 (internal)", "Sorting4 (internal)", "Sorting5 (internal)");

        // use new temporary/empty record for integration event to prevent SetFrom from being in effect at this point in time
        TempBaseOrderLineElementCustomView.SetView(_BaseOrderLineElement.GetView());
        OnGetAssemblyOrderLines_OnAfterSetCurrentKey(TempBaseOrderLineElementCustomView);
        _BaseOrderLineElement.SetView(TempBaseOrderLineElementCustomView.GetView());
    end;

    local procedure SetFromAssemblyHeader(_AssemblyHeader: Record "Assembly Header"; var _BaseOrder: Record "MOB NS BaseDataModel Element"; var _TempHeaderFilter: Record "MOB NS Request Element")
    var
        MobSetup: Record "MOB Setup";
        Location: Record Location;
        Item: Record Item;
        DisplayLine2To9List: List of [Text];
    begin
        MobSetup.Get();

        // Add the data to the order header element        
        _BaseOrder.Init();

        _BaseOrder.Set_BackendID(_AssemblyHeader."No.");
        _BaseOrder.Set_ItemNumber(_AssemblyHeader."Item No.");

        // Now we add the elements that we want the user to see            
        _BaseOrder.Set_DisplayLine1(_AssemblyHeader."No.");
        _BaseOrder.Set_DisplayLine2(_AssemblyHeader."Item No." + '  ' + _AssemblyHeader.Description);

        if (_TempHeaderFilter.Get_Location() = 'All') and Location.Get(_AssemblyHeader."Location Code") then
            _BaseOrder.Set_DisplayLine3(Location.Name <> '', Location.Name, Location.Code);

        _BaseOrder.Set_Location(_AssemblyHeader."Location Code"); // Default value for PrintLabel Lookup

        if _AssemblyHeader."Variant Code" <> '' then
            _BaseOrder.Set_DisplayLine4(_AssemblyHeader."Variant Code" <> '', MobWmsLanguage.GetMessage('VARIANT_LABEL') + ': ' + _AssemblyHeader."Variant Code", '');

        _BaseOrder.Set_HeaderLabel1(MobWmsLanguage.GetMessage('ORDER_NUMBER'));
        _BaseOrder.Set_HeaderLabel2(MobWmsLanguage.GetMessage('DESCRIPTION'));
        _BaseOrder.Set_HeaderValue1(_AssemblyHeader."No." + ' - ' + Format(_AssemblyHeader."Item No."));
        _BaseOrder.Set_HeaderValue2(_AssemblyHeader.Description);

        _BaseOrder.SetValue('StartingDateLabel', MobWmsLanguage.GetMessage('STARTING_DATE'));
        _BaseOrder.SetValue('StartingDate', MobWmsToolbox.Date2TextAsDisplayFormat(_AssemblyHeader."Starting Date"));

        _BaseOrder.SetValue('QuantityLabel', MobWmsLanguage.GetMessage('QUANTITY'));
        _BaseOrder.SetValue('FinishedQuantityLabel', MobWmsLanguage.GetMessage('FINISHED_QTY'));
        _BaseOrder.SetValue('RemainingQuantityLabel', MobWmsLanguage.GetMessage('REMAINING_QTY'));

        if MobSetup."Use Base Unit of Measure" then begin
            Item.Get(_AssemblyHeader."Item No.");
            _BaseOrder.Set_Quantity(MobWmsToolbox.Decimal2TextAsDisplayFormat(_AssemblyHeader."Quantity (Base)"));
            _BaseOrder.SetValue('FinishedQuantity', MobWmsToolbox.Decimal2TextAsDisplayFormat(_AssemblyHeader."Assembled Quantity (Base)", false));
            _BaseOrder.SetValue('RemainingQuantity', MobWmsToolbox.Decimal2TextAsDisplayFormat(_AssemblyHeader."Remaining Quantity (Base)", false));
            _BaseOrder.Set_UnitOfMeasure(Item."Base Unit of Measure");
        end else begin
            _BaseOrder.Set_Quantity(MobWmsToolbox.Decimal2TextAsDisplayFormat(_AssemblyHeader.Quantity));
            _BaseOrder.SetValue('FinishedQuantity', MobWmsToolbox.Decimal2TextAsDisplayFormat(_AssemblyHeader."Assembled Quantity", false));
            _BaseOrder.SetValue('RemainingQuantity', MobWmsToolbox.Decimal2TextAsDisplayFormat(_AssemblyHeader."Remaining Quantity", false));
            _BaseOrder.Set_UnitOfMeasure(_AssemblyHeader."Unit of Measure Code");
        end;

        _BaseOrder.Set_ReferenceID(_AssemblyHeader);
        _BaseOrder.Set_Status(); // Set Locked/Has Attachment symbol (1=Unlocked, 2=Locked, 3=Attachment)
        _BaseOrder.Set_Attachment();
        _BaseOrder.Set_ItemImageID();

        if _AssemblyHeader."Starting Date" <> 0D then
            _BaseOrder.Set_Sorting1(_AssemblyHeader."Starting Date");

        // Integration Events
        OnGetAssemblyOrders_OnAfterSetFromAssemblyHeader(_AssemblyHeader, _BaseOrder);

        // Compressed display lines 2 to 9 (after integration events to change display lines)
        _BaseOrder.GetDisplayLinesAsList(DisplayLine2To9List, 2, 9);
        MobWmsToolbox.ListTrimBlank(DisplayLine2To9List, 2);
        _BaseOrder.SetValue('CompressedDisplayLine2To9', MobWmsToolbox.List2TextLn(DisplayLine2To9List, 999));
    end;

    local procedure SetLineFromAssemblyHeader(_AssemblyHeader: Record "Assembly Header"; var _BaseOrderLine: Record "MOB NS BaseDataModel Element")
    var
        MobSetup: Record "MOB Setup";
        MobTrackingSetup: Record "MOB Tracking Setup";
        TempSteps: Record "MOB Steps Element" temporary;
        Location: Record Location;
        Item: Record Item;
        ExpDateRequired: Boolean;
        DisplayLine2To9List: List of [Text];
        ExtraInfo1_Col1: List of [Text];
        ExtraInfo1_Col2: List of [Text];
        ExtraInfo2_Col1: List of [Text];
        ExtraInfo2_Col2: List of [Text];
    begin
        MobSetup.Get();

        if not Location.Get(_AssemblyHeader."Location Code") then
            Clear(Location);

        // Add the data to the order line element
        _BaseOrderLine.Init();
        _BaseOrderLine.Set_OrderBackendID(_AssemblyHeader."No.");
        _BaseOrderLine.Set_Location(Location.Code);

        // Add the data to the order line element
        _BaseOrderLine.Set_LineNumber(0);
        _BaseOrderLine.Set_ItemNumber(_AssemblyHeader."Item No.");
        _BaseOrderLine.Set_ItemBarcode(MobItemReferenceMgt.GetBarcodeList(_AssemblyHeader."Item No.", _AssemblyHeader."Variant Code", _AssemblyHeader."Unit of Measure Code"));
        _BaseOrderLine.Set_Description(_AssemblyHeader.Description);

        _BaseOrderLine.Set_FromBin('');
        _BaseOrderLine.Set_ValidateFromBin(false);

        // ToBin
        if Location."Bin Mandatory" then begin
            _BaseOrderLine.Set_ToBin(_AssemblyHeader."Bin Code");
            _BaseOrderLine.Set_ValidateToBin(true);
            _BaseOrderLine.Set_AllowBinChange(true);
        end else begin
            // No location or no mandatory bin -> no bin validation
            _BaseOrderLine.Set_ToBin(MobWmsToolbox.GetItemShelfNo(_AssemblyHeader."Item No.", _AssemblyHeader."Location Code", _AssemblyHeader."Variant Code"));
            _BaseOrderLine.Set_ValidateToBin(_BaseOrderLine.Get_ToBin() <> '');
            _BaseOrderLine.Set_AllowBinChange(false);
        end;

        // Determine if serial / lot number registration is needed
        // Lot and serial no. should not be validated regardless of setup.
        Clear(MobTrackingSetup);
        MobTrackingSetup.DetermineItemTrackingRequiredByAssemblyHeader(_AssemblyHeader, ExpDateRequired);
        // MobTrackingSetup.Tracking: Tracking values are unused in this scope

        _BaseOrderLine.SetTracking(MobTrackingSetup);   // Set empty "Serial No." / "Lot No." / "Package No." to include tags in xml
        _BaseOrderLine.SetRegisterTracking(MobTrackingSetup);
        _BaseOrderLine.Set_RegisterExpirationDate(ExpDateRequired);

        // If the <RegisterQuantityByScan> element is set to true the mobile device can use values in <BarcodeQuantity>
        // element to register the quantity associated with barcode instead of always registering 1.
        _BaseOrderLine.Set_RegisterQuantityByScan(false);
        _BaseOrderLine.Set_RegisteredQuantity(0);

        // Set Quantity and UnitOfMeasure based on MobSetup."Use Base Unit of Measure"
        _BaseOrderLine.Set_Quantity(MobSetup."Use Base Unit of Measure", _AssemblyHeader."Quantity to Assemble (Base)", _AssemblyHeader."Quantity to Assemble");
        _BaseOrderLine.Set_UnitOfMeasure(MobSetup."Use Base Unit of Measure" and Item.Get(_AssemblyHeader."Item No."), Item."Base Unit of Measure", _AssemblyHeader."Unit of Measure Code");

        // Decide what to display on the lines
        // There are 9 display lines available. Lines 2 to 9 is compressed to new tag "CompressedDisplayLine2To9" after events
        // Line 1: Show the Bin (if Bin Mandatory), otherwise Item No.
        // Line 2: Show the Item Number (UoM is displayed in Quantity-step helplabel) + Item Description
        // Line 3: Show the Lot Info
        // Line 4: Show the Serial Info
        // Line 5: Show the Item Variant
        _BaseOrderLine.Set_DisplayLine1(_BaseOrderLine.Get_ToBin() <> '', _BaseOrderLine.Get_ToBin(), '');
        if _BaseOrderLine.Get_DisplayLine1() = '' then begin
            _BaseOrderLine.Set_DisplayLine1(_AssemblyHeader."Item No.");
            _BaseOrderLine.Set_DisplayLine2(_AssemblyHeader.Description);
        end else
            _BaseOrderLine.Set_DisplayLine2(_AssemblyHeader."Item No." + '  ' + _AssemblyHeader.Description);

        _BaseOrderLine.Set_DisplayLine3(_AssemblyHeader."Variant Code" <> '', MobWmsLanguage.GetMessage('VARIANT_LABEL') + ': ' + _AssemblyHeader."Variant Code", '');

        ExtraInfo1_Col1.Add('Qty. to Assemble');
        ExtraInfo1_Col2.Add(StrSubstNo('%1 %2', _AssemblyHeader."Quantity to Assemble", _AssemblyHeader."Unit of Measure Code"));
        ExtraInfo2_Col1.Add(MobWmsLanguage.GetMessage('REMAINING_QTY'));
        ExtraInfo2_Col2.Add(StrSubstNo('%1 %2', _AssemblyHeader."Remaining Quantity", _AssemblyHeader."Unit of Measure Code"));

        _BaseOrderLine.SetValue('ExtraInfo1_Col1', MobWmsToolbox.List2TextLn(ExtraInfo1_Col1, 999));
        _BaseOrderLine.SetValue('ExtraInfo1_Col2', MobWmsToolbox.List2TextLn(ExtraInfo1_Col2, 999));
        _BaseOrderLine.SetValue('ExtraInfo2_Col1', MobWmsToolbox.List2TextLn(ExtraInfo2_Col1, 999));
        _BaseOrderLine.SetValue('ExtraInfo2_Col2', MobWmsToolbox.List2TextLn(ExtraInfo2_Col2, 999));

        // The choices are: None, Warn, Block
        _BaseOrderLine.Set_UnderDeliveryValidation('Block');
        _BaseOrderLine.Set_OverDeliveryValidation('Block');

        _BaseOrderLine.Set_ReferenceID(_AssemblyHeader);
        _BaseOrderLine.Set_Status('0');
        _BaseOrderLine.Set_Attachment();
        _BaseOrderLine.Set_ItemImageID();

        // Integration Events
        OnGetAssemblyOrderLines_OnAfterSetFromAssemblyHeader(_AssemblyHeader, _BaseOrderLine);

        TempSteps.SetMustCallCreateNext(true);
        OnGetAssemblyOrderLines_OnAddStepsToOutputLine(_AssemblyHeader, _BaseOrderLine, TempSteps);
        if not TempSteps.IsEmpty() then
            _BaseOrderLine.Set_Workflow(TempSteps, "MOB TweakType"::Append);

        // Compressed display lines 2 to 9 (after integration events to change display lines)
        _BaseOrderLine.GetDisplayLinesAsList(DisplayLine2To9List, 2, 9);
        MobWmsToolbox.ListTrimBlank(DisplayLine2To9List, 2);
        _BaseOrderLine.SetValue('CompressedDisplayLine2To9', MobWmsToolbox.List2TextLn(DisplayLine2To9List, 999));
    end;

    local procedure SetFromAssemblyLine(_AssemblyLine: Record "Assembly Line"; _TempTrackingSpecification: Record "Tracking Specification"; var _BaseOrderLine: Record "MOB NS BaseDataModel Element")
    var
        MobSetup: Record "MOB Setup";
        MobTrackingSetup: Record "MOB Tracking Setup";
        TempSteps: Record "MOB Steps Element" temporary;
        Location: Record Location;
        Item: Record Item;
        MobCommonMgt: Codeunit "MOB Common Mgt.";
        ExpDateRequired: Boolean;
        DisplayLine2To9List: List of [Text];
        ExtraInfo1_Col1: List of [Text];
        ExtraInfo1_Col2: List of [Text];
        ExtraInfo2_Col1: List of [Text];
        ExtraInfo2_Col2: List of [Text];
    begin
        MobSetup.Get();

        if not Location.Get(_AssemblyLine."Location Code") then
            Clear(Location);

        // Add the data to the order line element
        _BaseOrderLine.Init();
        _BaseOrderLine.Set_OrderBackendID(_AssemblyLine."Document No.");
        _BaseOrderLine.Set_Location(Location.Code);

        // Add the data to the order line element        
        if _TempTrackingSpecification."Entry No." = 0 then
            _BaseOrderLine.Set_LineNumber(Format(_AssemblyLine."Line No."))
        else
            _BaseOrderLine.Set_LineNumber(CreatePrefixedLineNumberAsPostfix(_AssemblyLine."Line No.", _TempTrackingSpecification."Entry No.")); // to avoid redundant lines error at mobile device but not actually used during posting

        _BaseOrderLine.Set_ItemNumber(_AssemblyLine."No.");

        if _AssemblyLine.Type = _AssemblyLine.Type::Item then
            _BaseOrderLine.Set_ItemBarcode(MobItemReferenceMgt.GetBarcodeList(_AssemblyLine."No.", _AssemblyLine."Variant Code", _AssemblyLine."Unit of Measure Code"))
        else
            _BaseOrderLine.Set_ItemBarcode(_AssemblyLine."No.");  // Fallback to No. for non-item types

        _BaseOrderLine.Set_Description(_AssemblyLine.Description);

        // FromBin
        if Location."Bin Mandatory" and MobCommonMgt.AssemblyLine_IsInventoriableItem(_AssemblyLine) then begin
            _BaseOrderLine.Set_FromBin(_AssemblyLine."Bin Code");
            _BaseOrderLine.Set_ValidateFromBin(true);
            _BaseOrderLine.Set_AllowBinChange(true);
        end else begin
            // No location or no mandatory bin -> no bin validation
            _BaseOrderLine.Set_FromBin(MobWmsToolbox.GetItemShelfNo(_AssemblyLine."No.", _AssemblyLine."Location Code", _AssemblyLine."Variant Code"));
            _BaseOrderLine.Set_ValidateFromBin(_BaseOrderLine.Get_FromBin() <> '');
            _BaseOrderLine.Set_AllowBinChange(false);
        end;

        _BaseOrderLine.Set_ToBin('');
        _BaseOrderLine.Set_ValidateToBin(false);

        // Determine if serial / lot number registration is needed
        // Lot and serial no. should not be validated regardless of setup.
        MobTrackingSetup.DetermineItemTrackingRequiredByAssemblyLine(_AssemblyLine, ExpDateRequired);
        MobTrackingSetup.CopyTrackingFromTrackingSpec(_TempTrackingSpecification);

        _BaseOrderLine.SetTracking(MobTrackingSetup);
        _BaseOrderLine.SetRegisterTracking(MobTrackingSetup);
        _BaseOrderLine.Set_RegisterExpirationDate(ExpDateRequired);

        // If the <RegisterQuantityByScan> element is set to true the mobile device can use values in <BarcodeQuantity>
        // element to register the quantity associated with barcode instead of always registering 1.
        _BaseOrderLine.Set_RegisterQuantityByScan(false);
        _BaseOrderLine.Set_RegisteredQuantity(0);

        // The quantity on the mobile device is always in base UoM
        if _TempTrackingSpecification."Entry No." = 0 then
            _BaseOrderLine.Set_Quantity(MobSetup."Use Base Unit of Measure", _AssemblyLine."Quantity to Consume (Base)", _AssemblyLine."Quantity to Consume")
        else
            _BaseOrderLine.Set_Quantity(MobSetup."Use Base Unit of Measure", Abs(_TempTrackingSpecification."Qty. to Handle (Base)"), Abs(_TempTrackingSpecification."Qty. to Handle"));

        // The mobile device always works in the base unit of measure
        _BaseOrderLine.Set_UnitOfMeasure(
            MobSetup."Use Base Unit of Measure" and (_AssemblyLine.Type = _AssemblyLine.Type::Item) and Item.Get(_AssemblyLine."No."),
            Item."Base Unit of Measure",
            _AssemblyLine."Unit of Measure Code");

        // Decide what to display on the lines
        // There are 9 display lines available. Lines 2 to 9 is compressed to new tag "CompressedDisplayLine2To9" after events
        // Line 1: Show the Bin (if Bin Mandatory), otherwise Item No.
        // Line 2: Show the Item Number (UoM is displayed in Quantity-step helplabel) + Item Description
        // Line 3: Show the Lot Info
        // Line 4: Show the Serial Info
        // Line 5: Show the Item Variant
        _BaseOrderLine.Set_DisplayLine1(_BaseOrderLine.Get_FromBin() <> '', '   ' + _BaseOrderLine.Get_FromBin(), '');
        if _BaseOrderLine.Get_DisplayLine1() = '' then begin
            _BaseOrderLine.Set_DisplayLine1('   ' + _AssemblyLine."No.");   // Intentionally one less blank space due to bold font
            _BaseOrderLine.Set_DisplayLine2('    ' + _AssemblyLine.Description);
        end else
            _BaseOrderLine.Set_DisplayLine2('    ' + _AssemblyLine."No." + '  ' + _AssemblyLine.Description);

        _BaseOrderLine.Set_DisplayLine3(MobTrackingSetup.FormatTracking('    %1')); // Using a FormatExpr to have each separate tracking dimension indented in the returning string
        _BaseOrderLine.Set_DisplayLine4('');
        _BaseOrderLine.Set_DisplayLine5(_AssemblyLine."Variant Code" <> '', '    ' + MobWmsLanguage.GetMessage('VARIANT_LABEL') + ': ' + _AssemblyLine."Variant Code", '');

        // Write details for Resource and Item lines
        if _AssemblyLine.Type <> _AssemblyLine.Type::" " then begin
            ExtraInfo1_Col1.Add(MobWmsLanguage.GetMessage('QUANTITY_PER'));
            ExtraInfo1_Col2.Add(StrSubstNo('%1 %2', _AssemblyLine."Quantity per", _AssemblyLine."Unit of Measure Code"));

            if Location."Require Pick" and Location."Require Shipment" then begin     // Condition from standard posting in "Whse. Validate Source Line".ItemLineVerifyChange()
                ExtraInfo2_Col1.Add(MobWmsLanguage.GetMessage('PICKED_QTY'));
                if _AssemblyLine."Qty. Picked" = _AssemblyLine."Remaining Quantity" then
                    ExtraInfo2_Col2.Add(StrSubstNo('%1 %2', MobWmsToolbox.Decimal2TextAsDisplayFormat(_AssemblyLine."Qty. Picked"), _AssemblyLine."Unit of Measure Code"))
                else
                    ExtraInfo2_Col2.Add(StrSubstNo('%1 / %2 %3', MobWmsToolbox.Decimal2TextAsDisplayFormat(_AssemblyLine."Qty. Picked"), MobWmsToolbox.Decimal2TextAsDisplayFormat(_AssemblyLine."Remaining Quantity"), _AssemblyLine."Unit of Measure Code"))
            end else begin
                ExtraInfo2_Col1.Add(MobWmsLanguage.GetMessage('REMAINING_QTY'));
                ExtraInfo2_Col2.Add(StrSubstNo('%1 %2', MobWmsToolbox.Decimal2TextAsDisplayFormat(_AssemblyLine."Remaining Quantity"), _AssemblyLine."Unit of Measure Code"));
            end;

            _BaseOrderLine.SetValue('ExtraInfo1_Col1', '    ' + MobWmsToolbox.List2TextLn(ExtraInfo1_Col1, 999));
            _BaseOrderLine.SetValue('ExtraInfo1_Col2', '    ' + MobWmsToolbox.List2TextLn(ExtraInfo1_Col2, 999));
            _BaseOrderLine.SetValue('ExtraInfo2_Col1', '    ' + MobWmsToolbox.List2TextLn(ExtraInfo2_Col1, 999));
            _BaseOrderLine.SetValue('ExtraInfo2_Col2', '    ' + MobWmsToolbox.List2TextLn(ExtraInfo2_Col2, 999));
        end;

        // The choices are: None, Warn, Block
        _BaseOrderLine.Set_UnderDeliveryValidation('Block');
        _BaseOrderLine.Set_OverDeliveryValidation('Block');

        _BaseOrderLine.Set_ReferenceID(_AssemblyLine);
        _BaseOrderLine.Set_Status('0');
        _BaseOrderLine.Set_Attachment();
        _BaseOrderLine.Set_ItemImageID();

        // Integration Events
        OnGetAssemblyOrderLines_OnAfterSetFromAssemblyLine(_AssemblyLine, _TempTrackingSpecification, _BaseOrderLine);

        TempSteps.SetMustCallCreateNext(true);
        OnGetAssemblyOrderLines_OnAddStepsToConsumptionLine(_AssemblyLine, _TempTrackingSpecification, _BaseOrderLine, TempSteps);    // Set ExtraInfo key hence no RegistrationCollector is returned or set
        if not TempSteps.IsEmpty() then
            _BaseOrderLine.Set_Workflow(TempSteps, "MOB TweakType"::Append);

        // Compressed display lines 2 to 9 (after integration events to change display lines)
        _BaseOrderLine.GetDisplayLinesAsList(DisplayLine2To9List, 2, 9);
        MobWmsToolbox.ListTrimBlank(DisplayLine2To9List, 2);
        _BaseOrderLine.SetValue('CompressedDisplayLine2To9', MobWmsToolbox.List2TextLn(DisplayLine2To9List, 999));
    end;

    /// <summary>
    /// Create 'LineNumber' from parts (the prefix is after " - " so really a postfix, will be parsed from SaveRegistrationData when string includes the " - ")
    /// Lines with no TrackingSpec."Entry No." will still get the suffix after component line no. i.e. "10000 - 0"
    /// </summary>
    local procedure CreatePrefixedLineNumberAsPostfix(_AssemblyLineNo: Integer; _TrackingSpecEntryNo: Integer): Text
    begin
        exit(Format(_AssemblyLineNo) + ' - ' + Format(_TrackingSpecEntryNo));
    end;

    //
    // ------- IntegrationEvents: GetAssemblyOrders -------
    //
    // OnGetAssemblyOrders_OnSetFilterAssemblyHeader
    // OnGetAssemblyOrders_OnIncludeAssemblyHeader
    // OnGetAssemblyOrders_OnAfterSetFromAssemblyHeader
    // OnGetAssemblyOrders_OnAfterSetCurrentKey

    [IntegrationEvent(false, false)]
    local procedure OnGetAssemblyOrders_OnSetFilterAssemblyHeader(_HeaderFilter: Record "MOB NS Request Element"; var _AssemblyHeader: Record "Assembly Header"; var _AssemblyLine: Record "Assembly Line"; var _IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetAssemblyOrders_OnIncludeAssemblyHeader(_AssemblyHeader: Record "Assembly Header"; var _IncludeInOrderList: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetAssemblyOrders_OnAfterSetFromAssemblyHeader(_AssemblyHeader: Record "Assembly Header"; var _BaseOrderElement: Record "MOB NS BaseDataModel Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetAssemblyOrders_OnAfterSetCurrentKey(var _BaseOrderElementView: Record "MOB NS BaseDataModel Element")
    begin
    end;

    //
    // ------- IntegrationEvents: GetAssemblyOrderLines -------
    //
    // OnGetAssemblyOrderLines_OnSetFilterAssemblyLine
    // OnGetAssemblyOrderLines_OnIncludeAssemblyLine
    // OnGetAssemblyOrderLines_OnAfterSetFromAssemblyHeader
    // OnGetAssemblyOrderLines_OnAfterSetFromAssemblyLine
    // OnGetAssemblyOrderLines_OnAfterSetCurrentKey
    // OnGetAssemblyOrderLines_OnAddStepsToAssemblyHeader
    // OnGetAssembleOrderLines_OnAddStepsToOutputLine
    // OnGetAssemblyOrderLines_OnAddStepsToConsumptionLine

    [IntegrationEvent(false, false)]
    local procedure OnGetAssemblyOrderLines_OnSetFilterAssemblyLine(var _AssemblyLine: Record "Assembly Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetAssemblyOrderLines_OnIncludeAssemblyLine(_AssemblyLine: Record "Assembly Line"; var _IncludeInOrderLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetAssemblyOrderLines_OnAfterSetFromAssemblyHeader(_AssemblyHeader: Record "Assembly Header"; var _BaseOrderLineElement: Record "MOB NS BaseDataModel Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetAssemblyOrderLines_OnAfterSetFromAssemblyLine(_AssemblyLine: Record "Assembly Line"; _TrackingSpecification: Record "Tracking Specification"; var _BaseOrderLineElement: Record "MOB NS BaseDataModel Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetAssemblyOrderLines_OnAfterSetCurrentKey(var _BaseOrderLineElementView: Record "MOB NS BaseDataModel Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetAssemblyOrderLines_OnAddStepsToAssemblyHeader(_AssemblyHeader: Record "Assembly Header"; var _Steps: Record "MOB Steps Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetAssemblyOrderLines_OnAddStepsToOutputLine(_AssemblyHeader: Record "Assembly Header"; var _BaseOrderLineElement: Record "MOB NS BaseDataModel Element"; var _Steps: Record "MOB Steps Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetAssemblyOrderLines_OnAddStepsToConsumptionLine(_AssemblyLine: Record "Assembly Line"; _TrackingSpecification: Record "Tracking Specification"; var _BaseOrderLineElement: Record "MOB NS BaseDataModel Element"; var _Steps: Record "MOB Steps Element")
    begin
    end;


    //
    // ------- IntegrationEvents: PostAssemblyOrder -------
    //
    // OnPostAssemblyOrder_OnBeforePostAssemblyOrder
    // OnPostAssemblyOrder_OnHandleRegistrationForAssemblyHeader
    // OnPostAssemblyOrder_OnHandleRegistrationForAssemblyLine    

    [IntegrationEvent(false, false)]
    local procedure OnPostAssemblyOrder_OnBeforePostAssemblyOrder(var _OrderValues: Record "MOB Common Element"; var _AssemblyHeader: Record "Assembly Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostAssemblyOrder_OnHandleRegistrationForAssemblyHeader(var _Registration: Record "MOB WMS Registration"; var _AssemblyHeader: Record "Assembly Header"; var _NewReservationEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostAssemblyOrder_OnHandleRegistrationForAssemblyLine(var _Registration: Record "MOB WMS Registration"; var _AssemblyLine: Record "Assembly Line"; var _NewReservationEntry: Record "Reservation Entry")
    begin
    end;

}
