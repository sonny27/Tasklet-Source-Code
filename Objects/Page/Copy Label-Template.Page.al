page 81369 "MOB Copy Label-Template"
{
    Caption = 'Copy Label-Template';
    PageType = StandardDialog;
    layout
    {
        area(Content)
        {
            group("Copying Label-Templates")
            {
                Caption = 'Copying Label-Templates', Locked = true;
                InstructionalText = 'You are creating a working copy of an existing label-template. When completed use the "Open In Designer"-action to begin modifying the design.';
                field(InputName; TemplateName)
                {
                    ApplicationArea = All;
                    Caption = 'Name';
                    ToolTip = 'The name of the new label-template';
                    NotBlank = true;
                }
            }
        }
    }
    var
        TemplateName: Text;

    internal procedure GetTemplateName(): Text
    begin
        exit(TemplateName);
    end;

    internal procedure SetTemplateName(_Text: Text)
    begin
        TemplateName := _Text;
    end;
}
