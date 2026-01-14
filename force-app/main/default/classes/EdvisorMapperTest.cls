@IsTest(SeeAllData=true)
private class EdvisorMapperTest {

    @IsTest
    static void testFromApplication() {
        Account agency = new Account(
            Name = 'Agency Test',
            Email__c = 'agency@test.com'
        );
        insert agency;

        Date startDate = Date.valueOf('2025-10-01');
        Integer year = startDate.year();
        Integer daysDiff = Date.newInstance(year, 1, 1).daysBetween(startDate);
        Integer weekOfYear = (daysDiff / 7) + 1;
        String productName = 'General English ' + weekOfYear + '_' + year;

        Course_Type__c courseType = VirtualTestData.createCourseType('Inglês Intensivo');
        insert courseType;

        Course_Categorty__c courseCategory = VirtualTestData.createCourseCategory('Language', courseType.Id);
        insert courseCategory;
        
        Course__c course = VirtualTestData.createCourse('Curso de Teste', courseCategory.Id);
        insert course;

        Product2 prod = new Product2(
            Name = productName,
            ProductCode = 'P123',
            Parent_Course__c = course.Id,
            IsActive = true,
            Start_Date__c = Date.newInstance(2025, 10, 1),
            End_Date__c = Date.newInstance(2025, 11, 1),
            Duration__c = 4
        );

        insert prod;

        Id standardPBId = Test.getStandardPricebookId();

        PricebookEntry standardEntry = new PricebookEntry(
            Pricebook2Id = standardPBId,
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert standardEntry;

        Pricebook2 customPB = new Pricebook2(
            Name = 'NON-EU',
            IsActive = true
        );
        insert customPB;

        Map<String, Object> studentInfo = new Map<String, Object>{
            'firstname' => 'John',
            'lastname' => 'Doe',
            'email' => 'john.doe@test.com',
            'birthdate' => '2000-01-01T00:00:00Z',
            'phone' => '123456',
            'nationality' => new Map<String, Object>{ 'nameTranslation' => 'Brazil' }
        };

        Map<String, Object> courseSnapshot = new Map<String, Object>{
            'name' => productName + ' Morning'
        };

        Map<String, Object> enrollment = new Map<String, Object>{
            'courseSnapshot' => courseSnapshot,
            'startDate' => '2025-10-01T00:00:00Z',
            'endDate'   => '2025-12-01T00:00:00Z'
        };

        Map<String, Object> json = new Map<String, Object>{
            'student' => studentInfo,
            'studentEnrollmentFiles' => new List<Object>(),
            'studentEnrollmentOfferingItems' => new List<Object>{ enrollment },
            'agency' => new Map<String, Object>{ 'email' => agency.Email__c },
            'created' => '2025-09-17T00:00:00Z'
        };

        Test.startTest();
        Opportunity opp = EdvisorMapper.fromApplication(json);
        Test.stopTest();

        Account acc = [SELECT Id, FirstName, LastName, Email__c, PersonEmail, Student_Type__c FROM Account WHERE Email__c = 'john.doe@test.com' LIMIT 1];
        System.assertEquals('John', acc.FirstName);
        System.assertEquals('Doe', acc.LastName);
        System.assertEquals('john.doe@test.com', acc.Email__c);
        System.assertEquals('Non EU', acc.Student_Type__c);

        Opportunity createdOpp = [SELECT Id, Name, StageName, Product__c, Agent__c, SessionType__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('APP', createdOpp.StageName);
        System.assertEquals(agency.Id, createdOpp.Agent__c);
        System.assertEquals('Morning', createdOpp.SessionType__c);
    }
}