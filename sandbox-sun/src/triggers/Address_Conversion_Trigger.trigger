/*****************************************************************************************
    Name    : Address_Conversion_Trigger
    Desc    : This trigger is used to apply some data transformation rules on address data.
              This trigger should get deactivated once data load activity completes.
              Inactive the trigger and comment out the lines within the trigger once data load activity finishes.
              We have written the logic inside trigger because this is conversion trigger and we need to comment out this component once data load
              activity completes 
              
                            
    Modification Log : 
---------------------------------------------------------------------------
     Developer              Date            Description
---------------------------------------------------------------------------
     Neha Jaiswal         10 JUNE 2014         Created
******************************************************************************************/

trigger Address_Conversion_Trigger on Address__c (before insert,before update) {

    // iterating on all the address records and apply data transformation
    
    for(Address__c Address : trigger.new){
    
        // apply data transformation on status field
        if(address.Status__c !=Null ){
            if(address.Status__c == 'A'){
               address.Status__c = 'Active'; 
            }
            else if(address.Status__c == 'M'){
               address.Status__c = 'Merged'; 
            }
            else if(address.Status__c == 'I'){
               address.Status__c = 'Inactive'; 
            }
        }
        
        // apply data transformation on Identifying address field
        if(address.Identifying_Address__c != Null){
            if(string.valueOf(address.Identifying_Address__c)== 'Y'){
               address.Identifying_Address__c= True; 
            }
            if(string.valueOf(address.Identifying_Address__c) == 'N' || string.valueOf(address.Identifying_Address__c) == ''){
               address.Identifying_Address__c= False; 
            }
        }
        
        // apply data transformation on Bill to address field
        if(address.Bill_To_Address__c != Null){
        
            if(string.valueOf(address.Bill_To_Address__c)== 'Y'){
               address.Bill_To_Address__c= True; 
            }
            if(string.valueOf(address.Bill_To_Address__c) == 'N' || string.valueOf(address.Bill_To_Address__c) == ''){
               address.Bill_To_Address__c= False; 
            }
        }
        
        // apply data transformation on Ship To address field
        if(address.Ship_To_Address__c != Null){
        
            if(string.valueOf(address.Ship_To_Address__c)== 'Y'){
               address.Ship_To_Address__c= True; 
            }
            if(string.valueOf(address.Ship_To_Address__c) == 'N' || string.valueOf(address.Ship_To_Address__c) == ''){
               address.Ship_To_Address__c= False; 
            }
        }
        
        // apply data transformation on Sold To address field
        if(address.Sold_To_Address__c != Null){
        
            if(string.valueOf(address.Sold_To_Address__c)== 'Y'){
               address.Sold_To_Address__c= True; 
            }
            if(string.valueOf(address.Sold_To_Address__c) == 'N' || string.valueOf(address.Sold_To_Address__c) == ''){
               address.Sold_To_Address__c= False; 
            }
        }
        
        // apply data transformation on Entitle To address field
        if(address.Entitle_To_Address__c != Null){
        
            if(string.valueOf(address.Entitle_To_Address__c)== 'Y'){
               address.Entitle_To_Address__c= True; 
            }
            if(string.valueOf(address.Entitle_To_Address__c) == 'N' || string.valueOf(address.Entitle_To_Address__c) == ''){
               address.Entitle_To_Address__c= False; 
            }
        }
        
        // data transformation logic ends here      
    }
    // iteration on address record ends here.
}