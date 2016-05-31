/**
 * Class for updating Partner Tier on Opportunity Partners when Tier changes on the Partner Account.
 * Invoked from the trigger PartnerStatus_UpdateAccount on Partner Status. 
 *
 * @version 2014-08-13
 * @author: Jayant (Application Maintenance)
 * 2012-08-29 - September AM Release Case # RH-00181191.
 * Bill Riemers <briemers@redhat.com>
 * 2014-08-13 - Defere updates to a future call if the list is really large
 * 2014-08-12 - Added hook to prevent opportunity updates when updating Opportunity Partner Status values
 */
public without sharing class PartnerStatusTriggerPRL {
	public static final String PARTNERSTATUS_OPP_PARTNER_LIMIT_SETTING = 'PartnerStatuseOppPartnerLimit';
	private List<OpportunityPartner__c> oppPartners = new List<OpportunityPartner__c>();
	private List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
	private static OrgWideEmailAddress owe {
		get {
			if(owe == null) {
				owe = [select Id from OrgWideEmailAddress where Address = 'no-reply-partners@redhat.com' limit 1];
			}
			return owe;
		}
		set;
	}

	/**
	 * Sets Partner Tier field on Opportunity Partners when a Partner Status is updated.
	 *
	 * @param partnerIds the Ids of Accounts for which Partner Status records were modified
	 * @returns void
	 */
	@future
	public static void updateOppPartnerFieldsFuture(Set<Id> partnerIds) {
		updateOppPartnerFields(partnerIds,null);
	}

	/**
	 * Sets Partner Tier field on Opportunity Partners when a Partner Status is updated.
	 *
	 * @param partnerStatusByPartnerIdMap map of Partner Statuses which were modified by account id
	 * @returns void
	 */
	public static void updateOppPartnerFields(Map<Id, PartnerStatus__c> partnerStatusByPartnerIdMap) {
		updateOppPartnerFields(partnerStatusByPartnerIdMap.keySet(),partnerStatusByPartnerIdMap);
	}

	/**
	 * Sets Partner Tier field on Opportunity Partners when a Partner Status is updated.
	 *
	 * @param partnerIds the Ids of Accounts for which Partner Status records were modified
	 * @param partnerStatusByPartnerIdMap map of Partner Statuses which were modified by account id
	 * @returns void
	 */
	public static void updateOppPartnerFields(Set<Id> partnerIds,Map<Id, PartnerStatus__c> partnerStatusByPartnerIdMap) {
		Map<ID, Account> accountMap = new Map<ID, Account>([
				select  Id,
						(select Id,
								Opportunity__c,
								Opportunity__r.OpportunityNumber__c,
								Opportunity__r.OwnerId,
								PartnerTier__c
						from	OpportunityPartners2__r
						where Opportunity__r.IsClosed = false)
				from Account
				where Id in :partnerIds
		]);

		Map<ID, PartnerStatus__c> statusList = new Map<ID, PartnerStatus__c>([
				select  Id,
						PartnerTier__c,
						Partner__c
				from	PartnerStatus__c
				where   Partner__c in :partnerIds
				and	 ActivationStatus__c = 'Active'
				order by Partner__c
		]);

		PartnerStatusTriggerPRL obj = new PartnerStatusTriggerPRL();

		for (PartnerStatus__c ps : statusList.values()) {
			if (PFUtils.isEmpty(ps.PartnerTier__c)) continue;
			if (accountMap.containsKey(ps.Partner__c)) {
				Account acct = accountMap.get(ps.Partner__c);
				performUpdateOnOppPartners(acct.OpportunityPartners2__r, ps, obj.oppPartners, obj.mails);
			}
		}

		if(!obj.oppPartners.isEmpty()) {
			if(! System.isFuture()) {
				Integer sizeLimit = 0;
				LongSetting__c lv = LongSetting__c.getInstance(PARTNERSTATUS_OPP_PARTNER_LIMIT_SETTING);
				if(lv != null && lv.Value__c != null) {
					sizeLimit = lv.Value__c.intValue();
				}
				if(obj.oppPartners.size() > sizeLimit) {
					updateOppPartnerFieldsFuture(new Set<Id>(partnerIds));
					return;
				}
			}
			Boolean triggerValue1 = AbstractTrigger.booleanSettingMap.get(OpportunityPartnerTriggerBefore.LEGACY_PARTNER_SETTING);
			Boolean triggerValue2 = AbstractTrigger.booleanSettingMap.get(OpportunityPartnerTriggerAfter.UPDATE_OPPS_SETTING);
			try {
				AbstractTrigger.booleanSettingMap.put(OpportunityPartnerTriggerBefore.LEGACY_PARTNER_SETTING,false);
				AbstractTrigger.booleanSettingMap.put(OpportunityPartnerTriggerAfter.UPDATE_OPPS_SETTING,false);
				for(Database.Saveresult sr : Database.update(obj.oppPartners,false)) {
					OpportunityPartner__c op = obj.oppPartners.remove(0);
					if(partnerStatusByPartnerIdMap != null && !sr.isSuccess()) {
						PartnerStatus__c ps = partnerStatusByPartnerIdMap.get(op.Partner__c);
						if(ps != null) {
							ps.addError('Failed to update Opportunity : ' + op.Opportunity__c + ':\n' + sr.getErrors());
						}
					}
				}
			}
			finally {
				AbstractTrigger.booleanSettingMap.put(OpportunityPartnerTriggerBefore.LEGACY_PARTNER_SETTING,triggerValue1);
				AbstractTrigger.booleanSettingMap.put(OpportunityPartnerTriggerAfter.UPDATE_OPPS_SETTING,triggerValue2);
			}
		}
		if(!obj.mails.isEmpty()) {
			Messaging.sendEmail(obj.mails, false);
		}
	}

	private static void performUpdateOnOppPartners(List<OpportunityPartner__c> opList, PartnerStatus__c ps, List<OpportunityPartner__c> oppPartners, List<Messaging.SingleEmailMessage> mails) {
		Map<String, String> oppIdOwner = new Map<String, String> ();
		for(OpportunityPartner__c op : opList)
		{
			if(op.PartnerTier__c != ps.PartnerTier__c)	//added on 2012-08-29, JY.
			{
				op.PartnerTier__c = ps.PartnerTier__c;
				oppPartners.add(op);
				if(oppIdOwner.get(op.Opportunity__r.OpportunityNumber__c + op.Opportunity__r.OwnerId) != null)
				continue;
				oppIdOwner.put(op.Opportunity__r.OpportunityNumber__c + op.Opportunity__r.OwnerId,'Y');
				createMail(op, mails);
			}
		}
	}

	private static void createMail(OpportunityPartner__c op, List<Messaging.SingleEmailMessage> mails) {
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		String urlPath = URL.getSalesforceBaseUrl().toExternalForm() + '/' + op.Opportunity__c;
		String htmlBody = 'Please be advised, the Partner Status has changed on the opportunity partner in Opportunity # ' 
							+ '<b><a href ="'+ urlPath + '" target = "_blank">' + op.Opportunity__r.OpportunityNumber__c + '</a>. </b>'
							+ 'Their distribution pricing is affected. Please contact your regional Sales Support contact.' 
							+ '<br/><br/>Thank You.';
		String textBody = 'Please be advised, the Partner Status has changed on the opportunity partner in Opportunity # ' 
							+ op.Opportunity__r.OpportunityNumber__c + '. '
							+ 'Their distribution pricing is affected. Please contact your regional Sales Support contact.' 
							+ '\n\nThank You.';
		mail.setTargetObjectId(op.Opportunity__r.OwnerId);
		mail.setReplyTo('noreply@redhat.com');  
		mail.setSubject('The Partner Tier has changed on Opportunity # ' + op.Opportunity__r.OpportunityNumber__c);
		mail.setOrgWideEmailAddressId(owe.Id);
		mail.setHtmlBody(htmlBody);
		mail.setPlainTextBody(textBody);
		mail.setUseSignature(false);
		mail.setSaveAsActivity(false);
		mails.add(mail);
	}
}