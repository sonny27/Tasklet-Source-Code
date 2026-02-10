codeunit 81400 "MOB WMS Media"
{
    Access = Public;
    TableNo = "MOB Document Queue";
    trigger OnRun()
    begin
        MobDocQueue := Rec;
        case Rec."Document Type" of

            // Respond to the request for images
            'GetMedia':
                GetMedia();

            // Import an image
            'PostMedia':
                PostMedia();

            else
                Error(MobWmsLanguage.GetMessage('NO_DOC_HANDLER'), Rec."Document Type");
        end;

        // Store the result in the queue and update the status
        MobToolbox.UpdateResult(Rec, XmlResponseDoc);
    end;

    var
        MobDocQueue: Record "MOB Document Queue";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        MobBaseDocHandler: Codeunit "MOB WMS Base Document Handler";
        MobXmlMgt: Codeunit "MOB XML Management";
        MobToolbox: Codeunit "MOB Toolbox";
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
        MobNSRequest: Codeunit "MOB NS Request Management";
        /* #if BC26+ */
        MobExternalFileUpload: Codeunit "MOB External File Upload";
        MobExternalFileDownload: Codeunit "MOB External File Download";
        /* #endif */
        XmlResponseDoc: XmlDocument;
        EmptyFileNameErr: Label 'Please choose a file to attach.';
        NoDocumentAttachedErr: Label 'Please attach a document first.';

    /// <summary>
    /// Read the "MediaIDs" from a request and respond with the images as Base64
    /// </summary>
    local procedure GetMedia()
    var
        RecRef: RecordRef;
        XmlRequestDoc: XmlDocument;
        XmlRequestDataNode: XmlNode;
        XmlImage: XmlNode;
        XmlMediaIdsNode: XmlNode;
        XmlResponseData: XmlNode;
        XmlMediaResponse: XmlNode;
        ImageNodes: XmlNodeList;
        Index: Integer;
        NewHeight: Integer;
        NewWidth: Integer;
        MediaID: Text;
        IconId: Text;
        Base64Media: Text;
        IsHandled: Boolean;
    begin
        // <?xml version="1.0" encoding="utf-8"?>
        // <request name="GetMedia" created="2020-04-08T16:37:16+02:00" xmlns="http://schemas.microsoft.com/Dynamics/Mobile/2007/04/Documents/Request">
        //   <requestData name="GetMedia">
        //     <mediaIds>
        //       <image>08-04-2020 14:37:16.999Item: TF-003</image>         
        //     </mediaIds>
        //     <screenHeight>592</screenHeight>
        //     <screenWidth>360</screenWidth>
        //   </requestData>
        // </request>

        // Load request document 
        MobDocQueue.LoadXMLRequestDoc(XmlRequestDoc);
        XmlRequestDataNode := MobNSRequest.GetRequestDataNode(XmlRequestDoc);
        //Get screen height and width 
        Evaluate(NewHeight, MobXmlMgt.FindNodeAndValue(XmlRequestDataNode, 'screenHeight', XmlMediaIdsNode));
        Evaluate(NewWidth, MobXmlMgt.FindNodeAndValue(XmlRequestDataNode, 'screenWidth', XmlMediaIdsNode));
        // Find 
        MobXmlMgt.FindNode(XmlRequestDataNode, 'mediaIds', XmlMediaIdsNode);
        XmlMediaIdsNode.SelectNodes('//*[local-name() = "image"]', ImageNodes);
        // Initialize response
        MobToolbox.InitializeRespDocWithoutNS(XmlResponseDoc, XmlResponseData);
        MobXmlMgt.AddElement(XmlResponseData, 'media', '', MobXmlMgt.GetDocNSURI(XmlResponseDoc), XmlMediaResponse);

        // Loop the request
        for Index := 1 to ImageNodes.Count() do begin
            ImageNodes.Get(Index, XmlImage);

            MediaID := MobXmlMgt.GetNodeInnerText(XmlImage);

            IsHandled := false;
            OnGetMedia_OnBeforeAddImageToMedia(MediaID, NewHeight, NewWidth, Base64Media, IsHandled);

            case true of
                IsHandled:
                    AddMediaToResponse(MediaID, Base64Media, XmlMediaResponse);
                MediaID2RecRef(MediaID, RecRef): // --- RecRef is either Item Image or Attached image (mobile photo)
                    case RecRef.Number() of
                        Database::Item:
                            AddItemImageToMedia(RecRef, XmlImage, XmlMediaResponse, NewHeight, NewWidth);
                        else
                            AddAttachedImageToMedia(RecRef, MediaID, XmlImage, XmlMediaResponse, NewHeight, NewWidth)
                    end;
                IsIconMedia(MediaID, IconId):
                    begin
                        Base64Media := GetIconAsBase64String(IconId);
                        AddMediaToResponse(MediaID, Base64Media, XmlMediaResponse);
                    end;
                else
                    Error(MobWmsLanguage.GetMessage('UNKNOWN_MEDIAID'), MediaID);

            end;
        end;
    end;

    /// <summary>
    /// Import an image
    /// </summary>
    local procedure PostMedia()
    var
        MobWmsMediaQueue: Record "MOB WMS Media Queue";
        Item: Record Item;
        MobTelemetryManagement: Codeunit "MOB Telemetry Management";
        RecRef: RecordRef;
        XmlRequestDoc: XmlDocument;
        XmlRequestNode: XmlNode;
        XmlRequestDataNode: XmlNode;
        XmlParameterNode: XmlNode;
        XmlNodesList: XmlNodeList;
        Id: Text;
        ReferenceId: Text;
        "Type": Text;
        Data: Text;
        Index: Integer;
        MediaGuid: Guid;
    begin
        // The Request Document looks like this:        
        // <requestData name="PostMedia">
        //     <Id>/storage/emulated/0/MobileWMS/2019-09-10_08-06-38-609.jpg</Id>
        //     <ReferenceId>3e71320c-7d65-40da-a27a-69c9238056ab</ReferenceId>
        //     <Type>Image</Type>
        //     <Data>xxxxxxxxx</Data>
        // </requestData>        

        // Load the request document from the document queue
        MobDocQueue.LoadXMLRequestDoc(XmlRequestDoc);

        // Extract any parameters from the XML
        // The parameters are located in the <requestData> element
        MobXmlMgt.GetDocRootNode(XmlRequestDoc, XmlRequestNode);
        MobXmlMgt.FindNode(XmlRequestNode, MobWmsToolbox."CONST::requestData"(), XmlRequestDataNode);

        // Loop over the registration values. We don't know which values will be present because it is configurable
        MobXmlMgt.GetNodeChildNodes(XmlRequestDataNode, XmlNodesList);
        for Index := 1 to XmlNodesList.Count() do begin
            MobXmlMgt.GetListItem(XmlNodesList, XmlParameterNode, (Index)); // AL = 1 based index
            case MobXmlMgt.GetNodeName(XmlParameterNode) of
                'Id':
                    Id := MobXmlMgt.GetNodeInnerText(XmlParameterNode);
                'ReferenceId':
                    ReferenceId := MobXmlMgt.GetNodeInnerText(XmlParameterNode);
                'Type':
                    Type := MobXmlMgt.GetNodeInnerText(XmlParameterNode);
                'Data':
                    Data := MobXmlMgt.GetNodeInnerText(XmlParameterNode);
            end;
        end;

        // Get the previously received Media Queue entry
        MobWmsMediaQueue.Get(Id, MobDocQueue."Device ID");

        // Get the Record the Image should be attached to
        if RecRef.Get(MobWmsMediaQueue."Target Record ID") then;

        case RecRef.Number() of
            Database::Item:
                begin
                    // Item image is imported on the Item record
                    RecRef.SetTable(Item);
                    MediaGuid := StreamBase64DataToItemImage(Item, Data, MobWmsMediaQueue.Note);
                    ImportTenantMedia(MobWmsMediaQueue, MediaGuid);
                    Item.Modify(true);
                end;
            Database::"Sales Header", Database::"Sales Line", Database::"Purchase Header", Database::"Purchase Line":
                begin
                    // Image is imported as document attachment for the source document (Header or Line)
                    MediaGuid := SaveAttachmentFromBase64(RecRef, Data, MobWmsMediaQueue."Image Id");
                    if not IsNullGuid(MediaGuid) then
                        ImportTenantMedia(MobWmsMediaQueue, MediaGuid); // Attempt to reuse the source document mediaId
                end;
        end;
        if MobWmsMediaQueue.Picture.Count() = 0 then begin
            // Save image directly on Mob Media Queue
            StreamBase64DataToMobWmsMediaQueue(MobWmsMediaQueue, Data);
            MobWmsMediaQueue.Modify(true);
        end;
        UpdateImageSizeOnDevice(MobWmsMediaQueue);

        MobTelemetryManagement.SavePostMediaDetails(MobWmsMediaQueue);

        /* #if BC26+ */
        MobExternalFileUpload.StorePictureExternally(MobWmsMediaQueue);
        /* #endif */

        MobTelemetryManagement.SavePostMediaImageStorageDetails(MobWmsMediaQueue);

        MobToolbox.CreateSimpleResponse(XmlResponseDoc, 'OK');
    end;

    //
    // -------------------------------- Item Image --------------------------------
    //

    /// <summary>
    /// Add item image as Base64 to the response 
    /// </summary>
    local procedure AddItemImageToMedia(_ItemRecRef: RecordRef; _XmlImage: XmlNode; _XmlMediaReponse: XmlNode; _NewHeight: Integer; _NewWidth: Integer)
    var
        Item: Record Item;
        Base64ImageString: Text;
    begin
        _ItemRecRef.SetTable(Item);
        GetMediaIdAsBase64String(Item.Picture.MediaId(), Base64ImageString, _NewHeight, _NewWidth);

        // Add the <image> element to the <media> element        
        MobXmlMgt.AddElement(_XmlMediaReponse, 'image', Base64ImageString, MobXmlMgt.GetDocNSURI(XmlResponseDoc), _XmlImage);
        MobXmlMgt.AddAttribute(_XmlImage, 'id', CreateItemImageID(Item));
    end;

    /// <summary>
    /// Add item image as Base64 to the response 
    /// </summary>
    local procedure AddMediaToResponse(_MediaId: Text; _Base64ImageString: Text; _XmlMediaReponse: XmlNode)
    var
        _XmlImage: XmlNode;
    begin
        // Add the <image> element to the <media> element        
        MobXmlMgt.AddElement(_XmlMediaReponse, 'image', _Base64ImageString, MobXmlMgt.GetDocNSURI(XmlResponseDoc), _XmlImage);
        MobXmlMgt.AddAttribute(_XmlImage, 'id', _MediaId);
    end;

    /// <summary>
    /// Import Item image            
    /// </summary>
    /// <returns>Media GUID</returns>
    local procedure StreamBase64DataToItemImage(var _Item: Record Item; _Base64Data: Text; _Note: Text[250]) MediaGUID: Guid
    var
        MobBase64Convert: Codeunit "MOB Base64 Convert";
        ImageInStream: InStream;
    begin
        // Remove existing image
        MediaGUID := GetItemPictureMediaSetId(_Item);
        if not IsNullGuid(MediaGUID) then
            _Item.Picture.Remove(MediaGUID);

        // Import Item image            
        MobBase64Convert.FromBase64(_Base64Data, ImageInStream);
        _Item.Picture.ImportStream(ImageInStream, _Note);
        MediaGUID := GetItemPictureMediaSetId(_Item);
    end;

    /// <summary>
    /// Item image picture points to "Tenant MediaSet"
    /// </summary>
    /// <returns>Media GUID</returns>
    local procedure GetItemPictureMediaSetId(var _Item: Record Item) MediaGUID: Guid
    var
        TenantMediaSet: Record "Tenant Media Set";
    begin
        TenantMediaSet.SetRange("Company Name", CompanyName());
        TenantMediaSet.SetRange(ID, _Item.Picture.MediaId());
        if TenantMediaSet.FindFirst() then
            MediaGUID := SelectStr(1, Format(TenantMediaSet."Media ID"));
    end;

    /// <summary>
    /// Extract the latter part, ReferenceID/RecordID from a ItemImageID
    /// I.e. "2020-04-15T12:00:14.777ZWarehouse Receipt Line: RE000005,20000"
    /// </summary>
    local procedure MediaID2RecRef(_MediaID: Text; var _ReturnRecRef: RecordRef): Boolean
    var
        PartialMediaID: Text;
    begin
        PartialMediaID := CopyStr(_MediaID, 24);
        exit(MobToolbox.ReferenceIDText2RecRef(PartialMediaID, _ReturnRecRef));
    end;

    /// <summary>
    /// Create MediaId for an Item
    /// </summary>
    procedure GetItemImageID(_ItemNo: Code[20]): Text
    var
        Item: Record Item;
        TenantMedia: Record "Tenant Media";
    begin
        if Item.Get(_ItemNo) then
            if FindTenantMedia(Item.Picture.MediaId(), TenantMedia) then // Ensure item image can be found as Tenantmedia
                exit(CreateItemImageID(Item));
    end;

    /// <summary>
    /// Create a unique ID for the App to know the Image by
    /// When it changes, the app know it has to request New image data
    /// I.e: "08-04-2020 13:24:19Item: TF-002"
    /// </summary>
    local procedure CreateItemImageID(_Item: Record Item): Text
    var
        RecRef: RecordRef;
    begin
        MobToolbox.Variant2RecRef(_Item, RecRef);
        exit(DateTime2MediaIDFormat(_Item."Last Date Modified", _Item."Last Time Modified") + Format(RecRef.RecordId()));
    end;

    //
    // -------------------------------- Attached Image --------------------------------
    //

    /// <summary>
    /// Add attached image as Base64 to the response 
    /// </summary>
    local procedure AddAttachedImageToMedia(_RecRef: RecordRef; _MediaID: Text; _XmlImage: XmlNode; _XmlMediaReponse: XmlNode; _NewHeight: Integer; _NewWidth: Integer)
    var
        MobMediaQueue: Record "MOB WMS Media Queue";
        Base64String: Text;
    begin
        // Get attached image from Media Queue
        if FindAttachedImage(_RecRef, _MediaID, MobMediaQueue) then begin

            /* #if BC26+ */
            if not GetFileFromExternalStorageAsBase64(MobMediaQueue, Base64String, _NewHeight, _NewWidth) then
                /* #endif */
                GetMediaIdAsBase64String(MobMediaQueue.Picture.MediaId(), Base64String, _NewHeight, _NewWidth);

            // Add the <image> element to the <media> element        
            MobXmlMgt.AddElement(_XmlMediaReponse, 'image', Base64String, MobXmlMgt.GetDocNSURI(XmlResponseDoc), _XmlImage);
            MobXmlMgt.AddAttribute(_XmlImage, 'id', CreateAttachedImageID(MobMediaQueue));
        end;
    end;

    /// <summary>
    /// Read an Attached Image into Stream
    /// </summary>
    local procedure FindAttachedImage(_RecRef: RecordRef; _MediaID: Text; var _MobMediaQueue: Record "MOB WMS Media Queue"): Boolean
    var
        DT: DateTime;
    begin
        _MobMediaQueue.SetRange("Record ID", _RecRef.RecordId());

        // Extract the date and time from MediaID and use it for filtering
        DT := MediaIDFormat2DateTime(_MediaID);
        _MobMediaQueue.SetRange("Created Date", DT2Date(DT));
        _MobMediaQueue.SetRange("Created Time", DT2Time(DT));

        exit(_MobMediaQueue.FindFirst());
    end;

    /// <summary>
    /// Import image            
    /// </summary>
    local procedure StreamBase64DataToMobWmsMediaQueue(var _MobWmsMediaQueue: Record "MOB WMS Media Queue"; _Base64Data: Text)
    var
        MobBase64Convert: Codeunit "MOB Base64 Convert";
        ImageInStream: InStream;
    begin
        MobBase64Convert.FromBase64(_Base64Data, ImageInStream);
        _MobWmsMediaQueue.Picture.ImportStream(ImageInStream, _MobWmsMediaQueue.Note);
    end;

    /// <summary>
    /// Create a unique ID for the App to know the attached Image by
    /// When it changes, the app know it has to request New image data
    /// I.e. 2020-04-15T12:00:14.777ZWarehouse Receipt Line: RE000005,20000
    /// </summary>
    procedure CreateAttachedImageID(_MobMediaQueue: Record "MOB WMS Media Queue"): Text
    begin
        exit(DateTime2MediaIDFormat(_MobMediaQueue."Created Date", _MobMediaQueue."Created Time") + Format(_MobMediaQueue."Record ID"));
    end;

    /// <summary>
    /// Images are attached to this RecordId  
    /// </summary>
    internal procedure RecordIDHasAttachment(_RecordId: RecordId): Boolean
    var
        MobMediaQueue: Record "MOB WMS Media Queue";
    begin
        MobMediaQueue.SetCurrentKey("Record ID");
        MobMediaQueue.SetRange("Record ID", _RecordId);
        exit(not MobMediaQueue.IsEmpty())
    end;

    // -------------------------------- Mobile Icon --------------------------------

    local procedure IsIconMedia(_MediaID: Text; var _IconId: Text): Boolean
    var
        MobGetMediaDeviceIcon: Codeunit "MOB GetMedia-DeviceIcon";
    begin
        /* #if BC26+ */
        exit(MobGetMediaDeviceIcon.IsMediaAnIcon(_MediaID, _IconId));
        /* #endif */

        /* #if BC25- ##
        exit(false);
        /* #endif */
    end;

    local procedure GetIconAsBase64String(_IconId: Text): Text
    var
        MobGetMediaDeviceIcon: Codeunit "MOB GetMedia-DeviceIcon";
    begin
        /* #if BC26+ */
        exit(MobGetMediaDeviceIcon.GetIconMediaAsBase64(_IconId));
        /* #endif */
    end;

    // -------------------------------- Helper functions --------------------------------
    //

    /// <summary>
    /// Add an image to the Mob Wms Media queue
    /// </summary>
    procedure AddImageToMediaQueue(_RecRelatedVariantOrReferenceIDText: Variant; _ImageIdsAndNotes: Text): Text
    var
        MobWmsMediaQueue: Record "MOB WMS Media Queue";
        MOBSessionData: Codeunit "MOB SessionData";
        TargetRecId: RecordId;
        ImageList: List of [Text];
        ImageAndNoteList: List of [Text];
        ReferenceIDText: Text;
    begin
        MobWmsMediaQueue.Init();

        ImageList := _ImageIdsAndNotes.Split('§');
        if ImageList.Contains('') then exit;

        foreach _ImageIdsAndNotes in ImageList do begin
            ImageAndNoteList := _ImageIdsAndNotes.Split(';');
            ImageAndNoteList.Get(1, MobWmsMediaQueue."Image Id");
            ImageAndNoteList.Get(2, MobWmsMediaQueue.Note);
            MobWmsMediaQueue."Device ID" := MOBSessionData.GetDeviceID();

            ReferenceIDText := MobWmsToolbox.GetReferenceID(_RecRelatedVariantOrReferenceIDText);
            if ReferenceIDText <> '' then begin
                Evaluate(MobWmsMediaQueue."Record ID", ReferenceIDText);
                MobWmsMediaQueue.Description := Format(MobWmsMediaQueue."Record ID");
            end else begin
                // If _ReferenceID is missing, then use the current record as the RecordID
                MobWmsMediaQueue."Record ID" := MobWmsMediaQueue.RecordId();
                MobWmsMediaQueue.Description := Format(MobWmsMediaQueue."Record ID");
            end;
            GetMediaTargetRecordId(MobWmsMediaQueue, TargetRecId);
            MobWmsMediaQueue."Target Record ID" := TargetRecId;
            MobWmsMediaQueue.Insert(true);
        end;
    end;

    procedure AddImageToMediaQueue(_ImageIdsAndNotes: Text): Text
    var
        DummyReferenceIDText: Text;
    begin
        exit(AddImageToMediaQueue(DummyReferenceIDText, _ImageIdsAndNotes));
    end;

    /* #if BC26+ */
    /// <summary>
    /// If the image file is stored externally, it will be retrieved from the external storage as a stream.
    /// Image is then scaled to the specified height and width, converted to Base64, and returned.
    /// </summary>
    local procedure GetFileFromExternalStorageAsBase64(_MobMediaQueue: Record "MOB WMS Media Queue"; var _Base64String: Text; _NewHeight: Integer; _NewWidth: Integer): Boolean
    var
        ImageStream: InStream;
    begin
        if not MobExternalFileDownload.GetFileFromExternalStorageAsStream(_MobMediaQueue, ImageStream) then
            exit(false);

        _Base64String := ScaleAndConvertStreamToBase64(ImageStream, _NewHeight, _NewWidth);
        exit(true);
    end;
    /* #endif */

    /// <summary>
    /// Read an MediaID image into Stream
    /// Resize it to screen height and width
    /// convert to Base64
    /// </summary>
    local procedure GetMediaIdAsBase64String(_MediaId: Text; var _Base64String: Text; _NewHeight: Integer; _NewWidth: Integer)
    var
        TenantMedia: Record "Tenant Media";
        ImageStream: InStream;
    begin
        if not FindTenantMedia(_MediaId, TenantMedia) then
            exit;

        TenantMedia.Content.CreateInStream(ImageStream);

        _Base64String := ScaleAndConvertStreamToBase64(ImageStream, _NewHeight, _NewWidth);
    end;

    /// <summary>
    /// Resize image stream to screen height and width
    /// Convert to Base64
    /// </summary>
    local procedure ScaleAndConvertStreamToBase64(var _ImageStream: InStream; _NewHeight: Integer; _NewWidth: Integer) Base64String: Text
    var
        /* #if BC14 ##
        TempBlob: Record TempBlob;
        /* #endif */
        /* #if BC15+ */
        TempBlob: Codeunit "Temp Blob";
        /* #endif */
        ImageHandlerMgt: Codeunit "Image Handler Management";
        MobBase64Convert: Codeunit "MOB Base64 Convert";
        ScaledImageOutStream: OutStream;
        ScaledImageInStream: InStream;
    begin
        /* #if BC14 ##
        TempBlob.Blob.CreateOutStream(ScaledImageOutStream);
        ImageHandlerMgt.ScaleDown(_ImageStream, ScaledImageOutStream, _NewWidth, _NewHeight);
        TempBlob.Blob.CreateInStream(ScaledImageInStream);
        /* #endif */

        /* #if BC15+ */
        TempBlob.CreateOutStream(ScaledImageOutStream);
        ImageHandlerMgt.ScaleDown(_ImageStream, ScaledImageOutStream, _NewWidth, _NewHeight);
        TempBlob.CreateInStream(ScaledImageInStream);
        /* #endif */

        // Convert to Base64
        Base64String := MobBase64Convert.ToBase64(ScaledImageInStream);
    end;

    internal procedure FindTenantMedia(_MediaId: Text; var TenantMedia: Record "Tenant Media"): Boolean
    var
        TenantMediaSet: Record "Tenant Media Set";
        MediaGuid: Guid;
    begin
        if IsNullGuid(_MediaId) then
            exit;

        TenantMediaSet.SetRange("Company Name", CompanyName());
        TenantMediaSet.SetRange(ID, _MediaId);
        if not TenantMediaSet.FindFirst() then
            exit;

        // Select the Image
        MediaGuid := SelectStr(1, Format(TenantMediaSet."Media ID"));

        // Get media
        TenantMedia.SetRange("Company Name", CompanyName());
        TenantMedia.SetRange(ID, MediaGuid);
        TenantMedia.SetAutoCalcFields(Content);
        if TenantMedia.FindFirst() then
            if TenantMedia."Mime Type".Contains('image/') then
                exit((TenantMedia.Width > 0) and (TenantMedia.Height > 0));
    end;

    /// <summary>
    /// Export image file from Media Queue
    /// </summary>
    internal procedure ExportImageFile(_MobWmsMediaQueue: Record "MOB WMS Media Queue")
    var
        FileManagement: Codeunit "File Management";
    begin
        /* #if BC26+ */
        if MobExternalFileDownload.DownloadFileFromExternalStorage(_MobWmsMediaQueue) then
            exit;
        /* #endif */
        ExportTenantMedia(_MobWmsMediaQueue.Picture.MediaId(), FileManagement.GetFileName(_MobWmsMediaQueue."Image Id"));
    end;

    /// <summary>
    /// Export Media from Media Queue
    /// </summary>
    local procedure ExportTenantMedia(_TenantMediaId: Guid; _ToFileName: Text)
    var
        TenantMedia: Record "Tenant Media";
        ImageStream: InStream;
    begin
        if not FindTenantMedia(_TenantMediaId, TenantMedia) then
            exit;

        // Export
        TenantMedia.Content.CreateInStream(ImageStream);
        DownloadFromStream(ImageStream, '', '', '', _ToFileName);
    end;

    /// <summary>
    /// Import Media to Media Queue
    /// </summary>
    local procedure ImportTenantMedia(var _MobWmsMediaQueue: Record "MOB WMS Media Queue"; _MediaGuid: Guid)
    begin
        if IsNullGuid(_MediaGuid) then
            exit;

        // Replace existing media
        Clear(_MobWmsMediaQueue.Picture);
        _MobWmsMediaQueue.Picture.Insert(_MediaGuid);
        _MobWmsMediaQueue.Modify(true);
    end;

    /// <summary>
    /// Updates the fields "Latest Image Height" and "Latest Image Width" on the Device record if the values differ from the newly created Tenant Media. 
    /// </summary>
    /// <param name="_MobWmsMediaQueue"></param>
    local procedure UpdateImageSizeOnDevice(_MobWmsMediaQueue: Record "MOB WMS Media Queue")
    var
        TenantMedia: Record "Tenant Media";
        MobDevice: Record "MOB Device";
    begin
        if not TenantMedia.Get(_MobWmsMediaQueue.Picture.Item(1)) then
            exit;
        if not MobDevice.Get(_MobWmsMediaQueue."Device ID") then
            exit;
        if (MobDevice."Latest Image Height" = TenantMedia.Height) and (MobDevice."Latest Image Width" = TenantMedia.Width) then
            exit;
        MobDevice."Latest Image Height" := TenantMedia.Height;
        MobDevice."Latest Image Width" := TenantMedia.Width;
        MobDevice.Modify(true);
    end;

    /// <summary>
    /// Attaches image to source Documment or Line
    /// </summary>
    local procedure SaveAttachmentFromBase64(_RecRef: RecordRef; _Base64Data: Text; _FileName: Text) ReturnMediaId: Guid
    var
        DocumentAttachment: Record "Document Attachment";
        MobCommonMgt: Codeunit "MOB Common Mgt.";
        MobBase64Convert: Codeunit "MOB Base64 Convert";
        ImageInStream: InStream;
    begin
        MobBase64Convert.FromBase64(_Base64Data, ImageInStream);
        MobCommonMgt.SaveAttachmentFromStream(DocumentAttachment, ImageInStream, _RecRef, _FileName);
        ReturnMediaId := DocumentAttachment."Document Reference ID".MediaId();
    end;

    /// <summary>
    /// Returns the record id that is the target for the image/media - Target Record Id will be used when PostMedia is handled.
    /// </summary>
    local procedure GetMediaTargetRecordId(var _MobWmsMediaQueue: Record "MOB WMS Media Queue"; var TargetRecId: RecordId)
    var
        RecRef: RecordRef;
        SourceRecRef: RecordRef;
    begin
        if not RecRef.Get(_MobWmsMediaQueue."Record ID") then begin
            TargetRecId := _MobWmsMediaQueue.RecordId();
            exit;
        end;

        case true of
            RecRef.Number() = Database::Item:
                TargetRecId := RecRef.RecordId();
            MobBaseDocHandler.GetSourceDocOrLine(RecRef, SourceRecRef): // Target is the source sales or purchase header or line.
                TargetRecId := SourceRecRef.RecordId();
            else
                TargetRecId := _MobWmsMediaQueue.RecordId();
        end;
    end;

    /// <summary>
    /// Convert Date and Time to MediaID format i.e. "24-12-2020 11:22:33.444Item: TF-003"
    /// </summary>    
    local procedure DateTime2MediaIDFormat(_Date: Date; _Time: Time) _ReturnValue: Text
    var
        Thousands: Text;
    begin
        _ReturnValue := MobToolbox.DateTime2TextResponseFormat(CreateDateTime(_Date, _Time));

        // Pad thousands so ".44"=".440", ".111"=".111" and always fixed 3 char length
        Thousands := Format(_Time, 0, '<Second dec>');
        _ReturnValue += '.' + PadStr(CopyStr(Thousands, 2), 3, '0');
    end;

    /// <summary>
    /// Convert Media ID Format (dd-MM-yyyy mm:hh:ss.xxx) formatted datetime-value to DateTime
    /// </summary>    
    local procedure MediaIDFormat2DateTime(_MediaID: Text) _ReturnValue: DateTime
    var
        TempDate: Date;
        TempTime: Time;
    begin
        // Convert date
        TempDate := MobToolbox.Text2Date(CopyStr(_MediaID, 1, 10));

        // Convert "mm:hh:ss.xxx" to time (make sure ".44"=".440")
        if Evaluate(TempTime, CopyStr(_MediaID, 12, 12)) then
            _ReturnValue := CreateDateTime(TempDate, TempTime);
    end;

    //
    // Cloned procedures for backwards compatibility with BC14.
    // Only used from BC14 builds (callback from MobCommonMgt)
    //

    /// <summary>
    /// Use MobCommonMgt.SaveAttachmentFromStream()
    /// Clone of "Document Attachment".SaveAttachmentFromStream() (function do not exist in BC14)
    /// Callback from MobCommonMgt for BC14, newer versions are using standard code
    /// </summary>
    internal procedure SaveAttachmentFromStream14(var _DocumentAttachment: Record "Document Attachment"; DocStream: InStream; RecRef: RecordRef; FileName: Text)
    begin
        if FileName = '' then
            Error(EmptyFileNameErr);

        InsertAttachment14(_DocumentAttachment, DocStream, RecRef, FileName);
    end;

    /// <summary>
    /// Used internally for SaveAttachmentFromStream()
    /// Clone of "Document Attachment".InsertAttachment(), rewritten (function do not exist in BC14)
    /// Callback from MobCommonMgt.SaveAttachmentFromStream() for BC14, newer versions are using standard code
    /// </summary>
    local procedure InsertAttachment14(var _DocumentAttachment: Record "Document Attachment"; DocStream: InStream; RecRef: RecordRef; FileName: Text)
    var
        FileManagement: Codeunit "File Management";
    begin
        _DocumentAttachment.Validate("File Extension", FileManagement.GetExtension(FileName));
        _DocumentAttachment.Validate("File Name", CopyStr(FileManagement.GetFileNameWithoutExtension(FileName), 1, MaxStrLen(_DocumentAttachment."File Name")));

        // IMPORTSTREAM(stream,description, mime-type,filename)
        // description and mime-type are set empty and will be automatically set by platform code from the stream
        _DocumentAttachment."Document Reference ID".ImportStream(DocStream, '');
        if not _DocumentAttachment."Document Reference ID".HasValue() then
            Error(NoDocumentAttachedErr);

        InitAttachmentFieldsFromRecRef14(_DocumentAttachment, RecRef);

        // Note: Do not correctly set "File Extension" / "File Name" from Insert triggger, as internal global "IncomingFileName" is blank
        // Is handled above at the top of this function
        _DocumentAttachment.Insert(true);
    end;

    /// <summary>
    /// Used internally for SaveAttachmentFromStream()
    /// Clone of "Document Attachment".InitFieldsFromRecRef(), rewritten (function do not exist in BC14)
    /// Callback from MobCommonMgt for BC14, newer versions are using standard code
    /// </summary>
    local procedure InitAttachmentFieldsFromRecRef14(var _DocumentAttachment: Record "Document Attachment"; RecRef: RecordRef)
    var
        FieldRef: FieldRef;
        RecNo: Code[20];
        DocType: Option Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order";
        LineNo: Integer;
    begin
        _DocumentAttachment.Validate("Table ID", RecRef.Number());

        case RecRef.Number() of
            Database::Customer,
            Database::Vendor,
            Database::Item,
            Database::Employee,
            Database::"Fixed Asset",
            Database::Resource,
            Database::Job:
                begin
                    FieldRef := RecRef.Field(1);
                    RecNo := FieldRef.Value();
                    _DocumentAttachment.Validate("No.", RecNo);
                end;
        end;

        case RecRef.Number() of
            Database::"Sales Header",
            Database::"Purchase Header",
            Database::"Sales Line",
            Database::"Purchase Line":
                begin
                    FieldRef := RecRef.Field(1);
                    DocType := FieldRef.Value();
                    _DocumentAttachment.Validate("Document Type", DocType);

                    FieldRef := RecRef.Field(3);
                    RecNo := FieldRef.Value();
                    _DocumentAttachment.Validate("No.", RecNo);
                end;
        end;

        case RecRef.Number() of
            Database::"Sales Line",
            Database::"Purchase Line":
                begin
                    FieldRef := RecRef.Field(4);
                    LineNo := FieldRef.Value();
                    _DocumentAttachment.Validate("Line No.", LineNo);
                end;
        end;

        case RecRef.Number() of
            Database::"Sales Invoice Header",
            Database::"Sales Cr.Memo Header",
            Database::"Purch. Inv. Header",
            Database::"Purch. Cr. Memo Hdr.":
                begin
                    FieldRef := RecRef.Field(3);
                    RecNo := FieldRef.Value();
                    _DocumentAttachment.Validate("No.", RecNo);
                end;
        end;

        case RecRef.Number() of
            Database::"Sales Invoice Line",
            Database::"Sales Cr.Memo Line",
            Database::"Purch. Inv. Line",
            Database::"Purch. Cr. Memo Line":
                begin
                    FieldRef := RecRef.Field(3);
                    RecNo := FieldRef.Value();
                    _DocumentAttachment.Validate("No.", RecNo);

                    FieldRef := RecRef.Field(4);
                    LineNo := FieldRef.Value();
                    _DocumentAttachment.Validate("Line No.", LineNo);
                end;
        end;
    end;

    /// <summary>
    /// Publisher to allow extensions to handle unknown MediaIds - like icons used for actions
    /// </summary>
    /// <param name="_MediaID">The MediaId used in the application.cfg or tweak file. Should be prefixed or suffixed with tag used by extension.</param>
    /// <param name="_ScreenHeight">The screen height of the device.</param>
    /// <param name="_ScreenWidth">The screen width of the device.</param>
    /// <param name="_Base64Media">The PNG media base64 encoded.</param>
    /// <param name="_IsHandled">True if the subscriber provides a media for the MediaId - otherwise unchanged</param>
    [IntegrationEvent(false, false)]
    local procedure OnGetMedia_OnBeforeAddImageToMedia(_MediaID: Text; _ScreenHeight: Integer; _ScreenWidth: Integer; var _Base64Media: Text; var _IsHandled: Boolean)
    begin
    end;
}
