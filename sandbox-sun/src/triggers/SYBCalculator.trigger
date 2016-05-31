trigger SYBCalculator on Opportunity (before insert, before update) {   
    
    List<ID> opportunityIdList = new List<ID>();
    
    for (Integer i = 0; i < Trigger.new.size(); i++)
    {       
        opportunityIdList.add(Trigger.new[i].Id);
    }
    
    OpportunityLineItem[] opportunityLineItems = [Select 
        Id, 
        OpportunityId,
        UnitPrice, 
        TotalPrice, 
        Quantity,
        ActualStartDate__c,
        ActualEndDate__c,
        ActualTerm__c,
        Year1Amount__c,
        Year2Amount__c,
        Year3Amount__c,
        Year4Amount__c,
        Year5Amount__c,
        Year6Amount__c,
        PricebookEntry.Product2.Term__c 
        From OpportunityLineItem 
        Where OpportunityId In :opportunityIdList];
            
    for (Integer i = 0; i < Trigger.new.size(); i++)
    {                                                               
        if (Trigger.isInsert) 
        {
            Trigger.new[i].QuoteNumber__c = null;               
        }

        if (! (Util.channelLoadByPass()) && Trigger.isUpdate && Trigger.new[i].HasOpportunityLineItem && Trigger.new[i].QuoteNumber__c == null)
        {
            if (Trigger.old[i].CloseDate != Trigger.new[i].CloseDate) // || Trigger.old[i].RollupField__c != Trigger.new[i].RollupField__c)
            {   
                Opportunity opportunity = Trigger.new[i];   
                                                                               
                opportunity.Year1Amount__c = 0.00;
                opportunity.Year2Amount__c = 0.00;
                opportunity.Year3Amount__c = 0.00;
                opportunity.Year4Amount__c = 0.00;
                opportunity.Year5Amount__c = 0.00;
                opportunity.Year6Amount__c = 0.00;
                
        //        OpportunityLineItem[] opportunityLineItems = [Select 
        //            Id, 
        //            UnitPrice, 
        //            TotalPrice, 
        //            Quantity,
        //            ActualStartDate__c,
        //            ActualEndDate__c,
        //            ActualTerm__c,
        //            Year1Amount__c,
        //            Year2Amount__c,
        //            Year3Amount__c,
        //            Year4Amount__c,
        //            Year5Amount__c,
        //            Year6Amount__c,
        //            PricebookEntry.Product2.Term__c 
        //            From OpportunityLineItem 
        //            Where OpportunityId = :opportunity.Id];      
                                       
                for (OpportunityLineItem opportunityLineItem : opportunityLineItems) 
                {                   
                    if (opportunityLineItem.OpportunityId == opportunity.Id)
                    {
                        opportunityLineItem.ActualStartDate__c = opportunity.CloseDate;
                                        
                        if (opportunityLineItem.ActualTerm__c == null) 
                        {
                            if (opportunityLineItem.PricebookEntry.Product2.Term__c == null) 
                            {
                                opportunityLineItem.ActualTerm__c = 365;
                            } 
                            else 
                            {
                                opportunityLineItem.ActualTerm__c = opportunityLineItem.PricebookEntry.Product2.Term__c; 
                            }  
                        }
                                                                                             
                        opportunityLineItem.ActualEndDate__c = opportunityLineItem.ActualStartDate__c + opportunityLineItem.ActualTerm__c.longValue() -1;
                                                                          
                        Decimal totalPrice = opportunityLineItem.UnitPrice * opportunityLineItem.Quantity;
                    
                        opportunityLineItem.Year1Amount__c = 0.00;
                        opportunityLineItem.Year2Amount__c = 0.00;
                        opportunityLineItem.Year3Amount__c = 0.00;
                        opportunityLineItem.Year4Amount__c = 0.00;
                        opportunityLineItem.Year5Amount__c = 0.00;
                        opportunityLineItem.Year6Amount__c = 0.00;
                                                                                                                                 
                        if (opportunityLineItem.ActualTerm__c <= 365) 
                        {
                            opportunityLineItem.Year1Amount__c = totalPrice;
                        } 
                        else if (opportunityLineItem.ActualTerm__c > 365 && opportunityLineItem.ActualTerm__c <= 730) 
                        {                                           
                            opportunityLineItem.Year1Amount__c = Math.round((totalPrice / 2) * Math.pow(10,2)) / Math.pow(10,2);
                            opportunityLineItem.Year2Amount__c = totalPrice - opportunityLineItem.Year1Amount__c;                        
                        } 
                        else if (opportunityLineItem.ActualTerm__c > 730 && opportunityLineItem.ActualTerm__c <= 1095) 
                        {
                            opportunityLineItem.Year1Amount__c = Math.round((totalPrice / 3) * Math.pow(10,2)) / Math.pow(10,2);
                            opportunityLineItem.Year2Amount__c = Math.round((totalPrice / 3) * Math.pow(10,2)) / Math.pow(10,2);
                            opportunityLineItem.Year3Amount__c = totalPrice
                                - opportunityLineItem.Year1Amount__c 
                                - opportunityLineItem.Year2Amount__c;
                        }  
                        else if (opportunityLineItem.ActualTerm__c > 1095 && opportunityLineItem.ActualTerm__c <= 1460) 
                        {
                            opportunityLineItem.Year1Amount__c = Math.round((totalPrice / 4) * Math.pow(10,2)) / Math.pow(10,2);
                            opportunityLineItem.Year2Amount__c = Math.round((totalPrice / 4) * Math.pow(10,2)) / Math.pow(10,2);
                            opportunityLineItem.Year3Amount__c = Math.round((totalPrice / 4) * Math.pow(10,2)) / Math.pow(10,2);
                            opportunityLineItem.Year4Amount__c = totalPrice 
                                - opportunityLineItem.Year1Amount__c 
                                - opportunityLineItem.Year2Amount__c  
                                - opportunityLineItem.Year3Amount__c;
                        }
                        else if (opportunityLineItem.ActualTerm__c > 1460 && opportunityLineItem.ActualTerm__c <= 1825) 
                        {
                            opportunityLineItem.Year1Amount__c = Math.round((totalPrice / 5) * Math.pow(10,2)) / Math.pow(10,2);
                            opportunityLineItem.Year2Amount__c = Math.round((totalPrice / 5) * Math.pow(10,2)) / Math.pow(10,2);
                            opportunityLineItem.Year3Amount__c = Math.round((totalPrice / 5) * Math.pow(10,2)) / Math.pow(10,2);
                            opportunityLineItem.Year4Amount__c = Math.round((totalPrice / 5) * Math.pow(10,2)) / Math.pow(10,2);
                            opportunityLineItem.Year5Amount__c = totalPrice 
                                - opportunityLineItem.Year1Amount__c 
                                - opportunityLineItem.Year2Amount__c 
                                - opportunityLineItem.Year3Amount__c 
                                - opportunityLineItem.Year4Amount__c;
                        } 
                        else 
                        {
                            opportunityLineItem.Year1Amount__c = Math.round((totalPrice / 6) * Math.pow(10,2)) / Math.pow(10,2);
                            opportunityLineItem.Year2Amount__c = Math.round((totalPrice / 6) * Math.pow(10,2)) / Math.pow(10,2);
                            opportunityLineItem.Year3Amount__c = Math.round((totalPrice / 6) * Math.pow(10,2)) / Math.pow(10,2);
                            opportunityLineItem.Year4Amount__c = Math.round((totalPrice / 6) * Math.pow(10,2)) / Math.pow(10,2);
                            opportunityLineItem.Year5Amount__c = Math.round((totalPrice / 6) * Math.pow(10,2)) / Math.pow(10,2);
                            opportunityLineItem.Year6Amount__c = totalPrice 
                                - opportunityLineItem.Year1Amount__c 
                                - opportunityLineItem.Year2Amount__c 
                                - opportunityLineItem.Year3Amount__c 
                                - opportunityLineItem.Year4Amount__c
                                - opportunityLineItem.Year5Amount__c;
                        }    
                                    
                        opportunity.Year1Amount__c = Trigger.new[i].Year1Amount__c + opportunityLineItem.Year1Amount__c;
                        opportunity.Year2Amount__c = Trigger.new[i].Year2Amount__c + opportunityLineItem.Year2Amount__c;
                        opportunity.Year3Amount__c = Trigger.new[i].Year3Amount__c + opportunityLineItem.Year3Amount__c;
                        opportunity.Year4Amount__c = Trigger.new[i].Year4Amount__c + opportunityLineItem.Year4Amount__c;
                        opportunity.Year5Amount__c = Trigger.new[i].Year5Amount__c + opportunityLineItem.Year5Amount__c;
                        opportunity.Year6Amount__c = Trigger.new[i].Year6Amount__c + opportunityLineItem.Year6Amount__c;
                                                                                                 
                    }  
                }                                                                             
            }                    
        }
    }     
    
    update opportunityLineItems;       
}