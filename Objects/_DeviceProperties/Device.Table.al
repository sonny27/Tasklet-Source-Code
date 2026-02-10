table 81292 "MOB Device"
{
    Access = Public;
    Caption = 'Mobile Device', Locked = true;
    DataClassification = CustomerContent;
    DrillDownPageId = "MOB Devices";
    LookupPageId = "MOB Devices";

    fields
    {
        /// <summary>
        /// The "Device ID" of the device
        /// </summary>
        field(1; "Device ID"; Code[200])
        {
            Caption = 'Device ID', Locked = true;
            Editable = false;
            NotBlank = true;
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// The Description of the device - i.e. the name in SOTI or other human readable name
        /// </summary>
        field(10; Description; Text[50])
        {
            Caption = 'Description', Locked = true;
            DataClassification = CustomerContent;
        }
        field(11; "Latest Image Height"; Integer)
        {
            Caption = 'Latest Image Height', Locked = true;
            Editable = false;
            BlankZero = true;
            DataClassification = CustomerContent;
        }
        field(12; "Latest Image Width"; Integer)
        {
            Caption = 'Latest Image Width', Locked = true;
            Editable = false;
            BlankZero = true;
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// Contains the hash value of the capabilities node of the last GetReferenceData request.
        /// It is assumed many devices will have identical properties per company.
        /// The "Capability Hash Value" is used to reduce the need of storing the properties unless they have been changed
        /// A "MD5 Hash" got a length of 32 chars and a "SHA1 Hash" got a length of 42. 
        /// Having a field length of 42 allows usage of the fastest hash (MD5) but later change to SHA1 if MD5 is not "unique enough".
        /// </summary>
        field(20; "Capability Hash Value"; Text[42])
        {
            Caption = 'Capability Hash Value', Locked = true;
            DataClassification = CustomerContent;
            Editable = false;
        }
        /// <summary>
        /// The number of properties linked to the device via the capability hash
        /// </summary>
        field(100; "No. of Properties"; Integer)
        {
            Caption = 'No. of Properties', Locked = true;
            Editable = false;
            BlankZero = true;
            FieldClass = FlowField;
            CalcFormula = count("MOB Device Property" where("Capability Hash Value" = field("Capability Hash Value")));
        }

        /// <summary>
        /// The Application Version of the device property linked to the device via the capability hash
        /// </summary>
        field(110; "Application Version"; Text[250])
        {
            Caption = 'Application Version', Locked = true;
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("MOB Device Property".Value where("Capability Hash Value" = field("Capability Hash Value"),
                                                                     Name = const('/application[@version]')));
        }

        /// <summary>
        /// The Manufacturer of the device property linked to the device via the capability hash
        /// </summary>
        field(120; Manufacturer; Text[250])
        {
            Caption = 'Manufacturer', Locked = true;
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("MOB Device Property".Value where("Capability Hash Value" = field("Capability Hash Value"),
                                                                     Name = const('/device[@manufacturer]')));
        }

        /// <summary>
        /// The Model of the device property linked to the device via the capability hash
        /// </summary>
        field(130; Model; Text[250])
        {
            Caption = 'Model', Locked = true;
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("MOB Device Property".Value where("Capability Hash Value" = field("Capability Hash Value"),
                                                                     Name = const('/device[@model]')));
        }
        /// <summary>
        /// The Language Culture Name of the device property linked to the device via the capability hash
        /// </summary>
        field(140; "Language Culture Name"; Text[250])
        {
            Caption = 'Language Culture Name', Locked = true;
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("MOB Device Property".Value where("Capability Hash Value" = field("Capability Hash Value"),
                                                                     Name = const('/device/language[@currentCultureName]')));
        }
        /// <summary>
        /// The Number of Registrations on the device from the MOB RealTime Reg. Qty table
        /// </summary>
        field(150; "No. of Registrations"; Integer)
        {
            Caption = 'No. of Registrations', Locked = true;
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = count("MOB Realtime Reg Qty." where("Device ID" = field("Device ID")));
        }
    }
    keys
    {
        key(PK; "Device ID")
        {
            Clustered = true;
        }
    }
    fieldgroups
    {
        fieldgroup(DropDown; "Device ID", Description, Model)
        {
        }
    }

    trigger OnDelete()
    begin
        DeleteDevicePropertiesIfLastDevice();
    end;

    internal procedure DeleteDevicePropertiesIfLastDevice()
    var
        MobDeviceWithSameCapabilityHash: Record "MOB Device";
        MobDeviceProperty: Record "MOB Device Property";
    begin
        if Rec."Capability Hash Value" <> '' then begin
            MobDeviceWithSameCapabilityHash.SetFilter("Device ID", '<>%1', Rec."Device ID");
            MobDeviceWithSameCapabilityHash.SetRange("Capability Hash Value", Rec."Capability Hash Value");
            if MobDeviceWithSameCapabilityHash.IsEmpty() then begin
                // Delete all device properties to ensure they are not left without any linked device
                MobDeviceProperty.SetRange("Capability Hash Value", Rec."Capability Hash Value");
                MobDeviceProperty.DeleteAll();
            end;
        end;
    end;

}
