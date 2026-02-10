pageextension 81404 "MOB Phys. Inventory Journal" extends "Phys. Inventory Journal"
{
    layout
    {
        addafter(CurrentJnlBatchName)
        {
            field(MOBReleasedToMobileField; MOBReleasedToMobile())
            {
                Caption = 'Released To Mobile';
                ToolTip = 'Is the Item Journal Batch visible at the Mobile Device.';
                ApplicationArea = All;
            }
        }
        addafter(Description)
        {
            field(MOBRegisteredOnMobileField; Rec.MOBRegisteredOnMobile)
            {
                Caption = 'Registered On Mobile';
                ToolTip = 'Has anything been registered against this exact Physical Inventory Journal Line from the Mobile Device.';
                ApplicationArea = All;
            }
        }
    }
    actions
    {
        addlast(processing)
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
                trigger OnAction()
                var
                    ItemJnlBatch: Record "Item Journal Batch";
                begin
                    ItemJnlBatch.Get(Rec."Journal Template Name", Rec."Journal Batch Name");
                    ItemJnlBatch.MOBReleasedToMobile := not ItemJnlBatch.MOBReleasedToMobile;
                    ItemJnlBatch.Modify(true);
                end;
            }
        }
    }
    local procedure MOBReleasedToMobile(): Boolean
    var
        ItemJnlBatch: Record "Item Journal Batch";
    begin
        ItemJnlBatch.Get(Rec."Journal Template Name", Rec."Journal Batch Name");
        exit(ItemJnlBatch.MOBReleasedToMobile);
    end;
}
