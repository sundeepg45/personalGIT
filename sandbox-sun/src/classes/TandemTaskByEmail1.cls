global class TandemTaskByEmail1 implements Messaging.InboundEmailHandler{


    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {

        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
        
        //UATMailBack.createMail(email);
        
        String fromAddress = email.fromAddress;
        String comments = '';

        Task TandemTask=new Task();     
        try
        {
            //integer name_index1=email.plainTextBody.indexOf('Task Name:')+10;
            //integer name_index2=email.plainTextBody.indexOf('\n',name_index1);
            //integer account_index1=email.plainTextBody.indexOf('Account:')+8;
            //integer account_index2=email.plainTextBody.indexOf('\n',account_index1);
            integer accountid_index1=email.plainTextBody.indexOf('AccountId:')+10;
            integer accountid_index2=email.plainTextBody.indexOf('\n',accountid_index1);
            integer subject_index1=email.plainTextBody.indexOf('Subject:')+8;
            integer subject_index2=email.plainTextBody.indexOf('\n',subject_index1);
            integer duedate_index1=email.plainTextBody.indexOf('DueDate:')+8;
            integer duedate_index2=email.plainTextBody.indexOf('\n',duedate_index1);
            integer owner_index1=email.plainTextBody.indexOf('Owner:')+6;
            integer owner_index2=email.plainTextBody.indexOf('.com',owner_index1)+4;
            //integer owner_index2=email.plainTextBody.indexOf('\n',owner_index1);
            
            integer comment_index1 = 0;
            if(email.plainTextBody.indexOf('Comments:') >0)
            {
                comment_index1= email.plainTextBody.indexOf('Comments:')+9;
            }
            
            

            //System.debug('name_index1' + name_index1);
            //System.debug('name_index2' + name_index2);
            System.debug('accountid_index1' + accountid_index1);
            System.debug('accountid_index2' + accountid_index2);
            System.debug('subject_index1' + subject_index1);
            System.debug('subject_index2' + subject_index2);
            System.debug('duedate_index1' + duedate_index1);
            System.debug('duedate_index2' + duedate_index2);
            System.debug('owner_index1' + owner_index1);
            System.debug('owner_index2' + owner_index2);

            //TandemTask.name=email.plainTextBody.substring(name_index1, name_index2);
            System.debug('TandemTask.whatId' + email.plainTextBody.substring(accountid_index1, accountid_index2));
            TandemTask.whatId=(email.plainTextBody.substring(accountid_index1, accountid_index2)).trim();
            
            System.debug('TandemTask.Subject' + email.plainTextBody.substring(subject_index1, subject_index2));
            TandemTask.Subject=email.plainTextBody.substring(subject_index1, subject_index2);
            
            System.debug('TandemTask.strDate' + email.plainTextBody.substring(duedate_index1, duedate_index2)+' 00:00:00');
            String strDate= (email.plainTextBody.substring(duedate_index1, duedate_index2)+' 00:00:00').trim();
            
            /*integer hypen1=strDate.indexOf('-');
            integer hypen2=strDate.indexOf('-',hypen1);
            
            System.debug('hypen1'+hypen1);
            System.debug('hypen2'+hypen2);

            if( hypen1!=4 || hypen2!=7 ){
                result.success = false;
                result.message = 'Invalid date format. Please Provide Date in YYYY-MM-DD format.\n The Mail is not processed. \n Subject: '+email.subject +'\n Body:'+email.plainTextBody;
                return result;
            }

            */
            
            TandemTask.ActivityDate=Date.valueof(strDate);
            
            if(comment_index1 >0){
                comments = email.plainTextBody.substring(comment_index1);
            }
            
            System.debug('OwnerEmail'+(email.plainTextBody.substring(owner_index1, owner_index2)).trim());
            String OwnerEmail=(email.plainTextBody.substring(owner_index1, owner_index2)).trim();
            
            User[] assignto= [Select Email, Id from User where Email=:OwnerEmail and isactive=true  limit 1];
            integer user_size=0;
            user_size=assignto.size();
            if(user_size==0){
                result.success = false;
                result.message = 'User not found for mail id '+OwnerEmail +'\n The Mail is not processed. \n Subject: '+email.subject +'\n Body:'+email.plainTextBody;
                return result;
            }
            else{
                TandemTask.Ownerid=assignto[0].id;
            }
            System.debug('Ownerid'+TandemTask.Ownerid);

            RecordType[] tandem_record_type= [Select Id, Name from RecordType  where Name ='Tandem Task'];
            
            integer rt_size=tandem_record_type.size();
            
            if(rt_size==0){
                result.success = false;
                result.message = 'Tandem Record Type is not Created \n Please Contact to your System Admin';
                return result;
            }
            else{
                TandemTask.RecordTypeId=tandem_record_type[0].id;
            }
            System.debug('RecordTypeId'+TandemTask.RecordTypeId);

            TandemTask.Status='New';
            TandemTask.Priority='Normal';
            TandemTask.Requester__c = fromAddress;

            //Category
            integer category_index1=email.plainTextBody.indexOf('Category:')+9;
            integer category_index2=email.plainTextBody.indexOf('\n',category_index1);
            System.debug('category_index1'+category_index1);
            System.debug('category_index2'+category_index2);
            String category=(email.plainTextBody.substring(category_index1,category_index2)).trim();
            System.debug('category '+category);
            if(Util.TandemTask_Category.contains(category)){
                TandemTask.category__c=category;
            }
            System.debug('TandemTask.category__c'+TandemTask.category__c);

            
            TandemTask.Description = comments;
            
            Task[] newTask = new Task[0];   
            newTask.add(TandemTask);
            insert newTask;
            
            
            // Return the result for the Apex Email Service
              result.success = true;
              return result;
        }

        catch (System.StringException e){
            return catchError('StringException Occured while Create Tandem Task Mail Processing '+e+'\n Mail Subject: '+email.subject +'\n Body:'+email.plainTextBody);
            
        }   
        catch (System.QueryException e) {
            return  catchError('QueryException occured while Create Tandem Task Mail Processing '+e+'\n Mail Subject: '+email.subject +'\n Body:'+email.plainTextBody);
             
        }
        catch (System.DMLException e) {
            return  catchError('DMLException occured while Create Tandem Task Mail Processing '+e+'\n Mail Subject: '+email.subject +'\n Body:'+email.plainTextBody);
        }
        catch (System.TypeException e) {
             return catchError('Invalid date format. Please Provide Date in YYYY-MM-DD format.');
        }

    }

    private Messaging.InboundEmailResult catchError(String message){
         Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
         result.success = false;
         result.message = message;
         return result;

    }
  
}