public with sharing class Lead_EditControllerExtension extends Lead_GlobalManagement {
	Id leadId;
	ApexPages.StandardController controller;
	public Lead_EditControllerExtension(ApexPages.StandardController controller) {
		this.controller = controller;
		this.leadId = controller.getId();
	}

	private Lead lead {
		get { return (lead = queryLead(leadId,lead)); }
		set;
	}

	public PageReference leadEdit() {
		PageReference retval = new PageReference('/'+leadId);
		ApexPages.currentPage().getParameters().remove('nooverride');
		retval.getParameters().putAll(ApexPages.currentPage().getParameters());
		Boolean updateable = false;
		if(lead != null && lead.RecordTypeId != null) {
			Schema.DescribeSObjectResult d = lead.getSObjectType().getDescribe();
			updateable = d.isUpdateable();
			if(updateable) {
				System.Savepoint sp = Database.setSavepoint();
				Database.SaveResult sr = Database.update(lead,false);
				for(Database.Error e : sr.getErrors()) {
					System.debug(e);
					if(e.getStatusCode() == StatusCode.INSUFFICIENT_ACCESS_OR_READONLY) {
						updateable = false;
					}
				}
				if(sr.isSuccess()) {
					Database.rollback(sp);
				}
			}
		}
		User u = [ select Profile.Name from User where Id = :UserInfo.getUserId() ];
		if((!updateable)||u.Profile.Name.toUpperCase().indexof('PARTNER') >= 0||Util.adminByPass(false)||isUnlockedRecordType(lead)||isUnlockedStage(lead)) {
			retval = new PageReference('/'+leadId+'/e');
			retval.getParameters().put('retURL','/'+leadId);
			retval.getParameters().putAll(ApexPages.currentPage().getParameters());
			retval.getParameters().put('nooverride','1');
		}
		return retval;
	}
}