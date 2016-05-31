/**
 * In the future this class can replace all before insert and before update contract triggers.  
 * The processTrigger method is invoked by the Contract_Before trigger and in turn invokes
 * all the methods of this class.  This gives us a way to control the order in
 * which the code logic is invoked, as well as allowing other class features such
 * as shared data, constant values, and rigorous test coverage.
 * <p>
 * The Trigger object should never be directly referenced inside this class, as
 * that would make it impossible to substituting values inside test methods.
 * </p>
 * @author Scott Coleman <scoleman@redhat.com>
 * @version 2013-07-26
 * 2013-04-08 - Created
 * 2013-07-26 - added protectFields() method
 */
public without sharing class CreditTriggerBefore extends AbstractTrigger {
	/** BooleanSetting__c key to enable set opp amount */
	public static final String SET_OPP_AMOUNT_SETTING = 'Credit_Before.setOppAmount';
	/** BooleanSetting__c key to enable protect fields method */
	public static final String PROTECT_FIELDS_SETTING= 'Credit_Before.protectFields';

	private final Map<Id,Credit__c> oldMap = new Map<Id,Credit__c>();
	private final List<Credit__c> newList = new List<Credit__c>();

	public CreditTriggerBefore(Map<Id,Credit__c> xoldMap,List<Credit__c> xnewList) {
		super(xoldMap,xnewList,null);
		if(xoldMap != null) {
			oldMap.putAll(xoldMap);
		}
		if(xnewList != null) {
			newList.addAll(xnewList);
		}
	}

	/**
	 * For new credit records set the opportunity amount. Only do so when the current
	 * value is null. The Global Credit Check process and Special Payment Terms approval
	 * will generally specify a value. This trigger will populate the value for all other
	 * records (for example, those created manually by a Credit user).
	 */
	public void setOppAmount() {
		try {
			if(isInsert) {
				Map<Id,Opportunity> oppMap = new Map<Id,Opportunity>();
				for(Credit__c credit : newList) {
					if(credit.Opportunity_Amount__c == null) {
						oppMap.put(credit.Opportunity__c,null);
					}
				}
				if(oppMap.size()>0) {
					List<Opportunity> opps = [
						select Amount, CurrencyISOCode
						from Opportunity
						where Id in :oppMap.keySet() ];
					for(Opportunity opp : opps) {
						oppMap.put(opp.Id, opp);
					}
					for(Credit__c credit : newList) {
						if(oppMap.keySet().contains(credit.Opportunity__c)) {
							Opportunity opp = oppMap.get(credit.Opportunity__c);
							if(opp != null) {
								credit.Opportunity_Amount__c = opp.Amount;
								credit.CurrencyISOCode = opp.CurrencyISOCode;
							}
						}
					}
				}
			}
		}
		//while not ideal, I am swallowing exceptions to avoid disrupting the credit integration
		catch(Exception e) {}
	}

	/**
	 * Only allow specific profiles/permission sets to edit certain Credit__c fields. We need to allow unrestricted create,
	 * however, to avoid breaking the credit integration. The is necessary because credit integration creates new Credit__c 
	 * records under the current user's context. This is implemented as a trigger instead of a validation rule due to the
	 * requirement that we check a permission set.
	 */
	public void protectFields() {
		List<Profile> profile = [
			SELECT Name 
			FROM Profile 
			WHERE Id = :UserInfo.getProfileId() 
			LIMIT 1];
		String profileName = profile[0].Name;
		List<PermissionSetAssignment> permissionSet = [
			SELECT PermissionSetId 
			FROM PermissionSetAssignment 
			WHERE AssigneeId= :UserInfo.getUserId() 
				AND PermissionSet.Name = 'Customer_Data'];
		Boolean isCustomerData = !permissionSet.isEmpty();
		if(isUpdate &&  profileName != 'API' && profileName != 'Administrator - Level 1' && profileName != 'Credit User' && !isCustomerData) {
			for(Credit__c credit : newList) {
				Credit__c oldCredit = oldMap.get(credit.Id);
				if(credit.Credit_Stage__c != oldCredit.Credit_Stage__c) {
					credit.Credit_Stage__c.addError('You are not authorized to change the Credit Stage field value.');
				}
				if(credit.Comments__c != oldCredit.Comments__c) {
					credit.Comments__c.addError('You are not authorized to change the Comments field value.');
				}
				if(credit.Pending_Reasons__c != oldCredit.Pending_Reasons__c) {
					credit.Pending_Reasons__c.addError('You are not authorized to change the Reasons field value.');
				}
			}
		}
	}

	public static void processTrigger(Map<Id,Credit__c> xoldMap,List<Credit__c> xnewList) {
		final CreditTriggerBefore beforeTrigger = new CreditTriggerBefore(xoldMap,xnewList);
		if(AbstractTrigger.isActive(SET_OPP_AMOUNT_SETTING,true)) {
			beforeTrigger.setOppAmount();
		}
		if(AbstractTrigger.isActive(PROTECT_FIELDS_SETTING,true)) {
			beforeTrigger.protectFields();
		}
	}
}