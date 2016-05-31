/**
 *
* @author Rajiv Gangra <rgangra@DELOITTE.com>
* @version 2015-05-013
* 2015-05-13 - initial version
*/
trigger OpportunityHeaderStagingTrigger on Opportunity_Header_Staging__c (After Update) {
    set<id> setRelatedOHSRecords= new set<id>();
    static final String READY_FOR_REPROCESSING = 'Ready For Reprocessing';
    static final String ERROR = 'Error';
    List<Order_to_opp_data_metrics__c>  listOppMetricsRec=new List<Order_to_opp_data_metrics__c>();
    //Logic to get list of records related to Header staging record that went to processed status
    if(trigger.IsUpdate){
        for(Opportunity_Header_Staging__c oHS:trigger.new){
            if(oHS.Order_Status__c=='BOOKED' && Trigger.newMap.get(oHS.Id).Status__c=='Processed' && (Trigger.oldMap.get(oHS.Id).Status__c=='ERROR' || Trigger.oldMap.get(oHS.Id).Status__c==READY_FOR_REPROCESSING)){
                setRelatedOHSRecords.add(oHS.id);    
            }
        }
        listOppMetricsRec.addAll([select id,Name from Order_to_opp_data_metrics__c where Opportunity_Header_Staging__c IN:setRelatedOHSRecords]);
    }
    if(listOppMetricsRec !=null && listOppMetricsRec.size()>0){
        delete listOppMetricsRec;
    }
}