trigger OpportunityPartner_Legacy on OpportunityPartner__c (before insert,before update,after delete) {
//depreciated	List<OpportunityPartner__c> needLegacy = new List<OpportunityPartner__c>();
//depreciated	Set<Id> opportunityIds = new Set<Id>();
//depreciated	Map<Id,OpportunityPartner__c> oldLegacyIdMap = new Map<Id,OpportunityPartner__c>();
//depreciated	if(! Trigger.isInsert)
//depreciated	{
//depreciated		for(OpportunityPartner__c op : Trigger.old)
//depreciated		{
//depreciated			opportunityIds.add(op.Opportunity__c);
//depreciated			oldLegacyIdMap.put(op.Legacy_PartnerId__c,op);
//depreciated		}
//depreciated		oldLegacyIdMap.remove(null);
//depreciated	}
//depreciated	Set<Id> newLegacyIds = new Set<Id>();
//depreciated	if(! Trigger.isDelete)
//depreciated	{
//depreciated		for(OpportunityPartner__c op : Trigger.new)
//depreciated		{
//depreciated			if(op.Partner__c == null)
//depreciated			{
//depreciated				op.addError('Partner is required.');
//depreciated				continue;
//depreciated			}
//depreciated			opportunityIds.add(op.Opportunity__c);
//depreciated			if(Trigger.isUpdate)
//depreciated			{
//depreciated				OpportunityPartner__c o = Trigger.oldMap.get(op.Id);
//depreciated				if(op.Legacy_PartnerId__c == o.Legacy_PartnerId__c)
//depreciated				{
//depreciated					if(op.Partner__c != o.Partner__c || op.PartnerType__c != o.PartnerType__c || op.PartnerTier__c != o.PartnerTier__c)
//depreciated					{
//depreciated						op.Legacy_PartnerId__c = null;
//depreciated					}
//depreciated				}
//depreciated			}
//depreciated			String id = null;
//depreciated			newLegacyIds.add((id=op.Legacy_PartnerId__c));
//depreciated			if(id == null && op.RelationshipType__c != null)
//depreciated			{
//depreciated				needLegacy.add(op);
//depreciated			}
//depreciated		}
//depreciated		oldLegacyIdMap.keySet().removeAll(newLegacyIds);
//depreciated	}
//depreciated	opportunityIds.remove(null);
//depreciated	List<Partner> partners = new List<Partner>();
//depreciated	List<OpportunityPartner__c> ops = new List<OpportunityPartner__c>();
//depreciated	// find and clean-up orphaned legacy opportunity partner records.
//depreciated	List<Id> partnerIdsToRemove = new List<Id>(oldLegacyIdMap.keySet());
//depreciated	if(Trigger.isInsert && ! opportunityIds.isEmpty())
//depreciated	{
//depreciated		// It seems that adding one partner record automatically adds a reverse partner record.
//depreciated		// Removing the reverse partner, also removes the partner record we added.   So there 
//depreciated		// is no way to simply remove any partners we did not add.
//depreciated		// Instead we simply look for opportunity Id's for which we have not added any partners.
//depreciated		System.debug('Opportunity Ids to scan = '+opportunityIds);
//depreciated		for(AggregateResult ar : [select Opportunity__c from OpportunityPartner__c where Opportunity__c in : opportunityIds and Legacy_PartnerId__c != null Group By Opportunity__c Having Count(Id) > 0 ])
//depreciated		{
//depreciated			// We have added one or more partners to this opportunity, so remove it from the list.
//depreciated			opportunityIds.remove((Id)ar.get('Opportunity__c'));
//depreciated		}
//depreciated		System.debug('Opportunity Ids to clean = '+opportunityIds);
//depreciated		// add any Partners associated to these opportunities to our remove list.
//depreciated		partnerIdsToRemove.addAll(new Map<Id,Partner>([select Id from Partner where OpportunityId in :opportunityIds]).keySet());
//depreciated	}
//depreciated	// clean-up old partner records
//depreciated	System.debug('Partners to remove='+partnerIdsToRemove);
//depreciated	if(! partnerIdsToRemove.isEmpty())
//depreciated	{
//depreciated		for(Database.DeleteResult r : database.delete(partnerIdsToRemove,false))
//depreciated		{
//depreciated			Id legacyId = partnerIdsToRemove.remove(0);
//depreciated			OpportunityPartner__c op = oldLegacyIdMap.get(legacyId);
//depreciated			for(Database.Error e : r.getErrors()) {
//depreciated				String m = e.getMessage();
//depreciated				System.debug('legacyId='+legacyId+',error='+m);
//depreciated				if(op != null)
//depreciated				{
//depreciated					if(! m.contains('invalid cross reference'))
//depreciated					{
//depreciated						op.addError(e.getMessage());
//depreciated					}
//depreciated				}
//depreciated			}
//depreciated		}
//depreciated	}
//depreciated	// to do: add new legacy opportunity partner objects
//depreciated	if(! needLegacy.isEmpty())
//depreciated	{
//depreciated	   /*
//depreciated		Map<String,PartnerRole> partnerRoleMap = new Map<String,PartnerRole>{
//depreciated			'Distributor'=>new PartnerRole(MasterLabel='Distributor', Id='01J30000002EOlyEAG'),
//depreciated			'System Integrator'=>new PartnerRole(ReverseRole='Supplier', MasterLabel='System Integrator', Id='01J30000002EOm0EAG'),
//depreciated			'Value Added Reseller'=>new PartnerRole(ReverseRole='Vendor', MasterLabel='Value Added Reseller', Id='01J30000002EOm1EAG'),
//depreciated			'OEM'=>new PartnerRole(ReverseRole='Customer', MasterLabel='OEM', Id='01J300000038ZAOEA2'),
//depreciated			'Training'=>new PartnerRole(ReverseRole='Supplier', MasterLabel='Training', Id='01J300000038ZAsEAM'),
//depreciated			'Other'=>new PartnerRole(ReverseRole='Other', MasterLabel='Other', Id='01J300000038ZAxEAM'),
//depreciated			'Advanced Partner'=>new PartnerRole(ReverseRole='Customer', MasterLabel='Advanced Partner', Id='01J30000003dC4lEAE'),
//depreciated			'ISV'=>new PartnerRole(ReverseRole='Supplier', MasterLabel='ISV', Id='01J30000003dCeYEAU'),
//depreciated			'Technology'=>new PartnerRole(ReverseRole='Vendor', MasterLabel='Technology', Id='01J30000003dCemEAE'),
//depreciated			'Chip'=>new PartnerRole(ReverseRole='Supplier', MasterLabel='Chip', Id='01J60000007RvmnEAC')
//depreciated		};
//depreciated		*/
//depreciated		Map<String,String> partnerRoleNameMap = new Map<String,String>{
//depreciated			'Distributor'=>'Distributor',
//depreciated			'Global Chip'=>'Chip',
//depreciated			'ISP.Training'=>'Training',			
//depreciated			'ISP'=>'Other',
//depreciated			'ISV'=>'ISV',
//depreciated			'OEM'=>'OEM',
//depreciated			'Reseller:Advanced'=>'Advanced Partner',
//depreciated			'Reseller.'=>'Value Added Reseller',
//depreciated			'Reseller'=>'Other',
//depreciated			'SI'=>'System Integrator'};
//depreciated		for(OpportunityPartner__c op : needLegacy)
//depreciated		{
//depreciated			String roleName = 'Distributor';
//depreciated			if(! 'Financial'.equalsIgnoreCase(op.RelationshipType__c))
//depreciated			{
//depreciated				String subTypeName = op.PartnerSubTypeName__c;
//depreciated				if(subTypeName == null)
//depreciated				{
//depreciated					subTypeName = '';
//depreciated				}
//depreciated				roleName = partnerRoleNameMap.get(op.PartnerTypeName__c+'.'+subTypeName+':'+op.PartnerTierName__c);
//depreciated				if(roleName == null)
//depreciated				{
//depreciated					roleName = partnerRoleNameMap.get(op.PartnerTypeName__c+':'+op.PartnerTierName__c);
//depreciated					if(roleName == null)
//depreciated					{
//depreciated						roleName = partnerRoleNameMap.get(op.PartnerTypeName__c+'.'+subTypeName);
//depreciated						if(roleName == null)
//depreciated						{
//depreciated							roleName = partnerRoleNameMap.get(op.PartnerTypeName__c);
//depreciated							if(roleName == null)
//depreciated							{
//depreciated								roleName = 'Other';
//depreciated							}
//depreciated						}
//depreciated					}
//depreciated				}
//depreciated			}
//depreciated			if(roleName != null)
//depreciated			{
//depreciated				ops.add(op);
//depreciated				partners.add(new Partner(OpportunityId=op.Opportunity__c,AccountToId=op.Partner__c,Role=roleName));
//depreciated			}
//depreciated		}
//depreciated		if(! partners.isEmpty())
//depreciated		{
//depreciated			for(Database.SaveResult r : database.insert(partners,false))
//depreciated			{
//depreciated				Partner p = partners.remove(0);
//depreciated				OpportunityPartner__c op = ops.remove(0);
//depreciated				op.Legacy_PartnerId__c = p.Id;
//depreciated				if(! 'Financial'.equalsIgnoreCase(op.RelationshipType__c))
//depreciated				{
//depreciated					for(Database.Error e : r.getErrors())
//depreciated					{
//depreciated						String message = e.getMessage();
//depreciated						if(! message.startsWith('field integrity exception:'))
//depreciated						{
//depreciated							op.addError(e.getMessage());
//depreciated						}
//depreciated					}
//depreciated				}
//depreciated			}
//depreciated		}
//depreciated	}
}