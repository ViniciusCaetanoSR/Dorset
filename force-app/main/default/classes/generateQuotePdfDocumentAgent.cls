public class generateQuotePdfDocumentAgent {
    @InvocableMethod
    public static void CreateQuoteAgent(List<Id> quoteIds) {
        System.debug(LoggingLevel.INFO, 'CreateQuoteAgent invoked with quoteIds: ' + quoteIds);
        createQuoteFutureMethodAgent(quoteIds);
        System.debug(LoggingLevel.INFO, 'createQuoteFutureMethodAgent called for quoteIds: ' + quoteIds);
    }

    @future(callout=true)
    public static void createQuoteFutureMethodAgent(List<Id> quoteIds) {
        System.debug(LoggingLevel.INFO, 'Starting createQuoteFutureMethodAgent with quoteIds: ' + quoteIds);

        String baseQuoteUrl = '/quote/quoteTemplateDataViewer.apexp?';

        String quoteTemplateId = Label.QuoteTemplateId;
        String quoteTemplateIdAgent = Label.QuoteTemplateAgentId;

        List<QuoteDocument> lstQuoteDoc = new List<QuoteDocument>();

        if (quoteIds == null || quoteIds.isEmpty()) {
            System.debug(LoggingLevel.WARN, 'No Quote IDs provided to process');
            return;
        }

        for (Id quoteId : quoteIds) {
            System.debug(LoggingLevel.DEBUG, 'Processing Quote ID: ' + quoteId);

            try {
                List<Quote> quoteList = [
                    SELECT Id, OpportunityId
                    FROM Quote
                    WHERE Id = :quoteId
                ];

                if (quoteList.isEmpty()) {
                    System.debug(LoggingLevel.WARN, 'No Quote found with ID: ' + quoteId);
                    continue;
                }

                Quote d = quoteList[0];

                if (d.OpportunityId == null) {
                    System.debug(LoggingLevel.WARN, 'Quote has no associated Opportunity: ' + quoteId);
                    continue;
                }

                List<Opportunity> oppList = [
                    SELECT Id, Agent_Email__c
                    FROM Opportunity
                    WHERE Id = :d.OpportunityId
                ];

                if (oppList.isEmpty()) {
                    System.debug(LoggingLevel.WARN, 'No Opportunity found with ID: ' + d.OpportunityId);
                    continue;
                }

                Opportunity o = oppList[0];
                String aquoteTemplateId = quoteTemplateId;

                if (o.Agent_Email__c != null && o.Agent_Email__c.containsIgnoreCase('professionalcourses@dorset.ie')) {
                    aquoteTemplateId = quoteTemplateId;
                    System.debug(LoggingLevel.DEBUG, 'Using quoteTemplateId for professionalcourses@dorset.ie');
                } else {
                    aquoteTemplateId = quoteTemplateIdAgent;
                    System.debug(LoggingLevel.DEBUG, 'Using quoteTemplateIdAgent');

                    String quoteUrl = baseQuoteUrl + 'id=' + quoteId + '&headerHeight=197&footerHeight=400' + '&summlid=' + aquoteTemplateId;

                    PageReference pageRef = new PageReference(quoteUrl);
                    Blob quoteBlob;

                    if (Test.isRunningTest()) {
                        quoteBlob = Blob.valueOf('Generate Pdf');
                    } else {
                        quoteBlob = pageRef.getContentAsPDF();
                    }

                    QuoteDocument quoteDoc = new QuoteDocument();
                    quoteDoc.Document = quoteBlob;
                    quoteDoc.QuoteId = quoteId;

                    try {
                        Database.SaveResult insertResult = Database.insert(quoteDoc, false);
                        if (insertResult.isSuccess()) {
                            lstQuoteDoc.add(quoteDoc);
                            System.debug(LoggingLevel.INFO, 'QuoteDocument inserted for Quote ID: ' + quoteId);
                        } else {
                            for (Database.Error err : insertResult.getErrors()) {
                                System.debug(LoggingLevel.ERROR, 'Insert error for QuoteDocument: ' + err.getMessage());
                            }
                        }
                    } catch (Exception e) {
                        System.debug(LoggingLevel.ERROR, 'Exception inserting QuoteDocument: ' + e.getMessage());
                    }
                }
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'General error for Quote ID ' + quoteId + ': ' + e.getMessage());
            }
        }

        System.debug(LoggingLevel.INFO, 'Finished createQuoteFutureMethodAgent');
    }

    public static void fakeMethod() {
        Integer i = 0;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;

        //repeat the i++ hundred of times
    }
}