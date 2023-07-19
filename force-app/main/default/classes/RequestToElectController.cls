/**
 * Apex controller for requestToElectBtn LWC component.
 */ 
public with sharing class RequestToElectController {

    /**
     * Get User’s Account name.
     * @param  id id description
     * @return    account name
     */ 
    @AuraEnabled(cacheable=true)
    public static string getAccountName(String id) {
        try {
            Id accId = id;
            return [SELECT Name FROM Account WHERE Id = :accId]?.Name;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Return Id of report from CommunitySettings__mdt object. This report 
     * will be shown by clicking on the “Get Pricing Items” button.
     * @return   Id of report
     */ 
    @AuraEnabled(cacheable=true)
    public static string getReportID() {
        try {
            return CommunitySettings__mdt.getInstance('Sevaredent_Portal')
                  .Item_Pricing_Report_ID__c;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}