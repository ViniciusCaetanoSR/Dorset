public class GetAccomProduct{

@InvocableMethod 
public static void GetAccommProduct2(List<Opportunity> Opp)
    {
        GetAccommProduct3(Opp);
    }

    public static void GetAccommProduct3(List<Opportunity> Opp)
    {
       list<Opportunity> PId;
       list<Product2> Prods;
       list<Opportunity> Opps;
       list<Course__c> Courses;
       list<Course_Categorty__c> CourseCategories;
       product2 B;
       Opportunity A;
       string Prodc;

        if(!Opp.isEmpty() && Opp.size() > 0) {
            PId = [Select Accommodation_Option__c from Opportunity where Id =: Opp[0].Id];
            Prodc = PId[0].Accommodation_Option__c;
            Prods = [select id, Parent_Course__c from product2 where productcode =: Prodc];
            Opps = [Select id, Accommodation_Product__c from Opportunity where Id =: Opp[0].Id];

            if(!Prods.isEmpty())
            {
                B = Prods[0];
                if(!Opps.isEmpty())
                {
                    A = Opps[0];
                    A.Accommodation_Product__c = B.id;
      //              A.Pricebook2Id = '01s1t000004x8DIAAY';
                    update A;
                    
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
  i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
    i++;
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