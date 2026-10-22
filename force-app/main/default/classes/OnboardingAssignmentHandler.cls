public class OnboardingAssignmentHandler {

    public static void assignOnboardings(List<Onboarding__c> records) {
        List<CSM_Capacity__c> csmList = [
            select Id, CSM_User__c, Maximum_Active_Onboardings__c
            from CSM_Capacity__c
            where Eligible_for_Assignment__c = true
            and CSM_User__c != null
            for update
        ];

        Set<Id> csmIds = new Set<Id>();
        Map<Id, Integer> maxCapacity = new Map<Id, Integer>();
        Map<Id, Integer> activeCount = new Map<Id, Integer>();

        for (CSM_Capacity__c c : csmList) {
            csmIds.add(c.CSM_User__c);
            maxCapacity.put(
                c.CSM_User__c,
                c.Maximum_Active_Onboardings__c == null
                    ? 0
                    : c.Maximum_Active_Onboardings__c.intValue()
            );
            activeCount.put(c.CSM_User__c, 0);
        }

        if (csmIds.isEmpty()) {
            for (Onboarding__c o : records) {
                o.Assignment_Status__c = 'Team Backlog';
            }
            return;
        }

        for (AggregateResult ar : [
            select Assigned_CSM__c assignedUser, count(Id) total
            from Onboarding__c
            where Assigned_CSM__c in :csmIds
            and Onboarding_Stage__c != 'Post-Launch Review'
            group by Assigned_CSM__c
        ]) {
            activeCount.put(
                (Id) ar.get('assignedUser'),
                (Integer) ar.get('total')
            );
        }

        for (Onboarding__c o : records) {
            Id selectedUserId;
            Integer lowestCount;

            for (Id userId : csmIds) {
                Integer countNow = activeCount.get(userId);
                Integer capacity = maxCapacity.get(userId);

                if (countNow >= capacity) {
                    continue;
                }

                if (selectedUserId == null || countNow < lowestCount) {
                    selectedUserId = userId;
                    lowestCount = countNow;
                }
            }

            if (selectedUserId == null) {
                o.Assignment_Status__c = 'Team Backlog';
            } else {
                o.Assigned_CSM__c = selectedUserId;
                o.Assignment_Status__c = 'Assigned';
                activeCount.put(selectedUserId, activeCount.get(selectedUserId) + 1);
            }
        }
    }
}