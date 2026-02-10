codeunit 81414 "MOB ProdUnplannedConsumption"
{
    Access = Internal;

    internal procedure CreateMessages(_LanguageCode: Code[10])
    var
        MobWmsLanguage: Codeunit "MOB WMS Language";
        UnplannedConsumptionCompletedTxt: Label 'Item %1 consumed for production order %2 (%3).', Comment = '%1 = Item Number, %2 = Production Order Number, %3 = Output item number';
        UnplannedConsumptionTitleTxt: Label 'Unplanned Consumption';
    begin
        MobWmsLanguage.CreateMessage(_LanguageCode, 'PROD_UNPLANNED_CONSUMPTION_TITLE', UnplannedConsumptionTitleTxt);
        MobWmsLanguage.CreateMessage(_LanguageCode, 'PROD_UNPL_CONSUMPTION_COMPLETED', UnplannedConsumptionCompletedTxt);
    end;

    internal procedure AddHeaderConfiguration(var _HeaderConfiguration: Record "MOB HeaderField Element")
    var
        HeaderConfig: Codeunit "MOB ProdUnplConsump_HdrConfig";
    begin
        HeaderConfig.AddConfiguration(_HeaderConfiguration);
    end;

    internal procedure GetRegistrationConfiguration(var _HeaderValues: Record "MOB NS Request Element"; var _Steps: Record "MOB Steps Element"; var _RegistrationTypeTracking: Text)
    var
        RegConfig: Codeunit "MOB ProdUnplConsump_RegConfig";
    begin
        RegConfig.CreateConfiguration(_HeaderValues, _Steps, _RegistrationTypeTracking);
    end;

    internal procedure Post(var _TempRequestValues: Record "MOB NS Request Element" temporary; var _RegistrationTypeTracking: Text; var _SuccessMessage: Text)
    var
        RegPosting: Codeunit "MOB ProdUnplConsump_RegPosting";
    begin
        RegPosting.Post(_TempRequestValues, _RegistrationTypeTracking, _SuccessMessage);
    end;
}
