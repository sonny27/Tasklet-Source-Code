table 81281 "MOB Perf. Profile Entry"
{
    Access = Public;
    Caption = 'Performance Profiler Entry', Locked = true;
    DataClassification = CustomerContent;
    DrillDownPageId = "MOB Perf. Profiler Entries";
    LookupPageId = "MOB Perf. Profiler Entries";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.', Locked = true;
            DataClassification = SystemMetadata;
            AutoIncrement = true;
        }
        field(20; "Message ID"; Code[100])
        {
            Caption = 'Message ID', Locked = true;
            TableRelation = "MOB Document Queue"."Message ID";
            DataClassification = SystemMetadata;
        }
        field(25; "Request Created Date/Time"; DateTime)
        {
            Caption = 'Request Created Date/Time', Locked = true;
            DataClassification = SystemMetadata;
        }

        field(30; "Document Type"; Text[50])
        {
            Caption = 'Document Type', Locked = true;
            TableRelation = "MOB Document Type";
            DataClassification = CustomerContent;
        }
        field(40; "Registration Type"; Text[80])
        {
            Caption = 'Registration Type', Locked = true;
            DataClassification = CustomerContent;
        }
        field(50; Status; Option)
        {
            Caption = 'Status', Locked = true;
            OptionCaption = 'New,Processing,Completed,Error', Locked = true;
            OptionMembers = New,Processing,Completed,Error;
            DataClassification = CustomerContent;
        }
        field(60; "Processing Duration"; Duration)
        {
            Caption = 'Processing Duration', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(70; "SQL Rows Read"; BigInteger)
        {
            Caption = 'SQL Rows Read', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(80; "SQL Statements Executed"; BigInteger)
        {
            Caption = 'Sql Statements Executed', Locked = true;
            DataClassification = SystemMetadata;
        }
        field(90; "Mobile User ID"; Code[50])
        {
            Caption = 'Mobile User ID', Locked = true;
            TableRelation = "MOB User";
            DataClassification = EndUserIdentifiableInformation;
        }
        field(100; "Mobile WMS Extension Version"; Text[50])
        {
            Caption = 'Mobile WMS Extension Version', Locked = true;
            DataClassification = CustomerContent;
        }
        field(120; "Base App Version"; Text[50])
        {
            Caption = 'Base App Version', Locked = true;
            DataClassification = CustomerContent;
        }
        field(130; "Profile Data"; Blob)
        {
            Caption = 'Profile Data', Locked = true;
            DataClassification = EndUserIdentifiableInformation;
        }
    }
    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Message ID")
        {
        }

        /* #if BC17+ */
        key(Key3; SystemCreatedAt)
        {
        }
        /* #endif */
    }
    var
        MobSessionData: Codeunit "MOB SessionData";

    internal procedure InitializeValues()
    var
        MobDocQueue: Record "MOB Document Queue";
    begin
        MobDocQueue.GetByGuid(MobSessionData.GetPostingMessageId(), MobDocQueue);

        Init();
        "Entry No." := 0; // AutoIncrement = true
        "Message ID" := MobDocQueue."Message ID";
        "Request Created Date/Time" := MobDocQueue."Created Date/Time";
        "Document Type" := MobDocQueue."Document Type";
        "Registration Type" := MobDocQueue."Registration Type";
        Status := MobDocQueue.Status;
        "Processing Duration" := MobDocQueue."Processing Duration";
        "Mobile User ID" := MobDocQueue."Mobile User ID";
    end;

    internal procedure FilenameWithExtension(): Text
    begin
        exit(StrSubstNo('%1.%2', Filename(), FileExtension()));
    end;

    internal procedure Filename(): Text
    begin
        exit(StrSubstNo('%1 %2 (%3 ms)', "Document Type", "Message ID", Format(Round("Processing Duration", 1), 0, 2)));
    end;

    internal procedure FileExtension(): Text
    begin
        exit('alcpuprofile');
    end;
}
