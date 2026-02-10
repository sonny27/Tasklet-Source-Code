page 81271 "MOB Languages"
{
    Caption = 'Mobile Languages';
    AdditionalSearchTerms = 'Mobile Languages Tasklet Configuration Device Scanner', Locked = true;
    PageType = List;
    SourceTable = "MOB Language";
    UsageCategory = Administration;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                field("Code"; Rec.Code)
                {
                    ToolTip = 'Specifies the language code to use when sending mobile messages from the backend to the mobile device.';
                    ApplicationArea = All;
                }
                field(Name; Rec.Name)
                {
                    ToolTip = 'Specifies the name of the language.';
                    ApplicationArea = All;
                }
                field(Messages; Rec.Messages)
                {
                    ToolTip = 'Specifies if Mobile Messages has been created for the language.';
                    ApplicationArea = All;
                }
                field("Device Language Code"; Rec."Device Language Code")
                {
                    ToolTip = 'The device language code is used by mobile device to generate the front-end of the application. For each language code a Device Language Code can be specified.';
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            group(ActionGroup7)
            {
                Caption = 'Messages';
                action(CreateLanguages)
                {
                    Caption = 'Create Languages';
                    ToolTip = 'Create default language codes and messages.';
                    ApplicationArea = All;
                    Image = CreateDocuments;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;

                    trigger OnAction()
                    var
                        MOBLanguage: Codeunit "MOB WMS Language";
                    begin
                        MOBLanguage.SetupDefaultLanguages();
                    end;
                }
                action(EditMessages)
                {
                    Caption = 'Messages';
                    ToolTip = 'Display all Messages for the current Mobile Language.';
                    ApplicationArea = All;
                    Image = List;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    RunObject = page "MOB Messages";
                    RunPageLink = "Language Code" = field(filter(Code));
                }
            }
        }
    }
}

