pageextension 81408 "MOB Whse. Shipment Subform" extends "Whse. Shipment Subform"
{

    layout
    {
        addlast(Control1)
        {
            field(MOBToteIDs; MobWmsToolbox.LookupTotes(Rec))
            {
                Caption = 'Tote ID''s';
                ToolTip = 'Tote ID''s associated with the current Warehouse Shipment Line.';
                ApplicationArea = All;
            }
        }
    }
    var
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";

}
