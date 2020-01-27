/**
 * Author: Doug Ayers
 * Website: https://douglascayers.com
 * GitHub: https://github.com/douglascayers-org/sfdx-mass-action-scheduler
 * License: BSD 3-Clause License
 */
public with sharing class MA_ReportSourceBatchable implements Database.Batchable<Reports.ReportDetailRow>,
                                                              Database.Stateful,
                                                              Database.AllowsCallouts,
                                                              Database.RaisesPlatformEvents {

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

        this.reportDescribe = Reports.ReportManager.describeReport( config.Source_Report_ID__c );

        Iterable<Reports.ReportDetailRow> reportIterable = new MA_ReportService.ReportRowIterator( this.config.Source_Report_ID__c, this.config.Source_Report_Column_Name__c );

        MA_MassActionBatchUtils.handleBatchJobStarted( this.configId, context.getJobId() );

        return reportIterable;
    }

    public void execute( Database.BatchableContext context, List<Reports.ReportDetailRow> reportRows ) {

        System.debug( 'MA_ReportSourceBatchable.execute: ' + context + ', configId=' + this.configId );

        List<Map<String, Object>> sourceRowMaps = convertReportRowsToMaps( reportRows, this.reportDescribe );

        MA_MassActionUtils.invokeTargetAction( this.config, sourceRowMaps );

        MA_MassActionBatchUtils.handleBatchJobExecution( this.configId, context.getJobId(), reportRows.size(), JSON.serializePretty( sourceRowMaps ) );

    }

    public void finish( Database.BatchableContext context ) {

        System.debug( 'MA_ReportSourceBatchable.finish: ' + context + ', configId=' + this.configId );

        MA_MassActionBatchUtils.handleBatchJobFinished( this.configId, context.getJobId() );

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
        Map<String,Reports.DetailColumn> detailColumnsMap = reportDescribe.getReportExtendedMetadata().getDetailColumnInfo();
        List<Reports.ReportDataCell> dataCells = rowData.getDataCells();

        for ( Integer i = 0; i < columnNames.size(); i++ ) {

            String columnName = columnNames[i];
            Reports.ReportDataCell dataCell = dataCells[i];
            Reports.DetailColumn detailColumn = detailColumnsMap.get( columnName );

            Object cellValue = extractCellValue( dataCell.getLabel(), dataCell.getValue(), detailColumn.getDataType() );

            rowMap.put( columnName, cellValue );

        }

        return rowMap;
    }

    /**
     * Returns the raw value from the cell based on the column data type
     * and not simply the localized value displayed to the user.
     *
     * For example, consistently return a DateTime object and not
     * "January 3rd, 2019" or "03/01/2019" as Strings depending on the user's locale.
     *
     * To aid in testability, this method accepts as arguments the simple properties of Reports.ReportDataCell
     * because that object cannot be mocked or spoofed via JSON deserialization.
     *
     * @param cellLabel
     *      The localized value the user sees in the report
     * @param cellValue
     *      The raw value, might be a compound type like Reports.ReportCurrency
     * @param columnDataType
     *      Enum of the different data types the column value could represent
     *
     * @return The value to use when binding to invocable action inputs,
     *         which might be the `cellLabel`, `cellValue`, or a property off
     *         the complex-type `cellValue` like currency amount without the symbol.
     */
    @TestVisible
    private static Object extractCellValue( String cellLabel, Object cellValue, Reports.ColumnDataType columnDataType ) {

        Object extractedValue = null;

            switch on ( columnDataType ) {

                when BOOLEAN_DATA {
                    // important to grab the value and not the label
                    // otherwise get the text literal "true"/false
                    // instead of the boolean true/false
                    // which led to https://github.com/douglascayers-org/sfdx-mass-action-scheduler/issues/64
                    extractedValue = cellValue;
                }

                when DATE_DATA {
                    // important to grab the value and not the label
                    // because label will be formatted in running user's locale
                    // and will fail to map to date inputs on target action
                    extractedValue = cellValue;
                }

                when DATETIME_DATA {
                    // important to grab the value and not the label
                    // because label will be formatted in running user's locale
                    // and will fail to map to date inputs on target action
                    extractedValue = cellValue;
                }

                when CURRENCY_DATA {
                    // grab the numerical amount instead
                    // instead of the label which is text formatted with currency symbol
                    // this allows the cell value to map to currency inputs on target action
                    Reports.ReportCurrency currencyData = (Reports.ReportCurrency) cellValue;
                    if ( currencyData != null ) {
                        extractedValue = currencyData.getAmount();
                    }
                }

                when INT_DATA {
                    extractedValue = cellValue;
                }

                when DOUBLE_DATA {
                    extractedValue = cellValue;
                }

                when PERCENT_DATA {
                    extractedValue = cellValue;
                }

                when else {
                    // otherwise, use the display label
                    // this is important for Name field columns
                    // so you get the record's name and not its id
                    extractedValue = cellLabel;
                }

            }

        return extractedValue;
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