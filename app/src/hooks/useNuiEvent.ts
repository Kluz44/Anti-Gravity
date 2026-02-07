import { useEffect, useRef } from 'react';

interface NuiMessageData<T = unknown> {
    action: string;
    data: T;
}

export const useNuiEvent = <T = unknown>(
    action: string,
    handler: (data: T) => void,
) => {
    const savedHandler = useRef<((data: T) => void) | null>(null);

    // When handler changes, save the new handler
    useEffect(() => {
        savedHandler.current = handler;
    }, [handler]);

    useEffect(() => {
        const eventListener = (event: MessageEvent<NuiMessageData<T>>) => {
            const { action: eventAction, data } = event.data;

            if (savedHandler.current && eventAction === action) {
                savedHandler.current(data);
            }
        };

        window.addEventListener('message', eventListener);

        // Remove Event Listener on cleanup
        return () => window.removeEventListener('message', eventListener);
    }, [action]);
};
