public class StartEndDateUpdateMDF{


           public void updateMDF(){
            SFDC_Budget__c objMDF ;
            Integer year;
           

               for(Integer i=0;i<Trigger.new.size();i++)
               {    
                   objMDF=(SFDC_Budget__c)Trigger.new[i];
                    //String fiscalYearString=objMDF.Fiscal_Year__c;
                    //String yearString=fiscalYearString.substring(2);
                    //Integer year=Integer.valueOf(yearString);
                    //System.debug('year'+year);
                    
                    if(objMDF.Fiscal_Quarter__c==null ||objMDF.Select_Fiscal_Year__c==null)
                   {objMDF.Start_Date__c=null;
                    objMDF.End_Date__c=null;
                    continue;}
                    Date today=system.today();
                    Integer month=today.month();
                    if(month<3)
                   year=today.year();
                    else
                   year=today.year()+1;


                    if(objMDF.Select_Fiscal_Year__c=='Next Fiscal Year')
                    year=year+1;
                    

                    
                    if(objMDF.Fiscal_Quarter__c=='Q1')
                   {objMDF.Start_Date__c=date.newinstance(year-1, 3, 1);
                    objMDF.End_Date__c=date.newinstance(year-1, 5, 31);
                   }
                   if(objMDF.Fiscal_Quarter__c=='Q2')
                   {objMDF.Start_Date__c=date.newinstance(year-1, 6, 1);
                    objMDF.End_Date__c=date.newinstance(year-1, 8, 31);
                   }
                    if(objMDF.Fiscal_Quarter__c=='Q3')
                   {objMDF.Start_Date__c=date.newinstance(year-1, 9, 1);
                    objMDF.End_Date__c=date.newinstance(year-1, 11, 30);
                   }
                   if(objMDF.Fiscal_Quarter__c=='Q4')
                   {objMDF.Start_Date__c=date.newinstance(year-1, 12, 1);
                   if(date.isLeapYear(year))
                    objMDF.End_Date__c=date.newinstance(year, 2, 29);
                   else
                    objMDF.End_Date__c=date.newinstance(year, 2, 28);
                   }
                             
               }
             
           }

           public static testMethod void deployStartEndDateUpdateMDF() 
         {
                Account acc=[Select Id from Account where isAccountActive__c=true limit 1];
				
				RecordType objRecordType=[Select Id from RecordType where Name='MDF' and  SobjectType='SFDC_Budget__c'];    
				
                SFDC_Budget__c testBud=new SFDC_Budget__c();
                testBud.Name='StartEndDateMDF';
                testBud.Account_master__c=acc.Id;
                testBud.Select_Fiscal_Year__c='Next Fiscal Year';
                testBud.Fiscal_Quarter__c='Q1';
                testBud.RecordtypeId=objRecordType.Id;
                testBud.Active__c=true;
                insert testBud;

                SFDC_Budget__c testBud1=new SFDC_Budget__c();
                testBud1.Name='StartEndDateMDF1';
                testBud1.Account_master__c=acc.Id;
                testBud1.Select_Fiscal_Year__c='Next Fiscal Year';
                testBud1.Fiscal_Quarter__c='Q2';
                testBud1.RecordtypeId=objRecordType.Id;
                testBud1.Active__c=true;
                insert testBud1;
                
                SFDC_Budget__c testBud2=new SFDC_Budget__c();
                testBud2.Name='StartEndDateMDF2';
                testBud2.Account_master__c=acc.Id;
                testBud2.Select_Fiscal_Year__c='Next Fiscal Year';
                testBud2.Fiscal_Quarter__c='Q3';
                testBud2.RecordtypeId=objRecordType.Id;
                testBud2.Active__c=true;
                insert testBud2;

                SFDC_Budget__c testBud3=new SFDC_Budget__c();
                testBud3.Name='StartEndDateMDF3';
                testBud3.Account_master__c=acc.Id;
                testBud3.Select_Fiscal_Year__c='Next Fiscal Year';
                testBud3.Fiscal_Quarter__c='Q4';
                testBud3.RecordtypeId=objRecordType.Id;
                testBud3.Active__c=true;
                insert testBud3;

             }  

   }