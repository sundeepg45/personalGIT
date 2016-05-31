/**
 * Renewal_CotermDetailController
 * 
 * @author	   Bryan Bosely <bbosely@redhat.com>
 * @version	  2012-03-06
 * 2010-09-14 - Created
 * Bill C Riemers <briemers@redhat.com>
 * 2012-03-06 - Updated to revert opportunity type.
 */
 
public class Renewal_CotermDetailController extends Renewal_Coterm {
	/**
	 * Constructor
	 */
	public Renewal_CotermDetailController() {
		// set the source opportunity id
		super(ApexPages.currentPage().getParameters().get( 'source' ));
	}
}