codeunit 81408 "MOB GetMedia-DeviceIcon"
{
    Access = Internal;
    /* #if BC26+ */

    /// <summary>
    /// Searches for the incomming MediaId in the list of icons (Device Icon enum)
    /// </summary>
    /// <param name="_MediaId">The MediaId to search for</param>
    /// <param name="_IconId">Returns the found IconId (enum name), if any</param>
    /// <returns>True if the MediaId corresponds to an icon, otherwise false</returns>
    internal procedure IsMediaAnIcon(_MediaId: Text; var _IconId: Text): Boolean
    begin
        _IconId := _MediaId.ToLower(); // Normalize to lower case for enum name comparison (enum names are lower case)
        if Enum::"MOB Device Icon".Names().Contains(_IconId) then
            exit(true);
        if not GetIdFromCfgImageFileName(_IconId) then // Sometimes the incoming MediaId is the file name from application.cfg and not the image id
            exit(false);
        if Enum::"MOB Device Icon".Names().Contains(_IconId) then
            exit(true);
        exit(false);
    end;

    /// <summary>
    /// Retrieves the icon media as a Base64-encoded string
    /// </summary>
    /// <param name="_IconId">The IconId (enum name) to retrieve</param>
    /// <returns>Base64-encoded string representation of the icon image, or empty if icon not found</returns>
    internal procedure GetIconMediaAsBase64(_IconId: Text): Text
    var
        DeviceIcon: Enum "MOB Device Icon";
    begin
        if GetIconEnum(_IconId, DeviceIcon) then
            exit(GetIconAsBase64(_IconId, DeviceIcon));
    end;

    local procedure GetIconAsBase64(_IconId: Text; _DeviceIcon: Enum "MOB Device Icon"): Text
    var
        Base64Convert: Codeunit "Base64 Convert";
        ImageStream: InStream;
        ResourceFileNotFoundErr: Label 'The retrieval of icon %1 was not possible (file %2 not found).', Locked = true, Comment = '%1 = Icon Name, %2 = Resource File Name';
        ResourceList: List of [Text];
        ResourceFileName: Text;
    begin
        ResourceFileName := Format(_DeviceIcon, 0, 0); // Enum caption must be resource name/filepath
        ResourceList := NavApp.ListResources('icons/*');
        if not ResourceList.Contains(ResourceFileName) then
            Error(ResourceFileNotFoundErr, _IconId, ResourceFileName);

        NavApp.GetResource(ResourceFileName, ImageStream);
        exit(Base64Convert.ToBase64(ImageStream));
    end;

    local procedure GetIdFromCfgImageFileName(var _IconId: Text): Boolean
    var
        MobXmlMgt: Codeunit "MOB XML Management";
        XmlDoc: XmlDocument;
        ImageNode: XmlNode;
        Attribute: XmlAttribute;
    begin
        MobXmlMgt.DocReadText(XmlDoc, NavApp.GetResourceAsText('config/application.cfg'));
        if XmlDoc.SelectSingleNode(StrSubstNo('//*[@fileName="%1"]', _IconId), ImageNode) then // Search for image node with matching fileName attribute
            if ImageNode.AsXmlElement().Attributes().Get(1, Attribute) then begin // The first attribute is "id"
                _IconId := Attribute.Value().ToLower();
                exit(true);
            end;
    end;

    local procedure GetIconEnum(_IconId: Text; var _DeviceIcon: Enum "MOB Device Icon"): Boolean
    var
        Index: Integer;
        OrdinalValue: Integer;
    begin
        if not IsMediaAnIcon(_IconId, _IconId) then
            exit(false);

        Index := Enum::"MOB Device Icon".Names().IndexOf(_IconId);
        OrdinalValue := Enum::"MOB Device Icon".Ordinals().Get(Index);
        _DeviceIcon := Enum::"MOB Device Icon".FromInteger(OrdinalValue);
        exit(true);
    end;
    /* #endif */
}
