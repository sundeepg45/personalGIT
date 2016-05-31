/*****************************************************************************************
    Name    : OpportunityService
    Desc    : This class defines the logic for initiating Opportunity Create/update service

Modification Log :
---------------------------------------------------------------------------
 Developer              Date            Description
---------------------------------------------------------------------------
Pankaj Banik         30/06/2014          Created
******************************************************************************************/
public with sharing class OpportunityService
{
    //Class Level Variables declaration    
    private Opportunity_Header_Staging__c opportunityStagingRecord;
    private List<Opportunity_Line_Staging__c> opportunityLineStagingList;
    private List<Opportunity_Partner_Staging__c> opportunityPartnerStagingList;

    //Initiates the Opportunity Service
    public void initiateOpporrunityService(String opportunityStagingObjectID)
    {
        
        //Fetching Related records from Staging Objects
        //Fetching opportunity Staging Record
        opportunityStagingRecord = [SELECT
                                    Bill_To_Account_Number__c,
                                    Bill_To_Account__c,
                                    Bill_To_Address_CDH_Party_Site_Number__c,
                                    Bill_To_Address_Line_1__c,
                                    Bill_To_Address_Line_2__c,
                                    Bill_To_Address_Line_3__c,
                                    Bill_To_Address_Line_4__c,
                                    Bill_To_Address__c,
                                    Bill_To_CDH_Party_Number__c,
                                    Bill_To_City__c,
                                    Bill_To_Contact_Email__c,
                                    Bill_To_Contact_First_Name__c,
                                    Bill_To_Contact_Last_Name__c,
                                    Bill_To_Contact_Phone__c,
                                    Bill_To_Contact__c,
                                    Bill_To_Country__c,
                                    Bill_To_County__c,
                                    Bill_To_Party_Name__c,
                                    Bill_To_Party_Number__c,
                                    Bill_To_Party_Type__c,
                                    Bill_To_Province__c,
                                    Bill_To_Sales_Account__c,
                                    Bill_To_State__c,
                                    Bill_To_Zip_Postal_Code__c,
                                    Channel__c,
                                    CurrencyIsoCode,
                                    Date_Ordered__c,
                                    Employee_Number__c,
                                    Entitle_To_Account_Number__c,
                                    Entitle_To_Account__c,
                                    Entitle_To_Address_CDH_Party_Site_Number__c,
                                    Entitle_To_Address_Line_1__c,
                                    Entitle_To_Address_Line_2__c,
                                    Entitle_To_Address_Line_3__c,
                                    Entitle_To_Address_Line_4__c,
                                    Entitle_To_Address__c,
                                    Entitle_To_CDH_Party_Number__c,
                                    Entitle_To_City__c,
                                    Entitle_To_Contact_Email__c,
                                    Entitle_To_Contact_First_Name__c,
                                    Entitle_To_Contact_Last_Name__c,
                                    Entitle_To_Contact_Phone__c,
                                    Entitle_To_Contact__c,
                                    Entitle_To_Country__c,
                                    Entitle_To_County__c,
                                    Entitle_To_Party_Name__c,
                                    Entitle_To_Party_Number__c,
                                    Entitle_To_Party_Type__c,
                                    Entitle_To_Province__c,
                                    Entitle_To_Sales_Account__c,
                                    Entitle_To_State__c,
                                    Entitle_To_Zip_Postal_Code__c,
                                    Id,
                                    Name,
                                    Operating_Unit__c,
                                    Opportunity_ID__c,
                                    Opportunity_Name__c,
                                    Opportunity_Number__c,
                                    Opportunity_Owner__c,
                                    Oracle_Order_ID__c,
                                    Oracle_Order_Number__c,
                                    Order_Last_Update_Date__c,
                                    Order_Source__c,
                                    Order_Status__c,
                                    Order_Type__c,
                                    OwnerId,
                                    Payment_Type__c,
                                    PO_Number__c,
                                    Resller_PO__c,
                                    Sales_Account__c,
                                    Ship_To_Account_Number__c,
                                    Ship_To_Account__c,
                                    Ship_To_Address_CDH_Party_Site_Number__c,
                                    Ship_To_Address_Line_1__c,
                                    Ship_To_Address_Line_2__c,
                                    Ship_To_Address_Line_3__c,
                                    Ship_To_Address_Line_4__c,
                                    Ship_To_Address__c,
                                    Ship_To_CDH_Party_Number__c,
                                    Ship_To_City__c,
                                    Ship_To_Contact_Email__c,
                                    Ship_To_Contact_First_Name__c,
                                    Ship_To_Contact_Last_Name__c,
                                    Ship_To_Contact_Phone__c,
                                    Ship_To_Contact__c,
                                    Ship_To_Country__c,
                                    Ship_To_County__c,
                                    Ship_To_Party_Name__c,
                                    Ship_To_Party_Number__c,
                                    Ship_To_Party_Type__c,
                                    Ship_To_Province__c,
                                    Ship_To_Sales_Account__c,
                                    Ship_To_State__c,
                                    Ship_To_Zip_Postal_Code__c,
                                    Sold_To_Account_Number__c,
                                    Sold_To_Account__c,
                                    Sold_To_Address_CDH_Party_Site_Number__c,
                                    Sold_To_Address_Line_1__c,
                                    Sold_To_Address_Line_2__c,
                                    Sold_To_Address_Line_3__c,
                                    Sold_To_Address_Line_4__c,
                                    Sold_To_Address__c,
                                    Sold_To_CDH_Party_Number__c,
                                    Sold_To_City__c,
                                    Sold_To_Contact_Email__c,
                                    Sold_To_Contact_First_Name__c,
                                    Sold_To_Contact_Last_Name__c,
                                    Sold_To_Contact_Phone__c,
                                    Sold_To_Contact__c,
                                    Sold_To_Country__c,
                                    Sold_To_County__c,
                                    Sold_To_Party_Name__c,
                                    Sold_To_Party_Number__c,
                                    Sold_To_Party_Type__c,
                                    Sold_To_Province__c,
                                    Sold_To_Sales_Account__c,
                                    Sold_To_State__c,
                                    Sold_To_Zip_Postal_Code__c
                                    FROM Opportunity_Header_Staging__c
                                    WHERE Id = :opportunityStagingObjectID];

        System.Debug ('opportunityStagingRecord----->' + opportunityStagingRecord) ;
        
        //Fetching Opportunity Line Staging Records
        opportunityLineStagingList = [SELECT 
                                      ActualEndDate__c,
                                      ActualStartDate__c,
                                      Adjusted_Price__c,
                                      Base_Price__c,
                                      Contract_Numbers__c,
                                      Entitle_To_Account_Number__c,
                                      Entitle_To_Account__c,
                                      Entitle_To_Address_Line_1__c,
                                      Entitle_To_Address_Line_2__c,
                                      Entitle_To_Address_Line_3__c,
                                      Entitle_To_Address_Line_4__c,
                                      Entitle_To_Address__c,
                                      Entitle_To_CDH_Party_Number__c,
                                      Entitle_To_CDH_Party_Site_Number__c,
                                      Entitle_To_City__c,
                                      Entitle_To_Contact_Email__c,
                                      Entitle_To_Contact_First_Name__c,
                                      Entitle_To_Contact_Last_Name__c,
                                      Entitle_To_Contact_Phone__c,
                                      Entitle_To_Contact__c,
                                      Entitle_To_Country__c,
                                      Entitle_To_County__c,
                                      Entitle_To_Party_Name__c,
                                      Entitle_To_Party_Number__c,
                                      Entitle_To_Province__c,
                                      Entitle_To_State__c,
                                      Entitle_To_Zip_Postal_Code__c,
                                      Id,
                                      Install_Base_Number__c,
                                      Name,
                                      Opportunity_ID__c,
                                      Opportunity_Number__c,
                                      Opportunity_Product_ID__c,
                                      Opportunity_Stage_Header_ID__c,
                                      Oracle_Order_Header_Id__c,
                                      Product_Code__c,
                                      Quantity__c,
                                      Return_Reason_Code__c,
                                      Total_Price__c,
                                      UnitPrice__c,
                                      Unit_of_Measure__c 
                                      FROM Opportunity_Line_Staging__c
                                      WHERE Opportunity_Stage_Header_ID__c =:opportunityStagingRecord.Id];
        
        System.Debug ('opportunityLineStagingList----->' + opportunityLineStagingList) ;
        
        //Fetching Opportunity Line Staging Records
        opportunityPartnerStagingList = [SELECT 
                                        CDH_Party_Number__c,
                                        EBS_Account_Number__c,
                                        Id,
                                        Name,
                                        Opportunity_Stage_Header_ID__c,
                                        Oracle_Order_Header_Id__c,
                                        PartnerTier__c,
                                        Partner_Contact_CDH_Party_Number__c,
                                        Partner_Contact_Email__c,
                                        Partner_Contact_First_Name__c,
                                        Partner_Contact_Last_Name__c,
                                        Partner_Contact_Phone__c,
                                        Partner_Contact__c,
                                        Partner_Sales_Account__c,
                                        Partner_Sub_Type__c,
                                        Partner_Type__c,
                                        RelationshipType__c 
                                        FROM Opportunity_Partner_Staging__c
                                        WHERE Opportunity_Stage_Header_ID__c =:opportunityStagingRecord.Id];
        
        System.Debug ('opportunityPartnerStagingList----->' + opportunityPartnerStagingList) ;

        if (opportunityStagingRecord != null)
        {   
            
            //Checking for Order Status and initiating require processes
            if (opportunityStagingRecord.Order_Status__c == 'BOOKED')
            {
                //Check for Opportunity Source
                if (opportunityStagingRecord.Order_Source__c == 'SFDC_Sales')
                {
                    //DirectOpportunityService DirectServiceObject = new DirectOpportunityService();
                    //DirectServiceObject.initiateDirectOpportunityService(opportunityStagingRecord, opportunityLineStagingList, opportunityPartnerStagingList);
                }
                else
                {
                    //IndirectOpportunityService IndirectServiceObject = new IndirectOpportunityService();
                    //IndirectServiceObject.initiateIndirectOpportunityService(opportunityStagingRecord, opportunityLineStagingList, opportunityPartnerStagingList);
                }
            }
            else if (opportunityStagingRecord.Order_Status__c == 'INVOICED' || opportunityStagingRecord.Order_Status__c == 'ENTERED' || opportunityStagingRecord.Order_Status__c == 'CLOSED' || opportunityStagingRecord.Order_Status__c == 'CANCELLED' )
            {
                updateOpportunityRecords();
            }
            else if (opportunityStagingRecord.Order_Status__c == null)
            {
                
                opportunityStagingRecord.Status__c = 'Error' ;
                update opportunityStagingRecord ;
                
                // Exception
                // Throw exception in case Order Status is null.
                throw new Interface_ServiceException('Order Status cannot be null.');
            }
            
        }
    }

    // Logic for updating Opportunity staging records where Order status is not Booked
    public void updateOpportunityRecords()
    {
        Savepoint savepoint = Database.setSavepoint();
        try 
        {   
            List<Opportunity> opportunityRecordList = new List <Opportunity> ();
            //Logic for fetching Opportunity updating them
            //if (opportunityStagingRecord.Order_Source__c == 'Sfdc_Sales')
           // {
                // Query for Direct Opportunities
                opportunityRecordList =[Select Id , Name , OwnerId , StageName , OracleOrderNumber__c , OracleOrderID__c ,Order_Status__c  from Opportunity where id =:opportunityStagingRecord.Opportunity_ID__c or OpportunityNumber__c =:opportunityStagingRecord.Opportunity_Number__c ];
           // }
           // else 
           // {
               // Query for Indirect Opportunities
              // opportunityRecordList =[Select Id , Name , OwnerId , StageName , OracleOrderNumber__c , OracleOrderID__c , Order_Status__c  from Opportunity where OracleOrderNumber__c =:opportunityStagingRecord.Oracle_Order_Number__c or OracleOrderID__c =:opportunityStagingRecord.Oracle_Order_ID__c ];
           // }
            
            if (opportunityRecordList.size() > 0)
            {
                //Logic for updating Opportunity
                Opportunity opportunityRecord = opportunityRecordList[0];
                //Updating Opportunity Records
                if (opportunityStagingRecord.Order_Status__c == 'ENTERED')
                {
                    if (opportunityStagingRecord.Oracle_Order_Number__c != null || opportunityStagingRecord.Oracle_Order_ID__c != null)
                    {
                        opportunityRecord.Order_Status__c = 'Entered' ;
                        opportunityRecord.OracleOrderNumber__c = opportunityStagingRecord.Oracle_Order_Number__c ;
                        opportunityRecord.OracleOrderID__c = opportunityStagingRecord.Oracle_Order_ID__c ;
                    }
                    else 
                    {
                        //Exception
                        // Throw exception in case Oracle Order Number or Oracle Order Id is null.
                        throw new Interface_ServiceException('Oracle Order Number or Oracle Order Id cannot be null.');
                    }
                }
                else if (opportunityStagingRecord.Order_Status__c == 'CLOSED' )
                {
                    opportunityRecord.Order_Status__c = 'Closed';
                }
                else if ( opportunityStagingRecord.Order_Status__c == 'CANCELLED')
                {
                    opportunityRecord.Order_Status__c = 'Cancelled' ;
                }
                else if ( opportunityStagingRecord.Order_Status__c == 'INVOICED')
                {
                    opportunityRecord.Order_Status__c = 'Invoiced' ;
                }

                //Update the Opportunity
                update opportunityRecord;
                
                //Create Order Tracking Record
                Order_Tracking__c orderTrackingRecord = new Order_Tracking__c();
                orderTrackingRecord.Opportunity__c = opportunityRecord.Id;
                orderTrackingRecord.Opportunity_Owner__c = opportunityRecord.OwnerId;
                orderTrackingRecord.Opportunity_Stage__c = opportunityRecord.StageName;
                orderTrackingRecord.Oracle_Order_Number__c = opportunityRecord.OracleOrderNumber__c ;
                orderTrackingRecord.Order_Status__c = opportunityRecord.Order_Status__c ;
                orderTrackingRecord.Submitted_By__c = userInfo.getUserId() ;
                orderTrackingRecord.Submitted_Date__c = System.Now() ;
                
                insert orderTrackingRecord;
                
                opportunityStagingRecord.Status__c = 'Processed' ;
                update opportunityStagingRecord ;
            }
            else
            {
                opportunityStagingRecord.Status__c = 'Error' ;
                update opportunityStagingRecord ;
                //Exception
                // Throw exception in case no opportunity Record is found.
                throw new Interface_ServiceException('Opportunity record was not found.');          
            }
            
        }
        catch (Exception e)
        {
            opportunityStagingRecord.Status__c = 'Error' ;
            update opportunityStagingRecord ;
            
            System.Debug (e.GetMessage()) ;
            //database.rollback(savepoint);
        }
    }
}