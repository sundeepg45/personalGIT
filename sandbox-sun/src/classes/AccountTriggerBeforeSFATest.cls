/**
 * This class contains unit tests for validating the AccountTriggerBeforeSFA class.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * @author Bill C Riemers <briemers@redhat.com>
 * @version 2014-04-22
 * 2012-05-18 - created
 * Scott Coleman <scoleman@redhat.com>
 * 2014-04-22 - Add test for validateEligibleForDistiAnnualPay()
 * 2012-10-22 - Added mapping of Named Account to Account Classification
 */
@isTest
private class AccountTriggerBeforeSFATest {
	static final String SUPER_REGION = 'EMEA';
	static final String SUPER_REGION2 = 'NA';

	static RecordType preferredRecordType {
		get {
			if(preferredRecordType == null) {
				preferredRecordType = [
					select Id,Name
					from RecordType
					where Name like :(SUPER_REGION+' %')
						and SObjectType = 'Account'
						and IsActive = true
					order by Name
					limit 1 ];
			}
			return preferredRecordType;
		}
	}

	static Map<String,RecordTypeInfo> accountRecordTypeByNameMap {
		get {
			if(accountRecordTypeByNameMap == null) {
				accountRecordTypeByNameMap = Schema.SObjectType.Account.getRecordTypeInfosByName();
			}
			return accountRecordTypeByNameMap;
		}
	}

	@isTest(SeeAllData=true) // need all data to access custom settings
	static void customSettingTest() {
		StringSetting__c defaultRecordTypeId = StringSetting__c.getInstance('Account.DefaultRecordTypeId');
		System.assertNotEquals(null,defaultRecordTypeId,'Custom String setting Account.DefaultRecordTypeId has not been defined');
		Boolean found = false;
		for(RecordType rt : [
			select Id,name
			from RecordType
			where Id = :defaultRecordTypeId.Value__c
				and SObjectType = 'Account'
			limit 1 ] )
		{
			found = true;
		}
		System.assert(found,'No record type was found with an Id value of Account.DefaultRecordTypeId = '+defaultRecordTypeId.Value__c);
	}

	@isTest
	static void assignLegacyTest() {
		AbstractTriggerTest.assignLegacyTest(new AccountTriggerBeforeSFA(null,new List<Account>{AccountTriggerBeforeTest.createAccount()}));
	}
	
	@isTest
	static void setNamedAccountTest() {
		Account account = AccountTriggerBeforeTest.createAccount(accountRecordTypeByNameMap.get('APAC Account').getRecordTypeId());
		account.AccountClassification__c = 'Duplicate Account - Delete';
		AccountTriggerBeforeSFA triggerBefore = new AccountTriggerBeforeSFA(null,new List<Account>{account});
		triggerBefore.setNamedAccount();
		System.assert(!account.Named_Account__c);
		Account account2 = account.Clone();
		account2.AccountClassification__c = 'Sales - Global';
		triggerBefore = new AccountTriggerBeforeSFA(new Map<Id,Account>{null=>account},new List<Account>{account2});
		triggerBefore.setNamedAccount();
		System.assert(account2.Named_Account__c);
		account2.AccountClassification__c = 'Sales - Territory';
		triggerBefore = new AccountTriggerBeforeSFA(new Map<Id,Account>{null=>account},new List<Account>{account2});
		triggerBefore.setNamedAccount();
		System.assert(account2.Named_Account__c);
	}

