const resolveSharedWidgetInput = function(input) {
    const sharedPayloadKey = input.strSharedPayloadKey;

    if (!sharedPayloadKey) {
        return input;
    }

    window.__gsmKriSharedPayloadRegistry = window.__gsmKriSharedPayloadRegistry || {};
    const registry = window.__gsmKriSharedPayloadRegistry;

    if (!Object.prototype.hasOwnProperty.call(registry, sharedPayloadKey)) {
        console.warn(
            'resolveSharedWidgetInput: shared payload key "' +
            sharedPayloadKey +
            '" not found in window.__gsmKriSharedPayloadRegistry; using original input without shared payload.'
        );
        return input;
    }

    const sharedPayload = registry[ sharedPayloadKey ] || {};

    const output = { ...input };

    Object.keys(sharedPayload).forEach(key => {
        if (output[ key ] === null || typeof output[ key ] === 'undefined') {
            output[ key ] = sharedPayload[ key ];
        }
    });

    return output;
};
