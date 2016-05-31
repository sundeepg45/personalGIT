/*
author: Mike DeMeglio (mdemegli@redhat.com)
description: Prevents any user from unchecking the "Is_PAR__c" field on the Opportunity. Because of the customizations to the Opportunity detail page we
                    cannot use the standard SFDC declarative methods to enforce field-level security (the field is read-only to every profile but can still be edited 
                    due to the customizations of the OpportunityView vf page).
*/                    
trigger Opportunity_PreventIsPARModification on Opportunity (before update) {

    final string logTag = '[Opportunity_PreventIsPARModification]';
    
    for(Opportunity newOpp:trigger.new){
    	Opportunity oldOpp = trigger.oldMap.get(newOpp.Id);
    	if(newOpp.Is_PAR__c != oldOpp.Is_PAR__c){
    		newOpp.addError('The Is PAR flag cannot be changed by any user.');
    		
    	}    	
    }
    
}