trigger OpportunityAmount_LeadConversion on Lead (Before Update) {
     Map<Id,Lead> oppIdLeadIds = new Map<Id,Lead>();
     for(Lead l:trigger.new){
        if(L.IsConverted &&  L.Business_Unit__c=='Mobile'){
           oppIdLeadIds.put(L.ConvertedOpportunityId,L);
        }
     }
     
     Map<Id,Opportunity> createdOpp = new Map<Id,Opportunity>([select id,RecordType.Name,Amount from Opportunity where Id IN:oppIdLeadIds.Keyset()]);
     
     for(Opportunity opp:createdOpp.Values()){
         if(opp.RecordType.Name=='NA Sales Opportunity'){
            opp.Amount= 100000;
         }
         if(opp.RecordType.Name=='EMEA Sales Opportunity' || opp.RecordType.Name=='LATAM Sales Opportunity' || opp.RecordType.Name=='APAC Sales Opportunity' ){
            opp.Amount= 75000;
         }
     }
     
     if(createdOpp.size()>0) update createdOpp.Values();
}