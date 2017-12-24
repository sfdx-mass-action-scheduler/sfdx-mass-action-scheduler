({
    init: function (component, event, helper) {
        helper.calculateNubbinPlacement(component);
    },
    updateNubbinPosition: function(component, event, helper) {
        helper.calculateNubbinPlacement(component);
    },
    showTooltip: function (component, event, helper) {
        var tooltipStyleOptions = helper.calculateTooltipPosition(component);
        var tooltipStyle = 'position: absolute; width: ' + tooltipStyleOptions.width + 'px;left: ' + tooltipStyleOptions.tooltipXPos + 'px; top: ' + tooltipStyleOptions.tooltipYPos + 'px;';
        component.set('v.tooltipStyle', tooltipStyle);
        component.set('v.showTooltip', true);
    },
    hideTooltip: function (component, event, helper) {
        var tooltipStyle = component.find('tooltipStyle').getElement();

        tooltipStyle.innerHTML = '';
        component.set('v.showTooltip', false);
        component.set('v.tooltipStyle', '');
    }
})