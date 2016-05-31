@isTest(SeeAllData = true)
private class TriggerValidationExceptionTest {

	@isTest static void test() {
		TriggerValidationException controller = new TriggerValidationException();
		String errorMessage = controller.errorMessage;
		Boolean hasRecordId = controller.hasRecordId;
		String recordId = controller.recordId;
		String recordMessage = controller.recordMessage;
	}
}