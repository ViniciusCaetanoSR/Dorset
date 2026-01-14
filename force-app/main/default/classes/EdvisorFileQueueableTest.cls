@IsTest
private class EdvisorFileQueueableTest {
    private class SuccessMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBodyAsBlob(Blob.valueOf('conteudo de teste'));
            return res;
        }
    }

    private class FailMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('erro simulado');
            return res;
        }
    }

    // Pra não ter que cadastrar tudo 2x.
    private static Opportunity createFullOpportunity(String oppName) {
        Course_Type__c courseType = VirtualTestData.createCourseType('Inglês Intensivo');
        insert courseType;

        Course_Categorty__c courseCategory = VirtualTestData.createCourseCategory('Language', courseType.Id);
        insert courseCategory;
        
        Course__c course = VirtualTestData.createCourse('Curso de Teste', courseCategory.Id);
        insert course;
        
        Product2 prod = new Product2(
            Name = 'Test Product',
            ProductCode = 'P123',
            Parent_Course__c = course.Id,
            IsActive = true,
            Start_Date__c = Date.newInstance(2025, 10, 1),
            End_Date__c = Date.newInstance(2025, 11, 1),
            Duration__c = 4
        );
        insert prod;

        Account acct = new Account(
            Name = 'Agency Test',
            Email__c = 'agency@test.com'
        );
        insert acct;

        Opportunity opp = new Opportunity(
            Name        = oppName,
            StageName   = 'Prospecting',
            CloseDate   = Date.today().addDays(30),
            AccountId   = acct.Id,
            Product__c  = prod.Id,
            Product_End_Date2__c = prod.End_Date__c
        );
        insert opp;

        return opp;
    }

    @IsTest
    static void testSuccessFlow() {
        Opportunity opp = createFullOpportunity('Opp Success');

        List<String> urls = new List<String>{ 'http://fakeurl.com/file1' };
        List<String> names = new List<String>{ 'file1.pdf' };
        List<Id> oppIds = new List<Id>{ opp.Id };

        Test.setMock(HttpCalloutMock.class, new SuccessMock());

        Test.startTest();
        System.enqueueJob(new EdvisorFileQueueable(urls, names, oppIds));
        Test.stopTest();

        List<ContentVersion> cvs = [SELECT Id FROM ContentVersion WHERE Title = 'file1.pdf'];
        System.assertEquals(1, cvs.size(), 'Deveria ter inserido um ContentVersion');
    }

    @IsTest
    static void testFailFlow() {
        Opportunity opp = createFullOpportunity('Opp Fail');

        List<String> urls = new List<String>{ 'http://fakeurl.com/file2' };
        List<String> names = new List<String>{ 'file2.pdf' };
        List<Id> oppIds = new List<Id>{ opp.Id };

        Test.setMock(HttpCalloutMock.class, new FailMock());

        Test.startTest();
        System.enqueueJob(new EdvisorFileQueueable(urls, names, oppIds));
        Test.stopTest();

        List<ContentVersion> cvs = [SELECT Id FROM ContentVersion WHERE Title = 'file2.pdf'];
        System.assertEquals(0, cvs.size(), 'Não deveria inserir arquivos em caso de erro');
    }
}