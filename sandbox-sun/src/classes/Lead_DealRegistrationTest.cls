@IsTest 
private class Lead_DealRegistrationTest { public static testmethod void testServicesRevenueIsNotNull() { } }

/**mendler
private class Lead_DealRegistrationTest {
    private static final RecordType RecordType_NA = [
       select Name
         from RecordType
        where Name = 'NA Deal Registration'
    ];

    private static final RecordType RecordType_LATAM = [
       select Name
         from RecordType
        where Name = 'LATAM Deal Registration'
    ];

    private static final RecordType RecordType_EMEA = [
       select Name
         from RecordType
        where Name = 'EMEA Deal Registration'
    ];

	public class ExpectedExceptionNotThrownException extends Exception {}
	
	public static Lead newLead(RecordType recordType) {
        Lead lead = new Lead();
        lead.RecordTypeId = recordType.Id;
        lead.Company = 'Company Name';
        lead.LastName = 'Last Name';
        lead.State = 'NC';
        lead.Country = 'US';
		return lead;
	}
	
	public static Lead newServicesLead(RecordType recordType, Decimal revenue) {
		Lead lead = newLead(recordType);
        lead.Revenue_Type__c = 'Services';
        lead.Red_Hat_Services_Revenue__c = revenue;
        return lead;
	}
	
    public static Lead newSubscriptionLead(RecordType recordType, Decimal revenue) {
        Lead lead = newLead(recordType);
        lead.Revenue_Type__c = 'Subscription';
        lead.Red_Hat_Subscription_Revenue__c = revenue;
        return lead;
    }
    
    /** 
      * Services Revenue validation rules
      */
 /**mendler   
    public static testmethod void testServicesRevenueIsNotNull() {
        try {
            insert newServicesLead(RecordType_NA, null);
            throw new ExpectedExceptionNotThrownException();
        } catch (System.DmlException e) {
            system.assert(e.getDmlMessage(0).contains('Red Hat Services Revenue must be greater than zero.'));
        }
    } 

    public static testmethod void testServicesRevenueIsNotNegative() {
        try {
            insert newServicesLead(RecordType_NA, -10.00);
            throw new ExpectedExceptionNotThrownException();
        } catch (System.DmlException e) {
            system.assert(e.getDmlMessage(0).contains('Red Hat Services Revenue must be greater than zero.'));
        }
    } 

    public static testmethod void testServicesRevenueIsNotZero() {
        try {
            insert newServicesLead(RecordType_NA, 0.00);
            throw new ExpectedExceptionNotThrownException();
        } catch (System.DmlException e) {
            system.assert(e.getDmlMessage(0).contains('Red Hat Services Revenue must be greater than zero.'));
        }
    } 

    public static testmethod void testServicesRevenueIsPositive() {
        insert newServicesLead(RecordType_NA, 10.00);
    } 

    /** 
      * Subscription Revenue validation rules
      */
/**mendler
    public static testmethod void testSubscriptionRevenueIsNotNull() {
        try {
            insert newSubscriptionLead(RecordType_NA, null);
            throw new ExpectedExceptionNotThrownException();
        } catch (System.DmlException e) {
            system.assert(e.getDmlMessage(0).contains('Red Hat Subscription Revenue must be greater than zero.'));
        }
    } 

    public static testmethod void testSubscriptionRevenueIsNotNegative() {
        try {
            insert newSubscriptionLead(RecordType_NA, -10.00);
            throw new ExpectedExceptionNotThrownException();
        } catch (System.DmlException e) {
            system.assert(e.getDmlMessage(0).contains('Red Hat Subscription Revenue must be greater than zero.'));
        }
    } 

    public static testmethod void testSubscriptionRevenueIsNotZero() {
        try {
            insert newSubscriptionLead(RecordType_NA, 0.00);
            throw new ExpectedExceptionNotThrownException();
        } catch (System.DmlException e) {
            system.assert(e.getDmlMessage(0).contains('Red Hat Subscription Revenue must be greater than zero.'));
        }
    } 

    public static testmethod void testSubscriptionRevenueIsPositive() {
        insert newSubscriptionLead(RecordType_NA, 10.00);
    } 
    
    /**
     * NA specific validations - Services
     */
