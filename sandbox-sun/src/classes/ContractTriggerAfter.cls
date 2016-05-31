/**
 * This class replaces all after insert and after update contract triggers.  The
 * processTrigger method is invoked by the Contract_After trigger and in turn invokes
 * all the methods of this class.  This gives us a way to control the order in
 * which the code logic is invoked, as well as allowing other class features such
 * as shared data, constant values, and rigorious test coverage.
 * <p>
 * The Trigger object should never be directly referenced inside this class, as
 * that would make it impossible to substituting values inside test methods.
 * </p>
 *
 * @version 2016-03-30
 * @author Scott Coleman <scoleman@redhat.com>
 * @since 2014-01-16 - added resubmission to bid desk of contracts rejected by the contract owner (US42446)
 * @since 2013-04-15 - created
 * @author Sundeep Godishala <sgodisha@redhat.com>
 * @since 2016-02-18 - Modified Method ContractOwnerNotifications to allow to set Bid desk fields while creating the contract (DE9970)
 * @since 2015-12-22 - Notifications should be sent whenever a contract is picked up by Bid Desk User (US78666)
 * @author Bill C Riemers <briemers@redhat.com>
 * @since 2016-03-03 - Added Process Trigger Complete call.
 * @since 2016-03-01 - Cleaned up comments and fix a few formatting errors
 */
