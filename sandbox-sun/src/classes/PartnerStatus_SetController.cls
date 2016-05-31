/**
 * This class is the controller used to display 
 * partners for selection on the Manage Opportunity Partner's page.
 *
 * @version 2014-11-03
 * @author Bill C Riemers <briemers@redhat.com>
 * 2014-11-03 - Use partner types specified in the pattern values
 * 2013-03-19 - Updated API version.
 * 2012-06-01 - Updated to support Corporate Reseller
 * Scott Coleman <scoleman@redhat.com>
 * 2015-01-28 - Merged in US57705 New/Updated partner types 
 */
public without sharing class PartnerStatus_SetController {
    private Id partnerTierId;
    private Id partnerTypeId;
    private Set<String> allowedPartnerTypes = new Set<String>();
    private Set<Id> recordTypeIds = new Set<Id>();
    
    public PartnerStatus_SetController()
    {
        Map<String,String> paramMap = ApexPages.currentPage().getParameters();
        partnerStatusIdField = paramMap.get('partnerStatusIdField');
        System.debug('partnerStatusIdField='+partnerStatusIdField);
        partnerNameField = paramMap.get('partnerNameField');
        System.debug('partnerNameField='+partnerNameField);
        partnerTierId = paramMap.get('partnerTierId');
        System.debug('partnerTierId='+partnerTierId);
        partnerTypeId = paramMap.get('partnerTypeId');
        System.debug('partnerTypeId='+partnerTypeId);
        String transactionRole = paramMap.get('transactionRole');
        if(transactionRole == Opportunity_ManagePartners.FINANCIAL)
        {
            

            

            

            String channel = paramMap.get('channel');
            if(channel != null && ! Opportunity_ManagePartners.NO_FINANCIAL_PARTNER_CHANNELS.contains(channel))
            {
                allowedPartnerTypes = new Set<String>();
                if(channel=='Distributor')
                {
                    allowedPartnerTypes.addAll(Opportunity_ManagePartners.PATTERN_FINANCIAL_DISTRIBUTOR.split('\\|',0));
                }
                else if(channel == 'Direct Reseller')
                {
                    allowedPartnerTypes.addAll(Opportunity_ManagePartners.PATTERN_FINANCIAL_DIRECT_RESELLER.split('\\|',0));
                }
                else if(channel=='OEM')
                {
                    allowedPartnerTypes.addAll(Opportunity_ManagePartners.PATTERN_FINANCIAL_OEM.split('\\|',0));
                }
                else // this is a channel we know nothing about, so offer everything
                {
                    allowedPartnerTypes.addAll(Opportunity_ManagePartners.PATTERN_FINANCIAL_DISTRIBUTOR.split('\\|',0));
                    allowedPartnerTypes.addAll(Opportunity_ManagePartners.PATTERN_FINANCIAL_DIRECT_RESELLER.split('\\|',0));
                    allowedPartnerTypes.addAll(Opportunity_ManagePartners.PATTERN_FINANCIAL_OEM.split('\\|',0));
                }
            }
        }
        else if(transactionRole == Opportunity_ManagePartners.INFLUENCING)
        {
            allowedPartnerTypes = new Set<String>(Opportunity_ManagePartners.PATTERN_INFLUENCING.split('\\|',0));
        }
        else // assume reseller
        {
            allowedPartnerTypes = new Set<String>(Opportunity_ManagePartners.PATTERN_RESELLER.split('\\|',0));
        }
        System.debug('allowedPartnerTypes='+allowedPartnerTypes);
        String recordTypeName = paramMap.get('recordTypeName');     
        System.debug('recordTypeName='+recordTypeName);
        Map<String,Set<Id>> m = Opportunity_ManagePartners.getAccountRecordTypeIdByRegion();
        if(recordTypeName != null) {
            System.debug('regionNames='+m.keySet());
            for(String regionName : m.keySet())
            {
                System.debug('Compare '+recordTypeName+' with '+regionName);
                if(recordTypeName == regionName || recordTypeName.startsWith(regionName+' ') || recordTypeName.contains(' '+regionName+' ') || recordTypeName.endsWith(' '+regionName))
                {
                    System.debug('got '+regionName);
                    recordTypeIds.addAll(m.get(regionName));
                    System.debug('recordTypeIds='+recordTypeIds);
                    break;
                }
            }
        }
        if(recordTypeIds.isEmpty())
        {
            for(Set<Id> ids : m.values())
            {
                recordTypeIds.addAll(ids);
            }   
        }
        System.debug('recordTypeIds='+recordTypeIds);
        searchString = paramMap.get('partnerName');
    }
    
    public ApexPages.StandardSetController partnerStatusRecords{
        get {
            if(partnerStatusRecords == null) {
                String s = searchString;
                if(s == null) {
                    s = '';
                }
                s=s.replace('%','_').replace('*','%').replace('?','_')+'%';
                System.debug('searchString='+s);
                Integer maxQuerySize = 100*((10000 - Limits.getQueryRows() - 100)/100);
                partnerStatusRecords = new ApexPages.StandardSetController(Database.getQueryLocator([
                    select Partner__r.Name,
                        Partner__r.Account_Alias_Name__c,
                        Partner__r.Site,
                        Partner__r.OracleAccountNumber__c,
                        PartnerTier__r.Hierarchy__c,
                        PartnerType__r.Hierarchy__c,
                        Partner__r.Type,
                        Partner__r.Owner.Alias,
                        Partner__r.RecordType.Name
                    from PartnerStatus__c 
                    where Partner__r.Name like :s
                        and (PartnerTier__c = :partnerTierId or PartnerTier__r.Parent__c = :partnerTierId)
                        and (PartnerType__c = :partnerTypeId or PartnerType__r.Parent__c = :partnerTypeId or PartnerType__r.Parent__r.Parent__c = :partnerTypeId)
                        and ActivationStatus__c = 'Active'
                        and Partner__r.RecordTypeId in :recordTypeIds
                        and (PartnerType__r.Parent__r.Name != 'Partner Type' or PartnerType__r.Name in :allowedPartnerTypes)
                        and (PartnerType__r.Parent__r.Parent__r.Name != 'Partner Type' or PartnerType__r.Parent__r.Name in :allowedPartnerTypes)
                    order by Partner__r.Name,PartnerType__r.Hierarchy__c,PartnerTier__r.Hierarchy__c
                    limit :maxQuerySize ] ));
            }
            return partnerStatusRecords;
        }
        private set;
    }

    public String searchString {
        get;
        set {
            if(value != searchString) {
                searchString = value;
                partnerStatusRecords = null;
            }
        }
    }
    
    public String partnerNameField {
        get;
        set;
    }
    
    public String partnerStatusIdField {
        get;
        set;
    }
    
    public Integer getPageCount() {
        Integer rs = partnerStatusRecords.getResultSize();
        Integer ps = partnerStatusRecords.getPageSize();
        return (ps+rs-1)/ps;
    }
    
    public PageReference updateSearchString()
    {
        return null;
    }
    
    public List<PartnerStatus__c> getPartnerStatusPagination() {
        return (List<PartnerStatus__c>) partnerStatusRecords.getRecords();
    }
    
    public PageReference first()
    {
        partnerStatusRecords.first();
        return null;
    }
    
    public PageReference next()
    {
        partnerStatusRecords.next();
        return null;
    }
    
    public PageReference previous()
    {
        partnerStatusRecords.previous();
        return null;
    }
    
    public PageReference last()
    {
        partnerStatusRecords.last();
        return null;
    }
    
}