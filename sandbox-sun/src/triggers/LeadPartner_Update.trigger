trigger LeadPartner_Update on Lead (before insert, before update)
{
    new LeadPartnerUpdate().updateLeadPartnerWorked(Trigger.new);
}