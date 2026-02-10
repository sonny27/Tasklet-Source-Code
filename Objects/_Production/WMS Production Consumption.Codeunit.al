codeunit 81403 "MOB WMS Production Consumption"
{
    Access = Public;
    TableNo = "MOB Document Queue";

    var
        MobSessionData: Codeunit "MOB SessionData";
        MobItemSubst: Codeunit "MOB Item Subst.";

    trigger OnRun()
    var
        MobDocQueue: Record "MOB Document Queue";
        XmlResponseDoc: XmlDocument;
    begin
        MobDocQueue := Rec;

        case Rec."Document Type" of

            // Order headers (prod. order lines)
            'GetProdOrderLines':
                GetProdOrderLines(MobDocQueue, XmlResponseDoc);

            // Order consumption lines
            'GetProdConsumptionLines':
                GetProdConsumptionLines(MobDocQueue, XmlResponseDoc);

            // Posting
            'PostProdConsumption':
                PostProdConsumption(MobDocQueue, XmlResponseDoc);

            else
                Error(MobWmsLanguage.GetMessage('NO_DOC_HANDLER'), Rec."Document Type");
        end;

        // Store the result in the queue and update the status
        MobToolbox.UpdateResult(Rec, XmlResponseDoc);
    end;


    //
    // Run Actions
    // 
    procedure RunLookup(_LookupType: Text[50]; var _RequestValues: Record "MOB NS Request Element"; var _LookupResponse: Record "MOB NS WhseInquery Element"; var _ReturnRegistrationTypeTracking: Text)
    var
        MobWmsLookup: Codeunit "MOB WMS Lookup";
    begin
        case _LookupType of
            // Order output lines
            MobWmsLookup."CONST::SubstituteProdOrderComponent"():
                LookupSubstituteProdOrderComponent(_RequestValues, _LookupResponse, _ReturnRegistrationTypeTracking)
            else
                Error(MobWmsLanguage.GetMessage('NO_DOC_HANDLER'), 'Lookup.' + _LookupType);
        end;
    end;

    procedure RunPostAdhocRegistration(_RegistrationType: Text; var _RequestValues: Record "MOB NS Request Element"; var _SuccessMessage: Text; var _ReturnRegistrationTypeTracking: Text)
    begin
        case _RegistrationType of
            // Posting from Consumption Actions
            MobWmsToolbox."CONST::SubstituteProdOrderComponent"():
                PostSubstituteProdOrderComponent(_RequestValues, _SuccessMessage, _ReturnRegistrationTypeTracking)
            else
                Error(MobWmsLanguage.GetMessage('NO_DOC_HANDLER'), 'PostAdhocRegistration.' + _RegistrationType);
        end;
    end;

    var
        MobRequestMgt: Codeunit "MOB NS Request Management";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
        MobToolbox: Codeunit "MOB Toolbox";
        MUST_BE_TEMPORARY_Err: Label 'Internal error: %1 must be a temporary record.', Locked = true;


    //
    // Lookup SubstituteProdOrderComponent
    // 
    local procedure LookupSubstituteProdOrderComponent(var _RequestValues: Record "MOB NS Request Element"; var _LookupResponse: Record "MOB NS WhseInquery Element"; var _ReturnRegistrationTypeTracking: Text)
    var
        ToItem: Record Item;
        ProdOrderComp: Record "Prod. Order Component";
        TempItemSubstitution: Record "Item Substitution" temporary;
        TempSteps: Record "MOB Steps Element" temporary;
        ItemSubst: Codeunit "Item Subst.";
        MobWmsLookup: Codeunit "MOB WMS Lookup";
        ProdOrderCompRecordId: RecordId;
    begin
        // Find the Prod. Order Component the substitution is for (the ReferenceID tag must be at the ContextValues-level in the Xml)
        Clear(ProdOrderComp);
        Evaluate(ProdOrderCompRecordId, _RequestValues.GetContextValue('ReferenceID', true));
        ProdOrderComp.Get(ProdOrderCompRecordId);

        _ReturnRegistrationTypeTracking := DelChr(ProdOrderComp."Item No." + ' - ' + ProdOrderComp."Variant Code" + ' - ' + ProdOrderComp."Unit of Measure Code" + ' - ' + Format(ProdOrderComp."Due Date"), '<>', ' - ');

        // From MfgItemSubstitution.GetProdOrderCompSubst
        if not MobItemSubst.FindItemSubstitutions(
            TempItemSubstitution,
            ProdOrderComp."Item No.",
            ProdOrderComp."Variant Code",
            ProdOrderComp."Location Code",
            ProdOrderComp."Due Date",
            true)
        then
            ItemSubst.ErrorMessage(ProdOrderComp."Item No.", ProdOrderComp."Variant Code");

        TempItemSubstitution.Reset();
        if TempItemSubstitution.FindSet() then
            repeat
                // Collect the buffer values for the <LookupResponse> element
                _LookupResponse.Create();
                MobWmsLookup.SetFromLookupSubstituteItem(TempItemSubstitution, _LookupResponse);  // Reusing existing Response elements from subtitute items, but adding step below

                // ItemNumber / VariantCode from LookupResponseElement is overridden by HeaderField values in PostRequest -- need to store values as a new tag
                _LookupResponse.SetValue('SubstituteNo', TempItemSubstitution."Substitute No.");
                _LookupResponse.SetValue('SubstituteVariantCode', TempItemSubstitution."Substitute Variant Code");

                ToItem.Get(TempItemSubstitution."Substitute No.");

                TempSteps.DeleteAll();
                TempSteps.Create_InformationStep(10, 'Information');
                TempSteps.Set_header(MobWmsLanguage.GetMessage('SUBSTITUTE_COMPONENT'));
                TempSteps.Set_helpLabel(
                    StrSubstNo('<p><strong>%1</strong><br>%2 %3 %4</p><p><br> ' + MobWmsLanguage.GetMessage('SUBSTITUTE_WITH') + ' </p><p><strong>%5</strong><br>%6 %7 %8?</p>',
                        ProdOrderComp."Item No.",
                        ProdOrderComp.Description,
                        ProdOrderComp."Variant Code",
                        ProdOrderComp."Unit of Measure Code",
                        ToItem."No.",
                        ToItem.Description,
                        TempItemSubstitution."Substitute Variant Code",
                        ToItem."Base Unit of Measure"));

                _LookupResponse.SetRegistrationCollector(TempSteps);
                _LookupResponse.Save();

            until TempItemSubstitution.Next() = 0;
    end;

    //
    // Adhoc Post SubstituteProdOrderComponent
    //

    local procedure PostSubstituteProdOrderComponent(var _RequestValues: Record "MOB NS Request Element"; var _SuccessMessage: Text; var _ReturnRegistrationTypeTracking: Text)
    var
        ProdOrderComp: Record "Prod. Order Component";
        ProdOrderCompRecordId: RecordId;
        SubstituteNo: Code[20];
        SubstituteVariantCode: Code[10];
    begin
        // ItemNumber / VariantCode from LookupResponseElement is overridden by HeaderField values in PostRequest -- read values from new tags that was stored in LookupSubstituteProdOrderComponent()
        Evaluate(SubstituteNo, _RequestValues.GetValue('SubstituteNo'));
        Evaluate(SubstituteVariantCode, _RequestValues.GetValue('SubstituteVariantCode'));

        _ReturnRegistrationTypeTracking := DelChr(StrSubstNo('%1 - %2', SubstituteNo, SubstituteVariantCode), '<>', ' - ');

        // Find the Prod. Order Component the substitution is for (the ReferenceID tag must be at the ContextValues-level in the Xml)
        Clear(ProdOrderComp);
        Evaluate(ProdOrderCompRecordId, _RequestValues.GetContextValue('ReferenceID', true));
        ProdOrderComp.Get(ProdOrderCompRecordId);

        MobItemSubst.UpdateProdOrderComp(ProdOrderComp, SubstituteNo, SubstituteVariantCode);
        ProdOrderComp.Modify(true); // Must modify prior to AutoReserve
        ProdOrderComp.AutoReserve();

        // Create a response inside the <description> element of the document response
        // SuccessMessage is not displayed at mobile device since subsitute component page is closed on success
        _SuccessMessage := 'OK';
    end;

    //
    // -------  GetProdOrderLines -------
    //

    local procedure GetProdOrderLines(_MobDocQueue: Record "MOB Document Queue"; var _XmlResponseDoc: XmlDocument)
    var
        TempHeaderElement: Record "MOB NS BaseDataModel Element" temporary;
        XmlRequestDoc: XmlDocument;
        OrdersXmlResponseData: XmlNode;
    begin
        // Process:
        // 1. Filter and sort the Production Order Lines for this particular user
        // 2. Save the result in XML and return it to the mobile device

        // Load the request from the queue
        _MobDocQueue.LoadXMLRequestDoc(XmlRequestDoc);

        // Initialize the response document for order data
        MobToolbox.InitializeResponseDoc(_XmlResponseDoc, OrdersXmlResponseData);

        // Create the response for the mobile device
        CreateProdOrderLinesResponse(XmlRequestDoc, _MobDocQueue, TempHeaderElement);

        // Add collected buffer values to new <Orders> nodes
        AddBaseOrderElements(OrdersXmlResponseData, TempHeaderElement);
    end;

    /// <summary>
    /// Loop through the Production Order (Lines) and add the information that should be available
    /// on the mobile device to the XML. The only elements that MUST be present in the XML are "BackendID", "Status" and "Sorting".
    /// Other values can be added freely and used in Mobile WMS by referencing the element name from the XML.
    /// </summary>
    local procedure CreateProdOrderLinesResponse(var _XmlRequestDoc: XmlDocument; var _MobDocQueue: Record "MOB Document Queue"; var _BaseOrderElement: Record "MOB NS BaseDataModel Element")
    var
        ProdOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        TempProdOrderLine: Record "Prod. Order Line" temporary;
        TempHeaderFilter: Record "MOB NS Request Element" temporary;
        TempEmptyHeaderFilter: Record "MOB NS Request Element" temporary;
        MobItemReferenceMgt: Codeunit "MOB Item Reference Mgt.";
        WorkCenterFilter: Text;
        StartingDate: Date;
        VariantCode: Code[10];
        IsHandled: Boolean;
    begin

        // Mandatory Header filters for this function to operate
        ProdOrder.Reset();
        ProdOrder.SetRange(Status, ProdOrder.Status::Released);
        ProdOrder.SetRange(Blocked, false);

        ProdOrderLine.Reset();
        ProdOrderLine.SetCurrentKey(Status, "Starting Date-Time", "Prod. Order No.", "Line No.", "Item No.");   // Order by "Starting Date-Time" (however field is not a part of actual key)
        ProdOrderLine.SetRange(Status, ProdOrderLine.Status::Released);
        ProdOrderLine.SetFilter("Item No.", '<>%1', '');

        // XML filter data into Temporary table
        MobRequestMgt.SaveHeaderFilters(_XmlRequestDoc, TempHeaderFilter);

        if TempHeaderFilter.FindSet() then
            repeat
                //
                // Event to allow for handling (custom) filters
                //
                IsHandled := false;
                OnGetProdOrderLines_OnSetFilterProdOrderLine(TempHeaderFilter, ProdOrderLine, ProdOrder, IsHandled);

                if not IsHandled then
                    case TempHeaderFilter.Name of

                        'Location':
                            if TempHeaderFilter."Value" = 'All' then
                                ProdOrderLine.SetFilter("Location Code", MobWmsToolbox.GetLocationFilter(UserId())) // All locations for this user
                            else
                                ProdOrderLine.SetRange("Location Code", TempHeaderFilter."Value");

                        'StartingDate':
                            begin
                                StartingDate := TempHeaderFilter.GetValueAsDate();
                                if StartingDate <> 0D then
                                    ProdOrderLine.SetFilter("Starting Date", '<=%1', StartingDate);
                            end;

                        'ProductionProgress':
                            case TempHeaderFilter."Value" of
                                'All':
                                    ; // No filter -> do nothing
                                'Ready':
                                    ProdOrderLine.SetFilter("Remaining Quantity", '>0');
                                'Completed':
                                    ProdOrderLine.SetRange("Remaining Quantity", 0);
                            end;

                        'WorkCenterFilter':
                            WorkCenterFilter := TempHeaderFilter."Value";

                        'AssignedUser':
                            case TempHeaderFilter."Value" of
                                'All':
                                    ; // No filter -> do nothing
                                'OnlyMine':
                                    ProdOrder.SetRange("Assigned User ID", _MobDocQueue."Mobile User ID");  // Current user
                                'MineAndUnassigned':
                                    ProdOrder.SetFilter("Assigned User ID", '''''|%1', _MobDocQueue."Mobile User ID"); // Current user or blank
                            end;

                        'ScannedValue':
                            if ProdOrder.Get(ProdOrder.Status::Released, TempHeaderFilter."Value") then
                                ProdOrderLine.SetRange("Prod. Order No.", TempHeaderFilter."Value")
                            else begin
                                ProdOrderLine.SetRange("Item No.", MobItemReferenceMgt.SearchItemReference(MobToolbox.ReadEAN(TempHeaderFilter."Value"), VariantCode));
                                if VariantCode <> '' then
                                    ProdOrderLine.SetRange("Variant Code", VariantCode);
                            end;
                    end;

            until TempHeaderFilter.Next() = 0;

        // Run event once more with Empty "Header filter" to allow for additional filtering directly on the records, NOT related to specific Header filter        
        IsHandled := false;
        OnGetProdOrderLines_OnSetFilterProdOrderLine(TempEmptyHeaderFilter, ProdOrderLine, ProdOrder, IsHandled);

        // Insert orders into temp rec
        CopyFilteredProdOrderLinesToTempRecord(ProdOrderLine, ProdOrder, WorkCenterFilter, TempProdOrderLine);

        // Respond with resulting orders
        SetProdOrderLinesResponse(TempProdOrderLine, _BaseOrderElement, TempHeaderFilter);
    end;

    /// <summary>
    /// Transfer filtered orders into temp record
    /// </summary>
    local procedure CopyFilteredProdOrderLinesToTempRecord(var _ProdOrderLineView: Record "Prod. Order Line"; var _ProdOrderView: Record "Production Order"; _WorkCenterFilter: Text; var _TempProdOrderLine: Record "Prod. Order Line")
    var
        IncludeInOrderList: Boolean;
    begin
        if _ProdOrderLineView.FindSet() then
            repeat
                // Insert Only if header within filters
                _ProdOrderView.FilterGroup(2);
                _ProdOrderView.SetRange("No.", _ProdOrderLineView."Prod. Order No.");
                _ProdOrderView.FilterGroup(0);
                IncludeInOrderList := not _ProdOrderView.IsEmpty();

                // Insert only if within Work Center filter
                IncludeInOrderList := IncludeInOrderList and IsProdOrderInWorkCenterFilter(_ProdOrderLineView, _WorkCenterFilter);

                // Verify additional conditions from eventsubscribers
                OnGetProdOrderLines_OnIncludeProdOrderLine(_ProdOrderLineView, IncludeInOrderList);

                if IncludeInOrderList then begin
                    _TempProdOrderLine.Copy(_ProdOrderLineView);
                    _TempProdOrderLine.Insert();
                end;
            until _ProdOrderLineView.Next() = 0;
    end;

    /// <summary>
    /// Prod Order has routing lines within workcenter filter
    /// </summary>
    local procedure IsProdOrderInWorkCenterFilter(_ProdOrderLine: Record "Prod. Order Line"; _WorkCenterFilter: Text): Boolean
    var
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
    begin
        if _WorkCenterFilter in ['All', ''] then // If filter is not handled, return true
            exit(true);

        ProdOrderRtngLine.Reset();
        ProdOrderRtngLine.SetRange("Prod. Order No.", _ProdOrderLine."Prod. Order No.");
        ProdOrderRtngLine.SetRange("Routing No.", _ProdOrderLine."Routing No.");
        ProdOrderRtngLine.SetRange(Status, _ProdOrderLine.Status);
        ProdOrderRtngLine.SetRange("Routing Reference No.", _ProdOrderLine."Routing Reference No.");
        ProdOrderRtngLine.SetRange("Work Center No.", _WorkCenterFilter);
        exit(not ProdOrderRtngLine.IsEmpty());
    end;

    local procedure SetProdOrderLinesResponse(var _ProdOrderLine: Record "Prod. Order Line"; var _BaseOrderElement: Record "MOB NS BaseDataModel Element"; var _TempHeaderFilter: Record "MOB NS Request Element")
    begin
        if _ProdOrderLine.FindSet() then
            repeat
                _BaseOrderElement.Create();
                SetFromProdOrderLine(_ProdOrderLine, _BaseOrderElement, _TempHeaderFilter);
                _BaseOrderElement.Save();
            until _ProdOrderLine.Next() = 0;
    end;

    //
    // -------  GetProdConsumptionLines -------
    //

    local procedure GetProdConsumptionLines(_MobDocQueue: Record "MOB Document Queue"; var _XmlResponseDoc: XmlDocument)
    var
        TempRequestValues: Record "MOB NS Request Element" temporary;
        BackendID: Code[40];
    begin
        // Get the prefixed <BackendID> element
        _MobDocQueue.LoadAdhocRequestValues(TempRequestValues);
        BackendID := TempRequestValues.GetValue('BackendID', true);

        // Create the response for the mobile device
        CreateProdConsumptionLinesResponse(BackendID, _XmlResponseDoc);
    end;

    local procedure CreateProdConsumptionLinesResponse(_BackendID: Code[40]; var _XmlResponseDoc: XmlDocument)
    var
        MobSetup: Record "MOB Setup";
        ProdOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
        ProdOrderComp: Record "Prod. Order Component";
        TempBaseOrderLineElement: Record "MOB NS BaseDataModel Element" temporary;
        XmlResponseData: XmlNode;
        ProdOrderNo: Code[20];
        ProdOrderLineNo: Integer;
    begin
        MobSetup.Get();

        // Initialize the response document for order line data
        MobToolbox.InitializeOrderLineDataRespDoc(_XmlResponseDoc, XmlResponseData);

        // Extract the Order No and Line No. for the Prod. Order Line from the BackendID
        MobWmsToolbox.GetOrderNoAndOrderLineNoFromBackendId(_BackendID, ProdOrderNo, ProdOrderLineNo);
        ProdOrder.Get(ProdOrder.Status::Released, ProdOrderNo);
        ProdOrderLine.Get(ProdOrderLine.Status::Released, ProdOrderNo, ProdOrderLineNo);

        // Add collectorSteps to be displayed on posting
        AddStepsToProdOrderLine(ProdOrderLine, _XmlResponseDoc, XmlResponseData);

        ProdOrderRtngLine.Reset();
        ProdOrderRtngLine.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
        ProdOrderRtngLine.SetRange("Routing No.", ProdOrderLine."Routing No.");
        ProdOrderRtngLine.SetRange(Status, ProdOrderLine.Status);
        ProdOrderRtngLine.SetRange("Routing Reference No.", ProdOrderLine."Routing Reference No.");
        if ProdOrderRtngLine.FindSet() then begin
            InsertProdOrderComponents(_BackendID, ProdOrderLine, true, TempBaseOrderLineElement); //  No Routing Link or illegal Routing Link (Indent level 0 in Consumption Jnl.)
            repeat
                if ProdOrderRtngLine."Routing Link Code" <> '' then begin
                    ProdOrderComp.Reset();
                    ProdOrderComp.SetCurrentKey(Status, "Prod. Order No.", "Routing Link Code");
                    ProdOrderComp.SetRange(Status, ProdOrder.Status);
                    ProdOrderComp.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
                    ProdOrderComp.SetRange("Routing Link Code", ProdOrderRtngLine."Routing Link Code");
                    ProdOrderComp.SetRange("Prod. Order Line No.", ProdOrderLine."Line No.");
#pragma warning disable AL0432
                    ProdOrderComp.SetFilter("Flushing Method", '%1|%2', ProdOrderComp."Flushing Method"::Manual, 6); // 6 = ProdOrderComp."Flushing Method"::"Pick + Manual");
#pragma warning restore AL0432
                    ProdOrderComp.SetFilter("Item No.", '<>%1', '');
                    OnGetProdConsumptionLines_OnSetFilterProdOrderComponent(ProdOrderComp);
                    if ProdOrderComp.FindSet() then
                        repeat
                            InsertProdOrderComponent(TempBaseOrderLineElement, ProdOrderComp, ProdOrderLine, _BackendID);   // Indent level 1 in Consumption Jnl.
                        until ProdOrderComp.Next() = 0;
                end;
            until ProdOrderRtngLine.Next() = 0;
        end else
            // Insert All Components - No Routing Link Check
            InsertProdOrderComponents(_BackendID, ProdOrderLine, false, TempBaseOrderLineElement);   // Indent Level 0 in Consumption Jnl.

        // Insert the values from the prod. component lines in the XML
        AddBaseOrderLineElements(XmlResponseData, TempBaseOrderLineElement);
    end;

    local procedure AddStepsToProdOrderLine(_ProdOrderLine: Record "Prod. Order Line"; _XmlResponseDoc: XmlDocument; var _XmlResponseData: XmlNode)
    var
        TempSteps: Record "MOB Steps Element" temporary;
        MobXmlMgt: Codeunit "MOB XML Management";
        XmlSteps: XmlNode;
    begin
        TempSteps.SetMustCallCreateNext(true);
        OnGetProdConsumptionLines_OnAddStepsToProdOrderLine(_ProdOrderLine, TempSteps);

        if not TempSteps.IsEmpty() then begin
            // Adds Collector Configuration with <steps> {<add ... />} <steps/>
            MobToolbox.AddCollectorConfiguration(_XmlResponseDoc, _XmlResponseData, XmlSteps);
            MobXmlMgt.AddStepsaddElements(XmlSteps, TempSteps);
        end;
    end;

    local procedure InsertProdOrderComponents(_BackendID: Code[40]; _ProdOrderLine: Record "Prod. Order Line"; _CheckRoutingLink: Boolean; var _BaseOrderLineElement: Record "MOB NS BaseDataModel Element")
    var
        ProdOrderComp: Record "Prod. Order Component";
        ProdJournalMgt: Codeunit "Production Journal Mgt";
    begin
        // Components with no Routing Link or illegal Routing Link
        ProdOrderComp.Reset();
        ProdOrderComp.SetRange(Status, _ProdOrderLine.Status);
        ProdOrderComp.SetRange("Prod. Order No.", _ProdOrderLine."Prod. Order No.");
        ProdOrderComp.SetRange("Prod. Order Line No.", _ProdOrderLine."Line No.");
#pragma warning disable AL0432
        ProdOrderComp.SetFilter("Flushing Method", '%1|%2', ProdOrderComp."Flushing Method"::Manual, 6); // 6 = ProdOrderComp."Flushing Method"::"Pick + Manual");
#pragma warning restore AL0432
        ProdOrderComp.SetFilter("Item No.", '<>%1', '');
        OnGetProdConsumptionLines_OnSetFilterProdOrderComponent(ProdOrderComp);
        if ProdOrderComp.FindSet() then
            repeat
                if not _CheckRoutingLink then
                    InsertProdOrderComponent(_BaseOrderLineElement, ProdOrderComp, _ProdOrderLine, _BackendID)
                else
                    if not ProdJournalMgt.RoutingLinkValid(ProdOrderComp, _ProdOrderLine) then
                        InsertProdOrderComponent(_BaseOrderLineElement, ProdOrderComp, _ProdOrderLine, _BackendID);
            until ProdOrderComp.Next() = 0;
    end;

    local procedure InsertProdOrderComponent(var _BaseOrderLineElement: Record "MOB NS BaseDataModel Element"; _ProdOrderComp: Record "Prod. Order Component"; _ProdOrderLine: Record "Prod. Order Line"; _BackendID: Code[40])
    var
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        IncludeInOrderLines: Boolean;
    begin
        IncludeInOrderLines := true;

        // Verify additional conditions from eventsubscribers
        OnGetProdConsumptionLines_OnIncludeProdOrderComponent(_ProdOrderComp, IncludeInOrderLines);

        if IncludeInOrderLines then begin
            // Add the data to the order line element
            RetrieveProdOrderComponentItemTracking(_ProdOrderComp, TempTrackingSpecification);
            if TempTrackingSpecification.FindSet() then
                repeat
                    _BaseOrderLineElement.Create();
                    SetFromProdOrderComponent(_ProdOrderComp, TempTrackingSpecification, _ProdOrderLine, _BackendID, _BaseOrderLineElement);
                    _BaseOrderLineElement.Save();
                until TempTrackingSpecification.Next() = 0
            else begin
                Clear(TempTrackingSpecification);
                _BaseOrderLineElement.Create();
                SetFromProdOrderComponent(_ProdOrderComp, TempTrackingSpecification, _ProdOrderLine, _BackendID, _BaseOrderLineElement);
                _BaseOrderLineElement.Save();
            end;
        end;
    end;

    local procedure GetProdOrderRoutingLine(_ProdOrderComp: Record "Prod. Order Component"; var _ProdOrderRtngLine: Record "Prod. Order Routing Line"): Boolean
    begin
        Clear(_ProdOrderRtngLine);
        if _ProdOrderComp."Routing Link Code" = '' then
            exit(false);

        _ProdOrderRtngLine.Reset();
        _ProdOrderRtngLine.SetRange(Status, _ProdOrderComp.Status);
        _ProdOrderRtngLine.SetRange("Prod. Order No.", _ProdOrderComp."Prod. Order No.");
        _ProdOrderRtngLine.SetRange("Routing Link Code", _ProdOrderComp."Routing Link Code");
        exit(_ProdOrderRtngLine.FindFirst());
    end;

    local procedure RetrieveProdOrderComponentItemTracking(_ProdOrderComp: Record "Prod. Order Component"; var _TempTrackingSpecification: Record "Tracking Specification" temporary): Boolean
    var
        ReservEntry: Record "Reservation Entry";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        MobCommonMgt: Codeunit "MOB Common Mgt.";
    begin
        if not _TempTrackingSpecification.IsTemporary() then
            Error(MUST_BE_TEMPORARY_Err, _TempTrackingSpecification.TableCaption());    // SumUpItemTracking() will delete all content

        MobCommonMgt.SetSourceFilterForReservEntry(ReservEntry, Database::"Prod. Order Component", MobToolbox.AsInteger(_ProdOrderComp.Status), _ProdOrderComp."Prod. Order No.", _ProdOrderComp."Line No.", true);
        MobCommonMgt.SetSourceFilterForReservEntry(ReservEntry, '', _ProdOrderComp."Prod. Order Line No.");
        ReservEntry.SetFilter("Qty. to Handle (Base)", '<>0');

        // Sum up in a temporary table per component line:
        exit(ItemTrackingMgt.SumUpItemTracking(ReservEntry, _TempTrackingSpecification, true, true));
    end;

    //
    // ------- PostProdConsumption -------
    //

    local procedure PostProdConsumption(_MobDocQueue: Record "MOB Document Queue"; var _XmlResponseDoc: XmlDocument)
    var
        MobRegistration: Record "MOB WMS Registration";
        ConsumptionJnlLine: Record "Item Journal Line";
        ProdOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ItemJnlLine: Record "Item Journal Line";
        TempNewReservationEntry: Record "Reservation Entry" temporary;
        TempOrderValues: Record "MOB Common Element" temporary;
        TempSteps: Record "MOB Steps Element" temporary;
        ItemJnlPostBatch: Codeunit "Item Jnl.-Post Batch";
        ProductionJnlMgt: Codeunit "Production Journal Mgt";
        MobProductionJnlMgt: Codeunit "MOB Production Journal Mgt";
        MobSyncItemTracking: Codeunit "MOB Sync. Item Tracking";
        XmlRequestDoc: XmlDocument;
        BackendID: Code[40];
        ProdOrderNo: Code[20];
        ProdOrderLineNo: Integer;
        ToTemplateName: Code[10];
        ToBatchName: Code[10];
        ResultMessage: Text;
    begin
        // Disable the locktimeout to prevent timeout messages on the mobile device
        LockTimeout(false);

        // Load the request document from the document queue
        _MobDocQueue.LoadXMLRequestDoc(XmlRequestDoc);

        // Get the <backendID> element
        MobRequestMgt.InitCommonFromXmlOrderNode(XmlRequestDoc, TempOrderValues);
        Evaluate(BackendID, TempOrderValues.GetValue('backendID', true));

        // Extract the Prod Order No and Prod Order Line No. from the BackendID
        MobWmsToolbox.GetOrderNoAndOrderLineNoFromBackendId(BackendID, ProdOrderNo, ProdOrderLineNo);

        // Make sure that the released prod. order line still exists
        ProdOrder.Get(ProdOrder.Status::Released, ProdOrderNo);
        ProdOrderLine.Get(ProdOrderLine.Status::Released, ProdOrderNo, ProdOrderLineNo);

        // Create production jnl. and reset all lines to zero
        MobProductionJnlMgt.CreateAndResetJnlLines(ProdOrder, ProdOrderLine, ToTemplateName, ToBatchName);     // MAY COMMIT

        // Turn on commit protection to prevent unintentional committing data
        _MobDocQueue.Consistent(false);

        // Lock the tables to work on
        ProdOrderLine.LockTable();
        ItemJnlLine.LockTable();
        MobRegistration.LockTable();

        // Re-read due to possible commit above
        // ('=') throws warning since record is not iterated
        ProdOrder.Get(ProdOrder.Status, ProdOrder."No.");
        ProdOrderLine.Get(ProdOrderLine.Status, ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.");

        // Save the registrations from the XML in the Mobile WMS Registration table
        MobWmsToolbox.SaveRegistrationData(_MobDocQueue.MessageIDAsGuid(), XmlRequestDoc, MobRegistration.Type::"Production Consumption");

        // OnAddStepsTo IntegrationEvents
        OnPostProdConsumption_OnAddStepsToProdOrderLine(TempOrderValues, ProdOrderLine, TempSteps);
        if not TempSteps.IsEmpty() then begin
            MobSessionData.SetRegistrationTypeTracking('OnAddStepsTo');
            MobWmsToolbox.DeleteRegistrationData(_MobDocQueue.MessageIDAsGuid());
            MobToolbox.CreateResponseWithSteps(_XmlResponseDoc, TempSteps);
            _MobDocQueue.Consistent(true);
            exit;
        end;

        // OnBeforePost IntegrationEvents        
        OnPostProdConsumption_OnBeforePostProdOrderLine(TempOrderValues, ProdOrderLine);
        ProdOrderLine.Modify(true);

        ConsumptionJnlLine.Reset();
        ConsumptionJnlLine.SetRange("Journal Template Name", ToTemplateName);
        ConsumptionJnlLine.SetRange("Journal Batch Name", ToBatchName);
        ConsumptionJnlLine.SetRange("Entry Type", ConsumptionJnlLine."Entry Type"::Consumption);
        ConsumptionJnlLine.SetRange("Order Type", ConsumptionJnlLine."Order Type"::Production);
        ConsumptionJnlLine.SetRange("Order No.", ProdOrder."No.");
        ConsumptionJnlLine.SetRange("Order Line No.", ProdOrderLine."Line No.");
        ConsumptionJnlLine.FindSet();
        repeat
            HandleRegistrationsForProductionJnlLine(ConsumptionJnlLine, TempNewReservationEntry, _MobDocQueue.MessageIDAsGuid());
        until ConsumptionJnlLine.Next() = 0;

        // Verify all registrations was handled
        MobRegistration.Reset();
        MobRegistration.SetCurrentKey("Posting MessageId");
        MobRegistration.SetRange("Posting MessageId", _MobDocQueue.MessageIDAsGuid());
        MobRegistration.SetRange(Handled, false);
        if MobRegistration.FindFirst() then
            MobRegistration.FieldError(Handled);

        // Post applied lines from consumption journal
        MobSyncItemTracking.Run(TempNewReservationEntry);
        MobProductionJnlMgt.DeleteJnlLinesWithNoRegistrations(ToTemplateName, ToBatchName, ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.");
        if ConsumptionJnlLine.FindFirst() then begin
            _MobDocQueue.Consistent(true);
            Commit();

            Clear(ItemJnlPostBatch);
            ItemJnlPostBatch.SetSuppressCommit(true);
            if not ItemJnlPostBatch.Run(ConsumptionJnlLine) then begin
                ProductionJnlMgt.DeleteJnlLines(ToTemplateName, ToBatchName, ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.");
                MobWmsToolbox.DeleteRegistrationData(_MobDocQueue.MessageIDAsGuid());
                Commit();
                ResultMessage := GetLastErrorText();
                MobSessionData.SetPreservedLastErrorCallStack();
                Error(ResultMessage);
            end
        end else
            Error(MobWmsLanguage.GetMessage('NOTHING_TO_REGISTER'));

        // Turn on commit protection off again
        _MobDocQueue.Consistent(true);

        // Create a response inside the <description> element of the document response
        MobToolbox.CreateSimpleResponse(_XmlResponseDoc, MobWmsLanguage.GetMessage('REG_TRANS_SUCCESS'));
    end;

    local procedure HandleRegistrationsForProductionJnlLine(var _ConsumptionJnlLine: Record "Item Journal Line"; var _TempNewReservationEntry: Record "Reservation Entry"; _PostingMessageId: Guid)
    var
        ProdOrderComponent: Record "Prod. Order Component";
        MobSetup: Record "MOB Setup";
        MobRegistration: Record "MOB WMS Registration";
        MobTrackingSetup: Record "MOB Tracking Setup";
        MobSyncItemTracking: Codeunit "MOB Sync. Item Tracking";
        UoMMgt: Codeunit "Unit of Measure Management";
        xBinCode: Code[20];
        Qty: Decimal;
        QtyBase: Decimal;
        TotalQty: Decimal;
        TotalQtyBase: Decimal;
        DummyExpDateRequired: Boolean;
        HasCallbackDialog: Boolean;
    begin
        MobRegistration.Reset();
        MobRegistration.SetRange(Type, MobRegistration.Type::"Production Consumption");
        MobRegistration.SetRange("Order No.", _ConsumptionJnlLine."Order No.");
        MobRegistration.SetRange("Line No.", _ConsumptionJnlLine."Prod. Order Comp. Line No.");
        MobRegistration.SetRange("Prod. Order Line No.", _ConsumptionJnlLine."Order Line No.");
        MobRegistration.SetRange("Posting MessageId", _PostingMessageId);
        MobRegistration.SetRange(Handled, false);
        if not MobRegistration.FindSet() then
            exit;

        MobSetup.Get();

        Clear(TotalQty);
        repeat
            // Calculate registered quantity and base quantity
            if MobSetup."Use Base Unit of Measure" then begin
                Qty := 0; // To ensure best possible rounding the TotalQty will be calculated after the loop
                QtyBase := MobRegistration.Quantity;
            end else begin
                MobRegistration.TestField(UnitOfMeasure, _ConsumptionJnlLine."Unit of Measure Code");
                Qty := MobRegistration.Quantity;
                QtyBase := UoMMgt.CalcBaseQty(MobRegistration.Quantity, _ConsumptionJnlLine."Qty. per Unit of Measure");
            end;

            TotalQty := TotalQty + Qty;
            TotalQtyBase := TotalQtyBase + QtyBase;

            ProdOrderComponent.Get(ProdOrderComponent.Status::Released, MobRegistration."Order No.", MobRegistration."Prod. Order Line No.", MobRegistration."Line No.");

            MobTrackingSetup.DetermineManufOutboundTrackingRequiredFromItemNo(ProdOrderComponent."Item No.", DummyExpDateRequired);
            // MobTrackingSetup.Tracking: Copy later from MobWmsRegistration in MobSyncItemTracking.InsertTempReservEntryFromMobWmsRegistration()

            // Postive quantity from MobWmsRegistration is consumption meaning materials are leaving inventory (inbound=false)
            // Negative quantity from MobWmsRegistration is "negative consumption" meaning materials going back on inventory (inbound=true)
            if MobTrackingSetup.TrackingRequired() then
                MobSyncItemTracking.CreateTempReservEntryForItemJnlLineFromMobWmsRegistration(_ConsumptionJnlLine, MobRegistration, _TempNewReservationEntry, QtyBase);

            MobWmsToolbox.SaveRegistrationDataFromSource(_ConsumptionJnlLine."Location Code", _ConsumptionJnlLine."Item No.", _ConsumptionJnlLine."Variant Code", MobRegistration);

            // OnHandle IntegrationEvent
            OnPostProdConsumption_OnHandleRegistrationForProductionJnlLine(MobRegistration, _ConsumptionJnlLine);
            _ConsumptionJnlLine.Modify();

            // Remember that the registration was handled
            MobRegistration.Validate(Handled, true);
            MobRegistration.Modify();

            if MobTrackingSetup.TrackingRequired() then
                if _TempNewReservationEntry.Modify() then; // To modify if created earlier and possibly updated in subscriber

        until MobRegistration.Next() = 0;

        // To ensure best possible rounding the TotalQty is calculated and rounded only once when MobSetup."Use Base Unit of Measure" is enabled (i.e. 3 * 1/3 = 1)
        if MobSetup."Use Base Unit of Measure" then
            TotalQty := UoMMgt.CalcQtyFromBase(TotalQtyBase, _ConsumptionJnlLine."Qty. per Unit of Measure");

        // Determine if a confirm dialog would be displayed in standard code and need to be suppressed
        HasCallbackDialog := (ProdOrderComponent."Bin Code" <> '') and (MobRegistration.FromBin <> '') and (ProdOrderComponent."Bin Code" <> MobRegistration.FromBin);
        if not HasCallbackDialog then
            _ConsumptionJnlLine.Validate("Bin Code", MobRegistration.FromBin)
        else begin
            // Validate but suppress callback dialog from standard code
            xBinCode := ProdOrderComponent."Bin Code";
            ProdOrderComponent.Validate("Bin Code", MobRegistration.FromBin);
            ProdOrderComponent.Modify(true);
            _ConsumptionJnlLine.Validate("Bin Code", MobRegistration.FromBin);
            ProdOrderComponent.Validate("Bin Code", xBinCode);
            ProdOrderComponent.Modify(true);
        end;

        _ConsumptionJnlLine.Validate(Quantity, TotalQty);
        _ConsumptionJnlLine.Modify(true);
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
        OnGetProdOrderLines_OnAfterSetCurrentKey(TempHeaderElementCustomView);
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
        OnGetProdConsumptionLines_OnAfterSetCurrentKey(TempBaseOrderLineElementCustomView);
        _BaseOrderLineElement.SetView(TempBaseOrderLineElementCustomView.GetView());
    end;

    local procedure SetFromProdOrderLine(_ProdOrderLine: Record "Prod. Order Line"; var _BaseOrder: Record "MOB NS BaseDataModel Element"; var _TempHeaderFilter: Record "MOB NS Request Element")
    var
        MobSetup: Record "MOB Setup";
        Location: Record Location;
        Item: Record Item;
        MobWmsMedia: Codeunit "MOB WMS Media";
        DisplayLine2To9List: List of [Text];
    begin
        MobSetup.Get();

        // Add the data to the order header element        
        _BaseOrder.Init();

        // The journal name is prefixed to determine its type later            
        _BaseOrder.Set_BackendID(CreateBackendIdForProdOrderLine(_ProdOrderLine));

        // Now we add the elements that we want the user to see            
        _BaseOrder.Set_DisplayLine1(_ProdOrderLine."Prod. Order No.");
        _BaseOrder.Set_DisplayLine2(_ProdOrderLine."Item No." + '  ' + _ProdOrderLine.Description);

        if (_TempHeaderFilter.Get_Location() = 'All') and Location.Get(_ProdOrderLine."Location Code") then
            _BaseOrder.Set_DisplayLine3(Location.Name <> '', Location.Name, Location.Code);

        _BaseOrder.Set_Location(_ProdOrderLine."Location Code"); // Default value for PrintLabel Lookup

        if _ProdOrderLine."Variant Code" <> '' then
            _BaseOrder.Set_DisplayLine4(_ProdOrderLine."Variant Code" <> '', MobWmsLanguage.GetMessage('VARIANT_LABEL') + ': ' + _ProdOrderLine."Variant Code", '');

        _BaseOrder.Set_HeaderLabel1(MobWmsLanguage.GetMessage('ORDER_NUMBER'));
        _BaseOrder.Set_HeaderLabel2(MobWmsLanguage.GetMessage('DESCRIPTION'));
        _BaseOrder.Set_HeaderValue1(_ProdOrderLine."Prod. Order No." + ' - ' + Format(_ProdOrderLine."Item No."));
        _BaseOrder.Set_HeaderValue2(_ProdOrderLine.Description);

        _BaseOrder.SetValue('StartingDateLabel', MobWmsLanguage.GetMessage('STARTING_DATE'));
        if _ProdOrderLine."Starting Date" <> 0D then    // CreateDateTime will throw error if "Starting Date" is blank but "Starting Time" is populated
            _BaseOrder.SetValue('StartingDate', MobWmsToolbox.DateTime2TextAsDisplayFormat(CreateDateTime(_ProdOrderLine."Starting Date", _ProdOrderLine."Starting Time"))) // Date and Time as-is (not affected by user timezones or summer/winter time)
        else
            _BaseOrder.SetValue('StartingDate', '');

        _BaseOrder.SetValue('QuantityLabel', MobWmsLanguage.GetMessage('QUANTITY'));
        _BaseOrder.SetValue('FinishedQuantityLabel', MobWmsLanguage.GetMessage('FINISHED_QTY'));
        _BaseOrder.SetValue('RemainingQuantityLabel', MobWmsLanguage.GetMessage('REMAINING_QTY'));
        _BaseOrder.Set_ItemNumber(_ProdOrderLine."Item No.");
        _BaseOrder.SetValue('VariantCode', _ProdOrderLine."Variant Code");

        if MobSetup."Use Base Unit of Measure" then begin
            Item.Get(_ProdOrderLine."Item No.");
            _BaseOrder.Set_Quantity(MobWmsToolbox.Decimal2TextAsDisplayFormat(_ProdOrderLine."Quantity (Base)"));
            _BaseOrder.SetValue('FinishedQuantity', MobWmsToolbox.Decimal2TextAsDisplayFormat(_ProdOrderLine."Finished Qty. (Base)", false));
            _BaseOrder.SetValue('RemainingQuantity', MobWmsToolbox.Decimal2TextAsDisplayFormat(_ProdOrderLine."Remaining Qty. (Base)", false));
            _BaseOrder.Set_UnitOfMeasure(Item."Base Unit of Measure");
        end else begin
            _BaseOrder.Set_Quantity(MobWmsToolbox.Decimal2TextAsDisplayFormat(_ProdOrderLine.Quantity));
            _BaseOrder.SetValue('FinishedQuantity', MobWmsToolbox.Decimal2TextAsDisplayFormat(_ProdOrderLine."Finished Quantity", false));
            _BaseOrder.SetValue('RemainingQuantity', MobWmsToolbox.Decimal2TextAsDisplayFormat(_ProdOrderLine."Remaining Quantity", false));
            _BaseOrder.Set_UnitOfMeasure(_ProdOrderLine."Unit of Measure Code");
        end;

        _BaseOrder.Set_ReferenceID(_ProdOrderLine);
        _BaseOrder.Set_Status();    // Set Locked/Has Attachment symbol (1=Unlocked, 2=Locked, 3=Attachment)
        _BaseOrder.Set_Attachment();
        _BaseOrder.Set_ItemImageID(MobWmsMedia.GetItemImageID(_ProdOrderLine."Item No."));

        _BaseOrder.SetValue('LookupId', Format(_ProdOrderLine.RecordId()));     // Reposition on refresh (requires spring 2021 mobile app)

        if _ProdOrderLine."Starting Date-Time" <> 0DT then
            _BaseOrder.Set_Sorting1(_ProdOrderLine."Starting Date-Time");

        // Integration Events
        OnGetProdOrderLines_OnAfterSetFromProdOrderLine(_ProdOrderLine, _BaseOrder);

        // Compressed display lines 2 to 9 (after integration events to change display lines)
        _BaseOrder.GetDisplayLinesAsList(DisplayLine2To9List, 2, 9);
        MobWmsToolbox.ListTrimBlank(DisplayLine2To9List, 2);
        _BaseOrder.SetValue('CompressedDisplayLine2To9', MobWmsToolbox.List2TextLn(DisplayLine2To9List, 999));
    end;

    local procedure SetFromProdOrderComponent(_ProdOrderComp: Record "Prod. Order Component"; _TempTrackingSpecification: Record "Tracking Specification"; _ProdOrderLine: Record "Prod. Order Line"; _BackendID: Code[40]; var _BaseOrderLine: Record "MOB NS BaseDataModel Element")
    var
        MobSetup: Record "MOB Setup";
        MobTrackingSetup: Record "MOB Tracking Setup";
        TempSteps: Record "MOB Steps Element" temporary;
        Location: Record Location;
        Item: Record Item;
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
        UoMMgt: Codeunit "Unit of Measure Management";
        MobUoMMgt: Codeunit "MOB Unit of Measure Management";
        MobItemReferenceMgt: Codeunit "MOB Item Reference Mgt.";
        MobWmsAdhocReg: Codeunit "MOB WMS Adhoc Registr.";
        MobCommonMgt: Codeunit "MOB Common Mgt.";
        DummyExpDateRequired: Boolean;
        RemainingQty: Decimal;
        RemainingQtyBase: Decimal;
        DisplayLine1List: List of [Text];
        DisplayLine2To9List: List of [Text];
        ExtraInfo1_Col1: List of [Text];
        ExtraInfo1_Col2: List of [Text];
        ExtraInfo2_Col1: List of [Text];
        ExtraInfo2_Col2: List of [Text];
    begin
        MobSetup.Get();

        if not Location.Get(_ProdOrderComp."Location Code") then
            Clear(Location);

        Item.Get(_ProdOrderComp."Item No.");

        // Add the data to the journal line element        
        _BaseOrderLine.Init();
        _BaseOrderLine.Set_OrderBackendID(_BackendID);

        _BaseOrderLine.Set_LineNumber(CreatePrefixedLineNumberAsPostfix(_ProdOrderComp."Line No.", _TempTrackingSpecification."Entry No.")); // to avoid redundant lines error at mobile device but not actually used during posting
        _BaseOrderLine.Set_ItemNumber(_ProdOrderComp."Item No.");
        _BaseOrderLine.SetValue('VariantCode', _ProdOrderComp."Variant Code");  // Needed for lookup substitute item
        _BaseOrderLine.Set_ItemBarcode(MobItemReferenceMgt.GetBarcodeList(_ProdOrderComp."Item No.", _ProdOrderComp."Variant Code", _ProdOrderComp."Unit of Measure Code"));

        // Only inventory items require bin validation
        if MobCommonMgt.ProdOrderComponent_IsInventoriableItem(_ProdOrderComp) then begin
            _BaseOrderLine.Set_FromBin(_ProdOrderComp."Bin Code");
            _BaseOrderLine.Set_ValidateFromBin(MobWmsAdhocReg.TestBinMandatory(_ProdOrderComp."Location Code"));
        end else begin
            _BaseOrderLine.Set_FromBin('');
            _BaseOrderLine.Set_ValidateFromBin(false);
        end;

        // There is no ToBin when posting consumption
        _BaseOrderLine.Set_ToBin('');
        _BaseOrderLine.Set_ValidateToBin(false);

        _BaseOrderLine.Set_AllowBinChange(not Location."Directed Put-away and Pick");  // However, populated BinCode may trigger callback -- handled in Posting

        MobTrackingSetup.DetermineManufOutboundTrackingRequiredFromItemNo(_ProdOrderComp."Item No.", DummyExpDateRequired);
        MobTrackingSetup.CopyTrackingFromTrackingSpec(_TempTrackingSpecification);

        _BaseOrderLine.SetTracking(MobTrackingSetup);
        _BaseOrderLine.SetRegisterTracking(MobTrackingSetup);
        _BaseOrderLine.Set_RegisterExpirationDate(false);

        if _TempTrackingSpecification."Entry No." = 0 then begin
            // journal line with no tracking
            RemainingQty := _ProdOrderComp."Remaining Quantity";
            RemainingQtyBase := _ProdOrderComp."Remaining Qty. (Base)";
        end else begin
            // journal line split by tracking (this procedure is called for each tracking specification)
            RemainingQty := Abs(_TempTrackingSpecification."Qty. to Handle");
            RemainingQtyBase := Abs(_TempTrackingSpecification."Qty. to Handle (Base)");
        end;

        // Round quantities for consistency with CalcConsumption and to avoid unrounded values from ItemTrackingMgt.SumUpItemTracking()
        Item.Get(_ProdOrderComp."Item No.");
        if Item."Rounding Precision" > 0 then begin
            RemainingQty := MobUoMMgt.RoundToItemRndPrecision(RemainingQty, Item."Rounding Precision");
            RemainingQtyBase := MobUoMMgt.RoundToItemRndPrecision(RemainingQtyBase, Item."Rounding Precision");
        end else begin
            RemainingQty := UoMMgt.RoundQty(RemainingQty);
            RemainingQtyBase := UoMMgt.RoundQty(RemainingQtyBase);
        end;

        if MobSetup."Use Base Unit of Measure" then begin
            _BaseOrderLine.Set_Quantity(RemainingQtyBase);
            _BaseOrderLine.Set_UnitOfMeasure(Item."Base Unit of Measure");
        end else begin
            _BaseOrderLine.Set_Quantity(RemainingQty);
            _BaseOrderLine.Set_UnitOfMeasure(_ProdOrderComp."Unit of Measure Code");
        end;

        _BaseOrderLine.Set_RegisterQuantityByScan(false);
        _BaseOrderLine.Set_RegisteredQuantity('0');

        // Decide what to display on the lines
        // There are 9 display lines available. Lines 2 to 9 is compressed to new tag "CompressedDisplayLine2To9" after events
        // Line 1: Show the Prod. Routing Link Description (if exists) + Bin, otherwise Bin (if Bin Mandatory), otherwise Item No.
        // Line 2: Show the Item Number (UoM is displayed in Quantity-step helplabel) + Item Description
        // Line 3: Show the Lot Info
        // Line 4: Show the Serial Info
        // Line 5: Show the Item Variant
        if GetProdOrderRoutingLine(_ProdOrderComp, ProdOrderRtngLine) then begin
            Clear(DisplayLine1List);
            DisplayLine1List.Add(ProdOrderRtngLine.Description);
            DisplayLine1List.Add(_ProdOrderComp."Bin Code");
            _BaseOrderLine.Set_DisplayLine1(MobWmsToolbox.List2TextLn(DisplayLine1List, 2));
        end else
            _BaseOrderLine.Set_DisplayLine1(_ProdOrderComp."Bin Code");

        if _BaseOrderLine.Get_DisplayLine1() = '' then begin
            _BaseOrderLine.Set_DisplayLine1(_ProdOrderComp."Item No.");
            _BaseOrderLine.Set_DisplayLine2(_ProdOrderComp.Description);
        end else
            _BaseOrderLine.Set_DisplayLine2(_ProdOrderComp."Item No." + '  ' + _ProdOrderComp.Description);

        _BaseOrderLine.Set_DisplayLine3(MobTrackingSetup.FormatTracking());
        _BaseOrderLine.Set_DisplayLine4('');
        _BaseOrderLine.Set_DisplayLine5(_ProdOrderLine."Variant Code" <> '', MobWmsLanguage.GetMessage('VARIANT_LABEL') + ': ' + _ProdOrderComp."Variant Code", '');

        _ProdOrderComp.CalcFields("Substitution Available", "Act. Consumption (Qty)");
        ExtraInfo1_Col1.Add(MobWmsLanguage.GetMessage('QUANTITY_PER'));
        ExtraInfo1_Col2.Add(StrSubstNo('%1 %2', MobWmsToolbox.Decimal2TextAsDisplayFormat(_ProdOrderComp."Quantity per"), _ProdOrderComp."Unit of Measure Code"));
        if _ProdOrderComp."Substitution Available" then begin
            ExtraInfo1_Col1.Add(MobWmsLanguage.GetMessage('SUBSTITUTION_AVAILABLE'));
            ExtraInfo1_Col2.Add(MobWmsLanguage.GetMessage('YES'));
        end;

        if Location."Require Pick" and Location."Require Shipment" then begin  // Condition from standard posting in "Whse. Validate Source Line".ItemLineVerifyChange()
            ExtraInfo2_Col1.Add(MobWmsLanguage.GetMessage('PICKED_QTY'));
            if _ProdOrderComp."Qty. Picked" = _ProdOrderComp."Expected Quantity" then
                ExtraInfo2_Col2.Add(StrSubstNo('%1 %2', MobWmsToolbox.Decimal2TextAsDisplayFormat(_ProdOrderComp."Qty. Picked"), _ProdOrderComp."Unit of Measure Code"))
            else
                ExtraInfo2_Col2.Add(StrSubstNo('%1 / %2 %3', MobWmsToolbox.Decimal2TextAsDisplayFormat(_ProdOrderComp."Qty. Picked"), MobWmsToolbox.Decimal2TextAsDisplayFormat(_ProdOrderComp."Expected Quantity"), _ProdOrderComp."Unit of Measure Code"));
        end else begin
            ExtraInfo2_Col1.Add(MobWmsLanguage.GetMessage('EXPECTED_QTY'));
            ExtraInfo2_Col2.Add(StrSubstNo('%1 %2', MobWmsToolbox.Decimal2TextAsDisplayFormat(_ProdOrderComp."Expected Quantity"), _ProdOrderComp."Unit of Measure Code"));
        end;
        ExtraInfo2_Col1.Add(MobWmsLanguage.GetMessage('ACTUAL_CONSUMP_QTY'));
        ExtraInfo2_Col2.Add(StrSubstNo('%1 %2', MobWmsToolbox.Decimal2TextAsDisplayFormat(_ProdOrderComp."Act. Consumption (Qty)"), _ProdOrderComp."Unit of Measure Code"));

        _BaseOrderLine.SetValue('ExtraInfo1_Col1', MobWmsToolbox.List2TextLn(ExtraInfo1_Col1, 999));
        _BaseOrderLine.SetValue('ExtraInfo1_Col2', MobWmsToolbox.List2TextLn(ExtraInfo1_Col2, 999));
        _BaseOrderLine.SetValue('ExtraInfo2_Col1', MobWmsToolbox.List2TextLn(ExtraInfo2_Col1, 999));
        _BaseOrderLine.SetValue('ExtraInfo2_Col2', MobWmsToolbox.List2TextLn(ExtraInfo2_Col2, 999));

        // The choices are: None, Warn, Block
        _BaseOrderLine.Set_UnderDeliveryValidation('None');
        _BaseOrderLine.Set_OverDeliveryValidation('Warn');

        _BaseOrderLine.Set_ReferenceID(_ProdOrderComp);
        _BaseOrderLine.Set_Status('0');
        _BaseOrderLine.Set_Attachment();
        _BaseOrderLine.Set_ItemImageID();

        _BaseOrderLine.SetValue('LookupId', StrSubstNo('%1:::%2', Format(_ProdOrderComp.RecordId()), _TempTrackingSpecification."Entry No."));    // Reposition on refresh (requires spring 2021 mobile app)

        // Integration Events
        OnGetProdConsumptionLines_OnAfterSetFromProdOrderComponent(_ProdOrderComp, _TempTrackingSpecification, _BaseOrderLine);

        TempSteps.SetMustCallCreateNext(true);
        OnGetProdConsumptionLines_OnAddStepsToProdOrderComponent(_ProdOrderComp, _TempTrackingSpecification, _BaseOrderLine, TempSteps);       // Set ExtraInfo key hence no RegistrationCollector is returned or set
        if not TempSteps.IsEmpty() then
            _BaseOrderLine.Set_Workflow(TempSteps, "MOB TweakType"::Append);

        // Compressed display lines 2 to 9 (after integration events to change display lines)
        _BaseOrderLine.GetDisplayLinesAsList(DisplayLine2To9List, 2, 9);
        MobWmsToolbox.ListTrimBlank(DisplayLine2To9List, 2);
        _BaseOrderLine.SetValue('CompressedDisplayLine2To9', MobWmsToolbox.List2TextLn(DisplayLine2To9List, 999));
    end;

    /// <summary>
    /// Create 'BackendID' and 'OrderBackendID' for Prod. Order Line
    /// Line. No. is before Order No. to avoid issues if Order No. includes ":" and to easier distinguish from displayed HeaderValue1 (ie. 104101 - 10000)
    /// </summary>
    local procedure CreateBackendIdForProdOrderLine(_ProdOrderLine: Record "Prod. Order Line"): Code[40]
    begin
        exit(_ProdOrderLine."Prod. Order No." + ' - ' + Format(_ProdOrderLine."Line No."));
    end;

    /// <summary>
    /// Create 'LineNumber' from parts (the prefix is after " - " so really a postfix, will be parsed from SaveRegistrationData when string includes the " - ")
    /// Lines with no TrackingSpec."Entry No." will still get the suffix after component line no. i.e. "10000 - 0"
    /// </summary>
    local procedure CreatePrefixedLineNumberAsPostfix(_ProdComponentLineNo: Integer; _TrackingSpecEntryNo: Integer): Text
    begin
        exit(Format(_ProdComponentLineNo) + ' - ' + Format(_TrackingSpecEntryNo));
    end;

    //
    // ------- IntegrationEvents: GetProdOrderLines -------
    //
    // OnGetProdOrderLines_OnSetFilterProductionOrder
    // OnGetProdOrderLines_OnIncludeProdOrderLine
    // OnGetProdOrderLines_OnAfterSetFromProdOrderLine
    // OnGetProdOrderLines_OnAfterSetCurrentKey

    [IntegrationEvent(false, false)]
    local procedure OnGetProdOrderLines_OnSetFilterProdOrderLine(_HeaderFilter: Record "MOB NS Request Element"; var _ProdOrderLine: Record "Prod. Order Line"; var _ProductionOrder: Record "Production Order"; var _IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetProdOrderLines_OnIncludeProdOrderLine(_ProdOrderLine: Record "Prod. Order Line"; var _IncludeInOrderList: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetProdOrderLines_OnAfterSetFromProdOrderLine(_ProdOrderLine: Record "Prod. Order Line"; var _BaseOrderElement: Record "MOB NS BaseDataModel Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetProdOrderLines_OnAfterSetCurrentKey(var _BaseOrderElementView: Record "MOB NS BaseDataModel Element")
    begin
    end;

    //
    // ------- IntegrationEvents: GetProdConsumptionLines -------
    //
    // OnGetProdConsumptionLines_OnSetFilterProdOrderComponent
    // OnGetProdConsumptionLines_OnIncludeProdOrderComponent
    // OnGetProdConsumptionLines_OnAfterSetFromProdOrderComponent
    // OnGetProdConsumptionLines_OnAfterSetCurrentKey
    // OnGetProdConsumptionLines_OnAddStepsToProdOrderLine
    // OnGetProdConsumptionLines_OnAddStepsToProdOrderComponent

    [IntegrationEvent(false, false)]
    local procedure OnGetProdConsumptionLines_OnSetFilterProdOrderComponent(var _ProdOrderComponent: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetProdConsumptionLines_OnIncludeProdOrderComponent(_ProdOrderComponent: Record "Prod. Order Component"; var _IncludeInOrderLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetProdConsumptionLines_OnAfterSetFromProdOrderComponent(_ProdOrderComponent: Record "Prod. Order Component"; _TrackingSpecification: Record "Tracking Specification"; var _BaseOrderLineElement: Record "MOB NS BaseDataModel Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetProdConsumptionLines_OnAfterSetCurrentKey(var _BaseOrderLineElementView: Record "MOB NS BaseDataModel Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetProdConsumptionLines_OnAddStepsToProdOrderLine(_ProdOrderLine: Record "Prod. Order Line"; var _Steps: Record "MOB Steps Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetProdConsumptionLines_OnAddStepsToProdOrderComponent(_ProdOrderComponent: Record "Prod. Order Component"; _TrackingSpecification: Record "Tracking Specification"; var _BaseOrderLineElement: Record "MOB NS BaseDataModel Element"; var _Steps: Record "MOB Steps Element")
    begin
    end;

    //
    // ------- IntegrationEvents: PostProdConsumption -------
    //
    // OnPostProdConsumptin_OnAddStepsToProdOrderLine
    // OnPostProdConsumption_OnBeforePostProdOrderLine
    // OnPostProdConsumption_OnHandleRegistrationForProductionJnlLine
    // OnBeforeRunItemJnlPostBatch: not implemented as this posting codeunit as no addtional parameters to set

    [IntegrationEvent(false, false)]
    local procedure OnPostProdConsumption_OnAddStepsToProdOrderLine(var _OrderValues: Record "MOB Common Element"; _ProdOrderLine: Record "Prod. Order Line"; var _Steps: Record "MOB Steps Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostProdConsumption_OnBeforePostProdOrderLine(var _OrderValues: Record "MOB Common Element"; var _ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostProdConsumption_OnHandleRegistrationForProductionJnlLine(var _Registration: Record "MOB WMS Registration"; var _ProductionJnlLine: Record "Item Journal Line")
    begin
    end;

}
