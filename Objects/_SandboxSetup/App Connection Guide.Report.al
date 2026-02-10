report 81276 "MOB App Connection Guide"
{
    /* #if BC23+ */

    // This guide calling this report requires BC25, but the report is kept available for BC23 and BC24 to avoid breaking changes and to allow for manual execution

    Caption = 'Mobile App Connection Guide', Locked = true;
    DefaultRenderingLayout = "MOB App Connection Guide";
    ObsoleteState = Pending;
    ObsoleteReason = 'Will be made non-extendable in a future release. (planned for lockdown 02/2025)';
    ObsoleteTag = 'MOB5.53';

    dataset
    {
        dataitem(PageLoop; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = const(1));
            column(CompanyName; CompanyDisplayNameDefaulted)
            {
            }
            column(PlayStoreUrl; PlayStoreUrlLbl)
            {
            }
            column(PlayStoreUrlEncoded; PlayStoreUrlEncoded)
            {
            }
            column(AppConnectionJson; AppConnectionTxt)
            {
            }
            column(AppConnectionJsonEncoded; AppConnectionTxtEncoded)
            {
            }
            column(ApplicationId; ApplicationId)
            {
            }
            column(DirectoryId; DirectoryId)
            {
            }
            column(SoapUrl; SoapUrl)
            {
            }
            column(MailAddress; MailAddressTxt)
            {
            }
            column(MailAddressEncoded; MailAddressTxtEncoded)
            {
            }
        }
    }
    requestpage
    {
        layout
        {
            area(Content)
            {
                group(InstructionsGrp)
                {
                    Caption = 'Instructions', Locked = true;
                    InstructionalText = 'Get the required barcodes to download the Tasklet Mobile WMS app from Google Play Store and connect to the current company. It is recommended to save the report as a PDF and re-use it if additional devices are to be connected to this company.', Locked = true;
                    Editable = false;
                    field(ApplicationIdControl; ApplicationId)
                    {
                        ApplicationArea = All;
                        Caption = 'Application ID', Locked = true;
                        ToolTip = 'The Application ID of the Microsoft Entra ID (AAD) application that is used to authenticate the mobile app.', Locked = true;
                    }
                    field(DirectoryIdControl; DirectoryId)
                    {
                        ApplicationArea = All;
                        Caption = 'Directory ID', Locked = true;
                        ToolTip = 'The Directory ID of the Microsoft Entra ID (AAD) application that is used to authenticate the mobile app.', Locked = true;
                    }
                    field(SoapUrlControl; SoapUrl)
                    {
                        ApplicationArea = All;
                        Caption = 'SOAP URL', Locked = true;
                        ToolTip = 'The SOAP URL of the Business Central instance that the mobile app should connect to.', Locked = true;
                    }
                }
            }
        }
        trigger OnOpenPage()
        begin
            if (ApplicationId = '') or (DirectoryId = '') or (SoapUrl = '') then
                Error(ReqParamMissingErr);
        end;
    }
    rendering
    {
        layout("MOB App Connection Guide")
        {
            Type = Word;
            Caption = 'Mobile App Connection Guide', Locked = true;
            Summary = 'Mobile App Connection Guide with barcodes to download the Tasklet Mobile WMS app from Google Play Store and connect to the current company.', Locked = true;
            LayoutFile = './Objects/_SandboxSetup/MOB App Connection Guide.docx';
        }
    }
    trigger OnPreReport()
    var
        Company: Record Company;
        MobEnvironmentInformation: Codeunit "MOB Environment Information";
        AppConnectionJson: JsonObject;
        AzureConfigurationJson: JsonObject;
        AiDictionary: Dictionary of [Text, Text];
    begin
        // Generate connection json
        CompanyDisplayNameDefaulted := MobEnvironmentInformation.GetCompanyDisplayNameDefaulted();

        Company.Get(CompanyName());
        AppConnectionJson.Add('id', Format(Company.Id, 0, 4)); // 4 = The (company) guid without brackets - like 'EA48A3E0-48E0-4AB7-B1A1-E3EA85BF1B75'
        AppConnectionJson.Add('displayName', CompanyDisplayNameDefaulted);
        AppConnectionJson.Add('type', 'D365BC');
        AppConnectionJson.Add('protocol', 'classic');
        AppConnectionJson.Add('address', SoapUrl);
        AzureConfigurationJson.Add('authority', StrSubstNo('https://login.microsoftonline.com/%1/oauth2/v2.0/authorize', DirectoryId));
        AzureConfigurationJson.Add('clientId', ApplicationId);
        AzureConfigurationJson.Add('returnUri', 'https://businesscentral.dynamics.com/');
        AppConnectionJson.Add('azureConfiguration', AzureConfigurationJson);
        AppConnectionJson.WriteTo(AppConnectionTxt);

        // Generate encoded value of Playstore URL
        BarcodeManagement2D.SetSimpleTextToEncode(PlayStoreUrlLbl);
        BarcodeManagement2D.Set_BarcodeFontProvider(Enum::"Barcode Font Provider 2D"::IDAutomation2D);
        BarcodeManagement2D.Set_BarcodeSymbology(Enum::"Barcode Symbology 2D"::"QR-Code"); // Using QR for higher compatibility
        PlayStoreUrlEncoded := BarcodeManagement2D.GetEncodedBarcodeText();

        // Generate encoded value of connection json
        BarcodeManagement2D.SetSimpleTextToEncode(AppConnectionTxt);
        BarcodeManagement2D.Set_BarcodeFontProvider(Enum::"Barcode Font Provider 2D"::IDAutomation2D);
        BarcodeManagement2D.Set_BarcodeSymbology(Enum::"Barcode Symbology 2D"::"Data Matrix");
        AppConnectionTxtEncoded := BarcodeManagement2D.GetEncodedBarcodeText();

        // Generate encoded value of E-mail Address
        Clear(AiDictionary);
        AiDictionary.Add('95', MailAddressTxt);
        BarcodeManagement2D.SetAiDictionary(AiDictionary);
        BarcodeManagement2D.Set_BarcodeFontProvider(Enum::"Barcode Font Provider 2D"::IDAutomation2D);
        BarcodeManagement2D.Set_BarcodeSymbology(Enum::"Barcode Symbology 2D"::"Data Matrix");
        MailAddressTxtEncoded := BarcodeManagement2D.GetEncodedBarcodeText();
    end;

    internal procedure SetParameters(_ApplicationId: Text; _DirectoryId: Text; _SoapUrl: Text; _MailAdressTxt: Text)
    begin
        // Store parameters
        ApplicationId := _ApplicationId;
        DirectoryId := _DirectoryId;
        SoapUrl := _SoapUrl;
        MailAddressTxt := _MailAdressTxt;
    end;

    var
        BarcodeManagement2D: Codeunit "MOB Report Barcode Mgt. 2D";
        ApplicationId: Text;
        DirectoryId: Text;
        SoapUrl: Text;
        ReqParamMissingErr: Label 'Required parameters missing. This report can not be executed directly.', Locked = true;
        PlayStoreUrlLbl: Label 'https://taskletfactory.com/download', Locked = true; // Forwards to app in Google Play Store
        PlayStoreUrlEncoded: Text;
        AppConnectionTxt: Text;
        AppConnectionTxtEncoded: Text;
        MailAddressTxt: Text;
        MailAddressTxtEncoded: Text;
        CompanyDisplayNameDefaulted: Text;
    /* #endif */
}
