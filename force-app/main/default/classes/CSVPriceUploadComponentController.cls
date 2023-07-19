/**
 *  About
 *  -----
 *  Author: Appluent
 *  Create date: 01 Mar 2021
 *  
 *  Details
 *  -----
 *  
 *  
 *  
 *  Update History
 *  -----
 *  
 *  Issues / TODOs
 *  ----- 
 *
**/
public class CSVPriceUploadComponentController {

    //FOR DELETE LIGHTNING COMPONENT
    
    @AuraEnabled
    public static string deleteExistingRecords(Id contAgreeId) {
        String returnString;
        //Existing record Count 
        Integer totalRowsCount = [SELECT Count() 
                                    FROM  Item_Pricing__c 
                                    WHERE 
                                    Contract_Agreement__c= :contAgreeId
                                    AND To_Be_Deleted__c = true ];
        System.debug('totalRowsCount  : '+totalRowsCount);
        if(totalRowsCount > 0){                       
        //ItemPricingDeleteBatch
            Database.executebatch(new ItemPricingDeleteBatch(contAgreeId), 2000);
            returnString = null;
        }else{
            returnString = 'No Item Pricing Records are marked \'To be Deleted\' ';
            
        }
        System.debug('returnString  : '+returnString);
        return returnString;
        
    }

    @AuraEnabled
    public static existingRecordsResults getExistingRecords(Id contAgreeId) {
        System.debug('getExistingRecords');
        List<Item_Pricing__c> listExistingRecrd = new List<Item_Pricing__c>();
        //listExistingRecrd= getsObjectRecords('0', contAgreeId);
        
        Integer totalRowsCount = [SELECT Count() FROM  Item_Pricing__c WHERE Contract_Agreement__c= :contAgreeId ];
        
        /*[SELECT UNIQUE_KEY__c
                                                    ,Sevaredent_Contract_Number__c
                                                    ,Unique_Key_Formula__c
                                                    ,Contract_Agreement__c
                                                    ,Category_Name__c
                                                    ,Subcategory_Name__c
                                                    ,Vendor_Name__c
                                                    ,Vendor_Part_Number__c
                                                    ,Manufacturer_Name__c
                                                    ,Manufacturer_Part_Number__c
                                                    ,Item_Description__c
                                                    ,UOM__c
                                                    ,Qty_of_EA_p_UOM__c
                                                    ,List_p_UOM__c
                                                    ,Contract_Tier_1_Description__c
                                                    ,Contract_Tier_1_Price_UOM__c
                                                    ,Contract_Tier_2_Description__c
                                                    ,Contract_Tier_2_Price_UOM__c,
                                                    Contract_Tier_4_Price_UOM__c,
                                                    Contract_Tier_4_Description__c,
                                                    Contract_Tier_3_Price_UOM__c,
                                                    Contract_Tier_3_Description__c
                                                    ,Packaging_String__c
                                                    ,Price_End_Date__c
                                                    ,Price_Start_Date__c
                                                    ,URL_to_Item_Specifications__c
                                                    ,Item_Image_Name__c
                                                    ,Comments__c
                                                    FROM Item_Pricing__c
                                                    WHERE Contract_Agreement__c= :contAgreeId 
                                                    ORDER BY lastModifiedDate DESC
                                                   ]; */

        existingRecordsResults returnVariable = new existingRecordsResults();

        returnVariable.totalRows = totalRowsCount;
        
        if(listExistingRecrd !=null && !listExistingRecrd.isEmpty()){
            returnVariable.listExistingPricingItems = listExistingRecrd;
        }else{
            //Test
            //throw New AuraHandledException('Unable to Create Token: ');
            returnVariable.listExistingPricingItems = null;
        }

        //Customer Metadata Type
        List<CSV_to_Salesforce_Field_Map__mdt> listMetadataRecords = [SELECT Active__c,DeveloperName,
                                                    CSV_Field_Name__c,
                                                    Object_API_Name__c,
                                                    Salesforce_Field_Name__c,
                                                    Type__c
                                                    FROM CSV_to_Salesforce_Field_Map__mdt
                                                    WHERE Object_API_Name__c = 'Item_Pricing__c' ORDER BY DeveloperName ASC
                                                ];

        if(!listMetadataRecords.isEmpty()){
            returnVariable.listCustomMetadataRecords = listMetadataRecords;
        }else{
            //Test
            //throw New AuraHandledException('Unable to Create Token: ');
            returnVariable.listCustomMetadataRecords = null;
        }

        return returnVariable;
        
    }

