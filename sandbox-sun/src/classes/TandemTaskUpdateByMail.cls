global class TandemTaskUpdateByMail implements Messaging.InboundEmailHandler{


    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {

        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
        
        
        Task TandemTask=new Task();     
        try
        {
            Integer Mail_End_index=100;

            if(email.plainTextBody.indexof('======')!=-1){
                Mail_End_index=email.plainTextBody.indexof('======');
            }
            if(email.plainTextBody.indexof('Assign To')!=-1 && Mail_End_index > email.plainTextBody.indexof('Assign To')){
                return doReassign(email);
            }
            else if(email.plainTextBody.indexof('Resolved')!=-1 && Mail_End_index > email.plainTextBody.indexof('Resolved') ){
                return doResolved(email);
            }
            else{
                return catchError('Operation does not recognized. Please reply with Assign To:<Owner email> or Resolved.');
            }
            
        }

        catch (System.StringException e){}
        
        
        result.success = true;

        // Return the result for the Apex Email Service
              return result;

        }
         
        public Messaging.InboundEmailResult doReassign(Messaging.InboundEmail email){
            try
            {
                System.debug('hi inside doREasssing');

                integer owner_index1=email.plainTextBody.indexOf('Assign To:')+10;
                System.debug('owner_index1 = ' + owner_index1);
                integer owner_index2=email.plainTextBody.indexOf('\n',owner_index1);
                System.debug('owner_index2 = ' + owner_index2);
                
                //integer comment_index1=email.plainTextBody.indexOf('Comment:')+8;
                //System.debug('comment_index1 = ' + comment_index1);
                
                integer taskid_index1=email.subject.indexof('#[')+2;
                integer taskid_index2=email.subject.indexof(']');
                
                String taskid=(email.subject.substring(taskid_index1,taskid_index2)).trim();
                System.debug('taskid = ' + taskid);
                String ownermail=email.plainTextBody.substring(owner_index1,owner_index2).trim();
                        
                System.debug('ownermail = ' + ownermail);
                
                /*String comment;
                if(comment_index1==7){
                    comment='';
                }
                else{
                    integer comment_index2=email.plainTextBody.indexOf('\n',comment_index1);
                    comment=email.plainTextBody.substring(comment_index1,comment_index2);
                }
                */
                
                Task tk=[Select id, ownerid,description from task where id=:taskid  limit 1];
                User owner = null;
                try
                {
                owner=[Select id, name from user where email=:ownermail and isactive=true limit 1];
                }
                catch(Exception e){}
                if(owner == null) return catchError('Invalid Owner Email Id.');

                //ID ownerid=owner.id;
                System.debug('owner = ' + owner.name);

                //tk.Description=tk.Description +'  '+comment;
                tk.ownerid=owner.id;
                
                System.debug('owner.id '+tk.ownerid);
                //System.debug('tk.Description'+tk.Description);

                Task[] updateTask = new Task[0];    
                updateTask.add(tk);
                update updateTask;

                System.debug('updated ' );
                
                

                // Return the result for the Apex Email Service
                Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
                result.success = true;
                return result;
                
            }
            catch (System.StringException e){ 
                return catchError('String Exception '+e);
            }       
            catch (System.QueryException e) {
                return catchError('Query Exception '+e);
            }
            catch (System.Exception e) {
                return catchError('Exception '+e);
            }

        }

        Messaging.InboundEmailResult doResolved(Messaging.InboundEmail email){
            try
            {
                /*
                String comment;
                integer comment_index1=email.plainTextBody.indexOf('Comment:')+8;
                System.debug('comment_index1='+comment_index1);
                
                if(comment_index1==7){
                    comment='';
                }
                else{
                    integer comment_index2=email.plainTextBody.indexOf('\n',comment_index1);
                    comment=email.plainTextBody.substring(comment_index1,comment_index2);
                }
                */
                integer taskid_index1=email.subject.indexof('#[')+2;
                integer taskid_index2=email.subject.indexof(']');
                
                String taskid=(email.subject.substring(taskid_index1,taskid_index2)).trim();
                
                
                Task tk=[Select id,status,ownerid,description from task where id=:taskid  limit 1];
                
                System.debug('tk.id='+tk.id);

                //tk.Description=tk.Description +'  '+comment ;
                tk.status='Completed';
                
                Task[] updateTask = new Task[0];    
                updateTask.add(tk);
                update updateTask;
                System.debug('updated');

                // Return the result for the Apex Email Service
                Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
                result.success = true;
                return result;
                
                
            }
            catch (System.StringException e){ 
                return catchError('String Exception '+e);
            }       
            catch (System.QueryException e) {
                return catchError('Query Exception '+e);
            }

        
        }

    private Messaging.InboundEmailResult catchError(String message){
        
         Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
         result.success = false;
         result.message = message;
         return result;

    }

        

    }