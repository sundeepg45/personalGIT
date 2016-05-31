/*****************************************************************************************
    Name    : Address_Trigger_Handler
    Desc    : This class will act as helper class for Address trigger to process different business logic related to address.
              1.) Invoke the method provided by RH Team to process address domain object.
              2.) If a identifying address record created/update under one sales account which has already one identifying address , then set this identifying address as false on
                  previous identifying address record


Modification Log :
---------------------------------------------------------------------------
    Developer       Date                Description
---------------------------------------------------------------------------
    Vipul Jain      23 JULY 2014        Created
    Vipul Jain      28 JULY 2014        Changed the outbound message to send second address creation inside account structure.
    Scott Coleman   06 JULY 2015        US66997 - suppress publishing of outbound messages for inactive parties
    Scott Coleman   13 Aug 2015         Suppressing publishing of test records per US71693
    Bill C Riemers  26 Aug 2015         Ignore inactive addresses when setting the identifying address
    Bill C Riemers  27 Aug 2015         Query MasterRecord__r.Status__c and exclude duplicates
    J Garrison      29 Sep 2015         Suppressed the outbound message in the case where the sales
                                        account is flagged accordingly, per US73888 [RH-00431792].
    J Garrison      15 Oct 2015         Backed out changes from 29-Sep-2015 to fix issue with SFA push to Stage.
    Bill C Riemers  10 Nov 2015         Ignore Merged addresses
    Bill C Riemers  12 November 2015    Depreciated - Refactored into the Address_After class
******************************************************************************************/

@IsTest // marked as test because this is a depreciated class
private class Address_Trigger_Handler {}
//depreciated public with sharing class Address_Trigger_Handler {

//depreciated    public static void Address_Outbound_Message(map<Id,Address__c> newmap,map<Id,Address__c> oldmap){

//depreciated        //iterating through all the address records created. added CDH_Party_Name__r.Active__c to query for US66997
//depreciated        for(Address__c address: [Select id, name ,Zip_Postal_Code__c ,MasterRecord__r.Status__c,Status__c,Address_Line1__c,Address_Line2__c,
//depreciated                                    Address_Line3__c,Address_Line4__c,Bill_To_Address__c,CDH_Party_Site_Number__c,
//depreciated                                    City__c,Country__c,County__c,Entitle_To_Address__c,Identifying_Address__c,
//depreciated                                    Province__c,Sales_Account__c,Ship_To_Address__c,Sold_To_Address__c,
//depreciated                                    State__c,Sales_Account__r.Id,Sales_Account__r.CDH_Party_Name__r.Active__c,
//depreciated                                    Sales_Account__r.CDH_Party_Name__r.Name,Sales_Account__r.Count_Of_Identifying_Address__c,
//depreciated                                    Do_Not_Publish_To_Bus__c, Do_Not_Publish_To_Bus_Account__c
//depreciated                                    from Address__c where Id IN:newmap.keyset() and MasterRecord__c = null and Status__c != 'Merged' ]) {

//depreciated            // The BLOCK_MESSAGE variable is used to prevent the creation of a
//depreciated            // duplicate sales account during manual onboarding. This addresses
//depreciated            // US73888 [RH-00431792].
//depreciated            // if (OnboardingUtils.BLOCK_MESSAGE != null) {
//depreciated            //     OnboardingUtils.BLOCK_MESSAGE = (OnboardingUtils.BLOCK_MESSAGE == '1' ? '2' : null);
//depreciated            // } else {
//depreciated                /*  1.)check if sales account has only one identifying address (already) and new address is also identifying address , in this scenario address message will be sent to the
//depreciated                      outbound service method     OR
//depreciated                    2.) If identfying address = false , send this information to outbound service method.*/

//depreciated                // US66997
//depreciated                if((address.Sales_Account__r.CDH_Party_Name__r == null || address.Sales_Account__r.CDH_Party_Name__r.Active__c) &&
//depreciated                    ((address.Sales_Account__r.Count_Of_Identifying_Address__c == 1 && address.Identifying_Address__c == True)  || (address.Identifying_Address__c == False))){

//depreciated                    // US71693
//depreciated                    OutboundService.DoNotPublish = (OutboundService.DoNotPublish || address.Do_Not_Publish_To_Bus__c || address.Do_Not_Publish_To_Bus_Account__c);

//depreciated                    // creating the instance of sales account integration object.
//depreciated                    IntegrationObjects.SalesAccount ioAccount = new IntegrationObjects.SalesAccount();

//depreciated                    // set the id of account record.
//depreciated                    ioAccount.IDs = address.Sales_Account__r.Id;

//depreciated                    // setting the CDH Party number value
//depreciated                    if(address.Sales_Account__r.CDH_Party_Name__r != Null){
//depreciated                        ioAccount.CDH_Party_Number = address.Sales_Account__r.CDH_Party_Name__r.Name;
//depreciated                    }
//depreciated                    // create the instance of address integration object.
//depreciated                    IntegrationObjects.Address  ioAddress = new IntegrationObjects.Address();

//depreciated                    // invoke the converter method for address record
//depreciated                    ioAddress = IntegrationObjectConverter.convertAddress(address);

//depreciated                    // CDH Party# is the CDH Party# of sales account associated to address record , this is not set in the integration object converter method
//depreciated                    //ioAddress.CDH_Party_Number = address.Sales_Account__r.CDH_Party_Name__r.Name;

//depreciated                    // creating the list of address domain object and put the address domain object created above.
//depreciated                    List<IntegrationObjects.Address> ioAddressList = new List<IntegrationObjects.Address>();
//depreciated                    ioAddressList.add(ioAddress);

//depreciated                    // set the list of address for sales account domain object.
//depreciated                    ioAccount.Addresses = ioAddressList;
//depreciated                    system.debug('Create event is send outbound message-->'+ioAccount);

//depreciated                    // invoke the outbound service method to process address message.
//depreciated                    OutboundService.queueAccountMessage(ioAccount,'Create');
//depreciated                }
//depreciated            // }
//depreciated        }
//depreciated    }

//depreciated    public static void SetIdentifyingAddress( Map<id,Address__c> mapOfAddressRecords){
//depreciated        // set to hold the account id`s associated with the identifying address.
//depreciated        Set<id> accountIdset = new Set<Id>();

//depreciated        // iterating on the address records (being created/updated)
//depreciated        for(Address__c address : mapOfAddressRecords.values()){

//depreciated            // add id of sales account in set , if address is marked as identfying address
//depreciated            if(address.Identifying_Address__c == true && address.MasterRecord__c == null && address.Status__c != 'Merged') {
//depreciated                accountIdset.add(address.Sales_Account__c);
//depreciated            }
//depreciated        }

//depreciated        // list to hold address records to be updated
//depreciated        List<Address__c> addressList = new List<Address__c>();

//depreciated        // iterating all those address which are already indetfying address , set thier identfying address check box as false
//depreciated        for(Address__c address: [select id,Identifying_Address__c from Address__c where Sales_Account__c in :accountIdset and
//depreciated                                    Identifying_Address__c = true and id not in :mapOfAddressRecords.keyset()]){

//depreciated            // set  previous identifying address as false.
//depreciated            address.Identifying_Address__c = false;

//depreciated            // add address record into one list
//depreciated            addressList.add(address);
//depreciated        }

//depreciated        // update the address list.
//depreciated        update addressList;
//depreciated    }
//depreciated }