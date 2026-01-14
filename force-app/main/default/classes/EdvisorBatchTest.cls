@IsTest
private class EdvisorBatchTest {
    // Mock para callouts do EdvisorService
    private class EdvisorServiceMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);

            if (req.getBody() != null && req.getBody().contains('schoolStudentEnrollmentResumedList')) {
                res.setBody(
                    '{"data":{"schoolStudentEnrollmentResumedList":{"count":1,"applications":[{"studentEnrollmentId":110014,"studentEnrollmentStatus":"PENDING","created":"2025-09-09T12:23:24Z","sentToSchool":"2025-09-09T12:24:54Z","campus":"Dorset College Dublin","agency":"Dorset College - Advisor 1","agencyLogoUrl":null,"schoolId":21043,"schoolCompanyId":7689,"startDate":"2025-09-15T00:00:00Z","endDate":"2026-04-03T00:00:00Z","student":{"studentId":5544532,"firstName":"Alessandro","lastName":"Teste Setembro","email":"vecxel@gmail.com"}}]}}}'
                );
            } else if (req.getBody() != null && req.getBody().contains('studentEnrollmentReceived')) {
                // Adiciona o campo studentEnrollmentFiles ao JSON
                res.setBody(
                    '{"data":{"studentEnrollmentReceived":{' +
                        '"studentEnrollmentId":110014,' +
                        '"studentEnrollmentStatusId":3,' +
                        '"studentEnrollmentDecisionStatusId":1,' +
                        '"schoolId":21043,' +
                        '"studentId":5544532,' +
                        '"languageId":1,' +
                        '"obscuredId":"dbd0cca8e9a2cefb5b77bee54c5632f3",' +
                        '"studentSignature":null,' +
                        '"signedDate":"2025-09-09T12:24:07Z",' +
                        '"specialInstructions":null,' +
                        '"created":"2025-09-09T12:23:24Z",' +
                        '"modified":"2025-09-09T12:24:54Z",' +
                        '"agencyOwnerId":30991,' +
                        '"schoolOwnerId":null,' +
                        '"sent":null,' +
                        '"isDeletedByAgency":false,' +
                        '"isDeletedBySchool":false,' +
                        '"netInvoiceFileId":null,' +
                        '"grossInvoiceFileId":null,' +
                        '"letterOfAcceptanceFileId":null,' +
                        '"studentEnrollmentOfferingItems":[' +
                        '{' +
                        '"studentEnrollmentOfferingItemId":175066,' +
                        '"studentEnrollmentId":110014,' +
                        '"offeringTypeId":1,' +
                        '"durationAmount":25,' +
                        '"durationTypeId":3,' +
                        '"startDate":"2025-09-15",' +
                        '"endDate":"2026-04-03",' +
                        '"created":"2025-09-09T12:24:52Z",' +
                        '"modified":"2025-09-09T12:24:52Z",' +
                        '"courseSnapshot":{' +
                        '"offeringId":1997782,' +
                        '"offeringCourseCategoryId":9,' +
                        '"name":"Work & Study GE Morning 15 H/W"' +
                        '}' +
                        '}' +
                        '],' +
                        '"school":{' +
                        '"schoolId":21043,' +
                        '"schoolCompanyId":7689,' +
                        '"schoolTypeId":1,' +
                        '"name":"Dorset College Dublin",' +
                        '"isDeleted":0,' +
                        '"created":"2024-05-28T14:00:30Z",' +
                        '"modified":"2025-03-11T21:27:12Z",' +
                        '"photoId":93813,' +
                        '"phone":"+353 (01) 5746850",' +
                        '"email":"info@dorset.ie",' +
                        '"website":"https://dorset.ie/",' +
                        '"address":"8 Belvedere Pl, Mountjoy, Dublin 1, D01 EV27, Irlanda",' +
                        '"instituteNumber":null,' +
                        '"googlePlaceId":"ChIJL6wn6oAOZ0gRoHExl6nHAAo",' +
                        '"countryId":95,' +
                        '"courseHolidayRuleTypeId":1,' +
                        '"accommodationHolidayRuleTypeId":3,' +
                        '"includeAutoHolidays":0,' +
                        '"autoHolidayCountryId":35,' +
                        '"currencyId":43,' +
                        '"twitter":null,' +
                        '"facebook":"https://www.facebook.com/dorsetcollege/",' +
                        '"instagram":"https://www.instagram.com/dorsetcollegedublin/",' +
                        '"youtube":"https://www.youtube.com/channel/UCxLJ1AKUMuPvyhTWMH05q2Q",' +
                        '"schoolBannerFileId":3411181,' +
                        '"featuredVideoUrl":"https://www.youtube.com/watch?v=iGzRYWhzcjE",' +
                        '"walkscore":null,' +
                        '"mapUrl":null,' +
                        '"defaultLanguageId":1,' +
                        '"termsAndConditions":"<p>...</p>",' +
                        '"paymentPolicies":"<p>...</p>",' +
                        '"canAcceptStudentEnrollments":true' +
                        '},' +
                        '"studentEnrollmentFields":[{"codeName":"NOTES","value":"Arquivos em anexo...teste"},{"codeName":"FIRSTNAME","value":"Alessandro"},{"codeName":"LASTNAME","value":"Teste Setembro"},{"codeName":"EMAIL","value":"vecxel@gmail.com"},{"codeName":"BIRTHDATE","value":"1981-04-05"},{"codeName":"NATIONALITY_ID","value":"29"}],' +
                        '"studentEnrollmentFiles":[' +
                        '{' +
                        '"file":{' +
                        '"url":"https://example.com/file1.pdf",' +
                        '"name":"file1.pdf"' +
                        '}' +
                        '},' +
                        '{' +
                        '"file":{' +
                        '"url":"https://example.com/file2.pdf",' +
                        '"name":"file2.pdf"' +
                        '}' +
                        '}' +
                        '],' +
                        '"studentEnrollmentStatus":{"studentEnrollmentStatusId":3,"codeName":"PENDING","position":2},' +
                        '"agency":{"agencyId":10611,"name":"Dorset College - Advisor 1"},' +
                        '"student":{"studentId":5544532,"firstname":"Alessandro","lastname":"Teste Setembro","email":"vecxel@gmail.com","birthdate":"1981-04-05T00:00:00Z"}' +
                        '}}}'
                );
            }
            // else if (req.getBody() != null && req.getBody().contains('studentEnrollmentFiles')) {
            //     // Mock para busca de arquivos
            //     res.setBody(
            //         '{"data":{"studentEnrollmentFiles":[' +
            //             '{' +
            //                 '"file":{' +
            //                     '"url":"https://example.com/file1.pdf",' +
            //                     '"name":"file1.pdf"' +
            //                 '}' +
            //             '},' +
            //             '{' +
            //                 '"file":{' +
            //                     '"url":"https://example.com/file2.pdf",' +
            //                     '"name":"file2.pdf"' +
            //                 '}' +
            //             '}' +
            //         ']}}'
            //     );
            // }
            else {
                // fallback mínimo
                res.setBody('{"data":{}}');
            }
            return res;
        }
    }

    @IsTest(SeeAllData=true)
    static void testExecute_InsertsNewApplicationsAndEnqueuesQueueable() {
        Test.setMock(HttpCalloutMock.class, new EdvisorServiceMock());

        // Desliga o enqueue de arquivos durante o teste (não vamos exercitar a cadeia de FileQueueable aqui)
        EdvisorEnrollmentQueueable.disableFileEnqueueInTest = true;

        Test.startTest();
        delete [SELECT Id FROM EdvisorApplication__c];
        Datetime nowTime = System.now();
        Datetime fiveMinAgo = nowTime.addMinutes(-5);
        Database.executeBatch(new EdvisorBatch(fiveMinAgo, nowTime));
        Test.stopTest();

        List<EdvisorApplication__c> apps = [SELECT Id, StudentEnrollmentId__c, ProcessingStatus__c FROM EdvisorApplication__c];
        System.assertEquals(1, apps.size(), 'It should have created 1 EdvisorApplication__c');
    }
}