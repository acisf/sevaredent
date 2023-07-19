/**
 * Apex controller for showRelatedFiles LWC component.
 */ 
public with sharing class ShowRelatedFilesController {

    /**
     * Returns a list of ContentVersion records. Delegates work to the 
     * ContractAgreementFiles class.
     * @param  contractId Id of Contract Agreement object record
     * @return            list of related files
     */ 
    @AuraEnabled(Cacheable=true)
    public static List<ContentVersion> getRelatedFiles(String contractId){
        try {
            return ContractAgreementFiles.getRelatedFiles(contractId);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}