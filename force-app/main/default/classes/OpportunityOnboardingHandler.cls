public class OpportunityOnboardingHandler {

    public static void createOnboardings(List<Opportunity> newRecords, Map<Id, Opportunity> oldMap) {
        List<Onboarding__c> onboardings = new List<Onboarding__c>();
        Set<Id> opportunityIds = new Set<Id>();
        Set<Id> accountIds = new Set<Id>();

        for (Opportunity opp : newRecords) {
            Opportunity oldOpp = oldMap.get(opp.Id);

            if (opp.IsWon && !oldOpp.IsWon) {
                opportunityIds.add(opp.Id);

                if (opp.AccountId != null) {
                    accountIds.add(opp.AccountId);
                }
            }
        }

        if (opportunityIds.isEmpty()) {
            return;
        }

        Map<Id, Account> accounts = new Map<Id, Account>([
            select Id, Name
            from Account
            where Id in :accountIds
        ]);

        Set<Id> existingOpportunityIds = new Set<Id>();

        for (Onboarding__c o : [
            select Opportunity__c
            from Onboarding__c
            where Opportunity__c in :opportunityIds
        ]) {
            existingOpportunityIds.add(o.Opportunity__c);
        }

        for (Opportunity opp : newRecords) {
            if (!opportunityIds.contains(opp.Id) ||
                existingOpportunityIds.contains(opp.Id)) {
                continue;
            }

            String customerName = opp.Name;

            if (opp.AccountId != null && accounts.containsKey(opp.AccountId)) {
                customerName = accounts.get(opp.AccountId).Name;
            }

            String launchDateText = opp.Projected_Launch_Date__c == null
                ? 'TBD'
                : String.valueOf(opp.Projected_Launch_Date__c);

            onboardings.add(new Onboarding__c(
                Name = 'Onboarding - ' + customerName + ' - ' + launchDateText,
                Opportunity__c = opp.Id,
                Projected_Launch_Date__c = opp.Projected_Launch_Date__c,
                Onboarding_Stage__c = 'Kickoff Scheduled'
            ));
        }

        if (!onboardings.isEmpty()) {
            insert onboardings;
        }
    }
}