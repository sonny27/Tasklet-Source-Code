codeunit 81361 "MOB Upgrade per Database"
{
    Access = Public;
    Subtype = Upgrade;

    var
        PermissionUpgradeTagLbl: Label 'MOB Upgrade permission assignments from Tenant(Xml) to System(AL) scope', Locked = true;

    trigger OnCheckPreconditionsPerDatabase()
    // Pre  upgrade
    begin
    end;

    trigger OnUpgradePerDatabase()
    // Perform Upgrade
    begin
        /* #if BC19+ */
        UpgradePermissionSets();
        /* #endif */
    end;

    trigger OnValidateUpgradePerDatabase()
    // Post upgrade
    begin
    end;

    /* #if BC19+ */
    #region Update assignments of Permissions with Tenant Scope (from an XML file) to Permissions with System Scope (from an AL file)
    local procedure UpgradePermissionSets()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        // Check whether upgrade tag exists
        if UpgradeTag.HasUpgradeTag(PermissionUpgradeTagLbl, '') then
            exit;

        // Upgrade code
        UpgradePermissionSet('MOBWMSUSER');

        // Add the new upgrade tag using SetUpgradeTag or SetAllUpgradeTags
        UpgradeTag.SetDatabaseUpgradeTag(PermissionUpgradeTagLbl);
    end;

    local procedure UpgradePermissionSet(_PermissionSetCode: Code[20])
    var
        NewAccessControl: Record "Access Control";
        OldAccessControl: Record "Access Control";
        TempAccessControl: Record "Access Control" temporary;
        NewUserGroupPermissionSet: Record "User Group Permission Set";
        OldUserGroupPermissionSet: Record "User Group Permission Set";
        TempUserGroupPermissionSet: Record "User Group Permission Set" temporary;
        AppId: Guid;
        CurrentAppInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(CurrentAppInfo);
        AppId := CurrentAppInfo.Id();

        // Find and buffer assignments of the XML permission set to any user groups
        OldUserGroupPermissionSet.SetRange("App ID", AppId);
        OldUserGroupPermissionSet.SetRange(Scope, OldUserGroupPermissionSet.Scope::Tenant);
        OldUserGroupPermissionSet.SetRange("Role ID", _PermissionSetCode);
        if OldUserGroupPermissionSet.FindSet() then begin
            repeat
                TempUserGroupPermissionSet := OldUserGroupPermissionSet;
                TempUserGroupPermissionSet.Insert();
            until OldUserGroupPermissionSet.Next() = 0;

            // Assign the new AL permission set to the buffered user groups  (if not already assigned) and delete the assignment of the XML permission set
            TempUserGroupPermissionSet.FindSet();
            repeat
                OldUserGroupPermissionSet := TempUserGroupPermissionSet;
                OldUserGroupPermissionSet.Find();
                if NewUserGroupPermissionSet.Get(OldUserGroupPermissionSet."User Group Code", _PermissionSetCode, NewUserGroupPermissionSet.Scope::System, AppId) then
                    OldUserGroupPermissionSet.Delete()
                else
                    OldUserGroupPermissionSet.Rename(OldUserGroupPermissionSet."User Group Code", _PermissionSetCode, NewUserGroupPermissionSet.Scope::System, AppId);
            until TempUserGroupPermissionSet.Next() = 0;
        end;

        // Find and buffer assignments of the XML permission set to any users
        OldAccessControl.SetRange("App ID", AppId);
        OldAccessControl.SetRange(Scope, OldAccessControl.Scope::Tenant);
        OldAccessControl.SetRange("Role ID", _PermissionSetCode);
        if OldAccessControl.FindSet() then begin
            repeat
                TempAccessControl := OldAccessControl;
                TempAccessControl.Insert();
            until OldAccessControl.Next() = 0;
            TempAccessControl.FindSet();

            // Assign the new AL permission set to the buffered users (if not already assigned) and delete the assignment of the XML permission set
            repeat
                OldAccessControl := TempAccessControl;
                OldAccessControl.Find();
                if NewAccessControl.Get(OldAccessControl."User Security ID", _PermissionSetCode, OldAccessControl."Company Name", NewAccessControl.Scope::System, AppId) then
                    OldAccessControl.Delete()
                else
                    OldAccessControl.Rename(OldAccessControl."User Security ID", _PermissionSetCode, OldAccessControl."Company Name", NewAccessControl.Scope::System, AppId);
            until TempAccessControl.Next() = 0;
        end;

        UpgradeTenantPermissionsSetRel(_PermissionSetCode, AppId);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", 'OnGetPerDatabaseUpgradeTags', '', false, false)]
    local procedure OnGetPerDatabaseUpgradeTags(var PerDatabaseUpgradeTags: List of [Code[250]])
    begin
        PerDatabaseUpgradeTags.Add(PermissionUpgradeTagLbl);
    end;
    #endregion
    /* #endif */

    /* #if BC21+ */
    local procedure UpgradeTenantPermissionsSetRel(_PermissionSetCode: Code[20]; _AppId: Guid)
    var
        TenantPermissionSetRel: Record "Tenant Permission Set Rel.";
    begin
        // Upgrade permission sets including (or excluding) the Mobile WMS permission set
        TenantPermissionSetRel.SetRange("Related App ID", _AppId);
        TenantPermissionSetRel.SetRange("Related Scope", TenantPermissionSetRel."Related Scope"::Tenant);
        TenantPermissionSetRel.SetRange("Related Role ID", _PermissionSetCode);
        TenantPermissionSetRel.ModifyAll("Related Scope", TenantPermissionSetRel."Related Scope"::System); // "Related Scope" is not part of PK for the table
    end;
    /* #endif */
    /* #if BC20- ##
    local procedure UpgradeTenantPermissionsSetRel(_PermissionSetCode: Code[20]; _AppId: Guid)
    begin        
    end;
    /* #endif */
}
