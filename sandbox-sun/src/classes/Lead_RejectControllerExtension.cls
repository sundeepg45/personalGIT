/**
 * Controller class for rejecting leads.
 * 
 * @version 2016-03-01
 * @author Bill C Riemers <briemers@redhat.com>
 * @since 2011-08-15 - created
 * @author Jayant (Application Maintenance)
 * @since 2012-03-16 - updated
 * @since 2012-03-16 - AM release Case # RH-00120924
 * @author Sundeep Godishala
 * @since 2016-02-05 - US82534
 */
 public with sharing class Lead_RejectControllerExtension extends Lead_GlobalManagement {
	public static final String COMMENT_REQUIRED_MESSAGE =
		'Please provide more information about why you are rejecting this lead in the comments box below.';
	private ApexPages.StandardController controller;
	private Lead lead;

	public Lead_RejectControllerExtension(ApexPages.StandardController controller) {
		this.controller = controller;
		this.lead = (Lead)controller.getRecord();
	}

	public String getCommentRequiredMessage() {
		return COMMENT_REQUIRED_MESSAGE;
	}

	public Map<String,Reject_Lead_Setup__c> rejectionMap {
		get {
			if(rejectionMap == null) {
				rejectionMap = new Map<String,Reject_Lead_Setup__c>();
				// todo: we need to filter this on the current lead stage
		   User lgdInUser = [select id, IS_Marketing_User__c from user where id=:userinfo.getUserId()];
				If(lgdInUser.Is_Marketing_User__c==True)
				{	
			   for(Reject_Lead_Setup__c r : [
					select 
						DaysInPenaltyBox__c,
						OwnerId,
//					  Name,
						Lead_Stage__c,
//					  Lead_Status__c,
						Source_Stage__c,
						Rejection_Reason__c,
						Explanation_for_Reason__c
					from Reject_Lead_Setup__c
					where Source_Stage__c includes (:lead.Stage__c) AND Lead_Development_User__c=True AND Marked_As_Retired__c=False])
				{
					rejectionMap.put(r.Rejection_Reason__c,r);
				}
			 }
			 else
			 {
			 for(Reject_Lead_Setup__c r : [
			 select
			   DaysInPenaltyBox__c,
			   OwnerId,
//			 Name,
			   Lead_Stage__c,
//			 Lead_Status__c,
			   Source_Stage__c,
			   Rejection_Reason__c,
			   Explanation_for_Reason__c
			 from Reject_Lead_Setup__c
			  where Source_Stage__c includes (:lead.Stage__c) AND Lead_Development_User__c=False AND Marked_As_Retired__c=False])
			  {
			  rejectionMap.put(r.Rejection_Reason__c,r);
			  }
			 }
			}
			return rejectionMap;
			}
		set;
	}
	
	public string DescriptionMessage{get;set;}
	
	public void showDescription(){
	   Reject_Lead_Setup__c rls = rejectionMap.get(rejectionReason);
	   If(rls!=null){
	   DescriptionMessage = rls.Explanation_for_Reason__c;
	   }
	   else{
	   DescriptionMessage = '';
	   }
	}
	
	public List<SelectOption> rejectionReasonOptions {
		get {
			if(rejectionReasonOptions == null) {
				List<String> keys = new List<String>(rejectionMap.keySet());
				keys.sort();
				rejectionReasonOptions = new List<SelectOption>();
				rejectionReasonOptions.add(new SelectOption('', '--None--'));
				for(String key : keys) {
					rejectionReasonOptions.add(new SelectOption(key,key));
				}
			}
			return rejectionReasonOptions;
		}
		set;
	}

	public String rejectionReason {
		get;
		set;
	}

	public Boolean isRejectionReasonMissing {
		get {
			return (isRejectionReasonMissing == true);
		}
		set;
	}

	public String rejectionComment {
		get;
		set;
	}

	public Boolean isRejectionCommentMissing {
		get {
			return (isRejectionCommentMissing == true);
		}
		set;
	}

	public Boolean isRejectionAllowed {
		get { return (rejectionReasonOptions.size() >= 2); }
	}

	public PageReference rejectionAllowed() {
		if(! isRejectionAllowed) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'You may not reject the lead at this stage.'));
		}
		return null;
	}

	public PageReference rejectLead() {
		PageReference retval = null;
		Reject_Lead_Setup__c rls = rejectionMap.get(rejectionReason);
		isRejectionReasonMissing = false;
		isRejectionCommentMissing = false;
		if(rls == null) {
			isRejectionReasonMissing = true;
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Invalid Data.'));
		}
		else if(rejectionReason == 'Other' && (rejectionComment == null || rejectionComment == '')) {
			isRejectionCommentMissing = true;
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,getCommentRequiredMessage()));
		}
		else {
			if(rls.DaysInPenaltyBox__c != null && rls.DaysInPenaltyBox__c > 0) {
				DateTime penaltyBoxExpiration = DateTime.now().addDays(rls.DaysInPenaltyBox__c.intValue());
				if(lead.PenaltyBoxExpiration__c == null || lead.PenaltyBoxExpiration__c.getTime() < penaltyBoxExpiration.getTime()) {
					lead.PenaltyBoxExpiration__c = penaltyBoxExpiration;
				}
			}
			if(rls.Lead_Stage__c != null) {
				lead.Stage__c = rls.Lead_Stage__c;
			}
			if(lead.OwnerId != rls.OwnerId) {
				lead.OwnerId = rls.OwnerId;
			}
			if(lead.Route_Around__c != false) {
				lead.Route_Around__c = false;
			}
			//Jayant - Below code has been added for April 2012 AM release Case # RH-00120924 - Begin
			//Pre-Qualified flag should be unchecked on Lead rejection
			if(lead.Pre_Qualified__c != false) {
				lead.Pre_Qualified__c = false;
			}
			//End
			//Sundeep - 02/05/2015
			//contact sales and Sent to Lead Dev flags should be uncheked when lead is rejected
			if(lead.Contact_Sales__c != false) {
				lead.Contact_Sales__c = false;
			}
			if(lead.Sent_to_Lead_Development__c != false) {
				lead.Sent_to_Lead_Development__c = false;
			}
			//End
			if(updateLead(lead,createRejectedHistory(lead.Id,rejectionReason,rejectionComment))) {
				retval = getLeadPageReference(lead.id);
			}
		}
		return retval;
	}
}