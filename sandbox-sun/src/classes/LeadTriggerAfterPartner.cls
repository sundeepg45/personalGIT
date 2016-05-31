/**
 * This class replaces all after insert and after update lead triggers.  The
 * processTrigger method is invoked by the Lead_After trigger and in turn invokes
 * all the methods of this class.  This gives us a way to control the order in
 * which the code logic is invoked, as well as allowing other class features such
 * as shared data, constant values, and regorious test coverage.
 * <p>
 * The Trigger object should never be directly referenced inside this class, as
 * that would make it impossible to substituting values inside test methods.
 * </p>
 *
 * @author Bill C Riemers <briemers@redhat.com>
 * @version 2012-03-05
 * 2011-09-01 - Created
 * 2012-03-05 - Split into a subclass
 */
public without sharing class LeadTriggerAfterPartner extends LeadTriggerAfter {
	/** BooleanSetting__c key to enable the partnerConvertAgreements trigger method. */
	public static final String PARTNER_CONVERT_AGREEMENTS_SETTING = 'Lead_After.partnerConvertAgreements';
	/** BooleanSetting__c key to enable the partnerOnboardingApproved trigger method. */
	public static final String PARTNER_ONBOARDING_APPROVED_SETTING = 'Lead_After.partnerOnboardingApproved';
	/** Set of all the BooleanSetting__c keys used. */
	public static final Set<String> booleanSettingKeys = new Set<String> {
		PARTNER_CONVERT_AGREEMENTS_SETTING,
		PARTNER_ONBOARDING_APPROVED_SETTING };

	/** partner record types and map by name */
	public static final Map<String, Id> PARTNER_RECORD_TYPE_BY_NAME = new Map<String, Id> {
		'NA Partner' => '012600000004yfaAAA',
		'EMEA Partner' => '012600000004yfVAAQ',
		'LATAM Partner' => '0126000000053LWAAY',
		'APAC Partner' => '012600000004yfQAAQ' };

	/**
	 * This constructor is normally called from the processTrigger method and
	 * test methods.
	 */
	public LeadTriggerAfterPartner(Map<Id,Lead> xoldMap,Map<Id,Lead> xnewMap) {
		super(xoldMap,xnewMap);
	}

	/**
	 * Converts leads and return a map of lead Id's to account Id's.  Any failed
	 * conversion has an error added and is removed from the list.
	 *
	 * @param leads the list of leads to convert
	 * @returns a map of account ids mapped by lead ids
	 */
	public Map<Id,Id> convertLeads(List<Lead> leads) {
		Map<Id,Id> accountIdByLeadId = new Map<Id,Id>();
		if(! leads.isEmpty()) {
			List<Database.LeadConvert> leadConverts = new List<Database.LeadConvert>();
			for(Lead lead : leads) {
				Database.LeadConvert leadConvert = new Database.LeadConvert();
				leadConvert.setConvertedStatus('Converted');
				leadConvert.setDoNotCreateOpportunity(true);
				leadConvert.setLeadId(lead.Id);
				leadConvert.setSendNotificationEmail(false);
				leadConvert.setAccountId(lead.Account__c); // merge into account
				leadConverts.add(leadConvert);
			}
			// Execute the conversion
			for(Database.LeadConvertResult lcr : Database.convertLead(leadConverts,false)) {
				Lead lead = leads.remove(0);
				if(lead != null) {
					if (lcr.isSuccess()) {
						leads.add(lead);
						Id accountId = lcr.getAccountId();
						if(accountId != null) {
							accountIdByLeadId.put(lead.Id,accountId);
						}
					}
					else {
						hasErrors = addErrorsToLead(lead.Id,newMap,'Lead conversion failed: '+ lead.Id,lcr.getErrors(),hasErrors);
					}
				}
			}
		}
		return accountIdByLeadId;
	}

	/**
	 * Caled to update accounts.  If an error occurs, the message is added to the repective lead.
	 *
	 * @param accounts list of accounts to update
	 * @param leads list of leads the accounts were updated from.
	 * @param accountIdByLeadId map of account ids by lead id to map the two lists together.
	 * @returns the list of leads which have not had an error message added to it
	 */
	public List<Lead> updateAccountsForLeads(List<Account> accounts,List<Lead> leads,Map<Id,Id> accountIdByLeadId) {
		List<Lead> retval = new List<Lead>();
		if(! accounts.isEmpty()) {
			Map<Id,Database.SaveResult> saveResultByAccountId = new Map<Id,Database.SaveResult>();
			for(Database.SaveResult sr : Database.update(accounts,false)) {
				Account a = accounts.remove(0);
				if(! sr.isSuccess()) {
					saveResultByAccountId.put(a.Id,sr);
				}
			}
			for(Lead lead : leads) {
				Database.SaveResult sr = saveResultByAccountId.get(accountIdByLeadId.get(lead.Id));
				if(sr != null) {
					hasErrors = addErrorsToLead(lead.Id,newMap,'Unable to update account for lead '+lead.Id,sr.getErrors(),hasErrors);
				}
				else {
					retval.add(lead);
				}
			}
		}
		return retval;
	}

	/**
	 * This replacement to the Lead_PartnerOnboardingApproved trigger auto-converts
	 * approved onboarding leads and updates the respective accounts with partner
	 * status records.
	 */
	public void partnerOnboardingApproved() {
		if(isUpdate) {
			// Build a list of only the leads that were just approved and need to be converted
			List<Lead> leads = new List<Lead>();
			for(Lead lead : newMap.values()) {
				if (lead.IsConverted != true && lead.Partner_Onboarding_Status__c == 'Approved' && oldMap.get(lead.Id).Partner_Onboarding_Status__c != 'Approved') {
					leads.add(lead);
				}
			}

			Map<Id,Id> accountIdByLeadId = convertLeads(leads);
			if(! accountIdByLeadId.isEmpty()) {
				// Query accounts to update
				Map<Id, Account> accountMap = new Map<Id, Account>([
					select Id from Account
					where Id in :accountIdByLeadId.values() and IsPartner != true]);

				Set<String> countries = new Set<String>();
				for(Lead lead : leads) {
					if(lead.country != null && accountMap.containsKey(accountIdByLeadId.get(lead.Id))) {
						countries.add(lead.country.toUpperCase());
					}
				}

				// Pre-fetch the list of countries and their associated global region
				Map<String, String> globalRegionMap = new Map<String, String>();
				if(! countries.isEmpty()) {
					for(Country__c country : [
							select
								Abbreviation__c,
								Global_Region__c
							from Country__c
							where Abbreviation__c in :countries
							order by Global_Region__c ] )
					{
						globalRegionMap.put(country.Abbreviation__c.toUpperCase(), country.Global_Region__c.toUpperCase());
					}
				}

				//
				// Update each non-partner account with the correct record type, and enable as a partner
				//
				List<Account> accountList = new List<Account>();
				for(Lead lead : leads) {
					Account account = accountMap.get(accountIdByLeadId.get(lead.Id));
					if (account != null) {
						// update the account
						account.AccountClassification__c = 'Partner - Ready Partner';
						account.IsPartner = true;
						account.MigrationSource__c = 'Onboarded';
						account.Data_Status__c = 'Locked';
						account.Partner_Type__c = lead.Partner_Type_Name__c;
						String recordTypeName = globalRegionMap.get(lead.Country)+' Partner';
						Id recordTypeId = PARTNER_RECORD_TYPE_BY_NAME.get(recordTypeName);
						AccountRecordType__c acr = AccountRecordType__c.getInstance(recordTypeName);
						if(acr != null) {
							recordTypeId = acr.RecordTypeId__c;
						}
						if(recordTypeId != null) {
							account.RecordTypeId = recordTypeId;
						}
						account.Is_Primary_Public_Sector__c = lead.Is_Primary_Public_Sector__c;
						account.Public_Sector_Market__c = lead.Public_Sector_Market__c;
						if(lead.Global_Region__c == 'EMEA') {
							account.Is_Partner_Published__c = false;
						}
						// add to the update list
						accountList.add(account);
					}
				}

				leads = updateAccountsForLeads(accountList,leads,accountIdByLeadId);

				// Cached list to add parter statuses
				List<PartnerStatus__c> partnerStatusList = new List<PartnerStatus__c>();
				List<Lead> leadPartnerStatusSequence = new List<Lead>();
				Date thisYear = Date.today();
				//Date nextYear = thisYear.addYears(1);
				for(Lead lead : leads) {
					// Only add partner statuses and services messages when not joining to an exiting partner
					if (lead.Account__c == null) {
						Id accountId = accountIdByLeadId.get(lead.Id);
						if(accountId != null) {
							// Sync : Insert Partner Statuses
							partnerStatusList.add( new PartnerStatus__c(
								ActivationDate__c = thisYear,
								//ExpirationDate__c = nextYear,
								ExpirationDate__c = null,
								ApprovalStatus__c = 'Approved',
								IsVisible__c = (RedHatObjectReferences__c.getInstance('PARTNER_TYPE.ISV') != null),
								Partner__c = accountId,
								PartnerTier__c = lead.Partner_Tier__c,
								PartnerType__c = lead.Partner_Type__c) );
							leadPartnerStatusSequence.add(lead);
						}
					}
				}

				if (! partnerStatusList.isEmpty()) {
					for(Database.SaveResult sr : Database.insert(partnerStatusList,false)) {
						Lead lead = leadPartnerStatusSequence.remove(0);
						hasErrors = addErrorsToLead(lead.Id,newMap,'Unable to add PartnerStatus__c for lead '+lead.Id,sr.getErrors(),hasErrors);
					}
				}

				// If there is even a single error, then the trigger gets rolled back and runs again, without the
				// records that had problems.  So there is no need to make the future calls when an error has occured.
				if(! hasErrors) {
					Set<Id> leadConvertedIds = new Map<Id,Lead>(leads).keySet();

					// Future : Convert the Lead/Contact to a Partner User
					OnboardingExecuteConversion.convertContactToUserFuture(leadConvertedIds);

					// Not Future : Update the agreement to use the current account
					OnboardingExecuteConversion.convertPartnerAgreements(leadConvertedIds);

					// Future: Create service messages
					//NFRCreateOnOnboarding.createNFRNotFuture(new Set<Id>(accountIdByLeadId.values()));
				}
			}
		}
	}

	/**
	 * This replacement to the Lead_PartnerConvertAgreements trigger calls
	 * the OnboardingExecuteConversion.convertPartnerAgreementsFuture for
	 * partner onboarding approved converted leads.
	 */
	public void partnerConvertAgreements() {
		// If there is even a single error, then the trigger gets rolled back and runs again, without the
		// records that had problems.  So there is no need to make the future calls when an error has occured.
		if(isUpdate && ! hasErrors) {
			Set<Id> leadConvertedIds = new Set<Id>();
			for(Lead lead : newMap.values()) {
				if (lead.IsConverted == true && lead.Partner_Onboarding_Status__c == 'Approved' && oldMap.get(lead.Id).IsConverted != true) {
					leadConvertedIds.add(lead.Id);
				}
			}
			if (! leadConvertedIds.isEmpty()) {
				OnboardingExecuteConversion.convertPartnerAgreements(leadConvertedIds);
			}
		}
	}


	/**
	 * This method is called from the Lead_After trigger to invoke all the methods
	 * of this class, to obsolete the need for individual after triggers.  The primary
	 * reason to place all the triggers in a class is so we control the order in which
	 * the triggers are invoked.
	 *
	 * @param xoldMap the immutable map of previous Lead objects as in Trigger.oldMap.
	 * @param xnewMap the immutable map of new Lead objects as in Trigger.newMap
	 */
	public static void processTrigger(Map<Id,Lead> xoldMap,Map<Id,Lead> xnewMap) {
		final LeadTriggerAfterPartner afterTrigger = new LeadTriggerAfterPartner(xoldMap,xnewMap);
		if(LeadTriggerAfter.booleanSettingMap.get(PARTNER_ONBOARDING_APPROVED_SETTING) != false) {
			afterTrigger.partnerOnboardingApproved();
		}
		if(LeadTriggerAfter.booleanSettingMap.get(PARTNER_CONVERT_AGREEMENTS_SETTING) != false) {
			afterTrigger.partnerConvertAgreements();
		}
	}
}