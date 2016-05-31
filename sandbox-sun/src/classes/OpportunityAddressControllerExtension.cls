/**
 * Controller Extension used for Opportunity Addresses.
 *
 * @author Maybe: Bill Riemers <briemers@redhat.com>
 * 
 * @version 2012-05-17
 * Modified: Bill Riemers <briemers@redhat.com>
 * 2012-05-17 - refactored to a separate class, updated for SMR
 */
public with sharing class OpportunityAddressControllerExtension {
	private final Opportunity opportunity;

	public OpportunityAddressControllerExtension(ApexPages.StandardController stdController)
	{
		opportunity = (Opportunity)stdController.getRecord();
	}

	public List<NonPrimaryBillingAddress__c> nonPrimaryBillingAddressList
	{
		get {
			if(nonPrimaryBillingAddressList == null)
			{
				nonPrimaryBillingAddressList = [
					select 
						Account__r.Name,
						BillingAddress__c,
						BillingCity__c,
						BillingState__c,
						BillingZipPostalCode__c,
						BillingCountry__c,
						ASIDBT__c,
						CurrencyIsoCode
					from NonPrimaryBillingAddress__c
					where Account__c = :opportunity.Account.Id
					order by BillingCountry__c, BillingState__c, BillingCity__c, BillingAddress__c ];
				nonPrimaryBillingAddressList.addAll([
					select 
						Account__r.Name,
						BillingAddress__c,
						BillingCity__c,
						BillingState__c,
						BillingZipPostalCode__c,
						BillingCountry__c,
						ASIDBT__c,
						CurrencyIsoCode
					from NonPrimaryBillingAddress__c
					where Account__c in :getBillingAccountIds()
					order by Account__r.Name, BillingCountry__c, BillingState__c, BillingCity__c, BillingAddress__c ]);
			}
			return nonPrimaryBillingAddressList;
		}
		set;
	}

	public List<Account> getShippingAccountList()
	{
		return getAccountList(getShippingAccountIds());
	}

	public List<Account> getBillingAccountList()
	{
		return getAccountList(getBillingAccountIds());
	}

	private List<Account> getAccountList(Set<Id> accountIds)
	{
		List<Account> accountList = [
			select
				Name,
				ShippingStreet,
				ShippingCity,
				ShippingState,
				ShippingPostalCode,
				ShippingCountry,
				BillingStreet,
				BillingCity,
				BillingState,
				BillingPostalCode,
				BillingCountry,
				ASIDST__c,
				ASIDBT__c,
				CurrencyIsoCode
			from Account where Id in :accountIds
		];
		return accountList;
	}

	private Set<Id> getShippingAccountIds() {
		Set<Id> accountIds = new Set<Id>();
		for(OpportunityPartner__c opportunityPartner : [
			select Partner__c
			from OpportunityPartner__c
			where Opportunity__c = :opportunity.Id and Partner__c != :opportunity.Account.Id ])
		{
			accountIds.add(opportunityPartner.Partner__c);
		}
		return accountIds;
	}

	private Set<Id> getBillingAccountIds() {
		Set<Id> accountIds = new Set<Id>();
		for(OpportunityPartner__c opportunityPartner : [
			select Partner__c
			from OpportunityPartner__c
			where RelationshipType__c = 'FINANCIAL' and Opportunity__c = :opportunity.Id and Partner__c != :opportunity.Account.Id ])
		{
			accountIds.add(opportunityPartner.Partner__c);
		}
		return accountIds;
	}

	public List<NonPrimaryShippingAddress__c> nonPrimaryShippingAddressList
	{
		get {
			if(nonPrimaryShippingAddressList == null)
			{
				nonPrimaryShippingAddressList = [
					select
						Account__r.Name,
						ShippingAddress__c,
						ShippingCity__c,
						ShippingState__c,
						ShippingZipPostalCode__c,
						ShippingCountry__c,
						ASIDST__c,
						CurrencyIsoCode
					from NonPrimaryShippingAddress__c
					where Account__c = :opportunity.Account.Id
					order by ShippingCountry__c, ShippingState__c, ShippingCity__c, ShippingAddress__c ];
				nonPrimaryShippingAddressList.addAll([
					select 
						Account__r.Name,
						ShippingAddress__c,
						ShippingCity__c,
						ShippingState__c,
						ShippingZipPostalCode__c,
						ShippingCountry__c,
						ASIDST__c,
						CurrencyIsoCode
					from NonPrimaryShippingAddress__c
					where Account__c in :getShippingAccountIds()
					order by Account__r.Name, ShippingCountry__c, ShippingState__c, ShippingCity__c, ShippingAddress__c ]);
				
			}
			return nonPrimaryShippingAddressList;
		}
		set;
	}
}