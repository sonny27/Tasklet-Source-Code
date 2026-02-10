codeunit 81396 "MOB ProdUnplConsump_HdrConfig"
{
    Access = Internal;

    internal procedure AddConfiguration(var _HeaderConfiguration: Record "MOB HeaderField Element")
    var
        DummyProdOrderLine: Record "Prod. Order Line";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        PageHeaderConfigKeyTok: Label 'ProdUnplannedConsumptionHeader', Locked = true;
    begin
        _HeaderConfiguration.InitConfigurationKey(PageHeaderConfigKeyTok, true);

        _HeaderConfiguration.Create_TextField_OrderBackendID(10);
        _HeaderConfiguration.Set_label(StrSubstNo(MobWmsLanguage.GetMessage('FROM'), DummyProdOrderLine.TableCaption()));
        _HeaderConfiguration.Save();

        _HeaderConfiguration.Create_TextField_ItemNumberAsItem(20); // Item used as name to avoid value trasfer of ItemNumber from OrderLines page (Prod. Order Component line)
        _HeaderConfiguration.Set_clearOnClear(true);
        _HeaderConfiguration.Save();
    end;
}
