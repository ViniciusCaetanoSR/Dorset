public class EdvisorEnrollmentQueueable implements Queueable, Database.AllowsCallouts {
    public static Boolean disableFileEnqueueInTest = false;
    private List<String> ids;

    public EdvisorEnrollmentQueueable(List<String> enrollmentIds) {
        this.ids = enrollmentIds;
    }

    public void execute(QueueableContext qc) {
        Map<String, Map<String, Object>> dataById = new Map<String, Map<String, Object>>();
        for (String idStr : ids) {
            try {
                Map<String, Object> data = EdvisorService.fetchStudentEnrollmentReceived(idStr);
                if (data != null)
                    dataById.put(idStr, data);
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'Callout falhou para ' + idStr + ': ' + e.getMessage());
            }
        }

        if (dataById.isEmpty())
            return;

        List<EdvisorApplication__c> appsToUpdate = new List<EdvisorApplication__c>();
        List<String> allUrls = new List<String>();
        List<String> allNames = new List<String>();
        List<Id> allOppIds = new List<Id>();

        for (String idStr : dataById.keySet()) {
            try {
                Map<String, Object> json = dataById.get(idStr);

                Opportunity opp = EdvisorMapper.fromApplication(json);

                try {
                    if (opp != null && opp.Id != null && opp.getSObjectType().getDescribe().fields.getMap().containsKey('EdvisorApplicationid__c')) {
                        opp.EdvisorApplicationid__c = idStr;
                    }
                } catch (Exception ignore) {
                }

                List<EdvisorApplication__c> apps = [
                    SELECT Id, StudentEnrollmentId__c
                    FROM EdvisorApplication__c
                    WHERE StudentEnrollmentId__c = :idStr
                    LIMIT 1
                ];

                if (!apps.isEmpty()) {
                    EdvisorApplication__c app = apps[0];
                    app.Application__c = opp != null ? opp.Id : null;
                    app.ProcessingStatus__c = 'Processed';
                    appsToUpdate.add(app);
                }

                List<String> urls = extractUrls(json);
                List<String> names = extractNames(json);
                if (!urls.isEmpty() && opp != null && opp.Id != null) {
                    allUrls.addAll(urls);
                    allNames.addAll(names);
                    // Adiciona o opp.Id para cada arquivo
                    for (Integer i = 0; i < urls.size(); i++) {
                        allOppIds.add(opp.Id);
                    }
                }
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, '----------------------------------------------------------------------------------------------');
                System.debug(LoggingLevel.ERROR, 'Falha ao processar a opportunity: ' + idStr);
                System.debug(LoggingLevel.ERROR, 'Mensagem: ' + e.getMessage());
                System.debug(LoggingLevel.ERROR, 'Tipo: ' + e.getTypeName());
                System.debug(LoggingLevel.ERROR, 'StackTrace: ' + e.getStackTraceString());
                if (e.getCause() != null) {
                    System.debug(LoggingLevel.ERROR, 'Causa: ' + e.getCause().getMessage());
                }
                System.debug(LoggingLevel.ERROR, '----------------------------------------------------------------------------------------------');

                try {
                    List<EdvisorApplication__c> appsFail = [
                        SELECT Id
                        FROM EdvisorApplication__c
                        WHERE StudentEnrollmentId__c = :idStr
                        LIMIT 1
                    ];
                    if (!appsFail.isEmpty()) {
                        EdvisorApplication__c appFail = appsFail[0];
                        appFail.ProcessingStatus__c = 'Failed';
                        appsToUpdate.add(appFail);
                    }
                } catch (Exception ignore) {
                }
            }
        }

        if (!appsToUpdate.isEmpty())
            update appsToUpdate;

        // Enfileira apenas um job para todos os arquivos, passando a lista de oppIds
        if (!allUrls.isEmpty() && !disableFileEnqueueInTest) {
            System.enqueueJob(new EdvisorFileQueueable(allUrls, allNames, allOppIds));
        }
    }

    private static List<String> extractUrls(Map<String, Object> json) {
        List<String> urls = new List<String>();
        List<Object> filesInfo = (List<Object>) json.get('studentEnrollmentFiles');
        if (filesInfo == null)
            return urls;
        for (Object fileObj : filesInfo) {
            Map<String, Object> fileMap = (Map<String, Object>) fileObj;
            Map<String, Object> fileDetails = (Map<String, Object>) fileMap.get('file');
            String urlFile = (String) fileDetails.get('url');
            if (String.isNotBlank(urlFile))
                urls.add(urlFile);
        }
        return urls;
    }

    private static List<String> extractNames(Map<String, Object> json) {
        List<String> names = new List<String>();
        if (json == null)
            return names;

        List<Object> filesInfo = (List<Object>) json.get('studentEnrollmentFiles');
        if (filesInfo == null)
            return names;

        for (Object fileObj : filesInfo) {
            Map<String, Object> fileMap = (Map<String, Object>) fileObj;
            if (fileMap == null)
                continue;

            Map<String, Object> fileDetails = (Map<String, Object>) fileMap.get('file');
            if (fileDetails == null)
                continue;

            String nameFile = (String) fileDetails.get('name');
            if (String.isNotBlank(nameFile)) {
                names.add(nameFile);
            }
        }
        return names;
    }
}