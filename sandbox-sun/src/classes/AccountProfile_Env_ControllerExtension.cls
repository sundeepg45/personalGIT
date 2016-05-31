/**
 * This is a controller extension of the Account_Profile__c class to
 * view Environment__c records.
 *
 * @author Scott Coleman <scoleman@redhat.com>
 * @version 2013-04-25
 * 2013-04-25 - created
 */
public with sharing class AccountProfile_Env_ControllerExtension {
	/** Custom setting name for the field Id of Account_Profile_Power_Map.Account_Profile__c */
	public static final String ACCOUNT_PROFILE_FIELD_KEY = 'Environment.AccountProfileCF';

	final Account_Profile__c accountProfile;

	/**
	 * Standard controller extension constructor.
	 * @param stdController the StandardController for Account_Profile__c objects.
	 */
	public AccountProfile_Env_ControllerExtension(ApexPages.StandardController stdController) {
		accountProfile=(Account_Profile__c)stdController.getRecord();
	}

	/** The field Id for Environment__c.Account_Profile__c */
	public String accountProfileFieldId {
		get {
			// we can replace this with a hardcoded value once the code has been deployed in prod
			return StringSetting__c.getInstance(ACCOUNT_PROFILE_FIELD_KEY).Value__c;
		}
	}

	/**
	 * Query the list of Environment__c records and return them as a list
	 */
	public List<Environment> getEnvironments() {
		List<Environment> environments = new List<Environment>();
		for(Environment__c environment : [
			select
				Name,
				Account_Profile__c,
				LastModifiedById,
				LastModifiedDate,
				LastModifiedBy.FirstName,
				LastModifiedBy.LastName	
			from Environment__c 
			where Account_Profile__c = :accountProfile.Id
			order by CreatedDate])
		{
			environments.add(new Environment(environment));
		}

		return environments;
	}

	/**
	 * Called to add an Environment__c record.
	 * @return null
	 */
	public PageReference addEnvironment() {
		Schema.DescribeSObjectResult describeResult = Environment__c.sObjectType.getDescribe();
		return new PageReference('/'+describeResult.getKeyPrefix()+'/e?CF'+accountProfileFieldId+'_lkid='+accountProfile.Id+'&CF'+accountProfileFieldId+'='+accountProfile.Name+'&retURL='+accountProfile.Id+'%23Infrastructure_target&saveURL='+accountProfile.Id+'%23Infrastructure_target');
	}

	public class Environment {
		/**
		 * Simple constructor.
		 * @param xaccountProfile_Environment the Environment__c record to manage
		 */
		public Environment(Environment__c xaccountProfile_Environment) {
			accountProfile_Environment = xaccountProfile_Environment;
		}

		/** The Account_Profile_Power_Map__c object passed in the constructor. */
		public Environment__c accountProfile_Environment {
			get;
			private set;
		}

		/**
		 * Called to delete the Environment__c record.
		 * @return null
		 */
		public PageReference deleteEnvironment() {
			try {
				delete accountProfile_Environment;
			}
			catch(Exception ex) {
				ApexPages.addMessages(ex);
			}
			return null;
		}

		/**
		 * Called to edit the Environment__c record.
		 * @return null
		 */
		public PageReference editEnvironment() {
			return new PageReference('/'+accountProfile_Environment.Id+'/e?retURL='+accountProfile_Environment.Account_Profile__c+'%23Infrastructure_target');
		}
		
		/**
		 * Called to view the Environment__c record.
		 * @return null
		 */
		public PageReference viewEnvironment() {
			return new PageReference('/'+accountProfile_Environment.Id);
		}
	}
}