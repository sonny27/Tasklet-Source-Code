page 81374 "MOB RealTime Reg Qty"
{
    Caption = 'Mobile Realtime Registration List';
    AdditionalSearchTerms = 'Mobile Realtime Registration List Tasklet Log', Locked = true;
    ApplicationArea = All;
    PageType = List;
    SourceTable = "MOB Realtime Reg Qty.";
    UsageCategory = Administration;
    InsertAllowed = false;
    ModifyAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Device ID"; Rec."Device ID")
                {
                    ToolTip = '(Mobile) Device ID the request was received from.';
                    ApplicationArea = All;
                }
                field("Type"; Rec.Type)
                {
                    ToolTip = 'The Document Type from the Request XML.';
                    ApplicationArea = All;
                }
                field("Order No."; Rec."Order No.")
                {
                    ToolTip = 'Specifies the number of the involved document.';
                    ApplicationArea = All;
                }
                field("Line No."; Rec."Line No.")
                {
                    ToolTip = 'Specifies the Line Number on the involved document.';
                    ApplicationArea = All;
                }
                field("Registration No."; Rec."Registration No.")
                {
                    ToolTip = 'The Registration Number of the record.';
                    ApplicationArea = All;
                }
                field("Item No."; Rec."Item No.")
                {
                    ToolTip = 'Specifies the value of the Item Number field.';
                    ApplicationArea = All;
                }
                field(FromBin; Rec.FromBin)
                {
                    ToolTip = 'Specifies the value of the FromBin field.';
                    ApplicationArea = All;
                }
                field(ToBin; Rec.ToBin)
                {
                    ToolTip = 'Specifies the value of the ToBin field.';
                    ApplicationArea = All;
                }
                field(SerialNumber; Rec."Serial No.")
                {
                    ToolTip = 'Specifies the value of the SerialNumber field.';
                    ApplicationArea = All;
                }
                field(LotNumber; Rec."Lot No.")
                {
                    ToolTip = 'Specifies the value of the LotNumber field.';
                    ApplicationArea = All;
                }
                field(ExpirationDate; Rec."Expiration Date")
                {
                    ToolTip = 'Specifies the value of the Expiration Date field.';
                    ApplicationArea = All;
                }
                field(PackageNumber; Rec.PackageNumber)
                {
                    ToolTip = 'Specifies the value of the PackageNumber field.';
                    ApplicationArea = All;
                    Visible = PackageEnabled;
                    Enabled = PackageEnabled;
                }
                field(Quantity; Rec.Quantity)
                {
                    ToolTip = 'Specifies the value of the Quantity field.';
                    ApplicationArea = All;
                }
                field(UnitOfMeasure; Rec.UnitOfMeasure)
                {
                    ToolTip = 'Specifies the value of the UnitOfMeasure field.';
                    ApplicationArea = All;
                }
                field(ActionType; Rec.ActionType)
                {
                    ToolTip = 'Specifies the value of the Action Type field.';
                    ApplicationArea = All;
                }
                field("Mobile User ID"; Rec."Mobile User ID")
                {
                    ToolTip = 'The Mobile User ID the request was received from.';
                    ApplicationArea = All;
                }
                field("Tote ID"; Rec."Tote ID")
                {
                    ToolTip = 'Specifies the value of the Tote ID field.';
                    ApplicationArea = All;
                }
                field("Registration XML"; Rec."Registration XML")
                {
                    ToolTip = 'Specifies the value of the Registration XML field.';
                    ApplicationArea = All;
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
