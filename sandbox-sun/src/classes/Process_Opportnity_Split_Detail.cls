/**
 * This method is used to Delete/Insert records in Opportunity Split Detail object
 *
 *
 * @version 2014-10-09
 * @author Anshul Kumar <ankumar@redhat.com>
 * 2014-10-09 - Created
 * 2014-12-24 - Modified (US60849)
 * 2015-02-05 - Modified (US62595)
 * 2015-02-06 - Modified (US62950)
 */
public with sharing class Process_Opportnity_Split_Detail{
    
    /**
     * Start method impl for Database.Batchable interface.
     *
     * @param   setOpportunityIds set<Id>
     * @return  list<String> collection of error messages
     *
     */
    public List<String> rebuildSplitDetails(Set<Id> setOpportunityIds){
        
        //select all the Opportunity Split Detail records for deletion
        list<Opportunity_Split_Detail__c> listOppSplitDetail = new list<Opportunity_Split_Detail__c>([SELECT Id 
                                                                                                    FROM Opportunity_Split_Detail__c
                                                                                                    WHERE Opportunity__c IN: setOpportunityIds
                                                                                                    OR Opportunity__c = NULL]);
        list<Database.DeleteResult> oppDetDelRes = Database.delete(listOppSplitDetail, FALSE);
        
        //fetch all the Opportunities with related details
        list<Opportunity> listOpportunity = new list<Opportunity>([SELECT
                                                                CurrencyIsoCode,
                                                                StageName,
                                                                CloseDate,
                                                                (SELECT TotalPrice, Entitle_To_Address__r.Country__c, 
                                                                Year1Amount__c, Year2Amount__c, Year3Amount__c,
                                                                Year4Amount__c, Year5Amount__c, Year6Amount__c,
                                                                Configured_SKU__c, PricebookEntry.Product2.Id,
                                                                PricebookEntry.Product2.Primary_BU__c,
                                                                PricebookEntry.Product2.Secondary_BU__c,
                                                                PricebookEntry.Product2.Tertiary__c,
                                                                PricebookEntry.Product2.Quaternary_BU__c,
                                                                PricebookEntry.Product2.Quinary_BU__c
                                                                FROM 
                                                                OpportunityLineItems),
                                                                (SELECT UserId, TeamMemberRole 
                                                                FROM 
                                                                OpportunityTeamMembers),
                                                                (SELECT SplitAmount, SplitPercentage, 
                                                                SplitType.MasterLabel, SplitOwnerId, Country__c,
                                                                Region__c, Sub_Region__c, Super_Region__c
                                                                FROM 
                                                                OpportunitySplits)
                                                                FROM Opportunity
                                                                WHERE Id IN: setOpportunityIds]);
        
        listOppSplitDetail = new list<Opportunity_Split_Detail__c>();
        Opportunity_Split_Detail__c oppSplitDetailInst = new Opportunity_Split_Detail__c();
        boolean splitFound;
        list<Date> closeDates = new list<Date>();
        
      //collect close dates of all Closed Booked Opportunity
        for(Opportunity oppInst: listOpportunity){
            //if(oppInst.StageName == 'Closed Booked')
                closeDates.add(oppInst.CloseDate);
        }
        
        map<Id, map<String, Decimal>> mapOppIds_ConvRate = new map<Id, map<String, Decimal>>(); 
        if(!closeDates.isEmpty()){
          //Construct query to fetch all the Dated Conversion Rates  
            String dateConversionQuery = 'SELECT ConversionRate, IsoCode, StartDate,NextStartDate FROM DatedConversionRate WHERE ';
            list<String> conditions = new list<String>();
            
            for(Date closeDate : closeDates)
                conditions.add('(StartDate <= '+String.valueOf(closedate).substring(0,10)+' AND NextStartDate > '+String.valueOf(closeDate).substring(0,10)+')');
            
            dateConversionQuery += String.join(conditions, ' OR ');
            
            system.debug('---DateConversionQuery---'+dateConversionQuery);
            
            list<DatedConversionRate> listConvRates = new list<DatedConversionRate>((list<DatedConversionRate>)Database.query(dateConversionQuery));
          
          //populate map of Opp ids and map of Iso Codes and Conversion Rates  
            
            
            for(Opportunity oppInst : listOpportunity){
                for(DatedConversionRate dcrInst : listConvRates){
                    if(dcrInst.StartDate <= oppInst.CloseDate && dcrInst.NextStartDate > oppInst.CloseDate){
                        if(!mapOppIds_ConvRate.containsKey(oppInst.Id))
                            mapOppIds_ConvRate.put(oppInst.Id, new map<String, Decimal>());
                        if(mapOppIds_ConvRate.containsKey(oppInst.Id))
                            mapOppIds_ConvRate.get(oppInst.Id).put(dcrInst.IsoCode, dcrInst.ConversionRate);
                    }
                }
            }
        }
            
        //iterate to create new records of Opportunity Split Detail
        for(Opportunity oppInst : listOpportunity){
            
            for(OpportunityLineItem oppLineInst : oppInst.OpportunityLineItems){
                
                for(OpportunityTeamMember oppTeamInst : oppInst.OpportunityTeamMembers){
                    
                    splitFound = FALSE;
                    for(OpportunitySplit oppSplitInst : oppInst.OpportunitySplits){
                        
                        if(oppTeamInst.UserId == oppSplitInst.SplitOwnerId){
                            splitFound = TRUE;
                            oppSplitDetailInst = new Opportunity_Split_Detail__c();
                            oppSplitDetailInst.Team_Member_Role__c = oppTeamInst.TeamMemberRole;
                            oppSplitDetailInst.Sales_Incentive_Country__c = oppSplitInst.Country__c;
                            oppSplitDetailInst.CurrencyIsoCode = oppInst.CurrencyIsoCode;
                            oppSplitDetailInst.Product__c = oppLineInst.PricebookEntry.Product2.Id;
                            oppSplitDetailInst.OwnerId = oppTeamInst.UserId;
                            oppSplitDetailInst.Opportunity__c = oppInst.Id;
                            /****START: change in logic as per US60849****/
                            oppSplitDetailInst.Total_Amount__c = (oppLineInst.TotalPrice * oppSplitInst.SplitPercentage)/100;
                            oppSplitDetailInst.Opportunity_Line_Item_Total_Price__c = oppLineInst.TotalPrice;
                            /****END: change in logic as per US60849****/
                            oppSplitDetailInst.Split_Amount__c = oppSplitInst.SplitAmount;
                            oppSplitDetailInst.Split_Percent__c = oppSplitInst.SplitPercentage;
                            oppSplitDetailInst.Opportunity_Split_Type__c = oppSplitInst.SplitType.MasterLabel;
                            if(oppLineInst.TotalPrice != 0){
                                if(oppLineInst.PricebookEntry.Product2.Primary_BU__c != NULL)//change in logic as per US60849
                                    oppSplitDetailInst.Primary_Business_Unit_Amount__c = (oppLineInst.PricebookEntry.Product2.Primary_BU__c * oppLineInst.TotalPrice)/100;
                                if(oppLineInst.PricebookEntry.Product2.Secondary_BU__c != NULL)//change in logic as per US60849
                                    oppSplitDetailInst.Secondary_Business_Unit_Amount__c = (oppLineInst.PricebookEntry.Product2.Secondary_BU__c * oppLineInst.TotalPrice)/100;
                                if(oppLineInst.PricebookEntry.Product2.Tertiary__c != NULL)//change in logic as per US60849
                                    oppSplitDetailInst.Tertiary_Business_Unit_Amount__c = (oppLineInst.PricebookEntry.Product2.Tertiary__c * oppLineInst.TotalPrice)/100;
                                if(oppLineInst.PricebookEntry.Product2.Quaternary_BU__c != NULL)//change in logic as per US60849
                                    oppSplitDetailInst.Quaternary_Business_Unit_Amount__c = (oppLineInst.PricebookEntry.Product2.Quaternary_BU__c * oppLineInst.TotalPrice)/100;
                                if(oppLineInst.PricebookEntry.Product2.Quinary_BU__c != NULL)//change in logic as per US60849
                                    oppSplitDetailInst.Quinary_Business_Unit_Amount__c = (oppLineInst.PricebookEntry.Product2.Quinary_BU__c * oppLineInst.TotalPrice)/100;
                            }
                            
                            oppSplitDetailInst.Entitle_To_Country__c = oppLineInst.Entitle_To_Address__r.Country__c;
                            if(oppLineInst.Year1Amount__c != NULL)//change in logic as per US60849
                                oppSplitDetailInst.Year1_Amount__c = (oppLineInst.Year1Amount__c * oppSplitInst.SplitPercentage)/100;
                            if(oppLineInst.Year2Amount__c != NULL)//change in logic as per US60849
                                oppSplitDetailInst.Year2_Amount__c = (oppLineInst.Year2Amount__c * oppSplitInst.SplitPercentage)/100;
                            if(oppLineInst.Year3Amount__c != NULL)//change in logic as per US60849
                                oppSplitDetailInst.Year3_Amount__c = (oppLineInst.Year3Amount__c * oppSplitInst.SplitPercentage)/100;
                            if(oppLineInst.Year4Amount__c != NULL)//change in logic as per US60849
                                oppSplitDetailInst.Year4_Amount__c = (oppLineInst.Year4Amount__c * oppSplitInst.SplitPercentage)/100;
                            if(oppLineInst.Year5Amount__c != NULL)//change in logic as per US60849
                                oppSplitDetailInst.Year5_Amount__c = (oppLineInst.Year5Amount__c * oppSplitInst.SplitPercentage)/100;
                            if(oppLineInst.Year6Amount__c != NULL)//change in logic as per US60849
                                oppSplitDetailInst.Year6_Amount__c = (oppLineInst.Year6Amount__c * oppSplitInst.SplitPercentage)/100;
                            oppSplitDetailInst.Configured_SKU__c = oppLineInst.Configured_SKU__c;
                            oppSplitDetailInst.OpportunityLineItem__c = oppLineInst.Id;
                            oppSplitDetailInst.OpportunitySplit__c = oppSplitInst.Id;
                            oppSplitDetailInst.Region__c = oppSplitInst.Region__c;
                            oppSplitDetailInst.Sub_Region__c = oppSplitInst.Sub_Region__c;
                            oppSplitDetailInst.Super_Region__c = oppSplitInst.Super_Region__c;
                            
                            if(mapOppIds_ConvRate.get(oppInst.Id) != NULL){//oppInst.StageName == 'Closed Booked' && 
                                oppSplitDetailInst.EUR_Conversion_Rate__c = mapOppIds_ConvRate.get(oppInst.Id).get('EUR');
                                oppSplitDetailInst.INR_Conversion_Rate__c = mapOppIds_ConvRate.get(oppInst.Id).get('INR');
                                oppSplitDetailInst.KRW_Conversion_Rate__c = mapOppIds_ConvRate.get(oppInst.Id).get('KRW');
                                oppSplitDetailInst.JPY_Conversion_Rate__c = mapOppIds_ConvRate.get(oppInst.Id).get('JPY');
                                oppSplitDetailInst.BRL_Conversion_Rate__c = mapOppIds_ConvRate.get(oppInst.Id).get('BRL');
                                oppSplitDetailInst.CNY_Conversion_Rate__c = mapOppIds_ConvRate.get(oppInst.Id).get('CNY');
                                oppSplitDetailInst.AUD_Conversion_Rate__c = mapOppIds_ConvRate.get(oppInst.Id).get('AUD');
                                oppSplitDetailInst.SGD_Conversion_Rate__c = mapOppIds_ConvRate.get(oppInst.Id).get('SGD');
                                oppSplitDetailInst.ARS_Conversion_Rate__c = mapOppIds_ConvRate.get(oppInst.Id).get('ARS');
                                oppSplitDetailInst.CAD_Conversion_Rate__c = mapOppIds_ConvRate.get(oppInst.Id).get('CAD');
                                oppSplitDetailInst.HKD_Conversion_Rate__c = mapOppIds_ConvRate.get(oppInst.Id).get('HKD');
                                oppSplitDetailInst.IDR_Conversion_Rate__c = mapOppIds_ConvRate.get(oppInst.Id).get('IDR');
                                oppSplitDetailInst.MXN_Conversion_Rate__c = mapOppIds_ConvRate.get(oppInst.Id).get('MXN');
                                oppSplitDetailInst.MYR_Conversion_Rate__c = mapOppIds_ConvRate.get(oppInst.Id).get('MYR');
                                oppSplitDetailInst.NZD_Conversion_Rate__c = mapOppIds_ConvRate.get(oppInst.Id).get('NZD');
                                oppSplitDetailInst.PHP_Conversion_Rate__c = mapOppIds_ConvRate.get(oppInst.Id).get('PHP');
                                oppSplitDetailInst.THB_Conversion_Rate__c = mapOppIds_ConvRate.get(oppInst.Id).get('THB');
                                oppSplitDetailInst.GBP_Conversion_Rate__c = mapOppIds_ConvRate.get(oppInst.Id).get('GBP');
                                oppSplitDetailInst.CLP_Conversion_Rate__c = mapOppIds_ConvRate.get(oppInst.Id).get('CLP');
                            }
                            
                            listOppSplitDetail.add(oppSplitDetailInst);
                            
                        }
                    }
                    /****START: change in logic as per US62950****/
                    if(!splitFound){
                        
                        oppSplitDetailInst = new Opportunity_Split_Detail__c();
                        oppSplitDetailInst.Team_Member_Role__c = oppTeamInst.TeamMemberRole;
                        oppSplitDetailInst.CurrencyIsoCode = oppInst.CurrencyIsoCode;
                        oppSplitDetailInst.Product__c = oppLineInst.PricebookEntry.Product2.Id;
                        oppSplitDetailInst.OwnerId = oppTeamInst.UserId;
                        oppSplitDetailInst.Opportunity__c = oppInst.Id;
                        oppSplitDetailInst.Total_Amount__c = 0;
                        oppSplitDetailInst.Opportunity_Line_Item_Total_Price__c = oppLineInst.TotalPrice;
                        oppSplitDetailInst.Split_Amount__c = 0;
                        oppSplitDetailInst.Split_Percent__c = 0;
                        if(oppLineInst.TotalPrice != 0){
                            if(oppLineInst.PricebookEntry.Product2.Primary_BU__c != NULL)
                                oppSplitDetailInst.Primary_Business_Unit_Amount__c = (oppLineInst.PricebookEntry.Product2.Primary_BU__c * oppLineInst.TotalPrice)/100;
                            if(oppLineInst.PricebookEntry.Product2.Secondary_BU__c != NULL)
                                oppSplitDetailInst.Secondary_Business_Unit_Amount__c = (oppLineInst.PricebookEntry.Product2.Secondary_BU__c * oppLineInst.TotalPrice)/100;
                            if(oppLineInst.PricebookEntry.Product2.Tertiary__c != NULL)
                                oppSplitDetailInst.Tertiary_Business_Unit_Amount__c = (oppLineInst.PricebookEntry.Product2.Tertiary__c * oppLineInst.TotalPrice)/100;
                            if(oppLineInst.PricebookEntry.Product2.Quaternary_BU__c != NULL)
                                oppSplitDetailInst.Quaternary_Business_Unit_Amount__c = (oppLineInst.PricebookEntry.Product2.Quaternary_BU__c * oppLineInst.TotalPrice)/100;
                            if(oppLineInst.PricebookEntry.Product2.Quinary_BU__c != NULL)
                                oppSplitDetailInst.Quinary_Business_Unit_Amount__c = (oppLineInst.PricebookEntry.Product2.Quinary_BU__c * oppLineInst.TotalPrice)/100;
                        }
                        oppSplitDetailInst.Entitle_To_Country__c = oppLineInst.Entitle_To_Address__r.Country__c;
                        oppSplitDetailInst.Year1_Amount__c = 0;
                        oppSplitDetailInst.Year2_Amount__c = 0;
                        oppSplitDetailInst.Year3_Amount__c = 0;
                        oppSplitDetailInst.Year4_Amount__c = 0;
                        oppSplitDetailInst.Year5_Amount__c = 0;
                        oppSplitDetailInst.Year6_Amount__c = 0;
                        oppSplitDetailInst.Configured_SKU__c = oppLineInst.Configured_SKU__c;
                        oppSplitDetailInst.OpportunityLineItem__c = oppLineInst.Id;
                        
                        if(mapOppIds_ConvRate.get(oppInst.Id) != NULL){//oppInst.StageName == 'Closed Booked' && 
                            oppSplitDetailInst.EUR_Conversion_Rate__c = mapOppIds_ConvRate.get(oppInst.Id).get('EUR');
                            oppSplitDetailInst.INR_Conversion_Rate__c = mapOppIds_ConvRate.get(oppInst.Id).get('INR');
                            oppSplitDetailInst.KRW_Conversion_Rate__c = mapOppIds_ConvRate.get(oppInst.Id).get('KRW');
                            oppSplitDetailInst.JPY_Conversion_Rate__c = mapOppIds_ConvRate.get(oppInst.Id).get('JPY');
                            oppSplitDetailInst.BRL_Conversion_Rate__c = mapOppIds_ConvRate.get(oppInst.Id).get('BRL');
                            oppSplitDetailInst.CNY_Conversion_Rate__c = mapOppIds_ConvRate.get(oppInst.Id).get('CNY');
                            oppSplitDetailInst.AUD_Conversion_Rate__c = mapOppIds_ConvRate.get(oppInst.Id).get('AUD');
                            oppSplitDetailInst.SGD_Conversion_Rate__c = mapOppIds_ConvRate.get(oppInst.Id).get('SGD');
                            oppSplitDetailInst.ARS_Conversion_Rate__c = mapOppIds_ConvRate.get(oppInst.Id).get('ARS');
                            oppSplitDetailInst.CAD_Conversion_Rate__c = mapOppIds_ConvRate.get(oppInst.Id).get('CAD');
                            oppSplitDetailInst.HKD_Conversion_Rate__c = mapOppIds_ConvRate.get(oppInst.Id).get('HKD');
                            oppSplitDetailInst.IDR_Conversion_Rate__c = mapOppIds_ConvRate.get(oppInst.Id).get('IDR');
                            oppSplitDetailInst.MXN_Conversion_Rate__c = mapOppIds_ConvRate.get(oppInst.Id).get('MXN');
                            oppSplitDetailInst.MYR_Conversion_Rate__c = mapOppIds_ConvRate.get(oppInst.Id).get('MYR');
                            oppSplitDetailInst.NZD_Conversion_Rate__c = mapOppIds_ConvRate.get(oppInst.Id).get('NZD');
                            oppSplitDetailInst.PHP_Conversion_Rate__c = mapOppIds_ConvRate.get(oppInst.Id).get('PHP');
                            oppSplitDetailInst.THB_Conversion_Rate__c = mapOppIds_ConvRate.get(oppInst.Id).get('THB');
                            oppSplitDetailInst.GBP_Conversion_Rate__c = mapOppIds_ConvRate.get(oppInst.Id).get('GBP');
                            oppSplitDetailInst.CLP_Conversion_Rate__c = mapOppIds_ConvRate.get(oppInst.Id).get('CLP');
                        }
                        
                        listOppSplitDetail.add(oppSplitDetailInst);
                    }
                    /****END: change in logic as per US62950****/
                }
            }
        }
        
        list<Database.SaveResult> oppDetInsRes = Database.Insert(listOppSplitDetail, FALSE);
        
        list<String> errDet = new list<String>();
        
        //populate return list of errors
        for(Database.DeleteResult delRes : oppDetDelRes){
            for(Database.Error err : delRes.getErrors())
                errDet.add(err.getMessage());
        }
        
        for(Database.SaveResult insRes : oppDetInsRes){
            for(Database.Error err : insRes.getErrors())
                errDet.add(err.getMessage());
        }
        
        return errDet;
    }

}