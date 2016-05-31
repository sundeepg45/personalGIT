trigger LeadRouting on Lead (before insert,before update)
{
    if(Trigger.isBefore)
    {
        boolean isupdate=Trigger.isUpdate;
        new LeadAssignment().assignLead(Trigger.new,isupdate);
    }
}