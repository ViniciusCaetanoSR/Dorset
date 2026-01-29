public without sharing class ReceiptController {
    // Propriedades públicas
    public String decodedContent { get; set; }
    public List<OpportunityLineItem> oppLineItems { get; set; }
    public Id globalOpportunityId;

    // Constantes
    private static final String HR_TAG = '<hr style="height: 1px; background-color: #12215D; border: none; margin: 0.5;" />';
    private static final String P_TAG_STYLE = '<p style="margin:0; padding:0; line-height:1.2; font-size: 12px;">';

    public ReceiptController() {
        try {
            // Obter parâmetros da página
            Id paymentId = ApexPages.currentPage().getParameters().get('id');

            // Validação de entrada
            if (String.isBlank(paymentId)) {
                throw new PdfContentException('ID de Payment inválido: ' + paymentId);
            }

            // Log inicial
            System.debug(LoggingLevel.INFO, '=== Iniciando ReceiptController ===');
            System.debug(LoggingLevel.DEBUG, 'paymentId: ' + paymentId);

            // Consultar Payment
            Payment__c payment = queryPayment(paymentId);

            // Consultar Template
            PDFTemplate__c template = queryTemplate();
            System.debug(LoggingLevel.DEBUG, 'Template encontrado: ' + template.Id);

            // Consultar os produtos vinculados a application
            oppLineItems = [
                SELECT Id, Product2.Name, Description, Start_Date__c, End_Date__c, TotalPrice
                FROM OpportunityLineItem
                WHERE OpportunityId = :globalOpportunityId
            ];

            // Extrair placeholders e construir consulta dinâmica
            Set<String> placeholders = extractPlaceholders(template.HTMLContent__c);
            System.debug(LoggingLevel.DEBUG, 'Placeholders encontrados: ' + placeholders);

            String dynamicQuery = buildDynamicQuery(placeholders, paymentId);
            Payment__c payFull = Database.query(dynamicQuery);
            System.debug(LoggingLevel.DEBUG, 'Payment completo consultada: ' + payFull);

                
            // Processar conteúdo do template
            decodedContent = replacePlaceholders(template.HTMLContent__c, payFull);
            decodedContent = limparEspacamento(decodedContent);
            decodedContent = inserirHr(decodedContent);
            decodedContent = inserirTable(decodedContent);
            decodedContent = inserirData(decodedContent);

            if(payFull.Opportunity__r.Is_this_Application_from_an_Agent__c == true 
                && payFull.Opportunity__r.Amount_paid__c == payFull.Opportunity__r.Agent_Net_Amount__c) {
                System.debug(LoggingLevel.INFO, 'Pagamento feito por agência, recalculando valores...');
                calculateAgentPayment(payFull, decodedContent);
            }
                
            System.debug(LoggingLevel.INFO, 'Conteúdo processado: ' + decodedContent);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Erro no ReceiptController: ' + e.getMessage() + '\nStack Trace: ' + e.getStackTraceString());
            throw new PdfContentException('Erro ao processar o PDF: ' + e.getMessage(), e);
        }
    }

    // Consultar Payment
    private Payment__c queryPayment(Id paymentId) {
        List<Payment__c> payments = [
            SELECT Id, Name, Opportunity__c
            FROM Payment__c
            WHERE Id = :paymentId
            LIMIT 1
        ];
        if (payments.isEmpty()) {
            throw new PdfContentException('Nenhum payment encontrada para o ID: ' + paymentId);
        }
        globalOpportunityId = payments[0].Opportunity__c;
        System.debug(LoggingLevel.DEBUG, 'Payment consultado: Id=' + payments[0].Id + ', Opportunity__c=' + payments[0].Opportunity__c);
        return payments[0];
    }

    // Consultar PDFTemplate
    private PDFTemplate__c queryTemplate() {
        List<PDFTemplate__c> templates = [
            SELECT Id, HTMLContent__c
            FROM PDFTemplate__c
            WHERE name = 'Receipt'
            AND Active__c = TRUE
            LIMIT 1
        ];
        if (templates.isEmpty()) {
            throw new PdfContentException('Nenhum template de recibo ativo encontrado');
        }
        return templates[0];
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
    private String buildDynamicQuery(Set<String> placeholders, Id paymentId) {
        String query = 'SELECT Id';
        for (String fieldName : placeholders) {
            query += ', ' + fieldName;
        }
        query += ', opportunity__r.Is_this_Application_from_an_Agent__c, opportunity__r.Agent_Net_Amount__c, opportunity__r.Total_Amount__c FROM Payment__c WHERE Id = :paymentId LIMIT 1';
        System.debug(LoggingLevel.DEBUG, 'Consulta dinâmica gerada: ' + query);
        return query;
    }

    // Se for pagamento por agência
    private void calculateAgentPayment(Payment__c payFull, String decodedContent) {
        System.debug(LoggingLevel.INFO, 'Substituindo valores para pagamento de agência');
            decodedContent = decodedContent
            .replace('{{Amount_Paid__c}}', String.valueOf(payFull.Opportunity__r.Total_Amount__c))
            .replace('{{Student_Outstanding_Balance__c}}', '0');
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

        Payment__c pay;
        Decimal agentGross;
        Decimal agentNet;
        Decimal amountPaidSoFar;
        Decimal currentPayment;
        Decimal realPaidAmount;

        if (record instanceof Payment__c) {
            pay = (Payment__c) record;

            agentGross = pay.Opportunity__r.Agent_Gross_Amout__c != null
                ? pay.Opportunity__r.Agent_Gross_Amout__c
                : 0;

            agentNet = pay.Opportunity__r.Agent_Net_Amount__c != null
                ? pay.Opportunity__r.Agent_Net_Amount__c
                : 0;

            amountPaidSoFar = pay.Opportunity__r.Amount_Paid__c != null
                ? pay.Opportunity__r.Amount_Paid__c
                : 0;

            currentPayment = pay.Payment_Amount__c != null
                ? pay.Payment_Amount__c
                : 0;

            realPaidAmount = amountPaidSoFar + currentPayment;
        }

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
                    if (fieldPath == 'opportunity__r.Student_Outstanding_Balance__c'
                        && pay != null) {

                        Decimal updatedBalance;

                        if (agentNet == realPaidAmount) {
                            updatedBalance = 0;
                        } else {
                            updatedBalance = agentGross - realPaidAmount;
                        }

                        if (updatedBalance < 0) {
                            updatedBalance = 0;
                        }

                        value = String.valueOf(updatedBalance.setScale(2));

                        System.debug(LoggingLevel.DEBUG,
                            'Balance recalculado dinamicamente: ' + value
                        );

                    } else if (fieldPath == 'opportunity__r.Amount_Paid__c'
                        && pay != null) {

                        Decimal amountToShow =
                            (realPaidAmount == agentNet)
                            ? agentGross
                            : realPaidAmount;

                        if (amountToShow < 0) {
                            amountToShow = 0;
                        } else if (amountToShow > agentGross) {
                            amountToShow = agentGross;
                        }

                        value = String.valueOf(amountToShow.setScale(2));

                        System.debug(LoggingLevel.DEBUG,
                            'Amount Paid recalculado dinamicamente: ' + value
                        );
                    } else {
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
                    }

                    System.debug(LoggingLevel.DEBUG,
                        'Placeholder ' + placeholder + ' substituído por: ' + value
                    );
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

        result = solveExpressions(result);

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

    // Inserir data
    public String inserirData(String html) {
        if (String.isBlank(html)) {
            System.debug(LoggingLevel.WARN, 'HTML vazio ao inserir data');
            return html;
        }

        if (html.contains('{today}')) {
            html = html.replace('{today}', Today);
            System.debug(LoggingLevel.DEBUG, 'Tabela de itens inserida no HTML.');
        }
        return html;
    }

    // Inserir tabela de produtos
    public String inserirTable(String html) {
        if (String.isBlank(html)) {
            System.debug(LoggingLevel.WARN, 'HTML vazio ao inserir tabela');
            return html;
        }

        if (html.contains('{table}')) {
            String tabela = '';
            if (oppLineItems == null || oppLineItems.isEmpty()) {
                tabela = '<p style="color:#888;">Nenhum item encontrado.</p>';
            } else {
                tabela += '<table style="width:100%; border-collapse:collapse; font-family: Arial, Helvetica, sans-serif; font-size:12px;">';
                tabela += '<thead>';
                tabela += '<tr style="background:#12215D; color:#fff;">';
                tabela += '<th style="padding:6px; text-align:left; width: 40%;">Line Item Name</th>';
                tabela += '<th style="padding:6px; text-align:left; width: 20%;">Course Start Date</th>';
                tabela += '<th style="padding:6px; text-align:left; width: 20%;">Course End Date</th>';
                tabela += '<th style="padding:6px; text-align:left; width: 5%;">Weeks</th>';
                tabela += '<th style="padding:6px; text-align:left; width: 15%;">Total Price</th>';
                tabela += '</tr>';
                tabela += '</thead>';
                tabela += '<tbody>';

                for (OpportunityLineItem oli : oppLineItems) {
                    tabela += '<tr style="border-bottom:1px solid #ccc;">';
                    tabela += '<td style="padding:6px; text-align:left;">'+ String.valueOf(oli.Product2.Name) +'</td>';
                    tabela += '<td style="padding:6px; text-align:left;">'+ formatDate(oli.Start_Date__c) +'</td>';
                    tabela += '<td style="padding:6px; text-align:left;">'+ formatDate(oli.End_Date__c) +'</td>';
                    tabela += '<td style="padding:6px; text-align:left;">'+ calcularSemanas(oli.Start_Date__c, oli.End_Date__c) +'</td>';
                    tabela += '<td style="padding:6px; text-align:left;">€ '+ String.valueOf(oli.TotalPrice) +'</td>';
                    tabela += '</tr>';
                }

                tabela += '</tbody>';
                tabela += '</table>';
            }

            html = html.replace('{table}', tabela);
            System.debug(LoggingLevel.DEBUG, 'Tabela de itens inserida no HTML.');
        }

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

    // Calcular semanas na tabela
    private String calcularSemanas(Date startDate, Date endDate) {
        if (startDate != null && endDate != null) {
            Integer days = Math.abs(endDate.daysBetween(startDate)) + 1;
            Integer weeks = (Integer)Math.ceil(days / 7);
            return String.valueOf(weeks);
        }
        return '-';
    }

    // Resolver expressões (se tiver)
    private static String solveExpressions(String content) {
        if (String.isBlank(content)) return content;

        Pattern pattern = Pattern.compile('\\((\\d+(?:\\.\\d{1,2})?)\\s*([\\+\\-])\\s*(\\d+(?:\\.\\d{1,2})?)\\)');
        Matcher matcher = pattern.matcher(content);

        String result = content;

        while (matcher.find()) {
            String fullMatch = matcher.group(0);
            Decimal left = Decimal.valueOf(matcher.group(1));
            String operator = matcher.group(2);
            Decimal right = Decimal.valueOf(matcher.group(3));
            Decimal resultado = operator == '+' ? left + right : left - right;

            result = result.replace(fullMatch, String.valueOf(resultado.setScale(2)));
        }

        return result;
    }


    // Propriedade Today
    public String Today {
        get {
            String formattedDate = formatDateWithoutMonth(Date.today());
            System.debug(LoggingLevel.DEBUG, 'Data formatada (Today): ' + formattedDate);
            return formattedDate;
        }
    }

    public String TodayWithMonth {
        get {
            String formattedDate = formatDate(Date.today());
            System.debug(LoggingLevel.DEBUG, 'Data formatada (Today): ' + formattedDate);
            return formattedDate;
        }
    }

    // Exceção personalizada
    public class PdfContentException extends Exception {}
    
}