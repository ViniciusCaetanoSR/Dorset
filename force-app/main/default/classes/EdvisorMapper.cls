public without sharing class EdvisorMapper {
    public static Opportunity fromApplication(Map<String, Object> json) {
        System.debug('Iniciando criação de registros...');
        Map<String, Object> studentInfo = (Map<String, Object>) json.get('student');
        List<Object> filesInfo = (List<Object>) json.get('studentEnrollmentFiles');

        Account acc = createAccount(studentInfo);
        Opportunity opp = createOpportunity(acc, json);

        return opp;
    }

    private static Account createAccount(Map<String, Object> studentInfo) {
        System.debug('Iniciando criação de conta...');
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Student').getRecordTypeId();
        String email = stringVal(studentInfo.get('email'));

        Account acc = new Account();
        acc.RecordTypeId = recordTypeId;
        acc.FirstName = String.valueOf(studentInfo.get('firstname'));
        acc.LastName = String.valueOf(studentInfo.get('lastname'));
        acc.PersonEmail = email;
        acc.Email__c = email;
        acc.Email_3__pc = email;
        acc.D_O_B__c = Date.valueOf(String.valueOf(studentInfo.get('birthdate')).split('T')[0]);
        acc.PersonMobilePhone = String.valueOf(studentInfo.get('phone'));
        acc.Country_of_Birth__c = studentInfo.get('nationality') != null
            ? String.valueOf(((Map<String, Object>) studentInfo.get('nationality')).get('nameTranslation'))
            : null;
        acc.Student_Type__c = 'Non EU';

        insert acc;
        return acc;
    }

    private static Opportunity createOpportunity(Account acc, Map<String, Object> json) {
        System.debug('Iniciando criação de application...');
        Map<String, Object> enrollment = (Map<String, Object>) ((List<Object>) json.get('studentEnrollmentOfferingItems')).get(0);
        Map<String, Object> agency = (Map<String, Object>) json.get('agency');
        Map<String, Object> courseSnapshot = (Map<String, Object>) enrollment.get('courseSnapshot');

        Date proposedDate = parseDate(json.get('created'));

        Date startDate = parseDate(enrollment.get('startDate'));
        Date endDate = parseDate(enrollment.get('endDate'));

        String courseName = String.valueOf(courseSnapshot.get('name'));
        String sessionType = extractSessionType(courseName);

        Map<String, Object> productInfo = getProductInfo(startDate, courseName);
        Map<String, Object> agencyInfo = getAgentInfo(stringVal(agency.get('email')));

        Id recordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Student').getRecordTypeId();

        Opportunity opp = new Opportunity(
            RecordTypeId = recordTypeId,
            Name = 'Edvisor - ' + acc.FirstName + ' ' + acc.LastName,
            CloseDate = endDate,
            AccountId = acc.Id,
            StageName = 'APP',
            SessionType__c = sessionType,
            Product__c = (Id) productInfo.get('productId'),
            ProductNumber__c = (String) productInfo.get('productCode'),
            EL_Proposed_Start_Date__c = proposedDate,
            Agent__c = (Id) agencyInfo.get('agencyId'),
            Agent_Email__c = (String) agencyInfo.get('agencyEmail'),
            Product_End_Date2__c = (Date) productInfo.get('productEndDate'),
            WeeksDuration__c = (Decimal) productInfo.get('productDuration') + 'Weeks',
            Insurance_Required__c = true //como vai ficar só NON-EU, todos precisam disso. (é feito de forma manual no cadastro e no edvisor não tem)
        );
        insert opp;
        return opp;
    }

    //colocar em uma service
    private static Map<String, Object> getAgentInfo(String agentEmail) {
        Map<String, Object> result = new Map<String, Object>();
        if (String.isBlank(agentEmail))
            return result;

        Account agency = [
            SELECT Id, Name, Email__c
            FROM Account
            WHERE Email__c = :agentEmail
            LIMIT 1
        ];

        result.put('agencyId', agency.Id);
        result.put('agencyEmail', agency.Email__c);
        return result;
    }

    //colocar em uma service
    private static Map<String, Object> getProductInfo(Date startDate, String courseName) {
        Map<String, Object> result = new Map<String, Object>();

        if (startDate == null) {
            return result;
        }

        String searchPattern = '';
        String formattedCoursename = courseName.toLowerCase();
        String search = '';

        if (formattedCoursename.contains('general english') || formattedCoursename.contains('ge')) {
            searchPattern = '%general english%';
        } else if (formattedCoursename.contains('business english') || formattedCoursename.contains('be')) {
            searchPattern = '%business english%';
        }

        Boolean isSpecialCourse = formattedCoursename.contains('onshore') || formattedCoursename.contains('offshore');

        List<Product2> prods;

        if (isSpecialCourse) {
            if (formattedCoursename.contains('bachelor of business nfq level 7')) {
                searchPattern = '%Bachelor of Business QQI L7 - Year 1 of 3%';
            } else if (formattedCoursename.contains('bachelor of business (honours) in international business degree nfq level 8')) {
                searchPattern = '%Bachelor of Business (Hons) in International Business%';
            } else if (
                formattedCoursename.contains('bsc in computing nfq level 7') || formattedCoursename.contains('bachelor of science in computing nfq level 7')
            ) {
                searchPattern = '%Bachelor of Science in Computing QQI L7 - Year 1 of 3%';
            }

            prods = [
                SELECT Id, Name, ProductCode, Start_Date__c, End_Date__c, Duration__c
                FROM Product2
                WHERE Start_Date__c = :startDate AND Name LIKE :searchPattern
                LIMIT 1
            ];
        } else {
            // filtro por nome e semana/ano
            Integer year = startDate.year();
            Date firstDayOfYear = Date.newInstance(year, 1, 1);
            Integer daysDiff = firstDayOfYear.daysBetween(startDate);
            Integer weekOfYear = (daysDiff / 7) + 1;

            search = searchPattern + '%' + weekOfYear + '_' + year;

            prods = [
                SELECT Id, Name, ProductCode, Start_Date__c, End_Date__c, Duration__c
                FROM Product2
                WHERE Name LIKE :search
                LIMIT 1
            ];
        }

        if (!prods.isEmpty()) {
            result.put('productId', prods[0].Id);
            result.put('productName', prods[0].Name);
            result.put('productCode', prods[0].ProductCode);
            result.put('productStartDate', prods[0].Start_Date__c);
            result.put('productEndDate', prods[0].End_Date__c);
            result.put('productDuration', prods[0].Duration__c);
        }

        return result;
    }

    //colocar em uma service
    private static String extractSessionType(String courseName) {
        if (String.isBlank(courseName)) {
            return 'Neither';
        }

        String lowerName = courseName.toLowerCase();

        if (lowerName.contains('morning')) {
            return 'Morning';
        } else if (lowerName.contains('afternoon')) {
            return 'Afternoon';
        } else {
            return 'Neither';
        }
    }

    // Helpers
    private static String stringVal(Object value) {
        return value != null ? String.valueOf(value) : null;
    }

    private static Date parseDate(Object dateValue) {
        return dateValue != null ? Date.valueOf(String.valueOf(dateValue).split('T')[0]) : null;
    }
}