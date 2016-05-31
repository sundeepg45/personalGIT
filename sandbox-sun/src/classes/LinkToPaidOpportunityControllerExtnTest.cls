/**
 * This is a test class for LinkToPaidOpportunityControllerExtension.cls
 *
 * @version 2013-08-21
 * 
 * @author Scott Coleman <scoleman@redhat.com>
 * 2013-08-21 - Created
 */
@isTest
private class LinkToPaidOpportunityControllerExtnTest {
	static Account account {
		get {
			if(account == null) {
				account = new Account(
					Name='Test account');
				insert account;
			}
			return account;
		}
	}

	static Opportunity proofOfConcept {
		get {
			if(proofOfConcept == null) {
				proofOfConcept = new Opportunity(
					Name='Test POC',
					AccountId = account.Id,
					FulfillmentChannel__c='Indirect – VAR/VAD',
					CloseDate=System.today(),
					StageName='Prepare',
					Country_of_Order__c='United States',
					PrimaryBusinessUnit__c=null,
					POC_Primary_Product__c='Dummy Value');
				insert proofOfConcept;
			}
			return proofOfConcept;
		}
	}

	static Opportunity opportunity {
		get {
			if(opportunity == null) {
				opportunity = new Opportunity(
					Name='Test Opp',
					AccountId = account.Id,
					FulfillmentChannel__c='Indirect – VAR/VAD',
					CloseDate=System.today(),
					StageName='Prepare',
					Country_of_Order__c='United States');
				insert opportunity;
			}
			return opportunity;
		}
	}

	static Link_to_Paid_Opportunity__c link {
		get {
			if(link == null) {
				link = new Link_to_Paid_Opportunity__c(
					Proof_Of_Concept__c = proofOfConcept.Id,
					Paid_Opportunity__c = opportunity.Id);
				insert link;
			}
			return link;
		}
		set;
	}

	@isTest
    static void deleteAllTest() {
    	Test.setCurrentPage(new PageReference('/apex/LinkToPaidOpportunity_DeleteAll?pocId='+proofOfConcept.Id+'&retURL=testvalue.test'));
        ApexPages.StandardController sc = new ApexPages.StandardController(link);
		LinkToPaidOpportunityControllerExtension controller = new LinkToPaidOpportunityControllerExtension(sc);
		PageReference returnPage = controller.deleteAll();
		system.assert(returnPage != null);
		system.assertEquals('testvalue.test',returnPage.getUrl());
    }
}