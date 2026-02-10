codeunit 81369 "MOB WMS Test Localization"
{
    Access = Public;
    procedure BLUE(): Code[10]
    var
        Location: Record Location;
    begin
        if (Location.Get('BLUE')) then
            exit('BLUE');

        case (true) of
            IsCronusNL():
                exit('BLAUW');
            else
                Error('Localization.BLUE(): Evaluation CompanyName="%1" not implemented.', CompanyName());
        end;
    end;

    procedure RED(): Code[10]
    var
        Location: Record Location;
    begin
        if (Location.Get('RED')) then
            exit('RED');

        case (true) of
            IsCronusNL():
                exit('ROOD');
            else
                Error('Localization.RED(): Evaluation CompanyName="%1" not implemented.', CompanyName());
        end;
    end;

    procedure INVBIN(): Code[10]
    begin
        exit('INVBIN');        // our own location created in testhelper
    end;

    procedure SILVER(): Code[10]
    var
        Location: Record Location;
    begin
        if (Location.Get('SILVER')) then
            exit('SILVER');

        case (true) of
            IsCronusNL():
                exit('ZILVER');
            else
                Error('Localization.SILVER(): Evaluation CompanyName="%1" not implemented.', CompanyName());
        end;
    end;

    procedure WHITE(): Code[10]
    var
        Location: Record Location;
    begin
        if (Location.Get('WHITE')) then
            exit('WHITE');

        case (true) of
            IsCronusNL():
                exit('WIT');
            else
                Error('Localization.WHITE(): Evaluation CompanyName="%1" not implemented.', CompanyName());
        end;
    end;

    procedure BinType_PICK(): Code[10]
    var
        Zone: Record Zone;
        BinType: Record "Bin Type";
    begin
        Zone.Reset();
        Zone.SetRange("Location Code", WHITE());
        Zone.SetRange("Special Equipment Code", '');
        Zone.SetRange("Zone Ranking", 5);
        if (Zone.FindFirst() and BinType.Get(Zone."Bin Type Code") and BinType.Pick and (not BinType."Put Away")) then
            exit(BinType.Code);

        Error('Localization.BinType_PICK(): Localized BinType="PICK" not implemented.');
    end;

    procedure BinType_PUTAWAY(): Code[10]
    var
        Zone: Record Zone;
        BinType: Record "Bin Type";
    begin
        Zone.Reset();
        Zone.SetRange("Location Code", WHITE());
        Zone.SetRange("Special Equipment Code", 'LIFT');
        Zone.SetRange("Zone Ranking", 50);
        if (Zone.FindFirst() and BinType.Get(Zone."Bin Type Code") and BinType."Put Away" and (not BinType.Pick)) then
            exit(BinType.Code);

        Error('Localization.BinType_PUTAWAY(): Localized BinType="PUT AWAY" not implemented.');
    end;

    procedure BinType_PUTPICK(): Code[10]
    var
        Zone: Record Zone;
        BinType: Record "Bin Type";
    begin
        Zone.Reset();
        Zone.SetRange("Location Code", WHITE());
        Zone.SetRange("Cross-Dock Bin Zone", true);
        Zone.SetRange("Zone Ranking", 0);
        if (Zone.FindFirst() and BinType.Get(Zone."Bin Type Code") and BinType."Put Away" and BinType.Pick) then
            exit(BinType.Code);

        Error('Localization.BinType_PUTPICK(): Localized BinType="PUTPICK" not implemented.');
    end;

    procedure BinType_QC(): Code[10]
    var
        Zone: Record Zone;
        BinType: Record "Bin Type";
    begin
        Zone.Reset();
        Zone.SetRange("Location Code", WHITE());
        Zone.SetRange("Special Equipment Code", 'LIFT');
        Zone.SetRange("Zone Ranking", 5);
        if (Zone.FindFirst() and BinType.Get(Zone."Bin Type Code")) then
            exit(BinType.Code);

        Error('Localization.BinType_QC(): Localized BinType="QC" not implemented.');
    end;

    procedure BinType_RECEIVE(): Code[10]
    var
        Zone: Record Zone;
        BinType: Record "Bin Type";
    begin
        Zone.Reset();
        Zone.SetRange("Location Code", WHITE());
        Zone.SetRange("Special Equipment Code", 'HT1');
        Zone.SetRange("Zone Ranking", 10);
        if (Zone.FindFirst() and BinType.Get(Zone."Bin Type Code") and BinType.Receive) then
            exit(BinType.Code);

        Error('Localization.BinType_RECEIVE(): Localized BinType="RECEIVE" not implemented.');
    end;

    procedure BinType_SHIP(): Code[10]
    var
        Zone: Record Zone;
        BinType: Record "Bin Type";
    begin
        Zone.Reset();
        Zone.SetRange("Location Code", WHITE());
        Zone.SetRange("Special Equipment Code", 'HT2');
        Zone.SetRange("Zone Ranking", 200);
        if (Zone.FindFirst() and BinType.Get(Zone."Bin Type Code") and BinType.Ship) then
            exit(BinType.Code);

        Error('Localization.BinType_SHIP(): Localized BinType="SHIP" not implemented.');
    end;

    procedure CapacityUnitOfMeaure_MINUTES(): Code[10]
    var
        CapacityUnitOfMeasure: Record "Capacity Unit of Measure";
    begin
        CapacityUnitOfMeasure.Reset();
        CapacityUnitOfMeasure.SetRange(Type, CapacityUnitOfMeasure.Type::Minutes);
        if CapacityUnitOfMeasure.FindFirst() then
            exit(CapacityUnitOfMeasure.Code);

        Error('Localization.CapacityUnitOfMeasure_MINUTES(): Localized Capacity Unit of Measure="MINUTES" not implemented.');
    end;

    procedure GenProdPostingGroup_RETAIL(): Code[10]
    var
        Item: Record Item;
    begin
        if (Item.Get('1000') and (Item."Gen. Prod. Posting Group" <> '')) then
            exit(Item."Gen. Prod. Posting Group");

        Error('Localization.GenProdPostingGroup_RETAIL(): Localized Gen. Prod. Posting Group="RETAIL" not implemented.');
    end;

    procedure InventoryPostingGroup_RESALE(): Code[10]
    var
        Item: Record Item;
    begin
        if (Item.Get('1000') and (Item."Inventory Posting Group" <> '')) then
            exit(Item."Inventory Posting Group");

        Error('Localization.InventoryPostingGroup_RESALE(): Localized Inventory Posting Group="RESALE" not implemented.');
    end;

    procedure ItemCategoryCode_MISC(): Code[10]
    var
        Item: Record Item;
    begin
        if (Item.Get('1928-S') and (Item."Item Category Code" <> '')) then
            exit(Item."Item Category Code");

        Error('Localization.ItemCategoryCode_MISC(): Localized Gen. Prod. Posting Group="RETAIL" not implemented.');
    end;

    procedure MobSetup_InventoryJnllBatch_DEFAULT(): Code[10]
    var
        ItemJournalBatch: Record "Item Journal Batch";
        MobSetup: Record "MOB Setup";
    begin
        MobSetup.Get();
        ItemJournalBatch.Reset();
        ItemJournalBatch.SetRange("Journal Template Name", MobSetup."Inventory Jnl Template");
        if (ItemJournalBatch.FindFirst()) then
            exit(ItemJournalBatch.Name);

        Error('Localization.MobSetup_InventoryJnllBatch_DEFAULT(): Localized Item Jnl. Batch="DEFAULT" not implemented.');
    end;

    procedure MobSetup_WhseInventoryJnlBatch_DEFAULT(): Code[10]
    var
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        MobSetup: Record "MOB Setup";
    begin
        MobSetup.Get();
        WarehouseJournalBatch.Reset();
        WarehouseJournalBatch.SetRange("Journal Template Name", MobSetup."Whse Inventory Jnl Template");
        if (WarehouseJournalBatch.FindFirst()) then
            exit(WarehouseJournalBatch.Name);

        Error('Localization.MobSetup_WhseInventoryJnlBatch_DEFAULT(): Localized Warehouse Journal Batch="DEFAULT" not implemented.');
    end;

    procedure UoM_BOX(): Code[10]
    var
        UnitOfMeasure: Record "Unit of Measure";
    begin
        UnitOfMeasure.Reset();
        UnitOfMeasure.SetRange("International Standard Code", 'BX');
        if UnitOfMeasure.FindFirst() then
            exit(UnitOfMeasure.Code);

        Error('Localization.UoM_BOX(): Localized Unit Of Measure="BOX" not implemented.');
    end;

    procedure UoM_CAN(): Code[10]
    var
        UnitOfMeasure: Record "Unit of Measure";
    begin
        UnitOfMeasure.Reset();
        UnitOfMeasure.SetRange("International Standard Code", 'CA');
        if UnitOfMeasure.FindFirst() then
            exit(UnitOfMeasure.Code);

        Error('Localization.UoM_CAN(): Localized Unit Of Measure="CAN" not implemented.');
    end;

    procedure UoM_DAY(): Code[10]
    var
        UnitOfMeasure: Record "Unit of Measure";
    begin
        UnitOfMeasure.Reset();
        UnitOfMeasure.SetRange("International Standard Code", 'DAY');
        if UnitOfMeasure.FindFirst() then
            exit(UnitOfMeasure.Code);

        Error('Localization.UoM_DAY(): Localized Unit Of Measure="DAY" not implemented.');
    end;

    procedure UoM_GR(): Code[10]
    var
        UnitOfMeasure: Record "Unit of Measure";
    begin
        UnitOfMeasure.Reset();
        UnitOfMeasure.SetRange("International Standard Code", 'GRM');
        if UnitOfMeasure.FindFirst() then
            exit(UnitOfMeasure.Code);

        Error('Localization.UoM_GR(): Localized Unit Of Measure="GR" not implemented.');
    end;

    procedure UoM_HOUR(): Code[10]
    var
        UnitOfMeasure: Record "Unit of Measure";
    begin
        UnitOfMeasure.Reset();
        UnitOfMeasure.SetRange("International Standard Code", 'HUR');
        if UnitOfMeasure.FindFirst() then
            exit(UnitOfMeasure.Code);

        Error('Localization.UoM_HOUR(): Localized Unit Of Measure="HOUR" not implemented.');
    end;

    procedure UoM_KG(): Code[10]
    var
        UnitOfMeasure: Record "Unit of Measure";
    begin
        UnitOfMeasure.Reset();
        UnitOfMeasure.SetRange("International Standard Code", 'KGM');
        if UnitOfMeasure.FindFirst() then
            exit(UnitOfMeasure.Code);

        Error('Localization.UoM_KG(): Localized Unit Of Measure="KG" not implemented.');
    end;

    procedure UoM_KM(): Code[10]
    var
        UnitOfMeasure: Record "Unit of Measure";
    begin
        UnitOfMeasure.Reset();
        UnitOfMeasure.SetRange("International Standard Code", 'KMT');
        if UnitOfMeasure.FindFirst() then
            exit(UnitOfMeasure.Code);

        Error('Localization.UoM_KM(): Localized Unit Of Measure="KM" not implemented.');
    end;

    procedure UoM_L(): Code[10]
    var
        UnitOfMeasure: Record "Unit of Measure";
    begin
        UnitOfMeasure.Reset();
        UnitOfMeasure.SetRange("International Standard Code", 'LTR');
        if UnitOfMeasure.FindFirst() then
            exit(UnitOfMeasure.Code);

        Error('Localization.UoM_L(): Localized Unit Of Measure="L" not implemented.');
    end;

    procedure UoM_MILES(): Code[10]
    var
        UnitOfMeasure: Record "Unit of Measure";
    begin
        UnitOfMeasure.Reset();
        UnitOfMeasure.SetRange("International Standard Code", '1A');
        if UnitOfMeasure.FindFirst() then
            exit(UnitOfMeasure.Code);

        Error('Localization.UoM_MILES(): Localized Unit Of Measure="MILES" not implemented.');
    end;

    procedure UoM_PACK(): Code[10]
    var
        UnitOfMeasure: Record "Unit of Measure";
    begin
        UnitOfMeasure.Reset();
        UnitOfMeasure.SetRange("International Standard Code", 'PK');
        if UnitOfMeasure.FindFirst() then
            exit(UnitOfMeasure.Code);

        Error('Localization.UoM_PACK(): Localized Unit Of Measure="PACK" not implemented.');
    end;

    procedure UoM_PALLET(): Code[10]
    var
        UnitOfMeasure: Record "Unit of Measure";
    begin
        UnitOfMeasure.Reset();
        UnitOfMeasure.SetRange("International Standard Code", 'PF');
        if UnitOfMeasure.FindFirst() then
            exit(UnitOfMeasure.Code);

        Error('Localization.UoM_PALLET(): Localized Unit Of Measure="PALLET" not implemented.');
    end;

    procedure UoM_PCS(): Code[10]
    var
        UnitOfMeasure: Record "Unit of Measure";
    begin
        UnitOfMeasure.Reset();
        UnitOfMeasure.SetRange("International Standard Code", 'EA');
        if UnitOfMeasure.FindFirst() then
            exit(UnitOfMeasure.Code);

        Error('Localization.UoM_PCS(): Localized Unit Of Measure="PCS" not implemented.');
    end;

    procedure WhseClass_COLD(): Code[10]
    var
        WhseClass: Record "Warehouse Class";
    begin
        WhseClass.Reset();
        WhseClass.SetFilter(Description, '@2 *celsius*');
        if (WhseClass.FindFirst()) then
            exit(WhseClass.Code);

        Error('Localization.WhseClass_COLD(): Localized Warehouse Class="COLD" not implemented.');
    end;

    procedure WhseClass_DRY(): Code[10]
    var
        WhseClass: Record "Warehouse Class";
    begin
        WhseClass.Reset();
        WhseClass.SetFilter(Description, '@*60*%*');
        if (WhseClass.FindFirst()) then
            exit(WhseClass.Code);

        Error('Localization.WhseClass_DRY(): Localized Warehouse Class="DRY" not implemented.');
    end;

    procedure WhseClass_FROZEN(): Code[10]
    var
        WhseClass: Record "Warehouse Class";
    begin
        WhseClass.Reset();
        WhseClass.SetFilter(Description, '@-*8*celsius*');
        if (WhseClass.FindFirst()) then
            exit(WhseClass.Code);

        Error('Localization.WhseClass_FROZEN(): Localized Warehouse Class="FROZEN" not implemented.');
    end;

    procedure WhseClass_HEATED(): Code[10]
    var
        WhseClass: Record "Warehouse Class";
    begin
        WhseClass.Reset();
        WhseClass.SetFilter(Description, '@*15*celcius*');
        if (WhseClass.FindFirst()) then
            exit(WhseClass.Code);

        Error('Localization.WhseClass_HEATED(): Localized Warehouse Class="HEATED" not implemented.');
    end;

    procedure WhseClass_NONSTATIC(): Code[10]
    var
        WhseClass: Record "Warehouse Class";
    begin
        WhseClass.Reset();
        WhseClass.SetFilter(Description, '@*anti*');
        if (WhseClass.FindFirst()) then
            exit(WhseClass.Code);

        Error('Localization.WhseClass_NONSTATIC(): Localized Warehouse Class="NONSTATIC" not implemented.');
    end;

    procedure Zone_WHITE_ADJUSTMENT(): Code[10]
    begin
        case (true) of
            IsCronusW1(), IsCronusInsider():
                exit('ADJUSTMENT');
        end;

        Error('Localization.Zone_WHITE_ADJUSTMENT(): Localized Location="WHITE", Zone="ADJUSTMENT" not implemented.');
    end;

    procedure Zone_WHITE_BULK(): Code[10]
    var
        Zone: Record Zone;
        BinType: Record "Bin Type";
    begin
        Zone.Reset();
        Zone.SetRange("Location Code", WHITE());
        Zone.SetRange("Special Equipment Code", 'LIFT');
        Zone.SetRange("Zone Ranking", 50);
        if (Zone.FindFirst() and BinType.Get(Zone."Bin Type Code") and BinType."Put Away" and (not BinType.Pick)) then
            exit(Zone.Code);

        Error('Localization.Zone_WHITE_BULK(): Localized Location="WHITE", Zone="BULK" not implemented.');
    end;

    procedure Zone_WHITE_CROSSDOCK(): Code[10]
    var
        Zone: Record Zone;
    begin
        Zone.Reset();
        Zone.SetRange("Location Code", WHITE());
        Zone.SetRange("Bin Type Code", BinType_PUTAWAY());
        Zone.SetRange("Special Equipment Code", '');
        Zone.SetRange("Zone Ranking", 0);
        Zone.SetRange("Cross-Dock Bin Zone", true);
        if (Zone.FindFirst()) then
            exit(Zone.Code);

        Error('Localization.Zone_WHITE_CROSSDOCK(): Localized Location="WHITE", Zone="CROSSDOCK" not implemented.');
    end;

    procedure Zone_WHITE_PICK(): Code[10]
    var
        Zone: Record Zone;
    begin
        Zone.Reset();
        Zone.SetRange("Location Code", WHITE());
        Zone.SetRange("Bin Type Code", BinType_PUTPICK());
        Zone.SetRange("Special Equipment Code", '');
        Zone.SetRange("Zone Ranking", 100);
        Zone.SetRange("Cross-Dock Bin Zone", false);
        if (Zone.FindFirst()) then
            exit(Zone.Code);

        Error('Localization.Zone_WHITE_PICK(): Localized Location="WHITE", Zone="PICK" not implemented.');
    end;

    procedure Zone_WHITE_PRODUCTION(): Code[10]
    var
        Zone: Record Zone;
    begin
        Zone.Reset();
        Zone.SetRange("Location Code", WHITE());
        Zone.SetRange("Bin Type Code", BinType_QC());
        Zone.SetRange("Special Equipment Code", 'LIFT');
        Zone.SetRange("Zone Ranking", 5);
        Zone.SetRange("Cross-Dock Bin Zone", false);
        if (Zone.FindFirst()) then
            exit(Zone.Code);

        Error('Localization.Zone_WHITE_PRODUCTION(): Localized Location="WHITE", Zone="PRODUCTION" not implemented.');
    end;

    procedure Zone_WHITE_QC(): Code[10]
    var
        Zone: Record Zone;
    begin
        Zone.Reset();
        Zone.SetRange("Location Code", WHITE());
        Zone.SetRange(Code, BinType_QC());
        Zone.SetRange("Bin Type Code", BinType_QC());
        if (Zone.FindFirst()) then
            exit(Zone.Code);

        Error('Localization.Zone_WHITE_QC(): Localized Location="WHITE", Zone="QC" not implemented.');
    end;

    procedure Zone_WHITE_RECEIVE(): Code[10]
    var
        Zone: Record Zone;
    begin
        Zone.Reset();
        Zone.SetRange("Location Code", WHITE());
        Zone.SetRange("Bin Type Code", BinType_RECEIVE());
        Zone.SetRange("Special Equipment Code", 'HT1');
        Zone.SetRange("Zone Ranking", 10);
        Zone.SetRange("Cross-Dock Bin Zone", false);
        if (Zone.FindFirst()) then
            exit(Zone.Code);

        Error('Localization.Zone_WHITE_RECEIVE(): Localized Location="WHITE", Zone="RECEIVE" not implemented.');
    end;

    procedure Zone_WHITE_SHIP(): Code[10]
    var
        Zone: Record Zone;
    begin
        Zone.Reset();
        Zone.SetRange("Location Code", WHITE());
        Zone.SetRange("Bin Type Code", BinType_SHIP());
        Zone.SetRange("Special Equipment Code", 'HT2');
        Zone.SetRange("Zone Ranking", 200);
        Zone.SetRange("Cross-Dock Bin Zone", false);
        if (Zone.FindFirst()) then
            exit(Zone.Code);

        Error('Localization.Zone_WHITE_SHIP(): Localized Location="WHITE", Zone="SHIP" not implemented.');
    end;

    procedure Zone_WHITE_STAGE(): Code[10]
    var
        Zone: Record Zone;
    begin
        Zone.Reset();
        Zone.SetRange("Location Code", WHITE());
        Zone.SetRange("Bin Type Code", BinType_PICK());
        Zone.SetRange("Special Equipment Code", '');
        Zone.SetRange("Zone Ranking", 5);
        Zone.SetRange("Cross-Dock Bin Zone", false);
        if (Zone.FindFirst()) then
            exit(Zone.Code);

        Error('Localization.Zone_WHITE_STAGE(): Localized Location="WHITE", Zone="STAGE" not implemented.');
    end;

    procedure IsCronusW1(): Boolean
    begin
        exit(CompanyName() = 'CRONUS International Ltd.');
    end;

    internal procedure IsCronusInsider(): Boolean
    begin
        exit(CompanyName() = 'My Company');
    end;

    // procedure IsCronusDE(): boolean
    // begin
    //     exit(CompanyName() = 'CRONUS DE');
    // end;

    // procedure IsCronusDK(): boolean
    // begin
    //     exit(CompanyName() = 'CRONUS DK');
    // end;

    internal procedure IsCronusNL(): Boolean
    begin
        exit(CompanyName() = 'CRONUS NL');
    end;

    // procedure CronusCompanyName(): Text[30]
    // var
    //     Company: Record "Company";
    //     EvaluationCompanyName: Text[30];
    // begin
    //     EvaluationCompanyName := FirstEvaluationCompanyName();
    //     if (EvaluationCompanyName <> '') then
    //         exit(EvaluationCompanyName);

    //     Company.Reset();
    //     Company.SetRange(Name, 'CRONUS International Ltd.');
    //     if (Company.FindFirst()) then
    //         exit(Company.Name);

    //     exit('');
    // end;

    // local procedure FirstEvaluationCompanyName(): Text[30]
    // var
    //     Company: Record "Company";
    // begin
    //     Company.Reset();
    //     Company.SetRange("Evaluation Company", true);
    //     if (Company.FindFirst()) then
    //         exit(Company.Name);

    //     exit('');
    // end;
}
