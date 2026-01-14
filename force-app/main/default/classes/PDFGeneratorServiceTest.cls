@IsTest
private class PDFGeneratorServiceTest {
    @TestSetup
    static void setupTestData() {
        Account acc = VirtualTestData.createAccount('Teste', 'Teste', 'Brazil', Date.newInstance(2000, 1, 1), 'AB1234567');
        insert acc;

        Course_Type__c courseType = new Course_Type__c(Name = 'Inglês Intensivo');
        insert courseType;

        Course_Categorty__c courseCategory = new Course_Categorty__c(Name = 'Language', Course_Type__c = courseType.Id);
        insert courseCategory;

        Course__c course = new Course__c(Name = 'Curso de Teste', Course_Category__c = courseCategory.Id);
        insert course;

        Account agent = new Account(Name = 'Agente Ativo', Account_Status__c = 'Active');
        insert agent;

        Product2 product = new Product2(Name = 'Produto Teste', Parent_Course__c = course.Id, IsActive = true, Start_Date__c = Date.today().addDays(5));
        insert product;

        Opportunity opp = new Opportunity(
            Name = 'Oportunidade Teste',
            StageName = 'ACC',
            CloseDate = Date.today().addDays(10),
            Agent__c = agent.Id,
            AccountId = acc.Id,
            Product__c = product.Id,
            Course_Category__c = courseCategory.Id,
            Course_Type__c = courseType.Id
        );
        insert opp;

        PDFTemplate__c template = new PDFTemplate__c(
            Name = 'Template de Teste',
            Active__c = true,
            Stage__c = 'ACC',
            CourseCategory__c = courseCategory.Id,
            HTMLContent__c = 'Bem-vindo {{Name}}.',
            EmailBody__c = 'Olá {{Name}}, segue seu documento.',
            EmailSubject__c = 'Assunto de Teste',
            CCEmailAddresses__c = 'test1@example.com,test2@example.com'
        );
        insert template;

        // Mobility template for specific test
        PDFTemplate__c mobilityTemplate = new PDFTemplate__c(
            Name = 'Mobility Agreement Template',
            Active__c = true,
            Stage__c = 'ACC',
            CourseCategory__c = courseCategory.Id,
            HTMLContent__c = 'Mobility content',
            EmailBody__c = 'Mobility email',
            EmailSubject__c = 'Mobility subject'
        );
        insert mobilityTemplate;
    }

    // Helper method to get test opportunity with all required fields
    private static Opportunity getTestOpportunity() {
        return [SELECT Id, Name, CreatedDate FROM Opportunity LIMIT 1];
    }

    // Helper method to get test template with all required fields
    private static PDFTemplate__c getTestTemplate() {
        return [
            SELECT Id, Name, EmailBody__c, EmailSubject__c, CCEmailAddresses__c, HTMLContent__c
            FROM PDFTemplate__c
            WHERE Name = 'Template de Teste'
            LIMIT 1
        ];
    }

    // Helper method to get mobility template with all required fields
    private static PDFTemplate__c getMobilityTemplate() {
        return [
            SELECT Id, Name, EmailBody__c, EmailSubject__c, HTMLContent__c
            FROM PDFTemplate__c
            WHERE Name = 'Mobility Agreement Template'
            LIMIT 1
        ];
    }

    // Helper method to get course category
    private static Course_Categorty__c getTestCourseCategory() {
        return [SELECT Id FROM Course_Categorty__c LIMIT 1];
    }

    @IsTest
    static void testGeneratePDFSuccess() {
        Opportunity opp = getTestOpportunity();
        PDFTemplate__c template = getTestTemplate();
        Course_Categorty__c courseCategory = getTestCourseCategory();

        PDFGeneratorService.IPDFGenerator mockGenerator = new PDFGeneratorService.MockPDFGenerator();

        Test.startTest();
        PDFGeneratorService.PDFResult result = PDFGeneratorService.generatePDF(opp.Id, 'Test', courseCategory.Id, template.Id, mockGenerator);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(null, result.pdfBlob, 'PDF blob should not be null');
        System.assert(result.fileName.endsWith('.pdf'), 'Filename should end with .pdf');
        System.assert(String.isNotBlank(result.emailBody), 'Email body should not be blank');
        System.assertEquals('Assunto de Teste', result.emailSubject, 'Email subject should match template');
        System.assertEquals(2, result.CCEmailAddresses.size(), 'Should have 2 CC emails');
    }

