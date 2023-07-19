/**
 * Created by cshah on Oct 30, 2020.
 */

({
    doInit: function (component, event, helper) {
        component.set('v.refresh', false);
        const recordId = component.get('v.recordId');
        console.log('recordId: ', JSON.stringify(recordId));

        const pageRef = component.get('v.pageReference');
        if (pageRef && pageRef.state && Object.keys(pageRef.state).length > 0) {
            const state = pageRef.state; // state holds any query params
            let base64Context = state.inContextOfRef;

            /*For some reason, the string starts with '1.', if somebody knows why, this solution could be better generalized.*/
            if (base64Context.startsWith('1\.')) {
                base64Context = base64Context.substring(2);
            }

            const addressableContext = JSON.parse(window.atob(base64Context));
            console.log('addressableContext.attributes: ', JSON.stringify(addressableContext.attributes));
            component.set('v.contractId', addressableContext.attributes.recordId);
            component.set('v.actionName', 'edit');
        }

        component.set('v.refresh', true);
    }
});