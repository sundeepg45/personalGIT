/**
* Class Name:CaseDeployTest
* Author:Accenture
* Date:4/26/2011
* Description: Contains test methods for Case related triggers.
* Modificaton History:
* Modified By :	Nitesh Dokania
* Modified date :4/26/2011
* Reason for Modification: Included @isTest notation since it is a test class. 
*                          Changed class name from CaseDeploy to CaseDeployTest.
*/

@isTest
private class CaseDeployTest {
    public static testmethod void deployContact_of_Case() {
        Account account = new Account();
        account.Name = 'Red Hat (Internal Use Only)';
        insert Account;
        
        Contact contact = new Contact();
        contact.FirstName = 'First';
        contact.LastName = 'Last';
        contact.AccountId = account.Id;
        contact.Email = 'example@example.org';
        insert contact;          
                  
        Case newcase = new Case();
        newcase.Type='Accounts';
        newcase.Type_Detail__c ='Account Merge';
        newcase.Origin='Email';
        newcase.Status='New';
        newcase.Description='Kalidas IDC';
        newcase.Subject='Accenture';
        newcase.ContactId = contact.Id;
        insert newcase;
            
    }
}