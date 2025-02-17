// Add missing types for VS Code internals
interface HTMLElement {
    editContext?: any;
}

interface Thenable<T> {
    then<TResult>(onfulfilled?: (value: T) => TResult | Thenable<TResult>, onrejected?: (reason: any) => TResult | Thenable<TResult>): Thenable<TResult>;
    then<TResult>(onfulfilled?: (value: T) => TResult | Thenable<TResult>, onrejected?: (reason: any) => void): Thenable<TResult>;
}

declare module 'vs/base/common/map' {
    export interface ResourceMapKeyFn {
        (resource: URI): string;
    }

    export class ResourceMap<T> {
        constructor(entriesOrKey?: ResourceMapKeyFn | readonly URI[] | ResourceMap<T> | readonly (readonly [URI, T])[]);
        set(resource: URI, value: T): this;
        get(resource: URI): T | undefined;
        has(resource: URI): boolean;
        delete(resource: URI): boolean;
        clear(): void;
        size: number;
        keys(): URI[];
        values(): T[];
        entries(): [URI, T][];
    }
}

declare module 'vs/base/common/uri' {
    export interface UriComponents {
        scheme: string;
        authority: string;
        path: string;
        query: string;
        fragment: string;
    }

    export class URI implements UriComponents {
        scheme: string;
        authority: string;
        path: string;
        query: string;
        fragment: string;
        fsPath: string;
        with(change: { scheme?: string; authority?: string; path?: string; query?: string; fragment?: string }): URI;
        toJSON(): UriComponents;
    }
}

declare module 'vs/base/common/async' {
    export interface ISequentializer {
        run<T>(promiseFactory: () => Promise<T>): Promise<T>;
    }
}

// Extend the global scope
declare global {
    interface Window {
        _VSCODE_FILE_ROOT?: string;
        _VSCODE_NLS_MESSAGES?: any;
        _VSCODE_NLS_LANGUAGE?: string;
    }
}
