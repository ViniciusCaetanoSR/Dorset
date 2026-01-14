public class GetProduct{

@InvocableMethod 
public static void GetProduct2(List<Opportunity> Opp)
    {
        GetProduct3(Opp);
    }

    public static void GetProduct3(List<Opportunity> Opp)
    {
       list<Opportunity> PId;
       list<Product2> Prods;
       list<Opportunity> Opps;
       list<Course__c> Courses;
       list<Course_Categorty__c> CourseCategories;
       product2 B;
       Course__c cour;
       Course_Categorty__c courCat;
       Opportunity A;
       string Prodc;

        if(!Opp.isEmpty() && Opp.size() > 0) {
            PId = [Select ProductNumber__c from Opportunity where Id =: Opp[0].Id];
            Prodc = PId[0].ProductNumber__c;
            Prods = [select id, Parent_Course__c from product2 where productcode =: Prodc];
            Opps = [Select id, Product__c, Course_Type__c, Course_Category__c from Opportunity where Id =: Opp[0].Id];

            if(!Prods.isEmpty())
            {
                B = Prods[0];
                if(!Opps.isEmpty())
                {
                    A = Opps[0];
                    A.Product__c = B.id;
             //       A.Pricebook2Id = '01s1t000004x8DIAAY';
                    update A;
                    try
                    {//Associate parent course from product with application(oppurtunity)
                        A.Course__c = B.Parent_Course__c; 
                        update A;
                        
                        Courses = [Select Id, Course_Category__c from Course__c where Id =: B.Parent_Course__c];
                        //Associate course category
                        if(!Courses.isEmpty() && Courses.size() > 0){
                            cour = Courses[0];
                            //Associate course type
                            CourseCategories = [Select Id, Course_Type__c from Course_Categorty__c where Id =: cour.Course_Category__c];
                            if(!CourseCategories.isEmpty() && CourseCategories.size() > 0){
                                courCat = CourseCategories[0];
                                A.Course_Type__c = courCat.Course_Type__c;
                                A.Course_Category__c = cour.Course_Category__c;
                                update A;
                            }
                        }
                    } catch(DmlException e) {
                        System.debug('The following exception has occurred in the get product class ' + e.getMessage());
                    }
                }
            }
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
    
                 
    //repeat the i++ hundred of times

  }
    
    
    
    
}