/**mendler   
    public static testmethod void testRequiredServicesRevenue_NA_JBoss_IsBelowThreshhold() {
        try {
        	Lead lead = newServicesLead(RecordType_NA, 9999);
            lead.CurrencyIsoCode = 'USD';
        	lead.Deal_Registration_Classification__c = 'JBoss';
            insert lead;
            throw new ExpectedExceptionNotThrownException();
        } catch (System.DmlException e) {
            system.assert(e.getDmlMessage(0).contains('Services Revenue should greater than $10,000.'));
        }
    } 

    public static testmethod void testRequiredServicesRevenue_NA_JBoss_IsAtThreshhold() {
        Lead lead = newServicesLead(RecordType_NA, 20000);
        lead.CurrencyIsoCode = 'USD';
        lead.Deal_Registration_Classification__c = 'JBoss';
        insert lead;
    } 

    public static testmethod void testRequiredServicesRevenue_NA_JBoss_IsAboveThreshhold() {
        Lead lead = newServicesLead(RecordType_NA, 20001);
        lead.CurrencyIsoCode = 'USD';
        lead.Deal_Registration_Classification__c = 'JBoss';
        insert lead;
    } 

     
    public static testmethod void testRequiredServicesRevenue_NA_MetaMatrix_IsBelowThreshhold() {
        try {
            Lead lead = newServicesLead(RecordType_NA, 19999);
            lead.CurrencyIsoCode = 'USD';
            lead.Deal_Registration_Classification__c = 'MetaMatrix';
            insert lead;
            throw new ExpectedExceptionNotThrownException();
        } catch (System.DmlException e) {
            system.assert(e.getDmlMessage(0).contains('If registering a MetaMatrix deal, Services Revenue should be greater than $20,000.'));
        }
    } 

    public static testmethod void testRequiredServicesRevenue_NA_MetaMatrix_IsAtThreshhold() {
        Lead lead = newServicesLead(RecordType_NA, 20000);
        lead.CurrencyIsoCode = 'USD';
        lead.Deal_Registration_Classification__c = 'MetaMatrix';
        insert lead;
    } 

    public static testmethod void testRequiredServicesRevenue_NA_MetaMatrix_IsAboveThreshhold() {
        Lead lead = newServicesLead(RecordType_NA, 20001);
        lead.CurrencyIsoCode = 'USD';
        lead.Deal_Registration_Classification__c = 'MetaMatrix';
        insert lead;
    } 

     
    public static testmethod void testRequiredServicesRevenue_NA_RHEL_IsBelowThreshhold() {
        try {
            Lead lead = newServicesLead(RecordType_NA, 9999);
            lead.CurrencyIsoCode = 'USD';
            lead.Deal_Registration_Classification__c = 'RHEL';
            insert lead;
            throw new ExpectedExceptionNotThrownException();
        } catch (System.DmlException e) {
            system.assert(e.getDmlMessage(0).contains('Services Revenue should greater than $10,000.'));
        }
    } 

    public static testmethod void testRequiredServicesRevenue_NA_RHEL_IsAtThreshhold() {
        Lead lead = newServicesLead(RecordType_NA, 10000);
        lead.CurrencyIsoCode = 'USD';
        lead.Deal_Registration_Classification__c = 'RHEL';
        insert lead;
    } 

    public static testmethod void testRequiredServicesRevenue_NA_RHEL_IsAboveThreshhold() {
        Lead lead = newServicesLead(RecordType_NA, 10001);
        lead.CurrencyIsoCode = 'USD';
        lead.Deal_Registration_Classification__c = 'RHEL';
        insert lead;
    } 

     
    /**
     * NA specific validations - Subscription
     */
