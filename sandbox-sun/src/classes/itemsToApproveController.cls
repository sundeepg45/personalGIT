public class itemsToApproveController{

    public List<String> uIdsToCheck = new List<String>();
    public List<ProcessInstanceWorkitem> itemsToApprove = new List<ProcessInstanceWorkitem>();
    public List<Partner_Onboarding_Registration__c> leadItemList = new List<Partner_Onboarding_Registration__c>();
    public List<GroupMember> grps = new List<GroupMember>();

    private static Map<String, Schema.SObjectType> allObjNames;
    private static Map<String, String> allObjKeysMap;
    private static Set<String> allObjKeysSet;
    private static List<String> prefixes;
    private static List<String> viewOnlyList;
    private static StringSetting__c viewOnlySetting;

    public List<workItemList> itemListTest {get;set;}
    public List<workItemList> headerRow {get;set;}
    public List<ProcessInstanceWorkitem> approveRejectList {get;set;}
    public List<ProcessInstanceWorkitem> reassignList {get;set;}

    static {

        allObjNames = Schema.getGlobalDescribe();
        allObjKeysMap = new Map<String, String>{};
        allObjKeysSet = allObjNames.keySet();

        for (String obj : allObjKeysSet) {
            Schema.DescribeSObjectResult objDesc = allObjNames.get(obj).getDescribe();
            allObjKeysMap.put(objDesc.getKeyPrefix(), objDesc.getLabel());
        }

        viewOnlyList = new List<String>{};
        viewOnlySetting = [SELECT Value__c FROM StringSetting__c WHERE Name = 'ObjectPrefix'];

        if (viewOnlySetting.Value__c.contains(',')) {
            for (String objs : viewOnlySetting.Value__c.split(',')) {
        	viewOnlyList.add(objs);
        	}
        } else {
            viewOnlyList.add(viewOnlySetting.Value__c);
        }

    }

    public List<workItemList> getItemList() {

        if (itemsToApprove.isEmpty()) {

            itemListTest = new List<workItemList>();
            leadItemList = new List<Partner_Onboarding_Registration__c>();

            grps = [SELECT GroupId
                    FROM GroupMember
                    WHERE UserOrGroupId = : UserInfo.getUserId()];

            uIdsToCheck.add(String.valueOf(UserInfo.getUserId()));

            for (Integer i = 0; grps.size() > i; i++) {
                uIdsToCheck.add(String.valueOf(grps[i].GroupId));
            }

            itemsToApprove = [SELECT Id, ActorId, CreatedDate, CreatedById, CreatedBy.Name, ProcessInstance.TargetObject.Name, ProcessInstance.TargetObjectId
                              FROM ProcessInstanceWorkitem
                              WHERE ActorId in : uIdsToCheck
                              ORDER BY CreatedDate DESC];

            List<Id> leadId = new List<Id>();
            for (ProcessInstanceWorkitem piwi : itemsToApprove) {
            	leadId.add(piwi.ProcessInstance.TargetObjectId);
            }

            if (leadId.size() > 0) {
            	leadItemList = [SELECT Id, Name, Company__c FROM Partner_Onboarding_Registration__c WHERE Id in : leadId];
            }

            for (ProcessInstanceWorkitem piwi : itemsToApprove) {
                String p = piwi.ProcessInstance.TargetObjectId;
                String leadName = null;
                p = p.substring(0,3);

                for (Partner_Onboarding_Registration__c l : leadItemList) {
                    if (l.Id == piwi.ProcessInstance.TargetObjectId) {
                        //leadName = l.Name + ', ' + l.Company__c;
                        leadName = l.Company__c;
                    }
                }

                itemListTest.add(new workItemList(piwi, p, leadName));
            }
        }

        return itemListTest;
    }

    public class workItemList {

        public ProcessInstanceWorkitem p {get;set;}
        public String objName {get;set;}
        public String leadObjName {get;set;}
        public Boolean viewOnly {get;set;}
        public Boolean selected {get;set;}

        public workItemList(ProcessInstanceWorkitem p, String prefix, String leadName) {
            this.p = p;
            leadObjName = leadName;
            objName = String.valueOf(allObjKeysMap.get(prefix));
            viewOnly = false;
            selected = false;

            for (String objPrefix : viewOnlyList) {

                if (prefix == objPrefix) {
                	viewOnly = true;
                }
            }
        }
    }
}