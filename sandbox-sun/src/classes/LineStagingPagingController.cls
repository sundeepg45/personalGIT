/** 
 * @version  2015-03-23
 * @author Sagar Mehta <smehta@redhat.com>
 * Used for implementing pagination for Line Staging records.
 * User Story US65328: Opportunity Staging Table 100 line item limit  
 */
public class LineStagingPagingController {
    
    String opptyHeaderStagingId;    
    public String entitleToAccount = 'test';
    public String entitleToAddress = 'test';
    public String entitleToContact = 'test';
    public String entitleToSalesAccount = 'test';
    Opportunity_Header_Staging__c headerStaging;   
    
    public String headerName{get;set;}
    public String lineFieldNameSet{get;set;}         
    List<Opportunity_Line_Staging__c> relatedOpptyLineStagingList {get;set;}
    
    public LineStagingPagingController(){
        headerStaging = new Opportunity_Header_Staging__c();
        if(ApexPages.currentPage().getParameters().get('id') != null){
           opptyHeaderStagingId = ApexPages.currentPage().getParameters().get('id');
           List<Opportunity_Header_Staging__c> headerList = new List<Opportunity_Header_Staging__c>();
           headerList = [Select Id, Name, Entitle_To_Sales_Account__c, Entitle_To_Account__c, Entitle_To_Address__c, Entitle_To_Contact__c from Opportunity_Header_Staging__c where Id =: opptyHeaderStagingId];
           if(headerList.size() > 0){
               headerName = headerList.get(0).Name;
               headerStaging = headerList.get(0);
           }else{
               ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Invalid Header Staging record.'));
               return;
           }
           
           if(ApexPages.currentPage().getParameters().get('ea') != null && ApexPages.currentPage().getParameters().get('ea') != ''){
             entitleToAccount = ApexPages.currentPage().getParameters().get('ea');
           }           
           if(ApexPages.currentPage().getParameters().get('ead') != null && ApexPages.currentPage().getParameters().get('ead') != ''){
              entitleToAddress = ApexPages.currentPage().getParameters().get('ead');
           }
           if(ApexPages.currentPage().getParameters().get('ec') != null && ApexPages.currentPage().getParameters().get('ec') != ''){
              entitleToContact = ApexPages.currentPage().getParameters().get('ec');
           }           
           if(ApexPages.currentPage().getParameters().get('esa') != null && ApexPages.currentPage().getParameters().get('esa') != ''){
              entitleToSalesAccount = ApexPages.currentPage().getParameters().get('esa');
           }   
        }else{
           ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Invalid Header Staging record.'));
           return;
        }   
        for(Schema.FieldSetMember f : SObjectType.Opportunity_Line_Staging__c.FieldSets.Oppty_Line_Staging_Editable_Field_Set.getFields()) {
            lineFieldNameSet += f.getFieldPath() + ', ';
        }
    }
         
    // instantiate the StandardSetController from a query locator
    public ApexPages.StandardSetController con {
        get {
            if(con == null) {
                con = new ApexPages.StandardSetController(Database.query(buildLineStagingQuery()));
                // sets the number of records in each page set
                con.setPageSize(50);
            }
            return con;
        }
        set;
    }
    
    /**
     * Method name  : buildLineStagingQuery
     * Description  : Used to return SOQL query of Opportunity Line Staging related to a Opportunity Stage Header record.
     *                
     * Return Type  : String
     * Parameter    : 
     **/
    public String buildLineStagingQuery(){
       
       String query = 'SELECT ';
       for(Schema.FieldSetMember f : SObjectType.Opportunity_Line_Staging__c.FieldSets.Entitle_To_Account_Information_FieldSet.getFields()) {
            query += f.getFieldPath() + ', ';
       }
       for(Schema.FieldSetMember f : SObjectType.Opportunity_Line_Staging__c.FieldSets.Entitle_To_Address_Information_FieldSet.getFields()) {
            query += f.getFieldPath() + ', ';
       }
       for(Schema.FieldSetMember f : SObjectType.Opportunity_Line_Staging__c.FieldSets.Entitle_To_Contact_Information_Field_Set.getFields()) {
            query += f.getFieldPath() + ', ';
       }
       for(Schema.FieldSetMember f : SObjectType.Opportunity_Line_Staging__c.FieldSets.Oppty_Line_Staging_Information_FieldSet.getFields()) {
            query += f.getFieldPath() + ', ';
       }
       query += 'Id, Name, ActualEndDate__c, ActualStartDate__c, Base_Price__c, Quantity__c, UnitPrice__c, Total_Price__c FROM Opportunity_Line_Staging__c';
       query += ' where Opportunity_Stage_Header_ID__c = \'' +opptyHeaderStagingId+ '\'';        
       Oppty_Staging_Limit__c limitSetting = Oppty_Staging_Limit__c.getInstance('LineStaging');
       if(limitSetting.Limit__c != null)
          query += ' LIMIT ' + limitSetting.Limit__c;
       else
          query += ' LIMIT 10';
             
       system.debug('========================================================================>'+query);
       return query;
    }        

    // returns a list of wrapper objects for the sObjects in the current page set
    public List<Opportunity_Line_Staging__c> getRelatedOpptyLineStagingList() {
        relatedOpptyLineStagingList = new List<Opportunity_Line_Staging__c>();
        for (Opportunity_Line_Staging__c line : (List<Opportunity_Line_Staging__c>)con.getRecords())
            relatedOpptyLineStagingList.add(line);

        return relatedOpptyLineStagingList;
    }
    
    /**
     * Used to copy Entitle Information from Header Staging to Line Staging.     
     * @return void
     */ 
    public void copyEntitleToFromHeaderInformation(){
        for(Opportunity_Line_Staging__c lineStaging : relatedOpptyLineStagingList){            
            if(entitleToSalesAccount != 'test')
               lineStaging.Entitle_To_Sales_Account__c = entitleToSalesAccount;
            
            if(entitleToAccount != 'test')
               lineStaging.Entitle_To_Account__c = entitleToAccount;        
            
            if(entitleToAddress != 'test')
               lineStaging.Entitle_To_Address__c = entitleToAddress;  
            
            if(entitleToContact != 'test')
               lineStaging.Entitle_To_Contact__c = entitleToContact;                   
        }
    }  

    // displays the selected items
    public void saveLineStaging() {
         if(relatedOpptyLineStagingList != null && relatedOpptyLineStagingList.size() > 0)    
            update relatedOpptyLineStagingList;
    }
    
    public void saveAndCancel(){
        saveLineStaging();        
    }

    // indicates whether there are more records after the current page set.
    public Boolean hasNext {
        get {
            return con.getHasNext();
        }
        set;
    }

    // indicates whether there are more records before the current page set.
    public Boolean hasPrevious {
        get {
            return con.getHasPrevious();
        }
        set;
    }

    // returns the page number of the current page set
    public Integer pageNumber {
        get {
            return con.getPageNumber();
        }
        set;
    }

    // returns the first page of records
     public void first() {
         con.save();
         con.first();         
     }

     // returns the last page of records
     public void last() {
         con.save();
         con.last();
     }

     // returns the previous page of records
     public void previous() {
         con.save();
         con.previous();
     }

     // returns the next page of records
     public void next() {
         con.save();
         con.next();
     }

}