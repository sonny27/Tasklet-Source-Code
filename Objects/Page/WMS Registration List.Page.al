page 81277 "MOB WMS Registration List"
{
    Caption = 'Mobile WMS Registration List';
    AdditionalSearchTerms = 'Mobile WMS Registration List Tasklet Log', Locked = true;
    ApplicationArea = All;
    Editable = false;
    PageType = List;
    SourceTable = "MOB WMS Registration";
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Posting MessageId"; Rec."Posting MessageId")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Posting MessageId field.';
                    Visible = false;
                }
                field("Type"; Rec."Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Type field.';
                }
                field("Order No."; Rec."Order No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Order No. field.';
                    TableRelation =
            if (Type = const(Receive)) "Posted Whse. Receipt Header"."Whse. Receipt No."
                    else
                    if (Type = const(Pick)) "Registered Whse. Activity Hdr."."Whse. Activity No."
                    else
                    if (Type = const(Ship)) "Posted Whse. Shipment Header"."Whse. Shipment No."
                    else
                    if (Type = const(Move)) "Warehouse Activity Header"."No."
                    else
                    if (Type = const("Sales Order")) "Sales Header"."No." where("Document Type" = const(Order))
                    else
                    if (Type = const("Purchase Order")) "Purchase Header"."No." where("Document Type" = const(Order))
                    else
                    if (Type = const("Transfer Order")) "Transfer Receipt Header"."Transfer Order No."
                    else
                    if (Type = const("Sales Return Order")) "Return Receipt Header"."Return Order No."
                    else
                    if (Type = const("Purchase Return Order")) "Return Receipt Header"."Return Order No."
                    else
                    if (Type = const("Phys. Invt. Recording")) "Phys. Invt. Record Header"."Order No."
                    else
                    if (Type = const("Production Consumption")) "Production Order"."No."
                    else
                    if (Type = const("Assembly Order")) "Posted Assembly Header"."Order No.";
                }
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Line No. field.';
                }
                field("Registration No."; Rec."Registration No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Registration No. field.';
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Location Code field.';
                    TableRelation = Location;
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Item No. field.';
                    TableRelation = Item;

                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Variant Code field.';
                }

                field(FromBin; Rec.FromBin)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the FromBin field.';
                }
                field(ToBin; Rec.ToBin)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the ToBin field.';
                }
                field(SerialNumber; Rec.SerialNumber)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the SerialNumber field.';
                }
                field(LotNumber; Rec.LotNumber)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the LotNumber field.';
                }
                field(PackageNumber; Rec.PackageNumber)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the PackageNumber field.';
                    Visible = PackageEnabled;
                    Enabled = PackageEnabled;
                }
                field("Expiration Date"; Rec."Expiration Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Expiration Date field.';
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Quantity field.';
                }
                field(UnitOfMeasure; Rec.UnitOfMeasure)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the UnitOfMeasure field.';
                }
                field(Handled; Rec.Handled)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Handled field.';
                }
                field(ActionType; Rec.ActionType)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the ActionType field.';
                }
                field("Tote ID"; Rec."Tote ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Tote ID field.';
                }
                field("Tote Handled"; Rec."Tote Handled")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Tote Handled field.';
                }
                field("From License Plate"; Rec."From License Plate No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the From License Plate No. field.';
                }
                field("License Plate No."; Rec."License Plate No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the To License Plate No. field.';
                }
                field("Transferred to License Plate"; Rec."Transferred to License Plate")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies if the entry has been transferred to License Plate';
                }
                field("Transferred From License Plate"; Rec."Transferred From License Plate")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies if the entry has been transferred from License Plate';
                }
                field("Whse. Document Type"; Rec."Whse. Document Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Whse. Document Type field.';
                }
                field("Whse. Document No."; Rec."Whse. Document No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Whse. Document No. field.';
                }
                field("Whse. Document Line No."; Rec."Whse. Document Line No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Whse. Document Line No. field.';
                }

                field("Source Type"; Rec."Source Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Source Type field.';
                }
                field("Source No."; Rec."Source No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Source No. field.';
                }
                field("Source Document"; Rec."Source Document")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Source Document field.';
                }
                field("Source Line No."; Rec."Source Line No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Source Line No. field.';
                }
                field("Source MOBSystemId"; Rec."Source MOBSystemId")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Source MOBSystemId field.';
                }
                field("Prod. Order Line No."; Rec."Prod. Order Line No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Prod. Order Line No. field.';
                }

                field("Destination Type"; Rec."Destination Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Destination Type field.';
                }
                field("Destination No."; Rec."Destination No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Destination No. field.';
                }

                field("Whse. Shpmt. Exists"; Rec."Whse. Shpmt. Exists")
                {
                    ApplicationArea = All;
                    ToolTip = 'Shows if the associated Warehouse Shipment Line exists.';
                }
                field("AtO Tracking Collected"; Rec."AtO Tracking Collected")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the AtO Tracking Collected field.';
                }
                field("Phys. Invt. Recording No."; Rec."Phys. Invt. Recording No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Phys. Invt. Recording No. field.';
                }
                field("Whse. Jnl. Batch Location Code"; Rec."Whse. Jnl. Batch Location Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Whse. Jnl. Batch Location Code field.';
                }
                field("Prefixed Line No."; Rec."Prefixed Line No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Prefixed Line No. field.';
                }
                field(RegistrationCreated; Rec.RegistrationCreated)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the date and time of the creation of the registration on the handheld device shown in the current time zone.';
                }
                field(LineSelectionValue; Rec.LineSelectionValue)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the LineSelectionValue field.';
                }
                field(ExtraInfo; Rec.ExtraInfo)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the ExtraInfo field.';
                }
            }
            group(RegistrationXml)
            {
                Caption = 'Registration XML';

                /* #if BC24+ */
                usercontrol(RequestControl; WebPageViewer)
                /* #endif */
                /* #if BC23- ##
                usercontrol(RequestControl; "Microsoft.Dynamics.Nav.Client.WebPageViewer")
                /* #endif */
                {
                    ApplicationArea = All;

                    trigger ControlAddInReady(callbackUrl: Text)
                    begin
                        RequestAddInReady := true;
                        FillHtmlViewerAddIn();
                    end;
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        MobPackageMgt: Codeunit "MOB Package Management";
    begin
        PackageEnabled := MobPackageMgt.IsEnabled();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        if RequestAddInReady then
            FillHtmlViewerAddIn();
    end;

    var
        RequestAddInReady: Boolean;
        PackageEnabled: Boolean;

    local procedure FillHtmlViewerAddIn()
    var
        HtmlMgt: Codeunit "MOB HTML Management";
    begin
        CurrPage.RequestControl.SetContent(HtmlMgt.CreateHtmlWithTextArea(Rec.GetRegistrationXmlAsText()));
    end;

}
