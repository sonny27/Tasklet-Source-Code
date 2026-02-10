codeunit 81424 "MOB Print Buffer"
{
    Access = Public;
    // Stores printcommand(s) to be sent with the next mobile response

    SingleInstance = true;

    var
        PrintAddress: List of [Text];
        PrintCommand: List of [Text];

    /// <summary>
    /// Save a PrintCommand
    /// </summary>
    procedure Add(_PrintAddress: Text; _PrintCommand: Text)
    begin
        PrintAddress.Add(_PrintAddress);
        PrintCommand.Add(_PrintCommand);
    end;

    /// <summary>
    /// Read a PrintCommand
    /// </summary>
    procedure Get(_Index: Integer; var _PrintAddress: Text; var _PrintCommand: Text): Boolean
    begin
        if not (PrintAddress.Get(_Index, _PrintAddress) and
           PrintCommand.Get(_Index, _PrintCommand))
        then
            exit(false)
        else
            exit(true);
    end;

    /// <summary>
    /// Count curent number of stored PrintCommands
    /// </summary>
    procedure Count(): Integer
    begin
        exit(PrintAddress.Count());
    end;

}
