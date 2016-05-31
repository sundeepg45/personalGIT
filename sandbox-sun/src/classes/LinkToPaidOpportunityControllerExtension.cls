/**
 * This is a controller extension for page LinkToPaidOpportunity_DeleteAll.
 *
 * @version 2013-08-21
 * 
 * @author Scott Coleman <scoleman@redhat.com>
 * 2013-08-21 - Created
 */
public with sharing class LinkToPaidOpportunityControllerExtension {
	private final ApexPages.StandardController controller;
	private Id proofOfConceptId;
	private String returnURL;

    /*
     * Constructor for the controller extension
     */
	public LinkToPaidOpportunityControllerExtension(ApexPages.StandardController stdController) {
		controller = stdController;
		proofOfConceptId = ApexPages.currentPage().getParameters().get('pocId');
		returnURL = ApexPages.currentPage().getParameters().get('retURL');
	}

    public PageReference deleteAll() {
    	PageReference returnPage;
    	try {
	   		if(proofOfConceptId != null) {
	   			List<Link_to_Paid_Opportunity__c> links = [
	   				SELECT Id
	   				FROM Link_to_Paid_Opportunity__c
	   				WHERE Proof_Of_Concept__c = :proofOfConceptId];
	   			if(!links.isEmpty()) {
	   				delete links;
	   			}		
	   		}
	   		if(returnURL != null) {
	   			returnPage = new PageReference(returnURL);
	   			returnPage.setRedirect(true);
	   		}
	  	} 
	  	catch(Exception ex) {
	  		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, ex.getMessage()));
	  	}
    	return returnPage;
    }
}