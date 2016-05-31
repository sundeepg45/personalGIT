/**
 * This is a controller extension used for the Proof of Concept pages.
 *
 * @version 2014-06-27
 *
 * @author Scott Coleman <scoleman@redhat.com>
 * 2014-06-27 - Changed default Name to "POC Created From [Parent Opportunity Name]"
 * 2013-11-03 - Implemented scoping assignment approval process
 * 2013-10-16 - Added method recallPOC() to allow recall of an accepted POC
 * 2013-10-11 - Added methods isOwner() and isSAManagement()
 * 2013-10-01 - Now defaulting owner to be creator
 * 2013-07-10 - closePOC() now uses the RecordAccess.forceSave() to allow setting of Engagement End Date
 *              on locked records.
 * 2013-06-25 - Added custom action to submit for scoping assignment
 * 2013-06-17 - Merged functionality from ProofOfConceptController class into this class
 * 2013-06-13 - Created
 * Bill Riemers <briemers@redhat.com>
 * 2014-06-23 - Changed default StageName to POC
 * 2013-12-04 - Don't lock Engagement APAC POC's either (demo feedback)
 * 2013-12-03 - Accepted APAC POC's should not be edit locked.
 * 2013-11-21 - Query Super_Region__c on create
 * 2013-11-14 - Added savePoc() method to add source opportunity team members to new POC's
 * 2013-07-19 - Added getPrimaryProductField
 * 2013-07-18 - Changed product line to by dynamically based on business unit
 * 2013-07-08 - Added productLineOptions
 * 2013-07-04 - Added methods to support locking and unlocking edit
 * 2013-06-25 - Added method to close POC
 * 2013-06-24 - Set POC status on create, and only allow created from open opportunities
 */
