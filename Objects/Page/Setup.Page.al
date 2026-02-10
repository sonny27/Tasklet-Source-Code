page 81371 "MOB Setup"
{
    Caption = 'Mobile WMS Setup';
    AdditionalSearchTerms = 'Mobile WMS Setup Tasklet Configuration', Locked = true;
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    SourceTable = "MOB Setup";
    UsageCategory = Administration;
    ApplicationArea = All;
    HelpLink = 'https://taskletfactory.atlassian.net/wiki/spaces/TFSK/pages/78951894/Installation+Guide';

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';
                field("Sort Order Pick"; Rec."Sort Order Pick")
                {
                    ToolTip = 'This setting controls the sort order of Pick orders. There are 3 options: Worksheet, Item, Bin.  If "Worksheet" is selected the order lines are sorted in the sequence defined when the order was created. A typical usage of this is to sort the lines according to Bin Ranking.';
                    ApplicationArea = All;
                }
                field("Sort Order Put-away"; Rec."Sort Order Put-away")
                {
                    ToolTip = 'This setting controls the sort order of Put-Away orders. There are 3 options: Worksheet, Item, Bin.  If "Worksheet" is selected the order lines are sorted in the sequence defined when the order was created. A typical usage of this is to sort the lines according to Bin Ranking.';
                    ApplicationArea = All;
                }

                field("Use Base Unit of Measure"; Rec."Use Base Unit of Measure")
                {
                    ToolTip = 'If this check mark is set all quantities on the mobile device must be entered in the base unit of measure. If it is not set the quantities are entered in the unit of measure used on the order lines in Business Central.';
                    ApplicationArea = All;
                }
                field("Enable PackAndShip"; Rec."Enable Pack and Ship")
                {
                    ApplicationArea = All;
                    ToolTip = 'Enable Pack & Ship functionality';

                    trigger OnValidate()
                    begin
                        PackAndShipEnabled := Rec."Enable Pack and Ship";

                        CurrPage.Update(true);
                    end;
                }
                field("Enable Tote Picking"; Rec."Enable Tote Picking")
                {
                    ToolTip = 'This functionality enables you to perform Picking / Shipping operations more efficiently by consolidating several orders onto Pick orders and Shipments.';
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        EnableTotePer := Rec."Enable Tote Picking";
                    end;
                }
                field("Tote per"; Rec."Tote per")
                {
                    ToolTip = 'This setting determines how the orders are consolidated: "Destination No." = Tote per customer, "Source No." = Tote per order, "Whse. Document No." = Tote per shipment.';
                    ApplicationArea = All;
                    Enabled = EnableTotePer;

                }
                field("Skip Collect Delivery Note"; Rec."Skip Collect Delivery Note")
                {
                    ToolTip = 'Default a step to collect Delivery Note No. is displayed during posting of a Receive order. Enable this setting to hide this collection step.';
                    ApplicationArea = All;
                }
                field("Use Mobile DateTime Settings"; Rec."Use Mobile DateTime Settings")
                {
                    ToolTip = 'Controls how the current Work Date, Posting Date and Time should be determined. Enabled: Date and Time will be read from the mobile device. Disabled: Date and Time will come from the service tier or cloud hosting platform. To ensure the processed documents are posted with the current Date and Time, you might need to enable this setting. For example: The warehouse worker is located in one TimeZone and the system is hosted in another, you would want to use the device Time.';
                    ApplicationArea = All;
                }
                field("Post breakbulk automatically"; Rec."Post breakbulk automatically")
                {
                    ToolTip = 'This setting determines if breakbulk lines are hidden and posted automatically on Warehouse Activities. Automatically posting breakbulk lines for Items with Lot or Serial tracking is not supported unless Item Tracking is predefined on the Warehouse Activity Lines.';
                    ApplicationArea = All;
                }
                field("Allow Blank Variant Code"; Rec."Allow Blank Variant Code")
                {
                    ToolTip = 'Allow blank value when collecting variant code. If you store inventory both with and without variant code, enable this setting.';
                    ApplicationArea = All;
                }
                /* #if BC18+ */
                field("Package No. implementation"; Rec."Package No. implementation")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies if None/Customization or Standard Mobile WMS implementation for Package No. is enabled. Standard Mobile WMS implementation is implemented in codeunit MOB Package Management.';
                    Visible = PackageVisible;
                }
                /* #endif */
                field("Receive Commit per Source Document"; Rec."Commit per Source Doc(Receive)")
                {
                    ApplicationArea = All;
                    ToolTip = 'Commit continuously when posting multiple sources (default behavior until v5.55).', Locked = true;
                    Visible = false;
                }
            }
            group(Numbering)
            {
                Caption = 'Numbering';
                field("LP Number Series"; Rec."LP Number Series")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Number Series for License Plates';
                }
            }
            group(PackAndShip)
            {
                Caption = 'Pack & Ship', Locked = true;
                Visible = PackAndShipEnabled;

                field("Weight Unit"; Rec."Weight Unit")
                {
                    ApplicationArea = All;
                    Enabled = PackAndShipEnabled;
                    ToolTip = 'Specifies the unit of measure for weight. This is a value from the Shipping Provider and may not match up with existing Unit of Measure Codes from Business Central.';
                }
                field("Dimensions Unit"; Rec."Dimensions Unit")
                {
                    ApplicationArea = All;
                    Enabled = PackAndShipEnabled;
                    ToolTip = 'Specifies the unit of measure for dimensions. This is a value from the Shipping Provider and may not match up with existing Unit of Measure Codes from Business Central.';
                }
                field("Pick Collect Staging Hint"; Rec."Pick Collect Staging Hint")
                {
                    ApplicationArea = All;
                    Enabled = PackAndShipEnabled;
                    ToolTip = 'Specifies if a header step to collect "Staging Hint" is created during Warehouse Picks.';
                }
                field("Pick Collect Pack.Station"; Rec."Pick Collect Packing Station")
                {
                    ApplicationArea = All;
                    Enabled = PackAndShipEnabled;
                    ToolTip = 'Specifies if a header step to collect "Packing Station" is created during Warehouse Picks.';
                }
            }
            group(LicensePlate)
            {
                Caption = 'License Plate', Locked = true;
                field("License Plating Key"; Rec."License Plating Key")
                {
                    ToolTip = 'Enabling License Plating requires you to reach out to Tasklet through your Partner to learn about the possibilities and limitations of License Plating in Mobile WMS. Tasklet will then supply you with a free key to enable the feature.', Locked = true;
                    ApplicationArea = All;
                }
                field("Enable License Plating"; Rec."Enable License Plating")
                {
                    ToolTip = 'This enables the License Plating functionality for other areas than Pack & Ship. License Plating is a method of grouping items together for easier handling.';
                    ApplicationArea = All;
                }
                field("Use License Plate in Production Output"; Rec."Use LP in Production Output")
                {
                    ToolTip = 'This functionality enables you to use License Plates when registering Production Output.';
                    ApplicationArea = All;
                    Visible = false;
                    /* #if BC21+ */
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Replaced by location-specific License Plate handling configuration. Use "MOB LP Handling in Prod. Out." field on Location Card instead. (planned for removal 12/2026)';
                    ObsoleteTag = 'MOB5.61';
                    /* #endif */
                }
            }
            group("Count")
            {
                Caption = 'Count';

                field("Sort Order Count"; Rec."Sort Order Count")
                {
                    ToolTip = 'This setting controls the sort order of Count orders. There are 3 options: Worksheet, Item, Bin.  If "Worksheet" is selected the Count order lines are sorted in the sequence defined when the Count order was created. A typical usage of this is to sort the lines according to Bin Ranking.';
                    ApplicationArea = All;

                }
                group(Unplanned)
                {
                    Caption = 'Unplanned';

                    field("Handheld Enable Count Warning"; Rec."Handheld Enable Count Warning")
                    {
                        ToolTip = 'This setting controls if the user should be warned when the Unplanned Count feature is used. If the warning is enabled the user will get a warning if the physical quantity exceeds the tolerance levels defined below.';
                        ApplicationArea = All;
                    }
                    field("Handheld Count Warning Percent"; Rec."Handheld Count Warning Percent")
                    {
                        ToolTip = 'If the physical quantity exceeds this tolerance level the user will get a warning on the mobile device.';
                        ApplicationArea = All;
                    }
                    field("Handheld Count Warn. Min. Qty."; Rec."Handheld Count Warn. Min. Qty.")
                    {
                        ToolTip = 'The minimum tolerance prevents warning messages on items with a large difference in percentages, but only a small numerical difference. The difference must exceed this value before the warning is generated.';
                        ApplicationArea = All;
                    }
                    field("Skip Whse Unpl Count IJ Post"; Rec."Skip Whse Unpl Count IJ Post")
                    {
                        ToolTip = 'If – and only if - the location uses “Directed Put-away and Pick”, this setting makes it possible post the warehouse entries generated by the unplanned count and adjust quantity, without posting item journal. Periodically “Calculate Whse. Adjustment” from an Item Journal must be executed and posted.';
                        ApplicationArea = All;
                    }
                }
            }
            group(Move)
            {
                Caption = 'Move';
                group("Misc.")
                {
                    Caption = 'Miscellaneous';
                    field("Sort Order Movement"; Rec."Sort Order Movement")
                    {
                        ToolTip = 'This setting controls the sort order of Movement orders. There are 3 options: Worksheet, Item, Bin.  If "Worksheet" is selected the order lines are sorted in the sequence defined when the order was created. A typical usage of this is to sort the lines according to Bin Ranking.';
                        ApplicationArea = All;
                    }
                    field("Block Neg. Adj. if Resv Exists"; Rec."Block Neg. Adj. if Resv Exists")
                    {
                        ToolTip = 'Block negative adjustment if Reservation exists (standard Business Central behaviour is a warning if Reservation Entries exists).';
                        ApplicationArea = All;
                    }
                    field("Unpl Move Show Info"; Rec."Unpl Move Show Info")
                    {
                        ToolTip = 'Show available quantity on Unplanned Move. Makes the first “Step” an information step that shows the Quantity available to move. Enabling this view also moves the "From Bin" -field from Steps to the Header at mobile device. Mobile Users have to login again for changes to take effect.';
                        ApplicationArea = All;
                    }
                }
            }
            group(ItemAndWarehouseJournal)
            {
                Caption = 'Item & Warehouse Journals';
                grid(Grid01)
                {
                    GridLayout = Columns;
                    group(ItemJournal)
                    {
                        Caption = ' ', Locked = true;
                        field("Item Jnl, Template"; Rec."Item Jnl. Template")
                        {
                            ToolTip = 'Select the Template that is used for "Adjust Quantity".';
                            ApplicationArea = All;
                        }
                        field("Item Jnl. Adj. Qty. Batch Name"; Rec."Item Jnl. Batch")
                        {
                            ToolTip = 'Select the Batch that is used for "Adjust Quantity".';
                            ApplicationArea = All;
                        }
                    }
                    group(WarehouseJournal)
                    {
                        Caption = ' ', Locked = true;
                        field("Warehouse Journal Template"; Rec."Warehouse Jnl. Template")
                        {
                            ToolTip = 'Select the Template that is used for "Adjust Quantity".';
                            ApplicationArea = All;
                        }
                        field("Warehouse Journal Batch"; Rec."Warehouse Jnl. Batch")
                        {
                            ToolTip = 'Select the Batch that is used for "Adjust Quantity".';
                            ApplicationArea = All;
                        }
                    }
                }
            }
            group(Reclass)
            {
                Caption = 'Reclassification Journals';
                grid(Grid02)
                {
                    GridLayout = Columns;
                    group(ItemReclass)
                    {
                        Caption = ' ', Locked = true;
                        field("Move Item Jnl. Template"; Rec."Move Item Jnl. Template")
                        {
                            ToolTip = 'Select the Template that is used for "Unplanned Move" and "Bulk Move".';
                            ApplicationArea = All;
                        }
                        field("Unpl. Item Jnl Move Batch Name"; Rec."Unpl. Item Jnl Move Batch Name")
                        {
                            ToolTip = 'Select the Batch that is used for "Unplanned Move" and "Bulk Move".';
                            ApplicationArea = All;
                        }
                    }
                    group(WarehouseReclass)
                    {
                        Caption = ' ', Locked = true;
                        field("Move Whse. Jnl Template"; Rec."Move Whse. Jnl Template")
                        {
                            ToolTip = 'Select the Template that is used for "Unplanned Move" and "Bulk Move".';
                            ApplicationArea = All;
                        }
                        field("Unplanned Move Batch Name"; Rec."Unplanned Move Batch Name")
                        {
                            ToolTip = 'Select the Batch that is used for "Unplanned Move" and "Bulk Move".';
                            ApplicationArea = All;
                        }
                    }
                }
            }
            group(PhysInvt)
            {
                Caption = 'Physical Inventory Journals';
                grid(Grid03)
                {
                    GridLayout = Columns;
                    group(ItemPhysInvt)
                    {
                        Caption = ' ', Locked = true;
                        field("Inventory Jnl Template"; Rec."Inventory Jnl Template")
                        {
                            ToolTip = 'Select the Template that is used for "Count" and "Unplanned Count".';
                            ApplicationArea = All;
                        }
                        field("Unpl Item Jnl Count Batch Name"; Rec."Physical Inventory Batch")
                        {
                            ToolTip = 'Select the batch name that is used for "Unplanned Count". Note: "Count" uses the batch you have marked as "Released For Mobile".';
                            ApplicationArea = All;
                        }
                    }
                    group(WarehousePhysInvt)
                    {
                        Caption = ' ', Locked = true;
                        field("Whse Inventory Jnl Template"; Rec."Whse Inventory Jnl Template")
                        {
                            ToolTip = 'Select the Template that is used for "Count" and "Unplanned Count". The template is only used if the Location is configured to use "Directed Putaway and Pick".';
                            ApplicationArea = All;
                        }
                        field("Physical Inventory Batch"; Rec."Whse. Physical Inventory Batch")
                        {
                            ToolTip = 'Select the batch name that is used for "Unplanned Count". Note: "Count" uses the batch you have marked as "Released For Mobile".';
                            ApplicationArea = All;
                        }
                    }
                }
            }
            /* #if BC26+ */
            group(FileStorage_Group)
            {
                Caption = 'File Storage';

                field(FileAccountName_AttImages; FileAccountName)
                {
                    Caption = 'File Account Name';
                    ToolTip = 'Specifies the name of the external file account used for external storage of images (attached images from devices). The name that is shown is the name of the file account assigned to the file scenario "Tasklet - Attach Image". If no file account is assigned to the scenario, the default file account is shown and will also be used for external storage. We recommend that you create a dedicated file account for storing attached images.';
                    Editable = FileAccountNameEditable;
                    ApplicationArea = All;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        LookupFileAccount();
                    end;

                    trigger OnValidate()
                    begin
                        ValidateFileAccountName();
                    end;
                }
                group(EnableExternalStorage_AttImages_Group)
                {
                    ShowCaption = false;
                    field("Use External Storage_AttImages"; Rec."Use External Storage_AttaImage")
                    {
                        ToolTip = 'Specifies whether Tasklet Mobile WMS should use external storage for storing image files (attached images from devices). If the field is enabled, images are stored in the external file account specified here. If the field is disabled, images are stored in the database (Tenant Media).';
                        ApplicationArea = All;

                        trigger OnValidate()
                        begin
                            ValidateUseExternalStorageForAttachImages();
                        end;
                    }
                    field(TransferExisting_AttImages; TransferExistingImagesLbl)
                    {
                        ShowCaption = false;
                        ApplicationArea = All;
                        Enabled = IsExternalStorageEnabled;

                        trigger OnDrillDown()
                        begin
                            Report.Run(Report::"MOB Ext.Storage Batch Transfer");
                        end;
                    }
                }
            }
            /* #endif */
        }
    }


    actions
    {
        area(Processing)
        {
            group("Function")
            {
                Caption = 'F&unctions';
                action("Create Document Types")
                {
                    Caption = 'Create Document Types';
                    ToolTip = 'Creates the standard Document Types used by the Mobile WMS solution. The Document Types define the interface towards the mobile devices.';
                    ApplicationArea = All;
                    Image = CreateXMLFile;

                    trigger OnAction()
                    var
                        CreateDocTypes: Codeunit "MOB WMS Setup Doc. Types";
                    begin
                        CreateDocTypes.Run();
                        CurrPage.Update();
                    end;
                }
                /* #if BC17+ */
                action("Retention Policies")
                {
                    Caption = 'Enable Retention Policies';
                    ToolTip = 'Enable selected Mobile WMS tables for retention and prepare suggested retention policies.';
                    ApplicationArea = All;
                    Image = DeleteExpiredComponents;

                    trigger OnAction()
                    var
                        MobRetentionPolicyMgt: Codeunit "MOB Retention Policy Mgt.";
                    begin
                        // Ensure all Mobile WMS tables are enabled for Retention Policies and create a few default Retention Policies if not already created
                        MobRetentionPolicyMgt.SetupRetentionPolicy();

                        Message(RetentionPolicyEnabledMsg);
                    end;
                }
                /* #endif */
            }
        }
        area(Navigation)
        {
            group(PackAndShipActions)
            {
                Caption = 'Pack & Ship', Locked = true;
                Image = SetupList;

                action(MobPackageTypeList)
                {
                    Enabled = PackAndShipEnabled;
                    Visible = PackAndShipEnabled;
                    Caption = 'Mobile Package Types';
                    ToolTip = 'Show Mobile Package Types';
                    Image = WarehouseRegisters;
                    ApplicationArea = All;
                    RunObject = page "MOB Package Type List";
                }
                action(MobPackageSetup)
                {
                    Enabled = PackAndShipEnabled;
                    Visible = PackAndShipEnabled;
                    Caption = 'Mobile Package Setup';
                    ToolTip = 'Show Mobile Package Setup';
                    ApplicationArea = All;
                    Image = CreateWarehousePick;
                    RunObject = page "MOB Mobile WMS Package Setup";
                }
                action(MobPackingStationList)
                {
                    Enabled = PackAndShipEnabled;
                    Visible = PackAndShipEnabled;
                    Caption = 'Mobile Package Stations';
                    ToolTip = 'Show Mobile Package Stations';
                    ApplicationArea = All;
                    Image = PurchaseTaxStatement;
                    RunObject = page "MOB Packing Station List";
                }
            }
            group(Printing)
            {
                Caption = 'Printing', Locked = true;
                Image = SetupList;

                action(MobCloudPrintSetup)
                {
                    Caption = 'Cloud Print Setup', Locked = true;
                    ToolTip = 'Set-up of Cloud Printing', Locked = true;
                    Image = Setup;
                    ApplicationArea = All;
                    RunObject = page "MOB Print Setup";
                }

                /* #if BC16+ */
                action(MobReportPrintSetup)
                {
                    Caption = 'Report Print Setup', Locked = true;
                    ToolTip = 'Set-up of Report Printing', Locked = true;
                    ApplicationArea = All;
                    Image = Setup;
                    RunObject = page "MOB Report Print Setup";
                }

                action(MobPrintNodeSetup)
                {
                    Caption = 'PrintNode Setup', Locked = true;
                    ToolTip = 'Set-up of Tasklet PrintNode connector', Locked = true;
                    ApplicationArea = All;
                    Image = Setup;
                    RunObject = page "MOB PrintNode Setup";
                }
                /* #endif */
            }
        }
    }
    trigger OnOpenPage()
    var
        MobWmsLanguage: Codeunit "MOB WMS Language";
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;

        EnableTotePer := Rec."Enable Tote Picking";
        PackAndShipEnabled := Rec."Enable Pack and Ship";
        MobWmsLanguage.CheckENULanguageMessages();

        /* #if BC18+ */
        SetPackageVisibility();
        /* #endif */
    end;

    trigger OnAfterGetRecord()
    begin
        /* #if BC26+ */
        SetFileStorageValues(); // Placed here to ensure that FileAccountNameEditable is set correctly based on page editable state
        /* #endif */
    end;

    var
        /* #if BC26+ */
        MobExternalStorageSetup: Codeunit "MOB External Storage Setup";
        FileAccountName: Text[250];
        FileAccountNameEditable: Boolean;
        IsExternalStorageEnabled: Boolean;
        TransferExistingImagesLbl: Label 'Transfer Existing Images';
        /* #endif */
        EnableTotePer: Boolean;
        PackAndShipEnabled: Boolean;
        PackageVisible: Boolean;
        RetentionPolicyEnabledMsg: Label 'Selected Mobile WMS tables has been enabled for retention and suggested retention policies has been prepared.';

    /* #if BC18+ */
    local procedure SetPackageVisibility()
    var
        MobPackageMgt: Codeunit "MOB Package Management";
    begin
        PackageVisible := MobPackageMgt.IsFeaturePackageMgtEnabled();
    end;
    /* #endif */

    /* #if BC26+ */
    local procedure SetFileStorageValues()
    begin
        FileAccountNameEditable := CurrPage.Editable();
        FileAccountName := MobExternalStorageSetup.GetAttachImagesScenarioAccountName();
        if (FileAccountName = '') and Rec."Use External Storage_AttaImage" then begin
            Rec."Use External Storage_AttaImage" := false; // Disable if scenario is not assigned (can be unassigned from File Accounts page)
            CurrPage.Update(true);
        end;
        IsExternalStorageEnabled := Rec."Use External Storage_AttaImage";
    end;

    local procedure LookupFileAccount()
    begin
        FileAccountName := MobExternalStorageSetup.LookupAndValidateFileAccount();
        CurrPage.Update(false);
    end;

    local procedure ValidateFileAccountName()
    begin
        MobExternalStorageSetup.ValidateAttachImagesFileAccountName(FileAccountName);
        CurrPage.Update(false);
    end;

    local procedure ValidateUseExternalStorageForAttachImages()
    begin
        MobExternalStorageSetup.ValidateUseExternalStorageForAttachImages(Rec."Use External Storage_AttaImage");
        IsExternalStorageEnabled := Rec."Use External Storage_AttaImage";
    end;
    /* #endif */
}