    //List<sObject> sObjectRecords = getsObjectRecords(ObjectName, fieldSet, 50, '', Orderby, OrderDir);

    @AuraEnabled
    public static List<Item_Pricing__c> getsObjectRecords(String OFFSET, String contAgreeId) {
        
        //OrderDir = String.isBlank(OrderDir) ? 'asc' : OrderDir;
        String query = 'SELECT UNIQUE_KEY__c,Sevaredent_Contract_Number__c,Unique_Key_Formula__c,Contract_Agreement__c,Category_Name__c,Subcategory_Name__c,Vendor_Name__c,Vendor_Part_Number__c,Manufacturer_Name__c,Manufacturer_Part_Number__c,Item_Description__c,UOM__c,Qty_of_EA_p_UOM__c,List_p_UOM__c,Contract_Tier_1_Description__c,Contract_Tier_1_Price_UOM__c,Contract_Tier_2_Description__c,Contract_Tier_2_Price_UOM__c,Contract_Tier_4_Price_UOM__c,Contract_Tier_4_Description__c,Contract_Tier_3_Price_UOM__c,Contract_Tier_3_Description__c,Packaging_String__c,Price_End_Date__c,Price_Start_Date__c,URL_to_Item_Specifications__c,Item_Image_Name__c,Comments__c FROM Item_Pricing__c WHERE Contract_Agreement__c= \''+ contAgreeId +'\'';
        
        query += ' ORDER BY lastModifiedDate DESC';
        query += ' LIMIT 10 OFFSET ' + OFFSET;
        
      //  query += ' ORDER BY '+Orderby+' '+OrderDir+' NULLS LAST';
        system.debug(query);
        List<Item_Pricing__c> returnList = Database.query(query);
        if(returnList.size()>0){
            return returnList ;
        }else{
            return null ;
        }
       
    }







    public class existingRecordsResults {
        @AuraEnabled public List<Item_Pricing__c> listExistingPricingItems;
        @AuraEnabled public List<CSV_to_Salesforce_Field_Map__mdt> listCustomMetadataRecords;
        @AuraEnabled public integer totalRows;
    }

