codeunit 81389 "MOB WMS Setup Doc. Types"
{
    Access = Public;

    var
        HideMessageDialog: Boolean;

    trigger OnRun()
    var
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
        MobWmsLanguage: Codeunit "MOB WMS Language";
    begin
        // Create the WMS group
        CreateGroup(WMS_GROUP_Txt, MobileUsersLbl);

        // Create the document types needed for Mobile WMS
        CreateDefaultDocumentTypes();
        OnAfterCreateDefaultDocumentTypes();

        // Create the default menu options and add to WMS group
        CreateDefaultMenuOptions();
        OnAfterCreateDefaultMenuOptions();

        MobWmsToolbox.SetWhseSetupErrorMessages();

        MobWmsLanguage.SetupLanguageMessages('ENU');

        if GuiAllowed() and (not GetHideMessageDialog()) then
            Message(DocumentTypesCreatedMsg);
    end;

    var
        DocumentType: Record "MOB Document Type";
        DocumentTypesCreatedMsg: Label 'Mobile Document Types created successfully.';
        WMS_GROUP_Txt: Label 'WMS', Locked = true;
        MobileUsersLbl: Label 'Mobile WMS users';

    local procedure CreateDefaultDocumentTypes()
    begin
        //*** GetOrders ***        
        CreateDocumentType('GetReceiveOrders', '', Codeunit::"MOB WMS Receive");
        CreateDocumentType('GetPutAwayOrders', '', Codeunit::"MOB WMS Put Away");
        CreateDocumentType('GetPickOrders', '', Codeunit::"MOB WMS Pick");
        CreateDocumentType('GetShipOrders', '', Codeunit::"MOB WMS Ship");
        CreateDocumentType('GetCountOrders', '', Codeunit::"MOB WMS Count");
        CreateDocumentType('GetMoveOrders', '', Codeunit::"MOB WMS Move");
        CreateDocumentType('GetProdOrderLines', '', Codeunit::"MOB WMS Production Consumption");
        CreateDocumentType('GetAssemblyOrders', '', Codeunit::"MOB WMS Assembly");

        //*** GetOrderLines ***
        CreateDocumentType('GetReceiveOrderLines', '', Codeunit::"MOB WMS Receive");
        CreateDocumentType('GetPutAwayOrderLines', '', Codeunit::"MOB WMS Put Away");
        CreateDocumentType('GetPickOrderLines', '', Codeunit::"MOB WMS Pick");
        CreateDocumentType('GetShipOrderLines', '', Codeunit::"MOB WMS Ship");
        CreateDocumentType('GetCountOrderLines', '', Codeunit::"MOB WMS Count");
        CreateDocumentType('GetMoveOrderLines', '', Codeunit::"MOB WMS Move");
        CreateDocumentType('GetProdConsumptionLines', '', Codeunit::"MOB WMS Production Consumption");
        CreateDocumentType('GetAssemblyOrderLines', '', Codeunit::"MOB WMS Assembly");

        //*** PostOrder ***
        CreateDocumentType('PostReceiveOrder', '', Codeunit::"MOB WMS Receive");
        CreateDocumentType('PostPutAwayOrder', '', Codeunit::"MOB WMS Put Away");
        CreateDocumentType('PostPickOrder', '', Codeunit::"MOB WMS Pick");
        CreateDocumentType('PostShipOrder', '', Codeunit::"MOB WMS Ship");
        CreateDocumentType('PostCountOrder', '', Codeunit::"MOB WMS Count");
        CreateDocumentType('PostMoveOrder', '', Codeunit::"MOB WMS Move");
        CreateDocumentType('PostProdConsumption', '', Codeunit::"MOB WMS Production Consumption");
        CreateDocumentType('PostAssemblyOrder', '', Codeunit::"MOB WMS Assembly");

        //*** Lock/Unlock Order ***
        CreateDocumentType('LockOrder', '', Codeunit::"MOB WMS Order Locking");
        CreateDocumentType('UnlockOrder', '', Codeunit::"MOB WMS Order Locking");

        //*** Login ***
        CreateDocumentType('Login', '', Codeunit::"MOB User Management");

        //*** Reference data ***
        CreateDocumentType('GetReferenceData', '', Codeunit::"MOB WMS Reference Data");
        CreateDocumentType('GetLocalizationData', '', Codeunit::"MOB WMS Reference Data");

        //*** Application Configuration ***
        CreateDocumentType('GetApplicationConfiguration', '', Codeunit::"MOB Application Configuration");

        //*** Adhoc registrations
        CreateDocumentType('GetRegistrationConfiguration', '', Codeunit::"MOB WMS Adhoc Registr.");
        CreateDocumentType('PostAdhocRegistration', '', Codeunit::"MOB WMS Adhoc Registr.");

        //*** Warehouse inquiries
        CreateDocumentType('LocateItem', '', Codeunit::"MOB WMS Whse. Inquiry");
        CreateDocumentType('GetSerialNumberInformation', '', Codeunit::"MOB WMS Whse. Inquiry");
        CreateDocumentType('ValidateLotNumber', '', Codeunit::"MOB WMS Whse. Inquiry");
        CreateDocumentType('ValidateBinCode', '', Codeunit::"MOB WMS Whse. Inquiry");
        CreateDocumentType('RegisterRealtimeQuantity', '', Codeunit::"MOB WMS LiveUpdate");

        //*** LP inquiries ***        
        CreateDocumentType('GetLicensePlateContentToPick', '', Codeunit::"MOB WMS Whse. Inquiry");

        //*** Lookup ***
        CreateDocumentType('Lookup', '', Codeunit::"MOB WMS Lookup");

        //*** Online Search ***
        CreateDocumentType('Search', '', Codeunit::"MOB WMS Online Search");

        //*** Media ***
        CreateDocumentType('GetMedia', '', Codeunit::"MOB WMS Media");
        CreateDocumentType('PostMedia', '', Codeunit::"MOB WMS Media");
    end;

    /// <summary>
    /// Create a Document Type if not exists
    /// </summary>
    procedure CreateDocumentType(_DocType: Text[50]; _Description: Text[80]; _ProcessingCodeunit: Integer)
    begin
        DocumentType.Init();
        DocumentType."Document Type" := _DocType;
        DocumentType.Description := _Description;
        DocumentType."Processing Codeunit" := _ProcessingCodeunit;
        if DocumentType.Insert() then; // Avoid error if already exists
    end;

    procedure CreateGroup("Code": Code[10]; Name: Text[50])
    var
        MobileGroup: Record "MOB Group";
    begin
        MobileGroup.Code := Code;
        MobileGroup.Name := Name;
        if MobileGroup.Insert() then; // Avoid error if already exists
    end;

    local procedure CreateDefaultMenuOptions()
    begin
        CreateMobileMenuOptionAndAddToMobileGroup('Receive', WMS_GROUP_Txt, 100);
        CreateMobileMenuOptionAndAddToMobileGroup('PutAway', WMS_GROUP_Txt, 200);
        CreateMobileMenuOptionAndAddToMobileGroup('Pick', WMS_GROUP_Txt, 300);
        CreateMobileMenuOptionAndAddToMobileGroup('Ship', WMS_GROUP_Txt, 400);
        CreateMobileMenuOptionAndAddToMobileGroup('Count', WMS_GROUP_Txt, 500);
        CreateMobileMenuOptionAndAddToMobileGroup('Move', WMS_GROUP_Txt, 600);
        CreateMobileMenuOptionAndAddToMobileGroup('Production', WMS_GROUP_Txt, 650);
        CreateMobileMenuOptionAndAddToMobileGroup('Assembly', WMS_GROUP_Txt, 670);
        CreateMobileMenuOptionAndAddToMobileGroup('UnplannedCount', WMS_GROUP_Txt, 700);
        CreateMobileMenuOptionAndAddToMobileGroup('UnplannedMove', WMS_GROUP_Txt, 800);
        CreateMobileMenuOptionAndAddToMobileGroup('BinContent', WMS_GROUP_Txt, 900);
        CreateMobileMenuOptionAndAddToMobileGroup('ItemCrossReference', WMS_GROUP_Txt, 1000);
        CreateMobileMenuOptionAndAddToMobileGroup('SubstituteItems', WMS_GROUP_Txt, 1100);
        CreateMobileMenuOptionAndAddToMobileGroup('Logout', WMS_GROUP_Txt, 1200);
        CreateMobileMenuOptionAndAddToMobileGroup('LocateItem', WMS_GROUP_Txt, 1300);
        CreateMobileMenuOptionAndAddToMobileGroup('AdjustQty', WMS_GROUP_Txt, 1400);
        CreateMobileMenuOptionAndAddToMobileGroup('PrintLabelTemplateMenuItem', WMS_GROUP_Txt, 1505);
        CreateMobileMenuOptionAndAddToMobileGroup('BulkMove', WMS_GROUP_Txt, 1600);
        CreateMobileMenuOptionAndAddToMobileGroup('ItemDimensions', WMS_GROUP_Txt, 1700);
        CreateMobileMenuOptionAndAddToMobileGroup('ToteShipping', WMS_GROUP_Txt, 1800);
        CreateMobileMenuOptionAndAddToMobileGroup('RegisterItemImage', WMS_GROUP_Txt, 1900);
        CreateMobileMenuOption('PostShipment');
    end;

    procedure CreateMobileMenuOption(_MobileMenuOption: Text[100])
    var
        MobileMenuOption: Record "MOB Menu Option";
    begin
        MobileMenuOption."Menu Option" := _MobileMenuOption;
        if MobileMenuOption.Insert() then; // Avoid error if already exists
    end;

    procedure CreateMobileMenuOptionAndAddToMobileGroup(_MobileMenuOption: Text[100]; _MobileGroup: Code[10]; _Sorting: Integer)
    var
        MobileGroupMenuConfig: Record "MOB Group Menu Config";
    begin
        CreateMobileMenuOption(_MobileMenuOption);

        MobileGroupMenuConfig.Init();
        MobileGroupMenuConfig."Mobile Group" := _MobileGroup;
        MobileGroupMenuConfig."Mobile Menu Option" := _MobileMenuOption;
        MobileGroupMenuConfig.Sorting := _Sorting;
        if MobileGroupMenuConfig.Insert() then; // Avoid error if already exists
    end;

    /// <summary>
    /// Create a Mobile Menu Option and replace the obsolete one in the Mobile Group
    /// </summary>
    /// <param name="_ObsoleteMobileMenuOption">The MenuItem to be replaced. The option is not deleted as an Menu Option.</param>
    /// <param name="_NewMobileMenuOption">The new MenuOption to add as an option and replace the OpsoleteOption</param>
    /// <param name="_MobileGroup">The Group the options are replaced</param>
    /// <param name="_SortingIfNotFound">The sorting used if the obsolete option doesn't exist</param>
    internal procedure CreateMobileMenuOptionAndReplaceInMobileGroup(_ObsoleteMobileMenuOption: Text[100]; _NewMobileMenuOption: Text[100]; _MobileGroup: Code[10]; _SortingIfNotFound: Integer)
    var
        MobGroupMenuConfig: Record "MOB Group Menu Config";
    begin
        if GetMobileMenuOption(_ObsoleteMobileMenuOption, _MobileGroup, MobGroupMenuConfig) then begin
            MobGroupMenuConfig.Delete(true);
            CreateMobileMenuOptionAndAddToMobileGroup(_NewMobileMenuOption, _MobileGroup, MobGroupMenuConfig.Sorting);
        end else
            CreateMobileMenuOptionAndAddToMobileGroup(_NewMobileMenuOption, _MobileGroup, _SortingIfNotFound);
    end;

    internal procedure GetMobileMenuOption(_MobileMenuOption: Text[100]; _MobileGroup: Code[10]; var _MobileGroupMenuConfig: Record "MOB Group Menu Config"): Boolean
    begin
        _MobileGroupMenuConfig.Reset();
        _MobileGroupMenuConfig.SetRange("Mobile Group", _MobileGroup);
        _MobileGroupMenuConfig.SetRange("Mobile Menu Option", _MobileMenuOption);
        exit(_MobileGroupMenuConfig.FindFirst())
    end;

    internal procedure RemoveMobileMenuOptionFromMobileGroup(_MobileMenuOption: Text[100]; _MobileGroup: Code[10])
    var
        MobileGroupMenuConfig: Record "MOB Group Menu Config";
    begin
        MobileGroupMenuConfig.SetRange("Mobile Group", _MobileGroup);
        MobileGroupMenuConfig.SetRange("Mobile Menu Option", _MobileMenuOption);
        MobileGroupMenuConfig.DeleteAll(true);
    end;

    procedure SetHideMessageDialog(_NewHideMessageDialog: Boolean)
    begin
        HideMessageDialog := _NewHideMessageDialog;
    end;

    local procedure GetHideMessageDialog(): Boolean
    begin
        exit(HideMessageDialog);
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnAfterCreateDefaultDocumentTypes()
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnAfterCreateDefaultMenuOptions()
    begin
    end;
}

