@isTest
public class OnboardingAssignmentHandlerTest {

    @testSetup
    static void setupData() {
        User csm = [
            select Id
            from User
            where Id = :UserInfo.getUserId()
        ];

        insert new CSM_Capacity__c(
            Name = 'Test CSM',
            CSM_User__c = csm.Id,
            Eligible_for_Assignment__c = true,
            Maximum_Active_Onboardings__c = 2
        );
    }

    @isTest
    static void assignsOnboardingToAvailableCSM() {
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert opp;

        Onboarding__c onboarding = new Onboarding__c(
            Name = 'Test Onboarding',
            Opportunity__c = opp.Id,
            Onboarding_Stage__c = 'Kickoff Scheduled'
        );

        Test.startTest();
        insert onboarding;
        Test.stopTest();

        Onboarding__c savedRecord = [
            select Assigned_CSM__c, Assignment_Status__c
            from Onboarding__c
            where Id = :onboarding.Id
        ];

        System.assertEquals(UserInfo.getUserId(), savedRecord.Assigned_CSM__c);
        System.assertEquals('Assigned', savedRecord.Assignment_Status__c);
    }

    @isTest
    static void sendsOnboardingToBacklogWhenCapacityIsFull() {
        Opportunity opp1 = new Opportunity(
            Name = 'Opportunity One',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        Opportunity opp2 = new Opportunity(
            Name = 'Opportunity Two',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        Opportunity opp3 = new Opportunity(
            Name = 'Opportunity Three',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert new List<Opportunity>{opp1, opp2, opp3};

        List<Onboarding__c> onboardings = new List<Onboarding__c>{
            new Onboarding__c(
                Name = 'Onboarding One',
                Opportunity__c = opp1.Id,
                Onboarding_Stage__c = 'Kickoff Scheduled'
            ),
            new Onboarding__c(
                Name = 'Onboarding Two',
                Opportunity__c = opp2.Id,
                Onboarding_Stage__c = 'Kickoff Scheduled'
            ),
            new Onboarding__c(
                Name = 'Onboarding Three',
                Opportunity__c = opp3.Id,
                Onboarding_Stage__c = 'Kickoff Scheduled'
            )
        };

        Test.startTest();
        insert onboardings;
        Test.stopTest();

        List<Onboarding__c> savedRecords = [
            select Assigned_CSM__c, Assignment_Status__c
            from Onboarding__c
            where Id in :onboardings
        ];

        Integer assignedCount = 0;
        Integer backlogCount = 0;

        for (Onboarding__c record : savedRecords) {
            if (record.Assignment_Status__c == 'Assigned') {
                assignedCount++;
            } else if (record.Assignment_Status__c == 'Team Backlog') {
                backlogCount++;
            }
        }

        System.assertEquals(2, assignedCount, 'Only two onboardings should be assigned.');
        System.assertEquals(1, backlogCount, 'The extra onboarding should go to the backlog.');
    }

    @isTest
    static void handlesTwoHundredOnboardings() {
        List<Opportunity> opportunities = new List<Opportunity>();

        for (Integer i = 0; i < 200; i++) {
            opportunities.add(new Opportunity(
                Name = 'Bulk Opportunity ' + i,
                StageName = 'Prospecting',
                CloseDate = Date.today().addDays(30)
            ));
        }
        insert opportunities;

        List<Onboarding__c> onboardings = new List<Onboarding__c>();

        for (Integer i = 0; i < opportunities.size(); i++) {
            onboardings.add(new Onboarding__c(
                Name = 'Bulk Onboarding ' + i,
                Opportunity__c = opportunities[i].Id,
                Onboarding_Stage__c = 'Kickoff Scheduled'
            ));
        }

        Test.startTest();
        insert onboardings;
        Test.stopTest();

        System.assertEquals(
            200,
            [select count() from Onboarding__c where Opportunity__c in :opportunities],
            'All 200 onboarding records should be inserted.'
        );

        System.assertEquals(
            2,
            [select count() from Onboarding__c
             where Opportunity__c in :opportunities
             and Assignment_Status__c = 'Assigned'],
            'Only the two available CSM capacity slots should be used.'
        );
    }
    
    
    @isTest
   static void sendsToBacklogWhenNoCSMIsEligible() {
    delete [
        select Id
        from CSM_Capacity__c
    ];

    Opportunity opp = new Opportunity(
        Name = 'Backlog Test',
        StageName = 'Prospecting',
        CloseDate = Date.today().addDays(30)
    );
    insert opp;

    Onboarding__c onboarding = new Onboarding__c(
        Name = 'Backlog Onboarding',
        Opportunity__c = opp.Id,
        Onboarding_Stage__c = 'Kickoff Scheduled'
    );

    Test.startTest();
    insert onboarding;
    Test.stopTest();

    Onboarding__c savedRecord = [
        select Assignment_Status__c, Assigned_CSM__c
        from Onboarding__c
        where Id = :onboarding.Id
    ];

    System.assertEquals('Team Backlog', savedRecord.Assignment_Status__c);
    System.assertEquals(null, savedRecord.Assigned_CSM__c);
}
}