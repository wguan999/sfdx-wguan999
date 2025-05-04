public class Log {
    public static Log__c logError(Exception e) {
        return logError(e.getTypeName(), e.getMessage(), String.valueOf(e.getcause()), String.valueOf(e.getLineNumber()), e.getStackTraceString());
    }

    public static Log__c logError(String errorLogRecordId, Exception e) {
        return logError(errorLogRecordId, e.getTypeName(), e.getMessage(), String.valueOf(e.getcause()), String.valueOf(e.getLineNumber()), e.getStackTraceString(), null, null, null);
    }

    public static Log__c logError(Exception e, String EndPoint, String Request, String Response) {
        return logError(null, e.getTypeName(), e.getMessage(), String.valueOf(e.getcause()), String.valueOf(e.getLineNumber()), e.getStackTraceString(), EndPoint, Request, Response);
    }

    public static Log__c logError(String errorLogRecordId, Exception e, String EndPoint, String Request, String Response) {
        return logError(errorLogRecordId, e.getTypeName(), e.getMessage(), String.valueOf(e.getcause()), String.valueOf(e.getLineNumber()), e.getStackTraceString(), EndPoint, Request, Response);
    }

    public static Log__c logError(String TypeName , String Message, String Cause, String LineNumber, String StackTrace) {
		return logError(null, TypeName, Message, Cause, LineNumber, StackTrace, null, null, null);
    }

    public static Log__c logError(String errorLogRecordId, String TypeName , String Message, String Cause, String LineNumber, String StackTrace, String EndPoint, String Request, String Response) {
        System.debug('inside error log');
        Log__c log = new Log__c();
        log.Type_Name__c = TypeName;
        log.Message__c = Message;
        log.Cause__c = Cause;
        log.Line_Number__c = LineNumber;
        log.Stack_Trace__c = StackTrace;
        log.Record_Id__c = ( (errorLogRecordId != null || errorLogRecordId != '') ? errorLogRecordId : null);
        log.User__c = UserInfo.getFirstName() + ' ' + UserInfo.getLastName();
        log.request__c = request;
        log.response__c = response;
        log.End_Point__c = endPoint;
        insert log;
        return log;
    }
	
    public static void sendErrorEvent(Exception e) {
        sendErrorEvent(e.getTypeName(), e.getMessage(), String.valueOf(e.getcause()), String.valueOf(e.getLineNumber()), e.getStackTraceString());
    }

    public static void sendErrorEvent(String errorLogRecordId, Exception e) {
        sendErrorEvent(errorLogRecordId, e.getTypeName(), e.getMessage(), String.valueOf(e.getcause()), String.valueOf(e.getLineNumber()), e.getStackTraceString(), null, null, null);
    }

    public static void sendErrorEvent(Exception e, String EndPoint, String Request, String Response) {
        sendErrorEvent(null, e.getTypeName(), e.getMessage(), String.valueOf(e.getcause()), String.valueOf(e.getLineNumber()), e.getStackTraceString(), EndPoint, Request, Response);
    }

    public static void sendErrorEvent(String errorLogRecordId, Exception e, String EndPoint, String Request, String Response) {
        sendErrorEvent(errorLogRecordId, e.getTypeName(), e.getMessage(), String.valueOf(e.getcause()), String.valueOf(e.getLineNumber()), e.getStackTraceString(), EndPoint, Request, Response);
    }

    public static void sendErrorEvent(String TypeName , String Message, String Cause, String LineNumber, String StackTrace) {
		sendErrorEvent(null, TypeName, Message, Cause, LineNumber, StackTrace, null, null, null);
    }

    public static void sendErrorEvent(String errorLogRecordId, String TypeName , String Message, String StackTrace) {
		sendErrorEvent(errorLogRecordId, TypeName, Message, null, null, StackTrace, null, null, null);
    }

    public static void sendErrorEvent(String errorLogRecordId, String TypeName , String Message, String Cause, String LineNumber, String StackTrace, String EndPoint, String Request, String Response) {
        Log_Event__e newsEvent = new Log_Event__e(
            Type_Name__c 	= (TypeName!=null)?TypeName:'',
            Message__c 		= (Message!=null)?Message:'',
            Cause__c       	= (Cause!=null)?Cause:'',
            Line_Number__c 	= (LineNumber!=null)?LineNumber:'',
            Stack_Trace__c 	= (StackTrace!=null)?StackTrace:'',
            Record_Id__c   	= (errorLogRecordId!=null)?errorLogRecordId:'',
            request__c   	= (request!=null)?request:'',
            response__c    	= (response!=null)?response:'',
            End_Point__c    = (endPoint!=null)?endPoint:'');
        // Call method to publish events
        Database.SaveResult sr = EventBus.publish(newsEvent);
        if (!sr.isSuccess()) {
            for(Database.Error err : sr.getErrors()) {
                System.debug('Error returned: ' +
                            err.getStatusCode() +
                            ' - ' +
                            err.getMessage());
            }
        }    
    }
	
}