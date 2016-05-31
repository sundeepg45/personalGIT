public with sharing class PartnerRegistrationUtil {

    static Id naSalesRT = RecordTypeLookup.getRecordTypeId('NA Sales Opportunity','Opportunity');
    static Id emeaSalesRT = RecordTypeLookup.getRecordTypeId('EMEA Sales Opportunity','Opportunity');
    static Id latamSalesRT  = RecordTypeLookup.getRecordTypeId('LATAM Sales Opportunity','Opportunity');
    static Id apacSalesRT = RecordTypeLookup.getRecordTypeId('APAC Sales Opportunity','Opportunity');
    final static String logTag = '[PartnerRegistrationUtil]';
    

	@future
    public static void enableAutoApproval(ID[] idlist) {
		Partner_Registration__c[] reglist = new List<Partner_Registration__c>();
		for (ID regid : idlist) {
			reglist.add(new Partner_Registration__c(ID = regid, Enable_Autoapproval__c = True));
		}    	
		if (!reglist.isEmpty()) {
			update reglist;
		}
    }
    
    public class ParException extends Exception {}
   
    //@future
    public static void createOppFromPartnerReg(Set<String> partnerRegIdSet){
        if(partnerRegIdSet.isEmpty()) return;
        List<Opportunity> newOpps = new List<Opportunity>();
        Map<Id,Opportunity> regOppMap = new Map<Id,Opportunity>();
        //Map<Id,Opportunity> partnerOppMap = new Map<Id, Opportunity>();
        Map<Id, Partner_Registration__c> regMap = new Map<Id, Partner_Registration__c>();
            
        for(Partner_Registration__c pr:[select Company_Street_1__c, Company_City__c, Company_State__c, Company_Postal_Code__c, Company_Country__c, CreatedById, End_Customer__r.Name, End_Customer__r.OwnerId, Estimated_Close_Date__c, Id, Name, Partner__r.Global_Region__c, Partner__c, Product_Family__c, Project_Budget__c from Partner_Registration__c where Id IN :partnerRegIdSet]){
            String partnerRegion = pr.Partner__r.Global_Region__c;
            regMap.put(pr.Id, pr);   
            
            Id oppOwnerId = pr.End_Customer__r.OwnerId;
            if(oppOwnerId == null)
              oppOwnerId = UserInfo.getUserId();
            
            Opportunity opp = new Opportunity(
                AccountId = pr.End_Customer__c, 
                Amount = pr.Project_Budget__c,
                Is_PAR__c = true,
                ShippingAddress__c = pr.Company_Street_1__c,
                ShippingCity__c = pr.Company_City__c,
                ShippingState__c = pr.Company_State__c,
                ShippingZipPostalCode__c = pr.Company_Postal_Code__c,
                ShippingCountry__c = pr.Company_Country__c, 
                CloseDate = pr.Estimated_Close_Date__c,
                Name = pr.End_Customer__r.Name + ' - ' + pr.Product_Family__c,
                OwnerId = pr.End_Customer__r.OwnerId,
                RecordTypeId = getOppRecordType(partnerRegion),
                StageName = 'Prepare'               
            );
            newOpps.add(opp);
            regOppMap.put(pr.Id, opp);
        }
        
        insert(newOpps);
        associateOppsWithRegistrations(regOppMap);
        addOppTeamMembers(regOppMap, regMap);
        
        
    }
    
    
    private static void associateOppsWithRegistrations(Map<Id,Opportunity> regOppMap){
        // Find the Partner Registrations who now have valid Opportunities so we can link the two objects
        List<Partner_Registration__c> regUpdateList = new List<Partner_Registration__c>();
        for(Id regId : regOppMap.keySet()){
            Opportunity newOpp = regOppMap.get(regId);
            if(newOpp.Id != null){  
                regUpdateList.add( new Partner_Registration__c(Id = regId, Opportunity__c = newOpp.Id) );
            }
        }
            
        system.debug(logTag + 'Updating [' + regUpdateList.size() + '] Partner Registrations with new Opportunity relationships');
        upsert(regUpdateList);        
    }
    
    
    private static void addOppTeamMembers(Map<Id,Opportunity> regOppMap, Map<Id, Partner_Registration__c> regMap){
        
        List<OpportunityTeamMember> oppTeamMembers = new List<OpportunityTeamMember>();
        for(Id regId : regOppMap.keySet()){
            Opportunity newOpp = regOppMap.get(regId);
            // Add the Partner to the Opportunity Team so they can view the opportunity
            OpportunityTeamMember otm = new OpportunityTeamMember(
                 OpportunityId = newOpp.Id,
                 UserId = regMap.get(regId).CreatedById,
                 TeamMemberRole = 'Partner'//,
            );  
            oppTeamMembers.add(otm);
        }
        insert(oppTeamMembers);
    }
    
    
    private static Id getOppRecordType(string region){
        if(region == null) return null;
        
        if(region.equalsIgnoreCase('NA')){
            return naSalesRT;
        } else if (region.equalsIgnoreCase('EMEA')){
            return emeaSalesRT;
        } else if (region.equalsIgnoreCase('LATAM')){
            return latamSalesRT;
        } else if (region.equalsIgnoreCase('APAC')){
            return apacSalesRT;
        } else {
            system.debug('Undefiined Region for Opportunty Record Type lookup: [' + region + ']!');
            return null;
        }
    }
    
    
    public static void setEndCustomerManager(List<Partner_Registration__c> newRegList, Map<Id, Partner_Registration__c> oldMap){
        
        Map<Id, Id> regAcctMap = new Map<Id, Id>();
        List<Partner_Registration__c> processList = new List<Partner_Registration__c>(); 
            
        // Find any registrations whose End Customer field has just been set
        for(Partner_Registration__c newReg:newRegList){
            Partner_Registration__c oldReg = oldMap.get(newReg.Id);
            if(newReg.End_Customer__c != null && (newReg.End_Customer__c != oldReg.End_Customer__c)){
                system.debug(logTag + 'Registration End Customer has just been set, adding to process list so we can set the End Customer Account Manager for this registration.');
                regAcctMap.put(newReg.Id, newReg.End_Customer__c);
                processList.add(newReg);
            }
        }
        
        // Look up all the accounts we'll need to update registrations with
        Map<Id,Account> acctMap = new Map<Id,Account>( [select Id, OwnerId, Name from Account where Id IN :regAcctMap.values()]);
        
        
        // Set the Registration's "End Customer Manager" field and share the Registration record with that internal user
        for(Partner_Registration__c pr:processList){
            Account acct = acctMap.get(pr.End_Customer__c);
            pr.End_Customer_Manager__c = acct.OwnerId;
            system.debug(logTag + 'Set End Customer Manager to [' + acct.OwnerId + '] for Registration [' + pr.Id + ']');
        }
        
    }
    
}