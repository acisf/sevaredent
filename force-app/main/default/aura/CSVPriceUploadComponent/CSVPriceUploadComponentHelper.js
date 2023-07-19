({
	getExistingRecord :function(component, event, helper, reloadTime) {
        if(!reloadTime){
            helper.showSpinnerVisibility(component, event, helper);
        }
        console.log('getExistingRecord helper');
        var contractAgreeId =component.get("v.recordId");
        var action = component.get("c.getExistingRecords");
        console.log('action : '+action);
        action.setParams({ contAgreeId: contractAgreeId });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                //if(response.getReturnValue().listExistingPricingItems != null ){
                if(response.getReturnValue().totalRows != null ){
                    //component.set("v.listRecordToUpload",response.getReturnValue().listExistingPricingItems);
                    //component.set("v.listRecordExists",response.getReturnValue().listExistingPricingItems);
                    
                    helper.hideSpinnerVisibility(component, event, helper);
                    console.log('existing RECORD '+ JSON.stringify(response.getReturnValue().listExistingPricingItems ) );
                    component.set("v.dataExists",true);
                    component.set("v.totalRows",response.getReturnValue().totalRows);
                }else{
                    component.set("v.dataExists",false);
                    helper.hideSpinnerVisibility(component, event, helper);
                    component.set("v.totalRows",0);
                }
                //For custom MEtadata Type
                if(!reloadTime){
                    if(response.getReturnValue().listCustomMetadataRecords != null  ){
                        component.set("v.listCustomMetadataRecords",response.getReturnValue().listCustomMetadataRecords);
                        helper.extractCustomMetadata(component, event, helper);
                        //console.log('CustomMetadata RECORD '+ JSON.stringify(response.getReturnValue().listCustomMetadataRecords ) );
                    }else{
                        console.log('Missing Custom Metadata');
                    }
                }
                
            }else{
                helper.showPopup(component, "ERROR", "slds-theme--error", "Something went Wrong. Please contact the System Administrator.")
                console.log('Failed to get existing reocrds');
                helper.hideSpinnerVisibility(component, event, helper);
            }
        });
        $A.enqueueAction(action);
    },
    toggleSpinnerVisibility: function(component, event, helper) {
        $A.util.toggleClass(component.find("spinner_box"), "slds-hide");
    },

    loadMoreRecords: function(component, event, helper) {
        helper.showSpinnerVisibility(component, event, helper);
        var action = component.get("c.getsObjectRecords");
        var offsetCount = component.get("v.currentCount");
        var contractAgreeId =component.get("v.recordId");

        action.setParams({ OFFSET: offsetCount, 
                        contAgreeId: contractAgreeId });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                if(response.getReturnValue() != null ){
                    //component.set("v.listRecordToUpload",response.getReturnValue().listExistingPricingItems);
                    helper.hideSpinnerVisibility(component, event, helper);
                    var currentCount = component.get("v.currentCount");
                    currentCount += component.get("v.initialRows");
                    // set the current count with number of records loaded 
                    component.set("v.currentCount",currentCount);
                    
                    var currentData = component.get("v.listRecordExists");
                    var newData = currentData.concat(response.getReturnValue());
                    component.set("v.listRecordExists", newData);

                    event.getSource().set("v.isLoading", false); 

                }else{
                    helper.hideSpinnerVisibility(component, event, helper);
                }
                
            }else{
                helper.showPopup(component, "ERROR", "slds-theme--error", "Something went Wrong. Please contact the System Administrator.")
                console.log('Failed to get existing reocrds');
                helper.hideSpinnerVisibility(component, event, helper);
            }
        });
        $A.enqueueAction(action);



        
    },



    showPopup : function(component, popupHeader, popupTheme, popupMessage, errorMessage){
		component.set("v.popupHeader", popupHeader);
		component.set("v.popupTheme", popupTheme);
        component.set("v.popupMessage", popupMessage);
        component.set("v.errorMessage", errorMessage);
        
        $A.util.removeClass(component.find("modal_popup"), 'slds-hide');
       
    },
    
    extractCustomMetadata: function(component, event, helper) {
        
        var listCustomMRecords = component.get("v.listCustomMetadataRecords");
        var listOfCSVLabels = [];
        var listOfDataTableColumn = [];
        var mapCSVToSFFeild = {};
        for(var index in listCustomMRecords){
            
            if(listCustomMRecords[index].Salesforce_Field_Name__c != 'UNIQUE_KEY__c' )   { 
                var temp = {label: listCustomMRecords[index].CSV_Field_Name__c, fieldName: listCustomMRecords[index].Salesforce_Field_Name__c, type: listCustomMRecords[index].Type__c , initialWidth: 150, editable: true, wrapText: true};
                listOfDataTableColumn.push( temp );
            }else{
                var temp = {label: listCustomMRecords[index].CSV_Field_Name__c, fieldName: 'Unique_Key_Formula__c', type: listCustomMRecords[index].Type__c , columnWidthsMode: "fixed",initialWidth: 200, editable: false, wrapText: true};
                listOfDataTableColumn.push( temp );
            }

            
            //REMOVING SPACES
            listOfCSVLabels.push(listCustomMRecords[index].CSV_Field_Name__c.replace(/\s/g, ''));
            mapCSVToSFFeild[listCustomMRecords[index].CSV_Field_Name__c.replace(/\s/g, '')] = listCustomMRecords[index].Salesforce_Field_Name__c;
        }
    
        
        //This one for Data table COlumn
        component.set("v.listOfFieldsCSV",listOfDataTableColumn);

        component.set("v.listOfCSVLabels",listOfCSVLabels);


        component.set("v.mapCSVToSFFeild",mapCSVToSFFeild);
        
    },

    showDiv : function(component, event, helper ,compAuraId) {
        var divisionToShow =component.find(compAuraId);
        if(typeof divisionToShow != 'undefined'){
            $A.util.removeClass(divisionToShow, 'slds-hide');
            $A.util.addClass(divisionToShow, 'slds-show');
        }

    },
    hideDiv : function(component, event, helper ,compAuraId) {
        var divisionToHide =component.find(compAuraId);
        if(typeof divisionToHide != 'undefined'){
            $A.util.removeClass(divisionToHide, 'slds-show');
            $A.util.addClass(divisionToHide, 'slds-hide');
        }
    },

    //TO SAVE LOADED DATA
    saveCSVData : function(component, event, helper) {
        helper.showSpinnerVisibility(component, event, helper);
        console.log('saveCSVData');
		//Only Following feilds will be uploaded on salesfroce	
        var listAcceptedFields = component.get("v.listOfCSVLabels");
        console.log('listAcceptedFields : '+ JSON.stringify(listAcceptedFields));
		//converting to upper case
		var listAcceptedFieldsUpperCase = listAcceptedFields.map(function(x){ return x.toUpperCase() })
        //Map of Feild Name to API name

        
        console.log('listAcceptedFieldsUpperCase : '+ JSON.stringify(listAcceptedFieldsUpperCase));
        

        var mapNameToAPIname = component.get("v.mapCSVToSFFeild");
        console.log('mapNameToAPIname : '+ JSON.stringify(mapNameToAPIname));

		var files = component.find('fileId').get("v.files");
		var fileName = files[0]['name'];
		var textData ;
		var infolst =[];
		var reader = new FileReader();

		//to check Empty Object
		function isEmpty(obj) {
    		for(var key in obj) {
        		if(obj.hasOwnProperty(key))
            		return false;
    			}
    		return true;
		}

        //Handle Values with Comma and New line
        function csvToArray(text) {
            let p = '', row = [''], ret = [row], i = 0, r = 0, s = !0, l;
            
            for (l of text) {
                if ('"' === l) {
                    if (s && l === p) row[i] += l;
                    s = !s;
                } else if (',' === l && s) l = row[++i] = '';
                else if ('\n' === l && s) {
                    if ('\r' === p) row[i] = row[i].slice(0, -1);
                    row = ret[++r] = [l = '']; i = 0;
                } else row[i] += l;
                p = l;
            }
            return ret;
        };

		reader.onload = function() {
            var text = reader.result;
            console.log(reader.result.substring(0, 200));
            console.log('Data from CSV file' + text);
            textData = text;
            //var rows = textData.split(/\r\n|\n/); /*Spilt based on new line to get each row*/
            var rows = csvToArray(textData);
            var header = rows[0];
            

            /* Ignore the first row (header)  and start from second*/
            for (var i = 1; i < rows.length; i = i + 1) {
                console.log('Length', +rows.length); //total number of rows in the file including header
                /*Spilt based on the comma*/
                var cells = rows[i];
                console.log('One row' + cells);
                console.log('Row length' + cells.length);
 
                if(cells.length!=1){
                    
                    var contractNumber = '';
                    var manufName = '';
                    var manufPartNum = '';
                    var startDate = '';
                    var rowData = {};
                    var UOM = '';
                	for(var j = 0; j < header.length; j = j + 1){
                        console.log('Test '+header[j].replace(/\s/g, '').toUpperCase()+' +++ '+cells[j]);
                        if(typeof header[j] != 'undefined'){
                            if(listAcceptedFieldsUpperCase.indexOf(header[j].replace(/\s/g, '').toUpperCase()) > -1){
                                if(cells[j]){

                                        //TO create Unqiue Key
                                        if( ( header[j].replace(/\s/g, '').toUpperCase() == 'SEVAREDENTCONTRACTNBR' ) ) {
                                            contractNumber = cells[j];
                                        }

                                        if( ( header[j].replace(/\s/g, '').toUpperCase() == 'MANUFACTURERNAME' ) ) {
                                            manufName = cells[j];
                                        }
                                        if( ( header[j].replace(/\s/g, '').toUpperCase() == 'MANUFACTURERPARTNUMBER' ) ) {
                                            manufPartNum = cells[j];
                                        }
                                        if( ( header[j].replace(/\s/g, '').toUpperCase() == 'UOM' ) ) {
                                            UOM = cells[j];
                                        }




                                        //REMOVE $ SIGN FROM CURRENCY
                                        if( ( header[j].replace(/\s/g, '').toUpperCase() == 'LIST$P/UOM' ) 
                                            || ( header[j].replace(/\s/g, '').toUpperCase() == 'CONTRACTTIER1PRICE/UOM' ) 
                                            || ( header[j].replace(/\s/g, '').toUpperCase() == 'CONTRACTTIER2PRICE/UOM' ) 
                                            || ( header[j].replace(/\s/g, '').toUpperCase() == 'CONTRACTTIER4PRICE/UOM' ) 
                                            || ( header[j].replace(/\s/g, '').toUpperCase() == 'CONTRACTTIER3PRICE/UOM' ) 
                                            ){
                                            
                                            if(cells[j].includes("$")){
                                                console.log('INSIDE DOLLAR')
                                                cells[j] = cells[j].replace("$", "");
                                            }
                                            
                                            rowData[mapNameToAPIname[header[j].replace(/\s/g, '')]] = cells[j];

                                        }else if( ( header[j].replace(/\s/g, '').toUpperCase() == 'PRICEENDDATE' ) || header[j].replace(/\s/g, '').toUpperCase() == 'PRICESTARTDATE' ){
                                            //ON CSV TO CONCATINATE =CONCATENATE(TEXT(AB2,"mmddyyyy"))

                                            //FIX DATE //MM/DD/YYYY CSV
                                            //SAlesforce YYYY-MM-DD
                                            var date = cells[j];
                                            var datearray = date.split("/");
                                            var uniqueKeyDateString = '';

                                            
                                            
                                            if(typeof datearray[2] != 'undefined' && datearray[2] != null){
                                                if(datearray[2].length == 2){
                                                    cells[j] =  '20'+datearray[2]+'-'+(datearray[0] = (datearray[0].length == 2)?datearray[0]:'0'+datearray[0]) + '-' + (datearray[1] = (datearray[1].length == 2)?datearray[1]:'0'+datearray[1]) ;
                                                    uniqueKeyDateString = datearray[0] + datearray[1] + '20'+datearray[2];

                                                }else{
                                                    cells[j] =  datearray[2]+'-'+(datearray[0] = (datearray[0].length == 2)?datearray[0]:'0'+datearray[0]) + '-' + (datearray[1] = (datearray[1].length == 2)?datearray[1]:'0'+datearray[1]);
                                                    uniqueKeyDateString = datearray[0] + datearray[1] + datearray[2];
                                                }
                                            }
                                            rowData[mapNameToAPIname[header[j].replace(/\s/g, '')]] = cells[j];

                                            console.log('cells[j] '+ cells[j]);
                                            //for Start Date
                                            if(header[j].replace(/\s/g, '').toUpperCase() == 'PRICESTARTDATE'){
                                                startDate = uniqueKeyDateString;
                                                //THERE ARE SOME PROBLEMS IN GEETING DAYS from 1/1/1900
                                                //EXCEL 01/01/2008 - 39448
                                                //Excel 01/02/1900 - 2
                                                //OUR CODE 01/01/2008 - 39446
                                                //OUR CODE 01/02/1900 - 1
                                               /* function getDateDiffrence(startDate) {
                                                    var a = new Date("01/01/1900");
                                                    var b = new Date(startDate);

                                                    const utc1 = Date.UTC(a.getFullYear(), a.getMonth(), a.getDate());
                                                    const utc2 = Date.UTC(b.getFullYear(), b.getMonth(), b.getDate());
                                                    
                                                    // To calculate the time difference of two dates
                                                    var Difference_In_Time = utc2 - utc1 
                                                    // To calculate the no. of days between two dates
                                                    var Difference_In_Days = Math.floor((utc2 - utc1) / (1000 * 60 * 60 * 24));
                                                    
                                                    
                                                    //To display the final no. of days (result)
                                                    console.log('Difference_In_Time :  '+Difference_In_Time +'   '+Difference_In_Days);
                                                  }


                                                getDateDiffrence(cells[j]);*/

                                            }


                                            
                                        }else{
                                            
                                            rowData[mapNameToAPIname[header[j].replace(/\s/g, '')]] = cells[j];
                                        }                                    
                                        

                                        
                                }else if(typeof cells[j] == 'undefined' || cells[j] == ""){
                                    cells[j] = null;
                                    rowData[mapNameToAPIname[header[j].replace(/\s/g, '')]] = cells[j];
                                }

                            }
                        }

	 				}
                    
                    var selectedContId =component.get("v.recordId");

                    var unqiueKey = selectedContId.trim()+'_'+contractNumber.trim()+'_'+manufName.trim()+'_'+manufPartNum.trim()+'_'+UOM.trim()+'_'+startDate.trim();
                    //if the user already upload unique key using =CONCATENATE(TEXT(AB2,"mmddyyyy")) then should we keep that?
                    //Not keeping it to avoid confusion of using 
                    

                    //TO CHECK FOR UPDATE AND EXISTING RECORDS
                    rowData['UNIQUE_KEY__c'] = unqiueKey;


                    console.log('unqiueKey '+unqiueKey);

	 				if(!isEmpty(rowData)){
	 					rowData['sobjectType']='Item_Pricing__c';
                        rowData['Created_From_CSV__c']=true;
	 					rowData['Contract_Agreement__c']=component.get("v.recordId");
                         	
	 					infolst.push(rowData);
	 				}
	 				
	 				
	                

                }
 
                
            }
            console.log('Sheet Data : '+ JSON.stringify(infolst) );
	        component.set("v.listRecordToUpload",infolst);

            //upload data to salesforce
       		window.setTimeout(
			$A.getCallback(function() {
				helper.uploadToSalesforce(component, event, helper);
			}), 2000);

            //debugger;
        };

        if (files[0] !== undefined && files[0] !== null && files[0] !== '') {
            reader.readAsText(files[0]);
        }
        
	},

    uploadToSalesforce : function(component, event, helper) {
        console.log('uploadToSalesforce helper');
        helper.showSpinnerVisibility(component, event, helper);
		var listOfRecordToUpload = JSON.parse(JSON.stringify(component.get("v.listRecordToUpload")));
		
        //var selectedCaseId = component.get("v.caseId");
        var selectedContId =component.get("v.recordId");
        //it is actual number
        var sevaredentContractNameMain = component.get("v.contractAgreementRecord").Sevaredent_Contract_Number__c;

        console.log(listOfRecordToUpload);
        console.log('selectedContId: '+selectedContId);
        console.log('sevaredentContractNameMain: '+sevaredentContractNameMain);

        var action = component.get("c.saveCSVFile");
		action.setParams({ listRecordsToinsertTemp  : listOfRecordToUpload,
            contId: selectedContId,
            sevContName : sevaredentContractNameMain    
        });
        action.setCallback(this, function(response) {
        	var state = response.getState();
        	console.log('test' +state);
	        if (state === "SUCCESS") {
                console.log('records processed');
                var uploadedRecords = response.getReturnValue();
                console.log('uploadedRecords : '+JSON.stringify(uploadedRecords));
            	if(typeof uploadedRecords !== 'undefined' && uploadedRecords != null){
                    var messageText = '';
                    var errorMessage = '';
                    
                    if(typeof uploadedRecords.insertedRecords !== 'undefined' && uploadedRecords.insertedRecords != null){
                        messageText = messageText+ '\n Successfully Inserted : '+ uploadedRecords.insertedRecords.length + ' Record/s \n';
                    }

                    if(typeof uploadedRecords.updatedRecords !== 'undefined' && uploadedRecords.updatedRecords != null){
                        messageText = messageText+ '\n Successfully Updated : '+ uploadedRecords.updatedRecords.length + ' Record/s \n';
                    }

                    if(typeof uploadedRecords.recordsTodelete !== 'undefined' && uploadedRecords.recordsTodelete != null){
                        
                        component.set("v.listRecordToDelete",uploadedRecords.recordsTodelete);
                        
                    }

                    if(typeof uploadedRecords.failedRecords !== 'undefined' && uploadedRecords.failedRecords != null){
                        if(Object.keys(uploadedRecords.failedRecords).length === 0 && uploadedRecords.failedRecords.constructor === Object){
                            //show success
                            helper.showPopup(component, "SUCCESS", "slds-theme--success", messageText )
                        }else{

                                errorMessage = 'Records Inserted : 0' + '\n' + 'Records Updated : 0' + '\n' + 'Records Deleted : 0' + '\n';
                                for (const item of Object.entries(uploadedRecords.failedRecords)) {
                                    errorMessage = errorMessage + '\nFailed To Upload : '+ item + '\n';
                                }
                            helper.showPopup(component, "WARNING/ERROR", "slds-theme--error", messageText, errorMessage )
                            helper.getExistingRecord(component, event, helper, true);
                            helper.hideSpinnerVisibility(component, event, helper);
                        }
                    }else{
                        //show success
                        helper.showPopup(component, "SUCCESS", "slds-theme--success", messageText );
                        helper.getExistingRecord(component, event, helper, true);
                        helper.hideSpinnerVisibility(component, event, helper);
                    }
                    if(uploadedRecords.failedRecords == null){
                        helper.deleteRecords(component, event, helper);
                    }
                    
                   // helper.showPopup(component, "SUCCESS", "slds-theme--success", messageText );

                    

               // helper.getExistingRecord(component, event, helper, true);
               // helper.hideSpinnerVisibility(component, event, helper);

                }
            }else if(state === "ERROR"){
                //var errorMessage = '';
                    var errors = action.getError();
                    var errorMsg = errors[0].message;
                    console.log(errorMsg);
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        title: 'Error',
                        type: 'error',
                        mode: 'sticky',
                        message: errorMsg
                    });
                    toastEvent.fire();	
                    
                    
                    /*if (errors[0] && errors[0].message) {

                        alert(errors[0].message);
                    }*/

                    helper.hideSpinnerVisibility(component, event, helper);
                    //helper.showPopup(component, "ERROR",errorMsg);
            }else {
                //TYPE CAST ISSUE
                    //THE COLUMNS IN SHEET HAS INCORRCT VALUE TYPE IN ACCORDANCE WITH SALESFORCE.
                    //E.G. Number field has text value
                    console.log('State: '+state);
                    console.log('Failed to Upload Records');
                    helper.getExistingRecord(component, event, helper, true);
                    helper.showPopup(component, "ERROR", "slds-theme--error","No Records Uploaded!", "Incorrect Data on the Sheet! \nPlease check the currency and quantity columns' values on CSV. \n Also, please check the date format.(Acceptable MM/DD/YYYY).\nDoes the issue still persist? Please contact the System Administrator.")
                    //component.set("v.resultText",'Failed to insert Records' );
                    helper.hideSpinnerVisibility(component, event, helper);
            }
                /*var booleanvalue = response.getReturnValue().booleanvalue;
                if(booleanvalue){
                    messageText = 'Records Successfully inserted/upserted';
                    helper.showPopup(component, "SUCCESS", "slds-theme--success", messageText )
                }else{
                    messageText = 'Some records got failed';
                    helper.showPopup(component, "WARNING/ERROR", "slds-theme--error", messageText);
                }
            }else{
                    //TYPE CAST ISSUE
                    //THE COLUMNS IN SHEET HAS INCORRCT VALUE TYPE IN ACCORDANCE WITH SALESFORCE.
                    //E.G. Number field has text value
                    console.log('Failed to Upload Records');
                    helper.getExistingRecord(component, event, helper, true);
                    helper.showPopup(component, "ERROR", "slds-theme--error","No Records Uploaded!", "Incorrect Data on the Sheet! \nPlease check the currency and quantity columns' values on CSV. \n Also, please check the date format.(Acceptable MM/DD/YYYY).\nDoes the issue still persist? Please contact the System Administrator.")
                    //component.set("v.resultText",'Failed to insert Records' );
                    helper.hideSpinnerVisibility(component, event, helper);
                }*/
            });

            $A.enqueueAction(action);
        },

        deleteRecords : function(component, event, helper){
            console.log('I am in delete records');
            var listTodelete = component.get('v.listRecordToDelete');
            console.log('listTodelete: '+listTodelete);
            var action = component.get("c.deleteItemPricingRecords");
            action.setParams({
                recordsToDelete : listTodelete
            });
            action.setCallback(this, function(response){
                var state = response.getState();
                if(state === "SUCCESS"){
                    var result = response.getReturnValue();

                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        title: 'Deleted Records',
                        type: 'Success',
                        mode: 'sticky',
                        message: result + ' records deleted.'
                    });
                    toastEvent.fire();
                    helper.getExistingRecord(component, event, helper, true);
                }if(state === "ERROR"){
                    var errors = action.getError();
                    var errorMsg = errors[0].message;
                    console.log(errorMsg);
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        title: 'Error',
                        type: 'error',
                        mode: 'sticky',
                        message: errorMsg
                    });
                    toastEvent.fire();
                }
            });
            $A.enqueueAction(action);
        },

    /*uploadToSalesforce : function(component, event, helper) {
        console.log('uploadToSalesforce helper');
        helper.showSpinnerVisibility(component, event, helper);
		var listOfRecordToUpload = component.get("v.listRecordToUpload");
		var action = component.get("c.saveCSVFile");
        //var selectedCaseId = component.get("v.caseId");
        var selectedContId =component.get("v.recordId");
        //it is actual number
        var sevaredentContractNameMain = component.get("v.contractAgreementRecord").Sevaredent_Contract_Number__c;


		action.setParams({ listRecordsToinsertTemp  : listOfRecordToUpload,
            contId: selectedContId,
            sevContName : sevaredentContractNameMain,    
        });
        action.setCallback(this, function(response) {
        	var state = response.getState();
        	console.log('test' +state);
	        if (state === "SUCCESS") {
                var uploadedRecords = response.getReturnValue();
                console.log('uploadedRecords : '+JSON.stringify(uploadedRecords));
            	if(typeof uploadedRecords !== 'undefined' && uploadedRecords != null){
                    var messageText = '';
                    var errorMessage = '';
                    if(typeof uploadedRecords.insertedRecords !== 'undefined' && uploadedRecords.insertedRecords != null){
                        messageText = messageText+ '\n Successfully Inserted : '+ uploadedRecords.insertedRecords.length + ' Record/s \n';
                    }

                    if(typeof uploadedRecords.updatedRecords !== 'undefined' && uploadedRecords.updatedRecords != null){
                        messageText = messageText+ '\n Successfully Updated : '+ uploadedRecords.updatedRecords.length + ' Record/s \n';
                    }

                    if(typeof uploadedRecords.deletedRecords !== 'undefined' && uploadedRecords.deletedRecords != null){
                           
                    }

                    //deletedRecords
                   
                    if(typeof uploadedRecords.failedRecords !== 'undefined' && uploadedRecords.failedRecords != null){
                        if(Object.keys(uploadedRecords.failedRecords).length === 0 && uploadedRecords.failedRecords.constructor === Object){
                            //show success
                            helper.showPopup(component, "SUCCESS", "slds-theme--success", messageText )
                        }else{
                                for (const item of Object.entries(uploadedRecords.failedRecords)) {
                                    errorMessage = errorMessage + '\nFailed To Upload : '+ item + '\n';
                                }
                            helper.showPopup(component, "WARNING/ERROR", "slds-theme--error", messageText, errorMessage )
                            
                        }
                    }else{
                        //show success
                        helper.showPopup(component, "SUCCESS", "slds-theme--success", messageText )
                    }

                    helper.getExistingRecord(component, event, helper, true);
                    
                    //component.set("v.resultText",'Sucessfully Inserted '+ response.getReturnValue().length+' number of records !' );
                    //helper.toggleSpinnerVisibility(component, event, helper);
                    //component.set("v.dataStatusHeader","Uploaded Data")
                    //component.set("v.listRecordToUpload",uploadedRecords);      
                    component.set("v.dataExists",true);   
                    //helper.calculateData(component, event, helper);       
                }else{
                    console.log('ELSE CONDITONS');
                    helper.hideSpinnerVisibility(component, event, helper);
                    //component.set("v.listRecordToUpload",[]); 
                    //helper.calculateData(component, event, helper);   
                         
                /*} //commented till here by ankita

                /*if(response.getReturnValue().indexOf('Success') > -1 ){
            		console.log(response.getReturnValue().substring(9,10));
            		component.set("v.resultText",'Sucessfully Inserted '+ response.getReturnValue().substring(9)+' number of records !' );
            		helper.toggleSpinnerVisibility(component, event, helper);
                    component.set("v.dataStatusHeader","Uploaded Data")
                }*/
                //commented below by Ankita
            /*}else{
                //TYPE CAST ISSUE
                //THE COLUMNS IN SHEET HAS INCORRCT VALUE TYPE IN ACCORDANCE WITH SALESFORCE.
                //E.G. Number field has text value
                console.log('Failed to Upload Records');
                helper.getExistingRecord(component, event, helper, true);
                helper.showPopup(component, "ERROR", "slds-theme--error","No Records Uploaded!", "Incorrect Data on the Sheet! \nPlease check the currency and quantity columns' values on CSV. \n Also, please check the date format.(Acceptable MM/DD/YYYY).\nDoes the issue still persist? Please contact the System Administrator.")
            	//component.set("v.resultText",'Failed to insert Records' );
            	helper.hideSpinnerVisibility(component, event, helper);
            }
            
            
        });
        $A.enqueueAction(action);
    }, */
    
    showSpinnerVisibility: function(component, event, helper) {
        $A.util.addClass(component.find("spinner_box"), "slds-show");
        $A.util.removeClass(component.find("spinner_box"), "slds-hide");
        
    },
    hideSpinnerVisibility: function(component, event, helper) {
        $A.util.addClass(component.find("spinner_box"), "slds-hide");
        $A.util.removeClass(component.find("spinner_box"), "slds-show");
    },

    getItemPricingReport: function(component, event, helper){
        console.log('I am in getItemPricingReport');
        var contractID = component.get("v.recordId");
        var action = component.get("c.getReportId");
        action.setParams({ 
            contractAgreeId : contractID
        });

        action.setCallback(this, function(response) {
        	var state = response.getState();
        	//console.log('test' +state);
	        if (state === "SUCCESS") {
                console.log('I am in success');
                var reportId = response.getReturnValue().reportId;
                var contractAgreementName = response.getReturnValue().contractAgreementName;
                component.set("v.contractAgreementName",contractAgreementName);
                component.set("v.reportId",reportId);
                
               /* console.log('url for report');
                console.log('/lightning/r/Report/' + reportId + '/view?fv0=' + contractAgreementName);
                var urlEvent = $A.get("e.force:navigateToURL");
                urlEvent.setParams({
                "url": window.open('/lightning/r/Report/' + reportId + '/view?fv0=' + contractAgreementName,'_blank')
                });
                urlEvent.fire(); */

    }
});
    $A.enqueueAction(action);
 }

})