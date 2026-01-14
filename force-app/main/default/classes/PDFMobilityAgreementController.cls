public with sharing class PDFMobilityAgreementController {
    public String formattedDate { get; private set; }
    public String decodedContent { get; private set; }

    public PDFMobilityAgreementController() {
        formattedDate = formatDate(Date.today());

        try {
            Id appId = ApexPages.currentPage().getParameters().get('id');

            if (String.isBlank(appId)) {
                throw new PdfContentException('O parâmetro "id" da URL está ausente.');
            }

            Opportunity app = [SELECT Id, Name, Course_Category__c FROM Opportunity WHERE Id = :appId LIMIT 1];

            PDFTemplate__c template = queryTemplate('Mobility');
            Set<String> placeholders = extractPlaceholders(template.HTMLContent__c);
            System.debug(LoggingLevel.DEBUG, 'Placeholders encontrados: ' + placeholders);

            String dynamicQuery = buildDynamicQuery(placeholders, appId);
            Opportunity appFull = Database.query(dynamicQuery);
            System.debug(LoggingLevel.DEBUG, 'Application completa consultada: ' + appFull);

            decodedContent = replacePlaceholders(template.HTMLContent__c, appFull);
        } catch (PdfContentException e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Erro de conteúdo PDF: ' + e.getMessage()));
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Erro inesperado: ' + e.getMessage()));
            System.debug(LoggingLevel.ERROR, 'Erro na construção do PDF: ' + e.getStackTraceString());
        }
    }

    private static String formatDate(Date dateTemp) {
        DateTime dt = DateTime.newInstance(dateTemp.year(), dateTemp.month(), dateTemp.day());
        return dt.format('dd/MM/yyyy');
    }

    private PDFTemplate__c queryTemplate(String name) {
        if (String.isBlank(name)) {
            throw new PdfContentException('O parâmetro "name" não pode ser nulo ou vazio');
        }

        List<PDFTemplate__c> templates = [
            SELECT Id, HTMLContent__c
            FROM PDFTemplate__c
            WHERE Name LIKE :('%' + name + '%') AND Active__c = TRUE
        ];

        if (templates.isEmpty()) {
            throw new PdfContentException('Nenhum template ativo encontrado com Name LIKE ' + name);
        }

        return templates[0];
    }

    private static Set<String> extractPlaceholders(String content) {
        Set<String> placeholders = new Set<String>();

        if (String.isBlank(content)) {
            System.debug(LoggingLevel.WARN, 'Conteúdo do template está vazio');
            return placeholders;
        }

        Pattern pattern = Pattern.compile('\\{\\{([^}]+)\\}\\}');
        Matcher matcher = pattern.matcher(content);

        while (matcher.find()) {
            placeholders.add(matcher.group(1).trim());
        }

        return placeholders;
    }

    private String buildDynamicQuery(Set<String> placeholders, Id appId) {
        String query = 'SELECT Id';
        Schema.DescribeSObjectResult describeResult = Opportunity.SObjectType.getDescribe();
        Map<String, Schema.SObjectField> fieldMap = describeResult.fields.getMap();

        for (String fieldName : placeholders) {
            if (fieldName.contains('.')) {
                List<String> parts = fieldName.split('\\.');
                if (parts.size() == 2) {
                    query += ', ' + parts[0] + '.' + parts[1];
                }
            } else if (fieldMap.containsKey(fieldName.toLowerCase())) {
                query += ', ' + fieldName;
            }
        }

        query += ' FROM Opportunity WHERE Id = :appId LIMIT 1';
        System.debug(LoggingLevel.DEBUG, 'Consulta dinâmica gerada: ' + query);
        return query;
    }

    private static String replacePlaceholders(String content, SObject record) {
        if (String.isBlank(content)) {
            System.debug(LoggingLevel.WARN, 'Conteúdo para substituição está vazio');
            return '';
        }

        String result = content;
        Pattern pattern = Pattern.compile('\\{\\{([a-zA-Z0-9_\\.]+)\\}\\}');
        Matcher matcher = pattern.matcher(result);

        while (matcher.find()) {
            String placeholder = matcher.group();
            String fieldPath = placeholder.substring(2, placeholder.length() - 2);
            List<String> pathParts = fieldPath.split('\\.');
            SObject currentObj = record;
            Object valueObj;
            String value = '';

            for (Integer i = 0; i < pathParts.size(); i++) {
                String field = pathParts[i];

                if (currentObj == null) {
                    System.debug(LoggingLevel.WARN, 'Objeto nulo ao processar campo: ' + field);
                    break;
                }

                if (i == pathParts.size() - 1) {
                    valueObj = currentObj.get(field);

                    if (valueObj != null) {
                        if (valueObj instanceof Date) {
                            value = formatDate((Date) valueObj);
                        } else if (valueObj instanceof Datetime) {
                            value = formatDate(((Datetime) valueObj).date());
                        } else {
                            value = String.valueOf(valueObj);
                        }
                    }
                } else {
                    Object nextObj = currentObj.getSObject(field);
                    currentObj = (nextObj instanceof SObject) ? (SObject) nextObj : null;
                }
            }

            result = result.replace(placeholder, value);
        }

        return result;
    }

    public class PdfContentException extends Exception {
    }
}