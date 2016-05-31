trigger Account_IsPartnerValidation on Account (after update) {
         
      for (Account newAccounts : Trigger.new)
      {
          if (newAccounts.PartnerStatuses__c != null)
          {
              Account old = Trigger.oldMap.get(newAccounts.Id);
              if (old.IsPartner == false && newAccounts.IsPartner == true && newAccounts.PartnerStatuses__c.contains('Unaffiliated') ) {
                  newAccounts.addError('An unaffiliated partner cannot be enabled in the Partner Center Portal');
              }
           }
      }
}