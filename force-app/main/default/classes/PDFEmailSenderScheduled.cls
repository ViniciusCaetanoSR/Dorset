public without sharing class PDFEmailSenderScheduled implements Schedulable {
    private PDFEmailSender.EmailInput input;

    public PDFEmailSenderScheduled(PDFEmailSender.EmailInput input) {
        this.input = input;
        System.debug(LoggingLevel.INFO, 'PDFEmailSenderScheduled initialized with input: ' + JSON.serialize(input));
    }

    public void execute(SchedulableContext sc) {
        System.debug(LoggingLevel.INFO, 'Starting execute method for PDFEmailSenderScheduled with applicationId: ' + input.applicationId);

        try {
            // Query the most recent Quote related to the Opportunity
            System.debug(LoggingLevel.DEBUG, 'Querying Quote for OpportunityId: ' + input.applicationId);
            Quote invoice;
            try {
                invoice = [
                    SELECT Id, Name
                    FROM Quote
                    WHERE OpportunityId = :input.applicationId
                    ORDER BY CreatedDate DESC
                    LIMIT 1
                ];
                System.debug(LoggingLevel.INFO, 'Quote retrieved: Id=' + invoice.Id + ', Name=' + invoice.Name);
            } catch (QueryException e) {
                System.debug(LoggingLevel.WARN, 'No Quote found for OpportunityId: ' + input.applicationId + '. Proceeding without invoice attachments.');
                invoice = null;
            }

            // Update the input with the Quote Id (or set to null if no Quote found)
            input.invoiceId = invoice != null ? invoice.Id : null;
            input.isScheduled = true; // Set the flag to indicate this input has been scheduled
            System.debug(LoggingLevel.DEBUG, 'Updated input.invoiceId to: ' + input.invoiceId);

            // Prepare inputs list and call sendEmail
            List<PDFEmailSender.EmailInput> inputs = new List<PDFEmailSender.EmailInput>{ input };
            System.debug(LoggingLevel.INFO, 'Calling PDFEmailSender.sendEmail with input: ' + JSON.serialize(inputs));
            PDFEmailSender.sendEmail(inputs);
            System.debug(LoggingLevel.INFO, 'PDFEmailSender.sendEmail executed successfully for applicationId: ' + input.applicationId);
        } catch (Exception e) {
            System.debug(
                LoggingLevel.ERROR,
                'Unexpected error in PDFEmailSenderScheduled.execute: ' + e.getMessage() + '. Stack Trace: ' + e.getStackTraceString()
            );
        }
    }
}