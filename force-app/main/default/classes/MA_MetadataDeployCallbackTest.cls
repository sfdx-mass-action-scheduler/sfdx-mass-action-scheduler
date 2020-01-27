/**
 * Author: Doug Ayers
 * Website: https://douglascayers.com
 * GitHub: https://github.com/douglascayers-org/sfdx-mass-action-scheduler
 * License: BSD 3-Clause License
 */
@IsTest
private class MA_MetadataDeployCallbackTest {

    // https://trailhead.salesforce.com/content/learn/modules/apex_metadata_api/apex_metadata_api_testing

    @IsTest
    static void test_deploy_success() {

        Metadata.DeployCallbackContext deployContext = new MockMetadataDeployCallbackContext();

        Metadata.DeployResult deployResult = new Metadata.DeployResult();
        deployResult.success = true;

        Test.startTest();

        Metadata.DeployCallback callback = new MA_MetadataDeployCallback();
        callback.handleResult( deployResult, deployContext );

        Test.stopTest();

    }

    @IsTest
    static void test_deploy_fail() {

        Metadata.DeployCallbackContext deployContext = new MockMetadataDeployCallbackContext();

        Metadata.DeployResult deployResult = new Metadata.DeployResult();
        deployResult.success = false;
        deployResult.errorStatusCode = Metadata.StatusCode.INTERNAL_ERROR;
        deployResult.errorMessage = 'the error message';

        try {

            Test.startTest();

            Metadata.DeployCallback callback = new MA_MetadataDeployCallback();
            callback.handleResult( deployResult, deployContext );

            Test.stopTest();

            System.assert( false, 'should have thrown exception' );

        } catch ( MA_Exceptions.MetadataDeployException e ) {

            System.debug( LoggingLevel.ERROR, e.getMessage() + ' : ' + e.getStackTraceString() );
            System.assert( e.getMessage().containsIgnoreCase( String.valueOf( deployResult.errorStatusCode ) ) );
            System.assert( e.getMessage().containsIgnoreCase( deployResult.errorMessage ) );

        } catch ( Exception e ) {

            System.debug( LoggingLevel.ERROR, e.getMessage() + ' : ' + e.getStackTraceString() );
            System.assert( false, 'failed for wrong reason' );

        }

    }

    private class MockMetadataDeployCallbackContext extends Metadata.DeployCallbackContext {
        public override ID getCallbackJobId() {
            return '0Af00000000000TEST';
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