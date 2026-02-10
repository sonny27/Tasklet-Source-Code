codeunit 81300 "MOB Telemetry Logger" implements "Telemetry Logger"
//
// AppVersion 20.0.0.0 +
//

// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

/// <summary>
/// Allows 3rd party extensions to use "Telemetry" and "Feature Telemetry" codeunits.
/// Source : https://github.com/microsoft/BCTech/blob/master/samples/AppInsights/AL/FeatureTelemetry/Uptake%20sample%20extension/MyTelemetryLogger.Codeunit.al
/// Example : FeatureTelemetry.LogUsage|LogError|LogUptake
/// </summary>
{
    Access = Internal;

    procedure LogMessage(EventId: Text; Message: Text; Verbosity: Verbosity; DataClassification: DataClassification; TelemetryScope: TelemetryScope; CustomDimensions: Dictionary of [Text, Text])
    begin
        Session.LogMessage(EventId, Message, Verbosity, DataClassification, TelemetryScope, CustomDimensions);
    end;

    // For the functionality to behave as expected, there must be exactly one implementation of the "Telemetry Logger" interface registered per app publisher
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Telemetry Loggers", 'OnRegisterTelemetryLogger', '', true, true)]
    local procedure OnRegisterTelemetryLogger(var Sender: Codeunit "Telemetry Loggers")
    var
        SampleTelemetryLogger: Codeunit "MOB Telemetry Logger";
    begin
        Sender.Register(SampleTelemetryLogger);
    end;
}
