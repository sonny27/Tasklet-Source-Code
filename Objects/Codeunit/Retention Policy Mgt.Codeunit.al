codeunit 81365 "MOB Retention Policy Mgt."
{
    Access = Public;
    ///<summary>
    /// The following Mobile WMS Tables are currently included in the List of avaliable Tables for Retention Setup
    /// - "MOB Document Queue" (Including predefined Retention Setup Policy)
    /// - "MOB Print Log" (Including predefined Retention Setup Policy)
    /// - "MOB WMS Media Queue"
    /// - "MOB WMS Registration"
    /// - "MOB Perf. Profile Entry"
    /// - "MOB License Plate"
    /// - "MOB License Plate Content"
    /// </summary>

    internal procedure SetupRetentionPolicy()
    /* #if BC16- ##
    begin
        // Only avaliable in BC17 or newer
    end;
    /* #endif */

    /* #if BC17+ */
    var
        MobDocQueue: Record "MOB Document Queue";
        MobMediaQueue: Record "MOB WMS Media Queue";
        MobRegistration: Record "MOB WMS Registration";
        MobPrintLog: Record "MOB Print Log";
        MobPerfProfileEntry: Record "MOB Perf. Profile Entry";
        MobLicensePlate: Record "MOB License Plate";
        MobLicensePlateContent: Record "MOB License Plate Content";
        RetenPolAllowedTables: Codeunit "Reten. Pol. Allowed Tables";
    begin
        // Create a Retention Setup for "MOB Document Queue"
        CreateSetupRetentionPolicy(Database::"MOB Document Queue", MobDocQueue.FieldNo("Created Date/Time"), "Retention Period Enum"::"6 Months");

        // Create a Retention Setup for "MOB Print Log"
        CreateSetupRetentionPolicy(Database::"MOB Print Log", MobPrintLog.FieldNo("Created Date/Time"), "Retention Period Enum"::"6 Months");

        // Add additional Tables to "Retention Policy Allowed Tables" without any predefined Filters
        RetenPolAllowedTables.AddAllowedTable(Database::"MOB WMS Media Queue", MobMediaQueue.FieldNo("Created Date"));
        RetenPolAllowedTables.AddAllowedTable(Database::"MOB WMS Registration", MobRegistration.FieldNo(RegistrationCreated));
        RetenPolAllowedTables.AddAllowedTable(Database::"MOB Perf. Profile Entry", MobPerfProfileEntry.FieldNo(SystemCreatedAt)); // The table is not used before BC20, but it is created for all BC versions
        RetenPolAllowedTables.AddAllowedTable(Database::"MOB License Plate", MobLicensePlate.FieldNo(SystemCreatedAt));
        RetenPolAllowedTables.AddAllowedTable(Database::"MOB License Plate Content", MobLicensePlateContent.FieldNo(SystemCreatedAt));
    end;

    local procedure CreateSetupRetentionPolicy(_TableId: Integer; _DefaultDateFieldNo: Integer; _RetentionPeriod: Enum "Retention Period Enum")
    var
        RetenPolSetup: Record "Retention Policy Setup";
        RetenPolSetupLine: Record "Retention Policy Setup Line";
        RetenPolAllowedTables: Codeunit "Reten. Pol. Allowed Tables";
        RecRef: RecordRef;
        Enabled: Boolean;
        Locked: Boolean;
        TableFilters: JsonArray;
    begin
        if RetenPolSetup.Get(_TableId) then
            exit;

        // Create a dummy RecRef without filters and add it to TableFilters to be able to read locale independent Retention Period from the dummy setup line
        Enabled := false;
        Locked := false;
        RecRef.Open(_TableId);
        RetenPolAllowedTables.AddTableFilterToJsonArray(TableFilters, _RetentionPeriod, _DefaultDateFieldNo, Enabled, Locked, RecRef);

        // Create a Retention Setup and a dummy Retention Setup Line 
        RetenPolAllowedTables.AddAllowedTable(_TableId, _DefaultDateFieldNo, TableFilters);
        RetenPolSetup.Init();
        RetenPolSetup."Table Id" := _TableId;
        RetenPolSetup.Validate("Date Field No.", _DefaultDateFieldNo);
        RetenPolSetup.Insert();

        // Find and delete dummy Retention Setup Line and update Retention Policy with Retention Period
        RetenPolSetupLine.Reset();
        RetenPolSetupLine.SetRange("Table ID", _TableId);
        if RetenPolSetupLine.FindFirst() then begin
            RetenPolSetupLine.Delete(true);
            RetenPolSetup.Validate("Apply to all records", true);
            RetenPolSetup.Validate("Retention Period", RetenPolSetupLine."Retention Period");
            RetenPolSetup.Validate(Enabled, false);
            RetenPolSetup.Modify(true);
        end;
    end;
    /* #endif */
}
