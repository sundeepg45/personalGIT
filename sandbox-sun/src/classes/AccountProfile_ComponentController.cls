/**
 * This class is one of the controllers for the Account Profile ShowSummary components.
 *
 * @author Bill C Riemers <briemers@redhat.com>
 * @version 2013-01-04
 * 2013-01-04 - Refactored from the ProfileComponentController.
 */
public with sharing class AccountProfile_ComponentController {
	private Account account;

	public Account_Profile__c account_Profile
	{
		get;
		set {
			account_Profile = value;
			if(value != null)
			{
				account = value.Account__r;
			}
		}
	}

	public Partner_Profile__c partner_Profile
	{
		get;
		set {
			partner_Profile = value;
			if(value != null)
			{
				account = value.Partner__r;
			}
		}
	}

	public List<Assessment_Summary__c> assessmentSummaryList
	{
		get {
			if(assessmentSummaryList == null)
			{
		  		if(account_Profile != null)
				{
					assessmentSummaryList = [
					  select Assessment_Summary__c 
					  from Assessment_Summary__c 
					  where Account_Profile__c= :account_Profile.Id ];
				}
				else
				{
					assessmentSummaryList = new List<Assessment_Summary__c>();
				}
			}
			return assessmentSummaryList;
		}
		set;
	}

	public Integer assessmentSummaryCount
	{
		get {
			return assessmentSummaryList.size();
		}
	}

	public List<Partner_s_Assessment_Summary__c> partnerAssessmentSummaryList
	{
		get {
			if(partnerAssessmentSummaryList == null)
			{
				if(partner_Profile != null)
				{
					partnerAssessmentSummaryList = [
					  select Partner_Assessment_Summary__c 
					  from Partner_s_Assessment_Summary__c 
					  where Partner_Profile__c= :partner_Profile.Id ];
				}
				else
				{
					partnerAssessmentSummaryList = new List<Partner_s_Assessment_Summary__c>();
				}
			}
			return partnerAssessmentSummaryList;
		}
		set;
	}

	public Integer partnerAssessmentSummaryCount
	{
		get {
			return partnerAssessmentSummaryList.size();
		}
	}
}