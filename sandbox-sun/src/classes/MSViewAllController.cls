public with sharing class MSViewAllController {
	private MSController	ctrl;


	public String key {
		get {
			return key;
		}
		set {
			key = PartnerUtil.cleanSection(value);
		}
	}

	public String getPageName() {
		return ctrl.pageinfo.Page__c;
	}
	
	public String getSiteName() {
		return ctrl.pageinfo.Site__c;
	}

	public MSController getCtrl() {
		return ctrl;
	}

	public void setCtrl(MSController c) {
		ctrl = c;
	}

}