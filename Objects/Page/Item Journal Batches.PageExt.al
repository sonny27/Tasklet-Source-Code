pageextension 81403 "MOB Item Journal Batches" extends "Item Journal Batches"
{


    layout
    {
        addlast(Control1)
        {
            field(MOBReleasedToMobile; Rec.MOBReleasedToMobile)
            {
                Caption = 'Released To Mobile';
                ToolTip = 'Is the Item Journal Batch visible at the Mobile Device.';
                ApplicationArea = All;
                Visible = TemplateIsMobSetup;
            }
        }
    }
    actions
    {
        addafter("Edit Journal")
        {
            action(MOBReleaseToMobile)
            {
                Caption = 'Release To Mobile';
                ToolTip = 'Toggle making this Item Journal Batch visible at the Mobile Device.';
                ApplicationArea = All;
                Image = ReleaseDoc;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                Visible = TemplateIsMobSetup;

                trigger OnAction()
                begin
                    Rec.MOBReleasedToMobile := not Rec.MOBReleasedToMobile;
                    Rec.Modify(true);
                end;
            }
        }
    }

    var
        TemplateIsMobSetup: Boolean;

    // InherentPermissions valid from BC21+
    [InherentPermissions(PermissionObjectType::TableData, Database::"MOB Setup", 'R', InherentPermissionsScope::Both)]
    local procedure MOBCheckItemJournalMobSetup()
    var
        MobSetup: Record "MOB Setup";
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        // Filtergroup 2 (Page filter) is used when this page is called from "Item Journal Templates"
        if Rec.GetFilter("Journal Template Name") = '' then begin
            Rec.FilterGroup(2); // Search for filtergroup 2
            if Rec.GetFilter("Journal Template Name") = '' then
                exit;
        end;
        // For versions prior to BC21: check if user has permissions to MobSetup to avoid error
        if not MobSetup.ReadPermission() then
            exit;
        if not MobSetup.Get() then
            exit;
        // Template must be = Phys. Inventory and Page filter must = MobSetup 
        if ItemJournalTemplate.Get(Rec.GetFilter("Journal Template Name")) then
            TemplateIsMobSetup := (ItemJournalTemplate.Type = ItemJournalTemplate.Type::"Phys. Inventory") and (Rec.GetFilter("Journal Template Name") = MobSetup."Inventory Jnl Template");
    end;

    trigger OnOpenPage()
    begin
        MOBCheckItemJournalMobSetup();
    end;
}
