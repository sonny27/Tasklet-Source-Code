codeunit 81387 "MOB WMS Language"
{
    Access = Public;
    trigger OnRun()
    begin
    end;

    var
        MobTrackingSetup: Record "MOB Tracking Setup";
        MobToolbox: Codeunit "MOB Toolbox";
        LanguageMustExistErr: Label 'Language must exist';

        // Mobile Messages Labels
        Assigned_user_idTxt: Label 'Assigned User ID';
        Whse_act_not_uniqueTxt: Label 'The order number %1 is not unique. This can happen if the same numbers are used by several warehouse activities.', Comment = '%1 is Order No.';
        Xml_unknown_elementTxt: Label 'Unknown element: %1', Comment = '%1 is Element';
        Unknown_serialTxt: Label 'The serial number %1 does not exist.%2', Comment = '%1 is Item. %2 is Item Variant text';
        Recv_known_serialTxt: Label 'The serial number %1 already exist. It cannot be received again. Delete it from the registrations and try again.', Comment = '%1 is Serial';
        Unknown_lotTxt: Label 'The lot number %1 does not exist.%2', Comment = '%1 is Lot. %2 is Item Variant text';
        XY_DoesNotExist_ZTxt: Label 'The %1 %2 does not exist.%3', Comment = '%1, %2 and %3 is generic';
        Tracking_ReservedTxt: Label 'The specified tracking is reserved for something else at %1', Comment = '%1 is text explaining what tracking is reserved for';
        Split_line_not_foundTxt: Label 'The split line was not found.';
        Place_line_not_foundTxt: Label 'The matching place line could not be found for order line %1', Comment = '%1 is Line';
        Enter_delv_noteTxt: Label 'Enter delivery note number';
        Delv_note_label_textTxt: Label 'Del. Note:';
        Post_successTxt: Label 'Order posted successfully.';
        Not_availableTxt: Label 'Not available';
        Reg_trans_successTxt: Label 'The registrations were transferred successfully.';
        Order_locked_byTxt: Label 'The order is locked by: %1', Comment = '%1 is User';
        Lock_successTxt: Label 'The order was locked successfully.';
        Unlock_successTxt: Label 'The order was unlocked successfully.';
        BinTxt: Label 'Bin';
        ItemTxt: Label 'Item';
        Select_binTxt: Label 'Select Bin';
        DefaultTxt: Label 'Default';
        Serial_no_labelTxt: Label 'Serial No.';
        Lot_no_labelTxt: Label 'Lot No.';
        Package_no_labelTxt: Label 'Package No.';
        Scan_XTxt: Label 'Scan %1', Comment = '%1 is generic';
        Enter_exp_dateTxt: Label 'Enter Expiration Date';
        Exp_date_labelTxt: Label 'Exp. Date';
        Enter_qtyTxt: Label 'Enter Quantity';
        Qty_labelTxt: Label 'Qty';
        Uom_labelTxt: Label 'UoM';
        From_bin_labelTxt: Label 'From Bin';
        Enter_to_binTxt: Label 'Enter To Bin';
        Scan_to_binTxt: Label 'Scan To Bin';
        To_bin_labelTxt: Label 'To Bin';
        Unpl_move_completedTxt: Label 'Unplanned Move for %1 completed.', Comment = '%1 is Item';
        Unpl_count_serial_not_allowedTxt: Label 'Serial Controlled Items cannot be counted using the Unplanned Count.';
        Unpl_count_nowhse_not_allowedTxt: Label 'Unplanned Count without Warehouse Tracking is not supported.';
        Unpl_count_no_loc_not_allowedTxt: Label 'Unplanned Count without Location is not supported.';
        Enter_counted_qtyTxt: Label 'Enter Qty. Counted';
        Unpl_count_completedTxt: Label 'Unplanned Count for %1 completed.', Comment = '%1 is Item';
        LocationTxt: Label 'Location';
        New_locationTxt: Label 'New Location';
        Exp_recv_dateTxt: Label 'Exp. Recv. Date';
        ReasonTxt: Label 'Reason';
        Adjust_qty_completedTxt: Label 'Adjust quantity for %1 completed.', Comment = '%1 is Item';
        QuantityTxt: Label 'Quantity';
        Scan_barcodeTxt: Label 'Scan Bar Code';
        Item_barcodeTxt: Label 'Bar Code';
        Item_crossref_completedTxt: Label 'Item Cross Ref. for %1 created.', Comment = '%1 is Item';
        Item_reference_createdTxt: Label 'Item Reference for %1 created.', Comment = '%1 is Item';
        Item_descriptionTxt: Label 'Description';
        Item_categoryTxt: Label 'Category';
        Multi_bins_not_allowedTxt: Label 'You are not allowed to register multiple bins.';
        Recv_multi_bins_not_allowedTxt: Label 'You are not allowed to register multiple bins on receive orders.';
        Unknown_item_noTxt: Label 'Item No. %1 does not exist.', Comment = '%1 is Item';
        Enter_qty_to_adjustTxt: Label 'Enter Quantity to remove';
        Enter_reasonTxt: Label 'Enter Reason';
        Insufficient_stock_qtyTxt: Label 'Quantity on Bin is only %1 %2.', Comment = '%1 is Item. %2 is Unit';
        Item_noTxt: Label 'Item No.';
        Yes_noTxt: Label 'Yes;No';
        YesTxt: Label 'Yes';
        NoTxt: Label 'No';
        SignatureTxt: Label 'Signature';
        Signature_labelTxt: Label 'Please sign here.';
        Wrong_expiration_dateTxt: Label 'The Expiration Date must be %1 for Lot No. %2', Comment = '%1 is Date. %2 is Lot';
        No_qty_on_binTxt: Label 'No stock Qty. on Bin: %1', Comment = '%1 is Bin';
        Sales_order_labelTxt: Label 'Sales Order';
        Inbound_transfer_labelTxt: Label 'Inbound Transfer';
        Outbound_transfer_labelTxt: Label 'Outbound Transfer';
        Shipment_dateTxt: Label 'Shipment Date: %1', Comment = '%1 is Date';
        Expected_receipt_dateTxt: Label 'Expected Receipt Date: %1', Comment = '%1 is Date';
        ToTxt: Label 'To: %1', Comment = '%1 is To';
        FromTxt: Label 'From: %1', Comment = '%1 is From';
        No_of_linesTxt: Label 'No. of lines: %1', Comment = '%1 is Lines';
        Handheld_unplanned_moveTxt: Label 'Items moved using the Mobile Unplanned Move';
        Handheld_unplanned_countTxt: Label 'Phys. Invt. Journal using Mobile Unplanned Count';
        Handheld_adjust_quantityTxt: Label 'Items adjusted using the Mobile adjust quantity';
        HandheldTxt: Label 'Handheld';
        PrinterTxt: Label 'Printer';
        PrintersTxt: Label 'printers';
        PrinterOrPrintersTxt: Label 'printer(s)';
        NoprintersetupTxt: Label 'No mobile printers are set up';
        Print_qtyTxt: Label 'Qty. to print';
        Print_responseTxt: Label 'Print OK';
        Print_failedTxt: Label 'Print failed';
        ReprintTxt: Label 'Reprint';
        Take_line_not_foundTxt: Label 'The matching take line could not be found for order line %1', Comment = '%1 is Line';
        Enter_uomTxt: Label 'Enter Unit of Measure';
        Enter_uom_helpTxt: Label 'Unit of Measure';
        Batch_nameTxt: Label 'Jnl. Name';
        Add_lineTxt: Label 'Add Line?';
        Add_count_lineTxt: Label 'Add Count Line?';
        LineHasBeenAddedForXTxt: Label 'A line has been added for %1.', Comment = '%1 is generic';
        Count_line_existsTxt: Label 'The Item already exists in the Journal';
        Bulk_move_completedTxt: Label 'Bulk Move completed.';
        Whse_trkg_neededTxt: Label 'Bulk Move Without Whse. Tracking enabled is not supported. Item No.: %1', Comment = '%1 is Item';
        Nothing_to_registerTxt: Label 'Nothing to Register';
        Variant_labelTxt: Label 'Variant';
        Enter_variantTxt: Label 'Enter Variant Code';
        Enter_variant_helpTxt: Label 'Variant Code';
        Po_numberTxt: Label 'PO Number';
        Data_not_foundTxt: Label 'Data not found';
        Available_nowTxt: Label 'Available now:';
        Filter_allTxt: Label 'All';
        Filter_mine_unassignedTxt: Label 'Mine & Unassigned';
        Filter_only_mineTxt: Label 'Only my orders';
        Enter_weightTxt: Label 'Enter the weight of this unit of measure';
        Enter_heightTxt: Label 'Enter the height of this unit of measure';
        Enter_widthTxt: Label 'Enter the width of this unit of measure';
        Enter_cubageTxt: Label 'Enter the cubage for this unit of measure';
        Enter_lengthTxt: Label 'Enter the length of this unit of measure';
        Weight_labelTxt: Label 'Weight';
        Height_labelTxt: Label 'Height';
        Width_labelTxt: Label 'Width';
        Cubage_labelTxt: Label 'Cubage';
        Length_labelTxt: Label 'Length';
        Enter_qty_per_uomTxt: Label 'Enter quantity per unit of measure';
        Return_order_labelTxt: Label 'Return Order';
        Shipmt_dateTxt: Label 'Shipment Date';
        Shipmt_noTxt: Label 'Shipment No.';
        Return_Shipmt_noTxt: Label 'Return Shipment No.';
        Transfer_Shipmt_noTxt: Label 'Transfer Shipment No.';
        Tote_idTxt: Label 'Tote ID';
        Tote_shippingTxt: Label 'Tote Shipping';
        Scan_remaining_totesTxt: Label 'Scan Remaining Totes';
        Scan_remaining_totes_infoTxt: Label 'The following Tote IDs must be scanned to register on Shipment No. %1:\r\n', Comment = '%1 is Shipment';
        No_additional_totesTxt: Label 'There are no more totes to be delivered together with this one.';
        Scan_tote_idTxt: Label 'Scan Tote ID';
        Tote_combination_not_foundTxt: Label 'Tote %1 could not be found on shipment %2', Comment = '%1 is Tote. %2 is Shipment';
        Multiple_serial_existTxt: Label 'The serial number [%1] is associated with multiple items [%2]', Comment = '%1 is Serial. %2 is Items';
        No_binTxt: Label 'No Bin';
        Open_pick_ordersTxt: Label 'Open Pick Orders';
        Open_pick_orders_infoTxt: Label 'There are open Pick Orders for this shipment: %1\r\nPick Orders: %2', Comment = '%1 is Shipment. %2 is Pick Order';
        Not_partial_shipTxt: Label 'Partial shipment is not allowed for line %1 on shipment %2', Comment = '%1 is Line. %2 is Shipment';
        Completely_shippedTxt: Label 'Shipment %1 is completely shipped', Comment = '%1 is Shipment';
        Nothing_pickedTxt: Label 'Nothing has been picked for shipment %1', Comment = '%1 is Shipment';
        Unexpected_ship_statusTxt: Label 'Unexpected: Shipment status %1 not handled.', Comment = '%1 is Status';
        Tote_ship_loc_pick_ship_errorTxt: Label 'Tote shipping is only possible on locations where shipments and picks are used. This is not true for %1', Comment = '%1 is Location';
        Shipment_missingTxt: Label 'Shipment %1 does not exist or is not released', Comment = '%1 is Shipment';
        Unknown_orderTxt: Label 'Order %1 does not exist in Business Central anymore', Comment = '%1 is Order';
        Order_numberTxt: Label 'Order No.';
        No_doc_handlerTxt: Label 'No document handler is available for %1.', Comment = '%1 is Registration Type';
        ShipmentTxt: Label 'Shipment';
        ReceiverTxt: Label 'Receiver';
        SenderTxt: Label 'Sender';
        No_Menu_ItemsTxt: Label 'No menuitems has been defined for group %1.', Comment = '%1 is group';
        Jnl_batchTxt: Label 'Jnl. Batch';
        DescriptionTxt: Label 'Description';
        DocumentTxt: Label 'Document';
        Item_not_foundTxt: Label 'Item %1 could not be found.', Comment = '%1 is Item';
        Item_or_LP_not_foundTxt: Label 'The value %1 was not found as either an Item or License Plate.', Comment = '%1 is Item Number or License Plate Number';
        Bin_or_LP_not_foundTxt: Label 'The value %1 was not found as either a Bin or License Plate.', Comment = '%1 is Bin Code or License Plate Number';
        LP_Not_Found_Err: Label 'License Plate %1 not found', Comment = '%1 = License Plate No.';
        Quantity_errTxt: Label 'The quantity counted of %1 is significantly different from the system quantity of %2. Please ensure the counted quantity is correct.', Comment = '%1 is counted Quantity. %2 is Quantity';
        Barcode_inuse_errTxt: Label 'Barcode %1 is already used by Item %2. Item Cross Reference will not be created.', Comment = '%1 is Barcode. %2 is Item';
        Barcode_ref_in_use_errTxt: Label 'Barcode %1 is already used by Item %2. Item Reference will not be created.', Comment = '%1 is Barcode. %2 is Item';
        Item_exist_errTxt: Label 'Item %1 does not exist.', Comment = '%1 is Item';
        Bin_exist_errTxt: Label 'Bin "%1" does not exist on Location "%2".', Comment = '%1 is Bin. %2 is Location.';
        UnplannedcountdirectedlotitemjnlTxt: Label '%2 cannot be %3 when doing an Unplanned Count of Lot Tracked Items in anything but %1', Comment = '%1 is Base Unit of Measure. %2 is Skip Whse Unpl Count IJ Post-field. %3 is  Skip Whse Unpl Count IJ Post-value';
        Remove_qty_exceeds_reservationsTxt: Label 'It is not possible to post the adjustment due to reservations (%1 %2)', Comment = '%1 is Quantity. %2 is Unit';
        Post_shipmentTxt: Label 'Post Shipment';
        Add_imageTxt: Label 'Add Image';
        Item_image_registeredTxt: Label 'Item Image for Item %1 Registered', Comment = '%1 is Item';
        Select_xTxt: Label 'Select %1', Comment = '%1 is What to select';
        Available_qty_to_takeTxt: Label 'Available Qty. to Take';
        Available_qtyTxt: Label 'Available Qty.';
        Reference_idTxt: Label 'Reference ID';
        No_picture_to_attachTxt: Label 'There is no picture to attach';
        Image_registeredTxt: Label 'Image for ReferenceID: %1 Registered', Comment = '%1 is ReferenceID';
        Not_more_than_one_imageTxt: Label 'You cannot Register more than one picture at a time';
        Bin_is_mandatory_on_locationTxt: Label 'Bin is mandatory on Location %1', Comment = '%1 is location';
        Item_no_qty_on_locationTxt: Label 'Item %1 has no Inventory on Location %2', Comment = '%1 is item. %2 is location';
        Recording_noTxt: Label 'Recording No.';
        Person_responsibleTxt: Label 'Person Responsible';
        Onpostevent_failedTxt: Label 'But error occurred afterwards: %1 in event: "%2"', Comment = '%1 is Error. %2 is Event name';
        Error_occurred_afterwardsTxt: Label 'An error occurred afterwards: %1', Comment = '%1 is Last Error';
        Unknown_mediaidTxt: Label 'Unknown MediaID: %1', Comment = '%1 is MediaID';
        Starting_dateTxt: Label 'Starting Date';
        ProgressTxt: Label 'Progress';
        Filter_progress_readyTxt: Label 'Ready';
        Filter_progress_completedTxt: Label 'Completed';
        Enter_setup_timeTxt: Label 'Enter Setup Time';
        Setup_timeTxt: Label 'Setup Time';
        Enter_run_timeTxt: Label 'Enter Run Time';
        Run_timeTxt: Label 'Run Time';
        Time_can_not_be_registeredTxt: Label 'Time can not be registered at this production order';
        TimeTxt: Label 'Time';
        Enter_scrap_quantityTxt: Label 'Enter Scrap Quantity';
        Scrap_quantityTxt: Label 'Scrap Quantity';
        Enter_scrap_codeTxt: Label 'Enter Scrap Code';
        Scrap_codeTxt: Label 'Scrap Code';
        Work_centerTxt: Label 'Work Center';
        Finished_qtyTxt: Label 'Finished Qty.';
        Remaining_qtyTxt: Label 'Remaining Qty.';
        Actual_setup_timeTxt: Label 'Actual Setup Time';
        Actual_run_timeTxt: Label 'Actual Run Time';
        Actual_scrap_qtyTxt: Label 'Actual Scrap Qty.';
        Quantity_perTxt: Label 'Quantity Per';
        Picked_qtyTxt: Label 'Picked Qty.';
        Expected_qtyTxt: Label 'Expected Qty.';
        Actual_consump_qtyTxt: Label 'Actual Consump. Qty.';
        Substitution_availableTxt: Label 'Substitution available';
        Substitute_componentTxt: Label 'Substitute Component';
        Substitute_withTxt: Label 'substitute with';
        Finish_operation_xTxt: Label 'Finish operation %1', Comment = '%1 is Operation';
        Not_a_route_operationTxt: Label 'This is not a Route Operation';
        Route_operation_statusTxt: Label 'Route Operation Status';
        Route_operation_status_unfinishedTxt: Label 'Unfinished';
        No_of_labelsTxt: Label 'Number Of Labels';
        No_of_labels_helpTxt: Label 'Number of labels to print';
        Quantity_per_labelTxt: Label 'Number of units per label';
        Quantity_per_label_helpTxt: Label 'The number of units, each label represents';
        Number_of_copiesTxt: Label 'Number of Copies';
        Number_of_copies_helpTxt: Label 'Number of identical copies to print';
        Shipment_document_statusTxt: Label 'Document Status';
        Shipment_document_status_not_pickedTxt: Label 'Not picked';  // Artificial status to replace "blank"
        Shipment_document_status_partially_pickedTxt: Label 'Partially picked';
        Shipment_document_status_partially_shippedTxt: Label 'Partially shipped';
        Shipment_document_status_completely_pickedTxt: Label 'Completely picked';
        ProdOutputTimeTrackingTitleTxt: Label 'Time Tracking';
        ProdOutputFinishOperationTitleTxt: Label 'Finish operation';
        Start_timeTxt: Label 'Start Time';
        Stop_timeTxt: Label 'Stop Time';
        Start_setupTxt: Label 'Start Setup';
        Stop_setupTxt: Label 'Stop Setup';
        Start_runTxt: Label 'Start Run';
        Stop_runTxt: Label 'Stop Run';
        Quantity_on_inventory_xy_is_not_sufficientTxt: Label 'The quantity on inventory (%1 %2) is not sufficient to cover the net change in inventory. Are you sure that you want to record the quantity?', Comment = '%1 is Quantity. %2 is Unit';
        Pick_started_tote_picking_cannot_be_changedTxt: Label 'Pick Registration has started and Tote Picking cannot be changed.';
        Delete_all_registrations_and_try_againTxt: Label 'Delete All Registrations and try again.';
        Enable_tote_pickingTxt: Label 'Enable Tote Picking';
        Disable_tote_pickingTxt: Label 'Disable Tote Picking';
        NumberTxt: Label 'No.';
        TypeTxt: Label 'Type';
        ShiptoaddressTxt: Label 'Ship-to Address';
        No_of_documentsTxt: Label 'No. of documents: %1', Comment = '%1 is no of documents';
        SuggestionTxt: Label 'Suggestion: %1', Comment = '%1 is the suggested value';

        // >> _History
        HISTORY_Txt: Label 'History';

        No_of_entriesTxt: Label 'No. of entries';
        // << _History

        // >> _LicensePlate
        MainMenu_licensePlate_contentTxt: Label 'License Plate Contents';
#pragma warning disable LC0055 // Same as the other labels in this section, should be Txt
        LicensePlateTxt: Label 'License Plate', Locked = true;
        LPTxt: Label 'LP', Locked = true;
#pragma warning restore LC0055
        To_licensePlateTxt: Label 'To License Plate';
        To_licensePlate_helpTxt: Label 'Select the License Plate you want to move the content into';
        From_licensePlateTxt: Label 'From License Plate';
        Scan_From_bin_or_LPTxt: Label 'Scan From Bin / License Plate';
        LicensePlate_must_be_empty_errorTxt: Label 'You can not delete a License Plate with Content';
        Top_levelTxt: Label 'Top Level', Locked = true;
        Add_licensePlate_helpTxt: Label 'Scan the new License Plate No.';
        No_licensePlate_to_update_errorTxt: Label 'No License Plates to update';
        LicensePlate_commentTxt: Label 'Comment';
        LicensePlate_comment_helpTxt: Label 'Add a comment to mark or identify a License Plate';
        Edit_licensePlateTxt: Label 'Edit License Plate';
        Unpl_move_completed_putaway_registeredTxt: Label 'Unplanned Move for LP %1 completed. Put-away registered to Bin %2.', Comment = '%1 is License Plate. %2 is ToBin';
        Unpl_move_adv_completedTxt: Label 'Unplanned Move for %1 %2 completed to %3 %4.', Comment = '%1 is Item or LP. %2 is item no. or LP no. %3 is Bin or LP. %4 is Bin code or LP no.';
        MainMenu_UnplannedMove_AdvancedTxt: Label 'Unplanned Move Advanced';
        Page_UnplannedMove_Advanced_TitleTxt: Label 'Unplanned Move Advanced';
        MainMenu_PutAway_LicensePlateTxt: Label 'Put Away License Plate', Comment = 'To ensure non-linebreak in the word ''License Plate'', use the special ALT+0160 character';
        PutAwayNumberTxt: Label 'Put-away: %1', Comment = '%1 is Put-away No.';
        Create_new_LP_confirmTxt: Label 'Do you want to create a new License Plate with this number?';
        Scan_initial_bin_for_LPTxt: Label 'Scan the Bin code where the new License Plate will initially be placed';
        Print_LPTxt: Label 'Print LP Label';
        Start_New_LPTxt: Label 'Start New LP';
        // << _LicensePlate

        // >> _Pack
        Packing_stationTxt: Label 'Packing Station';
        Staging_hintTxt: Label 'Staging Hint';
        Staging_hint_helpTxt: Label 'Inform where goods are staged';
        Package_qtyTxt: Label 'Qty. of Packages';
        Item_qtyTxt: Label 'Qty. of Items';
        EmptyTxt: Label 'Empty';
        Package_typeTxt: Label 'Package Type';
        Package_type_labelTxt: Label 'Select Package Type';
        Shipping_agent_service_helpTxt: Label 'Select Shipping Agent Service';
        Shipping_agent_helpTxt: Label 'Select Shipping Agent';
        Enter_load_meterTxt: Label 'Enter Loading Meter (LDM)';
        Load_meterTxt: Label 'Loading Meter (LDM)';

        MainMenu_packingTxt: Label 'Pack & Ship', Locked = true;
        PackingTxt: Label 'Packing';
        LicensePlate_bulkRegistrationTxt: Label 'Bulk register information';
        LicensePlate_move_to_newTxt: Label 'Move License Plates to new';
        LicensePlate_combine_content_to_newTxt: Label 'Combine All Contents to new';
        LicensePlate_contentTxt: Label 'Contents';
        PostTxt: Label 'Post';
        LicensePlate_createTxt: Label 'Create LP';
        LicensePlate_addTxt: Label 'Add License Plate';
        LicensePlate_deleteTxt: Label 'Delete License Plate';
        LicensePlate_moveTxt: Label 'Move License Plate';
        New_LicensePlateNoTxt: Label 'New License Plate No.';
    // << _Pack

    internal procedure SetupDefaultLanguages()
    begin
        SetupDefaultLanguage('DAN', true);  // Danish
        SetupDefaultLanguage('DEU', true);  // German
        SetupDefaultLanguage('ENU', true);  // English
        SetupDefaultLanguage('FIN', true);  // Finnish
        SetupDefaultLanguage('NLD', true);  // Dutch
        SetupDefaultLanguage('SVE', true);  // Swedish

        SetupDefaultLanguage('ESP', false); // Spanish
        SetupDefaultLanguage('ETI', false); // Estonian
        SetupDefaultLanguage('FRA', false); // French
        SetupDefaultLanguage('HRV', false); // Croatian
        SetupDefaultLanguage('ITA', false); // Italian
        SetupDefaultLanguage('JPN', false); // Japanese
        SetupDefaultLanguage('LTH', false); // Lithuanian 
        SetupDefaultLanguage('LVI', false); // Latvian
        SetupDefaultLanguage('NOR', false); // Norwegian (Bokmål)
        SetupDefaultLanguage('PLK', false); // Polish
        SetupDefaultLanguage('PTG', false); // Portuguese
        SetupDefaultLanguage('ROM', false); // Romanian
        SetupDefaultLanguage('RUS', false); // Russian
        SetupDefaultLanguage('SLV', false); // Slovene
    end;

    internal procedure SetupDefaultLanguage(_LanguageCode: Code[10]; _SetupLanguageMessages: Boolean)
    var
        MobLanguage: Record "MOB Language";
    begin
        // Check if Language Code exists and has "Windows Language ID" specified
        if not MobToolbox.LanguageHasId(_LanguageCode) then
            exit;

        // Skip existing language
        if MobLanguage.Get(_LanguageCode) then
            exit;

        MobLanguage.Init();
        MobLanguage.Validate(Code, _LanguageCode); // Populates "Device Language Code"
        if MobLanguage.Insert(true) then; // Intentionally ignore errors

        if _SetupLanguageMessages then
            SetupLanguageMessages(_LanguageCode);   // Fallback to ENU if not DAN, DEU or ENU
    end;

    procedure GetMessage(_MsgKey: Code[50]) _MsgText: Text[250]
    var
        MobMessage: Record "MOB Message";
    begin
        // Globallanguage is set by Document Processor to use "Mobile User"'s language 
        // Possible re-set by Print or customization
        if MobMessage.Get(MobToolbox.GetGlobalLanguage(), _MsgKey) then
            exit(MobMessage.Message);

        // Fallback to ENU
        if MobMessage.Get('ENU', _MsgKey) then
            exit(MobMessage.Message);

        exit(_MsgKey);
    end;

    procedure SetupLanguageMessages(_LanguageCode: Code[10])
    var
        MobMessage: Record "MOB Message";
    begin
        CreateMessages(_LanguageCode);

        OnAddMessages(_LanguageCode, MobMessage);
    end;

    procedure CheckENULanguageMessages()
    var
        MobMessage: Record "MOB Message";
    begin
        if MobMessage.IsEmpty() then
            CreateMessages('ENU');
    end;

    local procedure CreateMessages(_LanguageCode: Code[10])
    var
        SavedLanguage: Code[10];
    begin
        if (_LanguageCode = '') then
            Error(LanguageMustExistErr);

        SavedLanguage := MobToolbox.GetGlobalLanguage();

        if SavedLanguage = '' then
            exit;

        if SavedLanguage <> _LanguageCode then
            GlobalLanguage(MobToolbox.GetLanguageId(_LanguageCode, true));

        CreateMessage(_LanguageCode, 'ASSIGNED_USER_ID', Assigned_user_idTxt);
        CreateMessage(_LanguageCode, 'WHSE_ACT_NOT_UNIQUE', Whse_act_not_uniqueTxt);
        CreateMessage(_LanguageCode, 'XML_UNKNOWN_ELEMENT', Xml_unknown_elementTxt);
        CreateMessage(_LanguageCode, 'UNKNOWN_SERIAL', Unknown_serialTxt);
        CreateMessage(_LanguageCode, 'RECV_KNOWN_SERIAL', Recv_known_serialTxt);
        CreateMessage(_LanguageCode, 'UNKNOWN_LOT', Unknown_lotTxt);
        CreateMessage(_LanguageCode, 'XY_DOESNOTEXIST_Z', XY_DoesNotExist_ZTxt);
        CreateMessage(_LanguageCode, 'TRACKING_RESERVED', Tracking_ReservedTxt);
        CreateMessage(_LanguageCode, 'SPLIT_LINE_NOT_FOUND', Split_line_not_foundTxt);
        CreateMessage(_LanguageCode, 'PLACE_LINE_NOT_FOUND', Place_line_not_foundTxt);
        CreateMessage(_LanguageCode, 'ENTER_DELV_NOTE', Enter_delv_noteTxt);
        CreateMessage(_LanguageCode, 'DELV_NOTE_LABEL_TEXT', Delv_note_label_textTxt);
        CreateMessage(_LanguageCode, 'POST_SUCCESS', Post_successTxt);
        CreateMessage(_LanguageCode, 'NOT_AVAILABLE', Not_availableTxt);
        CreateMessage(_LanguageCode, 'REG_TRANS_SUCCESS', Reg_trans_successTxt);
        CreateMessage(_LanguageCode, 'ORDER_LOCKED_BY', Order_locked_byTxt);
        CreateMessage(_LanguageCode, 'LOCK_SUCCESS', Lock_successTxt);
        CreateMessage(_LanguageCode, 'UNLOCK_SUCCESS', Unlock_successTxt);
        CreateMessage(_LanguageCode, 'BIN', BinTxt);
        CreateMessage(_LanguageCode, 'ITEM', ItemTxt);
        CreateMessage(_LanguageCode, 'SELECT_BIN', Select_binTxt);
        CreateMessage(_LanguageCode, 'DEFAULT', DefaultTxt);
        CreateMessage(_LanguageCode, 'SERIAL_NO_LABEL', Serial_no_labelTxt);
        CreateMessage(_LanguageCode, 'LOT_NO_LABEL', Lot_no_labelTxt);
        CreateMessage(_LanguageCode, 'PACKAGE_NO_LABEL', GetPackageNoCaption());
        CreateMessage(_LanguageCode, 'SCAN_X', Scan_XTxt);
        CreateMessage(_LanguageCode, 'ENTER_EXP_DATE', Enter_exp_dateTxt);
        CreateMessage(_LanguageCode, 'EXP_DATE_LABEL', Exp_date_labelTxt);
        CreateMessage(_LanguageCode, 'ENTER_QTY', Enter_qtyTxt);
        CreateMessage(_LanguageCode, 'QTY_LABEL', Qty_labelTxt);
        CreateMessage(_LanguageCode, 'UOM_LABEL', Uom_labelTxt);
        CreateMessage(_LanguageCode, 'FROM_BIN_LABEL', From_bin_labelTxt);
        CreateMessage(_LanguageCode, 'ENTER_TO_BIN', Enter_to_binTxt);
        CreateMessage(_LanguageCode, 'SCAN_TO_BIN', Scan_to_binTxt);
        CreateMessage(_LanguageCode, 'TO_BIN_LABEL', To_bin_labelTxt);
        CreateMessage(_LanguageCode, 'UNPL_MOVE_COMPLETED', Unpl_move_completedTxt);
        CreateMessage(_LanguageCode, 'UNPL_COUNT_SERIAL_NOT_ALLOWED', Unpl_count_serial_not_allowedTxt);
        CreateMessage(_LanguageCode, 'UNPL_COUNT_NOWHSE_NOT_ALLOWED', Unpl_count_nowhse_not_allowedTxt);
        CreateMessage(_LanguageCode, 'UNPL_COUNT_NO_LOC_NOT_ALLOWED', Unpl_count_no_loc_not_allowedTxt);
        CreateMessage(_LanguageCode, 'ENTER_COUNTED_QTY', Enter_counted_qtyTxt);
        CreateMessage(_LanguageCode, 'UNPL_COUNT_COMPLETED', Unpl_count_completedTxt);
        CreateMessage(_LanguageCode, 'LOCATION', LocationTxt);
        CreateMessage(_LanguageCode, 'NEW_LOCATION', New_locationTxt);
        CreateMessage(_LanguageCode, 'EXP_RECV_DATE', Exp_recv_dateTxt);
        CreateMessage(_LanguageCode, 'REASON', ReasonTxt);
        CreateMessage(_LanguageCode, 'ADJUST_QTY_COMPLETED', Adjust_qty_completedTxt);
        CreateMessage(_LanguageCode, 'QUANTITY', QuantityTxt);
        CreateMessage(_LanguageCode, 'SCAN_BARCODE', Scan_barcodeTxt);
        CreateMessage(_LanguageCode, 'ITEM_BARCODE', Item_barcodeTxt);
        CreateMessage(_LanguageCode, 'ITEM_CROSSREF_COMPLETED', Item_crossref_completedTxt);
        CreateMessage(_LanguageCode, 'ITEM_REFERENCE_CREATED', Item_reference_createdTxt);
        CreateMessage(_LanguageCode, 'ITEM_DESCRIPTION', Item_descriptionTxt);
        CreateMessage(_LanguageCode, 'ITEM_CATEGORY', Item_categoryTxt);
        CreateMessage(_LanguageCode, 'MULTI_BINS_NOT_ALLOWED', Multi_bins_not_allowedTxt);
        CreateMessage(_LanguageCode, 'RECV_MULTI_BINS_NOT_ALLOWED', Recv_multi_bins_not_allowedTxt);
        CreateMessage(_LanguageCode, 'UNKNOWN_ITEM_NO', Unknown_item_noTxt);
        CreateMessage(_LanguageCode, 'ENTER_QTY_TO_ADJUST', Enter_qty_to_adjustTxt);
        CreateMessage(_LanguageCode, 'ENTER_REASON', Enter_reasonTxt);
        CreateMessage(_LanguageCode, 'INSUFFICIENT_STOCK_QTY', Insufficient_stock_qtyTxt);
        CreateMessage(_LanguageCode, 'ITEM_NO', Item_noTxt);
        CreateMessage(_LanguageCode, 'YES_NO', Yes_noTxt);
        CreateMessage(_LanguageCode, 'YES', YesTxt);
        CreateMessage(_LanguageCode, 'NO', NoTxt);
        CreateMessage(_LanguageCode, 'SIGNATURE', SignatureTxt);
        CreateMessage(_LanguageCode, 'SIGNATURE_LABEL', Signature_labelTxt);
        CreateMessage(_LanguageCode, 'WRONG_EXPIRATION_DATE', Wrong_expiration_dateTxt);
        CreateMessage(_LanguageCode, 'NO_QTY_ON_BIN', No_qty_on_binTxt);
        CreateMessage(_LanguageCode, 'SALES_ORDER_LABEL', Sales_order_labelTxt);
        CreateMessage(_LanguageCode, 'INBOUND_TRANSFER_LABEL', Inbound_transfer_labelTxt);
        CreateMessage(_LanguageCode, 'OUTBOUND_TRANSFER_LABEL', Outbound_transfer_labelTxt);
        CreateMessage(_LanguageCode, 'SHIPMENT_DATE', Shipment_dateTxt);
        CreateMessage(_LanguageCode, 'EXPECTED_RECEIPT_DATE', Expected_receipt_dateTxt);
        CreateMessage(_LanguageCode, 'TO', ToTxt);
        CreateMessage(_LanguageCode, 'FROM', FromTxt);
        CreateMessage(_LanguageCode, 'NO_OF_LINES', No_of_linesTxt);
        CreateMessage(_LanguageCode, 'HANDHELD_UNPLANNED_MOVE', Handheld_unplanned_moveTxt);
        CreateMessage(_LanguageCode, 'HANDHELD_UNPLANNED_COUNT', Handheld_unplanned_countTxt);
        CreateMessage(_LanguageCode, 'HANDHELD_ADJUST_QUANTITY', Handheld_adjust_quantityTxt);
        CreateMessage(_LanguageCode, 'HANDHELD', HandheldTxt);
        CreateMessage(_LanguageCode, 'PRINTER', PrinterTxt);
        CreateMessage(_LanguageCode, 'PRINTERS', PrintersTxt);
        CreateMessage(_LanguageCode, 'PRINTER(S)', PrinterOrPrintersTxt);
        CreateMessage(_LanguageCode, 'NOPRINTERSETUP', NoprintersetupTxt);
        CreateMessage(_LanguageCode, 'PRINT_QTY', Print_qtyTxt);
        CreateMessage(_LanguageCode, 'PRINT_RESPONSE', Print_responseTxt);
        CreateMessage(_LanguageCode, 'PRINT_FAILED', Print_failedTxt);
        CreateMessage(_LanguageCode, 'REPRINT', ReprintTxt);
        CreateMessage(_LanguageCode, 'TAKE_LINE_NOT_FOUND', Take_line_not_foundTxt);
        CreateMessage(_LanguageCode, 'ENTER_UOM', Enter_uomTxt);
        CreateMessage(_LanguageCode, 'ENTER_UOM_HELP', Enter_uom_helpTxt);
        CreateMessage(_LanguageCode, 'BATCH_NAME', Batch_nameTxt);
        CreateMessage(_LanguageCode, 'ADD_LINE', Add_lineTxt);
        CreateMessage(_LanguageCode, 'ADD_COUNT_LINE', Add_count_lineTxt);
        CreateMessage(_LanguageCode, 'ADDED_LINE', LineHasBeenAddedForXTxt);
        CreateMessage(_LanguageCode, 'COUNT_LINE_EXISTS', Count_line_existsTxt);
        CreateMessage(_LanguageCode, 'BULK_MOVE_COMPLETED', Bulk_move_completedTxt);
        CreateMessage(_LanguageCode, 'WHSE_TRKG_NEEDED', Whse_trkg_neededTxt);
        CreateMessage(_LanguageCode, 'NOTHING_TO_REGISTER', Nothing_to_registerTxt);
        CreateMessage(_LanguageCode, 'VARIANT_LABEL', Variant_labelTxt);
        CreateMessage(_LanguageCode, 'ENTER_VARIANT', Enter_variantTxt);
        CreateMessage(_LanguageCode, 'ENTER_VARIANT_HELP', Enter_variant_helpTxt);
        CreateMessage(_LanguageCode, 'PO_NUMBER', Po_numberTxt);
        CreateMessage(_LanguageCode, 'DATA_NOT_FOUND', Data_not_foundTxt);
        CreateMessage(_LanguageCode, 'AVAILABLE_NOW', Available_nowTxt);
        CreateMessage(_LanguageCode, 'FILTER_ALL', Filter_allTxt);
        CreateMessage(_LanguageCode, 'FILTER_MINE_UNASSIGNED', Filter_mine_unassignedTxt);
        CreateMessage(_LanguageCode, 'FILTER_ONLY_MINE', Filter_only_mineTxt);
        CreateMessage(_LanguageCode, 'ENTER_WEIGHT', Enter_weightTxt);
        CreateMessage(_LanguageCode, 'ENTER_HEIGHT', Enter_heightTxt);
        CreateMessage(_LanguageCode, 'ENTER_WIDTH', Enter_widthTxt);
        CreateMessage(_LanguageCode, 'ENTER_CUBAGE', Enter_cubageTxt);
        CreateMessage(_LanguageCode, 'ENTER_LENGTH', Enter_lengthTxt);
        CreateMessage(_LanguageCode, 'WEIGHT_LABEL', Weight_labelTxt);
        CreateMessage(_LanguageCode, 'HEIGHT_LABEL', Height_labelTxt);
        CreateMessage(_LanguageCode, 'WIDTH_LABEL', Width_labelTxt);
        CreateMessage(_LanguageCode, 'CUBAGE_LABEL', Cubage_labelTxt);
        CreateMessage(_LanguageCode, 'LENGTH_LABEL', Length_labelTxt);
        CreateMessage(_LanguageCode, 'ENTER_QTY_PER_UOM', Enter_qty_per_uomTxt);
        CreateMessage(_LanguageCode, 'RETURN_ORDER_LABEL', Return_order_labelTxt);
        CreateMessage(_LanguageCode, 'SHIPMT_DATE', Shipmt_dateTxt);
        CreateMessage(_LanguageCode, 'SHIPMT_NO', Shipmt_noTxt);
        CreateMessage(_LanguageCode, 'RETURN_SHIPMT_NO', Return_Shipmt_noTxt);
        CreateMessage(_LanguageCode, 'TRANSFER_SHIPMT_NO', Transfer_Shipmt_noTxt);
        CreateMessage(_LanguageCode, 'TOTE_ID', Tote_idTxt);
        CreateMessage(_LanguageCode, 'TOTE_SHIPPING', Tote_shippingTxt);
        CreateMessage(_LanguageCode, 'SCAN_REMAINING_TOTES', Scan_remaining_totesTxt);
        CreateMessage(_LanguageCode, 'SCAN_REMAINING_TOTES_INFO', Scan_remaining_totes_infoTxt);
        CreateMessage(_LanguageCode, 'NO_ADDITIONAL_TOTES', No_additional_totesTxt);
        CreateMessage(_LanguageCode, 'SCAN_TOTE_ID', Scan_tote_idTxt);
        CreateMessage(_LanguageCode, 'TOTE_COMBINATION_NOT_FOUND', Tote_combination_not_foundTxt);
        CreateMessage(_LanguageCode, 'MULTIPLE_SERIAL_EXIST', Multiple_serial_existTxt);
        CreateMessage(_LanguageCode, 'NO_BIN', No_binTxt);
        CreateMessage(_LanguageCode, 'OPEN_PICK_ORDERS', Open_pick_ordersTxt);
        CreateMessage(_LanguageCode, 'OPEN_PICK_ORDERS_INFO', Open_pick_orders_infoTxt);
        CreateMessage(_LanguageCode, 'NOT_PARTIAL_SHIP', Not_partial_shipTxt);
        CreateMessage(_LanguageCode, 'COMPLETELY_SHIPPED', Completely_shippedTxt);
        CreateMessage(_LanguageCode, 'NOTHING_PICKED', Nothing_pickedTxt);
        CreateMessage(_LanguageCode, 'UNEXPECTED_SHIP_STATUS', Unexpected_ship_statusTxt);
        CreateMessage(_LanguageCode, 'TOTE_SHIP_LOC_PICK_SHIP_ERROR', Tote_ship_loc_pick_ship_errorTxt);
        CreateMessage(_LanguageCode, 'SHIPMENT_MISSING', Shipment_missingTxt);
        CreateMessage(_LanguageCode, 'UNKNOWN_ORDER', Unknown_orderTxt);
        CreateMessage(_LanguageCode, 'ORDER_NUMBER', Order_numberTxt);
        CreateMessage(_LanguageCode, 'NO_DOC_HANDLER', No_doc_handlerTxt);
        CreateMessage(_LanguageCode, 'SHIPMENT', ShipmentTxt);
        CreateMessage(_LanguageCode, 'RECEIVER', ReceiverTxt);
        CreateMessage(_LanguageCode, 'SENDER', SenderTxt);
        CreateMessage(_LanguageCode, 'NO_MENU_ITEMS', No_Menu_ItemsTxt);
        CreateMessage(_LanguageCode, 'JNL_BATCH', Jnl_batchTxt);
        CreateMessage(_LanguageCode, 'DESCRIPTION', DescriptionTxt);
        CreateMessage(_LanguageCode, 'DOCUMENT', DocumentTxt);
        CreateMessage(_LanguageCode, 'ITEM_NOT_FOUND', Item_not_foundTxt);
        CreateMessage(_LanguageCode, 'ITEM_OR_LP_NOT_FOUND', Item_or_LP_not_foundTxt);
        CreateMessage(_LanguageCode, 'QUANTITY_ERR', Quantity_errTxt);
        CreateMessage(_LanguageCode, 'BARCODE_INUSE_ERR', Barcode_inuse_errTxt);
        CreateMessage(_LanguageCode, 'BARCODE_REF_IN_USE_ERR', Barcode_ref_in_use_errTxt);
        CreateMessage(_LanguageCode, 'ITEM_EXIST_ERR', Item_exist_errTxt);
        CreateMessage(_LanguageCode, 'BIN_EXIST_ERR', Bin_exist_errTxt);
        CreateMessage(_LanguageCode, 'UnplannedCountDirectedLotItemJnl', UnplannedcountdirectedlotitemjnlTxt); // uppercase?
        CreateMessage(_LanguageCode, 'REMOVE_QTY_EXCEEDS_RESERVATIONS', Remove_qty_exceeds_reservationsTxt);
        CreateMessage(_LanguageCode, 'POST_SHIPMENT', Post_shipmentTxt);
        CreateMessage(_LanguageCode, 'ADD_IMAGE', Add_imageTxt);
        CreateMessage(_LanguageCode, 'ITEM_IMAGE_REGISTERED', Item_image_registeredTxt);
        CreateMessage(_LanguageCode, 'SELECT_X', Select_xTxt);
        CreateMessage(_LanguageCode, 'AVAILABLE_QTY_TO_TAKE', Available_qty_to_takeTxt);
        CreateMessage(_LanguageCode, 'AVAILABLE_QTY', Available_qtyTxt);
        CreateMessage(_LanguageCode, 'REFERENCE_ID', Reference_idTxt);
        CreateMessage(_LanguageCode, 'NO_PICTURE_TO_ATTACH', No_picture_to_attachTxt);
        CreateMessage(_LanguageCode, 'IMAGE_REGISTERED', Image_registeredTxt);
        CreateMessage(_LanguageCode, 'NOT_MORE_THAN_ONE_IMAGE', Not_more_than_one_imageTxt);
        CreateMessage(_LanguageCode, 'BIN_IS_MANDATORY_ON_LOCATION', Bin_is_mandatory_on_locationTxt);
        CreateMessage(_LanguageCode, 'ITEM_NO_QTY_ON_LOCATION', Item_no_qty_on_locationTxt);
        CreateMessage(_LanguageCode, 'RECORDING_NO', Recording_noTxt);
        CreateMessage(_LanguageCode, 'PERSON_RESPONSIBLE', Person_responsibleTxt);
        CreateMessage(_LanguageCode, 'ONPOSTEVENT_FAILED', Onpostevent_failedTxt);
        CreateMessage(_LanguageCode, 'ERROR_OCCURRED_AFTERWARDS', Error_occurred_afterwardsTxt);
        CreateMessage(_LanguageCode, 'UNKNOWN_MEDIAID', Unknown_mediaidTxt);
        CreateMessage(_LanguageCode, 'STARTING_DATE', Starting_dateTxt);
        CreateMessage(_LanguageCode, 'PROGRESS', ProgressTxt);
        CreateMessage(_LanguageCode, 'FILTER_PROGRESS_READY', Filter_progress_readyTxt);
        CreateMessage(_LanguageCode, 'FILTER_PROGRESS_COMPLETED', Filter_progress_completedTxt);
        CreateMessage(_LanguageCode, 'ENTER_SETUP_TIME', Enter_setup_timeTxt);
        CreateMessage(_LanguageCode, 'SETUP_TIME', Setup_timeTxt);
        CreateMessage(_LanguageCode, 'ENTER_RUN_TIME', Enter_run_timeTxt);
        CreateMessage(_LanguageCode, 'RUN_TIME', Run_timeTxt);
        CreateMessage(_LanguageCode, 'TIME_CAN_NOT_BE_REGISTERED', Time_can_not_be_registeredTxt);
        CreateMessage(_LanguageCode, 'TIME', TimeTxt);
        CreateMessage(_LanguageCode, 'ENTER_SCRAP_QUANTITY', Enter_scrap_quantityTxt);
        CreateMessage(_LanguageCode, 'SCRAP_QUANTITY', Scrap_quantityTxt);
        CreateMessage(_LanguageCode, 'ENTER_SCRAP_CODE', Enter_scrap_codeTxt);
        CreateMessage(_LanguageCode, 'SCRAP_CODE', Scrap_codeTxt);
        CreateMessage(_LanguageCode, 'WORK_CENTER', Work_centerTxt);
        CreateMessage(_LanguageCode, 'FINISHED_QTY', Finished_qtyTxt);
        CreateMessage(_LanguageCode, 'REMAINING_QTY', Remaining_qtyTxt);
        CreateMessage(_LanguageCode, 'ACTUAL_SETUP_TIME', Actual_setup_timeTxt);
        CreateMessage(_LanguageCode, 'ACTUAL_RUN_TIME', Actual_run_timeTxt);
        CreateMessage(_LanguageCode, 'ACTUAL_SCRAP_QTY', Actual_scrap_qtyTxt);
        CreateMessage(_LanguageCode, 'QUANTITY_PER', Quantity_perTxt);
        CreateMessage(_LanguageCode, 'PICKED_QTY', Picked_qtyTxt);
        CreateMessage(_LanguageCode, 'EXPECTED_QTY', Expected_qtyTxt);
        CreateMessage(_LanguageCode, 'ACTUAL_CONSUMP_QTY', Actual_consump_qtyTxt);
        CreateMessage(_LanguageCode, 'SUBSTITUTION_AVAILABLE', Substitution_availableTxt);
        CreateMessage(_LanguageCode, 'SUBSTITUTE_COMPONENT', Substitute_componentTxt);
        CreateMessage(_LanguageCode, 'SUBSTITUTE_WITH', Substitute_withTxt);
        CreateMessage(_LanguageCode, 'FINISH_OPERATION_X', Finish_operation_xTxt);
        CreateMessage(_LanguageCode, 'NOT_A_ROUTE_OPERATION', Not_a_route_operationTxt);
        CreateMessage(_LanguageCode, 'ROUTE_OPERATION_STATUS', Route_operation_statusTxt);
        CreateMessage(_LanguageCode, 'ROUTE_OPERATION_STATUS_UNFINISHED', Route_operation_status_unfinishedTxt);
        CreateMessage(_LanguageCode, 'NO_OF_LABELS', No_of_labelsTxt);
        CreateMessage(_LanguageCode, 'NO_OF_LABELS_HELP', No_of_labels_helpTxt);
        CreateMessage(_LanguageCode, 'QUANTITY_PER_LABEL', Quantity_per_labelTxt);
        CreateMessage(_LanguageCode, 'QUANTITY_PER_LABEL_HELP', Quantity_per_label_helpTxt);
        CreateMessage(_LanguageCode, 'NUMBER_OF_COPIES', Number_of_copiesTxt);
        CreateMessage(_LanguageCode, 'NUMBER_OF_COPIES_HELP', Number_of_copies_helpTxt);
        CreateMessage(_LanguageCode, 'SHIPMENT_DOCUMENT_STATUS', Shipment_document_statusTxt);
        CreateMessage(_LanguageCode, 'SHIPMENT_DOCUMENT_STATUS_NOT_PICKED', Shipment_document_status_not_pickedTxt);
        CreateMessage(_LanguageCode, 'SHIPMENT_DOCUMENT_STATUS_PARTIALLY_PICKED', Shipment_document_status_partially_pickedTxt);
        CreateMessage(_LanguageCode, 'SHIPMENT_DOCUMENT_STATUS_PARTIALLY_SHIPPED', Shipment_document_status_partially_shippedTxt);
        CreateMessage(_LanguageCode, 'SHIPMENT_DOCUMENT_STATUS_COMPLETELY_PICKED', Shipment_document_status_completely_pickedTxt);
        CreateMessage(_LanguageCode, 'ProdOutputTimeTrackingTitle', ProdOutputTimeTrackingTitleTxt);
        CreateMessage(_LanguageCode, 'ProdOutputFinishOperationTitle', ProdOutputFinishOperationTitleTxt);
        CreateMessage(_LanguageCode, 'START_TIME', Start_timeTxt);
        CreateMessage(_LanguageCode, 'STOP_TIME', Stop_timeTxt);
        CreateMessage(_LanguageCode, 'START_SETUP', Start_setupTxt);
        CreateMessage(_LanguageCode, 'STOP_SETUP', Stop_setupTxt);
        CreateMessage(_LanguageCode, 'START_RUN', Start_runTxt);
        CreateMessage(_LanguageCode, 'STOP_RUN', Stop_runTxt);
        CreateMessage(_LanguageCode, 'QUANTITY_ON_INVENTORY_XY_IS_NOT_SUFFICIENT', Quantity_on_inventory_xy_is_not_sufficientTxt);
        CreateMessage(_LanguageCode, 'PICK_STARTED_TOTE_PICKING_CANNOT_BE_CHANGED', Pick_started_tote_picking_cannot_be_changedTxt);
        CreateMessage(_LanguageCode, 'DELETE_ALL_REGISTRATIONS_AND_TRY_AGAIN', Delete_all_registrations_and_try_againTxt);
        CreateMessage(_LanguageCode, 'ENABLE_TOTE_PICKING', Enable_tote_pickingTxt);
        CreateMessage(_LanguageCode, 'DISABLE_TOTE_PICKING', Disable_tote_pickingTxt);
        CreateMessage(_LanguageCode, 'NO.', NumberTxt);
        CreateMessage(_LanguageCode, 'TYPE', TypeTxt);
        CreateMessage(_LanguageCode, 'SHIPTOADDRESS', ShiptoaddressTxt);
        CreateMessage(_LanguageCode, 'NO_OF_DOCUMENTS', No_of_documentsTxt);
        CreateMessage(_LanguageCode, 'SUGGESTION', SuggestionTxt);

        // >> _History
        CreateMessage(_LanguageCode, 'HISTORY', HISTORY_Txt);                                       // Used in Application.cfg
        CreateMessage(_LanguageCode, 'NO_OF_ENTRIES', No_of_entriesTxt);
        // << _History

        // >> _LicensePlate
        CreateMessage(_LanguageCode, 'MAINMENULPCONTENT', MainMenu_licensePlate_contentTxt);        // Used in Application.cfg
        CreateMessage(_LanguageCode, 'CREATE_LICENSEPLATE', LicensePlate_createTxt);                // Used in Application.cfg
        CreateMessage(_LanguageCode, 'LICENSEPLATE', LicensePlateTxt);
        CreateMessage(_LanguageCode, 'LP', LPTxt);                                                  // Used in Application.cfg
        CreateMessage(_LanguageCode, 'EDIT_LICENSEPLATE', Edit_licensePlateTxt);                    // Used in Application.cfg        
        CreateMessage(_LanguageCode, 'TO_LICENSEPLATE', To_licensePlateTxt);
        CreateMessage(_LanguageCode, 'FROM_LICENSEPLATE', From_licensePlateTxt);
        CreateMessage(_LanguageCode, 'SCAN_FROM_BIN_OR_LP', Scan_From_bin_or_LPTxt);
        CreateMessage(_LanguageCode, 'TO_LICENSEPLATE_HELP', To_licensePlate_helpTxt);
        CreateMessage(_LanguageCode, 'LICENSEPLATE_MUST_BE_EMPTY_ERROR', LicensePlate_must_be_empty_errorTxt);
        CreateMessage(_LanguageCode, 'TOP_LEVEL', Top_levelTxt);
        CreateMessage(_LanguageCode, 'ADD_LICENSEPLATE_HELP', Add_licensePlate_helpTxt);
        CreateMessage(_LanguageCode, 'NO_LICENSE_PLATES_TO_UPDATE', No_licensePlate_to_update_errorTxt);
        CreateMessage(_LanguageCode, 'LICENSEPLATE_COMMENT', LicensePlate_commentTxt);
        CreateMessage(_LanguageCode, 'LICENSEPLATECOMMENT_HELP', LicensePlate_comment_helpTxt);
        CreateMessage(_LanguageCode, 'UNPL_MOVE_COMPLETED_PUTAWAY_REGISTERED', Unpl_move_completed_putaway_registeredTxt);
        CreateMessage(_LanguageCode, 'UNPL_MOVE_ADV_COMPLETED', Unpl_move_adv_completedTxt);
        CreateMessage(_LanguageCode, 'MAINMENUUNPLANNEDMOVEADVANCED', MainMenu_UnplannedMove_AdvancedTxt);
        CreateMessage(_LanguageCode, 'PAGEUNPLANNEDMOVEADVANCEDTITLE', Page_UnplannedMove_Advanced_TitleTxt);
        CreateMessage(_LanguageCode, 'MAINMENUPUTAWAYLICENSEPLATE', MainMenu_PutAway_LicensePlateTxt);
        CreateMessage(_LanguageCode, 'PUTAWAY_NUMBER', PutAwayNumberTxt);
        CreateMessage(_LanguageCode, 'CREATE_NEW_LP_CONFIRM', Create_new_LP_confirmTxt);
        CreateMessage(_LanguageCode, 'BIN_OR_LP_NOT_FOUND', Bin_or_LP_not_foundTxt);
        CreateMessage(_LanguageCode, 'SCAN_INITIAL_BIN_FOR_LP', Scan_initial_bin_for_LPTxt);
        CreateMessage(_LanguageCode, 'PRINT_LP', Print_LPTxt);
        CreateMessage(_LanguageCode, 'START_NEW_LP', Start_New_LPTxt);
        CreateMessage(_LanguageCode, 'LP_NOT_FOUND_ERROR', LP_Not_Found_Err);
        // << _LicensePlate

        // >> _Pack    
        CreateMessage(_LanguageCode, 'PACKING_STATION', Packing_stationTxt);
        CreateMessage(_LanguageCode, 'STAGING_HINT', Staging_hintTxt);
        CreateMessage(_LanguageCode, 'STAGING_HINT_HELP', Staging_hint_helpTxt);
        CreateMessage(_LanguageCode, 'PACKAGE_QTY', Package_qtyTxt);
        CreateMessage(_LanguageCode, 'ITEM_QTY', Item_qtyTxt);
        CreateMessage(_LanguageCode, 'EMPTY', EmptyTxt);
        CreateMessage(_LanguageCode, 'PACKAGE_TYPE', Package_typeTxt);
        CreateMessage(_LanguageCode, 'PACKAGE_TYPE_LABEL', Package_type_labelTxt);
        CreateMessage(_LanguageCode, 'SHIPPING_AGENT_SERVICE_HELP', Shipping_agent_service_helpTxt);
        CreateMessage(_LanguageCode, 'SHIPPING_AGENT_HELP', Shipping_agent_helpTxt);
        CreateMessage(_LanguageCode, 'ENTER_LOAD_METER', Enter_load_meterTxt);
        CreateMessage(_LanguageCode, 'LOAD_METER_LABEL', Load_meterTxt);
        CreateMessage(_LanguageCode, 'MAINMENUPACKING', MainMenu_packingTxt);                       // Used in Application.cfg
        CreateMessage(_LanguageCode, 'PAGEPACKINGTITLE', PackingTxt);                               // Used in Application.cfg
        CreateMessage(_LanguageCode, 'BULKREGISTRATION', LicensePlate_bulkRegistrationTxt);         // Used in Application.cfg
        CreateMessage(_LanguageCode, 'COMBINETONEW', LicensePlate_move_to_newTxt);                  // Used in Application.cfg
        CreateMessage(_LanguageCode, 'ALLCONTENTTONEW', LicensePlate_combine_content_to_newTxt);    // Used in Application.cfg
        CreateMessage(_LanguageCode, 'LICENSEPLATE_CONTENT', LicensePlate_contentTxt);              // Used in Application.cfg
        CreateMessage(_LanguageCode, 'POSTPACKING', PostTxt);                                       // Used in Application.cfg
        CreateMessage(_LanguageCode, 'ADD_LICENSEPLATE', LicensePlate_addTxt);                      // Used in Application.cfg
        CreateMessage(_LanguageCode, 'DELETE_LICENSEPLATE', LicensePlate_deleteTxt);                // Used in Application.cfg
        CreateMessage(_LanguageCode, 'MOVE_LICENSEPLATE', LicensePlate_moveTxt);                    // Used in Application.cfg
        CreateMessage(_LanguageCode, 'LICENSEPLATE_UPDATE_POS', Edit_licensePlateTxt);              // Used in Older Application.cfg files - Mobile Message Retained for Backwards Compatibility
        CreateMessage(_LanguageCode, 'NEW_LICENSEPLATE', New_LicensePlateNoTxt);                    // Used in Application.cfg
        // << _Pack

        GlobalLanguage(MobToolbox.GetLanguageId(SavedLanguage, true));
    end;

    internal procedure CreateMessage(_LanguageCode: Code[10]; _MessageCode: Code[50]; _MessageText: Text[250])
    var
        MobMessage: Record "MOB Message";
    begin
        if MobMessage.Get(_LanguageCode, _MessageCode) then
            exit;

        MobMessage.Validate(Code, _MessageCode);
        MobMessage.Validate("Language Code", _LanguageCode);
        MobMessage.Validate(Message, _MessageText);
        MobMessage.Insert(true);
    end;

    procedure CreateMergeMessage(var _MobMessage: Record "MOB Message"; _LanguageCode: Code[10]; _MessageCode: Code[50]; _MessageText: Text[250])
    begin
        if (_LanguageCode = '') then
            Error(LanguageMustExistErr);

        if not _MobMessage.Get(_LanguageCode, _MessageCode) then
            _MobMessage.Init();

        _MobMessage.Validate(Code, _MessageCode);
        _MobMessage.Validate("Language Code", _LanguageCode);
        _MobMessage.Validate(Message, _MessageText);
        if not _MobMessage.Insert(true) then
            _MobMessage.Modify(true);
    end;

    /// <summary>
    /// If input Mobile Message is the same in ENU, remove the input Mobile Message to prepare for new translation
    /// </summary>    
    internal procedure RemoveMobileMessageIfNotTranslated(_MsgKey: Code[50]; _MsgText: Text[250])
    var
        MobMessage: Record "MOB Message";
        TranslatedMobMessage: Record "MOB Message";
    begin
        if MobMessage.Get('ENU', _MsgText) and TranslatedMobMessage.Get(_MsgKey, _MsgText) then
            if MobMessage.Message = TranslatedMobMessage.Message then
                TranslatedMobMessage.Delete(true);
    end;

    /* #if BC18+ */
    //Recreates the messages when the caption is changed otherwise Package No. is used
    [EventSubscriber(ObjectType::Table, Database::"Inventory Setup", 'OnAfterModifyEvent', '', false, false)]
    local procedure OnAfterModifyCaption(var Rec: Record "Inventory Setup"; var xRec: Record "Inventory Setup")
    var
        MobMessage: Record "MOB Message";
        SavedLanguageID: Integer;
    begin
        if Rec."Package Caption" = xRec."Package Caption" then
            exit;

        SavedLanguageID := GlobalLanguage();

        MobMessage.SetRange(Code, 'PACKAGE_NO_LABEL');
        if MobMessage.FindSet() then
            repeat
                GlobalLanguage(MobToolbox.GetLanguageId(MobMessage."Language Code", true));
                MobMessage.Message := GetPackageNoCaption();
                MobMessage.Modify();
            until MobMessage.Next() = 0;
        GlobalLanguage(SavedLanguageID);
    end;
    /* #endif */

    /* #if BC18+ */
    local procedure GetPackageNoCaption(): Text[250]
    var
        InventorySetup: Record "Inventory Setup";
    begin
        if InventorySetup.Get() and (InventorySetup."Package Caption" <> '') then
            exit(MobTrackingSetup.FieldCaption("Package No."))
        else
            exit(Package_no_labelTxt);
    end;
    /* #endif */
    /* #if BC17- ##
    local procedure GetPackageNoCaption(): Text[250]
    begin
        exit(Package_no_labelTxt);
    end;
    /* #endif */

    [IntegrationEvent(false, false)]
    local procedure OnAddMessages(_LanguageCode: Code[10]; var _Messages: Record "MOB Message")
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnConvertLanguageCodeToDeviceLanguageCode(_LanguageCode: Code[10]; var _DeviceLanguageCode: Code[20]; var _IsHandled: Boolean)
    begin
    end;

}

