table 81278 "MOB Document Type"
{
    Access = Public;
    Caption = 'Mobile Document Type';
    DataCaptionFields = "Document Type", Description;
    DrillDownPageId = "MOB Document Types";
    LookupPageId = "MOB Document Types";

    fields
    {
        field(1; "Document Type"; Text[50])
        {
            Caption = 'Document Type';
            NotBlank = true;
            DataClassification = CustomerContent;
        }
        field(2; Description; Text[80])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
        }
        field(3; "Process Type"; Option)
        {
            Caption = 'Process Type', Locked = true;
            OptionCaption = 'Queue,Direct';
            OptionMembers = Queue,Direct;
            DataClassification = CustomerContent;
            ObsoleteReason = 'Not used in Mobile WMS';
            ObsoleteState = Removed;
            ObsoleteTag = 'MOB4.37';
        }
        field(4; "Processing Codeunit"; Integer)
        {
            Caption = 'Processing Codeunit';
            TableRelation = AllObj."Object ID" where("Object Type" = const(Codeunit));
            DataClassification = CustomerContent;
        }
        field(5; "Processing Codeunit Name"; Text[30])
        {
            CalcFormula = lookup(AllObj."Object Name" where("Object Type" = const(Codeunit),
                                                             "Object ID" = field("Processing Codeunit")));
            Caption = 'Processing Codeunit Name';
            Editable = false;
            FieldClass = FlowField;
        }

        field(6; "Strict Schema Validation"; Boolean)
        {
            Caption = 'Strict Schema Validation', Locked = true;
            DataClassification = CustomerContent;
            ObsoleteReason = 'Not used in Mobile WMS';
            ObsoleteState = Removed;
            ObsoleteTag = 'MOB5.35';
        }

        /* #if BC20+ */
        field(20; "Profiling Enabled Until"; DateTime)
        {
            Caption = 'Profiling Enabled Until';
            DataClassification = CustomerContent;
            Editable = false;
        }
        /* #endif */
    }

    keys
    {
        key(Key1; "Document Type")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Processing Codeunit", "Processing Codeunit Name")
        {
        }
    }

    trigger OnDelete()
    var
        MobDocQueue: Record "MOB Document Queue";
    begin
        MobDocQueue.SetRange("Document Type", "Document Type");
        if not MobDocQueue.IsEmpty() then
            Error(ContainsDocumentsCannotDeleteMsg, MobDocQueue.TableCaption(), "Document Type");
    end;

    var
        ContainsDocumentsCannotDeleteMsg: Label 'The table %1 contains %2 documents and cannot be deleted until the documents are deleted.', Comment = '%1 contains Table No., %2 contains Document Type';
}

