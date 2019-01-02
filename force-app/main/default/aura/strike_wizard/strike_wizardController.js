/*
Strike by Appiphony

Version: 0.8.0
Website: http://www.lightningstrike.io
GitHub: https://github.com/appiphony/Strike-Components
License: BSD 3-Clause License
*/
({
    init: function(component, event, helper) {
        var displayMode = component.get('v.displayMode').toLowerCase();
        helper.buildInitState(component, displayMode);
    },
    advanceButtonClick: function(component, event, helper) {
        if (component.get('v.processComplete')) return;
        if (component.get('v.error')) return;
        var currentChevron = component.get('v.currentChevron');
        helper.renderAdvanceButtonClick(component, currentChevron);
    },
    chevronClick: function(component, event, helper) {
        if (component.get('v.processComplete')) return;
        var targetChevron = Number(event.currentTarget.id);
        helper.moveToChevron(component, targetChevron);
    },
    changeChevronMethod: function(component, event, helper) {
        var params = event.getParam('arguments');
        helper.moveToChevron(component, params.targetChevron);
    },
    showErrorMethod: function(component, event, helper) {
        component.set('v.error', true);
    },
    hideErrorMethod: function(component, event, helper) {
        component.set('v.error', false);
    },
    toggleBody: function(component, event, helper) {
        component.set('v.toggleBodyView', !component.get('v.toggleBodyView'));
        var chevronBody = component.find("chevron-body");
        $A.util.toggleClass(chevronBody, "toggle");
    },
    toastMessage: function(component, event, helper) {
        helper.showToast(component, event)
    },
    handleErrorState: function(component, event, helper) {
        var error = event.getParam('value');
        (error) ? helper.showErrorState(component) : helper.hideErrorState(component);
    }
})
/*
Copyright 2017 Appiphony, LLC

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the
following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following
disclaimer.
2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following
disclaimer in the documentation and/or other materials provided with the distribution.
3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote
products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/