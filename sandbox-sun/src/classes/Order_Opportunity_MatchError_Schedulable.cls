/**
* This class defines the logic for  opportunity matching Error Scheduler class 
 *
* @author Rajiv Gangra <rgangra@DELOITTE.com>
* @version 2015-05-20
* 2015-05-07 - initial version
*/
global class Order_Opportunity_MatchError_Schedulable implements Schedulable {
   global void execute(SchedulableContext sc) {
      Order_Opportunity_MatchError_Reporting matchingErrorMetrics = new Order_Opportunity_MatchError_Reporting(); 
      database.executebatch(matchingErrorMetrics);
   }
}