({
	doInit : function(component, event, helper) {
        
    },

    closeWarningBox : function(component, event, helper){
		$A.util.addClass(component.find("modal_popup"), "slds-hide");
    },

    deleteRecords: function(component, event, helper) {
        helper.showSpinnerVisibility(component, event, helper);
        console.log('getExistingRecord helper');
        var contractAgreeId =component.get("v.recordId");
        var action = component.get("c.deleteExistingRecords");
        action.setParams({ contAgreeId: contractAgreeId });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                console.log(response.getReturnValue());
                console.log(typeof(response.getReturnValue()));
                if(response.getReturnValue() == null){
                    helper.hideSpinnerVisibility(component, event, helper);
                    var successText = 'Deletion Process Started. You will recieve an Email with Details when the process will be completed. Thanks '
                    helper.showPopup(component, "SUCCESS", "slds-theme--success", successText )
                    component.set("v.alreadyClicked", true);
                }else{
                    helper.hideSpinnerVisibility(component, event, helper);
                    var successText = response.getReturnValue();
                    helper.showPopup(component, "SUCCESS", "slds-theme--success", successText )
                    component.set("v.alreadyClicked", true);
                }
            }else{
                helper.showPopup(component, "ERROR", "slds-theme--error", "Something went Wrong. Please contact the System Administrator.")
                console.log('Failed to delete existing reocrds');
                helper.hideSpinnerVisibility(component, event, helper);
            }
        });
        $A.enqueueAction(action);
    }
})