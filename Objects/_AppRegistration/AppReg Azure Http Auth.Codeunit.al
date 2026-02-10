codeunit 81341 "MOB AppReg Azure Http Auth" implements "Http Authentication"
//
// AppVersion 25.0.0.0
//
// (Interface might exist before BC25, but currently isn't used in MOB before BC25)
{
    Access = Internal;
    SingleInstance = true;

    var
        GraphApplicationReadWriteAllScopeTxt: Label 'https://graph.microsoft.com/Application.ReadWrite.All', Locked = true;
        GraphDelegatedPermissionGrantReadWriteAllScopeTxt: Label 'https://graph.microsoft.com/DelegatedPermissionGrant.ReadWrite.All', Locked = true;
        UserReadPermissionTxt: Label 'https://graph.microsoft.com/User.Read', Locked = true;
        AuthorizationEndpointTxt: Label 'https://login.microsoftonline.com/organizations/oauth2/v2.0/authorize', Locked = true;
        AppRegistrationClientIdTxt: Label 'c605d304-a99a-43fc-86c9-2dc130afab24', Locked = true;
        GetAccessTokenErr: Label 'Failed to get access token: %1\\%2', Locked = true;
        InitKeyVaultErr: Label 'Failed to initialize App Key Vault Secret Provider:\\%1', Locked = true;
        GetCertificateErr: Label 'Failed to get certificate from Key Vault:\\%1', Locked = true;
        GetCertificatePwdErr: Label 'Failed to get certificate password from Key Vault:\\%1', Locked = true;
        AccessToken: SecretText;

    procedure IsAuthenticationRequired(): Boolean
    begin
        exit(true);
    end;

    procedure GetAuthorizationHeaders() Headers: Dictionary of [Text, SecretText]
    begin
        Headers.Add('Authorization', SecretStrSubstNo('Bearer %1', GetAccessToken()));
    end;

    local procedure GetAccessToken(): SecretText
    begin
        if AccessToken.IsEmpty() then
            AcquireAccessToken();

        exit(AccessToken);
    end;

    [NonDebuggable]
    local procedure AcquireAccessToken()
    var
        OAuth2: Codeunit OAuth2;
        AuthCodeErr: Text;
        Scopes: List of [Text];
        Certificate: SecretText;
        CertificatePassword: SecretText;
    begin
        Scopes.Add(UserReadPermissionTxt);
        Scopes.Add(GraphApplicationReadWriteAllScopeTxt);
        Scopes.Add(GraphDelegatedPermissionGrantReadWriteAllScopeTxt);

        GetCertificateInKeyVault(Certificate, CertificatePassword);

        if not OAuth2.AcquireTokenByAuthorizationCodeWithCertificate(
            GetClientId(),
            Certificate,
            CertificatePassword,
            AuthorizationEndpointTxt,
            '',
            Scopes,
            Enum::"Prompt Interaction"::Login,
            AccessToken,
            AuthCodeErr)
        then
            Error(GetAccessTokenErr, AuthCodeErr, GetLastErrorText()); // Telemetry to get details?
    end;

    [NonDebuggable]
    local procedure GetCertificateInKeyVault(var _Certificate: SecretText; var _CertificatePassword: SecretText)
    var
        AppKeyVaultSecretProvider: Codeunit "App Key Vault Secret Provider";
    begin
        if not AppKeyVaultSecretProvider.TryInitializeFromCurrentApp() then
            Error(InitKeyVaultErr, GetLastErrorText());

        if not AppKeyVaultSecretProvider.GetSecret('AppRegistrationCreation-Certificate', _Certificate) then
            Error(GetCertificateErr, GetLastErrorText());

        if not AppKeyVaultSecretProvider.GetSecret('AppRegistrationCreation-CertificatePassword', _CertificatePassword) then
            Error(GetCertificatePwdErr, GetLastErrorText());
    end;

    /// <summary>
    /// Clears the access token to prevent re-using a token from an invalid used (For example a Partner trying to create a new App Registration in a Customer Tenant)
    /// </summary>
    internal procedure ClearAccessToken()
    begin
        Clear(AccessToken);
    end;

    /// <summary>
    /// Gets the client id of the App Registration in Azure AD to identify Tasklet Factory
    /// </summary>
    /// <returns>Client Id</returns>
    internal procedure GetClientId(): Text
    begin
        exit(AppRegistrationClientIdTxt);
    end;
}
