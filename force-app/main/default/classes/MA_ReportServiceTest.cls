/*
    Copyright (c) 2015 Salesforce.org
    All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Salesforce.com Foundation nor the names of
      its contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
    FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
    COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
    LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
    ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
    POSSIBILITY OF SUCH DAMAGE.
*/
/**
 * @author Salesforce.org
 * @group CampaignTools
 * @description A service class that provides methods for interacting with
 * reports via the Analytics API.
 *
 * This class has been modified by Doug Ayers for the purposes of the Mass Action app.
 * Test methods have been modified or added and assert based on reports packaged with this app.
 *
 * https://github.com/SalesforceFoundation/CampaignTools/blob/master/src/classes/ReportService_TEST.cls
 */
@IsTest
private class MA_ReportServiceTest {

    // the test report should filter for accounts whose name starts with this value
    private static final String ACCOUNT_NAME_PREFIX = 'dca_mass_action: MA Test Account';

    /**
     * Can't annotate this method with @TestSetup because not allowed
     * in test classes that use @IsTest( SeeAllData = true ).
     * Therefore our test methods must call this method explicitly.
     */
    static void setup() {

        // get rid of any data that might be in our test report's filters
        String nameFilter = ACCOUNT_NAME_PREFIX + '%';
        delete [ SELECT id FROM Account WHERE name LIKE :nameFilter ];

    }

    @IsTest( SeeAllData = true )
    static void testGetIdColumnsReturnsIdColumns() {

        setup();

        Map<String, String> expectedColumns = new Map<String, String>{
            'ACCOUNT_ID' => Schema.Account.Id.getDescribe().getLabel(),
            'PARENT_ID'  => Schema.Account.ParentId.getDescribe().getLabel()
        };

        Report testReport = [
            SELECT Id
            FROM Report
            WHERE DeveloperName = 'MA_Test_Account_Report'
        ];

        MA_ReportService service = new MA_ReportService();

        Map<String, String> actualColumns = service.getIdColumns( testReport.Id );

        System.assertEquals( expectedColumns, actualColumns );

    }

    @IsTest( SeeAllData = true )
    static void testReportIterable() {

        setup();

        Report testReport = [
            SELECT Id
            FROM Report
            WHERE DeveloperName = 'MA_Test_Account_Report'
        ];

        Test.startTest();

        Iterator<Reports.ReportDetailRow> reportRowIterator = new MA_ReportService.ReportRowIterator(
            testReport.Id,
            'ACCOUNT_ID'
        ).iterator();

        Test.stopTest();

    }

    /**
     * Due to bug introduced after https://success.salesforce.com/issues_view?Id=a1p3A000000ATHC was fixed,
     * the Reports.ReportManager.runReport method only sees records that exist in the org before the test runs.
     * Therefore, we cannot assert that the report sees any data we insert/update/delete in the test itself.
     */
    @IsTest( SeeAllData = true )
    static void testReportIterator() {

        String nameFilter = ACCOUNT_NAME_PREFIX + '%';
        Set<ID> expectedIds = new Map<ID, Account>([ SELECT Id FROM Account WHERE Name LIKE :nameFilter ]).keySet();

        List<String> expectedColumnNames = new List<String>{ 'ACCOUNT_ID', 'PARENT_ID' };

        Report testReport = [
            SELECT Id
            FROM Report
            WHERE DeveloperName = 'MA_Test_Account_Report'
        ];

        Test.startTest();

        MA_ReportService.ReportRowIterator reportRowIterator = new MA_ReportService.ReportRowIterator(
            testReport.Id,
            'ACCOUNT_ID'
        );

        Set<Id> actualIds = new Set<Id>();

        while ( reportRowIterator.hasNext() ) {
            actualIds.add( ( Id ) reportRowIterator.next().getDataCells().get( 0 ).getValue() );
        }

        Test.stopTest();

        System.assertEquals( expectedIds, actualIds );
        System.assertEquals( expectedColumnNames, reportRowIterator.getDetailColumnNames() );

    }

