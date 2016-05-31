/**
 * This class contains unit tests for validating the behavior of 
 * ContractTriggerBefore.cls
 *
 * @version 2014-01-17
 * @author Scott Coleman <scoleman@redhat.com>
 * 2012-06-01 - Created
 * Bill Riemers <briemers@redhat.com>
 * 2014-01-17 - Updated assignRegionsTest
 * 2013-12-12 - Added assignRegionsTest method
 */
@isTest
private class ContractTriggerBeforeTest {
	static final String accountRecordTypeName = 'EMEA Account';

	public static Account emeaAccount {
		get {
			if(emeaAccount == null) {
				RecordType recordType = [
					select name
					from RecordType
					where name = :accountRecordTypeName
						and SObjectType = 'Account'
						and IsActive = true
					limit 1 ];
				emeaAccount = new Account(
					RecordTypeId = recordType.Id,
					BillingCity = 'Raleigh',
					BillingCountry = 'US',
					BillingPostalCode = '27606',
					BillingState = 'North Carolina',
					BillingStreet = '1801 Varsity Drive',
					CurrencyIsoCode = 'USD',
					Name = 'Red Hat',
					PrimaryBillingAccountNumber__c = '12345',
					OracleAccountNumber__c = '12345',
					OraclePartyNumber__c = '12345',
					ShippingCity = 'Raleigh',
					ShippingCountry = 'US',
					ShippingPostalCode = '27606',
					ShippingState = 'North Carolina',
					ShippingStreet = '1801 Varsity Drive',
					SubTerritory__c= 'Federal',
					Territory1__c='Canada',
					VATNumber__c = '67890',
					Vertical__c = 'Education');
			}
			return emeaAccount;
		}
	}

	static Id getEMEAAccountId() {
		if(emeaAccount.Id == null) {
			insert emeaAccount;
		}
		return emeaAccount.Id;
	}

	static Region__c region {
		get {
			if(region == null) {
				region = new Region__c(
					Name='Fantasia',
					Country__c = 'Narnia',
					Sub_Region__c = 'Fantasy Land',
					Region__c = 'Fiction',
					Super_Region__c='EMEA');
			}
			return region;
		}
	}

	static Id getRegionId() {
		if(region.Id == null) {
			insert region;
		}
		return region.Id;
	}

	static Opportunity opportunity {
		get {
			if(opportunity == null) {
				opportunity = new Opportunity(
					Name='Opportunity Test',
					CurrencyIsoCode=emeaAccount.CurrencyIsoCode,
					CloseDate=System.today(),
					ContractStartDate__c = System.today().addDays(1),
					Embedded__c = false,
					EmbeddedOverridden__c = 0,
					StageName='Unqualified',
					OwnerId=UserInfo.getUserId(),
					AccountId=getEMEAAccountId(),
					Country_of_Order__c=region.Country__c,
					FulfillmentChannel__c='Direct - OEM',
					PrimaryBusinessUnit__c=null,
					POC_Status__c=null);
			}
			return opportunity;
		}
	}

	static Id getOpportunityId() {
		if(opportunity.Id == null) {
			insert opportunity;
		}
		return opportunity.Id;
	}

	static Contract contract {
		get {
			if (contract == null) {
				contract = new Contract(
					AccountId = getEMEAAccountId(),
					Opportunity__c = getOpportunityId(),
					OwnerId = UserInfo.getUserId(),
					Owner__c = null);
			}
			return contract;
		}
		set;
	}

