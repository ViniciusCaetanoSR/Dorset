public without sharing class ReceiptPDFGenerator {

    @TestVisible
    public static Blob testBlobContent;

    public class ReceiptPDFInput {
        @InvocableVariable(label='Payment Id' required=true)
        public Id paymentId;
    }

    @InvocableMethod(label='Gerar PDF do Recibo')
    public static void generatePdf(List<ReceiptPDFInput> inputs) {
        if (inputs == null || inputs.isEmpty()) {
            System.debug('Nenhum ID fornecido para geração do PDF.');
            return;
        }

        Id paymentId = inputs[0].paymentId;

        try {
            Payment__c payment = [
                SELECT Id, Opportunity__c, Name, Payment_Amount__c 
                FROM Payment__c 
                WHERE Id = :paymentId 
                LIMIT 1
            ];
            Id opportunityId = payment.Opportunity__c;
            String paymentName = payment.Name;
            Decimal paymentAmount = payment.Payment_Amount__c;

            if (opportunityId == null) {
                System.debug('Payment não possui Opportunity relacionada.');
                return;
            }

            PageReference pdfPage = Page.Receipt;
            pdfPage.getParameters().put('id', paymentId);

            Blob pdfBlob = (Test.isRunningTest() && testBlobContent != null)
                ? testBlobContent
                : pdfPage.getContentAsPDF();

            ContentVersion cv = new ContentVersion();
            cv.Title = 'Receipt - ' + paymentName + ' €' + paymentAmount;
            cv.PathOnClient = 'Receipt - ' + paymentName + ' €' + paymentAmount + '.pdf';
            cv.VersionData = pdfBlob;
            insert cv;

            cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];

            List<ContentDocumentLink> links = new List<ContentDocumentLink>();

            links.add(new ContentDocumentLink(
                ContentDocumentId = cv.ContentDocumentId,
                LinkedEntityId = opportunityId,
                ShareType = 'V',
                Visibility = 'AllUsers'
            ));

            links.add(new ContentDocumentLink(
                ContentDocumentId = cv.ContentDocumentId,
                LinkedEntityId = paymentId,
                ShareType = 'V',
                Visibility = 'AllUsers'
            ));

            insert links;

            System.debug('PDF gerado e vinculado à Opportunity com sucesso.');

        } catch (Exception e) {
            System.debug('Erro ao gerar PDF: ' + e.getMessage());
        }
    }
}