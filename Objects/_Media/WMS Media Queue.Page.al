page 81372 "MOB WMS Media Queue"
{
    Caption = 'Mobile WMS Media Queue';
    AdditionalSearchTerms = 'Mobile WMS Media Queue Tasklet Log Image', Locked = true;
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = List;
    SourceTable = "MOB WMS Media Queue";
    SourceTableView = order(descending);
    UsageCategory = Administration;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Control1000000000)
            {
                field("Created Date"; Rec."Created Date")
                {
                    ToolTip = 'Created Date.';
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Created Time"; Rec."Created Time")
                {
                    ToolTip = 'Created Time.';
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Image Id"; Rec."Image Id")
                {
                    ToolTip = 'Image ID of an image being asynchronously transferred between Mobile Device and Business Central.';
                    ApplicationArea = All;
                    Editable = false;
                }
                field(Note; Rec.Note)
                {
                    ToolTip = 'Note for an image being asynchronously transferred between Mobile Device and Business Central.';
                    ApplicationArea = All;
                }
                field("Device ID"; Rec."Device ID")
                {
                    ToolTip = 'Device ID that triggered this asynchronously image transfer between Mobile Device and Business Central.';
                    ApplicationArea = All;
                    Editable = false;
                }
                field(Description; Rec.Description)
                {
                    ToolTip = 'Description for an image being asynchronously transferred between Mobile Device and Business Central.';
                    ApplicationArea = All;
                    Editable = false;
                }
                field(TargetRecordId; Format(Rec."Target Record ID"))
                {
                    Caption = 'Target Record ID';
                    ToolTip = 'Record ID of the record that is the target of the image (e.g. the source document). The target record is found based on the ReferenceID in the RegisterImage request.';
                    ApplicationArea = All;
                    Editable = false;
                }
                /* #if BC26+ */
                field(StoredAsTenantMediaField; StoredAsTenantMedia)
                {
                    Caption = 'Stored as Tenant Media';
                    ToolTip = 'Specifies if the image is stored as Tenant Media in the Business Central database.';
                    Editable = false;
                    ApplicationArea = All;
                }
                field("Ext. File Name"; Rec."Ext. File Name")
                {
                    ToolTip = 'Specifies the name of the file in the external storage.';
                    Editable = false;
                    ApplicationArea = All;
                }
                field("Ext. File Account Connector"; Rec."Ext. Storage Connector")
                {
                    ToolTip = 'Specifies the connector that was used when the file was stored externally.';
                    BlankZero = true;
                    Editable = false;
                    ApplicationArea = All;
                }
                /* #endif */
            }
        }
        area(FactBoxes)
        {
            part(Picture; "MOB WMS Media Queue Picture")
            {
                ApplicationArea = All;
                Caption = 'Picture';
                SubPageLink = "Image Id" = field("Image Id"), "Device ID" = field("Device ID");
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ExportImage)
            {
                ApplicationArea = All;
                Caption = 'Export Image';
                ToolTip = 'Export Image';
                Image = ExportFile;
                Promoted = true;
                PromotedIsBig = true;
                PromotedCategory = Process;

                trigger OnAction()
                begin
                    Rec.ExportFile();
                end;
            }
        }
    }

    /* #if BC26+ */
    var
        StoredAsTenantMedia: Boolean;

    trigger OnAfterGetRecord()
    begin
        StoredAsTenantMedia := Rec.Picture.Count() > 0;
    end;
    /* #endif */
}

