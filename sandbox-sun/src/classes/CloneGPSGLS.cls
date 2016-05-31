public class CloneGPSGLS{

	public void cloneOpportunity(Opportunity[] new_array){
		
		boolean isEMEAOpp=false;
		if(new_array[0].Super_Region__c=='EMEA'){
			isEMEAOpp=true;	
		}
		
		System.debug('2');
		System.debug('isEMEAOpp '+isEMEAOpp);
		System.debug('new_array[0].id '+new_array[0].id);
		System.debug('new_array[0].Super_Region__c '+new_array[0].Super_Region__c);
		System.debug('new_array[0].Country_of_Order__c '+new_array[0].Country_of_Order__c);
		if(isEMEAOpp){
			// Check if GPS,GLS product is present
			System.debug('3');
			
			integer GPSGLSProductsCount =0;
			OpportunityLineItem[] lineitems=[Select opportunityId,PricebookEntry.Name, PricebookEntry.CurrencyIsoCode, PricebookEntry.Product2.Family, PricebookEntry.Product2.ProductCode, Quantity,CurrencyIsoCode,UnitPrice,TotalPrice from OpportunityLineItem where OpportunityId =:new_array[0].id ];			
			Util.products.put(new_array[0].id,lineitems);
			
			System.debug('3');
			for(OpportunityLineItem product : lineitems ){
				String product_Name=product.PricebookEntry.Product2.Family;
				if(product_Name.startsWith('GPS') || product_Name.startsWith('GLS') ){
						GPSGLSProductsCount ++;
				}			
			}
			System.debug('GPSGLSProductsCount '+GPSGLSProductsCount );
			if(GPSGLSProductsCount > 0){
				System.debug('Sending Mail');
				new GPSGLSProductNotificationMail().createMail(new_array[0],lineitems,'insert');
						
			}
						
		}
	}
	public static testmethod void deployCloneGPSGLS(){
		
		
		String oppid=[Select opportunityId,PricebookEntry.Product2.Family from OpportunityLineItem where (PricebookEntry.Product2.Family like '%GPS%' or PricebookEntry.Product2.Family like '%GLS%' )and opportunity.Super_Region__c='EMEA' limit 1].opportunityId;	

		List<Opportunity> tandem_Opportunities = new List<Opportunity>();
		Opportunity  tandem_Opportunity ;
		tandem_Opportunity = [select id,stageName,Super_Region__c,Country_of_Order__c from Opportunity where id=:oppid];
		tandem_Opportunities.add(tandem_Opportunity);

		

		new CloneGPSGLS().cloneOpportunity(tandem_Opportunities);

		

	}
  }