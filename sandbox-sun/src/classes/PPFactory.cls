public with sharing class PPFactory {
	public static final String PP_CONTENT = 'Content';
	public static final String PP_EVENT = 'Bulk Uploads';
	public static final String PP_LMS = 'LMS';

	public List<PPScoringPlugin> getPluginList(){
		List<PPScoringPlugin> l = new List<PPScoringPlugin>();
		l.add(getPlugin(PP_CONTENT));
		l.add(getPlugin(PP_EVENT));
		l.add(getPlugin(PP_LMS));
		return l;
	}

	public static PPScoringPlugin getPlugin(String cat) {
		if (cat == PP_CONTENT) {
			return new PPContentPlugin();
		}
		else if (cat == PP_EVENT) {
			return new PPBatchPlugin();
		}
		else if (cat == PP_LMS) {
			return new PPLMSPlugin();
		}
		return null;
	}

	static testmethod void simpleTest() {
		PPFactory.getPlugin(PPFactory.PP_CONTENT);
		PPFactory.getPlugin(PPFactory.PP_EVENT);
		PPFactory.getPlugin(PPFactory.PP_LMS);
	}

}