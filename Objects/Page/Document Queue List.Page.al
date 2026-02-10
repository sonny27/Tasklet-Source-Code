page 81279 "MOB Document Queue List"
{
    Caption = 'Mobile Document Queue List';
    AdditionalSearchTerms = 'Mobile Document Queue List Tasklet Log', Locked = true;
    PageType = List;
    PromotedActionCategories = 'New,Process,Report,Document,Troubleshooting';
    SaveValues = true;
    SourceTable = "MOB Document Queue";
    SourceTableView = sorting("Created Date/Time", Status, "Document Type", "Mobile User ID")
                      order(descending);
    UsageCategory = Administration;
    ApplicationArea = All;

    // Cannot use Editable = false on the page as that locks the filter controls too
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            grid(Grid01)
            {
                group("Filter")
                {
                    Caption = 'Filter';
                    field(ShowAllCheckBox; ShowAll)
                    {
                        Caption = 'Show All';
                        ToolTip = 'Remove all current filters and display all Queue entries.';
                        Editable = ShowAllCheckBoxEditable;
                        ApplicationArea = All;

                        trigger OnValidate()
                        begin
                            ShowAllOnAfterValidate();
                        end;
                    }
                    field(FilterMobileUserField; FilterMobileUser)
                    {
                        Caption = 'Mobile User Filter';
                        ToolTip = 'Filter queue entries to entries from a specific Mobile User.';
                        ApplicationArea = All;

                        trigger OnLookup(var Text: Text): Boolean
                        var
                            MobileUsers: Page "MOB Users";
                        begin
                            MobileUsers.LookupMode(true);
                            if not (MobileUsers.RunModal() = Action::LookupOK) then
                                exit(false)
                            else
                                Text := MobileUsers.GetSelectionFilter();
                            exit(true);
                        end;

                        trigger OnValidate()
                        begin
                            FilterMobileUserOnAfterValidat();
                        end;
                    }
                    field(FilterDocumentTypeField; FilterDocumentType)
                    {
                        Caption = 'Document Type Filter';
                        ToolTip = 'Filter queue entries to entries for a specific Document Type.';
                        ApplicationArea = All;

                        trigger OnLookup(var Text: Text): Boolean
                        var
                            MobDocTypes: Page "MOB Document Types";
                        begin
                            MobDocTypes.LookupMode(true);
                            if not (MobDocTypes.RunModal() = Action::LookupOK) then
                                exit(false)
                            else
                                Text := MobDocTypes.GetSelectionFilter();
                            exit(true);
                        end;

                        trigger OnValidate()
                        begin
                            FilterDocumentTypeOnAfterValid();
                        end;
                    }
                }
                group(StatusFilter)
                {
                    Caption = '', Locked = true;  // Without the Caption property the group name would be shown
                    field(ShowNewCheckBox; ShowNew)
                    {
                        Caption = 'New';
                        ToolTip = 'Filter queue entries to (unprocessed) entries with status New.';
                        ApplicationArea = All;

                        trigger OnValidate()
                        begin
                            ShowNewOnAfterValidate();
                        end;
                    }
                    field(ShowProcessingCheckBox; ShowProcessing)
                    {
                        Caption = 'Processing';
                        ToolTip = 'Filter queue entries to entries currently being processed (Status = Processing).';
                        ApplicationArea = All;

                        trigger OnValidate()
                        begin
                            ShowProcessingOnAfterValidate();
                        end;
                    }
                    field(ShowCompletedCheckBox; ShowCompleted)
                    {
                        Caption = 'Completed';
                        ToolTip = 'Display completed queue entries only.';
                        ApplicationArea = All;

                        trigger OnValidate()
                        begin
                            ShowCompletedOnAfterValidate();
                        end;
                    }
                    field(ShowerrorCheckBox; Showerror)
                    {
                        Caption = 'Error';
                        ToolTip = 'Display queue entries that failed during processing.';
                        ApplicationArea = All;

                        trigger OnValidate()
                        begin
                            ShowerrorOnAfterValidate();
                        end;
                    }
                }
            }
            repeater(Control1)
            {
                Editable = false;
                field("Created Date/Time"; Rec."Created Date/Time")
                {
                    ToolTip = 'Date/Time this current request was inserted into the Mobile Document Queue.';
                    ApplicationArea = All;
                }
                field("Mobile User ID"; Rec."Mobile User ID")
                {
                    ToolTip = 'The Mobile User ID the request was received from. This will be the user ID used during login at the Mobile Device.';
                    ApplicationArea = All;
                }
                field("Document Type"; Rec."Document Type")
                {
                    ToolTip = 'The request Document Type being processed.';
                    ApplicationArea = All;
                }
                field("Registration Type"; Rec."Registration Type")
                {
                    ToolTip = 'The request Registration Type being processed.';
                    ApplicationArea = All;
                }
                field("Print Log"; Rec."Print Log")
                {
                    Caption = 'Print Log';
                    ToolTip = 'Find Print Log entries related this current Mobile Document Queue entry.';
                    ApplicationArea = All;
                }
                field(Status; Rec.Status)
                {
                    ToolTip = 'Processing status for this current Mobile Document Queue entry.';
                    ApplicationArea = All;
                }
                field("Answer Date/Time"; Rec."Answer Date/Time")
                {
                    ToolTip = 'Date/Time a response to this request was created by the Mobile WMS backend.';
                    ApplicationArea = All;
                    Visible = false;
                }
                field(DurationsField; Rec."Processing Duration") // Keeping control name for compatibility with previous versions 
                {
                    ToolTip = 'Duration (time) to process this current Mobile Document Queue entry.';
                    ApplicationArea = All;
                }
                field("Device ID"; Rec."Device ID")
                {
                    ToolTip = '(Mobile) Device ID the request was received from.';
                    ApplicationArea = All;
                }
                field("Message ID"; Rec."Message ID") // PK placed last - like Entry lists
                {
                    ToolTip = 'A unique Message ID associated with each Document Queue entry.';
                    ApplicationArea = All;

                }
            }
            group(RequestDoc)
            {
                Caption = 'Request XML';

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
                        FillRequestHtmlViewerAddIn();
                    end;
                }
            }
            group(ResponseDoc)
            {
                Caption = 'Response XML';

                /* #if BC24+ */
                usercontrol(ResponseControl; WebPageViewer)
                /* #endif */
                /* #if BC23- ##
                usercontrol(ResponseControl; "Microsoft.Dynamics.Nav.Client.WebPageViewer")
                /* #endif */
                {
                    ApplicationArea = All;

                    trigger ControlAddInReady(callbackUrl: Text)
                    begin
                        ResponseAddInReady := true;
                        FillResponseHtmlViewerAddIn();
                    end;
                }
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            group(Request)
            {
                Caption = '&Document';
                action("Show &Request XML")
                {
                    Caption = 'Show &Request XML';
                    ToolTip = 'Open this current Request XML in a new window.';
                    ApplicationArea = All;
                    Image = ElectronicDoc;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;

                    trigger OnAction()
                    begin
                        Rec.ShowXMLRequestDoc();
                    end;
                }
                action("Show &Response XML")
                {
                    Caption = 'Show &Response XML';
                    ToolTip = 'Open this current Response XML in a new window.';
                    ApplicationArea = All;
                    Image = ElectronicDoc;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;

                    trigger OnAction()
                    begin
                        Rec.ShowXMLResponseDoc();
                    end;
                }
                action("Show Registrations")
                {
                    Caption = 'Show Registrations';
                    ToolTip = 'Show the registrations extracted from the Xml Request.';
                    ApplicationArea = All;
                    Image = ShowList;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;

                    trigger OnAction()
                    begin
                        Rec.ShowRegistrations();
                    end;
                }
                /* #if BC20+ */
                action("Performance Profiler Entries")
                {
                    Caption = 'Performance Profiler Entries', Locked = true;
                    ToolTip = 'Show the performance profiler entries from the Xml Request.', Locked = true;
                    ApplicationArea = All;
                    Image = Troubleshoot;
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedIsBig = true;
                    RunObject = page "MOB Perf. Profiler Entries";
                    RunPageLink = "Message ID" = field(filter("Message ID"));
                }
                /* #endif */

                action("Event Subscriptions")
                {
                    Caption = 'Event Subscriptions';
                    ToolTip = 'Show subscribers to Mobile WMS events.';
                    ApplicationArea = All;
                    Image = ShowList;
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedIsBig = true;

                    trigger OnAction()
                    var
                        EventSubscription: Record "Event Subscription";
                        EventSubscriptions: Page "Event Subscriptions";
                    begin
                        EventSubscription.SetRange("Publisher Object ID", 6181271, 6182270);
                        EventSubscription.SetFilter("Subscriber Codeunit ID", '<%1|>%2', 6181271, 6182270);
                        EventSubscriptions.SetTableView(EventSubscription);
                        EventSubscriptions.MOBSetEventSubsNotification(true);
                        EventSubscriptions.Run();
                    end;
                }
                action(Tweaks)
                {
                    Caption = 'Tweaks', Locked = true;
                    ToolTip = 'Show tweaks to the Mobile WMS configuration.', Locked = true;
                    ApplicationArea = All;
                    Image = ShowList;
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedIsBig = true;
                    RunObject = page "MOB Tweak List";
                }
            }
        }
        area(Processing)
        {
            group("Function")
            {
                Caption = 'F&unctions';
                action(Process)
                {
                    Caption = '&Process Documents';
                    ToolTip = 'Process all documents ready for processing.';
                    ApplicationArea = All;
                    Image = Start;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ShortcutKey = F10;
                    trigger OnAction()
                    var
                        MobDocQueue: Record "MOB Document Queue";
                        MobDocQueue2: Record "MOB Document Queue";
                        TempMobDocQueue: Record "MOB Document Queue" temporary;
                    begin
                        CurrPage.SetSelectionFilter(MobDocQueue);
                        MobDocQueue.SetCurrentKey("Message ID");
                        MobDocQueue.Ascending(true);
                        if MobDocQueue.FindSet() then
                            repeat
                                TempMobDocQueue := MobDocQueue;
                                TempMobDocQueue.Insert();
                            until MobDocQueue.Next() = 0;

                        TempMobDocQueue.SetCurrentKey("Created Date/Time");
                        if TempMobDocQueue.FindSet() then
                            repeat
                                MobDocQueue2 := TempMobDocQueue;
                                Rec.ProcessDocument(MobDocQueue2);
                            until TempMobDocQueue.Next() = 0;

                        if Rec.Get(Rec."Message ID") then; // Prevents cursor move after status changes and is part of sorting
                        MobSessionData.Initialize(); // Clear the session data to avoid leaving data behind (could be sensitive data or logged in telemetry for other processes)
                    end;
                }
                /* #if BC20+ */
                action(ProcessWithProfiler)
                {
                    Caption = '&Process Documents with Sampling Profiler', Locked = true;
                    ToolTip = 'Process selected documents with Sampling Profiler.', Locked = true;
                    ApplicationArea = All;
                    Image = Debug;
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedIsBig = true;
                    ShortcutKey = 'Ctrl+F10';
                    trigger OnAction()
                    var
                        MobDocQueue: Record "MOB Document Queue";
                        MobDocQueue2: Record "MOB Document Queue";
                        TempMobDocQueue: Record "MOB Document Queue" temporary;
                        MobPerfProfile: Record "MOB Perf. Profile Entry";
                        MobPerformanceProfiler: Codeunit "MOB Perf. Profiler";
                    begin
                        CurrPage.SetSelectionFilter(MobDocQueue);
                        MobDocQueue.SetCurrentKey("Message ID");
                        MobDocQueue.Ascending(true);
                        if MobDocQueue.FindSet() then
                            repeat
                                TempMobDocQueue := MobDocQueue;
                                TempMobDocQueue.Insert();
                            until MobDocQueue.Next() = 0;

                        TempMobDocQueue.SetCurrentKey("Created Date/Time");
                        if TempMobDocQueue.FindSet() then
                            repeat
                                MobDocQueue2 := TempMobDocQueue;
                                MobPerformanceProfiler.Start();
                                Rec.ProcessDocument(MobDocQueue2);

                                MobPerformanceProfiler.Stop(MobPerfProfile);
                                MobPerfProfile.Mark(true);
                            until TempMobDocQueue.Next() = 0;

                        MobPerfProfile.MarkedOnly(true);
                        MobPerformanceProfiler.DownloadProfilerFiles(MobPerfProfile);
                        MobSessionData.Initialize(); // Clear the session data to avoid leaving data behind (could be sensitive data or logged in telemetry for other processes)

                        Message(ProfileStartInfoMsg);

                        if Rec.Get(Rec."Message ID") then; // Prevents cursor move after status changes and is part of sorting
                    end;
                }
                /* #endif */
                action(Reset)
                {
                    Caption = 'R&eset Documents';
                    ToolTip = 'Reset documents Status to allow for reprocessing same documents again.';
                    ApplicationArea = All;
                    Ellipsis = true;
                    Image = ResetStatus;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ShortcutKey = F9;

                    trigger OnAction()
                    var
                        MobDocQueue: Record "MOB Document Queue";
                        MobDocQueue2: Record "MOB Document Queue";
                        TempMobDocQueue: Record "MOB Document Queue" temporary;
                    begin
                        if Confirm(ResetSelectedDocumentsQst, false) then begin
                            CurrPage.SetSelectionFilter(MobDocQueue);
                            MobDocQueue.SetCurrentKey("Message ID");
                            MobDocQueue.Ascending(true);
                            if MobDocQueue.FindSet() then
                                repeat
                                    TempMobDocQueue := MobDocQueue;
                                    TempMobDocQueue.Insert();
                                until MobDocQueue.Next() = 0;

                            TempMobDocQueue.SetCurrentKey("Created Date/Time");
                            if TempMobDocQueue.FindSet() then
                                repeat
                                    MobDocQueue2 := TempMobDocQueue;
                                    Rec.ResetDocument(MobDocQueue2);
                                until TempMobDocQueue.Next() = 0;
                        end;
                    end;
                }
                action(Delete)
                {
                    Caption = '&Delete Documents';
                    ToolTip = 'Delete documents from the Mobile Document Queue.';
                    ApplicationArea = All;
                    Ellipsis = true;
                    Image = DeleteXML;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;

                    trigger OnAction()
                    var
                        MobDocQueue: Record "MOB Document Queue";
                        MobDocQueue2: Record "MOB Document Queue";
                        NewFound: Boolean;
                        Confirmed: Boolean;
                    begin
                        CurrPage.SetSelectionFilter(MobDocQueue);
                        MobDocQueue.Ascending(true);
                        if MobDocQueue.FindSet() then begin
                            repeat
                                if MobDocQueue.Status in [MobDocQueue.Status::New, MobDocQueue.Status::Error] then
                                    NewFound := true;
                            until (MobDocQueue.Next() = 0) or NewFound;

                            if NewFound then begin
                                if Confirm(SelectedIncludeStatusMsg + DeleteSelectedDocumentsQst, false) then
                                    Confirmed := true;
                            end else
                                if Confirm(DeleteSelectedDocumentsQst, false) then
                                    Confirmed := true;

                            if Confirmed then begin
                                MobDocQueue.FindSet();
                                repeat
                                    MobDocQueue2 := MobDocQueue;
                                    Rec.DeleteDocument(MobDocQueue2);
                                until MobDocQueue.Next() = 0;
                            end;
                        end;
                    end;
                }
                separator(Separator58)
                {
                }
                action("Re&fresh")
                {
                    Caption = 'Re&fresh';
                    ToolTip = 'Refresh the Mobile Document Queue.';
                    ApplicationArea = All;
                    Image = Refresh;
                    Promoted = true;
                    PromotedCategory = Process;

                    trigger OnAction()
                    begin
                        CurrPage.Update(false);
                    end;
                }
            }
        }
    }

    var
        MobSessionData: Codeunit "MOB SessionData";
        /* #if BC20+ */
        ProfileStartInfoMsg: Label 'Sampling Profiling has now recorded the processing of the selected request(s) and the result can be found in your Downloads folder and in the Performance Profiler Entries window.\\Please make sure to have Additional Logging activated in Help and Support to get the highest level of detail in the Profiling data.', Locked = true;
    /* #endif */

    trigger OnInit()
    begin
        ShowAllCheckBoxEditable := true;
    end;

    trigger OnOpenPage()
    begin
        if (FilterMobileUser = '') and
           (FilterDocumentType = '') and
           not ShowNew and
           not ShowProcessing and
           not ShowCompleted and
           not Showerror
        then
            SetShowAll()
        else
            ValidateFilter();
        if not Rec.FindFirst() then; // To position on the uppermost record in the list
    end;

    trigger OnAfterGetCurrRecord()
    begin
        if RequestAddInReady then
            FillRequestHtmlViewerAddIn();

        if ResponseAddInReady then
            FillResponseHtmlViewerAddIn();
    end;

    local procedure FillRequestHtmlViewerAddIn()
    var
        HtmlMgt: Codeunit "MOB HTML Management";
    begin
        CurrPage.RequestControl.SetContent(HtmlMgt.CreateHtmlWithTextArea(Rec.GetRequestXMLAsText()));
    end;

    local procedure FillResponseHtmlViewerAddIn()
    var
        HtmlMgt: Codeunit "MOB HTML Management";
    begin
        CurrPage.ResponseControl.SetContent(HtmlMgt.CreateHtmlWithTextArea(Rec.GetResponseXMLAsText()));
    end;

    var
        FilterMobileUser: Text[1024];
        FilterDocumentType: Text[1024];
        FilterStatus: Text[1024];
        ShowAll: Boolean;
        ShowNew: Boolean;
        ShowProcessing: Boolean;
        ShowCompleted: Boolean;
        Showerror: Boolean;
        SelectedIncludeStatusMsg: Label 'The selected documents include documents with the status New or Error.\';
        DeleteSelectedDocumentsQst: Label 'Do you want to delete the selected documents?';
        ResetSelectedDocumentsQst: Label 'Do you want to reset the selected documents?';
        ShowAllCheckBoxEditable: Boolean;
        RequestAddInReady: Boolean;
        ResponseAddInReady: Boolean;

    local procedure ValidateFilter()
    begin
        BuildStatusFilter();

        ShowAll := ((FilterMobileUser = '') and (FilterDocumentType = '') and (FilterStatus = ''));

        Rec.FilterGroup(2);

        Rec.SetFilter(Status, FilterStatus);
        Rec.SetFilter("Document Type", FilterDocumentType);
        Rec.SetFilter("Mobile User ID", FilterMobileUser);

        ShowAllCheckBoxEditable := not ShowAll;
        Rec.FilterGroup(0);

        CurrPage.Update(false);
    end;

    local procedure SetShowAll()
    begin
        FilterMobileUser := '';
        FilterDocumentType := '';

        ShowNew := true;
        ShowProcessing := true;
        ShowCompleted := true;
        Showerror := true;

        ValidateFilter();
    end;

    local procedure BuildStatusFilter()
    begin
        FilterStatus := '';
        if ShowNew and ShowProcessing and ShowCompleted and Showerror then
            exit;

        if ShowNew then
            FilterStatus := FilterStatus + '|' + Format(Rec.Status::New);

        if ShowProcessing then
            FilterStatus := FilterStatus + '|' + Format(Rec.Status::Processing);

        if ShowCompleted then
            FilterStatus := FilterStatus + '|' + Format(Rec.Status::Completed);

        if Showerror then
            FilterStatus := FilterStatus + '|' + Format(Rec.Status::Error);

        if FilterStatus <> '' then
            FilterStatus := CopyStr(FilterStatus, 2)
        else
            FilterStatus :=
              StrSubstNo(
                '<>%1&<>%2&<>%3&<>%4', Format(Rec.Status::New), Format(Rec.Status::Processing), Format(Rec.Status::Completed), Format(Rec.Status::Error));
    end;

    local procedure ShowAllOnAfterValidate()
    begin
        SetShowAll();
    end;

    local procedure ShowNewOnAfterValidate()
    begin
        ValidateFilter();
    end;

    local procedure ShowProcessingOnAfterValidate()
    begin
        ValidateFilter();
    end;

    local procedure ShowerrorOnAfterValidate()
    begin
        ValidateFilter();
    end;

    local procedure ShowCompletedOnAfterValidate()
    begin
        ValidateFilter();
    end;

    local procedure FilterMobileUserOnAfterValidat()
    begin
        ValidateFilter();
    end;

    local procedure FilterDocumentTypeOnAfterValid()
    begin
        ValidateFilter();
    end;
}

