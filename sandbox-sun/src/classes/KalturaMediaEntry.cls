public with sharing class KalturaMediaEntry extends KalturaPlayableEntry {

    public String  dataUrl     {get; set; }
    public String  mediaType   {get; set; }
    public String  sourceType  {get; set; } 

    public KalturaMediaEntry(Dom.XmlNode entry) {
    	super(entry);
        dataUrl = entry.getChildElement('dataUrl', null).getText();
        mediaType = entry.getChildElement('mediaType', null).getText();
        sourceType = entry.getChildElement('sourceType', null).getText();

    }
    
    public KalturaMediaEntry() {
    	super();
    }
}