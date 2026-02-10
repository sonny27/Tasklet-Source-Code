page 81280 "MOB Messages"
{
    Caption = 'Mobile Messages';
    AdditionalSearchTerms = 'Mobile Messages Tasklet Configuration Device Scanner', Locked = true;
    PageType = List;
    SourceTable = "MOB Message";
    UsageCategory = Administration;
    ApplicationArea = All;
    DelayedInsert = true; // Nessesary to allow Create Message from an empty list (Otherwise BC tries to insert the rec but failes becasue the Code field is empty but mandatory)

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                field("Language Code"; Rec."Language Code")
                {
                    ToolTip = 'The Language Code this translation at Mobile Device is for.';
                    ApplicationArea = All;
                }
                field("Code"; Rec.Code)
                {
                    ToolTip = '(Internal) Code used by the Mobile WMS Extension to lookup translations for texts to be displayed at the Mobile Device.';
                    ApplicationArea = All;
                }
                field(Message; Rec.Message)
                {
                    ToolTip = 'The translated message to be displayed at the Mobile Device.';
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            group(ActionGroup6)
            {
                Caption = 'Process', Locked = true;
                action(CreateMessages)
                {
                    Caption = 'Create Messages';
                    ApplicationArea = All;
                    ToolTip = 'Create missing messages for current language with fallback to "ENU" if local message does not exist.';
                    Image = CreateDocuments;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;

                    trigger OnAction()
                    var
                        MOBWMSLanguageModule: Codeunit "MOB WMS Language";
                    begin
                        MOBWMSLanguageModule.SetupLanguageMessages(Rec."Language Code");
                    end;
                }

            }
        }
    }
}

