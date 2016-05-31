global class ProjectTrackerOperation implements Messaging.InboundEmailHandler{


Project_Tracker__c pt=new Project_Tracker__c();
String msg=' ';
String Opportunity_Number='';

global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {

    Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
    
    //UATMailBack.createMail(email);

    if(email.subject.indexOf('GPS Paperwork Uploaded')!=-1){

        doEventPaperworkCreated(email);

    }
    else if(email.subject.indexOf('Allocation')!=-1){

        doEventAllocation(email);
    }
    else if(email.subject.indexOf('New Status')!=-1){
 
        doEventStatusChange(email);
    }else{
        new MailServiceFailuerNotification().sendMail(null,'Project Tracker :- Operation is not recognized ',email);
    }

         // insert in PT

         Project_Tracker__c[] newProjectTracker= new Project_Tracker__c[0];
        
    
        try {
                newProjectTracker.add(pt);
                if(pt.Opportunity__c!=null){
                    insert newProjectTracker;
                }

            }
        catch (System.QueryException e) {
            new MailServiceFailuerNotification().sendMail(e,'Project Tracker ',email);
        }catch (System.DmlException e) {
            new MailServiceFailuerNotification().sendMail(e,'Project Tracker ',email);
        }

            

            // Return the result for the Apex Email Service
            result.success = true;
            return result;
        }

        
        public void doEventPaperworkCreated(Messaging.InboundEmail email){

            try
            {
                
                // Get index for a
                integer user_index1=email.plainTextBody.indexOf('User:')+5;
                integer user_index2=email.plainTextBody.indexOf('\n',user_index1);
                
                msg=msg+' user_index1 '+user_index1;
                msg=msg+' user_index2 '+user_index2;
                 
                

                integer comment_index1=email.plainTextBody.indexOf('Comment:')+8;
                //integer comment_index2=email.plainTextBody.length();
                msg=msg+' comment_index1 '+comment_index1;

                
                
                integer url_index1=email.plainTextBody.indexOf('URL:')+4;
                integer url_index2=email.plainTextBody.indexOf('\n',url_index1);

                msg=msg+' url_index1 '+url_index1;
                msg=msg+' url_index2 '+url_index2;

                integer opp_number_index1=email.subject.indexOf('#')+1;
                integer opp_number_index2=email.subject.indexOf(']');
                
                msg=msg+' opp_number_index1 '+opp_number_index1;
                msg=msg+' opp_number_index2 '+opp_number_index2;
                
                Opportunity_Number=email.subject.substring(opp_number_index1,opp_number_index2 );
                System.debug('Opportunity_Number '+Opportunity_Number);
                Opportunity opp;
                try{
                    opp = [Select Id From Opportunity Where opportunityNumber__c =: Opportunity_Number  limit 1 ];
                }
                catch(System.QueryException e){
                    new MailServiceFailuerNotification().sendMail(null,'Project Tracker: No such Opportunity ',email);
                    return;
                }
                pt.Opportunity__c=opp.id;
                pt.Status__c='Completed';
                pt.Comments__c=email.plainTextBody.substring(url_index1,url_index2) + email.plainTextBody.substring(comment_index1) ;
                pt.Name='GPS Paperwork Uploaded';
                pt.Consultant__c='';
                pt.Date_range__c='';
                pt.User__c=email.plainTextBody.substring(user_index1,user_index2);
                
                msg=msg+' pt.Opportunity__c '+pt.Opportunity__c;


            }
            catch (System.StringException e){
                new MailServiceFailuerNotification().sendMail(e,'Project Tracker ',email);
            }
            catch (System.QueryException e){
                new MailServiceFailuerNotification().sendMail(e,'Project Tracker ',email);
            }catch (System.DmlException e) {
            new MailServiceFailuerNotification().sendMail(e,'Project Tracker ',email);
        }


        }
        
        public void doEventAllocation(Messaging.InboundEmail email){

            try
            {
                // Get index for a
                integer user_index1=email.plainTextBody.indexOf('User:')+5;
                integer user_index2=email.plainTextBody.indexOf('\n',user_index1);
                
                integer consultant_index1=email.plainTextBody.indexOf('Consultant:')+11;
                integer consultant_index2=email.plainTextBody.indexOf('\n',consultant_index1);

                integer date_range_index1=email.plainTextBody.indexOf('Date:')+5;
                integer date_range_index2=email.plainTextBody.indexOf('\n',date_range_index1);
                
                integer url_index1=email.plainTextBody.indexOf('URL:')+4;
                integer url_index2=email.plainTextBody.indexOf('\n',url_index1);

                integer opp_number_index1=email.subject.indexOf('#')+1;
                integer opp_number_index2=email.subject.indexOf(']');

                
                
                Opportunity_Number=email.subject.substring(opp_number_index1,opp_number_index2);
                Opportunity opp;
                try{
                     opp = [Select Id From Opportunity Where opportunityNumber__c =: Opportunity_Number  limit 1 ];
                }
                catch(System.QueryException e){
                    new MailServiceFailuerNotification().sendMail(null,'Project Tracker: No such Opportunity ',email);
                    return;
                }
                
                pt.Opportunity__c=opp.id;
                pt.Status__c='Completed';
                pt.Comments__c=email.plainTextBody.substring(url_index1,url_index2);
                pt.Name=email.subject.substring(opp_number_index2+1,email.subject.length());
                pt.Consultant__c=email.plainTextBody.substring(consultant_index1,consultant_index2);
                pt.Date_range__c=email.plainTextBody.substring(date_range_index1,date_range_index2);
                pt.User__c=email.plainTextBody.substring(user_index1,user_index2);

            }
            catch (System.StringException e){
                new MailServiceFailuerNotification().sendMail(e,'Project Tracker ',email);
            }
            catch (System.QueryException e){
                new MailServiceFailuerNotification().sendMail(e,'Project Tracker ',email);
            }catch (System.DmlException e) {
            new MailServiceFailuerNotification().sendMail(e,'Project Tracker ',email);
        }



        }

        public void doEventStatusChange(Messaging.InboundEmail email){

            try
            {
                // Get index for a
                integer user_index1=email.plainTextBody.indexOf('User:')+5;
                integer user_index2=email.plainTextBody.indexOf('\n',user_index1);
                
                integer status_index1=email.plainTextBody.indexOf('New Status:')+11;
                integer status_index2=email.plainTextBody.indexOf('\n',status_index1);
                
                integer url_index1=email.plainTextBody.indexOf('URL:')+4;
                integer url_index2=email.plainTextBody.indexOf('\n',url_index1);

                integer opp_number_index1=email.subject.indexOf('#')+1;
                integer opp_number_index2=email.subject.indexOf(']');

                integer comment_index1=email.plainTextBody.indexOf('Comment:')+8;
                //integer comment_index2=email.plainTextBody.length();
                                
                Opportunity_Number=email.subject.substring(opp_number_index1,opp_number_index2 );
                
                Opportunity opp;
                try{
                    opp = [Select Id From Opportunity Where opportunityNumber__c =: Opportunity_Number  limit 1 ];
                }
                catch(System.QueryException e){
                    new MailServiceFailuerNotification().sendMail(null,'Project Tracker: No such Opportunity ',email);
                    return;
                }
                pt.Opportunity__c=opp.id;
                pt.Status__c=email.plainTextBody.substring(status_index1,status_index2);
                pt.Comments__c=email.plainTextBody.substring(url_index1,url_index2) + email.plainTextBody.substring(comment_index1) ;
                pt.Name='Status Changed';
                pt.Consultant__c='';
                pt.Date_range__c='';
                pt.User__c=email.plainTextBody.substring(user_index1,user_index2);

            }
            catch (System.StringException e){
                new MailServiceFailuerNotification().sendMail(e,'Project Tracker ',email);
            }
            catch (System.QueryException e){
                new MailServiceFailuerNotification().sendMail(e,'Project Tracker ',email);
            }catch (System.DmlException e) {
            new MailServiceFailuerNotification().sendMail(e,'Project Tracker ',email);
        }


        }

}