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