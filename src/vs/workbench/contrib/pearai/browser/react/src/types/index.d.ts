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
        protected readonly _map: Map<string, T>;
        protected readonly _toKey: ResourceMapKeyFn;

        constructor(toKey?: ResourceMapKeyFn);
        constructor(other?: ResourceMap<T>, toKey?: ResourceMapKeyFn);
        constructor(entries?: readonly (readonly [URI, T])[], toKey?: ResourceMapKeyFn);
        constructor(entriesOrKey?: any, toKey?: ResourceMapKeyFn);

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
        static isUri(thing: any): thing is URI;
        static parse(value: string, _strict?: boolean): URI;
        static file(path: string): URI;

        scheme: string;
        authority: string;
        path: string;
        query: string;
        fragment: string;
        fsPath: string;

        with(change: { scheme?: string; authority?: string; path?: string; query?: string; fragment?: string }): URI;
        toString(skipEncoding?: boolean): string;
        toJSON(): UriComponents;

        static revive(data: UriComponents | URI): URI;
        static revive(data: UriComponents | URI | undefined): URI | undefined;
        static revive(data: UriComponents | URI | null): URI | null;
        static revive(data: UriComponents | URI | undefined | null): URI | undefined | null;
    }

    export function revive(data: UriComponents | URI): URI;
    export function revive(data: UriComponents | URI | undefined): URI | undefined;
    export function revive(data: UriComponents | URI | null): URI | null;
    export function revive(data: UriComponents | URI | undefined | null): URI | undefined | null;
}

declare module 'vs/base/common/async' {
    export interface ISequentializer {
        run<T>(task: () => Promise<T>, taskId?: number): Promise<T>;
    }

    export class Sequentializer {
        private _running: Promise<unknown> | null;
        private _current: Promise<unknown> | null;

        run<T>(promiseTask: () => Promise<T>, taskId?: number): Promise<T>;
    }

    export class TaskSequentializer {
        private _sequentializer: ISequentializer;
        private _tasks: number;

        constructor();
        run<T>(factory: () => Promise<T>): Promise<T>;
        get sequentializer(): ISequentializer;
        get tasks(): number;
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

// Declare empty modules to satisfy TypeScript
declare module 'assets' {}
declare module 'hooks' {}
declare module 'types' {}
