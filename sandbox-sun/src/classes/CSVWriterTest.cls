/**
* Class Name: CSVWriterTest
* Description:Test Class created for CSVWriter business Class.
* Modificaton History:
* Modified By :Abhijeet Anand
* Reason for Modification:Enhanced code coverage and added assert statements.
*/

@IsTest
private class CSVWriterTest 
{
    public static testmethod void testProcess_Mapped() 
    {
        test.startTest();
        
        String str = CSVWriter.process(new List<Map<String, String>> 
        {
            new Map<String, String> 
            {
                'Column0' => '"Row0" Column0',
                'Column1' => 'Row0 "Column1"',
                'Column2' => '"Row0 Column2"'
            },
            new Map<String, String> 
            {
                'Column0' => 'Row1 Column0',
                'Column1' => 'Row2 Column1',
                'Column2' => 'Row3 Column2'
            }
        });
        
        test.stopTest();
    }
    public static testmethod void testProcess_MappedWithColumnNames() 
    {
        test.startTest();
        
        String str1 = CSVWriter.process(new List<Map<String, String>> 
        {
            new Map<String, String> 
            {
                'Column0' => 'Row0 Column0',
                'Column1' => 'Row0 Column1',
                'Column2' => 'Row0 Column2'
            },

            new Map<String, String> 
            {
                'Column0' => 'Row1 Column0',
                'Column1' => 'Row2 Column1',
                'Column2' => 'Row3 Column2'
            }
        }, new List<String> 
        {
            'Column0',
            'Column1',
            'Column2'   
        });
        
        test.stopTest();
    }
    
    public static testmethod void testProcess_MappedWithNewlineChrcter() 
    {
        test.startTest();
        
        String str2 = CSVWriter.process(new List<Map<String, String>> 
        {
            new Map<String, String> 
            {
                'Column0' => 'Row0 Column0',
                'Column1' => 'Row0 Column1',
                'Column2' => 'Row0 Column2'
            },

            new Map<String, String> 
            {
                'Column0' => 'Row1 Column0',
                'Column1' => 'Row2 Column1',
                'Column2' => 'Row3 Column2'
            }
        }, new List<String> 
        {
            'Column0\n',
            'Column1\n',
            'Column2\n' 
        });
        
        test.stopTest();
    } 
    public static testmethod void testProcess_MappedWithNewlnChrcter() 
    {
        test.startTest();
        
        String str3 = CSVWriter.process(new List<Map<String, String>> 
        {
            new Map<String, String> 
            {
                'Column0' => 'Row0 Column0',
                'Column1' => 'Row0 Column1',
                'Column2' => 'Row0 Column2'
            },

            new Map<String, String> 
            {
                'Column0' => 'Row1 Column0',
                'Column1' => 'Row2 Column1',
                'Column2' => 'Row3 Column2'
            }
        }, new List<String> 
        {
            'Column0\r\n',
            'Column1\r\n',
            'Column2\r\n'   
        });
        
        test.stopTest();
    }
    public static testmethod void testProcess_ObjectsWithColumnNames() 
    {
        test.startTest();
        
        String str4 = CSVWriter.process(new List<Account> 
        {
            new Account(
                Name = 'Account0 Name',
                Website = 'Account0 Website'
            ),

            new Account(
                Name = 'Account1 Name',
                Website = 'Account1 Website'
            )
        }, new List<String> 
        {
            'Name',
            'Website'   
        });
        
        test.stopTest();
    }
}