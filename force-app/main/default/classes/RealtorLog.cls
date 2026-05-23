public with sharing class RealtorLog {
    public static void error(String processName, String className, Exception ex) {
        write(processName, className, ex.getMessage() + '\n' + ex.getStackTraceString());
    }

    public static void write(String processName, String className, String details) {
        try {
            insert new Error_Log__c(
                Log_Date_Time__c = System.now(),
                Process_Name__c = processName,
                Apex_Class_Name__c = className,
                Log_Details__c = details
            );
        } catch (Exception ignored) {
        }
    }
}
