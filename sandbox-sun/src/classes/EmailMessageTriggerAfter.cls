/**
 * This class should contain the implementation for all EmailMessage after triggers.  The
 * processTrigger method is invoked by the EmailMessage_After trigger and in turn invokes
 * all the methods of this class.  This gives us a way to control the order in
 * which the code logic is invoked, as well as allowing other class features such
 * as shared data, constant values, and regorious test coverage.
 * <p>
 * The Trigger object should never be directly referenced inside this class, as
 * that would make it impossible to substituting values inside test methods.
 * </p>
 *
 * @version 2014-07-08
 * @author Scott Coleman <scoleman@redhat.com>
 * 2014-07-08 - Created
 */
 public without sharing class EmailMessageTriggerAfter extends AbstractTrigger {
	/** BooleanSetting__c key to enable hierarchy data maintenance */
	public static final String CREATE_CASE_COMMENT_SETTING = 'EmailMessage_After.CreateCaseComment';

	private final Map<Id,EmailMessage> oldMap = new Map<Id,EmailMessage>();
	private final Map<Id,EmailMessage> newMap = new Map<Id,EmailMessage>();
	// note: isUndelete == true => isInsert == true
	private Boolean isUndelete;

	/**
	 * Typical TriggerBefore type constructor
	 *
	 * @param xoldMap the mapping of old values
	 * @param xnewMap the mapping of new values
	 */
	public EmailMessageTriggerAfter(Map<Id,EmailMessage> xoldMap,Map<Id,EmailMessage> xnewMap,Boolean isUndelete) {
		super(xoldMap,null,xnewMap);
		this.isUndelete = isUndelete;
		if(xoldMap != null) {
			oldMap.putAll(xoldMap);
		}
		if(xnewMap != null) {
			newMap.putAll(xnewMap);
		}
	}

	/**
	 * Trigger class responsible for echoing case email message into a case comment.
	 */
	public void createCaseComment() {
		if(isInsert) {
			try {
				// build set of parent ids
				Set<Id> parentIds = new Set<Id>();
				for(EmailMessage msg : newMap.values()) {
					parentIds.add(msg.ParentId);
				}

				// build map of relevant parent cases
				// TODO: move origin values to config if/when we get a request to extend this to other groups of cases
				Map<Id, Case> caseMap = new Map<Id, Case>([SELECT Id, Origin FROM Case WHERE Id in :parentIds AND Origin = 'GOSS-Request']);

				// generate comments
				List<CaseComment> comments = new List<CaseComment>();
				for(EmailMessage msg : newMap.values()) {
					if(caseMap.containsKey(msg.ParentId) && msg.textbody != null) {
						Case caze = caseMap.get(msg.ParentId);

						// put from/to info at top of comment
						String commentBody = '';
						if(msg.FromAddress != null) {
							commentBody += 'From: ' + msg.FromAddress + '\n';
						}

						if(msg.ToAddress != null) {
							String toAddress = msg.ToAddress;
							if(toAddress.length() > 200) {
								toAddress = toAddress.left(200) + '...';
							}
							commentBody += 'To: ' + toAddress + '\n';
						}

						if(msg.CcAddress != null) {
							String ccAddress = msg.CcAddress;
							if(ccAddress.length() > 200) {
								ccAddress = ccAddress.left(200) + '...';
							}				
							commentBody += 'Cc: ' + ccAddress + '\n';
						}
						
						if(commentBody != '') {
							commentBody += '\n';
						}
						
						// try to suppress quoted email lines when possible
						Pattern quotePattern = Pattern.compile('On.+at.+wrote:');
						List<String> lines = msg.TextBody.split('\n', 0);
						for(String line: lines) {
							if(line.startsWith('----- Original Message -----') || quotePattern.matcher(line).matches()) {
								break;
							}
							if(!line.startsWith('>') && !line.contains('no-reply-sfa@redhat.com')) {
								commentBody += line + '\n';
							}
						}

						// case comments can only be 4000 chars
						comments.add(new CaseComment(ParentId = caze.Id, CommentBody = commentBody.left(4000)));
					}
				}

				// insert comments
				insert comments;
			}
			catch(Exception ex) {
				System.Debug(ex.getMessage());
			}
		}
	}

	/**
	 * This method is called to invoke all the trigger methods.
	 *
	 * @param xoldMap normally assigned from Trigger.oldMap
	 * @param xnewMap normally assigned from Trigger.newMap
	 */
	public static void processTrigger(Map<Id,EmailMessage> xoldMap,Map<Id,EmailMessage> xnewMap,Boolean isUndelete) {
		final EmailMessageTriggerAfter afterTrigger = new EmailMessageTriggerAfter(xoldMap,xnewMap,isUndelete);
		if(AbstractTrigger.isActive(CREATE_CASE_COMMENT_SETTING,true)) {
			afterTrigger.createCaseComment();
		}
		AbstractTrigger.processTriggerComplete();
	}
}