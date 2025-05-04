public class Platform_UnitOfWork {
    public String description {get; set;}
    public String uowProcessor {get; set;}
    public String parentId {get; set;}
    public Map<String, Object> parameters {get; set;}
    public List<Platform_UnitOfWork> subWorks {get; set;}
    public Platform_UnitOfWork nextWork {get; set;}
    
    public Platform_UnitOfWork(String uowProcessor, Map<String, Object> parameters, String description, String parentId, String status) {
        this.uowProcessor = uowProcessor;
        this.parameters = parameters;
        this.description = description;
        this.parentId = parentId;
    }
    
    public Platform_UnitOfWork(String uowProcessor, Map<String, Object> parameters, String description, String parentId) {
        this.uowProcessor = uowProcessor;
        this.parameters = parameters;
        this.description = description;
        this.parentId = parentId;
    }

    public Platform_UnitOfWork(String uowProcessor, Map<String, Object> parameters, String description) {
        this.uowProcessor = uowProcessor;
        this.parameters = parameters;
        this.description = description;
        this.parentId = null;
    }
}