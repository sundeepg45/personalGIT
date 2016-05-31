@isTest(SeeAllData = true)
private class LMSResyncTest {

    @isTest static void test() {
        List<User> users = [
            select  Id
            from    User
            limit   2
        ];
        LMSResync controller = new LMSResync();
        controller.userId = users[0].Id;
        controller.contentType = '.xls';
        controller.file = Blob.valueOf('Name\n' + users[1].Id + '\n');
        controller.submit();
        controller.contentType = 'text/csv';
        controller.submit();
        controller.updateRequests();
        controller.deleteResyncRequests();
    }
}