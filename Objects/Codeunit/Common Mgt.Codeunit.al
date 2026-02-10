codeunit 81288 "MOB Common Mgt."
{
    Access = Public;
    //
    // AppVersion 25.0.0.0
    // 

    /// <summary>
    /// AssemblyLine.IsInventoriableItem(): Method not available for extension development in BC14 (but do exist in BC15)
    /// </summary>
    procedure AssemblyLine_IsInventoriableItem(_AssemblyLine: Record "Assembly Line"): Boolean
    begin
        exit(_AssemblyLine.IsInventoriableItem());
    end;

    /// <summary>
    /// ProdOrderComponent.IsInventoriableItem(): Method not available for extension development in BC14-BC16
    /// </summary>
    procedure ProdOrderComponent_IsInventoriableItem(_ProdOrderComponent: Record "Prod. Order Component"): Boolean
    begin
        exit(_ProdOrderComponent.IsInventoriableItem());
    end;

    /// <summary>
    /// ItemTrackingCode.IsSpecific(): New method only available from BC17
    /// </summary>
    procedure ItemTrackingCode_IsSpecific(var _ItemTrackingCode: Record "Item Tracking Code"): Boolean
    begin
        exit(_ItemTrackingCode.IsSpecific());
    end;

    [Obsolete('Use MobItemTrackingManagement.GetWhseExpirationDate instead (planned for removal 04/2025)', 'MOB5.47')]
    /// <summary>
    /// ItemTrackingManagement.GetWhseExpirationDate: New signature with ItemTrackingSetup replacing LotNo/SerialNo from BC19
    /// </summary>
    procedure GetWhseExpirationDate(_ItemNo: Code[20]; _VariantCode: Code[20]; _Location: Record Location; _MobTrackingSetup: Record "MOB Tracking Setup"; var _ExpiryDate: Date) ReturnExpDateFound: Boolean
    var
        MobItemTrackingManagement: Codeunit "MOB Item Tracking Management";
    begin
        exit(MobItemTrackingManagement.GetWhseExpirationDate(_ItemNo, _VariantCode, _Location, _MobTrackingSetup, _ExpiryDate));
    end;

    /// <remarks>
    /// TrackingSpecification.CopyTrackingFromEntrySummary: Method only available from BC16
    /// </remarks>
    procedure CopyTrackingFromEntrySummary(var _ToTrackingSpec: Record "Tracking Specification"; _FromEntrySummary: Record "Entry Summary")
    begin
        _ToTrackingSpec.CopyTrackingFromEntrySummary(_FromEntrySummary);
    end;

    /// <summary>
    /// TrackingSpecification.CopyNewTrackingFromTrackingSpec: Method only available from BC17
    /// </summary>
    procedure CopyNewTrackingFromTrackingSpec(var _ToTrackingSpec: Record "Tracking Specification"; _FromTrackingSpec: Record "Tracking Specification")
    begin
        _ToTrackingSpec.CopyNewTrackingFromTrackingSpec(_FromTrackingSpec);
    end;

    /// <summary>
    /// WhseActivityLine.SetTrackingFilterFromWhseActivityLine: Method only available from BC17
    /// </summary>
    procedure SetTrackingFilterFromWhseActivityLine(var _ToWhseActivityLine: Record "Warehouse Activity Line"; _FromWhseActivityLine: Record "Warehouse Activity Line")
    begin
        _ToWhseActivityLine.SetTrackingFilterFromWhseActivityLine(_FromWhseActivityLine);
    end;

    procedure GetLanguageID(_LanguageCode: Code[10]) _ReturnLanguageID: Integer
    var
        Language: Codeunit Language;
    begin
        _ReturnLanguageID := Language.GetLanguageId(_LanguageCode);
        if _ReturnLanguageID = 0 then
            _ReturnLanguageID := GlobalLanguage();

        exit(_ReturnLanguageID);
    end;

    procedure WhseShipmentConflict(_DocType: Enum "Sales Document Type"; _DocNo: Code[20]; _ShippingAdvice: Enum "Sales Header Shipping Advice"): Boolean
    var
        SalesHeader: Record "Sales Header";
    begin
        exit(SalesHeader.WhseShipmentConflict(_DocType, _DocNo, _ShippingAdvice));
    end;

    /// <remarks>
    /// Changed to Enum in BC18
    /// </remarks>
    procedure AsItemLedgerEntryTypeFromInteger(_Integer: Integer) _ItemLedgerEntryType: Enum "Item Ledger Entry Type"
    begin
        _ItemLedgerEntryType := "Item Ledger Entry Type".FromInteger(_Integer);
    end;

    procedure AsReservationBinding(_FromReservationBinding: Enum "Reservation Binding") _ToReservationBinding: Enum "Reservation Binding"
    begin
        _ToReservationBinding := _FromReservationBinding;
    end;

    procedure AsSalesDocumentTypeFromInteger(_Integer: Integer) _SalesDocumentType: Enum "Sales Document Type"
    begin
        _SalesDocumentType := "Sales Document Type".FromInteger(_Integer);
    end;

    procedure AsSalesDocumentType(_FromSalesDocumentType: Enum "Sales Document Type") _ToSalesDocumentType: Enum "Sales Document Type"
    begin
        _ToSalesDocumentType := _FromSalesDocumentType;
    end;

    procedure AsWhseActivitySortingMethod(_FromWhseActivitySortingMethod: Enum "Whse. Activity Sorting Method") _ToWhseActivitySortingMethod: Enum "Whse. Activity Sorting Method"
    begin
        _ToWhseActivitySortingMethod := _FromWhseActivitySortingMethod;
    end;

    procedure DeleteReservEntries(var ItemJnlLine: Record "Item Journal Line")
    var
        ReservMgt: Codeunit "Reservation Management";
    begin
        ReservMgt.SetReservSource(ItemJnlLine);
        ReservMgt.SetItemTrackingHandling(1); // Allow Deletion
        ReservMgt.DeleteReservEntries(true, 0);
    end;

    /// <summary>
    /// Redundant method (same in all platforms) but included to make source code easier to read and to still be able to call standard code
    /// </summary>
    procedure SetSourceFilterForTrackingSpec(var _TrackingSpec: Record "Tracking Specification"; _SourceType: Integer; _SourceSubtype: Integer; _SourceID: Code[20]; _SourceRefNo: Integer; _SourceKey: Boolean)
    begin
        _TrackingSpec.SetSourceFilter(_SourceType, _SourceSubtype, _SourceID, _SourceRefNo, _SourceKey);
    end;

    procedure SetSourceFilterForTrackingSpec(var _TrackingSpec: Record "Tracking Specification"; _SourceBatchName: Code[10]; _SourceProdOrderLine: Integer)
    begin
        _TrackingSpec.SetSourceFilter(_SourceBatchName, _SourceProdOrderLine);
    end;

    /// <summary>
    /// Redundant method (same in all platforms) but included to make source code easier to read and to still be able to call standard code
    /// </summary>
    procedure SetSourceFilterForReservEntry(var _ReservEntry: Record "Reservation Entry"; _SourceType: Integer; _SourceSubtype: Integer; _SourceID: Code[20]; _SourceRefNo: Integer; _SourceKey: Boolean)
    begin
        _ReservEntry.SetSourceFilter(_SourceType, _SourceSubtype, _SourceID, _SourceRefNo, _SourceKey);
    end;

    procedure SetSourceFilterForReservEntry(var _ReservEntry: Record "Reservation Entry"; _SourceBatchName: Code[10]; _SourceProdOrderLine: Integer)
    begin
        _ReservEntry.SetSourceFilter(_SourceBatchName, _SourceProdOrderLine);
    end;

    procedure TimeFactor(UnitOfMeasureCode: Code[10]) Factor: Decimal
    var
        ShopCalendarMgt: Codeunit "Shop Calendar Management";
    begin
        exit(ShopCalendarMgt.TimeFactor(UnitOfMeasureCode));
    end;

    procedure SaveAttachmentFromStream(var _DocumentAttachment: Record "Document Attachment"; _DocStream: InStream; _RecRef: RecordRef; _FileName: Text)
    begin
        _DocumentAttachment.SaveAttachmentFromStream(_DocStream, _RecRef, _FileName);
    end;

    /// <remarks>
    /// Renamed from Item."Scheduled Need (Qty.)" in BC18
    /// </remarks>
    procedure Item_CalcFields_QtyOnComponentines(var _Item: Record Item)
    begin
        _Item.CalcFields("Qty. on Component Lines");
    end;

    /// <remarks>
    /// Renamed from Item."Scheduled Need (Qty.)" in BC18
    /// </remarks>
    procedure Item_GetQtyOnComponentines(var _Item: Record Item): Decimal
    begin
        exit(_Item."Qty. on Component Lines");
    end;

    internal procedure GenerateHashMD5(_Text: Text): Text
    var
        CryptographyManagement: Codeunit "Cryptography Management";
        HashAlgorithmType: Option MD5,SHA1,SHA256,SHA384,SHA512;
    begin
        HashAlgorithmType := HashAlgorithmType::MD5;
        exit(CryptographyManagement.GenerateHash(_Text, HashAlgorithmType));
    end;

}
