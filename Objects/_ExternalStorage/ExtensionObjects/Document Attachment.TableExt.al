tableextension 81273 "MOB Document Attachment" extends "Document Attachment"
{
    /* #if BC26+ */
    fields
    {
        /// <summary>
        /// External file account ID when the file is stored externally.
        /// </summary>
        field(6181271; "MOB Ext. File Account Id"; Guid)
        {
            Caption = 'MOB External File Account Id', Locked = true;
            Editable = false;
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// External storage connector type when the file is stored externally.
        /// </summary>
        field(6181272; "MOB Ext. Storage Connector"; Enum "Ext. File Storage Connector")
        {
            Caption = 'MOB External Storage Connector', Locked = true;
            Editable = false;
            DataClassification = CustomerContent;
        }
    }

    internal procedure MobIsExternalFile(): Boolean
    begin
        exit((not IsNullGuid(Rec."MOB Ext. File Account Id"))
                and (Rec."MOB Ext. Storage Connector".AsInteger() <> 0)
                and (Rec."File Name" <> '')
                and (Rec."File Extension" <> ''));
    end;
    /* #endif */
}
