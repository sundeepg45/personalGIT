/*
Name        : NotifyCaseTeamMemberTest
Author      : Nitesh Dokania
Reason      : This test will cover the NotifyCaseTeamMember class by executing the batch class.
Created Date: 01/23/13

*/
public class NotifyCaseTeamMemberTest{
    
    @isTest(SeeAllData=true)
    static void testBatchJob() 
    {
        DateTimeSetting__c myCS = new DateTimeSetting__c(Name = 'Test Config', Value__c = datetime.now());
        insert myCS;
        
        List<Case> lstCase = new List<Case>();
        List<CaseTeamMember> lstCaseTeam = new List<CaseTeamMember>();
        
        User usr = [Select Id from User where UserType = 'Standard' and Id != : UserInfo.getUserId() and isActive =: true limit 1 ];
        
        Case caseRec = new Case(Type = 'Accounts', Type_Detail__c = 'Account Merge', Subject = 'Test Subject', Description = 'Test Desc' );        
        lstCase.add(caseRec);
        
        try{
            insert lstCase;
        }catch(Exception e){

        }

        CaseTeamRole caseTeamRole = [Select c.Name, c.Id, c.AccessLevel From CaseTeamRole c limit 1];
        CaseTeamMember caseTeam = new CaseTeamMember(ParentId=caseRec.Id, MemberId=usr.Id, TeamRoleId=caseTeamRole.Id);
        lstCaseTeam.add(caseTeam);
        insert lstCaseTeam;  
             
        System.test.StartTest();             
        // Call the batch class
        
        
        datetime now = null;
        String lastRunDateTimeStr;
        
        NotifyCaseTeamMember batchClass = new NotifyCaseTeamMember();
        //batchClass.myCS = myCS;        
        ID batchprocessid = Database.executeBatch(batchClass);
        System.test.StopTest();  
        
        }
             
}