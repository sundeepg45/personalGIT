trigger BusinessPlan_UpdateApprovalOnLocalizedCopy on SFDC_Channel_Account_Plan__c (before update) {
	//
	// Fetch a list of business plans with the partner global region and subregion
	// - ensure that the global region is APAC
	// - ensure that the subregion is one of Japan, Korea, or Greater China
	//
	
	Map<Id, SFDC_Channel_Account_Plan__c> businessPlanMap = new Map<Id, SFDC_Channel_Account_Plan__c>([
	    select Partner_Name__r.Global_Region__c
	         , Partner_Name__r.Subregion__c
	      from SFDC_Channel_Account_Plan__c
	     where (Id in :Trigger.new)
	       and (Partner_Name__r.Global_Region__c = 'APAC')
           and (Partner_Name__r.Subregion__c in ('Japan', 'Greater China', 'Korea'))
	]);
	
	if (businessPlanMap.size() == 0)
	    return;
	
    //
    // Task list items
    //
    
    List<Task> dependentTaskList = new List<Task>();

	//
	// Loop plans
	//
	
	for(SFDC_Channel_Account_Plan__c businessPlan : Trigger.new) {
		SFDC_Channel_Account_Plan__c businessPlanOld = Trigger.oldMap.get(businessPlan.Id);
		
		//
		// New version must be active and in an Approved status.
		//
		
        if (businessPlan.Active__c == false)
            continue;
		if (businessPlan.Approval_Status__c != 'Approved')
	        continue;
	        
	    //
	    // old version must NOT be in an Approved state. Ie, the businessPlan was updated from a 
	    // non-approved to an approved copy. Anything other status and we ignore it for the 
	    // purposes of this trigger.
	    //
	    
        if (businessPlanOld.Approval_Status__c == 'Approved')
            continue; 

        //
        // Make sure that the map contains this business plan. The SOQL above is designed in 
        // such a way to only select business plans relevant to this trigger. If the Id isn't
        // present, we continue.
        //
        
        if (businessPlanMap.containsKey(businessPlan.Id) == false)
            continue;
        
        //
        // Fetch all related business plans that belong to this plan's parent account: 
        // - restrict to the same FY only.
        // - exclude the current plan we are updating.
        // - exclude already approved plans.
        //
        
        List<SFDC_Channel_Account_Plan__c> dependentPlanList = [
           select Business_Plan_Approval_Date__c
                , Business_Plan_Active__c
                , Business_Plan_Version__c
                , Approval_Status__c 
             from SFDC_Channel_Account_Plan__c 
            where Approval_Status__c != 'Approved'
           /* and Approval_Status__c in ('Draft', 'Rejected') */
              and Partner_Name__c = :businessPlan.Partner_Name__c
              and Fiscal_Year__c = :businessPlan.Fiscal_Year__c
              and Id != :businessPlan.Id
        ];

        //
        // No other business plans means nothing to do
        //
        
        if (dependentPlanList.size() == 0)
            continue;

	    //
	    // Update the approval status and date, and add a task log entry
	    //
	    for(SFDC_Channel_Account_Plan__c dependentPlan : dependentPlanList) {
	    	// update the plan
	        dependentPlan.Business_Plan_Approval_Date__c = Date.today();
	        dependentPlan.Approval_Status__c = 'Approved';
	        
	        // subject
	        String taskSubject = 'Approved: ' + businessPlan.Name;
	        
	        if (taskSubject.length() > 75)
	            taskSubject = taskSubject.substring(0, 75) + '...';
	        
	        // add a task
	        dependentTaskList.add(new Task(
                Status = 'Completed',
                Subject = taskSubject,
	            Description = Schema.Sobjecttype.SFDC_Channel_Account_Plan__c.Fields.Partner_Name__c.Label
    	                    + ' "' + businessPlan.Name + '"'
	                        + '\n '
	                        + Schema.Sobjecttype.SFDC_Channel_Account_Plan__c.Fields.Approval_Status__c.Label
	                        + ' "' + businessPlan.Approval_Status__c + '"',
                Type = 'Other',
                WhatId = dependentPlan.Id
	        ));
	    }
	    
	    //
	    // Update the dependent plans
	    //
	    
	    update dependentPlanList;
    }
    
    //
    // Insert the task list
    //
    
    insert dependentTaskList;
    
    
    /*
    SFDC_Channel_Account_Plan__c BizPlan  = Trigger.new[0];
    SFDC_Channel_Account_Plan__c oldBizPlan = Trigger.old[0];
    List<SFDC_Channel_Account_Plan__c> updateList = new List<SFDC_Channel_Account_Plan__c>();
    
    if(BizPlan.Approval_Status__c == 'Approved'  && oldBizPlan.Approval_Status__c <> 'Approved' && BizPlan.Active__c) {
        Account acc = [
           select Id
                , Global_Region__c
                , Subregion__c 
             from Account 
            where Id = :Bizplan.Partner_Name__c
        ];
    
        if (acc.Global_Region__c  =='APAC' && (acc.SubRegion__c == 'Korea' || acc.Subregion__c == 'Greater China' || acc.Subregion__c == 'Japan')) {
            List<SFDC_Channel_Account_Plan__c> accountsBps = [
               select Business_Plan_Approval_Date__c
                    , Business_Plan_Active__c
                    , Business_Plan_Version__c
                    , Approval_Status__c 
                 from SFDC_Channel_Account_Plan__c 
                where Partner_Name__c = :acc.Id 
            ];
            
            for(SFDC_Channel_Account_Plan__c bp: accountsBps) {
                Double ver1 = BizPlan.Business_Plan_Version__c; 
                Double ver2 = bp.Business_Plan_Version__c; 
                Double diff = ver1 - ver2; 
                System.debug('value test:' + diff);
                
                if(bp.Approval_Status__c == 'Approved')
                    continue;
                if(bp.id == BizPlan.Id)
                    continue;
                        
                if(diff > 1) {
                    bp.Business_Plan_Active__c = bp.Business_Plan_Active__c  + bp.Id;
                    updateList.add(bp);
                    system.debug('bp added in first if statement:' + bp);
                }
                
                System.debug('bp.id: ' + bp.id + 'BizPlan.Id: ' + BizPlan.Id);
                
                if(diff < 2 && ver1 > ver2) {
                    bp.Approval_Status__c = 'Approved'; 
                    bp.Business_Plan_Approval_Date__c = System.today();
                    updateList.add(bp); 
                    system.debug('bp added in second if statement:' + bp);
                }
                
                System.debug('updateList' + updateList);
             }
             
             update updateList;
        }
    
    }
    
    */
}