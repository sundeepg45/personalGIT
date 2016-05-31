public without sharing class TestOutboundServiceController {
    public String message { get; set; }
    public String error { get; set; }
    public String stacktrace { get; set; }


    public String contactId { get; set; }
    public String addressId { get; set; }
    public String accountId { get; set; }
    public String opportunityId { get; set; }
    public String errorMessagePayload { get; set; }
    public String errorCode { get; set; }
    public String errorDescription { get; set; }


	public TestOutboundServiceController() {
		message = null;
        error = null;
        stacktrace = null;

        if (ApexPages.currentPage().getParameters().containsKey('accountId')){
            accountId = ApexPages.currentPage().getParameters().get('accountId');
        }
        if (ApexPages.currentPage().getParameters().containsKey('contactId')){
            contactId = ApexPages.currentPage().getParameters().get('contactId');
        }
        if (ApexPages.currentPage().getParameters().containsKey('addressId')){
            addressId = ApexPages.currentPage().getParameters().get('addressId');
        }
        if (ApexPages.currentPage().getParameters().containsKey('opportunityId')){
            opportunityId = ApexPages.currentPage().getParameters().get('opportunityId');
        }
	}

    public PageReference queueError(){
        message = null;
        error = null;
        try {
            if (errorMessagePayload.trim().length() > 0 && errorCode.trim().length() > 0 && errorDescription.trim().length() > 0){
                OutboundService.queueErrorMessage(errorMessagePayload, errorCode, errorDescription);
                message = 'Error ' + errorCode + ' queued with description "' + errorDescription + '"';
            } else {
                error = 'You must fill out the payload, the code and the description for this to work...';
            }
        } catch (Exception e){
            error = 'An Exception occurred: ' + e.getMessage();
            stacktrace = e.getStackTraceString().replace('\n', '<br/>');
        }

        return null;
    }

    public PageReference queueOpportunityMessage() {
        message = null;
        error = null;
        stacktrace = null;
        accountId = null;
        contactId = null;
        addressId = null;
        try {
            Opportunity opportunity = OutboundSyncSelector.getOpportunityData(opportunityId);
            OutboundService.queueOrderMessage(IntegrationObjectConverter.convertOpportunityToOrder(opportunity), 'TEST_SYNC', 'SingleInsertUpdate');
            message = 'Opportunity named "' + opportunity.Name + '" (' + opportunity.Id + ') has been pushed into the outbound service queue';
            //OrderJSONGenerator.generateOrderJSON(IntegrationObjectConverter.convertOpportunityToOrder(opportunity), true);
        } catch (Exception e){
            error = 'An Exception occurred: ' + e.getMessage();
            stacktrace = e.getStackTraceString().replace('\n', '<br/>');
        }
        return null;
    }

    public PageReference queueContactMessage() {
        message = null;
        error = null;
        stacktrace = null;
        accountId = null;
        opportunityId = null;
        addressId = null;
        try {
            Contact contact = OutboundSyncSelector.getContactData(contactId);
            OutboundService.queueContactMessage(IntegrationObjectConverter.convertContact(contact), 'TEST_SYNC', 'SingleInsertUpdate');
            message = 'Contact named "' + contact.FirstName + ' ' + contact.LastName + '" (' + contact.Id + ') has been pushed into the outbound service queue';
        } catch (Exception e){
            error = 'An Exception occurred: ' + e.getMessage();
            stacktrace = e.getStackTraceString();
        }
        return null;
    }

    public PageReference queueAddressMessage() {
        message = null;
        error = null;
        stacktrace = null;
        accountId = null;
        opportunityId = null;
        contactId = null;
        try {
            Address__c address = [
                SELECT
                    Id,
                    Sales_Account__r.Name,
                    CDH_Party_Site_Number__c,
                    Address_Line1__c,
                    Address_Line2__c,
                    Address_Line3__c,
                    Address_Line4__c,
                    City__c,
                    State__c,
                    Province__c,
                    Zip_Postal_Code__c,
                    County__c,
                    Country__c,
                    Bill_To_Address__c,
                    Sold_To_Address__c,
                    Ship_To_Address__c,
                    Entitle_To_Address__c,
                    Identifying_Address__c,
                    Status__c
                FROM Address__c
                WHERE Id = :addressId
                LIMIT 1
            ];
            OutboundService.queueAddressMessage(IntegrationObjectConverter.convertAddress(address), 'TEST_SYNC', 'SingleInsertUpdate');
            message = 'Address from account "' + address.Sales_Account__r.Name + '" with address id (' + address.Id + ') has been pushed into the outbound service queue';
        } catch (Exception e){
            error = 'An Exception occurred: ' + e.getMessage();
            stacktrace = e.getStackTraceString().replace('\n', '<br/>');
        }
        return null;
    }

    public PageReference queueAccountMessage() {
        message = null;
        error = null;
        stacktrace = null;
        contactId = null;
        opportunityId = null;
        addressId = null;
        try {
            Account account = OutboundSyncSelector.getAccountData(accountId);
            OutboundService.queueAccountMessage(IntegrationObjectConverter.convertSalesAccount(account), 'TEST_SYNC', 'SingleInsertUpdate');
            message = 'Account "' + Account.Name + '" (' + account.Id + ') has been pushed into the outbound service queue';
        } catch (Exception e){
            error = 'An Exception occurred: ' + e.getMessage();
            stacktrace = e.getStackTraceString().replace('\n', '<br/>');
        }
        return null;
    }
}