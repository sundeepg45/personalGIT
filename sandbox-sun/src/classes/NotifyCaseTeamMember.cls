/*
Name        : NotifyCaseTeamMember
Author      : Nitesh Dokania
Reason      : Sends notification whenever a new case team member is added to a case. 
Created Date:  

*/

global class NotifyCaseTeamMember implements Database.Batchable<sObject>, Database.Stateful{

    /* Member Variables */ 
    public String query;
    datetime now = null;
    public DateTimeSetting__c myCS = null;
        
    /* Method for querying Team Members  - on basis of last batch run date and created date */    
    global database.querylocator start(Database.BatchableContext BC){

        System.debug('Inside Batch');
        DateTime lastRunCSDateTime = null;
        myCS = DateTimeSetting__c.getInstance('NotifyTeamMember');
        now = datetime.now();
        String nowDateTimeStr = now.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'','GMT');
        
        if(myCS!=null){
        
            lastRunCSDateTime = myCS.Value__c;
            String lastRunDateTimeStr = lastRunCSDateTime.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'','GMT');
            
            if ((query==null) || (query=='')) 
                query='Select c.ParentId, c.MemberId, c.CreatedDate, c.CreatedById From CaseTeamMember c where ';
                query += 'c.CreatedDate >= '+ lastRunDateTimeStr + ' and c.CreatedDate <= '+ nowDateTimeStr +' ';
                return Database.getQueryLocator(query);
            
        }
        else{
            return null;
        }
        
    }

    /* Start Batch 
    /* Start Method for sending email notification to notify new case team members.  */ 
    global void execute(Database.BatchableContext BC, List<sObject> scope)
    {
        List<CaseTeamMember> caseTeamMemLst = scope;
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
              
        Map<String,ID> memberCaseMap = new  Map<String,ID>();
        Map<String,ID> memberCreatedMap = new  Map<String,ID>();
        Map<String,ID> memberIdMap = new  Map<String,ID>();
        List<CaseRecordType__c> customSettingObj  = null ;
        Set<Id> recordTypeIdSet = new Set<Id>();
        OrgWideEmailAddress orgEmail = new OrgWideEmailAddress();
        
        customSettingObj  = CaseRecordType__c.getall().values();      
        for(CaseRecordType__c recTypeId : customSettingObj)
        {
            recordTypeIdSet.add(recTypeId.RecordTypeId__c);
        }   
        
        for(CaseTeamMember teamMem : caseTeamMemLst)
        {
            memberCaseMap.put(teamMem.MemberId + ' ' + teamMem.ParentId,teamMem.ParentId);
            memberCreatedMap.put(teamMem.MemberId + ' ' + teamMem.ParentId,teamMem.CreatedById);
            memberIdMap.put(teamMem.MemberId + ' ' + teamMem.ParentId,teamMem.MemberId);
        }
        
        Map<ID,Case> caseMap = new  Map<ID,Case>([Select Id, CaseNumber, RecordTypeId, Subject, Priority, Region__c, Type, Description from Case where id in : memberCaseMap.values()]);
        
        orgEmail = [Select o.Id, o.DisplayName, o.Address From OrgWideEmailAddress o where o.Address = 'no-reply-sfa@redhat.com'];
        
        List<User> usrEmail = new List<User>();
        
        usrEmail = [Select id, Email, Profile.Name, IsPortalEnabled from User where Id in : memberIdMap.values()];
        
        for(Case cse : caseMap.values())
        {
            for(User usr : usrEmail)
            {
                if(caseMap.get(memberCaseMap.get(usr.Id + ' ' + cse.id)) != null && memberCreatedMap.get(usr.Id + ' ' + cse.id) != usr.Id && !usr.Profile.Name.contains('Partner') && usr.IsPortalEnabled != true && recordTypeIdSet.contains(cse.RecordTypeId))
                {
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();  
                    mail.setOrgWideEmailAddressId(orgEmail.Id);
                    String[] toAddresses = new String[] { usr.email};
                    mail.setToAddresses(toAddresses);
                    String body;
                    if(caseMap.get(memberCaseMap.get(usr.Id + ' ' + cse.id)).Region__c != null)
                    {
                        mail.setSubject('You\'ve been added to the case team for ('+caseMap.get(memberCaseMap.get(usr.Id + ' ' + cse.id)).Region__c+') Case # '+caseMap.get(memberCaseMap.get(usr.Id + ' ' + cse.id)).CaseNumber);                    
                        body= '*** NEW CASE TEAM MEMBER NOTIFICATION ***'+
                                '\n \n You have been added as a team member to the following case.'+
                                '\n \n Case #:'+ caseMap.get(memberCaseMap.get(usr.Id + ' ' + cse.id)).CaseNumber+
                                '\n Subject:'+ caseMap.get(memberCaseMap.get(usr.Id + ' ' + cse.id)).Subject+ 
                                '\n Priority:'+ caseMap.get(memberCaseMap.get(usr.Id + ' ' + cse.id)).Priority + 
                                '\n Region:'+ caseMap.get(memberCaseMap.get(usr.Id + ' ' + cse.id)).Region__c+
                                '\n Type:'+ caseMap.get(memberCaseMap.get(usr.Id + ' ' + cse.id)).Type+
                                '\n Description:'+ caseMap.get(memberCaseMap.get(usr.Id + ' ' + cse.id)).Description+
                                '\n \n Follow this link for more information on the Case: https://na4.salesforce.com/'+caseMap.get(memberCaseMap.get(usr.Id + ' ' + cse.id)).Id+
                                '\n \n Thanks';
                    }
                    else
                    {
                        mail.setSubject('You\'ve been added to the case team for Case # '+caseMap.get(memberCaseMap.get(usr.Id + ' ' + cse.id)).CaseNumber);                    
                        body= '*** NEW CASE TEAM MEMBER NOTIFICATION ***'+
                                '\n \n You have been added as a team member to the following case.'+
                                '\n \n Case #:'+ caseMap.get(memberCaseMap.get(usr.Id + ' ' + cse.id)).CaseNumber+
                                '\n Subject:'+ caseMap.get(memberCaseMap.get(usr.Id + ' ' + cse.id)).Subject+ 
                                '\n Priority:'+ caseMap.get(memberCaseMap.get(usr.Id + ' ' + cse.id)).Priority + 
                                '\n Region:'+ +
                                '\n Type:'+ caseMap.get(memberCaseMap.get(usr.Id + ' ' + cse.id)).Type+
                                '\n Description:'+ caseMap.get(memberCaseMap.get(usr.Id + ' ' + cse.id)).Description+
                                '\n \n Follow this link for more information on the Case: https://na4.salesforce.com/'+caseMap.get(memberCaseMap.get(usr.Id + ' ' + cse.id)).Id+
                                '\n \n Thanks';
                    }
                    mail.setPlainTextBody(body);
                    emailList.add(mail);
                }
            }
        }
        Messaging.sendEmail(emailList);     
    } // End of Batch method
                     
    /* post method for updating custom setting to store current date nad time. */
    global void finish(Database.BatchableContext BC)
    {
       if(myCS!=null){
            myCS.Value__c = now;
            update myCS;
        } 
    }// End of Finish method
          
       
}