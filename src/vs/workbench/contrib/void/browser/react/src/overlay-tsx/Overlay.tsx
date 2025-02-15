/*--------------------------------------------------------------------------------------
 *  Copyright 2025 Glass Devtools, Inc. All rights reserved.
 *  Licensed under the Apache License, Version 2.0. See LICENSE.txt for more information.
 *--------------------------------------------------------------------------------------*/

import React from 'react';
import { useAccessor } from '../util/services.js';

export const Overlay = () => {
    const accessor = useAccessor();

    return (
        <div className="overlay-container" style={{
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            justifyContent: 'center',
            height: '100%',
            width: '100%',
            backgroundColor: 'var(--vscode-editor-background)',
            color: 'var(--vscode-editor-foreground)',
            borderRadius: '8px',
            boxShadow: '0 4px 6px rgba(0, 0, 0, 0.1)',
            padding: '20px'
        }}>
            <h2 style={{ marginBottom: '16px' }}>Overlay Component</h2>
            <p>This is a basic React component rendered in the overlay.</p>
        </div>
    );
};
