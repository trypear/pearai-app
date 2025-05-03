/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

import { URI } from 'vs/base/common/uri';
import { IStorageService, StorageScope, StorageTarget } from 'vs/platform/storage/common/storage';
import { INotificationService } from 'vs/platform/notification/common/notification';
import { IWorkbenchContribution } from 'vs/workbench/common/contributions';
import { Registry } from 'vs/platform/registry/common/platform';
import { Extensions as WorkbenchExtensions, IWorkbenchContributionsRegistry } from 'vs/workbench/common/contributions';
import { IURLHandler, IURLService } from 'vs/platform/url/common/url';
import { ISecretStorageService } from 'vs/platform/secrets/common/secrets';
import { IDisposable } from 'vs/base/common/lifecycle';
import { LifecyclePhase } from 'vs/workbench/services/lifecycle/common/lifecycle';

const PEAR_AUTH_STORAGE_KEY = 'pearai.auth';

export class PearAuthenticationUriHandler implements IWorkbenchContribution, IURLHandler {
	private urlHandler: IDisposable;

	constructor(
		@IURLService urlService: IURLService,
		@IStorageService private readonly storageService: IStorageService,
		@ISecretStorageService private readonly secretStorageService: ISecretStorageService,
		@INotificationService private readonly notificationService: INotificationService
	) {
		this.urlHandler = urlService.registerHandler(this);
	}

	async handleURL(uri: URI): Promise<boolean> {
		if (uri.authority === 'pearai.pearai') {
			if (uri.path === '/ping') {
				this.notificationService.info('PearAI received a custom URI!');
				return true;
			} else if (uri.path === '/auth') {
				const queryParams = new URLSearchParams(uri.query);
				const data = {
					accessToken: queryParams.get('accessToken'),
					refreshToken: queryParams.get('refreshToken'),
				};
if (data.accessToken && data.refreshToken) {
	// Store tokens in secret storage
	await this.secretStorageService.set('pearai.accessToken', data.accessToken);
	await this.secretStorageService.set('pearai.refreshToken', data.refreshToken);

	// Store auth state in storage service
	this.storageService.store(
		PEAR_AUTH_STORAGE_KEY,
		{ isAuthenticated: true },
		StorageScope.APPLICATION,
		StorageTarget.MACHINE
	);

	this.notificationService.info('Successfully logged in to PearAI');
}
return true;
}
}
return false;
}

dispose(): void {
	this.urlHandler.dispose();
}
}

// TODO: I think file isnt beeing registered, idk why

console.dir("I AM A REGISTERED OFFENDER")
// Register the URI handler as a workbench contribution
Registry.as<IWorkbenchContributionsRegistry>(WorkbenchExtensions.Workbench)
	.registerWorkbenchContribution(PearAuthenticationUriHandler, LifecyclePhase.Restored);
