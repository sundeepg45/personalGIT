trigger KJSE_UpdateAccount on Key_Joint_Sales_Engagement__c (before insert) {
    for(Key_Joint_Sales_Engagement__c kjse : Trigger.new) {
        // @todo Refactor later when resource limits are hit.
        kjse.Account_Name__c = [
            select Partner_Name__c
              from SFDC_Channel_Account_Plan__c 
             where Id = :kjse.Channel_Plan__c
        ].Partner_Name__c;
    }
}