/**
 * Class Name: Lead_AcceptControllerExtension 
 * Author: Bill C Riemers
 * Date: 2011-08-15
 * Description: Controller Extension for accepting leads
 * Modificaton History:
 * Modified By : 
 * Modified date : 
 * Reason for Modification:
 */
public with sharing class Lead_AcceptControllerExtension extends Lead_GlobalManagement {
	private ApexPages.StandardController controller;
	public Lead lead;

	public Lead_AcceptControllerExtension(ApexPages.StandardController controller) {
		this.controller = controller;
		this.lead = (Lead)controller.getRecord();
	}

	public PageReference acceptLead() {
		PageReference retval = null;
		Lead xlead = lead.clone(true);
		Boolean routeAround = !((lead.Stage__c == MARKETING_ACCEPTED)||(lead.Stage__c == MARKETING_QUALIFIED)|| (getCurrentUser().Is_Marketing_User__c == true));
		if(lead.Route_Around__c != routeAround) {
			xlead.Route_Around__c = routeAround;
		}
		if(lead.PenaltyBoxExpiration__c != null) {
			xlead.PenaltyBoxExpiration__c = null;
		}
		String stage = MARKETING_ACCEPTED;
		if(getCurrentUser().Is_Marketing_User__c != true) {
			stage = SALES_ACCEPTED;
		}
		Boolean validUpdate = false;
		if(stage != lead.Stage__c) {
			xlead.Stage__c = stage;
			validUpdate = true;
		}
		if(getCurrentUser().Id != lead.OwnerId) {
			xlead.OwnerId = getCurrentUser().Id;
			validUpdate = true;
		}
		if(! validUpdate) {
			ApexPages_Message_ControllerExtension.addErrorMessage('You have already accepted this Lead.');
		}
		else if(updateLead(xlead,createAcceptedHistory(lead.Id))) {
			retval = getLeadPageReference(lead.id);
			this.lead = xlead;
		}
		return retval;
	}
}