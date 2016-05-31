/**
 * This class is acting as a handler class for the trigger RH_CDH_Inbound trigger on 
 * sales account object.This will create/update the records of account to the integrationObjects account structure and pass them as parameter in outBound service.
 * 
 * @version 2016-03-01							
 * @author Neha Jaiswal
 * @since 2014-06-10 -Created
 * @author Phaniraj N
 * @since 2014-07-14 - Address trigger event to fill Billing address and create a new Identifying address.
 * @author Bill C Riemers <briemers@redhat.com>
 * @since 2015-08-27 - Use MasterRecord__r.Status__c from the address when available and adjust sorting
 * @since 2015-11-10 - Corrected to exclude, not include merged addresses.  Use a Merged status.
 * 
 * @todo: This code should be depreciated.
 */
public with sharing class AccountTriggerHandler {
	/** 
	 * method below will create address for new created accounts, if Address is not present for any accouunt during the
	 * creation and if identifying address is present in the account, new address record will be created 
	 * @param accountList
	 */
	public static void CreateAddressForNewAccounts(List<Account> accountList) {
		Map<Id,Account> accountWithIdentifyingAddressMap = new Map<Id,Account>();
		for(Account accountRecord : accountList){
			if(accountRecord.Identifying_Address__c != null)
				accountWithIdentifyingAddressMap.put(accountRecord.Id,accountRecord);
		}
		
		List<Address__c> addressToBeInsertedList = new List<Address__c>();
		for(Id accountId : accountWithIdentifyingAddressMap.keyset()){			
			Address__c addressRecord = new Address__c();
			addressRecord.Address_Line1__c = accountWithIdentifyingAddressMap.get(accountId).Address_Line_1__c;
			addressRecord.Address_Line2__c = accountWithIdentifyingAddressMap.get(accountId).Address_Line_2__c;
			addressRecord.Address_Line3__c = accountWithIdentifyingAddressMap.get(accountId).Address_Line_3__c; 
			addressRecord.Address_Line4__c = accountWithIdentifyingAddressMap.get(accountId).Address_Line_4__c;
			addressRecord.City__c = accountWithIdentifyingAddressMap.get(accountId).City__c;
			addressRecord.County__c = accountWithIdentifyingAddressMap.get(accountId).County__c;
			addressRecord.State__c = accountWithIdentifyingAddressMap.get(accountId).State__c; 
			addressRecord.Province__c  = accountWithIdentifyingAddressMap.get(accountId).Province__c;
			addressRecord.Country__c = accountWithIdentifyingAddressMap.get(accountId).Country__c;
			addressRecord.Zip_Postal_Code__c = accountWithIdentifyingAddressMap.get(accountId).Zip_Postal_Code__c;	
			addressRecord.Sales_Account__c = accountId;
			addressRecord.Identifying_Address__c = true;
			addressRecord.Bill_To_Address__c = true;
			addressToBeInsertedList.add(addressRecord); 
		}
		
		if(addressToBeInsertedList.size() > 0){
			try{
				insert addressToBeInsertedList; 
			}catch(Exception e){
				ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Error occured in inserting address');
				ApexPages.addMessage(myMsg);
			}	
		}
	}
	

	/** 
	 * Below method will be invoked from trigger whenever a address record created/updated.
	 * Below logic will create a record in outbound staging table correspond to creation/update of address record in sfdc. 
	 */
	public static void OutboundStagingInsertion(list<Account> objCDHOutBoundRec, integer countOfIdentifyingAddress){
		try{
			system.debug('test^&^&^&^&^' +objCDHOutBoundRec[0].Count_Of_Identifying_Address__c+'count test here'+countOfIdentifyingAddress);
			//query of the account details being created/updated in salesforce.
			List<Account> listAccountDetailInsertedOrUpdated = new List<Account>();
			List<Address__c> listIdentifyingAddressInserted =new List<Address__c>();
			
			//querying list of account details whose id's are passed as a parameter in this method.
			listAccountDetailInsertedOrUpdated = [
				Select id, 
					Name,
					CDH_Party_Name__r.Name,
					VATNumber__c,
					D_U_N_S__c, Status__c,
					Sic,
					SicDesc,
					All_NAICS_Codes__c,
					Do_Not_Do_Business_with__c, 
					SEA_Concern__c,
					Tradestyle,
					YearStarted,
					NumberOfEmployees,
					AnnualRevenue,
					Website,
					Phone,
					Fax,
					Headquarters__c,
					Domestic_Ultimate__c,
					Global_Ultimate__c, 
					Linkedin_URL__c,
					CDHPartyNumber__c,
					Count_Of_Identifying_Address__c
				From Account
				where id IN : objCDHOutBoundRec 
				LIMIT 1 ];
			
			//identifying address will total be 1 in this scenario.
			listIdentifyingAddressInserted = [
				Select id, 
					name,
					Zip_Postal_Code__c,
					Status__c,
					MasterRecord__r.Status__c,
					Address_Line1__c,
					Address_Line2__c,
					Address_Line3__c,
					Address_Line4__c,
					Bill_To_Address__c,
					CDH_Party__c,
					CDH_Party_Site_Number__c,
					City__c,
					Country__c,
					County__c,
					Entitle_To_Address__c,
					Identifying_Address__c,
					Province__c,
					Sales_Account__c,
					Ship_To_Address__c,
					Sold_To_Address__c,
					State__c
				from Address__c
				where Sales_Account__c = :objCDHOutBoundRec and IsDuplicate__c != true and Status__c != 'Merged' and MasterRecord__c = null 
				order by
					MasterRecord__c asc nulls first,
					Status__c asc nulls first,
					Identifying_Address__c desc nulls last
				limit 1];
			
			system.debug('^^^^^^^^^^^^^^^^^^^^&&***********$$$$$******* of address if count is changed'+ countOfIdentifyingAddress+integer.valueOf(listAccountDetailInsertedOrUpdated[0].Count_Of_Identifying_Address__c));
		   
			//instantiating the outbound wrapper class for address  created as identifying address.Needs to be send along with sales account details.
			IntegrationObjects.Address  addressToBeSend = new IntegrationObjects.Address();
			
			//list of address to pass in the wrapper structure of sales account in integrationObjects class.
			list<IntegrationObjects.Address>  listAddressSend = new list<IntegrationObjects.Address>();
			 
			// preparing address attributes 
			  
			addressToBeSend.Ids = listIdentifyingAddressInserted[0].id ;
			addressToBeSend.CDH_Party_Site_Number = listIdentifyingAddressInserted[0].CDH_Party_Site_Number__c ;
			addressToBeSend.Address_Line1 = listIdentifyingAddressInserted[0].Address_Line1__c ;
			addressToBeSend.Address_Line2 = listIdentifyingAddressInserted[0].Address_Line2__c ;
			addressToBeSend.Address_Line3 = listIdentifyingAddressInserted[0].Address_Line3__c ;
			addressToBeSend.Address_Line4 = listIdentifyingAddressInserted[0].Address_Line4__c;
			addressToBeSend.City = listIdentifyingAddressInserted[0].City__c;
			addressToBeSend.State = listIdentifyingAddressInserted[0].State__c ;
			addressToBeSend.Province = listIdentifyingAddressInserted[0].Province__c ;
			addressToBeSend.Zip_Postal_Code = listIdentifyingAddressInserted[0].Zip_Postal_Code__c ;
			addressToBeSend.County = listIdentifyingAddressInserted[0].County__c;
			addressToBeSend.Country = listIdentifyingAddressInserted[0].Country__c ;
			addressToBeSend.Bill_To_Address = listIdentifyingAddressInserted[0].Bill_To_Address__c ;
			addressToBeSend.Sold_To_Address = listIdentifyingAddressInserted[0].Sold_To_Address__c ;
			addressToBeSend.Ship_To_Address = listIdentifyingAddressInserted[0].Ship_To_Address__c ;
			addressToBeSend.Entitle_To_Address = listIdentifyingAddressInserted[0].Entitle_To_Address__c;
			addressToBeSend.Identifying_Address = listIdentifyingAddressInserted[0].Identifying_Address__c;
			addressToBeSend.Status = listIdentifyingAddressInserted[0].Status__c;
			if(listIdentifyingAddressInserted[0].MasterRecord__r != null) {
				addressToBeSend.Status = listIdentifyingAddressInserted[0].MasterRecord__r.Status__c;
			}
			
			//adding the address wrapper details in the list.
			listAddressSend.add(addressToBeSend);
			
			//instantiating the outbound wrapper class for sales account created or updated.
			IntegrationObjects.SalesAccount salesAccountToBeSend = new IntegrationObjects.SalesAccount();
			
			if(listAccountDetailInsertedOrUpdated != Null && listAccountDetailInsertedOrUpdated.size()>0){
			
				//mapping the value of the list queried above to the wrapper variables.
				salesAccountToBeSend.IDs = listAccountDetailInsertedOrUpdated[0].id;  
				salesAccountToBeSend.Name = listAccountDetailInsertedOrUpdated[0].Name;
				salesAccountToBeSend.CDH_Party_Number = listAccountDetailInsertedOrUpdated[0].CDH_Party_Name__r.Name;
				//salesAccountToBeSend.Sales_Account_Type = listAccountDetailInsertedOrUpdated[0].Sales_Account_type__C;
				salesAccountToBeSend.YearStarted = listAccountDetailInsertedOrUpdated[0].YearStarted;
				salesAccountToBeSend.NumberOfEmployees = listAccountDetailInsertedOrUpdated[0].NumberOfEmployees;
				salesAccountToBeSend.AnnualRevenue = listAccountDetailInsertedOrUpdated[0].AnnualRevenue;
				salesAccountToBeSend.Website = listAccountDetailInsertedOrUpdated[0].Website;
				salesAccountToBeSend.Phone = listAccountDetailInsertedOrUpdated[0].Phone;
				salesAccountToBeSend.Fax = listAccountDetailInsertedOrUpdated[0].Fax;
				//salesAccountToBeSend.CDH_Party_Type = listAccountDetailInsertedOrUpdated[0].CDH_Party_Name__r;
				salesAccountToBeSend.VATNumber = listAccountDetailInsertedOrUpdated[0].VATNumber__c;
				salesAccountToBeSend.D_U_N_S = listAccountDetailInsertedOrUpdated[0].D_U_N_S__c;
				salesAccountToBeSend.Status = listAccountDetailInsertedOrUpdated[0].Status__c;
				salesAccountToBeSend.Sic = listAccountDetailInsertedOrUpdated[0].Sic;
				salesAccountToBeSend.SicDesc = listAccountDetailInsertedOrUpdated[0].SicDesc;
				salesAccountToBeSend.All_NAICS_Codes = listAccountDetailInsertedOrUpdated[0].All_NAICS_Codes__c;
				salesAccountToBeSend.Do_Not_Do_Business_with = listAccountDetailInsertedOrUpdated[0].Do_Not_Do_Business_with__c;
				salesAccountToBeSend.Trade_Style = listAccountDetailInsertedOrUpdated[0].Tradestyle;
				salesAccountToBeSend.SEA_Concern = listAccountDetailInsertedOrUpdated[0].SEA_Concern__c;
				salesAccountToBeSend.Head_Quarters = listAccountDetailInsertedOrUpdated[0].Headquarters__c;
				salesAccountToBeSend.Domestic_Ultimate = listAccountDetailInsertedOrUpdated[0].Domestic_Ultimate__c;
				salesAccountToBeSend.Global_Ultimate = listAccountDetailInsertedOrUpdated[0].Global_Ultimate__c;
				salesAccountToBeSend.Linkedin_URL = listAccountDetailInsertedOrUpdated[0].Linkedin_URL__c;
				
				system.debug('test new value of count'+ objCDHOutBoundRec[0].Count_Of_Identifying_Address__c);
				system.debug('test earlier value of count'+ listAccountDetailInsertedOrUpdated[0].Count_Of_Identifying_Address__c);
				system.debug('test list here&&&&************ of address if count is changed'+ countOfIdentifyingAddress+integer.valueOf(listAccountDetailInsertedOrUpdated[0].Count_Of_Identifying_Address__c));
				
				// checking if the address is an identifying address,if yes it will be send along with the sales account updated.
				// Condition is based to check if the count of identifying address of the related sales account is changed or is same to it's prior value.
				// If it's changed that means it is an identifying address and than will be send with sales account.
				// In the case if only sales account's field is updated , sales account will only be send with null address as address is already there in CDH and there is no change
				
				if(countOfIdentifyingAddress != integer.valueOf(listAccountDetailInsertedOrUpdated[0].Count_Of_Identifying_Address__c))
				{
					
					salesAccountToBeSend.Addresses = listAddressSend ;
					system.debug('test list here of address if count is changed'+ listAddressSend.size()+listAddressSend);
				}
				else
				{
					system.debug('test list here of address if count is not changed'+ countOfIdentifyingAddress+integer.valueOf(listAccountDetailInsertedOrUpdated[0].Count_Of_Identifying_Address__c));
				}
				
			}
			// Below code will invoke outbound service by passing the parameter to it's method.
			
			OutboundService.queueAccountMessage(salesAccountToBeSend,'UPDATE');  
			system.debug('test list here%%%%%%%%%%'+salesAccountToBeSend);  
		}
		catch(Exception e)
		{
			system.debug('exception occurred-->'+e.getmessage());
		}
	}

}