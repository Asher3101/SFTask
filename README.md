# Revinfinity | Onboarding Tracker

## Overview

This project manages customer onboarding in Salesforce after an Opportunity is marked Closed Won. It creates an onboarding record, assigns it to a Customer Success Manager (CSM) based on workload and capacity, and tracks progress through the onboarding stages.

## Features

- Creates an Onboarding record when an Opportunity moves to Closed Won.
- Prevents duplicate onboarding records when an Opportunity is closed again.
- Tracks progress through six onboarding stages.
- Prevents users from skipping stages when moving forward.
- Requires notes before moving beyond Gathering Info and Implementation.
- Records the first time each stage is entered.
- Tracks the total time spent in each stage, including when a record returns to a previous stage.
- Assigns onboardings to eligible CSMs based on active workload and capacity.
- Places onboardings in Team Backlog when no eligible CSM has available capacity.
- Provides stage-duration fields for Salesforce reporting.

## Onboarding Stages

The onboarding process follows these six stages:

1. Kickoff Scheduled
2. Gathering Info
3. Implementation
4. QA / Review
5. Go Live
6. Post-Launch Review

Users can move backward to a previous stage when necessary, but they cannot skip stages while moving forward. Notes are required before progressing beyond Gathering Info and Implementation.

## Main Components

### Onboarding (`Onboarding__c`)

Stores the related Opportunity, projected launch date, current stage, assigned CSM, required notes, stage-entry timestamps, and accumulated stage-duration values.

### CSM Capacity (`CSM_Capacity__c`)

Stores CSM assignment settings, including the Salesforce user, eligibility, and maximum number of active onboardings. These records are maintained through Salesforce.

At least one eligible CSM Capacity record must exist for automatic assignment. If no eligible CSM has available capacity, the onboarding is placed in Team Backlog.

### Opportunity Automation

When an Opportunity changes to Closed Won, Apex checks whether an Onboarding record already exists. If no record exists, it creates one, uses the customer or Opportunity name in the onboarding name, and copies the projected launch date.

### Stage Tracking

Salesforce Flows validate stage progression and maintain stage-entry timestamps. Apex accumulates the time spent in the stage being left when an onboarding changes stages.

The first-entry timestamp for each stage remains unchanged when the onboarding returns to that stage.

### Team Backlog

The Team Backlog list view displays onboardings that could not be assigned because no eligible CSM had available capacity.

The project also includes an email notification Flow and Email Alert intended to notify CS Management when an onboarding enters the backlog. Email delivery must be verified in the target org.

## Setup and Deployment

### Requirements

- Salesforce CLI
- Visual Studio Code with Salesforce Extension Pack
- Access to a Salesforce org with permission to deploy metadata and configure the application

### Authorize Your Salesforce Org

```bash
sf org login web
```

### Deploy the Project

Run the following command from the project root:

```bash
sf project deploy start --source-dir force-app/main/default
```

To deploy to a specific org, provide its alias:

```bash
sf project deploy start --source-dir force-app/main/default --target-org YOUR_ORG_ALIAS
```

Replace `YOUR_ORG_ALIAS` with your authorized Salesforce org alias.

### Post-Deployment Configuration

1. Confirm that the objects, fields, Apex classes, triggers, Flows, and report metadata are deployed.
2. Activate the required Flows.
3. Create CSM Capacity records and configure each CSM's eligibility and maximum capacity.
4. Confirm that the CS Management public group and Team Backlog list view are configured.
5. Verify the Email Alert, its recipients, and email delivery.
6. Confirm that the report type and stage-duration report are available.
7. Confirm that the Lightning app is named `Revinfinity | Onboarding Tracker`.

## Running Tests

Run the Opportunity creation and CSM assignment test classes with:

```bash
sf apex run test --tests OpportunityOnboardingHandlerTest OnboardingAssignmentHandlerTest --result-format human --wait 10
```

During development, these two test classes completed with eight passing tests and no failures or skipped tests.

Stage validation, timestamp behavior, duration accumulation, capacity handling, backlog routing, and email notification delivery should also be verified in the target Salesforce org.

## Reporting

The following fields store accumulated time in each onboarding stage, in minutes:

- `Kickoff_Scheduled_Duration_Minutes__c`
- `Gathering_Info_Duration_Minutes__c`
- `Implementation_Duration_Minutes__c`
- `QA_Review_Duration_Minutes__c`
- `Go_Live_Duration_Minutes__c`
- `Post_Launch_Review_Duration_Minutes__c`

These fields can be included in Salesforce reports to review onboarding duration by stage.

## Project Structure

Salesforce metadata is stored under `force-app/main/default`, organized into folders such as Apex classes, Flows, objects, reports, and triggers. The `sfdx-project.json` file contains the Salesforce DX project configuration.

## Before Handover

Before submitting the project:

- Verify the email notification works in the target org.
- Confirm the stage-duration report is available and displays the expected fields.
- Run the Apex tests and complete the manual end-to-end checks.
- Complete the architecture document and demo recording.
- Confirm that the final project files are committed and pushed to the GitHub repository.