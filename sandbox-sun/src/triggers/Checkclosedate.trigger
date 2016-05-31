/*
Name : Checkclosedate
Date Created: July 29, 2009
Created By : Kalidass Gujar
Description : This Trigger will mark/clear a flag if Close date is moved to future Quarters or moved back. 
*/

trigger Checkclosedate on Opportunity (before update) {
    if(BooleanSetting__c.getInstance('DeactivateAll') != null && BooleanSetting__c.getInstance('DeactivateAll').Value__c == true) return;

    Integer Q1 = 3;
    Integer Q2 = 6;
    Integer Q3 = 9;
    Integer Q4 = 12;
    Boolean  inCQflag  = false;

    if (trigger.isUpdate) {
        
        for(Integer i=0;i<Trigger.new.size();i++) {
            Integer months = ((Trigger.new[i].CloseDate.year() * 12) + Trigger.new[i].CloseDate.month()) - ((Trigger.old[i].CloseDate.year() * 12) + Trigger.old[i].CloseDate.month());
            Integer monthsforflg = ((Trigger.new[i].CloseDate.year() * 12) + Trigger.new[i].CloseDate.month()) - ((System.Today().year() * 12) + System.Today().month());
            
            System.debug('- Trigger New Close Date ' + Trigger.new[i].CloseDate);
            System.debug('- Trigger Old Close Date ' + Trigger.old[i].CloseDate);
          
            System.debug('- Months for flg ' + monthsforflg);
            System.debug('- Months Difference .....' + months);
           
            if (months != 0) {   
                if ((Trigger.old[i].CloseDate < Trigger.new[i].CloseDate)) {
                    if (months < 3 && months > 0) {                          
                        System.debug('Less than 3 months' + months); 
                 
                        if ((Trigger.new[i].CloseDate.month() == Q1)
                            || (Trigger.new[i].CloseDate.month() == Q2) 
                            || (Trigger.new[i].CloseDate.month() == Q3)
                            || (Trigger.new[i].CloseDate.month() == Q4)
                            /*
                            || (Trigger.old[i].CloseDate.month() == Q1)
                            || (Trigger.old[i].CloseDate.month() == Q2) 
                            || (Trigger.old[i].CloseDate.month() == Q3)
                            || (Trigger.old[i].CloseDate.month() == Q4)
                            */
                            )
                        {
                            Trigger.new[i].Close_Date_Moved__c = true;  
                        } 
                        else {
                            if ((months == 2) 
                                && ((Trigger.old[i].CloseDate.month() + 1 == Q1)
                                || (Trigger.old[i].CloseDate.month() + 1 == Q2) 
                                || (Trigger.old[i].CloseDate.month() + 1 == Q3)
                                || (Trigger.old[i].CloseDate.month() + 1 == Q4)))
                            {
                                Trigger.new[i].Close_Date_Moved__c = true;                     
                            }
                        }                    
                    }
                    else { 
                        System.debug('date more 3>>flag true ....' + months);  
                        Trigger.new[i].Close_Date_Moved__c = true;
                    }                     
                }
                else {
                    if ((Trigger.old[i].CloseDate > Trigger.new[i].CloseDate) && (Trigger.old[i].Close_Date_Moved__c == true) &&(monthsforflg < 12)) {                     

                        if ((System.Today().month()==Q1 || System.Today().month()==(Q1+1)|| System.Today().month()==(Q1+2)) &&
                                (Trigger.new[i].CloseDate.month() == Q1 || Trigger.new[i].CloseDate.month() == (Q1+1) || Trigger.new[i].CloseDate.month() == (Q1+2)))
                              {
                                   inCQflag = true;    
                               }
                        else if ((System.Today().month()==Q2 || System.Today().month()==(Q2+1)|| System.Today().month()==(Q2+2)) &&
                                (Trigger.new[i].CloseDate.month() == Q2 || Trigger.new[i].CloseDate.month() == (Q2+1) || Trigger.new[i].CloseDate.month() == (Q2+2)))
                        {
                                inCQflag = true;    
                        }
                        else if ((System.Today().month()==Q3 || System.Today().month()==(Q3+1)|| System.Today().month()==(Q3+2)) &&
                                (Trigger.new[i].CloseDate.month() == Q3 || Trigger.new[i].CloseDate.month() == (Q3+1) || Trigger.new[i].CloseDate.month() == (Q3+2)))
                        {
                                 inCQflag = true;    
                        }
                        else if ((System.Today().month()==Q4 || System.Today().month()==1 || System.Today().month()==2) &&
                                (Trigger.new[i].CloseDate.month() == Q4 || Trigger.new[i].CloseDate.month() ==  1 || Trigger.new[i].CloseDate.month() == 2))
                        {
                                 inCQflag = true;    
                        }
                    
                         if(inCQflag){
                                    Trigger.new[i].Close_Date_Moved__c = false;    
                                    Trigger.new[i].Close_Date_Moved_Reason__c = '';
                                    Trigger.new[i].Close_Date_Moved_Details__c = '';                             
                         }
                    } 


                }//else                                      
            }
        }
    }
}