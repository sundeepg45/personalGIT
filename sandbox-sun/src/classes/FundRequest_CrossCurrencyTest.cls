@IsTest
private class FundRequest_CrossCurrencyTest {
    public static final Decimal BELOW_FACTOR = 1.00009;
    public static final Decimal FUDGE_FACTOR = 1.00010;
    public static final Decimal ABOVE_FACTOR = 1.00011;
    public static final CurrencyConverter currencyConverter = new CurrencyConverter();

    public class ExpectedExceptionNotThrownException extends Exception {}

    public static Decimal convert(String sourceCurrency, String targetCurrency, Decimal sourceAmount) {
        currencyConverter.setSourceAmount(sourceAmount);
        currencyConverter.setSourceCurrency(sourceCurrency);
        currencyConverter.setTargetCurrency(targetCurrency);
        currencyConverter.setLegacyConversion(true);

        system.debug('Preconversion of currency:');
        system.debug('- sourceCurrency = ' + sourceCurrency);
        system.debug('- sourceAmount = ' + sourceAmount);
        system.debug('- targetCurrency = ' + targetCurrency);
        system.debug('- targetAmount = ' + currencyConverter.getTargetAmount());
        return currencyConverter.getTargetAmount();
    }

    public static SFDC_Budget__c newMDF(String currencyCode, Decimal allocatedBudget) {
        Account account = new Account();
        account.Name = 'Account';
        account.RecordTypeId = [
            select Id
            from RecordType
            where SObjectType = 'Account'
            and Name = 'NA Partner'].Id;
        insert account;

        SFDC_Budget__c mdf = new SFDC_Budget__c();
        mdf.Name = 'Budget';
        mdf.Account_Master__c = account.Id;
        mdf.Active__c = true;
        mdf.Allocated_Budget__c = allocatedBudget;
        mdf.Select_Fiscal_Year__c = 'Current Fiscal Year';
        mdf.Fiscal_Quarter__c = MDFTestSupport.getCurrentFiscalQuarter();
        mdf.Start_Date__c = MDFTestSupport.getCurrentStartDate();
        mdf.End_Date__c = MDFTestSupport.getCurrentEndDate();
        mdf.CurrencyIsoCode = currencyCode;
        insert mdf;
        return mdf;
    }

    public static SFDC_MDF__c newFundRequest(SFDC_Budget__c mdf, String currencyCode, Decimal requestedFunding) {
        SFDC_MDF__c fundRequest = new SFDC_MDF__c();
        fundRequest.Account_Master__c = mdf.Account_Master__c;
        fundRequest.Budget__c = mdf.Id;
        fundRequest.CurrencyIsoCode = currencyCode;
        fundRequest.Total_Expenditure_of_Activity__c = requestedFunding * 1.50;
        fundRequest.Estimated_Red_Hat_Funding_Requested__c = requestedFunding;
        fundRequest.Approval_Status__c = 'Pending First Approval';
        return fundRequest;
    }

    public static testmethod void testNewFundRequest_LimitsAreIgnored_Draft() {
        SFDC_MDF__c fundRequest = newFundRequest(newMDF('USD', 100.00), 'USD', 200.00);
        fundRequest.Approval_Status__c = 'Draft';
        insert fundRequest;
    }

    public static testmethod void testNewFundRequest_LimitsAreIgnored_Rejected() {
        SFDC_MDF__c fundRequest = newFundRequest(newMDF('USD', 100.00), 'USD', 200.00);
        fundRequest.Approval_Status__c = 'Rejected';
        insert fundRequest;
    }

    public static testmethod void testNewFundRequest_USD_USD_IsBelowThreshold() {
        insert newFundRequest(newMDF('USD', 100.00), 'USD', convert('USD', 'USD', 100.00 * 0.95));
    }

    public static testmethod void testNewFundRequest_USD_USD_IsAtThreshold() {
        insert newFundRequest(newMDF('USD', 100.00), 'USD', convert('USD', 'USD', 100.00));
    }

