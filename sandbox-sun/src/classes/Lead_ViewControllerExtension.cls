/**
 * Author: Bill C Riemers
 * Date: 2011-08
 * Description: Controller Extension to view leads
 * Modificaton History:
 * Modified By : Bill C Riemers
 * Modified date : 2011-10-23
 * Reason for Modification: Removed nooverrideView so double click editing works
 */
public with sharing class Lead_ViewControllerExtension extends Lead_GlobalManagement {
	ApexPages.StandardController controller;
	public Lead_ViewControllerExtension(ApexPages.StandardController controller) {
		this.controller = controller;
		this.leadId = controller.getId();
	}

	public Id leadId {
		get;
		set;
	}

	public Lead qlead {
		get { 
			return (qlead = queryLead(leadId,qlead));
		}
		set;
	}

	public User currentUser {
		get {
			if(currentUser == null) {
				currentUser = [ select Profile.Name from User where Id = :UserInfo.getUserId() ];
			}
			return currentUser;
		}
		set;
	}

	public Boolean getIsUnlocked() {
		return Util.adminByPass(false) || currentUser.Profile.Name.toUpperCase().indexof('PARTNER') >= 0 || isUnlockedRecordType(qlead) || isUnlockedStage(qlead);
	}

	public Boolean isConverted {
		get {
			if(isConverted == null) {
				isConverted = [select Count() from Lead where Id = :controller.getId() and IsConverted = true] == 1;
			}
			return isConverted;
		}
		set;
	}

	public PageReference nooverrideView() {
		PageReference retval = null;
		if(isConverted) {
			retval = new PageReference('/'+controller.getId());
			retval.getParameters().put('nooverride','1');
			retval.setRedirect(true);
		}
		return retval;
	}
}