/**
* Class Name:RequestTrackerOperation
* Modificaton History:
* Modified By : Nitesh Dokania
* Modified date : 1/27/2012
* Reason for Modification: Removed hardcoded environment url and replaced it with variable that stores the respective environment url. By doing
                            this whenever any sandbox get refreshed next time we don't need to updated the hardcoded production url. 
*/

global class RequestTrackerOperation implements Messaging.InboundEmailHandler{

Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();

global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {

    Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
    
    //UATMailBack.createMail(email);
        
    System.debug('AutoReply:'+ email.subject.indexOf('AutoReply:'));    
    if(email.subject.indexOf('AutoReply:')!=-1 ){   
                
        System.debug('doEventNewRequest:');
        doEventNewRequest(email,'','');
        System.debug('done');
    }
    /*else if(email.plainTextBody.indexOf('Transaction: Taken by')!=-1 ||
        email.plainTextBody.indexOf('Transaction: Given to')!=-1 ||
        email.plainTextBody.indexOf('Transaction: Owner forcibly changed')!=-1 ||
        email.plainTextBody.indexOf('Transaction: Stolen from')!=-1 ){

            doEventAssignTo(email);
    }
    else if(email.plainTextBody.indexOf('Transaction: Status changed to')!=-1){

        doEventStatusChange(email);
    }*/
    else if(email.subject.indexOf('Resolved:')!=-1){
        
        doEventCloseRequest(email);
    }
    else{
        
        doEventAssignTo(email);
        //new MailServiceFailuerNotification().sendMail(null,'Request Tracker :- Operation is not recognized ',email);

    }
        
    // Return the result for the Apex Email Service
    //result.success = true;
    return result;
}

    
    public void doEventNewRequest(Messaging.InboundEmail email,String assign,String status){
        String msg='';
        try
        {

            // Get index for a

            Request_Tracker__c pt =new Request_Tracker__c();

            integer RT_Originator_index =email.plainTextBody.indexOf('Requester:')+10;
            System.debug('RT_Originator_index  '+RT_Originator_index);
            msg=msg+1;

            integer RT_Originator_index1 =0;
            String created_by='';
            if(RT_Originator_index!=9){
                RT_Originator_index1 =email.plainTextBody.indexOf('\n',RT_Originator_index);
                created_by= email.plainTextBody.substring( RT_Originator_index,RT_Originator_index1);
            }

            System.debug('RT_Originator_index1  '+ RT_Originator_index1);
            msg=msg+2;

            integer subject_index1=email.subject.indexOf('#')+1;
            System.debug('subject_index1  '+ subject_index1);
            msg=msg+3;

            integer subject_index2=email.subject.indexOf(']');
            System.debug('subject_index2  '+subject_index2);
            msg=msg+4;

            integer subject_index3=email.subject.indexOf('AutoReply:')+10;
            System.debug('subject_index3  '+ subject_index3);
            msg=msg+5;
            if(subject_index3==9){
                subject_index3=+subject_index2;
            }

            integer subject_index4=email.subject.length();
            
            /*  
                updated this class as part of Feb App Main Release - RH-00139664 - 01/27/2012
                Changes done to make URL independent of the hardcode environment URL. Going forward "sfdcurl" variable will be used to get the
                environment url.
                Scott Coleman <scoleman@redhat.com> 06/05/2012 reverted change to hard coded value because sfdcurl not returning expected value in production (case RH-00163341)
            */
            // -- Start--
            //integer id_index1=email.plainTextBody.indexOf(util.sfdcUrl)+util.sfdcUrl.length();
            //integer id_index1=email.plainTextBody.indexOf('https://cs2.salesforce.com/')+27;
            integer id_index1=email.plainTextBody.indexOf('https://na4.salesforce.com/')+27;
            //integer id_index1=email.plainTextBody.indexOf('https://tapp0.salesforce.com/')+29;
            // -- End --
            if(id_index1==28){
                //result.success = false;
                //result.message='SFDC Opportunity Link not found \n\n The Mail Body as \n'+email.plainTextBody;
                new MailServiceFailuerNotification().sendMail(null,'Request Tracker :- SFDC Link not found ',email);
                return;
            }
            
            integer id_index2=email.plainTextBody.indexOf('\n',id_index1);
            if(id_index2==-1){
                id_index2=email.plainTextBody.length();
            }
            String id=(email.plainTextBody.substring(id_index1,id_index2 )).trim();
            System.debug('id***** '+id);
            msg=msg+9;
            
            

            //check for account
            if(id.startsWith('001')){
                pt.Account__c=id;
            }
            //check for opportunity
            else if(id.startsWith('006')){
                pt.Opportunity__c=id;
            }
            // check for contact 
            else if(id.startsWith('003')){
                pt.Contact__c=id;
            }

            //pt.Opportunity_Number__c='288932';
            //email.plainTextBody.substring(opp_number_index,opp_url_index-7 );
            //Opportunity opp = [Select Id From Opportunity Where opportunityNumber__c =: pt.Opportunity_Number__c  limit 1 ];
            //pt.Opportunity__c=opp.id;
            System.debug('Opportunity__c  '+ pt.Opportunity__c);
            
            pt.Created_by_in_RT__c=created_by;
            
            String rt_no=email.subject.substring( subject_index1,subject_index2);
            pt.Name=rt_no;
            System.debug('pt.Created_by_in_RT__c  '+ pt.Created_by_in_RT__c);
            
            pt.Subject__c= getSubject(email);
            System.debug('pt.Subject__c'+ pt.Subject__c);
            
            if(assign==''){
                pt.Assign_To__c='Unassigned';
            }else{
                pt.Assign_To__c=assign;
            }

            if(status==''){
                pt.Status__c='New';
            }else{
                pt.Status__c=status;
            }
            
            pt.Comments__c='Ticket URL: https://rt.corp.redhat.com:443/rt3/Ticket/Display.html?id='+rt_no+'   SelfService URL: https://rt.corp.redhat.com:443/rt3/SelfService/Display.html?id='+rt_no;
                        
             // insert in RT

             Request_Tracker__c[] newRequestTracker= new Request_Tracker__c[0];
        
            newRequestTracker.add(pt);
            insert newRequestTracker;
            System.debug('inserted');
                            
        }
        catch (System.StringException e){
            new MailServiceFailuerNotification().sendMail(e,'Request Tracker',email);
        }
        catch (System.QueryException e) { 
            new MailServiceFailuerNotification().sendMail(e,'Request Tracker',email);
        }

    }
    public void doEventAssignTo(Messaging.InboundEmail email){

        try
        {
            // Get index for a
            Request_Tracker__c[] rt=new Request_Tracker__c[0];

            integer assign_to_index1 =email.plainTextBody.indexOf('Owner:')+6;
            System.debug('assign_to_index1  '+ assign_to_index1);
            integer assign_to_index2 =email.plainTextBody.indexOf('.com' , assign_to_index1)+4;
            integer assign_to_index3 =email.plainTextBody.indexOf('\n' , assign_to_index1);
            if(assign_to_index3<assign_to_index2){
                assign_to_index2=assign_to_index3;
            }
            String assignto=email.plainTextBody.substring(assign_to_index1,assign_to_index2);
            
            integer status_index1 =email.plainTextBody.indexOf('Status:')+7;
            integer status_index2 =email.plainTextBody.indexOf('\n',status_index1);
            String status=email.plainTextBody.substring(status_index1,status_index2).trim();
                                
            integer subject_index1=email.subject.indexOf('#')+1;
            integer subject_index2=email.subject.indexOf(']');
            
            String RT_Ticket_No=email.subject.substring( subject_index1,subject_index2);
            
            System.debug('RT_Ticket_No'+RT_Ticket_No);

            rt= [Select Name,Assign_To__c,Status__c from Request_Tracker__c where Name=:RT_Ticket_No];
            boolean isCreated=false;
            for(Request_Tracker__c request :rt){
                if(rt.size()==1){
                    isCreated=true;
                }else{
                    isCreated=false;
                }

            }

            if(isCreated){
                
                rt[0].Assign_To__c=email.plainTextBody.substring(assign_to_index1,assign_to_index2);
                if(status=='resolved' ){
                    rt[0].status__c='Closed';
                }else{
                    rt[0].status__c=status;                 
                }
                rt[0].Subject__c= getSubject(email);

                System.debug('pt.Assign_To__c  '+ rt[0].Assign_To__c);
                

                rt[0].Comments__c='Ticket URL: https://rt.corp.redhat.com:443/rt3/Ticket/Display.html?id='+RT_Ticket_No+'  SelfService URL: https://rt.corp.redhat.com:443/rt3/SelfService/Display.html?id='+RT_Ticket_No;

                 // update RT
                //Request_Tracker__c[] oldRequestTracker= new Request_Tracker__c[0];
                try {
                    //oldRequestTracker.add(rt);
                    //update oldRequestTracker;
                    update rt;
                    System.debug('updated ');
                }
                catch (System.QueryException e1) {
                    new MailServiceFailuerNotification().sendMail(e1,'Request Tracker',email);
                }
            }else{
                doEventNewRequest(email,assignto,status);       
            }
                        
        }
        catch (System.StringException e2){
            new MailServiceFailuerNotification().sendMail(e2,'Request Tracker',email);
        }

    }

    public void doEventStatusChange(Messaging.InboundEmail email){

        try
        {
            // Get index for a
            
            Request_Tracker__c[] rt=new Request_Tracker__c[0];

            integer status_index1 =email.plainTextBody.indexOf('Status:')+7;
            integer status_index2 =email.plainTextBody.indexOf('\n',status_index1);
        
            integer subject_index1=email.subject.indexOf('#')+1;
            integer subject_index2=email.subject.indexOf(']');
            
            String RT_Ticket_No=(email.subject.substring( subject_index1,subject_index2)).trim();
            
            rt= [Select Name,Assign_To__c,Status__c from Request_Tracker__c where Name=:RT_Ticket_No];
            boolean isCreated=false;
            for(Request_Tracker__c request :rt){
                if(rt.size()==1){
                    isCreated=true;
                }else{
                    isCreated=false;
                }

            }

            if(isCreated){
                //pt.Assign_To__c=email.plainTextBody.substring(assign_to_index1,assign_to_index2);
                rt[0].Status__c=email.plainTextBody.substring(status_index1,status_index2);
                
                rt[0].Comments__c='Ticket URL: https://rt.corp.redhat.com:443/rt3/Ticket/Display.html?id='+RT_Ticket_No+'   SelfService URL: https://rt.corp.redhat.com:443/rt3/SelfService/Display.html?id='+RT_Ticket_No;

                rt[0].Subject__c= getSubject(email);
                

                 // update RT
                //Request_Tracker__c[] oldRequestTracker= new Request_Tracker__c[0];
                try {
                    //oldRequestTracker.add(pt);
                    update rt;
                }
                catch (System.QueryException e1) {
                    new MailServiceFailuerNotification().sendMail(e1,'Request Tracker',email);
                }
            }else{
                doEventNewRequest(email,'',email.plainTextBody.substring(status_index1,status_index2));     
            }
                
        }
        catch (System.StringException e2){
            new MailServiceFailuerNotification().sendMail(e2,'Request Tracker',email);
        }

    }
     
  public void doEventCloseRequest(Messaging.InboundEmail email){

        try
        {   
            
        
            Request_Tracker__c[] rt=new Request_Tracker__c[0];  
            
            integer subject_index1=email.subject.indexOf('#')+1;
            integer subject_index2=email.subject.indexOf(']');
            
            String RT_Ticket_No=(email.subject.substring( subject_index1,subject_index2)).trim();
            
            rt= [Select Name,Assign_To__c,Status__c from Request_Tracker__c where Name=:RT_Ticket_No];
            boolean isCreated=false;
            for(Request_Tracker__c request :rt){
                if(rt.size()==1){
                    isCreated=true;
                }else{
                    isCreated=false;
                }

            }
            
            if(isCreated){
                
                rt[0].Status__c='Closed';
                rt[0].Subject__c= getSubject(email);
                
                 // update RT
                //Request_Tracker__c[] oldRequestTracker= new Request_Tracker__c[0];
                try {
                    //oldRequestTracker.add(pt);
                    update rt;
                }
                catch (System.QueryException e1) {
                    new MailServiceFailuerNotification().sendMail(e1,'Request Tracker',email);
                }
            }else{
                doEventNewRequest(email,'','Closed');       
            }
                        
        }
        catch (System.StringException e2){
            new MailServiceFailuerNotification().sendMail(e2,'Request Tracker',email);
        }

    }

    private String getSubject(Messaging.InboundEmail email){
            
            integer subject_index2=email.subject.indexOf(']')+1;
            System.debug('subject_index2  '+subject_index2);
            

            integer subject_index3=email.subject.indexOf('AutoReply:')+10;
            System.debug('subject_index3  '+ subject_index3);
            
            if(subject_index3==9){
                subject_index3=subject_index2;
            }

            integer status_index1 =email.plainTextBody.indexOf('Status:')+7;
            integer status_index2=6;
            String status='';
            if(status_index1!=6){
                status_index2=email.plainTextBody.indexOf('\n',status_index1);
                status=email.plainTextBody.substring(status_index1,status_index2).trim();
                System.debug('Hi status is '+status);
            }
            integer subject_index4=0;
            System.debug('Hi status is '+status);
            if(status!=''){
                String subjectEnd='- '+status+'/';
                System.debug('subjectEnd  '+ subjectEnd);
                subject_index4= email.subject.indexOf(subjectEnd);
                System.debug('subject_index4  '+ subject_index4);
            }
            else{
                subject_index4=email.subject.length();
            }
            if(subject_index4==-1){
                subject_index4=email.subject.length();
            }
            String subject= email.subject.substring(subject_index3,subject_index4);
            
            System.debug('Hi subject is '+subject);
            return subject;
    } 
    
}