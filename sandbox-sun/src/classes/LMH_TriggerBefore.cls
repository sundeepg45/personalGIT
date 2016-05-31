/**
 * This class replaces all before insert and before update Lead Management History triggers.  The
 * processTrigger method is invoked by the LeadManagementHistory_LFR trigger and in turn invokes
 * all the methods of this class.  This gives us a way to control the order in
 * which the code logic is invoked, as well as allowing other class features such
 * as shared data, constant values, and rigorious test coverage.
 * <p>
 * The Trigger object should never be directly referenced inside this class, as
 * that would make it impossible to substituting values inside test methods.
 * </p>
 *
 * @author Sundeep Godishala <Sgodisha@redhat.com>
 * @version 2015-12-16
 * 2015-12-16 - created
 */
public without sharing class LMH_TriggerBefore extends AbstractTrigger {

  public static final String ASSIGN_VALUES_SETTING='LMH.assignLMHValues';

  private final Map<Id,LeadManagementHistory__c> oldMap = new Map<Id,LeadManagementHistory__c>();
  private final List<LeadManagementHistory__c> newList = new List<LeadManagementHistory__c>();
  
  public LMH_TriggerBefore(Map<Id,LeadManagementHistory__c> xoldMap,List<LeadManagementHistory__c> xnewList) {
    super(xoldMap,xnewList,null);
    if(xoldMap != null) {
      oldMap.putAll(xoldMap);
    }
    if(xnewList != null) {
      newList.addAll(xnewList);
    }
  }
    
    public void assignLMHValues(){
     Set<String> leadIds = new Set<String>();
    for(LeadManagementHistory__c lmh : newList) {
        if(lmh.LeadId__c == null) {
            lmh.LeadId__c = lmh.Lead__c;
        }
        if(lmh.LFR__c == null && lmh.LeadId__c != null) {
            leadIds.add(lmh.LeadId__c);
        }
        lmh.Lead_Dev_User__c = currentUser.Is_Marketing_User__c;
        lmh.User_Profile_Name__c = currentUser.profile.Name;
    }
    if(! leadIds.isEmpty()) {
        Map<Id,Id> lfrIdMap = new Map<Id,Id>();
        for(AggregateResult ar : [
            select LeadId__c, max(Id) maxId
            from LeadForReporting__c
            where LeadId__c in :leadIds
            group by LeadId__c ])
        {
            lfrIdMap.put((Id)ar.get('LeadId__c'),(Id)ar.get('maxId'));
        }
        for(LeadManagementHistory__c lmh : newList) {
            if(lmh.LFR__c == null && lmh.LeadId__c != null) {
                lmh.LFR__c = lfrIdMap.get(lmh.LeadId__c);
            }
        }
    }   
    }
    
    public static void processTrigger(Map<Id,LeadManagementHistory__c> xoldMap,List<LeadManagementHistory__c> xnewList) {
       final LMH_TriggerBefore beforeTrigger = new LMH_TriggerBefore(xoldMap,xnewList);
       if(AbstractTrigger.isActive(ASSIGN_VALUES_SETTING,true)){
        beforeTrigger.assignLMHValues();      
     }
    }
}