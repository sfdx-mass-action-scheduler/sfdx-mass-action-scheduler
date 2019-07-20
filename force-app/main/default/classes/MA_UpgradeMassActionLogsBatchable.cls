/**
 * Author: Doug Ayers
 * Website: https://douglascayers.com
 * GitHub: https://github.com/douglascayers-org/sfdx-mass-action-scheduler
 * License: BSD 3-Clause License
 */
/**
 * Designed for the upgrade to release 2.3 that introduces the record types to Mass_Action_Log__c object.
 * Batches over all log records with a blank record type and assigns the "Child_Log" record type to it.
 * For each unique combination of configuration id and job id of existing logs for a configuration,
 * creates a new parent log record and links the child log records to it.
 *
 * This class explicitly uses 'without sharing' because it is invoked by the package install handler
 * and it is documented that the use of 'with sharing' by apex classes called by the handler may prevent installation.
 * https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_install_handler.htm
 */
public without sharing class MA_UpgradeMassActionLogsBatchable implements Database.Batchable<SObject>,
                                                                          Database.Stateful,
                                                                          Database.AllowsCallouts,
                                                                          Database.RaisesPlatformEvents {

    public Database.QueryLocator start( Database.BatchableContext context ) {

        System.debug( 'MA_UpgradeMassActionLogsBatchable.start: ' + context );

        return Database.getQueryLocator([
            SELECT
                Id, RecordTypeId, Mass_Action_Configuration__c, Parent_Log__c,
                Job_ID__c, Message_Type__c, Timestamp__c, CreatedDate
            FROM
                Mass_Action_Log__c
            WHERE
                RecordTypeId = null
                AND
                Job_ID__c != null
            ORDER BY
                Mass_Action_Configuration__c ASC,
                Job_ID__c ASC,
                CreatedDate ASC,
                Id ASC
        ]);
    }

    public void execute( Database.BatchableContext context, List<Mass_Action_Log__c> logs ) {

        System.debug( 'MA_UpgradeMassActionLogsBatchable.execute: ' + context );

        Map<String,RecordTypeInfo> logRecordTypeInfosMap = Mass_Action_Log__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName();

        Map<ID, AsyncApexJob> jobsMap = new Map<ID, AsyncApexJob>();
        Map<String, Mass_Action_Log__c> parentLogsMap = new Map<String, Mass_Action_Log__c>();
        Map<String, Mass_Action_Log__c> parentLogsToInsertMap = new Map<String, Mass_Action_Log__c>();
        List<Mass_Action_Log__c> childLogsToUpdate = new List<Mass_Action_Log__c>();

        // create filter criteria when searching for
        // existing parent logs; we only want parent logs
        // pertinent to these config and job ids
        Set<ID> configIds18 = new Set<ID>();
        Set<ID> jobIds18 = new Set<ID>();
        Set<String> jobIds15 = new Set<String>();

        for ( Mass_Action_Log__c log : logs ) {

            if ( String.isNotBlank( log.Mass_Action_Configuration__c ) ) {
                configIds18.add( log.Mass_Action_Configuration__c );
            }

            if ( String.isNotBlank( log.Job_ID__c ) ) {
                jobIds15.add( log.Job_ID__c.left( 15 ) );
                jobIds18.add( ID.valueOf( log.Job_ID__c ) );
            }

        }

        // get jobs to populate data on parent logs
        jobsMap = MA_MassActionBatchUtils.getJobsByJobIdMap( jobIds18 );

        // get any existing parent logs from prior batch executions
        parentLogsMap = getParentLogsMap( configIds18, jobIds15 );

        // determine any parent logs that need to be created
        for ( Mass_Action_Log__c log : logs ) {

            String key = computeKey( log.Mass_Action_Configuration__c, log.Job_ID__c );
            Mass_Action_Log__c parentLog = parentLogsMap.get( key );
            AsyncApexJob job = jobsMap.get( ID.valueOf( log.Job_ID__c ) );

            if ( parentLog == null ) {

                parentLog = new Mass_Action_Log__c(
                    RecordTypeId = logRecordTypeInfosMap.get( 'Parent_Log' ).getRecordTypeId(),
                    Mass_Action_Configuration__c = log.Mass_Action_Configuration__c,
                    Job_ID__c = log.Job_ID__c,
                    Message_Type__c = 'Informational',
                    Message__c = 'Batch job information',
                    Timestamp__c = String.valueOf( log.CreatedDate.getTime() ),
                    Total_Batches__c = 0,
                    Processed_Batches__c = 0,
                    Failed_Batches__c = 0
                );

                // very old jobs may have been deleted and no longer exist
                // so if not, just skip this part
                if ( job != null ) {

                    String messageType = 'Error';

                    String message = 'Batch job ' + (
                        ( job.Status == 'Completed' ) ? 'completed with errors' :
                        String.isBlank( job.Status ) ? 'information' :
                        job.Status.toLowerCase()
                    );

                    parentLog.Message_Type__c = messageType;
                    parentLog.Message__c = message;
                    parentLog.Submitted_Date__c = job.CreatedDate;
                    parentLog.Total_Batches__c = job.TotalJobItems;
                    parentLog.Processed_Batches__c = job.JobItemsProcessed;

                    // See comment further down where we increment failed batches
                    //parentLog.Failed_Batches__c = job.NumberOfErrors;

                } else {

                    // For old logs, the AsyncApexJob record may
                    // no longer exist or have been purged already.
                    // If we the job record doesn't exist then we can't
                    // reliably determine the job's submitted date or
                    // how many total batches were processed.
                    // Let's add a message to that effect so the user
                    // understands why their parent log isn't complete.
                    parentLog.Message__c = 'Batch job information incomplete';
                    parentLog.Long_Message__c = (
                        'Do not be alarmed, this is an informational message only.' +
                        '\n\n' +
                        'During the Mass Action Scheduler package upgrade to create parent logs, ' +
                        'we could not find a batch job for id "7071h00000ehRQZ". ' +
                        'The AsyncApexJob record from the Apex Jobs page in Setup may have already been purged from the system. ' +
                        'Therefore, the "Submitted Date", "Total Batches", and "Processed Batches" field values on this log record ' +
                        'may not be accurate because we did not find an AsyncApexJob record to copy the values from.' +
                        '\n\n' +
                        'Tip: You can safely delete Mass Action Log records anytime after the batch job has completed. ' +
                        'They exist to help you troubleshoot errors and track job progress.'
                    );

                }

                // add yet to be saved log to map to avoid
                // re-processing this key and so ensuring
                // the first parent log's timestamp should
                // be the earliest date of the earliest
                // child log for this map key
                parentLogsMap.put( key, parentLog );

                // add yet to be saved log to map that will saved
                parentLogsToInsertMap.put( key, parentLog );

            }

        }

        // create new parent logs
        insert parentLogsToInsertMap.values();

        // requery parent logs
        parentLogsMap = getParentLogsMap( configIds18, jobIds15 );

        // assign parent logs to child logs
        for ( Mass_Action_Log__c log : logs ) {

            String key = computeKey( log.Mass_Action_Configuration__c, log.Job_ID__c );
            Mass_Action_Log__c parentLog = parentLogsMap.get( key );

            if ( parentLog != null ) {
                childLogsToUpdate.add( new Mass_Action_Log__c(
                    Id = log.Id,
                    Parent_Log__c = parentLog.Id,
                    RecordTypeId = logRecordTypeInfosMap.get( 'Child_Log' ).getRecordTypeId(),
                    Message_Type__c = 'Error',
                    Timestamp__c = String.valueOf( log.CreatedDate.getTime() )
                ));
            }

        }

        // update child logs
        update childLogsToUpdate;

        // In prior versions, only batch job errors were
        // logged, but to do I used try/catch in the start/execute/finish
        // methods and inserted log records right then.
        // This let us log the errors, but the batch job considered
        // all executions were successful -- no number of errors.
        // For this data migration, assume any log record means an error.
        // We will set the number of errors equal to number of log records we find.
        for ( List<AggregateResult> results : [
            SELECT
                Mass_Action_Configuration__c configId,
                Job_ID__c jobId,
                Parent_Log__c parentLogId,
                COUNT( Id ) logCount
            FROM
                Mass_Action_Log__c
            WHERE
                Parent_Log__c IN :parentLogsMap.values()
                AND
                RecordTypeId = :logRecordTypeInfosMap.get( 'Child_Log' ).getRecordTypeId()
            GROUP BY
                Mass_Action_Configuration__c,
                Job_ID__c,
                Parent_Log__c
        ]) {
            for ( AggregateResult result : results ) {

                System.debug( result );

                ID configId = (ID) result.get( 'configId' );
                ID jobId = (ID) result.get( 'jobId' );
                ID parentLogId = (ID) result.get( 'parentLogId' );
                Integer logCount = (Integer) result.get( 'logCount' );

                String key = computeKey( configId, jobId );
                Mass_Action_Log__c parentLog = parentLogsMap.get( key );
                parentLog.Failed_Batches__c = logCount;

            }
        }

        update parentLogsMap.values();

    }

    public void finish( Database.BatchableContext context ) {

        System.debug( 'MA_UpgradeMassActionLogsBatchable.finish: ' + context );

    }

    // ------------------------------------------------------------------------

    private String computeKey( String configId, String jobId ) {
        return ( configId.left( 18 ) + '#' + jobId.left( 15 ) );
    }

    private Map<String, Mass_Action_Log__c> getParentLogsMap( Set<ID> configIds18, Set<String> jobIds15 ) {

        Map<String,RecordTypeInfo> logRecordTypeInfosMap = Mass_Action_Log__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName();

        Map<String, Mass_Action_Log__c> parentLogsMap = new Map<String, Mass_Action_Log__c>();

        for ( Mass_Action_Log__c parentLog : [
            SELECT
                Id, Mass_Action_Configuration__c, Job_ID__c,
                Total_Batches__c, Processed_Batches__c, Failed_Batches__c
            FROM
                Mass_Action_Log__c
            WHERE
                RecordTypeId = :logRecordTypeInfosMap.get( 'Parent_Log' ).getRecordTypeId()
                AND
                Mass_Action_Configuration__c IN :configIds18
                AND
                Job_ID__c IN :jobIds15
        ]) {
            String key = computeKey( parentLog.Mass_Action_Configuration__c, parentLog.Job_ID__c );
            parentLogsMap.put( key, parentLog );
        }

        return parentLogsMap;
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