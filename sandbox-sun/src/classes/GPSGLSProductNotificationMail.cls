public class GPSGLSProductNotificationMail
{
	public Boolean mailSent = false;
	String[] toAddresses =new String[0];
	String body='';
	String subject='';
	String AccountName='';


	public void sendMail(){

		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		//String[] ccAddresses =new String[] {'prasadkothawade@gmail.com','prasad.s.kothawade@accenture.com'};

		toAddresses.add('gps-projects-reply@redhat.com') ;
		mail.setToAddresses(toAddresses);
		//mail.setCcAddresses(ccAddresses);


		// Specify the name used as the display name.
		mail.setSenderDisplayName('SALES FORCE');

		// Specify the subject line for your email address.
		mail.setSubject(subject);

		// Set to True if you want to BCC yourself on the email.
		mail.setBccSender(false);
		// Optionally append the salesforce.com email signature to the email.
		// The email address of the user executing the Apex Code will be used.
		mail.setUseSignature(false);
		// Specify the text content of the email.
		mail.setPlainTextBody(body);

		Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail } );
		mailSent = true;
	}

	public void createMail(Opportunity opp,OpportunityLineItem[] GPSProduct,String Operation)
	{
	try
		{
			System.debug('operation&&&&'+Operation);
			createBody(opp,GPSProduct,Operation);
			sendMail();

		}
	catch(Exception e)
	{
		System.debug('Exception is => ' + e.getMessage());
	}
	}

	void createBody(Opportunity newOpp,OpportunityLineItem[] lineitems,String Operation){
		System.debug('pdts***'+lineitems);
		OpportunityLineItem product=lineitems[0];
		System.debug('Operation***'+Operation);
		//=[Select account.RecordType.Name,account.Name,account.Account_Priority__c, account.AccountClassification__c, account.AccountRating__c, account.EMEA_SE_Required__c, account.OwnerId, OwnerId,CurrencyIsoCode,AccountId, Amount, BillingAddress__c, BillingCity__c, BillingCountry__c, CloseDate, Country_of_Order__c, EMEA_SE_Required__c, ForecastCategory, FulfillmentChannel__c, Id, Name, Opportunity_Priority__c, OpportunityNumber__c, Primary_Partner__c, ProductsOfInterest__c, Region__c, Reseller__c, ShippingAddress__c, ShippingCity__c, ShippingCountry__c, StageName, LastModifiedById from opportunity where id=:product.opportunityId];


		String id=product.opportunityId;
		Opportunity oldOpp = Util.getOpportunityData(id);
		System.debug('oldOpp&&&'+oldOpp);
		if(newOpp==null){
			newOpp=oldOpp;
		}
		System.debug('NEWOPP'+ newOpp);

		Double amount = newOpp.amount;
		String currencyCode = newOpp.CurrencyIsoCode;

		body='The Opportunity Details as:\n'+
			'\n Account: '+ oldOpp.account.name+
			'\n Name: '+ newOpp.name+
			'\n Amount:'+ newOpp.CurrencyIsoCode+' '+ newOpp.amount+
			'\n CloseDate:'+ newOpp.CloseDate+
			'\n Stage: '+ newOpp.StageName+
			'\n URL:'+Util.sfdcurl + newOpp.id+
			'\n ConvertedAmount: USD'+Util.getConvertedAmount(currencyCode, amount );

		System.debug('body'+body);

		if(Operation=='insert'){
			String str='The GPS/GLS product are as \n Name   Quantity   Total Price   Converted Total Price';

			//OpportunityLineItem[] lineitems = [
			//Select PricebookEntry.Name, Quantity,CurrencyIsoCode,UnitPrice,TotalPrice from OpportunityLineItem where OpportunityId =:product.OpportunityId and (PricebookEntry.Name like '%GPS%' or PricebookEntry.Name like '%GLS%')];
			for(OpportunityLineItem product1: lineitems ){
				System.debug('product1.PricebookEntry.Product2.Family'+product1.PricebookEntry.Product2.Family);
				if(product1.PricebookEntry.Product2.Family.startsWith('GPS') || product1.PricebookEntry.Product2.Family.startsWith('GLS') ){
					amount =product1.TotalPrice;
					currencyCode = product1.CurrencyIsoCode;
					Double convertedprice=Util.getConvertedAmount(currencyCode, amount );

					str=str+'\n'+product1.PricebookEntry.Product2.Family +'   ' + product1.Quantity+'   '+product1.TotalPrice+'   '+convertedprice;
				}
			}


			subject='[SFDC #'+ newOpp.OpportunityNumber__c+'] New Opportunity "'+ newOpp.name+'" created for "'+ oldOpp.account.name+'"' ;
			body=body+str;
		} else if (Operation=='stage update'){
			subject='[SFDC #'+ newOpp.OpportunityNumber__c+'] Stage Changed to "'+ newOpp.StageName +'"';
		}
		else{
			subject='[SFDC #'+ newOpp.OpportunityNumber__c+'] Opportunity gone ';
		}


		// Request Form Fields


		Map<ID,User> ownerUsers = new Map<ID,User>();
		Set<ID> users = new Set<ID>();
		if(oldOpp.account.OwnerId != null) {
			ownerUsers.put(oldOpp.account.OwnerId,oldOpp.account.Owner);
			users.add(oldOpp.account.OwnerId);
		}
		if(oldOpp.OwnerId != null) {
			ownerUsers.put(oldOpp.OwnerId,oldOpp.Owner);
			users.add(oldOpp.OwnerId);
		}
		if(oldOpp.LastModifiedById != null) {
			ownerUsers.put(oldOpp.LastModifiedById,oldOpp.LastModifiedBy);
			users.add(oldOpp.LastModifiedById);
		}

		// users.add(oldOpp.LastModifiedById);
		System.debug('\n account.OwnerId '+ oldOpp.account.OwnerId);
		System.debug('\n OwnerId '+newOpp.OwnerId);
		System.debug('\n LastModifiedById '+newOpp.LastModifiedById);
		System.debug('\n oldOpp.account.Owner '+ oldOpp.account.OwnerId);
		System.debug('\n oldOpp.Owner '+ oldOpp.OwnerId);
		System.debug('\n oldOpp.LastModifiedBy '+oldOpp.LastModifiedById);
		System.debug('\n ownerUsers '+ ownerUsers);
		System.debug('\n users '+ users);
		// Jboss Product
		Boolean jboss_flag=false;
		/*OpportunityLineItem[] jbossItems = [
		Select PricebookEntry.Name, Quantity from OpportunityLineItem where OpportunityId =:product.OpportunityId and PricebookEntry.Name like 'JBoss%'];
		for(OpportunityLineItem jbossitem:jbossItems){
			jboss_flag=true;
		}*/

		jboss_flag=Util.hasJbossProducts(product.OpportunityId);

		Map<ID,User> accountTeamUsers = new Map<ID,User>();
		// Presales Account Team
		AccountTeamMember [] AccountTeam=[Select User.Id, User.UserRole.Name, User.Email from AccountTeamMember where (TeamMemberRole='Presales Owner' and accountid=:oldOpp.AccountId)];
		for(AccountTeamMember member:AccountTeam){
			//users.add(member.UserId);
			System.debug('\n member.UserId '+member.UserId);
			if(! ownerUsers.containsKey(member.UserId) && !users.contains(member.UserId)) {
				accountTeamUsers.put(member.UserId,member.User);
				System.debug('\n member.UserId '+member.UserId);
			}
		}

		// Presales Opportunity Team
		Map<ID,User> salesTeamUsers = new Map<ID,User>();
		OpportunityTeamMember[] SalesTeam=Util.getSalesTeam(product.opportunityId);
		for(OpportunityTeamMember salesrep :SalesTeam){
			System.debug('\n salesrep.UserId '+salesrep.UserId);
			if(! ownerUsers.containsKey(salesrep.UserId) && ! users.contains(salesrep.UserId)) {
				if(salesrep.TeamMemberRole=='Presales Owner') {
					salesTeamUsers.put(salesrep.UserId,salesrep.User);
					System.debug('\n salesrep.UserId '+salesrep.UserId);
				}
			}
		}

		String RequestFormFields='\n Opportunity Request Form Fields as: \n';
		RequestFormFields=RequestFormFields+ ' \n accountClassification='+ Util.nullCheck(oldOpp.account.AccountClassification__c);
		RequestFormFields=RequestFormFields+ ' \n accountName='+ Util.nullCheck(oldOpp.account.Name);
		RequestFormFields=RequestFormFields+ ' \n accountPriority='+ Util.nullCheck(oldOpp.account.Account_Priority__c);
		RequestFormFields=RequestFormFields+ ' \n accountRating='+ Util.nullCheck(oldOpp.account.AccountRating__c);
		RequestFormFields=RequestFormFields+ ' \n tandemAccount ='+(oldOpp.account.EMEA_SE_Required__c);
		RequestFormFields=RequestFormFields+ ' \n accountid='+ Util.nullCheck(newOpp.AccountId);
		RequestFormFields=RequestFormFields+ ' \n amount='+ (newOpp.Amount);
		RequestFormFields=RequestFormFields+ ' \n billingAddress='+ Util.nullCheck(newOpp.BillingAddress__c);
		RequestFormFields=RequestFormFields+ ' \n billingCity='+ Util.nullCheck(newOpp.BillingCity__c);
		RequestFormFields=RequestFormFields+ ' \n billingCountry='+ Util.nullCheck(newOpp.BillingCountry__c);
		RequestFormFields=RequestFormFields+ ' \n closeDate='+ (newOpp.CloseDate);
		RequestFormFields=RequestFormFields+ ' \n countryOfOrder='+ Util.nullCheck(newOpp.Country_of_Order__c);
		RequestFormFields=RequestFormFields+ ' \n financialPartner='+ Util.nullCheck(newOpp.Primary_Partner__c);
		RequestFormFields=RequestFormFields+ ' \n forecastCategory='+ Util.nullCheck(newOpp.ForecastCategory);
		RequestFormFields=RequestFormFields+ ' \n fulfillmentChannel='+ Util.nullCheck(newOpp.FulfillmentChannel__c);
		RequestFormFields=RequestFormFields+ ' \n opportunityID='+ (newOpp.Id);
		RequestFormFields=RequestFormFields+ ' \n opportunityName='+ (newOpp.Name);
		RequestFormFields=RequestFormFields+ ' \n opportunityNumber='+ Util.nullCheck(newOpp.OpportunityNumber__c);
		RequestFormFields=RequestFormFields+ ' \n opportunityPriority='+ Util.nullCheck(newOpp.Opportunity_Priority__c);
		RequestFormFields=RequestFormFields+ ' \n productOfInterest='+ Util.nullCheck(newOpp.ProductsOfInterest__c);
		RequestFormFields=RequestFormFields+ ' \n region='+ Util.nullCheck(newOpp.Region__c);
		RequestFormFields=RequestFormFields+ ' \n reseller='+ Util.nullCheck(newOpp.Reseller__c);
		RequestFormFields=RequestFormFields+ ' \n shippingAddr='+ Util.nullCheck(newOpp.ShippingAddress__c);
		RequestFormFields=RequestFormFields+ ' \n shippingCity='+ Util.nullCheck(newOpp.ShippingCity__c);
		RequestFormFields=RequestFormFields+ ' \n shippingCountry='+ Util.nullCheck(newOpp.ShippingCountry__c);
		RequestFormFields=RequestFormFields+ ' \n stage='+ Util.nullCheck(newOpp.StageName);
		RequestFormFields=RequestFormFields+ ' \n tandemOpportunity='+ (newOpp.EMEA_SE_Required__c);
		RequestFormFields=RequestFormFields+ ' \n jboss='+ (jboss_flag);

		System.debug('oldOpp.account.OwnerId' + oldOpp.account.OwnerId);
		System.debug('userrs**'+ users);
		if(oldOpp.account.OwnerId != null && users.remove(oldOpp.account.Owner.Id)) {
			RequestFormFields=RequestFormFields+ ' \n accountOwnerRole=' +oldOpp.account.Owner.UserRole.Name;
			RequestFormFields=RequestFormFields+ ' \n accountOwnerEmail=' +oldOpp.account.Owner.Email;
		}
		//System.debug('oldOpp.account.OwnerId='+ oldOpp.account.OwnerId);

		if(oldOpp.OwnerId != null && users.remove(oldOpp.OwnerId)){
			RequestFormFields=RequestFormFields+ ' \n opportunityOwnerEmail=' +oldOpp.Owner.Email;
		}
		System.debug('oldOpp.OwnerId='+ oldOpp.OwnerId);

		if(oldOpp.LastModifiedById != null && users.remove(oldOpp.LastModifiedById)){
			RequestFormFields=RequestFormFields+ ' \n sfdcUserEmail=' +oldOpp.LastModifiedBy.Email;
		}
		System.debug('oldOpp.LastModifiedById='+ oldOpp.LastModifiedById);

		for(User user : accountTeamUsers.values()) {
			RequestFormFields=RequestFormFields+ ' \n accountPresalesOwner=' +user.Email;
		}
		for(User user : salesTeamUsers.values()) {
			RequestFormFields=RequestFormFields+ ' \n preSalesEmail=' +user.Email;
		}

		body=body+RequestFormFields;
		System.debug('body '+body);
	}

}