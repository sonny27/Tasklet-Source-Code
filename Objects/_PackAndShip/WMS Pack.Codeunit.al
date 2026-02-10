codeunit 82238 "MOB WMS Pack"
{
    Access = Public;
    //
    // 'GetPackingOrders' (incl. eventsubscribers incl. eventpublishers)
    // 

    EventSubscriberInstance = Manual;

    TableNo = "MOB Document Queue";

    trigger OnRun()
    begin
        MobDocQueue := Rec;

        MobFeatureTelemetryWrapper.LogUptakeUsed(MobTelemetryEventId::"Pack & Ship Feature (MOB1010)");

        case Rec."Document Type" of

            // Order headers
            'GetPackingOrders':
                GetOrders();

            else
                Error(MobWmsLanguage.GetMessage('NO_DOC_HANDLER'), Rec."Document Type");
        end;

        // Store the result in the queue and update the status
        MobToolbox.UpdateResult(Rec, XmlResultDoc);
    end;

    var
        MobDocQueue: Record "MOB Document Queue";
        MobSetup: Record "MOB Setup";
        MobXmlMgt: Codeunit "MOB XML Management";
        MobToolbox: Codeunit "MOB Toolbox";
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        MobRequestMgt: Codeunit "MOB NS Request Management";
        MobFeatureTelemetryWrapper: Codeunit "MOB Feature Telemetry Wrapper";
        MobTelemetryEventId: Enum "MOB Telemetry Event ID";
        XmlResultDoc: XmlDocument;

    //
    // ReferenceData
    //

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Reference Data", 'OnGetReferenceData_OnAddHeaderConfigurations', '', true, true)]
    local procedure OnGetReferenceData_OnAddHeaderConfigurations(var _HeaderFields: Record "MOB HeaderField Element")
    begin
        _HeaderFields.InitConfigurationKey('PackingOrderFilters');
        _HeaderFields.Create_ListField_FilterLocationAsLocation(10);
        _HeaderFields.Create_DateField_ShipmentDateAsDate(20);
        _HeaderFields.Create_ListField_AssignedUserFilterAsAssignedUser(30);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Reference Data", 'OnGetReferenceData_OnAddDataTables', '', true, true)]
    local procedure OnGetReferenceData_OnAddDataTablesForPackageType(var _DataTable: Record "MOB DataTable Element")
    var
        MobPackageType: Record "MOB Package Type";
        MobPackageSetup: Record "MOB Mobile WMS Package Setup";
        MobPackageSetup2: Record "MOB Mobile WMS Package Setup";
        MobPackMgt: Codeunit "MOB Pack Management";
        CurrentShippingAgentServiceCode: Code[10];
        CurrentShippingAgent: Code[20];
    begin
        // Loop through all MobPackageSetup and add them to the DataTable. 
        // Notice for records with a blank "Shipping Agent Service Code", the Package Type is added to the DataTable for all non-blank Shipping Agent Service Codes for the Shipping Agent.
        CurrentShippingAgent := '';
        CurrentShippingAgentServiceCode := '';
        MobPackageSetup.SetCurrentKey("Shipping Agent", "Shipping Agent Service Code", "Package Type");
        if MobPackageSetup.FindSet() then
            repeat

                // Create a Package Types DataTable for each combination of Shipping Agent, Shipping Agent Service.
                if (MobPackageSetup."Shipping Agent" <> CurrentShippingAgent) or
                   (MobPackageSetup."Shipping Agent Service Code" <> CurrentShippingAgentServiceCode)
                then begin
                    if MobPackageSetup."Shipping Agent Service Code" <> '' then
                        _DataTable.InitDataTable(StrSubstNo('%1_%2_%3', 'PackageTypeTable', MobPackMgt.CreateValidDataTableName(MobPackageSetup."Shipping Agent"), MobPackMgt.CreateValidDataTableName(MobPackageSetup."Shipping Agent Service Code")))
                    else
                        _DataTable.InitDataTable(StrSubstNo('%1_%2', 'PackageTypeTable', MobPackMgt.CreateValidDataTableName(MobPackageSetup."Shipping Agent")));

                    _DataTable.Create_CodeAndName('', '');
                    CurrentShippingAgent := MobPackageSetup."Shipping Agent";
                    CurrentShippingAgentServiceCode := MobPackageSetup."Shipping Agent Service Code";

                    // Add all the general records with blank Shipping Agent Service Code
                    MobPackageSetup2.SetCurrentKey("Shipping Agent", "Shipping Agent Service Code", "Package Type");
                    MobPackageSetup2.SetRange("Shipping Agent", MobPackageSetup."Shipping Agent");
                    MobPackageSetup2.SetRange("Shipping Agent Service Code", '');
                    if MobPackageSetup2.FindSet() then
                        repeat
                            AddPackageTypeToDataTable(MobPackageSetup2."Package Type", _DataTable);
                        until MobPackageSetup2.Next() = 0;
                end;

                // Add specific record with a Shipping Agent Service Code
                if MobPackageSetup."Shipping Agent Service Code" <> '' then
                    AddPackageTypeToDataTable(MobPackageSetup."Package Type", _DataTable);

            until MobPackageSetup.Next() = 0;

        // Create a general fallback DataTable
        _DataTable.InitDataTable('PackageTypeTable');
        if MobPackageType.FindSet() then begin
            _DataTable.Create_CodeAndName('', '');
            repeat
                AddPackageTypeToDataTable(MobPackageSetup."Package Type", _DataTable);
            until MobPackageType.Next() = 0
        end
        else
            // Table cannot be empty or steps do not diplay when added as extra steps
            _DataTable.Create_CodeAndName('N/A', MobWmsLanguage.GetMessage('NOT_AVAILABLE'));
    end;

    // Helper procedure to add package type to DataTable
    local procedure AddPackageTypeToDataTable(_PackageTypeCode: Code[20]; var _DataTable: Record "MOB DataTable Element")
    var
        MobPackageType: Record "MOB Package Type";
    begin
        if MobPackageType.Get(_PackageTypeCode) then
            if MobPackageType.Description <> '' then
                _DataTable.Create_CodeAndName(MobPackageType.Code, MobPackageType.Description)
            else
                _DataTable.Create_CodeAndName(MobPackageType.Code, MobPackageType.Code);
    end;

    //
    // 'GetPackingOrders'
    //

    local procedure GetOrders()
    var
        TempBaseOrderElement: Record "MOB NS BaseDataModel Element" temporary;
        XmlRequestDoc: XmlDocument;
        XmlResponseData: XmlNode;
    begin

        // Using Pack and Ship require Tote Picking is enabled
        MobSetup.Get();
        MobSetup.TestField("Enable Tote Picking", true);

        // Process:
        // 1. Filter and sort the orders for this particular user
        // 2. Save the result in XML and return it to the mobile device

        // Load the request from the queue
        MobDocQueue.LoadXMLRequestDoc(XmlRequestDoc);

        // Initialize the response document for order data
        MobToolbox.InitializeResponseDoc(XmlResultDoc, XmlResponseData);

        // Warehouse shipments to buffer
        GetWarehouseShipmentsToPack(XmlRequestDoc, MobDocQueue, TempBaseOrderElement);

        // Add collected buffer values to new <BaseOrder> nodes
        AddBaseOrderElements(XmlResponseData, TempBaseOrderElement);
    end;

    internal procedure GetWarehouseShipmentsToPack(var _XmlRequestDoc: XmlDocument; var _MobDocQueue: Record "MOB Document Queue"; var _BaseOrderElement: Record "MOB NS BaseDataModel Element")
    var
        Location: Record Location;
        WhseShipmentHeader: Record "Warehouse Shipment Header";
        MobLicensePlate: Record "MOB License Plate";
        MobLicensePlateContent: Record "MOB License Plate Content";
        TempWhseShipmentHeader: Record "Warehouse Shipment Header" temporary;
        TempHeaderFilter: Record "MOB NS Request Element" temporary;
        MobBaseDocHandler: Codeunit "MOB WMS Base Document Handler";
        IsHandled: Boolean;
    begin
        // Respond with a list of Shipments        
        WhseShipmentHeader.SetRange(Status, WhseShipmentHeader.Status::Released);
        WhseShipmentHeader.SetFilter("Location Code", MobBaseDocHandler.GetLocationFilter_Ship(_MobDocQueue."Mobile User ID"));

        // XML filter data into Temporary table
        MobRequestMgt.SaveHeaderFilters(_XmlRequestDoc, TempHeaderFilter);

        if TempHeaderFilter.FindSet() then
            repeat

                IsHandled := false;

                OnGetPackingOrders_OnSetFilterWarehouseShipment(TempHeaderFilter, WhseShipmentHeader, MobLicensePlateContent, IsHandled);

                if not IsHandled then
                    case TempHeaderFilter.Name of
                        'Location':
                            if TempHeaderFilter."Value" = 'All' then
                                // Set the location filter to all locations
                                WhseShipmentHeader.SetFilter("Location Code", MobBaseDocHandler.GetLocationFilter_Ship(_MobDocQueue."Mobile User ID"))
                            else begin
                                Location.Get(TempHeaderFilter."Value");
                                WhseShipmentHeader.SetRange("Location Code", TempHeaderFilter."Value");
                            end;

                        'Date':
                            WhseShipmentHeader.SetFilter("Shipment Date", '<=%1', MobToolbox.Text2Date(TempHeaderFilter."Value"));

                        'ScannedValue':
                            if MobLicensePlate.Get(TempHeaderFilter."Value") then begin
                                MobLicensePlate.TestField("Whse. Document Type", MobLicensePlate."Whse. Document Type"::Shipment);  // In Pack, Whse. Doc. Type must always be Shipment                                
                                WhseShipmentHeader.Reset();
                                WhseShipmentHeader.SetRange("No.", MobLicensePlate."Whse. Document No.");
                                MobLicensePlateContent.SetRange("License Plate No.", MobLicensePlate."No.");
                            end else
                                WhseShipmentHeader.SetRange("No.", TempHeaderFilter.Value);

                        'AssignedUser':
                            case TempHeaderFilter."Value" of
                                'All':
                                    ; // No filter -> do nothing
                                'OnlyMine':
                                    // Set the filter to the current user
                                    WhseShipmentHeader.SetRange("Assigned User ID", _MobDocQueue."Mobile User ID"); // Current user
                                'MineAndUnassigned':
                                    // Set the filter to the current user + blank
                                    WhseShipmentHeader.SetFilter("Assigned User ID", '''''|%1', _MobDocQueue."Mobile User ID"); // Current user or blank
                            end;
                    end;

            until TempHeaderFilter.Next() = 0;

        // Run event once more with Empty "Header filter" to allow for additional filtering directly on the records, NOT related to specific Header filter
        Clear(TempHeaderFilter);
        Clear(IsHandled);

        OnGetPackingOrders_OnSetFilterWarehouseShipment(TempHeaderFilter, WhseShipmentHeader, MobLicensePlateContent, IsHandled);

        // Insert orders into temp rec        
        CopyFilteredWhseShipmentHeadersToTempRecord(WhseShipmentHeader, MobLicensePlateContent, TempWhseShipmentHeader);

        // Respond with resulting orders
        CreateWhseShipmentToPackResponse(TempWhseShipmentHeader, _BaseOrderElement);
    end;

    /// <summary>
    /// Transfer possibly filtered orders into temp record
    /// </summary> 
    local procedure CopyFilteredWhseShipmentHeadersToTempRecord(var _WhseShipmentHeaderView: Record "Warehouse Shipment Header"; var _LicensePlateContentView: Record "MOB License Plate Content"; var _TempWhseShipmentHeader: Record "Warehouse Shipment Header")
    var
        MobLicensePlate: Record "MOB License Plate";
        IncludeInOrderList: Boolean;
    begin
        if _WhseShipmentHeaderView.FindSet() then
            repeat
                IncludeInOrderList := false;
                // Insert Only if License Plate Content exist and not already transfer to Shipping Provider
                _LicensePlateContentView.SetRange("Whse. Document Type", _LicensePlateContentView."Whse. Document Type"::Shipment);
                _LicensePlateContentView.SetRange("Whse. Document No.", _WhseShipmentHeaderView."No.");
                if _LicensePlateContentView.FindSet() then
                    repeat
                        if MobLicensePlate."No." <> _LicensePlateContentView."License Plate No." then
                            if MobLicensePlate.Get(_LicensePlateContentView."License Plate No.") then
                                if MobLicensePlate."Transferred to Shipping" = false then
                                    IncludeInOrderList := true;
                    until (_LicensePlateContentView.Next() = 0) or IncludeInOrderList;

                // Verify additional conditions from eventsubscribers
                if IncludeInOrderList then
                    OnGetPackingOrders_OnIncludeWarehouseShipmentHeader(_WhseShipmentHeaderView, IncludeInOrderList);

                if IncludeInOrderList then begin
                    _TempWhseShipmentHeader.Copy(_WhseShipmentHeaderView);
                    _TempWhseShipmentHeader.Insert();
                end;
            until _WhseShipmentHeaderView.Next() = 0;
    end;

    local procedure CreateWhseShipmentToPackResponse(var _WhseShipmentHeader: Record "Warehouse Shipment Header"; var _BaseOrderElement: Record "MOB NS BaseDataModel Element")
    var
        MobLicensePlate: Record "MOB License Plate";
    begin
        if _WhseShipmentHeader.FindSet() then
            repeat
                MobLicensePlate.SetRange("Whse. Document Type", MobLicensePlate."Whse. Document Type"::Shipment);
                MobLicensePlate.SetRange("Whse. Document No.", _WhseShipmentHeader."No.");
                MobLicensePlate.SetRange("Transferred to Shipping", false);
                if not MobLicensePlate.IsEmpty() then begin
                    // Collect buffer values for the <Order>-<BaseOrder> element                    
                    _BaseOrderElement.Create();
                    SetFromWarehouseShipmentHeader(_WhseShipmentHeader, _BaseOrderElement);
                    _BaseOrderElement.Save();
                end;
            until _WhseShipmentHeader.Next() = 0;
    end;

    local procedure SetFromWarehouseShipmentHeader(_WhseShipmentHeader: Record "Warehouse Shipment Header"; var _BaseOrder: Record "MOB NS BaseDataModel Element")
    var
        MobPackingStation: Record "MOB Packing Station";
        MobWmsShip: Codeunit "MOB WMS Ship";
    begin
        // Add the data elements to the <Order> element
        _BaseOrder.Set_BackendID(_WhseShipmentHeader."No.");

        // Decide what to show on the lines
        _BaseOrder.Set_DisplayLine1(GetReceiver(_WhseShipmentHeader."No.") + ' (' + MobWmsToolbox.Date2TextAsDisplayFormat(_WhseShipmentHeader."Shipment Date") + ')');

        // Checks status of lines whether there are ATO lines or not -  since Document Status from Whse. Shipment not accurate in some cases.
        if _WhseShipmentHeader."MOB CompletelyPicked"() then
            _BaseOrder.Set_DisplayLine2(_WhseShipmentHeader."No." + ' (' + MobWmsLanguage.GetMessage('SHIPMENT_DOCUMENT_STATUS_COMPLETELY_PICKED') + ')')
        else
            _BaseOrder.Set_DisplayLine2(_WhseShipmentHeader."No." + ' (' + MobWmsLanguage.GetMessage('SHIPMENT_DOCUMENT_STATUS_PARTIALLY_PICKED') + ')');

        _BaseOrder.Set_DisplayLine3(MobWmsShip.GetSourceTypeNo(_WhseShipmentHeader."No.", 3));

        if _WhseShipmentHeader."Shipping Agent Code" <> '' then
            _BaseOrder.Set_DisplayLine4('Shipping Agent: ' + _BaseOrder.Get_DisplayLine4() + _WhseShipmentHeader."Shipping Agent Code");

        if _WhseShipmentHeader."Shipping Agent Service Code" <> '' then
            _BaseOrder.Set_DisplayLine4(_BaseOrder.Get_DisplayLine4() + ' | ' + _WhseShipmentHeader."Shipping Agent Service Code");

        if _WhseShipmentHeader."MOB Packing Station Code" <> '' then begin
            MobPackingStation.Get(_WhseShipmentHeader."MOB Packing Station Code");
            _BaseOrder.Set_DisplayLine5(MobPackingStation.TableCaption() + ': ' + MobPackingStation.Description);
        end;

        _BaseOrder.Set_HeaderLabel1(MobWmsLanguage.GetMessage('SHIPMENT'));
        _BaseOrder.Set_HeaderLabel2(MobWmsLanguage.GetMessage('RECEIVER'));
        _BaseOrder.Set_HeaderValue1(_WhseShipmentHeader."No.");

        if _WhseShipmentHeader."Shipping Agent Code" <> '' then
            _BaseOrder.Set_HeaderValue1(_BaseOrder.Get_HeaderValue1() + ' | ' + _WhseShipmentHeader."Shipping Agent Code");

        if _WhseShipmentHeader."Shipping Agent Service Code" <> '' then
            _BaseOrder.Set_HeaderValue1(_BaseOrder.Get_HeaderValue1() + ' | ' + _WhseShipmentHeader."Shipping Agent Service Code");

        _BaseOrder.Set_HeaderValue2(GetReceiver(_WhseShipmentHeader."No."));

        _BaseOrder.Set_ReferenceID(_WhseShipmentHeader);

        _BaseOrder.Set_Attachment();

        // Set Line Status Color
        _BaseOrder.SetValue('LineStatus', GetShippingOrderDeviceLineStatus(_WhseShipmentHeader));

        OnGetPackingOrders_OnAfterSetFromWarehouseShipmentHeader(_WhseShipmentHeader, _BaseOrder);
    end;

    //
    // ------- DATAMODEL HELPER -------
    //

    local procedure AddBaseOrderElements(var _XmlResponseData: XmlNode; var _BaseOrderElement: Record "MOB NS BaseDataModel Element")
    var
        CursorMgt: Codeunit "MOB Cursor Management";
    begin
        // store current cursor and sorting
        CursorMgt.Backup(_BaseOrderElement);

        // set sorting to be used for the export, then write to xml
        SetCurrentKeyHeader(_BaseOrderElement);
        MobXmlMgt.AddNsBaseDataModelBaseOrderElements(_XmlResponseData, _BaseOrderElement);

        // restore cursor and sorting
        CursorMgt.Restore(_BaseOrderElement);
    end;

    local procedure SetCurrentKeyHeader(var _BaseOrderElement: Record "MOB NS BaseDataModel Element")
    var
        TempBaseOrderElementCustomView: Record "MOB NS BaseDataModel Element" temporary;
    begin
        _BaseOrderElement.SetCurrentKey("Sorting1 (internal)", "Sorting2 (internal)", "Sorting3 (internal)", "Sorting4 (internal)", "Sorting5 (internal)");

        // use new temporary/empty record for integration event to prevent SetFrom from being in effect at this point in time
        TempBaseOrderElementCustomView.SetView(_BaseOrderElement.GetView());
        OnGetPackingOrders_OnAfterSetCurrentKey(TempBaseOrderElementCustomView);
        _BaseOrderElement.SetView(TempBaseOrderElementCustomView.GetView());
    end;

    //
    // ------- MISC. HELPER -------
    //

    /// <summary>
    /// Return value to set Line Status on Device
    /// </summary>
    /// <returns>
    /// Line Status 1 = In Progress, 2 = Done, 3 = Not Started
    /// </returns>
    local procedure GetShippingOrderDeviceLineStatus(_WhseShipmentHeader: Record "Warehouse Shipment Header"): Text
    var
        MobLicensePlate: Record "MOB License Plate";
        LineStatus: Text;
    begin
        LineStatus := '3'; // Not started

        MobLicensePlate.SetRange("Whse. Document Type", MobLicensePlate."Whse. Document Type"::Shipment);
        MobLicensePlate.SetRange("Whse. Document No.", _WhseShipmentHeader."No.");
        if MobLicensePlate.FindSet() then
            repeat

                if MobLicensePlate."Shipping Status" = MobLicensePlate."Shipping Status"::Ready then
                    LineStatus := '2' // Done
                else
                    if LineStatus = '2' then  // At least one is OK
                        LineStatus := '1' // In Progress
            until MobLicensePlate.Next() = 0;

        exit(LineStatus);
    end;

    internal procedure GetReceiver(_ShipmentNo: Code[20]): Text
    var
        Location: Record Location;
        Customer: Record Customer;
        Vendor: Record Vendor;
        SalesLine: Record "Sales Line";
        TransferLine: Record "Transfer Line";
        PurchaseLine: Record "Purchase Line";
        WhseShipmentLine: Record "Warehouse Shipment Line";
        ServiceLine: Record "Service Line";
    begin
        WhseShipmentLine.SetRange("No.", _ShipmentNo);

        // There is no support for shipment lines from multiple receivers (Customers/Vendors)
        if WhseShipmentLine.FindFirst() then
            case WhseShipmentLine."Source Document" of

                WhseShipmentLine."Source Document"::"Sales Order":
                    begin
                        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
                        SalesLine.SetRange("Document No.", WhseShipmentLine."Source No.");
                        SalesLine.SetRange("Line No.", WhseShipmentLine."Source Line No.");
                        if SalesLine.FindFirst() then begin
                            Customer.Get(SalesLine."Sell-to Customer No.");
                            exit(Customer.Name);
                        end;
                    end;
                WhseShipmentLine."Source Document"::"Outbound Transfer":
                    begin
                        TransferLine.SetRange("Document No.", WhseShipmentLine."Source No.");
                        TransferLine.SetRange("Line No.", WhseShipmentLine."Source Line No.");
                        if TransferLine.FindFirst() then begin
                            Location.Get(TransferLine."Transfer-to Code");
                            if Location.Name <> '' then
                                exit(Location.Name)
                            else
                                exit(Location.Code);
                        end;
                    end;
                WhseShipmentLine."Source Document"::"Service Order":
                    begin
                        ServiceLine.SetRange("Document Type", ServiceLine."Document Type"::Order);
                        ServiceLine.SetRange("Document No.", WhseShipmentLine."Source No.");
                        ServiceLine.SetRange("Line No.", WhseShipmentLine."Source Line No.");
                        if ServiceLine.FindFirst() then begin
                            Customer.Get(ServiceLine."Customer No.");
                            exit(Customer.Name);
                        end;
                    end;
                WhseShipmentLine."Source Document"::"Purchase Return Order":
                    begin
                        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::"Return Order");
                        PurchaseLine.SetRange("Document No.", WhseShipmentLine."Source No.");
                        PurchaseLine.SetRange("Line No.", WhseShipmentLine."Source Line No.");
                        if PurchaseLine.FindFirst() then begin
                            Vendor.Get(PurchaseLine."Buy-from Vendor No.");
                            exit(Vendor.Name);
                        end;
                    end;
            end;

        exit(MobWmsLanguage.GetMessage('NOT_AVAILABLE'));
    end;

    //
    // IntegrationEvents
    //

    [IntegrationEvent(false, false)]
    local procedure OnGetPackingOrders_OnSetFilterWarehouseShipment(var _HeaderFilter: Record "MOB NS Request Element"; var _WhseShipmentHeader: Record "Warehouse Shipment Header"; var _LicensePlateContent: Record "MOB License Plate Content"; var _IsHandled: Boolean)
    begin
        // Called from MOB Activity for activity types Movement and Invt.Movement
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetPackingOrders_OnIncludeWarehouseShipmentHeader(_WhseShipmentHeader: Record "Warehouse Shipment Header"; var _IncludeInOrderList: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetPackingOrders_OnAfterSetFromWarehouseShipmentHeader(_WhseShipmentHeader: Record "Warehouse Shipment Header"; var _BaseOrderElement: Record "MOB NS BaseDataModel Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetPackingOrders_OnAfterSetCurrentKey(var _BaseOrderElementView: Record "MOB NS BaseDataModel Element")
    begin
    end;
}
