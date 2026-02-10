tableextension 81308 "MOB Warehouse Activity Line" extends "Warehouse Activity Line"

// Tasklet Factory - Mobile WMS
// Output split line number
// The SplitLine function was updated so that it outputs the line number of the newly created line
// This is used when performing automated line splitting when receiving registrations from a mobile device

// Tasklet Factory - Mobile WMS
// Added boolean field "LineSplitAutomatically"
// This field is used by the automatic split functionality when posting warehouse activities to multiple bins

// Tasklet Factory - Mobile WMS
// Added Guid-field "MOBSystemId"
// Mirror new standard functionality for backwards compatbility at older platforms
// Used like (standard) SystemId to uniquely identity a line, even if line number is renumbered during SplitLine-functionality. 

// Tasklet Factory - Mobile WMS
// Added Key MOBSystemIdKey

{
    fields
    {
        field(6181271; MOBLineSplitAutomatically; Boolean)
        {
            Description = 'Mobile WMS';
            Caption = 'Line Split Automatically';
            DataClassification = CustomerContent;
        }
        field(6181272; MOBSystemId; Guid)
        {
            Description = 'Mobile WMS';
            Caption = 'MOB SystemId', Locked = true;
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(MOBSystemIdKey; MOBSystemId)
        {
        }
    }

    trigger OnInsert()
    begin
        if IsNullGuid(MOBSystemId) then
            MOBSystemId := CreateGuid();
    end;

    // See also: 
    // codeunit 6181285 "MOB Tab5767 EXT.WhseActLine"
    // [EventSubscriber(ObjectType::Table, Database::"Warehouse Activity Line", 'OnBeforeInsertNewWhseActivLine', '', true, true)]

    procedure "MOB ItemAllowWhseOverpick"(): Boolean
    var
        Item: Record Item;
    begin
        /* #if BC26+ */
        if Rec."Activity Type" <> Rec."Activity Type"::Pick then
            exit;

        if Rec."Source Document" <> Rec."Source Document"::"Prod. Consumption" then
            exit;

        if Item.Get(Rec."Item No.") then
            exit(Item."Allow Whse. Overpick");
        /* #endif */
    end;
}
