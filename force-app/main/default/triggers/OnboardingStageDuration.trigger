trigger OnboardingStageDuration on Onboarding__c (before insert, before update) {
    if (Trigger.isBefore && Trigger.isInsert) {
        OnboardingAssignmentHandler.assignOnboardings(Trigger.new);
    }

    if (Trigger.isBefore && Trigger.isUpdate) {
        OnboardingStageDurationHandler.updateDurations(Trigger.new, Trigger.oldMap);
    }
}