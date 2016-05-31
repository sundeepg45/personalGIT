/**
* Class Name:TeamMemberListTest
* Description: Test Class created for TeamMemberList business Class
* Modificaton History:
* Modified By :Ratan Sharma
* Modified date :4/11/2011
* Reason for Modification:Separated test class from business class and created a new test class
* Modified By :Nitesh Dokania
* Modified date :6/15/2011
* Reason for Modification: Enhanced test class code coverage.
*/

@isTest
private class TeamMemberListTest
{
    public static testMethod void deployTeamMemberList() 
    {
        List<Account> accList = new List<Account>();
        List<AccountTeamMember> accTeamList = new List<AccountTeamMember>();
        for(Integer i=0;i<20;i++)
        {
        	Account acc = new Account(Name='test Account', isAccountActive__c=true);
        	accList.add(acc);
        }
        insert accList;
        for(Account acc : accList)
        {
        	AccountTeamMember AccountTeamMem = new AccountTeamMember (UserId=UserInfo.getUserId(), AccountId=acc.Id, TeamMemberRole='Channel Account Manager');
        	accTeamList.add(AccountTeamMem);
        }
        insert accTeamList;
        
        test.startTest();
        
        TeamMemberList TeamMemberListObj = new TeamMemberList();
        List<AccountTeamMember> accTeam = new List<AccountTeamMember>();
        List<String> accids=new List<String>();
        for(integer i=0;i<accList.size();i++)
        {
            accids.add(accList.get(i).Id);
        }        
        accTeam = TeamMemberListObj.getTeamMemberList(accids);

        // Verify the result.
        System.assertEquals(accTeamList,accTeam);
        
        test.stopTest();
    }
}