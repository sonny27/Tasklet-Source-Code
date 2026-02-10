page 81287 "MOB PrintNode Setup"
{
    /* #if BC16+ */
    ApplicationArea = All;
    UsageCategory = Administration;
    /* #endif */
    Caption = 'Tasklet PrintNode Setup', Locked = true;
    AdditionalSearchTerms = 'Tasklet PrintNode Setup Configuration', Locked = true;
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    SourceTable = "MOB PrintNode Setup";
    HelpLink = 'https://taskletfactory.atlassian.net/wiki/spaces/TFSK/pages/78950705/Set+up+Tasklet+PrintNode';

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General', Locked = true;
                ;

                field("PrintNode Enabled"; Rec.Enabled)
                {
                    ApplicationArea = All;
                    ToolTip = 'Enable PrintNode functionality', Locked = true;
                }

                field("API Key"; ApiKey)
                {
                    ApplicationArea = All;
                    Caption = 'API Key', Locked = true;
                    ExtendedDatatype = Masked;
                    ToolTip = 'Specifies the PrintNode API Key. You will need to create a PrintNode account and create an API Key at PrintNode.com before inserting it here.', Locked = true;
                    Editable = PageIsEditable; // Page controls not linked to the source table does not automatically follow the Editable status of the page

                    trigger OnValidate()
                    var
                        MobPrintNodeMgt: Codeunit "MOB PrintNode Mgt.";
                    begin
                        Rec.SetPrintNodeAPIKey(ApiKey);
                        Rec.Modify(false);

                        if ApiKey <> '' then
                            MobPrintNodeMgt.CheckConnection(); // Validate the API Key
                    end;
                }

                field("API Record Limit"; Rec."API Record Limit")
                {
                    ApplicationArea = All;
                    ToolTip = 'Sets the maximum number of printers to retrieve from the PrintNode API. A value of 0 (zero) applies the default limit of 1000 printers.', Locked = true;
                    Visible = false;
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(Printers)
            {
                Caption = 'Printer Management', Locked = true;
                ToolTip = 'Exposes the list of added PrintNode printers.', Locked = true;
                ApplicationArea = All;
                Image = Print;
                PromotedCategory = Process;
                Promoted = true;
                PromotedIsBig = true;
                RunObject = page "MOB PrintNode Printer Mgt.";
            }
            action(OpenPrintNodeCom)
            {
                ApplicationArea = All;
                Caption = 'PrintNode.com', Locked = true;
                ToolTip = 'Opens PrintNode.com where you can set up a user and get an API key.', Locked = true;
                Image = Open;
                Promoted = true;
                PromotedIsBig = true;
                PromotedOnly = true;
                PromotedCategory = Process;
                trigger OnAction()
                begin
                    Hyperlink('https://printnode.com');
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;

        if not Rec.Enabled then
            MobFeatureTelemetryWrapper.LogUptakeDiscovered(MobTelemetryEventId::"Tasklet PrintNode Feature (MOB1030)");
    end;

    trigger OnAfterGetRecord()
    begin
        PageIsEditable := CurrPage.Editable();

        // Assign a value to the global variable to show ****
        if not IsNullGuid(Rec."API Isolated Storage Key") then
            ApiKey := 'Some dummy value to indicate the masked field got a value';
    end;

    var
        MobFeatureTelemetryWrapper: Codeunit "MOB Feature Telemetry Wrapper";
        MobTelemetryEventId: Enum "MOB Telemetry Event ID";
        ApiKey: Text;
        PageIsEditable: Boolean;
}
