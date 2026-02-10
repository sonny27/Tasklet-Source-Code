page 81274 "MOB Users"
{
    Caption = 'Mobile Users';
    AdditionalSearchTerms = 'Mobile Users Tasklet Configuration Device Scanner', Locked = true;
    PageType = List;
    SourceTable = "MOB User";
    UsageCategory = Administration;
    ApplicationArea = All;
    CardPageId = "MOB User Card";
    RefreshOnActivate = true;

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                field("User ID"; Rec."User ID")
                {
                    ToolTip = 'User ID for the Mobile User.';
                    ApplicationArea = All;
                    // Lookup is defined at tablelevel since platform 15 (no active code here)
                    /* #if BC14 ##
                    trigger OnLookup(var Text: Text): Boolean;
                    var
                        UserMgt: Codeunit "User Management";
                    begin
                        UserMgt.LookupUserID(Rec."User ID");
                    end;
                    /* #endif */
                }
                field("User Name"; Rec."User Name")
                {
                    ToolTip = 'User Name of the Mobile User.';
                    ApplicationArea = All;
                    DrillDown = false;
                }
                field("Language Code"; Rec."Language Code")
                {
                    ToolTip = 'Language to be used at Mobile Device this Mobile User. If no Language Code is provided, the default language (ENU) is used.';
                    ApplicationArea = All;
                }
                field("Employee No."; Rec."Employee No.")
                {
                    ToolTip = 'Specifies which Employee No. is assigned to the Mobile User. Used when handling Physical Inventory recordings on Mobile Device';
                    ApplicationArea = All;
                }
                field("Mobile Group Code"; MobUserGroupCode)
                {
                    Caption = 'Mobile Group Code';
                    ToolTip = 'Specifies the Mobile Group assigned to this user. A Mobile User can only belong to one Mobile Group at a time.';
                    ApplicationArea = All;
                    TableRelation = "MOB Group";
                    NotBlank = true;
                    ShowMandatory = true;

                    trigger OnValidate()
                    begin
                        Rec.ValidateMobileUserGroup(MobUserGroupCode);
                    end;
                }
                field("Location Count"; Rec."Location Count")
                {
                    ToolTip = 'Specifies the number of locations where this user is registered as a Warehouse Employee.';
                    ApplicationArea = All;
                    Editable = false;
                    DrillDown = true;
                    DrillDownPageId = "Warehouse Employees";
                    StyleExpr = LocationStatusStyle;
                }
                /* #if BC20+ */
                field("Profiling Enabled"; ProfilingEnabled)
                {
                    Caption = 'Profiling Enabled', Comment = 'Do not translate Profiling';
                    ToolTip = 'Sampling Profiling is enabled for the user. It can be enabled for 15 minutes and can also be enabled per document type.', Comment = 'Do not translate Sampling Profiling';
                    ApplicationArea = All;

                    trigger OnValidate()
                    var
                        MobPerfProfiler: Codeunit "MOB Perf. Profiler";
                    begin
                        MobPerfProfiler.ToggleEnabledUntil(Rec."Profiling Enabled Until", Rec.TableCaption(), Rec."User ID");
                        CurrPage.SaveRecord();
                    end;
                }
                /* #endif */
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(AddLocationsToUsers)
            {
                Caption = 'Add Locations to Users';
                ToolTip = 'Use this action to add a selection of locations for the selected mobile users. This will create warehouse employee records for the selected users.';
                ApplicationArea = All;
                Image = WarehouseSetup;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;

                trigger OnAction()
                var
                    MobUser: Record "MOB User";
                begin
                    CurrPage.SetSelectionFilter(MobUser);
                    MobUserConfig.AddLocationsToSelectedUsers(MobUser);
                    CurrPage.Update(false);
                end;

            }
            action(OpenMOBGroups)
            {
                Caption = 'Mobile Groups';
                ToolTip = 'Open the Mobile Groups page.';
                ApplicationArea = All;
                Image = Open;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                RunObject = page "MOB Groups";
                RunPageMode = Edit;
            }
        }
    }

    var
        MobUserConfig: Codeunit "MOB User Configuration";
        MobUserGroupCode: Code[10];
        LocationStatusStyle: Text[20];
        /* #if BC20+ */
        ProfilingEnabled: Boolean;
    /* #endif */

    trigger OnAfterGetRecord()
    begin
        MobUserGroupCode := Rec.GetUserGroupCode();

        LocationStatusStyle := Rec.GetLocationStatusStyle();

        /* #if BC20+ */
        ProfilingEnabled := Rec."Profiling Enabled Until" > CurrentDateTime();
        /* #endif */
    end;

    internal procedure GetSelectionFilter(): Text[1024]
    var
        MobUser: Record "MOB User";
        First: Text[65];
        Last: Text[65];
        SelectionFilter: Text[1024];
        MobUserCount: Integer;
        More: Boolean;
    begin
        CurrPage.SetSelectionFilter(MobUser);
        MobUser.SetCurrentKey("User ID");
        MobUserCount := MobUser.Count();
        if MobUserCount > 0 then begin
            MobUser.FindFirst();
            while MobUserCount > 0 do begin
                MobUserCount := MobUserCount - 1;
                MobUser.MarkedOnly(false);
                First := MobUser."User ID";
                Last := First;
                More := (MobUserCount > 0);
                while More do
                    if MobUser.Next() = 0 then
                        More := false
                    else
                        if not MobUser.Mark() then
                            More := false
                        else begin
                            Last := MobUser."User ID";
                            MobUserCount := MobUserCount - 1;
                            if MobUserCount = 0 then
                                More := false;
                        end;
                if SelectionFilter <> '' then
                    SelectionFilter := SelectionFilter + '|';
                if First = Last then
                    SelectionFilter := SelectionFilter + First
                else
                    SelectionFilter := SelectionFilter + First + '..' + Last;
                if MobUserCount > 0 then begin
                    MobUser.MarkedOnly(true);
                    MobUser.Next();
                end;
            end;
        end;
        exit(SelectionFilter);
    end;
}