    @AuraEnabled
    public static upsertRecordsResults saveCSVFile(List<Item_Pricing__c> listRecordsToinsertTemp,Id contId, String sevContName) {
        System.debug('saveCSVFile : '+ listRecordsToinsertTemp +' : '+sevContName);


        upsertRecordsResults returnValue = new upsertRecordsResults();
        List<Item_Pricing__c> listRecordsInserted = new List<Item_Pricing__c> ();
        List<Item_Pricing__c> listRecordsUpdated = new List<Item_Pricing__c> ();
        //List<Item_Pricing__c> listRecordsFailed = new List<Item_Pricing__c> ();
        Map<String, List<String> > mapRecordsFailed = new Map<String, List<String> >();
        String msg = '';
        


        List<Item_Pricing__c> listRecordsToinsert = new List<Item_Pricing__c>();
        Map<String, Integer> mapUniToRowNum = new Map<String, Integer> ();
        List<Item_Pricing__c> listRecordsToDelete = new List<Item_Pricing__c>();
        
        List<Item_Pricing__c> ListDescriptionValidated = new List<Item_Pricing__c>();

        if(!listRecordsToinsertTemp.isEmpty()){
            //Check if Existing 
            Map<String, Id> mapUKeyToRecord = new Map<String, Id>();
            Set<String> uniqueKeys = new Set<String>();


            for(Integer i = 0, size = listRecordsToinsertTemp.size(); i < size; i++) {
            //for(Item_Pricing__c OneRec :  listRecordsToinsertTemp){
                //if they have same Sevaredent Contract Name
                if(listRecordsToinsertTemp[i].Sevaredent_Contract_Number__c == sevContName){        
                    if(String.isNotBlank(listRecordsToinsertTemp[i].UNIQUE_KEY__c)){
                        uniqueKeys.add(listRecordsToinsertTemp[i].UNIQUE_KEY__c);
                        if(!mapUniToRowNum.containsKey(listRecordsToinsertTemp[i].UNIQUE_KEY__c)){
                        //Add to map
                        mapUniToRowNum.put(listRecordsToinsertTemp[i].UNIQUE_KEY__c, i+2);
                        listRecordsToinsert.add(listRecordsToinsertTemp[i]);
                        }else{
                            Integer existRowNum = mapUniToRowNum.get(listRecordsToinsertTemp[i].UNIQUE_KEY__c);
                            System.debug('existRowNum: '+existRowNum);
                            Integer rowNum = i + 2;
                            system.debug('rowNum: '+rowNum);
                            system.debug('mapRecordsFailed :'+mapRecordsFailed);
                            if(!mapRecordsFailed.containsKey('Duplicate Unique Key : '+listRecordsToinsertTemp[i].UNIQUE_KEY__c +' : row '+ existRowNum+ ' ')){
                                system.debug('I am in first else');
                                mapRecordsFailed.put('Duplicate Unique Key : '+listRecordsToinsertTemp[i].UNIQUE_KEY__c +' : row '+ existRowNum+ ' ', new list<String>{'row '+rowNum + ' '});
                            }else if(mapRecordsFailed.containsKey('Duplicate Unique Key : '+listRecordsToinsertTemp[i].UNIQUE_KEY__c +' : row '+ existRowNum+ ' ')){
                                    system.debug('I am in second else');
                                    mapRecordsFailed.get('Duplicate Unique Key : '+listRecordsToinsertTemp[i].UNIQUE_KEY__c +' : row '+ existRowNum+ ' ').add('row '+rowNum + ' ');
                                }
                         }
                    }else{
                        Integer rowNum = i+2;
                        mapRecordsFailed.put('row '+ rowNum + ' : ', new list<String>{'Missing Unique Key'});
                    }
                }else{
                    Integer rowNum = i+2;
                    mapRecordsFailed.put('row '+ rowNum + ' : ', new list<String>{'Incorrect/Missing Sevaredent Contract Number'});
                    
                }
            }
            //code by Ankita

            System.debug('mapUniToRowNum :'+mapUniToRowNum);

            if(!listRecordsToinsert.isEmpty()){
           String descr1 = listRecordsToinsert[0].Contract_Tier_1_Description__c;
           String descr2 = listRecordsToinsert[0].Contract_Tier_2_Description__c;
           string descr3 = listRecordsToinsert[0].Contract_Tier_3_Description__c;
           String descr4 = listRecordsToinsert[0].Contract_Tier_4_Description__c;
        

           for(Integer i =0; i<listRecordsToinsert.size(); i++){
               system.debug('listRecordsToinsert[i].Contract_Tier_1_Price_UOM__c:'+listRecordsToinsert[i].Contract_Tier_1_Price_UOM__c);
               if((listRecordsToinsert[i].Contract_Tier_1_Description__c == descr1)&&(listRecordsToinsert[i].Contract_Tier_2_Description__c == descr2)&&
               (listRecordsToinsert[i].Contract_Tier_3_Description__c == descr3)&&(listRecordsToinsert[i].Contract_Tier_4_Description__c == descr4)){
                    if((((listRecordsToinsert[i].Contract_Tier_1_Description__c == null) && (listRecordsToinsert[i].Contract_Tier_1_Price_UOM__c == null))||((listRecordsToinsert[i].Contract_Tier_1_Description__c != null)&&(listRecordsToinsert[i].Contract_Tier_1_Price_UOM__c != null)))&&
                    (((listRecordsToinsert[i].Contract_Tier_2_Description__c == null) && (listRecordsToinsert[i].Contract_Tier_2_Price_UOM__c == null))||((listRecordsToinsert[i].Contract_Tier_2_Description__c != null) && (listRecordsToinsert[i].Contract_Tier_2_Price_UOM__c != null)))&&
                    (((listRecordsToinsert[i].Contract_Tier_3_Description__c == null) && (listRecordsToinsert[i].Contract_Tier_3_Price_UOM__c == null))||((listRecordsToinsert[i].Contract_Tier_3_Description__c != null) && (listRecordsToinsert[i].Contract_Tier_3_Price_UOM__c != null)))&&
                    (((listRecordsToinsert[i].Contract_Tier_4_Description__c == null) && (listRecordsToinsert[i].Contract_Tier_4_Price_UOM__c == null))||((listRecordsToinsert[i].Contract_Tier_4_Description__c != null) && (listRecordsToinsert[i].Contract_Tier_4_Price_UOM__c != null)))){
                        if(((listRecordsToinsert[i].Price_Start_Date__c != null && listRecordsToinsert[i].Price_End_Date__c != null )&&(listRecordsToinsert[i].Price_Start_Date__c < listRecordsToinsert[i].Price_End_Date__c))||
                            ((listRecordsToinsert[i].Price_Start_Date__c != null && listRecordsToinsert[i].Price_End_Date__c != null)&&(listRecordsToinsert[i].Price_Start_Date__c == listRecordsToinsert[i].Price_End_Date__c))){
                                if((listRecordsToinsert[i].Item_Description__c != null) && (listRecordsToinsert[i].Qty_of_EA_p_UOM__c != null) && (listRecordsToinsert[i].UOM__c != null) && (listRecordsToinsert[i].Packaging_String__c != null) && (listRecordsToinsert[i].Price_End_Date__c != null)&&
                                    (listRecordsToinsert[i].Manufacturer_Name__c != null)&&(listRecordsToinsert[i].Manufacturer_Part_Number__c != null)&&(listRecordsToinsert[i].Contract_Tier_1_Description__c != null)&&(listRecordsToinsert[i].Contract_Tier_1_Price_UOM__c != null)&&
                                    (listRecordsToinsert[i].Price_Start_Date__c != null)){
                                        
                                        ListDescriptionValidated.add(listRecordsToinsert[i]); 
                                }else{
                                    Integer rowNumber = mapUniToRowNum.get(listRecordsToinsert[i].UNIQUE_KEY__c);
                                    mapRecordsFailed.put('row '+ rowNumber + ' : ', new list<String>{'Item Description, Qty of EA p/UOM, UOM, Packaging string, Price End Date, Price Start Date, Manufacturer Name, Manufacturer Part Number, Contract Tier 1 Description, Contract Tier 1 Price/UOM are required fields.'});
                                }
                        }else{
                            Integer rowNumber = mapUniToRowNum.get(listRecordsToinsert[i].UNIQUE_KEY__c);
                            mapRecordsFailed.put('row '+ rowNumber + ' : ', new list<String>{'Price End date should be greater than Price Start Date'});
                        }
                        
                    }else{
                            Integer rowNumber = mapUniToRowNum.get(listRecordsToinsert[i].UNIQUE_KEY__c);
                            mapRecordsFailed.put('row '+ rowNumber + ' : ', new list<String>{'Contract Tier description and Contract Tier Price UOM both should be filled together or kept blank together'});
                        }
                    }else{
                   Integer rowNumber = mapUniToRowNum.get(listRecordsToinsert[i].UNIQUE_KEY__c);
                   mapRecordsFailed.put('row '+ rowNumber + ' : ', new list<String>{'Contract Tier Descriptions do not match to other Item Pricing records.'});
               }
           }
        }
           // till here

            system.debug('uniqueKeys '+uniqueKeys);
            system.debug('contId '+contId);
            //Check if Records Existin

            List<Item_Pricing__c> allRecordsList = [SELECT Name,UNIQUE_KEY__c,Sevaredent_Contract_Number__c
                                                    FROM Item_Pricing__c 
                                                    WHERE Contract_Agreement__c = :contId 
                                                    ];



            List<Item_Pricing__c> existingRecords = new List<Item_Pricing__c>();
            
            if(!uniqueKeys.isEmpty() && String.isNotBlank(contId)){
                //though unique key is suffient
                for(Item_Pricing__c oneRecord :  allRecordsList ){
                    if(uniqueKeys.contains(oneRecord.UNIQUE_KEY__c)){
                        if( String.isNotBlank(oneRecord.UNIQUE_KEY__c)  ){
                            //for the records to update
                            mapUKeyToRecord.put(oneRecord.UNIQUE_KEY__c, oneRecord.Id);             
                        }
                    }else{
                        //delete the rest of the records
                        listRecordsToDelete.add(oneRecord);
                    }
                }
            }
            system.debug('mapUKeyToRecord '+ mapUKeyToRecord);

            //to set Id fro Upsert
            
            List<Item_Pricing__c> recordsToInsert = new List<Item_Pricing__c>();
            for(Item_Pricing__c OnePR :  listRecordsToinsert){
                if( mapUKeyToRecord.get(OnePR.UNIQUE_KEY__c) != null  ){
                    OnePR.Id = mapUKeyToRecord.get(OnePR.UNIQUE_KEY__c);
                }
            }
            
        }

        //CODE BY ANKITA
         system.debug(mapRecordsFailed);
        system.debug('ListDescriptionValidated: '+ListDescriptionValidated); 
        if(mapRecordsFailed.size() == 0){
            try{
            List<Database.UpsertResult> results =  Database.upsert(ListDescriptionValidated,Item_Pricing__c.UNIQUE_KEY__c,true);
               system.debug('results: '+json.serialize(results));

               for(Integer index = 0, size = results.size(); index < size; index++) {
                if(results[index].isSuccess()) {
                    if(results[index].isCreated()) {
                        System.debug(ListDescriptionValidated[index].Id +' was created');

                        listRecordsInserted.add(ListDescriptionValidated[index]);

                    } else {
                        System.debug(ListDescriptionValidated[index].Id +' was updated');
                        listRecordsUpdated.add(ListDescriptionValidated[index]);

                    }
                }else{
                    List<Database.Error> errors = results[index].getErrors();
                    system.debug('errors: '+errors);
                    List<String> errorsList = new List<String>();
                    for(Database.Error oneErr : errors){
                        system.debug('error : '+oneErr.getMessage());
                        system.debug('Record Id : '+listRecordsToinsert[index].Id);
                        system.debug('oneErr.statuscode: '+oneErr.statuscode);
                        errorsList.add(oneErr.getMessage());
                        system.debug('errorsList: '+errorsList);
                        Integer rownumber = mapUniToRowNum.get(ListDescriptionValidated[index].UNIQUE_KEY__c);
                        mapRecordsFailed.put('row '+ rownumber + ' : ', errorsList);
                    }
                    //system.debug(results[index].getErrors());
                }
            }
        }catch(DmlException e){
            for (Integer i = 0; i < e.getNumDml(); i++) {
                system.debug('The record : '+ListDescriptionValidated[e.getDmlIndex(i)]);
                system.debug('The field causing error : '+e.getDmlFieldNames(i));
                //Get Validation Rule & Trigger Error Messages
                msg =+ e.getDmlMessage(i) + '\n' ;
            }
            system.debug(msg);
            //throw DML exception message
            throw new AuraHandledException(msg);
        }catch(Exception e){
            system.debug(e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }
            system.debug('listRecordsToDelete: '+listRecordsToDelete);
            if(!listRecordsInserted.isEmpty()){
            returnValue.insertedRecords = listRecordsInserted;
            }
            if(!listRecordsUpdated.isEmpty()){
            returnValue.updatedRecords = listRecordsUpdated;
            }
            if(!listRecordsToDelete.isEmpty()){
            returnValue.recordsTodelete = listRecordsToDelete;
            }

            if(!mapRecordsFailed.isEmpty()) {
                //SORTING FAILED MAP
                //now lets put those ranks in a list
                list<String> keyList = new list<String>();
                keyList.addAll(mapRecordsFailed.keySet());
            
                //now sort them
                keyList.sort();
                
                //newSorted
                Map<String, List<String> > mapRecordsFailedSorted = new Map<String, List<String> >();
                
                for(String oneKey : keyList)
                {
                    mapRecordsFailedSorted.put(oneKey, mapRecordsFailed.get(oneKey));
                    
                }   
                returnValue.failedRecords = mapRecordsFailedSorted;
            }
            

            //UPSERT
            //commenting from line 230 to 285
           /* Database.UpsertResult[] results = Database.upsert(listRecordsToinsert,False);
            
            for(Integer index = 0, size = results.size(); index < size; index++) {
                if(results[index].isSuccess()) {
                    if(results[index].isCreated()) {
                        System.debug(listRecordsToinsert[index].Id +' was created');

                        listRecordsInserted.add(listRecordsToinsert[index]);

                    } else {
                        System.debug(listRecordsToinsert[index].Id +' was updated');
                        listRecordsUpdated.add(listRecordsToinsert[index]);

                    }
                }else{
                    List <Database.Error> errors = results[index].getErrors();
                    List<String> errorsList = new List<String>();
                    for(Database.Error oneErr : errors){
                        system.debug('error : '+oneErr.getMessage());
                        system.debug('Record Id : '+listRecordsToinsert[index].Id);
                        errorsList.add(oneErr.getMessage());
                    }
                    //to consider one header CSV
                    Integer rownumber = mapUniToRowNum.get(listRecordsToinsert[index].UNIQUE_KEY__c);
                    mapRecordsFailed.put('row '+ rownumber + ' : ', errorsList);
                        
                }
            }

            if(!listRecordsInserted.isEmpty())
                returnValue.insertedRecords = listRecordsInserted;
            if(!listRecordsUpdated.isEmpty())
                returnValue.updatedRecords = listRecordsUpdated;

            if(!mapRecordsFailed.isEmpty()) {
                //SORTING FAILED MAP
                //now lets put those ranks in a list
                list<String> keyList = new list<String>();
                keyList.addAll(mapRecordsFailed.keySet());
            
                //now sort them
                keyList.sort();
                
                //newSorted
                Map<String, List<String> > mapRecordsFailedSorted = new Map<String, List<String> >();
                
                for(String oneKey : keyList)
                {
                    mapRecordsFailedSorted.put(oneKey, mapRecordsFailed.get(oneKey));
                    
                }   
                returnValue.failedRecords = mapRecordsFailedSorted;
            }

            //delete listRecordsToDelete
            Map<String, List<String> > returnOfDelete = new Map<String, List<String>> (); */

           /* Database.DeleteResult[] drList = Database.delete(listRecordsToDelete, false);
            List<String> deleteRecordsName = new List<String>();
            //for(Database.DeleteResult dr : drList) {
            for(Integer index = 0, size = drList.size(); index < size; index++) {                
                if (drList[index].isSuccess()) {
                    // Operation was successful, so get the ID of the record that was processed
                    System.debug('Successfully deleted account with ID: ' + drList[index].getId());
                    deleteRecordsName.add(listRecordsToDelete[index].Name);
                }
                else {
                    // Operation failed, so get all errors                
                    List<string> delErrors = new List<string> ();
                    for(Database.Error err : drList[index].getErrors()) {
                        delErrors.add( err.getStatusCode() + ': ' + err.getMessage() )  ;           
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        
                    }
                    returnOfDelete.put(listRecordsToDelete[index].Name, delErrors);
                }
            }

            
            //returnOfDelete.put('success',deleteRecordsName);
            
            if(!returnOfDelete.isEmpty()){
                returnValue.deletedRecords = returnOfDelete;
            }*/
       // }
        
        
        //Delete Existing Records
       /* List<CBC__c> listExistingRecrd = [SELECT Id FROM CBC__c WHERE Credential__c= :credId];
        if(!listExistingRecrd.isEmpty()){
            Delete listExistingRecrd;
        }
        
        if(!listRecordsToinsert.isEmpty()){
            System.debug('CBC. to insert : '+ listRecordsToinsert[0].Id);
            if(listRecordsToinsert[0].Id == null){   
                insert listRecordsToinsert;
            }
        }
        

        List<CBC__c> listUploadedRecord = getExistingRecords(credId);
        return listUploadedRecord;*/

        system.debug('returnValue: '+returnValue);
        return returnValue;
    }

    @AuraEnabled
    public static Integer deleteItemPricingRecords(List<Item_Pricing__c> recordsToDelete){
                Integer y =0;
                Integer x = 0;
        try {

            if(!recordsToDelete.isEmpty()){
           List<Database.DeleteResult> res = Database.delete(recordsToDelete, true) ;
                
                for(Integer i=0; i<res.size(); i++){
                  if(res[i].isSuccess()){
                    y=y+1;
                  } else{
                      x=x+1;
                  }
                }

            }
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return y;
    }

    @AuraEnabled
    public static reportRequirement getReportId(Id contractAgreeId){
        try {
             String ItemPricingReport = System.Label.Item_Pricing_Report;
            
            List <Report> reportList = [SELECT Id, Name, DeveloperName FROM Report where 
                                            Name=:ItemPricingReport];
            String reportId = (String)reportList.get(0).Id; 
            system.debug('reportId: '+reportId);
            
            APXT_Redlining__Contract_Agreement__c conAgreement = [Select Id, Name from APXT_Redlining__Contract_Agreement__c 
                                                                        where ID=:contractAgreeId LIMIT 1];
            
            reportRequirement returnResult = new reportRequirement();
            
            if(reportId != null){
                returnResult.reportId = reportId;
            }
            if(conAgreement != null){
                returnResult.contractAgreementName = conAgreement.Name;
            }

            return returnResult;

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        } 

    }


    public class reportRequirement{
        @AuraEnabled public String reportId;
        @AuraEnabled public String contractAgreementName;
    }

    public class upsertRecordsResults {
        @AuraEnabled public List<Item_Pricing__c> insertedRecords;
        @AuraEnabled public List<Item_Pricing__c> updatedRecords;
        @AuraEnabled public List<Item_Pricing__c> recordsTodelete;
        @AuraEnabled public Map<String, List<String> > failedRecords;
        @AuraEnabled public Map<String, List<String> > deletedRecords;
        //@AuraEnabled public List<Database.Error> listErrors;
       // @AuraEnabled public List<Id> listInsertedRecordIds;
       // @AuraEnabled public List<Id> listUpdatedRecordIds;
        //@AuraEnabled public Boolean booleanValue;
       // @AuraEnabled public List<Database.SaveResult> srList;
        
    }

}