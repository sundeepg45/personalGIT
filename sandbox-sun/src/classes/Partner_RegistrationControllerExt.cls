public with sharing class Partner_RegistrationControllerExt {

    private ID accountid;
    public Partner_Registration__c reg {get; private set;}
    public Boolean isFinancesApproved { get; private set; }
    public Boolean isEnrolled { get; private set; }
    public Boolean isEditable {get;private set;}
    public Boolean attachmentComplete {get; private set;}
    public Boolean isRegApprovalSubmitted {get; private set;}
    public Boolean hasProducts {get; private set;}
    public Boolean saveComplete {get; private set;}
    public Boolean mdfCalcd {get; private set;}
    public Account acct {get; private set;}
    public List<Partner_Registration_Line_Item__c> regLineItems {get; private set;}
    public Decimal oppTotalAmt {get; private set;}
    public Decimal influencedAmtTotal {get; private set;}
    public Decimal allocationTotal {get; private set;}
        
    private final string logTag = '[Partner_RegistrationControllerExt]';
    
    public Attachment proofOfPerf {
        get {
            if(proofOfPerf == null){
              proofOfPerf = new Attachment(); 
            }
            return proofOfPerf;
        }
        set;
    }


    public Partner_RegistrationControllerExt(ApexPages.StandardController stdController) {
        
    	User me = [select ContactId, Contact.AccountId from User where Id = :UserInfo.getUserId()];
        Boolean isPartner = me.ContactId != null;
        Id regId = stdController.getRecord().Id;
        saveComplete = false;
        
        if(regId != null){
        	system.debug(logTag + 'Registration Id: [' + regId + ']');
            reg = [Select p.Status__c,  p.Proof_of_Performance_Docs_Uploaded__c, p.Project_Description__c, p.Project_Budget__c, p.Product_Family__c, p.Partner__c, p.Opportunity__c, p.Opportunity_Close_Stage__c, p.Opportunity_Close_Date__c, p.Opportunity_Actual_Amount__c, p.Name, p.Id, p.Has_Expiration__c, p.Expiration_Extended__c, p.Expiration_Date__c, p.Estimated_Close_Date__c, p.End_Customer__c, p.End_Customer_Manager__c, p.Current_Approval_Step__c, p.CurrencyIsoCode, p.Company_Street_2__c, p.Company_Street_1__c, p.Company_State__c, p.Company_Postal_Code__c, p.Company_Name__c, p.Company_Country__c, p.Company_Contact__c, p.Company_Contact_Title__c, p.Company_Contact_Phone__c, p.Company_Contact_Mobile__c, p.Company_Contact_Job_Function__c, p.Company_Contact_Email__c, p.Company_City__c, p.Channel_Ops_Approver__c, p.Account_Manager__c 
                    From Partner_Registration__c p where Id =:regId];
    	    accountid = reg.Partner__c;
    	    isEditable = (isPartner && reg.Status__c == 'Open') || !isPartner; //(!isPartner && (reg.Status__c == 'Approved' || reg.Status__c == 'Closed'));
        } else {
    		reg = (Partner_Registration__c)stdController.getRecord();
    	    accountid = me.Contact.AccountId;
        	isEditable = true;
    	}
        // If the user is a partner AND the reg status is "Open" let them edit it, if it's not a partner they can edit it any time as certain fields have to be set during the approval process.
        //if (me.ContactId == null) {
       /* if(!isPartner){
            // must be an admin, do nothing
            NoDataFoundException ex = new NoDataFoundException();
            ex.setMessage('Only partner users can create registrations');
            throw ex;
        }*/
        acct = [select Is_Financials_Approved__c, OwnerId, Name, Global_Region__c from Account where Id = :accountid];
        isFinancesApproved = acct.Is_Financials_Approved__c;
        Partner_Program__c[] pgmlist = [
            select Id
            from   Partner_Program__c
            where  Program__r.Program_Category__c LIKE 'Partner Assistance Reward%'
            and    Account__c = :accountid
            and    Status__c in ('Active','Approved')
        ];
        
        if (!pgmlist.isEmpty()) isEnrolled = True;
       
    }

    public Boolean getIsEnrolled() {
        return isEnrolled;
    }

    public Boolean getIsFinancesApproved() {
        return isFinancesApproved;
    }



    public PageReference save() {
    	if (reg.Partner__c == null) reg.Partner__c = accountid;
        reg.Name = reg.Company_Name__c;
        reg.Account_Manager__c = acct.OwnerId;
        insert reg;
        //return submitForApproval();
        ApexPages.addMessage(  new ApexPages.Message(ApexPages.Severity.CONFIRM, System.Label.Partner_Registration_Submit_for_Approval_Instructions) );
        return page.PAR_Registration_Submit;
    }

    public PageReference cancel() {
        return new PageReference('/' + accountid);
    }

    public PageReference cancelAttachment() {
        //return new PageReference('/' + reg.Id); // Return to Partner Registration detail page
        return returnToRegPage();
    }
    
    public PageReference returnToRegPage(){
    	return new PageReference('/' + reg.Id); // Return to Partner Registration detail page
    }

    public Boolean isReadyForFinalApproval(){

    	if(reg.Status__c == 'Approved'){
            ApexPages.addMessage(  new ApexPages.Message(ApexPages.Severity.INFO,'This registration has already been approved.') );
            return false;
        }



        if(reg.Status__c == 'Pending Opportunity Close'){
        	ApexPages.addMessage(  new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.Opp_must_be_closed_won_before_reg_final_approval) );
            return false;
        }


        // If this is the first approval (when the Status is "Open") they can submit it for approval, but if it's the 2nd approval process, they need to upload their Proof of Performance docs first.
        //if( (reg.Status__c != null && reg.Status__c != 'Open') && reg.Proof_of_Performance_Docs_Uploaded__c == null){
        if(reg.Status__c == 'Pending Proof of Performance Approval' && reg.Proof_of_Performance_Docs_Uploaded__c == null){
            ApexPages.addMessage(  new ApexPages.Message(ApexPages.Severity.ERROR,System.Label.Proof_of_Performance_docs_missing) );
            return false;
        }

        return true;
    }


    public PageReference submitForApproval(){

        if(!isReadyForFinalApproval()) return null;

        // add to approval process
        ApexPages.Message msg;
        Approval.ProcessSubmitRequest approvalRequest = new Approval.ProcessSubmitRequest();
        approvalRequest.setComments('Submitting request for approval.');
        approvalRequest.setObjectId(reg.Id);
        Approval.ProcessResult approvalResult;
        
        //try{
            approvalResult = Approval.process(approvalRequest);
            system.debug('APPROVAL RESULT: [' + approvalResult + ']');
        //} catch (DmlException e){
            //msg = new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.Partner_Registration_Approval_In_Process);

            // THIS DOESN'T GET CAUGHT FOR SOME REASON
        //}

        if(approvalResult != null && approvalResult.isSuccess()){
            msg = new ApexPages.Message(ApexPages.Severity.CONFIRM, System.Label.Partner_Registration_Submitted_for_Approval_Complete);
            isRegApprovalSubmitted = true;
        } else {
        	msg = new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.Partner_Registration_Approval_In_Process);
        }
        ApexPages.addMessage(msg);

        return null;
    }



    public PageReference attachPopDocuments(){

        if(proofOfPerf.Body == null){
        	ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, System.Label.No_file_to_attach));
            return null;
        }

        proofOfPerf.OwnerId = UserInfo.getUserId();
        proofOfPerf.ParentId = reg.Id;
        proofOfPerf.Description = System.Label.Proof_of_Performance_Invoice;
        
        try {
            insert(proofOfPerf);
            reg.Proof_of_Performance_Docs_Uploaded__c = DateTime.now();
            update(reg);
            attachmentComplete = true;
         } catch (DMLException e) {
         	system.debug(e);
         	ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, System.Label.Error_uploading_file + e.getDmlMessage(0) + ')'));
         	attachmentComplete = false;
            return null;
          } finally {
            proofOfPerf.body = null; // clears the viewstate;
            proofOfPerf = new Attachment();
         }

          ApexPages.addMessage(new ApexPages.message(ApexPages.severity.CONFIRM, System.Label.Document_Upload_Successful));
          return null;
    }


    public void loadRegLineItems(){
    	
    	if(reg.Opportunity__c == null) return;
    	if(regLineItems == null) regLineItems = new List<Partner_Registration_Line_Item__c>();
    	if(reg.Status__c == 'Approved'){
    		ApexPages.addMessage(new ApexPages.message(ApexPages.severity.WARNING, System.Label.Cannot_update_allocations_after_Reg_Approved));
            saveComplete = true;
            return;
        }
    	saveComplete = false;
    	influencedAmtTotal = 0.00;
    	allocationTotal = 0.00;
    	oppTotalAmt = 0.00;
    	
    	// 1. Look up existing Reg Line Items..
    	regLineItems = [select Id, Product_Family__c, Region__c, Opportunity_Product_Amount__c, Product_Allocation_Percent__c, Influenced_Amount__c, Total_Allocation__c   FROM Partner_Registration_Line_Item__c WHERE Partner_Registration__c = :reg.Id];
    	    
    	if(!regLineItems.isEmpty()){
    		hasProducts = true;
    		mdfCalcd = true;
    		for(Partner_Registration_Line_Item__c li:regLineItems){
    			influencedAmtTotal += li.Influenced_Amount__c;
    			allocationTotal += li.Total_Allocation__c;
    			oppTotalAmt+= li.Opportunity_Product_Amount__c;
    		}
    		
    	} else {
    		
	        AggregateResult[] arl = [Select SUM(o.TotalPrice) Total, o.PricebookEntry.Product2.Primary_Business_Unit__c ProductFamily 
			                                        From OpportunityLineItem o 
			                                        where OpportunityId = :reg.Opportunity__c GROUP BY o.PricebookEntry.Product2.Primary_Business_Unit__c];
	        hasProducts = arl.size() > 0;
	        system.debug(logTag + 'Opp Products Ag Result :' + arl);
	        system.debug(logTag + 'Opp Products Ag Result Size: ' + arl.size());
	    	
	    	if(arl.isEmpty()){	    		
	    		ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, System.Label.Opportunity_has_no_products_associated));
                return;
	    	}
	    	
	    	for(AggregateResult ar:arl){
	    		
	    		string prodFamily = string.valueOf(ar.get('ProductFamily'));
	    		decimal prodTotal = ((decimal)ar.get('Total'));
	    		system.debug(logTag + 'Creating reg line item for [' + prodFamily + '], Total opp value: [$' + prodTotal + ']');
	    		
	    		Partner_Registration_Line_Item__c newRegLineItem = new Partner_Registration_Line_Item__c(
	               Product_Family__c = prodFamily,
	               Partner_Registration__c = reg.Id,
	               Region__c = acct.Global_Region__c,
	               Opportunity_Product_Amount__c = prodTotal
	            );
	            regLineItems.add(newRegLineItem);
	            oppTotalAmt+= prodTotal;
	                		
	    	}    	
    	    system.debug(logTag+ 'Total Reg Line Items: [' + regLineItems.size() + ']');
    	    
    	}
    	
    }
    
    
    public PageReference cancelAllocation(){
    	//return new PageReference('/' + reg.Id).setRedirect(true);
    	return returnToRegPage();
    }
    
    
    public PageReference saveRegLineItems(){
    	
    	if(regLineItems == null) return null;
    	
    	if(!validate()) return null;
    	
    	// Look up the pre-defined MDF allocation percentages for each Product Family (e.g. Platform = 6%, Middleware = 10%, etc)
    	Map<String,PAR_MDF_Allocations__c> allocMap = PAR_MDF_Allocations__c.getAll();
    	for(Partner_Registration_Line_Item__c li:regLineItems){
    	    if(allocMap.get(li.Product_Family__c) == null){ 
    	    	system.debug(logTag + 'NO ALLOCATION PERCENTAGE FOUND FOR [' + li.Product_Family__c + ']'); 
    	    	continue;
    	    } else {
    	       Decimal pct = allocMap.get(li.Product_Family__c).Percentage__c;
    	       li.Product_Allocation_Percent__c = pct;
    	       system.debug(logTag + 'Allocation percentage for [' + li.Product_Family__c + '] is [' + pct + ']');
    	    }
    	 }
    	
    	try{
    		  upsert(regLineItems);
    		  saveComplete = true;
    		  mdfCalcd = true;
    		  loadRegLineItems();
    		  system.debug(logTag + 'Successfully inserted [' + regLineItems.size() + '] registration line items for PAR Registration [' + reg.Name + ']');
    		  ApexPages.addMessage(new ApexPages.message(ApexPages.severity.CONFIRM, System.Label.Product_MDF_Allocations_Saved));
        } catch (DmlException e){
    		system.debug(logTag + 'Error inserting registration line items: [' + e.getMessage() + ']');
    		ApexPages.addMessages(e);
    	}
    	
    	return null;
    	
    }
    
    
    private boolean validate(){
    	integer errorCount = 0;
    	for(Partner_Registration_Line_Item__c li:regLineItems){
    		
    		// Influenced Amt is greater than the Opp Line Item amt..
    		if(li.Influenced_Amount__c > li.Opportunity_Product_Amount__c){
    			li.addError(System.Label.Influenced_Amount_Greater_than_Opp_Prod_Amt + ': ' +  li.Product_Family__c);
    			errorCount++;
    		}
    		
    		// Influenced Amt is negative
    		if(li.Influenced_Amount__c < 0.00){
                li.addError(System.Label.Influenced_Amount_Cannot_Be_Negative + '  ' +  li.Product_Family__c);
                errorCount++;
            }
    		
    	}
    	return errorCount == 0;
    }
    

}