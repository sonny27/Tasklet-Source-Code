table 81293 "MOB Device Property"
{
    Caption = 'Mobile Device Property', Locked = true;
    DataClassification = CustomerContent;
    DrillDownPageId = "MOB Device Properties";
    LookupPageId = "MOB Device Properties";
    Access = Internal;

    fields
    {
        /// <summary>
        /// Contains the hash value of the capabilities node of the last GetReferenceData request.
        /// It is assumed many devices will have identical properties per company.
        /// The "Capability Hash Value" is used to reduce the need of storing the properties unless they have been changed
        /// A "MD5 Hash" got a length of 32 chars and a "SHA1 Hash" got a length of 42. 
        /// Having a field length of 42 allows usage of the fastest hash (MD5) but later change to SHA1 if MD5 is not "unique enough".
        /// </summary>
        field(1; "Capability Hash Value"; Text[42])
        {
            Caption = 'Capability Hash Value', Locked = true;
            DataClassification = CustomerContent;
        }

        /// <summary>
        /// The name of the attribute value in XPath format
        /// </summary>
        field(2; Name; Text[250])
        {
            Caption = 'Name', Locked = true;
            DataClassification = CustomerContent;
        }

        /// <summary>
        /// The value of the property
        /// </summary>     

        field(10; Value; Text[250])
        {
            Caption = 'Value', Locked = true;
            DataClassification = CustomerContent;
        }
    }
    keys
    {
        key(PK; "Capability Hash Value", Name)
        {
            Clustered = true;
        }
    }

    /// <summary>
    /// Opens a page with all devices with the specific property value (i.e. '/device/language[@currentCultureName]' = 'en-US')
    /// </summary>
    internal procedure ShowDevicesWithPropertyValue()
    var
        MobDevice: Record "MOB Device";
        MobDeviceProperty: Record "MOB Device Property";
    begin
        // Loop Device Properties with the same Path and Value
        MobDeviceProperty.SetRange(Name, Rec.Name);
        MobDeviceProperty.SetRange(Value, Rec.Value);
        if MobDeviceProperty.FindSet() then
            repeat
                // Loop all devices with the Hash Value of the found property
                MobDevice.SetRange("Capability Hash Value", MobDeviceProperty."Capability Hash Value");
                if MobDevice.FindSet() then
                    repeat
                        // Mark the device to show it in the list
                        MobDevice.Mark(true);
                    until MobDevice.Next() = 0;
            until MobDeviceProperty.Next() = 0;

        // Remove filter used above and show marked records in a list
        MobDevice.SetRange("Capability Hash Value");
        MobDevice.MarkedOnly(true);
        Page.Run(0, MobDevice);
    end;
}
