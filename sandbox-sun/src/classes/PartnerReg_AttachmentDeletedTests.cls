/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class PartnerReg_AttachmentDeletedTests {

    static testMethod void parAttachmentDeletedUpdatesRegistrationTest() {
        // When an attachment whose parentId is a Partner_Registration__c record is deleted, the Partner Reg record should be udpated (the Proof of Perf timestamp should be nulled)
        Account testPartner = new Account(Name = 'Test Partner', Global_Region__c = 'NA', CurrencyIsoCode = 'USD');
        insert(testPartner);
        Account testCustomer = new Account( Name = 'Test Customer' );
        insert(testCustomer);

        Partner_Registration__c testReg = new  Partner_Registration__c(
            Company_Name__c = 'Test Customer',
            Company_Street_1__c = '124 Street',
            Company_City__c = 'Raleigh',
            Company_Country__c = 'US',
            End_Customer__c = testCustomer.Id,
            Estimated_Close_Date__c = Date.today().addDays(30),
            Partner__c = testPartner.Id,
            Product_Family__c = 'JBOSS',
            Project_Budget__c = 25000.00, 
            Status__c = 'Pending'
        );
        insert(testReg);
        
        Attachment testAttachment = new Attachment(Name = 'Test Attachment', Body= Blob.valueOf('Test text'), ParentId=testReg.Id);
        insert(testAttachment);
        testReg.Proof_of_Performance_Docs_Uploaded__c = Datetime.now();
        update(testReg);
        
        test.startTest();
            delete(testAttachment);
        test.stopTest();
        
        // Test
        Partner_Registration__c prResult = [select Id, Proof_of_Performance_Docs_Uploaded__c FROM Partner_Registration__c WHERE Id = :testReg.Id];
        system.assertEquals(null, prResult.Proof_of_Performance_Docs_Uploaded__c);
        
    }
    
    
    static testMethod void nonParAttachmentIsIgnoredTest(){
    	// A non-Partner Registration attachment shouldn't be affected by the trigger
    	Account testCustomer = new Account( Name = 'Test Customer' );
        insert(testCustomer);
        Attachment testAttachment = new Attachment(Name = 'Test Attachment', Body= Blob.valueOf('Test text'), ParentId=testCustomer.Id);
        insert(testAttachment);
        
        test.startTest();
            delete(testAttachment);
        test.stopTest();
        
        List<Attachment> results = [select id from Attachment where Id = :testAttachment.Id];
        system.assertEquals(0, results.size());        
    	
    }
}