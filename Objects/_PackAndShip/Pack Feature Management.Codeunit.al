codeunit 82230 "MOB Pack Feature Management"
{
    Access = Public;
    var
        MobPack: Codeunit "MOB WMS Pack";
        MobPackAdhocReg: Codeunit "MOB WMS Pack Adhoc Reg";
        MobPackAdhocRegBulkReg: Codeunit "MOB WMS Pack Adhoc Reg-BulkReg";
        MobPackLookup: Codeunit "MOB WMS Pack Lookup";
        MobMoveLicensePlate: Codeunit "MOB WMS MoveLicensePlate";
        MobAllToNewLicensePlate: Codeunit "MOB WMS AllToNewLicensePlate";
        MobAllContentToNewLP: Codeunit "MOB WMS AllContentToNewLP";
        MobPackManagement: Codeunit "MOB Pack Management";
        PublishedCheckErr: Label 'Existing Pack & Ship Extension detected.\\To ensure correct Data Migration, you must contact Tasklet Factory for detailed instructions', Locked = true;

    /// <summary>
    /// Returns true if the feature is enabled
    /// Returns false if the MOB Setup record is missing or the feature is disabled.
    /// Fails if the user lacks permissions.
    /// </summary>
    internal procedure IsEnabled(): Boolean
    begin
        exit(IsEnabled(false));
    end;

    /// <summary>
    /// Returns true if the feature is enabled
    /// Returns false if the MOB Setup record is missing or the feature is disabled.
    /// If _DisabledOnMissingPermissions is true, it return false if the user lack permissions
    /// If _DisabledOnMissingPermissions is false, it fails if the user lack permissions
    /// </summary>
    [InherentPermissions(PermissionObjectType::TableData, Database::"MOB Setup", 'R', InherentPermissionsScope::Both)]
    internal procedure IsEnabled(_DisabledOnMissingPermissions: Boolean): Boolean
    var
        MobSetup: Record "MOB Setup";
    begin
        if _DisabledOnMissingPermissions then
            if not MobSetup.ReadPermission() then
                exit(false);

        if MobSetup.Get() then
            exit(MobSetup."Enable Pack and Ship");
    end;

    /// <remarks>
    /// Bindings are shared for all active MobPackManagement instances.
    /// When these global variables goes out of scope, all bindings are removed.
    /// </remarks>
    internal procedure BindUnbindPackManagement()
    begin
        if IsEnabled() then begin
            BindSubscription(MobPack);
            BindSubscription(MobPackLookup);
            BindSubscription(MobPackAdhocReg);
            BindSubscription(MobPackAdhocRegBulkReg);
            BindSubscription(MobMoveLicensePlate);
            BindSubscription(MobAllToNewLicensePlate);
            BindSubscription(MobAllContentToNewLP);
            BindSubscription(MobPackManagement);
        end;
    end;

    /* #if BC20+ */
    // After login, always refresh currently active Application Areas
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Initialization", 'OnAfterLogin', '', false, false)]
    local procedure OnAfterLogIn()
    var
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
    begin
        if GuiAllowed() then
            ApplicationAreaMgmtFacade.RefreshExperienceTierCurrentCompany();
    end;
    /* #endif */

    /* #if BC19- ##
    // After login, always refresh currently active Application Areas
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LogInManagement", 'OnAfterLogInStart', '', false, false)]
    local procedure OnAfterLogInStart()
    var
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
    begin
        if GuiAllowed then
            ApplicationAreaMgmtFacade.RefreshExperienceTierCurrentCompany();
    end;
    /* #endif */

    // Extend and modify Essential experience tier with "MOB Packing"
    [InherentPermissions(PermissionObjectType::TableData, Database::"MOB Setup", 'R', InherentPermissionsScope::Both)]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Application Area Mgmt.", 'OnGetEssentialExperienceAppAreas', '', false, false)]
    local procedure RegisterPackAndShipOnGetEssentialExperienceAppAreas(var TempApplicationAreaSetup: Record "Application Area Setup" temporary)
    var
        MobSetup: Record "MOB Setup";
    begin
        // Check if required permissions are available
        // For BC21+ everybody has read permissions because of InherentPermissions
        // For BC20- it requires explicit permissions in the permission set        
        if not MobSetup.ReadPermission() then
            exit;

        if MobSetup.Get() then
            TempApplicationAreaSetup."MOB WMS Pack and Ship" := MobSetup."Enable Pack and Ship";
    end;

    internal procedure CheckReadyToEnablePackAndShip()
    var
        MobSetup: Record "MOB Setup";
    begin

        // Validate required setup
        MobSetup.Get();
        MobSetup.TestField("Enable Tote Picking");

        ThrowErrorIfLegacyPackAndShipIsPublished();
    end;

    internal procedure ThrowErrorIfLegacyPackAndShipIsPublished()
    begin
        if LegacyPackAndShipPublished() then
            Error(PublishedCheckErr);
    end;

    /// <summary>
    /// Check if any Pack and Ship PTE Extensions are published. Please note that we use a commit in the sub-function, Please consider this if you use this function in a transaction.
    /// PerTenant  'f5cac71c-e4e8-4cbf-b615-79cedd7ea49e'
    /// OnPrem     '8733a1d9-05c8-4779-954d-3b2aff1cb77a'
    /// </summary>
    local procedure LegacyPackAndShipPublished(): Boolean
    begin
        if CheckIfPublished('f5cac71c-e4e8-4cbf-b615-79cedd7ea49e') or CheckIfPublished('8733a1d9-05c8-4779-954d-3b2aff1cb77a') then
            exit(true)
        else
            exit(false);
    end;

    internal procedure LegacyPackAndShipDetected(): Boolean
    var
        MobSetup: Record "MOB Setup";
    begin
        MobSetup.Get();

        if MobSetup."Legacy Pack and Ship Detected" then
            exit(true);

        if LegacyPackAndShipPublished() then
            exit(true)
        else
            exit(false);
    end;

    /* #if BC15+ */
    local procedure CheckIfPublished(_AppId: Text): Boolean
    var
        MobSetup: Record "MOB Setup";
        ExtensionMgt: Codeunit "Extension Management";
    begin
        // Check if Pack & Ship is published
        if not IsNullGuid(ExtensionMgt.GetLatestVersionPackageIdByAppId(_AppId)) then begin

            MobSetup.Get();
            MobSetup."Legacy Pack and Ship Detected" := true;
            MobSetup.Modify();
            Commit();  // We need to ensure the detection of Pack & Ship is saved to avoid manually uninstall and re-try to enable feature.
            exit(true);
        end else
            exit(false);
    end;
    /* #endif */

    /* #if BC14 ##
    local procedure CheckIfPublished(_AppId: Text): Boolean
    var
        MobSetup: Record "MOB Setup";
        ExtensionMgt: Codeunit NavExtensionInstallationMgmt;        
    begin
        // Check if Pack & Ship is published, then check if it is installed and has minimum version 1.20
        if not IsNullGuid(ExtensionMgt.GetLatestVersionPackageId(_AppId)) then begin

            MobSetup.Get();
            MobSetup."Legacy Pack and Ship Detected" := true;
            MobSetup.Modify();
            Commit();  // We need to ensure the detection of Pack & Ship is saved to avoid manually uninstall and re-try to enable feature.
            exit(true);
        end else
            exit(false);
    end;
    /* #endif */

    internal procedure InitPackAndShip()
    var
        MobLabelTemplate: Record "MOB Label-Template";
        MobPrint: Codeunit "MOB Print";
        LicensePlateMgt: Codeunit "MOB License Plate Mgt";
    begin
        // Create Document Types and Menu
        CreateDocumentTypesForPacking();
        CreateMenuForPacking();

        // Cleanup in Pack & Ship Mobile Messages        
        ReCreatePackAndShipMobileMessages('DAN');
        ReCreatePackAndShipMobileMessages('DEU');

        // Create Menu for License Plates
        LicensePlateMgt.CreateMenuForLicensePlate();

        // Create Label Templates
        MobPrint.InsertTemplate(MobLabelTemplate, 'License Plate Contents 4x6', 'License Plate Contents 4x6', '/Orderlist/' + 'standard_generic_orderlist_4x6_v3' + '.ift', MobLabelTemplate."Template Handler"::"License Plate Contents");
    end;

    internal procedure CreateDocumentTypesForPacking()
    var
        MobWmsSetupDocTypes: Codeunit "MOB WMS Setup Doc. Types";
    begin
        // <Service>
        // <getOrders>GetPackingOrders</getOrders>        
        // </Service>

        if not IsEnabled() then
            exit;

        MobWmsSetupDocTypes.CreateDocumentType('GetPackingOrders', '', Codeunit::"MOB WMS Pack");
        MobWmsSetupDocTypes.CreateDocumentType('ValidateToteID', '', Codeunit::"MOB WMS Whse. Inquiry");  // DocumentType for Online Validation of Tote ID
    end;

    local procedure CreateMenuForPacking()
    var
        MobWmsSetupDocTypes: Codeunit "MOB WMS Setup Doc. Types";
    begin
        if IsEnabled() then
            exit;

        MobWmsSetupDocTypes.CreateMobileMenuOptionAndAddToMobileGroup('Packing', 'WMS', 350);
    end;

    /// <summary>
    /// Check all existing Mobile Messages related to Pack And Ship in DAN and DEU languages
    /// </summary>
    internal procedure ReCreatePackAndShipMobileMessages(_MsgKey: Code[50])
    var
        MobWmsLanguage: Codeunit "MOB WMS Language";
    begin
        MobWmsLanguage.RemoveMobileMessageIfNotTranslated(_MsgKey, 'MAINMENULPCONTENT');
        MobWmsLanguage.RemoveMobileMessageIfNotTranslated(_MsgKey, 'LICENSEPLATE');
        MobWmsLanguage.RemoveMobileMessageIfNotTranslated(_MsgKey, 'TO_LICENSEPLATE');
        MobWmsLanguage.RemoveMobileMessageIfNotTranslated(_MsgKey, 'TO_LICENSEPLATE_HELP');
        MobWmsLanguage.RemoveMobileMessageIfNotTranslated(_MsgKey, 'LICENSEPLATE_MUST_BE_EMPTY_ERROR');
        MobWmsLanguage.RemoveMobileMessageIfNotTranslated(_MsgKey, 'TOP_LEVEL');
        MobWmsLanguage.RemoveMobileMessageIfNotTranslated(_MsgKey, 'ADD_LICENSEPLATE_HELP');
        MobWmsLanguage.RemoveMobileMessageIfNotTranslated(_MsgKey, 'NO_LICENSE_PLATES_TO_UPDATE');
        MobWmsLanguage.RemoveMobileMessageIfNotTranslated(_MsgKey, 'PACKING_STATION');
        MobWmsLanguage.RemoveMobileMessageIfNotTranslated(_MsgKey, 'STAGING_HINT');
        MobWmsLanguage.RemoveMobileMessageIfNotTranslated(_MsgKey, 'STAGING_HINT_HELP');
        MobWmsLanguage.RemoveMobileMessageIfNotTranslated(_MsgKey, 'PACKAGE_QTY');
        MobWmsLanguage.RemoveMobileMessageIfNotTranslated(_MsgKey, 'ITEM_QTY');
        MobWmsLanguage.RemoveMobileMessageIfNotTranslated(_MsgKey, 'EMPTY');
        MobWmsLanguage.RemoveMobileMessageIfNotTranslated(_MsgKey, 'PACKAGE_TYPE');
        MobWmsLanguage.RemoveMobileMessageIfNotTranslated(_MsgKey, 'PACKAGE_TYPE_LABEL');
        MobWmsLanguage.RemoveMobileMessageIfNotTranslated(_MsgKey, 'SHIPPING_AGENT_SERVICE_HELP');
        MobWmsLanguage.RemoveMobileMessageIfNotTranslated(_MsgKey, 'SHIPPING_AGENT_HELP');
        MobWmsLanguage.RemoveMobileMessageIfNotTranslated(_MsgKey, 'ENTER_LOAD_METER');
        MobWmsLanguage.RemoveMobileMessageIfNotTranslated(_MsgKey, 'LOAD_METER_LABEL');
        MobWmsLanguage.RemoveMobileMessageIfNotTranslated(_MsgKey, 'MAINMENUPACKING');
        MobWmsLanguage.RemoveMobileMessageIfNotTranslated(_MsgKey, 'PAGEPACKINGTITLE');
        MobWmsLanguage.RemoveMobileMessageIfNotTranslated(_MsgKey, 'BULKREGISTRATION');
        MobWmsLanguage.RemoveMobileMessageIfNotTranslated(_MsgKey, 'COMBINETONEW');
        MobWmsLanguage.RemoveMobileMessageIfNotTranslated(_MsgKey, 'BULKREGISTRATION');
        MobWmsLanguage.RemoveMobileMessageIfNotTranslated(_MsgKey, 'ALLCONTENTTONEW');
        MobWmsLanguage.RemoveMobileMessageIfNotTranslated(_MsgKey, 'LICENSEPLATE_CONTENT');
        MobWmsLanguage.RemoveMobileMessageIfNotTranslated(_MsgKey, 'POSTPACKING');
        MobWmsLanguage.RemoveMobileMessageIfNotTranslated(_MsgKey, 'ADD_LICENSEPLATE');
        MobWmsLanguage.RemoveMobileMessageIfNotTranslated(_MsgKey, 'DELETE_LICENSEPLATE');
        MobWmsLanguage.RemoveMobileMessageIfNotTranslated(_MsgKey, 'MOVE_LICENSEPLATE');
        MobWmsLanguage.RemoveMobileMessageIfNotTranslated(_MsgKey, 'LICENSEPLATE_UPDATE_POS');
        MobWmsLanguage.RemoveMobileMessageIfNotTranslated(_MsgKey, 'NEW_LICENSEPLATE');

        // Re-create missing Mobile Messages for specific Input Languages
        MobWmsLanguage.SetupLanguageMessages(_MsgKey);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Setup Doc. Types", 'OnAfterCreateDefaultDocumentTypes', '', true, true)]
    local procedure OnAfterCreateDefaultDocumentTypes()
    begin
        if IsEnabled() then
            CreateDocumentTypesForPacking();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Setup Doc. Types", 'OnAfterCreateDefaultMenuOptions', '', true, true)]
    local procedure OnAfterCreateDefaultMenuOptions()

    begin
        if IsEnabled() then
            CreateMenuForPacking();
    end;
}
