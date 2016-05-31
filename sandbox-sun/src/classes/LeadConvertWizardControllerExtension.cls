/**
 * This is a controller extension to allow add wizard options prior to the lead
 * convert page.  The fundamental problem this controller addresses is how to
 * augment the lead conversion process without overriding the whole thing. 
 * The way do this is to give lead development users a page where they can specify
 * extra parameters what will be copied after the lead is converted by a trigger.
 * 
 * One fundamental problem with this approach is the lead development users could
 * set these parameters and then cancel once they are on the stardard lead conversion
 * page.  The trigger would not know they cancelled, and if a sales person converted the
 * lead later, the same values could be applied after that conversion.
 * 
 * The solution to this delema is no matter who is converting the lead, we always update
 * a flag first that explicitly specifies if standard lead conversion should be used, or
 * if the extra values should also apply.  If a non-lead development user does the conversion
 * then the value flag is set to true, if a lead development user is doing the conversion the
 * flag is set to true, or whatever they toggle it to on the visual force page.
 * 
 * @version 2015-03-02
 * @author Bill C Riemers <briemers@redhat.com>
 * 2013-08-21 - Default SendEmailToOpportunityTeam__c to true
 * 2013-08-06 - Created
 * Scott Coleman <scoleman@redhat.com>
 * 2015-03-02 - Updated so this operates as an alternate flow from the C360 custom lead conversion page (CustomLeadConversionPage.page)
 */
public with sharing class LeadConvertWizardControllerExtension {
	private Id leadId;

	/** Controller Extension constructor. */
	public LeadConvertWizardControllerExtension(ApexPages.StandardController stdController) {
		leadId = stdController.getId();
	}

	/**
	 * Retrieve the current lead.
	 */
	public Lead currentLead {
		get {
			if(currentLead == null) {
				for(Lead ld : [
					select
						Stage__c
					from Lead
					where Id = :leadId ] )
				{
					currentLead = new Lead(
						Id=ld.Id,
						Stage__c=ld.Stage__c,
						StandardConversion__c=false,
						SendEmailToOpportunityTeam__c=true);
				}
			}
			return currentLead;
		}
		set;
	}

	/**
	 * Undo any edits to the current lead.
	 *
	 * @return null
	 */
	public PageReference reset() {
		Lead ld = currentLead;
		currentLead = new Lead(
			Id=currentLead.Id,
			Stage__c=currentLead.Stage__c,
			StandardConversion__c = currentLead.StandardConversion__c,
			SendEmailToOpportunityTeam__c=true);
		return null;
	}

	/**
	 * Update the current lead and return the lead convert url.
	 * 
	 * @return reference to the standard lead convert page
	 */
	public PageReference leadConvert() {
		Database.SaveResult sr = Database.update(currentLead,false);
		PageReference retval;
		if(sr.isSuccess()) {
			retval = new PageReference('/lead/leadconvert.jsp');
			retval.getParameters().putAll(ApexPages.currentPage().getParameters());
			retval.getParameters().put('retURL','/'+currentLead.Id);
			retval.getParameters().put('nooverride','1');
			retval.getParameters().put('id',currentLead.Id);
			retval.setRedirect(true);
		}
		else {
			for(Database.Error err: sr.getErrors()) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, err.getMessage())); 
			}
		}
		return retval;
	}
}