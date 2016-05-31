/**
 * In the future this class should replace all "after" triggers on the Opportunity object.  
 * The processTrigger method is invoked by the Opportunity_After trigger and in turn invokes
 * all the methods of this class.  This gives us a way to control the order in
 * which the code logic is invoked, as well as allowing other class features such
 * as shared data, constant values, and rigorous test coverage.
 * <p>
 * The Trigger object should never be directly referenced inside this class, as
 * that would make it impossible to substitute values inside test methods.
 * </p>
 * NOTE: Some existing triggers have not yet been incorporated into this class (future work).
 *
 * @version 2016-01-05
 * @author Scott Coleman <scoleman@redhat.com>
 * 2015-06-04 - Protect against invoking future method for POC updates while in batch
 * 2015-04-21 - Added method that deletes Financial Partner from PRL for certain changes to Channel (US65011)
 * 2013-12-05 - Bug fix for DE5610 when changing POC owner
 * 2013-11-01 - Added method that chains POC BU approval to end of SA Management approval
 * 2013-10-17 - Added method that cascades certain opp updates to related POCs
 * 2013-10-01 - Added method to add Engagement SA to opp team
 * 2013-02-25 - Added copy of POC products
 * 2012-07-12 - Created
 * Bill Riemers <briemers@redhat.com>
 * 2016-01-05 - Revert createEventRecords method, add createEventRecords2 method
 * 2015-11-26 - Added undelete and delete processing for adding event__c records
 * 2015-11-23 - Modified createEventRecords query to reduce the number of rows scanned.
 * 2015-08-07 - Added countryOppSplitAU and createEventRecords methods.
 * 2015-08-06 - Change to allow services allocations as a future call.  Added countryOppSplitAU and createEventRecords methods.
 * 2015-05-11 - Refactored to add backout and submit to order management methods
 * 2014-04-09 - change zero dollar order to zero value opportunity
 * 2013-03-05 - exclude zero dollar orders from syncProofOfConceptFields 
 * 2014-02-27 - Added method for creating a shipping contact role
 * 2014-02-18 - Added method to create lead history records
 * 2014-01-17 - Added method to sync contracts.
 * 2013-12-10 - Remove current user from POC owner change nofication email recipient list
 * 2013-12-10 - Add information about new owner and user who changed the owner the change into the change owner notification e-mail
 * 2013-11-25 - Synchronize stage name to POC's
 * 2013-11-19 - Added syncronization of Opportunity Team Member clones, and revised methods to avoid recursion
 * 2013-11-08 - Added method to notify when the owner of a POC is changed
 * 2013-08-16 - Implement updateServicesAllocations to maintain the new child records
 * 2013-08-08 - Renamed to OpportunityTriggerAfter2 to avoid release conflicts
 * 2013-05-14 - Added lookup for POC record type
 * 2013-04-04 - Added link solution method.  Correct usage of AbstractTrigger and such.
 */