	@isTest(SeeAllData=false) // we create the custom settings needed
	static void assignRecordTypeTest() {
		Account account = AccountTriggerBeforeTest.createAccount();
		insert new TestingIds__c(
			Name='Sales User Profile',
			Id__c=(''+UserInfo.getProfileId()).substring(0,15) );
		DefaultRecordTypes__c dfrt = DefaultRecordTypes__c.getInstance();
		dfrt.GlobalAs__c=SUPER_REGION;
		dfrt.PreferredAccountRecordType__c='oatuehaseouthaseuth';
		dfrt.PreferredOpportunityRecordType__c='Like it matters.';
		dfrt.SecondaryAccountRecordType__c='%r'+preferredRecordType.Name.substring(SUPER_REGION.length());
		dfrt.SecondaryOpportunityRecordType__c='Who cares?';
		upsert dfrt;
		Id recordTypeId = '012000000000000AAA';
		StringSetting__c defaultRecordTypeId = new StringSetting__c(
			Name='Account.DefaultRecordTypeId',
			Value__c=recordTypeId);
		insert new StringSetting__c(
			Name='Account.DefaultRecordTypeId',
			Value__c=recordTypeId);
		account.RecordTypeId = recordTypeId;
		AccountTriggerBeforeSFA triggerBefore = new AccountTriggerBeforeSFA(null,new List<Account>{account});
		triggerBefore.currentUser.Region__c = 'GLOBAL';
		RecordTypeAssignment__c rta = new RecordTypeAssignment__c(
			ManagedProfiles__c = triggerBefore.currentUser.Profile.Name,
			Object_Label__c = 'Account',
			RecordType__c = preferredRecordType.Name,
			Super_Region__c = 'GLOBAL');
		insert rta;
		// testing assignment from the secondary value
		triggerBefore.assignRecordType();
		System.assertEquals(preferredRecordType.Id,account.recordTypeId);
		account.RecordTypeId = recordTypeId;
		dfrt.SecondaryAccountRecordType__c='aoetuhaseouthshs';
		update dfrt;
		triggerBefore = new AccountTriggerBeforeSFA(null,new List<Account>{account});
		triggerBefore.currentUser.Region__c = 'GLOBAL';
		// testing failure case
		triggerBefore.assignRecordType();
		System.assertEquals(recordTypeId,account.recordTypeId);
		dfrt.PreferredAccountRecordType__c='%r'+preferredRecordType.Name.substring(SUPER_REGION.length());
		update dfrt;
		triggerBefore = new AccountTriggerBeforeSFA(null,new List<Account>{account});
		triggerBefore.currentUser.Region__c = 'GLOBAL';
		// testing assignment from preferred value
		triggerBefore.assignRecordType();
		System.assertEquals(preferredRecordType.Id,account.recordTypeId);
	}

	@isTest
	static void validateEligibleForDistiAnnualPayTest() {

		Group naChannelOpsGroup = [
			SELECT
				Id,
				Name,
				DeveloperName,
				Type
			FROM Group
			WHERE DeveloperName = 'NAChannelOps' 
			LIMIT 1 ];

		if(naChannelOpsGroup == null) {
			naChannelOpsGroup = new Group(
				Name = 'NA Channel Ops', 
				DeveloperName = 'NAChannelOps', 
				Type = 'Regular');
			insert naChannelOpsGroup;
		}

		Account account = AccountTriggerBeforeTest.createAccount();
		account.Eligible_for_Disti_Annual_Pay_Program__c = true;

		// test attempt to insert with flag set without being in NA Channel Ops public group
		AccountTriggerBeforeSFA triggerBefore = new AccountTriggerBeforeSFA(null,new List<Account>{account});
		triggerBefore.hasErrors = false;
		triggerBefore.validateEligibleForDistiAnnualPay();
		System.assert(triggerBefore.hasErrors);

		// add current user to public group
		GroupMember naChannelOpsGroupMember = new GroupMember(
			UserOrGroupId=UserInfo.getUserId(),
			GroupId=naChannelOpsGroup.Id);
		insert naChannelOpsGroupMember;

		// test attempt to insert with flag set now that I'm a member of the group
		triggerBefore.hasErrors = false;
		triggerBefore.validateEligibleForDistiAnnualPay();
		System.assert(!triggerBefore.hasErrors);

		// test update
		Account updatedAccount = account.Clone(true);
		updatedAccount.Eligible_for_Disti_Annual_Pay_Program__c = false;
		triggerBefore = new AccountTriggerBeforeSFA(new Map<Id,Account>{account.Id=>account},new List<Account>{updatedAccount});
		triggerBefore.hasErrors = false;
		triggerBefore.validateEligibleForDistiAnnualPay();
		System.assert(!triggerBefore.hasErrors);
	}
}