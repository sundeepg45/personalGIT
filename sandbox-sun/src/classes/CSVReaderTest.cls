/**
* Class Name:CSVReaderTest
* Description: Test Class created for CSVReader business Class
* Modificaton History:
* Modified By :Nitesh Dokania
* Modified date :9/15/2011
* Reason for Modification:Test coverage enhanced and assert statements are also added.
*/

@IsTest
private class CSVReaderTest {
    public static testmethod void testProcess_Unquoted() {
        String s = '';
        
        // headers
        s += 'Column0' + ',';
        s += 'Column1' + ',';
        s += '\n';
        
        // test data
        s += 'Record0 Column0' + ',';
        s += 'Record0 Column1' + ',';
        s += '\n';
        
        s += 'Record1 Column0' + ',';
        s += 'Record1 Column1' + ',';
        s += '\n';
        
        test.startTest();
                
        List<Map<String, String>> processedCSV = CSVReader.process(s);
        
        test.stopTest();
        
        System.assertEquals(2, processedCSV.size(), processedCSV);

        System.assertEquals(2, processedCSV.get(0).size(), processedCSV);
        System.assertEquals('Record0 Column0', processedCSV.get(0).get('Column0'), processedCSV);
        System.assertEquals('Record0 Column1', processedCSV.get(0).get('Column1'), processedCSV);

        System.assertEquals(2, processedCSV.get(1).size(), processedCSV);
        System.assertEquals('Record1 Column0', processedCSV.get(1).get('Column0'), processedCSV);
        System.assertEquals('Record1 Column1', processedCSV.get(1).get('Column1'), processedCSV);
    }

    public static testmethod void testProcess_Attachment() {
        
        String s = '';
        
        // headers
        s += 'Column0' + ',';
        s += 'Column1' + ',';
        s += '\n';
        
        // test data
        s += 'Record0 Column0' + ',';
        s += 'Record0 Column1 ""' + ',';
        s += '\n';
        
        s += 'Record1 Column0' + ',';
        s += 'Record1 Column1' + ',';
        s += '\n';
        
        Account acc= new Account(Name='Test Account');
        insert acc;
        
        Attachment testatt = new Attachment();
        testatt.Name = 'Attachment';
        testatt.ParentId = acc.Id;
        testatt.Body = Blob.valueOf(s);
        insert testatt;
        
        test.startTest();
        
        List<Map<String, String>> processedCSV = CSVReader.process(testatt);
        
        test.stopTest();
        
        System.assertEquals(2, processedCSV.size(), processedCSV);

        System.assertEquals(2, processedCSV.get(0).size(), processedCSV);
        System.assertEquals('Record0 Column0', processedCSV.get(0).get('Column0'), processedCSV);
        System.assertEquals('Record0 Column1 "', processedCSV.get(0).get('Column1'), processedCSV);

        System.assertEquals(2, processedCSV.get(1).size(), processedCSV);
        System.assertEquals('Record1 Column0', processedCSV.get(1).get('Column0'), processedCSV);
        System.assertEquals('Record1 Column1', processedCSV.get(1).get('Column1'), processedCSV);
    }
    
    public static testmethod void testProcess_Document() {
        
        String s = '';
        
        // headers
        s += 'Column0' + ',';
        s += 'Column1' + ',';
        s += '\n';
        
        // test data
        s += 'Record0 Column0' + ',';
        s += 'Record0 Column1' + ',';
        s += '\n';
        
        s += 'Record1 Column0' + ',';
        s += 'Record1 Column1' + ',';
        s += '\n';
        
        Folder folder = [Select f.Type, f.Name, f.AccessType, f.Id From Folder f where Type='Document' limit 1];
        
        Document doc = new Document();
        doc.Body = Blob.valueOf(s);
        doc.Name = 'Test Doc';
        doc.FolderId = folder.Id;
        insert doc;
        
        test.startTest();
        
        List<Map<String, String>> processedCSV = CSVReader.process(doc);
        
        test.stopTest();
        
        System.assertEquals(2, processedCSV.size(), processedCSV);

        System.assertEquals(2, processedCSV.get(0).size(), processedCSV);
        System.assertEquals('Record0 Column0', processedCSV.get(0).get('Column0'), processedCSV);
        System.assertEquals('Record0 Column1', processedCSV.get(0).get('Column1'), processedCSV);

        System.assertEquals(2, processedCSV.get(1).size(), processedCSV);
        System.assertEquals('Record1 Column0', processedCSV.get(1).get('Column0'), processedCSV);
        System.assertEquals('Record1 Column1', processedCSV.get(1).get('Column1'), processedCSV);
    }
    
    public static testmethod void testProcess_EmbeddedQuotes() {
        String s = '';
        
        // headers
        s += 'Column0' + ',';
        s += 'Column1' + ',';
        s += 'Column2';
        s += '\n';
        
        // test data
        s += '"Expected ""Data"""' + ',';
        s += 'Expected ""Data""' + ',';
        s += '"""Expected Data"""';
        s += '\n';
                
        test.startTest();
        
        List<Map<String, String>> processedCSV = CSVReader.process(s); 
        
        system.assertEquals(1, processedCSV.size(), processedCSV);

        system.assertEquals(3, processedCSV.get(0).size(), processedCSV);
        system.assertEquals('Expected "Data"', processedCSV.get(0).get('Column0'), processedCSV);
        system.assertEquals('Expected "Data"', processedCSV.get(0).get('Column1'), processedCSV);
        system.assertEquals('"Expected Data"', processedCSV.get(0).get('Column2'), processedCSV);
        
        test.stopTest();
    }
}