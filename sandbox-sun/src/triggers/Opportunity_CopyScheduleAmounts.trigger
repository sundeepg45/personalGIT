/**
 * Opportunity_CopyScheduleAmounts
 *
 * @see Opportunity
 * @version 1.0
 * @author Ian Zepp <izepp@redhat.com>
 */
trigger Opportunity_CopyScheduleAmounts on Opportunity (before insert, before update) {
    if(BooleanSetting__c.getInstance('DeactivateAll') != null && BooleanSetting__c.getInstance('DeactivateAll').Value__c == true) return;
    //
    // The roll-up fields automatically sum our opportunity products. All that needs
    // to be done is to copy over the values to the legacy fields.
    //
    for (Opportunity opportunity : Trigger.new) {
        opportunity.Year1Amount__c = opportunity.Year1AmountAuto__c;
        opportunity.Year2Amount__c = opportunity.Year2AmountAuto__c;
        opportunity.Year3Amount__c = opportunity.Year3AmountAuto__c;
        opportunity.Year4Amount__c = opportunity.Year4AmountAuto__c;
        opportunity.Year5Amount__c = opportunity.Year5AmountAuto__c;
        opportunity.Year6Amount__c = opportunity.Year6AmountAuto__c;
    }
}