/**
* Class Name:Lead_ManageForDLTTest
* Description:Test Class written to cover Lead_ManageForDLT class.
* Modificaton History:
* Modified By :Nitesh Dokania
* Modified date :6/6/2011
* Reason for Modification: Test Class updated to enhance the code coverage of Lead_ManageForDLT class.
*/

@IsTest
private class Lead_ManageForDLTTest {
    public static testmethod void testGetImportListSize() {
        new Lead_ManageForDLT().getImportListSize();
    }

    public static testmethod void testGetImportSuccesListSize() {
        new Lead_ManageForDLT().getImportSuccessListSize();
    }

    public static testmethod void testGetImportFailureListSize() {
        new Lead_ManageForDLT().getImportFailureListSize();
    }

    public static testmethod void testGetParam() {
        new Lead_ManageForDLT().getParam('');
    }

    public static testmethod void testPutParam() {
        new Lead_ManageForDLT().putParam('', '');
    }

    public static testmethod void testGetMinimumCreatedDate() {
        new Lead_ManageForDLT().getMinimumCreatedDate();
    }

    public static testmethod void testGetMaximumCreatedDate() {
        new Lead_ManageForDLT().getMaximumCreatedDate();
    }

    public static testmethod void testGetMinimumLastModifiedDate() {
        new Lead_ManageForDLT().getMinimumLastModifiedDate();
    }

    public static testmethod void testGetMaximumLastModifiedDate() {
        new Lead_ManageForDLT().getMaximumLastModifiedDate();
    }

    public static testmethod void testGetLeadSourceDetailIsLike_WhenNotEmpty() {
        Lead_ManageForDLT leadInstance = new Lead_ManageForDLT();
        leadInstance.exportLeadSource = 'Test%Test';
        leadInstance.getLeadSourceDetailIsLike();
    }

    public static testmethod void testGetLeadSourceDetailIsLike_WhenEmpty() {
        new Lead_ManageForDLT().getLeadSourceDetailIsLike();
    }

    public static testmethod void testGetLeadSourceDetailIsEqualTo_WhenNotEmpty() {
        Lead_ManageForDLT leadInstance = new Lead_ManageForDLT();
        leadInstance.exportLeadSource = 'Test%Test';
        leadInstance.getLeadSourceDetailIsEqualTo();
    }

    public static testmethod void testGetLeadSourceDetailIsEqualTo_WhenEmpty() {
        new Lead_ManageForDLT().getLeadSourceDetailIsEqualTo();
    }

    //public static testmethod void testGetLeadList() {
    //    new Lead_ManageForDLT().getLeadList();
    //}

    //public static testmethod void testGetLeadListPrefetchSize() {
    //    new Lead_ManageForDLT().getLeadListPrefetchSize();
    //}

    //public static testmethod void testExportDocument() {
    //    new Lead_ManageForDLT().exportDocument();
    //}

    public static testmethod void testImportDocument_WhenMissing() {
        new Lead_ManageForDLT().importDocument();
    }

    public static void testImportDocument() {
        String s = '';

        // headers
        s += 'Id' + ',';
        s += 'Company' + ',';
        s += '\n';

        // test data
        s += '00QP0000002fbUN' + ','; // the actual ID value is never used, and is irrelevant.
        s += 'My Company One' + ',';
        s += '\n';

        s += '00QP0000002fbUN' + ','; // the actual ID value is never used, and is irrelevant.
        s += 'My Company Two' + ',';
        s += '\n';

        String t = '';

        // headers
        t += 'Id' + ',';
        t += 'Company' + ',';
        t += 'LastName' + ',';
        t += '\n';

        // test data
        t += '00QP0000002fbUN' + ','; // the actual ID value is never used, and is irrelevant.
        t += 'My Company One' + ',';
        t += 'RedHat' + ',';
        t += '\n';

        t += '00QP0000002fbUN' + ','; // the actual ID value is never used, and is irrelevant.
        t += 'My Company Two' + ',';
        t += 'RedHat1' + ',';
        t += '\n';

        String x = '';

        // headers
        x += 'Id' + ',';
        x += 'Company' + ',';
        x += '\n';

        // test data
        x += '00QP0000002bUN' + ','; // the actual ID value is never used, and is irrelevant.
        x += 'My Company One' + ',';
        x += '\n';

        x += '00QP0000002bUN' + ','; // the actual ID value is never used, and is irrelevant.
        x += 'My Company Two' + ',';
        x += '\n';

        String y = '';

        // headers
        y += 'Id' + ',';
        y += 'Company' + ',';
        y += '\n';

        // test data
        y += '00QP0000002tbUN' + ','; // the actual ID value is never used, and is irrelevant.
        y += 'My Company One' + ',';
        y += '\n';

        y += '00QP0000002tbUN' + ','; // the actual ID value is never used, and is irrelevant.
        y += 'My Company Two' + ',';
        y += '\n';

        String str = '';

        test.startTest();

        Lead_ManageForDLT leadInstance1 = new Lead_ManageForDLT();
        leadInstance1.importAttachment.Body = Blob.valueOf(t);
        leadInstance1.importAttachment.Name = 'Test Attachment';
        leadInstance1.importDocument();

        Lead_ManageForDLT leadIns = new Lead_ManageForDLT();
        leadIns.importAttachment.Body = Blob.valueOf(x);
        leadIns.importAttachment.Name = 'Test Attachment1';
        leadIns.importDocument();

        Lead_ManageForDLT leadIn = new Lead_ManageForDLT();
        leadIn.importAttachment.Body = Blob.valueOf(y);
        leadIn.importAttachment.Name = 'Test Attachment1';
        leadIn.importDocument();

        Lead_ManageForDLT leadInstance2 = new Lead_ManageForDLT();
        leadInstance2.importAttachment.Name = 'Test Attachment';
        leadInstance2.importDocument();

        Lead_ManageForDLT leadInstance3 = new Lead_ManageForDLT();
        leadInstance3.refreshLeadList();

        Lead_ManageForDLT leadInstance4 = new Lead_ManageForDLT();
        leadInstance4.importAttachment.Body = Blob.valueOf(str);
        leadInstance4.importAttachment.Name = 'Test Attachment';
        leadInstance4.importDocument();

        Lead_ManageForDLT leadInstance = new Lead_ManageForDLT();
        leadInstance.importAttachment.Body = Blob.valueOf(s);
        leadInstance.importDocument();

        test.stopTest();
    }
}