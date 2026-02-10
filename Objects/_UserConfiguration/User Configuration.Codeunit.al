codeunit 81367 "MOB User Configuration"
{
    Access = Public;
    Permissions =
        tabledata "MOB User" = ri,
        tabledata "Warehouse Employee" = ri,
        tabledata Location = r;

    /// <summary>
    /// Adds the selected users as warehouse employees for the selected locations.
    /// </summary>
    /// <param name="_SelectedMobUsers"></param>
    internal procedure AddLocationsToSelectedUsers(var _SelectedMobUsers: Record "MOB User")
    var
        SelectedLocationsFilter: Text;
    begin
        if _SelectedMobUsers.IsEmpty() then
            exit;

        SelectedLocationsFilter := SelectMultipleLocations();
        if SelectedLocationsFilter = '' then
            exit;

        CreateWhseEmployees(_SelectedMobUsers, SelectedLocationsFilter);
    end;

    local procedure SelectMultipleLocations(): Text
    /* #if BC24+ */
    var
        Location: Record Location;
    begin
        exit(Location.SelectMultipleLocations())
    end;
    /* #endif */
    /* #if BC23- ##
    var
        LocationToSelect: Record Location;
        LocationList: Page "Location List";
    begin
        LocationToSelect.SetRange("Use As In-Transit", false);
        LocationList.SetTableView(LocationToSelect);
        LocationList.LookupMode(true);
        if LocationList.RunModal() = Action::LookupOK then
            exit(LocationList.GetSelectionFilter());
    end;
    /* #endif */

    local procedure CreateWhseEmployees(var _SelectedMobUsers: Record "MOB User"; _SelectedLocationsFilter: Text)
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        Location.SetFilter(Code, _SelectedLocationsFilter);

        if _SelectedMobUsers.FindSet() then
            repeat
                if Location.FindSet() then
                    repeat
                        WarehouseEmployee.Init();
                        WarehouseEmployee."User ID" := CopyStr(_SelectedMobUsers."User ID", 1, MaxStrLen(WarehouseEmployee."User ID"));
                        WarehouseEmployee."Location Code" := Location.Code;
                        if WarehouseEmployee.Insert(false) then; // Ignore error if already exists
                    until Location.Next() = 0;
            until _SelectedMobUsers.Next() = 0;
    end;
}
