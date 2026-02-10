table 81290 "MOB PrintNode Setup"
{
    Access = Internal;
    Caption = 'Tasklet PrintNode Setup', Locked = true;

    fields
    {
#pragma warning disable LC0013 // Ignore since this is a setup table
        field(1; "Primary Key"; Code[10])
#pragma warning restore LC0013
        {
            Caption = 'Primary Key', Locked = true;
            DataClassification = CustomerContent;
        }
        field(10; Enabled; Boolean)
        {
            Caption = 'Enabled', Locked = true;
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if Rec.Enabled and IsNullGuid(Rec."API Isolated Storage Key") then
                    Error(SpecifyApiKeyErr);
            end;

        }
        /// <summary>
        /// The Isolated Storage ID of the PrintNode API key
        /// </summary>        
        field(20; "API Isolated Storage Key"; Guid)
        {
            Caption = 'API Isolated Storage Key', Locked = true;
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// Used to adjust the default number of records (currently printers) loaded from the PrintNode API (PrintNode use 100 as default)
        /// Don't use the field directly, but use the protected GetApiRecordLimit() method
        /// </summary>
        field(30; "API Record Limit"; Integer)
        {
            Caption = 'API Record Limit', Locked = true;
            DataClassification = CustomerContent;
            InitValue = 1000;
            MinValue = 0;
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }
    trigger OnModify()
    var
        MobPrintNodePrinterSettings: Record "MOB PrintNode Printer Settings";
    begin
        // Add Telemetry for disabling feature
        if xRec.Enabled and (not Rec.Enabled) then
            MobFeatureTelemetryWrapper.LogUptakeUndiscovered(MobTelemetryEventId::"Tasklet PrintNode Feature (MOB1030)");

        // Add Telemetry for Discovering the feature when enabled.
        // This is also triggered when the setup page is opened, but needed here if the feature is disabled and then re-enabled in the same page view.
        if (not xRec.Enabled) and Rec.Enabled then begin
            MobFeatureTelemetryWrapper.LogUptakeDiscovered(MobTelemetryEventId::"Tasklet PrintNode Feature (MOB1030)");

            // Add Telemetry for UptakeSetup if re-enabling the feature (LogUptakeSetup is also triggered when the first printer is inserted)
            if not MobPrintNodePrinterSettings.IsEmpty() then
                MobFeatureTelemetryWrapper.LogUptakeSetup(MobTelemetryEventId::"Tasklet PrintNode Feature (MOB1030)");
        end
    end;

    [NonDebuggable]
    internal procedure SetPrintNodeAPIKey(_PrintNodeApiKey: Text)
    begin
        if _PrintNodeApiKey = '' then begin
            if not IsNullGuid(Rec."API Isolated Storage Key") then begin
                Rec.TestField(Enabled, false);

                // Clear value
                if IsolatedStorage.Contains(Rec."API Isolated Storage Key", DataScope::Module) then
                    IsolatedStorage.Delete(Rec."API Isolated Storage Key", DataScope::Module);
                Clear(Rec."API Isolated Storage Key");
            end;

            exit;
        end;

        // Set value
        if IsNullGuid(Rec."API Isolated Storage Key") then
            Rec."API Isolated Storage Key" := CreateGuid();

        if not EncryptionEnabled() then
            IsolatedStorage.Set(Rec."API Isolated Storage Key", _PrintNodeApiKey, DataScope::Module)
        else
            IsolatedStorage.SetEncrypted(Rec."API Isolated Storage Key", _PrintNodeApiKey, DataScope::Module);
    end;

    [NonDebuggable]
    internal procedure GetPrintNodeAPIKey(): Text
    var
        PrintNodeAPIKey: Text;
    begin
        if not IsolatedStorage.Get(Rec."API Isolated Storage Key", DataScope::Module, PrintNodeAPIKey) then begin
            Clear(Rec."API Isolated Storage Key");
            Rec.Modify(false);
            exit('');
        end;

        exit(PrintNodeAPIKey);
    end;

    internal procedure GetApiRecordLimit(): Integer
    begin
        // Using "Enabled" as flag indicating the the Rec is loaded, as it must be true for the feature being available.
        if not Rec.Enabled then
            Rec.Get();

        if Rec."API Record Limit" <> 0 then
            exit(Rec."API Record Limit")
        else
            exit(1000); // Increase the default number of printers loaded from the PrintNode API from 100
    end;

    var
        MobFeatureTelemetryWrapper: Codeunit "MOB Feature Telemetry Wrapper";
        MobTelemetryEventId: Enum "MOB Telemetry Event ID";
        SpecifyApiKeyErr: Label 'Please specify the API Key before enabling Tasklet PrintNode.', Locked = true;
}
