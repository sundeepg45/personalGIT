trigger OpportunityPartnerUpdateOpportunities on OpportunityPartner__c (after insert, after update, after delete)
{
//depreciated	final Map<Id,OpportunityPartner__c> financialPartnerMap = new Map<Id,OpportunityPartner__c>();
//depreciated	final Map<Id,OpportunityPartner__c> resellerPartnerMap = new Map<Id,OpportunityPartner__c>();
//depreciated	Map<Id,OpportunityPartner__c> relevantMap = Trigger.isDelete?Trigger.oldMap:Trigger.newMap;
//depreciated	System.debug('OpportunityPartnerUpdateOpportunities: '+relevantMap.values());
//depreciated	for(OpportunityPartner__c op : relevantMap.values())
//depreciated	{
//depreciated		System.debug('op.Id='+op.Id+',op.RelationshipType__c="'+op.RelationshipType__c+'"');
//depreciated		if(op.RelationshipType__c == 'Financial')
//depreciated		{
//depreciated			// we can safely ignore duplicates when deleting
//depreciated			if((!Trigger.isDelete) && financialPartnerMap.containsKey(op.Opportunity__c))
//depreciated			{
//depreciated				op.addError('Duplicate financial partner');
//depreciated				continue;
//depreciated			}
//depreciated			financialPartnerMap.put(op.Opportunity__c,op);
//depreciated		}
//depreciated		else if(op.RelationshipType__c == 'Reseller 2')
//depreciated		{
//depreciated			// we can safely ignore duplicates when deleting
//depreciated			if((! Trigger.isDelete) && resellerPartnerMap.containsKey(op.Opportunity__c))
//depreciated			{
//depreciated				op.addError('Duplicate reseller 2');
//depreciated				continue;
//depreciated			}
//depreciated			resellerPartnerMap.put(op.Opportunity__c,op);
//depreciated		}
//depreciated	}
//depreciated	final Set<Id> opportunityIds = financialPartnerMap.keySet().clone();
//depreciated	opportunityIds.addAll(resellerPartnerMap.keySet());
//depreciated	if(! opportunityIds.isEmpty())
//depreciated	{
//depreciated		// Lets take care of book-keeping first.
//depreciated		// Find existing partners
//depreciated		final List<OpportunityPartner__c> existingOpportunityPartners = [
//depreciated			select RelationshipType__c, Opportunity__c
//depreciated			from OpportunityPartner__c
//depreciated			where Opportunity__c in : opportunityIds
//depreciated			and ((RelationshipType__c = 'Financial' and Opportunity__c in :financialPartnerMap.keySet())
//depreciated			  or (RelationshipType__c = 'Reseller 2' and Opportunity__c in :resellerPartnerMap.keySet()))
//depreciated			and (not Id in :relevantMap.keySet()) ];
//depreciated		if(Trigger.isDelete)
//depreciated		{
//depreciated			// we can ignore deletes of partners that have duplicates
//depreciated			System.debug('Ignoring the delete of '+existingOpportunityPartners);
//depreciated			for(OpportunityPartner__c op : existingOpportunityPartners)
//depreciated			{
//depreciated				if(op.RelationshipType__c == 'Financial')
//depreciated				{
//depreciated					financialPartnerMap.remove(op.Opportunity__c);
//depreciated				}
//depreciated				else // if (op.RelationshipType__c == 'Reseller 2')
//depreciated				{
//depreciated					resellerPartnerMap.remove(op.Opportunity__c);
//depreciated				}
//depreciated			}
//depreciated		}
//depreciated		else
//depreciated		{
//depreciated			System.debug('Deleting '+existingOpportunityPartners);
//depreciated			// if this is an insert or update we need to remove pre-existing partners first
//depreciated			for(Database.DeleteResult r : Database.delete(existingOpportunityPartners,false))
//depreciated			{
//depreciated				OpportunityPartner__c op = existingOpportunityPartners.remove(0);
//depreciated				for(Database.Error e : r.getErrors() )
//depreciated				{
//depreciated					if(op.RelationshipType__c == 'Financial')
//depreciated					{
//depreciated						OpportunityPartner__c op2 = financialPartnerMap.remove(op.Opportunity__c);
//depreciated						if(op2 != null)
//depreciated						{
//depreciated							op2.addError('Failed to remove existing financial partner: '+e.getMessage());
//depreciated						}
//depreciated					}
//depreciated					else // if (op.RelationshipType__c == 'Reseller 2')
//depreciated					{
//depreciated						OpportunityPartner__c op2 = resellerPartnerMap.remove(op.Opportunity__c);
//depreciated						if(op2 != null)
//depreciated						{
//depreciated							op2.addError('Failed to remove existing reseller 2 partner: '+e.getMessage());
//depreciated						}
//depreciated					}
//depreciated				}
//depreciated			}
//depreciated		}
//depreciated		final Map<Id,Opportunity> updateOpportunityMap = new Map<Id,Opportunity>();
//depreciated		final Map<Id,Opportunity> opportunityMap = new Map<Id,Opportunity>([
//depreciated			select Id, Name, FinancialPartner__c, Primary_Partner__c, ResellerPartner__c, Reseller__c
//depreciated			from Opportunity where Id in :opportunityIds ]);
//depreciated		if(! resellerPartnerMap.isEmpty())
//depreciated		{
//depreciated			for(OpportunityPartner__c opportunityPartner : resellerPartnerMap.values())
//depreciated			{
//depreciated				final Opportunity opp = opportunityMap.get(opportunityPartner.Opportunity__c);
//depreciated				System.debug('Update opportunityPartner.Id='+opportunityPartner.Id+',Opportunity.Id='+opportunityPartner.Opportunity__c+'Opportunity.Name='+((opp!=null)?opp.Name:'null'));
//depreciated				if(opp != null)
//depreciated				{
//depreciated					String partnerName = null;
//depreciated					Id partnerId = null;
//depreciated					Boolean changed = (opp.ResellerPartner__c == opportunityPartner.Partner__c)||(opp.Reseller__c == opportunityPartner.PartnerName__c);
//depreciated					if(! Trigger.isDelete)
//depreciated					{
//depreciated						partnerId = opportunityPartner.Partner__c;
//depreciated						partnerName = opportunityPartner.PartnerName__c;
//depreciated						changed = ((opp.ResellerPartner__c != partnerId)||(opp.Reseller__c != partnerName));
//depreciated					}
//depreciated					if(changed)
//depreciated					{
//depreciated						opp.ResellerPartner__c = partnerId;
//depreciated						opp.Reseller__c = partnerName;
//depreciated						updateOpportunityMap.put(opp.Id,opp);
//depreciated					}
//depreciated				}
//depreciated			}
//depreciated		}
//depreciated		if(! financialPartnerMap.isEmpty())
//depreciated		{
//depreciated			for(OpportunityPartner__c opportunityPartner : financialPartnerMap.values())
//depreciated			{
//depreciated				final Opportunity opp = opportunityMap.get(opportunityPartner.Opportunity__c);
//depreciated				if(opp != null)
//depreciated				{
//depreciated					String partnerName = null;
//depreciated					Id partnerId = null;
//depreciated					Boolean changed = (opp.FinancialPartner__c == opportunityPartner.Partner__c)||(opp.Primary_Partner__c == opportunityPartner.PartnerName__c);
//depreciated					if( ! Trigger.isDelete )
//depreciated					{
//depreciated						partnerName = opportunityPartner.PartnerName__c;
//depreciated						partnerId = opportunityPartner.Partner__c;
//depreciated						changed = (opp.FinancialPartner__c != partnerId)||(opp.Primary_Partner__c != partnerName );
//depreciated					}
//depreciated					if(changed)
//depreciated					{
//depreciated						opp.FinancialPartner__c = partnerId;
//depreciated						opp.Primary_Partner__c = partnerName;
//depreciated						updateOpportunityMap.put(opp.Id,opp);
//depreciated					}
//depreciated				}
//depreciated			}
//depreciated		}
//depreciated		if(! updateOpportunityMap.isEmpty())
//depreciated		{
//depreciated			List<Opportunity> updateList = updateOpportunityMap.values().clone();
//depreciated			for(Database.SaveResult r : Database.update(updateList,false))
//depreciated			{
//depreciated				Opportunity o = updateList.remove(0);
//depreciated				for(Database.Error e : r.getErrors())
//depreciated				{
//depreciated					OpportunityPartner__c op = financialPartnerMap.get(o.Id);
//depreciated					if(op != null)
//depreciated					{
//depreciated						op.addError('Failed to update Opportunity: '+ e.getMessage());
//depreciated					}
//depreciated					op = resellerPartnerMap.get(o.Id);
//depreciated					if(op != null)
//depreciated					{
//depreciated						op.addError('Failed to update Opportunity: '+ e.getMessage());
//depreciated					}
//depreciated				}
//depreciated			}
//depreciated		}
//depreciated	}
}