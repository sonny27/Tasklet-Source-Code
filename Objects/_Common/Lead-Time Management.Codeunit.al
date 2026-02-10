codeunit 81347 "MOB Lead-Time Management"
{
    Access = Public;
    /// <remarks>
    /// "Lead-Time Management".GetPlannedEndingDate() Signature with 7 parameters (calculate forward from starting date) 
    ///  * Was called PlannedEndingDate2 in BC14.
    ///  * Changed to PlannedEndingDate in BC15.
    ///  * Changed to GetPlannedEndingDate and using an Enum for RefOrderType in BC25 (was an Option in BC14-BC24).
    /// </remarks>
    /* #if BC25+ */
    internal procedure GetPlannedEndingDate(ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]; VendorNo: Code[20]; LeadTime: Code[20]; RefOrderType: Enum "Requisition Ref. Order Type"; StartingDate: Date): Date
    var
        LeadTimeMgt: Codeunit "Lead-Time Management";
    begin
        exit(LeadTimeMgt.GetPlannedEndingDate(ItemNo, LocationCode, VariantCode, VendorNo, LeadTime, RefOrderType, StartingDate));
    end;
    /* #endif */
    /* #if BC15,BC16,BC17,BC18,BC19,BC20,BC21,BC22,BC23,BC24 ##
    internal procedure GetPlannedEndingDate(ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]; VendorNo: Code[20]; LeadTime: Code[20]; RefOrderType: Option " ",Purchase,"Prod. Order",Transfer,Assembly; StartingDate: Date): Date
    var
        LeadTimeMgt: Codeunit "Lead-Time Management";
    begin
        exit(LeadTimeMgt.PlannedEndingDate(ItemNo, LocationCode, VariantCode, VendorNo, LeadTime, RefOrderType, StartingDate));
    end;
    /* #endif */
    /* #if BC14 ##
    internal procedure GetPlannedEndingDate(ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]; VendorNo: Code[20]; LeadTime: Code[20]; RefOrderType: Option " ",Purchase,"Prod. Order",Transfer,Assembly; StartingDate: Date): Date
    var
        LeadTimeMgt: Codeunit "Lead-Time Management";
    begin
        exit(LeadTimeMgt.PlannedEndingDate2(ItemNo, LocationCode, VariantCode, VendorNo, LeadTime, RefOrderType, StartingDate));
    end;
    /* #endif */

    /// <remarks>
    /// "Lead-Time Management".GetPlannedDueDate()
    ///  * Was called PlannedDueDate in BC14.
    ///  * Changed to GetPlannedDueDate and using an Enum for RefOrderType in BC25 (was an Option in BC14-BC24).
    /// </remarks>
    /* #if BC25+ */
    internal procedure GetPlannedDueDate(ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]; EndingDate: Date; VendorNo: Code[20]; RefOrderType: Enum "Requisition Ref. Order Type") Result: Date
    var
        LeadTimeMgt: Codeunit "Lead-Time Management";
    begin
        exit(LeadTimeMgt.GetPlannedDueDate(ItemNo, LocationCode, VariantCode, EndingDate, VendorNo, RefOrderType));
    end;
    /* #endif */
    /* #if BC24- ##
    internal procedure GetPlannedDueDate(ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]; EndingDate: Date; VendorNo: Code[20]; RefOrderType: Option " ",Purchase,"Prod. Order",Transfer,Assembly) Result: Date
    var
        LeadTimeMgt: Codeunit "Lead-Time Management";
    begin
        exit(LeadTimeMgt.PlannedDueDate(ItemNo, LocationCode, VariantCode, EndingDate, VendorNo, RefOrderType));
    end;
    /* #endif */
}
