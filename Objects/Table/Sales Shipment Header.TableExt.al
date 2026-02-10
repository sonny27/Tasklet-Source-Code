tableextension 81370 "MOB Sales Shipment Header" extends "Sales Shipment Header"


// Tasklet Factory - Mobile WMS
// Added the "MOB Message ID" field
// This field is set when documents are being posting from the mobile device or mobile queue

{
    fields
    {
#pragma warning disable LC0044 // Names does not match cop-rule - This is not an issue we want to fix
        field(6181280; "MOB MessageId"; Guid)
#pragma warning restore LC0044
        {
            Description = 'Mobile WMS';
            Caption = 'Mobile MessageId';
            DataClassification = CustomerContent;
        }
    }

    /// <summary>
    /// Get the value for a custom header step for the Mobile Message ID posted ("MOB MessageId")
    /// </summary>
    /// <param name="_Path">The identification for the step as declared in the eventsubcriber that created the step</param>
    /// <param name="_ErrorIfNotExists">Throw error if _Path could not be found. If false, an empty string will be returned if _Path not exists</param>
    /// <remarks>If reading many values, you may use "MobRequestMgt.GetOrderValues("MOB MessageId", TempMobOrderValues)" for better performance</remarks>
    procedure "MOB GetOrderValue"(_Path: Text; _ErrorIfNotExists: Boolean): Text
    var
        TempMobOrderValues: Record "MOB Common Element" temporary;
        MobRequestMgt: Codeunit "MOB NS Request Management";
    begin
        TestField("MOB MessageId");
        MobRequestMgt.GetOrderValues("MOB MessageId", TempMobOrderValues);
        exit(TempMobOrderValues.GetValue(_Path, _ErrorIfNotExists));
    end;
}
