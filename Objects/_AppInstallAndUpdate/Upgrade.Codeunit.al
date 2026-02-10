codeunit 81360 "MOB Upgrade"
{
    Access = Public;
    Subtype = Upgrade;

    var
        MobInstall: Codeunit "MOB Install";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        UpgradingVersion: Version;
        FinishedUpgradeToVersion: Version;

    trigger OnCheckPreconditionsPerCompany()
    // Pre  upgrade
    begin
    end;

    trigger OnUpgradePerCompany()
    // Perform Upgrade
    begin

        if not VersionIsHigherThanInstalled() then
            exit;

        // Treat the current version as processed
        FinishedUpgradeToVersion := MobInstall.GetCurrentVersion();

        // Add new mobile messages
        AddNewMobileMessages();

        // Process upgrades
        "UpgradeTo4.36"();
        "UpgradeTo5.00"();
        "UpgradeTo5.01"();
        "UpgradeTo5.11"();
        "UpgradeTo5.16"();
        "UpgradeTo5.18"();
        "UpgradeTo5.19"();
        "UpgradeTo5.20"();
        "UpgradeTo5.22"();
        "UpgradeTo5.24"();
        "UpgradeTo5.25"();
        "UpgradeTo5.28"();
        "UpgradeTo5.34"();
        "UpgradeTo5.35"();
        "UpgradeTo5.35.x.216"();
        "UpgradeTo5.37"();
        "UpgradeTo5.38"();
        "UpgradeTo5.40"();
        "UpgradeTo5.41"();
        "UpgradeTo5.42"();
        "UpgradeTo5.43"();
        "UpgradeTo5.44"();
        "UpgradeTo5.46"();
        "UpgradeTo5.47"();
        "UpgradeTo5.55"();
        "UpgradeTo5.57"();
        "UpgradeTo5.58"();
        "UpgradeTo5.61"();
    end;

    trigger OnValidateUpgradePerCompany()
    // Post upgrade
    begin

    end;

    local procedure AddNewMobileMessages()
    var
        MobLanguage: Record "MOB Language";
        MobToolbox: Codeunit "MOB Toolbox";
    begin
        // Add new Mobile Messages
        MobLanguage.SetRange(Messages, true);
        if MobLanguage.FindSet() then
            repeat
                if MobToolbox.LanguageHasId(MobLanguage.Code) then
                    MobWmsLanguage.SetupLanguageMessages(MobLanguage.Code);
            until MobLanguage.Next() = 0
        else
            MobWmsLanguage.SetupLanguageMessages('ENU');
    end;

    internal procedure "UpgradeTo4.36"()
    var
        MobDocumentType: Record "MOB Document Type";
        MobDocumentQueue: Record "MOB Document Queue";
    begin
        UpgradingVersion := Version.Create(4, 36, 0, 0);

        if not ProcessUpgrade(UpgradingVersion) then
            exit;

        // Clear the obsolete Proces Type fields.
        MobDocumentType.ModifyAll("Process Type", 0, false);
        MobDocumentQueue.ModifyAll("Process Type", 0, false);

        OnPostVersionUpgrade(UpgradingVersion);
    end;

    internal procedure "UpgradeTo5.00"()
    var
        MobWmsSetupDocumentTypes: Codeunit "MOB WMS Setup Doc. Types";
    begin
        UpgradingVersion := Version.Create(5, 0, 0, 0);

        if not ProcessUpgrade(UpgradingVersion) then
            exit;

        // Add new supported Document Type "GetLocalizationData"
        MobWmsSetupDocumentTypes.CreateDocumentType('GetLocalizationData', '', Codeunit::"MOB WMS Reference Data");

        OnPostVersionUpgrade(UpgradingVersion);
    end;

    internal procedure "UpgradeTo5.01"()
    var
        MobSetup: Record "MOB Setup";
        MobWmsSetupDocumentTypes: Codeunit "MOB WMS Setup Doc. Types";
    begin
        UpgradingVersion := Version.Create(5, 1, 0, 0);

        if not ProcessUpgrade(UpgradingVersion) then
            exit;

        // Disable Log-Trade integration
        if MobSetup.Get() and MobSetup."Enable Log-Trade integration" then begin
            MobSetup."Enable Log-Trade integration" := false;
            MobSetup.Modify();
        end;
        // Add new supported Document Type "PostMedia"
        MobWmsSetupDocumentTypes.CreateDocumentType('PostMedia', '', Codeunit::"MOB WMS Media");

        OnPostVersionUpgrade(UpgradingVersion);
    end;

    internal procedure "UpgradeTo5.11"()
    var
        MobSetup: Record "MOB Setup";
    begin
        UpgradingVersion := Version.Create(5, 11, 0, 0);

        if not ProcessUpgrade(UpgradingVersion) then
            exit;

        // Ensure that "Block Neg. Adj. if Reservation exists is enabled"
        if MobSetup.Get() then begin
            MobSetup."Block Neg. Adj. if Resv Exists" := true;
            MobSetup.Modify();
        end;

        OnPostVersionUpgrade(UpgradingVersion);
    end;

    internal procedure "UpgradeTo5.16"()
    var
        MobMenuOptions: Record "MOB Menu Option";
        MobGroupMenuCfg: Record "MOB Group Menu Config";
    begin
        UpgradingVersion := Version.Create(5, 16, 0, 0);

        if not ProcessUpgrade(UpgradingVersion) then
            exit;

        // Add the option to select the new "PrintLabelTemplate" menu option, for existing installations
        MobMenuOptions."Menu Option" := 'PrintLabelTemplate';
        if MobMenuOptions.Insert() then begin
            // Rename existing "PrintLabel" menu options to new "PrintLabelTemplate"
            MobGroupMenuCfg.SetRange("Mobile Menu Option", 'PrintLabel');
            if MobGroupMenuCfg.FindSet(true) then
                repeat
                    MobGroupMenuCfg.Rename(MobGroupMenuCfg."Mobile Group", 'PrintLabelTemplate');
                    MobGroupMenuCfg.Modify();
                until MobGroupMenuCfg.Next() = 0;

            // Delete existing "PrintLabel" menu option
            if MobMenuOptions.Get('PrintLabel') then
                MobMenuOptions.Delete();
        end;

        OnPostVersionUpgrade(UpgradingVersion);
    end;

    internal procedure "UpgradeTo5.18"()
    var
        LabelTemplate: Record "MOB Label-Template";
        MobPrintInterForm: Codeunit "MOB Print InterForm";
    begin
        UpgradingVersion := Version.Create(5, 18, 0, 0);

        if not ProcessUpgrade(UpgradingVersion) then
            exit;

        // Update supported templates (Only if Mobile Print is in use)
        if not LabelTemplate.IsEmpty() then
            MobPrintInterForm.CreateTemplates(LabelTemplate, false);

        OnPostVersionUpgrade(UpgradingVersion);
    end;

    internal procedure "UpgradeTo5.19"()
    var
        MobWmsSetupDocTypes: Codeunit "MOB WMS Setup Doc. Types";
    begin
        UpgradingVersion := Version.Create(5, 19, 0, 0);

        if not ProcessUpgrade(UpgradingVersion) then
            exit;

        // Phys. Inventory Recordings are only supported on BC Platform 14 and newer
        if MobInstall.GetInstallingVersion().Build() >= 140 then begin
            MobWmsSetupDocTypes.CreateDocumentType('GetPhysInvtRecordings', '', Codeunit::"MOB WMS Phys Invt Recording");
            MobWmsSetupDocTypes.CreateDocumentType('GetPhysInvtRecordingLines', '', Codeunit::"MOB WMS Phys Invt Recording");
            MobWmsSetupDocTypes.CreateDocumentType('PostPhysInvtRecording', '', Codeunit::"MOB WMS Phys Invt Recording");
            MobWmsSetupDocTypes.CreateMobileMenuOptionAndAddToMobileGroup('PhysInvtRecording', 'WMS', 450);
        end;

        OnPostVersionUpgrade(UpgradingVersion);
    end;

    internal procedure "UpgradeTo5.20"()
    var
        MobMenuOptions: Record "MOB Menu Option";
        MobGroupMenuCfg: Record "MOB Group Menu Config";
        MobWmsSetupDocTypes: Codeunit "MOB WMS Setup Doc. Types";
    begin
        UpgradingVersion := Version.Create(5, 20, 0, 0);

        if not ProcessUpgrade(UpgradingVersion) then
            exit;

        // Rename old "PrintLabelTemplate" if exists in Menu configs
        MobGroupMenuCfg.SetRange("Mobile Menu Option", 'PrintLabelTemplate');
        if MobGroupMenuCfg.FindSet(true) then
            repeat
                MobGroupMenuCfg.Rename(MobGroupMenuCfg."Mobile Group", 'PrintLabelTemplateMenuItem');
                MobGroupMenuCfg.Modify();
            until MobGroupMenuCfg.Next() = 0;

        // Delete old menu option
        if MobMenuOptions.Get('PrintLabelTemplate') then
            MobMenuOptions.Delete();

        // Add new doc. type "PrintLabelTemplateMenuItem"
        MobWmsSetupDocTypes.CreateMobileMenuOptionAndAddToMobileGroup('PrintLabelTemplateMenuItem', 'WMS', 1505);


        OnPostVersionUpgrade(UpgradingVersion);
    end;

    internal procedure "UpgradeTo5.22"()
    var
        MobSetup: Record "MOB Setup";
        MobWmsSetupDocTypes: Codeunit "MOB WMS Setup Doc. Types";
    begin
        UpgradingVersion := Version.Create(5, 22, 0, 0);

        if not ProcessUpgrade(UpgradingVersion) then
            exit;

        // Existing installations should actively choose to not post breakbulk lines automatically. Posting breakbulk lines has been default behaviour until now.
        if MobSetup.Get() then begin
            MobSetup.Validate("Post breakbulk automatically", true);
            MobSetup.Modify();
        end;

        // Production Orders
        MobWmsSetupDocTypes.CreateDocumentType('GetProdOrderLines', '', Codeunit::"MOB WMS Production Consumption");
        MobWmsSetupDocTypes.CreateDocumentType('GetProdConsumptionLines', '', Codeunit::"MOB WMS Production Consumption");
        MobWmsSetupDocTypes.CreateDocumentType('PostProdConsumption', '', Codeunit::"MOB WMS Production Consumption");
        MobWmsSetupDocTypes.CreateMobileMenuOptionAndAddToMobileGroup('Production', 'WMS', 650);

        OnPostVersionUpgrade(UpgradingVersion);
    end;

    internal procedure "UpgradeTo5.24"()
    var
        MobDocumentType: Record "MOB Document Type";
        MobWmsSetupDocTypes: Codeunit "MOB WMS Setup Doc. Types";
    begin
        UpgradingVersion := Version.Create(5, 24, 0, 0);

        if not ProcessUpgrade(UpgradingVersion) then
            exit;

        // "RegisterRealtimeQuantity" has been moved from "Whse. Inquiry"(6181379) to "WMS LiveUpdate"(6181410)
        MobDocumentType.Reset();
        MobDocumentType.SetRange("Document Type", 'RegisterRealtimeQuantity');
        MobDocumentType.ModifyAll("Processing Codeunit", Codeunit::"MOB WMS LiveUpdate");

        // Assembly Orders
        MobWmsSetupDocTypes.CreateDocumentType('GetAssemblyOrders', '', Codeunit::"MOB WMS Assembly");
        MobWmsSetupDocTypes.CreateDocumentType('GetAssemblyOrderLines', '', Codeunit::"MOB WMS Assembly");
        MobWmsSetupDocTypes.CreateDocumentType('PostAssemblyOrder', '', Codeunit::"MOB WMS Assembly");
        MobWmsSetupDocTypes.CreateMobileMenuOptionAndAddToMobileGroup('Assembly', 'WMS', 670);

        OnPostVersionUpgrade(UpgradingVersion);
    end;

    internal procedure "UpgradeTo5.25"()
    var
        MobDocumentType: Record "MOB Document Type";
        MobDocumentGroup: Record "MOB Document Group";
        MobRetentionPolicyMgt: Codeunit "MOB Retention Policy Mgt.";
    begin
        UpgradingVersion := Version.Create(5, 25, 0, 0);

        if not ProcessUpgrade(UpgradingVersion) then
            exit;

        // Clean up deprecated document type "AddOrderLine" (is handled from Adhoc since long time ago)
        if MobDocumentType.Get('AddOrderLine') then
            MobDocumentType.Delete();

        MobDocumentGroup.Reset();
        MobDocumentGroup.SetRange("Mobile Document Type", 'AddOrderLine');
        MobDocumentGroup.DeleteAll();

        // Apply Retention Policy
        MobRetentionPolicyMgt.SetupRetentionPolicy();

        OnPostVersionUpgrade(UpgradingVersion);
    end;

    internal procedure "UpgradeTo5.28"()
    var
        MobPrintSetup: Record "MOB Print Setup";
    begin
        UpgradingVersion := Version.Create(5, 28, 0, 0);

        if not ProcessUpgrade(UpgradingVersion) then
            exit;

        if MobPrintSetup.Get() then begin
            MobPrintSetup."Preview URL" := '';
            MobPrintSetup.Modify(false);
        end;

        // Create MOB Languages
        // Setup only languages with existing MobMessages, everything else is to be added manually
        MobWmsLanguage.SetupDefaultLanguages();

        OnPostVersionUpgrade(UpgradingVersion);
    end;

    internal procedure "UpgradeTo5.34"()
    var
        LabelTemplate: Record "MOB Label-Template";
        MobRetentionPolicyMgt: Codeunit "MOB Retention Policy Mgt.";
    begin
        UpgradingVersion := Version.Create(5, 34, 0, 0);

        if not ProcessUpgrade(UpgradingVersion) then
            exit;

        // Apply Retention Policy in companies created after Mobile WMS was installed due to missing implementation of evensubscriber OnCompanyInitialize
        MobRetentionPolicyMgt.SetupRetentionPolicy();

        // Populate new field "Display Name"
        LabelTemplate.SetRange("Display Name", '');
        if LabelTemplate.FindSet() then
            repeat
                LabelTemplate."Display Name" := LabelTemplate.Name;
                LabelTemplate.Modify(false);
            until LabelTemplate.Next() = 0;

        OnPostVersionUpgrade(UpgradingVersion);
    end;

    internal procedure "UpgradeTo5.35"()
    var
        LabelTemplate: Record "MOB Label-Template";
        MobPrintSetup: Record "MOB Print Setup";
    begin
        UpgradingVersion := Version.Create(5, 35, 0, 0);

        if not ProcessUpgrade(UpgradingVersion) then
            exit;

        // Identify NG1 customer
        if MobPrintSetup.Get() then
            if MobPrintSetup.Enabled and
                (MobPrintSetup."Connection Tenant" = '') and
                (MobPrintSetup."Connection Username" <> '') and
                (MobPrintSetup."Connection Password" <> '')
            then begin
                OnPostVersionUpgrade(UpgradingVersion); // Don't upgrade NG1 customer. The few remaining customers are handled individually
                exit;
            end;


        // Change from individual workflow to generic workflow
        if LabelTemplate.FindSet(true) then
            repeat
                if not LabelTemplate."URL Mapping".Contains('/') then begin
                    case LabelTemplate."Template Handler" of
                        LabelTemplate."Template Handler"::"Item Label":
                            LabelTemplate."URL Mapping" := '/ItemLabels/NAV/' + LabelTemplate."URL Mapping" + '.ift';
                        LabelTemplate."Template Handler"::"License Plate":
                            LabelTemplate."URL Mapping" := '/LicensePlate/NAV/' + LabelTemplate."URL Mapping" + '.ift';
                        LabelTemplate."Template Handler"::"Warehouse Shipment",
                        LabelTemplate."Template Handler"::"Sales Shipment":
                            LabelTemplate."URL Mapping" := '/Orderlist/' + LabelTemplate."URL Mapping" + '.ift';
                    end;
                    LabelTemplate.Modify(false);
                end;
            until LabelTemplate.Next() = 0;

        // Add mobile language: Slovene
        MobWmsLanguage.SetupDefaultLanguage('SLV', false);

        OnPostVersionUpgrade(UpgradingVersion);
    end;

    internal procedure "UpgradeTo5.35.x.216"()
    var
        LabelTemplate: Record "MOB Label-Template";
    begin
        UpgradingVersion := Version.Create(5, 35, 190, 216); // Higher than the already released v5.35 - but lower than future v5.36

        if not ProcessUpgrade(UpgradingVersion) then
            exit;

        // Fix incorrect Orderlist-path
        LabelTemplate.SetFilter("Template Handler", '%1|%2', LabelTemplate."Template Handler"::"Warehouse Shipment", LabelTemplate."Template Handler"::"Sales Shipment");
        if LabelTemplate.FindSet(true) then
            repeat
                if LabelTemplate."URL Mapping".Contains('/') then
                    if CopyStr(LabelTemplate."URL Mapping", 1, 11) = '/OrderList/' then begin
                        LabelTemplate."URL Mapping" := '/Orderlist/' + CopyStr(LabelTemplate."URL Mapping", 12); // Fix 'List" to lowercase "list"
                        LabelTemplate.Modify(false);
                    end;
            until LabelTemplate.Next() = 0;

        OnPostVersionUpgrade(UpgradingVersion);
    end;

    internal procedure "UpgradeTo5.37"()
    var
        LabelTemplate: Record "MOB Label-Template";
    begin
        UpgradingVersion := Version.Create(5, 37, 0, 0);

        if not ProcessUpgrade(UpgradingVersion) then
            exit;

        // Fix incorrect Orderlist-path
        LabelTemplate.SetFilter("URL Mapping", '/Orderlist/standard_generic_orderList_4x6_v3.ift');
        if LabelTemplate.FindSet(true) then
            repeat
                LabelTemplate."URL Mapping" := '/Orderlist/standard_generic_orderlist_4x6_v3.ift'; // Fix 'List" to lowercase "list"
                LabelTemplate.Modify(false);
            until LabelTemplate.Next() = 0;

        OnPostVersionUpgrade(UpgradingVersion);
    end;

    internal procedure "UpgradeTo5.38"()
    var
        MobDocQueue: Record "MOB Document Queue";
        StartDateTime: DateTime;
    begin
        UpgradingVersion := Version.Create(5, 38, 0, 0);

        if not ProcessUpgrade(UpgradingVersion) then
            exit;

        // Fill new Processing Duration field
        StartDateTime := CurrentDateTime();
        MobDocQueue.SetCurrentKey("Created Date/Time", Status, "Document Type", "Mobile User ID");
        MobDocQueue.Ascending(false); // Ensure the most recent entries are updated
        if MobDocQueue.FindSet(true) then
            repeat
                if (MobDocQueue.Status in [MobDocQueue.Status::Completed, MobDocQueue.Status::Error]) and
                   (MobDocQueue."Created Date/Time" <> 0DT) and (MobDocQueue."Answer Date/Time" <> 0DT) and
                   (MobDocQueue."Processing Duration" = 0)
                then begin
                    MobDocQueue."Processing Duration" := MobDocQueue."Answer Date/Time" - MobDocQueue."Created Date/Time";
                    MobDocQueue.Modify();
                end
            until (MobDocQueue.Next() = 0) or (CurrentDateTime() - StartDateTime > 15000); // Run for a maximum of 15 secs 

        OnPostVersionUpgrade(UpgradingVersion);
    end;

    internal procedure "UpgradeTo5.40"()
    var
        MobRetentionPolicyMgt: Codeunit "MOB Retention Policy Mgt.";
    begin
        UpgradingVersion := Version.Create(5, 40, 0, 0);

        if not ProcessUpgrade(UpgradingVersion) then
            exit;

        // Apply Retention Policy (New table added)
        MobRetentionPolicyMgt.SetupRetentionPolicy();

        OnPostVersionUpgrade(UpgradingVersion);
    end;

    internal procedure "UpgradeTo5.41"()
    var
        MobSetup: Record "MOB Setup";
        MobPackFeatureManagement: Codeunit "MOB Pack Feature Management";
    begin
        UpgradingVersion := Version.Create(5, 41, 0, 0);

        if not ProcessUpgrade(UpgradingVersion) then
            exit;

        if MobSetup.Get() and (MobSetup."Whse Inventory Jnl Template" <> '') then begin
            MobSetup."Move Whse. Jnl Template" := MobSetup."Whse Inventory Jnl Template";
            MobSetup."Warehouse Jnl. Template" := MobSetup."Whse Inventory Jnl Template";
            MobSetup.Modify();
        end;

        // Cleanup in Pack & Ship Mobile Messages
        MobPackFeatureManagement.ReCreatePackAndShipMobileMessages('DAN');
        MobPackFeatureManagement.ReCreatePackAndShipMobileMessages('DEU');

        OnPostVersionUpgrade(UpgradingVersion);
    end;

    internal procedure "UpgradeTo5.42"()
    var
        MobSetup: Record "MOB Setup";
        MobFeatureTelemetryWrapper: Codeunit "MOB Feature Telemetry Wrapper";
        MobTelemetryEventId: Enum "MOB Telemetry Event ID";
    begin
        UpgradingVersion := Version.Create(5, 42, 0, 0);

        if not ProcessUpgrade(UpgradingVersion) then
            exit;

        // Added LogUptake to MobSetup."Package No. implementation".OnValidate() - this is to initialize the uptake funnel of existing companies.
        // This is not bullet proff. Customers having set "Package No. implementation" to "Standard Mobile WMS" in their BC18 or BC19 will never be added to the Uptake Funnel.
        if MobSetup.Get() then begin
            /* #if BC18+ */
            if MobSetup."Package No. implementation" = MobSetup."Package No. implementation"::"Standard Mobile WMS" then begin
                MobFeatureTelemetryWrapper.LogUptakeDiscovered(MobTelemetryEventId::"Package No. Implementation (Standard Mobile WMS) (MOB1000)");
                MobFeatureTelemetryWrapper.LogUptakeSetup(MobTelemetryEventId::"Package No. Implementation (Standard Mobile WMS) (MOB1000)");
            end;
            /* #endif */
            if MobSetup."Enable Pack and Ship" then begin
                MobFeatureTelemetryWrapper.LogUptakeDiscovered(MobTelemetryEventId::"Pack & Ship Feature (MOB1010)");
                MobFeatureTelemetryWrapper.LogUptakeSetup(MobTelemetryEventId::"Pack & Ship Feature (MOB1010)");
            end;
        end;

        OnPostVersionUpgrade(UpgradingVersion);
    end;

    internal procedure "UpgradeTo5.43"()
    begin
        UpgradingVersion := Version.Create(5, 43, 0, 0);

        if not ProcessUpgrade(UpgradingVersion) then
            exit;

        // Add mobile language: Latvian and Croatian
        MobWmsLanguage.SetupDefaultLanguage('HRV', false);
        MobWmsLanguage.SetupDefaultLanguage('LVI', false);
        OnPostVersionUpgrade(UpgradingVersion);
    end;

    internal procedure "UpgradeTo5.44"()
    var
        MobWmsSetupDocTypes: Codeunit "MOB WMS Setup Doc. Types";
    begin
        UpgradingVersion := Version.Create(5, 44, 0, 0);
        if not ProcessUpgrade(UpgradingVersion) then
            exit;

        // Online Validation Bin
        MobWmsSetupDocTypes.CreateDocumentType('ValidateBinCode', '', Codeunit::"MOB WMS Whse. Inquiry");

        OnPostVersionUpgrade(UpgradingVersion);
    end;

    internal procedure "UpgradeTo5.46"()
    var
        MobPrintSetup: Record "MOB Print Setup";
        MobReportPrintSetup: Record "MOB Report Print Setup";
        MobOrderLock: Record "MOB Order Lock";
        MobOrderLocking: Record "MOB Order Locking";
    begin
        UpgradingVersion := Version.Create(5, 46, 0, 0);
        if not ProcessUpgrade(UpgradingVersion) then
            exit;

        //Loops through the MobOrderLock table and inserts records in new MobOrderLocking table.
        if MobOrderLock.FindSet() then
            repeat
                MobOrderLocking.Init();
                MobOrderLocking.BackendID := MobOrderLock."BackendID Prefix" + MobOrderLock.BackendID;
                MobOrderLocking.MobileUser := MobOrderLock.MobileUser;
                MobOrderLocking.Name := MobOrderLock.Name;
                if MobOrderLocking.Insert() then; // Upgrade code must not fail
            until MobOrderLock.Next() = 0;
        MobOrderLock.DeleteAll();

        // Mobile Print Setup (Cloud Print Setup)
        MobPrintSetup.Init();
        if MobPrintSetup.Insert() then; // Not a new table, but wish to ensure that a record is created in all companies

        // Mobile Print Setup 
        MobReportPrintSetup.Init();
        if MobReportPrintSetup.Insert() then; // Not a new table, but wish to ensure that a record is created in all companies

        OnPostVersionUpgrade(UpgradingVersion);
    end;

    internal procedure "UpgradeTo5.47"()
    var
        MobSetup: Record "MOB Setup";
        MobWmsSetupDocumentTypes: Codeunit "MOB WMS Setup Doc. Types";
    begin
        UpgradingVersion := Version.Create(5, 47, 0, 0);

        if not ProcessUpgrade(UpgradingVersion) then
            exit;

        // Add new supported Document Type "GetApplicationConfiguration"
        MobWmsSetupDocumentTypes.CreateDocumentType('GetApplicationConfiguration', '', Codeunit::"MOB WMS Reference Data");

        // Ensure that companies who have hidden the Purchase Guide also hide the Sandbox Connection Guide.
        if MobSetup.Get() then
            if MobSetup.Guide1DoNotShow then begin
                MobSetup.Guide2DoNotShow := true;
                MobSetup.Modify();
            end;

        OnPostVersionUpgrade(UpgradingVersion);
    end;

    internal procedure "UpgradeTo5.55"()
    var
        MobDocumentType: Record "MOB Document Type";
    begin
        UpgradingVersion := Version.Create(5, 55, 0, 0);

        if not ProcessUpgrade(UpgradingVersion) then
            exit;

        // Re-direct "GetApplicationConfiguration" from the "MOB WMS Reference Data" codeunit to the new "MOB Application Configuration" codeunit.
        if MobDocumentType.Get('GetApplicationConfiguration') then begin
            MobDocumentType."Processing Codeunit" := Codeunit::"MOB Application Configuration";
            MobDocumentType.Modify();
        end;

        OnPostVersionUpgrade(UpgradingVersion);
    end;

    internal procedure "UpgradeTo5.57"()
    var
        MobLicensePlateContent: Record "MOB License Plate Content";
    begin
        UpgradingVersion := Version.Create(5, 57, 0, 0);

        if not ProcessUpgrade(UpgradingVersion) then
            exit;

        // Fix references on License Plate Content records not being correctly updated when the LP was put-away
        MobLicensePlateContent.SetRange("Whse. Document No.", '');
        MobLicensePlateContent.SetFilter("Whse. Document Line No.", '<>%1', 0);
        if MobLicensePlateContent.FindSet(true) then
            repeat
                MobLicensePlateContent.Validate("Whse. Document Line No.", 0);
                MobLicensePlateContent.Validate("Source Document", MobLicensePlateContent."Source Document"::" ");
                MobLicensePlateContent.Validate("Source Type", 0);
                MobLicensePlateContent.Validate("Source No.", '');
                MobLicensePlateContent.Validate("Source Line No.", 0);
                MobLicensePlateContent.Modify(true);
            until MobLicensePlateContent.Next() = 0;

        OnPostVersionUpgrade(UpgradingVersion);
    end;

    internal procedure "UpgradeTo5.58"()
    var
        MobWmsSetupDocumentTypes: Codeunit "MOB WMS Setup Doc. Types";
    begin
        UpgradingVersion := Version.Create(5, 58, 0, 0);

        if not ProcessUpgrade(UpgradingVersion) then
            exit;

        // Add new Document Type "GetLicensePlateContentToPick" for handling Picking
        MobWmsSetupDocumentTypes.CreateDocumentType('GetLicensePlateContentToPick', '', Codeunit::"MOB WMS Whse. Inquiry");

        OnPostVersionUpgrade(UpgradingVersion);
    end;

    internal procedure "UpgradeTo5.61"()
    var
        MobSetup: Record "MOB Setup";
        Location: Record Location;
        RequiresUpdate: Boolean;
    begin
        UpgradingVersion := Version.Create(5, 61, 0, 0);
        if not ProcessUpgrade(UpgradingVersion) then
            exit;

        // If "Use LP in Production Output" was enabled globally, set all locations to Optional
        // If "Enable License Plating" was enabled, set locations to Optional for Receive and Pick (only if required)
        if MobSetup.Get() and MobSetup."Enable License Plating" then begin
            Location.SetRange("Use As In-Transit", false); // Only regular locations
            if Location.FindSet(true) then
                repeat
                    RequiresUpdate := false;
                    if MobSetup."Use LP in Production Output" then begin
                        Location."MOB Prod. Output to LP" := Location."MOB Prod. Output to LP"::Optional;
                        RequiresUpdate := true;
                    end;

                    if Location."Require Receive" then begin
                        Location."MOB Receive to LP" := Location."MOB Receive to LP"::Optional;
                        RequiresUpdate := true;
                    end;

                    if Location."Require Pick" then begin
                        Location."MOB Pick from LP" := Location."MOB Pick from LP"::Optional;
                        RequiresUpdate := true;
                    end;

                    // Only modify if something was changed
                    if RequiresUpdate then
                        Location.Modify(false);

                until Location.Next() = 0;
        end;

        OnPostVersionUpgrade(UpgradingVersion);
    end;

    local procedure OnPostVersionUpgrade(_Version: Version)
    // Is the installing version higher than current
    begin
        FinishedUpgradeToVersion := _Version;
    end;

    local procedure VersionIsHigherThanInstalled(): Boolean
    // Is the installing version higher than current
    begin
        exit(MobInstall.GetInstallingVersion() > MobInstall.GetCurrentVersion());
    end;

    local procedure ProcessUpgrade(_Version: Version): Boolean
    // Is it relevant to run this particular upgrade
    begin
        exit(_Version > FinishedUpgradeToVersion);
    end;
}
