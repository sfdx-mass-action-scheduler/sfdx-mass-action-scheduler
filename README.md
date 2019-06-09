<!-- SHIELDS -->
<div align="center">
    
  [![Latest Version][version-shield]][version-url]
  [![Salesforce Community Support][community-shield]][community-url]
  [![Sponsor][sponsor-shield]][sponsor-url]
  [![License][license-shield]][license-url]
  
</div>

<!-- PROJECT LOGO -->
<p align="center">
  <a href="https://github.com/douglascayers-org/sfdx-mass-action-scheduler/">
    <img src="images/mas-logo.png" alt="Mass Action Scheduler Logo" border="0" />
  </a>
  <br />
  Declaratively schedule process automation from reports and list views!
  <br />
  <a href="https://github.com/douglascayers-org/sfdx-mass-action-scheduler/wiki"><strong>Explore the docs »</strong></a>
  <br />
  <br />
  <a href="https://github.com/douglascayers-org/sfdx-mass-action-scheduler/wiki/Examples">View Examples</a>
  ·
  <a href="https://github.com/douglascayers-org/sfdx-mass-action-scheduler/issues">Report Bug</a>
  ·
  <a href="https://github.com/douglascayers-org/sfdx-mass-action-scheduler/issues">Request Feature</a>
</p>

## 📝 Table of Contents

