@IsTest
private class EdvisorServiceTest {

    // ==========================
    // MOCK PARA SUCESSO PADRÃO
    // ==========================
    private class SuccessMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody('{"data":{"schoolStudentEnrollmentResumedList":{"applications":[{"studentEnrollmentId":"123","created":"2025-09-10T10:00:00Z"},{"studentEnrollmentId":"456","created":"2025-08-05T12:30:00Z"}]}}}');
            return res;
        }
    }

    // =====================================
    // MOCK PARA SUCESSO, MAS SEM CHAVE DATA
    // =====================================
    private class NoDataMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"message":"OK mas sem data"}');
            return res;
        }
    }

    // =============================
    // MOCK PARA ERRO HTTP (500)
    // =============================
    private class ErrorMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"error":"Internal Server Error"}');
            return res;
        }
    }

    // =============================
    // MOCK PARA LANÇAR EXCEÇÃO
    // =============================
    private class ExceptionMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            throw new CalloutException('Erro forçado no callout');
        }
    }

    // ===================================
    // MOCK PARA FETCH STUDENT RECEIVED
    // ===================================
    private class StudentEnrollmentMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            res.setBody(
                '{"data":{"studentEnrollmentReceived":{' +
                '"studentEnrollmentId":"789",' +
                '"studentId":"999",' +
                '"schoolId":"555",' +
                '"created":"2025-09-10T10:00:00Z",' +
                '"studentEnrollmentOfferingItems":[], "studentEnrollmentFiles":[]}}}'
            );
            return res;
        }
    }

    // ==============================
    // TESTE PRINCIPAL - SUCESSO
    // ==============================
    @IsTest
    static void testFetchSchoolStudentEnrollmentResumedList_Success() {
        Test.setMock(HttpCalloutMock.class, new SuccessMock());

        Test.startTest();
        EdvisorDTO.SchoolStudentEnrollmentResumedList result = EdvisorService.fetchSchoolStudentEnrollmentResumedList();
        Test.stopTest();

        System.assertNotEquals(null, result, 'O resultado não deveria ser nulo');
        System.assertEquals(2, result.applications.size(), 'Deveria retornar 2 aplicações');
        System.assertEquals('123', result.applications[0].studentEnrollmentId);
    }

    // ==============================
    // TESTE - RESPOSTA SEM DATA
    // ==============================
    @IsTest
    static void testFetchSchoolStudentEnrollmentResumedList_NoData() {
        Test.setMock(HttpCalloutMock.class, new NoDataMock());

        Test.startTest();
        EdvisorDTO.SchoolStudentEnrollmentResumedList result = EdvisorService.fetchSchoolStudentEnrollmentResumedList();
        Test.stopTest();

        System.assertEquals(null, result, 'Quando não houver chave data o retorno deve ser nulo');
    }

    // ==============================
    // TESTE - ERRO HTTP
    // ==============================
    @IsTest
    static void testFetchSchoolStudentEnrollmentResumedList_Error() {
        Test.setMock(HttpCalloutMock.class, new ErrorMock());

        Test.startTest();
        EdvisorDTO.SchoolStudentEnrollmentResumedList result = EdvisorService.fetchSchoolStudentEnrollmentResumedList();
        Test.stopTest();

        System.assertEquals(null, result, 'Deveria retornar nulo em caso de erro HTTP');
    }

    // ==============================
    // TESTE - EXCEÇÃO NO CALLOUT
    // ==============================
    @IsTest
    static void testFetchSchoolStudentEnrollmentResumedList_Exception() {
        Test.setMock(HttpCalloutMock.class, new ExceptionMock());

        Test.startTest();
        EdvisorDTO.SchoolStudentEnrollmentResumedList result = EdvisorService.fetchSchoolStudentEnrollmentResumedList();
        Test.stopTest();

        System.assertEquals(null, result, 'Quando der exceção o retorno deve ser nulo');
    }

    // ==============================
    // TESTE DO MÉTODO GETIDS
    // ==============================
    @IsTest
    static void testGetIds() {
        Test.setMock(HttpCalloutMock.class, new SuccessMock());

        Datetime startDate = Datetime.newInstance(2025, 8, 1, 0, 0, 0);
        Datetime endDate   = Datetime.newInstance(2025, 10, 1, 0, 0, 0);

        Test.startTest();
        List<String> ids = EdvisorService.getIds(startDate, endDate);
        Test.stopTest();

        System.assertEquals(2, ids.size(), 'Deveria trazer 2 IDs válidos');
        System.assert(ids.contains('123'), 'Deveria conter o ID 123');
    }

    // ==============================================
    // TESTE FETCH STUDENT ENROLLMENT RECEIVED - SUCESSO
    // ==============================================
    @IsTest
    static void testFetchStudentEnrollmentReceived_Success() {
        Test.setMock(HttpCalloutMock.class, new StudentEnrollmentMock());

        Test.startTest();
        Map<String, Object> result = EdvisorService.fetchStudentEnrollmentReceived('789');
        Test.stopTest();

        System.assertNotEquals(null, result, 'O retorno não deveria ser nulo');
        System.assertEquals('789', (String)result.get('studentEnrollmentId'));
    }

    // ==============================================
    // TESTE FETCH STUDENT ENROLLMENT RECEIVED - ERRO HTTP
    // ==============================================
    @IsTest
    static void testFetchStudentEnrollmentReceived_Error() {
        Test.setMock(HttpCalloutMock.class, new ErrorMock());

        Test.startTest();
        Map<String, Object> result = EdvisorService.fetchStudentEnrollmentReceived('123');
        Test.stopTest();

        System.assertEquals(null, result, 'Deveria retornar nulo em caso de erro');
    }
}