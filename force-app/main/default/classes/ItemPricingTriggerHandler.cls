/**
 * Handler for Item Pricing trigger. Provides functionality for 
 * sharing Item Pricing object records to certain community members. 
 * Functions of this handler does not contain logic itself, but calls 
 * methods from other classes.
 */ 
public with sharing class ItemPricingTriggerHandler {

    /**
     * Called from trigger when Item Pricing is created. Delegates 
     * work to the ItemPricingSharing class.
     * @param  newPricings the list of new Item Pricing objects
     */ 
    public static void shareItems(List<Item_Pricing__c> newPricings) {
        ItemPricingSharing.shareOnCreate(newPricings);
    }

    /**
     * Called from trigger when Item Pricing is updated. Delegates 
     * work to the ItemPricingSharing class.
     * @param  oldPricings the map of Item Pricing objects before update
     * @param newPricings     	the map of Item Pricing objects after update
     */ 
    public static void shareItems(
        Map<Id, Item_Pricing__c> oldPricings,
        Map<Id, Item_Pricing__c> newPricings
    ) {
        ItemPricingSharing.shareOnUpdate(oldPricings, newPricings);
    }
}