@IsTest
private class EdvisorSchedulerTest {
    @IsTest
    static void testSchedulerExecution() {
        for (CronTrigger ct : [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name = 'Edvisor Batch Scheduler']) {
            System.abortJob(ct.Id);
        }

        Test.startTest();
        System.schedule('Edvisor Batch Scheduler','0 0 0 1 1 ? 2099', new EdvisorScheduler());
        Test.stopTest();

        List<AsyncApexJob> jobs = [SELECT Id, JobType, Status FROM AsyncApexJob WHERE JobType = 'BatchApex'];
        System.assert(!jobs.isEmpty(), 'Um Batch deveria ter sido enfileirado pelo Scheduler');
    }
}