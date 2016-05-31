trigger GPSGLSProductNotification on OpportunityLineItem ( after insert,after delete )
{
    OpportunityLineItem[] lineitems;
    boolean isEMEAOpp=false;
    if(Trigger.isInsert)
    {
        System.debug('Going to insert');
        boolean hasNewGLSProduct=false;

        //by pass for admin
        if(Util.adminByPass()) return;

        // Check EMEA Region

        Opportunity opp=Util.getOpportunityData(Trigger.new[0].OpportunityId);
        System.debug('opp.name '+opp.name );
        System.debug('opp.Super_Region__c '+opp.Super_Region__c );
        if(opp.Super_Region__c=='EMEA')
        {
            isEMEAOpp=true;
        }

        if(isEMEAOpp)
        {
            // Check if GPS,GLS product is present
            
            //Set <String> setProducts=new Set <String>();
            Integer GPSGLSProductsCount =0;
            
            lineitems=Util.getProducts(Trigger.new[0].OpportunityId);
            for(OpportunityLineItem product : lineitems )
            {
                String product_Name=product.PricebookEntry.Name;
                if(product_Name.startsWith('GPS') || product_Name.startsWith('GLS') ){
                    GPSGLSProductsCount ++;
                    //setProducts.add(product.id);
                }
            }
            
            if(GPSGLSProductsCount > 0)
            {
                Map<String,OpportunityLineItem> new_products= new Map<String,OpportunityLineItem>();
                for(Integer i=0;i<Trigger.size;i++ )
                {
                    //system.debug(Trigger.new[i]);
                    new_products.put(Trigger.new[i].PricebookEntryId,Trigger.new[i]);
                }
                Integer new_gpsgls_count=0;
                PricebookEntry[] pbe= [
                    Select PricebookEntry.Name, Id from PricebookEntry where id in :new_products.keySet() and (PricebookEntry.Name like '%GPS%' or PricebookEntry.Name like '%GLS%')];
                Integer deleted_gpsgls_count;
                for(PricebookEntry product: pbe)
                {
                    new_gpsgls_count=pbe.size();
                }
                if( new_gpsgls_count== GPSGLSProductsCount)
                {
                    System.debug('Sending Mail');
                    new GPSGLSProductNotificationMail().createMail(null,lineitems,'insert');
                }
            }
        }
    }

    if(Trigger.isDelete)
    {
        System.debug('Going to delete');

        Opportunity opp=Util.getOpportunityData(Trigger.old[0].OpportunityId);
        if(opp.Super_Region__c=='EMEA')
        {
            isEMEAOpp=true;
        }

        if(isEMEAOpp){
            System.debug('EMEA OPP');

            // Check if GPS,GLS product is present

            Integer GPSGLSProductsCount =0;

            lineitems=Util.getProducts(Trigger.old[0].OpportunityId);
            for(OpportunityLineItem product : lineitems )
            {
                String product_Name=product.PricebookEntry.Name;
                if(product_Name.startsWith('GPS') || product_Name.startsWith('GLS') )
                {
                    GPSGLSProductsCount++;
                }
            }

            if(GPSGLSProductsCount==0)
            {
                OpportunityLineItem[] deleted_products=new OpportunityLineItem[0] ;
                Map <Id,OpportunityLineItem> deleted_items = new Map <Id,OpportunityLineItem>();
                for(integer j=0; j<Trigger.old.size();j++ )
                {
                    deleted_items.put(Trigger.old[j].PricebookEntryId,Trigger.old[j]);
                    deleted_products.add(Trigger.old[j]);
                }
                PricebookEntry[] pbe= [
                    Select PricebookEntry.Name, Id from PricebookEntry where id in :deleted_items.keySet() and (PricebookEntry.Name like '%GPS%' or PricebookEntry.Name like '%GLS%')];
                Integer deleted_gpsgls_count;
                for(PricebookEntry product: pbe)
                {
                    deleted_gpsgls_count=pbe.size();
                }
                if(deleted_gpsgls_count>=1 )
                {
                    System.debug('Sending Mail');
                    new GPSGLSProductNotificationMail().createMail(null,deleted_products,'delete');
                }
            }
        }
    }
}