page 81361 "MOB Purchase Guide"
{
    Caption = 'Mobile WMS Purchase Guide';
    PageType = NavigatePage;
    UsageCategory = Administration;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(GraphicsWelcome)
            {
                Editable = false;
                Visible = (CurrentStep = 0);
                ShowCaption = false;
                field(MediaRepositoryWelcomeField; MediaRepositoryWelcome.Image)
                {
                    ToolTip = 'Image displayed at the Purchase Guide welcome page.', Locked = true;
                    ApplicationArea = All;
                    ShowCaption = false;
                }
            }
            group(GraphicsHardware)
            {
                Editable = false;
                Visible = (CurrentStep = 1);
                ShowCaption = false;
                field(MediaRepositoryHardwareField; MediaRepositoryHardware.Image)
                {
                    ToolTip = 'Hardware image displayed at the Purchase Guide welcome page.', Locked = true;
                    ApplicationArea = All;
                    ShowCaption = false;
                }
            }
            group("00Welcome")
            {
                Visible = CurrentStep = 0;
                ShowCaption = false;
                group("You have succesfully installed Mobile WMS")
                {
                    Caption = 'You have succesfully installed Mobile WMS', Locked = true;
                }

                group("Important:")
                {
                    Caption = 'Important:', Locked = true;
                    InstructionalText = 'Mobile WMS requires an active subscription with Tasklet Factory to operate and a mobile scanning device.';
                }
                group("Interested in efficient warehouse management ?")
                {
                    Caption = 'Interested in efficient warehouse management?', Locked = true;
                    InstructionalText = 'On the next page you will be able to contact us.';
                }

                field(DoNotShowGuide; MobSetup.Guide1DoNotShow)
                {
                    Caption = 'Don''t show this guide again';
                    ToolTip = 'Prevent the Purchase Guide from displaying at the main menu next time you start Business Central.';
                    ApplicationArea = All;
                }
            }
            group(ContactTaskletFactory)
            {
                Visible = CurrentStep = 1;
                ShowCaption = false;

                group("Procure Hardware")
                {
                    Caption = 'Procure Hardware', Locked = true;
                    InstructionalText = 'Review our supported hardware here:';
                    field(Procure; TFHardwareURI_Txt)
                    {
                        Caption = 'Procure Hardware';
                        ToolTip = 'Review our supported hardware. Subject to change - you can always get current information at www.taskletfactory.com or sales(at)taskletfactory.com';
                        ApplicationArea = All;
                        ExtendedDatatype = URL;
                        ShowCaption = false;
                    }
                }
                group("Contact Tasklet Factory")
                {
                    Caption = 'Contact Tasklet Factory', Locked = true;
                    InstructionalText = 'Please contact us to learn more.';
                    field(SalesEmailAdresse; TFSalesEmail_Txt)
                    {
                        Caption = 'Contact Tasklet Factory';
                        ToolTip = 'Email address of our sales department.';
                        ApplicationArea = All;
                        ExtendedDatatype = EMail;
                        ShowCaption = false;
                    }
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(ActionBack)
            {
                ApplicationArea = All;
                Enabled = ActionBackAllowed;
                Image = PreviousRecord;
                InFooterBar = true;
                Caption = 'Back';
                ToolTip = 'Back to previous page.';
                trigger OnAction()
                begin
                    TaskStep(-1);
                end;
            }
            action(ActionNext)
            {
                Caption = 'Next';
                ToolTip = 'Forward to next page.';
                ApplicationArea = All;
                Enabled = ActionNextAllowed;
                Visible = ActionNextAllowed;
                Image = NextRecord;
                InFooterBar = true;
                trigger OnAction()
                begin
                    TaskStep(1);
                    if not MobSetup.Modify() then; // Early save attempt - changes persisted in OnClosePage regardless
                end;
            }
            action(ActionFinish)
            {
                Caption = 'Finish';
                ToolTip = 'Finish the Purhase Guide.';
                ApplicationArea = All;
                Enabled = ActionFinishAllowed;
                Visible = ActionFinishAllowed;
                Image = Approve;
                InFooterBar = true;
                trigger OnAction()
                begin
                    CurrPage.Close();
                end;
            }

        }
    }
    var
        MobSetup: Record "MOB Setup";
        MediaRepositoryWelcome: Record "Media Repository";
        MediaRepositoryHardware: Record "Media Repository";
        Customer: Record Customer;
        CurrentStep: Integer;
        ActionBackAllowed: Boolean;
        ActionNextAllowed: Boolean;
        ActionFinishAllowed: Boolean;
        TFHardwareURI_Txt: Label 'https://taskletfactory.com/hardware/mobile-computers/', Locked = true;
        TFSalesEmail_Txt: Label 'sales(at)taskletfactory.com', Locked = true;

    trigger OnOpenPage()
    begin
        // Get or Init source record
        if not MobSetup.Get() then begin
            MobSetup.Init();
            MobSetup.Insert(true);
        end;

        // Init number of devices
        Customer.Priority := 10;

        UpdateControls();
    end;

    trigger OnInit()
    begin
        LoadTopBanners();
    end;

    trigger OnClosePage()
    begin
        // Save steps to record
        MobSetup.Modify();
    end;

    local procedure UpdateControls()
    begin
        ActionBackAllowed := CurrentStep > 0;
        ActionNextAllowed := CurrentStep < 1;
        ActionFinishAllowed := CurrentStep = 1;
    end;

    local procedure TaskStep(_Step: Integer)
    begin
        CurrentStep += _Step;
        UpdateControls();
    end;

    local procedure LoadTopBanners()
    var
        MobBase64Convert: Codeunit "MOB Base64 Convert";
        MobGUIHelper: Codeunit "MOB GUI Helper";
        iStream: InStream;
    begin
        // Import BASE64 image        
        MobBase64Convert.FromBase64(MobGUIHelper.GetWelcomeBannerAsBase64String(), iStream);
        MediaRepositoryWelcome.Image.ImportStream(iStream, '');

        MobBase64Convert.FromBase64(MobGUIHelper.GetHardwareBannerAsBase64String(), iStream);
        MediaRepositoryHardware.Image.ImportStream(iStream, '');
    end;


}
