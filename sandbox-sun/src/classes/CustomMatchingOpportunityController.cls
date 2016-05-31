public with sharing class CustomMatchingOpportunityController {
 
      public List<Potential_Matched_Opportunities__c> results{get;set;} // search results
      public string searchString{get;set;} // search keyword
      public string searchOppStagingID{get;set;} // search Under Opp staging
     
      public CustomMatchingOpportunityController() {
         // get the current search string
         searchString = System.currentPageReference().getParameters().get('lksrch');
         searchOppStagingID = System.currentPageReference().getParameters().get('searchOppStagingID');
         runSearch();  
      }
     
      // performs the keyword search
      public PageReference search() {
        runSearch();
        return null;
      }
     
      // prepare the query and issue the search command
      private void runSearch() {
        // TODO prepare query string for complex serarches & prevent injections
        results = performSearch(searchString);               
      } 
     
      // run the search and return the records found. 
      private List<Potential_Matched_Opportunities__c> performSearch(String searchString) {
     
        /* String soql = 'select id, name from User';
         if(searchString != '' && searchString != null)
           soql = soql +  ' where name LIKE \'%' + searchString +'%\'';
         soql = soql + ' limit 25';
         System.debug(soql);*/
         //String soql = 'SELECT Id, Name from Potential_Matched_Opportunities__c WHERE Opportunity_Header_Staging__r.Name = \'' + searchString +'\'';        
         String soql = 'SELECT Id, Name,Opportunity__c,Opportunity_Name__c from Potential_Matched_Opportunities__c WHERE Opportunity_Header_Staging__c= \''+searchOppStagingID+'\''+' AND Opportunity_Name__c LIKE \'%'+searchString+ '%\'';
         soql = soql + ' LIMIT 25';
         return Database.query(soql); 
      }
     
      // used by the visualforce page to send the link to the right dom element
      public string getFormTag() {
        string str = System.currentPageReference().getParameters().get('frm');
        //system.debug('str======'+str);        
        return System.currentPageReference().getParameters().get('frm');
      }
     
      // used by the visualforce page to send the link to the right dom element for the text box
      public string getTextBox() {
        string str = System.currentPageReference().getParameters().get('txt');
        system.debug('str======'+str);
        return System.currentPageReference().getParameters().get('txt');
      }
      // used by the visualforce page to send the link to the right dom element for the text box
      public string getTextBoxID() {
        string str = System.currentPageReference().getParameters().get('txtID');
        return System.currentPageReference().getParameters().get('txtID');
      }
  
}