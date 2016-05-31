trigger GPSGLSNotification on Opportunity (after update)
{
    if(BooleanSetting__c.getInstance('DeactivateAll') != null && BooleanSetting__c.getInstance('DeactivateAll').Value__c == true) return;
    for(Integer i=0;i<Trigger.new.size();i++)
    {
        if(Util.adminByPass()) return;
        //if(Util.gpsglsIds.get(Trigger.new[i].Id) != null) continue;

        Util.gpsglsIds.put(Trigger.new[i].Id,'Y');
        boolean hasGLSProduct=false;

        if(Trigger.old[i].StageName!=Trigger.new[i].StageName && Trigger.new[i].Super_Region__c=='EMEA' )
        {

            /*
                OpportunityLineItem[] lineitems = [
                Select Description,PricebookEntry.Name, Id, OpportunityId,PricebookEntryId from OpportunityLineItem where OpportunityId=:Trigger.new[i].id and (PricebookEntry.Name like '%GPS%' or PricebookEntry.Name like '%GLS%')];
                OpportunityLineItem item1;
                for( OpportunityLineItem item : lineitems ){
                    item1=item ;
                    hasGLSProduct=true;
                    break;
                }
            */

            OpportunityLineItem[] lineitems =Util.getProducts(Trigger.new[i].id);

            for(OpportunityLineItem product : lineitems )
            {
                String product_Name=product.PricebookEntry.Name;
                if(product_Name.startsWith('GPS') || product_Name.startsWith('GLS') )
                {
                    hasGLSProduct= true;
                }
            }

            if(hasGLSProduct)
            {
                new GPSGLSProductNotificationMail().createMail(Trigger.new[i],lineitems,'stage update');
            }
        }
    }
}