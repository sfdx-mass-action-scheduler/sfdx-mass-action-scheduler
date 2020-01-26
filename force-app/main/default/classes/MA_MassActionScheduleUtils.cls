/**
 * Author: Doug Ayers
 * Website: https://douglascayers.com
 * GitHub: https://github.com/douglascayers-org/sfdx-mass-action-scheduler
 * License: BSD 3-Clause License
 */
/**
 * Most code coverage comes from MA_JobChangeEventTriggerHandlerTest
 */
public inherited sharing class MA_MassActionScheduleUtils {

    public static void unscheduleMassActions( List<ID> configIds ) {

        System.debug( 'MA_MassActionScheduleUtils.unscheduleMassActions: ' + configIds );

        configIds = ( configIds == null ? new List<ID>() : configIds );

        Set<String> jobNames = new Set<String>();
        for ( ID configId : configIds ) {
            // Due to oddity with JSON roundtrip serialization of IDs
            // ending up as 15-char IDs instead of 18-char IDs, then
            // explicitly converting the value to an ID to get back to 18-char version.
            // Otherwise, our SOQL query won't find the job names.
            // https://releasenotes.docs.salesforce.com/en-us/winter16/release-notes/rn_apex_json_ids.htm
            jobNames.add( 'MA_MassAction_' + ID.valueOf( configId ) );
        }

        for ( List<CronTrigger> cronTriggers : [
            SELECT
                Id, State, CronJobDetail.Name
            FROM
                CronTrigger
            WHERE
                CronJobDetail.Name IN :jobNames
        ]) {

            for ( CronTrigger cronTrigger : cronTriggers ) {

                System.debug( 'MA_MassActionScheduleUtils.unscheduleMassActions: Aborting job: ' + JSON.serializePretty( cronTrigger ) );
                System.abortJob( cronTrigger.Id );

            }

        }

    }

    public static void scheduleMassActions( List<ID> configIds ) {

        System.debug( 'MA_MassActionScheduleUtils.scheduleMassActions: ' + configIds );

        configIds = ( configIds == null ? new List<ID>() : configIds );

        List<Mass_Action_Configuration__c> configs = new List<Mass_Action_Configuration__c>([
            SELECT
                Id,
                Schedule_Cron__c,
                Schedule_Frequency__c,
                Schedule_SecondOfMinute__c,
                Schedule_MinuteOfHour__c,
                Schedule_HourOfDay__c,
                Schedule_DayOfMonth__c,
                Schedule_MonthOfYear__c,
                Schedule_DayOfWeek__c
            FROM
                Mass_Action_Configuration__c
            WHERE
                Id IN :configIds
        ]);

        for ( Mass_Action_Configuration__c config : configs ) {

            String jobName = 'MA_MassAction_' + config.Id;
            String cron = buildCron( config );

            System.debug( 'MA_MassActionScheduleUtils.scheduleMassActions: Scheduling job: jobName=' + jobName + ', cron=' + cron );
            ID jobId = System.schedule( jobName, cron, new MA_MassActionSchedulable( config.Id ) );
            System.debug( 'MA_MassActionScheduleUtils.scheduleMassActions: Scheduled job: ' + jobId );

        }

    }

    public static String buildCron( Mass_Action_Configuration__c config ) {

        System.debug( 'MA_MassActionScheduleUtils.buildCron: ' + config );

        String cron = '';

        if ( config.Schedule_Frequency__c == 'Scheduled' ) {

            cron = String.format(
                '{0} {1} {2} {3} {4} {5}',
                new String[] {
                    config.Schedule_SecondOfMinute__c,
                    config.Schedule_MinuteOfHour__c,
                    config.Schedule_HourOfDay__c,
                    config.Schedule_DayOfMonth__c,
                    config.Schedule_MonthOfYear__c,
                    config.Schedule_DayOfWeek__c
                }
            );

        } else if ( config.Schedule_Frequency__c == 'Custom' ) {

            cron = config.Schedule_Cron__c;

        }

        System.debug( 'MA_MassActionScheduleUtils.buildCron: cron=' + cron );

        return cron;
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