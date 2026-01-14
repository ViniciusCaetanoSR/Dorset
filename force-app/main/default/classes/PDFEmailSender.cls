public without sharing class PDFEmailSender {
    public class EmailInput {
        @InvocableVariable(label='Application Id' required=true)
        public Id applicationId;

        @InvocableVariable(label='Template Type (PO or ACC)' required=true)
        public String templateType;

        @InvocableVariable(label='Course Category Id')
        public String courseCategoryId;

        public String invoiceId;
        public Boolean isScheduled = false;
    }

    @InvocableMethod(label='Send PDF Email and Attach to Opportunity' description='Generates and sends a PDF email, attaching it to the specified Opportunity.')
    public static void sendEmail(List<EmailInput> inputs) {
        if (inputs == null || inputs.isEmpty()) {
            logError('No input provided for sendEmail.');
            return;
        }

        EmailInput input = inputs[0];
        if (!validateInput(input)) {
            return;
        }

        Opportunity opportunity = fetchOpportunity(input.applicationId);
        if (opportunity == null) {
            return;
        }

        if (hasLetterBeenSent(opportunity, input.templateType)) {
            logDebug('Letter already sent for Opportunity Id: ' + input.applicationId);
            return;
        }

        if (opportunity.StageName == 'PO' && !input.isScheduled) {
            logDebug('Opportunity StageName is PO, scheduling PDFEmailSenderScheduled.');
            scheduleEmailSender(input);
            return; // Não continuar executando aqui
        }

        List<PdfTemplate__c> templates = fetchTemplates(input.templateType, input.courseCategoryId);
        if (templates == null || templates.isEmpty()) {
            return;
        }

        List<PDFGeneratorService.PDFResult> pdfResults = new List<PDFGeneratorService.PDFResult>();
        List<ContentVersion> contentVersions = new List<ContentVersion>();

        for (PdfTemplate__c template : templates) {
            PDFGeneratorService.PDFResult pdfResult = generatePDF(input, template.Id);
            if (pdfResult == null) {
                continue;
            }

            ContentVersion cv = createContentVersion(pdfResult, input.applicationId);
            if (cv == null) {
                continue;
            }

            pdfResults.add(pdfResult);
            contentVersions.add(cv);
        }

        if (pdfResults.isEmpty()) {
            return;
        }

        Messaging.SingleEmailMessage email = buildEmail(opportunity, templates, pdfResults, input);
        if (email == null) {
            return;
        }

        updateOpportunityFlags(opportunity, input.templateType);

        executeDmlOperations(opportunity, contentVersions, email);
    }

    //Método para agendar a execução /TODO: Descomentar quando necessário
    private static void scheduleEmailSender(EmailInput input) {
        String jobName = 'PDFEmailSenderScheduled_' + String.valueOf(DateTime.now().getTime());

        System.schedule(
            jobName,
            System.now().addMinutes(1).format('ss mm HH dd MM ? yyyy'), // agenda para rodar em 1 minuto
            new PDFEmailSenderScheduled(input)
        );

        logDebug('Scheduled job with name: ' + jobName);
    }

    // Método para executar o envio de e-mail imediatamente
    // public static void scheduleEmailSender(EmailInput input) {
    //     System.debug(LoggingLevel.INFO, 'Starting sendEmailImmediately with input: ' + JSON.serialize(input));

    //     try {
    //         // Query the most recent Quote related to the Opportunity
    //         System.debug(LoggingLevel.DEBUG, 'Querying Quote for OpportunityId: ' + input.applicationId);
    //         Quote invoice;
    //         try {
    //             invoice = [
    //                 SELECT Id, Name
    //                 FROM Quote
    //                 WHERE OpportunityId = :input.applicationId
    //                 ORDER BY CreatedDate DESC
    //                 LIMIT 1
    //             ];
    //             System.debug(LoggingLevel.INFO, 'Quote retrieved: Id=' + invoice.Id + ', Name=' + invoice.Name);
    //         } catch (QueryException e) {
    //             System.debug(LoggingLevel.WARN, 'No Quote found for OpportunityId: ' + input.applicationId + '. Proceeding without invoice attachments.');
    //             invoice = null;
    //         }

    //         // Update the input with the Quote Id (or set to null if no Quote found)
    //         input.invoiceId = invoice != null ? invoice.Id : null;
    //         input.isScheduled = true; // Mantém consistência com o comportamento agendado
    //         System.debug(LoggingLevel.DEBUG, 'Updated input.invoiceId to: ' + input.invoiceId);

    //         // Prepare inputs list and call sendEmail
    //         List<EmailInput> inputs = new List<EmailInput>{ input };
    //         System.debug(LoggingLevel.INFO, 'Calling sendEmail with input: ' + JSON.serialize(inputs));
    //         sendEmail(inputs); // Chama o método sendEmail existente na classe
    //         System.debug(LoggingLevel.INFO, 'sendEmail executed successfully for applicationId: ' + input.applicationId);
    //     } catch (Exception e) {
    //         System.debug(LoggingLevel.ERROR, 'Unexpected error in sendEmailImmediately: ' + e.getMessage() + '. Stack Trace: ' + e.getStackTraceString());
    //     }
    // }

    private static Boolean validateInput(EmailInput input) {
        if (input.applicationId == null || String.isBlank(input.templateType)) {
            logError('Invalid input: Application Id or Template Type is missing.');
            return false;
        }
        return true;
    }
    private static Opportunity fetchOpportunity(Id applicationId) {
        try {
            return [
                SELECT Id, Name, StageName, Account.PersonEmail, Letter_of_offer_sent__c, Letter_of_acceptance_sent__c
                FROM Opportunity
                WHERE Id = :applicationId
                LIMIT 1
            ];
        } catch (QueryException e) {
            logError('Error querying Opportunity: ' + e.getMessage());
            return null;
        }
    }

    private static List<PdfTemplate__c> fetchTemplates(String templateType, String courseCategoryId) {
        try {
            return [
                SELECT Id, Name, HTMLContent__c, EmailBody__c, EmailSubject__c, CourseCategory__c, CCEmailAddresses__c
                FROM PdfTemplate__c
                WHERE Stage__c = :templateType AND Active__c = TRUE AND CourseCategory__c = :courseCategoryId
            ];
        } catch (QueryException e) {
            logError('Error querying PdfTemplate: ' + e.getMessage());
            return new List<PdfTemplate__c>();
        }
    }

    private static Boolean hasLetterBeenSent(Opportunity opp, String templateType) {
        if (templateType == 'PO' && opp.Letter_of_offer_sent__c) {
            return true;
        } else if (templateType == 'ACC' && opp.Letter_of_acceptance_sent__c) {
            return true;
        }
        return false;
    }

    private static PDFGeneratorService.PDFResult generatePDF(EmailInput input, String templateId) {
        try {
            if (Test.isRunningTest()) {
                PDFGeneratorService.IPDFGenerator mockGenerator = new PDFGeneratorService.MockPDFGenerator();
                return PDFGeneratorService.generatePDF(input.applicationId, input.templateType, input.courseCategoryId, templateId, mockGenerator);
            } else {
                return PDFGeneratorService.generatePDF(input.applicationId, input.templateType, input.courseCategoryId, templateId);
            }
        } catch (Exception e) {
            logError('Error generating PDF: ' + e.getMessage());
            return null;
        }
    }

    private static ContentVersion createContentVersion(PDFGeneratorService.PDFResult pdfResult, Id applicationId) {
        String timestamp = DateTime.now().format('dd_MMMM_yyyy_HHmmssSSS');
        String uniqueFileName = pdfResult.fileName.replace('.pdf', '') + '_' + timestamp + '.pdf';

        try {
            return new ContentVersion(
                Title = uniqueFileName,
                PathOnClient = uniqueFileName,
                VersionData = pdfResult.pdfBlob,
                IsMajorVersion = true,
                FirstPublishLocationId = applicationId
            );
        } catch (Exception e) {
            logError('Error creating ContentVersion: ' + e.getMessage());
            return null;
        }
    }

    private static Messaging.SingleEmailMessage buildEmail(
        Opportunity opp,
        List<PdfTemplate__c> templates,
        List<PDFGeneratorService.PDFResult> pdfResults,
        EmailInput input
    ) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

        // Validação da oportunidade e email do contato
        if (opp == null || opp.Account == null || String.isBlank(opp.Account.PersonEmail)) {
            logError('Oportunidade inválida ou conta sem e-mail definido.');
            return null;
        }

        // Set Org-Wide Email Address
        try {
            OrgWideEmailAddress owea = [
                SELECT Id
                FROM OrgWideEmailAddress
                WHERE Purpose = 'DefaultNoreply'
                LIMIT 1
            ];
            mail.setOrgWideEmailAddressId(owea.Id);
        } catch (QueryException e) {
            logError('Erro ao consultar OrgWideEmailAddress: ' + e.getMessage());
            return null;
        }

        // Set recipient
        mail.setToAddresses(new List<String>{ opp.Account.PersonEmail });

        // Assunto, corpo e CC a partir do template
        if (pdfResults != null && !pdfResults.isEmpty()) {
            for (PDFGeneratorService.PDFResult pdfResult : pdfResults) {
                if (String.isNotBlank(pdfResult.emailSubject)) {
                    mail.setSubject(pdfResult.emailSubject);
                    mail.setHtmlBody(pdfResult.emailBody);
                    mail.setCcAddresses(pdfResult.CCEmailAddresses);
                    break; // Apenas o primeiro template válido
                }
            }
        } else {
            logError('Nenhum template de e-mail válido foi fornecido.');
        }

        // Anexar PDFs gerados
        List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();
        if (pdfResults != null) {
            for (PDFGeneratorService.PDFResult result : pdfResults) {
                if (result != null && result.pdfBlob != null) {
                    Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
                    attachment.setFileName(result.fileName);
                    attachment.setBody(result.pdfBlob);
                    attachment.setContentType('application/pdf');
                    attachments.add(attachment);
                }
            }
        }

        // Anexos da invoice, se houver
        if (input != null && input.invoiceId != null) {
            try {
                List<ContentDocumentLink> docLinks = [
                    SELECT ContentDocumentId
                    FROM ContentDocumentLink
                    WHERE LinkedEntityId = :input.invoiceId
                ];

                if (!docLinks.isEmpty()) {
                    List<Id> contentDocIds = new List<Id>();
                    for (ContentDocumentLink link : docLinks) {
                        if (link.ContentDocumentId != null) {
                            contentDocIds.add(link.ContentDocumentId);
                        }
                    }

                    if (!contentDocIds.isEmpty()) {
                        List<ContentVersion> versions = [
                            SELECT Title, VersionData, FileExtension
                            FROM ContentVersion
                            WHERE ContentDocumentId IN :contentDocIds AND IsLatest = TRUE
                        ];

                        for (ContentVersion cv : versions) {
                            if (cv.VersionData != null) {
                                Messaging.EmailFileAttachment quoteAttachment = new Messaging.EmailFileAttachment();
                                quoteAttachment.setFileName(cv.Title + '.' + cv.FileExtension);
                                quoteAttachment.setBody(cv.VersionData);
                                quoteAttachment.setContentType('application/octet-stream');
                                attachments.add(quoteAttachment);
                            }
                        }
                    }
                }
            } catch (Exception e) {
                logError('Erro ao buscar anexos da invoice (Quote): ' + e.getMessage());
            }
        }

        mail.setFileAttachments(attachments);
        return mail;
    }

    private static void updateOpportunityFlags(Opportunity opp, String templateType) {
        if (templateType == 'PO') {
            opp.Letter_of_offer_sent__c = true;
        } else if (templateType == 'ACC') {
            opp.Letter_of_acceptance_sent__c = true;
        } else {
            logDebug('Unknown template type: ' + templateType);
        }
    }

    private static void executeDmlOperations(Opportunity opp, List<ContentVersion> contentVersions, Messaging.SingleEmailMessage email) {
        try {
            insert contentVersions;

            List<Id> contentVersionIds = new List<Id>();
            for (ContentVersion cv : contentVersions) {
                contentVersionIds.add(cv.Id);
            }

            Map<Id, ContentVersion> insertedVersions = new Map<Id, ContentVersion>(
                [SELECT Id, ContentDocumentId, FirstPublishLocationId FROM ContentVersion WHERE Id IN :contentVersionIds]
            );

            List<ContentDocumentLink> docLinks = new List<ContentDocumentLink>();

            for (ContentVersion cv : insertedVersions.values()) {
                // Evita criar links duplicados
                List<ContentDocumentLink> existingLinks = [
                    SELECT Id
                    FROM ContentDocumentLink
                    WHERE ContentDocumentId = :cv.ContentDocumentId AND LinkedEntityId = :cv.FirstPublishLocationId
                    LIMIT 1
                ];

                if (existingLinks.isEmpty()) {
                    docLinks.add(
                        new ContentDocumentLink(
                            ContentDocumentId = cv.ContentDocumentId,
                            LinkedEntityId = cv.FirstPublishLocationId,
                            ShareType = 'V',
                            Visibility = 'AllUsers'
                        )
                    );
                }
            }

            if (!docLinks.isEmpty()) {
                insert docLinks;
            }

            update opp;
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });
        } catch (DmlException e) {
            logError('Erro ao executar DML: ' + e.getMessage());
        } catch (EmailException e) {
            logError('Erro ao enviar email: ' + e.getMessage());
        }
    }

    private static void logError(String message) {
        System.debug(LoggingLevel.ERROR, 'PDFEmailSender: ' + message);
        // Consider integrating with a custom logging framework if available
    }

    private static void logDebug(String message) {
        System.debug(LoggingLevel.DEBUG, 'PDFEmailSender: ' + message);
    }
}