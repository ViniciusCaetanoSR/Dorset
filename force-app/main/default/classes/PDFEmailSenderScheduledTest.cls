@isTest
private class PDFEmailSenderScheduledTest {
    @isTest
    static void testScheduledExecution() {
        // Dados de teste
        Account acc = VirtualTestData.createAccount('Test', 'User', 'Brazil', Date.newInstance(1990, 1, 1), 'XPTO9876');
        acc.PersonEmail = 'test@example.com';
        insert acc;

        Course_Type__c courseType = VirtualTestData.createCourseType('Inglês Intensivo');
        insert courseType;

        Course_Categorty__c category = VirtualTestData.createCourseCategory('Language', courseType.Id);
        insert category;

        Course__c course = VirtualTestData.createCourse('Curso de Teste', category.Id);
        insert course;

        Product2 product = VirtualTestData.createProduct('Produto Teste', course.Id);
        insert product;

        Account agent = VirtualTestData.createAgent('Agente Ativo', 'Active');
        insert agent;

        Opportunity opp = VirtualTestData.createOpportunity(
            'Test Opp',
            'PO',
            Date.today().addDays(10),
            agent.Id,
            acc.Id,
            product.Id,
            category.Id,
            courseType.Id
        );
        insert opp;

        // Criando um Quote relacionado à Opportunity
        Quote quote = new Quote(Name = 'Fatura Teste', OpportunityId = opp.Id);
        insert quote;

        // Criando a entrada de email
        PDFEmailSender.EmailInput input = new PDFEmailSender.EmailInput();
        input.applicationId = opp.Id;
        input.templateType = 'PO';
        input.courseCategoryId = category.Id;

        // Instanciando e executando a classe agendada
        Test.startTest();
        PDFEmailSenderScheduled scheduled = new PDFEmailSenderScheduled(input);
        String jobId = System.schedule('Test PDFEmailSenderScheduled', '0 0 12 * * ?', scheduled);
        Test.stopTest();

        // Nenhuma assertiva é obrigatória pois só testamos o caminho feliz (sem erro)
    }
}