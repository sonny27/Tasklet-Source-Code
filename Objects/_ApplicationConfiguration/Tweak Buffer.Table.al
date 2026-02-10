table 81308 "MOB Tweak Buffer"
{
    Access = Public;
    Caption = 'Mobile Tweak', Locked = true;
    DataClassification = SystemMetadata;
    /* #if BC15+ */
    Extensible = false;
    /* #endif */

    fields
    {
        field(1; "File Name"; Text[250])
        {
            Caption = 'File Name', Locked = true;
            NotBlank = true;
        }
        field(10; "Sorting Id"; Integer)
        {
            Caption = 'Sorting Id', Locked = true;
        }
        field(20; Description; Text[100])
        {
            Caption = 'Description', Locked = true;
        }
        field(30; Content; Blob)
        {
            Caption = 'Content', Locked = true;
        }
        field(40; "Source Name"; Text[250])
        {
            Caption = 'Source Name', Locked = true;
        }
        field(50; "Source Version"; Text[100])
        {
            Caption = 'Source Version', Locked = true;
        }
        field(60; "Source Publisher"; Text[250])
        {
            Caption = 'Source Publisher', Locked = true;
        }
    }
    keys
    {
        key(PK; "File Name")
        {
            Clustered = true;
        }
    }

    var
        MUST_BE_TEMPORARY_Err: Label 'Internal error: %1 must be a temporary record.', Locked = true;

    internal procedure LoadTweaks()
    var
        MobApplicationConfiguration: Codeunit "MOB Application Configuration";
        MobTweakContainer: Codeunit "MOB Tweak Container";
    begin
        if not Rec.IsTemporary() then
            Error(MUST_BE_TEMPORARY_Err, Rec.TableCaption());

        // Get tweaks from the subscribers
        MobApplicationConfiguration.OnGetApplicationConfiguration_OnAddTweaks(MobTweakContainer);
        MobTweakContainer.GetTweakBuffer(Rec);
    end;

    internal procedure GetTweakName(): Text
    var
        TweakSortingIdTxt: Text;
        TweakName: Text;
    begin
        // Prefix with zeros to get a 10 character string for sorting (Long enough for max integer value)
        TweakSortingIdTxt := Format(Rec."Sorting Id").PadLeft(10, '0');

        // Create a tweak name based on the sorting id, description, source name, source publisher and source version
        TweakName := StrSubstNo('%1-%2-FROM-%3-BY-%4-v%5', TweakSortingIdTxt, Rec.Description, Rec."Source Name", Rec."Source Publisher", Rec."Source Version");

        // Max full filename on the device is 255 chars
        // The app prefixes the tweak name with "application-" and adds the hash and .cfg as suffix - a total of 49 chars
        // Example: application-0000000100-My_first_tweak-FROM-My_cool_app-BY-My_Company-v2_1_0_42-851062561D3095FE043DF8893FA65FB5.cfg
        // This leaves 206 chars for the tweak name
        exit(CopyStr(TweakName, 1, 206));
    end;

    internal procedure ShowXmlContent()
    var
        ToFile: Text[1024];
        Stream: InStream;
    begin
        Rec.CalcFields(Content);
        Rec.Content.CreateInStream(Stream);

        ToFile := Rec.Description + '.xml'; // .cfg might be more correct, but using xml makes it easier to open with formatting
        DownloadFromStream(Stream, '', '', '', ToFile);
    end;
}
