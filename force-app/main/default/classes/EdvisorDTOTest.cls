@IsTest
private class EdvisorDTOTest {

    @IsTest
    static void testEdvisorDTOFields() {
        Test.startTest();
        
        EdvisorDTO dto = new EdvisorDTO();

        EdvisorDTO.SchoolStudentEnrollmentResumedList resumedList = new EdvisorDTO.SchoolStudentEnrollmentResumedList();
        resumedList.count = 2;
        resumedList.applications = new List<EdvisorDTO.Application>();

        EdvisorDTO.Application app1 = new EdvisorDTO.Application();
        app1.studentEnrollmentId = 'ENR123';
        app1.studentEnrollmentStatus = 'Active';
        app1.created = '2025-09-10T12:00:00Z';
        app1.sentToSchool = 'true';
        app1.startDate = '2025-10-01';
        app1.endDate = '2025-12-15';
        app1.schoolId = 'SCH001';
        app1.schoolCompanyId = 'COMP001';
        app1.campus = 'Downtown Campus';
        app1.agency = 'Edvisor Agency';
        app1.agencyLogoUrl = 'https://example.com/logo.png';

        EdvisorDTO.Student student1 = new EdvisorDTO.Student();
        student1.studentId = 'STU001';
        student1.firstName = 'John';
        student1.lastName = 'Doe';
        student1.email = 'john.doe@example.com';
        app1.student = student1;

        EdvisorDTO.Application app2 = new EdvisorDTO.Application();
        app2.studentEnrollmentId = 'ENR456';
        app2.studentEnrollmentStatus = 'Pending';
        app2.created = '2025-09-11T14:30:00Z';
        app2.sentToSchool = 'false';
        app2.startDate = '2025-11-01';
        app2.endDate = '2026-01-20';
        app2.schoolId = 'SCH002';
        app2.schoolCompanyId = 'COMP002';
        app2.campus = 'Main Campus';
        app2.agency = 'Global Agency';
        app2.agencyLogoUrl = 'https://example.com/logo2.png';

        EdvisorDTO.Student student2 = new EdvisorDTO.Student();
        student2.studentId = 'STU002';
        student2.firstName = 'Jane';
        student2.lastName = 'Smith';
        student2.email = 'jane.smith@example.com';
        app2.student = student2;

        resumedList.applications.add(app1);
        resumedList.applications.add(app2);

        dto.schoolStudentEnrollmentResumedList = resumedList;

        Test.stopTest();

        System.assertNotEquals(null, dto.schoolStudentEnrollmentResumedList, 'A lista não pode ser nula');
        System.assertEquals(2, dto.schoolStudentEnrollmentResumedList.count, 'O count deveria ser 2');
        System.assertEquals(2, dto.schoolStudentEnrollmentResumedList.applications.size(), 'Deveria ter 2 aplicações');

        System.assertEquals('ENR123', dto.schoolStudentEnrollmentResumedList.applications[0].studentEnrollmentId);
        System.assertEquals('John', dto.schoolStudentEnrollmentResumedList.applications[0].student.firstName);

        System.assertEquals('ENR456', dto.schoolStudentEnrollmentResumedList.applications[1].studentEnrollmentId);
        System.assertEquals('Jane', dto.schoolStudentEnrollmentResumedList.applications[1].student.firstName);
    }
}