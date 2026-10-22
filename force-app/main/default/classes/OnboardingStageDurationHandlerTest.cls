@IsTest
public class OnboardingStageDurationHandlerTest {

    public static List<Onboarding__c> makeRecords(Integer total) {
        List<Opportunity> opps = new List<Opportunity>();

        for (Integer i = 0; i < total; i++) {
            opps.add(new Opportunity(
                Name = 'Test Opportunity ' + i,
                StageName = 'Prospecting',
                CloseDate = Date.today().addDays(30)
            ));
        }
        insert opps;

        List<Onboarding__c> onboardings = new List<Onboarding__c>();

        for (Integer i = 0; i < total; i++) {
            onboardings.add(new Onboarding__c(
                Name = 'Test Onboarding ' + i,
                Opportunity__c = opps[i].Id,
                Projected_Launch_Date__c = Date.today().addDays(30),
                Onboarding_Stage__c = 'Kickoff Scheduled'
            ));
        }
        insert onboardings;

        return onboardings;
    }

    public static void moveStage(Id recordId, String nextStage, Integer minutesInCurrentStage) {
        update new Onboarding__c(
            Id = recordId,
            Current_Stage_Entered_At__c = System.now().addMinutes(-minutesInCurrentStage)
        );

        update new Onboarding__c(
            Id = recordId,
            Onboarding_Stage__c = nextStage,
            Gathering_Info_Notes__c = 'Gathering info notes',
            Implementation_Notes__c = 'Implementation notes'
        );
    }

    public static Onboarding__c getRecord(Id recordId) {
        return [
            select Onboarding_Stage__c,
                   Current_Stage_Entered_At__c,
                   Kickoff_Scheduled_Duration_Minutes__c,
                   Gathering_Info_Duration_Minutes__c,
                   Implementation_Duration_Minutes__c,
                   QA_Review_Duration_Minutes__c,
                   Go_Live_Duration_Minutes__c,
                   Post_Launch_Review_Duration_Minutes__c
            from Onboarding__c
            where Id = :recordId
        ];
    }

    @IsTest
    static void durationIsAddedWhenStageChanges() {
        Onboarding__c o = makeRecords(1)[0];

        System.assertNotEquals(null, getRecord(o.Id).Current_Stage_Entered_At__c,
            'Stage entry time should be set on insert.');

        Test.startTest();
        moveStage(o.Id, 'Gathering Info', 20);
        Test.stopTest();

        Onboarding__c result = getRecord(o.Id);

        System.assertEquals('Gathering Info', result.Onboarding_Stage__c);
        System.assertEquals(20, result.Kickoff_Scheduled_Duration_Minutes__c,
            'Kickoff duration should equal the minutes spent in the stage.');
        System.assertEquals(null, result.Gathering_Info_Duration_Minutes__c,
            'The new stage should not have a duration yet.');
    }

    @IsTest
    static void everyStageRecordsItsDuration() {
        Onboarding__c o = makeRecords(1)[0];

        Test.startTest();
        moveStage(o.Id, 'Gathering Info', 5);
        moveStage(o.Id, 'Implementation', 10);
        moveStage(o.Id, 'QA / Review', 15);
        moveStage(o.Id, 'Go Live', 20);
        moveStage(o.Id, 'Post-Launch Review', 25);
        moveStage(o.Id, 'Go Live', 30);
        Test.stopTest();

        Onboarding__c result = getRecord(o.Id);

        System.assertEquals('Go Live', result.Onboarding_Stage__c);
        System.assertEquals(5, result.Kickoff_Scheduled_Duration_Minutes__c, 'Kickoff Scheduled duration');
        System.assertEquals(10, result.Gathering_Info_Duration_Minutes__c, 'Gathering Info duration');
        System.assertEquals(15, result.Implementation_Duration_Minutes__c, 'Implementation duration');
        System.assertEquals(20, result.QA_Review_Duration_Minutes__c, 'QA / Review duration');
        System.assertEquals(25, result.Go_Live_Duration_Minutes__c, 'Go Live duration');
        System.assertEquals(30, result.Post_Launch_Review_Duration_Minutes__c, 'Post-Launch Review duration');
    }

