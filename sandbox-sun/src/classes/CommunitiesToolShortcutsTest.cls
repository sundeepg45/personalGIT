@isTest (seeAllData=true)
private class CommunitiesToolShortcutsTest {
	
	@isTest static void testShortcuts() {
		DeactivateAllTestUtil.setDeactivateAll(false);

		User u = CommunitiesTestUtils.createGenericUser();
		CommunitiesTestUtils.createToolShortcuts();

		system.runAs(u){
			CommunitiesToolShortcuts cts = new CommunitiesToolShortcuts();
			cts.shortcutWrappers[0].checked = true;
			cts.save();
		}
	}
}