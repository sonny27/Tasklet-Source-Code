tableextension 81480 "MOB Warehouse Shipment Header" extends "Warehouse Shipment Header"


// Tasklet Factory - Mobile WMS
// Added the "MOB Posting Message ID" field
// This field is set when documents are being posting from the mobile device or mobile queue

{
    fields
    {
        field(6181280; "MOB Posting MessageId"; Guid)
        {
            Description = 'Mobile WMS';
            Caption = 'Posting Mobile MessageId';
            DataClassification = CustomerContent;
        }

        field(6182230; "MOB Packing Station Code"; Code[20])
        {
            Caption = 'Packing Station Code';
            DataClassification = CustomerContent;
            TableRelation = "MOB Packing Station";
        }
    }

    /// <summary>
    /// Get the value for a custom header step for the Mobile Message ID currently being posted ("MOB Posting MessageId")
    /// </summary>
    /// <param name="_Path">The identification for the step as declared in the eventsubcriber that created the step</param>
    /// <param name="_ErrorIfNotExists">Throw error if _Path could not be found. If false, an empty string will be returned if _Path not exists</param>
    /// <remarks>If reading many values, you may use "MobRequestMgt.GetOrderValues("MOB Posting MessageId", TempMobOrderValues)" for better performance</remarks>
    procedure "MOB GetOrderValue"(_Path: Text; _ErrorIfNotExists: Boolean): Text
    var
        TempMobOrderValues: Record "MOB Common Element" temporary;
        MobRequestMgt: Codeunit "MOB NS Request Management";
    begin
        TestField("MOB Posting MessageId");
        MobRequestMgt.GetOrderValues("MOB Posting MessageId", TempMobOrderValues);
        exit(TempMobOrderValues.GetValue(_Path, _ErrorIfNotExists));
    end;

    /// <summary>
    /// Checks if the warehouse shipment contains ATO lines
    /// </summary>
    internal procedure "MOB ATOLinesExist"(): Boolean
    var
        WhseShipmentLine: Record "Warehouse Shipment Line";
    begin
        WhseShipmentLine.SetRange("No.", Rec."No.");
        WhseShipmentLine.SetRange("Assemble to Order", true);
        exit(not WhseShipmentLine.IsEmpty());
    end;

    /// <summary>
    /// Checks if all lines from a warehouse shipment are fully picked including not ATO lines and non-ATO lines
    /// </summary>    
    internal procedure "MOB CompletelyPicked"(): Boolean
    var
        WhseShipmentLine: Record "Warehouse Shipment Line";
        MobPackMgt: Codeunit "MOB Pack Management";
    begin
        // Checks if there are any ATO lines, if not then use the standard field "completely picked"
        if not "MOB ATOLinesExist"() then begin
            Rec.CalcFields("Completely Picked");
            exit(Rec."Completely Picked");
        end;

        // Checks if all ATO lines are completely picked
        if MobPackMgt.ATOCompletelyPicked(Rec) then begin

            // Check if all non-ATO lines are completely picked
            WhseShipmentLine.SetRange("No.", Rec."No.");
            WhseShipmentLine.SetRange("Assemble to Order", false);
            WhseShipmentLine.SetRange("Completely Picked", false);
            exit(WhseShipmentLine.IsEmpty());
        end;

        // If none of the above checks have resulted in exit(true) then the Shipment is not completely picked
        exit(false);
    end;
}
