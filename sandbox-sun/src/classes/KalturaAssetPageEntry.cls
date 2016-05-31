public with sharing class KalturaAssetPageEntry {
    public KalturaMediaEntry    media {get; private set;}
    public Boolean              imported {get; set;}
    public Boolean              doImport {get; set; }
    
    public KalturaAssetPageEntry(KalturaMediaEntry theEntry, boolean isImported) {
        media =  theEntry;
        imported = isImported;
        doImport = false;
    }
}