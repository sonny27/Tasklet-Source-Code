pageextension 81406 "MOB Whse. Phys. Invt. Journal" extends "Whse. Phys. Invt. Journal"
{


    layout
    {
        addafter(CurrentLocationCode)
        {
            field(MOBReleasedToMobileField; MOBReleasedToMobile())
            {
                Caption = 'Released To Mobile';
                ToolTip = 'Is the Warehouse Journal Batch visible at the Mobile Device.';
                ApplicationArea = All;
            }
        }
        addafter(Description)
        {
            field(MOBRegisteredOnMobile; Rec.MOBRegisteredOnMobile)
            {
                Caption = 'Registered On Mobile';
                ToolTip = 'Has anything been registered against this exact Warehouse Physical Inventory Journal Line from the Mobile Device.';
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
                ToolTip = 'Toggle making this Warehouse Journal Batch visible at the Mobile Device.';
                ApplicationArea = All;
                Image = ReleaseDoc;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                trigger OnAction()
                var
                    WhseJnlBatch: Record "Warehouse Journal Batch";
                begin
                    WhseJnlBatch.Get(Rec."Journal Template Name", Rec."Journal Batch Name", Rec."Location Code");
                    WhseJnlBatch.MOBReleasedToMobile := not WhseJnlBatch.MOBReleasedToMobile;
                    WhseJnlBatch.Modify(true);
                end;
            }
        }
    }
    local procedure MOBReleasedToMobile(): Boolean
    var
        WhseJnlBatch: Record "Warehouse Journal Batch";
    begin
        WhseJnlBatch.Get(Rec."Journal Template Name", Rec."Journal Batch Name", Rec."Location Code");
        exit(WhseJnlBatch.MOBReleasedToMobile);
    end;
}