    @IsTest
    static void sameStageDoesNotAddDuration() {
        Onboarding__c o = makeRecords(1)[0];

        Test.startTest();
        update new Onboarding__c(
            Id = o.Id,
            Current_Stage_Entered_At__c = System.now().addMinutes(-10),
            Projected_Launch_Date__c = Date.today().addDays(45)
        );
        Test.stopTest();

        Onboarding__c result = getRecord(o.Id);

        System.assertEquals('Kickoff Scheduled', result.Onboarding_Stage__c);
        System.assertEquals(null, result.Kickoff_Scheduled_Duration_Minutes__c,
            'Duration should not change if the stage has not changed.');
    }

    @IsTest
    static void missingStageEntryTimeIsSkipped() {
        Onboarding__c o = makeRecords(1)[0];

        update new Onboarding__c(Id = o.Id, Current_Stage_Entered_At__c = null);

        Test.startTest();
        update new Onboarding__c(Id = o.Id, Onboarding_Stage__c = 'Gathering Info');
        Test.stopTest();

        Onboarding__c result = getRecord(o.Id);

        System.assertEquals('Gathering Info', result.Onboarding_Stage__c);
        System.assertEquals(null, result.Kickoff_Scheduled_Duration_Minutes__c,
            'No duration should be calculated without a stage entry time.');
    }

    @IsTest
    static void futureStageEntryTimeIsSkipped() {
        Onboarding__c o = makeRecords(1)[0];

        update new Onboarding__c(Id = o.Id, Current_Stage_Entered_At__c = System.now().addMinutes(30));

        Test.startTest();
        update new Onboarding__c(Id = o.Id, Onboarding_Stage__c = 'Gathering Info');
        Test.stopTest();

        Onboarding__c result = getRecord(o.Id);

        System.assertEquals('Gathering Info', result.Onboarding_Stage__c);
        System.assertEquals(null, result.Kickoff_Scheduled_Duration_Minutes__c,
            'A negative duration should not be recorded.');
    }

    @IsTest
    static void durationAccumulatesAcrossStageVisits() {
        Onboarding__c o = makeRecords(1)[0];

        Test.startTest();
        moveStage(o.Id, 'Gathering Info', 10);
        moveStage(o.Id, 'Kickoff Scheduled', 5);
        moveStage(o.Id, 'Gathering Info', 7);
        Test.stopTest();

        Onboarding__c result = getRecord(o.Id);

        System.assertEquals('Gathering Info', result.Onboarding_Stage__c);
        System.assertEquals(17, result.Kickoff_Scheduled_Duration_Minutes__c,
            'Kickoff duration should accumulate across both visits (10 + 7).');
        System.assertEquals(5, result.Gathering_Info_Duration_Minutes__c,
            'Gathering Info duration should be recorded for the first visit.');
    }

    @IsTest
    static void handles200RecordsInOneUpdate() {
        List<Onboarding__c> records = makeRecords(200);
        List<Onboarding__c> backdated = new List<Onboarding__c>();
        List<Onboarding__c> updates = new List<Onboarding__c>();

        for (Onboarding__c o : records) {
            backdated.add(new Onboarding__c(
                Id = o.Id,
                Current_Stage_Entered_At__c = System.now().addMinutes(-15)
            ));
            updates.add(new Onboarding__c(
                Id = o.Id,
                Onboarding_Stage__c = 'Gathering Info'
            ));
        }
        update backdated;

        Test.startTest();
        update updates;
        Test.stopTest();

        List<Onboarding__c> results = [
            select Onboarding_Stage__c,
                   Kickoff_Scheduled_Duration_Minutes__c
            from Onboarding__c
            where Id in :records
        ];

        System.assertEquals(200, results.size());

        for (Onboarding__c result : results) {
            System.assertEquals('Gathering Info', result.Onboarding_Stage__c);
            System.assertEquals(15, result.Kickoff_Scheduled_Duration_Minutes__c,
                'Each record should have its Kickoff duration calculated.');
        }
    }
}