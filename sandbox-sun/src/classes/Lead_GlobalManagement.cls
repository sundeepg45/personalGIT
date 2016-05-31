/**
 * Author: Bill C Riemers
 * Date: 2011-08-12
 * Description: Utility class for GLM controllers
 * Modificaton History:
 * Modified By : 
 * Modified date : 
 * Reason for Modification:
 */
public abstract with sharing class Lead_GlobalManagement {
	/** Error message to report when a lead is locked. */
	public static final String USE_LOCKING_SETTING = 'LeadView.UseLocking';
	/** Map of all the BooleanSetting__c values used. */
	public static final Map<String,Boolean> booleanSettingMap = new Map<String,Boolean> {
		USE_LOCKING_SETTING => getBooleanSettingValue(USE_LOCKING_SETTING) };

	public static final String ACCEPTED = 'Accepted';
	public static final String REJECTED = 'Rejected';
	public static final String SENT_TO_SALES = 'Sent to Sales';
	public static final String SALES_ACCEPTED = 'Sales Accepted';
	public static final String SALES_QUALIFIED = 'Sales Qualified';
	public static final String MARKETING_ACCEPTED = 'Marketing Accepted';
	public static final String MARKETING_QUALIFIED = 'Marketing Qualified';
	public static final Id LEAD_GEN_RECORDTYPE_ID = '012300000000Pn7AAE';
	public static final Id APAC_SALES_LEAD_RECORDTYPE_ID = '012300000000S4PAAU';
	public static final Id EMEA_SALES_LEAD_RECORDTYPE_ID = '012300000000S4KAAU';
	public static final Id LATAM_SALES_LEAD_RECORDTYPE_ID = '01260000000LkWAAA0';
	public static final Id NA_SALES_LEAD_RECORDTYPE_ID = '012300000000PmxAAE';
	public static final Set<Id> GLM_RECORDTYPE_IDS = new Set<Id>{
		LEAD_GEN_RECORDTYPE_ID,
		APAC_SALES_LEAD_RECORDTYPE_ID,
		EMEA_SALES_LEAD_RECORDTYPE_ID,
		LATAM_SALES_LEAD_RECORDTYPE_ID,
		NA_SALES_LEAD_RECORDTYPE_ID };

	/**
	 * Query a Boolean value from BooleanSetting__c constants.
	 */
	public static Boolean getBooleanSettingValue(String key) {
		Boolean retval = null;
		BooleanSetting__c bs = BooleanSetting__c.getInstance(key);
		if(bs != null) {
			retval = bs.Value__c;
		}
		return retval;
	}

	public static RecordType LEAD_MANAGEMENT_ACTIVITY_RECORDTYPE {
		get {
			if(LEAD_MANAGEMENT_ACTIVITY_RECORDTYPE == null) {
				for(RecordType rt : [
					SELECT Id, Name
					FROM RecordType 
					WHERE Name = 'Lead Management Activity'
						AND IsActive = true
						AND SObjectType = 'Task'
					limit 1])
				{
					LEAD_MANAGEMENT_ACTIVITY_RECORDTYPE = rt;
				}
			}
			return LEAD_MANAGEMENT_ACTIVITY_RECORDTYPE;
		}
	}

	public static LeadManagementHistory__c createAcceptedHistory(Id leadId) {
		return createHistory(leadId,ACCEPTED,null,null);
	}

	public static LeadManagementHistory__c createRejectedHistory(Id leadId,String rejectionReason,String comments) {
		return createHistory(leadId,REJECTED,rejectionReason,comments);
	}

	public static LeadManagementHistory__c createSentToSalesHistory(Id leadId) {
		return createHistory(leadId,SENT_TO_SALES,null,null);
	}

	public static LeadManagementHistory__c createHistory(
		Id leadId, String status, String rejectionReason, String comments)
	{
		LeadManagementHistory__c retval = null;
		for(RecordType rt : [
			SELECT Id 
			FROM RecordType 
			WHERE Name = :status 
				AND IsActive = true
				AND SObjectType = 'LeadManagementHistory__c' limit 1 ] )
		{
			retval = new LeadManagementHistory__c(
				Comments__c = comments,
				Lead__c = leadId,
				RecordTypeId = rt.Id,
				Rejection_Reason__c = rejectionReason);
		}
		return retval;
	}

	public static PageReference getLeadPageReference(Id leadId) {
		PageReference retval =  new PageReference('/'+Lead.SObjectType.getDescribe().getKeyPrefix()+'/o');
		try {
			Lead x = [select Id from Lead where Id = :leadId];
			retval = new PageReference('/'+leadId);
		}
		catch(Exception e) {}
		retval.setRedirect(true);
		return retval;
	}

	public static Boolean updateLead(Lead lead,LeadManagementHistory__c history) {
		Boolean retval = false;
		LeadTriggerAfterGLM.leadManagementHistoryMap.put(lead.Id,history);
		try {
			update lead;
			retval = true;
		}
		catch(Exception e) {
			ApexPages.addMessages(e);
		}
		LeadTriggerAfterGLM.leadManagementHistoryMap.remove(lead.Id);
		return retval;
	}

	private static User currentUser = null;
	public static User getCurrentUser() {
		if(currentUser == null) {
			currentUser = [
				select Id, Is_Marketing_User__c
				from User
				where Id = :UserInfo.getUserId() ];
		}
		return currentUser;
	}

	public static Lead queryLead(Id leadId,Lead retval) {
		if(retval == null && leadId != null) {
			retval = new Lead(Id=leadId);
			try {
				retval = [select RecordTypeId, Stage__c from Lead where Id = :leadId];
			}
			catch(Exception e) {
				ApexPages.addMessages(e);
			}
		}
		return retval;
	}

	public static Boolean isUnlockedRecordType(Lead lead) {
		return (BooleanSettingMap.get(USE_LOCKING_SETTING) == false) || (lead == null) || !GLM_RECORDTYPE_IDS.contains(lead.RecordTypeId);
	}

	public static Boolean isUnlockedStage(Lead lead) {
		return (BooleanSettingMap.get(USE_LOCKING_SETTING) == false) || (lead == null) || (lead.Stage__c == MARKETING_ACCEPTED) || (lead.Stage__c == SALES_ACCEPTED);
	}
}