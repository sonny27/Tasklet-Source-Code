codeunit 82244 "MOB WMS Pack Adhoc Reg-PostPck"
{
    Access = Public;
    //
    // 'PostPacking' (incl. eventsubscribers incl. eventpublishers)
    // Intentionally no EventsubscriberInstance = Manual to allow adhoc PostPacking to run programmatically.
    // All other methods are processed only if PackAnShip feature is enabled
    //

    var
        MobSessionData: Codeunit "MOB SessionData";
        MobPackFeatureMgt: Codeunit "MOB Pack Feature Management";
        CheckRegistrationsErr: Label 'Please Check Registrations.';
        ShippingAdviceErr: Label '%1 %2 must be completely shipped because the value of field ''%3'' is ''%4''', Comment = '%1 contains SalesHeader."Document Type", %2 contains SalesHeader."No.", %3 contains SalesHeader.FieldCaption("Shipping Advice"), %4 contains SalesHeader."Shipping Advice"';
        PartialShipmentErr: Label 'Partial Shipment in ''Pack & Ship'' is not supported in versions before BC%1.', Comment = '%1 contains Major Version No.';
        ConfirmPartialShipmentTxt: Label 'Only %1 of %2 packages ready to ship. Do you want to proceed anyway?', Comment = '%1 contains the qty. of License Plates to Post, %2 contains the qty. of all License Plates on Shipment';
        NotAllLicensePlateTransferredErr: Label 'Not all License Plates were transferred to Shipping.';
        PartialSuccessErr: Label 'IMPORTANT - ACTION REQUIRED!\\Error occured after the Warehouse Shipment was posted.\\Please manually Update the Page.\\%1', Comment = '%1 show Last Error Message';
        NotFullyPickedErr: Label 'All Assembly to Order items in Warehouse Shipment %1 must be either fully picked or not picked at all.', Comment = '%1 is the Whse. shipment no.';
        TrackingNotSupportedErr: Label 'You must assign tracking for item %1 in Assembly Order %2', Comment = '%1 is the Item No., %2 is the Assembly Order No.';
        PartialShipmentATOErr: Label 'Partial Shipment in ''Pack & Ship'' is not supported because it contains Assembly To Order items.';
        LPBinDoNotMatchShipmentBinErr: Label 'License Plate %1 located in bin %2 and not the expected shipping bin %3.\\You must move %1 to %3.', Comment = '%1 is License Plate No., %2 is current Bin Code, %3 is Shipment Line Bin Code';

    //
    // PostAdhocRegistration
    //
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Adhoc Registr.", 'OnPostAdhocRegistrationOnCustomRegistrationType', '', true, true)]
    local procedure OnPostAdhocRegistrationOnCustomRegistrationType(_RegistrationType: Text; var _RequestValues: Record "MOB NS Request Element"; var _SuccessMessage: Text; var _IsHandled: Boolean)
    begin
        if _IsHandled then
            exit;

        if not MobPackFeatureMgt.IsEnabled() then
            exit;

        if _RegistrationType = 'PostPacking' then begin
            _SuccessMessage := PostPacking(_RegistrationType, _RequestValues);
            _IsHandled := true;
        end;
    end;

    //
    // Whse.-Post Shipment
    //

    // From BC19 is the event "Whse.-Post Shipment".OnBeforePostSourceSalesDocument() used to suppress commit
    // From BC25 is the event moved to "Sales Whse. Post Shipment"
    /* #if BC25+ */
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales Whse. Post Shipment", 'OnBeforePostSourceSalesDocument', '', false, false)]
    local procedure OnBeforePostSourceSalesDocument(var SalesPost: Codeunit "Sales-Post")
    begin
        if MobPackFeatureMgt.IsEnabled() and (MobSessionData.GetRegistrationType() = 'PostPacking') then
            SalesPost.SetSuppressCommit(true);
    end;
    /* #endif */
    /* #if BC19,BC20,BC21,BC22,BC23,BC24 ##
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Post Shipment", 'OnBeforePostSourceSalesDocument', '', false, false)]
    local procedure OnBeforePostSourceSalesDocument(var SalesPost: Codeunit "Sales-Post")
    begin
        if MobPackFeatureMgt.IsEnabled() and (MobSessionData.GetRegistrationType() = 'PostPacking') then
            SalesPost.SetSuppressCommit(true);
    end;
    /* #endif */

    // From BC19 is the event "Whse.-Post Shipment".OnBeforePostSourceTransferDocument() used to suppress commit
    // From BC25 is the event moved to "Transfer Whse. Post Shipment"
    /* #if BC25+ */
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Transfer Whse. Post Shipment", 'OnBeforePostSourceTransferDocument', '', false, false)]
    local procedure OnBeforePostSourceTransferDocument(var TransferPostShipment: Codeunit "TransferOrder-Post Shipment")
    begin
        if MobPackFeatureMgt.IsEnabled() and (MobSessionData.GetRegistrationType() = 'PostPacking') then
            TransferPostShipment.SetSuppressCommit(true);
    end;
    /* #endif */
    /* #if BC19,BC20,BC21,BC22,BC23,BC24 ##
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Post Shipment", 'OnBeforePostSourceTransferDocument', '', false, false)]
    local procedure OnBeforePostSourceTransferDocument(var TransferPostShipment: Codeunit "TransferOrder-Post Shipment")
    begin
        if MobPackFeatureMgt.IsEnabled() and (MobSessionData.GetRegistrationType() = 'PostPacking') then
            TransferPostShipment.SetSuppressCommit(true);
    end;
    /* #endif */

    // From BC19 is the event "Whse.-Post Shipment".OnBeforePostSourcePurchDocument() used to suppress commit
    // From BC25 is the event moved to "Purch. Whse. Post Shipment"
    /* #if BC25+ */
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch. Whse. Post Shipment", 'OnBeforePostSourcePurchDocument', '', false, false)]
    local procedure OnBeforePostSourcePurchDocument(var PurchPost: Codeunit "Purch.-Post")
    begin
        if MobPackFeatureMgt.IsEnabled() and (MobSessionData.GetRegistrationType() = 'PostPacking') then
            PurchPost.SetSuppressCommit(true);
    end;
    /* #endif */
    /* #if BC19,BC20,BC21,BC22,BC23,BC24 ##
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Post Shipment", 'OnBeforePostSourcePurchDocument', '', false, false)]
    local procedure OnBeforePostSourcePurchDocument(var PurchPost: Codeunit "Purch.-Post")
    begin
        if MobPackFeatureMgt.IsEnabled() and (MobSessionData.GetRegistrationType() = 'PostPacking') then
            PurchPost.SetSuppressCommit(true);
    end;
    /* #endif */

    // BC 14, 15 and 16 not supported. Enum and event not available. 
    /* #if BC17+ */
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Post Shipment", 'OnCreatePostedShptLineOnBeforePostWhseJnlLine', '', false, false)]
    local procedure SetPostedSourceDocOnLicensePlateContenet_OnCreatePostedShptLineOnBeforePostWhseJnlLine_WhsePostShipment(WarehouseShipmentLine: Record "Warehouse Shipment Line"; var PostedWhseShipmentLine: Record "Posted Whse. Shipment Line")
    begin
        if not MobPackFeatureMgt.IsEnabled() then
            exit;
        UpdateLicensePlateContentWithPostedSourceDocDetails(WarehouseShipmentLine, PostedWhseShipmentLine);
    end;
    /* #endif */

    // Redirect standard event OnAfterPostWhseShipment to new internal API event for more accessible "interface" (all neccessary events in MOB Register CU)
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Post Shipment", 'OnAfterPostWhseShipment', '', false, false)]
    local procedure OnAfterPostWhseShipment(var WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    var
        PackAPI: Codeunit "MOB Pack API";
    begin
        if not MobPackFeatureMgt.IsEnabled() then
            exit;

        UpdateLicensePlatesAfterPostShipment(WarehouseShipmentHeader);
        PackAPI.OnPostPackingOnAfterPostWarehouseShipment(WarehouseShipmentHeader);
    end;

    // Redirect standard event OnAfterCheckWhseShptLine to new internal API event for more accessible "interface" (all neccessary events in MOB Register CU)
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Post Shipment", 'OnAfterCheckWhseShptLines', '', false, false)]
    local procedure OnAfterCheckWhseShptLines(var WhseShptHeader: Record "Warehouse Shipment Header"; var WhseShptLine: Record "Warehouse Shipment Line")
    var
        PackAPI: Codeunit "MOB Pack API";
    begin
        if not MobPackFeatureMgt.IsEnabled() then
            exit;

        PackAPI.OnPostPackingOnBeforePostWarehouseShipment(WhseShptHeader, WhseShptLine);
    end;

    local procedure PostPacking(_RegistrationType: Text; var _RequestValues: Record "MOB NS Request Element"): Text
    var
        WhseShipmentHeader: Record "Warehouse Shipment Header";
        MobPackingStation: Record "MOB Packing Station";
        UntransferredLicensePlates: Record "MOB License Plate";
        AllUntransferredLicensePlates: Record "MOB License Plate";
        MobToolbox: Codeunit "MOB Toolbox";
        MobPackAPI: Codeunit "MOB Pack API";
        MobFeatureTelemetryWrapper: Codeunit "MOB Feature Telemetry Wrapper";
        WhseShipmentHeaderRecordId: RecordId;
        MobTelemetryEventId: Enum "MOB Telemetry Event ID";
        SuccessMessage: Text;
        RegistrationTypeTracking: Text;
        ValidPackagesCount: Integer;
        TotalPackagesCount: Integer;
        ATOLinesExist: Boolean;
        AppInfo: ModuleInfo;
    begin
        // Get Whse. Shipment Header from Context (context are single element from page, not all elements)
        Evaluate(WhseShipmentHeaderRecordId, _RequestValues.GetContextValue('ReferenceID', true));
        WhseShipmentHeader.Get(WhseShipmentHeaderRecordId);

        if not MobPackingStation.Get(WhseShipmentHeader."MOB Packing Station Code") then
            Clear(MobPackingStation);

        // Refresh All actice shipping providers, any avaliable 'connector Apps' should apply own Shipping Provider Id
        MobPackAPI.DiscoverShippingProviders();

        MobPackAPI.OnBeforePostPacking(_RegistrationType, MobPackingStation, _RequestValues);

        // Get All Untransfered License Plates
        FilterAllLicensePlatesForWarehouseShipment(WhseShipmentHeader."No.", AllUntransferredLicensePlates);

        // Get All Untransfered License Plates ready for Shipping
        FilterUntransferredLicensePlatesForWarehouseShipment(WhseShipmentHeader."No.", UntransferredLicensePlates);

        // Check for any additional requirements
        CheckUntransferredLicensePlates(UntransferredLicensePlates); // Used from Shipping Provider API

        ValidPackagesCount := UntransferredLicensePlates.Count();
        TotalPackagesCount := AllUntransferredLicensePlates.Count();

        // Check if ATO lines exist in the shipment
        ATOLinesExist := WhseShipmentHeader."MOB ATOLinesExist"();

        // Pre-check if required Shipping Advice is ok to avoid late posting Errors
        CheckShippingAdvice(WhseShipmentHeader, ValidPackagesCount, TotalPackagesCount);

        if (ValidPackagesCount < TotalPackagesCount) then begin
            if ATOLinesExist then
                Error(PartialShipmentATOErr);

            NavApp.GetCurrentModuleInfo(AppInfo);
            if AppInfo.AppVersion().Build() >= 190 then // Example on BC19 Build: x.x.190.xxx 
                MobToolbox.ErrorIfNotConfirm(_RequestValues, StrSubstNo(ConfirmPartialShipmentTxt, ValidPackagesCount, TotalPackagesCount))
            else
                Error(PartialShipmentErr, AppInfo.AppVersion().Major());
        end;

        PostPackages(WhseShipmentHeader."No.", UntransferredLicensePlates, _RequestValues, SuccessMessage, RegistrationTypeTracking);
        MobSessionData.SetRegistrationTypeTracking(RegistrationTypeTracking);

        // Verify all License Plates was transferred to any Shipping Provider.
        if not UntransferredLicensePlates.IsEmpty() then
            Error(NotAllLicensePlateTransferredErr);

        // Logging uptake telemetry for ATO usage in Pack & Ship
        if ATOLinesExist then
            MobFeatureTelemetryWrapper.LogUptakeUsed(MobTelemetryEventId::"Pack & Ship ATO Feature (MOB1015)");

        exit(SuccessMessage);
    end;

    // TODO: Move to internal scope
    procedure FilterUntransferredLicensePlatesForWarehouseShipment(_WhseShipmentNo: Code[20]; var _LicensePlate: Record "MOB License Plate")
    begin
        _LicensePlate.Reset();
        _LicensePlate.SetCurrentKey("Whse. Document Type", "Whse. Document No.");
        _LicensePlate.SetRange("Whse. Document Type", _LicensePlate."Whse. Document Type"::Shipment);
        _LicensePlate.SetRange("Whse. Document No.", _WhseShipmentNo);
        _LicensePlate.SetRange("Top-level", true);
        _LicensePlate.SetRange("Transferred to Shipping", false);
        _LicensePlate.SetRange("Shipping Status", _LicensePlate."Shipping Status"::Ready);
    end;

    local procedure FilterAllLicensePlatesForWarehouseShipment(_WhseShipmentNo: Code[20]; var _LicensePlate: Record "MOB License Plate")
    begin
        _LicensePlate.Reset();
        _LicensePlate.SetCurrentKey("Whse. Document Type", "Whse. Document No.");
        _LicensePlate.SetRange("Whse. Document Type", _LicensePlate."Whse. Document Type"::Shipment);
        _LicensePlate.SetRange("Whse. Document No.", _WhseShipmentNo);
        _LicensePlate.SetRange("Top-level", true);
        _LicensePlate.SetRange("Transferred to Shipping", false);
        _LicensePlate.SetFilter("Shipping Status", '<%1', _LicensePlate."Shipping Status"::Shipped);
    end;

    /// <summary>
    /// Check each LP:
    /// - Package Setup
    /// - LP Content Bin matches Shipment Line
    /// - Event call for Shipping Providers checks
    /// </summary>
    local procedure CheckUntransferredLicensePlates(var _UnhandledLicensePlates: Record "MOB License Plate")
    var
        MobShippingProvider: Record "MOB Shipping Provider";
        MobPackageType: Record "MOB Package Type";
        MobPackAPI: Codeunit "MOB Pack API";
    begin
        if _UnhandledLicensePlates.IsEmpty() then
            Error(CheckRegistrationsErr);

        _UnhandledLicensePlates.FindSet();
        repeat
            // Check if Shipping Provider from LP´s Package Type exists
            if MobPackageType.Get(_UnhandledLicensePlates."Package Type") and (MobPackageType."Shipping Provider Id" <> '') then
                MobShippingProvider.Get(MobPackageType."Shipping Provider Id");

            CheckLPBinMatchShipment(_UnhandledLicensePlates); // Ensure content is still on Shipment Bin

            MobPackAPI.OnPostPackingOnCheckUntransferredLicensePlate(_UnhandledLicensePlates); // Used from Shipping Provider API's to check setup tables etc.
        until _UnhandledLicensePlates.Next() = 0;
    end;

    /// <summary>
    /// Check LP is ready for shipment by comparing LP content bin to shipment line bin
    /// </summary>
    local procedure CheckLPBinMatchShipment(_LicensePlate: Record "MOB License Plate")
    var
        LicensePlateContent: Record "MOB License Plate Content";
        WhseShipmentLine: Record "Warehouse Shipment Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnPostAdhocRegistrationOnPostPacking_OnBeforeCheckLPBinMatchShipment(_LicensePlate, IsHandled);
        if IsHandled then
            exit;

        LicensePlateContent.SetRange("License Plate No.", _LicensePlate."No.");
        LicensePlateContent.SetRange(Type, LicensePlateContent.Type::Item);
        if LicensePlateContent.FindSet() then
            repeat
                if WhseShipmentLine.Get(LicensePlateContent."Whse. Document No.", LicensePlateContent."Whse. Document Line No.") then
                    if LicensePlateContent."Bin Code" <> WhseShipmentLine."Bin Code" then
                        Error(LPBinDoNotMatchShipmentBinErr, _LicensePlate."No.", _LicensePlate."Bin Code", WhseShipmentLine."Bin Code");
            until LicensePlateContent.Next() = 0;
    end;

    /// <summary>
    /// Pre-Check to avoid late posting errors based on Shipping Advice setup
    /// </summary>
    local procedure CheckShippingAdvice(_WhseShipmentHeader: Record "Warehouse Shipment Header"; _ValidPackagesCount: Integer; _TotalPackagesCount: Integer)
    var
        SalesHeader: Record "Sales Header";
        WhseShipmentLine: Record "Warehouse Shipment Line";
    begin
        if (_WhseShipmentHeader."Document Status" in [_WhseShipmentHeader."Document Status"::"Completely Picked", _WhseShipmentHeader."Document Status"::"Completely Shipped"]) or ReadyToBeShipped(_WhseShipmentHeader) and
           (_ValidPackagesCount = _TotalPackagesCount)
        then
            exit;

        WhseShipmentLine.SetRange("No.", _WhseShipmentHeader."No.");
        WhseShipmentLine.SetRange("Source Document", WhseShipmentLine."Source Document"::"Sales Order");
        if WhseShipmentLine.FindSet() then
            repeat
                SalesHeader.Get(SalesHeader."Document Type"::Order, WhseShipmentLine."Source No.");
                if SalesHeader."Shipping Advice" = SalesHeader."Shipping Advice"::Complete then
                    Error(ShippingAdviceErr, SalesHeader."Document Type", SalesHeader."No.", SalesHeader.FieldCaption("Shipping Advice"), SalesHeader."Shipping Advice");
            until WhseShipmentLine.Next() = 0;
    end;

    /// <summary>
    /// Checks if the warehouse shipment is ready to be shipped with PostPacking
    /// </summary>    
    internal procedure ReadyToBeShipped(_WhseShipmentHeader: Record "Warehouse Shipment Header"): Boolean
    var
        WhseShipmentLine: Record "Warehouse Shipment Line";
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        ATOLink: Record "Assemble-to-Order Link";
        IsReadyToBeShipped: Boolean;
        IsHandled: Boolean;
    begin
        OnPostAdhocRegistrationOnPostPacking_OnBeforeCheckReadyToBeShipped(_WhseShipmentHeader, IsReadyToBeShipped, IsHandled);
        if IsHandled then
            exit(IsReadyToBeShipped);

        if not _WhseShipmentHeader."MOB ATOLinesExist"() then begin
            _WhseShipmentHeader.CalcFields("Completely Picked");
            exit(_WhseShipmentHeader."Completely Picked");
        end;

        //only ATO lines
        WhseShipmentLine.SetRange("No.", _WhseShipmentHeader."No.");
        WhseShipmentLine.SetRange("Assemble to Order", true);
        if WhseShipmentLine.FindSet() then
            repeat
                ATOLink.SetRange("Assembly Document Type", ATOLink."Assembly Document Type"::Order);
                ATOLink.SetRange("Document No.", WhseShipmentLine."Source No.");
                if ATOLink.FindSet() then
                    repeat
                        if AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, ATOLink."Assembly Document No.") then
                            if not AssemblyHeader.CompletelyPicked() then begin
                                AssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type");
                                AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
                                AssemblyLine.SetRange(Type, AssemblyLine.Type::Item);
                                AssemblyLine.SetFilter("Qty. Picked (Base)", '<>%1', 0);
                                // Prevent shipping if one or more lines are partly picked
                                if not AssemblyLine.IsEmpty() then
                                    exit(false);
                            end;
                    until ATOLink.Next() = 0;
            until WhseShipmentLine.Next() = 0;
        exit(true);
    end;

    //
    // Package Shipping
    //

    local procedure PostPackages(_ShipmentNo: Code[20]; var _UntransferredLicensePlates: Record "MOB License Plate"; var _RequestValues: Record "MOB NS Request Element"; var _SuccessMessage: Text; var _ReturnRegistrationTypeTracking: Text)
    var
        DummyMobDocQueue: Record "MOB Document Queue";
        Location: Record Location;
        WhseShipmentHeader: Record "Warehouse Shipment Header";
        WhseShipmentLine: Record "Warehouse Shipment Line";
        TempReservationEntryLog: Record "Reservation Entry" temporary;
        TempReservationEntry: Record "Reservation Entry" temporary;
        MobSetup: Record "MOB Setup";
        MobReportPrintSetup: Record "MOB Report Print Setup";
        MobLicensePlate: Record "MOB License Plate";
        WhsePostShipment: Codeunit "Whse.-Post Shipment";
        MobSyncItemTracking: Codeunit "MOB Sync. Item Tracking";
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
        PostingRunSuccessful: Boolean;
        PostedDocExists: Boolean;
        IsHandled: Boolean;
    begin
        MobWmsToolbox.CheckWhseSetupShipment();

        // Disable the locktimeout to prevent timeout messages on the mobile device
        LockTimeout(false);

        // Lock the tables to work on
        IsHandled := false;
        OnPostAdhocRegistrationOnPostPacking_OnBeforeLockTables(WhseShipmentHeader, WhseShipmentLine, MobLicensePlate, IsHandled);
        if not IsHandled then begin
            WhseShipmentHeader.LockTable();
            WhseShipmentLine.LockTable();
            MobLicensePlate.LockTable();
        end;

        // Turn on commit protection to prevent unintentional committing data
        DummyMobDocQueue.Consistent(false);

        MobSessionData.SetRegistrationTypeTracking(StrSubstNo('%1: %2', WhseShipmentHeader.TableCaption(), _ShipmentNo));

        MobSetup.Get();
        WhseShipmentHeader.Get(_ShipmentNo);    // Only this one shipment is posted despite multiple could exist (future improvement)

        // Check Locations Warehouse Setup
        Location.Get(WhseShipmentHeader."Location Code");
        Location.TestField("Require Shipment", true);

        // Set MOB Posting Message Id
        WhseShipmentHeader."MOB Posting MessageId" := MobSessionData.GetPostingMessageId();

        // Set Posting date
        WhseShipmentHeader.Validate("Posting Date", WorkDate());
        WhseShipmentHeader."Shipment Date" := WorkDate();

        // Event        
        OnPostAdhocRegistrationOnPostPacking_OnBeforeModifyWarehouseShipmentHeader(_RequestValues, WhseShipmentHeader);

        WhseShipmentHeader.Modify(true);

        // -- Prepare WhseShipmentLines to be updated (not every WhseShipmentLine may have an associated MobileWmsRegistraion in this run)
        Clear(WhseShipmentLine);
        WhseShipmentLine.SetRange("No.", WhseShipmentHeader."No.");

        // Update lines shipment date
        WhseShipmentLine.ModifyAll("Shipment Date", WorkDate());

        // Save the original reservation entrie in case we need to revert (if the posting fails)
        MobSyncItemTracking.SaveOriginalReservationEntriesForWhseShipmentLines(WhseShipmentLine, TempReservationEntryLog);

        // Reset lines qty. to ship
        WhseShipmentLine.SetFilter("Qty. to Ship", '>0');
        WhseShipmentLine.ModifyAll("Qty. to Ship", 0, true);
        WhseShipmentLine.SetRange("Qty. to Ship");

        // Loop through untransferred license plates and set WhseShipmentLine."Qty. to Ship" to the registered qty's
        // Update Shipment Lines using a non-var parameter LicensePlate (function is used recursively internally)
        if _UntransferredLicensePlates.FindSet() then
            repeat
                MobLicensePlate.Get(_UntransferredLicensePlates."No.");
                UpdateShipmentLinesFromLicensePlate(MobLicensePlate, TempReservationEntry);
            until _UntransferredLicensePlates.Next() = 0;

        // Print Shipment
        if MobReportPrintSetup.PrintShipmentOnPostEnabled() then
            WhsePostShipment.SetPrint(true);

        // Event OnBeforePostShipment
        IsHandled := false;
        OnPostAdhocRegistrationOnPostPacking_OnBeforeRunWhsePostShipment(WhseShipmentLine, WhsePostShipment, IsHandled);

        // Turn off the commit protection and run post
        DummyMobDocQueue.Consistent(true);
        Commit();

        if not MobSyncItemTracking.Run(TempReservationEntry) then begin
            // The created reservation entries might have been committed
            // If the synchronization fails for some reason we need to clean up the created reservation entries
            MobSyncItemTracking.RevertToOriginalReservationEntriesForWhseShipmentLines(WhseShipmentLine, TempReservationEntryLog);
            Commit();
            UpdateIncomingWarehouseShipment(WhseShipmentHeader);
            Commit();   // Separate commit to prevent error in UpdateIncomingWarehouseShipment from preventing Reservation Entries being rollback
            MobSessionData.SetPreservedLastErrorCallStack();
            Error(GetLastErrorText());
        end;

        if IsHandled then begin
            UpdateIncomingWarehouseShipment(WhseShipmentHeader); // Remove "MOB Posting MessageId" from WhseShipmentHeader
            exit;
        end;

        // SetSuppressCommit not working 100% in versions before BC20
        //
        // In BC16,BC17,BC18 it is not supported.
        //
        // In BC19 we also need to supress commit directly in the Sales + Transfer Posting CU´s
        // See functions: OnBeforePostSourceSalesDocument + OnBeforePostSourceTransferDocument + OnBeforePostSourcePurchDocument
        //
        // In BC20 it´s automatically transfered from Whse. Post to the Sales + Tramsfer CU´s

        // SetSuppressCommit supported from BC19
        /* #if BC19+ */
        WhsePostShipment.SetSuppressCommit(true);
        /* #endif */

        // Post Whse Shipment, then manually update "Tote Handled" accordingly to registrations that exists at the time of a partial posting        
        PostingRunSuccessful := WhsePostShipment.Run(WhseShipmentLine);

        if not PostingRunSuccessful then
            PostedDocExists := PostedWhseShipmentHeaderExists(WhseShipmentHeader);

        if PostingRunSuccessful or PostedDocExists then begin
            _ReturnRegistrationTypeTracking := MobSessionData.GetRegistrationTypeTracking();

            // Regardless of "PostSuccess"-error the shipment posting may have successfully posted documents that was committed prior to the error. 
            // Always commiting to prevent error in CreateInboundTransferWarehouseDoc from rolling back that update.
            UpdateIncomingWarehouseShipment(WhseShipmentHeader);
            Commit();

            // If Shipment is based on Transfer Order(s) then
            // create also the Inbound Receipts/Invt.Put-aways on the Transfer-to Code destination
            CreateInboundWarehouseDocs(WhseShipmentLine);
            Commit();

            if not PostingRunSuccessful and PostedDocExists then begin
                MobSessionData.SetPreservedLastErrorCallStack();
                Error(PartialSuccessErr, GetLastErrorText());
            end;
        end else begin
            // The created reservation entries have been committed
            // If the posting fails for some reason we need to clean up the created reservation entries and MobWmsRegistrations
            _SuccessMessage := GetLastErrorText();
            MobSessionData.SetPreservedLastErrorCallStack();
            MobSyncItemTracking.RevertToOriginalReservationEntriesForWhseShipmentLines(WhseShipmentLine, TempReservationEntryLog);
            Commit();
            UpdateIncomingWarehouseShipment(WhseShipmentHeader);
            Commit();   // Separate commit to prevent error in UpdateIncomingWarehouseShipment from preventing Reservation Entries being rollback
            Error(_SuccessMessage);
        end;
    end;

    local procedure UpdateShipmentLinesFromLicensePlate(_LicensePlate: Record "MOB License Plate"; var _TempReservationEntry: Record "Reservation Entry")  // Used recursively, must NOT be a var parameter
    var
        WhseShipmentHeader: Record "Warehouse Shipment Header";
        WhseShipmentLine: Record "Warehouse Shipment Line";
        MobSetup: Record "MOB Setup";
        MobLicensePlateContent: Record "MOB License Plate Content";
        ChildLicensePlate: Record "MOB License Plate";
        MobTrackingSetup: Record "MOB Tracking Setup";
        AssemblyHeader: Record "Assembly Header";
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
        MobWmsAssembly: Codeunit "MOB WMS Assembly";
        Qty: Decimal;
        ExpDateRequired: Boolean;
    begin
        MobSetup.Get();

        _LicensePlate.TestField("Whse. Document Type", _LicensePlate."Whse. Document Type"::Shipment);
        _LicensePlate.TestField("Whse. Document No.");

        if WhseShipmentHeader.Get(_LicensePlate."Whse. Document No.") and WhseShipmentHeader."MOB ATOLinesExist"() then
            if not ReadyToBeShipped(WhseShipmentHeader) then
                Error(NotFullyPickedErr, WhseShipmentHeader."No.");

        MobLicensePlateContent.Reset();
        MobLicensePlateContent.SetRange("License Plate No.", _LicensePlate."No.");
        MobLicensePlateContent.SetFilter("No.", '<>%1', '');

        if MobLicensePlateContent.FindSet() then
            repeat
                case MobLicensePlateContent.Type of
                    MobLicensePlateContent.Type::"License Plate":
                        begin
                            ChildLicensePlate.Get(MobLicensePlateContent."No.");
                            ChildLicensePlate.TestField("Whse. Document Type", _LicensePlate."Whse. Document Type");
                            ChildLicensePlate.TestField("Whse. Document No.", _LicensePlate."Whse. Document No.");
                            UpdateShipmentLinesFromLicensePlate(ChildLicensePlate, _TempReservationEntry);
                        end;
                    MobLicensePlateContent.Type::Item:
                        begin
                            // Read associated shipment line
                            MobLicensePlateContent.TestField("Whse. Document Type", _LicensePlate."Whse. Document Type");
                            MobLicensePlateContent.TestField("Whse. Document No.", _LicensePlate."Whse. Document No.");
                            MobLicensePlateContent.TestField("Whse. Document Line No.");
                            WhseShipmentLine.Get(MobLicensePlateContent."Whse. Document No.", MobLicensePlateContent."Whse. Document Line No.");

                            // If assembly to order then fill Qty. to ship with Qty. outstanding.
                            if MobLicensePlateContent."Source Document" = MobLicensePlateContent."Source Document"::"Assembly Consumption" then begin
                                if WhseShipmentLine."Qty. to Ship" <> WhseShipmentLine."Qty. Outstanding" then begin
                                    MobTrackingSetup.DetermineItemTrackingRequiredByWhseShipmentLine(WhseShipmentLine, ExpDateRequired);
                                    AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, MobLicensePlateContent."Source No.");

                                    // Tracking must be preassigned for the Assembly Header in Business Central, not supported from Mobile WMS
                                    if MobTrackingSetup.TrackingRequired() and not MobWmsAssembly.RetrieveAssemblyHeaderItemTracking(AssemblyHeader) then
                                        Error(TrackingNotSupportedErr, AssemblyHeader."Item No.", AssemblyHeader."No.");

                                    WhseShipmentLine.Validate("Qty. to Ship", WhseShipmentLine."Qty. Outstanding");
                                end;
                            end else begin
                                Qty := MobWmsToolbox.CalcQtyNewUOMRounded(WhseShipmentLine."Item No.", MobLicensePlateContent.Quantity, MobLicensePlateContent."Unit Of Measure Code", WhseShipmentLine."Unit of Measure Code");
                                WhseShipmentLine.Validate("Qty. to Ship", WhseShipmentLine."Qty. to Ship" + Qty);
                                CreateTempReservEntryForWhseShipmentLine(WhseShipmentLine, MobLicensePlateContent, _TempReservationEntry);
                            end;

                            WhseShipmentLine.Modify();
                        end;
                end;

            until MobLicensePlateContent.Next() = 0;
    end;

    local procedure UpdateIncomingWarehouseShipment(var _WhseShipmentHeader: Record "Warehouse Shipment Header")
    begin
        if not _WhseShipmentHeader.Get(_WhseShipmentHeader."No.") then
            exit;

        _WhseShipmentHeader.LockTable();
        _WhseShipmentHeader.Get(_WhseShipmentHeader."No.");
        Clear(_WhseShipmentHeader."MOB Posting MessageId");
        _WhseShipmentHeader.Modify();
    end;

    local procedure PostedWhseShipmentHeaderExists(_WhseShipmentHeader: Record "Warehouse Shipment Header"): Boolean
    var
        PostedWhseShipmentHeader: Record "Posted Whse. Shipment Header";
    begin
        PostedWhseShipmentHeader.SetRange("Whse. Shipment No.", _WhseShipmentHeader."No.");
        PostedWhseShipmentHeader.SetRange("MOB MessageId", _WhseShipmentHeader."MOB Posting MessageId");
        exit(not PostedWhseShipmentHeader.IsEmpty());
    end;

    /// <summary>
    /// Identify each Transfer Order(s) of the Posted Shipment
    /// Create Inbound Receipts/Invt.Put-aways on the Transfer-to Code destination
    /// </summary>
    local procedure CreateInboundWarehouseDocs(var _WhseShipmentLine: Record "Warehouse Shipment Line")
    var
        PostedWhseShipmentHeader: Record "Posted Whse. Shipment Header";
        PostedWhseShipmentLine: Record "Posted Whse. Shipment Line";
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
    begin
        PostedWhseShipmentHeader.SetCurrentKey("Whse. Shipment No.");
        PostedWhseShipmentHeader.SetRange("Whse. Shipment No.", _WhseShipmentLine."No.");

        if PostedWhseShipmentHeader.FindLast() then begin
            PostedWhseShipmentLine.SetCurrentKey("Source Type", "Source Subtype", "Source No.", "Source Line No.");
            PostedWhseShipmentLine.SetRange("Source Type", Database::"Transfer Line");
            PostedWhseShipmentLine.SetRange("Source Subtype", 0);
            PostedWhseShipmentLine.SetRange("Source Document", PostedWhseShipmentLine."Source Document"::"Outbound Transfer");
            PostedWhseShipmentLine.SetRange("No.", PostedWhseShipmentHeader."No.");
            if PostedWhseShipmentLine.FindSet() then
                repeat
                    PostedWhseShipmentLine.SetRange("Source No.", PostedWhseShipmentLine."Source No.");
                    MobWmsToolbox.CreateInboundTransferWarehouseDoc(PostedWhseShipmentLine."Source No.");

                    // Run only once per Source document
                    PostedWhseShipmentLine.FindLast(); // Make Repeat go to next Source Document
                    PostedWhseShipmentLine.SetRange("Source No.");
                until PostedWhseShipmentLine.Next() = 0;
        end;
    end;

    // TODO Refactor to 'internal'
    procedure CreateTempReservEntryForWhseShipmentLine(_WhseShipmentLine: Record "Warehouse Shipment Line"; _LicensePlateContent: Record "MOB License Plate Content"; var _TempReservEntry: Record "Reservation Entry")
    var
        ATOSalesLine: Record "Sales Line";
        AsmHeader: Record "Assembly Header";
        MobTrackingSetup: Record "MOB Tracking Setup";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        MobToolbox: Codeunit "MOB Toolbox";
        SignFactor: Integer;
        ToRowID: Text;
        IsATOPosting: Boolean;
    begin
        // Used for carrying the item tracking from the registration to the Warehouse Shipment line
        _LicensePlateContent.CopyTrackingToMobTrackingSetup(MobTrackingSetup);
        if not MobTrackingSetup.TrackingExists() then
            exit;

        IsATOPosting := (_WhseShipmentLine."Source Type" = Database::"Sales Line") and _WhseShipmentLine."Assemble to Order";

        if IsATOPosting then begin
            ATOSalesLine.Get(_WhseShipmentLine."Source Subtype", _WhseShipmentLine."Source No.", _WhseShipmentLine."Source Line No.");
            ATOSalesLine.AsmToOrderExists(AsmHeader);
            ToRowID :=
                ItemTrackingMgt.ComposeRowID(
                    Database::"Assembly Header", MobToolbox.AsInteger(AsmHeader."Document Type"), AsmHeader."No.", '', 0, 0);
        end else begin
            _WhseShipmentLine.Reset();
            _WhseShipmentLine.SetSourceFilter(_WhseShipmentLine."Source Type", _WhseShipmentLine."Source Subtype", _WhseShipmentLine."Source No.", _WhseShipmentLine."Source Line No.", true);
            ToRowID :=
                ItemTrackingMgt.ComposeRowID(
                    _WhseShipmentLine."Source Type", _WhseShipmentLine."Source Subtype", _WhseShipmentLine."Source No.", '', 0, _WhseShipmentLine."Source Line No.");
        end;

        _TempReservEntry.SetPointer(ToRowID);
        _TempReservEntry.SetItemData(
            _WhseShipmentLine."Item No.",
            _WhseShipmentLine.Description,
            _WhseShipmentLine."Location Code",
            _WhseShipmentLine."Variant Code",
            _WhseShipmentLine."Qty. per Unit of Measure");

        SignFactor := -1;
        InsertTempReservEntryFromLicensePlateContent(_LicensePlateContent, _TempReservEntry, SignFactor);
    end;

    local procedure InsertTempReservEntryFromLicensePlateContent(var _LicensePlateContent: Record "MOB License Plate Content"; var _TempReservEntry: Record "Reservation Entry"; _SignFactor: Integer)
    begin
        _TempReservEntry."Entry No." += 1;
        _TempReservEntry.Positive := _SignFactor > 0;
        _TempReservEntry."Quantity (Base)" := _LicensePlateContent."Quantity (Base)" * _SignFactor;
        _TempReservEntry.Quantity := _LicensePlateContent.Quantity * _SignFactor;
        _TempReservEntry."Qty. to Handle (Base)" := _LicensePlateContent."Quantity (Base)" * _SignFactor;
        _TempReservEntry."Qty. to Invoice (Base)" := _LicensePlateContent."Quantity (Base)" * _SignFactor;

        _LicensePlateContent.CopyTrackingToReservEntry(_TempReservEntry);

        // TODO: _TempReservEntry."Expiration Date" := _LicensePlateContent."Expiration Date";        
        _TempReservEntry.Insert();
    end;

    // Called from  OnCreatePostedShptLineOnBeforePostWhseJnlLine eventsubscriber
    // BC 14, 15 and 16 not supported. Enum and event not available. 
    /* #if BC17+ */
    local procedure UpdateLicensePlateContentWithPostedSourceDocDetails(WarehouseShipmentLine: Record "Warehouse Shipment Line"; var PostedWhseShipmentLine: Record "Posted Whse. Shipment Line")
    var
        MobLicensePlateContent: Record "MOB License Plate Content";
    begin
        MobLicensePlateContent.SetRange("Whse. Document Type", MobLicensePlateContent."Whse. Document Type"::Shipment);
        MobLicensePlateContent.SetRange("Whse. Document No.", WarehouseShipmentLine."No.");
        MobLicensePlateContent.SetRange("Posted Source No.", ''); // Only unposted lines
        if MobLicensePlateContent.FindSet(true) then
            repeat
                MobLicensePlateContent.Validate("Posted Source Document", PostedWhseShipmentLine."Posted Source Document");
                MobLicensePlateContent.Validate("Posted Source No.", PostedWhseShipmentLine."Posted Source No.");
                MobLicensePlateContent.Validate("Posted Source Line No.", PostedWhseShipmentLine."Source Line No.");
                MobLicensePlateContent.Modify(true);
            until MobLicensePlateContent.Next() = 0;
    end;
    /* #endif */

    // Called from OnAfterPostWhseShipment eventsubscriber
    local procedure UpdateLicensePlatesAfterPostShipment(_WhseShipmentHeader: Record "Warehouse Shipment Header")
    var
        MobLicensePlate: Record "MOB License Plate";
        MobLicensePlateToUpdate: Record "MOB License Plate";
    begin
        _WhseShipmentHeader.TestField("Shipping No.");

        MobLicensePlate.SetCurrentKey("Whse. Document Type", "Whse. Document No.");
        MobLicensePlate.SetRange("Whse. Document Type", MobLicensePlate."Whse. Document Type"::Shipment);
        MobLicensePlate.SetRange("Whse. Document No.", _WhseShipmentHeader."No.");
        MobLicensePlate.SetRange("Top-level", true);
        MobLicensePlate.SetRange("Transferred to Shipping", true);
        MobLicensePlate.SetRange("Shipping Status", MobLicensePlate."Shipping Status"::Ready);
        if MobLicensePlate.FindSet() then
            repeat
                MobLicensePlateToUpdate.Get(MobLicensePlate."No.");
                MobLicensePlateToUpdate.Validate("Whse. Document No.", _WhseShipmentHeader."Shipping No.");    // Will update current license plate content and all child license plates as well
                MobLicensePlateToUpdate.Validate("Shipping Status", MobLicensePlateToUpdate."Shipping Status"::Shipped);
                MobLicensePlateToUpdate.Modify(true);
            until MobLicensePlate.Next() = 0;

        OnPostAdhocRegistrationOnPostPacking_OnAfterPostWhseShipment(_WhseShipmentHeader);
    end;

    /// <summary>
    /// Only used from 'pack - ShipIT' and 'pack - LogTrade' connectors, procedure moved to "MOB Pack API"
    /// </summary>
    // TODO [Obsolete('Use "MOB Pack API".HasUntransferredLicensePlatesForWarehouseShipment  (planned for removal 04/2024)', 'MOB5.41')]    
    procedure HasUntransferredLicensePlatesForWarehouseShipment(_WhseShipmentNo: Code[20]): Boolean
    var
        MobPackAPI: Codeunit "MOB Pack API";
    begin
        exit(MobPackAPI.HasUntransferredLicensePlatesForWarehouseShipment(_WhseShipmentNo));
    end;

    //
    // IntegrationEvents
    //

    [IntegrationEvent(false, false)]
    local procedure OnPostAdhocRegistrationOnPostPacking_OnBeforeRunWhsePostShipment(var _WhseShipmentLine: Record "Warehouse Shipment Line"; var _WhsePostShipment: Codeunit "Whse.-Post Shipment"; var _IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostAdhocRegistrationOnPostPacking_OnBeforeModifyWarehouseShipmentHeader(var _RequestValues: Record "MOB NS Request Element"; var _WhseShipmentHeader: Record "Warehouse Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostAdhocRegistrationOnPostPacking_OnAfterPostWhseShipment(var _WhseShipmentHeader: Record "Warehouse Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostAdhocRegistrationOnPostPacking_OnBeforeLockTables(var _WhseShipmentHeader: Record "Warehouse Shipment Header"; var _WhseShipmentLine: Record "Warehouse Shipment Line"; var _MobLicensePlate: Record "MOB License Plate"; var _IsHandled: Boolean)
    begin
    end;

    /// <summary>
    ///  PostPacking requires the WhseShipmentHeader to be completely picked before it can be shipped.
    ///  This event enables the possibility to override this behavior, but it will often requre additional handling.
    /// </summary>
    [IntegrationEvent(false, false)]
    internal procedure OnPostAdhocRegistrationOnPostPacking_OnBeforeCheckReadyToBeShipped(var _WhseShipmentHeader: Record "Warehouse Shipment Header"; var _ReadyToBeShipped: Boolean; var _IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostAdhocRegistrationOnPostPacking_OnBeforeCheckLPBinMatchShipment(var _LicensePlate: Record "MOB License Plate"; var _IsHandled: Boolean)
    begin
    end;
}
