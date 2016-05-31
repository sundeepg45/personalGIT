public without sharing class FinderProfileEditController {

    private static Set<String> contentTypesAllowed = new Set<String>{'image/png','image/jpeg','image/gif','image/jpg'};

    public Account account {get; set;}
    public Attachment logoAttachment {get; private set;}
    public PartnerLogo__c logoRecord {get; set;}
    public boolean isInternalUser {get; set;}

    public String attachmentContentType {get; set;}
    public String attachmentFileName {get; set;}
    public Id accountID {get; private set;}
    public Id contactID {get; private set;}
    public Id userID {get; private set;}
    public String showHeader {get; private set;}
    public transient Blob attachmentFile {get; set;}
    public static Double MAX_BLOB_SIZE_IN_KB {get{return 500;}}
    public List<Partner_Location__c> locations {get; set;}
    public static boolean logoAttached {get; set;}

	public FinderProfileEditController() {

        // Get the accountID from the URL (for internal users)
        accountID = ApexPages.currentPage().getParameters().get('id');
        isInternalUser = true;
        System.debug('[DEBUG]*** is logo attached' + logoAttached);

        // If the accountID is not in the URL, get it from the user context (Partner users).
        if (String.isEmpty(accountID)) {
            isInternalUser = false;
            userID = UserInfo.getUserId();
            contactID = [SELECT ContactID
                            FROM User
                            WHERE Id = :userID].ContactID;
            accountID = [SELECT AccountID
                            FROM Contact
                            WHERE Id = :contactID].AccountID;
        }

        account = [SELECT Id,
                    Company_Email_Address__c,
                    Description_of_Business__c,
                    Industry_Focus__c,
                    Is_Partner_Published__c,
                    Name,
                    Phone,
                    Website
                    FROM Account
                    WHERE Id = :accountID];

        locations = [SELECT Id,
                        City__c,
                        Country__c,
                        Is_Primary__c,
                        Name,
                        State_Province__c,
                        Street__c,
                        Validated__c
                        FROM Partner_Location__c
                        WHERE Partner__r.Id = :accountID];
        System.debug('Locations: ' + locations);
	}

    public PageReference save() {
        update account;
        return null;
    }

    public PageReference cancel() {
        return new PageReference('/s');
    }

    public PageReference onLoad() {
        try {
            if (logoRecord == null || logoRecord.id == null) {
                List<PartnerLogo__c> logos = [SELECT id,
                                                Name,
                                                Partner__c
                                                FROM PartnerLogo__c
                                                WHERE Partner__c = :accountID];
            if (logos.size() > 0) {
                    logoRecord = logos.get(0);
                }
                else {
                    logoRecord = new PartnerLogo__c();
                    logoRecord.Partner__c = accountID;
                    System.debug('Created logoRecord as one did not already exist.');
                }
            }
        } catch (QueryException e) {
            System.debug('Got to the first onLoad query exception catch: ' + e.getMessage());
            return null;
        }
        try {
            logoAttachment = [SELECT Id
                                FROM Attachment
                                WHERE parentid = :logoRecord.id limit 1];
        } catch(QueryException e) {
            System.debug('Got to the second onLoad query exception catch: ' + e.getMessage());
        }
        return null;
    }

    public PageReference replaceLogo() {
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

            if (logoRecord.id == null) {
                insert logoRecord;
            } else {
                update logoRecord;
            }

            if (!isValidContentType(attachmentContentType)) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, System.Label.PartnerLogo_this_file_type_is_not_valid + attachmentContentType+'. \n'+
                                                   System.Label.PartnerLogo_the_formats_allowed_are));
            } else {

                delete [SELECT id
                        FROM Attachment
                        WHERE parentid = :logoRecord.id];

                logoAttachment = new Attachment(
                    Body=attachmentFile,
                    ContentType=attachmentContentType,
                    IsPrivate=false,
                    Name=attachmentFileName,
                    ParentID=logoRecord.id);

                insert logoAttachment;
            }
            logoAttached = true;
        } catch(Exception e) {
            Database.rollback(sp);
            ApexPages.addMessages(e);
            return null;
        }
        return null;
    }

    public PageReference create() {
        if (isInternalUser) {
            return new PageReference('/apex/manageLocation?retURL=/apex/FinderProfileEdit?id=' + account.Id);
        }
        return new PageReference('/apex/manageLocation?retURL=/apex/FinderProfileEdit');
    }

    private boolean isValidContentType(String contentType) {
        return contentTypesAllowed.contains(contentType);
    }

    public PageReference publish() {
        account.Is_Partner_Published__c = !account.Is_Partner_Published__c;
        update account;
        return null;
    }

    public PageReference preview() {
        return new PageReference('/apex/PFPartnerDetail?id=' + Account.Id);
    }
}