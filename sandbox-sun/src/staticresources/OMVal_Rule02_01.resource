function func_rule2_1(){
  var requiredChannels = {
    'Direct - OEM':true,
    'Direct - VAR/VAD':true,
    'Indirect - OEM Preload':true,
    'Indirect - VAR/VAD':true,
    'Direct - Carahsoft':true,
    'Direct - DLT':true,
    'Direct - GTSI':true,
  };
  if(Opportunity.FinancialPartnerName__c.isBlank() && requiredChannels[Opportunity.FulfillmentChannel__c] ) {
    show_error('error2_1');
  }
  rule_executed(2.1);
}
