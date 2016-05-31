/**
 * Test class for Opportunity_Split_Batchable
 *
 * @version 2015-02-07
 * @author Scott Coleman <scoleman@redhat.com>
 * 2015-02-07 - Updated to fix bug
 * 2014-10-08 - Created
 */
@isTest
private class Opportunity_Split_BatchableTest {
 
    public static Account account {
        get {
            if(account == null) {
                account = new Account(
                    CurrencyIsoCode='USD',
                    name='Test Account');
                insert account;
            }
            return account;
        }
    }

    public static Opportunity opportunity {
        get {
            if(opportunity == null) {
                opportunity = new Opportunity(
                    Name='Opportunity Test',
                    CloseDate=System.today(),
                    StageName='Unqualified',
                    OwnerId=UserInfo.getUserId(),
                    AccountId=account.Id,
                    Country_of_Order__c='India',
                    FulfillmentChannel__c='Direct - OEM',
                    Engagement_SA__c=null);
                insert opportunity;
            }
            return opportunity;
        }
    }

    static List<Event__c> events {
        get {
            if(events == null) {
                events = new List<Event__c>{
                    new Event__c(Opportunity__c = opportunity.Id), 
                    new Event__c(Opportunity__c = opportunity.Id), 
                    new Event__c(Opportunity__c = opportunity.Id)};
            }
            return events;
        }
    }

    @isTest
    static void executeTest() {
        insert events;
        Opportunity_Split_Batchable batchable = new Opportunity_Split_Batchable();
        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(batchable.start(null));
        ssc.setPageSize(100);
        List<Event__c> testEvents = ssc.getRecords();
        System.assertEquals(4,testEvents.size());
        Test.startTest();
        batchable.execute(null,testEvents);
        batchable.errorList.add('Anything');
        batchable.execute(null,testEvents);
        Test.stopTest();
    }

    @isTest
    static void processEventsTest() {
        insert events;
        Test.startTest();
        Opportunity_Split_Batchable.processEvents(events);
        Test.stopTest();
        List<Event__c> testEvents = [SELECT Id, Processed__c FROM Event__c WHERE Processed__c = True];
        System.assertEquals(3,testEvents.size());
    }

    @isTest
    static void finishTest() {
        Opportunity_Split_Batchable batchable = new Opportunity_Split_Batchable();
        Test.startTest();
        try {
            batchable.finish((Database.BatchableContext)null);
        }
        catch(Exception e) {}
        batchable.finish((AsyncApexJob)null);
        Test.stopTest();
    }

    @isTest
    static void sendErrorsTest() {
        Opportunity_Split_Batchable batchable = new Opportunity_Split_Batchable();
        batchable.errorList.add('anything');
        Test.startTest();
        System.assertNotEquals(null,batchable.sendErrors(null));
        Test.stopTest();
    }

    @IsTest
    static void coverageTest() {
        Test.startTest();
        AbstractBatchableTest.coverageTest(new Opportunity_Split_Batchable(),new List<Event__c>());
        Test.stopTest();
    }
}