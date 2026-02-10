codeunit 81359 "MOB Install"
{
    Access = Public;
    Subtype = Install;

    trigger OnInstallAppPerCompany() // Includes code for company-related operations. Runs once for each company in the database.
    begin

        if GetCurrentVersion() = Version.Create(0, 0, 0, 0) then
            FreshInstall()
        else
            Reinstall();
    end;

    local procedure FreshInstall()
    begin
        // Do work needed the first time this extension is ever installed for this tenant.
        // Some possible usages:
        // - Service callback/telemetry indicating that extension was install
        // - Initial data setup for use

        InitMobSetup();
    end;

    local procedure Reinstall()
    begin
        // Do work needed when reinstalling the same version of this extension back on this tenant.
        // Some possible usages:
        // - Service callback/telemetry indicating that extension was reinstalled
        // - Data 'patchup' work, for example, detecting if new 'base' records have been changed while you have been working 'offline'.
        // - Setup 'welcome back' messaging for next user access.
    end;

    procedure GetInstallingVersion(): Version
    var
        AppInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(AppInfo);
        exit(AppInfo.AppVersion());
    end;

    procedure GetCurrentVersion(): Version
    var
        AppInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(AppInfo);
        exit(AppInfo.DataVersion());
    end;

    internal procedure GetCurrentPublisher(): Text
    var
        AppInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(AppInfo);
        exit(AppInfo.Publisher());
    end;

    /// <summary>
    /// Initialize Mobile WMS - should be able to be executed at any time without causing issues, messages or confirms
    /// </summary>
    internal procedure InitMobSetup()
    var
        MobSetup: Record "MOB Setup";
        MobPrintSetup: Record "MOB Print Setup";
        MobReportPrintSetup: Record "MOB Report Print Setup";
        MobWmsSetupDocTypes: Codeunit "MOB WMS Setup Doc. Types";
        MobLanguage: Codeunit "MOB WMS Language";
        MobRetentionPolicyMgt: Codeunit "MOB Retention Policy Mgt.";
    begin
        MobSetup.Init();

        // Introduced in 4.38
        // In order to follow Base logic, it's it now up to new installs to actively disabled reservation blocking
        MobSetup.Validate("Block Neg. Adj. if Resv Exists", true);

        // Introduced in 5.18
        // Existing installations should actively choose to use Mobile DateTime Settings. Using Server settings has been default behaviour until now.
        // New installations should default to using Mobile DateTime Settings.
        MobSetup.Validate("Use Mobile DateTime Settings", true);

        // Introduced in 5.22
        // Existing installations should actively choose to not post breakbulk lines automatically. Posting breakbulk lines has been default behaviour until now.
        // New installations should default to Post breakbulk lines automatically.
        MobSetup.Validate("Post breakbulk automatically", true);

        // Introduced in 5.48
        // The Package No. feature is enabled by default in BC24+. 
        // New installations should default to using the Standard Mobile WMS Package No. implementation and only disable it if needed (if they wish to use a custom implementation)
        // We can't see if existing installations are using "None" or "Customization", so to avoid risk of unwanted changes we don't change the setting for existing installations.
        /* #if BC24+ */
        MobSetup."Package No. implementation" := MobSetup."Package No. implementation"::"Standard Mobile WMS"; // Avoid validating, as it contains a Confirm (if GuiAllowed) but the function is called from the Trial where the confirm shouldn't be shown
        /* #endif */

        if MobSetup.Insert() then;  // Conditionally insert required due to OnPremises deploy/upgrade issues for a small number of Partner hosting environments.

        // Introduced in 5.46 (The table is not new, but now a record is required to exist)
        MobPrintSetup.Init();
        if MobPrintSetup.Insert() then; // Conditionally insert required due to OnPremises deploy/upgrade issues for a small number of Partner hosting environments.

        // Introduced in 5.46
        MobReportPrintSetup.Init();
        if MobReportPrintSetup.Insert() then; // Conditionally insert required due to OnPremises deploy/upgrade issues for a small number of Partner hosting environments.

        // Create the WMS group
        // Create the document types needed for Mobile WMS
        // Create messages for ENU
        // Set Whse Setup Error Messages
        MobWmsSetupDocTypes.SetHideMessageDialog(true); // Avoid showing messages during connection guide setup and after company creation
        MobWmsSetupDocTypes.Run();

        // Create the MOB Languages
        // Setup only languages with existing MobMessages, everything else is to  added manually
        MobLanguage.SetupDefaultLanguages();

        // Introduced in 5.25
        // Apply Retention Policy
        MobRetentionPolicyMgt.SetupRetentionPolicy();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Company-Initialize", 'OnCompanyInitialize', '', false, false)]
    local procedure CompanyInitialize()
    begin
        InitMobSetup(); // Note: If new company has no Languages, no Mobile WMS Languages/Messages will be created either
    end;

}

