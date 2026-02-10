query 81371 "MOB WMS Tracking By Bin"
{
    Access = Public;
    Caption = 'Tracking By Bin', Locked = true;
    OrderBy = ascending(Bin_Code);

    elements
    {
        dataitem(Warehouse_Entry; "Warehouse Entry")
        {
            column(Location_Code; "Location Code")
            {
            }
            column(Bin_Code; "Bin Code")
            {
            }
            column(Item_No; "Item No.")
            {
            }
            column(Variant_Code; "Variant Code")
            {
            }
            column(Lot_No; "Lot No.")
            {
            }
            column(Serial_No; "Serial No.")
            {
            }
            // Package No. available from BC18 and newer
            /* #if BC18+ */
            column(Package_No; "Package No.")
            {
            }
            /* #endif */
            column(Unit_of_Measure_Code; "Unit of Measure Code")
            {
            }
            column(Sum_Quantity; Quantity)
            {
                ColumnFilter = Sum_Quantity = filter(<> 0);
                Method = Sum;
            }
            column(Sum_Qty_Base; "Qty. (Base)")
            {
                ColumnFilter = Sum_Qty_Base = filter(<> 0);
                Method = Sum;
            }
        }
    }
}

