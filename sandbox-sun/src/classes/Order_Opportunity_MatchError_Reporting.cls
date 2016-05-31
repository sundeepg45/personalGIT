/**
* This class defines the logic for  opportunity matching Error Handling to help create report 
 *
* @author Rajiv Gangra <rgangra@DELOITTE.com>
* @version 2015-05-07
* 2015-05-07 - initial version
*/
global class Order_Opportunity_MatchError_Reporting implements Database.Batchable<sObject>, Database.Stateful 
{
    public list<String> errorList = new list<String>();
    public Order_to_opp_data_metrics__c createOppErroRecord(string errorCode,string descError,string cdhEbsKey,Id stagingRec){
        Order_to_opp_data_metrics__c oppMetricRec= new Order_to_opp_data_metrics__c();
        oppMetricRec.Error_Code__c=errorCode;
        oppMetricRec.Error_Description__c=descError;
        oppMetricRec.CDH_EBS_Key__c=cdhEbsKey;
        oppMetricRec.Opportunity_Header_Staging__c=stagingRec;
        return oppMetricRec;
    }
    global Database.QueryLocator start(Database.BatchableContext BC)
    {
        errorList.clear();
        String[] statusList = new String[]{'Error'};
        String[] orderStatusList = new String[]{'BOOKED'};
        //String[] orderIDList = new String[]{'a5V60000000Xv5t'};
        String query = 'SELECT Id,Name,Status__c,Order_Status__c,';
        query =query +'Bill_To_Account_Number__c,Ship_To_Account_Number__c,Sold_To_Account_Number__c,Entitle_To_Account_Number__c,';
        query =query +'Bill_To_Address_CDH_Party_Site_Number__c,Ship_To_Address_CDH_Party_Site_Number__c,Sold_To_Address_CDH_Party_Site_Number__c,Entitle_To_Address_CDH_Party_Site_Number__c,';
        query =query +'Bill_To_CDH_Party_Number__c,Ship_To_CDH_Party_Number__c,Sold_To_CDH_Party_Number__c,Entitle_To_CDH_Party_Number__c,';
        query =query +'(SELECT Id,Name,Error_Description__c,Error_Code__c,Opportunity_Staging_Header__c,Opportunity_Product_Staging__c,Opportunity_Partner_Staging__c FROM Match_and_Validation_Errors__r),';
        query =query +'(SELECT Id,Name,Opportunity_Stage_Header_ID__c,Entitle_To_Account_Number__c,Entitle_To_CDH_Party_Site_Number__c,Entitle_To_CDH_Party_Number__c FROM Opportunities_Line_Staging__r),';
        query =query +'(SELECT Id,Name,Opportunity_Stage_Header_ID__c,CDH_Party_Number__c,Partner_Contact_CDH_Party_Number__c FROM Opportunities_Partner_Staging__r),';
        query =query +'(SELECT Id FROM Order_to_opp_data_metrics__r)';
        query =query +' FROM Opportunity_Header_Staging__c Where Status__c  IN: statusList AND Order_Status__c IN:orderStatusList';
        //query =query +' AND ID IN:orderIDList';
        if(Order_Error_Match_Reporting__c.getInstance('Time Stamp') ==null){
           Order_Error_Match_Reporting__c oEM= new Order_Error_Match_Reporting__c();
           oEM.Name='Time Stamp';
           oEM.Last_Processed__c=System.now();
           insert oEM;
        }else if(Order_Error_Match_Reporting__c.getInstance('Time Stamp') !=null){
           Order_Error_Match_Reporting__c oEM= Order_Error_Match_Reporting__c.getInstance('Time Stamp');
           DateTime dt = oEM.Last_Processed__c;
           query =query + ' AND LastModifiedDate >:dt';
           oEM.Last_Processed__c=System.now();
           update oEM;
        }
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC,SObject[] scope)
    {
        try{
        set<string> setEBSAccountCDH= new set<string>();
        set<string> setAddressSiteNumbers= new set<string>();
        set<string> setContactParty= new set<string>();
        set<string> setAccountCDH= new set<string>();
        list<Order_to_opp_data_metrics__c> oppErrorListToDelete= new list<Order_to_opp_data_metrics__c>();
        list<Order_to_opp_data_metrics__c> oppErrorListToCreate= new list<Order_to_opp_data_metrics__c>();
        //Run through the list of sObject to find related error and track Records causing error.
        for(SObject s:scope){
            Opportunity_Header_Staging__c oHSRecord=(Opportunity_Header_Staging__c)s;
            Map<id,Opportunity_Line_Staging__c> mapRelatedOLI= new Map<id,Opportunity_Line_Staging__c>();
            //Add the old metric records to delete list
            if(s.getSObjects('Order_to_opp_data_metrics__r') !=null && s.getSObjects('Order_to_opp_data_metrics__r').size()!=0){
                oppErrorListToDelete.addAll((list<Order_to_opp_data_metrics__c>)s.getSObjects('Order_to_opp_data_metrics__r'));
            }
            //Create map of Line staging name and related record for Validation with error message
            if(s.getSObjects('Opportunities_Line_Staging__r') !=null){
                for(Opportunity_Line_Staging__c oLI:s.getSObjects('Opportunities_Line_Staging__r')){
                    mapRelatedOLI.put(oLI.id,oLI);    
                }
            }
            Map<id,Opportunity_Partner_Staging__c> mapRelatedOPartner= new Map<id,Opportunity_Partner_Staging__c>();
            //Create map of partner staging name and related record for Validation with error message
            if(s.getSObjects('Opportunities_Partner_Staging__r') !=null){
                for(Opportunity_Partner_Staging__c oPartner:s.getSObjects('Opportunities_Partner_Staging__r')){
                    mapRelatedOPartner.put(oPartner.id,oPartner);    
                }
            }
            if(s.getSObjects('Match_and_Validation_Errors__r') !=null){
                for(Match_and_Validation_Error__c mV:s.getSObjects('Match_and_Validation_Errors__r')){
                   //*****************************Error on Billing Information
                    if(mV.Error_Code__c=='D5' || mV.Error_Code__c=='In4' || mV.Error_Code__c=='I7'){
                        if(oHSRecord.Bill_To_Account_Number__c !=null){
                            setEBSAccountCDH.add(oHSRecord.Bill_To_Account_Number__c);
                            oppErrorListToCreate.add(createOppErroRecord(mV.Error_Code__c,mV.Error_Description__c,oHSRecord.Bill_To_Account_Number__c,mV.Opportunity_Staging_Header__c));
                        }
                    }else if(mV.Error_Code__c=='D6' || mV.Error_Code__c=='In5' || mV.Error_Code__c=='I8'){
                        if(oHSRecord.Bill_To_Address_CDH_Party_Site_Number__c !=null){
                            setAddressSiteNumbers.add(oHSRecord.Bill_To_Address_CDH_Party_Site_Number__c);
                            oppErrorListToCreate.add(createOppErroRecord(mV.Error_Code__c,mV.Error_Description__c,oHSRecord.Bill_To_Address_CDH_Party_Site_Number__c,mV.Opportunity_Staging_Header__c));
                        }
                    }else if(mV.Error_Code__c=='D7' || mV.Error_Code__c=='In6' || mV.Error_Code__c=='I9'){
                        if(oHSRecord.Bill_To_CDH_Party_Number__c !=null){
                            setContactParty.add(oHSRecord.Bill_To_CDH_Party_Number__c);
                            oppErrorListToCreate.add(createOppErroRecord(mV.Error_Code__c,mV.Error_Description__c,oHSRecord.Bill_To_CDH_Party_Number__c,mV.Opportunity_Staging_Header__c));
                        }
                    }
                    //*****************************Error on Shipping Information
                    else if(mV.Error_Code__c=='D9' || mV.Error_Code__c=='In8' || mV.Error_Code__c=='I11'){
                        if(oHSRecord.Ship_To_Account_Number__c !=null){
                            setEBSAccountCDH.add(oHSRecord.Ship_To_Account_Number__c);
                            oppErrorListToCreate.add(createOppErroRecord(mV.Error_Code__c,mV.Error_Description__c,oHSRecord.Ship_To_Account_Number__c,mV.Opportunity_Staging_Header__c));
                        }
                    }else if(mV.Error_Code__c=='D10' || mV.Error_Code__c=='In9' || mV.Error_Code__c=='I12'){
                        if(oHSRecord.Ship_To_Address_CDH_Party_Site_Number__c !=null){
                           setAddressSiteNumbers.add(oHSRecord.Ship_To_Address_CDH_Party_Site_Number__c);
                            oppErrorListToCreate.add(createOppErroRecord(mV.Error_Code__c,mV.Error_Description__c,oHSRecord.Ship_To_Address_CDH_Party_Site_Number__c,mV.Opportunity_Staging_Header__c));
                        }
                    
                    }else if(mV.Error_Code__c=='D11' || mV.Error_Code__c=='In10' || mV.Error_Code__c=='I13'){
                        if(oHSRecord.Ship_To_CDH_Party_Number__c !=null){
                            setContactParty.add(oHSRecord.Ship_To_CDH_Party_Number__c);
                            oppErrorListToCreate.add(createOppErroRecord(mV.Error_Code__c,mV.Error_Description__c,oHSRecord.Ship_To_CDH_Party_Number__c,mV.Opportunity_Staging_Header__c));
                        }
                    }
                    //*****************************Error on Sold to Information
                    else if(mV.Error_Code__c=='D13' || mV.Error_Code__c=='In12' || mV.Error_Code__c=='I15'){
                        if(oHSRecord.Sold_To_Account_Number__c !=null){
                            setEBSAccountCDH.add(oHSRecord.Sold_To_Account_Number__c);
                            oppErrorListToCreate.add(createOppErroRecord(mV.Error_Code__c,mV.Error_Description__c,oHSRecord.Sold_To_Account_Number__c,mV.Opportunity_Staging_Header__c));
                        }
                    }else if(mV.Error_Code__c=='D14' || mV.Error_Code__c=='In13' || mV.Error_Code__c=='I16'){
                        if(oHSRecord.Sold_To_Address_CDH_Party_Site_Number__c !=null){
                            setAddressSiteNumbers.add(oHSRecord.Sold_To_Address_CDH_Party_Site_Number__c);
                            oppErrorListToCreate.add(createOppErroRecord(mV.Error_Code__c,mV.Error_Description__c,oHSRecord.Sold_To_Address_CDH_Party_Site_Number__c,mV.Opportunity_Staging_Header__c));
                        }
                    }else if(mV.Error_Code__c=='D15' || mV.Error_Code__c=='In14' || mV.Error_Code__c=='I17'){
                        if(oHSRecord.Sold_To_CDH_Party_Number__c !=null){
                            setContactParty.add(oHSRecord.Sold_To_CDH_Party_Number__c);
                            oppErrorListToCreate.add(createOppErroRecord(mV.Error_Code__c,mV.Error_Description__c,oHSRecord.Sold_To_CDH_Party_Number__c,mV.Opportunity_Staging_Header__c));
                        }
                    }
                    //*****************************Error on Entitle Information
                    else if(mV.Error_Code__c=='D17' || mV.Error_Code__c=='In16' || mV.Error_Code__c=='I19'){
                        if(oHSRecord.Entitle_To_Account_Number__c !=null){
                            setEBSAccountCDH.add(oHSRecord.Entitle_To_Account_Number__c);
                            oppErrorListToCreate.add(createOppErroRecord(mV.Error_Code__c,mV.Error_Description__c,oHSRecord.Bill_To_Account_Number__c,mV.Opportunity_Staging_Header__c));
                        }
                    }else if(mV.Error_Code__c=='D18' || mV.Error_Code__c=='In17' || mV.Error_Code__c=='I20'){
                        if(oHSRecord.Entitle_To_Address_CDH_Party_Site_Number__c !=null){
                            setAddressSiteNumbers.add(oHSRecord.Entitle_To_Address_CDH_Party_Site_Number__c);
                            oppErrorListToCreate.add(createOppErroRecord(mV.Error_Code__c,mV.Error_Description__c,oHSRecord.Entitle_To_Address_CDH_Party_Site_Number__c,mV.Opportunity_Staging_Header__c));
                        }
                    }else if(mV.Error_Code__c=='D19' || mV.Error_Code__c=='In18' || mV.Error_Code__c=='I21'){
                        system.debug('Entitle to CDH party===========================================>'+oHSRecord.Entitle_To_CDH_Party_Number__c);
                        if(oHSRecord.Entitle_To_CDH_Party_Number__c !=null){
                            setContactParty.add(oHSRecord.Entitle_To_CDH_Party_Number__c);
                            oppErrorListToCreate.add(createOppErroRecord(mV.Error_Code__c,mV.Error_Description__c,oHSRecord.Entitle_To_CDH_Party_Number__c,mV.Opportunity_Staging_Header__c));
                        }    
                    }
                    //*****************************Error on line staging Entitle information Information
                    else if(mV.Error_Code__c=='D21' || mV.Error_Code__c=='In20' || mV.Error_Code__c=='I23'){
                        if(mv.Opportunity_Product_Staging__c !=null && mapRelatedOLI.get(mv.Opportunity_Product_Staging__c).Entitle_To_Account_Number__c !=null){
                             setEBSAccountCDH.add(mapRelatedOLI.get(mv.Opportunity_Product_Staging__c).Entitle_To_Account_Number__c);   
                            oppErrorListToCreate.add(createOppErroRecord(mV.Error_Code__c,mV.Error_Description__c,mapRelatedOLI.get(mv.Opportunity_Product_Staging__c).Entitle_To_Account_Number__c,mV.Opportunity_Staging_Header__c));
                        }
                    }else if(mV.Error_Code__c=='D22' || mV.Error_Code__c=='In21' || mV.Error_Code__c=='I24'){
                        if(mv.Opportunity_Product_Staging__c !=null && mapRelatedOLI.get(mv.Opportunity_Product_Staging__c).Entitle_To_CDH_Party_Site_Number__c!=null){
                             setAddressSiteNumbers.add(mapRelatedOLI.get(mv.Opportunity_Product_Staging__c).Entitle_To_CDH_Party_Site_Number__c); 
                            oppErrorListToCreate.add(createOppErroRecord(mV.Error_Code__c,mV.Error_Description__c,mapRelatedOLI.get(mv.Opportunity_Product_Staging__c).Entitle_To_CDH_Party_Site_Number__c,mV.Opportunity_Staging_Header__c));
                        }
                    }else if(mV.Error_Code__c=='D23' || mV.Error_Code__c=='In22' || mV.Error_Code__c=='I25'){
                        if(mv.Opportunity_Product_Staging__c !=null && mapRelatedOLI.get(mv.Opportunity_Product_Staging__c).Entitle_To_CDH_Party_Number__c !=null){
                             setContactParty.add(mapRelatedOLI.get(mv.Opportunity_Product_Staging__c).Entitle_To_CDH_Party_Number__c); 
                            oppErrorListToCreate.add(createOppErroRecord(mV.Error_Code__c,mV.Error_Description__c,mapRelatedOLI.get(mv.Opportunity_Product_Staging__c).Entitle_To_CDH_Party_Number__c,mV.Opportunity_Staging_Header__c));
                        }
                    }
                    //*****************************Error on partner staging Entitle information Information
                    else if(mV.Error_Code__c=='D25' || mV.Error_Code__c=='In24' || mV.Error_Code__c=='I27'){
                        if(mv.Opportunity_Partner_Staging__c !=null && mapRelatedOPartner.get(mv.Opportunity_Partner_Staging__c).CDH_Party_Number__c !=null){
                             setAccountCDH.add(mapRelatedOPartner.get(mv.Opportunity_Partner_Staging__c).CDH_Party_Number__c);   
                            oppErrorListToCreate.add(createOppErroRecord(mV.Error_Code__c,mV.Error_Description__c,mapRelatedOPartner.get(mv.Opportunity_Partner_Staging__c).CDH_Party_Number__c,mV.Opportunity_Staging_Header__c));
                        }
                    }else if(mV.Error_Code__c=='D26' || mV.Error_Code__c=='In25' || mV.Error_Code__c=='I28'){
                        if(mv.Opportunity_Partner_Staging__c !=null && mapRelatedOPartner.get(mv.Opportunity_Partner_Staging__c).Partner_Contact_CDH_Party_Number__c!=null){
                            setContactParty.add(mapRelatedOPartner.get(mv.Opportunity_Partner_Staging__c).Partner_Contact_CDH_Party_Number__c); 
                            oppErrorListToCreate.add(createOppErroRecord(mV.Error_Code__c,mV.Error_Description__c,mapRelatedOPartner.get(mv.Opportunity_Partner_Staging__c).Partner_Contact_CDH_Party_Number__c,mV.Opportunity_Staging_Header__c));
                        }
                    }
                }
            }
        }
        //create Map of count from EBS based on CDH numbers recived
        map<string,string> mapEBSCDHCount= new map<string,string>();
        for(AggregateResult arEBS:[Select count(ID) TotalCount,Name from EBS_Account__c where Name IN:setEBSAccountCDH Group BY Name]){
            if(arEBS.get('Name') !=null && arEBS.get('TotalCount') !=null){
               mapEBSCDHCount.put(string.valueof(arEBS.get('Name')),string.valueof(arEBS.get('TotalCount')));
            }
        }
        //create Map of count from Address based on CDH Site numbers recived
        map<string,string> mapAddressSiteCount= new map<string,string>();
        for(AggregateResult arEBS:[Select count(ID) TotalCount,CDH_Party_Site_Number__c from Address__c where CDH_Party_Site_Number__c IN:setAddressSiteNumbers Group BY CDH_Party_Site_Number__c]){
            if(arEBS.get('CDH_Party_Site_Number__c') !=null && arEBS.get('TotalCount') !=null){
               mapAddressSiteCount.put(string.valueof(arEBS.get('CDH_Party_Site_Number__c')),string.valueof(arEBS.get('TotalCount')));
            }
        }
        //create Map of count from Contact based on CDH numbers recived
        map<string,string> mapCountactCDHCount= new map<string,string>();
        for(AggregateResult arEBS:[Select count(ID) TotalCount,CDH_Party__r.CDH_Party_Number_Ext__c from Contact where CDH_Party_Number__c IN:setContactParty Group BY CDH_Party__r.CDH_Party_Number_Ext__c]){
            if(arEBS.get('CDH_Party_Number_Ext__c') !=null && arEBS.get('TotalCount') !=null){
               mapCountactCDHCount.put(string.valueof(arEBS.get('CDH_Party_Number_Ext__c')),string.valueof(arEBS.get('TotalCount')));
            }
        }
        //create Map of count from Account based on CDH numbers recived
        map<string,string> mapAccountCDHCount= new map<string,string>();
        for(AggregateResult arEBS:[Select count(ID) TotalCount,CDH_Party_Name__r.Name from Account where CDH_Party_Name__r.Name IN:setAccountCDH Group BY CDH_Party_Name__c,CDH_Party_Name__r.Name]){
            if(arEBS.get('Name') !=null && arEBS.get('TotalCount') !=null){
               mapAccountCDHCount.put(string.valueof(arEBS.get('Name')),string.valueof(arEBS.get('TotalCount')));
            }
        }
        //Run through the current list of Error Metric Records to Assign the corresponding 
        List<Order_to_opp_data_metrics__c> oMetricsUpdatedLst = new List<Order_to_opp_data_metrics__c>();
        for(Order_to_opp_data_metrics__c oMetrics:oppErrorListToCreate){
            Order_to_opp_data_metrics__c oMetricsnew= new Order_to_opp_data_metrics__c();
            oMetricsnew=oMetrics;
            if(oMetricsnew.Error_Code__c=='D5' || oMetricsnew.Error_Code__c=='In4' || oMetricsnew.Error_Code__c=='I7' ||
            oMetricsnew.Error_Code__c=='D9' || oMetricsnew.Error_Code__c=='In8' || oMetricsnew.Error_Code__c=='I11' ||
            oMetricsnew.Error_Code__c=='D13' || oMetricsnew.Error_Code__c=='In12' || oMetricsnew.Error_Code__c=='I15' ||
            oMetricsnew.Error_Code__c=='D17' || oMetricsnew.Error_Code__c=='In16' || oMetricsnew.Error_Code__c=='I19' ||
            oMetricsnew.Error_Code__c=='D21' || oMetricsnew.Error_Code__c=='In20' || oMetricsnew.Error_Code__c=='I23'){
                if(mapEBSCDHCount !=null && mapEBSCDHCount.size() !=0 && mapEBSCDHCount.get(oMetricsnew.CDH_EBS_Key__c) !=null){
                    oMetricsnew.Matching_Records__c=  integer.Valueof(mapEBSCDHCount.get(oMetricsnew.CDH_EBS_Key__c));  
                }else{
                    oMetricsnew.Matching_Records__c=0;
                }
            }Else if(oMetricsnew.Error_Code__c=='D6' || oMetricsnew.Error_Code__c=='In5' || oMetricsnew.Error_Code__c=='I8' ||
            oMetricsnew.Error_Code__c=='D10' || oMetricsnew.Error_Code__c=='In9' || oMetricsnew.Error_Code__c=='I12' ||
            oMetricsnew.Error_Code__c=='D14' || oMetricsnew.Error_Code__c=='In13' || oMetricsnew.Error_Code__c=='I16' ||
            oMetricsnew.Error_Code__c=='D18' || oMetricsnew.Error_Code__c=='In17' || oMetricsnew.Error_Code__c=='I20' ||
            oMetricsnew.Error_Code__c=='D22' || oMetricsnew.Error_Code__c=='In21' || oMetricsnew.Error_Code__c=='I24'){
                if(mapAddressSiteCount !=null && mapAddressSiteCount.size() !=0 && mapAddressSiteCount.get(oMetricsnew.CDH_EBS_Key__c) !=null){
                    oMetricsnew.Matching_Records__c=  integer.Valueof(mapAddressSiteCount.get(oMetricsnew.CDH_EBS_Key__c));  
                }else{
                    oMetricsnew.Matching_Records__c=0;
                }
            }Else if(oMetricsnew.Error_Code__c=='D7' || oMetricsnew.Error_Code__c=='In6' || oMetricsnew.Error_Code__c=='I9' ||
            oMetricsnew.Error_Code__c=='D11' || oMetricsnew.Error_Code__c=='In10' || oMetricsnew.Error_Code__c=='I13' ||
            oMetricsnew.Error_Code__c=='D15' || oMetricsnew.Error_Code__c=='In14' || oMetricsnew.Error_Code__c=='I17' ||
            oMetricsnew.Error_Code__c=='D19' || oMetricsnew.Error_Code__c=='In18' || oMetricsnew.Error_Code__c=='I21' ||
            oMetricsnew.Error_Code__c=='D23' || oMetricsnew.Error_Code__c=='In22' || oMetricsnew.Error_Code__c=='I25' ||
            oMetricsnew.Error_Code__c=='D26' || oMetricsnew.Error_Code__c=='In25' || oMetricsnew.Error_Code__c=='I28'){
                if(mapCountactCDHCount !=null && mapCountactCDHCount.size()!=0 && mapCountactCDHCount.get(oMetricsnew.CDH_EBS_Key__c) !=null){
                    oMetricsnew.Matching_Records__c=  integer.Valueof(mapCountactCDHCount.get(oMetricsnew.CDH_EBS_Key__c));  
                }else{
                    oMetricsnew.Matching_Records__c=0;
                }
            }Else if(oMetricsnew.Error_Code__c=='D25' || oMetricsnew.Error_Code__c=='In24' || oMetricsnew.Error_Code__c=='I27'){
                if(mapAccountCDHCount !=null && mapAccountCDHCount.size() !=0 && mapAccountCDHCount.get(oMetricsnew.CDH_EBS_Key__c) !=null){
                    oMetricsnew.Matching_Records__c=  integer.Valueof(mapAccountCDHCount.get(oMetricsnew.CDH_EBS_Key__c));  
                }else{
                    oMetricsnew.Matching_Records__c=0;
                }
            }
            
            oMetricsUpdatedLst.add(oMetricsnew);
                
        }
        Insert oMetricsUpdatedLst;
        delete oppErrorListToDelete;
        }Catch(Exception Ex){
            errorList.add('Error :'+String.ValueOf(ex));   
        }
    }   
    global void finish(Database.batchablecontext bc) {

    // Check batch status - IF COMPLETED then 
    AsyncApexJob a = [Select Id, Status, NumberOfErrors, JobItemsProcessed,
        TotalJobItems, CreatedBy.Email, ExtendedStatus
        from AsyncApexJob where Id = :bc.getJobId()];        
    if(errorList !=null && errorList.size() >0){
        // 1. Send Email (CSV created in execute method)
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        // Send the email to the job submitter
        String[] toAddresses = new String[] {a.CreatedBy.Email};
        mail.setToAddresses(toAddresses);
        mail.setSenderDisplayName('Batch Processing');
        mail.setSubject('Error Reporting Batch Status: ' + a.Status);
        String ErrorMessage='Please find below the error List:';
        for(string s:errorList){
           ErrorMessage= ErrorMessage + '<br/>-'+s;
        }
        mail.setPlainTextBody('The batch Apex job processed ' + a.TotalJobItems +
            ' batches with '+ a.NumberOfErrors + ' failures. ExtendedStatus: ' + a.ExtendedStatus);
        // Add your attachment to the email.
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
}
}