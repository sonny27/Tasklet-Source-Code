page 81375 "MOB User Card"
{
    Caption = 'Mobile User Card';
    PageType = Card;
    SourceTable = "MOB User";

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';
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

            part(MobWarehouseEmployee; "MOB User Locations ListPart")
            {
                Caption = 'Warehouse Employee Locations';
                ApplicationArea = All;
                SubPageLink = "User ID" = field("User ID");
                UpdatePropagation = Both;
            }
        }
    }

    var
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
}
