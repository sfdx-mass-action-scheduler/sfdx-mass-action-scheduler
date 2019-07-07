/**
 * Author: Doug Ayers
 * Website: https://douglascayers.com
 * GitHub: https://github.com/douglascayers-org/sfdx-mass-action-scheduler
 * License: BSD 3-Clause License
 */
public without sharing class MA_BatchApexErrorEventTriggerHandler {

    public MA_BatchApexErrorEventTriggerHandler() {}

    // -------------------------------------------------------
    // INSERT
    // -------------------------------------------------------

    public void handleAfterInsert( List<BatchApexErrorEvent> newList, Map<ID, BatchApexErrorEvent> newMap ) {

        System.debug( 'MA_BatchApexErrorEventTriggerHandler.handleAfterInsert' );

        // We don't have lookup fields to AsyncApexJob records,
        // so standardizing on the 15 character id, least common denominator.
        // Also, must use string variable type because ID variable type
        // always coerces the assigned value back to 18 characters.

        Set<String> jobIds = new Set<String>();

        for ( BatchApexErrorEvent evt : newList ) {

            System.debug( 'MA_BatchApexErrorEventTriggerHandler.handleAfterInsert: ' + JSON.serializePretty( evt ) );

            jobIds.add( evt.AsyncApexJobId.left( 15 ) );

        }

        Map<ID, AsyncApexJob> jobsMap = new Map<ID, AsyncApexJob>([
            SELECT
                Id, ParentJobId, Status, ExtendedStatus, TotalJobItems, JobItemsProcessed, NumberOfErrors, CreatedDate
            FROM
                AsyncApexJob
            WHERE
                Id IN :jobIds
        ]);

        // It's possible that the batch error event's job id is
        // a child job of the main batch job that represents the
        // mass action configuration's execution.
        // The parent log record's job id will be a parent job id.
        // So to be able to cross-ref correctly, we need the parent job ids.
        Set<String> parentJobIds = new Set<String>();
        for ( AsyncApexJob job : jobsMap.values() ) {
            parentJobIds.add( String.valueOf( String.isNotBlank( job.ParentJobId ) ? job.ParentJobId : job.Id ).left( 15 ) );
        }

        Map<String, Mass_Action_Log__c> jobIdToParentLogMap = new Map<String, Mass_Action_Log__c>();
        for ( Mass_Action_Log__c parentLog : [
            SELECT
                Id, Job_ID__c, Mass_Action_Configuration__c
            FROM
                Mass_Action_Log__c
            WHERE
                Job_ID__c IN :parentJobIds
                AND
                RecordType.DeveloperName = 'Parent_Log'
        ]) {
            jobIdToParentLogMap.put( parentLog.Job_ID__c.left( 15 ), parentLog );
        }

        Map<String,RecordTypeInfo> logRecordTypeInfosMap = Mass_Action_Log__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName();

        List<Mass_Action_Log__c> parentLogsToUpdate = new List<Mass_Action_Log__c>();
        List<Mass_Action_Log__c> childLogsToInsert = new List<Mass_Action_Log__c>();

        for ( BatchApexErrorEvent evt : newList ) {

            AsyncApexJob job = jobsMap.get( ID.valueOf( evt.AsyncApexJobId ) );
            Mass_Action_Log__c parentLog = jobIdToParentLogMap.get( evt.AsyncApexJobId.left( 15 ) );

            // if either the job or parent log are null then
            // this batch error event is not for mass action scheduler, skip it
            if ( job != null && parentLog != null ) {

                switch on ( evt.Phase ) {

                    when 'START' {

                        parentLogsToUpdate.add( new Mass_Action_Log__c(
                            Id = parentLog.Id,
                            Message_Type__c = 'Error',
                            Message__c = 'Error in batch job phase ' + evt.Phase + ': ' + evt.Message,
                            Long_Message__c = 'Phase: ' + evt.Phase + '\nMessage: ' + evt.Message + '\nExceptionType: ' + evt.ExceptionType + '\nStackTrace: ' + evt.StackTrace,
                            Job_Scope__c = evt.JobScope,
                            Submitted_Date__c = job.CreatedDate,
                            Total_Batches__c = job.TotalJobItems,
                            Processed_Batches__c = job.JobItemsProcessed,
                            Failed_Batches__c = job.NumberOfErrors
                        ));

                    }

                    when 'EXECUTE' {

                        parentLogsToUpdate.add( new Mass_Action_Log__c(
                            Id = parentLog.Id,
                            Message_Type__c = 'Informational',
                            Message__c = 'Batch job processing',
                            Submitted_Date__c = job.CreatedDate,
                            Total_Batches__c = job.TotalJobItems,
                            Processed_Batches__c = job.JobItemsProcessed,
                            Failed_Batches__c = job.NumberOfErrors
                        ));

                        childLogsToInsert.add( new Mass_Action_Log__c(
                            RecordTypeId = logRecordTypeInfosMap.get( 'Child_Log' ).getRecordTypeId(),
                            Mass_Action_Configuration__c = parentLog.Mass_Action_Configuration__c,
                            Parent_Log__c = parentLog.Id,
                            Job_ID__c = parentLog.Job_ID__c,
                            Message_Type__c = 'Error',
                            Message__c = 'Error in batch job phase ' + evt.Phase + ': ' + evt.Message,
                            Long_Message__c = 'Phase: ' + evt.Phase + '\nMessage: ' + evt.Message + '\nExceptionType: ' + evt.ExceptionType + '\nStackTrace: ' + evt.StackTrace,
                            Job_Scope__c = evt.JobScope
                        ));

                    }

                    WHEN 'FINISH' {

                        parentLogsToUpdate.add( new Mass_Action_Log__c(
                            Id = parentLog.Id,
                            Message_Type__c = 'Error',
                            Message__c = 'Error in batch job phase ' + evt.Phase + ': ' + evt.Message,
                            Long_Message__c = 'Phase: ' + evt.Phase + '\nMessage: ' + evt.Message + '\nExceptionType: ' + evt.ExceptionType + '\nStackTrace: ' + evt.StackTrace,
                            Job_Scope__c = evt.JobScope,
                            Submitted_Date__c = job.CreatedDate,
                            Total_Batches__c = job.TotalJobItems,
                            Processed_Batches__c = job.JobItemsProcessed,
                            Failed_Batches__c = job.NumberOfErrors
                        ));

                    }

                }

            }

        }

        Database.DMLOptions dmo = new Database.DMLOptions();
        dmo.allowFieldTruncation = true;

        Database.insert( childLogsToInsert, dmo );
        Database.update( parentLogsToUpdate, dmo );

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