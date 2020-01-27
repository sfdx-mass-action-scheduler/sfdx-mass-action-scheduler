/**
 * Author: Doug Ayers
 * Website: https://douglascayers.com
 * GitHub: https://github.com/douglascayers-org/sfdx-mass-action-scheduler
 * License: BSD 3-Clause License
 */
/*
 * To simplify efforts to have one code base that can be open source
 * and in a managed package, and the code not have to know about any
 * namespace then rather than serialize custom sobjects or fields to
 * our Lightning Components we instead have an abstraction layer.
 *
 * Regardless the namespace of the org the code is deployed into,
 * the Lightning Compnent javascript can always reference attributes
 * from this class without worry.
 *
 * Test code coverage provided by MA_EditConfigCmpControllerTest.
 */
public inherited sharing class MA_MassActionConfigWrapper {

    @AuraEnabled
    public ID recordId { get; set; }

    @AuraEnabled
    public ID ownerId { get; set; }

    @AuraEnabled
    public String name { get; set; }

    @AuraEnabled
    public String developerName { get; set; }

    @AuraEnabled
    public String namedCredential { get; set; }

    @AuraEnabled
    public Boolean active { get; set; }

    @AuraEnabled
    public Integer batchSize { get; set; }

    @AuraEnabled
    public String description { get; set; }

    // source

    @AuraEnabled
    public String sourceType { get; set; }

    @AuraEnabled
    public String sourceReportID { get; set; }

    @AuraEnabled
    public String sourceReportColumnName { get; set; }

    @AuraEnabled
    public String sourceListViewID { get; set; }

    @AuraEnabled
    public String sourceSoqlQuery { get; set; }

    @AuraEnabled
    public String sourceApexClass { get; set; }

    // target

    @AuraEnabled
    public String targetType { get; set; }

    @AuraEnabled
    public String targetSobjectType { get; set; }

    @AuraEnabled
    public String targetActionName { get; set; }

    @AuraEnabled
    public String targetApexScript { get; set; }

    // schedule

    @AuraEnabled
    public String scheduleFrequency { get; set; }

    @AuraEnabled
    public String scheduleCron { get; set; }

    @AuraEnabled
    public String scheduleSecondOfMinute { get; set; }

    @AuraEnabled
    public String scheduleMinuteOfHour { get; set; }

    @AuraEnabled
    public String scheduleHourOfDay { get; set; }

    @AuraEnabled
    public String scheduleDayOfMonth { get; set; }

    @AuraEnabled
    public String scheduleMonthOfYear { get; set; }

    @AuraEnabled
    public String scheduleDayOfWeek { get; set; }

    // system

    @AuraEnabled
    public ID createdById { get; set; }

    @AuraEnabled
    public DateTime createdDate { get; set; }

    @AuraEnabled
    public ID lastModifiedById { get; set; }

    @AuraEnabled
    public DateTime lastModifiedDate { get; set; }

    @AuraEnabled
    public List<FieldMappingWrapper> fieldMappings { get; set; }

    public MA_MassActionConfigWrapper() { }

    public MA_MassActionConfigWrapper( Mass_Action_Configuration__c config ) {

        this.fieldMappings = new List<FieldMappingWrapper>();

        // defaults
        this.active = true;
        this.batchSize = 200;

        if ( config != null ) {

            this.recordId = config.Id;
            this.ownerId = config.OwnerId;
            this.name = config.Name;
            this.developerName = config.DeveloperName__c;
            this.namedCredential = config.Named_Credential__c;
            this.active = ( config.Active__c == null ? this.active : config.Active__c );
            this.batchSize = ( config.Batch_Size__c == null ? this.batchSize : config.Batch_Size__c.intValue() );
            this.description = config.Description__c;
            // source
            this.sourceType = config.Source_Type__c;
            this.sourceReportID = config.Source_Report_ID__c;
            this.sourceReportColumnName = config.Source_Report_Column_Name__c;
            this.sourceListViewID = config.Source_List_View_ID__c;
            this.sourceSoqlQuery = config.Source_SOQL_Query__c;
            this.sourceApexClass = config.Source_Apex_Class__c;
            // target
            this.targetType = config.Target_Type__c;
            this.targetSobjectType = config.Target_SObject_Type__c;
            this.targetActionName = config.Target_Action_Name__c;
            this.targetApexScript = config.Target_Apex_Script__c;
            // schedule
            this.scheduleFrequency = config.Schedule_Frequency__c;
            this.scheduleCron = config.Schedule_Cron__c;
            this.scheduleSecondOfMinute = config.Schedule_SecondOfMinute__c;
            this.scheduleMinuteOfHour = config.Schedule_MinuteOfHour__c;
            this.scheduleHourOfDay = config.Schedule_HourOfDay__c;
            this.scheduleDayOfMonth = config.Schedule_DayOfMonth__c;
            this.scheduleMonthOfYear = config.Schedule_MonthOfYear__c;
            this.scheduleDayOfWeek = config.Schedule_DayOfWeek__c;
            // system
            this.createdById = config.CreatedById;
            this.createdDate = config.CreatedDate;
            this.lastModifiedById = config.LastModifiedById;
            this.lastModifiedDate = config.LastModifiedDate;

            for ( Mass_Action_Mapping__c mapping : config.Mass_Action_Mappings__r ) {
                this.fieldMappings.add( new FieldMappingWrapper( mapping ) );
            }

        }

    }

    public Mass_Action_Configuration__c toConfiguration() {

        Mass_Action_Configuration__c config = new Mass_Action_Configuration__c(
            Name = this.name,
            DeveloperName__c = this.developerName,
            Named_Credential__c = this.namedCredential,
            Active__c = ( this.active == null ? true : this.active ),
            Batch_Size__c = ( this.batchSize == null ? 200 : this.batchSize ),
            Description__c = this.description,
            // source
            Source_Type__c = this.sourceType,
            Source_Report_ID__c = this.sourceReportID,
            Source_Report_Column_Name__c = this.sourceReportColumnName,
            Source_List_View_ID__c = this.sourceListViewID,
            Source_SOQL_Query__c = this.sourceSoqlQuery,
            Source_Apex_Class__c = this.sourceApexClass,
            // target
            Target_Type__c = this.targetType,
            Target_SObject_Type__c = this.targetSobjectType,
            Target_Action_Name__c = this.targetActionName,
            Target_Apex_Script__c = this.targetApexScript,
            // schedule
            Schedule_Frequency__c = this.scheduleFrequency,
            Schedule_Cron__c = this.scheduleCron,
            Schedule_SecondOfMinute__c = this.scheduleSecondOfMinute,
            Schedule_MinuteOfHour__c = this.scheduleMinuteOfHour,
            Schedule_HourOfDay__c = this.scheduleHourOfDay,
            Schedule_DayOfMonth__c = this.scheduleDayOfMonth,
            Schedule_MonthOfYear__c = this.scheduleMonthOfYear,
            Schedule_DayOfWeek__c = this.scheduleDayOfWeek
        );

        // some fields need to not be "set" otherwise will cause errors if set to null
        // so only if there are actual values to assign then we leave these unset
        if ( String.isNotBlank( this.recordId ) ) {
            config.Id = this.recordId;
        }

        if ( String.isNotBlank( this.ownerId ) ) {
            config.OwnerId = this.ownerId;
        }

        return config;
    }

    public inherited sharing class FieldMappingWrapper {

        @AuraEnabled
        public String sourceFieldName { get; set; }

        @AuraEnabled
        public String targetFieldName { get; set; }

        public FieldMappingWrapper( Mass_Action_Mapping__c mapping ) {
            this.sourceFieldName = mapping.Source_Field_Name__c;
            this.targetFieldName = mapping.Target_Field_Name__c;
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