public without sharing class ContractTriggerAfter extends AbstractTrigger {
    /** BooleanSetting__c key to enable contractOwnerNotification */
    public static final String CONTRACT_OWNER_NOTIFY = 'Contract_After.contractOwnerNotify';
    /** BooleanSetting__c key to enable statusChangeNotify */
    public static final String STAGE_CHANGE_NOTIFY = 'Contract_After.stageChangeNotify';
    /** BooleanSetting__c key to enable sendBackToBidDesk */
    public static final String SEND_BACK_TO_BID_DESK = 'Contract_After.sendBackToBidDesk';

    private final Map<Id,Contract> oldMap = new Map<Id,Contract>();
    private final Map<Id,Contract> newMap = new Map<Id,Contract>();

    private Set<Id> oppIds {
        get {
            if(oppIds == null) {
                oppIds = new Set<Id>();
            }
            return oppIds;
        }
        set;
    }

    /**
     * Map of oppotunity members related to the opportunity ids select.
     */
    public Map<Id,List<OpportunityTeamMember>> oppTeamMemberMap {
        get {
            if(oppIds != null && oppTeamMemberMap == null) {
                List<OpportunityTeamMember> teamMembers = [
                    select OpportunityId, UserId
                    from OpportunityTeamMember
                    where OpportunityId in :oppIds ];
                List<Opportunity> opportunities = [ 
                    select OwnerId
                    from Opportunity
                    where Id in :oppIds
                    and OwnerId != null ];
                oppTeamMemberMap = new Map<Id,List<OpportunityTeamMember>>();
                for(OpportunityTeamMember teamMember : teamMembers) {
                    if(oppTeamMemberMap.keySet().contains(teamMember.OpportunityId)) {
                        oppTeamMemberMap.get(teamMember.OpportunityId).add(teamMember);
                    }
                    else {
                        oppTeamMemberMap.put(teamMember.OpportunityId, new List<OpportunityTeamMember>{teamMember});
                    }
                }
                for(Opportunity opportunity : opportunities) {
                    OpportunityTeamMember teamMember = new OpportunityTeamMember(OpportunityId=opportunity.Id,UserId=opportunity.OwnerId);
                    if(oppTeamMemberMap.keySet().contains(opportunity.Id)) {
                        oppTeamMemberMap.get(opportunity.Id).add(teamMember);
                    }
                    else {
                        oppTeamMemberMap.put(opportunity.Id, new List<OpportunityTeamMember>{teamMember});
                    }                  
                }
            }
            return oppTeamMemberMap;
        }
        set;
    }

    private Set<Id> contractIds {
        get {
            if(contractIds == null) {
                contractIds = new Set<Id>();
            }
            return contractIds;
        }
        set;
    }

    /**
     * This our standard constructor for an after trigger.
     * @param xoldMap the mapping of old values
     * @param xnewMap the mapping of new values
     */
    public ContractTriggerAfter(Map<Id,Contract> xoldMap,Map<Id,Contract> xnewMap) {
        super(xoldMap,null,xnewMap);
        if(xoldMap != null) {
            oldMap.putAll(xoldMap);
        }
        if(xnewMap != null) {
            newMap.putAll(xnewMap);
        }
    }

    /** 
     * Email template used for notification e-mail.
     */
    public static EmailTemplate BID_DESK_NOTIFICATION_EMAIL_TEMPLATE {
        get {
            if(BID_DESK_NOTIFICATION_EMAIL_TEMPLATE == null) {
                for(EmailTemplate et : [
                    select Id, Name, Body, HtmlValue, Subject, Description
                    from EmailTemplate
                    where
                        Folder.Type = 'Email'
                        and Folder.Name = 'Contracts Notifications' 
                        and DeveloperName = 'BidDeskNotificationsContract'
                        and IsActive = true
                    order by LastModifiedDate desc
                    limit 1] )
            {
                BID_DESK_NOTIFICATION_EMAIL_TEMPLATE = et;
            }
        }
        return BID_DESK_NOTIFICATION_EMAIL_TEMPLATE;
        }
        set;
    }

    /** @todo: document this */
    /* Trigger method contractOwnerNotification() is triggering recursively due to other related object triggers, 
        hence IsContractOwnerNotificationTriggered is used 
        */
    public static Boolean IsContractOwnerNotificationTriggered = true;  

    /**
     * Sends notifications to Contract owner, Account team and Opportunity team whenever the contract is assigned to bid desk user
     */ 
    public void contractOwnerNotify(){
        system.debug('value @@@' +isInsert);
        Contract oldContract;
        //List<string> ToUsersEmailIds = new List<String>(); 
        List<string> ccUsersEmailIds = new List<String>(); 
        Set<Id> usrIds = new Set<Id>(); 
        Set<Id> OppIds = new Set<Id>();
        if(ContractTriggerAfter.IsContractOwnerNotificationTriggered) {
            List<Messaging.SingleEmailMessage> allMails = new List<Messaging.SingleEmailMessage>();
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            for(Contract newContract : newMap.values()) {
                oldContract = oldMap.get(newContract.Id);
                if((oldContract!=null 
                && newContract.BA_BRC_Owner__c!=null 
                && newContract.BA_Bid_Desk_Owner_2__c==null 
                && newContract.BA_BRC_Owner__c!=oldContract.BA_BRC_Owner__c) 
                    || (oldContract!=null 
                    && newContract.BA_Bid_Desk_Owner_2__c!=null 
                    && newContract.BA_BRC_Owner__c==null  
                    && newContract.BA_Bid_Desk_Owner_2__c!=oldContract.BA_Bid_Desk_Owner_2__c) 
                    || (oldContract==null 
                    && newContract.BA_BRC_Owner__c!=null) 
                    || (oldContract==null 
                    && newContract.BA_Bid_Desk_Owner_2__c!=null))
                {
                   
                    //accntIds.add(newContract.AccountId);
                    if(newContract.Opportunity__c!=null) {
                        OppIds.add(newContract.Opportunity__c);
                    }
                    
                    //usrIds.add(newContract.ownerId);
                    if(newContract.BA_BRC_Owner__c!=null) {
                        usrIds.add(newContract.BA_BRC_Owner__c);
                    }
                    if(newContract.BA_Bid_Desk_Owner_2__c!=null) {
                        usrIds.add(newContract.BA_Bid_Desk_Owner_2__c);
                    }
                }
            }
            Map<Id,Opportunity> opportunitMap = new Map<Id,Opportunity>([ select Id, OwnerId  from Opportunity where OwnerId != null And Id IN:oppIds]);
            for(Contract newContract : newMap.values()) {
                 if(newContract.Opportunity__c!=null && opportunitMap!=null && opportunitMap.get(newContract.Opportunity__c)!=null){
                            usrIds.add(opportunitMap.get(newContract.Opportunity__c).OwnerId);
                 }
            }
            
            Map<Id,User> cntrctUserMap = new Map<Id,User>([select id, name, Email from User where Id IN:usrIds AND isActive = true]);
            for(Contract newContract : newMap.values()) {
                if((oldContract!=null 
                && newContract.BA_BRC_Owner__c!=null 
                && newContract.BA_Bid_Desk_Owner_2__c==null 
                && newContract.BA_BRC_Owner__c!=oldContract.BA_BRC_Owner__c) 
                    || (oldContract!=null 
                    && newContract.BA_Bid_Desk_Owner_2__c!=null 
                    && newContract.BA_BRC_Owner__c==null  
                    && newContract.BA_Bid_Desk_Owner_2__c!=oldContract.BA_Bid_Desk_Owner_2__c) 
                    || (oldContract==null 
                    && newContract.BA_BRC_Owner__c!=null) 
                    || (oldContract==null 
                    && newContract.BA_Bid_Desk_Owner_2__c!=null))
                {
                    // if(newContract.OwnerId!=null && cntrctUserMap!=null && cntrctUserMap.get(newContract.OwnerId)!=null){
                    //  ToUsersEmailIds.add(cntrctUserMap.get(newContract.OwnerId).Email); 
                    //   mail.setToAddresses(ToUsersEmailIds);
                    // }
                    if(newContract.OwnerId!=null 
                    && cntrctUserMap.containsKey(newContract.OwnerId)) cntrctUserMap.remove(cntrctUserMap.get(newContract.OwnerId).Id);
                        for(User usr:cntrctUserMap.Values()){
                            ccUsersEmailIds.add(usr.Email);
                        }
                    mail.setccAddresses(ccUsersEmailIds);
                    mail.setTemplateId(BID_DESK_NOTIFICATION_EMAIL_TEMPLATE.Id);
                    mail.setTargetObjectId(newContract.OwnerId);
                    mail.setSaveAsActivity(false);
                    mail.setWhatId(newContract.Id);
                    // mail.setSubject(BID_DESK_NOTIFICATION_EMAIL_TEMPLATE.Subject);
                    // mail.setPlainTextBody(BID_DESK_NOTIFICATION_EMAIL_TEMPLATE.Body); 
                    // Use Organization Wide Address  
                    for(OrgWideEmailAddress owa : [select id, Address, DisplayName from OrgWideEmailAddress]) {
                        if(owa.Address.contains('no-reply-sfa@redhat.com')) {
                            mail.setOrgWideEmailAddressId(owa.id);
                        }
                    }
                }
                allMails.add(mail);
            }
            if(!allMails.isEmpty() && ! ccUsersEmailIds.isEmpty()) {
                System.Debug('Size @@'+ccUsersEmailIds.size());
                Messaging.sendEmail(allMails);
            }
            ContractTriggerAfter.IsContractOwnerNotificationTriggered=false;
        }
    }

    /**
     * Trigger method to notify users when there is a stage change.
     */ 
    public void stageChangeNotify() {
        Contract oldContract;
        for(Contract newContract : newMap.values()) {
            oldContract = oldMap.get(newContract.Id);
            //only add opportunities to the set if a stage change notification is necessary
            String oldStage = '';
            String newStage = '';
            String oldStatus = '';
            String newStatus = '';
            if(oldContract != null) {
                if(oldContract.Stage__c != null) {
                    oldStage = oldContract.Stage__c;
                }
                if(oldContract.Status != null) {
                    oldStatus = oldContract.Status;
                }
            }
            if(newContract.Stage__c != null) {
                newStage = newContract.Stage__c;
            }
            if(newContract.Status != null) {
                newStatus = newContract.Status;
            }          
            if(newContract.Opportunity__c != null && (isInsert || (isUpdate && (oldStage != newStage || oldStatus != newStatus)))) {
                contractIds.add(newContract.Id);
                oppIds.add(newContract.Opportunity__c);
            }
        }
        if(! oppIds.isEmpty()) {
            for(Contract newContract : newMap.values()) {
                if(newContract.Opportunity__c != null) {
                    oldContract = oldMap.get(newContract.Id);
                    String oldStage = '';
                    String newStage = '';
                    String oldStatus = '';
                    String newStatus = '';
                    if(oldContract != null) {
                        if(oldContract.Stage__c != null) {
                            oldStage = oldContract.Stage__c;
                        }
                        if(oldContract.Status != null) {
                            oldStatus = oldContract.Status;
                        }
                    }
                    if(newContract.Stage__c != null) {
                        newStage = newContract.Stage__c;
                    }
                    if(newContract.Status != null) {
                        newStatus = newContract.Status;
                    }
                    //build notification message
                    String message;
                    if(isInsert) {
                        message = 'Contract ' + newContract.ContractNumber + ' created with Stage ' + newStage + ' and Status ' + newStatus + '.';
                    }
                    else if(isUpdate) {
                        if(oldStage != newStage) {
                            message = 'Contract ' + newContract.ContractNumber + ' updated. Stage changed from ' + oldStage + ' to ' + newStage + '.';
                        }
                        if(oldStatus != newStatus) {
                            if(message == null) {
                                message = 'Contract ' + newContract.ContractNumber + ' updated.';
                            }
                            message = message + ' Status changed from ' + oldStatus + ' to ' + newStatus + '.';
                        }
                    }
                    if(message != null && message.length() > 0) {
                        message = message + ' ' + System.Url.getSalesforceBaseURL().toExternalForm() + '/' + newContract.Id;
                    }
                    //if there is a message, post it to the opp's chatter feed
                    if(message != null && message.length() > 0) {
                        //if there are sales team members that should be notified, add them as mentions on the chatter post
                       if(oppTeamMemberMap.keySet().contains(newContract.Opportunity__c)) {
                            Set<Id> userIds = new Set<Id>();
                            for(OpportunityTeamMember teamMember : oppTeamMemberMap.get(newContract.Opportunity__c)) {
//US86623                                userIds.add(teamMember.UserId);
                           }
                            //to add mentions, we must call a future method because the chatter util class uses a callout
                            if(!System.isFuture() && !System.isBatch()) {
                                postChatterMessage(newContract.Opportunity__c, message, userIds, UserInfo.getSessionId());
                            }
                        }
                        else {
                            //if there are no mentions we can call the chatter util class directly
                            ChatterUtil.postMessage(newContract.Opportunity__c, message);
                        }
                    }
                }
            }
        }
    }

    @future(callout=true)
    private static void postChatterMessage(Id oppId, String message, Set<Id> mentionIds, String sessionId) {
        List<User> users = new List<User>();
        for(Id userId : mentionIds) {
            users.add(new User(Id = userId));
        }
        ChatterUtil.postMessage(oppId, message, users, sessionId);
    }

    /**
     * Looks for a transition of SendBackToBidDeck__c from false to true. If found,
     * automatically submits the contract for approval.
     */
    public void sendBackToBidDesk() {
        if(isUpdate) {
            List<Contract> contractsToSubmit = new List<Contract>();
            for(Contract contract : oldMap.values()) {
                if(newMap.containsKey(contract.Id)) {
                    if(!contract.SendBackToBidDesk__c && newMap.get(contract.Id).SendBackToBidDesk__c) {
                        contractsToSubmit.add(contract);
                    }
                }
            }

            if(contractsToSubmit.size() > 5) {
                for(Contract contract : contractsToSubmit) {
                    contract.addError('Unable to send more than 5 contracts back to the bid desk in a single batch. Please try again.');
                }
            }
            else {
                for(Contract contract : contractsToSubmit) {
                    try {
                        if(!Test.isRunningTest() && !System.isFuture() && !System.isBatch()) {
                            submitContract(contract.Id);
                        }
                    }
                    catch(Exception e) {
                        contract.addError(e.getMessage());
                    }
                }
            }
        }
    }

    /**
     * Submits a contract for approval. Marked future to avoid errors associated with
     * submission of a contract that is already in the approval process.
     * @param contractId
     */
    @future
    @TestVisible
    private static void submitContract(Id contractId) {
        Approval.ProcessSubmitRequest submitRequest = new Approval.ProcessSubmitRequest();
        submitRequest.setObjectId(contractId);
        submitRequest.setComments('[SYSTEM] Automatically submitted back to Bid Desk after Contract Owner rejection.');
        Approval.ProcessResult result = Approval.process(submitRequest);
    }

    /**
     * This method is called from the Contract_After trigger to invoke all the methods
     * of this class, to obsolete the need for individual after triggers.  The primary
     * reason to place all the triggers in a class is so we control the order in which
     * the triggers are invoked.
     *
     * @param xoldMap the immutable map of previous Contract objects as in Trigger.oldMap.
     * @param xnewMap the immutable map of new Contract objects as in Trigger.newMAp
     */
    public static void processTrigger(Map<Id,Contract> xoldMap,Map<Id,Contract> xnewMap) {
        try {
            final ContractTriggerAfter afterTrigger = new ContractTriggerAfter(xoldMap,xnewMap);
            if(AbstractTrigger.isActive(STAGE_CHANGE_NOTIFY,true)) {
                afterTrigger.stageChangeNotify();
            }
            if(AbstractTrigger.isActive(SEND_BACK_TO_BID_DESK,true)) {
                afterTrigger.sendBackToBidDesk();
            } 
            if(AbstractTrigger.isActive(CONTRACT_OWNER_NOTIFY,true)) {
                afterTrigger.contractOwnerNotify();
            }
        }
        finally {
            AbstractTrigger.processTriggerComplete();
        }
    }
}