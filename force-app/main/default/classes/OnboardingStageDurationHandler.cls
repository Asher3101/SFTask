public class OnboardingStageDurationHandler {
    
    public static void updateDurations(List<Onboarding__c> records, Map<Id, Onboarding__c> oldMap) {
        Datetime nowTime = System.now();

        for (Onboarding__c o : records) {
            Onboarding__c oldO = oldMap.get(o.Id);

            if (o.Onboarding_Stage__c == oldO.Onboarding_Stage__c) {
                continue;
            }

            if (oldO.Current_Stage_Entered_At__c == null) {
                continue;
            }

            Long diff = nowTime.getTime() - oldO.Current_Stage_Entered_At__c.getTime();
            if (diff < 0) continue;

            Decimal mins = Decimal.valueOf(diff) / 60000;
            mins = mins.setScale(0, RoundingMode.DOWN);

            if (oldO.Onboarding_Stage__c == 'Kickoff Scheduled') {
                o.Kickoff_Scheduled_Duration_Minutes__c = (oldO.Kickoff_Scheduled_Duration_Minutes__c == null ? 0 : oldO.Kickoff_Scheduled_Duration_Minutes__c) + mins;
            } else if (oldO.Onboarding_Stage__c == 'Gathering Info') {
                o.Gathering_Info_Duration_Minutes__c = (oldO.Gathering_Info_Duration_Minutes__c == null ? 0 : oldO.Gathering_Info_Duration_Minutes__c) + mins;
            } else if (oldO.Onboarding_Stage__c == 'Implementation') {
                o.Implementation_Duration_Minutes__c = (oldO.Implementation_Duration_Minutes__c == null ? 0 : oldO.Implementation_Duration_Minutes__c) + mins;
            } else if (oldO.Onboarding_Stage__c == 'QA / Review') {
                o.QA_Review_Duration_Minutes__c = (oldO.QA_Review_Duration_Minutes__c == null ? 0 : oldO.QA_Review_Duration_Minutes__c) + mins;
            } else if (oldO.Onboarding_Stage__c == 'Go Live') {
                o.Go_Live_Duration_Minutes__c = (oldO.Go_Live_Duration_Minutes__c == null ? 0 : oldO.Go_Live_Duration_Minutes__c) + mins;
            } else if (oldO.Onboarding_Stage__c == 'Post-Launch Review') {
                o.Post_Launch_Review_Duration_Minutes__c = (oldO.Post_Launch_Review_Duration_Minutes__c == null ? 0 : oldO.Post_Launch_Review_Duration_Minutes__c) + mins;
            }
        }
    }
}