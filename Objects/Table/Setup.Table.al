table 81271 "MOB Setup"
{
    Access = Public;

    Caption = 'Mobile Setup';

    fields
    {
#pragma warning disable LC0013 // Ignore since this is a setup table
        field(1; "Primary Key"; Code[10])
#pragma warning restore LC0013
        {
            Caption = 'Primary Key';
            DataClassification = CustomerContent;
        }
        field(302; "Sort Order Pick"; Option)
        {
            Caption = 'Sort Order Pick';
            OptionCaption = 'Worksheet,Item,Bin';
            OptionMembers = Worksheet,Item,Bin;
            DataClassification = CustomerContent;
        }
        field(303; "Sort Order Put-away"; Option)
        {
            Caption = 'Sort Order Put-away';
            OptionCaption = 'Worksheet,Item,Bin';
            OptionMembers = Worksheet,Item,Bin;
            DataClassification = CustomerContent;
        }
        field(304; "Sort Order Count"; Option)
        {
            Caption = 'Sort Order Count';
            OptionCaption = 'Worksheet,Item,Bin';
            OptionMembers = Worksheet,Item,Bin;
            DataClassification = CustomerContent;
        }
        field(305; "Sort Order Movement"; Option)
        {
            Caption = 'Sort Order Movement';
            OptionCaption = 'Worksheet,Item,Bin';
            OptionMembers = Worksheet,Item,Bin;
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// Used by "Unplanned Move", "Bulk Move"
        /// </summary>
        field(306; "Move Whse. Jnl Template"; Code[10])
        {
            Caption = 'Warehouse Reclassification Template';
            TableRelation = "Warehouse Journal Template".Name where(Type = const(Reclassification));
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// Used by "Unplanned Move", "Bulk Move"
        /// </summary>
        field(307; "Unplanned Move Batch Name"; Code[10])
        {
            Caption = 'Warehouse Reclassification Batch';
            TableRelation = "Warehouse Journal Batch".Name where("Journal Template Name" = field("Move Whse. Jnl Template"));
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// Used by "Count", "Unplanned Count", "Add Count Line"
        /// </summary>
        field(308; "Inventory Jnl Template"; Code[10])
        {
            Caption = 'Physical Inventory Template';
            TableRelation = "Item Journal Template".Name where(Type = const("Phys. Inventory"));
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// Used by "Count", "Unplanned Count", "Add Count Line"
        /// </summary>
        field(309; "Whse Inventory Jnl Template"; Code[10])
        {
            Caption = 'Warehouse Physical Inventory Template';
            TableRelation = "Warehouse Journal Template".Name where(Type = const("Physical Inventory"));
            DataClassification = CustomerContent;
        }
        field(310; "Handheld Enable Count Warning"; Boolean)
        {
            Caption = 'Unplanned Count Warning';
            DataClassification = CustomerContent;
        }
        field(311; "Handheld Count Warning Percent"; Decimal)
        {
            Caption = 'Count Warning Tolerance %';
            DataClassification = CustomerContent;
        }
        field(312; "Handheld Count Warn. Min. Qty."; Decimal)
        {
            Caption = 'Count Warning Min. Tolerance';
            DecimalPlaces = 0 : 2;
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// Used by "Unplanned Count"
        /// </summary>
        field(313; "Physical Inventory Batch"; Code[10])
        {
            Caption = 'Physical Inventory Batch';
            TableRelation = "Item Journal Batch".Name where("Journal Template Name" = field("Inventory Jnl Template"), "Template Type" = const("Phys. Inventory"));
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// Used by "Unplanned Count"
        /// </summary>
        field(314; "Whse. Physical Inventory Batch"; Code[10])
        {
            Caption = 'Warehouse Physical Inventory Batch';
            TableRelation = "Warehouse Journal Batch".Name where("Journal Template Name" = field("Whse Inventory Jnl Template"));
            DataClassification = CustomerContent;
        }
        field(315; "Use Base Unit of Measure"; Boolean)
        {
            Caption = 'Use Base Unit of Measure';
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// Used by "Unplanned Move", "Bulk Move"
        /// </summary>
        field(316; "Move Item Jnl. Template"; Code[10])
        {
            Caption = 'Item Reclassification Template';
            TableRelation = "Item Journal Template".Name where(Type = const(Transfer));
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// Used by "Unplanned Move", "Bulk Move"
        /// </summary>
        field(317; "Unpl. Item Jnl Move Batch Name"; Code[10])
        {
            Caption = 'Item Reclassification Batch';
            TableRelation = "Item Journal Batch".Name where("Journal Template Name" = field("Move Item Jnl. Template"), "Template Type" = const(Transfer));
            DataClassification = CustomerContent;
        }
        field(318; "Enable Tote Picking"; Boolean)
        {
            Caption = 'Enable Tote Picking';
            DataClassification = CustomerContent;
        }
        field(319; "Tote per"; Option)
        {
            Caption = 'Tote per';
            OptionCaption = 'Destination No.,Source No.,Whse. Document No.';
            OptionMembers = "Destination No.","Source No.","Whse. Document No.";
            DataClassification = CustomerContent;
        }
        field(320; "Enable Log-Trade integration"; Boolean)
        {
            Caption = 'Enable Log-Trade integration', Locked = true;
            DataClassification = CustomerContent;
            ObsoleteState = Removed;
            ObsoleteReason = 'Not used in Mobile WMS';
            ObsoleteTag = 'MOB5.35';
        }
        field(321; "Skip Whse Unpl Count IJ Post"; Boolean)
        {
            Caption = 'Skip Whse. Unpl. Count Item Journal Post';
            DataClassification = CustomerContent;
        }
        field(322; "Skip Collect Delivery Note"; Boolean)
        {
            Caption = 'Skip collection of Delivery Note on Receive';
            DataClassification = CustomerContent;
        }
        field(325; "Allow Blank Variant Code"; Boolean)
        {
            Caption = 'Allow Blank Variant Code';
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// Used by "Adjust Quantity"
        /// </summary>
        field(328; "Item Jnl. Template"; Code[10])
        {
            Caption = 'Item Journal Template';
            TableRelation = "Item Journal Template".Name where(Type = const(Item));
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// Used by "Adjust Quantity"
        /// </summary>
        field(329; "Item Jnl. Batch"; Code[10])
        {
            Caption = 'Item Journal Batch';
            TableRelation = "Item Journal Batch".Name where("Journal Template Name" = field("Item Jnl. Template"));
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// Used by "Adjust Quantity"
        /// </summary>
        field(330; "Warehouse Jnl. Template"; Code[10])
        {
            Caption = 'Warehouse Journal Template';
            TableRelation = "Warehouse Journal Template".Name where(Type = const(Item));
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// Used by "Adjust Quantity"
        /// </summary>
        field(331; "Warehouse Jnl. Batch"; Code[10])
        {
            Caption = 'Warehouse Journal Batch';
            TableRelation = "Warehouse Journal Batch".Name where("Journal Template Name" = field("Warehouse Jnl. Template"));
            DataClassification = CustomerContent;
        }
        field(340; "Commit per Source Doc(Receive)"; Boolean)
        {
            Caption = 'Commit per Source Doc(Receive)', Locked = true;
            DataClassification = CustomerContent;
        }
        field(350; "Block Neg. Adj. if Resv Exists"; Boolean)
        {
            Caption = 'Block negative adjustment if Reservation exists';
            DataClassification = CustomerContent;
        }
        field(351; "Unpl Move Show Info"; Boolean)
        {
            Caption = 'Show available quantity on Unplanned Move';
            DataClassification = CustomerContent;
        }
        field(360; "Use Mobile DateTime Settings"; Boolean)
        {
            Caption = 'Use Mobile TimeZone when posting';
            DataClassification = CustomerContent;
        }
        field(370; "Post breakbulk automatically"; Boolean)
        {
            Caption = 'Post breakbulk lines automatically';
            DataClassification = CustomerContent;
        }

        /* #if BC18+ */
        field(380; "Package No. implementation"; Option)
        {
            Caption = 'Package No. implementation';
            OptionCaption = 'None/Customization,Standard Mobile WMS';
            OptionMembers = "None/Customization","Standard Mobile WMS";
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if (Rec."Package No. implementation" <> xRec."Package No. implementation") and (Rec."Package No. implementation" = Rec."Package No. implementation"::"Standard Mobile WMS") and GuiAllowed() then begin
                    MobFeatureTelemetryWrapper.LogUptakeDiscovered(MobTelemetryEventId::"Package No. Implementation (Standard Mobile WMS) (MOB1000)");

                    if not Confirm(ActivateStandardMobileWMSPackageNoQst, false) then
                        Rec."Package No. implementation" := xRec."Package No. implementation";
                end;

                MobFeatureTelemetryWrapper.LogUptakeSetupOfPackageNoFeature(Rec);
            end;
        }
        /* endif */

        field(390; "Enable License Plating"; Boolean)
        {
            Caption = 'Enable License Plating';
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                MobLicensePlateMgt: Codeunit "MOB License Plate Mgt";
            begin
                /* #if BC15- ##
                if Rec."Enable License Plating" then
                    Error(LicensePlatingVersionErr);
                /* #endif */

                if Rec."Enable License Plating" = xRec."Enable License Plating" then
                    exit;

                if Rec."Enable License Plating" then
                    MobLicensePlateMgt.EnableLicensePlating(Rec)
                else
                    MobLicensePlateMgt.DisableLicensePlating(Rec);
            end;
        }

        field(395; "License Plating Key"; Code[20])
        {
            Caption = 'License Plating Key', Locked = true;
            DataClassification = CustomerContent;
            ExtendedDatatype = Masked;

            trigger OnValidate()
            var
                MobFeatureTelemetryWrapper: Codeunit "MOB Feature Telemetry Wrapper";
                MobTelemetryEventId: Enum "MOB Telemetry Event ID";
            begin
                MobFeatureTelemetryWrapper.LogUptakeDiscovered(MobTelemetryEventId::"License Plating (MOB1050)");
            end;
        }

        field(400; "Use LP in Production Output"; Boolean)
        {
            Caption = 'Use License Plate in Production Output ', Locked = true;
            DataClassification = CustomerContent;
            /* #if BC21+ */
            ObsoleteState = Pending;
            ObsoleteReason = 'Replaced by location-specific setup field "MOB LP Handling in Prod. Output" (planned for removal 12/2026)';
            ObsoleteTag = 'MOB5.61';
            /* #endif */
            Editable = false;

            trigger OnValidate()
            begin
                TestField("Enable License Plating");
            end;
        }

        /// <summary>
        /// Purchase Guide
        /// </summary>
        field(510; Guide1DoNotShow; Boolean)
        {
            Caption = 'Guide1DoNotShow (internal)', Locked = true;
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                // Companies using BC23- should also disable (or enable) the Sandbox Connection Guide when they disable (or enable) the Purchase Guide.
                // Othwerwise it would suddenly appear when they later update to BC24+
                Guide2DoNotShow := Guide1DoNotShow;
            end;
        }

        /// <summary>
        /// Sandbox Configuration Guide
        /// </summary>
        field(520; Guide2DoNotShow; Boolean)
        {
            Caption = 'Guide2DoNotShow (internal)', Locked = true;
            DataClassification = CustomerContent;
        }

        field(600; "Enable Pack and Ship"; Boolean)
        {
            Caption = 'Enable Pack & Ship';
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                MobPackFeatureMgt: Codeunit "MOB Pack Feature Management";

            begin
                if Rec."Enable Pack and Ship" then begin
                    MobFeatureTelemetryWrapper.LogUptakeDiscovered(MobTelemetryEventId::"Pack & Ship Feature (MOB1010)");
                    if Rec."Legacy Pack and Ship Detected" then
                        Error(LegacyPackAndShipDetectedErr);

                    MobPackFeatureMgt.CheckReadyToEnablePackAndShip();
                    MobPackFeatureMgt.InitPackAndShip();
                    MobFeatureTelemetryWrapper.LogUptakeSetup(MobTelemetryEventId::"Pack & Ship Feature (MOB1010)");

                    // Apply default value for "Tote Per" when used from Pack & Ship
                    Rec.Validate("Tote per", "Tote per"::"Whse. Document No.");

                    Message(PackAndShipEnabledSucessTxt);
                end else
                    MobFeatureTelemetryWrapper.LogUptakeUndiscovered(MobTelemetryEventId::"Pack & Ship Feature (MOB1010)");
            end;
        }

        field(601; "Legacy Pack and Ship Detected"; Boolean)
        {
            Caption = 'Legacy Pack & Ship Detected', Locked = true;
            DataClassification = CustomerContent;
        }

        field(610; "Dimensions Unit"; Text[20])
        {
            Caption = 'Dimensions Unit';
            DataClassification = CustomerContent;
            TableRelation = "Unit of Measure";
        }
        field(611; "Weight Unit"; Text[20])
        {
            Caption = 'Weight Unit';
            DataClassification = CustomerContent;
            TableRelation = "Unit of Measure";
        }
        field(620; "LP Number Series"; Code[20])
        {
            Caption = 'License Plate Number Series';
            TableRelation = "No. Series";
            DataClassification = CustomerContent;
        }
        field(630; "Pick Collect Staging Hint"; Boolean)
        {
            Caption = 'Collect Staging Hint on Pick';
            DataClassification = CustomerContent;
        }
        field(640; "Pick Collect Packing Station"; Boolean)
        {
            Caption = 'Collect Packing Station on Pick';
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// The Application Id of the app registration that is registered in Microsoft Entra ID (AAD).
        /// </summary>
        field(700; "Entra Application Id"; Guid)
        {
            Caption = 'Entra Application (client) Id', Locked = true;
            Editable = false;
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// The Directory Id of the Application Id of the app registration that is registered in Microsoft Entra ID (AAD).
        /// Used to determine if the Microsoft Entra ID (AAD) Application Id is valid in the current tenant.
        /// </summary>
        field(710; "Entra Directory Id"; Guid)
        {
            Caption = 'Entra Directory (tenant) Id', Locked = true;
            Editable = false;
            DataClassification = CustomerContent;
        }
        /* #if BC26+ */
        /// <summary>
        /// The Store Images Externally field indicates whether the app should use external storage for storing files (images from devices).
        /// </summary>
        field(720; "Use External Storage_AttaImage"; Boolean)
        {
            Caption = 'Use External Storage (Attach Image)';
            DataClassification = CustomerContent;
            trigger OnValidate()
            var
                MobFileAccountMgt: Codeunit "MOB External Storage Setup";
                ScenarioNotAssignedErr: Label 'The file scenario "%1" is not assigned to any external file account. Please assign the scenario before enabling external storage.', Comment = '%1 - File Scenario Caption';
            begin
                if not MobFileAccountMgt.IsAttachImagesScenarioAssigned() then
                    Error(ScenarioNotAssignedErr, Format(Enum::"File Scenario"::"MOB Attach Image", 0, 0));
            end;
        }
        /* #endif */
    }

    keys
    {
        key(Key1; "Primary Key")
        {
        }
    }

    fieldgroups
    {
    }

    var
        /* #if BC15- ##
        LicensePlatingVersionErr: Label 'License Plating is not available in this version of Business Central. Please update to BC16 or later.', Locked = true;
        /* #endif */
        MobFeatureTelemetryWrapper: Codeunit "MOB Feature Telemetry Wrapper";
        MobTelemetryEventId: Enum "MOB Telemetry Event ID";
        ActivateStandardMobileWMSPackageNoQst: Label 'Activating the Standard Mobile WMS implementation for Package No. requires Mobile WMS Android App 1.8.0 (or newer).\\Do you want to continue?';
        LegacyPackAndShipDetectedErr: Label 'Pack & Ship has previously been detected - You must complete the data migration', Locked = true;
        PackAndShipEnabledSucessTxt: Label 'Pack & Ship was successfully enabled, All active users must sign out and sign in again.', Locked = true;
        LicensePlatingMustBeEnabledErr: Label 'License Plating must be enabled in Mobile WMS Setup to use this function.';

    internal procedure LicensePlatingIsEnabled(): Boolean
    begin
        if Rec.Get() then
            exit(Rec."Enable License Plating");
    end;

    internal procedure CheckLicensePlatingIsEnabled()
    begin
        if not LicensePlatingIsEnabled() then
            Error(LicensePlatingMustBeEnabledErr);
    end;
}
