codeunit 81330 "MOB Environment Information"
{
    Access = Public;
    /* #if BC15+ */
    procedure IsSandbox(): Boolean
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        exit(EnvironmentInformation.IsSandbox());
    end;
    /* #endif */
    /* #if BC14- ##
    procedure IsSandbox(): Boolean
    var
        TenantManagement: Codeunit "Tenant Management";
    begin
        exit(TenantManagement.IsSandbox());
    end;
    /* #endif */

    /* #if BC15+ */
    internal procedure IsSaaS(): Boolean
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        exit(EnvironmentInformation.IsSaaS());
    end;
    /* #endif */
    /* #if BC14- ##
    internal procedure IsSaaS(): Boolean
    begin
        exit(false); // BC14- cannot be SaaS
    end;
    /* #endif */

    /* #if BC19+ */
    internal procedure IsSaaSInfrastructure(): Boolean
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        exit(EnvironmentInformation.IsSaaSInfrastructure());
    end;
    /* #endif */
    /* #if BC18- ##
    internal procedure IsSaaSInfrastructure(): Boolean
    begin
        exit(false); // BC18- cannot be IsSaaSInfrastructure
    end;
    /* #endif */

    internal procedure GetCompanyDisplayNameDefaulted(): Text[250]
    var
        Company: Record Company;
    begin
        Company.Get(CompanyName());
        if Company."Display Name" <> '' then
            exit(Company."Display Name");
        exit(Company.Name)
    end;
}
