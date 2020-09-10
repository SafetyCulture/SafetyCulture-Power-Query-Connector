# iAuditor Power Query Connector

The iAuditor Power Query Connector provides a data connection for iAuditor in PowerBI.

# How to install
- Download latest release of iAuditor Signed connector from [releases section](https://github.com/SafetyCulture/iAuditor-Power-Query-Connector/releases).
- Create a `[My Documents]\Power BI Desktop\Custom Connectors` directory.
- Copy the extension file into this directory.
- Download thumbprint of the certificate from releases section.
- Follow the instruction in [Trusted third-party connectors](https://docs.microsoft.com/en-us/power-bi/connect-data/desktop-trusted-third-party-connectors) page.

## Development requirements
- Microsft Windows
- Microsoft Power BI Desktop
- Microsoft Visual Studio
- [Power Query SDK](https://marketplace.visualstudio.com/items?itemName=Dakahn.PowerQuerySDK)

## Development references
- [Power Query documentation](https://docs.microsoft.com/en-us/power-query/)
- [TripPin Tutorial](https://docs.microsoft.com/en-us/power-query/samples/trippin/readme) is a great starting point to understand how to create new data source extension for Power Query.

## Testing locally
- Open the project in Visual Studio.
- Build the project.
- Copy `bin\Debug`iAuditor.mez` into `[My Documents]\Power BI Desktop\Custom Connectors` directory. You can use [Auto Deploy](https://marketplace.visualstudio.com/items?itemName=lennyomg.AutoDeploy) Visual Studio Extension to make this step easier.
- Enable the `Custom data connectors` preview feature in Power BI Desktop (under `File > Options and settings > Custom data connectors`).
- Restart Power BI Desktop.
- Select `Get Data > More` to bring up the Get Data dialog.
- Search for iAuditor

# Connector signing
In Power BI, the loading of custom connectors is limited by your choice of security setting.
As a general rule, when the security for loading custom connectors is set to 'Recommended',
the custom connectors won't load at all, and you have to lower it to make them load.
The exception to this is trusted, `signed connectors`. To sign the connector [follow the steps here](https://docs.microsoft.com/en-us/power-query/HandlingConnectorSigning).
