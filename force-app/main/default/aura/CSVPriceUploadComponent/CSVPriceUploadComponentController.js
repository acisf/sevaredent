({
	doInit : function(component, event, helper) {
        //including customMetadata
        helper.getExistingRecord(component, event, helper);
        helper.getItemPricingReport(component, event, helper);
    },
    handleFilesChange: function(component, event, helper) {
        var fileName = 'No File Selected..';
        if (event.getSource().get("v.files").length > 0) {
        	component.set("v.isCSV",true);
        	fileName = event.getSource().get("v.files")[0]['name'];
        	console.log(fileName.substr(fileName.length - 3).toUpperCase());
        	if(fileName.substr(fileName.length - 3).toUpperCase() != 'CSV' ){
            	fileName = 'Please select a file with CSV Extension';
            	component.set("v.isCSV",false);
        	}
        }
        component.set("v.fileName", fileName);
        
    },
    //ERROR WARNING
    closeWarningBox : function(component, event, helper){
		$A.util.addClass(component.find("modal_popup"), "slds-hide");
    },
    
    showConfirmBox: function(component, event, helper) {
        var isCSV = component.get("v.isCSV");
        var files = component.find('fileId').get("v.files");
        if (files != null && files.length > 0 && isCSV) {
            helper.showDiv(component, event, helper,'areYouSure');
        } else {
            //alert('Please Select a Valid File.');
            helper.showPopup(component, "ERROR", "slds-theme--error", "Please select a valid file to upload.")
        }
    },
    hideConfirmBox: function(component, event, helper) {
    	helper.hideDiv(component, event, helper,'areYouSure');
    },

    doSave: function(component, event, helper) {
    	//helper.toggleSpinnerVisibility(component, event, helper);
		console.log('calling save helper');
        helper.saveCSVData(component, event, helper);
        helper.hideDiv(component, event, helper,'areYouSure');
        
    },
    handleRowAction : function(component, event, helper){
        var selRows = event.getParam('selectedRows');
        console.log('selRows : '+ JSON.stringify(selRows));
        component.set("v.deleteIds", selRows );
    },   

    loadMoreData: function (component, event, helper) {
        console.log('loadMoreData function');
        //event.getSource().set("v.isLoading", false); 
        /*var rowsToLoad = cmp.get('v.rowsToLoad');
        event.getSource().set("v.isLoading", true);
        cmp.set('v.loadMoreStatus', 'Loading');
        helper.fetchData(cmp, event, cmp.get("v.data").length); */

        console.log('TOTAL ROWS', component.get("v.totalRows"));

        if(! ((component.get("v.currentCount") >= component.get("v.totalRows")))) {
            //KEEP LOADING
            event.getSource().set("v.isLoading", true); 
            helper.loadMoreRecords(component, event, helper);
        }else{
            //STOP LOADING
        }



    },

    goToReport: function(component, event, helper) {
        console.log('I am in goToRepprt');
        //helper.getItemPricingReport(component, event, helper);
        var contractAgreementName = component.get("v.contractAgreementName")
        var reportId = component.get("v.reportId")
        var url = '/lightning/r/Report/' + reportId + '/view?fv0=' + contractAgreementName;
        window.open(url,'_blank');
    }

})