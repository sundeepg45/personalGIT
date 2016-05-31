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
private class Opportunity_PreventIsPARModificationTest {

    static testMethod void singleOppTest() {
        
        Account testAccount = new Account(Name = 'Test Account', CurrencyIsoCode = 'USD');
        insert(testAccount);
        Opportunity testOpp = new Opportunity(AccountId = testAccount.Id, Is_PAR__c = true, Name = 'Test Opp', StageName = 'Preparing', CloseDate = Date.today().addDays(45));
        insert(testOpp);
        
        
        test.startTest();
        
            // Attempt to change the Is_PAR__c field (which should be blocked and raise a DML Exception)
            try{
                testOpp.Is_PAR__c = false;
                update(testOpp);
            } catch(DmlException dmle){
            	system.assert(dmle.getDmlMessage(0).contains('PAR flag cannot be changed'));
            }
        test.stopTest();
        
    }
    
    
    
    static testMethod void bulkTest(){
    	
    	Account testAccount = new Account(Name = 'Test Account', CurrencyIsoCode = 'USD');
        insert(testAccount);
        
        // Create 5 opps for this account
        List<Opportunity> testOpps = new List<Opportunity>();
        for(integer i = 0; i < 5; i++){
            testOpps.add(new Opportunity(AccountId = testAccount.Id, Is_PAR__c = true, Name = 'Test Opp ' + i, StageName = 'Preparing', CloseDate = Date.today().addDays(45)) );
        }
        insert(testOpps);
        
    	for(Opportunity o:testOpps){
    		o.Is_PAR__c = false;
    	}
    	
    	
    	test.startTest();
    	   try{
    	   	   update(testOpps);
    	   } catch(DMLException e){
    	   	   system.assertEquals(5, e.getNumDml());
    	   	   system.assert(e.getDmlMessage(4).contains('PAR flag cannot be changed'));
    	   }
    	test.stopTest();
    	
    }
    
}