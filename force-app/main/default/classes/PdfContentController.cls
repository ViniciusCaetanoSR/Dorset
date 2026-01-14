public without sharing class PdfContentController {
    // Propriedades públicas
    public String decodedContent { get; set; }
    public String titulo { get; set; }
    public String qrCode { get; set; }
    public Boolean exibirQrCode { get; set; }
    public Opportunity opp;
    public String templateType { get; set; }
    public Boolean isErasmusCategory { get; set; }
    public Boolean isEnglishLanguageCategory { get; set; }
    public Boolean isProfessionalCourseCategory { get; set; }

    // Constantes
    private static final String QR_CODE_BASE_URL = 'https://api.qrserver.com/v1/create-qr-code/?size=120x120&data=';
    private static final String VALIDATOR_URL = 'https://dorsetcollege.my.salesforce-sites.com/Validator?id=';
    private static final String TITLE_STYLE = 'color: #12215D; font-family: \'Arial\', Helvetica, sans-serif !important;';
    private static final String HR_TAG = '<hr style="height: 1px; background-color: #12215D; border: none; margin: 0.5;" />';
    private static final String P_TAG_STYLE = '<p style="margin:0; padding:0; line-height:1.2; font-size: 12px;">';

    // Construtor
    public PdfContentController() {
        try {
            // Obter parâmetros da página
            Id oppId = ApexPages.currentPage().getParameters().get('id');
            templateType = ApexPages.currentPage().getParameters().get('templateType');

            // Validação de entrada
            if (String.isBlank(oppId) || !String.valueOf(oppId).startsWith(Opportunity.SObjectType.getDescribe().getKeyPrefix())) {
                throw new PdfContentException('ID de Opportunity inválido: ' + oppId);
            }
            if (String.isBlank(templateType) || !new Set<String>{'PO', 'ACC', 'PCCompletion'}.contains(templateType)) {
                throw new PdfContentException('Template Type inválido: ' + templateType);
            }

            // Log inicial
            System.debug(LoggingLevel.INFO, '=== Iniciando PdfContentController ===');
            System.debug(LoggingLevel.DEBUG, 'oppId: ' + oppId);
            System.debug(LoggingLevel.DEBUG, 'templateType: ' + templateType);

            // Consultar Opportunity
            opp = queryOpportunity(oppId);
            isErasmusCategory = (opp.Course_Category__r != null && String.valueOf(opp.Course_Category__r.Name).contains('Erasmus'));
            isEnglishLanguageCategory = (opp.Course_Category__r != null && String.valueOf(opp.Course_Type__r.Name).contains('English Language'));
            isProfessionalCourseCategory = (opp.Course_Category__r != null && String.valueOf(opp.Course_Type__r.Name).contains('Professional Courses'));

            if (opp.Course_Category__c == null) {
                System.debug(LoggingLevel.WARN, 'Course_Category__c está nulo para Opportunity: ' + opp.Id);
            }

            // Consultar Template
            PDFTemplate__c template = queryTemplate(opp.Course_Category__c, templateType);
            System.debug(LoggingLevel.DEBUG, 'Template encontrado: ' + template.Id);

            // Configurar título e QR Code com base no templateType
            configureTemplateSettings(templateType, oppId);

            // Extrair placeholders e construir consulta dinâmica
            Set<String> placeholders = extractPlaceholders(template.HTMLContent__c);
            System.debug(LoggingLevel.DEBUG, 'Placeholders encontrados: ' + placeholders);

            String dynamicQuery = buildDynamicQuery(placeholders, oppId);
            Opportunity oppFull = Database.query(dynamicQuery);
            System.debug(LoggingLevel.DEBUG, 'Opportunity completa consultada: ' + oppFull);

            // Processar conteúdo do template
            decodedContent = replacePlaceholders(template.HTMLContent__c, oppFull);
            decodedContent = limparEspacamento(decodedContent);
            decodedContent = inserirHr(decodedContent);

            // Transformar cada linha em <p>
            // String[] linhas = decodedContent.split('\n');
            // String htmlFinal = '';
            // for (String linha : linhas) {
            //     htmlFinal += '<p style="margin:0; padding:0; line-height:1.4; font-size: 12px;">' + linha + '</p>';
            //     System.debug('entrei no for novo');
            // }
            // decodedContent = htmlFinal;

            System.debug(LoggingLevel.INFO, 'Conteúdo processado: ' + decodedContent);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Erro no PdfContentController: ' + e.getMessage() + '\nStack Trace: ' + e.getStackTraceString());
            throw new PdfContentException('Erro ao processar o PDF: ' + e.getMessage(), e);
        }
    }

    // Consultar Opportunity
    private Opportunity queryOpportunity(Id oppId) {
        List<Opportunity> opps = [
            SELECT Id, Name, Course_Category__c, Course_Category__r.name, Course_Type__r.name
            FROM Opportunity
            WHERE Id = :oppId
            LIMIT 1
        ];
        if (opps.isEmpty()) {
            throw new PdfContentException('Nenhuma Opportunity encontrada para o ID: ' + oppId);
        }
        System.debug(LoggingLevel.DEBUG, 'Opportunity consultada: Id=' + opps[0].Id + ', Course_Category__c=' + opps[0].Course_Category__c);
        return opps[0];
    }

    // Consultar PDFTemplate
    private PDFTemplate__c queryTemplate(Id courseCategoryId, String templateType) {
        if (courseCategoryId == null) {
            throw new PdfContentException('Course_Category__c é nulo, não é possível consultar o template');
        }
        List<PDFTemplate__c> templates = [
            SELECT Id, HTMLContent__c
            FROM PDFTemplate__c
            WHERE CourseCategory__c = :courseCategoryId
            AND Stage__c = :templateType
            AND Active__c = TRUE
            LIMIT 1
        ];
        if (templates.isEmpty()) {
            throw new PdfContentException('Nenhum template ativo encontrado para CourseCategory__c=' + courseCategoryId + ' e Stage__c=' + templateType);
        }
        return templates[0];
    }

    // Configurar título e QR Code
    private void configureTemplateSettings(String templateType, Id oppId) {
        if (templateType == 'PO' && !isProfessionalCourseCategory) {
            titulo = '<h2 style="' + TITLE_STYLE + ' margin-bottom: 1;">Provisional Acceptance Letter</h2>';
            exibirQrCode = false;
        } else if (templateType == 'ACC' && !isProfessionalCourseCategory) {
            titulo = '<h2 style="' + TITLE_STYLE + ' margin-bottom: 1;">Full Acceptance Letter</h2>';
            qrCode = VALIDATOR_URL + oppId;
            exibirQrCode = true;
        } else if (templateType == 'PO' && isProfessionalCourseCategory) {
            titulo = '<h2 style="' + TITLE_STYLE + ' margin-bottom: 1;">Confirmation Letter</h2>';
        } else if (templateType == 'PCCompletion' && isProfessionalCourseCategory){
            titulo = '<h2 style="' + TITLE_STYLE + ' margin-bottom: 1;">Completion Confirmation Letter</h2>';
        }
        System.debug(LoggingLevel.DEBUG, 'Configurações do template: titulo=' + titulo + ', exibirQrCode=' + exibirQrCode + ', qrCode=' + qrCode);
    }

    // Extrair placeholders do conteúdo
    private static Set<String> extractPlaceholders(String content) {
        Set<String> placeholders = new Set<String>();
        if (String.isBlank(content)) {
            System.debug(LoggingLevel.WARN, 'Conteúdo do template está vazio');
            return placeholders;
        }

        Pattern pattern = Pattern.compile('\\{\\{([^}]+)\\}\\}');
        Matcher matcher = pattern.matcher(content);
        while (matcher.find()) {
            String placeholder = matcher.group(1).trim();
            placeholders.add(placeholder);
        }
        System.debug(LoggingLevel.DEBUG, 'Placeholders extraídos: ' + placeholders);
        return placeholders;
    }

    // Construir consulta dinâmica
    private String buildDynamicQuery(Set<String> placeholders, Id oppId) {
        String query = 'SELECT Id';
        Schema.DescribeSObjectResult objDescribe = Opportunity.SObjectType.getDescribe();
        Map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap();

        for (String fieldName : placeholders) {
            if (fieldName.contains('.')) {
                String relationship = fieldName.split('\\.')[0];
                String relatedField = fieldName.split('\\.')[1];
                query += ', ' + relationship + '.' + relatedField;
            } else if (fieldMap.containsKey(fieldName.toLowerCase())) {
                query += ', ' + fieldName;
            }
        }
        query += ' FROM Opportunity WHERE Id = :oppId LIMIT 1';
        System.debug(LoggingLevel.DEBUG, 'Consulta dinâmica gerada: ' + query);
        return query;
    }

    // Substituir placeholders no conteúdo
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
            String[] pathParts = fieldPath.split('\\.');
            SObject currentObj = record;
            Object valueObj = null;
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
                    System.debug(LoggingLevel.DEBUG, 'Placeholder ' + placeholder + ' substituído por: ' + value);
                } else {
                    Object nextObj = currentObj.getSObject(field);
                    if (nextObj != null && nextObj instanceof SObject) {
                        currentObj = (SObject) nextObj;
                    } else {
                        System.debug(LoggingLevel.WARN, 'Relacionamento inválido para campo: ' + field);
                        currentObj = null;
                    }
                }
            }
            result = result.replace(placeholder, value);
        }
        return result;
    }

    // Formatar data
    private static String formatDate(Date dateTemp) {
        if (dateTemp == null) {
            System.debug(LoggingLevel.WARN, 'Data nula ao formatar');
            return '';
        }
        DateTime dt = DateTime.newInstance(dateTemp.year(), dateTemp.month(), dateTemp.day());
        return dt.format('dd MMMM yyyy');
    }

    // Formatar data sem mês por extenso
    private static String formatDateWithoutMonth(Date dateTemp) {
        if (dateTemp == null) {
            System.debug(LoggingLevel.WARN, 'Data nula ao formatar sem mês');
            return '';
        }
        DateTime dt = DateTime.newInstance(dateTemp.year(), dateTemp.month(), dateTemp.day());
        return dt.format('dd/MM/yyyy');
    }

    // Limpar espaçamento do HTML
    public String limparEspacamento(String html) {
        if (String.isBlank(html)) {
            System.debug(LoggingLevel.WARN, 'HTML vazio ao limpar espaçamento');
            return html;
        }
        html = html.replaceAll('line-height:\\s*[^;"]+;?', '');
        html = html.replaceAll('margin(-[a-z]+)?:\\s*[^;"]+;?', '');
        html = html.replaceAll('padding(-[a-z]+)?:\\s*[^;"]+;?', '');
        html = html.replaceAll('<p(.*?)>', P_TAG_STYLE);
        System.debug(LoggingLevel.DEBUG, 'HTML após limpar espaçamento: ' + html);
        return html;
    }

    // Inserir tag HR
    public String inserirHr(String html) {
        if (String.isBlank(html)) {
            System.debug(LoggingLevel.WARN, 'HTML vazio ao inserir HR');
            return html;
        }
        html = html.replaceAll('-{5,}', HR_TAG);
        System.debug(LoggingLevel.DEBUG, 'HTML após inserir HR: ' + html);
        return html;
    }

    // Propriedade Today
    public String Today {
        get {
            String formattedDate = formatDateWithoutMonth(Date.today());
            System.debug(LoggingLevel.DEBUG, 'Data formatada (Today): ' + formattedDate);
            return formattedDate;
        }
    }

    // Propriedade qrCodeUrl
    public String qrCodeUrl {
        get {
            if (String.isBlank(qrCode)) {
                System.debug(LoggingLevel.WARN, 'qrCode está vazio, retornando URL vazia');
                return '';
            }
            String url = QR_CODE_BASE_URL + EncodingUtil.urlEncode(qrCode, 'UTF-8');
            System.debug(LoggingLevel.DEBUG, 'URL do QR Code gerada: ' + url);
            return url;
        }
    }

    public Boolean getIsErasmusCategory() {
        return opp != null &&
            opp.Course_Category__r != null &&
            String.valueOf(opp.Course_Category__r.Name).contains('Erasmus');
    }

    public Boolean getIsEnglishLanguageCategory() {
        return opp != null &&
            opp.Course_Type__r != null &&
            String.valueOf(opp.Course_Type__r.Name).contains('English Language');
    }

    public Boolean getIsProfessionalCourseCategory() {
        return opp != null &&
            opp.Course_Type__r != null &&
            String.valueOf(opp.Course_Type__r.Name).contains('Professional Courses');
    }

    // ===== Helpers de Template =====
    // o template é ACC
    public Boolean getIsTemplateACC() {
        return templateType != null && templateType.equalsIgnoreCase('ACC');
    }

    // o template é PO
    public Boolean getIsTemplatePO() {
        return templateType != null && templateType.equalsIgnoreCase('PO');
    }

    // ===== Lógica de assinatura =====
    // Patricia: aparece quando é Erasmus e o template é ACC ou PO
    public Boolean getShowPatricia() {
        return isErasmusCategory && (getIsTemplateACC() || getIsTemplatePO());
    }

    // Hugh: aparece quando NÃO é Erasmus e o template é ACC OU É PC
    public Boolean getShowHugh() {
        return !isErasmusCategory && (getIsTemplateACC() || isProfessionalCourseCategory);
    }

    // ===== Lógica de Stamp e QR =====
    // Mostra o selo (stamp) em ACC (sempre) e PO (somente se for Erasmus)
    public Boolean getShowStamp() {
        return getIsTemplateACC() || (isErasmusCategory && getIsTemplatePO()) || (isProfessionalCourseCategory);
    }

    // Mostra o QR Code somente se for ACC e exibirQrCode = true
    public Boolean getShowQr() {
        return getIsTemplateACC() && exibirQrCode;
    }

    public Boolean getShowValidityNote() {
        return !isErasmusCategory && !isEnglishLanguageCategory && !isProfessionalCourseCategory && getIsTemplatePO();
    }


    // Exceção personalizada
    public class PdfContentException extends Exception {}
}