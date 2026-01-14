@isTest
public with sharing class PdfContentControllerTest {
    @isTest
    static void testPdfContentController_ACC() {
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

        Opportunity opp = VirtualTestData.createOpportunity('Oportunidade Teste', 'ACC', Date.today().addDays(10), agent.Id, acc.Id, product.Id, courseCategory.Id, courseType.Id);
        insert opp;

        PDFTemplate__c template = VirtualTestData.createPdfTemplate('Template de Teste', true, 'ACC', courseCategory.Id, 'Bem-vindo {{Account.LastName}}! Data de nascimento: {{Account.PersonBirthdate}}. -----');
        insert template;

        Test.startTest();
        ApexPages.currentPage().getParameters().put('id', opp.Id);
        ApexPages.currentPage().getParameters().put('templateType', 'ACC');
        PdfContentController controller = new PdfContentController();
        Test.stopTest();

        System.assert(controller.decodedContent.contains('Bem-vindo'), 'Deve conter o texto formatado');
        System.assert(controller.decodedContent.contains('XPTO12345') == false, 'Não deve conter campos inexistentes');
        System.assert(controller.decodedContent.contains('<hr'), 'HR deve ter sido inserido');
        System.assertEquals(true, controller.exibirQrCode, 'Deveria exibir o QR code');
        System.assert(controller.qrCodeUrl.startsWith('https://api.qrserver.com'), 'QR Code URL deve ser gerada');
        System.assertNotEquals('', controller.Today, 'Today deve retornar a data formatada');
    }

    @isTest
    static void testPdfContentController_PO() {
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

        Opportunity opp = VirtualTestData.createOpportunity('Oportunidade Teste', 'PO', Date.today().addDays(10), agent.Id, acc.Id, product.Id, courseCategory.Id, courseType.Id);
        insert opp;

        PDFTemplate__c template = VirtualTestData.createPdfTemplate('Template de Teste', true, 'PO', courseCategory.Id, '');
        insert template;

        Test.startTest();
        ApexPages.currentPage().getParameters().put('id', opp.Id);
        ApexPages.currentPage().getParameters().put('templateType', 'PO');
        PdfContentController controller = new PdfContentController();
        Test.stopTest();

        System.assertNotEquals('', controller.Today, 'Today deve retornar a data formatada');
    }
}