    public static testmethod void testNewFundRequest_USD_USD_IsAboveThreshold() {
        try {
            insert newFundRequest(newMDF('USD', 100.00), 'USD', convert('USD', 'USD', 100.00 * BELOW_FACTOR));
            throw new ExpectedExceptionNotThrownException();
        } catch (System.DmlException e) {
            system.assert(e.getDmlMessage(0).contains('Please ensure the Estimated Red Hat Funding Requested amount is less than the Available Budget.'), e.getMessage());
        }
    }

    public static testmethod void testNewFundRequest_USD_USD_IsAboveThreshold_AboveFudgeFactor() {
        try {
            insert newFundRequest(newMDF('USD', 100.00), 'USD', convert('USD', 'USD', 100.00 * ABOVE_FACTOR));
            throw new ExpectedExceptionNotThrownException();
        } catch (System.DmlException e) {
            system.assert(e.getDmlMessage(0).contains('Please ensure the Estimated Red Hat Funding Requested amount is less than the Available Budget.'), e.getMessage());
        }
    }

    public static testmethod void testNewFundRequest_GBP_KRW_IsBelowThreshold() {
        insert newFundRequest(newMDF('GBP', 100.00), 'KRW', convert('GBP', 'KRW', 100.00 * 0.95));
    }

    public static testmethod void testNewFundRequest_GBP_KRW_IsAtThreshold() {
        insert newFundRequest(newMDF('GBP', 100.00), 'KRW', convert('GBP', 'KRW', 100.00));
    }

    public static testmethod void testNewFundRequest_GBP_KRW_IsAboveThreshold() {
        insert newFundRequest(newMDF('GBP', 100.00), 'KRW', convert('GBP', 'KRW', 100.00 * BELOW_FACTOR));
    }

    public static testmethod void testNewFundRequest_GBP_KRW_IsAboveThreshold_AboveFudgeFactor() {
        try {
            insert newFundRequest(newMDF('GBP', 100.00), 'KRW', convert('GBP', 'KRW', 100.00 * ABOVE_FACTOR));
            throw new ExpectedExceptionNotThrownException();
        } catch (System.DmlException e) {
            system.assert(e.getDmlMessage(0).contains('Please ensure the Estimated Red Hat Funding Requested amount is less than the Available Budget.'), e.getMessage());
        }
    }

    public static testmethod void testNewFundRequest_KRW_GBP_IsBelowThreshold() {
        insert newFundRequest(newMDF('KRW', 100.00), 'GBP', convert('KRW', 'GBP', 100.00 * 0.95));
    }

    public static testmethod void testNewFundRequest_KRW_GBP_IsAtThreshold() {
        insert newFundRequest(newMDF('KRW', 100.00), 'GBP', convert('KRW', 'GBP', 100.00));
    }

    public static testmethod void testNewFundRequest_KRW_GBP_IsAboveThreshold() {
        insert newFundRequest(newMDF('KRW', 100.00), 'GBP', convert('KRW', 'GBP', 100.00 * BELOW_FACTOR));
    }

    public static testmethod void testNewFundRequest_KRW_GBP_IsAboveThreshold_AboveFudgeFactor() {
        try {
            insert newFundRequest(newMDF('KRW', 100.00), 'GBP', convert('KRW', 'GBP', 100.00 * ABOVE_FACTOR));
            throw new ExpectedExceptionNotThrownException();
        } catch (System.DmlException e) {
            system.assert(e.getDmlMessage(0).contains('Please ensure the Estimated Red Hat Funding Requested amount is less than the Available Budget.'), e.getMessage());
        }
    }

    public static testmethod void testNewFundRequest_USD_KRW_IsBelowThreshold() {
        insert newFundRequest(newMDF('USD', 100.00), 'KRW', convert('USD', 'KRW', 100.00 * 0.95));
    }

    public static testmethod void testNewFundRequest_USD_KRW_IsAtThreshold() {
        insert newFundRequest(newMDF('USD', 100.00), 'KRW', convert('USD', 'KRW', 100.00));
    }

    public static testmethod void testNewFundRequest_USD_KRW_IsAboveThreshold() {
        insert newFundRequest(newMDF('USD', 100.00), 'KRW', convert('USD', 'KRW', 100.00 * BELOW_FACTOR));
    }

