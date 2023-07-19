/**
 * Created by cshah on Oct 19, 2020.
 */

public without sharing class ContractSummaryMSAController {

    public Contract contract    {get;set;}
    public String startDate     {get;set;}
    public String endDate       {get;set;}

    public ContractSummaryMSAController(ApexPages.StandardController stdController) {
        this.contract = (Contract)stdController.getRecord();
        Contract contractTemp = [SELECT Id, StartDate, EndDate FROM Contract WHERE Id = : this.contract.Id];
        this.startDate = getDateString(contractTemp.StartDate);
        this.endDate = getDateString(contractTemp.EndDate);

    }
    @TestVisible
    private String getDateString(Date date1) {
        Datetime datetime1 = Datetime.newInstance(date1, Datetime.now().time());
        String monthName = datetime1.format('MMMMM');
        String day = datetime1.format('dd');
        String year = datetime1.format('YYYY');
        String dateString = monthName+' '+day+','+' '+year;
        return dateString;
    }
}