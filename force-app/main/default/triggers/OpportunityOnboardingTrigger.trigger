trigger OpportunityOnboardingTrigger on Opportunity (after update) {
    OpportunityOnboardingHandler.createOnboardings(Trigger.new, Trigger.oldMap);
}