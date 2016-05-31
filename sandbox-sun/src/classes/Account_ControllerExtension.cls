/**
 * This class allows us to redirect to an account read only 
 * record as appropriate.
 *
 * @author Bill C Riemers <briemers@redhat.com>
 * @version 2012-09-19
 * 2012-09-19 - created
 */
public without sharing class Account_ControllerExtension {
	/** The account Id. */
	private final Id recordId;
	/**
	 * ControllerExtension constructor.
	 */
	public Account_ControllerExtension(ApexPages.StandardController stdController) {
		this.recordId = stdController.getId();
	}

	/**
	 * Query the AccountReadOnly__c Id for this account.
	 */
	public Id getAccountReadOnlyId() {
		Id retval = null;
		for(AccountReadOnly__c aro : [select Id from AccountReadOnly__c where Account__c = :recordId]) {
			retval = aro.Id;
		}
		return retval;
	}	
}