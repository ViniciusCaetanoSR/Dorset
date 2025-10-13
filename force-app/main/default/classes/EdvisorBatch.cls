global without sharing class EdvisorBatch implements Database.Batchable<String>, Database.AllowsCallouts, Database.Stateful {
    //Criação classes EdvisorBatch, EdvisorScheduler, EdvisorMapper
    //Criação objeto EdvisorApplication__c,
    //Criação Novo campo na Opportunity = EdvisorApplicationId__c

    // Constantes para evitar strings mágicas
    private static final String STATUS_RECEIVED = 'Received';
    private static final String STATUS_PROCESSED = 'Processed';
    private static final String STATUS_FAILED = 'Failed';
    private static final String EMAIL_RECIPIENT = 'vinicius.silva@srconsulting.io';
    private static final String EMAIL_SUBJECT = 'Edvisor Batch – Resumo';

    private final Datetime startDate;
    private final Datetime endDate;
    private Integer successCount = 0;
    private Integer errorCount = 0;

    // Construtor
    public EdvisorBatch(Datetime startDate, Datetime endDate) {
        this.startDate = startDate;
        this.endDate = endDate;
    }

    // Método start
    global Iterable<String> start(Database.BatchableContext bc) {
        return EdvisorService.getIds(startDate, endDate);
    }

    // Método execute
    global void execute(Database.BatchableContext bc, List<String> scope) {
        try {
            Set<String> enrollmentIds = new Set<String>(scope);
            List<EdvisorApplication__c> edvisorAppsToInsert = new List<EdvisorApplication__c>();
            List<Opportunity> opportunitiesToUpsert = new List<Opportunity>();

            // Busca aplicações existentes
            Map<String, EdvisorApplication__c> edvisorAppsMap = queryEdvisorApplications(enrollmentIds);

            // Cria novas aplicações para IDs não existentes
            createNewEdvisorApplications(enrollmentIds, edvisorAppsMap, edvisorAppsToInsert);

            // Processa aplicações
            processApplications(edvisorAppsMap, opportunitiesToUpsert);

            // Realiza upsert das oportunidades
            upsertOpportunities(opportunitiesToUpsert, edvisorAppsMap);

            // Salva as alterações
            saveEdvisorApplications(edvisorAppsMap);
        } catch (Exception e) {
            handleException(e);
        }
    }

    // Método para buscar aplicações existentes
    private Map<String, EdvisorApplication__c> queryEdvisorApplications(Set<String> enrollmentIds) {
        return new Map<String, EdvisorApplication__c>(
            [
                SELECT Id, StudentEnrollmentId__c, ProcessingStatus__c, Application__c
                FROM EdvisorApplication__c
                WHERE StudentEnrollmentId__c IN :enrollmentIds
            ]
        );
    }

    // Método para criar novas aplicações
    private void createNewEdvisorApplications(
        Set<String> enrollmentIds,
        Map<String, EdvisorApplication__c> edvisorAppsMap,
        List<EdvisorApplication__c> edvisorAppsToInsert
    ) {
        for (String enrollmentId : enrollmentIds) {
            if (!edvisorAppsMap.containsKey(enrollmentId)) {
                EdvisorApplication__c newApp = new EdvisorApplication__c(StudentEnrollmentId__c = enrollmentId, ProcessingStatus__c = STATUS_RECEIVED);
                edvisorAppsMap.put(enrollmentId, newApp);
                edvisorAppsToInsert.add(newApp);
            }
        }
    }

    // Método para processar aplicações
    private void processApplications(Map<String, EdvisorApplication__c> edvisorAppsMap, List<Opportunity> opportunitiesToUpsert) {
        for (EdvisorApplication__c edvisorApp : edvisorAppsMap.values()) {
            try {
                Opportunity opp = createOpportunity(edvisorApp.StudentEnrollmentId__c);
                opportunitiesToUpsert.add(opp);
            } catch (Exception e) {
                edvisorApp.ProcessingStatus__c = STATUS_FAILED;
                errorCount++;
                logError('Erro ao processar aplicação ' + edvisorApp.StudentEnrollmentId__c, e);
            }
        }
    }

    // Método para criar oportunidade
    // Mudar pra private depois
    public Opportunity createOpportunity(String studentEnrollmentId) {
        Map<String,Object> json = EdvisorService.fetchStudentEnrollmentReceived(studentEnrollmentId);
        Opportunity application = EdvisorMapper.fromApplication(json);
        return application;
        // return new Opportunity(
        //     Name = 'Edvisor – ' + studentEnrollmentId,
        //     CloseDate = Date.today(),
        //     StageName = 'Prospecting',
        //     EdvisorApplicationid__c = studentEnrollmentId
        // );
    }

    // Método para upsert de oportunidades
    private void upsertOpportunities(List<Opportunity> opportunitiesToUpsert, Map<String, EdvisorApplication__c> edvisorAppsMap) {
        if (!opportunitiesToUpsert.isEmpty()) {
            Database.UpsertResult[] results = Database.upsert(opportunitiesToUpsert, Opportunity.EdvisorApplicationid__c, false);

            for (Integer i = 0; i < results.size(); i++) {
                Opportunity opp = opportunitiesToUpsert[i];
                EdvisorApplication__c edvisorApp = edvisorAppsMap.get(opp.EdvisorApplicationid__c);

                if (edvisorApp == null)
                    continue;

                if (results[i].isSuccess()) {
                    edvisorApp.Application__c = results[i].getId();
                    edvisorApp.ProcessingStatus__c = STATUS_PROCESSED;
                    successCount++;
                } else {
                    edvisorApp.ProcessingStatus__c = STATUS_FAILED;
                    errorCount++;
                    logError('Erro ao upsert oportunidade ' + opp.EdvisorApplicationid__c, results[i].getErrors());
                }
            }
        }
    }

    // Método para salvar aplicações
    private void saveEdvisorApplications(Map<String, EdvisorApplication__c> edvisorAppsMap) {
        List<EdvisorApplication__c> toInsert = new List<EdvisorApplication__c>();
        List<EdvisorApplication__c> toUpdate = new List<EdvisorApplication__c>();

        for (EdvisorApplication__c app : edvisorAppsMap.values()) {
            if (app.Id == null) {
                toInsert.add(app);
            } else {
                toUpdate.add(app);
            }
        }

        if (!toInsert.isEmpty()) {
            Database.insert(toInsert, false);
        }
        if (!toUpdate.isEmpty()) {
            Database.update(toUpdate, false);
        }
    }

    // Método para log de erros
    private void logError(String context, Exception e) {
        System.debug(LoggingLevel.ERROR, context + ': ' + e.getMessage() + '\n' + e.getStackTraceString());
    }

    private void logError(String context, List<Database.Error> errors) {
        for (Database.Error err : errors) {
            System.debug(LoggingLevel.ERROR, context + ': ' + err.getMessage());
        }
    }

    // Método para tratamento geral de exceções
    private void handleException(Exception e) {
        errorCount++;
        System.debug(LoggingLevel.ERROR, 'Erro no processamento do batch: ' + e.getMessage() + '\n' + e.getStackTraceString());
    }

    // Método finish
    global void finish(Database.BatchableContext bc) {
        try {
            sendCompletionEmail();
        } catch (Exception e) {
            logError('Erro ao enviar e-mail de conclusão', e);
        }
    }

    // Método para enviar e-mail
    private void sendCompletionEmail() {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new List<String>{ EMAIL_RECIPIENT });
        mail.setSubject(EMAIL_SUBJECT);
        mail.setPlainTextBody(String.format('Período: {0} – {1}\nSucessos: {2}\nErros: {3}', new List<Object>{ startDate, endDate, successCount, errorCount }));
        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
    }
}