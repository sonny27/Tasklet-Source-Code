table 82217 "MOB License Plate"
{
    Access = Public;
    Caption = 'Mobile License Plate';
    DataClassification = CustomerContent;
    DrillDownPageId = "MOB License Plate List";
    LookupPageId = "MOB License Plate List";
    fields
    {
        field(2; "No."; Code[20])
        {
            Caption = 'No.';
            DataClassification = CustomerContent;
            NotBlank = true;
        }
        field(19; "Bin Code"; Code[20])
        {
            Caption = 'Bin Code';
            DataClassification = CustomerContent;
            TableRelation = Bin.Code where("Location Code" = field("Location Code"));
            Editable = false;

            trigger OnValidate()
            begin
                LicensePlateMgt.SynchronizeChildLicensePlatesFields(Rec, xRec);
            end;
        }
        field(20; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            DataClassification = CustomerContent;
            TableRelation = Location;
            Editable = false;

            trigger OnValidate()
            begin
                LicensePlateMgt.SynchronizeChildLicensePlatesFields(Rec, xRec);
            end;
        }
        field(21; "Whse. Document Type"; Option)
        {
            Caption = 'Whse. Document Type';
            DataClassification = CustomerContent;
            Editable = false;
            OptionCaption = ' ,Receipt,Shipment,Internal Put-away,Internal Pick,Production,Movement Worksheet,,Assembly';
            OptionMembers = " ",Receipt,Shipment,"Internal Put-away","Internal Pick",Production,"Movement Worksheet",,Assembly;

            trigger OnValidate()
            begin
                LicensePlateMgt.SynchronizeChildLicensePlatesFields(Rec, xRec);
            end;
        }
        field(22; "Whse. Document No."; Code[20])
        {
            Caption = 'Whse. Document No.';
            DataClassification = CustomerContent;
            Editable = false;

            trigger OnValidate()
            begin
                LicensePlateMgt.SynchronizeChildLicensePlatesFields(Rec, xRec);
            end;
        }
#pragma warning disable LC0076 // The related field "MOB Package Type".Code is Code[100] but the Package Type length is never expected to be over 50
        field(28; "Package Type"; Code[50])
#pragma warning restore LC0076
        {
            Caption = 'Package Type';
            DataClassification = CustomerContent;
            TableRelation = "MOB Package Type".Code;

            trigger OnValidate()
            var
                PackageType: Record "MOB Package Type";
                PackManagement: Codeunit "MOB Pack Management";
            begin
                if PackageType.Get("Package Type") then
                    PackManagement.UpdateDefaultPackageDimensionsOnLicensePlate(PackageType, Rec)
                else
                    PackManagement.ResetDefaultPackageDimensionsOnLicensePlate(Rec);
            end;
        }
        field(29; Weight; Decimal)
        {
            Caption = 'Gross Weight';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }

        field(30; Width; Decimal)
        {
            Caption = 'Width';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(31; Length; Decimal)
        {
            Caption = 'Length';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(32; Height; Decimal)
        {
            Caption = 'Height';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(33; "Loading Meter"; Decimal)
        {
            Caption = 'Loading Meter (LDM)';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(50; "Transferred to Shipping"; Boolean)
        {
            Caption = 'Transferred to Shipping Provider';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                LicensePlateMgt.SynchronizeChildLicensePlatesFields(Rec, xRec);
            end;
        }
        field(51; "Shipping Status"; Enum "MOB Shipping Status")
        {
            Caption = 'Shipping Status';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                LicensePlateMgt.SynchronizeChildLicensePlatesFields(Rec, xRec);
            end;
        }

        field(55; "Receipt Status"; Enum "MOB Receipt Status")
        {
            Caption = 'Receipt Status';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                LicensePlateMgt.SynchronizeChildLicensePlatesFields(Rec, xRec);
            end;
        }

        field(60; "Top-level"; Boolean)
        {
            Caption = 'Top-level';
            CalcFormula = - exist("MOB License Plate Content" where(Type = const("License Plate"), "No." = field("No.")));
            Editable = false;
            FieldClass = FlowField;
        }
        field(61; "Content Exists"; Boolean)
        {
            Caption = 'Content Exists';
            CalcFormula = exist("MOB License Plate Content" where("License Plate No." = field("No.")));

            Editable = false;
            FieldClass = FlowField;
        }
        field(62; "Sub License Plate Qty."; Integer)
        {
            Caption = 'Sub License Plate Quantity';
            CalcFormula = count("MOB License Plate Content" where("License Plate No." = field("No."), Type = const("License Plate")));

            Editable = false;
            FieldClass = FlowField;
        }

#pragma warning disable AA0232
        field(63; "Content Quantity (Base)"; Decimal)
#pragma warning restore AA0232    
        {
            Caption = 'Content Quantity (Base)';
            CalcFormula = sum("MOB License Plate Content"."Quantity (Base)" where("License Plate No." = field("No."), Type = const(Item)));

            Editable = false;
            DecimalPlaces = 0 : 2;
            FieldClass = FlowField;
        }

        field(70; "Staging Hint"; Text[50])
        {
            Caption = 'Staging Hint';
            DataClassification = CustomerContent;
        }
        field(71; "Packing Station Code"; Code[20])
        {
            Caption = 'Packing Station Code';
            DataClassification = CustomerContent;
            TableRelation = "MOB Packing Station";
        }
        field(80; Comment; Text[50])
        {
            Caption = 'Comment';
            DataClassification = CustomerContent;
        }
        field(90; "CreatedBy MessageId"; Guid)
        {
            Caption = 'CreatedBy MessageId', Locked = true;
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(91; "ModifiedBy MessageId"; Guid)
        {
            Caption = 'ModifiedBy MessageId', Locked = true;
            DataClassification = CustomerContent;
            Editable = false;
        }

    }
    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Whse. Document Type", "Whse. Document No.")
        {
        }
    }

    var
        LicensePlateMgt: Codeunit "MOB License Plate Mgt";
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
        LicensePlateQtyUpdateErr: Label 'You tried to remove %2 %4.\\License Plate %1 only has %3 %4.', Comment = '%1 is a License Plate No., %2 is the Requested Quantity to remove (original), %3 is the Quantity available after removing some, %4 is the Unit of Measure';

    trigger OnInsert()
    var
        MobSessionData: Codeunit "MOB SessionData";
        PackMgt: Codeunit "MOB Pack Management";
    begin
        Rec."CreatedBy MessageId" := MobSessionData.GetPostingMessageId();
        Clear("ModifiedBy MessageId");  // Must be empty to separate new records which still has not had OrderValues transferred to the record

        // Set Initial value for Field "Shipping Status"
        PackMgt.CheckLicensePlatePackageInfo(Rec);
    end;

    trigger OnModify()
    var
        MobSessionData: Codeunit "MOB SessionData";
        PackMgt: Codeunit "MOB Pack Management";
    begin
        Rec."ModifiedBy MessageId" := MobSessionData.GetPostingMessageId();

        // Update Field "Ready for Shipping"
        PackMgt.CheckLicensePlatePackageInfo(Rec);
    end;

    trigger OnDelete()
    var
        LicensePlateContent: Record "MOB License Plate Content";
    begin
        LicensePlateContent.SetRange("License Plate No.", Rec."No.");
        LicensePlateContent.DeleteAll();
    end;

    procedure ResetLicensePlate()
    var
        LicensePlateContent: Record "MOB License Plate Content";
    begin
        // Only allowed to delete top-level License Plates
        Rec.CalcFields("Top-level");
        Rec.TestField("Top-level", true);

        LicensePlateContent.SetRange("License Plate No.", Rec."No.");
        LicensePlateContent.DeleteAll();

        Rec.Get(Rec."No.");
        Rec.Init();
        Rec.Modify();
    end;

    /// <summary>
    /// Get "License Plate Content"-record, if exists
    /// This record holds any Parent LP-relation
    /// </summary>
    internal procedure GetAsContentOnParentLicensePlate(var _LicensePlateContent: Record "MOB License Plate Content"): Boolean
    begin
        _LicensePlateContent.SetRange("No.", Rec."No.");
        _LicensePlateContent.SetRange(Type, _LicensePlateContent.Type::"License Plate");
        exit(_LicensePlateContent.FindFirst());
    end;

    /// <summary>
    /// Delete LP
    /// All contents and children LP's are moved to the parent, if exist
    /// </summary>
    internal procedure DeleteLicensePlate()
    var
        MobLicensePlateContent: Record "MOB License Plate Content";
    begin
        if GetAsContentOnParentLicensePlate(MobLicensePlateContent) then begin // Find current LP as content on Parent
            MoveContentsTo(MobLicensePlateContent."License Plate No."); // Move contents to parent
            MobLicensePlateContent.Delete(); // Delete the old relation to parent
        end;

        Delete(true);
    end;

    /// <summary>
    /// Move this LP's item contents to another LP
    /// All contents and children LP's are moved
    /// </summary>
    internal procedure MoveContentsTo(_ToLicensePlateNo: Code[20])
    var
        ToMobLicensePlate: Record "MOB License Plate";
        MobLicensePlateContent: Record "MOB License Plate Content";
    begin
        ToMobLicensePlate.Get(_ToLicensePlateNo);

        MobLicensePlateContent.SetRange("License Plate No.", Rec."No.");
        if MobLicensePlateContent.FindSet(true) then
            repeat
                ToMobLicensePlate.AddContent(MobLicensePlateContent);
                MobLicensePlateContent.Delete();
            until MobLicensePlateContent.Next() = 0;
    end;

    /// <summary>
    /// Add content this LP
    /// If the same content already exists, the Quantity is updated otherwise new content is created
    /// </summary>
    internal procedure AddContent(_MobLicensePlateContent: Record "MOB License Plate Content")
    var
        AddLPContent: Record "MOB License Plate Content";
        MobTrackingSetup: Record "MOB Tracking Setup";
    begin
        // Search for matching content to update
        AddLPContent.SetRange("License Plate No.", Rec."No.");
        AddLPContent.SetRange("Location Code", _MobLicensePlateContent."Location Code");
        AddLPContent.SetRange("Bin Code", _MobLicensePlateContent."Bin Code");
        AddLPContent.SetRange("Whse. Document Type", _MobLicensePlateContent."Whse. Document Type");
        AddLPContent.SetRange("Whse. Document No.", _MobLicensePlateContent."Whse. Document No.");
        AddLPContent.SetRange("Whse. Document Line No.", _MobLicensePlateContent."Whse. Document Line No.");
        AddLPContent.SetRange("Source Type", _MobLicensePlateContent."Source Type");
        AddLPContent.SetRange("Source No.", _MobLicensePlateContent."Source No.");
        AddLPContent.SetRange("Source Line No.", _MobLicensePlateContent."Source Line No.");
        AddLPContent.SetRange("Source Document", _MobLicensePlateContent."Source Document");
        AddLPContent.SetRange(Type, _MobLicensePlateContent.Type);
        AddLPContent.SetRange("No.", _MobLicensePlateContent."No.");
        AddLPContent.SetRange("Unit Of Measure Code", _MobLicensePlateContent."Unit Of Measure Code");
        AddLPContent.SetRange("Variant Code", _MobLicensePlateContent."Variant Code");
        AddLPContent.SetTrackingFilterFromLicensePlateContent(_MobLicensePlateContent);

        // Content exists, update the Quantity
        if AddLPContent.FindFirst() then begin
            AddLPContent.Validate(Quantity, AddLPContent.Quantity + _MobLicensePlateContent.Quantity);
            AddLPContent.Modify();
        end else begin
            // Copy Tracking
            _MobLicensePlateContent.CopyTrackingToMobTrackingSetup(MobTrackingSetup);

            // Create as new content
            AddLPContent.Init();
            AddLPContent.SetValuesFromLicensePlate(Rec."No.");
            AddLPContent.Validate("Line No.", LicensePlateMgt.GetNextLicensePlateContentLineNo(Rec));
            AddLPContent.Validate("Whse. Document Line No.", _MobLicensePlateContent."Whse. Document Line No.");
            AddLPContent.Validate("Source Type", _MobLicensePlateContent."Source Type");
            AddLPContent.Validate("Source No.", _MobLicensePlateContent."Source No.");
            AddLPContent.Validate("Source Line No.", _MobLicensePlateContent."Source Line No.");
            AddLPContent.Validate("Source Document", _MobLicensePlateContent."Source Document");
            AddLPContent.Validate(Type, _MobLicensePlateContent.Type);
            AddLPContent.Validate("No.", _MobLicensePlateContent."No.");
            AddLPContent.Validate("Variant Code", _MobLicensePlateContent."Variant Code");
            AddLPContent.Validate("Unit Of Measure Code", _MobLicensePlateContent."Unit Of Measure Code");
            AddLPContent.Validate(Quantity, _MobLicensePlateContent.Quantity);
            AddLPContent.SetTracking(MobTrackingSetup);
            AddLPContent.Insert();
        end;
    end;

    /// <summary>
    /// Create new Content of type "License Plate" in the ToMobLicensePlate based on this License Plate
    /// </summary>
    internal procedure CreateAsContent(_ToMobLicensePlate: Record "MOB License Plate")
    var
        MobLicensePlateContent: Record "MOB License Plate Content";
        MobLicensePlateMgt: Codeunit "MOB License Plate Mgt";
    begin
        MobLicensePlateContent.Init();
        MobLicensePlateContent.Validate("Line No.", MobLicensePlateMgt.GetNextLicensePlateContentLineNo(_ToMobLicensePlate));
        MobLicensePlateContent.SetValuesFromLicensePlate(_ToMobLicensePlate."No.");
        MobLicensePlateContent.Validate(Type, MobLicensePlateContent.Type::"License Plate");
        MobLicensePlateContent.Validate("No.", Rec."No.");
        MobLicensePlateContent.Validate("Quantity (Base)", 1);
        MobLicensePlateContent.Insert();
    end;

    /// <summary>
    /// Delete this License Plate as Content in another License Plate
    /// </summary>
    internal procedure DeleteAsContent()
    var
        MobLicensePlateContent: Record "MOB License Plate Content";
    begin
        MobLicensePlateContent.SetCurrentKey(Type, "No.");
        MobLicensePlateContent.SetRange(Type, MobLicensePlateContent.Type::"License Plate");
        MobLicensePlateContent.SetRange("No.", Rec."No.");
        if MobLicensePlateContent.FindFirst() then
            MobLicensePlateContent.Delete(true);
    end;

    /// <summary>
    /// Move a License Plate into (another) License Plate as Content of type 'License Plate'
    /// </summary>
    internal procedure MoveToLicensePlate(var _ToMobLicensePlate: Record "MOB License Plate")
    var
        MobLicensePlateMgt: Codeunit "MOB License Plate Mgt";
    begin
        // Ensure the movement doesn't result in a circular reference
        MobLicensePlateMgt.CheckIsValidToLicensePlate(Rec."No.", _ToMobLicensePlate."No.");

        // Delete content from the License Plate containing the License Plate to be moved
        DeleteAsContent();

        // Create content in the To License Plate
        CreateAsContent(_ToMobLicensePlate);
    end;

    internal procedure GetReferenceID(): Text
    var
        WhseShipmentHeader: Record "Warehouse Shipment Header";
        WhseReceiptHeader: Record "Warehouse Receipt Header";
    begin
        case Rec."Whse. Document Type" of
            Rec."Whse. Document Type"::Shipment:
                if WhseShipmentHeader.Get(Rec."Whse. Document No.") then
                    exit(MobWmsToolbox.GetReferenceID(WhseShipmentHeader));
            Rec."Whse. Document Type"::Receipt:
                if WhseReceiptHeader.Get(Rec."Whse. Document No.") then
                    exit(MobWmsToolbox.GetReferenceID(WhseReceiptHeader));
        end;
    end;

    internal procedure GetSourceReferenceID(): Text
    var
        WhseShipmentHeader: Record "Warehouse Shipment Header";
        WhseShipmentLine: Record "Warehouse Shipment Line";
        WhseReceiptHeader: Record "Warehouse Receipt Header";
        WhseReceiptLine: Record "Warehouse Receipt Line";
    begin
        case Rec."Whse. Document Type" of
            Rec."Whse. Document Type"::Shipment:
                if WhseShipmentHeader.Get(Rec."Whse. Document No.") then begin
                    // Add reference to specific Source Document - in this case assume all Whse. Shipment Lines are for same Source Doc.                        
                    WhseShipmentLine.SetRange("No.", WhseShipmentHeader."No.");
                    if WhseShipmentLine.FindFirst() then
                        exit(MobWmsToolbox.GetSourceReferenceIDFromWhseShipmentLine(WhseShipmentLine));
                end;
            Rec."Whse. Document Type"::Receipt:
                if WhseReceiptHeader.Get(Rec."Whse. Document No.") then begin
                    // Add reference to specific Source Document - in this case assume all Whse. Shipment Lines are for same Source Doc.                        
                    WhseReceiptLine.SetRange("No.", WhseReceiptHeader."No.");
                    if WhseReceiptLine.FindFirst() then
                        exit(MobWmsToolbox.GetSourceReferenceIDFromWhseReceiptLine(WhseReceiptLine));
                end;
        end;
    end;

    /// <summary>
    /// Get related PutAwayNo for this License Plate if any
    /// </summary>    
    /// <returns>PutAwayNo if found, else return blanl</returns>
    internal procedure GetRelatedPutAwayNo() PutAwayNo: Code[20]
    var
        WhseActLine: Record "Warehouse Activity Line";
    begin
        WhseActLine.SetCurrentKey("Whse. Document No.", "Whse. Document Type", "Activity Type");
        WhseActLine.SetRange("Whse. Document No.", Rec."Whse. Document No.");
        WhseActLine.SetRange("Whse. Document Type", Rec."Whse. Document Type");
        WhseActLine.SetRange("Activity Type", WhseActLine."Activity Type"::"Put-away");
        if WhseActLine.FindFirst() then
            exit(WhseActLine."No.");
    end;

    /// <summary>
    /// Sets the initial "Receipt Status" 
    /// </summary>
    internal procedure InitReceiptStatus()
    begin
        if Rec."Whse. Document Type" <> Rec."Whse. Document Type"::Receipt then
            Rec.Validate("Receipt Status", Rec."Receipt Status"::" ")
        else
            Rec.Validate("Receipt Status", Rec."Receipt Status"::Ready);
    end;

    /// <summary>
    /// Create new empty LP. Can be related to a Whse. Document or just a Bin
    /// If _NewLicensePlateNo is empty, a new No. is assigned from the No. Series
    /// </summary>
    internal procedure InitLicensePlate(_NewLicensePlateNo: Code[20]; _LocationCode: Code[10]; _BinCode: Code[20]; _WhseDocumentType: Option; _WhseDocumentNo: Code[20])
    var
        MobLicensePlateMgt: Codeunit "MOB License Plate Mgt";
    begin
        Rec.Init();

        if _NewLicensePlateNo <> '' then
            Rec.Validate("No.", _NewLicensePlateNo)
        else
            Rec.Validate("No.", MobLicensePlateMgt.GetNextLicensePlateNo(true));

        if _LocationCode <> '' then
            Rec.Validate("Location Code", _LocationCode);

        if _BinCode <> '' then
            Rec.Validate("Bin Code", _BinCode);

        if (_WhseDocumentNo <> '') and (_WhseDocumentType <> 0) then begin
            Rec.Validate("Whse. Document Type", _WhseDocumentType);
            Rec.Validate("Whse. Document No.", _WhseDocumentNo);
        end;
    end;

    /// <summary>
    /// Remove content from License Plate
    /// If not enough content exists, an error is raised
    /// </summary>    
    internal procedure RemoveLicensePlateContent(_Quantity: Decimal; _ItemNo: Code[20]; _VariantCode: Code[10]; _UnitOfMeasure: Code[10]; _SerialNumber: Code[50]; _LotNumber: Code[50]; _PackageNumber: Code[50])
    var
        LicensePlateContent: Record "MOB License Plate Content";
        QtyToDelete: Decimal;
    begin
        QtyToDelete := _Quantity;

        LicensePlateContent.SetRange("License Plate No.", Rec."No.");
        LicensePlateContent.SetRange(Type, LicensePlateContent.Type::Item);
        LicensePlateContent.SetRange("No.", _ItemNo);
        LicensePlateContent.SetRange("Variant Code", _VariantCode);
        LicensePlateContent.SetRange("Unit Of Measure Code", _UnitOfMeasure);
        LicensePlateContent.SetRange("Serial No.", _SerialNumber);
        LicensePlateContent.SetRange("Lot No.", _LotNumber);
        LicensePlateContent.SetRange("Package No.", _PackageNumber);
        if LicensePlateContent.FindSet() then
            repeat
                // Update existing Content
                if QtyToDelete >= LicensePlateContent.Quantity then begin
                    QtyToDelete := QtyToDelete - LicensePlateContent.Quantity;
                    LicensePlateContent.Delete();
                end else begin
                    LicensePlateContent.Validate(Quantity, LicensePlateContent.Quantity - QtyToDelete);
                    LicensePlateContent.Modify(true);
                    QtyToDelete := 0;
                end;
            until (LicensePlateContent.Next() = 0) or (QtyToDelete <= 0);

        if QtyToDelete > 0 then
            Error(LicensePlateQtyUpdateErr, Rec."No.", _Quantity, _Quantity - QtyToDelete, _UnitOfMeasure);
    end;
}
