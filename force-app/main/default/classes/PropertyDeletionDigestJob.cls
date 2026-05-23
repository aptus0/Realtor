public with sharing class PropertyDeletionDigestJob implements Schedulable {
    public void execute(SchedulableContext context) {
        List<Error_Log__c> logs = [
            SELECT Id, Log_Details__c, Log_Date_Time__c
            FROM Error_Log__c
            WHERE Process_Name__c = 'PropertyDeleteTrigger'
            AND Log_Date_Time__c = TODAY
            ORDER BY Log_Date_Time__c ASC
        ];
        if (logs.isEmpty()) {
            return;
        }

        List<String> managerEmails = new List<String>();
        for (Manager__c manager : [SELECT Email__c FROM Manager__c WHERE Email__c != null]) {
            managerEmails.add(manager.Email__c);
        }
        if (managerEmails.isEmpty()) {
            return;
        }

        String body = 'Deleted properties today:\n\n';
        for (Error_Log__c logRecord : logs) {
            body += '- ' + logRecord.Log_Details__c + '\n';
        }

        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.setToAddresses(managerEmails);
        message.setSubject('Daily deleted property digest');
        message.setPlainTextBody(body);
        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ message });
    }
}
