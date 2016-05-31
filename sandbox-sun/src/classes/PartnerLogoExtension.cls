public without sharing class PartnerLogoExtension {
    
    private static Set<String> contentTypesAllowed = new Set<String>{'image/png','image/jpeg','image/gif','image/jpg'}; 

    public Account account {get;private set;}
    public PartnerLogo__c logoRecord {get;set;}
    public Attachment logoAttachment {get;private set;}
        
    public String   attachmentContentType {get;set;}
    public String   attachmentFileName {get;set;}
    public transient Blob   attachmentFile {get;set;}
    public String   accountId {get;private set;}
    public String   showHeader {get;private set;}
    

	public PartnerLogoExtension(Id anAccountId) {
		accountId = anAccountId;
	}

    public PartnerLogoExtension(ApexPages.StandardController controller) {
    	/*
		this.account = (Account) controller.getRecord();
		this.accountId = account.Id;
		*/
/*
        this.logoRecord = (PartnerLogo__c) controller.getRecord();
        this.accountId = PageUtils.get('accountId');
		Id i = PageUtils.get('Id');
		if (i != null) {
			accountId = i;
		}
*/
        if (accountId == null) {
	        User me = [select Contact.AccountId from User where Id = :UserInfo.getUserId()];
    	    accountId = me.Contact.AccountId;
        }
    }

    public PageReference doOnLoad() {
        try {
            if (this.logoRecord == null || this.logoRecord.id == null) {
            	List<PartnerLogo__c> logos = [select id, Name, Partner__c from PartnerLogo__c where Partner__c = :accountId];
            	if (logos.size() > 0) {
	                logoRecord = logos.get(0);
            	}
            	else {
            		logoRecord = new PartnerLogo__c();
            		logoRecord.Partner__c = accountId;
            	}            		
            }
            else {
            	logoRecord = [select id, Name, Partner__c from PartnerLogo__c where Id = :logoRecord.id];
            }
        } catch (QueryException e) {
            return null;
        }
        try {
            account = [select id,name from Account where id = :logoRecord.Partner__c];
            logoAttachment = [select id from Attachment where parentid = :logoRecord.id limit 1];
        } catch(QueryException e){}
        return null;
    }
    
    public static Double MAX_BLOB_SIZE_IN_KB {get{return 500;}}
     
    public PageReference doReplaceLogo() {
        if (attachmentFile == null) {
	        ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, System.Label.PartnerLogo_please_select_a_file_to_upload));
            return null;
        }
        
        final Double size = Decimal.valueOf(((Double)attachmentFile.size()/1024)).setScale(2);
        if (size > MAX_BLOB_SIZE_IN_KB) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, System.Label.PartnerLogo_size_exceeds_maximum_file_size));
            return null;
        }
        Savepoint sp = null;
        try { 
            sp = Database.setSavepoint();

//            logoRecord.Name = attachmentFileName;
            if (logoRecord.id == null) {
                insert logoRecord;
            }
            else {
                update logoRecord;
            }

            if (!IsValidContentType(attachmentContentType)) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, System.Label.PartnerLogo_this_file_type_is_not_valid + attachmentContentType+'. \n'+
                                                   System.Label.PartnerLogo_the_formats_allowed_are));
            }

			delete [select id from Attachment where parentid = :logoRecord.id];

//            if (logoAttachment == null) {
                logoAttachment = new Attachment(
                    Body=attachmentFile,
                    ContentType=attachmentContentType,
                    IsPrivate=false,
                    Name=attachmentFileName,
                    ParentID=logoRecord.id
                );              
                insert logoAttachment;
//            }
/*
            else {
                logoAttachment.Body=attachmentFile;
                logoAttachment.IsPrivate=false;
                logoAttachment.Name=attachmentFileName;

                update logoAttachment;  
            }
*/
        } catch(Exception e) {
            Database.rollback(sp);
            ApexPages.addMessages(e);
            return null;
        }
        return null;    
    }
    
    private Boolean IsValidContentType(String contentType) {
        return contentTypesAllowed.contains(contentType);
    }

}