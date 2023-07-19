({
    showSpinnerVisibility: function(component, event, helper) {
        $A.util.addClass(component.find("spinner_box"), "slds-show");
        $A.util.removeClass(component.find("spinner_box"), "slds-hide");
        
    },
    hideSpinnerVisibility: function(component, event, helper) {
        $A.util.addClass(component.find("spinner_box"), "slds-hide");
        $A.util.removeClass(component.find("spinner_box"), "slds-show");
    },
    showPopup : function(component, popupHeader, popupTheme, popupMessage, errorMessage){
		component.set("v.popupHeader", popupHeader);
		component.set("v.popupTheme", popupTheme);
        component.set("v.popupMessage", popupMessage);
        component.set("v.errorMessage", errorMessage);
        
        $A.util.removeClass(component.find("modal_popup"), 'slds-hide');
       
    },
    
})