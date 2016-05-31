/**
 * This class is a set of unit tests for the AccountProfile_PS_SetController class.
 *
 * @author Bill C Riemers <briemers@redhat.com>
 * @version 2013-01-07
 * 2012-01-07 - created
 */
@isTest
public class AccountProfile_PS_ControllerExtnTest {
	static List<Account> accounts {
		get {
			if(accounts == null) {
				RecordType recordType = [select Id,name from RecordType where name like '% Partner' and SObjectType = 'Account' limit 1];
				accounts = new List<Account>{
					new Account(
						Name='customer',
						RecordTypeId=recordType.Id,
						AccountClassification__c=recordType.Name,
						BillingCountry = 'US'),
					new Account(
						Name='reseller',
						RecordTypeId=recordType.Id,
						AccountClassification__c=recordType.Name,
						BillingCountry = 'US') };
				insert accounts;
				accounts[0].RecordType = recordType;
				accounts[1].RecordType = recordType;
			}
			return accounts;
		}
	}

	static Account customer {
		get { return accounts[0]; }
	}

	static Account reseller {
		get { return accounts[1]; }
	}

	static Opportunity opportunity {
		get {
			if(opportunity == null) {
				User xuser = new User(Id=UserInfo.getUserId());
				RecordType recordType2 = [select Id,name from RecordType where name like 'EMEA %' and SObjectType = 'Opportunity' limit 1];
				opportunity = new Opportunity(Name='Opportunity_ManagePartnersTest Test',
					CloseDate=System.today(),StageName='Prepare',//changed the opportunity stagename value to Prepare as part of Value Selling enhancement.July 20th release
					Owner=xuser,// DateOrderSubmitted__c=Datetime.newInstance(2009,1,1),
					AccountId=customer.Id,
					Country_of_Order__c='India',
					FulfillmentChannel__c='Direct - OEM',
					RecordTypeId = recordType2.Id);
				insert opportunity;
				opportunity.Account = customer;
				opportunity.RecordType = recordType2;
			}
			return opportunity;
		}
	}

	static PartnerStatus__c partnerStatus {
		get {
			if(partnerStatus == null) {
				Classification__c pType = new Classification__c(Name='Partner Type');
				Classification__c pTier = new Classification__c(Name='Partner Tier');
				for(Classification__c c : [
					select Name 
					from Classification__c 
					where Name in ('Partner Type','Partner Tier') 
						and Parent__c = null])
				{
					if(c.Name == 'Partner Type') {
						pType = c;
					}
					else if(c.Name == 'Partner Tier')
					{
						pTier = c;
					}
				}
				if(pType.Id == null || pTier.Id == null) {
					upsert new List<Classification__c>{pType,pTier};
				}
				Classification__c cTier = new Classification__c(Name='Child Tier',Parent__c=pTier.Id);
				Classification__c cType = new Classification__c(Name='Child Type',Parent__c=pType.Id);
				insert new List<Classification__c>{cTier,cType};
				// this is a sad story...
				List<RedHatObjectReferences__c> rhors = new List<RedHatObjectReferences__c>{
					new RedHatObjectReferences__c(
						Name='PARTNER_TYPE.ISV',
						ObjectId__c=cType.Id),
					new RedHatObjectReferences__c(
						Name='PARTNER_TIER.ADVANCED',
						ObjectId__c=cTier.Id) };
				upsert rhors;
				partnerStatus = new PartnerStatus__c(
					ActivationDate__c = Date.today().addDays(-1),
					ApprovalStatus__c = 'Approved',
					ExpirationDate__c = Date.today().addDays(7),
					Partner__c = reseller.Id,
					PartnerTier__c = cTier.Id,
					PartnerType__c = cType.Id);
				insert partnerStatus;
				partnerStatus.Partner__r = reseller;
				partnerStatus.PartnerTier__r = cTier;
				partnerStatus.PartnerType__r = cType;
			}
			return partnerStatus;
		}
	}

	static OpportunityPartner__c oppPartner {
		get {
			if(oppPartner == null)
			{
				System.debug('opportunity.Id='+opportunity.Id);
				System.debug('partnerStatus.Id='+partnerStatus.Id);
				oppPartner = new OpportunityPartner__c(
					Opportunity__c = opportunity.Id,
					Partner__c = partnerStatus.Partner__c,
					PartnerTier__c = partnerStatus.PartnerTier__c,
					PartnerType__c = partnerStatus.PartnerType__c,
					RelationshipType__c = 'Reseller 1');
				insert oppPartner;
				oppPartner.Opportunity__r = opportunity;
				oppPartner.Partner__r = partnerStatus.Partner__r;
				oppPartner.PartnerType__r = partnerStatus.PartnerType__r;
				oppPartner.PartnerTier__r = partnerStatus.PartnerTier__r;
			}
			return oppPartner;
		}
	}

	public static Account_Profile__c accountProfile {
		get {
			if(accountProfile == null) {
				accountProfile = new Account_Profile__c(
					Account__c = oppPartner.Opportunity__r.AccountId);
				insert accountProfile;
			}
			return accountProfile;
		}
	}

	static AccountProfile_PS_ControllerExtension controller {
		get {
			if(controller == null) {
				ApexPages.StandardController sc = new ApexPages.StandardController(accountProfile);
				controller = new AccountProfile_PS_ControllerExtension(sc);
			}
			return controller;
		}
	}

	@isTest
	static void testController() {
		System.assertEquals(0,controller.getPartnerStatuses().size());
		AccountProfile_PS_ControllerExtension.PartnerStatus ps = new AccountProfile_PS_ControllerExtension.PartnerStatus(
			new AccountProfile_PartnerStatus__c(
				Account_Profile__c=accountProfile.Id,
				PartnerStatus__c = partnerStatus.Id),
			partnerStatus);
		System.assertEquals(partnerStatus.Id,ps.partnerStatus.Id);
		System.assertEquals(null,ps.accountProfile_PartnerStatus.Id);
		ps.addPartnerStatus();
		System.assertNotEquals(null,ps.accountProfile_PartnerStatus.Id);
		System.assertEquals(1,controller.getPartnerStatuses().size());
		ps.deletePartnerStatus();
		System.assertEquals(0,controller.getPartnerStatuses().size());
		// coverage
		System.assertNotEquals(null,controller.managePreferredPartners());
	}

	@isTest
	static void testFailures() {
		// failure coverage test
		AccountProfile_PS_ControllerExtension.PartnerStatus ps = new AccountProfile_PS_ControllerExtension.PartnerStatus(
			new AccountProfile_PartnerStatus__c(
				Account_Profile__c= null,
				PartnerStatus__c = null),
			null);
		ps.addPartnerStatus();
		ps.deletePartnerStatus();
	}
}