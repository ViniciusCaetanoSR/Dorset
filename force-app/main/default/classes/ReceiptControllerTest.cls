@isTest
public with sharing class ReceiptControllerTest {
    @isTest
    static void ReceiptControllerTest(){
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

        Opportunity opp = VirtualTestData.createOpportunity('Oportunidade Teste', 'ACC', Date.today().addDays(10), agent.Id, acc.Id, product.Id, courseCategory.Id, courseType.Id);
        insert opp;

        product.IsActive = true;
        update product;

        Id standardPBId = Test.getStandardPricebookId();

        PricebookEntry standardEntry = new PricebookEntry(
            Pricebook2Id = standardPBId,
            Product2Id = product.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert standardEntry;

        Pricebook2 customPB = new Pricebook2(
            Name = 'Custom Pricebook',
            IsActive = true
        );
        insert customPB;

        opp.Pricebook2Id = customPB.Id;
        update opp;

        PricebookEntry customEntry = new PricebookEntry(
            Pricebook2Id = customPB.Id,
            Product2Id = product.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert customEntry;

        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            Quantity = 1,
            UnitPrice = 100,
            PricebookEntryId = customEntry.Id,
            Description = 'Linha de teste',
            Start_Date__c = Date.newInstance(2024, 12, 12),
            End_Date__c = Date.newInstance(2025, 12, 12)
        );
        insert oli;

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

        PDFTemplate__c template = VirtualTestData.createPdfTemplate('Receipt', true, '', courseCategory.Id, '----- Total Amount: € {{opportunity__r.amount}} {table} -----');
        insert template;

        Test.startTest();
        ApexPages.currentPage().getParameters().put('id', pay.Id);
        ReceiptController controller = new ReceiptController();
        Test.stopTest();

        System.assert(controller.decodedContent.contains('Total Amount'), 'Deve conter o texto formatado');
        System.assert(controller.decodedContent.contains('<hr'), 'HR deve ter sido inserido');
    }
}