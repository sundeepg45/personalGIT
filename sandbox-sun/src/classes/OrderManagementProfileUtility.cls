/*****************************************************************************************
    Name    : OrderManagementProfileUtility
    Desc    : Holds the utility methods used by OrderManagementProfileTrigger
                            
Modification Log : 
---------------------------------------------------------------------------
 Developer                Date                 Description
---------------------------------------------------------------------------
 Anshul Kumar             12 Jan, 2015         Created (US60986)
******************************************************************************************/
public with sharing class OrderManagementProfileUtility{
    
    /**
     *Name: checkDefault_appendDate
     *@param: list<Order_Management_Profile__c>
     *@return: void
     *
     *This method is used to append date to Name of OMP and uncheck Primary field of Previous OMP
     *if current OMP is Primary 
     */
    public static void checkDefault_appendDate(list<Order_Management_Profile__c> triggerNew){
        
        set<Id> setParentAccIds = new set<Id>();
     
     //append date to Name of OMP and collect parent account ids   
        for(Order_Management_Profile__c ompInst : triggerNew){
            
            //ompInst.Name += ' ' + string.valueOf(System.Now().Date());
            setParentAccIds.add(ompInst.Account__c);
        }
     
     //fetch the OMPs associated to parent Account with Primary as TRUE   
        list<Order_Management_Profile__c> lstOMP = new list<Order_Management_Profile__c>([
                                                            SELECT 
                                                                Default__c,
                                                                Account__c 
                                                            FROM 
                                                                Order_Management_Profile__c
                                                            WHERE 
                                                                Account__c IN: setParentAccIds
                                                                AND
                                                                Default__c = TRUE
                                                            ]);
        
        map<Id, Order_Management_Profile__c> mapAccId_OMP = new map<Id, Order_Management_Profile__c>();
      
     //create map of parent Account Id and OMP instance  
        for(Order_Management_Profile__c ompInst : lstOMP){
            
            mapAccId_OMP.put(ompInst.Account__c, ompInst);
        }
        
        lstOMP.clear();
     
     //uncheck Primary of previous OMP if present OMP is Primary and collect for update  
        for(Order_Management_Profile__c ompInst : triggerNew){
            
            if(ompInst.Default__c){
                
                if(mapAccId_OMP.get(ompInst.Account__c) != NULL){
                    mapAccId_OMP.get(ompInst.Account__c).Default__c = FALSE;
                    lstOMP.add(mapAccId_OMP.get(ompInst.Account__c));
                }
            }
        }
     
     //update all OMP with updated Primary field   
        if(!lstOMP.isEmpty())
            update lstOMP;
    }
}