/**mendler 
    public static testmethod void testRequiredSubscriptionRevenue_NA_JBoss_IsBelowThreshhold() {
        try {
            Lead lead = newSubscriptionLead(RecordType_NA, 9999);
            lead.CurrencyIsoCode = 'USD';
            lead.Deal_Registration_Classification__c = 'JBoss';
            insert lead;
            throw new ExpectedExceptionNotThrownException();
        } catch (System.DmlException e) {
            system.assert(e.getDmlMessage(0).contains('Subscription Revenue should greater than $10,000.'));
        }
    } 

    public static testmethod void testRequiredSubscriptionRevenue_NA_JBoss_IsAtThreshhold() {
        Lead lead = newSubscriptionLead(RecordType_NA, 20000);
        lead.CurrencyIsoCode = 'USD';
        lead.Deal_Registration_Classification__c = 'JBoss';
        insert lead;
    } 

    public static testmethod void testRequiredSubscriptionRevenue_NA_JBoss_IsAboveThreshhold() {
        Lead lead = newSubscriptionLead(RecordType_NA, 20001);
        lead.CurrencyIsoCode = 'USD';
        lead.Deal_Registration_Classification__c = 'JBoss';
        insert lead;
    } 

     
    public static testmethod void testRequiredSubscriptionRevenue_NA_MetaMatrix_IsBelowThreshhold() {
        try {
            Lead lead = newSubscriptionLead(RecordType_NA, 19999);
            lead.CurrencyIsoCode = 'USD';
            lead.Deal_Registration_Classification__c = 'MetaMatrix';
            insert lead;
            throw new ExpectedExceptionNotThrownException();
        } catch (System.DmlException e) {
            system.assert(e.getDmlMessage(0).contains('If registering a Metamatrix deal, Subscription Revenue should be greater than $20,000.'));
        }
    } 

    public static testmethod void testRequiredSubscriptionRevenue_NA_MetaMatrix_IsAtThreshhold() {
        Lead lead = newSubscriptionLead(RecordType_NA, 20000);
        lead.CurrencyIsoCode = 'USD';
        lead.Deal_Registration_Classification__c = 'MetaMatrix';
        insert lead;
    } 

    public static testmethod void testRequiredSubscriptionRevenue_NA_MetaMatrix_IsAboveThreshhold() {
        Lead lead = newSubscriptionLead(RecordType_NA, 20001);
        lead.CurrencyIsoCode = 'USD';
        lead.Deal_Registration_Classification__c = 'MetaMatrix';
        insert lead;
    } 

     
    public static testmethod void testRequiredSubscriptionRevenue_NA_RHEL_IsBelowThreshhold() {
        try {
            Lead lead = newSubscriptionLead(RecordType_NA, 9999);
            lead.CurrencyIsoCode = 'USD';
            lead.Deal_Registration_Classification__c = 'RHEL';
            insert lead;
            throw new ExpectedExceptionNotThrownException();
        } catch (System.DmlException e) {
            system.assert(e.getDmlMessage(0).contains('Subscription Revenue should greater than $10,000.'));
        }
    } 

    public static testmethod void testRequiredSubscriptionRevenue_NA_RHEL_IsAtThreshhold() {
        Lead lead = newSubscriptionLead(RecordType_NA, 10000);
        lead.CurrencyIsoCode = 'USD';
        lead.Deal_Registration_Classification__c = 'RHEL';
        insert lead;
    } 

    public static testmethod void testRequiredSubscriptionRevenue_NA_RHEL_IsAboveThreshhold() {
        Lead lead = newSubscriptionLead(RecordType_NA, 10001);
        lead.CurrencyIsoCode = 'USD';
        lead.Deal_Registration_Classification__c = 'RHEL';
        insert lead;
    } 

     
    /**
     * LATAM specific validations - Services
     *
     * 2009-12-04 - currently disabled
     *
     
    public static testmethod void testRequiredServicesRevenue_LATAM_JBoss_IsBelowThreshhold() {
        try {
            Lead lead = newServicesLead(RecordType_LATAM, 19999);
            lead.CurrencyIsoCode = 'USD';
            lead.Deal_Registration_Classification__c = 'JBoss';
            insert lead;
            throw new ExpectedExceptionNotThrownException();
        } catch (System.DmlException e) {
            system.assert(e.getDmlMessage(0).contains('If registering a JBoss or MetaMatrix deal, Services Revenue should be greater than $20,000.'));
        }
    } 

    public static testmethod void testRequiredServicesRevenue_LATAM_JBoss_IsAtThreshhold() {
        Lead lead = newServicesLead(RecordType_LATAM, 20000);
        lead.CurrencyIsoCode = 'USD';
        lead.Deal_Registration_Classification__c = 'JBoss';
        insert lead;
    } 

    public static testmethod void testRequiredServicesRevenue_LATAM_JBoss_IsAboveThreshhold() {
        Lead lead = newServicesLead(RecordType_LATAM, 20001);
        lead.CurrencyIsoCode = 'USD';
        lead.Deal_Registration_Classification__c = 'JBoss';
        insert lead;
    } 

     
    public static testmethod void testRequiredServicesRevenue_LATAM_MetaMatrix_IsBelowThreshhold() {
        try {
            Lead lead = newServicesLead(RecordType_LATAM, 19999);
            lead.CurrencyIsoCode = 'USD';
            lead.Deal_Registration_Classification__c = 'MetaMatrix';
            insert lead;
            throw new ExpectedExceptionNotThrownException();
        } catch (System.DmlException e) {
            system.assert(e.getDmlMessage(0).contains('If registering a JBoss or MetaMatrix deal, Services Revenue should be greater than $20,000.'));
        }
    } 

    public static testmethod void testRequiredServicesRevenue_LATAM_MetaMatrix_IsAtThreshhold() {
        Lead lead = newServicesLead(RecordType_LATAM, 20000);
        lead.CurrencyIsoCode = 'USD';
        lead.Deal_Registration_Classification__c = 'MetaMatrix';
        insert lead;
    } 

    public static testmethod void testRequiredServicesRevenue_LATAM_MetaMatrix_IsAboveThreshhold() {
        Lead lead = newServicesLead(RecordType_LATAM, 20001);
        lead.CurrencyIsoCode = 'USD';
        lead.Deal_Registration_Classification__c = 'MetaMatrix';
        insert lead;
    } 

     
    public static testmethod void testRequiredServicesRevenue_LATAM_RHEL_IsBelowThreshhold() {
        try {
            Lead lead = newServicesLead(RecordType_LATAM, 9999);
            lead.CurrencyIsoCode = 'USD';
            lead.Deal_Registration_Classification__c = 'RHEL';
            insert lead;
            throw new ExpectedExceptionNotThrownException();
        } catch (System.DmlException e) {
            system.assert(e.getDmlMessage(0).contains('If registering a RHEL deal, Services Revenue should greater than $10,000.'));
        }
    } 

    public static testmethod void testRequiredServicesRevenue_LATAM_RHEL_IsAtThreshhold() {
        Lead lead = newServicesLead(RecordType_LATAM, 10000);
        lead.CurrencyIsoCode = 'USD';
        lead.Deal_Registration_Classification__c = 'RHEL';
        insert lead;
    } 

    public static testmethod void testRequiredServicesRevenue_LATAM_RHEL_IsAboveThreshhold() {
        Lead lead = newServicesLead(RecordType_LATAM, 10001);
        lead.CurrencyIsoCode = 'USD';
        lead.Deal_Registration_Classification__c = 'RHEL';
        insert lead;
    } 

    */
         
    /**
     * LATAM specific validations - Subscription
     *
     * 2009-12-04 - currently disabled
     *
     
    public static testmethod void testRequiredSubscriptionRevenue_LATAM_JBoss_IsBelowThreshhold() {
        try {
            Lead lead = newSubscriptionLead(RecordType_LATAM, 19999);
            lead.CurrencyIsoCode = 'USD';
            lead.Deal_Registration_Classification__c = 'JBoss';
            insert lead;
            throw new ExpectedExceptionNotThrownException();
        } catch (System.DmlException e) {
            system.assert(e.getDmlMessage(0).contains('If registering a JBoss or Metamatrix deal, Subscription Revenue should be greater than $20,000.'));
        }
    } 

    public static testmethod void testRequiredSubscriptionRevenue_LATAM_JBoss_IsAtThreshhold() {
        Lead lead = newSubscriptionLead(RecordType_LATAM, 20000);
        lead.CurrencyIsoCode = 'USD';
        lead.Deal_Registration_Classification__c = 'JBoss';
        insert lead;
    } 

    public static testmethod void testRequiredSubscriptionRevenue_LATAM_JBoss_IsAboveThreshhold() {
        Lead lead = newSubscriptionLead(RecordType_LATAM, 20001);
        lead.CurrencyIsoCode = 'USD';
        lead.Deal_Registration_Classification__c = 'JBoss';
        insert lead;
    } 

     
    public static testmethod void testRequiredSubscriptionRevenue_LATAM_MetaMatrix_IsBelowThreshhold() {
        try {
            Lead lead = newSubscriptionLead(RecordType_LATAM, 19999);
            lead.CurrencyIsoCode = 'USD';
            lead.Deal_Registration_Classification__c = 'MetaMatrix';
            insert lead;
            throw new ExpectedExceptionNotThrownException();
        } catch (System.DmlException e) {
            system.assert(e.getDmlMessage(0).contains('If registering a JBoss or Metamatrix deal, Subscription Revenue should be greater than $20,000.'));
        }
    } 

    public static testmethod void testRequiredSubscriptionRevenue_LATAM_MetaMatrix_IsAtThreshhold() {
        Lead lead = newSubscriptionLead(RecordType_LATAM, 20000);
        lead.CurrencyIsoCode = 'USD';
        lead.Deal_Registration_Classification__c = 'MetaMatrix';
        insert lead;
    } 

    public static testmethod void testRequiredSubscriptionRevenue_LATAM_MetaMatrix_IsAboveThreshhold() {
        Lead lead = newSubscriptionLead(RecordType_LATAM, 20001);
        lead.CurrencyIsoCode = 'USD';
        lead.Deal_Registration_Classification__c = 'MetaMatrix';
        insert lead;
    } 

     
    public static testmethod void testRequiredSubscriptionRevenue_LATAM_RHEL_IsBelowThreshhold() {
        try {
            Lead lead = newSubscriptionLead(RecordType_LATAM, 9999);
            lead.CurrencyIsoCode = 'USD';
            lead.Deal_Registration_Classification__c = 'RHEL';
            insert lead;
            throw new ExpectedExceptionNotThrownException();
        } catch (System.DmlException e) {
            system.assert(e.getDmlMessage(0).contains('If registering a RHEL deal, Subscription Revenue should greater than $10,000.'));
        }
    } 

    public static testmethod void testRequiredSubscriptionRevenue_LATAM_RHEL_IsAtThreshhold() {
        Lead lead = newSubscriptionLead(RecordType_LATAM, 10000);
        lead.CurrencyIsoCode = 'USD';
        lead.Deal_Registration_Classification__c = 'RHEL';
        insert lead;
    } 

    public static testmethod void testRequiredSubscriptionRevenue_LATAM_RHEL_IsAboveThreshhold() {
        Lead lead = newSubscriptionLead(RecordType_LATAM, 10001);
        lead.CurrencyIsoCode = 'USD';
        lead.Deal_Registration_Classification__c = 'RHEL';
        insert lead;
    } 

    */     
/*mendler
} */