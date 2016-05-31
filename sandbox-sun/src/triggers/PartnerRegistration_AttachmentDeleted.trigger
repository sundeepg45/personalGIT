trigger PartnerRegistration_AttachmentDeleted on Attachment (after delete) {

    final string logTag = '[PartnerRegistration_AttachmentDeleted]';
    Schema.DescribeSObjectResult partnerRegSObject = Partner_Registration__c.sObjectType.getDescribe();
    string partnerRegKeyPrefix = partnerRegSObject.getKeyPrefix();
    system.debug('key prefix: [' + partnerRegKeyPrefix + ']');
    Set<Id> regIdSet = new Set<Id>();
    
    if(trigger.isDelete && trigger.isAfter){
    	for(Attachment oldAtt:trigger.old){
    		string parentId = oldAtt.ParentId;
    		if(parentId != null && parentId.startsWith(partnerRegKeyPrefix)){
    			system.debug(logTag + 'Attachment is for a Partner Registration record');
    		    // add parentId to list so we can clear out the proof-of-performance timestamp field later
    		    regIdSet.add(parentId);
    		}
    	}
    }
    
    List<Partner_Registration__c> regUpdates = [select Id from Partner_Registration__c where Id IN :regIdSet]; 
    for(Partner_Registration__c pr:regUpdates){
        pr.Proof_of_Performance_Docs_Uploaded__c = null;    	
    }
    
    if(!regUpdates.isEmpty()){
    	update(regUpdates);
    }
    
}