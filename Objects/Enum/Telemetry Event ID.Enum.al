enum 81370 "MOB Telemetry Event ID"
{

    // The values are prefixed with MOB in the Telemetry.
    // The names should have the MOB number at the end, to show the values in intellisense.
    // The caption does not need the MOB number as it is stored in Telemetry with the event id.

    Extensible = false;

    // Feature Uptake
    value(1000; "Package No. Implementation (Standard Mobile WMS) (MOB1000)")
    {
        Caption = 'Package No. Implementation (Standard Mobile WMS)', Locked = true;
    }
    value(1001; "Package No. implementation (None/Customization) (MOB1001)")
    {
        Caption = 'Package No. implementation (None/Customization)', Locked = true;
    }
    value(1010; "Pack & Ship Feature (MOB1010)")
    {
        Caption = 'Pack & Ship Feature', Locked = true;
    }
    value(1015; "Pack & Ship ATO Feature (MOB1015)")
    {
        Caption = 'Pack & Ship ATO Feature', Locked = true;
    }
    value(1020; "Mobile Print Feature (MOB1020)")
    {
        Caption = 'Mobile Print Feature', Locked = true;
    }
    value(1030; "Tasklet PrintNode Feature (MOB1030)")
    {
        Caption = 'Tasklet PrintNode Feature', Locked = true;
    }
    value(1040; "Mobile WMS Trial (MOB1040)")
    {
        Caption = 'Mobile WMS Trial', Locked = true;
    }
    value(1050; "License Plating (MOB1050)")
    {
        Caption = 'License Plating', Locked = true;
    }
    value(1060; "License Plating - Create LP during Receive (MOB1060)")
    {
        Caption = 'License Plating - Create LP during Receive', Locked = true;
    }
    value(1070; "License Plating - Put-away LP (MOB1070)")
    {
        Caption = 'License Plating - Put-away LP', Locked = true;
    }
    value(1075; "License Plating - Print LP Label in Receive (MOB1075)")
    {
        Caption = 'License Plating - Print LP Label in Receive', Locked = true;
    }
    value(1077; "License Plating - Start New LP (MOB1077)")
    {
        Caption = 'License Plating - Start New LP', Locked = true;
    }
    value(1080; "License Plating - Unplanned Move with LP (MOB1080)")
    {
        Caption = 'License Plating - Unplanned Move with LP', Locked = true;
    }
    value(1085; "License Plating - Prod. Output to LP (MOB1085)")
    {
        Caption = 'License Plating - Prod. Output to LP', Locked = true;
    }
    value(1087; "License Plating - Pick From LP (MOB1087)")
    {
        Caption = 'License Plating - Pick From LP', Locked = true;
    }
    value(1090; "License Plating - LP Created manually (MOB1090)")
    {
        Caption = 'License Plating - LP Created manually', Locked = true;
    }
    // Generic Usage and Errors
    value(2000; "MOB Request Processing (ok) (MOB2000)")
    {
        Caption = 'MOB Request Processing (ok)', Locked = true;
    }
    value(2001; "MOB Request Processing (error) (MOB2001)")
    {
        Caption = 'MOB Request Processing (error)', Locked = true;
    }
    value(2002; "MOB Request Processing (warning) (MOB2002)")
    {
        Caption = 'MOB Request Processing (warning)', Locked = true;
    }
    value(2010; "MOB Setup table (MOB2010)")
    {
        Caption = 'MOB Setup table', Locked = true;
    }
    value(2020; "MOB Tweak Usage (MOB2020)")
    {
        Caption = 'MOB Tweak Usage', Locked = true;
    }
    // HTTP Helper
    value(2100; "MOB HTTP Helper TrySend() Failed (MOB2100)")
    {
        Caption = 'MOB HTTP Helper TrySend() Failed', Locked = true;
    }
    // PrintNode
    value(2200; "MOB PrintNode Get Printers (MOB2200)")
    {
        Caption = 'MOB PrintNode Get Printers', Locked = true;
    }
    // Sandbox Configuration Guide
    value(2300; "MOB Sandbox Configuration Guide (MOB2300)")
    {
        Caption = 'MOB Sandbox Configuration Guide', Locked = true;
    }
    // Item Tracking
    value(2400; "MOB Specific Tracking Without Whse Tracking Detected (MOB2400)")
    {
        Caption = 'MOB Specific Tracking Without Whse Tracking Detected', Locked = true;
    }
}
