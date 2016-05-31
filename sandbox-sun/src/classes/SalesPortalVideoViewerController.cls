public with sharing class SalesPortalVideoViewerController {
    public SalesPortalContent__c content {get; set;}

    public SalesPortalVideoViewerController() {
    	loadContent();
    }
    
    public void loadContent() {
    	String salesPortalContentId = ApexPages.currentPage().getParameters().get('id');
        content = [
                select  Id,
                        Name,
                        Link__c,
                        RichText_en__c,
                        KalturaId__c,
                        KalturaThumbnailURL__c
                from    SalesPortalContent__c
                where   Id = :salesPortalContentId
                limit   1
        ];
    }
}