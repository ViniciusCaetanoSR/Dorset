@isTest
public with sharing class DorsetEnrolConfControllerTest {
    @isTest
    static void testDorsetEnrolConfController() {
        Account acc = VirtualTestData.createAccount('Teste', 'Teste', 'Brazil', Date.newInstance(2000, 1, 1), 'AB1234567');
        insert acc;

        Course_Type__c courseType = VirtualTestData.createCourseType('Inglês Intensivo');
        insert courseType;

        Account agent = VirtualTestData.createAgent('Agente Ativo', 'Active');
        insert agent;

        Course_Categorty__c courseCategory = VirtualTestData.createCourseCategory('Language', courseType.Id);
        insert courseCategory;

        Course__c course = VirtualTestData.createCourse('Curso de Teste', courseCategory.Id);
        insert course;

        Product2 product = VirtualTestData.createProduct('Produto Teste', course.Id);
        insert product;

        Opportunity opp = VirtualTestData.createOpportunity('Test Opp', 'APP', Date.today().addDays(10), agent.Id, acc.Id, product.Id, courseCategory.Id, courseType.Id);
        insert opp;

        //Atualizar StageName para forçar preenchimento de LastStageChangeDate
        opp.StageName = 'APP2';
        update opp;

        ApexPages.currentPage().getParameters().put('id', opp.Id);

        Test.startTest();
        DorsetEnrolConfController controller = new DorsetEnrolConfController();
        Test.stopTest();

        System.assertNotEquals(null, controller.opportunity);
        System.assertEquals('Produto Teste', controller.programmeTitle);
    }
}