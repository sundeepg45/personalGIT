trigger AfterUpdateAccount on Account (after update) 
{
    if(BooleanSetting__c.getInstance('DeactivateAll') != null && BooleanSetting__c.getInstance('DeactivateAll').Value__c == true) return;
    new AccountRecordTypeOnContract().populateAccRecordType();
}