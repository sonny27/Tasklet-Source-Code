codeunit 81470 "MOB Over-Receipt Mgt."
{
    Access = Public;

    /* #if BC22- ##
    var
        OVERRECEIPT_NOT_SUPPORTED_Err: Label 'Internal error: Over-Receipt not supported in this version.', Locked = true;
    /* #endif */

    /// <summary>
    /// Additional signature for standard method OverReceiptMgt.IsOverReceiptAllowed(). Used to detect IsAllowed before entry.
    /// Standard events are supported from BC20.
    /// </summary>
    /* #if BC20+ */
    procedure IsOverReceiptAllowed(_PurchLine: Record "Purchase Line") OverReceiptAllowed: Boolean
    var
        OverReceiptMgt: Codeunit "Over-Receipt Mgt.";
    begin
        OverReceiptAllowed := OverReceiptMgt.IsOverReceiptAllowed();
        OverReceiptAllowed := OverReceiptAllowed and ((_PurchLine."Over-Receipt Code" <> '') or (GetDefaultOverReceiptCode(_PurchLine) <> ''));
    end;
    /* #endif */

    /* #if BC16,BC17,BC18,BC19 ##
    procedure IsOverReceiptAllowed(_PurchLine: Record "Purchase Line") OverReceiptAllowed: Boolean
    begin
        OverReceiptAllowed := (_PurchLine."Over-Receipt Code" <> '') or (GetDefaultOverReceiptCode(_PurchLine) <> '');
    end;
    /* #endif */

    /* #if BC15- ##
    procedure IsOverReceiptAllowed(_PurchLine: Record "Purchase Line") OverReceiptAllowed: Boolean
    begin
        OverReceiptAllowed := false;
    end;
    /* #endif */


    /// <summary>
    /// Additional signature for standard method OverReceiptMgt.IsOverReceiptAllowed(). Used from BC16 for "Warehouse Receipt" to detect IsAllowed before entry.
    /// Standard events are supported from BC20.
    /// </summary>
    /* #if BC20+ */
    procedure IsOverReceiptAllowed(_WhseReceiptLine: Record "Warehouse Receipt Line") OverReceiptAllowed: Boolean
    var
        OverReceiptMgt: Codeunit "Over-Receipt Mgt.";
    begin
        OverReceiptAllowed := OverReceiptMgt.IsOverReceiptAllowed();
        OverReceiptAllowed := OverReceiptAllowed and ((_WhseReceiptLine."Over-Receipt Code" <> '') or (GetDefaultOverReceiptCode(_WhseReceiptLine) <> ''));
    end;
    /* #endif */

    /* #if BC16,BC17,BC18,BC19 ##
    procedure IsOverReceiptAllowed(_WhseReceiptLine: Record "Warehouse Receipt Line") OverReceiptAllowed: Boolean
    begin
        OverReceiptAllowed := (_WhseReceiptLine."Over-Receipt Code" <> '') or (GetDefaultOverReceiptCode(_WhseReceiptLine) <> '');
    end;
    /* #endif */

    /* #if BC15- ##
    procedure IsOverReceiptAllowed(_WhseReceiptLine: Record "Warehouse Receipt Line") OverReceiptAllowed: Boolean
    begin
        OverReceiptAllowed := false;
    end;
    /* #endif */

    /// <summary>
    /// Additional signature for standard method OverReceiptMgt.IsOverReceiptAllowed(). Used from BC23 for "Invt. Put-away" to detect IsAllowed before entry.
    /// </summary>
    /* #if BC23+ */
    procedure IsOverReceiptAllowed(_WhseActivityLine: Record "Warehouse Activity Line") OverReceiptAllowed: Boolean
    var
        OverReceiptMgt: Codeunit "Over-Receipt Mgt.";
    begin
        if _WhseActivityLine."Activity Type" <> _WhseActivityLine."Activity Type"::"Invt. Put-away" then begin
            OverReceiptAllowed := false;
            exit;
        end;

        OverReceiptAllowed := OverReceiptMgt.IsOverReceiptAllowed();
        OverReceiptAllowed := OverReceiptAllowed and ((_WhseActivityLine."Over-Receipt Code" <> '') or (GetDefaultOverReceiptCode(_WhseActivityLine) <> ''));
    end;
    /* #endif */

    /* #if BC22- ##
    procedure IsOverReceiptAllowed(_WhseActivityLine: Record "Warehouse Activity Line") OverReceiptAllowed: Boolean
    begin
        OverReceiptAllowed := false;
    end;
    /* #endif */

    /// <summary>
    /// Validate "Over-Receipt Quantity" separately to support validation code from BC16.0 version (cannot over-validate "Qty. to Receive" directly in this version)
    /// </summary>
    procedure ValidateOverReceiptQuantity(var _PurchLine: Record "Purchase Line"; _OverReceiptQuantity: Decimal)
    /* #if BC16+ */
    var
        MobPreventDirectCostCalc: Codeunit "MOB Prevent Direct Cost Calc";
    begin
        BindSubscription(MobPreventDirectCostCalc);
        _PurchLine.Validate("Over-Receipt Quantity", _OverReceiptQuantity);
        UnbindSubscription(MobPreventDirectCostCalc);
    end;
    /* #endif */
    /* #if BC15- ##
    begin
        Error(OVERRECEIPT_NOT_SUPPORTED_Err);
    end;
    /* #endif */

    /// <summary>
    /// Validate "Over-Receipt Quantity" separately to support validation code from BC16.0 version (cannot over-validate "Qty. to Receive" directly in this version).
    /// </summary>
    procedure ValidateOverReceiptQuantity(var _WhseReceiptLine: Record "Warehouse Receipt Line"; _OverReceiptQuantity: Decimal)
    /* #if BC16+ */
    var
        MobPreventDirectCostCalc: Codeunit "MOB Prevent Direct Cost Calc";
    begin
        BindSubscription(MobPreventDirectCostCalc);
        _WhseReceiptLine.Validate("Over-Receipt Quantity", _OverReceiptQuantity);
        UnbindSubscription(MobPreventDirectCostCalc);
    end;
    /* #endif */
    /* #if BC15- ##
    begin
        Error(OVERRECEIPT_NOT_SUPPORTED_Err);
    end;
    /* #endif */

    /// <summary>
    /// Validate "Over-Receipt Quantity" separately (cannot over-validate "Qty. to Handle" directly). Used from BC23 for "Invt. Put-away".
    /// </summary>
    procedure ValidateOverReceiptQuantity(var _WhseActLine: Record "Warehouse Activity Line"; _OverReceiptQuantity: Decimal)
    /* #if BC23+ */
    var
        MobPreventDirectCostCalc: Codeunit "MOB Prevent Direct Cost Calc";
    begin
        BindSubscription(MobPreventDirectCostCalc);
        _WhseActLine.Validate("Over-Receipt Quantity", _OverReceiptQuantity);
        UnbindSubscription(MobPreventDirectCostCalc);
    end;
    /* #endif */
    /* #if BC22- ##
    begin
        Error(OVERRECEIPT_NOT_SUPPORTED_Err);
    end;
    /* #endif */

    /// <summary>
    /// Replacing standard method OverReceiptMgt.GetDefaultOverReceiptCode() (inaccessible in BC16 due to OnPrem-tag).
    /// Can only be called from BC16 and newer. Standard events are supported from BC20.
    /// </summary>
    /* #if BC20+ */
    procedure GetDefaultOverReceiptCode(_PurchLine: Record "Purchase Line") DefaultOverReceiptCode: Code[20]
    var
        OverReceiptMgt: Codeunit "Over-Receipt Mgt.";
    begin
        DefaultOverReceiptCode := OverReceiptMgt.GetDefaultOverReceiptCode(_PurchLine);
    end;
    /* #endif */

    /* #if BC16,BC17,BC18,BC19 ##
    procedure GetDefaultOverReceiptCode(_PurchLine: Record "Purchase Line") DefaultOverReceiptCode: Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        OverReceiptCode: Record "Over-Receipt Code";
    begin
        DefaultOverReceiptCode := '';

        if _PurchLine.Type <> _PurchLine.Type::Item then
            exit; // Over-Receipt Codes can only be used when line type is Item

        Item.Get(_PurchLine."No.");
        if Item."Over-Receipt Code" <> '' then begin
            DefaultOverReceiptCode := Item."Over-Receipt Code";
            exit;
        end;

        PurchaseHeader.Get(_PurchLine."Document Type", _PurchLine."Document No.");
        Vendor.Get(PurchaseHeader."Buy-from Vendor No.");
        if Vendor."Over-Receipt Code" <> '' then begin
            DefaultOverReceiptCode := Vendor."Over-Receipt Code";
            exit;
        end;

        OverReceiptCode.SetRange(Default, true);
        if OverReceiptCode.FindFirst() then
            DefaultOverReceiptCode := OverReceiptCode.Code;
    end;
    /* #endif */

    /* #if BC15- ##
    procedure GetDefaultOverReceiptCode(_PurchLine: Record "Purchase Line") DefaultOverReceiptCode: Code[20]
    begin
        DefaultOverReceiptCode := '';
    end;
    /* #endif */


    /// <summary>
    /// Additional signature to call OverReceiptMgt.GetDefaultOverReceiptCode(_PurchLine). Used from BC16 for Warehouse Receipt.
    /// Standard events are supported from BC20.
    /// </summary>
    /* #if BC16+ */
    procedure GetDefaultOverReceiptCode(_WhseReceiptLine: Record "Warehouse Receipt Line"): Code[20]
    var
        PurchaseLine: Record "Purchase Line";
    begin
        if _WhseReceiptLine."Source Document" <> _WhseReceiptLine."Source Document"::"Purchase Order" then  // Must be based on PurchaseLine, intentionally excluding Purchase Return Order
            exit('');

        PurchaseLine.Get(_WhseReceiptLine."Source Subtype", _WhseReceiptLine."Source No.", _WhseReceiptLine."Source Line No.");
        exit(GetDefaultOverReceiptCode(PurchaseLine));
    end;
    /* #endif */

    /* #if BC15- ##
    procedure GetDefaultOverReceiptCode(_WhseReceiptLine: Record "Warehouse Receipt Line"): Code[20]
    begin
        exit('');
    end;
    /* #endif */

    /// <summary>
    /// Additional signature to call OverReceiptMgt.GetDefaultOverReceiptCode(_PurchLine). Used from BC23 for "Invt. Put-away".
    /// Standard events are supported from BC23.
    /// </summary>
    /* #if BC23+ */
    procedure GetDefaultOverReceiptCode(_WhseActivityLine: Record "Warehouse Activity Line"): Code[20]
    var
        PurchaseLine: Record "Purchase Line";
    begin
        if _WhseActivityLine."Source Document" <> _WhseActivityLine."Source Document"::"Purchase Order" then  // Must be based on PurchaseLine, intentionally excluding Purchase Return Order
            exit('');

        PurchaseLine.Get(_WhseActivityLine."Source Subtype", _WhseActivityLine."Source No.", _WhseActivityLine."Source Line No.");
        exit(GetDefaultOverReceiptCode(PurchaseLine));
    end;
    /* #endif */

    /* #if BC22- ##
    procedure GetDefaultOverReceiptCode(_WhseActivityLine: Record "Warehouse Activity Line"): Code[20]
    begin
        exit('');
    end;
    /* #endif */

}
