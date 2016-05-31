/*
 *  @version 2013-12-3
 *  @author Shawn Cureton <scureton@redhat.com>
 *
 *
 * Trigger to prevent users from updating the Deal Registration field on Opportunity
 * after the record is created.  Only Admin level 1 and 2 can override.
*/

trigger Opportunity_BeforeUpdate on Opportunity (before update) {
    /* movied to Opportunity_DealRegCheck.trigger as it is more efficient

    if(BooleanSetting__c.getInstance('DeactivateAll') != null && BooleanSetting__c.getInstance('DeactivateAll').Value__c == true) return;
    if(BooleanSetting__c.getInstance('Opp_Before.DealReg') != null && BooleanSetting__c.getInstance('Opp_Before.DealReg').Value__c == false) return;

    // Query the user's profile to check for admin status
    String usrProfileName = [select u.Profile.Name from User u where u.id = :Userinfo.getUserId()].Profile.Name;
    system.debug('***DEBUG***  user profile name:' + usrProfileName);
    if(usrProfileName == 'Administrator - Level 1' || usrProfileName == 'Administrator - Level 2' || usrProfileName == 'Administrator - Operations')return;



    // Iterate through triggering Opportunities and check for change in status of
    // Deal Registration or Deal Registration fed/sled checkbox.
    list<Opportunity> opps = new list<Opportunity>();
    for(Opportunity o: trigger.new){
        if(trigger.oldmap.get(o.id).Deal_Registration__c != o.Deal_Registration__c || trigger.oldmap.get(o.id).Deal_Registration_Fed_Sled__c != o.Deal_Registration_Fed_Sled__c){
            opps.add(o);
        }
    }
    if(opps.size()==0)return;

    // Stop the update and give error message if the field has been changed.
    for(Opportunity o: opps){
        o.addError('The Deal Registration or Deal Registration Fed/Sled flag can only be changed by IT department after an Opportunity is created.');
    }
    */
}