codeunit 81385 "MOB WMS Online Search"
{
    Access = Public;

    TableNo = "MOB Document Queue";

    trigger OnRun()
    begin
        MobDocQueue := Rec;

        case Rec."Document Type" of

            'Search':
                Search();

            else
                Error(MobWmsLanguage.GetMessage('NO_DOC_HANDLER'), Rec."Document Type");
        end;

        // Store the result in the queue and update the status
        MobToolbox.UpdateResult(Rec, XmlResponseDoc);
    end;

    var
        MobDocQueue: Record "MOB Document Queue";
        MobSessionData: Codeunit "MOB SessionData";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        MobXmlMgt: Codeunit "MOB XML Management";
        MobToolbox: Codeunit "MOB Toolbox";
        XmlResponseDoc: XmlDocument;

    local procedure Search()
    var
        TempRequestValues: Record "MOB NS Request Element" temporary;
        TempSearchResponse: Record "MOB NS SearchResult Element" temporary;
        MobRequestMgt: Codeunit "MOB NS Request Management";
        XmlRequestDoc: XmlDocument;
        XmlResponseDataNode: XmlNode;
        SearchType: Text[50];
        IsHandled: Boolean;
    begin
        // <?xml version="1.0" encoding="utf-8"?>
        // <request name="Search" created="2023-07-27T08:49:39+02:00" xmlns="http://schemas.microsoft.com/Dynamics/Mobile/2007/04/Documents/Request">
        //    <requestData name="Search">
        //       <Type>ItemSearch</Type>
        //       <parameters xmlns="http://schemas.taskletfactory.com/MobileWMS/SearchParameters">
        //         <add id="1" name="ItemNo" value="TF-003" />
        //         <add id="2" name="ItemDescription" value="" />
        //         <add id="3" name="ItemCategory" value="" />
        //       </parameters>
        //   </requestData>
        // </request>

        // Load the request document from the document queue
        MobDocQueue.LoadXMLRequestDoc(XmlRequestDoc);

        // Read mandatory Type and filters to process
        SearchType := MobRequestMgt.GetSearchType(XmlRequestDoc);
        MobRequestMgt.SaveSearchRequestValues(XmlRequestDoc, TempRequestValues);

        // SearchType is logged in Registration Type field
        MobSessionData.SetRegistrationType(SearchType);

        // Event
        IsHandled := false;
        OnSearchOnCustomSearchType(MobSessionData.GetPostingMessageId(), SearchType, TempRequestValues, TempSearchResponse, IsHandled);

        if not IsHandled then
            case SearchType of
                'ItemSearch':
                    begin
                        ItemSearch(TempRequestValues, TempSearchResponse);
                        IsHandled := true;
                    end;
                'BinSearch':
                    begin
                        BinSearch(TempRequestValues, TempSearchResponse);
                        IsHandled := true;
                    end;
            end;

        if not IsHandled then
            Error(MobWmsLanguage.GetMessage('NO_DOC_HANDLER'), 'Type::' + SearchType);

        MobToolbox.InitializeResponseDoc(XmlResponseDoc, XmlResponseDataNode);
        AddSearchResponseElements(SearchType, XmlResponseDataNode, TempSearchResponse);
    end;

    local procedure AddSearchResponseElements(_SearchType: Text; var _XmlResponseDataNode: XmlNode; var _SearchResponseElement: Record "MOB NS SearchResult Element")
    var
        CursorMgt: Codeunit "MOB Cursor Management";
        XmlSearchResultElement: XmlElement;
        XmlCreatedNode: XmlNode;
    begin
        // store current cursor and sorting, then set default sorting to be used for the export
        CursorMgt.Backup(_SearchResponseElement);

        SetCurrentKeyOnAnySearchType(_SearchType, _SearchResponseElement);
        if _SearchResponseElement.FindSet() then
            repeat
                XmlSearchResultElement := XmlElement.Create('SearchResult', MobXmlMgt.NS_SEARCHRESULT());
                MobXmlMgt.AddNsSearchResultElement2XmlElement(XmlSearchResultElement, _SearchResponseElement, XmlCreatedNode);
                _XmlResponseDataNode.AsXmlElement().Add(XmlSearchResultElement);
            until _SearchResponseElement.Next() = 0;

        // restore cursor and sorting
        CursorMgt.Restore(_SearchResponseElement);
    end;

    local procedure SetCurrentKeyOnAnySearchType(_SearchType: Text; var _SearchResponseElement: Record "MOB NS SearchResult Element")
    var
        TempSearchResponseElementView: Record "MOB NS SearchResult Element" temporary;
    begin
        // set sorting to be used for the export
        _SearchResponseElement.SetCurrentKey("Sorting1 (internal)", "Sorting2 (internal)", "Sorting3 (internal)", "Sorting4 (internal)", "Sorting5 (internal)");

        TempSearchResponseElementView.SetView(_SearchResponseElement.GetView());
        OnSearchOnAnySearchType_OnAfterSetCurrentKey(_SearchType, TempSearchResponseElementView);
        _SearchResponseElement.SetView(TempSearchResponseElementView.GetView());
    end;

    local procedure ItemSearch(var _RequestValues: Record "MOB NS Request Element"; var _SearchResponse: Record "MOB NS SearchResult Element")
    var
        Item: Record Item;
        ItemNo: Text;
        ItemDescription: Text;
        ItemCategory: Text;
    begin
        ItemNo := _RequestValues.Get_ItemNo();
        ItemDescription := _RequestValues.Get_ItemDescription();
        ItemCategory := _RequestValues.Get_ItemCategory();

        Item.Reset();

        if ItemNo <> '' then
            Item.SetFilter("No.", '%1', ItemNo + '*');

        if ItemDescription <> '' then
            Item.SetFilter("Search Description", '%1', '*' + ItemDescription + '*');

        if ItemCategory <> '' then
            Item.SetRange("Item Category Code", ItemCategory);

        OnSearchOnItemSearch_OnSetFilterItem(_RequestValues, Item);

        if Item.FindSet() then
            repeat
                _SearchResponse.Create();
                SetFromItemSearch(Item, _SearchResponse);
                _SearchResponse.Save();
            until Item.Next() = 0;
    end;

    local procedure SetFromItemSearch(_Item: Record Item; var _SearchResponse: Record "MOB NS SearchResult Element")
    begin
        _SearchResponse.Init();
        _SearchResponse.Set_IdValue(_Item."No.");
        _SearchResponse.Set_Name(_Item."No.");
        _SearchResponse.Set_DisplayLine1(_Item."No.");
        _SearchResponse.Set_DisplayLine2(_Item.Description);
        _SearchResponse.Set_DisplayLine3(_Item."Description 2");
        _SearchResponse.Set_ReferenceID(_Item);

        OnSearchOnItemSearch_OnAfterSetFromItem(_Item, _SearchResponse);
    end;

    local procedure BinSearch(var _RequestValues: Record "MOB NS Request Element"; var _SearchResponse: Record "MOB NS SearchResult Element")
    var
        Bin: Record Bin;
        Location: Text;
    begin
        Location := _RequestValues.Get_Location();

        Bin.Reset();
        if Location <> '' then
            Bin.SetRange("Location Code", Location);

        OnSearchOnBinSearch_OnSetFilterBin(_RequestValues, Bin);

        if Bin.FindFirst() then
            repeat
                _SearchResponse.Create();
                SetFromBinSearch(Bin, _SearchResponse);
                _SearchResponse.Save();
            until Bin.Next() = 0;
    end;

    local procedure SetFromBinSearch(_Bin: Record Bin; var _SearchResponse: Record "MOB NS SearchResult Element")
    begin
        _SearchResponse.Init();
        _SearchResponse.Set_IdValue(_Bin.Code);
        _SearchResponse.Set_Name(_Bin.Code);
        _SearchResponse.Set_DisplayLine1(_Bin.Code);
        _SearchResponse.Set_DisplayLine2(_Bin.Description);
        _SearchResponse.Set_DisplayLine3(_Bin.Empty, _Bin.FieldCaption(Empty), '');
        _SearchResponse.Set_ReferenceID(_Bin);

        OnSearchOnBinSearch_OnAfterSetFromBin(_Bin, _SearchResponse);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSearchOnAnySearchType_OnAfterSetCurrentKey(_SearchType: Text; var _SearchResponseElementView: Record "MOB NS SearchResult Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSearchOnCustomSearchType(_MessageId: Guid; _SearchType: Text; var _RequestValues: Record "MOB NS Request Element"; var _SearchResponseElement: Record "MOB NS SearchResult Element"; var _IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSearchOnItemSearch_OnSetFilterItem(var _RequestValues: Record "MOB NS Request Element"; var _Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSearchOnItemSearch_OnAfterSetFromItem(_Item: Record Item; var _SearchResponseElement: Record "MOB NS SearchResult Element")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSearchOnBinSearch_OnSetFilterBin(var _RequestValues: Record "MOB NS Request Element"; var _Bin: Record Bin)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSearchOnBinSearch_OnAfterSetFromBin(_Bin: Record Bin; var _SearchResponseElement: Record "MOB NS SearchResult Element")
    begin
    end;

}
