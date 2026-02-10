codeunit 81398 "MOB Production_Configuration"
{
    Access = Internal;

    var
        ProdUnplannedConsumption: Codeunit "MOB ProdUnplannedConsumption";

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Reference Data", 'OnGetReferenceData_OnAddHeaderConfigurations', '', false, false)]
    local procedure AddProductionHeaderConfigurations_OnGetReferenceData_OnAddHeaderConfigurations(var _HeaderFields: Record "MOB HeaderField Element")
    begin
        AddHeaderConfigurations(_HeaderFields);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Language", 'OnAddMessages', '', false, false)]
    local procedure AddProductionMessages_OnAddMessages(_LanguageCode: Code[10])
    begin
        CreateMessages(_LanguageCode);
    end;

    internal procedure AddHeaderConfigurations(var _HeaderConfiguration: Record "MOB HeaderField Element")
    begin
        ProdUnplannedConsumption.AddHeaderConfiguration(_HeaderConfiguration);
    end;

    local procedure CreateMessages(_LanguageCode: Code[10])
    var
        MobToolbox: Codeunit "MOB Toolbox";
        InputLanguageId: Integer;
        SavedLanguageId: Integer;
    begin
        InputLanguageId := MobToolbox.GetLanguageId(_LanguageCode, false);
        SavedLanguageId := GlobalLanguage();
        if (InputLanguageId = 0) or (SavedLanguageId = 0) then
            exit;
        if InputLanguageId <> SavedLanguageId then
            GlobalLanguage(InputLanguageId);

        ProdUnplannedConsumption.CreateMessages(_LanguageCode);

        if SavedLanguageId <> GlobalLanguage() then
            GlobalLanguage(SavedLanguageId);
    end;
}
