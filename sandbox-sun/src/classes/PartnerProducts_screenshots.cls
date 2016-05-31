public without sharing class PartnerProducts_screenshots {

    public Id partnerProductId {get; set;}
    public Attachment productLogo {get; set;}
    public Attachment screenshot {get; set;}
    public transient Blob   attachmentFile {get;set;}
    public transient String attachmentFilename {get;set;}
    public List<Attachment> partnerProductScreenShots{get; set;}
    public List<PartnerProductScreenshot__c> ProductScreenShots{get; set;}
    public List<PartnerProductLogo__c> ProductLogos{get; set;}
    public List<Attachment> partnerProductLogos{get; set;}


	public ApexPages.StandardController controller {
        get;
        set;
    }


    public PartnerProducts_screenshots(ApexPages.StandardController std)
    {
    	controller = std;
        loadPartnerProductInformation();  
        productLogo = new Attachment(); 
     }

       private void loadPartnerProductInformation() {
          partnerProductId = ApexPages.currentPage().getParameters().get('id');
          System.debug('partnerProductId In Constructor --------->:::'+ partnerProductId);
          if (partnerProductId != null) {
                loadPartnerProductLogos(partnerProductId);
                loadPartnerProductScreenShots(partnerProductId);
           } 
           
    }
     
     private void loadPartnerProductScreenShots(String partnerProductId) {
        ProductScreenShots = [Select Partner__c, PartnerProduct__c, Name, Id  From PartnerProductScreenshot__c where partnerProduct__c=:partnerProductId];
        partnerProductScreenShots = [Select id,name, parentid from Attachment where parentid in :ProductScreenShots];
        if (partnerProductScreenShots == null) {
            partnerProductScreenShots = new List<Attachment>() ; 
        }

     } 
     
     private void loadPartnerProductLogos(String partnerProductId) {
         ProductLogos = [Select PartnerId__c, PartnerProduct__c, Name, Id  From PartnerProductLogo__c where partnerProduct__c=:partnerProductId];
            partnerProductLogos = [Select id,name, parentid from Attachment where parentid in :ProductLogos];
            if (partnerProductLogos == null || partnerProductLogos.size() < 0) {
                partnerProductLogos = new List<Attachment>() ; 
             }
            
     }      

    public PageReference deleteAttachments() {
        System.debug('logoId-------->:::'+ ApexPages.currentPage().getParameters().get('partnerLogoId'));
        System.debug('productId-------->:::'+ ApexPages.currentPage().getParameters().get('partnerProductId'));
        System.debug('screenShotId-------->:::'+ ApexPages.currentPage().getParameters().get('partnerScreenshotId'));
        
        ID partnerLogoId = ApexPages.currentPage().getParameters().get('partnerLogoId');
        ID partnerScreenshotId = ApexPages.currentPage().getParameters().get('partnerScreenshotId');
        if (partnerLogoId != null) {
            Attachment currentAttachment = [Select a.ParentId, a.Name, a.Id From Attachment a where a.ParentId=: partnerLogoId];
            delete currentAttachment;
            PartnerProductLogo__c productLogo = new PartnerProductLogo__c(Id=partnerLogoId);
            delete productLogo;
        }
        if (partnerScreenshotId != null) {
            Attachment currentAttachment = [Select a.ParentId, a.Name, a.Id From Attachment a where a.ParentId=:partnerScreenshotId];
            delete currentAttachment;
            PartnerProductScreenshot__c productScreenshot = new PartnerProductScreenshot__c(Id=partnerScreenshotId);
            delete productScreenshot;
        }
        loadPartnerProductInformation(); 
        return Page.PartnerProducts_screenshots;
    }
    
    public PageReference replaceLogo() {
        if (productLogo.body == null) {
          ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, System.Label.PartnerLogo_please_select_a_file_to_upload));
            return null;
        }
        else{
             loadPartnerProductInformation();
              
            if (ProductLogos.size() > 0){
                delete ProductLogos[0];
            }
            PartnerProductLogo__c partnerProductLogo  = new PartnerProductLogo__c(partnerProduct__c=partnerProductId, ActivationDate__c=system.Today());
            insert partnerProductLogo;
            productLogo.parentid = partnerProductLogo.id;
            insert productLogo;
            productLogo = new Attachment();
            loadPartnerProductInformation();
            return Page.PartnerProducts_screenshots;
        }
    }
    
    public PageReference addScreenshot() {
         if (attachmentFile == null) {
              ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, System.Label.PartnerLogo_please_select_a_file_to_upload));
                return null;
            }
            else{
                 loadPartnerProductInformation();
                 // remmember put the screenshot limit
		        Attachment screenshot = new Attachment(Name = attachmentFilename, Body = attachmentFile); 
                PartnerProductScreenshot__c partnerProductScreenshot  = new PartnerProductScreenshot__c(partnerProduct__c=partnerProductId);
                insert partnerProductScreenshot;
                screenshot.parentid = partnerProductScreenshot.id;
                insert screenshot;
                loadPartnerProductInformation(); 
                return Page.PartnerProducts_screenshots;
           }     
    }

}