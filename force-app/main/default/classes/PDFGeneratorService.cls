public without sharing class PDFGeneratorService {
    // Constants
    private static final String MOBILITY_AGREEMENT_TEMPLATE = 'Mobility';
    private static final String MOBILITY_AGREEMENT_FILENAME = 'ERASMUS + Mobility Agreement.pdf';
    // private static final Pattern PLACEHOLDER_PATTERN = Pattern.compile('\\{\\{([a-zA-Z0-9_]+)\\}\\}');
    private static final Pattern PLACEHOLDER_PATTERN = Pattern.compile('\\{\\{([a-zA-Z0-9_\\.]+)\\}\\}');
    private static final Pattern EMAIL_PATTERN = Pattern.compile('^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$');

    // DTO for PDF generation results
    public class PDFResult {
        public Blob pdfBlob;
        public String fileName;
        public String emailBody;
        public String emailSubject;
        public List<String> CCEmailAddresses;
    }

    // Interface for PDF generation (dependency injection)
    public interface IPDFGenerator {
        Blob generatePDF(PageReference pageRef);
    }

    // Default PDF generator implementation
    public class DefaultPDFGenerator implements IPDFGenerator {
        public Blob generatePDF(PageReference pageRef) {
            return pageRef.getContentAsPDF();
        }
    }

    // Mock PDF generator for testing
    public class MockPDFGenerator implements IPDFGenerator {
        public Blob generatePDF(PageReference pageRef) {
            return Blob.valueOf('%PDF-1.4 Mock PDF Content');
        }
    }

    // Main service method
    public static PDFResult generatePDF(Id applicationId, String templateType, String courseCategoryId, String templateId) {
        return generatePDF(applicationId, templateType, courseCategoryId, templateId, new DefaultPDFGenerator());
    }

    // Overloaded method with dependency injection
    @TestVisible
    public static PDFResult generatePDF(Id applicationId, String templateType, String courseCategoryId, String templateId, IPDFGenerator pdfGenerator) {
        validateParameters(applicationId, templateId);

        PDFResult result = new PDFResult();
        try {
            Opportunity application = getApplication(applicationId);
            PDFTemplate__c template = getTemplate(templateId);

            Set<String> placeholders = getAllPlaceholders(template);
            Opportunity appWithFields = queryApplicationWithRequiredFields(applicationId, placeholders);

            result.emailBody = processEmailBody(template, appWithFields);
            result.emailSubject = template.EmailSubject__c;
            result.CCEmailAddresses = processCCEmails(template.CCEmailAddresses__c);

            if (isMobilityTemplate(template)) {
                result.fileName = MOBILITY_AGREEMENT_FILENAME;
                result.pdfBlob = generateMobilityPDF(applicationId, pdfGenerator);
            } else {
                result.fileName = generateStandardFilename(templateType, appWithFields);
                result.pdfBlob = generateStandardPDF(applicationId, templateType, courseCategoryId, pdfGenerator);
            }
        } catch (Exception e) {
            logError('PDF generation failed', e);
            throw new AuraHandledException('Error generating PDF: ' + e.getMessage());
        }

        return result;
    }

    // Parameter validation
    private static void validateParameters(Id applicationId, String templateId) {
        if (applicationId == null || templateId == null) {
            throw new AuraHandledException('Application ID and Template ID cannot be null');
        }
    }

    // Application retrieval
    private static Opportunity getApplication(Id applicationId) {
        try {
            return [
                SELECT Id, Name, Course_Category__c
                FROM Opportunity
                WHERE Id = :applicationId
                LIMIT 1
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving application: ' + e.getMessage());
        }
    }

    // Template retrieval
    private static PDFTemplate__c getTemplate(String templateId) {
        try {
            return [
                SELECT Id, Name, CCEmailAddresses__c, HTMLContent__c, EmailBody__c, EmailSubject__c, CourseCategory__c
                FROM PDFTemplate__c
                WHERE Id = :templateId
                LIMIT 1
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving PDF template: ' + e.getMessage());
        }
    }

    // Extract all placeholders from template content
    private static Set<String> getAllPlaceholders(PDFTemplate__c template) {
        Set<String> placeholders = new Set<String>();

        placeholders.addAll(extractPlaceholders(template.HTMLContent__c));
        placeholders.addAll(extractPlaceholders(template.EmailBody__c));

        return placeholders;
    }

    // Extract placeholders from content
    public static Set<String> extractPlaceholders(String content) {
        Set<String> placeholders = new Set<String>();
        if (String.isBlank(content))
            return placeholders;
        Matcher matcher = PLACEHOLDER_PATTERN.matcher(content);
        while (matcher.find()) {
            placeholders.add(matcher.group(1));
        }
        return placeholders;
    }

    // Dynamic query for application with required fields
    private static Opportunity queryApplicationWithRequiredFields(Id applicationId, Set<String> placeholders) {
        String query = buildDynamicQuery(placeholders);
        try {
            return Database.query(query);
        } catch (Exception e) {
            throw new AuraHandledException('Error executing dynamic query: ' + e.getMessage());
        }
    }

    // Build dynamic SOQL query
    private static String buildDynamicQuery(Set<String> placeholders) {
        System.debug('### buildDynamicQuery - Received placeholders: ' + placeholders);

        Schema.DescribeSObjectResult objDescribe = Opportunity.SObjectType.getDescribe();
        Map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap();
        System.debug('### buildDynamicQuery - Available fields on Opportunity: ' + fieldMap.keySet());

        // Mapa para evitar duplicatas (chave = lowercase, valor = formato original)
        Map<String, String> uniqueFieldsMap = new Map<String, String>();
        uniqueFieldsMap.put('id', 'Id'); // Garante que "Id" sempre esteja na query

        for (String fieldName : placeholders) {
            System.debug('### buildDynamicQuery - Processing placeholder: ' + fieldName);

            String normalizedFieldName = fieldName.toLowerCase(); // Chave de comparação

            if (fieldName.contains('.')) {
                // Campo de relacionamento (ex: Account.FirstName)
                if (!uniqueFieldsMap.containsKey(normalizedFieldName)) {
                    System.debug('### buildDynamicQuery - Adding relationship field: ' + fieldName);
                    uniqueFieldsMap.put(normalizedFieldName, fieldName); // Mantém o formato original
                }
            } else if (fieldMap.containsKey(normalizedFieldName)) {
                // Campo padrão (ex: Name, Start_Date__c)
                if (!uniqueFieldsMap.containsKey(normalizedFieldName)) {
                    System.debug('### buildDynamicQuery - Adding direct field: ' + fieldName);
                    uniqueFieldsMap.put(normalizedFieldName, fieldName); // Mantém o formato original
                }
            } else {
                System.debug('### buildDynamicQuery - Skipping unknown field: ' + fieldName);
            }
        }

        // Adiciona "Name" se não estiver presente (verifica em minúsculo)
        if (!uniqueFieldsMap.containsKey('name')) {
            System.debug('### buildDynamicQuery - Adding fallback field "Name"');
            uniqueFieldsMap.put('name', 'Name');
        }

        // Converte os valores do mapa para uma lista (sem duplicatas)
        List<String> fieldsList = new List<String>(uniqueFieldsMap.values());
        String query = 'SELECT ' + String.join(fieldsList, ', ') + ' FROM Opportunity WHERE Id = :applicationId LIMIT 1';
        System.debug('### buildDynamicQuery - Final Query: ' + query);

        return query;
    }

    // Process email body with placeholders
    private static String processEmailBody(PDFTemplate__c template, SObject record) {
        if (String.isBlank(template.EmailBody__c))
            return '';

        return replacePlaceholders(template.EmailBody__c, record);
    }

    // Replace placeholders in content
    public static String replacePlaceholders(String content, SObject record) {
        System.debug('### replacePlaceholders - Original content: ' + content);

        if (String.isBlank(content)) {
            System.debug('### replacePlaceholders - Content is blank, returning empty string');
            return '';
        }

        String result = content;
        Matcher matcher = PLACEHOLDER_PATTERN.matcher(result);

        while (matcher.find()) {
            String placeholder = matcher.group();
            String fieldName = matcher.group(1);
            System.debug('### replacePlaceholders - Found placeholder: ' + placeholder + ' | Field name: ' + fieldName);

            String replacementValue = '';
            // Split the fieldName to handle relationships (e.g., Account.FirstName)
            if (fieldName.contains('.')) {
                List<String> fieldParts = fieldName.split('\\.');
                if (fieldParts.size() == 2) {
                    String relationshipName = fieldParts[0]; // e.g., Account
                    String relatedField = fieldParts[1]; // e.g., FirstName

                    // Get the related object (e.g., Account)
                    SObject relatedRecord = record.getSObject(relationshipName);
                    if (relatedRecord != null) {
                        // Get the field value from the related object
                        Map<String, Schema.SObjectField> relatedFieldMap = relatedRecord.getSObjectType().getDescribe().fields.getMap();
                        if (relatedFieldMap.containsKey(relatedField.toLowerCase())) {
                            Object fieldValue = relatedRecord.get(relatedField);
                            replacementValue = formatFieldValue(fieldValue, relatedFieldMap.get(relatedField.toLowerCase()));
                            System.debug('### replacePlaceholders - Replacing placeholder "' + placeholder + '" with value: ' + replacementValue);
                        } else {
                            System.debug('### replacePlaceholders - Related field not found: ' + relatedField + ', replacing with empty string');
                        }
                    } else {
                        System.debug('### replacePlaceholders - Related record not found for: ' + relationshipName + ', replacing with empty string');
                    }
                }
            } else {
                // Handle non-relationship fields (same as before)
                Map<String, Schema.SObjectField> fieldMap = record.getSObjectType().getDescribe().fields.getMap();
                System.debug('### replacePlaceholders - Field Map Keys: ' + fieldMap.keySet());

                if (fieldMap.containsKey(fieldName.toLowerCase())) {
                    Object fieldValue = record.get(fieldName);
                    replacementValue = formatFieldValue(fieldValue, fieldMap.get(fieldName.toLowerCase()));
                    System.debug('### replacePlaceholders - Replacing placeholder "' + placeholder + '" with value: ' + replacementValue);
                } else {
                    System.debug('### replacePlaceholders - Field not found: ' + fieldName + ', replacing with empty string');
                }
            }

            result = result.replace(placeholder, replacementValue);
        }

        System.debug('### replacePlaceholders - Final result: ' + result);
        return result;
    }

    // Format field value based on type
    private static String formatFieldValue(Object fieldValue, Schema.SObjectField field) {
        if (fieldValue == null)
            return '';

        Schema.DisplayType fieldType = field.getDescribe().getType();

        if (fieldType == Schema.DisplayType.Date) {
            return formatDate((Date) fieldValue);
        } else if (fieldType == Schema.DisplayType.DateTime) {
            return formatDate(((Datetime) fieldValue).date());
        }
        return String.valueOf(fieldValue);
    }

    // Format date consistently
    public static String formatDate(Date dateValue) {
        if (dateValue == null)
            return '';
        return DateTime.newInstance(dateValue.year(), dateValue.month(), dateValue.day()).format('dd MMMM yyyy');
    }

    // Process CC emails
    private static List<String> processCCEmails(String ccEmails) {
        if (String.isBlank(ccEmails))
            return new List<String>();

        List<String> emailList = ccEmails.split(',');
        return cleanEmailList(emailList);
    }

    // Clean and validate email list
    public static List<String> cleanEmailList(List<String> emailList) {
        List<String> cleaned = new List<String>();

        for (String email : emailList) {
            email = email.trim();
            if (String.isNotBlank(email) && EMAIL_PATTERN.matcher(email).matches()) {
                cleaned.add(email);
            }
        }
        return cleaned;
    }

    // Check if template is for mobility agreement
    private static Boolean isMobilityTemplate(PDFTemplate__c template) {
        return template.Name != null && template.Name.contains(MOBILITY_AGREEMENT_TEMPLATE);
    }

    // Generate mobility PDF
    private static Blob generateMobilityPDF(Id applicationId, IPDFGenerator pdfGenerator) {
        PageReference pdfPage = Page.TemplateMobilityAgreement;
        pdfPage.getParameters().put('id', EncodingUtil.urlEncode(applicationId, 'UTF-8'));
        return pdfGenerator.generatePDF(pdfPage);
    }

    // Generate standard filename
    private static String generateStandardFilename(String templateType, Opportunity application) {
        return templateType + '_Application_' + application.Name + '.pdf';
    }

    // Generate standard PDF
    private static Blob generateStandardPDF(Id applicationId, String templateType, String courseCategoryId, IPDFGenerator pdfGenerator) {
        PageReference pdfPage = Page.DynamicPDFPage;
        pdfPage.getParameters().put('id', EncodingUtil.urlEncode(applicationId, 'UTF-8'));
        pdfPage.getParameters().put('templateType', EncodingUtil.urlEncode(templateType, 'UTF-8'));
        pdfPage.getParameters().put('courseCategoryId', EncodingUtil.urlEncode(courseCategoryId, 'UTF-8'));
        return pdfGenerator.generatePDF(pdfPage);
    }

    // Error logging
    private static void logError(String message, Exception e) {
        System.debug(LoggingLevel.ERROR, 'PDFGeneratorService: ' + message + '\n' + 'Stack Trace: ' + e.getStackTraceString());
        // Consider integrating with a logging framework
    }
}