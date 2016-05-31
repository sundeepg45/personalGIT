/**
 * This class is a controller extension for managing AccountProfileSWOT__c objects.
 *
 * @author Bill C Riemers <briemers@redhat.com>
 * @version 2012-11-09
 * 2012-11-09 - created
 */
public with sharing class AccountProfile_ManageSWOT {
	private final Id recordId;

	/**
	 * ControllerExtension constructor.
	 */
	public AccountProfile_ManageSWOT(ApexPages.StandardController stdController) {
		recordId = stdController.getId();
	}

	/**
	 * Query the list of SWOT Analysis objects.
	 * @return list of Account_Profile_SWOT__c objects.
	 */
	public List<Account_Profile_SWOT__c> getAccountProfileSWOTs() {
		AccountProfileSWOTController swotController = new AccountProfileSWOTController();
		swotController.accountProfileId = recordId;
		return swotController.accountProfileSWOTs;
	}

	/** List of SWOT_Editor objects, including 10 new ones. */
	public List<SWOT_Editor> swotEditors {
		get {
			if(swotEditors == null) {
				swotEditors = new List<SWOT_Editor>();
				for(Account_Profile_SWOT__c swot : getAccountProfileSWOTs()) {
					swotEditors.add(new SWOT_Editor(swot));
				}
				for(Integer i=10;i-- > 0;) {
					swotEditors.add(new SWOT_Editor(new Account_Profile_SWOT__c(Account_Profile__c=recordId)));
				}
			}
			return swotEditors;
		}
		set;
	}

	/** 
	 * Called to perform deletes, updates, and inserts.
	 * @return a page reference to the Account_Profile__c object if successful, null if failure.
	 */
	public PageReference save() {
		PageReference retval = null;
		List<Account_Profile_SWOT__c> changes = new List<Account_Profile_SWOT__c>();
		List<Account_Profile_SWOT__c> deletes = new List<Account_Profile_SWOT__c>();
		Boolean hasError = false;
		for(SWOT_Editor editor : swotEditors) {
			if(editor.isDeleted || editor.swot.Statement__c == null || editor.swot.Statement__c == '') {
				if(editor.swot.Id != null) {
					deletes.add(editor.swot);
				}
			}
			else if(editor.isChanged) {
				if(editor.swot.Type__c != null && editor.swot.Type__c != '') {
					changes.add(editor.swot);
				}
				else if(! hasError) {
					hasError = true;
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Type: You must enter a value'));
				}
			}
		}
		if(! hasError) {
			SavePoint sp = Database.setSavePoint();
			try {
				if(! deletes.isEmpty()) {
					hasError = true;
					delete deletes;
				}
				if(! changes.isEmpty()) {
					upsert changes;
				}
				swotEditors = null;
				sp = null;
				retval = new PageReference('/'+recordId);
			}
			catch(Exception ex) {
				ApexPages.addMessages(ex);
			}
			finally {
				if(sp != null) {
					Database.rollback(sp);
				}
			}
		}
		return retval;
	}

	/**
	 * Called to do deletes, updates, and saves.
	 * @return null
	 */
	public PageReference saveAndContinue() {
		save();
		return null;
	}

	/**
	 * Called to clear all edits in progress.
	 * @return null
	 */
	public PageReference reset() {
		swotEditors = null;
		return null;
	}

	/**
	 * Called to cancel updates.
	 * @return a page reference to the Account_Profile__c object.
	 */
	public PageReference cancel() {
		return new PageReference('/'+recordId);
	}

	/**
	 * This class maintains the variables needed to edit swot records.
	 */
	public class SWOT_Editor {
		private final Account_Profile_SWOT__c swot;
		private final String typeValue;
		private final String statementValue;

		public SWOT_Editor(Account_Profile_SWOT__c swot) {
			this.swot = swot;
			typeValue = swot.Type__c;
			statementValue = swot.Statement__c;
		}

		public Account_Profile_SWOT__c getSWOT() {
			return swot;
		}

		public Boolean isDeleted {
			get {
				return (isDeleted == true);
			}
			set;
		}

		public Boolean isChanged {
			get {
				return (typeValue == null && swot.Type__c != null && swot.Type__c != '')||
					(typeValue != null && !typeValue.equals(swot.Type__c))||
					(statementValue == null && swot.Statement__c != null && swot.Statement__c != '')||
					(statementValue != null && !statementValue.equals(swot.Statement__c));
			}
		}
//
//		public Boolean getTypeRequired() {
//			return (swot.Statement__c != null && swot.Statement__c != '');
//		}
	}
}