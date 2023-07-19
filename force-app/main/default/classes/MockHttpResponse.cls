@isTest
global class MockHttpResponse implements HttpCalloutMock {
    
    global HTTPResponse respond(HTTPRequest req) {
        
        // Create a fake response
        String strbody = '';
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/text');
        strbody = '{' +
            '"attributes":{"describeUrl":"/services/data/v52.0/analytics/reports/00O03000000JreiEAC/describe","instancesUrl":"/services/data/v52.0/analytics/reports/00O03000000JreiEAC/instances","reportId":"00O03000000JreiEAC","reportName":"test_Roster","type":"Report"}' +
            '} ';
        res.setBody(strBody);
        res.setStatusCode(200);
        return res;
    }
}