/**
 * Author: Doug Ayers
 * Website: https://douglascayers.com
 * GitHub: https://github.com/DouglasCAyers/sfdx-mass-action-scheduler
 * License: BSD 3-Clause License
 */
global class MA_RunConfigInvocable {

    @InvocableMethod(
        label = 'Run Mass Action'
        description = 'Submits background job to run a Mass Action Configuration.'
    )
    global static List<Response> execute( List<Request> requests ) {

        List<Response> responses = new List<Response>();

        for ( Request req : requests ) {

            System.debug( req );

            Response res = new Response();
            res.jobId = MA_MassActionBatchUtils.enqueueAction( req.configId );
            responses.add( res );

            System.debug( res );

        }

        return responses;
    }

    // ------------------------------------------------------------

    global class Request {

        @InvocableVariable(
            label = 'Mass Action Configuration ID'
            description = 'The Salesforce record ID of the Mass Action Configuration to run.'
            required = true
        )
        global ID configId;

    }

    global class Response {

        @InvocableVariable(
            label = 'Job ID'
            description = 'The ID of the background apex job processing the Mass Action request.'
        )
        global ID jobId;

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