@IsTest(SeeAllData=true) // this is required to access Custom settings.
private class AccountSearchBeforeCreateController_Test{

public testMethod static void testAccountSearch()
{
  //create an account
  Account acct=new Account();
  acct.Name='Test';
  acct.BillingCountry='India';
  insert acct;
  
  //code coverage for extensions
  ApexPages.StandardController sc = new ApexPages.StandardController(acct);
 
  AccountSearchBeforeCreateController acctSearch=new AccountSearchBeforeCreateController(sc);
  
  
  acctSearch.selectedSearchOption='1';
  acctSearch.searchTypeSelection();
  acctSearch.selectedSearchOption='2';
  acctSearch.searchTypeSelection();
  acctSearch.selectedSearchOption='3';
  acctSearch.searchTypeSelection();
  
  
  acctSearch.AccName='Test';
  acctSearch.PartyNo='12345';
  acctSearch.Street='1st road';
  acctSearch.city='New York';
  acctSearch.postalcode='890098';
  acctSearch.StrDUNSNumber='898977';
  acctSearch.Country='US';
  acctSearch.state='New York';
  acctSearch.AliasFlag= false;
  
  System.debug('AccName'+acctSearch.AccName);
  System.debug('PartyNo'+acctSearch.PartyNo);
  System.debug('Street'+acctSearch.Street);
  System.debug('city'+acctSearch.city);
  System.debug('postalcode'+acctSearch.postalcode);
  System.debug('StrDUNSNumber'+acctSearch.StrDUNSNumber);
  System.debug('Country'+acctSearch.Country);
  System.debug('state'+acctSearch.state);
  
  PageReference pageref = acctSearch.searchCDHParty();
  
  AccountSearchBeforeCreateController.searchResultsWrapper SRW=new AccountSearchBeforeCreateController.searchResultsWrapper();
  SRW.partyName = 'TEST TEST';
  SRW.partyNumber = '1171123';
  SRW.partyType = 'PERSON';
  SRW.IdentifyingAddress = 'jhdsfjh, Hyderabad, IN, 5000012';
  SRW.phone='-9898989898';
    
  acctSearch.searchResultsWrapperMap= new Map<Integer,AccountSearchBeforeCreateController.searchResultsWrapper>();
    
  acctSearch.searchResultsWrapperMap.put(0,SRW);
  
  ApexPages.currentPage().getParameters().put('countryName','US');
   
  Apexpages.currentpage().getParameters().put('selectedCDHAccount','0');
   
  Apexpages.currentpage().getParameters().put('recordTypeId','012300000000QglAAE');
  
  
   
    
  acctSearch.getAllStates();
    
  acctSearch.redirectAccountUrl();
  
  //Test data to cover AccountWrapper 
 Account accObj1=new Account ();
 accObj1.Name='newAccount1';
 insert accObj1;
 
 Account accObj2=new Account ();
 accObj2.Name='newAccount2';
 insert accObj2;
 String testquery=accObj1.id+','+accObj2.id;
 system.debug(testquery);
 
 
  String test=AccountSearchBeforeCreateController.showAccounts(testquery);
   List<String> testId1Split = testquery.split(','); 
   system.debug(testId1Split);
   
   
  List<Account> a= new List<Account>();
  a= [select id, Name, Owner.Name,Owner.Email,CDH_Party_Name__c,CDH_Party_Name__r.Name,Identifying_Address__c,
       BillingCity,BillingCountry,BillingLatitude,BillingLongitude,BillingPostalCode,BillingState,BillingStreet,RecordType.Name 
                from Account where Id in :testId1Split];
  


}
public testMethod static void newTestAccountSearch()
{
    Account acct1=new Account();
  acct1.Name='Test';
  acct1.BillingCountry='India';
  insert acct1;
  
 
  ApexPages.StandardController sc = new ApexPages.StandardController(acct1);
     List<AccountSearchBeforeCreateController.recordTypeWrapper>rTW =new List<AccountSearchBeforeCreateController.recordTypeWrapper>();
      rTW = new AccountSearchBeforeCreateController(sc).GetAvailableRecordTypeNamesForSObject(Account.SObjectType);
     // List<AccountSearchBeforeCreateController.recordTypeWrapper>recordTypeWrapperList =new List<AccountSearchBeforeCreateController.recordTypeWrapper>();
      new AccountSearchBeforeCreateController(sc).AliasFlag= true;
       new AccountSearchBeforeCreateController(sc).AccName='Test';
      
}



 
}