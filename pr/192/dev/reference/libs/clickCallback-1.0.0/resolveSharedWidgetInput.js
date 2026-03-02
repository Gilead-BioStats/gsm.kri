const resolveSharedWidgetInput = function(input) {
    const sharedPayloadKey = input.strSharedPayloadKey;

    if (!sharedPayloadKey) {
        return input;
    }

    window.__gsmKriSharedPayloadRegistry = window.__gsmKriSharedPayloadRegistry || {};
    const sharedPayload = window.__gsmKriSharedPayloadRegistry[ sharedPayloadKey ] || {};

    const output = { ...input };

    Object.keys(sharedPayload).forEach(key => {
        if (output[ key ] === null || typeof output[ key ] === 'undefined') {
            output[ key ] = sharedPayload[ key ];
        }
    });

    return output;
};
