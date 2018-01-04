/**
 * Author: Doug Ayers
 * Website: https://douglascayers.com
 * GitHub: https://github.com/DouglasCAyers/sfdx-mass-action-scheduler
 * License: BSD 3-Clause License
 */
public with sharing class MA_ReportSourceBatchable implements Database.Batchable<Reports.ReportDetailRow>, Database.Stateful, Database.AllowsCallouts {

    private ID configId { get; set; }

    private Mass_Action_Configuration__c config { get; set; }

    private Reports.ReportDescribeResult reportDescribe { get; set; }

    public MA_ReportSourceBatchable( ID configId ) {
        this.configId = configId;
    }

    // ------------------------------------------------------------------------

    public Iterable<Reports.ReportDetailRow> start( Database.BatchableContext context ) {

        System.debug( 'MA_ReportSourceBatchable.start: ' + context + ', configId=' + this.configId );

        this.config = MA_MassActionUtils.getConfiguration( this.configId );

        this.reportDescribe = Reports.ReportManager.describeReport( config.source_report_id__c );

        return new MA_ReportService.ReportRowIterator( this.config.source_report_id__c, this.config.source_report_column_name__c );
    }

    public void execute( Database.BatchableContext context, List<Reports.ReportDetailRow> sourceRows ) {

        try {

            System.debug( 'MA_ReportSourceBatchable.execute: ' + context + ', configId=' + this.configId );

            List<Map<String, Object>> sourceRowMaps = convertReportRowsToMaps( sourceRows, this.reportDescribe );

            List<Map<String, Object>> targetRowMaps = MA_MassActionUtils.buildActionInputs( sourceRowMaps, this.config.mass_action_mappings__r );

            MA_MassActionUtils.invokeAction( this.config, targetRowMaps );

        } catch ( Exception e ) {

            System.debug( LoggingLevel.ERROR, e.getMessage() + ' : ' + e.getStackTraceString() );

            MA_MassActionBatchUtils.logJobException( this.config.Id, context.getJobId(), e );

        }

    }

    public void finish( Database.BatchableContext context ) {

        System.debug( 'MA_ReportSourceBatchable.finish: ' + context + ', configId=' + this.configId );

        MA_MassActionBatchUtils.logJobErrors( this.config.Id, context.getJobId() );

    }

    // ------------------------------------------------------------------------

    private List<Map<String, Object>> convertReportRowsToMaps( List<Reports.ReportDetailRow> rows, Reports.ReportDescribeResult reportDescribe ) {

        List<Map<String, Object>> maps = new List<Map<String, Object>>();

        for ( Reports.ReportDetailRow row : rows ) {
            maps.add( convertReportRowToMap( row, reportDescribe ) );
        }

        return maps;
    }

    private Map<String, Object> convertReportRowToMap( Reports.ReportDetailRow rowData, Reports.ReportDescribeResult reportDescribe ) {

        Map<String, Object> rowMap = new Map<String, Object>();

        List<String> columnNames = reportDescribe.getReportMetadata().getDetailColumns();

        List<Reports.ReportDataCell> dataCells = rowData.getDataCells();

        for ( Integer i = 0; i < columnNames.size(); i++ ) {

            Reports.ReportDataCell dataCell = dataCells[i];

            // a report row data cell's value typically is either the record id, picklist value, or null
            // the label has the actual data that is displayed in the report
            // if the cell value is null then the label is actually a placeholder hyphen '-' so we check for that to remain null
            // so that we don't inadvertently pass a non-null value into target actions when the value truly is null
            rowMap.put( columnNames[i], ( dataCell.getValue() != null ? dataCell.getLabel() : null ) );

        }

        return rowMap;
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