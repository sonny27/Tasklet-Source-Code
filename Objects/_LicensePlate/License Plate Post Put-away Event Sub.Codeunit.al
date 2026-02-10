codeunit 81336 "MOB Post LP Put-away EventSub"
{
    Access = Public;
    EventSubscriberInstance = Manual;

    var
        MobLicensePlateNo: Code[20];
        ToBin: Code[20];

    internal procedure SetParameters(_MobLicensePlateNo: Code[20]; _ToBin: Code[20])
    begin
        MobLicensePlateNo := _MobLicensePlateNo;
        ToBin := _ToBin;
    end;

    /// <summary>
    /// We use this Event Subscriber to ensure that the License Plate is updated in same transaction as the Put-away is registered.
    /// </summary>    
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Activity-Register", 'OnAfterRegisterWhseActivity', '', false, false)]
    local procedure OnAfterRegisterWhseActivity(var WarehouseActivityHeader: Record "Warehouse Activity Header")
    var
        MobLicensePlate: Record "MOB License Plate";
    begin
        if WarehouseActivityHeader.Type <> WarehouseActivityHeader.Type::"Put-away" then
            exit;

        if MobLicensePlate.Get(MobLicensePlateNo) then begin
            // Update the License Plate record will update the License Plate Content records as well
            MobLicensePlate.Validate("Whse. Document Type", MobLicensePlate."Whse. Document Type"::" ");
            MobLicensePlate.Validate("Whse. Document No.", ''); // Clearing the WhseDocNo will clear the link to the source document on the LP content records
            MobLicensePlate.Validate("Receipt Status", MobLicensePlate."Receipt Status"::" ");
            MobLicensePlate.Validate("Bin Code", ToBin);
            MobLicensePlate.Modify(true);
        end;
    end;
}
