/**
 * Author: Doug Ayers
 * Website: https://douglascayers.com
 * GitHub: https://github.com/DouglasCAyers/sfdx-mass-action-scheduler
 * License: BSD 3-Clause License
 */
public class MA_MassActionBatchUtils {

    public static ID enqueueAction( ID configId ) {

        Mass_Action_Configuration__c config = MA_MassActionUtils.getConfiguration( configId );

        System.debug( 'MA_MassActionBatchUtils.enqueueAction: ' + config );

        ID jobId = null;

        if ( config.Active__c ) {

            if ( config.Source_Type__c == 'Report' ) {

                jobId = enqueueReportJob( config );

            } else if ( config.Source_Type__c == 'ListView' ) {

                jobId = enqueueListViewJob( config );

            } else {

                throw new MA_Exceptions.UnsupportedSourceTypeException( configId, config.Source_Type__c );

            }

        } else {

            System.debug( LoggingLevel.WARN, 'Not enqueueing inactive configuration' );

        }

        System.debug( 'jobId: ' + jobId );

        return jobId;
    }

    private static ID enqueueReportJob( Mass_Action_Configuration__c config ) {

        return Database.executeBatch( new MA_ReportSourceBatchable( config.Id ), config.Batch_Size__c.intValue() );
    }

    private static ID enqueueListViewJob( Mass_Action_Configuration__c config ) {

        return Database.executeBatch( new MA_ListViewSourceBatchable( config.Id ), config.Batch_Size__c.intValue() );
    }

    // ----------------------------------------------------

    public static void logJobErrors( ID configId, ID jobId ) {

        System.debug( 'MA_MassActionBatchUtils.logJobErrors: configId=' + configId + ', jobId=' + jobId );
        logJobErrors( configId, getJobById( jobId ), null );

    }

    // ----------------------------------------------------

    public static void logJobException( ID configId, ID jobId, Exception ex ) {

        System.debug( 'MA_MassActionBatchUtils.logJobException: configId=' + configId + ', jobId=' + jobId );
        logJobErrors( configId, getJobById( jobId ), ex );

    }

    // ----------------------------------------------------

    @TestVisible
    private static void logJobErrors( ID configId, AsyncApexJob job, Exception ex ) {

        System.debug( 'MA_MassActionBatchUtils.logJobErrors: configId=' + configId + ', job=' + job + ', exception=' + ex );

        Database.DMLOptions dmo = new Database.DMLOptions();
        dmo.allowFieldTruncation = true;

        if ( String.isNotBlank( job.ExtendedStatus ) || ( ex != null ) ) {

            // default the job error to short message as its only 255 chars
            // and put exception in long message
            String shortMessage = ( String.isBlank( job.ExtendedStatus ) ? null : job.ExtendedStatus );
            String longMessage = ( ex == null ? null : ex.getMessage() );

            // if either message field is blank then copy the other into it
            // because our DML option truncates values then its ok to copy long message into short
            shortMessage = ( String.isBlank( shortMessage ) ? longMessage : shortMessage );
            longMessage = ( String.isBlank( longMessage ) ? shortMessage : longMessage );

            Mass_Action_Log__c log = new Mass_Action_Log__c(
                Mass_Action_Configuration__c = configId,
                Job_ID__c = String.valueOf( job.Id ).left( 15 ),
                Submitted_Date__c = job.CreatedDate,
                Total_Batches__c = job.TotalJobItems,
                Processed_Batches__c = job.JobItemsProcessed,
                Failed_Batches__c = job.NumberOfErrors,
                Message__c = shortMessage,
                Long_Message__c = longMessage
            );

            Database.insert( log, dmo );

            System.debug( log );

        }

    }

    // ----------------------------------------------------

    private static AsyncApexJob getJobById( ID jobId ) {
        return [
            SELECT
                Id,
                CreatedDate,
                ExtendedStatus,
                TotalJobItems,
                JobItemsProcessed,
                NumberOfErrors
            FROM
                AsyncApexJob
            WHERE
                Id = :jobId
        ];
    }

}
/*
BSD 3-Clause License

Copyright (c) 2017, Doug Ayers, douglascayers.com
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