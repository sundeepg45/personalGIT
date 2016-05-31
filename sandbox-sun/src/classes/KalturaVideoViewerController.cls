public with sharing class KalturaVideoViewerController {
    public ContentVersion content {get; set;}
    public RH_Content__c rhcontent {get; set;}

    public KalturaVideoViewerController() {
        loadContent();
    }

    public void loadContent() {
        String kalturaId = ApexPages.currentPage().getParameters().get('kalturaId');
        rhcontent = [
            select  Id,
                    ContentDocumentId__c,
                    KalturaId__c,
                    Kaltura_Thumbnail_URL__c
            from    RH_Content__c
            where   KalturaId__c = :kalturaId
            limit   1
        ];

        ContentVersion[] tmp = [
                select  Id,
                        Title,
                        ContentDocumentId,
                        ContentSize,
                        ContentUrl,
                        Description,
                        Document_Type__c,
                        FileType,
                        Language,
                        Is_New__c
                from    ContentVersion
                where   ContentDocumentId = :rhcontent.ContentDocumentId__c
                and     isLatest = true
                limit   1
        ];
        if (tmp.size() > 0) {
            content = tmp.get(0);
        }
    }

    static private testmethod void basicTest() {
        RH_Content__c rhc = [select KalturaId__c from RH_Content__c limit 1];
        ApexPages.currentPage().getParameters().put('kalturaId', rhc.KalturaId__c);
        KalturaVideoViewerController ctrl = new KalturaVideoViewerController();
    }

}