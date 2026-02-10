codeunit 81384 "MOB WMS Conf. Tools"
{
    Access = Public;

    // This codeunit contains helper functions to generate configuration elements for:
    // - Header fields
    // - Registration steps
    // 
    // The functions shows the different options the mobile device is capable of.
    // 
    // USE THE "ExampleCode" FUNCTION AS A PLACE TO COPY THE CALLS YOU NEED
    // THIS FUNCTION IS NOT INTENDED TO BE USED
    // 
    // ************* Step Configuration *****************
    // To add a step multiple functions must be called.
    // There are a lot of parameters that CAN be set, but in most cases only a few is needed.
    // All parameters are defined as global variables.
    // 
    // Two functions are used to set:
    // - The standard values relevant to all step types. This MUST be called. It initializes all values with default values.
    //   RC_Std_Parms(_Id,_Name,_Header,_Label,_HelpLabel)
    // 
    // - The extended values relevant to all step types. This CAN be called if needed. It overwrites the relevant default values.
    //   RC_Ext_Parms(_EanAi,_AutoForwardAfterScan,_Optional,_Visible,_LabelWidth);
    // 
    // After that you call the relevant function that creates the step you need.
    // - RC_List_TableData(XmlCDataSection,_DataTable,_DataKeyColumn,_DataDisplayColumn,_DefaultValue);
    // 
    // ************* Header Configuration *****************


    trigger OnRun()
    begin
    end;

    var
        Id: Integer;
        Name: Text;
        Header: Text;
        Label: Text;
        LabelWidth: Integer;
        HelpLabel: Text;
        AutoForwardAfterScan: Boolean;
        Optional: Boolean;
        Visible: Boolean;
        ListValues: Text[1024];
        ListSeparator: Text[1];
        DataTable: Text[50];
        DataKeyColumn: Text[50];
        DataDisplayColumn: Text[50];
        LinkedElement: Integer;
        FilterColumn: Text[50];
        DefaultValue: Text[50];
        EanAi: Text;
        LIST_Txt: Label 'List', Locked = true;
        DATE_Txt: Label 'Date', Locked = true;
        DATETIME_Txt: Label 'DateTime', Locked = true;
        DECIMAL_Txt: Label 'Decimal', Locked = true;
        IMAGE_Txt: Label 'Image', Locked = true;
        IMAGECAPTURE_Txt: Label 'ImageCapture', Locked = true;
        SIGNATURE_Txt: Label 'Signature', Locked = true;
        INFORMATION_Txt: Label 'Information', Locked = true;
        MULTI_LINE_TEXT_Txt: Label 'MultiLineText', Locked = true;
        MULTI_SCAN_Txt: Label 'MultiScan', Locked = true;
        QUANTITY_BY_SCAN_Txt: Label 'QuantityByScan', Locked = true;
        RADIO_BUTTON_Txt: Label 'RadioButton', Locked = true;
        TEXT_Txt: Label 'Text', Locked = true;
        SUMMARY_Txt: Label 'Summary', Locked = true;
        WARN_Txt: Label 'Warn', Locked = true;
        Length: Integer;
        HelpLabelMaximize: Boolean;
        ValidationValues: Text[1024];
        ValidationCaseSensitive: Boolean;
        Editable: Boolean;
        MinValue: Decimal;
        MaxValue: Decimal;
        OverDeliveryValidation: Text[10];
        UniqueValues: Boolean;
        ResolutionHeight: Integer;
        ResolutionWidth: Integer;
        PerformCalculation: Boolean;
        DateFormat: Text[50];
        MinDate: Date;
        MaxDate: Date;
        PrimaryInputMethod: Text[50];
        InputFormat: Text[1024];

    local procedure RC_Step_CData(var _XmlCDataSection: XmlCData; _InputType: Text[50])
    var
        MobXmlMgt: Codeunit "MOB XML Management";
    begin
        // This function is private and should not be called from outside the codeunit

        MobXmlMgt.NodeAppendCDataText(_XmlCDataSection, '<add');
        MobXmlMgt.NodeAppendCDataText(_XmlCDataSection, StrSubstNo(' inputType="%1"', _InputType));
        MobXmlMgt.NodeAppendCDataText(_XmlCDataSection, StrSubstNo(' id="%1"', Id));
        MobXmlMgt.NodeAppendCDataText(_XmlCDataSection, StrSubstNo(' name="%1"', Name));
        MobXmlMgt.NodeAppendCDataText(_XmlCDataSection, StrSubstNo(' header="%1"', Header));
        MobXmlMgt.NodeAppendCDataText(_XmlCDataSection, StrSubstNo(' label="%1"', Label));
        MobXmlMgt.NodeAppendCDataText(_XmlCDataSection, StrSubstNo(' labelWidth="%1"', LabelWidth));
        MobXmlMgt.NodeAppendCDataText(_XmlCDataSection, StrSubstNo(' helpLabel="%1"', HelpLabel));

        // For character based input fields the maximum allowed length can be set
        if Length <> -1 then
            MobXmlMgt.NodeAppendCDataText(_XmlCDataSection, StrSubstNo(' length="%1"', Length));

        // Determines if the mobile device automatically moves on to the next step if a value is scanned
        // If it is set to false the mobile device stays on the step until the user manually moves forward
        if AutoForwardAfterScan then
            MobXmlMgt.NodeAppendCDataText(_XmlCDataSection, StrSubstNo(' autoForwardAfterScan="%1"', 'true'))
        else
            MobXmlMgt.NodeAppendCDataText(_XmlCDataSection, StrSubstNo(' autoForwardAfterScan="%1"', 'false'));

        // Determines if the step can be left blank / skipped or if the user must enter a value
        if Optional then
            MobXmlMgt.NodeAppendCDataText(_XmlCDataSection, StrSubstNo(' optional="%1"', 'true'))
        else
            MobXmlMgt.NodeAppendCDataText(_XmlCDataSection, StrSubstNo(' optional="%1"', 'false'));

        // Determines if the step is shown to the user
        if Visible then
            MobXmlMgt.NodeAppendCDataText(_XmlCDataSection, StrSubstNo(' visible="%1"', 'true'))
        else
            MobXmlMgt.NodeAppendCDataText(_XmlCDataSection, StrSubstNo(' visible="%1"', 'false'));

        if ListValues <> '' then begin
            MobXmlMgt.NodeAppendCDataText(_XmlCDataSection, StrSubstNo(' listValues="%1"', ListValues));

            // The separator is only relevant if list values are provided
            // Use ';' unless the caller defines another separator character
            if ListSeparator <> '' then
                MobXmlMgt.NodeAppendCDataText(_XmlCDataSection, StrSubstNo(' listSeparator="%1"', ListSeparator))
            else
                MobXmlMgt.NodeAppendCDataText(_XmlCDataSection, StrSubstNo(' listSeparator="%1"', ';'));
        end;

        if DataTable <> '' then begin
            MobXmlMgt.NodeAppendCDataText(_XmlCDataSection, StrSubstNo(' dataTable="%1"', DataTable));
            MobXmlMgt.NodeAppendCDataText(_XmlCDataSection, StrSubstNo(' dataKeyColumn="%1"', DataKeyColumn));
            MobXmlMgt.NodeAppendCDataText(_XmlCDataSection, StrSubstNo(' dataDisplayColumn="%1"', DataDisplayColumn));
        end;

        if LinkedElement <> -1 then
            MobXmlMgt.NodeAppendCDataText(_XmlCDataSection, StrSubstNo(' linkedElement="%1"', LinkedElement));

        if FilterColumn <> '' then
            MobXmlMgt.NodeAppendCDataText(_XmlCDataSection, StrSubstNo(' filterColumn="%1"', FilterColumn));

        // Use the default value to pre-populate the step with a value
        if DefaultValue <> '' then
            MobXmlMgt.NodeAppendCDataText(_XmlCDataSection, StrSubstNo(' defaultValue="%1"', DefaultValue));

        // One or more GS1 application identifiers can be associated with a step
        MobXmlMgt.NodeAppendCDataText(_XmlCDataSection, StrSubstNo(' eanAi="%1"', EanAi));

        // Perform Calculation
        if PerformCalculation then
            MobXmlMgt.NodeAppendCDataText(_XmlCDataSection, StrSubstNo(' performCalculation="%1"', 'true'))
        else
            MobXmlMgt.NodeAppendCDataText(_XmlCDataSection, StrSubstNo(' performCalculation="%1"', 'false'));

        // Help Label Maximize
        if HelpLabelMaximize then
            MobXmlMgt.NodeAppendCDataText(_XmlCDataSection, StrSubstNo(' helpLabelMaximize="%1"', 'true'))
        else
            MobXmlMgt.NodeAppendCDataText(_XmlCDataSection, StrSubstNo(' helpLabelMaximize="%1"', 'false'));

        // Validation Values
        if ValidationValues <> '' then begin
            MobXmlMgt.NodeAppendCDataText(_XmlCDataSection, StrSubstNo(' validationValues="%1"', ValidationValues));

            // Case sensitive
            if ValidationCaseSensitive then
                MobXmlMgt.NodeAppendCDataText(_XmlCDataSection, StrSubstNo(' validationCaseSensitive="%1"', 'true'))
            else
                MobXmlMgt.NodeAppendCDataText(_XmlCDataSection, StrSubstNo(' validationCaseSensitive="%1"', 'false'));
        end;

        // Overdelivery Validation
        MobXmlMgt.NodeAppendCDataText(_XmlCDataSection, StrSubstNo(' overDeliveryValidation="%1"', OverDeliveryValidation));

        // Editable
        if Editable then
            MobXmlMgt.NodeAppendCDataText(_XmlCDataSection, StrSubstNo(' editable="%1"', 'true'))
        else
            MobXmlMgt.NodeAppendCDataText(_XmlCDataSection, StrSubstNo(' editable="%1"', 'false'));

        // Unique values
        if UniqueValues then
            MobXmlMgt.NodeAppendCDataText(_XmlCDataSection, StrSubstNo(' uniqueValues="%1"', 'true'))
        else
            MobXmlMgt.NodeAppendCDataText(_XmlCDataSection, StrSubstNo(' uniqueValues="%1"', 'false'));

        // Resolution Height
        if ResolutionHeight <> -1 then
            MobXmlMgt.NodeAppendCDataText(_XmlCDataSection, StrSubstNo(' resolutionHeight="%1"', ResolutionHeight));

        // Resolution Width
        if ResolutionWidth <> -1 then
            MobXmlMgt.NodeAppendCDataText(_XmlCDataSection, StrSubstNo(' resolutionWidth="%1"', ResolutionWidth));

        // Date Format
        if DateFormat <> '' then
            MobXmlMgt.NodeAppendCDataText(_XmlCDataSection, StrSubstNo(' format="%1"', DateFormat));

        // Min Date
        if MinDate <> 0D then
            MobXmlMgt.NodeAppendCDataText(_XmlCDataSection, StrSubstNo(' minDate="%1"', Format(MinDate, 0, '<Day>-<Month>-<Year4>')));

        // Max Date
        if MaxDate <> 0D then
            MobXmlMgt.NodeAppendCDataText(_XmlCDataSection, StrSubstNo(' maxDate="%1"', Format(MaxDate, 0, '<Day>-<Month>-<Year4>')));

        // Min Value
        if MinValue <> -10000000 then
            MobXmlMgt.NodeAppendCDataText(_XmlCDataSection, StrSubstNo(' minValue="%1"', Format(MinValue, 0, 9)));

        // Max Value
        if MaxValue <> 10000000 then
            MobXmlMgt.NodeAppendCDataText(_XmlCDataSection, StrSubstNo(' maxValue="%1"', Format(MaxValue, 0, 9)));

        if PrimaryInputMethod <> '' then
            MobXmlMgt.NodeAppendCDataText(_XmlCDataSection, StrSubstNo(' primaryInputMethod="%1"', PrimaryInputMethod));

        if InputFormat <> '' then
            MobXmlMgt.NodeAppendCDataText(_XmlCDataSection, StrSubstNo(' inputFormat="%1"', InputFormat));

        MobXmlMgt.NodeAppendCDataText(_XmlCDataSection, '/>');
    end;

    local procedure RC_Step_XmlNode(var _XmlSteps: XmlNode; _InputType: Text[50]; _ShowUnique: Boolean)
    var
        MobXmlMgt: Codeunit "MOB XML Management";
        XmlAddElement: XmlNode;
    begin
        // This function is private and should not be called outside this codeunit

        MobXmlMgt.AddElement(_XmlSteps, 'add', '', MobXmlMgt.GetNodeNSURI(_XmlSteps), XmlAddElement);
        MobXmlMgt.AddAttribute(XmlAddElement, 'inputType', _InputType);
        MobXmlMgt.AddAttribute(XmlAddElement, 'id', Format(Id, 0, 9));
        MobXmlMgt.AddAttribute(XmlAddElement, 'name', Name);
        MobXmlMgt.AddAttribute(XmlAddElement, 'header', Header);
        MobXmlMgt.AddAttribute(XmlAddElement, 'label', Label);
        MobXmlMgt.AddAttribute(XmlAddElement, 'labelWidth', Format(LabelWidth, 0, 9));
        MobXmlMgt.AddAttribute(XmlAddElement, 'helpLabel', HelpLabel);

        // For character based input fields the maximum allowed length can be set
        if Length <> -1 then
            MobXmlMgt.AddAttribute(XmlAddElement, 'length', Format(Length, 0, 9));

        // Determines if the mobile device automatically moves on to the next step if a value is scanned
        // If it is set to false the mobile device stays on the step until the user manually moves forward
        if AutoForwardAfterScan then
            MobXmlMgt.AddAttribute(XmlAddElement, 'autoForwardAfterScan', 'true')
        else
            MobXmlMgt.AddAttribute(XmlAddElement, 'autoForwardAfterScan', 'false');

        // Determines if the step can be left blank / skipped or if the user must enter a value
        if Optional then
            MobXmlMgt.AddAttribute(XmlAddElement, 'optional', 'true')
        else
            MobXmlMgt.AddAttribute(XmlAddElement, 'optional', 'false');

        // Determines if the step is shown to the user
        if Visible then
            MobXmlMgt.AddAttribute(XmlAddElement, 'visible', 'true')
        else
            MobXmlMgt.AddAttribute(XmlAddElement, 'visible', 'false');

        if ListValues <> '' then begin
            MobXmlMgt.AddAttribute(XmlAddElement, 'listValues', ListValues);

            // The separator is only relevant if list values are provided
            // Use ';' unless the caller defines another separator character
            if ListSeparator <> '' then
                MobXmlMgt.AddAttribute(XmlAddElement, 'listSeparator', ListSeparator)
            else
                MobXmlMgt.AddAttribute(XmlAddElement, 'listSeparator', ';');
        end;

        if DataTable <> '' then begin
            MobXmlMgt.AddAttribute(XmlAddElement, 'dataTable', DataTable);
            MobXmlMgt.AddAttribute(XmlAddElement, 'dataKeyColumn', DataKeyColumn);
            MobXmlMgt.AddAttribute(XmlAddElement, 'dataDisplayColumn', DataDisplayColumn);
        end;

        if LinkedElement <> -1 then
            MobXmlMgt.AddAttribute(XmlAddElement, 'linkedElement', Format(LinkedElement, 0, 9));

        if FilterColumn <> '' then
            MobXmlMgt.AddAttribute(XmlAddElement, 'filterColumn', FilterColumn);

        // Use the default value to pre-populate the step with a value
        if DefaultValue <> '' then
            MobXmlMgt.AddAttribute(XmlAddElement, 'defaultValue', DefaultValue);

        // One or more GS1 application identifiers can be associated with a step
        MobXmlMgt.AddAttribute(XmlAddElement, 'eanAi', EanAi);

        // Perform Calculation
        if PerformCalculation then
            MobXmlMgt.AddAttribute(XmlAddElement, 'performCalculation', 'true')
        else
            MobXmlMgt.AddAttribute(XmlAddElement, 'performCalculation', 'false');

        // Help Label Maximize
        if HelpLabelMaximize then
            MobXmlMgt.AddAttribute(XmlAddElement, 'helpLabelMaximize', 'true')
        else
            MobXmlMgt.AddAttribute(XmlAddElement, 'helpLabelMaximize', 'false');

        // Validation Values
        if ValidationValues <> '' then begin
            MobXmlMgt.AddAttribute(XmlAddElement, 'validationValues', ValidationValues);

            // Case sensitive
            if ValidationCaseSensitive then
                MobXmlMgt.AddAttribute(XmlAddElement, 'validationCaseSensitive', 'true')
            else
                MobXmlMgt.AddAttribute(XmlAddElement, 'validationCaseSensitive', 'false');
        end;

        // Overdelivery Validation
        MobXmlMgt.AddAttribute(XmlAddElement, 'overDeliveryValidation', OverDeliveryValidation);

        // Editable
        if Editable then
            MobXmlMgt.AddAttribute(XmlAddElement, 'editable', 'true')
        else
            MobXmlMgt.AddAttribute(XmlAddElement, 'editable', 'false');

        // Unique values
        if _ShowUnique then
            if UniqueValues then
                MobXmlMgt.AddAttribute(XmlAddElement, 'uniqueValues', 'true')
            else
                MobXmlMgt.AddAttribute(XmlAddElement, 'uniqueValues', 'false');

        // Resolution Height
        if ResolutionHeight <> -1 then
            MobXmlMgt.AddAttribute(XmlAddElement, 'resolutionHeight', Format(ResolutionHeight, 0, 9));

        // Resolution Width
        if ResolutionWidth <> -1 then
            MobXmlMgt.AddAttribute(XmlAddElement, 'resolutionWidth', Format(ResolutionWidth, 0, 9));

        // Date Format
        if DateFormat <> '' then
            MobXmlMgt.AddAttribute(XmlAddElement, 'format', DateFormat);

        // Min Date
        if MinDate <> 0D then
            MobXmlMgt.AddAttribute(XmlAddElement, 'minDate', Format(MinDate, 0, '<Day>-<Month>-<Year4>'));

        // Max Date
        if MaxDate <> 0D then
            MobXmlMgt.AddAttribute(XmlAddElement, 'maxDate', Format(MaxDate, 0, '<Day>-<Month>-<Year4>'));

        // Min Value
        if MinValue <> -10000000 then
            MobXmlMgt.AddAttribute(XmlAddElement, 'minValue', Format(MinValue, 0, 9));

        // Max Value
        if MaxValue <> 10000000 then
            MobXmlMgt.AddAttribute(XmlAddElement, 'maxValue', Format(MaxValue, 0, 9));

        if PrimaryInputMethod <> '' then
            MobXmlMgt.AddAttribute(XmlAddElement, 'primaryInputMethod', PrimaryInputMethod);

        if InputFormat <> '' then
            MobXmlMgt.AddAttribute(XmlAddElement, 'inputFormat', InputFormat);
    end;

    procedure RC_List_TableData_CData(var _XmlCDataSection: XmlCData; _DataTable: Text[50]; _DataKeyColumn: Text[50]; _DataDisplayColumn: Text[50]; _DefaultValue: Text[50])
    begin

        // Standard table data values
        DataTable := _DataTable;                        // The name of the table in the reference data
        DataKeyColumn := _DataKeyColumn;                // The column to use for the data value
        DataDisplayColumn := _DataDisplayColumn;        // The column to vbuse for the value displayed in the list
        DefaultValue := _DefaultValue;                  // The initial value of the list. If "blank" is supplied the first entry is used.

        // Create the XML based on the set variables
        RC_Step_CData(_XmlCDataSection, LIST_Txt);
    end;

    procedure RC_List_TableData_XmlNode(var _XmlSteps: XmlNode; _DataTable: Text[50]; _DataKeyColumn: Text[50]; _DataDisplayColumn: Text[50]; _DefaultValue: Text[50])
    begin

        // Standard table data values
        DataTable := _DataTable;                        // The name of the table in the reference data
        DataKeyColumn := _DataKeyColumn;                // The column to use for the data value
        DataDisplayColumn := _DataDisplayColumn;        // The column to use for the value displayed in the list
        DefaultValue := _DefaultValue;                  // The initial value of the list. If "blank" is supplied the first entry is used.

        // Create the XML based on the set variables
        RC_Step_XmlNode(_XmlSteps, LIST_Txt, false);
    end;

    procedure RC_List_TableData_Ext(_LinkedElement: Integer; _FilterColumn: Text[50])
    begin
        // Set the extended variables

        // The ID of the step that is linked to this step (the step to get the value to filter on from)
        LinkedElement := _LinkedElement;

        // The column in the data table associated with this step where the data value from the linked step will be applied
        FilterColumn := _FilterColumn;

        // Example
        // Step 1 has a selected data value of "A"
        // Step 2 has a table that looks like this:
        // Data Column | Filter column
        //      1             A
        //      2             A
        //      3             B
        //      4             C

        // Result:
        // Only 1 and 2 is shown in the list
    end;

    procedure RC_List_ListData_CData(var _XmlCDataSection: XmlCData; _ListValues: Text[1024]; _DefaultValue: Text[50])
    begin
        // Standard list values
        ListValues := _ListValues;
        DefaultValue := _DefaultValue;

        // Create the XML based on the set variables
        RC_Step_CData(_XmlCDataSection, LIST_Txt);
    end;

    procedure RC_List_ListData_XmlNode(var _XmlSteps: XmlNode; _ListValues: Text[1024]; _DefaultValue: Text[50])
    begin
        // Standard list values
        ListValues := _ListValues;
        DefaultValue := _DefaultValue;

        // Create the XML based on the set variables
        RC_Step_XmlNode(_XmlSteps, LIST_Txt, false);
    end;

    procedure RC_List_ListData_Ext(_ListSeparator: Text[1])
    begin
        ListSeparator := _ListSeparator;
    end;

    procedure RC_Text_CData(var _XmlCDataSection: XmlCData; _DefaultValue: Text[50]; _Length: Integer)
    begin
        // Standard text values
        DefaultValue := _DefaultValue;
        Length := _Length;

        // Create the XML based on the set variables
        RC_Step_CData(_XmlCDataSection, TEXT_Txt);
    end;

    procedure RC_Text_XmlNode(var _XmlSteps: XmlNode; _DefaultValue: Text[50]; _Length: Integer)
    begin
        // Standard text values
        DefaultValue := _DefaultValue;
        Length := _Length;

        // Create the XML based on the set variables
        RC_Step_XmlNode(_XmlSteps, TEXT_Txt, false);
    end;

    procedure RC_Text_Ext(_HelpLabelMaximize: Boolean; _ValidationValues: Text[1024]; _ValidationCaseSensitive: Boolean; _ListSeparator: Text[1])
    begin
        // Extended text values
        HelpLabelMaximize := _HelpLabelMaximize;
        ValidationValues := _ValidationValues;
        ValidationCaseSensitive := _ValidationCaseSensitive;
        ListSeparator := _ListSeparator;
    end;

    procedure RC_RadioButton_CData(var _XmlCDataSection: XmlCData; _DefaultValue: Text[50]; _ListValues: Text[1024]; _ListSeparator: Text[1])
    begin
        // Set the standard parameters
        DefaultValue := _DefaultValue;
        ListValues := _ListValues;
        ListSeparator := _ListSeparator;

        // Create the XML based on the set variables
        RC_Step_CData(_XmlCDataSection, RADIO_BUTTON_Txt);
    end;

    procedure RC_RadioButton_XmlNode(var _XmlSteps: XmlNode; _DefaultValue: Text[50]; _ListValues: Text[1024]; _ListSeparator: Text[1])
    begin
        // Set the standard parameters
        DefaultValue := _DefaultValue;
        ListValues := _ListValues;
        ListSeparator := _ListSeparator;

        // Create the XML based on the set variables
        RC_Step_XmlNode(_XmlSteps, RADIO_BUTTON_Txt, false);
    end;

    procedure RC_QtyByScan_CData(var _XmlCDataSection: XmlCData; _Editable: Boolean; _MinValue: Decimal; _MaxValue: Decimal; _OverDeliveryValidation: Text[10]; _ValidationValues: Text[1024]; _ListSeparator: Text[1]; _DataTable: Text[50]; _DataKeyColumn: Text[50])
    begin
        // Standard values
        Editable := _Editable;
        MinValue := _MinValue;
        MaxValue := _MaxValue;
        OverDeliveryValidation := _OverDeliveryValidation;
        ListValues := _ValidationValues;    // For backwards compatibility with Windows Mobile
        ValidationValues := _ValidationValues;
        ListSeparator := _ListSeparator;
        DataTable := _DataTable;
        DataKeyColumn := _DataKeyColumn;

        // Create the XML based on the set variables
        RC_Step_CData(_XmlCDataSection, QUANTITY_BY_SCAN_Txt);
    end;

    procedure RC_QtyByScan_XmlNode(var _XmlSteps: XmlNode; _Editable: Boolean; _MinValue: Decimal; _MaxValue: Decimal; _OverDeliveryValidation: Text[10]; _ValidationValues: Text[1024]; _ListSeparator: Text[1]; _DataTable: Text[50]; _DataKeyColumn: Text[50])
    begin
        // Standard values
        Editable := _Editable;
        MinValue := _MinValue;
        MaxValue := _MaxValue;
        OverDeliveryValidation := _OverDeliveryValidation;
        ListValues := _ValidationValues;    // For backwards compatibility with Windows Mobile
        ValidationValues := _ValidationValues;
        ListSeparator := _ListSeparator;
        DataTable := _DataTable;
        DataKeyColumn := _DataKeyColumn;

        // Create the XML based on the set variables
        RC_Step_XmlNode(_XmlSteps, QUANTITY_BY_SCAN_Txt, false);
    end;

    procedure RC_MultiScan_CData(var _XmlCDataSection: XmlCData; _UniqueValues: Boolean; _ListSeparator: Text[1])
    begin
        // Standard values
        UniqueValues := _UniqueValues;
        ListSeparator := _ListSeparator;

        // Create the XML based on the set variables
        RC_Step_CData(_XmlCDataSection, MULTI_SCAN_Txt);
    end;

    procedure RC_MultiScan_XmlNode(var _XmlSteps: XmlNode; _UniqueValues: Boolean; _ListSeparator: Text[1])
    begin
        // Standard values
        UniqueValues := _UniqueValues;
        ListSeparator := _ListSeparator;

        // Create the XML based on the set variables
        RC_Step_XmlNode(_XmlSteps, MULTI_SCAN_Txt, true);
    end;

    procedure RC_MultiLineText_CData(var _XmlCDataSection: XmlCData; _DefaultValue: Text[1024]; _Length: Integer)
    begin
        DefaultValue := _DefaultValue;
        Length := _Length;

        // Create the XML based on the set variables
        RC_Step_CData(_XmlCDataSection, MULTI_LINE_TEXT_Txt);
    end;

    procedure RC_MultiLineText_XmlNode(var _XmlSteps: XmlNode; _DefaultValue: Text[1024]; _Length: Integer)
    begin
        DefaultValue := _DefaultValue;
        Length := _Length;

        // Create the XML based on the set variables
        RC_Step_XmlNode(_XmlSteps, MULTI_LINE_TEXT_Txt, false);
    end;

    procedure RC_Information_CData(var _XmlCDataSection: XmlCData)
    begin
        // Create the XML based on the set variables
        RC_Step_CData(_XmlCDataSection, INFORMATION_Txt);
    end;

    procedure RC_Information_XmlNode(var _XmlSteps: XmlNode)
    begin
        // Create the XML based on the set variables
        RC_Step_XmlNode(_XmlSteps, INFORMATION_Txt, false);
    end;

    procedure RC_ImageCapture_CData(var _XmlCDataSection: XmlCData; _DefaultValue: Text[50]; _ListSeparator: Text[1]; _ResolutionHeight: Integer; _ResolutionWidth: Integer)
    begin
        // Standard text values
        DefaultValue := _DefaultValue;
        ListSeparator := _ListSeparator;
        ResolutionHeight := _ResolutionHeight;
        ResolutionWidth := _ResolutionWidth;

        // Create the XML based on the set variables
        RC_Step_CData(_XmlCDataSection, IMAGECAPTURE_Txt);
    end;

    procedure RC_ImageCapture_XmlNode(var _XmlSteps: XmlNode; _DefaultValue: Text[50]; _ListSeparator: Text[1]; _ResolutionHeight: Integer; _ResolutionWidth: Integer)
    begin
        // Standard text values
        DefaultValue := _DefaultValue;
        ListSeparator := _ListSeparator;
        ResolutionHeight := _ResolutionHeight;
        ResolutionWidth := _ResolutionWidth;

        // Create the XML based on the set variables
        RC_Step_XmlNode(_XmlSteps, IMAGECAPTURE_Txt, false);
    end;

    procedure RC_Image_CData(var _XmlCDataSection: XmlCData; _DefaultValue: Text[1024])
    begin
        DefaultValue := _DefaultValue;

        // Create the XML based on the set variables
        RC_Step_CData(_XmlCDataSection, IMAGE_Txt);
    end;

    procedure RC_Image_XmlNode(var _XmlSteps: XmlNode; _DefaultValue: Text[1024])
    begin
        DefaultValue := _DefaultValue;

        // Create the XML based on the set variables
        RC_Step_XmlNode(_XmlSteps, IMAGE_Txt, false);
    end;

    procedure RC_SignatureCapture_CData(var _XmlCDataSection: XmlCData)
    begin

        // Create the XML based on the set variables
        RC_Step_CData(_XmlCDataSection, SIGNATURE_Txt);
    end;

    procedure RC_SignatureCapture_XmlNode(var _XmlSteps: XmlNode)
    begin

        // Create the XML based on the set variables
        RC_Step_XmlNode(_XmlSteps, SIGNATURE_Txt, false);
    end;

    procedure RC_Decimal_CData(var _XmlCDataSection: XmlCData; _DefaultValue: Decimal; _MinValue: Decimal; _MaxValue: Decimal; _Length: Integer; _PerformCalculation: Boolean)
    begin
        DefaultValue := Format(_DefaultValue, 0, 9);
        MinValue := _MinValue;
        MaxValue := _MaxValue;
        Length := _Length;
        PerformCalculation := _PerformCalculation;

        // Create the XML based on the set variables
        RC_Step_CData(_XmlCDataSection, DECIMAL_Txt);
    end;

    procedure RC_Decimal_XmlNode(var _XmlSteps: XmlNode; _DefaultValue: Decimal; _MinValue: Decimal; _MaxValue: Decimal; _Length: Integer; _PerformCalculation: Boolean)
    begin
        DefaultValue := Format(_DefaultValue, 0, 9);
        MinValue := _MinValue;
        MaxValue := _MaxValue;
        Length := _Length;
        PerformCalculation := _PerformCalculation;

        // Create the XML based on the set variables
        RC_Step_XmlNode(_XmlSteps, DECIMAL_Txt, false);
    end;

    procedure RC_Date_CData(var _XmlCDataSection: XmlCData; _DefaultValue: Text[50]; _Format: Text[50]; _MinDate: Date; _MaxDate: Date)
    begin
        DefaultValue := _DefaultValue;
        DateFormat := _Format;
        MinDate := _MinDate;
        MaxDate := _MaxDate;

        // Create the XML based on the set variables
        RC_Step_CData(_XmlCDataSection, DATE_Txt);
    end;

    procedure RC_Date_XmlNode(var _XmlSteps: XmlNode; _DefaultValue: Text[50]; _Format: Text[50]; _MinDate: Date; _MaxDate: Date)
    begin
        DefaultValue := _DefaultValue;
        DateFormat := _Format;
        MinDate := _MinDate;
        MaxDate := _MaxDate;

        // Create the XML based on the set variables
        RC_Step_XmlNode(_XmlSteps, DATE_Txt, false);
    end;

    procedure RC_DateTime_CData(var _XmlCDataSection: XmlCData; _DefaultValue: Text[50]; _Format: Text[50]; _MinDate: Date; _MaxDate: Date)
    begin
        DefaultValue := _DefaultValue;
        DateFormat := _Format;
        MinDate := _MinDate;
        MaxDate := _MaxDate;

        // Create the XML based on the set variables
        RC_Step_CData(_XmlCDataSection, DATETIME_Txt);
    end;

    procedure RC_DateTime_XmlNode(var _XmlSteps: XmlNode; _DefaultValue: Text[50]; _Format: Text[50]; _MinDate: Date; _MaxDate: Date)
    begin
        DefaultValue := _DefaultValue;
        DateFormat := _Format;
        MinDate := _MinDate;
        MaxDate := _MaxDate;

        // Create the XML based on the set variables
        RC_Step_XmlNode(_XmlSteps, DATETIME_Txt, false);
    end;

    procedure RC_Summary_CData(var _XmlCDataSection: XmlCData; _LabelWidth: Integer)
    begin
        // Set the label width
        LabelWidth := _LabelWidth;

        // Create the XML based on the set variables
        RC_Step_CData(_XmlCDataSection, SUMMARY_Txt);
    end;

    procedure RC_Summary_XmlNode(var _XmlSteps: XmlNode; _LabelWidth: Integer)
    begin
        // Set the label width
        LabelWidth := _LabelWidth;

        // Create the XML based on the set variables
        RC_Step_XmlNode(_XmlSteps, SUMMARY_Txt, false);
    end;

    procedure RC_Std_Parms(_Id: Integer; _Name: Text; _Header: Text; _Label: Text; _HelpLabel: Text)
    begin
        // Use this function to set the standard parameters for all step types
        // It initializes the advanced parameters to it's default values

        // Standard parameters for all steps
        Id := _Id;
        Name := _Name;
        Header := _Header;
        Label := _Label;
        HelpLabel := _HelpLabel;

        // Default values
        Length := -1;
        LabelWidth := 100;
        AutoForwardAfterScan := true;
        Optional := false;
        Visible := true;
        ListValues := '';
        ListSeparator := '';
        DataTable := '';
        DataKeyColumn := '';
        DataDisplayColumn := '';
        LinkedElement := -1;
        FilterColumn := '';
        DefaultValue := '';
        EanAi := '';
        PerformCalculation := false;
        HelpLabelMaximize := false;
        ValidationValues := '';
        ValidationCaseSensitive := false;
        Editable := true;
        MinValue := -10000000;
        MaxValue := 10000000;
        OverDeliveryValidation := WARN_Txt;
        UniqueValues := true;
        ResolutionHeight := -1;
        ResolutionWidth := -1;
        DateFormat := '';
        MinDate := 0D;
        MaxDate := 0D;
        PrimaryInputMethod := 'Scan';
        InputFormat := '';
    end;

    procedure RC_Ext_Parms(_EanAi: Text; _AutoForwardAfterScan: Boolean; _Optional: Boolean; _Visible: Boolean; _LabelWidth: Integer)
    begin
        // Use this function to set the extended parameters for all step types
        LabelWidth := _LabelWidth;
        AutoForwardAfterScan := _AutoForwardAfterScan;
        Optional := _Optional;
        Visible := _Visible;
        EanAi := _EanAi;
    end;

    procedure RC_Ext_Parms_PrimaryInputMetho(_PrimaryInputMethod: Text[20])
    begin
        PrimaryInputMethod := _PrimaryInputMethod;
    end;

    procedure RC_Ext_Parms_InputFormat(_InputFormat: Text[1024])
    begin
        InputFormat := _InputFormat;
    end;

}

