page 81367 "MOB Print Log"
{
    Caption = 'Mobile Print Log';
    AdditionalSearchTerms = 'Mobile Print Log Tasklet', Locked = true;
    Editable = false;
    SaveValues = true;
    PageType = List;
    SourceTable = "MOB Print Log";
    UsageCategory = Administration;
    ApplicationArea = All;
    PromotedActionCategories = 'New,Process,Report,Log';
    SourceTableView = sorting("Entry No.") order(descending);

    layout
    {
        area(Content)
        {
            repeater(Control1000000000)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ToolTip = 'Entry No.';
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Message ID"; Rec."Message ID")
                {
                    ToolTip = 'A unique Message ID associated with each Document Queue entry.';
                    ApplicationArea = All;
                }
                field("Device ID"; Rec."Device ID")
                {
                    ToolTip = 'Device ID.';
                    ApplicationArea = All;
                }
                field("Mobile User ID"; Rec."Mobile User ID")
                {
                    ToolTip = 'The Mobile User ID the request was received from.';
                    ApplicationArea = All;
                }
                field("Label-Template Name"; Rec."Label-Template Name")
                {
                    ToolTip = 'Label-Template Name.';
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
                {
                    ToolTip = 'Description.';
                    ApplicationArea = All;
                }
                field("Created Date/Time"; Rec."Created Date/Time")
                {
                    ToolTip = 'Created Date/Time.';
                    ApplicationArea = All;
                }
                field("Record ID"; Rec."Record ID")
                {
                    ToolTip = 'The record the print is based upon.';
                    ApplicationArea = All;
                    Visible = false;
                }
            }
            group(RequestDoc)
            {
                Caption = 'Cloud &Request XML';

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
        area(FactBoxes)
        {
        }
    }

    actions
    {
        area(Navigation)
        {
            group(Log)
            {
                Caption = '&Log';
                action("Show Request &DataSet")
                {
                    Caption = 'Show Internal &DataSet';
                    ToolTip = 'View the internal DataSet, which is customizable and created before the final request to Cloud print service.';
                    ApplicationArea = All;
                    Image = ElectronicDoc;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    trigger OnAction()
                    begin
                        Rec.ShowRequestDataSet();
                    end;
                }
                action("Show Cloud &Request")
                {
                    Caption = 'Show Cloud &Request';
                    ToolTip = 'View the final XML request data sent to Cloud print service.';
                    ApplicationArea = All;
                    Image = ElectronicDoc;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    trigger OnAction()
                    begin
                        Rec.ShowRequestData();
                    end;
                }
                action("Show Cloud &Response")
                {
                    Caption = 'Show Cloud &Response';
                    ToolTip = 'View the response received from Cloud print service.';
                    ApplicationArea = All;
                    Image = ElectronicDoc;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    trigger OnAction()
                    begin
                        Rec.ShowResponseData();
                    end;
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        if RequestAddInReady then
            FillHtmlViewerAddIn();
    end;

    local procedure FillHtmlViewerAddIn()
    var
        HtmlMgt: Codeunit "MOB HTML Management";
    begin
        CurrPage.RequestControl.SetContent(HtmlMgt.CreateHtmlWithTextArea(Rec.GetRequestXMLAsText()));
    end;

    var
        RequestAddInReady: Boolean;
}

