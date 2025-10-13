public with sharing class EdvisorDTO {

    public SchoolStudentEnrollmentResumedList schoolStudentEnrollmentResumedList;

    public class SchoolStudentEnrollmentResumedList {
        public Integer count { get; set; }
        public List<Application> applications { get; set; }
    }

    public class Application {
        public String studentEnrollmentId { get; set; }
        public String studentEnrollmentStatus { get; set; }
        public String created { get; set; }
        public String sentToSchool { get; set; }
        public String startDate { get; set; }
        public String endDate { get; set; }
        public String schoolId { get; set; }
        public String schoolCompanyId { get; set; }
        public String campus { get; set; }
        public String agency { get; set; }
        public String agencyLogoUrl { get; set; }
        public Student student { get; set; }
    }

    public class Student {
        public String studentId { get; set; }
        public String firstName { get; set; }
        public String lastName { get; set; }
        public String email { get; set; }
    }
}