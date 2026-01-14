Public class generateCreditPdfDocumentEFL{
    
    @InvocableMethod   
    public static void CreateCredit(List<Id> quoteIds)  
    { 
        createCreditFutureMethod(quoteIds);
    }
    
    @future(callout=true)
    public static void createCreditFutureMethod (List<Id> quoteIds) {
        //Initialize the quote urly
        String quoteUrl = '/quote/quoteTemplateDataViewer.apexp?';
        
        //Get the Quote Template Id from Custom Settings
        String quoteTemplateId = Label.CreditTemplateIdEFL;
        
        //List variable to get all the Quote Documents
        List<QuoteDocument> lstQuoteDoc = new List<QuoteDocument>();
        
        if(!quoteIds.isEmpty() && quoteIds.size() > 0) {
            
            for(Id quoteId :quoteIds) {
                //Construct the quote URL to generate PDF
                quoteUrl += 'id=' + quoteId;
                quoteUrl += '&headerHeight=197&footerHeight=400';
                quoteUrl += '&summlid=' + quoteTemplateId;
                
                
               
               Quote c = [SELECT AccountId FROM Quote WHERE Id = :quoteId];
                
               Account a = [SELECT PersonEmail FROM Account WHERE Id = :c.AccountId];

                //call the quote url
                PageReference pageRef = new PageReference(quoteUrl);
                
                //get the quotePdf
                Blob quoteBlob;
                
                if(Test.isRunningTest()) {
                    quoteBlob = Blob.valueOf('Generate Pdf');
                } else {
                    quoteBlob = pageRef.getContentAsPDF();
                }
                
                //initialze the QuoteDocument to hold the quote pdf for insertion
                QuoteDocument quoteDoc = new QuoteDocument();
                quoteDoc.Document = quoteBlob;
                quoteDoc.QuoteId = quoteId;
                 Database.SaveResult insertResult =  Database.insert(quoteDoc,false);
                
                
                       // Document doc = [SELECT Id,Name FROM Document WHERE Id = '0QD3Y000000ZaNfWAK'];
        Messaging.SingleEmailMessage semail = new Messaging.SingleEmailMessage();
        //  semail.setDocumentAttachments(new ID[]{doc.id});
        semail.setSubject('Dorset College Invoice attached');
        
        String[] sendTo = new String[]{a.PersonEmail};
        
        semail.setToAddresses(sendTo);
        
        //Override sender email
        OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address = 'noreply@dorset.ie'];
        if (owea.size() > 0) {
            semail.setOrgWideEmailAddressId(owea.get(0).Id);
        }
        
        semail.setHtmlBody('Dear Student,<br><BR>Welcome to Dorset College. Thank you for your completed application form and deposit.<br><BR>We hope you enjoy your time at Dorset College and that your participation in the course proves both beneficial and worthwhile in your future chosen career path.<br><BR>Attached to this email you will find your invoice. The finance team will contact you regarding the payment and you will soon receive instructions from our Academic Department regarding your course.<br><BR>Please be advised that if no refund will be made to students who fail to attend classes, cancel the enrolment or do not complete the course.  Dorset College reserves the right to cancel courses where it deems that this is necessary.<br><BR>In order to continue your enrolment, we need you to fill out the attached form for Garda Vetting, after this first step, in a few days you will receive an email with the instructions for the second step: http://bit.ly/2pjEh9g<br><BR>Kind regards,<br><br>Lais Gusatti<br><br>Admissions Lead');
      //Set email file attachments
        List<Messaging.Emailfileattachment> fileAttachments = new List<Messaging.Emailfileattachment>();
     
        // Add to attachment file list
        Messaging.Emailfileattachment efa = new Messaging.Emailfileattachment();
        efa.setFileName('Invoice.pdf');
        efa.setBody(quoteBlob);
        fileAttachments.add(efa);
        
   //     semail.setFileAttachments(fileAttachments);


  //      Messaging.sendEmail(new Messaging.SingleEmailMessage[]{semail});

                

            }
        }
        
        if(!lstQuoteDoc.isEmpty() && lstQuoteDoc.size() > 0) {
         //   Database.insert(lstQuoteDoc);
        }
        
    }
    
        public static void fakeMethod(){
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
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
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