page 81373 "MOB WMS Media Queue Picture"
{
    PageType = CardPart;
    Caption = 'Mobile WMS Media Queue Picture';
    Editable = false;
    LinksAllowed = false;
    UsageCategory = None;
    SourceTable = "MOB WMS Media Queue";

    layout
    {
        area(Content)
        {
            field(Picture; Rec.Picture)
            {
                ToolTip = 'Picture.';
                ApplicationArea = All;
                ShowCaption = false;
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

                trigger OnAction()
                begin
                    Rec.ExportFile();
                end;
            }
        }
    }
}
