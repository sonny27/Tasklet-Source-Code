codeunit 81326 "MOB Device Usage Validation"
{
    Access = Public;
    var
        MobDeviceManagement: Codeunit "MOB Device Management";
        OnlySaasSandboxLbl: Label 'This app is only licensed for Business Central Online and use in a "Sandbox". Please contact your reseller for a full license.', Locked = true;

    internal procedure ValidateDeviceUsage(var _XmlRequestDoc: XmlDocument)
    var
        MobEnvironmentInformation: Codeunit "MOB Environment Information";
    begin
        // Fully licensed version of the app doesn't require any validation
        if not MobDeviceManagement.GetDeviceInstallerIsUnmanaged(_XmlRequestDoc) then
            exit;

        if (not MobEnvironmentInformation.IsSandbox()) or (not MobEnvironmentInformation.IsSaaSInfrastructure()) then
            Error(OnlySaasSandboxLbl);
    end;
}
