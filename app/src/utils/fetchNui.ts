/**
 * A wrapper for fetch to make NUI callbacks to the Lua client.
 * @param eventName - The event name to trigger in the client (RegisterNUICallback)
 * @param data - The data to send
 * @returns Promise with the result
 */
export const fetchNui = async <T = any>(eventName: string, data?: any): Promise<T> => {
    const options = {
        method: 'post',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify(data),
    };

    const resourceName = (window as any).GetParentResourceName
        ? (window as any).GetParentResourceName()
        : 'nui-frame-app'; // Fallback for browser dev

    const resp = await fetch(`https://${resourceName}/${eventName}`, options);

    const respFormatted = await resp.json();

    return respFormatted;
};
