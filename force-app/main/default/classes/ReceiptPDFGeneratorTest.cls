@isTest
private class ReceiptPDFGeneratorTest {

    @isTest
    static void testGeneratePdf() {
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

        Product2 product = new Product2(
            Name = 'Produto Teste',
            Parent_Course__c = course.Id,
            IsActive = true,
            Start_Date__c = Date.newInstance(2024, 12, 12),
            End_Date__c = Date.newInstance(2025, 12, 12)
        );
        insert product;

        Opportunity opp = VirtualTestData.createOpportunity(
            'Oportunidade Teste', 
            'ACC', 
            Date.today().addDays(10), 
            agent.Id, 
            acc.Id, 
            product.Id, 
            courseCategory.Id, 
            courseType.Id
        );
        insert opp;

        Payment_Plan__c payPlan = new Payment_Plan__c(
            Name = 'Payment Plan Test'
        );
        insert payPlan;

        Payment__c pay = new Payment__c(
            Name = 'Payment Test',
            Opportunity__c = opp.Id,
            Payment_Plan__c = payPlan.Id,
            Payment_Amount__c = 100,
            Student_Name__c = acc.Id
        );
        insert pay;

        PDFTemplate__c template = VirtualTestData.createPdfTemplate(
            'Receipt', 
            true, 
            '', 
            courseCategory.Id, 
            '----- Total Amount: € {{opportunity__r.amount}} {table} -----'
        );
        insert template;

        Test.setCurrentPage(Page.Receipt);
        ReceiptPDFGenerator.testBlobContent = Blob.valueOf('%PDF-1.4 Simulated PDF');

        ReceiptPDFGenerator.ReceiptPDFInput input = new ReceiptPDFGenerator.ReceiptPDFInput();
        input.paymentId = pay.Id;

        List<ReceiptPDFGenerator.ReceiptPDFInput> inputs = new List<ReceiptPDFGenerator.ReceiptPDFInput>{ input };

        Test.startTest();
        ReceiptPDFGenerator.generatePdf(inputs);
        Test.stopTest();

        List<ContentVersion> cvs = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Title LIKE 'Receipt - %'];
        System.assertEquals(1, cvs.size(), 'Deveria haver 1 ContentVersion');
        ContentVersion cv = cvs[0];
        System.assert(cv.Title.contains('Receipt'), 'O título deve conter "Receipt"');

        List<ContentDocumentLink> links = [
            SELECT LinkedEntityId 
            FROM ContentDocumentLink 
            WHERE ContentDocumentId = :cv.ContentDocumentId
        ];

        Set<Id> expectedIds = new Set<Id>{ pay.Id, opp.Id };
        Set<Id> actualIds = new Set<Id>();
        for (ContentDocumentLink link : links) {
            actualIds.add(link.LinkedEntityId);
        }
    }
}