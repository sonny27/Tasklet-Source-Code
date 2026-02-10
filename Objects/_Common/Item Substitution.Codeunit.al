codeunit 81316 "MOB Item Subst."
{
    Access = Public;
    var
        ItemSubst: Codeunit "Item Subst.";

    /// <summary>
    /// Wrapper for ItemSubst.FindItemSubstitutions, without the unneeded GrossReq, SchedRcpt
    /// </summary>
    internal procedure FindItemSubstitutions(var TempItemSubstitutions: Record "Item Substitution" temporary; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; DemandDate: Date; CalcATP: Boolean): Boolean
    var
        GrossReq: Decimal;
        SchedRcpt: Decimal;
    begin
        /* #if BC26+ */
        exit(ItemSubst.FindItemSubstitutions(TempItemSubstitutions, ItemNo, VariantCode, LocationCode, DemandDate, CalcATP, GrossReq, SchedRcpt));
        /* #endif */

        /* #if BC25- ##
        if ItemSubst.PrepareSubstList(ItemNo, VariantCode, LocationCode, DemandDate, CalcATP) then begin
            ItemSubst.GetTempItemSubstList(TempItemSubstitutions);
            exit(true);
        end;
        /* #endif */
    end;

    /// <summary>
    /// Wrapper for MfgItemSubst.UpdateProdOrderComp
    /// "UpdateComponent" is the legacy name
    /// </summary>
    /* #if BC26+ */
    internal procedure UpdateProdOrderComp(var ProdOrderComp: Record "Prod. Order Component"; SubstItemNo: Code[20]; SubstVariantCode: Code[10])
    var
        MfgItemSubst: Codeunit "Mfg. Item Substitution";
    begin
        MfgItemSubst.UpdateProdOrderComp(ProdOrderComp, SubstItemNo, SubstVariantCode);
    end;
    /* #endif */

    /* #if BC25- ##
    internal procedure UpdateProdOrderComp(var ProdOrderComp: Record "Prod. Order Component"; SubstItemNo: Code[20]; SubstVariantCode: Code[10])
    begin
        ItemSubst.UpdateComponent(ProdOrderComp, SubstItemNo, SubstVariantCode);    
    end;
    /* #endif */
}
