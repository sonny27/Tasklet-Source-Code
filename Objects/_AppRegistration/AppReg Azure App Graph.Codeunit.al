codeunit 81338 "MOB AppReg Azure App Graph"
{
    Access = Internal;

    /* #if BC25+ */

    var
        RestClient: Codeunit "Rest Client";
        MobJsonHelper: Codeunit "MOB JSON Helper";
        Initialized: Boolean;
        ProgressDialog: Dialog;
        AppDisplayNameTok: Label 'Mobile WMS', Locked = true;
        AzureADMyOrgTok: Label 'AzureADMyOrg', Locked = true;
        AppUniqueNameTok: Label 'TaskletFactory-Mobile-WMS', Locked = true;
        BusinessCentralAppIdTok: Label '996def3d-b36c-4153-8607-a6fd3c01b89f', Locked = true;
        BusinessCentralUserImpersonationIdTok: Label 'bce0976a-cb0b-473b-8800-84eda9f8e447', Locked = true;
        BusinessCentralUserImpersonationScopeTok: Label 'user_impersonation', Locked = true;
        GraphBaseUrlTok: Label 'https://graph.microsoft.com/v1.0/', Locked = true;
        RedirectUriTok: Label 'https://businesscentral.dynamics.com/', Locked = true;
        CreatingAppRegistrationMsg: Label 'Creating App Registration #1#\\', Locked = true;
        CreatingServicePrincipalMsg: Label 'Creating Service Principal #2#\\', Locked = true;
        GrantingPermissionsMsg: Label 'Granting Permissions #3#\\', Locked = true;
        RemovingTemporaryPermissionsMsg: Label 'Removing Temporary Permissions #4#', Locked = true;
        FailedToGetOrgErr: Label 'Failed to get organization information.\\HTTP Response: %1', Locked = true;
        FailedToGetOrgIdErr: Label 'Failed to get organization ID from the response.\\HTTP Response: %1', Locked = true;
        DirectoryMismatchErr: Label 'The provided credentials are associated with Directory ID "%1", but the Business Central environment is linked to Directory ID "%2". \\Please provide credentials associated with the current Business Central tenant.', Locked = true;
        AppRegInDifferentDirErr: Label 'The created App Registration seems to be created in a different directory (%1) than the current Business Central tenant (%2) and might not work as expected.\\This can happen if the admin credentials doesn''t belong to the current Business Central environment.', Locked = true;
        ObjectConflictUniqueNameErr: Label 'Unique Name of App Registration already exists. Please permanently delete the existing App Registration from the list of Deleted Applications and try again.\\HTTP Response: %1', Locked = true;
        FailedToGrantPermissionErr: Label 'Failed to grant permission: %1', Locked = true;
        FailedGettingJsonLbl: Label 'Failed to get %1 from the created App Registration.\\HTTP Response: %2', Locked = true;

    internal procedure CreateAppRegistration(var _AppId: Text; var _DirectoryId: Text)
    var
        PrincipalId: Text;
        ResourceId: Text;
    begin
        Initialize();

        // Get the user to login and validate the organization id of the provided credentials
        ValidateOrganizationIdOfProvidedCredentials();

        // Step 1: Create App Registration (asks the user for consent as part of the request)
        CreateEntraAppRegistration(_AppId, _DirectoryId);
        UpdateDialog(1);

        // Step 2: Create Service Principal
        PrincipalId := GetServicePrincipalId(_AppId, true);
        UpdateDialog(2);

        // Step 3: Grant Permissions
        ResourceId := GetServicePrincipalId(BusinessCentralAppIdTok, false);
        GrantDelegatedPermission(PrincipalId, ResourceId, BusinessCentralUserImpersonationScopeTok);
        UpdateDialog(3);

        // Step 4: Remove temporary permissions
        RemoveGrantedPermissions();
        UpdateDialog(4);

        DisposeDialog();
    end;

    local procedure Initialize()
    begin
        if Initialized then
            exit;

        RestClient := RestClientBuild();
        InitializeProgressDialog();

        Initialized := true;
    end;

    local procedure RestClientBuild() ReturnRestClient: Codeunit "Rest Client"
    var
        MobHttpClientHandler: Codeunit "MOB Http Client Handler";
        MobAppRegAzureHttpAuth: Codeunit "MOB AppReg Azure Http Auth";
    begin
        // Ensure the access token is cleared before initializing the RestClient to avoid re-using the last used credentials
        MobAppRegAzureHttpAuth.ClearAccessToken();

        ReturnRestClient.Initialize(MobHttpClientHandler, MobAppRegAzureHttpAuth);
        ReturnRestClient.SetBaseAddress(GraphBaseUrlTok);
    end;

    local procedure DisposeDialog()
    begin
        if not Initialized then
            exit;

        ProgressDialog.Close();
    end;

    local procedure InitializeProgressDialog()
    begin
        ProgressDialog.Open(
            CreatingAppRegistrationMsg +
            CreatingServicePrincipalMsg +
            GrantingPermissionsMsg +
            RemovingTemporaryPermissionsMsg);
    end;

    local procedure UpdateDialog(_Step: Integer)
    begin
        ProgressDialog.Update(_Step, '✅');
        Sleep(1000); // Delay to enable users to see the flow
    end;

    local procedure ValidateOrganizationIdOfProvidedCredentials()
    var
        HttpRequestMessage: Codeunit "Http Request Message";
        HttpResponseMessage: Codeunit "Http Response Message";
        JsonResponse: JsonObject;
        HttpMethod: Enum "Http Method";
        UserOrganizationId: Text;
        BcDirectoryId: Text;
    begin
        // Let the user log in and get the organization information of the logged-in user
        HttpRequestMessage.SetHttpMethod(HttpMethod::GET);
        HttpRequestMessage.SetRequestUri(StrSubstNo('%1organization', RestClient.GetBaseAddress()));
        HttpResponseMessage := RestClient.Send(HttpRequestMessage);
        if not HttpResponseMessage.GetIsSuccessStatusCode() then begin
            ClearAccessToken(); // Clear the access token to avoid reusing the last used credentials
            Error(FailedToGetOrgErr, HttpResponseMessage.GetContent().AsText());
        end;

        // Extract the organization id from the response
        JsonResponse := HttpResponseMessage.GetContent().AsJson().AsObject();
        UserOrganizationId := MobJsonHelper.SelectValueAsText(JsonResponse, 'value[0].id');
        if UserOrganizationId = '' then begin
            ClearAccessToken(); // Clear the access token to avoid reusing the last used credentials
            Error(FailedToGetOrgIdErr, HttpResponseMessage.GetContent().AsText());
        end;

        // Get the DirectoryId of the BC tenant
        BcDirectoryId := GetDirectoryId();

        // DirectoryId will be equal to OrganizationId for most companies.
        // If a partner-login is used in a customer tenant, it would create the App Registration in the partner's directory and not the customer's directory. This should be prevented.
        // In scenarios where multiple organizations are linked or federated, the Organization ID may be used to differentiate specific entities within a broader setup.
        // This scenario has not been tested and might not be supported.
        if BcDirectoryId <> UserOrganizationId then begin
            ClearAccessToken(); // Clear the access token to avoid reusing the last used credentials
            Error(DirectoryMismatchErr, UserOrganizationId, BcDirectoryId); // TODO: Telemetry?
        end;
    end;

    local procedure CreateEntraAppRegistration(var _AppId: Text; var _DirectoryId: Text)
    var
        HttpRequestMessage: Codeunit "Http Request Message";
        HttpResponseMessage: Codeunit "Http Response Message";
        HttpContent: Codeunit "Http Content";
        JsonRequest: JsonObject;
        JsonResponse: JsonObject;
        HttpMethod: Enum "Http Method";
        HttpResponseMessageText: Text;
        OrganizationId: Text;
    begin
        JsonRequest.Add('displayName', AppDisplayNameTok);
        JsonRequest.Add('signInAudience', AzureADMyOrgTok);
        JsonRequest.Add('requiredResourceAccess', GetRequiredResourceAccess());
        JsonRequest.Add('publicClient', GetPublicClient());

        HttpRequestMessage.SetHttpMethod(HttpMethod::PATCH);
        HttpRequestMessage.SetRequestUri(StrSubstNo('%1applications(uniqueName=''%2'')', RestClient.GetBaseAddress(), AppUniqueNameTok));
        HttpRequestMessage.SetHeader('Prefer', 'create-if-missing'); // Upsert
        HttpRequestMessage.SetContent(HttpContent.Create(JsonRequest));

        HttpResponseMessage := RestClient.Send(HttpRequestMessage);
        if HttpResponseMessage.GetHttpStatusCode() = 204 then
            JsonResponse := RestClient.GetAsJson(StrSubstNo('applications(uniqueName=''%1'')', AppUniqueNameTok)).AsObject()
        else
            JsonResponse := HttpResponseMessage.GetContent().AsJson().AsObject();

        // Search for keywords in the error message to provide additional help for specific error
        HttpResponseMessageText := HttpResponseMessage.GetContent().AsText();
        if HttpResponseMessageText.Contains('ObjectConflict') and HttpResponseMessageText.Contains('uniqueName') then begin
            ClearAccessToken(); // Clear the access token to avoid reusing the last used credentials
            Error(ObjectConflictUniqueNameErr, HttpResponseMessageText);
        end;

        // Get the Id of the created App Registration
        _AppId := MobJsonHelper.GetValueAsText(JsonResponse, 'appId');
        if _AppId = '' then begin
            ClearAccessToken(); // Clear the access token to avoid reusing the last used credentials
            Error(FailedGettingJsonLbl, 'appId', HttpResponseMessageText);
        end;

        // The DirectoryId of the BC tenant
        _DirectoryId := GetDirectoryId();

        // The OrganizationId of the created AppRegistration
        OrganizationId := GetOrganizationId();

        // DirectoryId will be equal to OrganizationId for most companies.
        // If a customer uses a partner-login to create the App Registration, it will be created in the partner's directory and not the customer's directory.
        // In scenarios where multiple organizations are linked or federated, the Organization ID may be used to differentiate specific entities within a broader setup.
        // This scenario has not been tested and might not be supported.
        // To assist troubleshooting, a warning will be shown if the DirectoryId is different from the OrganizationId, as this might cause connection issues.
        if _DirectoryId <> OrganizationId then
            Message(AppRegInDifferentDirErr, _DirectoryId, OrganizationId); // TODO: Telemetry?
    end;

    local procedure GetDirectoryId() ReturnDirectoryId: Text
    var
        AzureAdTenant: Codeunit "Azure AD Tenant";
    begin
        ReturnDirectoryId := AzureAdTenant.GetAadTenantId(); // Returns the Azure AD Tenant ID in lowercase without brackets
    end;

    local procedure GetOrganizationId() ReturnOrganizationId: Text
    var
        JsonResponse: JsonObject;
    begin
        JsonResponse := RestClient.GetAsJson('organization?$select=id').AsObject();
        ReturnOrganizationId := MobJsonHelper.SelectValueAsText(JsonResponse, 'value[0].id');
    end;

    local procedure GrantDelegatedPermission(_PrincipalObjectId: Text; _ResourceId: Text; _Scope: Text)
    var
        HttpRequestMessage: Codeunit "Http Request Message";
        HttpResponseMessage: Codeunit "Http Response Message";
        HttpContent: Codeunit "Http Content";
        JsonRequest: JsonObject;
        JsonResponse: JsonObject;
        HttpMethod: Enum "Http Method";
    begin
        JsonRequest.Add('clientId', _PrincipalObjectId);
        JsonRequest.Add('consentType', 'AllPrincipals');
        JsonRequest.Add('resourceId', _ResourceId);
        JsonRequest.Add('scope', _Scope);

        HttpRequestMessage.SetHttpMethod(HttpMethod::POST);
        HttpRequestMessage.SetRequestUri(RestClient.GetBaseAddress() + 'oauth2PermissionGrants');
        HttpRequestMessage.SetContent(HttpContent.Create(JsonRequest));

        HttpResponseMessage := RestClient.Send(HttpRequestMessage);
        if HttpResponseMessage.GetIsSuccessStatusCode() then
            exit;

        if HttpResponseMessage.GetHttpStatusCode() = 400 then begin
            JsonResponse := HttpResponseMessage.GetContent().AsJson().AsObject();
            if MobJsonHelper.SelectValueAsText(JsonResponse, 'error.message') = 'Permission entry already exists.' then
                exit; // Permission already granted, no need to show error message
        end;

        ClearAccessToken(); // Clear the access token to avoid reusing the last used credentials
        Error(FailedToGrantPermissionErr, HttpResponseMessage.GetContent().AsText()); // TODO: Telemetry? (Currently we will not get the detailed error message)
    end;

    local procedure GetServicePrincipalId(_AppId: Text; _IntegratedApp: Boolean) ReturnId: Text
    var
        HttpRequestMessage: Codeunit "Http Request Message";
        HttpResponseMessage: Codeunit "Http Response Message";
        HttpContent: Codeunit "Http Content";
        HttpMethod: Enum "Http Method";
        JsonRequest: JsonObject;
        JsonRequestTags: JsonArray;
        JsonResponse: JsonObject;
    begin
        HttpRequestMessage.SetHttpMethod(HttpMethod::PATCH);
        HttpRequestMessage.SetRequestUri(StrSubstNo(RestClient.GetBaseAddress() + 'servicePrincipals(appId=''%1'')', _AppId));
        HttpRequestMessage.SetHeader('Prefer', 'create-if-missing'); // Upsert
        if _IntegratedApp then begin
            JsonRequestTags.Add('WindowsAzureActiveDirectoryIntegratedApp');
            JsonRequest.Add('tags', JsonRequestTags);
        end;
        HttpRequestMessage.SetContent(HttpContent.Create(JsonRequest));

        HttpResponseMessage := RestClient.Send(HttpRequestMessage);
        if HttpResponseMessage.GetHttpStatusCode() = 204 then
            JsonResponse := RestClient.GetAsJson(StrSubstNo('servicePrincipals(appId=''%1'')', _AppId)).AsObject()
        else
            JsonResponse := HttpResponseMessage.GetContent().AsJson().AsObject();

        ReturnId := MobJsonHelper.GetValueAsText(JsonResponse, 'id');
        if ReturnId = '' then begin
            ClearAccessToken(); // Clear the access token to avoid reusing the last used credentials
            Error(FailedGettingJsonLbl, 'Service Principal Id', HttpResponseMessage.GetContent().AsText());
        end
    end;

    local procedure RemoveGrantedPermissions()
    var
        MobAppRegAzureHttpAuth: Codeunit "MOB AppReg Azure Http Auth";
        JsonResponse: JsonObject;
        PermissionGrant: JsonObject;
        PermissionGrants: JsonArray;
        JsonToken: JsonToken;
        PrincipalId: Text;
    begin
        // Step 1: Get Service Principal Id for BC App Registration Wizard
        PrincipalId := GetServicePrincipalId(MobAppRegAzureHttpAuth.GetClientId(), false);

        // Step 2: Get all permissions for this app /oauth2PermissionGrants?$filter=clientId eq 'ServicePrincipalId'
        JsonResponse := RestClient.GetAsJson(StrSubstNo('oauth2PermissionGrants?$filter=clientId eq ''%1''', PrincipalId)).AsObject();
        PermissionGrants := MobJsonHelper.GetValueAsArray(JsonResponse, 'value');

        // Step 3: Delete all permissions by id
        foreach JsonToken in PermissionGrants do begin
            PermissionGrant := JsonToken.AsObject();
            RestClient.Delete(StrSubstNo('oauth2PermissionGrants/%1', MobJsonHelper.GetValueAsText(PermissionGrant, 'id')));
        end;
    end;

    local procedure GetRequiredResourceAccess() RequiredResourceAccessArray: JsonArray
    var
        ResourceAccessObject: JsonObject;
        ResourceAccessArray: JsonArray;
        RequiredResourceAccessObject: JsonObject;

    begin
        ResourceAccessObject.Add('id', BusinessCentralUserImpersonationIdTok); // user_impersonation
        ResourceAccessObject.Add('type', 'Scope');
        ResourceAccessArray.Add(ResourceAccessObject);

        RequiredResourceAccessObject.Add('resourceAppId', BusinessCentralAppIdTok);
        RequiredResourceAccessObject.Add('resourceAccess', ResourceAccessArray);

        RequiredResourceAccessArray.Add(RequiredResourceAccessObject);
    end;

    local procedure GetPublicClient() ReturnPublicClient: JsonObject
    var
        RedirectUris: JsonArray;
    begin
        RedirectUris.Add(RedirectUriTok);
        ReturnPublicClient.Add('redirectUris', RedirectUris);
    end;

    /// <summary>
    /// Ensure the access token is cleared in the SingleInstance codeunit to avoid reuse of the last used credentials
    /// </summary>
    local procedure ClearAccessToken()
    var
        MobAppRegAzureHttpAuth: Codeunit "MOB AppReg Azure Http Auth";
    begin
        MobAppRegAzureHttpAuth.ClearAccessToken();
    end;
    /* #endif */
}
