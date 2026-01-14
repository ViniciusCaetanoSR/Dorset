global without sharing class EdvisorBatch implements Database.Batchable<String>, Database.AllowsCallouts, Database.Stateful {
    private final Datetime startDate;
    private final Datetime endDate;

    public EdvisorBatch(Datetime startDate, Datetime endDate) {
        this.startDate = startDate;
        this.endDate = endDate;
    }

    global Iterable<String> start(Database.BatchableContext bc) {
        return EdvisorService.getIds(startDate, endDate);
    }

    global void execute(Database.BatchableContext bc, List<String> scope) {
        try {
            Set<String> enrollmentIds = new Set<String>(scope);
            Set<String> enrollmentIdsToSend = new Set<String>();

            Map<String, EdvisorApplication__c> edvisorAppsMap = queryEdvisorApplications(enrollmentIds);
            List<EdvisorApplication__c> toInsert = new List<EdvisorApplication__c>();

            for (String enrollmentId : enrollmentIds) {
                if (!edvisorAppsMap.containsKey(enrollmentId)) {
                    EdvisorApplication__c newApp = new EdvisorApplication__c(StudentEnrollmentId__c = enrollmentId, ProcessingStatus__c = 'Received');
                    toInsert.add(newApp);
                    enrollmentIdsToSend.add(enrollmentId);
                }
            }
            if (!toInsert.isEmpty())
                insert toInsert;

            System.enqueueJob(new EdvisorEnrollmentQueueable(new List<String>(enrollmentIdsToSend)));
        } catch (Exception e) {
        }
    }

    // Método para buscar aplicações existentes
    private Map<String, EdvisorApplication__c> queryEdvisorApplications(Set<String> enrollmentIds) {
        Map<String, EdvisorApplication__c> edvisorApplications = new Map<String, EdvisorApplication__c>();

        for (EdvisorApplication__c edvisorApplication : [
            SELECT Id, StudentEnrollmentId__c, ProcessingStatus__c, Application__c
            FROM EdvisorApplication__c
            WHERE StudentEnrollmentId__c IN :enrollmentIds
        ]) {
            edvisorApplications.put(edvisorApplication.StudentEnrollmentId__c, edvisorApplication);
        }

        return edvisorApplications;
    }

    // Método finish
    global void finish(Database.BatchableContext bc) {
    }
}