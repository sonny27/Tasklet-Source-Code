codeunit 81317 "MOB Item Tracking Management"
{
    Access = Public;

    /// <summary>
    /// Based on ItemTrackingMgt.GetItemTrackingSetup
    /// </summary>
    /* #if BC16+ */
    procedure GetItemTrackingSetup(var _ItemTrackingCode: Record "Item Tracking Code"; _EntryType: Option Purchase,Sale,"Positive Adjmt.","Negative Adjmt.",Transfer,Consumption,Output," ","Assembly Consumption","Assembly Output"; _Inbound: Boolean; var _MobTrackingSetup: Record "MOB Tracking Setup")
    var
        ItemTrackingSetup: Record "Item Tracking Setup";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        MobCommonMgt: Codeunit "MOB Common Mgt.";
    begin
        ItemTrackingSetup.TransferFields(_MobTrackingSetup);
        ItemTrackingMgt.GetItemTrackingSetup(_ItemTrackingCode, MobCommonMgt.AsItemLedgerEntryTypeFromInteger(_EntryType), _Inbound, ItemTrackingSetup);
        _MobTrackingSetup.CopyTrackingRequiredFromItemTrackingSetup(ItemTrackingSetup);
    end;
    /* #endif */
    /* #if BC15- ##
    procedure GetItemTrackingSetup(var _ItemTrackingCode: Record "Item Tracking Code"; _EntryType: Option Purchase,Sale,"Positive Adjmt.","Negative Adjmt.",Transfer,Consumption,Output," ","Assembly Consumption","Assembly Output"; _Inbound: Boolean; var _MobTrackingSetup: Record "MOB Tracking Setup")
    var
        ItemTrackingMgt: Codeunit "Item Tracking Management";
    begin
        ItemTrackingMgt.GetItemTrackingSettings(_ItemTrackingCode,
                                                    _EntryType,
                                                    _Inbound,
                                                    _MobTrackingSetup."Serial No. Required",
                                                    _MobTrackingSetup."Lot No. Required",
                                                    _MobTrackingSetup."Serial No. Info Required",
                                                    _MobTrackingSetup."Lot No. Info Required");
    end;
    /* #endif */


    /// <summary>
    /// ItemTrackingMgt.ExistingExpirationDate: New signature with TrackingSpecification only available from BC18.1 (=BC19 build)
    /// </summary>
    /* #if BC19+ */
    procedure ExistingExpirationDate(_TrackingSpecification: Record "Tracking Specification"; _TestMultiple: Boolean; var _EntriesExist: Boolean): Date
    var
        ItemTrackingMgt: Codeunit "Item Tracking Management";
    begin
        exit(ItemTrackingMgt.ExistingExpirationDate(_TrackingSpecification, _TestMultiple, _EntriesExist));
    end;
    /* #endif */
    /* #if BC18- ##
    procedure ExistingExpirationDate(_TrackingSpecification: Record "Tracking Specification"; _TestMultiple: Boolean; var _EntriesExist: Boolean): Date
    var
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        SerialNo: Code[50];
        LotNo: Code[50];
    begin
        LotNo := _TrackingSpecification."Lot No.";
        SerialNo := _TrackingSpecification."Serial No.";
        exit(ItemTrackingMgt.ExistingExpirationDate(_TrackingSpecification."Item No.", _TrackingSpecification."Variant Code", LotNo, SerialNo, _TestMultiple, _EntriesExist));
    end;
    /* #endif */


    /// <summary>
    /// ItemTrackingMgt.ExistingExpirationDate: New signature with ItemTrackingSetup replacing LotNo/SerialNo from BC19
    /// </summary>
    /* #if BC19+ */
    procedure ExistingExpirationDate(_ItemNo: Code[20]; _VariantCode: Code[20]; _MobTrackingSetup: Record "MOB Tracking Setup"; _TestMultiple: Boolean; var _EntriesExist: Boolean): Date
    var
        ItemTrackingSetup: Record "Item Tracking Setup";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
    begin
        ItemTrackingSetup.TransferFields(_MobTrackingSetup);
        exit(ItemTrackingMgt.ExistingExpirationDate(_ItemNo, _VariantCode, ItemTrackingSetup, _TestMultiple, _EntriesExist));
    end;
    /* #endif */
    /* #if BC18- ##
    procedure ExistingExpirationDate(_ItemNo: Code[20]; _VariantCode: Code[20]; _MobTrackingSetup: Record "MOB Tracking Setup"; _TestMultiple: Boolean; var _EntriesExist: Boolean): Date
    var
        ItemTrackingMgt: Codeunit "Item Tracking Management";
    begin
        exit(ItemTrackingMgt.ExistingExpirationDate(_ItemNo, _VariantCode, _MobTrackingSetup."Lot No.", _MobTrackingSetup."Serial No.", _TestMultiple, _EntriesExist));
    end;
    /* #endif */


    /// <summary>
    /// ItemTrackingMgt.GetWhseExpirationDate: New signature with ItemTrackingSetup replacing LotNo/SerialNo from BC19
    /// From BC24 Microsoft changed the ItemTrackingMgt.GetWhseExpirationDate() function to only return true if an expiration date is found.
    /// Mobile WMS needs to the keep the old behavior, so the function is reimplemented here.
    /// </summary>
    /* #if BC19+ */
    procedure GetWhseExpirationDate(_ItemNo: Code[20]; _VariantCode: Code[20]; _Location: Record Location; _MobTrackingSetup: Record "MOB Tracking Setup"; var _ExpiryDate: Date) ReturnExpDateFound: Boolean
    var
        ItemTrackingSetup: Record "Item Tracking Setup";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        EntriesExist: Boolean;
    begin
        ItemTrackingSetup.TransferFields(_MobTrackingSetup);

        _ExpiryDate := ItemTrackingMgt.ExistingExpirationDate(_ItemNo, _VariantCode, ItemTrackingSetup, false, EntriesExist);
        if EntriesExist then
            exit(true);

        _ExpiryDate := ItemTrackingMgt.WhseExistingExpirationDate(_ItemNo, _VariantCode, _Location, ItemTrackingSetup, EntriesExist);
        if EntriesExist then
            exit(true);

        _ExpiryDate := 0D;
        ReturnExpDateFound := false;
    end;
    /* #endif */
    /* #if BC18- ##
    procedure GetWhseExpirationDate(_ItemNo: Code[20]; _VariantCode: Code[20]; _Location: Record Location; _MobTrackingSetup: Record "MOB Tracking Setup"; var _ExpiryDate: Date) ReturnExpDateFound: Boolean
    var
        ItemTrackingMgt: Codeunit "Item Tracking Management";
    begin
        ReturnExpDateFound := ItemTrackingMgt.GetWhseExpirationDate(_ItemNo, _VariantCode, _Location, _MobTrackingSetup."Lot No.", _MobTrackingSetup."Serial No.", _ExpiryDate);
        exit(ReturnExpDateFound);
    end;
    /* #endif */

}
