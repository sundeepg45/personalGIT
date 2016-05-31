/*
* Called from the Send Button on the Reference Collateral
* Creates a new Reference Usage
*/
public class ReferenceUsageController {
    
       
    public Customer_Reference__c cusRefIn;
    
    public Customer_Reference__c getcusRefIn(){
            if(this.cusRefIn==NULL)
                    this.cusRefIn = new Customer_Reference__c();
            return this.cusRefIn;
    }
    
    /*
    * Action method called from the page
    * Creates the new Ref Usage and flips its owner to the owner of the Customer reference
    */
    public PageReference proceed() {           
   
        //PageReference returnRef = null;
        Id custRefId = ApexPages.currentPage().getParameters().get('cid');  
        Id RefColId = ApexPages.currentPage().getParameters().get('rid');   
        
        //Customer_Reference__c cr = [select c.OwnerId from Customer_Reference__c c where c.Id=:custRefId];
        Customer_Reference__c crr = [select Name, c.Account__r.Id, c.Account__c, c.Opportunity__r.Name, 
                c.Opportunity__c, c.Contact__r.Id, c.Contact__c, c.OwnerId  
                from Customer_Reference__c c  
                where c.Id = :custRefId];
        
        Reference_Collateral__c rcc = [select Name, Email_Template_ID__c from Reference_Collateral__c where Id=:RefColId]   ;                           
        
        Reference_Usage__c ru = new Reference_Usage__c();
        ru.Collateral__c = RefColId;
        ru.Opportunity_Supported__c = this.cusRefIn.Opportunity__c;
        ru.Sent_To_Contact__c = this.cusRefIn.Contact__c;
//        ru.RecordTypeId = '012T0000000CxAR';
//        ru.RecordTypeID = [select Id from RecordType where sObjectType = 'Reference_Usage__c' and Name = 'Contact_Request' limit 1].Id;
        ru.Reference__c = custRefId; 
        insert ru; 
//      ru.OwnerId = crr.OwnerId;
//      update ru;
        
            
        String str;
        str = '/email/author/emailauthor.jsp?template_id='+rcc.Email_Template_ID__c+'&new_template=1';
        
        Contact c = [select Id from contact where Id =:this.cusRefIn.Contact__c];
        
        if(c.Id != null) {
             str += '&p2_lkid=' + c.Id;
        }
        
        String refName = rcc.Name;
        str += '&p6= Reference Collateral (' +refName + ') related to' +crr.Name; 
        
        str += '&p3_lkid='+RefColId +'&retURL=%2F'+RefColId;
        
        PageReference prcd = new PageReference(str);  

        prcd.setRedirect(true);     
        return prcd;        
       
    }   
    
    /*
    * Action method called from the page
    * Cancels the current operation
    */
    public PageReference cancel() {
        String url = '/' + System.currentPageReference().getParameters().get('rid');
        PageReference submitCancel = new PageReference(url);  
                     
        submitCancel.setRedirect(true); 
    
        return submitCancel;
    }   
        
}