codeunit 81328 "MOB Register Assisted Setup"
{
    Access = Public;
    /* #if BC25+ */
    var
        SandboxSetupTitleLbl: Label 'Configure a sandbox', Locked = true;
        SandboxSetupShortTitleLbl: Label 'Set up a user and a device for a sandbox', Locked = true;
        SandboxSetupDescriptionLbl: Label 'Set up a user and connect a supported device to the current company to easy try or demonstrate the Mobile WMS solution', Locked = true;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Guided Experience", 'OnRegisterAssistedSetup', '', true, true)]
    local procedure AddMobileWmsSetup_OnRegisterAssistedSetup()
    var
        GuidedExperience: Codeunit "Guided Experience";
        MobEnvironmentInformation: Codeunit "MOB Environment Information";
        AssistedSetupGroup: Enum "Assisted Setup Group";
        VideoCategory: Enum "Video Category";
    begin
        if not MobEnvironmentInformation.IsSandbox() then
            exit;
        if not MobEnvironmentInformation.IsSaaSInfrastructure() then
            exit;

        GuidedExperience.InsertAssistedSetup(
                                         // Link text for the assisted setup guide
                                         SandboxSetupTitleLbl,
                                         // Short description, not shown on page 
                                         SandboxSetupShortTitleLbl,
                                         // Text that shows in Description column
                                         SandboxSetupDescriptionLbl,
                                         // Expected duration in minutes
                                         5,
                                         // Object type
                                         ObjectType::Page,
                                         // Object ID
#pragma warning disable AL0432
                                         Page::"MOB WMS Sandbox Config. Guide",
#pragma warning restore AL0432
                                         // Assign guide to Task category
                                         AssistedSetupGroup::MobileWMS,
                                         //Video URL not required
                                         '',
                                         VideoCategory::Uncategorized,
                                         //Help URL not required
                                         '');
    end;

    /* #endif */
}
