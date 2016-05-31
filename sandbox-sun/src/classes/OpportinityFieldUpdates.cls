public class OpportinityFieldUpdates
{
    // Rule OM 1.0: Oracle Order Number not NULL
    public void OpportunityIsBooked(Opportunity opp){
        System.debug(opp.DateOrderSubmitted__c);
        System.debug(opp.OracleOrderNumber__c);
        System.debug(opp.DateOrderBooked__c);

        //Rule triggered by the populate of the Oracle Order Number, representing an Order has been booked in oracle.
        if( (opp.DateOrderSubmitted__c!= null) && (opp.OracleOrderNumber__c != null) &&  (opp.DateOrderBooked__c==null)   ){    
            opp.DateOrderBooked__c=system.now();
            opp.RecordTypeId=Util.OpportunityBookedOppRecordTypeId;
            opp.StageName='Closed Booked';
        }
        
    }

    //OM 2.0 Date Order Submitted not NULL
    public void opportuinityClosedWon(Opportunity opp){
        //Rule triggered when Date Order Submitted is not null and Date Order Booked is null. 
        //Date Order Submitted is only populated when the Submit Order button is clicked and the Opportunity has passed all coded validation rules.
        if((opp.DateOrderSubmitted__c != null) && (opp.DateOrderBooked__c == null) ){
            opp.StageName='Closed Won';     
        }
    }
    
    //OM 3.0 Date Order Booked not NULL
    public void opportuinityClosedBooked(Opportunity opp){
        //Rule triggered when Date Order Booked isn't null and Date Order Submitted isn't null either. 
        //Occurs only after the Submit Order button is triggered and all validation rules are skipped.
        if((opp.DateOrderSubmitted__c != null) && (opp.DateOrderBooked__c != null) ){
            opp.StageName='Closed Booked';
            opp.RecordTypeId=Util.OpportunityBookedOppRecordTypeId;
        }
    }


    //OM 4.0 Booked Order Back Out
    public void backoutBookedOrder(Opportunity opp){
        System.debug(opp.DateOrderSubmitted__c);
        System.debug(opp.OracleOrderNumber__c);
        System.debug(opp.DateOrderBooked__c);
        System.debug(opp.TimeTillOrderBooked__c);

        //Date Submitted not null, Date Booked not null, Oracle # is null, Time Till Booked >0
        if((opp.DateOrderSubmitted__c != null) && (opp.DateOrderBooked__c != null) && (opp.OracleOrderNumber__c == null)  ){ //&& (opp.TimeTillOrderBooked__c > 0)
            opp.StageName='Closed Won';
            opp.DateOrderBooked__c=null;    
        }
 
    }
    
    //OM 5.0 Closed Won Back Out
    public void backoutSubmitOrder(Opportunity opp){

        System.debug(opp.DateOrderSubmitted__c);
        System.debug(opp.OracleOrderNumber__c);
        System.debug(opp.DateOrderBooked__c);
        System.debug(opp.TimeTillOrderBooked__c);
        System.debug(opp.StageName);

        //Rule to fire when Closed Won Opp needs to be set back and the Date order Submitted field needs to be cleared. Dt Submitted not null, Dt Booked is null, Stage not closed won or Closed booked, time till booked >0.001
        System.debug('opp.DateOrderSubmitted__c '+opp.DateOrderSubmitted__c);
        System.debug('opp.DateOrderSubmitted__c != null '+opp.DateOrderSubmitted__c != null);
        if((opp.DateOrderSubmitted__c != null) && (opp.DateOrderBooked__c == null) && (opp.StageName != 'Closed Booked' && opp.StageName != 'Closed Won') && (opp.TimeTillOrderBooked__c > 0.001)  ){  
            opp.DateOrderSubmitted__c=null; 
        }

    }   
    
    // Rule Upate close Order date
    public void updateOpportunityCloseDate(Opportunity new_opp,Opportunity old_opp){
        System.debug('new_opp.DateOrderBooked__c '+new_opp.DateOrderBooked__c);     
        System.debug(new_opp.DateOrderSubmitted__c);
        System.debug(new_opp.OracleOrderNumber__c);
        System.debug(new_opp.DateOrderBooked__c);
        System.debug(old_opp.DateOrderBooked__c);
        System.debug(new_opp.TimeTillOrderBooked__c);
        System.debug(new_opp.StageName);

        if( new_opp.FulfillmentChannel__c !=null && new_opp.FulfillmentChannel__c.startsWith('Direct') && new_opp.OracleOrderNumber__c!=null ){
            if(new_opp.DateOrderBooked__c!=null && old_opp.DateOrderBooked__c!= new_opp.DateOrderBooked__c ){
                
                String year =''+(new_opp.DateOrderBooked__c.year());
                String month = ''+new_opp.DateOrderBooked__c.month();
                String day =''+(new_opp.DateOrderBooked__c.day());
                String strdate=year+'-'+month+'-'+day + ' ' +'00:00:00';
                
                System.debug('strdate '+ strdate );
                new_opp.closedate=Date.valueof( strdate );
                
                System.debug('new_opp.DateOrderBooked__c '+new_opp.DateOrderBooked__c);     
                System.debug('new_opp.closedate '+new_opp.closedate);       
                    
            }

        }
    }
}