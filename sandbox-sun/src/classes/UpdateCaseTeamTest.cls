/**
 * This class contains unit tests for validating the behavior of Apex class UpdateCaseTeam
 *
 * Author: Nitesh Dokania
 * Created Date : 10/22/2012
 * Modified Date:
 *
 */
 
@isTest
private class UpdateCaseTeamTest
{
    public static testMethod void newMemberTest()
    {
        Account a = new Account();
        a.Name = 'Red Hat (Internal Use Only)';
        insert a;
        
        Contact con = new Contact(LastName='Test',Email='TestUser@acc.com',AccountId=a.Id);
        insert con;
        
        Case caseRec = new Case();
        caseRec.Origin = 'Web';
        caseRec.Type = 'Campaign';
        caseRec.Status = 'New';
        caseRec.ContactId = con.Id;
        insert caseRec;
    
        UpdateCaseTeam.addUserToCaseTeam(caseRec.Id);
        
        CaseTeamMember caseTeam = [Select Id, MemberId, ParentId from CaseteamMember where ParentId =: caseRec.Id];
        System.assertEquals(UserInfo.getUserId(),caseTeam.MemberId);
        
        UpdateCaseTeam.addUserToCaseTeam(caseRec.Id);

    }
}