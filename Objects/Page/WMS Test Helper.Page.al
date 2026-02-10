page 81370 "MOB WMS Test Helper"
{
    Caption = 'Mobile Test Helper', Locked = true;
    AdditionalSearchTerms = 'Mobile Test Helper Tasklet', Locked = true;
    PageType = Card;
    SourceTable = "MOB Setup";
    UsageCategory = Administration;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General', Locked = true;
                InstructionalText = 'Create a number of locations, items and tracking codes in order to cover various test scenarios.', Locked = true;

                field(CreateBaseDataField; CreateBaseData)
                {
                    Caption = 'Create Base Data', Locked = true;
                    ToolTip = 'Specifies if a number of locations, items and tracking codes will be created in order to cover various test scenarios.', Locked = true;
                    ApplicationArea = All;
                }
            }
            group(CreateDocuments)
            {
                Caption = 'Create Documents', Locked = true;
                InstructionalText = 'Create documents in Base Unit of Measure (PCS) for each of the following locations: WHITE, INVBIN, BLUE.', Locked = true;

                field(CreatePurchaseDataField; CreatePurchaseData)
                {
                    Caption = 'Create Purchase Data', Locked = true;
                    ToolTip = 'Specifies if a purchase order in Base Unit of Measure (PCS) will be created for each of the following locations: WHITE, INVBIN, BLUE.', Locked = true;
                    ApplicationArea = All;
                }
                field(CreateTransferDataField; CreateTransferData)
                {
                    Caption = 'Create Transfer Data', Locked = true;
                    ToolTip = 'Specifies if a transfer order in Base Unit of Measure (PCS) will be created to move items from location WHITE to BLUE, from location INVBIN to WHITE and from location BLUE to INVBIN.', Locked = true;
                    ApplicationArea = All;
                }
                field(CreateSalesDataField; CreateSalesData)
                {
                    Caption = 'Create Sales Data', Locked = true;
                    ToolTip = 'Specifies if a sales order in Base Unit of Measure (PCS) will be created for each of the following locations: WHITE, INVBIN, BLUE.', Locked = true;
                    ApplicationArea = All;
                }
                field(CreateAssemblyDataField; CreateAssemblyData)
                {
                    Caption = 'Create Assembly Data', Locked = true;
                    ToolTip = 'Specifies if assembly orders (tracked+untracked) in Base Unit of Measure (PCS) will be created for each of the following locations: WHITE, INVBIN, BLUE.', Locked = true;
                    ApplicationArea = All;
                }
                field(CreateProductionDataField; CreateProductionData)
                {
                    Caption = 'Create Production Data', Locked = true;
                    ToolTip = 'Specifies if production orders (with and without route) in Base Unit of Measure (PCS) will be created for location WHITE.', Locked = true;
                    ApplicationArea = All;
                }

            }
            group(CreateDocumentsTotePick)
            {
                Caption = 'Tote Picking', Locked = true;

                field(UpdateMobileWMSSetupForTotePickField; UpdateMobileWMSForTotePick)
                {
                    Caption = 'Enable Tote Pick setup in Mobile WMS Setup', Locked = true;
                    ToolTip = 'The Mobile WMS will be setup to enable Tote Picking and "Tote per" = "Whse. Document No."', Locked = true;
                    ApplicationArea = All;
                }
                field(CreateSalesDataTotePickField; CreateSalesDataTotePick)
                {
                    Caption = 'Create Sales Data (Tote Pick)', Locked = true;
                    ToolTip = 'Specifies if a sales order in Base Unit of Measure (PCS) will be created for locations: WHITE. (Note: LOT 99 will be added to Inventory for manual test purpose)', Locked = true;
                    ApplicationArea = All;
                }
            }

            group(CreatePackAndShipData)
            {
                Caption = 'Pack & Ship', Locked = true;

                field(CreatePackAndShipDataField; CreatePackAndShipData)
                {
                    Caption = 'Create Pack & Ship Data and required Mobile WMS Setup', Locked = true;
                    ToolTip = 'The Mobile WMS will be setup to enable Pack & Ship and Demo data will be created', Locked = true;
                    ApplicationArea = All;
                }
            }
            group(CreateDocumentsBOX)
            {
                Caption = 'Create Documents (BOX)', Locked = true;
                InstructionalText = 'Create documents in alternative Unit of Measure (BOX) for each of the following locations: WHITE, INVBIN, BLUE.', Locked = true;

                field(CreatePurchaseDataBOXField; CreatePurchaseDataBOX)
                {
                    Caption = 'Create Purchase Data (BOX)', Locked = true;
                    ToolTip = 'Specifies if a purchase order in altenative Unit of Measure (BOX) will be created for each of the following locations: WHITE, INVBIN, BLUE.', Locked = true;
                    ApplicationArea = All;
                }
                field(CreateTransferDataBOXField; CreateTransferDataBOX)
                {
                    Caption = 'Create Transfer Data (BOX)', Locked = true;
                    ToolTip = 'Specifies if a transfer order in altenative Unit of Measure (BOX) will be created to move items from location WHITE to BLUE, from location INVBIN to WHITE and from location BLUE to INVBIN.', Locked = true;
                    ApplicationArea = All;
                }
                field(CreateSalesDataBOXField; CreateSalesDataBOX)
                {
                    Caption = 'Create Sales Data (BOX)', Locked = true;
                    ToolTip = 'Specifies if a sales order in altenative Unit of Measure (BOX) will be created for each of the following locations: WHITE, INVBIN, BLUE.', Locked = true;
                    ApplicationArea = All;
                }
            }

            group(PerformanceTest)
            {
                Caption = 'Performance Testing', Locked = true;
                InstructionalText = 'Create large number of documents for performance testing.', Locked = true;

                field(BatchCreateWhseInternalPicksField; BatchCreateWhseInternalPicks)
                {
                    Caption = 'Batch create Whse. Internal Picks', Locked = true;
                    ToolTip = 'Create a large number of Whse. Internal Picks.', Locked = true;
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            group("Function")
            {
                Caption = 'F&unctions', Locked = true;
                action("Execute Test Setup")
                {
                    Caption = 'Execute Test Setup', Locked = true;
                    ToolTip = 'Creation of testdata is restricted to companies named ''CRONUS'' or  ''MY COMPANY''', Locked = true;
                    Enabled = EnableExecute;
                    Image = CreateDocument;
                    ApplicationArea = All;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;

                    trigger OnAction()
                    begin
                        if CreateBaseData then begin

                            MobTesthelper.SetupAllBaseData();
                            CreateBaseData := false;

                        end;

                        //
                        // Create documents in Base Unit of Measure
                        //
                        if CreatePurchaseData then begin
                            MobTesthelper.SetupTestOrderPurchase();
                            CreatePurchaseData := false;
                        end;

                        if CreateTransferData then begin
                            MobTesthelper.SetupTestOrderTransfer();
                            CreateTransferData := false;
                        end;

                        if CreateSalesData then begin
                            MobTesthelper.SetupTestOrderSales();
                            CreateSalesData := false;
                        end;

                        if CreateAssemblyData then begin
                            MobTesthelper.SetupTestOrderAssembly();
                            CreateAssemblyData := false;
                        end;

                        if CreateProductionData then begin
                            MobTesthelper.SetupTestOrderProduction();
                            CreateProductionData := false;
                        end;

                        if UpdateMobileWMSForTotePick then begin
                            MobTesthelper.SetupMobileWMSForTotePick();
                            UpdateMobileWMSForTotePick := false;
                        end;

                        if CreateSalesDataTotePick then begin
                            MobTesthelper.SetupTestOrderSales_TotePick();
                            CreateSalesDataTotePick := false;
                        end;

                        if CreatePackAndShipData then begin
                            MobTesthelper.SetupPackAndShip();
                            CreatePackAndShipData := false;
                        end;

                        //
                        // Create documents in alternative Unit of Measure
                        //
                        if CreatePurchaseDataBOX then begin
                            MobTesthelper.SetupTestOrderPurchase_BOX();
                            CreatePurchaseDataBOX := false;
                        end;

                        if CreateTransferDataBOX then begin
                            MobTesthelper.SetupTestOrderTransfer_BOX();
                            CreateTransferDataBOX := false;
                        end;

                        if CreateSalesDataBOX then begin
                            MobTesthelper.SetupTestOrderSales_BOX();
                            CreateSalesDataBOX := false;
                        end;

                        if BatchCreateWhseInternalPicks then begin
                            MobTesthelper.BatchCreateWhseInternalPicks(100);
                            BatchCreateWhseInternalPicks := false;
                        end;

                        CurrPage.Update(false);
                    end;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        if (StrPos(UpperCase(CompanyName()), 'CRONUS') <> 0) or
           (StrPos(UpperCase(CompanyName()), 'MY COMPANY') <> 0) then
            EnableExecute := true
        else
            Message(CreationIsRestrictedLbl);

        if not Item.Get('TF-001') then
            CreateBaseData := true;
    end;

    var
        Item: Record Item;
        MobTesthelper: Codeunit "MOB Test Helper";
        EnableExecute: Boolean;
        CreateBaseData: Boolean;
        CreatePurchaseData: Boolean;
        CreateTransferData: Boolean;
        CreateSalesData: Boolean;
        CreatePurchaseDataBOX: Boolean;
        CreateTransferDataBOX: Boolean;
        CreateSalesDataBOX: Boolean;
        CreationIsRestrictedLbl: Label 'Creation of testdata is restricted to companies named *CRONUS* or *MY COMPANY*', Locked = true;
        CreateAssemblyData: Boolean;
        CreateProductionData: Boolean;
        CreateSalesDataTotePick: Boolean;
        UpdateMobileWMSForTotePick: Boolean;
        BatchCreateWhseInternalPicks: Boolean;
        CreatePackAndShipData: Boolean;
}
