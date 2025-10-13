@isTest
private class PDFEmailSenderTest {
    @isTest
    static void testSendEmail() {
        // Criar Account (Pessoa)
        Account acc = VirtualTestData.createAccount('Test', 'Teste', 'Brazil', Date.newInstance(2000, 5, 10), 'XPTO1234');
        insert acc;

        Course_Type__c courseType = VirtualTestData.createCourseType('Inglês Intensivo');
        insert courseType;

        Course_Categorty__c courseCategory = VirtualTestData.createCourseCategory('Language', courseType.Id);
        insert courseCategory;

        Course__c course = VirtualTestData.createCourse('Curso de Teste', courseCategory.Id);
        insert course;

        Account agent = VirtualTestData.createAgent('Agente Ativo', 'Active');
        insert agent;

        Product2 product = VirtualTestData.createProduct('Produto Teste', course.Id);
        insert product;

        Opportunity opp = VirtualTestData.createOpportunity(
            'Oportunidade Teste',
            'PO',
            Date.today().addDays(10),
            agent.Id,
            acc.Id,
            product.Id,
            courseCategory.Id,
            courseType.Id
        );
        insert opp;

        PDFTemplate__c template = VirtualTestData.createPdfTemplate(
            'Template de Teste',
            true,
            'PO',
            courseCategory.Id,
            'Bem-vindo {{Account.LastName}}! Data de nascimento: {{Account.PersonBirthdate}}. -----'
        );
        insert template;

        Quote invoice = VirtualTestData.createQuote('Teste Invoice', opp.Id);
        insert invoice;

        ContentVersion contentVersion = new ContentVersion(
            Title = 'a picture',
            PathOnClient = 'Pic.jpg',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true
        );
        insert contentVersion;

        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];

        //create ContentDocumentLink  record
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.LinkedEntityId = invoice.Id;
        cdl.ContentDocumentId = documents[0].Id;
        cdl.ShareType = 'V';
        cdl.Visibility = 'AllUsers';
        insert cdl;

        Test.startTest();
        // Criar input e chamar método
        PDFEmailSender.EmailInput input = new PDFEmailSender.EmailInput();
        input.applicationId = opp.Id;
        input.templateType = 'PO';
        input.courseCategoryId = courseCategory.Id;
        input.invoiceId = invoice.Id;
        System.debug('invoiceid =' + invoice.Id);

        PDFEmailSender.sendEmail(new List<PDFEmailSender.EmailInput>{ input });
        Test.stopTest();
    }

    @isTest
    static void testExeptionSemInput() {
        Test.startTest();

        PDFEmailSender.sendEmail(new List<PDFEmailSender.EmailInput>{});
        Test.stopTest();
    }

    @isTest
    static void testExeptionComInputVazio() {
        Test.startTest();
        PDFEmailSender.EmailInput input = new PDFEmailSender.EmailInput();

        PDFEmailSender.sendEmail(new List<PDFEmailSender.EmailInput>{ input });
        Test.stopTest();
    }

    @isTest
    static void testExeptionSemInvoice() {
        // Criar Account (Pessoa)
        Account acc = VirtualTestData.createAccount('Test', 'Teste', 'Brazil', Date.newInstance(2000, 5, 10), 'XPTO1234');
        insert acc;

        Course_Type__c courseType = VirtualTestData.createCourseType('Inglês Intensivo');
        insert courseType;

        Course_Categorty__c courseCategory = VirtualTestData.createCourseCategory('Language', courseType.Id);
        insert courseCategory;

        Course__c course = VirtualTestData.createCourse('Curso de Teste', courseCategory.Id);
        insert course;

        Account agent = VirtualTestData.createAgent('Agente Ativo', 'Active');
        insert agent;

        Product2 product = VirtualTestData.createProduct('Produto Teste', course.Id);
        insert product;

        Opportunity opp = VirtualTestData.createOpportunity(
            'Oportunidade Teste',
            'PO',
            Date.today().addDays(10),
            agent.Id,
            acc.Id,
            product.Id,
            courseCategory.Id,
            courseType.Id
        );
        insert opp;

        PDFTemplate__c template = VirtualTestData.createPdfTemplate('Template de Teste', true, 'PO', courseCategory.Id, 'Bem-vindo. -----');
        insert template;

        Test.startTest();
        // Criar input e chamar método
        PDFEmailSender.EmailInput input = new PDFEmailSender.EmailInput();
        input.applicationId = opp.Id;
        input.templateType = 'PO';
        input.courseCategoryId = courseCategory.Id;

        PDFEmailSender.sendEmail(new List<PDFEmailSender.EmailInput>{ input });
        Test.stopTest();
    }

    @isTest
    static void testFetchOpportunityReturnsNull() {
        PDFEmailSender.EmailInput input = new PDFEmailSender.EmailInput();
        input.applicationId = '006000000000000'; // ID inválido
        input.templateType = 'PO';
        input.courseCategoryId = 'a1x000000000000';

        Test.startTest();
        PDFEmailSender.sendEmail(new List<PDFEmailSender.EmailInput>{ input });
        Test.stopTest();
    }

}