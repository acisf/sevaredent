public class AnnualNotificationController {
    
    public String memberId{get;set;}
    public Account memberAccount{get;set;}
    public String currentDate{get;set;}
    public String primaryContactName{get;set;}
    public String shippingStreet{get;set;}
    public String shippingAddress{get;set;}
    public String bodyLine1{get;set;}
    public String bodyLine2{get; set;}
    public String bodyLine3 {get; set;}
    public String footerLine1{get;set;}
    public String footerLine2{get; set;}
    public String footerLine3{get; set;}
    public String footerLine4{get; set;}
    public String footerLine5{get; set;}
    public String footerLine6{get; set;}
    
    public enum Error {
        Address_Not_Found,
            Primary_Contact_Not_Found
            }
    
    public static Map<Error, String> errors = new Map<Error, String>{
        Error.Address_Not_Found => 'Address not found',
            Error.Primary_Contact_Not_Found => 'Primary Contact not found'
            };
                
    public AnnualNotificationController(){
        memberId = System.currentPageReference().getParameters().get('memberId');
        memberAccount = getMemberAccount();
        currentDate = getCurrentDateString();
        shippingStreet = getShippingAddress();
        primaryContactName = getPrimaryContactName();
        bodyLine1 = 'RE: Sevaredent - Annual Report';
        bodyLine2 = 'Dear Sevaredent Member:';
        bodyLine3 = 'In accordance with section 4.3 of your Master Participation Agreement, this letter serves as your '+(System.today().year()-1)+' revenue report. This report summarizes the vendor fees received relative to the vendor and applicable Sevaredent contract for the reporting period 01/01/2022 – 12/31/2022. No action is required on your behalf. If you have any questions, please contact me.';
        footerLine1 = 'Sincerely,';
        footerLine2 = 'Blake Hibray';
        footerLine3 = 'President';
        footerLine4 = 'Sevaredent Sourcing Solutions, LLC';
        footerLine5 = '984.328.4156 (office)';
        footerLine6 = 'Blake.Hibray@sevaredent.com';
    }
    
    public AggregateResult[] getVendorAmounts() {
        return [SELECT 
                CA_Vendor_Contract__r.Sevaredent_Contract_Number__c  VendorContractName, 
                CA_Vendor_Contract__r.APXT_Redlining__Account__r.Name  VendorContractAccount, 
                CA_Vendor_Contract__r.Contract_Category_ID__r.Category__c Category,
                CA_Vendor_Contract__r.Contract_Category_ID__r.Sub_Category__c SubCategory,
                SUM(Amount__c) Amount
                FROM Revenue_Tracking__c 
                WHERE GPO_Member_Account__c =: memberId 
                AND Year__c =: (System.today().year()-1)
                GROUP BY 
                CA_Vendor_Contract__r.Sevaredent_Contract_Number__c, 
                CA_Vendor_Contract__r.APXT_Redlining__Account__r.Name,
                CA_Vendor_Contract__r.Contract_Category_ID__r.Category__c,
                CA_Vendor_Contract__r.Contract_Category_ID__r.Sub_Category__c];
    }
    
    @TestVisible
    private Account getMemberAccount(){
        Account memberAccount = [select Id, Name, ShippingStreet, ShippingState, ShippingCity, ShippingPostalCode from Account where Id =: memberId];
        return memberAccount;
    }
    
    @TestVisible
    private String getCurrentDateString(){
        DateTime dt = DateTime.now();
        String monthName = dt.format('MMMMM');
        String day = dt.format('dd');
        String year = dt.format('YYYY');
        String dateString = monthName+' '+day+','+' '+year;
        return dateString;
    }
    
    @TestVisible
    private String getShippingAddress(){
        if(!String.isBlank(memberAccount.ShippingStreet)){
            shippingAddress = getShippingAddressPart2();
            return memberAccount.ShippingStreet;
        }
        else{
            return errors.get(Error.Address_Not_Found);
        }
    }
    
    @TestVisible
    private String getShippingAddressPart2(){
        String shippingAddress = '';
        shippingAddress += memberAccount.ShippingCity+', ';
        shippingAddress += memberAccount.ShippingState+' ';
        shippingAddress += memberAccount.ShippingPostalCode;
        System.debug(' AnnualNotificationController.getShippingAddress shippingAddress: ' + shippingAddress);
        return shippingAddress;
    }
    
        @TestVisible
    private String getPrimaryContactName(){
       Revenue_Tracking__c a;        
        Double fy = System.today().year()-1;
        
        try{
            a = [SELECT Id, Name, Primary_Contact__r.Name FROM Revenue_Tracking__c
                                               WHERE GPO_Member_Account__c =: memberid AND
                                                Year__c =: fy
                                               LIMIT 1];
        }catch (Exception e){
            System.debug(' AnnualNotificationController.getPrimaryContactName e.getMessage(): ' + e.getMessage());
        }
        if(a!=null && a.Primary_Contact__r.Name!=null)
            return a.Primary_Contact__r.Name;
        else
            return '';
    }
    
    
    
}