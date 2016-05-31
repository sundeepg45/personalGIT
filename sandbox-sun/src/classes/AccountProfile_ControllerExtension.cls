/**
 * Implents a controller extension to for the main components of the account profile 
 * visual force page.  Most tables have their own controller extension...
 *
 * @version 2015-10-27
 * @author Bill C Riemers <briemers@redhat.com>
 * 2015-10-27 - worked around salesforce apex:variable bug by moving some of the variables into the controller
 * 2014-02-05 - Added method return the potential opportunities and total spent report id.
 * 2013-06-21 - created
 */
public with sharing class AccountProfile_ControllerExtension {
	public static final String SHOW_SUMMARY_SETTING = 'Account_Profile.showSummary';
	public static final String POTENTIAL_SPENDING_SETTING = 'AccountProfile.PotentialSpending';
	public static final String TOTAL_SPEND_SETTING = 'AccountProfile.TotalSpend';

	/**
	 * ControllerExtension constructor.
	 */
	public AccountProfile_ControllerExtension(ApexPages.StandardController stdController) {}

	/** 
	 * Use a custom setting to control the view of the summary button.
	 */
	public Boolean getShowSummary() {
		BooleanSetting__c showSummary = BooleanSetting__c.getInstance(SHOW_SUMMARY_SETTING);
		return (showSummary != null && showSummary.Value__c == true);
	}

	public Id getPotentialSpendingReportId() {
		Id retval = null;
		StringSetting__c potentialSpending = StringSetting__c.getInstance(POTENTIAL_SPENDING_SETTING);
		if(potentialSpending != null) {
			try {
				retval = (Id)potentialSpending.Value__c;
			}
			catch(Exception ex) {}
		}
		return retval;
	}

	public Id getTotalSpendReportId() {
		Id retval = null;
		StringSetting__c totalSpend = StringSetting__c.getInstance(TOTAL_SPEND_SETTING);
		if(totalSpend != null) {
			try {
				retval = (Id)totalSpend.Value__c;
			}
			catch(Exception ex) {}
		}
		return retval;
	}

	public Boolean getIsRenderAsPDF() {
		return ApexPages.currentPage().getParameters().get('renderas') == 'pdf';
	}

	public Boolean getIsPrintableView() {
		return getIsRenderAsPDF() || ApexPages.currentPage().getParameters().get('print') == '1';
	}

	public Boolean getIsInfrastructureView() {
		return ApexPages.currentPage().getParameters().get('view') == 'infrastructure';
	}

	public Boolean getIsTopView() {
		return ApexPages.currentPage().getParameters().get('view') == 'top';
	}

	public Boolean getIsFullView() {
		return ! (getIsInfrastructureView() || getIsTopView());
	}
}