Systran Language Translation
====================

![Last tested in Nuix 9.4](https://img.shields.io/badge/Nuix-9.4-green.svg)

View the GitHub project [here](https://github.com/Nuix/Systran-Language-Translation) or download the latest release [here](https://github.com/Nuix/Systran-Language-Translation/releases).

## Overview
A script which integrates with Systran, providing a way to translate text of items in a Nuix case

## Setup

Begin by downloading the latest release.  Extract the contents of the archive into your Nuix scripts directory.  In Windows the script directory is likely going to be either of the following:

- `%appdata%\Nuix\Scripts` - User level script directory
- `%programdata%\Nuix\Scripts` - System level script directory

## Instructions

1. Select some items OR run across all items in a case by selecting no items.
2. Run the script 
3. Input your systran url, default will be the online portal
4. Input your api key. Contact Systran to gain access to one of these
5. Select a source language * See below for more information
6. Select a target language. Will default to your OS installed language as a preference however you can choose any language. This language is limited by Systran based on the source language
7. Run

## Source Language advice

|Source Language | Advice |
|----------------|--------|
| nuix-auto | Uses Nuix's language detection in order to save time on Systran's engine detecting the language |
| auto | Uses Systrans server side engine to detect the language |
| fr | Use french or 'en' for english etc in order to specifically use that language |

## Source Verse Target
Systran operates on known routes. If a language can't go from japanese to english for example the item will not be translated
Similarly if source langauge is the same as target this item will be skipped.

## Results
Two tabs will be launched at the completion of this script.

### First tab will be the successful items

Example of translation, the deliminator is like below, with the language abbreviation and the confidence level of that language being correct:

============ TRANSLATED (da 100%) ============

### Second tab will be any items with an error. The errors can be seen as custom metadata.

Example of error stating no path from japanese to english

Language-error-message: 

TD.async.onFinishedJob: No Queue defined for Route: accountId: 61706d6ef6be7c69a309071a, service: Translate_ja_en, selectors: {profileId: 95e5694a-b612-4842-8bd7-cdea9cd6c0e2}




# License

```
Copyright 2018 Nuix

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
