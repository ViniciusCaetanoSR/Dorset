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
            Start_Date__c = Date.newInstance(2025, 12, 12),
            End_Date__c = Date.newInstance(2026, 12, 12)
        );
        insert product;

        Opportunity opp = new Opportunity(
            Name = 'Oportunidade Teste',
            StageName = 'PO',
            CloseDate = Date.today().addDays(10),
            AccountId = acc.Id,
            Agent__c = agent.Id,
            Course_Category__c = courseCategory.Id,
            Course_Type__c = courseType.Id,
            Product__c = product.Id,
            LeadCloseDate__c = Date.today().addDays(10)
        );
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

        PDFTemplate__c template = VirtualTestData.createPdfTemplate('Receipt', true, '', courseCategory.Id, '----- Total Amount: € {{opportunity__r.Agent_Gross_Amout__c}}<br/>' +
            'Paid: {{opportunity__r.Amount_Paid__c}}<br/>' +
            'Outstanding: {{opportunity__r.Student_Outstanding_Balance__c}}' +
			'Payment amount: {{Payment_Amount__c}}' +
            '{table} -----');
        insert template;

        Test.startTest();
        ApexPages.currentPage().getParameters().put('id', pay.Id);
        ReceiptController controller = new ReceiptController();
        Test.stopTest();

        System.assert(controller.decodedContent.contains('Total Amount'), 'Deve conter o texto formatado');
        System.assert(controller.decodedContent.contains('<hr'), 'HR deve ter sido inserido');
    }
}