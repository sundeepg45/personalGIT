/**
 * This is a controller extension of the Account_Profile_Other_Partner__c class to
 * create or edit Account_Profile_Other_Partner__c records.
 *
 * @author Scott Coleman <scoleman@redhat.com>
 * @version 2013-01-21
 * 2013-01-21 - Created
 */
public with sharing class AccountProfileOtherPartner_ContExtn {
	/** Custom setting name for the field Id of Account_Profile_Power_Map.Account__c */
	public static final String ACCOUNT_PROFILE_FIELD_KEY = 'OtherPartner.AccountProfileCF';	
	public final ApexPages.StandardController controller;
	private final String returnURL;
	private final String accountProfileId;
	private final String accountProfileName;

	public AccountProfileOtherPartner_ContExtn(ApexPages.StandardController stdController) {
		controller = stdController;
		returnURL = ApexPages.currentPage().getParameters().get('retURL');
		accountProfileId = ApexPages.currentPage().getParameters().get('CF'+accountProfileFieldId+'_lkid');
		accountProfileName = ApexPages.currentPage().getParameters().get('CF'+accountProfileFieldId);
	}

	/** The field Id for Account_Profile_Other_Partner__c.Account_Profile__c */
	public String accountProfileFieldId {
		get {
			if (accountProfileFieldId == null) {
				accountProfileFieldId = StringSetting__c.getInstance(ACCOUNT_PROFILE_FIELD_KEY).Value__c;
			}
			// we can replace this with a hardcoded value once the code has been deployed in prod
			return accountProfileFieldId;
		}
		private set{}
	}

	public List<SelectOption> getPartnerTypeList() {
		List<SelectOption> partnerTypeList = new List<SelectOption>();
		partnerTypeList.add(new SelectOption('','--None--'));
		List<Classification__c> classifications = [SELECT Id,Name FROM Classification__c WHERE HierarchyKey__c LIKE 'PARTNER_TYPE%' AND HierarchyDepth__c = 2 AND IsActive__c = true ORDER BY Name ASC NULLS FIRST];
		for(Classification__c classification : classifications) {
			partnerTypeList.add(new SelectOption(classification.Id,classification.Name));
		}
		return partnerTypeList;
	}

	public PageReference saveAndReturn() {
		try {
			PageReference returnPage = controller.save();
			if (returnURL != null) {
				returnPage = new PageReference(returnURL);
				returnPage.setAnchor('AccountObjectives_target');
				returnPage.setRedirect(true);
			}
			return returnPage;			
		}
		catch (Exception ex) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, ex.getMessage()));
			return null;
		}
	}

	public PageReference saveAndNew() {
		try {	
			controller.save();
			Schema.DescribeSObjectResult describeResult = controller.getRecord().getSObjectType().getDescribe();
            PageReference returnPage = new PageReference('/' + describeResult.getKeyPrefix() + '/e?CF'+accountProfileFieldId+'_lkid='+accountProfileId+'&CF'+accountProfileFieldId+'='+accountProfileName+'&retURL='+returnURL);
            returnPage.setRedirect(true);
			return returnPage;
		}
		catch (Exception ex) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, ex.getMessage()));
			return null;
		}
	}

	public PageReference cancelAndReturn() {
		try {
			PageReference returnPage = controller.cancel();
			if (returnURL != null) {
				returnPage = new PageReference(returnURL);
				returnPage.setAnchor('AccountObjectives_target');
				returnPage.setRedirect(true);
			}		
			return returnPage;			
		}
		catch (Exception ex) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, ex.getMessage()));
			return null;
		}
	}
}