public without sharing class OpportunityTriggerAfter2 extends AbstractTrigger {
    /** String used for locking. */
    public static final String LOCK_STRING = 'OpportunityTriggerAfter.Lock';
    /** BooleanSetting__c key to enable backout order method. */
    public static final String BACKOUT_ORDER_SETTING = 'Opp_After.backoutOrder';
    /** BooleanSetting__c key to enable the countryOppSplitAU method. */
    public static final String COUNTRY_OPP_SPLIT_AU_SETTING = 'Opp_After.CountryOppSPlitAU';
    /** BooleanSetting__c key to enable the createEventRecords method. */
    public static final String CREATE_EVENT_RECORDS_SETTING = 'Opp_After.CreateEventRecords';
    /** BooleanSetting__c key to enable the leadHistory trigger method. */
    public static final String LEAD_HISTORY_SETTING = 'Opp_After.leadHistory';
    /** BooleanSetting__c key to enable setting legacy values */
    public static final String INSERT_OPPORTUNITY_SNAPSHOT_SETTING = 'Opp_After.insertOppSnapshot';
    /** BooleanSetting__c key to enable the insertOpportunitySnapshot trigger method. */
    public static final String COPY_POC_PRODUCTS_SETTING = 'Opp_After.copyPOCProducts';
    /** BooleanSetting__c key to enable the linkSolution trigger method. */
    public static final String LINK_SOLUTIONS_SETTING = 'Opp_After.linkSolutions';
    /** BooleanSetting__c key to enable the updateServiesAllocations trigger method. */
    public static final String UPDATE_SERVICES_ALLOCATIONS_SETTING = 'Opp_After.updateServicesAlloc';
    /** BooleanSetting__c key to enable require engagement SA. */
    public static final String REQUIRE_ENGAGEMENT_SA_SETTING = 'Opp_After.requireEngagementSA';
    /** BooleanSetting__c key to enable setting of engagement SA. */
    public static final String NEXT_STEP_HISTORY_SETTING = 'Opp_After.nextStepHistory';
    /** BooleanSetting__c key to enable data migration. */
    public static final String SERVICES_ALLOCATIONS_MIGRATE_DATA_SETTING = 'ServiceAlloc.MigrateData';
    /** BooleanSetting__c key to enable setting of engagement SA. */
    public static final String SET_ENGAGEMENT_SA_SETTING = 'Opp_After.setEngagementSA';
    /** BooleanSetting__c key to enable submit to order management method. */
    public static final String SUBMIT_TO_ORDER_MANAGEMENT_SETTING = 'Opp_After.submitToOM';
    /** BooleanSetting__c key to enable sync Opportunity Team Member Clone method. */
    public static final String SYNC_OPPORTUNITY_TEAM_MEMBER_CLONE_SETTING = 'Opp_After.syncOTMClone';
    /** BooleanSetting__c key to enable sync of POC field values. */
    public static final String SYNC_POC_FIELDS_SETTING = 'Opp_After.syncPOCFields';
    /** BooleanSetting__c key to enable sync of Contract field values. */
    public static final String SYNC_CONTRACTS_SETTING = 'Opp_After.syncContracts';
    /** BooleanSetting__c key to enable the syncShippingContacts trigger method. */
    public static final String SYNC_SHIPPING_CONTACTS_SETTING = 'Opp_After.syncShipToContact';
    /** BooleanSetting__c key to enable submission of a POC for BU approval. */
    public static final String SUBMIT_FOR_BU_APPROVAL_SETTING = 'Opp_After.submitForBUApproval';
    /** BooleanSetting__c key to enable notify on owner change. */
    public static final String NOTIFY_OWNER_CHANGE_SETTING = 'Opp_After.notifyOwnerChange';
    /** BooleanSetting__c key to enable notify on owner change. */
    public static final String REMOVE_FINANCIAL_PARTNER_SETTING = 'Opp_After.removeFinancialPartner';

    /** Lead Stage to indicate sales accepted. */
    public static final String SALES_ACCEPTED = 'Sales Accepted';
    /** Lead Stage to indicate sales qualified. */
    public static final String SALES_QUALIFIED = 'Sales Qualified';
    /** Lead Stage to indicate won. */
    public static final String LEAD_WON = 'Won';
    /** Lead Stage to indicate lost */
    public static final String LEAD_LOST = 'Lost';
    /** Order Status for orders submitted for OM Review */
    public static final String SUBMITTED_FOR_OM_REVIEW_PLV = 'Submitted for OM Review';
    /** Order Status for orders cancelled */
    public static final String CANCELLED_PLV = 'CANCELLED';
    public static final String NOT_STARTED_PLV = 'Not Started';
    public static final String SYSTEM_DEFERRED_PLV = 'System Deferred';
    public static final String REVERTED_PLV = 'Reverted';

    /** Set to false to do services allocations as a future call. */
    public static Boolean updateServicesAllocationsNow = true;

    /** Normally populated as a copy of Trigger.oldMap */
    public final Map<Id,Opportunity> oldMap = new Map<Id,Opportunity>();
    /** Normally populated as Trigger.new */
    public final Map<Id,Opportunity> newMap = new Map<Id,Opportunity>();
    /** Used to keep track of errors while debugging */
    public Boolean hasErrors = false;
    /** Used to keep track of undeletes */
    private final  Boolean isUndelete;
    /** Used to by-pass the requireEngagementSA test when synchronizing Opportunity Team Member. */
    private Set<Id> checkRequireEngagementSAByPass = new Set<Id>();

    /**
     * This constructor is normally called from the processTrigger method and
     * test methods.
     */
    public OpportunityTriggerAfter2(
        Map<Id,Opportunity> xoldMap,
        Map<Id,Opportunity> xnewMap,
        Boolean isUndelete )
    {
        super(xoldMap,null,xnewMap);
        if(xoldMap != null) {
            oldMap.putAll(xoldMap);
        }
        if(xnewMap != null) {
            newMap.putAll(xnewMap);
        }
        this.isUndelete = isUndelete;
    }

    /** This is to allow us to pass in query values from other triggers. */
    public static Map<Id,Opportunity> staticProofOfConceptMap = null;

    /**
     * Query the selected list of opportunity ids.  The results are limited to
     * just POC's.
     */
    public static Map<Id,Opportunity> queryProofOfConcepts(Set<Id> oppIds) {
        return new Map<Id,Opportunity>([
            select
                RecordTypeId,
                Engagement_SA__c,
                POC_Status__c,
                (select 
                    CreatedDate,
                    OpportunityId,
                    TeamMemberRole,
                    UserId
                    from OpportunityTeamMembers ),
                (select 
                    CreatedDate,
                    Opportunity__c,
                    OpportunityTeamMemberId__c,
                    TeamMemberRole__c,
                    User__r.IsActive,
                    User__r.Email,
                    User__r.EnterpriseServerUrl__c,
                    User__r.Name
                    from OpportunityTeamMemberClones__r )
            from Opportunity
            where Id in :oppIds 
                and RecordTypeId = :pocRecordTypeId ]);
    }

    private void addError(Map<Id,Opportunity> oppMap,Id oppId, String message) {
        addErrorStatic(this,oppMap,oppId,message);
    }

    private static void addErrorStatic(OpportunityTriggerAfter2 afterTrigger,Map<Id,Opportunity> oppMap,Id oppId, String message) {
        if(oppMap != null) {
            Opportunity opp = oppMap.remove(oppId);
            if(opp != null) {
                opp.addError(message);
            }
        }
        if(afterTrigger != null) {
            afterTrigger.hasErrors = true;
        }
    }

    /**
     * This is a map of opportunities, currently restricte to POC's.
     */
    public Map<Id,Opportunity> proofOfConceptMap {
        get {
            if(proofOfConceptMap == null) {
                proofOfConceptMap = new Map<Id,Opportunity>();
                Map<Id,Opportunity> currentMap = newMap;
                if(isDelete) {
                    currentMap = oldMap;
                }
                Set<Id> oppIds = new Set<Id>{};
                for(Opportunity opp : currentMap.values() ) {
                    if(opp.RecordTypeId == pocRecordTypeId) {
                        oppIds.add(opp.Id);
                    }
                }
                if(staticProofOfConceptMap != null) {
                    proofOfConceptMap.putAll(staticProofOfConceptMap);
                    proofOfConceptMap.keySet().retainAll(oppIds);
                    oppIds.removeAll(proofOfConceptMap.keySet());
                }
                if(! oppIds.isEmpty()) {
                    proofOfConceptMap.putAll( queryProofOfConcepts( oppIds ) );
                }
            }
            return proofOfConceptMap;
        }
        set;
    }

    private boolean haveSnapshotFieldsChanged(Opportunity opp) {
        Opportunity oldOpp = oldMap.get(opp.Id);
        boolean retVal = false;
        //for new opps, check if any in-scope fields have a value
        if (oldOpp == null) {
            if (opp.Rush_Order__c 
                    || opp.Rush_Order_Reason__c != null 
                    || opp.Rush_Order_Set_By_System__c) {
                retVal = true;
            }
        }
        //for updated opps, check if any in-scope fields have changed 
        else if (opp.Rush_Order__c != oldOpp.Rush_Order__c
                || opp.Rush_Order_Reason__c != oldOpp.Rush_Order_Reason__c
                || opp.Rush_Order_Set_By_System__c != oldOpp.Rush_Order_Set_By_System__c) {
            retVal = true;
        }
        return retVal;
    }

    private OpportunitySnapshot__c createSnapshotRecord(Opportunity opp) {
        Opportunity oldOpp = oldMap.get(opp.Id);
        OpportunitySnapshot__c snapshot;
        if (oldOpp == null) {
            snapshot = new OpportunitySnapshot__c(
                Opportunity__c=opp.Id,
                RushOrderFrom__c=false,
                RushOrderTo__c=opp.Rush_Order__c,
                RushOrderReasonFrom__c=null,
                RushOrderReasonTo__c=opp.Rush_Order_Reason__c,
                RushOrderSetBySystemFrom__c=false,
                RushOrderSetBySystemTo__c=opp.Rush_Order_Set_By_System__c);
        }
        else {
            snapshot = new OpportunitySnapshot__c(
                Opportunity__c=opp.Id,
                RushOrderFrom__c=oldOpp.Rush_Order__c,
                RushOrderTo__c=opp.Rush_Order__c,
                RushOrderReasonFrom__c=oldOpp.Rush_Order_Reason__c,
                RushOrderReasonTo__c=opp.Rush_Order_Reason__c,
                RushOrderSetBySystemFrom__c=oldOpp.Rush_Order_Set_By_System__c,
                RushOrderSetBySystemTo__c=opp.Rush_Order_Set_By_System__c);
        }
        return snapshot;
    }

    /**
     * Called to create and delete OpportunityContactRole values based on the ShippingContact__c field.
     */
    public void syncShippingContacts() {
        Set<Id> oppIds = new Set<Id>();
        Set<Id> contactIds = new Set<Id>();
        for(Opportunity opp : newMap.values()) {
            Opportunity oldOpp = oldMap.get(opp.Id);
            if(oldOpp != null && oldOpp.ShippingContact__c != null && opp.ShippingContact__c != oldOpp.ShippingContact__c)
            {
                oppIds.add(opp.Id);
                contactIds.add(oldOpp.ShippingContact__c);
            }
            if(opp.ShippingContact__c != null
                && (OpportunityTriggerBefore2.opportunitiesAutoAssignedShippingContact == null
                    || ! OpportunityTriggerBefore2.opportunitiesAutoAssignedShippingContact.contains(opp.Id)) )
            {
                oppIds.add(opp.Id);
                contactIds.add(opp.ShippingContact__c);
            }
        }
        if(! oppIds.isEmpty()) {
            List<OpportunityContactRole> deleteList = new List<OpportunityContactRole>();
            for(OpportunityContactRole contactRole : [
                select 
                    ContactId,
                    OpportunityId
                from OpportunityContactRole
                where Role = 'Shipping Contact'
                    and ContactId in :contactIds
                    and OpportunityId in :oppIds ] )
            {
                Id shippingContactId = newMap.get(contactRole.OpportunityId).ShippingContact__c;
                if(contactRole.ContactId == shippingContactId) {
                    oppIds.remove(contactRole.OpportunityId);
                }
                else {
                    Opportunity oldOpp = oldMap.get(contactRole.OpportunityId);
                    if(oldOpp != null && contactRole.ContactId == oldOpp.ShippingContact__c) {
                        deleteList.add(contactRole);
                        oppIds.remove(contactRole.OpportunityId);
                    }
                }
            }
            if(! deleteList.isEmpty()) {
                Database.delete(deleteList,false);
            }
            if(! oppIds.isEmpty()) {
                List<OpportunityContactRole> contactRoles = new List<OpportunityContactRole>();
                for(Id oppId : oppIds) {
                    Id contactId = newMap.get(oppId).ShippingContact__c;
                    if(contactId != null) {
                        contactRoles.add(
                            new OpportunityContactRole(
                                ContactId = newMap.get(oppId).ShippingContact__c,
                                OpportunityId = oppId,
                                Role = 'Shipping Contact'));
                    }
                }
                Database.insert(contactRoles,false);
            }
        }
    }

    /**
     * Method to insert a snapshot.
     */
    public void insertOpportunitySnapshot() {
        for(Opportunity opp : newMap.values()) {
            if (haveSnapshotFieldsChanged(opp) && !OpportunitySnapshotHelper.hasAlreadyCreatedSnapshot()) {
                OpportunitySnapshot__c snapshot = createSnapshotRecord(opp);
                OpportunitySnapshotHelper.setAlreadyCreatedSnapshot();
                insert snapshot;
            }
        }
    }

    /** Lookup the POC record id. */
    // to do: Once this is the same on all environments this can be changed to constant value
    public static Id pocRecordTypeId {
        get {
            return RecordTypeLookup.getRecordTypeId('Proof of Concept','Opportunity');
        }
    }

    public static Id zeroValueOpportunityRecordTypeId {
        get {
            return RecordTypeLookup.getRecordTypeId('Zero Value Opportunity','Opportunity');
        }
    }

    /**
     * Lookup the global pricebook id.
     */
    public static String globalPricebookId {
        get {
            if (globalPricebookId == null) {
                for(Pricebook2 globalPriceBook : [
                    SELECT Id 
                    FROM Pricebook2 
                    WHERE Name = 'Global Price Book' limit 1] )

                {
                    globalPriceBookId = globalPriceBook.Id;
                }
            }
            return globalPricebookId;
        }
        set;
    }

    // batch fetch all the line items from any opportunities used to create POC opportunities
    private Map<Id,List<OpportunityLineItem>> sourceOppLineItems {
        get {
            if(sourceOppLineItems == null) {
                Set<Id> sourceOppIds = new Set<Id>();
                for(Opportunity opp : newMap.values()) {
                    if(opp.RecordTypeId == pocRecordTypeId && opp.Cloned_From_Opportunity__c != null) {
                        sourceOppIds.add(opp.Cloned_From_Opportunity__c);
                    }
                }
                if(sourceOppIds.size() > 0) {
                    List<OpportunityLineItem> lineItems = [
                        SELECT ActualEndDate__c,
                            ActualStartDate__c,
                            ActualTerm__c,
                            Base_Price__c,
                            Configured_SKU__c,
                            Contract_Numbers__c,
                            CurrencyIsoCode,
                            Description,
                            Extended_Sales_Price__c,
                            HasQuantitySchedule,
                            HasRevenueSchedule,
                            HasSchedule,
                            Line_Item_Source__c,
                            ListPrice,
                            NewOrRenewal__c,
                            OpportunityCloseDate__c,
                            OpportunityId,
                            PricebookEntryId,
                            Pricing_Attributes__c,
                            ProductDefaultTerm__c,
                            Quantity,
                            RenewalProduct__c,
                            ScheduleLocked__c,
                            ServiceDate,
                            SortOrder,
                            Suggested_List_Price__c,
                            TotalPrice,
                            UnitPrice,
                            Year1Amount__c,
                            Year2Amount__c,
                            Year3Amount__c,
                            Year4Amount__c,
                            Year5Amount__c,
                            Year6Amount__c,
                            YearlySalesPrice__c
                        FROM OpportunityLineItem
                        WHERE OpportunityId IN :sourceOppIds];
                    sourceOppLineItems = new Map<Id,List<OpportunityLineItem>>();
                    for(OpportunityLineItem lineItem : lineItems) {
                        if(sourceOppLineItems.containsKey(lineItem.OpportunityId)) {
                            sourceOppLineItems.get(lineItem.OpportunityId).add(lineItem);
                        }
                        else {
                            sourceOppLineItems.put(lineItem.OpportunityId, new List<OpportunityLineItem>{lineItem});
                        }
                    }
                }
            }
            return sourceOppLineItems;
        }
        private set;
    }

    private Map<Id,String> sourceOppCurrencies {
        get {
            if(sourceOppCurrencies == null) {
                sourceOppCurrencies = new Map<Id,String>();
                Set<Id> sourceOppIds = new Set<Id>();
                for(Opportunity opp : newMap.values()) {
                    if(opp.RecordTypeId == pocRecordTypeId && opp.Cloned_From_Opportunity__c != null) {
                        sourceOppIds.add(opp.Cloned_From_Opportunity__c);
                    }
                }
                if(sourceOppIds.size() > 0) {
                    List<Opportunity> opps = [SELECT Id, CurrencyISOCode 
                                                FROM Opportunity 
                                                WHERE Id IN :sourceOppIds];
                    for(Opportunity opp : opps) {
                        sourceOppCurrencies.put(opp.Id, opp.CurrencyISOCode);
                    }
                }
            }
            return sourceOppCurrencies;
        }
        private set;
    }

    /** 
     * For each new proof of concept opp that was created from another opp,
     * copy the products from the source opp.
     */
    public void copyProofOfConceptProducts() {
        if(isInsert) {
            List<OpportunityLineItem> targetOppLineItems = new List<OpportunityLineItem>();
            for(Opportunity opp : newMap.values()) {
                if(opp.RecordTypeId == pocRecordTypeId && opp.Cloned_From_Opportunity__c != null) {
                    List<OpportunityLineItem> sourceLineItems = sourceOppLineItems.get(opp.Cloned_From_Opportunity__c);
                    if(sourceLineItems != null && opp.CurrencyIsoCode == sourceOppCurrencies.get(opp.Cloned_From_Opportunity__c)) {
                        List<OpportunityLineItem> targetLineItems = sourceLineItems.deepClone(false);
                        for(OpportunityLineItem lineItem : targetLineItems) {
                            lineItem.OpportunityId = opp.Id;
                            lineItem.TotalPrice = null;
                        }
                        if(opp.Pricebook2Id != null) {
                            targetOppLineItems.addAll(targetLineItems);
                        }
                    }
                }
            }
            if(! targetOppLineItems.isEmpty()) {
                for(Database.Saveresult sr : Database.insert(targetOppLineItems,false)) {
                    OpportunityLineItem lineItem = targetOppLineItems.remove(0);
                    if(! sr.isSuccess()) {
                        addError(newMap,lineItem.OpportunityId,'Failed to add line item: '+sr.getErrors());
                    }
                }
            }
        }
    }

    /**
     * Map of OpportunityTeamMembers for poc's.
     */
    public Map<Id,OpportunityTeamMember> pocTeamMemberMap {
        get {
            if(pocTeamMemberMap == null) {
                pocTeamMemberMap = new Map<Id,OpportunityTeamMember>();
                for(Opportunity poc : proofOfConceptMap.values()) {
                    if(poc.OpportunityTeamMembers != null) {
                        pocTeamMemberMap.putAll(new Map<Id,OpportunityTeamMember>(poc.OpportunityTeamMembers));
                    }
                }
            }
            return pocTeamMemberMap;
        }
        set;
    }

    /**
     * Map of OpportunityTeamMemberClone__c records for poc's using
     * the OpportunityTeamMember Id as the key.
     */
    public Map<Id,OpportunityTeamMemberClone__c> pocTeamMemberCloneMap {
        get {
            if(pocTeamMemberCloneMap == null) {
                pocTeamMemberCloneMap = new Map<Id,OpportunityTeamMemberClone__c>();
                for(Opportunity poc : proofOfConceptMap.values()) {
                    if(poc.OpportunityTeamMemberClones__r != null) {
                        for(OpportunityTeamMemberClone__c teamMemberClone : poc.OpportunityTeamMemberClones__r ) {
                            Id teamMemberId = teamMemberClone.OpportunityTeamMemberId__c;
                            pocTeamMemberCloneMap.put(teamMemberId,teamMemberClone);
                        }
                    }
                }
            }
            return pocTeamMemberCloneMap;
        }
        set;
    }

    /** 
     * Called to synchronize OpportunityTeamMember with OpportunityTeamMemberClone.
     */
    public void syncOpportunityTeamMemberClone() {
        if(isUpdate && ! proofOfConceptMap.isEmpty()) {
            // first delete any clone without a team member
            Map<Id,OpportunityTeamMemberClone__c> pocTeamMemberCloneMap2 = pocTeamMemberCloneMap.clone();
            pocTeamMemberCloneMap2.keySet().removeAll(pocTeamMemberMap.keySet());
            if(! pocTeamMemberCloneMap2.isEmpty()) {
                pocTeamMemberCloneMap.keySet().removeAll(pocTeamMemberCloneMap2.keySet());
                List<OpportunityTeamMemberClone__c> deleteList = pocTeamMemberCloneMap2.values().clone();
                try {
                    OpportunityTeamMemberCloneTriggerAfter.staticOpportunityMap = proofOfConceptMap;
                    for(Database.DeleteResult r : Database.delete(deleteList,false)) {
                        OpportunityTeamMemberClone__c teamMemberClone = deleteList.remove(0);
                        checkRequireEngagementSAByPass.add(teamMemberClone.Opportunity__c);
                        if(! r.isSuccess()) {
                            addError(newMap,teamMemberClone.Opportunity__c,'Failed to delete opportunity team member clone: '+r.getErrors());
                        }
                    }
                }
                finally {
                    OpportunityTeamMemberCloneTriggerAfter.staticOpportunityMap = null;
                }
            }
            // now update any team member without a clone
            Map<Id,OpportunityTeamMember> pocTeamMemberMap2 = pocTeamMemberMap.clone();
            pocTeamMemberMap2.keySet().removeAll(pocTeamMemberCloneMap.keySet());
            if(! pocTeamMemberMap2.isEmpty()) {
                List<OpportunityTeamMember> updateList = pocTeamMemberMap2.values().clone();
                try {
                    OpportunityTeamMemberCloneTriggerAfter.staticOpportunityMap = proofOfConceptMap;
                    for(Database.SaveResult r : Database.update(updateList,false)) {
                        OpportunityTeamMember teamMember = updateList.remove(0);
                        checkRequireEngagementSAByPass.add(teamMember.OpportunityId);
                        if(! r.isSuccess()) {
                            addError(newMap,teamMember.OpportunityId,'Failed to update opportunity team member: '+r.getErrors());
                        }
                    }
                }
                finally {
                    OpportunityTeamMemberCloneTriggerAfter.staticOpportunityMap = null;
                }
            }
        }
    }

    //Prevents creating duplicate record in Opportunity History for 'Next Step'
    public static Boolean IsNextStepHistoryTriggered = true;  
    
    //Creates records whenever 'Next Step' field on opportunity is updated
    public void nextStepHistory() {
        if(OpportunityTriggerAfter2.IsNextStepHistoryTriggered) {
        List<Opportunity_History__c> oppHistoryList = new List<Opportunity_History__c>();       
        for(Opportunity opp : newMap.values()) {
             Opportunity oldOpp = oldMap.get(opp.Id);
             if (((isUpdate && opp.Next_Step__c != oldOpp.Next_Step__c)) || (isInsert && opp.Next_Step__c!=null)) {
                 Opportunity_History__c oppH = new Opportunity_History__c();
                 oppH.Next_Step__c = opp.Next_Step__c;
                 //oppH.Created_Date__c = opp.LastModifiedDate;
                 //oppH.Created_By__c = userInfo.getUserId();
                 //oppH.Opportunity_Stage__c = opp.StageName;
                 //oppH.Opportunity_Value__c = opp.Amount;
                 oppH.Name = opp.Name.substring(0,80);
                 //oppH.Opportunity__c = opp.Id;
                 oppHistoryList.add(oppH);
             }
        }
        if(!oppHistoryList.isEmpty()) insert oppHistoryList;
        OpportunityTriggerAfter2.IsNextStepHistoryTriggered=false;
       }
    }

    /**
     * Adds the engagement SA to the opportunity team.
     */
    public void setEngagementSA() {
        Map<Id, Id> addEngagementSAs = new Map<Id, Id>();
        Map<Id, Id> removeEngagementSAs = new Map<Id, Id>();
        for(Opportunity opp : newMap.values()) {
            if(opp.RecordTypeId == pocRecordTypeId) {
                Opportunity oldOpp = oldMap.get(opp.Id);
                if((isInsert || (isUpdate && opp.Engagement_SA__c != oldOpp.Engagement_SA__c)) && opp.Engagement_SA__c != null) {
                    addEngagementSAs.put(opp.Id, opp.Engagement_SA__c);
                }
                if ((isUpdate && opp.Engagement_SA__c != oldOpp.Engagement_SA__c) && oldOpp.Engagement_SA__c != null) {
                    removeEngagementSAs.put(opp.Id, oldOpp.Engagement_SA__c);
                }
            }
        }
        if(!addEngagementSAs.isEmpty() || !removeEngagementSAs.isEmpty()) {
            Boolean triggerValue = booleanSettingMap.get(SET_ENGAGEMENT_SA_SETTING);
            Boolean triggerValue2 = booleanSettingMap.get(OpportunityTeamMemberCloneTriggerAfter.SET_ENGAGEMENT_SA_SETTING);
            try {
                // turn off set engagement sa setting trigger to avoid recursion
                booleanSettingMap.put(SET_ENGAGEMENT_SA_SETTING,false);
                booleanSettingMap.put(OpportunityTeamMemberCloneTriggerAfter.SET_ENGAGEMENT_SA_SETTING,false);
                if(!addEngagementSAs.isEmpty()) {
                    List<OpportunityTeamMember> upsertTeamMembers = new List<OpportunityTeamMember>();
                    List<OpportunityShare> upsertOpportunityShares = new List<OpportunityShare>();
                    //add new Engagement SAs
                    for(Id oppId : addEngagementSAs.keySet()) {
                        upsertTeamMembers.add(new OpportunityTeamMember(
                            OpportunityId = oppId,
                            TeamMemberRole = 'Engagement SA',
                            UserId = addEngagementSAs.get(oppId)));
                        //need to add a new OpportunityShare record if the Engagement SA is not the POC owner
                        if(newMap.get(oppId).OwnerId != addEngagementSAs.get(oppId)) {
                            upsertOpportunityShares.add(new OpportunityShare(
                                OpportunityId = oppId,
                                UserOrGroupId = addEngagementSAs.get(oppId),
                                OpportunityAccessLevel = 'Edit'));
                        }
                    }
                    if(!upsertTeamMembers.isEmpty()) {
                        for(Database.UpsertResult r : Database.upsert(upsertTeamMembers,false)) {
                            OpportunityTeamMember teamMember = upsertTeamMembers.remove(0);
                            if(! r.isSuccess()) {
                                addError(newMap,teamMember.OpportunityId,'Failed to update teamMember: '+r.getErrors());
                            }
                        }
                        if(!upsertOpportunityShares.isEmpty()) {
                            for(Database.UpsertResult r : Database.upsert(upsertOpportunityShares,false)) {
                                OpportunityShare oppShare = upsertOpportunityShares.remove(0);
                                if(! r.isSuccess()) {
                                    addError(newMap,oppShare.OpportunityId,'Failed to update Opportunity share: '+r.getErrors());
                                }
                            }
                        }
                    }
                }
                if(!removeEngagementSAs.isEmpty()) {
                    List<OpportunityTeamMember> deleteTeamMembers = new List<OpportunityTeamMember>();
                    //List<OpportunityShare> deleteOpportunityShares = new List<OpportunityShare>();
                    List<OpportunityTeamMember> teamMembers = new List<OpportunityTeamMember>();
                    //check for existing team members that need to be deleted
                    for(OpportunityTeamMember teamMember : pocTeamMemberMap.values() ) {
                        if( teamMember.TeamMemberRole == 'Engagement SA'
                            && teamMember.UserId == removeEngagementSAs.get(teamMember.OpportunityId) )
                        {
                            deleteTeamMembers.add(teamMember);
                            removeEngagementSAs.remove(teamMember.OpportunityId);
                        }
                    }
                    if(!deleteTeamMembers.isEmpty()) {
                        for(Database.DeleteResult r : Database.delete(deleteTeamMembers,false)) {
                            OpportunityTeamMember teamMember = deleteTeamMembers.remove(0);
                            if(! r.isSuccess()) {
                                addError(newMap,teamMember.OpportunityId,'Failed to delete teamMember: '+r.getErrors());
                            }
                        }
                    }
                }
            }
            finally {
                // restore the trigger state
                booleanSettingMap.put(SET_ENGAGEMENT_SA_SETTING,triggerValue);
                booleanSettingMap.put(OpportunityTeamMemberCloneTriggerAfter.SET_ENGAGEMENT_SA_SETTING,triggerValue2);
            }
        }
    }

    public void requireEngagementSA() {
        if(isUpdate  && ! System.isFuture()) {
            for(Opportunity opp : newMap.values()) {
                if(opp.Engagement_SA__c == null 
                    && (! checkRequireEngagementSAByPass.contains(opp.Id)) 
                    && opp.RecordTypeId == pocRecordTypeId
                    && (opp.POC_Status__c == 'Scoping'
                        || opp.POC_Status__c == 'Submitted'
                        || opp.POC_Status__c == 'Accepted'
                        || opp.POC_Status__c == 'Closed' ) && opp.Super_Region__c == 'APAC' && opp.Cloned_From_Opportunity__r.Super_Region__c == 'APAC')
                {
                    addError(newMap,opp.Id,'This Proof of Concept is required to have an Engagement SA.');
                }
            }
        }
    }
    /**
     * Cascades certain opp updates to related Proof of Concept opps
     */
    public void syncProofOfConceptFields() {
        // If we have errors, this method will be 
        // called again to process the remaining records.
        // There is no need to use an extra future call...
        if(isUpdate && ! hasErrors && ! System.isFuture() ) {
            Set<Id> updatedOppIds = new Set<Id>();
            //figure out which opps (if any) had updates that should be
            // cascaded to related Proof of Concept opportunities
            for(Opportunity opp : newMap.values()) {
                Opportunity oldOpp = oldMap.get(opp.Id);
                if(opp.RecordTypeId != pocRecordTypeId
                    && opp.RecordTypeId != zeroValueOpportunityRecordTypeId
                    && (opp.AccountId != oldOpp.AccountId
                        || opp.Country_of_Order__c != oldOpp.Country_of_Order__c
                        || opp.StageName != oldOpp.StageName) )
                {
                    updatedOppIds.add(opp.Id);
                }
            }
            if(!updatedOppIds.isEmpty()) {
                //now get a list of opps that have child POCs that need to be updated
                Set<Id> oppIds = new Set<Id>();
                for( Opportunity poc : [
                    SELECT Cloned_From_Opportunity__c
                    FROM Opportunity
                    WHERE RecordTypeId = :pocRecordTypeId
                        AND Cloned_From_Opportunity__c IN :updatedOppIds] )
                {
                    oppIds.add(poc.Cloned_From_Opportunity__c);
                }
                if(!oppIds.isEmpty()) {
                    if(!System.isBatch()) {
                        //call a future method to update the POC records
                        syncProofOfConceptFieldsFuture(oppIds);
                    }
                    else {
                        //call a method to update the POC records
                        syncProofOfConceptFields(oppIds);
                    }
                }
            }
        }
    }

    /**
     * Future method that syncs certains fields from parent opp to child POC opp
     *
     * oppIds: A set of parent opportunities whose child POCs should be updated
     */
    @future 
    public static void syncProofOfConceptFieldsFuture(Set<Id> oppIds) {
        syncProofOfConceptFields(oppIds);
    }

    /**
     * Method that syncs certains fields from parent opp to child POC opp
     *
     * oppIds: A set of parent opportunities whose child POCs should be updated
     */
    public static void syncProofOfConceptFields(Set<Id> oppIds) {
        List<Opportunity> updatedOpps = [
            SELECT Id,
                AccountId,
                Country_of_Order__c,
                (SELECT Id,
                    AccountId,
                    Cloned_From_Opportunity__c,
                    Country_of_Order__c
                 FROM ClonedOpportunities__r
                 WHERE RecordTypeId = :pocRecordTypeId)
            FROM Opportunity
            WHERE Id IN :oppIds];

        List<Opportunity> updatedPOCs = new List<Opportunity>();
        for(Opportunity opp : updatedOpps) {
            for(Opportunity poc : opp.ClonedOpportunities__r) {
                poc.AccountId = opp.AccountId;
                poc.Country_of_Order__c = opp.Country_of_Order__c;
                updatedPOCs.add(poc);
            }
        }

        if(!updatedPOCs.isEmpty()) {
            // update everything we can
            Database.update(updatedPOCs,false);
        }
    }

    /**
     * Looks for the setting of the POC_Submit_for_BU_Approval__c flag and then
     *  automatically submits a POC for BU approval. This is used to chain together
     *  the SA Management approval process and the BU approval process. The flag
     *  is set by an approval action on each of the regional SA Management processes.
     */
    public void submitForBUApproval() {
        if(isUpdate && ! System.isFuture() ) {
            for(Opportunity poc : newMap.values()) {
                Opportunity oldPoc = oldMap.get(poc.Id);
                try {
                    if(poc.RecordTypeId == pocRecordTypeId 
                            && poc.POC_Submit_for_BU_Approval__c 
                            && !oldPoc.POC_Submit_for_BU_Approval__c
                            && poc.POC_Approved_by_SA_Management__c) {     
                        Approval.ProcessSubmitRequest submitRequest = new Approval.ProcessSubmitRequest();
                        submitRequest.setObjectId(poc.id);
                        submitRequest.setNextApproverIds(new Id[] {UserInfo.getUserId()});
                        // submit the POC into an the BU approval process                          
                        Approval.ProcessResult result = Approval.process(submitRequest);
                        // get the work item Id
                        List<Id> workItemIds = result.getNewWorkitemIds();
                        // figure out if the pending approval is assigned to the current user, and if so, auto approve
                        List<ProcessInstanceWorkitem> workItems = [
                            SELECT ActorId
                            FROM ProcessInstanceWorkitem 
                            WHERE Id = :workItemIds[0]];
                        if(!workItems.isEmpty() && workItems[0].ActorId == UserInfo.getUserId()) {
                            // create a ProcessWorkitemRequest
                            Approval.ProcessWorkitemRequest approveRequest = new Approval.ProcessWorkitemRequest();
                            approveRequest.setComments('No BU approval required - automatically approved');
                            approveRequest.setAction('Approve');
                            approveRequest.setWorkitemId(workItemIds[0]);
                            // complete the approval 
                            Approval.ProcessResult result2 =  Approval.process(approveRequest);
                        }
                    }
                }
                catch(Exception e) {}
            }
        }
    }

    /**
     * Link the solution which created this opportunity.
     */
    public void linkSolutions() {
        if(isInsert) {
            List<StrategicPlan_SolutionOpportunity__c> solutionOpportunities = new List<StrategicPlan_SolutionOpportunity__c>();
            for(Opportunity opp : newMap.values()) {
                if(opp.CreatedFromSolution__c != null) {
                    solutionOpportunities.add(
                        new StrategicPlan_SolutionOpportunity__c(
                            Opportunity__c = opp.Id,
                            StrategicPlan_Solution__c = opp.CreatedFromSolution__c));
                }
            }
            if(! solutionOpportunities.isEmpty()) {
                for(Database.Saveresult sr : Database.insert(solutionOpportunities,false)) {
                    StrategicPlan_SolutionOpportunity__c solutionOpportunity = solutionOpportunities.remove(0);
                    if(!sr.isSuccess()) {
                        addError(newMap,solutionOpportunity.Opportunity__c,'Failed to link solution: '+sr.getErrors());
                    }
                }
            }
        }
    }

    static Map<String,Decimal> cleanServiceEffortAllocationMap(Map<String,Decimal> servicesEffortAllocationMap) {
        servicesEffortAllocationMap.remove(null);
        for(String productLine : servicesEffortAllocationMap.keySet()) {
            Decimal servicesEffortAllocation = servicesEffortAllocationMap.get(productLine);
            if(servicesEffortAllocation == null || servicesEffortAllocation <= 0) {
                servicesEffortAllocationMap.remove(productLine);
            }
        }
        return servicesEffortAllocationMap;
    }

    static void populateServicesAllocationsLists(
        List<Opportunity> newList,
        Map<Id,Opportunity> oldMap,
        Boolean dataMigrate,
        Set<Id> deleteSet,
        List<Id> oppIds,
        List<String> currencyIsoCodes,
        List<String> productLines,
        List<Decimal> servicesEffortAllocations,
        List<String> externalIds)
    {
        DateTime migratedDate = DateTime.newInstanceGmt(2013,9,27);
        for(Opportunity opp : newList) {
            Map<String,Decimal> newServicesEffortAllocationMap = cleanServiceEffortAllocationMap(
                new Map<String,Decimal>{
                    opp.Services_Product_Line_1__c => opp.Services_Effort_Allocation_1__c,
                    opp.Services_Product_Line_2__c => opp.Services_Effort_Allocation_2__c,
                    opp.Services_Product_Line_3__c => opp.Services_Effort_Allocation_3__c,
                    opp.Services_Product_Line_4__c => opp.Services_Effort_Allocation_4__c,
                    opp.Services_Product_Line_5__c => opp.Services_Effort_Allocation_5__c,
                    opp.Services_Product_Line_6__c => opp.Services_Effort_Allocation_6__c } );
            Map<String,Decimal> oldServicesEffortAllocationMap = new Map<String,Decimal>();
            if(oldMap != null) {
                Opportunity oldOpp = oldMap.get(opp.Id);
                if( oldOpp != null) {
                    oldServicesEffortAllocationMap = cleanServiceEffortAllocationMap(
                        new Map<String,Decimal>{
                            oldOpp.Services_Product_Line_1__c => oldOpp.Services_Effort_Allocation_1__c,
                            oldOpp.Services_Product_Line_2__c => oldOpp.Services_Effort_Allocation_2__c,
                            oldOpp.Services_Product_Line_3__c => oldOpp.Services_Effort_Allocation_3__c,
                            oldOpp.Services_Product_Line_4__c => oldOpp.Services_Effort_Allocation_4__c,
                            oldOpp.Services_Product_Line_5__c => oldOpp.Services_Effort_Allocation_5__c,
                            oldOpp.Services_Product_Line_6__c => oldOpp.Services_Effort_Allocation_6__c } );
                    Boolean dataMigrate2 = dataMigrate || ( oldOpp.LastModifiedDate < migratedDate); 
                    if ( dataMigrate2
                        || oldOpp.CurrencyIsoCode != opp.CurrencyIsoCode 
                        || ! newServicesEffortAllocationMap.keySet().containsAll(oldServicesEffortAllocationMap.keySet()) )
                    {
                        if(deleteSet != null) {
                            deleteSet.add(opp.Id);
                        }
                        oldServicesEffortAllocationMap.clear();
                    }
                }
            }
            for(String productLine : newServicesEffortAllocationMap.keySet()) {
                Decimal servicesEffortAllocationNew = newServicesEffortAllocationMap.get(productLine);
                Decimal servicesEffortAllocationOld = oldServicesEffortAllocationMap.get(productLine);
                if(servicesEffortAllocationOld != servicesEffortAllocationNew) {
                    oppIds.add(opp.Id);
                    currencyIsoCodes.add(opp.CurrencyIsoCode);
                    productLines.add(productLine);
                    servicesEffortAllocations.add(servicesEffortAllocationNew);
                    externalIds.add(opp.Id+('-'+productLine).toUpperCase());
                }
            }
        }
    }

    /**
     * Creates, updates, and delete services allocation records to use with BO reporting.
     */
    public void updateServicesAllocations() {
        Boolean dataMigrate = AbstractTrigger.isActive(SERVICES_ALLOCATIONS_MIGRATE_DATA_SETTING,true);
        if(! dataMigrate) {
            DateTime migratedDate = DateTime.newInstance(2013,09,27,00,00,00);
            for(Opportunity opp : newMap.values()) {
                if(opp.LastModifiedDate < migratedDate) {
                    dataMigrate = true;
                    break;
                }
            }
        }
        // set of opportunity ids which should have all allocations deleted.
        Set<Id> deleteSet = new Set<Id>();
        List<Id> oppIds = new List<Id>();
        List<String> currencyIsoCodes = new List<String>();
        List<String> productLines = new List<String>();
        List<Decimal> servicesEffortAllocations = new List<Decimal>();
        List<String> externalIds = new List<String>();
        populateServicesAllocationsLists(
            newMap.values(),
            oldMap,
            dataMigrate,
            deleteSet,
            oppIds,
            currencyIsoCodes,
            productLines,
            servicesEffortAllocations,
            externalIds);
        if(! (oppIds.isEmpty() && deleteSet.isEmpty()) ) {
            if(updateServicesAllocationsNow || System.isBatch() || isFuture) {
                List<ServicesAllocation__c> deleteList = null;
                if(!deleteSet.isEmpty()) {
                    deleteList = [
                        select Opportunity__c
                        from ServicesAllocation__c
                        where Opportunity__c in :deleteSet 
                            and ExternalId__c not in :externalIds ];
                }
                if(! (oppIds.isEmpty() && (deleteList == null || deleteList.isEmpty())) ) {
                    updateServicesAllocationsStatic(this,deleteList,oppIds,currencyIsoCodes,productLines,servicesEffortAllocations);
                }
            }
            else {
                Set<Id> oppIdSet = deleteSet;
                oppIdSet.addAll(oppIds);
                updateServicesAllocationsFuture(oppIdSet,dataMigrate);
            }
        }
    }

    @future
    private static void updateServicesAllocationsFuture(Set<Id> oppIdSet,Boolean dataMigrate) {
        updateServicesAllocationsStatic( dataMigrate, [
            select
                CurrencyIsoCode,
                Services_Product_Line_1__c,
                Services_Effort_Allocation_1__c,
                Services_Product_Line_2__c,
                Services_Effort_Allocation_2__c,
                Services_Product_Line_3__c,
                Services_Effort_Allocation_3__c,
                Services_Product_Line_4__c,
                Services_Effort_Allocation_4__c,
                Services_Product_Line_5__c,
                Services_Effort_Allocation_5__c,
                Services_Product_Line_6__c,
                Services_Effort_Allocation_6__c,
                (   select
                        CurrencyIsoCode,
                        ExternalId__c,
                        Opportunity__c,
                        ServicesEffortAllocation__c,
                        ServicesProductLine__c
                    from Services_Allocations__r) 
            from Opportunity
            where Id in :oppIdSet ] );
    }

    @TestVisible
    private static void updateServicesAllocationsStatic(Boolean dataMigrate,List<Opportunity> oppList) {
        // there may have been other updates since this call was queued, so we need to rebuild the data set
        List<Id> oppIds = new List<Id>();
        List<String> currencyIsoCodes = new List<String>();
        List<String> productLines = new List<String>();
        List<Decimal> servicesEffortAllocations = new List<Decimal>();
        List<String> externalIds = new List<String>();

        populateServicesAllocationsLists(
            oppList,
            null,
            dataMigrate,
            null,
            oppIds,
            currencyIsoCodes,
            productLines,
            servicesEffortAllocations,
            externalIds);

        Map<String,ServicesAllocation__c> servicesAllocationMap = new Map<String,ServicesAllocation__c>();
        for(Opportunity opp : oppList) {
            if(opp.Services_Allocations__r != null) {
                for( ServicesAllocation__c servicesAllocation : opp.Services_Allocations__r ) {
                    servicesAllocationMap.put(servicesAllocation.ExternalId__c,servicesAllocation);
                }
            }
        }

        for(Integer i=externalIds.size();i-- > 0;) {
            ServicesAllocation__c servicesAllocation = servicesAllocationMap.remove(externalIds[i]);
            if(servicesAllocation != null) {
                if(servicesAllocation.CurrencyIsoCode == currencyIsoCodes[i]
                    && servicesAllocation.ServicesEffortAllocation__c == servicesEffortAllocations[i]
                    && servicesAllocation.ServicesProductLine__c == productLines[i])
                {
                    oppIds.remove(i);
                    currencyIsoCodes.remove(i);
                    productLines.remove(i);
                    servicesEffortAllocations.remove(i);
                    externalIds.remove(i);
                }
            }
        }
        updateServicesAllocationsStatic(null,servicesAllocationMap.values(),oppIds,currencyIsoCodes,productLines,servicesEffortAllocations);
    }

    private static void updateServicesAllocationsStatic(
        OpportunityTriggerAfter2 afterTrigger,
        List<ServicesAllocation__c> deleteList,
        List<Id> oppIds,
        List<String> currencyIsoCodes,
        List<String> productLines,
        List<Decimal> servicesEffortAllocations)
    {
        System.assert(! (oppIds.isEmpty() && (deleteList == null || deleteList.isEmpty())) , 'Expected either a line to delete a line to upsert.');
        Map<Id,Opportunity> xnewMap = null;
        if(afterTrigger != null) {
            xnewMap = afterTrigger.newMap;
        }
        // remove obsolete services allocations records
        if(deleteList != null && ! deleteList.isEmpty()) {
            for(Database.DeleteResult dr : Database.delete(deleteList,false)) {
                ServicesAllocation__c sa = deleteList.remove(0);
                if(! dr.isSuccess()) {
                    addErrorStatic(afterTrigger,xnewMap,sa.Opportunity__c,'Failed to delete services allocation: '+dr.getErrors());
                }
            }
        }
        // upsert current services allocations records
        if(! oppIds.isEmpty()) {
            List<ServicesAllocation__c> upsertList = new List<ServicesAllocation__c>();
            for(Integer i=0,oppIdsSize=oppIds.size();i < oppIdsSize;i++) {
                upsertList.add(new ServicesAllocation__c(
                    CurrencyIsoCode = currencyIsoCodes[i],
                    ExternalId__c = oppIds[i]+('-'+productLines[i]).toUpperCase(),
                    Opportunity__c = oppIds[i],
                    ServicesEffortAllocation__c = servicesEffortAllocations[i],
                    ServicesProductLine__c = productLines[i]));
            }
            for(Database.UpsertResult ur : Database.upsert(upsertList,ServicesAllocation__c.Fields.ExternalId__c,false)) {
                ServicesAllocation__c sa = upsertList.remove(0);
                if(! ur.isSuccess()) {
                    addErrorStatic(afterTrigger,xnewMap,sa.Opportunity__c,'Failed to upsert services allocation: '+ur.getErrors());
                }
            }
        }
    }

    public static EmailTemplate POC_OWNER_CHANGE_EMAIL_TEMPLATE {
        get {
            if(POC_OWNER_CHANGE_EMAIL_TEMPLATE == null) {
                for(EmailTemplate et : [
                    select Name, Body, HtmlValue, Subject, Description
                    from EmailTemplate
                    where
                        Folder.Type = 'Email'
                        and Folder.Name = 'Alerts' 
                        and DeveloperName = 'POC_Owner_Change'
                        and IsActive = true
                    order by LastModifiedDate ] )
                {
                    POC_OWNER_CHANGE_EMAIL_TEMPLATE = et;
                }
            }
            return POC_OWNER_CHANGE_EMAIL_TEMPLATE;
        }
        set;
    }

    /**
     * Notify users when the owner of an POC has changed.
     */
    public Messaging.SingleEmailMessage notifyOwnerChange() {
        Messaging.SingleEmailMessage retval = null;
        if(isUpdate) {
            Id currentUserId = UserInfo.getUserId();
            Set<Id> oppIds = new Set<Id>();
            Set<Id> ownerIds = new Set<Id>{ currentUserId };
            for(Opportunity opp : newMap.values()) {
                if(opp.RecordTypeId == pocRecordTypeId) {
                    Opportunity oldOpp = oldMap.get(opp.Id);
                    if(opp.OwnerId != oldOpp.OwnerId || (oldOpp.Owner__c != null && opp.Owner__c != null && opp.Owner__c != oldOpp.Owner__c)) {
                        oppIds.add(opp.Id);
                        ownerIds.add(opp.OwnerId);
                        ownerIds.add(oldOpp.OwnerId);
                        Id modifiedById = currentUserId;
                        if(opp.OwnerId == oldOpp.OwnerId) {
                            ownerIds.add(oldOpp.Owner__c);
                            modifiedById = oldOpp.LastModifiedById;
                        }
                        ownerIds.add(modifiedById);
                    }
                }
            }
            if(! oppIds.isEmpty() && POC_OWNER_CHANGE_EMAIL_TEMPLATE != null) {
                Set<String> emailAddressSet = new Set<String>();
                Map<Id,User> userMap = new Map<Id,User>();
                for(Id oppId : oppIds) {
                    Opportunity opp = proofOfConceptMap.get(oppId);
                    if(opp != null) {
                        for(OpportunityTeamMemberClone__c opportunityTeamMemberClone : opp.OpportunityTeamMemberClones__r) {
                            if(opportunityTeamMemberClone.User__r != null && opportunityTeamMemberClone.User__r.IsActive == true) {
                                userMap.put(opportunityTeamMemberClone.User__c,opportunityTeamMemberClone.User__r);
                                emailAddressSet.add(opportunityTeamMemberClone.User__r.Email);
                            }
                        }
                    }
                }
                ownerIds.removeAll(userMap.keySet());
                ownerIds.remove(null);
                if(! ownerIds.isEmpty() ) {
                    userMap.putAll( [
                        select
                            Email,
                            EnterpriseServerUrl__c,
                            Name
                        from User
                        where Id in :ownerIds and IsActive = true ] );
                }
                if(! userMap.isEmpty()) {
                    String body = POC_OWNER_CHANGE_EMAIL_TEMPLATE.Body;
                    String htmlValue = POC_OWNER_CHANGE_EMAIL_TEMPLATE.HtmlValue;
                    String enterpriseServerUrl = userMap.values()[0].EnterpriseServerUrl__c;
                    if(htmlValue != null) {
                        htmlValue = htmlValue.replace('OPP_LIST','<ul>\nOPP_LIST\n</ul>');
                    }
                    for(Id oppId : oppIds) {
                        Opportunity opp = newMap.get(oppId);
                        User oppOwner = userMap.get(opp.OwnerId);
                        String oppValue = 'POC Name: '+opp.Name
                            + '\nPOC Link: '+enterpriseServerUrl+opp.Id;
                        if(oppOwner != null) {
                            oppValue += '\nNew Owner: '+oppOwner.Name+' <'+oppOwner.Email+'>';
                        }
                        Opportunity oldOpp = oldMap.get(opp.Id);
                        User modifyUser = userMap.get(CurrentUserId);
                        Id oldOwnerId = oldOpp.OwnerId;
                        if(oldOwnerId == opp.OwnerId) {
                            oldOwnerId = oldOpp.Owner__c;
                            modifyUser = userMap.get(oldOpp.LastModifiedById);
                        }
                        User oldOwner = userMap.get(oldOwnerId);
                        if(oldOwner != null) {
                            oppValue += '\nOld Owner: '+oldOwner.Name+' <'+oldOwner.Email+'>';
                        }
                        if(modifyUser != null) {
                            oppValue += '\nChanged By: '+modifyUser.Name+' <'+modifyUser.Email+'>';
                        }
                        body = body.replace('OPP_LIST',oppValue+'\n\nOPP_LIST');
                        if(htmlValue != null) {
                            String oppName = (''+opp.Name).escapeXml();
                            oppValue = 'POC: <a href="'+enterpriseServerUrl+'/'+opp.Id+'">'+oppName+'</a>';
                            if(oppOwner != null && oppOwner.Email != null) {
                                oppValue +='<br />New Owner: <a href="' + enterpriseServerUrl + oppOwner.Id + '">'
                                    + (''+oppOwner.Name).escapeXml()
                                    + '</a>&#160;&lt;<a href="mailto:'+EncodingUtil.urlEncode(oppOwner.Email,'UTF8')+'">'
                                    + oppOwner.Email.escapeXml()
                                    + '</a>&gt;';
                            }
                            if(oldOwner != null && oldOwner.Email != null) {
                                oppValue +='<br />Old Owner: <a href="' + enterpriseServerUrl + oppOwner.Id + '">'
                                    + (''+oldOwner.Name).escapeXml()
                                    + '</a>&#160;&lt;<a href="mailto:'+EncodingUtil.urlEncode(oldOwner.Email,'UTF8')+'">'
                                    + oldOwner.Email.escapeXml()
                                    + '</a>&gt;';
                            }
                            if(modifyUser != null && modifyUser.Email != null) {
                                oppValue +='<br />Changed By: <a href="' + enterpriseServerUrl + modifyUser.Id + '">'
                                    + (''+modifyUser.Name).escapeXml()
                                    + '</a>&#160;&lt;<a href="mailto:'+EncodingUtil.urlEncode(modifyUser.Email,'UTF8')+'">'
                                    + modifyUser.Email.escapeXml()
                                    + '</a>&gt;';
                            }
                            htmlValue = htmlValue.replace('OPP_LIST','<li>'+oppValue+'</li>\nOPP_LIST');
                        }
                    }
                    body = body.replace('OPP_LIST','');
                    if(htmlValue != null) {
                        htmlValue = htmlValue.replace('OPP_LIST','');
                    }
                    for(Id oppId : oppIds) {
                        Opportunity oldOpp = oldMap.get(oppId);
                        Id oldOwnerId = oldOpp.OwnerId;
                        if(oldOwnerId == newMap.get(oppId).OwnerId) {
                            oldOwnerId = oldOpp.Owner__c;
                        }
                        User u = userMap.get(oldOwnerId);
                        if(u != null && u.Email != null) {
                            emailAddressSet.add(u.Email);
                        }
                    }
                    List<List<String>> emailAddressesList = new List<List<String>>();
                    List<String> currentList = null;
                    for(String emailAddress : emailAddressSet) {
                        if(currentList == null || currentList.size() == 100) {
                            emailAddressesList.add(currentList);
                            currentList = new List<String>();
                        }
                        currentList.add(emailAddress);
                    }
                    emailAddressesList.add(currentList);
                    List<Messaging.SingleEmailMessage> allMail = new List<Messaging.SingleEmailMessage>();
                    for(List<String> emailAddresses : emailAddressesList) {
                        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                        mail.setPlainTextBody(body);
                        if(htmlValue != null) {
                            mail.setHtmlBody(htmlValue);
                        }
                        mail.setSubject(POC_OWNER_CHANGE_EMAIL_TEMPLATE.Subject);
                        mail.setToAddresses(emailAddresses);
                        allMail.add(mail);
                    }
                    for(Messaging.SendEmailResult r : Messaging.sendEmail(allMail,false)) {
                        System.debug(r.getErrors());
                        retval = allMail.remove(0);
                    }
                }
            }
        }
        return retval;
    }

    @future
    public static void updateContractsFuture(Set<Id> contractIds) {
        List<Contract> contracts = new List<Contract>();
        for(Id contractId : contractIds) {
            contracts.add(new Contract(Id=contractId));
        }
        updateContracts(contracts);
    }

    public static void updateContracts(List<Contract> contracts) {
        if(! contracts.isEmpty()) {
            if(! System.isFuture()) {
                Database.update(contracts,false);
            }
            else {
                updateContractsFuture(new Map<Id,Contract>(contracts).keySet());
            }
        }
    }

    /**
     * Synchronized contracts to assign the respective region values from the country of order.
     */
    public void syncContracts() {
        if(isUpdate && ! hasErrors) {
            Set<Id> oppIds = new Set<Id>();
            for(Opportunity opp : newMap.values()) {
                Opportunity oldOpp = oldMap.get(opp.Id);
                if(oldOpp != null) {
                    if(oldOpp.Country_of_Order__c != opp.Country_of_Order__c
                        || oldOpp.Region2__c != opp.Region2__c
                        || oldOpp.Region__c != opp.Region__c
                        || oldOpp.SubRegion__c != opp.SubRegion__c )
                    {
                        oppIds.add(opp.Id);
                    }
                }
            }
            if(! oppIds.isEmpty()) {
                updateContracts([
                    select Id
                    from Contract
                    where Opportunity__c in :oppIds 
                        and Global__c != true ]);
            }
        }
    }

    /**
     * This is a simplified stage mapping logic to use for lead management history.
     * When an opportunity probability changed from the converted probability value
     * it is considered SALES_ACCEPTED.  When Closed Lost, it is Closed Lost, and when 
     * Closed Booked it is Closed Booked.
     */
    public static String leadStage(Opportunity opp,Boolean probabilityChange,String stage) {
        // this is needed because it is possible for the sales accepted and sales qualified
        // to be in reverse order
        if(stage == SALES_ACCEPTED) {
            stage = SALES_QUALIFIED;
        }
        else if(stage != SALES_QUALIFIED && (probabilityChange || opp.IsClosed == true)) {
            stage = SALES_ACCEPTED;
        }
        if(opp.IsClosed == true) {
            if(opp.StageName == OpportunityTriggerBefore2.CLOSED_LOST_PLV) {
                stage = LEAD_LOST;
            }
            else if(opp.StageName == OpportunityTriggerBefore2.CLOSED_BOOKED_PLV) {
                stage = LEAD_WON;
            }
        }
        return stage;
    }

    @TestVisible
    private static Boolean isFuture {
        get {
            return (isFuture == true)||System.isFuture();
        }
        set;
    }

    /**
     * Update lead history records.
     */
    public void leadHistory() {
        if(isUpdate) {
            // generate the list of opportunity ids that need a new lead management history record
            // we use a map instead of relying on ConvertedOpportunityId, so test methods don't need to
            // use converted leads
            Map<Id,Id> oppIdByLeadForReportingIdMap = new Map<Id,Id>();
            for(Opportunity opp : newMap.values()) {
                if(opp.LFR__c != null) {
                    Opportunity oldOpp = oldMap.get(opp.Id);
                    Boolean probabilityChange = (oldOpp.Probability != opp.Probability && ! isFuture);
                    String oldStage = leadStage(oldOpp,false,null);
                    String stage = leadStage(opp,probabilityChange,oldStage);
                    if(oldOpp.CloseDate != opp.CloseDate || oldOpp.OwnerId != opp.OwnerId || oldStage != stage) {
                        oppIdByLeadForReportingIdMap.put(opp.LFR__c,opp.Id);
                    }
                }
            }
            if(! oppIdByLeadForReportingIdMap.isEmpty()) {
                List<LeadManagementHistory__c> lmhList = new List<LeadManagementHistory__c>();
                // query the related leads and most recent history record
                for(LeadForReporting__c lfr : [
                    select
                        Id,
                        (   select
                                Amount_From__c,
                                Amount_To__c,
                                ForecastCategory_From__c,
                                ForecastCategory_To__c,
                                CloseDate_From__c,
                                CloseDate_To__c,
                                CreatedDate,
                                FromCloseDateModifiedDateTime__c,
                                FromOwnerModifiedDateTime__c,
                                FromStageModifiedDateTime__c,
                                Interest_Score__c,
                                Qualified_By__c,
                                Qualified_By__r.IsActive,
                                Lead_Ranking__c,
                                Lead_Source__c,
                                Lead_Source_Detail__c,
                                LeadId__c,
                                LeadStageFrom__c,
                                LeadStageTo__c,
                                LFR__c,
                                Opportunity__c,
                                OwnerId_From__c,
                                OwnerId_To__c,
                                Pre_Qualified_To__c,
                                Probability_From__c,
                                Probability_To__c, 
                                Qualification_Score__c,
                                Route_Around_To__c
                            from Lead_Management_Histories__r
                            order by CreatedDate desc,Id desc
                            limit 1)
                    from LeadForReporting__c
                    where Id in :oppIdByLeadForReportingIdMap.keySet() ])
                {
                    Id oppId = oppIdByLeadForReportingIdMap.get(lfr.Id);
                    // if there is a history record create a new history record
                    for(LeadManagementHistory__c lmh : lfr.Lead_Management_Histories__r) {
                        Opportunity opp= newMap.get(oppId);
                        Opportunity oldOpp = oldMap.get(oppId);
                        // we ignore probability changes when they happen in a future call...
                        Boolean probabilityChange = (oldOpp.Probability != opp.Probability && !isFuture);
                        String oldStage = leadStage(oldOpp,false,lmh.LeadStageTo__c);
                        String stage = leadStage(opp,probabilityChange,oldStage);
                        if((oldOpp.CloseDate != opp.CloseDate) || (oldOpp.OwnerId != opp.OwnerId) || (oldStage != stage)) {
                            Boolean updateExisting = (stage == oldStage && isFuture);
                            System.debug('Update existing: '+updateExisting);
                            if(lmh.Qualified_By__r != null && lmh.Qualified_By__r.IsActive != true) {
                                lmh.Qualified_By__r = null;
                                lmh.Qualified_By__c = null;
                            }
                            LeadManagementHistory__c lmh2 = lmh.clone(updateExisting);
                            lmh2.RecordTypeId = RecordTypeLookup.getRecordTypeId('Updated Stage or Owner','LeadManagementHistory__c');
                            if(! updateExisting) {
                                lmh2.Amount_From__c = oldOpp.Amount;
                                lmh2.CloseDate_From__c = oldOpp.CloseDate;
                                lmh2.ForecastCategory_From__c = oldOpp.ForecastCategory;
                                lmh2.LeadStageFrom__c = lmh2.LeadStageTo__c;
                                lmh2.Probability_From__c = oldOpp.Probability;
                                lmh2.Pre_Qualified_From__c = lmh2.Pre_Qualified_To__c;
                                lmh2.Route_Around_From__c = lmh2.Route_Around_To__c;
                                lmh2.OwnerId_From__c = oldOpp.OwnerId;
                            }
                            lmh2.Amount_To__c = opp.Amount;
                            lmh2.CloseDate_To__c = opp.CloseDate;
                            lmh2.CurrencyIsoCode = opp.CurrencyIsoCode;
                            lmh2.ForecastCategory_To__c = opp.ForecastCategory;
                            lmh2.Opportunity__c = opp.Id;
                            lmh2.OwnerId_To__c = opp.OwnerId;
                            lmh2.Probability_To__c = opp.Probability;
                            Boolean closeDateChanged = lmh2.CloseDate_From__c != lmh2.CloseDate_To__c;
                            if(closeDateChanged) {
                                lmh2.Comments__c = opp.Close_Date_Moved_Details__c;
                            }
                            if(lmh2.LeadStageTo__c != stage) {
                                lmh2.LeadStageTo__c = stage;
                                if(stage == LEAD_LOST) {
                                    lmh2.RecordTypeId = RecordTypeLookup.getRecordTypeId('Rejected','LeadManagementHistory__c');
                                    lmh2.Rejection_Reason__c = opp.ReasonWonLostSalesProcess__c;
                                }
                            }
                            if(lmh.LeadStageFrom__c != lmh.LeadStageTo__c) {
                                lmh2.FromStageModifiedDateTime__c = lmh.CreatedDate;
                            }
                            if(lmh.OwnerId_From__c != lmh.OwnerId_To__c) {
                                lmh2.FromOwnerModifiedDateTime__c = lmh.CreatedDate;
                            }
                            if(lmh.Opportunity__c == null || lmh.CloseDate_From__c != lmh.CloseDate_To__c) {
                                lmh2.FromCloseDateModifiedDateTime__c = lmh.CreatedDate;
                            }
                            lmhList.add(lmh2);
                            // sales accepted need to become sales qualified
                            if(stage == SALES_ACCEPTED) {
                                LeadManagementHistory__c lmh3 = lmh2.clone(false);
                                lmh3.Amount_From__c = lmh2.Amount_To__c;
                                lmh3.CloseDate_From__c = lmh2.CloseDate_To__c;
                                lmh3.FromStageModifiedDateTime__c = opp.LastModifiedDate;
                                lmh3.ForecastCategory_From__c = lmh2.ForecastCategory_To__c;
                                lmh3.Probability_To__c = lmh2.Probability_From__c; 
                                lmh3.LeadStageFrom__c = lmh2.LeadStageTo__c;
                                lmh3.OwnerId_From__c = lmh2.OwnerId_To__c;
                                lmh3.Comments__c = null;
                                lmh3.LeadStageTo__c = SALES_QUALIFIED;
                                if(closeDateChanged) {
                                    lmh3.FromCloseDateModifiedDateTime__c = opp.LastModifiedDate;
                                }
                                if(lmh2.OwnerId_From__c != lmh2.OwnerId_To__c) {
                                    lmh3.FromOwnerModifiedDateTime__c = opp.LastModifiedDate;
                                }
                                lmhList.add(lmh3);
                            }
                        }
                    }
                }
                if(! lmhList.isEmpty()) {
                    for(Database.UpsertResult sr : Database.upsert(lmhList,false)) {
                        LeadManagementHistory__c lmh = lmhList.remove(0);
                        if((! isFuture) && (! sr.isSuccess())) {
                            Opportunity opp = newMap.get(lmh.Opportunity__c);
                            opp.addError('Failed to insert LMH Record: '+sr.getErrors());
                            hasErrors = true;
                        }
                    }
                }
            }
        }
    }

    @TestVisible
    List<Opportunity> queriedOpportunities {
        get {
            if(queriedOpportunities == null) {
                Set<Id> oppIds = new Set<Id>(removeFinancialPartnerOppIds);
                oppIds.addAll(oppIdsBackOut);
                queriedOpportunities = new List<Opportunity>();
                if(! oppIds.isEmpty()) {
                    queriedOpportunities = [
                        select 
                            Id,
                            (   select
                                    Id,
                                    Opportunity__c,
                                    RelationshipType__c
                                from OpportunityPartners2__r
                                where Opportunity__c in :removeFinancialPartnerOppIds
                                    and RelationshipType__c = 'Financial'),
                            (   select
                                    Id,
                                    Opportunity__c,
                                    Order_Status__c
                                from Order_Tracking__r 
                                where Opportunity__c in :oppIdsBackOut
                                    and Order_Status__c != :REVERTED_PLV )
                        from Opportunity
                        where Id in :oppIds ];
                }
            }
            return queriedOpportunities;
        }
        set;
    }

    @TestVisible
    Set<Id> removeFinancialPartnerOppIds {
        get {
            if(removeFinancialPartnerOppIds == null) {
                removeFinancialPartnerOppIds = new Set<Id>();
                if(isUpdate) {
                    for(Opportunity opp : newMap.values()) {
                        Opportunity oldOpp = oldMap.get(opp.Id);
                        if(Opportunity_ManagePartners.FINANCIAL_PARTNER_CHANNELS.contains(oldOpp.FulfillmentChannel__c)
                            && Opportunity_ManagePartners.NO_FINANCIAL_PARTNER_CHANNELS.contains(opp.FulfillmentChannel__c))
                        {
                            removeFinancialPartnerOppIds.add(opp.Id);
                        }
                    }
                }
            }
            return removeFinancialPartnerOppIds;
        }
        set;
    }

    public void removeFinancialPartner() {
        if(! removeFinancialPartnerOppIds.isEmpty()) {
            List<OpportunityPartner__c> financialPartners = new List<OpportunityPartner__c>();
            for(Opportunity opp : queriedOpportunities) {
                if(removeFinancialPartnerOppIds.contains(opp.Id) && opp.OpportunityPartners2__r != null) {
                    for(OpportunityPartner__c op : opp.OpportunityPartners2__r) {
                        if(op.RelationshipType__c == 'Financial') {
                            financialPartners.add(op);
                        }
                    }
                }
            }
            if(!financialPartners.isEmpty()) {
                for(Database.DeleteResult dr : Database.delete(financialPartners,false)) {
                    OpportunityPartner__c financialPartner = financialPartners.remove(0);
                    if((!isFuture) && (!dr.isSuccess())) {
                        Opportunity opp = newMap.get(financialPartner.Opportunity__c);
                        opp.addError('Failed to delete Financial Partner: ' + dr.getErrors());
                        hasErrors = true;
                    }
                }
            }
        }
    }

    @TestVisible
    Set<Id> oppIdsSubmittedForReview {
        get {
            if(oppIdsSubmittedForReview == null) {
                oppIdsSubmittedForReview = new Set<Id>();
                for(Opportunity opp : newMap.values()) {
                    if(opp.Order_Status__c == SUBMITTED_FOR_OM_REVIEW_PLV && opp.Country_of_Order__c != null) {
                        Opportunity oldOpp =  oldMap.get(opp.Id);
                        if(oldOpp == null || oldOpp.Order_Status__c != opp.Order_Status__c) {
                            oppIdsSubmittedForReview.add(opp.Id);
                        }
                    }
                }
                oppIdsSubmittedForReview.removeAll(oppIdsBackOut);
            }
            return oppIdsSubmittedForReview;
        }
        set;
    }

    @TestVisible
    Set<Id> oppIdsBackOut {
        get {
            if(oppIdsBackOut == null) {
                oppIdsBackOut = new Set<Id>();
                if(isUpdate) {
                    for(Opportunity opp : newMap.values()) {
                        if(opp.IsClosed != true) {
                            Opportunity oldOpp =  oldMap.get(opp.Id);
                            if(oldOpp != null && oldOpp.StageName == OpportunityTriggerBefore2.CLOSED_WON_PLV) {
                                oppIdsBackOut.add(opp.Id);
                            }
                        }
                    }
                }
            }
            return oppIdsBackOut;
        }
        set;
    }

    static Id OM_TASK_ID {
        get {
            if(OM_TASK_ID == null) {
                OM_TASK_ID = Schema.SObjectType.Task.getRecordTypeInfosByName().get('OM Processing Task').getRecordTypeId();
            }
            return OM_TASK_ID;
        }
        set;
    }


    @TestVisible
    List<Task> tasks {
        get {
            if(tasks == null) {
                tasks = [
                    select
                        Id,
                        IsClosed,
                        Status,
                        RecordTypeId,
                        WhatId
                    from Task
                    where IsClosed = false
                        and RecordTypeId = :OM_TASK_ID
                        and ((Status = :NOT_STARTED_PLV and WhatId IN :oppIdsSubmittedForReview)
                            or WhatId IN :oppIdsBackOut) ];
            }
            return tasks;
        }
        set;
    }

    /**
     * Replaces the Opportunity_Submitted_to_OM trigger to create a task for order management.
     */
    public void submitToOrderManagement() {
        if(! oppIdsSubmittedForReview.isEmpty()) {
            Set<Id> oppIds = new Set<Id>(oppIdsSubmittedForReview);
            for(Task t : tasks) {
                if( t.RecordTypeId == OM_TASK_ID 
                    && t.Status == NOT_STARTED_PLV
                    && oppIds.contains(t.WhatId) )
                {
                    oppIds.remove(t.WhatId);
                }
            }
            if(! oppIds.isEmpty()){
                // find the countries we need to lookup for each task
                Set<String> countries=new Set<String>();
                for(Id oppId : oppIds) {
                    Opportunity opp = newMap.get(oppId);
                    if(opp != null && opp.Country_Of_Order__c != null) {
                        countries.add(opp.Country_Of_Order__c);
                    }
                }
                if(! countries.isEmpty()) {
                    Map<String,Region__c> regionMap = new Map<String,Region__c>();
                    for(Region__c region: [
                        select
                            Country__c, 
                            Super_Region__c,
                            OM_Task_Owner__c
                        from Region__c 
                        where Country__c IN :countries
                            and OM_Task__c = true
                            and OM_Task_Owner__c != null
                            and Super_Region__c != null ] )
                    {
                        regionMap.put(region.Country__c,region);
                    }
                    List<Task> insertTasks = new List<Task>();
                    for(Id oppId : oppIds) {
                        Opportunity opp = newMap.get(oppId);
                        Region__c r = regionMap.get(opp.Country_of_Order__c);
                        if(r != null) {
                            insertTasks.add ( new Task(
                                OwnerId = r.OM_Task_Owner__c,
                                Subject = 'Order Submitted for Processing '+r.Super_Region__c,
                                WhatId=oppId,
                                RecordTypeId = OM_TASK_ID,
                                Status =NOT_STARTED_PLV,
                                Priority = 'Normal',
                                ActivityDate = System.today(),
                                Description='Please proceed with the following:\n' +
                                    '1. Print out the Order using the Order Form custom link on the Opportunity detail.\n'+
                                    '2. After printing the form update this task status to In progress and check the "OE Form Printed" checkbox') );
                        }
                    }
                    if(!insertTasks.isEmpty()) {
                        for(Database.SaveResult sr : Database.insert(insertTasks,false)) {
                            Task t = insertTasks.remove(0);
                            if(! sr.isSuccess()) {
                                Opportunity opp = newMap.get(t.WhatId);
                                for(Database.Error e : sr.getErrors()) {
                                    opp.addError('Failed to insert OM task: '+e.getMessage());
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    /**
     * Implements a backout ouf the order management task and order tracking when returning to an
     * open status.
     */
    public void backoutOrder() {
        if(! oppIdsBackOut.isEmpty()) {
            Boolean needsTasks = false;
            List<Order_Tracking__c> updateOrderTrackingList = new List<Order_Tracking__c>();
            for(Opportunity opp : queriedOpportunities) {
                if(oppIdsBackOut.contains(opp.Id)) {
                    if(opp.Order_Tracking__r != null) {
                        for(Order_Tracking__c ot : opp.Order_Tracking__r) {
                            if(ot.Order_Status__c != REVERTED_PLV) {
                                ot.Order_Status__c = REVERTED_PLV;
                                updateOrderTrackingList.add(ot);
                            }
                        }
                    }
                    needsTasks = needsTasks || (opp.OpenActivities != null && ! opp.OpenActivities.isEmpty());
                }
            }
            if(! updateOrderTrackingList.isEmpty()) {
                for(Database.SaveResult sr : Database.update(updateOrderTrackingList,false)) {
                    Order_Tracking__c ot = updateOrderTrackingList.remove(0);
                    if(! sr.isSuccess()) {
                        Opportunity opp = newMap.get(ot.Opportunity__c);
                        for(Database.Error e : sr.getErrors()) {
                            opp.addError('Failed to revert Order Tracking record: '+e.getMessage());
                        }
                    }
                }
            }
            List<Task> updateTasks = new List<Task>();
            for(Task t : tasks) {
                if(oppIdsBackOut.contains(t.WhatId)
                    && t.RecordTypeId == OM_TASK_ID
                    && t.IsClosed == false )
                {
                    t.Status = SYSTEM_DEFERRED_PLV;
                    updateTasks.add(t);
                }
            }
            if(! updateTasks.isEmpty()) {
                for(Database.SaveResult sr : Database.update(updateTasks,false)) {
                    Task t = updateTasks.remove(0);
                    if(! sr.isSuccess()) {
                        Opportunity opp = newMap.get(t.WhatId);
                        for(Database.Error e : sr.getErrors()) {
                            opp.addError('Failed to close OM task: '+e.getMessage());
                        }
                    }
                }
            }
        }
    }

    /**
     * Refactored from Opportunity_UpdateCountryOppSplit_AU to update the country of
     * OpportunitySplit records.
     */
    public void countryOppSplitAU() {
        if(isUpdate) {
            Set<Id> oppIds = new Set<Id>();
            Set<String> oldCountriesOfOrder = new Set<String>();
            for(Opportunity opp : newMap.values()) {
                Opportunity oldOpp = oldMap.get(opp.Id);
                if(oldOpp != null && oldOpp.Country_of_Order__c != opp.Country_of_Order__c) {
                    oppIds.add(opp.Id);
                    oldCountriesOfOrder.add(oldOpp.Country_of_Order__c);
                }
            }
            if(!oppIds.isEmpty()) {
                List<OpportunitySplit> listChildSplits = new List<OpportunitySplit>();
                //check if the Country in split is not manually changes, change it to new value in Country of Order  
                for(Opportunity opp : [
                    select
                        Id,
                        (   select
                                Country__c
                            from OpportunitySplits
                            where Country__c in :oldCountriesOfOrder )
                    from Opportunity
                    where Id in :oppIds ] )
                {
                    if(opp.OpportunitySplits != null) {
                        String newCountryOfOrder = newMap.get(opp.Id).Country_of_Order__c;
                        String oldCountryOfOrder = oldMap.get(opp.Id).Country_of_Order__c;
                        for(OpportunitySplit oppSplit : opp.OpportunitySplits) {
                            if( oppSplit.Country__c == oldCountryOfOrder ) {
                                oppSplit.Country__c = newCountryOfOrder;
                                listChildSplits.add( oppSplit );
                            }
                        }
                    }
                }
                //update split records
                if(!listChildSplits.isEmpty()) {
                    database.update( listChildSplits, false);
                }
            }
        }
    }

//US80608(rollback DE7583)  public static void createEventRecords(Set<Id> oppIds,Boolean isDelete) {
//US80608(rollback DE7583)      if(! oppIds.isEmpty()) {
//US80608(rollback DE7583)          List<Event__c> events = new list<Event__c>();
//US80608(rollback DE7583)          // only exclude opportunities which have events that have not started processing.
//US80608(rollback DE7583)          for(Opportunity opp : [
//US80608(rollback DE7583)              SELECT Id, IsDeleted
//US80608(rollback DE7583)              FROM Opportunity
//US80608(rollback DE7583)              WHERE Id IN :oppIds
//US80608(rollback DE7583)                  AND Id NOT IN (
//US80608(rollback DE7583)                      SELECT Opportunity__c
//US80608(rollback DE7583)                      FROM Event__c
//US80608(rollback DE7583)                      WHERE Processed__c = false
//US80608(rollback DE7583)                          AND Opportunity__c in :oppIds
//US80608(rollback DE7583)                          AND LastModifiedDate > :Opportunity_Split_Batchable2.maxProcessingSetting.Value__c)
//US80608(rollback DE7583)              ALL ROWS ] )
//US80608(rollback DE7583)          {
//US80608(rollback DE7583)              Event__c ev = new Event__c(OpportunityId__c = opp.Id, Processed__c = false);
//US80608(rollback DE7583)              if(opp.IsDeleted != true && ! isDelete) {
//US80608(rollback DE7583)                  ev.Opportunity__c = opp.Id;
//US80608(rollback DE7583)              }
//US80608(rollback DE7583)              events.add( ev );
//US80608(rollback DE7583)          }
//US80608(rollback DE7583)          if(!events.isEmpty()) {
//US80608(rollback DE7583)              Database.insert(events, false);
//US80608(rollback DE7583)          } 
//US80608(rollback DE7583)      }
//US80608(rollback DE7583)  }

    /**
     * Create new Event__c records on change of ownership or delete Opportunity (US67021).
     */
    public void createEventRecords() {
//US80608(rollback DE7583)      if(Opportunity_Split_Batchable2.scheduledApex == null) {
            if(isUpdate) {
                //collect all the Opportunity records with changed owner
                set<Id> setParentOppIds = new set<Id>();
                map<Id, Event__c> mapParentOppId_Event = new map<Id, Event__c>();
                list<Event__c> listNewEventRecs = new list<Event__c>();
                Event__c newEventInst = new Event__c();
                
                for(Opportunity oppInst : newMap.values()){
                    if(oppInst.CloseDate != oldMap.get(oppInst.Id).CloseDate ||
                        oppInst.StageName != oldMap.get(oppInst.Id).StageName)
                    {
                        setParentOppIds.add(oppInst.Id);
                    }
                }
                
                //fetch all the event records, if already present, for the corresponding parent opportunity
                list<Event__c> listEventRecs = new list<Event__c>([
                    SELECT Opportunity__c 
                    FROM Event__c 
                    WHERE Opportunity__c IN: setParentOppIds 
                        AND Processed__c = FALSE ] );
                
                setParentOppIds = new set<Id>();
                
                //create map opportunity id and corresponding event record 
                for(Event__c eventInst : listEventRecs){
                    mapParentOppId_Event.put(eventInst.Opportunity__c, eventInst);
                }
                
                setParentOppIds = new set<Id>();
                
                for(Opportunity oppInst : newMap.values()){
                    if((oppInst.CloseDate != oldMap.get(oppInst.Id).CloseDate ||
                        oppInst.StageName != oldMap.get(oppInst.Id).StageName) &&
                        mapParentOppId_Event.get(oppInst.Id) == NULL)
                    {
                        setParentOppIds.add(oppInst.Id);
                    }
                }
                
                //create new records in Event
                for(Id parentOppId : setParentOppIds){
                    newEventInst = new Event__c();
                    newEventInst.Opportunity__c = parentOppId;
                    listNewEventRecs.add(newEventInst);
                }
                
                Database.Insert(listNewEventRecs, FALSE); 
            }
//US80608(rollback DE7583)      }
//US80608(rollback DE7583)      else if(isUpdate||isDelete||isUndelete) {
//US80608(rollback DE7583)          //collect all the Opportunity records with changed owner
//US80608(rollback DE7583)          Set<Id> oppIds = new Set<Id>();
//US80608(rollback DE7583)          if(isDelete || isUndelete) {
//US80608(rollback DE7583)              oppIds.addAll(newMap.keySet());
//US80608(rollback DE7583)              oppIds.addAll(oldMap.keySet());
//US80608(rollback DE7583)          }
//US80608(rollback DE7583)          else {
//US80608(rollback DE7583)              for(Opportunity opp : newMap.values()) {
//US80608(rollback DE7583)                  Opportunity oldOpp = oldMap.get(opp.Id);
//US80608(rollback DE7583)                  if(oldOpp != null 
//US80608(rollback DE7583)                      && (oldOpp.OwnerId != opp.OwnerId
//US80608(rollback DE7583)                          || oldOpp.CloseDate != opp.CloseDate
//US80608(rollback DE7583)                          || oldOpp.StageName != opp.StageName ) )
//US80608(rollback DE7583)                  {
//US80608(rollback DE7583)                      oppIds.add(opp.Id);
//US80608(rollback DE7583)                  }
//US80608(rollback DE7583)              }
//US80608(rollback DE7583)          }
//US80608(rollback DE7583)          createEventRecords(oppIds,isDelete);
//US80608(rollback DE7583)      }
    }

    /**
     * Method to invoke all triggers
     */
    public static void processTrigger(Map<Id,Opportunity> xoldMap,Map<Id,Opportunity> xnewMap,Boolean isUndelete) {
        if(ThreadLock.lock(LOCK_STRING)) {
            try {
                final OpportunityTriggerAfter2 afterTrigger = new OpportunityTriggerAfter2(xoldMap,xnewMap,isUndelete);
                if(AbstractTrigger.isActive(BACKOUT_ORDER_SETTING,true)) {
                    afterTrigger.backoutOrder();
                }
                if(AbstractTrigger.isActive(INSERT_OPPORTUNITY_SNAPSHOT_SETTING,true)) {
                    afterTrigger.insertOpportunitySnapshot();
                }
                if(AbstractTrigger.isActive(COPY_POC_PRODUCTS_SETTING,true)) {
                    afterTrigger.copyProofOfConceptProducts();
                }
                if(AbstractTrigger.isActive(NOTIFY_OWNER_CHANGE_SETTING,true)) {
                    afterTrigger.notifyOwnerChange();
                }
                if(AbstractTrigger.isActive(SYNC_OPPORTUNITY_TEAM_MEMBER_CLONE_SETTING,true)) {
                    afterTrigger.syncOpportunityTeamMemberClone();
                }
                if(AbstractTrigger.isActive(SET_ENGAGEMENT_SA_SETTING,true)) {
                    afterTrigger.setEngagementSA();
                }
                if(AbstractTrigger.isActive(REQUIRE_ENGAGEMENT_SA_SETTING,true)) {
                    afterTrigger.requireEngagementSA();
                }
                if(AbstractTrigger.isActive(SYNC_POC_FIELDS_SETTING,true)) {
                    afterTrigger.syncProofOfConceptFields();
                }
                if(AbstractTrigger.isActive(LINK_SOLUTIONS_SETTING,true)) {
                    afterTrigger.linkSolutions();
                }
                if(AbstractTrigger.isActive(CREATE_EVENT_RECORDS_SETTING,true)) {
                    afterTrigger.createEventRecords();
                }
                if(AbstractTrigger.isActive(NEXT_STEP_HISTORY_SETTING,true)) {
                    afterTrigger.nextStepHistory();
                }
                if(AbstractTrigger.isActive(COUNTRY_OPP_SPLIT_AU_SETTING,true)) {
                    afterTrigger.countryOppSplitAU();
                }
                if(AbstractTrigger.isActive(UPDATE_SERVICES_ALLOCATIONS_SETTING,true)) {
                    afterTrigger.updateServicesAllocations();
                }
                if(AbstractTrigger.isActive(SUBMIT_FOR_BU_APPROVAL_SETTING,true)) {
                    afterTrigger.submitForBUApproval();
                }
                if(AbstractTrigger.isActive(LEAD_HISTORY_SETTING,true)) {
                    afterTrigger.leadHistory();
                }
                if(AbstractTrigger.isActive(SYNC_CONTRACTS_SETTING,true)) {
                    afterTrigger.syncContracts();
                }
                if(AbstractTrigger.isActive(SYNC_SHIPPING_CONTACTS_SETTING,true)) {
                    afterTrigger.syncShippingContacts();
                }
                if(AbstractTrigger.isActive(REMOVE_FINANCIAL_PARTNER_SETTING,true)) {
                    afterTrigger.removeFinancialPartner();
                }
                if(AbstractTrigger.isActive(SUBMIT_TO_ORDER_MANAGEMENT_SETTING,true)) {
                    afterTrigger.submitToOrderManagement();
                }
                AbstractTrigger.processTriggerComplete();
            }
            finally {
                ThreadLock.unlock(LOCK_STRING);
            }
        }
    }
}