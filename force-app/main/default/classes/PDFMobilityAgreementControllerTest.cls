@isTest
private class PDFMobilityAgreementControllerTest {
    @TestSetup
    static void setup() {
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
            'Test Opportunity',
            'APP',
            Date.today().addDays(10),
            agent.Id,
            acc.Id,
            product.Id,
            courseCategory.Id,
            courseType.Id
        );
        insert opp;

        PDFTemplate__c template = new PDFTemplate__c(Name = 'Mobility Template', HTMLContent__c = 'Nome: {{Name}}', Active__c = true);
        insert template;
    }

    @isTest
    static void testConstructorSuccess() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];

        PageReference pageRef = Page.TemplateMobilityAgreement;
        pageRef.getParameters().put('id', opp.Id);
        Test.setCurrentPage(pageRef);

        Test.startTest();
        PDFMobilityAgreementController controller = new PDFMobilityAgreementController();
        Test.stopTest();

        System.assertNotEquals(null, controller.formattedDate, 'A data formatada não deveria ser nula');
        System.assertNotEquals(null, controller.decodedContent, 'O conteúdo decodificado não deveria ser nulo');
        System.assert(controller.decodedContent.contains('Test Opportunity'), 'O conteúdo deveria conter o nome da Opportunity');
    }

    @isTest
    static void testConstructorMissingId() {
        PageReference pageRef = Page.TemplateMobilityAgreement;
        Test.setCurrentPage(pageRef);

        Test.startTest();
        PDFMobilityAgreementController controller = new PDFMobilityAgreementController();
        Test.stopTest();

        List<ApexPages.Message> messages = ApexPages.getMessages();
        System.assertEquals(1, messages.size(), 'Deveria haver uma mensagem de erro');
        System.assert(messages[0].getSummary().contains('O parâmetro "id" da URL está ausente'), 'A mensagem de erro deveria indicar a ausência do ID');
    }

    @isTest
    static void testConstructorNoTemplateFound() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];

        delete [SELECT Id FROM PDFTemplate__c];

        PageReference pageRef = Page.TemplateMobilityAgreement;
        pageRef.getParameters().put('id', opp.Id);
        Test.setCurrentPage(pageRef);

        Test.startTest();
        PDFMobilityAgreementController controller = new PDFMobilityAgreementController();
        Test.stopTest();

        List<ApexPages.Message> messages = ApexPages.getMessages();
        System.assertEquals(1, messages.size(), 'Deveria haver uma mensagem de erro');
        System.assert(messages[0].getSummary().contains('Nenhum template ativo encontrado'), 'A mensagem de erro deveria indicar a ausência do template');
    }
}