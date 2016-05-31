/**
 * This class will initiate the insert/update logic for copying data from legacy Opportunity Partner object to the new object.
 * As per User Story US60137
 *
 * @version 2015-10-28
 * @author Pankaj Banik   <pbanik@deloitte.com>
 * 2014-10-31 - Created
 * Bill C Riemers <briemers@redhat.com>
 * 2015-10-28 - Refactored into OpportunityLineItemTriggerAfter
 */
@IsTest
private class OpportunityLineItem_Trigger_Handler {}
//depreciated public class OpportunityLineItem_Trigger_Handler{

//depreciated    private static Opportunity opportunities;
//depreciated    private static Set <String> OpportunityIds;
//depreciated    
//depreciated    //Method call to deactivate Quotes on Update event
//depreciated    public static void deactivateQuotesOnUpdate(map <id,OpportunityLineItem> lineItemsOldMap,map <id,OpportunityLineItem> lineItemsNewMap){
//depreciated        if (lineItemsOldMap != null || lineItemsNewMap != null){
//depreciated            Boolean valueChanged = false;
//depreciated            
//depreciated            // code for checking whether line item record has been modified
//depreciated            List<String> fieldNames = new List<String>();
//depreciated            //Fetching list of field API names from custom label
//depreciated            String fields = Label.Lineitems_fields_for_trigger ;
//depreciated            if (fields != null){
//depreciated                fieldNames = fields.split(';');
//depreciated                
//depreciated                //Iterating on list of fields
//depreciated                for (String fieldName : fieldNames){
//depreciated                    //iterating on list of lineItems
//depreciated                    for(id opportunitylineitemId: lineItemsOldMap.keyset()){
//depreciated                        //checking if values have changed
//depreciated                        if(lineItemsOldMap.get(opportunitylineitemId).get(fieldName)!=lineItemsNewMap.get(opportunitylineitemId).get(fieldName))
//depreciated                            valueChanged = true ;
//depreciated                            break;
//depreciated                    }
//depreciated                    if (valueChanged)
//depreciated                        break;
//depreciated                }
//depreciated                
//depreciated                //if value has changed, deactivate quote
//depreciated                if (valueChanged)
//depreciated                {
//depreciated                    findOpportunityIds(lineItemsNewMap);
//depreciated                    deactivateQuotes(); 
//depreciated                }
//depreciated            }
//depreciated        }
//depreciated    }
//depreciated    
//depreciated    //Method to deactivate Big Machine Quotes
//depreciated    public static void deactivateQuotes() {
//depreciated        //Fetch list of BigMachine Quotes for an opportunity
//depreciated        List<BigMachines__Quote__c> bmQuotes = [select Id from BigMachines__Quote__c where BigMachines__Opportunity__c IN :opportunityIds and BigMachines__Is_Primary__c != false];
//depreciated        
//depreciated        List<BigMachines__Quote__c> bigMachineQoutes = new List<BigMachines__Quote__c>();
//depreciated        for(BigMachines__Quote__c bmQuote : bmQuotes) {
//depreciated            bmQuote.put('BigMachines__Is_Primary__c',false);
//depreciated            bigMachineQoutes.add(bmQuote);
//depreciated        }
//depreciated        
//depreciated        if (!bigMachineQoutes.isEmpty()){
//depreciated            try{
//depreciated                update bigMachineQoutes;
//depreciated            }
//depreciated            catch (Exception e)
//depreciated            {
//depreciated                System.debug(e.getMessage());
//depreciated            }
//depreciated        }
//depreciated    }
//depreciated    
//depreciated    
//depreciated    
//depreciated    //Method to fetch List of opportunity Ids from the map of OpportunityLine Items
//depreciated    public static void findOpportunityIds(Map <id,OpportunityLineItem> lineItemsMap){
//depreciated        OpportunityIds = new Set <String>();
//depreciated        if (lineItemsMap!= null){
//depreciated            for (Id lineItemid : lineItemsMap.keyset()){            
//depreciated                OpportunityIds.add(lineItemsMap.get(lineItemid).opportunityid);
//depreciated            }
//depreciated        }
//depreciated    }
//depreciated    
//depreciated    
//depreciated }