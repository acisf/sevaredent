/**
 * Created by cshah on Oct 29, 2020.
 */

public without sharing class ContractAmendmentScheduler implements Schedulable {

    public void execute(SchedulableContext schedulableContext) {
        Database.executeBatch(new ContractAmendmentBatch());
    }
}