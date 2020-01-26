/**
 * Author: Doug Ayers
 * Website: https://douglascayers.com
 * GitHub: https://github.com/douglascayers-org/sfdx-mass-action-scheduler
 * License: BSD 3-Clause License
 */
public with sharing class MA_MassActionSchedulable implements System.Schedulable, Database.AllowsCallouts {

    private ID configId { get; set; }

    public MA_MassActionSchedulable( ID configId ) {
        this.configId = configId;
    }

    public void execute( System.SchedulableContext context ) {

        System.debug( 'MA_MassActionSchedulable.execute: ' + context + ', configId=' + this.configId );

        /*
         * Apex that is scheduled or code that is explicitly called by scheduled apex
         * is not updateable and throws error "This schedulable class has jobs pending or in progress".
         * The workaround is to use a dispatcher design pattern that dynamically looks up a handler class,
         * thereby avoiding the apex lock on the handler code so that it is updateable.
         * https://help.salesforce.com/articleView?id=000004423&language=en_US&type=1
         * https://salesforce.stackexchange.com/questions/33838/scheduled-batch-job-from-installhandler-and-further-upgrades-of-managed-package
         * https://salesforce.stackexchange.com/questions/24446/how-to-deploy-apex-classes-that-are-scheduled
         */

        Type enqueuer = Type.forName( 'MA_MassActionBatchEnqueuer' );

        MA_MassActionSchedulableDispatched dispatched = (MA_MassActionSchedulableDispatched) enqueuer.newInstance();
        dispatched.execute( context, this.configId );

    }

    // ----------------------------------------------------

    public interface MA_MassActionSchedulableDispatched {

        void execute( System.SchedulableContext context, ID configId );

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