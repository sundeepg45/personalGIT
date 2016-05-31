trigger Lead_PartnerFCPAReviewKickoff on Lead (after insert, after update) {
    List<Lead> fcpaFailures = new List<Lead>();
    
    for (Lead l : Trigger.new){
        if ((Trigger.isInsert && l.Anti_Corruption_Status__c == 'Anti-Corruption Review Required')
             || (l.Anti_Corruption_Status__c == 'Anti-Corruption Review Required' 
                    && Trigger.oldMap.get(l.Id).Anti_Corruption_Status__c != l.Anti_Corruption_Status__c)){
            fcpaFailures.add(l);
        }
    }
    
    if (fcpaFailures.size() > 0){
        List<Anti_corruption__c> acl = new List<Anti_corruption__c>();
        for (Lead l : fcpaFailures){
            Anti_corruption__c ac = new Anti_corruption__c();
            
            ac.Origin__c = 'Onboarding';
            ac.Lead__c = l.Id;
            ac.Ever_Convicted__c = l.Have_they_been_convicted__c == 'Yes';
            ac.Government_Position__c = l.Do_they_act_in_any_government_position__c == 'Yes';
            ac.Underlying_Facts__c = l.FCPA_Underlying_Facts__c;

            acl.add(ac);
            
        }
        insert acl;
        
        for (Anti_corruption__c ac : acl){
            Approval.ProcessSubmitRequest approvalReq = new Approval.ProcessSubmitRequest();   
            approvalReq.setComments('Lead Submitted for Anti-Corruption Check.');         
            approvalReq.setObjectId(ac.Id);
            // Submit the approval request
           Approval.ProcessResult result = Approval.process(approvalReq);
        }
        
    }
}