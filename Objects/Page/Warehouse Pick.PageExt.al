pageextension 81409 "MOB Warehouse Pick" extends "Warehouse Pick"
{

    layout
    {
        addlast(General)
        {
            field(MOBTotePickingEnabledDefaultYes; Rec."MOB Tote Picking Enabled")
            {
                OptionCaption = 'Default (Yes),No,Yes';
                ToolTip = 'Specifies "Tote Picking" for this document. Default refers to setting on Mobile WMS Setup';
                Visible = MOBShowTotePickingEnabledDefaultYes;
                ApplicationArea = All;
            }
            field(MOBTotePickingEnabledDefaultNo; Rec."MOB Tote Picking Enabled")
            {
                OptionCaption = 'Default (No),No,Yes';
                ToolTip = 'Specifies "Tote Picking" for this document. Default refers to setting on Mobile WMS Setup';
                Visible = MOBShowTotePickingEnabledDefaultNo;
                ApplicationArea = All;
            }
        }
    }

    var
        MOBShowTotePickingEnabledDefaultYes: Boolean;
        MOBShowTotePickingEnabledDefaultNo: Boolean;

    // InherentPermissions valid from BC21+
    [InherentPermissions(PermissionObjectType::TableData, Database::"MOB Setup", 'R', InherentPermissionsScope::Both)]
    local procedure MOBEnableShowTotePickingEnabled()
    var
        MobSetup: Record "MOB Setup";
    begin
        // For versions prior to BC21: check if user has permissions to MobSetup to avoid error
        if not MobSetup.ReadPermission() then
            exit;
        if not MobSetup.Get() then
            exit;

        MOBShowTotePickingEnabledDefaultYes := MobSetup."Enable Tote Picking";
        MOBShowTotePickingEnabledDefaultNo := not MOBShowTotePickingEnabledDefaultYes;
    end;

    trigger OnOpenPage()
    begin
        MOBEnableShowTotePickingEnabled();
    end;
}