    public static testmethod void testNewFundRequest_USD_KRW_IsAboveThreshold_AboveFudgeFactor() {
        try {
            insert newFundRequest(newMDF('USD', 100.00), 'KRW', convert('USD', 'KRW', 100.00 * ABOVE_FACTOR));
            throw new ExpectedExceptionNotThrownException();
        } catch (System.DmlException e) {
            system.assert(e.getDmlMessage(0).contains('Please ensure the Estimated Red Hat Funding Requested amount is less than the Available Budget.'), e.getMessage());
        }
    }

    public static testmethod void testNewFundRequest_KRW_USD_IsBelowThreshold() {
        insert newFundRequest(newMDF('KRW', 100.00), 'USD', convert('KRW', 'USD', 100.00 * 0.95));
    }

    public static testmethod void testNewFundRequest_KRW_USD_IsAtThreshold() {
        insert newFundRequest(newMDF('KRW', 100.00), 'USD', convert('KRW', 'USD', 100.00));
    }

    public static testmethod void testNewFundRequest_KRW_USD_IsAboveThreshold() {
        insert newFundRequest(newMDF('KRW', 100.00), 'USD', convert('KRW', 'USD', 100.00 * BELOW_FACTOR));
    }

    public static testmethod void testNewFundRequest_KRW_USD_IsAboveThreshold_AboveFudgeFactor() {
        try {
            insert newFundRequest(newMDF('KRW', 100.00), 'USD', convert('KRW', 'USD', 100.00 * ABOVE_FACTOR));
            throw new ExpectedExceptionNotThrownException();
        } catch (System.DmlException e) {
            system.assert(e.getDmlMessage(0).contains('Please ensure the Estimated Red Hat Funding Requested amount is less than the Available Budget.'), e.getMessage());
        }
    }

    public static testmethod void testNewFundRequest_GBP_USD_IsBelowThreshold() {
        insert newFundRequest(newMDF('GBP', 100.00), 'USD', convert('GBP', 'USD', 100.00 * 0.95));
    }

    public static testmethod void testNewFundRequest_GBP_USD_IsAtThreshold() {
        insert newFundRequest(newMDF('GBP', 100.00), 'USD', convert('GBP', 'USD', 100.00));
    }

    public static testmethod void testNewFundRequest_GBP_USD_IsAboveThreshold() {
        insert newFundRequest(newMDF('GBP', 100.00), 'USD', convert('GBP', 'USD', 100.00 * BELOW_FACTOR));
    }

    public static testmethod void testNewFundRequest_GBP_USD_IsAboveThreshold_AboveFudgeFactor() {
        try {
            insert newFundRequest(newMDF('GBP', 100.00), 'USD', convert('GBP', 'USD', 100.00 * ABOVE_FACTOR));
            throw new ExpectedExceptionNotThrownException();
        } catch (System.DmlException e) {
            system.assert(e.getDmlMessage(0).contains('Please ensure the Estimated Red Hat Funding Requested amount is less than the Available Budget.'), e.getMessage());
        }
    }

    public static testmethod void testNewFundRequest_USD_GBP_IsBelowThreshold() {
        insert newFundRequest(newMDF('USD', 100.00), 'GBP', convert('USD', 'GBP', 100.00 * 0.95));
    }

    public static testmethod void testNewFundRequest_USD_GBP_IsAtThreshold() {
        insert newFundRequest(newMDF('USD', 100.00), 'GBP', convert('USD', 'GBP', 100.00));
    }

    public static testmethod void testNewFundRequest_USD_GBP_IsAboveThreshold() {
        insert newFundRequest(newMDF('USD', 100.00), 'GBP', convert('USD', 'GBP', 100.00 * BELOW_FACTOR));
    }

    public static testmethod void testNewFundRequest_USD_GBP_IsAboveThreshold_AboveFudgeFactor() {
        try {
            insert newFundRequest(newMDF('USD', 100.00), 'GBP', convert('USD', 'GBP', 100.00 * ABOVE_FACTOR));
            throw new ExpectedExceptionNotThrownException();
        } catch (System.DmlException e) {
            system.assert(e.getDmlMessage(0).contains('Please ensure the Estimated Red Hat Funding Requested amount is less than the Available Budget.'), e.getMessage());
        }
    }

}