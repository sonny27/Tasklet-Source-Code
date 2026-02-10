page 81278 "MOB Document Types"
{
    Caption = 'Mobile Document Types';
    AdditionalSearchTerms = 'Mobile Document Types Tasklet Configuration Device Scanner', Locked = true;
    PageType = List;
    SourceTable = "MOB Document Type";
    UsageCategory = Administration;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                field("Document Type"; Rec."Document Type")
                {
                    Caption = 'Request Document Type';
                    ToolTip = 'The Document Type from the Request XML.';
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
                {
                    ToolTip = 'Description for this Request Document Type.';
                    ApplicationArea = All;
                }
                field("Processing Codeunit"; Rec."Processing Codeunit")
                {
                    ToolTip = 'Specifies the processing codeunit for Requests with this Document Type.';
                    ApplicationArea = All;
                }
                field("Processing Codeunit Name"; Rec."Processing Codeunit Name")
                {
                    ToolTip = 'Name of processing codeunit for Requests with this Document Type.';
                    ApplicationArea = All;
                }
                /* #if BC20+ */
                field("Profiling Enabled"; ProfilingEnabled)
                {
                    Caption = 'Profiling Enabled', Comment = 'Do not translate Profiling';
                    ToolTip = 'Sampling Profiling is enabled for the document type. It can be enabled for 15 minutes and can also be enabled per user.', Comment = 'Do not translate Sampling Profiling';
                    ApplicationArea = All;

                    trigger OnValidate()
                    var
                        MobPerfProfiler: Codeunit "MOB Perf. Profiler";
                    begin
                        MobPerfProfiler.ToggleEnabledUntil(Rec."Profiling Enabled Until", Rec.TableCaption(), Rec."Document Type");
                        CurrPage.SaveRecord();
                    end;
                }
                /* #endif */
            }
        }
    }

    /* #if BC20+ */
    var
        ProfilingEnabled: Boolean;

    trigger OnAfterGetRecord()
    begin
        ProfilingEnabled := Rec."Profiling Enabled Until" > CurrentDateTime();
    end;
    /* #endif */

    procedure GetSelectionFilter(): Text[1024]
    var
        MobDocType: Record "MOB Document Type";
        First: Text[50];
        Last: Text[50];
        SelectionFilter: Text[1024];
        MobDocTypeCount: Integer;
        More: Boolean;
    begin
        CurrPage.SetSelectionFilter(MobDocType);
        MobDocType.SetCurrentKey("Document Type");
        MobDocTypeCount := MobDocType.Count();
        if MobDocTypeCount > 0 then begin
            MobDocType.FindFirst();
            while MobDocTypeCount > 0 do begin
                MobDocTypeCount := MobDocTypeCount - 1;
                MobDocType.MarkedOnly(false);
                First := MobDocType."Document Type";
                Last := First;
                More := (MobDocTypeCount > 0);
                while More do
                    if MobDocType.Next() = 0 then
                        More := false
                    else
                        if not MobDocType.Mark() then
                            More := false
                        else begin
                            Last := MobDocType."Document Type";
                            MobDocTypeCount := MobDocTypeCount - 1;
                            if MobDocTypeCount = 0 then
                                More := false;
                        end;
                if SelectionFilter <> '' then
                    SelectionFilter := SelectionFilter + '|';
                if First = Last then
                    SelectionFilter := SelectionFilter + First
                else
                    SelectionFilter := SelectionFilter + First + '..' + Last;
                if MobDocTypeCount > 0 then begin
                    MobDocType.MarkedOnly(true);
                    MobDocType.Next();
                end;
            end;
        end;
        exit(SelectionFilter);
    end;
}

