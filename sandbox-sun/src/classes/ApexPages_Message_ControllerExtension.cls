public with sharing class ApexPages_Message_ControllerExtension {
	public static String testString = '';
	public final ApexPages.StandardController controller;

	public ApexPages_Message_ControllerExtension(ApexPages.StandardController stdController) {
		controller = stdController;
	}
	
	public static List<ApexPages.Message> getMessages(ApexPages.Severity severity) {
		List<ApexPages.Message> messages = new List<ApexPages.Message>();
		for(ApexPages.Message message : ApexPages.getMessages()) {
			if (message.getSeverity() == severity) {
				messages.add(message);
			}
		}
		return messages;
	}

	public static List<ApexPages.Message> getErrorMessages() {
		return getMessages(ApexPages.Severity.ERROR);
	}

	public static List<ApexPages.Message> getInfoMessages() {
		return getMessages(ApexPages.Severity.INFO);
	}

	public static List<ApexPages.Message> getWarningMessages() {
		return getMessages(ApexPages.Severity.WARNING);
	}

	public static void addMessage(String message, ApexPages.Severity severity) {
		ApexPages.addMessage(new ApexPages.Message(severity, testString+message));
	}

	public static void addErrorMessage(String message) {
		addMessage(message,ApexPages.Severity.ERROR);
	}

	public static void addInfoMessage(String message) {
		addMessage(message,ApexPages.Severity.INFO);
	}

	public static void addWarningMessage(String message) {
		addMessage(message,ApexPages.Severity.WARNING);
	}

	public Boolean getHasErrorMessages() {
		return ApexPages.hasMessages(ApexPages.Severity.ERROR);
	}
}