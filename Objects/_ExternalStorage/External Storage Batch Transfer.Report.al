report 81277 "MOB Ext.Storage Batch Transfer"
{
    /* #if BC19+ */
    Extensible = false;
    /* #endif */

    /* #if BC26+ */
    Caption = 'Transfer existing images to external storage';
    ProcessingOnly = true;
    DataAccessIntent = ReadWrite;
    UsageCategory = None;
    ApplicationArea = All;
    Permissions =
        tabledata "MOB WMS Media Queue" = r;

    dataset
    {
        dataitem(MobWmsMediaQueue; "MOB WMS Media Queue")
        {
            DataItemTableView = where("Ext. File Name" = filter(''));
            RequestFilterFields = "Created Date", "Created Time", "Device ID";

            trigger OnPreDataItem()
            begin
                MobExternalFileUpload.InitializeBatchTransfer();
            end;

            trigger OnAfterGetRecord()
            begin
                if MobExternalFileUpload.StorePictureExternally(MobWmsMediaQueue) then begin
                    CommitCounter += 1;
                    TotalCounter += 1;
                end;
                if CommitCounter = 100 then begin
                    CommitCounter := 0;
                    Commit(); // Commit in batches to save progress if some error occurs
                end;
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                group(InformationGroup)
                {
                    ShowCaption = false;

                    field(Instruction1; Instruction1Lbl)
                    {
                        ShowCaption = false;
                        MultiLine = true;
                    }
                    field(Instruction2; Instruction2Lbl)
                    {
                        ShowCaption = false;
                        MultiLine = true;
                    }
                    field(Instruction3; Instruction3Lbl)
                    {
                        ShowCaption = false;
                        MultiLine = true;
                    }
                }
            }
        }
    }

    trigger OnPostReport()
    begin
        ProcessingDoneMessage();
    end;

    local procedure ProcessingDoneMessage()
    begin
        if GuiAllowed() then
            Message(ProcessingDoneMsg, TotalCounter);
    end;

    var
        MobExternalFileUpload: Codeunit "MOB External File Upload";
        CommitCounter: Integer;
        TotalCounter: Integer;
        ProcessingDoneMsg: Label 'Processing completed. Total images transferred: %1', Comment = '%1 = Number of images transferred';
        Instruction1Lbl: Label 'This report processes the Mobile WMS Media Queue and transfers images from Tenant Media to external storage. The images are transferred one by one, and the process might take a while if there are many images to transfer.';
        Instruction2Lbl: Label 'We recommend scheduling this report to run during off-peak hours to minimize the impact on users and system performance. The report will then run in the background via a Job Queue Entry.';
        Instruction3Lbl: Label 'You can also use filters to limit the number of Mobile WMS Media Queue entries to process.';
    /* #endif */
}
