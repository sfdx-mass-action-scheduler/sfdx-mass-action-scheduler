/**
 * Author: Doug Ayers
 * Website: https://douglascayers.com
 * GitHub: https://github.com/douglascayers-org/sfdx-mass-action-scheduler
 * License: BSD 3-Clause License
 */
/**
 * When users save Mass Action Configurations using the MA_EditConfigCmp component,
 * it invokes our custom Apex REST endpoint via the LC_API component. Therefore, the Mass Action Configuration
 * trigger handler ends up being invoked from within the execution context of Apex REST.
 *
 * Due to known issue that execution contexts started from Apex REST endpoints
 * cannot schedule or abort jobs, then our workaround is to use platform events
 * to move into another execution context.
 * https://success.salesforce.com/issues_view?id=a1p30000000SyhIAAS
 *
 * This is the trigger handler for those platform events to handle scheduling and unscheduling
 * the Apex jobs driven by the Mass Action Configuration records.
 */
public with sharing class MA_JobChangeEventTriggerHandler {

    public MA_JobChangeEventTriggerHandler() {}

    // -------------------------------------------------------
    // INSERT
    // -------------------------------------------------------

    public void handleAfterInsert( List<Mass_Action_Job_Change_Event__e> newList, Map<ID, Mass_Action_Job_Change_Event__e> newMap ) {

        System.debug( 'MA_JobChangeEventTriggerHandler.handleAfterInsert' );

        for ( Mass_Action_Job_Change_Event__e changeEvent : newList ) {

            MA_JobChangeEvent eventPayload = (MA_JobChangeEvent) JSON.deserialize( changeEvent.Payload__c, MA_JobChangeEvent.class );
            System.debug( 'MA_JobChangeEventTriggerHandler.handleAfterInsert: event=' + eventPayload );

            switch on ( eventPayload.scheduleChangeOperation ) {
                when SCHEDULE {
                    MA_MassActionScheduleUtils.scheduleMassActions( eventPayload.configIds );
                }
                when UNSCHEDULE {
                    MA_MassActionScheduleUtils.unscheduleMassActions( eventPayload.configIds );
                }
                when else {
                    System.debug( LoggingLevel.WARN, 'MA_JobChangeEventTriggerHandler.handleAfterInsert: Unexpected operation: ' + eventPayload.scheduleChangeOperation );
                }
            }

        }

    }

}
/*
BSD 3-Clause License

Copyright (c) 2017-2020, Doug Ayers, douglascayers.com
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