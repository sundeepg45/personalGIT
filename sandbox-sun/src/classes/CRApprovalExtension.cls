/*
Checks if the CR has any line items. If no shows an error else submits cr for approval
Req - If done as an entry criteria on approval, error msg is not clean
Button on CR - "Submit Reference"
*/
public class CRApprovalExtension {

  private ApexPages.StandardController controller;

   /* Submits an object for approval*/
    public static Approval.ProcessResult submitForApproval(Id objId, String message) {
        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setComments(message);
        req.setObjectId(objId);
        Approval.ProcessResult result = Approval.process(req,false);
        return result;
    }

  public CRApprovalExtension(ApexPages.StandardController controller) {
    this.controller = controller;
  }

    public Customer_Reference__c getCustomerReference() {
        return (Customer_Reference__c) controller.getRecord();
    }
 
  
  //called as an init action from the VF page
  public PageReference submitForApproval() {
  //  Id sprId = 
    Customer_Reference__c cr = [Select CRP_Count__c, Name from Customer_Reference__c where Id = :this.controller.getId()];
    if (cr.CRP_Count__c == null || cr.CRP_Count__c == 0) { 
      ApexPages.addMessage(new ApexPages.Message(ApexPages.SEVERITY.ERROR, 'Customer References without products cannot be submitted for approval. Please use the buttons below to choose your next action.'));
      
    } else {
      try {
        Approval.ProcessResult result = submitForApproval(this.controller.getId(), 'Submitting Customer Reference for Approval.');
        if (result.isSuccess()) {
          ApexPages.addMessage(new ApexPages.Message(ApexPages.SEVERITY.INFO, 'Customer Reference submitted for approval.'));
        } else {
          ApexPages.addMessage(new ApexPages.Message(ApexPages.SEVERITY.ERROR, 'Failed to submit Customer Reference for approval. There are no matching Approval Policies for Customer References that are already approved or in an approval process'));
        }
      } catch(Exception e) {
        ApexPages.addMessage(new ApexPages.Message(ApexPages.SEVERITY.ERROR, e.getMessage()));
      }
    }
    return null;
  }

  public PageReference addProducts() {

    //get the objectID
    Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
    Schema.DescribeSObjectResult r = gd.get('Customer_Reference_Product__c').getDescribe();
    String url = '/'+r.getKeyPrefix()+'/e?';
    
    //build the URL
      String pageUrl = url+'CF00NT000000192yD_lkid='
                     + getCustomerReference().Id
                     + '&CF00NT000000192yD='
                     + getCustomerReference().Name;
  
      PageReference pageReference = new PageReference(pageUrl);
      pageReference.setRedirect(true);
      return pageReference;
  }
}