@isTest(SeeAllData=true)
private class LogSwarmTest {

    @isTest static void testInfo() {
        LogSwarm log = new LogSwarm('test_module', 'test_function');
        log.push('accountid', '00100000001');
        log.info('start of test');
    }

    @isTest static void testError() {
        LogSwarm log = new LogSwarm('test_module', 'test_function');
        log.error('something erroneous happened');
    }

    @isTest static void testException() {
        LogSwarm log = new LogSwarm('test_module', 'test_function');
        try {
            Account acct = [select Id from Account where Name = 'testexception()'];
        }
        catch (QueryException ex) {
            log.exception(ex);
        }
    }

    @isTest static void testPushedException() {
        LogSwarm log = new LogSwarm('test_module', 'test_function');
        try {
            Account acct = [select Id from Account where Name = 'testpushedexception()'];
        }
        catch (QueryException ex) {
            log.pushException(ex).error('exception bad, very bad');
        }
    }
}