global class CSVWriter {
    public static String process(List<Map<String, String>> data) {
        Set<String> columnSet = new Set<String>();
        
        for(Map<String, String> recordMap : data)
            columnSet.addAll(recordMap.keySet());
        
        return process(data, new List<String>(columnSet));
    }
    
    public static String process(List<SObject> objectData, List<String> columnList) {
        List<Map<String, String>> recordData = new List<Map<String, String>>();
        
        for(SObject record : objectData) {
            Map<String, String> recordMap = new Map<String, String>();
            
            for(String columnName : columnList)
                recordMap.put(columnName, String.valueOf(record.get(columnName)));
                
            recordData.add(recordMap);
        }
        
        return process(recordData, columnList);
    }
    
    public static String process(List<Map<String, String>> recordData, List<String> columnList) {
        String processedCSV = '';
        
        if (true) { // balance
            for(String columnName : columnList)
                processedCSV += '"' + escape(columnName) + '",';
            processedCSV += '\n';
        }
        
        for(Map<String, String> recordMap : recordData) {
            for(String columnName : columnList)
                processedCSV += '"' + escape(recordMap.get(columnName)) +'",';
            processedCSV += '\n';
        }
        
        return processedCSV;
    }

    private static String escape(String value) {
        if (value == null || value == '')
            return '';
        if (value.contains('"'))
            value = value.replace('"', '""');
        if (value.contains('\r\n'))
            value = value.replace('\r\n', '|');
        if (value.contains('\n'))
            value = value.replace('\n', '|');
        return value;
    }
}