    @IsTest
    static void testGenerateMobilityPDF() {
        Opportunity opp = getTestOpportunity();
        PDFTemplate__c template = getMobilityTemplate();
        Course_Categorty__c courseCategory = getTestCourseCategory();

        PDFGeneratorService.IPDFGenerator mockGenerator = new PDFGeneratorService.MockPDFGenerator();
        Test.startTest();
        PDFGeneratorService.PDFResult result = PDFGeneratorService.generatePDF(opp.Id, 'Mobility', courseCategory.Id, template.Id, mockGenerator);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals('ERASMUS + Mobility Agreement.pdf', result.fileName, 'Filename should match mobility template');
        System.assertNotEquals(null, result.pdfBlob, 'PDF blob should not be null');
    }

    @IsTest
    static void testGeneratePDFWithMockGenerator() {
        Opportunity opp = getTestOpportunity();
        PDFTemplate__c template = getTestTemplate();
        Course_Categorty__c courseCategory = getTestCourseCategory();

        PDFGeneratorService.IPDFGenerator mockGenerator = new PDFGeneratorService.MockPDFGenerator();

        Test.startTest();
        PDFGeneratorService.PDFResult result = PDFGeneratorService.generatePDF(opp.Id, 'Test', courseCategory.Id, template.Id, mockGenerator);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals('%PDF-1.4 Mock PDF Content', result.pdfBlob.toString(), 'Should use mock generator');
    }

    @IsTest
    static void testExtractPlaceholders() {
        String content = 'Hello {{Name}}! Your birthdate is {{Birthdate}}. {{Invalid}}';

        Test.startTest();
        Set<String> placeholders = PDFGeneratorService.extractPlaceholders(content);
        Test.stopTest();

        System.assertEquals(3, placeholders.size(), 'Should find all placeholders');
        System.assert(placeholders.contains('Name'), 'Should contain Name placeholder');
        System.assert(placeholders.contains('Birthdate'), 'Should contain Birthdate placeholder');
        System.assert(placeholders.contains('Invalid'), 'Should contain Invalid placeholder');
    }

    @IsTest
    static void testReplacePlaceholders() {
        Opportunity opp = [SELECT Id, Name, CreatedDate FROM Opportunity LIMIT 1];
        String template = 'Hello {{Name}}! Created on {{CreatedDate}}.';

        Test.startTest();
        String result = PDFGeneratorService.replacePlaceholders(template, opp);
        Test.stopTest();

        System.assert(result.contains(opp.Name), 'Should replace Name placeholder');
        System.assert(result.contains('Created on'), 'Should maintain static text');
    }

    @IsTest
    static void testFormatDate() {
        Date testDate = Date.newInstance(2023, 5, 15);

        Test.startTest();
        String formattedDate = PDFGeneratorService.formatDate(testDate);
        Test.stopTest();

        System.assertEquals('15 May 2023', formattedDate, 'Should format date correctly');
    }

    @IsTest
    static void testCleanEmailList() {
        List<String> emails = new List<String>{ ' valid1@example.com ', 'invalid-email', 'valid2@example.com', '', 'another.invalid' };

        Test.startTest();
        List<String> cleaned = PDFGeneratorService.cleanEmailList(emails);
        Test.stopTest();

        System.assertEquals(2, cleaned.size(), 'Should only keep valid emails');
        System.assertEquals('valid1@example.com', cleaned[0], 'Should trim and validate emails');
        System.assertEquals('valid2@example.com', cleaned[1], 'Should validate emails');
    }

    @IsTest
    static void testProcessEmailBody() {
        Opportunity opp = getTestOpportunity();
        PDFTemplate__c template = getTestTemplate();

        Test.startTest();
        String emailBody = PDFGeneratorService.replacePlaceholders(template.EmailBody__c, opp);
        Test.stopTest();

        System.assert(emailBody.contains(opp.Name), 'Should replace Name placeholder');
        System.assert(emailBody.contains('segue seu documento'), 'Should maintain static text');
    }
}