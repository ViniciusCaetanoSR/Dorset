global class EdvisorScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        // Janela de 5 minutos
        Datetime nowTime = System.now();
        Datetime fiveMinAgo = nowTime.addMinutes(-5);

        // Rode o batch
        Database.executeBatch(new EdvisorBatch(fiveMinAgo, nowTime));

        // Próximo múltiplo de 5 min (sempre no futuro, segundos = 0)
        Integer add = 5 - Math.mod(nowTime.minute(), 5);
        Datetime next = Datetime.newInstance(nowTime.year(), nowTime.month(), nowTime.day(), nowTime.hour(), nowTime.minute(), 0)
            .addMinutes(add == 0 ? 5 : add);

        // CRON: s m H d M ? yyyy  (somente inteiros)
        String cron = String.format(
            '{0} {1} {2} {3} {4} ? {5}',
            new List<String>{
                '0',
                String.valueOf(next.minute()),
                String.valueOf(next.hour()),
                String.valueOf(next.day()),
                String.valueOf(next.month()),
                String.valueOf(next.year())
            }
        );

        // Mantém só um job vivo
        System.abortJob(sc.getTriggerId());
        System.schedule('Edvisor Batch Scheduler', cron, new EdvisorScheduler());
    }
}

//Executar pela primeira vez:

// Datetime start = System.now().addMinutes(5);
// String cron = String.format('0 {0} {1} {2} {3} ? {4}', new List<String>{
//     String.valueOf(start.minute()),
//     String.valueOf(start.hour()),
//     String.valueOf(start.day()),
//     String.valueOf(start.month()),
//     String.valueOf(start.year())
// });
// System.schedule('Edvisor Batch Scheduler', cron, new EdvisorScheduler());