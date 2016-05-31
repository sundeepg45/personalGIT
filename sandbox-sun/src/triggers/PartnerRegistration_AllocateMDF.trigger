trigger PartnerRegistration_AllocateMDF on Partner_Registration__c (after update) {

	private final string logTag = '[PartnerRegistration_AllocateMDF]';
	private final string STATUS_APPROVED = 'Approved';

	Partner_Registration__c newReg = trigger.new[0];
	Partner_Registration__c oldReg = trigger.oldMap.get(newReg.Id);

    if(newReg.Status__c == STATUS_APPROVED && oldReg.Status__c != STATUS_APPROVED){

	   system.debug(logTag + 'Status has been updated for ' + newReg.Name);
	    
	    if (!ThreadLock.lock('PartnerRegistration_AllocateMDF')){ 
	    	system.debug(logTag + 'TRIGGER HAS ALREADY EXECUTED, EXITING..');
	    	return;
	    }


	    
            // Calculate the mdf $ amount awarded to the partner
           decimal mdfAmount = newReg.MDF_Awarded__c;// PartnerRegistrationUtil.calculateParMdfAwardAmount(newReg);
           system.debug(logTag + 'MDF FUND REQUEST AMOUNT: ' + mdfAmount + ']'); 
            
            
	       // Find the MDF record for this partner.
           SFDC_Budget__c mdf = null;
	       String PAR_MDF_RECORD_TYPE_ID = [select Id from RecordType where SobjectType = 'SFDC_Budget__c' and DeveloperName = 'PAR'].Id;
           List<SFDC_Budget__c> mdfResults =   [SELECT s.Account_Master__c, Id, Name, s.Start_Date__c, s.Select_Fiscal_Year__c, s.Partner_Account__c, s.Allocated_Budget__c //s.Unique_Name_Constraint__c, s.Unclaimed__c, s.Unclaimed_Requests2__c, s.SystemModstamp, s.Start_Date__c, s.Select_Fiscal_Year__c, s.Script_Run_Check__c, s.Script_Last_Run_Date__c, s.Requests_Submitted__c, s.Requests_Awaiting_Approval__c, s.Refresh_Balances__c, s.RecordTypeId, s.Partner_Type__c, s.Partner_Tier__c, s.Partner_Manager__c, s.Partner_Manager_Email__c, s.Partner_Account__c, s.Note__c, s.Note_Request__c, s.Name, s.Marketing_Program_Manager__c, s.Marketing_Program_Manager_Title__c, s.Marketing_Program_Manager_Phone__c, s.Marketing_Program_Manager_Mobile__c, s.Marketing_Program_Manager_Email__c, s.Last_Refresh_Date__c, s.LastViewedDate, s.LastReferencedDate, s.LastModifiedDate, s.LastModifiedById, s.Key_Partner_Contact_2_Title__c, s.Key_Partner_Contact_2_Telephone__c, s.Key_Partner_Contact_2_Name__c, s.Key_Partner_Contact_2_Mobile__c, s.Key_Partner_Contact_2_Email__c, s.Key_Partner_Contact_1_Title__c, s.Key_Partner_Contact_1_Telephone__c, s.Key_Partner_Contact_1_Name__c, s.Key_Partner_Contact_1_Mobile__c, s.Key_Partner_Contact_1_Email__c, s.IsDeleted, s.Inside_Channel_Account_Manager__c, s.Inside_Channel_Account_Manager_Title__c, s.Inside_Channel_Account_Manager_Phone__c, s.Inside_Channel_Account_Manager_Mobile__c, s.Inside_Channel_Account_Manager_Email__c, s.Id, s.I_Agree_to_the_Terms_and_Conditions__c, s.Fiscal_Year__c, s.Fiscal_Quarter__c, s.End_Date__c, s.CurrencyIsoCode, s.CreatedDate, s.CreatedById, s.Claims_Submitted__c, s.Claims_Awaiting_Approval__c, s.Channel_Sales_Manager__c, s.Channel_Sales_Manager_Name__c, s.Channel_Marketing_Manager_Country__c, s.Channel_Account_Manager__c, s.Channel_Account_Manager_Title__c, s.Channel_Account_Manager_Phone__c, s.Channel_Account_Manager_Mobile_formula__c, s.Channel_Account_Manager_Email__c, s.Change_Record_Type_to_MDF__c, s.Available_Budget__c, s.Assign_Budget__c, s.Approved_Requests__c, s.Approved_Claims__c, s.Allocated_Budget__c, s.Active__c, s.Account_master__c
                                                                            FROM SFDC_Budget__c s
                                                                            WHERE Account_master__c = :newReg.Partner__c
                                                                                AND RecordTypeId = :PAR_MDF_RECORD_TYPE_ID
                                                                                AND Is_PAR__c = true 
                                                                          ORDER BY Start_Date__c DESC
                                                                          LIMIT 1];
			if (mdfResults.size() == 0) {
				System.debug(logTag + 'no MDF found, exiting');
				return;
			}
            mdf = mdfResults[0];

	       string qtr;
	       FiscalYearSettings fys = [select Id, PeriodId, StartDate, EndDate from FiscalYearSettings where StartDate <= :Date.today() and EndDate >= :Date.today()];
        
           for(Period p: [select StartDate, EndDate, Number from Period where FiscalYearSettingsId = :fys.Id and Type = 'Quarter' order by Number]){
                if(Date.today() >= p.StartDate && Date.today() <= p.EndDate){
                	qtr = 'Q' + string.valueOf(p.Number);
                	continue;
                }           	
           }
           system.debug(logTag + 'Current Red Hat fiscal quarter: [' + qtr + ']');
           
           
	       Id primaryPartnerContactId = newReg.Partner__r.PrimaryPartnerUser__r.ContactId;
	       if(primaryPartnerContactId == null){
	       	   system.debug(logTag + 'Looking up Primary Partner User for Partner Account..');
	       	   primaryPartnerContactId = [select PrimaryPartnerUser__r.ContactId from Account where Id = :newReg.Partner__c].PrimaryPartnerUser__r.ContactId;
	       }
           system.debug(logTag + 'Primary Partner Contact:' + primaryPartnerContactId);
           

		   
	       // Set the MDF Budget to Active
	       mdf.Active__c = true;
	       mdf.Start_Date__c = Date.today();
	       mdf.Select_Fiscal_Year__c = 'Current Fiscal Year';
	       mdf.Fiscal_Quarter__c = qtr;
	       mdf.End_Date__c = Date.today().addDays(360);
	       mdf.Key_Partner_Contact_1_Name__c = primaryPartnerContactId;
	       mdf.Allocated_Budget__c += mdfAmount;
           Database.Saveresult sr = Database.update(mdf);
           system.debug(logTag + 'SUCCESSFULLY UPDATED MDF: [' + mdf + ']');
           
           if(!sr.isSuccess()){
                system.debug(logTag + 'ERROR UPDATING MDF: [' + sr.getErrors() + ']');
                newReg.addError('Error updating MDF!');
                return;
           }


           Account endCustomer = [select Name from Account where Id = :newReg.End_Customer__c];

		   String parMdfReqRecTypeId = [select Id from RecordType where SobjectType = 'SFDC_MDF__c' and DeveloperName = 'PAR'].Id;

	       // Add an MDF Request (which will be auto approved)
	       SFDC_MDF__c newFundRequest = new SFDC_MDF__c(
	           RecordTypeId = parMdfReqRecTypeId,
	           Partner_Registration__c = newReg.Id,
	           Account_master__c = newReg.Partner__c,
	           Activity_Description__c = 'PAR Program auto-approved request',
	           Activity_End_Date__c = Date.today().addDays(360),
	           Activity_Start_Date__c = Date.today(),
	           Approval_Status__c = 'Draft',
	           Approved__c = true,
	           Approved_Date__c = Date.today(),
	           Budget__c = mdf.Id,
	           Date_Approved__c = Date.today(),
	           Date_of_Request__c = Date.today(),
	           I_Agree_to_the_Terms_and_Conditions__c = true,
	           Name = 'PAR' + ' ' + Date.today().year() + ' ' + endCustomer.Name,
	           Oracle_Project_Code__c = 'Not Applicable',
	           Partner_Manager__c = newReg.Account_Manager__c,
	           Status__c = 'Approved',
	           
	           Estimated_Red_Hat_Funding_Requested__c = mdfAmount,
               Total_Expenditure_of_Activity__c = mdfAmount
	       
	       );
	       insert(newFundRequest);
           system.debug(logTag + 'Created new Fund Request: [' + newFundRequest + ']');
           

           // Auto-approve the new Fund Request
           Approval.ProcessSubmitRequest approvalRequest = new Approval.ProcessSubmitRequest();
           system.debug(logTag + 'approvalRequest: [' + approvalRequest + ']');
           approvalRequest.setComments('Submitting request for auto-approval.');
           approvalRequest.setObjectId(newFundRequest.Id);
           system.debug(logTag + 'approvalRequest (updated): [' + approvalRequest + ']');
           Approval.ProcessResult approvalResult = Approval.process(approvalRequest);
           
           system.debug(logTag + 'Approval Process Result: [' + approvalResult + ']');
           
           if(approvalResult.isSuccess()){
           	    // Approve the request
           	    List<Id> workItemIdList = approvalResult.getNewWorkitemIds();
      
      // PROBLEM - Unit test is failing becuase this list is empty 
      system.debug(logTag + 'Approval status: [' + approvalResult.getInstanceStatus() + ']');
      system.debug(logTag + 'Approval process work items: []' + workItemIdList + ']');     	    
           	    
           	    Approval.Processworkitemrequest req = new Approval.Processworkitemrequest();
           	    req.setComments('Auto-approving PAR MDF Fund Request.');
           	    req.setAction('Approve');
           	    req.setNextApproverIds(new Id[] {UserInfo.getUserId()});
        
	           // Use the ID from the newly created item to specify the item to be worked
	           req.setWorkitemId(workItemIdList.get(0));
        
               // Submit the request for approval
               Approval.ProcessResult result2 =  Approval.process(req);
               
               // Verify the results
               System.assert(result2.isSuccess(), 'Result Status:'+result2.isSuccess());
        
		       System.assertEquals(
		            'Approved', result2.getInstanceStatus(), 
		            'Instance Status'+result2.getInstanceStatus());
		            
           } else {
           	    system.debug(logTag + 'FAILED TO SUBMIT FUND REQUST TO APPROVAL PROCESS. Errors: [' + approvalResult.getErrors()[0].getMessage() +  ']');
           }


	    




	}




}