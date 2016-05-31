trigger Opportunity_history on Opportunity (after insert, after update)
{
    Map<String,Opportunity_History__c> oppHistory= new Map<String,Opportunity_History__c>();
    Map<String,String> oppIds= new Map<String,String>();
    List<Opportunity_History__c> insertHistory = new List<Opportunity_History__c>();

    if(Trigger.isAfter)
    {
        //trigger when new opportunity is created
        if((Trigger.isInsert))
        {
            for(Opportunity opp :trigger.New)
            {
                Opportunity_History__c history = new Opportunity_History__c();
                history.Opportunity__c = opp.Id;
                history.Opportunity_Type__c = opp.OpportunityType__c;
                history.Financial_Partner__c = opp.Primary_Partner__c;
                history.Channel__c = opp.FulfillmentChannel__c;
                history.Payment_Type__c = opp.PaymentType__c;
                history.Pay_Now__c = opp.Pay_Now__c;
                history.Account__c = opp.AccountId;
                history.Owner__c = opp.OwnerId;
                history.Opportunity_Name__c = opp.Name;
                insertHistory.add(history);
            }
            insert insertHistory;
        }

        //trigger when the opportunity specific data are updated.
        if((Trigger.isUpdate))
        {
            for(Integer i=0;i<Trigger.new.size();i++)
            {
                if(Trigger.new[i].OpportunityType__c != Trigger.old[i].OpportunityType__c
                    || Trigger.new[i].Primary_Partner__c != Trigger.old[i].Primary_Partner__c
                    || Trigger.new[i].FulfillmentChannel__c != Trigger.old[i].FulfillmentChannel__c
                    || Trigger.new[i].PaymentType__c != Trigger.old[i].PaymentType__c
                    || Trigger.new[i].Pay_Now__c != Trigger.old[i].Pay_Now__c
                    || Trigger.new[i].OwnerId != Trigger.old[i].OwnerId
                    || Trigger.new[i].AccountId != Trigger.old[i].AccountId
                    || Trigger.new[i].Name != Trigger.old[i].Name)
                {
                    oppIds.put(Trigger.new[i].Id,Trigger.new[i].Id);
                }
            }
            Opportunity_History__c[] oldHistries ;

            if(oppIds.size() <1) return;

            try
            {
                oldHistries = [select
                    Opportunity_Type__c
                    , Opportunity_Name__c
                    , Financial_Partner__c
                    , Channel__c
                    , Payment_Type__c
                    , Pay_Now__c
                    , Account__c
                    , Owner__c
                    from  Opportunity_History__c
                    where
                    Opportunity__c IN :oppIds.Values() order by LastModifiedDate asc ];
            }
            catch(Exception ignored) {}

            //populate opportunity history object.
            for(Opportunity_History__c history:oldHistries)
            {
                oppHistory.put(history.Opportunity__c,history);
            }

            Opportunity_History__c oldHistory   = null;

            //Run through the list of opportunities to check the history
            for(Integer i=0;i<Trigger.new.size();i++)
            {
                oldHistory  = null;
                if(!oppIds.containsKey(Trigger.new[i].Id)) continue;

                oldHistory = oppHistory.get(Trigger.new[i].Id);
                if(oldHistory != null)
                {
                    if(oldHistory.Opportunity_Type__c != Trigger.new[i].OpportunityType__c
                        || oldHistory.Financial_Partner__c != Trigger.new[i].Primary_Partner__c
                        || oldHistory.Channel__c != Trigger.new[i].FulfillmentChannel__c
                        || oldHistory.Pay_Now__c != Trigger.new[i].Pay_Now__c
                        || oldHistory.Payment_Type__c != Trigger.new[i].PaymentType__c
                        || oldHistory.Account__c != Trigger.new[i].AccountId
                        || oldHistory.Owner__c != Trigger.new[i].OwnerId
                        || oldHistory.Opportunity_Name__c != Trigger.new[i].Name)
                    {
                        Opportunity_History__c historyUpload = new Opportunity_History__c();
                        historyUpload.Opportunity__c = Trigger.new[i].Id;
                        historyUpload.Opportunity_Type__c = Trigger.new[i].OpportunityType__c;
                        historyUpload.Financial_Partner__c = Trigger.new[i].Primary_Partner__c;
                        historyUpload.Channel__c = Trigger.new[i].FulfillmentChannel__c;
                        historyUpload.Payment_Type__c= Trigger.new[i].PaymentType__c;
                        historyUpload.Pay_Now__c = Trigger.new[i].Pay_Now__c;
                        historyUpload.Account__c= Trigger.new[i].AccountId;
                        historyUpload.Owner__c = Trigger.new[i].OwnerId;
                        historyUpload.Opportunity_Name__c = Trigger.new[i].Name;
                        insertHistory.add(historyUpload);
                    }
                }
                else
                {
                    Opportunity_History__c historyUpload = new Opportunity_History__c();
                    historyUpload.Opportunity__c = Trigger.new[i].Id;
                    historyUpload.Opportunity_Type__c = Trigger.new[i].OpportunityType__c;
                    historyUpload.Financial_Partner__c = Trigger.new[i].Primary_Partner__c;
                    historyUpload.Channel__c = Trigger.new[i].FulfillmentChannel__c;
                    historyUpload.Payment_Type__c= Trigger.new[i].PaymentType__c;
                    historyUpload.Pay_Now__c = Trigger.new[i].Pay_Now__c;
                    historyUpload.Account__c = Trigger.new[i].AccountId;
                    historyUpload.Owner__c = Trigger.new[i].OwnerId;
                    historyUpload.Opportunity_Name__c = Trigger.new[i].Name;
                    insertHistory.add(historyUpload);
                }
            }
            insert insertHistory;
        }
    }
}