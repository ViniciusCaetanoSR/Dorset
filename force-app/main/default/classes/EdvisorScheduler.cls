global class EdvisorScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        Datetime startDt = System.now().addDays(-1); // últimas 24 h
        Datetime endDt = System.now();
        Database.executeBatch(new EdvisorBatch(startDt, endDt), 100);
    }
}