    /**
     * Due to bug introduced after https://success.salesforce.com/issues_view?Id=a1p3A000000ATHC was fixed,
     * the Reports.ReportManager.runReport method only sees records that exist in the org before the test runs.
     * Therefore, we cannot assert that the report sees any data we insert/update/delete in the test itself.
     */
    /*
    @IsTest( SeeAllData = true )
    static void testReportIterator() {

        setup();

        Account acct = new Account(
            name = ACCOUNT_NAME_PREFIX
        );

        insert acct;

        Set<Id> expectedIds = new Set<Id>{ acct.id };
        List<String> expectedColumnNames = new List<String>{ 'ACCOUNT_ID', 'PARENT_ID' };

        Report testReport = [
            SELECT Id
            FROM Report
            WHERE DeveloperName = 'MA_Test_Account_Report'
        ];

        Test.startTest();

        MA_ReportService.ReportRowIterator reportRowIterator = new MA_ReportService.ReportRowIterator(
            testReport.Id,
            'ACCOUNT_ID'
        );

        Set<Id> actualIds = new Set<Id>();

        while ( reportRowIterator.hasNext() ) {
            actualIds.add( ( Id ) reportRowIterator.next().getDataCells().get( 0 ).getValue() );
        }

        Test.stopTest();

        System.assertEquals( expectedIds, actualIds );
        System.assertEquals( expectedColumnNames, reportRowIterator.getDetailColumnNames() );
    }
    */

    /**
     * Due to bug introduced after https://success.salesforce.com/issues_view?Id=a1p3A000000ATHC was fixed,
     * the Reports.ReportManager.runReport method only sees records that exist in the org before the test runs.
     * Therefore, we cannot assert that the report sees any data we insert/update/delete in the test itself.
     */
    @IsTest( SeeAllData = true )
    static void testGetNextPageReportResults() {

        String nameFilter = ACCOUNT_NAME_PREFIX + '%';
        List<Account> accounts = [ SELECT Id FROM Account WHERE Name LIKE :nameFilter ORDER BY Id ASC ];
        ID firstAccountId = accounts[0].Id;

        // remove first account; when filter the report we expect all the other ids to be returned
        accounts.remove( 0 );
        Set<ID> expectedIds = new Map<ID, Account>( accounts ).keySet();

        Report testReport = [
            SELECT Id
            FROM Report
            WHERE DeveloperName = 'MA_Test_Account_Report'
        ];

        String columnName = 'ACCOUNT_ID';
        String pageIndex = firstAccountId; // report should return all rows with Ids after this one

        Test.startTest();

        Reports.ReportResults results = MA_ReportService.getReportResults( testReport.id, columnName, pageIndex );
        Reports.ReportFactWithDetails facts = ( Reports.ReportFactWithDetails ) results.getFactMap().get( 'T!T' );
        Iterator<Reports.ReportDetailRow> reportRowIterator = facts.getRows().iterator();

        Set<Id> actualIds = new Set<Id>();

        while ( reportRowIterator.hasNext() ) {
            actualIds.add( ( Id ) reportRowIterator.next().getDataCells().get( 0 ).getValue() );
        }

        Test.stopTest();

        System.assertEquals( expectedIds, actualIds );

    }

    /**
     * Due to bug introduced after https://success.salesforce.com/issues_view?Id=a1p3A000000ATHC was fixed,
     * the Reports.ReportManager.runReport method only sees records that exist in the org before the test runs.
     * Therefore, we cannot assert that the report sees any data we insert/update/delete in the test itself.
     */
    /*
    @IsTest( SeeAllData = true )
    static void testGetNextPageReportResults() {

        setup();

        Account acct1 = new Account(
            name = ACCOUNT_NAME_PREFIX + '1'
        );

        Account acct2 = new Account(
            name = ACCOUNT_NAME_PREFIX + '2'
        );

        insert new Account[] { acct1, acct2 };

        Set<Id> expectedIds = new Set<Id>{ acct2.id };

        Report testReport = [
            SELECT Id
            FROM Report
            WHERE DeveloperName = 'MA_Test_Account_Report'
        ];

        String columnName = 'ACCOUNT_ID';
        String pageIndex = acct1.id; // report should return all rows with Ids after this one

        Test.startTest();

        Reports.ReportResults results = MA_ReportService.getReportResults( testReport.id, columnName, pageIndex );
        Reports.ReportFactWithDetails facts = ( Reports.ReportFactWithDetails ) results.getFactMap().get( 'T!T' );
        Iterator<Reports.ReportDetailRow> reportRowIterator = facts.getRows().iterator();

        Set<Id> actualIds = new Set<Id>();

        while ( reportRowIterator.hasNext() ) {
            actualIds.add( ( Id ) reportRowIterator.next().getDataCells().get( 0 ).getValue() );
        }

        Test.stopTest();

        System.assertEquals( expectedIds, actualIds );

    }
    */

}