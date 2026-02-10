page 81281 "MOB Perf. Profiler Entries"
{
    // Sampling Profiling is introduced by Microsoft in BC20
    /* #if BC20+ */

    Caption = 'Performance Profiler Entries', Locked = true;
    PageType = List;
    SourceTable = "MOB Perf. Profile Entry";
    Editable = false;
    SourceTableView = sorting("Entry No.") order(descending);

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(SystemCreatedAt; Rec.SystemCreatedAt)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Profiled Date/Time field.', Locked = true;
                    Caption = 'Profiled Date/Time', Locked = true;
                }
                field("Mobile User ID"; Rec."Mobile User ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Mobile User ID field.', Locked = true;
                }

                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Document Type field.', Locked = true;
                }
                field("Registration Type"; Rec."Registration Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Registration Type field.', Locked = true;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Status field.', Locked = true;
                }
                field("SQL Rows Read"; Rec."SQL Rows Read")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the SQL Rows Read field.', Locked = true;
                }
                field("SQL Statements Executed"; Rec."SQL Statements Executed")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Sql Statements Executed field.', Locked = true;
                }
                field("Processing Duration"; Rec."Processing Duration")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Processing Duration field.', Locked = true;
                }
                field("Mobile WMS Extension Version"; Rec."Mobile WMS Extension Version")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Mobile WMS Extension Version field.', Locked = true;
                }
                field("Base App Version"; Rec."Base App Version")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Base App Version field.', Locked = true;
                }
                field("Request Created Date/Time"; Rec."Request Created Date/Time")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Request Created Date/Time field.', Locked = true;
                }
                field("Message ID"; Rec."Message ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Message ID field.', Locked = true;
                }
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Entry No. field.', Locked = true;
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(Download)
            {
                ApplicationArea = All;
                Promoted = true;
                PromotedOnly = true;
                PromotedCategory = Process;
                Image = Download;
                Caption = 'Download', Locked = true;
                ToolTip = 'Download the performance profiler file of the recording performed.', Locked = true;

                trigger OnAction()
                var
                    ToFile: Text;
                    IStream: InStream;
                begin
                    if not Confirm(PrivacyNoticeQst) then
                        exit;

                    Rec.CalcFields("Profile Data");
                    Rec."Profile Data".CreateInStream(IStream);
                    ToFile := Rec.FilenameWithExtension();
                    DownloadFromStream(IStream, '', '', '', ToFile);
                end;
            }
        }
    }
    var
        PrivacyNoticeQst: Label 'The file might contain sensitive data, so be sure to handle it securely and according to privacy requirements. Do you want to continue?', Locked = true;

    /* #endif */
}
