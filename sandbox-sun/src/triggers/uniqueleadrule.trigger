trigger uniqueleadrule on LeadRules__c (before insert,before update)
{
    new LeadRules().setUniqueLeadRule(Trigger.new);
}