trigger PartnerProduct_SyncProductDetails on PartnerProduct__c (before insert, before update) {

	for (PartnerProduct__c newPartnerProducts : Trigger.new) {
   		if (Trigger.isInsert) {
            if (newPartnerProducts.Product_Detail_to_Load__c == null && newPartnerProducts.Product_Details__c != null) {
            	newPartnerProducts.Product_Detail_to_Load__c = newPartnerProducts.Product_Details__c;
            }
            else {         
            	newPartnerProducts.Product_Details__c = newPartnerProducts.Product_Detail_to_Load__c; 
            }
        }
        else if (Trigger.isUpdate) {
			PartnerProduct__c beforeUpdate = System.Trigger.oldMap.get(newPartnerProducts.Id); 
			if (beforeUpdate.Product_Detail_to_Load__c != newPartnerProducts.Product_Detail_to_Load__c) {
            	newPartnerProducts.Product_Details__c = newPartnerProducts.Product_Detail_to_Load__c;
            }    
            else {
           		newPartnerProducts.Product_Detail_to_Load__c = newPartnerProducts.Product_Details__c;
            }
            //
            // if user changes the name but not full name, replace full name
            //
            if (beforeUpdate.Name != newPartnerProducts.Name && beforeUpdate.Full_Product_Name__c == newPartnerProducts.Full_Product_Name__c) {
            	newPartnerProducts.Full_Product_Name__c = newPartnerProducts.Name;
            }
		}

		//
		// If users erases full name, or full name not yet filled out, force it
		//
		if (newPartnerProducts.Name != null && newPartnerProducts.Full_Product_Name__c == null) {
			newPartnerProducts.Full_Product_Name__c = newPartnerProducts.Name;
		}

		//
		// Make sure Name contains the truncated product name of record (full name)
		//
        if (newPartnerProducts.Full_Product_Name__c != null && newPartnerProducts.Full_Product_Name__c.length() >= 80) {
        	newPartnerProducts.Name = newPartnerProducts.Full_Product_Name__c.substring(0, 79);
        }
        else {
        	newPartnerProducts.Name = newPartnerProducts.Full_Product_Name__c;
        }

	}
}