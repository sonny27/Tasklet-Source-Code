codeunit 81281 "MOB Command XML Management"
{
    Access = Public;
    /// <summary>
    /// Add multiple command elements to XML.
    /// Processes a recordset of command elements.
    /// </summary>

    var
        MobXmlMgt: Codeunit "MOB XML Management";

    internal procedure AddCommandsElements(var _XmlCommandsNode: XmlNode; var _CommandsElements: Record "MOB Command Element")
    var
        XmlCreatedNode: XmlNode;
    begin
        if not _CommandsElements.FindSet() then
            exit;

        // The <commands> node already exists in the _XmlCommandsNode
        // Now we must process and add each command element one by one - remember all details for each element are in the ValueBuffer
        repeat
            AddCommandElement2XmlElement(_XmlCommandsNode, _CommandsElements, XmlCreatedNode);
        until _CommandsElements.Next() = 0;
    end;

    /// <summary>
    /// Add a single command element to XML using the standard MOB pattern
    /// Each command record contains all its data in the linked ValueBuffer
    /// </summary>
    internal procedure AddCommandElement2XmlElement(var _XmlCommandsNode: XmlNode; var _CommandElement: Record "MOB Command Element"; var _XmlCreatedNode: XmlNode)
    var
        TempValueBuffer: Record "MOB NodeValue Buffer" temporary;
        XmlCommandElement: XmlNode;
    begin
        // Ensure table data is synchronized to buffer
        _CommandElement.Save();

        // Get the shared NodeValue buffer for this command element
        _CommandElement.GetSharedNodeValueBuffer(TempValueBuffer);

        // Filter out internal fields (same pattern as other element tables) 
        TempValueBuffer.SetCurrentKey("Reference Key", Sorting);
        TempValueBuffer.SetFilter(Sorting, '0|10..799|1000..');

        // Create the main command element like (filter, select, pin) to the <commands> node
        MobXmlMgt.AddElement(_XmlCommandsNode, _CommandElement.NodeName, '', MobXmlMgt.GetNodeNSURI(_XmlCommandsNode), XmlCommandElement);

        // Add ID attribute from table field if present
        if _CommandElement.Id <> '' then
            MobXmlMgt.AddAttribute(XmlCommandElement, 'id', _CommandElement.Id);

        // Add attributes to the specific command element
        AddCommandAttributes(XmlCommandElement, TempValueBuffer);

        // Add child elements and their contents like <values> and <includes>
        AddCommandElements(XmlCommandElement, TempValueBuffer);

        _XmlCreatedNode := XmlCommandElement;
    end;

    local procedure AddCommandAttributes(var _XmlCommandElement: XmlNode; var _ValueBuffer: Record "MOB NodeValue Buffer")
    var
        IsDirectAttribute: Boolean;
        IsChildElement: Boolean;
    begin
        // Add direct attributes (paths without / separator) to the <command> element
        // Skip paths that represent child elements (values, includes)
        if _ValueBuffer.FindSet() then
            repeat
                IsDirectAttribute := (StrPos(_ValueBuffer.Path, '/') = 0);
                IsChildElement := (_ValueBuffer.Path in ['values', 'include']);

                if IsDirectAttribute and (not IsChildElement) then
                    MobXmlMgt.AddAttribute(_XmlCommandElement, _ValueBuffer.Path, _ValueBuffer.GetValue());
            until _ValueBuffer.Next() = 0;
    end;

    /// <summary>
    /// Add child elements and their content to the command element
    /// Like 'values' and 'includes'
    /// </summary>    
    local procedure AddCommandElements(var _XmlCommandElement: XmlNode; var _ValueBuffer: Record "MOB NodeValue Buffer")
    begin
        // Create <values> element and add child elements        
        AddValueElements(_XmlCommandElement, _ValueBuffer);

        // Create <include> elements
        AddIncludeElements(_XmlCommandElement, _ValueBuffer);
    end;

    local procedure AddValueElements(var _XmlCommandElement: XmlNode; var _ValueBuffer: Record "MOB NodeValue Buffer")
    var
        XmlValuesElement: XmlNode;
        XmlValueElement: XmlNode;
        ElementName: Text;
    begin
        // Add child elements to the <values> element
        _ValueBuffer.SetFilter(Path, 'values/*'); // Filter to only 'values/' paths

        if _ValueBuffer.FindSet() then begin

            // Create <values> element
            MobXmlMgt.AddElement(_XmlCommandElement, 'values', '', MobXmlMgt.GetNodeNSURI(_XmlCommandElement), XmlValuesElement);
            repeat
                ElementName := CopyStr(_ValueBuffer.Path, 8); // Remove 'values/' prefix

                // Create child elements like FromBin, FromLicensePlate etc. inside values element
                MobXmlMgt.AddElement(XmlValuesElement, ElementName, _ValueBuffer.GetValue(), MobXmlMgt.GetNodeNSURI(XmlValuesElement), XmlValueElement);
            //end;
            until _ValueBuffer.Next() = 0;
        end;

        // Reset the filter on Path
        _ValueBuffer.SetRange(Path);
    end;

    local procedure AddIncludeElements(var _XmlCommandElement: XmlNode; var _ValueBuffer: Record "MOB NodeValue Buffer")
    var
        XmlIncludeElement: XmlNode;
        Includes: List of [Text];
        IncludeIndex: Text;
        IncludeName: Text;
        IncludeValue: Text;
        I: Integer;
    begin
        // Collect unique include elements, e.g., include[1], include[2]
        GetUniqueIncludes(_ValueBuffer, Includes, IncludeIndex);

        // Create separate include element for each unique include index
        for I := 1 to Includes.Count() do begin
            IncludeIndex := Includes.Get(I);

            // Get name and value for this include
            IncludeName := '';
            IncludeValue := '';
            _ValueBuffer.Reset();
            _ValueBuffer.SetFilter(Path, 'include[*');
            if _ValueBuffer.FindSet() then
                repeat
                    case _ValueBuffer.Path of
                        'include[' + IncludeIndex + ']/name':
                            IncludeName := _ValueBuffer.GetValue();

                        'include[' + IncludeIndex + ']/value':
                            IncludeValue := _ValueBuffer.GetValue();
                    end;
                until _ValueBuffer.Next() = 0;

            // Create include element with name and value attributes
            if (IncludeName <> '') and (IncludeValue <> '') then begin
                MobXmlMgt.AddElement(_XmlCommandElement, 'include', '', MobXmlMgt.GetNodeNSURI(_XmlCommandElement), XmlIncludeElement);
                MobXmlMgt.AddAttribute(XmlIncludeElement, 'name', IncludeName);
                MobXmlMgt.AddAttribute(XmlIncludeElement, 'value', IncludeValue);
            end;
        end;

        // Reset the filter on Path
        _ValueBuffer.SetRange(Path);
    end;

    local procedure GetUniqueIncludes(var _ValueBuffer: Record "MOB NodeValue Buffer"; var _Includes: List of [Text]; var _IncludeIndex: Text)
    begin
        // Collect unique include group indices (e.g., "1", "2" from "include[1]/name", "include[2]/name")
        _ValueBuffer.SetFilter(Path, 'include[*');
        if _ValueBuffer.FindSet() then
            repeat
                _IncludeIndex := CopyStr(_ValueBuffer.Path, 9); // Remove 'include[' prefix
                _IncludeIndex := CopyStr(_IncludeIndex, 1, StrPos(_IncludeIndex, ']') - 1); // Extract index before ']'
                if not _Includes.Contains(_IncludeIndex) then
                    _Includes.Add(_IncludeIndex);
            until _ValueBuffer.Next() = 0;
    end;
}
