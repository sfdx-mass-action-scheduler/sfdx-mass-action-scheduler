/**
 * Author: Doug Ayers
 * Website: https://douglascayers.com
 * GitHub: https://github.com/douglascayers-org/sfdx-mass-action-scheduler
 * License: BSD 3-Clause License
 */
public with sharing class MA_MassActionConfigTriggerHandler {

    public MA_MassActionConfigTriggerHandler() {}

    // -------------------------------------------------------
    // INSERT
    // -------------------------------------------------------

    public void handleBeforeInsert( List<Mass_Action_Configuration__c> newList ) {

        // no logic yet

    }

    public void handleAfterInsert( List<Mass_Action_Configuration__c> newList, Map<ID, Mass_Action_Configuration__c> newMap ) {

        List<Mass_Action_Configuration__c> configsToSchedule = new List<Mass_Action_Configuration__c>();

        for ( Mass_Action_Configuration__c newConfig : newList ) {

            if ( newConfig.Active__c && newConfig.Schedule_Frequency__c != 'Manual' ) {
                configsToSchedule.add( newConfig );
            }

        }

        if ( configsToSchedule.size() > 0 ) {
            scheduleMassActions( configsToSchedule );
        }

    }

    // -------------------------------------------------------
    // UPDATE
    // -------------------------------------------------------

    public void handleBeforeUpdate( List<Mass_Action_Configuration__c> oldList, Map<ID, Mass_Action_Configuration__c> oldMap,
                                    List<Mass_Action_Configuration__c> newList, Map<ID, Mass_Action_Configuration__c> newMap ) {

        // no logic yet

    }

    public void handleAfterUpdate( List<Mass_Action_Configuration__c> oldList, Map<ID, Mass_Action_Configuration__c> oldMap,
                                   List<Mass_Action_Configuration__c> newList, Map<ID, Mass_Action_Configuration__c> newMap ) {

        List<Mass_Action_Configuration__c> configsToReschedule = new List<Mass_Action_Configuration__c>();
        List<Mass_Action_Configuration__c> configsToUnschedule = new List<Mass_Action_Configuration__c>();

        for ( Mass_Action_Configuration__c newConfig : newList ) {

            Mass_Action_Configuration__c oldConfig = oldMap.get( newConfig.Id );

            System.debug( 'MA_MassActionConfigTriggerHandler.handleAfterUpdate: newConfig: ' + newConfig );
            System.debug( 'MA_MassActionConfigTriggerHandler.handleAfterUpdate: oldConfig: ' + oldConfig );

            if ( newConfig.Active__c && newConfig.Schedule_Frequency__c != 'Manual' ) {

                // Since Spring '15, code coverage calculations may not count multi-line statements
                // if the actual expression is never evaluated (e.g. if condition short-circuit)
                // so I can either make this one super long single statement, make multiple boolean expressions
                // that will be evaluated everytime, or create several test permutations.
                // Creating all possible test permutations probably is the "better practice" but
                // considering they are all just testing if two values don't match I think that's overkill.
                // So I'm opting for multiple boolean expressions that will always be evaluated to ensure coverage.
                // https://releasenotes.docs.salesforce.com/en-us/summer15/release-notes/rn_apex_expressions_coverage.htm
                // https://twitter.com/DouglasCAyers/status/942635375939538944

                Boolean activeChanged = ( oldConfig.Active__c != newConfig.Active__c );
                Boolean frequencyChanged = ( oldConfig.Schedule_Frequency__c != newConfig.Schedule_Frequency__c );
                Boolean cronChanged = ( oldConfig.Schedule_Cron__c != newConfig.Schedule_Cron__c );
                Boolean secondChanged = ( oldConfig.Schedule_SecondOfMinute__c != newConfig.Schedule_SecondOfMinute__c );
                Boolean minuteChanged = ( oldConfig.Schedule_MinuteOfHour__c != newConfig.Schedule_MinuteOfHour__c );
                Boolean hourChanged = ( oldConfig.Schedule_HourOfDay__c != newConfig.Schedule_HourOfDay__c );
                Boolean dayOfWeekChanged = ( oldConfig.Schedule_DayOfWeek__c != newConfig.Schedule_DayOfWeek__c );
                Boolean dayOfMonthChanged = ( oldConfig.Schedule_DayOfMonth__c != newConfig.Schedule_DayOfMonth__c );
                Boolean monthOfYearChanged = ( oldConfig.Schedule_MonthOfYear__c != newconfig.Schedule_MonthOfYear__c );

                Boolean reschedule = ( activeChanged || frequencyChanged || cronChanged || secondChanged || minuteChanged || hourChanged || dayOfWeekChanged || dayOfMonthChanged || monthOfYearChanged );

                if ( reschedule ) {
                    configsToReschedule.add( newConfig );
                }

            } else {

                configsToUnschedule.add( newConfig );

            }

        }

        if ( configsToReschedule.size() > 0 ) {
            rescheduleMassActions( configsToReschedule );
        }

        if ( configsToUnschedule.size() > 0 ) {
            unscheduleMassActions( configsToUnschedule );
        }

    }

    // -------------------------------------------------------
    // DELETE
    // -------------------------------------------------------

    public void handleBeforeDelete( List<Mass_Action_Configuration__c> oldList, Map<ID, Mass_Action_Configuration__c> oldMap ) {

        // no logic yet

    }

    public void handleAfterDelete( List<Mass_Action_Configuration__c> oldList, Map<ID, Mass_Action_Configuration__c> oldMap ) {

        unscheduleMassActions( oldList );

    }

    // -------------------------------------------------------

    private static void rescheduleMassActions( List<Mass_Action_Configuration__c> configs ) {

        System.debug( 'MA_MassActionConfigTriggerHandler.rescheduleMassActions' );

        unscheduleMassActions( configs );
        scheduleMassActions( configs );

    }

    private static void unscheduleMassActions( List<Mass_Action_Configuration__c> configs ) {

        System.debug( 'MA_MassActionConfigTriggerHandler.unscheduleMassActions' );

        // publishJobChangeEvent( configs, MA_JobChangeEvent.ScheduleOperation.UNSCHEDULE );
        MA_MassActionScheduleUtils.unscheduleMassActions( toIds( configs ) );

    }

    private static void scheduleMassActions( List<Mass_Action_Configuration__c> configs ) {

        System.debug( 'MA_MassActionConfigTriggerHandler.scheduleMassActions' );

        // publishJobChangeEvent( configs, MA_JobChangeEvent.ScheduleOperation.SCHEDULE );
        MA_MassActionScheduleUtils.scheduleMassActions( toIds( configs ) );

    }

    private static List<ID> toIds( List<SObject> records ) {
        List<ID> ids = new List<ID>();
        for ( SObject record : records ) {
            ids.add( record.Id );
        }
        return ids;
    }

    /**
     * When users save Mass Action Configurations using the MA_EditConfigCmp component,
     * it invokes our custom Apex REST endpoint via the LC_API component. Therefore, this
     * trigger handler ends up being invoked from within the execution context of Apex REST.
     *
     * Due to known issue that execution contexts started from Apex REST endpoints
     * cannot schedule or abort jobs, then our workaround is to use platform events
     * to move into another execution context.
     * https://success.salesforce.com/issues_view?id=a1p30000000SyhIAAS
     */
    /*
    private static void publishJobChangeEvent( List<Mass_Action_Configuration__c> configs, MA_JobChangeEvent.ScheduleOperation scheduleOperation ) {

        System.debug( 'MA_MassActionConfigTriggerHandler.publishJobChangeEvent' );
        System.debug( 'scheduleOperation=' + scheduleOperation );

        MA_JobChangeEvent eventPayload = new MA_JobChangeEvent();
        eventPayload.configIds = new List<ID>( new Map<ID, Mass_Action_Configuration__c>( configs ).keySet() );
        eventPayload.scheduleChangeOperation = scheduleOperation;

        EventBus.publish( new Mass_Action_Job_Change_Event__e(
            Payload__c = JSON.serialize( eventPayload )
        ));

    }
    */

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