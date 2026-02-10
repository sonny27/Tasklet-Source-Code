codeunit 82236 "MOB Packing Station Management"
{
    Access = Public;

    /// <summary>
    /// Used when calling the Edit License Plate Action to update Packing Station, Staging Hint and Comment
    /// </summary>
    var
        MobPackFeatureMgt: Codeunit "MOB Pack Feature Management";
        MobWmsLanguage: Codeunit "MOB WMS Language";


    internal procedure GetRegistrationConfiguration_EditLicensePlate(_MobDocQueue: Record "MOB Document Queue"; _RegistrationType: Text; var _HeaderFilter: Record "MOB NS Request Element"; var _Steps: Record "MOB Steps Element"; var _RegistrationTypeTracking: Text)
    var
        MobSetup: Record "MOB Setup";

    begin
        if MobPackFeatureMgt.IsEnabled() or MobSetup.LicensePlatingIsEnabled() then
            _RegistrationTypeTracking := CreateEditLicensePlateSteps(_HeaderFilter, _Steps);
    end;

    internal procedure Create_TextStep_StagingHint(_Id: Integer; var _Steps: Record "MOB Steps Element")
    begin
        _Steps.Create_TextStep(_Id, 'StagingHint', false);
        _Steps.Set_header(MobWmsLanguage.GetMessage('STAGING_HINT'));
        _Steps.Set_label('');
        _Steps.Set_helpLabel(MobWmsLanguage.GetMessage('STAGING_HINT_HELP'));
        _Steps.Set_length(50);
        _Steps.Set_optional(true);
        _Steps.Save();
    end;

    internal procedure Create_ListStep_PackingStation(_Id: Integer; var _Steps: Record "MOB Steps Element")
    begin
        _Steps.Create_ListStep(_Id, 'PackingStation', false);
        _Steps.Set_header(MobWmsLanguage.GetMessage('PACKING_STATION'));
        _Steps.Set_helpLabel(MobWmsLanguage.GetMessage('STAGING_HINT_HELP'));
        _Steps.Set_optional(true);
        _Steps.Save();
    end;

    local procedure CreateEditLicensePlateSteps(var _HeaderFieldValues: Record "MOB NS Request Element"; var _Steps: Record "MOB Steps Element") RegistrationTypeTracking: Text
    var
        WhseShipHeader: Record "Warehouse Shipment Header";
        MobSetup: Record "MOB Setup";
        MobLicensePlate: Record "MOB License Plate";
        MobPackingStation: Record "MOB Packing Station";
        MobLicensePlateMgt: Codeunit "MOB License Plate Mgt";
        LocationFilterTxt: Text;
        PackingStationListAsTxt: Text;
    begin
        if not MobLicensePlate.Get(_HeaderFieldValues.GetValue('LicensePlate')) then
            Error(MobWmsLanguage.GetMessage('LP_NOT_FOUND_ERROR'), _HeaderFieldValues.GetValue('LicensePlate'));


        MobLicensePlateMgt.Create_TextStep_LicensePlateComment(300, _Steps);
        if MobLicensePlate.Comment <> '' then
            _Steps.Set_defaultValue(MobLicensePlate.Comment);

        MobSetup.Get();
        //Collecting of Packing Station and Staging Hint only from Shipment type (Pack & Ship)
        if MobLicensePlate."Whse. Document Type" = MobLicensePlate."Whse. Document Type"::Shipment then begin

            if MobSetup."Pick Collect Staging Hint" then begin
                Create_TextStep_StagingHint(100, _Steps);
                _Steps.Set_defaultValue(MobLicensePlate."Staging Hint");
            end;

            if MobSetup."Pick Collect Packing Station" then begin
                // Apply filter on Location Code based on WhseActHeader and Stations without Location specified.
                WhseShipHeader.Get(MobLicensePlate."Whse. Document No.");
                LocationFilterTxt := StrSubstNo('%1|%2', WhseShipHeader."Location Code", '''''');
                MobPackingStation.SetFilter("Location Code", LocationFilterTxt);

                if MobPackingStation.FindSet() then begin
                    repeat
                        PackingStationListAsTxt += MobPackingStation.Code + ';';
                    until MobPackingStation.Next() = 0;

                    PackingStationListAsTxt := DelStr(PackingStationListAsTxt, StrLen(PackingStationListAsTxt), 1);
                    Create_ListStep_PackingStation(200, _Steps);
                    _Steps.Set_listValues(PackingStationListAsTxt);
                end;

                // Set default Packing Station
                if MobLicensePlate."Packing Station Code" <> '' then
                    _Steps.Set_defaultValue(MobLicensePlate."Packing Station Code")
                else
                    if MobPackingStation.Count() = 1 then begin
                        MobPackingStation.FindFirst();
                        _Steps.Set_defaultValue(MobPackingStation.Code);
                    end;
            end;
        end;
        RegistrationTypeTracking := '';
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Adhoc Registr.", 'OnPostAdhocRegistrationOnCustomRegistrationType', '', true, true)]
    local procedure OnPostAdhocRegistrationOnCustomRegistrationType(_RegistrationType: Text; var _RequestValues: Record "MOB NS Request Element"; var _SuccessMessage: Text; var _IsHandled: Boolean)
    begin
        if _IsHandled then
            exit;

        // TODO: Remove this check when all customers have migrated from Pack and Ship PTE
        if MobPackFeatureMgt.LegacyPackAndShipDetected() then
            exit;

        if _RegistrationType = 'EditLicensePlate' then begin
            _SuccessMessage := EditLicensePlate(_RegistrationType, _RequestValues);
            _IsHandled := true;
        end;
    end;

    local procedure EditLicensePlate(_RegistrationType: Text; var _RequestValues: Record "MOB NS Request Element"): Text
    var
        MobLicensePlate: Record "MOB License Plate";
        PackingStationTxt: Text;
        StagingHintTxt: Text;
        CommentTxt: Text;
    begin
        if _RegistrationType <> 'EditLicensePlate' then
            exit;

        if not MobLicensePlate.Get(_RequestValues.GetValue('LicensePlate')) then
            exit;

        if _RequestValues.HasValue('PackingStation') then begin
            PackingStationTxt := _RequestValues.GetValue('PackingStation');
            if PackingStationTxt <> MobLicensePlate."Packing Station Code" then
                MobLicensePlate.Validate("Packing Station Code", PackingStationTxt);
        end;

        if _RequestValues.HasValue('StagingHint') then begin
            StagingHintTxt := _RequestValues.GetValue('StagingHint');
            if StagingHintTxt <> MobLicensePlate."Staging Hint" then
                MobLicensePlate.Validate("Staging Hint", StagingHintTxt);
        end;

        if _RequestValues.HasValue('Comment') then begin
            CommentTxt := _RequestValues.GetValue('Comment');
            if CommentTxt <> MobLicensePlate.Comment then
                MobLicensePlate.Validate(Comment, CommentTxt);
        end;
        MobLicensePlate.Modify(true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Pick", 'OnGetPickOrderLines_OnAddStepsToAnyHeader', '', true, true)]
    local procedure OnGetPickOrderLines_OnAddStepsToAnyHeader(_RecRef: RecordRef; var _StepsElement: Record "MOB Steps Element")
    begin
        // TODO: Remove this check when all customers have migrated from Pack and Ship PTE
        if MobPackFeatureMgt.LegacyPackAndShipDetected() then
            exit;

        GetStepsForPackAndShipOnPostPick(_RecRef, _StepsElement);
    end;

    internal procedure GetStepsForPackAndShipOnPostPick(_RecRef: RecordRef; var _StepsElement: Record "MOB Steps Element" temporary)
    var
        WhseActivityHeader: Record "Warehouse Activity Header";
        WhseActivityLine: Record "Warehouse Activity Line";
        WhseShipHeader: Record "Warehouse Shipment Header";
        MobSetup: Record "MOB Setup";
        PackingStation: Record "MOB Packing Station";
        LocationFilterTxt: Text;
        PackingStationListAsTxt: Text;
    begin
        if not MobPackFeatureMgt.IsEnabled() then
            exit;

        if _RecRef.Number() <> Database::"Warehouse Activity Header" then
            exit;

        _RecRef.SetTable(WhseActivityHeader);
        if WhseActivityHeader.Type <> WhseActivityHeader.Type::Pick then
            exit;

        WhseActivityLine.SetRange("Activity Type", WhseActivityHeader.Type);
        WhseActivityLine.SetRange("No.", WhseActivityHeader."No.");
        WhseActivityLine.SetFilter("Source Document", '%1|%2|%3|%4', WhseActivityLine."Source Document"::"Sales Order", WhseActivityLine."Source Document"::"Outbound Transfer", WhseActivityLine."Source Document"::"Purchase Return Order", WhseActivityLine."Source Document"::"Service Order");
        if WhseActivityLine.IsEmpty() then
            exit;

        MobSetup.Get();
        if not (MobSetup."Pick Collect Staging Hint" or MobSetup."Pick Collect Packing Station") then
            exit;

        // Add Step for collection Packing Station if required
        if MobSetup."Pick Collect Packing Station" then begin
            // Apply filter on Location Code based on WhseActHeader and Stations without Location specified.
            LocationFilterTxt := StrSubstNo('%1|%2', WhseActivityHeader."Location Code", '''''');
            PackingStation.SetFilter("Location Code", LocationFilterTxt);

            if PackingStation.FindSet() then begin
                repeat
                    PackingStationListAsTxt += PackingStation.Code + ';';
                until PackingStation.Next() = 0;

                PackingStationListAsTxt := DelStr(PackingStationListAsTxt, StrLen(PackingStationListAsTxt), 1);

                Create_ListStep_PackingStation(100, _StepsElement);
                _StepsElement.Set_listValues(PackingStationListAsTxt);
            end;

            // Set default if only one Packing Station exists,if more, set default if packing station was already set for the same whse. shipment.
            if PackingStation.Count() = 1 then begin
                PackingStation.FindFirst();
                _StepsElement.Set_defaultValue(PackingStation.Code);
            end else begin
                WhseActivityLine.SetRange("Activity Type", WhseActivityHeader.Type::Pick);
                WhseActivityLine.SetRange("No.", WhseActivityHeader."No.");
                if WhseActivityLine.FindFirst() then
                    if (WhseShipHeader.Get(WhseActivityLine."Whse. Document No.")) and
                         (WhseShipHeader."MOB Packing Station Code" <> '') then
                        _StepsElement.Set_defaultValue(WhseShipHeader."MOB Packing Station Code");
            end;
        end;

        // Add Step for collection Staging Hint if required
        if MobSetup."Pick Collect Staging Hint" then begin
            Create_TextStep_StagingHint(200, _StepsElement);
            _StepsElement.Set_defaultValue('');
        end;
    end;

    internal procedure AddStagingOrderValuesToLicensePlate(_PostingMessageId: Guid; var _LicensePlate: Record "MOB License Plate")
    var
        TempOrderValues: Record "MOB Common Element" temporary;
    begin
        GetOrderValuesByMessageId(_PostingMessageId, TempOrderValues);
        Evaluate(_LicensePlate."Staging Hint", TempOrderValues.GetValue('StagingHint', false));
        Evaluate(_LicensePlate."Packing Station Code", TempOrderValues.GetValue('PackingStation', false));
    end;

    internal procedure AddStagingOrderValuesToWhseDoc(_PostingMessageId: Guid; var _WarehouseActivityLine: Record "Warehouse Activity Line")
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        TempOrderValues: Record "MOB Common Element" temporary;
        PackingStationTxt: Text;
    begin
        GetOrderValuesByMessageId(_PostingMessageId, TempOrderValues);
        Evaluate(PackingStationTxt, TempOrderValues.GetValue('PackingStation', false));

        if PackingStationTxt = '' then
            exit;

        if _WarehouseActivityLine."Whse. Document Type" <> _WarehouseActivityLine."Whse. Document Type"::Shipment then
            exit;

        if not WarehouseShipmentHeader.Get(_WarehouseActivityLine."Whse. Document No.") then
            exit;

        if WarehouseShipmentHeader."MOB Packing Station Code" = '' then begin
            WarehouseShipmentHeader.Validate("MOB Packing Station Code", PackingStationTxt);
            WarehouseShipmentHeader.Modify();
        end;
    end;

    internal procedure GetOrderValuesByMessageId(_MessageId: Guid; var _TempOrderValues: Record "MOB Common Element")
    var
        MobDocQueue: Record "MOB Document Queue";
        MobRequestMgt: Codeunit "MOB NS Request Management";
        XmlRequestDoc: XmlDocument;
    begin
        MobDocQueue.GetByGuid(_MessageId, MobDocQueue);
        MobDocQueue.LoadXMLRequestDoc(XmlRequestDoc);
        MobRequestMgt.InitCommonFromXmlOrderNode(XmlRequestDoc, _TempOrderValues);
    end;
}
