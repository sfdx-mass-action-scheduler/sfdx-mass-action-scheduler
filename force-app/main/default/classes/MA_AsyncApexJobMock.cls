/**
 * Author: Doug Ayers
 * Website: https://douglascayers.com
 * GitHub: https://github.com/douglascayers-org/sfdx-mass-action-scheduler
 * License: BSD 3-Clause License
 */
/*
 * Test coverage provided by MA_MassActionBatchUtilsTest.
 */
public inherited sharing class MA_AsyncApexJobMock {

    // These are fake job ids that parse via ID.valueOf()
    // but don't actually exist. This allows test/mock code
    // to instantiate AsyncApexJobs or pass job ids to methods
    // and reliably get back a test/mock job record later.
    // Checkmarx security scanner labels these "low risk hardcoded ids".
    // They are hardcoded on purpose for testing/mocking purposes.
    public static final ID QUEUED_JOB_ID                = '707f40000000001';
    public static final ID PREPARING_JOB_ID             = '707f40000000002';
    public static final ID PROCESSING_JOB_ID            = '707f40000000003';
    public static final ID ABORTED_JOB_ID               = '707f40000000004';
    public static final ID FAILED_JOB_ID                = '707f40000000005';
    public static final ID COMPLETED_JOB_ID             = '707f40000000006';
    public static final ID COMPLETED_WITH_ERRORS_JOB_ID = '707f40000000007';

    public static final Set<ID> MOCK_JOB_IDS = new Set<ID>{
        QUEUED_JOB_ID,
        PREPARING_JOB_ID,
        PROCESSING_JOB_ID,
        ABORTED_JOB_ID,
        FAILED_JOB_ID,
        COMPLETED_JOB_ID,
        COMPLETED_WITH_ERRORS_JOB_ID
    };

    private static final Map<ID, AsyncApexJob> MOCK_JOBS_MAP = new Map<ID, AsyncApexJob>{
        QUEUED_JOB_ID => mockJob( QUEUED_JOB_ID, 'Queued', null, null, null, null ),
        PREPARING_JOB_ID => mockJob( PREPARING_JOB_ID, 'Preparing', null, null, null, null ),
        PROCESSING_JOB_ID => mockJob( PROCESSING_JOB_ID, 'Processing', null, 2, 0, 0 ),
        ABORTED_JOB_ID => mockJob( ABORTED_JOB_ID, 'Aborted', null, 2, 1, 0 ),
        FAILED_JOB_ID => mockJob( FAILED_JOB_ID, 'Failed', 'Test Job Failed', 2, 0, 2 ),
        COMPLETED_JOB_ID => mockJob( COMPLETED_JOB_ID, 'Completed', null, 2, 2, 0 ),
        COMPLETED_WITH_ERRORS_JOB_ID => mockJob( COMPLETED_WITH_ERRORS_JOB_ID, 'Completed', 'Test Job Completed with Errors', 2, 0, 2 )
    };

    public static AsyncApexJob getJobById( ID jobId ) {
        return MOCK_JOBS_MAP.get( jobId );
    }

    private static AsyncApexJob mockJob( ID jobId, String status, String extendedStatus, Integer totalJobItems, Integer jobItemsProcessed, Integer numberOfErrors ) {
        // this object has non-writable fields so we use the json serialization trick to populate a mock record
        return (AsyncApexJob) JSON.deserialize( JSON.serialize( new Map<String, Object>{
            'Id' => jobId,
            'Status' => status,
            'ExtendedStatus' => extendedStatus,
            'TotalJobItems' => totalJobItems,
            'JobItemsProcessed' => jobItemsProcessed,
            'NumberOfErrors' => numberOfErrors,
            'CreatedDate' => DateTime.now(),
            'CompletedDate' => DateTime.now()
        }), AsyncApexJob.class );
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