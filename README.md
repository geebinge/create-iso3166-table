# Introduction

This scrips load a iso 3166 table into a Azure Storage table. The primary reason is to map countries to a Azure Region. This repository works for Ubuntu 20.04 LTS

## Repository structure


| Folder   | Description                |
| ---------- | ---------------------------- |
| `scipts` | contains the bash script's |

The following schema provides an overview of the high level folder structure for the TMS-IOT solution.

## Installation

if azure cli is not installed use

```
sudo curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bashgit clone https://github.com/geebinge/create-iso3166-table
```

to install the sccipts use

```
git clone https://github.com/geebinge/create-iso3166-table
cd ./create-iso3166-table/scripts
chmod 775 load_iso3166.sh
```

Download from https://unstats.un.org/unsd/methodology/m49/overview/ the CSV verison and
adopt the ${ISO3166_File} and all other varibles in ./create-iso3166-table/scripts/iso3166.inc

```
`./load_iso3166.sh`
```

After you start the scropt you will get asked to use a web browser to open the page https://microsoft.com/devicelogin and enter the code you get asked to authenticate.
