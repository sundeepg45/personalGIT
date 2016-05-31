public without sharing class LogSwarm {
    public static final String FUNCTION = 'function';
    public static final String MODULE = 'module';

    private Map<String,Object> contextMap = new Map<String,Object>();
    private Exception[] exceptionList = new List<Exception>();
    private String transaction_id = String.valueOf(System.currentTimeMillis());
    private Boolean staticinit = false;
    private String[] debugBatch;
    private static String endpoint;
    private static String user;
    private static String authkey;
    private static Integer level = 0;
    private static Integer calloutLimit = 0;


    public LogSwarm(String mod, String fn) {
        if (mod != null) contextMap.put('module_name', mod);
        if (fn != null) contextMap.put('function_name', fn);
        debugBatch = new List<String>();

        if (!staticinit) {
            LogSwarm__c tmpurl = LogSwarm__c.getInstance('url');
            if (tmpurl == null) {
                return;
            }
            endpoint = LogSwarm__c.getInstance('url').Value__c;
            String strlevel = LogSwarm__c.getInstance('level').Value__c;
            if (strlevel == 'debug') level = 1;
            if (strlevel == 'info') level = 2;
            if (strlevel == 'warn') level = 3;
            if (strlevel == 'error') level = 4;
            if (strlevel == 'fatal') level = 5;
            user = LogSwarm__c.getInstance('user').Value__c;
            authkey = LogSwarm__c.getInstance('key').Value__c;
            calloutLimit = Limits.getLimitCallouts();
            staticinit = true;
        }

        System.debug('***** [debug] ***** endpoint=' + endpoint);
        System.debug('***** [debug] ***** level=' + level);
    }

    public String getTransactionId() {
        return transaction_id;
    }

    public LogSwarm push(String key, Object value) {
        if (level == 0) return this;
        contextMap.put(key, value);
        return this;
    }

    public LogSwarm pushException(Exception ex) {
        if (level > 4) return this;
        exceptionList.add(ex);
        return this;
    }

    public void remove(String key) {
        contextMap.remove(key);
    }

    public void debug(String message) {
        try {
            if (level != 1) return;
            contextMap.put('message', message);
            JSONGenerator gen = createPayload('debug');
            String payload = gen.getAsString();
            debugBatch.add(payload);
//            sendPayload(gen);
        }
        catch (Exception ex) {
            System.debug(ex.getMessage());
        }
    }

    public void info(String message) {
        try {
            if (level > 2) return;
            contextMap.put('message', message);
            JSONGenerator gen = createPayload('info');
            send(gen);
        }
        catch (Exception ex) {
            System.debug(ex.getMessage());
        }

    }

    public void warn(String message) {
        try {
            if (level == 0 || level > 3) return;
            contextMap.put('message', message);
            JSONGenerator gen = createPayload('error');
            send(gen);
        }
        catch (Exception ex) {
            System.debug(ex.getMessage());
        }
    }

    public void error(String message) {
        try {
            if (level > 4) return;
            contextMap.put('message', message);
            JSONGenerator gen = createPayload('error');
            send(gen);
        }
        catch (Exception ex) {
            System.debug(ex.getMessage());
        }
    }

    public void fatal(String message) {
        try {
            contextMap.put('message', message);
            JSONGenerator gen = createPayload('fatal');
            send(gen);
        }
        catch (Exception ex) {
            System.debug(ex.getMessage());
        }
    }

    public void exception(Exception ex) {
        try {
            if (level > 4) return;
            contextMap.put('message', ex.getMessage());
            exceptionList.add(ex);
            JSONGenerator gen = createPayload('error');
            send(gen);
        }
        catch (Exception exc) {
            System.debug(exc.getMessage());
        }
    }

    public void flush() {
        if (Test.isRunningTest()) {
            return;
        }
        if (debugBatch.size() > 0) {
            String payload = PartnerUtil.joinArray(debugBatch, ',');
            if (!System.isFuture()) {
                if (Limits.getDMLStatements() > 0) {
                    // there is a pending DML, can't do a single threaded callout
                    sendPayloadFuture('[\n' + payload + '\n]', endpoint);
                }
                else {
                    sendPayload('[\n' + payload + '\n]', endpoint);
                }
            }
            else {
                if (Limits.getDMLStatements() == 0) {
                    sendPayload('[\n' + payload + '\n]', endpoint);
                }
                else {
                    System.debug(payload);
                }
            }
            debugBatch = new List<String>();
        }
    }

    private void send(JSONGenerator gen) {
        String payload = gen.getAsString();
        if (endpoint == null || Test.isRunningTest() || (calloutLimit - Limits.getCallouts() <= 5)) {
            System.debug('PAYLOAD=' + payload);
        }
        else {
            if (!System.isFuture()) {
                if (Limits.getDMLStatements() > 0) {
                    // there is a pending DML, can't do a single threaded callout
                    sendPayloadFuture(Payload, endpoint);
                }
                else {
                    sendPayload(payload, endpoint);
                }
            }
            else {
                if (Limits.getDMLStatements() == 0) {
                    sendPayload(payload, endpoint);
                }
                else {
                    System.debug(payload);
                }
            }
        }
    }

    @future(callout=true)
    static private void sendPayloadFuture(String payload, String receiver) {
        sendPayload(payload, receiver);
    }

    static private void sendPayload(String payload, String receiver) {
        Http client = new Http();
        HttpRequest request = new HttpRequest();
        request.setTimeout(1500);
        request.setMethod('POST');
        request.setBody(payload);
        request.setEndpoint(receiver);
        request.setHeader('Content-type', 'application/json');
        try {
            client.send(request);
        }
        catch (Exception ex) {
            System.debug('***** [warn] ***** unable to send logswarm payload to ' + receiver);
            System.debug('PAYLOAD=' + payload);
        }
    }

    private JSONGenerator createPayload(String loglevel) {
        JSONGenerator gen = JSON.createGenerator(true);
        if (level == 0) return gen;
        gen.writeStartObject();
            gen.writeStringField('loguser', user);
            gen.writeStringField('authkey', authkey);
            gen.writeFieldName('payload');
            gen.writeStartObject();
                gen.writeStringField('level', loglevel);
                gen.writeIdField('user_id', UserInfo.getUserId());
                gen.writeDateTimeField('event_time', System.now());
                gen.writeStringField('event_tz', 'GMT');  // System.now() returns timestamp in GMT
                gen.writeStringField('host_zone', 'sfdc');
                gen.writeStringField('transaction_id', transaction_id);
                gen.writeFieldName('context_params');
                gen.writeStartObject();
                    buildGraph(gen, contextMap);

                    for (Exception ex : exceptionList) {
                        gen.writeFieldName('stack');
                        gen.writeStartObject();
                            gen.writeFieldName('stack_trace'); gen.writeString(ex.getStackTraceString());
                            gen.writeFieldName('type_name'); gen.writeString(ex.getTypeName());
                            gen.writeFieldNAme('line'); gen.writeObject(ex.getLineNumber());
                        gen.writeEndObject();
                    }
                gen.writeEndObject();
            gen.writeEndObject();
        gen.writeEndObject();
        exceptionList.clear();
        return gen;
    }

    private JSONGenerator buildGraph(JSONGenerator gen, Map<String, Object> dataMap) {
        for (String key : dataMap.keySet()) {
            Object value = dataMap.get(key);
            if (value instanceof Map<String,Object>) {
                gen.writeFieldName(key);
                gen.writeStartObject();
                buildGraph(gen, (Map<String,Object>) value);
                gen.writeEndObject();
            }
            else {
                gen.writeFieldName(key);
                gen.writeString(String.valueOf(value));
            }
        }
        return gen;
    }
}