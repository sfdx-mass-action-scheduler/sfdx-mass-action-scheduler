/**
 * Author: Doug Ayers
 * Website: https://douglascayers.com
 * GitHub: https://github.com/douglascayers/sfdx-mass-action-scheduler
 * License: BSD 3-Clause License
 */
public inherited sharing class MA_AsyncApexJobMock {

    public static final ID PASS_JOB_ID = '707f4000000PASS';
    public static final ID FAIL_JOB_ID = '707f4000000FAIL';

    public static final Set<ID> MOCK_JOB_IDS = new Set<ID>{
        PASS_JOB_ID, FAIL_JOB_ID
    };

    public static AsyncApexJob getJobById( ID jobId ) {

        AsyncApexJob job;

        if ( jobId == PASS_JOB_ID ) {

            // this object has non-writable fields so we use the json serialization trick to populate a mock record
            job = (AsyncApexJob) JSON.deserialize( JSON.serialize( new Map<String, Object>{
                'Id' => jobId,
                'ExtendedStatus' => 'Test Job Success',
                'TotalJobItems' => 1,
                'TotalJobItems' => 1,
                'NumberOfErrors' => 0,
                'CreatedDate' => DateTime.now(),
                'CompletedDate' => DateTime.now()
            }), AsyncApexJob.class );

        } else if ( jobId == FAIL_JOB_ID ) {

            // this object has non-writable fields so we use the json serialization trick to populate a mock record
            job = (AsyncApexJob) JSON.deserialize( JSON.serialize( new Map<String, Object>{
                'Id' => jobId,
                'ExtendedStatus' => 'Test Job Failure',
                'TotalJobItems' => 1,
                'JobItemsProcessed' => 1,
                'NumberOfErrors' => 1,
                'CreatedDate' => DateTime.now(),
                'CompletedDate' => DateTime.now()
            }), AsyncApexJob.class );

        }

        return job;
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