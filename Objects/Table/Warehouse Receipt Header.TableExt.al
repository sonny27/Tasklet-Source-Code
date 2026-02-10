tableextension 81440 "MOB Warehouse Receipt Header" extends "Warehouse Receipt Header"


// Tasklet Factory - Mobile WMS
// Added the "MOB Posting Message ID" field
// This field is set when documents are being posting from the mobile device or mobile queue

{
    fields
    {
#pragma warning disable LC0044 // Names does not match cop-rule - This is not an issue we want to fix
        field(6181280; "MOB Posting MessageId"; Guid)
#pragma warning restore LC0044
        {
            Description = 'Mobile WMS';
            Caption = 'Posting Mobile MessageId';
            DataClassification = CustomerContent;
        }
    }

    /// <summary>
    /// Get the value for a custom header step for the Mobile Message ID currently being posted ("MOB Posting MessageId")
    /// </summary>
    /// <param name="_Path">The identification for the step as declared in the eventsubcriber that created the step</param>
    /// <param name="_ErrorIfNotExists">Throw error if _Path could not be found. If false, an empty string will be returned if _Path not exists</param>
    /// <remarks>If reading many values, you may use "MobRequestMgt.GetOrderValues("MOB Posting MessageId", TempMobOrderValues)" for better performance</remarks>
    procedure "MOB GetOrderValue"(_Path: Text; _ErrorIfNotExists: Boolean): Text
    var
        TempMobOrderValues: Record "MOB Common Element" temporary;
        MobRequestMgt: Codeunit "MOB NS Request Management";
    begin
        TestField("MOB Posting MessageId");
        MobRequestMgt.GetOrderValues("MOB Posting MessageId", TempMobOrderValues);
        exit(TempMobOrderValues.GetValue(_Path, _ErrorIfNotExists));
    end;
}
