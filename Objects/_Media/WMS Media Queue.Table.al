table 81375 "MOB WMS Media Queue"
{
    Access = Public;
    Caption = 'Mobile WMS Media Queue';
    Description = 'Contains reference to images expected to be received from the mobile devices';
    DrillDownPageId = "MOB WMS Media Queue";
    LookupPageId = "MOB WMS Media Queue";

    fields
    {
        field(1; "Image Id"; Text[250])
        {
            Caption = 'Image Id';
            DataClassification = CustomerContent;
        }
        field(2; "Device ID"; Code[200])
        {
            Caption = 'Device ID';
            DataClassification = CustomerContent;
        }
        field(10; Note; Text[250])
        {
            Caption = 'Note';
            DataClassification = CustomerContent;
        }
        field(11; Description; Text[250])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
        }
        field(12; "Record ID"; RecordId)
        {
            Caption = 'Record ID';
            Description = 'RecordId extracted from ReferenceID in request.';
            DataClassification = SystemMetadata;
        }
        field(13; "Target Record ID"; RecordId)
        {
            Caption = 'Target Record ID';
            Description = 'RecordId for the record that is the target of the image (e.g. the source document).';
            DataClassification = SystemMetadata;
        }
        field(15; "Created Date"; Date)
        {
            Caption = 'Date';
            DataClassification = SystemMetadata;
        }
        field(16; "Created Time"; Time)
        {
            Caption = 'Time';
            DataClassification = SystemMetadata;
        }
        field(100; Picture; MediaSet)
        {
            Caption = 'Picture';
            DataClassification = CustomerContent;
        }
        /* #if BC26+ */
        /// <summary>
        /// External file account ID when the file is stored externally.
        /// </summary>
        field(101; "Ext. File Account Id"; Guid)
        {
            Caption = 'External File Account Id';
            Editable = false;
            AllowInCustomizations = Always;
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// External storage connector type when the file is stored externally.
        /// </summary>
        field(102; "Ext. Storage Connector"; Enum "Ext. File Storage Connector")
        {
            Caption = 'External Storage Connector';
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// External file name when the file is stored externally.
        /// </summary>
        field(103; "Ext. File Name"; Text[250])
        {
            Caption = 'External File Name';
            DataClassification = CustomerContent;
        }
        /* #endif */
    }

    keys
    {
        key(Key1; "Image Id", "Device ID")
        {
        }
        key(Key2; "Record ID")
        {
        }
        /* #if BC26+ */
        key(Key3; "Ext. File Account Id", "Ext. Storage Connector") { }
        /* #endif */
    }

    fieldgroups
    {
    }
    trigger OnInsert()
    begin
        "Created Date" := WorkDate();
        "Created Time" := Time();
    end;

    internal procedure ExportFile()
    var
        MobWmsMedia: Codeunit "MOB WMS Media";
    begin
        MobWmsMedia.ExportImageFile(Rec);
    end;

    /* #if BC26+ */
    internal procedure IsExternalFile(): Boolean
    begin
        exit((not IsNullGuid(Rec."Ext. File Account Id"))
                and (Rec."Ext. Storage Connector".AsInteger() <> 0)
                and (Rec."Ext. File Name" <> ''));
    end;
    /* #endif */
}
