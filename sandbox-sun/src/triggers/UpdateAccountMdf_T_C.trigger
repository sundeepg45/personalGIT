/*
* File Name:UpdateAccountMdf_T_C
* Date Implemented: 2/25/09
* Project: Routes To Market
* Description:This Trigger used to call an apex class "UpdateAccountMDF_T_C" and .The class will check for the "I_Agree_to_the_Terms_and_Conditions__c" flag on Account.
* If the flag is false,then it will update the "I_Agree_to_the_Terms_and_Conditions__c" flag of all Budgets associated to that account with False.
*/
trigger UpdateAccountMdf_T_C on Account (after insert, after update)
{
    if(BooleanSetting__c.getInstance('DeactivateAll') != null && BooleanSetting__c.getInstance('DeactivateAll').Value__c == true) return;
    new UpdateAccouneMdf_T_C().updateMdfRecordForTandC();
}