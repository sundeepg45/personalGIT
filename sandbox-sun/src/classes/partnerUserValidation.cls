public class partnerUserValidation
{
        public List<Lead> partvalidation(List<Lead> leads)
        {
                List<Lead> errorList= new List<Lead>();
                Map<String,String> partneruserMap = new Map<String,String>();
                SET<String> ownerIdSet= new SET<String>();              
                
               // String dealerRegistrationRecordTypeId = null;

                for(Lead lead:leads)
                {
                        ownerIdSet.add(lead.OwnerId);
                }

                User[] users = [Select Name, Id, ProfileId from User where Id in :ownerIdSet and Profile.Name like '%partner%'];

                for(User user:users)
                {
                        partneruserMap.put(user.Id,user.Id);
                }
                
                //RecordType[] recordType = [select Id from RecordType where Name = 'Deal Registration' limit 1];
                
                //if (recordType.size() > 0) 
            //  {
                        //dealerRegistrationRecordTypeId = recordType[0].Id;                        
                //}
                
                // Find the record type information
                for(Lead objlead:leads)
                {                   
                         if (partneruserMap.containsKey(objlead.ownerId) == false)
                         		continue; 
                         		
                 	     if (objlead.recordTypeId == '0126000000058QXAAY')
                 	     		continue; // Production.Lead.RecordTypeId = NA
                 	     if (objlead.recordTypeId == '0126000000059wFAAQ')
                 	     		continue; // Production.Lead.RecordTypeId = NA Fed/Sled
                 	     if (objlead.recordTypeId == '0126000000059wAAAQ')
                 	     		continue; // Production.Lead.RecordTypeId = LATAM
                 	     if (objlead.recordTypeId == System.Label.RecordTypeId_EMEADealRegistration)
                 	     		continue; // SADEV = 012R00000008mwSIAQ
                 	     				  // QA = 012R00000004aFkIAI
                 	     				  // Stage = 012T00000008VxBIAU
                 	     				  // Production = ?

                         if (objlead.Partner_Opt_In__c != null)
                                continue;

                         errorList.add(objlead);
                }

                return errorlist;
        }

        public static testmethod void t1()
        {
                Lead[] leads = new Lead[1];
        
                Lead lead = new Lead();
                lead.OwnerId=Util.ldPartnerUser;
                lead.LastName ='TestR4DeployLead';
                lead.Title='R4';
                lead.LeadSourceDetail__c='APAC World Tour';
                lead.Status='New';
                lead.Products_of_Interest__c='JBoss';
                lead.Partner_Opt_In__c=true;
                lead.Email='Paresh@gmail.gov';
                lead.Iso_Country_Code__c='US';

                leads[0]=lead;
                                
                new partnerUserValidation().partvalidation(leads);
        }
}