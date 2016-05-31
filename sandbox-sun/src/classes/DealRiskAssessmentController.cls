global class DealRiskAssessmentController{
      webservice static void doSubmitApprovals(string recid){
       Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Submitting request for approvals');
        req1.setObjectId(recid);
        //req1.setNextApproverIds(new Id[] {asdf,asdfasd});
        // Submit the approval request for the Opportunity
        Approval.ProcessResult result = Approval.process(req1);
     }
     
      webservice static integer attachmentsCount(string recid){
        return [select id from attachment where parentid=:recid].size();
     }
      
     public Boolean Show_Hide_ApprovalsButton{get;set;}
      public final ApexPages.StandardController controller;
      public string recid;
      public Boolean refreshPnl{get;set;}
      public DealRiskAssessmentController(ApexPages.StandardController stdController) {
        controller = stdController;
        recid=ApexPages.CurrentPage().getParameters().get('id');
        refreshPnl=false;
       list<ProcessInstance> existingApprovals = [SELECT Id, TargetObjectId FROM ProcessInstance WHERE TargetObjectId =:recid AND Status='Pending'];
       System.Debug('Record ID@@@ '+recid+' ###Approvals !!!'+existingApprovals.size());
       if(existingApprovals.size()==0){
          Show_Hide_ApprovalsButton=true;
       }else{
          Show_Hide_ApprovalsButton=false;
       }
      }  
      
      public PageReference submitDRA() {
      List<Attachment> attchmntLst = [select id,parentid from Attachment where parentId=:recid];
      if(attchmntLst.size()==0){
         ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Make sure that you attach the Financial analysis spreadsheet as well as Appendix 3 to this assessment before submitting it for approval.');
            ApexPages.addMessage(myMsg);
         return null;
      }
        PageReference retval = null;
        try {
            Approval.ProcessSubmitRequest submitRequest = new Approval.ProcessSubmitRequest();
            submitRequest.setObjectId(recid);
            Approval.ProcessResult result = Approval.process(submitRequest);
            
            refreshPnl=true;
            Show_Hide_ApprovalsButton=false;
        }
        catch(Exception e) {
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,e.getMessage()));
        }
        return null;
    }
}