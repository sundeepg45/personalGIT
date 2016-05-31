public class DeactivateAllTestUtil {
	public static void setDeactivateAll(Boolean value) {
		System.runAs(new User(Id = UserInfo.getUserId())) {
			BooleanSetting__c deactivateAll = BooleanSetting__c.getValues('DeactivateAll');
			if(deactivateAll != null) {
				deactivateAll.Value__c = value;
				update deactivateAll;
			}
			else {
				deactivateAll = new BooleanSetting__c(
					Name = 'DeactivateAll',
					Value__c = value
				);
				insert deactivateAll;
			}
		}
	}
}