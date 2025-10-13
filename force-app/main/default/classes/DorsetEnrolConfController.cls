public without sharing class DorsetEnrolConfController {
    public Opportunity opportunity { get; set; }
    public String programmeTitle { get; set; }
    public String formattedLastStageChangeDate { get; set; }
    public String passportNumber { get; set; }
    public Date dateOfBirth { get; set; }
    public String studentId { get; set; }
    public String fullName { get; set; }
    public String countryOfBirth { get; set; }

    public DorsetEnrolConfController() {
        Id oppId = ApexPages.currentPage().getParameters().get('id');

        this.opportunity = [
            SELECT
                Id,
                Account.Name,
                Account.Student_ID__c,
                Account.PersonBirthdate,
                Account.Passport_Number__c,
                Account.Country_of_Birth__c,
                product__r.Name,
                product__r.Duration__c,
                product__r.Duration1__c,
                LastStageChangeDate
            FROM Opportunity
            WHERE Id = :oppId
            LIMIT 1
        ];

        formattedLastStageChangeDate = formatDate(opportunity.LastStageChangeDate.date());

        programmeTitle = opportunity.product__r.Name;
        fullName = opportunity.Account.Name;
        studentId = opportunity.Account.Student_ID__c;
        dateOfBirth = opportunity.Account.PersonBirthdate;
        passportNumber = opportunity.Account.Passport_Number__c;
        countryOfBirth = opportunity.Account.Country_of_Birth__c;
    }

    public static String formatDate(Date dateTemp) {
        DateTime dt = DateTime.newInstance(dateTemp.year(), dateTemp.month(), dateTemp.day());
        return dt.format('dd MMMM yyyy');
    }
}