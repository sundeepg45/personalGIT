public with sharing class SpecialDealRegistrationController {

    public String leadKeyPrefix;
    public Lead lead {get; set;}
    public String partnerRegKeyPrefix;
    public Id accountId;
    public String accountName;
    public String global_region {get; set;}
    public String dealType {get; set;}
    public User me {get; set;}
    private Boolean isFedSled;

    public SpecialDealRegistrationController() {
        lead = new Lead();
        lead.Special_Deal_Type__c = ApexPages.currentPage().getParameters().get('dealType');
        Schema.DescribeSObjectResult leadSchema = null;
        for (Schema.SObjectType objectType : Schema.getGlobalDescribe().values()) {
            Schema.DescribeSObjectResult d = objectType.getDescribe();
            if (d != null && d.getName() == 'Lead') {
                leadSchema = d;
                break;
            }
        }
        Schema.DescribeSObjectResult regSchema = null;
        for (Schema.SObjectType objectType : Schema.getGlobalDescribe().values()) {
            Schema.DescribeSObjectResult d = objectType.getDescribe();
            if (d != null && d.getName() == 'Partner_Registration__c') {
                regSchema = d;
                break;
            }
        }
        partnerRegKeyPrefix = regSchema.getKeyPrefix();
        leadKeyPrefix = leadSchema.getKeyPrefix();
        me = [select Id, Name, Profile.Name, Contact.AccountId, Contact.Account.Name, Contact.Account.Global_Region__c from User where Id = :UserInfo.getUserId()];
        if (me.Contact == null || me.Contact.Account == null) {
            global_region = 'NA';
            accountName = 'test';
        }
        else {
            global_region = me.Contact.Account.Global_Region__c;
            accountId = me.Contact.AccountId;
            accountName = me.Contact.Account.Name;
        }
        isFedSled = me.Profile.Name.indexOf('Fed/Sled') > 0;
        dealType = ApexPages.currentPage().getParameters().get('dealType');
    }

    public PageReference save() {
        try {
            insert lead;
            return new PageReference('/' + lead.Id);
        } catch(DmlException e) {

        }
        return null;
    }

    public PageReference cancel() {
        return new PageReference('/s/Dashboard');
    }

    private String getDealRegRecordTypeName() {
        if (isFedSled) {
            return 'NA Fed/Sled Deal Registration';
        }
        else {
            if (global_region == 'NA') {
                return global_region + ' Subscription Deal Registration';
            }
        }
        return global_region + ' Deal Registration';
    }

    public Boolean getHasDealRegAccess() {
        return hasLeadRecordTypeAccess(getDealRegRecordTypeName());
    }

    private Boolean hasLeadRecordTypeAccess(String recordTypeName) {
        ID rectypeid = null;
        try {
            rectypeid = [select Id from RecordType where Name = :recordTypeName].Id;
        }
        catch (Exception ex) {
            return false;
        }
        Set<ID> names = getAvailableRecordTypesForSObject((new Lead()).getsObjectType());
        System.debug('*****[debug]***** names for record type ' + recordTypeName);
        for (String name : names) System.debug('*****[debug]***** >> ' + name);
        if (!names.contains(rectypeid)) {
            return false;
        }
        return true;
    }

    private static Set<ID> getAvailableRecordTypesForSObject(Schema.SObjectType objType) {
        Set<ID> names = new Set<ID>();
        List<RecordTypeInfo> infos = objType.getDescribe().getRecordTypeInfos();
        if (infos.size() > 1) {
            for (RecordTypeInfo i : infos) {
               // Ignore the Master Record Type, whose Id always ends with 'AAA'.
               // We check the Id because Name can change depending on the user's language.
               if (i.isAvailable() && !String.valueOf(i.getRecordTypeId()).endsWith('AAA')) {
                   names.add(i.getRecordTypeId());
               }
            }
        }
        // Otherwise there's just the Master record type,
        // so add it in, since it MUST always be available
        else {
            names.add(infos[0].getRecordTypeId());
        }
        return names;
    }
}