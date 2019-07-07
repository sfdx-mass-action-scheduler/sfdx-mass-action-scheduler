/**
 * Author: Doug Ayers
 * Website: https://douglascayers.com
 * GitHub: https://github.com/douglascayers-org/sfdx-mass-action-scheduler
 * License: BSD 3-Clause License
 */
public inherited sharing class MA_MassActionBatchUtils {

    public static ID enqueueAction( ID configId ) {

        Mass_Action_Configuration__c config = MA_MassActionUtils.getConfiguration( configId );

        System.debug( 'MA_MassActionBatchUtils.enqueueAction: ' + config );

        ID jobId = null;

        if ( config.Active__c ) {

            if ( config.Source_Type__c == 'Report' ) {

                jobId = enqueueReportJob( config );

            } else if ( config.Source_Type__c == 'ListView' ) {

                jobId = enqueueListViewJob( config );

            } else if ( config.Source_Type__c == 'SOQL' ) {

                jobId = enqueueSoqlJob( config );

            } else if ( config.Source_Type__c == 'Apex' ) {

                jobId = enqueueApexJob( config );

            } else {

                throw new MA_Exceptions.UnsupportedSourceTypeException( configId, config.Source_Type__c );

            }

            // Log that the job has been enqueued.
            // All other success/error logs for this job
            // will be saved as child logs to this one.

            Map<String,RecordTypeInfo> logRecordTypeInfosMap = Mass_Action_Log__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName();

            // We don't have lookup fields to AsyncApexJob records,
            // so standardizing on the 15 character id, least common denominator.
            // Also, must use string variable type because ID variable type
            // always coerces the assigned value back to 18 characters.
            String jobId15 = String.valueOf( jobId ).left( 15 );

            Mass_Action_Log__c log = new Mass_Action_Log__c(
                RecordTypeId = logRecordTypeInfosMap.get( 'Parent_Log' ).getRecordTypeId(),
                Mass_Action_Configuration__c = configId,
                Job_ID__c = jobId15,
                Submitted_Date__c = DateTime.now(),
                Message__c = 'Batch job enqueued',
                Message_Type__c = 'Informational'
            );

            insert log;

        } else {

            System.debug( LoggingLevel.WARN, 'MA_MassActionBatchUtils.enqueueAction: Not enqueueing inactive configuration' );

        }

        System.debug( 'MA_MassActionBatchUtils.enqueueAction: jobId: ' + jobId );

        return jobId;
    }

    private static ID enqueueReportJob( Mass_Action_Configuration__c config ) {

        return Database.executeBatch( new MA_ReportSourceBatchable( config.Id ), config.Batch_Size__c.intValue() );
    }

    private static ID enqueueListViewJob( Mass_Action_Configuration__c config ) {

        return Database.executeBatch( new MA_ListViewSourceBatchable( config.Id ), config.Batch_Size__c.intValue() );
    }

    private static ID enqueueSoqlJob( Mass_Action_Configuration__c config ) {

        return Database.executeBatch( new MA_IterableSourceBatchable( config.Id, new MA_SoqlSourceIterable( config.Id ) ), config.Batch_Size__c.intValue() );
    }

    private static ID enqueueApexJob( Mass_Action_Configuration__c config ) {

        String namespace = null;
        String className = config.Source_Apex_Class__c;

        Type t = null;

        if ( className.contains( '.' ) ) {
            namespace = config.Source_Apex_Class__c.substringBefore( '.' );
            className = config.Source_Apex_Class__c.substringAfter( '.' );
        }

        t = Type.forName( namespace, className );

        // If don't find type then maybe the class name pattern
        // isn't "namespace.className" but rather "outerClass.innerClass"
        // in the current namespace.
        if ( t == null ) {
            t = Type.forName( null, config.Source_Apex_Class__c );
        }

        // If still don't find the type then either it
        // doesn't exist or isn't accessible by our package.
        if ( t == null ) {
            throw MA_Exceptions.buildException(
                NoDataFoundException.class,
                'No class found for name "' + config.Source_Apex_Class__c + '". If it exists, it may need to be global to be accessible by the Mass Action Scheduler package.'
            );
        }

        Iterable<Map<String, Object>> iterable = (Iterable<Map<String, Object>>) t.newInstance();
        return Database.executeBatch( new MA_IterableSourceBatchable( config.Id, iterable ), config.Batch_Size__c.intValue() );

    }

    // ----------------------------------------------------

    /**
     * Designed to be invoked during the batch start method.
     */
    public static void handleBatchJobStarted( ID configId, ID jobId ) {

        System.debug( 'MA_MassActionBatchUtils.handleBatchJobStarted: configId=' + configId + ', jobId=' + jobId );

        updateJobParentLogStatus( configId, jobId );

    }

    /**
     * Designed to be invoked during the batch execute method.
     */
    public static void handleBatchJobExecution( ID configId, ID jobId, Integer jobScopeSize, String jobScope ) {

        System.debug( 'MA_MassActionBatchUtils.handleBatchJobExecution: configId=' + configId + ', jobId=' + jobId + ', jobScopeSize=' + jobScopeSize + ', jobScope=' + jobScope );

        updateJobParentLogStatus( configId, jobId );

        Map<String,RecordTypeInfo> logRecordTypeInfosMap = Mass_Action_Log__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName();

        // We don't have lookup fields to AsyncApexJob records,
        // so standardizing on the 15 character id, least common denominator.
        // Also, must use string variable type because ID variable type
        // always coerces the assigned value back to 18 characters.
        String jobId15 = String.valueOf( jobId ).left( 15 );

        Mass_Action_Log__c parentLog = [
            SELECT
                Id, Mass_Action_Configuration__c, Job_ID__c
            FROM
                Mass_Action_Log__c
            WHERE
                Mass_Action_Configuration__c = :configId
                AND
                Job_ID__c = :jobId15
                AND
                RecordType.DeveloperName = 'Parent_Log'
        ];

        Mass_Action_Log__c childLog = new Mass_Action_Log__c(
            RecordTypeId = logRecordTypeInfosMap.get( 'Child_Log' ).getRecordTypeId(),
            Mass_Action_Configuration__c = parentLog.Mass_Action_Configuration__c,
            Parent_Log__c = parentLog.Id,
            Job_ID__c = parentLog.Job_ID__c,
            Message_Type__c = 'Success',
            Message__c = 'Processed ' + jobScopeSize + ' records',
            Long_Message__c = 'Phase: EXECUTION' + '\nMessage: Processed ' + jobScopeSize + ' records',
            Job_Scope__c = jobScope
        );

        Database.DMLOptions dmo = new Database.DMLOptions();
        dmo.allowFieldTruncation = true;

        Database.insert( childLog, dmo );

    }

    /**
     * Designed to be invoked during the batch finish method.
     */
    public static void handleBatchJobFinished( ID configId, ID jobId ) {

        System.debug( 'MA_MassActionBatchUtils.handleBatchJobFinished: configId=' + configId + ', jobId=' + jobId );

        updateJobParentLogStatus( configId, jobId );

        // We don't have lookup fields to AsyncApexJob records,
        // so standardizing on the 15 character id, least common denominator.
        // Also, must use string variable type because ID variable type
        // always coerces the assigned value back to 18 characters.
        String jobId15 = String.valueOf( jobId ).left( 15 );

        AsyncApexJob job = getJobById( jobId );

        // If actual batch job didn't fail with an error,
        // check if any of the batch executions logged errors
        Integer jobErrorLogCount = [
            SELECT
                COUNT()
            FROM
                Mass_Action_Log__c
            WHERE
                Mass_Action_Configuration__c = :configId
                AND
                Job_ID__c = :jobId15
                AND
                Message_Type__c = 'Error'
        ];

        Mass_Action_Configuration__c config = new Mass_Action_Configuration__c(
            Id = configId,
            Last_Run_Completed_Date__c = job.CompletedDate,
            Last_Run_Completed_With_Errors__c = ( jobErrorLogCount > 0 || job.NumberOfErrors > 0 )
        );

        update config;

    }

    // ----------------------------------------------------

    /**
     * Designed to be called once per batch job's start, execute, and finish phases.
     *
     * Updates the parent log record with details from the AsyncApexJob,
     * such as items processed and the current job status.
     *
     * @param configId
     *      Configuration that owns the log record.
     * @param jobId
     *      AsyncApexJob the log is tracking progress for.
     */
    private static void updateJobParentLogStatus( ID configId, ID jobId ) {

        System.debug( 'MA_MassActionBatchUtils.updateJobLogStatus: configId=' + configId + ', jobId=' + jobId );

        // We don't have lookup fields to AsyncApexJob records,
        // so standardizing on the 15 character id, least common denominator.
        // Also, must use string variable type because ID variable type
        // always coerces the assigned value back to 18 characters.
        String jobId15 = String.valueOf( jobId ).left( 15 );

        AsyncApexJob job = getJobById( jobId );

        // Technically, there should be exactly 0 or 1
        // parent logs for this apex job, but just in case
        // there are multiples, and just in case there are none,
        // a SOQL-FOR loop is simplest approach to handle all use cases.
        for ( List<Mass_Action_Log__c> parentLogs : [
            SELECT
                Id, Mass_Action_Configuration__c, Job_ID__c, Parent_Log__c,
                Job_Scope__c, Message_Type__c, Message__c, Long_Message__c,
                Submitted_Date__c, Total_Batches__c, Processed_Batches__c, Failed_Batches__c
            FROM
                Mass_Action_Log__c
            WHERE
                Mass_Action_Configuration__c = :configId
                AND
                Job_ID__c = :jobId15
                AND
                RecordType.DeveloperName = 'Parent_Log'
            FOR UPDATE
        ]) {

            for ( Mass_Action_Log__c parentLog : parentLogs ) {
                parentLog.Message__c = 'Batch job ' + ( String.isBlank( job.Status ) ? 'details' : job.Status ).toLowerCase();
                parentLog.Submitted_Date__c = job.CreatedDate;
                parentLog.Total_Batches__c = job.TotalJobItems;
                parentLog.Processed_Batches__c = job.JobItemsProcessed;
                parentLog.Failed_Batches__c = job.NumberOfErrors;
            }

            Database.DMLOptions dmo = new Database.DMLOptions();
            dmo.allowFieldTruncation = true;

            Database.update( parentLogs, dmo );

        }

    }

    // ----------------------------------------------------

    public static AsyncApexJob getJobById( ID jobId ) {

        AsyncApexJob job;

        if ( Test.isRunningTest() ) {
            job = MA_AsyncApexJobMock.getJobById( jobId );
        }

        // acrobatics for test coverage and the fact that
        // AsyncApexJob records can't truly be mocked
        if ( job == null && !MA_AsyncApexJobMock.MOCK_JOB_IDS.contains( jobId ) ) {
            for ( AsyncApexJob item : [
                SELECT
                    Id,
                    CreatedDate,
                    CompletedDate,
                    Status,
                    ExtendedStatus,
                    TotalJobItems,
                    JobItemsProcessed,
                    NumberOfErrors
                FROM
                    AsyncApexJob
                WHERE
                    Id = :jobId
                LIMIT 1
            ]) {
                job = item;
            }
        }

        return job;
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