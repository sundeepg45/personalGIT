trigger Opportunity_Submitted_to_OM on Opportunity (after update){
//depreciated    if(BooleanSetting__c.getInstance('DeactivateAll') != null && BooleanSetting__c.getInstance('DeactivateAll').Value__c == true) return;
//depreciated    List<Opportunity> oppList=new  List<Opportunity>();
//depreciated    List<Id> oppIds=new  List<Id>();
//depreciated    Set<String> oppCountryList=new Set<String>();
//depreciated    List<Task> taskList=new  List<Task>();    
//depreciated    Map<String,Region__c> regionMap=new Map<String,Region__c>();

//depreciated    Id omTaskId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('OM Processing Task').getRecordTypeId();
//depreciated    for(Opportunity opptyRecord: Trigger.new){  
//depreciated        if(opptyRecord.StageName == 'Closed Won'){             
//depreciated            oppList.add(opptyRecord);
//depreciated            oppIds.add(opptyRecord.Id);
//depreciated            oppCountryList.add(opptyRecord.Country_Of_Order__c);
//depreciated        }
//depreciated    }   
//depreciated    if(oppList.size()==0) return;

//depreciated    //check if Task is already present. 
//depreciated    Task oldtask = null;
//depreciated    taskList = [select Id,WhatId from Task where WhatId IN :oppIds and RecordTypeId =:omTaskId and Status ='Not Started' limit 1];
//depreciated    
//depreciated    if(taskList.size()==0){
//depreciated        for(Region__c region: [select Country__c, Super_Region__c, OM_Task_Owner__c from Region__c where Country__c IN :oppCountryList and OM_Task__c = true]){            
//depreciated            regionMap.put(region.Country__c,region);            
//depreciated        }
//depreciated    }   
//depreciated    
//depreciated    List<Task> taskInsertList = new List<Task>();
//depreciated    for(Opportunity opp:oppList){
//depreciated        if(regionMap.get(opp.Country_Of_Order__c) != NULL){
//depreciated            Task newTask=new Task();            
//depreciated            if(regionMap.get(opp.Country_Of_Order__c).Super_Region__c == 'NA'){             
//depreciated                newTask.OwnerId = regionMap.get(opp.Country_Of_Order__c).OM_Task_Owner__c;
//depreciated                newTask.Subject = 'Order Submitted for Processing NA';
//depreciated            }
//depreciated            // July Release ,case RH-00036357 starts here.
//depreciated            else if (regionMap.get(opp.Country_Of_Order__c).Super_Region__c== 'LATAM'){             
//depreciated                newTask.OwnerId = regionMap.get(opp.Country_Of_Order__c).OM_Task_Owner__c;
//depreciated                newTask.Subject = 'Order Submitted for Processing LATAM';
//depreciated            }
//depreciated            // July Release ,case RH-00036357 ends here.
//depreciated            else if(regionMap.get(opp.Country_Of_Order__c).Super_Region__c== 'EMEA'){                   
//depreciated                newTask.OwnerId = regionMap.get(opp.Country_Of_Order__c).OM_Task_Owner__c;
//depreciated                newTask.Subject = 'Order Submitted for Processing EMEA';
//depreciated            }
//depreciated            else if(regionMap.get(opp.Country_Of_Order__c).Super_Region__c== 'APAC'){                   
//depreciated                newTask.OwnerId = regionMap.get(opp.Country_Of_Order__c).OM_Task_Owner__c;
//depreciated                newTask.Subject = 'Order Submitted for Processing APAC';                
//depreciated            }
//depreciated            if(String.isNotBlank(newTask.OwnerId)&&String.isNotBlank(newTask.Subject)){
//depreciated                newTask.WhatId=opp.Id;
//depreciated                newTask.RecordTypeId = omTaskId;
//depreciated                newTask.Status ='Not Started';
//depreciated                newTask.Priority = 'Normal';
//depreciated                newTask.ActivityDate = System.today();
//depreciated                newTask.Description='Please proceed with the following:\n' +
//depreciated                '1. Print out the Order using the Order Form custom link on the Opportunity detail.\n'+
//depreciated                '2. After printing the form update this task status to In progress and check the "OE Form Printed" checkbox';
//depreciated                taskInsertList.add(newTask);
//depreciated            }               
//depreciated        }
//depreciated    }
//depreciated    if(!taskInsertList.isEmpty()&&taskInsertList.size()>0){
//depreciated        insert taskInsertList;
//depreciated    }
}