trigger Opportunity_PopulateOMPData_BI on Opportunity (before Insert) {

    set<Id> setParentAccountId = new set<Id>();
    map<Id, Opportunity> mapAccountId_Opp = new map<Id, Opportunity>();
    map<Id, Opportunity> mapOppId_Opp;
    set<Id> setParentOppIds = new set<Id>();
  
  //populate set of parent account ids and map of parent account id --> opportunity  
    for(Opportunity oppInst : Trigger.new){
        
        setParentAccountId.add(oppInst.AccountId);
        mapAccountId_Opp.put(oppInst.AccountId, oppInst);
        setParentOppIds.add(oppInst.Cloned_From_Opportunity__c);
    }
  
  //fetch the related default OMPs  
    list<Order_Management_Profile__c> lstOMP = new list<Order_Management_Profile__c>([
                                                            SELECT
                                                                Name, Account__c, Bill_To_Account__c, Bill_To_Address__c,
                                                                Bill_To_Contact__c, Bill_To_EBS_Account__c, Default__c,
                                                                Entitle_To_Account__c, Entitle_To_Address__c, 
                                                                Entitle_To_Contact__c, Entitle_To_EBS_Account__c, 
                                                                Operating_Unit__c, Order_Type__c, Ship_To_Account__c,
                                                                Ship_To_Address__c, Ship_To_Contact__c, 
                                                                Ship_To_EBS_Account__c, Sold_To_Account__c, Sold_To_Address__c,
                                                                Sold_To_Contact__c, Sold_To_EBS_Account__c
                                                            FROM
                                                                Order_Management_Profile__c
                                                            WHERE
                                                                Account__c IN: setParentAccountId
                                                                AND
                                                                Default__c = TRUE
                                                            LIMIT 1
                                                            ]);
    
    mapOppId_Opp = new map<Id, Opportunity>([
                                            SELECT 
                                                Order_Management_Profile__c, Set_As_Default_Profile__c 
                                            FROM 
                                                Opportunity 
                                            WHERE 
                                                Id IN: setParentOppIds
                                            ]);
    
    Opportunity oppInst;
    
    
  //populate the opportunity fields from default OMP fields                                                          
    for(Order_Management_Profile__c ompInst : lstOMP){
        
        oppInst = new Opportunity();
        oppInst = mapAccountId_Opp.get(ompInst.Account__c);
        system.debug('---oppInst---'+oppInst);
        if(oppInst != NULL && oppInst.Cloned_From_Opportunity__c == NULL){
            oppInst.Order_Management_Profile__c = ompInst.Name;
            oppInst.Bill_To_Sales_Account__c = ompInst.Bill_To_Account__c;
            oppInst.Bill_To_Address__c = ompInst.Bill_To_Address__c;
            oppInst.Bill_To_Contact__c = ompInst.Bill_To_Contact__c;
            oppInst.Bill_To_Account__c = ompInst.Bill_To_EBS_Account__c;
            oppInst.Set_As_Default_Profile__c = ompInst.Default__c;
            oppInst.Entitle_To_Sales_Account__c = ompInst.Entitle_To_Account__c;
            oppInst.Entitle_To_Address__c = ompInst.Entitle_To_Address__c;
            oppInst.Entitle_To_Contact__c = ompInst.Entitle_To_Contact__c;
            oppInst.Entitle_To_Account__c = ompInst.Entitle_To_EBS_Account__c;
            oppInst.Operating_Unit__c = ompInst.Operating_Unit__c;
            oppInst.Order_Type__c = ompInst.Order_Type__c;
            oppInst.Ship_To_Sales_Account__c = ompInst.Ship_To_Account__c;
            oppInst.Ship_To_Address__c = ompInst.Ship_To_Address__c;
            oppInst.Ship_To_Contact__c = ompInst.Ship_To_Contact__c;
            oppInst.Ship_To_Account__c = ompInst.Ship_To_EBS_Account__c;
            oppInst.Sold_To_Sales_Account__c = ompInst.Sold_To_Account__c;
            oppInst.Sold_To_Address__c = ompInst.Sold_To_Address__c;
            oppInst.Sold_To_Contact__c = ompInst.Sold_To_Contact__c;
            oppInst.Sold_To_Account__c = ompInst.Sold_To_EBS_Account__c;
            system.debug('---oppInst---'+oppInst);
        }
        if(oppInst.Cloned_From_Opportunity__c != NULL && mapOppId_Opp.get(oppInst.Cloned_From_Opportunity__c) != NULL){
            oppInst.Order_Management_Profile__c
                            = mapOppId_Opp.get(oppInst.Cloned_From_Opportunity__c).Order_Management_Profile__c;
            oppInst.Set_As_Default_Profile__c 
                            = mapOppId_Opp.get(oppInst.Cloned_From_Opportunity__c).Set_As_Default_Profile__c;
        }
    }
}