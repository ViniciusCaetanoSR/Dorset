public without sharing class EdvisorMapper {

    public static Opportunity fromApplication(Map<String, Object> json) {
        Map<String, Object> studentInfo = (Map<String, Object>) json.get('student');
        Account acc = createAccount(studentInfo);

        Opportunity opp = createOpportunity(acc, json);
        return opp;
    }

    private static Account createAccount(Map<String, Object> studentInfo) {
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
            ? String.valueOf(((Map<String, Object>) studentInfo.get('nationality')).get('nameTranslation')) : null;

        insert acc;
        return acc;
    }

    private static Opportunity createOpportunity(Account acc, Map<String, Object> json) {
        Map<String, Object> enrollment = (Map<String, Object>) ((List<Object>) json.get('studentEnrollmentOfferingItems')).get(0);
        Map<String, Object> agency = (Map<String, Object>) json.get('agency');
        Map<String, Object> courseSnapshot = (Map<String, Object>) enrollment.get('courseSnapshot');


        Date startDate = parseDate(enrollment.get('startDate'));
        String startDateFormatted = DateTime.newInstance(startDate.year(), startDate.month(), startDate.day()).format('yyyy-MM-dd');
        Date endDate = parseDate(enrollment.get('endDate'));

        Map<String, Object> productInfo = getProductAndPricebook(stringVal(courseSnapshot.get('offeringId')));
        Map<String, Object> agencyInfo = getAgentInfo(stringVal(agency.get('name')));

        Id recordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Student').getRecordTypeId();

        Opportunity opp = new Opportunity(
            RecordTypeId = recordTypeId,
            Name = 'Edvisor - ' + acc.FirstName + ' ' + acc.LastName + ' - ' + productInfo.get('productName') + ' - ' + startDateFormatted,
            CloseDate = endDate,
            AccountId = acc.Id,
            StageName = 'APP', //confirmar
            SessionType__c = 'Neither', //confirmar
            Product__c = (Id) productInfo.get('productId'),
            Pricebook2Id = (Id) productInfo.get('pricebookId'),
            ProductNumber__c = (String) productInfo.get('productCode'),
            Agent__c = (Id) agencyInfo.get('agencyId'),
            Agent_Email__c = (String) agencyInfo.get('agencyEmail'),
            Product_End_Date2__c = (Date) productInfo.get('productEndDate'),
            Course_Type__c = (Id) productInfo.get('productCourseType'),
            Course_Category__c = (Id) productInfo.get('productCourseCategory'),
            Course__c = (Id) productInfo.get('Parent_Course__c')
        );
        //product end e start date confirmar se pego do produto ou do postman (vem diferente)
        insert opp;
        return opp;
    }

    //colocar em uma service
    private static Map<String, Object> getAgentInfo(String agentName) {
        Map<String, Object> result = new Map<String, Object>();
        if (String.isBlank(agentName)) return result;
        
        Account agency = [
            SELECT Id, Name, Email__c
            FROM Account
            WHERE Name = :agentName
            LIMIT 1
        ];
        
        result.put('agencyId', agency.Id);
        result.put('agencyEmail', agency.Email__c);
        return result;
    }

    //colocar em uma service
    private static Map<String, Object> getProductAndPricebook(String edvisorId) {
        Map<String, Object> result = new Map<String, Object>();
        if (String.isBlank(edvisorId)) return result;
        
        Product2 prod = [
            SELECT Id, Name, EdvisorID__c, ProductCode, Start_Date__c, End_Date__c, 
            Parent_Course__c, Parent_Course__r.Course_Category__c, Parent_Course__r.Course_Category__r.Course_Type__c
            FROM Product2
            WHERE EdvisorID__c = :edvisorId
            LIMIT 1
        ];
        
        PricebookEntry pbe = [
            SELECT Id, Pricebook2Id
            FROM PricebookEntry
            WHERE Product2Id = :prod.Id AND IsActive = true AND Pricebook2.Name = 'EU'
            LIMIT 1
        ];
        
        result.put('productId', prod.Id);
        result.put('productCode', prod.ProductCode);
        result.put('pricebookId', pbe.Pricebook2Id);
        result.put('productName', prod.Name);
        result.put('productStartDate', prod.Start_Date__c);
        result.put('productEndDate', prod.End_Date__c);
        result.put('productParentCourse', prod.Parent_Course__c);
        result.put('productCourseCategory', prod.Parent_Course__r.Course_Category__c);
        result.put('productCourseType', prod.Parent_Course__r.Course_Category__r.Course_Type__c);
        return result;
    }

    // Helpers
    private static String stringVal(Object value) {
        return value != null ? String.valueOf(value) : null;
    }
    
    private static Date parseDate(Object dateValue) {
        return dateValue != null ? Date.valueOf(String.valueOf(dateValue).split('T')[0]) : null;
    }
}