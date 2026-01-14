public class EdvisorFileQueueable implements Queueable, Database.AllowsCallouts {
    private static final Integer BATCH_SIZE = 10; // Limite de arquivos por execução
    private static final Integer MAX_DEPTH = 5; // Limite de profundidade de recursão

    private List<String> urls;
    private List<String> names;
    private List<Id> oppIds;
    private Integer depth;

    public EdvisorFileQueueable(List<String> urls, List<String> names, List<Id> oppIds) {
        this(urls, names, oppIds, 1);
    }

    public EdvisorFileQueueable(List<String> urls, List<String> names, List<Id> oppIds, Integer depth) {
        this.urls = urls;
        this.names = names;
        this.oppIds = oppIds;
        this.depth = depth;
    }

    public void execute(QueueableContext context) {
        try {
            Integer processCount = Math.min(BATCH_SIZE, urls.size());
            List<ContentVersion> contentVersions = new List<ContentVersion>();
            List<Id> oppIdsToLink = new List<Id>();
            List<String> namesToLink = new List<String>();

            for (Integer i = 0; i < processCount; i++) {
                try {
                    HttpRequest req = new HttpRequest();
                    req.setEndpoint(urls[i]);
                    req.setMethod('GET');

                    Http http = new Http();
                    HttpResponse res = http.send(req);

                    if (res.getStatusCode() == 200) {
                        Blob body = res.getBodyAsBlob();
                        ContentVersion cv = new ContentVersion(Title = names[i], PathOnClient = names[i], VersionData = body);
                        contentVersions.add(cv);
                        oppIdsToLink.add(oppIds[i]);
                        namesToLink.add(names[i]);
                    } else {
                        System.debug('Erro ao baixar arquivo ' + names[i] + ': ' + res.getStatusCode());
                    }
                } catch (Exception e) {
                    System.debug('Erro ao baixar arquivo: ' + e.getMessage());
                }
            }

            if (!contentVersions.isEmpty()) {
                insert contentVersions;
                // Os Ids retornados pelo insert estão na mesma ordem da lista inserida
                List<Id> insertedIds = new List<Id>();
                for (ContentVersion cv : contentVersions) {
                    insertedIds.add(cv.Id);
                }

                List<ContentVersion> insertedCVs = [
                    SELECT Id, ContentDocumentId
                    FROM ContentVersion
                    WHERE Id IN :insertedIds
                ];

                // Mapeia Id para ContentVersion
                Map<Id, ContentVersion> idToCV = new Map<Id, ContentVersion>();
                for (ContentVersion cv : insertedCVs) {
                    idToCV.put(cv.Id, cv);
                }

                List<ContentDocumentLink> links = new List<ContentDocumentLink>();
                for (Integer i = 0; i < insertedIds.size(); i++) {
                    ContentVersion cv = idToCV.get(insertedIds[i]);
                    if (cv != null) {
                        ContentDocumentLink cdl = new ContentDocumentLink();
                        cdl.ContentDocumentId = cv.ContentDocumentId;
                        cdl.LinkedEntityId = oppIdsToLink[i];
                        cdl.ShareType = 'V';
                        cdl.Visibility = 'AllUsers';
                        links.add(cdl);
                    }
                }

                insert links;
            }

            // Se ainda restam arquivos, enfileira novo job, mas respeita o limite de profundidade
            if (urls.size() > BATCH_SIZE && depth < MAX_DEPTH) {
                List<String> remainingUrls = new List<String>();
                List<String> remainingNames = new List<String>();
                List<Id> remainingOppIds = new List<Id>();
                for (Integer i = BATCH_SIZE; i < urls.size(); i++) {
                    remainingUrls.add(urls[i]);
                    remainingNames.add(names[i]);
                    remainingOppIds.add(oppIds[i]);
                }
                System.enqueueJob(new EdvisorFileQueueable(remainingUrls, remainingNames, remainingOppIds, depth + 1));
            }
        } catch (Exception e) {
            System.debug('Erro no processamento dos arquivos: ' + e.getMessage());
        }
    }
}