codeunit 81381 "MOB WMS Reference Data"
{
    Access = Public;

    TableNo = "MOB Document Queue";

    trigger OnRun()
    begin
        MobDocQueue := Rec;

        case Rec."Document Type" of

            'GetReferenceData':
                GetReferenceData(XmlResponseDoc);

            'GetLocalizationData':
                GetLocalizationData(XmlResponseDoc);

            else
                Error(MobWmsLanguage.GetMessage('NO_DOC_HANDLER'), Rec."Document Type");
        end;

        // Store the result in the queue and update the status
        MobToolbox.UpdateResult(Rec, XmlResponseDoc);
    end;

    var
        MobDocQueue: Record "MOB Document Queue";
        MobXmlMgt: Codeunit "MOB XML Management";
        MobToolbox: Codeunit "MOB Toolbox";
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        XmlResponseDoc: XmlDocument;
        //
        // HeaderConfiguration
        // (other headerconfiguration constants moved to MOB HeaderField Element)
        //

        UPDATE_SHELF_HEADER_Txt: Label 'UpdateShelfHeader', Locked = true; // Unused in application.cfg but retained for backwards compatibility
        COUNT_ADD_LINE_HEADER_Txt: Label 'AddCountLineHeaderConf', Locked = true; // Unused in application.cfg but retained for backwards compatibility
        ITEM_SEARCH_HEADER_Txt: Label 'ItemSearchHeaderConf', Locked = true; // Hardcoded in Android App for Online Search 'ItemSearch'
        BIN_SEARCH_HEADER_Txt: Label 'BinSearchHeaderConf', Locked = true; //  Hardcoded in Android App for Online Search 'BinSearch'

        //
        // DataTables
        //
        InvalidDataTableIdErr: Label 'Invalid DataTableId="%1": %2', Comment = '%1 contains datatable id, %2 contains last error text', Locked = true;
        REASON_CODE_TABLE_Txt: Label 'ReasonCode', Locked = true;
        SCRAP_CODE_TABLE_Txt: Label 'ScrapCode', Locked = true;
        RET_REASON_CODE_TABLE_Txt: Label 'ReturnReasonCode', Locked = true;
        ITEM_CATEGORY_TABLE_Txt: Label 'ItemCategory', Locked = true;
        PRINTERS_TABLE_Txt: Label 'Printers', Locked = true;
        UOM_TABLE_Txt: Label 'UnitOfMeasure', Locked = true;
        WORKCENTER_TABLE_FILTER_Txt: Label 'WorkCenterFilter', Locked = true;
        ASSIGNED_USER_FILTER_TABLE_Txt: Label 'AssignedUserFilter', Locked = true;
        PRODUCTION_PROGRESS_FILTER_TABLE_Txt: Label 'ProductionProgressFilter', Locked = true;
        SHIPMENT_DOCUMENT_STATUS_FILTER_TABLE_Txt: Label 'ShipmentDocumentStatusFilter', Locked = true;
        LOCATION_TABLE_Txt: Label 'Location', Locked = true;
        FILTER_LOCATION_TABLE_Txt: Label 'FilterLocation', Locked = true;

        //
        // MenuConfiguration
        //
        MobileUserNotAssociatedToMobileGroupErr: Label 'Mobile User %1 is not associated to any Mobile Group.', Comment = '%1 contains Mobile User Id';
        MobileUserNotWhseEmployeeErr: Label 'User "%1" is not set up as a "Warehouse Employee" for any valid location', Comment = '%1 contains UserID';

    local procedure GetReferenceData(var _XmlResponseDoc: XmlDocument)
    var
        TempHeaderFieldElement: Record "MOB HeaderField Element" temporary;
        TempDataTableElement: Record "MOB DataTable Element" temporary;
        MobDeviceMgt: Codeunit "MOB Device Management";
        MobDeviceUsageValidation: Codeunit "MOB Device Usage Validation";
        MobApplicationConfiguration: Codeunit "MOB Application Configuration";
        XmlRequestDoc: XmlDocument;
        XmlResponseData: XmlNode;
        XmlReferenceData: XmlNode;
    begin
        // The Request Document looks like this:
        //  <request name="DocumentTypeName"
        //           created="2009-01-20T22:36:34-08:00"
        //           xmlns="http://schemas.microsoft.com/Dynamics/Mobile/2007/04>
        //    <requestData name="DocumentTypeName">
        //      <ParameterName>RE000004</ParameterName>
        //    </requestData>
        //  </request>
        //

        // 1. Validate Mobile User Setup
        // 2. Get any parameters from the XML
        // 3. Perform the business logic
        // 4. Return a response to the mobile device

        ValidateUserIsAssignedToValidMobileGroup(MobDocQueue."Mobile User ID");
        ValidateUserIsValidWhseEmployee(MobDocQueue."Mobile User ID");

        // Load the request document from the document queue
        MobDocQueue.LoadXMLRequestDoc(XmlRequestDoc);

        // Store device information
        MobDeviceMgt.StoreDeviceProperties(XmlRequestDoc);

        // Validate Unmanaged device usage
        MobDeviceUsageValidation.ValidateDeviceUsage(XmlRequestDoc);

        // Initialize the response xml
        MobToolbox.InitializeResponseDoc(_XmlResponseDoc, XmlResponseData);

        // Add the <ReferenceData> element to the <responseData> element
        MobXmlMgt.AddElement(XmlResponseData, 'ReferenceData', '', '', XmlReferenceData);

        // Verify that Moblie Messages exists - if not create them
        VerifyMessages();

        // Add headerConfiguration
        CreateHeaderConfigurations(TempHeaderFieldElement);
        AddHeaderConfigurationElements(XmlReferenceData, TempHeaderFieldElement);

        // Add registrationCollectorConfiguration
        AddRegCollectorConfigurations(XmlReferenceData);

        // Add menuConfiguration>
        AddMenuConfigurationElements(XmlReferenceData, MobDocQueue."Mobile User ID");

        // Add listdata (tabledata)
        CreateDataTables(TempDataTableElement, MobDocQueue."Mobile User ID");
        AddDataTableElements(XmlReferenceData, TempDataTableElement);

        // Add the device language if specified for the user
        // If an applicable device language code is not specified,
        // the language specified in the device configuration is used
        AddUserLanguageCode(XmlReferenceData, MobDocQueue."Mobile User ID");
        AddUserLanguageCustomizationVersion(XmlReferenceData, MobDocQueue."Mobile User ID");

        // Add applicationConfiguration
        MobApplicationConfiguration.AddApplicationConfigurationVersionToReferenceData(XmlReferenceData);

        // LegacyEvent for "ListDataAsXml" (ListData = DataTable)
        // Also: may now be used to modify UserLanguageCode and UserLanguageCustomization if needed
        OnGetReferenceData_OnAfterAddListDataAsXml(XmlReferenceData);
    end;

    local procedure ValidateUserIsAssignedToValidMobileGroup(_UserID: Code[50]): Boolean
    var
        MobileGroupUser: Record "MOB Group User";
        MobileGroupMenuConfig: Record "MOB Group Menu Config";
    begin
        MobileGroupUser.SetFilter("Mobile User ID", '@' + _UserID);
        if MobileGroupUser.FindFirst() then begin
            MobileGroupMenuConfig.SetCurrentKey(Sorting);
            MobileGroupMenuConfig.SetRange("Mobile Group", MobileGroupUser."Group Code");
            if MobileGroupMenuConfig.IsEmpty() then
                // No menuitems has been defined for the mobile group.
                Error(MobWmsLanguage.GetMessage('NO_MENU_ITEMS'), MobileGroupUser."Group Code");
        end else
            Error(MobileUserNotAssociatedToMobileGroupErr, UpperCase(_UserID));
    end;

    local procedure ValidateUserIsValidWhseEmployee(_UserID: Code[50]): Boolean
    var
        WarehouseEmployee: Record "Warehouse Employee";
        Location: Record Location;
    begin
        Location.SetRange("Use As In-Transit", false);
        if Location.FindSet() then
            repeat
                if WarehouseEmployee.Get(_UserID, Location.Code) then
                    exit(true);
            until Location.Next() = 0;

        Error(MobileUserNotWhseEmployeeErr, _UserID);
    end;

    local procedure GetLocalizationData(var _XmlResponseDoc: XmlDocument)
    var
        MobUser: Record "MOB User";
        MobLanguage: Record "MOB Language";
        MobMessage: Record "MOB Message";
        XmlRequestDoc: XmlDocument;
        XmlResponseData: XmlNode;
        XmlLocalizationData: XmlNode;
        XmlLanguageNode: XmlNode;
    begin
        // Load the request document from the document queue
        MobDocQueue.LoadXMLRequestDoc(XmlRequestDoc);

        // Initialize the response xml
        MobToolbox.InitializeResponseDoc(_XmlResponseDoc, XmlResponseData);

        // Get the user
        if MobUser.Get(MobDocQueue."Mobile User ID") then begin
            if MobUser."Language Code" = '' then
                MobUser."Language Code" := 'ENU'; // Fallback to ENU

            // Get the language code
            if MobLanguage.Get(MobUser."Language Code") then begin
                MobMessage.SetRange("Language Code", MobLanguage.Code);
                if MobMessage.FindSet() then begin
                    // Add the <ReferenceData> element to the <responseData> element
                    MobXmlMgt.AddElement(XmlResponseData, 'localization', '', '', XmlLocalizationData);
                    MobXmlMgt.AddElement(XmlLocalizationData, 'language', '', '', XmlLanguageNode);
                    MobXmlMgt.AddAttribute(XmlLanguageNode, 'code', MobLanguage."Device Language Code");
                    MobXmlMgt.AddAttribute(XmlLanguageNode, 'version', MobLanguage.GetLanguageCustomizationVersion());
                    repeat
                        AddTranslation(XmlLanguageNode, MobMessage.Code, MobMessage.Message);
                    until MobMessage.Next() = 0;
                end;
            end;
        end;
    end;

    local procedure AddTranslation(_XmlLanguageNode: XmlNode; _Key: Text; _Value: Text)
    var
        XmlTranslationNode: XmlNode;
    begin
        // Add translations
        MobXmlMgt.AddElement(_XmlLanguageNode, 'string', _Value, '', XmlTranslationNode);
        MobXmlMgt.AddAttribute(XmlTranslationNode, 'name', _Key);
    end;

    local procedure AddMenuConfigurationElements(var _XmlResponseData: XmlNode; _MobileUserID: Text[65])
    var
        MobileGroupMenuConfig: Record "MOB Group Menu Config";
        MobileGroupUser: Record "MOB Group User";
        XmlConfiguration: XmlNode;
        XmlCreatedNode: XmlNode;
        XmlCDataSection: XmlCData;
        XmlValueNode: XmlNode;
        HeaderConfNS: Text;
    begin
        // Create the configuration "envelope"
        MobXmlMgt.AddElement(_XmlResponseData, 'Configuration', '', '', XmlConfiguration);

        MobXmlMgt.AddElement(XmlConfiguration, 'Key', 'menuConfiguration', '', XmlCreatedNode);
        MobXmlMgt.AddElement(XmlConfiguration, 'Value', '', '', XmlValueNode);

        // Get the header configuration namespace
        HeaderConfNS := MobXmlMgt.GetNodeNSURI(_XmlResponseData);

        // Create an empty CDATA section to add the configuration XML to
        MobXmlMgt.NodeCreateCData(XmlCDataSection, '');

        // Create the start tags of the configuration xml. These must be closed afterwards.
        MobXmlMgt.NodeAppendCDataText(XmlCDataSection, '<menuConfiguration>');
        MobXmlMgt.NodeAppendCDataText(XmlCDataSection, '<useStatusUpdate>true</useStatusUpdate>');
        MobXmlMgt.NodeAppendCDataText(XmlCDataSection, '<items>');

        // Get the user group
        MobileGroupUser.SetFilter("Mobile User ID", '@' + _MobileUserID);
        if MobileGroupUser.FindFirst() then begin
            // Lookup the enabled menu items and add them
            MobileGroupMenuConfig.SetCurrentKey(Sorting);
            MobileGroupMenuConfig.SetRange("Mobile Group", MobileGroupUser."Group Code");
            if MobileGroupMenuConfig.FindSet() then
                repeat
                    MobXmlMgt.NodeAppendCDataText(XmlCDataSection, StrSubstNo('<add name="%1" enabled="true"/>', MobileGroupMenuConfig."Mobile Menu Option"));
                until MobileGroupMenuConfig.Next() = 0
        end;

        // Close CData section
        MobXmlMgt.NodeAppendCDataText(XmlCDataSection, '</items>');
        MobXmlMgt.NodeAppendCDataText(XmlCDataSection, '</menuConfiguration>');

        // Add the CDATA element to the ValueNodeElement
        MobXmlMgt.NodeAppendCData(XmlValueNode, XmlCDataSection);
    end;


    local procedure CreateDataTables(var _DataTable: Record "MOB DataTable Element"; _MobileUserID: Code[50])
    begin
        AddAssignedUserFilterList(_DataTable);
        AddProductionProgressFilterList(_DataTable);
        AddWorkCenterFilterList(_DataTable);
        AddShipmentDocumentStatusFilterList(_DataTable);
        AddLocations(_DataTable, _MobileUserID, DataTable_FILTER_LOCATION_TABLE(), true);
        AddLocations(_DataTable, _MobileUserID, DataTable_LOCATION_TABLE(), false);
        AddItemCategories(_DataTable);
        AddPrinters(_DataTable);
        AddReasonCodes(_DataTable);
        AddReturnReasonCodes(_DataTable);
        AddScrapCodes(_DataTable);
        AddUnitOfMeasureCodes(_DataTable);
        AddYesNoMenu(_DataTable);

        // Allow integration partners to add new DataTables, first subscriber will see an initialized record
        _DataTable.Init();
        _DataTable.Key := 0;
        _DataTable.SetMustCallCreateNext(true);
        OnGetReferenceData_OnAddDataTables(_DataTable, _MobileUserID);

        // Allow integration partners to update existing DataTables
        _DataTable.SetMustCallCreateNext(false);
        if _DataTable.FindFirst() then
            repeat
                OnGetReferenceData_OnAfterAddDataTableEntry(_DataTable);
            until _DataTable.Next() = 0;
    end;

    local procedure AddDataTableElements(var _XmlResponseData: XmlNode; var _DataTable: Record "MOB DataTable Element")
    var
        xDataTable: Record "MOB DataTable Element";
    begin
        if _DataTable.IsEmpty() then
            exit;

        xDataTable.Copy(_DataTable);

        _DataTable.SetCurrentKey(DataTableId);
        if _DataTable.FindSet() then
            repeat
                AddDataTableElement(_XmlResponseData, _DataTable);
            until _DataTable.Next() = 0;

        _DataTable.Copy(xDataTable);
    end;

    local procedure AddDataTableElement(var _XmlResponseData: XmlNode; var _DataTable: Record "MOB DataTable Element")
    var
        XmlDataTableIdNode: XmlNode;
        XmlDataTableIdElement: XmlElement;
    begin
        // Verify Xml naming conventions since DataTableId is written as NodeName in Xml
        if not MobXmlMgt.IsValidNodeName(_DataTable.DataTableId) then
            Error(InvalidDataTableIdErr, _DataTable.DataTableId, GetLastErrorText());

        // Add the mandatory nodes
        MobXmlMgt.AddElement(_XmlResponseData, _DataTable.DataTableId, '', '', XmlDataTableIdNode);

        XmlDataTableIdElement := XmlDataTableIdNode.AsXmlElement();
        MobXmlMgt.AddDataTableEntry2XmlElement(XmlDataTableIdElement, _DataTable);
    end;

    local procedure AddLocations(var _DataTable: Record "MOB DataTable Element"; _MobileUserID: Text[65]; _DataTableId: Text[30]; _IncludeAll: Boolean)
    var
        WhseEmployee: Record "Warehouse Employee";
        FilteredLocation: Record Location;
        LocationFilter: Text;
        DefaultLocation: Code[10];
    begin
        // The MobWmsToolbox.GetLocationFilter() can be overruled by a subscriber determining which Locations the user are able to use
        LocationFilter := MobWmsToolbox.GetLocationFilter(_MobileUserID);

        _DataTable.InitDataTable(_DataTableId);

        // Add the locations setup for this employee
        // First add the default location (to make it the first in the list)
        // Then add the other locations
        // Finally add an "all" entry that returns for all locations in the list

        // Get the default location
        WhseEmployee.SetRange("User ID", _MobileUserID);
        WhseEmployee.SetRange(Default, true);
        WhseEmployee.SetFilter("Location Code", LocationFilter);
        if WhseEmployee.FindFirst() then begin
            DefaultLocation := WhseEmployee."Location Code";
            _DataTable.Create_Code(DefaultLocation);
        end;

        // Get the other locations
        FilteredLocation.SetFilter(Code, LocationFilter);
        if DefaultLocation <> '' then begin
            // Avoid finding the Default location again
            FilteredLocation.FilterGroup(2);
            FilteredLocation.SetFilter(Code, '<>%1', DefaultLocation);
            FilteredLocation.FilterGroup(0);
        end;
        if FilteredLocation.FindSet() then
            repeat
                _DataTable.Create_Code(FilteredLocation.Code);
            until FilteredLocation.Next() = 0;

        if _IncludeAll then
            _DataTable.Create_Code('All');
    end;

    local procedure AddReasonCodes(var _DataTable: Record "MOB DataTable Element")
    var
        ReasonCode: Record "Reason Code";
    begin
        _DataTable.InitDataTable(REASON_CODE_TABLE_Txt);

        // Add all reason codes
        if ReasonCode.FindSet() then
            repeat
                _DataTable.Create_CodeAndName(ReasonCode.Code, ReasonCode.Description);
            until ReasonCode.Next() = 0;
    end;

    local procedure AddReturnReasonCodes(var _DataTable: Record "MOB DataTable Element")
    var
        ReturnReason: Record "Return Reason";
    begin
        _DataTable.InitDataTable(RET_REASON_CODE_TABLE_Txt);

        // Add all return reason descriptions as Code's
        if ReturnReason.FindSet() then
            repeat
                _DataTable.Create_Code(ReturnReason.Description);  // Description used a keyColumn
            until ReturnReason.Next() = 0;
    end;

    local procedure AddScrapCodes(var _DataTable: Record "MOB DataTable Element")
    var
        Scrap: Record Scrap;
    begin
        _DataTable.InitDataTable(SCRAP_CODE_TABLE_Txt);

        // Add all scrap codes incl. blank default code
        _DataTable.Create_CodeAndName('', '');

        // If user only has an Essentials License, he will get an error on login if company contains Scrap Codes
        // This is mostly a problem when using Cronus company for Demo, as normally an essentials system shouldn't have been able to insert records in the Scrap table in the first place.
        if Scrap.ReadPermission() then
            if Scrap.FindSet() then
                repeat
                    if Scrap.Description <> '' then
                        _DataTable.Create_CodeAndName(Scrap.Code, Scrap.Description)
                    else
                        _DataTable.Create_CodeAndName(Scrap.Code, Scrap.Code);
                until Scrap.Next() = 0;
    end;

    local procedure CreateHeaderConfigurations(var _HeaderField: Record "MOB HeaderField Element")
    begin
        // Add all Configuration
        // When the configuration is added it must be wrapped in a <![CDATA[  ]]> section
        // This is to prevent the configuration value (in XML format) from being processed when it is converted to data on the mobile device
        AddHeaderConfiguration_PickOrderFilters(_HeaderField);
        AddHeaderConfiguration_ReceiveOrderFilters(_HeaderField);
        AddHeaderConfiguration_PutAwayOrderFilters(_HeaderField);
        AddHeaderConfiguration_MoveOrderFilters(_HeaderField);
        AddHeaderConfiguration_ProdOrderLineFilters(_HeaderField);
        AddHeaderConfiguration_ProdOutputHeader(_HeaderField);
        AddHeaderConfiguration_ProdOutputActionHeader(_HeaderField);
        AddHeaderConfiguration_SubstituteProdProdOrderComponentHeader(_HeaderField);
        AddHeaderConfiguration_AssemblyOrderFilters(_HeaderField);
        AddHeaderConfiguration_CreateAssemblyOrderHeader(_HeaderField);
        AddHeaderConfiguration_AdjustQtyToAssembleHeader(_HeaderField);
        AddHeaderConfiguration_UnplannedMoveHeader(_HeaderField);
        AddHeaderConfiguration_UnplannedMoveAdvancedHeader(_HeaderField);
        AddHeaderConfiguration_AdjustQuantityHeader(_HeaderField);
        AddHeaderConfiguration_UpdateShelfHeader(_HeaderField);
        AddHeaderConfiguration_UnplannedCountHeader(_HeaderField);
        AddHeaderConfiguration_BinContentCfgHeader(_HeaderField);
        AddHeaderConfiguration_SubstituteItemsCfgHeader(_HeaderField);
        AddHeaderConfiguration_LocateItemCfgHeader(_HeaderField);
        AddHeaderConfiguration_ItemCrossReferenceHeade(_HeaderField);
        AddHeaderConfiguration_AddCountLineHeaderConf(_HeaderField);
        AddHeaderConfiguration_ItemSearchHeaderConf(_HeaderField);
        AddHeaderConfiguration_BinSearchHeaderConf(_HeaderField);
        AddHeaderConfiguration_PrintLabelHeader(_HeaderField);
        AddHeaderConfiguration_PrintLabelTemplateHeader(_HeaderField);
        AddHeaderConfiguration_PrintLabelTemplateMenuItemHeader(_HeaderField);
        AddHeaderConfiguration_PrintLabelTemplateLicensePlateHeader(_HeaderField);
        AddHeaderConfiguration_AttachmentsHeader(_HeaderField);
        AddHeaderConfiguration_AddCountLineHeader(_HeaderField);
        AddHeaderConfiguration_BulkMoveHeader(_HeaderField);
        AddHeaderConfiguration_ItemDimensionsHeader(_HeaderField);
        AddHeaderConfiguration_ShipOrderFilters(_HeaderField);
        AddHeaderConfiguration_ToteShippingHeader(_HeaderField);
        AddHeaderConfiguration_PostShipmentCfgHeader(_HeaderField);
        AddHeaderConfiguration_RegisterItemImageCfgHeader(_HeaderField);
        AddHeaderConfiguration_RegisterImageCfgHeader(_HeaderField);
        AddHeaderConfiguration_HistoryHeader(_HeaderField);

        // Allow integration partners to add new header configurations to support new screens on the mobile devices, first subscriber will see an initialized record
        _HeaderField.Init();
        _HeaderField.Key := 0;
        _HeaderField.SetMustCallInitNext(true);
        OnGetReferenceData_OnAddHeaderConfigurations(_HeaderField);

        // Allow integration partners to update existing HeaderConfigurations
        _HeaderField.SetMustCallInitNext(false);
        if _HeaderField.FindFirst() then
            repeat
                OnGetReferenceData_OnAfterAddHeaderField(_HeaderField);
            until _HeaderField.Next() = 0;
    end;

    local procedure AddHeaderConfigurationElements(var _XmlResponseData: XmlNode; var _HeaderFields: Record "MOB HeaderField Element")
    var
        xHeaderField: Record "MOB HeaderField Element";
    begin
        if _HeaderFields.IsEmpty() then
            exit;

        xHeaderField.Copy(_HeaderFields);

        // For HeaderFields only Sorting1 is implemented and always for Id numeric value (padded value)
        _HeaderFields.SetCurrentKey(ConfigurationKey, "Sorting1 (internal)");

        if _HeaderFields.FindSet() then
            repeat
                // group by ConfigurationKey, then write all steps for that key
                _HeaderFields.SetRange(ConfigurationKey, _HeaderFields.ConfigurationKey);
                AddHeaderConfigurationElement(_XmlResponseData, _HeaderFields);
                _HeaderFields.SetRange(ConfigurationKey);
            until _HeaderFields.Next() = 0;

        _HeaderFields.Copy(xHeaderField);
    end;

    local procedure AddHeaderConfigurationElement(var _XmlResponseData: XmlNode; var _HeaderFields: Record "MOB HeaderField Element")
    var
        XmlConfigurationNode: XmlNode;
        XmlKeyNode: XmlNode;
        XmlValueNode: XmlNode;
        XmlHeaderConfigurationNode: XmlNode;
        XmlLinesNode: XmlNode;
        ConfigurationKey: Text[50];
    begin
        _HeaderFields.FindFirst();
        ConfigurationKey := _HeaderFields.ConfigurationKey;    // Assuming all steps have same key

        // Add the mandatory nodes
        MobXmlMgt.AddElement(_XmlResponseData, 'Configuration', '', '', XmlConfigurationNode);
        MobXmlMgt.AddElement(XmlConfigurationNode, 'Key', ConfigurationKey, '', XmlKeyNode);
        MobXmlMgt.AddElement(XmlConfigurationNode, 'Value', '', '', XmlValueNode);

        // Create the <registrationCollectorConfiguration> XmlNode (incl. subnodes) to be added as CDATA below
        XmlHeaderConfigurationNode := XmlElement.Create('headerConfiguration').AsXmlNode();
        MobXmlMgt.AddElement(XmlHeaderConfigurationNode, 'lines', '', '', XmlLinesNode);
        MobXmlMgt.AddHeaderFieldsaddElements(XmlLinesNode, _HeaderFields);

        // Write CDATA to Value-node
        MobXmlMgt.NodeAppendNodeAsCData(XmlValueNode, XmlHeaderConfigurationNode);
    end;

    local procedure AddRegCollectorConfigurations(var _XmlReferenceData: XmlNode)
    var
        TempSteps: Record "MOB Steps Element" temporary;
    begin
        // Allow integration partners to add new registrations collector configurations to support extra steps on order lines
        TempSteps.SetMustCallCreateNext(true);
        OnGetReferenceData_OnAddRegistrationCollectorConfigurations(TempSteps);

        // Allow integration partners to update custom registration collectors (standard Mobile WMS has no registration collectors in ReferenceData)
        TempSteps.SetMustCallCreateNext(false);
        if TempSteps.FindFirst() then
            repeat
                OnGetReferenceData_OnAfterAddRegistrationCollectorStep(TempSteps);
            until TempSteps.Next() = 0;

        AddRegistrationCollectorConfigurationElements(_XmlReferenceData, TempSteps);

        // Also, allow partners to write collector configurations as xml
        OnGetReferenceData_OnAfterAddRegistrationCollectorConfigurationsAsXml(_XmlReferenceData);

        // Legacy example code to register extra information on an order line
        // CreateRegCollectorConfiguration(XmlResponseData,'DemoOrderLineExtraInfo');
    end;

    local procedure AddRegistrationCollectorConfigurationElements(var _XmlResponseData: XmlNode; var _Steps: Record "MOB Steps Element")
    var
        xSteps: Record "MOB Steps Element";
    begin
        if _Steps.IsEmpty() then
            exit;

        xSteps.Copy(_Steps);

        _Steps.SetCurrentKey(ConfigurationKey);
        if _Steps.FindSet() then
            repeat
                // group by ConfigurationKey, then write all steps for that key
                _Steps.SetRange(ConfigurationKey, _Steps.ConfigurationKey);
                AddRegistrationCollectorConfigurationElement(_XmlResponseData, _Steps);
                _Steps.SetRange(ConfigurationKey);
            until _Steps.Next() = 0;

        _Steps.Copy(xSteps);
    end;

    local procedure AddRegistrationCollectorConfigurationElement(var _XmlResponseData: XmlNode; var _Steps: Record "MOB Steps Element")
    var
        XmlConfigurationNode: XmlNode;
        XmlKeyNode: XmlNode;
        XmlValueNode: XmlNode;
        XmlRegistrationCollectorConfigurationNode: XmlNode;
        XmlStepsNode: XmlNode;
        ConfigurationKey: Text[50];
    begin
        _Steps.FindFirst();
        ConfigurationKey := _Steps.ConfigurationKey;    // Assuming all steps have same key

        // Add the mandatory nodes
        MobXmlMgt.AddElement(_XmlResponseData, 'Configuration', '', '', XmlConfigurationNode);
        MobXmlMgt.AddElement(XmlConfigurationNode, 'Key', ConfigurationKey, '', XmlKeyNode);
        MobXmlMgt.AddElement(XmlConfigurationNode, 'Value', '', '', XmlValueNode);

        // Create the <registrationCollectorConfiguration> XmlNode (incl. subnodes) to be added as CDATA below
        XmlRegistrationCollectorConfigurationNode := XmlElement.Create('registrationCollectorConfiguration').AsXmlNode();
        MobXmlMgt.AddElement(XmlRegistrationCollectorConfigurationNode, 'steps', '', '', XmlStepsNode);
        MobXmlMgt.AddStepsaddElements(XmlStepsNode, _Steps);

        // Write CDATA to Value-node
        MobXmlMgt.NodeAppendNodeAsCData(XmlValueNode, XmlRegistrationCollectorConfigurationNode);
    end;

    local procedure AddYesNoMenu(var _DataTable: Record "MOB DataTable Element")
    begin
        // Add a drop down that can be used for a yes/no question. 'No' first as default.
        _DataTable.InitDataTable('YesNoMenu');
        _DataTable.Create_Option('No');
        _DataTable.Create_Option('Yes');
    end;

    local procedure AddItemCategories(var _DataTable: Record "MOB DataTable Element")
    var
        ItemCategory: Record "Item Category";
    begin
        _DataTable.InitDataTable(DataTable_ITEM_CATEGORY_TABLE());

        //Add Blank option
        _DataTable.Create_CodeAndName('', '');

        // Add all Item Categories
        if ItemCategory.FindSet() then
            repeat
                _DataTable.Create_CodeAndName(ItemCategory.Code, ItemCategory.Description);
            until ItemCategory.Next() = 0;
    end;

    /// <summary>
    /// Add mobile printers as labels printers
    /// </summary>
    local procedure AddPrinters(var _DataTable: Record "MOB DataTable Element")
    var
        MobPrinter: Record "MOB Printer";
    begin

        _DataTable.InitDataTable(PRINTERS_TABLE_Txt);

        MobPrinter.SetRange(Enabled, true);
        if MobPrinter.FindSet() then
            repeat
                _DataTable.Create();
                _DataTable.SetValue('Address', MobPrinter.Address);
                _DataTable.SetValue('Name', MobPrinter.Name);
                _DataTable.SetValue('Type', 'Zebra');
            until MobPrinter.Next() = 0;
    end;

    /// <summary>
    /// Add work centers
    /// </summary>
    local procedure AddWorkCenterFilterList(var _DataTable: Record "MOB DataTable Element")
    var
        WorkCenter: Record "Work Center";
    begin

        _DataTable.InitDataTable(DataTable_WORKCENTER_FILTER_TABLE());
        _DataTable.Create_CodeAndName('All', MobWmsLanguage.GetMessage('FILTER_ALL'));

        WorkCenter.SetRange(Blocked, false);
        if WorkCenter.FindSet() then
            repeat
                _DataTable.Create();
                _DataTable.SetValue('Code', WorkCenter."No.");
                _DataTable.SetValue('Name', WorkCenter.Name);
            until WorkCenter.Next() = 0;

    end;

    local procedure AddAssignedUserFilterList(var _DataTable: Record "MOB DataTable Element")
    begin
        _DataTable.InitDataTable(DataTable_ASSIGNED_USER_FILTER_TABLE());

        // Add assigned user filters
        _DataTable.Create_CodeAndName('MineAndUnassigned', MobWmsLanguage.GetMessage('FILTER_MINE_UNASSIGNED'));
        _DataTable.Create_CodeAndName('All', MobWmsLanguage.GetMessage('FILTER_ALL'));
        _DataTable.Create_CodeAndName('OnlyMine', MobWmsLanguage.GetMessage('FILTER_ONLY_MINE'));
    end;

    local procedure AddProductionProgressFilterList(var _DataTable: Record "MOB DataTable Element")
    begin
        _DataTable.InitDataTable(DataTable_PRODUCTION_PROGRESS_FILTER_TABLE());

        // Add assigned user filters
        _DataTable.Create_CodeAndName('Ready', MobWmsLanguage.GetMessage('FILTER_PROGRESS_READY'));
        _DataTable.Create_CodeAndName('Completed', MobWmsLanguage.GetMessage('FILTER_PROGRESS_COMPLETED'));
        _DataTable.Create_CodeAndName('All', MobWmsLanguage.GetMessage('FILTER_ALL'));
    end;

    local procedure AddShipmentDocumentStatusFilterList(var _DataTable: Record "MOB DataTable Element")
    begin
        _DataTable.InitDataTable(DataTable_SHIPMENT_DOCUMENT_STATUS_FILTER_TABLE());

        // Add assigned user filters
        _DataTable.Create_CodeAndName('All', MobWmsLanguage.GetMessage('FILTER_ALL'));
        // _DataTable.Create_CodeAndName('', '');   -- intentionally avoid option blank, hard-to-explain meaning with no text in Web Client
        _DataTable.Create_CodeAndName('PartiallyPicked', MobWmsLanguage.GetMessage('SHIPMENT_DOCUMENT_STATUS_PARTIALLY_PICKED'));
        _DataTable.Create_CodeAndName('PartiallyShipped', MobWmsLanguage.GetMessage('SHIPMENT_DOCUMENT_STATUS_PARTIALLY_SHIPPED'));
        _DataTable.Create_CodeAndName('CompletelyPicked', MobWmsLanguage.GetMessage('SHIPMENT_DOCUMENT_STATUS_COMPLETELY_PICKED'));
    end;

    local procedure AddHeaderConfiguration_PickOrderFilters(var _HeaderConfiguration: Record "MOB HeaderField Element")
    begin
        _HeaderConfiguration.InitConfigurationKey_PickOrderFilters();

        // Add the header lines
        _HeaderConfiguration.Create_ListField_FilterLocationAsLocation(10);
        _HeaderConfiguration.Create_ListField_AssignedUserFilterAsAssignedUser(20);
    end;

    local procedure AddHeaderConfiguration_MoveOrderFilters(var _HeaderConfiguration: Record "MOB HeaderField Element")
    begin
        _HeaderConfiguration.InitConfigurationKey_MoveOrderFilters();

        // Add the header lines
        _HeaderConfiguration.Create_ListField_FilterLocationAsLocation(10);
        _HeaderConfiguration.Create_ListField_AssignedUserFilterAsAssignedUser(20);
    end;

    local procedure AddHeaderConfiguration_ReceiveOrderFilters(var _HeaderConfiguration: Record "MOB HeaderField Element")
    begin
        _HeaderConfiguration.InitConfigurationKey_ReceiveOrderFilters();

        // Add the header lines
        _HeaderConfiguration.Create_ListField_FilterLocationAsLocation(10);
        _HeaderConfiguration.Create_DateField_ExpRecvDateAsDate(20);      // Expected Receive Date
        _HeaderConfiguration.Create_TextField_PurchaseOrderNumber(30);
        _HeaderConfiguration.Create_ListField_AssignedUserFilterAsAssignedUser(40);
    end;

    local procedure AddHeaderConfiguration_PutAwayOrderFilters(var _HeaderConfiguration: Record "MOB HeaderField Element")
    begin
        _HeaderConfiguration.InitConfigurationKey_PutAwayOrderFilters();

        // Add the header lines
        _HeaderConfiguration.Create_ListField_FilterLocationAsLocation(10);
        _HeaderConfiguration.Create_ListField_AssignedUserFilterAsAssignedUser(20);
    end;

    local procedure AddHeaderConfiguration_ProdOrderLineFilters(var _HeaderConfiguration: Record "MOB HeaderField Element")
    begin
        _HeaderConfiguration.InitConfigurationKey_ProdOrderLineFilters();

        _HeaderConfiguration.Create_ListField_FilterLocationAsLocation(10);
        _HeaderConfiguration.Create_DateField_StartingDate(20);
        _HeaderConfiguration.Create_ListField_ProductionProgress(30);
        _HeaderConfiguration.Create_ListField_WorkCenterFilter(40);
        _HeaderConfiguration.Create_ListField_AssignedUserFilterAsAssignedUser(50);
    end;

    local procedure AddHeaderConfiguration_ProdOutputHeader(var _HeaderConfiguration: Record "MOB HeaderField Element")
    var
        DummyProdOrderLine: Record "Prod. Order Line";
    begin
        _HeaderConfiguration.InitConfigurationKey_ProdOutputHeader();

        _HeaderConfiguration.Create_TextField(10, 'BackendID', false);
        _HeaderConfiguration.Set_label(StrSubstNo(MobWmsLanguage.GetMessage('FROM'), DummyProdOrderLine.TableCaption()));
        _HeaderConfiguration.Set_clearOnClear(false);
        _HeaderConfiguration.Set_acceptBarcode(false);
        _HeaderConfiguration.Set_length(40);
        _HeaderConfiguration.Set_locked(true);
        _HeaderConfiguration.Save();

        // Using listValues instead of DataTable, since the "Unfinished"-value is "pseudo" value and do not exact match ProdOrderRtngLine."Operation Status"
        _HeaderConfiguration.Create_ListFieldFromListValues(20, 'RouteOperationStatus',
            MobWmsLanguage.GetMessage('ROUTE_OPERATION_STATUS'),
            MobWmsLanguage.GetMessage('ROUTE_OPERATION_STATUS_UNFINISHED') + ';' + MobWmsLanguage.GetMessage('FILTER_ALL'),
            MobWmsLanguage.GetMessage('ROUTE_OPERATION_STATUS_UNFINISHED'));
    end;

    local procedure AddHeaderConfiguration_ProdOutputActionHeader(var _HeaderConfiguration: Record "MOB HeaderField Element")
    var
        DummyProdOrderLine: Record "Prod. Order Line";
    begin
        _HeaderConfiguration.InitConfigurationKey_ProdOutputActionHeader();

        // Must include at least one field to be able to Accept on page
        _HeaderConfiguration.Create_TextField(10, 'BackendID', false);
        _HeaderConfiguration.Set_label(StrSubstNo(MobWmsLanguage.GetMessage('FROM'), DummyProdOrderLine.TableCaption()));
        _HeaderConfiguration.Set_clearOnClear(false);
        _HeaderConfiguration.Set_acceptBarcode(false);
        _HeaderConfiguration.Set_length(40);
        _HeaderConfiguration.Set_locked(true);
        _HeaderConfiguration.Save();
    end;

    local procedure AddHeaderConfiguration_SubstituteProdProdOrderComponentHeader(var _HeaderConfiguration: Record "MOB HeaderField Element")
    begin
        _HeaderConfiguration.InitConfigurationKey_SubstituteProdOrderComponentHeader();
        // all fields locked, can only substitute item that is already a Prod. Component

        _HeaderConfiguration.Create_TextField_ItemNumber(10);
        _HeaderConfiguration.Set_locked(true);

        _HeaderConfiguration.Create_TextField(20, 'VariantCode', false);
        _HeaderConfiguration.Set_label(MobWmsLanguage.GetMessage('VARIANT_LABEL') + ':');
        _HeaderConfiguration.Set_length(10);
        _HeaderConfiguration.Set_optional(true);
        _HeaderConfiguration.Set_locked(true);
        _HeaderConfiguration.Save();

        _HeaderConfiguration.Create_TextField(30, 'UnitOfMeasure', false);
        _HeaderConfiguration.Set_label(MobWmsLanguage.GetMessage('UOM_LABEL') + ':');
        _HeaderConfiguration.Set_length(10);
        _HeaderConfiguration.Set_optional(true);
        _HeaderConfiguration.Set_locked(true);
        _HeaderConfiguration.Save();
    end;

    local procedure AddHeaderConfiguration_AssemblyOrderFilters(var _HeaderConfiguration: Record "MOB HeaderField Element")
    begin
        _HeaderConfiguration.InitConfigurationKey_AssemblyOrderFilters();

        _HeaderConfiguration.Create_ListField_FilterLocationAsLocation(10);
        _HeaderConfiguration.Create_DateField_StartingDate(20);
        _HeaderConfiguration.Create_ListField_AssignedUserFilterAsAssignedUser(30);
    end;

    local procedure AddHeaderConfiguration_CreateAssemblyOrderHeader(var _HeaderConfiguration: Record "MOB HeaderField Element")
    begin
        _HeaderConfiguration.InitConfigurationKey_CreateAssemblyOrderHeader();

        // Add the header lines
        _HeaderConfiguration.Create_ListField_Location(10);
        _HeaderConfiguration.Create_TextField_ItemNumber(20);
    end;

    local procedure AddHeaderConfiguration_AdjustQtyToAssembleHeader(var _HeaderConfiguration: Record "MOB HeaderField Element")
    var
        DummyAssemblyHeader: Record "Assembly Header";
    begin
        _HeaderConfiguration.InitConfigurationKey_AdjustQtyToAssembleHeader();

        _HeaderConfiguration.Create_TextField_OrderBackendID(10);
        _HeaderConfiguration.Set_label(StrSubstNo(MobWmsLanguage.GetMessage('FROM'), DummyAssemblyHeader.TableCaption()));
    end;

    local procedure AddHeaderConfiguration_UnplannedMoveHeader(var _HeaderConfiguration: Record "MOB HeaderField Element")
    begin
        _HeaderConfiguration.InitConfigurationKey_UnplannedMoveHeader();

        // Add the header lines
        _HeaderConfiguration.Create_ListField_Location(10);
        _HeaderConfiguration.Set_linkedElement(20);
        _HeaderConfiguration.Set_linkColumn('Code');

        _HeaderConfiguration.Create_ListField_NewLocation(20);

        if MobToolbox.ShowAvailableQtyOnUnplannedMove() then
            _HeaderConfiguration.Create_TextField_Bin(30);

        _HeaderConfiguration.Create_TextField_ItemNumber(40);
    end;

    local procedure AddHeaderConfiguration_UnplannedMoveAdvancedHeader(var _HeaderConfiguration: Record "MOB HeaderField Element")
    begin
        _HeaderConfiguration.InitConfigurationKey_UnplannedMoveAdvancedHeader();

        // Add the header lines
        _HeaderConfiguration.Create_ListField_Location(10);
        _HeaderConfiguration.Set_linkedElement(20);
        _HeaderConfiguration.Set_linkColumn('Code');
        _HeaderConfiguration.Set_clearOnClear(false);

        _HeaderConfiguration.Create_ListField_NewLocation(20);
        _HeaderConfiguration.Set_clearOnClear(false);

        _HeaderConfiguration.Create_TextField_Number(30);
    end;

    local procedure AddHeaderConfiguration_AdjustQuantityHeader(var _HeaderConfiguration: Record "MOB HeaderField Element")
    begin
        _HeaderConfiguration.InitConfigurationKey_AdjustQuantityHeader();

        // Add the header lines
        _HeaderConfiguration.Create_ListField_Location(10);

        _HeaderConfiguration.Create_TextField_Bin(20);
        _HeaderConfiguration.Set_optional(true);

        _HeaderConfiguration.Create_TextField_ItemNumber(30);
    end;

    local procedure AddHeaderConfiguration_UpdateShelfHeader(var _HeaderConfiguration: Record "MOB HeaderField Element")
    begin
        _HeaderConfiguration.InitConfigurationKey(UPDATE_SHELF_HEADER_Txt);

        // Add the header lines
        _HeaderConfiguration.Create_ListField_Location(10);
        _HeaderConfiguration.Create_TextField_ItemNumberAsItem(20);
        _HeaderConfiguration.Create_TextField_Bin_NoSearchType(30);
    end;

    local procedure AddHeaderConfiguration_UnplannedCountHeader(var _HeaderConfiguration: Record "MOB HeaderField Element")
    begin
        _HeaderConfiguration.InitConfigurationKey_UnplannedCountHeader();

        // Add the header lines
        _HeaderConfiguration.Create_ListField_Location(10);
        _HeaderConfiguration.Create_TextField_ItemNumberAsItem(20);
    end;

    local procedure AddHeaderConfiguration_BinContentCfgHeader(var _HeaderConfiguration: Record "MOB HeaderField Element")
    begin
        _HeaderConfiguration.InitConfigurationKey_BinContentCfgHeader();

        // Add the header lines
        _HeaderConfiguration.Create_ListField_Location(10);
        _HeaderConfiguration.Create_TextField_Bin(20);
    end;

    local procedure AddHeaderConfiguration_SubstituteItemsCfgHeader(var _HeaderConfiguration: Record "MOB HeaderField Element")
    begin
        _HeaderConfiguration.InitConfigurationKey_SubstituteItemsCfgHeader();

        // Add the header lines
        _HeaderConfiguration.Create_TextField_ItemNumber(10);
    end;

    local procedure AddHeaderConfiguration_LocateItemCfgHeader(var _HeaderConfiguration: Record "MOB HeaderField Element")
    begin
        _HeaderConfiguration.InitConfigurationKey_LocateItemCfgHeader();

        // Add the header lines
        _HeaderConfiguration.Create_ListField_FilterLocationAsLocation(10);
        _HeaderConfiguration.Create_TextField_ItemNumber(20);
    end;

    local procedure AddHeaderConfiguration_ItemCrossReferenceHeade(var _HeaderConfiguration: Record "MOB HeaderField Element")
    begin
        _HeaderConfiguration.InitConfigurationKey_ItemCrossReferenceHeader();

        // Add the header lines
        _HeaderConfiguration.Create_TextField_ItemNumber(10);
    end;

    local procedure AddHeaderConfiguration_AddCountLineHeaderConf(var _HeaderConfiguration: Record "MOB HeaderField Element")
    begin
        _HeaderConfiguration.InitConfigurationKey(COUNT_ADD_LINE_HEADER_Txt);

        // Add the header lines
        _HeaderConfiguration.Create_TextField_ItemNumberAsItem(10);
        _HeaderConfiguration.Create_ListField_Location(20);
        _HeaderConfiguration.Create_TextField_Bin_NoSearchType(30);
        _HeaderConfiguration.Create_IntegerField_Quantity_NoAcceptBarcode(40);
    end;

    local procedure AddHeaderConfiguration_ItemSearchHeaderConf(var _HeaderConfiguration: Record "MOB HeaderField Element")
    var
        ItemCategory: Record "Item Category";
    begin
        _HeaderConfiguration.InitConfigurationKey(ITEM_SEARCH_HEADER_Txt);

        // Add the header lines
        _HeaderConfiguration.Create_TextField_ItemNumberAsItemNo_NoAcceptBarcode(10);
        _HeaderConfiguration.Create_TextField_ItemDescription(20);
        if not ItemCategory.IsEmpty() then
            _HeaderConfiguration.Create_ListField_ItemCategory(30);
    end;

    local procedure AddHeaderConfiguration_BinSearchHeaderConf(var _HeaderConfiguration: Record "MOB HeaderField Element")
    begin
        _HeaderConfiguration.InitConfigurationKey(BIN_SEARCH_HEADER_Txt);

        // Add the header lines
        _HeaderConfiguration.Create_ListField_Location(10);
    end;

    local procedure AddHeaderConfiguration_PrintLabelHeader(var _HeaderConfiguration: Record "MOB HeaderField Element")
    begin
        _HeaderConfiguration.InitConfigurationKey_PrintLabelHeader();

        _HeaderConfiguration.Create_TextField_ItemNumber(10);
        _HeaderConfiguration.Create_TextField_LotNumber(20);
        _HeaderConfiguration.Create_DateField_ExpirationDate(30);
        _HeaderConfiguration.Create_IntegerField_Quantity(40);

        // Field: Printer (list)
        _HeaderConfiguration.Create_ListField(50, 'Printer', false);
        _HeaderConfiguration.Set_label(MobWmsLanguage.GetMessage('Printer') + ':');
        _HeaderConfiguration.Set_dataTable(PRINTERS_TABLE_Txt);
        _HeaderConfiguration.Set_dataKeyColumn('Name');
        _HeaderConfiguration.Set_dataDisplayColumn('Name');
        _HeaderConfiguration.Set_clearOnClear(false);
        _HeaderConfiguration.Set_acceptBarcode(false);
        _HeaderConfiguration.Save();

        // Field: NumberOfLabels
        _HeaderConfiguration.Create_IntegerField(60, 'NumberOfLabels', false);
        _HeaderConfiguration.Set_label(MobWmsLanguage.GetMessage('PRINT_QTY') + ':');
        _HeaderConfiguration.Set_clearOnClear(true);
        _HeaderConfiguration.Set_acceptBarcode(false);
        _HeaderConfiguration.Set_minValue(0);
        _HeaderConfiguration.Set_maxValue(5);
        _HeaderConfiguration.Save();
    end;

    /// <summary>
    /// Lookup to display Labels are available for printing.
    /// Print functionality will collect most of the needed info in Steps, not the header. "ReferenceID" is in header.
    /// </summary>
    local procedure AddHeaderConfiguration_PrintLabelTemplateHeader(var _HeaderConfiguration: Record "MOB HeaderField Element")
    begin
        _HeaderConfiguration.InitConfigurationKey_PrintLabelTemplateHeader();

        // "ReferenceID" is from Order Lines
        // It identifies the context, this header is being called from
        _HeaderConfiguration.Create_TextField_ReferenceID(10);
        _HeaderConfiguration.Set_optional(true);

        // Location filter
        _HeaderConfiguration.Create_ListField_Location(20);
    end;

    /// <summary>
    /// Main menu display Labels are available for printing.
    /// Print functionality will collect most of the needed info in Steps.
    /// </summary>
    local procedure AddHeaderConfiguration_PrintLabelTemplateMenuItemHeader(var _HeaderConfiguration: Record "MOB HeaderField Element")
    begin
        _HeaderConfiguration.InitConfigurationKey_PrintLabelTemplateMenuItemHeader();

        // Location filter
        _HeaderConfiguration.Create_ListField_Location(10);

        // Item Filter
        _HeaderConfiguration.Create_TextField_ItemNumber(20);
        _HeaderConfiguration.Set_optional(true);
    end;

    /// <summary>
    /// Lookup to display Labels are available for printing.
    /// Print functionality will collect most of the needed info in Steps.
    /// The value "LicensePlate" is collected from header and determine if print or reprint should be done.
    /// If "LicensePlate" is empty, it will be a print, if not empty, it will be a reprint.
    /// </summary>
    local procedure AddHeaderConfiguration_PrintLabelTemplateLicensePlateHeader(var _HeaderConfiguration: Record "MOB HeaderField Element")
    begin
        _HeaderConfiguration.InitConfigurationKey_PrintLabelTemplateLicensePlateHeader();

        // Location filter
        _HeaderConfiguration.Create_ListField_Location(10);

        // License Plate Filter        
        _HeaderConfiguration.Create_TextField_LicensePlate(20);
        _HeaderConfiguration.Set_optional(true);
    end;

    /// <summary>
    /// Lookup to display attachments
    /// </summary>
    local procedure AddHeaderConfiguration_AttachmentsHeader(var _HeaderConfiguration: Record "MOB HeaderField Element")
    begin

        _HeaderConfiguration.InitConfigurationKey_AttachmentsHeader();

        // "ReferenceID" is from Order Lines.
        // It identifies the context, this header is being called from
        _HeaderConfiguration.Create_TextField_ReferenceID(10);
        _HeaderConfiguration.Set_optional(true);
    end;

    local procedure AddHeaderConfiguration_AddCountLineHeader(var _HeaderConfiguration: Record "MOB HeaderField Element")
    begin
        _HeaderConfiguration.InitConfigurationKey_AddCountLineHeader();

        // Add the header lines
        // Journal Batch Name
        // Location
        // Item

        // Field: OrderBackendID (Journal Batch Name)
        _HeaderConfiguration.Create_TextField_OrderBackendID(10);
        _HeaderConfiguration.Set_label(MobWmsLanguage.GetMessage('BATCH_NAME') + ':');

        // Field: Location
        _HeaderConfiguration.Create_ListField_Location(20);

        // Field: AddCountLineItem (Item)
        _HeaderConfiguration.Create_TextField_ItemNumber(30);
        _HeaderConfiguration.Set_name('AddCountLineItem');
    end;

    local procedure AddHeaderConfiguration_BulkMoveHeader(var _HeaderConfiguration: Record "MOB HeaderField Element")
    begin
        _HeaderConfiguration.InitConfigurationKey_BulkMoveHeader();

        // Add the header lines
        _HeaderConfiguration.Create_ListField_Location(10);
        _HeaderConfiguration.Create_TextField_FromBin(20);
        _HeaderConfiguration.Create_TextField_ToBin(30);
    end;

    local procedure AddHeaderConfiguration_ToteShippingHeader(var _HeaderConfiguration: Record "MOB HeaderField Element")
    begin
        _HeaderConfiguration.InitConfigurationKey_ToteShippingHeader();

        // Add the header lines
        _HeaderConfiguration.Create_TextField_ToteID(10);
    end;

    local procedure AddUnitOfMeasureCodes(var _DataTable: Record "MOB DataTable Element")
    var
        UnitOfMeasure: Record "Unit of Measure";
    begin
        _DataTable.InitDataTable(DataTable_UOM_TABLE());

        // Add all Unit of Measure codes
        if UnitOfMeasure.FindSet() then
            repeat
                _DataTable.Create_CodeAndName(UnitOfMeasure.Code, UnitOfMeasure.Description);
            until UnitOfMeasure.Next() = 0;
    end;

    local procedure AddHeaderConfiguration_ItemDimensionsHeader(var _HeaderConfiguration: Record "MOB HeaderField Element")
    begin
        _HeaderConfiguration.InitConfigurationKey_ItemDimensionsHeader();
        _HeaderConfiguration.Create_ListField_UnitOfMeasure(10);
        _HeaderConfiguration.Create_TextField_ItemNumber(20);
        _HeaderConfiguration.Save();
    end;

    local procedure AddHeaderConfiguration_ShipOrderFilters(var _HeaderConfiguration: Record "MOB HeaderField Element")
    begin
        _HeaderConfiguration.InitConfigurationKey_ShipOrderFilters();
        _HeaderConfiguration.Create_ListField_FilterLocationAsLocation(10);
        _HeaderConfiguration.Create_DateField_ShipmentDateAsDate(20);
        _HeaderConfiguration.Create_ListField_ShipmentDocumentStatusFilter(30);
        _HeaderConfiguration.Create_ListField_AssignedUserFilterAsAssignedUser(40);      // No id=3 in original code
        _HeaderConfiguration.Save();
    end;

    local procedure AddHeaderConfiguration_PostShipmentCfgHeader(var _HeaderConfiguration: Record "MOB HeaderField Element")
    begin
        _HeaderConfiguration.InitConfigurationKey_PostShipmentCfgHeader();
        _HeaderConfiguration.Create_ListField_FilterLocationAsLocationFilter(10);
        _HeaderConfiguration.Create_TextField_ShipmentNoFilter(2);
        _HeaderConfiguration.Save();
    end;

    local procedure AddHeaderConfiguration_RegisterItemImageCfgHeader(var _HeaderConfiguration: Record "MOB HeaderField Element")
    begin
        _HeaderConfiguration.InitConfigurationKey_RegisterItemImageHeader();
        _HeaderConfiguration.Create_TextField_ItemNumber(10);
        _HeaderConfiguration.Save();
    end;

    local procedure AddHeaderConfiguration_RegisterImageCfgHeader(var _HeaderConfiguration: Record "MOB HeaderField Element")
    begin
        _HeaderConfiguration.InitConfigurationKey_RegisterImageHeader();
        _HeaderConfiguration.Create_TextField_ReferenceID(10);
        _HeaderConfiguration.Save();
    end;

    local procedure AddHeaderConfiguration_HistoryHeader(var _HeaderConfiguration: Record "MOB HeaderField Element")
    begin
        _HeaderConfiguration.InitConfigurationKey_HistoryHeader();
        _HeaderConfiguration.Create_ListField_Location(10);
        _HeaderConfiguration.Create_ListField_NoOfEntries(20);
        _HeaderConfiguration.Create_TextField_Bin(30);
        _HeaderConfiguration.Set_optional(true);
        _HeaderConfiguration.Create_TextField_ItemNumber(40);
        _HeaderConfiguration.Set_optional(true);
        _HeaderConfiguration.Save();
    end;

    local procedure AddUserLanguageCode(var _XmlResponseDataNode: XmlNode; _MobileUserID: Text[50])
    var
        MobUser: Record "MOB User";
        MobLanguage: Record "MOB Language";
        XmlConfiguration: XmlNode;
        XmlCreatedNode: XmlNode;
    begin
        // Get the user
        if MobUser.Get(_MobileUserID) then begin
            if MobUser."Language Code" = '' then
                MobUser."Language Code" := 'ENU'; // Fallback to ENU

            // Get the language
            if MobLanguage.Get(MobUser."Language Code") then
                if MobLanguage."Device Language Code" <> '' then begin
                    // Create the configuration "envelope"
                    MobXmlMgt.AddElement(_XmlResponseDataNode, 'Configuration', '', '', XmlConfiguration);
                    MobXmlMgt.AddElement(XmlConfiguration, 'Key', 'UserLanguage', '', XmlCreatedNode);
                    MobXmlMgt.AddElement(XmlConfiguration, 'Value', MobLanguage."Device Language Code", '', XmlCreatedNode);
                end;
        end;
    end;

    local procedure AddUserLanguageCustomizationVersion(var _XmlResponseData: XmlNode; _MobileUserID: Text[50])
    var
        MobUser: Record "MOB User";
        MobLanguage: Record "MOB Language";
        MobMessages: Record "MOB Message";
        XmlConfiguration: XmlNode;
        XmlCreatedNode: XmlNode;
    begin
        // Get the user
        if MobUser.Get(_MobileUserID) then begin
            if MobUser."Language Code" = '' then
                MobUser."Language Code" := 'ENU'; // Fallback to ENU

            // Get the language
            if MobLanguage.Get(MobUser."Language Code") then begin
                MobMessages.SetRange("Language Code", MobLanguage.Code);
                if not MobMessages.IsEmpty() then begin
                    // Create the configuration "envelope"
                    MobXmlMgt.AddElement(_XmlResponseData, 'Configuration', '', '', XmlConfiguration);
                    MobXmlMgt.AddElement(XmlConfiguration, 'Key', 'UserLanguageCustomizationVersion', '', XmlCreatedNode);
                    MobXmlMgt.AddElement(XmlConfiguration, 'Value', MobLanguage.GetLanguageCustomizationVersion(), '', XmlCreatedNode);
                end;
            end;
        end;
    end;

    local procedure VerifyMessages()
    var
        MobMessage: Record "MOB Message";
    begin
        if MobMessage.IsEmpty() then
            MobWmsLanguage.SetupLanguageMessages('ENU');
    end;

    procedure DataTable_ASSIGNED_USER_FILTER_TABLE(): Text
    begin
        exit(ASSIGNED_USER_FILTER_TABLE_Txt);
    end;

    procedure DataTable_PRODUCTION_PROGRESS_FILTER_TABLE(): Text
    begin
        exit(PRODUCTION_PROGRESS_FILTER_TABLE_Txt);
    end;

    procedure DataTable_SHIPMENT_DOCUMENT_STATUS_FILTER_TABLE(): Text
    begin
        exit(SHIPMENT_DOCUMENT_STATUS_FILTER_TABLE_Txt);
    end;

    procedure DataTable_WORKCENTER_FILTER_TABLE(): Text
    begin
        exit(WORKCENTER_TABLE_FILTER_Txt);
    end;

    procedure DataTable_ITEM_CATEGORY_TABLE(): Text
    begin
        exit(ITEM_CATEGORY_TABLE_Txt);
    end;

    procedure DataTable_LOCATION_TABLE(): Text
    begin
        exit(LOCATION_TABLE_Txt);
    end;

    procedure DataTable_FILTER_LOCATION_TABLE(): Text
    begin
        exit(FILTER_LOCATION_TABLE_Txt);
    end;

    procedure DataTable_UOM_TABLE(): Text
    begin
        exit(UOM_TABLE_Txt);
    end;

    procedure DataTable_PRINTERS_TABLE(): Text
    begin
        exit(PRINTERS_TABLE_Txt);
    end;



    // // Removed MOB5.14
    // [IntegrationEvent(false, false)]
    // procedure OnGetReferenceData_OnAfterCreateHeaderConfigurations(var _HeaderConfigurationElement: Record "MOB RefD HeaderConfig Element")
    // begin
    // end;

    [IntegrationEvent(false, false)]
    local procedure OnGetReferenceData_OnAddHeaderConfigurations(var _HeaderFields: Record "MOB HeaderField Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetReferenceData_OnAfterAddHeaderField(var _HeaderField: Record "MOB HeaderField Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetReferenceData_OnAddRegistrationCollectorConfigurations(var _Steps: Record "MOB Steps Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetReferenceData_OnAfterAddRegistrationCollectorStep(var _Step: Record "MOB Steps Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetReferenceData_OnAfterAddRegistrationCollectorConfigurationsAsXml(var _XMLResponseData: XmlNode)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetReferenceData_OnAddDataTables(var _DataTable: Record "MOB DataTable Element"; _MobileUserID: Code[50])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetReferenceData_OnAfterAddDataTableEntry(var _DataTable: Record "MOB DataTable Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetReferenceData_OnAfterAddListDataAsXml(var _XmlResponseData: XmlNode)
    begin
    end;
}
