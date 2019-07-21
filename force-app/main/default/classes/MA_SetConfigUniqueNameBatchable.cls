/**
 * Author: Doug Ayers
 * Website: https://douglascayers.com
 * GitHub: https://github.com/douglascayers-org/sfdx-mass-action-scheduler
 * License: BSD 3-Clause License
 */
/**
 * Designed for the upgrade to release 1.6 that introduces the Mass_Action_Configuration__c.DeveloperName__c field.
 * Batches over all config records with a blank developer name field and populates one for it based on its name.
 * Automatically retries updating the config record by appending a random suffix to the developer name until generates a unique value.
 *
 * This class explicitly uses 'without sharing' because it is invoked by the package install handler
 * and it is documented that the use of 'with sharing' by apex classes called by the handler may prevent installation.
 * https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_install_handler.htm
 */
public without sharing class MA_SetConfigUniqueNameBatchable implements Database.Batchable<SObject>,
                                                                        Database.Stateful,
                                                                        Database.AllowsCallouts,
                                                                        Database.RaisesPlatformEvents {

    public Database.QueryLocator start( Database.BatchableContext context ) {

        System.debug( 'MA_SetConfigUniqueNameBatchable.start: ' + context );

        return Database.getQueryLocator([
            SELECT
                Id, Name, DeveloperName__c
            FROM
                Mass_Action_Configuration__c
            WHERE
                DeveloperName__c = null
        ]);
    }

    public void execute( Database.BatchableContext context, List<Mass_Action_Configuration__c> records ) {

        System.debug( 'MA_SetConfigUniqueNameBatchable.execute: ' + context );

        Boolean hasDuplicateDeveloperNameErrors = false;

        List<Mass_Action_Configuration__c> recordsToUpdate = new List<Mass_Action_Configuration__c>( records );

        for ( Mass_Action_Configuration__c record : recordsToUpdate ) {
            record.DeveloperName__c = formatNameAsUniqueName( record.Name, false );
        }

        do {

            List<Database.SaveResult> saveResults = Database.update( recordsToUpdate, false );
            List<Mass_Action_Configuration__c> recordsToRetry = new List<Mass_Action_Configuration__c>();

            for ( Integer i = 0; i < saveResults.size(); i++ ) {

                Database.SaveResult saveResult = saveResults[i];
                Mass_Action_Configuration__c record = recordsToUpdate[i];

                if ( !saveResult.isSuccess() ) {

                    Boolean isDuplicateDeveloperNameError = false;

                    System.debug( 'MA_SetConfigUniqueNameBatchable.execute: record failed to update: ' + record );

                    for ( Database.Error err : saveResult.getErrors() ) {

                        System.debug( 'MA_SetConfigUniqueNameBatchable.execute: ' + err );

                        // Bug W-4635920: duplicate value errors are not populating which field in Error.getFields() nor Error.getMessage()
                        Boolean isDeveloperNameField = true; // assume so until Salesforce fixes the bug
                        Boolean isDuplicateValue = ( err.getStatusCode() == StatusCode.DUPLICATE_VALUE );

                        isDuplicateDeveloperNameError = ( isDeveloperNameField && isDuplicateValue );

                    }

                    if ( isDuplicateDeveloperNameError ) {

                        // try to make name "more" unique with random suffix
                        record.DeveloperName__c = formatNameAsUniqueName( record.Name, true );
                        System.debug( 'MA_SetConfigUniqueNameBatchable.execute: duplicate developer name, trying a random value: ' + record );

                        recordsToRetry.add( record );

                        hasDuplicateDeveloperNameErrors = true;

                    }

                    System.debug( 'MA_SetConfigUniqueNameBatchable.execute: isDuplicateDeveloperNameError=' + isDuplicateDeveloperNameError );

                }

            }

            recordsToUpdate = recordsToRetry;

        } while ( hasDuplicateDeveloperNameErrors && recordsToUpdate.size() > 0 );

    }

    public void finish( Database.BatchableContext context ) {

        System.debug( 'MA_SetConfigUniqueNameBatchable.finish: ' + context );

    }

    // ------------------------------------------------------------------------

    private String formatNameAsUniqueName( String name, Boolean useRandomSuffix ) {

        String uniqueName = name;

        if ( uniqueName != null ) {

            // trim whitespace
            uniqueName = uniqueName.trim();

            // replace whitespace with underscore
            uniqueName = uniqueName.replaceAll( '[ ]+', '_' );

            if ( useRandomSuffix ) {

                String randomSuffix = '_' + MA_StringUtils.getRandomLetters( 4 );

                // ensure room for random suffix
                uniqueName = uniqueName.left( Mass_Action_Configuration__c.DeveloperName__c.getDescribe().getLength() - randomSuffix.length() );

                // append random suffix
                uniqueName += randomSuffix;

            }

        }

        return uniqueName;
    }

}
/*
BSD 3-Clause License

Copyright (c) 2017-2019, Doug Ayers, douglascayers.com
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
  list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice,
  this list of conditions and the following disclaimer in the documentation
  and/or other materials provided with the distribution.

* Neither the name of the copyright holder nor the names of its
  contributors may be used to endorse or promote products derived from
  this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/