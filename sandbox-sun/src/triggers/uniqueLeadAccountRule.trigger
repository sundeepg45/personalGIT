trigger uniqueLeadAccountRule on LeadAccountRules__c (before insert,before update) 
{
    new LeadAccountRules().setUniqueIdentifier(Trigger.new);
}