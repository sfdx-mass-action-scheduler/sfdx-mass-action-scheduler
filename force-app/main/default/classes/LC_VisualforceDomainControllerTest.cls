/*
Author: Doug Ayers
Website: https://douglascayers.com
GitHub: https://github.com/douglascayers/sfdx-lightning-api-component
License: BSD 3-Clause License
 */
@IsTest
private class LC_VisualforceDomainControllerTest {

    // Aura Component

    @IsTest
    static void test_get_visualforce_domain_url() {

        Test.startTest();

        String vfDomainURL = LC_VisualforceDomainController.getVisualforceDomainURL();

        System.assertEquals( 'https://visualforce.com', vfDomainURL );

        Test.stopTest();

    }

    // -----------------------------------------------------------------------------

    // Visualforce Page

    @IsTest
    static void test_get_domain_url() {

        Test.setCurrentPage( Page.LC_VisualforceDomainPage );

        Test.startTest();

        LC_VisualforceDomainController controller = new LC_VisualforceDomainController();

        String domainURL = controller.getDomainURL();

        // The test is not running in Visualforce context,
        // so best we can get here is domain in Apex context.
        System.assertEquals( URL.getSalesforceBaseUrl().toExternalForm(), domainURL );

        Test.stopTest();

    }

}
/*
BSD 3-Clause License

Copyright (c) 2018, Doug Ayers, douglascayers.com
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