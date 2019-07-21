/**
 * Author: Doug Ayers
 * Website: https://douglascayers.com
 * GitHub: https://github.com/douglascayers-org/sfdx-mass-action-scheduler
 * License: BSD 3-Clause License
 */
/*
 * This class explicitly uses 'without sharing' because it runs not as a real user
 * but rather as the Automated Process user, an entity we can't grant permissions to.
 */
public without sharing class MA_BatchApexErrorEventInvocable {

    @InvocableMethod(
        label = 'MAS: Batch Apex Error Event Handler'
        description = 'Creates Mass Action Logs from batch job errors when running Mass Action Configurations.'
    )
    public static List<Response> execute( List<Request> requests ) {

        List<Response> responses = new List<Response>();

        System.debug( 'MA_BatchApexErrorEventInvocable.execute: size=' + requests.size() );

        Set<ID> jobIds = new Set<ID>();
        for ( Request evt : requests ) {
            if ( String.isNotBlank( evt.asyncApexJobId ) ) {
                jobIds.add( ID.valueOf( evt.asyncApexJobId ) );
            }
        }

        Map<ID, AsyncApexJob> jobIdToJobMap = MA_MassActionBatchUtils.getJobsByJobIdMap( jobIds );

        Map<ID, Mass_Action_Log__c> jobIdtoParentLogMap = MA_MassActionBatchUtils.getParentLogsByJobIdMap( jobIdToJobMap.values() );

        List<Mass_Action_Batch_Apex_Status_Event__e> jobStatusEvents = new List<Mass_Action_Batch_Apex_Status_Event__e>();

        for ( Request evt : requests ) {

            ID asyncApexJobId = ID.valueOf( evt.AsyncApexJobId );
            AsyncApexJob job = jobIdToJobMap.get( asyncApexJobId );
            Mass_Action_Log__c parentLog = jobIdToParentLogMap.get( asyncApexJobId );

            // if either the job or parent log are null then
            // this batch error event is not for mass action scheduler, skip it
            if ( job != null && parentLog != null ) {

                jobStatusEvents.add( new Mass_Action_Batch_Apex_Status_Event__e(
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
                    // It is very important that we use the event's created date
                    // and not when we're processing the event because platform events
                    // are handled asynchronously. If we use "now" vs. "then" then
                    // our log records will be out of order chronologically.
                    // The logs would appear in the order we got to insert them
                    // rather than the real time of when the cause occurred.
                    Timestamp__c = String.valueOf( evt.CreatedDate.getTime() )
                ));

            }

        }

        List<Database.SaveResult> results = MA_MassActionBatchUtils.publish( jobStatusEvents );

        for ( Database.SaveResult result : results ) {
            responses.add( new Response( result ) );
        }

        return responses;
    }

    /**
     * Mirrors the BatchApexErrorEvent record.
     * Designed for process builder to map the fields to this invocable request parameter.
     * https://developer.salesforce.com/docs/atlas.en-us.220.0.platform_events.meta/platform_events/sforce_api_objects_batchapexerrorevent.htm
     */
    public inherited sharing class Request {

        @InvocableVariable(
            label = 'Async Apex Job ID'
            description = 'ID of the batch Apex job that fired this event.'
            required = true
        )
        public String asyncApexJobId;

        @InvocableVariable(
            label = 'Phase'
            description = 'The phase of the batch job when it encountered an error. One of START, EXECUTE, or FINISH.'
            required = true
        )
        public String phase;

        @InvocableVariable(
            label = 'Job Scope'
            description = 'The Record IDs that are in scope if the event was fired from the execute() method of a batch job.'
            required = true
        )
        public String jobScope;

        @InvocableVariable(
            label = 'Message'
            description = 'Exception message text.'
            required = true
        )
        public String message;

        @InvocableVariable(
            label = 'Exception Type'
            description = 'The Apex exception type name.'
            required = true
        )
        public String exceptionType;

        @InvocableVariable(
            label = 'Stack Trace'
            description = 'The Apex stacktrace of the exception, if available.'
            required = true
        )
        public String stackTrace;

        @InvocableVariable(
            label = 'Replay ID'
            description = 'ID value that is populated by the system and refers to the position of the event in the event stream.'
            required = true
        )
        public String replayId;

        @InvocableVariable(
            label = 'Request ID'
            description = 'The unique ID of the batch job that fired the event.'
            required = true
        )
        public String requestId;

        @InvocableVariable(
            label = 'Created By ID'
            description = 'Who published this event.'
            required = true
        )
        public ID createdById;

        @InvocableVariable(
            label = 'Created Date'
            description = 'When the event was published.'
            required = true
        )
        public DateTime createdDate;

        public Request() {}

        public Request( BatchApexErrorEvent evt ) {
            this.asyncApexJobId = evt.AsyncApexJobId;
            this.phase = evt.Phase;
            this.jobScope = evt.JobScope;
            this.message = evt.Message;
            this.exceptionType = evt.ExceptionType;
            this.stackTrace = evt.StackTrace;
            this.replayId = evt.ReplayId;
            this.requestId = evt.RequestId;
            this.createdById = evt.CreatedById;
            this.createdDate = evt.CreatedDate;
        }

    }

    public inherited sharing class Response {

        @InvocableVariable(
            label = 'Event ID'
            description = 'ID of the published Mass_Action_Batch_Apex_Status_Event__e event.'
        )
        public ID eventId;

        @InvocableVariable(
            label = 'Success'
            description = 'True if the event was published, false otherwise.'
        )
        public Boolean success;

        @InvocableVariable(
            label = 'Errors'
            description = 'List of errors trying to publish the event.'
        )
        public List<String> errors = new List<String>();

        public Response() {}

        public Response( Database.SaveResult result ) {
            this.eventId = result.id;
            this.success = result.success;
            for ( Database.Error err : result.getErrors() ) {
                errors.add( err.getStatusCode() + ' : ' + err.getMessage() );
            }
        }

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