page 81288 "MOB Devices"
{
    Caption = 'Mobile Devices';
    AdditionalSearchTerms = 'Mobile Devices Tasklet Scanner', Locked = true;
    ApplicationArea = All;
    PageType = List;
    SourceTable = "MOB Device";
    UsageCategory = Administration;
    InsertAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Device ID"; Rec."Device ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Device ID field.', Locked = true;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Description field.', Locked = true;
                }
                field("Latest Image Width"; Rec."Latest Image Width")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the width in pixels of the latest image received from the device.', Locked = true;
                }
                field("Latest Image Height"; Rec."Latest Image Height")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the height in pixels of the latest image received from the device.', Locked = true;
                }
                field("Application Version"; Rec."Application Version")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the version of the Mobile Application of the device.', Locked = true;
                }
                field(Manufacturer; Rec.Manufacturer)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Manufacturer of the device.', Locked = true;
                }
                field(Model; Rec.Model)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Model of the device.', Locked = true;
                }
                field("Language Culture Name"; Rec."Language Culture Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Language Culture Name of the device.', Locked = true;
                }
                field("No. of Properties"; Rec."No. of Properties")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Number of Properties of the device.', Locked = true;
                }
                field("No. of Registrations"; Rec."No. of Registrations")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Number of unposted Registrations on the device.', Locked = true;
                }
            }
        }
    }
}