	@isTest
	static void assignRegions() {
		getRegionId();
		// Turn off all the triggers, and make sure everything is tested.
		AbstractTrigger.setBooleanSettings('Contract_Before.',false);
		insert contract;
		List<Contract> contractList = [
			select
				CountryOfOrder__c,
				Country_of_Order__c,
				Global__c,
				Sub_Region__c,
				Region__c,
				Super_Region__c
			from Contract
			where Id = :contract.Id ];
		ContractTriggerBefore triggerBefore = new ContractTriggerBefore(
			null,contractList );
		triggerBefore.assignRegions();
		System.assertEquals(region.Country__c,contractList[0].CountryOfOrder__c);
		System.assertEquals(region.Sub_Region__c,contractList[0].Sub_Region__c);
		System.assertEquals(region.Region__c,contractList[0].Region__c);
		System.assertEquals(region.Super_Region__c,contractList[0].Super_Region__c);
		contract.Opportunity__c = null;
		contract.CountryOfOrder__c = null;
		contract.Sub_Region__c = region.Sub_Region__c;
		contract.Region__c = null;
		contract.Super_Region__c = null;
		triggerBefore = new ContractTriggerBefore(
			null,new List<Contract>{contract});
		triggerBefore.assignRegions();
		System.assertEquals(null,contract.CountryOfOrder__c);
		System.assertEquals(null,contract.Sub_Region__c);
		System.assertEquals(null,contract.Region__c);
		System.assertEquals(null,contract.Super_Region__c);
		contract.Sub_Region__c = null;
		contract.Super_Region__c = null;
		triggerBefore.assignRegions();
		System.assertEquals(null,contract.CountryOfOrder__c);
		System.assertEquals(null,contract.Sub_Region__c);
		System.assertEquals(null,contract.Region__c);
		System.assertEquals(null,contract.Super_Region__c);
		contract.Global__c = true;
		contract.CountryOfOrder__c = region.Country__c;
		contract.Sub_Region__c = region.Sub_Region__c;
		contract.Region__c = region.Region__c;
		contract.Super_Region__c = region.Super_Region__c;
		triggerBefore.assignRegions();
		System.assertEquals(null,contract.CountryOfOrder__c);
		System.assertEquals(null,contract.Sub_Region__c);
		System.assertEquals(null,contract.Region__c);
		System.assertEquals(null,contract.Super_Region__c);
	}

	@isTest
	static void assignFieldsFromAccountTest() {
		ContractTriggerBefore triggerBefore = new ContractTriggerBefore(
			null,new List<Contract>{ contract } );
		triggerBefore.assignFieldsFromAccount();
		System.assertEquals(emeaAccount.SubTerritory__c,contract.SubTerritory__c);
		System.assertEquals(emeaAccount.Territory1__c,contract.Territory__c);
		System.assertEquals(emeaAccount.Vertical__c,contract.Vertical__c);
		System.assertEquals(accountRecordTypeName,contract.Account_Record_Type__c);
	}

	@isTest
	static void assignCompletedDate() {
		Contract contract2 = contract.clone();
		contract2.Stage__c = 'Completed';
		ContractTriggerBefore triggerBefore = new ContractTriggerBefore(
			new Map<Id,Contract>{null => contract},new List<Contract>{ contract2 } );
		triggerBefore.assignCompletedDate();
		System.assertNotEquals(null,contract2.Completed_Date__c);
	}

	@isTest // (SeeAllData=true) is not needed anymore because we insert missing settings
	static void processTriggerTest() {
		AbstractTrigger.setBooleanSettings('Contract_Before.',false);
		// insert missing boolean settings
		AbstractTrigger.insertMissing = 0;
		insert contract;
		List<Contract> contracts = new List<Contract>{contract};
		Map<Id,Contract> oldMap = new Map<Id,Contract>{ contract.Id => contract };
		List<Contract> newList = contracts.deepClone(true);
		// Turn on all the triggers, and make sure everything is tested.
		AbstractTrigger.setBooleanSettings('Contract_Before.',true);
		// insert
		AbstractTrigger.insertMissing = 0;
		// Turn on all the triggers, and make sure everything is tested.
		AbstractTrigger.setBooleanSettings('Contract_Before.',true);
		// insert
		ContractTriggerBefore.processTrigger(null,contracts);
		// update
		ContractTriggerBefore.processTrigger(oldMap,newList);
		// delete
		ContractTriggerBefore.processTrigger(oldMap,null);
		// If there were any missing values, our test is invalid
		AbstractTriggerTest.validateSettings('Contract_Before.');
	}

	@isTest
	static void deployTest() {
		AbstractTriggerTest.deployTest('Contract_Before.',new List<Contract>{contract});
	}

}