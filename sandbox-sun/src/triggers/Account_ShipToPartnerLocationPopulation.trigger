trigger Account_ShipToPartnerLocationPopulation on Account (before update, after update) {
    if(BooleanSetting__c.getInstance('DeactivateAll') != null && BooleanSetting__c.getInstance('DeactivateAll').Value__c == true) return;

    // If the shipping address is blank just copy the bill to address
    if (Trigger.isBefore) {
        for (Account beforeUpdate : Trigger.new) {
             if (beforeupdate.ShippingStreet == null && beforeupdate.IsPartner == True){
                 // Classification__c IProductClassifications = [Select Name, Parent__c, IdFrom Classification__c where id=:beforeupdate.Industry__c];
                 beforeupdate.ShippingStreet = beforeupdate.BillingStreet;
                 beforeupdate.ShippingCity = beforeupdate.BillingCity;
                 beforeupdate.ShippingState = beforeupdate.BillingState;
                 beforeupdate.ShippingPostalCode = beforeupdate.BillingPostalCode;
                 beforeupdate.ShippingCountry = beforeupdate.BillingCountry;
            }    
        } 
    }
    //If it is not a location listed in the partner account populates ship to as primary  address
    if (Trigger.isAfter){ 
        system.debug('------[loc] After update in location trigger');                    
        List<Partner_Location__c> locsToInsert = new List<Partner_Location__c>(); 
        List<Partner_Location__c> partnerLocations = [Select Id, Name, Is_Primary__c, Partner__c From Partner_Location__c where Partner__c in :Trigger.new ];
        
        for (Account curAcct : Trigger.new ){
            if (curAcct.IsPartner == True){
                Boolean hasLocationAlready = false;
                for (Partner_Location__c pl : partnerLocations){
                    if (pl.Partner__c == curAcct.Id){
                        hasLocationAlready = true;
                        system.debug('------[loc] Already found address for: ' + curAcct.Name);                    
                        break;
                    }
                }
                if (hasLocationAlready)
                    continue;

                system.debug('------[loc] Creating address for: ' + curAcct.Name + ' - ' + curAcct.ShippingStreet + ', ' + curAcct.ShippingCity + ', ' + curAcct.ShippingState + ', ' + curAcct.ShippingCountry);                    
                if (curAcct.ShippingCountry != null && curAcct.ShippingCountry.length() < 3 && curAcct.ShippingCity != null && curAcct.ShippingStreet != null )  {      
                    system.debug('------[loc] Creating...');                    
                    locsToInsert.add(new Partner_Location__c (
                        Name= 'Shipping Address',
                        Street__c = curAcct.ShippingStreet, 
                        City__c = curAcct.ShippingCity,
                        State_Province__c = curAcct.ShippingState,
                        Postal_Code__c = curAcct.ShippingPostalCode,
                        Country__c = curAcct.ShippingCountry,
                        Partner__c = curAcct.Id,
                        Website__c = curAcct.Website,
                        Convert__c = True,
                        Is_Primary__c = True)
                    );
                    system.debug('------[loc] Done.');                    
                    
                 }   
            }    
        }
        if (locsToInsert.size()>0){
            insert locsToInsert;
        } 
    }
}