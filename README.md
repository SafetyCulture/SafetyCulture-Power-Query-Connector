# iAuditor Power Query Connector

The iAuditor Power Query Connector provides a data connection for iAuditor in Power BI.

# Getting started
To learn how to install and use this connector please visit our [support page](https://support.safetyculture.com/integrations/power-bi-desktop-pull-data-via-the-iauditor-connector/).

## Sample report
A Power BI report template has been included with [each release](https://github.com/SafetyCulture/iAuditor-Power-Query-Connector/releases). After installing the connector you can download and open this report in Power BI desktop. You will be prompted to enter an API key which you can generate by visiting [API Tokens](https://app.safetyculture.com/account/api-tokens) page in SafetyCulture website.

# Frequently Asked Questions (FAQ)

## What is the purpose of the "Org Name"?
This is the name to distinguish between your organisations locally, should you choose to consume data from multiple organisations inside iAuditor. This information is never transmitted to our servers and is only stored locally on your machine. This name can be anything you want, as long as it is unique.

## Can the data be filtered when loading data for the first time?
Yes, `inspections` and `inspection_items` can be filtered using the provided function `GetInspections` and `GetInspectionItems` respectively. These can be found in the [nav table](./iAuditor.pq#L274-L286)

## What are some best practices to follow when loading data using this connector?
We have a sample report provided which includes a few common use cases of the data present. The report can be found [here](./Sample%20Report.pbit)

## Some tables have no data in them i.e. `schedules`, `schedule_assignees`, `groups` and `group_users`. Is this expected?
`schedule_assignees` may be a result of that organisation not having any schedules. `groups`, `group_users` and `users` will require the Group Management and User Management permissions in order to load. Please refer to the following [support page](https://help.safetyculture.com/en_us/1514571103-SkUXQp9Hv) for more information.

# Development
## Development requirements
- Microsoft Windows
- Microsoft Power BI Desktop
- Microsoft Visual Studio
- [Power Query SDK](https://marketplace.visualstudio.com/items?itemName=Dakahn.PowerQuerySDK)

## Development references
- [Power Query documentation](https://docs.microsoft.com/en-us/power-query/)
- [TripPin Tutorial](https://docs.microsoft.com/en-us/power-query/samples/trippin/readme) is a great starting point to understand how to create a new data source extension for Power Query.

## Testing locally
- Open the project in Visual Studio.
- Build the project.
- Copy `bin\Debug\iAuditor.mez` into `[My Documents]\Power BI Desktop\Custom Connectors` directory. You can use [Auto Deploy](https://marketplace.visualstudio.com/items?itemName=lennyomg.AutoDeploy) Visual Studio Extension to make this step easier.
- Enable the `Custom data connectors` preview feature in Power BI Desktop (under `File > Options and settings > Custom data connectors`).
- Open Power BI Desktop.
- Make sure you enable `Allow any extensions` in the security options of Power BI.
- Select `Get Data > More` to bring up the Get Data dialog.
- Search for iAuditor

# Connector signing
In Power BI, the loading of custom connectors is limited by your choice of security setting.
As a general rule, when the security for loading custom connectors is set to 'Recommended',
the custom connectors won't load at all, and you have to lower it to make them load.
The exception to this is trusted, `signed connectors`. To sign the connector [follow the steps here](https://docs.microsoft.com/en-us/power-query/HandlingConnectorSigning).

# Creating a new release
To release a new version you just need to push a new tag and `GitHub Actions` will do the rest.

1. Checkout the `master` branch and pull the latest changes. If you don't you'll tag the wrong commit for release.
2. Create your tag, make sure it follows correct versioning and increments on the latest release   
`git tag -a v1.0 -m "Initial Public Release"`.  
Acceptable version formats include `v1.0` and `v1.0-beta2`.
3. Push your tag to GitHub using `git push origin v1.0`.
4. Wait for [Github Actions](https://github.com/SafetyCulture/iAuditor-Power-Query-Connector/actions) to finish its work.
4. Update the [release draft](https://github.com/SafetyCulture/iAuditor-Power-Query-Connector/releases) and publish it.