public with sharing class Opportunity_ProofOfConceptControllerExtn {
    public static final String POC_STATUS_NEW_REQUEST = 'New Request';
    public static final String POC_STATUS_SUBMIT_FOR_SCOPING = 'Submit for Scoping Assignment';
    public static final String POC_STATUS_SUBMITTED = 'Submitted'; // submitted for approval
    public static final String POC_STATUS_ENGAGED = 'Engaged';
    public static final String POC_STATUS_ACCEPTED = 'Accepted';
    public static final String POC_STATUS_SCOPING = 'Scoping'; //this value assigned by a trigger on OpportunityTeamMember
    public static final String POC_STATUS_CLOSED = 'Closed';
    public static final String PRODUCT2_STORAGE_BUSINESS_UNITS_KEY = 'Product2.StorageBusinessUnits';

    public final ApexPages.StandardController controller;
    private final Opportunity sourceOpportunity;
    private final Opportunity proofOfConcept;
    private final List<OpportunityTeamMember> opportunityTeamMembers;
    private final List<OpportunityShare> opportunityShares;
    private transient Schema.DescribeSObjectResult describe;

    public static final String POC_ENGAGEMENT_SA_ROLE = 'Engagement SA';

    /** Lookup the POC record id. */
    // to do: Once this is the same on all environments this can be changed to constant value
    public static Id pocRecordTypeId {
        get {
            return RecordTypeLookup.getRecordTypeId('Proof of Concept','Opportunity');
        }
    }
    public Schema.FieldSetMember getPrimaryProductField() {
        Schema.FieldSetMember retval = null;
        for(Schema.FieldSetMember fsm : Schema.SObjectType.Opportunity.FieldSets.POC_Fields_General.getFields()) {
            if(fsm.getFieldPath() == 'POC_Primary_Product__c') {
                retval = fsm;
                break;
            }
        }
        return retval;
    }

    public Boolean isEngagementSA {
        get {
            return engagementSAUserIds.contains(UserInfo.getUserId());
        }
    }

    public Set<Id> engagementSAUserIds {
        get {
            if(engagementSAUserIds == null) {
                engagementSAUserIds = new Set<Id>();
                if(proofOfConcept.Id != null) {
                    List<OpportunityTeamMember> engagementSAs = [
                        select UserId
                        from OpportunityTeamMember
                        where OpportunityId = :proofOfConcept.Id
                        and TeamMemberRole = :POC_ENGAGEMENT_SA_ROLE];
                    for(OpportunityTeamMember engagementSA : engagementSAs){
                        engagementSAUserIds.add(engagementSA.UserId);
                        System.Debug('Engagement SA User Id: ' + engagementSA.UserId);
                    }
                }
            }
            return engagementSAUserIds;
        }
        private set;
    }

    public Boolean isOwner {
        get {
            return (proofOfConcept.OwnerId == userInfo.getUserId());
        }
    }

    public Boolean isSaManagement {
        get {
            return saManagementUserIds.contains(UserInfo.getUserId());
        }
    }

    public Set<Id> saManagementUserIds {
        get {
            if(saManagementUserIds == null) {
                saManagementUserIds = new Set<Id>();
                List<Group> managementGroup = [
                    SELECT Id, (SELECT Id, UserOrGroupId FROM GroupMembers)
                    FROM Group
                    WHERE DeveloperName = 'SA_Management_Groups'];
                Set<Id> regionalGroupIds = new Set<Id>();
                if(!managementGroup.isEmpty()) {
                    for(GroupMember regionalGroup : managementGroup[0].GroupMembers) {
                        regionalGroupIds.add(regionalGroup.UserOrGroupId);
                    }
                }
                List<GroupMember> managers = [
                    SELECT Id, UserOrGroupId
                    FROM GroupMember
                    WHERE GroupId IN :regionalGroupIds];
                if(!managers.isEmpty()) {
                    for(GroupMember manager : managers) {
                        saManagementUserIds.add(manager.UserOrGroupId);
                    }
                }
            }
            return saManagementUserIds;
        }
        private set;
    }

    public Opportunity_ProofOfConceptControllerExtn(ApexPages.StandardController stdController) {
        controller = stdController;
        proofOfConcept = (Opportunity)stdController.getRecord();
        opportunityTeamMembers = new List<OpportunityTeamMember>();
        opportunityShares = new List<OpportunityShare>();
        //if this is a new record...
        if(proofOfConcept.Id == null) {
            //set the record type
            proofOfConcept.RecordTypeId = pocRecordTypeId;
            proofOfConcept.POC_Status__c = POC_STATUS_NEW_REQUEST;
            proofOfConcept.StageName = 'POC';
            proofOfConcept.Probability = 0;
            proofOfConcept.OwnerId = UserInfo.getUserId();

            //see if there's an opp from which some initial values should be copied
            String sourceOppId = ApexPages.currentPage().getParameters().get('sourceOppId');
            if(sourceOppId != null && sourceOppId != '') {
                for(Opportunity opp : [
                    SELECT Id,
                        Name,
                        Account.Name,
                        AccountId,
                        Country_of_Order__c,
                        CloseDate,
                        CurrencyIsoCode,
                        Region__c,
                        SubRegion__c,
                        Super_Region__c,
                        (   select
                                OpportunityAccessLevel,
                                TeamMemberRole,
                                UserId,
                                User.IsActive
                            from OpportunityTeamMembers )
                    FROM Opportunity
                    WHERE Id = :sourceOppId and IsClosed = false
                    limit 1 ])
                {
                    sourceOpportunity =opp;
                    String pocName = 'POC Created From ' + sourceOpportunity.Name;
                    pocName = pocName.left(120);
                    proofOfConcept.Name = pocName;
                    proofOfConcept.AccountId = sourceOpportunity.AccountId;
                    proofOfConcept.CloseDate = sourceOpportunity.CloseDate;
                    proofOfConcept.Country_of_Order__c = sourceOpportunity.Country_of_Order__c;
                    proofOfConcept.CurrencyIsoCode = sourceOpportunity.CurrencyIsoCode;
                    proofOfConcept.Region__c = sourceOpportunity.Region__c;
                    proofOfConcept.SubRegion__c = sourceOpportunity.SubRegion__c;
                    proofOfConcept.Cloned_From_Opportunity__c = sourceOpportunity.Id;
                    proofOfConcept.Cloned_From_Opportunity__r = sourceOpportunity;
                    for(OpportunityTeamMember otm : opp.OpportunityTeamMembers ) {
                        if(otm.User != null && otm.User.IsActive == true) {
                            opportunityTeamMembers.add( otm.clone(false) );
                        }
                    }
                    for(OpportunityShare share : [
                        select
                            OpportunityAccessLevel,
                            UserOrGroupId
                        from OpportunityShare
                        where OpportunityId = :opp.Id ])
                    {
                        opportunityShares.add( share.clone(false) );
                    }
                }
            }
        }
    }

    /**
     * Set by calling detectRecordLock.  A true value will be return if
     * the user does not have edit access, the POC has been closed, or
     * a test update fails.  Otherwise a false value will be returned.
     *
     * @return true if the user is unable to edit the record
     */
    public Boolean isLocked {
        get {
            return (isLocked == true);
        }
        set;
    }

    /**
     * Query all the Primary_Business_Unit__c and Product_Line__c pairs
     * used by active products.
     */
    private List<AggregateResult> products {
        get {
            if(products == null) {
                products = [
                    select
                        Primary_Business_Unit__c,
                        Product_Line__c
                    from Product2
                    where Primary_Business_Unit__c != null
                        and Product_Line__c != null
                        and IsActive = true
                    group by Primary_Business_Unit__c, Product_Line__c
                    order by Primary_Business_Unit__c, Product_Line__c ];
            }
            return products;
        }
        set;
    }

    /**
     * Create a dynamic select option list of primary business unit based products queried above.
     *
     * @return the primary business unit options
     */
    public List<SelectOption> getPrimaryBusinessUnitOptions() {
        List<SelectOption> primaryBusinessUnitOptions = new List<SelectOption>{
            new SelectOption('','-- None --') };
        Boolean hasCurrent = (proofOfConcept.PrimaryBusinessUnit__c == null || proofOfConcept.PrimaryBusinessUnit__c == '');
        String currentValue = null;
        for(AggregateResult ar : products) {
            String businessUnit = (String)ar.get('Primary_Business_Unit__c');
            if(businessUnit != currentValue) {
                currentValue = businessUnit;
                primaryBusinessUnitOptions.add(
                    new SelectOption(currentValue,currentValue));
                hasCurrent = hasCurrent || (currentValue == proofOfConcept.PrimaryBusinessUnit__c);
            }
        }
        if(! hasCurrent) {
            primaryBusinessUnitOptions.add(new SelectOption(proofOfConcept.PrimaryBusinessUnit__c,proofOfConcept.PrimaryBusinessUnit__c+' (Do Not Use)',true));
        }
        return primaryBusinessUnitOptions;
    }

    /**
     * Create a dynamic select option list of product line based products queried above.
     *
     * @return the product line options
     */
    public List<SelectOption> getProductLineOptions() {
        List<SelectOption> productLineOptions = new List<SelectOption>{
            new SelectOption('','-- None --') };
        Boolean hasCurrent = (proofOfConcept.POC_Primary_Product__c == null || proofOfConcept.POC_Primary_Product__c == '');
        String currentValue = null;
        for(AggregateResult ar : products) {
            if(proofOfConcept.PrimaryBusinessUnit__c == (String)ar.get('Primary_Business_Unit__c')) {
                String productLine = (String)ar.get('Product_Line__c');
                if(productLine != currentValue) {
                    currentValue = productLine;
                    productLineOptions.add(
                        new SelectOption(currentValue,currentValue));
                    hasCurrent = hasCurrent || (currentValue == proofOfConcept.POC_Primary_Product__c);
                }
            }
        }
        if(! hasCurrent) {
            proofOfConcept.POC_Primary_Product__c = null;
        }
        return productLineOptions;
    }

    private Schema.DescribeSObjectResult getDescribe() {
        if(describe == null) {
            describe = Opportunity.sObjectType.getDescribe();
        }
        return describe;
    }

    public RecordAccess getRecordAccess() {
        RecordAccess retval = new RecordAccess(proofOfConcept,opportunityShares);
        retval.hasCreateAccess = getDescribe().isCreateable();
        retval.hasReadAccess=getDescribe().isAccessible();
        retval.hasEditAccess=getDescribe().isUpdateable();
        retval.hasDeleteAccess=getDescribe().isDeletable();
        if(proofOfConcept != null && proofOfConcept.Id != null) {
            for(UserRecordAccess a : [
                SELECT RecordId,
                    HasReadAccess,
                    HasEditAccess,
                    HasDeleteAccess
                FROM UserRecordAccess
                WHERE UserId = :UserInfo.getUserId()
                    AND RecordId = :proofOfConcept.Id] )
            {
                retval.hasReadAccess = a.HasReadAccess;
                retval.hasEditAccess = a.HasEditAccess;
                retval.hasDeleteAccess = a.HasDeleteAccess;
            }
        }
        return retval;
    }

    /**
     * Called to save the POC along with the OpportunityTeamMembers if insert.
     */
    public PageReference savePOC() {
        PageReference retval = null;
        Savepoint sp = null;
        try {
            Boolean isInsert = (proofOfConcept.Id == null);
            sp = Database.setSavepoint();          
            if(proofOfConcept.Engagement_SA__c!=null && proofOfConcept.Super_region__c=='APAC'){
            proofOfConcept.POC_Status__c = POC_STATUS_ACCEPTED;
            }
            upsert proofOfConcept;
            if(isInsert) {
                for(OpportunityTeamMember otm : opportunityTeamMembers) {
                    otm.OpportunityId = proofOfConcept.Id;
                }
                insert opportunityTeamMembers;
                for(OpportunityShare share : opportunityShares) {
                    share.OpportunityId = proofOfConcept.Id;
                }
                RecordAccess recordAccess = getRecordAccess();
                recordAccess.saveShares();
            }           
            retval = new PageReference('/'+proofOfConcept.Id);
            retval.setRedirect(true);
            sp = null;
        }
        catch(Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,e.getMessage()));
        }
        finally {
            if(sp != null) {
                Database.rollback(sp);
            }
        }
        return retval;
    }

    /**
     * Called to submit POC for scoping (business process step #5).
     */
    public PageReference submitForScoping() {
        PageReference retval = null;
        try {
            Approval.ProcessSubmitRequest submitRequest = new Approval.ProcessSubmitRequest();
            submitRequest.setObjectId(proofOfConcept.id);
            Approval.ProcessResult result = Approval.process(submitRequest);
            retval = controller.view();
            retval.setRedirect(true);
        }
        catch(Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,e.getMessage()));
        }
        detectRecordLock();
        return retval;
    }

    /**
     * Called to submit POC for approval (business process step #8A).
     */
    public PageReference submitPOC() {
        PageReference retval = null;
        try {
            Approval.ProcessSubmitRequest submitRequest = new Approval.ProcessSubmitRequest();
            submitRequest.setObjectId(proofOfConcept.id);
            Approval.ProcessResult result = Approval.process(submitRequest);
            retval = controller.view();
            retval.setRedirect(true);
        }
        catch(Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,e.getMessage()));
        }
        detectRecordLock();
        return retval;
    }

    /**
     * Called to recall accepted POC back to scoping. Requires that "Proof of Concept Un-approval" approval
     *   process exists and is active.
     */
    public PageReference recallPOC() {
        PageReference retval = null;
        if(getIsPOCAccepted()) {
            try {
                Approval.ProcessSubmitRequest submitRequest = new Approval.ProcessSubmitRequest();
                submitRequest.setObjectId(proofOfConcept.id);
                submitRequest.setNextApproverIds(new Id[] {UserInfo.getUserId()});
                // submit the POC into an approval process with the sole purpose of unlocking the record
                //  and setting the status back to Scoping
                Approval.ProcessResult result = Approval.process(submitRequest);
                // get the work item Id
                List<Id> workItemIds = result.getNewWorkitemIds();
                // create a ProcessWorkitemRequest
                Approval.ProcessWorkitemRequest approveRequest = new Approval.ProcessWorkitemRequest();
                approveRequest.setComments('Successfully recalled');
                approveRequest.setAction('Approve');
                approveRequest.setWorkitemId(workItemIds[0]);
                // complete the approval
                Approval.ProcessResult result2 =  Approval.process(approveRequest);
                retval = controller.view();
                retval.setRedirect(true);
            }
            catch(Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,e.getMessage()));
            }
            detectRecordLock();
        }
        return retval;
    }

    /**
     * Called to close the POC.
     */
    public PageReference closePOC() {
        PageReference retval = null;
        try {
            proofOfConcept.POC_Status__c = POC_STATUS_CLOSED;
            RecordAccess recordAccess = getRecordAccess();
            retval = recordAccess.forceSave();
            isLocked = true;
        }
        catch(Exception ex) {
            ApexPages.addMessages(ex);
        }
        return retval;
    }

    public Boolean getIsPOCNewRequest() {
        return proofOfConcept.POC_Status__c == POC_STATUS_NEW_REQUEST || proofOfConcept.POC_Status__c == 'Defined';
    }

    public Boolean getIsPOCSubmitForScoping() {
        return proofOfConcept.POC_Status__c == POC_STATUS_SUBMIT_FOR_SCOPING;
    }

    public Boolean getIsPOCScoping() {
        return proofOfConcept.POC_Status__c == POC_STATUS_SCOPING;
    }

    public Boolean getIsPOCClosed() {
        return proofOfConcept.POC_Status__c == POC_STATUS_CLOSED;
    }

    public Boolean getIsPOCSubmitted() {
        return proofOfConcept.POC_Status__c == POC_STATUS_SUBMITTED;
    }

    public Boolean getIsPOCAccepted() {
        return proofOfConcept.POC_Status__c == POC_STATUS_ACCEPTED;
    }

    public Boolean getIsPOCEngaged() {
        return proofOfConcept.POC_Status__c == POC_STATUS_ENGAGED;
    }

    /**
     * Check if the storage section is required.
     *
     * return true if a storage business unit has been selected
     */
    public Boolean getIsStorageBusinessUnit() {
        Boolean retval = false;
        String bu = proofOfConcept.PrimaryBusinessUnit__c;
        if(bu != null && bu != '') {
            bu = bu.trim();
            StringSetting__c ss = StringSetting__c.getInstance(PRODUCT2_STORAGE_BUSINESS_UNITS_KEY);
            if(ss == null) {
                ss = new StringSetting__c(name=PRODUCT2_STORAGE_BUSINESS_UNITS_KEY,Value__c='Storage');
            }
            String s = ss.Value__c;
            if(s != null && s != '') {
                for(String value : ss.Value__c.split(',')) {
                    if ( bu == value.trim() ) {
                        retval = true;
                        break;
                    }
                }
            }
        }
        return retval;
    }

    /**
     * If a record is not in a accepted, closed, accepted, or engaged status then
     * test the lock status by attempting to save the record.
     */
    public PageReference detectRecordLock() {
        Savepoint sp = null;
        try {
            isLocked = (proofOfConcept != null && proofOfConcept.Id != null);
            if(isLocked && ! (getIsPOCClosed() || ((getIsPOCAccepted() || getIsPOCEngaged() ) && proofOfConcept.Super_Region__c != 'APAC')) && getRecordAccess().hasEditAccess) {
                sp = Database.setSavepoint();
                update proofOfConcept;
                isLocked = false;
            }
        }
        catch(Exception ex) {
            isLocked = true;
        }
        finally {
            if(sp != null) {
                Database.rollback(sp);
            }
        }
        return null;
    }

    /**
     * Class to report record access, and allow saving even when approval locked.
     */
    public without sharing class RecordAccess {
        private Opportunity proofOfConcept;
        private List<OpportunityShare> opportunityShares;
        private RecordAccess(Opportunity proofOfConcept,List<OpportunityShare> opportunityShares) {
            this.proofOfConcept = proofOfConcept;
            this.opportunityShares = opportunityShares;
        }
        public Boolean hasCreateAccess { get; set; }
        public Boolean hasReadAccess { get; set; }
        public Boolean hasEditAccess { get; set; }
        public Boolean hasDeleteAccess { get; set; }
        public PageReference forceSave() {
            PageReference retval = null;
            try {
                update proofOfConcept;
                retval = new PageReference('/'+proofOfConcept.Id);
                retval.setRedirect(true);
            }
            catch(Exception ex) {
                ApexPages.addMessages(ex);
            }
            return retval;
        }
        public void saveShares() {
            Database.insert(opportunityShares,false);
        }
    }

}