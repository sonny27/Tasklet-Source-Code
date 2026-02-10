page 81305 "MOB WMS Sandbox Config. Guide"
{
    /* #if BC25+ */
    // Make sure to update codeunit 6181328 "MOB Register Assisted Setup" when the version requirement is changed

    Caption = 'Mobile WMS Sandbox Configuration Guide', Locked = true;
    AdditionalSearchTerms = 'Mobile WMS Sandbox Configuration Guide Tasklet Free Trial Demo', Locked = true;
    PageType = NavigatePage;
    UsageCategory = Administration;
    ApplicationArea = All;
    SourceTable = "MOB WMS Sandbox Config. Guide"; // A sourcetable is required to enable proper User ID lookup
    SourceTableTemporary = true;
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    Extensible = false;
    ObsoleteState = Pending;
    ObsoleteReason = 'This page will continuously be deleted in older versions as it is intended solely for BC Online.';
    ObsoleteTag = 'MOB5.53';

    layout
    {
        area(Content)
        {
            group(GraphicsTaskletLogo)
            {
                Editable = false;
                Visible = ((CurrentStep = CurrentStep::FirstPage) or (CurrentStep = CurrentStep::LastPage));
                field(MediaRepositoryWelcomeField; MediaRepositoryTaskletLogo.Image)
                {
                    ApplicationArea = All;
                    ShowCaption = false;
                }
            }
            group(GraphicsHardware)
            {
                Editable = false;
                Visible = (CurrentStep = CurrentStep::SupportedHardware);
                field(MediaRepositoryHardwareField; MediaRepositoryHardware.Image)
                {
                    ApplicationArea = All;
                    ShowCaption = false;
                }
            }
            group(FirstPage)
            {
                Visible = CurrentStep = CurrentStep::FirstPage;
                group(FirstPageHeader)
                {
                    Caption = 'Welcome!', Locked = true;
                    InstructionalText = 'This guide enables you to quickly set up Mobile WMS for demonstration usage in a Business Central sandbox environment with either a copy of production data or the Cronus demonstration data.', Locked = true;
                }
                group(FirstPageBody1)
                {
                    Caption = 'You will be guided through these steps:', Locked = true;
                    field(FirstPagePhase1; FirstPagePhase1Lbl)
                    {
                        ShowCaption = false;
                    }
                    field(FirstPagePhase2; FirstPagePhase2Lbl)
                    {
                        ShowCaption = false;
                    }
                    field(FirstPagePhase3; FirstPagePhase3Lbl)
                    {
                        ShowCaption = false;
                    }
                }
            }
            group(SupportedHardware)
            {
                Visible = CurrentStep = CurrentStep::SupportedHardware;

                group(SupportedHardwareHeader)
                {
                    Caption = 'Supported Hardware', Locked = true;
                    InstructionalText = 'Mobile WMS supports a wide range of Android devices. Review our supported hardware here:', Locked = true;

                    field(SupportedHardwareLbl; SupportedHardwareLbl)
                    {
                        ApplicationArea = All;
                        Editable = false;
                        ShowCaption = false;
                        Caption = ' ', Locked = true; // Unknown purpose, but done by Microsoft
                        ToolTip = 'View information about supported mobile devices', Locked = true;
                        trigger OnDrillDown()
                        begin
                            LogTelemetryUsage('OpenSupportedHardwareUrl');

                            Hyperlink(SupportedHardwareUrlLbl);
                        end;
                    }
                }
            }
            group(DemoUserSetup)
            {
                Visible = CurrentStep = CurrentStep::DemoUserSetup;

                group(DemoUserSetupHeader)
                {
                    Caption = 'User Setup', Locked = true;
                    InstructionalText = 'Mobile WMS requires Mobile Users created as Warehouse Employees and assigned a Mobile User Group to continue. The Mobile user also requires specific permission sets to use all features. This guide automatically ensure the specified user will get the required configuration when you continue.', Locked = true;
                }
                group(DemoUserSetupBody)
                {
                    ShowCaption = false;
                    field(UserID; Rec."User ID")
                    {
                        ToolTip = 'User ID to set up for demonstration usage', Locked = true;
                        ApplicationArea = All;
                        ShowMandatory = true;
                    }
                    field(DefaultLocationCode; Rec."Default Location Code")
                    {
                        ToolTip = 'The default location code for demonstration usage', Locked = true;
                        ApplicationArea = All;
                        ShowMandatory = true;
                    }
                    group(SetupDemoInstructions)
                    {
                        ShowCaption = false;
                        InstructionalText = 'Clicking next will ensure the specified user is a Warehouse Employee for all locations and having the specified default location and able to use Mobile WMS.', Locked = true;
                    }
                }
            }

            group(ApplicationRegistration)
            {
                Visible = CurrentStep = CurrentStep::ApplicationRegistration;

                group(ApplicationRegistrationHeader)
                {
                    Caption = 'App Registration', Locked = true;
                    InstructionalText = 'To access Business Central using Tasklet Mobile WMS, you need to create an App Registration in your environment. This App Registration enables client access to the service in Microsoft Entra ID. In most environments, the App Registration can be created automatically; however, in some cases, you may need to create it manually.', Locked = true;

                    field(AppRegMode; AppRegMode)
                    {
                        Caption = 'App Registration Mode', Locked = true;
                        ToolTip = 'Select the mode for setting up the Microsoft Entra ID app registration for authentication.', Locked = true;
                        OptionCaption = 'Automatic,Manual', Locked = true;
                    }

                    group(ApplicationRegistrationAutomatic)
                    {
                        Visible = AppRegMode = AppRegMode::Automatic;
                        Caption = 'Automatic App Registration (recommended)', Locked = true;
                        InstructionalText = 'Click below to automatically create the app registration.', Locked = true;

                        field(CreateAppRegistrationLbl; CreateAppRegistrationLbl)
                        {
                            ApplicationArea = All;
                            Editable = false;
                            ShowCaption = false;
                            Caption = ' ', Locked = true; // Unknown purpose, but done by Microsoft
                            ToolTip = 'Automatically sets up Microsoft Entra ID app registration for authentication.', Locked = true;
                            trigger OnDrillDown()
                            var
                                MobAppRegAzureAppGraph: Codeunit "MOB AppReg Azure App Graph";
                            begin
                                if not Confirm(CreateAppRegLbl) then begin
                                    LogTelemetryUsage('AutomaticCreateAppRegistration.Cancelled');
                                    exit;
                                end;

                                Rec.TestField("Application ID Text", '');
                                Rec.TestField("Directory ID Text", '');

                                LogTelemetryUsage('AutomaticCreateAppRegistration.Started');

                                MobAppRegAzureAppGraph.CreateAppRegistration(Rec."Application ID Text", Rec."Directory ID Text");

                                LogTelemetryUsage('AutomaticCreateAppRegistration.Succeeded');
                            end;
                        }
                    }
                    group(ApplicationRegistrationManual)
                    {
                        Visible = AppRegMode = AppRegMode::Manual;
                        Caption = 'Manual App Registration (advanced)', Locked = true;
                        InstructionalText = 'Use the external guide below as an alternative to the recommended automatic setup. This method is to be used if the automatic setup doesn''t work or if you prefer not to use it. Enter the Application (client) ID and Directory (tenant) ID in the fields below as instructed in the guide.', Locked = true;

                        field(InstallGuideMobSetupLbl; SetupEntraIdAppRegistrationLbl)
                        {
                            ApplicationArea = All;
                            Editable = false;
                            ShowCaption = false;
                            Caption = ' ', Locked = true; // Unknown purpose, but done by Microsoft
                            ToolTip = 'View information about setting up Microsoft Entra ID app registration for authentication.', Locked = true;
                            trigger OnDrillDown()
                            var
                            begin
                                LogTelemetryUsage('OpenSetupEntraIdAppRegistrationUrl');

                                Hyperlink(SetupEntraIdAppRegistrationUrlLbl);
                            end;
                        }
                    }

                    field(ApplicationId; Rec."Application ID Text")
                    {
                        ToolTip = 'Please specify the Application (client) ID from the application registration in Microsoft Entra ID (AAD).', Locked = true;
                        ApplicationArea = All;
                        ShowMandatory = true;
                        trigger OnValidate()
                        var
                            TestGuid: Guid;
                        begin
                            if Rec."Application ID Text" <> '' then begin
                                if not Evaluate(TestGuid, Rec."Application ID Text") then
                                    Error(InvalidAppIdGuidErr, Rec.FieldCaption("Application ID Text"));

                                // Ensure the Guid is formatted correctly
                                Rec."Application ID Text" := FormatGuidAsAppReg(TestGuid);
                            end;
                        end;
                    }
                    field(DirectoryId; Rec."Directory ID Text")
                    {
                        ToolTip = 'Please specify the Directory (tenant) ID from the application registration in Microsoft Entra ID (AAD).', Locked = true;
                        ApplicationArea = All;
                        ShowMandatory = true;
                        trigger OnValidate()
                        var
                            TestGuid: Guid;
                        begin
                            if Rec."Directory ID Text" <> '' then begin
                                if not Evaluate(TestGuid, Rec."Directory ID Text") then
                                    Error(InvalidGuidLbl, Rec.FieldCaption("Directory ID Text"));

                                // Ensure the Guid is formatted correctly
                                Rec."Directory ID Text" := FormatGuidAsAppReg(TestGuid);
                            end;
                        end;
                    }
                }
            }
            group(PrintConnectionGuide)
            {
                Visible = CurrentStep = CurrentStep::PrintConnectionGuide;

                group(PrintConnectionGuideHeader)
                {
                    Caption = 'Print Connection Guide with Barcodes', Locked = true;
                    InstructionalText = 'To connect your supported mobile device to Mobile WMS you need to install the Mobile WMS app from Google Play Store and connect it to your company. Print the Mobile WMS Connection Guide, containing the required barcodes. Either print the guide or save it as a PDF to simplify the process of connecting your mobile device.', Locked = true;
                }
                field(TroubleshootConnectionLbl; TroubleshootConnectionLbl)
                {
                    ApplicationArea = All;
                    Editable = false;
                    ShowCaption = false;
                    Caption = ' ', Locked = true; // Unknown purpose, but done by Microsoft
                    ToolTip = 'Troubleshoot connection issues', Locked = true;
                    trigger OnDrillDown()
                    var
                    begin
                        LogTelemetryUsage('OpenTroubleshootConnectionUrl');

                        Hyperlink(TroubleshootConnectionUrlLbl);
                    end;
                }

            }
            group(LastPage)
            {
                Visible = CurrentStep = CurrentStep::LastPage;

                group(LastPageHeader)
                {
                    Caption = 'Congratulations!', Locked = true;
                    InstructionalText = 'You have now configured a user in Mobile WMS and can try or demonstrate the functionality in the current company.', Locked = true;
                }
                group(LastPageBody)
                {
                    ShowCaption = false;

                    field(SaveEntraIds; Rec."Save Microsoft Entra IDs")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Save the Application ID and Directory ID to re-use them if the guide is opened again.', Locked = true;
                    }
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {

            action(ActionBack)
            {
                ApplicationArea = All;
                Enabled = ActionBackAllowed;
                Image = PreviousRecord;
                InFooterBar = true;
                Caption = 'Back', Locked = true;
                ToolTip = 'Back to previous page.', Locked = true;
                trigger OnAction()
                begin
                    LogTelemetryUsage('Back');

                    TaskStep(-1);
                end;
            }
            action(ActionNext)
            {
                Caption = 'Next', Locked = true;
                ToolTip = 'Forward to next page.', Locked = true;
                ApplicationArea = All;
                Enabled = ActionNextAllowed;
                Visible = ActionNextAllowed;
                Image = NextRecord;
                InFooterBar = true;
                trigger OnAction()
                begin
                    LogTelemetryUsage('Next');

                    ValidateCurrentStep();

                    TaskStep(1);
                end;
            }
            action(PrintGuide)
            {
                ApplicationArea = All;
                Visible = CurrentStep = CurrentStep::PrintConnectionGuide;
                Image = NextRecord; // Markes the action as the default action in the footer bar
                InFooterBar = true;
                Caption = 'Print Connection Guide', Locked = true;
                ToolTip = 'Print a guide with the required barcodes to download the Mobile WMS app and connect it to the current company.', Locked = true;
                trigger OnAction()
                var
#pragma warning disable AL0432
                    MobAppConnectionGuide: Report "MOB App Connection Guide";
#pragma warning restore AL0432
                    MobFeatureTelemetryWrapper: Codeunit "MOB Feature Telemetry Wrapper";
                    MobTelemetryEventId: Enum "MOB Telemetry Event ID";
                begin
                    // Logging 3 times to track usage of the connection guide like previous version and to track the overall uptake of the Mobile WMS trial feature
                    LogTelemetryUsage('Next'); // Done to ensure the step is marked as completed in the telemetry (like in version 5.47) 
                    LogTelemetryUsage('PrintConnectionGuide'); // Kept to stay in line with telemetry from version 5.47 (Printing were a separate action in the guide in 5.47)
                    MobFeatureTelemetryWrapper.LogUptakeSetup(MobTelemetryEventId::"Mobile WMS Trial (MOB1040)");

                    MobAppConnectionGuide.SetParameters(Rec."Application ID Text", Rec."Directory ID Text", Rec."SOAP URL", Rec."Authentication Email");
                    MobAppConnectionGuide.RunModal();

                    TaskStep(1);
                end;
            }
            action(ActionFinish)
            {
                Caption = 'Finish', Locked = true;
                ToolTip = 'Finish the Guide.', Locked = true;
                ApplicationArea = All;
                Enabled = ActionFinishAllowed;
                Visible = ActionFinishAllowed;
                Image = Approve;
                InFooterBar = true;
                trigger OnAction()
                var
                    MobSetup: Record "MOB Setup";
                    GuidedExperience: Codeunit "Guided Experience";
                begin
                    LogTelemetryUsage('Finish');

#pragma warning disable AL0432
                    GuidedExperience.CompleteAssistedSetup(ObjectType::Page, Page::"MOB WMS Sandbox Config. Guide");
#pragma warning restore AL0432

                    // Save Microsoft Entra ID (AAD) settings to the MOB Setup record to re-use if the guide is opened again
                    if Rec."Save Microsoft Entra IDs" then begin
                        MobSetup.LockTable();
                        MobSetup.Get();
                        Evaluate(MobSetup."Entra Application Id", Rec."Application ID Text");
                        Evaluate(MobSetup."Entra Directory Id", Rec."Directory ID Text");
                        MobSetup.Modify();
                    end;
                    if not MobSetup.Guide2DoNotShow then begin
                        MobSetup.LockTable();
                        MobSetup.Get();
                        MobSetup.Guide2DoNotShow := true;
                        MobSetup.Modify();
                    end;
                    CurrPage.Close();

                end;
            }
        }
    }
    var
        MediaRepositoryTaskletLogo: Record "Media Repository";
        MediaRepositoryHardware: Record "Media Repository";
        CurrentStep: Option FirstPage,SupportedHardware,DemoUserSetup,ApplicationRegistration,PrintConnectionGuide,LastPage; // The order of the options determines the order of the steps
        ActionBackAllowed: Boolean;
        ActionNextAllowed: Boolean;
        ActionFinishAllowed: Boolean;
        WmsGroupLbl: Label 'WMS', Locked = true;
        SupportedHardwareLbl: Label 'Learn more about supported mobile devices', Locked = true;
        SupportedHardwareUrlLbl: Label 'https://taskletfactory.com/hardware/mobile-computers/', Locked = true;
        CreateAppRegistrationLbl: Label 'Create App Registration automatically', Locked = true;
        SetupEntraIdAppRegistrationLbl: Label 'Guide to set up Microsoft Entra ID (AAD) app registration manually', Locked = true;
        SetupEntraIdAppRegistrationUrlLbl: Label 'https://taskletfactory.atlassian.net/wiki/spaces/TFSK/pages/212893700/Set+up+Microsoft+Entra+ID+for+Sandbox+Configuration+Guide', Locked = true;
        TroubleshootConnectionLbl: Label 'Troubleshooting connection issues', Locked = true;
        TroubleshootConnectionUrlLbl: Label 'https://taskletfactory.atlassian.net/wiki/spaces/TFSK/pages/249167873/Troubleshooting+Sandbox+Connection+Guide', Locked = true;
        InvalidGuidLbl: Label 'The %1 is not a valid GUID.\\Please specify the Directory ID from the App Registration in Microsoft Entra ID (ADD).', Locked = true;
        GuideOnlyAvailableForOnlineSandboxLbl: Label 'This guide is only available for Business Central Online and use in a "Sandbox".', Locked = true;
        PleaseSpecifyUserLbl: Label '%1 must be specified.\\Please specify the user you wish to log into Mobile WMS.', Locked = true;
        PleaseSpecifyMailLbl: Label '%1 %2 must have a %3 specified to enable login to Mobile WMS.\\Please specify the %3 for the user or select a user with a %3.', Locked = true; // If to be translated the parameters should be changed from FieldName/TableName to FieldCaption/TableCaption
        PleaseSpecifyDefaultLocationLbl: Label '%1 must be specified.\\Please specify the default location to be used in Mobile WMS', Locked = true;
        ThisWillConfigureSandboxLbl: Label 'This will configure the current sandbox company for demonstration usage of Mobile WMS and the changes will not be rolled back if you step back or uninstall Mobile WMS.\\Are you sure you want to continue?', Locked = true;
        ConfigUserSuccessLbl: Label 'The mobile user has now succesfully been configured for demonstration usage of Mobile WMS.\\Please proceed with the next steps to complete the guide.', Locked = true;
        UserLacksRequiredPermissionsLbl: Label 'The %1 user lacks required permissions. This means the user will not be able to perform tasks in the Mobile WMS app.\\Please ensure the user is either super or has the %2 and additional recommended permission sets.', Locked = true;
        UserLacksOptionalPermissionsLbl: Label 'The %1 user does not have all the recommended permission sets (missing: %2). This means that the user might not be able to perform all tasks in the Mobile WMS app.\\Do you want to continue without these permissions?', Locked = true;
        InvalidAppIdGuidErr: Label 'The %1 is not a valid GUID.\\Please specify the Application ID from the App Registration in Microsoft Entra ID (AAD).', Locked = true;
        MustBeSpecifiedFromAppRegLbl: Label '%1 is required.\\Creating the App Registration automatically will populate the field for you.\\Alternatively, you can create it manually and copy the necessary information from the App Registration in Microsoft Entra ID (AAD).', Locked = true;
        CreateAppRegLbl: Label 'You are about to create an App Registration, which requires providing user credentials.\\When prompted for a user account in the next dialog, ensure to use an account belonging to the environment of this Business Central tenant.\\Do you want to proceed?', Locked = true;
        AppRegDoesNotMatchLbl: Label 'The specified %1 does not match the %1 of current Business Central tenant.\\Please ensure the App Registration is created for the correct tenant.', Locked = true;
        FirstPagePhase1Lbl: Label '1: Configure a Mobile User', Locked = true;
        FirstPagePhase2Lbl: Label '2: Create an App Registration for authentication', Locked = true;
        FirstPagePhase3Lbl: Label '3: Print barcodes to download the Mobile App and connect it to this company', Locked = true;
        AppRegMode: Option Automatic,Manual;

    trigger OnOpenPage()
    var
        MobFeatureTelemetryWrapper: Codeunit "MOB Feature Telemetry Wrapper";
        MobTelemetryEventId: Enum "MOB Telemetry Event ID";
    begin
        UpdateControls();

        MobFeatureTelemetryWrapper.LogUptakeDiscovered(MobTelemetryEventId::"Mobile WMS Trial (MOB1040)");
    end;

    trigger OnInit()
    begin
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;

        LoadTopBanners();
    end;

    local procedure UpdateControls()
    begin
        ActionBackAllowed := CurrentStep > CurrentStep::FirstPage;
        ActionNextAllowed := (CurrentStep < CurrentStep::LastPage) and (CurrentStep <> CurrentStep::PrintConnectionGuide);
        ActionFinishAllowed := CurrentStep = CurrentStep::LastPage;

        CurrPage.Update(true);
    end;

    local procedure TaskStep(_Step: Integer)
    begin
        CurrentStep += _Step;
        UpdateControls();
    end;

    local procedure LoadTopBanners()
    var
        MobBase64Convert: Codeunit "MOB Base64 Convert";
        MobGUIHelper: Codeunit "MOB GUI Helper";
        ImageInStream: InStream;
    begin
        // Import BASE64 image        
        MobBase64Convert.FromBase64(MobGUIHelper.GetWelcomeBannerAsBase64String(), ImageInStream);
        MediaRepositoryTaskletLogo.Image.ImportStream(ImageInStream, '');

        MobBase64Convert.FromBase64(MobGUIHelper.GetHardwareBannerAsBase64String(), ImageInStream);
        MediaRepositoryHardware.Image.ImportStream(ImageInStream, '');

        // Image.ImportStream starts a transaction (also if the rec were temporary) that must be committed before the page can be opened from the Assisted Setup guide
        Commit();
    end;

    local procedure ValidateCurrentStep()
    begin
        case CurrentStep of
            CurrentStep::FirstPage:
                ValidateEnvironment();
            CurrentStep::SupportedHardware:
                FindSuggestedUserAndLocation();
            CurrentStep::DemoUserSetup:
                SetupSandboxEnvironment();
            CurrentStep::ApplicationRegistration:
                ValidateApplicationRegistration();
        end;
    end;

    local procedure ValidateEnvironment()
    var
        MobEnvironmentInformation: Codeunit "MOB Environment Information";
    begin
        // Check overall preconditions
        if (not MobEnvironmentInformation.IsSandbox()) or (not MobEnvironmentInformation.IsSaaSInfrastructure()) then
            Error(GuideOnlyAvailableForOnlineSandboxLbl);
    end;

    local procedure FindSuggestedUserAndLocation()
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        // Initialise suggested user and default location (and validate current user got permissions to the Warehouse Employee table)
        if Rec."User ID" = '' then
            Rec."User ID" := UserId;

        if Rec."Default Location Code" = '' then begin
            WarehouseEmployee.SetRange("User ID", Rec."User ID");
            WarehouseEmployee.SetRange(Default, true);
            if WarehouseEmployee.FindFirst() then
                Rec."Default Location Code" := WarehouseEmployee."Location Code";
        end;
    end;

    local procedure SetupSandboxEnvironment()
    var
        MobSetup: Record "MOB Setup";
        WarehouseEmployee: Record "Warehouse Employee";
        Location: Record Location;
        MobUser: Record "MOB User";
        MobGroupUser: Record "MOB Group User";
        User: Record User;
        WebServiceAggregate: Record "Web Service Aggregate";
        WebServiceManagement: Codeunit "Web Service Management";
        AzureAdTenant: Codeunit "Azure AD Tenant";
        MobInstall: Codeunit "MOB Install";
        AadTenantId: Guid;
        NullGuid: Guid;
    begin
        // Check preconditions
        User.SetRange("User Name", Rec."User ID");
        if (Rec."User ID" = '') or (not User.FindFirst()) then
            Error(PleaseSpecifyUserLbl, Rec.FieldCaption("User ID"));

        // Intentionally using TableName/FieldName in the user interface due to the label being locked to English
        if User."Authentication Email" = '' then
            Error(PleaseSpecifyMailLbl, Format(User.TableName()), Rec."User ID", Format(User.FieldName("Authentication Email"))); // Using Format() to avoid AA0448 warnings

        if Rec."Default Location Code" = '' then
            Error(PleaseSpecifyDefaultLocationLbl, Rec.FieldCaption("Default Location Code"));

        ValidateUserPermissions(Rec."User ID");

        // Get user confirmation
        if not Confirm(ThisWillConfigureSandboxLbl) then
            Error('');

        // Mobile WMS Setup - Ensure the main setup records and document types etc. exists
        MobInstall.InitMobSetup();
        MobSetup.Get();


        // Warehouse Employees - Ensure the user is a warehouse user for all locations        

        // Reset Default field for other locations
        WarehouseEmployee.SetRange("User ID", Rec."User ID");
        WarehouseEmployee.SetFilter("Location Code", '<>%1', Rec."Default Location Code");
        WarehouseEmployee.SetRange(Default, true);
        if not WarehouseEmployee.IsEmpty then
            WarehouseEmployee.ModifyAll(Default, false);

        // Loop Locations to ensure the user is a warehouse employee for all locations (Locations cannot be empty when Rec."Location Code" is specified)
        Location.FindSet();
        repeat
            WarehouseEmployee.Reset();
            WarehouseEmployee.SetRange("User ID", Rec."User ID");
            WarehouseEmployee.SetRange("Location Code", Location.Code);
            if WarehouseEmployee.FindFirst() then begin

                // Check if default location should be marked
                if (Location.Code = Rec."Default Location Code") and (not WarehouseEmployee.Default) then begin
                    WarehouseEmployee.Default := true;
                    WarehouseEmployee.Modify(true);
                end;

            end else begin

                // Create a new Warehouse Employee
                WarehouseEmployee.Init();
                WarehouseEmployee."User ID" := Rec."User ID";
                WarehouseEmployee."Location Code" := Location.Code;
                WarehouseEmployee.Default := (Location.Code = Rec."Default Location Code");
                WarehouseEmployee.Insert(true);
            end;

        until Location.Next() = 0;

        // Mobile User
        if not MobUser.Get(Rec."User ID") then begin
            MobUser.Init();
            MobUser."User ID" := Rec."User ID";
            MobUser.Insert();
        end;

        // Mobile User Group - Ensure the user is a member of the default Mobile Group
        MobGroupUser.SetRange("Mobile User ID", Rec."User ID");
        if MobGroupUser.IsEmpty() then begin
            MobGroupUser.Init();
            MobGroupUser."Mobile User ID" := Rec."User ID";
            MobGroupUser."Group Code" := WmsGroupLbl;
            MobGroupUser.Insert();
        end;

        // Web service  - Ensure it is published and get the SOAP URL used for connection json
        WebServiceManagement.LoadRecords(WebServiceAggregate);
        WebServiceAggregate.SetRange(Published, true);
        WebServiceAggregate.SetRange("Object Type", WebServiceAggregate."Object Type"::Codeunit);
        WebServiceAggregate.SetRange("Object ID", Codeunit::"MOB WS Dispatcher");
        if not WebServiceAggregate.FindFirst() then begin
            WebServiceManagement.CreateTenantWebService(WebServiceAggregate."Object Type"::Codeunit, Codeunit::"MOB WS Dispatcher", 'MobileDocumentService', true);
            WebServiceManagement.LoadRecords(WebServiceAggregate);
            WebServiceAggregate.FindFirst();
        end;

        // Setting default value(s) for next step
        Rec."SOAP URL" := WebServiceManagement.GetWebServiceUrl(WebServiceAggregate, Enum::"Client Type"::SOAP);
        Rec."Authentication Email" := User."Authentication Email";

        // Re-use Application ID and Tenant ID if they are already stored and match the current tenant 
        if (MobSetup."Entra Application Id" <> NullGuid) and (Rec."Directory ID Text" = '') and (Rec."Application ID Text" = '') then
            if Evaluate(AadTenantId, AzureAdTenant.GetAadTenantId()) then
                if MobSetup."Entra Directory Id" = AadTenantId then begin
                    Rec."Application ID Text" := FormatGuidAsAppReg(MobSetup."Entra Application Id");
                    Rec."Directory ID Text" := FormatGuidAsAppReg(MobSetup."Entra Directory Id");
                end;

        Message(ConfigUserSuccessLbl);
    end;

    local procedure ValidateUserPermissions(_UserId: Code[50])
    var
        User: Record User;
        UserPermissions: Codeunit "User Permissions";
        AccessMemberScope: Option System,Tenant; // Defined in the Access Member table
        i: Integer;
        RecommendedPermissionSets: List of [Code[20]];
        RecommendedPermissionSetsMissing: Text;
        BaseAppGuid: Guid;
        MobileWmsAppGuid: Guid;
    begin
        // Initialize GUIDs used for validation
        BaseAppGuid := '437dbf0e-84ff-417a-965d-ed2bb9650972'; // Base Application
        MobileWmsAppGuid := 'a5727ce6-368c-49e2-84cb-1a6052f0551c'; // Mobile WMS

        // Get the User record to get the User Security ID (Value already validated by OnValidate trigger)
        User.SetRange("User Name", _UserId);
        User.FindFirst();

        // Check if the user is a super user - then everything is awesome
        if UserPermissions.IsSuper(User."User Security ID") then
            exit;

        // Check if the user has the MOBWMSUSER permission set
        if not UserPermissions.HasUserPermissionSetAssigned(User."User Security ID", CompanyName(), 'MOBWMSUSER', AccessMemberScope::System, MobileWmsAppGuid) then
            Error(UserLacksRequiredPermissionsLbl, _UserId, 'MOBWMSUSER');

        // Check if the user has the the additional recommended permission sets - otherwise ask for confirmation, as they might not be required
        RecommendedPermissionSets.Add('D365 BASIC');
        RecommendedPermissionSets.Add('D365 SETUP');
        RecommendedPermissionSets.Add('D365 INV DOC, POST');
        RecommendedPermissionSets.Add('D365 JOURNALS, POST');
        RecommendedPermissionSets.Add('D365 PURCH DOC, POST');
        RecommendedPermissionSets.Add('D365 SALES DOC, POST');
        RecommendedPermissionSets.Add('D365 WHSE, EDIT');
        RecommendedPermissionSets.Add('D365PREM MFG, EDIT');
        RecommendedPermissionSets.Add('D365 ASSEMBLY, EDIT');
        for i := 1 to RecommendedPermissionSets.Count do
            if not UserPermissions.HasUserPermissionSetAssigned(User."User Security ID", CompanyName(), RecommendedPermissionSets.Get(i), AccessMemberScope::System, BaseAppGuid) then
                if RecommendedPermissionSetsMissing = '' then
                    RecommendedPermissionSetsMissing := StrSubstNo('"%1"', RecommendedPermissionSets.Get(i)) // Several permission sets contains a comma, so we need to wrap them in quotes
                else
                    RecommendedPermissionSetsMissing += StrSubstNo(', "%1"', RecommendedPermissionSets.Get(i));
        if RecommendedPermissionSetsMissing = '' then
            exit;

        if not Confirm(UserLacksOptionalPermissionsLbl, false, _UserId, RecommendedPermissionSetsMissing) then
            Error('');
    end;

    local procedure ValidateApplicationRegistration()
    var
        AzureAdTenant: Codeunit "Azure AD Tenant";
        AadTenantId: Guid;
    begin
        if Rec."Application ID Text" = '' then
            Error(MustBeSpecifiedFromAppRegLbl, Rec.FieldCaption("Application ID Text"));

        if Rec."Directory ID Text" = '' then
            Error(MustBeSpecifiedFromAppRegLbl, Rec.FieldCaption("Directory ID Text"));

        if not Evaluate(AadTenantId, AzureAdTenant.GetAadTenantId()) or (Rec."Directory ID Text" <> FormatGuidAsAppReg(AadTenantId)) then
            Error(AppRegDoesNotMatchLbl, Rec.FieldCaption("Directory ID Text"));

        // Setting default value(s) for next step
        Rec."Save Microsoft Entra IDs" := true;
    end;

    local procedure FormatGuidAsAppReg(_Guid: Guid): Text[36] // Lenght a guid without brackets
    begin
        exit(LowerCase(Format(_Guid, 0, 4))); // Lowercase the Guid without brackets to match the format in the App Registration
    end;

    local procedure LogTelemetryUsage(_EventName: Text)
    var
        MobTelemetryMgt: Codeunit "MOB Telemetry Management";
    begin
        MobTelemetryMgt.LogSandboxConfigurationGuideUsage(Format(CurrentStep), _EventName);
    end;

    /* #endif */

    // ****************************************************************************************
    // This guide requires BC25, but customers might still use BC24 Online at the time of release and install the Free Trial expecting to find the connection guide.
    // The page is therefore still shown in the menu and the assisted setup for BC24, but provides an error message when opened.
    // (BC25 is required to be able to use SecretText in the integration to Microsoft Graph for App Registration)
    // ****************************************************************************************

    /* #if BC24 ##
    UsageCategory = Administration;
    ApplicationArea = All;
    /* #endif */

    /* #if BC23,BC24 ##
    // BC23 is kept to avoid errors because of destructive changes from before the page was marked obsolete, but the page is hidden in the menu for BC23
    Caption = 'Mobile WMS Sandbox Configuration Guide', Locked = true;
    PageType = NavigatePage;
    SourceTable = "MOB WMS Sandbox Config. Guide"; // A sourcetable is required to enable proper User ID lookup
    SourceTableTemporary = true;
    Extensible = false;
    ObsoleteState = Pending;
    ObsoleteReason = 'This page will continuously be deleted in older versions as it is intended solely for BC Online.';
    ObsoleteTag = 'MOB5.53';

    trigger OnOpenPage()
    var
        GuideRequiresBc25Err: Label 'This guide requires Business Central 2024 release wave 1 (BC25) or later.\\Please update before using this guide.', Locked = true;
    begin
        Error(GuideRequiresBc25Err);
    end;
    /* #endif */
}
