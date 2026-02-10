codeunit 81349 "MOB Format Address"
{
    Access = Public;
    //
    // Unlike most common wrapper codeunits, this one is not a wrapper for the new codeunit, but for the old one.
    // This is because we foresee other functions from the "Format Address" being moved to individual codeunits.
    // It is considered unessesary to create a wrapper for each of them, so instead this codeunit is intended for all "Format Address" functions.
    //
    // These functions are also expected to be moved by Microsoft, and should be wrapped here:
    // * FormatAddress.SalesHeaderShipTo()
    // * FormatAddress.TransferHeaderTransferTo()
    // * FormatAddress.PurchHeaderShipTo()
    //

    /* #if BC25+ */
    internal procedure ServiceHeaderShipTo(var _AddrArray: array[8] of Text[100]; var _ServiceHeader: Record "Service Header")
    var
        ServiceFormatAddress: Codeunit "Service Format Address";
    begin
        ServiceFormatAddress.ServiceHeaderShipTo(_AddrArray, _ServiceHeader);
    end;
    /* #endif */
    /* #if BC24- ##
    internal procedure ServiceHeaderShipTo(var _AddrArray: array[8] of Text[100]; var _ServiceHeader: Record "Service Header")
    var
        FormatAddress: Codeunit "Format Address";
    begin
        FormatAddress.ServiceHeaderShipTo(_AddrArray, _ServiceHeader);
    end;
    /* #endif */
}
