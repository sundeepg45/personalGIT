public class UpdateAccouneMdf_T_C {

    Account objAccount;
    Account objOldAccount;
    List<String> accountIds = new List<String>();
    List<SFDC_Budget__c> mdfList = new List<SFDC_Budget__c>();
    List<SFDC_Budget__c> updateMdfList= new List<SFDC_Budget__c>();
    Map<String,Boolean> accountFlagMap =  new Map<String,Boolean>();

    public void updateMdfRecordForTandC() {

        /** Description:List of Account ids for which Legal Ts and Cs is false */
        for (Integer i=0;i<Trigger.new.size();i++) {
        	objAccount = (Account) Trigger.new[i];
            if (Trigger.isUpdate) {
                objOldAccount = (Account)Trigger.old[i];
                
				if(objAccount.I_Agree_to_the_Terms_and_Conditions__c != objOldAccount.I_Agree_to_the_Terms_and_Conditions__c)
				{
				    accountFlagMap.put(''+objAccount.Id, objAccount.I_Agree_to_the_Terms_and_Conditions__c);
				    accountIds.add(objAccount.Id);
				}
            }

            if(Trigger.isInsert) {
                accountFlagMap.put(''+objAccount.Id, objAccount.I_Agree_to_the_Terms_and_Conditions__c);
                accountIds.add(objAccount.Id);
            }
        }

        if (!accountIds.isEmpty()) {
            mdfList = getMdfForAccount(accountIds);
            if(mdfList != null) {
                for(SFDC_Budget__c objBudget:mdfList) {
                    objBudget.Change_Record_Type_to_MDF__c = accountFlagMap.get(objBudget.Account_master__c);
                    objBudget.I_Agree_to_the_Terms_and_Conditions__c = accountFlagMap.get(objBudget.Account_master__c);
                    updateMdfList.add(objBudget);
                }
                update updateMdfList;
            }
        }
    }

    public List<SFDC_Budget__c> getMdfForAccount(List<String> accIdList)
    {
        List<SFDC_Budget__c> mdfList_loc = new List<SFDC_Budget__c>();
        mdfList_loc =  [Select Id,Account_master__c from SFDC_Budget__c where Account_master__c in :accIdList];
        return mdfList_loc;
    }

    public static testMethod void deployUpdateAccouneMdf_T_C() {
        Account testAcc=new Account();
        testAcc.Name='testAcc';
        testAcc.isAccountActive__c=true;
        testAcc.I_Agree_to_the_Terms_and_Conditions__c=true;
        testAcc.CurrencyIsoCode='USD';
        insert testAcc;
        
        RecordType objRecordType=[Select Id from RecordType where Name='MDF' and  SobjectType='SFDC_Budget__c'];    
        
        List<Account> accList=new List<Account>();
        accList.add(testAcc);
                        
        SFDC_Budget__c testBud=new SFDC_Budget__c();
        testBud.Name='testUpdateAccouneMdf';
        testBud.Account_master__c=testAcc.Id;
        testBud.RecordtypeId=objRecordType.Id;
        testBud.Allocated_Budget__c = 100;
        testBud.Select_Fiscal_Year__c = 'Current Fiscal Year';
        testBud.Fiscal_Quarter__c = 'Q3';
        testBud.Start_Date__c = Date.newInstance(2009, 9, 1);
        testBud.End_Date__c = Date.newInstance(2009, 11, 30);
        insert testBud;

        UpdateAccouneMdf_T_C objUpdateAccouneMdf= new UpdateAccouneMdf_T_C();
                        
        List<String> accids=new List<String>();
        for(integer i=0;i<accList.size();i++)
         {
            accids.add(accList.get(i).Id);
         }

        objUpdateAccouneMdf.getMdfForAccount(accids);
     }
    
}