page 81310 "MOB Tweak List"
{
    Caption = 'Mobile Tweak List', Locked = true;
    PromotedActionCategories = 'New,Process,Report,Tweak', Locked = true; // Only Tweak is used and shouldn't be translated
    PageType = List;
    SourceTable = "MOB Tweak Buffer";
    SourceTableTemporary = true;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("File Name"; Rec."File Name")
                {
                    ApplicationArea = All;
                    Visible = false;
                    ToolTip = 'Specifies the file name of the tweak on the mobile device, which determins the sort order of the tweaks.', Locked = true;
                }
                field("Sorting Id"; Rec."Sorting Id")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the sorting id of the tweak.', Locked = true;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description of the tweak.', Locked = true;
                }
                field("Source Name"; Rec."Source Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the extension adding the tweak.', Locked = true;
                }
                field("Source Version"; Rec."Source Version")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the version of the extension adding the tweak.', Locked = true;
                }
                field("Source Publisher"; Rec."Source Publisher")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the publisher of the extension adding the tweak.', Locked = true;
                }
            }
            group(TweakContent)
            {
                Caption = 'Content', Locked = true;

                /* #if BC24+ */
                usercontrol(TweakContentControl; WebPageViewer)
                /* #endif */
                /* #if BC23- ##
                usercontrol(TweakContentControl; "Microsoft.Dynamics.Nav.Client.WebPageViewer")
                /* #endif */
                {
                    ApplicationArea = All;

                    trigger ControlAddInReady(callbackUrl: Text)
                    begin
                        TweakContentAddInReady := true;
                        FillTweakContentHtmlViewerAddIn();
                    end;
                }
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            group(Tweak)
            {
                Caption = '&Tweak', Locked = true;
                action("Show &Tweak XML")
                {
                    Caption = 'Show &Tweak XML', Locked = true;
                    ToolTip = 'Open this current Tweak XML in a new window.', Locked = true;
                    ApplicationArea = All;
                    Image = ElectronicDoc;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;

                    trigger OnAction()
                    begin
                        Rec.ShowXmlContent();
                    end;
                }
            }
        }
    }

    var
        TweakContentAddInReady: Boolean;

    trigger OnOpenPage()
    begin
        Rec.LoadTweaks();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        if TweakContentAddInReady then
            FillTweakContentHtmlViewerAddIn();
    end;

    local procedure FillTweakContentHtmlViewerAddIn()
    var
        HtmlMgt: Codeunit "MOB HTML Management";
        InStr: InStream;
        Content: Text;
    begin
        Rec.CalcFields(Content);
        Rec.Content.CreateInStream(InStr);
        InStr.Read(Content);

        CurrPage.TweakContentControl.SetContent(HtmlMgt.CreateHtmlWithTextArea(Content));
    end;
}
