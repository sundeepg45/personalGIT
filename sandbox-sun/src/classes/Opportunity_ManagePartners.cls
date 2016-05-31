/**
 * This is the controller extension used by the Opportunity_ManagePartner page.
 *
 * @author Bill C Riemers <briemers@redhat.com>
 * @version 2015-02-05
 * 2013-03-19 - Updated API version.
 * 2011-12-20 - ?
 * Scott Coleman <scoleman@redhat.com>
 * 2015-02-05 - Fixed bug for non-regional opp record types
 * 2015-01-16 - Merged in US57705 New/Updated partner types - moved partner type patterns into custom settings
 * 2014-12-15 - Added support for non-regional opp record types (originally for Master Claim)
 * 2013-07-15 - Implemented Opp Lock
 */
public without sharing class Opportunity_ManagePartners {
    // This is a DateTime value older than the oldest PartnerStatus__c record.
    public static final DateTime OLDEST_DATETIME = DateTime.newInstance(2010,1,1);
    // Make this the newest date time without too many PartnerStatus__c records for 
    // one query.
    public static DateTime SAFE_DATETIME = DateTime.newInstance(2011,8,5);
    public static final String FINANCIAL = 'Financial';
    public static final String INFLUENCING = 'Influencing';
    public static final String OTHER = 'Other';
    public static final String PARTNER_TIER_ROOTKEY = 'PARTNER_TIER';
    public static final String PARTNER_TYPE_ROOTKEY = 'PARTNER_TYPE';
    // this value needs to be true if the reseller validation rules are activated
    public static Boolean RESELLER_REQUIRED = false;
    // Changes in code due to Channel pick list value changes
    // Pankaj Banik <pbanik@redhat.com>
    public static final Set<String> FINANCIAL_PARTNER_CHANNELS = new Set<String>{
        'OEM', 'Direct Reseller', 'Distributor' };
    public static final Set<String> NO_FINANCIAL_PARTNER_CHANNELS = new Set<String>{
        'Direct End Customer', 'Webstore' };
    public static final Set<String> NA_EMEA_RESELLER_PARTNER_CHANNELS = new Set<String>{
        'Distributor' };
    public static final Set<String> NA_RESELLER_PARTNER_CHANNELS = new Set<String>{
        'OEM', 'Distributor' };  
        
    // For these record types the UI should not limit available partners by region
    public static final Set<String> GLOBAL_RECORD_TYPES = new Set<String>{
        'Master Claim Opportunity', 'Master Claim', 
        //'Commission Claim Opportunity', 'Commission Claim', 
        //'ICC Opportunity', 'ICC',
        'Overlay Credit'
        };

    public static final Map<String,Schema.RecordTypeInfo> accountRecordTypeInfosByName =
        Account.SObjectType.getDescribe().getRecordTypeInfosByName();
    private static final Map<String,PartnerStatus__c> partnerStatusByRegion = new Map<String,PartnerStatus__c>();

    // A default limit of 1 is applied.  So we only need to specify the limits
    // for values allowed more than 1 record.
    public static Map<String,Integer> RELATIONAL_TYPE_LIMITS = new Map<String,Integer> {
        INFLUENCING=>5
    };

    //
    // private vars
    //
    private ApexPages.StandardController controller;

    private Opportunity opportunity;
    
    private Set<Id> requiredPartnerIds = new Set<Id>();
    private Set<Id> queriedPartnerIds = null;

    public Opportunity_ManagePartners(ApexPages.StandardController controller) {
        this.controller = controller;
        this.opportunity = [
            select Name,
                RecordType.Name,
                FulfillmentChannel__c,
                FinancialPartnerName__c,
                IsLockedForSales__c,
                StageName
            from Opportunity where Id = :controller.getId() ];
        if(isOppLocked) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING,System.Label.Opp_Lock_Message));
        }
    }

    private static String getStringSetting(String key,String defaultValue) {
        StringSetting__c s = StringSetting__c.getInstance(key);
        if(s != null) {
            defaultValue = s.Value__c;
        }
        return defaultValue;
    }

    public static Boolean isFinancialPartnerRequired(Opportunity opp)
    {
        return (
            (opp.FinancialPartnerName__c == null || opp.FinancialPartnerName__c == '') 
            && (! opp.StageName.startsWith('Closed'))
            && FINANCIAL_PARTNER_CHANNELS.contains(opp.FulfillmentChannel__c));
    }

    public static Boolean isFinancialPartnerRequired(Id oppId)
    {
        Boolean retval = false;
        for(Opportunity opp : [select FinancialPartnerName__c, FulfillmentChannel__c, StageName from Opportunity where Id = :oppId]) {
            system.debug('opp select values'+opp);
            retval = isFinancialPartnerRequired(opp);
        }
        return retval;
    }

    public static Boolean isGlobalRecordType(Opportunity opp)
    {
        return (GLOBAL_RECORD_TYPES.contains(opp.RecordType.Name));
    }

    // standard page methods
    private static String getPageParam(String name)
    {
        return ApexPages.currentPage().getParameters().get(name);
    }

    private static void addMessage(ApexPages.Severity severity, String message) {
        ApexPages.addMessage(new ApexPages.Message(severity, message));
    }

    private static void addMessage(String message)
    {
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, message));
    }

    public static void addExceptionMessage(Exception e)
    {
        ApexPages.addMessages(e);
    }

    public static void addExceptionMessage(String message)
    {
        addMessage(ApexPages.Severity.ERROR, message);
    }

    public static void addConfirmationMessage()
    {
        addMessage(ApexPages.Severity.CONFIRM, 'Changes have been saved successfully.');
    }

    public static Boolean hasMessages(ApexPages.Severity severity)
    {
        for(ApexPages.Message message : ApexPages.getMessages()) {
            if (message.getSeverity() == severity) {
                return true;
            }
        }
        return false;
    }

    private static List<Classification__c> getClassificationList(String rootKey)
    {
        return [
            select 
                Id,
                Hierarchy__c, 
                Name, 
                HierarchyDepth__c, 
                Descendents__c,
                Parent__c
            from Classification__c
            where IsActive__c = true and (HierarchyKey__c = :rootKey or HierarchyKey__c like :rootKey+'.%' )
            order by Hierarchy__c asc ];
    }

    static Map<String,Set<Id>> accountRecordTypeIdByRegion = null;
    public static Map<String,Set<Id>> getAccountRecordTypeIdByRegion()
    {
        if(accountRecordTypeIdByRegion == null)
        {
            Map<String,Set<Id>> retval = new Map<String,Set<Id>>();
            for(String name :  accountRecordTypeInfosByName.keySet())
            {
                Schema.RecordTypeInfo accountRecordTypeInfo = accountRecordTypeInfosByName.get(name);
                String region = name;
                if(name.startsWith('APAC '))
                {
                    region = 'APAC';
                }
                else if(name.startsWith('EMEA '))
                {
                    region = 'EMEA';
                }
                else if(name.startsWith('LATAM '))
                {
                    region = 'LATAM';
                }
                else if(name.startsWith('NA '))
                {
                    region = 'NA';
                }
                Set<Id> idSet = retval.get(region);
                if(idSet == null)
                {
                    idSet = new Set<Id>();
                    retval.put(region,idSet);
                }
                idSet.add(accountRecordTypeInfo.getRecordTypeId());
            }
            accountRecordTypeIdByRegion = retval;
        }
        return accountRecordTypeIdByRegion;
    }
    
    static List<Classification__c>  completePartnerTierList = null;

    public static List<Classification__c>  getCompletePartnerTierList()
    {
        if(completePartnerTierList == null) {
            completePartnerTierList = getClassificationList(PARTNER_TIER_ROOTKEY);
        }
        return completePartnerTierList;
    }

    public static Id rootPartnerTierId {
        get {
            if(rootPartnerTierId == null) {
                Id retval = null;
                List<Classification__c>  xcompletePartnerTierList = getCompletePartnerTierList();
                if(! xcompletePartnerTierList.isEmpty()) {
                    retval = xcompletePartnerTierList.get(0).Id;
                }
                else {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'The partner tier classification is missing.'));   
                }
                rootPartnerTierId = retval;
            }
            return rootPartnerTierId;
        }
    }

    static Map<Id,Classification__c> partnerTierMap = null;
    
    public static Map<Id,Classification__c> getPartnerTierMap()
    {
        if(partnerTierMap == null) {
            partnerTierMap = new Map<Id,Classification__c>(getCompletePartnerTierList());
        }
        return partnerTierMap;
    }

    static List<Classification__c>  completePartnerTypeList = null;
    
    public static List<Classification__c>  getCompletePartnerTypeList()
    {
        if(completePartnerTypeList == null) {
            completePartnerTypeList = getClassificationList(PARTNER_TYPE_ROOTKEY);
        }
        return completePartnerTypeList;
    }

    public static Id rootPartnerTypeId {
        get {
            if(rootPartnerTypeId == null) {
                Id retval = null;
                List<Classification__c> xcompletePartnerTypeList = getCompletePartnerTypeList();
                if(! xcompletePartnerTypeList.isEmpty()) {
                    retval = xcompletePartnerTypeList.get(0).Id;
                }
                else {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'The partner type classification is missing.'));   
                }
                rootPartnerTypeId = retval;
            }
            return rootPartnerTypeId;
        }
    }

    static Map<Id,Classification__c> partnerTypeMap = null;
    
    public static Map<Id,Classification__c> getPartnerTypeMap()
    {
        if(partnerTypeMap == null) {
            partnerTypeMap = new Map<Id,Classification__c>(getCompletePartnerTypeList());
        }
        return partnerTypeMap;
    }

    private static List<Schema.Picklistentry> relationshipTypePicklistentryList {
        get {
            if(relationshipTypePicklistentryList == null) {
                relationshipTypePicklistentryList = OpportunityPartner__c.RelationshipType__c.getDescribe().getPicklistValues();
            }
            return relationshipTypePicklistentryList;
        }
    }

    private static final Map<String,Pattern> partnerTypePatternMap = new Map<String,Pattern>();

    public static String PATTERN_FINANCIAL_DISTRIBUTOR {
        get {
            return getStringSetting('Pattern.Financial.Distributor','Distributor|ISP|ISV|Reseller|SI|Systems Integrator');
        }
    }

    public static String PATTERN_FINANCIAL_OEM {
        get {
            return getStringSetting('Pattern.Financial.OEM','OEM');
        }
    }

    public static String PATTERN_FINANCIAL_DIRECT_RESELLER {
        get {
            return getStringSetting('Pattern.Financial.DirectReseller','Distributor|Reseller|SI|Systems Integrator');
        }
    }

    public static String PATTERN_INFLUENCING {
        get {
            return getStringSetting('Pattern.Influencing','Global Chip|ISV|OEM|Reseller|SI|Systems Integrator|Training|Service/Cloud Provider');
        }
    }

    public static String PATTERN_RESELLER {
        get {
            return getStringSetting('Pattern.Reseller','Distributor|ISP|Reseller|Corporate Reseller|ISV|OEM|SI|Systems Integrator|Training|Service/Cloud Provider');
        }
    }

    public static Pattern getPartnerTypePattern(String channel,String rt) {
        Pattern retval = null;
        if(channel != null && rt != null) {
            system.debug('channel test value'+channel +'value of rt'+rt);
            final String key = channel+':'+rt;
            retval = partnerTypePatternMap.get(key);
            if(retval == null) {
                final String startPattern = '^Partner Type » ((';
                final String endPattern = ')( » .*)*)$';
                retval = Pattern.compile(startPattern+'.*'+endPattern);
                if(rt == Opportunity_ManagePartners.FINANCIAL) {
                    if(Opportunity_ManagePartners.NO_FINANCIAL_PARTNER_CHANNELS.contains(channel)) {
                        retval = Pattern.compile('^$');
                    }
                    // Changes in code due to Channel pick list value changes
                    // Pankaj Banik <pbanik@redhat.com>
                    //else if(channel.contains('VAR/VAD')) {
                    else if(channel=='Distributor') {
                        retval = Pattern.compile(
                            startPattern + PATTERN_FINANCIAL_DISTRIBUTOR + endPattern);
                        system.debug('retval Distributor'+retval);
                    }
                    //else if(channel.endsWith(' OEM') || channel.contains(' OEM ')) {
                    else if(channel=='OEM') {
                        retval = Pattern.compile(
                            startPattern + PATTERN_FINANCIAL_OEM + endPattern);
                        system.debug('retVal OEM'+retval);
                    }
                    //else if(channel.endsWith(' DLT') || channel.endswith('Carahsoft')) {
                    else if (channel == 'Direct Reseller'){
                    // End of code change
                        retval = Pattern.compile(
                            startPattern + PATTERN_FINANCIAL_DIRECT_RESELLER + endPattern);
                        system.debug('retVal Distributor|Reseller'+retval);
                    }
                }
                else if(rt == Opportunity_ManagePartners.INFLUENCING) {
                    retval = Pattern.compile(
                        startPattern + PATTERN_INFLUENCING + endPattern);
                    system.debug('retVal Influencing'+retval);
                }
                else if(rt.startsWith('Reseller ')) {
                    retval = Pattern.compile(
                        + startPattern + PATTERN_RESELLER + endPattern);
                    system.debug('retVal Reseller'+retval);
                }
                partnerTypePatternMap.put(key,retval);
            }
        }
        return retval;
    }

    public DateTime startDateTime = OLDEST_DATETIME;
    
    public Boolean getNeedsFillPartnerStatusMaps()
    {
        return (startDateTime != null);
    }
    
    //transient 
    Map<Id,Id> partnerTypeIdByPartnerStatusIdMap = null;

    public Map<Id,Id> getPartnerTypeIdByPartnerStatusIdMap()
    {
        if(startDateTime != null || partnerTypeIdByPartnerStatusIdMap == null) {
            fillPartnerStatusMaps();
        }
        return partnerTypeIdByPartnerStatusIdMap;
    }

    //transient 
    Map<Id,Id> partnerTierIdByPartnerStatusIdMap = null;

    public Map<Id,Id> getPartnerTierIdByPartnerStatusIdMap()
    {
        if(startDateTime != null || partnerTierIdByPartnerStatusIdMap == null) {
            fillPartnerStatusMaps();
        }
        return partnerTierIdByPartnerStatusIdMap;
    }

    //transient 
    Map<Id,Map<String,Map<Id,PartnerStatus__c>>> partnerStatusRecordTypeIdTypeHierarchyMap = null;

    public Map<Id,Map<String,Map<Id,PartnerStatus__c>>> getPartnerStatusRecordTypeIdTypeHierarchyMap()
    {
        if(startDateTime != null || partnerStatusRecordTypeIdTypeHierarchyMap == null) {
            fillPartnerStatusMaps();
        }
        return partnerStatusRecordTypeIdTypeHierarchyMap;
    }

    //transient 
    Map<Id,Map<Id,PartnerStatus__c>> partnerStatusMapByIdMap = null;

    public Map<Id,Map<Id,PartnerStatus__c>> getPartnerStatusMapByIdMap()
    {
        if(startDateTime != null || partnerStatusMapByIdMap == null) {
            fillPartnerStatusMaps();
        } 
        return partnerStatusMapByIdMap;
    }

    
    public void addPartners(Set<Id> partnerIds)
    {
        if(! requiredPartnerIds.containsAll(partnerIds)) {
            requiredPartnerIds.addAll(partnerIds);
            fillPartnerStatusMaps();
        }
    }
    
    
    private void addPartnerStatuses(List<PartnerStatus__c> currentList)
    {
        if(partnerStatusMap == null) fillPartnerStatusMaps();

        for(PartnerStatus__c p : currentList)
        {
            partnerTypeIdByPartnerStatusIdMap.put(p.Id,p.PartnerType__c);
            partnerTierIdByPartnerStatusIdMap.put(p.Id,p.PartnerTier__c);
            Map<String,Map<Id,PartnerStatus__c>> m2 = partnerStatusRecordTypeIdTypeHierarchyMap.get(p.Partner__r.RecordTypeId);
            if(m2 == null) {
                partnerStatusRecordTypeIdTypeHierarchyMap.put(p.Partner__r.RecordTypeId,(m2 = new Map<String,Map<Id,PartnerStatus__c>>()));
            }
            Map<Id,PartnerStatus__c> m = m2.get(p.PartnerType__r.Hierarchy__c);
            if(m == null) {
                m2.put(p.PartnerType__r.Hierarchy__c,(m=new Map<Id,PartnerStatus__c>()));
            }
            m.put(p.Id,p);
            m = partnerStatusMapByIdMap.get(p.PartnerType__c);
            if(m == null) {
                partnerStatusMapByIdMap.put(p.PartnerType__c,(m=new Map<Id,PartnerStatus__c>()));
            }
            m.put(p.Id,p);
            m = partnerStatusMapByIdMap.get(p.PartnerTier__c);
            if(m == null) {
                partnerStatusMapByIdMap.put(p.PartnerTier__c,(m=new Map<Id,PartnerStatus__c>()));
            }
            m.put(p.Id,p);
            m = partnerStatusMapByIdMap.get(p.Partner__c);
            if(m == null) {
                partnerStatusMapByIdMap.put(p.Partner__c,(m=new Map<Id,PartnerStatus__c>()));
            }
            m.put(p.Id,p);
        }
        partnerStatusMap.putAll(new Map<Id,PartnerStatus__c>(currentList));
    }
    
    public PageReference fillPartnerStatusMaps() {
        Boolean firstTime = (partnerStatusMap == null);
        Set<DateTime> createdDates = new Set<DateTime>();
        if(firstTime) {
            queriedPartnerIds = new Set<Id>();
            partnerStatusMapByIdMap = new Map<Id,Map<Id,PartnerStatus__c>>();
            partnerTypeIdByPartnerStatusIdMap = new Map<Id,Id>();
            partnerTierIdByPartnerStatusIdMap = new Map<Id,Id>();
            partnerStatusMap = new Map<Id,PartnerStatus__c>();
            partnerStatusRecordTypeIdTypeHierarchyMap = new Map<Id,Map<String,Map<Id,PartnerStatus__c>>>();
            for(AggregateResult ar : [
                    select max(CreatedDate) maxCreatedDate 
                    from PartnerStatus__c
                    where ActivationStatus__c = 'Active'
                        and PartnerTier__c != null
                        and PartnerType__c != null
                        and Partner__c != null
                        and PartnerTier__r.Parent__c != null
                        and PartnerType__r.Parent__c != null
                        and CreatedDate < :SAFE_DATETIME
                    group by PartnerTier__c, PartnerType__c,Partner__r.RecordTypeId ])
            {
                createdDates.add((DateTime)ar.get('maxCreatedDate'));
            }
            startDateTime = SAFE_DATETIME;
        }
        Boolean needsPartnerInfoUpdate = false;
        if(startDateTime != null) {
            Integer maxQuerySize = (Limits.getLimitQueryLocatorRows() - Limits.getQueryLocatorRows());
            Integer maxQuerySize2 = (Limits.getLimitQueryRows() - Limits.getQueryRows() - requiredPartnerIds.size() - 500);
            if(maxQuerySize > maxQuerySize2) maxQuerySize = maxQuerySize2;
            System.debug('maxQuerySize='+maxQuerySize);
            if(maxQuerySize >= 500) {
                ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(Database.getQueryLocator([
                    select Id, Name,
                        Partner__c, 
                        Partner__r.Name,
                        Partner__r.RecordTypeId,
                        PartnerTier__c,
                        PartnerTier__r.Hierarchy__c,
                        PartnerTier__r.Name,
                        PartnerType__c,
                        PartnerType__r.Hierarchy__c,
                        PartnerType__r.Name,
                        CreatedDate
                    from PartnerStatus__c
                    where ActivationStatus__c = 'Active'
                        and PartnerTier__c != null
                        and PartnerType__c != null
                        and Partner__c != null
                        and PartnerTier__r.Parent__c != null
                        and PartnerType__r.Parent__c != null
                        and CreatedDate >= :startDateTime
                    order by CreatedDate asc limit :maxQuerySize] ));
                Integer resultSize = ssc.getResultSize();
                DateTime endDateTime = null;
                if(resultSize > 0) {
                    needsPartnerInfoUpdate = ! firstTime;
                    ssc.setPageSize(1);
                    ssc.last();
                    List<PartnerStatus__c> currentList = (List<PartnerStatus__c>)ssc.getRecords();
                    PartnerStatus__c lastPS = currentList.get(currentList.size()-1);
                    addPartnerStatuses(currentList);
                    if(resultSize > 1) {
                        List<AggregateResult> ars = null;
                        if(resultSize == maxQuerySize) {
                            endDateTime = lastPS.CreatedDate;
                            ars = [
                                select max(CreatedDate) maxCreatedDate 
                                from PartnerStatus__c
                                where ActivationStatus__c = 'Active'
                                    and PartnerTier__c != null
                                    and PartnerType__c != null
                                    and Partner__c != null
                                    and PartnerTier__r.Parent__c != null
                                    and PartnerType__r.Parent__c != null
                                    and CreatedDate >= :startDateTime
                                    and CreatedDate < :endDateTime
                                group by PartnerTier__c, PartnerType__c,Partner__r.RecordTypeId ];
                        }
                        else {
                            ars = [
                                select max(CreatedDate) maxCreatedDate 
                                from PartnerStatus__c
                                where ActivationStatus__c = 'Active'
                                    and PartnerTier__c != null
                                    and PartnerType__c != null
                                    and Partner__c != null
                                    and PartnerTier__r.Parent__c != null
                                    and PartnerType__r.Parent__c != null
                                    and CreatedDate >= :startDateTime
                                group by PartnerTier__c, PartnerType__c,Partner__r.RecordTypeId ];
                        }
                        for(AggregateResult ar : ars ) {
                            createdDates.add((DateTime)ar.get('maxCreatedDate'));
                        }
                    }
                }
                startDateTime = endDateTime;
            }
        }
        Set<Id> partnerIds = requiredPartnerIds.clone();
        partnerIds.removeAll(queriedPartnerIds);
        if((! partnerIds.isEmpty())||!createdDates.isEmpty()) {
            List<PartnerStatus__c> currentList = [
                select Id, 
                    Partner__c, 
                    Partner__r.Name,
                    Partner__r.RecordTypeId,
                    PartnerTier__c,
                    PartnerTier__r.Hierarchy__c,
                    PartnerTier__r.Name,
                    PartnerType__c,
                    PartnerType__r.Hierarchy__c,
                    PartnerType__r.Name,
                    LastModifiedDate
                from PartnerStatus__c
                where ActivationStatus__c = 'Active'
                    and PartnerTier__c != null
                    and PartnerType__c != null
                    and Partner__c != null
                    and PartnerTier__r.Parent__c != null
                    and PartnerType__r.Parent__c != null
                    and (not Id in :partnerStatusMap.keySet())
                    and (CreatedDate in :createdDates or Partner__c in :partnerIds) ];
            if(! currentList.isEmpty()) {
                needsPartnerInfoUpdate = ! firstTime;
                addPartnerStatuses(currentList);
            }
            queriedPartnerIds.addAll(partnerIds);
        }
        if(needsPartnerInfoUpdate) {
            // we need to update all the options lists to include the new values that have been added.
            for(Opportunity_PartnerInfo opi : getPartnerInfoList()) {
                opi.updateShowAllRegions();
            }
        }
        return null;
    }

    //transient
    Map<Id,PartnerStatus__c> partnerStatusMap = null;

    public Map<Id,PartnerStatus__c> getPartnerStatusMap() {
        if(startDateTime != null || partnerStatusMap == null) fillPartnerStatusMaps();
        return partnerStatusMap;
    }

    Map<String,Integer> relationshipTypeMap = null;
    private Map<String,Integer> getRelationshipTypeMap() {
        if(relationshipTypeMap == null)
        {
            relationshipTypeMap = new Map<String,Integer>();
            if(NO_FINANCIAL_PARTNER_CHANNELS.contains(opportunity.FulfillmentChannel__c)) {
                relationshipTypeMap.put(FINANCIAL,1);
            }
            for(Opportunity_PartnerInfo partnerInfo : getPartnerInfoList()) {
                OpportunityPartner__c opportunityPartner = partnerInfo.opportunityPartner;
                if(opportunityPartner.Id != null) {
                    Integer count = relationshipTypeMap.get(opportunityPartner.RelationshipType__c);
                    relationshipTypeMap.put(opportunityPartner.RelationshipType__c,(count == null)?1:(count+1));
                }
            }
        }
        return relationshipTypeMap;
    }

    private void setRelationshipTypeMap(Map<String,Integer> value) {
        relationshipTypeMap = value;
        relationshipTypeOptions = null;
    }

    //
    // Opportunity and Account IDs
    //
    public Opportunity getOpportunity()
    {
        system.debug('test opportunity passed -->'+opportunity);
        return opportunity;
    }

    public Boolean isFinancialPartnerRequired {
        get {
            return isFinancialPartnerRequired(opportunity);
        }
    }

    public Boolean isOppLocked {
        get {
            Boolean oppLocked = false;
            AdminByPass__c bypass = AdminByPass__c.getInstance();
            if(bypass != null) {
                oppLocked = opportunity.IsLockedForSales__c && bypass.IsSalesUser__c;
            }
            return oppLocked;
        }
    }

    public Boolean isGlobalRecordType {
        get {
            return isGlobalRecordType(opportunity);
        }
    }

    private List<Opportunity_PartnerInfo> partnerInfoList = null;
    
    public List<Opportunity_PartnerInfo> getPartnerInfoList()
    {
        if(partnerInfoList == null)
        {
            partnerInfoList = new List<Opportunity_PartnerInfo>();
            final List<OpportunityPartner__c> opportunityPartnerList = new List<OpportunityPartner__c>();
            try
            {
                opportunityPartnerList.addAll([
                    select Id,
                        Partner__c,
                        PartnerTier__c,
                        PartnerTier__r.Hierarchy__c,
                        PartnerTier__r.Name,
                        PartnerType__c,
                        PartnerType__r.Hierarchy__c,
                        PartnerType__r.Name,
                        
                        //added here by Deloitte
                        Partner_Contact__c,
                        RelationshipType__c
                    from OpportunityPartner__c
                    where Opportunity__c = :opportunity.Id
                    order by RelationshipType__c asc, Name asc ]);
            } 
            catch (System.DmlException dmlException)
            {
                addExceptionMessage(dmlException);
            }
            Boolean hasFinancial = false;
            Set<Id> partnerIds = new Set<Id>();
            for(OpportunityPartner__c opportunityPartner : opportunityPartnerList)
            {
                partnerIds.add(opportunityPartner.Partner__c);
                hasFinancial = hasFinancial || (opportunityPartner.RelationshipType__c == FINANCIAL);
                partnerInfoList.add(new Opportunity_PartnerInfo(this,opportunityPartner));
            }
            addPartners(partnerIds);
            partnerInfoList.add(null);
            if((! hasFinancial)&& isFinancialPartnerRequired(opportunity))
            {
                Opportunity_PartnerInfo p = new Opportunity_PartnerInfo(this);
                partnerInfoList.add(0,p);
                p.opportunityPartner.RelationshipType__c = FINANCIAL;
                p.isRequired=true;
                if(isGlobalRecordType) {
                    p.showAllRegions = true;
                    p.updateShowAllRegions();
                }               
            }
            partnerInfoList.remove(partnerInfoList.size()-1);
        }
        return partnerInfoList;
    }

    public void setPartnerInfoList(List<Opportunity_PartnerInfo> value) {
        partnerInfoList = value;
        setRelationshipTypeMap(null);
    }

    public Boolean getPartnerInfoListIsEmpty()
    {
        return getPartnerInfoList().isEmpty();
    }

    private List<SelectOption> relationshipTypeOptions = null;
    
    public List<SelectOption> getRelationshipTypeOptions()
    {
        if(relationshipTypeOptions == null) {
            final List<SelectOption> selectOptions = new List<SelectOption>();
            selectOptions.add(new SelectOption('', '--None--'));
            Boolean needsReseller = true;
            Map<String,Integer> xrelationshipTypeMap = getRelationshipTypeMap();
            for(Schema.Picklistentry entry : relationshipTypePicklistentryList) {
                final String value = entry.getValue();
                final SelectOption selectOption = new SelectOption(
                    value, entry.getLabel());
                final Integer count = xrelationshipTypeMap.get(value);
                Boolean disabled = (!needsReseller)&&value.startsWith('Reseller ');
                if(count != null) {
                    Integer valueLimit = RELATIONAL_TYPE_LIMITS.get(value);
                    disabled = disabled || (valueLimit == null)||(count >= valueLimit);
                }
                else if(needsReseller) {
                    needsReseller = ! value.startsWith('Reseller ');
                }
                selectOption.setDisabled(disabled);
                selectOptions.add(selectOption);
            }
            relationshipTypeOptions = selectOptions;
        }
        return relationshipTypeOptions;
    }

    public Boolean getHasAvailableRelationshipTypeOptions()
    {
        Boolean retval = false;
        for(SelectOption selectOption : getRelationshipTypeOptions())
        {
            if(! selectOption.getDisabled())
            {
                String value = selectOption.getValue();
                if(value != null && value != '')
                {
                    retval=true;
                    break;
                }
            }
        }
        return retval;
    }

    public void cancelEdit(Integer id)
    {
        List<Opportunity_PartnerInfo> xpartnerInfoList = getPartnerInfoList();
        for(Integer i=0;i<xpartnerInfoList.size();i++)
        {
            Opportunity_PartnerInfo partnerInfo = xpartnerInfoList.get(i);
            if(id == partnerInfo.id)
            {
                if(! partnerInfo.isNew)
                {
                    try
                    {
                        OpportunityPartner__c opportunityPartner = [
                            select Id,
                                Partner__c,
                                PartnerTier__c,
                                PartnerTier__r.Hierarchy__c,
                                PartnerTier__r.Name,
                                PartnerType__c,
                                PartnerType__r.Hierarchy__c,
                                PartnerType__r.Name,
                                Partner_Contact__c,
                                RelationshipType__c
                            from OpportunityPartner__c
                            where Id = :partnerInfo.opportunityPartner.Id ];
                        xpartnerInfoList.add(i,new Opportunity_PartnerInfo(this,opportunityPartner));
                        i++;
                    }
                    catch (Exception e)
                    {
                        addExceptionMessage(e);
                    }
                }
                xpartnerInfoList.remove(i);
                break;
            }
        }
    }

    public PageReference cancel()
    {
        setPartnerInfoList(null);
        addMessage(ApexPages.Severity.INFO, 'All changes were canceled.');
        return null;
    }

    public PageReference insertOpportunityPartner()
    {
        Opportunity_PartnerInfo partnerInfo = new Opportunity_PartnerInfo(this);
        if(isGlobalRecordType) {
            partnerInfo.showAllRegions = true;
            partnerInfo.updateShowAllRegions();
        }
        List<Opportunity_PartnerInfo> xpartnerInfoList = getPartnerInfoList();
        xpartnerInfoList.add(null);
        xpartnerInfoList.add(0,partnerInfo);
        xpartnerInfoList.remove(xpartnerInfoList.size()-1);
        return null;
    }

    public PageReference editSelected()
    {
        for(Opportunity_PartnerInfo partnerInfo : getPartnerInfoList())
        {
            if(partnerInfo.isSelected)
            {
                partnerInfo.isEdit = true;
                if(isGlobalRecordType) {
                    partnerInfo.showAllRegions = true;
                    partnerInfo.updateShowAllRegions();
                }        
            }
        }
        return null;
    }

    public Boolean isEdit {
        get {
            Boolean retval = false;
            for(Opportunity_PartnerInfo partnerInfo : getPartnerInfoList())
            {
                if(partnerInfo.isEdit)
                {
                    retval = true;
                    break;
                }
            }
            return retval;
        }
    }

    public String partnerTierMapJS {
        get {
            if(partnerTierMapJS == null) {
                Set<String> results = new Set<String>();
                for(Classification__c c : getCompletePartnerTierList()) {
                    String [] hierarchy = c.Hierarchy__c.split(' » ',2);
                    if(hierarchy.size() > 1) {
                        results.add('"'+c.Id+'": {"parentId": "'+c.Parent__c+'", "hierarchy": ["'+hierarchy[1].replaceAll(' » ','","')+'"] },\n');
                    }
                }
                partnerTierMapJS='<script type="text/javascript">\nvar partnerTierMap={\n';
                for(String r : results) {
                    partnerTierMapJS += r;
                }
                partnerTierMapJS += '};\n</script>';
            }
            return partnerTierMapJS;
        }
        set;
    }

    public String partnerTypeMapByRelationshipTypeJS {
        get {
            if(partnerTypeMapByRelationshipTypeJS == null) {
                final String channel = getOpportunity().FulfillmentChannel__c;
                partnerTypeMapByRelationshipTypeJS='<script type="text/javascript">\nvar partnerTypeMapByRelationshipType={\n';
                for(Schema.Picklistentry entry : relationshipTypePicklistentryList) {
                    final String relationshipType = entry.getValue();
                    final Pattern pat = getPartnerTypePattern(channel,relationshipType);
                    final Set<String> results = new Set<String>();
                    for(Classification__c c : getCompletePartnerTypeList()) {
                        String [] hierarchy = c.Hierarchy__c.split(' » ',2);
                        if(hierarchy.size() > 1) {
                            if(pat == null || pat.matcher(c.Hierarchy__c).matches()) {
                                results.add('"'+c.Id+'": {"parentId": "'+c.Parent__c+'", "hierarchy": ["'+hierarchy[1].replaceAll(' » ','","')+'"] },\n');
                            }
                        }
                    }
                    if(! results.isEmpty()) {
                        partnerTypeMapByRelationshipTypeJS += '"'+relationshipType+'": {\n';
                        for(String r : results) {
                            partnerTypeMapByRelationshipTypeJS += r;
                        }
                        partnerTypeMapByRelationshipTypeJS += '},\n';
                    }
                }
                partnerTypeMapByRelationshipTypeJS += '};\n</script>';
            }
            return partnerTypeMapByRelationshipTypeJS;
        }
        set;
    }

    public String partnerStatusArrayJS {
        get {
            if(partnerStatusArrayJS == null && ! getNeedsFillPartnerStatusMaps()) {
                final Map<String,Set<Id>> xaccountRecordTypeIdByRegion = getAccountRecordTypeIdByRegion();
                final Map<Id,Map<String,Map<Id,PartnerStatus__c>>> m = getPartnerStatusRecordTypeIdTypeHierarchyMap();
                Set<String> results = new Set<String>();
                String recordTypeName = getOpportunity().RecordType.Name;
                for(String regionName : xaccountRecordTypeIdByRegion.keySet()) {
                    Boolean inRegion = (recordTypeName == regionName || recordTypeName.startsWith(regionName+' ') || recordTypeName.contains(' '+regionName+' ') || recordTypeName.endsWith(' '+regionName));
                    for(Id recordTypeId : xaccountRecordTypeIdByRegion.get(regionName)) {
                        Map<String,Map<Id,PartnerStatus__c>> m2 = m.get(recordTypeId);
                        if(m2 != null) {
                            for(String partnerTypeHierarchy : m2.keySet()) {
                                for(PartnerStatus__c ps : m2.get(partnerTypeHierarchy).values()) {
                                    results.add(
                                        '{ inRegion:'+ inRegion 
                                        + ', tier:"'+ps.PartnerTier__c
                                        + '", type:"'+ps.PartnerType__c+'"},\n');
                                }
                            }
                        }
                    }
                    partnerStatusArrayJS='<script type="text/javascript">\nvar partnerStatusArray=[\n';
                    for(String r : results) {
                        partnerStatusArrayJS += r;
                    }
                    partnerStatusArrayJS += '];\n</script>';
                }
            }
            return partnerStatusArrayJS;
        }
        set;
    }

    public PageReference removeSelected()
    {
        try {
            List<OpportunityPartner__c> opportunityPartnerList = new List<OpportunityPartner__c>();
            for(Opportunity_PartnerInfo partnerInfo : getPartnerInfoList()) {
                if(partnerInfo.isSelected) {
                    if(partnerInfo.opportunityPartner.RelationshipType__c == FINANCIAL && FINANCIAL_PARTNER_CHANNELS.contains(opportunity.FulfillmentChannel__c)) {
                        addExceptionMessage(Schema.SObjectType.Opportunity.Fields.FinancialPartnerName__c.getLabel()+' is required.');
                    }
                    else {
                        opportunityPartnerList.add(partnerInfo.opportunityPartner);
                    }
                }
            }
            setPartnerInfoList(null);
            if(! opportunityPartnerList.isEmpty()) {
                delete opportunityPartnerList;
            }
        }
        catch (System.DmlException dmlException) {
            addExceptionMessage(dmlException);
        }
        return null;
    }

    public PageReference saveOpportunityPartnerList()
    {
        List<Opportunity_PartnerInfo> xpartnerInfoList = getPartnerInfoList();
        if (xpartnerInfoList.isEmpty()) {
            addExceptionMessage('Internal Error: the opportunityPartner list is empty.');
        }
        else {
            try {
                Opportunity_ManagePartners_AsUser asUser = new Opportunity_ManagePartners_AsUser();
                if (asUser.checkPermissions(this.opportunity)) {
                    List<OpportunityPartner__c> opportunityPartnerList = new List<OpportunityPartner__c>();
                    for(Opportunity_PartnerInfo partnerInfo : xpartnerInfoList) {
                        OpportunityPartner__c opportunityPartner = partnerInfo.opportunityPartner;
                        PartnerStatus__c partnerStatus = partnerInfo.getPartnerStatus();
                        if(partnerStatus != null) {
                            opportunityPartner.PartnerTier__c = partnerStatus.PartnerTier__c;
                            opportunityPartner.PartnerType__c = partnerStatus.PartnerType__c;
                        }
                        if(partnerInfo.isEdit) {
                            opportunityPartnerList.add(opportunityPartner);
                        }
                    }
                    upsert opportunityPartnerList;
                    setPartnerInfoList(null);
                    addConfirmationMessage();
                }
                else {
                    throw new AddOpportunityPartnerException('Insufficient priviledges to add Partners to this Opportunity.');
                }
            }
            catch (System.DmlException dmlException) {   
                addExceptionMessage(dmlException);
            }
        }
        return null;
    }

    public PageReference saveOpportunityPartnerListAndInsert()
    {
        saveOpportunityPartnerList();
        return hasMessages(ApexPages.Severity.ERROR)?null:insertOpportunityPartner();
    }

    public PageReference saveOpportunityPartnerListAndReturn()
    {
        saveOpportunityPartnerList();
        return hasMessages(ApexPages.Severity.ERROR)?null:(new PageReference('/' + opportunity.Id));
    }

    public class AddOpportunityPartnerException extends Exception {}
}