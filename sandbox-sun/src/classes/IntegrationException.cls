/**
 * Throw this custom exception in integration code. Set Retry to false
 * to suppress retry in the case that an error is not likely to resolve
 * with repeated attempts. Recommended constructor is:
 *
 * IntegrationException(String message, Exception cause)
 * 
 * @version 2014-07-16
 * @author Scott Coleman <scoleman@redhat.com>
 * 2014-07-16- created
 */
public virtual class IntegrationException extends Exception {}