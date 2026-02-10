codeunit 81380 "MOB WMS Adhoc Registr."
{
    Access = Public;

    Permissions = tabledata "Whse. Item Tracking Line" = rimd;
    TableNo = "MOB Document Queue";

    trigger OnRun()
    var
        MobWmsLanguage: Codeunit "MOB WMS Language";
    begin
        MobDocQueue := Rec;

        case Rec."Document Type" of

            GetRegistrationConfigurationTok:
                GetRegistrationConfiguration();

            PostAdhocRegistrationTok:
                PostAdhocRegistration();

            else
                Error(MobWmsLanguage.GetMessage('NO_DOC_HANDLER'), Rec."Document Type");
        end;

        // Store the result in the queue and update the status
        Rec := MobDocQueue;
        MobToolbox.UpdateResult(Rec, XmlResponseDoc);
    end;

    var
        MobDocQueue: Record "MOB Document Queue";
        GlobalWarehouseRegister: Record "Warehouse Register";
        MobSessionData: Codeunit "MOB SessionData";
        MobXmlMgt: Codeunit "MOB XML Management";
        MobItemReferenceMgt: Codeunit "MOB Item Reference Mgt.";
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
        MobToolbox: Codeunit "MOB Toolbox";
        MobAvailability: Codeunit "MOB Availability";
        MobWmsAdhocUnplannedMove: Codeunit "MOB WMS Adhoc UnplannedMove";
        MobItemJnlLineReserve: Codeunit "MOB Item Jnl. Line-Reserve";
        MobReportPrintManagement: Codeunit "MOB Report Print Management";
        MobDeviceManagement: Codeunit "MOB Device Management";
        XmlResponseDoc: XmlDocument;
        PostAdhocRegistrationTok: Label 'PostAdhocRegistration', Locked = true;
        GetRegistrationConfigurationTok: Label 'GetRegistrationConfiguration', Locked = true;
        RegistrationTypeTok: Label 'RegistrationType', Locked = true;
        ActionTok: Label 'Action', Locked = true;
        ParameterTok: Label 'Parameter', Locked = true;
        CreatePurchaseOrdersTok: Label 'CreatePurchaseOrders', Locked = true;
#pragma warning disable LC0055 // It's an error message, not a token
        UnknownPrefixErr: Label 'Unknown prefix', Locked = true;
#pragma warning restore LC0055

    local procedure GetRegistrationConfiguration()
    var
        TempHeaderFieldValues: Record "MOB NS Request Element" temporary;
        TempSteps: Record "MOB Steps Element" temporary;
        MobWmsLanguage: Codeunit "MOB WMS Language";
        MobWmsProductionOutput: Codeunit "MOB WMS Production Output";
        MobWmsAssembly: Codeunit "MOB WMS Assembly";
        MobPackingStationMgt: Codeunit "MOB Packing Station Management";
        MobRequestMgt: Codeunit "MOB NS Request Management";
        MobWmsAdhocUnplannedMoveAdvanced: Codeunit "MOB WMS Adhoc Unpl. Move Adv.";
        MobWmsAdhocPutAwayLP: Codeunit "MOB WMS Adhoc Put Away LP";
        XmlRequestDoc: XmlDocument;
        RegistrationType: Text;
        XmlResponseData: XmlNode;
        XmlSteps: XmlNode;
        RegistrationTypeTracking: Text;
        IsHandled: Boolean;
    begin
        // The Request Document looks like this:
        //  <request name="DocumentTypeName"
        //           created="2009-01-20T22:36:34-08:00"
        //           xmlns="http://schemas.microsoft.com/Dynamics/Mobile/2007/04>
        //    <requestData name="DocumentTypeName">
        //      <ParameterName>RE000004</ParameterName>
        //      <RegistrationType>RegistrationType</RegistrationType>
        //    </requestData>
        //  </request>
        //

        // 1. Get any parameters from the XML
        // 2. Perform the business logic
        // 3. Return a response to the mobile device

        // Load the request document from the document queue
        MobDocQueue.LoadXMLRequestDoc(XmlRequestDoc);

        // Read mandatory RegistationType and filtervalues to process, but excluding the RegistrationType-node
        MobRequestMgt.SaveAdhocRequestValues(XmlRequestDoc, TempHeaderFieldValues);
        RegistrationType := TempHeaderFieldValues.GetValue(RegistrationTypeTok, true);

        // Save value to be logged in case of error
        MobSessionData.SetRegistrationType(RegistrationType);

        // Event
        OnGetRegistrationConfiguration_OnBeforeAddSteps(RegistrationType, TempHeaderFieldValues, TempSteps, RegistrationTypeTracking, IsHandled);

        // The GetRegistrationConfiguration function is always called from the "Unplanned Item Registration" screen
        // This screen can be configured to handle many different registration types
        // The registration type is always added as one of the gathered registrations.
        // Use the registration type to forward the call to the appropriate function.
        if not IsHandled then
            case RegistrationType of
                MobWmsToolbox."CONST::UnplannedMove"():
                    RegistrationTypeTracking := MobWmsAdhocUnplannedMove.CreateSteps(TempHeaderFieldValues, TempSteps);

                MobWmsToolbox."CONST::UnplannedMoveAdvanced"(): // UnplannedMove Advanced with support for License Plate
                    RegistrationTypeTracking := MobWmsAdhocUnplannedMoveAdvanced.CreateSteps(TempHeaderFieldValues, TempSteps);

                MobWmsToolbox."CONST::RegisterPutAwayLicensePlate"(): // Register Put Away License Plate
                    RegistrationTypeTracking := MobWmsAdhocPutAwayLP.CreateSteps(TempHeaderFieldValues, TempSteps);

                MobWmsToolbox."CONST::UnplannedCount"():
                    RegistrationTypeTracking := CreateUnplannedCountColConf(TempHeaderFieldValues, TempSteps);

                MobWmsToolbox."CONST::AdjustQuantity"():
                    RegistrationTypeTracking := CreateAdjustQuantityRegColConf(TempHeaderFieldValues, TempSteps);

                MobWmsToolbox."CONST::ItemCrossReference"():
                    RegistrationTypeTracking := CreateItemCrossRefRegColConf(TempHeaderFieldValues, TempSteps);

                MobWmsToolbox."CONST::AddCountLine"():
                    RegistrationTypeTracking := CreateAddCountLineColConf(TempHeaderFieldValues, TempSteps);

                MobWmsToolbox."CONST::ItemDimensions"():
                    RegistrationTypeTracking := CreateItemDimensionsRegColConf(TempHeaderFieldValues, TempSteps);

                MobWmsToolbox."CONST::ToteShipping"():
                    RegistrationTypeTracking := CreateToteShippingRegColConf(TempHeaderFieldValues, TempSteps);

                MobWmsToolbox."CONST::RegisterItemImage"():
                    RegistrationTypeTracking := CreateRegisterItemImageRegColConf(TempHeaderFieldValues, TempSteps);

                MobWmsToolbox."CONST::RegisterImage"():
                    RegistrationTypeTracking := CreateRegisterImageRegColConf(TempHeaderFieldValues, TempSteps);

                MobWmsToolbox."CONST::ProdOutputTimeTracking"(),
                // Intentionally no RegistrationCollectorConfiguration for RegistrationType ProdOutput as PostAdhoc is called from Lookup form
                MobWmsToolbox."CONST::ProdOutputQuantity"(),
                MobWmsToolbox."CONST::ProdOutputTime"(),
                MobWmsToolbox."CONST::ProdOutputScrap"():
                    MobWmsProductionOutput.RunGetRegistrationConfiguration(MobDocQueue, RegistrationType, TempHeaderFieldValues, TempSteps, RegistrationTypeTracking);
                MobWmsToolbox."CONST::ProdUnplannedConsumption"():
                    GetRegistrationConfigProdUnplannedConsumption(TempHeaderFieldValues, TempSteps, RegistrationTypeTracking);
                MobWmsToolbox."CONST::CreateAssemblyOrder"(),
                MobWmsToolbox."CONST::AdjustQtyToAssemble"():
                    MobWmsAssembly.RunGetRegistrationConfiguration(MobDocQueue, RegistrationType, TempHeaderFieldValues, TempSteps, RegistrationTypeTracking);

                MobWmsToolbox."CONST::EditLicensePlate"():
                    MobPackingStationMgt.GetRegistrationConfiguration_EditLicensePlate(MobDocQueue, RegistrationType, TempHeaderFieldValues, TempSteps, RegistrationTypeTracking);
            end;

        // Events for all steps (standard steps as well as custom steps)
        TempSteps.SetMustCallCreateNext(true);
        OnGetRegistrationConfiguration_OnAddSteps(RegistrationType, TempHeaderFieldValues, TempSteps, RegistrationTypeTracking);
        TempSteps.SetMustCallCreateNext(false);
        if TempSteps.FindFirst() then
            repeat
                OnGetRegistrationConfiguration_OnAfterAddStep(RegistrationType, TempHeaderFieldValues, TempSteps);
            until TempSteps.Next() = 0;

        // Initialize the response xml including <registrationCollectorConfiguration><steps> elements
        // It is important that the xmlns="" attribute is not added, because it will prevent the configuration from loading on the mobile device.
        MobToolbox.InitializeRespDocWithoutNS(XmlResponseDoc, XmlResponseData);

        MobToolbox.AddCollectorConfiguration(XmlResponseDoc, TempSteps, XmlSteps);

        MobXmlMgt.AddStepsaddElements(XmlSteps, TempSteps);

        // Add additional steps AsXml (if any)
        IsHandled := not TempSteps.IsEmpty();
        OnGetRegistrationConfigurationOnCustomRegistrationType_OnAddStepsAsXml(XmlRequestDoc, XmlSteps, RegistrationType, RegistrationTypeTracking, IsHandled);

        // Verify handler returned values as expected, either from "framework" subscrbers or AsXml
        if not MobXmlMgt.GetNodeHasChildNodes(XmlSteps) then
            Error(MobWmsLanguage.GetMessage('NO_DOC_HANDLER'), 'GetRegistrationConfiguration::' + RegistrationType + '/XmlSteps');

        // Update the registration type field on the mobile document queue record
        // In case of errors a fallback value is written from MOB WS Dispatcher
        MobDocQueue.SetRegistrationTypeAndTracking(RegistrationType, RegistrationTypeTracking);
    end;

    local procedure PostAdhocRegistration()
    var
        TempRequestValues: Record "MOB NS Request Element" temporary;
        TempCurrentRegistrations: Record "MOB WMS Registration" temporary;
        TempSteps: Record "MOB Steps Element" temporary;
        TempCommands: Record "MOB Command Element" temporary;
        MobWmsLanguage: Codeunit "MOB WMS Language";
        MobRequestMgt: Codeunit "MOB NS Request Management";
        MobWmsProductionConsumption: Codeunit "MOB WMS Production Consumption";
        MobWmsProductionOutput: Codeunit "MOB WMS Production Output";
        MobWmsAssembly: Codeunit "MOB WMS Assembly";
        MobWmsAdhocUnplannedMoveAdvanced: Codeunit "MOB WMS Adhoc Unpl. Move Adv.";
        MobWmsAdhocPutAwayLP: Codeunit "MOB WMS Adhoc Put Away LP";
        MobPrintLicensePlateLabel: Codeunit "MOB Print License Plate Label";
        MobWmsStartLP: Codeunit "MOB WMS Start New LicensePlate";
        XmlRequestDoc: XmlDocument;
        RegistrationType: Text;
        SuccessMessage: Text;
        RegistrationTypeTracking: Text;
        IsHandled: Boolean;
    begin
        // The Request Document looks like this:
        //  <request name="DocumentTypeName"
        //           created="2009-01-20T22:36:34-08:00"
        //           xmlns="http://schemas.microsoft.com/Dynamics/Mobile/2007/04>
        //    <requestData name="DocumentTypeName">
        //      <ParameterName>RE000004</ParameterName>
        //    </requestData>
        //  </request>
        //

        // 1. Get any parameters from the XML
        // 2. Perform the business logic
        // 3. Return a response to the mobile device

        // Load the request document from the document queue
        MobDocQueue.LoadXMLRequestDoc(XmlRequestDoc);

        // Read mandatory RegistationType and filtervalues to process, but excluding the RegistrationType-node
        MobRequestMgt.SaveAdhocRequestValues(XmlRequestDoc, TempRequestValues);
        RegistrationType := TempRequestValues.GetValue(RegistrationTypeTok, true);

        // Save value to be logged in case of error
        MobSessionData.SetRegistrationType(RegistrationType);


        // ------- Interupt Posting and Return steps -------

        // Add additional steps on posting for specific registration types
        if RegistrationType = MobWmsToolbox."CONST::PrintLicensePlate"() then begin
            // Ensure the correct version of the app
            MobDeviceManagement.CheckAppVersionOfCurrentDevice('1.11.9.0', true);
            MobPrintLicensePlateLabel.AddSteps(TempRequestValues, TempSteps);
        end;

        // Add additional steps on posting
        OnPostAdhocRegistration_OnAddSteps(RegistrationType, TempRequestValues, TempSteps, RegistrationTypeTracking);
        if not TempSteps.IsEmpty() then begin
            MobDocQueue.SetRegistrationTypeAndTracking(RegistrationType, 'OnPostAdhocRegistration_OnAddSteps');
            MobToolbox.CreateResponseWithSteps(XmlResponseDoc, TempSteps);
            exit;
        end;

        // -------------------- Posting --------------------

        // The PostAdhocRegistration function is always called from the "Unplanned Item Registration" screen
        // This screen can be configured to handle many different registration types
        // The registration type is always added as one of the gathered registrations.
        // Use the registration type to forward the call to the appropriate posting function.
        Clear(SuccessMessage);
        case RegistrationType of
            MobWmsToolbox."CONST::UnplannedMove"():
                begin
                    MobWmsAdhocUnplannedMove.PostRegistration(TempRequestValues, SuccessMessage, RegistrationTypeTracking);
                    MobToolbox.CreateSimpleResponse(XmlResponseDoc, SuccessMessage);
                end;
            MobWmsToolbox."CONST::UnplannedMoveAdvanced"(): // UnplannedMove with support for License Plate
                begin
                    MobWmsAdhocUnplannedMoveAdvanced.PostRegistration(TempRequestValues, SuccessMessage, RegistrationTypeTracking);
                    MobToolbox.CreateSimpleResponse(XmlResponseDoc, SuccessMessage);
                end;
            MobWmsToolbox."CONST::RegisterPutAwayLicensePlate"(): // Register Put Away License Plate
                begin
                    MobWmsAdhocPutAwayLP.PostRegistration(TempRequestValues, SuccessMessage, RegistrationTypeTracking);
                    MobToolbox.CreateSimpleResponse(XmlResponseDoc, SuccessMessage);
                end;
            MobWmsToolbox."CONST::PrintLicensePlate"():
                begin
                    // If LicensePlate is not available in the request values, we use ToteID instead
                    if (TempRequestValues.Get_LicensePlate() = '') and (TempRequestValues.Get_ToteID() <> '') then
                        TempRequestValues.SetValue('LicensePlate', TempRequestValues.Get_ToteID());

                    PostPrintRegistration(TempRequestValues, XmlResponseDoc, RegistrationTypeTracking);
                end;
            MobWmsToolbox."CONST::UnplannedCount"():
                begin
                    PostUnplannedCountRegistration(TempRequestValues, SuccessMessage, RegistrationTypeTracking);
                    MobToolbox.CreateSimpleResponse(XmlResponseDoc, SuccessMessage);
                end;
            MobWmsToolbox."CONST::AdjustQuantity"():
                begin
                    PostAdjustQuantityRegistration(TempRequestValues, SuccessMessage, RegistrationTypeTracking);
                    MobToolbox.CreateSimpleResponse(XmlResponseDoc, SuccessMessage);
                end;
            MobWmsToolbox."CONST::ItemCrossReference"():
                begin
                    MobItemReferenceMgt.PostItemCrossRefRegistration(TempRequestValues, SuccessMessage, RegistrationTypeTracking);
                    MobToolbox.CreateSimpleResponse(XmlResponseDoc, SuccessMessage);
                end;
            MobWmsToolbox."CONST::PrintLabelTemplate"():
                PostPrintRegistration(TempRequestValues, XmlResponseDoc, RegistrationTypeTracking);

            MobWmsToolbox."CONST::AddCountLine"():
                begin
                    PostAddCountLineRegistration(TempRequestValues, SuccessMessage, RegistrationTypeTracking);
                    MobToolbox.CreateSimpleResponse(XmlResponseDoc, SuccessMessage);
                end;
            MobWmsToolbox."CONST::BulkMove"():
                begin
                    PostBulkMoveRegistration(TempRequestValues, SuccessMessage, RegistrationTypeTracking);
                    MobToolbox.CreateSimpleResponse(XmlResponseDoc, SuccessMessage);
                end;
            MobWmsToolbox."CONST::ItemDimensions"():
                begin
                    PostItemDimensionsRegistration(TempRequestValues, SuccessMessage, RegistrationTypeTracking);
                    MobToolbox.CreateSimpleResponse(XmlResponseDoc, SuccessMessage);
                end;
            MobWmsToolbox."CONST::ToteShipping"():
                begin
                    // Now now, still using XMLRequestDoc since request may have multiple ToteID nodes (is at same childlevel so IS supported RequestValues but will require code refactoring)
                    PostToteShippingRegistration(TempRequestValues, MobDocQueue.MessageIDAsGuid(), XmlRequestDoc, SuccessMessage, RegistrationTypeTracking);
                    MobToolbox.CreateSimpleResponse(XmlResponseDoc, SuccessMessage);
                end;
            MobWmsToolbox."CONST::PostShipment"():
                begin
                    PostShipmentRegistration(TempRequestValues, SuccessMessage, RegistrationTypeTracking);
                    MobToolbox.CreateSimpleResponse(XmlResponseDoc, SuccessMessage);
                end;
            MobWmsToolbox."CONST::RegisterItemImage"():
                begin
                    PostRegisterItemImage(TempRequestValues, SuccessMessage, RegistrationTypeTracking);
                    MobToolbox.CreateSimpleResponse(XmlResponseDoc, SuccessMessage);
                end;
            MobWmsToolbox."CONST::RegisterImage"():
                begin
                    PostRegisterImage(TempRequestValues, SuccessMessage, RegistrationTypeTracking);
                    MobToolbox.CreateSimpleResponse(XmlResponseDoc, SuccessMessage);
                end;
            MobWmsToolbox."CONST::ToggleTotePicking"():
                begin
                    MobWmsToolbox.SaveRegistrationData(MobDocQueue.MessageIDAsGuid(), XmlRequestDoc, TempCurrentRegistrations.Type::CurrentRegistration, TempCurrentRegistrations);
                    PostToggleTotePicking(TempRequestValues, TempCurrentRegistrations, SuccessMessage, RegistrationTypeTracking);
                    MobToolbox.CreateSimpleResponse(XmlResponseDoc, SuccessMessage);
                end;
            MobWmsToolbox."CONST::SubstituteProdOrderComponent"():
                begin
                    MobWmsProductionConsumption.RunPostAdhocRegistration(RegistrationType, TempRequestValues, SuccessMessage, RegistrationTypeTracking);
                    MobToolbox.CreateSimpleResponse(XmlResponseDoc, SuccessMessage);
                end;
            MobWmsToolbox."CONST::ProdOutputTimeTracking"(),
            MobWmsToolbox."CONST::ProdOutput"(),
            MobWmsToolbox."CONST::ProdOutputQuantity"(),
            MobWmsToolbox."CONST::ProdOutputTime"(),
            MobWmsToolbox."CONST::ProdOutputScrap"(),
            MobWmsToolbox."CONST::ProdOutputFinishOperation"():
                begin
                    MobWmsProductionOutput.RunPostAdhocRegistration(MobDocQueue, RegistrationType, TempRequestValues, SuccessMessage, RegistrationTypeTracking);
                    MobToolbox.CreateSimpleResponse(XmlResponseDoc, SuccessMessage);
                end;
            MobWmsToolbox."CONST::ProdUnplannedConsumption"():
                PostProdUnplannedConsumption(TempRequestValues, RegistrationTypeTracking);
            MobWmsToolbox."CONST::CreateAssemblyOrder"(),
            MobWmsToolbox."CONST::AdjustQtyToAssemble"():
                begin
                    MobWmsAssembly.RunPostAdhocRegistration(RegistrationType, TempRequestValues, SuccessMessage, RegistrationTypeTracking);
                    MobToolbox.CreateSimpleResponse(XmlResponseDoc, SuccessMessage);
                end;
            MobWmsToolbox."CONST::Internal"():
                begin
                    Internal(TempRequestValues, SuccessMessage, RegistrationTypeTracking);
                    MobToolbox.CreateSimpleResponse(XmlResponseDoc, SuccessMessage);
                end;
            MobWmsToolbox."CONST::StartNewLicensePlate"():
                begin
                    MobWmsStartLP.AdhocStartNewLicensePlateFromWhseReceipt(RegistrationType, TempRequestValues, TempCommands, SuccessMessage);
                    MobToolbox.CreateSimpleResponseWithCommands(XmlResponseDoc, TempCommands, SuccessMessage);
                end;
            else begin
                // The registration type was not part of the standard solution -> see if a customization exists
                MobToolbox.InitializeQueueResponseDoc(XmlResponseDoc);

                IsHandled := false;
                SuccessMessage := MobWmsLanguage.GetMessage('REG_TRANS_SUCCESS');  // Default message that could be overwritten in the subscriber
                MobWmsToolbox.SaveRegistrationData(MobDocQueue.MessageIDAsGuid(), XmlRequestDoc, TempCurrentRegistrations.Type::CurrentRegistration, TempCurrentRegistrations);

                OnPostAdhocRegistrationOnCustomRegistrationType(MobDocQueue.MessageIDAsGuid(), RegistrationType, TempRequestValues, TempCurrentRegistrations, TempCommands, SuccessMessage, RegistrationTypeTracking, IsHandled);

                // Write SuccessMessage to XmlResponseDoc
                if IsHandled or (SuccessMessage <> '') then
                    if not TempCommands.IsEmpty() then
                        MobToolbox.CreateResponseWithCommands(XmlResponseDoc, TempCommands)
                    else
                        MobToolbox.CreateSimpleResponse(XmlResponseDoc, SuccessMessage);

                // Attempt handle AsXml only if unhandled by no-Xml event
                if not IsHandled then begin
                    OnPostAdhocRegistrationOnCustomRegistrationTypeAsXml(MobDocQueue.MessageIDAsGuid(), XmlRequestDoc, XmlResponseDoc, RegistrationType, RegistrationTypeTracking, IsHandled);
                    if not IsHandled then
                        Error(MobWmsLanguage.GetMessage('NO_DOC_HANDLER'), 'PostAdhocRegistration::' + RegistrationType);
                end;

                // No default SimpleResponse for custom types: custom document handler must create response during handling
                if not MobXmlMgt.GetDocRootNodeHasChildNodes(XmlResponseDoc) then
                    Error(MobWmsLanguage.GetMessage('NO_DOC_HANDLER'), 'PostAdhocRegistration::' + RegistrationType + '/XmlResponseDoc');
            end;
        end;

        OnPostAdhocRegistration_OnAfterPost(MobDocQueue.MessageIDAsGuid(), RegistrationType, TempRequestValues, XmlResponseDoc, RegistrationTypeTracking);

        // Update the registration type field on the mobile document queue record
        // In case of errors a fallback value is written from MOB WS Dispatcher
        MobDocQueue.SetRegistrationTypeAndTracking(RegistrationType, RegistrationTypeTracking);
    end;

    local procedure CreateUnplannedCountColConf(var _HeaderFilter: Record "MOB NS Request Element"; var _Steps: Record "MOB Steps Element") _ReturnRegistrationTypeTracking: Text
    var
        MobSetup: Record "MOB Setup";
        MobTrackingSetup: Record "MOB Tracking Setup";
        Location: Record Location;
        Item: Record Item;
        MobWmsLanguage: Codeunit "MOB WMS Language";
        RegisterExpirationDate: Boolean;
        LocationCode: Code[10];
        ItemNumber: Code[50];
        VariantCode: Code[10];
        UoMCode: Code[10];
    begin
        MobSetup.Get();

        // -- Find the Location and ItemNo
        LocationCode := _HeaderFilter.GetValue('Location', true);
        ItemNumber := MobItemReferenceMgt.SearchItemReference(MobToolbox.ReadEAN(_HeaderFilter.GetValue('Item', true)), VariantCode, UoMCode);

        // Set the tracking value displayed in the document queue
        _ReturnRegistrationTypeTracking := StrSubstNo('%1 - %2', LocationCode, ItemNumber);

        if not Item.Get(ItemNumber) then
            Error(MobWmsLanguage.GetMessage('UNKNOWN_ITEM_NO'), ItemNumber);

        Clear(MobTrackingSetup);
        MobTrackingSetup.DetermineNegAdjustItemTrackingRequired(ItemNumber, RegisterExpirationDate);
        // MobTrackingSetup.Tracking: Tracking values are unused in this scope

        if MobTrackingSetup."Lot No. Required" then begin
            if not Location.Get(LocationCode) then
                //Unplanned count with lot tracking is not supported without location
                Error(MobWmsLanguage.GetMessage('UNPL_COUNT_NO_LOC_NOT_ALLOWED'));
            if Location."Bin Mandatory" then
                if not MobWmsToolbox.WarehouseTrackingEnabled(ItemNumber, 1) then
                    // If item lot tracking are used in combination with bins,its recommended that lot tracking is enabled as well
                    // If warehouse tracking is disabled,the "Item Ledger Entry" will hold information of lot but this informations is not
                    // registred per bin.

                    // This makes it impossible to calculate and create the relevant tracking linies to the journal lines.
                    Error(MobWmsLanguage.GetMessage('UNPL_COUNT_NOWHSE_NOT_ALLOWED'));
        end;
        if MobTrackingSetup."Serial No. Required" then
            Error(MobWmsLanguage.GetMessage('UNPL_COUNT_SERIAL_NOT_ALLOWED'));

        // Add the steps
        CreateUnplannedCountSteps(_Steps, Item, LocationCode, VariantCode, UoMCode, MobTrackingSetup);
    end;

    local procedure CreateUnplannedCountSteps(var _Steps: Record "MOB Steps Element"; _Item: Record Item; _LocationCode: Code[10]; _VariantCode: Code[10]; _UoMCode: Code[10]; _MobTrackingSetup: Record "MOB Tracking Setup")
    var
        MobSetup: Record "MOB Setup";
        ItemVariant: Record "Item Variant";
        MobWmsLanguage: Codeunit "MOB WMS Language";
    begin
        MobSetup.Get();

        // Step: Bin
        if TestBinMandatory(_LocationCode) then
            _Steps.Create_TextStep_Bin(10, _LocationCode, _Item."No.", _VariantCode);

        // Step: Variant
        if _VariantCode = '' then begin
            ItemVariant.Reset();
            ItemVariant.SetRange("Item No.", _Item."No.");
            if not ItemVariant.IsEmpty() then
                _Steps.Create_ListStep_Variant(20, _Item."No.");
        end;

        // Step: UoM
        if (not MobSetup."Use Base Unit of Measure") and (_UoMCode = '') then begin
            _Steps.Create_ListStep_UoM(30, _Item."No.");
            _Steps.Set_defaultValue(_Item."Base Unit of Measure");
            if not MobWmsToolbox.GetItemHasMultipleUoM(_Item."No.") then begin
                _UoMCode := _Item."Base Unit of Measure";
                _Steps.Set_visible(false);
            end;
        end;

        // Step: LotNumber, PackageNumber and custom dimensions (UnplannedCount currently do not support SerialNumber)
        _Steps.Create_TrackingStepsIfRequired(_MobTrackingSetup, 40, _Item."No.");

        // Step: Quantity
        _Steps.Create_DecimalStep_Quantity(70, _Item."No.");
        _Steps.Set_header(MobWmsLanguage.GetMessage('ITEM') + ' ' + _Item."No." + ' - ' + MobWmsLanguage.GetMessage('ENTER_COUNTED_QTY'));
        _Steps.Set_minValue(0); // Counting zero means the bin was empty

        // Show UoM in Quantity help
        if MobSetup."Use Base Unit of Measure" then
            _Steps.Set_helpLabel(MobWmsLanguage.GetMessage('UOM_LABEL') + ': ' + _Item."Base Unit of Measure")
        else
            if _UoMCode <> '' then
                _Steps.Set_helpLabel(MobWmsLanguage.GetMessage('UOM_LABEL') + ': ' + _UoMCode);
    end;

    local procedure PostUnplannedCountRegistration(var _RequestValues: Record "MOB NS Request Element"; var _SuccessMessage: Text; var _ReturnRegistrationTypeTracking: Text)
    var
        MobSetup: Record "MOB Setup";
        MobTrackingSetup: Record "MOB Tracking Setup";
        SourceCode: Record "Source Code";
        Location: Record Location;
        Item: Record Item;
        BinRec: Record Bin;
        BinContent: Record "Bin Content";
        ItemJnlLine2: Record "Item Journal Line";
        ReservationEntry: Record "Reservation Entry";
        ItemUnitofMeasure: Record "Item Unit of Measure";
        ItemJnlLine: Record "Item Journal Line";
        ItemJournalTemplate: Record "Item Journal Template";
        TempWhseJnlLine: Record "Warehouse Journal Line" temporary;
        TempTrackingSpec: Record "Tracking Specification" temporary;
        WMSMgt: Codeunit "WMS Management";
        MobItemTrackingManagement: Codeunit "MOB Item Tracking Management";
        MobTrackingSpecReserve: Codeunit "MOB Tracking Spec-Reserve";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        LocationCode: Code[10];
        Bin: Code[20];
        ScannedBarcode: Code[50];
        ItemNumber: Code[50];
        VariantCode: Code[10];
        UoMCode: Code[10];
        Quantity: Decimal;
        Force: Boolean;
        ActualQty: Decimal;
        ToleranceQty: Decimal;
        RegisterExpirationDate: Boolean;
        ExistingExpDate: Date;
        EntriesExist: Boolean;
        ForceWarningText: Text;
    begin
        MobSetup.Get();

        // The values are added to the relevant journal if they have been registered on the mobile device

        LocationCode := _RequestValues.GetValue('Location', true);
        Bin := MobToolbox.ReadBin(_RequestValues.GetValue('Bin'));
        ScannedBarcode := _RequestValues.GetValue('Item', true);
        Quantity := _RequestValues.GetValueAsDecimal('Quantity', true);
        Force := _RequestValues.GetValueAsBoolean('Force');
        // MobTrackingSetup.TrackingRequired: Determine later when a valid WhseJnlLine."Item No." has been found
        MobTrackingSetup.CopyTrackingFromRequestValues(_RequestValues); // Unplanned Count currently never includes a Serial No. but may include Lot No.

        // Set Item, UoM and Variant from Barcode
        ItemNumber := MobItemReferenceMgt.SearchItemReference(ScannedBarcode, VariantCode, UoMCode);
        // Collected values have priority
        if _RequestValues.HasValue('UoM') then
            UoMCode := _RequestValues.GetValue('UoM');
        if _RequestValues.HasValue('Variant') then
            VariantCode := _RequestValues.GetValue('Variant');


        // Set the tracking value displayed in the document queue
        _ReturnRegistrationTypeTracking :=
            ItemJnlLine.FieldCaption("Location Code") + ' ' +
            LocationCode + ' ' +
            Item.TableCaption() + ' ' +
            ItemNumber + ' ' +
            ItemJnlLine.FieldCaption(Quantity) + ' ' +
            Format(Quantity);

        Item.Get(ItemNumber);
        Location.Get(LocationCode);

        // Testing against reserved quantites on negative adjustment is in PostItemJnlLine and PostWhseJnlLine

        // Check adjustment bin
        if Location."Directed Put-away and Pick" then
            Location.TestField("Adjustment Bin Code");

        // Check source code exist
        if not SourceCode.Get('MOBUCOUNT') then begin
            SourceCode.Code := 'MOBUCOUNT';
            SourceCode.Description := CopyStr(MobWmsLanguage.GetMessage('HANDHELD_UNPLANNED_COUNT'), 1, MaxStrLen(SourceCode.Description));
            SourceCode.Insert();
        end;


        if (not Location."Directed Put-away and Pick") and (UoMCode <> '') then begin
            // Journal line quantity must be in base UoM
            // Adjust quantity to be in base UoM
            ItemUnitofMeasure.Get(ItemNumber, UoMCode);
            ItemUnitofMeasure.TestField("Qty. per Unit of Measure");
            Quantity := Quantity * ItemUnitofMeasure."Qty. per Unit of Measure";
        end;

        //Check if within count tolerance
        if MobSetup."Handheld Enable Count Warning" then begin
            if Bin <> '' then begin
                BinContent.SetRange("Location Code", LocationCode);
                BinContent.SetRange("Bin Code", Bin);
                BinContent.SetRange("Item No.", ItemNumber);
                BinContent.SetRange("Variant Code", VariantCode);
                if Location."Directed Put-away and Pick" then begin
                    if MobSetup."Use Base Unit of Measure" then
                        BinContent.SetRange("Unit of Measure Code", DetermineItemUOM(ItemNumber))
                    else
                        BinContent.SetRange("Unit of Measure Code", UoMCode);
                end else
                    BinContent.SetRange("Unit of Measure Code", WMSMgt.GetBaseUOM(ItemNumber)); // Non directed is always Base UoM                                                    

                MobTrackingSetup.SetTrackingFilterForBinContent(BinContent);
                BinContent.SetAutoCalcFields(Quantity);
                if BinContent.FindFirst() then
                    ActualQty := BinContent.Quantity;
            end else begin
                Item.SetRange("Location Filter", LocationCode);
                Item.SetRange("Variant Filter", VariantCode);
                MobTrackingSetup.SetTrackingFilterForItemIfNotBlank(Item);
                Item.SetAutoCalcFields(Inventory);
                if Item.Get(ItemNumber) then
                    ActualQty := Item.Inventory;
            end;

            ToleranceQty := (ActualQty / 100) * MobSetup."Handheld Count Warning Percent";
            if ToleranceQty < MobSetup."Handheld Count Warn. Min. Qty." then
                ToleranceQty := MobSetup."Handheld Count Warn. Min. Qty.";
            if (Quantity < (ActualQty - ToleranceQty)) or (Quantity > (ActualQty + ToleranceQty)) then
                if not Force then begin
                    ForceWarningText := 'ForceWarning:' + MobWmsLanguage.GetMessage('QUANTITY_ERR');
                    Error(ForceWarningText, Quantity, ActualQty);
                end;
        end;

        if MobSetup."Skip Whse Unpl Count IJ Post" and Location."Directed Put-away and Pick" then begin
            // ------- Post only Warehouse Jnl. -------
            // The posting will generate bin entries to/from the adjustment bin.
            // Periodically G/L must be updated by executing "Calculate Whse. Adjustment" in an item journal.

            // Create Warehouse Journal
            MobSetup.TestField("Whse Inventory Jnl Template");
            Location.TestField("Adjustment Bin Code");
            TempWhseJnlLine.Init();
            TempWhseJnlLine."Journal Template Name" := MobSetup."Whse Inventory Jnl Template";
            TempWhseJnlLine."Journal Batch Name" := MobSetup."Whse. Physical Inventory Batch";
            TempWhseJnlLine."Location Code" := LocationCode;
            TempWhseJnlLine.Validate("Registering Date", WorkDate());
            TempWhseJnlLine."MOB GetWhseDocumentNo"(true);
            TempWhseJnlLine.Validate("Source Code", SourceCode.Code);
            TempWhseJnlLine.Validate("Whse. Document Type", TempWhseJnlLine."Whse. Document Type"::"Whse. Phys. Inventory");
            TempWhseJnlLine."User ID" := UserId();
            TempWhseJnlLine.Validate("Entry Type", TempWhseJnlLine."Entry Type"::"Positive Adjmt.");
            TempWhseJnlLine.Validate("Item No.", ItemNumber);
            TempWhseJnlLine.Validate("Variant Code", VariantCode);
            if MobSetup."Use Base Unit of Measure" then
                TempWhseJnlLine.Validate("Unit of Measure Code", DetermineItemUOM(ItemNumber))
            else
                TempWhseJnlLine.Validate("Unit of Measure Code", UoMCode);

            // Count is always for a specific Location Code meaning this is WhseTracking and never TransferTracking
            MobTrackingSetup.DetermineWhseTrackingRequired(TempWhseJnlLine."Item No.", RegisterExpirationDate);
            // MobTrackingSetup.Tracking: Copied before (during parse of RequestValues)

            if MobTrackingSetup."Lot No. Required" then begin
                // The entered lot number MUST exist (verify indirectly by searching for Open/Closed ItemLedgEntries or WhseEntries that would determine the expiration date).
                // The 'GetWhseExpirationDate' function used below will return if any entries exists for the lot number EVEN if such entries all has a blank expiration date or is closed
                EntriesExist :=
                    MobItemTrackingManagement.GetWhseExpirationDate(
                        TempWhseJnlLine."Item No.",
                        TempWhseJnlLine."Variant Code",
                        Location,
                        MobTrackingSetup,
                        ExistingExpDate);

                // Intentionally less strict validation here than in code for ItemJnlLine further below, as Entry Type is not yet known at this place in the code
                // Relying on standard error message for negative adjustment for a "lotnumber without expiration date" not being on inventory

                if (not EntriesExist) and RegisterExpirationDate then
                    Error(MobWmsLanguage.GetMessage('UNKNOWN_LOT'), MobTrackingSetup."Lot No.",
                                                    MobWmsToolbox.GetItemAndVariantTxt(TempWhseJnlLine."Item No.",
                                                    TempWhseJnlLine."Variant Code"));
                MobTrackingSetup.ValidateTrackingToWhseJnlLineIfRequired(TempWhseJnlLine);

                if RegisterExpirationDate then begin
                    // If expiration date is mandatory use the previously entered expiry date for the lot number
                    if Format(ExistingExpDate) = '' then
                        Error(MobWmsLanguage.GetMessage('WRONG_EXPIRATION_DATE'), MobWmsToolbox.Date2TextAsDisplayFormat(ExistingExpDate), MobTrackingSetup."Lot No.");

                    if TempWhseJnlLine."Expiration Date" <> ExistingExpDate then
                        TempWhseJnlLine."Expiration Date" := ExistingExpDate;
                    if TempWhseJnlLine."New Expiration Date" <> ExistingExpDate then
                        TempWhseJnlLine."New Expiration Date" := ExistingExpDate;
                end;
            end;
            // Set the adjustment bin
            BinRec.Get(Location.Code, Location."Adjustment Bin Code");
            TempWhseJnlLine."From Bin Code" := BinRec.Code;
            TempWhseJnlLine."From Zone Code" := BinRec."Zone Code";
            TempWhseJnlLine."From Bin Type Code" := BinRec."Bin Type Code";
            // Set the counted bin
            BinRec.Get(Location.Code, Bin);
            TempWhseJnlLine.Validate("To Bin Code", BinRec.Code);
            TempWhseJnlLine.Validate("To Zone Code", BinRec."Zone Code");
            TempWhseJnlLine.Validate("Zone Code", BinRec."Zone Code");
            TempWhseJnlLine.Validate("Bin Code", BinRec.Code);
            // Allow entry of quantities
            TempWhseJnlLine."Phys. Inventory" := true;
            // Calculate the quantity on bin
            BinContent.SetRange("Location Code", LocationCode);
            BinContent.SetRange("Bin Code", Bin);
            BinContent.SetRange("Item No.", ItemNumber);
            BinContent.SetRange("Variant Code", VariantCode);
            MobTrackingSetup.SetTrackingFilterForBinContent(BinContent);
            BinContent.SetRange("Unit of Measure Code", TempWhseJnlLine."Unit of Measure Code");
            BinContent.SetAutoCalcFields(Quantity, "Quantity (Base)");
            if BinContent.FindFirst() then begin
                TempWhseJnlLine."Qty. (Calculated)" := BinContent.Quantity;
                TempWhseJnlLine."Qty. (Calculated) (Base)" := BinContent."Quantity (Base)";
            end;
            TempWhseJnlLine.Validate("Qty. (Phys. Inventory)", Quantity);

            // Post the warehouse journal
            OnPostAdhocRegistrationOnUnplannedCount_OnAfterCreateWhseJnlLine(_RequestValues, TempWhseJnlLine);
            RegisterWhseJnlLine(TempWhseJnlLine, 4, false);
        end else begin
            // ------- Post both Item and Warehouse Jnl. -------

            // Step 1: Item Jnl.
            ItemJnlLine.Init();
            ItemJnlLine."Journal Template Name" := MobSetup."Inventory Jnl Template";
            ItemJnlLine."Journal Batch Name" := MobSetup."Physical Inventory Batch";
            ItemJnlLine."Entry Type" := ItemJnlLine."Entry Type"::"Negative Adjmt.";
            ItemJnlLine.Validate("Item No.", ItemNumber);
            ItemJnlLine.Validate("Variant Code", VariantCode);
            ItemJnlLine.Validate("Posting Date", WorkDate());
            ItemJnlLine."MOB GetDocumentNo"(true);
            ItemJnlLine."Source Code" := SourceCode.Code;
            ItemJnlLine.Validate("Location Code", LocationCode);

            if Location."Directed Put-away and Pick" and (not MobSetup."Use Base Unit of Measure") then begin
                if (MobTrackingSetup.TrackingExists()) and
                   (not MobSetup."Skip Whse Unpl Count IJ Post") and
                   (ItemJnlLine."Unit of Measure Code" <> UoMCode)
                then
                    Error(MobWmsLanguage.GetMessage('UnplannedCountDirectedLotItemJnl'),    // "'%2 cannot be %3 when doing an Unplanned Count of Lot Tracked Items in anything but %1'"
                          Item.FieldCaption("Base Unit of Measure"),
                          MobSetup.FieldCaption("Skip Whse Unpl Count IJ Post"),
                          MobSetup."Skip Whse Unpl Count IJ Post");
                ItemJnlLine.Validate("Unit of Measure Code", UoMCode);
            end;

            ItemJnlLine."Phys. Inventory" := true;
            if Bin <> '' then begin
                BinContent.SetRange("Location Code", LocationCode);
                BinContent.SetRange("Bin Code", Bin);
                BinContent.SetRange("Item No.", ItemNumber);
                BinContent.SetRange("Variant Code", VariantCode);
                if Location."Directed Put-away and Pick" then
                    BinContent.SetRange("Unit of Measure Code", ItemJnlLine."Unit of Measure Code") // The bin content uses UoM
                else
                    BinContent.SetRange("Unit of Measure Code", WMSMgt.GetBaseUOM(ItemJnlLine."Item No.")); // Non directed is always Base UoM                    
                MobTrackingSetup.SetTrackingFilterForBinContent(BinContent);
                BinContent.SetAutoCalcFields(Quantity);
                if BinContent.FindFirst() then
                    ItemJnlLine."Qty. (Calculated)" := BinContent.Quantity;
            end else begin
                Item.SetRange("Location Filter", LocationCode);
                Item.SetRange("Variant Filter", VariantCode);
                MobTrackingSetup.SetTrackingFilterForItemIfNotBlank(Item);    // Only set filter when needed, as an empty filter excludes Lot entries set by Outbound Sales tracking 
                Item.SetAutoCalcFields(Inventory);
                if Item.Get(ItemNumber) then
                    ItemJnlLine."Qty. (Calculated)" := Item.Inventory;
            end;

            ItemJnlLine.Validate("Qty. (Phys. Inventory)", Quantity);
            if (Location."Directed Put-away and Pick") and (not MobSetup."Use Base Unit of Measure") then begin
                //UoM was reset when validating "Qty. (Phys. Inventory)"
                ItemJnlLine."Phys. Inventory" := false;
                ItemJnlLine.Validate("Unit of Measure Code", UoMCode);
                ItemJnlLine."Phys. Inventory" := true;
            end;
            ItemJnlLine.Validate("Bin Code", Bin);

            MobTrackingSetup.DetermineNegAdjustItemTrackingRequired(ItemNumber, RegisterExpirationDate);
            // MobTrackingSetup.Tracking: Copied before (during parse of RequestValues)

            if MobTrackingSetup.TrackingRequired() then begin
                // The entered lot number MUST exist (verify indirectly by searching for Open/Closed ItemLedgEntries or WhseEntries that would determine the expiration date).
                // The 'GetWhseExpirationDate' function used below will return if any entries exists for the lot number EVEN if such entries all has a blank expiration date or is closed
                EntriesExist :=
                    MobItemTrackingManagement.GetWhseExpirationDate(
                        ItemJnlLine."Item No.",
                        ItemJnlLine."Variant Code",
                        Location,
                        MobTrackingSetup,
                        ExistingExpDate);

                // Any count for an item requiring ExpirationDate will fail if that date cannot be derived from exiting entries (as date value is not collected from steps)
                // Positive adjustment without RegisterExpirationDate is always possible
                // Negative adjusment will fail if LotNumber is not in inventory
                if (not EntriesExist) and MobTrackingSetup."Lot No. Required" then
                    if (ItemJnlLine."Entry Type" = ItemJnlLine."Entry Type"::"Negative Adjmt.") or
                        ((ItemJnlLine."Entry Type" = ItemJnlLine."Entry Type"::"Positive Adjmt.") and RegisterExpirationDate)
                    then
                        Error(MobWmsLanguage.GetMessage('UNKNOWN_LOT'), MobTrackingSetup."Lot No.",
                                                                        MobWmsToolbox.GetItemAndVariantTxt(ItemJnlLine."Item No.",
                                                                        ItemJnlLine."Variant Code"));
            end;

            MobItemJnlLineReserve.InitFromItemJnlLine(TempTrackingSpec, ItemJnlLine);
            MobTrackingSetup.CopyTrackingToTrackingSpec(TempTrackingSpec);
            TempTrackingSpec."Expiration Date" := 0D;   // Unplanned Count only supported for Tracking already on inventory (Expiration Date is populated from existing entries)

            if TempTrackingSpec.TrackingExists() and (TempTrackingSpec."Quantity (Base)" <> 0) then begin
                MobTrackingSpecReserve.CreateReservation(TempTrackingSpec);
                MobTrackingSpecReserve.GetLastEntry(ReservationEntry);
                MobTrackingSetup.CopyTrackingFromReservEntry(ReservationEntry);
            end;

            // Step 2: Warehouse Jnl.
            OnPostAdhocRegistrationOnUnplannedCount_OnAfterCreateItemJnlLine(_RequestValues, ReservationEntry, ItemJnlLine);
            PostItemJnlLine(ItemJnlLine, ItemJnlLine2);

            if ItemJnlLine."Location Code" <> '' then begin
                Location.Get(ItemJnlLine."Location Code");
                if Location."Bin Mandatory" then begin
                    // When using Directed Put-away and Pick, Zone Code and Bin Code is set to Adjustment bin from Location Card. This must be
                    // overwritten to post on the correct Zone and Bin.
                    MobTrackingSetup.CopyTrackingToItemJnlLine(ItemJnlLine2);
                    ItemJnlLine2."Item Expiration Date" := ReservationEntry."Expiration Date";

                    // Create Warehouse Jnl. based on the Item Jnl.
                    if WMSMgt.CreateWhseJnlLine(ItemJnlLine2, MobToolbox.AsInteger(ItemJournalTemplate.Type::"Phys. Inventory"), TempWhseJnlLine, false) then begin
                        if Location."Directed Put-away and Pick" then begin
                            TempWhseJnlLine."Journal Template Name" := MobSetup."Whse Inventory Jnl Template";
                            TempWhseJnlLine."Journal Batch Name" := MobSetup."Whse. Physical Inventory Batch";
                            TempWhseJnlLine.Validate("Whse. Document Type", TempWhseJnlLine."Whse. Document Type"::"Whse. Phys. Inventory");
                            TempWhseJnlLine."MOB GetWhseDocumentNo"(false);

                            // Trigger warehouse event only for "Directed Put-away and Pick"
                            OnPostAdhocRegistrationOnUnplannedCount_OnAfterCreateWhseJnlLine(_RequestValues, TempWhseJnlLine);

                            // Suppress adjustment bin entries since we do post item journal from our own code
                            if TempWhseJnlLine."Entry Type" = TempWhseJnlLine."Entry Type"::"Positive Adjmt." then begin
                                BinContent.SetRange("Location Code", LocationCode);
                                BinContent.SetRange("Bin Code", Bin);
                                BinContent.SetRange("Item No.", ItemNumber);
                                BinContent.SetRange("Variant Code", VariantCode);
                                MobTrackingSetup.SetTrackingFilterForBinContent(BinContent);
                                if MobSetup."Use Base Unit of Measure" then
                                    BinContent.SetRange("Unit of Measure Code", DetermineItemUOM(ItemNumber))
                                else
                                    BinContent.SetRange("Unit of Measure Code", UoMCode);

                                if BinContent.FindFirst() then begin
                                    BinContent.CheckWhseClass(false);
                                    TempWhseJnlLine.Validate("To Zone Code", BinContent."Zone Code");
                                    TempWhseJnlLine.Validate("To Bin Code", BinContent."Bin Code");
                                    // Validation is deliberately not performed to avoid posting to adjustment bin
                                    TempWhseJnlLine."From Zone Code" := '';
                                    TempWhseJnlLine."From Bin Type Code" := '';
                                    TempWhseJnlLine."From Bin Code" := '';
                                end else begin
                                    BinRec.SetRange("Location Code", LocationCode);
                                    BinRec.SetRange(Code, Bin);
                                    if BinRec.FindFirst() then begin
                                        BinRec.CheckWhseClass(ItemNumber, false);
                                        TempWhseJnlLine.Validate("To Zone Code", BinRec."Zone Code");
                                        TempWhseJnlLine.Validate("To Bin Code", BinRec.Code);
                                        // Validation is deliberately not performed to avoid posting to adjustment bin
                                        TempWhseJnlLine."From Zone Code" := '';
                                        TempWhseJnlLine."From Bin Type Code" := '';
                                        TempWhseJnlLine."From Bin Code" := '';
                                    end;
                                end;
                            end else
                                if TempWhseJnlLine."Entry Type" = TempWhseJnlLine."Entry Type"::"Negative Adjmt." then begin
                                    TempWhseJnlLine.Validate("From Zone Code", BinContent."Zone Code");
                                    TempWhseJnlLine.Validate("From Bin Code", BinContent."Bin Code");
                                    // Validation is deliberately not performed to avoid posting to adjustment bin
                                    TempWhseJnlLine."To Zone Code" := '';
                                    TempWhseJnlLine."To Bin Code" := '';
                                end;
                        end;
                        RegisterWhseJnlLine(TempWhseJnlLine, 4, false);
                    end;
                end;
            end;
        end;

        _SuccessMessage := StrSubstNo(MobWmsLanguage.GetMessage('UNPL_COUNT_COMPLETED'), ItemNumber);
    end;

    /// <summary>
    /// Replaced by procedure DetermineNegAdjustItemTrackingRequired() with parameter "Mob Tracking Setup"  (but not planned for removal for backwards compatibility)
    /// </summary>
    procedure DetermineNegAdjustItemTracking(_ItemNo: Code[20]; var _RegisterSerialNumber: Boolean; var _RegisterLotNumber: Boolean; var _RegisterExpirationDate: Boolean)
    var
        ItemTrackingCode: Record "Item Tracking Code";
        Item: Record Item;
    begin
        _RegisterSerialNumber := false;
        _RegisterLotNumber := false;
        _RegisterExpirationDate := false;

        if Item.Get(_ItemNo) then
            if ItemTrackingCode.Get(Item."Item Tracking Code") then begin
                if ItemTrackingCode."SN Neg. Adjmt. Outb. Tracking" or ItemTrackingCode."SN Neg. Adjmt. Inb. Tracking" then
                    _RegisterSerialNumber := true
                else
                    _RegisterSerialNumber := false;

                if ItemTrackingCode."Lot Neg. Adjmt. Outb. Tracking" or ItemTrackingCode."Lot Neg. Adjmt. Inb. Tracking" then
                    _RegisterLotNumber := true
                else
                    _RegisterLotNumber := false;

                if ItemTrackingCode."Man. Expir. Date Entry Reqd." then
                    _RegisterExpirationDate := true
                else
                    _RegisterExpirationDate := false;
            end;
    end;

    procedure DetermineItemUOM(_ItemNo: Code[20]): Text[10]
    var
        Item: Record Item;
    begin
        if Item.Get(_ItemNo) then
            exit(Item."Base Unit of Measure");
    end;

    local procedure CreateAdjustQuantityRegColConf(var _HeaderFilter: Record "MOB NS Request Element"; var _Steps: Record "MOB Steps Element") _ReturnRegistrationTypeTracking: Text
    var
        Item: Record Item;
        BinContent: Record "Bin Content";
        MobBlankTrackingSetup: Record "MOB Tracking Setup";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        ReservedQtyOnInventory: Decimal;
        QtyOnHand: Decimal;
        LocationCode: Code[10];
        BinCode: Code[20];
        ItemNumber: Code[50];
        VariantCode: Code[10];
        UoMCode: Code[10];
    begin
        // Get Location
        LocationCode := _HeaderFilter.GetValue('Location', true);

        // Get Item - If scanned value is Cross Reference, then get Variant and UoM from that
        ItemNumber := MobItemReferenceMgt.SearchItemReference(MobToolbox.ReadEAN(_HeaderFilter.GetValue('ItemNumber', true)), VariantCode, UoMCode);
        if not Item.Get(ItemNumber) then
            Error(MobWmsLanguage.GetMessage('UNKNOWN_ITEM_NO'), ItemNumber);

        if MobWmsToolbox.LocationIsBinMandatory(LocationCode) then begin
            // Get Bin
            BinCode := MobToolbox.ReadBin(_HeaderFilter.GetValue('Bin'));
            if BinCode = '' then
                Error(MobWmsLanguage.GetMessage('BIN_IS_MANDATORY_ON_LOCATION'), LocationCode);

            // Validate Bin has inventory
            BinContent.Reset();
            BinContent.SetRange("Location Code", LocationCode);
            BinContent.SetRange("Bin Code", BinCode);
            BinContent.SetRange("Item No.", ItemNumber);
            if VariantCode <> '' then
                BinContent.SetRange("Variant Code", VariantCode);
            if BinContent.IsEmpty() then
                Error(MobWmsLanguage.GetMessage('NO_QTY_ON_BIN'), BinCode);
        end else begin
            // Validate Location has inventory
            Clear(MobBlankTrackingSetup);
            MobAvailability.ItemGetAvailability(LocationCode, Item."No.", '', MobBlankTrackingSetup, ReservedQtyOnInventory, QtyOnHand);    // With no variant and blank Tracking Setup (calculating availability regardless of tracking)
            if not (QtyOnHand > 0) then
                Error(MobWmsLanguage.GetMessage('ITEM_NO_QTY_ON_LOCATION'), Item."No.", LocationCode);
        end;

        // Set the tracking value displayed in the document queue
        _ReturnRegistrationTypeTracking := StrSubstNo('%1 - %2 - %3', LocationCode, BinCode, ItemNumber);

        // Add the steps
        CreateAdjustQuantitySteps(_Steps, Item, VariantCode, UoMCode);
    end;

    local procedure CreateAdjustQuantitySteps(var _Steps: Record "MOB Steps Element"; _Item: Record Item; _VariantCode: Code[10]; _UoMCode: Code[10])
    var
        MobSetup: Record "MOB Setup";
        MobTrackingSetup: Record "MOB Tracking Setup";
        ReasonCode: Record "Reason Code";
        ItemVariant: Record "Item Variant";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        RegisterExpirationDate: Boolean;
    begin
        MobSetup.Get();

        Clear(MobTrackingSetup);
        MobTrackingSetup.DetermineNegAdjustItemTrackingRequired(_Item."No.", RegisterExpirationDate);
        // MobTrackingSetup.Tracking: Tracking values are unused in this scope

        // Steps: SerialNumber, LotNumber, PackageNumber and custom tracking dimensions
        _Steps.Create_TrackingStepsIfRequired(MobTrackingSetup, 10, _Item."No.");

        // Step: Variant
        if _VariantCode = '' then begin
            ItemVariant.Reset();
            ItemVariant.SetRange("Item No.", _Item."No.");
            if not ItemVariant.IsEmpty() then
                _Steps.Create_ListStep_Variant(50, _Item."No.");
        end;

        // Step: UoM
        if (not MobSetup."Use Base Unit of Measure") and (_UoMCode = '') then begin
            _Steps.Create_ListStep_UoM(60, _Item."No.");
            _Steps.Set_defaultValue(_Item."Base Unit of Measure");
            if not MobWmsToolbox.GetItemHasMultipleUoM(_Item."No.") then begin
                _UoMCode := _Item."Base Unit of Measure";
                _Steps.Set_visible(false);
            end;
        end;

        // Step: Quantity
        if not MobTrackingSetup."Serial No. Required" then begin
            _Steps.Create_DecimalStep_Quantity(70, _Item."No.");
            _Steps.Set_header(MobWmsLanguage.GetMessage('ENTER_QTY_TO_ADJUST'));
            _Steps.Set_minValue(0.0000000001);

            // Show UoM in Quantity help
            if MobSetup."Use Base Unit of Measure" then
                _Steps.Set_helpLabel(MobWmsLanguage.GetMessage('UOM_LABEL') + ': ' + _Item."Base Unit of Measure")
            else
                if _UoMCode <> '' then
                    _Steps.Set_helpLabel(MobWmsLanguage.GetMessage('UOM_LABEL') + ': ' + _UoMCode);
        end;

        // Step: ReasonCode
        ReasonCode.Reset();
        if not ReasonCode.IsEmpty() then
            _Steps.Create_ListStep_ReasonCode(80, _Item."No.");
    end;

    local procedure PostAdjustQuantityRegistration(var _RequestValues: Record "MOB NS Request Element"; var _SuccessMessage: Text; var _ReturnRegistrationTypeTracking: Text)
    var
        MobSetup: Record "MOB Setup";
        MobTrackingSetup: Record "MOB Tracking Setup";
        SourceCode: Record "Source Code";
        Item: Record Item;
        BinRec: Record Bin;
        Location: Record Location;
        ItemUnitofMeasure: Record "Item Unit of Measure";
        BinContent: Record "Bin Content";
        ItemJnlLine: Record "Item Journal Line";
        ItemJnlLine2: Record "Item Journal Line";
        ItemJournalTemplate: Record "Item Journal Template";
        TempWhseJnlLine: Record "Warehouse Journal Line" temporary;
        ReservationEntry: Record "Reservation Entry";
        TempTrackingSpec: Record "Tracking Specification" temporary;
        MobItemTrackingManagement: Codeunit "MOB Item Tracking Management";
        MobTrackingSpecReserve: Codeunit "MOB Tracking Spec-Reserve";
        WMSMgt: Codeunit "WMS Management";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        LocationCode: Code[10];
        ReasonCode: Code[10];
        Bin: Code[20];
        ScannedBarcode: Code[50];
        ItemNumber: Code[50];
        VariantCode: Code[10];
        UoMCode: Code[10];
        Quantity: Decimal;
        RegisterExpirationDate: Boolean;
        ExistingExpDate: Date;
        QtyBase: Decimal;
    begin
        MobSetup.Get();

        // The values are added to the relevant journal if they have been registered on the mobile device

        LocationCode := _RequestValues.GetValue('Location', true);
        Bin := MobToolbox.ReadBin(_RequestValues.GetValue('Bin'));
        ScannedBarcode := _RequestValues.GetValue('ItemNumber', true);
        Quantity := _RequestValues.GetValueAsDecimal('Quantity');
        ReasonCode := _RequestValues.GetValue('ReasonCode');
        // MobTrackingSetup.TrackingRequired: Determine later when a valid Item No. has been found
        MobTrackingSetup.CopyTrackingFromRequestValues(_RequestValues); // LotNumber, SerialNumber, PackageNumber

        // Set Item, UoM and Variant from Barcode
        ItemNumber := MobItemReferenceMgt.SearchItemReference(ScannedBarcode, VariantCode, UoMCode);
        // Collected values have priority
        if _RequestValues.HasValue('UoM') then
            UoMCode := _RequestValues.GetValue('UoM');
        if _RequestValues.HasValue('Variant') then
            VariantCode := _RequestValues.GetValue('Variant');

        // Set the tracking value displayed in the document queue
        _ReturnRegistrationTypeTracking :=
            ItemJnlLine.FieldCaption("Location Code") + ' ' +
            LocationCode + ' ' +
            Item.TableCaption() + ' ' +
            ItemNumber + ' ' +
            ItemJnlLine.FieldCaption(Quantity) + ' ' +
            Format(Quantity);

        // When using Serial Number Quantity is always = 1
        if MobTrackingSetup."Serial No." <> '' then
            Quantity := 1;

        Item.SetFilter("Location Filter", LocationCode);
        Item.SetFilter("Variant Filter", VariantCode);
        MobTrackingSetup.SetTrackingFilterForItem(Item);
        Item.SetAutoCalcFields("Reserved Qty. on Inventory", Inventory);
        Item.Get(ItemNumber);

        if UoMCode <> '' then begin
            ItemUnitofMeasure.Get(ItemNumber, UoMCode);
            ItemUnitofMeasure.TestField("Qty. per Unit of Measure");
            QtyBase := Quantity * ItemUnitofMeasure."Qty. per Unit of Measure";
        end else
            QtyBase := Quantity;

        if MobSetup."Block Neg. Adj. if Resv Exists" and (not MobSetup."Skip Whse Unpl Count IJ Post") then
            if Item."Reserved Qty. on Inventory" > (Item.Inventory - QtyBase) then
                Error(MobWmsLanguage.GetMessage('REMOVE_QTY_EXCEEDS_RESERVATIONS'),
                                                Item."Reserved Qty. on Inventory", Item."Base Unit of Measure");

        // Make sure that the MOBISSUE source code exist (for tracking purposes)
        if not SourceCode.Get('MOBADJQTY') then begin
            SourceCode.Code := 'MOBADJQTY';
            SourceCode.Description := CopyStr(MobWmsLanguage.GetMessage('HANDHELD_ADJUST_QUANTITY'), 1, MaxStrLen(SourceCode.Description));
            SourceCode.Insert();
        end;

        Location.Get(LocationCode);
        if (MobSetup."Skip Whse Unpl Count IJ Post") and Location."Directed Put-away and Pick" then begin
            // ------- Post only Warehouse Jnl. -------
            // The posting will generate bin entries to/from the adjustment bin.
            // Periodically G/L must be updated by executing "Calculate Whse. Adjustment" in an item journal.

            // Create Warehouse Journal
            MobSetup.TestField("Warehouse Jnl. Template"); // Journal Template is mandatory, while the newer Journal Batch field is not
            Location.TestField("Adjustment Bin Code");
            TempWhseJnlLine.Init();
            TempWhseJnlLine."Journal Template Name" := MobSetup."Warehouse Jnl. Template";
            TempWhseJnlLine."Journal Batch Name" := MobSetup."Warehouse Jnl. Batch";
            TempWhseJnlLine."Location Code" := LocationCode;
            TempWhseJnlLine.Validate("Registering Date", WorkDate());
            TempWhseJnlLine."MOB GetWhseDocumentNo"(true);
            TempWhseJnlLine.Validate("Source Code", SourceCode.Code);
            TempWhseJnlLine.Validate("Whse. Document Type", TempWhseJnlLine."Whse. Document Type"::"Whse. Phys. Inventory");
            TempWhseJnlLine."User ID" := UserId();
            TempWhseJnlLine.Validate("Entry Type", TempWhseJnlLine."Entry Type"::"Positive Adjmt.");
            TempWhseJnlLine.Validate("Item No.", ItemNumber);
            TempWhseJnlLine.Validate("Variant Code", VariantCode);
            TempWhseJnlLine.Validate("Reason Code", ReasonCode);
            if MobSetup."Use Base Unit of Measure" then
                TempWhseJnlLine.Validate("Unit of Measure Code", DetermineItemUOM(ItemNumber))
            else
                TempWhseJnlLine.Validate("Unit of Measure Code", UoMCode);

            // AdjustQuantity is always for a specific Location Code meaning this is WhseTracking and never TransferTracking
            MobTrackingSetup.DetermineWhseTrackingRequired(TempWhseJnlLine."Item No.", RegisterExpirationDate);
            // MobTrackingSetup.Tracking: Copied before (during parse of RequestValues)

            MobTrackingSetup.ValidateTrackingToWhseJnlLineIfRequired(TempWhseJnlLine);

            if MobTrackingSetup."Lot No. Required" then begin
                MobTrackingSetup.CheckLotNoOnInventory(TempWhseJnlLine."Item No.", TempWhseJnlLine."Variant Code");

                if RegisterExpirationDate then begin
                    MobItemTrackingManagement.GetWhseExpirationDate(TempWhseJnlLine."Item No.", TempWhseJnlLine."Variant Code", Location, MobTrackingSetup, ExistingExpDate);
                    if Format(ExistingExpDate) = '' then
                        Error(MobWmsLanguage.GetMessage('WRONG_EXPIRATION_DATE'), MobWmsToolbox.Date2TextAsDisplayFormat(ExistingExpDate), MobTrackingSetup."Lot No.");  // 'The Expiration Date must be %1 for Lot No. %2'

                    if TempWhseJnlLine."Expiration Date" <> ExistingExpDate then
                        TempWhseJnlLine."Expiration Date" := ExistingExpDate;
                    if TempWhseJnlLine."New Expiration Date" <> ExistingExpDate then
                        TempWhseJnlLine."New Expiration Date" := ExistingExpDate;
                end;
            end;

            // Find BinContent to check if it is possible to remove quantity
            if Bin <> '' then begin
                BinContent.SetRange("Location Code", LocationCode);
                BinContent.SetRange("Bin Code", Bin);
                BinContent.SetRange("Item No.", ItemNumber);
                BinContent.SetRange("Variant Code", VariantCode);
                BinContent.SetRange("Unit of Measure Code", TempWhseJnlLine."Unit of Measure Code");
                BinContent.SetAutoCalcFields(Quantity, "Quantity (Base)");
                if BinContent.FindFirst() then begin
                    if BinContent."Quantity (Base)" < QtyBase then
                        Error(MobWmsLanguage.GetMessage('INSUFFICIENT_STOCK_QTY'), BinContent.Quantity, BinContent."Unit of Measure Code");
                end else
                    Error(MobWmsLanguage.GetMessage('NO_QTY_ON_BIN'), Bin);
            end;
            // Set the adjustment bin
            BinRec.Get(Location.Code, Location."Adjustment Bin Code");
            TempWhseJnlLine."From Bin Code" := BinRec.Code;
            TempWhseJnlLine."From Zone Code" := BinRec."Zone Code";
            TempWhseJnlLine."From Bin Type Code" := BinRec."Bin Type Code";
            // Set the counted bin
            BinRec.Get(Location.Code, Bin);
            TempWhseJnlLine.Validate("To Bin Code", BinRec.Code);
            TempWhseJnlLine.Validate("To Zone Code", BinRec."Zone Code");
            TempWhseJnlLine.Validate("Zone Code", BinRec."Zone Code");
            TempWhseJnlLine.Validate("Bin Code", BinRec.Code);
            // Allow entry of quantities
            TempWhseJnlLine."Phys. Inventory" := true;
            // Calculate the quantity on bin
            BinContent.SetRange("Location Code", LocationCode);
            BinContent.SetRange("Bin Code", Bin);
            BinContent.SetRange("Item No.", ItemNumber);
            BinContent.SetRange("Variant Code", VariantCode);
            MobTrackingSetup.SetTrackingFilterForBinContent(BinContent);
            BinContent.SetRange("Unit of Measure Code", TempWhseJnlLine."Unit of Measure Code");
            BinContent.SetAutoCalcFields(Quantity, "Quantity (Base)");
            if BinContent.FindFirst() then begin
                TempWhseJnlLine."Qty. (Calculated)" := BinContent.Quantity;
                TempWhseJnlLine."Qty. (Calculated) (Base)" := BinContent."Quantity (Base)";
            end;
            TempWhseJnlLine.Validate("Qty. (Phys. Inventory)", BinContent.Quantity - Quantity);
            // Post the warehouse journal
            OnPostAdhocRegistrationOnAdjustQuantity_OnAfterCreateWhseJnlLine(_RequestValues, TempWhseJnlLine);
            RegisterWhseJnlLine(TempWhseJnlLine, 4, false);
        end else begin
            // ------- Post both Item and Warehouse Jnl. -------

            // Step 1: Item Jnl.
            ItemJnlLine.Init();
            ItemJnlLine."Journal Template Name" := MobSetup."Item Jnl. Template";
            ItemJnlLine."Journal Batch Name" := MobSetup."Item Jnl. Batch";

            ItemJnlLine."Entry Type" := ItemJnlLine."Entry Type"::"Negative Adjmt.";
            ItemJnlLine.Validate("Item No.", ItemNumber);
            ItemJnlLine.Validate("Variant Code", VariantCode);
            ItemJnlLine.Validate("Posting Date", WorkDate());
            ItemJnlLine."MOB GetDocumentNo"(true);
            ItemJnlLine."Source Code" := SourceCode.Code;
            ItemJnlLine.Validate("Location Code", LocationCode);
            if MobSetup."Use Base Unit of Measure" then
                ItemJnlLine.Validate("Unit of Measure Code", DetermineItemUOM(ItemNumber))
            else
                ItemJnlLine.Validate("Unit of Measure Code", UoMCode);

            ItemJnlLine.Validate(Quantity, Quantity);
            ItemJnlLine.Validate("Reason Code", ReasonCode);

            // Find BinContent to check if it is possible to remove quantity
            if Bin <> '' then begin
                BinContent.SetRange("Location Code", LocationCode);
                BinContent.SetRange("Bin Code", Bin);
                BinContent.SetRange("Item No.", ItemNumber);
                BinContent.SetRange("Variant Code", VariantCode);
                if Location."Directed Put-away and Pick" then
                    BinContent.SetRange("Unit of Measure Code", ItemJnlLine."Unit of Measure Code")
                else
                    BinContent.SetRange("Unit of Measure Code", WMSMgt.GetBaseUOM(ItemJnlLine."Item No.")); // Non directed is always Base UoM
                BinContent.SetAutoCalcFields(Quantity, "Quantity (Base)");
                if BinContent.FindFirst() then
                    if BinContent."Quantity (Base)" < QtyBase then  // Compare base with base
                        Error(MobWmsLanguage.GetMessage('INSUFFICIENT_STOCK_QTY'), BinContent.Quantity, BinContent."Unit of Measure Code")
                    else
                        ItemJnlLine.Validate("Bin Code", Bin)
                else
                    Error(MobWmsLanguage.GetMessage('NO_QTY_ON_BIN'), Bin);
            end;

            // Determine if item tracking is needed
            // No -> just post
            // Yes -> create reservation entries for the line
            MobTrackingSetup.DetermineNegAdjustItemTrackingRequired(ItemJnlLine."Item No.", RegisterExpirationDate);
            // MobTrackingSetup.Tracking: Copied before (during parse of RequestValues)

            // Make sure that the tracking exists on inventory
            MobTrackingSetup.CheckTrackingOnInventoryIfRequired(ItemJnlLine."Item No.", ItemJnlLine."Variant Code");

            MobItemJnlLineReserve.InitFromItemJnlLine(TempTrackingSpec, ItemJnlLine);
            MobTrackingSetup.CopyTrackingToTrackingSpec(TempTrackingSpec);
            TempTrackingSpec."Expiration Date" := 0D;   // Adjust Quantity only supported for Tracking already on inventory (Expiration Date is populated from existing entries)

            if TempTrackingSpec.TrackingExists() then begin
                MobTrackingSpecReserve.CreateReservation(TempTrackingSpec);
                MobTrackingSpecReserve.GetLastEntry(ReservationEntry);
                MobTrackingSetup.CopyTrackingFromReservEntry(ReservationEntry);
            end;

            // Step 2: Warehouse Jnl.
            OnPostAdhocRegistrationOnAdjustQuantity_OnAfterCreateItemJnlLine(_RequestValues, ReservationEntry, ItemJnlLine);
            PostItemJnlLine(ItemJnlLine, ItemJnlLine2);

            if ItemJnlLine."Location Code" <> '' then begin
                Location.Get(ItemJnlLine."Location Code");
                if Location."Bin Mandatory" then begin
                    // When using Directed Put-away and Pick, Zone Code and Bin Code is set to Adjustment bin from Location Card. This must be
                    // overwritten to post on the correct Zone and Bin.
                    MobTrackingSetup.CopyTrackingToItemJnlLine(ItemJnlLine2);
                    ItemJnlLine2."Item Expiration Date" := ReservationEntry."Expiration Date";

                    // Create Warehouse Jnl. based on the Item Jnl.
                    if WMSMgt.CreateWhseJnlLine(ItemJnlLine2, MobToolbox.AsInteger(ItemJournalTemplate.Type::Item), TempWhseJnlLine, false) then begin
                        if Location."Directed Put-away and Pick" then begin
                            MobSetup.TestField("Warehouse Jnl. Template"); // Journal Template is mandatory, while the newer Journal Batch is not
                            TempWhseJnlLine."Journal Template Name" := MobSetup."Warehouse Jnl. Template";
                            TempWhseJnlLine."Journal Batch Name" := MobSetup."Warehouse Jnl. Batch";
                            TempWhseJnlLine.Validate("Whse. Document Type", TempWhseJnlLine."Whse. Document Type"::"Whse. Journal");
                            TempWhseJnlLine."MOB GetWhseDocumentNo"(false);

                            if TempWhseJnlLine."Entry Type" = TempWhseJnlLine."Entry Type"::"Positive Adjmt." then begin
                                TempWhseJnlLine.Validate("To Zone Code", BinContent."Zone Code");
                                TempWhseJnlLine.Validate("To Bin Code", BinContent."Bin Code");
                                // Validation deliberately not performed to avoid posting to adjustment bin
                                TempWhseJnlLine."From Zone Code" := '';
                                TempWhseJnlLine."From Bin Type Code" := '';
                                TempWhseJnlLine."From Bin Code" := '';
                            end else
                                if TempWhseJnlLine."Entry Type" = TempWhseJnlLine."Entry Type"::"Negative Adjmt." then begin
                                    TempWhseJnlLine.Validate("From Zone Code", BinContent."Zone Code");
                                    TempWhseJnlLine.Validate("From Bin Code", BinContent."Bin Code");
                                    // Validation deliberately not performed to avoid posting to adjustment bin
                                    TempWhseJnlLine."To Zone Code" := '';
                                    TempWhseJnlLine."To Bin Code" := '';
                                end;
                        end;
                        OnPostAdhocRegistrationOnAdjustQuantity_OnAfterCreateWhseJnlLine(_RequestValues, TempWhseJnlLine);
                        RegisterWhseJnlLine(TempWhseJnlLine, 4, false);
                    end;
                end;
            end;
        end;

        _SuccessMessage := StrSubstNo(MobWmsLanguage.GetMessage('ADJUST_QTY_COMPLETED'), ItemNumber);
    end;

    local procedure CreateItemCrossRefRegColConf(var _HeaderFilter: Record "MOB NS Request Element"; var _Steps: Record "MOB Steps Element") _ReturnRegistrationTypeTracking: Text
    var
        ItemNo: Code[20];
    begin
        // Find the item parameter
        ItemNo := MobWmsToolbox.GetItemNumber(_HeaderFilter.GetValue('ItemNumber', true));

        // Set the tracking value displayed in the document queue
        _ReturnRegistrationTypeTracking := ItemNo;

        // Add the steps
        CreateItemCrossRefSteps(_Steps, ItemNo);
    end;

    local procedure CreateItemCrossRefSteps(var _Steps: Record "MOB Steps Element"; _ItemNo: Code[20])
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ItemVariant: Record "Item Variant";
        MobSetup: Record "MOB Setup";
    begin
        MobSetup.Get();
        Item.Get(_ItemNo);

        // Step: Barcode
        _Steps.Create_TextStep_Barcode(10, _ItemNo);

        // Step: UoM
        ItemUnitOfMeasure.SetRange("Item No.", Item."No.");
        if ItemUnitOfMeasure.Count() > 1 then begin
            _Steps.Create_ListStep_UoM(20, _ItemNo);
            _Steps.Set_defaultValue(Item."Base Unit of Measure");
        end;

        // Step: Variant
        ItemVariant.Reset();
        ItemVariant.SetRange("Item No.", _ItemNo);
        if not ItemVariant.IsEmpty() then
            _Steps.Create_ListStep_Variant(30, _ItemNo);

    end;

    procedure TestBinMandatory(_LocationCode: Code[10]): Boolean
    var
        Location: Record Location;
    begin
        if Location.Get(_LocationCode) then
            exit(Location."Bin Mandatory")
        else
            exit(false);
    end;

    /// <summary>
    /// Replaced by procedures MobTrackingSetup.DetermineWhseTrackingRequired and MobTrackingSetup.DetermineTransferTrackingRequired (but kept for backwards compatibility). Could potentially be used in a lot of customizations.
    /// </summary>
    procedure DetermineUnpMoveItemTracking(_ItemNo: Code[20]; var _RegisterSerialNumber: Boolean; var _RegisterLotNumber: Boolean; var _RegisterExpirationDate: Boolean)
    var
        ItemTrackingCode: Record "Item Tracking Code";
        Item: Record Item;
    begin
        _RegisterSerialNumber := false;
        _RegisterLotNumber := false;
        _RegisterExpirationDate := false;

        if Item.Get(_ItemNo) then
            if ItemTrackingCode.Get(Item."Item Tracking Code") then begin
                if ItemTrackingCode."SN Warehouse Tracking" then
                    _RegisterSerialNumber := (ItemTrackingCode."SN Neg. Adjmt. Outb. Tracking" or ItemTrackingCode."SN Neg. Adjmt. Inb. Tracking");

                if ItemTrackingCode."Lot Warehouse Tracking" then
                    _RegisterLotNumber := (ItemTrackingCode."Lot Neg. Adjmt. Outb. Tracking" or ItemTrackingCode."Lot Neg. Adjmt. Inb. Tracking");

                if _RegisterSerialNumber or _RegisterLotNumber then
                    _RegisterExpirationDate := ItemTrackingCode."Man. Expir. Date Entry Reqd.";
            end;
    end;

    local procedure PostPrintLabelTemplateRegistration(var _TempRequestElementsAndSteps: Record "MOB NS Request Element" temporary; var _XmlResponseDoc: XmlDocument; var _ReturnRegistrationTypeTracking: Text[200])
    var
        MobPrinter: Record "MOB Printer";
        MobLabelTemplate: Record "MOB Label-Template";
        TempPrintParameter: Record "MOB Print REST Parameter" temporary;
        MobPrintBuffer: Codeunit "MOB Print Buffer";
        FileManagement: Codeunit "File Management";
        MobPrint: Codeunit "MOB Print";
        SourceRecRef: RecordRef;
        PrintCommand: Text;
    begin
        // Create Response with a Print Command (label) via Print service, to a Bluetooth or Network printer

        // Get context from ReferenceID
        MobToolbox.ReferenceIDText2RecRef(_TempRequestElementsAndSteps.GetValue('ReferenceID'), SourceRecRef);

        // Print from Main Menu uses "Label-Template" as ReferenceId
        if SourceRecRef.Number() = Database::"MOB Label-Template" then
            MobItemReferenceMgt.SearchItemReference(_TempRequestElementsAndSteps.GetValue('ItemNumber'), SourceRecRef, true); // Item No. is collected in header

        TempPrintParameter.Printer := CopyStr(_TempRequestElementsAndSteps.GetValue('Printer'), 1, MaxStrLen(TempPrintParameter.Printer)); // Printer is collect as Step

        TempPrintParameter."Label-Template Name" := CopyStr(_TempRequestElementsAndSteps.GetValue('LabelTemplate'), 1, MaxStrLen(TempPrintParameter."Label-Template Name")); // LabelTemplate is transferred from lookup-response

        // Save value to be logged in case of error
        MobLabelTemplate.Get(TempPrintParameter."Label-Template Name");
        _ReturnRegistrationTypeTracking := CopyStr(StrSubstNo('%1 [%2]', TempPrintParameter."Label-Template Name", FileManagement.GetFileName(MobLabelTemplate."URL Mapping")), 1, MaxStrLen(_ReturnRegistrationTypeTracking)); // Using GetFileName() to avoid logging the full path
        MobSessionData.SetRegistrationTypeTracking(_ReturnRegistrationTypeTracking);   // Save value to be logged in case of error

        // -- Print via "Print service"
        TempPrintParameter."Message ID" := MobDocQueue."Message ID";
        TempPrintParameter."Device ID" := MobDocQueue."Device ID";

        // Note how steps are transferred to print service
        MobPrint.CreateMobilePrint(SourceRecRef, _TempRequestElementsAndSteps, TempPrintParameter);

        // Get printcommand response from print service
        TempPrintParameter.GetResponseContentAsBase64Text(PrintCommand);

        // Set printer
        MobPrint.GetPrinterFromName(MobPrinter, TempPrintParameter.Printer);

        // Add printcommand to buffer
        MobPrintBuffer.Add(MobPrinter.Address, PrintCommand);

        // -- Respond to mobile
        MobToolbox.CreateSimpleResponse(_XmlResponseDoc, '');
    end;

    local procedure PostPrintReportRegistration(var _RequestValues: Record "MOB NS Request Element" temporary; var _XmlResponseDoc: XmlDocument; var _ReturnRegistrationTypeTracking: Text[200])
    var
        MobReport: Record "MOB Report";
        MobReportParametersMgt: Codeunit "MOB ReportParameters Mgt.";
        SourceRecRef: RecordRef;
        ReportPrinter: Text[250];
        ReportDisplayName: Text[50];
        ReportParameters: Text;
    begin
        // Get source record ref from ReferenceID
        MobToolbox.ReferenceIDText2RecRef(_RequestValues.GetValue('ReferenceID'), SourceRecRef);

        ReportPrinter := CopyStr(_RequestValues.GetValue('ReportPrinter'), 1, MaxStrLen(ReportPrinter));
        ReportDisplayName := CopyStr(_RequestValues.GetValue('ReportDisplayName'), 1, MaxStrLen(ReportDisplayName));

        // Get report
        MobReport.Get(ReportDisplayName);

        // Event to adjust report-id and layout before proceeding with the MOB Report
        MobReportPrintManagement.OnPostPrintReport_OnAfterGetMobReport(_RequestValues, SourceRecRef, ReportPrinter, MobReport);

        // Save value to be logged in case of error (The Layout can be blank and it will then print the default layout)
        _ReturnRegistrationTypeTracking := CopyStr(StrSubstNo('%1 [%2:%3]', ReportDisplayName, MobReport."Report ID", MobReport.GetLayout()), 1, MaxStrLen(_ReturnRegistrationTypeTracking));
        MobSessionData.SetRegistrationTypeTracking(_ReturnRegistrationTypeTracking);

        // Validate report no.
        MobReport.TestField("Report ID");

        // Generate report request page parameters and execute print
        ReportParameters := MobReportParametersMgt.CreateReportParameters(MobReport, SourceRecRef, _RequestValues);

        // Print the report with the requested (or default) layout
        MobReport.Print(ReportParameters, ReportPrinter);

        // Respond to mobile 
        MobToolbox.CreateSimpleResponse(_XmlResponseDoc, '');
    end;

    local procedure PostPrintRegistration(var _RequestValues: Record "MOB NS Request Element"; var _XmlResponseDoc: XmlDocument; var _ReturnRegistrationTypeTracking: Text[200])
    begin
        case true of
            _RequestValues.GetValue('ReportDisplayName') <> '':
                PostPrintReportRegistration(_RequestValues, _XmlResponseDoc, _ReturnRegistrationTypeTracking);
            _RequestValues.GetValue('LabelTemplate') <> '':
                PostPrintLabelTemplateRegistration(_RequestValues, _XmlResponseDoc, _ReturnRegistrationTypeTracking);
        end;
    end;

    local procedure PostAddCountLineRegistration(var _RequestValues: Record "MOB NS Request Element"; var _SuccessMessage: Text; var _ReturnRegistrationTypeTracking: Text)
    var
        MobSetup: Record "MOB Setup";
        MobTrackingSetup: Record "MOB Tracking Setup";
        Item: Record Item;
        Location: Record Location;
        BinRec: Record Bin;
        BinContent: Record "Bin Content";
        ItemJnlBatch: Record "Item Journal Batch";
        WhseJnlBatch: Record "Warehouse Journal Batch";
        ItemJnlLine: Record "Item Journal Line";
        ItemJnlLine2: Record "Item Journal Line";
        WhseJnlLine: Record "Warehouse Journal Line";
        WhseJnlLine2: Record "Warehouse Journal Line";
        MobItemTrackingManagement: Codeunit "MOB Item Tracking Management";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        UoMCode: Code[10];
        LocationCode: Code[10];
        Bin: Code[20];
        ScannedBarcode: Code[50];
        ItemNumber: Code[50];
        VariantCode: Code[10];
        CombinedBatchName: Code[40];
        Prefix: Code[10];
        BatchName: Code[10];
        BatchLocationCode: Code[10];
        RegisterExpirationDate: Boolean;
        ExpirationDate: Date;
        ScannedExpirationDate: Date;
        EntriesExist: Boolean;
    begin
        // This function adds a line to an existing phys. invt. journal
        // It supports both the "Whse. Phys. Invt. Journal" and the "Phys. Invt. Journal"
        // The values are added to the relevant journal if they have been registered on the mobile device

        CombinedBatchName := _RequestValues.GetValue('OrderBackendID');
        LocationCode := _RequestValues.GetValue('Location');
        Bin := MobToolbox.ReadBin(_RequestValues.GetValue('Bin'));
        ScannedBarcode := _RequestValues.GetValue('AddCountLineItem');
        ScannedExpirationDate := _RequestValues.GetValueAsDate('ExpirationDate');
        // MobTrackingSetup.TrackingRequired: Determine later when a valid Item No. is found
        MobTrackingSetup.CopyTrackingFromRequestValues(_RequestValues);    // SerialNumber, LotNumber, PackageNumber

        // Set Item, UoM and Variant from Barcode
        ItemNumber := MobItemReferenceMgt.SearchItemReference(ScannedBarcode, VariantCode, UoMCode);
        // Collected values have priority
        if _RequestValues.HasValue('UoM') then
            UoMCode := _RequestValues.GetValue('UoM');
        if _RequestValues.HasValue('Variant') then
            VariantCode := _RequestValues.GetValue('Variant');


        if _RequestValues.GetValue('AddCountLine') = 'No' then
            Error(MobWmsLanguage.GetMessage('NOTHING_TO_REGISTER'));

        // Determine the type of the journal and find it
        // This is determined by the prefix
        // "I-" means search the "Item Journal Batch" table
        // "W-" means search the "Warehouse Journal Batch"

        // Extract the prefix, batch name and location code (if exists)
        Prefix := CopyStr(CombinedBatchName, 1, 2);
        if Prefix = 'I-' then begin
            BatchName := CopyStr(CombinedBatchName, 3);
            BatchLocationCode := '';
        end else
            MobWmsToolbox.GetWhseJnlBatchNameAndLocationCodeFromBackendID(CombinedBatchName, BatchName, BatchLocationCode);

        // Set the tracking value displayed in the document queue
        _ReturnRegistrationTypeTracking :=
            CopyStr(CombinedBatchName, 3) + ' - ' +
            Item.TableCaption() + ' ' +
            ItemNumber;

        // Get the Mobile WMS configuration. This is needed to:
        // - Get the journal template names to use in the filter
        // - Determine the UoM to use
        MobSetup.Get();

        // Find the batch name based on the prefix
        case Prefix of
            'I-':
                begin
                    ItemJnlBatch.Get(MobSetup."Inventory Jnl Template", BatchName);

                    // Check if Item allready exists in the Journal
                    ItemJnlLine2.SetRange("Journal Template Name", ItemJnlBatch."Journal Template Name");
                    ItemJnlLine2.SetRange("Journal Batch Name", ItemJnlBatch.Name);
                    ItemJnlLine2.SetRange("Item No.", ItemNumber);
                    ItemJnlLine2.SetRange("Location Code", LocationCode);
                    ItemJnlLine2.SetRange("Variant Code", VariantCode);
                    if MobSetup."Use Base Unit of Measure" then
                        ItemJnlLine2.SetRange("Unit of Measure Code", DetermineItemUOM(ItemNumber))
                    else
                        ItemJnlLine2.SetRange("Unit of Measure Code", UoMCode);
                    if Bin <> '' then
                        ItemJnlLine2.SetRange("Bin Code", Bin);

                    MobTrackingSetup.SetTrackingFilterForItemJnlLineIfNotBlank(ItemJnlLine2);
                    if ItemJnlLine2.FindFirst() then
                        Error(MobWmsLanguage.GetMessage('COUNT_LINE_EXISTS'));

                    Clear(ItemJnlLine2);

                    // We have now found the journal to add the line to
                    // Get the last line of the journal and use it to initialize the values on the new line
                    ItemJnlLine2.SetRange("Journal Template Name", ItemJnlBatch."Journal Template Name");
                    ItemJnlLine2.SetRange("Journal Batch Name", ItemJnlBatch.Name);
                    ItemJnlLine2.FindLast();

                    // Insert a new line
                    ItemJnlLine.Init();
                    ItemJnlLine."Line No." := ItemJnlLine2."Line No." + 10000;
                    ItemJnlLine."Journal Template Name" := ItemJnlLine2."Journal Template Name";
                    ItemJnlLine."Journal Batch Name" := ItemJnlLine2."Journal Batch Name";
                    ItemJnlLine.SetUpNewLine(ItemJnlLine2);
                    ItemJnlLine.Validate("Item No.", ItemNumber);
                    ItemJnlLine.Validate("Variant Code", VariantCode);
                    ItemJnlLine.Validate("Location Code", LocationCode);
                    ItemJnlLine.Validate("Posting Date", WorkDate());
                    if MobSetup."Use Base Unit of Measure" then
                        ItemJnlLine.Validate("Unit of Measure Code", DetermineItemUOM(ItemNumber))
                    else
                        ItemJnlLine.Validate("Unit of Measure Code", UoMCode);

                    ItemJnlLine."Phys. Inventory" := true;
                    if Bin <> '' then begin
                        BinContent.SetRange("Location Code", LocationCode);
                        BinContent.SetRange("Bin Code", Bin);
                        BinContent.SetRange("Item No.", ItemNumber);
                        BinContent.SetRange("Variant Code", VariantCode);
                        BinContent.SetRange("Unit of Measure Code", ItemJnlLine."Unit of Measure Code");
                        MobTrackingSetup.SetTrackingFilterForBinContentIfNotBlank(BinContent);
                        BinContent.SetAutoCalcFields(Quantity);
                        if BinContent.FindFirst() then
                            ItemJnlLine."Qty. (Calculated)" := BinContent.Quantity;
                    end else begin
                        Item.SetRange("Location Filter", LocationCode);
                        Item.SetRange("Variant Filter", VariantCode);
                        Item.SetAutoCalcFields(Inventory);
                        if Item.Get(ItemNumber) then
                            ItemJnlLine."Qty. (Calculated)" := Item.Inventory;
                    end;

                    ItemJnlLine.Validate("Qty. (Phys. Inventory)");
                    ItemJnlLine."Phys. Inventory" := false;

                    if MobSetup."Use Base Unit of Measure" then
                        ItemJnlLine.Validate("Unit of Measure Code", DetermineItemUOM(ItemNumber))
                    else
                        ItemJnlLine.Validate("Unit of Measure Code", UoMCode);

                    ItemJnlLine."Phys. Inventory" := true;

                    ItemJnlLine.Validate("Bin Code", Bin);

                    // Insert the line
                    OnPostAdhocRegistrationOnAddCountLine_OnAfterCreateItemJnlLine(_RequestValues, ItemJnlLine);
                    ItemJnlLine.Insert(true);
                end;
            'W-':
                begin
                    WhseJnlBatch.Get(MobSetup."Whse Inventory Jnl Template", BatchName, BatchLocationCode);

                    // Check if Item allready exists in the Journal
                    WhseJnlLine2.SetRange("Journal Template Name", WhseJnlBatch."Journal Template Name");
                    WhseJnlLine2.SetRange("Journal Batch Name", WhseJnlBatch.Name);
                    WhseJnlLine2.SetRange("Location Code", WhseJnlBatch."Location Code");
                    WhseJnlLine2.SetRange("Item No.", ItemNumber);
                    WhseJnlLine2.SetRange("Variant Code", VariantCode);
                    if MobSetup."Use Base Unit of Measure" then
                        WhseJnlLine2.SetRange("Unit of Measure Code", DetermineItemUOM(ItemNumber))
                    else
                        WhseJnlLine2.SetRange("Unit of Measure Code", UoMCode);
                    if Bin <> '' then
                        WhseJnlLine2.SetRange("Bin Code", Bin);

                    MobTrackingSetup.SetTrackingFilterForWhseJnlLineIfNotBlank(WhseJnlLine2);
                    if WhseJnlLine2.FindFirst() then
                        Error(MobWmsLanguage.GetMessage('COUNT_LINE_EXISTS'));

                    Clear(WhseJnlLine2);

                    // We have now found the journal to add the line to
                    // Get the last line of the journal and use it to initialize the values on the new line
                    WhseJnlLine2.SetRange("Journal Template Name", WhseJnlBatch."Journal Template Name");
                    WhseJnlLine2.SetRange("Journal Batch Name", WhseJnlBatch.Name);
                    WhseJnlLine2.SetRange("Location Code", WhseJnlBatch."Location Code");
                    WhseJnlLine2.FindLast();

                    WhseJnlLine.Init();
                    WhseJnlLine."Line No." := WhseJnlLine2."Line No." + 10000;
                    WhseJnlLine."Journal Template Name" := WhseJnlBatch."Journal Template Name";
                    WhseJnlLine."Journal Batch Name" := WhseJnlBatch.Name;
                    WhseJnlLine."Location Code" := WhseJnlBatch."Location Code";
                    WhseJnlLine.SetUpNewLine(WhseJnlLine2);
                    Location.Get(LocationCode);
                    Location.TestField("Adjustment Bin Code");
                    BinRec.Get(Location.Code, Location."Adjustment Bin Code");
                    BinRec.TestField("Zone Code");
                    WhseJnlLine."From Bin Code" := Location."Adjustment Bin Code";
                    WhseJnlLine."From Zone Code" := BinRec."Zone Code";
                    WhseJnlLine."From Bin Type Code" := BinRec."Bin Type Code";
                    WhseJnlLine.Validate("Item No.", ItemNumber);
                    WhseJnlLine.Validate("Variant Code", VariantCode);
                    WhseJnlLine."Registering Date" := WorkDate();
                    WhseJnlLine."User ID" := UserId();
                    WhseJnlLine."Entry Type" := WhseJnlLine."Entry Type"::"Positive Adjmt.";
                    WhseJnlLine.Validate("Bin Code", Bin);

                    MobTrackingSetup.DetermineWhseTrackingRequired(ItemNumber, RegisterExpirationDate);
                    // MobTrackingSetup.Tracking: Copied before (during parse of RequestValues)

                    MobTrackingSetup.ValidateTrackingToWhseJnlLineIfRequired(WhseJnlLine);

                    // If expiration date is used for either the serial or lot number then the new expiration date must match the old exp date
                    if RegisterExpirationDate then begin
                        ExpirationDate :=
                          MobItemTrackingManagement.ExistingExpirationDate(
                            WhseJnlLine."Item No.",
                            WhseJnlLine."Variant Code",
                            MobTrackingSetup,
                            false,
                            EntriesExist);
                        if EntriesExist then begin
                            if WhseJnlLine."Expiration Date" <> ExpirationDate then
                                WhseJnlLine."Expiration Date" := ExpirationDate;
                        end else
                            if WhseJnlLine."Expiration Date" <> ScannedExpirationDate then
                                WhseJnlLine."Expiration Date" := ScannedExpirationDate;
                    end;

                    if MobSetup."Use Base Unit of Measure" then
                        WhseJnlLine.Validate("Unit of Measure Code", DetermineItemUOM(ItemNumber))
                    else
                        WhseJnlLine.Validate("Unit of Measure Code", UoMCode);

                    WhseJnlLine."Phys. Inventory" := true;

                    if Bin <> '' then begin
                        BinContent.SetRange("Location Code", LocationCode);
                        BinContent.SetRange("Zone Code", WhseJnlLine."Zone Code");
                        BinContent.SetRange("Bin Code", Bin);
                        BinContent.SetRange("Item No.", ItemNumber);
                        BinContent.SetRange("Variant Code", VariantCode);
                        BinContent.SetRange("Unit of Measure Code", WhseJnlLine."Unit of Measure Code");
                        MobTrackingSetup.SetTrackingFilterForBinContentIfNotBlank(BinContent);
                        BinContent.SetAutoCalcFields(Quantity, "Quantity (Base)");
                        if BinContent.FindFirst() then begin
                            WhseJnlLine.Validate("Qty. (Calculated)", BinContent.Quantity);
                            WhseJnlLine.Validate("Qty. (Calculated) (Base)", BinContent."Quantity (Base)");
                        end;
                    end;
                    WhseJnlLine.Validate("Qty. (Phys. Inventory)");

                    // Insert the line
                    OnPostAdhocRegistrationOnAddCountLine_OnAfterCreateWhseJnlLine(_RequestValues, WhseJnlLine);
                    WhseJnlLine.Insert(true);

                end;
            else
                Error(UnknownPrefixErr);
        end;

        _SuccessMessage := StrSubstNo(MobWmsLanguage.GetMessage('ADDED_LINE'), ItemNumber);
    end;

    local procedure CreateAddCountLineColConf(var _HeaderFilter: Record "MOB NS Request Element"; var _Steps: Record "MOB Steps Element") _ReturnRegistrationTypeTracking: Text
    var
        Location: Record Location;
        Item: Record Item;
        MobTrackingSetup: Record "MOB Tracking Setup";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        RegisterExpirationDate: Boolean;
        CombinedBatchName: Code[40];
        Prefix: Code[2];
        BatchName: Code[10];
        BatchLocationCode: Code[10];
        LocationCode: Code[10];
        ItemNumber: Code[50];
        VariantCode: Code[10];
        UoMCode: Code[10];
    begin
        // Find the Location parameter
        LocationCode := _HeaderFilter.GetValue('Location', true);
        Location.Get(LocationCode);

        // Now find the Jnl. Name parameter and Prefix
        CombinedBatchName := _HeaderFilter.GetValue('OrderBackendID', true);
        Prefix := CopyStr(CombinedBatchName, 1, 2);

        // Verify Location is setup accordingly to prefix
        case Prefix of
            'I-':
                begin
                    Location.TestField(Location."Directed Put-away and Pick", false);
                    BatchName := CopyStr(CombinedBatchName, 3);
                    BatchLocationCode := '';
                end;
            'W-':
                begin
                    Location.TestField(Location."Directed Put-away and Pick", true);
                    MobWmsToolbox.GetWhseJnlBatchNameAndLocationCodeFromBackendID(CombinedBatchName, BatchName, BatchLocationCode);
                end;
        end;

        // If scanned value is Cross Reference, then get Variant and UoM from that
        ItemNumber := MobItemReferenceMgt.SearchItemReference(MobToolbox.ReadEAN(_HeaderFilter.GetValue('AddCountLineItem', true)), VariantCode, UoMCode);

        // Set the tracking value displayed in the document queue
        _ReturnRegistrationTypeTracking := StrSubstNo('%1 - %2', CopyStr(CombinedBatchName, 3), ItemNumber);

        if not Item.Get(ItemNumber) then
            Error(MobWmsLanguage.GetMessage('UNKNOWN_ITEM_NO'), ItemNumber);

        if Prefix = 'W-' then
            // Warehouse Tracking Enabled : Collect tracking directly here when adding new count line
            MobTrackingSetup.DetermineWhseTrackingRequired(ItemNumber, RegisterExpirationDate);

        // Add the steps
        CreateAddCountLineSteps(_Steps, Item, LocationCode, VariantCode, UoMCode, MobTrackingSetup, RegisterExpirationDate);
    end;

    local procedure CreateAddCountLineSteps(var _Steps: Record "MOB Steps Element"; _Item: Record Item; _LocationCode: Code[10]; _VariantCode: Code[10]; _UoMCode: Code[10]; _MobTrackingSetup: Record "MOB Tracking Setup"; _RegisterExpirationDate: Boolean)
    var
        ItemVariant: Record "Item Variant";
        MobSetup: Record "MOB Setup";
        MobWmsLanguage: Codeunit "MOB WMS Language";
    begin
        MobSetup.Get();

        // Step: Bin
        if TestBinMandatory(_LocationCode) then
            _Steps.Create_TextStep_Bin(10, _LocationCode, _Item."No.", _VariantCode);

        // Step: Variant
        if _VariantCode = '' then begin
            ItemVariant.Reset();
            ItemVariant.SetRange("Item No.", _Item."No.");
            if not ItemVariant.IsEmpty() then
                _Steps.Create_ListStep_Variant(20, _Item."No.");
        end;

        // Step: UoM
        if (not MobSetup."Use Base Unit of Measure") and (_UoMCode = '') then begin
            _Steps.Create_ListStep_UoM(30, _Item."No.");
            _Steps.Set_defaultValue(_Item."Base Unit of Measure");
            if not MobWmsToolbox.GetItemHasMultipleUoM(_Item."No.") then begin
                _UoMCode := _Item."Base Unit of Measure";
                _Steps.Set_visible(false);
            end;
        end;

        // Step: SerialNumber, LotNumber, PackageNumber
        _Steps.Create_TrackingStepsIfRequired(_MobTrackingSetup, 40, _Item."No.");

        // Step: ExpirationDate
        if _RegisterExpirationDate then
            _Steps.Create_DateStep_ExpirationDate(90, _Item."No.");

        // Step: 'AddCountLine' if no other visible steps are defined
        _Steps.SetRange(visible, 'true');
        if _Steps.IsEmpty() then begin
            _Steps.Create_RadioButtonStep(100, 'AddCountLine');
            _Steps.Set_header(MobWmsLanguage.GetMessage('ADD_COUNT_LINE'));
            _Steps.Set_label('');
            _Steps.Set_helpLabel(MobWmsLanguage.GetMessage('ADD_COUNT_LINE'));
            _Steps.Set_defaultValue('');
            _Steps.Set_listValues(MobWmsLanguage.GetMessage('YES_NO'));
        end;
        _Steps.Reset();

    end;

    local procedure PostBulkMoveRegistration(var _RequestValues: Record "MOB NS Request Element"; var _SuccessMessage: Text; var _ReturnRegistrationTypeTracking: Text)
    var
        Location: Record Location;
        MobWmsLanguage: Codeunit "MOB WMS Language";
        LocationCode: Code[10];
        FromBin: Code[20];
        ToBin: Code[20];
    begin
        // The Unplanned Move feature expects 5 values
        // Location, FromBin, ToBin, Item and Quantity
        // The values are added to the relevant journal if they have been registered on the mobile device

        LocationCode := _RequestValues.GetValue('Location');
        FromBin := _RequestValues.GetValue('FromBin');
        ToBin := _RequestValues.GetValue('ToBin');

        _ReturnRegistrationTypeTracking := LocationCode + ': ' + FromBin + ' -> ' + ToBin;

        // Get the location and determine if it uses directed pick/put-away or not
        Location.Get(LocationCode);
        if Location."Directed Put-away and Pick" then
            BulkMoveWhseJnlLine(LocationCode, FromBin, ToBin, _RequestValues)
        else begin
            Location.TestField("Bin Mandatory");
            BulkMoveItemJnlLine(LocationCode, FromBin, ToBin, _RequestValues);
        end;

        _SuccessMessage := MobWmsLanguage.GetMessage('BULK_MOVE_COMPLETED');
    end;

    local procedure BulkMoveWhseJnlLine(_LocationCode: Code[10]; _FromBin: Code[20]; _ToBin: Code[20]; var _RequestValues: Record "MOB NS Request Element")
    var
        MobSetup: Record "MOB Setup";
        MobTrackingSetup: Record "MOB Tracking Setup";
        SourceCode: Record "Source Code";
        Location: Record Location;
        Item: Record Item;
        BinContent: Record "Bin Content";
        BinContentLotSerial: Record "Bin Content";
        WhseJnlLine: Record "Warehouse Journal Line";
        WhseJnlLine2: Record "Warehouse Journal Line";
        TempEntrySummary: Record "Entry Summary" temporary;
        WhseJnlRegisterBatch: Codeunit "Whse. Jnl.-Register Batch";
        MobItemTrackingManagement: Codeunit "MOB Item Tracking Management";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        RegisterExpirationDate: Boolean;
        // ExpirationDate: Date;    // TODO - Delete or should this one be used in the code below?
        EntriesExist: Boolean;
        NextLineNo: Integer;
        ResultMessage: Text;
    begin
        // The Unplanned Move feature expects 5 values
        // Location, FromBin, ToBin (then Item and Quantity is derived based on these values)
        // The values are added to the relevant journal if they have been registered on the mobile device

        // Make sure that the MOBUNPMOVE source code exist (for tracking purposes)
        if not SourceCode.Get('MOBUNPMOVE') then begin
            SourceCode.Code := 'MOBUNPMOVE';
            SourceCode.Description := CopyStr(MobWmsLanguage.GetMessage('HANDHELD_UNPLANNED_MOVE'), 1, MaxStrLen(SourceCode.Description));
            SourceCode.Insert();
        end;

        // Get the Mobile WMS configuration
        MobSetup.Get();

        // Get the location and determine if it uses directed pick/put-away or not
        Location.Get(_LocationCode);

        MobSetup.TestField("Move Whse. Jnl Template");
        MobSetup.TestField("Unplanned Move Batch Name");
        WhseJnlLine2.SetRange("Journal Template Name", MobSetup."Move Whse. Jnl Template");
        WhseJnlLine2.SetRange("Journal Batch Name", MobSetup."Unplanned Move Batch Name");
        if WhseJnlLine2.FindLast() then
            NextLineNo := WhseJnlLine2."Line No." + 10000
        else
            NextLineNo := 10000;

        // Lookup the content of the bin
        BinContent.SetCurrentKey("Location Code", "Bin Code");
        BinContent.SetRange("Location Code", _LocationCode);
        BinContent.SetRange("Bin Code", _FromBin);
        OnPostAdhocRegistrationOnBulkMove_OnSetFilterBinContent(_RequestValues, BinContent);
        BinContent.SetAutoCalcFields(Quantity); // Calculate the quantity
        if BinContent.FindSet() then
            repeat
                Item.Reset();
                Item.Get(BinContent."Item No.");

                MobTrackingSetup.DetermineWhseTrackingRequired(BinContent."Item No.", RegisterExpirationDate);
                // MobTrackingSetup.Tracking: Copy later in EntrySummary loop

                if MobTrackingSetup.TrackingRequired() then begin

                    // Item is tracked, get at summary to Look Up in Bin Content
                    MobWmsToolbox.GetTrackedSummary(TempEntrySummary, Location, BinContent."Bin Code", BinContent."Item No.",
                                                        BinContent."Variant Code", BinContent."Unit of Measure Code", RegisterExpirationDate);

                    // Respect additional filters from event
                    BinContent.CopyFilter("Serial No. Filter", TempEntrySummary."Serial No.");
                    BinContent.CopyFilter("Lot No. Filter", TempEntrySummary."Lot No.");
                    /* #if BC18+ */
                    BinContent.CopyFilter("Package No. Filter", TempEntrySummary."Package No.");
                    /* #endif */

                    if TempEntrySummary.FindSet() then
                        repeat
                            // MobTrackingSetup.TrackingRequired: Determined before (outside TempEntrySummary loop)
                            MobTrackingSetup.CopyTrackingFromEntrySummary(TempEntrySummary);

                            BinContentLotSerial.Reset();
                            BinContentLotSerial.SetRange("Location Code", Location.Code);
                            BinContentLotSerial.SetRange("Bin Code", BinContent."Bin Code");
                            BinContentLotSerial.SetRange("Item No.", BinContent."Item No.");
                            BinContentLotSerial.SetRange("Variant Code", BinContent."Variant Code");
                            BinContentLotSerial.SetRange("Unit of Measure Code", BinContent."Unit of Measure Code");
                            MobTrackingSetup.SetTrackingFilterForBinContent(BinContentLotSerial);
                            BinContentLotSerial.SetFilter(Quantity, '<>0');
                            BinContentLotSerial.SetAutoCalcFields(Quantity);
                            if BinContentLotSerial.FindFirst() then
                                if BinContentLotSerial.Quantity <> 0 then begin
                                    // Init Warehouse Journal Line
                                    WhseJnlLine.Init();

                                    // Perform the posting using the Warehouse Item Journal
                                    // Set the template
                                    WhseJnlLine."Journal Template Name" := MobSetup."Move Whse. Jnl Template";

                                    // Set the batch name
                                    WhseJnlLine."Journal Batch Name" := MobSetup."Unplanned Move Batch Name";

                                    // Set the location code
                                    WhseJnlLine."Location Code" := BinContentLotSerial."Location Code";

                                    // Set the Line No.
                                    WhseJnlLine."Line No." := NextLineNo;
                                    NextLineNo += 10000;

                                    // Create Warehouse Journal
                                    WhseJnlLine.Validate("Registering Date", WorkDate());
                                    WhseJnlLine.Validate("Source Code", SourceCode.Code);
                                    WhseJnlLine.Validate("Whse. Document Type", WhseJnlLine."Whse. Document Type"::"Whse. Journal");
                                    WhseJnlLine."MOB GetWhseDocumentNo"(false); // Dont modify No. Series, as "Whse Jnl Register Batch" must be able to validate same number
                                    WhseJnlLine.Validate("Entry Type", WhseJnlLine."Entry Type"::Movement);
                                    WhseJnlLine."User ID" := UserId();

                                    // Set the values from the mobile device
                                    WhseJnlLine.Validate("Item No.", BinContentLotSerial."Item No.");
                                    WhseJnlLine.Validate("Variant Code", BinContentLotSerial."Variant Code");
                                    WhseJnlLine.Validate("From Bin Code", _FromBin);
                                    WhseJnlLine.Validate("To Bin Code", _ToBin);
                                    WhseJnlLine.Validate("Unit of Measure Code", BinContentLotSerial."Unit of Measure Code");
                                    WhseJnlLine.Validate(Quantity, BinContentLotSerial.Quantity);

                                    MobTrackingSetup.ValidateTrackingToWhseJnlLineIfRequired(WhseJnlLine);

                                    // If expiration date is used for either the serial or lot number then the new expiration date
                                    // must match the old exp date
                                    if RegisterExpirationDate then begin
                                        // TODO - ExpirationDate is never assigned below... can MobCommonMgt.ExistingExpirationDate function call be entirely removed?
                                        // ExpirationDate :=
                                        MobItemTrackingManagement.ExistingExpirationDate(
                                          WhseJnlLine."Item No.",
                                          WhseJnlLine."Variant Code",
                                          MobTrackingSetup,
                                          false,
                                          EntriesExist);

                                        if WhseJnlLine."Expiration Date" <> TempEntrySummary."Expiration Date" then
                                            WhseJnlLine."Expiration Date" := TempEntrySummary."Expiration Date";
                                        if WhseJnlLine."New Expiration Date" <> TempEntrySummary."Expiration Date" then
                                            WhseJnlLine."New Expiration Date" := TempEntrySummary."Expiration Date";
                                    end;
                                    OnPostAdhocRegistrationOnBulkMove_OnAfterCreateWhseJnlLine(_RequestValues, WhseJnlLine);
                                    WhseJnlLine.Insert(true);
                                    WhseJnlLine.Mark(true);
                                    InsertWhseItemTracking(WhseJnlLine);
                                end;
                        until TempEntrySummary.Next() = 0;

                end else
                    // Filter entries with zero quantity
                    if BinContent.Quantity <> 0 then begin
                        // Init Warehouse Journal Line
                        WhseJnlLine.Init();

                        // Perform the posting using the Warehouse Item Journal
                        // Set the template
                        WhseJnlLine."Journal Template Name" := MobSetup."Move Whse. Jnl Template";

                        // Set the batch name
                        WhseJnlLine."Journal Batch Name" := MobSetup."Unplanned Move Batch Name";

                        // Set the location code
                        WhseJnlLine."Location Code" := BinContent."Location Code";

                        // Set the Line No.
                        WhseJnlLine."Line No." := NextLineNo;
                        NextLineNo += 10000;

                        // Create Warehouse Journal 
                        WhseJnlLine.Validate("Registering Date", WorkDate());
                        WhseJnlLine.Validate("Source Code", SourceCode.Code);
                        WhseJnlLine.Validate("Whse. Document Type", WhseJnlLine."Whse. Document Type"::"Whse. Journal");
                        WhseJnlLine."MOB GetWhseDocumentNo"(false); // Dont modify No. Series, as "Whse Jnl Register Batch" must be able to validate same number
                        WhseJnlLine.Validate("Entry Type", WhseJnlLine."Entry Type"::Movement);
                        WhseJnlLine."User ID" := UserId();

                        // Set the values from the mobile device
                        WhseJnlLine.Validate("Item No.", BinContent."Item No.");
                        WhseJnlLine.Validate("Variant Code", BinContent."Variant Code");
                        WhseJnlLine.Validate("From Bin Code", _FromBin);
                        WhseJnlLine.Validate("To Bin Code", _ToBin);
                        WhseJnlLine.Validate("Unit of Measure Code", BinContent."Unit of Measure Code");
                        WhseJnlLine.Validate(Quantity, BinContent.Quantity);

                        OnPostAdhocRegistrationOnBulkMove_OnAfterCreateWhseJnlLine(_RequestValues, WhseJnlLine);
                        WhseJnlLine.Insert(true);
                        WhseJnlLine.Mark(true);
                        InsertWhseItemTracking(WhseJnlLine);
                    end;

            until BinContent.Next() = 0;

        Commit();
        WhseJnlLine.MarkedOnly(true);
        // Perform the posting using the Warehouse Journal
        WhseJnlLine.SetRange("Journal Template Name", MobSetup."Move Whse. Jnl Template");
        WhseJnlLine.SetRange("Journal Batch Name", MobSetup."Unplanned Move Batch Name");
        WhseJnlLine.SetFilter("Item No.", '<>%1', '');
        if WhseJnlLine.FindFirst() then begin
            if not WhseJnlRegisterBatch.Run(WhseJnlLine) then begin
                // Cleanup the marked records
                WhseJnlLine.DeleteAll(true);
                Commit();
                ResultMessage := GetLastErrorText();
                MobSessionData.SetPreservedLastErrorCallStack();
                Error(ResultMessage);
            end
        end else
            Error(MobWmsLanguage.GetMessage('NOTHING_TO_REGISTER'));
    end;

    local procedure BulkMoveItemJnlLine(_LocationCode: Code[10]; _FromBin: Code[20]; _ToBin: Code[20]; var _RequestValues: Record "MOB NS Request Element")
    var
        SourceCode: Record "Source Code";
        Location: Record Location;
        BinContent: Record "Bin Content";
        ItemJnlLine: Record "Item Journal Line";
        MobSetup: Record "MOB Setup";
        GetBinContent: Report "Whse. Get Bin Content";
        ItemJnlPostBatch: Codeunit "Item Jnl.-Post Batch";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        MobReservationMgt: Codeunit "MOB Reservation Mgt.";
        MobCommonMgt: Codeunit "MOB Common Mgt.";
        ResultMessage: Text;
        LastLineNo: Integer;
    begin
        // The Bulk Move feature expects 3 values
        // Location, FromBin, ToBin (then Item and Quantity is derived based on these values)
        // The values are added to the relevant journal if they have been registered on the mobile device

        // Make sure that the MOBUNPMOVE source code exist (for tracking purposes)
        if not SourceCode.Get('MOBUNPMOVE') then begin
            SourceCode.Code := 'MOBUNPMOVE';
            SourceCode.Description := CopyStr(MobWmsLanguage.GetMessage('HANDHELD_UNPLANNED_MOVE'), 1, MaxStrLen(SourceCode.Description));
            SourceCode.Insert();
        end;

        // Get the Mobile WMS configuration
        MobSetup.Get();

        // Get the location and determine if it uses directed pick/put-away or not
        Location.Get(_LocationCode);

        // Perform the posting using the standard journal
        MobSetup.TestField("Move Item Jnl. Template");
        MobSetup.TestField("Unpl. Item Jnl Move Batch Name");

        ItemJnlLine.SetRange("Journal Template Name", MobSetup."Move Item Jnl. Template");
        ItemJnlLine.SetRange("Journal Batch Name", MobSetup."Unpl. Item Jnl Move Batch Name");
        ItemJnlLine.SetFilter("Item No.", '<>%1', '');
        if ItemJnlLine.FindLast() then
            LastLineNo := ItemJnlLine."Line No.";

        ItemJnlLine.Init();
        ItemJnlLine.Validate("Journal Template Name", MobSetup."Move Item Jnl. Template");
        ItemJnlLine.Validate("Journal Batch Name", MobSetup."Unpl. Item Jnl Move Batch Name");
        ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::Transfer);
        ItemJnlLine.Validate("Posting Date", WorkDate());
        ItemJnlLine."MOB GetDocumentNo"(false);
        ItemJnlLine.Validate("Source Code", SourceCode.Code);

        BinContent.SetRange("Location Code", _LocationCode);
        BinContent.SetRange("Bin Code", _FromBin);
        BinContent.SetFilter(Quantity, '>0');
        OnPostAdhocRegistrationOnBulkMove_OnSetFilterBinContent(_RequestValues, BinContent);

        if BinContent.FindSet() then
            repeat
                MobReservationMgt.CheckWhseTrackingEnabledIfSpecificTrackingRequired(BinContent."Item No.");
            until BinContent.Next() = 0;
        GetBinContent.SetTableView(BinContent);
        GetBinContent.InitializeItemJournalLine(ItemJnlLine);
        GetBinContent.UseRequestPage(false);
        RunWhseGetBinContentReportWithoutCommits(GetBinContent); // Report contains commits and the wrapper function ensures their are ignored

        ItemJnlLine.SetRange("Journal Template Name", MobSetup."Move Item Jnl. Template");
        ItemJnlLine.SetRange("Journal Batch Name", MobSetup."Unpl. Item Jnl Move Batch Name");
        ItemJnlLine.SetFilter("Item No.", '<>%1', '');
        // Filter to new records only
        if LastLineNo <> 0 then
            ItemJnlLine.SetFilter("Line No.", '>%1', LastLineNo);

        if ItemJnlLine.FindSet(true) then
            repeat
                ItemJnlLine.Validate("New Bin Code", _ToBin);
                OnPostAdhocRegistrationOnBulkMove_OnAfterCreateItemJnlLine(_RequestValues, ItemJnlLine);
                ItemJnlLine.Modify();
            until ItemJnlLine.Next() = 0;

        Commit();
        if ItemJnlLine.FindFirst() then begin
            ItemJnlPostBatch.SetSuppressCommit(true);
            if not ItemJnlPostBatch.Run(ItemJnlLine) then begin
                // Cleanup the new records - must delete invidually as associated tracking cannot be deleted programmatically with DeleteAll(true)
                ItemJnlLine.FindSet();
                repeat
                    MobCommonMgt.DeleteReservEntries(ItemJnlLine);
                    ItemJnlLine.Delete(true);
                until ItemJnlLine.Next() = 0;

                Commit();
                ResultMessage := GetLastErrorText();
                MobSessionData.SetPreservedLastErrorCallStack();
                Error(ResultMessage);
            end
        end else
            Error(MobWmsLanguage.GetMessage('NOTHING_TO_REGISTER'));
    end;

    /// <summary>
    /// Wraps the "Whse. Get Bin Content" report with "CommitBehavior::Ignore" because it contains unavoidable Commits when tracking is in use.
    /// 
    /// The solution is not enabled for BC16- as the property is introduced in BC17. 
    /// However, it seems not be a problem in BC16 (and most likely all older versions) as BC16 doesn't use Page 6510 to write tracking.
    /// Instead BC16 inserts the tracking records directly (without any commits).
    /// </summary>
    /// <param name="_Report">The Report variable prepared with filters etc.</param>    
    /* #if BC17+ */
    [CommitBehavior(CommitBehavior::Ignore)]
    /* #endif */
    local procedure RunWhseGetBinContentReportWithoutCommits(var _Report: Report "Whse. Get Bin Content")
    begin
        _Report.RunModal();
    end;

    internal procedure InsertWhseItemTracking(_WhseJnlLine: Record "Warehouse Journal Line")
    var
        WhseItemTrkngLine: Record "Whse. Item Tracking Line";
        MobTrackingSetup: Record "MOB Tracking Setup";
        EntryNo: Integer;
    begin
        //Create WhseItemTracking
        if WhseItemTrkngLine.FindLast() then
            EntryNo := WhseItemTrkngLine."Entry No."
        else
            EntryNo := 0;
        WhseItemTrkngLine.Reset();
        WhseItemTrkngLine.Init();
        WhseItemTrkngLine."Entry No." := EntryNo + 1;
        WhseItemTrkngLine.Validate("Item No.", _WhseJnlLine."Item No.");
        WhseItemTrkngLine.Validate("Location Code", _WhseJnlLine."Location Code");
        WhseItemTrkngLine.Validate("Variant Code", _WhseJnlLine."Variant Code");
        WhseItemTrkngLine.Validate("Quantity (Base)", _WhseJnlLine."Qty. (Base)");
        WhseItemTrkngLine.Validate("Source Subtype", 0);
        WhseItemTrkngLine.Validate("Source Type", Database::"Warehouse Journal Line");
        WhseItemTrkngLine.Validate("Source ID", _WhseJnlLine."Journal Batch Name");
        WhseItemTrkngLine.Validate("Source Batch Name", _WhseJnlLine."Journal Template Name");
        WhseItemTrkngLine.Validate("Source Ref. No.", _WhseJnlLine."Line No.");

        MobTrackingSetup.CopyTrackingFromWhseJnlLine(_WhseJnlLine);
        MobTrackingSetup.ValidateTrackingToWhseItemTrackingLine(WhseItemTrkngLine);

        WhseItemTrkngLine.Validate("Expiration Date", _WhseJnlLine."Expiration Date");
        WhseItemTrkngLine.Insert();
    end;

    local procedure CreateItemDimensionsRegColConf(var _HeaderFilter: Record "MOB NS Request Element"; var _Steps: Record "MOB Steps Element") _ReturnRegistrationTypeTracking: Text
    var
        Item: Record Item;
        MobWmsLanguage: Codeunit "MOB WMS Language";
        UnitOfMeasureCode: Code[10];
        ItemNumber: Code[50];
        VariantCode: Code[10];
    begin
        // -- Now find the UnitOfMeasure and ItemNumber parameters
        UnitOfMeasureCode := _HeaderFilter.GetValue('UnitOfMeasure', true);
        ItemNumber := MobItemReferenceMgt.SearchItemReference(MobToolbox.ReadEAN(_HeaderFilter.GetValue('ItemNumber', true)), VariantCode);

        // Validate that the item exists
        if not Item.Get(ItemNumber) then
            Error(MobWmsLanguage.GetMessage('UNKNOWN_ITEM_NO'), ItemNumber);

        // Set the tracking value displayed in the document queue
        _ReturnRegistrationTypeTracking := StrSubstNo('%1 - %2', ItemNumber, UnitOfMeasureCode);

        // Add the steps
        CreateItemDimensionsSteps(_Steps, ItemNumber, UnitOfMeasureCode);
    end;

    local procedure CreateItemDimensionsSteps(var _Steps: Record "MOB Steps Element"; _ItemNo: Code[20]; _UnitOfMeasureCode: Code[10])
    var
        Item: Record Item;
        ItemUoM: Record "Item Unit of Measure";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        SetDefaultValue: Boolean;
    begin
        // If the selected unit of measure is already defined for the item then we show the entered values to the user
        // The user can then update the values if necessary
        Item.Get(_ItemNo);

        ItemUoM.Reset();
        ItemUoM.SetRange("Item No.", _ItemNo);
        ItemUoM.SetRange(Code, _UnitOfMeasureCode);
        SetDefaultValue := ItemUoM.FindFirst();

        // Step: QuantityPerUoM
        if _UnitOfMeasureCode <> Item."Base Unit of Measure" then begin
            _Steps.Create_DecimalStep_Quantity(10, _ItemNo);
            _Steps.Set_name('QuantityPerUoM');
            _Steps.Set_header(MobWmsLanguage.GetMessage('ENTER_QTY_PER_UOM'));
            if SetDefaultValue then
                _Steps.Set_defaultValue(ItemUoM."Qty. per Unit of Measure");
            _Steps.Set_minValue(0.0000000001);
        end;

        // Step: Length
        _Steps.Create_DecimalStep_Quantity(20, _ItemNo);
        _Steps.Set_name('Length');
        _Steps.Set_header(MobWmsLanguage.GetMessage('ENTER_LENGTH'));
        _Steps.Set_label(MobWmsLanguage.GetMessage('LENGTH_LABEL') + ':');
        _Steps.Set_eanAi('');
        if SetDefaultValue then
            _Steps.Set_defaultValue(ItemUoM.Length);
        _Steps.Set_minValue(0);

        // Step: Width
        _Steps.Create_DecimalStep_Quantity(30, _ItemNo);
        _Steps.Set_name('Width');
        _Steps.Set_header(MobWmsLanguage.GetMessage('ENTER_WIDTH'));
        _Steps.Set_label(MobWmsLanguage.GetMessage('WIDTH_LABEL') + ':');
        _Steps.Set_eanAi('');
        if SetDefaultValue then
            _Steps.Set_defaultValue(ItemUoM.Width);
        _Steps.Set_minValue(0);

        // Step: Height
        _Steps.Create_DecimalStep_Quantity(40, _ItemNo);
        _Steps.Set_name('Height');
        _Steps.Set_header(MobWmsLanguage.GetMessage('ENTER_HEIGHT'));
        _Steps.Set_label(MobWmsLanguage.GetMessage('HEIGHT_LABEL') + ':');
        _Steps.Set_eanAi('');
        if SetDefaultValue then
            _Steps.Set_defaultValue(ItemUoM.Height);
        _Steps.Set_minValue(0);

        // Step: Cubage - Uncomment (or create eventsubscriber) to allow the user to enter cubage
        // _Steps.Create_QuantityStep(50, Item);
        // _Steps.Set_name('Cubage');
        // _Steps.Set_header(MobWmsLanguage.GetMessage('ENTER_CUBAGE'));
        // _Steps.Set_label(MobWmsLanguage.GetMessage('CUBAGE_LABEL') + ':');
        // _Steps.Set_eanAI('');
        // if SetDefaultValue then
        //     _Steps.Set_defaultValue(ItemUoM.Cubage);
        // _Steps.Set_minValue(0);

        // Step: Weight
        _Steps.Create_DecimalStep_Quantity(60, _ItemNo);
        _Steps.Set_name('Weight');
        _Steps.Set_header(MobWmsLanguage.GetMessage('ENTER_WEIGHT'));
        _Steps.Set_label(MobWmsLanguage.GetMessage('WEIGHT_LABEL') + ':');
        _Steps.Set_eanAi('');
        if SetDefaultValue then
            _Steps.Set_defaultValue(ItemUoM.Weight);
        _Steps.Set_minValue(0);

    end;

    local procedure PostItemDimensionsRegistration(var _RequestValues: Record "MOB NS Request Element"; var _SuccessMessage: Text; var _ReturnRegistrationTypeTracking: Text)
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        ItemNumber: Code[20];
        UnitOfMeasureCode: Code[10];
        Weight: Decimal;
        Height: Decimal;
        Length: Decimal;
        QtyPerUoM: Decimal;
        UseQtyPerUoM: Decimal;
        Width: Decimal;
    begin
        QtyPerUoM := _RequestValues.GetValueAsDecimal('QuantityPerUoM');
        Width := _RequestValues.GetValueAsDecimal('Width');
        Height := _RequestValues.GetValueAsDecimal('Height');
        Length := _RequestValues.GetValueAsDecimal('Length');
        // Cubage := _RequestValues.GetValueAsDecimal('Cubage');
        Weight := _RequestValues.GetValueAsDecimal('Weight');
        ItemNumber := MobWmsToolbox.GetItemNumber(_RequestValues.GetValue('ItemNumber'));
        UnitOfMeasureCode := _RequestValues.GetValue('UnitOfMeasure');

        _ReturnRegistrationTypeTracking := ItemUnitOfMeasure.FieldCaption("Item No.") + ' ' + ItemNumber;

        // Determine if the item unit of measure exists
        ItemUnitOfMeasure.SetRange("Item No.", ItemNumber);
        ItemUnitOfMeasure.SetRange(Code, UnitOfMeasureCode);

        // Overwrite undefined QtyPerUoM if posting to base unit of measure
        if (QtyPerUoM = 0) and (Item.Get(ItemNumber)) and (UnitOfMeasureCode = Item."Base Unit of Measure") then
            UseQtyPerUoM := 1
        else
            UseQtyPerUoM := QtyPerUoM;

        if ItemUnitOfMeasure.FindFirst() then begin
            // The UoM is already defined for this item -> update the values
            if ItemUnitOfMeasure."Qty. per Unit of Measure" <> UseQtyPerUoM then
                ItemUnitOfMeasure.Validate("Qty. per Unit of Measure", UseQtyPerUoM);
            if ItemUnitOfMeasure.Length <> Length then
                ItemUnitOfMeasure.Validate(Length, Length);
            if ItemUnitOfMeasure.Width <> Width then
                ItemUnitOfMeasure.Validate(Width, Width);
            if ItemUnitOfMeasure.Height <> Height then
                ItemUnitOfMeasure.Validate(Height, Height);
            ItemUnitOfMeasure.Weight := Weight;
            OnPostAdhocRegistrationOnItemDimensions_OnBeforeInsertModifyItemUnitOfMeasure(_RequestValues, ItemUnitOfMeasure);
            ItemUnitOfMeasure.Modify();

        end else begin
            // The UoM is not defined for this item -> insert it
            ItemUnitOfMeasure."Item No." := ItemNumber;
            ItemUnitOfMeasure.Code := UnitOfMeasureCode;
            ItemUnitOfMeasure.Validate("Qty. per Unit of Measure", UseQtyPerUoM);
            ItemUnitOfMeasure.Validate(Length, Length);
            ItemUnitOfMeasure.Validate(Width, Width);
            ItemUnitOfMeasure.Validate(Height, Height);
            ItemUnitOfMeasure.Weight := Weight;
            OnPostAdhocRegistrationOnItemDimensions_OnBeforeInsertModifyItemUnitOfMeasure(_RequestValues, ItemUnitOfMeasure);
            ItemUnitOfMeasure.Insert();
        end;

        _SuccessMessage := MobWmsLanguage.GetMessage('REG_TRANS_SUCCESS');
    end;

    local procedure CreateToteShippingRegColConf(var _HeaderFilter: Record "MOB NS Request Element"; var _Steps: Record "MOB Steps Element") _ReturnRegistrationTypeTracking: Text
    var
        Location: Record Location;
        WhseShipmentHeader: Record "Warehouse Shipment Header";
        WhseShipmentLine: Record "Warehouse Shipment Line";
        MobSetup: Record "MOB Setup";
        MobWmsRegistration: Record "MOB WMS Registration";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        ShipmentNo: Code[20];
        ToteID: Code[100];
        ReadyToShip: Boolean;
        OpenPickOrders: Boolean;
        RemainingToteString: Text[1024];
        RemainingToteFilter: Text[1024];
        NextStepNo: Integer;
        OpenPickIDs: Text;
    begin

        MobSetup.Get();

        // -- Now find the ToteID parameter
        ToteID := _HeaderFilter.GetValue('ToteID', true);

        // Set the tracking value displayed in the document queue
        _ReturnRegistrationTypeTracking := ToteID;

        FindRemaingToteIDs(ShipmentNo, ToteID, RemainingToteString, RemainingToteFilter);

        // Check if Warehouse Shipment is ready
        ReadyToShip := false;
        OpenPickOrders := false;
        WhseShipmentHeader.SetRange("No.", ShipmentNo);
        WhseShipmentHeader.SetRange(Status, WhseShipmentHeader.Status::Released);
        if WhseShipmentHeader.FindFirst() then begin
            Location.Get(WhseShipmentHeader."Location Code");
            if Location."Require Shipment" and Location."Require Pick" then begin
                if WhseShipmentHeader."Document Status" = WhseShipmentHeader."Document Status"::"Completely Picked" then
                    ReadyToShip := true
                else
                    if (WhseShipmentHeader."Document Status" = WhseShipmentHeader."Document Status"::"Partially Picked") or
                       (WhseShipmentHeader."Document Status" = WhseShipmentHeader."Document Status"::"Partially Shipped")
                    then begin
                        MobWmsRegistration.SetCurrentKey("Tote ID", "Whse. Document Type", "Whse. Document No.", "Whse. Document Line No.");
                        MobWmsRegistration.SetRange("Tote ID", ToteID);
                        MobWmsRegistration.SetRange("Whse. Shpmt. Exists", true);
                        MobWmsRegistration.SetRange("Tote Handled", false);
                        MobWmsRegistration.SetRange("Whse. Document Type", MobWmsRegistration."Whse. Document Type"::Shipment);
                        MobWmsRegistration.SetRange("Whse. Document No.", ShipmentNo);
                        if MobWmsRegistration.FindFirst() then
                            case MobSetup."Tote per" of
                                MobSetup."Tote per"::"Destination No.":
                                    begin
                                        WhseShipmentLine.SetRange("Destination Type", MobWmsRegistration."Destination Type");
                                        WhseShipmentLine.SetRange("Destination No.", MobWmsRegistration."Destination No.");
                                        MobWmsRegistration.SetRange("Destination Type", MobWmsRegistration."Destination Type");
                                        MobWmsRegistration.SetRange("Destination No.", MobWmsRegistration."Destination No.");
                                    end;
                                MobSetup."Tote per"::"Source No.":
                                    begin
                                        WhseShipmentLine.SetRange("Source Type", MobWmsRegistration."Source Type");
                                        WhseShipmentLine.SetRange("Source No.", MobWmsRegistration."Source No.");
                                        MobWmsRegistration.SetRange("Source Type", MobWmsRegistration."Source Type");
                                        MobWmsRegistration.SetRange("Source No.", MobWmsRegistration."Source No.");
                                    end;
                            end;

                        WhseShipmentLine.SetRange("No.", WhseShipmentHeader."No.");
                        WhseShipmentLine.SetFilter("Pick Qty.", '<>0');
                        WhseShipmentLine.SetFilter("Qty. Outstanding", '<>0');
                        if WhseShipmentLine.FindFirst() then begin
                            ReadyToShip := true;
                            OpenPickOrders := true;
                            OpenPickIDs := MobWmsToolbox.FindOpenPickIDs(WhseShipmentLine);
                        end;
                        WhseShipmentLine.SetRange("Pick Qty.");
                        if WhseShipmentLine.FindSet() then
                            repeat
                                case WhseShipmentLine.Status of
                                    WhseShipmentLine.Status::"Completely Picked":
                                        ReadyToShip := true;
                                    WhseShipmentLine.Status::"Partially Picked",
                                  WhseShipmentLine.Status::"Partially Shipped":
                                        if WhseShipmentLine."Shipping Advice" = WhseShipmentLine."Shipping Advice"::Partial then
                                            ReadyToShip := true
                                        else
                                            Error(MobWmsLanguage.GetMessage('NOT_PARTIAL_SHIP'), WhseShipmentLine."Line No.", ShipmentNo);
                                    else
                                        if (WhseShipmentLine."Shipping Advice" = WhseShipmentLine."Shipping Advice"::Partial) or WhseShipmentLine."Assemble to Order" then
                                            ReadyToShip := true
                                        else
                                            Error(MobWmsLanguage.GetMessage('NOT_PARTIAL_SHIP'), WhseShipmentLine."Line No.", ShipmentNo);
                                end;
                            until (WhseShipmentLine.Next() = 0) or (ReadyToShip = false);
                    end else begin
                        if WhseShipmentHeader."Document Status" = WhseShipmentHeader."Document Status"::"Completely Shipped" then
                            Error(MobWmsLanguage.GetMessage('COMPLETELY_SHIPPED'), ShipmentNo);

                        if WhseShipmentHeader."Document Status" = WhseShipmentHeader."Document Status"::" " then begin
                            WhseShipmentLine.SetRange("No.", WhseShipmentHeader."No.");
                            WhseShipmentLine.SetRange("Assemble to Order", true);
                            WhseShipmentLine.SetFilter("Qty. Outstanding", '<>0');
                            ReadyToShip := not WhseShipmentLine.IsEmpty();
                            if not ReadyToShip then
                                Error(MobWmsLanguage.GetMessage('NOTHING_PICKED'), ShipmentNo);
                        end;

                        // All different statuses should have been handled at this point
                        if not ReadyToShip then
                            Error(MobWmsLanguage.GetMessage('UNEXPECTED_SHIP_STATUS'), WhseShipmentHeader."Document Status");
                    end;

            end else
                Error(MobWmsLanguage.GetMessage('TOTE_SHIP_LOC_PICK_SHIP_ERROR'), WhseShipmentHeader."Location Code");

        end else
            Error(MobWmsLanguage.GetMessage('SHIPMENT_MISSING'), ShipmentNo);


        // Now we have the parameters -> determine which registrations to collect

        NextStepNo := 10;
        // Step: Information (Open Pick Orders)
        if OpenPickOrders then begin
            _Steps.Create_InformationStep(NextStepNo, 'Information');
            _Steps.Set_header(MobWmsLanguage.GetMessage('TOTE_SHIPPING'));
            _Steps.Set_label(MobWmsLanguage.GetMessage('OPEN_PICK_ORDERS'));
            _Steps.Set_helpLabel(StrSubstNo(MobWmsLanguage.GetMessage('OPEN_PICK_ORDERS_INFO'), WhseShipmentHeader."No.", OpenPickIDs));
            NextStepNo += 10;
        end;

        // Assemble to Order scenarios are covered by requiring picks to be complete (no partial tote-picking supported in AtO)
        // and checking if any of the assembled items require Item Tracking
        AddItemTrackingStepsIfToteContainsAtOLines(_Steps, NextStepNo, ToteID, true);

        if RemainingToteString <> '' then begin
            // Step: Information
            _Steps.Create_InformationStep(NextStepNo, 'Information');
            _Steps.Set_header(MobWmsLanguage.GetMessage('TOTE_SHIPPING'));
            _Steps.Set_label(MobWmsLanguage.GetMessage('SCAN_REMAINING_TOTES'));
            _Steps.Set_helpLabel(StrSubstNo(MobWmsLanguage.GetMessage('SCAN_REMAINING_TOTES_INFO'), WhseShipmentHeader."No.") + RemainingToteString);
            NextStepNo += 10;

            // Create Scan Steps
            MobWmsRegistration.SetCurrentKey("Tote ID", "Whse. Document Type", "Whse. Document No.", "Whse. Document Line No.");
            MobWmsRegistration.SetFilter("Tote ID", RemainingToteFilter);
            MobWmsRegistration.SetRange("Whse. Shpmt. Exists", true);
            MobWmsRegistration.SetRange("Tote Handled", false);
            MobWmsRegistration.SetRange("Whse. Document Type", MobWmsRegistration."Whse. Document Type"::Shipment);
            MobWmsRegistration.SetRange("Whse. Document No.", ShipmentNo);
            if MobWmsRegistration.FindFirst() then begin
                case MobSetup."Tote per" of
                    MobSetup."Tote per"::"Destination No.":
                        begin
                            MobWmsRegistration.SetRange("Destination Type", MobWmsRegistration."Destination Type");
                            MobWmsRegistration.SetRange("Destination No.", MobWmsRegistration."Destination No.");
                        end;
                    MobSetup."Tote per"::"Source No.":
                        begin
                            MobWmsRegistration.SetRange("Source Type", MobWmsRegistration."Source Type");
                            MobWmsRegistration.SetRange("Source No.", MobWmsRegistration."Source No.");
                        end;
                end;
                if MobWmsRegistration.FindFirst() then
                    repeat
                        MobWmsRegistration.SetRange("Tote ID", MobWmsRegistration."Tote ID");
                        MobWmsRegistration.FindLast();

                        // Step: ToteID 
                        _Steps.Create_TextStep(NextStepNo, 'ToteID' + Format(NextStepNo));
                        _Steps.Set_header(MobWmsLanguage.GetMessage('TOTE_SHIPPING'));
                        _Steps.Set_label(MobWmsLanguage.GetMessage('TOTE_ID') + ': ');
                        _Steps.Set_helpLabel(MobWmsLanguage.GetMessage('SCAN_TOTE_ID') + ': ' + MobWmsRegistration."Tote ID");
                        _Steps.Set_helpLabelMaximize_WindowsMobile(true);
                        _Steps.Set_length(100);
                        _Steps.Set_validationValues(MobWmsRegistration."Tote ID");
                        // Make sure that the user can only scan the suggested totes
                        _Steps.Set_validationWarningType('Block');
                        _Steps.Set_validationCaseSensitive(false);
                        _Steps.Set_listSeparator(',');
                        _Steps.Set_optional(false);
                        NextStepNo += 10;

                        MobWmsRegistration.SetFilter("Tote ID", RemainingToteFilter);
                    until MobWmsRegistration.Next() = 0;
            end;
        end else begin
            // Step: OnlyOneTote
            _Steps.Create_InformationStep(NextStepNo, 'OnlyOneTote');
            _Steps.Set_header(MobWmsLanguage.GetMessage('TOTE_SHIPPING'));
            _Steps.Set_label(MobWmsLanguage.GetMessage('SCAN_REMAINING_TOTES'));
            _Steps.Set_helpLabel(MobWmsLanguage.GetMessage('NO_ADDITIONAL_TOTES'));
            NextStepNo += 10;
        end;

        // This is where collection of info for shipping systems should be made.

    end;

    local procedure PostToteShippingRegistration(var _RequestValues: Record "MOB NS Request Element"; _PostingMessageId: Guid; _XmlRequestDoc: XmlDocument; var _SuccessMessage: Text; var _ReturnRegistrationTypeTracking: Text)
    var
        MobSetup: Record "MOB Setup";
        MobReportPrintSetup: Record "MOB Report Print Setup";
        MobWmsRegistration: Record "MOB WMS Registration";
        Location: Record Location;
        WhseShipmentHeader: Record "Warehouse Shipment Header";
        WhseShipmentLine: Record "Warehouse Shipment Line";
        TempWhseShipmentLineLog: Record "Warehouse Shipment Line" temporary;
        AssemblyHeader: Record "Assembly Header";
        TempAtOItemTracking: Record "MOB WMS Registration" temporary;
        WhsePostShipment: Codeunit "Whse.-Post Shipment";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        MobTryEvent: Codeunit "MOB Try Event";
        XmlRequestNode: XmlNode;
        XmlRequestDataNode: XmlNode;
        XmlParameterNode: XmlNode;
        XmlNodesList: XmlNodeList;
        ShipmentNo: Code[20];
        ToteFilter: Text;
        i: Integer;
        Qty: Decimal;
    begin
        MobWmsToolbox.CheckWhseSetupShipment();

        // The Unplanned Tote Shipping feature expects ToteId values at all associated MobWmsRegistrations

        // Disable the locktimeout to prevent timeout messages on the mobile device
        LockTimeout(false);

        // Lock the tables to work on
        WhseShipmentHeader.LockTable();
        WhseShipmentLine.LockTable();
        MobWmsRegistration.LockTable();

        // Turn on commit protection to prevent unintentional committing data
        MobDocQueue.Consistent(false);

        // Extract ToteID* parameters and ATOItemTracking from the XML
        // The parameters are located in the <requestData> element
        // Loop over the registration values. We don't know which values will be present because it is configurable
        // The values are added to the relevant journal if they have been registered on the mobile device
        MobXmlMgt.GetDocRootNode(_XmlRequestDoc, XmlRequestNode);
        MobXmlMgt.FindNode(XmlRequestNode, MobWmsToolbox."CONST::requestData"(), XmlRequestDataNode);
        MobXmlMgt.GetNodeChildNodes(XmlRequestDataNode, XmlNodesList);
        for i := 1 to XmlNodesList.Count() do begin
            MobXmlMgt.GetListItem(XmlNodesList, XmlParameterNode, (i)); // AL = 1 based index
            if StrPos(MobXmlMgt.GetNodeName(XmlParameterNode), 'ToteID') <> 0 then
                if ToteFilter = '' then
                    ToteFilter := MobXmlMgt.GetNodeInnerText(XmlParameterNode)
                else
                    ToteFilter := ToteFilter + '|' + MobXmlMgt.GetNodeInnerText(XmlParameterNode);
            // Assemble to Order scenario
            CreateAtOItemTrackingEntries(XmlParameterNode, TempAtOItemTracking);
        end;

        MobSetup.Get();
        _ReturnRegistrationTypeTracking := ToteFilter;
        MobSessionData.SetRegistrationTypeTracking(_ReturnRegistrationTypeTracking);

        // Determine the one ShipmentNo to post (always posting against only a single WhseShipment)
        MobWmsRegistration.Reset();
        MobWmsRegistration.SetCurrentKey("Tote ID", "Whse. Document Type", "Whse. Document No.", "Whse. Document Line No.");
        MobWmsRegistration.SetFilter("Tote ID", ToteFilter);
        MobWmsRegistration.SetRange("Whse. Document Type", MobWmsRegistration."Whse. Document Type"::Shipment);
        MobWmsRegistration.SetRange("Whse. Shpmt. Exists", true);    // Despite naming, calculate if whse. shipment LINE exists
        MobWmsRegistration.SetRange("Tote Handled", false);
        MobWmsRegistration.SetRange(Type, MobWmsRegistration.Type::Pick);

        // Find shipment for last unhandled registration -- only this one shipment is posted despite multiple could exist (future improvement)
        MobWmsRegistration.FindLast();
        ShipmentNo := MobWmsRegistration."Whse. Document No.";
        WhseShipmentHeader.Get(ShipmentNo);

        // Check Locations Warehouse Setup
        Location.Get(WhseShipmentHeader."Location Code");
        if not (Location."Require Pick" and Location."Require Shipment") then
            Error(MobWmsLanguage.GetMessage('TOTE_SHIP_LOC_PICK_SHIP_ERROR'), WhseShipmentHeader."Location Code");

        // Set MOB Posting Message Id        
        WhseShipmentHeader."MOB Posting MessageId" := _PostingMessageId;

        // Set Posting date
        WhseShipmentHeader.Validate("Posting Date", WorkDate());
        WhseShipmentHeader."Shipment Date" := WorkDate();

        // Event
        OnPostAdhocRegistrationOnToteShipping_OnBeforeModifyWarehouseShipmentHeader(_RequestValues, ToteFilter, WhseShipmentHeader);
        WhseShipmentHeader.Modify(true);

        // -- Prepare WhseShipmentLines to be updated (not every WhseShipmentLine may have an associated MobileWmsRegistraion in this run)
        Clear(WhseShipmentLine);
        WhseShipmentLine.SetRange("No.", WhseShipmentHeader."No.");

        // Update lines shipment date
        WhseShipmentLine.ModifyAll("Shipment Date", WorkDate());

        // Update lines shipment qty.
        WhseShipmentLine.SetFilter("Qty. to Ship", '>0');
        WhseShipmentLine.ModifyAll("Qty. to Ship", 0, true);
        WhseShipmentLine.SetRange("Qty. to Ship");

        // Save original Whse. Shipment Lines to be able to recognize which source document lines was successfully posted in case of error
        SaveOriginalWhseShipmentLines(WhseShipmentLine, TempWhseShipmentLineLog);

        // MobRegistrations to handles
        MobWmsRegistration.Reset();
        MobWmsRegistration.SetCurrentKey("Tote ID", "Whse. Document Type", "Whse. Document No.", "Whse. Document Line No.");
        MobWmsRegistration.SetFilter("Tote ID", ToteFilter);
        MobWmsRegistration.SetRange("Whse. Document Type", MobWmsRegistration."Whse. Document Type"::Shipment);
        MobWmsRegistration.SetRange("Whse. Document No.", WhseShipmentHeader."No.");
        MobWmsRegistration.SetRange("Whse. Shpmt. Exists", true);    // Despite naming, calculate if whse. shipment LINE exists
        MobWmsRegistration.SetRange("Tote Handled", false);
        MobWmsRegistration.SetRange(Type, MobWmsRegistration.Type::Pick);
        MobWmsRegistration.FindSet();

        // Loop through MobWmsRegistrations and set WhseShipmentLine."Qty. to Ship" to the registered qty's
        repeat
            MobWmsRegistration.TestField("Whse. Document No.", WhseShipmentHeader."No.");
            MobWmsRegistration.TestField("Whse. Document Line No.");
            MobWmsRegistration.TestField("Tote ID");

            if WhseShipmentLine."Line No." <> MobWmsRegistration."Whse. Document Line No." then
                WhseShipmentLine.Get(MobWmsRegistration."Whse. Document No.", MobWmsRegistration."Whse. Document Line No.");

            if MobSetup."Use Base Unit of Measure" then
                Qty := WhseShipmentLine.CalcQty(MobWmsRegistration.Quantity)
            else begin
                MobWmsRegistration.TestField(UnitOfMeasure);
                Qty := MobWmsToolbox.CalcQtyNewUOMRounded(WhseShipmentLine."Item No.", MobWmsRegistration.Quantity, MobWmsRegistration.UnitOfMeasure, WhseShipmentLine."Unit of Measure Code");
            end;

            //Assemble to Order scenarios are covered by requiring picks to be complete (no partial tote-picking supported in AtO)
            if LineIsAtOPicked(MobWmsRegistration) then begin
                // "To Bin" changed from the one on the pick (To-Assembly-Bin) to the one on the Shipment Line
                WhseShipmentLine.Validate("Qty. to Ship", WhseShipmentLine."Qty. Outstanding");
                MobWmsRegistration.ToBin := WhseShipmentLine."Bin Code";

                // Add Item Tracking to any Assemble to Order Shipment Lines
                AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, MobWmsRegistration."Source No.");
                AddAtOItemTrackingEntries(AssemblyHeader."Item No.", WhseShipmentLine, TempAtOItemTracking);
            end else
                WhseShipmentLine.Validate("Qty. to Ship", WhseShipmentLine."Qty. to Ship" + Qty);

            if WhseShipmentLine."Bin Code" <> MobWmsRegistration.ToBin then begin
                WhseShipmentLine.SuspendStatusCheck(true);
                WhseShipmentLine.Validate("Bin Code", MobWmsRegistration.ToBin);
                WhseShipmentLine.SuspendStatusCheck(false);
            end;

            MobWmsToolbox.SaveRegistrationDataFromSource(WhseShipmentLine."Location Code", WhseShipmentLine."Item No.", WhseShipmentLine."Variant Code", MobWmsRegistration);

            OnPostAdhocRegistrationOnToteShipping_OnBeforeModifyRegistration(WhseShipmentLine, _RequestValues, MobWmsRegistration);
            MobWmsRegistration.Modify(true);

            OnPostAdhocRegistrationOnToteShipping_OnHandleRegistrationForWarehouseShipmentLine(MobWmsRegistration, _RequestValues, WhseShipmentLine);
            WhseShipmentLine.Modify();

        until MobWmsRegistration.Next() = 0;

        // Set Print Shipment
        if MobReportPrintSetup.PrintShipmentOnPostEnabled() then
            WhsePostShipment.SetPrint(true);

        // Event OnBeforePostShipment
        OnPostAdhocRegistrationOnToteShipping_OnBeforeRunWhsePostShipment(WhseShipmentLine, WhsePostShipment);

        // Turn off the commit protection and run post
        MobDocQueue.Consistent(true);
        Commit();

        // SetSuppressCommit not working even in BC16+ (data still committed even when error in eventsubscribers ie. ShipIt)
        // Post Whse Shipment, then manually update "Tote Handled" accordingly to which source documents was successfully posted
        if WhsePostShipment.Run(WhseShipmentLine) then begin
            UpdateIncomingWarehouseShipment(WhseShipmentHeader);
            MobWmsRegistration.ModifyAll("Tote Handled", true);
            Commit();   // Prevent error in CreateInboundTransferWarehouseDoc from rolling back partially commit
        end else begin
            UpdateIncomingWarehouseShipment(WhseShipmentHeader);
            UpdateToteHandledFromPostedOriginalWhseShipmentLines(TempWhseShipmentLineLog, ToteFilter);    // Some whse. shipment lines may be successfully posted
            Commit();
            MobSessionData.SetPreservedLastErrorCallStack();
            Error(GetLastErrorText());
        end;

        // If we have posted the shipment of an outbound transfer order then we automatically create the Receipt/Invt. Put-away
        if WhseShipmentLine."Source Document" = WhseShipmentLine."Source Document"::"Outbound Transfer" then
            MobWmsToolbox.CreateInboundTransferWarehouseDoc(WhseShipmentLine."Source No.");

        _SuccessMessage := MobWmsLanguage.GetMessage('POST_SUCCESS');

        Commit();

        // Event OnAfterPost
        MobTryEvent.RunEventOnUnplannedPosting('OnPostAdhocRegistration_OnAfterPostToteShipping', WhseShipmentLine, _RequestValues, _SuccessMessage);

        _ReturnRegistrationTypeTracking := MobSessionData.GetRegistrationTypeTracking();
    end;

    /// <summary>
    /// Save warehouse shipment lines prior to ToteShipping to facilitate updating "Tote Handled" based on actual shipped lines
    /// </summary>
    local procedure SaveOriginalWhseShipmentLines(var _WhseShipmentLine: Record "Warehouse Shipment Line"; var _TempWhseShipmentLineLog: Record "Warehouse Shipment Line")
    begin
        if _WhseShipmentLine.FindSet() then
            repeat
                _TempWhseShipmentLineLog := _WhseShipmentLine;
                _TempWhseShipmentLineLog.Insert();
            until _WhseShipmentLine.Next() = 0;
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

    /// <summary>
    /// For each original Whse. Shipment Line, check if something was shipped at that line, then update MobWmsRegistrations."Tote Handled" accordingly
    /// </summary>
    local procedure UpdateToteHandledFromPostedOriginalWhseShipmentLines(var _TempWhseShipmentLinesLog: Record "Warehouse Shipment Line"; _ToteFilter: Text)
    var
        WhseShipmentLine: Record "Warehouse Shipment Line";
        MobWmsRegistration: Record "MOB WMS Registration";
        LineExists: Boolean;
        IsPosted: Boolean;
    begin
        if _TempWhseShipmentLinesLog.FindSet() then
            repeat
                LineExists := WhseShipmentLine.Get(_TempWhseShipmentLinesLog."No.", _TempWhseShipmentLinesLog."Line No.");
                IsPosted :=
                    (not LineExists) or
                    (LineExists and (WhseShipmentLine."Qty. Shipped (Base)" <> _TempWhseShipmentLinesLog."Qty. Shipped (Base)"));

                if IsPosted then begin
                    // Set "Tote Handled" for MobRegistrations that was handled in posting
                    MobWmsRegistration.Reset();
                    MobWmsRegistration.SetCurrentKey("Whse. Document Type", "Whse. Document No.", "Whse. Document Line No.", "Tote ID");
                    MobWmsRegistration.SetRange("Whse. Document Type", MobWmsRegistration."Whse. Document Type"::Shipment);
                    MobWmsRegistration.SetRange("Whse. Document No.", _TempWhseShipmentLinesLog."No.");
                    MobWmsRegistration.SetRange("Whse. Document Line No.", _TempWhseShipmentLinesLog."Line No.");
                    MobWmsRegistration.SetFilter("Tote ID", _ToteFilter);
                    MobWmsRegistration.SetRange("Tote Handled", false);
                    MobWmsRegistration.SetRange(Type, MobWmsRegistration.Type::Pick);
                    MobWmsRegistration.ModifyAll("Tote Handled", true);
                end;
            until _TempWhseShipmentLinesLog.Next() = 0;
    end;

    local procedure FindRemaingToteIDs(var _ShipmentNo: Code[20]; _ToteId: Code[100]; var _RemainingToteString: Text[1024]; var _RemainingToteFilter: Text[1024])
    var
        MobSetup: Record "MOB Setup";
        MobWmsRegistration: Record "MOB WMS Registration";
        MobWmsLanguage: Codeunit "MOB WMS Language";
    begin
        MobSetup.Get();

        MobWmsRegistration.SetCurrentKey("Tote ID", "Whse. Document Type", "Whse. Document No.", "Whse. Document Line No.");
        MobWmsRegistration.SetRange("Tote ID", _ToteId);
        MobWmsRegistration.SetRange("Whse. Shpmt. Exists", true);
        MobWmsRegistration.SetRange("Tote Handled", false);
        MobWmsRegistration.SetRange("Whse. Document Type", MobWmsRegistration."Whse. Document Type"::Shipment);
        if MobWmsRegistration.FindLast() then begin
            case MobSetup."Tote per" of
                MobSetup."Tote per"::"Destination No.":
                    begin
                        MobWmsRegistration.SetRange("Destination Type", MobWmsRegistration."Destination Type");
                        MobWmsRegistration.SetRange("Destination No.", MobWmsRegistration."Destination No.");
                    end;
                MobSetup."Tote per"::"Source No.":
                    begin
                        MobWmsRegistration.SetRange("Source Type", MobWmsRegistration."Source Type");
                        MobWmsRegistration.SetRange("Source No.", MobWmsRegistration."Source No.");
                    end;
            end;
            _ShipmentNo := MobWmsRegistration."Whse. Document No.";
            MobWmsRegistration.SetRange("Whse. Document No.", _ShipmentNo);
        end else
            Error(MobWmsLanguage.GetMessage('TOTE_COMBINATION_NOT_FOUND'), _ToteId, _ShipmentNo);

        MobWmsRegistration.SetFilter("Tote ID", '<>%1', _ToteId);
        if MobWmsRegistration.FindSet() then
            repeat
                if _RemainingToteString = '' then begin
                    _RemainingToteString := MobWmsRegistration."Tote ID";
                    _RemainingToteFilter := MobWmsRegistration."Tote ID";
                end else
                    if StrPos(_RemainingToteString, MobWmsRegistration."Tote ID") = 0 then begin
                        _RemainingToteString := _RemainingToteString + ',' + MobWmsRegistration."Tote ID";
                        _RemainingToteFilter := _RemainingToteFilter + '|' + MobWmsRegistration."Tote ID";
                    end;
            until MobWmsRegistration.Next() = 0;
    end;

    local procedure CreateRegisterItemImageRegColConf(var _HeaderFilter: Record "MOB NS Request Element"; var _Steps: Record "MOB Steps Element") _ReturnRegistrationTypeTracking: Text
    var
        MobWmsLanguage: Codeunit "MOB WMS Language";
        ItemNumber: Code[20];
    begin
        // -- Now find the ItemNumber parameter
        ItemNumber := MobWmsToolbox.GetItemNumber(MobToolbox.ReadEAN(_HeaderFilter.GetValue('ItemNumber', true)));

        // Set the tracking value displayed in the document queue
        _ReturnRegistrationTypeTracking := ItemNumber;

        // Crreate the steps

        // Step: ImageCapture
        _Steps.Create_ImageCaptureStep(10, 'ImageCapture');
        _Steps.Set_header(MobWmsLanguage.GetMessage('ADD_IMAGE'));
        _Steps.Set_listSeparator(';');
        _Steps.Set_resolutionHeight_WindowsMobile(800);
        _Steps.Set_resolutionWidth_WindowsMobile(600);
    end;

    local procedure PostRegisterItemImage(var _RequestValues: Record "MOB NS Request Element"; var _SuccessMessage: Text; var _ReturnRegistrationTypeTracking: Text)
    var
        Item: Record Item;
        MobWmsLanguage: Codeunit "MOB WMS Language";
        MobWmsMedia: Codeunit "MOB WMS Media";
        ItemNumber: Code[20];
        ItemImage: Text;
    begin
        // Find the ItemNumber and ImageCapture
        ItemNumber := MobWmsToolbox.GetItemNumber(MobToolbox.ReadEAN(_RequestValues.GetValue('ItemNumber', true)));
        ItemImage := _RequestValues.GetValue('ImageCapture', true);
        // Do not allow multiple item images
        if ItemImage.Contains('§') then
            Error((MobWmsLanguage.GetMessage('NOT_MORE_THAN_ONE_IMAGE')));

        // Set the tracking value displayed in the document queue
        _ReturnRegistrationTypeTracking := StrSubstNo('%1 %2', Item.TableCaption(), ItemNumber);

        // Perform the posting
        if not Item.Get(ItemNumber) then
            Error(MobWmsLanguage.GetMessage('ITEM_EXIST_ERR'), ItemNumber);

        //Add image to Media Queue
        MobWmsMedia.AddImageToMediaQueue(Format(Item.RecordId()), ItemImage);

        _SuccessMessage := StrSubstNo(MobWmsLanguage.GetMessage('ITEM_IMAGE_REGISTERED'), ItemNumber);
    end;

    local procedure CreateRegisterImageRegColConf(var _HeaderFilter: Record "MOB NS Request Element"; var _Steps: Record "MOB Steps Element") _ReturnRegistrationTypeTracking: Text
    var
        MobWmsLanguage: Codeunit "MOB WMS Language";
        ReferenceID: Text;
    begin
        // -- Now find the ReferenceID parameter
        ReferenceID := _HeaderFilter.GetValue('ReferenceID', true);

        // Set the tracking value displayed in the document queue
        _ReturnRegistrationTypeTracking := ReferenceID;

        // Crreate the steps

        // Step: ImageCapture
        _Steps.Create_ImageCaptureStep(10, 'ImageCapture');
        _Steps.Set_header(MobWmsLanguage.GetMessage('ADD_IMAGE'));
        _Steps.Set_listSeparator(';');
        _Steps.Set_resolutionHeight_WindowsMobile(800);
        _Steps.Set_resolutionWidth_WindowsMobile(600);
    end;

    local procedure PostRegisterImage(var _RequestValues: Record "MOB NS Request Element"; var _SuccessMessage: Text; var _ReturnRegistrationTypeTracking: Text)
    var
        MobWmsLanguage: Codeunit "MOB WMS Language";
        MobWmsMedia: Codeunit "MOB WMS Media";
        RecRef: RecordRef;
        ReferenceID: RecordId;
        ImageIdsAndNotes: Text;
    begin
        // Find the ReferenceID and ImageCapture
        Evaluate(ReferenceID, _RequestValues.GetValue('ReferenceID', true));
        ImageIdsAndNotes := _RequestValues.GetValue('ImageCapture', true);

        _ReturnRegistrationTypeTracking := MobWmsToolbox."CONST::RegisterImage"() + ': ' + Format(ReferenceID);

        // Perform the posting
        if ImageIdsAndNotes = '' then
            Error(MobWmsLanguage.GetMessage('NO_PICTURE_TO_ATTACH'));

        RecRef.Get(ReferenceID); // Must exist

        //Add image to Media Queue
        MobWmsMedia.AddImageToMediaQueue(RecRef, ImageIdsAndNotes);

        _SuccessMessage := StrSubstNo(MobWmsLanguage.GetMessage('IMAGE_REGISTERED'), Format((ReferenceID)));
    end;

    local procedure PostToggleTotePicking(var _RequestValues: Record "MOB NS Request Element"; var _TempCurrentRegistrations: Record "MOB WMS Registration"; var _SuccessMessage: Text; var _ReturnRegistrationTypeTracking: Text)
    var
        WhseActivityHeader: Record "Warehouse Activity Header";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        BackendID: Code[20];
    begin
        Evaluate(BackendID, _RequestValues.GetValue('backendId', true));
        _ReturnRegistrationTypeTracking := MobWmsToolbox."CONST::ToggleTotePicking"() + ': ' + BackendID;

        WhseActivityHeader.Get(WhseActivityHeader.Type::Pick, BackendID);

        if not _TempCurrentRegistrations.IsEmpty() then
            Error('%1%2%3',
            MobWmsLanguage.GetMessage('PICK_STARTED_TOTE_PICKING_CANNOT_BE_CHANGED'),
                MobToolbox.CRLFSeparator() + MobToolbox.CRLFSeparator(),
                MobWmsLanguage.GetMessage('DELETE_ALL_REGISTRATIONS_AND_TRY_AGAIN'));

        // Toggle, including changing "Default" to "Yes" or "No"
        if WhseActivityHeader."MOB GetTotePickingEnabled"() then
            WhseActivityHeader.Validate("MOB Tote Picking Enabled", WhseActivityHeader."MOB Tote Picking Enabled"::No)
        else
            WhseActivityHeader.Validate("MOB Tote Picking Enabled", WhseActivityHeader."MOB Tote Picking Enabled"::Yes);

        WhseActivityHeader.Modify();

        Clear(_SuccessMessage); // Intentionally avoid confirmation message
    end;

    local procedure PostShipmentRegistration(var _RequestValues: Record "MOB NS Request Element"; var _SuccessMessage: Text; var _ReturnRegistrationTypeTracking: Text)
    var
        MobReportPrintSetup: Record "MOB Report Print Setup";
        WhseShipmentHeader: Record "Warehouse Shipment Header";
        WhseShipmentLine: Record "Warehouse Shipment Line";
        WhsePostShipment: Codeunit "Whse.-Post Shipment";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        ShipmentNo: Code[20];
        ExtDocNo: Code[35];
        ResultMessage: Text;
    begin
        // The values are added to the relevant journal if they have been registered on the mobile device

        // Disable the locktimeout to prevent timeout messages on the mobile device
        LockTimeout(false);

        ShipmentNo := _RequestValues.GetValue('ShipmentNo', true);
        ExtDocNo := _RequestValues.GetValue('ExtDocNo');

        _ReturnRegistrationTypeTracking := Format(ShipmentNo);

        // Update header
        WhseShipmentHeader.Get(ShipmentNo);
        WhseShipmentHeader.Validate("External Document No.", ExtDocNo);
        WhseShipmentHeader.Validate("Posting Date", WorkDate());
        WhseShipmentHeader."Shipment Date" := WorkDate();
        WhseShipmentHeader."MOB Posting MessageId" := MobDocQueue.MessageIDAsGuid();

        // Event 
        OnPostAdhocRegistrationOnPostShipment_OnBeforeModifyWarehouseShipmentHeader(_RequestValues, WhseShipmentHeader);
        WhseShipmentHeader.Modify(true);


        // Update lines
        WhseShipmentLine.SetRange("No.", WhseShipmentHeader."No.");
        WhseShipmentLine.ModifyAll("Shipment Date", WorkDate());

        // Set Print Shipment
        if MobReportPrintSetup.PrintShipmentOnPostEnabled() then
            WhsePostShipment.SetPrint(true);

        // Event
        OnPostAdhocRegistrationOnPostShipment_OnBeforeRunWhsePostShipment(WhseShipmentLine, WhsePostShipment);
        WhseShipmentLine.SetRange("No.", WhseShipmentHeader."No."); // Redundant SetRange to ensure never posting to other than current WhseShipmentHeader
        Commit();

        if WhseShipmentLine.FindFirst() then begin

            if not WhsePostShipment.Run(WhseShipmentLine) then begin
                ResultMessage := GetLastErrorText();
                MobSessionData.SetPreservedLastErrorCallStack();
                UpdateIncomingWarehouseShipment(WhseShipmentHeader);
                Commit();
                Error(ResultMessage);
            end else begin
                // The posting was successful
                ResultMessage := MobWmsLanguage.GetMessage('POST_SUCCESS');
                UpdateIncomingWarehouseShipment(WhseShipmentHeader);
                // If we have posted the shipment of an outbound transfer order then we automatically create the Receipt/Invt. Put-away
                if WhseShipmentLine."Source Document" = WhseShipmentLine."Source Document"::"Outbound Transfer" then
                    MobWmsToolbox.CreateInboundTransferWarehouseDoc(WhseShipmentLine."Source No.");
            end;

            _SuccessMessage := ResultMessage;
        end;
    end;

    local procedure LineIsAtOPicked(_MobWmsRegistration: Record "MOB WMS Registration"): Boolean
    var
        AssemblyLine: Record "Assembly Line";
        MobWmsLanguage: Codeunit "MOB WMS Language";
    begin
        if not (_MobWmsRegistration."Source Type" = 901) then   // 901 = Assembly Line
            exit(false);

        AssemblyLine.SetRange("Document No.", _MobWmsRegistration."Source No.");
        AssemblyLine.FindSet();
        repeat
            if AssemblyLine."Qty. Picked" <> AssemblyLine."Remaining Quantity" then
                Error(MobWmsLanguage.GetMessage('NOT_PARTIAL_SHIP'), _MobWmsRegistration."Whse. Document Type", _MobWmsRegistration."Whse. Document No.");
        until AssemblyLine.Next() = 0;

        exit(true);
    end;

    local procedure AddItemTrackingStepsIfToteContainsAtOLines(var _Steps: Record "MOB Steps Element"; var _NextStepNo: Integer; _ToteID: Code[100]; _ClearAtOTrackingCollected: Boolean)
    var
        MobSetup: Record "MOB Setup";
        MobTrackingSetup: Record "MOB Tracking Setup";
        MobWmsRegistration: Record "MOB WMS Registration";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        PreviousLineNo: Integer;
        RegisterExpirationDate: Boolean;
    begin
        Clear(PreviousLineNo);
        MobSetup.Get();

        MobWmsRegistration.SetCurrentKey("Tote ID", "Whse. Document Type", "Whse. Document No.", "Whse. Document Line No.");
        MobWmsRegistration.SetRange("Tote ID", _ToteID);
        MobWmsRegistration.SetRange("Whse. Document Type", MobWmsRegistration."Whse. Document Type"::Shipment);
        MobWmsRegistration.SetRange("Whse. Shpmt. Exists", true);
        MobWmsRegistration.SetRange("Tote Handled", false);
        if MobWmsRegistration.FindLast() then begin
            case MobSetup."Tote per" of
                MobSetup."Tote per"::"Destination No.":
                    begin
                        MobWmsRegistration.SetRange("Destination Type", MobWmsRegistration."Destination Type");
                        MobWmsRegistration.SetRange("Destination No.", MobWmsRegistration."Destination No.");
                    end;
                MobSetup."Tote per"::"Source No.":
                    begin
                        MobWmsRegistration.SetRange("Source Type", MobWmsRegistration."Source Type");
                        MobWmsRegistration.SetRange("Source No.", MobWmsRegistration."Source No.");
                    end;
            end;
            MobWmsRegistration.SetRange("Whse. Document No.", MobWmsRegistration."Whse. Document No.");
        end;

        // Remove the Tote filter and mark all MobWmsRegistrations on the shipment to have AtO Tracking Collected
        MobWmsRegistration.SetRange("Tote ID");
        if _ClearAtOTrackingCollected then
            MobWmsRegistration.ModifyAll("AtO Tracking Collected", false);
        MobWmsRegistration.SetRange("Tote ID", _ToteID);

        // The lines are sorted according to Warehouse Shipment Line No, so just run through them and collect Item Tracking for each Shipment Line needed
        MobWmsRegistration.SetRange("Source Type", 901);  // 901 = Assembly Line
        MobWmsRegistration.SetRange("AtO Tracking Collected", false);
        if MobWmsRegistration.FindSet() then
            repeat
                if MobWmsRegistration."Whse. Document Line No." <> PreviousLineNo then begin
                    WarehouseShipmentLine.Get(MobWmsRegistration."Whse. Document No.", MobWmsRegistration."Whse. Document Line No.");

                    // Check for needed Tracking
                    Clear(MobTrackingSetup);
                    MobTrackingSetup.DetermineWhseTrackingRequired(WarehouseShipmentLine."Item No.", RegisterExpirationDate);
                    // MobTrackingSetup.Tracking: Tracking values are unused in this scope

                    // Add steps for collecting necessary Item Tracking
                    // Serial number (should only be added if the item is serial tracked)
                    if MobTrackingSetup."Serial No. Required" then begin
                        // Step: SerialNumber
                        _Steps.Create_TextStep_SerialNumber(_NextStepNo, WarehouseShipmentLine."Item No.");
                        _Steps.Set_name('SerialNumber' + WarehouseShipmentLine."No." + '_' + Format(WarehouseShipmentLine."Line No."));
                        _NextStepNo += 10;
                    end;

                    // Lot number (should only be added if the item is lot tracked)
                    if MobTrackingSetup."Lot No. Required" then begin
                        // Step: LotNumber
                        _Steps.Create_TextStep_LotNumber(_NextStepNo, WarehouseShipmentLine."Item No.");
                        _Steps.Set_name('LotNumber' + WarehouseShipmentLine."No." + '_' + Format(WarehouseShipmentLine."Line No."));
                        _NextStepNo += 10;
                    end;

                    OnPostAdhocRegistrationOnToteShipping_OnAddStepsIfToteContainsAtoLines(WarehouseShipmentLine, MobTrackingSetup, _NextStepNo, _Steps);

                    // Expiration Date (should only be added if the item requires expiration date)
                    if RegisterExpirationDate then begin
                        // Step: ExpirationDate
                        _Steps.Create_DateStep_ExpirationDate(_NextStepNo, WarehouseShipmentLine."Item No.");
                        _Steps.Set_name('ExpirationDate' + WarehouseShipmentLine."No." + '_' + Format(WarehouseShipmentLine."Line No."));
                        _NextStepNo += 10;
                    end;

                end;
                PreviousLineNo := MobWmsRegistration."Whse. Document Line No.";

                // Remove the Tote filter and mark all AtO MobWmsRegistrations with Tracking Collected
                MobWmsRegistration.SetRange("Tote ID");
                MobWmsRegistration.ModifyAll("AtO Tracking Collected", true);

            until MobWmsRegistration.Next() = 0;
    end;

    local procedure CreateAtOItemTrackingEntries(_XmlParameterNode: XmlNode; var _TempAtOItemTracking: Record "MOB WMS Registration" temporary)
    begin
        // The request xml looks like this
        // <request name="PostAdhocRegistration" created="2018-03-22T13:09:49+01:00" xmlns="http://schemas.microsoft.com/Dynamics/Mobile/2007/04/Documents/Request">
        //  <requestData name="PostAdhocRegistration">
        //    <ToteID>box4</ToteID>
        //    <LotNumberSH000020_20000>newlot1</LotNumberSH000020_20000>
        //    <ExpirationDateSH000020_20000>30-03-2018</ExpirationDateSH000020_20000>
        //    <ToteID4>box3</ToteID4>
        //    <ToteID5>box5</ToteID5>
        //    <ExtDocNo>asdfqwer345</ExtDocNo>
        //    <RegistrationType>ToteShipping</RegistrationType>
        //  </requestData>
        // </request>

        if (StrPos(MobXmlMgt.GetNodeName(_XmlParameterNode), 'SerialNumber') = 1) and (CopyStr(MobXmlMgt.GetNodeName(_XmlParameterNode), 13) <> '') then begin
            Evaluate(_TempAtOItemTracking."Order No.", CopyStr(MobXmlMgt.GetNodeName(_XmlParameterNode), 13, StrPos(MobXmlMgt.GetNodeName(_XmlParameterNode), '_') - 13));
            Evaluate(_TempAtOItemTracking."Line No.", CopyStr(MobXmlMgt.GetNodeName(_XmlParameterNode), StrPos(MobXmlMgt.GetNodeName(_XmlParameterNode), '_') + 1));
            _TempAtOItemTracking.SerialNumber := MobXmlMgt.GetNodeInnerText(_XmlParameterNode);
            _TempAtOItemTracking.Insert();
        end;

        if (StrPos(MobXmlMgt.GetNodeName(_XmlParameterNode), 'LotNumber') = 1) and (CopyStr(MobXmlMgt.GetNodeName(_XmlParameterNode), 10) <> '') then begin
            Evaluate(_TempAtOItemTracking."Order No.", CopyStr(MobXmlMgt.GetNodeName(_XmlParameterNode), 10, StrPos(MobXmlMgt.GetNodeName(_XmlParameterNode), '_') - 10));
            Evaluate(_TempAtOItemTracking."Line No.", CopyStr(MobXmlMgt.GetNodeName(_XmlParameterNode), StrPos(MobXmlMgt.GetNodeName(_XmlParameterNode), '_') + 1));
            _TempAtOItemTracking.LotNumber := MobXmlMgt.GetNodeInnerText(_XmlParameterNode);
            if not _TempAtOItemTracking.Insert() then
                _TempAtOItemTracking.Modify();
        end;

        if (StrPos(MobXmlMgt.GetNodeName(_XmlParameterNode), 'ExpirationDate') = 1) and (CopyStr(MobXmlMgt.GetNodeName(_XmlParameterNode), 15) <> '') then begin
            Evaluate(_TempAtOItemTracking."Order No.", CopyStr(MobXmlMgt.GetNodeName(_XmlParameterNode), 15, StrPos(MobXmlMgt.GetNodeName(_XmlParameterNode), '_') - 15));
            Evaluate(_TempAtOItemTracking."Line No.", CopyStr(MobXmlMgt.GetNodeName(_XmlParameterNode), StrPos(MobXmlMgt.GetNodeName(_XmlParameterNode), '_') + 1));
            _TempAtOItemTracking.SerialNumber += ',' + MobXmlMgt.GetNodeInnerText(_XmlParameterNode);
            _TempAtOItemTracking.LotNumber += ',' + MobXmlMgt.GetNodeInnerText(_XmlParameterNode);
            if not _TempAtOItemTracking.Insert() then
                _TempAtOItemTracking.Modify();
        end;
    end;

    local procedure AddAtOItemTrackingEntries(_AssemblyHeaderItemNo: Code[20]; var _WhseShipmentLine: Record "Warehouse Shipment Line"; var _TempAtOItemTracking: Record "MOB WMS Registration" temporary)
    var
        ReservationEntry: Record "Reservation Entry";
        MobTrackingSetup: Record "MOB Tracking Setup";
        MobWmsShip: Codeunit "MOB WMS Ship";
        RegisterExpirationDate: Boolean;
        ExpirationDate: Date;
        ReservedQtyToHandleReset: Boolean;
    begin
        MobTrackingSetup.DetermineWhseTrackingRequired(_AssemblyHeaderItemNo, RegisterExpirationDate);
        MobTrackingSetup.CopyTrackingFromRegistrationIfRequired(_TempAtOItemTracking);

        if MobTrackingSetup.TrackingRequired() then begin
            _TempAtOItemTracking.SetRange("Order No.", _WhseShipmentLine."No.");
            _TempAtOItemTracking.SetRange("Line No.", _WhseShipmentLine."Line No.");
            _TempAtOItemTracking.FindFirst();

            if MobTrackingSetup.TrackingRequired() and RegisterExpirationDate then begin
                _TempAtOItemTracking.TestField("Expiration Date");
                ExpirationDate := _TempAtOItemTracking."Expiration Date";
            end else
                ExpirationDate := 0D;   // The expiration date is not registered.

            // In an AtO scenario, Order-to-Order bound Reservation Entries will always exist. These must be updated with collected Item Tracking
            if MobWmsShip.ReservEntriesExist(_WhseShipmentLine, ReservationEntry, MobTrackingSetup, ReservedQtyToHandleReset, 0) then begin
                MobTrackingSetup.CopyTrackingToReservEntry(ReservationEntry);
                ReservationEntry."Expiration Date" := ExpirationDate;
                ReservationEntry.UpdateItemTracking();
                ReservationEntry.Validate("Quantity (Base)", -_WhseShipmentLine."Qty. (Base)");
                ReservationEntry.Modify();
                // And the other leg...
                ReservationEntry.Get(ReservationEntry."Entry No.", not ReservationEntry.Positive);
                MobTrackingSetup.CopyTrackingToReservEntry(ReservationEntry);
                ReservationEntry."Expiration Date" := ExpirationDate;
                ReservationEntry.UpdateItemTracking();
                ReservationEntry.Validate("Quantity (Base)", _WhseShipmentLine."Qty. (Base)");
                ReservationEntry.Modify();
            end;

        end;
    end;

    procedure PostItemJnlLine(_ItemJnlLine2Post: Record "Item Journal Line"; var _ItemJnlLineCopy: Record "Item Journal Line")
    var
        MobSetup: Record "MOB Setup";
        MobTrackingSetup: Record "MOB Tracking Setup";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
        NetNegativeAdjmt: Boolean;
    begin
        // Post Item Journal Line
        MobSetup.Get();

        // Make copy of Item Journal Line to preserve Quantity according to Unit of Measure
        _ItemJnlLineCopy.Copy(_ItemJnlLine2Post);

        // Check for Reservations like Base does
        if MobSetup."Block Neg. Adj. if Resv Exists" and IsNotInternalWhseMovement(_ItemJnlLine2Post) then begin
            NetNegativeAdjmt := _ItemJnlLine2Post.Signed(_ItemJnlLine2Post.Quantity) < 0;
            if NetNegativeAdjmt then begin
                MobTrackingSetup.ClearTrackingRequired();
                MobTrackingSetup.CopyTrackingFromItemJnlLine(_ItemJnlLine2Post);
                MobAvailability.ItemJnlPostBatch_CheckItemAvailability(_ItemJnlLine2Post."Location Code",
                                                                            _ItemJnlLine2Post."Item No.",
                                                                            _ItemJnlLine2Post."Variant Code",
                                                                            MobTrackingSetup,
                                                                            Abs(_ItemJnlLine2Post.Quantity),
                                                                            MobToolbox.AsInteger(_ItemJnlLine2Post."Order Type"),
                                                                            _ItemJnlLine2Post."Order No.");
            end;
        end;
        ItemJnlPostLine.RunWithCheck(_ItemJnlLine2Post);
    end;

    local procedure IsNotInternalWhseMovement(_ItemJnlLine: Record "Item Journal Line"): Boolean
    begin
        /* #if BC18+ */
        exit(_ItemJnlLine.IsNotInternalWhseMovement());
        /* #endif */
        /* #if BC17- ##
        exit(
          not ((_ItemJnlLine."Entry Type" = _ItemJnlLine."Entry Type"::Transfer) and
               (_ItemJnlLine."Location Code" = _ItemJnlLine."New Location Code") and
               (_ItemJnlLine."Dimension Set ID" = _ItemJnlLine."New Dimension Set ID") and
               (_ItemJnlLine."Value Entry Type" = _ItemJnlLine."Value Entry Type"::"Direct Cost") and
               not _ItemJnlLine.Adjustment));
        /* #endif */
    end;

    procedure RegisterWhseJnlLine(var _TmpWhseJnlLine: Record "Warehouse Journal Line" temporary; _SourceJnl: Integer; _TransferTo: Boolean)
    var
        MobSetup: Record "MOB Setup";
        MobTrackingSetup: Record "MOB Tracking Setup";
        WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line";
        WMSMgt: Codeunit "WMS Management";
        NetNegativeAdjmt: Boolean;
    begin
        // Post Whse Journal Line
        MobSetup.Get();

        // SourceJnl 1 = Item Journal, 4 = Whse Journal
        // Copied Validation from Base CU7304 "Whse. Jnl.-Register Batch"


        // Set current Warehouse Register record. This is critical in e.g. "Unplanned Move" non-directed with Bins, when this function is called twice
        WhseJnlRegisterLine.SetWhseRegister(GlobalWarehouseRegister);

        // Check for Reservations like Base does
        if MobSetup."Block Neg. Adj. if Resv Exists" then begin
            NetNegativeAdjmt :=
                ((_TmpWhseJnlLine."Entry Type" = _TmpWhseJnlLine."Entry Type"::"Negative Adjmt.") and (_TmpWhseJnlLine.Quantity > 0)) or
                ((_TmpWhseJnlLine."Entry Type" = _TmpWhseJnlLine."Entry Type"::"Positive Adjmt.") and (_TmpWhseJnlLine.Quantity < 0));  // Movement intentionally ignored
            if NetNegativeAdjmt then begin
                MobTrackingSetup.ClearTrackingRequired();
                MobTrackingSetup.CopyTrackingFromWhseJnlLine(_TmpWhseJnlLine);
                MobAvailability.WhseJnlRegisterBatch_CheckItemAvailability(_TmpWhseJnlLine."Location Code",
                                                                                _TmpWhseJnlLine."Item No.",
                                                                                _TmpWhseJnlLine."Variant Code",
                                                                                MobTrackingSetup,
                                                                                Abs(_TmpWhseJnlLine.Quantity));
            end;
        end;

        // DecreaseQtyBase=0 since WarehouseJnlLine is in-memory only (never inserted into DB)
        WMSMgt.CheckWhseJnlLine(_TmpWhseJnlLine, _SourceJnl, 0, _TransferTo);
        // Post
        WhseJnlRegisterLine.Run(_TmpWhseJnlLine);
        // Save the current Warehouse Register
        WhseJnlRegisterLine.GetWhseRegister(GlobalWarehouseRegister);
    end;


    local procedure Internal(var _RequestValues: Record "MOB NS Request Element"; var _SuccessMessage: Text; var _ReturnRegistrationTypeTracking: Text)
    var
        MobTesthelper: Codeunit "MOB Test Helper";
        ActionText: Text;
        NoOfOrders: Integer;
        NoOfLines: Integer;
        LocationCode: Code[20];
    begin
        // Internal functionality

        //<request name="GetRegistrationConfiguration" created="2018-03-14T14:08:24+01:00" xmlns="http://schemas.microsoft.com/Dynamics/Mobile/2007/04/Documents/Request">
        //  <requestData name="Internal">
        //    <RegistrationType>Internal</RegistrationType>
        //    <Action>CreatePurchaseOrders</Action>
        //    <Parameter01>2</Parameter01>
        //    <Parameter02>40</Parameter02>
        //    <Parameter03>WHITE</Parameter03>
        //  </requestData>
        //</request>

        _ReturnRegistrationTypeTracking := _RequestValues.GetValue(RegistrationTypeTok, false);
        ActionText := _RequestValues.GetValue(ActionTok, false);
        NoOfOrders := _RequestValues.GetValueAsInteger(ParameterTok + '01', false);
        NoOfLines := _RequestValues.GetValueAsInteger(ParameterTok + '02', false);
        LocationCode := _RequestValues.GetValue(ParameterTok + '03', false);

        case ActionText of
            CreatePurchaseOrdersTok:
                begin
                    MobTesthelper.CreatePurchaseOrders(NoOfOrders, NoOfLines, LocationCode, '');
                    _SuccessMessage := '';
                end;
        end;
    end;

    local procedure GetRegistrationConfigProdUnplannedConsumption(var _TempHeaderFieldValues: Record "MOB NS Request Element" temporary; var _TempSteps: Record "MOB Steps Element" temporary; var _RegistrationTypeTracking: Text)
    var
        MobProdUnplannedConsumption: Codeunit "MOB ProdUnplannedConsumption";
    begin
        MobProdUnplannedConsumption.GetRegistrationConfiguration(_TempHeaderFieldValues, _TempSteps, _RegistrationTypeTracking);
    end;

    local procedure PostProdUnplannedConsumption(var _TempRequestValues: Record "MOB NS Request Element" temporary; var _RegistrationTypeTracking: Text)
    var
        MobProdUnplannedConsumption: Codeunit "MOB ProdUnplannedConsumption";
        SuccessMessage: Text;
    begin
        MobProdUnplannedConsumption.Post(_TempRequestValues, _RegistrationTypeTracking, SuccessMessage);
        MobToolbox.CreateSimpleResponse(XmlResponseDoc, SuccessMessage);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetRegistrationConfigurationOnCustomRegistrationType_OnAddStepsAsXml(var _XMLRequestDoc: XmlDocument; var _XMLSteps: XmlNode; _RegistrationType: Text; var _RegistrationTypeTracking: Text[200]; var _IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetRegistrationConfiguration_OnBeforeAddSteps(_RegistrationType: Text; var _HeaderFieldValues: Record "MOB NS Request Element"; var _Steps: Record "MOB Steps Element"; var _RegistrationTypeTracking: Text; var _IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetRegistrationConfiguration_OnAddSteps(_RegistrationType: Text; var _HeaderFieldValues: Record "MOB NS Request Element"; var _Steps: Record "MOB Steps Element"; var _RegistrationTypeTracking: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnGetRegistrationConfigurationOnProdOutput_OnAddStepsToProductionOutputTimeTracking(var _LookupResponse: Record "MOB NS WhseInquery Element"; var _Steps: Record "MOB Steps Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnGetRegistrationConfigurationOnProdOutput_OnAddStepsToProductionOutput(var _LookupResponse: Record "MOB NS WhseInquery Element"; var _Steps: Record "MOB Steps Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnGetRegistrationConfigurationOnProdOutput_OnAddStepsToProductionOutputQuantity(var _LookupResponse: Record "MOB NS WhseInquery Element"; var _Steps: Record "MOB Steps Element")
    begin
    end;

    /// <param name="_RegistrationType">'ProdOutputQuantity' = Called from Adhoc Action; 'ProdOutput' = Called from element list by clicking the element</param>
    [IntegrationEvent(false, false)]
    internal procedure OnGetRegistrationConfigurationOnProdOutput_OnAfterAddStepToProductionOutputQuantity(_RegistrationType: Text; var _LookupResponse: Record "MOB NS WhseInquery Element"; var _Step: Record "MOB Steps Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnGetRegistrationConfigurationOnProdOutput_OnAddStepsToProductionOutputTime(var _LookupResponse: Record "MOB NS WhseInquery Element"; _IncludeAllSteps: Boolean; var _Steps: Record "MOB Steps Element")
    begin
    end;

    /// <param name="_RegistrationType">'ProdOutputTime' = Called from Adhoc Action; 'ProdOutput' = Called from element list by clicking the element</param>
    [IntegrationEvent(false, false)]
    internal procedure OnGetRegistrationConfigurationOnProdOutput_OnAfterAddStepToProductionOutputTime(_RegistrationType: Text; var _LookupResponse: Record "MOB NS WhseInquery Element"; var _Step: Record "MOB Steps Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnGetRegistrationConfigurationOnProdOutput_OnAddStepsToProductionOutputScrap(var _LookupResponse: Record "MOB NS WhseInquery Element"; _IncludeAllSteps: Boolean; var _Steps: Record "MOB Steps Element")
    begin
    end;

    /// <param name="_RegistrationType">'ProdOutputScrap' = Called from Adhoc Action; 'ProdOutput' = Called from element list by clicking the element</param>
    [IntegrationEvent(false, false)]
    internal procedure OnGetRegistrationConfigurationOnProdOutput_OnAfterAddStepToProductionOutputScrap(_RegistrationType: Text; var _LookupResponse: Record "MOB NS WhseInquery Element"; var _Step: Record "MOB Steps Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetRegistrationConfiguration_OnAfterAddStep(_RegistrationType: Text; var _HeaderFieldValues: Record "MOB NS Request Element"; var _Step: Record "MOB Steps Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostAdhocRegistration_OnAddSteps(_RegistrationType: Text; var _RequestValues: Record "MOB NS Request Element"; var _Steps: Record "MOB Steps Element"; var _RegistrationTypeTracking: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostAdhocRegistrationOnCustomRegistrationType(_MessageId: Guid; _RegistrationType: Text; var _RequestValues: Record "MOB NS Request Element"; var _CurrentRegistrations: Record "MOB WMS Registration"; _Commands: Record "MOB Command Element"; var _SuccessMessage: Text; var _RegistrationTypeTracking: Text; var _IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostAdhocRegistrationOnCustomRegistrationTypeAsXml(_MessageId: Guid; var _XMLRequestDoc: XmlDocument; var _XMLResponseDoc: XmlDocument; _RegistrationType: Text; var _RegistrationTypeTracking: Text[200]; var _IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnPostAdhocRegistration_OnAfterPostToteShipping(_WhseShipmentLine: Record "Warehouse Shipment Line"; var _RequestValues: Record "MOB NS Request Element"; var _SuccessMessage: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnPostAdhocRegistrationOnUnplannedMove_OnAfterCreateItemJnlLine(var _RequestValues: Record "MOB NS Request Element"; _ReservationEntry: Record "Reservation Entry"; var _ItemJnlLine: Record "Item Journal Line")
    begin
        // In addition use "WMS Management".OnAfterCreateWhseJnlLine() to handle In- and Outbound transfer Warehouse Journal Lines when posting though ItemJnl (when no Location."Directed Put-away and Pick")
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnPostAdhocRegistrationOnUnplannedMove_OnAfterCreateWhseJnlLine(var _RequestValues: Record "MOB NS Request Element"; var _WhseJnlLine: Record "Warehouse Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostAdhocRegistrationOnUnplannedCount_OnAfterCreateItemJnlLine(var _RequestValues: Record "MOB NS Request Element"; _ReservationEntry: Record "Reservation Entry"; var _ItemJnlLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostAdhocRegistrationOnUnplannedCount_OnAfterCreateWhseJnlLine(var _RequestValues: Record "MOB NS Request Element"; var _WhseJnlLine: Record "Warehouse Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostAdhocRegistrationOnAdjustQuantity_OnAfterCreateItemJnlLine(var _RequestValues: Record "MOB NS Request Element"; _ReservationEntry: Record "Reservation Entry"; var _ItemJnlLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostAdhocRegistrationOnAdjustQuantity_OnAfterCreateWhseJnlLine(var _RequestValues: Record "MOB NS Request Element"; var _WhseJnlLine: Record "Warehouse Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostAdhocRegistrationOnAddCountLine_OnAfterCreateItemJnlLine(var _RequestValues: Record "MOB NS Request Element"; var _ItemJnlLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostAdhocRegistrationOnAddCountLine_OnAfterCreateWhseJnlLine(var _RequestValues: Record "MOB NS Request Element"; var _WhseJnlLine: Record "Warehouse Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostAdhocRegistrationOnBulkMove_OnSetFilterBinContent(var _RequestValues: Record "MOB NS Request Element"; var _BinContent: Record "Bin Content")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostAdhocRegistrationOnBulkMove_OnAfterCreateItemJnlLine(var _RequestValues: Record "MOB NS Request Element"; var _ItemJnlLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostAdhocRegistrationOnBulkMove_OnAfterCreateWhseJnlLine(var _RequestValues: Record "MOB NS Request Element"; var _WhseJnlLine: Record "Warehouse Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostAdhocRegistrationOnItemDimensions_OnBeforeInsertModifyItemUnitOfMeasure(var _RequestValues: Record "MOB NS Request Element"; var _ItemUnitOfMeasure: Record "Item Unit of Measure")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostAdhocRegistrationOnToteShipping_OnAddStepsIfToteContainsAtoLines(_WhseShptLine: Record "Warehouse Shipment Line"; _MobTrackingSetup: Record "MOB Tracking Setup"; var _NextStepNo: Integer; var _Steps: Record "MOB Steps Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostAdhocRegistrationOnToteShipping_OnBeforeModifyWarehouseShipmentHeader(var _RequestValues: Record "MOB NS Request Element"; _ToteFilter: Text; var _WhseShptHeader: Record "Warehouse Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostAdhocRegistrationOnToteShipping_OnBeforeModifyRegistration(_WhseShptLine: Record "Warehouse Shipment Line"; var _RequestValues: Record "MOB NS Request Element"; var _Registration: Record "MOB WMS Registration")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostAdhocRegistrationOnToteShipping_OnHandleRegistrationForWarehouseShipmentLine(var _Registration: Record "MOB WMS Registration"; var _RequestValues: Record "MOB NS Request Element"; var _WhseShptLine: Record "Warehouse Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostAdhocRegistrationOnToteShipping_OnBeforeRunWhsePostShipment(var _WhseShptLine: Record "Warehouse Shipment Line"; var _WhsePostShipment: Codeunit "Whse.-Post Shipment")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostAdhocRegistrationOnPostShipment_OnBeforeModifyWarehouseShipmentHeader(var _RequestValues: Record "MOB NS Request Element"; var _WhseShptHeader: Record "Warehouse Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostAdhocRegistrationOnPostShipment_OnBeforeRunWhsePostShipment(var _WhseShptLine: Record "Warehouse Shipment Line"; var _WhsePostShipment: Codeunit "Whse.-Post Shipment")
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnPostAdhocRegistrationOnProdOutput_OnAfterCreateProductionJnlLine(var _RequestValues: Record "MOB NS Request Element"; var _ProductionJnlLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostAdhocRegistration_OnAfterPost(_MessageId: Guid; _RegistrationType: Text; var _RequestValues: Record "MOB NS Request Element"; var _XmlResponseDoc: XmlDocument; var _RegistrationTypeTracking: Text)
    begin
    end;

}

