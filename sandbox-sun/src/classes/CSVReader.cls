global class CSVReader {
    public static List<Map<String, String>> process(Attachment data) {
        return data == null ? new  List<Map<String, String>>() : process(data.Body);
    }

    public static List<Map<String, String>> process(Attachment data, Set<String> requiredHeaders) {
    	return data == null ? new  List<Map<String, String>>() : process(data.Body, requiredHeaders);
    }

    public static List<Map<String, String>> process(Document data) {
        return data == null ? new  List<Map<String, String>>() : process(data.Body);
    }

    public static List<Map<String, String>> process(Document data, Set<String> requiredHeaders) {
    	return data == null ? new  List<Map<String, String>>() : process(data.Body, requiredHeaders);
    }

    public static List<Map<String, String>> process(Blob data) {
        return data == null ? new  List<Map<String, String>>() : process(data.toString());
    }

    public static List<Map<String, String>> process(Blob data, Set<String> requiredHeaders) {
    	return data == null ? new  List<Map<String, String>>() : process(data.toString(), requiredHeaders);
    }
    
    public static List<Map<String, String>> process(String data) {
    	return process(data, null);
    }

    public static List<Map<String, String>> process(String data, Set<String> requiredHeaders) {
        //
        // Build the original patterns and vars
        //
        
        //Pattern fieldPattern = Pattern.compile('("([^"]*|"{2})*"(,|$))|"[^"]*"(,|$)|[^,]+(,|$)|(,)');
        //Pattern fieldPattern = Pattern.compile('(")?(.*?)(\\1)?(,|$)');
        Pattern fieldPattern = Pattern.compile('("?)(.*?)(\\1)(,|$)');
        List<Map<String, String>> processedCSV = new List<Map<String, String>>();
        List<String> headerList = new List<String>();
        Integer groupPos = 2;
            
        //
        // Loop through csv
        //
        
        for(String recordLine : data.split('\n')) {
            Matcher fieldMatcher = fieldPattern.matcher(recordLine);
            
            if (headerList.size() == 0) {
                while (fieldMatcher.find()) { // add all headers
                    headerList.add(unescape(fieldMatcher.group(groupPos)).trim());
                }
                if (requiredHeaders != null && requiredHeaders.size() > 0){
                	for (String header : requiredHeaders){
                		boolean found = false;
                		for (String csvHeader : headerList){
                			if (csvHeader.toLowerCase() == header.toLowerCase()){
                				found = true;
                				break;
                			}
                		}
                		if (!found){
                			throw new DataRequiredException('CSV file is missing required header: ' + header);
                		}
                	}
                }
            } else {
                Map<String, String> columnData = new Map<String, String>();
                Integer column = 0;
                
                while (fieldMatcher.find()) { // add all rows
                	String columnName = headerList.get(column);
                	String columnText = unescape(fieldMatcher.group(groupPos));
                    column++;

                	if (columnName != '') // can't meaningfully import records without field/column names
                        columnData.put(columnName, columnText);
                }
                
                processedCSV.add(columnData);
            }
        }
        
        return processedCSV;
    }
    
    // helper methods
    
    private static String unescape(String value) {
        if (value == null || value == '' || value == '""')
            return '';
        if (Pattern.matches('^".+"$', value))
            value = value.substring(1, value.length() - 1);
        if (value.contains('""'))
            value = value.replace('""', '"');
        return value;
    }
}