* [About the Project](#-about-the-project)
* [Features](#-features)
* [Roadmap](#-roadmap)
* [Documentation and Discussion](#-documentation-and--discussion)
* [Getting Started](#-getting-started)
  - [Prerequisites](#-prerequisites)
  - [Install Package](#-install-package)
  - [Install Source Code](#-install-source-code)
* [Sponsoring](#-sponsoring)
* [Contributing](#-contributing)
* [Acknowledgements](#-acknowledgements)
* [License](#-license)

<br />

## 🧐 About the Project

Put the power of [Batch Apex](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_batch.htm) within reach of [declarative configuration](https://help.salesforce.com/articleView?id=extend_click_intro.htm&type=5). Declaratively schedule Process Builder, Flows, Quick Actions, Email Alerts, Workflow Rules, or Apex to process records from Reports, List Views, SOQL, or Apex.

Inspired by Marie Chandra's idea [Ability to Schedule when Process Builder Triggers](https://success.salesforce.com/ideaView?id=08730000000DjEmAAK).

Inspired by Narender Singh's idea [Ability to schedule flows, workflows and processes in process builder](https://success.salesforce.com/ideaView?id=0873A000000EA71QAG).

No more waiting for records to be updated or creating clever workarounds to cause records to be updated to cause these actions to fire.

<br />

## 🦄 Features

🙌 **Declarative** - no code necessary, never write Batch Apex again for queries that can be expressed in a report or list view and actions that can be expressed with a declarative alternative.

☁️ **On Platform** - everything happens in Salesforce so no exporting or uploading data necessary.

⏰ **Timely** - run actions manually or schedule hourly, daily, weekly, or any time in between.

<br />

## 🗺 Roadmap

See the [open issues](https://github.com/douglascayers-org/sfdx-mass-action-scheduler/issues) for a list of proposed features (and known issues).

<br />

## 📘 Documentation and 💬 Discussion

* For discussion and feedback [post in the community group](https://success.salesforce.com/_ui/core/chatter/groups/GroupProfilePage?g=0F93A000000LhvN) or raise well defined issues and ideas via the [issue tracker](https://github.com/douglascayers/sfdx-mass-action-scheduler/issues).
* Read the [wiki page](https://github.com/douglascayers-org/sfdx-mass-action-scheduler/wiki) for further documentation on Mass Action Scheduler.
* Read the [FAQ page](https://github.com/douglascayers-org/sfdx-mass-action-scheduler/wiki/Frequently-Asked-Questions) to help troubleshoot technical issues.

<br />

## 👋 Getting Started

### 🚨 Prerequisites

There are a few items you need to setup before installing and using this app.

1. You will need to [Enable Lightning Experience](https://github.com/douglascayers-org/sfdx-mass-action-scheduler/wiki/Pre-Requisites-Instructions#1-enable-lightning-experience) because we are using Lightning Components.
2. You will need to [Enable My Domain](https://github.com/douglascayers-org/sfdx-mass-action-scheduler/wiki/Pre-Requisites-Instructions#2-enable-my-domain) because we are using Lightning Components.
3. You will need to [Allow IFraming of Visualforce Pages with Clickjack Protection](https://github.com/douglascayers-org/sfdx-mass-action-scheduler/wiki/Pre-Requisites-Instructions#3-allow-iframing-of-visualforce-pages-with-clickjack-protection) because we iframe pages in Lightning Components.

Please see the [instructions in the wiki](https://github.com/douglascayers-org/sfdx-mass-action-scheduler/wiki/Pre-Requisites-Instructions) for screen shots and step-by-steps.

### 📦 Install Package

_Due to Lightning Experience web page caching, please log out and log back in after installing the package for UI changes to appear._

* Install Managed Package
    * Browser Links ([Production](https://login.salesforce.com/packaging/installPackage.apexp?p0=04tf4000004MdAC)) ([Sandbox](https://test.salesforce.com/packaging/installPackage.apexp?p0=04tf4000004MdAC))
    * Salesforce CLI (`sfdx force:package:install --package 04tf4000004MdAC --wait 10`)
* Assign the **Mass Action Admin** permission set to users who will configure mass actions.
* [Release Notes](https://github.com/douglascayers-org/sfdx-mass-action-scheduler/wiki/Release-Notes)
* [Closed Issues](https://github.com/douglascayers-org/sfdx-mass-action-scheduler/milestone/7?closed=1)
* [Archived Releases](https://github.com/douglascayers-org/sfdx-mass-action-scheduler/milestones?state=closed)

---

### 🛠 Install Source Code

⚠️ For general use of Mass Action Scheduler you don't need to deploy the source code. I recommend that you install the managed package instead as it's easy, simple, and you don't have to worry about Apex test coverage on deployment.

For developers wanting to 🔍 explore or 💻 make changes to the code, keep reading.

This repository is organized using [Salesforce DX](https://trailhead.salesforce.com/en/trails/sfdx_get_started).
You may install the source code from GitHub and make any desired adjustments.
You are responsible for ensuring unit tests meet your org's validation rules and other requirements.

First, clone the repository.

```
git clone https://github.com/douglascayers-org/sfdx-mass-action-scheduler.git
```

Change directory into the project folder.

```
cd sfdx-mass-action-scheduler
```

Create a new scratch org.

```
sfdx force:org:create -a mas -s -f config/project-scratch-def.json
```

Push the source metadata into your scratch org.

```
sfdx force:source:push
```

Assign the permission set to your user. 

```
sfdx force:user:permset:assign -n Mass_Action_Admin
```

Create a test account, only required for the report tests.

```
sfdx force:data:record:create --sobjecttype Account --values "Name='dca_mass_action: MA Test Account'"
``` 

Run unit tests.

```
sfdx force:apex:test:run --codecoverage --resultformat human --wait 10
```

Open the scratch org and enjoy!

```
sfdx force:org:open --path //lightning/o/Mass_Action_Configuration__c/list
```

<br />

## 💎 Sponsoring

Mass Action Scheduler is a free and independently developed passion project of mine ([Doug Ayers](https://douglascayers.com)).

If your business has found value in my open source projects, please consider showing your support:
  * ⭐️ Star this project on GitHub
  * Contribute a ☕️ or 🌮 via my [virtual tip jar on PayPal](https://www.paypal.me/douglascayers/)

Thank you! ❤️

https://douglascayers.com/thanks-for-your-support/

<br />

## 🙏 Contributing

Contributions are what make the open source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

Please see the [guidelines for contributing](CONTRIBUTING.md) for more details.

For documentation contributions (the [wiki](https://github.com/douglascayers-org/sfdx-mass-action-scheduler/wiki)), please [open an issue](https://github.com/douglascayers-org/sfdx-mass-action-scheduler/issues) with your suggested changes.

For code contributions, please follow the [GitHub flow](https://help.github.com/en/articles/github-flow):
1. Fork this project.
2. Create your feature branch (`git checkout -b feature/AmazingFeature`).
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`).
4. Push to your feature branch (`git push origin feature/AmazingFeature`).
5. Open a pull request.

<br />

## ✍️ Authors

* [Doug Ayers](https://douglascayers.com) develops and maintains the project.

See also the list of [contributors](https://github.com/douglascayers-org/sfdx-mass-action-scheduler/contributors) who participated in this project.

## 🎉 Acknowledgements

* [Appiphony](http://www.lightningstrike.io) for developing the Strike Wizard component based on Lightning Design System [Path blueprint](https://www.lightningdesignsystem.com/components/path/).
* [Salesforce Foundation](https://github.com/SalesforceFoundation/CampaignTools) for developing tools for querying Salesforce Reports API in Apex.
* [Shinichi Tomita](https://twitter.com/stomita) for developing [jsforce](https://jsforce.github.io/) and [soql-parse](https://github.com/stomita/soql-parse) libraries for easy use of Salesforce REST APIs in JavaScript.
* [jQuery](https://jquery.com/) for developing jQuery library.
* [Aaron Hardy](https://twitter.com/aaronius) for developing [Penpal](https://github.com/Aaronius/penpal), a promise-based library for securely communicating with iframes via postMessage.

<br />

## 👀 License

The source code is licensed under the [BSD 3-Clause License](LICENSE).

<!-- MARKDOWN LINKS & IMAGES -->

[version-shield]: https://img.shields.io/github/tag/douglascayers-org/sfdx-mass-action-scheduler.svg?label=release&color=green
[version-url]: https://github.com/douglascayers-org/sfdx-mass-action-scheduler/wiki/Release-Notes

[license-shield]: https://img.shields.io/github/license/douglascayers-org/sfdx-mass-action-scheduler.svg?label=license&color=green
[license-url]: LICENSE

[community-shield]: https://img.shields.io/badge/-Join_our_Community-blue.svg?logo=salesforce&logoColor=white
[community-url]: https://success.salesforce.com/_ui/core/chatter/groups/GroupProfilePage?g=0F93A000000LhvN

<!-- https://stackoverflow.com/questions/42679712/why-does-the-red-heart-emoji-require-two-code-points-but-the-other-colored-hear -->
[sponsor-shield]: https://img.shields.io/badge/-💜_Sponsor_this_project-ff69b4.svg
[sponsor-url]: https://www.paypal.me/douglascayers/
