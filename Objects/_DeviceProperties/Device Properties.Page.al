page 81289 "MOB Device Properties"
{
    Caption = 'Mobile Device Properties', Locked = true;
    PageType = List;
    Editable = false;
    SourceTable = "MOB Device Property";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Capability Hash Value"; Rec."Capability Hash Value")
                {
                    Visible = false;
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Capability Hash Value field.', Locked = true;
                }

                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Name field.', Locked = true;
                }
                field("Value"; Rec."Value")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Value field.', Locked = true;
                }
            }
        }
    }
    actions
    {
        area(Navigation)
        {
            action(DevicesWithIdenticalProperties)
            {
                ApplicationArea = All;
                Image = VariableList;
                Caption = 'Identical Devices', Locked = true;
                ToolTip = 'Show devices with identical properties.', Locked = true;
                RunObject = page "MOB Devices";
                RunPageLink = "Capability Hash Value" = field("Capability Hash Value");
            }
            action(DevicesWithProperty)
            {
                ApplicationArea = All;
                Image = Open;
                Caption = 'Devices with this property value', Locked = true;
                ToolTip = 'Show devices with the this specific property value.', Locked = true;

                trigger OnAction()
                begin
                    Rec.ShowDevicesWithPropertyValue();
                end;
            }
        }
    }
}
