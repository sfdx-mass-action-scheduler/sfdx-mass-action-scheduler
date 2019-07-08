/**
 * Author: Doug Ayers
 * Website: https://douglascayers.com
 * GitHub: https://github.com/douglascayers-org/sfdx-mass-action-scheduler
 * License: BSD 3-Clause License
 */
public with sharing class MA_BatchApexErrorEventTriggerHandler {

    public MA_BatchApexErrorEventTriggerHandler() {}

    // -------------------------------------------------------
    // INSERT
    // -------------------------------------------------------

    public void handleAfterInsert( List<BatchApexErrorEvent> newList, Map<ID, BatchApexErrorEvent> newMap ) {

        System.debug( 'MA_BatchApexErrorEventTriggerHandler.handleAfterInsert' );

        Map<ID, AsyncApexJob> jobIdToJobMap = MA_MassActionBatchUtils.getJobsByJobIdMap( newList );

        Map<ID, Mass_Action_Log__c> jobIdtoParentLogMap = MA_MassActionBatchUtils.getParentLogsByJobIdMap( jobIdToJobMap.values() );

        List<MA_BatchApexStatusEvent__e> jobStatusEvents = new List<MA_BatchApexStatusEvent__e>();

        for ( BatchApexErrorEvent evt : newList ) {

            ID asyncApexJobId = ID.valueOf( evt.AsyncApexJobId );
            AsyncApexJob job = jobIdToJobMap.get( asyncApexJobId );
            Mass_Action_Log__c parentLog = jobIdToParentLogMap.get( asyncApexJobId );

            // if either the job or parent log are null then
            // this batch error event is not for mass action scheduler, skip it
            if ( job != null && parentLog != null ) {

                jobStatusEvents.add( new MA_BatchApexStatusEvent__e(
                    Job_ID__c = job.Id,
                    Phase__c = evt.Phase,
                    Message_Type__c = 'Error',
                    Message__c = 'Error in job phase ' + evt.Phase + ': ' + evt.Message,
                    Long_Message__c = (
                        'Phase: ' + evt.Phase + '\n' +
                        'Message: ' + evt.Message + '\n' +
                        'ExceptionType: ' + evt.ExceptionType + '\n' +
                        'StackTrace: ' + evt.StackTrace
                    ),
                    Job_Scope__c = evt.JobScope,
                    Timestamp__c = String.valueOf( evt.CreatedDate.getTime() )
                ));

            }

        }

        MA_MassActionBatchUtils.publish( jobStatusEvents );

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