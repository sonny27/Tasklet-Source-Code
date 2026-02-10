codeunit 82217 "MOB License Plate Mgt"
{
    Access = Public;
    /// <summary>
    /// _License Plate Object ID range: 6182217 - 6182229
    /// </summary>

    var
        MobSetup: Record "MOB Setup";
        MobToolbox: Codeunit "MOB Toolbox";
        LicensePlateMoveErr: Label 'You cannot move License Plate %1 into License Plate %2 as it would create a circular containment:\\%3\\A License Plate cannot be placed inside a License Plate it already contains.', Comment = '%1 contains the License Plate No. being moved, %2 contains the To License Plate No., %3 is the path (e.g. "LP1 - LP2 - LP3 - LP1")';
        LicensePlateKeyErr: Label 'No valid %1 found.\\Enabling License Plating requires you to reach out to Tasklet through your Partner to learn about the possibilities and limitations of License Plating in Mobile WMS.\\Tasklet will then supply you with a free key to enable the feature.', Comment = '%1 is the fieldcaption: "License Plating Key"', Locked = true;
        EnableLicensePlatingMsg: Label 'This will configure the %1 Company for License Plating. Please see the documentation for details.\\Are you sure you want to continue?', Comment = '%1 is the name of the current company. Please don''t translate the term "License Plating"';
        LicensePlatingEnabledMsg: Label 'License Plating was successfully enabled.\\All mobile users must sign out and sign in again.';
        DisableLicensePlatingMsg: Label 'This will disable License Plating in the %1 Company. Please see the documentation for details.\\Are you sure you want to continue?', Comment = '%1 is the name of the current company. Please don''t translate the term "License Plating"';
        LicensePlatingDisabledMsg: Label 'License Plating was successfully disabled.\\All mobile users must sign out and sign in again.';
        LegacyPackAndShipDetectedErr: Label 'Pack & Ship has previously been detected - You must complete the data migration', Locked = true;

    // 'AddLicensePlate', 'AllContentToNewLicensePlate', 'AllToNewLicensePlate'
    internal procedure GetNextLicensePlateNo(_ModifySeries: Boolean): Code[20]
    var
        MobNoSeries: Codeunit "MOB No. Series";
    begin
        MobSetup.Get();
        MobSetup.TestField("LP Number Series");
        exit(MobNoSeries.GetNextNo(MobSetup."LP Number Series", WorkDate(), _ModifySeries));
    end;

    // 'LicensePlateContentLookup', 'MoveLicensePlate', 'Whse.-Activity-Register Ext'
    internal procedure GetNextLicensePlateContentLineNo(_LicensePlate: Record "MOB License Plate"): Integer
    var
        MobLicensePlateContent: Record "MOB License Plate Content";
    begin
        MobLicensePlateContent.SetRange("License Plate No.", _LicensePlate."No.");
        if MobLicensePlateContent.FindLast() then
            exit(MobLicensePlateContent."Line No." + 10000)
        else
            exit(10000);
    end;

    /// <summary>
    /// Based on a License Plate Content, Get a list of possible License Plates the current content record can be moved to.
    /// This list will include all License Plates associated to the current warehouse shipment but exclude the parent license plate of the content to be moved (and the content license plate itself).
    /// </summary>
    // 'LicensePlateContentLookup'
    internal procedure GetLicensePlatesAsListValues(_LicensePlateContent: Record "MOB License Plate Content"): Text
    var
        ToLicensePlate: Record "MOB License Plate";
        LicensePlateListAsTxt: Text;
    begin
        ToLicensePlate.SetRange("Whse. Document Type", _LicensePlateContent."Whse. Document Type");
        ToLicensePlate.SetRange("Whse. Document No.", _LicensePlateContent."Whse. Document No.");

        if _LicensePlateContent.Type = _LicensePlateContent.Type::"License Plate" then
            ToLicensePlate.SetFilter("No.", '<>%1&<>%2', _LicensePlateContent."License Plate No.", _LicensePlateContent."No.") // Filter out Parent LP and it self
        else
            ToLicensePlate.SetFilter("No.", '<>%1', _LicensePlateContent."License Plate No.");

        if ToLicensePlate.FindSet() then begin
            LicensePlateListAsTxt += ';';
            repeat
                if IsValidToLicensePlate(_LicensePlateContent."No.", ToLicensePlate."No.") then
                    LicensePlateListAsTxt += ToLicensePlate."No." + ';';
            until ToLicensePlate.Next() = 0;
        end;

        if LicensePlateListAsTxt <> '' then
            LicensePlateListAsTxt := DelStr(LicensePlateListAsTxt, StrLen(LicensePlateListAsTxt), 1);

        exit(LicensePlateListAsTxt);
    end;

    /// <summary>
    /// Based on a License Plate, Get a list of possible License Plates the Current License Plate can be moved to.
    /// This list will include all License Plates associated to the current warehouse shipment but exclude the License plate itself.
    /// </summary>
    // 'MoveLicensePlates'
    internal procedure GetLicensePlatesAsListValues(_LicensePlate: Record "MOB License Plate"): Text
    var
        ToLicensePlate: Record "MOB License Plate";
        LicensePlateListAsTxt: Text;
    begin
        ToLicensePlate.SetRange("Whse. Document Type", _LicensePlate."Whse. Document Type");
        ToLicensePlate.SetRange("Whse. Document No.", _LicensePlate."Whse. Document No.");
        ToLicensePlate.SetFilter("No.", '<>%1', _LicensePlate."No.");

        if ToLicensePlate.FindSet() then begin
            LicensePlateListAsTxt += ';';
            repeat
                if IsValidToLicensePlate(_LicensePlate."No.", ToLicensePlate."No.") then
                    LicensePlateListAsTxt += ToLicensePlate."No." + ';';
            until ToLicensePlate.Next() = 0;
        end;

        if LicensePlateListAsTxt <> '' then
            LicensePlateListAsTxt := DelStr(LicensePlateListAsTxt, StrLen(LicensePlateListAsTxt), 1);

        exit(LicensePlateListAsTxt);
    end;

    /// <summary>
    /// Synchronize Specific fields from a license plate to same field on all child license plates and License Plate Contents
    /// The function is called from LP.OnValidates and therefore requires the LP to be Modified in the same transaction (should be re-designed if the fields are to be made editable on a page)
    /// </summary>
    internal procedure SynchronizeChildLicensePlatesFields(_LicensePlate: Record "MOB License Plate"; _xRecLicensePlate: Record "MOB License Plate")
    var
        MobLicensePlateContent: Record "MOB License Plate Content";
        ChildLicensePlate: Record "MOB License Plate";
    begin
        // Handle changes to Fields 'Whse. Document Type' + 'Whse. Document No.' + 'Receipt Status' on LP contents and any Child LP
        if (_LicensePlate."Whse. Document Type" <> _xRecLicensePlate."Whse. Document Type") or
           (_LicensePlate."Whse. Document No." <> _xRecLicensePlate."Whse. Document No.") or
           (_LicensePlate."Receipt Status" <> _xRecLicensePlate."Receipt Status")
        then begin
            MobLicensePlateContent.Reset();
            MobLicensePlateContent.SetRange("License Plate No.", _LicensePlate."No.");
            MobLicensePlateContent.SetFilter("No.", '<>%1', '');
            if MobLicensePlateContent.FindSet(true) then
                repeat
                    case MobLicensePlateContent.Type of
                        MobLicensePlateContent.Type::Item:
                            begin
                                MobLicensePlateContent.Validate("Whse. Document Type", _LicensePlate."Whse. Document Type");
                                MobLicensePlateContent.Validate("Whse. Document No.", _LicensePlate."Whse. Document No.");
                                // Clear the document reference when the LP is not linked to a warehouse document
                                if _LicensePlate."Whse. Document No." = '' then begin
                                    MobLicensePlateContent.Validate("Whse. Document Line No.", 0);
                                    MobLicensePlateContent.Validate("Source Document", MobLicensePlateContent."Source Document"::" ");
                                    MobLicensePlateContent.Validate("Source Type", 0);
                                    MobLicensePlateContent.Validate("Source No.", '');
                                    MobLicensePlateContent.Validate("Source Line No.", 0);
                                end;
                                MobLicensePlateContent.Modify(true);
                            end;
                        MobLicensePlateContent.Type::"License Plate":
                            begin
                                ChildLicensePlate.Get(MobLicensePlateContent."No.");
                                ChildLicensePlate.Validate("Whse. Document Type", _LicensePlate."Whse. Document Type");
                                ChildLicensePlate.Validate("Whse. Document No.", _LicensePlate."Whse. Document No.");
                                ChildLicensePlate.Validate("Receipt Status", _LicensePlate."Receipt Status"); // Shipment Status get updated by PackMgt.CheckLicensePlatePackageInfo (via OnModify)
                                ChildLicensePlate.Modify(true);
                            end;
                    end;
                until MobLicensePlateContent.Next() = 0;
        end;

        // Handle changes to Fields Location Code + Bin Code on LP contents and any Child LP
        if (_LicensePlate."Location Code" <> _xRecLicensePlate."Location Code") or (_LicensePlate."Bin Code" <> _xRecLicensePlate."Bin Code") then begin
            MobLicensePlateContent.Reset();
            MobLicensePlateContent.SetRange("License Plate No.", _LicensePlate."No.");
            if MobLicensePlateContent.FindSet(true) then
                repeat
                    case MobLicensePlateContent.Type of
                        MobLicensePlateContent.Type::Item:
                            begin
                                if _LicensePlate."Location Code" <> _xRecLicensePlate."Location Code" then begin
                                    MobLicensePlateContent.Validate("Bin Code", '');
                                    MobLicensePlateContent.Validate("Location Code", _LicensePlate."Location Code");
                                end;
                                if _LicensePlate."Bin Code" <> _xRecLicensePlate."Bin Code" then
                                    MobLicensePlateContent.Validate("Bin Code", _LicensePlate."Bin Code");
                                MobLicensePlateContent.Modify(true);
                            end;
                        MobLicensePlateContent.Type::"License Plate":
                            begin
                                ChildLicensePlate.Get(MobLicensePlateContent."No.");
                                if _LicensePlate."Location Code" <> _xRecLicensePlate."Location Code" then begin
                                    ChildLicensePlate.Validate("Bin Code", '');
                                    ChildLicensePlate.Validate("Location Code", _LicensePlate."Location Code");
                                end;
                                if _LicensePlate."Bin Code" <> _xRecLicensePlate."Bin Code" then
                                    ChildLicensePlate.Validate("Bin Code", _LicensePlate."Bin Code");
                                ChildLicensePlate.Modify(true);
                            end;
                    end;
                until MobLicensePlateContent.Next() = 0;
        end;

        // Handle changes to Field 'Transferred to Shipping' and 'Shipping Status' on all related Child LP´s
        if (_LicensePlate."Transferred to Shipping" <> _xRecLicensePlate."Transferred to Shipping") or (_LicensePlate."Shipping Status" <> _xRecLicensePlate."Shipping Status") then begin
            MobLicensePlateContent.Reset();
            MobLicensePlateContent.SetRange("License Plate No.", _LicensePlate."No.");
            MobLicensePlateContent.SetRange(Type, MobLicensePlateContent.Type::"License Plate");
            MobLicensePlateContent.SetFilter("No.", '<>%1', '');
            if MobLicensePlateContent.FindSet() then
                repeat
                    ChildLicensePlate.Get(MobLicensePlateContent."No.");
                    ChildLicensePlate.Validate("Transferred to Shipping", _LicensePlate."Transferred to Shipping");
                    ChildLicensePlate.Validate("Shipping Status", _LicensePlate."Shipping Status");
                    ChildLicensePlate.Modify(true);
                until MobLicensePlateContent.Next() = 0;
        end;
    end;

    // 'MOB Print License Plate'
    procedure GetLicensePlateStructureAsText(_LicensePlateContent: Record "MOB License Plate Content"; var _InputTxt: Text)
    var
        MobLicensePlateContent: Record "MOB License Plate Content";
    begin
        MobLicensePlateContent.SetRange(Type, MobLicensePlateContent.Type::"License Plate");
        MobLicensePlateContent.SetRange("No.", _LicensePlateContent."License Plate No.");
        if MobLicensePlateContent.FindFirst() then begin
            _InputTxt := MobLicensePlateContent."No." + ' -> ' + _InputTxt;
            GetLicensePlateStructureAsText(MobLicensePlateContent, _InputTxt);
        end else
            _InputTxt := _LicensePlateContent."License Plate No." + ' -> ' + _InputTxt;
    end;

    /// <summary>
    /// Used to ensure that a License Plate can be moved to another License Plate without creating a circular containment.
    /// Will provide detailed error message if a loop is detected.
    /// </summary>
    /// <param name="_LicensePlateNo">The License Plate to be moved</param>
    /// <param name="_ToLicensePlateNo">The destination of the License Plate</param>
    procedure CheckIsValidToLicensePlate(_LicensePlateNo: Code[20]; _ToLicensePlateNo: Code[20])
    var
        TestedLicensePlate: Dictionary of [Code[20], Boolean]; // A "global" variable for IsValidToLicensePlateRecursive() to avoid infinite loops. (Boolean value is not used)
        TestedLicensePlatePath: Text;
        i: Integer;
    begin
        if ValidToMoveLicensePlateIntoLicensePlate(_LicensePlateNo, _ToLicensePlateNo, TestedLicensePlate) then
            exit;

        // Build the path of License Plates that are part of the loop for the error message (FromLp.No -> ToLp.No -> ParentToLp.No -> ParentToParentToLp.No ... FromLp.No)
        // The error message is not entirely correct if the LPs are already in a loop, but that should not be possible
        for i := 1 to TestedLicensePlate.Count() do
            TestedLicensePlatePath += TestedLicensePlate.Keys().Get(i) + ' -> ';
        TestedLicensePlatePath := _LicensePlateNo + ' -> ' + TestedLicensePlatePath + _LicensePlateNo;

        Error(LicensePlateMoveErr, _LicensePlateNo, _ToLicensePlateNo, TestedLicensePlatePath);
    end;

    /// <summary>
    /// Used to determine if a License Plate can be moved to another License Plate without creating a circular containment
    /// </summary>
    /// <param name="_LicensePlateNo">The License Plate to be moved</param>
    /// <param name="_ToLicensePlateNo">The destination of the License Plate</param>
    /// <returns>Specifies if the movement can be completed without making a loop</returns>
    procedure IsValidToLicensePlate(_LicensePlateNo: Code[20]; _ToLicensePlateNo: Code[20]): Boolean
    var
        TestedLicensePlate: Dictionary of [Code[20], Boolean]; // A "global" variable for IsValidToLicensePlateRecursive() to avoid infinite loops. (Boolean value is not used)
    begin
        exit(ValidToMoveLicensePlateIntoLicensePlate(_LicensePlateNo, _ToLicensePlateNo, TestedLicensePlate));
    end;

    /// <summary>
    /// Checks if a License Plate can be moved into another License Plate without creating a circular containment
    /// </summary>
    /// <param name="_LicensePlateNo">The License Plate to be moved</param>
    /// <param name="_ToLicensePlateNo">The destination of the License Plate that it should be insured the License Plate isn't in</param>
    /// <param name="_TestedLicensePlates">A dictionary of checked License Plates to prevent License Plates in a loops</param>
    /// <returns>If the destination LP isn't contained in the LP, then it is Ok to move the LP into the destination LP.</returns>
    local procedure ValidToMoveLicensePlateIntoLicensePlate(_LicensePlateNo: Code[20]; _ToLicensePlateNo: Code[20]; var _TestedLicensePlates: Dictionary of [Code[20], Boolean]): Boolean
    var
        MobLicensePlateContent: Record "MOB License Plate Content";
    begin
        if (_LicensePlateNo = '') or (_ToLicensePlateNo = '') then
            exit(false);

        // Test if the LP is already tested. Then it is part of an loop of LPs and should not be used until the loop of LPs is broken
        if _TestedLicensePlates.ContainsKey(_ToLicensePlateNo) then
            exit(false);
        _TestedLicensePlates.Add(_ToLicensePlateNo, true);

        MobLicensePlateContent.SetCurrentKey(Type, "No.");
        MobLicensePlateContent.SetRange(Type, MobLicensePlateContent.Type::"License Plate");
        MobLicensePlateContent.SetRange("No.", _ToLicensePlateNo);
        if not MobLicensePlateContent.FindFirst() then
            exit(true);

        if MobLicensePlateContent."License Plate No." = _LicensePlateNo then
            exit(false);

        exit(ValidToMoveLicensePlateIntoLicensePlate(_LicensePlateNo, MobLicensePlateContent."License Plate No.", _TestedLicensePlates));
    end;

    // 'AddLicensePlate', 'AllContentToNewLicensePlate', 'AllToNewLicensePlate'
    internal procedure Create_TextStep_NewLicensePlateNo(_Id: Integer; var _Steps: Record "MOB Steps Element")
    var
        MobWmsLanguage: Codeunit "MOB WMS Language";
    begin
        _Steps.Create_TextStep(_Id, 'NewLicensePlateNo', false);
        _Steps.Set_header(MobWmsLanguage.GetMessage('ADD_LICENSEPLATE'));
        _Steps.Set_helpLabel(MobWmsLanguage.GetMessage('ADD_LICENSEPLATE_HELP'));
        _Steps.Set_eanAi(MobToolbox.GetLicensePlateNoGS1Ai());
        _Steps.Save();
    end;

    //Comment for License Plates
    internal procedure Create_TextStep_LicensePlateComment(_Id: Integer; var _Steps: Record "MOB Steps Element")
    var
        MobWmsLanguage: Codeunit "MOB WMS Language";
    begin
        _Steps.Create_TextStep(_Id, 'Comment', false);
        _Steps.Set_header(MobWmsLanguage.GetMessage('LICENSEPLATE_COMMENT'));
        _Steps.Set_helpLabel(MobWmsLanguage.GetMessage('LICENSEPLATECOMMENT_HELP'));
        _Steps.Set_length(50);
        _Steps.Set_primaryInputMethod('Control');
        _Steps.Set_optional(true);
        _Steps.Save();
    end;

    //
    // Warehouse Picks for Sales Orders: Copy picked goods to License Plate Content
    //
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Activity-Register", 'OnAfterFindWhseActivLine', '', true, true)]
    local procedure UpdateLicensePlateFromRegistration_OnAfterFindWhseActivLine(var WarehouseActivityLine: Record "Warehouse Activity Line")
    var
        MobWmsRegistration: Record "MOB WMS Registration";
        MobWmsRegistration2: Record "MOB WMS Registration";
        MobSessionData: Codeunit "MOB SessionData";
        MobPackFeatureMgt: Codeunit "MOB Pack Feature Management";
        IsHandled: Boolean;
    begin
        if (WarehouseActivityLine."Activity Type" <> WarehouseActivityLine."Activity Type"::Pick) or
           (WarehouseActivityLine."Action Type" <> WarehouseActivityLine."Action Type"::Take)
        then
            exit;

        if not (WarehouseActivityLine."Whse. Document Type" in [WarehouseActivityLine."Whse. Document Type"::Shipment, WarehouseActivityLine."Whse. Document Type"::Production]) then
            exit;

        if IsNullGuid(MobSessionData.GetPostingMessageId()) then    // Not posting from Mobile WMS
            exit;

        // This check is intentionally performed after it has been determined that the posting originate from Mobile WMS (see above) to prevent errors due to lacking Mobile WMS Permissions
        if not (MobPackFeatureMgt.IsEnabled() or MobSetup.LicensePlatingIsEnabled()) then
            exit;

        OnBeforeUpdateLicensePlateFromRegistration_FromWarehouseActivityLine(WarehouseActivityLine, IsHandled);
        if IsHandled then
            exit;

        MobWmsRegistration.Reset();
        MobWmsRegistration.SetCurrentKey("Posting MessageId");
        MobWmsRegistration.SetRange("Posting MessageId", MobSessionData.GetPostingMessageId());
        MobWmsRegistration.SetRange(Type, MobWmsRegistration.Type::Pick);
        MobWmsRegistration.SetRange("Order No.", WarehouseActivityLine."No.");
        MobWmsRegistration.SetRange("Source MOBSystemId", WarehouseActivityLine.MOBSystemId);
        MobWmsRegistration.SetRange(ActionType, 'TAKE');
        MobWmsRegistration.SetRange("Transferred to License Plate", false);
        MobWmsRegistration.SetRange("Transferred From License Plate", false);
        if MobWmsRegistration.FindSet() then
            repeat
                MobWmsRegistration2 := MobWmsRegistration;
                UpdateLicensePlateFromRegistration(MobWmsRegistration2, WarehouseActivityLine);

                if MobWmsRegistration2."License Plate No." <> '' then
                    MobWmsRegistration2.TestField("Transferred to License Plate", true);

                if MobWmsRegistration2."From License Plate No." <> '' then
                    MobWmsRegistration2.TestField("Transferred From License Plate", true);
            until MobWmsRegistration.Next() = 0;
    end;

    //
    // Warehouse Receive: Copy received goods to License Plate Content
    //
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Post Receipt", 'OnBeforePostSourceDocument', '', true, true)]
    local procedure UpdateLicensePlateFromWhseRcptLine(var WhseRcptLine: Record "Warehouse Receipt Line")
    var
        MobWmsRegistration: Record "MOB WMS Registration";
        MobWmsRegistration2: Record "MOB WMS Registration";
        MobSessionData: Codeunit "MOB SessionData";
    begin
        if IsNullGuid(MobSessionData.GetPostingMessageId()) then    // Not posting from Mobile WMS
            exit;

        if WhseRcptLine.FindSet() then
            repeat
                MobWmsRegistration.Reset();
                MobWmsRegistration.SetCurrentKey("Posting MessageId");
                MobWmsRegistration.SetRange("Posting MessageId", MobSessionData.GetPostingMessageId());
                MobWmsRegistration.SetRange(Type, MobWmsRegistration.Type::Receive);
                MobWmsRegistration.SetRange("Order No.", WhseRcptLine."No.");
                MobWmsRegistration.SetRange("Line No.", WhseRcptLine."Line No.");
                MobWmsRegistration.SetFilter("License Plate No.", '<>%1', '');
                MobWmsRegistration.SetRange("Transferred to License Plate", false);
                if MobWmsRegistration.FindSet() then begin

                    // Ensure License Plating is enabled before creating or updating the license plates
                    MobSetup.CheckLicensePlatingIsEnabled();

                    repeat
                        MobWmsRegistration2 := MobWmsRegistration;
                        UpdateLicensePlateFromRegistration(MobWmsRegistration2);
                        MobWmsRegistration2.TestField("Transferred to License Plate", true);
                    until MobWmsRegistration.Next() = 0;
                end;
            until WhseRcptLine.Next() = 0;
    end;

    local procedure UpdateLicensePlateFromRegistration(var _Registration: Record "MOB WMS Registration"; _WarehouseActivityLine: Record "Warehouse Activity Line")
    var
        ToLicensePlate: Record "MOB License Plate";
        FromLicensePlate: Record "MOB License Plate";
        PackingStationMgt: Codeunit "MOB Packing Station Management";
        MobSessionData: Codeunit "MOB SessionData";
    begin
        // Handle From-License Plate
        if _Registration."From License Plate No." <> '' then begin
            FromLicensePlate.Get(_Registration."From License Plate No.");
            RemoveRegistrationFromLicensePlate(_Registration, FromLicensePlate);
        end;

        // Handle To-License Plate
        if _Registration."License Plate No." <> '' then begin

            // Update or Create License Plate, this function will always return a License Plate Record
            CreateOrUpdateLicensePlate(_Registration, ToLicensePlate);

            if ToLicensePlate."ModifiedBy MessageId" <> MobSessionData.GetPostingMessageId() then begin
                // Current LicensePlate header values are from an older Posting MessageId
                PackingStationMgt.AddStagingOrderValuesToLicensePlate(_Registration."Posting MessageId", ToLicensePlate);
                ToLicensePlate.Modify(true);  // Set ModifiedBy MessageId
            end;

            // Update Warehouse Document
            PackingStationMgt.AddStagingOrderValuesToWhseDoc(_Registration."Posting MessageId", _WarehouseActivityLine);

            // Add Registration as License Plate Content
            AddRegistrationToLicensePlate(_Registration, ToLicensePlate);
        end;

    end;

    local procedure UpdateLicensePlateFromRegistration(var _Registration: Record "MOB WMS Registration")
    var
        MobLicensePlate: Record "MOB License Plate";
    begin
        if _Registration."License Plate No." = '' then
            exit;

        // Update or Create License Plate, this function will always return a License Plate Record
        CreateOrUpdateLicensePlate(_Registration, MobLicensePlate);

        // Add Registration as License Plate Content
        AddRegistrationToLicensePlate(_Registration, MobLicensePlate);
    end;


    /// <summary>
    /// Creates or Updates an existing License Plate based on the Registration
    /// </summary>

    local procedure CreateOrUpdateLicensePlate(_Registration: Record "MOB WMS Registration"; var _LicensePlate: Record "MOB License Plate")
    var
        PackingStationMgt: Codeunit "MOB Packing Station Management";
        MobFeatureTelemetryWrapper: Codeunit "MOB Feature Telemetry Wrapper";
        MobWmsLicensePlateReceive: Codeunit "MOB WMS License Plate Receive";
        MobTelemetryEventId: Enum "MOB Telemetry Event ID";
        LocationCode: Code[10];
        BinCode: Code[20];
        IsHandled: Boolean;
    begin
        _Registration.TestField("License Plate No.");

        if _Registration."Whse. Document Type" = _Registration."Whse. Document Type"::Receipt then
            MobWmsLicensePlateReceive.CheckToLicensePlateHandling(_Registration."Location Code");

        if not _LicensePlate.Get(_Registration."License Plate No.") then begin
            _LicensePlate.Init();
            _LicensePlate.Validate("No.", _Registration."License Plate No.");
            _LicensePlate.Insert(true);

            // Logging uptake telemetry for used LP feature
            if _Registration."Whse. Document Type" = _Registration."Whse. Document Type"::Receipt then begin
                MobFeatureTelemetryWrapper.LogUptakeUsed(MobTelemetryEventId::"License Plating - Create LP during Receive (MOB1060)");
                MobFeatureTelemetryWrapper.LogUptakeUsed(MobTelemetryEventId::"License Plating (MOB1050)");
            end;
        end;

        if _LicensePlate."Whse. Document No." = '' then begin
            // LP is new or "Cleared (action)"        

            //Ensure the License Plate does not have content            
            _LicensePlate.CalcFields("Content Exists");
            _LicensePlate.TestField("Content Exists", false);

            _LicensePlate.Validate("Whse. Document Type", _Registration."Whse. Document Type");
            _LicensePlate.Validate("Whse. Document No.", _Registration."Whse. Document No.");
            _LicensePlate.InitReceiptStatus();
            PackingStationMgt.AddStagingOrderValuesToLicensePlate(_Registration."Posting MessageId", _LicensePlate);

            _Registration.GetLocationAndBinFromRelatedWhseDocLine(LocationCode, BinCode);
            _LicensePlate.Validate("Bin Code", ''); // Clear Bin Code before Location to avoid validation error
            _LicensePlate.Validate("Location Code", LocationCode);
            _LicensePlate.Validate("Bin Code", BinCode);

            _LicensePlate.Modify(true);
        end else begin
            // LP is re-used and not "Cleared (action)"
            IsHandled := false;
            OnCreateOrUpdateLicensePlate_OnBeforeCheckExistingLicensePlate(_Registration, _LicensePlate, IsHandled);

            if not IsHandled then begin
                // Test for same Whse. Document
                _LicensePlate.TestField("Whse. Document Type", _Registration."Whse. Document Type");
                _LicensePlate.TestField("Whse. Document No.", _Registration."Whse. Document No.");

                // Test for same Location and Bin Code
                _Registration.GetLocationAndBinFromRelatedWhseDocLine(LocationCode, BinCode);
                _LicensePlate.TestField("Location Code", LocationCode);
                _LicensePlate.TestField("Bin Code", BinCode);
            end;
        end;
    end;

    /// <summary>
    /// Add Content to License Plate, based on Mobile Registration.
    /// </summary>
    internal procedure AddRegistrationToLicensePlate(var _Registration: Record "MOB WMS Registration"; _LicensePlate: Record "MOB License Plate")
    var
        MobTrackingSetup: Record "MOB Tracking Setup";
        MobLicensePlateContent: Record "MOB License Plate Content";
        MobLicensePlateMgt: Codeunit "MOB License Plate Mgt";
    begin
        _Registration.TestField("License Plate No.");
        _Registration.TestField("Item No.");
        _LicensePlate.TestField("No.");

        _LicensePlate.TestField("Whse. Document Type", _Registration."Whse. Document Type");
        _LicensePlate.TestField("Whse. Document No.", _Registration."Whse. Document No.");

        // You can only Add Content to a Top-level LP
        _LicensePlate.TestField("Transferred to Shipping", false);

        _LicensePlate.CalcFields("Top-level");
        _LicensePlate.TestField("Top-level", true);

        MobLicensePlateContent.Init();
        MobLicensePlateContent."Line No." := MobLicensePlateMgt.GetNextLicensePlateContentLineNo(_LicensePlate);
        MobLicensePlateContent.SetValuesFromLicensePlate(_LicensePlate."No.");

        // Data from Registration                
        MobLicensePlateContent.Validate(Type, MobLicensePlateContent.Type::Item);
        MobLicensePlateContent.Validate("No.", _Registration."Item No.");
        MobLicensePlateContent.Validate("Variant Code", _Registration."Variant Code");
        MobLicensePlateContent.Validate(Quantity, _Registration.Quantity);
        MobLicensePlateContent.Validate("Unit Of Measure Code", _Registration.UnitOfMeasure);

        Clear(MobTrackingSetup);
        MobTrackingSetup.CopyTrackingFromRegistration(_Registration);
        MobLicensePlateContent.SetTracking(MobTrackingSetup);

        MobLicensePlateContent.Validate("Whse. Document Line No.", _Registration."Whse. Document Line No."); // Whse. Doc Type and No. are already populated in SetValuesFromLicensePlate()
        MobLicensePlateContent.Validate("Source Type", _Registration."Source Type");
        MobLicensePlateContent.Validate("Source No.", _Registration."Source No.");
        MobLicensePlateContent.Validate("Source Line No.", _Registration."Source Line No.");
        MobLicensePlateContent.Validate("Source Document", _Registration."Source Document");

        OnBeforeInsertLPContent_OnAddRegistrationToLicensePlate(_Registration, MobLicensePlateContent);

        MobLicensePlateContent.Insert();
        _Registration."Transferred to License Plate" := true;
        _Registration.Modify();
    end;

    /// <summary>
    /// Removes the quantity from a Registration from the specified License Plate.
    /// </summary>    
    internal procedure RemoveRegistrationFromLicensePlate(var _Registration: Record "MOB WMS Registration"; _LicensePlate: Record "MOB License Plate")
    begin
        _Registration.TestField("From License Plate No.");
        _Registration.TestField("Item No.");
        _LicensePlate.TestField("No.");
        _LicensePlate.TestField("Transferred to Shipping", false);

        _LicensePlate.RemoveLicensePlateContent(
            _Registration.Quantity,
            _Registration."Item No.",
            _Registration."Variant Code",
            _Registration.UnitOfMeasure,
            _Registration.SerialNumber,
            _Registration.LotNumber,
            _Registration.PackageNumber);

        _Registration."Transferred From License Plate" := true;
        _Registration.Modify();
    end;

    // This eventsubscriber is used to update License Plate Content after a Warehouse Receipt has been posted
    // Intentionally is always executed after the Warehouse Receipt has been posted (no specific setup required)
    /* #if BC16+ */
    // The event is introduced in BC15.X (X>0), so License Plating is not available in BC15 and earlier - see "MOB Setup"."Enable License Plating".OnValidate()
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Post Receipt", 'OnCodeOnAfterPostSourceDocuments', '', true, true)]
    local procedure UpdateLicensePlates_OnCodeOnAfterPostSourceDocuments(var WarehouseReceiptHeader: Record "Warehouse Receipt Header")
    begin
        UpdateLicensePlates_OnAfterPostSourceDocs(WarehouseReceiptHeader);
    end;
    /* #endif */

    /// <summary>
    /// Updates the license plates after posting a warehouse receipt to make sure the license plate reference the posted document.
    /// </summary>    
    local procedure UpdateLicensePlates_OnAfterPostSourceDocs(_WarehouseReceiptHeader: Record "Warehouse Receipt Header")
    var
        MobLicensePlate: Record "MOB License Plate";
        MobLicensePlateToUpdate: Record "MOB License Plate";
        Location: Record Location;
        RequirePutaway: Boolean;
    begin
        RequirePutaway := Location.RequirePutaway(_WarehouseReceiptHeader."Location Code");

        MobLicensePlate.SetCurrentKey("Whse. Document Type", "Whse. Document No.");
        MobLicensePlate.SetRange("Whse. Document Type", MobLicensePlate."Whse. Document Type"::Receipt);
        MobLicensePlate.SetRange("Whse. Document No.", _WarehouseReceiptHeader."No.");
        MobLicensePlate.SetRange("Receipt Status", MobLicensePlate."Receipt Status"::Ready); // Avoid updating already received license plates
        MobLicensePlate.SetRange("Top-level", true);
        if MobLicensePlate.FindSet() then
            repeat
                MobLicensePlateToUpdate.Get(MobLicensePlate."No.");

                if RequirePutaway then begin
                    MobLicensePlateToUpdate.Validate("Whse. Document No.", GetCurrentWarehouseReceiptReceivingNo(_WarehouseReceiptHeader)); // Will update current license plate content and all child license plates as well  
                    MobLicensePlateToUpdate.Validate("Receipt Status", MobLicensePlate."Receipt Status"::Received);
                end else begin
                    MobLicensePlateToUpdate.Validate("Whse. Document Type", MobLicensePlateToUpdate."Whse. Document Type"::" ");
                    MobLicensePlateToUpdate.Validate("Whse. Document No.", ''); // Clearing the WhseDocNo will clear the link to the source document on the LP content records
                    MobLicensePlateToUpdate.Validate("Receipt Status", MobLicensePlate."Receipt Status"::" ");
                end;

                MobLicensePlateToUpdate.Modify(true);
            until MobLicensePlate.Next() = 0;
    end;

    /// <summary>
    /// This function is used to be prepared if Microsoft decides to refresh the WhseReceiptHeader before firing the OnCodeOnAfterPostSourceDocuments event.
    /// Currently (as of BC26) the WhseReceiptHeader is not refreshed before the event is fired, which means the WhseReceiptHeader contains the values from before the PostSourceDocument event is fired.
    /// Currently the PostSourceDocument moves the "Receiving No." value to the "Last Receiving No." field and modifies the WhseReceiptHeader. 
    /// However, this updated record is not transfered back to the "Whse.-Post Receipt" codeunit.
    /// This function therefore returns the "Receiving No." value if it is not empty, otherwise it returns the "Last Receiving No." value.
    /// </summary>
    local procedure GetCurrentWarehouseReceiptReceivingNo(_WarehouseReceiptHeader: Record "Warehouse Receipt Header"): Code[20]
    begin
        if _WarehouseReceiptHeader."Receiving No." <> '' then
            exit(_WarehouseReceiptHeader."Receiving No.");

        exit(_WarehouseReceiptHeader."Last Receiving No.");
    end;

    internal procedure CreateMenuForLicensePlate()
    var
        MobWmsSetupDocTypes: Codeunit "MOB WMS Setup Doc. Types";
    begin
        MobWmsSetupDocTypes.CreateMobileMenuOption('LicensePlateContent');
        MobWmsSetupDocTypes.CreateMobileMenuOption('EditLicensePlate');
    end;

    /// <summary>
    /// /// True if License Plates related to this  Warehouse Receipt Header exists
    /// </summary>
    procedure RelatedLicensePlatesExists(_WhseReceiptHeader: Record "Warehouse Receipt Header"): Boolean
    var
        MobLicensePlate: Record "MOB License Plate";
    begin
        MobLicensePlate.SetCurrentKey("Whse. Document Type", "Whse. Document No.");
        MobLicensePlate.SetRange("Whse. Document Type", MobLicensePlate."Whse. Document Type"::Receipt);
        MobLicensePlate.SetRange("Whse. Document No.", _WhseReceiptHeader."No.");
        exit(not MobLicensePlate.IsEmpty());
    end;

    /// <summary>
    /// True if License Plates related to this Warehouse Activity Header exists
    /// </summary>
    procedure RelatedLicensePlatesExists(_WhseActivityHeader: Record "Warehouse Activity Header"): Boolean
    var
        WhseActivityLine: Record "Warehouse Activity Line";
        MobLicensePlate: Record "MOB License Plate";
    begin
        WhseActivityLine.Reset();
        WhseActivityLine.SetRange("Activity Type", _WhseActivityHeader."Type");
        WhseActivityLine.SetRange("No.", _WhseActivityHeader."No.");
        if WhseActivityLine.FindFirst() then begin
            MobLicensePlate.SetCurrentKey("Whse. Document Type", "Whse. Document No.");
            MobLicensePlate.SetRange("Whse. Document Type", WhseActivityLine."Whse. Document Type");
            MobLicensePlate.SetRange("Whse. Document No.", WhseActivityLine."Whse. Document No.");
            MobLicensePlate.SetRange("Receipt Status", MobLicensePlate."Receipt Status"::Received);
            exit(not MobLicensePlate.IsEmpty());
        end;

        exit(false);
    end;

    internal procedure EnableLicensePlating(var _MobSetup: Record "MOB Setup")
    var
        MobWmsSetupDocTypes: Codeunit "MOB WMS Setup Doc. Types";
        MobDeviceManagement: Codeunit "MOB Device Management";
        MobCommonMgt: Codeunit "MOB Common Mgt.";
        MobPrintInterForm: Codeunit "MOB Print InterForm";
        MobPrint: Codeunit "MOB Print";
        MobReportPrintManagement: Codeunit "MOB Report Print Management";
        MobPackFeatureManagement: Codeunit "MOB Pack Feature Management";
        MobFeatureTelemetryWrapper: Codeunit "MOB Feature Telemetry Wrapper";
        MobTelemetryEventId: Enum "MOB Telemetry Event ID";
        MobLabelTemplateHandlerEnum: Enum "MOB Label-Template Handler";
        RequestPageHandler: Enum "MOB RequestPage Handler";
    begin
        MobFeatureTelemetryWrapper.LogUptakeDiscovered(MobTelemetryEventId::"License Plating (MOB1050)");

        if MobCommonMgt.GenerateHashMD5(_MobSetup."License Plating Key") <> '93B88AED472DB82FF069EE28CEA8DB80' then begin // P. I. C.
            Message(LicensePlateKeyErr, _MobSetup.FieldCaption("License Plating Key"));
            _MobSetup."Enable License Plating" := false;
            exit;
        end;

        if not Confirm(EnableLicensePlatingMsg, false, CompanyName()) then begin
            _MobSetup."Enable License Plating" := false;
            exit;
        end;

        // Ensure the Pack & Ship extension isn't installed or has been migrated if it ever was detected
        if _MobSetup."Legacy Pack and Ship Detected" then
            Error(LegacyPackAndShipDetectedErr);
        MobPackFeatureManagement.ThrowErrorIfLegacyPackAndShipIsPublished();

        // Validate that at least one handheld device is updated to the required app version
        // 1.10.2 is required to make use of Pinned Values and other License Plate features including new LP Put-away icon
        MobDeviceManagement.CheckAnyDeviceExistWithMinimumAppVersion('1.10.2.0', true);

        // Add new LP menu options and add them to the WMS group
        MobWmsSetupDocTypes.CreateMobileMenuOptionAndAddToMobileGroup('PutAwayLicensePlate', 'WMS', 225); // Typical the end of the 1st row
        MobWmsSetupDocTypes.CreateMobileMenuOptionAndAddToMobileGroup('LicensePlate', 'WMS', 425); // Typical the end of the 2nd row

        // Replace 'UnplannedMove' with 'UnplannedMoveAdvanced' in the WMS group
        MobWmsSetupDocTypes.CreateMobileMenuOptionAndReplaceInMobileGroup('UnplannedMove', 'UnplannedMoveAdvanced', 'WMS', 800); // 800 is the default location of 'UnplannedMove'

        // Adjust Label Templates by enabling GS1 versions of License Plate and License Plate Contents
        MobLabelTemplateHandlerEnum := MobLabelTemplateHandlerEnum::"License Plate";
        MobPrint.ReplaceLabelTemplate(
            'License Plate 3x2', 'License Plate GS1 3x2', Format(MobLabelTemplateHandlerEnum) + ' GS1 3x2',
            MobPrintInterForm.Get_Template_LicensePlate_GS1_3x2_URL(), MobLabelTemplateHandlerEnum);

        MobLabelTemplateHandlerEnum := MobLabelTemplateHandlerEnum::"License Plate Contents";
        MobPrint.ReplaceLabelTemplate(
            'License Plate Contents 4x6', 'License Plate Contents GS1 4x6', Format(MobLabelTemplateHandlerEnum) + ' GS1 4x6',
            MobPrintInterForm.Get_Template_Generic_OrderList_GS1_4x6_URL(), MobLabelTemplateHandlerEnum);

        // Adjust Mobile Reports by enabling the standard GS1 versions of the layouts (Report Pack only exists in BC20+)
        /* #if BC20+ */
        RequestPageHandler := RequestPageHandler::"License Plate Label";
        MobReportPrintManagement.EnableReportLayoutAndDisableOthers(Report::"MOB License Plate Label", 'License Plate Label GS1 3x2', RequestPageHandler);

        RequestPageHandler := RequestPageHandler::"License Plate Contents Label";
        MobReportPrintManagement.EnableReportLayoutAndDisableOthers(Report::"MOB LP Contents Label", 'License Plate Contents GS1 4x6', RequestPageHandler);
        /* #endif */

        SetInitialLocationSetupForLicensePlating();

        // Ensure the Setup Rec is saved in the same transaction as the other updates to the DB
        _MobSetup.Modify(true);

        Message(LicensePlatingEnabledMsg);
        MobFeatureTelemetryWrapper.LogUptakeSetup(MobTelemetryEventId::"License Plating (MOB1050)");
    end;

    internal procedure DisableLicensePlating(var _MobSetup: Record "MOB Setup")
    var
        Location: Record Location;
        MobWmsSetupDocTypes: Codeunit "MOB WMS Setup Doc. Types";
        MobFeatureTelemetryWrapper: Codeunit "MOB Feature Telemetry Wrapper";
        MobTelemetryEventId: Enum "MOB Telemetry Event ID";
        RequiresUpdate: Boolean;
    begin
        if not Confirm(DisableLicensePlatingMsg, false, CompanyName()) then begin
            _MobSetup."Enable License Plating" := true;
            exit;
        end;

        // Remove LP menu options from the WMS group
        MobWmsSetupDocTypes.RemoveMobileMenuOptionFromMobileGroup('PutAwayLicensePlate', 'WMS');
        MobWmsSetupDocTypes.RemoveMobileMenuOptionFromMobileGroup('LicensePlate', 'WMS');

        // Replace 'UnplannedMoveAdvanced' with 'UnplannedMove' in the WMS group
        MobWmsSetupDocTypes.CreateMobileMenuOptionAndReplaceInMobileGroup('UnplannedMoveAdvanced', 'UnplannedMove', 'WMS', 800); // 800 is the default location of 'UnplannedMove'

        // Ensure the Setup Rec is saved in the same transaction as the other updates to the DB
        _MobSetup.Modify(true);

        // Reset all LP related settings to Disabled for all locations
        Location.SetRange("Use As In-Transit", false); // Only regular locations
        if Location.FindSet(true) then
            repeat
                RequiresUpdate := false;
                if Location."MOB Receive to LP" <> Location."MOB Receive to LP"::Disabled then begin
                    Location.Validate("MOB Receive to LP", Location."MOB Receive to LP"::Disabled);
                    RequiresUpdate := true;
                end;

                if Location."MOB Pick from LP" <> Location."MOB Pick from LP"::Disabled then begin
                    Location.Validate("MOB Pick from LP", Location."MOB Pick from LP"::Disabled);
                    RequiresUpdate := true;
                end;

                if Location."MOB Prod. Output to LP" <> Location."MOB Prod. Output to LP"::Disabled then begin
                    Location.Validate("MOB Prod. Output to LP", Location."MOB Prod. Output to LP"::Disabled);
                    RequiresUpdate := true;
                end;

                if RequiresUpdate then
                    Location.Modify(true);
            until Location.Next() = 0;

        Message(LicensePlatingDisabledMsg);
        MobFeatureTelemetryWrapper.LogUptakeUndiscovered(MobTelemetryEventId::"License Plating (MOB1050)");
    end;

    /// <summary>
    /// Applies initial License Plate setup to all locations
    /// </summary>
    internal procedure SetInitialLocationSetupForLicensePlating()
    var
        Location: Record Location;
    begin
        Location.SetRange("Use As In-Transit", false); // Only regular locations
        if Location.FindSet(true) then
            repeat
                if Location."Require Receive" then
                    Location.Validate("MOB Receive to LP", Location."MOB Receive to LP"::Optional);

                if Location."Require Pick" then
                    Location.Validate("MOB Pick from LP", Location."MOB Pick from LP"::Optional);

                // Production Output to LP is Optional by default
                Location.Validate("MOB Prod. Output to LP", Location."MOB Prod. Output to LP"::Optional);
                Location.Modify(true);
            until Location.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateOrUpdateLicensePlate_OnBeforeCheckExistingLicensePlate(_Registration: Record "MOB WMS Registration"; var _LicensePlate: Record "MOB License Plate"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateLicensePlateFromRegistration_FromWarehouseActivityLine(_WarehouseActivityLine: Record "Warehouse Activity Line"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before adding registration content to a license plate.
    /// </summary>
    /// <param name="_Registration">Mobile registration containing the item and tracking details to be added as content to license plate, before modification.</param>
    /// <param name="_LicensePlateContent">License plate content record being created, before insertion.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertLPContent_OnAddRegistrationToLicensePlate(var _Registration: Record "MOB WMS Registration"; var _LicensePlateContent: Record "MOB License Plate Content")
    begin
    end;

    //TODO Move to _Pack after migration
    [IntegrationEvent(false, false)]
    internal procedure OnCheckLicensePlatePackageInfo(_LicensePlate: Record "MOB License Plate"; _PackageSetup: Record "MOB Mobile WMS Package Setup"; var _IsPackageInfoCollected: Boolean)
    begin
    end;

    // TODO Desired Changes to Pack & Ship after migration is completed
    /*
    
    MIV: IntegrationEvent OnCheckLicensePlatePackageInfo is in reality 'Pack' functionality incl. the OnCheckLicensePlatePackageInfo event - should be moved to _Pack
    DVI: Yes, but we cannot currently move the event - Requires obsolete roundtrip, currently on-hold.
    
    */
}
