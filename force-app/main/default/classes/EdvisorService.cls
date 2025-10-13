public with sharing class EdvisorService {
    private static final String NAMED_CREDENTIAL = 'Edvisor';
    private static final String apiKey = [SELECT ApiKey__c FROM EdvisorConfig__mdt LIMIT 1].ApiKey__c;

    public static EdvisorDTO.SchoolStudentEnrollmentResumedList fetchSchoolStudentEnrollmentResumedList() {
        //Query GraphQL
        String graphqlQuery = String.join(new List<String>{
            'query SchoolStudentEnrollmentResumedList {',
            '  schoolStudentEnrollmentResumedList(',
            '    pagination:{limit: 1000,offset:0}',
            '  ){',
            '    applications{ studentEnrollmentId created }',
            '  }',
            '}'
        }, '\n');
        
        String requestBody = JSON.serialize(new Map<String,String>{ 'query' => graphqlQuery });

        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:' + NAMED_CREDENTIAL);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + apiKey);
        req.setBody(requestBody);

        Http http = new Http();

        try {
            HttpResponse res = http.send(req);

            if (res.getStatusCode() == 200) {
                Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());

                if (root.containsKey('data')) {
                    Map<String, Object> data = (Map<String, Object>) root.get('data');

                    String resumedListJson = JSON.serialize(data.get('schoolStudentEnrollmentResumedList'));

                    return (EdvisorDTO.SchoolStudentEnrollmentResumedList) JSON.deserialize(resumedListJson, EdvisorDTO.SchoolStudentEnrollmentResumedList.class);
                } else {
                    System.debug('Resposta JSON sem chave "data": ' + res.getBody());
                    return null;
                }
            } else {
                System.debug('Erro HTTP: ' + res.getStatusCode() + ' - ' + res.getBody());
                return null;
            }
        } catch(Exception e) {
            System.debug('Erro no callout para Edvisor: ' + e.getMessage());
            return null;
        }
    }

    public static List<String> getIds(Datetime startDate, Datetime endDate) {
        EdvisorDTO.SchoolStudentEnrollmentResumedList result = fetchSchoolStudentEnrollmentResumedList();

        List<String> ids = new List<String>();
        if (result != null && result.applications != null) {
            for (EdvisorDTO.Application app : result.applications) {
                if (app.created != null) {
                    try {
                        Datetime createdAt = Datetime.valueOfGmt(app.created.replace('T', ' ').replace('Z', ''));
                        
                        if (createdAt >= startDate && createdAt <= endDate) {
                            ids.add(app.studentEnrollmentId);
                        }
                    } catch(Exception e) {
                        System.debug('Erro: ' + app.created + ' (' + e.getMessage() + ')');
                    }
                }
            }
        }
        return ids;
    }

    public static Map<String, Object> fetchStudentEnrollmentReceived(String enrollmentId) {
       String graphqlQuery = String.join(new List<String>{
            'query StudentEnrollmentReceived {',
            '  studentEnrollmentReceived(studentEnrollmentId: ' + enrollmentId + ') {',
            '    studentEnrollmentId',
            '    studentEnrollmentStatusId',
            '    studentEnrollmentDecisionStatusId',
            '    schoolId',
            '    studentId',
            '    languageId',
            '    obscuredId',
            '    studentSignature',
            '    signedDate',
            '    specialInstructions',
            '    created',
            '    modified',
            '    agencyOwnerId',
            '    schoolOwnerId',
            '    sent',
            '    isDeletedByAgency',
            '    isDeletedBySchool',
            '    netInvoiceFileId',
            '    grossInvoiceFileId',
            '    letterOfAcceptanceFileId',
            '    studentEnrollmentOfferingItems {',
            '      ... on StudentEnrollmentOfferingCourseItem {',
            '        studentEnrollmentOfferingItemId',
            '        studentEnrollmentId',
            '        offeringTypeId',
            '        durationAmount',
            '        durationTypeId',
            '        startDate',
            '        endDate',
            '        created',
            '        modified',
            '        courseSnapshot {',
            '          offeringId',
            '          offeringCourseCategoryId',
            '          name',
            '        }',
            '      }',
            '    }',
            '    studentEnrollmentStatus {',
            '      studentEnrollmentStatusId',
            '      codeName',
            '      position',
            '    }',
            '    student {',
            '      nationalityId',
            '      firstname',
            '      lastname',
            '      email',
            '      birthdate',
            '      studentId',
            '      preferredName',
            '      phone',
            '      address',
            '      gender',
            '      passportNumber',
            '      visaTypeId',
            '      postalCode',
            '      nationality {',
            '        countryId',
            '        code',
            '        continent',
            '        currencyId',
            '        languageId',
            '        nameTranslationId',
            '        nameTranslation',
            '      }',
            '    }',
            '    agency {',
            '      agencyId',
            '      agencyCompanyId',
            '      name',
            '      phone',
            '      address',
            '      city',
            '      postalCode',
            '      email',
            '      websiteUrl',
            '    }',
            '  }',
            '}'
        }, '\n');

        String requestBody = JSON.serialize(new Map<String, String>{ 'query' => graphqlQuery });

        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:' + NAMED_CREDENTIAL);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + apiKey);
        req.setBody(requestBody);

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 200) {
            Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            return (Map<String, Object>) ((Map<String, Object>) root.get('data')).get('studentEnrollmentReceived');
        } else {
            System.debug('Erro na chamada GraphQL: ' + res.getStatusCode() + ' - ' + res.getBody());
            return null;
        }
    }

    public static void syncEnrollments(List<String> enrollmentIds) {
        for (String id : enrollmentIds) {
            Map<String, Object> enrollmentData = fetchStudentEnrollmentReceived(id);
            if (enrollmentData != null) {
                upsertOpportunity(enrollmentData);
            }
        }
    }

    public static void upsertOpportunity(Map<String, Object> enrollmentData) {
        String studentEnrollmentId = String.valueOf(enrollmentData.get('studentEnrollmentId'));
        Map<String, Object> status = (Map<String, Object>) enrollmentData.get('studentEnrollmentStatus');
        String stage = status != null ? (String) status.get('codeName') : 'Prospecting';

        String endDateStr;
        Date closeDate;
        List<Object> items = (List<Object>) enrollmentData.get('studentEnrollmentOfferingItems');
        if (items != null && !items.isEmpty()) {
            Map<String, Object> firstItem = (Map<String, Object>) items[0];
            endDateStr = (String) firstItem.get('endDate');
        } else {
            endDateStr = (String) enrollmentData.get('endDate');
        }
        closeDate = endDateStr != null ? Date.valueOf(endDateStr.split('T')[0]) : Date.today();

        Map<String, Object> agency = (Map<String, Object>) enrollmentData.get('agency');
        Map<String, Object> school = (Map<String, Object>) enrollmentData.get('school');
        String accountName = agency != null ? (String) agency.get('name') : (school != null ? (String) school.get('name') : null);

        Map<String, Object> student = (Map<String, Object>) enrollmentData.get('student');
        String studentName = student != null ? (String) student.get('firstname') + ' ' + (String) student.get('lastname') : 'N/A';
        String studentEmail = student != null ? (String) student.get('email') : null;

        // Oportunidade
        Opportunity opp = new Opportunity();
        opp.Name = 'Enrollment ' + studentEnrollmentId;
        opp.StageName = stage;
        opp.CloseDate = closeDate;
        opp.Description = 'Student: ' + studentName + ', Email: ' + studentEmail;

       

        // upsert opp;

        System.debug('Opportunity: ' + JSON.serializePretty(opp));
    }




}