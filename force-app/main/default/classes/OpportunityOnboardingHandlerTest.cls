@isTest
public class OpportunityOnboardingHandlerTest {

    @isTest
    static void createsOnboardingWhenOpportunityIsWon() {
        Account acc = new Account(Name = 'Test Customer');
        insert acc;

        Date launchDate = Date.today().addDays(30);

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = acc.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10),
            Projected_Launch_Date__c = launchDate
        );
        insert opp;

        Test.startTest();
        opp.StageName = 'Closed Won';
        update opp;
        Test.stopTest();

        List<Onboarding__c> records = [
            select Id, Name, Opportunity__c, Projected_Launch_Date__c,
                   Onboarding_Stage__c
            from Onboarding__c
            where Opportunity__c = :opp.Id
        ];

        System.assertEquals(1, records.size(), 'One onboarding should be created');
        System.assert(records[0].Name.contains('Test Customer'));
        System.assert(records[0].Name.contains(String.valueOf(launchDate)));
        System.assertEquals(launchDate, records[0].Projected_Launch_Date__c);
        System.assertEquals('Kickoff Scheduled', records[0].Onboarding_Stage__c);
    }

    @isTest
    static void doesNotCreateDuplicateWhenOpportunityIsReclosed() {
        Account acc = new Account(Name = 'Duplicate Test Customer');
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Reclose Test',
            AccountId = acc.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10),
            Projected_Launch_Date__c = Date.today().addDays(30)
        );
        insert opp;

        opp.StageName = 'Closed Won';
        update opp;

        opp.StageName = 'Prospecting';
        update opp;

        Test.startTest();
        opp.StageName = 'Closed Won';
        update opp;
        Test.stopTest();

        List<Onboarding__c> records = [
            select Id
            from Onboarding__c
            where Opportunity__c = :opp.Id
        ];

        System.assertEquals(1, records.size(), 'Reclosing must not create a duplicate');
    }

    @isTest
    static void handlesTwoHundredOpportunities() {
        Account acc = new Account(Name = 'Bulk Test Customer');
        insert acc;

        List<Opportunity> opportunities = new List<Opportunity>();

        for (Integer i = 0; i < 200; i++) {
            opportunities.add(new Opportunity(
                Name = 'Bulk Opportunity ' + i,
                AccountId = acc.Id,
                StageName = 'Prospecting',
                CloseDate = Date.today().addDays(10),
                Projected_Launch_Date__c = Date.today().addDays(30)
            ));
        }

        insert opportunities;

        for (Opportunity opp : opportunities) {
            opp.StageName = 'Closed Won';
        }

        Test.startTest();
        update opportunities;
        Test.stopTest();

        Integer onboardingCount = [
            select count()
            from Onboarding__c
            where Opportunity__c in :opportunities
        ];

        System.assertEquals(
            200,
            onboardingCount,
            'Each won Opportunity should have exactly one onboarding'
        );
    }
}