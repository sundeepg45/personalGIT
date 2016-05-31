trigger Opportunity_UpdateValueSellingCycle on Opportunity (before insert) {
    if(BooleanSetting__c.getInstance('DeactivateAll') != null && BooleanSetting__c.getInstance('DeactivateAll').Value__c == true) return;
    /** Days for sales cycle */
    final Integer MIN_DAYS_FOR_12_MONTHS_CYCLE = (9 * 30) + 15;
    final Integer MIN_DAYS_FOR_09_MONTHS_CYCLE = (8 * 30) + 15;
    final Integer MIN_DAYS_FOR_08_MONTHS_CYCLE = (6 * 30) + 15;
    final Integer MIN_DAYS_FOR_06_MONTHS_CYCLE = (4 * 30) + 15;
    final Integer MIN_DAYS_FOR_04_MONTHS_CYCLE = (3 * 30) + 15;
    final Integer MIN_DAYS_FOR_03_MONTHS_CYCLE = (2 * 30) + 15;

    // Loop the opportunities
    for (Opportunity opportunity : Trigger.new) {
        Integer daysBetween = Date.today ().daysBetween (opportunity.CloseDate);

        if (daysBetween >= MIN_DAYS_FOR_12_MONTHS_CYCLE)
            opportunity.Value_Selling_Cycle__c = '12 Months';
        else if (daysBetween >= MIN_DAYS_FOR_09_MONTHS_CYCLE)
            opportunity.Value_Selling_Cycle__c = '09 Months';
        else if (daysBetween >= MIN_DAYS_FOR_08_MONTHS_CYCLE)
            opportunity.Value_Selling_Cycle__c = '08 Months';
        else if (daysBetween >= MIN_DAYS_FOR_06_MONTHS_CYCLE)
            opportunity.Value_Selling_Cycle__c = '06 Months';
        else if (daysBetween >= MIN_DAYS_FOR_04_MONTHS_CYCLE)
            opportunity.Value_Selling_Cycle__c = '04 Months';
        else if (daysBetween >= MIN_DAYS_FOR_03_MONTHS_CYCLE)
            opportunity.Value_Selling_Cycle__c = '03 Months';
        else 
            opportunity.Value_Selling_Cycle__c = 'Immediate';
    }
}