pageextension 81407 "MOB Whse. Journal Batches List" extends "Whse. Journal Batches List"
{


    layout
    {
        addlast(Control1)
        {
            field(MOBReleasedToMobile; Rec.MOBReleasedToMobile)
            {
                Caption = 'Released To Mobile';
                ToolTip = 'Is the Warehouse Journal Batch visible at the Mobile Device.';
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
                ToolTip = 'Toggle making this Warehouse Journal Batch visible at the Mobile Device.';
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
    local procedure MOBCheckWhseJournalTemplateMobSetup()
    var
        MobSetup: Record "MOB Setup";
        WhseJournalTemplate: Record "Warehouse Journal Template";
    begin
        if Rec.GetFilter("Journal Template Name") = '' then
            exit;
        // For versions prior to BC21: check if user has permissions to MobSetup to avoid error
        if not MobSetup.ReadPermission() then
            exit;
        if not MobSetup.Get() then
            exit;
        // Template must be = Phys. Inventory and Page filter must = MobSetup 
        if WhseJournalTemplate.Get(Rec.GetFilter("Journal Template Name")) then
            TemplateIsMobSetup := (WhseJournalTemplate.Type = WhseJournalTemplate.Type::"Physical Inventory") and (Rec.GetFilter("Journal Template Name") = MobSetup."Whse Inventory Jnl Template");
    end;

    trigger OnOpenPage()
    begin
        MOBCheckWhseJournalTemplateMobSetup();
    end;
}
