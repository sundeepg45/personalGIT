/**
 * @author: Jayant (Application Maintenance)
 * @version: 2012-04-26
 * @description: Test class for the class PartnerStatusTriggerPRL.cls.
 * Modificaton History:
 * Modified By : 
 * Modified date :
 * Reason for Modification:
 */
@isTest 
private class PartnerStatusTriggerPRLTest {
    
    static final String ORACLE_ACCOUNT_NUMBER='2@Test';
    
    static testMethod void myUnitTest() {

    Account acc = new Account(
                    Name='0OppUpFinPartTest',RecordTypeId='012300000000NBG',
                    AccountClassification__c='Sales - Territory',
                    BillingCountry='US',
                    OwnerId=UserInfo.getUserId());
    insert acc; 
    
    Account partner = new Account(
                    Name='1OppUpFinPartTest',RecordTypeId='012600000004yfa',
                    OracleAccountNumber__c=ORACLE_ACCOUNT_NUMBER,
                    BillingCountry='US',
                    OwnerId=UserInfo.getUserId());
    insert partner;

    Opportunity opp = new Opportunity(
                    Name='2OppUpFinPartTest',
                    StageName='Prepare', FulfillmentChannel__c='Direct - VAR/VAD',
                    Amount=0.00, RecordTypeId='012300000000TVD', 
                    OpportunityType__c='Royalty', AccountId=acc.Id, 
                    OwnerId=UserInfo.getUserId(), Pay_Now__c='No', 
                    ForecastCategoryName='Omitted', CloseDate=Date.today(), 
                    PaymentType__c='NA Purchase Order');
    insert opp;
    
    Classification__c partnerType = [select Id from Classification__c where Hierarchy__c = 'Partner Type » Reseller' and IsActive__c = true limit 1];
    Classification__c partnerTier = [select Id from Classification__c where Hierarchy__c like 'Partner Tier » Ready' and IsActive__c = true limit 1];

    PartnerStatus__c partnerStat = new PartnerStatus__c(
                    ApprovalStatus__c='Approved', 
                    PartnerTier__c=partnerTier.Id, 
                    ActivationDate__c=Date.today().addDays(-1), 
                    PartnerType__c=partnerType.Id, 
                    Partner__c=partner.Id, 
                    ExpirationDate__c=Date.today().addDays(1),
                    IsVisible__c=true);
    insert partnerStat;
    
    OpportunityPartner__c oppPartner = new OpportunityPartner__c(
                    Opportunity__c=opp.Id,
                    Partner__c=partner.Id,
                    PartnerTier__c=partnerStat.PartnerTier__c,
                    PartnerType__c=partnerStat.PartnerType__c, 
                    RelationshipType__c='Reseller 2');
    insert oppPartner;
    
    Test.startTest();    
    Classification__c partnerTier1 = [select Id from Classification__c where Hierarchy__c = 'Partner Tier » Advanced' and IsActive__c = true limit 1];
    partnerStat.PartnerTier__c = partnerTier1.Id;
    update partnerStat;
    Test.stopTest();
    }
}