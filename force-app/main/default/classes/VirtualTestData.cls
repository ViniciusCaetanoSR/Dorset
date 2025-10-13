@isTest
public with sharing class VirtualTestData {
    public static Account createAccount(String firstName, String lastName, String birthCountry, Date birthDate, String passportNumber) {
        return new Account(
            FirstName = firstName,
            LastName = lastName,
            Country_of_Birth__c = birthCountry,
            PersonBirthdate = birthDate,
            Passport_Number__c = passportNumber,
            D_O_B__c = birthDate
        );
    }

    public static Course_Type__c createCourseType(String name) {
        return new Course_Type__c(Name = name);
    }

    public static Course_Categorty__c createCourseCategory(String name, Id courseTypeId) {
        return new Course_Categorty__c(Name = name, Course_Type__c = courseTypeId);
    }

    public static Course__c createCourse(String name, Id courseCategoryId) {
        return new Course__c(Name = name, Course_Category__c = courseCategoryId);
    }

    public static Account createAgent(String name, String status) {
        return new Account(Name = name, Account_Status__c = status);
    }

    public static Product2 createProduct(String name, Id parentCourseId) {
        return new Product2(Name = name, Parent_Course__c = parentCourseId, IsActive = true, Start_Date__c = Date.today().addDays(5));
    }

    public static Opportunity createOpportunity(
        String name,
        String stageName,
        Date closeDate,
        Id agentId,
        Id accountId,
        Id productId,
        Id courseCategoryId,
        Id courseTypeId
    ) {
        return new Opportunity(
            Name = name,
            StageName = stageName,
            CloseDate = closeDate,
            Agent__c = agentId,
            AccountId = accountId,
            Product__c = productId,
            Course_Category__c = courseCategoryId,
            Course_Type__c = courseTypeId
        );
    }

    public static PDFTemplate__c createPdfTemplate(String name, Boolean active, String stage, Id courseCategoryId, String htmlContent) {
        return new PDFTemplate__c(Name = name, Active__c = active, Stage__c = stage, CourseCategory__c = courseCategoryId, HTMLContent__c = htmlContent);
    }

    public static Quote createQuote(String name, Id opportunityId) {
        return new Quote(Name = name, OpportunityId = opportunityId);
    }
}