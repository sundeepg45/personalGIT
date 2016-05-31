/**
* Class Name:leaddetailInfoTest
* Description:Test Class created for leaddetailInfo business Class.
* Modificaton History:
* Modified By:Ratan Sharma
* Modified date :4/29/2011
* Reason for Modification:Separated test class from business class and created a new test class
*/


@isTest
private class leaddetailInfoTest
{
	public static testMethod void deployLeaddetailInfo() 
    {
    	
    	Account acc = new Account(Name='Test Account');
        insert acc;
        
        Opportunity  oppNew;
        
        Lead NALead= new Lead();
        NALead.status='Deal Registartion';
        NALead.LastName='TEST_LEADDetailInfo'; 
        NALead.LeadSourceDetail__c='Deal Registartion';
        NALead.email='abc@xyz.com';
        NALead.Company='Accenture';
        NALead.STATE='OH';  
        NALead.Country='US';  
        NALead.RecordTypeId='0126000000058QX';
        NALead.Red_Hat_Subscription_Revenue__c = 100.00;
        //NALead.ConvertedOpportunityId = oppNew.Id;
        insert NALead;
        
        Opportunity  oppNewObj = new Opportunity(Name='Test Opp',closedate=System.today(),stageName='Unqualified',AccountId=acc.Id,Country_of_Order__c ='India');
        insert oppNewObj;
        
        // Create an approval request for the account  
    
        test.startTest();
        
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Submitting request for approval.');
        req1.setObjectId(NALead.id);
        
        // Submit the approval request for the lead
            
        Approval.ProcessResult result = Approval.process(req1);
        
        // Verify the result
		System.assert(result.isSuccess());
		System.assertEquals('Pending', result.getInstanceStatus(), 'InstanceStatus'+result.getInstanceStatus());
        
        // Approve the submitted request  
   
        // First, get the ID of the newly created item  
            
        List<Id> newWorkItemIds = result.getNewWorkitemIds();
        
        // Instantiate the new ProcessWorkitemRequest object and populate it  
            
        Approval.ProcessWorkitemRequest req2 = new Approval.ProcessWorkitemRequest();
        req2.setComments('Approving request.');
        req2.setAction('Approve');
        req2.setNextApproverIds(new Id[] {UserInfo.getUserId()});
        
        // Use the ID from the newly created item to specify the item to be worked  
            
        req2.setWorkitemId(newWorkItemIds.get(0));
        
        // Submit the request for approval  
            
        Approval.ProcessResult result2 =  Approval.process(req2);
        
        // Verify the results
		System.assert(result2.isSuccess(), 'Result Status:'+result2.isSuccess());
		System.assertEquals('Approved', result2.getInstanceStatus(), 'InstanceStatus'+result2.getInstanceStatus());
        
        Database.LeadConvert lc = new database.LeadConvert();
        lc.setLeadId(NALead.id);
        LeadStatus convertStatus = [Select Id, MasterLabel from LeadStatus where IsConverted=true limit 1];
        lc.setConvertedStatus(convertStatus.MasterLabel);
        Database.LeadConvertResult lcr = Database.convertLead(lc);
        String Id = lcr.getOpportunityId();
        oppNew = [Select Id from Opportunity where Id =: Id];
        
        ApexPages.StandardController standardController = new ApexPages.StandardController(oppNew);
        leaddetailInfo detailInfo = new leaddetailInfo(standardController);
        detailInfo.getObjOpp(oppNew.Id);
        detailInfo.getObjLead(oppNew.Id);
        detailInfo.getObjOpp();
        detailInfo.getObjLead();
        detailInfo.getLeadUser();
        //detailInfo.getLeadInstance();
        detailInfo.getLeadInstanceStep();
        
        ApexPages.StandardController standardControllerObj = new ApexPages.StandardController(oppNewObj);
        leaddetailInfo detailInfoObj = new leaddetailInfo(standardControllerObj);
        detailInfoObj.getObjOpp(oppNewObj.Id);
        detailInfoObj.getObjLead(oppNewObj.Id);
        detailInfoObj.getObjOpp();
        detailInfoObj.getObjLead();
        detailInfoObj.getLeadUser();
        detailInfoObj.getLeadInstances();
        detailInfoObj.getLeadInstanceStep();
        
        test.stopTest();
     }  
 }