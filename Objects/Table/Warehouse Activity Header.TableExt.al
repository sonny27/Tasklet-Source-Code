tableextension 81410 "MOB Warehouse Activity Header" extends "Warehouse Activity Header"


// Tasklet Factory - Mobile WMS
// Added the "MOB Posting Message ID" field
// This field is set when documents are being posting from the mobile device or mobile queue
// Added the "MOB Tote Picking Enabled" field
// This field specifies if Tote Picking is enabled for the pick and all related picks for the same warehouse shipment
// Value is preferable read as boolean through Rec."MOB GetTotePickingEnabled" (will fallback to default value from MobSetup as needed)

{
    fields
    {
#pragma warning disable LC0044 // Names does not match cop-rule - This is not an issue we want to fix
        field(6181280; "MOB Posting MessageId"; Guid)
#pragma warning restore LC0044
        {
            Description = 'Mobile WMS';
            Caption = 'Posting Mobile MessageId';
            DataClassification = CustomerContent;
        }
        field(6181318; "MOB Tote Picking Enabled"; Option)
        {
            Caption = 'Tote Picking Enabled';
            OptionCaption = 'Default,No,Yes';
            OptionMembers = Default,No,Yes;
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                MobWmsRegistration: Record "MOB WMS Registration";
            begin
                if MOBGetFirstRegistrationData(MobWmsRegistration) then
                    // Prevent changing the value when pick registration has started
                    if "MOB GetTotePickingEnabled"() <> (MobWmsRegistration."Tote ID" <> '') then
                        Error(PickStartedTotePickingCannotBeChangedErr);
            end;
        }
        /* #if BC19+ */
        field(6181319; "MOB Action Type Filter"; Enum "Warehouse Action Type")
        {
            Caption = 'Action Type Filter';
            FieldClass = FlowFilter;
        }
        /* #endif */
        /* #if BC18- ##
        field(6181319; "MOB Action Type Filter"; Option)
        {
            Caption = 'Action Type Filter';
            FieldClass = FlowFilter;
            OptionMembers = " ",Take,Place;
        }
        /* #endif */
        field(6181320; "MOB Breakbulk No. Filter"; Integer)
        {
            Caption = 'Breakbulk No. Filter';
            FieldClass = FlowFilter;
        }
        field(6181321; "MOB No. of Lines"; Integer)
        {
            Caption = 'No. of Lines';
            FieldClass = FlowField;
            Editable = false;
            CalcFormula = count("Warehouse Activity Line" where("Activity Type" = field(Type),
                                                                 "No." = field("No."),
                                                                 "Source Type" = field("Source Type Filter"),
                                                                 "Source Subtype" = field("Source Subtype Filter"),
                                                                 "Source No." = field("Source No. Filter"),
                                                                 "Location Code" = field("Location Filter"),
                                                                 "Action Type" = field("MOB Action Type Filter"),
                                                                 "Breakbulk No." = field("MOB Breakbulk No. Filter")));
        }

    }

    var
        PickStartedTotePickingCannotBeChangedErr: Label 'Pick Registration has started and Tote Picking cannot be changed.';

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
        MobRequestMgt.GetOrderValues("MOB Posting MessageId", TempMobOrderValues);
        exit(TempMobOrderValues.GetValue(_Path, _ErrorIfNotExists));
    end;

    /// <summary>
    /// Get "MOB Tote Packing Enabled" as boolean including returning value from "MOB Setup" when "MOB Tote Picking Enabled" is "Default"
    /// </summary>
    procedure "MOB GetTotePickingEnabled"(): Boolean
    var
        MobSetup: Record "MOB Setup";
    begin
        case Rec."MOB Tote Picking Enabled" of
            Rec."MOB Tote Picking Enabled"::Default:
                begin
                    MobSetup.Get();
                    exit(MobSetup."Enable Tote Picking");
                end;
            Rec."MOB Tote Picking Enabled"::Yes:
                exit(true);
            Rec."MOB Tote Picking Enabled"::No:
                exit(false);
        end;
    end;

    /// <summary>
    /// Get the first Mobile Wms Registration for the Warehouse Activity Header
    /// Use to check when a field value must be same for all registations or blank/populated for all registrations (i.e. Tote ID must be either all blank / all populated)
    /// </summary>
    local procedure MOBGetFirstRegistrationData(var _ReturnMobWmsRegistration: Record "MOB WMS Registration"): Boolean
    var
        WhseActivityLine: Record "Warehouse Activity Line";
        MobWmsRegistration: Record "MOB WMS Registration";
    begin
        WhseActivityLine.Reset();
        WhseActivityLine.SetCurrentKey("Activity Type", "No.", "Whse. Document Type", "Whse. Document No.");
        WhseActivityLine.SetRange("Activity Type", Type);
        WhseActivityLine.SetRange("No.", "No.");
        if WhseActivityLine.FindFirst() then
            repeat
                MobWmsRegistration.Reset();
                MobWmsRegistration.SetRange("Whse. Document Type", WhseActivityLine."Whse. Document Type");
                MobWmsRegistration.SetRange("Whse. Document No.", WhseActivityLine."Whse. Document No.");
                if MobWmsRegistration.FindFirst() then begin
                    _ReturnMobWmsRegistration := MobWmsRegistration;
                    exit(true);
                end;
                WhseActivityLine.SetRange("Whse. Document Type", WhseActivityLine."Whse. Document Type");
                WhseActivityLine.SetRange("Whse. Document No.", WhseActivityLine."Whse. Document No.");
                WhseActivityLine.FindLast();
                WhseActivityLine.SetRange("Whse. Document Type");
                WhseActivityLine.SetRange("Whse. Document No.");
            until WhseActivityLine.Next() = 0;

        Clear(_ReturnMobWmsRegistration);
    end;

}
